# Codex overnight optimization and triple-root report — 2026-08-23

Status: **in progress**.  This file is an append/update handoff for Fable.  Do
not interpret it as a claim that CF300 or the triple-root families are fully
certified yet.

## Resource and safety envelope

- One persistent Wolfram main at
  `/tmp/codex-triple-root-20260823c.vx654S/pool`, with eight flat
  subkernels pinned to logical P-core IDs `0,1,6,7,8,9,18,19`.
- No independent or nested Wolfram main was launched.  Per-mission helper
  ceilings are captured by `kpsubmit.sh`; regression missions used zero.
- The live CF300 sector run and the old-code production performance gate were
  left running.  No process was killed or pattern-killed.
- A read-only watchdog follows `Design/Watchdog.md` at 300-second cadence.

## Confirmed package changes and tests

### Sparse family row propagation

`FeynFacet/Private/FamilyRowGauge.wl` implements exact sparse propagation of
a solved sector row.  It installs the already materialized dlog row, uses
support intersections for matrix products, and reports per-stage statistics.
The default future-connection mode remains `"Together"`; the explicit
`"Deferred"` mode leaves only future additive products unnormalized.

Regression: `Tests/t_family_row_gauge.wls`, **37/37**.

### Read-only resume hydration and integrity replay

`FeynFacet/Private/FamilyRowGaugeResume.wl` replays saved strip inputs and
finite-field caches in an isolated temporary directory.  It never writes the
driver checkpoint.  The strengthened implementation replays **every**
recovered key, not merely missing `SolvedForms`: existing forms must be
`SameQ` to the rematerialized dlog form before an installed row can activate.
Both direct rational finite-field caches and multiquadratic in-frame caches
are replayed, including the saved `ExtraLetters`.  A typed replay failure now
invalidates the complete recovered row (`PrevD`, gauges, forms, strip
summaries, and installed row) so every strip is recomputed; only the explicit
`FACET_RESUME_HYDRATION=False` opt-out trusts gauges for a final certificate.
A dimension-valid one-entry corruption returns the typed status
`ResumeHydrationExistingFormReplayMismatch` and remains nonactivating.  The
sector driver falls back to exact sparse propagation if hydration is disabled
or fails.

Focused unit: **16/16**.  Combined fresh-pool regression, helper quota zero:

- resume hydration: 16/16, 0.477 s;
- family row gauge: 37/37, 5.062 s;
- task-broker limit: 11/11, 0.207 s (only the test fixture's expected
  `CreateDirectory::eexist`);
- multiquadratic transport frame: 13/13, 0.309 s;
- row finite-field prototype: 35/35, 0.538 s.

All five missions filed `OK`; `git diff --check` and shell syntax checks were
green.

### Pool target-parse false-success bug

The first physical CF300 sidecar attempt contained an extra closing bracket.
Its target emitted `Syntax::sntx`, returned `Null`, and the pool filed the
mission `OK`: the server had parsed only the small generated wrapper, not the
file subsequently passed to `Get`.

`Scripts/kpsubmit.sh` now imports and parses the actual target under
`HoldComplete` before `Get`, stripping an optional WolframScript shebang.
Target import/parse failure prints an explicit diagnostic and returns
`$Failed`.  `Scripts/KernelPool.wls` and `Design/KernelPool.md` now distinguish
the wrapper parse gate from this target parse gate.

Held parsing initially introduced a second bug: it interned later TestKit
names in the `Global` context before ordinary expression-by-expression `Get`, producing
`FTAssert::shdw`/`FTReport::shdw`.  The final gate parses in a valid unique
letter-prefixed disposable context with only the `System` context visible,
then removes the held expression, temporary symbols, and newly interned
`Global` names before `Get`.  Symbol-table calls are explicitly
``System`Names`` and ``System`Remove``: FeynCalc exports its own `Names`, and a live diagnostic proved
that the unqualified call defeated the first cleanup attempt.  Abort cleanup
is also guaranteed and rethrows the abort.  The analogous server wrapper gate
is patched on disk and will become live at the next pool restart; generated
wrappers already use private-qualified locals, so the current pool is safe.

Adversarial live-pool regression:

- malformed shebang target: filed `FAILED` in 0.023 s, printed
  `KPSUBMIT TARGET PARSE FAILURE`, and did not print its unreachable payload;
- valid shebang target: filed `OK` in 0.017 s.
- namespace-neutral target gate: **2/2**, `OK`, no messages or shadow
  warnings (`fresh_kpsubmit_target_namespace_xh_v3`);
- real multiquadratic transport rerun: **13/13**, `OK`, no messages
  (`fresh_parserfix_xh_multiquadratic_transport_frame_v1`).

The shell/static wrapper suite is **27/27** and covers argv escaping, mission
name validation, valid temporary-context construction, System-qualified
cleanup, and abort cleanup.  Two deliberately failed namespace missions are
retained as diagnostics: v1 found an invalid digit-leading UUID context; v2
then isolated the FeynCalc `Names` shadow.  Neither was accepted as evidence.

Log SHA256 values are respectively
`5da3a93ae01d52d4bba6f49fa7070b49084ccaaee38fef40d3af2ef54066ae36`
and
`3eaedba1d0b47a4aaf307659a8b2e731ed082273104c87c5bd9b94536d74f019`.

## Finite-field performance conclusion

The modular arithmetic is not the bottleneck.  The row prototype is correct
for ranks 0–3 and all sign branches (35/35), and the genuine CF300
three-class oracle reconstructed 25 unknowns with rank 25/nullity 0 at three
construction primes, then passed an unseen prime and all eight sign branches
(22/22).  Measured scaling at support size 16 was 9.33 s for rank 3 (129
unknowns) versus 2.69 s for rank 2 (65 unknowns), ratio 3.46.

The winning production route is therefore:

1. replay/hydrate and verify the current solved row once;
2. install that materialized row;
3. retain future `base + sum(products)` as an additive term graph;
4. decompose/evaluate each leaf in the multiquadratic basis modulo a prime;
5. sum only rational grade channels, then reconstruct and certify at an
   unseen prime and every sign branch.

Calling `Together` on the whole algebraic future block destroys this
advantage.  CF300 sector 10 has 36 future targets and 80 products: raw
deferred construction took about 0.16 s, whereas old symbolic normalization
is the long stage.  The sector-8 termwise prototype covered all 36 cells at
three primes plus an unseen prime and all eight signs with zero failures; raw
build was 0.066 s, compile 1.15 s, and a one-branch all-cell evaluation was
about 3.7–6 s.

## CF300 physical rank-3 sidecar

The external-only derivation keeps the sector-12 future block as additive
leaves.  Base terms and each recursive `-D.A` product are decomposed
separately, exact-round-tripped, lifted into the declared eight-grade global
basis, and only then rational channels are summed.  Static review confirms
there is no whole-forcing-block algebraic `Together`.

The integrity gates are now implemented.  The checked wrapper executes an
immutable held target, traps local `Exit`/`Quit`, refuses stale result or
terminal-marker paths, binds target/source hashes, and creates exactly one
success or failure marker.  The derivation snapshots the 22.99 MB sector-10
state and sector-11 checkpoint byte-identically, verifies the CF300
`Multiquadratic3` chart fingerprint, and exact-replays all ten checkpoint
strips before using the installed row.  The original adversarial safety smoke
passed all **13/13** integrity checks with a persisted artifact and no
messages.  After the rank-zero repair it was expanded to **27/27** checks,
covering the exact former `3x2x1x1` rational-leaf path, rank-zero
algebra/decomposition/lifting, sparse root-index sets `{2}` and `{1,3}`, full
rank three, invalid channel maps, and unsupported cube roots failing closed.
The independent algebra/adapter suite is **42/42** over ranks zero through
three, characteristic zero, modular projection at two primes, active-root
denominators, derivatives, multiplication, and mixed-grade lifts.

The first checked physical run then failed closed after 14.2 s, but usefully
after all ten exact replays, the common regulator factor, square-class rank-3
certificate, and deferred row application passed.  A rational leaf with no
active radical reached the rank-zero polynomial-to-channel path, where
`Range[0,-1]` caused unequal-length multiplication and invalid part indices.
The checked wrapper filed `EXIT91` plus a failure sentinel; no success marker
was created and the source hashes stayed pinned:

- state: `44827aec1992b477dd1bf9038fac15debbd8d3269a1ff7b082ec94b2bba5e464`;
- checkpoint: `d643839382af8a8e6cafe880a01af69c8ed26c3440b80ae590a110e9df7b3f32`.

