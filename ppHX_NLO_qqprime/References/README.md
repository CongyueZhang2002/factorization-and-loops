# External validation inputs

Production does not read this directory. The repository includes our comparison
code and compact validation results; original attachments and downloaded
third-party source files remain local.

To reproduce the LL comparison, place the original user-supplied Werner
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
wolframscript -file Scripts/Validation/check_nlo_qqprime_references.wls ppHX_NLO_qqprime
```

The TT nonzero control is regenerated automatically. FeynCalc/FeynArts and the
usual local framework dependencies are required as documented in the root README.
