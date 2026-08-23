# CF303 fresh identity-frame capture gate V4

Prepared statically on 2026-08-23 after V3 failed closed.  V1-V3 were not
edited.  No Wolfram/native kernel was launched and no process or mission was
touched, stopped, signalled, reniced, or affinity-changed.

## Exact V3 predicate failure

V3 correctly returned ordinary `$Failed`; the pool log contains `MISSION end`
with status `FAILED` after 0.1 seconds.  It created no CF303 state.  Its failed
predicate did **not** demonstrate a missing pool contract.

The V3 bug was:

```wl
ToString[HoldComplete[DownValues[Global`poolRun]], InputForm]
```

and the analogous expressions for `System`Exit and `System`Quit.
`HoldComplete` prevented `DownValues[...]` from evaluating.  The resulting
text represented the literal held call, not the definition list.  Therefore:

* `PoolRunHasKernelPoolExit` was false;
* `PoolRunHasMissionEnd` was false;
* `PoolRunHasDoneMarker` was false;
* `ExitHasKernelPoolExit` was false;
* `QuitHasKernelPoolExit` was false.

The conjunction necessarily failed on every worker, independent of symbol
context.  The V3 static test missed this because it asserted that source tokens
were present but did not model Wolfram's hold attributes or actually evaluate
the probe.

V3 remains preserved at
`4969fe24022305569c139e678ee59c6cf7c10364079fb516eb7514f44cc19f66`.

## V4 contract

V4 removes live `DownValues` introspection entirely.  Its executable wrapper
contains no `DownValues` call.  It uses the context-independent scheme allowed
for this gate:

* pin the current `Scripts/KernelPool.wls` source;
* pin the active pool's saved `poolrun_definition.m`;
* pin the 69-file package/data manifest;
* retain the V3 private tagged preflight `Catch`/`Throw` protocol;
* locally catch the family driver's `KernelPoolExit`, restore environment,
  `$ScriptCommandLine`, and working directory, write a typed status, then
  rethrow the exact payload/tag to pool cleanup.

Pinned runner hashes:

* KernelPool source:
  `0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d`
* active saved poolRun definition:
  `d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51`

The saved definition contains the `KernelPoolExit` catch plus `MISSION end` and
`.done` writes.  The KernelPool source installs the corresponding worker
`Exit`/`Quit` interception.  If either file changes, V4 fails normally with
`$Failed`; it does not guess across pool versions or contexts.

As in V3, V4 contains no executable wrapper call to `Return`, `Exit`, or
`Quit`.  Every wrapper validation failure is a private tagged throw caught by
the target itself and returned to `Get` as ordinary `$Failed`.

## Safe-to-launch verdict

**V4 is statically safe to launch against the currently pinned tree and active
pool.**  It uses fresh label/output, CF303 only, no chart override, no CF300
state/preparation/plan/artifact, FiniteFieldFirst, Production,
`FACET_KERNEL_COUNT=1`, both broker ceilings zero, no existing nested kernels,
and atomic typed status artifacts.

Fresh mission label:

```
cf303_identity_capture_xh_v4
```

Fresh output:

```
/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v4
```

Exact launch from `/home/maxzhang/factorization-and-loops`:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf303_identity_capture_xh_v4 \
  External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/run_cf303_identity_capture_fresh_xh_v4.wls
```

## Optional exact live no-op probe

An adjacent read-only probe is available if root wants runtime evidence before
launching V4.  Unlike V3, it first evaluates each `DownValues` into a local
list and only then stringifies that list.  It also reports the old held
expression so the V3 failure is directly visible.  It calls none of
`Return`/`Exit`/`Quit`, launches no helper, and writes no target artifact.

Root-only exact command:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf303_pool_exit_contract_noop_v1 \
  External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/probe_cf303_pool_exit_contract_noop_v1.wls
```

Expected record fields are the three positive poolRun checks, the two positive
worker interception checks, and
`"FormerHeldExpressionEvaluated" -> False`.

## Static regression

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/test_cf303_identity_capture_gate_v4_static.py
```

Current result: **120/120 PASS**.  It verifies all 69 source hashes, the two
runner hashes, unchanged V1-V3, the private control-flow model, absence of
wrapper-level escape calls, absence of `DownValues`/`ParentDirectory` and
process controls in V4 executable code, environment restoration before the
driver-exit rethrow, fresh lexical output, and the exact evaluate-then-stringify
shape of the optional runtime probe.

## Frozen hashes

* V4 wrapper:
  `f0b8f0a4c13b9b0bb07308fdd89321e4e4db30b1b7a05fc69172336d5ea60a6e`
* no-op probe:
  `c3442570fba2a0210a6e97111ce9df3832129b2d8c7dd7440b1c3b462bab3935`
* V4 static verifier:
  `aba1cf77c911befcf49c9f79b4dcbdeee89bab89f8d152cd6d9d798206f334fb`
* shared package/data manifest:
  `0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d`

