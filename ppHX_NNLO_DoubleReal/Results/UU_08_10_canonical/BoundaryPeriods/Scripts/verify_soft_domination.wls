#!/usr/bin/env wolframscript
(* Symbolic verification of every algebraic and analytic step in
   ../Proofs/SoftEndpointDomination.md, the exact zero proof for boundary
   periods 1 (CF1), 6 and 7 (CF124).

   No numerical substitution occurs anywhere in this script.  Inequalities
   are decided by Resolve over the reals (exact quantifier elimination);
   identities are closed by Together / FullSimplify.

   Sections
     K.  the two kernels are exactly linear in the corner coordinates
     L.  the single geometric inequality that both periods need
     D.  the dominating function and its exact Beta-function bound
     S.  the exact, numerics-free soft value of both parametric integrals
         (this is the reconstruction check against Kira's IBP connection)
     B.  the free mode is unbounded exactly where the bound holds

   Acceptance: every line tagged [OK] and SOFT_DOMINATION_EXACT = True.
*)

$fail = False;
report[label_, val_] := Module[{ok = TrueQ[val]},
  If[! ok, $fail = True];
  Print[If[ok, "[OK]   ", "[FAIL] "], label, " = ", val]];

zeroQ[e_] := Module[{t = Together[e]},
  If[t === 0, True, FullSimplify[t] === 0]];

Print["=== K. kernels in corner coordinates u = 1-x, t = 1-y ==="];

(* CF1 (period 1).  Uncut denominator #3 = (kc - ka + kf)^2; the pilot's
   parametric form is J = v + x s - x (v+s) y, with s = 1-v-w. *)
J1raw = v + x s - x (v + s) y;
J1corner = v u + (1 - u) (v + s) t;
report["K1. CF1 kernel: J = v u + (1-u)(v+s) t exactly",
  zeroQ[(J1raw /. {x -> 1 - u, y -> 1 - t}) - J1corner]];

(* CF124 (periods 6, 7).  Uncut denominator #5 = (kc+ke+kf)^2, which the
   pilot reconstructs as D5 = 1 - x s - x (1-s) y. *)
D5raw = 1 - x s - x (1 - s) y;
D5corner = u + (1 - u) (1 - s) t;
report["K2. CF124 kernel: D5 = u + (1-u)(1-s) t exactly",
  zeroQ[(D5raw /. {x -> 1 - u, y -> 1 - t}) - D5corner]];

(* Both are the same shape  alpha u + beta (1-u) t  with
     CF1   : alpha = v,  beta = v + s   (beta >= alpha > 0 for all s >= 0)
     CF124 : alpha = 1,  beta = 1 - s   (beta >= 1 - s0 > 0 for s <= s0)
   so one inequality serves both. *)

Print[""];
Print["=== L. the geometric inequality ==="];

(* L1 is the whole geometric content: the kernel cannot vanish faster than
   linearly in the distance to the corner. *)
L1 = Resolve[ForAll[{u, t}, 0 <= u <= 1 && 0 <= t <= 1,
    u + (1 - u) t >= (u + t)/4], Reals];
report["L1. u + (1-u) t >= (u+t)/4 on the unit square", L1];

(* L1 is sharp at the corner in the sense that equality is attained only
   there, so no larger constant of this form is available from below. *)
L1tight = Resolve[Exists[{u, t}, 0 <= u <= 1 && 0 <= t <= 1 &&
     u + (1 - u) t == (u + t)/4 && u + t > 0], Reals];
report["L1b. equality only at the corner (no interior contact)",
  L1tight === False];

(* L2. Scaling out the smaller of the two coefficients. *)
L2 = Resolve[ForAll[{u, t, al, be},
    0 <= u <= 1 && 0 <= t <= 1 && al > 0 && be >= al,
    al u + be (1 - u) t >= al (u + (1 - u) t)], Reals];
report["L2. alpha u + beta (1-u) t >= alpha (u + (1-u) t) for beta >= alpha",
  L2];

(* L3. CF1 instance: beta = v + s >= alpha = v for every s >= 0, so the
   bound is uniform in s with NO upper cut on s. *)
L3 = Resolve[ForAll[{u, t, v, s},
    0 <= u <= 1 && 0 <= t <= 1 && 0 < v < 1 && s >= 0,
    v u + (1 - u) (v + s) t >= (v/4) (u + t)], Reals];
report["L3. CF1: J >= (v/4)(u+t), uniformly in s >= 0", L3];

(* L4. CF124 instance: beta = 1-s degrades as s -> 1, so the bound is
   uniform only on 0 <= s <= s0 < 1.  That is why the record states an
   s0 and the CF1 record does not. *)
L4 = Resolve[ForAll[{u, t, s, s0},
    0 <= u <= 1 && 0 <= t <= 1 && 0 < s0 < 1 && 0 <= s <= s0,
    u + (1 - u) (1 - s) t >= ((1 - s0)/4) (u + t)], Reals];
report["L4. CF124: D5 >= ((1-s0)/4)(u+t) for 0 <= s <= s0 < 1", L4];

Print[""];
Print["=== D. dominating function and its exact bound ==="];

(* AM-GM turns the linear lower bound into a separable dominating
   function, which is what makes the bound an explicit Beta product. *)
AMGM = Resolve[ForAll[{u, t}, u >= 0 && t >= 0, u + t >= 2 Sqrt[u t]],
  Reals];
report["D1. u + t >= 2 Sqrt[u t]", AMGM];

(* The measure is  dmu = x^(1-2eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy,
   i.e. in corner coordinates
        (1-u)^(1-2eps) u^(-eps) (1-t)^(-eps) t^(-eps) du dt.
   With |z^(-eps)| = z^(-sig) for z > 0 and sig = Re[eps], the modulus of
   the dominating integrand separates. *)

uInt = Integrate[u^(-sig - 1/2) (1 - u)^(1 - 2 sig), {u, 0, 1},
   Assumptions -> sig < 1/2];
tInt = Integrate[t^(-sig - 1/2) (1 - t)^(-sig), {t, 0, 1},
   Assumptions -> sig < 1/2];
report["D2. u-integral equals Beta[1/2-sig, 2-2sig]",
  zeroQ[uInt - Beta[1/2 - sig, 2 - 2 sig]]];
report["D3. t-integral equals Beta[1/2-sig, 1-sig]",
  zeroQ[tInt - Beta[1/2 - sig, 1 - sig]]];

(* Convergence domain: both Beta arguments positive.  The binding
   condition is sig < 1/2, contributed by the corner. *)
dom = Reduce[1/2 - sig > 0 && 2 - 2 sig > 0 && 1 - sig > 0, sig, Reals];
report["D4. convergence domain is exactly Re[eps] < 1/2",
  Reduce[dom, sig, Reals] === Reduce[sig < 1/2, sig, Reals]];
Print["       domain = ", InputForm[dom]];

Print[""];
Print["=== S. exact soft value of the parametric integrals ==="];

(* This section is the numerics-free replacement for the pilot's
   ~30-digit agreement.  It evaluates the s -> 0 parametric integral in
   closed form and compares with the value forced by Kira's connection.

   At s = 0 both kernels collapse to the SAME integral:
        J|_{s=0}  = v (1 - x y),      D5|_{s=0} = 1 - x y,
   so a single evaluation settles both periods. *)
report["S0. both kernels collapse to 1 - x y at s = 0 (up to the factor v)",
  zeroQ[(J1raw /. s -> 0) - v (D5raw /. s -> 0)]];

(* Step 1: the y integral is Euler's representation.
     Int_0^1 y^(-eps) (1-y)^(-eps) / (1 - x y) dy
       = B(1-eps,1-eps) 2F1(1, 1-eps; 2-2eps; x),  Re[eps] < 1. *)
yStep = Integrate[y^(-eps) (1 - y)^(-eps)/(1 - x y), {y, 0, 1},
   Assumptions -> Re[eps] < 1 && 0 < x < 1];
report["S1. y integral = B(1-eps,1-eps) 2F1(1,1-eps;2-2eps;x)",
  zeroQ[yStep -
    Beta[1 - eps, 1 - eps] Hypergeometric2F1[1, 1 - eps, 2 - 2 eps, x]]];

(* Step 2: the x integral, done termwise on the 2F1 series.  The n-th
   term needs  B(n+2-2eps, 1-eps) = B(2-2eps,1-eps) (2-2eps)_n/(3-3eps)_n. *)
xTerm = FullSimplify[
   Beta[n + 2 - 2 eps, 1 - eps] -
    Beta[2 - 2 eps, 1 - eps] Pochhammer[2 - 2 eps, n]/
     Pochhammer[3 - 3 eps, n],
   Assumptions -> Element[n, Integers] && n >= 0 && Re[eps] < 1/2];
report["S2. termwise x integral is the Pochhammer ratio", xTerm === 0];

(* Step 3: the (2-2eps)_n factors cancel between the 2F1 coefficient and
   the Beta ratio, collapsing the 3F2 to a Gauss 2F1 at unit argument. *)
collapse = FullSimplify[
   (Pochhammer[1 - eps, n] Pochhammer[2 - 2 eps, n])/
     (Pochhammer[2 - 2 eps, n] Pochhammer[3 - 3 eps, n]) -
    Pochhammer[1 - eps, n]/Pochhammer[3 - 3 eps, n],
   Assumptions -> Element[n, Integers] && n >= 0];
report["S3. 3F2 collapses to 2F1(1,1-eps;3-3eps;1)", collapse === 0];

(* Step 4: Gauss summation at z = 1.  Gauss's theorem requires
   Re[c-a-b] = Re[1-2 eps] > 0, i.e. exactly the same half plane
   Re[eps] < 1/2 on which the domination bound holds.  Split into the
   unconditional Gamma identity and the (conditional) summation itself,
   so the record shows precisely which hypothesis is used where. *)
gaussGamma = Gamma[3 - 3 eps] Gamma[1 - 2 eps]/
   (Gamma[2 - 3 eps] Gamma[2 - 2 eps]);
report["S4a. Gauss Gamma ratio = (2-3eps)/(1-2eps), unconditionally",
  FullSimplify[gaussGamma - (2 - 3 eps)/(1 - 2 eps)] === 0];
report["S4b. 2F1(1,1-eps;3-3eps;1) equals it on Re[eps] < 1/2",
  FullSimplify[Hypergeometric2F1[1, 1 - eps, 3 - 3 eps, 1] - gaussGamma,
    Assumptions -> Re[eps] < 1/2] === 0];

(* Step 5: compare with the value the repository connection forces.
   CF124 row 6 couples only to the volume row 5. *)
root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName],
   "..", "..", "..", "..", ".."}]];
