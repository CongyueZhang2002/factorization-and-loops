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
- [🟢] Compare the optimized 7,272-column affine equation against the independent
  raw-PDE oracle at three generic modular points.  All 24 rows and RHS entries
  agree exactly; the compact full-system witness has `rank(A)=7268`,
  `rank([A|b])=7269`, `y^T A=0`, and `y^T b!=0` modulo 2147483423.
- [🟢] Complete the geometric polar-divisor census.  All 16 affine polar curves
  and the projective infinity component are absolutely irreducible, so there
  are no missing component-dlog directions.
- [🟢] Close the remaining strict-dlog target axes. Rational canonical diagonal
  changes preserve existence; all simple-pole closed rational one-forms on the
  projective divisor are already in the 16-dlog span; the full valuation and
  infinity bounds are saturated.
- [🟢] Confirm the gauge-eliminated obstruction for both 16 and 48 dlogs at two
  configured and one fresh independent prime/regulator image.
- [🟢] Recover all six feeder affine nullspaces and prove that their 26 gauge
  directions are exactly kinematics-independent matrix shifts, so a coupled
  row solve cannot repair the downstream dlog obstruction.
- [🔴] Do not treat the `7280 x 7284` exact-form fits as solution evidence:
  they were full-row-rank underdetermined systems. The properly overdetermined
  `7296 x 7284` system rejects `dx,dy,d(x^2)`.
- [🟡] Find the smallest rational-kernel target with an overdetermined
  covariant-integrability ladder, starting from all polynomial potentials of
  total degree 2 and extending only when the rank evidence requires it.
- [ ] Reconstruct and accept a surviving rational-kernel gauge across
  regulator images and primes using unseen-prime and random-point residuals.
- [ ] Remove redundant rectangle/offset probes after a certified simplex has
  failed at two independent generic images.
- [ ] Complete and certify the remaining triple-root families.
