#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    row20CertificateFile, source1918File, solution2120File,
    solution2119File, outdir, censusFile, summaryFile, expectedHashes,
    dependencyFiles, dependencyHashes, hashHex, putAtomic, exportAtomic,
    fail, tag, result, badHashes, state, row20Certificate,
    source1918Payload, solution2120Payload, solution2119Payload,
    solution2120, solution2119, ranges, connection, variables, regulator,
    rowRange, range20, range19, lowerRange, range17, rootSquares,
    frameVariables, frame, allRoots, deltas, d2018, d1918, d2120, d2119,
    zeroNestedQ, decomposePair, decomposeMatrix, composePair,
    gradeSupportOf, rootsFromGradeSupport, gradeRecord,
    channelProduct, channelDerivative, e20Channels, e19Channels,
    e21Channels, c18Channels, d2018Channels, d1918Channels,
    d2120Channels, d2119Channels, a2018Channels, a1918Channels,
    a2118Channels, a2119Channels, a2120Channels, prior1918PathChannels,
    prior2018PathChannels, currentA2018Channels, currentA1918Channels,
    new2119PathChannels, new2120PathChannels, base2118Channels,
    forcing2118Channels, forcing2118, forcingRoundTripChannels,
    roundTripDifference, roundTripComposedDifference,
    roundTripDifferencePositions,
    strip, termGradeSupports, termRecords, forcingGradeSupport,
    diagonal21GradeSupport, diagonal18GradeSupport, stripGradeSupport,
    forcingRootIndices, stripRootIndices, classifierForcing,
    classifierStrip, activeRootSquares, chart, route,
    decompositionSeconds, currentSeconds, baseSeconds, forcingSeconds,
    composeSeconds, roundTripSeconds, checks, summary},
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
    "cf303_21_18_dependency_closed_channel_census_v2_diagnostic";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032118DependencyClosedChannelCensusV2$"];
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
    Print["CF303 21->18 CHANNEL CENSUS FAILURE V2: ", status,
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
    range17 = ranges[[17]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || lowerRange =!= {29, 30} ||
        ! AllTrue[Flatten[connection[[All, rowRange, range17]]],
          TrueQ[# === 0] &],
      fail["UnexpectedPinnedStateOrPriorRowPath"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector21ChannelCensus`p"],
      Symbol["CF303Sector21ChannelCensus`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    If[! ListQ[allRoots] || Length[allRoots] =!= 3 ||
        ! AllTrue[MapThread[Function[{root, square},
          TrueQ[Together[root["RootSquare"] - square] === 0]],
          {allRoots, rootSquares}], TrueQ],
      fail["PinnedRootABIInvalid"]];
    deltas = Lookup[allRoots, "RootSquare", {}];
    zeroNestedQ[expression_] := AllTrue[Flatten[expression],
      TrueQ[Together[#] === 0] &];
    decomposePair[pair_] := Map[
      FeynFacet`Private`multiquadraticFieldDecompose[#, allRoots] &,
      pair, {3}];
    decomposeMatrix[matrix_] := Map[
      FeynFacet`Private`multiquadraticFieldDecompose[#, allRoots] &,
      matrix, {2}];
    composePair[channels_] := Map[
      FeynFacet`Private`multiquadraticFieldCompose[#, allRoots] &,
      channels, {3}];
    gradeSupportOf[channels_] := Module[{level = ArrayDepth[channels] - 1},
      Table[! zeroNestedQ[Map[Part[#, grade] &, channels, {level}]],
        {grade, 1, 8}]];
    rootsFromGradeSupport[support_List] := Sort@DeleteDuplicates@Flatten[
      Table[If[TrueQ[support[[grade]]], Flatten@Position[
          Table[BitGet[grade - 1, bit], {bit, 0, 2}], 1], {}],
        {grade, 1, 8}]];
    gradeRecord[support_List] := Table[<|
      "GradeIndexZeroBased" -> grade - 1,
      "RootMask" -> Table[BitGet[grade - 1, bit], {bit, 0, 2}],
      "Nonzero" -> support[[grade]]|>, {grade, 1, 8}];
    channelProduct[left_, right_] := Module[{product},
      product = FeynFacet`Private`multiquadraticStripChannelMatrixProduct[
        left, right, deltas];
      If[product === $Failed, fail["ChannelMatrixDimensionMismatch"]];
      product];
    channelDerivative[gauge_, mu_Integer] := Map[
      FeynFacet`Private`multiquadraticDerivative[
        #, deltas, variables[[mu]]] &, gauge, {2}];

    d2018 = row20Certificate["SolvedSourceGauges"][18];
    d1918 = source1918Payload["SourceGauge"];
    d2120 = solution2120["Gauge"];
    d2119 = solution2119["Gauge"];
    If[Dimensions /@ {d2018, d1918, d2120, d2119} =!=
        {{2, 2}, {4, 2}, {2, 2}, {2, 4}},
      fail["UnexpectedGaugeShapes"]];

    Print["CF3032118CHANNELV2 stage=decompose-leaves"];
    decompositionSeconds = First@AbsoluteTiming[
      e20Channels = decomposePair[
        connection[[All, range20, range20]]/regulator];
      e19Channels = decomposePair[
        connection[[All, range19, range19]]/regulator];
      e21Channels = decomposePair[
        connection[[All, rowRange, rowRange]]/regulator];
      c18Channels = decomposePair[
        connection[[All, lowerRange, lowerRange]]/regulator];
      d2018Channels = decomposeMatrix[d2018];
      d1918Channels = decomposeMatrix[d1918];
      d2120Channels = decomposeMatrix[d2120];
      d2119Channels = decomposeMatrix[d2119];
      a2018Channels = decomposePair[
        connection[[All, range20, lowerRange]]];
      a1918Channels = decomposePair[
        connection[[All, range19, lowerRange]]];
      a2118Channels = decomposePair[
        connection[[All, rowRange, lowerRange]]];
      a2119Channels = decomposePair[
        connection[[All, rowRange, range19]]];
      a2120Channels = decomposePair[
        connection[[All, rowRange, range20]]]];
    If[! FreeQ[{e20Channels, e19Channels, e21Channels, c18Channels,
          d2018Channels, d1918Channels, d2120Channels, d2119Channels,
          a2018Channels, a1918Channels, a2118Channels, a2119Channels,
          a2120Channels}, $Failed],
      fail["ExactLeafDecompositionFailed"]];

    Print["CF3032118CHANNELV2 stage=current-lower-blocks decompositionSeconds=",
      Round[decompositionSeconds, 0.1]];
    currentSeconds = First@AbsoluteTiming[
      currentA2018Channels = Table[Map[Together,
        a2018Channels[[mu]] + regulator (
          channelProduct[e20Channels[[mu]], d2018Channels] -
          channelProduct[d2018Channels, c18Channels[[mu]]]) -
          channelDerivative[d2018Channels, mu], {3}], {mu, 2}];
      currentA1918Channels = Table[Map[Together,
        a1918Channels[[mu]] + regulator (
          channelProduct[e19Channels[[mu]], d1918Channels] -
          channelProduct[d1918Channels, c18Channels[[mu]]]) -
          channelDerivative[d1918Channels, mu], {3}], {mu, 2}]];

    Print["CF3032118CHANNELV2 stage=base currentSeconds=",
      Round[currentSeconds, 0.1]];
    baseSeconds = First@AbsoluteTiming[
      prior1918PathChannels = Table[
        channelProduct[a2119Channels[[mu]], d1918Channels], {mu, 2}];
      prior2018PathChannels = Table[
        channelProduct[a2120Channels[[mu]], d2018Channels], {mu, 2}];
      base2118Channels = Map[Together,
        a2118Channels + prior1918PathChannels + prior2018PathChannels,
        {4}]];

    Print["CF3032118CHANNELV2 stage=forcing baseSeconds=",
      Round[baseSeconds, 0.1]];
    forcingSeconds = First@AbsoluteTiming[
      new2119PathChannels = Table[
        channelProduct[d2119Channels, currentA1918Channels[[mu]]],
        {mu, 2}];
      new2120PathChannels = Table[
        channelProduct[d2120Channels, currentA2018Channels[[mu]]],
        {mu, 2}];
      forcing2118Channels = Map[Together,
        base2118Channels - new2119PathChannels - new2120PathChannels,
        {4}]];

    termGradeSupports = <|
      "Raw2118" -> gradeSupportOf[a2118Channels],
      "Prior1918Path" -> gradeSupportOf[prior1918PathChannels],
      "Prior2018Path" -> gradeSupportOf[prior2018PathChannels],
      "CurrentA1918" -> gradeSupportOf[currentA1918Channels],
      "CurrentA2018" -> gradeSupportOf[currentA2018Channels],
      "New2119Path" -> gradeSupportOf[new2119PathChannels],
      "New2120Path" -> gradeSupportOf[new2120PathChannels]|>;
    termRecords = Association@KeyValueMap[
      #1 -> <|"GradeSupport" -> #2,
        "RootIndices" -> rootsFromGradeSupport[#2],
        "Grades" -> gradeRecord[#2]|> &, termGradeSupports];
    forcingGradeSupport = gradeSupportOf[forcing2118Channels];
    diagonal21GradeSupport = gradeSupportOf[e21Channels];
    diagonal18GradeSupport = gradeSupportOf[c18Channels];
    stripGradeSupport = MapThread[Or,
      {forcingGradeSupport, diagonal21GradeSupport,
        diagonal18GradeSupport}];
    forcingRootIndices = rootsFromGradeSupport[forcingGradeSupport];
    stripRootIndices = rootsFromGradeSupport[stripGradeSupport];
    activeRootSquares = rootSquares[[stripRootIndices]];
    chart = FeynFacet`TransportRootSetChart[activeRootSquares, variables];
    route = If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
      "NoJointRationalChart"];

    Print["CF3032118CHANNELV2 stage=compose roots=", stripRootIndices,
      " route=", route, " forcingSeconds=", Round[forcingSeconds, 0.1]];
    composeSeconds = First@AbsoluteTiming[
      forcing2118 = composePair[forcing2118Channels];
      strip = {connection[[All, rowRange, rowRange]]/regulator,
        connection[[All, lowerRange, lowerRange]]/regulator,
        forcing2118}];
    If[! FreeQ[{forcing2118, strip}, $Failed],
      fail["FinalChannelCompositionFailed"]];

    classifierForcing =
      FeynFacet`Private`transportChartRootIndices[forcing2118, allRoots];
    classifierStrip =
      FeynFacet`Private`transportChartRootIndices[strip, allRoots];
    If[! AssociationQ[classifierForcing] ||
        ! AssociationQ[classifierStrip] ||
        Lookup[classifierForcing, "UnclassifiedRadicalBases", {1}] =!= {} ||
        Lookup[classifierStrip, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["FinalRootClassifierUnclassified", <|
        "Forcing" -> classifierForcing, "Strip" -> classifierStrip|>]];
    Print["CF3032118CHANNELV2 stage=roundtrip"];
    roundTripSeconds = First@AbsoluteTiming[
      forcingRoundTripChannels = decomposePair[forcing2118];
      roundTripDifference = Map[Together,
        forcingRoundTripChannels - forcing2118Channels, {4}];
      roundTripComposedDifference = composePair[roundTripDifference];
      roundTripDifferencePositions = Position[
        roundTripDifference, Except[0], {4}, Heads -> False]];
    checks = <|
      "AllInputsExactlyCertified" ->
        TrueQ[solution2120["FrameCertificate"]["Exact"]] &&
        TrueQ[solution2119["FrameCertificate"]["Exact"]] &&
        And @@ Values[source1918Payload["Checks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "Raw2117PriorPathExactlyZero" ->
        AllTrue[Flatten[connection[[All, rowRange, range17]]],
          TrueQ[# === 0] &],
      "FinalForcingChannelRoundTrip" ->
        ! FreeQ[forcingRoundTripChannels, $Failed] &&
        zeroNestedQ[roundTripDifference],
      "FinalForcingExpressionRoundTrip" ->
        ! FreeQ[roundTripComposedDifference, $Failed] &&
        zeroNestedQ[roundTripComposedDifference],
      "ForcingClassifierMatchesChannels" ->
        classifierForcing["RootIndices"] === forcingRootIndices,
      "StripClassifierMatchesChannels" ->
        classifierStrip["RootIndices"] === stripRootIndices,
      "RouteTyped" -> StringQ[route]|>;
    If[! And @@ Values[checks],
      fail["DependencyClosedChannelCensusChecksFailed", <|
        "Checks" -> checks,
        "ForcingClassifier" -> classifierForcing,
        "StripClassifier" -> classifierStrip,
        "ForcingGradeSupport" -> forcingGradeSupport,
        "StripGradeSupport" -> stripGradeSupport,
        "RoundTripDifferencePositions" -> roundTripDifferencePositions,
        "RoundTripDifferenceLeafCount" -> LeafCount[roundTripDifference],
        "RoundTripComposedDifferenceZero" ->
          zeroNestedQ[roundTripComposedDifference]|>]];

    exportAtomic[<|
      "Status" -> "CF303Sector2118DependencyClosedChannelCensusPassedV2",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 18,
      "Variables" -> variables, "Regulator" -> regulator,
      "Strip" -> strip, "AssembledForcing" -> forcing2118,
      "AssembledForcingChannels" -> forcing2118Channels,
      "CurrentA2018Channels" -> currentA2018Channels,
      "CurrentA1918Channels" -> currentA1918Channels,
      "Base2118Channels" -> base2118Channels,
      "TermGradeRecords" -> termRecords,
      "ForcingGradeRecords" -> gradeRecord[forcingGradeSupport],
      "StripGradeRecords" -> gradeRecord[stripGradeSupport],
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingRootClassifier" -> classifierForcing,
      "StripRootClassifier" -> classifierStrip,
      "SelectedRoute" -> route, "Checks" -> checks,
      "Timings" -> <|"LeafDecomposition" -> decompositionSeconds,
        "CurrentLowerBlocks" -> currentSeconds, "Base" -> baseSeconds,
        "Forcing" -> forcingSeconds, "Compose" -> composeSeconds,
        "RoundTrip" -> roundTripSeconds|>,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, censusFile];
    summary = <|
      "Status" -> "CF303Sector2118DependencyClosedChannelCensusPassedV2",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 18,
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingNonzeroGrades" -> Flatten@Position[
        forcingGradeSupport, True] - 1,
      "StripNonzeroGrades" -> Flatten@Position[
        stripGradeSupport, True] - 1,
      "SelectedRoute" -> route,
      "ForcingLeafCount" -> LeafCount[forcing2118],
      "ForcingChannelLeafCount" -> LeafCount[forcing2118Channels],
      "Checks" -> checks,
      "Timings" -> <|"LeafDecomposition" -> decompositionSeconds,
        "CurrentLowerBlocks" -> currentSeconds, "Base" -> baseSeconds,
        "Forcing" -> forcingSeconds, "Compose" -> composeSeconds,
        "RoundTrip" -> roundTripSeconds|>,
      "CensusFile" -> censusFile,
      "CensusSHA256" -> hashHex[censusFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringCensus"]];
    Print["CF3032118CHANNELV2 status=PASS roots=", stripRootIndices,
      " nonzeroGrades=", summary["StripNonzeroGrades"],
      " route=", route];
    0,
    tag];
  result
]
