# CF300-root rank-2 multiquadratic reconstruction evidence

Date: 2026-08-23 PDT

## Scope

This is a development certificate for the identity-frame multiquadratic
sampler/reconstructor.  It uses a constructed, nonzero scalar strip built
from two roots in the CF300 catalog,
`sqrt(lambda3)` and `sqrt(1-4 x y)`, and an inactive third catalog root.
It is deliberately exercised without a joint rationalizing chart.

It is **not** a certification of the physical CF300 family differential
equation and does not promote any code into `FeynFacet/`.

## Acceptance tests and measured results

`fresh_cf300_rank2_mq_recon_smoke_v10_xh`:

- 23/23 checks passed in 0.71 s mission wall time.
- Exhaustive packed-column bijection on a synthetic 2 x 3 matrix, eight
  root grades and three support monomials.
- Gauge and residue column ranges are disjoint and invalid coordinates are
  rejected.
- Exact integers/rationals are accepted by both modular evaluators;
  symbolic values and modular poles are rejected.
- The constructed oracle has nonzero forcing in all four rank-2 grades.
- Its exact root-channel differential residual is zero.
- A normalized modular sample is full rank and equals the oracle vector.
- Rectangular full-rank, underdetermined-nullspace and inconsistent affine
  systems have the expected typed outcomes and zero residuals where
  applicable.
- Catalog-root reversal and support reversal preserve the ABI fingerprint.

`fresh_cf300_rank2_mq_reconstruction_v1_xh`:

- 18/18 checks passed in 5.90 s mission wall time; reconstruction itself
  took 2.38 s.
- Training primes: `{10007, 10039, 10067}`; epsilon samples:
  `{1/2, 2/3, 3/5}`.
- The 65-component vector reconstructed at rank 65/nullity 0 and is exactly
  equal to the oracle, including all four gauge grades and residue `11`.
- An exact root-channel residual certifies the reconstructed vector.
- Held-out prime `1000003` passes at unseen epsilon values.
- All branch flip masks `0,1,2,3` pass held-out-prime verification.
- Reversing catalog roots and support order preserves the ABI and passes a
  held-out-prime check.
- A seen training prime is rejected.
- Gauge-coefficient and residue corruptions both fail the held-out-prime
  residual; ABI-fingerprint corruption is rejected with the typed status
  `ReconstructionABIMismatch`.

## Defects exposed and fixed in the prototype

1. A line break ended an implicitly multiplied Wolfram expression in the
   packed gauge index, dropping `supportCount + monomial`; grade zero then
   resolved to column zero.  Gauge and residue packers now use explicit
   multiplication.  Other line-broken implicit products in interpolation,
   unpacking and oracle assembly were made explicit as well.
2. `FreeQ[rational, _Symbol]` inspected the head `Rational`, so both modular
   evaluators rejected every nonintegral rational.  They now admit exactly
   `_Integer | _Rational` after `Together` and still reject symbols and
   modular poles.
3. `FirstPosition[row, _?(# =!= 0 &)]` inspected the row head `List` and
   reported pivot position `{0}` for every row, producing impossible ranks.
   The solver now scans indexed columns only and checks pivot uniqueness,
   range and the rank bound before assembling a solution.
4. Exact and modular result verifiers now require the result ABI fingerprint
   to match its preparation fingerprint.

## Remaining boundary before production

- Replace the constructed oracle with an extracted nonzero physical CF300
  off-diagonal block in the identity frame.
- Infer/certify support and normalization data instead of supplying the
  known oracle support and one boundary normalization.
- Exercise a genuine rank-3 system (eight channels/branches).
- Benchmark the modular row build and solve against the rational-chart
  finite-field implementation and the FLINT backend on real blocks.
- Only after those gates should this prototype be adapted to package
  conventions and wired into the family driver.

The exact outputs are `smoke_result.wl`, `multiprime_result.wl`, their logs
and mission status records.  `SHA256SUMS` covers those six artifacts.
