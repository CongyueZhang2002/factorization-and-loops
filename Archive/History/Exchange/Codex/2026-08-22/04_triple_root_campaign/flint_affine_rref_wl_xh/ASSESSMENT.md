# Native affine-RREF external pilot assessment

Status: external implementation complete; managed-pool Wolfram syntax/runtime
still required. No Wolfram kernel was launched while authoring these files, and
no package, prototype, preparation, physical driver, or live process was
modified by this work.

The native protocol and the Wolfram consumer agree on `CFFR1V1/CFFR1X1`.
Acceptance is not based on the native exit code alone. The adapter binds exact
dimensions, modulus, flags, payload length, EOF, and a nonzero 128-bit nonce,
then independently proves the affine and nullspace residuals, canonical RREF
basis, row-minor inverse witness, normalization-minor inverse witness, and the
production residue-first normalization preference. The V1 constructor also
binds the certificate request to the exact assembled sample matrix and RHS.

The production-shaped path has two roles:

- Discover: a bounded epsilon prefix is probed natively. Native exit code 5 is
  a typed `InconsistentAffineImage`, not an infrastructure failure. The
  earliest maximum-rank consistent probe constructs
  `CrossPrimeEliminationPlanV1`; every other usable image uses the existing
  fixed-plan `flint_modular_solve` path with fallback disabled.
- Reuse: every usable candidate image uses that same fixed plan and fixed FLINT
  path.

Both roles retain and exclude bad image records only if at least
`ConstructionCount+4` stable samples remain, require exact all-row particular
and nullspace residuals, call the existing `InterpolateEpsFormStripAffine`,
enforce the degree profile, and emit `RationalAffinePrimeInterpolated`. The
single native prime driver handles both roles, so discover and reuse artifacts
carry one driver path/hash. A reuse run independently re-verifies the stored
native request/certificate and reconstructs the origin V1 plan with `SameQ`
equality before sampling.

The rejected first physical attempt established that `p=10007`, `eps=1/21`
is an inconsistent modular image for this preparation. The revised physical
benchmark therefore scans `{10007,10039,10067}` across a bounded epsilon list,
requires consistent witnesses at two distinct primes, and benchmarks the
earliest maximum-rank consistent image at 1, 2, and 4 threads.

Pinned native implementation:

- C source SHA256:
  `11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd`
- `flint_affine_rref` SHA256:
  `e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5`
- existing fixed-plan `flint_modular_solve` SHA256 at authoring time:
  `e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b`

External Wolfram source hashes at the final static checkpoint:

- adapter: `4474e56ce63f6150e77593f8ac41710dac7ab2cd6d351f15dd42775a83fa237e`
- native prime module:
  `9f8de21255c74286d8bec4ebd33ff62fd98591e4855f6277a28b10b7a1de310b`
- production driver:
  `26a753dc3f2767d1a072ddb1376b909fffe9a09cfc89f6a1080d5be477e66194`
- physical 1/2/4-thread benchmark:
  `4f4e27ab51e512afab573a53e616c2c0bc87d2ab0c1b759f61261997c2bc5af8`
- differential/adversarial smoke:
  `46a31cb023a398a268adc01924dd7884652c797808e72c9ca817dd60db98d32a`

The static and delimiter suite passes 110/110. The corrected managed-pool
differential run passed 70/70 with empty captured load and runtime message
streams; the earlier nominal pass with loader messages remains rejected.
Runtime order should be:

1. managed-pool syntax/load and randomized differential smoke;
2. bounded cross-prime/epsilon physical probe followed by the selected-image
   benchmark at 1, 2, and 4 native threads;
3. one 48-candidate Discover artifact with the production driver (the count is
   configurable and is no longer an exact-success requirement);
4. two 48-candidate Reuse artifacts using that immutable Discover artifact;
5. the current aggregate and its exact/unseen/all-branch terminal checks.

The preparation must be freshly generated under the exact current core
dependency hashes. The older preparation retained only for workload measurement
is intentionally rejected by the provenance gates.

One limitation is explicit: the current aggregate knows the ordinary core
dependency, common-plan, degree-profile, and source-artifact contracts, but it
does not have native-specific schema checks for the additional binary hashes and
pilot evidence. Each native prime artifact enforces those fields itself, reuse
re-verifies the origin certificate/plan, and the aggregate's exact original PDE,
unseen-prime, and all-branch checks remain the terminal defense. A future package
integration should teach the aggregate the native-specific fields before this
path becomes the default.

Independent xhigh review found no P0/P1 blocker. Three P2 limitations remain:
reuse algebraically re-verifies persisted request/certificate/plan evidence but
does not reassemble the physical pilot; some redundant evidence fields are not
cross-bound even though every plan-affecting field is; and the physical
benchmark reports the four-epsilon candidate set while its genericity maximum
is over the actually executed bounded prefix, which normally stops after the
first epsilon round satisfies the two-prime floor.
