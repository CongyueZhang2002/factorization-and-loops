# Pro inquiry: finite-field evaluation of a pair-chart DAG containing a third root

Please review the actual current code, especially:

- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldDeferredInhomogeneity.wl`
- `FeynFacet/Backends/flint/flint_deferred_ast_eval.c`
- `FeynFacet/Private/EpsForm/OffDiagonalBlocks/OffDiagonalBasisTransformationBlock.wl`
- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldOffDiagonalBlockSolve.wl`

Concrete production case: CF259 off-diagonal block `(26,1)`.  Its deferred
preparation reports active roots `{1,3}` but denominator roots `{1,2,3}`.  The
selected pair parametrization rationalizes roots 1 and 3.  Exact symbolic
materialization shows that root 2 cancels after the terms of each matrix entry
are summed, but materialization cost 178.6 s and the subsequent chart projection
was still running after four minutes.  The native DAG request instead declared
only roots 1 and 3, so the C evaluator correctly encountered the undeclared root
2 in expression 34.  The symbolic fallback is now disabled after a native
refusal.

The proposed general finite-field route is:

1. Build the native plan with the complete square-root-generator set carried by
   the deferred preparation, while recording which roots the selected rational
   parametrization rationalizes.
2. Choose modular chart points at which every remaining root square is a
   quadratic residue; this costs about a factor of two per remaining root.
3. Evaluate the complete sign orbit and recover all multiquadratic grades.
4. Require every grade containing an unrationalized root to vanish for every
   returned matrix entry.  Only then contract the grades involving rationalized
   roots with their declared rational images and pass the resulting rational
   values to the existing interpolation/linear solver.
5. Make the line census and later residual checks draw enough split points
   rather than requiring a fixed unfiltered sequence to split.

Please assess the mathematical soundness of this projection, especially whether
vanishing of the unwanted grades pointwise at sufficiently many independent
modular points is the right statement that the exact summed entry lies in the
pair-chart rational subfield.  Then inspect the code and recommend the smallest
general implementation: where point filtering should live, how the full-root
and rationalized-root index maps should be represented, how to avoid biasing
interpolation by the split-point subset, and what minimal held-out test is
needed.  Please flag a materially simpler or faster route if one exists.  Do
not recommend returning to characteristic-zero `Together` materialization.
