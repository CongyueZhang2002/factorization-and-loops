# Finite-field performance audit for the triple-root workflow

Date: 2026-08-23  
Status: source-pinned, read-only audit; package integration deferred

## Conclusion

The finite-field arithmetic is fast enough.  The current performance problem
is the symbolic boundary around it:

1. exact multiquadratic channel compilation takes about 682 seconds;
2. the current factor/support discriminator spent 1183 seconds before its
   first direct compilation milestone;
3. a warm direct CF300 image takes 3.73 seconds, of which 2.65 seconds is
   point/row assembly and 0.68 seconds is repeated full-assembly validation;
4. native affine RREF is 0.13--0.35 seconds at the physical matrix shape and
   was below one percent of the earlier twelve-image campaign;
5. exact CRT/rational reconstruction is currently 2.7 seconds at rank two and
   9.3 seconds at rank three in the existing scaling evidence, so it is not a
   first-wave optimization target.

The correct near-term implementation is therefore to make the already
validated direct-channel cache/rebind route the production architecture,
then optimize the compiler and batched evaluator.  More work on dense modular
elimination will not materially shorten CF300.

No Wolfram kernel was launched by this audit, no process was signalled, and no
package source was edited.  The only new code is a non-evaluating static cache
census under this directory.

## Measured evidence

### Fair cached CF300 A0 benchmark

The final common-stream benchmark is source/input/ABI-bound, reads a previously
adversarially validated 32.8 MB cache, never calls `DRCAPrepare`, performs seven
warm repetitions, and compares the complete `672 x 624` matrix and RHS with
the legacy split-sign builder.

| quantity | result |
|---|---:|
| cache read plus full validation | 1.803819 s |
| direct cold image | 9.219459 s |
| cold prime-plus-epsilon collapse | 5.411802 s |
| cold point assembly, 21 points | 2.711063 s |
| direct warm image, median | 3.728163 s |
| warm repeated assembly validation, median | 0.680287 s |
| warm epsilon-cache hit, median | 0.000047 s |
| warm point assembly, median | 2.649368 s |
| warm sign transform, median | 0.816235 s |
| legacy warm split-sign assembly, median | 82.614038 s |
| direct grade-basis speedup | 22.159x |
| direct plus sign-transform speedup | 18.179x |
| direct attempts for 21 accepted points | 21 |
| split attempts for 21 accepted points | 78 |
| measured split-point attempt penalty | 3.714x |
| nonsplit points among direct target points | 15/21 |

The complete matrix and RHS were exactly equal after the independent sign
transform.  Runtime messages were empty and source hashes were stable.

Evidence:

- artifact:
  `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_common_stream_cached_benchmark_xh_v1.wl`,
  SHA-256
  `908655450bc99be903c7db5d4369d56f5fd42bc3f3f7259e14f9af620431b64a`;
- log SHA-256
  `9ed894e0316bb40322f007a86a738a58caa724e1cfb01e7611d7157f5ef1fe87`;
- status SHA-256
  `ee14a876b032d3b2af45442bcc8e4f9f1a59cc0612d0f69d985ce70ee921d0e8`.

### Compilation, cache and ansatz rebind

- A0 direct compile: 682.267943 s.
- Validated cache load: 1.803819 s, a 378.2x replacement for recompilation.
- The full compile amortizes only after about 8.6 images at the measured warm
  direct/legacy difference.  Persistent cache reuse removes that startup cost
  instead of merely amortizing it inside one run.
- The QUICK rebind gate passed.  Rebinding identity/support/denominator/
  one-form/combined variants took 9.00--12.18 seconds.  The combined rebind
  took 9.508653 seconds, 71.75x below a fresh A0 compile.
- The physical projection, non-prefix mutant and source mutant gates passed.

The production unit must consequently be a compiled equation core plus a
small ansatz layer, not one monolithic compilation per support/denominator/
alphabet candidate.

### What exact serialized deduplication can and cannot buy

The static census of the validated cache found:

| serialized type | records | exact unique | duplicate occurrences | byte saving if interned |
|---|---:|---:|---:|---:|
| rational leaves | 393 | 267 | 126 | 45,143 bytes (0.293%) |
| polynomial leaves | 786 | 474 | 312 | 1,351,618 bytes (8.78%) |

