# CF300 split-sparse plan: physical speed result

Timestamp: 2026-08-27T17:32:51-07:00

The provider/prime positional plan is now validated on the physical CF300
`(12,9)` image and through the focused package gate.  This is a general
two-variable, rank-zero-through-three provider optimization; no family name
appears in `FeynFacet/Private`.

## Correctness gate

- `t_multiquadratic_bundle_provider`: 17/17
- eight-suite focused pool: 8/8 suites green, including reconstruction,
  promotion, follower-image, real-pair, constrained-plan, and installed-family
  integration tests
- planned and historical unplanned sampling produce the identical finite-field
  matrix/RHS ABI in the focused fixture

The only implementation defect found was in a boundary-only expression-hash
validator: `HoldComplete` prevented an association lookup from evaluating.
It was fixed with one lexical insertion.  No hash or cache lookup remains in
the point-level plan hot path, and no further defensive fingerprint machinery
should be added.

## Physical timing

Baseline image before this change:

- complete image: 182.927 s
- coefficient evaluation: 171.678 s
- repeated split compile/cache calls: 136.634 s
- 7,659 calls for 207 occurrences at 37 accepted points

After this change, same prime and random point schedule:

- cold first fibre: 57.832 s, including 23.137 s plan construction
- warm second fibre: 35.270 s
- warm coefficient evaluation: 23.460 s
- unique-leaf arithmetic: 22.374 s
- row assembly: 8.285 s
- preflight: 3.411 s
- occurrence gathering: 0.0028 s
- deferred-bundle composition: 1.032 s
- 148 unique leaves, 207 occurrences, 5,476 leaf evaluations, zero fallbacks

This is a 5.19x recurring-image speedup and a 3.16x cold-image speedup.  The
repeated cache/hash cost has been eliminated rather than merely shortened.

## Next largest target

Native batch evaluation is now justified by measurement.  The 22.374 s leaf
phase is 63% of a warm image.  The dominant active-root group has 68 leaves
with 409,146 numerator/denominator term occurrences but only 11,023 distinct
monomials, a 37.1x monomial-reuse opportunity.  The next implementation should
therefore batch the finite-field polynomial arithmetic in a small native
backend, share powers/monomials across leaves, and return grade channels.  It
should use exact channel equality against the current Wolfram evaluator as its
acceptance test, without adding hashes, nonces, or metadata replay.

Physical artifacts:

- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_image_profile_20260827/profile_result.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_image_profile_20260827/profile_fixture.wxf`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_image_profile_20260827/split_plan_2147483423.wxf`
