# ppHX UU

Shared physics: [card.wl](card.wl). Orders precede channels.

- [NNLO qq' -> qq' workflow](NNLO/qqp-qqp/README.md): accepted two-gluon
  double-real contribution with ghost subtraction, current artifacts and replay.
- NLO qq' -> qq': [Real](NLO/qqp-qqp/Cards/Real.wl),
  [Virtual](NLO/qqp-qqp/Cards/Virtual.wl),
  [Counterterm](NLO/qqp-qqp/Cards/Counterterm.wl).

From the repository root, use the bounded execution instructions in
[WORKFLOW.md](../../WORKFLOW.md). The NLO entry point is:

```bash
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_UU_NNLO qqp-qqp all
```

Read [NLO/qqp-qqp/Results/Result.wl](NLO/qqp-qqp/Results/Result.wl) with
ReadPartonicResult. LO results use the same format and retain the epsilon
orders declared by their cards. See [cards and results](../../Design/ProjectCardsAndResults.md).