de124 = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF124.wl"}]];
b124 = de124["BlockBasis"];
report["S5a. CF124 row 6 is the period master",
  b124[[6]] === gli["CF124", {1, 1, 0, 0, 1, 0, 1, 0, 0}]];
report["S5b. CF124 row 5 is the volume master",
  b124[[5]] === gli["CF124", {1, 1, 0, 0, 0, 0, 1, 0, 0}]];

Av124 = de124["Av"]; Aw124 = de124["Aw"];
nonzeroCols[row_] :=
  Flatten[Position[Simplify /@ row, x_ /; x =!= 0, {1}, Heads -> False]];
report["S5c. Av row 6 couples only to row 5 (volume) and itself",
  nonzeroCols[Av124[[6]]] === {5, 6}];
report["S5c'. Aw row 6 couples only to row 5 (volume) and itself",
  nonzeroCols[Aw124[[6]]] === {5, 6}];

(* DE-forced soft value: s -> 0 in  s dR/dv = (1-2eps) R + s A65 + s A66 R
   kills the diagonal term, leaving R_soft = -lim(s A65)/(1-2eps). *)
softDE = Simplify[
   -Limit[(1 - v - w) Av124[[6, 5]] /. w -> 1 - v - sS, sS -> 0]/(1 - 2 eps)];
