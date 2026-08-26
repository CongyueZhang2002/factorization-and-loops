#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{stateFile, checkpointFile, outdir, summaryFile, expectedHashes,
    hashHex, badHashes, state, checkpoint, ranges, connection, prevD,
    solved, len, column, lowerSector, rowRange, lowerRange, sourceX,
    sourceY, lambda1, lambda2, lambda3, bilinear, generators,
    candidates, expressions, radicalBases, classified, failedExpression,
    failedBases, summary, putAtomic, fail, tag, result},
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  checkpointFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_CF303_identity_capture_xh_v4/CF303_17_strip_state.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_radical_census_v1";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303RadicalCensusV1$"];
  expectedHashes = <|
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
    Print["CF303 RADICAL CENSUS FAILURE V1: " <> message];
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
    Print["CF303CENSUSV1 stage=load"];
    state = Get[stateFile];
    checkpoint = Get[checkpointFile];
    ranges = Lookup[state, "Ranges", $Failed];
    connection = Lookup[state, "A", $Failed];
    prevD = Lookup[checkpoint, "PrevD", $Failed];
    If[! ListQ[ranges] || Dimensions[connection] =!= {2, 45, 45} ||
        Dimensions[prevD] =!= {1, 11},
      fail["unexpected pinned input shapes"]];

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

    sourceX = Symbol["Global`x"];
    sourceY = Symbol["Global`y"];
    lambda1 = Together[(1 - sourceX - sourceY)^2 -
      4 sourceX sourceY];
    lambda2 = Together[(1 + sourceX - sourceY)^2 +
      4 sourceX sourceY];
    lambda3 = Together[(1 - sourceX + sourceY)^2 +
      4 sourceX sourceY];
    bilinear = Together[1 - 4 sourceX sourceY];
    generators = {lambda2, lambda3, bilinear};
    candidates = Association@Join[
      {"Lambda1" -> lambda1},
      Table[StringRiffle[Pick[{"Lambda2", "Lambda3", "Bilinear115"},
          IntegerDigits[mask, 2, 3], 1], "*"] ->
        Times @@ Pick[generators, IntegerDigits[mask, 2, 3], 1],
        {mask, 1, 7}]];

    rowRange = ranges[[17]];
    lowerRange = ranges[[12]];
    expressions = Join[
      Flatten[connection[[All, rowRange, rowRange]]],
      Flatten[connection[[All, lowerRange, lowerRange]]],
      Flatten[connection[[All, rowRange, lowerRange]]],
      Flatten[Values[solved]],
      Flatten@Table[connection[[All, ranges[[m]], lowerRange]],
        {m, Keys[solved]}]];
    radicalBases = DeleteDuplicates[Together /@ Cases[
      expressions,
      Power[base_, exponent_Rational] /;
          Denominator[exponent] === 2 :> base,
      Infinity]];
    classified = Map[Function[base,
      <|"Base" -> base, "FactoredBase" -> Factor[base],
        "ExactGeneratorProducts" -> Keys@Select[candidates,
          TrueQ[Together[base - #] === 0] &]|>], radicalBases];

    failedExpression = connection[[1, First[ranges[[15]]],
      First[lowerRange]]];
    failedBases = DeleteDuplicates[Together /@ Cases[
      failedExpression,
      Power[base_, exponent_Rational] /;
          Denominator[exponent] === 2 :> base,
      Infinity]];
    summary = <|
      "Status" -> "CF303RadicalCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "OperandScalarCount" -> Length[expressions],
      "DistinctRadicalBaseCount" -> Length[radicalBases],
      "ClassifiedBases" -> classified,
      "FailedAuditOperand" -> "Alower/1/15/1,1",
      "FailedAuditOperandLeafCount" -> LeafCount[failedExpression],
      "FailedAuditOperandRadicalBases" -> failedBases,
      "CandidateSquares" -> candidates, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303CENSUSV1 status=PASS bases=", Length[radicalBases],
      " classifications=", Lookup[classified, "ExactGeneratorProducts"],
      " failedBases=", failedBases, " summary=", summaryFile];
    0,
    tag];
  result
]