The empty-index defect is repaired in the External prototype:
`TRFromPolynomial[expr,{},{}]` returns the sole rational channel;
`TRFieldDecompose[expr,{}]` does the same while rejecting every unsupported
noninteger rational power; and `TRLiftLocalChannels` maps that sole channel
only to global grade zero.  Current hashes are Algebra
`fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab`
and Adapter
`ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5`.

The isolated syntax/load gate subsequently passed in 0.375 s: all three
sidecar targets parsed, all eight dependencies loaded, no messages or
`Global` additions/removals occurred, and any names retained by held parsing
were confined to unique disposable contexts absent from `$ContextPath`.
The expanded safety mission passed **27/27** in 0.212 s.  An independent
xhigh static audit then cleared a fresh physical run.

Physical v3 ran for 39.1 s with no Wolfram messages.  It exact-replayed the
ten sector-11 strips, reproduced the common regulator factor and square-class
rank-three certificate, and passed deferred prefix factorization.  It then:

- decomposed and exactly solved strip `12 -> 11` (root 3, active rank one);
- decomposed and exactly solved strip `12 -> 10` (root 2, active rank one);
- decomposed strip `12 -> 9` into roots `{2,3}`, grades `{0,2,4}`, active
  rank two, with 80 additive leaves and exact leaf round trips;
- failed closed because `SolveEpsFormStripInFrame` returned
  `NoRationalStripChart` for that two-root pair.

Thus the next real blocker is no longer rational-leaf algebra.  It is the
first pre-rank-three multiquadratic solve: an extension-field finite-field
solver must produce the `12 -> 9` gauge before the sidecar can recurse to the
first genuine rank-three strip.  Its pinned input is
`physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_9_input.wl`, SHA256
`274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6`.
No success marker or physical rank-three input was created.

The rank-three census/reconstruction scripts also remain launch-gated.  An
xhigh audit found that the census wildcard would accidentally include the
eventual `*_physical_rank3_input.wl` duplicate and then index an empty filename
parse.  It also found missing end-to-end input-hash binding, stale-output
overwrite races, repeated full symbolic ABI canonicalization, three redundant
dense RREF benchmarks, and unconditional sparse-to-dense conversion.  These
are being hardened before any physical certification claim.  Every split
sample already evaluates all `2^r` branches; repeated `BranchFlipMask` calls
permute those rows while adding independent point ensembles, not new branch
semantics.

## Live jobs at this checkpoint

- `sol_CF300_triple_xh_v2`: all sector-11 strips solved; CPU-active in the
  sector-11 row normalization of the old loaded code.  No CF300 completion is
  claimed.
- `fresh_cf300_resume_hydration_production_gate_xh`: completed `OK`, no
  messages.  Replay/hydration took 112.73 s; the old default symbolic row
  application then took **3657.18 s**, producing a 1,420,036-leaf installed
  row (38.7 MB).  This is the measured legacy baseline and loaded code before
  the new deferred production route.

## CF300 `(12,9)` rank-two extension-field solve (current overnight stage)

The pinned physical input
`cf300_sector12_physical_rank3_xh/physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_9_input.wl`
(SHA256
`274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6`)
has now passed a fresh preparation under the final cross-prime source hashes.
The preparation used roots `{2,3}`, exact four-branch split sampling, and the
pure-regulator clearance
`eps^3 (1+2 eps) (1+5 eps) (2+5 eps)`.  Exact measured dimensions are:

- preparation time 313.489647 s (324.4 s mission wall);
- 30 gauge-support monomials, bidegrees `{4,5}`;
- 36 one-forms (8 diagonal plus 28 forcing-derived);
- 480 gauge unknowns plus 144 residue unknowns = 624 total;
- 32 equations per split point, 21 automatic points, hence a `672 x 624`
  modular matrix;
- preparation artifact SHA256
  `a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6`.

`CrossPrimeEliminationPlanV1` performs semantic plan discovery once and binds
all later epsilon images and primes to the immutable plan.  A follower can
only solve the fixed square constrained core.  It cannot call the canonical
dense RREF or rediscover normalization columns.  Every solution and nullspace
vector is nevertheless checked against all 672 original rows and the exact
`{0,I}` normalization block.  Degree profiles are fixed across primes.  The
physical drivers bind input, preparation, plan-source, prototype, dependency,
driver, root-order and ABI hashes and commit artifacts atomically.

Current validation evidence:

- isolated syntax/load/semantic smoke: passed, zero messages, stable hashes;
- cross-prime static suite: 47/47;
- runtime adversarial suite: 19/19 in 6.9 s, including trapped dense entry
  points (zero calls in Require mode), a one-byte dense cap, altered plan,
  root order, degree profile, source hash, and a corrupted non-core row;
- aggregate raw-certificate static suite: 18/18;
- an independent direct characteristic-zero residual now evaluates the
  reloaded original equation with ordinary `D`, `Dot`, and entrywise
  `Together`, independently of `TRFieldDecompose`, `TRDerivative`, and
  `TRMultiply`;
- the aggregate records the CRT modulus, rational-reconstruction bound, and
  observed recovered coefficient heights before the exact original PDE,
  unseen-prime, and all-branch point-set gates.

The legacy discover pilot at prime 10007 is deliberately retained as a
performance baseline.  Its first sample is not merely one dense RREF.  For
this block the normal path executes a `672 x 625` augmented `RowReduce`, a
near-square independent-row `MatrixRank`, and a `624 x 624` constrained-core
`MatrixRank`; the last rank calculation is theoretically redundant.  The
pilot remained CPU-active and memory-flat near 513 MB beyond 38 minutes with
no messages.  No process was stopped.

An isolated FLINT 3.0.1 rectangular affine-RREF adapter was therefore built
under `triple_root_2026-08-22/flint_affine_rref_xh/` without changing the
live package/prototype/driver hashes.  It returns canonical particular and
nullspace data, independent equation rows, residue-first normalization
columns, and two inverse witnesses.  Both C and Wolfram sides verify all-row
affine/null residuals, canonical free coordinates, and both two-sided minor
inverse identities.  Native evidence is:

- release adversarial tests 73/73;
- ASan+UBSan tests 36/36;
- source SHA256
  `11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd`;
- binary SHA256
  `e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5`;
- deterministic dense CF300-shape `672 x 624`, rank 620/nullity 4 benchmark
  at prime 2147483647: 0.3176/0.1966/0.1307 s total at 1/2/4 threads,
  24.5/25.1/25.0 MB RSS, with byte-identical outputs.

The native Wolfram verifier and production-shaped discover/reuse driver are
still External-only and under independent xhigh review.  They must pass the
managed-pool differential/corruption smoke and the actual physical matrix
before any package integration or optimized certification claim.

### Native physical result and A0 ansatz diagnosis

The native bridge has now passed the managed-pool differential and corruption
smoke, **70/70**, with empty captured load/runtime message streams and stable
source/binary hashes.  The complete CF300 sidecar syntax/load smoke also
passed with no messages, and the aggregate's explicit native-provenance
mutant suite passed 6/6.  The aggregate now rejects mixed native/legacy prime
artifacts and binds the adapter, native module, native binary, fixed-plan
binary and native prime driver through completion and into `SidecarSeed`.

The old Wolfram pilot terminated by itself after 4093.9 s with
`InsufficientStablePivotSamples`: only 3 of 48 epsilon images were usable.
The first nine were `InconsistentModularSystem`, all first exposed at reduced
row 613; the remaining 36 were `ConstrainedResidualNonzero`.  Since 19 points
give 608 rows and the twentieth begins at row 609, this is direct evidence
that the current ansatz becomes inconsistent when the twentieth point starts
to overdetermine it.  No process was stopped.

The bounded native physical probe then tested all 12 combinations of
primes `{10007,10039,10067}` and epsilon values
`{1/21,1/11,3/23,1/6}`.  Every image returned typed mathematical
inconsistency; no cross-prime consistent image exists for A0.  Mission wall
was 999.2 s with no Wolfram messages.  Per-image measurements were:

- symbolic split-branch assembly: min 80.007 s, median 81.805 s,
  mean 81.819 s, max 84.269 s, total 981.823 s;
- native affine RREF: min 0.336 s, median 0.353 s, mean 0.546 s,
  max 2.649 s, total 6.550 s.

