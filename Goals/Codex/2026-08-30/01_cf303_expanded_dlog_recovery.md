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
- [🟢] Run the real CF303 `(25,18)` minimal-denominator discriminator and record
  stage timings, unknown count, memory estimate, and consistency result.  The
  complete 48-letter system has 7,272 unknowns and is generically inconsistent.
- [🔴] Do not implement the proposed subset selector: a subset cannot repair
  the demonstrated inconsistency of the complete 48-letter span.
- [🟢] Reduce exact materialization from 1,477.2 s to 489.6 s and broker exact
  dlog construction from 1,513.8 s to 157.5 s on the real block.
- [🟢] Move constructed-dlog pair normalization and zero admission into the
  existing shards, and route large exact Jacobian pullbacks through helpers.
- [🟡] Compare the optimized 7,272-column affine equation against an independent
  reference assembly at a generic modular image.  If they agree, produce a
  compact left-null obstruction witness; if they disagree, repair the assembly.
- [ ] Remove redundant rectangle/offset probes after a certified simplex has
  failed at two independent generic images.
- [ ] Complete and certify the remaining triple-root families.
