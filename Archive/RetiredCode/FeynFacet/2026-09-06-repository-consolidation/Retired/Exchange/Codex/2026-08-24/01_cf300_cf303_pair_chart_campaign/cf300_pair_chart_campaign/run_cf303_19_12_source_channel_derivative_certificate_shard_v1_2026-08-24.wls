#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, bundleFile,
    sourceDirectory, channelDirectory, outdir, shard, expectedChannelHash,
    rows, sourceFile, channelFile, resultFile, expectedHashes,
    sourceHashes, dependencyFiles, dependencyHashes, hashHex, exportAtomic,
    fail, tag, result, badHashes, sourceHashBefore, channelHashBefore,
    sourcePayload, channelPayload, bundle, variables, roots, deltas,
    sourceRows, sourceChannels, derivativeChannels, sourceDerivatives,
    composedDerivatives, derivativeDifferences, seconds, checks},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "MultiquadraticStripSolve.wl"}];
  bundleFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  sourceDirectory =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_19_12_kallen23_source_pullback_shards_v1";
  channelDirectory =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
      "cf303_19_12_source_channel_decomposition_shards_v1";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_19_12_source_channel_derivative_certificates_v1";
  tag = Unique["CF3031912SourceChannelDerivativeCertificateShardV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    bundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec"|>;
  sourceHashes = <|
    1 -> "95bec5d70761d0213ea24801028a0bde5ca1368f9c7f8cb86a70746d876434e9",
    2 -> "ca4f108e175de91056758e927b686551fd642489378aa8d478e6303bf641920f",
    3 -> "f03fcb4cc2d78171295a6cbc058e1e53206cdc1af2f2e810daad2bed1bd14bcd"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile|>;
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  exportAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
    Export[temporary, expression, "WXF"];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := (
    Print["CF303 19->12 DERIVATIVE SHARD FAILURE V1: ", status,
      " data=", data]; Throw[$Failed, tag]);

  result = Catch[
    If[Length[Rest[$ScriptCommandLine]] =!= 2,
      fail["ShardAndChannelHashArgumentsRequired"]];
    shard = Quiet[Check[ToExpression[Rest[$ScriptCommandLine][[1]],
      InputForm], $Failed]];
    expectedChannelHash = Rest[$ScriptCommandLine][[2]];
    If[! MemberQ[{1, 2, 3}, shard], fail["ShardMustBeOneTwoOrThree"]];
    If[! StringQ[expectedChannelHash] ||
        ! StringMatchQ[expectedChannelHash,
          Repeated[HexadecimalCharacter, {64}]],
      fail["InvalidExpectedChannelHash"]];
    rows = Switch[shard, 1, {1, 2}, 2, {3}, 3, {4}];
    sourceFile = FileNameJoin[{sourceDirectory,
      "source_rows_shard_" <> ToString[shard] <> ".wxf"}];
    channelFile = FileNameJoin[{channelDirectory,
      "source_channels_shard_" <> ToString[shard] <> ".wxf"}];
    resultFile = FileNameJoin[{outdir,
      "derivative_certificate_shard_" <> ToString[shard] <> ".wxf"}];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["PoolWorkerRequired"]];
    If[Length[Kernels[]] =!= 0,
      fail["MissionWorkerAlreadyOwnsNestedKernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["HelperCeilingMustBeZero"]];
    If[FileExistsQ[resultFile], fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {}, fail["ImmutableInputHashMismatch", <|
        "Files" -> badHashes|>]];
    sourceHashBefore = hashHex[sourceFile];
    channelHashBefore = hashHex[channelFile];
    If[sourceHashBefore =!= sourceHashes[shard] ||
        channelHashBefore =!= expectedChannelHash,
      fail["ShardInputHashMismatch", <|
        "SourceObserved" -> sourceHashBefore,
        "ChannelObserved" -> channelHashBefore|>]];
    If[! DirectoryQ[outdir], Quiet[Check[CreateDirectory[outdir], Null]]];
    If[! DirectoryQ[outdir], fail["OutputDirectoryUnavailable"]];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    sourcePayload = Import[sourceFile, "WXF"];
    channelPayload = Import[channelFile, "WXF"];
    bundle = Get[bundleFile];
    If[! AssociationQ[sourcePayload] || ! AssociationQ[channelPayload] ||
        ! AssociationQ[bundle] ||
        Lookup[sourcePayload, "Status", None] =!=
          "CF303Sector1912Kallen23SourcePullbackShardPassedV1" ||
        Lookup[channelPayload, "Status", None] =!=
          "CF303Sector1912SourceChannelShardPassedV1" ||
        Lookup[bundle, "Status", None] =!= "CF303PairFactorBundlePassedV3" ||
        Lookup[sourcePayload, "Shard", None] =!= shard ||
        Lookup[channelPayload, "Shard", None] =!= shard ||
        Lookup[sourcePayload, "Rows", None] =!= rows ||
        Lookup[channelPayload, "Rows", None] =!= rows ||
        Lookup[channelPayload, "SourceRowsSHA256", None] =!=
          sourceHashBefore ||
        ! And @@ Values[Lookup[channelPayload, "Checks", <||>]],
      fail["InvalidInputABI"]];
    variables = bundle["SourceVariables"];
    roots = bundle["SourceRoots"];
    deltas = Lookup[roots, "RootSquare", $Failed];
    sourceRows = sourcePayload["SourceRows"];
    sourceChannels = channelPayload["SourceChannels"];
    If[! MatchQ[variables, {_Symbol, _Symbol}] || Length[roots] =!= 3 ||
        Dimensions[sourceRows] =!= {Length[rows], 4} ||
        Dimensions[sourceChannels] =!= {Length[rows], 4, 8} ||
        ! ListQ[deltas] || Length[deltas] =!= 3,
      fail["InvalidRootOrChannelShape"]];
    Print["CF3031912DERIVV1 shard=", shard, " rows=", rows,
      " sourceLeaves=", LeafCount[sourceRows],
      " channelLeaves=", LeafCount[sourceChannels]];
    seconds = First@AbsoluteTiming[
      derivativeChannels = Table[Map[
        FeynFacet`Private`multiquadraticDerivative[
          #, deltas, variables[[mu]]] &, sourceChannels, {2}], {mu, 2}];
      sourceDerivatives = Table[Map[D[#, variables[[mu]]] &,
        sourceRows, {2}], {mu, 2}];
      composedDerivatives = Table[Map[
        FeynFacet`Private`multiquadraticFieldCompose[#, roots] &,
        derivativeChannels[[mu]], {2}], {mu, 2}];
      derivativeDifferences = Map[Together,
        composedDerivatives - sourceDerivatives, {3}]];
    checks = <|
      "DerivativeChannelShapeExact" ->
        Dimensions[derivativeChannels] === {2, Length[rows], 4, 8},
      "DerivativeCompositionShapeExact" ->
        Dimensions[composedDerivatives] === {2, Length[rows], 4},
      "DifferentiationCommutesWithLift" -> AllTrue[
        Flatten[derivativeDifferences], TrueQ[# === 0] &],
      "InputHashesStable" -> hashHex[sourceFile] === sourceHashBefore &&
        hashHex[channelFile] === channelHashBefore,
      "PackageSourceUnmodified" ->
        Map[hashHex, dependencyFiles] === dependencyHashes|>;
    If[! And @@ Values[checks], fail["DerivativeCertificateChecksFailed", <|
        "Checks" -> checks|>]];
    exportAtomic[<|
      "Status" ->
        "CF303Sector1912SourceChannelDerivativeShardCertifiedV1",
      "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> 12,
      "Shard" -> shard, "Rows" -> rows,
      "SourceRowsFile" -> sourceFile,
      "SourceRowsSHA256" -> sourceHashBefore,
      "SourceChannelsFile" -> channelFile,
      "SourceChannelsSHA256" -> channelHashBefore,
      "DerivativeChannels" -> derivativeChannels,
      "Checks" -> checks, "Seconds" -> seconds,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    Print["CF3031912DERIVV1 status=PASS shard=", shard,
      " seconds=", Round[seconds, 0.1]];
    0,
    tag];
  result
]