Thus native RREF is less than one percent of this campaign's wall time.  The
remaining performance bottleneck is `TRSplitPointRows`: for this physical
sample it performs roughly 8064 repeated symbolic root-branch substitutions
and `Together` reductions.  The next performance implementation is direct
root-channel assembly: exact channel decomposition once, sparse polynomial
compilation, per-prime reduction, per-epsilon Horner collapse, numerical
point evaluation, xor/square-class grade multiplication, and packed dense
row construction.  It will be accepted only after a rank-0--3 differential
transform against the legacy split-sign rows.

The current A0 failure is therefore an ansatz failure, not a finite-field
performance failure.  Two heuristic ingredients are being separated with a
pure-superset discriminator: support rectangle `{4,5}` versus `{5,6}`, and
the 36 composite-entry one-forms versus their union with epsilon-free
irreducible factor dlogs.  Production CRT reconstruction remains gated until
one of A0/AS/AL/ASL is generically consistent at more than one prime.

### Certified A0 19/20/21 transition

The final gapped-pivot-corrected native verifier has now certified the exact
transition at `p=10007`, `eps=1/21` on one immutable 21-point stream.  The
19-point prefix is consistent with `rank(A)=rank([A|b])=608` and coefficient
nullity 16.  Adding point 20 gives `rank(A)=612` and
`rank([A|b])=613`; the same mismatch remains at 21 points.  The full
`672 x 624` coefficient matrix therefore has rank 612 and nullity 12, while
the augmented matrix has rank 613.  Both ranks at every prefix were proved by
independently verified native homogeneous certificates, rather than inferred
from an affine-solver exit code.

The shared symbolic assembly took 82.931902 s and 82 candidate points to
accept 21.  The mission completed `OK` in 105.1 s with no diagnostic
messages.  Artifact SHA256 is
`269aef2b41ada3289f9143495e4c0dc9b4344bd38c51b0eb7a18f0c06981ec68`;
log SHA256 is
`234e2ab48a744e916aac81a1edfda2440e4da24fdfdea71b6af2696a598c0bee`.
This closes the ambiguity in the legacy row-613 observation: A0 is a genuine
structurally underfit ansatz, not an unlucky image or a native-backend error.

The four pure-superset discriminator shards have now completed `OK`, without
messages or source drift, on the Cartesian product of primes
`{10007,10039}` and epsilon values `{1/21,1/11}`.  All sixteen full
variant-images are inconsistent, with the same rank pattern in every image:

- A0 (`672 x 624`): `rank(A)=612`, `rank([A|b])=613`, nullity 12;
- widened-support AS (`864 x 816`): 804/805, nullity 12;
- enlarged-letter AL (`704 x 672`): 632/633, nullity 40;
- combined ASL (`896 x 864`): 824/825, nullity 40.

The coefficient/augmented pivot, free-column and independent-row-witness
fingerprints also agree variantwise across both primes and both epsilon
images.  Support widening adds 192 unknowns and exactly 192 rank directions,
so it preserves nullity 12 but does not span the forcing term.  The twelve
factor-derived dlog forms add 48 unknowns but only 20 rank directions, raising
nullity to 40 without curing the contradiction.  The two effects add in ASL.
Thus no A0/AS/AL/ASL candidate may enter Discover/Reuse or reconstruction;
the missing ingredient lies outside the tested 42-monomial box and the twelve
naive factor dlogs.  The next discriminator must distinguish numerator degree,
gauge denominator, epsilon/root-grade structure and genuinely algebraic
letters rather than blindly promoting ASL.

The four artifact SHA256 values are, in image order I00/I01/I10/I11,
`125b56e1a32970f97dd409d845a21f738133f9510bf38e9180e5cc561f927044`,
`9e1df894c54a391a67eef9c3fa4cf63fc2d358f12dc622543fe85fd85f07b0f1`,
`1620d0471c1f474282fcd39b90a80656757b068e3731ef8eb2fe835228c1b2fa`,
and `836f9104c3f8a57a7004efa94bac4afbdc849a4301446b6e1d754b78006e550b`.
Each legacy mission took about 56--57 minutes, while only about 2.5 minutes
was explicitly attributed to preparation validation, point assembly and
native ranks.  Roughly 95% of wall time is therefore an uninstrumented
rational-channel census/factorization/variant-construction cost; this is a
separate optimization and telemetry target.

### Direct multiquadratic channel assembler

The External-only direct assembler now replaces repeated explicit branch
substitution by one exact channel decomposition, sparse polynomial images,
cached prime reduction, cached epsilon collapse, xor/square-class grade
multiplication, and packed modular rows.  Its production sampling condition is
only that coordinates, declared root squares and rational denominators are
nonzero.  It therefore does not require quadratic residues or modular square
roots; explicit roots remain confined to the held-out sign-basis differential
oracle.

Managed testing exposed and fixed three real prototype defects before any
physical launch:

- the prime-image cache insertion helper lacked `HoldFirst`, so its cache
  symbol evaluated before mutation;
- two oracle point finders used `Return` inside `Do` and fell through to
  `$Failed`;
- the derivative of a gauge basis term `q_m r_g` was added to every target
  grade rather than only target grade `g`.  The old branch-space leakage was
  exactly `d_g Sum[S_(s,t), t != g]`; an independent rank-one diagnostic
  reconstructed every wrong entry and verified the corrected Kronecker grade
  gate component by component.

A final failure-only preflight now preserves typed `DegenerateRootImage` and
`ZeroGaugeDenominator` diagnostics when their dependent logarithmic
derivatives also have poles.  The valid-point hot path is unchanged and still
performs one combined evaluation.

The frozen assembler SHA256 is
`227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`.
The final managed adversarial oracle passed 109/109 top-level checks in 8.7 s
with no Wolfram messages.  Coverage includes ranks zero through three at both
primes `{10007,10039}` and both epsilon images `{1/21,1/11}`, exact matrix and
RHS equality after sign transformation, all cache paths, malformed epsilon,
wrong-root and perturbed-channel mutants, a deliberately nonsplit accepted
point, sparse large exponents, resource caps, A0/AS/AL/ASL projections, and
verified native consistent/inconsistent affine ranks.  Artifact SHA256 is
`bfbfc0519c311c0126883628670543f5dbef32bd08dd9504c1a35d08e102f585`;
log SHA256 is
`c1928188401a966d13b47ad9a4a05c9cce79f25beecea444e02f992b068b05e8`.

The physical CF300 sector-12 A0 comparison passed against the exact same 21
ordered split points as the legacy assembler.  The complete `672 x 624`
matrix and RHS are identical after the direct grade-to-sign transform, and an
independent first-point differential also passed.  Source hashes were stable
and both message streams were empty.  Artifact SHA256 is
`a31dba4a3dae438b5c77c999f72b7c87a9125bcacf8ce60d231ac38fd6586fe1`;
log SHA256 is
`c25e320f982d6f44bd8946cbb853720c71f3abc839fa2680d6f99f76f7adbe4a`.

The timing separates the optimized numerical kernel from the still-slow exact
compiler:

- exact direct compilation: 677.816766 s;
- legacy 21-point split sample: 93.887939 s;
- direct sample on those same points: 6.866564 s, including 0.851611 s full
  assembly validation, 2.794136 s prime/epsilon collapse, 2.808681 s for all
  21 point rows, and 0.000385 s dense materialization;
- grade-to-sign transform: 0.9899 s;
- total mission wall: 797.6 s.

Thus the already-compiled direct sample is 13.67x faster than the legacy
end-to-end sample even before counting its arbitrary/nonresidue point
acceptance advantage; direct plus the certificate-only sign transform is
about 11.9x faster.  The current v1 compile amortizes after roughly eight such
images, but it is not yet acceptable as a one-image optimization.  The next
compiler version is therefore gated on unique-scalar DAG compilation,
root-free rational fast paths, reuse of the canonical round-trip expression,
base-versus-ansatz compilation split, and one full-validation token.

