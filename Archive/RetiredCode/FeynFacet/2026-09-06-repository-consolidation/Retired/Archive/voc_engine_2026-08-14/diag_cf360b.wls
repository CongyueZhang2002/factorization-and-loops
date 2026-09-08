#!/usr/bin/env wolframscript
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 2; target = {1/2, 1/5};
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
VoCLog["need ", InputForm[solv["Need"]], "  quadPass ", solv["QuadPass"]];
ms = VoCMasterSeries[asm, solv, {0, kmaxT}];
Module[{b = solv["Base"], tgt = solv["Target"], dv, dw, sub, ahat, lau, r0, r1, lhs, rhs, res, rr},
 dv = tgt[[1]] - b[[1]]; dw = tgt[[2]] - b[[2]];
 sub = {v -> b[[1]] + tau dv, w -> b[[2]] + tau dw};
 ahat = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahat], Infinity], 0]];
 r1 = kmaxT;
 lau = VoCLaurentMat[ahat, {r0, r1}];
 lhs = VoCDtau /@ ms["I"][[1]];
 rhs = Sum[If[0 <= 0 - r <= kmaxT, lau[[r - r0 + 1]].ms["I"][[0 - r + 1]],
    ConstantArray[0, asm["N"]]], {r, r0, r1}];
 res = lhs - rhs;
 VoCLog["r0 = ", r0];
 Do[Module[{gr},
   gr = GPLResidual[res[[i]], tau];
   VoCLog["row ", i, ": zero=", VoCZeroFn[res[[i]]],
     "  nonzero words = ", If[gr === $Failed, "FAILED", Length[gr]],
     "  weights = ", If[gr === $Failed, "-", InputForm[Tally[Length /@ Keys[gr]]]]];
   If[gr =!= $Failed && Length[gr] > 0 && Length[gr] <= 3,
    Do[VoCLog["    word ", InputForm[k], "  coef ", InputForm[Together[gr[k]]]], {k, Keys[gr]}]];
   If[gr =!= $Failed && KeyExistsQ[gr, {}],
    VoCLog["    PURELY RATIONAL part (word {}) = ", InputForm[Together[gr[{}]]]]]],
  {i, asm["N"]}]];
VoCLog["=== DONE ==="];
