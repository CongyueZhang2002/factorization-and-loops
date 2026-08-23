# Assessment and integration order

## Outcome

The defects are real and independent of the triple-root implementation.
They should be fixed before promoting either the native affine-RREF discovery
backend or a direct multiquadratic solver.

The staged candidate enforces these contracts:

1. `"Backend"` is exactly one of `Automatic`, `"Wolfram"`, or `"FLINT"`;
   `"BackendThreads"` is an integer in 1--4.  Unknown values are typed
   failures, never aliases for `Automatic`.
2. `Automatic` retains the historical size-gated native attempt and may fall
   back to Wolfram, but records `BackendRequested`, `BackendUsed`,
   `BackendFallbackReason`, and `BackendFailure`.
3. Explicit `"FLINT"` fails closed when its binary is unavailable, its
   process/parser fails, or its square-core certificate fails.  It never
   calls Wolfram `LinearSolve` as a fallback.
4. A reusable elimination plan has an exact key set, schema/version,
   preparation fingerprint, solver provenance, SHA-256 payload fingerprint,
   exact ansatz metadata, and strictly increasing unique row/column
   selectors in range.  Rank/nullity/layout identities are checked before
   any selector is indexed.
5. An invalid plan under `Automatic` is not reused; the code takes the full
   verified Wolfram elimination path and records the typed rejection.  Under
   explicit `"FLINT"`, absence of a validated constrained plan is a typed
   failure rather than an implicit Wolfram solve.
6. `_unsolved.wl` receives a bounded typed solver-failure summary.  Only a
   fixed diagnostic whitelist is admitted; every value is capped at 4096
   bytes, while gauges, samples, matrices, and inner solutions are excluded.
7. Every finite-field-first strip summary/checkpoint receives an exact,
   sealed `SolverConfiguration`: route, coefficient field, final-check mode,
   requested backend/thread count, frame fingerprint, ABI versions, and
   SHA-256 hashes of the solver source files.
8. Resume compares the complete configuration with `SameQ` before replay.
   Missing configuration is accepted only for zero forcing or for the
   historical multiquadratic rational-chart/rational-frame route.  A legacy
   direct-rational checkpoint is recomputed.  A present malformed
   configuration is never treated as legacy.

## Why these choices

- A bad reusable plan is an optimization failure, not evidence that the PDE
  has no solution.  Falling back to the full, all-row-checked Wolfram path is
  therefore correct for `Automatic`.
- An explicit native backend request is an audit assertion.  Falling back
  would make backend comparisons and production provenance unreliable, so it
  must fail closed.
- The constrained native solution is checked against `core.X == rhs mod p`
  before acceptance or fallback.  The existing all-original-row residuals
  remain mandatory afterwards; the new check does not replace them.
- Solver versions alone are easy to forget during edits.  Source hashes make
  the checkpoint binding exact.  This deliberately invalidates replay after
  any solver-source change, including a seemingly harmless edit; recomputing
  a row is preferable to silently changing its route.
- The narrow legacy exception prevents current algebraic rational-chart work
  from being discarded while ensuring that a future direct-multiquadratic
  checkpoint cannot silently replay through that route.

## Additional required integration detail

Before declaring the hardening complete, bind each modular interpolation
artifact to both the sealed plan fingerprint and the backend configuration.
The current production reader checks record fingerprint, degree offset, and
support shell, but not these two new provenance fields.  Mathematically an
old interpolation is still guarded by later residuals, but retaining it would
leave an audit gap.  The minimal extension is:

- write `EliminationPlanFingerprint` and `BackendConfiguration` beside
  `RecordFingerprint`;
- require exact equality on read;
- treat an old artifact as stale and recompute it (do not infer a legacy
  configuration);
- retain per-sample `BackendUsed` telemetry so an `Automatic` run records
  mixed FLINT/Wolfram execution if a fallback occurred.

This artifact-binding add-on should be made in the final rebase because the
currently running source-pinned missions may still consume the old artifact
shape.

## Integration order

1. Wait for every source-pinned CF300 discriminator/cache/benchmark mission
   to be terminal.  Recompute the four source hashes in `README.md` and rebase
   the templates if Fable changed any target.
2. Integrate backend option validation and telemetry only.  Run the existing
   finite-field tests plus the backend half of
   `run_finite_field_backend_plan_adversarial.wls`.
3. Integrate plan sealing/strict validation.  Deliberately confirm that an
   old or mutated plan takes the full Wolfram path under `Automatic` and that
   all original-row checks still pass.
4. Add modular-artifact plan/backend binding described above.  Test stale
   artifact rejection without deleting or mutating the original fixture.
5. Integrate bounded solver-failure persistence.  Force
   `NoRationalStripChart`, `$Failed`, an invalid backend, and an oversized
   whitelisted diagnostic; inspect the serialized `_unsolved.wl` byte count
   and exact allowed keys.
6. Integrate `SolverConfiguration` creation and resume comparison.  Run the
   configuration adversarial driver and the existing row-gauge resume suite.
7. Only then consider enabling a new plan-discovery backend or direct
   multiquadratic route.  Each needs a new route/ABI value; it must not reuse
   `RationalChartFiniteField` provenance.

## Required post-integration tests

- `External/CodexExchange/finite_field_backend_hardening_2026-08-23_xh/test_hardening_candidates_static.sh`
- `External/CodexExchange/finite_field_backend_hardening_2026-08-23_xh/run_finite_field_backend_plan_adversarial.wls`
- `External/CodexExchange/finite_field_backend_hardening_2026-08-23_xh/run_solver_configuration_resume_adversarial.wls`
- `Tests/t_finite_field_constrained_solve.wls`
- `Tests/t_finite_field_round2.wls`
- `Tests/t_finite_field_preparation.wls`
- `Tests/t_family_row_gauge_resume.wls`
- one real cached rational strip and one real algebraic rational-chart strip,
  each replayed with exact gauge/form `SameQ` and unchanged artifact hashes.

The two dynamic drivers are serial and contain no `LaunchKernels`,
`ParallelMap`, `RunProcess`, or shell escape.  They were not run during this
staging task because Wolfram launches were explicitly prohibited.

## Non-goals

- This does not promote the External FLINT affine-RREF protocol.  That remains
  a separate `PlanDiscoveryBackend` with its own fail-closed CFFR certificate.
- This does not solve the direct-channel dlog-potential gap.
- This does not bless `FamilyRowGaugeFiniteField.wl` as a shared
  multiquadratic ABI.
- This does not modify any package or production script.
