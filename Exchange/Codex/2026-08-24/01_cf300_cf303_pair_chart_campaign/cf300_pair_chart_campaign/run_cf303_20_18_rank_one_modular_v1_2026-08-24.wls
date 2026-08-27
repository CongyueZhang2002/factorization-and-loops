#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stripFile,
    preparationFile, outdir, resultFile, summaryFile, expectedHashes,
    hashHex, putAtomic, exportAtomic, fail, tag, result, badHashes,
    stripPayload, preparation, frame, record, solveResult, solveSeconds,
    exactLiftStatuses, exactResidualStatuses, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stripFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/rank_one_strips.wxf";
  preparationFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/preparation_20_18.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_modular_v1";
  resultFile = FileNameJoin[{outdir, "modular_result.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018RankOneModularV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stripFile ->
      "766ffcc218bf56ac85add02d441e84f54811d1b5dde40685af7cf3c308db50ef",
    preparationFile ->
      "b070db79a1987306c98400aab69942c4ce59c61304ccb044203826a27c4198ba"|>;

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
  fail[status_String, data_: <||>] := Module[{failureFile, failure},
    failure = Join[<|"Status" -> status, "Family" -> "CF303",
      "Sector" -> 20, "LowerSector" -> 18,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 20->18 RANK-ONE MODULAR FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]];

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
    Print["CF3032018R1MODV1 stage=load"];
    Get[loadFile];
    stripPayload = Import[stripFile, "WXF"];
    preparation = Import[preparationFile, "WXF"];
    If[! AssociationQ[stripPayload] || ! AssociationQ[preparation] ||
        Lookup[stripPayload, "Status", None] =!=
          "CF303Sector20TopAnd181RankOneStripsPassedV1" ||
        Lookup[preparation, "Status", None] =!=
          "PreparedMultiquadraticStripV1" ||
        preparation["ABIFingerprint"] =!=
          "f409248c387143d33b9f4403952291335072c07b755d9c12420ec1773b20d2e4",
      fail["InvalidPreparedInputABI"]];
    frame = stripPayload["Frame"];
    record = <|"Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> 18, "Variables" -> preparation["Variables"],
      "Regulator" -> preparation["Regulator"],
      "Strip" -> stripPayload["Strip2018"]|>;

    Print["CF3032018R1MODV1 stage=solve unknowns=",
      preparation["UnknownCount"]];
    solveSeconds = First@AbsoluteTiming[
      solveResult =
        FeynFacet`Private`solveEpsFormStripMultiquadratic[
          record, frame, "Verbose" -> True]];
    exactLiftStatuses = If[AssociationQ[solveResult],
      Values[Lookup[solveResult, "ExactLift", <||>]], {}];
    exactResidualStatuses = If[AssociationQ[solveResult],
      Values[Lookup[solveResult, "ExactChannelResidual", <||>]], {}];
    checks = <|
      "ModularConsistentStatus" ->
        AssociationQ[solveResult] &&
          Lookup[solveResult, "Status", None] === "ModularConsistent",
      "NeverClaimsSolved" ->
        Lookup[solveResult, "Status", None] =!= "Solved" &&
          Lookup[solveResult, "SolutionContract", None] ===
            "OneFormsNotCertified",
      "RankOneGradeTwo" ->
        Lookup[solveResult, "RootCount", None] === 1 &&
          Lookup[solveResult, "GradeCount", None] === 2,
      "DimensionsTwoByTwo" ->
        Lookup[solveResult, "Dimensions", None] === {2, 2},
      "StableNonnegativeRankNullity" ->
        IntegerQ[Lookup[solveResult, "Rank", None]] &&
          IntegerQ[Lookup[solveResult, "Nullity", None]] &&
          Min[solveResult["Rank"], solveResult["Nullity"]] >= 0,
      "AllBranchesCertified" ->
        Length[Lookup[solveResult, "BranchCertificate", {}]] === 2 &&
          AllTrue[Lookup[solveResult, "BranchCertificate", {}],
            TrueQ[Lookup[#, "ResidualZero", False]] &],
      "SplitSignDifferentialPassed" ->
        Lookup[Lookup[solveResult, "DifferentialCheck", <||>],
          "Status", None] === "MultiquadraticPointDifferentialPassed"|>;
    exportAtomic[<|
      "Status" -> If[And @@ Values[checks],
        "CF303Sector2018RankOneModularPassedV1",
        "CF303Sector2018RankOneModularFailedV1"],
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Checks" -> checks, "SolveSeconds" -> solveSeconds,
      "Result" -> solveResult,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    If[! And @@ Values[checks],
      fail["ModularCertificateFailed", <|"Checks" -> checks,
        "ResultSummary" -> If[AssociationQ[solveResult],
          KeyDrop[solveResult, {"HeldOutSolution", "ModularSolutions",
            "ExactLiftVectors", "GaugeChannels", "Gauge", "Residues"}],
          solveResult]|>]];
    summary = <|
      "Status" -> "CF303Sector2018RankOneModularPassedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Method" -> solveResult["Method"],
      "SolutionContract" -> solveResult["SolutionContract"],
      "RootCount" -> solveResult["RootCount"],
      "GradeCount" -> solveResult["GradeCount"],
      "Dimensions" -> solveResult["Dimensions"],
      "UnknownCount" -> solveResult["UnknownCount"],
      "EquationsPerPoint" -> solveResult["EquationsPerPoint"],
      "Rank" -> solveResult["Rank"],
      "Nullity" -> solveResult["Nullity"],
      "SamplePrimes" -> solveResult["SamplePrimes"],
      "RegulatorValues" -> solveResult["RegulatorValues"],
      "HeldOutPrime" -> solveResult["HeldOutPrime"],
      "HeldOutRegulatorValue" -> solveResult["HeldOutRegulatorValue"],
      "ExactLiftStatuses" -> exactLiftStatuses,
      "ExactChannelResidualStatuses" -> exactResidualStatuses,
      "AllBranchesCertified" -> checks["AllBranchesCertified"],
      "DifferentialCheck" -> solveResult["DifferentialCheck"],
      "ChannelPathStatistics" -> solveResult["ChannelPathStatistics"],
      "SolveSeconds" -> solveSeconds,
      "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3032018R1MODV1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " rank=", solveResult["Rank"],
      " nullity=", solveResult["Nullity"], " exactLifts=",
      exactLiftStatuses];
    0,
    tag];
  result
]
