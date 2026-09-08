#!/usr/bin/env wolframscript
(* MISSING-CONSTRAINT TEST.
   The general solution family has I_{-1} != 0; the PHYSICAL one must start at
   its true Laurent valuation.  Impose I_{-1} == 0 identically in tau as linear
   constraints on the free constants, restrict to that subfamily, and re-run
   the order-0 assembled check.
   PASS: order-0 residual vanishes on ALL rows for the constrained subfamily. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kminP = -1; kmaxT = 2; target = {1/2, 1/5}; base = VoCBasePoint;
cache = FileNameJoin[{dir, "cf360_solve_kmin1.wl"}];
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
n = asm["N"];
If[FileExistsQ[cache],
  solv = Get[cache]; VoCLog["solve loaded from cache"],
  solv = VoCSolve[asm, "KMin" -> kminP, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
  VoCPut[solv, cache]; VoCLog["solve computed and cached"]];
VoCLog["solve ", solv["Status"], "  need ", InputForm[solv["Need"]], "  quadPass ", solv["QuadPass"]];

ms = VoCMasterSeries[asm, solv, {-1, 2}];
Im1 = ms["I"][[1]];
VoCLog["I_{-1} per-row zero (unconstrained): ", InputForm[Table[VoCZeroFn[Im1[[i]]], {i, n}]]];

(* linear constraints: every word-coefficient of I_{-1} must vanish identically in tau *)
eqsFrom[expr_] := Module[{c = GPLCollect[expr, tau], eqs = {}},
  If[c === $Failed, Return[$Failed]];
  Do[Module[{coef = Together[Lookup[c, Key[k]]], num},
    num = Numerator[coef];
    eqs = Join[eqs, DeleteCases[CoefficientList[Expand[num], tau], 0]]], {k, Keys[c]}];
  eqs];
eqs = DeleteDuplicates[Flatten[Table[eqsFrom[Im1[[i]]], {i, n}]]];
csts = DeleteDuplicates[Cases[ms["I"], _cst, {0, Infinity}]];
VoCLog["free constants: ", Length[csts], "   linear equations from I_{-1}==0: ", Length[eqs]];
sol = Quiet[Solve[Thread[eqs == 0], csts]];
If[Head[sol] =!= List || sol === {},
  VoCLog[">>> I_{-1} == 0 has NO solution -- constraint set inconsistent"]; Quit[1]];
rules = First[sol];
VoCLog["constraints solved: ", Length[rules], " constants fixed; remaining free: ",
  Length[csts] - Length[rules]];
VoCLog["  rules (first few): ", InputForm[Take[rules, UpTo[6]]]];

msC = <|"Orders" -> ms["Orders"], "I" -> (ms["I"] /. rules)|>;
VoCLog[">>> I_{-1} per-row zero (constrained): ",
  InputForm[Table[VoCZeroFn[msC["I"][[1]][[i]]], {i, n}]]];

Module[{dv, dw, sub, ahatO, lau, r0A, lhs, rhs},
 dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
 sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
 ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
 r0A = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahatO], Infinity], 0]];
 lau = VoCLaurentMat[ahatO, {r0A, 3}];
 Do[Module[{lhsv, rhsv},
   lhsv = VoCDtau /@ msC["I"][[nn + 2]];
   rhsv = Sum[If[-1 <= nn - r <= 2, lau[[r - r0A + 1]].msC["I"][[nn - r + 2]],
      ConstantArray[0, n]], {r, r0A, 3}];
   VoCLog[">>> CONSTRAINED order eps^", nn, " per-row = ",
     InputForm[VoCZeroFn /@ (lhsv - rhsv)]]], {nn, 0, 1}]];
VoCLog["=== VALUATION TEST DONE ==="];
