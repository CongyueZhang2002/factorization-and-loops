# CF303 fresh identity-frame capture gate V2

Prepared statically on 2026-08-23 after V1 exposed a preflight-only bug.  No
Wolfram/native kernel was launched, and the V1 mission was not touched,
signalled, stopped, or modified.

## V1 diagnosis and preservation

The V1 source remains byte-for-byte at SHA-256
`586e46e7b157f063f1e0c2ce926a0c736f43c6e5745e38fb6e8f975b3537cc8d`.
Its log showed, before any output creation or driver load:

```
ParentDirectory::dirnex
StringJoin::string
```

Cause: Wolfram `ParentDirectory[path]` requires `path` itself to be an existing
directory in this runtime.  The wrapper intentionally requires the fresh
output target not to exist, so the parent check was self-contradictory.
`ParentDirectory[outdir]` remained unevaluated and was then concatenated with a
string, producing the second message.

V2 uses the lexical operation once:

```wl
outdirParent = DirectoryName[outdir];
```

and applies both `DirectoryQ` and diagnostic formatting to that guaranteed
string.  V1 was not edited.

## Safe-to-launch verdict

**V2 is safe to launch**, conditional on its repeated runtime source and
freshness checks.  It retains all V1 isolation controls: one existing pool
worker, `FACET_KERNEL_COUNT=1`, mission and inherited broker ceilings zero,
no existing nested kernels, FiniteFieldFirst, Production, a fresh CF303-only
state, no chart override, 69 source hashes, and atomic typed status files.

Fresh V2 output:

```
/tmp/codex-triple-root-20260823c.vx654S/cf303_identity_capture_xh_v2
```

Fresh V2 mission label:

```
cf303_identity_capture_xh_v2
```

## Exact launch

From `/home/maxzhang/factorization-and-loops`:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf303_identity_capture_xh_v2 \
  External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/run_cf303_identity_capture_fresh_xh_v2.wls
```

Do not reuse the V1 label or target.

## V2 regression gate

Run immediately before submission:

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf303_identity_capture_gate_2026-08-23_xh/test_cf303_identity_capture_gate_v2_static.py
```

Current result: **98/98 PASS**.  Besides the prior source/parser/isolation
checks, it now:

* requires `DirectoryName[outdir]` and forbids `ParentDirectory` in executable
  wrapper code;
* models the exact nonexistent V2 target and an additional nonexistent sibling;
* requires both lexical parents to exist and the modeled parent/freshness
  preflight to emit no message;
* requires V2-specific output, tag, typed launch/running sentinels, atomic
  rename, environment restoration, and zero-helper controls.

The real Wolfram held-parser gate remains in `kpsubmit.sh` and executes when V2
is submitted.  No kernel was used for this static regression.

## Frozen hashes

* V2 wrapper:
  `5b75e81df5907a45882e7f82183b9e7bfd5a2960e4b0ce031bb3dd6fe6959a9d`
* V2 static verifier:
  `72f05b9484511bae23468d63511900ee1eed1239cf4f4adb339822d2ada13809`
* shared 69-source manifest:
  `0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d`

