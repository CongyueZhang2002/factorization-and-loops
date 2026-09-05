# V2 physical master-integral solutions and regeneration

## Close the current V2 unit

- [x] 🟢 Derive each required master-integral epsilon order from the requested hard-function order and the exact epsilon valuation of its coefficient.

- [ ] Complete the `MasterIntegralSolution` consumer for boundary functions on a positive-dimensional physical boundary stratum, without treating them as constants.

- [x] 🟢 For a singular lower limit, reuse the coefficient operator of the same differential system with new local initial data; do not introduce an artificial inverse map to the old regular base point.

- [ ] Replace the remaining package-facing pre-V2 names in this unit and remove aliases only after all live callers use the new names.

## Finalize the general code before family runs

- [x] 🟢 Remove family and project names from `FeynFacet/Private`; family-specific input builders remain under `Scripts`.

- [ ] Replace overloaded `Observable`, `Endpoint`, `Period`, `Frame`, `Gauge`, bare `Word`, and generic `Transport` names according to the accepted mathematical terminology, with semantic splits where the old object combined distinct operations.

- [ ] Remove unused V1 readers, one-off compatibility branches, and synthetic-only modules after the V2 callers and tests have migrated.

- [x] 🟢 Keep exact symbolic validation and probabilistic finite-field validation as explicitly different choices. Production large-family validation uses the bounded finite-field choice unless an exact proof is itself the requested output.

- [ ] 🟡 Profile the representative-family path before the campaign. Prioritize sparse demand propagation, batched finite-field evaluation, coefficient reconstruction, and delayed marked-point expansion.

  CF48's fresh epsilon-form construction now takes 561 s and its corrected final finite-field validation 84 s, for a projected 645 s fresh total versus the previous 724.51 s. CF259's fresh diagonal-block assembly fell from about 430 s to 44 s by removing duplicate symbolic diagonal identities and applying size-aware parallel rational simplification only to large block rows.

- [ ] Make the family worker pool redistribute available workers as jobs enter and leave. Give a phase more workers only when that algorithm scales with them.

- [ ] Keep the night within eight Wolfram subkernels and eight native cores. Run one main Wolfram kernel per family job, and never start a second copy of a family phase already in progress.

- [ ] Stop and diagnose a phase that approaches one hour or shows stagnant output, low useful CPU utilization, or abnormal memory growth; preserve completed mathematical records before changing the implementation.

## Finish CF303 and the three-root code path

- [ ] Regenerate the CF303 source-system, rational-in-epsilon final-block, local Frobenius, and soft-stratum records in the V2 formats from preserved mathematical inputs.

- [ ] Express the complete 45-component local initial data in the same `G25` basis used by the differential system, including the six intrinsic and seven inherited modes, resonant logarithmic chains, and the exact `F25 = G25 + H L` relation.

- [ ] Build the formal Chen/GPL/eMPL solution with tangential lower limit `z=2p`; retain the dependence on the soft-stratum variable `p` as boundary functions until its tangential differential equation is solved.

- [ ] Materialize only the master rows and epsilon orders required by the hard function. Keep each path segment explicit and expand polynomial-factor kernels into marked points only for surviving terms.

- [ ] Emit the exact list of boundary-function epsilon coefficients and iterated integrals that must be evaluated next. This list, rather than an intermediate operator, is the completion condition for the differential-equation stage.

- [ ] Validate the defining differential equation and the local asymptotics at bounded independent finite-field points; do not add additional intermediate acceptance layers.

## Representative-family qualification gate

- [ ] Select one historically difficult family with zero square-root generators and run the complete V2 path under a bounded phase budget.

  Differential-system rung completed for CF269: 23 masters, two Kira closure iterations, 53.99 s wall time and 414,060,424 bytes peak kernel memory. Phase times were 45.20 s for Kira, 7.69 s for connection assembly, and 0.65 s for nine finite-field flatness samples. The regenerated matrices are exactly identical to the archived trusted matrices. The later epsilon-form and boundary-solution rungs remain open.

- [ ] Select one historically difficult family with one square-root generator and run the same complete V2 path.

  Differential-system rung completed for CF48: 27 masters, 59.03 s wall time and 442,482,448 bytes peak kernel memory. The regenerated matrices are exactly identical to the archived trusted matrices.

  Its 20-sector family dlog epsilon form has also passed the final finite-field validation. A redundant stored alphabet first exposed a rank-deficient residue fit; production now reduces supplied rational letters to distinct irreducible divisors before fitting the constant residue matrices. One fully fresh post-fix timing run remains before this representative is closed.