Thus there is useful repeated structure by count, but almost all repeated
rational leaves are small zeros/constants.  Interning final serialized
records alone will not explain or remove the 682-second compile.  The larger
win must happen before serialization: avoid repeated `Together`, avoid the
dense symbolic multiquadratic inverse, compile the already canonical channel
once, and separate the equation core from the ansatz.

Static census artifact:
`cf300_a0_serialized_cache_census.json`, SHA-256
`da8b2aa4bb392ba69e95111c68e784522d84dabb44d0d9ceab69cf3fb20d7c8b`.

### Census/variant construction

The active direct discriminator reported:

- preparation valid at 8.62 seconds;
- census complete at 1183.14 seconds;
- 40 unique rational strip channels;
- 12 factor dlogs and 48 union one-forms.

The current driver nevertheless decomposes the strip again, canonicalizes
every channel again, factors numerators and denominators, recomputes one-form
keys repeatedly, builds four full ABI payloads, and fully validates every
variant.  It then starts a fresh ASL compile.  The validated A0 cache already
contains exact and compiled `E/C/BBar/root` channels, and the rebind gate proves
that support changes need no compile at all.  This 1183-second stage is the
largest currently exposed avoidable cost.

## Prioritized patch plan

### P0: use the validated cache and ansatz rebind as the architecture

Promote the contracts represented by `DirectRootChannelCompiledArtifact.wl`
and `DirectRootChannelAnsatzRebind.wl` after all source-pinned missions end.
Follow the package convention of typed status associations and fail-closed
source/ABI checks.

Required structure:

- immutable `EquationCore`: `E`, `C`, `BBar`, root squares and root dlogs;
- `AnsatzLayer`: support, one-forms with certified potentials, gauge
  denominator and its dlog, column order and normalizations;
- derived artifact binding parent cache file SHA, parent cache key, core
  fingerprint, target preparation ABI and all newly compiled suffixes;
- support-only rebind performs zero rational-channel compilation;
- denominator rebind compiles only `D` and `dlog D`;
- one-form rebind compiles only a prefix-preserving suffix;
- every derived artifact gets its own exact differential/adversarial
  attestation before a solve consumes it.

Measured payoff: 56--76x for current rebind operations and 378x for validated
cache load versus fresh compilation.

For ansatz search, construct a certified left inconsistency witness once at
each of the four existing `(p, eps)` images.  Evaluate candidate column blocks
against those witnesses before building a full matrix.  A zero witness score
rejects a candidate rigorously.  Only candidates that pierce all witnesses
receive full rank tests.  This should be used for missing denominator factors,
anisotropic support edges and algebraic one-form orbits.

### P0: validate once, then use a private sealed handle

`DRCAAssembleSample` currently recomputes the full assembly fingerprints on
every warm image.  That costs a median 0.680287 seconds, 18.25% of the warm
wall.  Do not weaken validation to a caller-supplied fingerprint string.

Patch-ready design:

1. `DRCAOpenCompiledArtifact[file]` performs the existing full read/source/
   ABI validation once and stores the immutable assembly in a private,
   process-local registry.
2. It returns an unforgeable session handle containing a random nonce,
   process ID, artifact SHA and assembly fingerprint.
3. Hot prime/collapse/sample functions accept the handle and retrieve the
   stored assembly; they do not accept a mutable assembly plus a bare
   fingerprint as an equivalent fast path.
4. Cache keys include the registry generation.  Clearing/reloading invalidates
   all older handles.
5. Public mutation, wrong-process, stale-generation, source-drift and cache-
   file replacement tests must fail closed.

This directly removes about 0.68 seconds per warm image without reducing the
trust boundary.

### P1: replace the exact compiler's repeated algebra

The present call chain is expensive by construction:

`drcaCompileTensor` -> `drcaDecomposeScalar` -> `TRFieldDecompose` ->
symbolic field inverse -> channel-wise `Together` -> compose -> another exact
`Together` round trip -> `drcaCompileRational` -> another `Together`.

