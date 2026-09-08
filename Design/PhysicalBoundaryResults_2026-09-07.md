# Physical boundary results, 2026-09-07

All boundary constants needed by the stored solutions are determined:
91 families, 345 requested masters and 2,220 requested epsilon coefficients.
The actual shared boundary expressions contain no free Frobenius amplitudes.
The original integral definitions, cut signs and measure prefactors are preserved.

This completes numerical singular-endpoint evaluation and physical boundary
integration for these stored orders. NNLO assembly, general analytic
continuation, and additional endpoint/renormalization/PDF-factorization epsilon
demands remain separate work.

## General code and reproduction

`FeynFacet/Boundary/DetermineAmplitudes.wl` selects independent established
physical coefficient equations, preserves Laurent lower bounds, derives
sufficient integral orders, and evaluates missing coefficients.
Seed-to-amplitude maps are explicit matrices. Cached values must match their
integral definitions. A representation alone does not establish a physical limit.

The driver is `Scripts/Boundary/determine_boundary_amplitudes.wls`. Its input is

    ppHX_NNLO_DoubleReal/Results/BoundaryValues/OvernightEvaluation_2026-09-07/general_boundary_determination_input.wxf

Apply its output with `general_physical_boundary_application_input.wxf` in that
directory. The driver has no process or family selection. Its reduction agrees
exactly with the initial complete reduction after reordering the input columns.

Physical limits are in `Integrals/Asymptotics`. Gaussian parameters, Euler
products and scale normalization are in `Integrals/Parametric`. Integration,
affine reduction and order application are in `Boundary`; vendor translation
is in `Interfaces/SubTropica.wl`.

## Physical coefficient determination

The 346-component closure has a known volume amplitude and 83 initially unknown
amplitude series. Whole-domain limits fix all 48 slope -2 directions. Three
single-collinear Gamma coefficients fix the slope -3 directions. A large-real-D
bound excludes the exceptional zero mode. Complete double-collinear
coefficients fix all 32 slope -4 directions.

The whole-domain construction handles unit cuts and one doubled cut, exact
eikonal factors and up to two distinct final-state pair invariants. A doubled
cut is a mass derivative, including the moving integration domain.

The adopted computation evaluated four non-elementary Euler integral series:
three whole-domain integrals and one shared pair-cluster integral. Other inputs
have Gamma/Beta formulas, digamma formulas, or explicit finite classical-PL
coefficients. This counts the integrals used, not a minimal transcendental basis.

### Physical-limit proofs

Write alpha=(D-2)/2 and Q^2=z. The exact raw energy-angle measure scales as
z^(2 alpha-1). Rescaling both angular caps supplies z^(2 alpha), giving the
double-collinear measure z^(4 alpha-1). The original measure/routing prefactor
multiplies this result.

Reusable Gamma formulas cover a Euclidean sunset, a product of bubbles, and
two cluster denominators. A cluster-plus-constituent profile uses the exact
conditional two-body moment

    Gamma(alpha-b) Gamma(2 alpha) /
      [Gamma(alpha) Gamma(2 alpha-b)].

The conditional identity is established before meromorphic continuation.

For external-only cluster profiles, replacing positive cluster eikonals by
selected constituents gives a pointwise bound by two convergent bubbles.
In 1<alpha<2 the complete scaled bubble measure has no mass left at energy
endpoints or outside the double cap. The bounded target/comparator ratio
converges on compact subsets, proving the complete coefficient.

For a future-timelike cluster K contained in Q,

    K^2/(2 P.K) <= z/(2 P.Q).

Thus quadratic cluster propagators differ from signed eikonals by a uniform
relative O(z) correction. The six partial-fraction relations are consequently
physical leading-coefficient identities, not exact finite-z identities between
the original quadratic integrals.

The pair-plus-cross-pair profiles use

    1/(r1+r2) <= 1/(2 sqrt(r1 r2)).

The comparator's energy and angular bounds give 5/4<alpha<3/2. The antipodal
corner is integrable; the cap complement is suppressed relative to the target
by z^(3-2 alpha) and z^(3/2-alpha). Bounded-weight transfer proves the full limit.

Detailed derivations are retained in
`External/ChatGPT/Records/2026-09-07/09_double_collinear_coefficients.md` and
`10_double_collinear_completeness.md`.

### Finite formulas

For delta=alpha-1, r>=1 and q=1/r, the one-cluster sharing weight is

    W(r;delta) = tan(pi delta)/(2 pi)
      * [q^delta/delta + integral_0^q (x^delta-x^(-delta))/(1-x) dx].

