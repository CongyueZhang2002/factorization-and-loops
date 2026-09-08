#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{bundleFile, expectedBundleHash, outdir, payloadFile, summaryFile,
    hashHex, bundle, delta, jacobian, chartVariables, regulator,
    leftDiagonal, rightDiagonal, directForcing, solvedFactors,
    lowerConnectionFactors, sectors, channelProduct, pullBack,
    channelArrayOddZeroQ,
    productChannels, sourceForcingChannels, chartLeftChannels,
    chartRightChannels, chartForcingChannels, oddZeroQ, rationalLeft,
    rationalRight, rationalForcing, rationalOracleSource,
    rationalOracleChart, strip, productSeconds, pullbackSeconds,
    checks, payload, summary, putAtomic, exportAtomic, fail, tag, result},
  bundleFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  expectedBundleHash =
    "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_strip_v1";
  payloadFile = FileNameJoin[{outdir, "CF303_17_12_pair_chart_strip_v1.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303PairChartStripV1$"];

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
  fail[message_String] := (
    Print["CF303 PAIR CHART STRIP FAILURE V1: " <> message];
    Throw[$Failed, tag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {}, fail["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["must run on a pool subkernel"]];
    If[Length[Kernels[]] =!= 0,
      fail["mission worker already owns nested kernels"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["output already exists"]];
    If[hashHex[bundleFile] =!= expectedBundleHash,
      fail["factor bundle hash mismatch"]];
    CreateDirectory[outdir];
    Print["CF303STRIPV1 stage=load-bundle"];
    bundle = Get[bundleFile];
    If[! AssociationQ[bundle] ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[bundle, {"Family", "Sector", "LowerSector"}, None] =!=
          {"CF303", 17, 12},
      fail["invalid factor bundle ABI"]];

    delta = bundle["ResidualPolynomial"];
    jacobian = bundle["Jacobian"];
    chartVariables = bundle["ChartVariables"];
    regulator = bundle["Regulator"];
    leftDiagonal = bundle["LeftDiagonalChannels"];
    rightDiagonal = bundle["RightDiagonalChannels"];
    directForcing = bundle["DirectForcingChannels"];
    solvedFactors = bundle["SolvedFactorChannels"];
    lowerConnectionFactors = bundle["LowerConnectionFactorChannels"];
    sectors = Keys[solvedFactors];
    If[Dimensions[leftDiagonal] =!= {2, 1, 1, 2} ||
        Dimensions[rightDiagonal] =!= {2, 4, 4, 2} ||
        Dimensions[directForcing] =!= {2, 1, 4, 2} ||
        Sort[sectors] =!= {13, 14, 15, 16} ||
        ! AllTrue[sectors,
          Dimensions[solvedFactors[#]] ===
              {1, Length[bundle["Ranges"][#]], 2} &&
            Dimensions[lowerConnectionFactors[#]] ===
              {2, Length[bundle["Ranges"][#]], 4, 2} &],
      fail["factor bundle channel shapes changed"]];

    channelProduct[left_List, right_List] := Module[
      {leftDimensions, rightDimensions, inner},
      leftDimensions = Dimensions[left];
      rightDimensions = Dimensions[right];
      If[Length[leftDimensions] =!= 3 || Length[rightDimensions] =!= 3 ||
          Last[leftDimensions] =!= 2 || Last[rightDimensions] =!= 2 ||
          leftDimensions[[2]] =!= rightDimensions[[1]], Return[$Failed]];
      inner = leftDimensions[[2]];
      Table[{
        Together[Total@Table[
          left[[i, k, 1]] right[[k, j, 1]] +
            delta left[[i, k, 2]] right[[k, j, 2]], {k, inner}]],
        Together[Total@Table[
          left[[i, k, 1]] right[[k, j, 2]] +
            left[[i, k, 2]] right[[k, j, 1]], {k, inner}]]},
        {i, leftDimensions[[1]]}, {j, rightDimensions[[2]]}]];
    pullBack[pair_List] := Table[
      Map[Together,
        pair[[1]] jacobian[[1, component]] +
          pair[[2]] jacobian[[2, component]], {3}],
      {component, 2}];
    oddZeroQ[pair_List] := AllTrue[
      Flatten[pair[[All, All, All, 2]]], TrueQ[# === 0] &];
    channelArrayOddZeroQ[array_List] := AllTrue[
      Flatten[Map[Last, array, {ArrayDepth[array] - 1}]],
      TrueQ[# === 0] &];

    Print["CF303STRIPV1 stage=channel-products"];
    productSeconds = First@AbsoluteTiming[
      productChannels = Association@Table[m -> Table[
        channelProduct[solvedFactors[m],
          lowerConnectionFactors[m][[mu]]], {mu, 2}], {m, sectors}];
      If[! FreeQ[productChannels, $Failed],
        fail["rank-one channel product failed"]];
      sourceForcingChannels = Table[Map[Together,
        directForcing[[mu]] -
          Total[Table[productChannels[m][[mu]], {m, sectors}]], {3}],
        {mu, 2}]];

    Print["CF303STRIPV1 stage=pullback"];
    pullbackSeconds = First@AbsoluteTiming[
      chartLeftChannels = pullBack[leftDiagonal];
      chartRightChannels = pullBack[rightDiagonal];
      chartForcingChannels = pullBack[sourceForcingChannels]];
    If[! And @@ (oddZeroQ /@ {chartLeftChannels, chartRightChannels,
          chartForcingChannels}),
      fail["the 17-to-12 strip did not collapse to the rational pair chart"]];
    rationalLeft = chartLeftChannels[[All, All, All, 1]];
    rationalRight = chartRightChannels[[All, All, All, 1]];
    rationalForcing = chartForcingChannels[[All, All, All, 1]];
    strip = {rationalLeft, rationalRight, rationalForcing};
    If[! FreeQ[strip,
        _Root | Power[_, exponent_Rational /;
          Denominator[exponent] > 1]],
      fail["rational chart strip still contains radicals"]];

    Print["CF303STRIPV1 stage=independent-rational-oracle"];
    rationalOracleSource = Table[Map[Together,
      directForcing[[mu, All, All, 1]] -
        Total[Table[
          solvedFactors[m][[All, All, 1]] .
            lowerConnectionFactors[m][[mu, All, All, 1]],
          {m, sectors}]], {2}], {mu, 2}];
    rationalOracleChart = pullBack[
      Map[Function[matrix, Map[Function[value, {value, 0}], matrix, {2}]],
        rationalOracleSource]][[All, All, All, 1]];
    checks = <|
      "AllMappedFactorsRational" -> And @@ Map[
        channelArrayOddZeroQ,
        Join[{leftDiagonal, rightDiagonal, directForcing},
          Values[solvedFactors], Values[lowerConnectionFactors]]],
      "IndependentDotOracleSameQ" ->
        TrueQ[rationalOracleChart === rationalForcing],
      "PullbackOrientationMutantRejected" ->
        ! TrueQ[pullBack[Reverse[sourceForcingChannels]][[All, All, All, 1]] ===
          rationalForcing]|>;
    If[! And @@ Values[checks],
      fail["adversarial strip assembly check failed: " <>
        ToString[checks, InputForm]]];

    payload = <|
      "Status" -> "CF303PairChartRationalStripV1",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "Variables" -> chartVariables, "Regulator" -> regulator,
      "Strip" -> strip, "Chart" -> "Kallen23",
      "SourceVariables" -> bundle["SourceVariables"],
      "SourceSubstitution" -> bundle["SourceSubstitution"],
      "Jacobian" -> jacobian, "SourceRoots" -> bundle["SourceRoots"],
      "RootImages" -> bundle["RootImages"],
      "NestedRadicand" -> bundle["NestedRadicand"],
      "NestedRootImage" -> bundle["NestedRootImage"],
      "FactorBundleFile" -> bundleFile,
      "FactorBundleSHA256" -> expectedBundleHash,
      "Checks" -> checks, "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[payload, payloadFile];
    summary = <|
      "Status" -> "CF303PairChartStripAssemblyPassedV1",
      "PayloadFile" -> payloadFile,
      "PayloadSHA256" -> hashHex[payloadFile],
      "PayloadBytes" -> FileByteCount[payloadFile],
      "StripDimensions" -> Dimensions /@ strip,
      "StripLeafCount" -> LeafCount[strip],
      "ProductSeconds" -> productSeconds,
      "PullbackSeconds" -> pullbackSeconds,
      "Checks" -> checks, "FactorBundleSHA256" -> expectedBundleHash,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303STRIPV1 status=PASS productSeconds=",
      Round[productSeconds, 0.1], " leafCount=", LeafCount[strip],
      " payload=", payloadFile];
    0,
    tag];
  result
]
