#!/usr/bin/env wolframscript
(* Exact symbolic certificate for boundary period 1 (family CF1).

   Proves, with no numerical substitution anywhere in the chain:

   P1. (contiguous relation, general parameters)  For f(z) = 2F1(a,1;c;z),
           z (1-z) f'(z) - (a z - (c-1)) f(z) - (c-1) = 0.
       Proved from the exact Pochhammer coefficient recursion, symbolically
       in a, c and in the summation index n.  This replaces the 25-digit
       numeric spot check used by Tests/Reconstruction/t_nlo_masters.wls criterion B.

   P2. (differential-equation identity)  With the CF1 connection read from
       the repository artifact
         ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/
           DifferentialEquations/nnlo_de_CF1.wl
       the vector
           I = { V , R V },      V = volc (1-v-w)^(1-2 eps),
           R = -(2-3 eps)/(v (1-2 eps)) 2F1(1-eps,1;2-2 eps;-(1-v-w)/v)
       satisfies  dI - A.I = 0  in both v and w, as a literal zero after
       Together.  Equivalently dR - A R - S = 0 in reduced scalar form.
       This replaces the recorded 1.25e-9 five-point-stencil residual.

   P3. (soft value)  lim_{s->0} R = -(2-3 eps)/(v (1-2 eps)) exactly, the
       value forced by the differential equation.

   P4. (branch content of the closed form)  R is analytic in s = 1-v-w at
       s = 0, i.e. its coefficient of the free mode v^(-eps) s^(2 eps-1) is
       zero.  P4 records what the closed form contains; it does NOT prove
       that the closed form is the period.  That step is the endpoint
       domination argument in ../Proofs/SoftEndpointDomination.md, verified
       by ./verify_soft_domination.wls.

   Acceptance: every line below tagged [OK] and the final line reads
   PERIOD01_EXACT_DE = True.
*)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName],
   "..", "..", "..", "..", ".."}]];

(* ---------- reporting helpers ---------- *)

$fail = False;
report[label_, val_] := Module[{ok = TrueQ[val]},
  If[! ok, $fail = True];
  Print[If[ok, "[OK]   ", "[FAIL] "], label, " = ", val]];

(* Try increasingly strong normalizers; report which one closed the
   residual, so the certificate records the actual proof strength. *)
zeroQ[expr_, label_] := Module[{t},
  t = Together[expr];
  If[t === 0, Print["[OK]   ", label, ": Together -> 0"]; Return[True]];
  t = Simplify[t];
  If[t === 0, Print["[OK]   ", label, ": Simplify -> 0"]; Return[True]];
  t = FullSimplify[t];
  If[t === 0, Print["[OK]   ", label, ": FullSimplify -> 0"]; Return[True]];
  $fail = True;
  Print["[FAIL] ", label, ": residual = ", InputForm[t]];
  False];

(* ================================================================== *)
(* P1.  Contiguous relation for 2F1(a,1;c;z), proved symbolically.     *)
(* ================================================================== *)

(* Coefficients of 2F1(a,1;c;z) = Sum_n g[n] z^n, since (1)_n/n! = 1. *)
Clear[gcoef];
gcoef[n_] := Pochhammer[a, n]/Pochhammer[c, n];

(* Exact coefficient recursion (c+n-1) g[n] = (a+n-1) g[n-1]. *)
recResidual = FullSimplify[
   (n + c - 1) gcoef[n] - (a + n - 1) gcoef[n - 1],
   Assumptions -> Element[n, Integers] && n >= 1];
report["P1a. Pochhammer recursion residual is 0", recResidual === 0];

(* The recursion is exactly the statement that the coefficient of z^n in
   z(1-z) f' - (a z - (c-1)) f - (c-1) vanishes:
     coefficient of z^n, n >= 1 :  (n + c - 1) g[n] - (a + n - 1) g[n-1]
     coefficient of z^0         :  (c-1) g[0] - (c-1) = 0  since g[0] = 1.
   Both are now literal zeros. *)
report["P1b. g[0] = 1 (constant term closes)", Simplify[gcoef[0] - 1] === 0];

(* Independent corroboration of P1 on the specialised parameters used
   below, by series expansion.  This is corroboration, not the proof. *)
p1Series = Module[{aa = 1 - eps, cc = 2 - 2 eps, f, ser},
   f = Hypergeometric2F1[aa, 1, cc, z];
   ser = Series[
     z (1 - z) D[f, z] - (aa z - (cc - 1)) f - (cc - 1), {z, 0, 25}];
   Union[Together /@ CoefficientList[Normal[ser], z]]];
report["P1c. series corroboration to order 25 (all coefficients 0)",
  p1Series === {0} || p1Series === {}];

