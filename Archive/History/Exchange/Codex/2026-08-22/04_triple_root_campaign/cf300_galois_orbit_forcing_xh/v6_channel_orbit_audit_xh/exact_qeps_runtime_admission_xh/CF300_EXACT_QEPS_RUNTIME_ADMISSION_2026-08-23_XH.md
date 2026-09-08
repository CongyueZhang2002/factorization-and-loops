# CF300 exact-Q(eps) K24 runtime admission

Date: 2026-08-23

## Disposition

The frozen exact-Q(eps) bundle remains byte-for-byte unchanged. This adjacent admission layer is source-ready but has not been launched. No Wolfram kernel, native solver, pool mission, process-control command, or package edit was used in this audit.

At the final read-only observation, K24 was running `cf300_s12_v6e_correctness_same_input_benchmark_xh_v1`, and the V6e prerequisite capture did not yet exist. The held-parse, exact certificate, and admission-receipt paths below were all absent. Do not submit either new mission until the V6e mission finishes and K24 is the designated next worker.

## Admission contract

Both entry points reject before argument parsing or source I/O unless:

- `System`$KernelID === 24`;
- `KernelPoolMission`$TaskBrokerMaxHelpers === 0`; and
- `System`Kernels[] === {}`.

`System`$KernelCount` is recorded only as outer-pool telemetry. The runtime driver checks K24/helper/nested state again after the exact run. Neither admission source contains a Wolfram nested-kernel launch API.

The held-parse gate parses these five exact sources under `HoldComplete`: the admission driver, frozen driver, exact helper, modular reconstruction, and prerequisite schema. It requires full `SyntaxLength`, zero parser messages, no trimmed source line ending in a context backtick, exact before/after hashes, and exact cleanup of temporary and tracked namespaces. Its atomic output is limited to 16 MiB.

The runtime driver refuses to run without that exact passed held-parse artifact. The artifact must bind the current admission-driver hash, all four frozen-source hashes, K24, helper ceiling zero, nested count zero, five passing parse records, and the current held-parse gate hash.

The runtime driver executes a deterministic in-memory transformation of the frozen driver:

- exactly four `Exit[...]` requests become `Throw[...]`, preserving persistent K24;
- the frozen atomic writer receives a 1 GiB pre-write `ByteCount` ceiling; and
- the written certificate receives the same 1 GiB disk-size ceiling.

The original driver hash, exact transformation occurrence counts, transformed-text SHA256, and a second held parse of the transformed text are mandatory. A success receipt is limited to 16 MiB. A certified output is rolled back if any post-run admission check or the success-receipt write fails.

## Frozen hashes

- admission driver: `a4cc4466c9844e8d4d49206b4fd7498a923f306ea3765812af72fa35e635a6f9`
- held-parse gate: `005c9297aabb329de81ce52e00b321ea84ed1d2865d97c8c7cadf55672da461e`
- frozen exact driver: `446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174`
- exact helper: `e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b`
- modular reconstruction: `0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce`
- prerequisite schema: `909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45`
- frozen-bundle manifest: `642fb0b403c1c68e04e9943945e32b3b66b923265e50777c3fef3da85e451757`
- transformed driver text: `0b71743d40da509bef35cbadbae0df5f27263ce7ff6b283e9c481a91e89a8f66`
- `kpsubmit.sh`: `138315a11149c14fc3491a008e6e7ad4d23623d29a2228fbdea31d4384707ddc`
- frozen V6d artifact: `20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf`

## Exact held-parse command

First verify the adjacent admission bundle, confirm that the output and mission name are fresh, and coordinate the pool so K24 is the next designated worker:

```bash
cd /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh
sha256sum -c SHA256SUMS_CF300_EXACT_QEPS_RUNTIME_ADMISSION_XH_V1

test ! -e /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl
test ! -e /tmp/codex-triple-root-20260823c.vx654S/pool/done/held_parse_cf300_exact_qeps_runtime_admission_xh_v1.status
test ! -e /tmp/codex-triple-root-20260823c.vx654S/pool/failed/held_parse_cf300_exact_qeps_runtime_admission_xh_v1.status

POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  held_parse_cf300_exact_qeps_runtime_admission_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh/held_parse_cf300_exact_qeps_runtime_admission_xh.wls \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl
```

