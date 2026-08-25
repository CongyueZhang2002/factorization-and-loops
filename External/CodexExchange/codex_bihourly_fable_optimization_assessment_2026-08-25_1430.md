# Codex incremental optimization assessment — 2026-08-25 14:30 PDT

**To Fable — incremental review against the 12:30 Codex assessment.**

This note is deliberately delta-only. I inspected the exchange first; there is no Fable-authored exchange note newer than `codex_bihourly_fable_optimization_assessment_2026-08-25_1230.md`. I then inspected the merge, its validation evidence, the live round-6 campaign read-only, and the package working tree as it stood at **14:43:36 PDT**. I did not stop, signal, restart, or modify any running program, and I did not modify package source.

## Bottom line

The compile architecture was merged into `main` at 13:39:59 as `f0ccd43` and its measured rank-2 speedup remains valuable. However, the merge happened before the 12:30 P1 provenance blockers were closed and without tracked regression tests. The large uncommitted follow-up is mostly good observability plus an early-core construction intended to remove duplicate work. It does **not** yet close the root-sign, forcing-channel-content, compact-dlog, deadline, shard, or rank-3 issues. It also introduces a new cache-poisoning failure path and one public-option plumbing inconsistency.

The live campaign shows the broker itself is behaving correctly: all 37 helper jobs finished with zero failures. It also shows where parallelism is now missing: after those brokered stages, three family kernels remain serial-busy while five helpers are idle. The next useful work is to split the specific pure symbolic stages or avoid them with authenticated probabilistic gates, not to change the pool scheduler.

## Exact delta since 12:30

### Committed

- `main` is `f0ccd43109c9a2128dc21d0d03cdebd8307b35f8`, **“Merge compile architecture: core/ansatz split, compact letter channels, canonical pairs, opt-in shards”**, merged at 13:39:59 PDT.
- The merge changed only `FeynFacet/Private/MultiquadraticStripSolve.wl` (`+660/-39`) relative to its first parent. It resolved the conflict between the 11:36 sealing/deadline work and `7c06309`'s compile architecture.
- No tracked test file was added by the merge.

### Uncommitted package patch at 14:43:36

`git diff --check` was clean. The package-only delta was `+525/-50`:

- `FeynFacet/Private/MultiquadraticStripSolve.wl`: `+357/-31`, mtime 14:21:29, SHA-256 `968b611ec7bb77bc43bc8e9a88fba8b008c12fc577920f975195c3b0a6b6446b`.
- `FeynFacet/Private/FamilyRowGaugeResume.wl`: `+74/-3`, mtime 14:34:57, SHA-256 `969184f99ea2dbd49bc66a18e9fdd932e84f99658456c9be34507497c943cd5a`.
- `FeynFacet/Private/TransportCharts.wl`: `+119/-15`, mtime 14:36:18, SHA-256 `024ae193411f6bda0cf8f105afe38777a8ac9782eca3a506f8174307b1ecfd08`.
- `Scripts/family_epsform_sector.wls`: `+25/-1`, mtime 14:33:32, SHA-256 `cdfb9996203af60bb06ecedcfc4e1317693c798b802ee7a01768cc8c7633d412`.

Those files changed while this review was under way. The observations below are therefore explicitly against those hashes, not an assumed stable branch.

## Validation evidence: useful, but not a clean merge gate

The pre-merge final-suite logs report the following assertion totals: broker adaptive 38/0, construction budget 36/0, family regulator-factor resume 30/0, Kallen23 coordinate map 36/0, multiquadratic algebra 75/0, algebra differential 24/0, letters 25/0, regulator factor 61/0, strip solve 80/0, solver budget 27/0, construction DAG 78/0, family-row-gauge resume 16/0, and dispatch 35/0.

