# Mathematica add-ons

This directory vendors third-party Wolfram Language packages used by FACET.
`LoadAddons.wl` defines explicit repository-relative entry points, adds their
directories to `$Path`, and sets `$FeynArtsDirectory`. Upstream source is
unchanged except for AMFlow's
site-specific `ibp_interface/Kira/install.m`, which points to FACET-local
Kira and Fermat executables.

For a calculation that needs FeynHelpers, configure it before loading
FeynCalc:

```wl
Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/LoadAddons.wl"];
$LoadAddOns = {"FeynHelpers", "FeynCalcLegacy"};
FACETLoadAddon["FeynCalc"];
```

Load other packages by name, for example

```wl
FACETLoadAddon["SubTropica"];
```

This explicit loader prevents a user-level paclet with the same context from
silently taking precedence over the FACET copy.

`Addon/Load/LoadFACET.wl` loads FeynFacet with the required FeynCalcLegacy add-on.
Versions and source locations are recorded in `MANIFEST.md`.
