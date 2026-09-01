# Reconstruct the CF303 exception transport modularly

## Replace symbolic materialization

- [x] 🟢 Feed the authoritative factorized deferred forcing directly to finite-field evaluators; do not construct the giant symbolic direct-`u` expressions in production.
- [x] 🟢 Reconstruct the rational and residual-root channels pointwise over a 61-bit prime, then perform rational and quartic Hermite reduction over the same finite field.
- [x] 🟢 Match the accepted block-2 symbolic primitive and remainder, and match the independent block-1 path-jet reduction coefficient by coefficient.
- [x] 🟢 Make selected-sheet scalar sampling the production route.  Block 1 now takes about 1.81 s at one `(prime,p,epsilon)` image instead of more than 2,531 s for one unfinished symbolic entry.
- [x] 🟢 Replace small consecutive `u` images by reproducible generic modular images, eliminating systematic collisions with moving path divisors.

## Reconstruct the reduced coefficients

- [x] 🟢 Reconstruct all 148 reduced block-1 coordinates in epsilon at fixed `(prime,p)`: 17 construction images plus two complete held-out reductions, with maximum epsilon total degree 16.
- [x] 🟢 Census the generic p dependence: 135 construction images plus four complete held-out images, 288 coordinates, maximum p total degree 127, and one genuine `p=4` degree-drop image.
- [x] 🟢 Replay the known p profiles with the bulk FLINT fixed-profile interpolator.  The 288-coordinate lift takes 0.0275 s instead of 15.08 s in the scalar Python discovery loop.
- [x] 🟢 Run the resumable nested `(p,epsilon)` lift at the first 61-bit prime and discover the p profiles of the epsilon-polynomial coefficients.  The accepted q1 artifact has 2,540 flattened coordinates, maximum p total degree 127, and four complete held-out p images; degree discovery took 12.27 s.
- [ ] 🟡 Replay those fixed profiles at additional 61-bit primes, combine by CRT, and rationally lift the scalar coefficients to `Q`.
- [ ] 🟡 Accept the exact lift at an unused prime with unused `(p,epsilon,u)` images; production acceptance is modular and pointwise, not a giant symbolic equality.

## Use the available cores efficiently

- [x] 🟢 Raise the bounded nested sampler from eight to sixteen active native cores without changing its mathematical contract or cache keys.
- [x] 🟢 Benchmark the complete 19-image fixed-p stage: `4 x 4` takes about 8.8 s, `8 x 2` takes 8.38 s, and `16 x 1` takes 9.57 s.  Use `8 x 2`; sixteen independent single-thread jobs are slower.

## Finish the physical transport

- [ ] 🟡 Assemble the exact basepoint-normalized path gauge `F25 = G25 + H L` from the reconstructed primitives and the already accepted exception blocks 2, 11, 14, and 18.
- [ ] 🟡 Use the corrected forcing valuation `-3`: the path-gauge coefficient window is `epsilon^-3..epsilon^4`, and source boundary coefficients extend through order 5 for target output through `epsilon^2`.
- [ ] 🟡 Build the complete 45-master weighted GPL/eMPL operator, convolve the physical block-25 source gauge, and export selected paper-facing coefficients on demand.
