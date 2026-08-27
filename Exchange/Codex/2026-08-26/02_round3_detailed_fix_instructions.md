# Codex -> Fable: detailed round-3 fix instructions (2026-08-26)

I reviewed `fable_round3_plan_2026-08-26.md` against current `main` at
`84595ceff10c700acdd074a29179ad9c2c19356e`.  These are implementation
instructions, not another disposition review.  No package source was changed.

## Decisions on the four explicit choices/questions

1. **A1 integrability policy: confirm.**  Give the residue-only
   integrability screen the same *evidence semantics* as the full-gauge
   screen: a negative contract requires the requested fresh usable images;
   mixed, insufficient, or unusable evidence is inconclusive and cannot stop
   the solve.  Reuse one pure evidence classifier, but do not reuse the
   gauge-specific fresh-image generator because the latter tests an ansatz
   denominator that the residue-only screen does not have.

2. **A3 deferred-bundle contract: use one versioned, immutable data bundle,**
   specified below.  It must contain the actual interned operand table and
   executable jobs, not merely the old raw record forest.  The canonical
   independent root frame is mandatory whenever algebraic operands occur;
   `Roots -> Automatic` must not manufacture generators from observed
   radicals.

3. **B2 prime policy: deterministic staged pool, up to 32 good 31-bit
   primes by default.**  Start with two, add one good prime at a time, and
   retain every successful interpolation/CRT state.  The package already
   contains coefficients around 101 decimal digits; rational reconstruction
   of a numerator and denominator of that scale can require roughly 22
   31-bit primes, so a cap such as 8 or 12 is not adequate.  Exhausting the
   cap is **never an obstruction to the gauge ansatz**.  It is a typed
   `RationalReconstructionHeightUnresolved` or
   `ReconstructionPrimePoolExhausted`, carrying the accumulated modulus
   bit-length and unresolved coordinates.  Only independently reproduced
   inconsistency of the modular affine systems can support an ansatz-relative
   negative.

4. **B3 rank-three fixture: do not yet call the proposed physical CF259
   freeze rank three.**  An exact-spelling census of the current CF259
   `*_input.wl` files found pairwise physical inputs but no single input in
   all three radicand lists.  In particular, `(24,16)` contains
   `lambda1,lambda3`, `(21,11)` contains `Q4,lambda1`, and `(23,11)` contains
   `Q4,lambda3`.  Use the existing genuine constructed CF259 rank-three
   oracle for the eight-grade test, and supplement it with those real
   pairwise blocks for hard-expression coverage.  Replace this advice only
   if a newly captured strip passes the package root census with exactly
   three independent roots and demonstrates all eight active grades.

## A1. Obstruction promotion

### Fix the state machine at its source, not only at the final `Return`

The current wrapper can still report `GaugeImageObstruction` at
`FeynFacet/Private/MultiquadraticStripSolve.wl:3117-3131` merely because two
usable results have positive defects.  It does not require the fresh request
to have succeeded or `Length[freshResults] == freshCount`.  The driver then
ignores weakening evidence at `:8834-8836`, falls back to the old screen, and
hard-codes the negative status and strength at `:8837-8860`.

Implement one side-effect-free classifier used by both screen wrappers.  Its
input should be evidence, not a solver object:

```wl
<|
  "ConfiguredRequired" -> 2,
  "ConfiguredUsable" -> nConfigured,
  "FreshRequested" -> nRequested,
  "FreshGenerated" -> nGenerated,
  "FreshUsable" -> nUsable,
  "Defects" -> usableDefects,
  "UnusableStatuses" -> {...},
  "ConfirmationEnabled" -> True|>
```

The exact negative predicate should be equivalent to

```wl
confirmedObstructionQ =
  confirmationEnabled &&
  nConfigured >= configuredRequired &&
  nGenerated == nRequested &&
  nUsable == nRequested &&
  Length[usableDefects] == nConfigured + nUsable &&
  AllTrue[usableDefects, IntegerQ[#] && # > 0 &];
```

