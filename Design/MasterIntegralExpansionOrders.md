# From boundary normalization to sufficient expansion orders

`DetermineMasterIntegralExpansionOrders[system,request]` performs the complete
order determination for its supported integral representations. It fixes
the normalization, derives pole bounds, and returns separate orders for
global evolution, singular-point matching and boundary coefficients.
It does not construct global evolution or evaluate boundary coefficients.

## Executable two-loop example

```sh
wolframscript -file Scripts/Transport/determine_epsilon_orders.wls \
  Examples/Transport/master_integral_expansion_orders.wl /tmp/master-orders.wl
```

The example supplies a two-loop differential equation and momentum-space
propagators, with requested master orders -2 through 0. The parameter
representation and Gamma factors are now derived automatically.
It supplies no pole bound and no known integral value. The result derives a
double pole, requests global evolution through order 2 and boundary
coefficients at orders -2, -1 and 0. The order calculation took about
0.032 seconds in the recorded run, excluding package loading.

[Input](../Examples/Transport/master_integral_expansion_orders.wl) and
[saved finite result](../ppHX_NNLO_DoubleReal/Results/Examples/MasterIntegralExpansionOrders/result.wl).

## Inputs

The differential system uses `KinematicVariables`, `DimensionalRegulator`,
`ConnectionMatrices` and optionally `BasisTransformationMatrix` and
`InverseBasisTransformationMatrix`, with the convention `I=T J`.
An existing `FamilyDLogEpsilonForm` record is also accepted directly.
The original master basis determines row numbering and representation identity.

The request contains:

```wl
<|"BasePoint" -> {1/4},
  "RequestedMasterIntegralOrderRanges" -> <|1 -> {-2,0}|>,
  "BoundaryNormalization" -> <|
    "Type" -> "Frobenius", "NormalVariable" -> x, "SingularPoint" -> 0|>,
  "MasterIntegralRepresentations" -> <|1 -> representation|>|>
```

Each pair specifies an inclusive range. Different rows can have different
ranges. An omitted base point is chosen from deterministic rational candidates
that satisfy `BasePointRegion` and the ordinary-point conditions. The candidate
list also checks the supported physical cut domain using the actual coefficient
coordinates. Reversed coordinate tuples are included: a fixed ordering can
otherwise miss the physical region of a rationalizing chart.

One coupled DE system has one shared point, rather than independent points for
its masters. Independent systems can have different points. An explicit
boundary/request point takes priority; otherwise a unique saved dimensional
recurrence point is used before the system default or automatic selection.
Conflicting saved recurrence points are rejected.
`BasePointSelection` records these checks and explicitly states
`BoundaryEvaluationCostOptimized -> False`. This admissibility search is not a
boundary-cost or conditioning optimization. A supplied
singular point is rejected as an ordinary base point. Integration parameters
must differ from kinematic variables.

Representations are definitions of the indicated original master, including
all normalization factors. Their kinematics are evaluated at the selected
ordinary point before deriving a bound. Optional `MasterIntegral` identities
are checked against the original basis. Only relevant coupled components
require representations. The automatic builder resolves topology and kinematic references in saved
DE records. A bare identifier with no associated integral definition is still
insufficient. See [automatic integral representations](MasterIntegralRepresentations.md)
for measure conventions and supported conversions.

An explicit `MasterIntegralLaurentLowerBounds` association can substitute for
integral definitions, but this remains a supplied assumption. A requested
lower order is never silently used as a pole bound.

## Independent pole bounds from integral definitions

Normalized unit-cube inputs contain `Terms` with `IntegrationVariables`,
`EndpointPowers`, optional `UpperEndpointPowers`, `LogPowers`, `RegularFactor`,
`Prefactor` and `PolynomialFactors`. Each polynomial factor is an association
with `Polynomial` and `Exponent`. Exponents may depend rationally on epsilon.
The polynomial bases are epsilon-independent.

Upper endpoints are moved to zero by exact half-interval subdivisions.
Overlapping singularities are resolved by sector substitutions, with the
Jacobian, endpoint exponents, logarithms and coordinate maps retained.
Monomial factors determine the possible epsilon poles. Regular polynomial
units are checked for nonvanishing. Explicit epsilon factors in rational
numerators/denominators are moved into the prefactor.

The scalar Feynman-parameter input additionally constructs primary sectors
and the Gamma normalization from `FeynmanParameters`, positive integer
`PropagatorPowers`, `LoopCount`, `SymanzikPolynomials -> {U,F}`,
`Dimension` (default `4-2 epsilon`), and a required `NormalizationPrefactor`.
The convention is the Euclidean scalar measure
`product_l d^D k_l / Pi^(D/2)` before that prefactor. The homogeneity of U
and F is checked.

