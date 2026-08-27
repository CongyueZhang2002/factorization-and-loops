# CF259 Q4 rank-three transfer gate V2

Prepared statically on 2026-08-23 after V1 completed its mathematics but
failed its success-cardinality check. No V1 source, output, log, status, or
pool wrapper was edited or removed. No Wolfram/native process or mission was
launched while preparing V2.

## Exact V1 diagnosis and preserved evidence

V1 ran on K145 in 8.744 seconds with no messages. Every executed runtime
assertion passed, but there were eleven assertion sites while `allPassed`
required `Length[checks]===12`. V1 correctly wrote a failed result and returned
`$Failed`; this was a bookkeeping defect, not a mathematical failure.

Frozen V1 runtime evidence:

* pool wrapper:
  `b6ff194e5f0bf5ffe7317f21732cc6a26fdbb99d427419bcb2db670ef218bf63`
* pool status:
  `37589830daadc68849cf907ab1ee17f0565644727889a5602b76baf9e6988ec4`
* log:
  `1d05e92f130743fff78b2b0b50ac7cc5cc31a0f9a18ac5b1f17854754252dce8`
* result:
  `a4a3bfb9f62b15197a2cfd81599bcee30c76523a0c75833bca23583596ebc198`

The result records 11/11 true checks, preparation rank three with 25 unknowns,
rank/nullity `25/0`, exact characteristic-zero residual zero, all eight unseen
sign branches verified, the Q4 corruption rejected, K145, and zero nested
kernels. Preserve it as terminal V1 evidence; do not overwrite or relabel it.

## Genuine twelfth assertion

V2 keeps all eleven mathematical checks and adds

```
canonical_cf259_root_order_abi_is_pinned_and_mutation_rejected
```

This is not count padding. It pins the exact canonical root fingerprints
observed and certified by V1 for CF259's `{lambda1,lambda3,Q4}` channel-mask
ABI, confirms source indices `{1,2,3}` and the same fingerprints inside the
recomputed ABI payload, then reverses the stored root fingerprints. The
mutant must fail both `TRPreparationABIValidQ` and
`TRPreparationABICompatibleQ`. This checks that stale or reordered root
metadata cannot silently reuse a preparation.

V2 also requires runtime assertion names to be duplicate-free and records
`RuntimeAssertionCountExpected -> 12` and
`RuntimeAssertionNamesUnique -> True` in its result.

## Static/adversarial gate

Run:

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf259_q4_rank3_oracle_2026-08-23_xh/test_cf259_q4_rank3_oracle_v2_static.py
```

Current result: **105/105 PASS**. In addition to syntax, source, process-control,
K145-before-I/O, fresh-output, and 24-point finite-field checks, V2's verifier:

* extracts all literal runtime `assert["name",...]` sites;
* requires exactly 12 unique names;
* proves that the extracted count equals both the `allPassed` count and the
  recorded result count;
* rejects a missing assertion, a duplicate name, a stale success count, and a
  stale recorded count;
* pins every V1 runtime artifact and confirms its eleven true results; and
* statically requires the exact root-order fingerprints and both negative ABI
  checks inside the new assertion.

This closes the defect class that allowed V1's hardcoded count to drift from
the executable assertion sites.

## Dispatch and launch

V2 remains hard-bound to **K145** before every target-level
`FileHash`/`Import`/`FileExistsQ` call. It requires zero Wolfram helpers,
zero nested kernels, and zero native/FLINT workers. A wrong assignment,
including K146, fails before target-level I/O. `kpsubmit.sh` supplies the held
parse of V2 itself; V2 then source-loads all four pinned semantic files on
K145.

Submit only when K145 is the worker central scheduling makes available and
K146 remains occupied/reserved by its recapture gate:

```bash
cd /home/maxzhang/factorization-and-loops
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf259_q4_rank3_oracle_xh_v2 \
  External/CodexExchange/triple_root_2026-08-22/cf259_q4_rank3_oracle_2026-08-23_xh/run_cf259_q4_rank3_oracle_xh_v2.wls
```

Fresh V2 output:

```
/tmp/codex-triple-root-20260823c.vx654S/cf259_q4_rank3_oracle_xh_v2.wl
```

Acceptance requires pool status `OK`, K145, no messages, result status
`CF259Q4Rank3OraclePassedV2`, 12/12 unique true assertions, root-order mutant
`ABIValid -> False` and `ABICompatibleWithOriginal -> False`, rank/nullity
`25/0`, exact residual zero, and all eight unseen-prime branch summaries.

## Frozen V2 hashes

* V2 driver:
  `1812ee54af7c9f560484935a0f9fabe351874ec4fd5c8c0b34a66be95730a538`
* V2 static/adversarial verifier:
  `1da2bc79f06550ba6bf0f4cf7122b615c9a94672c42898d99242ff17c57a43a3`
* Shared oracle:
  `b431db4737dab33329eeea709d9999990522e0925a26c9974d14faa3b2512d71`
* Shared source manifest:
  `dc64dfb52af72dcb387a0c4fdfaf83fa9a6b8de8d85fbad9e2a297bf5c88b271`