The immutable serialization gate has now passed.  A source/input/ABI-bound A0
cache compiled in 682.267943 s and completed in 699.9 s without messages.  Its
32.8 MB artifact has SHA256
`0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be`,
cache key
`3a6b6a63cbf3191bb4732ea3b3e8d6500dab826ae89388a192d3e08ba0baaf0f`,
and assembly fingerprint
`e5a3de1b068388896c238186c78216cbe191aeb7d0abd679cb2fd39f6fbe012b`.
An independently pinned validator read and fully validated it in 1.864363 s,
performed an operational epsilon collapse in 3.188345 s, and passed exact
Put/Get, fingerprint/payload/cache-key corruption, truncation, relocated-source
mutation, cleanup, source-stability and empty-message gates in 14.4 s total.
The validation report SHA256 is
`3dc97464e37ec5d8f578588821053427539ce588902920d857659d66a063cb65`.
A cached-only common-stream benchmark has now completed `OK` in 803.8 s; its
driver cannot call `DRCAPrepare` and required that exact validator
attestation.  Seven warm repetitions on the same 21 preselected split points
give a median 3.728163 s for direct grade-basis assembly versus 82.614038 s
for legacy `TRSplitPointRows`, a **22.159x** speedup.  Adding the separately
timed 0.816235 s sign-basis transform gives 4.544398 s and an exact
like-for-like **18.179x** speedup.  The direct matrix and RHS after this
transform are exactly equal to the legacy output.  Warm direct anatomy is
0.680287 s validation, 0.000047 s epsilon-cache hit, 2.649368 s point
assembly, and 0.000377 s dense materialization.  The 9.219459 s cold sample
is dominated by a one-time 5.411802 s prime/epsilon collapse; the serialized
cache itself read and fully validated in 1.803819 s.  On one common candidate
stream, direct sampling accepted 21 points in 21 attempts, while explicit
rank-two split sampling required 78 attempts (3.714x); 15 of the 21 direct
points were genuinely nonsplit.  Artifact SHA256 is
`908655450bc99be903c7db5d4369d56f5fd42bc3f3f7259e14f9af620431b64a`;
log SHA256 is
`9ed894e0316bb40322f007a86a738a58caa724e1cfb01e7611d7157f5ef1fe87`.

The first compile-reuse gate for changing only the ansatz has now passed.
`DRCARebindAnsatz` reused the cached equation core and rebound five targets in
161.9 s mission wall, with no messages: identity 12.183073 s, the `{+2,+2}`
support shell 9.124429 s, one extra denominator factor 9.003683 s, one appended
exact-potential dlog form 12.143314 s, and the combined target 9.508653 s.  The
support target has 56 monomials/1040 unknowns; the denominator target has 36
monomials/720 unknowns and proves exact containment of every old gauge
numerator after multiplication by `1+x`; the appended-letter target has 37
forms/628 unknowns; the combined target has 1044 unknowns.  On five physical
CF300 points at `p=10039`, `eps=1/21`, projection of the rebound support matrix
and RHS was exactly the cached A0 matrix and RHS.  Non-prefix one-form and
mutated-source adversaries failed closed.  Artifact SHA256 is
`da9cc2ff38b9b01d36c940cbbb3f12a06bb08323e7819285d1271abf32310703`;
log SHA256 is
`db2a8ce796f8f646b3545d0766da6a40b87795682f916741fb0c0ca44d64b9f6`.
A managed FULL gate then compared the rebound combined assembly against a
completely fresh compilation.  It passed exact `SameQ` with no messages:
fresh compilation took 691.315630 s, whereas combined rebind took 12.324428 s
(**56.1x** lower).  Mission wall was 854.0 s.  Artifact SHA256 is
`43fe9980f7cfacd9d86ce280d7b4dff82eaf2aae02270593f38d61827225a682`;
log SHA256 is
`f82a96fa4a4cf68ced8c304020d830c336c2084aae31cc17a4ccb35638bbebd0`.

A targeted census now reads the validated exact `E/C/BBar` channels from the
cache rather than decomposing and refactoring the strip.  On the physical
CF300 input it found 40 nonzero rational channels, 27 unique denominators,
and no missing higher-pole gauge factor in 3.3 s mission wall; denominator
canonicalization and factorization themselves took 0.146888 s and 0.043738 s.
The three forcing simple-pole factors omitted by the current `p -> p-1`
gauge rule are `x`, `1-x`, and
`1-2x+x^2+2y+2xy+y^2`.  The diagonal-only contextual factors `1+x` and
`1+x+y` are recorded separately.  The final artifact has no symbolic
`Missing` exponents and SHA256
`c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a`;
log SHA256 is
`73b87384d68f111320d36626be3b3a39f3a12f59c0f8486bdccef288b0b8f3e1`.
Two short fail-closed diagnostic revisions exposed and fixed integer
coefficient, expression-head symbol, and empty-source aggregation mistakes in
the new census driver before this artifact was accepted.  The four-image
left-witness and independent native-rank screen has now rejected every single
factor as sufficient on its own.  For `x` and `1-x`, every image has
coefficient/augmented ranks 708/709 with nullity 12.  For the quadratic factor,
every image has ranks 1028/1029 with nullity 12.  Each factor pierces the base
left witness, so none is rejected by the cheap necessary test, but all twelve
promoted systems are independently inconsistent.  The next denominator test
must therefore cover the three pair products and the triple product; it must
not promote any single-factor ansatz to reconstruction.

That physical screen exposed a verifier-only large-rank defect.  At size 1028,
Wolfram leaves `IdentityMatrix[1028]` in a structured form while the modular
matrix product is an explicit list, so representation-sensitive `SameQ`
returned false even though the inverse was exact.  The retained 9,069,264-byte
request and 8,580,320-byte response passed the native backend's full exact
two-sided check and an independent wire parser's left/right Freivalds checks.
The adapter now normalizes both products and the cached identity before exact
comparison; SHA256 is
`d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605`.
Its static suite passes 120/120 and a fresh 64-random-case differential,
including semantic and binary corruption mutants, passes 108/108 with no
messages.  That rerun also found and fixed a persistent-kernel test defect:
a stale global association named `record` could turn the driver's delayed
assertion recorder into an association-key assignment and falsely report 0/0
as success.  Helper symbols are now cleared and an assertion-cardinality floor
fails closed.

An independent direct A0/AS/AL/ASL discriminator completed all four expensive
image/rank stages, but its V1 final artifact was lost to the commit-path defect
described below.  The checkpointed V2 replacement is now running as one
four-image mission.  Its final static checks pass 68/68.  It preserves the pure
supersets, exact projection maps, variant point counts, A0 19/20/21 prefixes,
and separately verified FLINT ranks of `A` and `[A|b]`, while replacing only
`TRSplitPointRows` by direct grade-channel sampling.  It records non-split
evidence, Legendre-character and typed-rejection histograms, exact source
closure, compilation time, and per-image assembly time.  Driver SHA256 is
`346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64`;
static-test SHA256 is
`536173615ef0dacb1c94c87dab5ce0dadddb5701d9bb188fb0587c4a1228ee8f`.

Package-facing defects and promotion gates are recorded separately in
`codex_package_bug_handoff_2026-08-23.md`, SHA256
`5cd3cdac12669846ff6017d072566fe4e1e5ecd7a2b611dbb04de2854839b899`.
In particular, the native affine-RREF discovery backend must be distinct from
the existing fixed-core FLINT solver and fail closed; a direct strip solver
cannot claim package `Solved` status until every closed one-form has a verified
dlog potential compatible with installation and final certification.

### Package integration and post-merge gates

The source-rebased finite-field, resume-provenance, deferred-row-gauge and
regulator-seal changes have now been applied in their staged order to the live
working tree.  The production postimage SHA256 values exactly match the
independently prepared mirror:

- `FiniteFieldStripSolve.wl`:
  `8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70`;
- `FamilyRowGaugeResume.wl`:
  `816fa4d544806115181b3c3fe2d6ee3de89fff1d3d999e6412b6a745b010fc2b`;
- `FamilyRegulatorFactor.wl`:
  `bef8ca27d92a76b6db0abb7cbccb1be2e4498471005fdfe8c40687d071d168c1`;
- `family_epsform_sector.wls`:
  `6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1`.

The managed post-merge suite passed the backend/plan adversaries 30/30,
solver-configuration/resume adversaries 30/30, deferred static contract
18/18, deferred sequential exact identities 19/19, constrained finite-field
9/9, round-two finite-field 24/24, preparation/reuse 6/6, family row gauge
37/37, and family resume 16/16.  The official resume fixture was updated to
write the schema-2 direct-rational `SolverConfiguration`; this preserves the
intended rule that legacy direct checkpoints are recomputed rather than
silently trusted.  Its test SHA256 is
`ed54cb2648159485639b59dbe5740725823879e6adfce039092c2fe64be3e8c7`
and the clean 16/16 log SHA256 is
`65618704bba9bb3e1c9ea8561c0b0cbda111ac7d79b80934cc0c2b1b4ac1c484`.
One reused-kernel constrained-solve gate emitted a package reload
`BuildBasis::length` message, but all nine mathematical assertions passed;
the fresh resume gate was message-free.

### Direct discriminator commit-path repair

