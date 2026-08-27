# Direct preparation compile/cache audit

Scope: External-only source audit and staged tests. No Wolfram kernel was
launched, no package file was changed, and no running mission was touched.

## Conclusion

The current `PreparedDirectRootChannelsV1` association is structurally safe to
attempt as a serialized cache artifact. Its stored values are exact Wolfram
expressions, associations, lists, strings, symbols, integers/rationals, and
packed arrays. It contains no open stream, process handle, `LibraryFunction`,
compiled function, closure, or mutable package cache. Prime and epsilon caches
remain process-local globals and are intentionally not serialized.

This is not yet a runtime certification. The staged harness must pass an exact
`Put`/`Get` round trip, full `DRCAAssemblyPreparationValidQ`, an operational
epsilon collapse, corruption rejection, and source-mutation rejection in the
managed pool before a production consumer is allowed to reuse a cache.

The artifact is source-bound rather than portable. It binds the preparation
ABI and SHA, root order, assembler path and SHA, helper path and SHA, runtime
source closure, exact/compiled/shape fingerprints, and direct assembly
fingerprint. It is read under the same `Global`` context convention as the
physical preparation. Moving the checkout, changing a source file, changing
symbol contexts, or changing the artifact schema invalidates it. Cross-Wolfram
version reuse should not be claimed until explicitly tested.

"Immutable" here means fail-closed content validation at every read boundary,
not filesystem write protection. An in-memory association can be replaced, but
the stored fingerprints and full direct-assembly validator reject mutations.

## Why `DRCAPrepare` dominates

The observed physical run spent far longer than the prior approximately
83-second legacy sample assembly before producing a milestone. Static review
shows several multiplicative costs:

1. `DRCAPrepare` first runs full source-preparation ABI validation.
2. `DRCACompileSystem` independently calls field decompose, field compose, and
   an exact `Together` round trip for every scalar entry in `E`, `C`, `BBar`,
   and the one-forms, including repeated expressions.
3. Each returned channel is canonicalized with `Together` again before sparse
   polynomial compilation.
4. Rational primitive tensors with `roots == {}` still traverse the generic
   field decompose/compose path.
5. Both the exact channel tree and compiled channel tree are retained and
   serialized through several `ToString[InputForm]` SHA fingerprints.
6. The physical driver immediately calls `DRCAAssemblyPreparationValidQ`,
   which recomputes the exact, compiled, shape, semantic, and assembly
   fingerprints. `DRCAAssembleSample` validates the preparation again.

For a single image, this exact compilation and repeated validation can swamp
the fast point assembler. A validated compiled cache is therefore the first
safe performance intervention: it amortizes current exact work without
changing algebra.

## Safe compile-time reduction candidates

These should be prototyped externally and differentially certified before any
source-pinned assembler change:

1. Build an exact, collision-checked unique-scalar DAG across all tensors.
   Decompose, round-trip, and compile each exact unique scalar once, then map
   indices back to tensor positions.
2. Add a `roots == {}` rational fast path that compiles the single rational
   channel directly. This is exact by construction and avoids field
   decompose/compose overhead for root squares, logarithmic derivatives, and
   the gauge denominator.
3. Fuse canonicalization: retain the exact canonical rational obtained during
   the round-trip check and feed its numerator/denominator directly to sparse
   compilation instead of calling `Together` again.
4. Split immutable equation-core compilation (`E`, `C`, `BBar`, roots,
   denominator) from ansatz instantiation (support and one-forms). Gauge support
   changes do not change the compiled equation forms. Pure one-form supersets
   should reuse compiled base forms and compile only new forms.
5. Perform one full validation at compile or artifact reload, then use a
   private validated token for repeated prime/epsilon/sample calls. Public or
   deserialized inputs must still receive full validation.
6. In a version-2 representation, consider retaining exact round-trip and
   canonical digests instead of duplicating the entire exact channel tree,
   provided build-time exact verification and adversarial differentials remain
   mandatory.
7. Benchmark direct expression `Hash` against string-based fingerprints before
   changing stable provenance. A faster runtime structural hash may supplement,
   but must not silently replace, the stable cross-artifact SHA.
8. Only after deduplication, consider bounded parallel compilation of unique
   scalars. Eliminating duplicate symbolic work is lower risk and likely higher
   leverage than parallelizing the current repeated work.

## Staged cache protocol

`DirectRootChannelCompiledArtifact.wl` defines a strict version-1 wrapper,
source-bound cache key, atomic non-overwriting write, exact readback, and full
read validation. The CF300 A0 builder compiles once and writes this artifact.
The validator performs:

- exact serialized round trip;
- full direct preparation validation after reload;
- operational prime/epsilon collapse;
- stored-fingerprint corruption rejection;
- compiled-payload corruption rejection;
- cache-key corruption rejection;
- validation of an identical temporary source relocation;
- rejection after mutating only that temporary copy;
- rejection of a bounded 4096-byte truncated artifact; and
- cleanup and final source/hash stability checks.

The source-mutation test never opens or writes the actual assembler source.

The staged builder currently targets the physical CF300 sector-12 A0
preparation. It does not yet eliminate the discriminator's ASL compilation,
because ASL is constructed dynamically after the factor census. After the
cache protocol passes, the next External-only step is to cache the constructed
ASL `PreparedReconstruction` and let the direct discriminator accept that cache
as an explicit optional input. No implicit fallback or unvalidated cache lookup
should be added.
