#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stripFile,
    referencePreparationFile, candidateFile, outdir, resultFile,
    winningPreparationFile, summaryFile, expectedHashes, hashHex,
    putAtomic, exportAtomic, fail, tag, result, badHashes, stripPayload,
    referencePreparation, candidates, frame, record, variables,
    fullForms, factors, sortedFactors, baseDenominator, candidateDenominator,
    factorDegree, records = {}, preparation, assembly, sample, solve,
    heldOutSample, heldOutSolve, seconds, winningRecord = None,
    summary, factor, index},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stripFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/rank_one_strips.wxf";
  referencePreparationFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/preparation_20_18.wxf";
  candidateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_alphabet_probe_v1/candidate_alphabets.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_denominator_probe_v1";
  resultFile = FileNameJoin[{outdir, "probe.wl"}];
  winningPreparationFile = FileNameJoin[{outdir,
    "winning_preparation.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018RankOneDenominatorProbeV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stripFile ->
      "766ffcc218bf56ac85add02d441e84f54811d1b5dde40685af7cf3c308db50ef",
    referencePreparationFile ->
      "b070db79a1987306c98400aab69942c4ce59c61304ccb044203826a27c4198ba",
    candidateFile ->
      "df9aba223582397f44160cbcb92e6c87a040095ad97282b6ed14ad0462c34b5a"|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  exportAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Export[temporary, expression, "WXF"];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := (
    Print["CF303 20->18 RANK-ONE DENOMINATOR PROBE FAILURE V1: ",
      status, " data=", data];
    Throw[$Failed, tag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      fail["SinglePoolWorkerRequired"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    Print["CF3032018R1DENOMV1 stage=load"];
    Get[loadFile];
    stripPayload = Import[stripFile, "WXF"];
    referencePreparation = Import[referencePreparationFile, "WXF"];
    candidates = Import[candidateFile, "WXF"];
    If[! And @@ (AssociationQ /@
        {stripPayload, referencePreparation, candidates}) ||
        Lookup[candidates, "Status", None] =!=
          "CF303Sector2018RankOneAlphabetProbeCompletedV1",
      fail["InvalidCandidateInputABI"]];
    frame = stripPayload["Frame"];
    variables = referencePreparation["Variables"];
    record = <|"Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> 18, "Variables" -> variables,
      "Regulator" -> referencePreparation["Regulator"],
      "Strip" -> stripPayload["Strip2018"]|>;
    fullForms = candidates["FullOneForms"];
    factors = candidates["RationalFactors"];
    baseDenominator = referencePreparation["GaugeDenominator"];
    factorDegree[value_] := {
      Total[Exponent[value, #] & /@ variables],
      Max[Exponent[value, #] & /@ variables], LeafCount[value]};
    sortedFactors = SortBy[factors, factorDegree];

    Do[
      factor = sortedFactors[[index]];
      candidateDenominator = Together[baseDenominator factor];
      Print["CF3032018R1DENOMV1 candidate=", index, "/",
        Length[sortedFactors], " factorDegrees=", factorDegree[factor],
        " denominatorDegrees=",
        Exponent[candidateDenominator, #] & /@ variables];
      seconds = First@AbsoluteTiming[
        preparation = FeynFacet`Private`multiquadraticStripPrepare[
          record, frame, "OneForms" -> fullForms,
          "GaugeDenominator" -> candidateDenominator,
          "DegreeOffset" -> {0, 0}];
        If[Lookup[preparation, "Status", None] ===
            "PreparedMultiquadraticStripV1",
          assembly = FeynFacet`Private`multiquadraticStripCompile[
            preparation];
          sample = If[Lookup[assembly, "Status", None] ===
              "CompiledMultiquadraticStripV1",
            FeynFacet`Private`multiquadraticStripAssembleSample[
              assembly, 1/13, 2147483423], assembly];
          solve = If[Lookup[sample, "Status", None] ===
              "AssembledMultiquadraticSampleV1",
            FeynFacet`Private`multiquadraticStripAffineSolve[
              sample["Matrix"], sample["RightHandSide"],
              2147483423], sample],
          assembly = Missing["NotCompiled"];
          sample = Missing["NotAssembled"];
          solve = preparation]];
      AppendTo[records, <|
        "CandidateIndex" -> index, "Factor" -> factor,
        "FactorDegrees" -> factorDegree[factor],
        "GaugeDenominator" -> candidateDenominator,
        "GaugeDenominatorDegrees" -> If[AssociationQ[preparation],
          Lookup[preparation, "GaugeDenominatorDegrees", Missing[]],
          Missing[]],
        "GaugeSupportCount" -> Length[If[AssociationQ[preparation],
          Lookup[preparation, "GaugeSupport", {}], {}]],
        "OneFormCount" -> Length[fullForms],
        "UnknownCount" -> If[AssociationQ[preparation],
          Lookup[preparation, "UnknownCount", Missing[]], Missing[]],
        "MatrixDimensions" -> If[AssociationQ[sample],
          Lookup[sample, "MatrixDimensions", Missing[]], Missing[]],
        "SolveStatus" -> If[AssociationQ[solve],
          Lookup[solve, "Status", None], None],
        "Rank" -> If[AssociationQ[solve],
          Lookup[solve, "Rank", Missing[]], Missing[]],
        "Nullity" -> If[AssociationQ[solve],
          Lookup[solve, "Nullity", Missing[]], Missing[]],
        "InconsistentRows" -> If[AssociationQ[solve],
          Lookup[solve, "InconsistentRows", {}], {}],
        "Seconds" -> seconds|>];
      Print["CF3032018R1DENOMV1 result=", Last[records]];
      If[Lookup[solve, "Status", None] ===
          "MultiquadraticAffineSolution",
        heldOutSample =
          FeynFacet`Private`multiquadraticStripAssembleSample[
            assembly, 3/17, 2147483399, "SplitPointsOnly" -> True];
        heldOutSolve = If[Lookup[heldOutSample, "Status", None] ===
            "AssembledMultiquadraticSampleV1",
          FeynFacet`Private`multiquadraticStripAffineSolve[
            heldOutSample["Matrix"], heldOutSample["RightHandSide"],
            2147483399], heldOutSample];
        winningRecord = Join[Last[records], <|
          "HeldOutStatus" -> Lookup[heldOutSolve, "Status", None],
          "HeldOutRank" -> Lookup[heldOutSolve, "Rank", Missing[]],
          "HeldOutNullity" -> Lookup[heldOutSolve, "Nullity", Missing[]],
          "HeldOutSignatureMatches" -> TrueQ[
            Lookup[heldOutSolve, "Status", None] ===
              "MultiquadraticAffineSolution" &&
            {heldOutSolve["Rank"], heldOutSolve["Nullity"],
              heldOutSolve["PivotSignature"]} ===
            {solve["Rank"], solve["Nullity"],
              solve["PivotSignature"]}]|>];
        If[TrueQ[winningRecord["HeldOutSignatureMatches"]],
          exportAtomic[preparation, winningPreparationFile];
          Break[]]],
      {index, Length[sortedFactors]}];

    putAtomic[<|
      "Status" -> "CF303Sector2018RankOneDenominatorProbeCompletedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "BaseGaugeDenominator" -> baseDenominator,
      "SortedFactors" -> sortedFactors, "Records" -> records,
      "WinningRecord" -> winningRecord,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector2018RankOneDenominatorProbeCompletedV1",
      "FactorCount" -> Length[sortedFactors],
      "TestedCandidateCount" -> Length[records],
      "WinningRecord" -> winningRecord,
      "WinningPreparationFile" -> If[FileExistsQ[winningPreparationFile],
        winningPreparationFile, Missing["NoWinningPreparation"]],
      "WinningPreparationSHA256" -> If[
        FileExistsQ[winningPreparationFile],
        hashHex[winningPreparationFile], Missing["NoWinningPreparation"]],
      "ProbeFile" -> resultFile,
      "ProbeSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3032018R1DENOMV1 status=COMPLETE winning=",
      winningRecord];
    0,
    tag];
  result
]
