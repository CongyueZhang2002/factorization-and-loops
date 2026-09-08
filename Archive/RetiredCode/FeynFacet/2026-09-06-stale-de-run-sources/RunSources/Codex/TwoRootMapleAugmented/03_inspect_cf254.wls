#!/usr/bin/env wolframscript

$HistoryLength = 0;

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
  "sector_CF254_standard/CF254_9_8_unsolved.wl";

zeroQ[expr_] := AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

factorSummary[expr_, variables_List] := Module[
  {denominator, factors},
  denominator = Denominator[Together[expr]];
  factors = FactorList[denominator];
  <|
    "Denominator" -> denominator,
    "Factors" -> factors,
    "Degrees" -> AssociationThread[
      SymbolName /@ variables,
      Exponent[denominator, #] & /@ variables]
  |>
];

start = AbsoluteTime[];
record = Get[recordPath];
loadSeconds = AbsoluteTime[] - start;

Print["BEGIN_RECORD"];
Print["record_path=", recordPath];
Print["record_file_hash_sha256=", FileHash[recordPath, "SHA256", "HexString"]];
Print["load_seconds=", InputForm[loadSeconds]];
Print["head=", Head[record]];
Print["keys=", InputForm[Keys[record]]];
Print["metadata=", InputForm[KeyDrop[record, {"Strip"}]]];

variables = record["Variables"];
regulator = record["Regulator"];
strip = record["Strip"];
{e, c, bbar} = strip;
Print["variables=", InputForm[variables]];
Print["variable_contexts=", InputForm[Context /@ variables]];
Print["regulator=", InputForm[regulator]];
Print["regulator_context=", Context[regulator]];
Print["strip_dimensions=", InputForm[Dimensions /@ strip]];
Print["strip_byte_count=", ByteCount[strip]];
Print["strip_leaf_count=", LeafCount[strip]];
Print["nonzero_entry_counts=", InputForm[Count[Flatten[#], Except[0]] & /@ strip]];
Print["all_non_system_symbols=", InputForm[
  SortBy[
    DeleteDuplicates@Cases[strip,
      symbol_Symbol /; Context[symbol] =!= "System`",
      {0, Infinity}, Heads -> True],
    {Context[#], SymbolName[#]} &]]];

entryLabels = {};
entries = {};
Do[
  AppendTo[entryLabels, {part, mu, i, j}];
  AppendTo[entries, strip[[part, mu, i, j]]],
  {part, 3}, {mu, 2},
  {i, Dimensions[strip[[part, mu]]][[1]]},
  {j, Dimensions[strip[[part, mu]]][[2]]}];
nonzeroPositions = Flatten[Position[entries, Except[0], {1}, Heads -> False]];

Print["BEGIN_DENOMINATOR_SUMMARIES"];
Do[
  summaryStart = AbsoluteTime[];
  summary = factorSummary[entries[[position]], Join[variables, {regulator}]];
  Print["entry=", InputForm[entryLabels[[position]]],
    "; seconds=", InputForm[AbsoluteTime[] - summaryStart],
    "; summary=", InputForm[summary]],
  {position, nonzeroPositions}];
Print["END_DENOMINATOR_SUMMARIES"];

flatnessStart = AbsoluteTime[];
stripFlatness = Map[Together,
  D[bbar[[2]], variables[[1]]] - D[bbar[[1]], variables[[2]]] -
    regulator (e[[1]].bbar[[2]] - bbar[[2]].c[[1]]) +
    regulator (e[[2]].bbar[[1]] - bbar[[1]].c[[2]]),
  {2}];
Print["strip_flatness_seconds=", InputForm[AbsoluteTime[] - flatnessStart]];
Print["strip_flatness_zero=", zeroQ[stripFlatness]];
If[! zeroQ[stripFlatness], Print["strip_flatness_residual=", InputForm[stripFlatness]]];
Print["total_seconds=", InputForm[AbsoluteTime[] - start]];
Print["END_RECORD"];

Exit[0];
