# Triple-root runtime optimization and completion

- [🟢] Replace expanded common-denominator gauge pullback with bounded common
  models.  Real CF259 `(27,11)` improved from 717.0 s to 207.3 s (3.46x).
- [🟢] Vectorize all multiquadratic sign sheets in the active-grade census.
  Real CF259 `(27,9)` improved from 258.8 s to 36.1--36.8 s (about 7.1x).
- [🟢] Parallelize pure deferred-operand materialization while leaving all
  deterministic IDs, factor registration, orbits, and provenance on the
  controller.
- [🟢] Route pathological algebraic materialization tails through Maple with
  opaque declared roots.  The two real 40 MB CF259 operands improved from
  944.9 s and more than 1066.5 s to 15--18 s each; the full 66-helper batch
  now completes in 28.7--31.5 s.
- [🟢] Preserve the declared radical frame across Maple, merge denominator
  valuations after root restoration, fold restored numeric content, and match
  only complete radicands.  Focused suites pass and Pro independently approved
  the corrected algorithm.
- [🟢] Authenticate a deferred bundle once at the outer strip boundary and
  reuse that acceptance only for the exact same `SameQ` association inside the
  synchronous multiquadratic call.  Mutated or different bundles still take
  the full validator.
- [🟢] Replace the deferred zero-placeholder equation's unconditional
  `Together`/`Expand`/`InputForm` pass with a versioned structural E/C seal plus
  the authenticated forcing-bundle identity.  On real CF259 `(27,9)`, the
  later checkpoint identity fell from more than five minutes to 0.0 s.
- [🟢] Separate source-spelling divisor provenance from mathematical pole
  multiplicity.  The old census added negative-power occurrences across
  different `Plus` branches; on CF259 `(27,9)` it reported pole orders up to
  1204 even though canonical operand orders are at most 4.  Exact canonical
  denominator propagation reduces the base gauge from 273,245,832 to 7,488
  unknowns and bidegree `(12,17)`, so no exact-channel refinement is entered.
- [🟢] Compile authenticated deferred operands as their existing exact
  numerator/denominator factor products instead of expanding those products
  into one sparse polynomial.  A guarded local-term compiler reduced the
  largest real CF259 `(27,9)` operand from 168.6 s to 8.9 s (19.0x), while
  exact modular comparison agrees with the source quotient.
- [🟢] Extend the FLINT split-sparse evaluator to the factored `MQSE1P2`
  protocol.  On the complete real 145-leaf CF259 plan, one point fell from
  2.55 s in the Wolfram value evaluator to 0.34 s end to end (0.060 s native),
  with identical `E`, `C`, deferred forcing, and one-form channels.  Release,
  ASan/UBSan, five focused suites, and a real rank-three differential probe
  are green.
- [ ] Add modular univariate denominator refinement only if a correctly
  propagated canonical bound is still too large on a real block.  Both Pro
  and the independent Codex review recommend this as the second-stage
  fallback, not as work to do before the tractable structural bound is tried.
- [🟡] Bank and modularly accept the genuine three-root CF259 `(27,9)` gauge,
  then continue its remaining sector-27 strips from checkpoints.
- [🟡] Screen CF303 complete one-extra-pole quotient shells.  Full f7 and f8
  shells are inconsistent at generic finite-field images; f9--f16 remain.
- [ ] Complete and certify CF259, CF300, and CF303 with production modular
  per-block acceptance and separate final family certification.
