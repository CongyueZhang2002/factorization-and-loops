# Independent adversarial audit: DirectRootChannelCompilerV2

Date: 2026-08-23  
Scope: External-only V2 prototype and its two staged managed-pool drivers  
Method: static review plus independent Python exact arithmetic; no Wolfram or
Mathematica kernel was launched, and no process was signalled or stopped.

## Decision

The recursive multiquadratic algebra, bit-mask ordering, collision-checked
pooling, core/ansatz split, prefix rebind, and managed-pool resource behavior
have no audit-level algebra or resource blocker. It is **safe to schedule the
synthetic and CF300 physical drivers as managed diagnostic tests now**. They
use one mission kernel, acquire no nested kernels, and contain no process-control
call.

This is not a production-promotion verdict. One public-API compatibility defect
and two test/provenance contract gaps must be fixed before package integration
or a serialized V2 cache is accepted.

## Verified

1. **Recursive inversion is exact in the package basis.** The implementation
   splits the coefficient vector into the low/high halves for the last (highest
   bit) root and applies
   `inverse(u + v r) = (u - v r) inverse(u^2 - delta v^2)`. This agrees with
   `TRMultiply`/`TRFromPolynomial`, where root index `k` occupies bit `k-1`.
   Every recursion level checks the full product against the unit vector and
   every decomposition checks field recomposition.

2. **Independent non-Wolfram differential.** The audit model compared the
   recursive formula with independent dense Gaussian elimination over exact
   `Fraction` arithmetic for 1,000 deterministic rank-0 through rank-3 cases:
   978 invertible and 22 singular. It also checked explicit norm-zero divisors
   at ranks 1, 2, and 3. All comparisons passed.

3. **Sparse polynomial ABI matches V1 construction.** V2 channels are put
   through `Together`; their numerator and denominator are expanded once, then
   compiled with the same x/y/epsilon term grouping and epsilon-degree cap as
   V1. Each newly pooled polynomial is reconstructed from the sparse ABI and
   compared structurally with the expanded source polynomial.

4. **Hash collisions cannot alias pool values.** SHA-256 is only a bucket key.
   Both scalar and polynomial pools require `SameQ` before a hit. Rebind seeds
   are revalidated at public boundaries. The pools retain exact expressions and
   sparse associations only—no compiled function, stream, process, or
   kernel-local handle.

5. **Rebind semantics are fail-closed.** Support/normalization-only rebind
   reuses the exact and compiled one-form trees. A form rebind requires the old
   list to be an exact prefix and compiles only the suffix. A non-prefix change
   returns a typed failure.

6. **Managed-pool contract is clean.** Neither compiler nor drivers call
   `LaunchKernels`, `CloseKernels`, a `Parallel*` primitive, process launch, or
   process signalling. Both drivers require a fresh output, hash inputs before
   loading, rehash at completion, capture messages, and publish atomically.

The supplied static suites pass unchanged. The independent static and exact
arithmetic suites also pass; see `TEST_RESULTS.txt`.

## Required fixes

### P1 — default SourceABIFingerprint is not V1-compatible

`DRCACompileSystem` without explicit metadata fingerprints
`{record, roots, oneForms, gaugeDenominator, support, normalizations}`.
`DRCAV2CompileCore` instead fingerprints only
`{record, roots, Together[gaugeDenominator]}` and the V1 adapter copies that
core fingerprint. Therefore a direct no-metadata V2 call cannot be exactly
equal to the corresponding V1 call, despite the compatibility claim. The
staged tests do not expose this because they always supply explicit metadata.

The default root-order fallback also differs subtly: V1 hashes the stored
`RootSquare` list, while V2 hashes its `Together`-canonicalized list.

Required resolution before integration:

- distinguish an explicit source fingerprint from the core's internal source
  identity;
- when building the V1 compatibility view without explicit metadata, compute
  exactly the V1 default payload at ansatz finalization;
- reproduce V1's default root-order payload exactly, or require explicit
  metadata and remove the misleading optional default from the public API;
- add a rank-0 through rank-3 differential with `metadata` omitted.

This defect does not invalidate the staged CF300 driver because it uses the
validated preparation fingerprint explicitly.

### P1 — “exact association equality” gates are partial

Both drivers compare `KeyTake` projections. They omit `Record`, `Roots`,
`PrototypeSourceFile`, and `PrototypeSourceSHA256`, although their documentation
says exact V1 association equality. The current constructor appears to populate
those fields correctly, but the gate should enforce the stated contract.

Required resolution: make `SameQ[v1View, legacyAssembly]` the promotion gate.
The projected comparison may remain as diagnostic detail. This is a cheap
driver-only correction and is recommended before spending a managed physical
slot, though the existing projected gate still exercises all numerical forms,
orders, counts, and the legacy assembly fingerprint.

### P2 — detached V1 view is not itself V2-source-bound

The containing `PreparedDirectRootChannelsV2` object is bound to both compiler
sources. Once `DRCAV2ToV1Assembly` returns the compatibility association, that
standalone V1 view contains and fingerprints only the V1 assembler source.
Thus the assessment's statement that the *view* is bound to both source hashes
is too strong.

Required resolution before serialized caching: either document that V2
provenance exists only in the containing V2 envelope and cache that envelope,
or return a separate provenance-bearing wrapper/token. Do not change the
legacy V1 assembly fingerprint merely to add V2 provenance.

### P2 — serialized-artifact validation remains a promotion gate

In-memory construction binds exact/compiled trees through their fingerprints
and the V1 validator. The core validator does not independently rederive every
compiled core channel from the corresponding exact channel; its polynomial
pool is validated separately. This is acceptable for the present in-memory
prototype and physical differential, but corruption/relocation tests are still
required before a persisted V2 core or assembly becomes trusted input.

## Performance add-ons

These are not correctness blockers, but they are the next measurements worth
making if the physical benchmark is slower than expected.

1. The advertised root-free path is selected by the bundle's declared root
   list, not by each scalar's actual root usage. Rational E/C/BBar entries in a
   rank-2 or rank-3 block still pay branch replacement, polynomial reduction,
   and recursive inversion. Detect a scalar that contains no replacement-root
   symbols and emit `{rational, 0, ...}` directly, with the same round trip.

2. Scalar and polynomial pools grow `Values`/`Compiled` with repeated `Append`,
   and decomposition grows with `AppendTo`. If unique counts become large, use
   a two-pass census with preallocated tables or indexed associations. Preserve
   collision-bucket `SameQ` checks.

3. Full polynomial-pool reconstruction runs at every public validation and
   rebind boundary. If telemetry shows validation dominating, introduce an
   immutable, source-bound validation token for an unchanged pool. Do not drop
   the initial exact reconstruction check.

## Scheduling guidance

Run the existing synthetic managed driver first, followed by the CF300 physical
driver. A pass is diagnostic evidence only. Promotion additionally requires:

- the no-metadata compatibility fix and test;
- full `SameQ` V1 association gates;
- empty captured messages and stable hashes;
- exact physical V1 equality and point differential;
- material compile-time improvement;
- serialized corruption/source-relocation tests;
- unchanged V1 adversarial oracle results.

