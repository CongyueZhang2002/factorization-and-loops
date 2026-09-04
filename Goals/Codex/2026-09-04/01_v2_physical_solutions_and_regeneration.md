# V2 physical master-integral solutions and regeneration

## Close the current V2 unit

- [x] 🟢 Derive each required master-integral epsilon order from the requested hard-function order and the exact epsilon valuation of its coefficient.

- [ ] Complete the `MasterIntegralSolution` consumer for boundary functions on a positive-dimensional physical boundary stratum, without treating them as constants.

- [x] 🟢 For a singular lower limit, reuse the coefficient operator of the same differential system with new local initial data; do not introduce an artificial inverse map to the old regular base point.

- [ ] Replace the remaining package-facing pre-V2 names in this unit and remove aliases only after all live callers use the new names.

## Finish the CF303 solution in mathematical order

- [ ] Regenerate the CF303 source-system, rational-in-epsilon final-block, local Frobenius, and soft-stratum records in the V2 formats from preserved mathematical inputs.

- [ ] Express the complete 45-component local initial data in the same `G25` basis used by the differential system, including the six intrinsic and seven inherited modes, resonant logarithmic chains, and the exact `F25 = G25 + H L` relation.

- [ ] Build the formal Chen/GPL/eMPL solution with tangential lower limit `z=2p`; retain the dependence on the soft-stratum variable `p` as boundary functions until its tangential differential equation is solved.

- [ ] Materialize only the master rows and epsilon orders required by the hard function. Keep each path segment explicit and expand polynomial-factor kernels into marked points only for surviving terms.

- [ ] Emit the exact list of boundary-function epsilon coefficients and iterated integrals that must be evaluated next. This list, rather than an intermediate operator, is the completion condition for the differential-equation stage.

- [ ] Validate the defining differential equation and the local asymptotics at bounded independent finite-field points; do not add additional intermediate acceptance layers.

## Regenerate the other families

- [ ] Regenerate the rational and lower-root families first from the preserved reduction, registry, master-list, and hard-function valuation inputs, using only V2 records.

- [ ] Run the full dlog epsilon-form families through the same demand-derived solution builder and emit one `MasterIntegralSolution` per family.

- [ ] Run the other multiquadratic families through the same public workflow; root count and family name may select mathematical input data, but must not select code paths inside `FeynFacet/Private`.

- [ ] Record wall time, peak resident memory, term count, and demanded epsilon coefficients for every mathematical stage and family as the new baseline.

## Performance work driven by the regenerated baseline

- [ ] Profile only stages that dominate a real family. Prioritize sparse demand propagation, batched finite-field evaluation, coefficient reconstruction, and delayed marked-point expansion.

- [ ] When several families are active, distribute the available workers across them; as the active count falls, give remaining families more workers only when their current algorithm scales with them.

- [ ] Keep the night within eight Wolfram subkernels and eight native cores. Run one main Wolfram kernel per family job, and never start a second copy of a family phase already in progress.

- [ ] Stop and diagnose a phase that approaches one hour or shows stagnant output, low useful CPU utilization, or abnormal memory growth; preserve completed mathematical records before changing the implementation.

## Generality and conciseness goals

- [ ] Remove family and project names from `FeynFacet/Private`; family-specific input builders remain under `Scripts`.

- [ ] Remove unused V1 readers, one-off compatibility branches, and synthetic-only modules after the V2 callers and tests have migrated.

- [ ] Replace overloaded `Observable`, `Endpoint`, `Period`, `Frame`, `Gauge`, bare `Word`, and generic `Transport` names according to the accepted mathematical terminology, with semantic splits where the old object combined distinct operations.

- [ ] Keep exact symbolic validation and probabilistic finite-field validation as explicitly different choices. Production large-family validation uses the bounded finite-field choice unless an exact proof is itself the requested output.

- [ ] Run the focused V2 tests, the package-generality test, and then the bounded full gate. A missing archived artifact is not a passing test.

## Expected overnight extent

The first three sections contain more than one night of work. A successful night should close the boundary-function consumer, produce a V2 CF303 solution or a precisely localized mathematical obstruction, regenerate the easy and ordinary dlog families, and leave measured baselines for any hard families still running. Terminology cleanup and removal of retired code proceed only around units already made green; they do not delay the mathematical path to the solutions.
