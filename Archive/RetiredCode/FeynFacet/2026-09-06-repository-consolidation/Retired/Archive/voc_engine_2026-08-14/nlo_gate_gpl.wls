#!/usr/bin/env wolframscript
(* MILESTONE GATE 1 (GPL backend) -- NLO golden system.

   Differences from nlo_gate.wls (Integrate backend, which died at
   sector 2 / eps^1 after 619 s):
     * ONE solve with a SYMBOLIC endpoint (v,w) and SYMBOLIC constants,
       giving the general chamber answer, instead of one solve per point;
     * every quadrature is verified exactly on the spot
       (d/dtau F - source == 0 by Together);
     * the assembled solution is checked against the ORIGINAL NLO DE in the
       path frame, exactly, with the constants still symbolic;
     * the constants are then fixed at (1/4,1/4) from the exact masters and
       the answer is compared with the exact masters at two other points.  *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

prec = 50; kmin = -1; kmaxT = 2;
base = VoCBasePoint;
targets = {{1/2, 1/5}, {1/10, 3/5}};

digits[a_, b_] := Which[
   a === b, Infinity,
   b == 0, If[a == 0, Infinity, N[-Log10[Abs[a]], 5]],
   True, N[-Log10[Abs[(a - b)/b]], 5]];

VoCLog["=== NLO GATE (backend ", VoCBackendDefault, ") ==="];
sys = VoCNLOSystem[];
masters = sys["Masters"]; basis = sys["Basis"];
VoCLog["masters in the DE basis: ", Length[basis]];

tt = AbsoluteTime[];
asm = VoCAssemble[sys, "Provider" -> "Scalar"];
If[asm["Status"] =!= "OK",
  VoCLog["first assembly returned ", asm["Status"], " -- retrying with explicit singleton blocks"];
  asm = VoCAssemble[sys, "Provider" -> "Scalar",
    "Blocks" -> Table[{{i}, None}, {i, Length[sys["Av"]]}]]];
VoCLog["assembly status ", asm["Status"], "  (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
VoCLog["perm = ", asm["Perm"], "   blocks = ", asm["Blocks"]];
VoCLog["certificate OK: ", VoCCertificateOK[asm]];
If[!VoCCertificateOK[asm], VoCLog["GATE 1 FAILED at the assembly certificate"]; Quit[1]];

exactAt[pt_, nmin_, kmax_, pr_] := Module[{cs},
  cs = Table[VoCExactSeries[masters[b]["Exact"], pt, nmin, kmax, pr], {b, basis}];
  Association[Table[k -> Table[cs[[m]]["C"][[k - nmin + 1]], {m, Length[basis]}], {k, nmin, kmax}]]];

ahat = VoCPathMatrix[asm, {v, w}, base];
budget = VoCDepthBudget[asm, ahat, kmaxT];
needMax = Max[budget["Need"]];
VoCLog["depth budget: ", budget["Need"]];

(* ---------- the symbolic solve, general endpoint (v,w) ---------- *)
VoCLog["--- symbolic solve, endpoint (v,w), constants symbolic ---"];
tt = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> {v, w}];
tSolve = AbsoluteTime[] - tt;
VoCLog["solve: ", solv["Status"], "  (", Round[tSolve, 0.01], "s, ", solv["NIntegrals"],
  " quadratures, ", Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1],
  " ms per quadrature)"];
VoCLog["per-quadrature exact check (d/dtau F == source): ", solv["QuadPass"]];
If[solv["Status"] =!= "OK", VoCLog["GATE 1 FAILED in the quadratures"]; Quit[1]];
Do[VoCLog["   ", InputForm[q]], {q, solv["QuadCheck"]}];
VoCLog["letters on the segment: ", solv["LetterCheck"]["Status"],
  "  (", Length[solv["LetterCheck"]["Letters"]], " letters)"];
Do[VoCLog["   timing sector ", t["Sector"], " eps^", t["Order"], ": ",
   Round[1000 t["Seconds"], 0.1], " ms for ", t["N"], " integrals"], {t, solv["Times"]}];

(* the G-alphabet actually produced *)
words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
VoCLog["distinct G words: ", Length[words], "  max weight ", Max[Length /@ words]];
idxs = DeleteDuplicates[Flatten[words]];
VoCLog["G indices (letters of the alphabet): ", InputForm[idxs]];

ms = VoCMasterSeries[asm, solv, {kmin, kmaxT}];
VoCLog["master series built, leaf counts ", LeafCount /@ ms["I"]];

(* ---------- exact per-order DE check, path frame, symbolic constants ---------- *)
VoCLog["--- exact per-order check of the ORIGINAL NLO DE (path frame, d/dtau) ---"];
chkPath = {};
Do[Module[{t1 = AbsoluteTime[], c},
   c = First[VoCCheckDEPath[asm, solv, ms, {nn}]];
   AppendTo[chkPath, c];
   VoCLog["  order eps^", nn, ": ", InputForm[c["Zero"]],
     "   (", Round[AbsoluteTime[] - t1, 0.01], "s)"]],
 {nn, kmin, kmaxT - 1}];