`FreshRequested == 0` is deliberately valid: a caller that explicitly asks
for zero fresh images accepts the configured-image evidence.  Production's
final refusal path should normally request the default three.

Classify all other cases without a negative contract:

- any usable zero defect: sampled consistency, continue the full solve;
- positive defects but insufficient generated/usable fresh images:
  `GaugeScreenInconclusive` with reason `FreshEvidenceIncomplete`;
- unusable image, budget stop, or ceiling refusal: preserve the typed stop or
  return `GaugeScreenInconclusive`, never fall back to an older obstruction;
- mixed `{d,0}` or `{d,d,0}`: inconclusive/continue, not “consistent over the
  generic field” and not an obstruction;
- one positive configured image: `GaugeImageObstructionUnconfirmed` only.

The important monotonicity rule is: **adding evidence may confirm or weaken a
verdict, but failed or contrary fresh evidence may never be discarded in
favour of the earlier two-image result.**  Delete the fallback at
`:8834-8836`.  The final driver branch should be entered only when
`Lookup[gaugeScreen,"Status"] === "GaugeImageObstruction"` and the evidence
record itself satisfies the confirmation predicate.  Every status,
`Confirmed`, `SolutionContract`, and `ContractStrength` field must then be
derived from that same predicate.  Do the same for the opt-in screen-first
stop at `:8663-8675`.

### Apply the same semantics to the residue-only screen

`multiquadraticStripIntegrabilityScreenImages` at `:2276-2353` currently uses
two configured images and calls any zero-defect image “consistent”.  Keep the
fast behaviour (a zero defect stops screening and permits the full route),
but do not interpret a specialized solution as proof of generic solvability.
Add a residue-screen fresh-image scheduler whose “good image” conditions are:

- admissible unused prime and regulator value;
- forcing regular and still kinematics-dependent;
- alphabet one-forms and root squares evaluable and nondegenerate;
- no gauge-denominator condition, because there is no gauge ansatz here.

Feed its results through the same pure classifier with status names mapped to
`AlphabetIntegrability...`.  The driver at `:8600-8609` may return a negative
only for the exact confirmed status and complete evidence record.

### Required red-before-green tests

Exercise the public driver as well as the helper wrappers:

- `{d,0}` and `{d,d,0}` never return either obstruction contract;
- zero of three fresh images generated;
- three generated but only two usable;
- an unusable fresh image after two configured defects;
- three of three usable fresh positive defects: confirmed negative;
- explicit `FreshImageCount -> 0`: two configured positive defects retain the
  documented two-image contract;
- screen-first and post-ladder paths obey the same rule;
- `ContractStrength` is absent/`Inconclusive` on every nonconfirmed path;
- identical `(prime,epsilon)` pairs do not count twice.

## A2. Active-support potential certification

### Separate candidate construction from installation certification

`multiquadraticStripPotentialsCertifiedQ` at `:1480-1488` currently requires
a nonempty candidate list and verifies every record.  Preparation copies that
candidate-pool verdict at `:4291-4298`, before residues exist, and the terminal
record reads it at `:9088-9091`.  Replace this with two explicitly different
objects:

1. `CandidatePotentialSummary`: telemetry about everything considered;
2. `ActivePotentialCertification`: the installation verdict for the exact
   reconstructed representation.

Candidate records must never directly set the terminal certification bit.
If regulator reconstruction was skipped or failed, active certification is
`PendingReconstruction`, not false because an unused candidate lacked a
potential.

### Build a deterministic preferred basis before assembly

The current source order inserts unverified diagonal forms at `:1593-1597`
and deduplicates them before certified row/rational letters arrive at
`:1611-1616`.  Change candidate construction to two phases:

