# Third-party Mathematica packages

| Package | Version | Copied from |
| --- | --- | --- |
| FeynCalc | 10.2.1 | Working Linux reverse-unitarity tool tree |
| FeynHelpers | 2.0.0 | `FeynCalc/AddOns/FeynHelpers` |
| FeynCalcLegacy | bundled | `FeynCalc/AddOns/FeynCalcLegacy` |
| FeynArts | 3.12 | Windows FeynCalc package backup |
| Package-X | 2.1.1 | Windows Mathematica package backup |
| SubTropica | 1.2.9 | Linux Wolfram paclet repository |
| Libra | 1.2 | Linux FACET-NLO add-on store |
| HPL | 2.0 | Linux FACET-NLO add-on store |
| PolyLogTools | 1.4 | Linux FACET-NLO add-on store |
| CANONICA | source snapshot | Local differential-equation probe |
| AMFlow | source snapshot | Local AMFlow checkout |

The files are copied for a reproducible local environment. They retain their
upstream notices. Redistribution rights must be audited package by package
before a public FACET release.
- **Fermatica** — github.com/rnlg/Fermatica @ abfd433 (2025-02-21), cloned 2026-08-17. Mathematica interface to Fermat (fer64 in Other_Addon/Fermat). Consumer: Libra Fuchsify/FactorOut UseFermat->True for completing family eps-forms of the two-root families (dim >= 18 FactorOut wall). License: see repo; review before redistribution.
- **RationalizeRoots** — github.com/marcobesier/rationalizeroots (GPL-3), cloned 2026-08-17. Rationalization of square roots (Besier-Wasser-Weinzierl 1910.13251). Consumer: triple-root families CF259/CF300/CF303 (phase 3 feasibility: joint rationalization of three quadratics; genus test companion). License GPL-3: review before redistribution.
- **FLINT** (system library, `libflint-dev` 3.0.1, LGPL-2.1+, SONAME libflint.so.18) — used since 2026-08-21 by the finite-field strip solver's optional modular-solve backend (`FeynFacet/Backends/flint/flint_modular_solve.c`, built by `build.sh` into the gitignored `bin/`; `SampleEpsFormStripAffine` option `"Backend" -> "FLINT"`, automatic fallback to the Wolfram solver when the binary is absent or any check fails). Adapter source: Codex round-2 A4 prototype, unchanged; every FLINT solution is re-verified in Wolfram (all-row residuals). Authorization: the standing package rule (worthy math package, recorded here); Codex's measurement 13.4 s -> 0.56 s on the (9,7) 2144-square core at 4 threads.
