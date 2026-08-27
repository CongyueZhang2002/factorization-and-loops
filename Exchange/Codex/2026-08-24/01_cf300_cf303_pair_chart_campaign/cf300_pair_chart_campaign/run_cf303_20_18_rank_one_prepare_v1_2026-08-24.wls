#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    factorBundleFile, sector19CertificateFile, outdir, stripFile,
    preparationFile, summaryFile, expectedHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, bundle,
    sector19Certificate, ranges, connection, regulator, sourceVariables,
    chartVariables, substitution, jacobian, sourceRoots, imageRoots,
    residualRoot, nestedRadicand, nestedRootImage, canonicalize,
    usedRootIndices, mapScalarRankOne, mapMatrixRankOne, pullBack,
    zeroPairQ, rowRange, range19, range18, leftDiagonalChart,
    right19Chart, right18Chart, forcing19Chart, forcing18Chart,
    strip19, strip18, record18, rankSourceVariables, rankRootSquare,
    frame, preparation, mappingStatistics = {}, blockMappingStatistics,
    residualChannels, sourceChannels, chartChannels, chartExpression,
    recomposed, canonicalExpression, indices, seconds, pathStatistics,
    summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  factorBundleFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  sector19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1";
  stripFile = FileNameJoin[{outdir, "rank_one_strips.wxf"}];
  preparationFile = FileNameJoin[{outdir, "preparation_20_18.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018RankOnePrepareV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    factorBundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    sector19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619"|>;

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
    Print["CF303 20->18 RANK-ONE PREPARE FAILURE V1: ", status,
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
    Print["CF3032018R1PREPV1 stage=load"];
    Get[loadFile];
    state = Get[stateFile];
    bundle = Get[factorBundleFile];
    sector19Certificate = Import[sector19CertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@ {state, bundle, sector19Certificate}) ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[sector19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        ! And @@ Values[sector19Certificate["GlobalChecks"]],
      fail["InvalidPinnedInputABI"]];
    ranges = state["Ranges"];
    connection = state["A"];
    regulator = bundle["Regulator"];
    sourceVariables = bundle["SourceVariables"];
    chartVariables = bundle["ChartVariables"];
    substitution = bundle["SourceSubstitution"];
    jacobian = bundle["Jacobian"];
    sourceRoots = bundle["SourceRoots"];
    imageRoots = bundle["RootImages"];
    residualRoot = bundle["ResidualRoot"];
    nestedRadicand = bundle["NestedRadicand"];
    nestedRootImage = bundle["NestedRootImage"];
    rowRange = ranges[[20]];
    range19 = ranges[[19]];
    range18 = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {35, 36} || range19 =!= {31, 32, 33, 34} ||
        range18 =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];
    If[! AllTrue[Flatten[connection[[All, rowRange, range19]]],
        TrueQ[# === 0] &] ||
        ! AllTrue[Flatten[connection[[All, rowRange, ranges[[17]]]]],
          TrueQ[# === 0] &] ||
        ! TrueQ[Lookup[Lookup[sector19Certificate, "GlobalChecks", <||>],
          "Indirect171819PathExactlyZero", False]],
      fail["PriorFrameDecouplingFailed"]];

    canonicalize[expression_] := Together[expression /.
      Power[base_, exponent_Rational] :> If[
        Denominator[exponent] === 2 &&
          TrueQ[Together[base - nestedRadicand] === 0],
        nestedRootImage^(2 exponent), Power[base, exponent]]];
    usedRootIndices[expression_] := Flatten@Position[
      Table[Module[{marker = Unique["rootMarker$"]},
        ! FreeQ[FeynFacet`Private`transportChartApplyRootBranches[
          expression, {sourceRoots[[index]]}, {marker}], marker]],
        {index, Length[sourceRoots]}], True];
    mapScalarRankOne[label_String, expression_] := Module[{},
      If[TrueQ[expression === 0],
        AppendTo[blockMappingStatistics, <|"Label" -> label,
          "LiteralZero" -> True, "RootIndices" -> {},
          "ResidualOddChannelZero" -> True, "Seconds" -> 0.|>];
        Return[0]];
      canonicalExpression = canonicalize[expression];
      indices = usedRootIndices[canonicalExpression];
      seconds = First@AbsoluteTiming[
        sourceChannels = FeynFacet`Private`multiquadraticFieldDecompose[
          canonicalExpression, sourceRoots[[indices]]];
        If[sourceChannels === $Failed,
          fail["SourceFactorDecompositionFailed", <|
            "Label" -> label, "RootIndices" -> indices|>]];
        chartChannels = Together /@ (sourceChannels /. substitution);
        chartExpression = FeynFacet`Private`multiquadraticFieldCompose[
          chartChannels, imageRoots[[indices]]];
        If[chartExpression === $Failed,
          fail["ChartFactorCompositionFailed", <|"Label" -> label|>]];
        residualChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            chartExpression, {residualRoot}];
        If[residualChannels === $Failed,
          fail["ResidualRankOneDecompositionFailed", <|
            "Label" -> label|>]];
        recomposed = FeynFacet`Private`multiquadraticFieldCompose[
          residualChannels, {residualRoot}];
        If[recomposed === $Failed || ! TrueQ[
            Together[recomposed - chartExpression] === 0],
          fail["ResidualRankOneRoundTripFailed", <|
            "Label" -> label|>]]];
      AppendTo[blockMappingStatistics, <|"Label" -> label,
        "LiteralZero" -> False, "RootIndices" -> indices,
        "ResidualOddChannelZero" ->
          TrueQ[residualChannels[[2]] === 0],
        "SourceLeafCount" -> LeafCount[expression],
        "ChartLeafCount" -> LeafCount[recomposed],
        "Seconds" -> seconds|>];
      recomposed];
    mapMatrixRankOne[prefix_String, matrix_List] := MapIndexed[
      mapScalarRankOne[prefix <> "/" <>
        StringRiffle[ToString /@ #2, ","], #1] &, matrix, {2}];
    pullBack[pair_List] := Table[Map[Together,
      pair[[1]] jacobian[[1, component]] +
        pair[[2]] jacobian[[2, component]], {2}], {component, 2}];
    zeroPairQ[pair_List] := AllTrue[Flatten[pair],
      TrueQ[Together[#] === 0] &];

    Print["CF3032018R1PREPV1 stage=map-strips"];
    blockMappingStatistics = {};
    leftDiagonalChart = pullBack@Table[
      mapMatrixRankOne["E20/" <> ToString[mu],
        connection[[mu, rowRange, rowRange]]/regulator], {mu, 2}];
    right19Chart = pullBack@Table[
      mapMatrixRankOne["C19/" <> ToString[mu],
        connection[[mu, range19, range19]]/regulator], {mu, 2}];
    forcing19Chart = pullBack@Table[
      mapMatrixRankOne["B2019/" <> ToString[mu],
        connection[[mu, rowRange, range19]]], {mu, 2}];
    right18Chart = pullBack@Table[
      mapMatrixRankOne["C18/" <> ToString[mu],
        connection[[mu, range18, range18]]/regulator], {mu, 2}];
    forcing18Chart = pullBack@Table[
      mapMatrixRankOne["B2018/" <> ToString[mu],
        connection[[mu, rowRange, range18]]], {mu, 2}];
    strip19 = {leftDiagonalChart, right19Chart, forcing19Chart};
    strip18 = {leftDiagonalChart, right18Chart, forcing18Chart};
    mappingStatistics = blockMappingStatistics;
    If[! zeroPairQ[forcing19Chart],
      fail["Top2019ForcingNotZero"]];
    If[zeroPairQ[Map[
        FeynFacet`Private`multiquadraticFieldDecompose[#,
          {residualRoot}] &, leftDiagonalChart, {3}][[All, All, All, 2]]],
      fail["Sector20DiagonalOddGradeMissing"]];

    rankSourceVariables = {
      Symbol["CF303RankOneFrame`v"],
      Symbol["CF303RankOneFrame`w"]};
    rankRootSquare = residualRoot["RootSquare"] /.
      Thread[chartVariables -> rankSourceVariables];
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      {rankRootSquare}, rankSourceVariables, chartVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["RankOneFrameConstructionFailed", <|"Frame" -> frame|>]];
    record18 = <|"Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> 18, "Variables" -> chartVariables,
      "Regulator" -> regulator, "Strip" -> strip18|>;

    Print["CF3032018R1PREPV1 stage=prepare"];
    FeynFacet`Private`multiquadraticFieldResetPathStatistics[];
    preparation = FeynFacet`Private`multiquadraticStripPrepare[
      record18, frame];
    pathStatistics =
      FeynFacet`Private`multiquadraticFieldPathStatistics[];
    If[! AssociationQ[preparation] || Lookup[preparation, "Status", None]
        =!= "PreparedMultiquadraticStripV1" ||
        preparation["RootCount"] =!= 1 ||
        preparation["GradeCount"] =!= 2 ||
        preparation["Dimensions"] =!= {2, 2},
      fail["RankOnePreparationFailed", <|"Preparation" ->
        If[AssociationQ[preparation], KeyDrop[preparation,
          {"Record", "Frame", "OneForms", "ABIPayload"}],
          preparation]|>]];
    exportAtomic[<|
      "Status" -> "CF303Sector20TopAnd181RankOneStripsPassedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "TopLowerSector" -> 19, "TopGauge" -> ConstantArray[0, {2, 4}],
      "TopForcingExactlyZero" -> True,
      "RankOneLowerSector" -> 18, "Frame" -> frame,
      "Strip2019" -> strip19, "Strip2018" -> strip18,
      "MappingStatistics" -> mappingStatistics,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, stripFile];
    exportAtomic[preparation, preparationFile];
    summary = <|
      "Status" -> "CF303Sector2018RankOnePreparationPassedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Chart" -> "Kallen23PlusResidualRankOne",
      "ResidualRootSquare" -> residualRoot["RootSquare"],
      "Top2019ForcingExactlyZero" -> True,
      "Top2019GaugeExactlyZero" -> True,
      "RootCount" -> preparation["RootCount"],
      "GradeCount" -> preparation["GradeCount"],
      "Dimensions" -> preparation["Dimensions"],
      "GaugeDenominator" -> preparation["GaugeDenominator"],
      "GaugeDenominatorDegrees" ->
        preparation["GaugeDenominatorDegrees"],
      "GaugeSupportCount" -> Length[preparation["GaugeSupport"]],
      "GaugeSupportMaximumDegrees" ->
        Max /@ Transpose[preparation["GaugeSupport"]],
      "OneFormCount" -> Length[preparation["OneForms"]],
      "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
      "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
      "UnknownCount" -> preparation["UnknownCount"],
      "EquationsPerPoint" -> preparation["EquationsPerPoint"],
      "ABIFingerprint" -> preparation["ABIFingerprint"],
      "RootOrderingFingerprint" ->
        preparation["RootOrderingFingerprint"],
      "MappingScalarCount" -> Length[mappingStatistics],
      "MappingOddScalarCount" -> Count[mappingStatistics,
        item_Association /; ! TrueQ[item["ResidualOddChannelZero"]]],
      "MappingSeconds" -> Total[Lookup[
        mappingStatistics, "Seconds", 0.]],
      "ChannelPathStatistics" -> pathStatistics,
      "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
      "PreparationFile" -> preparationFile,
      "PreparationSHA256" -> hashHex[preparationFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3032018R1PREPV1 status=PASS unknowns=",
      preparation["UnknownCount"], " support=",
      Length[preparation["GaugeSupport"]], " oneForms=",
      Length[preparation["OneForms"]]];
    0,
    tag];
  result
]
