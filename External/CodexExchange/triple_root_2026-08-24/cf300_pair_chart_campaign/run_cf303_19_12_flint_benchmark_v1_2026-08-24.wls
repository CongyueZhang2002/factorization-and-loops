#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, finiteFieldFile,
    stripFile, referenceSolutionFile, referenceSummaryFile, outdir,
    artifactDirectory, solutionFile, summaryFile, expectedHashes,
    dependencyFiles, dependencyHashes, hashHex, expressionHash,
    putAtomic, exportAtomic, fail, tag, result, badHashes, stripPayload,
    referencePayload, referenceSummary, referenceSolution, record,
    solution, solveSeconds, referenceSeconds, speedup, zeroMatrixQ,
    gaugeSameQ, gaugeDifferenceZeroQ, exactChecks, comparisonChecks,
    summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stripFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_12_attempt_1/strip.wxf";
  referenceSolutionFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_12_attempt_1/solution.wxf";
  referenceSummaryFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_12_attempt_1/summary.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_19_12_flint_benchmark_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  solutionFile = FileNameJoin[{outdir, "benchmark_solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3031912FLINTBenchmarkV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stripFile ->
      "c37b3277f2aa770c88506f9664f440d36efe5459c94688ad85723001f66a0dc8",
    referenceSolutionFile ->
      "afe538e835c0b56ff871af920a4d31848f87afa8c7f849883661f67aec069162",
    referenceSummaryFile ->
      "fcdfc96bf3cc2b11218f7358a6751514d9689f191ad17e2b6287380e4eab766c"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile,
    "FiniteFieldStripSolve" -> finiteFieldFile|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  expressionHash[expression_] :=
    IntegerString[Hash[expression, "SHA256"], 16, 64];
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
      "Sector" -> 19, "LowerSector" -> 12,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 19->12 FLINT BENCHMARK FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]];

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["PoolWorkerRequired"]];
    If[Length[Kernels[]] =!= 0,
      fail["MissionWorkerAlreadyOwnsNestedKernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 4),
      fail["HelperCeilingMustBeFour"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    CreateDirectory[artifactDirectory];

    Print["CF3031912FLINTV1 stage=load-inputs"];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    stripPayload = Import[stripFile, "WXF"];
    referencePayload = Import[referenceSolutionFile, "WXF"];
    referenceSummary = Get[referenceSummaryFile];
    referenceSolution = Lookup[referencePayload, "Solution", $Failed];
    If[! And @@ (AssociationQ /@ {stripPayload, referencePayload,
          referenceSummary, referenceSolution}) ||
        Lookup[stripPayload, "Status", None] =!=
          "CF303Sector19PairChartRationalStripV1" ||
        Lookup[stripPayload, "LowerSector", None] =!= 12 ||
        Lookup[referencePayload, "Status", None] =!=
          "CF303Sector19PairChartDLogSolutionV1" ||
        Lookup[referenceSolution, "Status", None] =!= "Solved" ||
        ! TrueQ[Lookup[referenceSolution, "ExactDLog", False]],
      fail["InvalidReferenceABI"]];
    record = <|"Family" -> "CF303", "Sector" -> 19,
      "LowerSector" -> 12, "Variables" -> stripPayload["Variables"],
      "Regulator" -> stripPayload["Regulator"],
      "Strip" -> stripPayload["Strip"]|>;
    referenceSeconds = referenceSummary["SolveSeconds"];

    Print["CF3031912FLINTV1 stage=solve baselineSeconds=",
      referenceSeconds];
    solveSeconds = First@AbsoluteTiming[
      solution = FeynFacet`SolveEpsFormStripFiniteField[record,
        "KernelCount" -> 5,
        "ArtifactDirectory" -> artifactDirectory,
        "ArtifactPrefix" -> "CF303_19_12_flint_benchmark_v1",
        "Backend" -> Automatic, "BackendThreads" -> 1,
        "PlanDiscoveryBackend" -> "FLINTAffineRREF",
        "SupportStrategy" -> "SimplexFirst",
        "SupportLearning" -> True,
        "RegulatorSampling" -> "HeldOut",
        "FinalCheck" -> "Exact", "Verbose" -> True]];
    exactChecks = <|
      "SolvedStatus" ->
        AssociationQ[solution] && Lookup[solution, "Status", None] ===
          "Solved",
      "ExactDLog" -> TrueQ[Lookup[solution, "ExactDLog", False]],
      "ExactPfaffianResidualsZero" -> TrueQ[Lookup[
        solution, "ExactPfaffianResidualsZero", False]],
      "LettersEpsFree" ->
        TrueQ[Lookup[solution, "LettersEpsFree", False]],
      "ResiduesKinematicsFree" -> TrueQ[Lookup[
        solution, "ResiduesKinematicsFree", False]],
      "DLogFormCertified" ->
        TrueQ[Lookup[solution, "DLogFormCertified", False]],
      "FLINTPlanDiscoveryUsed" ->
        Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
          "FLINTAffineRREF"|>;
    If[! And @@ Values[exactChecks],
      exportAtomic[<|"Status" -> "CF3031912FLINTBenchmarkFailedV1",
        "SolveSeconds" -> solveSeconds, "ExactChecks" -> exactChecks,
        "Solution" -> solution|>, solutionFile];
      fail["FLINTSolveNotExactlyCertified", <|
        "SolveSeconds" -> solveSeconds, "Checks" -> exactChecks,
        "SolutionSummary" -> If[AssociationQ[solution],
          KeyDrop[solution, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], solution]|>]];

    zeroMatrixQ[matrix_List] := AllTrue[Flatten[matrix],
      TrueQ[Together[#] === 0] &];
    gaugeSameQ = TrueQ[solution["Gauge"] === referenceSolution["Gauge"]];
    gaugeDifferenceZeroQ = Dimensions[solution["Gauge"]] ===
        Dimensions[referenceSolution["Gauge"]] &&
      zeroMatrixQ[solution["Gauge"] - referenceSolution["Gauge"]];
    comparisonChecks = <|
      "GaugeSameQReference" -> gaugeSameQ,
      "GaugeDifferenceExactlyZero" -> gaugeDifferenceZeroQ,
      "AlphabetSameQReference" -> TrueQ[
        solution["Alphabet"] === referenceSolution["Alphabet"]],
      "ResidueMatricesSameQReference" -> TrueQ[
        solution["ResidueMatrices"] ===
          referenceSolution["ResidueMatrices"]]|>;
    speedup = referenceSeconds/solveSeconds;
    exportAtomic[<|
      "Status" -> "CF3031912FLINTBenchmarkSolutionPassedV1",
      "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> 12,
      "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
      "ReferenceSolutionFile" -> referenceSolutionFile,
      "ReferenceSolutionSHA256" -> hashHex[referenceSolutionFile],
      "Solution" -> solution|>, solutionFile];
    summary = <|
      "Status" -> "CF3031912FLINTBenchmarkPassedV1",
      "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> 12,
      "ReferencePlanDiscoveryBackend" -> "Wolfram",
      "BenchmarkPlanDiscoveryBackend" ->
        solution["PlanDiscoveryBackendUsed"],
      "ReferenceSolveSeconds" -> referenceSeconds,
      "BenchmarkSolveSeconds" -> solveSeconds,
      "Speedup" -> speedup,
      "ExactChecks" -> exactChecks,
      "ComparisonChecks" -> comparisonChecks,
      "ReferenceGaugeFingerprint" ->
        expressionHash[referenceSolution["Gauge"]],
      "BenchmarkGaugeFingerprint" -> expressionHash[solution["Gauge"]],
      "SelectedNumeratorDegreeOffset" ->
        Lookup[solution, "SelectedNumeratorDegreeOffset", Missing[]],
      "SelectedSupportShell" ->
        Lookup[solution, "SelectedSupportShell", Missing[]],
      "DegreeProbe" -> Lookup[solution, "DegreeProbe", Missing[]],
      "ModularPrimeCount" ->
        Lookup[solution, "ModularPrimeCount", Missing[]],
      "TotalSamplingSeconds" ->
        Lookup[solution, "TotalSamplingSeconds", Missing[]],
      "TotalInterpolationSeconds" ->
        Lookup[solution, "TotalInterpolationSeconds", Missing[]],
      "SolutionFile" -> solutionFile,
      "SolutionSHA256" -> hashHex[solutionFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringBenchmark"]];
    Print["CF3031912FLINTV1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " speedup=", Round[speedup, 0.01],
      " gaugeExact=", gaugeDifferenceZeroQ];
    0,
    tag];
  result
]
