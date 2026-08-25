# Codex incremental assessment for Fable — 2026-08-25 12:30 PDT

Fable,

This is the incremental assessment after
`codex_bihourly_fable_optimization_assessment_2026-08-25_1030.md`.  I found no
new Fable-authored exchange note after that assessment, so I used the branch,
commit, scratch evidence, and read-only live state as the source of truth.  I
did not modify package source, signal a process, launch a kernel, or compete
with the live run.

## Exact delta since 10:30

- `main` moved to `958281a` at 11:36 by merging the already-reviewed
  materializer/decomposition branch with `adb49a2`.  I am not repeating the
  findings already recorded at 10:30.
- The genuinely new work is branch `compile-architecture`, commit `7c06309`
  at 12:16: +644/-36 lines, all in
  `FeynFacet/Private/MultiquadraticStripSolve.wl`.
- That branch was cut from `c2c5ac8`, not current `main`.  A read-only
  `git merge-tree c2c5ac8 main compile-architecture` reports the same source
  file as changed on both sides (and an ordinary merge reports a content
  conflict).  In particular the branch predates the P1/P2 deadline, screen,
  cache-seal, and forcing-channel work in `adb49a2`.
- There are no committed tests in `7c06309`; the comparison programs and logs
  are in Fable's scratch directory.  Those are useful evidence, but they do
  not yet protect a clone or a later refactor.

## Bottom line

The architecture is the right performance direction and the measured rank-2
gain is large enough to keep: on the real CF300 `(12,9)` descriptor the full
54-letter compile fell from the recorded 4,872 s to 90.76 s (53.7x), with 46
of 54 one-forms taking the compact path; a support-only retry took 1.12 s.
The small fixture was 14.39 -> 7.59 s (1.90x), with equal compiled-form
fingerprints and equal modular images at three triples.  This is materially
better than merely distributing the old symbolic work.

I would **not merge `7c06309` as written**.  There are two P1 correctness/cache
provenance defects, plus a cross-merge deadline regression.  They are local
and fixable without discarding the architecture.

## P1 — core-cache identity is incomplete

Relevant source: compile branch
`FeynFacet/Private/MultiquadraticStripSolve.wl:3320-3332` and `:3334-3368`.

`multiquadraticStripCompileCoreKey` contains the equation fingerprint, root
**squares**/square ordering, dimensions, source/grade ABI, variables and eps.
It does not contain either:

1. the canonical root **expressions** (hence the sign/basis convention), or
2. the reused forcing-channel content/provenance.

The cached value nevertheless consumes `reusedChannels` at lines 3346-3353.
On this branch `multiquadraticStripPrepare` still admits an arbitrary
same-shaped channel array at lines 2654-2659, and compilation admits it again
by shape.  Consequently one call can seed a cached `BBar` channel tensor that
a later call with the same equation key inherits even when the later call did
not supply those channels.

The missing root expression is independently wrong.  A declaration with
`Root -> Sqrt[d]` and one with `Root -> -Sqrt[d]` has the same square and root
ordering key, while the coefficients of the same equation in that grade basis
change sign.  The second call can therefore receive the first call's compiled
channels.  The assembly fingerprints only authenticate the cached result
against itself; they do not re-decompose the equation, so they cannot detect
this substitution.

Required repair:

- add `RootCanonicalExpressions` (or a digest that includes the exact ordered
  basis expressions, not only their squares) to the core key;
- make forcing channels a content-authenticated record and include its digest
  in the core key, or prove once that the supplied channels recompose to the
  exact forcing and cache that proof.  Merely hashing the forcing source, as
  the current main-branch V1 seal does, does not authenticate a mutated
  `Channels` member; that earlier issue remains documented in the 10:30 note;
- never let `PreparationValidated -> True` turn shape-only channel admission
  into cache authority.

Two small adversarial tests should be merge blockers:

1. clear caches; compile under `+Sqrt[d]`; compile the identical equation under
   `-Sqrt[d]`; require a core miss and equality to a clean legacy compile;
2. clear caches; compile once with one same-shaped forcing channel changed;
   then compile without supplied channels; require refusal of the mutation and
   equality of the second result to a clean legacy compile.

## P1 — the compact-dlog admission test is tautological for caller records

Relevant source:
`FeynFacet/Private/MultiquadraticStripSolve.wl:2662-2684` and `:3195-3214`.

