# Checking omitted epsilon coefficients

The sufficient-order planner is supplemented by an optional, independent
forward check. For an input known through epsilon^m, the check represents the
unknown tail as

```text
A(epsilon,X) = A_truncated(epsilon,X)
             + epsilon^(m+1) R_A(epsilon,X).
```

`R_A` is an arbitrary function analytic in epsilon. Its kinematic dependence
is retained. Each independent input, including each matrix entry, has a
different label; repeated uses of the same input retain the same label.
An arbitrary function protects all omitted orders. A single constant marker
can miss a higher omitted order after differentiation or a cancellation.

If any remainder can contribute to the requested output range, the checked
calculation stops with `InsufficientEpsilonOrdersDetected`. No extra physical
integral coefficient is evaluated merely to perform this check.

## Running the production checks

After loading `Addon/Load/LoadFACET.wl`:

```wl
checked = WithEpsilonRemainderChecks[
  ConstructMasterIntegralSolution[system, request]
];
checked["EpsilonRemainderAudit"]
solution = checked["Result"];
```

The same wrapper applies to `EvaluateBoundaryIntegralSystem`,
`ConstructSharedBoundaryCoefficientDefinitions`,
`AssembleFiniteMasterIntegralDensity`, the tangential endpoint construction,
and `ExtractEndpointDistributions`. The enabled checks cover:

| Stage | Operations checked |
|---|---|
| 2 | Prepared-connection gauge products; finite DE recurrence; both basis transformations; the intermediate matrix truncation; evolution times ordinary-point boundary constants |
| 3 | Exact boundary-reduction multipliers; actual returned integral orders; known amplitudes and the shared boundary connection; tangential physical matching; SubTropica's returned series orders |
| 4 | Finite coefficient series and prefactors; coefficients times masters; tangential endpoint projection; distribution convolutions and exact endpoint moments |

The wrapper returns the mathematical result separately from its audit.
Debug symbols never enter saved solution definitions. Normal calls have the
checks disabled. The finite-density coefficient pool propagates the wrapper settings to its workers and combines their audits. Other parallel callers must place the wrapper **inside each worker** and retain its report: a dynamic setting alone on the main kernel does not enable checks in subkernels.

`"TruncationOrderShift" -> -1` deliberately moves finite remainder cutoffs
down one order, for testing the detector. It changes the audit, not the
production expressions. `"TimeLimitPerCheck"` defaults to 10 seconds for an
individual symbolic check. A timeout cannot produce a passed check.

Inspect `"ChecksByStage"` as well as `"Status"`. Cached or uninstrumented work
with no executed checks reports `"NoChecksExecuted"`. A failed underlying
calculation reports `"CalculationFailed"`. A passed report covers only the
operations actually executed within that wrapper, not earlier cache creation.

## How the check stays inexpensive

For Laurent products the implementation propagates independent unknown tails
using their lowest possible output orders. For example, the tail of A times B
can first contribute at `m_A + 1 + lower_B`. Products containing two or more
unknown tails are also covered. This is a conservative version of multiplying
the labelled remainders, without constructing large symbolic coefficients.
It does not call the sufficient-order planner or assume cancellations between
independent omitted coefficients.

Exact epsilon-dependent multipliers are checked by direct series expansion
with the arbitrary remainder function. Endpoint delta coefficients are checked
against the exact moment

```text
integral_0^Z z^(c-1) log(z)^p dz = (d/dc)^p (Z^c/c),
```

continued meromorphically in c. This independently detects the extra epsilon
poles from endpoint integration; checking only an interior value of z would
miss them. The production moment coefficient formula is separate from this
derivative calculation.

A finite series whose retained coefficients vanish still has an unknown tail.
Only an exact zero factor removes a dependency. When an unsimplified source
coefficient raises a possible order alarm, the DE audit attempts an exact
zero identity, expanding shared kernels only as needed. It never uses the
planner's claimed valuation as proof of that identity.

## Auditing saved DE solutions

```wl
CheckMasterIntegralSolutionEpsilonRemainders[solution]
```

This checks the saved recurrence, basis convolutions and original boundary
orders using construction metadata. It neither solves the DE nor evaluates
integrals. The command-line driver accepts a solution file, or a directory
whose `solution.wxf` files should all be checked:

```sh
wolframscript -file Scripts/Transport/check_solution_epsilon_remainders.wls \
  SOLUTION_FILE_OR_TREE PROCESS/Results/Validation/EpsilonOrders.wxf
```