The held-parse argument vector is one fresh output path.

Watch with:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
/home/maxzhang/factorization-and-loops/Scripts/kpwait.sh \
  held_parse_cf300_exact_qeps_runtime_admission_xh_v1 600

grep -F 'CF300_EXACT_QEPS_HELD_PARSE PASS output=' \
  /tmp/codex-triple-root-20260823c.vx654S/pool/logs/held_parse_cf300_exact_qeps_runtime_admission_xh_v1.log
grep -F 'CF300ExactQepsRuntimeAdmissionHeldParsePassedXH' \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl
```

Acceptance requires a `done` status with `Status -> "OK"`, `HadMessages -> False`, `Kernel -> 24`, and `Result -> 0`, plus both markers above. Any `CF300_EXACT_QEPS_HELD_PARSE FAIL`, a `failed` status, a nonzero/failed result, or a missing/failed artifact is terminal for this source set.

## Exact runtime command

Run only after the held-parse acceptance and after V6e has atomically emitted the prerequisite capture:

```bash
cd /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh
sha256sum -c SHA256SUMS_CF300_EXACT_QEPS_RUNTIME_ADMISSION_XH_V1

test -f /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl
test -f /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl
test ! -e /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_left_obstruction_admitted_xh_v1.wl
test ! -e /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_runtime_admission_receipt_xh_v1.wl
test ! -e /tmp/codex-triple-root-20260823c.vx654S/pool/done/cf300_s12_exact_qeps_runtime_admitted_xh_v1.status
test ! -e /tmp/codex-triple-root-20260823c.vx654S/pool/failed/cf300_s12_exact_qeps_runtime_admitted_xh_v1.status

POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_exact_qeps_runtime_admitted_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh/run_cf300_sector12_exact_qeps_admitted_xh.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_left_obstruction_admitted_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_runtime_admission_receipt_xh_v1.wl
```

The ordered runtime arguments are:

1. project root;
2. frozen V6d artifact;
3. V6e exact-lift prerequisite capture;
4. passed central held-parse artifact;
5. fresh exact-certificate output; and
6. fresh admission receipt.

The frozen modular source uses four native FLINT threads. The mission helper ceiling remains zero; no Wolfram nested kernels are authorized.

Watch with:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
/home/maxzhang/factorization-and-loops/Scripts/kpwait.sh \
  cf300_s12_exact_qeps_runtime_admitted_xh_v1 604800

grep -F 'CF300_EXACT_QEPS_ADMISSION PASS output=' \
  /tmp/codex-triple-root-20260823c.vx654S/pool/logs/cf300_s12_exact_qeps_runtime_admitted_xh_v1.log
grep -F 'CF300Sector12ExactQepsLeftObstructionCertifiedV1' \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_left_obstruction_admitted_xh_v1.wl
grep -F 'CF300ExactQepsRuntimeAdmissionPassedXH' \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_runtime_admission_receipt_xh_v1.wl
```

Acceptance requires a `done` status with `Status -> "OK"`, `HadMessages -> False`, `Kernel -> 24`, and `Result -> 0`; the runtime PASS log marker; the exact certificate status; and the passed admission receipt. The receipt must also say `AdmissionPassed -> True`, `HeldParseEvidenceValid -> True`, `ImmutableSourcePinsStable -> True`, `PrerequisiteStable -> True`, `AdmissionStateStable -> True`, and `ContextBacktickSplitGuardPassed -> True`.

Failure markers are any `CF300_EXACT_QEPS_ADMISSION FAIL` log line, a pool `failed` status, a nonzero/failed result, a missing certificate or receipt, `CF300ExactQepsRuntimeAdmissionFailedXH`, or any certificate status other than `CF300Sector12ExactQepsLeftObstructionCertifiedV1`. Do not reinterpret a typed diagnostic as certification.

## No-kernel verification

- runtime-admission static suite: 82/82 passed;
- runtime-admission adversarial suite: 40/40 passed;
- original exact bundle: 111/111 static and 97/97 adversarial;
- original eight-entry manifest: all entries verified.

Central held parsing and runtime remain pending by design.
