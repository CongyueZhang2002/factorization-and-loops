# Stage 1 and stage 2 performance audit, 2026-09-05

The first optimization work should target coefficient representation and
repeated algebra. Finite-field elimination has already received substantial
optimization. The finite-integral recurrence is inexpensive on the profiled
families. Result validation, however, dominates one of the stage 2 examples.

This is an inspection with isolated prototypes. Production algorithms and
saved mathematical results were not changed. The all-family regeneration
has not started.

## Measurements

The audit inspected the V2 DE builder, diagonal/family epsilon forms, rational
and multiquadratic off-diagonal solvers, reconstruction, source-coordinate
re-expression, shared scheduler, and finite-solution/order code.

Three current master-range inputs were constructed successfully:

| Family | Total profiled construction | Order determination | Finite integral definitions | Final basis convolutions | Two full result predicates |
|---|---:|---:|---:|---:|---:|
| CF269 | 6.60 s | 3.39 s | 0.033 s | 0.630 s | 2.24 s |
| CF48 | 39.80 s | 6.74 s | 0.116 s | 8.78 s | 23.28 s |
| CF303 | 207.45 s | 85.50 s | 0.475 s | 0.684 s | 30.39 s |

These are instrumented profiles, not before/after speedup measurements.
Function timings can be inclusive; the columns are not an exhaustive
partition. CF48 overlapped the final portion of CF303. Loading, input reading,
output writing and earlier Kira/preparation runs are outside these timings.
The requests and saved preparations are those of the complete examples.

The user authorizes eight subkernels/eight CPU cores for subsequent
benchmarks and regeneration. Record and enforce that total allocation,
rather than giving eight native threads to each simultaneous family.

[Measurement scope](Stage1And2PerformanceAudit_2026-09-05_sources/measurement_scope.json)
and raw profiles accompany this report. Two early profiling attempts rebound
Wolfram symbols during source reload and failed; those runs are excluded.
The preserved profiler uses explicit package contexts and completed all
three examples.

## 1. Constant-linearity validation: immediate, measured improvement

In `solutionExpandedCoefficientsQ`, an auxiliary scalar scales every
integration constant, followed by `PolynomialQ`, `Exponent` and `Coefficient`
to test degree-one homogeneity.

For all 162 CF48 coefficients, the dedicated profile measured:

| Operation | Seconds |
|---|---:|
| PolynomialQ | **21.957** |
| Explicit-expression check | 0.045 |
| Exponent | 0.038 |
| Coefficient | 0.0014 |

This format check should not consume over half the construction time.
A conservative structural homogeneity check took **0.057 s** on the same
coefficients. Ten controls distinguished zero/linear expressions from
constant offsets, products, inverse constants and transcendental dependence.

The candidate propagates degree intervals through sums, products and
positive integer powers. C-independent expressions have degree zero and need
no polynomial analysis in their kinematics. Unexpected dependence is refused.
It may conservatively reject cancellations requiring additional
simplification; it is not a universal symbolic identity prover.

Use this check while retaining constant-index, order, explicit-definition
and dependency checks. Avoid scanning unchanged kernel definitions twice
when only the final C convolution was added. The writer currently invokes
the full predicate once more, outside the reported constructor timing.

Code: [FiniteMasterIntegralSolution.wl](../FeynFacet/Private/Transport/Solutions/FiniteMasterIntegralSolution.wl),
lines 548–569; predicate calls at 458 and 652;
[MasterIntegralSolutionFromOrders.wl](../FeynFacet/Private/Transport/Solutions/MasterIntegralSolutionFromOrders.wl).
Evidence: [linearity profile](Stage1And2PerformanceAudit_2026-09-05_sources/CF48-constant-check-profile.json)
and [candidate](Stage1And2PerformanceAudit_2026-09-05_sources/linearity-candidate.json).

## 2. Epsilon-order analysis: major triple-root algebra cost

Within CF303's order calculation:

- Preparing the supplied frame: **1.29 s**.
- Selecting/checking the base point: **21.62 s**.
- Basis valuations: **0.094 s**.
- Connection valuations: **52.33 s**.

`epsOrderOrdinaryPointQ` applies `Together` to full connection/basis entries
before testing their leading epsilon denominators at the point.
`epsOrderValuation` performs a generic zero test and `Together` before its
epsilon-independent shortcut. The planner calls it on every prepared
connection entry.

Treat large kinematic/algebraic/elementary coefficients as elements of a
coefficient field during epsilon manipulations. The finite constructor
already does part of this in `solutionRegulatorSeries`. Share the resulting
factor/series information between planning and construction.

