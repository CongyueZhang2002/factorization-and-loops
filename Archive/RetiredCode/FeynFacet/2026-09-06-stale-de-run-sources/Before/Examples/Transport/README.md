# Master ranges to complete finite solutions

```wl
solution = ConstructMasterIntegralSolution[system,
  <|"RequestedMasterIntegralOrderRanges" -> <|1 -> {-2,0}, 2 -> {-1,1}|>|>];
WriteMasterIntegralSolution[solution, directory, "FileFormat" -> "WXF"];
```

The system supplies its momentum-space topology or saved source references.
This call derives the pole bounds and sufficient epsilon orders, constructs
the finite solution, and stores explicit coefficients in `C[j,m]`. It uses
one ordinary point for the coupled DE, bounds and constants.
See [the full interface](../../Design/FiniteMasterIntegralSolutions.md).

For several independent families:

```sh
wolframscript -file Scripts/Transport/solve_master_integral_families.wls \
  Examples/Transport/pre_stage3_family_solutions.wl \
  ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions
```

[This input](pre_stage3_family_solutions.wl) is a five-family demonstration
with 998 explicit requested coefficients. It is not the current all-family
inventory, and its example ranges do not establish final NNLO demands.
[The subsequent campaign](../../Design/Stage1And2FullCampaign_2026-09-06.md)
regenerated all 91 families. Use [the general production guide](../../Scripts/Transport/README.md)
for coefficient-table requests and concurrent execution.

A general input uses `Families -> <|name -> <|"DataFile"->path,
"Request"->request,"Options"->options|>,...|>`; `Data` can supply the system
directly. The driver resumes equal saved inputs, refuses changed requests in
an existing directory, and continues other families after a failure.

# Sufficient epsilon orders

For the complete workflow starting from a master request and normalized
momentum-space integral definitions, use
`DetermineMasterIntegralExpansionOrders[system,request]`.
It fixes the boundary normalization, derives its pole bounds, and returns
global DE, local matching and boundary coefficient orders before solving
global evolution. See [the workflow and input formats](../../Design/MasterIntegralExpansionOrders.md).

```sh
wolframscript -file Scripts/Transport/determine_epsilon_orders.wls \
  Examples/Transport/master_integral_expansion_orders.wl /tmp/master-orders.wl
```

[The two-loop input](master_integral_expansion_orders.wl) and
[its saved result](master_integral_expansion_orders.result.wl) contain no
supplied pole bound or evaluated boundary coefficient. The input supplies
propagators; U, F and Gamma prefactors are derived by the code.

The individual operations remain available as described below.

Load `Addon/Load/LoadFACET.wl`, or run the general driver from the repository:

```sh
wolframscript -file Scripts/Transport/determine_epsilon_orders.wls \
  Examples/Transport/sufficient_epsilon_orders.wl /tmp/epsilon-orders.wl
```

The example derives bounds for two normalized resolved integrals, propagates
a request through their product and an explicit coefficient, and returns
`I1` through order 1 and `I2` through order 2. No master is evaluated numerically.

## Declaring a calculation

`DetermineEpsilonOrders[calculation]` accepts:

- `DimensionalRegulator`: a symbol. Package-specific copies are normalized.
- `Inputs`: an association from string identifiers to integral-bound records,
  integer lower bounds, or `Missing[...]`.
- `Operations`: associations in dependency order. `LinearCombination` uses
  `Id` and `Terms`, each with `Input` and `Coefficient`. `Product` and
  `Convolution` use `Id` and a list of `Inputs`.
- `RequestedOrders`: output identifiers mapped to an integer upper order or
  a nonempty list of requested orders.

Convolutions must be well-defined epsilon-independent bilinear maps in the
declared function/distribution spaces. Write epsilon-dependent normalizations
as explicit coefficient operations. An amplitude and its complex conjugate
can be separate inputs with the same justified lower bound.

Identical input coefficients are combined exactly before determining orders.
A term can use `CoefficientLaurentLowerBound` instead of `Coefficient` when
only a bound is available. Its use is marked conditional; no coefficient
function is invented. Duplicate terms with only bounds use a conservative
bound on the sum; no cancellation is assumed.

The result contains input/intermediate upper orders, input order intervals,
coefficient expansion orders, and remainder inequalities explaining each
demand. Unknown bounds are reported. Integers are assumptions;
`SufficientForInputRepresentations` applies only to the declared calculation
and supplied integral identities. It does not establish coverage of an
undeclared NNLO assembly.

The existing coefficient-table schema is accepted as:

```wl
DetermineEpsilonOrders[coefficientValuationTable,
  <|"ThroughOrder" -> 0,
    "MasterIntegralLaurentLowerBounds" -> <|1 -> boundForMaster1|>|>]
```

