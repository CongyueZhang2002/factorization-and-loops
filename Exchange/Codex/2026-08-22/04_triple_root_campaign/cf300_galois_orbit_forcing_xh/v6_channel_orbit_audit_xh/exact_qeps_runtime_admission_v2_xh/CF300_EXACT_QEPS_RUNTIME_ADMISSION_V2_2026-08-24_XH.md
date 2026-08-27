# CF300 exact-Q(eps) runtime admission V2

Date: 2026-08-24

## Disposition

V2 is an adjacent, no-package-change repair of the failed V1 admission pin.
The frozen exact-Q(eps) bundle and all V1 admission evidence remain unchanged.
No kernel or native job was launched while preparing V2.

V2 is ready for a centrally managed campaign only after the operator confirms
that the intended K24 worker is clean and is the sole dispatchable worker.  The
pool dispatcher has no hard-target option, so K24 targeting remains an
external scheduling invariant; a driver's K24 guard is fail-closed, not a
dispatch mechanism.

## Exact V1 failure diagnosis

The frozen driver is ASCII, has SHA-256
`446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174`,
and ends in one LF.  V1's Python preparation retained that LF and pinned the
transformed text as `0b71743d...`.  The live Wolfram text-import plus
split/riffle path canonicalized the terminal LF away.  The observed live hash
`4b5766a39e87484c9ac0a91a4f8a825eae25969efc3f2440c808c663739426de`
is exactly the V1 transformed byte sequence with its final LF deleted.

This happened before the frozen exact driver ran.  It is not evidence against
the exact-Q(eps) obstruction, finite-field reconstruction, or the physics.

## V2 correction

- Read every held-parsed source as pinned ASCII bytes with `BinaryReadList`.
- Require the terminal LF and reject non-ASCII input.
- Remove only the shebang through its first LF with `StringPosition` and
  `StringDrop`, preserving every later byte including the terminal LF.
- Replace the four exact, individually counted `Exit[...]` spellings with
  `Throw[..., "CF300ExactQepsFrozenDriverExitV2"]`.
- Catch only that tag.  An unrelated or untagged `Throw` cannot impersonate a
  frozen-driver exit code.
- Preserve the 1 GiB certificate memory/disk ceilings, 16 MiB held/receipt
  ceilings, atomic non-overwrite outputs, source stability, namespace cleanup,
  K24/helper-zero/nested-zero gates, and certificate rollback policy.

The exact byte-preserving, typed transform is 17,043 ASCII bytes and has
SHA-256 `35c3c32e6db5c1b5bb0accd62b7516b43b264191b664f6377e4d8d0d87f31ac8`.

## Frozen V2 entry hashes

- runtime admission driver:
  `7e57344560dbf102b84f95640b32000455060c5d933d96f35c294e1f3c6c7630`
- held-parse driver:
  `0c5014ede7bcef827e58ec297022855ece5852d4bd9efa39a7fb871679636922`
- static suite:
  `eedddf90e57ab1a4631029c262fa2f4cccab1c9eb126301901a7befe79d2134c`
- adversarial suite:
  `16ca0b681143292f6723b4af6d047a9c28a68b935f4b1c27c6c502add2d80ed5`

The SHA256SUMS file in this directory is authoritative after final freezing.

## Managed campaign protocol

Use fresh V2 mission/output names.  Never reuse the stale V1 certificate,
receipt, held-parse artifact, mission name, or moved wrapper.  Verify the V2
manifest and both no-kernel suites before submission.

Phase A is the mandatory central held parse, with exactly one argument: a fresh
V2 held-parse artifact path.  Acceptance requires its V2 passed status, K24,
helper ceiling zero, no nested kernels, five byte-exact passing records, the
V2 driver hash, and the current held-gate hash.

Phase B is the single heavy managed campaign mission.  Its six ordered
arguments are the project root, frozen V6d artifact, exact-lift prerequisite,
passed V2 held-parse artifact, fresh V2 certificate, and fresh V2 receipt.  The
frozen modular helper uses four native FLINT threads but no Wolfram helper.

Suggested fresh names under the active campaign scratch are:

- `held_parse_cf300_exact_qeps_runtime_admission_v2_xh_v1`
- `cf300_s12_exact_qeps_runtime_admitted_v2_xh_v1`
- `cf300_exact_qeps_runtime_admission_held_parse_v2_xh_v1.wl`
- `cf300_s12_exact_qeps_left_obstruction_admitted_v2_xh_v1.wl`
- `cf300_s12_exact_qeps_runtime_admission_receipt_v2_xh_v1.wl`

The operator must first prove all names and output paths fresh, preserve an
invocation-time SHA-256 of the generated pool wrapper, and refuse submission
unless K24 is the intended sole dispatch target.  Do not kill, restart, or
clean K24/K146 merely to make this condition true.  If the pool has stale V1
metadata, reconcile it through the pool owner's safe lifecycle procedure
before dispatch; V2 must not be placed behind an ambiguous worker claim.

After Phase B reaches `pool/done`, use the adjacent no-Wolfram post-run
verifier with the invocation-time wrapper pin.  A failed status, any admission
FAIL marker, any message, any hash/path mismatch, any typed diagnostic instead
of the exact certificate, or any missing receipt/certificate is terminal.

## No-kernel evidence

- static: 85/85 passed;
- adversarial: 52/52 passed.

These suites include terminal-LF deletion, non-ASCII input, all four typed-exit
spellings, broad untyped-transform regression, untyped Catch regression,
wrapper pin mutation, context-backtick split, stale outputs, output ceilings,
held evidence drift, source drift, helper/nested/wrong-kernel rejection, and
atomic rollback policy.