Implement a V2 compiler with these changes:

1. **Root-free fast path.**  If a scalar contains no declared radical, run one
   rational canonicalization and return grade zero plus structural zeros.
2. **Recursive norm inverse.**  Replace the dense symbolic `LinearSolve` in
   `TRFieldInverse` by the tower recurrence
   `(a+b r)^(-1) = (a-b r) (a^2-delta b^2)^(-1)`, recursively in the
   lower-rank subfield.  Retain one exact multiply-to-one check.  This is the
   standard multiquadratic inversion and avoids a fresh symbolic 4x4/8x8 solve
   for each denominator.
3. **Canonical decomposition result.**  Return canonical numerator/
   denominator channel pairs and a round-trip certificate from one function.
   `drcaCompileRational` consumes these pairs without another `Together`.
4. **One round-trip per source scalar.**  The independent full tensor
   round-trip remains an acceptance gate, but do not compose and normalize
   every scalar again after the decomposition routine already proved its
   inverse and channel identity.
5. **Scalar/polynomial pools.**  Store unique compiled leaves once and replace
   tensor leaves by integer pool IDs.  Reduce, epsilon-collapse and evaluate
   each pool entry once, then gather by ID.  Pool fingerprints and index maps
   are part of the ABI.
6. **Core/ansatz split.**  Compile `E/C/BBar/root` once.  One-form and
   denominator suffixes remain separate pools so a rebind cannot invalidate
   the core.
7. **Stage telemetry.**  Persist decomposition, inversion, round-trip,
   rational canonicalization, coefficient extraction, fingerprint and
   serialization seconds plus leaf/term counts.

Parallel compiler mode should canonicalize and assign stable scalar IDs on
the main kernel, farm only unique IDs, and reassemble in ID order.  Worker
results must bind the source scalar hash and root-order fingerprint.  Use four
workers initially: these symbolic tasks are memory-heavy, and eight workers
should be enabled only after an RSS stress gate.

Acceptance target, not an unmeasured promise: reduce the physical cold compile
from 682 seconds to below 120 seconds while remaining exactly `SameQ` at the
channel/compiled ABI level and differentially identical at ranks 0--3.

### P1: compile a batched evaluator plan

Warm image anatomy makes this the next numerical kernel:

- point assembly: 2.649 seconds (71.1%);
- repeated validation: 0.680 seconds (18.2%);
- warm epsilon cache: negligible;
- remaining wrapper/source/normalization overhead: about 0.40 seconds.

The current point function re-scans all image forms with `Cases`, recomputes
required exponent unions, creates power associations, evaluates every
rational leaf by recursive tree traversal, and materializes a dense row array
for each point.

Patch-ready V2 evaluator:

1. Epsilon collapse returns an `EvaluatorPlan` with a unique polynomial pool,
   integer tensor index maps, maximum exponents, support exponent vectors and
   a sealed assembly/prime/epsilon key.
2. Build x/y power tables for a batch of candidate points by recurrence, not
   repeated `PowerMod` and `Association` lookup.
3. Evaluate each unique sparse polynomial over the whole point batch, invert
   unique nonzero denominators once per point, then gather rational/tensor
   values by integer index.
4. Reject duplicate candidate points modulo `p` before expensive evaluation.
5. Assemble grade rows from precomputed xor/product-grade tables.  Keep dense
   materialization only at the consumer boundary; a native rank backend may
   consume streamed row chunks directly later.
6. Keep the present typed root-zero, denominator-zero and rational-pole
   diagnostics.  A failure-only diagnostic pass may re-evaluate the small
   primitive subset.
7. Enforce a machine-integer accumulation bound.  Products are safe for
   `p < 2^31`, but an unchecked packed `Total` can still overflow if the term
   count grows.  Use chunked modular sums or certify
   `termCount (p-1) < 2^63`.

For one-image latency, four point workers give an ideal point stage of about
0.66 seconds.  With the sealed validation handle, a realistic first
acceptance target is at most 1.5 seconds for the 21-point warm A0 image
(2.5x over the current warm path).  If Wolfram batching misses this target,
move only the sparse polynomial evaluation and grade-row fill to a small
native machine-word backend; keep preparation and certificate logic in
Wolfram.

