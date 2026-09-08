#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{campaignDir, checkpointFile, checkpointHash, sourceCheckpointFile,
    sourceCheckpointHash, strip12File,
    solution12File, factorAuditSummaryFile, transportCertificateFile,
    outdir, certificateFile, summaryFile, expectedHashes, hashHex,
    badHashes, checkpoint, sourceCheckpoint, factorAuditSummary,
    transportCertificate, solvedGauges, solverSummaries, sourceSolvers,
    sourceSolvedForms, sourceSolverBySector, sourceSolver,
    frameCertificate, lowerSectors, newLowerSectors,
    inheritedLowerSectors, ranges, stripFiles,
    solutionFiles, strips, solutions, blockDirectory, stripPayload,
    solutionPayload, solution, mappingStatistics, checksBySector,
    rowGauge, nilpotent, unipotent, inverse, globalChecks, certificate,
    summary, putAtomic, exportAtomic, fail, tag, result, j},
  campaignDir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_campaign_v1";
  checkpointFile = FileNameJoin[{campaignDir, "checkpoint_after_1.wxf"}];
  checkpointHash =
    "401048f3002e90a7027214edbd96006ca899616981e040e3bd6cfb31c1f37894";
  sourceCheckpointFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_CF303_identity_capture_xh_v4/CF303_17_strip_state.wl";
  sourceCheckpointHash =
    "87528ab68d77c4e6e1492dec7f58d59dfc8cb0d29b4e2791ee0bfe6f620f999a";
  strip12File = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_strip_v1/CF303_17_12_pair_chart_strip_v1.wxf";
  solution12File = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_solve_v1/solution.wxf";
  factorAuditSummaryFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/summary.wl";
  transportCertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_certificate_v2/certificate.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector17_pair_chart_row_certificate_v2";
  certificateFile = FileNameJoin[{outdir, "certificate.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector17RowCertificateV2$"];
  expectedHashes = <|
    checkpointFile -> checkpointHash,
    sourceCheckpointFile -> sourceCheckpointHash,
    strip12File ->
      "246b89517021211fd41470a4ff7ec6591c674b9f694481c820a8b9b8bf3779d4",
    solution12File ->
      "20ed234d0bb41933aa120f329193779c005be920fabbdc84d493f5c55985a3e9",
    factorAuditSummaryFile ->
      "f307c447c29ec800c8ee2ff75bab8f58bbdfb23a69886972a4a4da9e52308427",
    transportCertificateFile ->
      "6427e714963c48a59d53e2acc8858663f147ad00d327b08f5bae04a274ca6958"|>;

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
    Print["CF303 SECTOR17 ROW CERTIFICATE FAILURE V2: " <> message];
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
      fail["immutable input hash mismatch: " <>
        ToString[badHashes, InputForm]]];
    CreateDirectory[outdir];
    Print["CF303ROWCERTV2 stage=load"];
    checkpoint = Import[checkpointFile, "WXF"];
    sourceCheckpoint = Get[sourceCheckpointFile];
    factorAuditSummary = Get[factorAuditSummaryFile];
    transportCertificate = Import[transportCertificateFile, "WXF"];
    If[! And @@ (AssociationQ /@
        {checkpoint, sourceCheckpoint, factorAuditSummary,
          transportCertificate}) ||
        Lookup[checkpoint, "Status", None] =!=
          "CF303Sector17PairChartRowSolvedV1" ||
        Lookup[sourceCheckpoint, "Sector", None] =!= 17 ||
        Lookup[sourceCheckpoint, "SubSize", None] =!= 1 ||
        Lookup[factorAuditSummary, "Status", None] =!=
          "CF303PairFactorAuditPassedV3" ||
        Lookup[transportCertificate, "Status", None] =!=
          "CF303PairChartDLogStripCertificatePassedV2",
      fail["invalid aggregate input ABI"]];
    solvedGauges = checkpoint["SolvedChartGauges"];
    solverSummaries = checkpoint["SolverSummaries"];
    sourceSolvers = Lookup[sourceCheckpoint, "StripSolvers", $Failed];
    sourceSolvedForms = Lookup[sourceCheckpoint, "SolvedForms", $Failed];
    lowerSectors = Range[1, 16];
    newLowerSectors = Range[1, 12];
    inheritedLowerSectors = Range[13, 16];
    ranges = AssociationThread[lowerSectors,
      {{1}, {2}, {3}, {4}, {5}, {6}, {7, 8}, {9}, {10}, {11}, {12},
       {13, 14, 15, 16}, {17, 18, 19, 20}, {21, 22}, {23, 24, 25},
       {26, 27}}];
    If[! ListQ[sourceSolvers] || ! AssociationQ[sourceSolvedForms],
      fail["invalid inherited source evidence ABI"]];
    sourceSolverBySector = AssociationThread[
      Lookup[sourceSolvers, "LowerSector", {}], sourceSolvers];
    If[Sort[Keys[solvedGauges]] =!= lowerSectors ||
        Sort[Lookup[solverSummaries, "LowerSector", {}]] =!=
          newLowerSectors ||
        ! ContainsAll[Keys[sourceSolverBySector], inheritedLowerSectors] ||
        ! ContainsAll[Keys[sourceSolvedForms], inheritedLowerSectors],
      fail["row gauge or summary chain is incomplete"]];

    stripFiles = <||>;
    solutionFiles = <||>;
    strips = <||>;
    solutions = <||>;
    checksBySector = <||>;
    Print["CF303ROWCERTV2 stage=verify-new-blocks"];
    Do[
      If[j === 12,
        stripFiles[j] = strip12File;
        solutionFiles[j] = solution12File,
        blockDirectory = FileNameJoin[{campaignDir,
          "block_" <> ToString[j] <> "_attempt_1"}];
        stripFiles[j] = FileNameJoin[{blockDirectory, "strip.wxf"}];
        solutionFiles[j] = FileNameJoin[{blockDirectory, "solution.wxf"}]];
      If[! FileExistsQ[stripFiles[j]] || ! FileExistsQ[solutionFiles[j]],
        fail["missing block artifact at lower sector " <> ToString[j]]];
      stripPayload = Import[stripFiles[j], "WXF"];
      solutionPayload = Import[solutionFiles[j], "WXF"];
      solution = Lookup[solutionPayload, "Solution", $Failed];
      If[! AssociationQ[stripPayload] || ! AssociationQ[solution],
        fail["invalid block artifact at lower sector " <> ToString[j]]];
      mappingStatistics = Lookup[stripPayload, "MappingStatistics", {}];
      strips[j] = stripPayload["Strip"];
      solutions[j] = solution;
      checksBySector[j] = <|
        "GaugeSameQCheckpoint" ->
          TrueQ[solution["Gauge"] === solvedGauges[j]],
        "GaugeDimensions" ->
          Dimensions[solution["Gauge"]] === {1, Length[ranges[j]]},
        "SolvedStatus" -> Lookup[solution, "Status", None] === "Solved",
        "ExactDLog" -> TrueQ[Lookup[solution, "ExactDLog", False]],
        "ExactPfaffianResidualsZero" ->
          TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]],
        "LettersEpsFree" ->
          TrueQ[Lookup[solution, "LettersEpsFree", False]],
        "ResiduesKinematicsFree" ->
          TrueQ[Lookup[solution, "ResiduesKinematicsFree", False]],
        "DLogFormCertified" ->
          TrueQ[Lookup[solution, "DLogFormCertified", False]],
        "NoResidualThirdRootInMapping" -> If[j === 12,
          Lookup[factorAuditSummary,
            "ResidualOddChannelNonzeroCount", -1] === 0,
          AllTrue[mappingStatistics,
            TrueQ[Lookup[#, "ResidualOddChannelZero", False]] &&
              ! MemberQ[Lookup[#, "RootIndices", {}], 3] &]],
        "RationalStrip" -> FreeQ[strips[j],
          _Root | Power[_, exponent_Rational /;
            Denominator[exponent] > 1]]|>;
      If[! And @@ Values[checksBySector[j]],
        fail["block verification failed at lower sector " <> ToString[j] <>
          ": " <> ToString[Select[checksBySector[j], ! TrueQ[#] &],
            InputForm]]],
      {j, newLowerSectors}];

    Print["CF303ROWCERTV2 stage=verify-inherited-blocks"];
    Do[
      sourceSolver = sourceSolverBySector[j];
      frameCertificate = Lookup[sourceSolver, "FrameCertificate", <||>];
      checksBySector[j] = <|
        "EvidenceMode" -> "PinnedInheritedExactFrameCertificate",
        "GaugeDimensions" ->
          Dimensions[solvedGauges[j]] === {1, Length[ranges[j]]},
        "GaugeMappedExactlyIntoKallen23" -> AllTrue[
          Select[Lookup[factorAuditSummary, "FactorAudit", {}],
            StringStartsQ[Lookup[#, "Label", ""],
              "D/" <> ToString[j] <> "/"] &],
          TrueQ[Lookup[#, "ResidualOddChannelZero", False]] &],
        "GaugeFactorAuditPresent" -> Length[Select[
          Lookup[factorAuditSummary, "FactorAudit", {}],
          StringStartsQ[Lookup[#, "Label", ""],
            "D/" <> ToString[j] <> "/"] &]] > 0,
        "SolvedFormPresent" -> KeyExistsQ[sourceSolvedForms, j],
        "SourceSolverSectorIdentity" ->
          Lookup[sourceSolver, "Sector", None] === 17 &&
            Lookup[sourceSolver, "LowerSector", None] === j,
        "SourceFrameExact" ->
          TrueQ[Lookup[frameCertificate, "Exact", False]],
        "SourceGaugeRoundTrip" ->
          TrueQ[Lookup[frameCertificate, "GaugeRoundTrip", False]],
        "SourceTransformedOneFormPullBack" -> TrueQ[Lookup[
          frameCertificate, "TransformedOneFormPullBack", False]],
        "SourceDLogCertified" -> If[j === 16,
          MatchQ[Lookup[sourceSolver, "ExactDLog", None],
            _Missing] &&
            Lookup[sourceSolver, "Method", ""] ===
              "RationalFrame/SimultaneousFiniteFieldAffinePDE",
          TrueQ[Lookup[frameCertificate, "SourceDLog", False]]],
        "NoThirdRootInSourceSolver" ->
          ! MemberQ[Lookup[sourceSolver, "RootIndices", {}], 3]|>;
      If[! And @@ Select[Values[checksBySector[j]], BooleanQ],
        fail["inherited block verification failed at lower sector " <>
          ToString[j] <> ": " <>
          ToString[Select[checksBySector[j],
            BooleanQ[#] && ! TrueQ[#] &], InputForm]]],
      {j, inheritedLowerSectors}];

    Print["CF303ROWCERTV2 stage=unipotent-row"];
    rowGauge = ConstantArray[0, {1, 27}];
    Do[rowGauge[[All, ranges[j]]] = solvedGauges[j], {j, lowerSectors}];
    nilpotent = ConstantArray[0, {28, 28}];
    nilpotent[[{28}, 1 ;; 27]] = rowGauge;
    unipotent = IdentityMatrix[28] + nilpotent;
    inverse = IdentityMatrix[28] - nilpotent;
    globalChecks = <|
      "AllSixteenBlocksCertified" ->
        AllTrue[Values[checksBySector],
          And @@ Select[Values[#], BooleanQ] &],
      "NilpotentSquareZero" ->
        TrueQ[nilpotent . nilpotent === ConstantArray[0, {28, 28}]],
      "UnipotentTwoSidedInverse" -> TrueQ[
        unipotent . inverse === IdentityMatrix[28] &&
          inverse . unipotent === IdentityMatrix[28]],
      "TransportCertificatePassed" ->
        And @@ Values[transportCertificate["Checks"]],
      "RegulatorFactorizationPending" ->
        AnyTrue[Values[KeyTake[solutions, newLowerSectors]],
          ! TrueQ[Lookup[#, "ResiduesEpsFree", True]] &]|>;
    If[! And @@ Values[globalChecks],
      fail["global row check failed: " <>
        ToString[Select[globalChecks, ! TrueQ[#] &], InputForm]]];

    certificate = <|
      "Status" -> "CF303Sector17PairChartRowCertificatePassedV2",
      "Family" -> "CF303", "Sector" -> 17,
      "Chart" -> "Kallen23", "RowGauge" -> rowGauge,
      "SolvedChartGauges" -> solvedGauges,
      "BlockChecks" -> checksBySector,
      "NewlySolvedLowerSectors" -> newLowerSectors,
      "InheritedLowerSectors" -> inheritedLowerSectors,
      "InheritedSourceSolvers" -> KeyTake[sourceSolverBySector,
        inheritedLowerSectors],
      "GlobalChecks" -> globalChecks,
      "StripFiles" -> stripFiles, "SolutionFiles" -> solutionFiles,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[certificate, certificateFile];
    summary = <|
      "Status" -> "CF303Sector17PairChartRowCertificatePassedV2",
      "CertificateFile" -> certificateFile,
      "CertificateSHA256" -> hashHex[certificateFile],
      "CertificateBytes" -> FileByteCount[certificateFile],
      "RowGaugeDimensions" -> Dimensions[rowGauge],
      "RowGaugeLeafCount" -> LeafCount[rowGauge],
      "CertifiedLowerSectors" -> lowerSectors,
      "NewlySolvedLowerSectors" -> newLowerSectors,
      "InheritedLowerSectors" -> inheritedLowerSectors,
      "ZeroForcingSectors" -> Select[newLowerSectors,
        Lookup[solutions[#], "Method", None] === "ZeroForcing" &],
      "GlobalChecks" -> globalChecks,
      "InputHashes" -> expectedHashes,
      "RegulatorFactorizationPending" -> True,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303ROWCERTV2 status=PASS rowGaugeLeaves=",
      LeafCount[rowGauge], " certificate=", certificateFile];
    0,
    tag];
  result
]
