# Source-rebased integration suite: deferred propagation and finite-field hardening

Date: 2026-08-23 (America/Los_Angeles)

This directory is an External-only, xhigh integration proposal against the
current dirty working tree.  No package source was edited, no Wolfram or
Mathematica kernel was launched, and no process was signalled.  The direct
root-channel assembler/performance work is deliberately outside this lane.

## Verdict

The three production changes can be merged in the order below after all
source-pinned missions are terminal.  The older finite-field `.patch` files
are design templates, not executable patches; these replacements use the
workspace `apply_patch` grammar and were applied sequentially to a temporary
mirror without context failure.

The current preimages still match the earlier pins, so there is no unresolved
source conflict at the time of this report.  The targets are dirty/untracked
Fable work, however.  If any preimage hash changes, stop and rebase; do not
use fuzzy application or guess across the changed source.

## Required merge order

1. `01_finite_field_backend_plan_artifact.apply_patch`
   - makes the fixed-core backend exhaustive and explicit FLINT fail closed;
   - records the current Wolfram plan-discovery path under a distinct
     `PlanDiscoveryBackend` contract;
   - reserves `FLINTAffineRREF` as a separate, currently unavailable route,
     rather than treating CFFA4 fixed-core FLINT as affine-RREF discovery;
   - strictly seals and validates M1 plans;
   - requires canonical native residues in `[0,p-1]` in addition to the
     modular core residual;
   - binds each modular interpolation artifact to record/ansatz, exact plan
     fingerprint, fixed-core backend request/thread/source/binary contract,
     and plan-discovery backend.  Old artifacts are stale, never legacy;
   - retains per-sample actual backend telemetry and returns the aggregate
     `BackendsUsed` set.

2. `02_solver_failure_resume_provenance.apply_patch`
   - adds bounded typed failure persistence with no gauge/sample/matrix
     payloads;
   - raises `SolverConfiguration` to schema 2;
   - hashes the finite-field solver, resume code, row-form materializer,
     sector route selector, and (for framed solves) transport chart code;
   - embeds the fixed-core source/binary execution contract and the distinct
     plan-discovery request;
   - records request and actual backend/plan telemetry in strip summaries;
   - binds resume by full `SameQ`, with only the existing narrow zero-forcing
     and rational-chart legacy exceptions.  A legacy direct-rational row is
     recomputed.

3. `03_deferred_row_gauge_regulator_seal.apply_patch`
   - enables Production-only deferred future-A row propagation when a
     complete installed row exists; Development remains `Together`;
   - adds deferred constant-regulator right-products and skips only the
     post-checkpoint diagnostic `badStrips` census when Deferred was actually
     used;
   - rejects kinematic-dependent regulator transformations;
   - verifies both inverse directions exactly;
   - requires an input/output/inverse/transformation seal created inside the
     accepted factor routine before installing the transformed prefix;
   - pins the accumulated transformation directions as
     `S -> S diag(T,I)` and
     `SInverse -> diag(T^-1,I) SInverse`.

4. `04_adversarial_mutants.apply_patch`
   - extends the existing serial post-integration drivers with noncanonical
     native residues, old/wrong-backend cache records, plan-discovery route
     confusion, source/backend provenance mutation, kinematic transformation,
     false inverse, bad factor seal, and independent/double `S`/`SInverse`
     direction swaps.

Patch 4 changes tests only and may be applied immediately after patches 1--3.
The runtime drivers were not executed because this task prohibited Wolfram
launches.  They remain mandatory before promotion.

## Pinned preimages