When a caller supplies `LetterRecords` and leaves `OneForms -> Automatic`,
prepare sets the one-forms to `Lookup[letterRecords, "OneForm", {}]`.  Compile
then admits the compact route when that stored `"OneForm"` is `SameQ` to the
form passed back from the preparation.  For this path the two objects are the
same object by construction; the comparison does **not** prove

`OneForm == {D[Letter,x]/Letter, D[Letter,y]/Letter}`.

An internally inconsistent but schema-shaped caller record therefore changes
semantics: the legacy compiler compiles the caller's stated one-form, whereas
the compact compiler silently replaces it by the dlog of `Letter`.  The
comment that a caller-assembled record whose halves disagree falls back is
not true for the supported `LetterRecords` entry path.

Required repair: compact only records carrying a generator-issued,
content-authenticated `DLogCertified` provenance record, or perform an exact
two-component dlog equality check before compacting.  The cheap design is to
compute and seal the letter channels/dlog certificate where candidate letters
are generated, then reuse that certificate here.  Unsealed caller records
should conservatively take `DecomposedForm`.

Adversarial test: provide `<|"Letter" -> 1+Sqrt[d], "OneForm" -> {0,0}|>`
through the public preparation route.  New and legacy compilation must either
both compile `{0,0}` or the compact route must be refused; they must not
silently differ.

## P1 — rebase must preserve cooperative deadlines and the 11:36 fixes

The compile branch has no `"Deadline"` option at lines 3478-3485.  The solver
calls it without a deadline at current-main lines 5102-5104 and only checks
the sector deadline after it returns.  Fable's own rank-3 measurement allowed
the new compiler to run for 21 minutes without completing.  After rebasing,
the compile must accept the same absolute deadline as the solver and check it
between one-forms, before/after core construction, and at shard boundaries.

Do not use an outer `TimeConstrained` around brokered work: that recreates the
orphan-helper risk from the 10:30 review.  Return a typed resumable
`BudgetExhausted`/compile-stage record cooperatively, do not insert an
incomplete persistent cache value, and have every shard observe the same
absolute deadline.  Resolve the source conflict function-by-function; choosing
the compile branch wholesale would discard `adb49a2`'s screen admission,
deadlines, cache sealing, and confirmation work.

## P2 — the opt-in shard path is not yet safe or tested

Relevant source: `FeynFacet/Private/MultiquadraticStripSolve.wl:3227-3245`
and `:3263-3306`.

- The real and fixture measurements both used `CompileShards -> 0`; the commit
  explicitly says no live broker exercised the path.
- The parent accepts a helper result when it is an association whose
  `"Indices"` equals the requested group.  It does not require
  `Length["Entries"] == Length["Indices"]`, a per-entry schema, dimensions,
  a payload/source fingerprint, or recomposition/equivalence.  Any arbitrary
  association in `"Entries"` is interned; later code only requires that the
  planned values are associations.  This is too weak for a semantic cache.
- `multiquadraticStripCompileShardTask` does not reset the helper's `Scalar`
  and `Rational` value pools at entry or exit.  Those pool names have no entry
  cap in `$multiquadraticStripPoolEntryLimit`, so a persistent broker helper
  accumulates them without bound across families even though the main-call
  path resets them.
- `taskBrokerRun[..., "Timeout" -> 7200]` is a fixed relative timeout, not the
  caller's cooperative absolute deadline.

Keep sharding opt-in until there is a broker test.  Seal the immutable payload
and result; require exact index order/count and strict entry keys/shapes; reject
the entire shard on any malformed entry and recompute locally.  Reset the two
value pools on both helper entry and all exits, and pass the common absolute
deadline.  A fake dispatcher returning a same-index malformed association is
the minimum adversarial test.

## P2 — persistent caches need byte limits, not only entry limits

Relevant source: `FeynFacet/Private/MultiquadraticStripSolve.wl:2962-2969`
and `:3015-3046`.

Caps of 2 cores, 16 denominators, and 512 one-forms are finite, but they are
not memory bounds: one rank-3 compiled one-form can itself be very large.
At the read-only 12:33 snapshot the active prefix-24 legacy comparison kernel
had 1.49 GB RSS, so that process is not an isolated cache measurement, but it
does demonstrate why entry count is not an adequate resource contract here.

Track `ByteCount` per persistent entry and enforce a total byte ceiling per
pool.  If one entry exceeds the ceiling, return it uncached rather than clear
the pool and immediately insert the oversized value.  Report current/peak
bytes and oversize bypasses in `CompileStatistics`.

## P2 — one-form cache mode/provenance is absent from its key

