# Explicit endpoint-subtracted density

`AssembleEndpointSubtractedDensity[interior, endpoints, request]` combines the
full ordinary-point Laurent coefficients with finite scalar endpoint
solutions. It produces explicit coefficients of delta derivatives, generalized
plus distributions and the full remainder. Definitions of scalar integrals and
algebraic coefficients are shared with disjoint indices across all inputs.

For each requested epsilon order, the remainder is the full interior function
minus the coefficient of the singular local model. The interior function is
never replaced by a Taylor polynomial. All global prefactors are already part
of the supplied functions; the assembler does not multiply them again.

The inputs must refer to the same physical coefficient file. Their weighted
master identities must cover the full interior density exactly once. Unused
rows needed only for differential closure are excluded from that coverage.
A physical endpoint solution with no singular terms is still needed to establish
that its contribution is locally integrable. If the interior also contains a scalar term outside the master sum, exactly
one endpoint record must include its endpoint contribution and declare
`ScalarRemainderContributionIncluded -> True`.
Missing epsilon coefficients,
unresolved coefficient tails, unknown boundary constants and unscoped integral
references cause explicit failures.

The request specifies `NormalVariable`, `TangentialVariable`, `KinematicRules`,
`Interval`, `ThroughOrder`, `Assumptions`, `TestFunctionDomain` and
`EndpointConditions`. `CoordinateJacobianIncluded -> True` states that the same
coordinate measure was already used in the interior and endpoint inputs.
The coordinate map must not capture a bound integration parameter.

For the current threshold chart, z=1-v-w, the interval is [0,1-v].
`ThresholdCompactSupport` means test functions smooth up to z=0 and compactly
supported away from w=0 and tangential boundaries. The value at z=0 may be
nonzero. Plus subtractions still use the complete interval and preserve all
upper-limit contact moments. No extension at w=0 is asserted.

The output stores `DeltaTerms`, `PlusTerms`, `RegularRemainderCoefficients`,
`InteriorCoefficients`, `SingularModelCoefficients` and their finite combined
`Coefficients`, together with `AlgebraicDefinitions`, `IntegralDefinitions` and
`KernelDefinitions`. The regular coefficients retain full kinematic dependence.
Derivative delta functions and higher-power plus distributions are preserved
until an actual cancellation establishes a smaller basis.

This interface combines established endpoint data. It does not itself prove
that a regulator-dependent reduction pole cancels. In particular, a divisor
z+O(epsilon) invalidates uniform fixed-z coefficient truncation until its pole
part or its cancellation is treated. Such input must not receive the uniform
endpoint conditions just because a generic-point check passed.

The elementary test is `Tests/Coefficients/t_endpoint_subtracted_density.wls`.
It independently integrates a small set of scalar functions and checks the
variable-interval delta moment, the finite plus coefficient, the complete
remainder, normalization, definition indices and missing-input failures.
