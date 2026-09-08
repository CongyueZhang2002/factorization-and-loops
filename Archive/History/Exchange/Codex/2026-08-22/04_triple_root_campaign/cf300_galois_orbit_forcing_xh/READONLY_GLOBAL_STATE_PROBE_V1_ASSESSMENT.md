# CF300 read-only Global symbol-state probe V1

Status: frozen for a centrally managed live run. This is a diagnostic gate only.

The probe reads, twice, the exact `OwnValues`, `DownValues`, `UpValues`,
`SubValues`, `NValues`, `DefaultValues`, `FormatValues`, and `Attributes` of
`Global`x`, `Global`y`, and `Global`eps`. It prints the exact held rule tables,
whole-state SHA-256 fingerprints, per-component SHA-256 fingerprints, and
same-kernel before/after/context checks.

It never unlocks, unprotects, clears, assigns, removes, exports, launches a
kernel, or starts a process. The only `ClearAll` is scoped to the probe's fresh
private package context. Static policy gate: 38/38 PASS. The no-kernel Wolfram
parse guard also passes.

Central launch (one main kernel, no helpers/subkernels):

```sh
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_galois_global_state_readonly_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/inspect_cf300_galois_global_symbol_state_readonly_v1.wls
```

Interpretation is deliberately two-stage. Do not run a cleanup from an
expected state. First capture this probe's exact diagnostics. Only then may an
adjacent cleanup gate be written, pinned to the observed exact definition
tables and attributes. That later gate must fail without mutation on any
signature mismatch.

