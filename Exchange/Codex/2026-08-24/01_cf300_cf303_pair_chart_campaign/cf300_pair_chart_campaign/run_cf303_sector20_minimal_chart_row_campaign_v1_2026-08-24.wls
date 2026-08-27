#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, multiquadraticFile,
    finiteFieldFile, stateFile, seedSolutionFile, row17CertificateFile,
    row18CertificateFile, row19CertificateFile, outdir,
    campaignSummaryFile, expectedHashes, dependencyFiles,
    dependencyHashes, hashHex, expressionHash, putAtomic, exportAtomic,
    fail, stopNoChart, tag, result, badHashes, state, seedPayload,
    seedSolution, row17Certificate, row18Certificate, row19Certificate,
    ranges, connection, variables, regulator, rowRange, range18,
    rootSquares, frameVariables, frame, allRoots, rootCensus, zeroPairQ,
    zeroGaugeQ, upperDiagonal, upperCensus, priorRowChecks,
    checkpointFileFor, checkpointSector, writeCheckpoint, checkpointFiles,
    latestCheckpointFile, checkpoint, solvedSource, solverSummaries,
    nextLowerSector, j, lowerRange, intermediateSectors,
    activeIntermediateSectors, directForcing, lowerConnections, forcing,
    lowerDiagonal, strip, stripCensus, activeRootSquares, chart, chartName,
    blockAttempt, blockDirectory, stripFile, solutionFile, summaryFile,
    artifactDirectory, stripPayload, solution, solveSeconds,
    solutionChecks, gaugeCensus, solverSummary, witnessFile,
    campaignSummary, rowGauge, nilpotent, unipotent, inverse,
    finalChecks},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  seedSolutionFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_bilinear115_solve_v1/solution.wxf";
  row17CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_certificate_v2/certificate.wxf";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1";
  campaignSummaryFile = FileNameJoin[{outdir, "campaign_summary.wl"}];
  tag = Unique["CF303Sector20MinimalChartRowCampaignV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    seedSolutionFile ->
      "687cc3815fd18be7e3a5a9f4f9ad893e7062012366fdab66a33faea88681ef9f",
    row17CertificateFile ->
      "adf9f2103dbecf16bac89cbe5be81909dc4bdfa3e5a0ff4e26f9bbeaed572435",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile,
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
      "Sector" -> 20, "NextLowerSector" -> nextLowerSector,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> ToString[If[IntegerQ[nextLowerSector],
          nextLowerSector, "preflight"]] <> "_" <>
          StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 SECTOR20 MINIMAL-CHART CAMPAIGN FAILURE V1: ",
      status, " data=", data];
    Throw[$Failed, tag]];
  stopNoChart[sector_Integer, census_Association,
      payloadFile_String] := Module[{stopSummary},
    witnessFile = FileNameJoin[{outdir,
      "no_joint_rational_chart_at_" <> ToString[sector] <> ".wxf"}];
    exportAtomic[<|
      "Status" -> "CF303Sector20NoJointRationalChartWitnessV1",
      "Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> sector, "RootCensus" -> census,
      "StripFile" -> payloadFile, "StripSHA256" -> hashHex[payloadFile],
      "SolvedSourceGaugeFingerprint" -> expressionHash[solvedSource],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, witnessFile];
    stopSummary = <|
      "Status" ->
        "CF303Sector20MinimalChartRowStoppedNoJointRationalChartV1",
      "Family" -> "CF303", "Sector" -> 20,
      "CompletedThroughLowerSector" -> sector + 1,
      "NextLowerSector" -> sector,
      "RootIndices" -> census["RootIndices"],
      "WitnessFile" -> witnessFile,
      "WitnessSHA256" -> hashHex[witnessFile],
      "SolverSummaries" -> solverSummaries,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[! FileExistsQ[campaignSummaryFile],
      putAtomic[stopSummary, campaignSummaryFile]];
    Print["CF303S20MINCHARTV1 status=STOP_NO_CHART lowerSector=",
      sector, " rootIndices=", census["RootIndices"],
      " witness=", witnessFile];
    Throw[0, tag]];

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
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];

    Print["CF303S20MINCHARTV1 stage=load-inputs"];
    state = Get[stateFile];
    seedPayload = Import[seedSolutionFile, "WXF"];
    row17Certificate = Import[row17CertificateFile, "WXF"];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@ {state, seedPayload,
          row17Certificate, row18Certificate, row19Certificate}) ||
        Lookup[seedPayload, "Status", None] =!=
          "CF303Sector2018Bilinear115SolvedV1" ||
        Lookup[row17Certificate, "Status", None] =!=
          "CF303Sector17PairChartRowCertificatePassedV2" ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1",
      fail["InvalidInputABI"]];
    seedSolution = Lookup[seedPayload, "Solution", $Failed];
    If[! AssociationQ[seedSolution] ||
        Lookup[seedSolution, "Status", None] =!= "Solved" ||
        Lookup[seedSolution, "RootIndices", None] =!= {3} ||
        ! TrueQ[Lookup[seedSolution, "ExactDLog", False]] ||
        ! TrueQ[Lookup[Lookup[seedSolution, "FrameCertificate", <||>],
          "Exact", False]],
      fail["Pinned2018SolutionNotExact"]];
    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[20]];
    range18 = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        Length[ranges] =!= 25 || rowRange =!= {35, 36} ||
        range18 =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];

    zeroPairQ[pair_] := AllTrue[Flatten[Map[Together, pair, {3}]],
      TrueQ[# === 0] &];
    zeroGaugeQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];
    priorRowChecks = <|
      "Sector17CertificatePassed" ->
        And @@ Values[row17Certificate["GlobalChecks"]],
      "Sector18CertificatePassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]],
      "Sector19CertificatePassed" ->
        And @@ Values[row19Certificate["GlobalChecks"]],
      "Sector18RowGaugeExactlyZero" ->
        zeroGaugeQ[row18Certificate["RowGauge"]],
      "Raw2019BlockStructurallyZero" ->
        zeroPairQ[connection[[All, rowRange, ranges[[19]]]]],
      "Raw2017BlockStructurallyZero" ->
        zeroPairQ[connection[[All, rowRange, ranges[[17]]]]],
      "Raw1817BlockStructurallyZero" ->
        zeroPairQ[connection[[All, range18, ranges[[17]]]]]|>;
    If[! And @@ Values[priorRowChecks],
      fail["PriorRowDecouplingCheckFailed", <|
        "Checks" -> priorRowChecks|>]];

    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector20Frame`p"],
      Symbol["CF303Sector20Frame`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["SourceMultiquadraticFrameFailed"]];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    If[! ListQ[allRoots] || Length[allRoots] =!= 3,
      fail["InvalidCurrentRoots"]];
    rootCensus[expression_] := Module[{census},
      census = FeynFacet`Private`transportChartRootIndices[
        expression, allRoots];
      If[! AssociationQ[census] ||
          Lookup[census, "UnclassifiedRadicalBases", {1}] =!= {},
        fail["UnclassifiedRadical", <|"Census" -> census|>]];
      census];
    upperDiagonal = connection[[All, rowRange, rowRange]]/regulator;
    upperCensus = rootCensus[upperDiagonal];
    If[upperCensus["RootIndices"] =!= {3},
      fail["UnexpectedUpperDiagonalRootSet", <|
        "Census" -> upperCensus|>]];

    checkpointFileFor[sector_Integer] := FileNameJoin[{outdir,
      "checkpoint_after_" <> ToString[sector] <> ".wxf"}];
    writeCheckpoint[sector_Integer, next_Integer] := Module[{payload, file},
      file = checkpointFileFor[sector];
      payload = <|"Status" -> If[next === 0,
          "CF303Sector20MinimalChartRowSolvedV1",
          "CF303Sector20MinimalChartRowCheckpointV1"],
        "Family" -> "CF303", "Sector" -> 20,
        "CompletedThroughLowerSector" -> sector,
        "NextLowerSector" -> next,
        "SolvedSourceGauges" -> solvedSource,
        "SolvedSourceGaugeFingerprint" -> expressionHash[solvedSource],
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
      solvedSource = <|
        19 -> ConstantArray[0, {2, Length[ranges[[19]]]}],
        18 -> Map[Together, seedSolution["Gauge"], {2}]|>;
      solverSummaries = {
        <|"LowerSector" -> 19, "Status" -> "CertifiedDLogStrip",
          "Method" -> "ZeroForcing", "Inherited" -> True,
          "SolveSeconds" -> 0.,
          "GaugeDimensions" -> Dimensions[solvedSource[19]],
          "GaugeLeafCount" -> LeafCount[solvedSource[19]],
          "RootIndices" -> {3}, "ExactDLog" -> True|>,
        <|"LowerSector" -> 18, "Status" -> "CertifiedDLogStrip",
          "Method" -> seedSolution["Method"], "Inherited" -> True,
          "SolveSeconds" -> Lookup[seedPayload, "SolveSeconds", 0.],
          "GaugeDimensions" -> Dimensions[solvedSource[18]],
          "GaugeLeafCount" -> LeafCount[solvedSource[18]],
          "RootIndices" -> seedSolution["RootIndices"],
          "ExactDLog" -> True, "SolutionFile" -> seedSolutionFile,
          "SolutionSHA256" -> hashHex[seedSolutionFile]|>};
      nextLowerSector = 17;
      writeCheckpoint[18, 17];
      Print["CF303S20MINCHARTV1 initialized at lower sector 17"],
      latestCheckpointFile = First@MinimalBy[checkpointFiles,
        checkpointSector];
      checkpoint = Import[latestCheckpointFile, "WXF"];
      If[! AssociationQ[checkpoint] ||
          Lookup[checkpoint, "Family", None] =!= "CF303" ||
          Lookup[checkpoint, "Sector", None] =!= 20 ||
          Lookup[checkpoint, "InputHashes", None] =!= expectedHashes ||
          Lookup[checkpoint, "DependencyHashes", None] =!=
            dependencyHashes ||
          Lookup[checkpoint, "SolvedSourceGaugeFingerprint", None] =!=
            expressionHash[Lookup[checkpoint,
              "SolvedSourceGauges", <||>]],
        fail["InvalidResumeCheckpoint", <|
          "File" -> latestCheckpointFile|>]];
      solvedSource = checkpoint["SolvedSourceGauges"];
      solverSummaries = checkpoint["SolverSummaries"];
      nextLowerSector = checkpoint["NextLowerSector"];
      Print["CF303S20MINCHARTV1 resumed checkpoint=",
        latestCheckpointFile, " nextLowerSector=", nextLowerSector]];
    If[! IntegerQ[nextLowerSector] || nextLowerSector < 0 ||
        nextLowerSector > 17,
      fail["InvalidNextLowerSector"]];

    For[j = nextLowerSector, j >= 1, j--,
      nextLowerSector = j;
      lowerRange = ranges[[j]];
      intermediateSectors = Range[j + 1, 19];
      If[Sort[Keys[solvedSource]] =!= intermediateSectors,
        fail["SolvedGaugeChainHasGap", <|"LowerSector" -> j,
          "ExpectedIntermediateSectors" -> intermediateSectors,
          "ActualSolvedSectors" -> Sort[Keys[solvedSource]]|>]];
      activeIntermediateSectors = Select[intermediateSectors,
        ! zeroGaugeQ[solvedSource[#]] &];
      directForcing = connection[[All, rowRange, lowerRange]];
      lowerConnections = Association@Table[m ->
        connection[[All, ranges[[m]], lowerRange]],
        {m, activeIntermediateSectors}];
      forcing = Table[Map[Together,
        directForcing[[mu]] - If[activeIntermediateSectors === {},
          0, Total[(solvedSource[#] . lowerConnections[#][[mu]]) & /@
            activeIntermediateSectors]], {2}], {mu, 2}];
      lowerDiagonal = connection[[All, lowerRange, lowerRange]]/regulator;
      strip = {upperDiagonal, lowerDiagonal, forcing};
      stripCensus = rootCensus[strip];
      activeRootSquares = Lookup[
        allRoots[[stripCensus["RootIndices"]]], "RootSquare", {}];

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
      chart = If[zeroPairQ[forcing], None,
        FeynFacet`TransportRootSetChart[activeRootSquares, variables]];
      chartName = Which[
        zeroPairQ[forcing], "ZeroForcing",
        AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
        True, "NoJointRationalChart"];
      stripPayload = <|
        "Status" -> "CF303Sector20DependencyClosedSourceStripV1",
        "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> j,
        "Variables" -> variables, "Regulator" -> regulator,
        "Strip" -> strip, "RootCensus" -> stripCensus,
        "SelectedRoute" -> chartName,
        "IntermediateSectors" -> intermediateSectors,
        "ActiveIntermediateSectors" -> activeIntermediateSectors,
        "SkippedZeroIntermediateSectors" ->
          Complement[intermediateSectors, activeIntermediateSectors],
        "DirectForcing" -> directForcing,
        "ActiveGauges" -> KeyTake[solvedSource,
          activeIntermediateSectors],
        "LowerConnections" -> lowerConnections,
        "AssembledForcing" -> forcing,
        "PriorCumulativeGaugeFingerprint" -> expressionHash[solvedSource],
        "InputHashes" -> expectedHashes,
        "DependencyHashes" -> dependencyHashes,
        "PackageSourceModified" -> False,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      exportAtomic[stripPayload, stripFile];
      Print["CF303S20MINCHARTV1 block=", {20, j},
        " zeroForcing=", zeroPairQ[forcing],
        " rootIndices=", stripCensus["RootIndices"],
        " route=", chartName, " activeIntermediates=",
        activeIntermediateSectors];

      If[! zeroPairQ[forcing] && ! AssociationQ[chart],
        stopNoChart[j, stripCensus, stripFile]];
      If[zeroPairQ[forcing],
        solveSeconds = 0.;
        solution = <|"Status" -> "Solved", "Method" -> "ZeroForcing",
          "Gauge" -> ConstantArray[0, Dimensions[forcing[[1]]]],
          "RootIndices" -> stripCensus["RootIndices"],
          "RootSquares" -> activeRootSquares, "Chart" -> None,
          "Alphabet" -> {}, "ExactDLog" -> True,
          "Certificate" -> "ExactDLog", "FrameCertificate" -> <|
            "Chart" -> None, "GaugeRoundTrip" -> True,
            "TransformedOneFormPullBack" -> True,
            "SourceDLog" -> True, "SamplingEntered" -> False,
            "Exact" -> True|>|>,
        CreateDirectory[artifactDirectory];
        solveSeconds = First@AbsoluteTiming[
          solution = FeynFacet`SolveEpsFormStripInFrame[
            strip, variables, regulator, frame,
            "FiniteFieldFirst" -> True,
            "FiniteFieldFallback" -> True,
            "MultiquadraticDispatch" -> False,
            "CANONICAKernels" -> 5,
            "ScratchDirectory" -> blockDirectory,
            "Tag" -> "CF303_20_" <> ToString[j] <>
              "_minimal_chart_row_v1",
            "FiniteFieldOptions" -> {
              "KernelCount" -> 5,
              "ArtifactDirectory" -> artifactDirectory,
              "ArtifactPrefix" -> "CF303_20_" <> ToString[j] <>
                "_minimal_chart_row_v1",
              "Backend" -> Automatic, "BackendThreads" -> 1,
              "PlanDiscoveryBackend" -> "FLINTAffineRREF",
              "SupportStrategy" -> "SimplexFirst",
              "SupportLearning" -> True,
              "RegulatorSampling" -> "HeldOut",
              "FinalCheck" -> "Exact", "Verbose" -> True},
            "Verbose" -> True]]];
      solutionChecks = <|
        "SolvedStatus" -> AssociationQ[solution] &&
          Lookup[solution, "Status", None] === "Solved",
        "ExactDLog" -> TrueQ[Lookup[solution, "ExactDLog", False]],
        "GaugeDimensions" -> Dimensions[
          Lookup[solution, "Gauge", {}]] === Dimensions[forcing[[1]]],
        "RootCensusAgrees" -> Lookup[solution,
          "RootIndices", None] === stripCensus["RootIndices"],
        "SelectedChartAgrees" -> (zeroPairQ[forcing] ||
          StringContainsQ[ToString[Lookup[solution, "Method", ""]],
            chartName]),
        "GaugeRoundTrip" -> TrueQ[Lookup[
          Lookup[solution, "FrameCertificate", <||>],
          "GaugeRoundTrip", False]],
        "TransformedOneFormPullBack" -> TrueQ[Lookup[
          Lookup[solution, "FrameCertificate", <||>],
          "TransformedOneFormPullBack", False]],
        "SourceDLog" -> TrueQ[Lookup[
          Lookup[solution, "FrameCertificate", <||>],
          "SourceDLog", False]],
        "FrameCertificateExact" -> TrueQ[Lookup[
          Lookup[solution, "FrameCertificate", <||>],
          "Exact", False]]|>;
      If[! And @@ Values[solutionChecks],
        exportAtomic[<|
          "Status" -> "CF303Sector20MinimalChartSolveFailedV1",
          "Family" -> "CF303", "Sector" -> 20,
          "LowerSector" -> j, "Checks" -> solutionChecks,
          "Result" -> solution|>, solutionFile];
        fail["StripSolveNotExactlyCertified", <|
          "LowerSector" -> j, "SolveSeconds" -> solveSeconds,
          "Checks" -> solutionChecks,
          "SolutionSummary" -> If[AssociationQ[solution],
            KeyDrop[solution, {"Gauge", "ResidueMatrices",
              "EliminationPlan"}], solution]|>]];
      gaugeCensus = rootCensus[solution["Gauge"]];
      If[! SubsetQ[stripCensus["RootIndices"],
          gaugeCensus["RootIndices"]],
        fail["GaugeIntroducedInactiveRoot", <|"LowerSector" -> j,
          "StripRootIndices" -> stripCensus["RootIndices"],
          "GaugeRootIndices" -> gaugeCensus["RootIndices"]|>]];
      exportAtomic[<|
        "Status" -> "CF303Sector20MinimalChartDLogSolutionV1",
        "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> j,
        "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
        "SolutionChecks" -> solutionChecks,
        "GaugeRootCensus" -> gaugeCensus,
        "Solution" -> solution|>, solutionFile];
      solverSummary = <|"LowerSector" -> j,
        "Status" -> "CertifiedDLogStrip",
        "Method" -> solution["Method"], "SelectedRoute" -> chartName,
        "RootIndices" -> stripCensus["RootIndices"],
        "GaugeRootIndices" -> gaugeCensus["RootIndices"],
        "SolveSeconds" -> solveSeconds,
        "GaugeDimensions" -> Dimensions[solution["Gauge"]],
        "GaugeLeafCount" -> LeafCount[solution["Gauge"]],
        "GaugeFingerprint" -> expressionHash[solution["Gauge"]],
        "PriorCumulativeGaugeFingerprint" -> expressionHash[solvedSource],
        "ActiveIntermediateSectors" -> activeIntermediateSectors,
        "AlphabetLength" -> Length[Lookup[solution, "Alphabet", {}]],
        "ExactDLog" -> True, "SolutionChecks" -> solutionChecks,
        "RegulatorFactorizationPending" -> True,
        "StripFile" -> stripFile, "StripSHA256" -> hashHex[stripFile],
        "SolutionFile" -> solutionFile,
        "SolutionSHA256" -> hashHex[solutionFile]|>;
      putAtomic[solverSummary, summaryFile];
      solvedSource[j] = Map[Together, solution["Gauge"], {2}];
      AppendTo[solverSummaries, solverSummary];
      writeCheckpoint[j, j - 1];
      If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
        fail["PackageChangedDuringCampaign", <|"LowerSector" -> j|>]];
      Print["CF303S20MINCHARTV1 block=", {20, j},
        " status=PASS seconds=", Round[solveSeconds, 0.1],
        " gaugeLeaves=", LeafCount[solution["Gauge"]]];
    ];

    nextLowerSector = 0;
    rowGauge = ConstantArray[0, {2, 34}];
    Do[rowGauge[[All, ranges[[j]]]] = solvedSource[j], {j, 1, 19}];
    nilpotent = ConstantArray[0, {45, 45}];
    nilpotent[[rowRange, 1 ;; 34]] = rowGauge;
    unipotent = IdentityMatrix[45] + nilpotent;
    inverse = IdentityMatrix[45] - nilpotent;
    finalChecks = <|
      "AllNineteenBlocksCertified" ->
        Sort[Keys[solvedSource]] === Range[1, 19],
      "AllStripChecksPassed" -> AllTrue[solverSummaries,
        TrueQ[Lookup[#, "ExactDLog", False]] &],
      "NilpotentSquareZero" -> zeroGaugeQ[nilpotent . nilpotent],
      "UnipotentTwoSidedInverse" ->
        zeroGaugeQ[inverse . unipotent - IdentityMatrix[45]] &&
        zeroGaugeQ[unipotent . inverse - IdentityMatrix[45]],
      "PriorRowDecouplingChecksPassed" ->
        And @@ Values[priorRowChecks]|>;
    If[! And @@ Values[finalChecks],
      fail["FinalRowChecksFailed", <|"Checks" -> finalChecks|>]];
    campaignSummary = <|
      "Status" -> "CF303Sector20MinimalChartRowSolvedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "CompletedLowerSectors" -> Reverse[Range[1, 19]],
      "SolvedGaugeSectors" -> Sort[Keys[solvedSource]],
      "NonzeroGaugeSectors" -> Select[Range[1, 19],
        ! zeroGaugeQ[solvedSource[#]] &],
      "SolverSummaries" -> solverSummaries,
      "FinalCheckpoint" -> checkpointFileFor[1],
      "FinalCheckpointSHA256" -> hashHex[checkpointFileFor[1]],
      "TotalSolveSeconds" -> Total[Lookup[solverSummaries,
        "SolveSeconds", {}]],
      "RowGaugeDimensions" -> Dimensions[rowGauge],
      "RowGaugeLeafCount" -> LeafCount[rowGauge],
      "RowGaugeFingerprint" -> expressionHash[rowGauge],
      "FinalChecks" -> finalChecks,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PriorRowChecks" -> priorRowChecks,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[! FileExistsQ[campaignSummaryFile],
      putAtomic[campaignSummary, campaignSummaryFile]];
    Print["CF303S20MINCHARTV1 status=PASS nonzeroGaugeSectors=",
      campaignSummary["NonzeroGaugeSectors"],
      " totalSolveSeconds=",
      Round[campaignSummary["TotalSolveSeconds"], 0.1]];
    0,
    tag];
  result
]
