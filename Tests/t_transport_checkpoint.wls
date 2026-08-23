#!/usr/bin/env wolframscript
(* Budget policy: a Pexp that exceeds its time budget must CHECKPOINT.

   Both 2026-08-16 reviews raised the same operational defect: a
   whole-family PexpExpansion that hit the 1800 s budget returned
   nothing at all -- 1859 CPU-seconds and, worse, the cost data point
   were lost, three times.  The engine's own capability was measured
   before anything was built on top of it: Libra's PexpExpansion is a
   NestList over one operator (Libra.m:2496-2517) and
   PexpExpansion[{M, w}, x, x0] returns the whole prefix
   {U_0, ..., U_w}, so it CAN be driven weight by weight from outside
   without writing a Pexp of our own.  masterTransportBackendLibra
   therefore climbs w = 0, 1, ..., wmax under the budget and keeps the
   last completed list.

   Acceptance criteria, stated before any of them is run.

   K1 the ladder and the single call produce the SAME transport at the
      same weight -- exact expression equality, not a spot check;
   K2 the ladder returns one wall time per completed weight, so a run
      that dies is still a cost data point (the log-t-vs-weight slope
      the reviews asked for);
   K3 a budget too small for the requested weight returns
      "BackendBudgetExceeded" WITH the weights already computed: a list
      of Weight+1 matrices, Partial -> True, and that list is EXACTLY
      the prefix of the complete transport -- not a different object;
   K4 TransportFamily surfaces the overrun as "TransportBudgetExceeded"
      and carries the partial transport AND the depth arithmetic
      (Budget, Shift, ExactDepth) back with it, instead of discarding
      the analysis it had already done;
   K5 with no finite budget the single-call route is taken, i.e. the
      default path is unchanged.

   The ladder's overhead relative to one call is MEASURED and logged; it
   is a performance number, not a contract. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"]; tauS = Symbol["Global`tau"];

log[a___] := Print["[t] ", StringJoin[ToString /@ {a}]];
secs[t_] := ToString[NumberForm[N[t], {8, 2}]] <> " s";

$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x",
  "y", "u", "t", "tau", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[$normalizeNames, SymbolName[s]] && Context[s] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeSymbols[Get[file]];

chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

cf258 = readArtifact[FileNameJoin[{ftDE, "nnlo_de_CF258.wl"}]];
hardRows97 = {18, 19, 20, 21};

(* the assembly only -- MaxWeight -> 0 stops before any transport *)
{assemblySeconds, r0} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, 97}}, "FormDirectory" -> ftClassForms,
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
log["assembly (MaxWeight -> 0): status ", Lookup[r0, "Status", "?"], "  ",
  secs[assemblySeconds]];
If[! (AssociationQ[r0] && KeyExistsQ[r0, "Assembly"]),
  Print["FAIL  no assembly to test the backend on"]; Exit[1]];

assembly = r0["Assembly"];
ahat = FeynFacet`Private`masterTransportPathMatrix[
  assembly["Apv"], assembly["Apw"], {xx, yy}, {1/2, yy}, tauS, {xx, yy}];

backend = FeynFacet`Private`masterTransportBackendLibra;

(* ----------------------------------------------------------------- K1/K2 *)

weight = 3;
{singleSeconds, single} = AbsoluteTiming[backend[ahat, tauS, weight, root]];
log["single call, weight ", weight, ": status ", single["Status"],
  ", route ", Lookup[single, "Route", "?"], "  ", secs[singleSeconds]];

{ladderSeconds, ladder} = AbsoluteTiming[backend[ahat, tauS, weight, root, 600]];
log["weight ladder, weight ", weight, ": status ", ladder["Status"],
  ", route ", Lookup[ladder, "Route", "?"], ", per-weight ",
  Lookup[ladder, "PerWeightSeconds", {}], "  ", secs[ladderSeconds]];
log["K4 MEASURED ladder overhead: ",
  ToString[NumberForm[N[ladderSeconds/singleSeconds], {4, 2}]], "x the single call"];

FTAssert["K1 the weight ladder and the single call produce the SAME \
transport at the same weight, as exact expression equality",
  AssociationQ[single] && single["Status"] === "OK" &&
    AssociationQ[ladder] && ladder["Status"] === "OK" &&
    ladder["Weight"] === weight && TrueQ[ladder["U"] === single["U"]]];

FTAssert["K2 the ladder returns one wall time per completed weight, so a \
run that dies is still a cost data point",
  AssociationQ[ladder] &&
    Length[Lookup[ladder, "PerWeightSeconds", {}]] === weight + 1 &&
    Lookup[ladder, "PerWeightSeconds", {}][[All, 1]] === Range[0, weight] &&
    AllTrue[Lookup[ladder, "PerWeightSeconds", {}][[All, 2]], NumericQ]];

FTAssert["K5 with no finite budget the single-call route is taken, so the \
default path is unchanged",
  Lookup[single, "Route", None] === "SingleCall" &&
    Lookup[ladder, "Route", None] === "WeightLadder"];

(* ------------------------------------------------------------------- K3 *)

(* The budget is calibrated from the ladder's OWN measured per-weight
   times: enough for the first weights, not enough for the last.  A
   fixed number would be a guess about this machine. *)
perWeight = Lookup[ladder, "PerWeightSeconds", {}][[All, 2]];
budget = Total[Take[perWeight, Min[2, Length[perWeight]]]] + 0.05;
log["K3 forcing an overrun: requesting weight ", weight + 2,
  " with a budget of ", secs[budget]];
{partialSeconds, partial} = AbsoluteTiming[backend[ahat, tauS, weight + 2, root, budget]];
log["K3 partial: status ", partial["Status"], ", weight ",
  Lookup[partial, "Weight", "?"], " of ", Lookup[partial, "Requested", "?"],
  ", per-weight ", Lookup[partial, "PerWeightSeconds", {}], "  ", secs[partialSeconds]];

FTAssert["K3 a budget too small for the requested weight returns the \
weights ALREADY COMPUTED -- a genuine prefix of the complete transport -- \
and says so, instead of returning nothing",
  AssociationQ[partial] && partial["Status"] === "BackendBudgetExceeded" &&
    TrueQ[partial["Partial"]] &&
    IntegerQ[partial["Weight"]] && partial["Weight"] >= 0 &&
    partial["Weight"] < weight + 2 &&
    ListQ[partial["U"]] && Length[partial["U"]] === partial["Weight"] + 1 &&
    TrueQ[partial["U"] === Take[single["U"], partial["Weight"] + 1]]];

(* ------------------------------------------------------------------- K4 *)

budgetFamily = Max[0.05, Total[Take[perWeight, Min[1, Length[perWeight]]]]/4];
log["K4 whole-stage overrun: TimeConstraint ", secs[budgetFamily]];
stage = FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, 97}}, "FormDirectory" -> ftClassForms,
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 10, "DepthReport" -> True,
  "TimeConstraint" -> budgetFamily, "Verbose" -> False];
log["K4 stage status ", Lookup[stage, "Status", "?"],
  ", partial weight ", Lookup[stage, "PartialWeight", "?"],
  " of ", Lookup[stage, "RequestedWeight", "?"],
  ", per-weight ", Lookup[stage, "PerWeightSeconds", {}]];

FTAssert["K4 TransportFamily reports a budget overrun as \
TransportBudgetExceeded and carries the partial transport AND the depth \
arithmetic back, instead of discarding the analysis it already did",
  AssociationQ[stage] && stage["Status"] === "TransportBudgetExceeded" &&
    IntegerQ[Lookup[stage, "PartialWeight", None]] &&
    ListQ[Lookup[stage, "PartialTransportWeightGraded", None]] &&
    AssociationQ[Lookup[stage, "Budget", None]] &&
    AssociationQ[Lookup[stage, "Shift", None]] &&
    AssociationQ[Lookup[stage, "ExactDepth", None]]];

FTReport[];
