#!/usr/bin/env wolframscript
(* Which ROWS of the CF360 assembled check fail, and why.
   Leading hypothesis: VoCSolve silently skips a source term F[{j,m}] whose
   order m exceeds the depth budget need[[j]] (it records a "missing"
   warning).  The per-quadrature check would still pass -- it verifies F
   against the rhs that was ACTUALLY built -- so only the assembled check
   can see it.  Diagnosis only; no fixes here. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

kmin = 0; kmaxT = 3; target = {1/2, 1/5};

pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
VoCLog["blocks (permuted order) = ", InputForm[asm["Blocks"]],
  "   ranges = ", InputForm[asm["Ranges"]], "   perm = ", InputForm[asm["Perm"]]];
VoCLog["classes = ", InputForm[asm["ClassIDs"]]];

solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
VoCLog["solve ", solv["Status"], "  need = ", InputForm[solv["Need"]],
  "  quadPass ", solv["QuadPass"]];
VoCLog[">>> WARNINGS (missing source terms) = ", InputForm[solv["Warnings"]]];
VoCLog["    (each {\"missing\", s, kk, j, m} means: building sector s at eps^kk",
  " needed F[sector j, eps^m] and it was not solved)"];

(* which F orders exist *)
VoCLog["available F orders per sector: ",
  InputForm[Table[{s, Sort[Cases[Keys[solv["F"]], {s, m_} :> m]]}, {s, Length[asm["Blocks"]]}]]];

tr0 = VoCTOrderMin[asm]; n0 = kmin + tr0; n1 = n0 + kmaxT;
ms = VoCMasterSeries[asm, solv, {n0, n1}];

(* per-ROW status, not DeleteDuplicates *)
Module[{b = solv["Base"], tgt = solv["Target"], dv, dw, sub, ahat, lau, r0, r1, o0, o1},
 dv = tgt[[1]] - b[[1]]; dw = tgt[[2]] - b[[2]];
 sub = {v -> b[[1]] + tau dv, w -> b[[2]] + tau dw};
 ahat = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 o0 = n0; o1 = n1;
 r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahat], Infinity], 0]];
 r1 = o1 - o0;
 lau = VoCLaurentMat[ahat, {r0, r1}];
 VoCLog["r0 (global rmin) = ", r0, "  r1 = ", r1];
 Do[Module[{lhs, rhs, res},
   lhs = VoCDtau /@ ms["I"][[nn - o0 + 1]];
   rhs = Sum[If[o0 <= nn - r <= o1, lau[[r - r0 + 1]].ms["I"][[nn - r - o0 + 1]],
      ConstantArray[0, asm["N"]]], {r, r0, r1}];
   res = VoCZeroFn /@ (lhs - rhs);
   VoCLog["order eps^", nn, " per-row zero status = ", InputForm[res]];
   Do[If[res[[i]] =!= True,
     VoCLog["   row ", i, " (original master ", asm["Perm"][[i]],
       ", block ", SelectFirst[Range[Length[asm["Ranges"]]], MemberQ[asm["Ranges"][[#]], i] &],
       ") residual leaves ", LeafCount[(lhs - rhs)[[i]]]]], {i, asm["N"]}]],
  {nn, n0, n1 - 2}]];

VoCLog["=== DIAG CF360 DONE ==="];
