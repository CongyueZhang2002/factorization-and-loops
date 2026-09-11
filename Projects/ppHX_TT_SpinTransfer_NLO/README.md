# ppHX_TT_SpinTransfer_NLO

Execution and CPU policy: [WORKFLOW.md](../../WORKFLOW.md).
Available retained channels: [project index](../README.md).

NLO qq' -> observed q + X, incoming quark A to observed-quark spin transfer.
Polarization is declared once in [card.wl](card.wl):
`<|"Incoming" -> {"T", "U"}, "Observed" -> "T"|>`.

The common compiler derives the matching amplitude projectors, PDFs/FFs and
collinear kernels. Both qq' and qg Born results are required through epsilon^1.
The transverse result retains symbolic incoming and outgoing azimuths and spin
magnitudes; it is not restricted to one spin axis.

`wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_TT_SpinTransfer_NLO qqp-qqp all`

The output is `NLO/qqp-qqp/Results/Result.wl`. Its coefficient convention and
distribution basis are the same as in the other NLO projects.

A complete independent finite TT literature comparison has not been
established. Retained internal checks must be reported separately from such
a comparison.