The direct A0/AS/AL/ASL mission completed all four expensive image/rank stages
and then exited 98 solely in its atomic final writer.  Its `Counts::invrp`
message was a separate empty-telemetry bug (`Lookup[{},...,None]` produces
`None`, which is not a list for `Counts`).  The old writer collapsed eight
commit failure modes to one label and deleted both temporary and target
evidence, so the exact failed substage cannot be recovered after the fact.

An adjacent External-only V2 driver now seals one checkpoint per image,
strictly resumes only hash-compatible stages, prints ranks immediately,
returns typed writer stages, preserves failed commit evidence, and fixes the
empty rejection histogram.  The first post-merge submission was rejected
before execution by `kpsubmit`'s held target parser: one qualified helper name
had been line-broken immediately after its context backtick.  The token is now
contiguous, and a comment/string-aware no-kernel lexer rejects this general
class of split qualified symbols (including a synthetic negative fixture).
Its final driver SHA256 is
`346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64`;
the typed atomic/checkpoint helper SHA256 is
`dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30`;
its static gate passes 68/68.  A coherent post-merge preparation with SHA256
`6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`
pins the integrated source closure.  Mission
`cf300_s12_direct_discriminator_postmerge_xh_v2` loaded successfully after the
parse fix and is running with two native FLINT threads; no old mission or user
process was stopped.

### CF300 square-free denominator-product discrimination

The optimized target-first witness driver tested every remaining square-free
product of the three omitted forcing factors `x`, `1-x`, and
`Q = 1-2x+x^2+2y+2xy+y^2`.  Each candidate was checked at two primes and two
epsilon values, and every nonzero witness score was followed by independent
FLINT ranks of the coefficient and augmented matrices.  All four candidates
are inconsistent in all four images:

- `Q (1-x)` and `x Q`: 64 support monomials, 1168 unknowns, ranks
  `1156/1157`, nullity 12;
- `x (1-x)`: 42 support monomials, 816 unknowns, ranks `804/805`, nullity 12;
- `x Q (1-x)`: 72 support monomials, 1296 unknowns, ranks `1284/1285`,
  nullity 12.

The conclusion is stronger than the earlier necessary left-witness screen:
no square-free product of the current three denominator factors makes the
physical affine system consistent.  The next ansatz axis must therefore add
something genuinely new (higher numerator support, repeated pole powers, or
new algebraic-letter/root channels), rather than another subset of this factor
catalog.  The four artifact SHA256 values for masks `011`, `101`, `110`, and
`111` are respectively
`d9cdee63f757afc124324dbdb29afe50aa458c27e5ab43f14e9fdf9739679bc7`,
`58fecdbd08984f2a23b2e9eba9468ddafa96bc843cc724d27c50396ab456f45a`,
`f177735d223c46f8085d3e3d4e2f315613193e8d5367a4a258225a45e7a21a0c`,
and `90b2fc707397c5df5e94f2eac4235bb4e84265f53e8bee8f9abb4a18f284572a`.

## CF303 / CF259 continuation inventory

An independent no-kernel xhigh inventory fixes the continuation order as
CF300, then CF303, then CF259.  CF303 has 45 masters, 25 diagonal sectors and
124 raw nonzero lower-block pairs; it uses the same ordered degree-eight field
as CF300, `{lambda2,lambda3,1-4 v w}`.  The generic multiquadratic algebra,
strip adapter, direct assembler and reconstruction code are reusable, but no
CF300 preparation, elimination plan, state or prime artifact is.  CF259 has
47 masters, 27 diagonal sectors and 132 raw nonzero pairs; its third square
class is the distinct `4 v+w^2`, so it additionally needs fresh Kallen+Q4
coverage.

Neither family currently has a captured strip input, recursive state,
preparation or prime artifact.  The cheapest meaningful next step is therefore
a fresh identity-frame CF303 sector capture after CF300's reconstructed-gauge
consumer exists, followed by classification/preparation of its first typed
stop; a raw static strip census cannot see the grades introduced by recursive
row gauges.  The two stops must remain distinct:
`NoRationalStripChart` belongs to the extension-field strip solver, whereas
`NeedsMultiquadraticRegulatorFactorization` requires constant truncated
multiquadratic regulator factorization before a strip solver can continue.

The inventory also found a package diagnostic-loss bug: on an algebraic-frame
solve failure, `family_epsform_sector.wls` logs the returned typed status, but
the `_unsolved.wl` artifact saves only the strip and optional obstruction, not
that returned solution/status.  The `_input.wl` still permits recovery, so
this does not corrupt mathematics, but automation should persist the typed
failure.  Full evidence and the exact family DAGs are in
`triple_root_2026-08-22/cf259_cf303_continuation_2026-08-23_xh/ASSESSMENT.md`,
SHA256
`9cb9067e74d563a72bead20555d9ad7e064220fdb39792abf5804a8508c29f2c`.

## Continuation update: maximal denominator closure and capture hardening

The decisive `MAX5` finite-field screen completed on all four independent
`(prime, epsilon)` images.  Its denominator multiplies the base ansatz by all
five absent square-free factors: the forcing factors `x`, `1-x`, and
`1-2x+x^2+2y+2xy+y^2`, together with the diagonal-context factors `1+x` and
`1+x+y`.  The dense bidegree `(10,8)` support has 99 monomials and 1728
unknowns.  Every image has witness score 1585, ranks `1716/1717`, nullity 12,
and is inconsistent.  The artifact SHA256 is
`9167588092db9734dbd6f7540575790e4c4eed5eb1e8b4c8327f7854da85d5da`;
the log SHA256 is
`5db80d4d90391612b3d51c7417eab73893c45a4b6aec199fc54f49f8bee937c1`.

The driver also certifies exact polynomial convolution embeddings for all 31
nonempty square-free subsets.  Therefore this one affine inconsistency rejects
every mixed square-free choice from the complete five-factor catalog, not only
the combinations sampled earlier.  It does not reject repeated pole powers,
a genuinely larger numerator support, or new algebraic one-forms.

Two follow-up V2 drivers passed 65/65 static checks, 24/24 poisoned-namespace
checks and 33/33 count checks, but both failed closed at artifact hydration on
reused kernels before target construction.  No mathematical result was
recorded.  This demonstrates that mechanically wrapping a formerly global
driver in `BeginPackage` is not enough: the runtime artifact reader/validator
must be exercised in the same poisoned kernel, not only checked lexically.
Adjacent V3 repairs are being prepared; the terminal V1/V2 sources remain
immutable.

The CF303 capture wrapper exposed a separate pool control-flow defect: an
untagged target-level `Return` can leave a scheduler record without the final
marker even though the worker survives.  Recovery wrote only the missing
terminal metadata after confirming that the kernel was already reused; no
process was stopped or signalled.  V3 then failed safely because it stringified
held `DownValues` rather than their evaluated values.  V4 removes that brittle
predicate, pins both KernelPool source and live `poolRun` definition hashes,
and passes 120/120 static assertions.  Its exact no-op live-contract probe
completed cleanly and proved all five expected pool markers.  The real CF303
identity-frame capture has consequently been launched as
`cf303_identity_capture_xh_v4` with one worker and zero nested helpers.

## Production endpoint, namespace adversary, and safe continuation

The long `sol_CF300_triple_xh_v2` production mission reached a useful typed
stop after 32,105.5 seconds.  Sector 11's ten strips were individually solved
and checked, then its row gauge was installed blockwise.  The row operation
took 28,541.3 seconds, of which 28,538.9 seconds was symbolic normalization;
the sparse/touched counts were `A=48/56`, `S=12/12`, and
`SInverse=20/12`, with 20 literal single-term fast paths and 80 certified row
entries.  The next stage detected regulator-dependent residues in rows 1--11
of the 22-by-22 truncation and stopped before sector 12 with the explicit
`NeedsMultiquadraticRegulatorFactorization` condition: roots `{1,2,3}` have no
joint rational chart.  The preserved family state is
`triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl`, size 33,012,365
bytes, SHA256
`898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12`.
The sector-11 strip-state SHA256 is
`d643839382af8a8e6cafe880a01af69c8ed26c3440b80ae590a110e9df7b3f32`.
No completed row was discarded.

The reused-kernel adversary exposed a sharper artifact contract.  The public
compiled-artifact reader hardcodes the Global context, while its `InputForm`
fingerprint depends on the contexts of symbolic `x/y`.  A test also
irreversibly set `Locked` on Global-context `x`, `y`, and `eps` on worker 144.
All attempted cleanup paths failed closed; two independent read-only probes
proved the exact states stable, with fingerprints
`7a97decc...52ae54`, `859b06b0...b561d4e`, and
`57576170...d08968`.  No process was killed, signalled, or restarted.

