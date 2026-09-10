# ppHX_UU_NNLO

Shared physics: [card.wl](card.wl). Orders precede channels.
The NLO channel has [Real](NLO/qqp-qqp/Cards/Real.wl),
[Virtual](NLO/qqp-qqp/Cards/Virtual.wl), and
[Counterterm](NLO/qqp-qqp/Cards/Counterterm.wl) cards.

Run from the repository:
`wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_UU_NNLO qqp-qqp all`

Read `NLO/qqp-qqp/Results/Result.wl` with `ReadPartonicResult`.
LO results use the same format and retain coefficients through epsilon^1.
See [the card and result contract](../Design/ProjectCardsAndResults.md).
