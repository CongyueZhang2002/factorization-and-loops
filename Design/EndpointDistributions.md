# Finite regulated endpoint distributions

`FeynFacet/Coefficients/Distributions.wl` implements
`DetermineEndpointDistributionOrders[data,request]` and
`ExtractEndpointDistributions[data,request]`. It loads after
`Solutions/Orders/LaurentBounds.wl` and `Coefficients/EndpointOrders.wl`.
The first function reports sufficient orders before explicit coefficients
are computed. The second requires those coefficients and returns a finite
Laurent expansion. Neither function supplies missing coefficients.

## Declared representation

The input is a sum of scalar terms on the dimensionless interval `0<z<Z`:

    P(epsilon) z^(a+b epsilon) Log[z]^p A(z,epsilon),
    A(z,epsilon) = Sum[z^r A_r(epsilon), {r,0,N-1}]
                   + z^N R(z,epsilon),
    N = Max[0,Floor[-a]].

Tangential variables, channel/color labels, and kinematic functions in the
coefficients remain symbolic. The amplitude decomposition is a supplied
identity on the admitted normal domain; a local expansion alone does not establish
it. The closed interval is the default. The explicit half-open threshold mode
described below permits a singular upper endpoint excluded by the test support.
The bound `rho` on `R` means every coefficient and the omitted epsilon tail
are uniformly bounded by a finite power of `Abs[Log[z]]` times `z^rho` as
`z` tends to zero. The strict inequality `a+N+rho>-1` is required. Other
singularities on the interval must have been excluded. The same statements
must hold on the declared tangential domain. An interval ending at another
unresolved singularity does not satisfy the contract.

`a` is rational, `p` is a nonnegative integer, and `b` is independent of
`z` and epsilon. When `a<=-1`, the assumptions must prove `b!=0`.
The analytic continuation is from epsilon values for which the integral
converges at zero. Noninteger negative powers are supported with the same
continuation. An integrable power needs no nonzero regulator slope.

The data association has these keys:

```wolfram
<|"DimensionalRegulator" -> eps,
  "Variable" -> z,
  "Interval" -> {0, 1-v},
  "Assumptions" -> 0<v<1,
  "EndpointConditions" -> <|
    "NoOtherSingularities" -> True,
    "UniformEpsilonExpansion" -> True,
    "RepresentationValidOnInterval" -> True|>,
  "Terms" -> {<|
    "Power" -> -1-2 eps,
    "LogPower" -> 0,
    "Prefactor" -> 1,
    "TaylorCoefficients" -> <|0 -> finiteAmplitude|>,
    "Remainder" -> finiteRemainder,
    "RemainderEndpointPowerLowerBound" -> 0,
    "Labels" -> <|"PartonicChannel" -> "ud", "ColorStructure" -> color,
                  "PerturbativeOrder" -> 2|>
  |>}
|>
```

`LogPower`, `Prefactor`, and `Labels` default to `0`, `1`, and `<||>`.
For `N=0`, `TaylorCoefficients` is empty and `Remainder` is the entire
amplitude. For `N>0`, every Taylor coefficient from zero through `N-1`
is required, including explicit zero records. There are no symbolic limits
of an unspecified amplitude function. The input itself supplies the Taylor
data and the remainder identity.

All finite epsilon records use the same representation:

```wolfram
<|"LaurentLowerBound" -> -1,
  "KnownThroughOrder" -> 1,
  "Coefficients" -> <|-1 -> cMinus1, 0 -> c0, 1 -> c1|>,
  "ExactInEpsilon" -> False|>
```

Every integer key in the declared range is mandatory. Coefficients are
finite expressions independent of epsilon. `LaurentLowerBound` asserts
that all lower orders vanish; it need not be the tight valuation.
`ExactInEpsilon -> True` asserts that every higher coefficient vanishes,
so a finite Laurent polynomial can satisfy arbitrarily high requests.
It does not excuse holes inside the declared range. An empty coefficient
range is allowed when `KnownThroughOrder == LaurentLowerBound-1`.
Without exactness, it means only an unknown tail at the lower bound.
With exactness, it represents zero.

Taylor coefficients and prefactors must be independent of `z`.
Remainder coefficients may contain `z`, including integrable logarithms
and symbolic functions whose supplied bounds apply. Symbolic finite
special-function definitions may be retained; coefficient generators,
`SeriesData`, missing values, and regulator-dependent coefficient values
are rejected. Any stored definitions must be available to the consumer.