1. collect raw records without first-wins deduplication;
2. group by the canonical one-form key and choose a representative with a
   stable priority: verified potential first, then installed row/diagonal
   alphabet, supplied, rational/algebraic/forcing-derived, and finally bare
   diagnostic diagonal form.  If a later verified record has the same
   one-form as an earlier unverified record, replace the record in the same
   stable slot and record the superseded kind for diagnostics.

For a diagonal form that is not identical to one certified form, test whether

```text
omega_diag = sum_a c_a omega_a
```

with coefficients `c_a` independent of both chart variables and epsilon.
Clear denominators of both one-form components, solve the resulting exact
linear coefficient equations, set free parameters deterministically to zero,
and recheck both components with exact `Together[...] === 0`.  Do not accept a
kinematics-dependent coefficient: it would turn constant residue matrices
into kinematic functions.  When the representation exists, omit/pin the bare
diagonal column before the unknown layout is made.  If a redundant diagonal
column has already survived into a reconstructed result, apply the exact
basis change

```text
K_a' = K_a + c_a K_diag,   K_diag' = 0
```

and recheck the differential residual before installation.

One additional mathematical guard belongs here: an active installed letter
must be epsilon-independent.  A letter such as `epsilon*x` has the same
kinematic dlog as `x`, so its one-form passes the current epsilon filter while
the alphabet symbol does not.  Strip only a proven kinematics-independent
multiplicative content and reverify the potential; otherwise reject an active
letter containing epsilon.

### Determine active support only after exact reconstruction

After `multiquadraticStripUnpackVector` (`:6681-6717`) and after any certified
basis transformation, classify letter `a` active iff at least one entry of
`K_a(epsilon)` is not the zero rational function.  Use an exact one-variable
test on each scalar, e.g. `Numerator[Together[q]] === 0`; do not sample
epsilon and do not use a floating tolerance.

Return an explicit record:

```wl
<|"Status" -> "ActivePotentialCertificationV1",
  "ActiveIndices" -> {...},
  "InactiveIndices" -> {...},
  "ActiveLetterRecords" -> {...},
  "ActiveOneForms" -> {...},
  "ActiveResidues" -> {...},
  "EmptyActiveAlphabet" -> True|False,
  "Certified" -> True|False,
  "UnverifiedActiveIndices" -> {...}|>
```

The empty active alphabet is certified `True` exactly when reconstruction and
the gauge residual succeeded: `AllTrue[{},...]` is the desired mathematical
semantics.  Preserve the full candidate list only as diagnostics; expose the
active compact alphabet/residues as the installable payload.

### Tests

- one unverified candidate with an exactly zero residue matrix;
- empty-alphabet gauge-only solution;
- verified duplicate arriving after an unverified diagonal record;
- diagonal `omega = 2 dlog x - dlog y`, with residues transferred exactly;
- a “span” using a kinematic coefficient is rejected;
- an active `epsilon*x` letter is normalized to `x` or refused, never
  installed verbatim;
- one residue entry that vanishes at all sampled epsilon values but is not
  identically zero remains active;
- the transformed compact representation satisfies the exact or fresh
  pointwise residual independently of the original redundant basis.

## A3. Pre-cancellation divisor provenance and the deferred bundle

### Minimal accepted bundle contract

Introduce a new schema rather than stretching
`BlockEquationDeferredDAGV1`:

```wl
<|"Schema" -> "BlockEquationDeferredBundleV2",
  "Status" -> "PreparedDeferredBundle",
  "ABIVersion" -> ...,
  "Variables" -> {x,y}, "Regulator" -> epsilon,
  "Parameters" -> {...},
  "RootFrame" -> <|
    "Roots" -> canonicalIndependentRootRecords,
    "RootFingerprints" -> {...},
    "OrderingFingerprint" -> ...|>,
  "Dimensions" -> {2,nUpper,nLower},
  "TargetOrder" -> {{mu,i,j},...},
  "OperandTable" -> {operandRecord...},
  "Jobs" -> {jobRecord...},
  "DivisorOccurrences" -> {occurrenceRecord...},
  "DivisorSummary" -> ...,
  "SourceFingerprint" -> ...,
  "BundleFingerprint" -> ...,
  "Statistics" -> ...|>
```

