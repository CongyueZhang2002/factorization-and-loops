# Family-neutral native postfix backend and CF259 end-to-end result

Date: 2026-09-02

## Outcome

The optimized 31-bit CPU evaluator is now exposed through a family-neutral C
ABI and Python backend.  A complete CF259 common-dlog calculation using that
backend, the existing FLINT RREF, and the existing FLINT multi-RHS solver
finished successfully with all 13 CRT primes and the same independent fresh
prime as the CUDA calculation.

The native run reported **10.030088 s** end to end.  The existing CUDA record
reports **20.515136946 s**, making the measured native workflow **2.045x
faster end to end** while limited to eight CPU threads.  The enclosing command,
including compilation of the shared library, took 10.79 s and peaked at
1,435,172 KiB RSS.

## Exact result comparison

The native and CUDA outputs have identical record keys.  Every field except
the deliberately backend-specific `Backend` and measured `Seconds` fields is
equal.  In particular:

- `Residues` is raw-text identical: 581,636 characters in each record.
- `Letters` is raw-text identical: 56,710 characters in each record.
- The 13-element `CRTPrimes` list is raw-text identical.
- `FreshValidationPrime` is identical: 2,147,482,943.
- Dimension 47, rank-3 sheet policy, point counts, coefficient field, identity
  method, replay flags, and all validity/provenance fields are identical.
- The reconstructed CRT modulus has 403 bits.

The output is `cf259_dlog_residues_native.wl`; the raw phase log is
`cf259_native_dlog_run.jsonl`.

## Timing breakdown

The run used CPUs 2–9 through `taskset`, eight native postfix threads, and four
FLINT threads.  Values below aggregate all 14 evaluated primes.

| Stage | Total (s) | Median per prime (s) | Observed range (s) |
|---|---:|---:|---:|
| Point/request construction | 0.065596 | 0.004402 | 0.003384–0.006969 |
| Montgomery constant/input preparation | 0.223690 | 0.016077 | 0.013183–0.017629 |
| Native connection evaluation | 7.038366 | 0.503770 | 0.495433–0.509869 |
| Native dlog evaluation | 0.008622 | 0.000470 | 0.000461–0.002113 |
| Design/RHS construction | 0.013676 | 0.000763 | 0.000610–0.002377 |
| FLINT RREF | 0.197701 | 0.013500 | 0.011108–0.018620 |
| FLINT multi-RHS solve | 0.070090 | 0.004967 | 0.004766–0.005585 |
| Existing pointwise replay | 0.491860 | 0.034642 | 0.032861–0.039399 |
| Rational reconstruction | 0.091009 | once | — |

The sum of per-prime wall times is 8.296385 s.  One-time overhead includes the
0.781307 s pickle load, 0.079530 s native packing/scheduling plan construction,
record writing, and exact comparison with the CUDA record.  Connection postfix
evaluation remains the dominant reusable stage.

## Reusable implementation

- `postfix_native.cpp` contains no family names or family data.  Its immutable
  plan holds neutral postfix programs and assembly metadata.  Each request
  supplies its prime, Montgomery constants and inputs, image/base counts, and
  root rank.  It implements all eight existing opcodes, general record/term
  assembly, and rank-0 through rank-3 Walsh channel canonicalization.
- `deferred_native.py` adapts the existing neutral `Programs` and `Request`
  structures to the C ABI.  It caches the packed execution plan across primes
  and reports preparation, expression, assembly, channel, and complete-call
  timings separately.
- `family_dlog_native.py` is family-neutral orchestration: cache and sidecar
  paths are arguments, as are the native library and FLINT executables.  It
  retains the established 13-prime CRT, independent fresh-prime, and pointwise
  replay workflow without adding certification stages.
- `run_cf259_native_dlog.sh` is the only new CF259-specific driver.  It builds
  the shared library in a temporary directory and supplies the CF259 fixture
  paths.  No compiled binary or large intermediate payload is retained.

No file under `FeynFacet/Private` was changed.
