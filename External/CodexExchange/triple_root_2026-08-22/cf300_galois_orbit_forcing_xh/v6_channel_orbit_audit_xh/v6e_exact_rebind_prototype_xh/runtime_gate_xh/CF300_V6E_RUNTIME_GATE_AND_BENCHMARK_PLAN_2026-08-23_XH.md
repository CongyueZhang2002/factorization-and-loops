# CF300 sector 12 V6e runtime gate and same-input benchmark

Date: 2026-08-23

## Disposition

This adjacent V6e source set is frozen after a successful centralized held
parse on the designated persistent worker K24. The runtime correctness and
benchmark mission has not been launched by this author, so this report makes
no speedup or runtime-correctness claim.

No package source, V6d source, pool file, process, or artifact outside
`runtime_gate_xh` was modified while building the source set. No Wolfram
kernel, process, pool mission, or subkernel was launched by this author.

## Frozen source hashes

- runtime driver:
  `2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884`
- held-parse gate:
  `05a8298243012f915b3b91bb57ea6512115f7a6e6943c43c140416b534918f6d`
- runtime static suite:
  `2bd02f896597e517eb50fd30a2b1cc89dbfe8370e8d65fa6c0b5c8d64ebbb262`
- runtime adversarial suite:
  `1b4c99a11d75b56b3b60951083f6ffdc7d0f5fef200fd7d561c2306ba7589e84`

Consumed exact-lift sources were explicitly declared immutable by their
owner and are pinned as follows:

- prerequisite schema:
  `909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45`
- exact-Q(eps) consumer helper:
  `e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b`

V6d remains byte-for-byte at core hash
`7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed`
and driver hash
`921422ec0f78c8a56a707fb487115d0b0a5debe6b84e5257e0d3df638e43988d`.

## Dispatch and isolation contract

Both Wolfram entry points fail before argument parsing or source I/O unless:

- ``System`$KernelID === 24``;
- dynamically scoped
  ``KernelPoolMission`$TaskBrokerMaxHelpers === 0``; and
- ``System`Kernels[] === {}``.

The wrapper-scoped value is the authoritative helper ceiling for persistent
pool workers. ``System`$KernelCount`` is outer-pool telemetry, not a nested
kernel count. Successful artifacts record the expected and actual dispatch
kernel, task-broker helper ceiling, outer-pool count, nested-kernel count, and
the entry `Kernels[]` value. The current `kpsubmit.sh` wrapper source is
`138315a11149c14fc3491a008e6e7ad4d23623d29a2228fbdea31d4384707ddc`.

This K24 guard preserves K146 for the separate V4 mission. A wrong-worker
dispatch exits 69 before source reads or output writes.

## Held-parse gate

`held_parse_cf300_sector12_v6e_runtime_gate_xh.wls` pins and held-parses all
seven full-mode sources: the runtime driver, V6e helper, integration reference,
V6d orbit core, V6 correctness-oracle helper, exact-lift schema, and exact-lift
consumer helper. Each record requires:

- full `HoldComplete` parsing;
- `SyntaxLength[parseText] == StringLength[parseText]`;
- zero parser messages;
- exact before/after SHA256 equality; and
- exact disposal of its temporary parse namespace.

It rejects a stale output and writes its result by fresh temporary file plus
non-overwriting atomic rename. The source also supports an independently
runnable `core-only` mode, but the acceptance run used full mode.

The final centralized full-mode parse passed on K24:

- artifact:
  `/tmp/codex-triple-root-20260823c.vx654S/v6e_runtime_gate_held_parse_final_xh_v4.wl`
- artifact SHA256:
  `4b20582bc1a0230441aaae85954d182dae8e61bb190957a77d329745e43c8cb9`
- status: `CF300Sector12V6eHeldParseGatePassedXH`
- pool result: OK, result 0, no messages, wall time `1.6634 s`
- dispatch: K24, task-broker max helpers 0, outer pool 8, nested 0
- parse records: 7/7 passed with exact before/after hashes.

Two earlier attempts are failures only, not acceptance evidence: v1 correctly
rejected the shell-environment/$KernelCount model on a persistent subkernel;
v2 found a real split-context-symbol lexical truncation in the runtime driver.
The final static suite forbids every code line ending in an ASCII context mark,
and the adversarial suite contains the exact split-symbol mutant.

## Runtime correctness before performance

`run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls` has two
independent modes. Core-only mode takes four or five arguments. Full capture
mode takes six or seven arguments and additionally emits the exact-lift
prerequisite. Both modes run these correctness gates before performance:

