# CF300 Galois-orbit screen V3: exact persistent-kernel cleanup

Date: 2026-08-23

V1 and V2 are preserved and must not be launched. The V1 same-kernel poison
model failed closed although both canonical reads and fingerprints were
correct. Its aggregate hashes included values and attributes, so the old log
cannot distinguish those components. The exact diagnosis is therefore an
inference until the corrected model runs: `Internal`InheritedBlock` restores
symbol definitions but does not restore attributes changed by
`Unlock`/`Unprotect`; all three old hashes consequently changed because all
three poison symbols were `Protected`.

The corrected V2 poison model now reproduces the legacy cleanup last and
reports exact per-component restoration for `OwnValues`, `DownValues`,
`UpValues`, `SubValues`, `NValues`, `DefaultValues`, `FormatValues`, and
`Attributes`. It requires the inferred signature: every definition component
is restored and only `Attributes` fails.

## V3 correction

V3 retains canonical Global hydration and private driver state, but wraps it
in guaranteed cleanup:

1. exact definition states and attribute lists of `Global`x`, `Global`y`, and
   `Global`eps` are snapshotted;
2. `Internal`InheritedBlock` localizes definitions;
3. unlock, unprotect and `ClearAll` sanitize the canonical hydration symbols;
4. all hydration, validation, rebind and sampling runs in the canonical
   Global context;
5. after `InheritedBlock` restores definitions, `Internal`WithLocalSettings`
   cleanup restores the original attributes, applying `Locked` last;
6. exact `SameQ` of all saved definition components and attributes is required
   before the requested process exit is honored.

No `System`Exit` executes inside the sanitized scope. `finish` issues a
private tagged `Throw`; the scope catches it, restores and verifies state, and
only then dispatches the exit outside the cleanup scope. Unexpected throws and
aborts still cross `WithLocalSettings` cleanup.

The corrected model installs exact Own/Down/Up/Sub poison plus
`Protected|Locked`, checks two canonical reads, checks cleanup across an
intentional nonlocal throw, proves the original caller state is restored after
the complete model scope, and separately compares canonical and isolated
hydration. It also reports the legacy restoration result by exact component.

## Required model launch

Run this first on the managed persistent pool:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_galois_hydration_poison_model_xh_v2 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_hydration_context_poison_model_v2.wls
```

Do not launch production unless this mission exits 0 and reports
`LegacyAttributeOnlyFailureObserved -> True`, every corrected state-restoration
field `True`, canonical variables in `Global``, isolated variables in the V2
isolation context, and the expected fingerprint difference.

## Production launch after the model passes

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v3 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_cf300_sector12_galois_orbit_forcing_screen_v3.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v3.wl \
  2
```

## Frozen code hashes

- V1 driver: `ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0`
- V2 driver: `5b2238dde9ecdc77d9114f97955ce700aa4308ccbcbc73ddfa22f6e47ade91de`
- V3 driver: `8952afbda47958104eb473a4c24705283f517ba6a58816eec9d194d0f294e265`
- failed-model V1: `3d2b1bdfa89628a9098885bea6097c54d591666af723f5db6008e5cb6870a630`
- corrected-model V2: `aff670514603ac2a87b9fcf92d88ebd2ef1b29330f2b7d7b41234d339b1393f2`
- fixture: `300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4`
- V3 static audit: `36bda74646e4cb40316a4d2a9dcf20a5b1b0ed1f083fff21a4591ad3a184a3fd`

No kernel or pool mission was launched while preparing V3. Static audit
passed 85/85 and the no-kernel lexical guard passed for V3, model V2 and the
fixture.

