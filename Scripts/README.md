# Script layout

General production and operational entry points remain directly under
`Scripts/` so established commands and automation keep stable paths. More
specialized material is grouped by purpose:

- `Diagnostics/`: benchmarks, probes, ledgers, and read-only campaign analysis.
- `HardClasses/`: historical hard-class derivations and reproducibility drivers.
- `Backup/retired_routes_2026-09-02/`: the CANONICA/Maple eps-form drivers, the August transport sweep and the Libra research tooling, retired with their routes (see its README).

## Production entry points

- V2 differential-equation stages:
  `DifferentialEquations/build_family_differential_system_v2.wls` constructs
  one explicit `FamilyDifferentialSystem`; then
  `DifferentialEquations/build_family_differential_system_block_decomposition_v2.wls`
  derives its strongly connected components and writes one validated
  `FamilyDifferentialSystemBlockDecomposition`. Both accept absolute or
  repository-root-relative mathematical input paths.
- Full epsilon-form completion: `complete_family_epsforms.sh`
- Family campaign and worker: `family_epsform_campaign.sh`,
  `family_epsform_pool.sh`, and `family_epsform_sector.wls`. The launchers
  take a tab-separated table whose columns are the family and explicit paths
  to its V2 `FamilyDifferentialSystem`, block decomposition, coefficient
  presentation, and directory of validated diagonal-block dlog epsilon forms.
  Paths may be absolute or repository-root-relative. The worker validates the
  completed family equation and writes `FamilyDLogEpsilonForm.wl`; it never
  discovers or translates the retired pre-V2 result tree.
- Standalone validation of an explicitly supplied working result and V2
  system remains available through `certify_family_epsform_record.wls`; the
  production worker already performs this validation before writing output.
- Observable and master transport: `complete_observable_transport.sh`
  (manifest + rounds; dispatches the standalone driver),
  `observable_transport_kernelpool_campaign.sh` (CANONICAL multi-family
  driver: one pool main + N subkernels, mission
  `family_observable_transport_pool_mission.wls`),
  `observable_transport_campaign.sh` (standalone: one wolframscript per
  family, no pool -- only when no KernelPool can run or for one family),
  `family_observable_transport.wls`, `complete_master_transport.sh`
  (eps-form completion followed by the observable transport; the name
  predates the retirement of the Libra `TransportFamily` route, which it
  never calls)
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
