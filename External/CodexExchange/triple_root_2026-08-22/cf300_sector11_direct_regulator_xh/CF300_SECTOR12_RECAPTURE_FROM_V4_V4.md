# CF300 sector-12 isolated recapture V4

V4 supersedes V3, which is **not launchable**.  The V3 dirty-worker gate did
not cover the complete source-derived Global write set, could not prove exact
message payloads, and could return a package-loaded worker to KernelPool.

V4 is a source-pinned launcher/private-body design with a separate no-write
K146 probe.  Before any output write, the launcher runs a read-only virgin
preflight built from the 637-name conservative driver census.  It rejects any
existing driver Global name, relevant package name or `$Packages` entry, and
all FeynCalc/FeynArts/FeynFacet/FeynHelpers/FeynCalcLegacy/CANONICA basename
shadows.  The probe and launcher explicitly use `System`Names`,
`System`Remove`, `System`FileHash`, `System`ToExpression`, and the other
critical introspection heads; this is required by the live K24 observation
that unqualified `Names` resolves to `FeynCalc`Names` on a preloaded worker.

The private body parses the driver in
`CodexCF300Sector12DriverV4`` with only `System`` on `$ContextPath`, while an
`Internal`InheritedBlock` localizes the full explicit Global artifact/basis
set and the System context/package/path lifecycle.  `FACET_MEMTRACE` is
explicitly unset and restored.  A package-load-attempt seal is atomically
written, rehashed, and independently rehydrated before driver evaluation.
The clean-basis contract is zero raw messages and an empty byte-exact message
transcript.  The only accepted driver exit is the intentional
`{"EXIT",75}`.  The output must remain the sector-11 V4 state and contain the
exact fresh sector-12/lower-11 strip SHA-256
`f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976`
at 15,667 bytes, with no checkpoint or temporary file.

After package load, no outcome returns a worker to the pool immediately.
Durable PASS writes the result and pre-quarantine marker and then remains in a
same-evaluation 30-second heartbeat loop.  Success, post-load failure, and
escaped-Abort quarantine loops all validate integrity *before* accepting an
inert plain-text release token.  Their integrity sets include the launcher,
body, driver, source manifest, KernelPool source, pool-run definition,
preflight, census/inspector, path seal/inspector, validator evidence, formal
result, V4 state/report, output hashes, exact Global namespace/definitions,
environment, argv, directory, and exact inventory.  A failed integrity gate
holds fail-closed even if a release file exists.

The deterministic Python path seal has 21 passing lstat/realpath records.  It
rejects symlinked sources/components and requires the V4 output to be absent
under `lexists`, thereby also rejecting a dangling output link.  The static
test independently regenerates that result and exercises regular and dangling
symlink mutants.

## Frozen sources

- launcher `run_cf300_sector12_recapture_from_v4_xh_v4.wls`
  - SHA-256 `8c033f6cee92e0b01b2e5b31ff45cdde1a20afb3706b1fd092f3cb93ff54197c`
- private body `run_cf300_sector12_recapture_from_v4_xh_v4_body.wls`
  - SHA-256 `51f489e78ec5ea5f277b7b1c8b0ef18f2853d9d62795ce6a5327a2384caf9cc7`
- read-only preflight `preflight_cf300_sector12_recapture_v4_global_state.wls`
  - SHA-256 `91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5`
- no-write K146 probe `probe_cf300_sector12_recapture_v4_virgin_k146.wls`
  - SHA-256 `b3edd4eed9e3dcfb81ca4188325c01585791f128f1996ba572d5616fcf9ab44a`
- path inspector `inspect_cf300_sector12_recapture_v4_paths.py`
  - SHA-256 `c6bfcee4603e5d2b0248a5dc8c02320f7a1d3fac3f4075e6f869d634caa6a0cd`
- path-seal result `cf300_sector12_recapture_v4_path_seal.json`
  - SHA-256 `6f326c92c6f9948f0fcb4c10f8e1052da446ac4ea9a5baf3cc71d177f690e44e`
- static/adversarial audit
  `test_cf300_sector12_recapture_from_v4_xh_v4_static.py`
  - SHA-256 `94f59cf5a86269f0e5bd5b951a74838ae1858533c588bcaad9404d36cd52fdf4`
  - result `PASS 171/171`; all three Python sources compile

The fixed output directory
`/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v4`
was absent under `lexists` at freeze time.

## Required central launch order

First run the read-only probe while K146 is the only dispatchable virgin
worker.  Dispatch to any other kernel fails closed and performs no output
write:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  probe_cf300_s12_recapture_v4_virgin_k146_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/probe_cf300_sector12_recapture_v4_virgin_k146.wls
```

Require pool status `OK`, result `0`, no pool-level messages, actual kernel
146, preflight `GateQ=True`, exact outer lifecycle/namespace restoration,
dedicated-name cleanup, and continued V4-output absence.

Only after that pass, submit the launcher with no script arguments and helper
ceiling zero:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_recapture_from_v4_xh_v4 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector12_recapture_from_v4_xh_v4.wls
```

A successful production mission is intentionally still `RUNNING`.  Acceptance
requires the durable result
`CF300_sector12_recapture_result_v4.wl`, the durable
`CF300_prequarantine_pass_v4.wl`, a
`CF300 S12 RECAPTURE V4 PRE-QUARANTINE PASS` log record, the pinned strip
hash/size, and subsequent heartbeats with `IntegrityQ=True`.  Do not write any
release sentinel while the pool is expected to continue serving work.  At a
planned clean pool restart, use the exact plain-text success token and
sentinel declared in the durable result; the body rechecks integrity before
acknowledging it.  Failure/Abort releases are separate and similarly
integrity-gated.

