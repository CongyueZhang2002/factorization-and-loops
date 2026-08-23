# CF300 sector-12 recapture V5: K146 dirty-worker recovery

V5 is an adjacent, K146-only recovery bundle.  It does not modify or weaken the
frozen V4 bundle.  V4 remains the preferred launcher on a virgin worker; V5 is
for the observed K146 state only.

## Why V5 is safe for this recapture

The failed V4 probe was read-only and showed a known package-loaded state, not
corruption.  V5 expands the inherited Global set by `root`, `ranges`, `t0`,
`variables`, and `dD`; all five are cleared only inside
`Internal\`InheritedBlock` and their complete definitions are required to
restore exactly.  Any other definition-bearing source candidate or package
shadow rejects before output.

FeynCalc/FeynArts are not treated as equivalent merely because their package
names exist.  The no-write probe requires:

- K146, zero nested kernels, helper ceiling zero;
- the exact observed 1,685-name relevant package definition set;
- exact relevant `$Packages` set `{CANONICA`, FeynFacet`, FeynArts`,
  FeynCalc`}`;
- FeynCalc 10.2.1 and FeynArts 3.12 (27 Mar 2025);
- pinned entry-point SHA-256 values;
- a stable SHA-256 fingerprint over every relevant package symbol's own,
  down, up, sub, numeric, default, format, attribute, message, and option
  definitions;
- exact read-only restoration of every pre-existing Global definition and the
  complete System context/package/path lifecycle;
- no output-directory creation and no messages.

The probe prints one unwrapped line
`CF300_V5_DIRTY_K146_PACKAGE_FINGERPRINT_SHA256=<64hex>`.  Production requires
that exact fingerprint as its only argument and recomputes it both in the
launcher and in the body before any output write.  This closes the gap between
the no-write observation and production dispatch.  FeynFacet is then cleared
and reloaded from the pinned source by `LoadFACET.wl`; CANONICA is forcibly
re-`Get` by the driver.  Acceptance finally requires the exact known
sector-12/lower-11 strip (SHA-256
`f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976`,
15,667 bytes), exact reconstruction identity, unchanged certified V4 state,
zero driver messages, source immutability, and a stable post-driver package
definition fingerprint.  Thus V5 proves the package equivalence actually
needed by this recapture; it does not claim universal equivalence of every
possible FeynCalc/FeynArts computation.

Every post-load result remains in the same-evaluation cooperative quarantine.
K146 is never advertised reusable.  No process is killed, restarted, or
signalled.

## Frozen files

- `run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146.wls`
- `run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146_body.wls`
- `preflight_cf300_sector12_recapture_v5_dirty_k146_global_state.wls`
- `probe_cf300_sector12_recapture_v5_dirty_k146_k146.wls`
- `inspect_cf300_sector12_recapture_v5_dirty_k146_paths.py`
- `cf300_sector12_recapture_v5_dirty_k146_path_seal.json`
- `test_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146_static.py`
- `test_cf300_sector12_v5_dirty_k146_adversarial.py`

The immutable hashes are in
`CF300_SECTOR12_RECAPTURE_FROM_V4_V5_DIRTY_K146_SHA256SUMS`.

No-kernel validation at freeze time:

- static audit: `PASS 183/183`;
- adversarial audit: `PASS 99/99`, including nine contract mutants;
- path seal: 21/21, output absent;
- all Python files compile;
- all four frozen V4 source hashes remain exact.

## Exact central sequence

Run only when K146 is the sole dispatchable target.  Dispatch elsewhere fails
closed and writes no output.

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/probe_cf300_sector12_recapture_v5_dirty_k146_k146.wls
```

Require normal pool status `OK`, result `0`, no messages, actual kernel 146,
`GateQ=True`, both Global read-only gates true, package fingerprint stable,
versions and entry hashes exact, dedicated cleanup true, and V5 output absent.

Read the single marker line from:

```text
/tmp/codex-triple-root-20260823c.vx654S/pool/logs/probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.log
```

Set `cf300_v5_fingerprint` to only its 64 lowercase hexadecimal characters,
then submit:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_recapture_from_v4_xh_v5_dirty_k146 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146.wls \
  "$cf300_v5_fingerprint"
```

Do not submit production if the marker is absent, duplicated, wrapped,
non-hexadecimal, or if any intervening mission ran on K146.  In the last case,
rerun the no-write probe and use only its new fingerprint.

Successful production intentionally stays `RUNNING`.  Accept only after the
durable result
`CF300_sector12_recapture_result_v5_dirty_k146.wl`, durable marker
`CF300_prequarantine_pass_v5_dirty_k146.wl`, the
`PRE-QUARANTINE PASS` log record, exact strip hash/size, and subsequent
heartbeats with `IntegrityQ=True`.  Do not write a release sentinel during the
active pool campaign.
