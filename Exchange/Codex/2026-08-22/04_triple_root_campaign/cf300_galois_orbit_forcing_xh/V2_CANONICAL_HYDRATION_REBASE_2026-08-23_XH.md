# CF300 Galois-orbit screen V2: canonical cache hydration rebase

Date: 2026-08-23

V1 remains unchanged as evidence and must not be launched. The central probe
proved that its private-package caller context is unsafe for the compiled
cache: the stored/canonical `ExactChannelFormsFingerprint` is
`fc5496...e34d`, whereas viewing the same value from the isolated context
produces `e241f1...1a08`; the public reader correctly fails closed.

## V2 correction

V2 keeps every driver variable in
`CodexCF300GaloisOrbitForcingDriverV2`Private``. The complete artifact-facing
and fingerprint-sensitive computation is dynamically evaluated inside:

- `Internal`InheritedBlock[{Global`x,Global`y,Global`eps}, ...]`;
- a reversible unlock, unprotect and clear of those three symbols;
- `$Context = "Global`"` with an explicit canonical context path.

Because the large outer `Block` is parsed after `Begin["`Private`"]`, driver
state remains private. Only artifact hydration resolves unqualified `x`, `y`
and `eps` canonically. Keeping the downstream validators, ansatz rebind and
sampler in the same dynamic block also prevents later fingerprint validation
from reverting to the isolated caller view.

The hydration gate records and requires all of the following value-level
facts before starting the orbit census:

- preparation status, public ABI validator, variable names and contexts, and
  regulator name/context;
- raw cache status, raw artifact validator and raw assembly validator;
- public reader status, reader artifact validator and reader assembly
  validator;
- exact value identity of raw and reader artifacts;
- stored, recomputed and expected exact-channel fingerprint equality;
- stored, recomputed and expected compiled-form fingerprint equality.

Pinned fingerprints:

- exact channels:
  `fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d`
- compiled forms:
  `e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7`

The raw duplicate cache value is cleared immediately after this gate to bound
the hydration memory overhead.

## Same-kernel poison regression model

`run_hydration_context_poison_model_v1.wls` and its pinned fixture provide a
small same-kernel model. It installs protected own-value poison on
`Global`x`, `Global`y` and `Global`eps`; performs two canonical reads; proves
the poison is restored after each nested inherited block; hydrates the same
fixture in an isolated context; and requires both the expected symbol-context
difference and the canonical-versus-isolated fingerprint mismatch.

No Wolfram kernel was launched while preparing V2. To execute the model on the
managed persistent pool before production, use:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_galois_hydration_poison_model_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_hydration_context_poison_model_v1.wls
```

This model uses one pool kernel and no subkernels or native helpers.

## Production V2 launch

After the poison model passes, use only the centrally managed pool:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v2 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_cf300_sector12_galois_orbit_forcing_screen_v2.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v2.wl \
  2
```

The final argument grants two native FLINT threads. Wolfram execution remains
on one pool kernel and launches no Wolfram subkernels.

## Validation and hashes

- V1 unchanged:
  `ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0`
- V2 driver:
  `5b2238dde9ecdc77d9114f97955ce700aa4308ccbcbc73ddfa22f6e47ade91de`
- V2 static audit:
  `3fd2888fc0f55e5532df1fd12b0bb0f6f6e0afbce00bacb4700b8a3283f4c4af`
- poison model:
  `3d2b1bdfa89628a9098885bea6097c54d591666af723f5db6008e5cb6870a630`
- fixture:
  `300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4`

No-kernel checks passed: V2 static audit 63/63 and the nested-comment,
string, context-token and delimiter guard on the V2 driver, poison model and
fixture.

