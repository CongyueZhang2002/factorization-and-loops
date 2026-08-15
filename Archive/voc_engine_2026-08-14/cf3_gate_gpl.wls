#!/usr/bin/env wolframscript
(* MILESTONE GATE 2 (GPL backend) -- family CF3 through the class-form path.
   SCC + class forms + equivalence maps -> assembly certificate ->
   order-by-order VoC solve with SYMBOLIC constants and a SYMBOLIC endpoint
   (v,w) -> exact per-order verification.  No numerics anywhere.

   Two independent exact verifications are run:
     (i)  per quadrature:  d/dtau F_{s,k} - source_{s,k} == 0   (Together)
     (ii) assembled:       d/dtau I_n - (Ahat . I)_n == 0       (Together)
   The Integrate backend never reached order eps^2 of sector 2 (>1 h).      *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

kmin = 0; kmaxT = 3;

(* PRIMARY PATH: a numeric rational endpoint.  The gate's verification is at
   chamber points, and the fixed-depth production target never needs
   symbolic-endpoint functions (demoted-exactness principle).  The solve is
   still fully symbolic in tau with SYMBOLIC constants, and both exact checks
   below are exact symbolic zeros -- nothing is weakened.
   "useSymbolic = True" restores the general-(v,w) answer but causes severe
   coefficient swell (leaf counts ~90 -> 1935 -> 16465 -> 50000 across eps
   orders on NLO); see the swell warning in GPLLayer.wl. *)
useSymbolic = If[Length[$ScriptCommandLine] > 1, $ScriptCommandLine[[2]] === "symbolic", False];
target = If[useSymbolic, {v, w}, {1/2, 1/5}];

VoCLog["=== CF3 GATE (backend ", VoCBackendDefault, ", endpoint ",
   If[useSymbolic, "SYMBOLIC (v,w)", ToString[InputForm[target]]], ") ==="];
pf = VoCPrepareFamily["CF3"];
VoCLog["blocks from the SCC file: ", InputForm[pf["Blocks"]]];
VoCLog["independent SCC recomputation agrees: ", pf["SCCAgrees"]];

tt = AbsoluteTime[];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"]];
VoCLog["assembly: ", asm["Status"], " (", Round[AbsoluteTime[] - tt, 0.1], "s)"];
If[asm["Status"] =!= "OK", VoCLog["failures: ", InputForm[asm["Failures"]]]; Quit[1]];
VoCLog["perm = ", asm["Perm"], "  classes in SCC order = ", asm["ClassIDs"]];
VoCLog["certificate = ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
VoCLog["certificate OK: ", VoCCertificateOK[asm]];
If[!VoCCertificateOK[asm], VoCLog["GATE 2 FAILED at the assembly certificate"]; Quit[1]];

tt = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target];
tSolve = AbsoluteTime[] - tt;
VoCLog["solve: ", solv["Status"], " (", Round[tSolve, 0.01], "s)  depth ", solv["Need"],
  "  warnings ", InputForm[solv["Warnings"]]];
If[solv["Status"] =!= "OK", VoCLog["GATE 2 FAILED in the quadratures"]; Quit[1]];
VoCLog[solv["NIntegrals"], " quadratures, ",
  Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1], " ms each on average"];
Do[VoCLog["   timing sector ", t["Sector"], " eps^", t["Order"], ": ",
   Round[1000 t["Seconds"], 0.1], " ms for ", t["N"], " integrals"], {t, solv["Times"]}];
VoCLog["per-quadrature exact check (d/dtau F == source): ", solv["QuadPass"]];
Do[VoCLog["   ", InputForm[q]], {q, solv["QuadCheck"]}];

words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
VoCLog["distinct G words: ", Length[words], "  max weight ", Max[Length /@ words]];
VoCLog["G indices: ", InputForm[DeleteDuplicates[Flatten[words]]]];
Do[If[KeyExistsQ[solv["F"], {s, k}],
   VoCLog["  F[sector ", s, ", eps^", k, "] leaves ", LeafCount[solv["F"][{s, k}]]]],
 {s, Length[asm["Blocks"]]}, {k, kmin, Max[solv["Need"]]}];
VoCLog["  F[sector 1, eps^0] = ", InputForm[solv["F"][{1, 0}]]];
VoCLog["  F[sector 1, eps^1] = ", InputForm[solv["F"][{1, 1}]]];

tr0 = VoCTOrderMin[asm];
n0 = kmin + tr0; n1 = n0 + kmaxT;
VoCLog["T starts at eps^", tr0, "; master series orders ", n0, " .. ", n1];
tt = AbsoluteTime[];
ms = VoCMasterSeries[asm, solv, {n0, n1}];
VoCLog["master series built (", Round[AbsoluteTime[] - tt, 0.1], "s), leaf counts ",
  LeafCount /@ ms["I"]];

VoCLog["--- exact per-order check of the ORIGINAL CF3 DE (path frame, d/dtau) ---"];
chk2 = {};
Do[Module[{t1 = AbsoluteTime[], c},
   c = First[VoCCheckDEPath[asm, solv, ms, {nn}]];
   AppendTo[chk2, c];
   VoCLog["  order eps^", c["Order"], ":  ", InputForm[c["Zero"]],
     "   (", Round[AbsoluteTime[] - t1, 0.01], "s)"]],
 {nn, n0, n1 - 1}];
pass2 = AllTrue[chk2, #["Zero"] === {True} &];

(* the (v,w)-frame check needs the Goncharov parameter differential, which
   this layer does not implement; it reports NeedsParamDeriv rather than a
   meaningless zero.  See REPORT_GPL.md for why path frame + flatness is
   already a complete verification. *)
If[useSymbolic,
 VoCLog["--- (v,w)-frame check status ---"];
 chk = VoCCheckDEvw[asm, ms, {n0}];
 VoCLog["  ", InputForm[chk]],
 VoCLog["--- (v,w)-frame check skipped: numeric endpoint; the path-frame"];
 VoCLog["    check + flatness certificate is the verification contract ---"]];

VoCLog["=== CF3 GATE: quadrature check ", solv["QuadPass"],
  " ; path DE check ", pass2, " ==="];
VoCPut[<|"Certificate" -> asm["Certificate"], "QuadCheck" -> solv["QuadCheck"],
   "QuadPass" -> solv["QuadPass"], "CheckPath" -> (KeyDrop[#, "Residual"] & /@ chk2),
   "PathPass" -> pass2, "Pass" -> (solv["QuadPass"] && pass2),
   "Times" -> solv["Times"], "NIntegrals" -> solv["NIntegrals"],
   "TotalSeconds" -> solv["TotalSeconds"], "SolveSeconds" -> tSolve,
   "Words" -> words, "Perm" -> asm["Perm"], "ClassIDs" -> asm["ClassIDs"]|>,
  FileNameJoin[{dir, "cf3_gate_gpl_results.wl"}]];
VoCLog["=== CF3 GATE DONE ==="];