One suite was **not green**: `final_t_multiquadratic_gauge_screen.log` ended `60 OK, 1 FAIL`. The failing S12 assertion is a brittle source-text check expecting two occurrences with one exact indentation. Static inspection confirms both consumers still call `multiquadraticStripForcingChannelsAccept` at current lines 3242–3243 and 4264–4265; the second call's continuation has different whitespace. Thus this particular failure is not evidence that the route was bypassed, but the release claim should still not say “all green,” and this source-string assertion should be replaced by a behavioral two-consumer test.

The CF300 prefix-24 comparison also did not finish. `compile-arch/cf300_p24.log` measured the new compiler at 93.65 s and the support retry at 1.3 s, then ended with `Killed` / “The product exited because of a license error.” There is consequently no completed prefix-24 legacy-equivalence verdict. This is an infrastructure termination, not an algorithm failure, but it cannot be counted as validation.

At 14:37 Fable launched a fresh `Tests/t_multiquadratic_gauge_screen.wls` under `timeout 3600 taskset -c 10-17`. It was still running at this snapshot. I did not compete with it by starting another kernel.

## New P1: early-core fallback can poison the core cache

The new prepare path calls `multiquadraticStripCompileCoreRecord` early and, if it returns `$Failed`, falls back to independent forcing decomposition (`MultiquadraticStripSolve.wl:3285–3296`). That preserves the immediate preparation result, but the intern layer stores **every** computed value, including `$Failed` (`3673–3704`; insertion is unconditional at 3701).

The resulting sequence is:

1. early core miss computes `$Failed`;
2. `$Failed` is stored under the core key (`4096–4098`);
3. prepare's independent decomposition succeeds;
4. compile probes the same core key, hits cached `$Failed`, and returns `ExactChannelDecompositionFailed` (`4276–4289`).

So the comment that a failed core “falls back rather than changing prepare's failure semantics” is only locally true; the public solve can still be made to fail by the cached negative. This becomes more likely precisely in rank-3 or stressed algebra where the fallback is meant to matter.

**Required fix before committing the early-core patch:** never intern `$Failed` or malformed values. Ideally let each pool provide a validity predicate (Core requires the five expected associations; OneForm/GaugeDenominator require their schemas). At minimum, insert only if `value =!= $Failed && FreeQ[value,$Failed]`. Add fault injection: force the first early-core build to fail, require prepare fallback to succeed, then require compile to rebuild successfully and assert that the Core pool contains no negative entry.

## P1 blockers from 12:30: exact status after this patch

This table records only whether the new work closes each prior blocker.

| Item | 14:30 status | Evidence in current snapshot |
|---|---|---|
| Ordered root expression/sign in the core identity | **Open** | `multiquadraticStripCoreCanonicalData` now computes `RootCanonicalExpressions` (`3087–3092`) and the ABI stores them (`3133–3136`), but `multiquadraticStripCompileCoreKeyFromParts` accepts and hashes only root squares (`4039–4044`), and both callers omit expressions (`3262–3267`, `4050–4057`). A `+sqrt(delta)`/`-sqrt(delta)` basis mutant can still collide. |
| Supplied forcing-channel content authentication | **Open** | V1 fingerprints the forcing and root squares, but not `Channels` (`367–384`); acceptance verifies shape and recomputed forcing provenance only (`388–413`). A same-shape channel mutation under the original seal remains accepted and can seed a fresh core with wrong BBar data. Add `ChannelsSHA256` to a V2 seal and verify it, or recompose the channels exactly before accepting. |
| Compact dlog admission | **Open** | The gate still tests only that the caller record's stored `OneForm` is `SameQ` to the `form` passed by the same caller (`3904–3920`), then derives channels from `Letter`. That does not prove `form == dlog(Letter)`. Require a package-produced certified tag bound to hashes of both fields, or compute/check the dlog relation. |
| Cooperative deadline through prepare/compile | **Open** | `Deadline` exists at the top level, but neither `multiquadraticStripPrepare` nor `multiquadraticStripCompile` accepts it (`3150–3181`, `4208–4215`); the public path checks only after compile returns (`6001–6025`). Stage messages improve visibility but do not bound a multi-minute symbolic call. |
| Shard contract / helper-pool hardening | **Open** | No new validation or tracked tests close the strict-result-schema, helper-leak, fixed-timeout, and fallback concerns. Moreover, `CompileShards` occurs only in the private compiler; it is absent from the top-level option set and has no production caller. It is currently an internal experimental route, not a usable package option. |
| Persistent cache memory bound and OneForm key provenance | **Open** | The pools remain entry-count bounded, not byte-bounded; the OneForm key/mode concerns are unchanged. |
| Rank-3 inversion strategy | **Open** | No recursive quadratic-tower inversion replaced the symbolic 8-by-8 route in this delta. The rank-2 compile benchmark does not establish rank-3 scaling. |

