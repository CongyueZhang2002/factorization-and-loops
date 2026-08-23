# CF300 sector-12 recapture V5b: exact K146 lifecycle recovery

## Assessment

A fresh pool is **not required** if the current K146 reservation exits naturally
with its own state/source-stability gates true.  The V5 failure is fully
explained by the fingerprint reader, not by a damaged FeynCalc/FeynArts
installation:

- FeynArts defines `M$ClassesDescription := (Message[...]; Abort[])` while no
  classes model is loaded.
- `Attributes[Options] == {Protected}`; therefore
  `Options[M$ClassesDescription]` evaluates the sentinel and aborts.
- `Options[Unevaluated[M$ClassesDescription]]` is non-aborting.  `Messages`
  already has `HoldAll`.
- V5 aborted before its preflight and left its probe private context plus a
  `$Packages` entry.  The first diagnostic also aborted and left a second
  private context/package entry.  The frozen lifecycle inspector proves the
  exact two-frame stack and exact 52-name/28-name censuses.

V5b keeps all ten definition components.  It changes only the option-table
reader to `Options[Unevaluated[symbol]]`; message and option definitions are
still fingerprinted.  FeynCalc/FeynArts equivalence is therefore not weakened.

## Recovery contract

The V5b no-write probe first requires all of the following before mutation:

- K146, zero nested kernels, helper ceiling zero;
- exact current context
  `CodexDefinitionReaderHoldDiagnosticK146XH`Private``;
- exact current path
  `{CodexDefinitionReaderHoldDiagnosticK146XH`, System`}`;
- exact `$Packages` prefix diagnostic / V5 probe / pre-existing V4 probe;
- exact 52 V5 private names and exact 28 diagnostic private names;
- no locked or protected symbol among those owned names;
- frozen V5 failure, definition-reader, lifecycle-inspector, FeynArts source,
  and status hashes;
- the 1,685 relevant package-symbol census and a complete ten-component state
  snapshot; and a complete Global state snapshot;
- fresh V5b output absence.

Only after those gates pass does it execute this LIFO stack recovery:

1. diagnostic `End[]`;
2. diagnostic `EndPackage[]`;
3. V5-probe `End[]`;
4. V5-probe `EndPackage[]`;
5. drop exactly the first two known `$Packages` entries;
6. remove only the two known Codex-owned contexts;
7. prove Global definitions, all relevant package definitions, `$Path`,
   directory, and argv are unchanged.

The probe then runs the corrected preflight, prints both package and recovered
lifecycle SHA-256 tokens, and removes its own context and `$Packages` entry.
Production requires both tokens.  Its first expression runs before
`BeginPackage`, accepts only the exact definition-free names interned by the
pinned held-parser, and verifies the lifecycle token before output can exist.

All risky V5b preflight/launcher phases catch aborts and execute dedicated
cleanup.  Post-package-load behavior retains V5's cooperative quarantine; no
process is killed, restarted, or signalled.

## Current live-state gate

At freeze time K146 is intentionally occupied by
`reserve_kernel146_for_k24_exact_qeps_xh_v1`, started 2026-08-23 14:32:27
PDT for at most 1,800 seconds.  Do **not** stop it.  Its pinned source is a
no-mutation reservation: it snapshots Global names, `$Packages`,
`$ContextPath`, `$Path`, assumptions, limits, and history, rechecks them
every five seconds, then `End[]`s and removes only its own context.

Before V5b, run:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/test_cf300_sector12_v5b_recovered_k146_staged.py
```

It intentionally fails while that reservation is active.  Proceed only after
it reports PASS, which requires the reservation's normal `done` status,
`Status -> "OK"`, a release record, and both state/source stability markers.
Any other post-inspector K146 mission fails closed.

## Exact central commands

Run only when K146 is the sole dispatchable worker.

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  probe_cf300_s12_recapture_v5b_recovered_k146_no_write_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/probe_cf300_sector12_recapture_v5b_recovered_k146_k146.wls
```

Require pool status `OK`, result `0`, `HadMessages -> False`, kernel 146,
recovery `GateQ=True`, probe `GateQ=True`, both definition-equivalence
gates true, dedicated cleanup true, and V5b output absent.  Extract the unique
64-lowercase-hex payloads from:

```text
CF300_V5B_RECOVERED_K146_PACKAGE_FINGERPRINT_SHA256=<64hex>
CF300_V5B_RECOVERED_K146_LIFECYCLE_SHA256=<64hex>
```

Then, with no intervening K146 mission:

```bash
cf300_v5b_package_fingerprint='<package-64hex>'
cf300_v5b_lifecycle_fingerprint='<lifecycle-64hex>'

POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_recapture_from_v4_xh_v5b_recovered_k146 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146.wls \
  "$cf300_v5b_package_fingerprint" \
  "$cf300_v5b_lifecycle_fingerprint"
```

A missing, duplicate, wrapped, non-hex token; wrong kernel; any message; any
intervening K146 mission; or any path/source/state drift is a hard stop.  Do
not write a quarantine release sentinel during the active campaign.

## No-kernel validation

- static/adversarial audit: `PASS 102/102`, including 17 contract mutants;
- path seal: `21/21`, output absent;
- all three Python files compile;
- frozen V5 sources and seal remain byte-for-byte exact;
- no Wolfram kernel or native solver was launched while building V5b.

The staged gate is presently blocked only by the intentional live K146
reservation described above, not by a V5b defect.

