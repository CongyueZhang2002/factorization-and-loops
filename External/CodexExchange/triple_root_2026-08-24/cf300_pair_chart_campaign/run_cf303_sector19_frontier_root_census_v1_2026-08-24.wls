#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stateFile,
    factorBundleFile, outdir, auditFile, summaryFile, expectedHashes,
    hashHex, badHashes, state, bundle, ranges, connection, regulator,
    substitution, sourceRoots, imageRoots, residualRoot, nestedRadicand,
    nestedRootImage, canonicalize, usedRootIndices, analyzeScalar,
    analyzeMatrix, putAtomic, fail, tag, result, rowSector, rowRange,
    lowerSectors, lowerRange, audit = {}, blockRecords = <||>,
    nestedRewriteCount = 0, canonicalExpression, indices, localRoots,
    localImages, sourceChannels, sourceRoundTrip, chartChannels,
    chartExpression, residualChannels, chartRoundTrip, seconds, record,
    rowDiagonalRecords, rightRecords, directRecords, expectedSlots,
    actualSlots,
    rootThreeRecords, oddRecords, summary, j, mu},
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
    "cf303_sector19_frontier_root_census_v1";
  auditFile = FileNameJoin[{outdir, "audit.wl"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector19FrontierCensusV1$"];
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
  fail[message_String, data_: <||>] := (
    Print["CF303 SECTOR19 FRONTIER CENSUS FAILURE V1: " <> message,
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
    Print["CF303S19CENSUSV1 stage=load"];
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
    substitution = bundle["SourceSubstitution"];
    sourceRoots = bundle["SourceRoots"];
    imageRoots = bundle["RootImages"];
    residualRoot = bundle["ResidualRoot"];
    nestedRadicand = bundle["NestedRadicand"];
    nestedRootImage = bundle["NestedRootImage"];
    rowSector = 19;
    rowRange = ranges[[rowSector]];
    lowerSectors = Range[1, 18];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        ! VectorQ[rowRange, IntegerQ] || rowRange === {},
      fail["unexpected pinned state shape", <|"RowRange" -> rowRange|>]];

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
    analyzeScalar[label_String, expression_] := Module[{},
      If[TrueQ[expression === 0],
        record = <|"Label" -> label, "LiteralZero" -> True,
          "SourceRootIndices" -> {}, "ResidualOddChannelZero" -> True,
          "Seconds" -> 0.|>;
        AppendTo[audit, record]; Return[record]];
      canonicalExpression = canonicalize[expression];
      indices = usedRootIndices[canonicalExpression];
      seconds = 0.;
      residualChannels = {Missing["NotMapped"], Missing["NotMapped"]};
      If[MemberQ[indices, 3],
        localRoots = sourceRoots[[indices]];
        localImages = imageRoots[[indices]];
        seconds = First@AbsoluteTiming[
          sourceChannels =
            FeynFacet`Private`multiquadraticFieldDecompose[
              canonicalExpression, localRoots];
          If[sourceChannels === $Failed,
            fail["source decomposition failed", <|"Label" -> label|>]];
          sourceRoundTrip =
            FeynFacet`Private`multiquadraticFieldCompose[
              sourceChannels, localRoots];
          If[sourceRoundTrip === $Failed || ! TrueQ[
              Together[sourceRoundTrip - canonicalExpression] === 0],
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
            fail["residual decomposition failed", <|"Label" -> label|>]];
          chartRoundTrip =
            FeynFacet`Private`multiquadraticFieldCompose[
              residualChannels, {residualRoot}];
          If[chartRoundTrip === $Failed || ! TrueQ[
              Together[chartRoundTrip - chartExpression] === 0],
            fail["chart recomposition failed", <|"Label" -> label|>]]];
        ];
      record = <|"Label" -> label, "LiteralZero" -> False,
        "SourceRootIndices" -> indices,
        "ResidualOddChannelZero" -> If[MemberQ[indices, 3],
          TrueQ[residualChannels[[2]] === 0], True],
        "Seconds" -> seconds, "SourceLeafCount" -> LeafCount[expression],
        "CanonicalSourceLeafCount" -> LeafCount[canonicalExpression],
        "ResidualChannelLeafCounts" -> If[MemberQ[indices, 3],
          LeafCount /@ residualChannels, {}]|>;
      AppendTo[audit, record];
      record];
    analyzeMatrix[prefix_String, matrix_List] := Flatten@MapIndexed[
      analyzeScalar[prefix <> "/" <>
        StringRiffle[ToString /@ #2, ","], #1] &, matrix, {2}];

    Print["CF303S19CENSUSV1 stage=scan-frontier rowRange=", rowRange];
    rowDiagonalRecords = Flatten@Table[
      analyzeMatrix["E/" <> ToString[mu],
        connection[[mu, rowRange, rowRange]]/regulator], {mu, 2}];
    blockRecords["Diagonal"] = <|
      "ScalarCount" -> Length[rowDiagonalRecords],
      "NonzeroScalarCount" -> Count[rowDiagonalRecords,
        item_Association /; ! TrueQ[item["LiteralZero"]]],
      "SourceThirdRootScalarCount" -> Count[rowDiagonalRecords,
        item_Association /; MemberQ[item["SourceRootIndices"], 3]],
      "ResidualOddScalarCount" -> Count[rowDiagonalRecords,
        item_Association /; ! TrueQ[item["ResidualOddChannelZero"]]],
      "MappingSeconds" -> Total[Lookup[
        rowDiagonalRecords, "Seconds", 0.]]|>;
    Print["CF303S19CENSUSV1 diagonal thirdRoot=",
      blockRecords["Diagonal"]["SourceThirdRootScalarCount"],
      " residualOdd=",
      blockRecords["Diagonal"]["ResidualOddScalarCount"]];
    Do[
      lowerRange = ranges[[j]];
      rightRecords = Flatten@Table[
        analyzeMatrix["C/" <> ToString[j] <> "/" <> ToString[mu],
          connection[[mu, lowerRange, lowerRange]]/regulator], {mu, 2}];
      directRecords = Flatten@Table[
        analyzeMatrix["B/" <> ToString[j] <> "/" <> ToString[mu],
          connection[[mu, rowRange, lowerRange]]], {mu, 2}];
      blockRecords[j] = <|
        "LowerSector" -> j, "LowerWidth" -> Length[lowerRange],
        "RightDiagonalScalarCount" -> Length[rightRecords],
        "DirectForcingScalarCount" -> Length[directRecords],
        "NonzeroScalarCount" -> Count[Join[rightRecords, directRecords],
          record_Association /; ! TrueQ[record["LiteralZero"]]],
        "SourceThirdRootScalarCount" -> Count[
          Join[rightRecords, directRecords], record_Association /;
            MemberQ[record["SourceRootIndices"], 3]],
        "ResidualOddScalarCount" -> Count[
          Join[rightRecords, directRecords], record_Association /;
            ! TrueQ[record["ResidualOddChannelZero"]]],
        "MappingSeconds" -> Total[Lookup[
          Join[rightRecords, directRecords], "Seconds", 0.]]|>;
      Print["CF303S19CENSUSV1 lower=", j,
        " thirdRoot=", blockRecords[j]["SourceThirdRootScalarCount"],
        " residualOdd=", blockRecords[j]["ResidualOddScalarCount"]],
      {j, Reverse[lowerSectors]}];

    expectedSlots = 2 Length[rowRange]^2 + Total[Table[
      2 Length[ranges[[j]]]^2 +
        2 Length[rowRange] Length[ranges[[j]]], {j, lowerSectors}]];
    actualSlots = Length[audit];
    If[actualSlots =!= expectedSlots,
      fail["frontier traversal accounting failed", <|
        "Expected" -> expectedSlots, "Actual" -> actualSlots|>]];
    rootThreeRecords = Select[audit,
      MemberQ[Lookup[#, "SourceRootIndices", {}], 3] &];
    oddRecords = Select[audit,
      ! TrueQ[Lookup[#, "ResidualOddChannelZero", True]] &];
    putAtomic[<|"Status" -> "CF303Sector19FrontierRootCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 19,
      "BlockRecords" -> blockRecords, "ScalarRecords" -> audit,
      "InputHashes" -> expectedHashes, "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, auditFile];
    summary = <|
      "Status" -> "CF303Sector19FrontierRootCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 19,
      "BlockRecords" -> blockRecords,
      "ScalarCount" -> actualSlots,
      "NestedRadicalRewriteScalarCount" -> nestedRewriteCount,
      "SourceThirdRootScalarCount" -> Length[rootThreeRecords],
      "SourceThirdRootLabels" -> Lookup[rootThreeRecords, "Label", {}],
      "ResidualOddScalarCount" -> Length[oddRecords],
      "ResidualOddLabels" -> Lookup[oddRecords, "Label", {}],
      "FirstDescendingResidualOddSector" -> SelectFirst[
        Reverse[lowerSectors],
        blockRecords[#]["ResidualOddScalarCount"] > 0 &,
        Missing["NoResidualOddFrontier"]],
      "TotalMappingSeconds" -> Total[Lookup[audit, "Seconds", 0.]],
      "AuditFile" -> auditFile, "AuditSHA256" -> hashHex[auditFile],
      "InputHashes" -> expectedHashes, "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303S19CENSUSV1 status=PASS thirdRoot=",
      Length[rootThreeRecords], " residualOdd=", Length[oddRecords],
      " firstDescending=", summary["FirstDescendingResidualOddSector"],
      " seconds=", Round[summary["TotalMappingSeconds"], 0.1]];
    0,
    tag];
  result
]
