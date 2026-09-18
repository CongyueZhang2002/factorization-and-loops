# ppHX_LL

Common physics: [Common-Card.wl](Common-Card.wl). Read the shared
[workflow](../../WORKFLOW.md) and [card contract](../../Design/ProjectCardsAndResults.md).

Each raw contribution owns its card, result and working files under
`Raw/ORDER/CHANNEL/CONTRIBUTION/`. Explicit result cards select the sum under
`Results/ORDER/CHANNEL/`. Counterterms regenerate their own source amplitudes;
standalone lower-order results are not inputs. A counterterm belongs to its
perturbative source channel, with names such as Counter-PDFB or Counter-FF.
Its explicit output components can be selected by result cards in other channels.
Raw may therefore include source channels for which no complete result was
requested. See the shared card contract for the OutputChannel selector.

## NLO channels

| Channel | Result selection | Coefficients |
|---|---|---|
| qg-qg | [Result_Card.wl](Results/NLO/qg-qg/Result_Card.wl) | [Results.wl](Results/NLO/qg-qg/Results.wl) |
| qqb-qpqpb | [Result_Card.wl](Results/NLO/qqb-qpqpb/Result_Card.wl) | [Results.wl](Results/NLO/qqb-qpqpb/Results.wl) |
| qqp-qqp | [Result_Card.wl](Results/NLO/qqp-qqp/Result_Card.wl) | [Results.wl](Results/NLO/qqp-qqp/Results.wl) |
| u-g_g-u | [Result_Card.wl](Results/NLO/u-g_g-u/Result_Card.wl) | [Results.wl](Results/NLO/u-g_g-u/Results.wl) |

Regeneration and verification status: [completed campaign](../../Reports/2026-09-13/NLO_SIDIS_NNLO_Run.md).
Only an existing accepted Results.wl with a completed run report establishes
completion. Timings distinguish the kernel calculation from supervised wall time.

Latest fresh regeneration: `qqp-qqp` completed in **3.57 min on eight CPUs**,
including kernel startup and cleanup. The current result passes 40/40 Navis
comparisons and exact pole cancellation. See the
[15 September optimization report](../../Reports/2026-09-15/PreMasterOptimization2.md).
Other channel results remain those accepted in the completed campaign.

## Result files

The former NLO runs and their archive copies have been deleted. New readable
Wolfram records have a `.meta.wxf` companion; keep it with the text for exact
machine reading. `Get["Results.wl"]` directly displays the mathematics.
Standalone LO cards request epsilon zero; counterterms generate their own
sources to the required order.
