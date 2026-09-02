#!/usr/bin/env wolframscript

(* Bounded prototype: exact univariate rational arithmetic in eps while every
   eps-free subtree remains an opaque coefficient-field element.  This is a
   development benchmark, not package code. *)

repositoryRoot = ExpandFileName[FileNameJoin[
  {DirectoryName[$InputFileName], "..", ".."}]];
record = Get[FileNameJoin[{repositoryRoot, "Runtime",
  "2026-09-01_observable_transport_triple_final", "cf259_dlog_gpu",
  "family_epsform_CF259_compact.wl"}]];
eps = record["Regulator"];
entries = Select[Flatten[Normal[record["TTotal"]]],
  ! TrueQ[# === 0] &];
entryCount = Replace[Environment["FACET_JET_ENTRY_COUNT"], {
  value_String /; StringMatchQ[value, DigitCharacter ..] :>
    Max[1, ToExpression[value]], _ -> 1}];
largest = TakeLargestBy[entries, LeafCount, UpTo[entryCount]];

ClearAll[polyTrim, polyAdd, polyMul, polyPow, ratAdd, ratMul, ratPow,
  ratCompile, ratJet];

polyTrim[p_List] := Module[{q = p},
  While[Length[q] > 1 && TrueQ[Last[q] === 0], q = Most[q]];
  q
];
polyAdd[a_List, b_List] := polyTrim[
  PadRight[a, Max[Length[a], Length[b]]] +
    PadRight[b, Max[Length[a], Length[b]]]];
polyMul[a_List, b_List] := polyTrim@Table[
  Total@Table[
    a[[i]] b[[k - i + 1]],
    {i, Max[1, k - Length[b] + 1], Min[Length[a], k]}],
  {k, Length[a] + Length[b] - 1}];
polyPow[_, 0] := {1};
polyPow[p_List, n_Integer?Positive] := Module[
  {base = p, exponent = n, out = {1}},
  While[exponent > 0,
    If[OddQ[exponent], out = polyMul[out, base]];
    exponent = Quotient[exponent, 2];
    If[exponent > 0, base = polyMul[base, base]]];
  out
];

ratAdd[{an_, ad_}, {bn_, bd_}] := If[SameQ[ad, bd],
  {polyAdd[an, bn], ad},
  {polyAdd[polyMul[an, bd], polyMul[bn, ad]], polyMul[ad, bd]}];
ratMul[{an_, ad_}, {bn_, bd_}] := {polyMul[an, bn], polyMul[ad, bd]};
ratPow[{n_, d_}, k_Integer] := Which[
  k === 0, {{1}, {1}},
  k > 0, {polyPow[n, k], polyPow[d, k]},
  True, {polyPow[d, -k], polyPow[n, -k]}];

ratCompile[e_] := Which[
  TrueQ[e === 0], {{0}, {1}},
  SameQ[e, eps], {{0, 1}, {1}},
  FreeQ[e, eps], {{e}, {1}},
  Head[e] === Plus, Fold[ratAdd, {{0}, {1}}, ratCompile /@ (List @@ e)],
  Head[e] === Times, Fold[ratMul, {{1}, {1}}, ratCompile /@ (List @@ e)],
  Head[e] === Power && IntegerQ[e[[2]]],
    ratPow[ratCompile[e[[1]]], e[[2]]],
  True, Throw[<|"Unsupported" -> HoldForm[e]|>]
];

ratJet[{num_List, den_List}, high_Integer] := Module[
  {n0, d0, valuation, depth, nn, dd, quotient},
  n0 = FirstPosition[num, x_ /; ! TrueQ[x === 0], Missing["Zero"],
    {1}, Heads -> False];
  If[MissingQ[n0],
    Return[<|"Valuation" -> Infinity, "Coefficients" -> {}|>]];
  d0 = FirstPosition[den, x_ /; ! TrueQ[x === 0], Missing["Zero"],
    {1}, Heads -> False];
  If[MissingQ[d0], Return[$Failed]];
  n0 = First[n0] - 1; d0 = First[d0] - 1;
  valuation = n0 - d0;
  depth = Max[0, high - valuation];
  nn = PadRight[Drop[num, n0], depth + 1];
  dd = PadRight[Drop[den, d0], depth + 1];
  quotient = ConstantArray[0, depth + 1];
  Do[
    quotient[[k + 1]] = (nn[[k + 1]] -
      Sum[dd[[j + 1]] quotient[[k - j + 1]], {j, 1, k}])/dd[[1]],
    {k, 0, depth}];
  <|"Valuation" -> valuation, "Coefficients" -> quotient|>
];

{compileSeconds, rational} = AbsoluteTiming[ratCompile /@ largest];
{jetSeconds, jet} = AbsoluteTiming[ratJet[#, 4] & /@ rational];
Print[InputForm[<|
  "EntryCount" -> Length[largest],
  "EntryLeafCounts" -> (LeafCount /@ largest),
  "CompileSeconds" -> compileSeconds,
  "NumeratorDegrees" -> (Length[First[#]] - 1 & /@ rational),
  "DenominatorDegrees" -> (Length[Last[#]] - 1 & /@ rational),
  "JetSeconds" -> jetSeconds,
  "Valuations" -> Lookup[jet, "Valuation"],
  "FirstJetLeafCount" ->
    Total[LeafCount /@ First[jet]["Coefficients"]],
  "FirstJetByteCount" -> ByteCount[First[jet]]
|>]];

pointRules = Thread[record["Variables"] -> {2/7, 1/5}];
expected = Table[
  SeriesCoefficient[First[largest] /. pointRules, {eps, 0, order}],
  {order, First[jet]["Valuation"], 4}];
actual = First[jet]["Coefficients"] /. pointRules;
Print[InputForm[<|"PointwiseAgreement" ->
  And @@ MapThread[TrueQ[RootReduce[#1 - #2] === 0] &,
    {actual, expected}]|>]];