The parameter measure and sector substitutions follow the standard formula
and changes of variables in [Bogner and Weinzierl, sections 2–3](https://arxiv.org/html/0709.4092v2).
The implemented subset selection is bounded; it makes no unconditional
termination claim. Every successful result contains the complete resolved
terms. A resolution limit or an unestablished regularity condition returns
no pole bound.

A cut integral must use its cut/phase-space parameter representation.
The uncut scalar Feynman-parameter formula rejects declared cut propagators.
Ordinary topology inputs, including numerator powers, are converted automatically.
Pure phase-space inputs receive explicit cut Baikov representations.
Compact physical domains now receive pole-multiplicity bounds from the
mass-deformation argument, with an optional dimensional-recurrence refinement.
Unestablished convergence hypotheses and interior singularities return no bound.
See [CutIntegralLaurentBounds.md](CutIntegralLaurentBounds.md). Upper-endpoint powers together with logarithms currently require
an explicit subdivision in the input.

## Fixed ordinary and singular normalizations

Ordinary normalization is `C(epsilon)=I(X0,epsilon)` in the original master basis.

For singular normalization, all tangential coordinates are fixed at their
ordinary-point values. A positive inward normal coordinate rho is chosen.
The definition is

```text
I = G(rho,epsilon) Phi(rho,epsilon) S(epsilon) b(epsilon)
Phi = H(rho,log(rho),epsilon) rho^R(epsilon),  H_0 = identity.
```

Thus b denotes constants at a definite tangential point, not functions on an
unspecified boundary surface. G defaults to the prepared DE basis, which can
avoid unnecessary resonant poles. `LocalBasisTransformationMatrix` and
`BoundaryNormalizationMatrix` can specify G and S explicitly.

A finite Frobenius calculation derives pole bounds for Phi and its inverse.
Entrywise bounds are closed through the regular connection and residue.
This prevents a pole in one off-diagonal entry from being assigned
automatically to every diagonal entry. The fixed normal matching segment is
checked for uniform epsilon regularity. Moving singularities or poles on the
segment prevent a successful matching bound.

At the ordinary point, `C=M b` with `M=G(X0) Phi(rho0) S`. Bounds on both M
and its inverse therefore give a lower bound on b from the independently
derived lower bound on C. No global solution or actual matching coefficient
is needed for this step.

## Determining all expansion orders

Let `ell_j` bound the leading power of C_j and `u_ij` bound that of the
original fundamental matrix U_ij. For a master target through N_i,

```text
U_ij through N_i - ell_j;
C_j  through max_i(N_i - u_ij).
```

The bounds on U follow from the known basis transformations and weighted
paths in the prepared DE. Requests for U are then closed through every
potentially contributing DE coefficient and basis convolution.

For singular normalization, let `t_i` be the required order of C_i,
`m_ij` the bound on M_ij and `ell_bj` the derived bound on b_j. Then

```text
M_ij through t_i - ell_bj;
b_j  through max_i(t_i - m_ij).
```

The result also includes orders for Phi, H, exp(R log(rho)), the residue,
the regular connection and both normalization matrices. Expanding rho^R
can consume residue coefficients beyond those required by a direct
coefficient recurrence for Phi; these orders are included explicitly.
The resonant prefix is retained exactly, avoiding a circular request for
its epsilon precision.

These are sufficient bounds. Unknown relations among boundary constants
are not used to claim smaller orders.

## Results and limits

`BoundaryCoefficientOrders` contains each component's lower bound, pole-order
bound, upper order and explicit required list. `FundamentalMatrixEpsilonOrders`
contains the entrywise global evolution/connection/basis requirements.
`LocalBoundaryEpsilonOrders` contains the local matching requirements.
`IntegralBoundRecords` preserves the complete mathematical derivation inputs.

To both determine orders and solve the requested master coefficients, pass
the same `RequestedMasterIntegralOrderRanges` request directly to
`ConstructMasterIntegralSolution[system,request]`. It uses the exact entrywise
requirements, preserves this order report, and exports the finite convolution
into ordinary-point constants. No manual conversion to a uniform U range is
needed. Unrequested U entries are explicitly uncomputed, rather than zero.

`PreparedDifferentialSystem` retains the smaller source connection and its
exact basis transformation for coefficient-wise epsilon expansion.
`EvolutionConstructionRequests` remains available for direct per-row U
construction; its uniform column limits can be less economical.

Frobenius-normalized order determination remains available here. The integrated
finite master export currently uses ordinary-point constants; a singular
normalization needs an explicit matching matrix before that export can
express coefficients in the singular constants.

`SufficientOrdersDetermined` means sufficient for the declared master
requests and integral definitions. Missing definitions return
`AdditionalIntegralDataRequired` with the relevant master identities.
Supplying the saved CF269 epsilon form constructs its 23 definitions and
bounds automatically. With the saved dimensional recurrence at (1/4,1/3),
targets through the finite term for all original masters require prepared
evolution through epsilon^4 and master-dependent boundary orders through
at most epsilon^3. The bounds are derived from the integrals and recurrence,
not inferred from NNLO or from the requested lower order.
The request can supply `DimensionalRecurrence`, a list in
`DimensionalRecurrences`, or `CutPoleBoundMethod -> "DimensionalRecurrence"`
with `DimensionalRecurrenceOptions` to construct the recurrences.

Fifty focused assertions cover the complete workflow, including an independent
Gamma-function result, a two-loop integral, endpoint resolution, epsilon-pole
basis changes, local resonance, rescaling of boundary constants and executable
finite-evolution requests. Existing order and finite-solution tests pass.