- [ ] Select one historically difficult family with two independent square-root generators and run the same complete V2 path.

  Differential-system rung completed for CF265: 32 masters, 46.81 s wall time and 431,858,256 bytes peak kernel memory. The regenerated matrices are exactly identical to the archived trusted matrices.

- [ ] Run a three-root representative through the completed multiquadratic path; CF303 additionally exercises the rational-in-epsilon final block and boundary-stratum solution.

  Differential-system rung completed for CF259: 47 masters, 126.39 s wall time and 687,429,472 bytes peak kernel memory. The regenerated matrices are exactly identical to the archived trusted matrices. The multiquadratic epsilon-form and solution rungs remain open.

  CF259 is now running from a fresh 44 s diagonal-block assembly. The earlier production assembly spent 96 s re-deriving one validated 4x4 diagonal block and then repeated the same diagonal conjugation; those duplicate identities are now left to the single final whole-family finite-field validation. Large genuine off-diagonal block-row simplifications use the shared worker pool, while small rows remain serial.

  The first genuine three-root block, `(23,21)`, exposed two separate implementation defects. First, the outer root census correctly found the union of roots in the visible block equation and its deferred inhomogeneity, but the preparation call recomputed the census from the zero placeholder and dropped the deferred-only root. The provider therefore rejected every split point as undeclared. Preparation now receives the already-validated union explicitly; the corrected block has rank three, 2,442 unknowns, and 96 equations per kinematic point.

  The corrected run was then stopped deliberately after 1,189 s and 80 image waves to repair a throughput defect rather than wait for it. In each four-image wave, three clean helper kernels finished in about 2.8--3.8 s, while the fourth image ran on the coordinator whose retained image cache had grown to about 3.3 GB; successive wave dispatches were therefore 13--17 s apart and seven kernels were idle between bursts. Complete image batches now run on up to seven clean helpers and reuse one immutable parsed payload. With that change, `(23,21)` reconstructed and passed fresh finite-field residuals in 70 s using two 61-bit primes and seven regulator images per prime. A further measured repeated payload-validation pass has been removed from the next-run code path but is not included in the 70 s timing.

  The later hard blocks now have an explicit before/after performance gate. For `(27,23)`, the same saved equation and `KallenQ4a` parametrization improved from 878.7 s to 523.1 s in the finite-field solve and from 558.1 s to 428.3 s in pull-back acceptance; combined time fell from 1,436.8 s to 951.4 s. For `(27,19)`, the identical 15,616 by 15,500 complete modular system now returns its inconsistency in 151.2 s instead of remaining unresolved after at least about 538 s. A provisional degree-one support construction was slower and has been removed. `(27,21)` and `(27,20)` completed in 128.0 s and 85.9 s respectively, but neither has a comparable earlier corrected-input completion and neither is counted as a speedup claim. The earlier 1,189-to-70-second result belongs to the distinct `(23,21)` block. Full evidence is in `Exchange/Codex/2026-09-04/18_hard_block_performance_acceptance.md`.

- [ ] Compare every representative against its defining differential equation and local asymptotics, and record wall time and peak memory by mathematical phase. A timed-out or memory-pathological phase returns to code optimization rather than being allowed to finish eventually.

- [ ] Run the focused V2 tests and package-generality test after the representatives. A missing archived artifact is not a passing test.

## Launch the all-family regeneration only after the gate

- [ ] Regenerate the rational and lower-root families first from the preserved reduction, registry, master-list, and hard-function valuation inputs, using only V2 records.

- [ ] Run the full dlog epsilon-form families through the same demand-derived solution builder and emit one `MasterIntegralSolution` per family.

- [ ] Run the other multiquadratic families through the same public workflow; root count and family name may select mathematical input data, but must not select code paths inside `FeynFacet/Private`.

- [ ] Record wall time, peak resident memory, term count, and demanded epsilon coefficients for every mathematical stage and family as the new baseline.

## Expected overnight extent

The plan contains more than one night of work. A successful night should close the general interfaces and performance path, pass hard representatives for all four root counts, produce a V2 CF303 solution or a precisely localized mathematical obstruction, and only then begin the all-family regeneration. No broad campaign starts against code that has not passed the representative gate.
