# CF300 V4 post-launch read-only verifier

This verifier is separate from, and does not alter, the frozen V4 launch
manifest.  It performs only lstat/stat/read/hash operations.  It has no file
write/remove/rename calls, no subprocess or signal API, and no process-control
operation.  In particular, it can never create a release sentinel.

Run it immediately after the central K146 probe completes:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/verify_cf300_sector12_recapture_v4_postlaunch.py probe
```

The probe phase requires the mission to be filed `done`, pool status `OK`,
result `0`, `HadMessages=False`, exact kernel 146, helper ceiling zero, all
preflight/restoration/cleanup gates true, no Wolfram message signature, and
the V4 output still absent under `lexists`.

After production writes its durable PASS evidence and at least one complete
heartbeat, run:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/verify_cf300_sector12_recapture_v4_postlaunch.py production
```

The production phase revalidates the frozen V4 manifest and 17 direct runtime
pins, the historical probe evidence, and the live K146 running marker.  It
requires the exact eight-entry output inventory, one strip-only scratch entry,
no temporary/release/failure artifact, the unchanged V4 state and snapshot,
the exact 15,667-byte `f26c4cc3...a976` strip, an empty driver-message
transcript, internally consistent result/marker hashes, no FAIL/message/end
record in the active log, and a complete latest heartbeat with
`IntegrityQ=True` and every restoration/hash gate true.  Durable outputs are
rehash-checked at the end to reject read races.  The active log may receive a
new heartbeat; a read-time race fails closed and is safe to retry.

`auto` (the default) chooses `probe` while the V4 outdir is absent and
`production` after it exists.  A pass prints a single JSON object with
`"GateQ": true`; a failure prints a fail-closed JSON object and exits 1.

## Frozen verifier bundle

- `verify_cf300_sector12_recapture_v4_postlaunch.py`
  - SHA-256 `2bf558f8c9663ba167a5bf981b6c60e805a2c8e07992d59d5c03071a2f3460ef`
- `test_cf300_sector12_recapture_v4_postlaunch_verifier.py`
  - SHA-256 `ec4b1b8bb4aa2a0d9b29db1aa76ac1a7e8c0d7a3410c1e9d811ae8382abcfe94`
  - result `PASS 226/226`

The synthetic audit proves the good probe/production paths and rejects
`HadMessages=True`, a nonempty driver transcript, a mutated strip, a false
heartbeat-integrity bit, an unexpected release/inventory entry, a symlinked
read, and an explicit Wolfram message.  It also rechecks the original frozen
V4 manifest and all of its members.

