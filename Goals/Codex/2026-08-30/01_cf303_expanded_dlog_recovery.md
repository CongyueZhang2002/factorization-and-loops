# CF303 expanded-dlog recovery

- [🟢] Correct the false `ModularStructureUnstable` result when no dense sample
  is admitted.
- [🟢] Reuse package-built exact dlog one-forms in the rational finite-field
  engine without repeating symbolic differentiation/materialization.
- [🟢] Retry the broader dlog alphabet with the original A3 denominator before
  any conservative denominator widening.
- [🟢] Preserve alphabet and gauge-denominator coordinate metadata through
  interpolation, resume, and reconstruction.
- [🟢] Keep legacy artifacts compatible with record-level `ExtraLetters` and
  `GaugeDenominatorFactor`.
- [🟢] Obtain independent xhigh and ChatGPT Pro review and resolve blockers.
- [🟡] Run the real CF303 `(25,18)` minimal-denominator discriminator and record
  stage timings, unknown count, memory estimate, and consistency result.
- [ ] If the full richer alphabet is still inconsistent, implement a modular
  full-system cokernel selector before any new exact dlog construction or
  denominator experiment.
- [ ] Complete and certify the remaining triple-root families.

