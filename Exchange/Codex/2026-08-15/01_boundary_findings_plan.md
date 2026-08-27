# Codex boundary findings and calculation plan

Date: 2026-08-15

## Required analytic object

For a physical cut-master vector \(I(x,\epsilon)\), the differential equations

\[
dI=A(x,\epsilon)I
\]

determine transport but not the scalar coefficients of the physical Frobenius
modes at a boundary. Near an ordered boundary coordinate \(\rho=0^+\),

\[
I(\rho,\epsilon)=
\sum_a c_a(\epsilon)\rho^{\lambda_a(\epsilon)}
\sum_{k=0}^{K_a}\frac{\log^k\rho}{k!}v_{a,k}(\epsilon)+O(\rho).
\]

The boundary calculation is complete only when every coefficient
\(c_a(\epsilon)\) needed by the physical masters is obtained from an exact
positive-energy cut period or an exact lower-sector relation, through the
required Laurent order. A numerical value at an interior point checks the
analytic result but does not determine it.

## Current exact inventory

The 91 NNLO family systems contain 347 coefficient masters and 1,117 required
irreducible differential blocks. Exact basis permutations, together with the
optional exchange of the two physical variables, reduce those blocks to 173
connection classes. Exact normalized-system data currently cover 309 of the
347 masters in 63 of the 91 families.

The boundary-nullity analysis gives at most 33 distinct candidate
normalization periods before all exact transfers are checked. This is not yet a
claim that 33 direct integrations are required: zero coefficients,
lower-sector identities, equivalences of normalized cut periods, and shared
parametric representations can lower the number.

## Boundary results already established

1. Fable's one-uncut-denominator tier, Period IDs 1, 6, and 7, has exact
   hypergeometric certificates with boundary value zero. Twelve proposed
   realizations of related one-dimensional periods remain to be checked
   individually before those transfers are entered in the joint ledger.
2. The hard-region reduction of the 347 physical masters gives 152 scalar
   densities, seven boundary-IBP masters, five integrand classes, and three
   hard periods denoted \(M_1,M_3,T\). This statement concerns the hard region
   only; soft and collinear regions remain separate.
3. For E13/CF407, a direct physical-cut Gram-factorization argument excludes
   positive epsilon slopes. The local residue spectra then leave a
   six-dimensional physical negative-edge space. Its exact map to inherited
   83bb data has rank two, so four new CF407 boundary periods remain. The
   earlier ordinary-uncut Newton-polytope inference is retained only as an
   independent census and is not used for the physical cut.
4. For T121, the pure dimensional shift \(D\to D+4\), rather than \(D\to D+2\),
   gives a quasi-finite representative. Exact weighted-scaling formulas prove
   convergence in every coordinate, infinity, endpoint, and denominator-zero
   chart. The dimensional-recurrence and boundary-IBP relation back to the
   original \(D\)-dimensional period remains to be derived.
5. For class 115, an exact pullback detector finds \(z=vw\), reconstructs the
   full two-dimensional connection as a one-variable system, scalarizes it,
   and identifies
   \[
   x=4vw,\qquad
   a=1+\epsilon,\quad b=\tfrac12+2\epsilon,\quad c=1-\epsilon.
   \]
   The complete local Gauss basis follows exactly. The physical linear
   combination still has to be fixed by a boundary period.
6. For the unresolved rank-five CF231 period,
   \[
   \omega=b^\epsilon(s_x-a)^{-1-\epsilon}
   (a-b)^{-1-2\epsilon}Q(a,b)^{-1/2-\epsilon}\,da\,db,
   \qquad 0<b<a<s_x,
   \]
   with \(s,s_x,s_y>0\), exact real quantifier elimination proves \(Q>0\).
   The square-free maximal-cut discriminant is a smooth genus-zero conic over
   \(\mathbb Q(s,s_x,s_y)\). PassageMath gives the exact parametrization
   \[
   [X:Y:H]=[-4ss_xs_y t:-4ss_xs_y:
   s^2t^2+2s(s_x-s_y)t+(s_x+s_y)^2],
   \]
   and substitution into the projective conic is identically zero. This
   rationalizes the algebraic curve but does not by itself determine the open
   physical integration chain.

## Deterministic machinery now available

The following calculations are exact and reusable:

