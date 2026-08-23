(* Source-pinned CF259 Q4 rank-3 arithmetic/reconstruction transfer gate.
   This is a constructed oracle, not a physical CF259 sector solution. *)

Module[
  {repositoryRoot = "/home/maxzhang/factorization-and-loops",
   exchangeRoot, workDirectory, sourceManifest, expectedManifestHash,
   outputFile, outputParent, failureTag, fail, hashHex, manifestText,
   manifestLines, manifestParts, expectedHashes, badSources, sourcePaths,
   checks = {}, assert, exactZeroQ, sameVectorQ, putAtomic,
   oracle, preparation, expected, squareCertificate, coverage,
   squares, q4Unit, q4DerivativeX, q4DerivativeY,
   trainingPrimes, unseenPrime, epsilonSamples, reconstructionSeconds,
   reconstruction, exactVerification, branchSeconds, branchChecks,
   branchLabels, corruptedVector, corrupted, corruptedExact,
   result, allPassed, wrapperResult},

  exchangeRoot = FileNameJoin[{repositoryRoot,
    "External", "CodexExchange", "triple_root_2026-08-22"}];
  workDirectory = FileNameJoin[{exchangeRoot,
    "cf259_q4_rank3_oracle_2026-08-23_xh"}];
  sourceManifest = FileNameJoin[{workDirectory, "SOURCE_SHA256SUMS"}];
  expectedManifestHash =
    "dc64dfb52af72dcb387a0c4fdfaf83fa9a6b8de8d85fbad9e2a297bf5c88b271";
  outputFile =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf259_q4_rank3_oracle_xh_v1.wl";
  outputParent = DirectoryName[outputFile];
  failureTag = Unique["CF259Q4Rank3OracleV1$"];

  fail[message_String] := (
    Print["CF259 Q4 RANK3 GATE FAILURE V1: " <> message];
    Throw[$Failed, failureTag]);
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
  exactZeroQ[expression_] := AllTrue[
    Flatten[{expression}], TrueQ[Together[#] === 0] &];
  sameVectorQ[left_List, right_List] :=
    Dimensions[left] === Dimensions[right] && exactZeroQ[left - right];
  assert[name_String, condition_] := Module[{passed = TrueQ[condition]},
    AppendTo[checks, <|"Name" -> name, "Pass" -> passed|>];
    Print["CF259 Q4 RANK3 ", If[passed, "PASS ", "FAIL "], name];
    passed];
  putAtomic[expression_, file_String] := Module[
    {temporary, written, moved},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = Quiet[Check[
      Put[expression, temporary]; FileExistsQ[temporary], False]];
    If[TrueQ[written],
      moved = Quiet[Check[
        RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
      If[StringQ[moved] && FileExistsQ[file], file, $Failed],
      $Failed]];

  wrapperResult = Catch[
    (* K145 is the only authorized worker.  Keep this dispatch guard before
       every FileHash/Import/FileExistsQ call so a wrong assignment performs
       no target-level I/O and cannot consume the K146 recapture slot. *)
    If[! IntegerQ[$KernelID] || $KernelID =!= 145,
      fail["hard dispatch requires pool worker K145; observed K" <>
        ToString[$KernelID, InputForm]]];
    If[Length[Kernels[]] =!= 0,
      fail["nested kernels are forbidden"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["mission helper ceiling must be exactly zero"]];
    If[Length[$ScriptCommandLine] =!= 1 ||
        ExpandFileName[First[$ScriptCommandLine]] =!=
          ExpandFileName[$InputFileName],
      fail["gate takes no arguments"]];

    If[hashHex[sourceManifest] =!= expectedManifestHash,
      fail["source manifest drifted or is unreadable"]];
    manifestText = Quiet[Check[Import[sourceManifest, "Text"], $Failed]];
    If[! StringQ[manifestText], fail["could not import source manifest"]];
    manifestLines = Select[
      StringSplit[manifestText, {"\r\n", "\n", "\r"}],
      StringLength[StringTrim[#]] > 0 &];
    manifestParts = StringSplit[StringTrim[#], Whitespace] & /@
      manifestLines;
    If[Length[manifestParts] =!= 4 ||
        ! AllTrue[manifestParts,
          Length[#] === 2 &&
            StringMatchQ[#[[1]],
              Repeated[HexadecimalCharacter, {64}]] &&
            ! StringStartsQ[#[[2]], "/"] &&
            FreeQ[FileNameSplit[#[[2]]], ".."] &],
      fail["malformed source manifest"]];
    expectedHashes = Association[Rule @@@ (Reverse /@ manifestParts)];
    If[Length[expectedHashes] =!= Length[manifestParts],
      fail["duplicate source-manifest path"]];
    sourcePaths = FileNameJoin[{repositoryRoot, #}] & /@
      Keys[expectedHashes];
    badSources = Select[Keys[expectedHashes],
      hashHex[FileNameJoin[{repositoryRoot, #}]] =!= expectedHashes[#] &];
    If[badSources =!= {},
      fail["source drift: " <> ToString[badSources, InputForm]]];

    If[FileExistsQ[outputFile] || DirectoryQ[outputFile],
      fail["output is not fresh: " <> outputFile]];
    If[! DirectoryQ[outputParent],
      fail["output parent is absent: " <> outputParent]];

    Scan[Function[path,
      If[Quiet[Check[Get[path]; True, False]] =!= True,
        fail["could not load pinned source: " <> path]]], sourcePaths];

    Block[{Global`x, Global`y, Global`eps},
      oracle =
        CodexTripleRootRank3CF259Oracle`TRBuildCF259Q4Rank3Oracle[];
      squares = Lookup[oracle, "ActiveRootSquares", {}];
      assert["oracle_family_and_field",
        Lookup[oracle, "Status", None] ===
            "ConstructedCF259Q4Rank3Oracle" &&
          Lookup[oracle, "Family", None] === "CF259" &&
          Length[squares] === 3 &&
          exactZeroQ[squares - {
            Expand[(1 - Global`x - Global`y)^2 -
              4 Global`x Global`y],
            Expand[(1 - Global`x + Global`y)^2 +
              4 Global`x Global`y],
            4 Global`x + Global`y^2}]];

      squareCertificate =
        CodexTripleRootRank3CF259Oracle`TRCF259Q4Rank3SquareClassCertificate[
          oracle];
      assert["all_seven_square_class_products_are_nonsquare",
        Lookup[squareCertificate, "Status", None] ===
            "IndependentSquareClasses" &&
          Lookup[squareCertificate, "Rank", None] === 3 &&
          Lookup[squareCertificate, "Masks", {}] === Range[1, 7] &&
          Lookup[squareCertificate, "Nonsquare", {}] ===
            ConstantArray[True, 7]];

      q4Unit = ReplacePart[ConstantArray[0, 8], 5 -> 1];
      q4DerivativeX = CodexTripleRoot`TRDerivative[
        q4Unit, squares, Global`x];
      q4DerivativeY = CodexTripleRoot`TRDerivative[
        q4Unit, squares, Global`y];
      assert["q4_radical_derivatives",
        sameVectorQ[q4DerivativeX,
          ReplacePart[ConstantArray[0, 8],
            5 -> 2/(4 Global`x + Global`y^2)]] &&
        sameVectorQ[q4DerivativeY,
          ReplacePart[ConstantArray[0, 8],
            5 -> Global`y/(4 Global`x + Global`y^2)]]];

      preparation =
        CodexTripleRootReconstruction`TRPrepareReconstruction[
          oracle["Record"], oracle["Frame"],
          "OneForms" -> oracle["OneForms"],
          "GaugeDenominator" -> oracle["GaugeDenominator"],
          "Support" -> oracle["GaugeSupport"],
          "NormalizationEquations" ->
            oracle["NormalizationEquations"]];
      assert["prepared_rank3_q4_identity_frame_with_valid_abi",
        Lookup[preparation, "Status", None] ===
            "PreparedReconstruction" &&
          Lookup[preparation, "RootCount", None] === 3 &&
          Lookup[preparation, "GradeCount", None] === 8 &&
          Lookup[preparation, "UnknownCount", None] === 25 &&
          Lookup[preparation, "EquationsPerPoint", None] === 16 &&
          CodexTripleRootReconstruction`TRPreparationABIValidQ[
            preparation]];

      expected =
        CodexTripleRootRank3CF259Oracle`TRCF259Q4Rank3ExpectedVector[
          oracle, preparation];
      assert["expected_oracle_vector_uses_all_q4_grades",
        Lookup[expected, "Status", None] === "ExpectedOracleVector" &&
          Length[Lookup[expected, "Vector", {}]] === 25 &&
          AllTrue[Take[Lookup[expected, "Vector", {}], 24],
            ! TrueQ[Together[#] === 0] &]];

      coverage =
        CodexTripleRootRank3CF259Oracle`TRCF259Q4Rank3ForcingGradeCoverage[
          oracle, preparation];
      assert["forcing_exercises_all_eight_grades",
        Lookup[coverage, "Status", None] ===
            "OracleForcingGradeCoverage" &&
          Lookup[coverage, "Coverage", {}] === ConstantArray[True, 8] &&
          TrueQ[Lookup[coverage, "AllGradesNonzero", False]]];

      trainingPrimes = Take[Select[Range[10000, 11000],
        PrimeQ[#] && Mod[#, 4] === 3 &], 3];
      unseenPrime = First[Select[Range[1000000, 1003000],
        PrimeQ[#] && Mod[#, 4] === 3 &&
          ! MemberQ[trainingPrimes, #] &]];
      epsilonSamples = {1/2, 2/3, 3/5};
      {reconstructionSeconds, reconstruction} = AbsoluteTiming[
        CodexTripleRootReconstruction`TRReconstructAffineBatch[
          preparation, epsilonSamples, trainingPrimes,
          "EpsilonDegree" -> 0,
          "RandomSeed" -> 259043,
          "Verbose" -> True]];
      assert["three_prime_exact_q4_reconstruction",
        Lookup[reconstruction, "Status", None] ===
            "ExactReconstruction" &&
          Lookup[reconstruction, "Primes", {}] === trainingPrimes &&
          Lookup[reconstruction, "Rank", None] === 25 &&
          Lookup[reconstruction, "Nullity", None] === 0];
      assert["reconstruction_matches_constructed_oracle",
        AssociationQ[expected] && AssociationQ[reconstruction] &&
          sameVectorQ[reconstruction["ReconstructedVector"],
            expected["Vector"]] &&
          Lookup[reconstruction, "Residues", Missing[]] === {{{43}}}];

      exactVerification =
        CodexTripleRootReconstruction`TRVerifyReconstructionExact[
          reconstruction];
      assert["exact_characteristic_zero_channel_certificate",
        Lookup[exactVerification, "Status", None] ===
            "ExactChannelResidualZero" &&
          TrueQ[Lookup[exactVerification, "ResidualZero", False]]];

      {branchSeconds, branchChecks} = AbsoluteTiming[Table[
        CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
          reconstruction, unseenPrime, {4/7, 5/8},
          "RandomSeed" -> 259100 + branchMask,
          "BranchFlipMask" -> branchMask],
        {branchMask, 0, 7}]];
      branchLabels = Map[
        Lookup[First[Lookup[#, "Checks", {<||>}]],
          "BranchFlipMask", Missing[]] &, branchChecks];
      assert["all_eight_q4_sign_branches_at_unseen_prime",
        Length[branchChecks] === 8 &&
          AllTrue[branchChecks,
            Lookup[#, "Status", None] === "UnseenPrimeVerified" &&
              TrueQ[Lookup[#, "ResidualZero", False]] &] &&
          branchLabels === Range[0, 7]];

      corruptedVector = ReplacePart[
        reconstruction["ReconstructedVector"],
        13 -> reconstruction["ReconstructedVector"][[13]] + 1];
      corrupted = Join[reconstruction,
        <|"ReconstructedVector" -> corruptedVector|>];
      corruptedExact =
        CodexTripleRootReconstruction`TRVerifyReconstructionExact[
          corrupted];
      assert["q4_grade_corruption_is_rejected_exactly",
        Lookup[corruptedExact, "Status", None] ===
            "ExactChannelResidualNonzero" &&
          ! TrueQ[Lookup[corruptedExact, "ResidualZero", True]]];
    ];

    allPassed = Length[checks] === 12 &&
      AllTrue[checks, TrueQ[Lookup[#, "Pass", False]] &];
    result = <|
      "Status" -> If[allPassed,
        "CF259Q4Rank3OraclePassedV1", "CF259Q4Rank3OracleFailedV1"],
      "Scope" -> "ConstructedQ4ArithmeticTransferGateNotPhysicalSector",
      "Family" -> "CF259",
      "RootSquares" -> squares,
      "Checks" -> checks,
      "TrainingPrimes" -> trainingPrimes,
      "UnseenPrime" -> unseenPrime,
      "EpsilonSamples" -> epsilonSamples,
      "ReconstructionSeconds" -> reconstructionSeconds,
      "AllBranchSeconds" -> branchSeconds,
      "PreparationSummary" -> KeyTake[preparation,
        {"Status", "RootCount", "GradeCount", "RootSourceIndices",
          "RootFingerprints", "GaugeUnknownCount", "ResidueUnknownCount",
          "UnknownCount", "EquationsPerPoint", "ABIFingerprint"}],
      "ReconstructionSummary" -> KeyTake[reconstruction,
        {"Status", "Primes", "Rank", "Nullity", "PivotColumns",
          "FreeColumns"}],
      "SquareClassSummary" -> KeyTake[squareCertificate,
        {"Status", "Masks", "FactorLists", "Nonsquare", "Rank"}],
      "BranchSummaries" -> (KeyDrop[#, {"Checks"}] & /@ branchChecks),
      "CorruptionSummary" -> corruptedExact,
      "SourceManifest" -> sourceManifest,
      "SourceManifestSHA256" -> expectedManifestHash,
      "SourceHashes" -> expectedHashes,
      "WorkerKernelID" -> $KernelID,
      "RequiredWorkerKernelID" -> 145,
      "NestedKernelCount" -> Length[Kernels[]],
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[putAtomic[result, outputFile] === $Failed,
      fail["atomic result write failed"]];
    Print["CF259 Q4 RANK3 RESULT V1 status=", result["Status"],
      " passed=", Count[Lookup[checks, "Pass", {}], True], "/",
      Length[checks], " output=", outputFile];
    If[allPassed, result, Throw[$Failed, failureTag]],
    failureTag];
  wrapperResult
]
