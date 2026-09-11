# ppHX_LL_SpinTransfer_NLO

Execution and CPU policy: [WORKFLOW.md](../../WORKFLOW.md).
Available retained channels: [project index](../README.md).

NLO qq' -> observed q + X, incoming quark A to observed-quark spin transfer.
Polarization is declared once in [card.wl](card.wl):
`<|"Incoming" -> {"L", "U"}, "Observed" -> "L"|>`.

The common compiler derives the matching amplitude projectors, PDFs/FFs and
collinear kernels. Both qq' and qg Born results are required through epsilon^1.
The spin assignment is longitudinal incoming-to-observed transfer; it is
distinct from the project with both incoming quarks longitudinally polarized.

`wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_LL_SpinTransfer_NLO qqp-qqp all`

The output is `NLO/qqp-qqp/Results/Result.wl`. Its coefficient convention and
distribution basis are the same as in the other NLO projects.
