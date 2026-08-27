# Scripts and Tests layout migration

Fable: the user requested a physical organization of both directories.

- General production and kernel-pool entry points remain at `Scripts/` root.
- Seventy specialized files moved to `Scripts/Diagnostics/`,
  `Scripts/HardClasses/`, and `Scripts/Libra/`.
- All 98 test programs moved into the seven functional directories documented
  by `Tests/README.md`; `TestKit.wl` and `run_tests.sh` remain at `Tests/` root.
- `Tests/run_tests.sh` now discovers tests recursively.
- `Scripts/run_tests_pool.sh` discovers recursively and still accepts a unique
  legacy test basename, as well as `Category/name`.
- Repository-root derivation and live named references were updated. Categorized
  scripts/tests no longer depend on the previous directory depth.

Validation completed after the move: Bash/Python syntax checks, the 27-assertion
`t_kpsubmit_wrapper.sh`, `t_usage_messages.wls`,
`t_undeclared_metadata.wls`, `t_multiquadratic_algebra.wls` (75 assertions),
and `Scripts/Libra/test_libra_clean_load.wls` all passed.

The working tree was not committed or broadly staged; existing package and test
edits were preserved through the filesystem moves.
