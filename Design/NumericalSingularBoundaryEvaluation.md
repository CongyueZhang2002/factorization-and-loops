# Numerical singular-boundary evaluation

The symbolic shared boundary definitions remain explicit finite expressions.
Numerical evaluation now has a separate Frobenius initializer and sparse Taylor
continuation. It does not use unweighted quadrature at the singular endpoint.

## Mathematical method

For the normalized epsilon-regular system, expand z A(z,epsilon) in the normal
coordinate and epsilon. At fixed supplied amplitude coefficients, first form
the Laurent seed S(epsilon)c(epsilon). The initializer computes the complete
logarithm polynomials at each normal and epsilon order. Its initial logarithm
polynomial is exp(R(epsilon) Log z) S c, normalized at Log z = 0.

The unregulated residue must be nilpotent. Its exact nilpotency index determines
a safe logarithm degree; the index does not cap all epsilon orders at the same
logarithm degree. For positive normal order n, the inverse of n I - R0 is the
finite geometric series in R0. No dense matrix inverse is needed.

Native FLINT arithmetic expands each exact rational connection entry locally
by bivariate truncated polynomial division. It keeps epsilon convolution
implicit rather than materializing a large repeated block matrix. Ordinary
Taylor steps use z = center + step*s. Their chords and the corresponding
quadratic contour arcs lie in pole-free Taylor disks. Distances are measured
in z, the Taylor coordinate actually used by this implementation.

The contour has the same geometry as the stored t^8 contour:
z(u) = target (u + i deformation u(1-u)). The initial logarithm uses its principal
branch; continuation carries it onward. This does not independently establish
the physical Feynman sheet.

## Orders and reuse

`EvaluateSharedBoundaryCoefficients` derives demands backwards through the
original-basis gauge, all same-order connection couplings and the seed.
A normalized interval [low, high] needs connection coefficients through
high-low. Missing required amplitude coefficients fail explicitly.

Unused normalized rows are removed by the closed dependency graph. Seed
coefficients above a row's proven demand may be omitted; they cannot affect
a requested output. This is independent of accidental cancellations for a
particular numerical amplitude assignment.

The normal `ReadMasterIntegralSolution` / `EvaluateMasterIntegralSolution` call
selects this method from stored singular-boundary input. It supplies completed
physical amplitudes, compares matching points and increases precision on
arithmetic failure. `BoundaryWorkingPrecision` sets the initial precision;
`MaxBoundaryWorkingPrecision` sets its cap. Arithmetic failure is detected
before reducing Taylor step sizes.

For reuse, compute shared ordinary-point coefficients once, then pass their association
to `ReadMasterIntegralSolution[directory, "BoundaryCoefficientValues" -> values]`.
It substitutes the computed B[index,order] values before reading any endpoint
integral definitions. The existing `EvaluateMasterIntegralSolution` then evaluates
the ordinary-point local transport. The general driver is
`Scripts/Boundary/evaluate_boundary_values.wls`.

The input record specifies the shared definitions, singular construction,
amplitude coefficient values, selected solution files and an output directory.
Its output is actual numerical Laurent coefficients, not a generator.

## Accuracy and measured scope

Normal-order tails, Taylor tails and FLINT arithmetic uncertainty are monitored
separately. The tail is summed directly, avoiding subtraction of two nearly
equal ball values. Target-level comparison is performed after the gauge
convolution, with a second matching point and increased normal/Taylor orders.

These are empirical truncation estimates, not certified global error bounds.
FLINT balls also suffer interval overestimation in a nonnormal basis. The full
346-component test needed increased working precision to pass that conservative
arithmetic check; precision did not repair the retired endpoint discretization.

On 2026-09-07 the new method passed analytic logarithm/dilogarithm/Jordan tests
and the epsilon-depth regression epsilon^11 times an epsilon^-8 seed. Two
independent full-system runs agreed for 1,038 original-master coefficients at
a 10^-20 absolute/relative tolerance. The largest scaled difference was
1.94e-9. The runs took 265.98 and 211.70 seconds on seven cores, at 400 and 450
working digits; they used a normalized epsilon interval [0,2] and rational,
nonphysical amplitudes.

CF123's actual requested boundary coefficients were then tested with Laurent
seeds: 49 coefficients, normalized interval [-8,-1], and 11 active components.
CF269 and CF300 together passed 236 demanded coefficients at their two ordinary
base points, using 45 active components and the same normalized interval.
These tests supply a known volume plus nonphysical rational values for the
unknown amplitudes. Subsequently, CF198 with the fully determined physical
boundaries passed a nonzero AMFlow comparison through epsilon^1 after correcting
the vendor order conversion; see PhysicalBoundaryResults_2026-09-07.md.

Records are in
`Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/BoundaryValues/OvernightEvaluation_2026-09-07`.
