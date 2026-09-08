# CF300 exact-Q(eps) admission V2 post-run verifier

This verifier is read-only and Wolfram-independent.  It evaluates no Wolfram
Language, launches no kernel/native solver, invokes no subprocess, controls no
process, and writes no runtime artifact.  It structurally parses the literal
WL associations/lists emitted by the held parse, prerequisite capture, exact
certificate, admission receipt, and pool status.

In addition to the V1 certificate and source-chain checks, V2 requires:

- core V2 manifest SHA-256
  `7db4c3cc751764a07ad0a7134578ec59459bd0276b371c04a4d8ac03b1ee0c80`;
- V2 admission driver SHA-256
  `7e57344560dbf102b84f95640b32000455060c5d933d96f35c294e1f3c6c7630`;
- byte-exact transformed driver SHA-256
  `35c3c32e6db5c1b5bb0accd62b7516b43b264191b664f6377e4d8d0d87f31ac8`;
- held artifact/read records with V2 statuses, a true terminal-LF gate, and
  `PinnedASCIIBytesPreserveTerminalLF` mode;
- receipt fields for the same read mode, true frozen-driver terminal LF, and
  typed tag `CF300ExactQepsFrozenDriverExitV2`;
- the exact V1 characteristic-zero obstruction certificate and its frozen
  Q(eps), rank, modular-reconstruction, held-out-prime, cleared-denominator,
  source-hash, and no-plan-rediscovery evidence;
- final moved pool wrapper in `pool/done`, its invocation-time SHA-256 pin,
  exact six-argument linkage, helper ceiling zero, K24/no messages/result zero,
  clean log, no stale atomic temporary, and exact output path/hash/size links.

## Invocation-time wrapper pin

Immediately after the one authorized V2 heavy-mission submission, hash the
generated `.wl` wrapper in `queue`, `running`, or `done`.  Record that digest
before completion and pass it unchanged as `--expected-wrapper-sha256`.  Never
repin a wrapper after a mutation or a failed run.

## Verification command template

Run only after the V2 heavy mission has moved to `pool/done`:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_v2_xh/postrun_verifier_v2_xh/verify_cf300_exact_qeps_admission_postrun_v2_xh.py \
  --project-root /home/maxzhang/factorization-and-loops \
  --admission-driver /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_v2_xh/run_cf300_sector12_exact_qeps_admitted_v2_xh.wls \
  --v6d <SCRATCH>/cf300_s12_galois_orbit_forcing_xh_v6d.wl \
  --prerequisite <SCRATCH>/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl \
  --held-parse <SCRATCH>/cf300_exact_qeps_runtime_admission_held_parse_v2_xh_v1.wl \
  --certificate <SCRATCH>/cf300_s12_exact_qeps_left_obstruction_admitted_v2_xh_v1.wl \
  --receipt <SCRATCH>/cf300_s12_exact_qeps_runtime_admission_receipt_v2_xh_v1.wl \
  --mission-wrapper <POOL>/done/cf300_s12_exact_qeps_runtime_admitted_v2_xh_v1.wl \
  --mission-status <POOL>/done/cf300_s12_exact_qeps_runtime_admitted_v2_xh_v1.status \
  --mission-log <POOL>/logs/cf300_s12_exact_qeps_runtime_admitted_v2_xh_v1.log \
  --expected-wrapper-sha256 "$WRAPPER_SHA256"
```

Success prints one JSON object with status
`CF300ExactQepsAdmissionPostRunVerifiedV2XH`, K24, helper ceiling zero, no
nested kernels, and four native FLINT threads.  Any discrepancy prints a typed
V2 verification-failed JSON object and exits 1.

## No-kernel adversarial suite

```bash
python3 test_verify_cf300_exact_qeps_admission_postrun_v2_adversarial_xh.py
```

The frozen suite passes 34/34 tests, including positive synthetic evidence and
mutants for source/manifest/wrapper pins, wrapper arguments, K24/result/helper,
log failures, held read mode/terminal LF/context cleanup, typed exit tag,
transformed hash, prerequisite/certificate/receipt linkage, native thread
claims, size ceilings, and stale atomic outputs.
