#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, finiteFieldFile,
    stateFile, bundleFile, row19CertificateFile, row20CertificateFile,
    solution2120File, outdir, artifactDirectory, resultFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, state, bundle,
    row19Certificate, row20Certificate, solution2120Payload,
    solution2120, ranges, connection, sourceVariables, chartVariables,
    regulator, rowRange, lowerRange, range20, sourceRoots, usedRoots,
    rootSquares, frameVariables, frame, allRoots, strip, classification,
    gauge2019, currentA2019, base2119, forcing, recurrenceChecks,
    chart, rekeyed, data, chartCertificate, chartBranchRoots, rootImages,
    chartStrip, mapSeconds, inner, solveSeconds, coordinateMap,
    identityData, nestedRadicand, nestedRootImage, canonicalize, chartGauge,
    rawSourceGauge, sourceGauge, sourceAlphabet, signChoices, acceptedSigns,
    branchImages, branchedGauge, zeroMatrixQ, sourceTransformed,
    chartTransformed, pulledTransformed, pullPair, sourceCensus,
    unclassifiedRadicals, constantField, checks, sourceSolution,
    singleRootResult, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  bundleFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  row19CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector19_pair_chart_row_certificate_v1/certificate.wxf";
  row20CertificateFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_minimal_chart_row_certificate_v1/certificate.wxf";
  solution2120File =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_20_bilinear115_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_19_kallen23_source_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  resultFile = FileNameJoin[{outdir, "solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032119Kallen23SourceSolveV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    bundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec",
    row19CertificateFile ->
      "50a98ef694adbffa290a1b75b3e33780e4e7e01c5afa483935831897a787a619",
    row20CertificateFile ->
      "8d5f6048000d5256b28c98b8ee6e870732d1f0b6c76fcecd213edfdd54183140",
    solution2120File ->
      "77de52807fe1b737ae8001e8d32708253112d2e6c69c4cd06c4cedda6b9266a5"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile,
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
      "Sector" -> 21, "LowerSector" -> 19,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->19 KALLEN23 SOURCE SOLVE FAILURE V1: ", status,
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
        KernelPoolMission`$TaskBrokerMaxHelpers === 4),
      fail["HelperCeilingMustBeFour"]];
    If[(DirectoryQ[outdir] &&
          (FileExistsQ[resultFile] || FileExistsQ[summaryFile])) ||
        (FileExistsQ[outdir] && ! DirectoryQ[outdir]),
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    If[! DirectoryQ[outdir], CreateDirectory[outdir]];
    If[! DirectoryQ[artifactDirectory], CreateDirectory[artifactDirectory]];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];

    state = Get[stateFile];
    bundle = Get[bundleFile];
    row19Certificate = Import[row19CertificateFile, "WXF"];
    row20Certificate = Import[row20CertificateFile, "WXF"];
    solution2120Payload = Import[solution2120File, "WXF"];
    If[! And @@ (AssociationQ /@ {state, bundle, row19Certificate,
          row20Certificate, solution2120Payload}) ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3" ||
        Lookup[row19Certificate, "Status", None] =!=
          "CF303Sector19PairChartRowCertificatePassedV1" ||
        Lookup[row20Certificate, "Status", None] =!=
          "CF303Sector20MinimalChartRowCertificatePassedV1" ||
        Lookup[solution2120Payload, "Status", None] =!=
          "CF303Sector2120Bilinear115SolvedV1",
      fail["InvalidInputABI"]];
    solution2120 = solution2120Payload["Solution"];
    If[! AssociationQ[solution2120] ||
        ! TrueQ[solution2120["ExactDLog"]] ||
        ! TrueQ[solution2120["FrameCertificate"]["Exact"]],
      fail["Pinned2120SolutionNotExact"]];
    ranges = state["Ranges"];
    connection = state["A"];
    sourceVariables = bundle["SourceVariables"];
    chartVariables = bundle["ChartVariables"];
    regulator = bundle["Regulator"];
    rowRange = ranges[[21]];
    lowerRange = ranges[[19]];
    range20 = ranges[[20]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38} || lowerRange =!= {31, 32, 33, 34} ||
        range20 =!= {35, 36},
      fail["UnexpectedPinnedStateShape"]];

    gauge2019 = row20Certificate["SolvedSourceGauges"][19];
    currentA2019 = Table[Map[Together,
      connection[[mu, range20, lowerRange]] +
        regulator ((connection[[mu, range20, range20]]/regulator) .
          gauge2019 - gauge2019 .
          (connection[[mu, lowerRange, lowerRange]]/regulator)) -
        D[gauge2019, sourceVariables[[mu]]], {2}], {mu, 2}];
    base2119 = Table[Map[Together,
      connection[[mu, rowRange, lowerRange]] +
        connection[[mu, rowRange, range20]] . gauge2019, {2}], {mu, 2}];
    forcing = Table[Map[Together,
      base2119[[mu]] - solution2120["Gauge"] . currentA2019[[mu]], {2}],
      {mu, 2}];
    zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
      TrueQ[# === 0] &];
    recurrenceChecks = <|
      "Gauge2019ExactlyZero" -> zeroMatrixQ[gauge2019],
      "RawA2019ExactlyZero" -> AllTrue[currentA2019, zeroMatrixQ],
      "CurrentA2019ExactlyZero" -> AllTrue[currentA2019, zeroMatrixQ],
      "Base2119EqualsRaw" -> AllTrue[Table[
        base2119[[mu]] - connection[[mu, rowRange, lowerRange]],
        {mu, 2}], zeroMatrixQ],
      "Forcing2119EqualsRaw" -> AllTrue[Table[
        forcing[[mu]] - connection[[mu, rowRange, lowerRange]],
        {mu, 2}], zeroMatrixQ]|>;
    If[! And @@ Values[recurrenceChecks],
      fail["CurrentFrameRecurrenceFailed", <|
        "Checks" -> recurrenceChecks|>]];

    sourceRoots = bundle["SourceRoots"];
    usedRoots = sourceRoots[[{1, 2}]];
    rootSquares = Lookup[usedRoots, "RootSquare", {}];
    frameVariables = {Symbol["CF303Sector21Frame`p"],
      Symbol["CF303Sector21Frame`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      Lookup[sourceRoots, "RootSquare", {}], sourceVariables,
      frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, sourceVariables];
    strip = {
      connection[[All, rowRange, rowRange]]/regulator,
      connection[[All, lowerRange, lowerRange]]/regulator,
      forcing};
    classification = FeynFacet`Private`transportChartRootIndices[
      strip, allRoots];
    If[Lookup[classification, "RootIndices", None] =!= {1} ||
        Lookup[classification, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["UnexpectedActiveRootSet", <|
        "Classification" -> classification|>]];

    Print["CF3032119MINV1 stage=single-root-solve"];
    solveSeconds = First@AbsoluteTiming[
      singleRootResult = FeynFacet`SolveEpsFormStripInFrame[
        strip, sourceVariables, regulator, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldFallback" -> True,
        "MultiquadraticDispatch" -> False,
        "CANONICAKernels" -> 5,
        "ScratchDirectory" -> outdir,
        "Tag" -> "CF303_21_19_single_root_source_v1",
        "FiniteFieldOptions" -> {
          "KernelCount" -> 5,
          "ArtifactDirectory" -> artifactDirectory,
          "ArtifactPrefix" -> "CF303_21_19_single_root_source_v1",
          "Backend" -> Automatic, "BackendThreads" -> 1,
          "PlanDiscoveryBackend" -> "FLINTAffineRREF",
          "SupportStrategy" -> "SimplexFirst",
          "SupportLearning" -> True,
          "RegulatorSampling" -> "HeldOut",
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "Verbose" -> True]];
    checks = <|
      "RecurrenceChecksPassed" -> And @@ Values[recurrenceChecks],
      "SolvedStatus" -> AssociationQ[singleRootResult] &&
        Lookup[singleRootResult, "Status", None] === "Solved",
      "OnlyFirstRootUsed" ->
        Lookup[singleRootResult, "RootIndices", None] === {1},
      "ExactDLog" ->
        TrueQ[Lookup[singleRootResult, "ExactDLog", False]],
      "GaugeDimensionsExact" -> Dimensions[
        Lookup[singleRootResult, "Gauge", {}]] === {2, 4},
      "GaugeRoundTrip" -> TrueQ[Lookup[
        Lookup[singleRootResult, "FrameCertificate", <||>],
        "GaugeRoundTrip", False]],
      "TransformedOneFormPullBack" -> TrueQ[Lookup[
        Lookup[singleRootResult, "FrameCertificate", <||>],
        "TransformedOneFormPullBack", False]],
      "SourceDLog" -> TrueQ[Lookup[
        Lookup[singleRootResult, "FrameCertificate", <||>],
        "SourceDLog", False]],
      "FrameCertificateExact" -> TrueQ[Lookup[
        Lookup[singleRootResult, "FrameCertificate", <||>],
        "Exact", False]]|>;
    If[! And @@ Values[checks],
      fail["SingleRootSourceSolveFailed", <|
        "Checks" -> checks,
        "Result" -> If[AssociationQ[singleRootResult],
          KeyDrop[singleRootResult, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], singleRootResult]|>]];
    sourceSolution = singleRootResult;
    exportAtomic[<|
      "Status" -> "CF303Sector2119MinimalChartSourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 19,
      "SourceStrip" -> strip, "RecurrenceChecks" -> recurrenceChecks,
      "SourceSolution" -> sourceSolution, "Checks" -> checks,
      "MapSeconds" -> 0., "SolveSeconds" -> solveSeconds,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector2119MinimalChartSourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 19,
      "Method" -> sourceSolution["Method"],
      "RootIndices" -> sourceSolution["RootIndices"],
      "GaugeDimensions" -> Dimensions[sourceSolution["Gauge"]],
      "GaugeLeafCount" -> LeafCount[sourceSolution["Gauge"]],
      "AlphabetLength" -> Length[Lookup[sourceSolution, "Alphabet", {}]],
      "SolveSeconds" -> solveSeconds, "Checks" -> checks,
      "ResultFile" -> resultFile, "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032119MINV1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " method=", sourceSolution["Method"]];
    Throw[0, tag];

    chart = FeynFacet`TransportRootSetChart[rootSquares, sourceVariables];
    If[! AssociationQ[chart] || Lookup[chart, "Name", None] =!= "Kallen23",
      fail["Kallen23ChartNotSelected"]];
    rekeyed = FeynFacet`Private`transportChartRekey[
      chart, sourceVariables, chartVariables];
    data = FeynFacet`Private`masterTransportChartData[
      rekeyed, sourceVariables];
    chartCertificate = FeynFacet`TransportChartVerify[rekeyed];
    If[Lookup[data, "Status", None] =!= "OK" ||
        ! TrueQ[Lookup[chartCertificate, "OK", False]],
      fail["Kallen23ChartVerificationFailed"]];
    Print["CF3032119K23V1 stage=map-source stripLeaves=", LeafCount[strip]];
    mapSeconds = First@AbsoluteTiming[
      chartStrip = FeynFacet`Private`transportChartPullBackStrip[strip, data];
      chartBranchRoots = Map[
        <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
        usedRoots];
      rootImages = Lookup[bundle["RootImages"][[{1, 2}]], "Root", {}];
      chartStrip = Map[Together,
        FeynFacet`Private`transportChartApplyRootBranches[
          chartStrip, chartBranchRoots, rootImages], {4}]];
    If[! FreeQ[chartStrip,
        _Root | Power[_, exponent_Rational /;
          Denominator[exponent] > 1]],
      fail["MappedChartStripContainsRadicals"]];

    Print["CF3032119K23V1 stage=finite-field mapSeconds=",
      Round[mapSeconds, 0.1], " chartLeaves=", LeafCount[chartStrip]];
    solveSeconds = First@AbsoluteTiming[
      inner = FeynFacet`SolveEpsFormStripFiniteField[
        <|"Family" -> "CF303", "Sector" -> 21,
          "LowerSector" -> 19, "Variables" -> chartVariables,
          "Regulator" -> regulator, "Strip" -> chartStrip|>,
        "KernelCount" -> 5,
        "ArtifactDirectory" -> artifactDirectory,
        "ArtifactPrefix" -> "CF303_21_19_kallen23_source_v1",
        "Backend" -> Automatic, "BackendThreads" -> 1,
        "PlanDiscoveryBackend" -> "FLINTAffineRREF",
        "SupportStrategy" -> "SimplexFirst",
        "SupportLearning" -> True,
        "RegulatorSampling" -> "HeldOut",
        "FinalCheck" -> "Exact", "Verbose" -> True]];
    If[! AssociationQ[inner] || Lookup[inner, "Status", None] =!= "Solved" ||
        ! TrueQ[Lookup[inner, "ExactDLog", False]],
      fail["Kallen23FiniteFieldSolveFailed", <|
        "Result" -> If[AssociationQ[inner],
          KeyDrop[inner, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], inner]|>]];

    identityData = <|"Status" -> "OK", "Kind" -> "TwoVariable",
      "CoefficientField" -> "Multiquadratic",
      "Variables" -> sourceVariables,
      "SourceVariables" -> sourceVariables,
      "Subst" -> Thread[sourceVariables -> sourceVariables],
      "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
      "Root" -> sourceRoots[[1, "Root"]],
      "RootSquare" -> sourceRoots[[1, "RootSquare"]],
      "Roots" -> sourceRoots|>;
    coordinateMap = FeynFacet`Private`masterTransportRecordCoordinateMap[
      <|"Variables" -> chartVariables, "Chart" -> rekeyed|>,
      identityData, Automatic];
    If[Lookup[coordinateMap, "Status", None] =!= "OK" ||
        ! TrueQ[coordinateMap["CompositionExact"]],
      fail["Kallen23InverseCoordinateMapFailed"]];
    nestedRadicand = bundle["NestedRadicand"];
    nestedRootImage = bundle["NestedRootImage"];
    canonicalize[expression_] := Together[expression /.
      Power[base_, exponent_Rational] :> If[
        Denominator[exponent] === 2 &&
          TrueQ[Together[base - nestedRadicand] === 0],
        nestedRootImage^(2 exponent), Power[base, exponent]]];
    chartGauge = inner["Gauge"];
    rawSourceGauge = Map[Together,
      chartGauge /. coordinateMap["Map"], {2}];
    sourceGauge = Map[canonicalize, rawSourceGauge, {2}];
    sourceAlphabet = DeleteDuplicates[
      canonicalize /@ (Lookup[inner, "Alphabet", {}] /.
        coordinateMap["Map"])];
    signChoices = Tuples[{1, -1}, 2];
    acceptedSigns = Select[signChoices, Function[signs,
      branchImages = MapThread[Times, {signs, rootImages}];
      branchedGauge =
        FeynFacet`Private`transportChartApplyRootBranches[
          sourceGauge, usedRoots, branchImages];
      zeroMatrixQ[(branchedGauge /. data["Subst"]) - chartGauge]]];
    If[acceptedSigns === {},
      fail["SourceGaugeRoundTripFailed"]];
    branchImages = MapThread[Times, {First[acceptedSigns], rootImages}];
    sourceTransformed = Table[Map[Together,
      strip[[3, mu]] + regulator (strip[[1, mu]] . sourceGauge -
        sourceGauge . strip[[2, mu]]) -
        D[sourceGauge, sourceVariables[[mu]]], {2}], {mu, 2}];
    chartTransformed = Table[Map[Together,
      chartStrip[[3, mu]] + regulator (chartStrip[[1, mu]] . chartGauge -
        chartGauge . chartStrip[[2, mu]]) -
        D[chartGauge, chartVariables[[mu]]], {2}], {mu, 2}];
    branchedGauge = FeynFacet`Private`transportChartApplyRootBranches[
      sourceTransformed, usedRoots, branchImages];
    pullPair[pair_] := Module[{components},
      components = Map[
        Map[Together, # /. data["Subst"], {2}] &, pair];
      FeynFacet`Private`masterTransportPullBackOneForm[
        components[[1]], components[[2]], data["Jacobian"]]];
    pulledTransformed = pullPair[branchedGauge];
    sourceCensus = FeynFacet`Private`transportChartRootIndices[
      sourceGauge, sourceRoots];
    unclassifiedRadicals = Lookup[sourceCensus,
      "UnclassifiedRadicalBases", {Missing["Absent"]}];
    constantField = If[AnyTrue[unclassifiedRadicals,
        TrueQ[Together[# - 2] === 0] &], "Q(Sqrt[2])", "Q"];
    checks = <|
      "RecurrenceChecksPassed" -> And @@ Values[recurrenceChecks],
      "Kallen23ChartExact" -> TrueQ[chartCertificate["OK"]],
      "MappedStripRational" -> FreeQ[chartStrip,
        _Root | Power[_, exponent_Rational /;
          Denominator[exponent] > 1]],
      "InnerSolvedExactDLog" -> TrueQ[inner["ExactDLog"]],
      "GaugeDimensionsExact" -> Dimensions[sourceGauge] === {2, 4},
      "GaugeRoundTripHasSheet" -> acceptedSigns =!= {},
      "TransformedOneFormPullBack" ->
        zeroMatrixQ[pulledTransformed[[1]] - chartTransformed[[1]]] &&
        zeroMatrixQ[pulledTransformed[[2]] - chartTransformed[[2]]],
      "OnlyDeclaredConstantRadicalsUnclassified" -> AllTrue[
        unclassifiedRadicals, TrueQ[Together[# - 2] === 0] &],
      "OnlyKallen23RootsUsed" -> SubsetQ[{1, 2},
        Lookup[sourceCensus, "RootIndices", {}]],
      "ResidualThirdRootAbsent" ->
        ! MemberQ[Lookup[sourceCensus, "RootIndices", {}], 3],
      "AlphabetEpsilonFree" -> FreeQ[sourceAlphabet, regulator]|>;
    If[! And @@ Values[checks],
      fail["SourceSolutionChecksFailed", <|
        "Checks" -> checks, "SourceCensus" -> sourceCensus|>]];
    sourceSolution = <|
      "Status" -> "Solved",
      "Method" -> "RationalChart/Kallen23/" <> inner["Method"] <>
        "/CanonicalizedSourcePullback",
      "Gauge" -> sourceGauge, "RootIndices" -> {1, 2},
      "RootSquares" -> rootSquares, "Chart" -> rekeyed,
      "Alphabet" -> sourceAlphabet,
      "InnerSolution" -> KeyDrop[inner, "Gauge"],
      "ExactDLog" -> True, "Certificate" -> "ExactDLog",
      "ConstantField" -> constantField,
      "FrameCertificate" -> <|
        "CoordinateComposition" -> coordinateMap["CompositionExact"],
        "BranchSigns" -> First[acceptedSigns],
        "AllAcceptedBranchSigns" -> acceptedSigns,
        "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True,
        "SourceDLog" -> True, "NestedRadicalCanonicalized" -> True,
        "Exact" -> True|>|>;
    exportAtomic[<|
      "Status" -> "CF303Sector2119Kallen23SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 19,
      "SourceStrip" -> strip, "ChartStrip" -> chartStrip,
      "RecurrenceChecks" -> recurrenceChecks,
      "SourceSolution" -> sourceSolution,
      "Checks" -> checks, "MapSeconds" -> mapSeconds,
      "SolveSeconds" -> solveSeconds,
      "SourceRootCensus" -> sourceCensus,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector2119Kallen23SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 19,
      "Method" -> sourceSolution["Method"],
      "RootIndices" -> sourceSolution["RootIndices"],
      "ConstantField" -> constantField,
      "GaugeDimensions" -> Dimensions[sourceGauge],
      "GaugeLeafCount" -> LeafCount[sourceGauge],
      "AlphabetLength" -> Length[sourceAlphabet],
      "AcceptedBranchSigns" -> First[acceptedSigns],
      "MapSeconds" -> mapSeconds, "SolveSeconds" -> solveSeconds,
      "Checks" -> checks, "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032119K23V1 status=PASS mapSeconds=",
      Round[mapSeconds, 0.1], " solveSeconds=", Round[solveSeconds, 0.1],
      " sourceLeaves=", LeafCount[sourceGauge]];
    0,
    tag];
  result
]