Cold prime-plus-epsilon collapse is 5.41 seconds.  Split its telemetry into
prime reduction, epsilon Horner collapse, pool validation and fingerprinting.
Pool interning should reduce the 393 rational/786 polynomial leaf traversals;
do not optimize it blindly until the split is measured.

### P1: make the factor census targeted and reusable

For denominator tests, factor only denominators of the forcing channels first.
Do not factor every numerator and all diagonal entries.  For epsilon-free dlog
candidates, the exact epsilon-free factor is contained in the polynomial
content with respect to epsilon: compute the GCD/content of epsilon
coefficients and factor that bivariate content.  This is much cheaper than a
full trivariate numerator/denominator `FactorList` and preserves the exact
meaning of "epsilon-free factor".

Persist a `ChannelCensusArtifact` bound to the compiled core:

- canonical channel pool IDs and numerator/denominator IDs;
- denominator factors with multiplicities;
- epsilon-free contents/factors;
- one-form potential, exact dlog pair and Galois orbit metadata;
- factor/potential fingerprints;
- per-stage timings and resource caps.

Use cached `ExactChannelForms` rather than calling `TRFieldDecompose` on the
strip again.  Compute each one-form key once and carry it through all column
maps and result summaries.  Construct lightweight ansatz payloads from a
sealed core fingerprint instead of rebuilding/validating the entire record
four times.

The current 1183-second census is the baseline.  A first acceptance target is
below 120 seconds with identical 40-channel/12-factor/48-form results; the
target must be verified by the substage telemetry rather than assumed.

### P2: coarse scheduling before nested parallelism

Use two mutually exclusive modes:

- **throughput mode:** up to eight independent `(prime, epsilon, ansatz)`
  images, one Wolfram pool kernel each, FLINT affine RREF at one thread;
- **single-image latency mode:** one image with up to four point/compiler
  workers and, only during the isolated native-rank phase, up to four FLINT
  threads.

Do not use eight image jobs each with multithreaded FLINT or nested point
workers.  Native RREF saves only about 0.2 seconds between one and four
threads, while oversubscription would slow the symbolic/evaluation stages.

Load the 32.8 MB compiled cache once per persistent kernel by file path and
memoize the sealed handle.  Do not serialize the full assembly in every
parallel task closure.  The existing `TaskBroker` already uses this pattern
for rational strip records/preparations; the direct-channel route needs the
same artifact-path cache.

Prime scheduling must respect early reconstruction stop.  Run the minimum
required prime set concurrently, then keep at most one speculative next prime
in flight while reconstruction/unseen-prime validation executes.  This avoids
paying for a whole unnecessary prime window.

### P3: incremental CRT only after it becomes measurable

If physical reconstruction later becomes more than 5% of wall:

- update CRT accumulators incrementally with each new prime instead of
  recomputing `ChineseRemainder` from all prior artifacts at every lift;
- rational-reconstruct only coordinates whose accumulated image changed or
  whose prior reconstruction failed the height bound;
- preserve degree-profile and training-image checks;
- run the unseen-prime residual before the characteristic-zero exact gate.

At present this cannot compete with compiler/census/evaluation work for
payoff.

## Finite-field benchmark and adversarial stress matrix

Every performance result must include cold and warm scopes, source/input/ABI
hashes, exact output fingerprints, message streams, CPU/wall/RSS, cache-hit
state and backend/thread provenance.

