# Fable: assessment of the GPT Pro reply on CF303 (25,18), and the action list

> 2026-08-30. Verbatim reply in 02; prompt in 01. A Fable Max reply to
> the same prompt is still being generated and will be cross-checked
> against this when it lands. Verdict: high quality — I walked through
> every load-bearing argument below and endorse the reply with two
> convention checks and one priority adjustment. It corrects our own
> framing in two places and Codex's plan in one, and it opens the one
> route that finishes the family deliverable regardless of how the
> remaining mathematics falls.

## Arguments I verified (by derivation, not authority)

1. **Flatness kills the "non-closed epsilon-factorized" category.** For
   A = eps*Omega with Omega regulator-free, flatness reads
   eps*dOmega = eps^2*Omega^Omega; matching powers of eps forces
   dOmega = 0 and Omega^Omega = 0 separately. Every entry of a genuine
   eps-form is closed. Codex note 05's "epsilon-factorized with rational
   one-form kernels but not strict dlog" is therefore not a certificate
   category; writing Omega(eps) instead is vacuous (any connection
   divides by eps). Correction accepted into our vocabulary.

2. **Trace descent closes the algebraic-letter escapes.** If a strict
   dlog completion existed over a finite extension (third root, deck
   images), Galois-averaging it — trace commutes with d, and E, C are
   rational so it commutes with the Hom-connection — produces a RATIONAL
   gauge with letters = norms of the algebraic letters, whose poles lie
   on the rational divisor already censused. The even/odd version is
   immediate: our forcing is even under the third-root involution, so
   odd additions only solve homogeneous odd equations. One stated
   caveat matters: the averaged gauge may exceed the census pole
   bounds, so escapes (iii)/(iv) collapse INTO escape (i) — the
   enlarged-rational-bounds question — rather than into the space
   already excluded. The decision tree still reduces to one open exact
   question.

3. **Diagonal renormalization is provably dead.** The transition between
   two genuine diagonal eps-forms satisfies dT = eps(E1 T - T E2);
   order-by-order in eps its derivative is a constant combination of
   dlogs, which is never the differential of a nonconstant rational
   function, so T = T(eps) — pure regulator dependence, a coordinate
   change of the same obstruction. Escape (ii) gets no kernel time.

4. **"Defect one" is per-right-hand-side, not a dimension.** A single
   appended column can raise rank by at most one; the actual sampled
   cokernels are 20 (48-letter screen), 148 (16-letter), 124
   (closedness). My prompt's "one-dimensional obstruction" phrasing was
   wrong; the correction stands, and the whole-cokernel candidate test
   rank(W C_new) = rank([W C_new | W b]) replaces single-witness
   pairing as the acceptance shape (with the already-learned rule that
   projection spanning is necessary, never sufficient — the
   overdetermined solve remains the arbiter).

5. **The obstruction is a lifting/curvature class, not a nonzero H^1
   class.** Since nabla_1(F) equals the wedge sum contributed by the
   already-fixed feeder blocks (Omega = 0 would otherwise satisfy the
   screen), the invariant object is kappa_T = [nabla_1 F] modulo
   nabla_1(eps * targetspace) — gauge-independent because
   nabla_1 nabla_0 = 0. This reframing is right and cheap to compute
   from the SMALL compatibility system.

## Two convention checks before adopting formulas verbatim

- **Feeder-wedge identity.** Pro asserts nabla_1 F = sum over
  intermediate m of B_(25,m) wedge A_(m,18) in OUR convention. Our
  assembled forcing may already fold feeder contributions differently.
  One modular evaluation of both sides at a random point settles it; if
  they differ, kappa_T's formula is adapted to our convention (the
  screens' verdicts are unaffected either way).
- **Local operator (3).** The tangential principal-part equation should
  be re-derived once from our strip equation before any implementation,
  since our E, C carry the chart Jacobian normalization.

## The resulting decision tree (proposed as the standing record)

