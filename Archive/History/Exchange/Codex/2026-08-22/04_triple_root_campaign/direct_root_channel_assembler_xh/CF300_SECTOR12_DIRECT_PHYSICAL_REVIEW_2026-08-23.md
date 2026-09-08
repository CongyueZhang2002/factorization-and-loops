# CF300 sector-12 direct-channel physical review

External-only static review; no Wolfram kernel was launched and no package
file was changed.

## Launch verdict

`run_cf300_sector12_a0_direct_comparison.wls` is launch-safe when invoked
with a new, nonexistent output pathname. Reviewed hashes:

- driver: `521d7ae55cae500a0d16246d3299d0d0368ce12439a98219674b14a1add035a7`
- assembler: `227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`

The driver refuses an existing output, writes by atomic non-overwriting rename,
and pins the preparation, dependencies, assembler, driver, recursive
preparation driver, and physical input before/after the run. It requires the
rank-two independent-square-class sidecar certificate.

The legacy assembler selects 21 split points. The direct assembler receives
the same ordered points, must accept all 21 without substitution or reordering,
and produces the `672 x 624` grade-basis system. The driver transforms every
point block to the legacy sign basis and compares the complete matrix and RHS
with `SameQ` after modular dense packing. It also runs a fresh independent
first-point differential. No P0 or P1 correctness defect was found.

## P1 performance-reporting caveat

`AssemblySpeedupExcludingCompilation` is an illustrative end-to-end ratio,
not an isolated hot-path throughput ratio. The legacy numerator includes
split-point search and quadratic-residue rejections. The direct denominator
uses already accepted points after exact channel compilation. This mixes the
finite-field acceptance advantage with row-construction speed. The denominator
still includes source validation, cold prime/epsilon cache fill, point
assembly, and dense materialization. The sign transform is separate and is not
needed by a production grade-basis solve. Do not present the ratio as a pure
kernel speedup or amortized multi-image throughput.

## Fair benchmark design

Run after the oracle and physical exact comparison are green, on the same
frozen preparation at `p=10007`, `eps=1/21`.

1. Generate one deterministic stream of at least 2048 points uniformly from
   `{2,...,p-2}^2`, with a seed bound to ABI, prime, epsilon, and benchmark
   version. This exactly matches the direct sampler's coordinate distribution.
2. In one validated `DRCAAssembleSample` call request the first 256 direct-valid
   points from the explicit stream. This avoids repeated public-boundary
   validation. Classify ordered `PointDeltaValues` by their full Legendre
   character vector.
3. Record raw stream positions of the 21st direct point and 21st all-residue
   point. Their ratio is the common-stream attempt reduction. Record the full
   rank-two character histogram, typed direct rejections, duplicate count, and
   candidate-stream fingerprint. Fail closed if 21 split points are absent.
4. Clear caches and time one cold explicit 21-point direct sample. Warm once,
   then run at least seven warm repetitions on the same points. Report medians
   and MADs of wall, internal total, summed point assembly, validation, epsilon
   collapse, and dense materialization. Report rows/s and matrix entries/s.
5. Repeat warm direct timing on the exact 21 split points used by the physical
   legacy comparison. Time the sign transform separately.
6. Warm and time `TRSplitPointRows` on those same ordered split points with the
   same repetition count. Compare direct-plus-transform against legacy for
   like-for-like sign rows. State explicitly when comparing transform-free
   direct grade rows instead.
7. Keep legacy full-sample time as a distinct end-to-end metric. Put it beside,
   not inside, hot-path ratios. The common-stream attempt ratio then isolates
   the acceptance benefit.

The expected rank-two split penalty is approximately four only under the
independent square-class hypothesis and away from poles and zero root images.
The measured character histogram and typed rejection counts are required
evidence; the expected factor alone is not a benchmark result.

## Minor observations

- Direct automatic sampling excludes `0`, `1`, and `p-1`; a fair common stream
  must use the same `{2,...,p-2}` distribution.
- The point routine rejects `x=0` or `y=0` because its logarithmic derivative
  implementation takes coordinate inverses. This is outside its sampler and
  changes large-prime acceptance only by `O(1/p)`.
- Pole, zero-gauge-denominator, and zero-root images cannot be accepted. Failure
  reason precedence at a multiply singular point is diagnostic only.
- Split physical points certify algebraic equality. Arbitrary/nonresidue
  acceptance needs the separate production benchmark above.