This is an order-coverage audit, not a verification of the numerical or
symbolic values of every stored coefficient, nor a retrospective audit of
subsequent physical boundary substitutions and stage-4 assembly.

## Checking a new symbolic calculation

`CheckEpsilonTruncation` supplies a callback with marked expressions. For
example, this fails because the missing epsilon^2 coefficient reaches the
finite term:

```wl
CheckEpsilonTruncation[
  Function[values, values["A"]/eps^2],
  <|"A" -> <|"Expression" -> 1 + eps,
               "KnownThroughOrder" -> 1|>|>,
  eps, {0, 0}
]
```

An input may additionally declare `"Variables" -> {x, y}` or
`"ExactInEpsilon" -> True`. The callback must return a scalar expression or
list of expressions and **preserve the remainders in intermediate operations**.
An intermediate `Normal[Series[...]]` can erase the evidence. Production hooks
avoid that problem by auditing cuts separately from their finite coefficients.
New finite convolutions should use these hooks at their actual cutoffs.

The check assumes the declared Laurent lower bounds and the endpoint
regularity/uniformity class. It does not prove them, fix analytic continuation,
or inspect undocumented truncations inside an external integration program.
These remain distinct mathematical requirements.

## Validation and a corrected boundary expansion

The core tests cover independent labels, exact cancellations, inverses,
epsilon and kinematic derivatives, products of omitted tails, exact zeros,
and failed or uninstrumented calculations. Integration tests deliberately
remove one needed order in each of stages 2, 3 and 4. Ordinary output
coefficients agree exactly with checks disabled.

The implementation also corrected known boundary-amplitude expansion in
`ConstructSharedBoundaryCoefficientDefinitions`: the needed amplitude order
is the output order minus the matching-matrix entry's Laurent lower bound.
For example, obtaining the finite coefficient of `(1+eps)/eps` needs the
amplitude through epsilon^1, even though the output ends at epsilon^0.
The stored singular-boundary matching snapshot is unaffected by this specific
bug: its sole known amplitude multiplies matrix entries starting at epsilon^2
or higher, while the old amplitude expansion already extends through
epsilon^4, the largest requested ordinary-point order.

The current 91 saved DE solutions all pass the audit. The checks took 20.36
seconds in aggregate, excluding package and file loading, with zero new
integral evaluations. Nine initial alarms were resolved by exact identities
for unsimplified zero coefficients. CF300 takes about 0.33 seconds after
avoiding repeated polynomial expansion. The retained report is
`Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/EpsilonRemainderChecks/AllSavedSolutions.wxf`.
This run does not assert that the existing stage-3/4 artifacts were regenerated
or completely reaudited.

## Auditing saved boundary and endpoint orders

The general driver `Scripts/Validation/check_saved_epsilon_orders.wls MANIFEST.wl REPORT.wxf` checks saved stage-3 or stage-4 inputs without integration. Paths in a manifest are resolved relative to that manifest; paths in a referenced assembly request are resolved relative to that request. Reports are separate from every input, and a failed or empty audit exits nonzero.

For stage 3, provide `Stage -> 3`, a `Reduction` record (or path) with `DimensionalRegulator`, `ReductionMatrix`, and `BoundaryIntegralLaurentLowerBounds`, a list of `{amplitudeIndex, epsilonOrder}` in `RequestedAmplitudeCoefficients`, and an association `EvaluatedBoundaryIntegrals` mapping integral indices to records (or paths) containing the actual `LaurentCoefficients`. Exact analytic inputs can first be expanded algebraically to an explicit finite table; no new integration is required.

For stage 4, provide `Stage -> 4` and `AssemblyInput` pointing to the ordinary endpoint-assembly request. The audit checks the actual interior master/coefficient index ranges, missing orders within those ranges, complete master and separated-pole coverage, and the actual endpoint coefficients against exact regulated moments. It requires the stored uniform-tail declarations. It does not replay earlier tangential DE construction or establish the declared Laurent lower bounds and uniformity class.

Repeated identical exact multiplier checks are reused within one wrapper. Source occurrences remain counted independently, and failures retain the responsible source. This avoids checking the same endpoint moment hundreds of times.

The current process demonstrations and negative driver test are retained in [Stage4Optimization](../Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/Stage4Optimization/README.md). All 345 masters and 92 endpoint contributions pass the saved stage-4 audit; all 33 boundary inputs pass the stage-3 order audit. These results concern order sufficiency, not the separately incomplete independent boundary-value reference coverage.
