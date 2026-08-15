#!/usr/bin/env wolframscript
(* PREDICTION PROBE for the KMin hypothesis, run unaltered.
   Claim: F starts below the assumed KMin (ord(T^-1) = -1 on the 2x2 block,
   deep negative couplings elsewhere).  Solving from KMin = -3 should supply
   the missing components and make the order-0 assembled check pass on ALL
   rows.  PASS criterion: {True, True, True, True}.  Same baseline as the
   failing run: master series over orders 0..2, numeric endpoint. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kminProbe = -3; kmaxT = 2; target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"];
t0 = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kminProbe, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
VoCLog["solve ", solv["Status"], "  KMin = ", kminProbe, "  need = ", InputForm[solv["Need"]],
  "  rmin(A') = ", solv["RMin"], "  quadPass ", solv["QuadPass"],
  "  warnings ", InputForm[solv["Warnings"]],
  "  (", Round[AbsoluteTime[] - t0, 0.1], "s, ", solv["NIntegrals"], " quadratures)"];

(* are the newly solved low orders actually nonzero? *)
Do[VoCLog["  F at eps^", m, " leaves per sector: ",
   InputForm[Table[LeafCount[Lookup[solv["F"], Key[{s, m}], Missing[]]], {s, 3}]]],
 {m, kminProbe, 0}];

(* same baseline as the failing run: master series over orders 0..2 *)
ms = VoCMasterSeries[asm, solv, {0, 2}];
VoCLog["master series orders 0..2 leaves ", LeafCount /@ ms["I"]];
chk = VoCCheckDEPath[asm, solv, ms, {0}];
VoCLog[">>> ORDER-0 ASSEMBLED CHECK: ", InputForm[First[chk]["Zero"]],
  "   missing shifts ", InputForm[First[chk]["MissingShifts"]]];

Module[{dv, dw, sub, ahatO, lau, r0A, lhs, rhs},
 dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
 sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
 ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0A = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahatO], Infinity], 0]];
 lau = VoCLaurentMat[ahatO, {r0A, 2}];
 lhs = VoCDtau /@ ms["I"][[1]];
 rhs = Sum[If[0 <= 0 - r <= 2, lau[[r - r0A + 1]].ms["I"][[0 - r + 1]],
    ConstantArray[0, n]], {r, r0A, 2}];
 VoCLog[">>> PER-ROW order-0 status = ", InputForm[VoCZeroFn /@ (lhs - rhs)]]];

(* does F now genuinely start at -3?  residual below the new KMin *)
Module[{ahat = solv["Ahat"], r0, r1, lau, kmaxF},
 r0 = solv["RMin"]; kmaxF = Max[solv["Need"]]; r1 = kmaxF - kminProbe;
 lau = VoCLaurentMat[ahat, {r0, r1}];
 Do[Module[{rr},
   rr = Sum[If[kminProbe <= m - p <= kmaxF, lau[[p - r0 + 1]].VoCFVector[asm, solv, m - p],
      ConstantArray[0, n]], {p, r0, r1}];
   VoCLog["  below-KMin residual at m = ", m, " : ",
     InputForm[Table[VoCZeroFn[rr[[i]]], {i, n}]]]],
  {m, kminProbe - 1, kminProbe - 2, -1}]];
VoCLog["=== KMIN PROBE DONE ==="];