`Prefactor` accepts a finite epsilon record or an exact expression handled
by the existing Laurent valuation planner, including rational expressions,
supported Gamma factors, exponentials, and epsilon powers of nonzero bases.
An exact expression must also admit an explicit finite `Series` result.
Unsupported meromorphic expressions should be supplied as finite records.
Context-specific `eps`, `ep`, and `Epsilon` symbols are normalized by name.

Both public functions take `request = <|"ThroughOrder" -> q|>` for an
integer target `q`. Planning requires the lower/known-order metadata for
each amplitude and finite prefactor, but does not read its coefficients.
Extraction checks every declared coefficient range and every required
upper order before returning a result. Missing orders produce a `Failure`
with the affected term/component and required upper order.

## Distribution convention and finite-interval moments

The measure is `dz`. All physical Jacobians, fluxes, scales, and
normalization factors must already be explicit in the input. The inert
head `EndpointDeltaDerivative[z,j,Z]` has full endpoint normalization:

    <delta^(j),f> = (-1)^j f^(j)(0).

It does not inherit the half-weight convention that a library integrator
might assign to an ordinary `DiracDelta` at an integration boundary.

`EndpointPlusDistribution[z,c,k,n,Z]` denotes the generalized plus
prescription

    Integral_0^Z dz z^c Log[z]^k
      (f(z) - Sum[z^j f^(j)(0)/j!, {j,0,n-1}]).

The Taylor polynomial is subtracted over the entire interval. `Log[z]`
uses the positive real, dimensionless coordinate. There is no implicit
rescaling to `Log[z/Z]` or hidden factorization scale. For a singular
monomial with `c=a+r`, `n=N-r` guarantees local integrability after
subtraction. Its delta-derivative coefficient is

    (-1)^j/j! M_p(a+r+j+1+b epsilon,Z),
    M_p(t,Z) = d^p/dt^p [Z^t/t].

For `t=b epsilon` the Laurent series is

    (-1)^p p!/(b epsilon)^(p+1)
      + Sum[(b epsilon)^k Log[Z]^(k+p+1)/(k! (k+p+1)), {k,0,...}].

All other delta moments are regular at epsilon zero and follow by
ordinary derivatives of `Z^t/t`. Thus the familiar unit-interval
formula is recovered for `a=-1,p=0`:

    z^(-1+b epsilon) = delta(z)/(b epsilon)
      + Sum[(b epsilon)^k/k! [Log[z]^k/z]_+, {k,0,...}].

On `[0,Z]` the delta coefficient is `Z^(b epsilon)/(b epsilon)`.
For higher powers, nonresonant moments also contribute finite delta
coefficients; omitting them would change the chosen finite-interval
prescription.

## Sufficient orders and returned coefficients

Let `nuP` be the prefactor Laurent lower bound. For integral `a<=-1`,
every required amplitude Taylor coefficient can multiply an endpoint
moment of order `epsilon^(-p-1)`. Its sufficient upper order is
`q-nuP+p+1`; the remainder needs only `q-nuP`.
For noninteger `a`, the endpoint moments have no pole at zero and both
upper demands are `q-nuP`. The prefactor demand is the maximum of
`q-nuA+p+1` for resonant Taylor terms and `q-nuR` for the remainder,
with the pole shift omitted for nonresonant powers. These demands are
conservative if a coefficient is identically zero; they do not assume
cancellations between separate terms.

The existing `DetermineEndpointEpsilonOrders` result is retained in each
term plan as `EndpointProjectionOrderPlan`. Additional finite-interval
moments do not increase its worst pole order. Required prefactor,
individual Taylor, and remainder upper orders are explicit in
`TermRequirements`. The guarantee is conditional on the supplied uniform
bounds, exact amplitude identity, and physical prefactors.

Extraction returns `DataType -> "FiniteEndpointDistributions"`, the
interval and conditions, `ThroughOrder`, and
`OmittedEpsilonOrderLowerBound -> q+1`. `Terms` retains each input term's
`Labels`, `DeltaTerms`, `PlusTerms`, `RegularRemainder`, complete finite
`Coefficients` association, and `Expression`. Each delta/plus record has
its own finite epsilon coefficient association. Distinct amplitude
Taylor terms can contribute to the same delta derivative; the total
coefficient is their sum. `Components` groups identical `Labels` and
contains the explicit summed coefficients for each channel/color/order.
`OrderRequirements` records the complete sufficient-order plan.

