# CF300 sector-12 recapture V3

V2 proved that moving wrapper controls out of the Global context fixed V1's
restoration failure: all seven environment components, command line,
protection state, and directory restored exactly.  Its K141 run then failed
closed for two independent reasons:

1. K141 carried Global symbols shadowing FeynCalc/FeynArts (`$LoadFeynArts`,
   `$LoadAddOns`, and `A0`), so the raw message list contained three `shdw`
   messages in addition to `BuildBasis::length`.  V2 correctly rejected it.
2. V2 tried to assign the protected system variable `$Packages` during final
   context cleanup, producing `Set::wrsym`.

V3 uses a source-pinned two-file design.  The launcher performs a read-only
dirty-worker gate before the body can create its fixed V3 output directory.  It
rejects the three known K141 hazards and every Global basename overlapping an
already loaded FeynCalc, FeynArts, FeynFacet, or CANONICA public symbol.  It then
runs the private body inside
`Internal`InheritedBlock[{System`$ContextPath,System`$Packages}, ...]`.
The body uses `BeginPackage`/`EndPackage`, but never assigns `$Packages` or
`$ContextPath`; the launcher requires their values, `$Context`, and the
`Protected` state of `$Packages` to restore exactly before it returns or
forwards any non-75 driver payload.

The clean-worker message contract is deliberately unchanged: the body accepts
only the singleton raw signature `HoldForm[BuildBasis::length]`.  It does not
allow any `shdw` message.  It pins the complete V1 and V2 sources, logs,
statuses, launch seals, copied state/snapshots, and identical strip, as well as
the certified V4/validator/69-source provenance.  V1 and V2 directories remain
immutable.

## Frozen sources

- launcher `run_cf300_sector12_recapture_from_v4_xh_v3.wls`
  - SHA-256 `07029adc6eddbd0fefd6e8287123f35f7297c8bc6327b27c712477036d833c97`
- private body `run_cf300_sector12_recapture_from_v4_xh_v3_body.wls`
  - SHA-256 `138ddd8643bff53779a14503c7c3579cc6b5375aab486e6a2e8719e3745ddff3`
- no-write lifecycle probe
  `probe_cf300_sector12_recapture_v3_localized_packages.wls`
  - SHA-256 `7de4b1ba1f8fd4292d2e290ed245b7160dba8bc628af14b5e116e984959c0df0`
- static audit `test_cf300_sector12_recapture_from_v4_xh_v3_static.py`
  - SHA-256 `eca12824dc3184f0e84f7462bc9a5407cd1fad89f8911030edb7e43780678a73`
  - result `PASS 645/645`

The V3 output directory
`/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v3`
was absent at freeze time and must remain absent before the production launch.

## Required central launch order

First run the no-write lifecycle proof on a clean worker (K24, K146, or K147;
not held K141 or quarantined K144):

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  probe_cf300_s12_recapture_v3_localized_packages_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/probe_cf300_sector12_recapture_v3_localized_packages.wls
```

Require normal pool status `OK`, result `0`, no messages, both localized
package/path presence gates true inside the inherited block, and exact outer
value/attribute restoration plus name cleanup.

Only after that passes, submit the source-pinned launcher with helper ceiling
zero and no script arguments:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_recapture_from_v4_xh_v3 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v3.wls
```

Expected completion is pool status `OK`, wrapper result `0`, exact singleton
`BuildBasis::length` captured internally, successful V3 lifecycle telemetry,
and an exact sector-12/lower-11 strip.  The production driver remains one main
worker, zero helpers/subkernels, `Production`, `FiniteFieldFirst`, resume
hydration, record-only mode, sector budget 7200 and direct budget 30.
