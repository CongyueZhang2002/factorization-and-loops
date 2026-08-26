#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, finiteFieldFile,
    stateFile, factorBundleFile, row17CertificateFile,
    row18CertificateFile, outdir, expectedHashes,
    hashHex, expressionHash, badHashes, dependencyFiles, dependencyHashes,
    state, bundle, row17Certificate, row18Certificate, ranges,
    connection, regulator,
    sourceVariables, chartVariables, substitution, jacobian, sourceRoots,
    imageRoots, residualRoot, nestedRadicand, nestedRootImage,
    leftDiagonalChart, canonicalize, usedRootIndices, mapScalarRational,
    mapMatrixRational, pullBack, zeroMatrixPairQ, putAtomic, exportAtomic,
    checkpointFiles, checkpointSector, latestCheckpointFile, checkpoint,
    solvedChart, solverSummaries, nextLowerSector, checkpointFileFor,
    writeCheckpoint, fail, tag, result, j, rowRange, lowerRange,
    intermediateSectors, activeIntermediateSectors, directSourceChart,
    lowerConnectionChart,
    rightDiagonalSourceChart, rightDiagonalChart, sourceForcingChart,
    forcingChart, strip, blockAttempt, blockDirectory, stripFile,
    solutionFile, summaryFile, artifactDirectory, stripPayload,
    solution, solveSeconds, zeroForcing, zeroGaugeQ, solverSummary,
    blockMappingStats, mappingStats = {}, campaignSummaryFile,
    campaignSummary, witnessFile, priorRowChecks, leftMappingStats},
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
  factorBundleFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  row17CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_certificate_v2/certificate.wxf";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1";
  campaignSummaryFile = FileNameJoin[{outdir, "campaign_summary.wl"}];
  tag = Unique["CF303Sector19PairRowCampaignV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    factorBundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    row17CertificateFile ->
      "adf9f2103dbecf16bac89cbe5be81909dc4bdfa3e5a0ff4e26f9bbeaed572435",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
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
  expressionHash[expression_] :=
    IntegerString[Hash[expression, "SHA256"], 16, 64];
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
      "Sector" -> 19, "NextLowerSector" -> nextLowerSector,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> ToString[If[IntegerQ[nextLowerSector],
          nextLowerSector, "preflight"]] <> "_" <>
          StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 SECTOR19 ROW CAMPAIGN FAILURE V1: ", status,
      " data=", data];
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

    Print["CF303S19ROWV1 stage=load-inputs"];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    state = Get[stateFile];
    bundle = Get[factorBundleFile];
    row17Certificate = Import[row17CertificateFile, "WXF"];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@
        {state, bundle, row17Certificate, row18Certificate}) ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[row17Certificate, "Status", None] =!=
          "CF303Sector17PairChartRowCertificatePassedV2" ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1",
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
    rowRange = ranges[[19]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {31, 32, 33, 34},
      fail["UnexpectedPinnedStateShape"]];
    priorRowChecks = <|
      "Sector17CertificatePassed" ->
        And @@ Values[row17Certificate["GlobalChecks"]],
      "Sector18CertificatePassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]],
      "Sector18CumulativeGaugeExactlyZero" -> TrueQ[
        Lookup[row18Certificate["GlobalChecks"],
          "EntireRowGaugeExactlyZero", False]],
      "Raw1917BlockStructurallyZero" -> AllTrue[
        Flatten[connection[[All, rowRange, ranges[[17]]]]],
        TrueQ[# === 0] &]|>;
    If[! And @@ Values[priorRowChecks],
      fail["PriorRowDecouplingCheckFailed", <|
        "Checks" -> priorRowChecks|>]];

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
        witnessFile = FileNameJoin[{outdir,
          "rank_one_transition_witness_" <> ToString[j] <> ".wxf"}];
        If[! FileExistsQ[witnessFile],
          exportAtomic[<|
            "Status" -> "CF303Sector19RankOneTransitionWitnessV1",
            "Family" -> "CF303", "Sector" -> 19,
            "LowerSector" -> j, "Label" -> label,
            "RootIndices" -> indices,
            "CanonicalSourceExpression" -> canonicalExpression,
            "ChartExpression" -> chartExpression,
            "ResidualChannels" -> residualChannels,
            "ResidualRoot" -> residualRoot,
            "InputHashes" -> expectedHashes,
            "PackageSourceModified" -> False,
            "Created" -> DateString[Now, "ISODateTime"]|>,
            witnessFile]];
        fail["ResidualThirdRootActivated", <|"Label" -> label,
          "LowerSector" -> j, "RootIndices" -> indices,
          "WitnessFile" -> witnessFile,
          "WitnessSHA256" -> hashHex[witnessFile]|>]];
      residualChannels[[1]]];
    mapMatrixRational[prefix_String, matrix_List] := MapIndexed[
      mapScalarRational[prefix <> "/" <>
        StringRiffle[ToString /@ #2, ","], #1] &, matrix, {2}];
    pullBack[pair_List] := Table[Map[Together,
      pair[[1]] jacobian[[1, component]] +
        pair[[2]] jacobian[[2, component]], {2}], {component, 2}];
    zeroMatrixPairQ[pair_List] := AllTrue[
      Flatten[Map[Together, pair, {3}]], TrueQ[# === 0] &];
    zeroGaugeQ[matrix_List] :=
      AllTrue[Flatten[matrix], TrueQ[# === 0] &];

    Print["CF303S19ROWV1 stage=map-left-diagonal"];
    blockMappingStats = {};
    j = 19;
    leftDiagonalChart = pullBack@Table[
      mapMatrixRational["E/" <> ToString[mu],
        connection[[mu, rowRange, rowRange]]/regulator], {mu, 2}];
    leftMappingStats = blockMappingStats;
    If[Dimensions[leftDiagonalChart] =!= {2, 4, 4} ||
        ! FreeQ[leftDiagonalChart,
          _Root | Power[_, exponent_Rational /;
            Denominator[exponent] > 1]],
      fail["LeftDiagonalMappingFailed", <|
        "Dimensions" -> Dimensions[leftDiagonalChart]|>]];

    checkpointFileFor[sector_Integer] := FileNameJoin[{outdir,
      "checkpoint_after_" <> ToString[sector] <> ".wxf"}];
    writeCheckpoint[sector_Integer, next_Integer] := Module[{payload, file},
      file = checkpointFileFor[sector];
      payload = <|"Status" -> If[next === 0,
          "CF303Sector19PairChartRowSolvedV1",
          "CF303Sector19PairChartRowCheckpointV1"],
        "Family" -> "CF303", "Sector" -> 19,
        "CompletedThroughLowerSector" -> sector,
        "NextLowerSector" -> next,
        "SolvedChartGauges" -> solvedChart,
        "SolvedChartGaugeFingerprint" -> expressionHash[solvedChart],
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
      solvedChart = <||>;
      solverSummaries = {};
      nextLowerSector = 18;
      Print["CF303S19ROWV1 initialized at lower sector 18"],
      latestCheckpointFile = First@MinimalBy[checkpointFiles,
        checkpointSector];
      checkpoint = Import[latestCheckpointFile, "WXF"];
      If[! AssociationQ[checkpoint] ||
          Lookup[checkpoint, "Family", None] =!= "CF303" ||
          Lookup[checkpoint, "Sector", None] =!= 19 ||
          Lookup[checkpoint, "InputHashes", None] =!= expectedHashes ||
          Lookup[checkpoint, "DependencyHashes", None] =!=
            dependencyHashes ||
          Lookup[checkpoint, "SolvedChartGaugeFingerprint", None] =!=
            expressionHash[Lookup[checkpoint, "SolvedChartGauges", <||>]],
        fail["InvalidResumeCheckpoint", <|
          "File" -> latestCheckpointFile|>]];
      solvedChart = checkpoint["SolvedChartGauges"];
      solverSummaries = checkpoint["SolverSummaries"];
      nextLowerSector = checkpoint["NextLowerSector"];
      Print["CF303S19ROWV1 resumed checkpoint=", latestCheckpointFile,
        " nextLowerSector=", nextLowerSector]];
    If[! IntegerQ[nextLowerSector] || nextLowerSector < 0 ||
        nextLowerSector > 18,
      fail["InvalidNextLowerSector"]];

    For[j = nextLowerSector, j >= 1, j--,
      nextLowerSector = j;
      lowerRange = ranges[[j]];
      intermediateSectors = Sort@Select[Keys[solvedChart], j < # < 19 &];
      If[intermediateSectors =!= Range[j + 1, 18],
        fail["SolvedGaugeChainHasGap", <|"LowerSector" -> j,
          "IntermediateSectors" -> intermediateSectors|>]];
      activeIntermediateSectors = Select[intermediateSectors,
        ! zeroGaugeQ[solvedChart[#]] &];
      If[MemberQ[activeIntermediateSectors, 17],
        fail["InstalledSector17RowWouldBeRequired", <|
          "LowerSector" -> j,
          "Gauge1917" -> solvedChart[17]|>]];
      blockMappingStats = {};
      Print["CF303S19ROWV1 block=", {19, j}, " stage=map-operands",
        " activeIntermediates=", activeIntermediateSectors,
        " skippedZeroIntermediates=",
        Complement[intermediateSectors, activeIntermediateSectors]];
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
        {mu, 2}], {m, activeIntermediateSectors}];
      sourceForcingChart = Table[Map[Together,
        directSourceChart[[mu]] - Total[Table[
          solvedChart[m] . lowerConnectionChart[m][[mu]],
          {m, activeIntermediateSectors}]], {2}], {mu, 2}];
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
        "Status" -> "CF303Sector19PairChartRationalStripV1",
        "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> j,
        "Variables" -> chartVariables, "Regulator" -> regulator,
        "Strip" -> strip, "Chart" -> "Kallen23",
        "IntermediateSectors" -> intermediateSectors,
        "ActiveIntermediateSectors" -> activeIntermediateSectors,
        "SkippedZeroIntermediateSectors" ->
          Complement[intermediateSectors, activeIntermediateSectors],
        "MappingStatistics" -> blockMappingStats,
        "InputHashes" -> expectedHashes,
        "PackageSourceModified" -> False,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      exportAtomic[stripPayload, stripFile];

      zeroForcing = zeroMatrixPairQ[forcingChart];
      Print["CF303S19ROWV1 block=", {19, j}, " stage=solve zeroForcing=",
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
            <|"Family" -> "CF303", "Sector" -> 19,
              "LowerSector" -> j, "Variables" -> chartVariables,
              "Regulator" -> regulator, "Strip" -> strip|>,
            "KernelCount" -> 5,
            "ArtifactDirectory" -> artifactDirectory,
            "ArtifactPrefix" -> "CF303_19_" <> ToString[j] <>
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
        exportAtomic[<|"Status" -> "CF303Sector19PairChartSolveFailedV1",
          "Result" -> solution|>, solutionFile];
        fail["StripSolveNotCertifiedDLog", <|"LowerSector" -> j,
          "SolveSeconds" -> solveSeconds,
          "SolutionSummary" -> If[AssociationQ[solution],
            KeyDrop[solution, {"Gauge", "ResidueMatrices",
              "EliminationPlan"}], solution]|>]];
      exportAtomic[<|"Status" ->
          "CF303Sector19PairChartDLogSolutionV1",
        "Family" -> "CF303", "Sector" -> 19, "LowerSector" -> j,
        "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
        "Solution" -> solution|>, solutionFile];
      solverSummary = <|"LowerSector" -> j,
        "Status" -> "CertifiedDLogStrip",
        "Method" -> Lookup[solution, "Method", "ZeroForcing"],
        "SolveSeconds" -> solveSeconds,
        "GaugeDimensions" -> Dimensions[solution["Gauge"]],
        "GaugeLeafCount" -> LeafCount[solution["Gauge"]],
        "GaugeFingerprint" -> expressionHash[solution["Gauge"]],
        "PriorCumulativeGaugeFingerprint" -> expressionHash[solvedChart],
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
      Print["CF303S19ROWV1 block=", {19, j},
        " status=PASS solveSeconds=",
        Round[solveSeconds, 0.1], " gaugeLeaves=",
        LeafCount[solution["Gauge"]]];
    ];

    nextLowerSector = 0;
    campaignSummary = <|
      "Status" -> "CF303Sector19PairChartRowSolvedV1",
      "Family" -> "CF303", "Sector" -> 19,
      "CompletedLowerSectors" -> Reverse[Range[1, 18]],
      "SolvedGaugeSectors" -> Sort[Keys[solvedChart]],
      "SolverSummaries" -> solverSummaries,
      "FinalCheckpoint" -> checkpointFileFor[1],
      "FinalCheckpointSHA256" -> hashHex[checkpointFileFor[1]],
      "TotalSolveSeconds" -> Total[Lookup[solverSummaries,
        "SolveSeconds", {}]],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PriorRowChecks" -> priorRowChecks,
      "LeftDiagonalMappingStatistics" -> leftMappingStats,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[! FileExistsQ[campaignSummaryFile],
      putAtomic[campaignSummary, campaignSummaryFile]];
    Print["CF303S19ROWV1 status=PASS finalCheckpoint=",
      checkpointFileFor[1], " totalSolveSeconds=",
      Round[campaignSummary["TotalSolveSeconds"], 0.1]];
    0,
    tag];
  result
]
