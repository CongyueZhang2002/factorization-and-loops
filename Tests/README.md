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
