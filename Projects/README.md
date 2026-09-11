# Calculation projects

Start with [WORKFLOW.md](../WORKFLOW.md) for execution directions and
[STATUS.md](../STATUS.md) for accepted results and current limits.

```text
Projects/PROJECT/
  card.wl
  LO/CHANNEL/Cards/Born.wl
  LO/CHANNEL/Results/Result.wl
  NLO/CHANNEL/Cards/{Real,Virtual,Counterterm}.wl
  NLO/CHANNEL/Results/Result.wl
  NNLO/CHANNEL/{Cards,Results,Kira}/...
```

Counterterm cards declare lower-order dependencies and required epsilon ranges.
See [the card/result contract](../Design/ProjectCardsAndResults.md) for path
resolution, inheritance and common result format. General algorithms belong
in FeynFacet; reference coefficients are validation inputs, never production
formulas.

## Project selection

The table inventories retained NLO Result.wl files on this installation.
It is not by itself a verification report; use the selected project guide
for the physical channel, polarization, reference availability and scope.

| Project | Polarization | Retained NLO result channels |
|---|---|---|
| [ppHX_UU_NNLO](ppHX_UU_NNLO/README.md) | Unpolarized | qg-qg, qqbar-qpqpbar, qqp-qqp, u-g_g-u |
| [ppHX_LL_NLO](ppHX_LL_NLO/README.md) | Both incoming longitudinal | qg-qg, qqbar-qpqpbar, qqp-qqp, u-g_g-u |
| [ppHX_TT_NLO](ppHX_TT_NLO/README.md) | Both incoming transverse | qqp-qqp |
| [ppHX_LL_SpinTransfer_NLO](ppHX_LL_SpinTransfer_NLO/README.md) | Incoming A to observed quark, longitudinal | qqp-qqp |
| [ppHX_TT_SpinTransfer_NLO](ppHX_TT_SpinTransfer_NLO/README.md) | Incoming A to observed quark, transverse | qqp-qqp |
| [DrellYan_UU_NLO](DrellYan_UU_NLO/README.md) | Unpolarized | g-q, g-qbar, q-g, q-qbar, qbar-g, qbar-q |
| [SIDIS_UU_NNLO](SIDIS_UU_NNLO/README.md) | Unpolarized | g-q, g-qbar, q-g, q-q, qbar-g, qbar-qbar |
| [SIDIS_LL_NNLO](SIDIS_LL_NNLO/README.md) | Longitudinal; unpolarized FF | g-q, g-qbar, q-g, q-q, qbar-g, qbar-qbar |

## NNLO

- [ppHX UU qq' -> qq' workflow](ppHX_UU_NNLO/NNLO/qqp-qqp/README.md):
  current two-gluon double-real contribution with ghost subtraction,
  explicit higher endpoint distributions and an executable replay map.
  The remaining NNLO cuts and counterterms are outside that result.
- [SIDIS UU](SIDIS_UU_NNLO/NNLO/README.md) and
  [SIDIS LL](SIDIS_LL_NNLO/NNLO/README.md): 13 complete electromagnetic channels
  each, including real/virtual, UV and PDF/FF terms and the LL finite
  helicity-scheme conversion, with independent NNLO comparisons.

Existing NNLO final-assembly replays reuse solved physical profiles. A fresh
arbitrary-process NNLO calculation still needs supported integral, DE and
physical-boundary specifications; do not interpret retained result presence
as a universal one-card execution guarantee.

All current output stays with the owning project/order/channel. Dated
dependencies can remain current when explicitly bound by accepted requests.
Archive/ProjectLayouts and other retired paths are historical.
