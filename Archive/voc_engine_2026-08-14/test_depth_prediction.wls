#!/usr/bin/env wolframscript
(* PREDICTION TEST, run unaltered.
   Claim: the assembled path-frame check at order n needs EVERY sector's F to
   order n + |rmin(A')|.  For CF360, rmin(A') = -3, so checking order 0 needs
   every sector at depth >= 3.  VoCDepthBudget initialises need to kmax for
   every sector, so solving with KMax = 3 forces exactly that.
   PASS criterion: order-0 assembled check gives {True} on all rows. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 3; target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"]; ranges = asm["Ranges"];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
rminAp = solv["RMin"];
VoCLog["need = ", InputForm[solv["Need"]], "   rmin(A') = ", rminAp,
  "   quadPass ", solv["QuadPass"], "   warnings ", InputForm[solv["Warnings"]]];
VoCLog[">>> DEPTH CONDITION for checking order 0: every sector depth >= ",
  0 + Abs[rminAp], "   -- actually ", InputForm[solv["Need"]],
  "   SATISFIED: ", AllTrue[solv["Need"], # >= Abs[rminAp] &]];

tr0 = VoCTOrderMin[asm]; n0 = kmin + tr0; n1 = n0 + kmaxT;
ms = VoCMasterSeries[asm, solv, {n0, n1}];
chk = VoCCheckDEPath[asm, solv, ms, {n0}];
VoCLog[">>> ORDER-0 ASSEMBLED CHECK: ", InputForm[First[chk]["Zero"]],
  "   missing shifts ", InputForm[First[chk]["MissingShifts"]]];

(* per-row detail *)
Module[{dv, dw, sub, ahatO, lau, r0A, r1A, lhs, rhs},
 dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
 sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
 ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0A = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahatO], Infinity], 0]];
 r1A = n1 - n0;
 lau = VoCLaurentMat[ahatO, {r0A, r1A}];
 VoCLog["rmin(A original) = ", r0A];
 lhs = VoCDtau /@ ms["I"][[1]];
 rhs = Sum[If[n0 <= n0 - r <= n1, lau[[r - r0A + 1]].ms["I"][[n0 - r - n0 + 1]],
    ConstantArray[0, n]], {r, r0A, r1A}];
 VoCLog["per-row order-0 status = ", InputForm[VoCZeroFn /@ (lhs - rhs)]]];

(* single cheap probe of the stated fallback suspect: is T_0 . A'_{-3} = 0 ?
   (matrix algebra on assembly data only -- no further investigation here) *)
Module[{Tfull, Tp, T0, ahatC, lauC, Am3, sub, dv, dw},
 dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
 sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
 Tfull = ConstantArray[0, {n, n}];
 Do[Tfull[[ranges[[s]], ranges[[s]]]] = asm["Forms"][[s]]["T"], {s, Length[ranges]}];
 Tp = Map[Together, Tfull /. sub, {2}];
 T0 = Map[VoCLaurent[#, {0, 0}][[1]] &, Tp, {2}];
 ahatC = Map[Together, (asm["Apv"] dv + asm["Apw"] dw) /. sub, {2}];
 lauC = VoCLaurentMat[ahatC, {rminAp, 0}];
 Am3 = lauC[[1]];
 VoCLog["probe: T_0 . A'_{", rminAp, "} == 0 ? ", VoCZeroMatQ[T0.Am3],
   "    (det T_0 zero? ", VoCZeroQ[Det[T0]], ")"]];
VoCLog["=== PREDICTION TEST DONE ==="];
