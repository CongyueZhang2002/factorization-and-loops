#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stripFile,
    referencePreparationFile,
    outdir, resultFile, summaryFile, expectedHashes, hashHex, putAtomic,
    fail, tag, result, badHashes, stripPayload, referencePreparation,
    frame, record, offsets,
    records = {}, preparation, assembly, sample, solve, seconds,
    consistentOffsets, summary, offset},
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
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_degree_probe_v1";
  resultFile = FileNameJoin[{outdir, "probe.wl"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018RankOneDegreeProbeV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stripFile ->
      "766ffcc218bf56ac85add02d441e84f54811d1b5dde40685af7cf3c308db50ef",
    referencePreparationFile ->
      "b070db79a1987306c98400aab69942c4ce59c61304ccb044203826a27c4198ba"|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := (
    Print["CF303 20->18 RANK-ONE DEGREE PROBE FAILURE V1: ", status,
      " data=", data];
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
    Print["CF3032018R1DEGREEV1 stage=load"];
    Get[loadFile];
    stripPayload = Import[stripFile, "WXF"];
    referencePreparation = Import[referencePreparationFile, "WXF"];
    If[! AssociationQ[stripPayload] ||
        ! AssociationQ[referencePreparation] ||
        Lookup[stripPayload, "Status", None] =!=
          "CF303Sector20TopAnd181RankOneStripsPassedV1" ||
        Lookup[referencePreparation, "Status", None] =!=
          "PreparedMultiquadraticStripV1",
      fail["InvalidStripInputABI"]];
    frame = stripPayload["Frame"];
    record = <|"Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> 18,
      "Variables" -> referencePreparation["Variables"],
      "Regulator" -> referencePreparation["Regulator"],
      "Strip" -> stripPayload["Strip2018"]|>;
    offsets = {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
      {2, 1}, {1, 2}, {2, 2}, {3, 0}, {0, 3}};
    Do[
      Print["CF3032018R1DEGREEV1 offset=", offset, " stage=prepare"];
      seconds = First@AbsoluteTiming[
        preparation = FeynFacet`Private`multiquadraticStripPrepare[
          record, frame,
          "OneForms" -> referencePreparation["OneForms"],
          "GaugeDenominator" ->
            referencePreparation["GaugeDenominator"],
          "DegreeOffset" -> offset];
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
              sample["Matrix"], sample["RightHandSide"], 2147483423],
            sample],
          assembly = Missing["NotCompiled"];
          sample = Missing["NotAssembled"];
          solve = preparation]];
      AppendTo[records, <|
        "DegreeOffset" -> offset,
        "PreparationStatus" -> Lookup[preparation, "Status", None],
        "GaugeDenominatorDegrees" -> Lookup[preparation,
          "GaugeDenominatorDegrees", Missing[]],
        "GaugeSupportCount" -> Length[Lookup[preparation,
          "GaugeSupport", {}]],
        "OneFormCount" -> Length[Lookup[preparation, "OneForms", {}]],
        "UnknownCount" -> Lookup[preparation, "UnknownCount", Missing[]],
        "MatrixDimensions" -> Lookup[sample, "MatrixDimensions",
          Missing[]],
        "SolveStatus" -> Lookup[solve, "Status", None],
        "Rank" -> Lookup[solve, "Rank", Missing[]],
        "Nullity" -> Lookup[solve, "Nullity", Missing[]],
        "InconsistentRows" -> Lookup[solve, "InconsistentRows", {}],
        "Seconds" -> seconds|>];
      Print["CF3032018R1DEGREEV1 offset=", offset, " status=",
        Last[records]["SolveStatus"], " unknowns=",
        Last[records]["UnknownCount"], " seconds=",
        Round[seconds, 0.1]],
      {offset, offsets}];
    consistentOffsets = Lookup[Select[records,
      Lookup[#, "SolveStatus", None] ===
        "MultiquadraticAffineSolution" &], "DegreeOffset", {}];
    putAtomic[<|
      "Status" -> "CF303Sector2018RankOneDegreeProbeCompletedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Prime" -> 2147483423, "RegulatorValue" -> 1/13,
      "Records" -> records, "ConsistentOffsets" -> consistentOffsets,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector2018RankOneDegreeProbeCompletedV1",
      "TestedOffsets" -> offsets,
      "ConsistentOffsets" -> consistentOffsets,
      "FirstConsistentOffset" -> If[consistentOffsets === {},
        Missing["NoConsistentGaugeDegree"], First[consistentOffsets]],
      "Records" -> records,
      "ProbeFile" -> resultFile,
      "ProbeSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3032018R1DEGREEV1 status=COMPLETE consistentOffsets=",
      consistentOffsets];
    0,
    tag];
  result
]