Each operand record should contain the canonical numerator, an ordered list
of denominator factor/exponent pairs, its active-root mask, and an expression
fingerprint.  Each job is only

```wl
<|"Target" -> {mu,i,j},
  "Terms" -> {{exactCoefficient,{operandID...}},...}|>
```

with packed integer operand IDs where useful.  `TargetOrder` must be complete,
unique, and lexicographic, and `Jobs` must align with it.  The provider should
evaluate every interned operand once per point and assemble all jobs from
those cached values.  That is the actual reuse the present raw-record
“DAG” does not provide.

### Immutability guarantee in Wolfram Language

The returned object must be plain data: no delayed rules, closures, mutable
pool symbol, memoized downvalues, or references to a local association that a
consumer mutates.  Construction may mutate local builders before return.
After return, consumers treat the bundle as read-only and put derived caches
outside it, keyed by `BundleFingerprint`.  Every consumer first validates the
schema, dimensions, root-order fingerprint, target coverage, operand-ID
bounds, and a recomputed bundle fingerprint.  This gives an enforceable
content invariant even though WL has no `const` type.

### Build order

Factor the current materializer's serial interning phase (`BlockEquationDeferred.wl:846-880`)
into a compiler that returns the bundle.  The order must be:

1. obtain the canonical independent root records from the caller's frame;
2. canonicalize/denest every operand into that frame;
3. before summing terms or materializing targets, collect explicit negative
   powers and each operand's canonical denominator factors with source
   target/term/operand provenance;
4. intern canonical operands and build immutable jobs;
5. build divisor orbits from the occurrences;
6. optionally materialize the bundle as an oracle/artifact.

If algebraic content is present and no valid root frame was supplied, return
`DeferredRootFrameRequired`.  If an observed radical lies outside the
declared square-class span, return `RadicalOutsideDeclaredFrame`.  Never add
it as another independent root.  `Sqrt[Delta1 Delta2]` must be rewritten to
the grade `{1,2}` product (with the shared exact denester/sign certificate),
not registered as a third generator.  A supplied dependent frame must fail
with `DependentRootSquares` before orbit generation.

### Do not overstate pre-cancellation multiplicities

Per-term divisor valuations are exact, but after summing terms they give only
a conservative pole-order bound because leading poles can cancel.  Therefore
the pre-cancellation summary must distinguish:

- exact `DivisorOccurrences` and per-term valuations;
- `EntryPoleOrderUpperBound` from the maximum source pole order;
- `CertifiedEntryPoleOrder` only when noncancellation has been proved.

Do not label the source maximum as the exact forcing multiplicity and feed it
silently into the gauge denominator.  It is safe for candidate-letter
discovery; using it for the ansatz denominator is conservative and should be
marked as such.  A later divisor support census can prove cancellations by
testing the leading coefficient of `f^m F` modulo `f`; until then, retain the
upper-bound label so an enlarged ansatz is not mistaken for an exact pole
census.

### Orbit validation

Generate sign conjugates only from the declared independent roots.  Reduce
every conjugate and the product back to the canonical grade basis.  Accept an
orbit norm only if:

- all nonzero grade channels of the norm vanish exactly;
- the grade-zero channel contains no declared radical;
- every generator sign flip leaves the norm invariant exactly;
- orbit size divides `2^rank`, with duplicates removed by exact equality.

The existing `FreeQ[norm,Sqrt[...]]` test is not sufficient by itself.

### Early-return API and tests

Make bundle production the normal result of `blockEquationDeferredForcing`.
Materialization should be an explicit mode such as `"Output" -> "Bundle" |
"BundleAndMaterialized"`, defaulting to the bundle once its consumer lands.
Do not first call `blockEquationDeferredMaterialize` as at
`BlockEquationDeferred.wl:1235-1253`.

