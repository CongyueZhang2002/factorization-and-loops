# CF305 `(18,15)` investigation — 2026-08-22

## Result

This block is **not obstructed**.  The failure is a finite-field support
selection false negative: the certified total-degree simplex was intersected
with a narrower inferred bidegree rectangle.  The exact gauge needs monomials
outside that rectangle (in particular, `x`-degree 6 while the inferred gauge
denominator has `x`-degree 3), although its numerator total degree is only 9
and is safely below the certified bound 12.

No package or production-family artifact was changed by Codex.  The scripts
and independent artifacts for this investigation are in this exchange
directory.

## Independent exact evidence

`CF3051815ExactCertificate.wls` reconstructs the unobstructed coefficients
`D_0,D_1,D_2`, forms the order-three Pfaffian equation independently, and
takes symbolic residues on the two curves that were initially suspected:

- on `y - 3`, the two residues are exactly `{0,0}`;
- on `-2 + 5 x - 2 y - 2 x y + x y^2`, they are exactly `{8,16}`.

Both are constant.  The full order-by-order checker is clean through order
10; every nonzero `D_k` has numerator total degree 9.

The preceding `(18,16)` modular system has rank 58 and nullity 2 in the old
19-monomial support.  Both nullspace gauges differentiate to zero modulo the
pilot prime, so they are precisely the expected two kinematics-constant
integration modes of a `2 x 1` gauge.  Retuning that normalization can add
only constant-residue dlogs to `(18,15)` and is not the cause of the failure.

## Closed-form solution from the epsilon series

The exact coefficients satisfy, entry by entry,

```text
D_k = -4 D_(k-1),       k = 3,...,10
R_k = -4 R_(k-1),       k = 3,...,10
```

where `R_k` denotes the order-`eps^k` residue coefficient of the transformed
off-diagonal form.  Therefore the series resums to

```text
D(eps) = eps D_1 + eps^2 D_2/(1 + 4 eps),
K(eps) = R_1 + eps R_2/(1 + 4 eps).
```

`CF3051815SeriesResummation.wls` constructs this gauge and residue set and
checks the complete two-variable identity

```text
bbar + eps (e D - D c) - dD
  = eps Sum_a K_a dlog(L_a)
```

both directly and through CANONICA's exact dlog checker.  Its output files
are `CF305_18_15_series_solution.wl` and
`CF305_18_15_series_certificate.wl`.

## Finite-field diagnosis

The old automatic support was

```text
{(i,j): i <= deg_x(den)+offset_x,
          j <= deg_y(den)+offset_y,
          i+j <= certified total-degree bound + shell}.
```

Offsets only through `{2,2}` never admitted the needed `x^6` terms.  This is
why every pilot rectangle was inconsistent before any prime lifting began.
Adding denominator letters or collecting more primes cannot repair a missing
numerator monomial.

With the complete degree-12 simplex, the CF305 pilot has:

```text
91 support monomials
204 unknowns = 2*91 gauge coefficients + 22 residues
rank 202, nullity 2
```

and the held-out modular interpolation stabilizes after three primes.

### Direct regression of the repaired package path

`CF3051815FiniteFieldRegression.wls` ran the current package solver with one
main kernel, three primes, and the exact final check.  It completed in 21.86 s
with:

```text
selected offset {0,0}, support shell 0
91 monomials, 204 unknowns
rank 202, nullity 2
3 modular primes
ExactDLog = True
ExactPfaffianResidualsZero = True
```

The finite-field gauge is not literally identical to the independently
resummed gauge, but their difference is kinematics-constant.  They are the
same solution modulo the expected `2 x 1` integration-mode freedom.  The
retained exact result and run certificate are
`CF305_18_15_finite_field_solution.wl` and
`CF305_18_15_finite_field_certificate.wl`.

## Recommended package fix

Keep the cheap sparse support as the fast path, but make the complete
certified simplex a terminal completeness fallback:

1. Probe the former `rectangle intersect simplex` supports over the existing
   bidegree-offset ladder.  This preserves the measured CF254 fast path (124
   monomials, 548 unknowns).
2. If all of those are inconsistent and the valuation census is certified,
   probe the full simplex `i+j <= bound` once.  Label it explicitly, e.g.
   `"CertifiedSimplex"`.
3. Size the power tables from the actual support maxima, not only from the
   bidegree caps.
4. Do not use “rectangle inconsistent” to prune a full-simplex or wing
   support: after the intersection is removed, those supports are not subsets
   of the rectangle.
5. Once a support can exceed `denominatorDegrees + offset`, do not continue
   reporting that old cap as `GaugeNumeratorDegrees`.  Record the requested
   cap separately and set the ansatz/support maximum degrees from the actual
   exponent list; otherwise the elimination-plan and solution metadata
   under-report the search that was performed.

Trying the full simplex first is correct for CF305 but unnecessarily enlarges
ordinary cases and changes the meaning of the degree-offset ladder.  The
fast-path-then-completeness-fallback ordering gives both correctness and the
previous performance.

Also remove the stale header claim in
`FeynFacet/Private/EpsFormStripObstruction.wl` that CF305 has an order-three
nonconstant residue.  The implementation and the updated test correctly
return `NoObstructionToOrder`; only that explanatory comment is stale.

Operational note: the scratch `resum.wls` and `solve_fixed.wls` currently call
`FamilyArtifactWrite[path, value]`.  The public signature is
`FamilyArtifactWrite[value, file]`; reversing those arguments silently leaves
no artifact, which explains the missing `resummed_solution.wl` and
`ff_solution_fixed.wl` despite successful calculations.

## Regression to retain

- Existing CF254 `(9,6)` sparse count and exact solve remain unchanged.
- Saved CF305 `(18,15)`:
  - the old clipped supports are inconsistent;
  - the 91-monomial certified simplex is consistent;
  - the finite-field solution verifies the exact Pfaffian identity;
  - comparison with the resummed solution is exact up to a
    kinematics-constant `2 x 1` gauge mode (exact equality is acceptable when
    both solvers choose the same normalization).
- The order-by-order obstruction test is clean through at least order 4 and
  retains the geometric residue check.
