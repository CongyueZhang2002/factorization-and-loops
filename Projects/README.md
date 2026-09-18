# Calculation projects

Use [WORKFLOW.md](../WORKFLOW.md) and the [card contract](../Design/ProjectCardsAndResults.md).

```text
Projects/PROJECT/
  Common-Card.wl
  Raw/ORDER/CHANNEL/CONTRIBUTION/{Card.wl, Results.wl, Work/}
  Results/ORDER/CHANNEL/{Result_Card.wl, Results.wl, RunReport.wl}
```

Physics project names identify process and polarization; orders belong inside Raw
and Results. Antiquarks use qb/qpb (explicit flavors ub/db). The former NLO outputs and their archived copies have been deleted.

The [fresh regeneration campaign](../Reports/2026-09-16/NNLOImprovementsAndRegeneration.md) covers these declared NLO channels:

| Project | NLO channels |
|---|---|
| [DrellYan_UU](DrellYan_UU/README.md) | g-q, g-qb, q-g, q-qb, qb-g, qb-q |
| [SIDIS_LL](SIDIS_LL/README.md) | g-q, g-qb, q-g, q-q, qb-g, qb-qb |
| [SIDIS_UU](SIDIS_UU/README.md) | g-q, g-qb, q-g, q-q, qb-g, qb-qb |
| [ppHX_LL](ppHX_LL/README.md) | qg-qg, qqb-qpqpb, qqp-qqp, u-g_g-u |
| [ppHX_LL_SpinTransfer](ppHX_LL_SpinTransfer/README.md) | qqp-qqp |
| [ppHX_TT](ppHX_TT/README.md) | qqp-qqp |
| [ppHX_TT_SpinTransfer](ppHX_TT_SpinTransfer/README.md) | qqp-qqp |
| [ppHX_UU](ppHX_UU/README.md) | qg-qg, qqb-qpqpb, qqp-qqp, u-g_g-u |

All prior NLO/NNLO output and saved masters were deleted on 16 September.
The fresh campaign rebuilds NLO for all listed projects and SIDIS UU/LL NNLO,
one project at a time. ppHX NNLO declarations remain, but that order is excluded
from regeneration. Follow [STATUS.md](../STATUS.md) and the dated campaign report
for actual completion; the older NNLO input trees no longer exist.
All 29 fresh NLO channels are now complete; see the
[one-page report](../Reports/2026-09-16/calculation_status.pdf) and
[completion record](../Reports/2026-09-16/NLOCompletion.md). All timing cells are
filled. SIDIS NNLO remains paused; the user requested stopping after NLO.

All real, virtual and counterterm raw results use the common partonic schema.
References are validation inputs, never production formulas.
Counterterms belong to their underlying perturbative source channel, and
result cards select the needed OutputChannel across raw channel directories.
For example Raw/NLO/qqp-qqp/Counter-PDFB can contribute to a qg-qg result.


Only physics projects belong in this directory. Status tables and accepted
campaign reports live in ../Reports/YYYY-MM-DD/. One-off run scripts and old
attempt logs are retained under ../Archive/Runs/.

## Energy correlators

[EE_EEC](EE_EEC/README.md) reproduces the full massless vector-current EEC through order alpha_s, including both angular endpoints. The six native-cut masters, generated virtual amplitude and exact reference/moment tests use the general quadratic-measurement workflow. Its Raw/NLO folder corresponds to conventional LO EEC.
