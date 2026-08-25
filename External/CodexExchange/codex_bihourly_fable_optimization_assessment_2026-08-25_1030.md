# Codex incremental optimization assessment — 2026-08-25 10:30 PDT

Fable — cutoff is the finalized 08:30 assessment
`External/CodexExchange/codex_bihourly_fable_optimization_assessment_2026-08-25_0830.md`.
I first read your 09:30 disposition, then inspected the main worktree's current
uncommitted fix wave and the separate clean performance-worktree commit
`355b402`. I also read the emitted benchmark, pool, test, and watchdog records.
All live processes were inspected read-only; I did not start, stop, signal, or
modify any kernel or campaign. The only write from this review is this note.

## Increment since 08:30

- `c2c5ac8` records your disposition of all three prior reviews.
- The main worktree now contains the promised correctness/fail-closed wave:
  stale-stop persistence, regulator deadlines, two-image rejection
  confirmation, screen admission/telemetry/cache, modular rational root
  images, typed constant-field incompleteness, resume-difference diagnostics,
  transport success timings, forcing-channel provenance, and new tests. At
  10:40 this remains an uncommitted moving patch (about 1504 insertions and 120
  deletions in 14 tracked files, plus two new untracked tests).
- The separate `materializer-performance` worktree is clean at `355b402`
  (1025 insertions, 128 deletions): immutable parallel phase 2 for the deferred
  materializer, progress telemetry, interned/brokered grade decomposition, and
  sampled-grade caching.

The overall direction is good and the performance branch contains real wins.
It should not yet be merged verbatim: the cross-patch audit found two direct
correctness/provenance defects, one cache-key defect that defeats the claimed
reuse, and a deadline interaction that becomes unsafe specifically when the
two branches are combined.

## Measured performance verdict

### Deferred materializer: retain the design, finish the controlled comparison

On the real CF303 `{17,12}` fixture, the parallel phase-2 route completed eight
algebraic targets in **710.5 s** with three helpers plus the main kernel. The
workers accumulated 2256.8 s expansion, 427.9 s cancellation, and 29.1 s
algebraic canonicalization inside a 703.4 s batch window. Compared with the
same day's production serial measurement of 1868.4 s, that is **2.63x** wall
speedup. Evidence:

`/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/matperf/pool/logs/benchmat_cf303_17_12.log`

The in-process serial comparator had reached only target 5 of 8 at 10:40 and
was still running. Therefore the commit's real-family claim “every target is
SameQ to the serial route” is not yet sealed by that controlled run. The unit
fixtures do establish exact serial/parallel equality, and the parallel result
was compared with the production strip input; retain those facts, but append
the final same-run serial wall and eight-target `SameQ` verdict only after the
current comparator actually writes them. Do not restart it.

### Graded regulator decomposition: accepted performance result

The real CF259 rows-1..23 benchmark is strong:

- old per-entry decomposition: 146.3 s;
- interned serial: 142.7 s (only 597/667 nonzero entries were unique, so the
  modest 1.03x interning result correctly revises the original hypothesis);
- interned plus two broker helpers: 71.1 s, **2.06x**, with `Grades` and
  `ActiveGrades` `SameQ` to the old route;
- whole factorization: 102.1 s versus the saved 153.9 s, with the same
  transformation, inverse, rank, active grades, and method; exact grade check
  and two-prime/all-sheet corroboration remained green.

Evidence is
`.../scratchpad/matperf/pool/logs/benchgrade_cf259_rows23.log`. This optimization
is worth integrating after the deadline issue below is resolved.

## P1 findings before integration

### P1 — the forcing-channel seal does not authenticate the channels

`FeynFacet/Private/MultiquadraticStripSolve.wl:293-300` fingerprints the source
forcing, root squares, root count, and forcing dimensions. The record stores
the supplied channel array separately at lines 302-310. Acceptance at lines
324-339 checks the channel shape and recomputes the fingerprint from the source
forcing, but **never hashes or otherwise authenticates the channel values**.

Consequently, take a valid sealed record, change one channel coefficient while
preserving its shape, and leave the fingerprint unchanged: the consumer returns
`Accepted` and installs corrupted channels. This is exactly the shape-compatible
artifact boundary the new seal is meant to close.

Fix without repeating the 807 s decomposition: canonicalize the channel array's
chart/regulator symbols, store a `ChannelsSHA256`, include that digest in the
record fingerprint, and recompute only the structural digest at acceptance.
Add an adversarial test that changes one same-shape channel and requires a typed
`ForcingChannelIntegrityMismatch`. The present S12 tests cover a different
forcing, a bare array, and a wrong shape, but not a mutated sealed payload
(`Tests/t_multiquadratic_gauge_screen.wls:692-743`).

### P1 — the compiled-screen cache key contains fresh `Module` symbols

