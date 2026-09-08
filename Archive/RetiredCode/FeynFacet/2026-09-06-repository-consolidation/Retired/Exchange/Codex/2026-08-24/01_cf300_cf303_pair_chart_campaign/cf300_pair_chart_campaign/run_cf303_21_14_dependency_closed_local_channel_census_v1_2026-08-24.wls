#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, familyRowFile,
    stateFile, row18CertificateFile, row19CertificateFile,
    row20CertificateFile, row18Block14File, row19Block14File,
    row20Block14File, solution2120File, solution2119File,
    solution2118File, solution2115File, outdir, censusFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, row18Certificate,
    row19Certificate, row20Certificate, row18Block14Payload,
    row19Block14Payload, row20Block14Payload, solution2120Payload,
    solution2119Payload, solution2118Payload, solution2115Payload,
    solution1814, solution1914, solution2014, solution2120,
    solution2119, solution2118, solution2115, solutionExactlyCertifiedQ,
    ranges, connection,
    variables, regulator, rowRange, range20, range19, range18, range17,
    range16, range15, lowerRange, rootSquares, frameVariables, frame,
    allRoots, deltas, d1814, d1914, d2014, d2120, d2119, d2118,
    d2117, d2116, d2115, currentA1814, currentA1914, currentA2014,
    currentA1514, zeroNestedQ, zeroMatrixQ, localRankHistogram,
    localRootSetHistogram, localDecomposeScalar, decomposePair,
    decomposeMatrix, fullDecomposePair, composePair, gradeSupportOf,
    rootsFromGradeSupport, gradeRecord, channelProduct,
    e21Channels, c14Channels, d1814Channels, d1914Channels,
    d2014Channels, d2120Channels, d2119Channels, d2118Channels,
    d2115Channels, currentA1814Channels, currentA1914Channels,
    currentA2014Channels, currentA1514Channels, a2114Channels,
    a2120Channels, a2119Channels, a2118Channels, prior2014PathChannels,
    prior1914PathChannels, prior1814PathChannels, base2114Channels,
    new2120PathChannels, new2119PathChannels, new2118PathChannels,
    new2115PathChannels, forcing2114Channels, forcing2114,
    fullRankForcingChannels, fullRankDifference,
    forcingRoundTripChannels, roundTripDifference,
    roundTripComposedDifference, roundTripDifferencePositions,
    structuralChecks, strip, termGradeSupports, termRecords,
    forcingGradeSupport, diagonal21GradeSupport, diagonal14GradeSupport,
    stripGradeSupport, forcingRootIndices, stripRootIndices,
    classifierForcing, classifierStrip, activeRootSquares, chart, route,
    materializeSeconds, decompositionSeconds, baseSeconds, forcingSeconds,
    composeSeconds, fullRankSeconds, roundTripSeconds, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  familyRowFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FamilyRowGauge.wl"}];
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
  row18Block14File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_campaign_v1/" <>
    "block_14_attempt_1/solution.wxf";
  row19Block14File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_14_attempt_1/solution.wxf";
  row20Block14File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1/" <>
    "block_14_attempt_1/solution.wxf";
  solution2120File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_20_bilinear115_solve_v1/solution.wxf";
  solution2119File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_19_kallen23_source_solve_v1/solution.wxf";
  solution2118File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_18_kallen2_source_solve_v1/solution.wxf";
  solution2115File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_17_16_zero_15_kallen3_source_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_14_dependency_closed_local_channel_census_v1_retry";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032114DependencyClosedLocalChannelCensusV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    familyRowFile ->
      "ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140",
    row18Block14File ->
      "f8569513077508ac5ae1b6d7c414f0c9d73877456157b87b675bc879f360158e",
    row19Block14File ->
      "6d0b8c3fa59f0136b7d2f083ed04408036ca08f6802bfe319125c897fe264e3f",
    row20Block14File ->
      "8a0915108dce892c32295f7991c8d0e2c4b83172c5427875dacba46f10427b44",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5",
    solution2119File ->
      "cd382a49f4dc930f6372861ba103b30d6731869ef63e907b922bd6449c18a5c8",
    solution2118File ->
      "f9e89a247594a7f9b2e079e1195344decc3d0d1f8107f5a30d1b499b73332956",
    solution2115File ->
      "d4e8e7452972596dc8156db500cb442e1a58e473464561067dc3e84ef5184405"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile,
    "FamilyRowGauge" -> familyRowFile|>;

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
      "Sector" -> 21, "LowerSector" -> 14,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->14 LOCAL CHANNEL CENSUS FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]];

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {}, fail["WrapperTakesNoArguments"]];
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
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    row18Block14Payload = Import[row18Block14File, "WXF"];
    row19Block14Payload = Import[row19Block14File, "WXF"];
    row20Block14Payload = Import[row20Block14File, "WXF"];
    solution2120Payload = Import[solution2120File, "WXF"];
    solution2119Payload = Import[solution2119File, "WXF"];
    solution2118Payload = Import[solution2118File, "WXF"];
    solution2115Payload = Import[solution2115File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, row18Certificate,
          row19Certificate, row20Certificate, row18Block14Payload,
          row19Block14Payload, row20Block14Payload, solution2120Payload,
          solution2119Payload, solution2118Payload, solution2115Payload}) ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[row18Block14Payload, "Status", None] =!=
          "CF303Sector18PairChartDLogSolutionV1" ||
        Lookup[row19Block14Payload, "Status", None] =!=
          "CF303Sector19PairChartDLogSolutionV1" ||
        Lookup[row20Block14Payload, "Status", None] =!=
          "CF303Sector20MinimalChartDLogSolutionV1" ||
        Lookup[solution2120Payload, "Status", None] =!=
          "CF303Sector2120Bilinear115SolvedV1" ||
        Lookup[solution2119Payload, "Status", None] =!=
          "CF303Sector2119MinimalChartSourceSolvedV1" ||
        Lookup[solution2118Payload, "Status", None] =!=
          "CF303Sector2118Kallen2SourceSolvedV1" ||
        Lookup[solution2115Payload, "Status", None] =!=
          "CF303Sector2117And16ZeroSector2115Kallen3SourceSolvedV1",
      fail["InvalidInputABI"]];
    solution1814 = row18Block14Payload["Solution"];
    solution1914 = row19Block14Payload["Solution"];
    solution2014 = row20Block14Payload["Solution"];
    solution2120 = solution2120Payload["Solution"];
    solution2119 = solution2119Payload["SourceSolution"];
    solution2118 = solution2118Payload["SourceSolution"];
    solution2115 = solution2115Payload["SourceSolution"];
    solutionExactlyCertifiedQ[solution_Association] := If[
      Lookup[solution, "Method", None] === "ZeroForcing",
      TrueQ[Lookup[solution, "ExactDLog", False]] &&
        TrueQ[Lookup[solution, "DLogFormCertified", False]] &&
        AllTrue[Flatten[Lookup[solution, "Gauge", {$Failed}]],
          TrueQ[# === 0] &],
      TrueQ[Lookup[Lookup[solution, "FrameCertificate", <||>],
        "Exact", False]]];
    If[! And @@ (AssociationQ /@ {solution1814, solution1914,
          solution2014, solution2120, solution2119, solution2118,
          solution2115}) ||
        ! (And @@ (solutionExactlyCertifiedQ /@ {solution1814,
              solution1914, solution2014, solution2120, solution2119,
              solution2118, solution2115})),
      fail["PinnedSolutionsNotExactlyCertified"]];

    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[21]];
    range20 = ranges[[20]];
    range19 = ranges[[19]];
    range18 = ranges[[18]];
    range17 = ranges[[17]];
    range16 = ranges[[16]];
    range15 = ranges[[15]];
    lowerRange = ranges[[14]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || range18 =!= {29, 30} ||
        range17 =!= {28} || range16 =!= {26, 27} ||
        range15 =!= {23, 24, 25} || lowerRange =!= {21, 22},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector2114LocalChannelCensus`p"],
      Symbol["CF303Sector2114LocalChannelCensus`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
          "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]] ||
        ! ListQ[allRoots] || Length[allRoots] =!= 3 ||
        ! AllTrue[MapThread[Function[{root, square},
          TrueQ[Together[root["RootSquare"] - square] === 0]],
          {allRoots, rootSquares}], TrueQ],
      fail["PinnedRootABIInvalid"]];
    deltas = Lookup[allRoots, "RootSquare", {}];
    zeroNestedQ[expression_] := AllTrue[Flatten[expression],
      TrueQ[Together[#] === 0] &];
    zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];

    d1814 = row18Certificate["SolvedChartGauges"][14];
    d1914 = row19Certificate["SolvedChartGauges"][14];
    d2014 = row20Certificate["SolvedSourceGauges"][14];
    d2120 = solution2120["Gauge"];
    d2119 = solution2119["Gauge"];
    d2118 = solution2118["Gauge"];
    d2117 = solution2115Payload["D2117"];
    d2116 = solution2115Payload["D2116"];
    d2115 = solution2115["Gauge"];
    If[Dimensions /@ {d1814, d1914, d2014, d2120, d2119, d2118,
          d2117, d2116, d2115} =!=
        {{2, 2}, {4, 2}, {2, 2}, {2, 2}, {2, 4}, {2, 2},
          {2, 1}, {2, 2}, {2, 3}},
      fail["UnexpectedGaugeShapes"]];

    Print["CF3032114LOCALV1 stage=materialize-current-blocks"];
    materializeSeconds = First@AbsoluteTiming[
      currentA1814 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution1814, variables, regulator, {2, 2}];
      currentA1914 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution1914, variables, regulator, {4, 2}];
      currentA2014 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution2014, variables, regulator, {2, 2}];
      currentA1514 = connection[[All, range15, lowerRange]]];
    If[! And @@ (ListQ /@ {currentA1814, currentA1914,
          currentA2014, currentA1514}) ||
        Dimensions /@ {currentA1814, currentA1914, currentA2014,
          currentA1514} =!= {{2, 2, 2}, {2, 4, 2}, {2, 2, 2},
          {2, 3, 2}} ||
        ! FreeQ[{currentA1814, currentA1914, currentA2014,
          currentA1514}, Alternatives[_Missing, Automatic, $Failed]],
      fail["CurrentLowerBlockMaterializationFailed"]];

    structuralChecks = <|
      "AllPriorRowCertificatesPassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]] &&
        And @@ Values[row19Certificate["GlobalChecks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "Row18Gauge14ExactlyZero" -> zeroMatrixQ[d1814],
      "Row19Gauge14ExactlyZero" -> zeroMatrixQ[d1914],
      "Row18CurrentA14ExactlyZero" -> zeroNestedQ[currentA1814],
      "Row19CurrentA14ExactlyZero" -> zeroNestedQ[currentA1914],
      "Row20Gauge14MatchesPinnedSolution" ->
        zeroMatrixQ[d2014 - solution2014["Gauge"]],
      "D2117AndD2116ExactlyZero" ->
        zeroMatrixQ[d2117] && zeroMatrixQ[d2116],
      "Raw2117And2116ExactlyZero" ->
        zeroNestedQ[connection[[All, rowRange, range17]]] &&
        zeroNestedQ[connection[[All, rowRange, range16]]],
      "PinnedZeroBlockMethods" ->
        solution1814["Method"] === "ZeroForcing" &&
        solution1914["Method"] === "ZeroForcing"|>;
    If[! And @@ Values[structuralChecks],
      fail["DependencyClosureStructuralChecksFailed", <|
        "Checks" -> structuralChecks|>]];

    localRankHistogram = AssociationThread[Range[0, 3],
      ConstantArray[0, 4]];
    localRootSetHistogram = <||>;
    localDecomposeScalar[expression_] := Module[
      {classification, indices, localChannels, globalChannels,
       reconstructed, rootSetKey},
      classification = FeynFacet`Private`transportChartRootIndices[
        expression, allRoots];
      If[! AssociationQ[classification] ||
          Lookup[classification, "UnclassifiedRadicalBases", {1}] =!= {},
        Return[$Failed]];
      indices = Lookup[classification, "RootIndices", $Failed];
      If[! ListQ[indices] || ! VectorQ[indices, IntegerQ], Return[$Failed]];
      localChannels = FeynFacet`Private`multiquadraticFieldDecompose[
        expression, allRoots[[indices]]];
      If[localChannels === $Failed, Return[$Failed]];
      globalChannels = FeynFacet`Private`multiquadraticLiftLocalChannels[
        localChannels, indices, 3];
      If[globalChannels === $Failed, Return[$Failed]];
      reconstructed = FeynFacet`Private`multiquadraticFieldCompose[
        globalChannels, allRoots];
      If[reconstructed === $Failed ||
          ! TrueQ[Together[reconstructed - expression] === 0],
        Return[$Failed]];
      AssociateTo[localRankHistogram, Length[indices] ->
        (Lookup[localRankHistogram, Length[indices], 0] + 1)];
      rootSetKey = ToString[indices, InputForm];
      AssociateTo[localRootSetHistogram, rootSetKey ->
        (Lookup[localRootSetHistogram, rootSetKey, 0] + 1)];
      globalChannels];
    decomposePair[pair_] := Map[localDecomposeScalar, pair, {3}];
    decomposeMatrix[matrix_] := Map[localDecomposeScalar, matrix, {2}];
    fullDecomposePair[pair_] := Map[
      FeynFacet`Private`multiquadraticFieldDecompose[#, allRoots] &,
      pair, {3}];
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

    Print["CF3032114LOCALV1 stage=local-decompose materializeSeconds=",
      Round[materializeSeconds, 0.1]];
    decompositionSeconds = First@AbsoluteTiming[
      e21Channels = decomposePair[
        connection[[All, rowRange, rowRange]]/regulator];
      c14Channels = decomposePair[
        connection[[All, lowerRange, lowerRange]]/regulator];
      d1814Channels = decomposeMatrix[d1814];
      d1914Channels = decomposeMatrix[d1914];
      d2014Channels = decomposeMatrix[d2014];
      d2120Channels = decomposeMatrix[d2120];
      d2119Channels = decomposeMatrix[d2119];
      d2118Channels = decomposeMatrix[d2118];
      d2115Channels = decomposeMatrix[d2115];
      currentA1814Channels = decomposePair[currentA1814];
      currentA1914Channels = decomposePair[currentA1914];
      currentA2014Channels = decomposePair[currentA2014];
      currentA1514Channels = decomposePair[currentA1514];
      a2114Channels = decomposePair[
        connection[[All, rowRange, lowerRange]]];
      a2120Channels = decomposePair[
        connection[[All, rowRange, range20]]];
      a2119Channels = decomposePair[
        connection[[All, rowRange, range19]]];
      a2118Channels = decomposePair[
        connection[[All, rowRange, range18]]]];
    If[! FreeQ[{e21Channels, c14Channels, d1814Channels,
          d1914Channels, d2014Channels, d2120Channels, d2119Channels,
          d2118Channels, d2115Channels, currentA1814Channels,
          currentA1914Channels, currentA2014Channels,
          currentA1514Channels, a2114Channels, a2120Channels,
          a2119Channels, a2118Channels}, $Failed],
      fail["ExactLocalLeafDecompositionFailed", <|
        "LocalRankHistogram" -> localRankHistogram,
        "LocalRootSetHistogram" -> localRootSetHistogram|>]];

    Print["CF3032114LOCALV1 stage=base localSeconds=",
      Round[decompositionSeconds, 0.1], " rankHistogram=",
      localRankHistogram];
    baseSeconds = First@AbsoluteTiming[
      prior2014PathChannels = Table[
        channelProduct[a2120Channels[[mu]], d2014Channels], {mu, 2}];
      prior1914PathChannels = Table[
        channelProduct[a2119Channels[[mu]], d1914Channels], {mu, 2}];
      prior1814PathChannels = Table[
        channelProduct[a2118Channels[[mu]], d1814Channels], {mu, 2}];
      base2114Channels = Map[Together,
        a2114Channels + prior2014PathChannels + prior1914PathChannels +
          prior1814PathChannels, {4}]];

    Print["CF3032114LOCALV1 stage=forcing baseSeconds=",
      Round[baseSeconds, 0.1]];
    forcingSeconds = First@AbsoluteTiming[
      new2120PathChannels = Table[
        channelProduct[d2120Channels, currentA2014Channels[[mu]]],
        {mu, 2}];
      new2119PathChannels = Table[
        channelProduct[d2119Channels, currentA1914Channels[[mu]]],
        {mu, 2}];
      new2118PathChannels = Table[
        channelProduct[d2118Channels, currentA1814Channels[[mu]]],
        {mu, 2}];
      new2115PathChannels = Table[
        channelProduct[d2115Channels, currentA1514Channels[[mu]]],
        {mu, 2}];
      forcing2114Channels = Map[Together,
        base2114Channels - new2120PathChannels - new2119PathChannels -
          new2118PathChannels - new2115PathChannels, {4}]];

    termGradeSupports = <|
      "Raw2114" -> gradeSupportOf[a2114Channels],
      "Prior2014Path" -> gradeSupportOf[prior2014PathChannels],
      "Prior1914Path" -> gradeSupportOf[prior1914PathChannels],
      "Prior1814Path" -> gradeSupportOf[prior1814PathChannels],
      "CurrentA2014" -> gradeSupportOf[currentA2014Channels],
      "CurrentA1914" -> gradeSupportOf[currentA1914Channels],
      "CurrentA1814" -> gradeSupportOf[currentA1814Channels],
      "CurrentA1514" -> gradeSupportOf[currentA1514Channels],
      "New2120Path" -> gradeSupportOf[new2120PathChannels],
      "New2119Path" -> gradeSupportOf[new2119PathChannels],
      "New2118Path" -> gradeSupportOf[new2118PathChannels],
      "New2115Path" -> gradeSupportOf[new2115PathChannels]|>;
    termRecords = Association@KeyValueMap[
      #1 -> <|"GradeSupport" -> #2,
        "RootIndices" -> rootsFromGradeSupport[#2],
        "Grades" -> gradeRecord[#2]|> &, termGradeSupports];
    forcingGradeSupport = gradeSupportOf[forcing2114Channels];
    diagonal21GradeSupport = gradeSupportOf[e21Channels];
    diagonal14GradeSupport = gradeSupportOf[c14Channels];
    stripGradeSupport = MapThread[Or,
      {forcingGradeSupport, diagonal21GradeSupport,
        diagonal14GradeSupport}];
    forcingRootIndices = rootsFromGradeSupport[forcingGradeSupport];
    stripRootIndices = rootsFromGradeSupport[stripGradeSupport];
    activeRootSquares = rootSquares[[stripRootIndices]];
    chart = FeynFacet`TransportRootSetChart[activeRootSquares, variables];
    route = If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
      "NoJointRationalChart"];

    Print["CF3032114LOCALV1 stage=compose roots=", stripRootIndices,
      " route=", route, " forcingSeconds=", Round[forcingSeconds, 0.1]];
    composeSeconds = First@AbsoluteTiming[
      forcing2114 = composePair[forcing2114Channels];
      strip = {connection[[All, rowRange, rowRange]]/regulator,
        connection[[All, lowerRange, lowerRange]]/regulator,
        forcing2114}];
    If[! FreeQ[{forcing2114, strip}, $Failed],
      fail["FinalChannelCompositionFailed"]];

    classifierForcing =
      FeynFacet`Private`transportChartRootIndices[forcing2114, allRoots];
    classifierStrip =
      FeynFacet`Private`transportChartRootIndices[strip, allRoots];
    If[! AssociationQ[classifierForcing] ||
        ! AssociationQ[classifierStrip] ||
        Lookup[classifierForcing, "UnclassifiedRadicalBases", {1}] =!= {} ||
        Lookup[classifierStrip, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["FinalRootClassifierUnclassified", <|
        "Forcing" -> classifierForcing, "Strip" -> classifierStrip|>]];

    Print["CF3032114LOCALV1 stage=full-rank-crosscheck"];
    fullRankSeconds = First@AbsoluteTiming[
      fullRankForcingChannels = fullDecomposePair[forcing2114];
      fullRankDifference = Map[Together,
        fullRankForcingChannels - forcing2114Channels, {4}]];
    Print["CF3032114LOCALV1 stage=local-roundtrip fullRankSeconds=",
      Round[fullRankSeconds, 0.1]];
    roundTripSeconds = First@AbsoluteTiming[
      forcingRoundTripChannels = decomposePair[forcing2114];
      roundTripDifference = Map[Together,
        forcingRoundTripChannels - forcing2114Channels, {4}];
      roundTripComposedDifference = composePair[roundTripDifference];
      roundTripDifferencePositions = Position[
        roundTripDifference, Except[0], {4}, Heads -> False]];
    checks = <|
      "AllInputsExactlyCertified" ->
        And @@ Values[structuralChecks] &&
        And @@ (solutionExactlyCertifiedQ /@ {solution1814, solution1914,
            solution2014, solution2120, solution2119, solution2118,
            solution2115}),
      "ZeroDependencyPathsExactlyZero" ->
        zeroNestedQ[prior1914PathChannels] &&
        zeroNestedQ[prior1814PathChannels] &&
        zeroNestedQ[new2119PathChannels] &&
        zeroNestedQ[new2118PathChannels],
      "FullRankCrossCheck" ->
        FreeQ[fullRankForcingChannels, $Failed] &&
        zeroNestedQ[fullRankDifference],
      "FinalForcingChannelRoundTrip" ->
        FreeQ[forcingRoundTripChannels, $Failed] &&
        zeroNestedQ[roundTripDifference],
      "FinalForcingExpressionRoundTrip" ->
        FreeQ[roundTripComposedDifference, $Failed] &&
        zeroNestedQ[roundTripComposedDifference],
      "ForcingClassifierMatchesChannels" ->
        classifierForcing["RootIndices"] === forcingRootIndices,
      "StripClassifierMatchesChannels" ->
        classifierStrip["RootIndices"] === stripRootIndices,
      "RouteTyped" -> StringQ[route]|>;
    If[! And @@ Values[checks],
      fail["DependencyClosedLocalChannelCensusChecksFailed", <|
        "Checks" -> checks,
        "ForcingClassifier" -> classifierForcing,
        "StripClassifier" -> classifierStrip,
        "ForcingGradeSupport" -> forcingGradeSupport,
        "StripGradeSupport" -> stripGradeSupport,
        "RoundTripDifferencePositions" -> roundTripDifferencePositions|>]];

    exportAtomic[<|
      "Status" ->
        "CF303Sector2114DependencyClosedLocalChannelCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 14,
      "Variables" -> variables, "Regulator" -> regulator,
      "Strip" -> strip, "AssembledForcing" -> forcing2114,
      "AssembledForcingChannels" -> forcing2114Channels,
      "Base2114Channels" -> base2114Channels,
      "CurrentA2014" -> currentA2014,
      "CurrentA1514" -> currentA1514,
      "TermGradeRecords" -> termRecords,
      "ForcingGradeRecords" -> gradeRecord[forcingGradeSupport],
      "StripGradeRecords" -> gradeRecord[stripGradeSupport],
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingRootClassifier" -> classifierForcing,
      "StripRootClassifier" -> classifierStrip,
      "SelectedRoute" -> route,
      "LocalRankHistogram" -> localRankHistogram,
      "LocalRootSetHistogram" -> localRootSetHistogram,
      "StructuralChecks" -> structuralChecks, "Checks" -> checks,
      "Timings" -> <|"Materialize" -> materializeSeconds,
        "LocalLeafDecomposition" -> decompositionSeconds,
        "Base" -> baseSeconds, "Forcing" -> forcingSeconds,
        "Compose" -> composeSeconds,
        "FullRankForcingCrossCheck" -> fullRankSeconds,
        "LocalRoundTrip" -> roundTripSeconds|>,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, censusFile];
    summary = <|
      "Status" ->
        "CF303Sector2114DependencyClosedLocalChannelCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 14,
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingNonzeroGrades" -> Flatten@Position[
        forcingGradeSupport, True] - 1,
      "StripNonzeroGrades" -> Flatten@Position[
        stripGradeSupport, True] - 1,
      "SelectedRoute" -> route,
      "ForcingLeafCount" -> LeafCount[forcing2114],
      "ForcingChannelLeafCount" -> LeafCount[forcing2114Channels],
      "LocalRankHistogram" -> localRankHistogram,
      "LocalRootSetHistogram" -> localRootSetHistogram,
      "StructuralChecks" -> structuralChecks, "Checks" -> checks,
      "Timings" -> <|"Materialize" -> materializeSeconds,
        "LocalLeafDecomposition" -> decompositionSeconds,
        "Base" -> baseSeconds, "Forcing" -> forcingSeconds,
        "Compose" -> composeSeconds,
        "FullRankForcingCrossCheck" -> fullRankSeconds,
        "LocalRoundTrip" -> roundTripSeconds|>,
      "CensusFile" -> censusFile,
      "CensusSHA256" -> hashHex[censusFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringCensus"]];
    Print["CF3032114LOCALV1 status=PASS roots=", stripRootIndices,
      " nonzeroGrades=", summary["StripNonzeroGrades"],
      " route=", route, " localSeconds=",
      Round[decompositionSeconds, 0.1], " fullRankForcingSeconds=",
      Round[fullRankSeconds, 0.1]];
    0,
    tag];
  result
]