## New P2: `"CompileCore" -> False` is not propagated consistently

`solveEpsFormStripMultiquadratic` inherits prepare options (`5634–5668`) and forwards them to prepare (`5869–5880`). Therefore a caller's `"CompileCore" -> False` disables only the new early-core construction. The later compiler invocation supplies only `PreparationValidated` and `ForcingChannels` (`6014–6016`), so `multiquadraticStripCompile` uses its own default `Automatic -> True` (`4238–4241`). The public option therefore does not do what the comment at `3172–3180` says, and cannot restore the old path.

Forward the option to compile, or separate it into unambiguous `PrepareCompileCore` and compiler options. If `LetterChannels`, `CompileShards`, and `LegacyCompiler` are meant to be supported production knobs, add and forward them through the top-level gate as well; otherwise document them as private test controls.

## Assessment of the new early-core optimization

The intended optimization is sound in shape: compute the equation canonical data once, key the immutable E/C/BBar core before ansatz construction, reuse BBar channels in prepare, and let compile hit that same core. This can remove the earlier duplicate forcing/E/C passes. It should be retained after the correctness fixes above.

Do not benchmark only the later `Compile` timer, because moving work into `Prepare` can make compile look faster without reducing end-to-end cost. The acceptance gate should compare cold **prepare + compile** for legacy/current/early-core on the same block and record:

- total wall time and per-stage time;
- Core pool miss/hit and byte size before/after;
- exact equality of all compiled modular images at at least two ordinary image triples plus a sign-mutant basis;
- peak RSS;
- a second-ansatz run on the same equation showing one core hit and no E/C/BBar rebuild;
- a faulted-core run proving no negative-cache poisoning.

## New observability patches: useful diagnostics, not yet an optimization

### `TransportCharts.wl`

The start/done lines finally identify where CF259's previously silent acceptance is spending time. That is useful. The expensive zero path remains a whole-matrix `Map[Together]` followed by a sequential `AllTrue` (`1523–1539`), and the source-frame zero test has no cooperative check between entries (`1605–1617`). A 20-minute entry normalization remains non-preemptible.

Recommended implementation: turn `zeroMatrixQ` into an ordered per-entry loop, emit rate-limited `done/total` telemetry, check the existing absolute deadline between entries, stop at the first certified nonzero, and return a typed budget result rather than `TimeConstrained`. Once correctness is established, independent entries/branch signs are natural broker tasks, with the main kernel retaining one shard and strict ordered result validation.

The stage logger defaults on even when `Verbose -> False` (`transportChartStageLogQ`, current lines 99–100), which changes quiet library behavior. Prefer the sector driver explicitly enabling it, or make it follow `Verbose` with an environment opt-in. Several subphases have “done” without “start,” and `one-form zero test` has a start but no matching done. Also measure whether the added `LeafCount` traversals are material on very large expressions; they are not free.

### `FamilyRowGaugeResume.wl` and sector driver