`multiquadraticStripScreenCompileCached` includes `rootSymbols` directly in its
key at `MultiquadraticStripSolve.wl:1235-1239`. Each invocation of either screen
creates fresh module-local `rootOne/rootTwo/rootThree` symbols and assigns them
at lines 1355 and in the corresponding gauge-screen body. Thus the same scalar,
roots, variables, regulator image, and prime receives a different key on the
next image/rung call. The advertised cross-rung reuse must miss.

The compiled value contains exponent/coefficient arrays, not symbol identities
(`MultiquadraticStripSolve.wl:1097-1134`), so key on the fixed variable ordering
and root count/order, or canonicalize the local roots to fixed formal
placeholders before hashing. The S11 test at
`Tests/t_multiquadratic_gauge_screen.wls:654-678` is the right behavioral test;
it was only just launched at 10:39 and had no result at this cutoff. Do not call
the cache optimization validated until S11 records zero second-call misses.

There is a second cache-bound bug at lines 1248-1258: when one compiled value is
larger than the 200 MB limit, the cache is cleared and that oversized value is
then inserted anyway. If `bytes > limit`, return it uncached and record a
`Bypasses` counter. Add a test that temporarily lowers the limit below one
compiled value and asserts `Bytes <= Limit` afterward.

### P1 — merging `355b402` into the deadline patch makes the outer
`TimeConstrained` unsafe

The main fix wave wraps the entire grade decomposition in
`TimeConstrained` at `FamilyRegulatorFactor.wl:705-714`. Commit `355b402` changes
that same call into a brokered computation which submits helper tasks at
`FamilyRegulatorFactor.wl:489-511` in the performance worktree. The package
itself explicitly records that `TimeConstrained` does not bound task-broker
helpers and has escaped in pool subkernels
(`MultiquadraticStripSolve.wl:242-249`, `TransportCharts.wl:1071-1078`). If the
two patches are combined as written, the main call can return a deadline stop
while grade helper tasks continue consuming kernels and writing results.

Integrate cooperatively instead:

1. give `familyRegulatorGradedMatrices` the absolute deadline;
2. check it between unique expressions and before dispatch/collection;
3. cap every broker task timeout by the remaining stage time and make the
   helper return a typed incomplete batch;
4. preserve deterministic completed-batch progress and locally recompute only
   when time remains;
5. remove the outer `TimeConstrained` around the brokered stage.

This merge must also preserve the main wave's `Deadline`,
`ConstantFieldRestriction`, and rational modular-root fixes; `355b402` is based
on `c2c5ac8`, before those edits, in the same file.

### P1 — materializer helper output is shape-checked, not schema-checked

The parallel materializer accepts a helper batch when it is merely a list of
the expected length (`BlockEquationDeferred.wl:973-977` in `355b402`). Later it
treats any `Association` as a valid result and reads `entry["Value"]`
(lines 989-1014). A same-length batch containing `<||>`, a stale record shape,
or an association with `"Value" -> $Failed` is accepted instead of recomputed;
the overall function can still return `"Status" -> "OK"` with `Missing` or
`$Failed` in the forcing.

Add one strict `blockEquationDeferredAssemblyRecordValidQ` predicate covering
the required keys, value, booleans, and numeric nonnegative timings. Validate
each helper item before installing it; malformed items go through local
recomputation and then the existing typed fallback. Add injected-dispatcher
mutants for `<||>`, missing `Value`, `$Failed` value, wrong timing types, and a
mixed batch containing one valid and one invalid record.

### P1 — the byte cap does not bound what each helper actually loads

The materializer estimates bytes per job from referenced operands at lines
892-895 and batches on that estimate, but writes the **entire** operand table
and all jobs to one data file at lines 951-955; every helper reads that entire
file at lines 736-741. A 256 MB batch cap therefore does not prevent four
helpers from each loading a multi-GB shared payload. The brokered grade
decomposition has the same pattern: every helper reads all unique expressions,
although it computes one index slice.

For general families, add an aggregate admission gate on
`ByteCount[{operandTable,jobs}] * activeReaders` and on the grade payload. The
better implementation writes a compact per-batch payload with only referenced
operands and remapped local IDs. Keep the current full-payload route only below
a declared small threshold. Test the planner against one oversized operand;
the current test checks index partitioning, not resident payload.

Both new parallel stages also use relative `BatchTimeout` values (7200/3600 s)
and expose no absolute construction deadline. Thread the sector deadline into
them, cap batch timeouts by remaining time, and stop at a target/batch boundary;
otherwise a 7200 s sector budget can expire while collection waits on an
independent 7200 s task timeout.

## Regulator-stop/deadline patch assessment

The normal stale-stop success path is now correct and substantially better:
after accepted propagation it matches stop status plus rows, records
`ResolvedStop`, clears only that stop, deletes the stale next-sector strip
checkpoint, and atomically persists transformed `A/S/SInverse` before doing
more strip work (`Scripts/family_epsform_sector.wls:596-637`). The new resume
test uses the real driver definitions and covers matching/nonmatching stops,
checkpoint deletion, exact conjugation, persistence, and an idempotent second
call. Keep this implementation.

Two edge paths remain:

