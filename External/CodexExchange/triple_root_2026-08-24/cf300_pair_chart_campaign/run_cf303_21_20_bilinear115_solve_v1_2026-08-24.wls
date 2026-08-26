#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, finiteFieldFile,
    stateFile, row17CertificateFile, row18CertificateFile,
    row19CertificateFile, row20CertificateFile, outdir,
    artifactDirectory, resultFile, summaryFile, expectedHashes,
    dependencyFiles, dependencyHashes, hashHex, putAtomic, exportAtomic,
    fail, tag, result, badHashes, state, row17Certificate,
    row18Certificate, row19Certificate, row20Certificate, ranges,
    connection, variables, regulator, rowRange, lowerRange, rootSquares,
    frameVariables, frame, currentRoots, strip, classification,
    solveResult, solveSeconds, priorChecks, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  row17CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_certificate_v2/certificate.wxf";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  row20CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_20_bilinear115_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  resultFile = FileNameJoin[{outdir, "solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032120Bilinear115SolveV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    row17CertificateFile ->
      "adf9f2103dbecf16bac89cbe5be81909dc4bdfa3e5a0ff4e26f9bbeaed572435",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile,
    "FiniteFieldStripSolve" -> finiteFieldFile|>;

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
      "Sector" -> 21, "LowerSector" -> 20,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->20 BILINEAR115 SOLVE FAILURE V1: ", status,
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
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    state = Get[stateFile];
    row17Certificate = Import[row17CertificateFile, "WXF"];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@ {state, row17Certificate,
          row18Certificate, row19Certificate, row20Certificate}),
      fail["InvalidInputABI"]];
    priorChecks = <|
      "Sector17Passed" -> And @@ Values[row17Certificate["GlobalChecks"]],
      "Sector18Passed" -> And @@ Values[row18Certificate["GlobalChecks"]],
      "Sector19Passed" -> And @@ Values[row19Certificate["GlobalChecks"]],
      "Sector20Passed" -> And @@ Values[row20Certificate["GlobalChecks"]],
      "Sector20CertificateStatus" ->
        row20Certificate["Status"] ===
          "CF303Sector20MinimalChartRowCertificatePassedV1"|>;
    If[! And @@ Values[priorChecks],
      fail["PriorRowCertificateFailed", <|"Checks" -> priorChecks|>]];
    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[21]];
    lowerRange = ranges[[20]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || lowerRange =!= {35, 36},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector21Frame`p"],
      Symbol["CF303Sector21Frame`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["SourceMultiquadraticFrameFailed"]];
    currentRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, variables];
    strip = {
      connection[[All, rowRange, rowRange]]/regulator,
      connection[[All, lowerRange, lowerRange]]/regulator,
      connection[[All, rowRange, lowerRange]]};
    classification = FeynFacet`Private`transportChartRootIndices[
      strip, currentRoots];
    If[Lookup[classification, "RootIndices", None] =!= {3} ||
        Lookup[classification, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["UnexpectedActiveRootSet", <|
        "Classification" -> classification|>]];

    Print["CF3032120B115V1 stage=solve"];
    solveSeconds = First@AbsoluteTiming[
      solveResult = FeynFacet`SolveEpsFormStripInFrame[
        strip, variables, regulator, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldFallback" -> True,
        "MultiquadraticDispatch" -> False,
        "CANONICAKernels" -> 5,
        "ScratchDirectory" -> outdir,
        "Tag" -> "CF303_21_20_bilinear115_v1",
        "FiniteFieldOptions" -> {
          "KernelCount" -> 5,
          "ArtifactDirectory" -> artifactDirectory,
          "ArtifactPrefix" -> "CF303_21_20_bilinear115_v1",
          "Backend" -> Automatic, "BackendThreads" -> 1,
          "PlanDiscoveryBackend" -> "FLINTAffineRREF",
          "SupportStrategy" -> "SimplexFirst",
          "SupportLearning" -> True,
          "RegulatorSampling" -> "HeldOut",
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "Verbose" -> True]];
    checks = <|
      "SolvedStatus" -> AssociationQ[solveResult] &&
        Lookup[solveResult, "Status", None] === "Solved",
      "Bilinear115Route" -> StringContainsQ[
        ToString[Lookup[solveResult, "Method", ""]], "Bilinear115"],
      "OnlyThirdRootUsed" ->
        Lookup[solveResult, "RootIndices", None] === {3},
      "ExactDLog" -> TrueQ[Lookup[solveResult, "ExactDLog", False]],
      "GaugeDimensions" ->
        Dimensions[Lookup[solveResult, "Gauge", {}]] === {2, 2},
      "GaugeRoundTrip" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "GaugeRoundTrip", False]],
      "TransformedOneFormPullBack" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "TransformedOneFormPullBack", False]],
      "SourceDLog" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "SourceDLog", False]],
      "FrameCertificateExact" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "Exact", False]]|>;
    exportAtomic[<|
      "Status" -> If[And @@ Values[checks],
        "CF303Sector2120Bilinear115SolvedV1",
        "CF303Sector2120Bilinear115FailedV1"],
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 20,
      "Checks" -> checks, "SolveSeconds" -> solveSeconds,
      "SourceStrip" -> strip, "Frame" -> frame,
      "Solution" -> solveResult, "PriorChecks" -> priorChecks,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    If[! And @@ Values[checks],
      fail["Bilinear115SolveNotExactlyCertified", <|
        "Checks" -> checks, "SolveSeconds" -> solveSeconds|>]];
    summary = <|
      "Status" -> "CF303Sector2120Bilinear115SolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 20,
      "Method" -> solveResult["Method"],
      "RootIndices" -> solveResult["RootIndices"],
      "GaugeDimensions" -> Dimensions[solveResult["Gauge"]],
      "GaugeLeafCount" -> LeafCount[solveResult["Gauge"]],
      "AlphabetLength" -> Length[Lookup[solveResult, "Alphabet", {}]],
      "ExactDLog" -> solveResult["ExactDLog"],
      "FrameCertificate" -> solveResult["FrameCertificate"],
      "SolveSeconds" -> solveSeconds,
      "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032120B115V1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " method=", solveResult["Method"]];
    0,
    tag];
  result
]
