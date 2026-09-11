# ppHX_TT_NLO

Execution and CPU policy: [WORKFLOW.md](../../WORKFLOW.md).
Available retained channels: [project index](../README.md).

Shared physics: [card.wl](card.wl). Orders precede channels.
The NLO channel has [Real](NLO/qqp-qqp/Cards/Real.wl),
[Virtual](NLO/qqp-qqp/Cards/Virtual.wl), and
[Counterterm](NLO/qqp-qqp/Cards/Counterterm.wl) cards.

Run from the repository:
`wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_TT_NLO qqp-qqp all`

Read `NLO/qqp-qqp/Results/Result.wl` with `ReadPartonicResult`.
LO results use the same format and retain coefficients through epsilon^1.
See [the card and result contract](../../Design/ProjectCardsAndResults.md).

A complete independent finite TT literature comparison has not been
established. Retained internal checks must be reported separately from such
a comparison.