The safe replacement hydrates preparation and cache values in a fixed,
mission-owned context containing exactly `{v,w,x,y,eps}`, keeps that context
visible through public value validators, fingerprint recomputation, ansatz
rebind and sampling, and omits Global from `$ContextPath`.  It raw-loads with
`CheckAbort`, records messages separately, and never calls the hardcoded-Global
reader.  Live poisoned-worker gates established that preparation/cache are
Associations, preparation/cache/assembly validators all pass, and the exact
and compiled fingerprints recompute to
`fc5496c7...82e34d` and `e9f7152a...039e7`, while the complete Global states
remain unchanged.  The apparent gate failures after those checks were
test-harness Hold-semantics defects (`Context` of a carrier, shortened `Names`
inside the current context, and a held dynamic `Remove` pattern), not failures
of artifact hydration.

Worker 144 is now reserved by the no-mutation mission
`kernel144_quarantine_nomutation_xh_v2c`.  Before its first pause it required
`$KernelID == 144`, two identical reads of all Global symbol-definition tables,
the three exact fingerprints above, an absent release sentinel, and stable
source SHA256
`52c04ec384284fa288e5297c60c4113adbe1d2d4420d2351509761a52c2c13b7`.
It rechecks source and poison fingerprints every heartbeat and self-releases
only on its sentinel or 24-hour deadline.  Earlier submissions landed on newly
free clean worker 24 and immediately returned `EXIT67` because the ID and
fingerprints did not match; this demonstrates the fail-closed scheduler gate.

Clean worker 24 completed `cf300_s12_second_support_shell_xh_v5` in 189.3
seconds with four native FLINT threads and no messages.  Its live startup
passed the exact dedicated namespace, definition-free symbols,
Global-absence/unchanged checks, preparation/cache/assembly validators, both
fingerprints, and the base ABI contract; cleanup then removed the dedicated
context and again proved Global unchanged.  The target-first maximal second
numerator shell enlarged support from 42 to 56 monomials and the system from
816 to 1040 unknowns.  All four images have ranks `1028/1029`, nullity 12,
and are inconsistent, so exact column inclusion rejects every anisotropic
sub-shell.  The artifact SHA256 is
`d0abf868f3b2356f94e15d6c69410855211baed5e45c1167edbd21d2e6bb28e0`;
the log SHA256 is
`a4beee2094f36f30129438c76d233683aa318741ad404f1fbd2a673e54dcea5e`.
This screen does not repeat the 31 square-free denominator subsets already
rejected by `MAX5`.  A separate Galois-orbit V4
launch failed closed before sampling only because `Names` returned short names
inside its current dedicated context; every substantive hydration and
fingerprint check passed.  The adjacent V5 correction normalizes every raw
name and verifies its resolved context/name/full-name identity; it is active
on clean worker 145 with two native FLINT threads.

The immediate mathematical continuation is therefore two-pronged: finish the
Galois-orbit screen and test genuinely new repeated-pole/local-resonance axes
for sector 12, while replacing the 22-by-22 symbolic regulator normalization
by targeted multiquadratic evaluation/reconstruction on only the
regulator-dependent residue subspace.

### Direct support/alphabet discriminator result

The checkpointed post-merge A0/AS/AL/ASL discriminator completed cleanly in
4,332.7 seconds with no Wolfram messages.  The one-time target census found 40
unique forcing channels, 12 factor dlogs, and a 48-one-form union; compiling
the maximal ASL assembly took 738.8 seconds, while each subsequent direct
sample took only 5.4--8.5 seconds.  At both primes (`10007`, `10039`) and both
epsilon values (`1/21`, `1/11`), every variant is affine-inconsistent:

- A0: 30 support monomials, 36 one-forms, 624 unknowns, ranks `612/613`;
- AS: 42 support monomials, 36 one-forms, 816 unknowns, ranks `804/805`;
- AL: 30 support monomials, 48 one-forms, 672 unknowns, ranks `632/633`;
- ASL: 42 support monomials, 48 one-forms, 864 unknowns, ranks `824/825`.

All four coefficient nullities are respectively 12, 12, 40, and 40 at every
image.  A0's nested prefix transition is reproduced exactly: 19 points are
consistent with rank `608/608`, while 20 and 21 points are inconsistent with
rank `612/613`.  Each coefficient and augmented rank carries an independently
verified native certificate, and each image was atomically checkpointed.
Thus neither the first numerator-support shell, the 12 new factor-dlog
letters, nor their combination resolves the physical direct system.  The
artifact SHA256 is
`99fd3e5e0928f1c452e8ee81a4e1635d601625a88181aef1322799941112d44d`;
the log SHA256 is
`6993d5671a6e7ad16a561c498eae586ea6d4af2de03cf0ac541915393b07b59a`.

## Targeted CF300 regulator reduction and local-pole closure

The preserved sector-11 state admits a substantially cheaper continuation
than a general rank-three reconstruction.  The completed prefix splits as
20 old masters plus the new two-master sector.  Across both one-form
components the old `20 x 20` block has 284 nonzero entries, all exactly
`eps`-homogeneous; the `20 x 2` upper-right block is structurally zero; all
26 nonzero entries of the new `2 x 20` lower-left block share

```text
q(eps) = (2 eps-1)(3 eps-1)(3 eps-2)/eps^2;
```

and all eight nonzero entries of the new `2 x 2` diagonal block are already
`eps` times regulator-free coefficients.  Hence the epsilon-only scalar
transformation

```text
G = diag(I20, t I2),
t = (2 eps-1)(3 eps-1)(3 eps-2)/eps^3
```

maps the lower-left factor to `eps` under the package convention
`Anew = G^-1 A G` and leaves the two diagonal blocks unchanged.  It is
invertible over `Q(eps)`; `{0,1/3,1/2,2/3}` are only exceptional evaluation
values.  The V2 no-kernel structural inspector passed on the pinned
33,012,365-byte input and additionally proved all 88 completed-prefix to
future channels are zero and exactly eight future channels need the right
column scaling.  Its SHA256 is
`036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3`.

The first hardened writer, SHA256
`73a3c23c2a68ebc3ec3196b2bba29cbee1be3c6bf4601d0622126d84fb4576f8`,
passed its 104/104 static gate and then failed closed on clean worker 24 with
exit 71 after silent, schema-valid hydration.  Cleanup proved both the
dedicated context and `Global` state unchanged, and the fresh candidate
directory remains empty.  This is a validator rejection, not a mathematical
counterexample or a partial state write.  A diagnostic adjacent version is
separating the syntactic full-prefix `FreeQ` predicate from the exact changed
block identities before any retry; the V2 source and failed log remain
frozen.

Repeated finite poles have now been closed as a physics-motivated ansatz axis
for the actual rank-two sector-12 channel.  The exact algebraic gauge basis
contributes half-root valuations, so at a catalog divisor the leading
homogeneous operator for an extra positive integral pole order `k` is

```text
(-k + nu_grade/2) I + eps L_f.
```

The dynamically certified `2 x 9` root-square valuation matrix is
`{{0,0,0,0,0,1,0,0,0},{1,0,0,0,0,0,0,0,0}}`; therefore every grade
valuation is zero or one, and the epsilon-constant determinant
`Product_grade(-k+nu_grade/2)^4` is nonzero for every `k>0`.  All nine
catalog factors meet the forcing-valuation bound, and every exact determinant
constant was independently nonzero modulo 10007 and 10039.  The hardened
`CERTIFICATE` rerun completed in 20.8 seconds with driver SHA256
`5c43e5ad88270968d34b35c4445247a815a35fa8e5bb6598013098e1089708b1`.
Its result SHA256 is
`8728854bd5a0a7f0dfc0caad8d8a095a28e0e438751e1719301fa2eb3cc68046`;
the log SHA256 is
`57926ae7175c3b9112f04f42d02452b290cba07c68be48f2f101d359a06cb775`.

