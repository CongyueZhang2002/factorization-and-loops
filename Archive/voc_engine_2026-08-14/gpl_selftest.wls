#!/usr/bin/env wolframscript
(* Self-test of GPLLayer.wl:
     A. shuffle algebra
     B. numeric evaluator vs closed forms (Log, PolyLog, zeta values)
     C. the integration primitive, verified EXACTLY by differentiating back
     D. definite integrals vs high-precision NIntegrate
     E. regularised limit at 0 and the divergence assertion
   No VoCEngine, no PolyLogTools (both would clash on G / on eps).        *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "GPLLayer.wl"}]];

log[args___] := WriteString["stdout",
   "[" <> DateString["ISODateTime"] <> "] " <> StringJoin[ToString /@ {args}] <> "\n"];

pass = {}; fail = {};
check[name_, cond_] := (If[TrueQ[cond], AppendTo[pass, name], AppendTo[fail, name]];
   log[If[TrueQ[cond], "  PASS  ", "  FAIL  "], name]);
checkNum[name_, a_, b_, dig_] := Module[{d},
  d = If[a === b, Infinity,
     If[Abs[b] < 10^-30, If[Abs[a] < 10^-30, Infinity, -Log10[Abs[a]]],
      N[-Log10[Abs[(a - b)/b]], 5]]];
  If[TrueQ[d >= dig], AppendTo[pass, name], AppendTo[fail, name]];
  log[If[TrueQ[d >= dig], "  PASS  ", "  FAIL  "], name, "  (", N[d, 6], " digits)"];
  d];

