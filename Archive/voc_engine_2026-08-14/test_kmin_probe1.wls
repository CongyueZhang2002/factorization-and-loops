#!/usr/bin/env wolframscript
(* PREDICTION PROBE at the DESIGN value KMin = -1 = n0 + ord(T^-1) on the 2x2
   block (0 elsewhere).  Three assertions:
     (i)   F_{-1} is genuinely nonzero (the components the engine never solved)
     (ii)  I_{-1} VANISHES  -- the ker(T_0) assumption, now asserted, so a
           negative verdict cannot be a master-series range artefact
     (iii) order-0 assembled check == {True,True,True,True}   <-- PASS criterion
   Master series is built FROM -1 so the check consumes I_{-1} rather than
   silently excluding it. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kminProbe = -1; kmaxT = 2; target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"];
Do[VoCLog["block ", s, " rows ", asm["Blocks"][[s]], "  ord(T^-1) = ",
   Min[VoCEpsOrder /@ Flatten[asm["Tinv"][[s]]]]], {s, Length[asm["Ranges"]]}];
t0 = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kminProbe, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
VoCLog["solve ", solv["Status"], "  KMin = ", kminProbe, "  need = ", InputForm[solv["Need"]],
  "  rmin(A') = ", solv["RMin"], "  quadPass ", solv["QuadPass"],
  "  warnings ", InputForm[solv["Warnings"]], "  (", Round[AbsoluteTime[] - t0, 0.1], "s, ",
  solv["NIntegrals"], " quadratures)"];

VoCLog[">>> (i) F at eps^-1, leaves per sector: ",
  InputForm[Table[LeafCount[Lookup[solv["F"], Key[{s, -1}], Missing[]]], {s, 3}]]];

ms = VoCMasterSeries[asm, solv, {-1, 2}];
VoCLog["master series orders -1..2 leaves ", LeafCount /@ ms["I"]];
VoCLog[">>> (ii) I_{-1} vanishes per row: ",
  InputForm[Table[VoCZeroFn[ms["I"][[1]][[i]]], {i, n}]]];

chk = VoCCheckDEPath[asm, solv, ms, {0}];
VoCLog[">>> (iii) ORDER-0 ASSEMBLED CHECK: ", InputForm[First[chk]["Zero"]],
  "   missing shifts ", InputForm[First[chk]["MissingShifts"]]];
Module[{dv, dw, sub, ahatO, lau, r0A, lhs, rhs},
 dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
 sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
 ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0A = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahatO], Infinity], 0]];
 lau = VoCLaurentMat[ahatO, {r0A, 3}];
 lhs = VoCDtau /@ ms["I"][[2]];
 rhs = Sum[If[-1 <= 0 - r <= 2, lau[[r - r0A + 1]].ms["I"][[0 - r + 2]],
    ConstantArray[0, n]], {r, r0A, 3}];
 VoCLog[">>> PER-ROW order-0 status = ", InputForm[VoCZeroFn /@ (lhs - rhs)]]];
VoCLog["=== KMIN=-1 PROBE DONE ==="];
