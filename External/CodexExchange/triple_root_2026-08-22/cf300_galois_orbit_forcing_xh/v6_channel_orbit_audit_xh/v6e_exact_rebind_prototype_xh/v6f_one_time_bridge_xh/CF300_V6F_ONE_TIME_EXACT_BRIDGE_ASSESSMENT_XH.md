# CF300 V6f one-time exact bridge assessment (staged, no kernel)

## Frozen inputs inspected

- Live wrapper: `/tmp/codex-triple-root-20260823c.vx654S/pool/running/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl`, SHA-256 `04ed1f5df890acff7fbebfcb743b8e80d93f71bf69713189b833d450add70e56`.
- V6e helper: `DirectRootChannelExactOneFormRebindV6e.wl`, SHA-256 `2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8`.
- Runtime driver: `runtime_gate_xh/run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls`, SHA-256 `2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884`.
- Frozen V6 exact rebind: `../DirectRootChannelExactOneFormRebindV6.wl`, SHA-256 `2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44`.
- Orbit core V6d: `../GaloisChannelOrbitCoreV6d.wl`, SHA-256 `7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed`.
- Assembler: `../../../direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl`, SHA-256 `227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`.
- Completed V6e result: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl`, SHA-256 `4b7a03067c6db5f18d036e5a91565ff84061228e677f6e187fc25afe3bfc4adb`.
- Completed lift prerequisite: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl`, SHA-256 `3fab0f58e3c85cb84cd8f8b99e301039ac30f78a4261cff0b30c6e3aa9cc680a`.
- Final mission log: `/tmp/codex-triple-root-20260823c.vx654S/pool/logs/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.log`, SHA-256 `aeffb059600183dfec26edcfb01e6a8808295cb43456186da890abaca86e5441`.

## Static phase attribution

The printed V6e milestones expose only suffix composition, unique compilation,
the legacy whole-result validator, and seal construction.  The helper's
`AbsoluteTiming` also includes the following hidden phases:

1. `BaseValidation`: the assembler validator serializes exact forms, compiled
   forms, compiled shape, source payload, and semantic payload.
2. `TargetABIValidation`: `TRPreparationABIValidQ` rebuilds the canonical ABI
   payload and serializes it.
3. `CanonicalLeafGrouping` and `CanonicalLeafValidation`.
4. `DeterministicLegacyCompilerAudit` and `ExactCompiledJoins`.
5. `LegacyFingerprintConstruction`: serializes exact forms, compiled forms,
   compiled shape, and the semantic payload.
6. `SpecializedSealSelfValidation`: serializes the seal payload, exact suffix,
   canonical suffix, compiled suffix, base prefix, and column order again and
   performs full structural prefix/core comparisons.

The driver then invokes the specialized validator once explicitly and once
again through `DRCAConsumeExactOneFormRebindSealV6e`; it also fingerprints the
entire `{baseAssembly,maxPreparation,additionalRecords}` before and after every
trial and compares every semantic result to the oracle with whole-expression
`SameQ`.  The replay consume is cheap because the consumed-nonce test
short-circuits.

There is a second driver-wide residual after the rebind benchmark.  The four
maximal and four base image calls use public `DRCAAssembleSample`; that boundary
runs `DRCAAssemblyPreparationValidQ` on every call (assembler lines 833--846).
Consequently the staged bridge below fixes the repeated rebind/identity/seal
path but is not by itself a complete full-driver performance promotion.

The completed durable result makes the attribution exact.  Trial walls were
486.911427 s and 496.049937 s.  `TargetABIValidation` alone took 420.888848 s
and 428.830242 s (about 86.4% of each wall); it rebuilds/canonicalizes and
serializes the large maximal preparation ABI on every call.  The second cost
was `CanonicalLeafValidation` at 36.909202 s and 37.984327 s (about 7.6%).
`BaseValidation` was only 1.199755 s and 0.718389 s.  The remaining reported
trial-2 phases were suffix composition 0.191638 s, grouping 1.245753 s, unique
compilation 9.294693 s, compiler audit 0.343015 s, joins 0.000261 s, legacy
fingerprint construction 4.024118 s, whole-result validator 3.948618 s, seal
construction 4.373089 s, and seal self-validation 4.440966 s.

