# To Fable — live reduced finite-field gauge pullback result

Date: 2026-08-29 (PDT)

## Bottom line

The characteristic-zero slowdown was real intermediate-expression pathology, but the earlier “1000x” comparison was not honest: it compared the full ~1080 s Maple normalization with only a ~0.01 s FLINT linear solve and omitted black-box evaluation, epsilon fibres, primes, CRT and lifting.

The complete live CF300 `(12,6)` result is now:

- inner strip solve: 831.4 s in this run, dominated by regenerating five stale modular artifacts at roughly 97–110 s/prime;
- new gauge pullback: 155.2 s for reconstruction, 160.5 s including the existing post-pullback modular strip residual;
- primes needed by the pullback: 3;
- source points per prime: 93;
- epsilon fibres per prime: 52;
- quotient-grade outputs: 32, of which 16 were active;
- inferred common reduced bounds: numerator `(7,6)`, denominator `(4,5)`;
- installed reduced gauge size: 32,415 leaves;
- result: accepted in `Kallen23`, branch signs `{1,1}`.

Thus the measured pullback-stage gain over the ~1080 s Maple result is **about 7.0x**, not 1000x. CF300 `(12,6)` is checkpointed as the sixth completed block of sector 12.

## Mathematical/algorithmic fixes required by the live gate

1. Quotient-grade compact evaluation was independently compared at a fresh source point against the exact compact pullback. All eight channels of the smaller `(12,11)` gate agreed modulo `1000003`; the black box is correct.
2. The initial coupled rational model transported the largest reduced denominator to every output but retained each output's reduced numerator bound. This is wrong. If output `i` has reduced degrees `(n_i,d_i)` and the common denominator has degree `D`, its common-denominator numerator needs the ceiling `n_i + D - d_i`. For `(12,11)` this changes the common numerator bound from `(4,3)` to `(5,4)` and makes the fit exact.
3. The denominator fit previously selected the first square prefix of an overdetermined system. It now selects independent equations from the whole matrix before the multi-RHS FLINT solve.
4. Denominator degree inference is a ceiling. The pilot can reduce the rectangular model if the ceiling is non-identifiable.
5. Deterministic degree/model refusals stop after the first prime rather than wasting the full prime schedule.

## Hybrid dispatch

Finite-field reconstruction must not replace the easy compact route blindly. Live `(12,11)` took 5.9 s by reconstruction while its exact compact pullback is ~0.4 s. `(12,7)` exceeds the bounded reconstruction degree cap, but unsimplified compact substitution itself is effectively 0 s and is accepted by the existing per-block modular residual. Production now uses:

1. bounded reduced finite-field reconstruction;
2. on deterministic degree/model refusal only, unsimplified compact composition (no `Together`, no Maple);
3. the same existing post-pullback modular strip residual in either case.

The `(12,7)` recovery took 27.4 s total because the degree probe cost remains; a future cheap pre-dispatch should avoid that probe when compact composition is clearly preferable.

## Resume semantics — important correction

The resume failure was caused solely by an execution whitelist: 8 backend threads and `FLINTAffineRREF` were rejected even though the connection and accepted blocks were unchanged. Merely widening that whitelist was the wrong fix.

The active driver resume gate is now mathematical only:

- family/sector and current connection content;
- block-boundary shape and exact banked block list;
- one mathematical acceptance record for each banked block.

Backend, thread count, cache layout, provider choice, method name, source revision and implementation provenance do not participate. Saved dlog forms are optional acceleration; malformed/incomplete forms fall back to exact sparse row propagation and the mandatory final family certificate.

## Direct-kernel parallelism defect found

Outside KernelPool, `KernelCount -> 8` used `ParallelMap`, and every subkernel inherited `BackendThreads -> 8`. The live run briefly launched three simultaneous 8-thread FLINT jobs (and can launch up to eight), oversubscribing cores and multiplying memory. The direct path now divides the native-core quota by concurrent Wolfram sample workers; with eight workers on this host it assigns two FLINT threads per worker. KernelPool already had this balancing logic.

## Files

- `FeynFacet/Private/FiniteFieldGaugePullBack.wl` — new general rank 0–3, two-variable compact quotient-grade reconstruction.
- `FeynFacet/Private/TransportCharts.wl` — finite-field/hybrid pullback integration and existing modular acceptance.
- `FeynFacet/Private/FiniteFieldStripSolve.wl` — direct-worker native-thread balancing.
- `FeynFacet/Private/FamilyRowGauge.wl` and `Scripts/family_epsform_sector.wls` — mathematical-only active resume admission.
- `Tests/Transport/t_finite_field_gauge_pullback.wls` — rank-zero, rank-two and in-frame integration coverage.

Pro's independent review is stored at `/home/maxzhang/FACET/Codex/General/ChatGPT/finite_field_gauge_pullback_response_2026-08-28.md`. It endorsed quotient-grade compact evaluation, 31-bit primes and multi-output FLINT, and warned against norm over-clearing; the live measurements confirm direct reduced common-denominator reconstruction is the right primary route here.
