# External validation inputs

Production does not read this directory. The repository includes our comparison
code and compact validation results; original attachments and downloaded
third-party source files remain local.

To reproduce the qq-prime incoming-LL comparison, place the original user-supplied Werner
Vogelsang file `p1_p-fromfor (1).m` in this directory, unchanged. The accompanying
`coefficients (1).pdf` is documentation, not executable validation input. Their
conventions and discrepancies are recorded in `../Notes/ReferenceInventory.md`.

For UU, download [INCNLO 1.4](https://lapth.cnrs.fr/PHOX_FAMILY/src_inc/inc1_4.tar.gz)
from the [authors' site](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html).
Extract its `inc1_4` directory under `INCNLO/`; the reference driver requires
`INCNLO/inc1_4/hadlib/src/hadlib.f` and `cdel.f`. A working `gfortran` compiler
is required. Our wrapper compiles the original routines in a temporary directory
and writes only the eight comparison points to process Results/Validation.

After generating the three NLO results, run from the repository:

```sh
wolframscript -file Scripts/Validation/check_nlo_qqprime_references.wls ppHX_UU_NNLO ppHX_LL_NLO ppHX_TT_NLO
```

The TT nonzero control is regenerated automatically. FeynCalc/FeynArts and the
usual local framework dependencies are required as documented in the root README.

For full UU/LL qg coefficients, the independent reference is
[Navis](https://github.com/QCDLab/navis), pinned to commit
`89dab06673c4b6d2a142236d5d0109642cfc3b57` under `Navis/`.
`Source.json` lists the unchanged downloaded files, and the upstream MIT license
is retained. The reference wrapper compiles its original two `mes.rs` files
directly with `rustc`; it needs no PDF, FF or Monte Carlo installation.

```sh
wolframscript -file Scripts/Validation/check_nlo_navis_references.wls ppHX_UU_NNLO ppHX_LL_NLO
```

All 320 finite comparisons pass, including both polarized qg observed tags.
This establishes agreement with public Navis, not direct authentication against
an original author-distributed archive. [Details and scope](../../../Projects/ppHX_LL_NLO/NLO/qg-qg/Results/Validation/ExternalReferenceAvailability.md).