This theorem excludes genuine repeated finite-pole resonances, including new
unlisted finite divisors, but not numerator growth at infinity.  The
deliberately over-complete `RAD9` fallback therefore ran only as a bounded
numerator/cancellation adversary: 182 support monomials, 3,056 unknowns, 97
points per image, and exact convolution inclusion of all 511 nonempty divisor
profiles.  It completed normally in 571.1 seconds with no messages.  All four
independent images are inconsistent with ranks `3044/3045` and coefficient
nullity 12; exact support containment transfers each image rejection to every
one of the 511 bounded profiles.  The result SHA256 is
`49b2532ce216bfd8e3eda0e7e3bd759f8d2b7cb6f556d6fd633137c6dfd88cc1`
and the log SHA256 is
`0b6e2f300cf66a3cfb6cd9d5d5f03d71d4c5b7e2ba442e7a9d5957d754bf655e`.
This is a strong finite-field screen, not a lifted characteristic-zero
obstruction, and it cannot override the exact local-resonance certificate's
physical conclusion.

The V3 continuation then passed every internal mathematical predicate and
atomically wrote a 33,009,263-byte candidate with SHA256
`e98957d50ef3dbee431e5b585d7d3068d089b1fcbd4ef417ef3e4464b71c0453`
in 8.8 seconds.  It is nevertheless withheld from continuation because the
pool correctly filed `EXITfinalCode`: `finalCode` was assigned in the package
private context and referenced unqualified after `EndPackage[]`, where it
resolved to an unbound Global symbol.  The immutable failed V3 source and its
candidate remain diagnostic evidence.  Frozen V4 changed only the report
schema/context and the fully qualified terminal status reference.  Its
137/137 static gate and six-file manifest passed, and the central pool run
then completed normally in 8.8 seconds with status `OK`, no messages, and
clean context removal.  Its distinct 33,009,263-byte state has SHA256
`daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009`;
the report SHA256 is
`eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e`.
It remains gated from sector 12 until a separately implemented hydration and
reconstruction validator passes.

That independent gate has now passed.  The first validator attempt failed
closed before loading either state because a pool subkernel did not return an
Association from its external `RunProcess` call; the immutable candidate did
not change.  V2 instead pins the already completed formal inspector JSON and
repeats the substantive identities natively in Wolfram.  It completed on clean
worker 24 in 9.513776 seconds with status `OK`, no messages, and result zero.
It proved the full transformed-versus-prior connection reconstruction, both
left and right inverse products, all lower-left/diagonal/future block laws,
all 88 prefix-to-future zeros, two deliberately wrong-side transformation
mutants, the propagation seal, the epsilon pole-order/depth shift of three,
exact file hashes, and dedicated-context/Global cleanup.  The candidate still
contains exactly its two original files with hashes
`daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009`
and
`eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e`.
The frozen successful validator log and status have SHA256
`185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e`
and
`7f5f4363a3d05766744bf6145b6dc81d88b768d1fd6675f422930f825bee1717`.
A fresh isolated sector-12 strip recapture is therefore the next gate; it must
copy rather than mutate this sealed candidate and independently establish the
relation to the earlier physical sidecar rather than assuming its frame.

The ChatGPT Classics Pro response for request
`51883daa-ea7f-4c7a-88f8-b89e8c23ac78` is now complete (SHA256
`4429b8d4d0eb6bb55f07bdabb741a6eebc5d5467b28acb0a1394ae9823e46ee3`).
Its useful recommendations are to certify the scalar continuation
independently, recapture sector 12, use direct grade arithmetic with split
signs only as an oracle, and stop blind nearby support growth.  Its displayed
scalar is algebraically inverted, however: under `Anew=G^-1 A G` and
`A10=q B`, the required value is `t=q/eps=P/eps^3`, not `eps/q`.  The complete
independent assessment is in
`External/CodexExchange/chatgpt_pro_current_workflow_assessment_2026-08-23.md`.

## CF300 sector-12 recapture audit (V1--V3)

Two record-only recaptures reproduced the post-regulator sector-12/lower-11
strip exactly: 15,667 bytes, SHA256
`f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976`,
with both copied state and pre-sector snapshot still equal to the sealed V4
state (`daf3e994...f9009`).  Neither result is accepted as a production launch.
V1 kept its controls in the Global context and failed its restoration gate.  V2 moved
the controls to a private context and proved all environment, command-line,
protection, and directory components restored, but correctly failed closed on
reused K141: `$LoadFeynArts`, `$LoadAddOns`, and `A0` shadow messages joined a
changed `BuildBasis::length` payload.  Its attempted direct assignment to the
protected `$Packages` also produced `Set::wrsym`.  K141 is therefore held by a
cooperative no-mutation quarantine; no worker or unrelated process was killed
or restarted.

The subsequently frozen V3 source passed its 645/645 static audit and 33-file
manifest, and its body passed a real held Wolfram parse on K146.  An independent
prelaunch red-team then rejected V3 before the output directory was created.
The launcher checked only three known/package-basename shadows, while the
driver clears Global-context `tau,s,u,p,x,y,eps`, reads uncleared `v,w`, overwrites
the global basis state, and (under V3) would install roughly eighty top-level
driver names in the Global context.  The raw `$MessageList` records only
`HoldForm[BuildBasis::length]`, so it cannot distinguish the observed V1
payload `{nb,5,xhat,yhat}` from V2's `{12,24,xhat,yhat}`.  Further blockers are
third-party package definitions and the system `$Path` surviving a restored
`$Packages` list, abort/nonlocal-exit paths bypassing context cleanup, inherited
`FACET_MEMTRACE` permitting an external append, and an incomplete top-level
filesystem inventory.

Consequently V3 is **not launchable** despite its correct hashes.  The active
V4 replacement must run the driver in a disposable context with the Global context
removed from its lookup path, locally inherit/clear/restore the explicit
artifact and basis symbols, localize `$Path`, unset and restore
`FACET_MEMTRACE`, capture a deterministic full message contract, finalize
cleanup on every abort/throw/exit path, require an exact recursive inventory
and the twice-reproduced strip hash/size, and then cooperatively quarantine the
package-loaded worker rather than claim it is reusable.  The V3 output path
remains absent.

The independent package-free V2 strip comparator then corrected an important
provenance assumption.  The 121,662-byte physical sidecar is not pre-regulator:
its pinned result (SHA256 `362e460a...555b4`) explicitly records the same
`P/eps^3` factor.  Reduction over `rho^2=1-4xy` proves the fresh and sidecar
`E`, `C`, and `BBar` arrays identical, while both additional forward and
inverse rescaling mutants fail.  Four exact rational-root samples agree.  The
fresh representation is 15,667 bytes versus 121,662 (7.765x smaller), and its
`BBar` leaf count is 6,707 versus 10,433 (1.556x smaller).  The comparator
source, successful log, and successful status have SHA256
`a9f83628...a87799`, `d21a8d57...f469f`, and `3250a54f...fc2bd45`.

The optimized Galois-orbit V6d run also completed normally in 1,791.863386
seconds with no Wolfram messages.  Its former occurrence-versus-source blocker
is resolved: 32 occurrences deduplicate to 28 sources (four aliases), 112 orbit
candidates, 100 forcing letters/compositions, and 72 appended forms.  Census
took 270.577244 seconds and the exact-channel rebind took 485.843061 seconds.
The maximal system has 108 one-forms, 912 unknowns and 30 points.  All four
images (`p=10007,10039`; `eps=1/21,1/11`) have coefficient/augmented ranks
`888/889` and coefficient nullity 24, so every subset of this four-sign forcing
orbit closure is rejected at every tested image.  This remains a finite-field
screen, not a lifted characteristic-zero obstruction.  The 163,154,433-byte
artifact, log and status have SHA256 `20823fde...eb1cf`,
`173373c6...69a2d`, and `9b80664a...f4ed9`.  The adjacent V6e work targets the
measured fixed workload of 144 multiquadratic compositions/zero tests and 576
rational leaf compiles with collision-checked canonical-leaf memoization,
phase timings, a suffix seal, and one retained legacy whole-result oracle.

## Post-V6d ansatz triage and V6e parse certification

The post-V6d physics audit closes several tempting but uninformative axes.
The active field is already the full rank-two `{r2,r3}` field with all four
grades present; adjoining inactive `r1` alone splits the equation into the
same inhomogeneous rank-two problem plus a homogeneous copy and cannot repair
the contradiction.  Every gauge and residue coordinate is already free at
each fixed epsilon image, so increasing epsilon interpolation degree also
cannot repair an image-wise affine inconsistency.  Constant gauges are in the
current `(4,5)` numerator rectangle because `D/D=1`, and the exact local
resonance certificate closes positive repeated finite poles.  V6d closes the
four-sign orbit of the 28 whole forcing-potential sources, but it does not
close irreducible factor-level divisor orbits or positive polynomial growth at
infinity.