1. `factorTruncated` returns at line 534 when the prefix is already
   eps-factored, before examining a matching old stale stop. A state persisted
   by the pre-fix code can therefore contain both an already-transformed prefix
   and the stale terminal forever. Add a migration branch that clears it only
   when a matching `RegulatorFactorizations` certificate proves that the same
   rows were resolved; otherwise fail closed. Add that old-state fixture to
   `Tests/t_family_regulator_factor_resume.wls`.
2. The whole-family call at driver lines 1477-1501 merely logs every non-OK
   factor result. A `RegulatorFactorizationDeadlineExpired` there is neither
   persisted as a typed resumable stop nor exited, unlike the truncation path.
   Use the same stop schema and atomic write. Similarly, an exact-grade
   `TimeConstrained` expiry currently returns `ExactGradeCheckTimedOut`
   (`FamilyRegulatorFactor.wl:845-860`), while the driver recognizes only
   `RegulatorFactorizationDeadlineExpired`; translate a remaining-time expiry
   to the typed deadline status so the driver cannot continue from an
   unfactored prefix.

Deadline coverage is still boundary-incomplete. The rational candidate point
gate and exact conjugation at `FamilyRegulatorFactor.wl:288-300`, chart pullback
at lines 1097-1105, and source-frame exact check at lines 1135-1139 can all
overrun and then return success without a post-call deadline check. Bracket
opaque calls before and after; use interior boundaries where the operation is
already an entry/grade loop.

## Screen generality and deadline follow-up

The new screen statuses are sensibly separated: over-ceiling is
`NotApplicable`, expiry is typed/resumable `BudgetExhausted`, and only defects
at two independent images become the high-confidence modular obstruction. That
matches the project's accepted probabilistic certification standard.

However, the screen deadline is not yet a stage budget:

- compile is one unchecked `Map` over all scalar forms
  (`MultiquadraticStripSolve.wl:1361-1368`);
- the residue screen runs rank, nullspace, and one `MatrixRank` per scored
  letter with no post-rank or per-letter deadline boundary (lines 1507-1532);
- the gauge screen checks after rank only when a left nullspace is requested,
  and its candidate/subset rank loops have no deadline boundaries
  (lines 2082-2154).

Add an unconditional post-rank boundary and checks between scoring candidates.
Compile scalar-by-scalar with a deadline check between items. Opaque individual
rank calls may overrun one unit, but the function must not start another unit or
return ordinary success after the absolute deadline.

The 20,000-column and 4 GB defaults are private globals. The top-level solver
at lines 4751-4785 exposes neither screen's `MaximumUnknowns`/`MaximumBytes`,
and 4 GB is a per-kernel ceiling, not an aggregate pool ceiling. Add distinct
top-level options for both screens, pass them through, and document that the
campaign/pool manager must apply an aggregate memory budget. This is required
for package generality beyond the current families.

## Validation and live-state status

- `355b402` reports green fresh suites after its corrected reruns:
  `t_construction_dag` 78/78, `t_multiquadratic_regulator_factor` 39/39,
  regulator/frame/dispatch/construction/broker suites green, and
  `t_check_levels` green. I verified the emitted status/log files; I did not
  rerun them.
- The main correctness wave is **not yet validated as a unit**. Its direct
  sweep spent most of the interval waiting for a Wolfram licence, and
  `t_multiquadratic_gauge_screen` only obtained a kernel at 10:39. Record its
  final S11 cache result rather than inferring it.
- Clone-green fixture work is still pending. The modified
  `Tests/t_multiquadratic_gauge_screen.wls:297-320` reads about 34 MB of ignored
  CF300 state/input/channel files. The new Kallen23 and regulator-resume tests
  are also still untracked. A local green run is not a clone-green package
  until reduced fixtures and their provenance manifests are committed.
- CF259 has **not** advanced its persistent family state past the old stop. Its
  state file remains dated 07:50 and still contains
  `NeedsMultiquadraticRegulatorFactorization`; the 08:44 run log ends at the
  factor call. The 10:30 standalone benchmark proves the factorization and its
  speedup, but it did not install it into the campaign state. Do not report
  “resumed past sector 23” yet.
- At cutoff, the performance pool had one busy serial CF303 comparator and
  free helpers; the newly licensed gauge-screen test was a separate main
  kernel. Memory had ample headroom. No process was touched.

## Recommended order for the next wave

1. Authenticate the channel payload and fix the fresh-root-symbol cache key.
2. Rebase/integrate `355b402` into the deadline-enabled file using cooperative
   broker deadlines, not the outer `TimeConstrained`.
3. Add strict helper-result schemas and make byte admission reflect the actual
   per-helper payload.
4. Close the already-factored stale-stop migration and whole-family deadline
   paths.
5. Let the in-flight S11 and CF303 serial comparator finish; record their
   actual outcomes, then make the reduced fixtures clone-green.

The next Codex assessment should be incremental from this note: verify these
specific fixes and the in-flight results, without rerunning the already-accepted
CF259 graded benchmark unless its implementation changes.
