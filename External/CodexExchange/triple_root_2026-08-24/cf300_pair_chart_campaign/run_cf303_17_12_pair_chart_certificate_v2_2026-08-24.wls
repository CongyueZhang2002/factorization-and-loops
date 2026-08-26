#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stripFile,
    solutionFile, expectedHashes, hashHex, badHashes, outdir,
    certificateFile, summaryFile, stripPayload, solutionPayload, solution,
    variables, regulator, strip, leftDiagonal, rightDiagonal, forcing,
    gauge, alphabet, residueMatrices, transformed, dlogTarget,
    zeroMatrixPairQ, correctResidualZero, derivativeSignMutant,
    connectionSignMutant, sourceVariables, substitution, sourceRoots,
    rootImages, activeRoots, activeRootImages, chartBranchRoots,
    sourceX, sourceY, p, q, root2, root3, pInverse, zInverse, qInverse,
    applyChartBranch, chosenRoundTrip, signChoices, acceptedSigns,
    fieldZeroQ, sourceRoundTrip, jacobian, inverseJacobian,
    inverseJacobianChart, differentialChartCheck, differentialSourceCheck,
    sourceGauge, gaugeRoundTrip, unipotent, nilpotentPart,
    unipotentInverse, unipotentCheck, nestedCheck, dlogs, dlogClosed,
    denominators, candidatePoints, openPoint, exactFlags, checks,
    certificate, summary, putAtomic, exportAtomic, fail, tag, result},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stripFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_strip_v1/CF303_17_12_pair_chart_strip_v1.wxf";
  solutionFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_certificate_v2";
  certificateFile = FileNameJoin[{outdir, "certificate.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303PairChartCertificateV2$"];
  expectedHashes = <|
    stripFile ->
      "246b89517021211fd41470a4ff7ec6591c674b9f694481c820a8b9b8bf3779d4",
    solutionFile ->
      "20ed234d0bb41933aa120f329193779c005be920fabbdc84d493f5c55985a3e9",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09"|>;

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
    Print["CF303 PAIR CHART CERTIFICATE FAILURE V2: " <> message];
    Throw[$Failed, tag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {}, fail["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["must run on a pool subkernel"]];
    If[Length[Kernels[]] =!= 0,
      fail["mission worker already owns nested kernels"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["output already exists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["immutable input hash mismatch: " <>
        ToString[badHashes, InputForm]]];
    CreateDirectory[outdir];
    Print["CF303CERTV2 stage=load"];
    Get[loadFile];
    stripPayload = Import[stripFile, "WXF"];
    solutionPayload = Import[solutionFile, "WXF"];
    solution = Lookup[solutionPayload, "Solution", $Failed];
    If[! AssociationQ[stripPayload] || ! AssociationQ[solution] ||
        Lookup[stripPayload, "Status", None] =!=
          "CF303PairChartRationalStripV1" ||
        Lookup[solutionPayload, "Status", None] =!=
          "CF303PairChartRationalSolutionV1",
      fail["invalid strip or solution ABI"]];

    variables = stripPayload["Variables"];
    regulator = stripPayload["Regulator"];
    strip = stripPayload["Strip"];
    {leftDiagonal, rightDiagonal, forcing} = strip;
    gauge = solution["Gauge"];
    alphabet = solution["Alphabet"];
    residueMatrices = solution["ResidueMatrices"];
    {p, q} = variables;
    If[Dimensions[gauge] =!= {1, 4} || Length[alphabet] =!= 14 ||
        Dimensions[residueMatrices] =!= {14, 1, 4},
      fail["solution shape changed"]];
    zeroMatrixPairQ[pair_List] := AllTrue[
      Flatten[Map[Together, pair, {3}]], TrueQ[# === 0] &];

    Print["CF303CERTV2 stage=independent-dlog-residual"];
    transformed = Table[Map[Together,
      forcing[[mu]] + regulator
        (leftDiagonal[[mu]] . gauge - gauge . rightDiagonal[[mu]]) -
        D[gauge, variables[[mu]]], {2}], {mu, 2}];
    dlogTarget = Table[Map[Together, regulator Total[MapThread[
      #1 Together[D[#2, variables[[mu]]]/#2] &,
      {residueMatrices, alphabet}]], {2}], {mu, 2}];
    correctResidualZero = zeroMatrixPairQ[transformed - dlogTarget];
    derivativeSignMutant = Table[Map[Together,
      forcing[[mu]] + regulator
        (leftDiagonal[[mu]] . gauge - gauge . rightDiagonal[[mu]]) +
        D[gauge, variables[[mu]]] - dlogTarget[[mu]], {2}], {mu, 2}];
    connectionSignMutant = Table[Map[Together,
      forcing[[mu]] - regulator
        (leftDiagonal[[mu]] . gauge - gauge . rightDiagonal[[mu]]) -
        D[gauge, variables[[mu]]] - dlogTarget[[mu]], {2}], {mu, 2}];

    Print["CF303CERTV2 stage=function-field-isomorphism"];
    sourceVariables = stripPayload["SourceVariables"];
    substitution = stripPayload["SourceSubstitution"];
    sourceRoots = stripPayload["SourceRoots"];
    rootImages = stripPayload["RootImages"];
    activeRoots = sourceRoots[[1 ;; 2]];
    activeRootImages = rootImages[[1 ;; 2]];
    chartBranchRoots = Map[
      <|"RootSquare" -> Together[#1["RootSquare"] /. substitution]|> &,
      activeRoots];
    {sourceX, sourceY} = sourceVariables;
    root2 = activeRoots[[1, "Root"]];
    root3 = activeRoots[[2, "Root"]];
    pInverse = Together[(1 - sourceX - sourceY - root2)/2];
    zInverse = Together[(1 - sourceX - sourceY + root2)/2];
    qInverse = Together[(root3 - 1 - pInverse)/(zInverse - 1)];
    applyChartBranch[expression_, signs_List : {1, 1}] := Together[
      FeynFacet`Private`transportChartApplyRootBranches[
        expression /. substitution, chartBranchRoots,
        MapThread[Times,
          {signs, Lookup[activeRootImages, "Root"]}]]];
    chosenRoundTrip = Together /@
      {applyChartBranch[pInverse] - p, applyChartBranch[qInverse] - q};
    signChoices = Tuples[{1, -1}, 2];
    acceptedSigns = Select[signChoices, Function[signs,
      And @@ (TrueQ[# === 0] & /@ (Together /@
        {applyChartBranch[pInverse, signs] - p,
          applyChartBranch[qInverse, signs] - q}))]];

    fieldZeroQ[expression_] := Module[{channels},
      channels = FeynFacet`Private`multiquadraticFieldDecompose[
        expression, activeRoots];
      channels =!= $Failed &&
        AllTrue[Together /@ channels, TrueQ[# === 0] &]];
    sourceRoundTrip = Map[fieldZeroQ,
      ((Last /@ substitution) /. {p -> pInverse, q -> qInverse}) -
        sourceVariables];
    jacobian = stripPayload["Jacobian"];
    inverseJacobian = Table[
      D[{pInverse, qInverse}[[i]], sourceVariables[[j]]],
      {i, 2}, {j, 2}];
    inverseJacobianChart = Map[applyChartBranch, inverseJacobian, {2}];
    differentialChartCheck = AllTrue[
      Flatten[Map[Together,
        inverseJacobianChart . jacobian - IdentityMatrix[2], {2}]],
      TrueQ[# === 0] &];
    differentialSourceCheck = AllTrue[Flatten[Map[fieldZeroQ,
      (jacobian /. {p -> pInverse, q -> qInverse}) . inverseJacobian -
        IdentityMatrix[2], {2}]], TrueQ];

    Print["CF303CERTV2 stage=gauge-roundtrip-and-inverse"];
    sourceGauge = gauge /. {p -> pInverse, q -> qInverse};
    gaugeRoundTrip = AllTrue[
      Flatten[Map[Together, Map[applyChartBranch, sourceGauge, {2}] - gauge,
        {2}]], TrueQ[# === 0] &];
    nilpotentPart = ArrayFlatten[{{ConstantArray[0, {1, 1}], gauge},
      {ConstantArray[0, {4, 1}], ConstantArray[0, {4, 4}]}}];
    unipotent = IdentityMatrix[5] + nilpotentPart;
    unipotentInverse = IdentityMatrix[5] - nilpotentPart;
    unipotentCheck = AllTrue[Flatten[Map[Together,
      {unipotent . unipotentInverse - IdentityMatrix[5],
       unipotentInverse . unipotent - IdentityMatrix[5]}, {3}]],
      TrueQ[# === 0] &];
    nestedCheck = TrueQ[Together[
      stripPayload["NestedRootImage"]^2 -
        stripPayload["NestedRadicand"]] === 0];

    Print["CF303CERTV2 stage=alphabet-and-open-set"];
    dlogs = Table[{Together[D[letter, p]/letter],
        Together[D[letter, q]/letter]}, {letter, alphabet}];
    dlogClosed = AllTrue[dlogs,
      TrueQ[Together[D[#[[2]], p] - D[#[[1]], q]] === 0] &];
    denominators = DeleteDuplicates[Factor /@ Select[
      Denominator[Together[#]] & /@
        Flatten[{strip, gauge, alphabet, Det[jacobian]}],
      ! TrueQ[# === 1] &]];
    candidatePoints = Tuples[{Range[2, 9], Range[2, 9],
      {1, 2, 3, 1/2, 2/3}}];
    openPoint = SelectFirst[candidatePoints, Function[point,
      AllTrue[denominators /. Thread[{p, q, regulator} -> point],
        TrueQ[# =!= 0] &] &&
      AllTrue[alphabet /. Thread[{p, q, regulator} -> point],
        TrueQ[# =!= 0] &]], Missing["NoOpenPoint"]];
    exactFlags = Lookup[solution,
      {"LettersEpsFree", "ResiduesKinematicsFree",
       "ExactPfaffianResidualsZero", "ExactPfaffianIdentitiesZero",
       "DLogFormCertified", "ExactDLog"}, False];

    checks = <|
      "IndependentDLogResidualZero" -> correctResidualZero,
      "DerivativeSignMutantRejected" ->
        ! zeroMatrixPairQ[derivativeSignMutant],
      "ConnectionSignMutantRejected" ->
        ! zeroMatrixPairQ[connectionSignMutant],
      "ChartInverseRoundTrip" -> And @@ (TrueQ[# === 0] & /@
        chosenRoundTrip),
      "OnlyChosenRootBranchRoundTrips" -> acceptedSigns === {{1, 1}},
      "SourceInverseRoundTrip" -> And @@ sourceRoundTrip,
      "DifferentialPullbackChartIdentity" -> differentialChartCheck,
      "DifferentialPullbackSourceIdentity" -> differentialSourceCheck,
      "GaugeRoundTrip" -> gaugeRoundTrip,
      "UnipotentTwoSidedInverse" -> unipotentCheck,
      "NestedRadicalBranchIdentity" -> nestedCheck,
      "DLogsClosed" -> dlogClosed,
      "AlphabetRationalAndRegulatorFree" ->
        FreeQ[alphabet, regulator | _Root |
          Power[_, exponent_Rational /; Denominator[exponent] > 1]],
      "ResiduesKinematicsFree" -> AllTrue[variables,
        FreeQ[residueMatrices, #] &],
      "RegulatorFactorizationStillRequired" ->
        ! FreeQ[residueMatrices, regulator],
      "DeclaredOpenSetNonempty" -> ! MissingQ[openPoint],
      "SolverDLogStageExactFlags" -> And @@ (TrueQ /@ exactFlags),
      "ResidualThirdRootInactive" -> FreeQ[
        {strip, gauge, alphabet}, sourceRoots[[3, "Root"]]]|>;
    If[! And @@ Values[checks],
      fail["exact acceptance check failed: " <>
        ToString[Select[checks, ! TrueQ[#] &], InputForm]]];

    certificate = <|
      "Status" -> "CF303PairChartDLogStripCertificatePassedV2",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "Variables" -> variables, "Regulator" -> regulator,
      "Gauge" -> gauge, "SourceGauge" -> sourceGauge,
      "Alphabet" -> alphabet, "ResidueMatrices" -> residueMatrices,
      "InverseMap" -> {p -> pInverse, q -> qInverse},
      "AcceptedRootSigns" -> acceptedSigns,
      "ExceptionalDenominators" -> denominators,
      "WitnessOpenPoint" -> Thread[{p, q, regulator} -> openPoint],
      "Checks" -> checks, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[certificate, certificateFile];
    summary = <|
      "Status" -> "CF303PairChartDLogStripCertificatePassedV2",
      "CertificateFile" -> certificateFile,
      "CertificateSHA256" -> hashHex[certificateFile],
      "CertificateBytes" -> FileByteCount[certificateFile],
      "GaugeLeafCount" -> LeafCount[gauge],
      "SourceGaugeLeafCount" -> LeafCount[sourceGauge],
      "AlphabetLength" -> Length[alphabet],
      "ExceptionalDenominatorCount" -> Length[denominators],
      "WitnessOpenPoint" -> Thread[{p, q, regulator} -> openPoint],
      "Checks" -> checks, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303CERTV2 status=PASS sourceGaugeLeaves=",
      LeafCount[sourceGauge], " certificate=", certificateFile];
    0,
    tag];
  result
]
