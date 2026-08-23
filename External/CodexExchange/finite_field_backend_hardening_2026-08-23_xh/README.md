# Finite-field backend hardening (External-only candidate)

This directory is an xhigh, source-pinned hardening proposal.  Nothing here
has been applied to `FeynFacet/` or `Scripts/`, and no Wolfram kernel was
started while preparing it.

Pinned working-tree inputs:

- `FeynFacet/Private/FiniteFieldStripSolve.wl`:
  `c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671`
- `FeynFacet/Private/FamilyRowGaugeResume.wl`:
  `e9719e551fcd1930dfbce478a25880d7393a9b6ab3dcf1d2a9672cf0bf4c5dde`
- `Scripts/family_epsform_sector.wls`:
  `60cc272a0b28da47d670984f401286f4ec29854b6216b7f36580bcde43e4a660`
- `FeynFacet/Private/TransportCharts.wl`:
  `c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a`

The proposal is split deliberately:

1. `01_backend_and_plan_hardening.patch` makes backend selection exhaustive,
   makes explicit FLINT requests fail closed, records attempted/used/fallback
   telemetry, and seals elimination plans with a strict versioned schema.
2. `02_solver_failure_and_resume_binding.patch` persists a bounded typed
   failure summary and binds checkpoint replay to a sealed
   `SolverConfiguration`, with only the safe historical rational-chart and
   zero-forcing legacy exceptions.
3. `run_finite_field_backend_plan_adversarial.wls` and
   `run_solver_configuration_resume_adversarial.wls` are post-integration
   dynamic tests.  They intentionally run no parallel kernels.
4. `test_hardening_candidates_static.sh` is the no-kernel source/patch gate.

Apply only after all source-pinned CF300 discriminator missions have ended.
The two patches touch currently dirty/untracked package work, so rebase them
against Fable's final versions rather than using a blind three-way apply.
