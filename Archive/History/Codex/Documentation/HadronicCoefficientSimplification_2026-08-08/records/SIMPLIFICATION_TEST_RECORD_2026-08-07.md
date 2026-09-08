# NNLO coefficient simplification test record

Date: 2026-08-07

## Scope

This record covers exact analytic simplification tests performed on the
`ppHX_NNLO_DoubleReal` UU calculation after Kira reduction. It records both
successful calculations and bounded failures. Numerical sampling was not used
to define any analytic result.

The current data set contains 44,877 Kira targets and 342 master integrals.
The serialized coefficients entering final-master simplification occupy
3,960,695,102 bytes. The currently stored final-master files occupy
3,597,827,125 bytes. Thus, the current all-master final sweep gives only a
1.101-fold reduction, or 9.2 percent. This is not considered a satisfactory
final method.

## Acceptance criteria

A simplification result is accepted as exact only when:

1. the calculation contains no inexact numerical data;
2. time limits return the original exact expression rather than a partial
   transformation;
3. branch-sensitive factors, BMHV structures, and causal information are not
   transformed by unproved identities;
4. where an explicit equality test was practical, the exact symbolic
   difference was verified to be zero;
5. the output is materially smaller than the input. A method that expands the
   expression is not accepted merely because it completes quickly.

## Main measured results

| Stage and method | Input bytes | Output bytes | Reduction | Runtime and resources | Exactness result |
|---|---:|---:|---:|---|---|
| 64 largest NNLO Kira target coefficients, termwise `Simplify` | 83,386,848 | 28,279,424 | 2.949-fold | 75.64 s, 4 kernels | exact symbolic data retained |
| NLO targets composed into masters before vs. after target-first simplification | 99,144,512 | 39,771,488 | 2.493-fold | target simplification 40.06 s | exact symbolic data retained |
| Largest isolated NNLO target, whole `Simplify` | 2,434,656 | 811,576 | 3.000-fold | 15.30 s | exact difference zero |
| Largest isolated NNLO target, termwise `Simplify` | 2,434,656 | 701,328 | 3.471-fold | 6.92 s | exact difference zero |
| Largest isolated NNLO target, `Cancel[Together[...]]` | 2,434,656 | 3,748,912 | expansion | 0.37 s | exact difference zero |
| Largest isolated NNLO target, `FactorTerms[Cancel[Together[...]]]` | 2,434,656 | 5,316,312 | expansion | 0.83 s | exact difference zero |
| Final master 8, termwise `Simplify` | 4,655,210 | 3,082,976 | 1.510-fold | 175.07 s, 8 kernels, 377 terms | exact symbolic data retained; no term timed out |
| Final master 1, rational/signature method | 1,607,146,927 | 920,945,177 | 1.745-fold | about 19.5 min | exact symbolic data retained |
| Final master 2, rational/signature method | 903,734,615 | 464,281,765 | 1.947-fold | about 15 min | exact symbolic data retained |
| Final master 4, isolated rational/signature test | 83,696,010 | 47,987,161 | 1.744-fold | 68.55 s | exact symbolic data retained |
| Current all-master final sweep | 3,960,695,102 | 3,597,827,125 | 1.101-fold | completed for 342 masters | exact symbolic data retained, but result is too weak |

The several-fold reductions occur at the Kira-target level, before target
contributions are assembled into final master coefficients. The Kira rule
application subsequently expands these coefficients. The useful target-level
reduction is already present in the stored workflow; it cannot be counted a
second time as final-master simplification.

## Whole-master `Simplify` test

Acceptance criterion: each job had to finish within 1,800 seconds and 4 GiB,
retain exact symbolic data, and serialize to a materially smaller result.

Masters 3 through 10 were run concurrently on eight kernels. Every job reached
the 1,800-second time bound and returned no transformed output. The input file
sizes ranged from 4,655,210 bytes to 129,816,704 bytes. In particular, even
master 8, whose input file was only 4.7 MB, did not finish as one
`Simplify[wholeMaster]` call. Aggregate peak memory was approximately 34 GiB.

This result does not prove that an unbounded calculation could never finish.
It establishes that unpartitioned whole-master `Simplify` is not a usable
production method under the tested resource bound.

Machine-readable result:

- `WholeMasterSimplifyBenchmark_20260807.wl`
- driver: `benchmark_whole_master_simplify_20260807.wls`
- log: `benchmark_whole_master_simplify_20260807.log`

## Termwise final-master `Simplify`

Master 8 was partitioned into its 377 additive terms and simplified dynamically
on eight kernels. All terms completed without the 300-second per-term fallback.
The exact output shrank from 4,655,210 to 3,082,976 bytes in 175.07 seconds.
The fast `Cancel`-based production result for the same master was 7,978,901
bytes, so that method expanded this master by 71 percent instead of reducing
it.

Artifacts:

