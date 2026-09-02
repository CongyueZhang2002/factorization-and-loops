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
- [x] 🟢 Complete six 61-bit images.  The expanded all-orders lift was correctly rejected: five construction primes plus a sixth-prime oracle recover only 4,794 of 66,381 numerator coefficients.
- [x] 🟢 Test the finite Laurent deck before adding primes.  It removes the unnecessary global epsilon reconstruction but still leaves 54,105 of 94,525 expanded coefficients unresolved.
- [x] 🟢 Move the cancellation boundary to the finite path gauge.  The first nontrivial post-gauge profile reaches p-degree 203 and resolves only 6,839 of 12,643 coefficients under the 305-bit modulus, establishing that expanded coefficients are the wrong exact representation.
- [x] 🟢 Encode block 1 as a 138-node exact arithmetic circuit over the original exact deferred input, the finite Laurent selector, and the fixed Hermite recurrence.  All 16 rational `delta H/delta K` records are exposed lazily.
- [x] 🟢 Accept the block-1 circuit pointwise: 15,024/15,024 rational comparisons across q1--q7 and two fresh q7 p-points, plus 476/476 fresh checks for the exact elliptic remainder/cohomology channel.

## Use the available cores efficiently

- [x] 🟢 Raise the bounded nested sampler from eight to sixteen active native cores without changing its mathematical contract or cache keys.
- [x] 🟢 Benchmark the complete 19-image fixed-p stage: `4 x 4` takes about 8.8 s, `8 x 2` takes 8.38 s, and `16 x 1` takes 9.57 s.  Use `8 x 2`; sixteen independent single-thread jobs are slower.

## Finish the physical transport

- [x] 🟢 Implement a real block-1 circuit point resolver.  At both fresh q7 points it resolves all 16 rational/elliptic records, matches 1,878 rational source-replay coefficients per point, and checks the elliptic polynomial quotient against the independently lifted three-component cohomology profile.
- [x] 🟢 Compress the lazy circuit ABI from 384 per-power incoming labels to 32 composite labels (16 rational plus 16 elliptic); expand numerator powers and quartic cohomology letters only for requested physical words.
- [x] 🟢 Replace the failed all-at-once 88-entry symbolic recurrence by a provenance-sealed deferred exact circuit.  Two q7 points pass 1,376 recurrence, 1,376 basepoint, and 6,160 final `T25` channel comparisons in 76.03 s total with 128,452 KiB peak RSS.
- [ ] 🟡 Assemble the complete lazy path gauge from the 76-entry base, the accepted block-2/11/14/18 censuses (12 entries), and the two block-1 circuit entries.  Keep both baseline and block-1 circuit coefficients lazy; do not reconstruct the expanded characteristic-zero `H/K` matrices.
- [x] 🟢 Use the corrected forcing valuation `-3`: the path-gauge coefficient window is `epsilon^-3..epsilon^4`, and source boundary coefficients extend through order 5 for target output through `epsilon^2`.
- [ ] 🟡 Bind the accepted baseline circuit to the existing 45-master weighted GPL/eMPL operator ABI, then export selected paper-facing coefficients on demand.  The recurrence and all three physical `T25` orders already pass at both q7 points; the remaining work is lazy composition, not another symbolic recurrence.

## Prepare the remaining transport campaign

- [x] 🟢 Install and validate the minimal CUDA 13.0 compiler/runtime without replacing the working NVIDIA driver; the exact GPU31 evaluator passes rank-0/rank-3 CPU comparisons.
- [x] 🟢 Measure the GPU boundary honestly: it is useful for heavy finite-field batches, but not for short ordinary transports or the tiny fixed-p CF303 gauge recurrence.
- [x] 🟢 Implement an eight-slot dynamic family scheduler and fix its parser for Wolfram's quoted TSV manifests.
- [ ] 🟡 Run the 88 ordinary exact epsilon-form families in one licensed main plus eight reusable subkernels, then handle CF300 and CF259 through their special algebraic/modular routes.  The ordinary queue is active; completed artifacts are written atomically and the pool refills dynamically.
- [ ] 🟡 Remove the tautological symbolic reconstruction in algebraic entry-kernel assembly, retry `BoundarySubspaceNotInvariant` once with the variable order reversed, and rerun only the affected families after the active pool drains.
