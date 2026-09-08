(* ============================================================
   FeynFacet canonicalization campaign -- CLASS 79 (4x4, rep CF231 rows {1,2,3,4})
   STATUS: NOT canonicalized here.  Codex owns the CF231_B1 chart geometry and
   is actively running run_quadratic_chart_attempt.wls.  This file is
   VERIFICATION + LOCAL DATA only, produced independently (sympy 1.14, no
   Wolfram kernel used -- the single-seat queue was busy for the whole session).
   ============================================================ *)

(* ---------- 1. THE QUADRATIC LETTER ---------- *)
Class79$Q = 1 + 2 v + v^2 - 2 w + 2 v w + w^2;
(*  verified identities:
       Q == (1+v+w)^2 - 4 w
       Q == (v+w-1)^2 + 4 v
       Discriminant[Q, w] == -16 v      (roots w = 1-v +- 2 Sqrt[-v])
    In the physical chamber 0<v,w, v+w<1 both terms of (v+w-1)^2+4v are
    positive, so Q > 0 there: no branch point inside the chamber.           *)

(* ---------- 2. CODEX CHART -- INDEPENDENTLY VERIFIED ---------- *)
(*  w = -t (1+t+v)/(1+t)   gives, EXACTLY,
        Q  ->  ( (t^2 + 2 t + v + 1) / (t+1) )^2  =  ( (v + (1+t)^2)/(1+t) )^2
    so   Sqrt[Q] -> (v + (1+t)^2)/(1+t)      -- RATIONAL.  Chart CONFIRMED.
    Inverse:  t = -(1 + v + w)/2 +- Sqrt[Q]/2 .
    Other letters in the chart:
        v      -> v
        w      -> -t(t+v+1)/(t+1)
        v+w    -> -(t^2 + t - v)/(t+1)
        1+v+w  -> -(t^2 - v - 1)/(t+1)
        1-v-w  ->  (t^2 + 2t - v + 1)/(t+1)
    Equivalent minimal rationalization (used below):  v = -m^2, giving
        Q = (w - (1+m)^2) (w - (1-m)^2).                                     *)
Class79$CodexChart = w -> -t (1 + t + v)/(1 + t);
Class79$SqrtQ      = (v + (1 + t)^2)/(1 + t);

(* ---------- 3. DENOMINATOR ALPHABET OF THE STORED BASIS ---------- *)
Class79$Letters = {
  v, w, v + w, 1 + v + w, Class79$Q,
  (3 + 5 eps) (v + w) - 3 (1 + eps)        (* <-- EPS-DEPENDENT: see 5 *)
};
(* eps-only factors (1+eps), (1+4eps) also occur: harmless basis normalisation *)

(* ---------- 4. POLE ORDERS IN THE STORED BASIS ---------- *)
(*   letter                       ord in Av   ord in Aw
     v                                1           1
     w                                0           1
     v + w                            2           2      <-- NOT FUCHSIAN
     1 + v + w                        1           1
     Q                                1           1
     (3+5eps)(v+w)-3(1+eps)           1           1                          *)

(* ---------- 5. LOCAL EXPONENTS (residue eigenvalues) ---------- *)
(*  Valid only at simple poles.  Computed with eps symbolic.                 *)
Class79$Exponents = <|
  "v=0"        -> {eps, -1 - 2 eps, -2 - 2 eps, -2 - 2 eps},
  "1+v+w=0"    -> {0, 0, 0, -5 - 6 eps},
  "Q=0"        -> {0, 0, 0, 1/2 + eps},   (* rank-1 residue; branch w=(1+m)^2, v=-m^2 *)
  "L=0"        -> {0, 0, 0, 1},           (* rank-1, eps-INDEPENDENT INTEGER *)
  "v+w=0"      -> "UNDEFINED -- order-2 pole, needs Moser reduction first"
|>;

(* ---------- 6. THE TWO DEFECTS OF THE STORED BASIS ---------- *)
(*  These are almost certainly why CANONICA timed out at degrees 0 and 1
    (1200 s each) and why Codex reports the system "Fuchsian in z but not
    in u" for CF231_B1.  BOTH are artifacts of the stored master
    normalization, not properties of the integrals.

    (D1) NON-FUCHSIAN DOUBLE POLE at v+w = 0.
         Order-2 pole in both Av and Aw.  A Moser reduction is required
         before any eps-form search; a rational-ansatz canonicalizer asked to
         produce a double pole needs a much higher ansatz degree, which is
         consistent with the observed timeouts.

    (D2) APPARENT EPS-DEPENDENT SINGULARITY at
             L := (3 + 5 eps)(v + w) - 3 (1 + eps) = 0 ,
         i.e. the moving locus  v + w = 3(1+eps)/(3+5eps).
         A master integral cannot have a singular locus that moves with eps
         (Landau loci are eps-independent), so this is spurious.
         Evidence: residue R_L is rank 1 with eigenvalues {0,0,0,1} --
         integer and eps-INDEPENDENT -- identical at w = 1/7 and w = 2/5.

         REMOVAL (exact, explicit, verified):
           R_L is rank 1 with trace 1, hence R_L^2 = R_L : it IS the spectral
           projector P onto the eigenvalue-1 eigenspace.  The balance
               T    = (1 - P) + L P
               T^-1 = (1 - P) + P / L        (exact; no matrix inverse needed)
           satisfies T.T^-1 = 1 and det T proportional to L.
           After the gauge transformation  A -> T^-1 A T - T^-1 dT,
           L NO LONGER DIVIDES ANY DENOMINATOR (pole order 0).
           Verified at (eps,w) = (1/11,1/7), (2/13,2/5), (-3/7,1/3).         *)

(* ---------- 7. THE GENUINE OBSTRUCTION ---------- *)
(*  The exponent 1/2 + eps at Q = 0 is a HALF-INTEGER offset.  No rational
    gauge over Q(v,w) can shift it, so NO eps-form exists in (v,w) -- the
    same mechanism that makes class 115 non-rational in (v,w) (there the
    exponent is -3/2 - 4 eps).
    Under a rationalizing chart (Codex's t, or v = -m^2) the exponent DOUBLES
    to 1 + 2 eps: integer part 1, removable by ONE balance.
    => an eps-form should exist in the rationalized chart, PROVIDED (D1) and
       (D2) are cleared first.  Recommended order:
         (i) Moser-reduce the v+w=0 double pole,
        (ii) balance away L (section 6),
       (iii) change to the chart,
        (iv) one balance at the doubled Q exponent,
         (v) then run CANONICA -- with an eps-INDEPENDENT alphabet, so a low
             ansatz degree becomes plausible.                                 *)

(* ---------- 8. NOT DONE ---------- *)
(*  - No CANONICA run (single Wolfram seat busy all session: hardclasses.wls
      plus Codex's own run_quadratic_chart_attempt.wls).
    - No 4x4 chart transformation, no eps-form, no reducibility analysis.
    - Removal of (D2) verified at three rational (eps,w) points plus the
      general structural argument, not as one closed symbolic identity.      *)