passPath = AllTrue[chkPath, #["Zero"] === {True} &];
VoCLog["path-frame DE check (all orders exact zeros): ", passPath];

(* ---------- constants from the exact masters at the base point ---------- *)
tt = AbsoluteTime[];
icoefBase = exactAt[base, kmin, needMax, prec];
VoCLog["exact masters at the base point ", base, " (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
crules = VoCConstantRules[asm, icoefBase, kmin, needMax];
VoCLog["integration constants fixed at the base point (", Length[crules], " constants)"];

(* ---------- the gate proper: two other chamber points ---------- *)
results = {};
Do[Module[{pt = targets[[ip]], iex, iexP, ieng, dg, t0},
  VoCLog["--- target point ", InputForm[pt], " ---"];
  iex = exactAt[pt, kmin, kmaxT, prec];
  iexP = Association[Table[k -> iex[k][[asm["Perm"]]], {k, kmin, kmaxT}]];
  t0 = AbsoluteTime[];
  ieng = Table[
    VoCNAtVec[((ms["I"][[k - kmin + 1]] /. crules) /. {v -> pt[[1]], w -> pt[[2]]}), 1, prec],
    {k, kmin, kmaxT}];
  VoCLog["  numeric evaluation of the symbolic answer: ", Round[AbsoluteTime[] - t0, 0.01], "s"];
  If[!FreeQ[ieng, $Failed], VoCLog["  !! numeric evaluation failed"],
   dg = Table[MapThread[digits, {ieng[[k - kmin + 1]], iexP[k]}], {k, kmin, kmaxT}];
   Do[VoCLog["  eps^", k, " agreement (digits, permuted basis): ",
      InputForm[dg[[k - kmin + 1]]]], {k, kmin, kmaxT}];
   Do[VoCLog["    eps^", k, " engine: ", InputForm[N[ieng[[k - kmin + 1]], 18]]], {k, kmin, kmaxT}];
   Do[VoCLog["    eps^", k, " exact : ", InputForm[N[iexP[k], 18]]], {k, kmin, kmaxT}];
   AppendTo[results, <|"Point" -> pt, "Route" -> "gpl-symbolic", "Digits" -> dg,
      "Min" -> Min[Flatten[dg /. Infinity -> 10^6]]|>]];
  (* independent cross-check: solve again with THIS point as a numeric
     endpoint (G indices are then rational numbers, a different code path) *)
  Module[{solvN, msN, iengN, dgN},
   t0 = AbsoluteTime[];
   solvN = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> pt, "Verbose" -> False];
   VoCLog["  numeric-endpoint solve: ", solvN["Status"], "  (",
     Round[AbsoluteTime[] - t0, 0.01], "s, ", solvN["NIntegrals"], " quadratures, ",
     Round[1000 solvN["TotalSeconds"]/Max[solvN["NIntegrals"], 1], 0.1], " ms each)",
     "  quad check ", solvN["QuadPass"]];
   If[solvN["Status"] === "OK",
    msN = VoCMasterSeries[asm, solvN, {kmin, kmaxT}];
    iengN = Table[VoCNAtVec[msN["I"][[k - kmin + 1]] /. crules, 1, prec], {k, kmin, kmaxT}];
    If[FreeQ[iengN, $Failed],
     dgN = Table[MapThread[digits, {iengN[[k - kmin + 1]], iexP[k]}], {k, kmin, kmaxT}];
     Do[VoCLog["  eps^", k, " numeric-endpoint agreement: ",
        InputForm[dgN[[k - kmin + 1]]]], {k, kmin, kmaxT}];
     AppendTo[results, <|"Point" -> pt, "Route" -> "gpl-numeric-endpoint", "Digits" -> dgN,
        "Min" -> Min[Flatten[dgN /. Infinity -> 10^6]]|>],
     VoCLog["  !! numeric-endpoint evaluation failed"]]]]],
 {ip, Length[targets]}];

VoCLog["=== NLO GATE SUMMARY ==="];
Do[VoCLog["  ", r["Route"], " @ ", InputForm[r["Point"]], ": min agreement ", r["Min"], " digits"],
 {r, results}];
VoCLog["  quadrature check: ", solv["QuadPass"], " ; path DE check: ", passPath];
gatePass = solv["QuadPass"] && passPath && results =!= {} &&
   AllTrue[results, #["Min"] >= 25 &];
VoCLog["  GATE 1 PASS: ", gatePass];
VoCPut[<|"Results" -> results, "Certificate" -> asm["Certificate"], "Perm" -> asm["Perm"],
   "QuadCheck" -> solv["QuadCheck"], "QuadPass" -> solv["QuadPass"],
   "PathDE" -> (KeyDrop[#, "Residual"] & /@ chkPath), "PathDEPass" -> passPath,
   "Times" -> solv["Times"], "NIntegrals" -> solv["NIntegrals"],
   "TotalSeconds" -> solv["TotalSeconds"], "SolveSeconds" -> tSolve,
   "Words" -> words, "Pass" -> gatePass|>,
  FileNameJoin[{dir, "nlo_gate_gpl_results.wl"}]];
VoCLog["=== NLO GATE DONE ==="];