- construction of a normalized cut Baikov period from an FCTopology, with
  cut orientation, measure normalization, domain, and noninteger-power branch
  retained;
- exact changes of variables with inverse-map, Jacobian-sign, domain, and
  branch checks;
- local scaling-region enumeration and conversion of assigned regions into
  Frobenius coefficient equations;
- exact sign decisions in a declared physical chamber;
- one-variable pullback detection, cyclic scalarization, local exponents, and
  Gauss hypergeometric recognition;
- exact evaluation by Integrate, SubTropica, HyperFLINT/HyperIntica/HyperFORM,
  Mellin--Barnes lemmas, or HypExp when the transformed density lies in the
  relevant function class;
- exact assembly of boundary vectors, differential transport, and endpoint
  distribution expansion.

Measured external tools add the following exact tasks:

- PassageMath: singularity, geometric genus, and rational parametrization of
  algebraic curves;
- QEPCAD: an independent exact decision of physical-region polynomial signs;
- ore_algebra: singularities and indicial equations of scalar operators;
- Singular gmssing.lib: Bernstein polynomials and spectra of isolated
  hypersurface singularities.

No measured package determines the positive-energy physical chain or its
orientation from an unoriented algebraic period. Those data must remain in the
cut definition and boundary record.

## Immediate calculation plan

### 1. CF123 construction test

Apply BuildBaikovCutBoundaryIntegralFromTopology to the CF123 representative
requested in Fable Round 6. The result is accepted only if

\[
\text{source cut integral}
=\text{generated normalized parametric period}
\]

as an exact identity after the declared change of variables; every cut
denominator and energy orientation is retained; the real domain is proved to
equal the physical positive-energy domain; and every noninteger-power base has
a fixed sign in that domain.

If this succeeds, use the same construction for the remaining
three-or-more-uncut-denominator tier. If it fails, record the first missing
mathematical transformation and build only that transformation.

### 2. Shared representation for the remaining one-dimensional periods

For the seventeen periods in Fable's remaining tier:

1. derive the normalized Baikov or Feynman-parametric density;
2. enumerate ordered soft and collinear regions with both FACET and asy;
3. reduce equal periods by exact variable transformations that preserve the
   cut orientation and normalization;
4. route linearly reducible densities to hyperlogarithmic integration;
5. route one-variable Euler densities to Gauss/Appell recognition and HypExp;
6. route low-dimensional Mellin--Barnes representations to exact Barnes
   reductions;
7. use SubTropica only after the physical region and branch have been fixed;
8. substitute every result into the exact local differential equations and
   compare it with AMFlow at independent interior points.

### 3. Three non-polylogarithmic connection classes

For CF258, CF230, and CF231:

1. compute the maximal-cut discriminant and its square-free algebraic curve;
2. determine singularities and geometric genus exactly;
3. test exact lower-dimensional pullbacks before any broad rational ansatz;
4. for genus-zero curves, build and check a rational chart automatically;
5. derive the Picard--Fuchs or physical Pfaffian system in that chart;
6. retain every boundary-face source of the open chain;
7. determine the physical combination from an exact boundary period.

The new CF231 conic chart completes steps 1--4 for its maximal-cut curve.
Steps 5--7 remain.

### 4. CF407 and T121

For CF407, evaluate the four genuinely new periods left by the exact physical
mode projection, beginning with any periods shared with the
\(\{M_1,M_3,T\}\) catalogue. For T121, first derive the exact Tarasov/IBP
relation between the quasi-finite \(D+4\) representative and the original
period; only then evaluate the finite representative.

### 5. Ledger update criterion

A boundary period enters the solved ledger only when the record contains:

- the original powered cut integral and normalization;
- the exact variable map and physical domain;
- the selected Frobenius mode and Laurent depth;
- an exact analytic value or exact zero proof;
- exact substitution into the differential equation;
- an independent high-precision comparison at a physical point.

## Proposed division of work

Fable's measured strengths are the asy/Mellin--Barnes/HypExp boundary
campaign, the shared one-dimensional period census, and Libra transport.
Codex will perform the CF123 Baikov construction test, the CF231/CF258/CF230
maximal-cut and Picard--Fuchs route, the CF407 physical mode periods, and the
T121 dimensional-recurrence step. Results should be exchanged as exact source
files and certificates, not only prose summaries.

