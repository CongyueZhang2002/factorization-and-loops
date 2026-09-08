# CF300 V6e full-mission post-run verifier

This directory is deliberately outside the frozen runtime-gate manifest.  The
verifier is read-only and Mathematica-independent: it never starts a Wolfram
kernel, executes artifact expressions, invokes a subprocess, or signals a
process.  It parses only literal `Association` and `List` structure from the
two `Put` artifacts and the KernelPool status.

It is pinned to runtime driver SHA-256
`2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884`.
It also pins the final moved KernelPool mission wrapper at SHA-256
`04ed1f5df890acff7fbebfcb743b8e80d93f71bf69713189b833d450add70e56`.
It recomputes the 15 live source hashes, preparation/cache/V6d input hashes,
runtime manifest entries, driver and mission-wrapper hashes, prerequisite hash,
pool status/log hashes, and final artifact hashes.  It then verifies:

- dispatch on K24, helper ceiling zero, eight outer workers and no nested kernels;
- the final wrapper is beside the `pool/done` status, and that status names it;
- exactly one literal `$ScriptCommandLine` assignment containing the pinned
  target followed by the seven ordered arguments: project root, preparation,
  cache, V6d, benchmark output, prerequisite output, and native thread count
  `"4"`;
- exactly one literal zero helper-ceiling binding, plus exact target linkage in
  the wrapper's `Import`, `Get`, and target-directory `SetDirectory` calls;
- successful pool status with `HadMessages -> False` and a clean K24 log;
- two exact V6e/V6 semantic-identity gates and identical frozen fingerprints;
- two valid, independently consumed seals with distinct UUID nonces and seal fingerprints;
- the two-trial timing inventory, exact median, frozen V6d baseline and accepted speedup;
- all four I00/I01/I10/I11 `888/889/nullity 24` certificates, exact frozen
  fingerprints, canonical pivot/free/independent-row arrays, and cross-image
  plan equality;
- atomic prerequisite linkage, actual SHA-256/byte count, no stale temporary,
  and the 1 GiB output ceiling;
- exact-lift consumer-validation metadata, anchor residues/rational lifts,
  stable-plan linkage, revalidation metadata and fail-closed capture policy;
- two distinct regular output files and their final size/hash inventory.

The no-kernel verifier cannot recompute Mathematica's `SameQ` over the captured
algebraic assembly or its `Hash[InputForm[...]]`.  It instead verifies the
frozen driver that performed those operations, both independently emitted
`SameQ` gates, all redundant fingerprints, the full plan arrays, and every
source/input hash.  Any missing or contradictory certificate fails closed.

Run after the central mission reaches `pool/done`:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/runtime_gate_xh/postrun_verifier_xh/verify_cf300_v6e_full_mission_xh.py \
  --driver /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/runtime_gate_xh/run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls \
  --output /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl \
  --prerequisite /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl \
  --preparation /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  --cache /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  --v6d /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl \
  --mission-wrapper /tmp/codex-triple-root-20260823c.vx654S/pool/done/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl \
  --mission-status /tmp/codex-triple-root-20260823c.vx654S/pool/done/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.status \
  --mission-log /tmp/codex-triple-root-20260823c.vx654S/pool/logs/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.log \
  --manifest /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/runtime_gate_xh/SHA256SUMS_RUNTIME_GATE_XH
```

Success prints one JSON report with status
`CF300V6eFullMissionPostRunVerifiedXH`; any discrepancy prints one fail-closed
JSON error and exits 1.

Adversarial suite:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/runtime_gate_xh/postrun_verifier_xh/test_verify_cf300_v6e_full_mission_adversarial_xh.py
```