No total NNLO coverage is inferred (`PhysicalNNLOCoverageInferred ->
False`). This code does not add absent real-virtual, virtual, coupling,
PDF, or fragmentation counterterms.

## Scope and verification

Only one resolved scalar endpoint is implemented. Multiple normal
variables, non-single endpoint geometry, and unhandled overlaps return
`Failure["UnresolvedMultipleEndpoints",...]`. Tensor products, coupled
endpoint sectors, endpoint coordinate changes, and matrix exponentials
must be resolved upstream. Finite symbolic coefficient functions remain
valid on their supplied tangential domain; this does not establish
uniformity as that domain approaches a second endpoint.

`Tests/Coefficients/t_endpoint_distributions.wls` checks full delta
normalization on unit and variable intervals, generalized plus terms and
delta-derivative signs, logarithmic pole orders and separate coefficient
demands, Gamma and finite prefactors, rational/symbolic remainders,
noninteger/integrable powers, and explicit failures for insufficient
orders or endpoint assumptions. Two small test-function integrals compare
with independently integrated elementary moments and a rational-amplitude
identity. The checks require no AMFlow, IBP reduction, or master solving.
## Explicit half-open threshold domain

The default `TestFunctionDomain -> "SmoothOnClosedInterval"` preserves the
stricter full-interval assumptions above. When the upper endpoint is another
physical singularity, select this different domain explicitly:

```wolfram
"TestFunctionDomain" -> "ThresholdCompactSupport",
"EndpointConditions" -> <|
  "NoInteriorSingularities" -> True,
  "UniformEpsilonExpansionOnCompactSubsets" -> True,
  "RepresentationValidOnHalfOpenInterval" -> True|>
```

The domain is `v` in the declared open tangential patch and `0 <= z < Z(v)`.
Tests are smooth up to `z=0`, may have nonzero value there, and have compact
support away from `z=Z(v)` and the tangential patch boundaries. The remainder
need only belong to `L1_loc([0,Z))`, locally uniformly on compact tangential
subsets. In particular, a remainder proportional to `1/(Z-z)` is admissible
under these explicit conditions; no distributional extension at `z=Z` is
asserted. The default closed-interval mode does not accept this replacement
set of assumptions without the explicit domain selection.

The plus prescription still subtracts the test-function Taylor polynomial
over **all of `[0,Z]`**. The delta moments and logarithm conventions are
unchanged. Although a test vanishes near `Z`, its subtracted Taylor polynomial
does not: the plus-integral tail beyond the test's support must be retained.
A cutoff-weighted plus integral with the same delta moment would be incorrect
without its finite compensating term. The constant test function on all of
`[0,Z]` is not admissible in this half-open mode.

For the current recoil coordinate, `Z(v)=1-v` excludes the observed collinear
boundary `w=0`. This represents the bare coefficient at the threshold on the
stated half-open domain; it does not assert joint corner integrability or a
fully integrated bare cross section. `DomainConvention` records these facts
in the order plan and extracted result.

## Joint normal-crossing endpoints

`ExtractEndpointDistributions` and `DetermineEndpointDistributionOrders` also
accept `EndpointGeometry -> "NormalCrossings"`, `NormalVariables -> {u,r}`,
and `Intervals -> {{0,U},{0,R}}`. Each term supplies `Powers`,
optional nonnegative `LogPowers`, and a `SmoothFactor` that is exact in epsilon
or has explicit finite Laurent coefficients and known-order metadata.

The supported exponents have epsilon-zero power -1 or greater than -1.
Each singular direction is subtracted once. All endpoint restrictions commute;
the interior remainder is `(1-E_u)(1-E_r)F`, with the intersection restored once.
Corner, edge and interior terms receive distinct epsilon requirements.
Output uses the same `EndpointDeltaDerivative` and `EndpointPlusDistribution`
objects as the one-variable engine, with finite explicit coefficients.

The caller must supply joint smoothness, uniform epsilon expansion and absence
of other singularities. A nonfinite face/corner restriction is rejected.
Coupled singularities require resolution into charts before this entry point;
these declarations do not perform or certify that resolution.
`EndpointDistributionAction` evaluates the resulting tensor product against a
smooth test function and rejects multiplication of two distributions on one
variable. Mass-factorization convolution remains a separate operation.

The physical-result adapter for this tensor basis is still pending.
Tests: `Tests/Coefficients/t_tensor_product_distributions.wls`.
