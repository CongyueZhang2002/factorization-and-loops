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
- [🟢] Remove the repeated Wolfram all-original-row residual replay from
  native constrained follower images.  CFFA4 already solves and verifies its
  fixed core exactly; production acceptance remains the independent
  fresh-point full provider residual after reconstruction.  On the real
  CF259 `(27,9)` payload the deleted replay was still running after 10 min per
  image, while the streamlined cold image completed in 122.17 s: 69.41 s
  sampling, 33.13 s FLINT solve, and 0 s replay.  Commit `043bb2d` is pushed;
  focused suites pass 26/0, 12/0, 18/0, and 12/0.
- [ ] Add modular univariate denominator refinement only if a correctly
  propagated canonical bound is still too large on a real block.  Both Pro
  and the independent Codex review recommend this as the second-stage
  fallback, not as work to do before the tractable structural bound is tried.
- [🟡] Bank and modularly accept the genuine three-root CF259 `(27,9)` gauge.
  A clean 8-subkernel run resumed 17 banked strips and is solving only this
  final block with the streamlined follower path.  The support ladder adopted
  `(3,3)` after 3,332.2 s; the reconstruction has nullity 69, uses 19 regulator
  images per prime, and had accepted three primes by 13:49.  The fourth prime
  is in progress.
- [🟢] CF300 is complete; do not restart it during the CF259/CF303 endgame.
- [🟡] Resolve CF303 `(25,18)`.  Fixed-divisor constant-residue dlog and the
  degree-3/4 exact-potential ladders are closed.  The complete E1 system is
  now proven inconsistent at a generic modular image (`rank 7528`, augmented
  rank `7529`).  Broad `f09--f16` pole-shell solves are rejected because their
  projections only saturate the old cokernel.  The bounded constructive route
  is the complete-row variation-of-constants extension integral, whose feeder
  identity passes at two independent generic images after reconstructing the
  authoritative target from the accepted gauge.  The exact negative-proof
  route is coefficient-space curvature reduction over `Q(eps)`.
- [ ] Promote the already-native split-provider path to a tested 61-bit prime
  schedule.  Row assembly and sparse channel evaluation already use FLINT
  `nmod`, and a physical CF300 image measured 3.804 s at 61 bits versus 3.848 s
  at 31 bits with exact rows/RHS.  The remaining work is a physical adaptive
  interpolation/CRT/lift gate, not a new assembler.  Require at least 1.5x
  complete-reconstruction improvement; leave the legacy compiled-channel
  `<2^31` compatibility port off the triple-root critical path.
- [ ] Complete and certify CF259, CF300, and CF303 with production modular
  per-block acceptance and separate final family certification.
