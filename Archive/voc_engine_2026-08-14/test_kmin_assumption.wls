#!/usr/bin/env wolframscript
(* The unstated assumption: that F starts at eps^KMin.
   F = T^-1 . I.  On a block where T is SINGULAR at eps=0 (det T ~ eps),
   T^-1 has a 1/eps pole, so F starts BELOW KMin even though I starts at 0.
   The engine solves only m >= KMin, so the recursion
        dF_m/dtau = Sum_p A'_p F_{m-p}
   is never imposed at m < KMin -- yet with rmin(A') < 0 its right-hand side
   is NOT zero there.  Test: is that residual nonzero, and on which rows? *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 2; target = {1/2, 1/5};
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"]; ranges = asm["Ranges"];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];

(* 1. eps order of T and of T^-1, per block *)
VoCLog["--- eps orders per block ---"];
Do[Module[{tmin, timin},
  tmin = Min[VoCEpsOrder /@ Flatten[asm["Forms"][[s]]["T"]]];
  timin = Min[VoCEpsOrder /@ Flatten[asm["Tinv"][[s]]]];
  VoCLog["  block ", s, " rows ", asm["Blocks"][[s]], " dim ", Length[ranges[[s]]],
    ": ord(T) = ", tmin, "   ord(T^-1) = ", timin,
    "   det T vanishes at eps=0: ",
    VoCZeroQ[Det[Map[VoCLaurent[#, {0, 0}][[1]] &, asm["Forms"][[s]]["T"], {2}]]]]],
 {s, Length[ranges]}];

(* 2. the recursion residual at orders BELOW kmin *)
VoCLog["--- residual of  0 = Sum_p A'_p F_{m-p}  at m < KMin ---"];
Module[{ahat = solv["Ahat"], r0, r1, lau, kmaxF},
 r0 = solv["RMin"]; kmaxF = Max[solv["Need"]]; r1 = kmaxF - kmin;
 lau = VoCLaurentMat[ahat, {r0, r1}];
 Do[Module[{rr},
   rr = Sum[If[kmin <= m - p <= kmaxF, lau[[p - r0 + 1]].VoCFVector[asm, solv, m - p],
      ConstantArray[0, n]], {p, r0, r1}];
   VoCLog["  m = ", m, " : per-row zero? ", InputForm[Table[VoCZeroFn[rr[[i]]], {i, n}]],
     "   (nonzero => F_", m, " must exist and the engine never solved it)"]],
  {m, -1, -3, -1}]];
VoCLog["=== DONE ==="];