| test | cases | required gate | performance metric |
|---|---|---|---|
| algebra differential | ranks 0,1,2,3; zero/sparse/dense channels; two odd primes in both mod-4 classes; two epsilon images | direct grade rows transformed to split signs exactly equal legacy rows/RHS at split points | compile/reduce/collapse/point seconds by rank |
| nonsplit oracle | every attainable Legendre-character pattern, including rank-3 nonsplit points | independent quotient-algebra or finite-extension evaluation equals direct grade equations; no reliance on the production implementation | acceptance rate and batch throughput |
| physical A0 common stream | p=10007, eps=1/21, same 21 split points | exact 672x624 matrix/RHS equality; certified 19/20/21 rank transition | cold/warm medians and MAD over >=7 runs |
| physical A0/AS/AL/ASL | primes 10007/10039, eps 1/21 and 1/11 | same coefficient/augmented ranks and witness fingerprints as certified legacy artifacts | one shared ASL assembly plus projection versus four independent builds |
| denominator/witness search | every missing factor separately, survivor products, anisotropic support edges | pure-superset containment; four nonzero witness screens before full rank; exact potential for every promoted one-form | candidate columns/s and rejected candidates without RREF |
| compiler V2 | synthetic rank 0--3, physical A0, rebound support/denominator/forms | exact channel and compiled-pool differential; source/root/order mutants rejected | cold compile, stage timers, peak RSS, artifact size |
| evaluator V2 | batches 1,4,21,34,128,256 points; repeated and random streams | exact equality with V1 for accepted/rejected points and typed failure reasons | points/s and rows/s at 1/2/4 workers |
| cache lifecycle | cold build/read, relocated copy, truncation, byte mutation, stale source, wrong prep/root order, concurrent readers | every mutation fails closed; atomic writes leave no stale success artifact | read/full-validation time and per-kernel RSS |
| native rank | consistent/inconsistent; nullity 0,1,4,12,40; gapped pivots; 672x624 through 896x864 | independent ranks of A and [A|b], all-row residuals and witnesses | 1/2/4 native threads; throughput with 8 one-thread images |
| interpolation/CRT | zero coordinates, degree changes, bad primes, coefficients just below/above reconstruction bound, 3/5/7 primes | exact training images, unseen-prime rejection, exact recovered vector | incremental versus full CRT wall and allocations |
| scheduler | 1,2,4,8 concurrent physical images; cache already resident | byte-identical outputs, no nested kernels, declared CPU ceiling, bounded RSS | throughput, p95 latency, CPU efficiency |
| rational-package regression | frozen CF254 (9,6), CF254 (9,7), malformed backend/plan cases | oracle-identical gauge/residues/alphabet and existing exact/numerical gates | preserve or improve 140.9/187 s baselines |
| family transfer | first captured recursive stops in CF303 then CF259 | fresh family/preparation/root-order bindings; no CF300 artifact reuse | compile amortization and image throughput by family |

Additional fail-closed cases:

- prime `>= 2^31`, composite/even prime, zero epsilon image;
- zero root square, zero gauge denominator, rational-channel pole;
- duplicate point modulo the prime and exhausted candidate stream;
- nonzero `BranchFlipMask` on a production grade sampler (remove it or reject
  it; it currently changes no direct equation);
- reordered roots, changed source index, changed square, changed ABI column
  order, changed one-form prefix or uncertified one-form potential;
- corrupted pool index, out-of-range pool reference, pool hash collision
  mutant, term-count overflow bound;
- cache reuse after source, binary, protocol, preparation, solver
  configuration or process generation changes;
- eight concurrent jobs under a byte-budgeted cache/RSS ceiling.

## Package integration boundary

Do not combine this performance work with a permissive backend fallback.
`finite_field_backend_hardening_2026-08-23_xh/` already stages exhaustive
backend selection, strict plan schemas and checkpoint solver-configuration
binding.  Integrate/rebase those correctness patches first or together, and
retain distinct options for fixed-core FLINT solve and affine-RREF plan
discovery.

A direct-channel result must not become package `Solved` merely because the
modular affine system is consistent.  Every installed one-form needs a
verified dlog potential, and the reconstructed gauge must pass the unseen-
prime, all-branch and characteristic-zero original-equation gates.

## Static audit artifacts

- `analyze_serialized_direct_cache.py`: non-evaluating balanced-association
  scanner; SHA-256
  `d801dbfdf626fcad38560e27904a328154fe84c5bab66bb5b7f25509c7da42de`.
- `cf300_a0_serialized_cache_census.json`: SHA-256
  `da8b2aa4bb392ba69e95111c68e784522d84dabb44d0d9ceab69cf3fb20d7c8b`.

The scanner reads serialized text only; it neither loads Wolfram code nor
modifies the cache.
