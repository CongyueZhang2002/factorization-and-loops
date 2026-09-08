# Artifact index

All original paths are under `/home/maxzhang/FACET`.  Compact copies are kept
in this documentation directory.  Multi-gigabyte expressions are not copied.

## Earlier written records

- `records/Hadronic_Coefficient_Simplification_original.md` copies
  `Codex/ppHX_NNLO_DoubleReal/HadronicSimplification/Hadronic_Coefficient_Simplification.md`.
  It is the contemporaneous 8 August narrative.  Its statement that 62.13 s
  is the total target-then-master time is corrected in the present report:
  62.13 s is the second stage, so the sequential total is 85.84 s.
- `records/SIMPLIFICATION_TEST_RECORD_2026-08-07.md` is a terminology-normalized copy of
  `Codex/ppHX_NNLO_DoubleReal/Validation/SIMPLIFICATION_TEST_RECORD_2026-08-07.md`.
  It records the earlier final-master and software comparisons.

## NLO UU records

- `records/NLO_UU_BenchmarkSummary.wl`:
  pair-first, target-first, master-first, target-then-master.
- `records/NLO_UU_ProductionSummary.wl`:
  complete 5 by 5 timing, master count, common factor, and exactness flag.
- `records/NLO_UU_FractionMonomialReport.wl`:
  Laurent valuation `{-1,-1,-2}` in `{xa,xb,zh}` for all seven 10 by 10
  master coefficients.
- `records/NLO_UU_NewNormalizationTest.wl`:
  33 certified physical-branch rules and the 283,144-byte result.
- `scripts/benchmark_algebra_strategies_uu.wls`
- `scripts/benchmark_largest_target_uu.wls`
- `scripts/test_target_factorization_uu.wls`
- `scripts/benchmark_factored_target_route_uu.wls`
- `scripts/benchmark_compact_strip_uu.wls`
- `scripts/benchmark_final_cleanup_uu.wls`
- `scripts/benchmark_signature_cleanup_uu.wls`

The larger result files `LargestTargetStrategies.wl`,
`TargetFactorizationTest.wl`, `FactoredTargetRoute.wl`,
`TargetDirectCleanup.wl`, `CompactStripVariants.wl`,
`FinalCleanupVariants.wl`, and `SignatureCleanupBenchmark.wl` remain in
`Codex/ppHX_NLO/HadronicSimplification/UU_10x10/`.

## NLO TT records

- `records/NLO_TT_TensorIdentitySummary.wl`:
  exact rank-one/rank-two and dimension-bookkeeping checks.
- `records/NLO_TT_TensorAbsorbSummary.wl`:
  tensor-reduction and absorption sizes.
- `records/NLO_TT_TargetBenchmarkGrid.wl`:
  target simplifier ordering grid.
- `scripts/test_dimensional_shift_tensor_identities.wls`
- `scripts/BenchmarkTargetGrid.wls`
- `scripts/BenchmarkTTHardAngular.wls`

The 750,504-byte TT result remains at
`Codex/ppHX_NLO/HadronicSimplification/TTOrdering/TTMasterCoefficients_01.wl`.

## NNLO 7 August records

- `records/NNLO_ExactNormalizerBenchmark_20260807.wl`
- `records/NNLO_Master_0008_TermwiseSimplifySummary.wl`
- `records/NNLO_WholeMasterSimplifyBenchmark_20260807.wl`
- `records/NNLO_SignatureGroupProfile_20260807.wl`
- `scripts/benchmark_exact_normalizers_20260807.wls`
- `scripts/benchmark_termwise_simplify_master_20260807.wls`
- `scripts/benchmark_whole_master_simplify_20260807.wls`
- `scripts/profile_signature_groups_20260807.wls`

The full post-IBP input and old output occupy 3,960,695,102 and
3,597,827,125 serialized bytes and remain in the original coefficient store.

## NNLO 8 August records

- `records/NNLO_EntryFirstInvariantCleanup_Manifest.wl`
- `records/NNLO_SizeMonotone_Manifest.wl`
- `records/NNLO_SizeMonotone_AuditCertificate.wl`
- `records/NNLO_Dimensionless_Manifest.wl`
- `records/NNLO_Dimensionless_AuditCertificate.wl`
- `records/NNLO_FactorInventory.wl`
- `scripts/NNLOFractionRing.wl`
- `scripts/NNLOInvariantRootRing.wl`
- `scripts/BenchmarkNNLOEntryFirstInvariantCleanup.wls`
- `scripts/AssembleNNLOSelectedMasterCoefficientsSizeMonotone.wls`
- `scripts/BenchmarkNNLODimensionlessNormalization.wls`
- `scripts/ConsolidateNNLODimensionlessCoefficients.wls`
- `scripts/CensusNNLODimensionlessDenominatorFactors.wls`

Large source and derived files remain under
`Codex/ppHX_NNLO_DoubleReal/HadronicSimplification/`.  Their hashes are stored
in the copied manifests and audit certificates.

## Card and package audit

- `records/UU_card_2026-08-08.wl` and `records/TT_card_2026-08-08.wl` are
  snapshots of the cards used for the hadronic substitutions.
- `records/Process_card_assumption_source.wl` copies the package source that
  infers `0 < xi < 1` and combines those inequalities with card assumptions.