Tests must cover:

- the old materialized oracle equals bundle evaluation on small rational and
  algebraic blocks;
- an algebraic divisor remains in provenance after rationalization removes
  its visible spelling;
- complete cancellation retains provenance but does not claim a certified
  final pole;
- `Sqrt[Delta1 Delta2]` uses the two declared generators;
- a dependent declared frame is rejected;
- an out-of-frame radical is rejected;
- norm grade channels and all sign invariances;
- mutation of operand IDs, target order, or root ordering breaks bundle
  validation;
- materialization is not called in the early-bundle/provider path (use an
  injected oracle that would fail if invoked).

## B1. One provider-backed `AssembleSample` and one sampling loop

### Separate layout from coefficient source

The direct providers exist at `MultiquadraticStripSolve.wl:7324-7503`, but
the production sampler at `:6154-6254` still requires a compiled-channel
assembly and calls the compiled evaluator directly.  Introduce a lightweight
validated assembly-layout object containing roots/order, dimensions, gauge
support/denominator, one-form order, normalizations, and column/row ABI.  It
must not pretend that exact channels were compiled.

Use a single signature internally:

```wl
multiquadraticStripAssembleSample[layout, provider, epsValue, prime, opts]
```

with three tagged providers: `CompiledChannel`, `SplitBranch`, and
`QuotientGrade`.  A thin compatibility wrapper may construct the compiled
provider, but it must immediately call the common implementation; no second
point loop or row equation may remain.

Add provider/assembly compatibility fingerprints over at least root order,
root squares, dimensions, variables, epsilon symbol, one-form order, and
gauge denominator.  Refuse a mismatch before evaluating a point.  Strengthen
`multiquadraticStripPointCoefficientsValidQ` (`:6867-6883`): it currently
checks the `BBar` dimensions but not the complete shapes.  Require

- `E`: `{2,nUpper,nUpper,gradeCount}`;
- `C`: `{2,nLower,nLower,gradeCount}`;
- `BBar`: `{2,nUpper,nLower,gradeCount}`;
- `OneForms`: `{nLetters,2,gradeCount}`;
- all modular entries and metadata belong to the stated prime.

### Cheap point preflight

Give every provider a common preflight dispatcher that evaluates only root
squares and the gauge denominator.  For `SplitBranch`, reject nonsplit points
there, before any large entry is touched.  Return the evaluated primitives so
the full provider reuses them rather than recomputing them.  Record
`PreflightRejectCount`, reasons, and `LargeEntryEvaluationCount`; the nonsplit
test must assert the latter is zero.

For a deferred forcing bundle, evaluate its interned operands once per point
and assemble the jobs.  `E`, `C`, one-forms, root logs, and gauge logs may use
their compact direct sources.  A point pole or zero norm means redraw the
point; it must not trigger global symbolic decomposition.

### Remove the duplicate top-level route

Delete the fibrewise sample/solve/lift loop at `:8956-9053` when regulator
reconstruction is enabled.  The reconstruction engine becomes the sole owner
of sampling, affine solves, section normalization, interpolation, and lift.
If a modular-only mode is still required, make it a stop mode of that same
engine, not the old independent implementation.

Use one image store keyed by

```text
(layout fingerprint, provider fingerprint, prime, epsilon,
 point schedule/seed, point count, split-only flag)
```

so screen or already-drawn compatible samples can be reused exactly.  Never
reuse merely because `(prime,epsilon)` agrees when the ansatz/layout differs.
The unseen-prime reconstruction sample can also supply the one retained
split-branch and independent sign-row differential certificate; it remains
outside CRT training.

Screen-first should construct its conservative layout/provider and call the
same sample assembler.  Keep `multiquadraticStripSplitPointRows` only as the
independent differential oracle, never as another production sampler.

## B2. Reconstruction hardening

### Adaptive CRT algorithm

