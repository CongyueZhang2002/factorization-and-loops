#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, familyRowFile,
    stateFile, row18CertificateFile, row19CertificateFile,
    row20CertificateFile, row18Block13File, row19Block13File,
    row20Block13File, solution2120File, solution2119File,
    solution2118File, solution2115File, solution2114File, outdir,
    censusFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, row18Certificate,
    row19Certificate, row20Certificate, row18Block13Payload,
    row19Block13Payload, row20Block13Payload, solution2120Payload,
    solution2119Payload, solution2118Payload, solution2115Payload,
    solution2114Payload,
    solution1813, solution1913, solution2013, solution2120,
    solution2119, solution2118, solution2115, solution2114,
    solutionExactlyCertifiedQ,
    ranges, connection,
    variables, regulator, rowRange, range20, range19, range18, range17,
    range16, range15, range14, lowerRange, rootSquares, frameVariables, frame,
    allRoots, deltas, d1813, d1913, d2013, d2120, d2119, d2118,
    d2117, d2116, d2115, d2114, currentA1813, currentA1913,
    currentA2013, currentA1513, currentA1413, zeroNestedQ, zeroMatrixQ,
    localRankHistogram,
    localRootSetHistogram, localDecomposeScalar, decomposePair,
    decomposeMatrix, fullDecomposePair, composePair, gradeSupportOf,
    rootsFromGradeSupport, gradeRecord, channelProduct,
    e21Channels, c13Channels, d1813Channels, d1913Channels,
    d2013Channels, d2120Channels, d2119Channels, d2118Channels,
    d2115Channels, d2114Channels, currentA1813Channels,
    currentA1913Channels, currentA2013Channels, currentA1513Channels,
    currentA1413Channels, a2113Channels,
    a2120Channels, a2119Channels, a2118Channels, prior2013PathChannels,
    prior1913PathChannels, prior1813PathChannels, base2113Channels,
    new2120PathChannels, new2119PathChannels, new2118PathChannels,
    new2115PathChannels, new2114PathChannels, forcing2113Channels,
    forcing2113,
    fullRankForcingChannels, fullRankDifference,
    forcingRoundTripChannels, roundTripDifference,
    roundTripComposedDifference, roundTripDifferencePositions,
    structuralChecks, strip, termGradeSupports, termRecords,
    forcingGradeSupport, diagonal21GradeSupport, diagonal13GradeSupport,
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
  row18Block13File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_campaign_v1/" <>
    "block_13_attempt_1/solution.wxf";
  row19Block13File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_13_attempt_1/solution.wxf";
  row20Block13File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1/" <>
    "block_13_attempt_1/solution.wxf";
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
  solution2114File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_14_kallen3_source_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_13_dependency_closed_local_channel_census_v1_retry2";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032113DependencyClosedLocalChannelCensusV1$"];
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
    row18Block13File ->
      "fd5f6440df4deda314273f08e99da879b2d7c73e2ce838be593b9d9754e21e54",
    row19Block13File ->
      "355b135b4634a00110798b0138ed2eacb0aa59513ce49f355ae4a8a48f7e037c",
    row20Block13File ->
      "62f3083bdf77117fec0d6939db95c70a22b67312b5fe88fcd011dbd1c1894e79",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5",
    solution2119File ->
      "cd382a49f4dc930f6372861ba103b30d6731869ef63e907b922bd6449c18a5c8",
    solution2118File ->
      "f9e89a247594a7f9b2e079e1195344decc3d0d1f8107f5a30d1b499b73332956",
    solution2115File ->
      "d4e8e7452972596dc8156db500cb442e1a58e473464561067dc3e84ef5184405",
    solution2114File ->
      "8e8c1c38e0f3d6b243ac40e2bc7d5dc616a8d92f49a155057226b381b4d4f926"|>;
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
      "Sector" -> 21, "LowerSector" -> 13,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->13 LOCAL CHANNEL CENSUS FAILURE V1: ", status,
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
    row18Block13Payload = Import[row18Block13File, "WXF"];
    row19Block13Payload = Import[row19Block13File, "WXF"];
    row20Block13Payload = Import[row20Block13File, "WXF"];
    solution2120Payload = Import[solution2120File, "WXF"];
    solution2119Payload = Import[solution2119File, "WXF"];
    solution2118Payload = Import[solution2118File, "WXF"];
    solution2115Payload = Import[solution2115File, "WXF"];
    solution2114Payload = Import[solution2114File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, row18Certificate,
          row19Certificate, row20Certificate, row18Block13Payload,
          row19Block13Payload, row20Block13Payload, solution2120Payload,
          solution2119Payload, solution2118Payload, solution2115Payload,
          solution2114Payload}) ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[row18Block13Payload, "Status", None] =!=
          "CF303Sector18PairChartDLogSolutionV1" ||
        Lookup[row19Block13Payload, "Status", None] =!=
          "CF303Sector19PairChartDLogSolutionV1" ||
        Lookup[row20Block13Payload, "Status", None] =!=
          "CF303Sector20MinimalChartDLogSolutionV1" ||
        Lookup[solution2120Payload, "Status", None] =!=
          "CF303Sector2120Bilinear115SolvedV1" ||
        Lookup[solution2119Payload, "Status", None] =!=
          "CF303Sector2119MinimalChartSourceSolvedV1" ||
        Lookup[solution2118Payload, "Status", None] =!=
          "CF303Sector2118Kallen2SourceSolvedV1" ||
        Lookup[solution2115Payload, "Status", None] =!=
          "CF303Sector2117And16ZeroSector2115Kallen3SourceSolvedV1" ||
        Lookup[solution2114Payload, "Status", None] =!=
          "CF303Sector2114Kallen3SourceSolvedV1",
      fail["InvalidInputABI"]];
    solution1813 = row18Block13Payload["Solution"];
    solution1913 = row19Block13Payload["Solution"];
    solution2013 = row20Block13Payload["Solution"];
    solution2120 = solution2120Payload["Solution"];
    solution2119 = solution2119Payload["SourceSolution"];
    solution2118 = solution2118Payload["SourceSolution"];
    solution2115 = solution2115Payload["SourceSolution"];
    solution2114 = solution2114Payload["SourceSolution"];
    solutionExactlyCertifiedQ[solution_Association] := If[
      Lookup[solution, "Method", None] === "ZeroForcing",
      TrueQ[Lookup[solution, "ExactDLog", False]] &&
        (TrueQ[Lookup[solution, "DLogFormCertified", False]] ||
          TrueQ[Lookup[Lookup[solution, "FrameCertificate", <||>],
            "Exact", False]]) &&
        AllTrue[Flatten[Lookup[solution, "Gauge", {$Failed}]],
          TrueQ[# === 0] &],
      TrueQ[Lookup[Lookup[solution, "FrameCertificate", <||>],
        "Exact", False]]];
    If[! And @@ (AssociationQ /@ {solution1813, solution1913,
          solution2013, solution2120, solution2119, solution2118,
          solution2115, solution2114}) ||
        ! (And @@ (solutionExactlyCertifiedQ /@ {solution1813,
              solution1913, solution2013, solution2120, solution2119,
              solution2118, solution2115, solution2114})),
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
    range14 = ranges[[14]];
    lowerRange = ranges[[13]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || range18 =!= {29, 30} ||
        range17 =!= {28} || range16 =!= {26, 27} ||
        range15 =!= {23, 24, 25} || range14 =!= {21, 22} ||
        lowerRange =!= {17, 18, 19, 20},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector2113LocalChannelCensus`p"],
      Symbol["CF303Sector2113LocalChannelCensus`q"]};
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

    d1813 = row18Certificate["SolvedChartGauges"][13];
    d1913 = row19Certificate["SolvedChartGauges"][13];
    d2013 = row20Certificate["SolvedSourceGauges"][13];
    d2120 = solution2120["Gauge"];
    d2119 = solution2119["Gauge"];
    d2118 = solution2118["Gauge"];
    d2117 = solution2115Payload["D2117"];
    d2116 = solution2115Payload["D2116"];
    d2115 = solution2115["Gauge"];
    d2114 = solution2114["Gauge"];
    If[Dimensions /@ {d1813, d1913, d2013, d2120, d2119, d2118,
          d2117, d2116, d2115, d2114} =!=
        {{2, 4}, {4, 4}, {2, 4}, {2, 2}, {2, 4}, {2, 2},
          {2, 1}, {2, 2}, {2, 3}, {2, 2}},
      fail["UnexpectedGaugeShapes"]];

    Print["CF3032113LOCALV1 stage=materialize-current-blocks"];
    materializeSeconds = First@AbsoluteTiming[
      currentA1813 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution1813, variables, regulator, {2, 4}];
      currentA1913 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution1913, variables, regulator, {4, 4}];
      currentA2013 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution2013, variables, regulator, {2, 4}];
      currentA1513 = connection[[All, range15, lowerRange]];
      currentA1413 = connection[[All, range14, lowerRange]]];
    If[! And @@ (ListQ /@ {currentA1813, currentA1913,
          currentA2013, currentA1513, currentA1413}) ||
        Dimensions /@ {currentA1813, currentA1913, currentA2013,
          currentA1513, currentA1413} =!=
          {{2, 2, 4}, {2, 4, 4}, {2, 2, 4}, {2, 3, 4}, {2, 2, 4}} ||
        ! FreeQ[{currentA1813, currentA1913, currentA2013,
          currentA1513, currentA1413},
          Alternatives[_Missing, Automatic, $Failed]],
      fail["CurrentLowerBlockMaterializationFailed"]];

    structuralChecks = <|
      "AllPriorRowCertificatesPassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]] &&
        And @@ Values[row19Certificate["GlobalChecks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "Row18Gauge13ExactlyZero" -> zeroMatrixQ[d1813],
      "Row19Gauge13ExactlyZero" -> zeroMatrixQ[d1913],
      "Row18CurrentA13ExactlyZero" -> zeroNestedQ[currentA1813],
      "Row19CurrentA13ExactlyZero" -> zeroNestedQ[currentA1913],
      "Row20Gauge13MatchesPinnedSolution" ->
        zeroMatrixQ[d2013 - solution2013["Gauge"]],
      "Row20CurrentA13ExactlyZero" -> zeroNestedQ[currentA2013],
      "D2117AndD2116ExactlyZero" ->
        zeroMatrixQ[d2117] && zeroMatrixQ[d2116],
      "Raw2117And2116ExactlyZero" ->
        zeroNestedQ[connection[[All, rowRange, range17]]] &&
        zeroNestedQ[connection[[All, rowRange, range16]]],
      "PinnedZeroBlockMethods" ->
        solution1813["Method"] === "ZeroForcing" &&
        solution1913["Method"] === "ZeroForcing" &&
        solution2013["Method"] === "ZeroForcing"|>;
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

    Print["CF3032113LOCALV1 stage=local-decompose materializeSeconds=",
      Round[materializeSeconds, 0.1]];
    decompositionSeconds = First@AbsoluteTiming[
      e21Channels = decomposePair[
        connection[[All, rowRange, rowRange]]/regulator];
      c13Channels = decomposePair[
        connection[[All, lowerRange, lowerRange]]/regulator];
      d1813Channels = decomposeMatrix[d1813];
      d1913Channels = decomposeMatrix[d1913];
      d2013Channels = decomposeMatrix[d2013];
      d2120Channels = decomposeMatrix[d2120];
      d2119Channels = decomposeMatrix[d2119];
      d2118Channels = decomposeMatrix[d2118];
      d2115Channels = decomposeMatrix[d2115];
      d2114Channels = decomposeMatrix[d2114];
      currentA1813Channels = decomposePair[currentA1813];
      currentA1913Channels = decomposePair[currentA1913];
      currentA2013Channels = decomposePair[currentA2013];
      currentA1513Channels = decomposePair[currentA1513];
      currentA1413Channels = decomposePair[currentA1413];
      a2113Channels = decomposePair[
        connection[[All, rowRange, lowerRange]]];
      a2120Channels = decomposePair[
        connection[[All, rowRange, range20]]];
      a2119Channels = decomposePair[
        connection[[All, rowRange, range19]]];
      a2118Channels = decomposePair[
        connection[[All, rowRange, range18]]]];
    If[! FreeQ[{e21Channels, c13Channels, d1813Channels,
          d1913Channels, d2013Channels, d2120Channels, d2119Channels,
          d2118Channels, d2115Channels, d2114Channels,
          currentA1813Channels,
          currentA1913Channels, currentA2013Channels,
          currentA1513Channels, currentA1413Channels, a2113Channels,
          a2120Channels,
          a2119Channels, a2118Channels}, $Failed],
      fail["ExactLocalLeafDecompositionFailed", <|
        "LocalRankHistogram" -> localRankHistogram,
        "LocalRootSetHistogram" -> localRootSetHistogram|>]];

    Print["CF3032113LOCALV1 stage=base localSeconds=",
      Round[decompositionSeconds, 0.1], " rankHistogram=",
      localRankHistogram];
    baseSeconds = First@AbsoluteTiming[
      prior2013PathChannels = Table[
        channelProduct[a2120Channels[[mu]], d2013Channels], {mu, 2}];
      prior1913PathChannels = Table[
        channelProduct[a2119Channels[[mu]], d1913Channels], {mu, 2}];
      prior1813PathChannels = Table[
        channelProduct[a2118Channels[[mu]], d1813Channels], {mu, 2}];
      base2113Channels = Map[Together,
        a2113Channels + prior2013PathChannels + prior1913PathChannels +
          prior1813PathChannels, {4}]];

    Print["CF3032113LOCALV1 stage=forcing baseSeconds=",
      Round[baseSeconds, 0.1]];
    forcingSeconds = First@AbsoluteTiming[
      new2120PathChannels = Table[
        channelProduct[d2120Channels, currentA2013Channels[[mu]]],
        {mu, 2}];
      new2119PathChannels = Table[
        channelProduct[d2119Channels, currentA1913Channels[[mu]]],
        {mu, 2}];
      new2118PathChannels = Table[
        channelProduct[d2118Channels, currentA1813Channels[[mu]]],
        {mu, 2}];
      new2115PathChannels = Table[
        channelProduct[d2115Channels, currentA1513Channels[[mu]]],
        {mu, 2}];
      new2114PathChannels = Table[
        channelProduct[d2114Channels, currentA1413Channels[[mu]]],
        {mu, 2}];
      forcing2113Channels = Map[Together,
        base2113Channels - new2120PathChannels - new2119PathChannels -
          new2118PathChannels - new2115PathChannels -
          new2114PathChannels, {4}]];

    termGradeSupports = <|
      "Raw2113" -> gradeSupportOf[a2113Channels],
      "Prior2013Path" -> gradeSupportOf[prior2013PathChannels],
      "Prior1913Path" -> gradeSupportOf[prior1913PathChannels],
      "Prior1813Path" -> gradeSupportOf[prior1813PathChannels],
      "CurrentA2013" -> gradeSupportOf[currentA2013Channels],
      "CurrentA1913" -> gradeSupportOf[currentA1913Channels],
      "CurrentA1813" -> gradeSupportOf[currentA1813Channels],
      "CurrentA1513" -> gradeSupportOf[currentA1513Channels],
      "CurrentA1413" -> gradeSupportOf[currentA1413Channels],
      "New2120Path" -> gradeSupportOf[new2120PathChannels],
      "New2119Path" -> gradeSupportOf[new2119PathChannels],
      "New2118Path" -> gradeSupportOf[new2118PathChannels],
      "New2115Path" -> gradeSupportOf[new2115PathChannels],
      "New2114Path" -> gradeSupportOf[new2114PathChannels]|>;
    termRecords = Association@KeyValueMap[
      #1 -> <|"GradeSupport" -> #2,
        "RootIndices" -> rootsFromGradeSupport[#2],
        "Grades" -> gradeRecord[#2]|> &, termGradeSupports];
    forcingGradeSupport = gradeSupportOf[forcing2113Channels];
    diagonal21GradeSupport = gradeSupportOf[e21Channels];
    diagonal13GradeSupport = gradeSupportOf[c13Channels];
    stripGradeSupport = MapThread[Or,
      {forcingGradeSupport, diagonal21GradeSupport,
        diagonal13GradeSupport}];
    forcingRootIndices = rootsFromGradeSupport[forcingGradeSupport];
    stripRootIndices = rootsFromGradeSupport[stripGradeSupport];
    activeRootSquares = rootSquares[[stripRootIndices]];
    chart = FeynFacet`TransportRootSetChart[activeRootSquares, variables];
    route = If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
      "NoJointRationalChart"];

    Print["CF3032113LOCALV1 stage=compose roots=", stripRootIndices,
      " route=", route, " forcingSeconds=", Round[forcingSeconds, 0.1]];
    composeSeconds = First@AbsoluteTiming[
      forcing2113 = composePair[forcing2113Channels];
      strip = {connection[[All, rowRange, rowRange]]/regulator,
        connection[[All, lowerRange, lowerRange]]/regulator,
        forcing2113}];
    If[! FreeQ[{forcing2113, strip}, $Failed],
      fail["FinalChannelCompositionFailed"]];

    classifierForcing =
      FeynFacet`Private`transportChartRootIndices[forcing2113, allRoots];
    classifierStrip =
      FeynFacet`Private`transportChartRootIndices[strip, allRoots];
    If[! AssociationQ[classifierForcing] ||
        ! AssociationQ[classifierStrip] ||
        Lookup[classifierForcing, "UnclassifiedRadicalBases", {1}] =!= {} ||
        Lookup[classifierStrip, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["FinalRootClassifierUnclassified", <|
        "Forcing" -> classifierForcing, "Strip" -> classifierStrip|>]];

    Print["CF3032113LOCALV1 stage=full-rank-crosscheck"];
    fullRankSeconds = First@AbsoluteTiming[
      fullRankForcingChannels = fullDecomposePair[forcing2113];
      fullRankDifference = Map[Together,
        fullRankForcingChannels - forcing2113Channels, {4}]];
    Print["CF3032113LOCALV1 stage=local-roundtrip fullRankSeconds=",
      Round[fullRankSeconds, 0.1]];
    roundTripSeconds = First@AbsoluteTiming[
      forcingRoundTripChannels = decomposePair[forcing2113];
      roundTripDifference = Map[Together,
        forcingRoundTripChannels - forcing2113Channels, {4}];
      roundTripComposedDifference = composePair[roundTripDifference];
      roundTripDifferencePositions = Position[
        roundTripDifference, Except[0], {4}, Heads -> False]];
    checks = <|
      "AllInputsExactlyCertified" ->
        And @@ Values[structuralChecks] &&
        And @@ (solutionExactlyCertifiedQ /@ {solution1813, solution1913,
            solution2013, solution2120, solution2119, solution2118,
            solution2115, solution2114}),
      "ZeroDependencyPathsExactlyZero" ->
        zeroNestedQ[prior2013PathChannels] &&
        zeroNestedQ[prior1913PathChannels] &&
        zeroNestedQ[prior1813PathChannels] &&
        zeroNestedQ[new2120PathChannels] &&
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
        "CF303Sector2113DependencyClosedLocalChannelCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 13,
      "Variables" -> variables, "Regulator" -> regulator,
      "Strip" -> strip, "AssembledForcing" -> forcing2113,
      "AssembledForcingChannels" -> forcing2113Channels,
      "Base2113Channels" -> base2113Channels,
      "CurrentA2013" -> currentA2013,
      "CurrentA1513" -> currentA1513,
      "CurrentA1413" -> currentA1413,
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
        "CF303Sector2113DependencyClosedLocalChannelCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 13,
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingNonzeroGrades" -> Flatten@Position[
        forcingGradeSupport, True] - 1,
      "StripNonzeroGrades" -> Flatten@Position[
        stripGradeSupport, True] - 1,
      "SelectedRoute" -> route,
      "ForcingLeafCount" -> LeafCount[forcing2113],
      "ForcingChannelLeafCount" -> LeafCount[forcing2113Channels],
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
    Print["CF3032113LOCALV1 status=PASS roots=", stripRootIndices,
      " nonzeroGrades=", summary["StripNonzeroGrades"],
      " route=", route, " localSeconds=",
      Round[decompositionSeconds, 0.1], " fullRankForcingSeconds=",
      Round[fullRankSeconds, 0.1]];
    0,
    tag];
  result
]
