# CF300 triple-root progress: the `(8,5)` blocker and the corrected route

Date: 2026-08-22

Scope: exchange-only investigation. No file under `FeynFacet/`, `Scripts/`,
or the installed package was modified.

## Result

CF300 `(8,5)` was not a finite-field performance failure and was not a
three-root block. It was an invalid recursive input caused by skipping the
truncated regulator factorization whenever the family coefficient frame is
multiquadratic.

After factoring the completed rows 1--7 in the targeted Kallen2 chart and
applying the resulting constant `T(eps)` back in the identity frame, `(8,5)`
solved exactly by

`RationalChart/Kallen2/SimultaneousFiniteFieldAffinePDE`

in about 84 seconds in the guarded restart. The same restart also regenerated
and exactly certified `(8,7)` and `(8,6)` before reaching `(8,5)`.

## Evidence that the old `(8,5)` record was intrinsically inconsistent

- Every default rectangular numerator support through offset `{3,3}` was
  inconsistent by exactly one equation.
- Adding every one-letter and every two-distinct-letter gauge pole from the
  nine-letter alphabet did not change the defect.
- Adding 71 extra letters extracted from Laurent coefficients did not change
  the defect.
- The complete product of all nine letters as gauge denominator, with
  numerator offsets through `{6,6}` (matrix up to `1072 x 1060`), still had
  `rank = 1056`, `augmented rank = 1057`, and nullity 4.
- Constants inherited from solved parent strips `(8,6)` (16 columns) and
  `(8,7)` (8 columns) added zero rank at every support.
- The exact pre-gauge residue system failed at stage `SolveResidues` in
  20.91 seconds. Thus no larger numerator could have repaired that record.

These checks rule out numerator degree, gauge denominator size, missing parent
integration constants, and modular sampling as explanations.

## Root cause

`Scripts/family_epsform_sector.wls` correctly calls `factorTruncated[m]` before
later rows and after a completed row for the ordinary rational
FiniteFieldFirst route. Both calls are guarded by `! algebraicFrameQ`.
Consequently, CF300 sectors 2--7 accumulated `AlreadyDLog` strips whose
residues still depended on `eps`, and sector 8 was constructed from that
unfactored lower connection.

The completed 11-dimensional rows 1--7 truncation has only root index `{1}`
and is fully rational in Kallen2. On that chart,
`FactorFamilyRegulatorDependence` found a transformation from two rational
sample points:

- chart rationality: exact `True`;
- before factorization: not epsilon-factored;
- factor status: `OK`, method `ExactRationalSamples`, points `2`;
- exact source-frame check after pulling the constant transformation back:
  `True`.

The transformation is diagonal and depends only on `eps`, so it is unchanged
by the chart pullback. The independently constructed exchange checkpoint also
passes the exact inverse identity and epsilon-factor test.

## Correct algorithmic ordering

For a multiquadratic family, before constructing row `k`:

1. Classify the roots present in the completed truncation `1..k-1`.
2. If that root set has a catalogued rational chart, pull the truncated
   connection to the smallest such chart.
3. Run `FactorFamilyRegulatorDependence` there.
4. Apply its variable-independent `T(eps)` and inverse directly to the full
   identity-frame state.
5. Discard any partial checkpoint for row `k`, then construct its strips.

Repeat after each completed row. This postpones multiquadratic extension-field
work until the completed truncation itself genuinely contains an unrationalized
three-root set.

## Performance add-on

The algebraic branch still composes a completed strip row through CANONICA's
full truncated matrices. An exchange-only v3 driver changes only this
composition step to the existing block-triangular formulas already used by
the rational FiniteFieldFirst route. Those formulas are field-independent, so
they apply unchanged to multiquadratic entries. This avoids the measured
multi-minute 15-by-15 composition after sector 8.

## Exchange artifacts

- `CF300_rows1to7_Kallen2_regulator_factor.wl`: exact factorization artifact.
- `factor_truncation_in_chart.wls`: targeted chart factor diagnostic.
- `apply_truncation_factor_to_state.wls`: guarded application to a copied
  checkpoint.
- `cf300_factorized_restart_probe/`: independent restart and modular artifacts.
- `family_epsform_sector_triple_root_candidate_v2.wls`: refreshed driver with
  targeted chart recognition-to-finite-field routing.
- `family_epsform_sector_triple_root_candidate_v3.wls`: v2 plus algebraic
  blockwise row composition.
- `CF300_8_5_residue_compatibility.wl`,
  `CF300_8_5_full_alphabet_denominator_probe.wl`, and parent-constant probes:
  negative controls documenting why the old record could not solve.

## Remaining three-root work

The actual rank-3 finite-field design remains the 8-channel multiquadratic
sampler: split points where all root squares are residues, eight sign
conjugates, and Walsh--Hadamard projection into the root basis. Arithmetic,
derivatives, split-point generation, conjugation homomorphism, and the
Hadamard round trip already pass the exchange harness. The corrected
factorization ordering should be applied first so that the first rank-3 record
is a valid epsilon-form problem rather than a propagated regulator artifact.