Keys in the bound association are master indices. Omit missing bounds to
obtain preliminary upper orders and an unresolved list. The adapter preserves
master identities and zero columns.

## Deriving integral lower bounds

`DetermineIntegralLaurentBound[representation]` takes `DimensionalRegulator`
and a list of `Terms`. Each term represents an integral over the unit cube:

```wl
<|"IntegrationVariables" -> {x,y},
  "EndpointPowers" -> {-1-eps,-1-2 eps},
  "LogPowers" -> {0,0},
  "RegularFactor" -> 1/(1+x+y),
  "Prefactor" -> Gamma[1+eps]|>
```

The integrand is the prefactor times the regular factor times the specified
variable/logarithm powers, understood by meromorphic continuation. Powers
must be rational functions of epsilon with finite rational limits. The
regular factor must be rational, with a denominator nonzero on the closed
cube at epsilon zero. Elementary positivity arguments are tried first;
a remaining exact real-algebraic proof has a default five-second limit,
adjustable with `"RegularityProofTimeLimit"`. An unestablished condition
returns failure.

Polynomial regular factors are integrated by elementary moments and
combined before taking their valuation. General regular rational factors
use Taylor subtraction bounds. Endpoint poles add within a term; bounds on
a sum of sectors use the minimum. Gamma prefactors and regulator zeros count.

The representation must include the actual master normalization.
Overlapping endpoint factors can now be resolved automatically from polynomial
parameter inputs; primary sectors and Gamma normalization can also be derived
from scalar Feynman-parameter data. See the complete workflow above for formats
and supported domains. Cut definitions are converted to Baikov representations;
general cut-domain pole resolution remains unfinished. See
[automatic construction](../../Design/MasterIntegralRepresentations.md).

## Endpoints and local matching

```wl
DetermineEndpointEpsilonOrders[
  <|"DimensionalRegulator"->eps, "NormalVariables"->{x,y},
    "EndpointPowers"->{-1-eps,-1-2 eps}|>,
  <|"ThroughOrder"->0|>]
```

This returns bulk order 0, face orders 1, and corner order 2, attached to the
appropriate Taylor projections. Higher powers select normal derivatives;
log powers and nonlinear epsilon slopes determine the actual pole order.
An `ExponentMatrix` instead gives entrywise orders from exact moments
`(M+k IdentityMatrix[n])^-1`, with `TaylorOrders` specifying `k`.
Local-expansion completeness, uniform remainders, and matching factors remain
explicit conditions. The routine does not discover physical endpoints.

`DetermineFrobeniusLaurentBounds` takes `NormalVariable`,
`DimensionalRegulator`, and `ConnectionMatrix` for `dZ/dx=connection.Z`.
In a rational frame jointly regular after multiplication by `x`, it computes
the finite resonant prefix of `H` and `H^-1` in `Phi=H x^R`.
Persistent resonances use logarithmic polynomials. The result bounds both
local fundamental matrices without computing global matching functions.
Extra meromorphic normalizations and a uniform ordinary matching path must
be included separately. Default limits are resonance index 64 and 4096
polynomial unknowns.

## Using the bounds in the finite DE solver

`DetermineFundamentalMatrixEpsilonOrders[system,request]` takes
`ConnectionMatrices`, `DimensionalRegulator`, and optional `LeftBasisMatrix`
and `RightBasisMatrix`. The connection must be epsilon-regular with a strictly
lower-triangular zero-order part. Request coefficients of `U=L V R` with
`RequestedCoefficients -> {{row,column,epsilonOrder},...}`.

The result gives entrywise requirements for `V`, the connection and both
basis matrices, closed through all DE dependencies. Shortest paths give
conservative lower bounds. Relations among unknown constants are not assumed.

`ConstructMasterIntegralSolution` uses the same calculation automatically.
Requested original-basis coefficients remain complete finite expressions.
Internal transformed entries above their recorded upper orders are
uncomputed; their placeholders must not be read as zero coefficients. The
verifier observes those bounds. Source and basis series still start from
conservative uniform expansion limits; entrywise finite integration is the
implemented storage/computation reduction.

For automatic integral bounds and explicit master coefficients, use
`RequestedMasterIntegralOrderRanges` as above. The separate
`RequestedMasterIntegralEpsilonOrders` and `InitialConstantLaurentLowerBounds`
interface accepts previously derived integral-bound records or integer
assumptions. These bounds refer to `C(eps)=I(X0,eps)`;
regularity of the prepared DE never supplies a bound on `C`.

The driver supports `Task` values `MasterIntegralExpansion`, `MasterIntegralRepresentations`, `Calculation`, `MasterCoefficientValuations`,
`IntegralLaurentBound`, `FundamentalMatrix`, `EndpointExpansion` and
`FrobeniusLaurentBounds`. Put the input in `Data` and, where applicable,
the order request in `Request`.
