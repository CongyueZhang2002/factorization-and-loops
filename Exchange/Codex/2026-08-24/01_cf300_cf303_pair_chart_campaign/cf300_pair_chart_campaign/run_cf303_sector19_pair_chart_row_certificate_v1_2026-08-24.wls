#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{campaignDir, checkpointFile, campaignSummaryFile, stateFile,
    rankAuditFile, row17CertificateFile, row18CertificateFile,
    outdir, certificateFile, summaryFile, expectedHashes, hashHex,
    expressionHash, putAtomic, exportAtomic, fail, tag, result, badHashes,
    checkpoint, campaignSummary, state, rankAudit, row17Certificate,
    row18Certificate, solvedGauges, solverSummaries, sourceRanges,
    lowerSectors, artifactSectors, ranges, stripFiles = <||>,
    solutionFiles = <||>, checksBySector = <||>, blockDirectory,
    stripPayload, solutionPayload, solution, mappingStatistics, rowGauge,
    nilpotent, unipotent, inverse, globalChecks, certificate, summary,
    radicalPattern, zeroMatrixQ, zeroPairQ, raw1817ZeroQ,
    raw1917ZeroQ, sector18RowGaugeZeroQ, pinned1817ForcingZeroQ, j},
  campaignDir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_campaign_v1";
  checkpointFile = FileNameJoin[{campaignDir, "checkpoint_after_1.wxf"}];
  campaignSummaryFile = FileNameJoin[{campaignDir, "campaign_summary.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  rankAuditFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_18_17_kallen23_rank_one_audit_v1/rank_one_strip.wxf";
  row17CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_certificate_v2/certificate.wxf";
  row18CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1";
  certificateFile = FileNameJoin[{outdir, "certificate.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector19RowCertificateV1$"];
  expectedHashes = <|
    checkpointFile ->
      "6288f28584eeb5bb2a775047f60b54fa577d9f10c94013e7271aac8412ebf72f",
    campaignSummaryFile ->
      "85ba45bd7b2f1820d842227302d015a0505eb2ddca2113b21f047eb7f629b652",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    rankAuditFile ->
      "d1e25d67f90bad8612c06b0388707d9518174988eec0bba3e9717baafce3bec1",
    row17CertificateFile ->
      "adf9f2103dbecf16bac89cbe5be81909dc4bdfa3e5a0ff4e26f9bbeaed572435",
    row18CertificateFile ->
      "977bcbb1bfb89c15e9f07357c88c5e91da2ccf9baa8250603c9effb672e9492c"|>;

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
  fail[message_String, data_: <||>] := (
    Print["CF303 SECTOR19 ROW CERTIFICATE FAILURE V1: " <> message,
      " data=", data];
    Throw[$Failed, tag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {}, fail["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      fail["single pool worker required"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["output already exists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["immutable input hash mismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    Print["CF303S19ROWCERTV1 stage=load"];
    checkpoint = Import[checkpointFile, "WXF"];
    campaignSummary = Get[campaignSummaryFile];
    state = Get[stateFile];
    rankAudit = Import[rankAuditFile, "WXF"];
    row17Certificate = Import[row17CertificateFile, "WXF"];
    row18Certificate = Import[row18CertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@
        {checkpoint, campaignSummary, state, rankAudit,
          row17Certificate, row18Certificate}) ||
        Lookup[checkpoint, "Status", None] =!=
          "CF303Sector19PairChartRowSolvedV1" ||
        Lookup[campaignSummary, "Status", None] =!=
          "CF303Sector19PairChartRowSolvedV1" ||
        Lookup[rankAudit, "Status", None] =!=
          "CF3031817Kallen23RankOneAuditPassedV1" ||
        Lookup[row17Certificate, "Status", None] =!=
          "CF303Sector17PairChartRowCertificatePassedV2" ||
        Lookup[row18Certificate, "Status", None] =!=
          "CF303Sector18PairChartRowCertificatePassedV1",
      fail["invalid aggregate input ABI"]];
    solvedGauges = checkpoint["SolvedChartGauges"];
    solverSummaries = checkpoint["SolverSummaries"];
    lowerSectors = Range[1, 18];
    artifactSectors = lowerSectors;
    ranges = AssociationThread[lowerSectors,
      {{1}, {2}, {3}, {4}, {5}, {6}, {7, 8}, {9}, {10}, {11}, {12},
       {13, 14, 15, 16}, {17, 18, 19, 20}, {21, 22}, {23, 24, 25},
       {26, 27}, {28}, {29, 30}}];
    If[Sort[Keys[solvedGauges]] =!= lowerSectors ||
        Sort[Lookup[solverSummaries, "LowerSector", {}]] =!= lowerSectors ||
        Lookup[checkpoint, "SolvedChartGaugeFingerprint", None] =!=
          expressionHash[solvedGauges],
      fail["row gauge, summary, or fingerprint chain is incomplete"]];
    radicalPattern = _Root | Power[_, exponent_Rational /;
      Denominator[exponent] > 1];
    zeroMatrixQ[matrix_List] :=
      AllTrue[Flatten[matrix], TrueQ[Together[#] === 0] &];
    zeroPairQ[pair_List] :=
      AllTrue[Flatten[pair], TrueQ[Together[#] === 0] &];
    sourceRanges = state["Ranges"];
    raw1817ZeroQ = AllTrue[Flatten[
      state["A"][[All, sourceRanges[[18]], sourceRanges[[17]]]]],
      TrueQ[# === 0] &];
    raw1917ZeroQ = AllTrue[Flatten[
      state["A"][[All, sourceRanges[[19]], sourceRanges[[17]]]]],
      TrueQ[# === 0] &];
    sector18RowGaugeZeroQ = zeroMatrixQ[row18Certificate["RowGauge"]];
    pinned1817ForcingZeroQ =
      zeroPairQ[rankAudit["ForcingEven"]] &&
        zeroPairQ[rankAudit["ForcingOdd"]];

    Print["CF303S19ROWCERTV1 stage=verify-artifacts"];
    Do[
      blockDirectory = FileNameJoin[{campaignDir,
        "block_" <> ToString[j] <> "_attempt_1"}];
      stripFiles[j] = FileNameJoin[{blockDirectory, "strip.wxf"}];
      solutionFiles[j] = FileNameJoin[{blockDirectory, "solution.wxf"}];
      If[! FileExistsQ[stripFiles[j]] || ! FileExistsQ[solutionFiles[j]],
        fail["missing block artifact", <|"LowerSector" -> j|>]];
      stripPayload = Import[stripFiles[j], "WXF"];
      solutionPayload = Import[solutionFiles[j], "WXF"];
      solution = Lookup[solutionPayload, "Solution", $Failed];
      If[! AssociationQ[stripPayload] || ! AssociationQ[solution] ||
          Lookup[stripPayload, "Status", None] =!=
            "CF303Sector19PairChartRationalStripV1" ||
          Lookup[solutionPayload, "Status", None] =!=
            "CF303Sector19PairChartDLogSolutionV1",
        fail["invalid block artifact ABI", <|"LowerSector" -> j|>]];
      mappingStatistics = Lookup[stripPayload, "MappingStatistics", {}];
      checksBySector[j] = <|
        "GaugeSameQCheckpoint" ->
          TrueQ[solution["Gauge"] === solvedGauges[j]],
        "GaugeDimensions" ->
          Dimensions[solution["Gauge"]] === {4, Length[ranges[j]]},
        "SolvedStatus" -> Lookup[solution, "Status", None] === "Solved",
        "ExactDLog" -> TrueQ[Lookup[solution, "ExactDLog", False]],
        "ExactPfaffianResidualsZero" -> TrueQ[Lookup[
          solution, "ExactPfaffianResidualsZero", False]],
        "LettersEpsFree" ->
          TrueQ[Lookup[solution, "LettersEpsFree", False]],
        "ResiduesKinematicsFree" -> TrueQ[Lookup[
          solution, "ResiduesKinematicsFree", False]],
        "DLogFormCertified" ->
          TrueQ[Lookup[solution, "DLogFormCertified", False]],
        "NoResidualThirdRootInMapping" -> AllTrue[mappingStatistics,
          TrueQ[Lookup[#, "ResidualOddChannelZero", False]] &&
            ! MemberQ[Lookup[#, "RootIndices", {}], 3] &],
        "ActiveIntermediateSetExact" ->
          Lookup[stripPayload, "ActiveIntermediateSectors", None] ===
            Select[Range[j + 1, 18],
              ! zeroMatrixQ[solvedGauges[#]] &],
        "SkippedIntermediateSetExact" ->
          Lookup[stripPayload, "SkippedZeroIntermediateSectors", None] ===
            Select[Range[j + 1, 18],
              zeroMatrixQ[solvedGauges[#]] &],
        "RationalStrip" -> FreeQ[stripPayload["Strip"], radicalPattern]|>;
      If[! And @@ Values[checksBySector[j]],
        fail["block verification failed", <|"LowerSector" -> j,
          "FailedChecks" ->
            Select[checksBySector[j], ! TrueQ[#] &]|>]],
      {j, artifactSectors}];

    Print["CF303S19ROWCERTV1 stage=global-row"];
    rowGauge = ConstantArray[0, {4, 30}];
    Do[rowGauge[[All, ranges[j]]] = solvedGauges[j], {j, lowerSectors}];
    nilpotent = ConstantArray[0, {34, 34}];
    nilpotent[[{31, 32, 33, 34}, 1 ;; 30]] = rowGauge;
    unipotent = IdentityMatrix[34] + nilpotent;
    inverse = IdentityMatrix[34] - nilpotent;
    globalChecks = <|
      "AllEighteenBlocksCertified" -> AllTrue[Values[checksBySector],
        And @@ Select[Values[#], BooleanQ] &],
      "NonzeroGaugeSectorsExact" ->
        Select[lowerSectors, ! zeroMatrixQ[solvedGauges[#]] &] ===
          {1, 6, 11, 12, 18},
      "NilpotentSquareZero" ->
        TrueQ[nilpotent . nilpotent === ConstantArray[0, {34, 34}]],
      "UnipotentIsNontrivial" ->
        TrueQ[unipotent =!= IdentityMatrix[34]],
      "UnipotentTwoSidedInverse" -> TrueQ[
        unipotent . inverse === IdentityMatrix[34] &&
          inverse . unipotent === IdentityMatrix[34]],
      "PriorRowDecouplingChecksPassed" ->
        And @@ Values[Lookup[campaignSummary, "PriorRowChecks", <||>]],
      "Raw1817BlockStructurallyZero" -> raw1817ZeroQ,
      "Raw1917BlockStructurallyZero" -> raw1917ZeroQ,
      "Pinned1817AuditForcingExactlyZero" -> pinned1817ForcingZeroQ,
      "Sector17CertificatePassed" ->
        And @@ Values[row17Certificate["GlobalChecks"]],
      "Sector18CertificatePassed" ->
        And @@ Values[row18Certificate["GlobalChecks"]],
      "Sector18RowGaugeExactlyZero" -> sector18RowGaugeZeroQ,
      "Indirect171819PathExactlyZero" -> TrueQ[
        raw1817ZeroQ && sector18RowGaugeZeroQ],
      "RegulatorFactorizationPending" -> AnyTrue[
        Select[solverSummaries, MemberQ[{1, 6, 11, 12, 18},
          Lookup[#, "LowerSector", None]] &],
        ! TrueQ[Lookup[#, "ResiduesEpsFree", True]] &]|>;
    If[! And @@ Values[globalChecks],
      fail["global row check failed", <|
        "FailedChecks" -> Select[globalChecks, ! TrueQ[#] &]|>]];

    certificate = <|
      "Status" -> "CF303Sector19PairChartRowCertificatePassedV1",
      "Family" -> "CF303", "Sector" -> 19, "Chart" -> "Kallen23",
      "RowGauge" -> rowGauge, "SolvedChartGauges" -> solvedGauges,
      "BlockChecks" -> checksBySector, "GlobalChecks" -> globalChecks,
      "StripFiles" -> stripFiles, "SolutionFiles" -> solutionFiles,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[certificate, certificateFile];
    summary = <|
      "Status" -> "CF303Sector19PairChartRowCertificatePassedV1",
      "CertificateFile" -> certificateFile,
      "CertificateSHA256" -> hashHex[certificateFile],
      "CertificateBytes" -> FileByteCount[certificateFile],
      "RowGaugeDimensions" -> Dimensions[rowGauge],
      "RowGaugeLeafCount" -> LeafCount[rowGauge],
      "CertifiedLowerSectors" -> lowerSectors,
      "NonzeroForcingSectors" -> {1, 6, 11, 12, 18},
      "NonzeroGaugeSectors" -> {1, 6, 11, 12, 18},
      "GlobalChecks" -> globalChecks,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303S19ROWCERTV1 status=PASS certificate=", certificateFile];
    0,
    tag];
  result
]
