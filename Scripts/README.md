# Script layout

General production and operational entry points remain directly under
`Scripts/` so established commands and automation keep stable paths. More
specialized material is grouped by purpose:

- `Diagnostics/`: benchmarks, probes, ledgers, and read-only campaign analysis.
- `HardClasses/`: historical hard-class derivations and reproducibility drivers.
- `Libra/`: specialized Libra and earlier two-root research tooling.

## Production entry points

- Full epsilon-form completion: `complete_family_epsforms.sh`
- Family campaign and worker: `family_epsform_campaign.sh`,
  `family_epsform_sector.wls`, `family_epsform.wls`
- Certification: `certify_family_epsform_campaign.wls`,
  `certify_family_epsform_parallel.wls`, `certify_family_epsform_record.wls`
- Observable and master transport: `complete_observable_transport.sh`,
  `observable_transport_campaign.sh`, `family_observable_transport.wls`,
  `complete_master_transport.sh`
- Shared persistent kernel pool: `KernelPool.wls`, `kpsubmit.sh`, `kpwait.sh`,
  `kpstatus.sh`, `watchdog_register.sh`
- Test pool: `run_tests_pool.sh`

The differential-equation builders, reconstruction pipeline, campaign launchers,
and small production utilities also stay at this level. `HardClassToolkit.wl`
and `EpsilonGraded.wl` remain here because both general and historical drivers
load them as shared source modules.

## Conventions

Categorized Wolfram scripts derive the repository root with
`DirectoryName[ExpandFileName[$InputFileName], 3]`. Top-level scripts use their
existing two-level ascent. Repository-internal callers and provenance strings
should name the categorized path explicitly.

New family-specific experiments belong in `Exchange/`; add a script here only
when it is reusable. Keep public production commands at `Scripts/` root. Move a
stable entry point only as a deliberate compatibility migration with all callers
and documentation updated in the same change.
