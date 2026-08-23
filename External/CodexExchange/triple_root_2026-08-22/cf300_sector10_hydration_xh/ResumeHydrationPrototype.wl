(* Fail-closed resume hydration prototype.  This file is deliberately not
   loaded by FeynFacet.m or the production sector driver. *)

BeginPackage["CodexResumeHydration`"];
HydrateMissingSolvedForms::usage =
  "HydrateMissingSolvedForms[checkpoint,file,blocks,forms,family,sector,variables,eps,frame,ranges,scratch] replays only missing materialized dlog forms from isolated copies of exact matching saved inputs/modular artifacts. The mandatory CurrentConnection option binds each saved strip to the checkpoint connection; writing is atomic and occurs only after every identity/coverage gate passes.";
Begin["`Private`"];

ClearAll[hydrationHashDirectory, hydrationZeroQ,
  hydrationFrameCertificateQ, hydrationBlockEquation,
  HydrateMissingSolvedForms];

hydrationHashDirectory[directory_] := If[DirectoryQ[directory],
  Association@Table[
    FileNameTake[file] -> FileHash[file, "SHA256", "HexString"],
    {file, Sort[FileNames["*.wl", directory]]}], <||>];

hydrationZeroQ[value_] := AllTrue[Flatten[value], SameQ[#, 0] &];

(* Reproduce the production blockEquation ordering exactly.  A saved strip
   is not an authority by itself: before replay it must be derivable from the
   checkpoint's current connection and the already-solved higher blocks. *)
hydrationBlockEquation[connection_List, sector_Integer,
    lowerSector_Integer, solvedBlocks_Association, ranges_List,
    epsilon_Symbol] := Module[{rk = ranges[[sector]],
    rj = ranges[[lowerSector]], higher},
  higher = Select[Keys[solvedBlocks], lowerSector < # < sector &];
  {
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rk, rk]], {2}], {mu, 2}],
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rj, rj]], {2}], {mu, 2}],
    Table[Map[Together,
      connection[[mu, rk, rj]] -
        Sum[solvedBlocks[m] .
          connection[[mu, ranges[[m]], rj]], {m, higher}],
      {2}], {mu, 2}]
  }
];

