# CF300 exact-Q(eps) admission post-run verifier

This adjacent verifier is read-only and Mathematica-independent. It does not
evaluate Wolfram Language, launch a kernel or native solver, invoke a
subprocess, signal a process, or modify any runtime artifact. It structurally
parses only literal `Association` and `List` output and hashes every pinned
source and artifact.

The verifier checks:

- the final moved KernelPool wrapper beside its `pool/done` status, an explicit
  invocation-time wrapper SHA-256 pin, exactly one literal
  `$ScriptCommandLine` assignment, the exact target plus six ordered arguments,
  helper ceiling zero, and exact target `Import`/`Get`/`SetDirectory` linkage;
- pool status `OK`, `HadMessages -> False`, K24, result zero, the matching
  wrapper name, a clean log, and the exact admission PASS certificate/receipt
  marker;
- all frozen exact/admission source hashes and both frozen manifests;
- the source-chain native FLINT thread literal `4` in both the exact driver and
  modular backend, plus `NativeThreads -> 4` in both reconstruction certificate
  layers;
- the held-parse success artifact, five exact source/path/hash records,
  K24/helper-zero/nested-zero evidence, parser/context cleanup, gate linkage,
  and its 16 MiB ceiling;
- exact prerequisite status, V6d path/SHA linkage, point-lift and stable-plan
  schema, revalidation/capture gates, and its 1 GiB ceiling;
- exact certificate top and nested success statuses, Q(eps), source and input
  hashes, no plan discovery, modular held-out/solve-count evidence, exact sample
  shape, and cleared-denominator left/right identity gates;
- passed admission-receipt status, K24/helper-zero/nested-zero, held/prerequisite
  linkage, source stability, transformed held parse, output SHA/size, ceiling
  policy, and no rollback;
- distinct artifacts, their actual 1 GiB/16 MiB ceilings, and no stale atomic
  `.tmp-*` files.

Any failed or typed diagnostic top-level/nested status fails closed. The
verifier does not claim to re-run the characteristic-zero algebra; it validates
the exact certificate and the frozen code/hashes that produced and checked it.

## Two-phase wrapper pin

The KernelPool wrapper does not exist before submission, so its expected hash
cannot be embedded in this frozen verifier. Freeze it immediately after the
single authorized submission:

1. Submit the mission once with the command documented in the parent admission
   report. Do not resubmit under the same name.
2. As soon as the wrapper appears in `queue`, `running`, or `done`, hash that
   exact `.wl` wrapper—not the `.kernel` claim file—and record the lowercase
   digest in the run log/exchange record:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
MISSION=cf300_s12_exact_qeps_runtime_admitted_xh_v1

for state in queue running done; do
  candidate="$POOL/$state/$MISSION.wl"
  if test -f "$candidate"; then
    WRAPPER_SHA256=$(sha256sum "$candidate" | awk '{print $1}')
    WRAPPER_PIN_SOURCE="$candidate"
    break
  fi
done
test -n "${WRAPPER_SHA256:-}"
test "${#WRAPPER_SHA256}" -eq 64
printf 'wrapper_sha256=%s source=%s\n' "$WRAPPER_SHA256" "$WRAPPER_PIN_SOURCE"
```

3. After completion, require that the identically hashed wrapper has moved to
   `pool/done`, then pass the frozen digest explicitly as
   `--expected-wrapper-sha256`. A different digest is terminal; never repin a
   post-completion mutation.

## Post-run command

Run only after the admission mission is in `pool/done` and all four output
artifacts exist:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh/postrun_verifier_xh/verify_cf300_exact_qeps_admission_postrun_xh.py \
  --project-root /home/maxzhang/factorization-and-loops \
  --admission-driver /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh/run_cf300_sector12_exact_qeps_admitted_xh.wls \
  --v6d /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl \
  --prerequisite /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl \
  --held-parse /tmp/codex-triple-root-20260823c.vx654S/cf300_exact_qeps_runtime_admission_held_parse_xh_v1.wl \
  --certificate /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_left_obstruction_admitted_xh_v1.wl \
  --receipt /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_exact_qeps_runtime_admission_receipt_xh_v1.wl \
  --mission-wrapper /tmp/codex-triple-root-20260823c.vx654S/pool/done/cf300_s12_exact_qeps_runtime_admitted_xh_v1.wl \
  --mission-status /tmp/codex-triple-root-20260823c.vx654S/pool/done/cf300_s12_exact_qeps_runtime_admitted_xh_v1.status \
  --mission-log /tmp/codex-triple-root-20260823c.vx654S/pool/logs/cf300_s12_exact_qeps_runtime_admitted_xh_v1.log \
  --expected-wrapper-sha256 "$WRAPPER_SHA256"
```

Success prints one JSON object with status
`CF300ExactQepsAdmissionPostRunVerifiedXH`, `kernel: 24`,
`helper_ceiling: 0`, `nested_kernels: 0`, and
`native_flint_threads: 4`. Any discrepancy prints a typed failed JSON object
and exits 1.

No-kernel adversarial suite:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/exact_qeps_runtime_admission_xh/postrun_verifier_xh/test_verify_cf300_exact_qeps_admission_postrun_adversarial_xh.py
```
