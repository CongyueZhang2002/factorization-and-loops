# CF303 fresh identity-frame capture gate

Static preparation only, made 2026-08-23.  No Wolfram kernel, native solver,
or package source was launched or changed while preparing this gate.

## Verdict

**Safe to launch now**, subject to the wrapper's repeated runtime checks.  The
output path is currently absent and all 69 pinned sources match.  The wrapper
uses the current `Scripts/family_epsform_sector.wls`, the complete current
FeynFacet Wolfram source closure, the FLINT executable/source, the CF303
differential system, the block assignment, and all 24 CF303 class forms.

This is a fresh CF303 run.  It accepts no arguments, hard-codes family
`CF303`, supplies no chart override (therefore `TransportFamilyChart["CF303"]`
selects the identity multiquadratic frame), and writes only to

```
/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v1
```

It does not reference a CF300 preparation, plan, checkpoint, state, or
finite-field artifact.

## Exact launch

Run from `/home/maxzhang/factorization-and-loops`:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf303_identity_capture_xh_v1 \
  External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/run_cf303_identity_capture_fresh_xh_v1.wls
```

The wrapper passes the family driver exactly:

```
CF303
/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v1
1800
identity_capture_xh_v1
30
""  (no chart file)
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/ClassForms
```

The exact environment during the driver is:

```
FACET_KERNEL_COUNT=1
FACET_TASK_BROKER_MAX_HELPERS=0
FACET_CHECK_LEVEL=Production
FACET_STRIP_ROUTE=FiniteFieldFirst
FACET_ZERO_FORCING=True
FACET_RECORD_STRIP_ONLY=False
FACET_RESUME_HYDRATION=True
FACET_MEMTRACE=/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v1/memtrace.log
```

## Parallelism and process safety

The unwrapped family driver can request nested Wolfram kernels: it calls
`LaunchKernels` when `FACET_KERNEL_COUNT > 1`, and a one-kernel finite-field
solve can broker sample batches to free KernelPool workers.  This wrapper
closes both paths:

* it refuses a main kernel and requires a pool subkernel;
* it refuses launch if `Kernels[]` is nonempty;
* it forces `FACET_KERNEL_COUNT=1`;
* it requires the mission-scoped `KernelPoolMission` helper ceiling to equal
  zero and also sets the inherited broker environment ceiling to zero;
* `FiniteFieldFirst` does not enter the CANONICA off-diagonal solver loop, and
  the package loader forces CANONICA's own compute-parallel flags false.

Thus the mission occupies one existing KernelPool worker and launches no
nested Wolfram subkernel or pool helper.  The package's automatic fixed-core
backend may execute the pinned FLINT binary with its existing two native
threads; that is not a Wolfram kernel or an additional pool mission.

No wrapper code signals, stops, deletes, renices, or changes affinity of any
process.  No process was signalled during preparation.

The wrapper snapshots all environment values it changes.  On a caught abort
or an ordinary return it atomically records a typed status and restores the
environment, `$ScriptCommandLine`, and working directory.  The standard family
driver normally ends with `Exit`; that terminates the pool worker process, so
its process-local environment ceases to exist rather than leaking into a
reused worker.  Before entering the driver, the wrapper atomically writes both
`CF303_identity_capture_launch_seal.wl` and the typed
`CF303_identity_capture_status_running.wl`.  Driver typed stops atomically
write their family state/input artifacts before `Exit`.

## Freshness, parser, and atomic gates

At runtime the wrapper refuses:

* any source/manifest hash mismatch;
* any extra wrapper argument;
* a main kernel, an existing nested kernel, or a nonzero mission helper cap;
* a pre-existing output path;
* a missing output parent;
* a failed atomic launch-seal or running-status write.

`kpsubmit.sh` additionally performs a held parse of the actual wrapper before
`Get`; its generated mission fails if parsing fails.  The local no-kernel test
also strips nested Wolfram comments/strings and checks delimiter balance,
source closure, all hashes, the exact 24-class CF303 form set, isolation from
CF300, the serialization controls, and the atomic-write pattern.

Run immediately before submission:

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/test_cf303_identity_capture_gate_static.py
```

Current result: **99/99 PASS**.

## Expected capture evidence

The purpose is to run normally to the first physical typed stop, not merely
record the first strip (`FACET_RECORD_STRIP_ONLY=False`).  A mission filed as
failed by the pool can still be the expected successful capture because the
family driver uses exit code 2 for typed mathematical stops.  Inspect, in
order:

1. `CF303_identity_capture_launch_seal.wl` and
   `CF303_identity_capture_status_running.wl`;
2. `sector_state_CF303_identity_capture_xh_v1.wl`, especially its `Stop` key;
3. `sector_CF303_identity_capture_xh_v1/CF303_*_input.wl` and any matching
   `_unsolved.wl`;
4. if the family completes, `family_epsform_CF303.wl` (a Production candidate
   still requires the separate exact family certificate).

Interpret the first state stop as follows:

* `NeedsMultiquadraticRegulatorFactorization`: implement/certify the constant
  multiquadratic truncation transform; a strip reconstruction is not the
  remedy.
* a frame/strip failure such as `NoRationalStripChart`: use the newly captured
  CF303 strip only to build a fresh adapter/preparation/elimination plan.

Do not rerun this fresh wrapper after it has created the output directory; its
freshness gate intentionally refuses.  A later continuation should use a
separately reviewed resume wrapper against this CF303 state.

## Frozen hashes

* source manifest:
  `0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d`
* launch wrapper:
  `586e46e7b157f063f1e0c2ce926a0c736f43c6e5745e38fb6e8f975b3537cc8d`
* static verifier: recorded in the adjacent final `SHA256SUMS`.

