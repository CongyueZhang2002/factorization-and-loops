#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    checkpointFile, outdir, bundleFile, summaryFile, expectedHashes,
    hashHex, badHashes, state, checkpoint, ranges, connection, regulator,
    sourceX, sourceY, p, q, z, xImage, yImage, substitution, jacobian,
    lambda2, lambda3, bilinear, sourceRoots, lambda2Image,
    lambda3Image, bilinearImage, residualPolynomial,
    residualDenominator, residualRoot, normalizedResidualRoot, imageRoots,
    prevD, solved, len, column, lowerSector, rowSector, rowRange,
    lowerRange, mappedCount = 0, zeroCount = 0, audit = {},
    usedRootIndices, mapScalar, mapMatrix, leftDiagonal, rightDiagonal,
    directForcing, solvedFactors, lowerConnectionFactors, bundle, summary,
    putAtomic, fail, tag, result},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  checkpointFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_CF303_identity_capture_xh_v4/CF303_17_strip_state.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v1";
  bundleFile = FileNameJoin[{outdir, "chart_factor_bundle.wl"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303PairFactorAuditV1$"];

  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    checkpointFile ->
      "87528ab68d77c4e6e1492dec7f58d59dfc8cb0d29b4e2791ee0bfe6f620f999a"|>;
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[message_String] := (
    Print["CF303 PAIR FACTOR AUDIT FAILURE V1: " <> message];
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

    Print["CF303PAIRV1 stage=load-inputs"];
    Get[loadFile];
    state = Get[stateFile];
    checkpoint = Get[checkpointFile];
    If[! AssociationQ[state] || ! AssociationQ[checkpoint],
      fail["state or checkpoint is not an association"]];
    If[Lookup[checkpoint, "Sector", None] =!= 17 ||
        Lookup[checkpoint, "SubSize", None] =!= 1,
      fail["checkpoint is not the pinned sector-17 row"]];
    ranges = Lookup[state, "Ranges", $Failed];
    connection = Lookup[state, "A", $Failed];
    If[! ListQ[ranges] || Length[ranges] < 17 ||
        Dimensions[connection] =!= {2, 45, 45},
      fail["unexpected state shape"]];

    sourceX = Symbol["Global`x"];
    sourceY = Symbol["Global`y"];
    regulator = Symbol["Global`eps"];
    p = Symbol["Global`pairP"];
    q = Symbol["Global`pairQ"];
    z = Together[(-3 + q) (1 + q - 2 p)/(-1 + q^2)];
    xImage = Together[-z p];
    yImage = Together[(1 - z) (1 - p)];
    substitution = {sourceX -> xImage, sourceY -> yImage};
    jacobian = {
      {Together[D[xImage, p]], Together[D[xImage, q]]},
      {Together[D[yImage, p]], Together[D[yImage, q]]}};

    lambda2 = Together[(1 + sourceX - sourceY)^2 +
      4 sourceX sourceY];
    lambda3 = Together[(1 - sourceX + sourceY)^2 +
      4 sourceX sourceY];
    bilinear = Together[1 - 4 sourceX sourceY];
    sourceRoots = {
      <|"Name" -> "Lambda2", "Root" -> Sqrt[lambda2],
        "RootSquare" -> lambda2|>,
      <|"Name" -> "Lambda3", "Root" -> Sqrt[lambda3],
        "RootSquare" -> lambda3|>,
      <|"Name" -> "Bilinear115", "Root" -> Sqrt[bilinear],
        "RootSquare" -> bilinear|>};
    lambda2Image = Together[z - p];
    lambda3Image = Together[(1 + p) + q (z - 1)];
    bilinearImage = Together[bilinear /. substitution];
    residualPolynomial = Factor[Numerator[bilinearImage]];
    residualDenominator = Factor[Denominator[bilinearImage]];
    If[! TrueQ[Together[residualDenominator - (q^2 - 1)^2] === 0],
      fail["unexpected residual-root denominator"]];
    residualRoot = <|"Name" -> "Kallen23Residual",
      "Root" -> Sqrt[residualPolynomial],
      "RootSquare" -> residualPolynomial|>;
    normalizedResidualRoot =
      Together[residualRoot["Root"]/(q^2 - 1)];
    imageRoots = {
      <|"Root" -> lambda2Image,
        "RootSquare" -> Together[lambda2 /. substitution]|>,
      <|"Root" -> lambda3Image,
        "RootSquare" -> Together[lambda3 /. substitution]|>,
      <|"Root" -> normalizedResidualRoot,
        "RootSquare" -> bilinearImage|>};
    If[! TrueQ[Together[lambda2Image^2 -
          imageRoots[[1, "RootSquare"]]] === 0] ||
        ! TrueQ[Together[lambda3Image^2 -
          imageRoots[[2, "RootSquare"]]] === 0] ||
        ! TrueQ[Together[normalizedResidualRoot^2 -
          imageRoots[[3, "RootSquare"]]] === 0],
      fail["Kallen23 root image check failed"]];

    prevD = Lookup[checkpoint, "PrevD", $Failed];
    If[Dimensions[prevD] =!= {1, 11},
      fail["unexpected recovered row-gauge shape"]];
    solved = <||>;
    len = Length[prevD[[1]]];
    column = len;
    lowerSector = 16;
    While[column > 0 && lowerSector >= 1,
      solved[lowerSector] =
        prevD[[All, column - Length[ranges[[lowerSector]]] + 1 ;; column]];
      column -= Length[ranges[[lowerSector]]];
      lowerSector--];
    If[Sort[Keys[solved]] =!= {13, 14, 15, 16} || column =!= 0,
      fail["recovered row-gauge partition failed"]];

    usedRootIndices[expression_] := Flatten@Position[
      Table[Module[{marker = Unique["rootMarker$"]},
        ! FreeQ[
          FeynFacet`Private`transportChartApplyRootBranches[
            expression, {sourceRoots[[index]]}, {marker}], marker]],
        {index, Length[sourceRoots]}], True];

    mapScalar[label_String, expression_] := Module[
      {indices, localRoots, localImages, sourceChannels, chartChannels,
       chartExpression, residualChannels, seconds, record},
      If[TrueQ[expression === 0], zeroCount++; Return[{0, 0}]];
      indices = usedRootIndices[expression];
      localRoots = sourceRoots[[indices]];
      localImages = imageRoots[[indices]];
      seconds = First@AbsoluteTiming[
        sourceChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            expression, localRoots];
        If[sourceChannels === $Failed,
          fail["source decomposition failed for " <> label]];
        chartChannels = Together /@ (sourceChannels /. substitution);
        chartExpression =
          FeynFacet`Private`multiquadraticFieldCompose[
            chartChannels, localImages];
        If[chartExpression === $Failed,
          fail["chart composition failed for " <> label]];
        residualChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            chartExpression, {residualRoot}];
        If[residualChannels === $Failed,
          fail["residual rank-one decomposition failed for " <> label]]];
      mappedCount++;
      record = <|"Label" -> label, "SourceRootIndices" -> indices,
        "Seconds" -> seconds, "SourceLeafCount" -> LeafCount[expression],
        "ResidualChannelLeafCounts" -> (LeafCount /@ residualChannels),
        "ResidualOddChannelZero" -> TrueQ[residualChannels[[2]] === 0]|>;
      AppendTo[audit, record];
      Print["CF303PAIRV1 mapped=", label, " roots=", indices,
        " seconds=", Round[seconds, 0.01], " leaves=",
        record["ResidualChannelLeafCounts"]];
      residualChannels];
    mapMatrix[prefix_String, matrix_List] := MapIndexed[
      mapScalar[prefix <> "/" <> StringRiffle[ToString /@ First[#2], ","],
        #1] &, matrix, {2}];

    rowSector = 17;
    lowerSector = 12;
    rowRange = ranges[[rowSector]];
    lowerRange = ranges[[lowerSector]];
    If[rowRange =!= {28} || lowerRange =!= {13, 14, 15, 16},
      fail["pinned 17-to-12 range identity changed"]];
    Print["CF303PAIRV1 stage=map-operands"];
    leftDiagonal = Table[
      mapMatrix["E/" <> ToString[mu],
        connection[[mu, rowRange, rowRange]]/regulator], {mu, 2}];
    rightDiagonal = Table[
      mapMatrix["C/" <> ToString[mu],
        connection[[mu, lowerRange, lowerRange]]/regulator], {mu, 2}];
    directForcing = Table[
      mapMatrix["Bdirect/" <> ToString[mu],
        connection[[mu, rowRange, lowerRange]]], {mu, 2}];
    solvedFactors = Association@Table[m ->
      mapMatrix["D/" <> ToString[m], solved[m]], {m, Keys[solved]}];
    lowerConnectionFactors = Association@Table[m -> Table[
      mapMatrix["Alower/" <> ToString[mu] <> "/" <> ToString[m],
        connection[[mu, ranges[[m]], lowerRange]]], {mu, 2}],
      {m, Keys[solved]}];

    bundle = <|
      "Status" -> "CF303PairFactorBundlePassedV1",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "SourceVariables" -> {sourceX, sourceY},
      "ChartVariables" -> {p, q}, "Regulator" -> regulator,
      "SourceSubstitution" -> substitution, "Jacobian" -> jacobian,
      "SourceRoots" -> sourceRoots, "RootImages" -> imageRoots,
      "ResidualRoot" -> residualRoot,
      "NormalizedResidualRoot" -> normalizedResidualRoot,
      "ResidualPolynomial" -> residualPolynomial,
      "LeftDiagonalChannels" -> leftDiagonal,
      "RightDiagonalChannels" -> rightDiagonal,
      "DirectForcingChannels" -> directForcing,
      "SolvedFactorChannels" -> solvedFactors,
      "LowerConnectionFactorChannels" -> lowerConnectionFactors,
      "Ranges" -> KeyTake[AssociationThread[Range[Length[ranges]], ranges],
        Join[{12, 17}, Keys[solved]]],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    summary = <|
      "Status" -> "CF303PairFactorAuditPassedV1",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "Method" -> "Operand-local decomposition then Kallen23 rank-one map",
      "MappedNonzeroScalars" -> mappedCount,
      "SkippedLiteralZeros" -> zeroCount,
      "SourceRootUseCounts" -> Counts[Lookup[audit, "SourceRootIndices"]],
      "ResidualOddChannelNonzeroCount" -> Count[
        Lookup[audit, "ResidualOddChannelZero"], False],
      "TotalMappingSeconds" -> Total[Lookup[audit, "Seconds"]],
      "FactorAudit" -> audit, "BundleFile" -> bundleFile,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[bundle, bundleFile];
    putAtomic[summary, summaryFile];
    Print["CF303PAIRV1 status=PASS mapped=", mappedCount,
      " zeros=", zeroCount, " seconds=",
      Round[summary["TotalMappingSeconds"], 0.1], " summary=", summaryFile];
    0,
    tag];
  result
]
