# Independent verification of the A2/A3/A4 standardization (2026-08-21, evening session)

Context: the standardization was partly done by an Opus session; the user asked
for an independent check. Everything here was recomputed from stored artifacts,
not read from the acceptance prose.

- `compare_oracle.wls/.log` — for CF254 (9,7) vs the frozen M0 oracle and
  CF254 (9,6) vs both the O2b result and the ORIGINAL M0 census result:
  Alphabet, ResidueMatrices and Gauge are `SameQ`; the exact both-variable
  Pfaffian residuals of the A2A3A4 gauge are recomputed from the fixture by
  independent code and are identically zero. NormalizationColumns differ only
  because A3 renumbers the unknowns (1568 vs 2144, 548 vs 728).
- `probe_heldout.wls/.log` — `finiteFieldStripHeldOutInterpolate` on synthetic
  coordinates of degrees (3,3), (1,2), (0,0), 0, (5,1) and a cancelling (1,1):
  validated with 10 images (construction 4 -> 7), all degrees correct,
  interpolants reproduce the truth at fresh regulator values; a wrong expected
  profile returns `RejectPrimeDegreeProfileChanged`; short pools return
  `MoreSamplesRequired`; a second prime with the learned profile validates at
  10. `finiteFieldStripUnseenPrimeResidualQ` on the real (9,6) A4 artifacts
  accepts the true lift and rejects a +1 and a +eps/7 corruption.
- `t_round2.log` — `Tests/t_finite_field_round2.wls` 11/11; FLINT backend
  recorded on 70/70 samples of both A4 acceptance runs, zero discards.

Open items found (none affect the accepted results): no prime-width guard in
`SampleEpsFormStripAffine` (packed evaluator assumes p < 2^31); the degree
probe climbs every support shell at an offset whose full rectangle is already
inconsistent (7 wasted probes per rejected offset on (9,7)); the unseen-prime
check silently becomes a no-op if the reserve primes are all in "Primes"; the
suite test exercises A2 only on a 1x1 eps-linear block.

## Fixes of the four open items (same evening, user request)

`FeynFacet/Private/FiniteFieldStripSolve.wl`:
1. **Width guard**: `SampleEpsFormStripAffine` and `SolveEpsFormStripFiniteField`
   refuse any prime >= 2^31 with `SampleEpsFormStripAffine::width` (the
   packed evaluator's products must stay below 2^62).
2. **Probe order** (`finiteFieldStripProbeOrder`): shell 0, then the full
   rectangle — inconsistent means no sub-support at that offset, stop —
   then the intermediate shells ascending; the rectangle is the fallback.
   Re-run of the (9,6) acceptance (`probe_order_rerun/`): 2 probes at offset
   {0,0} instead of 9, wall 157.1 -> 140.9 s, gauge/residues/alphabet SameQ
   to the M0 census oracle, exact residuals recomputed zero.
3. **Reserve primes**: chosen by walking down from 2147483399 past every
   prime of the schedule (never empty); the prime used is recorded as
   `"UnseenPrime"` in the solution.
4. **Test**: `Tests/t_finite_field_round2.wls` now also covers the held-out
   mechanics at degrees up to (3,3)/(5,1), the unseen-prime acceptance and
   rejection on the stored (9,6) A4 artifacts, the reserve prime outside a
   schedule that contains the former fixed reserves, the width guard, and
   the probe order: 23/23 (`t_round2_after_fixes.log`). The five other
   finite-field tests were re-run as regression tests: all green.

## Codex epsilon-form audit (late evening): residue census and fixes

Text-level census of the residue matrices in every deep-rung result under
`BenchmarkStripBackends/` (the first Wolfram check was invalid: a
Module-local `eps = Global`eps` self-assignment): frozen (9,7) 40/52 nonzero
residue entries carry `c/(a+eps)`, (9,6) 44/44, CF48 9/9, Maple results
likewise. These are DLOG forms, the rung's contract (the sector driver
factorizes eps afterwards; CF254's certified record was built from these
strips). The structural gate adopted from the audit therefore requires
regulator-free letters and kinematics-free residues (`DLogFormCertified`)
and reports eps-free residues separately (`CanonicalEpsFormCertified`).
Logs of the rewritten/re-run tests: `codex_audit_fixes/`.
