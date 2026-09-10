# Calculation projects

Every active calculation lives here. Each project has one common `card.wl`,
then perturbative order, physical channel, contribution cards and results:

```text
Projects/<project>/
  card.wl
  LO/<channel>/Cards/Born.wl
  LO/<channel>/Results/Result.wl
  NLO/<channel>/Cards/{Real,Virtual,Counterterm}.wl
  NLO/<channel>/Results/Result.wl
  NNLO/<channel>/Cards/
  NNLO/<channel>/Results/
```

Each counterterm card explicitly names its lower-order result files and
required epsilon orders. Paths are relative to that card. Channel folders
also own reduction workspaces and validation records. Shared algorithms
belong in `FeynFacet/`, and literature comparisons in `External/References/`.

| Project | Polarization | Completed full NLO channels |
| --- | --- | --- |
| ppHX_UU_NNLO | Unpolarized | qqp-qqp, qqbar-qpqpbar, qg-qg |
| ppHX_LL_NLO | Both incoming longitudinal | qqp-qqp, qqbar-qpqpbar |
| ppHX_TT_NLO | Both incoming transverse | qqp-qqp |
| ppHX_LL_SpinTransfer_NLO | Incoming A to observed, longitudinal | qqp-qqp |
| ppHX_TT_SpinTransfer_NLO | Incoming A to observed, transverse | qqp-qqp |

The UU project also contains the NNLO double-real work. This is not a complete
NNLO hard function. See each project index for its current channel coverage.

From the repository root, name a project directly:
```sh
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_UU_NNLO qqp-qqp all
wolframscript -file Scripts/generate_born_density.wls ppHX_UU_NNLO qqp-qqp
```
The drivers resolve names under `Projects/`. Lower-level pair and reduction
drivers accept the full relative channel path, including `Projects/`.
Frozen historical calculations remain in `Archive/ProjectLayouts/` for
provenance and explicitly declared historical tests.

## Integrated SIDIS

The full electromagnetic SIDIS NNLO calculation is complete for UU and LL:
13 channels each, with all real, virtual, UV, PDF and FF contributions and
the finite LL helicity-scheme conversion. UU stores {2F1, FL/x}; LL stores
{2g1} with an unpolarized FF. Each channel uses the common result format.

- [UU final results](SIDIS_UU_NNLO/NNLO/README.md)
- [LL final results](SIDIS_LL_NNLO/NNLO/README.md)

All delta, plus and regular coefficients match the independent NNLO
references at five exact parameter points, including all four kinematic
regions, unequal scales and a second color/flavor/charge assignment.
Every negative epsilon coefficient was checked separately. The compressed
final Mathematica files total 5.18 MB and contain explicit standard functions,
with no unevaluated integrations or solution generators.

Both projects also retain their six complete NLO channels through epsilon
one and exact NLO literature checks. Shared production algorithms are in
FeynFacet; numerical reference comparisons remain outside production.