Both trials passed every correctness, identity, source, oracle, collision, and
fresh/replay seal gate.  The four images certified the frozen ranks, and the
lift prerequisite was written.  The mission intentionally ended `EXIT3` with
`CF300Sector12V6eCorrectButPerformanceAcceptanceNotMetXH`: median V6e time was
491.480682 s versus frozen V6d 485.843061 s (speedup factor 0.9885293131).

## V6f contract

The staged V6f helper does not try to derive the legacy SHA-256 of a complete
assembly from Merkle leaves; that is impossible without reproducing the exact
legacy byte stream, and accepting a Merkle root alone would weaken the
contract.  Instead:

1. The pinned driver executes the frozen V6 rebind once.  Frozen V6 constructs
   and validates the complete legacy assembly.
2. V6f receives that immediate result, validates all 72 source records exactly,
   compiles the 336 unique canonical leaves, performs the deterministic legacy
   compiler audit, and compares the 576 exact and compiled suffix leaves with
   the oracle by `SameQ`.
3. The accepted assembly is literally `KeyDrop[legacyResult,
   "ExactOneFormChannelRebindV6"]`; V6f never reconstructs it from hashes.
4. Each source record gets a deterministic leaf seal binding its orbit-core
   source root, target ABI, forcing index, exact one-form fingerprint, certified
   channel fingerprint, and provenance fingerprint.  The Merkle root is for
   compact integrity and lookup only.
5. The exact assembly is retained in a private same-kernel registry.  Repeated
   resolution checks the compact handle and current source file hashes only.
   It never serializes or revalidates the whole assembly.
6. Any new or changed record set requires a fresh exact bridge build.  A Merkle
   update or finite-field pass can never authorize an algebraic result.

For full-driver promotion, add a bridge-owned sampling entry point.  It must
resolve the private registry entry, recheck the compact handle and current
source hashes, and call a source-pinned assembler *private* validated-sample
implementation with the registry's assembly and stored fingerprint.  The
token must never be a public option usable with an arbitrary caller-supplied
assembly.  This follows the existing reconstruction convention:
`TRAssembleReconstructionSample` validates once, then calls its private
implementation under `$trValidatedABIFingerprint`; the assembler already uses
the analogous trusted fingerprint in `drcaAssemblePointInternal`.  Until that
refactor is staged, parsed, and adversarially tested, downstream code must keep
the slow public boundary and the full V6f driver remains blocked from
performance promotion.

This design is sound only in the source-pinned driver call sequence where the
legacy result is the immediate output of frozen V6.  The promoted driver must
hash-pin both helper and driver and must not accept a deserialized or externally
supplied `legacyResult` as an exact witness.

## Finite-field all-sign screen

An optional screen may evaluate every selected record under every Galois sign
at several already-certified primes and nonsingular points.  Any mismatch is a
valid early rejection/triage signal.  Passing is never acceptance: finite
sampling can miss a nonzero rational function, bad primes can erase content,
and excluded denominator loci matter.  A screen error or indeterminate point
must either continue to the exact bridge or fail closed.  No `TimeConstrained`,
`Timeout`, catch-and-accept, or skipped exact branch is allowed.

## Promotion and rollback

Promote only after held parse, static invariants, all adversarial mutations,
and a fresh isolated runtime gate pass.  Require exact oracle assembly
fingerprint `32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`,
72 record seals, 576 raw leaves, 336 unique leaves on CF300, exact suffix and
compiler audit gates, source stability, identical downstream four-image ranks
and lift prerequisite, and zero whole-assembly `InputForm` calls after bridge
creation.  Report cold oracle time and warm resolve time separately.
Also require a bridge-owned validated sample path; the current public
`DRCAAssembleSample[screenAssembly,...]` loop is an explicit promotion blocker.

Rollback on any source/hash drift, record/Merkle mismatch, oracle suffix
mismatch, replay after release, changed downstream fingerprints/ranks, a warm
path that calls either full validator, or any finite-field positive used as
acceptance.  Rollback is removal of the V6f driver/helper entries; frozen V6/V6e
sources and artifacts are untouched.