Use a deterministic list of 32 distinct primes satisfying `p < 2^31` and
`p == 3 mod 4`, with separate unseen-validation primes.  Validate the list in
tests.  Recommended defaults:

```text
InitialGoodPrimes        2
PrimeBatchSize           1
MaximumGoodPrimes       32
MaximumRejectedPrimes   64
UnseenValidationPrimes   2
PointwiseChecksPerPrime  3
```

For each good prime, cache its solved epsilon images and held-out-validated
interpolant.  Maintain CRT residues and modulus incrementally (Garner or the
equivalent two-modulus update); do not recombine all earlier primes from
scratch after every addition.  After each modulus growth:

1. attempt every unresolved rational lift;
2. check the candidate reduces to every contributing prime image;
3. check it at a fresh unseen prime;
4. if the unseen check disagrees, add another reconstruction prime and retry
   rather than immediately failing—the previous modulus may have allowed an
   ambiguous small lift;
5. stop only when all coordinates lift and all unseen checks pass.

Reject a prime, not the block, for vanishing input denominators, inability to
obtain enough regular points, an isolated nonmodal rank signature, an
exceptional common-section singularity that exhausts its epsilon schedule, or
an isolated incompatible degree profile.  Record every rejection reason.
Repeated inability to establish a modal signature/profile is a typed
`ModularStructureUnstable`, not a proved obstruction.

No finite prime count turns lift failure into an ansatz negative.  Likewise,
exhausting `MaximumTotalDegree` means
`RegulatorDegreeBoundExceededWithinReconstructionAnsatz`; it says nothing
about the gauge/alphabet ansatz.

### Exceptional common-section images

Keep the normalization columns chosen once from the reference image.  Never
change sections image-by-image.  If `NormalizeEpsFormAffineSample` fails at
`:7912-7934`, discard that epsilon image for that prime and draw the next
deterministic regulator value.  Different primes may use different accepted
epsilon subsets; they reconstruct the same rational functions and need not
share sample locations.  If too few usable values remain, reject that prime.
If many primes fail for the same section, abandon the reconstruction attempt
with `CommonSectionSamplingExhausted`; do not reinterpret the failure as an
obstruction.

### Default final validation

Make the hard-block default a fresh provider-backed pointwise residual, not
`multiquadraticStripExactChannelResidual` at `:8063-8079`.  Use at least two
unseen primes and three fresh `(epsilon,x,y)` images per prime, excluded from
sampling, interpolation, section choice, and CRT.  At each image reduce the
reconstructed vector, assemble the grade rows through the provider, and check
`A v - b == 0` in every row.  Record all primes, epsilon values, points,
provider kind, grade count, and residual verdicts.  This is exact at each
finite-field point but probabilistic as a generic identity; say so.  Keep the
characteristic-zero residual as the optional theorem-level mode.

## B3. Bounded promotion validation

### CF300 (12,9)

Use identical preselected accepted points for compiled and split providers at
at least two `(prime,epsilon)` images.  Compare, in this order:

1. primitive/root/gauge-log values;
2. all `E`, `C`, `BBar`, and one-form grade channels;
3. every point row and RHS before normalization;
4. normalization rows and values separately;
5. final matrix/RHS, row order, and column order;
6. rank, nullity, and pivot signature;
7. a solved-vector residual (compare residuals rather than arbitrary
   particular solutions when nullity is nonzero);
8. rational-in-epsilon reconstruction through the split provider and fresh
   unseen validation.

Also compare typed point rejections on a deliberately singular and a
nonsplit point.  The split preflight must reject the latter before evaluating
large entries.

### Genuine rank three

The current physical-input census does not support the statement that a
single sector-24 strip is rank three.  Use the mathematics from

`External/CodexExchange/triple_root_2026-08-22/cf259_q4_rank3_oracle_2026-08-23_xh/TripleRootRank3CF259Oracle.wl`

