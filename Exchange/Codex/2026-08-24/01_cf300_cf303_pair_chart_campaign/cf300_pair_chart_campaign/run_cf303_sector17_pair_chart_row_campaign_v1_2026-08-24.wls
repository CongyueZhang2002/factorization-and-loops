#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, finiteFieldFile,
    stateFile, sourceCheckpointFile, factorBundleFile, strip12File,
    solution12File, outdir, expectedHashes, hashHex, badHashes,
    dependencyFiles, dependencyHashes, state, sourceCheckpoint, bundle,
    strip12Payload, solution12Payload, ranges, connection, regulator,
    sourceVariables, chartVariables, substitution, jacobian, sourceRoots,
    imageRoots, residualRoot, nestedRadicand, nestedRootImage,
    leftDiagonalChart, canonicalize, usedRootIndices, mapScalarRational,
    mapMatrixRational, pullBack, zeroMatrixPairQ, putAtomic, exportAtomic,
    checkpointFiles, checkpointSector, latestCheckpointFile, checkpoint,
    solvedChart, solverSummaries, nextLowerSector, checkpointFileFor,
    writeCheckpoint, fail, tag, result, j, rowRange, lowerRange,
    intermediateSectors, directSourceChart, lowerConnectionChart,
    rightDiagonalSourceChart, rightDiagonalChart, sourceForcingChart,
    forcingChart, strip, blockAttempt, blockDirectory, stripFile,
    solutionFile, summaryFile, artifactDirectory, stripPayload,
    solution, solveSeconds, zeroForcing, solverSummary, blockMappingStats,
    mappingStats = {}, campaignSummaryFile, campaignSummary},
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
  sourceCheckpointFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_CF303_identity_capture_xh_v4/CF303_17_strip_state.wl";
  factorBundleFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  strip12File = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_strip_v1/CF303_17_12_pair_chart_strip_v1.wxf";
  solution12File = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_campaign_v1";
  campaignSummaryFile = FileNameJoin[{outdir, "campaign_summary.wl"}];
  tag = Unique["CF303Sector17PairRowCampaignV1$"];
  expectedHashes = <|
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    sourceCheckpointFile ->
      "87528ab68d77c4e6e1492dec7f58d59dfc8cb0d29b4e2791ee0bfe6f620f999a",
    factorBundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    strip12File ->
      "246b89517021211fd41470a4ff7ec6591c674b9f694481c820a8b9b8bf3779d4",
    solution12File ->
      "20ed234d0bb41933aa120f329193779c005be920fabbdc84d493f5c55985a3e9",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1"|>;
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
      "Sector" -> 17, "NextLowerSector" -> nextLowerSector,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> ToString[If[IntegerQ[nextLowerSector],
          nextLowerSector, "preflight"]] <> "_" <>
          StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 ROW CAMPAIGN FAILURE V1: ", status, " data=", data];
    Throw[$Failed, tag]];

  result = Catch[
    nextLowerSector = Missing["NotInitialized"];
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["PoolWorkerRequired"]];
    If[Length[Kernels[]] =!= 0,
      fail["MissionWorkerAlreadyOwnsNestedKernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 4),
      fail["HelperCeilingMustBeFour"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    If[! DirectoryQ[outdir], CreateDirectory[outdir]];

    Print["CF303ROWV1 stage=load-inputs"];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    state = Get[stateFile];
    sourceCheckpoint = Get[sourceCheckpointFile];
    bundle = Get[factorBundleFile];
    strip12Payload = Import[strip12File, "WXF"];
    solution12Payload = Import[solution12File, "WXF"];
    If[! And @@ (AssociationQ /@
        {state, sourceCheckpoint, bundle, strip12Payload,
          solution12Payload}) ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[strip12Payload, "Status", None] =!=
          "CF303PairChartRationalStripV1" ||
        Lookup[solution12Payload, "Status", None] =!=
          "CF303PairChartRationalSolutionV1",
      fail["InvalidInputABI"]];
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
    leftDiagonalChart = strip12Payload["Strip"][[1]];
    rowRange = ranges[[17]];
    If[Dimensions[connection] =!= {2, 45, 45} || rowRange =!= {28} ||
        Dimensions[leftDiagonalChart] =!= {2, 1, 1},
      fail["UnexpectedPinnedStateShape"]];

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
    mapScalarRational[label_String, expression_] := Module[
      {canonicalExpression, indices, sourceChannels, chartChannels,
       chartExpression, residualChannels, seconds},
      If[TrueQ[expression === 0], Return[0]];
      canonicalExpression = canonicalize[expression];
      indices = usedRootIndices[canonicalExpression];
      seconds = First@AbsoluteTiming[
        sourceChannels = FeynFacet`Private`multiquadraticFieldDecompose[
          canonicalExpression, sourceRoots[[indices]]];
        If[sourceChannels === $Failed,
          fail["SourceFactorDecompositionFailed", <|"Label" -> label,
            "RootIndices" -> indices|>]];
        chartChannels = Together /@ (sourceChannels /. substitution);
        chartExpression = FeynFacet`Private`multiquadraticFieldCompose[
          chartChannels, imageRoots[[indices]]];
        If[chartExpression === $Failed,
          fail["ChartFactorCompositionFailed", <|"Label" -> label|>]];
        residualChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            chartExpression, {residualRoot}]];
      If[residualChannels === $Failed,
        fail["ResidualRankOneDecompositionFailed", <|"Label" -> label,
          "RootIndices" -> indices|>]];
      AppendTo[blockMappingStats, <|"Label" -> label,
        "RootIndices" -> indices, "Seconds" -> seconds,
        "SourceLeafCount" -> LeafCount[expression],
        "ChartLeafCount" -> LeafCount[residualChannels[[1]]],
        "ResidualOddChannelZero" ->
          TrueQ[residualChannels[[2]] === 0]|>];
      If[! TrueQ[residualChannels[[2]] === 0],
        fail["ResidualThirdRootActivated", <|"Label" -> label,
          "LowerSector" -> j, "RootIndices" -> indices|>]];
      residualChannels[[1]]];
    mapMatrixRational[prefix_String, matrix_List] := MapIndexed[
      mapScalarRational[prefix <> "/" <>
        StringRiffle[ToString /@ #2, ","], #1] &, matrix, {2}];
    pullBack[pair_List] := Table[Map[Together,
      pair[[1]] jacobian[[1, component]] +
        pair[[2]] jacobian[[2, component]], {2}], {component, 2}];
    zeroMatrixPairQ[pair_List] := AllTrue[
      Flatten[Map[Together, pair, {3}]], TrueQ[# === 0] &];

    checkpointFileFor[sector_Integer] := FileNameJoin[{outdir,
      "checkpoint_after_" <> ToString[sector] <> ".wxf"}];
    writeCheckpoint[sector_Integer, next_Integer] := Module[{payload, file},
      file = checkpointFileFor[sector];
      payload = <|"Status" -> If[next === 0,
          "CF303Sector17PairChartRowSolvedV1",
          "CF303Sector17PairChartRowCheckpointV1"],
        "Family" -> "CF303", "Sector" -> 17,
        "CompletedThroughLowerSector" -> sector,
        "NextLowerSector" -> next,
        "SolvedChartGauges" -> solvedChart,
        "SolverSummaries" -> solverSummaries,
        "InputHashes" -> expectedHashes,
        "DependencyHashes" -> dependencyHashes,
        "PackageSourceModified" -> False,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      exportAtomic[payload, file];
      file];
    checkpointSector[file_String] := Quiet[Check[ToExpression[
      First@StringCases[FileNameTake[file],
        "checkpoint_after_" ~~ number : DigitCharacter .. ~~ ".wxf" :>
          number]], Infinity]];

    checkpointFiles = FileNames["checkpoint_after_*.wxf", outdir];
    If[checkpointFiles === {},
      solvedChart = Map[#[[All, All, 1]] &,
        bundle["SolvedFactorChannels"]];
      solvedChart[12] = solution12Payload["Solution", "Gauge"];
      solverSummaries = {<|"LowerSector" -> 12,
        "Status" -> "CF303PairChartDLogStripCertificatePassedV2",
        "SolutionFile" -> solution12File,
        "SolveSeconds" -> 10.208938,
        "ExactDLog" -> True,
        "RegulatorFactorizationPending" -> True|>};
      nextLowerSector = 11;
      writeCheckpoint[12, 11];
      Print["CF303ROWV1 initialized checkpoint after lower sector 12"],
      latestCheckpointFile = First@MinimalBy[checkpointFiles,
        checkpointSector];
      checkpoint = Import[latestCheckpointFile, "WXF"];
      If[! AssociationQ[checkpoint] ||
          Lookup[checkpoint, "Family", None] =!= "CF303" ||
          Lookup[checkpoint, "Sector", None] =!= 17 ||
          Lookup[checkpoint, "InputHashes", None] =!= expectedHashes ||
          Lookup[checkpoint, "DependencyHashes", None] =!=
            dependencyHashes,
        fail["InvalidResumeCheckpoint", <|
          "File" -> latestCheckpointFile|>]];
      solvedChart = checkpoint["SolvedChartGauges"];
      solverSummaries = checkpoint["SolverSummaries"];
      nextLowerSector = checkpoint["NextLowerSector"];
      Print["CF303ROWV1 resumed checkpoint=", latestCheckpointFile,
        " nextLowerSector=", nextLowerSector]];
    If[! IntegerQ[nextLowerSector] || nextLowerSector < 0 ||
        nextLowerSector > 11,
      fail["InvalidNextLowerSector"]];

    For[j = nextLowerSector, j >= 1, j--,
      nextLowerSector = j;
      lowerRange = ranges[[j]];
      intermediateSectors = Sort@Select[Keys[solvedChart], j < # < 17 &];
      If[intermediateSectors =!= Range[j + 1, 16],
        fail["SolvedGaugeChainHasGap", <|"LowerSector" -> j,
          "IntermediateSectors" -> intermediateSectors|>]];
      blockMappingStats = {};
      Print["CF303ROWV1 block=", {17, j}, " stage=map-operands",
        " intermediates=", intermediateSectors];
      rightDiagonalSourceChart = Table[
        mapMatrixRational["C/" <> ToString[mu],
          connection[[mu, lowerRange, lowerRange]]/regulator], {mu, 2}];
      rightDiagonalChart = pullBack[rightDiagonalSourceChart];
      directSourceChart = Table[
        mapMatrixRational["Bdirect/" <> ToString[mu],
          connection[[mu, rowRange, lowerRange]]], {mu, 2}];
      lowerConnectionChart = Association@Table[m -> Table[
        mapMatrixRational["Alower/" <> ToString[mu] <> "/" <>
          ToString[m], connection[[mu, ranges[[m]], lowerRange]]],
        {mu, 2}], {m, intermediateSectors}];
      sourceForcingChart = Table[Map[Together,
        directSourceChart[[mu]] - Total[Table[
          solvedChart[m] . lowerConnectionChart[m][[mu]],
          {m, intermediateSectors}]], {2}], {mu, 2}];
      forcingChart = pullBack[sourceForcingChart];
      strip = {leftDiagonalChart, rightDiagonalChart, forcingChart};
      If[! FreeQ[strip, _Root | Power[_, exponent_Rational /;
            Denominator[exponent] > 1]],
        fail["ChartStripContainsRadicals", <|"LowerSector" -> j|>]];

      blockAttempt = 1 + Length[FileNames[
        "block_" <> ToString[j] <> "_attempt_*", outdir]];
      blockDirectory = FileNameJoin[{outdir,
        "block_" <> ToString[j] <> "_attempt_" <>
          ToString[blockAttempt]}];
      CreateDirectory[blockDirectory];
      stripFile = FileNameJoin[{blockDirectory, "strip.wxf"}];
      solutionFile = FileNameJoin[{blockDirectory, "solution.wxf"}];
      summaryFile = FileNameJoin[{blockDirectory, "summary.wl"}];
      artifactDirectory = FileNameJoin[{blockDirectory, "finite_field"}];
      stripPayload = <|
        "Status" -> "CF303Sector17PairChartRationalStripV1",
        "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> j,
        "Variables" -> chartVariables, "Regulator" -> regulator,
        "Strip" -> strip, "Chart" -> "Kallen23",
        "IntermediateSectors" -> intermediateSectors,
        "MappingStatistics" -> blockMappingStats,
        "InputHashes" -> expectedHashes,
        "PackageSourceModified" -> False,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      exportAtomic[stripPayload, stripFile];

      zeroForcing = zeroMatrixPairQ[forcingChart];
      Print["CF303ROWV1 block=", {17, j}, " stage=solve zeroForcing=",
        zeroForcing, " stripLeaves=", LeafCount[strip]];
      If[zeroForcing,
        solveSeconds = 0.;
        solution = <|"Status" -> "Solved", "Method" -> "ZeroForcing",
          "Gauge" -> ConstantArray[0,
            Dimensions[forcingChart[[1]]]], "Alphabet" -> {},
          "ResidueMatrices" -> {}, "ExactDLog" -> True,
          "ExactPfaffianResidualsZero" -> True,
          "LettersEpsFree" -> True, "ResiduesKinematicsFree" -> True,
          "DLogFormCertified" -> True|>,
        CreateDirectory[artifactDirectory];
        solveSeconds = First@AbsoluteTiming[
          solution = FeynFacet`SolveEpsFormStripFiniteField[
            <|"Family" -> "CF303", "Sector" -> 17,
              "LowerSector" -> j, "Variables" -> chartVariables,
              "Regulator" -> regulator, "Strip" -> strip|>,
            "KernelCount" -> 5,
            "ArtifactDirectory" -> artifactDirectory,
            "ArtifactPrefix" -> "CF303_17_" <> ToString[j] <>
              "_pair_chart_row_v1",
            "Backend" -> Automatic, "BackendThreads" -> 1,
            "PlanDiscoveryBackend" -> "Wolfram",
            "SupportStrategy" -> "SimplexFirst",
            "SupportLearning" -> True,
            "RegulatorSampling" -> "HeldOut",
            "FinalCheck" -> "Exact", "Verbose" -> True]]];
      If[! AssociationQ[solution] ||
          Lookup[solution, "Status", None] =!= "Solved" ||
          ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
          ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]] ||
          ! TrueQ[Lookup[solution, "LettersEpsFree", False]] ||
          ! TrueQ[Lookup[solution, "ResiduesKinematicsFree", False]] ||
          ! TrueQ[Lookup[solution, "DLogFormCertified", False]],
        exportAtomic[<|"Status" -> "CF303Sector17PairChartSolveFailedV1",
          "Result" -> solution|>, solutionFile];
        fail["StripSolveNotCertifiedDLog", <|"LowerSector" -> j,
          "SolveSeconds" -> solveSeconds,
          "SolutionSummary" -> If[AssociationQ[solution],
            KeyDrop[solution, {"Gauge", "ResidueMatrices",
              "EliminationPlan"}], solution]|>]];
      exportAtomic[<|"Status" ->
          "CF303Sector17PairChartDLogSolutionV1",
        "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> j,
        "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
        "Solution" -> solution|>, solutionFile];
      solverSummary = <|"LowerSector" -> j,
        "Status" -> "CertifiedDLogStrip",
        "Method" -> Lookup[solution, "Method", "ZeroForcing"],
        "SolveSeconds" -> solveSeconds,
        "GaugeDimensions" -> Dimensions[solution["Gauge"]],
        "GaugeLeafCount" -> LeafCount[solution["Gauge"]],
        "AlphabetLength" -> Length[Lookup[solution, "Alphabet", {}]],
        "ExactDLog" -> True,
        "ResiduesEpsFree" ->
          TrueQ[Lookup[solution, "ResiduesEpsFree", True]],
        "RegulatorFactorizationPending" -> True,
        "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
        "SolutionFile" -> solutionFile,
        "SolutionSHA256" -> hashHex[solutionFile],
        "MappingScalarCount" -> Length[blockMappingStats],
        "MappingSeconds" -> Total[Lookup[blockMappingStats, "Seconds", {}]]|>;
      putAtomic[solverSummary, summaryFile];
      solvedChart[j] = solution["Gauge"];
      AppendTo[solverSummaries, solverSummary];
      AppendTo[mappingStats, <|"LowerSector" -> j,
        "Statistics" -> blockMappingStats|>];
      writeCheckpoint[j, j - 1];
      If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
        fail["PackageChangedDuringCampaign", <|"LowerSector" -> j|>]];
      Print["CF303ROWV1 block=", {17, j}, " status=PASS solveSeconds=",
        Round[solveSeconds, 0.1], " gaugeLeaves=",
        LeafCount[solution["Gauge"]]];
    ];

    nextLowerSector = 0;
    campaignSummary = <|
      "Status" -> "CF303Sector17PairChartRowSolvedV1",
      "Family" -> "CF303", "Sector" -> 17,
      "CompletedLowerSectors" -> Reverse[Range[1, 16]],
      "SolvedGaugeSectors" -> Sort[Keys[solvedChart]],
      "SolverSummaries" -> solverSummaries,
      "FinalCheckpoint" -> checkpointFileFor[1],
      "FinalCheckpointSHA256" -> hashHex[checkpointFileFor[1]],
      "TotalSolveSeconds" -> Total[Lookup[solverSummaries,
        "SolveSeconds", {}]],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[! FileExistsQ[campaignSummaryFile],
      putAtomic[campaignSummary, campaignSummaryFile]];
    Print["CF303ROWV1 status=PASS finalCheckpoint=",
      checkpointFileFor[1], " totalSolveSeconds=",
      Round[campaignSummary["TotalSolveSeconds"], 0.1]];
    0,
    tag];
  result
]
