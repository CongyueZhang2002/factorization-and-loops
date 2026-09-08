# Overnight endpoint and boundary evaluation, 2026-09-07

The authorized work is complete. The monitor is paused; no worker remains.
The original deadline was 2026-09-07 17:24:04 UTC. The CPU limit was eight cores.

All required physical boundary constants are determined and applied to the
91 saved solutions for 345 masters and 2,220 epsilon coefficients.
The final general reduction and its process reproduction input are in
ppHX_NNLO_DoubleReal/Results/BoundaryValues/OvernightEvaluation_2026-09-07.

Read [the completed report](PhysicalBoundaryResults_2026-09-07.md), STATUS.md and
the result directory README for the current method. run_state.json and
Validation contain the final audit and numerical evidence.

The public reader/evaluator uses Frobenius initialization automatically and
requires no constants for the completed solutions. Independent Euler and
nonzero hypergeometric comparisons pass. The subsequent CF198 AMFlow correction
also passes through epsilon^1: the old wrapper confused an absolute epsilon
upper power with the vendor offset from -2 L. Both interfaces are fixed; see
Results/Validation/AMFlowCF198_2026-09-07 in the process directory. The original
failed trial remains retained as provenance.

No further overnight computation is required. Broader remaining tasks are
general analytic continuation, complete endpoint/renormalization/PDF-factorization
orders and NNLO assembly. Preserve the original singular-matching provenance,
the user's dirty tree and the frozen read-only ~/FACET.