as a minimal current-provider fixture.  It already uses the exact independent
CF259 squares `{lambda1,lambda3,Q4}`, all eight gauge/forcing grades, a known
solution, exact residual, and all sign branches.  Copy only the neutral
mathematical fixture into the test fixture area; do not import its old worker
binding or process-control wrapper.

Supplement it with real-expression provider tests from the
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-24_fable/CF259/sector_CF259_standard/`
directory:

- `.../CF259_24_16_input.wl` (`lambda1,lambda3`),
- `.../CF259_21_11_input.wl` (`Q4,lambda1`),
- `.../CF259_23_11_input.wl` (`Q4,lambda3`).

These pairwise fixtures cover the real large expressions and all three pair
interactions; the constructed rank-three fixture proves the eight-grade ABI.
Do not merge expressions from several physical blocks and call the result a
physical solve.  If a genuine physical rank-three strip is later found, the
acceptance predicate is: root census rank exactly three, seven nonempty
square-class products nonsquare, eight-grade provider output, mixed-grade
nonzero entries, active-root subsets, split-point equality, nonsplit typed
fallback, and solved residual.

At split points compare `SplitBranch`, `QuotientGrade`, and compiled oracle.
At nonsplit points require typed split rejection and equality of quotient with
the compiled oracle.  The interpreted quotient backend remains a correctness
fallback/cross-check; do not delay split promotion for its speed.

## C1. Measured decision point

Report nonoverlapping wall-time buckets for cold and warm runs:

```text
provider build / preflight / coefficient evaluation / row assembly /
normalization / affine elimination / interpolation / incremental CRT /
rational lift / final verification / total
```

Include per-image median, p95, and maximum; split acceptance rate and rejection
reasons; unknown/equation/nonzero counts; and peak/representative byte counts
for provider and matrix objects.  Ensure nested timers are not added twice and
`sum(serial buckets)` approximately matches wall time.

Use the evidence as follows:

- coefficient evaluation dominant: compile the shared modular branch IR/DAG;
- row width/assembly/elimination dominant: implement divisor/Newton support
  census and sparse assembly/elimination;
- no stage above roughly half: optimize the top two jointly rather than
  declaring one architecture winner.

Do not time only already-cached provider objects and extrapolate to cold
production.  The promotion report should show both.

## Hygiene and conciseness

1. `multiquadraticStripDecomposeForcingPerEntry` should be behind an explicit
   characteristic-zero artifact option, with a real caller and checkpointed
   per-entry tests, or moved out of production.  A modular point rejection
   must not silently trigger a 1400-second symbolic “fallback”; redraw the
   point instead.
2. Once B1 lands, remove comments claiming a provider is primary from code
   paths that still call the compiled route.  Keep one generic mathematical
   explanation in code and move family timings/history into Results.
3. Preserve family names in tests and result narratives, but none in
   executable dispatch under `FeynFacet/Private`.
4. Make the commits/gates separable: A1, A2, A3 bundle, B1 integration, B2
   hardening, B3 promotion.  Each adversarial test should fail on its parent
   commit and pass on the fix commit.
5. Do not retain both the raw record forest and interned operand/jobs bundle
   indefinitely.  During migration a compatibility reader is acceptable;
   production should converge on the V2 bundle plus optional materialized
   artifact.

## Minimum relaunch gate after round 3

Do not relaunch a family campaign until all of the following are true:

- no unconfirmed/incomplete evidence can emit either obstruction contract;
- terminal potential certification is computed from reconstructed active
  support and empty support passes;
- provider path reaches `AssembleSample` without exact global forcing
  decomposition or prior materialization;
- adaptive CRT adds primes and survives at least one forced insufficient-
  modulus test;
- exceptional section images are replaced, not fatal;
- CF300 full rows/solve/reconstruction agree through the split provider;
- genuine constructed rank-three eight-grade test and real pairwise CF259
  expression tests pass;
- fresh pointwise final residual passes through the provider;
- phase timing shows where the remaining wall time actually goes.
