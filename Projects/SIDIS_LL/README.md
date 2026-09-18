> **2026-09-16 regeneration:** Previous generated NLO/NNLO outputs and saved
> masters were deleted. Historical paths below are not current inputs.
> See the repository STATUS.md and Reports/2026-09-16/FreshRegeneration.
> ppHX NNLO is excluded from this regeneration campaign.

# SIDIS_LL

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
| g-q | [Result_Card.wl](Results/NLO/g-q/Result_Card.wl) | [Results.wl](Results/NLO/g-q/Results.wl) |
| g-qb | [Result_Card.wl](Results/NLO/g-qb/Result_Card.wl) | [Results.wl](Results/NLO/g-qb/Results.wl) |
| q-g | [Result_Card.wl](Results/NLO/q-g/Result_Card.wl) | [Results.wl](Results/NLO/q-g/Results.wl) |
| q-q | [Result_Card.wl](Results/NLO/q-q/Result_Card.wl) | [Results.wl](Results/NLO/q-q/Results.wl) |
| qb-g | [Result_Card.wl](Results/NLO/qb-g/Result_Card.wl) | [Results.wl](Results/NLO/qb-g/Results.wl) |
| qb-qb | [Result_Card.wl](Results/NLO/qb-qb/Result_Card.wl) | [Results.wl](Results/NLO/qb-qb/Results.wl) |

Current regeneration and verification status:
[September 16 campaign](../../Reports/2026-09-16/NNLOImprovementsAndRegeneration.md).
Only an existing accepted Results.wl with a completed run report establishes
completion. Timings include supervised startup and cleanup.

## NNLO channels

Thirteen NNLO channel result cards are declared. All earlier upstream masters,
endpoint profiles and assembled outputs were deleted on 16 September.
The fresh producer builds diagrams, integral families, shared IBP reduction,
DEs, physical boundaries, explicit master solutions and endpoint profiles
before assembling these cards. Progress is recorded in
[RemainingCampaign.json](../../Reports/2026-09-16/FreshRegeneration/RemainingCampaign.json).
A declared card or a historical reference comparison does not establish
completion of this fresh calculation.

## Result files

The former NLO runs and their archive copies have been deleted. New readable
Wolfram records have a `.meta.wxf` companion; keep it with the text for exact
machine reading. `Get["Results.wl"]` directly displays the mathematics.
Standalone LO cards request epsilon zero; counterterms generate their own
sources to the required order.
