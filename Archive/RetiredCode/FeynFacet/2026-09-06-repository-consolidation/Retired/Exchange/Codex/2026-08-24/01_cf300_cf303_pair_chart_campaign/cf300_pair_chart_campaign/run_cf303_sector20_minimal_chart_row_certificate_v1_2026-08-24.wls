#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, stateFile, seedSolutionFile,
    row17CertificateFile, row18CertificateFile, row19CertificateFile,
    checkpointFile, campaignSummaryFile, outdir, certificateFile,
    summaryFile, expectedHashes, dependencyFiles, dependencyHashes,
    hashHex, expressionHash, putAtomic, exportAtomic, fail, tag, result,
    badHashes, state, seedPayload, row17Certificate, row18Certificate,
    row19Certificate, checkpoint, campaignSummary, ranges, connection,
    variables, regulator, rowRange, range18, solvedSource,
    solverSummaries, summaryBySector, zeroNestedQ, zeroPairQ, zeroGaugeQ,
    upperDiagonal, priorRowChecks, recurrenceChecks, j, lowerRange,
    intermediateSectors, activeIntermediateSectors, directForcing,
    lowerConnections, forcing, expectedStrip, record, stripPayload,
    solutionPayload, solution, frameCertificate, seedStrip, rowGauge,
    nilpotent, unipotent, inverse, nonzeroGaugeSectors, zeroGaugeSectors,
    methods, globalChecks, certificate, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
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
  checkpointFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1/checkpoint_after_1.wxf";
  campaignSummaryFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_campaign_v1/campaign_summary.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1";
  certificateFile = FileNameJoin[{outdir, "certificate.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector20MinimalChartRowCertificateV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    seedSolutionFile ->
      "687cc3815fd18be7e3a5a9f4f9ad893e7062012366fdab66a33faea88681ef9f",
    row17CertificateFile ->
      "adf9f2103dbecf16bac89cbe5be81909dc4bdfa3e5a0ff4e26f9bbeaed572435",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    checkpointFile ->
      "0762debd67c6eea102302a8f2a599e123e81d5502b391b2a4a7ff45e5b7c0070",
    campaignSummaryFile ->
      "13e70c10dcb996f0d751286f93740f13365e6294908acfcf8b1776c26032fa0f"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile|>;

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
      "Sector" -> 20, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 SECTOR20 ROW CERTIFICATE FAILURE V1: ", status,
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
    seedPayload = Import[seedSolutionFile, "WXF"];
    row17Certificate = Import[row17CertificateFile, "WXF"];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    checkpoint = Import[checkpointFile, "WXF"];
    campaignSummary = Get[campaignSummaryFile];
    If[! And @@ (AssociationQ /@ {state, seedPayload,
          row17Certificate, row18Certificate, row19Certificate,
          checkpoint, campaignSummary}) ||
        Lookup[checkpoint, "Status", None] =!=
          "CF303Sector20MinimalChartRowSolvedV1" ||
        Lookup[campaignSummary, "Status", None] =!=
          "CF303Sector20MinimalChartRowSolvedV1" ||
        Lookup[checkpoint, "InputHashes", None] =!=
          Lookup[campaignSummary, "InputHashes", Missing["Mismatch"]] ||
        Lookup[checkpoint, "DependencyHashes", None] =!=
          Lookup[campaignSummary, "DependencyHashes", Missing["Mismatch"]],
      fail["InvalidCampaignABI"]];

    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[20]];
    range18 = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {35, 36} || range18 =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];
    solvedSource = checkpoint["SolvedSourceGauges"];
    solverSummaries = checkpoint["SolverSummaries"];
    If[! AssociationQ[solvedSource] ||
        Sort[Keys[solvedSource]] =!= Range[1, 19] ||
        Lookup[checkpoint, "SolvedSourceGaugeFingerprint", None] =!=
          expressionHash[solvedSource] || Length[solverSummaries] =!= 19,
      fail["InvalidSolvedGaugeChain"]];
    summaryBySector = Association[Map[
      Lookup[#, "LowerSector", Missing["LowerSector"]] -> # &,
      solverSummaries]];
    If[Sort[Keys[summaryBySector]] =!= Range[1, 19],
      fail["InvalidSolverSummaryIndex"]];

    zeroNestedQ[expression_] := AllTrue[Flatten[expression],
      TrueQ[Together[#] === 0] &];
    zeroPairQ[pair_] := AllTrue[Flatten[Map[Together, pair, {3}]],
      TrueQ[# === 0] &];
    zeroGaugeQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];
    upperDiagonal = connection[[All, rowRange, rowRange]]/regulator;
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

    seedStrip = Lookup[seedPayload, "SourceStrip", $Failed];
    recurrenceChecks = <||>;
    recurrenceChecks[19] = <|
      "GaugeExactlyZero" -> zeroGaugeQ[solvedSource[19]],
      "DirectForcingExactlyZero" ->
        zeroPairQ[connection[[All, rowRange, ranges[[19]]]]],
      "DimensionsExact" ->
        Dimensions[solvedSource[19]] === {2, Length[ranges[[19]]]}|>;
    recurrenceChecks[18] = <|
      "SeedStatusExact" -> Lookup[seedPayload, "Status", None] ===
        "CF303Sector2018Bilinear115SolvedV1",
      "SeedGaugeExact" -> zeroGaugeQ[
        solvedSource[18] - seedPayload["Solution"]["Gauge"]],
      "SeedStripExact" -> zeroNestedQ[seedStrip - {
        upperDiagonal,
        connection[[All, range18, range18]]/regulator,
        connection[[All, rowRange, range18]]}],
      "SeedFrameCertificateExact" -> TrueQ[Lookup[
        seedPayload["Solution"]["FrameCertificate"], "Exact", False]],
      "SeedExactDLog" ->
        TrueQ[seedPayload["Solution"]["ExactDLog"]]|>;

    For[j = 17, j >= 1, j--,
      lowerRange = ranges[[j]];
      intermediateSectors = Range[j + 1, 19];
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
      expectedStrip = {upperDiagonal,
        connection[[All, lowerRange, lowerRange]]/regulator, forcing};
      record = summaryBySector[j];
      If[! AssociationQ[record] ||
          hashHex[record["StripFile"]] =!= record["StripSHA256"] ||
          hashHex[record["SolutionFile"]] =!= record["SolutionSHA256"],
        fail["BlockArtifactHashMismatch", <|"LowerSector" -> j|>]];
      stripPayload = Import[record["StripFile"], "WXF"];
      solutionPayload = Import[record["SolutionFile"], "WXF"];
      If[! AssociationQ[stripPayload] || ! AssociationQ[solutionPayload],
        fail["InvalidBlockArtifactABI", <|"LowerSector" -> j|>]];
      solution = Lookup[solutionPayload, "Solution", $Failed];
      frameCertificate = If[AssociationQ[solution],
        Lookup[solution, "FrameCertificate", <||>], <||>];
      recurrenceChecks[j] = <|
        "StripStatusExact" -> Lookup[stripPayload, "Status", None] ===
          "CF303Sector20DependencyClosedSourceStripV1",
        "SolutionStatusExact" -> Lookup[solutionPayload, "Status", None] ===
          "CF303Sector20MinimalChartDLogSolutionV1",
        "ActiveIntermediateSectorsExact" ->
          Lookup[stripPayload, "ActiveIntermediateSectors", None] ===
            activeIntermediateSectors,
        "LowerConnectionsExact" -> zeroNestedQ[
          Values[Lookup[stripPayload, "LowerConnections", <||>]] -
            Values[lowerConnections]],
        "AssembledForcingExact" -> zeroNestedQ[
          Lookup[stripPayload, "AssembledForcing", $Failed] - forcing],
        "DependencyClosedStripExact" -> zeroNestedQ[
          Lookup[stripPayload, "Strip", $Failed] - expectedStrip],
        "InstalledGaugeExact" -> AssociationQ[solution] && zeroGaugeQ[
          solvedSource[j] - Lookup[solution, "Gauge", {}]],
        "GaugeDimensionsExact" -> Dimensions[solvedSource[j]] ===
          {2, Length[lowerRange]},
        "SolutionChecksPassed" -> And @@ Values[
          Lookup[solutionPayload, "SolutionChecks", <||>]],
        "ExactDLog" -> AssociationQ[solution] &&
          TrueQ[Lookup[solution, "ExactDLog", False]],
        "GaugeRoundTrip" -> TrueQ[Lookup[
          frameCertificate, "GaugeRoundTrip", False]],
        "TransformedOneFormPullBack" -> TrueQ[Lookup[
          frameCertificate, "TransformedOneFormPullBack", False]],
        "SourceDLog" -> TrueQ[Lookup[
          frameCertificate, "SourceDLog", False]],
        "FrameCertificateExact" -> TrueQ[Lookup[
          frameCertificate, "Exact", False]],
        "AlphabetEpsilonFree" -> AssociationQ[solution] &&
          FreeQ[Lookup[solution, "Alphabet", {}], regulator],
        "CampaignSummaryAgrees" ->
          Lookup[record, "GaugeFingerprint", None] ===
            expressionHash[solvedSource[j]]|>;
    ];
    If[! AllTrue[Values[recurrenceChecks],
        And @@ Values[#] &],
      fail["AggregateRecurrenceCheckFailed", <|
        "FailedSectors" -> Keys@Select[recurrenceChecks,
          ! And @@ Values[#] &], "Checks" -> recurrenceChecks|>]];

    rowGauge = ConstantArray[0, {2, 34}];
    Do[rowGauge[[All, ranges[[j]]]] = solvedSource[j], {j, 1, 19}];
    nilpotent = ConstantArray[0, {45, 45}];
    nilpotent[[rowRange, 1 ;; 34]] = rowGauge;
    unipotent = IdentityMatrix[45] + nilpotent;
    inverse = IdentityMatrix[45] - nilpotent;
    nonzeroGaugeSectors = Select[Range[1, 19],
      ! zeroGaugeQ[solvedSource[#]] &];
    zeroGaugeSectors = Complement[Range[1, 19], nonzeroGaugeSectors];
    methods = Association@Table[j -> summaryBySector[j]["Method"],
      {j, 1, 19}];
    globalChecks = <|
      "AllNineteenBlocksCertified" ->
        Sort[Keys[recurrenceChecks]] === Range[1, 19],
      "AllRecurrenceIdentitiesExact" -> AllTrue[
        Values[recurrenceChecks], And @@ Values[#] &],
      "NonzeroGaugeSectorsExact" ->
        nonzeroGaugeSectors === {1, 2, 11, 14, 18},
      "EveryNonzeroGaugeUsesBilinear115" -> AllTrue[
        nonzeroGaugeSectors,
        StringContainsQ[ToString[summaryBySector[#]["Method"]],
          "Bilinear115"] &],
      "EveryNonzeroGaugeUsesOnlyThirdRoot" -> AllTrue[
        nonzeroGaugeSectors,
        Lookup[summaryBySector[#], "RootIndices", None] === {3} &],
      "NilpotentSquareZero" -> zeroGaugeQ[nilpotent . nilpotent],
      "UnipotentTwoSidedInverse" ->
        zeroGaugeQ[inverse . unipotent - IdentityMatrix[45]] &&
        zeroGaugeQ[unipotent . inverse - IdentityMatrix[45]],
      "CampaignFinalChecksPassed" ->
        And @@ Values[campaignSummary["FinalChecks"]],
      "PriorRowDecouplingChecksPassed" ->
        And @@ Values[priorRowChecks]|>;
    If[! And @@ Values[globalChecks],
      fail["GlobalCertificateCheckFailed", <|
        "Checks" -> globalChecks|>]];
    certificate = <|
      "Status" -> "CF303Sector20MinimalChartRowCertificatePassedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "Variables" -> variables, "Regulator" -> regulator,
      "RowGauge" -> rowGauge, "SolvedSourceGauges" -> solvedSource,
      "NonzeroGaugeSectors" -> nonzeroGaugeSectors,
      "ZeroGaugeSectors" -> zeroGaugeSectors,
      "Methods" -> methods,
      "RecurrenceChecks" -> recurrenceChecks,
      "GlobalChecks" -> globalChecks,
      "PriorRowChecks" -> priorRowChecks,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[certificate, certificateFile];
    summary = <|
      "Status" -> "CF303Sector20MinimalChartRowCertificatePassedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "CertificateFile" -> certificateFile,
      "CertificateSHA256" -> hashHex[certificateFile],
      "CertificateBytes" -> FileByteCount[certificateFile],
      "RowGaugeDimensions" -> Dimensions[rowGauge],
      "RowGaugeLeafCount" -> LeafCount[rowGauge],
      "RowGaugeFingerprint" -> expressionHash[rowGauge],
      "CertifiedLowerSectors" -> Range[1, 19],
      "NonzeroGaugeSectors" -> nonzeroGaugeSectors,
      "ZeroGaugeSectors" -> zeroGaugeSectors,
      "GlobalChecks" -> globalChecks,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringCertificate"]];
    Print["CF303S20ROWCERTV1 status=PASS nonzeroGaugeSectors=",
      nonzeroGaugeSectors, " rowGaugeLeaves=", LeafCount[rowGauge],
      " certificate=", certificateFile];
    0,
    tag];
  result
]