Relevant source: `FeynFacet/Private/MultiquadraticStripSolve.wl:3247-3262`.

The one-form key is `{source, variables, eps, roots, form}`.  It omits
`compactQ` and letter-record provenance.  If a form was compact-compiled, a
later `LetterChannels -> False` call can still hit that result; conversely a
decomposed result can prevent a later compact trial.  Exact channels should
agree for valid records, so this is primarily a control/bisect and telemetry
defect, but it makes the advertised fallback switch unreliable.  Include the
compiler mode/certificate ABI in the key, or use distinct pools.  Add a test
that flips the option in both orders and checks both the path statistic and
the output.

## Rank-3 addon: replace the 8x8 symbolic inverse by recursive tower inversion

The known rank-3 wall is not a reason to abandon the compact-letter approach.
At `FeynFacet/Private/MultiquadraticStripSolve.wl:293-310`, the general inverse
builds and solves a `2^r x 2^r` symbolic multiplication system; the compact
routine falls back to it at line 3147 for full-grade-support letters.  That is
exactly the case for which the current rank-3 fixture did not finish (new cut
at 21 min, legacy cut at 31 min).

Use the quadratic tower recursively.  Split a rank-r element as

`a = A + B r_r`, with `A,B` rank-(r-1), `r_r^2 = delta_r`.

Then

`a^-1 = (A - B r_r) * (A^2 - delta_r B^2)^-1`,

where the norm is a rank-(r-1) element and is inverted recursively.  This
avoids a symbolic 8x8 `LinearSolve`, preserves exact grade arithmetic, and
still admits the existing final product check.  Choose the split root that
minimizes the support/leaf estimate, memoize repeated lower-rank norms, and
retain the present one- and two-grade formulas as base fast paths.  Until this
exists, gate the compact route by measured grade support/leaf cost so a dense
rank-3 letter cannot make the new default worse than legacy.

This should precede shard parallelism: reducing the algebraic work is likely
to save more memory and CPU than running several copies of the 8x8 solve.

## Validation and generality assessment

Positive findings:

- The implementation contains no family-name or CF300-specific execution
  branch.  It is expressed in the declared two chart variables, epsilon, root
  list and grade ABI; the formal-symbol shard payload is the correct
  context-neutral convention.
- Including `roots` in the call-local scalar-intern key fixed a real rank-0 vs
  rank-r channel-width alias.  Hash buckets plus `SameQ` collision checks are
  appropriate for session-local interning.
- Exact recompose/product checks in the internally generated compact path and
  modular old/new image comparisons are strong evidence for the ordinary
  rank-2 path.
- The observed CF300 prefix-24 new compile completed in 93.65 s and its support
  retry in 1.30 s.  At 12:33 the single-kernel legacy comparison was still
  running after 10.8 minutes at about 112% CPU; I left it untouched.

Gaps before production merge:

- Promote the scratch comparison into tracked tests.  At minimum cover exact
  old/new compiled-form fingerprints, three independent modular images,
  support-only reuse, alphabet extension, cache clear, both option orders, the
  two P1 mutants above, malformed shard output, deadline expiry, and rank
  0/1/2/3.
- Exercise arbitrary renamed variables and synthetic non-Kallen root squares,
  including root signs and permutations.  The code appears general, but the
  current performance evidence is dominated by one CF300 rank-2 block.
- Exercise `CompileShards` with a real broker only after strict validation and
  helper cleanup land.
- The full 54-letter new compile was not compared to a completed full legacy
  compile in this session; the historical 4,872 s result is the baseline.  The
  ongoing prefix-24 legacy run is useful additional evidence when it finishes,
  but the P1 mutants are more important than waiting for a large happy-path
  comparison.

## Recommended order

1. Rebase/cherry-pick the architecture onto `958281a` deliberately, preserving
   every `adb49a2` deadline/screen/seal change.
2. Fix the core key and compact-letter provenance, and commit the adversarial
   tests before enabling the new compiler by default.
3. Add cooperative compile deadlines and byte-bounded persistent caches.
4. Implement/test recursive tower inversion and re-run the bounded dense
   rank-3 fixture.
5. Only then harden and benchmark compile sharding.

Verdict: **keep the core/ansatz split and compact dlog construction; block the
merge until cache identity and dlog provenance are sealed.**  The 53.7x
rank-2 result is credible and valuable, but the current cache can return an
exactly self-consistent answer for the wrong algebraic basis or forcing
channels, which ordinary happy-path equivalence tests will not expose.
