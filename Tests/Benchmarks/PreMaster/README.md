# Pre-master performance diagnostics

`profile_pipeline.wls INPUT.wl OUTPUT_DIRECTORY` measures diagram pairs or
coefficient reconstruction in a fresh Wolfram kernel. Named times are
inclusive and overlap; use `ElapsedSeconds` for total duration. Inputs select
Mode Pairs (Project, Card, Pairs) or Coefficients (ReductionDirectory, Threads).
Always put outputs in the process Results/Validation directory. A fresh
coefficient test requires a distinct reduction workspace: reuse of an existing
normalization trace is a restart measurement, not a computational speedup.

`compare_pair_algebra.wls` compares closed-trace evaluation with the original
Calc algebra inside the same physical process scope and tests exact equality.
Its second timing can benefit from algebra caches; use a separate fresh
production profile to establish the actual end-to-end speedup.

`verify_optimization.wls` verifies the retained 2026-09-08 campaign outputs:
exact coefficient expressions, full NLO hard functions, hard NNLO pairs and
positive denominator support of stored selected masters. It requires those
process-owned validation artifacts and is not an ordinary unit test.

The small, self-contained regression tests are
`Core/t_phase_space_denominator_bounds.wls` and
`Core/t_prepared_process_diagrams.wls`, together with the closed-trace, coefficient-work-path and pre-master runtime tests in Core. See
[the mathematical scope](../../../Design/PhaseSpaceDenominatorSigns.md).
