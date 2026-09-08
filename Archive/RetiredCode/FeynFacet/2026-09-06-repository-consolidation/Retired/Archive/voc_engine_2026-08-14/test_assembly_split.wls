#!/usr/bin/env wolframscript
(* BINARY SPLIT: is the engine's assembled I_n literally  Sum_r T_r . F_{n-r} ?
   (A) T_r : engine (expand in eps, THEN substitute path) vs direct
             (substitute path, THEN expand in eps)          -- candidate 3
   (B) I_n : engine's VoCMasterSeries vs a direct product   -- candidates 1 & 2
   The order-0 assembled check consumes I_0, I_1 AND I_2, so all three are
   compared.  Diagnosis only; no fixes. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 2; target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"]; ranges = asm["Ranges"];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
VoCLog["need = ", InputForm[solv["Need"]], "  quadPass ", solv["QuadPass"]];

tr0 = VoCTOrderMin[asm]; n1 = kmin + tr0 + kmaxT; tr1 = n1 - solv["KMin"];
kmaxF = Max[solv["Need"]];
VoCLog["tr0 = ", tr0, "  tr1 = ", tr1, "  kmaxF = ", kmaxF, "  n0..n1 = ", kmin + tr0, "..", n1];

dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};

(* engine's T Laurent: expand first, then substitute *)
tlEng = Map[Together, VoCTLaurent[asm, {tr0, tr1}] /. sub, {3}];
(* direct: substitute first, then expand *)
Tfull = ConstantArray[0, {n, n}];
Do[Tfull[[ranges[[s]], ranges[[s]]]] = asm["Forms"][[s]]["T"], {s, Length[ranges]}];
Tpath = Map[Together, Tfull /. sub, {2}];
tlDir = Table[Map[VoCLaurent[#, {tr0, tr1}][[r - tr0 + 1]] &, Tpath, {2}], {r, tr0, tr1}];
VoCLog["--- (A) T_r engine vs direct ---"];
Do[VoCLog["  r = ", r, "  identical: ",
   VoCZeroMatQ[tlEng[[r - tr0 + 1]] - tlDir[[r - tr0 + 1]]]], {r, tr0, tr1}];

(* (B) I_n engine vs direct product *)
ms = VoCMasterSeries[asm, solv, {kmin + tr0, n1}];
VoCLog["--- (B) I_n engine vs direct Sum_r T_r . F_{n-r} ---"];
Do[Module[{iEng, iDir, diff},
  iEng = ms["I"][[nn - (kmin + tr0) + 1]];
  iDir = Sum[If[nn - r >= kmin, tlDir[[r - tr0 + 1]].VoCFVector[asm, solv, nn - r],
     ConstantArray[0, n]], {r, tr0, tr1}];
  diff = iEng - iDir;
  VoCLog["  n = ", nn, "  per-row identical: ",
    InputForm[Table[VoCZeroFn[diff[[i]]], {i, n}]]]],
 {nn, kmin + tr0, n1}];

(* what the engine's guard actually admits, per (n,r) *)
VoCLog["--- guard audit: engine admits (n,r) pairs with kmin <= n-r <= kmaxF ---"];
Do[VoCLog["  n = ", nn, "  r admitted = ",
   InputForm[Select[Range[tr0, tr1], kmin <= nn - # <= kmaxF &]],
   "   r with F-order >= 0 = ", InputForm[Select[Range[tr0, tr1], nn - # >= kmin &]]],
 {nn, kmin + tr0, n1}];
VoCLog["=== SPLIT TEST DONE ==="];
