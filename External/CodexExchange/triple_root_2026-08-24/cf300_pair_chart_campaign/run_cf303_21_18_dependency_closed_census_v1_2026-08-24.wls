#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    row20CertificateFile, source1918File, solution2120File,
    solution2119File, outdir, censusFile, summaryFile, expectedHashes,
    dependencyFiles, dependencyHashes, hashHex, putAtomic, exportAtomic,
    fail, tag, result, badHashes, state, row20Certificate,
    source1918Payload, solution2120Payload, solution2119Payload,
    solution2120, solution2119, ranges, connection, variables, regulator,
    rowRange, range20, range19, lowerRange, rootSquares, frameVariables,
    frame, allRoots, d2018, d1918, d2120, d2119, matrixTogether,
    currentA2018, currentA1918, base2118, forcing2118, termRecords,
    rootCensus, strip, stripCensus, forcingCensus, activeRootSquares,
    chart, route, currentSeconds, baseSeconds, forcingSeconds,
    forcingChannels, channelSeconds, gradeSupport, gradeRecords,
    reconstructedForcing, zeroNestedQ, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  row20CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1/certificate.wxf";
  source1918File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_19_18_kallen23_source_pullback_v1/source_gauge_19_18.wxf";
  solution2120File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_20_bilinear115_solve_v1/solution.wxf";
  solution2119File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_19_kallen23_source_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_18_dependency_closed_census_v1";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032118DependencyClosedCensusV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140",
    source1918File ->
      "c770cba5c46fc942f2da9c5b057c2b148afc69b0646b087887376ce03b2c7cb6",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5",
    solution2119File ->
      "cd382a49f4dc930f6372861ba103b30d6731869ef63e907b922bd6449c18a5c8"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile|>;

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
      "Sector" -> 21, "LowerSector" -> 18,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->18 DEPENDENCY CENSUS FAILURE V1: ", status,
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
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["HelperCeilingMustBeZero"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];

    state = Get[stateFile];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    source1918Payload = Import[source1918File, "WXF"];
    solution2120Payload = Import[solution2120File, "WXF"];
    solution2119Payload = Import[solution2119File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, row20Certificate,
          source1918Payload, solution2120Payload, solution2119Payload}) ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[source1918Payload, "Status", None] =!=
          "CF303Sector1918Kallen23SourcePullbackPassedV1" ||
        Lookup[solution2120Payload, "Status", None] =!=
          "CF303Sector2120Bilinear115SolvedV1" ||
        Lookup[solution2119Payload, "Status", None] =!=
          "CF303Sector2119MinimalChartSourceSolvedV1",
      fail["InvalidInputABI"]];
    solution2120 = solution2120Payload["Solution"];
    solution2119 = solution2119Payload["SourceSolution"];
    If[! TrueQ[solution2120["FrameCertificate"]["Exact"]] ||
        ! TrueQ[solution2119["FrameCertificate"]["Exact"]],
      fail["PinnedSector21SolutionsNotExact"]];
    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[21]];
    range20 = ranges[[20]];
    range19 = ranges[[19]];
    lowerRange = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || lowerRange =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector21Census`p"],
      Symbol["CF303Sector21Census`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    rootCensus[expression_] := Module[{record},
      record = FeynFacet`Private`transportChartRootIndices[
        expression, allRoots];
      If[! AssociationQ[record] ||
          Lookup[record, "UnclassifiedRadicalBases", {1}] =!= {},
        fail["UnclassifiedRadical", <|"Census" -> record|>]];
      record];
    matrixTogether[matrix_] := Map[Together, matrix, {2}];
    zeroNestedQ[expression_] := AllTrue[Flatten[expression],
      TrueQ[Together[#] === 0] &];

    d2018 = row20Certificate["SolvedSourceGauges"][18];
    d1918 = source1918Payload["SourceGauge"];
    d2120 = solution2120["Gauge"];
    d2119 = solution2119["Gauge"];
    If[Dimensions /@ {d2018, d1918, d2120, d2119} =!=
        {{2, 2}, {4, 2}, {2, 2}, {2, 4}},
      fail["UnexpectedGaugeShapes"]];

    Print["CF3032118CENSUSV1 stage=current-lower-blocks"];
    currentSeconds = First@AbsoluteTiming[
      currentA2018 = Table[matrixTogether[
        connection[[mu, range20, lowerRange]] +
          regulator ((connection[[mu, range20, range20]]/regulator) .
            d2018 - d2018 .
            (connection[[mu, lowerRange, lowerRange]]/regulator)) -
          D[d2018, variables[[mu]]]], {mu, 2}];
      currentA1918 = Table[matrixTogether[
        connection[[mu, range19, lowerRange]] +
          regulator ((connection[[mu, range19, range19]]/regulator) .
            d1918 - d1918 .
            (connection[[mu, lowerRange, lowerRange]]/regulator)) -
          D[d1918, variables[[mu]]]], {mu, 2}]];
    Print["CF3032118CENSUSV1 stage=base currentSeconds=",
      Round[currentSeconds, 0.1]];
    baseSeconds = First@AbsoluteTiming[
      base2118 = Table[matrixTogether[
        connection[[mu, rowRange, lowerRange]] +
          connection[[mu, rowRange, range19]] . d1918 +
          connection[[mu, rowRange, range20]] . d2018], {mu, 2}]];
    Print["CF3032118CENSUSV1 stage=forcing baseSeconds=",
      Round[baseSeconds, 0.1]];
    forcingSeconds = First@AbsoluteTiming[
      forcing2118 = Table[matrixTogether[
        base2118[[mu]] - d2120 . currentA2018[[mu]] -
          d2119 . currentA1918[[mu]]], {mu, 2}]];

    termRecords = <|
      "Raw2118" -> rootCensus[connection[[All, rowRange, lowerRange]]],
      "Prior1918Path" -> rootCensus[Table[
        connection[[mu, rowRange, range19]] . d1918, {mu, 2}]],
      "Prior2018Path" -> rootCensus[Table[
        connection[[mu, rowRange, range20]] . d2018, {mu, 2}]],
      "CurrentA1918" -> rootCensus[currentA1918],
      "CurrentA2018" -> rootCensus[currentA2018],
      "New2119Path" -> rootCensus[Table[
        d2119 . currentA1918[[mu]], {mu, 2}]],
      "New2120Path" -> rootCensus[Table[
        d2120 . currentA2018[[mu]], {mu, 2}]]|>;
    forcingCensus = rootCensus[forcing2118];
    strip = {
      connection[[All, rowRange, rowRange]]/regulator,
      connection[[All, lowerRange, lowerRange]]/regulator,
      forcing2118};
    stripCensus = rootCensus[strip];
    activeRootSquares = Lookup[
      allRoots[[stripCensus["RootIndices"]]], "RootSquare", {}];
    chart = FeynFacet`TransportRootSetChart[activeRootSquares, variables];
    route = If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
      "NoJointRationalChart"];

    Print["CF3032118CENSUSV1 stage=exact-grade-decomposition roots=",
      stripCensus["RootIndices"], " route=", route,
      " forcingSeconds=", Round[forcingSeconds, 0.1]];
    channelSeconds = First@AbsoluteTiming[
      forcingChannels = Map[
        FeynFacet`Private`multiquadraticFieldDecompose[#, allRoots] &,
        forcing2118, {3}]];
    If[! FreeQ[forcingChannels, $Failed],
      fail["ExactGradeDecompositionFailed"]];
    gradeSupport = Table[
      ! zeroNestedQ[forcingChannels[[All, All, All, grade]]],
      {grade, 1, 8}];
    gradeRecords = Table[<|
      "GradeIndexZeroBased" -> grade - 1,
      "RootMask" -> Table[BitGet[grade - 1, bit], {bit, 0, 2}],
      "Nonzero" -> gradeSupport[[grade]],
      "LeafCount" -> LeafCount[
        forcingChannels[[All, All, All, grade]]]|>, {grade, 1, 8}];
    reconstructedForcing = Map[
      FeynFacet`Private`multiquadraticFieldCompose[#, allRoots] &,
      forcingChannels, {3}];
    checks = <|
      "AllInputsExactlyCertified" ->
        TrueQ[solution2120["FrameCertificate"]["Exact"]] &&
        TrueQ[solution2119["FrameCertificate"]["Exact"]] &&
        And @@ Values[source1918Payload["Checks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "ForcingCompositionRoundTrip" ->
        zeroNestedQ[reconstructedForcing - forcing2118],
      "RootClassifierMatchesGradeSupport" ->
        Sort[DeleteDuplicates@Flatten@Map[
          Flatten@Position[
            Table[BitGet[# - 1, bit], {bit, 0, 2}], 1] &,
          Flatten@Position[gradeSupport, True]]] ===
          forcingCensus["RootIndices"],
      "StripAndForcingRootSetsAgree" ->
        stripCensus["RootIndices"] === forcingCensus["RootIndices"],
      "RouteTyped" -> StringQ[route]|>;
    If[! And @@ Values[checks],
      fail["DependencyClosedCensusChecksFailed", <|
        "Checks" -> checks, "ForcingCensus" -> forcingCensus,
        "GradeRecords" -> gradeRecords|>]];
    exportAtomic[<|
      "Status" -> "CF303Sector2118DependencyClosedCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 18,
      "Variables" -> variables, "Regulator" -> regulator,
      "Strip" -> strip, "AssembledForcing" -> forcing2118,
      "CurrentA2018" -> currentA2018,
      "CurrentA1918" -> currentA1918,
      "Base2118" -> base2118,
      "TermRootCensuses" -> termRecords,
      "ForcingRootCensus" -> forcingCensus,
      "StripRootCensus" -> stripCensus,
      "ForcingGradeChannels" -> forcingChannels,
      "GradeRecords" -> gradeRecords,
      "SelectedRoute" -> route, "Checks" -> checks,
      "Timings" -> <|"CurrentLowerBlocks" -> currentSeconds,
        "Base" -> baseSeconds, "Forcing" -> forcingSeconds,
        "GradeDecomposition" -> channelSeconds|>,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, censusFile];
    summary = <|
      "Status" -> "CF303Sector2118DependencyClosedCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 18,
      "ForcingRootIndices" -> forcingCensus["RootIndices"],
      "StripRootIndices" -> stripCensus["RootIndices"],
      "NonzeroGrades" -> Lookup[
        Select[gradeRecords, TrueQ[Lookup[#, "Nonzero", False]] &],
        "GradeIndexZeroBased", {}],
      "SelectedRoute" -> route,
      "ForcingLeafCount" -> LeafCount[forcing2118],
      "StripLeafCount" -> LeafCount[strip],
      "Checks" -> checks,
      "Timings" -> <|"CurrentLowerBlocks" -> currentSeconds,
        "Base" -> baseSeconds, "Forcing" -> forcingSeconds,
        "GradeDecomposition" -> channelSeconds|>,
      "CensusFile" -> censusFile,
      "CensusSHA256" -> hashHex[censusFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringCensus"]];
    Print["CF3032118CENSUSV1 status=PASS roots=",
      stripCensus["RootIndices"], " nonzeroGrades=",
      summary["NonzeroGrades"], " route=", route];
    0,
    tag];
  result
]