(* ================================================================== *)
(* P2.  The differential-equation identity, from the repository DE.    *)
(* ================================================================== *)

deFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF1.wl"}];
report["P2a. repository DE artifact exists", FileExistsQ[deFile]];
de = Get[deFile];

report["P2b. artifact is the CF1 block", de["Family"] === "CF1"];
report["P2c. block basis is {volume, period}",
  de["BlockBasis"] === {gli["CF1", {1, 1, 0, 0, 1, 0, 0, 0, 0}],
                        gli["CF1", {1, 1, 1, 0, 1, 0, 0, 0, 0}]}];

Av = de["Av"]; Aw = de["Aw"];
Print["       Av = ", InputForm[Av]];
Print["       Aw = ", InputForm[Aw]];

(* Inert head for the hypergeometric, and the P1 relation as a rewrite. *)
aa = 1 - eps; cc = 2 - 2 eps;
contiguous = HoldPattern[Derivative[1][ff][q_]] :>
  ((aa q - (cc - 1)) ff[q] + (cc - 1))/(q (1 - q));

zarg = (v + w - 1)/v;                       (* = -(1-v-w)/v = -s/v *)
Rclosed = -(2 - 3 eps)/(v (1 - 2 eps)) ff[zarg];
Vol = volc (1 - v - w)^(1 - 2 eps);
Ivec = {Vol, Rclosed Vol};

resV = (D[Ivec, v] /. contiguous) - Av . Ivec;
resW = (D[Ivec, w] /. contiguous) - Aw . Ivec;

(* Divide out the overall volume so the residual is rational in
   v, w, eps and the inert ff. *)
resVn = Cancel[resV/Vol];
resWn = Cancel[resW/Vol];

report["P2d. dI - Av.I = 0, volume row", zeroQ[resVn[[1]], "P2d"]];
report["P2e. dI - Av.I = 0, period row", zeroQ[resVn[[2]], "P2e"]];
report["P2f. dI - Aw.I = 0, volume row", zeroQ[resWn[[1]], "P2f"]];
report["P2g. dI - Aw.I = 0, period row", zeroQ[resWn[[2]], "P2g"]];

(* Reduced scalar form  s dR/dv - (1-2eps) R - s A21 - s A22 R = 0,
   the form quoted in the ledger record. *)
sv = 1 - v - w;
scalarV = (sv (D[Rclosed, v] /. contiguous)
   - (1 - 2 eps) Rclosed - sv Av[[2, 1]] - sv Av[[2, 2]] Rclosed);
scalarW = (sv (D[Rclosed, w] /. contiguous)
   - (1 - 2 eps) Rclosed - sv Aw[[2, 1]] - sv Aw[[2, 2]] Rclosed);
report["P2h. reduced scalar v-equation", zeroQ[scalarV, "P2h"]];
report["P2i. reduced scalar w-equation", zeroQ[scalarW, "P2i"]];

(* ================================================================== *)
(* P3.  Exact soft value.                                             *)
(* ================================================================== *)

softExact = Limit[
   -(2 - 3 eps)/(v (1 - 2 eps)) Hypergeometric2F1[1 - eps, 1, 2 - 2 eps,
     -(1 - v - w)/v] /. w -> 1 - v - sS, sS -> 0];
report["P3. soft limit equals (3 eps-2)/((1-2 eps) v)",
  Simplify[softExact - (3 eps - 2)/((1 - 2 eps) v)] === 0];

(* DE-forced soft value, independently: s->0 in the scalar equation kills
   the diagonal term and leaves 0 = (1-2eps) R + lim(s A21). *)
deForced = -Limit[sv Av[[2, 1]] /. w -> 1 - v - sS, sS -> 0]/(1 - 2 eps);
report["P3b. DE-forced soft value agrees",
  Simplify[deForced - (3 eps - 2)/((1 - 2 eps) v)] === 0];

(* ================================================================== *)
(* P4.  Branch content of the closed form.                            *)
(* ================================================================== *)

(* R as a function of s at fixed v is a 2F1 in z = -s/v, analytic at s=0;
   its expansion has integer powers only, so the coefficient of the free
   mode v^(-eps) s^(2 eps-1) is zero. *)
p4 = Module[{ser},
   ser = Series[Hypergeometric2F1[1 - eps, 1, 2 - 2 eps, -sS/v], {sS, 0, 6}];
   FreeQ[Normal[ser], Power[sS, _?(! IntegerQ[#] &)]] &&
     Simplify[(Normal[ser] /. sS -> 0) - 1] === 0];
report["P4. closed form is analytic in s at s=0 (no s^(2 eps-1) mode)", p4];

Print[""];
Print["PERIOD01_EXACT_DE = ", ! $fail];