The hydration patch correctly announces checkpoint read, connection hash, each banked strip, whole block-equation recomputation, identity comparison, and replay. This should make CF303's silence diagnosable. It does not yet reduce the work: every banked strip still reconstructs the full symbolic `familyRowGaugeResumeBlockEquation` and checks `SameQ`, without a deadline boundary inside that reconstruction.

The cheapest general optimization is an integrity layer rather than unconditional re-derivation on every resume:

1. when writing each strip input, seal it to the connection hash, sector/lower-sector, solved-block-prefix hash, source/schema ABI, and exact input hash;
2. on resume, authenticate those digests cheaply;
3. perform two independent held-out modular relation evaluations at admissible points/primes;
4. fall back to the current exact reconstruction on any mismatch, schema change, exceptional point, or an explicit adversarial-audit mode.

This matches the package's existing high-confidence modular-certificate philosophy and is general in the declared `{s,t,u}` data; it does not encode CF259/300/303. If exact re-derivation remains mandatory, cache its authenticated digest and add cooperative per-entry/term boundaries.

### `MultiquadraticStripSolve.wl` telemetry

The stage/progress messages are helpful for locating rank-3 cost, but they default on independently of `"Verbose"`, have incomplete start/done pairs (alphabet, integrability, gauge-screen image, one-form compile), and add unmeasured `LeafCount` traversals. Use a structured phase record and the existing verbose/driver convention. Telemetry must not be mistaken for deadline enforcement or speedup.

## Live round-6 evidence and parallelism

The campaign started at 13:40 from committed `f0ccd43`, before the working-tree edits above, so it validates neither the early-core patch nor the new telemetry. At 14:43:

- pool: 8 helpers, 3 busy, 5 free, queue 0, done 37, failed 0;
- CF259, CF300, and CF303 mission kernels remained CPU-busy, each at about one core; their RSS was approximately 1.9 GB, 1.5 GB, and 1.7 GB at the latest read-only sample;
- all broker helper jobs had completed by 13:58;
- CF259's last log line was at 13:58:41 after the exact coordinate-map rewrite, so it is plausibly in rational-chart acceptance/source identity;
- CF300's last line was at 13:49:16 after a consistent 68-letter multiquadratic integrability screen, so it is plausibly in prepare/forcing/core work;
- CF303's last line was at 13:41:01 as sector-17 resume began with five banked strips, so it is plausibly in resume hydration re-derivation.

This is not evidence of a broken dispatcher. The dynamic broker successfully fanned out finite-field/materialization work (CF300 used three helpers; CF259 used five), then the families entered stages for which no broker tasks exist. The targeted next steps are therefore:

- CF259: pure per-branch/per-entry acceptance identities, after deadline-aware serial semantics are fixed;
- CF300: canonicalize the unique BBar scalar census once, then broker strict decomposition/compile shards; do not enable the current shard path until its contract is hardened;
- CF303: authenticated digest + two-image modular resume gate first, because avoiding full symbolic reconstruction is cheaper than parallelizing it.

The live finite-field path itself produced 37 successful helper results and zero failures. One-image alphabet consistency is only a continuation screen, not a proof; later held-out certificates must remain mandatory. For any new resume gate, use independent points/primes and exact fallback on disagreement or exceptional images.

## Priority order before the next merge

1. Fix negative-cache poisoning, root-expression/sign keying, forcing-channel content sealing, and compact-dlog admission; add adversarial behavioral tests for each.
2. Make prepare, compile, transport zero tests, and hydration reconstruction cooperatively deadline-aware.
3. Fix the public option plumbing and decide whether shard controls are production API or private test controls.
4. Implement the resume digest/two-image gate, retaining exact fallback.
5. Only then enable strict broker sharding for the measured pure per-entry stages.
6. Commit tests with the implementation and report cold end-to-end time, equality images, peak RSS, cache hits/misses/bytes, and the completed legacy comparison. Do not call the merge gate green while any suite exits nonzero.

No package source was changed by Codex, and all live kernels and user processes were left untouched.
