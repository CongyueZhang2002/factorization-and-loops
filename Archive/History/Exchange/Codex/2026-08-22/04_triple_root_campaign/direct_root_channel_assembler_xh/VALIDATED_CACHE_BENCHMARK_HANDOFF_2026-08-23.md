# Validated-cache CF300 A0 benchmark handoff (2026-08-23)

## Outcome

The fair common-stream benchmark is now cached-only. It never calls
`DRCAPrepare`; a run must supply both a compiled-cache artifact and the passed
report from the pinned adversarial validator. The previous implicit uncached
path was removed, rather than retaining a mode that could silently include an
approximately eleven-minute compilation in performance results.

Before sampling, the driver independently performs a full artifact read and
validation and fails closed unless all of the following agree:

- the cache file path and SHA-256 in the prior validation report;
- the pinned validator source path and SHA-256;
- every adversarial-validation boolean, empty messages, and temporary-file
  cleanup;
- cache key and direct-assembly fingerprint;
- preparation file path/SHA-256 and preparation ABI fingerprint;
- root ordering, unknown count, and equations-per-point shape;
- recursive raw input and preparation-driver paths/SHA-256 values;
- pinned cache-builder, assembler, and artifact-helper sources;
- current dependency hashes and the cache builder's runtime-source record.

Cache read/full validation is timed separately. The report explicitly records
`"DirectCompilationPerformed" -> False`; warm direct, sign-transform, and
legacy timings retain their original like-for-like scopes and common point
stream.

The adversarial validator now records a versioned validation contract and its
own stable source path/SHA-256. Temporary-file cleanup is also part of the pass
predicate, not merely a diagnostic field.

## Run order and exact arguments

Run the validator first:

```text
run_direct_compile_cache_validate_adversarial.wls \
  <project-root> <compiled-cache.wl> <fresh-validation-report.wl>
```

Only after that report has passed, run the benchmark:

```text
run_cf300_sector12_a0_direct_common_stream_benchmark.wls \
  <project-root> <preparation.wl> <compiled-cache.wl> \
  <passed-validation-report.wl> <fresh-benchmark-output.wl>
```

Both output paths must be fresh. The benchmark requires the exact cache path
recorded by the validator report.

For the current overnight pool and CF300 sector-12 A0 cache, the exact proposed
submissions (after the cache builder is terminal and after adding each mission
to the watchdog watchlist) are:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  fresh_cf300_s12_a0_direct_compile_cache_validate_xh_v2 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/direct_root_channel_assembler_xh/run_direct_compile_cache_validate_adversarial.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_validation_xh_v2.wl

POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  fresh_cf300_s12_a0_direct_common_stream_cached_benchmark_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/direct_root_channel_assembler_xh/run_cf300_sector12_a0_direct_common_stream_benchmark.wls \
  /home/maxzhang/factorization-and-loops \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/rank2_cross_prime_v1_xh/CF300_12_9_rank2_preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_validation_xh_v2.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_common_stream_cached_benchmark_xh_v1.wl
```

## Staged source hashes

- `run_cf300_sector12_a0_direct_common_stream_benchmark.wls`:
  `59b4d8e972eaee2ef7174b1c5aa8ffab8915b82ec05bb50d39507c35ad34b191`
- `run_direct_compile_cache_validate_adversarial.wls`:
  `7565022c17c29c4b2c0f3e2661f6890db0ebb1ef1fc457623a8642f6e00d02d9`
- `test_cf300_sector12_direct_common_stream_benchmark_static.sh`:
  `703ffffa9c67afca364a9363070f470e68aa700d9cb745deee5c5c854e8dbd25`
- `test_direct_compile_cache_static.sh`:
  `c73f93916de00ef7135acc49b8ce69c64eed94a2ae0a1e046ef159e7fa2077c0`

## Static verification

- cached fair benchmark contract: 64 passes, 0 failures;
- compiled-cache/validator contract: 60 passes, 0 failures;
- Wolfram delimiter checks, shell syntax, trailing whitespace, and
  `git diff --check`: passed.

No Wolfram kernel was launched for this staging work. No package source or
running process was modified.

## Later support-rebind compatibility

The present V1 cache and validator deliberately do **not** authorize support
rebinding. `CompiledForms` and `ExactChannelForms` contain the equation-core,
one-form, root, and denominator primitives and are independent of
`GaugeSupport`, so their expensive compiled payload can in principle be reused.
However, `GaugeSupport` also enters `SourceABIFingerprint`, gauge/total unknown
counts, column ordering, the semantic payload, and `AssemblyFingerprint`.
Simply replacing the support inside a validated V1 artifact would therefore be
correctly rejected.

A safe later design is a source-bound derived-artifact V2 (or a dedicated
assembler-side `DRCARebindSupport` constructor) that:

1. fully validates both the parent V1 artifact and the enlarged source
   preparation;
2. proves equality of the support-independent record/root/one-form/denominator
   core and records the parent cache SHA-256, cache key, and compiled-forms
   fingerprints;
3. requires an ordered, duplicate-free support extension and explicitly
   remaps any normalization columns (the current A0 case has none);
4. recomputes gauge/total counts, column order, source ABI, semantic payload,
   assembly fingerprint, and cache key while reusing only the unchanged exact
   and compiled forms; and
5. receives its own adversarial validation report before any benchmark or
   solve consumes it.

This preserves the current fail-closed V1 attestation instead of weakening it
to accommodate a future optimization.
