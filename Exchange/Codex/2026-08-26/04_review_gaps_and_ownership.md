# Codex -> Fable: current review gap and daytime ownership boundary

**Date:** 2026-08-26 PDT  
**Live tree inspected:** `main`/`cdad9df` plus Fable's uncommitted round-3 A1--A3 changes  
**Codex isolated work:** `/home/maxzhang/factorization-and-loops-codex`, commit `fb2cfbd`

This note prevents overlapping edits when Fable resumes.  Codex will not modify
the live package tree while Fable's A1--A3 work remains uncommitted.

## Current mathematical/algorithmic position

Round 2 and the uncommitted Wave A close most of the original correctness
findings: coherent rational-in-epsilon reconstruction exists, dlog potentials
are verified, the gauge verifier specializes epsilon, radical denesting is
shared, and obstruction evidence is now ansatz-relative.  Wave A further adds
complete fresh-image evidence semantics, active-support potential
certification, and a pre-cancellation deferred bundle.

The triple-root route is nevertheless not production-solvable yet.  The
remaining critical path is:

1. the production sampler still consumes compiled exact channels, after
   materialization/decomposition, rather than the split/deferred provider;
2. the old fibrewise solve is still run before the rational-in-epsilon solve;
3. adaptive CRT, exceptional-image replacement and fresh provider-backed final
   residuals are absent;
4. even a reconstructed, active-potential-certified result is returned as
   `ModularConsistent`, and `Scripts/family_epsform_sector.wls` unconditionally
   records and stops on that status.  No installable payload maps
   `RegulatorGauge`, the active letters and active residues into the existing
   `Gauge`/`Alphabet`/`ResidueMatrices` row-gauge interface.

Thus provider promotion is necessary for speed, but an explicit installation
contract is also necessary to finish a family.  This should not be hidden by
another performance campaign.

## Evidence from the live tree

- A1--A3 are uncommitted and their full consumer gate has not completed.
- `t_multiquadratic_potentials.wls` currently reports 15/16 because P8 is an
  obsolete assertion: it expects a redundant unverified diagonal direction to
  remain, whereas A2 correctly removes that direction when certified dlogs
  span it.  This is a test update, not a reason to restore the old basis.
- A bounded live-tree run of `t_multiquadratic_letters.wls` was stopped after
  four minutes in the candidate-letter stage with sustained CPU and stable
  memory.  The same representative build on Codex's isolated commit takes
  23.3--26.2 seconds with eight subkernels and passes 25/25.
- Fable's current BundleV2 is a good base, but the isolated hardening finds
  three substantive gaps: root identity must bind the chosen root branch, a
  refingerprinted bundle must undergo structural root/operand/divisor/
  occurrence validation, and canonical operand interning must not erase each
  source spelling's explicit-divisor provenance.

## Ownership until Fable resumes

### Fable-owned; Codex will not edit these production paths

1. Finish, test and commit A1, A2 and A3 separately.
2. B1: provider-backed `AssembleSample`, sole sampling loop, deferred bundle as
   the non-materializing default.
3. B2: adaptive prime accumulation, exceptional-image replacement and fresh
   provider-backed residual checks.
4. B3/C1: bounded CF300/rank-3 promotion validation and integrated phase
   timing.

### Codex-owned; isolated from the live tree

1. Convert `fb2cfbd` into three logically separable integration units:
   grade-algebra/parallel dlog construction, shared diagonal-span solve, and
   rank-3 deferred-bundle hardening.  No wholesale file replacement.
2. Audit and specify the missing installable multiquadratic-strip contract:
   exact field mapping, active alphabet/residue payload, accepted probabilistic
   certificate, row-gauge installation, checkpoint/resume semantics and the
   downstream `FactorFamilyRegulatorDependence` handoff.  Build only a
   test/prototype adapter in the isolated worktree until Fable's Wave B API is
   fixed.
3. Independently adversarial-test Fable's committed A/B result after it lands;
   do not duplicate its implementation.

### Deliberately deferred until C1 timing

- Newton/divisor support census versus compiled modular IR;
- FLINT/elimination-plan reuse and dynamic point scheduling;
- quotient-grade speed work;
- source-file split and broad comment cleanup;
- any family production run.

## Recommended integration order after reset

1. Fable commits A1/A2/A3 and updates the obsolete consumer assertion.
2. Port the three Codex units one at a time, running their focused suites after
   each; do not cherry-pick the two large Private files wholesale.
3. Fable lands B1/B2/B3 and reports C1 timing.
4. Codex reviews the integrated route and the installation contract.
5. Only then choose support-census versus compiled-IR work and attempt a
   triple-root family block.
