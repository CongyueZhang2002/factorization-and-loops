# CF303 fresh identity-frame capture gate V3

Prepared statically on 2026-08-23.  V1 and V2 were not edited.  No Wolfram or
native kernel was launched, and no mission/process was touched, signalled,
stopped, reniced, or affinity-changed.

## V1/V2 withdrawal and control-flow diagnosis

Do **not** launch V1 or V2.

V1 exposed two independent wrapper defects:

1. `ParentDirectory[outdir]` was filesystem-sensitive and failed on the
   intentionally nonexistent fresh target.  V2 fixed this part with lexical
   `DirectoryName[outdir]`.
2. More seriously, V1's wrapper-level `Return[$Failed]` dynamically returned
   from `poolRun`'s enclosing `Module`, not merely from the target loaded by
   `Get`.  It bypassed `poolRun`'s `MISSION end`, log close, `.result`, and
   `.kernel.done` code.  The scheduler retained a stale running job even after
   the same worker was reused.  V2 retained this defect and is withdrawn.

Preserved source hashes:

* V1: `586e46e7b157f063f1e0c2ce926a0c736f43c6e5745e38fb6e8f975b3537cc8d`
* V2: `5b75e81df5907a45882e7f82183b9e7bfd5a2960e4b0ce031bb3dd6fe6959a9d`

## V3 control-flow contract

V3 contains no executable call to `Return`, `Exit`, or `Quit`.

Every validation branch calls a private failure helper which performs

```wl
Throw[$Failed, preflightTag]
```

inside one matching private

```wl
wrapperResult = Catch[..., preflightTag]
```

The final target expression is `wrapperResult`.  Consequently a failed
preflight returns the ordinary value `$Failed` from `Get`; `poolRun` then sets
status `FAILED` and continues through its mission-end and completion-marker
protocol.  No private validation throw can match the pool's distinct
`"KernelPoolExit"` tag.

The V3 atomic helper was also rewritten without `Return`; failed writes are
ordinary `$Failed` expression values.

## Family-driver Exit/Quit contract and environment cleanup

The earlier claim that a normal driver `Exit` terminates the worker was wrong.
The KernelPool deliberately reuses the worker:

* `Scripts/KernelPool.wls:60-64` installs definitions mapping `Exit[code]` and
  `Quit[code]` to `Throw[{"EXIT", code}, "KernelPoolExit"]`;
* `Scripts/KernelPool.wls:176-180` catches that tag around `Get[file]` and maps
  the code to pool status;
* `:183-195` then writes `MISSION end` and `.kernel.done`.

V3 pins the KernelPool source and the active pool's saved `poolRun` definition.
Before changing any environment it also inspects the live `DownValues` of
`Global`poolRun`, `System`Exit`, and `System`Quit`, requiring the
`KernelPoolExit`, `MISSION end`, and `.done` contract strings.

V3 locally catches a family driver's `KernelPoolExit` payload, restores every
environment value it changed plus `$ScriptCommandLine` and the working
directory, atomically writes
`CF303_identity_capture_status_driver_exit_v3.wl`, and only then rethrows the
same payload/tag to `poolRun`.  Thus the worker is safely reusable and the pool
still receives the intended exit code.  Aborts and ordinary driver returns
also restore the same state and write typed status files.

Pinned runner hashes:

* `Scripts/KernelPool.wls`:
  `0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d`
* active `poolrun_definition.m`:
  `d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51`

## Safe-to-launch verdict

**V3 is statically safe to launch**, subject to its runtime hash, live pool
contract, and fresh-output gates.

It preserves the mathematical/run isolation contract: CF303 only, no CF300
state/preparation/plan/artifact, no chart override, FiniteFieldFirst,
Production checks, `FACET_KERNEL_COUNT=1`, both task-broker ceilings zero,
no existing nested kernels, 69 package/data pins plus the KernelPool source,
and atomic typed launch/running/terminal records.

Fresh V3 mission label:

```
cf303_identity_capture_xh_v3
```

Fresh V3 output:

```
/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v3
```

## Exact launch

From `/home/maxzhang/factorization-and-loops`:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf303_identity_capture_xh_v3 \
  External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/run_cf303_identity_capture_fresh_xh_v3.wls
```

## Static regression

Run immediately before launch:

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/test_cf303_identity_capture_gate_v3_static.py
```

Current result: **110/110 PASS**.  It verifies:

* all 69 package/data hashes plus KernelPool source, active pool definition,
  and unchanged V1/V2 hashes;
* Wolfram delimiter balance and all V3-specific serialization/atomic/status
  contracts;
* no executable wrapper call to `Return`, `Exit`, or `Quit`;
* no `ParentDirectory`, nested-kernel launch, process control, deletion, or
  CF300 reference in executable wrapper code;
* private tagged validation failure becomes ordinary `$Failed`, after which a
  modeled `poolRun` writes both mission-end and done markers;
* modeled driver exit codes 0 and 2 are restored/rethrown and still produce
  pool statuses `OK` and `EXIT2` with both markers;
* V3's target is absent, its lexical parent exists, and the modeled freshness
  preflight is message-free.

The actual held Wolfram parse remains a separate `kpsubmit.sh` runtime gate.
No Wolfram kernel was used to prepare or test V3.

## Frozen hashes

* V3 wrapper:
  `4969fe24022305569c139e678ee59c6cf7c10364079fb516eb7514f44cc19f66`
* V3 static verifier:
  `6c7800bd7b6521269707d8caee826f125c2d80e5f689bc0d43ce839cfd049315`
* shared 69-source manifest:
  `0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d`