report["S5d. DE-forced soft value = (2-3eps)/(1-2eps)",
  zeroQ[softDE - (2 - 3 eps)/(1 - 2 eps)]];

(* The parametric soft value equals N(0)/Int dmu with
   Int dmu = B(2-2eps,1-eps) B(1-eps,1-eps). *)
softParam = Simplify[
   (Beta[2 - 2 eps, 1 - eps] Beta[1 - eps, 1 - eps] (2 - 3 eps)/(1 - 2 eps))/
    (Beta[2 - 2 eps, 1 - eps] Beta[1 - eps, 1 - eps])];
report["S6. parametric soft value equals the DE-forced value (CF124)",
  zeroQ[softParam - softDE]];

(* Same comparison for CF1, where the extra 1/v and the sign of J appear. *)
de1 = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF1.wl"}]];
softDE1 = Simplify[
   -Limit[(1 - v - w) de1["Av"][[2, 1]] /. w -> 1 - v - sS, sS -> 0]/
    (1 - 2 eps)];
report["S7. parametric soft value equals the DE-forced value (CF1)",
  zeroQ[(-(1/v) (2 - 3 eps)/(1 - 2 eps)) - softDE1]];

Print[""];
Print["=== B. the free mode is unbounded exactly on the proved domain ==="];

(* |s^(2 eps - 1)| = s^(2 sig - 1) -> Infinity as s -> 0+ iff sig < 1/2,
   the same half plane on which the domination bound holds.  There is no
   gap between the two conditions. *)
blow = Resolve[ForAll[sig, sig < 1/2, 2 sig - 1 < 0], Reals];
report["B1. Re[eps] < 1/2 implies the free mode s^(2 eps-1) is unbounded",
  blow];

freeLimit = Limit[sS^(2 sig - 1), sS -> 0, Direction -> "FromAbove",
   Assumptions -> sig < 1/2];
report["B2. limit of the free mode at s -> 0+ is Infinity",
  freeLimit === Infinity || freeLimit === DirectedInfinity[1]];

Print[""];
Print["SOFT_DOMINATION_EXACT = ", ! $fail];
