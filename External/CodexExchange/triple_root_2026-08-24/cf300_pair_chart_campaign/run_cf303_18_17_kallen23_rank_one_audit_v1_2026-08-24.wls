#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    factorBundleFile, outdir, payloadFile, summaryFile, expectedHashes,
    hashHex, badHashes, state, bundle, ranges, connection, regulator,
    sourceVariables, chartVariables, substitution, jacobian, sourceRoots,
    imageRoots, residualRoot, nestedRadicand, nestedRootImage,
    canonicalize, nestedRewriteCount = 0, usedRootIndices, mapScalar,
    mapMatrix, pullBackGrade, putAtomic, exportAtomic, fail, tag, result,
    rowSector, lowerSector, rowRange, lowerRange, leftSource, rightSource,
    forcingSource, leftChannels, rightChannels, forcingChannels,
    leftEven, leftOdd, rightEven, rightOdd, forcingEven, forcingOdd,
    audit = {}, mappedCount = 0, zeroCount = 0, oddRecords,
    allCoefficients, radicalPattern, sourceRoundTrip, chartRoundTrip,
    sourceChannels, chartChannels, chartExpression, residualChannels,
    localRoots, localImages, canonicalExpression, indices, seconds,
    record, residualMutantRejected, payload, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  factorBundleFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_factor_audit_v3/chart_factor_bundle.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_18_17_kallen23_rank_one_audit_v1";
  payloadFile = FileNameJoin[{outdir, "rank_one_strip.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3031817RankOneAuditV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    factorBundleFile ->
      "8dccaff196948ffadb354370fac3b59c5e84e297886eec179e3e5328ff30a1ec"|>;

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
  fail[message_String, data_: <||>] := (
    Print["CF303 18->17 RANK-ONE AUDIT FAILURE V1: " <> message,
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
    Print["CF3031817R1V1 stage=load"];
    Get[loadFile];
    state = Get[stateFile];
    bundle = Get[factorBundleFile];
    If[! AssociationQ[state] || ! AssociationQ[bundle] ||
        Lookup[bundle, "Status", None] =!=
          "CF303PairFactorBundlePassedV3",
      fail["invalid pinned input ABI"]];
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
    rowSector = 18;
    lowerSector = 17;
    rowRange = ranges[[rowSector]];
    lowerRange = ranges[[lowerSector]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        Length[rowRange] =!= 2 || lowerRange =!= {28},
      fail["unexpected pinned block shape", <|
        "RowRange" -> rowRange, "LowerRange" -> lowerRange|>]];

    canonicalize[expression_] := Module[{rewritten},
      rewritten = expression /. Power[base_, exponent_Rational] :>
        If[Denominator[exponent] === 2 &&
            TrueQ[Together[base - nestedRadicand] === 0],
          nestedRootImage^(2 exponent), Power[base, exponent]];
      If[! SameQ[rewritten, expression], nestedRewriteCount++];
      Together[rewritten]];
    usedRootIndices[expression_] := Flatten@Position[
      Table[Module[{marker = Unique["rootMarker$"]},
        ! FreeQ[FeynFacet`Private`transportChartApplyRootBranches[
          expression, {sourceRoots[[index]]}, {marker}], marker]],
        {index, Length[sourceRoots]}], True];
    mapScalar[label_String, expression_] := Module[{},
      If[TrueQ[expression === 0], zeroCount++; Return[{0, 0}]];
      canonicalExpression = canonicalize[expression];
      indices = usedRootIndices[canonicalExpression];
      localRoots = sourceRoots[[indices]];
      localImages = imageRoots[[indices]];
      seconds = First@AbsoluteTiming[
        sourceChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            canonicalExpression, localRoots];
        If[sourceChannels === $Failed,
          fail["source decomposition failed", <|"Label" -> label,
            "RootIndices" -> indices|>]];
        sourceRoundTrip =
          FeynFacet`Private`multiquadraticFieldCompose[
            sourceChannels, localRoots];
        If[sourceRoundTrip === $Failed ||
            ! TrueQ[Together[sourceRoundTrip - canonicalExpression] === 0],
          fail["source recomposition failed", <|"Label" -> label|>]];
        chartChannels = Together /@ (sourceChannels /. substitution);
        chartExpression =
          FeynFacet`Private`multiquadraticFieldCompose[
            chartChannels, localImages];
        If[chartExpression === $Failed,
          fail["chart composition failed", <|"Label" -> label|>]];
        residualChannels =
          FeynFacet`Private`multiquadraticFieldDecompose[
            chartExpression, {residualRoot}];
        If[residualChannels === $Failed,
          fail["residual decomposition failed", <|"Label" -> label,
            "RootIndices" -> indices|>]];
        chartRoundTrip =
          FeynFacet`Private`multiquadraticFieldCompose[
            residualChannels, {residualRoot}];
        If[chartRoundTrip === $Failed ||
            ! TrueQ[Together[chartRoundTrip - chartExpression] === 0],
          fail["chart recomposition failed", <|"Label" -> label|>]]];
      mappedCount++;
      record = <|"Label" -> label, "SourceRootIndices" -> indices,
        "Seconds" -> seconds,
        "SourceLeafCount" -> LeafCount[expression],
        "CanonicalSourceLeafCount" -> LeafCount[canonicalExpression],
        "ResidualChannelLeafCounts" -> (LeafCount /@ residualChannels),
        "ResidualOddChannelZero" ->
          TrueQ[residualChannels[[2]] === 0]|>;
      AppendTo[audit, record];
      Print["CF3031817R1V1 mapped=", label, " roots=", indices,
        " oddZero=", record["ResidualOddChannelZero"], " seconds=",
        Round[seconds, 0.01]];
      residualChannels];
    mapMatrix[prefix_String, matrix_List] := MapIndexed[
      mapScalar[prefix <> "/" <>
        StringRiffle[ToString /@ #2, ","], #1] &, matrix, {2}];
    pullBackGrade[forms_List, grade_Integer] := Table[
      Map[Together,
        Map[#[[grade]] &, forms[[1]], {2}] jacobian[[1, component]] +
          Map[#[[grade]] &, forms[[2]], {2}]
            jacobian[[2, component]], {2}], {component, 2}];

    Print["CF3031817R1V1 stage=map-operands rowRange=", rowRange];
    leftSource = Table[
      connection[[mu, rowRange, rowRange]]/regulator, {mu, 2}];
    rightSource = Table[
      connection[[mu, lowerRange, lowerRange]]/regulator, {mu, 2}];
    forcingSource = Table[
      connection[[mu, rowRange, lowerRange]], {mu, 2}];
    leftChannels = Table[
      mapMatrix["E/" <> ToString[mu], leftSource[[mu]]], {mu, 2}];
    rightChannels = Table[
      mapMatrix["C/" <> ToString[mu], rightSource[[mu]]], {mu, 2}];
    forcingChannels = Table[
      mapMatrix["B/" <> ToString[mu], forcingSource[[mu]]], {mu, 2}];
    leftEven = pullBackGrade[leftChannels, 1];
    leftOdd = pullBackGrade[leftChannels, 2];
    rightEven = pullBackGrade[rightChannels, 1];
    rightOdd = pullBackGrade[rightChannels, 2];
    forcingEven = pullBackGrade[forcingChannels, 1];
    forcingOdd = pullBackGrade[forcingChannels, 2];
    oddRecords = Select[audit,
      ! TrueQ[Lookup[#, "ResidualOddChannelZero", True]] &];
    allCoefficients = Flatten[{leftEven, leftOdd, rightEven, rightOdd,
      forcingEven, forcingOdd}];
    radicalPattern = _Root | Power[_, exponent_Rational /;
      Denominator[exponent] > 1];
    residualMutantRejected = If[oddRecords === {}, True,
      AnyTrue[Flatten[{leftOdd, rightOdd, forcingOdd}],
        ! TrueQ[Together[2 residualRoot["Root"] #] === 0] &]];
    If[mappedCount + zeroCount =!= 14 || Length[audit] =!= mappedCount,
      fail["operand traversal accounting failed", <|
        "Mapped" -> mappedCount, "Zeros" -> zeroCount|>]];
    If[! TrueQ[residualMutantRejected],
      fail["nonzero residual grade was not retained"]];

    payload = <|
      "Status" -> "CF3031817Kallen23RankOneAuditPassedV1",
      "Family" -> "CF303", "Sector" -> 18, "LowerSector" -> 17,
      "Chart" -> "Kallen23", "Variables" -> chartVariables,
      "Regulator" -> regulator, "ResidualRoot" -> residualRoot,
      "RowRange" -> rowRange, "LowerRange" -> lowerRange,
      "LeftDiagonalEven" -> leftEven, "LeftDiagonalOdd" -> leftOdd,
      "RightDiagonalEven" -> rightEven, "RightDiagonalOdd" -> rightOdd,
      "ForcingEven" -> forcingEven, "ForcingOdd" -> forcingOdd,
      "FactorAudit" -> audit, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    exportAtomic[payload, payloadFile];
    summary = <|
      "Status" -> "CF3031817Kallen23RankOneAuditPassedV1",
      "Family" -> "CF303", "Sector" -> 18, "LowerSector" -> 17,
      "Chart" -> "Kallen23", "MappedNonzeroScalars" -> mappedCount,
      "SkippedLiteralZeros" -> zeroCount,
      "NestedRadicalRewriteScalarCount" -> nestedRewriteCount,
      "SourceRootUseCounts" ->
        Counts[Lookup[audit, "SourceRootIndices", {}]],
      "ResidualOddChannelNonzeroCount" -> Length[oddRecords],
      "ResidualOddChannelLabels" -> Lookup[oddRecords, "Label", {}],
      "CoefficientRadicalFree" -> FreeQ[allCoefficients, radicalPattern],
      "ResidualMutantRejected" -> residualMutantRejected,
      "TotalMappingSeconds" -> Total[Lookup[audit, "Seconds", {}]],
      "PayloadFile" -> payloadFile,
      "PayloadSHA256" -> hashHex[payloadFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3031817R1V1 status=PASS oddNonzero=", Length[oddRecords],
      " radicalFree=", summary["CoefficientRadicalFree"],
      " totalSeconds=", Round[summary["TotalMappingSeconds"], 0.1]];
    0,
    tag];
  result
]
