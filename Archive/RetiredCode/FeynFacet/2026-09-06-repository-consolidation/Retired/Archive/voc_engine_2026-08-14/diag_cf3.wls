#!/usr/bin/env wolframscript
(* DIAGNOSIS ONLY -- no fixes, no tuning.  Establish the root cause of the
   CF3 path-frame DE check returning False at every order. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

L[args___] := VoCLog[args];

L["=== DIAG: $Version = ", $Version, " ==="];

(* ---- H1: does ConstantArray return a structured array here, and does
        Part assignment into it silently fail? ---- *)
L["--- H1: ConstantArray / Part assignment ---"];
Module[{a, b, ok1, ok2},
 a = ConstantArray[0, 3];
 L["  Head[ConstantArray[0,3]]      = ", Head[a], "   ArrayQ ", ArrayQ[a],
   "   InputForm ", ToString[InputForm[a]]];
 b = ConstantArray[0, {3, 3}];
 L["  Head[ConstantArray[0,{3,3}]]  = ", Head[b]];
 ok1 = Quiet@Check[(a[[{2}]] = {qq}; True), False];
 L["  a[[{2}]] = {qq} succeeded: ", ok1, "   a now = ", ToString[InputForm[a]]];
 ok2 = Quiet@Check[(b[[{1}, {1}]] = {{qq}}; True), False];
 L["  b[[{1},{1}]] = {{qq}} succeeded: ", ok2];
 L["  SymbolicZerosArray present in $ContextPath test: ",
   ToString[InputForm[Head[ConstantArray[0, 3]]]]]];

(* ---- rebuild the CF3 solve exactly as the gate did ---- *)
L["--- rebuilding CF3 (numeric endpoint) ---"];
pf = VoCPrepareFamily["CF3"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
L["  assembly ", asm["Status"], "  N = ", asm["N"], "  Head[asm[\"N\"]] = ", Head[asm["N"]],
  "  Ranges = ", ToString[InputForm[asm["Ranges"]]]];
solv = VoCSolve[asm, "KMin" -> 0, "KMax" -> 3, "Target" -> {1/2, 1/5}, "Verbose" -> False];
L["  solve ", solv["Status"], "  need ", solv["Need"], "  quadPass ", solv["QuadPass"]];

(* ---- H2: is VoCFVector actually returning the F values? ---- *)
L["--- H2: VoCFVector ---"];
Do[Module[{fv},
  fv = VoCFVector[asm, solv, k];
  L["  k=", k, "  Head ", Head[fv], "  Length ", Length[fv],
    "  leaves ", LeafCount[fv],
    "  per-entry leaves ", ToString[LeafCount /@ fv],
    "  all-zero? ", TrueQ[fv === ConstantArray[0, asm["N"]]]]],
 {k, 0, 3}];
L["  for comparison, F[{s,k}] leaves: ",
  ToString[Table[{s, k, LeafCount[Lookup[solv["F"], Key[{s, k}], Missing[]]]}, {s, 3}, {k, 0, 3}]]];

(* ---- H3: is VoCTLaurent returning T? ---- *)
L["--- H3: VoCTLaurent ---"];
Module[{tl},
 tl = VoCTLaurent[asm, {0, 3}];
 L["  Length ", Length[tl], "  leaves per order ", ToString[LeafCount /@ tl]];
 L["  order-0 matrix = ", ToString[InputForm[tl[[1]]]]]];

(* ---- H4: shape of the assembled master series ---- *)
L["--- H4: VoCMasterSeries ---"];
ms = VoCMasterSeries[asm, solv, {0, 3}];
Do[L["  I[eps^", nn, "]  Head ", Head[ms["I"][[nn + 1]]], "  Length ",
   Length[ms["I"][[nn + 1]]], "  leaves ", LeafCount[ms["I"][[nn + 1]]]], {nn, 0, 3}];

(* ---- H5: what exactly is lhs-rhs in the check? ---- *)
L["--- H5: structure inside VoCCheckDEPath ---"];
Module[{b = solv["Base"], target = solv["Target"], dv, dw, sub, ahat, lau, r0, r1, lhs, rhs, d},
 dv = target[[1]] - b[[1]]; dw = target[[2]] - b[[2]];
 sub = {v -> b[[1]] + tau dv, w -> b[[2]] + tau dw};
 ahat = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahat], Infinity], 0]];
 r1 = 3 - 0;
 L["  r0 = ", r0, "  r1 = ", r1];
 lau = VoCLaurentMat[ahat, {r0, r1}];
 lhs = VoCDtau /@ ms["I"][[1]];
 rhs = Sum[If[0 <= 0 - r <= 3, lau[[r - r0 + 1]].ms["I"][[0 - r + 1]],
     ConstantArray[0, asm["N"]]], {r, r0, r1}];
 L["  lhs Head ", Head[lhs], " Length ", Length[lhs]];
 L["  rhs Head ", Head[rhs], " Length ", Length[rhs]];
 d = lhs - rhs;
 L["  (lhs-rhs) Head ", Head[d], "  Length ", Length[d]];
 L["  VoCZeroFn /@ (lhs-rhs) = ", ToString[InputForm[VoCZeroFn /@ d]]]];

L["=== DIAG DONE ==="];