hydrationFrameCertificateQ[solution_Association] := Module[
  {method = Lookup[solution, "Method", None], certificate},
  If[method === "ZeroForcing",
    Return[TrueQ[Lookup[solution, "ExactDLog", False]]]];
  certificate = Lookup[solution, "FrameCertificate", <||>];
  If[! AssociationQ[certificate] || ! StringQ[method], Return[False]];
  Which[
    StringStartsQ[method, "RationalFrame/"],
      Lookup[solution, "RootIndices", Missing["NoRootIndices"]] === {} &&
        Lookup[certificate, "Chart", Missing["NoChart"]] === None &&
        And @@ (TrueQ[Lookup[certificate, #, False]] & /@
          {"GaugeRoundTrip", "TransformedOneFormPullBack", "Exact"}),
    StringStartsQ[method, "RationalChart/"],
      MatchQ[Lookup[solution, "RootIndices", {}], {__Integer}] &&
        And @@ (TrueQ[Lookup[certificate, #, False]] & /@
          {"CoordinateComposition", "GaugeRoundTrip",
           "TransformedOneFormPullBack", "SourceDLog", "Exact"}),
    True, False]
];
hydrationFrameCertificateQ[_] := False;

Options[HydrateMissingSolvedForms] = {
  "KernelCount" -> 1,
  "FinalCheck" -> "Numerical",
  "MinimumCachedPrimeCount" -> 3,
  "ExpectedConnectionHash" -> Automatic,
  "CurrentConnection" -> Automatic,
  "WriteCheckpoint" -> False,
  "Verbose" -> True
};

HydrateMissingSolvedForms[
    checkpoint_Association, checkpointFile_String,
    solvedBlocks_Association, existingForms_Association,
    family_String, sector_Integer?Positive,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    frame_Association, ranges_List, scratch_String,
    OptionsPattern[]] := Module[
  {tag = Unique["resumeHydration"], workRoot, result, missing,
   forms = existingForms, keys, rowSize, lowerSize, blockColumns,
   installedRow = Automatic, replayRecords = {}, stripSolvers, kernelCount,
   finalCheck, minimumCached, expectedConnectionHash, diskCheckpoint,
   currentConnection, currentTruncation, currentConnectionHash, nk,
   lowerBlockSizes, reconstructedPrevD, checkpointForms, verbose, writeQ,
   fullCoverageQ, formsShapeQ,
   started = AbsoluteTime[]},

  kernelCount = OptionValue["KernelCount"];
  finalCheck = OptionValue["FinalCheck"];
  minimumCached = OptionValue["MinimumCachedPrimeCount"];
  expectedConnectionHash = OptionValue["ExpectedConnectionHash"];
  currentConnection = OptionValue["CurrentConnection"];
  verbose = TrueQ[OptionValue["Verbose"]];
  writeQ = TrueQ[OptionValue["WriteCheckpoint"]];
  If[! IntegerQ[kernelCount] || kernelCount < 1 ||
      ! MemberQ[{"Numerical", "Exact"}, finalCheck] ||
      ! IntegerQ[minimumCached] || minimumCached < 1 ||
      ! StringQ[expectedConnectionHash] ||
      ! MatchQ[ranges, {{__Integer} ..}] ||
      ! MatchQ[Dimensions[currentConnection], {2, _Integer, _Integer}] ||
      Dimensions[currentConnection][[2]] =!=
        Dimensions[currentConnection][[3]] ||
      sector > Length[ranges],
    Return[<|"Status" -> "InvalidOptionsOrRanges",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  nk = Last[ranges[[sector]]];
  If[! IntegerQ[nk] || nk < 1 || nk > Dimensions[currentConnection][[2]],
    Return[<|"Status" -> "InvalidCurrentConnection",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  If[Flatten[Take[ranges, sector]] =!= Range[nk],
    Return[<|"Status" -> "InvalidRangePartition",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  currentTruncation =
    currentConnection[[All, 1 ;; nk, 1 ;; nk]] /.
      epsilon -> CANONICA`eps;
  currentConnectionHash = Hash[currentTruncation,
    "SHA256", "HexString"];
  diskCheckpoint = If[FileExistsQ[checkpointFile],
    FeynFacet`FamilyArtifactRead[checkpointFile], Missing["NoCheckpoint"]];
  If[! SameQ[diskCheckpoint, checkpoint] ||
      Lookup[checkpoint, "ConnectionHash", None] =!=
        expectedConnectionHash ||
      currentConnectionHash =!= expectedConnectionHash,
    Return[<|"Status" -> "CheckpointIdentityMismatch",
      "DiskSameQ" -> SameQ[diskCheckpoint, checkpoint],
      "ConnectionHashSameQ" ->
        (Lookup[checkpoint, "ConnectionHash", None] ===
          expectedConnectionHash),
      "CurrentConnectionHashSameQ" ->
        (currentConnectionHash === expectedConnectionHash),
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];

  checkpointForms = Lookup[checkpoint, "SolvedForms", <||>];
  If[! AssociationQ[checkpointForms] ||
      ! SameQ[forms, checkpointForms],
    Return[<|"Status" -> "CheckpointSolvedFormsMismatch",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  keys = Sort[Keys[solvedBlocks]];
  missing = Complement[keys, Keys[forms]];
  rowSize = Length[ranges[[sector]]];
  lowerSize = First[ranges[[sector]]] - 1;
  blockColumns = Association@Table[key -> ranges[[key]], {key, keys}];
  stripSolvers = Lookup[checkpoint, "StripSolvers", {}];
  lowerBlockSizes = Length /@ ranges[[Range[sector - 1]]];
  If[Lookup[checkpoint, "Sector", Missing["NoSector"]] =!= sector ||
      Lookup[checkpoint, "SubSize", Missing["NoSubSize"]] =!= rowSize ||
      Lookup[checkpoint, "Truncation", Missing["NoTruncation"]] =!= nk ||
      ! FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
        Lookup[checkpoint, "PrevD", None], rowSize, lowerBlockSizes] ||
      ! FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
        stripSolvers, Lookup[checkpoint, "PrevD", None], sector,
        lowerBlockSizes],
    Return[<|"Status" -> "InvalidCheckpointMetadata",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  If[! AssociationQ[forms] || ! ListQ[stripSolvers] ||
      ! AllTrue[keys, IntegerQ[#] && 1 <= # < sector &] ||
      (keys =!= {} && keys =!= Range[First[keys], sector - 1]) ||
      ! AllTrue[keys,
        Dimensions[Lookup[solvedBlocks, #, Missing["NoGauge"]]] ===
          {rowSize, Length[ranges[[#]]]} &],
    Return[<|"Status" -> "InvalidCheckpointPayload",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  reconstructedPrevD = If[keys === {}, ConstantArray[{}, rowSize],
    Transpose[Join @@ (Transpose /@ Lookup[solvedBlocks, keys])]];
  If[! SameQ[reconstructedPrevD,
      Lookup[checkpoint, "PrevD", Missing["NoPrevD"]]],
    Return[<|"Status" -> "CheckpointSolvedBlocksMismatch",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]];
  fullCoverageQ = keys === Range[sector - 1];
  formsShapeQ[candidate_Association] :=
    Sort[Keys[candidate]] === keys && AllTrue[keys,
      Dimensions[Lookup[candidate, #, Missing["NoForm"]]] ===
          {2, rowSize, Length[ranges[[#]]]} &&
        Dimensions[Lookup[solvedBlocks, #, Missing["NoGauge"]]] ===
          {rowSize, Length[ranges[[#]]]} &&
        FreeQ[Lookup[candidate, #],
          Alternatives[_Missing, Automatic, $Failed]] &];

  (* A complete modern checkpoint is never replayed or rewritten. *)
  If[missing === {},
    If[! formsShapeQ[forms],
      Return[<|"Status" -> "ExistingFormsFailedAssembly",
        "ActivateInstalledRow" -> False,
        "CheckpointWritten" -> False|>]];
    If[fullCoverageQ,
      installedRow = FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
        forms, solvedBlocks, rowSize, lowerSize, blockColumns]];
    Return[If[fullCoverageQ && ListQ[installedRow],
      <|"Status" -> "AlreadyComplete", "SolvedForms" -> forms,
        "InstalledRow" -> installedRow, "ActivateInstalledRow" -> True,
        "CheckpointWritten" -> False|>,
      If[! fullCoverageQ,
        <|"Status" -> "AlreadyCompletePartial",
          "SolvedForms" -> forms, "InstalledRow" -> Automatic,
          "ActivateInstalledRow" -> False,
          "CheckpointWritten" -> False|>,
      <|"Status" -> "ExistingFormsFailedAssembly",
        "ActivateInstalledRow" -> False,
        "CheckpointWritten" -> False|>]]]];

  workRoot = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
    "FeynFacet-resume-hydration-" <> CreateUUID[]}]];
  result = Catch[
    Do[Module[{stripTag, sourceInput, copiedInput, sourceArtifacts,
        copiedArtifacts, input, zeroQ, beforeHashes, afterHashes,
        summary, seconds, solution, gauge, expectedGauge, dimensions,
        solvedForm, frameQ, artifactCount},
      stripTag = family <> "_" <> ToString[sector] <> "_" <>
        ToString[lowerSector];
      sourceInput = FileNameJoin[{scratch, stripTag <> "_input.wl"}];
      copiedInput = FileNameJoin[{workRoot, stripTag <> "_input.wl"}];
      sourceArtifacts = FileNameJoin[{scratch,
        stripTag <> "_finite_field"}];
      copiedArtifacts = FileNameJoin[{workRoot,
        stripTag <> "_finite_field"}];
      If[! FileExistsQ[sourceInput],
        Throw[<|"Status" -> "MissingStripInput",
          "LowerSector" -> lowerSector|>, tag]];
      CopyFile[sourceInput, copiedInput];
      input = FeynFacet`FamilyArtifactRead[copiedInput];
      If[! AssociationQ[input] ||
          Lookup[input, "Family", None] =!= family ||
          Lookup[input, "Sector", None] =!= sector ||
          Lookup[input, "LowerSector", None] =!= lowerSector ||
          ! SameQ[Lookup[input, "Variables", None], variables] ||
          ! SameQ[Lookup[input, "Regulator", None], epsilon] ||
          ! MatchQ[Lookup[input, "Strip", None], {_List, _List, _List}],
        Throw[<|"Status" -> "StripInputIdentityMismatch",
          "LowerSector" -> lowerSector|>, tag]];
      Module[{expectedStrip = hydrationBlockEquation[currentConnection,
          sector, lowerSector, solvedBlocks, ranges, epsilon]},
        If[! SameQ[input["Strip"], expectedStrip],
          Throw[<|
            "Status" -> "StripInputCheckpointConnectionMismatch",
            "LowerSector" -> lowerSector,
            "SavedStripSHA256" -> Hash[input["Strip"],
              "SHA256", "HexString"],
            "RecomputedStripSHA256" -> Hash[expectedStrip,
              "SHA256", "HexString"],
            "CheckpointWritten" -> False|>, tag]]];
      expectedGauge = Lookup[solvedBlocks, lowerSector,
        Missing["MissingCheckpointGauge"]];
      dimensions = If[MatrixQ[expectedGauge],
        Dimensions[expectedGauge], {}];
      If[! MatchQ[dimensions, {rowSize, _Integer}] ||
          dimensions[[2]] =!= Length[ranges[[lowerSector]]] ||
          Dimensions[input["Strip"][[3, 1]]] =!= dimensions,
        Throw[<|"Status" -> "StripGaugeDimensionMismatch",
          "LowerSector" -> lowerSector, "Expected" -> dimensions,
          "Input" -> Quiet[Check[
            Dimensions[input["Strip"][[3, 1]]], Missing[]]]|>, tag]];
      summary = SelectFirst[stripSolvers,
        Lookup[#, "Sector", None] === sector &&
          Lookup[#, "LowerSector", None] === lowerSector &,
        Missing["NoStripSolverSummary"]];
      If[MissingQ[summary],
        Throw[<|"Status" -> "MissingStripSolverSummary",
          "LowerSector" -> lowerSector|>, tag]];
      zeroQ = hydrationZeroQ[input["Strip"][[3]]];
      artifactCount = If[DirectoryQ[sourceArtifacts],
        Length[FileNames[stripTag <> "_mod_*.wl", sourceArtifacts]], 0];
      If[! zeroQ && artifactCount < minimumCached,
        Throw[<|"Status" -> "InsufficientCachedArtifacts",
          "LowerSector" -> lowerSector, "Count" -> artifactCount|>, tag]];
      If[DirectoryQ[sourceArtifacts],
        CopyDirectory[sourceArtifacts, copiedArtifacts]];
      beforeHashes = hydrationHashDirectory[copiedArtifacts];
      If[verbose, Print["  resume hydration strip ",
        {sector, lowerSector}, ": zero=", zeroQ,
        ", cached=", artifactCount]];
      {seconds, solution} = AbsoluteTiming[
        FeynFacet`SolveEpsFormStripInFrame[
          input["Strip"], variables, epsilon, frame,
          "FiniteFieldFirst" -> True,
          "FiniteFieldOptions" -> {
            "KernelCount" -> kernelCount,
            "FinalCheck" -> finalCheck,
            "Verbose" -> verbose},
          "ScratchDirectory" -> workRoot,
          "Tag" -> stripTag, "Verbose" -> verbose]];
      afterHashes = hydrationHashDirectory[copiedArtifacts];
      If[! AssociationQ[solution] ||
          Lookup[solution, "Status", None] =!= "Solved" ||
          ! If[finalCheck === "Exact",
              TrueQ[Lookup[solution, "ExactDLog", False]],
              TrueQ[Lookup[solution, "ExactDLog", False]] ||
                Lookup[solution, "Certificate", None] ===
                  "NumericalResidual"],
        Throw[<|"Status" -> "HydrationSolveFailed",
          "LowerSector" -> lowerSector,
          "SolutionStatus" -> If[AssociationQ[solution],
            Lookup[solution, "Status", None], "NotAssociation"]|>, tag]];
      gauge = Lookup[solution, "Gauge", Missing["NoGauge"]];
      frameQ = hydrationFrameCertificateQ[solution];
      If[! SameQ[gauge, expectedGauge] || ! frameQ ||
          Lookup[solution, "Method", None] =!=
            Lookup[summary, "Method", None] ||
          beforeHashes =!= afterHashes,
        Throw[<|"Status" -> "HydrationIdentityGateFailed",
          "LowerSector" -> lowerSector,
          "GaugeSameQ" -> SameQ[gauge, expectedGauge],
          "FrameCertificate" -> frameQ,
          "MethodSameQ" -> (Lookup[solution, "Method", None] ===
            Lookup[summary, "Method", None]),
          "CopiedArtifactsUnchanged" -> beforeHashes === afterHashes|>,
          tag]];
      solvedForm = FeynFacet`Private`familyRowGaugeDLogForm[
        solution, variables, epsilon, dimensions];
      If[! ListQ[solvedForm] ||
          Dimensions[solvedForm] =!= Prepend[dimensions, 2] ||
          ! FreeQ[solvedForm, Alternatives[_Missing, Automatic, $Failed]],
        Throw[<|"Status" -> "HydratedFormInvalid",
          "LowerSector" -> lowerSector|>, tag]];
      AssociateTo[forms, lowerSector -> solvedForm];
      AppendTo[replayRecords, <|"LowerSector" -> lowerSector,
        "InputSHA256" -> FileHash[copiedInput, "SHA256", "HexString"],
        "CheckpointStripSameQ" -> True,
        "ZeroForcing" -> zeroQ, "CachedPrimeCount" -> artifactCount,
        "Seconds" -> seconds, "Method" -> solution["Method"],
        "Certificate" -> Lookup[solution, "Certificate", None],
        "ExactDLog" -> Lookup[solution, "ExactDLog", False],
        "GaugeSameQ" -> True, "FrameCertificate" -> True,
        "CopiedArtifactsUnchanged" -> True,
        "SolvedFormDimensions" -> Dimensions[solvedForm],
        "SolvedFormSHA256" -> Hash[solvedForm,
          "SHA256", "HexString"]|>]],
      {lowerSector, missing}];

    If[Sort[Keys[forms]] =!= keys,
      Throw[<|"Status" -> "IncompleteHydratedKeyCoverage",
        "Expected" -> keys, "Actual" -> Sort[Keys[forms]]|>, tag]];
    If[! formsShapeQ[forms],
      Throw[<|"Status" -> "HydratedFormsInvalid"|>, tag]];
    If[fullCoverageQ,
      installedRow = FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
        forms, solvedBlocks, rowSize, lowerSize, blockColumns];
      If[! ListQ[installedRow] ||
          Dimensions[installedRow] =!= {2, rowSize, lowerSize} ||
          ! FreeQ[installedRow,
            Alternatives[_Missing, Automatic, $Failed]],
        Throw[<|"Status" -> "HydratedAssemblyFailed"|>, tag]]];
    If[writeQ,
      Module[{latestCheckpoint, updatedCheckpoint, written, reread},
        (* Replay may take minutes.  Never overwrite a checkpoint changed by
           another process since the identity gate at function entry. *)
        latestCheckpoint = If[FileExistsQ[checkpointFile],
          FeynFacet`FamilyArtifactRead[checkpointFile],
          Missing["NoCheckpoint"]];
        If[! SameQ[latestCheckpoint, checkpoint],
          Throw[<|"Status" -> "CheckpointChangedBeforeWrite",
            "CheckpointWritten" -> False|>, tag]];
        updatedCheckpoint = Join[checkpoint, <|
          "SolvedForms" -> forms,
          "SolvedFormsHydration" -> <|
            "Method" -> "CachedArtifactReplay",
            "FinalCheck" -> finalCheck,
            "AllReplayedFormsExactDLog" ->
              AllTrue[replayRecords,
                TrueQ[Lookup[#, "ExactDLog", False]] &],
            "MissingLowerSectors" -> missing,
            "ReplayRecords" -> replayRecords|>|>];
        written = Quiet[Check[
          FeynFacet`FamilyArtifactWrite[updatedCheckpoint,
            checkpointFile], $Failed]];
        reread = If[written === $Failed, $Failed,
          FeynFacet`FamilyArtifactRead[checkpointFile]];
        If[written === $Failed || ! SameQ[reread, updatedCheckpoint],
          Throw[<|"Status" -> "AtomicCheckpointWriteVerificationFailed",
            "CheckpointWritten" -> (written =!= $Failed)|>, tag]]]];
    <|"Status" -> If[fullCoverageQ, "Hydrated", "HydratedPartial"],
      "SolvedForms" -> forms,
      "InstalledRow" -> installedRow, "MissingLowerSectors" -> missing,
      "ActivateInstalledRow" -> fullCoverageQ,
      "ReplayRecords" -> replayRecords,
      "CheckpointWritten" -> writeQ,
      "Seconds" -> N[AbsoluteTime[] - started]|>,
    tag, #1 &];
  If[DirectoryQ[workRoot],
    Quiet[DeleteDirectory[workRoot, DeleteContents -> True]]];
  If[AssociationQ[result],
    If[MemberQ[{"Hydrated", "HydratedPartial"},
        Lookup[result, "Status", None]], result,
      Join[result, <|"ActivateInstalledRow" -> False,
        "CheckpointWritten" -> False|>]],
    <|"Status" -> "HydrationInternalFailure",
      "ActivateInstalledRow" -> False,
      "CheckpointWritten" -> False|>]
];

HydrateMissingSolvedForms[___] :=
  <|"Status" -> "InvalidHydrationArguments",
    "ActivateInstalledRow" -> False,
    "CheckpointWritten" -> False|>;

End[];
EndPackage[];
