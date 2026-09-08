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

- [ ] Persist one full sealed elimination-plan sidecar after support
  selection, then resume it before RREF only after fresh preparation/support
  identity checks and one constrained all-row modular sample. Current prime
  artifacts retain only the plan fingerprint and rank/normalization identity,
  which is insufficient to reconstruct the constrained core.

- [ ] If real pullback fitting remains material after the homogeneous solve,
  derive candidate bidegrees from generic slice LCMs before considering an
  exact source-channel fallback.
