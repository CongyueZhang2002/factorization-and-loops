# Fable: cross-check of the two consults on CF303 (25,18); unified action list

> 2026-08-30. Inputs: GPT Pro reply (02, assessed in 03) and Fable Max
> reply (04). This note supersedes 03's action list where the two
> differ. Bottom line: the consults agree on every kill, and they
> disagree on exactly one thing — the next computation — where Fable
> Max's answer is sharper and cheaper, conditional on one minutes-scale
> check. The obstruction now has a name, a classical precedent, and a
> predicted cure.

## Where the consults agree (independent arguments, same verdicts)

- Third root / deck images / algebraic letters: dead. Pro proves it by
  Galois trace descent (algebraic solutions average to rational ones);
  Fable Max by parity (the equation is even under the deck involution;
  odd targets are pure gauge; even parts of algebraic dlogs are norms =
  rational letters). Same kill, two proofs — high confidence.
- Constant diagonal renormalization (any ε-dependence): dead by
  functoriality/uniqueness on both sides.
- New letters supported on the known divisor D: dead (facts 2+3).
- A genuine ε-form (regulator-independent kernel matrix) cannot contain
  a non-closed entry: both invoke the same ε-order-matching flatness
  argument. Codex note 05's "ε-factorized but non-dlog" wording must
  not be used as a certificate category.
- The witness/cokernel oracle: necessary filter only; every survivor
  goes to an honestly overdetermined solve; whole-cokernel test, not
  single pairings.
- No elliptic/K3 claim without maximal-cut/Picard-Fuchs evidence.
  (Fable Max's own thinking passes flirted with a genus-one reading of
  the cubic divisor components; its final answer drops it and states
  the expected kernel is rational. The two consults concur.)

## Where they disagree, and the adjudication

**Pro's remaining GO:** enlarge the gauge pole bounds and keep hunting
CLOSED rational targets, entered through a tangential analysis of the
closedness operator along each divisor component.

**Fable Max's remaining GO:** the closedness demand itself was the
artifact — it came from insisting on constant residues. Identification:
the diagonals are ε-independent with (predicted) nilpotent residues, so
every local exponent of the completion connection is 0 at EVERY ε —
maximally resonant, the classical Bolibrukh locus (reducible +
resonant), which is exactly where constant-residue log form on a fixed
divisor can fail while the system remains perfectly polylogarithmic.
The measured ε-stability of the defect (fact 7) is itself the
fingerprint: exponents ε·λ are non-resonant at generic ε unless λ = 0.
Deligne's comparison then predicts the cure: allow residues to be
low-degree POLYNOMIALS in (x, y) (equivalently, adjoin finitely many
apparent letters off D), and the completion exists — one plain linear
solve, no closedness side-condition, in the existing gauge space.
Higher poles on D are then provably sterile (nilpotent spectra admit no
positive-integer eigenvalues), which settles Pro's enlargement question
on D by theorem rather than by computation; the only place extra
valuations can hide is exceptional components of the normal-crossings
resolution, a bounded afternoon audit.

**Adjudication: run Fable Max's route first.** It analyzes the right
operator (the completion connection itself) for the right target class;
Pro's tangential analysis was scoped to the closed-target problem,
which Fable Max shows is the wrong demand. The decisive probe (E1) is
hours on existing machinery, strictly cheaper than Pro's program, and
theory predicts success. Pro's extension-integral construction (its
equation (5)) is retained as the guaranteed exact finisher if E1 fails
— the two replies are complementary there, not in conflict.

**Consistency note (so nobody trips on it later):** E1's target has
non-constant residues, hence non-closed one-forms — this does NOT
contradict the flatness theorem both consults state. The E1 solve
happens at our existing dlog-form stage, where residues may depend on
the regulator; flatness of the completed triangular system supplies
dT = O(ε) automatically. The final certificate is then worded per E2:
either "(a) ε-factorized log form with residues polynomial in (x, y)"
or "(b) constant residues restored at the price of N flagged apparent
letters with nilpotent residue matrices" — never "ε-form with a
non-closed entry".

## Checks performed on the new claims before endorsing

- Fact 4 (closedness screen) does not exclude E1: it tested closed
  targets only. Fact 2 tested constant residues only. E1's space is
  genuinely untested. Verified against the screens' definitions.
- Fact 6b excluded forcing-numerator factors only as constant-residue
  strict dlogs; as COUPLED apparent letters (gauge denominators widened
  simultaneously) they are live — Fable Max's C2 caution matches the
  fact-6c lesson exactly.
- The census's honest hole is real: a valuation census on D cannot
  bound divisor components absent from D (apparent singularities).
  Escape (i) as framed in the prompt conflated the two.
- The ε-stability inference (fact 7 ⇒ nilpotent residues) is sound and
  makes the B1 check a prediction test, not a fishing trip.

## Unified ordered actions

1. **Nilpotency check (minutes).** Eigenvalues of the residue matrices
   of both diagonal ε-forms along every letter. Predicted: all
   nilpotent. If NOT: stop — both consults' identification needs
   revisiting before any further spend.
2. **Feeder-wedge convention check (one modular point).** Verify
   ∇F = −Σ_ℓ F_(25,ℓ) ∧ F_(ℓ,18) in our conventions (both consults
   assert it; it also certifies the screens' interpretation).
3. **Exact witness (cheap).** Rationally reconstruct y(ε) over Q(ε)
   and record yᵀb(ε) as an exact rational function — the paper-grade
   obstruction certificate; makes all subsequent oracle pairings exact;
   answers the depth-truncation side-question for free.
4. **THE E1 probe (hours; decisive).** Solve F + ∇G = Σ f_a(x,y) dlog
   φ_a + small polynomial one-form, deg f ≤ 2, existing gauge space,
   honestly overdetermined, fresh-point acceptance. Order a few hundred
   new residue columns on the existing 7,080-unknown system. Theory
   predicts success. On success: the block is plain MPL over the
   existing alphabet; arrange ε-factorization by the family rotation,
   else the E2 technology (Dlapa-Henn-Wagner; Goerges-Nega-Tancredi-
   Wagner; Poegel-Wang-Weinzierl); certificate wording (a)/(b) is a
   user decision.
5. **Spectral audit (afternoon; parallel).** Normal-crossings
   resolution of D; residue spectra on all components including
   exceptionals and infinity; admissible extra valuations = positive-
   integer eigenvalues with multiplicities. Upgrades the census to a
   theorem and closes escape (i) exactly, whatever E1 does.
6. **If E1 fails:** the C2 apparent-letter ladder (coupled solves;
   nilpotent-residue constraint at apparent letters), then Pro's
   extension-integral representation of row 25 as the guaranteed exact
   finisher, with numerical transport (two engines, 40-60 digits,
   stated standards) as insurance.
7. **STOP list (both consults, final):** deck/third-root rescues;
   constant diagonal renormalization; letters within D; the degree-3/4
   potential ladder within current bounds; "non-closed ε-form"
   certificate wording. Deck-odd columns are retained only as free
   null-controls of the oracle (exact zero forced; nonzero = bug
   detector).

## Decisions for the user

- Certificate wording preference if E1 succeeds: (a) polynomial
  residues, or (b) apparent letters — (b) is closest to the existing
  certificate language; both are equivalent and honest.
- Confirm the reprioritization: E1 probe before Pro's enlarged-bounds
  program (this note's adjudication).

— Fable, 2026-08-30
