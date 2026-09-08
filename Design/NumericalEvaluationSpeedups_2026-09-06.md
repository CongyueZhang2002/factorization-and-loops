# Numerical evaluation speedups, 2026-09-06

The general numerical evaluator now uses compiled arbitrary-precision complex
arithmetic, reuses preparation and refinement results, and evaluates independent
families or kinematic points on up to eight CPU workers. A separate optional
Taylor evaluator stores explicit numerical coefficients for repeated points on
an ordinary line segment. No process or family names occur in these implementations.
The existing 91 exact symbolic solution files were not regenerated or changed.

## Matched scalar timings

All rows below evaluate the stored master coefficients at
`X={13/50,7/40}`, using explicit rational test boundary coefficients, 30-digit
absolute/relative goals and an initial working precision of 80 digits.
The test values are C[j,k]=(101+3 j+k)/(113+j-k) for the required constants;
the Taylor records retain their complete supplied boundary lists.
The numerical evaluation includes convergence refinements, input/path checks
and final reconstruction. Reading the solution file is excluded. Arithmetic
preparation is listed separately and is reusable.

| Family | Requested coefficients | Wolfram evaluator | Compiled evaluator | Compiled preparation |
|---|---:|---:|---:|---:|
| CF269 | 16 | 10.82 s | 1.83 s | 0.36 s |
| CF259 | 56 | 53.42 s | 8.02 s | 4.07 s |
| CF303 | 36 | 52.65 s | 8.56 s | 3.06 s |

The Wolfram column uses the reference evaluator with the shared preparation
and quadrature caches. These are observed elapsed times on the same WSL machine
and eight-core allocation, not CPU-time totals or isolated hardware measurements.
They do not time DE construction, AMFlow boundary computation, or full NNLO
assembly. The CF269 point here differs from its earlier AMFlow benchmark point,
so the earlier 7.89-second CF269 number is not the baseline for this table.

All 108 requested coefficients agree between the compiled and Wolfram paths at
the requested tolerance. The compiled evaluator also agrees with the saved
independent AMFlow series results: maximum normalized differences
`4.59*10^-59` for CF269 and `1.65*10^-39` for CF259. Each comparison uses the
reference's own point and test boundary polynomial; CF269's AMFlow point is
`{13/50,41/120}`. These are nonzero test-boundary comparisons. No new physical
auxiliary-mass-flow computation was performed.

## Parallel throughput

The same eight tasks—four CF259 and four CF303 evaluations, including repeated
points to isolate scheduling and preparation costs—took:

- one persistent worker: **76.44 s**;
- eight persistent workers: **18.13 s**, about **4.2 times faster**.

Both timings include reading/preparing families, numerical convergence and
batch overhead. Each parallel worker used one native thread. Results preserve
input order; independent failures do not discard successful tasks. Duplicate
output paths are rejected. Workers retain prepared families throughout the batch.

The native evaluator also supports up to eight threads across quadrature nodes
for one point. Its one-thread and eight-thread results were checked for equality;
no single-point eightfold speedup is claimed.

## Explicit Taylor reuse

The optional constructor forms the finite vector of required epsilon coefficients
from the original rational DE. It propagates exact valuation bounds, then follows
the actual nonzero coefficient dependencies. Thus a term
`epsilon^-1 I_2` requires the appropriate higher coefficient of `I_2`.
Missing center coefficients are an error. A negative cycle that prevents a
finite raw-DE coefficient closure declines this numerical route; it is not a
nonexistence result for the symbolic solution.

For `y'(z)=B(z)y(z)`, the native recurrence is

```text
y[n+1] = Sum[B[a].y[n-a], {a,0,n}] / (n+1).
```

It evolves a vector, without constructing every boundary-to-master matrix column.
The saved WXF contains the actual numerical Taylor coefficients, coefficient
states, requested output rows, center, direction, boundary binding, numerical
accuracy and accepted radius. Output row labels are not stored as fictitious
zero coefficient values.

These production measurements use Taylor degree 32 plus eight additional terms,
90-digit working precision, 30-digit output goals, and direction
`{1/100,1/120}`. Each point is `Center + z Direction`.

