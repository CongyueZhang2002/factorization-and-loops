# Static audit record

Date: 2026-08-19

This record was prepared without starting a Wolfram kernel.  At the time of
inspection, the standardized CF254 continuation and the independent CF231
calculation occupied the two active master-kernel slots.

## Files inspected

- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Pairs/F19_C26.wl`
- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Pairs/F19_C36.wl`
- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF254.wl`
- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF265.wl`
- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/NNLOInventoryAudit/ExactBlockEquivalenceCatalogue.wl`
- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/NNLOInventoryAudit/FamilyDifferentialBlockEquivalence.wl`
- `/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819/family_epsform_CF254.wl`
- `/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819/family_epsform_CF265.wl`

## Static findings

1. The loop momenta, external momenta, massless kinematic rules, first seven
   denominators, cut momenta, and cut orientations are identical.
2. CF254 denominator 8 is CF265 denominator 9.
3. CF254 denominator 9 is an auxiliary scalar-product denominator; every
   CF254 master has zero ninth power.
4. CF265 denominator 8 is an additional ordinary propagator.  Nine CF265
   masters carry this enlarged-family information and have no CF254 image.
5. The 23 source power vectors map one-to-one into the 32-entry CF265 basis at
   positions
   `{29,4,5,6,7,9,10,12,13,14,16,17,18,19,20,21,22,24,25,28,30,31,32}`.
6. Both family records contain the same `Kallen13` chart.  Static extraction
   gives exact textual equality for the chart variables, source variables,
   substitutions, Jacobian matrix, and both rationalized roots.
7. The existing block catalogues independently identify the source coefficient
   master and its mapped CF265 master, with identical direct kinematic map.
8. A brace-aware static parser extracted both complete rational connection
   matrices.  After applying the 23-entry permutation, all 529 entries of each
   CF254 matrix are textually identical to the corresponding CF265 entries.
   Every entry in both `23 x 9` complementary coupling blocks is the literal
   integer zero.  Thus the two exact matrix identities and the closure condition
   are already visible in the stored analytic records, before simplification by
   a Wolfram kernel.

## Remaining executed check

When one Wolfram master-kernel slot is demonstrably free, run

```bash
wolframscript -file check_and_build_transfer_cf254_to_cf265.wls
```

The script performs exact rational checks of the two differential matrices and
their closure on the 23-dimensional mapped sector.  It writes the transfer
record only after every identity is zero exactly.
