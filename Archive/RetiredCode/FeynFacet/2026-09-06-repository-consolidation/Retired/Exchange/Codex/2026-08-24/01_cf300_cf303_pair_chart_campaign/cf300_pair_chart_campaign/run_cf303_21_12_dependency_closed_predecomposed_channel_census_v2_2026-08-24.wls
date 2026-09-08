#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, familyRowFile,
    stateFile, factorBundleFile, row18CertificateFile, row19CertificateFile,
    row20CertificateFile, row18Block12File, row19Block12File,
    row20Block12File, source1912File, source1912ChannelFiles,
    source1912DerivativeFiles,
    solution2120File, solution2119File,
    solution2118File, solution2115File, solution2114File,
    solution2113File, outdir,
    censusFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, factorBundle,
    row18Certificate,
    row19Certificate, row20Certificate, row18Block12Payload,
    row19Block12Payload, row20Block12Payload, solution2120Payload,
    solution2119Payload, solution2118Payload, solution2115Payload,
    solution2114Payload, solution2113Payload, source1912Payload,
    source1912ChannelPayloads, source1912DerivativePayloads,
    solution1812, solution1912, solution2012, solution2120,
    solution2119, solution2118, solution2115, solution2114, solution2113,
    solutionExactlyCertifiedQ,
    ranges, connection,
    variables, regulator, rowRange, range20, range19, range18, range17,
    range16, range15, range14, range13, lowerRange, rootSquares,
    frameVariables, frame,
    frameRoots, allRoots, deltas, d1812, d1912, d2012, d2120, d2119,
    d2118,
    d2117, d2116, d2115, d2114, d2113, currentA1812, currentA1912,
    currentA2012, currentA1512, currentA1412, zeroNestedQ, zeroMatrixQ,
    localRankHistogram,
    localRootSetHistogram, localDecomposeScalar, decomposePair,
    decomposeMatrix, fullDecomposePair, composePair, gradeSupportOf,
    rootsFromGradeSupport, gradeRecord, channelProduct, channelDerivative,
    e21Channels, e19Channels, c12Channels, d1812Channels, d1912Channels,
    d1912DerivativeChannels, locallyDifferentiatedD1912Channels,
    d2012Channels, d2120Channels, d2119Channels, d2118Channels,
    d2115Channels, d2114Channels, currentA1812Channels,
    currentA1912Channels, currentA2012Channels, currentA1512Channels,
    currentA1412Channels, a1912Channels, a2112Channels,
    a2120Channels, a2119Channels, a2118Channels, prior2012PathChannels,
    prior1912PathChannels, prior1812PathChannels, base2112Channels,
    new2120PathChannels, new2119PathChannels, new2118PathChannels,
    new2115PathChannels, new2114PathChannels, forcing2112Channels,
    forcing2112,
    fullRankForcingChannels, fullRankDifference,
    forcingRoundTripChannels, roundTripDifference,
    roundTripComposedDifference, roundTripDifferencePositions,
    structuralChecks, stateAccumulationChecks, baseFrameProvenance,
    expectedStateStripPairs, stateStripPairs, strip, termGradeSupports,
    termRecords,
    forcingGradeSupport, diagonal21GradeSupport, diagonal12GradeSupport,
    stripGradeSupport, forcingRootIndices, stripRootIndices,
    classifierForcing, classifierStrip, activeRootSquares, chart, route,
    materializeSeconds, decompositionSeconds, currentLowerSeconds,
    baseSeconds, forcingSeconds,
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
  factorBundleFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  row20CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1/certificate.wxf";
  row18Block12File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_campaign_v1/" <>
    "block_12_attempt_1/solution.wxf";
  row19Block12File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1/" <>
    "block_12_attempt_1/solution.wxf";
  row20Block12File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1/" <>
    "block_12_attempt_1/solution.wxf";
  source1912File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_19_12_kallen23_source_pullback_shard_aggregate_v1/" <>
      "source_gauge_19_12.wxf";
  source1912ChannelFiles = Table[
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_19_12_source_channel_decomposition_shards_v1/" <>
      "source_channels_shard_" <> ToString[shard] <> ".wxf",
    {shard, 3}];
  source1912DerivativeFiles = Table[
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_19_12_source_channel_derivative_certificates_v1/" <>
      "derivative_certificate_shard_" <> ToString[shard] <> ".wxf",
    {shard, 3}];
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
  solution2113File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_13_zero_source_solve_v1_retry/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_12_dependency_closed_predecomposed_channel_census_v2";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique[
    "CF3032112DependencyClosedPredecomposedChannelCensusV2$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    familyRowFile ->
      "ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    factorBundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140",
    row18Block12File ->
      "40eb95eb0aaf803361a1de08248444dd8af53169f8487c1270d8f40ce7ec1f39",
    row19Block12File ->
      "afe538e835c0b56ff871af920a4d31848f87afa8c7f849883661f67aec069162",
    row20Block12File ->
      "61ea530473053e48e1234d3dd3fdff1344271d241ea193ec21b37e95b6f96d01",
    source1912File ->
      "5afc03d2d731363c8566beaf783cb9cf560f871e79f7ec68a0eb60f286691a64",
    source1912ChannelFiles[[1]] ->
      "42463172895894cbe666c73159b8012337d64f844702f1165f03d23e3c1439ce",
    source1912ChannelFiles[[2]] ->
      "9312ff3ada90268edd3b646a4afdf241beea4461d74514c064d93792ea87674d",
    source1912ChannelFiles[[3]] ->
      "ec5487969ee357d334e4049090ffac9a90b4f2a766b01e89f8063a771837f659",
    source1912DerivativeFiles[[1]] ->
      "PENDING_DERIVATIVE_SHARD_1_SHA256",
    source1912DerivativeFiles[[2]] ->
      "PENDING_DERIVATIVE_SHARD_2_SHA256",
    source1912DerivativeFiles[[3]] ->
      "PENDING_DERIVATIVE_SHARD_3_SHA256",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5",
    solution2119File ->
      "cd382a49f4dc930f6372861ba103b30d6731869ef63e907b922bd6449c18a5c8",
    solution2118File ->
      "f9e89a247594a7f9b2e079e1195344decc3d0d1f8107f5a30d1b499b73332956",
    solution2115File ->
      "d4e8e7452972596dc8156db500cb442e1a58e473464561067dc3e84ef5184405",
    solution2114File ->
      "8e8c1c38e0f3d6b243ac40e2bc7d5dc616a8d92f49a155057226b381b4d4f926",
    solution2113File ->
      "a7ee4b257061e1975b0c3d4ad6a540318c1bac770cc446469e3031a50d10c482"|>;
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
      "Sector" -> 21, "LowerSector" -> 12,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->12 PREDECOMPOSED CHANNEL CENSUS FAILURE V2: ",
      status,
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
    factorBundle = Get[factorBundleFile];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    row18Block12Payload = Import[row18Block12File, "WXF"];
    row19Block12Payload = Import[row19Block12File, "WXF"];
    row20Block12Payload = Import[row20Block12File, "WXF"];
    source1912Payload = Import[source1912File, "WXF"];
    source1912ChannelPayloads = Import[#, "WXF"] & /@
      source1912ChannelFiles;
    source1912DerivativePayloads = Import[#, "WXF"] & /@
      source1912DerivativeFiles;
    solution2120Payload = Import[solution2120File, "WXF"];
    solution2119Payload = Import[solution2119File, "WXF"];
    solution2118Payload = Import[solution2118File, "WXF"];
    solution2115Payload = Import[solution2115File, "WXF"];
    solution2114Payload = Import[solution2114File, "WXF"];
    solution2113Payload = Import[solution2113File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, factorBundle, row18Certificate,
          row19Certificate, row20Certificate, row18Block12Payload,
          row19Block12Payload, row20Block12Payload, solution2120Payload,
          solution2119Payload, solution2118Payload, solution2115Payload,
          solution2114Payload, solution2113Payload, source1912Payload}) ||
        ! AllTrue[source1912ChannelPayloads, AssociationQ] ||
        ! AllTrue[source1912DerivativePayloads, AssociationQ] ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1" ||
        Lookup[factorBundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[row18Block12Payload, "Status", None] =!=
          "CF303Sector18PairChartDLogSolutionV1" ||
        Lookup[row19Block12Payload, "Status", None] =!=
          "CF303Sector19PairChartDLogSolutionV1" ||
        Lookup[row20Block12Payload, "Status", None] =!=
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
          "CF303Sector2114Kallen3SourceSolvedV1" ||
        Lookup[solution2113Payload, "Status", None] =!=
          "CF303Sector2113ZeroSourceSolvedV1" ||
        Lookup[source1912Payload, "Status", None] =!=
          "CF303Sector1912Kallen23SourcePullbackPassedV1",
      fail["InvalidInputABI"]];
    If[Lookup[source1912ChannelPayloads, "Status", None] =!=
          ConstantArray["CF303Sector1912SourceChannelShardPassedV1", 3] ||
        Lookup[source1912ChannelPayloads, "Shard", None] =!= {1, 2, 3} ||
        Lookup[source1912ChannelPayloads, "Rows", None] =!=
          {{1, 2}, {3}, {4}} ||
        ! AllTrue[Lookup[source1912ChannelPayloads, "Checks", <||>],
          AssociationQ[#] && And @@ Values[#] &] ||
        ! AllTrue[
          Lookup[source1912ChannelPayloads, "PackageSourceModified", True],
          FalseQ],
      fail["InvalidSourceChannelShardABI"]];
    If[Lookup[source1912DerivativePayloads, "Status", None] =!=
          ConstantArray[
            "CF303Sector1912SourceChannelDerivativeShardCertifiedV1", 3] ||
        Lookup[source1912DerivativePayloads, "Shard", None] =!= {1, 2, 3} ||
        Lookup[source1912DerivativePayloads, "Rows", None] =!=
          {{1, 2}, {3}, {4}} ||
        Lookup[source1912DerivativePayloads, "SourceChannelsSHA256", None] =!=
          (expectedHashes /@ source1912ChannelFiles) ||
        ! AllTrue[Lookup[source1912DerivativePayloads, "Checks", <||>],
          AssociationQ[#] && And @@ Values[#] &] ||
        ! AllTrue[
          Lookup[source1912DerivativePayloads, "PackageSourceModified", True],
          FalseQ],
      fail["InvalidSourceDerivativeShardABI"]];
    solution1812 = row18Block12Payload["Solution"];
    solution1912 = row19Block12Payload["Solution"];
    solution2012 = row20Block12Payload["Solution"];
    solution2120 = solution2120Payload["Solution"];
    solution2119 = solution2119Payload["SourceSolution"];
    solution2118 = solution2118Payload["SourceSolution"];
    solution2115 = solution2115Payload["SourceSolution"];
    solution2114 = solution2114Payload["SourceSolution"];
    solution2113 = solution2113Payload["SourceSolution"];
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
    If[! And @@ (AssociationQ /@ {solution1812, solution1912,
          solution2012, solution2120, solution2119, solution2118,
          solution2115, solution2114, solution2113}) ||
        ! (And @@ (solutionExactlyCertifiedQ /@ {solution1812,
              solution2012, solution2120, solution2119,
              solution2118, solution2115, solution2114, solution2113})),
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
    range13 = ranges[[13]];
    lowerRange = ranges[[12]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || range20 =!= {35, 36} ||
        range19 =!= {31, 32, 33, 34} || range18 =!= {29, 30} ||
        range17 =!= {28} || range16 =!= {26, 27} ||
        range15 =!= {23, 24, 25} || range14 =!= {21, 22} ||
        range13 =!= {17, 18, 19, 20} ||
        lowerRange =!= {13, 14, 15, 16},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector2112LocalChannelCensus`p"],
      Symbol["CF303Sector2112LocalChannelCensus`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    frameRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, variables];
    allRoots = factorBundle["SourceRoots"];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
          "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]] ||
        ! ListQ[frameRoots] || Length[frameRoots] =!= 3 ||
        ! ListQ[allRoots] || Length[allRoots] =!= 3 ||
        ! AllTrue[MapThread[Function[{root, square},
          TrueQ[Together[root["RootSquare"] - square] === 0]],
          {allRoots, rootSquares}], TrueQ] ||
        ! AllTrue[MapThread[Function[{bundleRoot, frameRoot},
          TrueQ[Together[bundleRoot["RootSquare"] -
            frameRoot["RootSquare"]] === 0] &&
            TrueQ[Together[bundleRoot["Root"] -
              frameRoot["Root"]] === 0]], {allRoots, frameRoots}], TrueQ],
      fail["PinnedRootABIInvalid"]];
    deltas = Lookup[allRoots, "RootSquare", {}];
    zeroNestedQ[expression_] := AllTrue[Flatten[expression],
      TrueQ[Together[#] === 0] &];
    zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];

    d1812 = row18Certificate["SolvedChartGauges"][12];
    d1912 = source1912Payload["SourceGauge"];
    d1912Channels = Join @@
      Lookup[source1912ChannelPayloads, "SourceChannels"];
    d1912DerivativeChannels = Table[
      Join @@ (#[[mu]] & /@
        Lookup[source1912DerivativePayloads, "DerivativeChannels"]),
      {mu, 2}];
    d2012 = row20Certificate["SolvedSourceGauges"][12];
    d2120 = solution2120["Gauge"];
    d2119 = solution2119["Gauge"];
    d2118 = solution2118["Gauge"];
    d2117 = solution2115Payload["D2117"];
    d2116 = solution2115Payload["D2116"];
    d2115 = solution2115["Gauge"];
    d2114 = solution2114["Gauge"];
    d2113 = solution2113["Gauge"];
    If[Dimensions /@ {d1812, d1912, d2012, d2120, d2119, d2118,
          d2117, d2116, d2115, d2114, d2113} =!=
        {{2, 4}, {4, 4}, {2, 4}, {2, 2}, {2, 4}, {2, 2},
          {2, 1}, {2, 2}, {2, 3}, {2, 2}, {2, 4}},
      fail["UnexpectedGaugeShapes"]];

    Print["CF3032112PRECHANNELV2 stage=materialize-current-blocks"];
    materializeSeconds = First@AbsoluteTiming[
      currentA1812 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution1812, variables, regulator, {2, 4}];
      currentA2012 = FeynFacet`Private`familyRowGaugeDLogForm[
        solution2012, variables, regulator, {2, 4}];
      currentA1512 = connection[[All, range15, lowerRange]];
      currentA1412 = connection[[All, range14, lowerRange]]];
    If[! And @@ (ListQ /@ {currentA1812,
          currentA2012, currentA1512, currentA1412}) ||
        Dimensions /@ {currentA1812, currentA2012,
          currentA1512, currentA1412} =!=
          {{2, 2, 4}, {2, 2, 4}, {2, 3, 4}, {2, 2, 4}} ||
        ! FreeQ[{currentA1812, currentA2012,
          currentA1512, currentA1412},
          Alternatives[_Missing, Automatic, $Failed]],
      fail["CurrentLowerBlockMaterializationFailed"]];

    expectedStateStripPairs = Flatten[
      Table[{sector, lower}, {sector, 2, 16}, {lower, 1, sector - 1}], 1];
    stateStripPairs = Lookup[state["StripSolvers"],
      {"Sector", "LowerSector"}, None];
    stateAccumulationChecks = <|
      "StateSectorExactly16" -> Lookup[state, "Sector", None] === 16,
      "StateConnectionIsAccumulatedA" -> connection === state["A"],
      "StateContainsTransformationAndInverse" ->
        MatrixQ[Lookup[state, "S", None]] &&
        MatrixQ[Lookup[state, "SInverse", None]] &&
        Dimensions[state["S"]] === {45, 45} &&
        Dimensions[state["SInverse"]] === {45, 45},
      "StateStripPairCoverageThrough16Exact" ->
        Sort[stateStripPairs] === Sort[expectedStateStripPairs] &&
        Length[stateStripPairs] === Length[expectedStateStripPairs],
      "StateStripSummariesExactlyCertified" -> AllTrue[
        state["StripSolvers"],
        If[Lookup[#, "Method", None] === "ZeroForcing",
          TrueQ[Lookup[#, "ExactDLog", False]],
          TrueQ[Lookup[Lookup[#, "FrameCertificate", <||>],
            "Exact", False]]] &],
      "StateSectorCertificateCoverageThrough16Exact" ->
        Lookup[state["SectorCertificates"], "Sector", None] === Range[2, 16] &&
        Length[state["SectorCertificates"]] === 15,
      "StateSectorRoutesBlockwise" ->
        Lookup[state["SectorCertificates"], "Route", None] ===
          ConstantArray["Blockwise", 15]|>;
    If[! And @@ Values[stateAccumulationChecks],
      fail["StateAccumulationProvenanceFailed", <|
        "Checks" -> stateAccumulationChecks|>]];

    structuralChecks = <|
      "AllPriorRowCertificatesPassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]] &&
        And @@ Values[row19Certificate["GlobalChecks"]] &&
        And @@ Values[row20Certificate["GlobalChecks"]],
      "Row18Gauge12ExactlyZero" -> zeroMatrixQ[d1812],
      "Row18CurrentA12ExactlyZero" -> zeroNestedQ[currentA1812],
      "Row19SourceGaugeMatchesCertifiedChartGauge" -> zeroMatrixQ[
        source1912Payload["ChartGauge"] -
          row19Certificate["SolvedChartGauges"][12]],
      "Row19SourcePullbackChecksPassed" ->
        And @@ Values[source1912Payload["Checks"]],
      "Row19PredecomposedChannelShapeExact" ->
        Dimensions[d1912Channels] === {4, 4, 8},
      "Row19PredecomposedDerivativeShapeExact" ->
        Dimensions[d1912DerivativeChannels] === {2, 4, 4, 8},
      "Row19DifferentiationCommutesWithLiftCertified" ->
        AllTrue[Lookup[source1912DerivativePayloads, "Checks"],
          TrueQ[Lookup[#, "DifferentiationCommutesWithLift", False]] &],
      "Row19ChannelShardsLinkedToPullback" ->
        Lookup[source1912Payload["ShardHashes"],
          Lookup[source1912ChannelPayloads, "SourceRowsFile"]] ===
            Lookup[source1912ChannelPayloads, "SourceRowsSHA256"],
      "Row19ChannelShardsUsePinnedRootABI" -> AllTrue[
        Lookup[source1912ChannelPayloads, "InputHashes"],
        Lookup[#, bundleFile, None] === expectedHashes[bundleFile] &],
      "Row19SourceThirdRootAbsent" ->
        ! MemberQ[source1912Payload["SourceRootCensus"]["RootIndices"], 3],
      "Row19Gauges13Through17ExactlyZero" -> And @@ Table[
        zeroMatrixQ[row19Certificate["SolvedChartGauges"][j]],
        {j, 13, 17}],
      "Row20Gauge12MatchesPinnedSolution" ->
        zeroMatrixQ[d2012 - solution2012["Gauge"]],
      "Row20Gauge12ExactlyZero" -> zeroMatrixQ[d2012],
      "Row20CurrentA12ExactlyZero" -> zeroNestedQ[currentA2012],
      "D2117AndD2116ExactlyZero" ->
        zeroMatrixQ[d2117] && zeroMatrixQ[d2116],
      "D2113ExactlyZero" -> zeroMatrixQ[d2113],
      "Raw2117And2116ExactlyZero" ->
        zeroNestedQ[connection[[All, rowRange, range17]]] &&
        zeroNestedQ[connection[[All, rowRange, range16]]],
      "StateRow19To17ExactlyZero" ->
        zeroNestedQ[connection[[All, range19, range17]]],
      "PinnedZeroBlockMethods" ->
        solution1812["Method"] === "ZeroForcing" &&
        solution2012["Method"] === "ZeroForcing"|>;
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
    channelDerivative[gauge_, mu_Integer] := Map[
      FeynFacet`Private`multiquadraticDerivative[
        #, deltas, variables[[mu]]] &, gauge, {2}];

    Print["CF3032112PRECHANNELV2 stage=local-decompose materializeSeconds=",
      Round[materializeSeconds, 0.1]];
    decompositionSeconds = First@AbsoluteTiming[
      e21Channels = decomposePair[
        connection[[All, rowRange, rowRange]]/regulator];
      e19Channels = decomposePair[
        connection[[All, range19, range19]]/regulator];
      c12Channels = decomposePair[
        connection[[All, lowerRange, lowerRange]]/regulator];
      d1812Channels = decomposeMatrix[d1812];
      d2012Channels = decomposeMatrix[d2012];
      d2120Channels = decomposeMatrix[d2120];
      d2119Channels = decomposeMatrix[d2119];
      d2118Channels = decomposeMatrix[d2118];
      d2115Channels = decomposeMatrix[d2115];
      d2114Channels = decomposeMatrix[d2114];
      currentA1812Channels = decomposePair[currentA1812];
      currentA2012Channels = decomposePair[currentA2012];
      currentA1512Channels = decomposePair[currentA1512];
      currentA1412Channels = decomposePair[currentA1412];
      a1912Channels = decomposePair[
        connection[[All, range19, lowerRange]]];
      a2112Channels = decomposePair[
        connection[[All, rowRange, lowerRange]]];
      a2120Channels = decomposePair[
        connection[[All, rowRange, range20]]];
      a2119Channels = decomposePair[
        connection[[All, rowRange, range19]]];
      a2118Channels = decomposePair[
        connection[[All, rowRange, range18]]]];
    If[! FreeQ[{e21Channels, e19Channels, c12Channels, d1812Channels,
          d1912Channels, d2012Channels, d2120Channels, d2119Channels,
          d2118Channels, d2115Channels, d2114Channels,
          currentA1812Channels, currentA2012Channels,
          currentA1512Channels, currentA1412Channels, a2112Channels,
          a1912Channels, a2120Channels,
          a2119Channels, a2118Channels}, $Failed],
      fail["ExactLocalLeafDecompositionFailed", <|
        "LocalRankHistogram" -> localRankHistogram,
        "LocalRootSetHistogram" -> localRootSetHistogram|>]];

    Print["CF3032112PRECHANNELV2 stage=current-row19 localSeconds=",
      Round[decompositionSeconds, 0.1], " rankHistogram=",
      localRankHistogram];
    currentLowerSeconds = First@AbsoluteTiming[
      locallyDifferentiatedD1912Channels = Table[
        channelDerivative[d1912Channels, mu], {mu, 2}];
      If[! zeroNestedQ[Map[Together,
          locallyDifferentiatedD1912Channels - d1912DerivativeChannels,
          {4}]],
        fail["ImportedDerivativeChannelsDifferFromLocalRecomputation"]];
      currentA1912Channels = Table[Map[Together,
        a1912Channels[[mu]] + regulator (
          channelProduct[e19Channels[[mu]], d1912Channels] -
          channelProduct[d1912Channels, c12Channels[[mu]]]) -
          d1912DerivativeChannels[[mu]], {3}], {mu, 2}]];

    Print["CF3032112PRECHANNELV2 stage=base currentRow19Seconds=",
      Round[currentLowerSeconds, 0.1]];
    baseSeconds = First@AbsoluteTiming[
      prior2012PathChannels = Table[
        channelProduct[a2120Channels[[mu]], d2012Channels], {mu, 2}];
      prior1912PathChannels = Table[
        channelProduct[a2119Channels[[mu]], d1912Channels], {mu, 2}];
      prior1812PathChannels = Table[
        channelProduct[a2118Channels[[mu]], d1812Channels], {mu, 2}];
      base2112Channels = Map[Together,
        a2112Channels + prior2012PathChannels + prior1912PathChannels +
          prior1812PathChannels, {4}]];
    baseFrameProvenance = <|
      "PinnedStateSector" -> state["Sector"],
      "PinnedStateSHA256" -> expectedHashes[stateFile],
      "StateAlreadyAccumulatesRows" -> Range[2, 16],
      "PostStateRowOrder" -> {17, 18, 19, 20},
      "Sector17RightAction" -> "A21,17 D17,12 = 0 (A21,17 exact zero)",
      "Sector18RightAction" -> "A21,18 D18,12 = 0 (D18,12 exact zero)",
      "Sector19RightAction" -> "A21,19 D19,12 included",
      "Sector20RightAction" -> "A21,20 D20,12 = 0 (D20,12 exact zero)",
      "BaseFormula" ->
        "state[A]21,12 + state[A]21,20 D20,12 + " <>
        "state[A]21,19 D19,12 + state[A]21,18 D18,12",
      "NoRawConnectionReintroduction" -> True,
      "StateAccumulationChecks" -> stateAccumulationChecks|>;

    Print["CF3032112PRECHANNELV2 stage=forcing baseSeconds=",
      Round[baseSeconds, 0.1]];
    forcingSeconds = First@AbsoluteTiming[
      new2120PathChannels = Table[
        channelProduct[d2120Channels, currentA2012Channels[[mu]]],
        {mu, 2}];
      new2119PathChannels = Table[
        channelProduct[d2119Channels, currentA1912Channels[[mu]]],
        {mu, 2}];
      new2118PathChannels = Table[
        channelProduct[d2118Channels, currentA1812Channels[[mu]]],
        {mu, 2}];
      new2115PathChannels = Table[
        channelProduct[d2115Channels, currentA1512Channels[[mu]]],
        {mu, 2}];
      new2114PathChannels = Table[
        channelProduct[d2114Channels, currentA1412Channels[[mu]]],
        {mu, 2}];
      forcing2112Channels = Map[Together,
        base2112Channels - new2120PathChannels - new2119PathChannels -
          new2118PathChannels - new2115PathChannels -
          new2114PathChannels, {4}]];

    termGradeSupports = <|
      "Raw2112" -> gradeSupportOf[a2112Channels],
      "Prior2012Path" -> gradeSupportOf[prior2012PathChannels],
      "Prior1912Path" -> gradeSupportOf[prior1912PathChannels],
      "Prior1812Path" -> gradeSupportOf[prior1812PathChannels],
      "CurrentA2012" -> gradeSupportOf[currentA2012Channels],
      "RawA1912" -> gradeSupportOf[a1912Channels],
      "CurrentA1912" -> gradeSupportOf[currentA1912Channels],
      "CurrentA1812" -> gradeSupportOf[currentA1812Channels],
      "CurrentA1512" -> gradeSupportOf[currentA1512Channels],
      "CurrentA1412" -> gradeSupportOf[currentA1412Channels],
      "New2120Path" -> gradeSupportOf[new2120PathChannels],
      "New2119Path" -> gradeSupportOf[new2119PathChannels],
      "New2118Path" -> gradeSupportOf[new2118PathChannels],
      "New2115Path" -> gradeSupportOf[new2115PathChannels],
      "New2114Path" -> gradeSupportOf[new2114PathChannels]|>;
    termRecords = Association@KeyValueMap[
      #1 -> <|"GradeSupport" -> #2,
        "RootIndices" -> rootsFromGradeSupport[#2],
        "Grades" -> gradeRecord[#2]|> &, termGradeSupports];
    forcingGradeSupport = gradeSupportOf[forcing2112Channels];
    diagonal21GradeSupport = gradeSupportOf[e21Channels];
    diagonal12GradeSupport = gradeSupportOf[c12Channels];
    stripGradeSupport = MapThread[Or,
      {forcingGradeSupport, diagonal21GradeSupport,
        diagonal12GradeSupport}];
    forcingRootIndices = rootsFromGradeSupport[forcingGradeSupport];
    stripRootIndices = rootsFromGradeSupport[stripGradeSupport];
    activeRootSquares = rootSquares[[stripRootIndices]];
    chart = FeynFacet`TransportRootSetChart[activeRootSquares, variables];
    route = If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
      "NoJointRationalChart"];

    Print["CF3032112PRECHANNELV2 stage=compose roots=", stripRootIndices,
      " route=", route, " forcingSeconds=", Round[forcingSeconds, 0.1]];
    composeSeconds = First@AbsoluteTiming[
      forcing2112 = composePair[forcing2112Channels];
      strip = {connection[[All, rowRange, rowRange]]/regulator,
        connection[[All, lowerRange, lowerRange]]/regulator,
        forcing2112}];
    If[! FreeQ[{forcing2112, strip}, $Failed],
      fail["FinalChannelCompositionFailed"]];

    classifierForcing =
      FeynFacet`Private`transportChartRootIndices[forcing2112, allRoots];
    classifierStrip =
      FeynFacet`Private`transportChartRootIndices[strip, allRoots];
    If[! AssociationQ[classifierForcing] ||
        ! AssociationQ[classifierStrip] ||
        Lookup[classifierForcing, "UnclassifiedRadicalBases", {1}] =!= {} ||
        Lookup[classifierStrip, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["FinalRootClassifierUnclassified", <|
        "Forcing" -> classifierForcing, "Strip" -> classifierStrip|>]];

    Print["CF3032112PRECHANNELV2 stage=full-rank-crosscheck"];
    fullRankSeconds = First@AbsoluteTiming[
      fullRankForcingChannels = fullDecomposePair[forcing2112];
      fullRankDifference = Map[Together,
        fullRankForcingChannels - forcing2112Channels, {4}]];
    Print["CF3032112PRECHANNELV2 stage=local-roundtrip fullRankSeconds=",
      Round[fullRankSeconds, 0.1]];
    roundTripSeconds = First@AbsoluteTiming[
      forcingRoundTripChannels = decomposePair[forcing2112];
      roundTripDifference = Map[Together,
        forcingRoundTripChannels - forcing2112Channels, {4}];
      roundTripComposedDifference = composePair[roundTripDifference];
      roundTripDifferencePositions = Position[
        roundTripDifference, Except[0], {4}, Heads -> False]];
    checks = <|
      "AllInputsExactlyCertified" ->
        And @@ Values[stateAccumulationChecks] &&
        And @@ Values[structuralChecks] &&
        And @@ (solutionExactlyCertifiedQ /@ {solution1812,
            solution2012, solution2120, solution2119, solution2118,
            solution2115, solution2114, solution2113}),
      "CurrentRow19ChannelShapeExact" ->
        Dimensions[currentA1912Channels] === {2, 4, 4, 8},
      "ZeroDependencyPathsExactlyZero" ->
        zeroNestedQ[prior2012PathChannels] &&
        zeroNestedQ[prior1812PathChannels] &&
        zeroNestedQ[new2120PathChannels] &&
        zeroNestedQ[new2118PathChannels],
      "BaseBoundToAccumulatedFrame" ->
        TrueQ[baseFrameProvenance["NoRawConnectionReintroduction"]] &&
        baseFrameProvenance["PinnedStateSector"] === 16 &&
        zeroNestedQ[prior2012PathChannels] &&
        zeroNestedQ[prior1812PathChannels],
      "ImportedDerivativeChannelsMatchLocalExactDerivative" ->
        zeroNestedQ[Map[Together,
          locallyDifferentiatedD1912Channels - d1912DerivativeChannels,
          {4}]],
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
        "CF303Sector2112DependencyClosedPredecomposedChannelCensusPassedV2",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 12,
      "Variables" -> variables, "Regulator" -> regulator,
      "Strip" -> strip, "AssembledForcing" -> forcing2112,
      "AssembledForcingChannels" -> forcing2112Channels,
      "Base2112Channels" -> base2112Channels,
      "CurrentA2012" -> currentA2012,
      "CurrentA1912Channels" -> currentA1912Channels,
      "D1912PredecomposedChannels" -> d1912Channels,
      "D1912ChannelShardFiles" -> source1912ChannelFiles,
      "D1912ChannelShardChecks" ->
        Lookup[source1912ChannelPayloads, "Checks"],
      "D1912DerivativeShardFiles" -> source1912DerivativeFiles,
      "D1912DerivativeShardChecks" ->
        Lookup[source1912DerivativePayloads, "Checks"],
      "D1912ChannelShardTimings" ->
        Lookup[source1912ChannelPayloads, "Seconds"],
      "CurrentA1512" -> currentA1512,
      "CurrentA1412" -> currentA1412,
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
      "StateAccumulationChecks" -> stateAccumulationChecks,
      "BaseFrameProvenance" -> baseFrameProvenance,
      "StructuralChecks" -> structuralChecks, "Checks" -> checks,
      "Timings" -> <|"Materialize" -> materializeSeconds,
        "LocalLeafDecomposition" -> decompositionSeconds,
        "CurrentRow19" -> currentLowerSeconds,
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
        "CF303Sector2112DependencyClosedPredecomposedChannelCensusPassedV2",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 12,
      "ForcingRootIndices" -> forcingRootIndices,
      "StripRootIndices" -> stripRootIndices,
      "ForcingNonzeroGrades" -> Flatten@Position[
        forcingGradeSupport, True] - 1,
      "StripNonzeroGrades" -> Flatten@Position[
        stripGradeSupport, True] - 1,
      "SelectedRoute" -> route,
      "ForcingLeafCount" -> LeafCount[forcing2112],
      "ForcingChannelLeafCount" -> LeafCount[forcing2112Channels],
      "D1912ChannelShardTimings" ->
        Lookup[source1912ChannelPayloads, "Seconds"],
      "D1912ChannelShardRankHistograms" ->
        Lookup[source1912ChannelPayloads, "LocalRankHistogram"],
      "LocalRankHistogram" -> localRankHistogram,
      "LocalRootSetHistogram" -> localRootSetHistogram,
      "StateAccumulationChecks" -> stateAccumulationChecks,
      "BaseFrameProvenance" -> baseFrameProvenance,
      "StructuralChecks" -> structuralChecks, "Checks" -> checks,
      "Timings" -> <|"Materialize" -> materializeSeconds,
        "LocalLeafDecomposition" -> decompositionSeconds,
        "CurrentRow19" -> currentLowerSeconds,
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
    Print["CF3032112PRECHANNELV2 status=PASS roots=", stripRootIndices,
      " nonzeroGrades=", summary["StripNonzeroGrades"],
      " route=", route, " localSeconds=",
      Round[decompositionSeconds, 0.1], " fullRankForcingSeconds=",
      Round[fullRankSeconds, 0.1]];
    0,
    tag];
  result
]
