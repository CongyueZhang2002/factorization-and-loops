#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{campaignDir, checkpointFile, campaignSummaryFile, rankAuditFile,
    outdir, certificateFile, summaryFile, expectedHashes, hashHex,
    expressionHash, putAtomic, exportAtomic, fail, tag, result, badHashes,
    checkpoint, campaignSummary, rankAudit, solvedGauges, solverSummaries,
    lowerSectors, artifactSectors, ranges, stripFiles = <||>,
    solutionFiles = <||>, checksBySector = <||>, blockDirectory,
    stripPayload, solutionPayload, solution, mappingStatistics, rowGauge,
    nilpotent, unipotent, inverse, globalChecks, certificate, summary,
    radicalPattern, zeroMatrixQ, zeroPairQ, j},
  campaignDir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_campaign_v1";
  checkpointFile = FileNameJoin[{campaignDir, "checkpoint_after_1.wxf"}];
  campaignSummaryFile = FileNameJoin[{campaignDir, "campaign_summary.wl"}];
  rankAuditFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_18_17_kallen23_rank_one_audit_v1/rank_one_strip.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector18_pair_chart_row_certificate_v1";
  certificateFile = FileNameJoin[{outdir, "certificate.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector18RowCertificateV1$"];
  expectedHashes = <|
    checkpointFile ->
      "d013fc5daab845b440bb3f0ac0bd21015c5c27c446479ea5fbd268466da3ca90",
    campaignSummaryFile ->
      "ef87ca9f8b6a4d40c5737967ab468b65b6dce0d821346e682ba3e867127ac5ad",
    rankAuditFile ->
      "d1e25d67f90bad8612c06b0388707d9518174988eec0bba3e9717baafce3bec1"|>;

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
    Print["CF303 SECTOR18 ROW CERTIFICATE FAILURE V1: " <> message,
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
    Print["CF303S18ROWCERTV1 stage=load"];
    checkpoint = Import[checkpointFile, "WXF"];
    campaignSummary = Get[campaignSummaryFile];
    rankAudit = Import[rankAuditFile, "WXF"];
    If[! And @@ (AssociationQ /@
        {checkpoint, campaignSummary, rankAudit}) ||
        Lookup[checkpoint, "Status", None] =!=
          "CF303Sector18PairChartRowSolvedV1" ||
        Lookup[campaignSummary, "Status", None] =!=
          "CF303Sector18PairChartRowSolvedV1" ||
        Lookup[rankAudit, "Status", None] =!=
          "CF3031817Kallen23RankOneAuditPassedV1",
      fail["invalid aggregate input ABI"]];
    solvedGauges = checkpoint["SolvedChartGauges"];
    solverSummaries = checkpoint["SolverSummaries"];
    lowerSectors = Range[1, 17];
    artifactSectors = Range[1, 16];
    ranges = AssociationThread[lowerSectors,
      {{1}, {2}, {3}, {4}, {5}, {6}, {7, 8}, {9}, {10}, {11}, {12},
       {13, 14, 15, 16}, {17, 18, 19, 20}, {21, 22}, {23, 24, 25},
       {26, 27}, {28}}];
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

    Print["CF303S18ROWCERTV1 stage=verify-artifacts"];
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
            "CF303Sector18PairChartRationalStripV1" ||
          Lookup[solutionPayload, "Status", None] =!=
            "CF303Sector18PairChartDLogSolutionV1",
        fail["invalid block artifact ABI", <|"LowerSector" -> j|>]];
      mappingStatistics = Lookup[stripPayload, "MappingStatistics", {}];
      checksBySector[j] = <|
        "GaugeSameQCheckpoint" ->
          TrueQ[solution["Gauge"] === solvedGauges[j]],
        "GaugeDimensions" ->
          Dimensions[solution["Gauge"]] === {2, Length[ranges[j]]},
        "GaugeExactlyZero" -> zeroMatrixQ[solution["Gauge"]],
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
        "ActiveIntermediateSetEmpty" ->
          Lookup[stripPayload, "ActiveIntermediateSectors", None] === {},
        "AllPriorSectorsSkippedAsZero" ->
          Lookup[stripPayload, "SkippedZeroIntermediateSectors", None] ===
            Range[j + 1, 17],
        "RationalStrip" -> FreeQ[stripPayload["Strip"], radicalPattern]|>;
      If[! And @@ Values[checksBySector[j]],
        fail["block verification failed", <|"LowerSector" -> j,
          "FailedChecks" ->
            Select[checksBySector[j], ! TrueQ[#] &]|>]],
      {j, artifactSectors}];

    checksBySector[17] = <|
      "EvidenceMode" -> "PinnedExact1817Audit",
      "GaugeDimensions" -> Dimensions[solvedGauges[17]] === {2, 1},
      "GaugeExactlyZero" -> zeroMatrixQ[solvedGauges[17]],
      "ForcingEvenExactlyZero" -> zeroPairQ[rankAudit["ForcingEven"]],
      "ForcingOddExactlyZero" -> zeroPairQ[rankAudit["ForcingOdd"]],
      "LeftDiagonalOddExactlyZero" ->
        zeroPairQ[rankAudit["LeftDiagonalOdd"]],
      "RightDiagonalOddExactlyZero" ->
        zeroPairQ[rankAudit["RightDiagonalOdd"]],
      "AuditRecompositionPassed" -> AllTrue[
        Lookup[rankAudit, "FactorAudit", {}],
        TrueQ[Lookup[#, "ResidualOddChannelZero", False]] &]|>;
    If[! And @@ Select[Values[checksBySector[17]], BooleanQ],
      fail["18-to-17 audit verification failed"]];

    Print["CF303S18ROWCERTV1 stage=global-row"];
    rowGauge = ConstantArray[0, {2, 28}];
    Do[rowGauge[[All, ranges[j]]] = solvedGauges[j], {j, lowerSectors}];
    nilpotent = ConstantArray[0, {30, 30}];
    nilpotent[[{29, 30}, 1 ;; 28]] = rowGauge;
    unipotent = IdentityMatrix[30] + nilpotent;
    inverse = IdentityMatrix[30] - nilpotent;
    globalChecks = <|
      "AllSeventeenBlocksCertified" -> AllTrue[Values[checksBySector],
        And @@ Select[Values[#], BooleanQ] &],
      "EntireRowGaugeExactlyZero" -> zeroMatrixQ[rowGauge],
      "NilpotentSquareZero" ->
        TrueQ[nilpotent . nilpotent === ConstantArray[0, {30, 30}]],
      "UnipotentIsIdentity" ->
        TrueQ[unipotent === IdentityMatrix[30]],
      "UnipotentTwoSidedInverse" -> TrueQ[
        unipotent . inverse === IdentityMatrix[30] &&
          inverse . unipotent === IdentityMatrix[30]],
      "RegulatorFactorizationPending" -> AnyTrue[
        Select[solverSummaries,
          MemberQ[{1, 11}, Lookup[#, "LowerSector", None]] &],
        ! TrueQ[Lookup[#, "ResiduesEpsFree", True]] &]|>;
    If[! And @@ Values[globalChecks],
      fail["global row check failed", <|
        "FailedChecks" -> Select[globalChecks, ! TrueQ[#] &]|>]];

    certificate = <|
      "Status" -> "CF303Sector18PairChartRowCertificatePassedV1",
      "Family" -> "CF303", "Sector" -> 18, "Chart" -> "Kallen23",
      "RowGauge" -> rowGauge, "SolvedChartGauges" -> solvedGauges,
      "BlockChecks" -> checksBySector, "GlobalChecks" -> globalChecks,
      "StripFiles" -> stripFiles, "SolutionFiles" -> solutionFiles,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[certificate, certificateFile];
    summary = <|
      "Status" -> "CF303Sector18PairChartRowCertificatePassedV1",
      "CertificateFile" -> certificateFile,
      "CertificateSHA256" -> hashHex[certificateFile],
      "CertificateBytes" -> FileByteCount[certificateFile],
      "RowGaugeDimensions" -> Dimensions[rowGauge],
      "RowGaugeLeafCount" -> LeafCount[rowGauge],
      "CertifiedLowerSectors" -> lowerSectors,
      "NonzeroForcingSectors" -> {1, 11},
      "NonzeroGaugeSectors" -> {}, "GlobalChecks" -> globalChecks,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303S18ROWCERTV1 status=PASS certificate=", certificateFile];
    0,
    tag];
  result
]