Keep exact zero information needed to establish the triangular epsilon-zero
connection. Use conservative bounds only where a bound suffices.
Ordinary-point checks must still examine epsilon-expanded denominators:
checking a finite value at one nonzero epsilon would miss moving poles.

There is definite unused work in the constructor: `connectionBounds` is
computed at lines 332–334 even when a complete order plan was supplied.
It is used only in the subsequent `If[!AssociationQ[planned], ...]`.
Move that scan inside the branch that needs it. This changes no mathematics.

Code: [MasterIntegralExpansionOrders.wl](../FeynFacet/Private/Transport/Orders/MasterIntegralExpansionOrders.wl),
lines 45–56 and 337–351;
[LaurentBounds.wl](../FeynFacet/Private/Transport/Orders/LaurentBounds.wl), lines 11–20;
[FiniteMasterIntegralSolution.wl](../FeynFacet/Private/Transport/Solutions/FiniteMasterIntegralSolution.wl),
lines 47–85 and 332–348.

## 3. Share arithmetic inside scalar kernels

CF303 contains 2,260 scalar kernels, 2,645 finite integral definitions and
2,747 shared arithmetic expressions. The structural sizes are:

| Part | Wolfram ByteCount |
|---|---:|
| Kernel definitions | **2,891,471,344 bytes** |
| Complete solution | 3,173,125,928 bytes |
| Finite integral definitions | 10,618,968 bytes |
| Final master coefficients | 3,964,352 bytes |

These counts are not operating-system RSS; shared subexpressions can be
counted repeatedly. The complete disk result is 20.27 MB compressed.
Nonetheless, traversing and numerically substituting large repeated kernel
expressions is avoidable work.

The constructor shares complete kernel entries by exact identity. Its
`a[i]` arithmetic definitions serve the basis convolutions, but repeated
subexpressions inside kernel entries have no equivalent shared definitions.
Coefficient-wise conjugation and path substitution repeat common factors.

Retain factored coefficient arithmetic, identify common kernel
subexpressions before path substitution, and store all their definitions
in dependency order. Evaluate each once per quadrature node. This remains
a complete finite answer, with no lazy coefficient generator.

CF303 source-coefficient conjugation took **50.47 s**, including its series
work. Reduce duplicate series and derivatives and preserve sparse products.
`solutionLaurentCoefficients` also repeats `Expand` for each requested
order; extracting each coefficient array once is another candidate.

Code: [FiniteMasterIntegralSolution.wl](../FeynFacet/Private/Transport/Solutions/FiniteMasterIntegralSolution.wl),
lines 108–133 and 350–366;
[FiniteSolutionData.wl](../FeynFacet/FiniteSolutionData.wl).
Evidence: [stored sizes](Stage1And2PerformanceAudit_2026-09-05_sources/CF303-stored-size.json).

## 4. Source-coordinate reconstruction: primary stage 1 target

The comparable retained CF259 (27,23) run took **523.1 s** for the
finite-field solve and **428.3 s** for source re-expression and acceptance:
951.4 s combined. This was already 1.51 times faster than the earlier
comparable run. The 428.3 seconds include constructing the source-coordinate
answer; they are not just checking a finished expression.

Current opportunities:

1. **Batch numerator fits across epsilon samples.** The points, monomial
   support and independent row selection are unchanged. `FitNumerators`
   rebuilds these and solves separately for each sample. Use bounded
   multi-right-hand-side batches and the existing native backend for large
   matrices. A synthetic exact 81-monomial, 89-point, 32-output, 12-sample
   comparison took **0.157 s separately versus 0.031 s batched**, including
   setup and residual checks. Every coefficient agreed. This is not a
   measured hard-family speedup. A cached Wolfram `LinearSolveFunction`
   took about 0.75 s including setup and was worse.

2. **Retain completed samples during schedule growth.** Lines 867–879 refit
   all samples; lines 921–925 clear the point records and reevaluate them
   after extending the epsilon schedule. Reuse values and fits while the
   prime, points, supports, denominator model and normalization stay fixed.

3. **Batch quotient-algebra evaluation.** Re-expression calls interpreted
   `multiquadraticMultiply` for every point and grade product. Three
   independent roots give eight basis elements and 64 grade-pair products
   per multiplication. The main solver already has native batched sampling;
   re-expression does not automatically inherit it. Measure this component
   and move repeated evaluation into a packed/native batch.

4. **Reuse model preparation.** The initial validation plan, common model,
   wider common model and per-entry fallback can rebuild the same coordinate
   and support information. Preserve their immutable parts and slice data.

