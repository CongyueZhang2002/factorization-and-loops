# CF300 Galois-orbit forcing screen V5: Names-shortening rebase

Date: 2026-08-23

Status: frozen and not launched by the subagent.

## V4 live result

Production V4 ran centrally on clean kernel 24 and exited at the hydration
gate after 15.15 seconds. Every substantive condition passed:

- preparation, cache, and assembly validators;
- stored/recomputed exact and compiled fingerprints;
- preparation variable and regulator contexts;
- absence of `Global`` from the runtime path;
- definition-free dedicated symbols.

The sole failure was representational. Inside the dynamic artifact block,
`Names["CodexCF300GaloisOrbitArtifactV4`*"]` returned the short strings
`{"eps","v","w","x","y"}` because the artifact context was visible on
`$ContextPath`. The old gate compared those strings directly with fully
qualified strings, yielding a false negative. The pinned failure artifact is
`2f5f39d0...ced3`; it contains no physics or fingerprint failure.

## V5 correction

V5 never treats a `Names` string as a symbol-identity certificate. Every raw
name is first canonicalized: a short name is prefixed by the fixed artifact
context, while an already-qualified name is preserved. `ToExpression` then
resolves the canonical name through a `HoldAll` accessor. For every resolved
symbol V5 records and verifies:

- `Context[symbol]` is exactly `CodexCF300GaloisOrbitArtifactV5``;
- `SymbolName[symbol]` is exactly one of `{v,w,x,y,eps}`;
- `Context[symbol] <> SymbolName[symbol]` is exactly the expected full name;
- the five canonical names are duplicate-free and complete.

The same normalization is used by definition-state inspection, so short names
cannot accidentally inspect driver-private carriers. Namespace audits are run
before hydration, inside the artifact block after hydration, and after the
block before cleanup. Direct raw-string comparisons were removed. Literal
context removal and the final zero-name check remain unchanged.

All V4 physics, Galois identities, exact channel deduplication, ansatz rebind,
finite-field sampling, and the qualified subset-embedding certificate are
otherwise unchanged.

## Static validation

- V5 static adversarial audit: 91/91 PASS.
- Wolfram no-kernel nested-comment/string/context-token/delimiter guard: PASS.
- V1--V4 hashes remain unchanged.
- No Wolfram kernel or process was launched while preparing V5.

## Central launch candidate

Use a clean non-144 main kernel and a fresh V5 output path:

```sh
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v5 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_cf300_sector12_galois_orbit_forcing_screen_v5.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v5.wl \
  2
```

V5 launches no Wolfram subkernels; the final argument grants two native FLINT
threads.