Use W(r)=1-W(1/r) for r<1 and W(1)=1/2. At a requested order, the integral is
replaced explicitly by finitely many

    J_m(q) = sum_(j=0)^m (-1)^j m!/(m-j)!
             * log(q)^(m-j) Li_(j+1)(q).

The required arguments are 9/16, 1/16 and 1/9. No unevaluated sharing function
or infinite series is stored.

For two clusters, the opposite-constituent weight is

    X(delta) = tan(pi delta)/(2 pi) [psi(1)-psi(2 delta)].

The same-constituent weight is 1/2-X. Both multiply the known bubble product.
Whole expressions are expanded before truncation, including removable poles.

The only new pair-cluster integral is

    E(delta) = integral_0^1 du integral_0^1 dt
      u^(delta-1) (1-u)^(2 delta-1) t^(delta-1) (1-u t)^(delta-1).

Its physical prefactor is

    N(D) 4^3 / [2^(4 alpha+2) s_P s_R]
    * pi^(2 alpha) L^(2 alpha-3)
    * Gamma(1-2 delta) Gamma(2 delta) Gamma(delta)/Gamma(3 delta).

L is the squared separation of the two scaled external directions; each s
retains its sign. The two physical coefficients share E and differ by exact
scale factors. The two-dimensional evaluation through physical epsilon^1 took
15.1 seconds on four cores; the independent three-dimensional calculation
took 62.1 seconds.

## Numerical use

The normal public call selects Frobenius initialization automatically:

```wl
Get["/home/maxzhang/factorization-and-loops/FeynFacet/Solution.m"];
solution = FeynFacetSolution`ReadMasterIntegralSolution[
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/CF300/FiniteSolution"];
value = FeynFacetSolution`EvaluateMasterIntegralSolution[
  solution, {1/4, 1/5}, "Threads" -> 4];
```

No constants need to be supplied. The evaluator computes demanded boundary
coefficients, refines the matching point, and increases precision on arithmetic
failure. Roundoff failure is detected before reducing Taylor step sizes.

At 18-digit absolute/relative goals, CF198 and CF300 took 21.1 and 31.1 seconds
on four cores for initialization plus ordinary transport. Reading their
symbolic files took another 2.8 and 3.3 seconds. Both started at 80 digits and
succeeded at 160; larger systems can need more.

Computed `BoundaryCoefficientValues` can be reused through the reader option.
GPL endpoint checks distinguish convergent nonleading endpoint letters from
divergent endpoints. Real interior letters require `RealLetterPrescription`
of +1 or -1, following the
[GiNaC convention](https://www.ginac.de/tutorial/#Multiple-polylogarithms).
An exact dilogarithm identity removes contour-sign terms only when their
coefficient vanishes.

## Validation and limits

- All 91 family files have zero undetermined requested boundary coefficients.
  Every reference is stored; actual boundary expressions contain no free
  amplitudes or unresolved series operations.
- Five independent Euler representations agree with the final formulas at
  tolerance 10^-25 through all overlapping orders.
- Automatic CF198 evaluation agrees with an independent nonzero hypergeometric
  integral through epsilon^1 at (v,w)=(1/4,1/5).
- Full 346-component artificial-seed transport was separately checked for
  1,038 original coefficients. Final physical numerical checks cover selected
  systems, including CF300, not every family.
- Focused tests cover the general order/amplitude driver, Gamma kernels,
  endpoint resolution, multiple-zeta decoding, scale transformations and GPL
  prescriptions. Package layout checks pass.

Truncation checks are empirical, not certified global error bounds.
The CF198 AMFlow discrepancy is resolved. The wrapper had passed the desired
upper epsilon power directly to SolveIntegrals, whose third argument is an
offset from -2 L in the installed vendor implementation. For two loops, order
1 retained only powers through -3 and omitted the nonzero leading power -2.
Both interfaces now translate the order correctly, including master prefactors
in the standalone driver; older exports without that convention are not reused.
A fresh 25-digit AMFlow run took 75 seconds on four cores and agrees with both
the stored physical DE and the independent hypergeometric expression through
epsilon^1 at v=1/4,w=1/5, with tolerance 10^-18. This is a selected-master
physical check, not an all-family numerical audit. The standalone driver also
passes (73.74 seconds), after restoring momentum-square forms of quadratic cut
propagators for AMFlow boundary matching. Seven order/cache/failure regression
assertions pass. Inputs, values and comparison
are in Results/Validation/AMFlowCF198_2026-09-07 under the process directory.

All final data and validation records are in the actual process Results
directory. The frozen ~/FACET was not edited.
