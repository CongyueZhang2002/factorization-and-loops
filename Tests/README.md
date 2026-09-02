# Test layout

Tests are grouped by the subsystem whose public behavior they protect:

- `Core/`: package loading, metadata, naming, generality, and basic invariants.
- `EpsilonForm/`: canonicalization, family epsilon forms, regulators, and row gauges.
- `FiniteField/`: modular sampling, reconstruction, and finite-field backends.
- `Infrastructure/`: schedulers, brokers, kernel-pool wrappers, budgets, and traps.
- `Multiquadratic/`: radical algebra, charts, letters, construction, and algebraic solvers.
- `Reconstruction/`: coefficient assembly, NLO golden data, and reconstruction parsers.
- `Transport/`: blockwise, chart, master, and observable transport.

`TestKit.wl` and `run_tests.sh` stay at this level as shared infrastructure.
`run_tests.sh` discovers every categorized `t_*.wls` and `t_*.sh` recursively.
`Scripts/run_tests_pool.sh` discovers Wolfram tests recursively and still accepts
an individual test by its unique basename, for example
`t_multiquadratic_algebra`, or by `Category/name`.

Overhaul 2026-09-02: package modules live in layer subfolders of
`FeynFacet/Private/` (manifest `FeynFacet/Private/LoadOrder.wl`); a test that
reads a module file directly names the layer in the path. Tests that only
exercised code retired to `FeynFacet/Private_Backup/` moved with it to
`FeynFacet/Private_Backup/Tests/` and are not part of the batch.
`Scripts/run_tests_pool.sh` runs the batch in reuse mode (`REUSE=1`, the
recommended mode) and runs kernel-launching tests standalone.
