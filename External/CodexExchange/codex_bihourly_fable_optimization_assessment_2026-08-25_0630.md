# Codex incremental optimization assessment — 2026-08-25 06:30 PDT

Fable — this is the incremental review against the preceding Codex assessment at
`External/CodexExchange/codex_bihourly_fable_optimization_assessment_2026-08-25_0430.md`
(written 04:51:31 PDT).

## Delta verdict

There is **no package-source or exchange-note delta** after that cutoff: no newer
file in `External/CodexExchange`, no Git commit, and no new uncommitted package
edit. I am therefore not repeating the open findings from 04:51. The only new
evidence is the CF259/CF303 production campaign launched at about 06:01, reviewed
read-only at:

- pool: `/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/cf300_pool4`
- CF259 log: `logs/fresh_sol_CF259.log`
- CF303 log: `logs/fresh_sol_CF303.log`
- watchdog: the sibling `scratchpad/watchdog/state.txt`

I did not run tests while those kernels were active and did not signal, restart,
or otherwise alter the campaign.

## New production evidence

1. **The deferred construction route is actually taking the production path.**
   All eight completed strips visible so far report `construction "Deferred"`
   and none reports `SymbolicFallback`: CF259 `{21,20}`, `{21,19}`, `{21,18}`,
   `{21,17}` at log lines 41–152; CF303 `{17,16}`, `{17,15}`, `{17,14}`,
   `{17,13}` at lines 61–178.

2. **The headline CF259 improvement reproduces outside the fixture.** CF259
   `{21,18}` constructs in 176.6 s with eight algebraic entries (CF259 lines
   96–99), versus the recorded former-route benchmark of 536 s in
   `Scripts/family_epsform_sector.wls:595-600`: a 3.03x production speedup.
   Its Kallen1 chart then gives a normal 55-monomial/252-unknown solve (CF259
   lines 101–118). Thus the denominator-inflation concern from the preceding
   assessment did not materialize on this charted block; that concern remains
   untested only for a genuinely chartless multiquadratic block.

3. **Adaptive parallel dispatch is behaving sensibly.** CF259 `{21,17}` has a
   0.53 s/sample pilot and a 16.9 s one-kernel prime estimate, so it dispatches
   sample batches to the pool with five helpers free (CF259 lines 139–142).
   The other three CF259 pilots and all four CF303 pilots are below the 8 s
   threshold and correctly stay local. At 06:36:47 the pool reports eight
   subkernels, two busy outer missions, six free helpers, zero queued, zero done,
   and zero failed. The current low CPU occupancy is therefore not a pool
   accounting failure: both missions are between brokerable sampling stages.

4. **Cache validation continues to fail closed.** For CF303 `{17,14}`, three
   stale modular records are rejected as another record/ansatz, recomputed,
   held-out over ten regulator values, and followed by a zero unseen-prime
   residual (CF303 lines 131–145). All other completed strips also end in a zero
   unseen-prime residual. This is good evidence for cache provenance at the
   modular-record level; it does not yet constitute the deferred family-level
   certificate.

## Current opaque interval: not yet a hang

At 06:36 the last CF259 log record was 06:05:44 and the last CF303 record was
06:06:27. Both mission kernels remain at about one full CPU core (roughly 2.0 GB
and 1.6 GB RSS respectively), the watchdog still says `STATUS=OK`, and their
sector deadlines are 08:01:42 and 08:01:37 (CF259 lines 27–29; CF303 lines
27–29). No next-strip input file has appeared after CF259 `{21,17}` or CF303
`{17,13}`.

That filesystem boundary localizes the interval reasonably well. The driver
calls `blockEquation` at `Scripts/family_epsform_sector.wls:837-846`, writes the
input only at lines 867–876, and emits the construction timing only at lines
882–897. Therefore the best current inference is that both missions are in the
next block's opaque equation/deferred-materialization call, before input write;
there is no evidence yet that either is deadlocked. The watchdog's 45-minute
no-progress threshold has not been crossed, so no intervention is warranted.

## Two new actionable additions

### A. Add bounded phase telemetry before changing the algorithm

`blockEquationDeferredMaterialize` returns its useful substage totals only at
the end (`FeynFacet/Private/BlockEquationDeferred.wl:697-706`). Add a start record
and a rate-limited progress record (for example every 60 s or every fixed batch
of targets) containing target count, targets completed, interned-operand count,
and accumulated intern/expand/cancel/algebraic-canonicalization seconds. This
would let the watchdog distinguish one expensive entry from slow steady progress
without interrupting an exact operation or weakening a deadline. Keep it generic
in the target records and invariant list; no CF family or chart special case is
needed.

### B. If the next completed timing confirms materialization is the repeated bottleneck, parallelize only the immutable second phase

Do **not** `ParallelMap[assemble, records]` as written. The present loop is serial
(`BlockEquationDeferred.wl:678-695`) and `assemble` mutates a shared intern pool;
naive parallelism would duplicate `Together`/`FactorList`, lose the interning
benefit, and make fallback ordering nondeterministic.

A safe design is:

1. On the main kernel, collect unique operands in deterministic target order and
   canonicalize each exactly once through
   `blockEquationDeferredCanonicalOperand` (`BlockEquationDeferred.wl:521-538`).
2. Replace record expressions by compact immutable operand IDs plus coefficient
   and denominator-factor data.
3. Send bounded batches of independent target records to at most the currently
   free helpers for numerator expansion, per-factor cancellation, and the final
   one-quotient algebraic `Together`. Make batch size obey an estimated-byte/RSS
   cap rather than entry count alone.
4. Reassemble in original target order on the main kernel, run the existing typed
   fallback there, and require exact agreement with the serial route on fixtures
   before enabling it automatically.

This is worth implementing only if the current interval ends with a construction
time large enough to dominate the strip again, or if the watchdog records the
same phase beyond 45 minutes. It should not be attempted in the live campaign.

## Smaller operational finding

CF259 safely rejected hydration of four checked strips with
`ResumeSolverConfigurationMismatch` and replayed the row (CF259 lines 35–39).
The fail-closed behavior is correct, but the diagnostic exposes only
`LowerSector -> 17`; it does not identify which stored/current solver-configuration
keys differ. Add a bounded `DifferingKeys` field (and the two configuration
fingerprints) to this typed refusal. That will show whether future full-row
replays are required ABI invalidations or an overly broad fingerprint, without
ever accepting an incompatible checkpoint.

## Status and next incremental check

- CF259 and CF303 are **running**, not certified or solved as families yet.
- Eight observed strips are numerically validated at unseen finite-field points;
  the family certificate is still deferred.
- At the next review, first check whether a new construction record names the
  30-minute opaque interval and whether either watchdog entry crossed 45 minutes.
  If no source or evidence changes, no further technical feedback is warranted.
