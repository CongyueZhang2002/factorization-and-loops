#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, finiteFieldFile,
    stateFile, row18CertificateFile, row19CertificateFile,
    row20CertificateFile, solution2120File, solution2119File,
    solution2118File, outdir, artifactDirectory, resultFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, row18Certificate,
    row19Certificate, row20Certificate, solution2120Payload,
    solution2119Payload, solution2118Payload, solution2120, solution2119,
    solution2118, ranges, connection, sourceVariables, regulator, rowRange,
    range20, range19, range18, range17, range16, range15, zeroMatrixQ,
    zeroPairQ, structuralChecks, d2117, d2116, forcing15, rootSquares,
    frameVariables, frame, allRoots, strip15, classification, chart,
    solveResult, solveSeconds, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  row20CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1/certificate.wxf";
  solution2120File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_20_bilinear115_solve_v1/solution.wxf";
  solution2119File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_19_kallen23_source_solve_v1/solution.wxf";
  solution2118File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_18_kallen2_source_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_17_16_zero_15_kallen3_source_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  resultFile = FileNameJoin[{outdir, "solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303211716Zero15Kallen3SourceSolveV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5",
    solution2119File ->
      "cd382a49f4dc930f6372861ba103b30d6731869ef63e907b922bd6449c18a5c8",
    solution2118File ->
      "f9e89a247594a7f9b2e079e1195344decc3d0d1f8107f5a30d1b499b73332956"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile,
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
      "Sector" -> 21, "LowerSector" -> 15,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->17,16 ZERO / 21->15 KALLEN3 FAILURE V1: ",
      status, " data=", data];
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
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    solution2120Payload = Import[solution2120File, "WXF"];
    solution2119Payload = Import[solution2119File, "WXF"];
    solution2118Payload = Import[solution2118File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, row18Certificate,
          row19Certificate, row20Certificate, solution2120Payload,
          solution2119Payload, solution2118Payload}) ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[solution2120Payload, "Status", None] =!=
          "CF303Sector2120Bilinear115SolvedV1" ||
        Lookup[solution2119Payload, "Status", None] =!=
          "CF303Sector2119MinimalChartSourceSolvedV1" ||
        Lookup[solution2118Payload, "Status", None] =!=
          "CF303Sector2118Kallen2SourceSolvedV1",
      fail["InvalidInputABI"]];
    solution2120 = solution2120Payload["Solution"];
    solution2119 = solution2119Payload["SourceSolution"];
    solution2118 = solution2118Payload["SourceSolution"];
    If[! (And @@ (TrueQ[Lookup[
          Lookup[#, "FrameCertificate", <||>], "Exact", False]] & /@
          {solution2120, solution2119, solution2118})),
      fail["PriorSector21SolutionsNotExact"]];
    ranges = state["Ranges"];
    connection = state["A"];
    sourceVariables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[21]];
    range20 = ranges[[20]];
    range19 = ranges[[19]];
    range18 = ranges[[18]];
    range17 = ranges[[17]];
    range16 = ranges[[16]];
    range15 = ranges[[15]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || range18 =!= {29, 30} ||
        range17 =!= {28} || range16 =!= {26, 27} ||
        range15 =!= {23, 24, 25},
      fail["UnexpectedPinnedStateShape"]];
    zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];
    zeroPairQ[pair_] := AllTrue[Flatten[pair],
      TrueQ[Together[#] === 0] &];

    structuralChecks = <|
      "AllPriorRowCertificatesPassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]] &&
        And @@ Values[row19Certificate["GlobalChecks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "Sector18RowGaugeExactlyZero" ->
        zeroMatrixQ[row18Certificate["RowGauge"]],
      "Sector18Gauges151617ExactlyZero" -> And @@ Table[
        zeroMatrixQ[row18Certificate["SolvedChartGauges"][j]],
        {j, {15, 16, 17}}],
      "Sector19Gauges151617ExactlyZero" -> And @@ Table[
        zeroMatrixQ[row19Certificate["SolvedChartGauges"][j]],
        {j, {15, 16, 17}}],
      "Sector20Gauges151617ExactlyZero" -> And @@ Table[
        zeroMatrixQ[row20Certificate["SolvedSourceGauges"][j]],
        {j, {15, 16, 17}}],
      "Raw2117And2116ExactlyZero" ->
        zeroPairQ[connection[[All, rowRange, range17]]] &&
        zeroPairQ[connection[[All, rowRange, range16]]],
      "All181920To151617RawPathsExactlyZero" -> And @@ Flatten@Table[
        zeroPairQ[connection[[All, ranges[[k]], ranges[[j]]]]],
        {k, {18, 19, 20}}, {j, {15, 16, 17}}],
      "Raw2019And2017ExactlyZero" ->
        zeroPairQ[connection[[All, range20, range19]]] &&
        zeroPairQ[connection[[All, range20, range17]]],
      "Raw1917ExactlyZero" ->
        zeroPairQ[connection[[All, range19, range17]]]|>;
    If[! And @@ Values[structuralChecks],
      fail["ZeroPathStructuralProofFailed", <|
        "Checks" -> structuralChecks|>]];
    d2117 = ConstantArray[0, {2, Length[range17]}];
    d2116 = ConstantArray[0, {2, Length[range16]}];
    forcing15 = connection[[All, rowRange, range15]];

    rootSquares = {
      1 + 2 sourceVariables[[1]] + sourceVariables[[1]]^2 -
        2 sourceVariables[[2]] +
        2 sourceVariables[[1]] sourceVariables[[2]] +
        sourceVariables[[2]]^2,
      1 - 2 sourceVariables[[1]] + sourceVariables[[1]]^2 +
        2 sourceVariables[[2]] +
        2 sourceVariables[[1]] sourceVariables[[2]] +
        sourceVariables[[2]]^2,
      1 - 4 sourceVariables[[1]] sourceVariables[[2]]};
    frameVariables = {Symbol["CF303Sector2115Kallen3`p"],
      Symbol["CF303Sector2115Kallen3`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, sourceVariables, frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, sourceVariables];
    strip15 = {
      connection[[All, rowRange, rowRange]]/regulator,
      connection[[All, range15, range15]]/regulator,
      forcing15};
    classification = FeynFacet`Private`transportChartRootIndices[
      strip15, allRoots];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
          "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]] ||
        ! AssociationQ[classification] ||
        classification["RootIndices"] =!= {2} ||
        classification["UnclassifiedRadicalBases"] =!= {},
      fail["ExactFrameOrRootCensusFailed", <|
        "Classification" -> classification|>]];
    chart = FeynFacet`TransportRootSetChart[
      rootSquares[[classification["RootIndices"]]], sourceVariables];
    If[! AssociationQ[chart] || Lookup[chart, "Name", None] =!= "Kallen3" ||
        ! TrueQ[Lookup[FeynFacet`TransportChartVerify[chart], "OK", False]],
      fail["Kallen3ChartNotExactlySelected"]];

    Print["CF3032115K3V1 stage=solve stripLeaves=", LeafCount[strip15]];
    solveSeconds = First@AbsoluteTiming[
      solveResult = FeynFacet`SolveEpsFormStripInFrame[
        strip15, sourceVariables, regulator, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldFallback" -> True,
        "MultiquadraticDispatch" -> False,
        "CANONICAKernels" -> 5,
        "ScratchDirectory" -> outdir,
        "Tag" -> "CF303_21_15_kallen3_source_v1",
        "FiniteFieldOptions" -> {
          "KernelCount" -> 5,
          "ArtifactDirectory" -> artifactDirectory,
          "ArtifactPrefix" -> "CF303_21_15_kallen3_source_v1",
          "Backend" -> Automatic, "BackendThreads" -> 1,
          "PlanDiscoveryBackend" -> "FLINTAffineRREF",
          "SupportStrategy" -> "SimplexFirst",
          "SupportLearning" -> True,
          "RegulatorSampling" -> "HeldOut",
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "Verbose" -> True]];
    checks = <|
      "ZeroPathStructuralProofPassed" ->
        And @@ Values[structuralChecks],
      "D2117AndD2116ExactlyZero" ->
        zeroMatrixQ[d2117] && zeroMatrixQ[d2116],
      "Forcing2115EqualsRaw" ->
        zeroPairQ[forcing15 - connection[[All, rowRange, range15]]],
      "SolvedStatus" -> AssociationQ[solveResult] &&
        Lookup[solveResult, "Status", None] === "Solved",
      "OnlySecondRootUsed" ->
        Lookup[solveResult, "RootIndices", None] === {2},
      "Kallen3Method" -> StringStartsQ[
        Lookup[solveResult, "Method", ""], "RationalChart/Kallen3/"],
      "ExactDLog" -> TrueQ[Lookup[solveResult, "ExactDLog", False]],
      "GaugeDimensionsExact" ->
        Dimensions[Lookup[solveResult, "Gauge", {}]] === {2, 3},
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
        "Exact", False]],
      "AlphabetEpsilonFree" ->
        FreeQ[Lookup[solveResult, "Alphabet", {}], regulator]|>;
    If[! And @@ Values[checks],
      fail["Kallen3SourceSolveFailed", <|
        "Checks" -> checks,
        "Result" -> If[AssociationQ[solveResult],
          KeyDrop[solveResult, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], solveResult]|>]];

    exportAtomic[<|
      "Status" ->
        "CF303Sector2117And16ZeroSector2115Kallen3SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21,
      "ZeroGaugeLowerSectors" -> {17, 16},
      "D2117" -> d2117, "D2116" -> d2116,
      "LowerSector" -> 15, "SourceStrip" -> strip15,
      "SourceSolution" -> solveResult,
      "StructuralChecks" -> structuralChecks,
      "Checks" -> checks, "SolveSeconds" -> solveSeconds,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" ->
        "CF303Sector2117And16ZeroSector2115Kallen3SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21,
      "ZeroGaugeLowerSectors" -> {17, 16}, "LowerSector" -> 15,
      "Method" -> solveResult["Method"],
      "RootIndices" -> solveResult["RootIndices"],
      "GaugeDimensions" -> Dimensions[solveResult["Gauge"]],
      "GaugeLeafCount" -> LeafCount[solveResult["Gauge"]],
      "AlphabetLength" -> Length[Lookup[solveResult, "Alphabet", {}]],
      "SolveSeconds" -> solveSeconds,
      "StructuralChecks" -> structuralChecks, "Checks" -> checks,
      "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032115K3V1 status=PASS zero={17,16} seconds=",
      Round[solveSeconds, 0.1], " method=", solveResult["Method"]];
    0,
    tag];
  result
]
