# CF300 sector-12 recapture V2: context-safe relaunch

V1 successfully produced the exact sector-12/lower-11 strip and left the copied
state unchanged, but then failed its dynamic-state restoration gate.  The V1
wrapper used a top-level `Global`` `Module`; reentrant FACET/FeynCalc loading can
clear temporary `Global`` control symbols, so its restore helper no longer
executed.  The failed log, status, launch seal, copied state/snapshot, and strip
are frozen and hash-pinned by V2.

V2 moves every wrapper control symbol into
`CodexCF300Sector12RecaptureV2`Private`` and executes only the production family
driver under `Global``.  It captures raw `$MessageList`, restores all seven
environment components, `$ScriptCommandLine`, its `Protected` state, and the
working directory, and prints the componentwise saved/current telemetry before
classifying either messages or the tagged exit.  It accepts only the exact
runtime-observed startup signature
`HoldForm[BuildBasis::length]`; the rendered V1 evidence is
`BuildBasis::length: Expected four basis vectors, but received {nb, 5, xhat,
yhat}.`  Any extra, missing, or differently qualified message fails closed.
Only `{"EXIT",75}` is accepted; every other tagged payload is retained through
the private-context cleanup and rethrown unchanged afterward.

The wrapper contains no explicitly qualified symbol token in its own dedicated
context.  This is required because kpsubmit first parses the full target under
`HoldComplete`: explicitly qualified tokens survive its disposable-context
cleanup and would make the wrapper's clean-context preflight reject the later
real `Get`.  Runtime context inspection uses `System`Names` and cleanup uses
`System`Remove` explicitly, avoiding FeynCalc's known `Names` shadow.  It also
removes and verifies the dedicated public/private context in `$ContextPath` and
`$Packages` after `EndPackage`.

The superseded first parse probe is preserved as
`probe_cf300_s12_recapture_v2_parse_context_xh_v1_SUPERSEDED_HUNG.log`.  It
demonstrates both hazards: unqualified `Names` stayed symbolic, and a top-level
`Return[$Failed]` escaped because `Module` is not a return boundary.  The final
probe uses `Catch`/`Throw`, contains no `Return`, uses only System-qualified
namespace primitives, never `Get`s the production wrapper, and writes nothing.
Do not signal or restart its stuck K141 mission; it is outside the final launch.

## Frozen artifacts

- Wrapper: `run_cf300_sector12_recapture_from_v4_xh_v2.wls`
  - SHA-256 `8667a863f0fe60a8fc59080880c7736ee76114189bb1b49196c342a2f2a9ccbb`
- Clean-worker held-parse/context probe:
  `probe_cf300_sector12_recapture_v2_parse_context.wls`
  - SHA-256 `bf85d8df492e8b4a95c2a692f74177377daedc4d96cfa6da3b1de125cc6cb531`
- Static adversarial audit:
  `test_cf300_sector12_recapture_from_v4_xh_v2_static.py`
  - SHA-256 `62f1431f3e93287271f4ab3c60dbd26f4f2792b985e95720e5c01a0a1232b323`
  - result `PASS 596/596`
- Superseded diagnostic log:
  - SHA-256 `cf2c09fbfeab9f079f253434edb812d5a18364b8260802fc36eb70f96f7f4331`

The fixed V2 output directory
`/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v2`
must not exist before launch.  It was absent at freeze time.

## Required central launch sequence

First run the clean-worker parser/context gate.  Its kpsubmit-generated wrapper
is also the required independent actual Wolfram held-parse diagnostic:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  probe_cf300_s12_recapture_v2_parse_context_xh_v2 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/probe_cf300_sector12_recapture_v2_parse_context.wls
```

Require normal pool status `OK`, result `0`, no messages, a `HoldComplete` parse,
unchanged dedicated and `Global`` namespaces, a populated disposable parse
context, and successful literal cleanup.  Use a clean free worker such as K24,
K146, or K147; not K141 or poisoned/quarantined K144.

Only after that gate passes, submit the recapture with no script arguments:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_recapture_from_v4_xh_v2 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v2.wls
```

Expected completion is normal pool status `OK` with wrapper result `0`.  The
wrapper itself intercepts the intentional driver exit 75.  It uses one main
worker, helper ceiling zero, no nested kernels, `Production`,
`FiniteFieldFirst`, resume hydration, record-only mode, sector budget 7200 and
direct budget 30.  It independently reconstructs and exact-compares the strip,
requires the copied state to remain the certified sector-11 state, forbids a
sector-12 checkpoint, and rehashes all V4, validator, V1, pool-contract, and
69-source provenance before writing its atomic result.
