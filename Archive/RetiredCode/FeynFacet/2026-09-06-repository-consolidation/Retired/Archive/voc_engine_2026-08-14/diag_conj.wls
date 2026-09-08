#!/usr/bin/env wolframscript
(* Does the conjugation identity hold ON THE PATH, entrywise, with no order
   bookkeeping anywhere?   Ahat . T  ==  T . A'hat + dT/dtau
   If yes, the assembly defect is pure order bookkeeping.
   If it fails on the 2x2 block's rows/columns, the block form is at fault. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"]; ranges = asm["Ranges"];
VoCLog["ranges = ", InputForm[ranges], "  perm = ", InputForm[asm["Perm"]]];

(* full block-diagonal T in the permuted basis, NOT eps-expanded *)
Tfull = ConstantArray[0, {n, n}];
Do[Tfull[[ranges[[s]], ranges[[s]]]] = asm["Forms"][[s]]["T"], {s, Length[ranges]}];
VoCLog["Head[Tfull] ", Head[Tfull], " dims ", Dimensions[Tfull]];

(* Tinv . T == identity ? *)
Tinvfull = ConstantArray[0, {n, n}];
Do[Tinvfull[[ranges[[s]], ranges[[s]]]] = asm["Tinv"][[s]], {s, Length[ranges]}];
VoCLog["Tinv.T - Id all zero: ",
  InputForm[Map[VoCZeroQ, Tinvfull.Tfull - IdentityMatrix[n], {2}]]];

dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
ahatC = Map[Together, (asm["Apv"] dv + asm["Apw"] dw) /. sub, {2}];
Tp = Map[Together, Tfull /. sub, {2}];
dTp = Map[Together, D[Tp, tau], {2}];

resid = Map[Together, ahatO.Tp - (Tp.ahatC + dTp), {2}];
VoCLog["conjugation identity residual, entrywise zero?"];
Do[VoCLog["  row ", i, ": ", InputForm[Table[VoCZeroQ[resid[[i, j]]], {j, n}]]], {i, n}];
VoCLog["ALL ZERO: ", VoCZeroMatQ[resid]];

(* same test in the (v,w) frame, to see if it is a path/tau artefact *)
residV = Map[Together, asm["Av"].Tfull - (Tfull.asm["Apv"] + VoCDMat[Tfull, v]), {2}];
residW = Map[Together, asm["Aw"].Tfull - (Tfull.asm["Apw"] + VoCDMat[Tfull, w]), {2}];
VoCLog["(v,w)-frame: Av identity all zero ", VoCZeroMatQ[residV],
  " ; Aw identity all zero ", VoCZeroMatQ[residW]];
Do[VoCLog["  Av row ", i, ": ", InputForm[Table[VoCZeroQ[residV[[i, j]]], {j, n}]]], {i, n}];
VoCLog["=== DONE ==="];
