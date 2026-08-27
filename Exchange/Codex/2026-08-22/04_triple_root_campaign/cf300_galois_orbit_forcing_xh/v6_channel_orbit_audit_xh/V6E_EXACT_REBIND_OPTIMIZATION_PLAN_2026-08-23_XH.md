# V6e exact-channel rebind optimization plan

Date: 2026-08-23

Scope: read-only, no-kernel audit of the V6d-pinned exact rebind and assembler.
No V6d source, helper, process, pool state, or output was modified.

Pinned sources audited:

- `DirectRootChannelExactOneFormRebindV6.wl`
  SHA256 `2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44`
- `DirectRootChannelAssembler.wl`
  SHA256 `227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`
- V6d driver
  SHA256 `921422ec0f78c8a56a707fb487115d0b0a5debe6b84e5257e0d3df638e43988d`

## Exact V6d workload

The V6d orbit milestone reported 72 appended one-forms.  Rank two gives four
field channels and every one-form has two differential components.  Therefore
the current rebind performs the following fixed work before `target_ready`:

| Operation | Formula | Exact count |
|---|---:|---:|
| `TRFieldCompose` on appended components | 72 x 2 | 144 |
| `Together` zero tests after composition | 72 x 2 | 144 |
| `drcaCompileRational` leaf calls | 72 x 2 x 4 | 576 |

Every rational compiler call performs `Together`, radical rejection, numerator
and denominator extraction, and two polynomial compiles.  Each polynomial
compile performs `Expand`, `PolynomialQ`, `CoefficientRules`, grouping, and
coefficient-row construction.  No leaf memoization exists.

The pipeline also repeats large exact validations and fingerprints:

1. The driver builds the target ABI payload, validates it by rebuilding that
   payload, then the rebind validates it again.  Each payload build
   canonicalizes 108 x 2 = 216 one-form components in addition to the equation
   record and roots.
2. `DRCAAssemblyPreparationValidQ` is called once on the base at rebind entry,
   once on the result inside the helper, and immediately once more on the same
   result in the driver.
3. Every generic assembly validation recomputes the exact-forms,
   compiled-forms, compiled-shape, source-semantic, and assembly fingerprints.
   These use `ToString[InputForm[...]]`; the cached artifact is about 32 MB and
   the unchanged equation core dominates the traversal.
4. Result construction separately computes exact-forms, compiled-forms,
   compiled-shape, and assembly fingerprints before the two result validators.
5. Later, four target and four base `DRCAAssembleSample` calls each run another
   generic assembly validation.  The sample path also re-hashes collapsed form
   shapes and full collapsed forms.

The rebind interval therefore contains 576 rational normalizations/compiles and
at least three generic assembly validations around a result for which only the
one-form suffix changed.  Exact phase timings are not presently exposed, so the
relative share of compilation versus serialization cannot yet be asserted.

## Ranked minimal V6e prototype

### 1. Phase timings and counters

Add independent `AbsoluteTiming` fields for:

- base validation
- target ABI validation
- suffix composition/equality
- canonical leaf grouping
- unique leaf compilation
- exact/compiled joins
- legacy fingerprint construction
- specialized validation seal construction
- one legacy whole-result oracle validation

Record raw leaf count, unique canonical leaf count, compile count, cache reuse
count, collision-group count, serialized expression byte counts when cheaply
available, and peak memory before/after each phase.  Emit a pre-rebind and
post-phase milestone so silence can be localized.

### 2. Collision-checked compiled-leaf memoization

The orbit core already carries canonical exact rational channel pairs for every
deduplicated forcing letter.  Extend the V6e payload so the 72 appended records
carry, per component and grade, both the exact channel and canonical expanded
`{numerator, denominator}` pair used by its channel fingerprint.

Compile each distinct canonical pair once:

1. key by SHA256 of the canonical pair;
2. group by the key;
3. require exact `SameQ` equality inside every group, failing closed on a hash
   collision;
4. validate that numerator and denominator are polynomials in `x,y,eps` with
   exact integer/rational coefficients and a nonzero denominator;
5. call a source-pinned canonical rational compiler that skips `Together` and
   compiles the already-expanded pair;
6. map the compiled leaf back to all 576 positions without reordering.

Required conservation:

