#!/usr/bin/env wolframscript
(* MILESTONE GATE 1 -- NLO golden system.
   Full engine pipeline: SCC -> inline singleton canonicalisation ->
   assembly + conjugation certificate -> order-by-order VoC solve with
   symbolic constants -> constants fixed from the exact masters at the
   base point -> comparison against the exact masters at two other
   chamber points, orders eps^-1..eps^2. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

prec = 50; kmin = -1; kmaxT = 2;
base = VoCBasePoint;
targets = {{1/2, 1/5}, {1/10, 3/5}};

digits[a_, b_] := Which[
   a === b, Infinity,
   b == 0, If[a == 0, Infinity, N[-Log10[Abs[a]], 5]],
   True, N[-Log10[Abs[(a - b)/b]], 5]];

VoCLog["=== NLO GATE ==="];
sys = VoCNLOSystem[];
masters = sys["Masters"]; basis = sys["Basis"];
VoCLog["masters in the DE basis: ", Length[basis]];

sccNLO = VoCSCCBlocks[sys["Av"], sys["Aw"]];
VoCLog["engine-computed SCC blocks: ", InputForm[sccNLO]];
tt = AbsoluteTime[];
asm = VoCAssemble[sys, "Provider" -> "Scalar"];
If[asm["Status"] =!= "OK",
  VoCLog["first assembly returned ", asm["Status"], " -- retrying with explicit singleton blocks"];
  asm = VoCAssemble[sys, "Provider" -> "Scalar",
    "Blocks" -> Table[{{i}, None}, {i, Length[sys["Av"]]}]]];
VoCLog["assembly status ", asm["Status"], "  (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
VoCLog["perm = ", asm["Perm"], "   blocks = ", asm["Blocks"]];
VoCLog["certificate = ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
VoCLog["certificate OK: ", VoCCertificateOK[asm]];
VoCLog["T (diagonal, per block) = ", InputForm[Flatten[Table[asm["Forms"][[s]]["T"], {s, Length[asm["Blocks"]]}]]]];
VoCLog["A'v = ", InputForm[asm["Apv"]]];
VoCLog["A'w = ", InputForm[asm["Apw"]]];
If[!VoCCertificateOK[asm], VoCLog["GATE 1 FAILED at the assembly certificate"]; Quit[1]];

(* --- exact masters, eps-series at a point, ORIGINAL basis order --- *)
exactAt[pt_, nmin_, kmax_, pr_] := Module[{cs},
  cs = Table[VoCExactSeries[masters[b]["Exact"], pt, nmin, kmax, pr], {b, basis}];
  Association[Table[k -> Table[cs[[m]]["C"][[k - nmin + 1]], {m, Length[basis]}], {k, nmin, kmax}]]];

(* depth budget (needs only the path matrix) *)
ahat = VoCPathMatrix[asm, First[targets], base];
budget = VoCDepthBudget[asm, ahat, kmaxT];
needMax = Max[budget["Need"]];
VoCLog["depth budget: ", budget["Need"], "  rmin matrix min = ",
  Min[Append[DeleteCases[Flatten[budget["RMin"]], Infinity], 0]]];

(* sanity: nothing below eps^kmin in the exact masters *)
Module[{low = exactAt[base, -3, 0, 25]},
  VoCLog["exact masters at the base point, orders below eps^", kmin, ": ",
   InputForm[N[{low[-3], low[-2]}, 12]], "  (must be zero)"]];

tt = AbsoluteTime[];
icoefBase = exactAt[base, kmin, needMax, prec];
VoCLog["exact masters at the base point ", base, " (", Round[AbsoluteTime[] - tt, 0.1], "s):"];
Do[VoCLog["   eps^", k, ": ", InputForm[N[icoefBase[k], 20]]], {k, kmin, kmaxT}];

crules = VoCConstantRules[asm, icoefBase, kmin, needMax];
VoCLog["integration constants fixed at the base point (", Length[crules], " constants)"];
Do[VoCLog["   ", InputForm[crules[[i]][[1]]], " = ", InputForm[N[crules[[i]][[2]], 20]]],
 {i, Min[Length[crules], 14]}];

(* --- the gate proper --- *)
results = {};
Do[
 Module[{pt = targets[[ip]], solv, ms, ieng, iex, iexP, t0, dg, solvN, msN, iengN, dgN},
  VoCLog["--- target point ", pt, " ---"];
  iex = exactAt[pt, kmin, kmaxT, prec];
  iexP = Association[Table[k -> iex[k][[asm["Perm"]]], {k, kmin, kmaxT}]];
  (* fast independent route first, so gate numbers exist even if the
     symbolic quadratures run long *)
  t0 = AbsoluteTime[];
  solvN = VoCSolveODE[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> pt,
     "Precision" -> 45, "Init" -> Association[crules]];
  VoCLog["  NDSolve route: ", solvN["Status"], "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
  If[solvN["Status"] === "OK",
   msN = VoCMasterSeriesFrom[asm, solvN["F"], kmin, Max[solvN["Need"]], {kmin, kmaxT}, pt];
   iengN = msN["I"];
   dgN = Table[MapThread[digits, {iengN[[k - kmin + 1]], iexP[k]}], {k, kmin, kmaxT}];
   Do[VoCLog["  eps^", k, " NDSolve agreement (digits): ", InputForm[dgN[[k - kmin + 1]]]],
    {k, kmin, kmaxT}];
   AppendTo[results, <|"Point" -> pt, "Route" -> "ndsolve", "Digits" -> dgN,
      "Min" -> Min[Flatten[dgN /. Infinity -> 10^6]]|>]];
  t0 = AbsoluteTime[];
  solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> pt, "TimeLimit" -> 150];
  VoCLog["  symbolic VoC solve: ", solv["Status"], "  (", Round[AbsoluteTime[] - t0, 0.1], "s)",
    If[solv["Warnings"] =!= {}, "  WARNINGS " <> ToString[solv["Warnings"]], ""]];
  If[solv["Status"] === "OK",
   ms = VoCMasterSeries[asm, solv, {kmin, kmaxT}];
   ieng = Table[N[(ms["I"][[k - kmin + 1]] /. tau -> 1) /. crules, prec], {k, kmin, kmaxT}];
   dg = Table[MapThread[digits, {ieng[[k - kmin + 1]], iexP[k]}], {k, kmin, kmaxT}];
   Do[VoCLog["  eps^", k, " agreement (digits, permuted basis): ",
      InputForm[dg[[k - kmin + 1]]]], {k, kmin, kmaxT}];
   Do[VoCLog["    eps^", k, " engine: ", InputForm[N[ieng[[k - kmin + 1]], 18]]], {k, kmin, kmaxT}];
   Do[VoCLog["    eps^", k, " exact : ", InputForm[N[iexP[k], 18]]], {k, kmin, kmaxT}];
   AppendTo[results, <|"Point" -> pt, "Route" -> "symbolic", "Digits" -> dg,
      "Min" -> Min[Flatten[dg /. Infinity -> 10^6]]|>],
   VoCLog["  symbolic route unavailable"]]],
 {ip, Length[targets]}];

VoCLog["=== NLO GATE SUMMARY ==="];
Do[VoCLog["  ", r["Route"], " @ ", r["Point"], ": min agreement ", r["Min"], " digits"], {r, results}];
VoCPut[<|"Results" -> results, "Certificate" -> asm["Certificate"], "Perm" -> asm["Perm"]|>,
  FileNameJoin[{dir, "nlo_gate_results.wl"}]];
VoCLog["=== NLO GATE DONE ==="];