| Target | Required preimage SHA-256 |
|---|---|
| `FeynFacet/Private/FiniteFieldStripSolve.wl` | `c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671` |
| `FeynFacet/Private/FamilyRowGaugeResume.wl` | `e9719e551fcd1930dfbce478a25880d7393a9b6ab3dcf1d2a9672cf0bf4c5dde` |
| `Scripts/family_epsform_sector.wls` before patch 2 | `60cc272a0b28da47d670984f401286f4ec29854b6216b7f36580bcde43e4a660` |
| `Scripts/family_epsform_sector.wls` before patch 3 (post patch 2) | `31a7800df979719b9b3b5e0384474c61493890d02e02a4dc9a84e8255539599c` |
| `FeynFacet/Private/FamilyRegulatorFactor.wl` | `6e26a8eec72780a6fea52f5c72f32a4ac314b1cd436d6fdb09808e4e84f83b60` |
| `FeynFacet/Private/FamilyRowGauge.wl` (provenance dependency, unchanged) | `ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b` |
| `FeynFacet/Private/TransportCharts.wl` (provenance dependency, unchanged) | `c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a` |
| backend/plan adversarial driver | `95e78e65332c91db9e66eef7508954261d953a0e06a76ae1a84af0599e79cf0f` |
| solver/resume adversarial driver | `1a1137ac298f66e365cee43728a88083be042be9cf2eec2e42024fa6687ba0cf` |
| deferred sequential exact driver | `a9bd19ae674b32bc679ea7ff9c1371a20e6b5e38ce53fdaedfe4591f352ff701` |
| deferred static contract driver | `baecd98d2e5ce1749d71be85da842964c7bdd6889b8db18b722215eee7a8ec32` |

## Temporary-mirror postimages

These hashes are not package claims; they prove the exact staged sequence that
was statically inspected.

| Stage/target | Postimage SHA-256 |
|---|---|
| patch 1: `FiniteFieldStripSolve.wl` | `8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70` |
| patch 2: `FamilyRowGaugeResume.wl` | `816fa4d544806115181b3c3fe2d6ee3de89fff1d3d999e6412b6a745b010fc2b` |
| patch 2: `family_epsform_sector.wls` | `31a7800df979719b9b3b5e0384474c61493890d02e02a4dc9a84e8255539599c` |
| patch 3: `FamilyRegulatorFactor.wl` | `bef8ca27d92a76b6db0abb7cbccb1be2e4498471005fdfe8c40687d071d168c1` |
| patch 3: `family_epsform_sector.wls` | `6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1` |
| patch 4: backend/plan driver | `d61eea2863794565f32d1b13679de31987f57034fe02c2bec7bbc40018559c59` |
| patch 4: solver/resume driver | `3d37c6cf39e8d5ff9a22f417ef36f3dae3a38bea937ed72c2307c9c34f90f5af` |
| patch 4: deferred sequential driver | `7475f111359c8ff5f095bb729f1672670ec45efa50d3256479300542b027b426` |
| patch 4: deferred static driver | `5bec1c3af70d023f58dd7549946e72dc175a9d8df326b2ecdc3a6597483dc760` |

## Static evidence

- All four patch images applied sequentially to
  `/tmp/facet-package-rebase-xh-01` with the `apply_patch` parser.
- The package postimages and four mutated Wolfram drivers passed the existing
  no-kernel delimiter checker.
- `git diff --no-index --check` reported no whitespace errors for every
  preimage/postimage pair.
- `test_patch_suite_static.sh`: 72/72 passed.
- No patch contains `DirectRootChannelAssembler`.

## Mandatory post-merge runtime gates

Run only after source-pinned missions finish and through the centrally owned
kernel pool:

1. the two finite-field adversarial drivers;
2. `Tests/t_finite_field_constrained_solve.wls`,
   `Tests/t_finite_field_round2.wls`, and
   `Tests/t_finite_field_preparation.wls`;
3. the deferred sequential exact driver and `Tests/t_family_row_gauge.wls`;
4. the solver/resume adversarial driver and
   `Tests/t_family_row_gauge_resume.wls`;
5. one real rational and one algebraic rational-chart cache replay;
6. copied-checkpoint Production/Development comparison;
7. a complete independent family epsilon-form certificate.

Do not promote the deferred path or the strict cache schema based on the
static evidence alone.