log["=== GPL LAYER SELF-TEST ==="];
(* x, aa, bb, ... are plain Global` symbols here -- never assign them *)

(* ---------------- A. shuffle ---------------- *)
log["--- A. shuffle algebra ---"];
check["shuffle count w(2)xw(2) = 6", Length[GPLShuffle[{a1, a2}, {b1, b2}]] === 6];
check["shuffle count w(1)xw(3) = 4", Length[GPLShuffle[{a1}, {b1, b2, b3}]] === 4];
check["shuffle G[{a}]G[{b}] = G[{a,b}]+G[{b,a}]",
  Together[GPLShuffleNormal[G[{aa}, x] G[{bb}, x]] - (G[{aa, bb}, x] + G[{bb, aa}, x])] === 0];
check["shuffle G[{a}]^2 = 2 G[{a,a}]",
  Together[GPLShuffleNormal[G[{aa}, x]^2] - 2 G[{aa, aa}, x]] === 0];
check["G[{},x] collapses to 1", G[{}, x] === 1];

(* ---------------- B. numerics ---------------- *)
log["--- B. numeric evaluator ---"];
prec = 35;
xv = 1/2;
checkNum["G[{0},1/2] = Log[1/2]", GPLNValue[{0}, xv, "Precision" -> prec], N[Log[xv], prec], 30];
checkNum["G[{1},1/2] = Log[1-1/2]", GPLNValue[{1}, xv, "Precision" -> prec], N[Log[1 - xv], prec], 30];
checkNum["G[{-1},1/2] = Log[1+1/2]", GPLNValue[{-1}, xv, "Precision" -> prec], N[Log[1 + xv], prec], 30];
checkNum["G[{3},1/2] = Log[1-1/6]", GPLNValue[{3}, xv, "Precision" -> prec], N[Log[1 - xv/3], prec], 30];
checkNum["G[{0,1},1/2] = -Li2[1/2]", GPLNValue[{0, 1}, xv, "Precision" -> prec],
   N[-PolyLog[2, xv], prec], 30];
checkNum["G[{0,-1},1/2] = -Li2[-1/2]", GPLNValue[{0, -1}, xv, "Precision" -> prec],
   N[-PolyLog[2, -xv], prec], 30];
checkNum["G[{0,2},1/2] = -Li2[1/4]", GPLNValue[{0, 2}, xv, "Precision" -> prec],
   N[-PolyLog[2, xv/2], prec], 30];
checkNum["G[{0,0,1},1/2] = -Li3[1/2]", GPLNValue[{0, 0, 1}, xv, "Precision" -> prec],
   N[-PolyLog[3, xv], prec], 30];
checkNum["G[{0,0,0,1},1/2] = -Li4[1/2]", GPLNValue[{0, 0, 0, 1}, xv, "Precision" -> prec],
   N[-PolyLog[4, xv], prec], 30];
checkNum["G[{0,1},1] = -Pi^2/6", GPLNValue[{0, 1}, 1, "Precision" -> prec], N[-Pi^2/6, prec], 30];
checkNum["G[{0,0,1},1] = -Zeta[3]", GPLNValue[{0, 0, 1}, 1, "Precision" -> prec], N[-Zeta[3], prec], 30];
checkNum["G[{0,0,0,1},1] = -Pi^4/90", GPLNValue[{0, 0, 0, 1}, 1, "Precision" -> prec],
   N[-Pi^4/90, prec], 30];
checkNum["G[{1,0},1/2] = Log[x]Log[1-x]+Li2[x]", GPLNValue[{1, 0}, xv, "Precision" -> prec],
   N[Log[xv] Log[1 - xv] + PolyLog[2, xv], prec], 30];
(* weight 4 at an index close to the segment (stress) *)
checkNum["G[{-1/50,1},1] vs NIntegrate", GPLNValue[{-1/50, 1}, 1, "Precision" -> prec],
   NIntegrate[Log[1 - s]/(s + 1/50), {s, 0, 1}, WorkingPrecision -> 45,
     MaxRecursion -> 30], 25];

(* shuffle identity numerically at weight 2+2 *)
Module[{u = {2, -3}, ww = {5, -1/2}, lhs, rhs},
 lhs = GPLNValue[u, 1, "Precision" -> prec] GPLNValue[ww, 1, "Precision" -> prec];
 rhs = Total[GPLNValue[#, 1, "Precision" -> prec] & /@ GPLShuffle[u, ww]];
 checkNum["numeric shuffle w2 x w2 at x=1", lhs, rhs, 28]];

(* ---------------- C. integration: differentiate back ---------------- *)
log["--- C. integration primitive (exact check: d/dx primitive == integrand) ---"];
SeedRandom[20260814];
testIntegrands = {
  1/(x - 2) G[{3}, x],
  1/(x + 1) G[{2, -1}, x],
  x^3 G[{2}, x],
  (1 + x)/(x - 5) G[{1/2, 3}, x],
  1/(x - 2)^2 G[{3}, x],
  1/(x - 2)^3 G[{3, -1}, x],
  (x^2 + 1)/((x - 2)^2 (x + 3)) G[{5, 1/2, -2}, x],
  1/((x - 2) (x + 3)) G[{5, 1/2, -2, 7}, x],
  x^2/(x - 1/3)^2 G[{2, 2}, x],
  (3 x^4 - 1)/((x - 2)^3 (x + 5)^2) G[{-3, 4}, x],
  1/(x - aa) G[{bb, cc}, x],
  (x + pp)/((x - aa)^2 (x - bb)) G[{cc, dd, aa}, x]};
Do[Module[{ig = testIntegrands[[i]], prim, back, t0, dt},
  t0 = AbsoluteTime[];
  prim = GPLPrimitive[ig, x];
  dt = AbsoluteTime[] - t0;
  If[prim === $Failed,
   check["primitive #" <> ToString[i] <> " computed", False],
   back = GPLDeriv[prim, x] - ig;
   check["d/dx primitive #" <> ToString[i] <> " == integrand  (" <>
      ToString[Round[1000 dt, 0.1]] <> " ms)", GPLZeroQ[back, x]]]],
 {i, Length[testIntegrands]}];

(* ---------------- D. definite integrals vs NIntegrate ---------------- *)
log["--- D. definite integral 0->1 vs NIntegrate ---"];
Module[{cases, di},
 (* every reference integrand is in closed form so NIntegrate can evaluate it *)
 cases = {
   {1/(x - 2) G[{3}, x], Log[1 - s/3]/(s - 2)},
   {1/(x + 1) G[{2}, x], Log[1 - s/2]/(s + 1)},
   {x^2 G[{-1}, x], s^2 Log[1 + s]},
   {1/(x - 2)^2 G[{3}, x], Log[1 - s/3]/(s - 2)^2},
   {1/(x - 3) G[{0, 2}, x], -PolyLog[2, s/2]/(s - 3)},
   {x/(x - 3)^2 G[{0, -1}, x], -s PolyLog[2, -s]/(s - 3)^2},
   (* index 3 (not 1): with an index AT the endpoint the individual terms of
      the primitive diverge there even though their sum is finite, and the
      term-by-term numeric evaluator refuses the job by design *)
   {(x^2 + 1)/((x - 2) (x + 4)) G[{0, 0, 3}, x],
      -(s^2 + 1) PolyLog[3, s/3]/((s - 2) (s + 4))}};
 Do[Module[{ig = cases[[k, 1]], ref = cases[[k, 2]], val, nv},
   di = GPLDefInt[ig, x];
   If[di === $Failed, check["definite integral #" <> ToString[k], False],
    val = GPLNumeric[di, x, 1, 30];
    nv = NIntegrate[Evaluate[ref], {s, 0, 1}, WorkingPrecision -> 40, MaxRecursion -> 30];
    checkNum["definite integral #" <> ToString[k] <> " vs NIntegrate", val, nv, 22]]],
  {k, Length[cases]}]];

(* ---------------- E. limit at 0 / divergence assertion ---------------- *)
log["--- E. regularised limit at 0 ---"];
check["limit0 of G[{2},x] is 0", GPLLimit0[G[{2}, x], x] === 0];
check["limit0 of G[{2,3},x] is 0", GPLLimit0[G[{2, 3}, x], x] === 0];
check["limit0 of 5 + G[{2},x] is 5", Together[GPLLimit0[5 + G[{2}, x], x] - 5] === 0];
check["limit0 of G[{0},x] is flagged divergent (Log)", GPLLimit0[G[{0}, x], x] === $Failed];
check["limit0 of G[{0},x]-G[{0},x] is 0", GPLLimit0[G[{0}, x] - G[{0}, x], x] === 0];
(* log divergences that cancel must be accepted: G[{0,2},x] + shuffle piece *)
Module[{e},
 (* G[{0},x]G[{2},x] = G[{0,2},x]+G[{2,0},x]; each of the two has a finite
    limit 0, and the product does too -- a genuine cancellation test is a
    1/x pole against a G vanishing linearly: *)
 e = G[{2}, x]/x;
 check["1/x * G[{2},x] has finite limit -1/2",
   Together[GPLLimit0[e, x] + 1/2] === 0]];
(* G[{2,3},x] = x^2/12 + O(x^3): /x^2 is finite, /x^3 is a genuine pole *)
check["1/x^2 * G[{2,3},x] has finite limit 1/12",
  Together[GPLLimit0[G[{2, 3}, x]/x^2, x] - 1/12] === 0];
check["1/x^3 * G[{2,3},x] is flagged divergent",
  GPLLimit0[G[{2, 3}, x]/x^3, x] === $Failed];

(* GPLDefInt of an integrand whose primitive is log-divergent at 0 must fail
   loudly rather than drop the divergence *)
check["divergent quadrature is rejected", GPLDefInt[G[{2}, x]/x^2, x] === $Failed];

(* an index sitting ON the integration segment, or a leading index at the
   endpoint, must be refused by the numeric evaluator rather than guessed *)
check["index inside the segment is refused", GPLNValue[{1/2}, 1, "Precision" -> 20] === $Failed];
check["leading index at the endpoint is refused",
  GPLNValue[{1, 0}, 1, "Precision" -> 20] === $Failed];
check["interior index at the endpoint goes through Hoelder",
  NumericQ[GPLNValue[{0, 1}, 1, "Precision" -> 20]]];

log["=== SELF-TEST SUMMARY: ", Length[pass], " passed, ", Length[fail], " failed ==="];
If[fail =!= {}, log["FAILED: ", InputForm[fail]]];
log["GPL assertion log: ", Length[GPLFailures], " entries (expected: the deliberate ones above)"];
log["cache sizes: ", InputForm[GPLCacheSizes[]]];
log["=== DONE ==="];