1. Hydrate the pinned preparation and compiled cache in a dedicated artifact
   context, with normalized qualified-name, exact-context, symbol-identity,
   and definition-free cleanup audits.
2. Build the frozen V6d orbit basis and maximal 108-letter target once.
3. Run the frozen V6 exact-channel rebind as the correctness oracle.
4. Run exactly two V6e trials on the same immutable
   `{baseAssembly,maxPreparation,additionalRecords}` input.
5. Strip only version-specific diagnostics/seal fields and require exact
   `SameQ` semantic identity to the V6 oracle.
6. Require each fresh seal to validate and consume exactly `{True,False}`;
   require exact raw/unique/reuse/compile conservation, zero collisions,
   exactly one passing legacy oracle, no fallback, no failure/missing value,
   stable inputs, and stable source hashes.
   Each stripped trial preserves non-secret seal status, UUID nonce, SHA256
   seal fingerprint, and fresh/replay booleans. Both UUIDs and fingerprints
   must be correctly shaped and distinct across the two trials.
7. Rerun all four deterministic V6d finite-field image certificates. Every
   image must recover dimensions 960 by 912, coefficient/augmented ranks
   888/889, coefficient nullity 24, inconsistency, the frozen accepted-point
   fingerprint, and all complete pivot/free/independent-row arrays and
   fingerprints. The four recovered plans must be identical.

Only after correctness passes is performance accepted. The median of the two
same-input V6e outer rebind times must be strictly below the frozen V6d rebind
time `485.843061 s`. Correct-but-not-faster writes status
`CF300Sector12V6eCorrectButPerformanceAcceptanceNotMetXH` and exits 3.

Every V6e phase retains time and memory telemetry. The final artifact also
records census time/memory, oracle time/memory, both trial records, median,
speedup factor, four finite-field results, source hashes, dispatch state, and
output-size policy.

## Full exact-lift prerequisite capture

Full mode emits a second fresh atomic artifact with status
`CF300V6dExactLiftPrerequisiteV1`. It contains:

- pinned V6d artifact/core/maximal-assembly provenance;
- `MaximalAssembly`;
- ordered 30 I00 residue pairs and frozen fingerprint;
- deterministic balanced rational lifts, using denominator search 1 through
  100 and lexicographic tie break
  `{Max[Abs[a],b],Abs[a]+b,b,a}`;
- all 60 ordered coordinate reduction records and reduction/invertibility,
  distinctness, modular nonsingularity, and plan-revalidation flags;
- full coefficient and augmented pivot/free/independent-row arrays and their
  frozen fingerprints; and
- eps=1/21 I00 plan and full-residual revalidation.

The frozen public consumer `EQWPrerequisiteValidQ` must accept the complete
artifact before it is written. The capture explicitly does not claim exact
Q(eps) nonsingularity; that remains a consumer-side proof.

Both outputs have a 1 GiB in-memory and on-disk ceiling, fresh-target policy,
abort/failure temporary cleanup, non-overwriting rename, reread equality, and
post-write source-stability/rollback checks. A final namespace-cleanup failure
rolls back both outputs.

## Exact full-run command and arguments

The two output paths below were confirmed absent at freeze time. Recheck their
absence immediately before submission. Submit only when the broker's next
dispatch is K24; the driver deliberately fails on any other worker.

```bash
test ! -e /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl
test ! -e /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl

POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_v6e_correctness_same_input_full_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/runtime_gate_xh/run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6e_correctness_same_input_benchmark_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_v6d_exact_lift_prerequisite_xh_v1.wl \
  2
```

The ordered runtime argument vector is:

1. project root;
2. pinned preparation, SHA256 `6d8d3e59...52ae5d4`;
3. pinned compiled cache, SHA256 `0f85d336...e0440be`;
4. frozen V6d artifact, SHA256 `20823fde...5aeb1cf`;
5. fresh benchmark output;
6. fresh exact-lift prerequisite output; and
7. native FLINT threads `2`.

This source launches no Wolfram helpers. The final integer controls only
native FLINT threads and is validated in the range 1 through 8.

## Validation evidence

- runtime static suite: 89/89;
- runtime adversarial suite: 118/118;
- frozen V6e helper static suite: 65/65;
- frozen V6e helper adversarial suite: 57/57 plus 800 randomized memo
  fixtures; and
- final centralized Wolfram held parse: 7/7 source records passed on K24.

The benchmark/full-capture mission remains intentionally unrun at freeze time.
