# Full differential-equation and finite-solution regeneration, 2026-09-06

All 91 families in the current canonical coefficient inventory have freshly
constructed raw differential equations and complete finite master-integral
coefficients at their derived order requirements. No family remains unresolved
in this run.

- Requested masters: **345** (all nonzero coefficient-table entries).
- Stored explicit master coefficients: **2,220**.
- Compressed complete solutions: **79,095,223 bytes (79.1 MB)**.
- Closed-system master positions: **1,561**, including lower sectors and
  repeated positions across families; this is not a unique-integral count.
- Boundary constants remain unevaluated and kinematics-independent within
  each family's declared ordinary-point Laurent class.

## Timing and resource scope

The full campaign ran from 2026-09-06 09:45:31 UTC to
2026-09-06 10:16:42 UTC, or
02:45:31–03:16:42 PDT.

| Measurement | Time |
|---|---:|
| Full campaign elapsed, including failed attempts and recovery | **31.19 minutes** |
| Sum of successful per-family DE construction times | 107.02 minutes |
| Sum of retained successful finite-construction times | 27.68 minutes |
| Median successful DE + finite time for one family | 63.50 seconds |
| Largest successful DE + finite time for one family | 488.16 seconds |
| Additional final stored-result audit | 27.3 seconds |

Per-family times overlap; their sums are neither elapsed time nor CPU time.
Finite-construction time includes order determination, preparation and writing.
Optimization, earlier trials and report writing are outside the 31.2-minute
campaign measurement. Six families ran concurrently in one pool of eight
subkernels, sharing CPU IDs 0,1,6,7,8,9,18,19. Each Kira job used one thread.

The first pass constructed every DE and completed 80 finite solutions.
Eleven finite phases encountered the same insufficient pole support in their
homogeneous preparation. A general correction resolved all eleven; completed
DEs and solutions were reused. No full phase reached its 900-second limit.

## General implementation

The process enters through specifications and mathematical inputs. There are
no new family-name branches in the package.

- [Concurrent family driver](../Scripts/Transport/run_family_solution_campaign.py):
  one existing KernelPool, phase checkpoints, exact source snapshots, one Kira
  thread per family, failure continuation, and resumption without duplicate jobs.
- [Coefficient-order worker](../Scripts/Transport/solve_family_from_coefficient_orders.wls):
  matches master identifiers, combines duplicate upper-order demands, derives
  all required ranges, writes explicit solutions, and preserves completed data
  when an input or request is rejected. It can add missing lower output
  coefficients from already computed finite evolution.
- [Order determination](../FeynFacet/Solutions/Orders/DetermineOrders.wl):
  an upper-only request uses the complete evolution-entry valuation bounds
  together with all relevant boundary bounds. It does not mistake a bound at
  the boundary point for a bound away from it.
- [Finite integration preparation](../FeynFacet/Solutions/Preparation.wl):
  consistent elementary-function expressions, verified cyclic-vector
  reconstruction, and a bounded second pole-support ansatz at nonlinear divisors.
- [Fast inconsistency witnesses](../FeynFacet/DifferentialEquations/EpsilonForm/Multiquadratic/Screens.wl):
  constructs one supported left-null vector when only a sampled inconsistency
  witness is needed. The negative conclusion remains scoped to the tested
  target, coefficient field and finite-field images.

The final outputs retain the existing V2 differential systems and complete
compressed finite-solution format. Every finite integral definition and every
requested coefficient is stored. The standalone reader needs no DE solver;
this is not a deferred coefficient generator.

## Why the eleven failed preparations were resolved

For the representative quadratic divisor
`Delta = (v-w-1)^2 - 4w`, an algebraic horizontal section is

`h = (-Delta, 0, v-w-1)^T / (v Delta^(3/2)).`

The previous square-root ansatz with only one denominator factor Delta could
not contain its Delta^(-3/2) component, regardless of numerator degree. The
extra factor allows `sqrt(Delta)/Delta^2`. The polynomial numerator degree grows
with the denominator so the search does not discard the earlier candidate
space. A found invariant line is reduced and the quotient is treated by the
existing general code. Exact identities are required in both variables.

This is a bounded constructive improvement, not a completeness theorem or an
arbitrary-basis nonexistence criterion. Pro independently derived the section,
a triangular preparation and its logarithmic solution in
[review 05](../External/ChatGPT/Records/2026-09-06/05_nonlinear_divisor_pole_orders.md).

## Checks and remaining scope

The focused changes have 202 passing Wolfram assertions and five passing
Python execution tests. The final saved-result audit read all 91 solutions:
each passed the explicit-expression/coverage predicate, reported derived
sufficient orders, and contained every order required by transport of the
declared boundary class. Production construction retains inexpensive checks
against the original differential equations and the ordinary-point
normalization. No AMFlow comparison was claimed.

This completes the current **pre-endpoint coefficient-table** request.
Physical boundary values, continuation beyond the declared ordinary domains,
and order requirements from endpoint integration, renormalization and PDF
convolution remain separate work. Full strict epsilon-form canonicalization
of every family was not claimed. The earlier CF259 canonicalization trial
remains a valid partial result stopped on its time allowance.

## Data and reproduction

- [Result directory](../ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/README.md)
- [All-family timing and size inventory](../ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/summary.json)
- [Exact campaign specification](../ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/campaign-input.json)
- [Dated work and Pro-review record](../Archive/History/Design/OvernightStage1And2_2026-09-06.md)

The first-pass state and all attempt records are preserved. Re-running the
coordinator with the identical specification reuses the complete campaign.
A new independent regeneration uses a new output/scratch directory in its
explicit JSON specification and the same general drivers.
