#!/usr/bin/env wolframscript
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 2; target = {1/2, 1/5};
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
ahat = solv["Ahat"];   (* conjugated A' restricted to the path, permuted basis *)
r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahat], Infinity], 0]];
kmaxF = Max[solv["Need"]];
r1 = kmaxF - kmin;
lau = VoCLaurentMat[ahat, {r0, r1}];
VoCLog["A' rmin = ", r0, "   need = ", InputForm[solv["Need"]], "  kmaxF = ", kmaxF];
(* FULL conjugated check: dF/dtau - sum_r A'_r . F_{n-r} == 0, all blocks *)
Do[Module[{fn, lhs, rhs, res, avail},
  fn[m_] := VoCFVector[asm, solv, m];
  avail[m_] := AllTrue[Range[Length[asm["Ranges"]]], KeyExistsQ[solv["F"], {#, m}] &];
  lhs = VoCDtau /@ fn[nn];
  rhs = Sum[If[kmin <= nn - r <= kmaxF, lau[[r - r0 + 1]].fn[nn - r],
     ConstantArray[0, asm["N"]]], {r, r0, r1}];
  res = VoCZeroFn /@ (lhs - rhs);
  VoCLog["order eps^", nn, ": full A' check per row = ", InputForm[res],
    "   (all F orders <= ", nn - r0, " available: ",
    AllTrue[Range[nn, nn - r0], avail], ")"]],
 {nn, kmin, 1}];
VoCLog["=== DONE ==="];
