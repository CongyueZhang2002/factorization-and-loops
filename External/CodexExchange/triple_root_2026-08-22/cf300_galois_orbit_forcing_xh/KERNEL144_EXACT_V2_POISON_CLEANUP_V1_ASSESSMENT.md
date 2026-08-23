# Kernel 144 exact V2 poison cleanup V1

Status: **NON-LAUNCHABLE / superseded.** It was never launched. Wolfram's
`Locked` attribute is irreversible for the lifetime of a kernel; neither
`Unlock` nor any exact-definition restoration design can make the three
poisoned symbols safely reusable. Kernel 144 must remain quarantined until the
managed pool is restarted after live missions drain. The driver is retained
only as audit history and must not be submitted.

The gate is pinned to the exact state printed by the independent read-only
mission `cf300_cgar_global_state_readonly_xh_v1` and to the source fixture in
`run_hydration_context_poison_model_v2.wls`. It compares all eight state
components for each of `Global`x`, `Global`y`, and `Global`eps` by exact
`SameQ`, and independently compares whole-state SHA-256 fingerprints to the
three observed values. The literal expected states must themselves reproduce
those pinned fingerprints before mutation becomes reachable.

On a mismatch it exits with status 2 without calling any mutating helper. On a
complete match it unlocks and unprotects only those three symbols, clears them,
and requires their `OwnValues`, `DownValues`, `UpValues`, `SubValues`,
`NValues`, `DefaultValues`, `FormatValues`, and `Attributes` all to be exactly
empty. A throw, abort, or failed postcondition invokes explicit restoration of
the exact preflight snapshot and verifies exact rollback. There is no
`InheritedBlock`, artifact hydration, file write, process control, or parallel
kernel call.

Static audit: 65/65 PASS. No-kernel Wolfram parse guard: PASS.

Obsolete launch text retained only to identify the forbidden candidate:

```sh
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_kernel144_exact_v2_poison_cleanup_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/cleanup_kernel144_exact_v2_poison_signature_v1.wls
```

Do not run this candidate. New artifact missions must use a dedicated artifact
context and must never hydrate `x`, `y`, or `eps` in `Global``.

