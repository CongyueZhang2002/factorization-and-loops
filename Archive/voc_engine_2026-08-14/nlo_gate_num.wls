#!/usr/bin/env wolframscript
(* MILESTONE GATE 1 (GPL backend, NUMERIC endpoints) -- NLO golden system.

   PRIMARY gate path per the coordinator ruling: the brief's verification is
   at chamber points, and the fixed-depth production target never needs
   symbolic-endpoint functions.  With a numeric rational endpoint the G
   indices are rational NUMBERS, so the coefficient swell that stalls the
   symbolic-endpoint solve (leaves 90 -> 1935 -> 16465 -> 50000 across eps
   orders) does not arise.  Nothing in the verification is weakened:
     * the solve is symbolic in tau with SYMBOLIC constants,
     * every quadrature is checked exactly (d/dtau F - source == 0, Together),
     * the assembled solution is checked exactly against the ORIGINAL NLO DE
       in the path frame with the constants still symbolic,
   and only then are the constants fixed at (1/4,1/4) from the exact masters
   and the answer compared with the exact masters at two other points.      *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

prec = 40; kmin = -1; kmaxT = 2;
base = VoCBasePoint;
targets = {{1/2, 1/5}, {1/10, 3/5}};

(* Honest agreement measure.  If a-b is zero to within the working precision
   of the comparison, Log10 of that approximate zero is Indeterminate; the
   truthful statement is then "agrees to at least p digits", where p is the
   precision actually carried.  Never report more than p. *)
digits[a_, b_] := Module[{p, d, rel},
  p = Min[Precision[a], Precision[b]];
  If[!TrueQ[p < Infinity], p = prec];
  If[a === b, Return[p]];
  d = Abs[a - b];
  rel = If[TrueQ[Abs[b] > 0], d/Abs[b], d];
  If[!TrueQ[rel > 0], Return[p]];
  Min[p, N[-Log10[rel], 5]]];

relDev[a_, b_] := If[TrueQ[Abs[b] > 0], Abs[(a - b)/b], Abs[a - b]];

VoCLog["=== NLO GATE, numeric endpoints (backend ", VoCBackendDefault, ") ==="];
sys = VoCNLOSystem[];
masters = sys["Masters"]; basis = sys["Basis"];

tt = AbsoluteTime[];
asm = VoCAssemble[sys, "Provider" -> "Scalar", "Verbose" -> False];
If[asm["Status"] =!= "OK",
  asm = VoCAssemble[sys, "Provider" -> "Scalar", "Verbose" -> False,
    "Blocks" -> Table[{{i}, None}, {i, Length[sys["Av"]]}]]];
VoCLog["assembly ", asm["Status"], ", certificate OK: ", VoCCertificateOK[asm],
  "  (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
VoCLog["perm = ", asm["Perm"]];
If[!VoCCertificateOK[asm], VoCLog["GATE 1 FAILED at the assembly certificate"]; Quit[1]];

exactAt[pt_, nmin_, kmax_, pr_] := Module[{cs},
  cs = Table[VoCExactSeries[masters[b]["Exact"], pt, nmin, kmax, pr], {b, basis}];
  Association[Table[k -> Table[cs[[m]]["C"][[k - nmin + 1]], {m, Length[basis]}], {k, nmin, kmax}]]];

budget = VoCDepthBudget[asm, VoCPathMatrix[asm, First[targets], base], kmaxT];
needMax = Max[budget["Need"]];
VoCLog["depth budget: ", budget["Need"]];

tt = AbsoluteTime[];
icoefBase = exactAt[base, kmin, needMax, prec + 10];
crules = VoCConstantRules[asm, icoefBase, kmin, needMax];
VoCLog["constants fixed at the base point ", InputForm[base], ": ", Length[crules],
  " constants  (", Round[AbsoluteTime[] - tt, 0.1], "s)"];

results = {}; allQuad = {}; allPath = {};
Do[Module[{pt = targets[[ip]], solv, ms, iex, iexP, ieng, dg, t0, chkPath, passPath, words},
  VoCLog["--- target point ", InputForm[pt], " ---"];
  GPLClearCache[];
  t0 = AbsoluteTime[];
  solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> pt, "Verbose" -> False];
  VoCLog["  solve ", solv["Status"], ": ", solv["NIntegrals"], " quadratures in ",
    Round[solv["TotalSeconds"], 0.01], "s  (",
    Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1], " ms each)  total ",
    Round[AbsoluteTime[] - t0, 0.1], "s"];
  If[solv["Status"] =!= "OK", VoCLog["  !! solve failed"],
   VoCLog["  per-quadrature exact check (d/dtau F == source): ", solv["QuadPass"],
     "   [", Count[Flatten[solv["QuadCheck"][[All, "Zero"]]], True], " of ",
     Length[Flatten[solv["QuadCheck"][[All, "Zero"]]]], " exact zeros]"];
   AppendTo[allQuad, <|"Point" -> pt, "Pass" -> solv["QuadPass"],
      "NZero" -> Count[Flatten[solv["QuadCheck"][[All, "Zero"]]], True],
      "NTot" -> Length[Flatten[solv["QuadCheck"][[All, "Zero"]]]]|>];
   words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
   VoCLog["  distinct G words: ", Length[words], "  max weight ",
     If[words === {}, 0, Max[Length /@ words]]];
   ms = VoCMasterSeries[asm, solv, {kmin, kmaxT}];
   (* exact DE check with the constants STILL SYMBOLIC *)
   t0 = AbsoluteTime[];
   chkPath = VoCCheckDEPath[asm, solv, ms, Range[kmin, kmaxT - 1]];
   passPath = AllTrue[chkPath, #["Zero"] === {True} &];
   VoCLog["  path-frame exact DE check (symbolic constants): ",
     InputForm[{#["Order"], #["Zero"]} & /@ chkPath], "  (",
     Round[AbsoluteTime[] - t0, 0.1], "s)  PASS=", passPath];
   AppendTo[allPath, <|"Point" -> pt, "Pass" -> passPath,
      "Orders" -> ({#["Order"], #["Zero"]} & /@ chkPath)|>];
   (* now fix the constants and compare with the exact masters *)
   iex = exactAt[pt, kmin, kmaxT, prec + 10];
   iexP = Association[Table[k -> iex[k][[asm["Perm"]]], {k, kmin, kmaxT}]];
   t0 = AbsoluteTime[];
   ieng = Table[VoCNAtVec[ms["I"][[k - kmin + 1]] /. crules, 1, prec], {k, kmin, kmaxT}];
   VoCLog["  numeric evaluation: ", Round[AbsoluteTime[] - t0, 0.1], "s"];
   If[!FreeQ[ieng, $Failed], VoCLog["  !! numeric evaluation failed"],
    dg = Table[MapThread[digits, {ieng[[k - kmin + 1]], iexP[k]}], {k, kmin, kmaxT}];
    Do[VoCLog["  eps^", k, " agreement (digits): ", InputForm[dg[[k - kmin + 1]]]],
     {k, kmin, kmaxT}];
    Do[VoCLog["    eps^", k, " max relative deviation = ",
       InputForm[N[Max[MapThread[relDev, {ieng[[k - kmin + 1]], iexP[k]}]], 3]]],
     {k, kmin, kmaxT}];
    AppendTo[results, <|"Point" -> pt, "Digits" -> dg,
       "Min" -> Min[Flatten[dg /. Infinity -> 10^6]]|>]]]],
 {ip, Length[targets]}];

VoCLog["=== NLO GATE SUMMARY ==="];
Do[VoCLog["  @ ", InputForm[r["Point"]], ": min agreement ", r["Min"], " digits"], {r, results}];
Do[VoCLog["  @ ", InputForm[q["Point"]], ": quadrature exact zeros ", q["NZero"], "/", q["NTot"]],
 {q, allQuad}];
Do[VoCLog["  @ ", InputForm[c["Point"]], ": path DE exact zeros ", c["Pass"]], {c, allPath}];
gatePass = results =!= {} && Length[results] === Length[targets] &&
   AllTrue[results, #["Min"] >= 25 &] && AllTrue[allQuad, TrueQ[#["Pass"]] &] &&
   AllTrue[allPath, TrueQ[#["Pass"]] &];
VoCLog["  GATE 1 PASS: ", gatePass];
VoCPut[<|"Results" -> results, "Quad" -> allQuad, "Path" -> allPath,
   "Certificate" -> asm["Certificate"], "Perm" -> asm["Perm"], "Pass" -> gatePass|>,
  FileNameJoin[{dir, "nlo_gate_num_results.wl"}]];
VoCLog["=== NLO GATE DONE ==="];
