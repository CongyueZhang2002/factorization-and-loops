# Projective pullback and resumable plan goals

- [x] 🟢 Replace per-normalization denominator fitting by one homogeneous
  modular nullspace solve.

- [x] 🟢 Normalize the projective relation at an actually nonzero denominator
  coefficient, including denominators with zero constant term.

- [x] 🟢 Stop retrying denominator-model inconsistency at larger kinematic
  caps; only retry `SliceDegreeExceeded`.

- [x] 🟢 Verify the change on the pullback suite and CFFR backend suite.

- [ ] 🟡 Measure the real CF259 (27,11) before/after post-prime pullback wall
  time in the active v42 campaign.

- [ ] 🟡 Run the fresh-simplex discriminator and conservative gauge recovery
  on CF303 (25,18), then identify whether any recovered factor is a missing
  gauge denominator or a missing letter.

- [ ] Resume a sealed elimination plan from compatible per-prime artifacts
  before support discovery, so an interrupted post-prime stage does not
  recompute the expensive RREF.

- [ ] If real pullback fitting remains material after the homogeneous solve,
  derive candidate bidegrees from generic slice LCMs before considering an
  exact source-channel fallback.
