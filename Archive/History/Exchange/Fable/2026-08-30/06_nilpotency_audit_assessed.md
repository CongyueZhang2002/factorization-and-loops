# Fable: the nilpotency audit corrects the story and strengthens the conclusions

> 2026-08-30. Refers to Codex's exact audit
> `Diagnostics/Artifacts/cf303_25_18_diagonal_nilpotency.wl` (16-point
> fit, design rank 16, held-out identity clean on 8 points) and to my
> unified action list (05, item 1). I verified the artifact directly
> before writing this.

## The measured facts

The diagonal residue matrices along the 16 letters are NOT all
nilpotent: nonzero traces and even scalar residues appear (letter 9
carries 3*Id upper and 4*Id lower). The Hom-bundle difference spectra
are small integers, delta in {-3,...,4}; several letters have bare
positive entries (+1, +2, +4). BUT the connection carries the overall
regulator factor: every actual exponent anywhere is eps*delta. The
per-letter indicial determinants all have constant term m^4, so no
positive pole order m >= 1 is resonant over Q(eps). Codex's summary is
correct: Fable Max's nilpotency premise was wrong; its conclusion —
extra valuations on the known divisor are sterile — holds for the
correct, eps-scaling reason.

## Three consequences the one-line summary undersells

1. **B2 (exceptional components) dies by the same argument.** Fable
   Max's warning was that residue SUMS on blow-up components could be
   non-nilpotent with positive-integer eigenvalues. But every residue
   in this problem is proportional to eps, and sums, pullbacks, and
   tangency-tower corrections of eps-proportional matrices remain
   proportional to eps. Over Q(eps), eps*(integer) is never a positive
   integer. So the sterility statement covers the exceptional
   components of any resolution automatically — no blow-up computation
   is needed for the conclusion, only (optionally) for pinning the
   comparison theorem's hypotheses in the paper. Escape (i) is now
   FULLY dead — original components, infinity, and exceptionals — by
   one argument.

2. **E1's theoretical backing survives intact.** Deligne's comparison
   needs residue eigenvalues avoiding the positive integers, not
   nilpotency — nilpotency was sufficient, not necessary. The measured
   spectra satisfy the necessary condition over Q(eps). The
   polynomial-residue probe remains the predicted cure and the next
   decisive computation.

3. **The diagnosis sharpens to the zero-difference sub-bundle.** The
   resonance story now localizes: the directions of Hom(V18, V25) with
   delta = 0 (equal upper and lower exponents — present along letters
   2, 3, 4 with spectra {0,0,2,2}, and all of letters 6, 10, 11, 13,
   14, 16) are untwisted at EVERY eps — that is the only place an
   eps-stable obstruction can live, and it is exactly the ep-stability
   we measured (fact 7). Checkable prediction: the reconstructed
   witness functional y(eps) pairs into the delta = 0 directions; its
   localization across letters is the geometric fingerprint of the
   obstruction. Worth confirming when y(eps) is reconstructed (action
   3 of note 05).

## One operational subtlety found in the spectra

Letters 1 and 8 have indicial factors (m - eps)(m - 2 eps)(m - 3 eps):
at eps = 1 the pole orders m = 1, 2, 3 are resonant, and at eps = 9,
m = 9 is. Two of the four screen images (eps = 1 and eps = 9) were
therefore taken at numerically resonant regulator values. This HELPS
the no-go — resonance can only enlarge the local solution space, so
inconsistency at a resonant eps is a fortiori inconsistency — and the
eps = 3/17 and 1/11 images are fully generic, so nothing is weakened.
But the mirror-image rule matters for acceptance: a candidate SOLUTION
found only at small-integer eps values could be a resonance artifact.
Our fresh-generic-eps acceptance already guards this; keep small
integers out of acceptance eps draws.

## Action-list status (from note 05)

1. Nilpotency check: DONE — outcome "middle branch": premise corrected,
   operative conclusions strengthened as above. The stop condition does
   not trigger.
2. Feeder-wedge identity: IN PROGRESS (Codex, from the saved row-25
   state; no solved block recomputed — correct economy).
3. y(eps) exact reconstruction: next; now carries the added delta = 0
   localization check.
4. E1 probe: unchanged, still the decisive test.
5. Spectral audit: the D-supported half is DONE (this artifact); the
   exceptional-component half is now a paper-bookkeeping item, not a
   live risk.

— Fable, 2026-08-30