The next bounded mathematical tests are therefore:

1. lift a characteristic-zero left obstruction over `Q(eps)` at the same 30
   nonsingular rational points, using the frozen modular pivot/free-column
   plan, and verify `y^T A(eps)=0`, `y^T b(eps)=1` exactly after clearing
   denominators;
2. compute grade-resolved valuations at the coordinate and mixed toric
   infinity divisors, adding only the finite numerator shell predicted by the
   resulting indicial operator and first scoring it against the exact witness;
3. factor the 28 forcing cores and diagonal catalog in the rank-two field,
   close irreducible factors under the Klein-four action, and quotient their
   exact dlogs by the existing 108-form constant span before any full-rank
   promotion.

The audit also found a real early-screen bug in
`AffineInconsistencyWitness.wl` line 128 (SHA256
`6d2ea565...79f`): `Position[scores,Except[0]]` visits heads and inserts index
zero for the `List` head.  This explains V6d's impossible 289 active positions
for 288 columns and RAD9's width-plus-one count.  It does not invalidate either
inconsistency because it forces, rather than skips, the conservative full
two-rank test.  The required `Pick[Range[Length[scores]],scores,Except[0]]`
repair and zero/all/mixed regressions are recorded in
`codex_package_bug_handoff_2026-08-23.md`; no live package source was edited.

The adjacent V6e prototype is now frozen with helper SHA256
`2fea1e07...f2e8` and integration-block SHA256 `7ea7a437...0dbe`.  Independent
no-kernel reruns passed 65/65 structural checks and 57/57 adversarial checks,
including 800 randomized memo fixtures.  The centralized V4 held-parse gate
(SHA256 `03a0afa0...be08`) then passed on K24 with helper ceiling zero, no
nested kernels, exact source hashes, character/syntax lengths `33177/33177`
and `5336/5336`, `HoldComplete` heads, zero parse/syntax messages, and exact
namespace cleanup.  Its successful log and status hashes are
`bcee1351...317d` and `e4de91a3...66be`.  No speedup is claimed yet: a new
source-pinned V6e driver must still reproduce the V6d fingerprint and all four
rank certificates, then repeat the same input on the same worker before the
485.843061-second rebind baseline can be compared.

Two failed diagnostics remain deliberate evidence.  V1 used the invalid
`parsed=.` form in a `Module` local list; the pool's `KERNELLOST` bookkeeping
label did not reflect an OS/process loss—all eight subkernels remained live.
V2/V3 then showed that unqualified `Names` on a preloaded worker resolves to
``FeynCalc`Names``; V4 explicitly qualifies ``System`Names`` and
``System`Remove``, and
is the accepted gate.  No process was signalled, restarted, or killed.

## Live continuation: V6e runtime and V4 admission, 13:51 PDT

The final V6e runtime bundle is now frozen.  Its manifest SHA256 is
`9a11296f92aaa16543138c622738b1eab2121b7c7693f1ea69c0b47fdaa0a845`;
the driver SHA256 is
`2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884`.
Independent no-kernel reruns passed 89/89 static and 118/118 adversarial
checks.  The final held-parse artifact has SHA256
`4b20582bc1a0230441aaae85954d182dae8e61bb190957a77d329745e43c8cb9`:
all seven pinned sources parsed on K24 with exact syntax length,
`HoldComplete`, zero parser messages, exact namespace cleanup, helper ceiling
zero, and no nested kernels.  The full same-input V6/V6e benchmark is now
running centrally on K24 as mission
`cf300_s12_v6e_correctness_same_input_benchmark_xh_v1`, with four native
FLINT threads permitted only inside the fixed native rank calls.  It will also
write the atomic V6d exact-lift prerequisite needed by the independent
`Q(eps)` left-obstruction driver.  No performance or CF300 certification is
claimed before its two outputs and post-run verifier pass.

The V4 sector-12 recapture was not launched.  Its frozen 171/171 static suite,
226/226 post-launch-verifier suite, and both SHA manifests passed, and the
fixed output directory was absent under `lexists`.  The required read-only
probe then dispatched to K146 and failed closed in 0.557645 seconds with no
Wolfram messages and no output write.  Its structured report proved the
worker was not virgin: 381 existing Global names, 42 source-candidate names,
four package shadows, 1,685 relevant package names, and the loaded package
contexts `CANONICA`, `FeynFacet`, `FeynArts`, and `FeynCalc`.  This is
consistent with the active pool having been launched with `preload=True`,
which loads FACET on every initial and replacement subkernel.  Therefore the
current V4 virgin-worker contract is unachievable in this pool by
construction, not a CF300 algebra failure.  Production remains unsubmitted;
K146 was neither changed nor restarted.  A separate no-kernel review is
testing whether a fully sealed dirty-worker isolation is possible.  Otherwise
recapture must wait for a user-authorized future pool generation whose worker
is genuinely unpreloaded.

The older source-pinned Galois V5 mission also terminated by itself after
9,392.171897 seconds; no process intervention was used.  It reached the same
mathematical screen as V6d (all four images inconsistent, with the known
head-traversal score count 289), atomically wrote its diagnostic artifact,
and then exited 97 because its postcondition found thousands of
definition-free `trRoot*` symbols in the dedicated artifact context.  This is
a namespace-cleanup failure after the result, not contrary physics evidence.
V6d remains the accepted superseding run because it has the corrected scope
handling and stronger exact repeated-pole evidence.  The V5 log/status are
retained unchanged.

## Continuation update: V6e oracle, CF259 V2, and K146 dirty-state evidence

The live V6e runtime passed its first expensive correctness boundary on K24:
the exact split-sign oracle became ready after `450.255283` seconds with
fingerprint
`32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`,
then entered the 72-record exact rebind.  The mission remains CPU-active; this
milestone is not yet a performance or rank-certificate acceptance.  The
adjacent post-run verifier now also pins the generated pool wrapper and proves
the literal final native-thread argument is `4`, the helper ceiling is zero,
all eight command-line entries are unique and correctly ordered, and the
wrapper's `Import`/`Get`/`SetDirectory` target linkage is exact.  Its updated
verifier SHA256 is
`cfa91afd5e355db9596bcaa4bb15c3bbbbe98b11e4384c73bb06f6d1e4e5823d`;
an independent rerun passed all 29 adversarial tests and its four-entry
manifest.

The CF259 rank-three Q4 arithmetic transfer oracle has an adjacent V2 after
V1's mathematical 11/11 result exposed a stale hard-coded assertion count.
V2 adds a genuine twelfth assertion: the certified CF259 root fingerprints,
source indices, and preparation ABI are pinned, while a reversed-root-order
mutant must fail both ABI validators.  The source-derived static gate requires
exactly 12 unique assertion names and rejects missing, duplicate, stale
success-count, and stale recorded-count mutants.  Independent validation
passed 105/105; the V2 driver SHA256 is
`1812ee54af7c9f560484935a0f9fabe351874ec4fd5c8c0b34a66be95730a538`.
It is intentionally not dispatched until K146 is permanently occupied, so
its hard K145 guard cannot race another free worker.

The dirty-K146 recapture review first produced a fail-closed V5 bundle whose
static/adversarial/staged gates passed 183/183, 99/99, and 62/62.  K145 was
then reserved by a no-mutation heartbeat mission, making K146 the sole
dispatchable target.  The V5 no-write probe reached K146 and wrote no recapture
output, but correctly failed under the pool's outer abort gate: definition
fingerprinting called `Options[FeynArts`M$ClassesDescription]`; `Options` has
no Hold attribute, so the symbol's delayed FeynArts reset value emitted
`M$ClassesDescription::undefinedmod` and executed `Abort[]`.

Two subsequent K146-only read diagnostics established the repair boundary.
`Messages` and `Attributes` are held, while
`Options[Unevaluated[symbol]]` is non-aborting; the current `Options[symbol]`
reader aborts reproducibly.  The abort also bypassed the package footer and
left exact, Codex-owned probe namespaces and package-list entries.  A lifecycle
inspector pinned the resulting `$Context` to
`CodexDefinitionReaderHoldDiagnosticK146XH`Private`` and the corresponding
two-entry context path.  The adjacent V5b work therefore must first require
that exact leak census, unwind only the two known `BeginPackage` frames in
LIFO order, restore and verify the pre-V5 baseline, use unevaluated `Options`
reads everywhere, and install cleanup on every abort path before it may emit a
new package fingerprint.  Frozen V5 evidence and the package sources remain
unchanged; no process was stopped, signalled, or restarted.