Keeping multiquadratic coefficients through row composition, regulator
factorization and final validation is a larger follow-up. Current code
sometimes composes radical expressions and then decomposes them again.
Changing only one consumer would move the cost elsewhere.

Code: [FiniteFieldBasisTransformationReexpression.wl](../FeynFacet/Private/EpsForm/FiniteField/FiniteFieldBasisTransformationReexpression.wl),
lines 178–240, 514–571, 790–925 and 1284–1447;
[MultiquadraticAlgebra.wl](../FeynFacet/Private/Core/Algebra/MultiquadraticAlgebra.wl), lines 71–85.
Evidence: [hard-block comparison](../Exchange/Codex/2026-09-04/18_hard_block_performance_acceptance.md)
and [numerator-fitting experiment](Stage1And2PerformanceAudit_2026-09-05_sources/numerator-reuse.json).

## 5. Further stage 1 and execution opportunities

**Share branch-check evaluations.** Production re-expression tests every
root-sign choice. Keep that mathematical check, but share invariant
polynomial and inhomogeneity evaluations across choices.
[OffDiagonalBasisTransformationBlock.wl](../FeynFacet/Private/EpsForm/OffDiagonalBlocks/OffDiagonalBasisTransformationBlock.wl),
lines 1580–1638.

**Use the available workers consistently.** The direct multiquadratic
follower routine returns concurrency one without the shared scheduler,
even if a standalone caller launched subkernels. Source re-expression
also requires that scheduler and caps its helpers at two. The production
pool launcher activates the scheduler, so this does not establish that
historical runs were serial. Measure with eight subkernels/eight total cores,
including the final period with only one hard family left.
Preserve the existing limits against competing families oversubscribing.
[MultiquadraticOffDiagonalBlockSampling.wl](../FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockSampling.wl),
lines 2416–2439; re-expression lines 1220–1248.

**Parallelize independent stage 2 families.** The new
[family driver](../Scripts/Transport/solve_master_integral_families.wls)
is serial. Use the same resource-aware scheduler after reducing per-family
memory, with isolated kinematic symbols.

**Remove repeated DE coefficient simplification.** The V2 builder collects
with `Together`, calls it on each extracted matrix coefficient, then repeats
it after invariant substitution. CF259 assembly took 35.62 s of 126.39 s;
CF303 took 37.59 s of 146.86 s. Their Kira closure times were 78.62 s and
96.93 s. Extract sparse coefficient rules once and normalize in the selected
coordinates. Kira reuse during closure is another candidate, but exact
basis closure must be retained.
[FamilyDifferentialSystemV2.wl](../Scripts/DifferentialEquations/FamilyDifferentialSystemV2.wl),
lines 801–847.

**Measure checkpoint writing.** Stage 1 repeatedly writes complete text
construction states. Separate immutable algebra from changing progress
records and consider compressed binary storage. The retained hard timings
do not isolate this enough to quantify its priority yet.

## Work order and all-family timing

1. Install the fast constant-linearity check and remove the unused repeated
   connection-order scan; measure constructor plus writer.
2. Share epsilon coefficient information across planning and construction.
3. Add shared kernel arithmetic with complete standalone finite evaluation.
4. Batch stage 1 re-expression and retain completed samples. Demonstrate
   a comparable hard-block improvement before changing production defaults.
5. Test CF269/CF48 as controls, CF265 as a larger case, CF259/CF303 for
   difficult algebra, and a regenerated CF300 hard case once V2 inputs exist.
6. Then regenerate all families using the recorded eight-worker/eight-core
   allocation, and report separate stage 1 and stage 2 outcomes.

For comparisons, hold fixed the full master basis, root set, coordinates,
ansatz/support, epsilon requests, validation method and resource allocation.
Record first-use and reused-work timings separately. Include DE input
construction, canonicalization, order determination, finite construction,
checks and writing; show queue wait and package startup separately.
The earlier 453.25-second five-family figure measures construction only.

Do not prioritize rewriting the finite-integral recurrence: it took less
than half a second for the profiled CF303 request. Do not weaken epsilon
requirements, introduce lazy outputs or indiscriminately reduce checks.

CF259 (27,19) also remains a mathematical limitation: the tested complete
degree-zero and degree-one ansatzes were inconsistent. Faster rejection
does not complete its canonical form. Treat alphabet/denominator completeness
separately from runtime optimization.

A finite solution obtained with a weaker preparation is not a completed
full dlog epsilon form. Keep distinct completion statuses and retain the
mathematical reason and consumed time for every unresolved family.
