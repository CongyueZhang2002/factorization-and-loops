#!/usr/bin/env wolframscript
(* MILESTONE GATE 2 -- family CF3 through the class-form path.
   SCC + class forms + equivalence maps -> assembly certificate ->
   order-by-order VoC solve with SYMBOLIC constants and a SYMBOLIC
   endpoint (v,w) -> exact per-order verification of the ORIGINAL CF3
   differential equations (no numerics). *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

kmin = 0; kmaxT = 3;

VoCLog["=== CF3 GATE ==="];
pf = VoCPrepareFamily["CF3"];
VoCLog["blocks from the SCC file: ", InputForm[pf["Blocks"]]];
VoCLog["independent SCC recomputation agrees: ", pf["SCCAgrees"]];
VoCLog["Av = ", InputForm[pf["System"]["Av"]]];
VoCLog["Aw = ", InputForm[pf["System"]["Aw"]]];

tt = AbsoluteTime[];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"]];
VoCLog["assembly: ", asm["Status"], " (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
If[asm["Status"] =!= "OK", VoCLog["failures: ", InputForm[asm["Failures"]]]; Quit[1]];
VoCLog["perm = ", asm["Perm"], "  classes in SCC order = ", asm["ClassIDs"]];
Do[VoCLog["  block ", s, " rows ", asm["Blocks"][[s]], " class ", asm["ClassIDs"][[s]],
   " map ", InputForm[KeyDrop[asm["Forms"][[s]]["Map"], {"Family", "Rows"}]],
   " T = ", InputForm[asm["Forms"][[s]]["T"]]], {s, Length[asm["Blocks"]]}];
VoCLog["certificate = ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
VoCLog["certificate OK: ", VoCCertificateOK[asm]];
VoCLog["A'v = ", InputForm[asm["Apv"]]];
VoCLog["A'w = ", InputForm[asm["Apw"]]];
If[!VoCCertificateOK[asm], VoCLog["GATE 2 FAILED at the assembly certificate"]; Quit[1]];

tt = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> {v, w}, "TimeLimit" -> 300];
VoCLog["solve: ", solv["Status"], " (", Round[AbsoluteTime[] - tt, 0.1], "s)  depth ", solv["Need"],
  "  warnings ", InputForm[solv["Warnings"]]];
If[solv["Status"] =!= "OK", VoCLog["GATE 2 FAILED in the quadratures"]; Quit[1]];
Do[If[KeyExistsQ[solv["F"], {s, k}],
   VoCLog["  F[sector ", s, ", eps^", k, "] = ", InputForm[Simplify[solv["F"][{s, k}]]]]],
 {s, Length[asm["Blocks"]]}, {k, kmin, Max[solv["Need"]]}];

tr0 = VoCTOrderMin[asm];
n0 = kmin + tr0; n1 = n0 + kmaxT;
VoCLog["T starts at eps^", tr0, "; master series orders ", n0, " .. ", n1];
tt = AbsoluteTime[];
ms = VoCMasterSeries[asm, solv, {n0, n1}];
VoCLog["master series built (", Round[AbsoluteTime[] - tt, 0.1], "s), leaf counts ",
  LeafCount /@ ms["I"]];

VoCLog["--- exact per-order check of the ORIGINAL CF3 DE (tau -> 1, (v,w) frame) ---"];
chk = {};
Do[Module[{t1 = AbsoluteTime[], c},
   c = First[VoCCheckDEvw[asm, ms, {nn}]];
   AppendTo[chk, c];
   VoCLog["  order eps^", c["Order"], ":  d_v check ", InputForm[c["ZeroV"]],
     "   d_w check ", InputForm[c["ZeroW"]], "   (", Round[AbsoluteTime[] - t1, 0.1], "s)"]],
 {nn, n0, n1 - 1}];
pass = AllTrue[chk, #["ZeroV"] === {True} && #["ZeroW"] === {True} &];

VoCLog["--- same check in the path frame (d/dtau) ---"];
chk2 = {};
Do[Module[{t1 = AbsoluteTime[], c},
   c = First[VoCCheckDEPath[asm, solv, ms, {nn}]];
   AppendTo[chk2, c];
   VoCLog["  order eps^", c["Order"], ":  ", InputForm[c["Zero"]],
     "   (", Round[AbsoluteTime[] - t1, 0.1], "s)"]],
 {nn, n0, n1 - 1}];
pass2 = AllTrue[chk2, #["Zero"] === {True} &];

VoCLog["=== CF3 GATE: (v,w) check ", pass, " ; path check ", pass2, " ==="];
VoCPut[<|"Certificate" -> asm["Certificate"], "CheckVW" -> KeyDrop[#, "Residual"] & /@ chk,
   "CheckPath" -> (KeyDrop[#, "Residual"] & /@ chk2), "Pass" -> pass && pass2,
   "Perm" -> asm["Perm"], "ClassIDs" -> asm["ClassIDs"]|>,
  FileNameJoin[{dir, "cf3_gate_results.wl"}]];
VoCLog["=== CF3 GATE DONE ==="];
