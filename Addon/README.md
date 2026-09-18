# Local dependencies

[Load/LoadFACET.wl](Load/LoadFACET.wl) loads the configured FeynCalc/FeynArts
dependencies and the FeynFacet package. Local paths are declared in
[Load/Paths.wl](Load/Paths.wl).
[Mathematica_Addon](Mathematica_Addon/README.md) documents the explicit add-on
loader; its [manifest](Mathematica_Addon/MANIFEST.md) records versions.

Vendor packages and native executables are local installations, not generated
physics results. The WSL Other_Addon symlink targets the frozen ~/FACET tree;
do not edit or recursively clean through it. Setup and native build instructions
are in [WORKFLOW.md](../WORKFLOW.md).