```text
raw leaf count = unique compiled leaf count + compile-cache reuse count
```

The compiled suffix must retain dimensions `{72,2,4}`, and every output leaf
must carry the exact rational ABI type.  A deterministic audit subset must be
recompiled with the legacy `drcaCompileRational` and compared by `SameQ`.

### 3. One specialized validation seal, one legacy oracle

The helper should validate the base and target once, construct the result under
a specialized one-form-suffix contract, and return an opaque seal binding:

- base assembly fingerprint and pinned assembler source hash
- target ABI fingerprint
- immutable equation-core fingerprints
- base one-form count and exact prefix
- appended channel/canonical/compiled fingerprints in order
- gauge/residue/unknown counts and column order
- exact and compiled suffix dimensions
- source hashes before and after rebind

The specialized validator must prove that all non-one-form fields are exactly
unchanged, the target prefix is exact, the suffix order is exact, and count and
column-layout equations hold.  The driver consumes this seal instead of calling
the generic result validator a second time.

For the first V6e prototype, retain one legacy whole-result
`DRCAAssemblyPreparationValidQ` call as an independent oracle.  Its result and
the specialized seal must both be true.  Retain the legacy whole exact,
compiled, shape, and assembly fingerprint fields for downstream compatibility,
but compute/store each only once.

### 4. Upstream lineage seal for the 144 composition checks

After the timed prototype establishes the share of the composition phase,
replace algebraic recomposition with a lineaged exact-channel suffix seal.  The
orbit builder itself creates each appended form by composing the exact channels
once.  It should return the composed form, canonical channels, channel
fingerprint, and ordered provenance in the same record.  Rebind then requires:

- target suffix `SameQ` to those exact composed objects;
- appended channels `SameQ` to the sealed channels;
- per-index canonical fingerprints and order exact;
- target ABI and source/helper hashes bound to the seal.

No hardcoded `True` may stand in for this lineage.  Until this seal exists, keep
the 144 legacy composition/equality checks.

### 5. Validated sampling path

After one full generic validation and a specialized seal, pass an opaque,
source-pinned validation token to the internal already-validated sample path.
This removes eight later whole-assembly validations without weakening source
stability checks.  The token must be private, nonce-bound to the exact assembly
and validator source hash, and rejected after any fingerprint/source change.

### 6. Component/Merkle fingerprint ABI

Longer term, replace repeated whole-association `InputForm` serialization with
component fingerprints for immutable equation core, base one-forms, appended
suffix, compiled suffix, shapes, and layout metadata.  Derive an assembly V2
fingerprint from those component hashes.  Preserve the old whole fingerprints
during a cross-check transition; do not silently change the existing cache ABI.

## Non-negotiable correctness gates

1. All V6d exact character, finite-field jet, stabilizer, rebind, occurrence
   versus unique-source, and subset-certificate tests remain green.
2. Actual Wolfram held-parse gates pass for every new core/helper/driver before
   launch.
3. Base and target source files and hashes are checked before and after the
   operation.
4. Fingerprint collision mutants fail by exact `SameQ` group comparison.
5. Channel mutation, channel reordering, component swap, grade swap, numerator
   mutation, denominator mutation, zero denominator, and stale compiled-cache
   mutants all fail closed.
6. Equation-core mutation, base-prefix mutation, target ABI mutation, count or
   column-layout mutation, stale seal, wrong validator source hash, and reused
   nonce mutants all fail closed.
7. Raw/unique/cache counts conserve exactly; no successful result contains an
   unresolved symbol or non-Boolean certificate field.
8. The specialized validator and the one retained legacy whole-result oracle
   agree exactly on both valid and adversarial fixtures.
9. A fresh output path and atomic `OverwriteTarget -> False` remain mandatory.
10. No package merge occurs until a successful CF300 run and independent seal
    demonstrate identical exact forms, compiled forms, assembly fingerprints,
    matrix prefixes, and final rank/certificate results.

## Expected payoff

The minimal prototype can reduce 576 compiler invocations to the number of
unique canonical rational leaves, eliminate duplicate target/result validation,
and localize the remaining cost.  The later lineage and validated-sampling
steps remove 144 algebraic equality reductions and eight repeated whole-
assembly validations.  Exact gains must be reported from phase timers; no
speedup should be claimed from static counts alone.
