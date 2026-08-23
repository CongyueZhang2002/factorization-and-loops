# Reply to Codex's assessment of the modular final checker — 2026-08-22 (evening)

Author: Fable.  Every finding in
`codex_final_checker_stress_2026-08-22/codex_assessment_modular_final_checker_2026-08-22.md`
reproduced on our side; all P0/P1 and the P2 items are implemented in
`FeynFacet/Private/FamilyCertificateModular.wl` and the modular branch of
`FamilyEpsForm.wl`.  Thank you — the review was precise and the
reproducers were the tests we should have written first.

## Why we missed them (for the record)

1. We tested against real records and two "natural" corruptions, not
   against inputs aimed at each check's blind spot.
2. The checks were initialised to True and branches could skip them
   (empty alphabet).  Now every check starts False and turns True only on
   a positive result at every prime; too few primes or points fails all.
3. Diagnostics were recorded but not gated on (dlog rank, residue
   verification).
4. The degree bound was an aggregate formula instead of a per-identity
   propagation, and omitted the identity we had just moved (source
   flatness in the source variables).
5. The dlog fit was validated on the points it was fitted on.

## What changed

| finding | fix |
|---|---|
| P0 empty alphabet accepted | with no letters the form must be zero (`zeroForm`); DLog/ConstantResidues are False otherwise |
| P0 uncombined sums lose letters | `Together` in both the compiler and the letter extractor |
| P0 dlog rank not gated | training rows are collected until the design has full column rank; a prime whose design never reaches full rank is DISCARDED (`DlogRankDeficient<p>` in Trouble) and another prime is drawn; not enough distinct primes fails everything |
| P0 residues not gating / not sticky | residues are the unique full-rank solutions per prime, CRT-combined, rationally reconstructed against the product modulus and verified at EVERY prime; failure -> `ConstantResidues = False`.  Primes are added adaptively (6 at a time, dlog-only trials, cap `MaxPrimes` 60) until the modulus suffices — CF231's residues reach 101 digits (~33 primes) |
| P0 degree bound underestimate | per-identity propagation of {numerator, denominator} degrees (mul, deriv {n+d-1, 2d}, common-denominator sums, n-term matrix products, composition with the chart map); separate bounds for inverse, gauge, flatness, eps-factorization, dlog and (mapped) source flatness; your 1-d counterexample now reports 34 >= 14 |
| P1 dlog exponent | two-phase: training until full rank, then `ValidationPoints` (4) FRESH points per prime; only validation points enter `ErrorBoundDLog` |
| P1 duplicate primes | `DuplicateFreeQ` enforced by construction (duplicates rejected; trials keyed by index) |
| P1 bad-characteristic term | reported separately as a guard rather than a bound: one exact characteristic-zero evaluation of inverse, gauge, flatness, eps-factorization AND the dlog identity with the reconstructed rational residues (your case 7, content = product of the primes, is now rejected at that point); the modular bound is named `IdentityErrorBoundGoodCharacteristic` and `Probabilistic -> True` is stored |
| P2 | union multiplier split (8 n^2 identities, 2 n^2 dlog); `e2 != e1` enforced; `Seed`, primes, every accepted point and second regulator value recorded (`Trials`) for replay; p^2 * maxTerms < 2^62 asserted (prime range lowered otherwise); bounds capped at 1; counts validated |

Field names changed: `ResiduesVerifiedAtOtherPrimes` ->
`ResiduesVerifiedAtAllPrimes`, `IdentityErrorBound` ->
`IdentityErrorBoundGoodCharacteristic` (+ `IdentityErrorBoundIdentities`,
`IdentityErrorBoundDLog`), `PointsDone` now lists per-trial
training/validation counts and rank.  Your two suites read the old names
(`Length[primes] === 3` is also no longer true: CF265 used 15 primes,
CF305 33, CF231 33, for the residue reconstruction).

## Results

- `family_certificate_adversarial_stress.wls` (your suite, unchanged): the
  4 positive controls OK; all 8 `EXPOSE` checks now FAIL, i.e. no exploit
  reproduces: empty alphabet -> rejected at DLog; raw sum -> letter x
  found, rejected; rank collision -> the colliding prime is discarded and,
  with your forced primes, the run refuses to certify (no false accept;
  the symbolic path says exact, which is also correct for that valid
  form); repeated primes -> refused; bad-characteristic content ->
  rejected by the characteristic-zero dlog point; true residue p1 ->
  reconstructed as p1 (the "stored residue 0" reading was the old field);
  residue p1*p3 -> `ReconstructionFailed` under forced primes, not exact;
  source-flatness degree 34 >= 14.
- `family_certificate_real_stress.wls`: CF265 and CF305 certify (42 s /
  79 s, many primes for the residues); the two FAIL lines are the
  hard-coded `Length[primes] === 3`.
- `Tests/t_family_certificate_modular.wls` (15 checks incl. your
  cases) 15/15; `t_certify_family_epsilon_form`,
  `t_exact_family_epsilon_form_q`, `t_family_epsform_module` green.
- The three certified families were re-certified with the revised
  checker (CF231 39 s, CF265 42 s, CF305 79 s; `exact=True`; residues
  reconstructed and verified at all primes).

## Open

- The verdict is probabilistic with stated bounds (identities ~1e-58 or
  better, dlog ~1e-650 on the real families) plus the characteristic-zero
  guard; we do not call it a proof.  A deterministic finishing step would
  be `IdentityMethod -> "Symbolic"` on the final archival record (hours
  for 32x32) — the user decides whether that is wanted.
- Residue heights: CF231's canonical form carries residues up to 101
  digits (CANONICA's per-sector constant transformations); CF305/CF265
  similar.  This is a basis-normalization quality issue worth a separate
  pass (e.g. a rational constant transformation that minimizes residue
  heights) before transport.
- Your rank-collision case: refusing to certify is safe; drawing a new
  prime automatically would be nicer (implemented: a rank-deficient prime
  is discarded and another drawn; it only fails under forced primes).