| Family | Construction, including checks | 128 queries | Accepted `Abs[z]` | File size |
|---|---:|---:|---:|---:|
| CF269 | 2.85 s | 0.42 s | 1 | 0.39 MB |
| CF259 | 24.37 s | 1.59 s | 1/4 | 1.43 MB |
| CF303 | 25.04 s | 1.46 s | 1 | 1.34 MB |

Construction consists of preparing the restricted rational coefficient connection,
the compiled recurrence, and validation. The native recurrence itself took
0.24, 0.62 and 0.60 seconds respectively. Production validation uses one direct
finite-integral comparison, plus inexpensive off-grid DE residuals and
Taylor-error estimates at the two outer endpoints and one interior point.
`"ValidationPoints"->3` requests three direct comparisons. The earlier three-comparison development expansions were superseded and removed.

Every one of the 384 production queries passed its local accuracy checks.
A CF269 recentering check and an analytic logarithmic control also passed.
To recenter, request all coefficient-state values from a valid query.
Their exported accuracy includes the estimated Taylor error. The constructor
checks the original basis, base point and boundary binding, requires every
coefficient needed at the new center, and validates the new expansion.

A directional cache covers its specified line, not an arbitrary multidimensional
neighborhood. Queries outside the accepted radius fail. Radius selection accounts
for complex poles of the restricted rational connection. Singular endpoints,
physical thresholds and general branch continuation remain outside this ordinary
local evaluator. Arithmetic/input uncertainty, Taylor truncation estimates and
direct comparison results remain distinct; the complete result is not a rigorous
interval enclosure. A cache is useful only when enough queries lie in its region
with the same boundary binding. CPU batches remain the default.

## Implementation and validation

- `FeynFacet/Solution.m` retains the standalone reader, Gauss-Legendre
  collocation and output reconstruction. Quadrature matrices are cached by order
  and precision; failed order refinements reuse the previous higher-order result.
- `FeynFacet/Numerics/FLINT.wl` validates dependencies once and compiles
  shared arithmetic expressions. Changed definitions invalidate preparation.
  Unsupported expressions use the Wolfram path under automatic selection, or
  fail explicitly when the compiled path is required.
- `FeynFacet/Backends/flint/finite_integrals.cpp` evaluates the stored arithmetic
  with FLINT complex balls and carries nested integrals between panels. Dead
  intermediate storage is reused. No conversion through machine precision occurs.
- `FeynFacet/Numerics/Batch.wl` shares boundary/reference validation between
  the single-point driver and the worker pool.
- `FeynFacet/Numerics/Taylor.wl` and `finite_taylor.cpp` provide finite
  epsilon-state closure, rational-series evaluation, the sparse Taylor recurrence,
  explicit coefficient storage, local error checks and recentering.

The focused checks pass: 18 existing numerical tests, 11 compiled/batch tests,
11 Taylor/order/recentering tests, and 43 symbolic finite-solution tests.
The new tests include complex elementary functions, nonzero logarithmic values,
cancellation, negative epsilon powers, missing data, changed prepared definitions,
parallel agreement, polynomial integration moments, and error magnitudes beyond
machine floating-point exponent range.

Retired source snapshots and session benchmark drivers are in the code backup.
Measurement records are under
`ppHX_NNLO_DoubleReal/Results/Validation/NumericalEvaluationSpeedups_2026-09-06`. Complete numerical
records are under `NumericalSpeedups_2026-09-06` in the process result directory.
The scalar-reference and compiled-point timings are distinct from the AMFlow
comparisons and from the line-scan timings.

The old CF3 AMFlow exports contain zero master values at the tested orders.
They predate the corrected AMFlow order conversion and are not accepted
physical validation. On 2026-09-07 the corrected physical CF198 comparison
passed through epsilon^1; see PhysicalBoundaryResults_2026-09-07.md.

Pro reviewed the method description, not the uncommitted code. The exchange is
recorded in `External/ChatGPT/Records/2026-09-06/07_numerical_speedups.md`.
The implementation follows the finite-coefficient DE recurrence, pole-aware local
regions, explicit error accounting and CPU-first recommendation. GPU work was
deferred after these measured CPU improvements.

FLINT's [complex-ball documentation](https://flintlib.org/doc/acb.html) describes
the arithmetic used here; the independent reference remains
[AMFlow 2.0](https://arxiv.org/abs/2607.08477).