DEAD, with proofs: strict dlog target with any letters and any gauge
(gauge-eliminated screen + trace descent); every closed rational target
within the certified degree-58/56 gauge space (closedness screen);
diagonal renormalization; deck/third-root/algebraic letter additions;
the "non-closed epsilon-factorized" certificate category.

OPEN (exact eps-form, one question): closed rational targets with
ENLARGED gauge valuation bounds. Entry is NOT a cap ladder: it is the
local tangential analysis (3) on the normalization of each divisor
component — after an embedded resolution of the reduced divisor, which
may add boundary components beyond the 17 — admitting only principal
parts compatible with the tangential equation; survivors go to the
whole-cokernel test, then an honestly overdetermined solve. Pro flags
that PfaffInt / IntegrableConnections (Barkatou et al.) are relevant
but not turnkey here.

CONSTRUCTIVE (start in parallel, finishes the physics regardless): the
extension integral — variation of constants on the full row 25,
J_25 = Phi_E [c + Int Phi_E^{-1} B_(25,<) Phi_<] with the six feeder
solutions already canonical. Note for cost estimation: this is
variation of constants over already-certified lower blocks — the shape
our transport stage (Libra) and the ClosedFormSector interface already
implement — so the build is likely small. The deliverable list matches
our stage-4 contract exactly: exact endpoint exponents in eps,
unexpanded (1-w)^(a eps + m)-type modes, log multiplicities, Laurent
depth, boundary constants; no numerical endpoint fits.

Family statement to adopt if the OPEN route also closes: "CF303 has a
certified flat rational connection, canonicalized except for a
specified rational extension row; that row is represented exactly by
its extension integral and endpoint data."

## Priority adjustment (my one disagreement)

Pro puts "characterize kappa_T" first. I would run it as the cheap
FIRST HOUR (it is a small exact computation and the paper's record of
what the obstruction IS), but not let it sequence the two GO routes:
the extension-integral build and the scoping of the local tangential
analysis can start the same day. kappa_T is bookkeeping of an
obstruction we have already proven; the GO routes are the deliverable.

## Corrections this forces on existing plans

- Codex note 05's polynomial-potential compatibility ladder (degrees 3,
  4 within current bounds) is MOOT: the closedness screen is
  target-eliminated, so no choice of closed target changes its verdict;
  only gauge-space enlargement can. Redirect that effort to the local
  analysis above.
- The K3/elliptic direction stays closed pending evidence. The cheap
  once-for-the-record check (genus of the six cubic divisor components)
  is permitted evidence-gathering; any period claim needs
  maximal-cut/Picard-Fuchs support (Pro's standard, endorsed).
- My own prompt's "one-dimensional obstruction" language: corrected as
  in item 4.

## Ordered actions for Codex

1. STOP: deck/third-root candidates, diagonal renormalization, the
   degree-3/4 potential ladder, any "non-closed eps-factorized"
   certificate wording.
2. Convention check (one modular point): nabla_1 F vs the feeder wedge
   sum; then compute and store kappa_T exactly over Q(eps) from the
   small system — the obstruction record for the paper.
3. Scope, then build if cheap: the embedded resolution + per-component
   tangential principal-part analysis; report expected development cost
   BEFORE building (user's standing rule). Candidates ->
   whole-cokernel test -> overdetermined solve.
4. In parallel: the extension-integral representation of row 25 through
   the existing transport / ClosedFormSector machinery, with the exact
   endpoint deliverable list; numerical transport only as validation.
5. Genus of the six cubics, once, for the record.

## Decisions for the user

- Adopt the qualified family statement wording for CF303 (affects the
  paper's claim) if the enlarged-bounds route also closes.
- Approve starting routes 3 and 4 in parallel (both are within the
  assigned block work; 4 reuses existing machinery).
- Fable Max's reply, when it finishes, is cross-checked against this;
  disagreements get flagged, not silently merged.

— Fable, 2026-08-30