- `Master_0008_TermwiseSimplifySummary.wl`
- `Master_0008_TermwiseSimplify.bin`
- driver: `benchmark_termwise_simplify_master_20260807.wls`
- log: `benchmark_termwise_simplify_master_20260807.log`

## Strict rational/signature grouping

The rational/signature method separates each additive term into a rational
coefficient and a held branch-sensitive signature. It permits exact rational
algebra only within identical signatures.

For master 4, a structural profile found 2,591 additive terms and 2,591 exact
signatures. No signature occurred with more than one denominator. Therefore,
the strict signature grammar exposes no cross-term merge for this master; its
reduction comes from rational normalization inside individual terms.

Artifact:

- `SignatureGroupProfile_20260807.wl`
- driver: `profile_signature_groups_20260807.wls`

For master 1, the completed module representation contained 24,050 entries.
Rehydration used 64 shards and produced a 920,945,095-byte expression from
921,800,785 bytes of module data. Rehydration itself therefore provides almost
no additional compression; the reduction occurred while normalizing the
rational portions.

Artifact:

- `rehydrate_signature_master_20260807.log`

## Other explored methods

### Global rational normalization

Monolithic `Together`/`Cancel` on master 4 did not finish within the
1,800-second bound. Small-target tests also showed that `Together`-based
normalization can expand serialized expressions by more than a factor of two,
despite preserving exact equality.

Drivers:

- `benchmark_master_rational_20260807.wls`
- `benchmark_master_term_methods_20260807.wls`
- `benchmark_master_term_cancel_full_20260807.wls`

### Chunked and signature-module experiments

Chunking bounded memory and made exact rational normalization possible on the
largest masters, but it did not by itself reveal enough equal signatures to
give an order-of-magnitude reduction. These tests motivated the current
rational/signature implementation but are not separate final results.

Relevant artifacts:

- `benchmark_master_chunked_20260807.wls`
- `benchmark_signature_modules_20260807.wls`
- `benchmark_signature_modules_20260807.log`
- `benchmark_signature_rational_merge_20260807.wls`
- `benchmark_signature_rational_merge_20260807.log`
- `benchmark_signature_denominator_buckets_20260807.wls`
- `benchmark_signature_denominator_buckets_20260807.log`
- `benchmark_global_signature_bucket_merge_20260807.wls`
- `benchmark_global_signature_bucket_merge_20260807.log`
- `benchmark_global_signature_bucket_merge_full_20260807.log`
- `benchmark_raw_record_signature_buckets_20260807.wls`
- `benchmark_raw_record_signature_buckets_20260807.log`
- `benchmark_raw_record_signature_buckets_full_20260807.log`
- `validate_raw_signature_buckets_20260807.wls`
- `validate_raw_signature_buckets_20260807.log`

### Symbolica preprocessing

On the tested large coefficient, direct Mathematica processing took 5.91 s and
produced 0.70 MB. Symbolica preprocessing followed by Mathematica took 12.16 s
and produced 0.81 MB, before including preprocessing overhead. It was therefore
not an improvement for this expression grammar.

Legacy logs are retained under:

- `../Scratch/Legacy_2026-08-06/mathematica_raw_master.log`
- `../Scratch/Legacy_2026-08-06/mathematica_symbolica_master.log`
- `../Scratch/Legacy_2026-08-06/mathematica_raw_master_termwise.log`
- `../Scratch/Legacy_2026-08-06/mathematica_symbolica_master_termwise.log`

## Target-level source records

The target-level measurements are retained in:

- `../Scratch/Legacy_2026-08-06/nnlo_target_profile.log`
- `../Scratch/Legacy_2026-08-06/nnlo_target_profile_summary.wl`
- `../Scratch/Legacy_2026-08-06/target_normalization_stages.log`
- `../Scratch/Legacy_2026-08-06/target_normalization_checkpoint.wl`
- `../Scratch/Legacy_2026-08-06/target_normalization_benchmark.log`
- `../Scratch/Legacy_2026-08-06/largest_target_normalizers.log`

The isolated exact normalizer comparison is retained locally as:

- `ExactNormalizerBenchmark_20260807.wl`
- driver: `benchmark_exact_normalizers_20260807.wls`

## Current conclusion

1. Target-level termwise `Simplify` is useful and gives approximately
   2.5-3.5-fold reduction on the measured inputs.
2. Whole-master `Simplify` is unusable under the tested 30-minute and 4-GiB
   per-job bound.
3. Termwise final-master `Simplify` is exact and can prevent the severe
expansions produced by the fast `Cancel` sweep, but the measured reduction
   was only 1.51-fold.
4. The best measured dense-master reduction is 1.947-fold. No tested
   final-master method has produced the desired several-fold or
   order-of-magnitude reduction.
5. The current 9.2-percent aggregate final sweep is retained only as an exact
   experimental artifact. It is rejected as the final production strategy.
6. Achieving order-of-magnitude compression likely requires preserving shared
   factored target/Kira structure or proving a broader branch-safe canonical
   grammar. It cannot be claimed from the completed tests.
