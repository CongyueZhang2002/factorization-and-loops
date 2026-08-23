# Package bug report: multiquadratic rows bypass regulator factorization

Date: 2026-08-22

Scope: report and exchange-only fix design. No package file was changed.

Package snapshot inspected:

- `Scripts/family_epsform_sector.wls`
- SHA-256: `1f4276cfcfd1ada45439e0a089ed88c0044785774315ce6a4684d742f59001e4`

## P1 correctness bug

### Summary

The finite-field-first sector driver factors regulator dependence in completed
truncations only when `! algebraicFrameQ`. A family whose global coefficient
frame is multiquadratic therefore skips the pre-row, post-row, and final
regulator-factorization stages even when the roots occurring in the completed
truncation are rationalizable in a catalogued subchart.

This leaves `AlreadyDLog` blocks with residues that still depend on `eps`.
Those blocks are then used as the diagonal and intermediate forcing data for
the next row. The resulting strip problem can be intrinsically inconsistent;
enlarging its finite-field ansatz cannot repair it.

The exact final checker prevents a false certificate, but the solver spends
substantial time on an invalid recursively constructed problem and may report
an apparent obstruction.

### Affected control flow

In the inspected snapshot of `Scripts/family_epsform_sector.wls`:

- line 462: the pre-row `factorTruncated[k - 1]` call is guarded by
  `! algebraicFrameQ`;
- line 729: the post-row `factorTruncated[k]` call has the same guard;
- line 742: the family-level factorization is also disabled for an algebraic
  frame;
- the checkpoint invalidation at lines 463--466 is consequently never reached
  for a multiquadratic family whose completed connection has just been
  regulator-factored in a rational subchart.

The problematic tests are the global-frame test `algebraicFrameQ`. The correct
test is local: which roots occur in the completed truncation, and whether that
root set has a rational chart.

### Reproduction: CF300 before sector 8

The completed rows 1--7 of CF300 have dimension 11 and use only root index
`{1}`. They are rational in `Kallen2`, despite CF300 as a whole having a
multiquadratic identity frame.

Evidence is under `cf300_first_strip_probe/`:

- `CF300_rows1to7_Kallen2_regulator_factor.wl`
  - `RootIndices -> {1}`;
  - `ChartRational -> True`;
  - `BeforeEpsFactored -> False`;
  - factor status `OK` by `ExactRationalSamples` with 2 points;
  - `SourceFrameEpsFactored -> True` after applying the resulting constant
    `T(eps)` back in the identity frame.
- `CF300_8_5_residue_compatibility.wl`
  - the old, unfactored `(8,5)` input fails exactly at `SolveResidues` in about
    20.9 seconds.
- The negative-control probes in the same directory show the defect remains
  one equation after increasing numerator support, using the full alphabet as
  gauge denominator, and adding parent-strip constants.
- After the rows 1--7 factor was applied to a copied state and sector 8 was
  restarted, `(8,5)` solved and passed its exact check by
  `RationalChart/Kallen2/SimultaneousFiniteFieldAffinePDE`; sector 8 was then
  completed and checkpointed under `cf300_factorized_restart_probe/`.

Thus the old `(8,5)` failure was caused upstream by skipped regulator
factorization, not by the finite-field support, sampling, or triple-root
arithmetic.

## Required fix

Do not merely remove `! algebraicFrameQ`: the existing
`factorTruncated[m]` passes identity-frame entries directly to
`FactorFamilyRegulatorDependence`, whose current path expects rational
functions.

Replace the global-frame gate with a dispatcher conceptually of the form
`factorCompletedTruncation[m]`:

1. Extract the current completed `1..m` connection from `state["A"]`.
2. If it is already epsilon-factored, return `False` without changing state.
3. Classify the roots actually present in that truncation.
4. If no roots occur, use the existing rational `factorTruncated` path.
5. If the roots have a catalogued rational chart, pull the truncated one-form
   to the smallest such chart, including its Jacobian and branch convention.
6. Verify exact rationality in that chart, then run
   `FactorFamilyRegulatorDependence` there.
7. Accept the result only if `T` and `TInverse` are independent of both chart
   variables, are exact inverses, and conjugating the original identity-frame
   truncation makes both components epsilon-factored exactly.
8. Embed the constant matrices into the full state and update `A`, `S`, and
   `SInverse` with the existing sparse regulator helpers.
9. Record the chart, root set, factor method, points, and exact source-frame
   checks in `RegulatorFactorizations`.
10. If state changed, delete the current row's strip checkpoint before loading
    or constructing any strip in that row.
11. If all roots in the completed truncation have no joint rational chart,
    return a typed `NeedsMultiquadraticRegulatorFactorization` result and stop
    before constructing the next row. Do not silently continue with
    regulator-dependent residues.

The dispatcher should be called:

- before row `k`, for completed rows `1..k-1`;
- immediately after completing row `k`;
- at family completion if the connection is still not epsilon-factored.

The pre-row call must occur before `aTrunc` is built and before a partial strip
checkpoint is adopted.

## Regression tests

1. CF300 rows 1--7: detect `{1}`, select `Kallen2`, reproduce the 2-point
   factor, and prove the source-frame truncation epsilon-factored exactly.
2. CF300 sector 8: discard a deliberately installed stale `(8,*)` checkpoint,
   solve `(8,5)`, and complete the sector with exact strip and sector checks.
3. Resume test: applying the same completed-truncation factor twice must be
   idempotent; the second call returns no state change.
4. Rational-family control: current rational finite-field-first behavior and
   checkpoint schema remain unchanged.
5. Genuine rank-3 control: when no joint chart exists, assert the typed stop
   rather than constructing a strip from unfactored parents.
6. For every accepted factor, require exact `T.TInverse == I`,
   `TInverse.T == I`, and exact epsilon factorization in the source frame.

## P2 performance defect in the same branch

The algebraic branch also forces CANONICA full-truncation equation assembly and
full-matrix row composition because several choices are gated by
`! algebraicFrameQ` (notably around the current lines 530, 660, 666, and 673).
The row-gauge formulas already implemented in `blockEquation` and
`applyRowGaugeBlockwise` are identities over any characteristic-zero
coefficient field; they do not require rational coefficients.

The exchange-only
`family_epsform_sector_triple_root_candidate_v3.wls` introduces
`blockwiseRouteQ` and uses those formulas for the targeted algebraic
finite-field route. This avoids the observed multi-minute full truncated
matrix materialization. Treat v3 as a patch prototype: it still needs an
end-to-end exact comparison on a completed algebraic-family checkpoint before
package integration.

## Relevant exchange artifacts

- `codex_cf300_triple_root_progress_2026-08-22.md`
- `cf300_first_strip_probe/CF300_rows1to7_Kallen2_regulator_factor.wl`
- `cf300_first_strip_probe/CF300_8_5_residue_compatibility.wl`
- `cf300_first_strip_probe/` negative-control probes
- `cf300_factorized_restart_probe/`
- `factor_truncation_in_chart.wls`
- `apply_truncation_factor_to_state.wls`
- `family_epsform_sector_triple_root_candidate_v3.wls`

