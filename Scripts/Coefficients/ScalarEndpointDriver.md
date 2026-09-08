# Scalar endpoint family continuation

The single-family interface remains:

```sh
wolframscript -file Scripts/Coefficients/construct_scalar_endpoint_family.wls INPUT.wl OUTPUT_DIRECTORY
```

Its implementation is the reusable `RunScalarEndpointFamily[input, output]` in
`ScalarEndpointDriver.wl`. The function owns its state and returns a result
association without calling `Exit`. It uses the accepted endpoint system,
the coefficient order planner, `ExtendTangentialEndpointSystem` when needed,
the scalar projection, and the finite physical tangential solution.

The batch interface is:

```sh
wolframscript -file Scripts/Coefficients/construct_scalar_endpoint_families.wls CAMPAIGN_INPUT.wl OUTPUT_DIRECTORY
```

The configuration supplies `CoefficientInputFiles`, an
`AcceptedEndpointManifest` containing `AcceptedDirectories`, `CommonInput`,
and optionally `FamilyInputOverrides`, `Workers` (one through eight),
`FamilyTimeLimit`, `Resume`, and `DeferredFamilies`. Deferrals require an
explicit reason. By default `RequireAllAcceptedFamilies -> True` records
accepted families lacking a coefficient input as `MISSING_COEFFICIENT_INPUT`.
Setting it to false permits a named pilot selection and records the remaining
accepted families under `AcceptedFamiliesNotRequested`.

Each persistent worker loads the mathematical package once. Families are
assigned to available workers individually; physical input records are read
once and shared as immutable values. The launcher only closes the worker
pool it creates. `WorkerInitializationFile` can supply a controlled alternate
initialization, as used by the driver control-flow test.

Each family atomically saves `order_requirements.wxf`, `endpoint_system.wxf`,
`scalar_projection.wxf`, and `scalar_endpoint_solution.wxf` as those stages
finish. `mathematical_input.wxf` stores actual mathematical input and the
relevant implementation text captured at worker initialization; no hashes
are used. `stage_completion.wxf` associates completed stages with the input
generation, so stale artifacts from changed input cannot be reused. A timeout
preserves all completed stages for continuation. The separate accepted
endpoint directories remain the source of the normal gauge and physical
matching.

The final status distinguishes explicit physical coefficients, `MISSING_ORDERS`,
`UNRESOLVED_COEFFICIENT_CLASS`, `MISSING_ENDPOINT_SYSTEM`,
`MISSING_COEFFICIENT_INPUT`, `INPUT_FAILURE`, `COMPUTATION_FAILURE`,
`TIME_LIMIT`, `ABORTED`, and explicitly `DEFERRED` families. Every family has
a result in `campaign_report.wxf`; compact status counts are also written as
JSON. A deferral is never reported as a completed finite solution.

`Tests/Coefficients/t_scalar_endpoint_driver.wls` uses controlled constructor
mocks to test local state, checkpoint reuse, changed-input invalidation,
partial timeout recovery, failure categories, explicit missing/deferred
families, and reuse of two persistent workers. Its nine assertions passed in
3.9 seconds. The mathematical constructors have separate exact tests and
current-process pilots; this test does not replace those checks.


## Continue a sufficient order plan

continue_scalar_endpoint_from_order_plan.wls INPUT.wl OUTPUT_DIRECTORY
continues an accepted mathematical order plan without repeating rational
coefficient assembly. The input association supplies Family, OrderPlan,
EndpointSystemDirectory and PhysicalBoundaryConstruction. Optional EndpointSystem
selects an already extended normal system; it must have the same master basis
and normal gauge as the plan. Matching and Laurent bounds are read from
EndpointSystemDirectory. The driver retains the extended system, scalar
projection and final explicit physical solution as separate completed stages.

A common coefficient row may include exact pole parts of coefficients whose
remainders are treated elsewhere. Their explicit decomposition metadata is
propagated to the final merger. The master-coverage check and the separate
pole-piece check both have to pass; a family count alone is insufficient.
