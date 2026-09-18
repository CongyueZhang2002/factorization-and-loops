# Distributions from a proved interior and inclusive moments

For a kernel f on(0,1) with z(1-z)f in L1, define

    IntervalFinitePart[f,{z,0,1}][phi]
      = integral_0^1 f(z) [phi(z)-(1-z)phi(0)-z phi(1)] dz.

The complete coefficient kernel is used inside this integral; separately
integrating divergent GPL summands is invalid. Zeroth and first moments vanish.
If a regulated calculation proves that the remaining endpoint ambiguity contains
only ordinary deltas, its two generated inclusive moments fix the contacts:

    S = IntervalFinitePart[f,{z,0,1}]
        + (m0-m1) delta(z) + m1 delta(1-z).

`CompleteUnitIntervalDistributionFromMoments` consumes explicit Laurent rows,
physical moments, and the uniform regulated contact proofs. The one-loop
producer binds those proofs, moments and GPL rows to the same source definition.
It accepts constant generated moment weights; other weights require their own
weighted inclusive calculation and are rejected by the current producer.
No observable-specific coefficient or assumed equality of contacts is inserted.

The shared partonic result format uses DistributionBasis Representation
`UnitIntervalFinitePart`, row fields `FinitePartKernel`, `Variable`, and
`DeltaCoefficients`. This is distinct from the ordinary `UnitInterval`
delta/logarithmic-plus/regular basis. Mixing these bases without conversion
fails. Constant weighting, addition, interior restriction and moment extraction
are supported. A nonconstant multiplier is rejected by the row-map interface
because multiplying just the kernel would omit the induced contact shifts.
To convert a standard unit-interval row, retain its full interior and compute
its zeroth and first moments in the ORIGINAL convention first.

The finite part is a defined distribution, not a deferred integral evaluator.
Its kernel and both contacts are explicit in the saved file. No claim that the
finite-part kernel is an ordinary integrable regular coefficient is made.
The full contact/meromorphy justification is retained in actual Pro review14:
External/ChatGPT/Records/2026-09-18/14_inclusive_scalars_and_distribution_completion.md.
