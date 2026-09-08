# Automatic construction of master-integral representations

The momentum-space convention is fixed, not discovered separately for each
master. `ConstructMasterIntegralRepresentations[data,request]` converts the
propagators, integer indices, loop prescriptions and cuts into an explicit
integral representation. `DetermineMasterIntegralExpansionOrders` invokes it
automatically for relevant masters that have neither a supplied representation
nor an assumed Laurent bound.

This is separate from fixing `U(X0)=1` or a Frobenius normalization of the DE.
No boundary constant, master basis or physical normalization is changed.

## Measure convention

The default and currently supported convention is AMFlow's:

- A virtual loop with +i0 contributes `d^D l/(i Pi^(D/2))`.
- A virtual loop with -i0 contributes `-d^D l/(i Pi^(D/2))`.
- Integrated cut particles use the standard Lorentz-invariant phase-space
  measure, including its momentum-conservation delta function.

After eliminating conservation delta functions, the common prefactor multiplying
the remaining momentum integrations and unit-normalized cut delta functions is

```text
(i Pi^(D/2))^(-L_virtual) (-1)^(L_minus)
  (2 Pi)^(c D - n_cut (D-1)),
c = n_cut - L_phase.
```

Here c is the number of independent phase-space conservation constraints.
There is no additional `i Pi^(D/2)` for a phase-space integration variable.
This matches the installed [AMFlow README](../Addon/Mathematica_Addon/AMFlow/README.md)
and its `automatic_phasespace` and `feynman_prescription` examples.

`MeasurePrefactor` records this factor. An optional `MasterIntegralPrefactor`
records an additional explicitly supplied multiplier. For a master vector,
`MasterIntegralPrefactors -> <|row -> multiplier,...|>` supplies these multipliers.
A multiplier is part of the user's definition of the original DE basis.
The builder does not infer one from a desired pole order or change the DE.

The old NLO solved artifact explicitly declares an unnormalized delta-plus
measure without 2 Pi factors. That is a different convention; it must be
converted before comparison to an AMFlow-normalized value. The new builder
does not rewrite that artifact. This difference is holomorphic and nonzero
at epsilon zero, so it does not change Laurent pole bounds.

## Inputs and executable example

```wl
ConstructMasterIntegralRepresentations[
 <|"Topology" -> topology,
   "OriginalMasterIntegralBasis" -> {GLI[family, indices1], GLI[family, indices2]},
   "DimensionalRegulator" -> eps,
   "CutIndices" -> cutSlots,
   "CutMomenta" -> orientedLineMomenta,
   "CutDirections" -> energySigns,
   "Prescription" -> loopPrescriptions,
   "KinematicRules" -> scalarProductRules|>]
```

`TopologyRecord` and a list of `Topologies` are also accepted. Loop prescriptions
can come from `Setup` or canonical-registry `LoopSectorData`; ordinary uncut
integrals default to +i0. Cut integrals require their phase/virtual loop roles.
Family data are selected by the master identifier, not by row position.

Saved family DE and dlog-form records are accepted directly. Their references
supply the canonical topology registry, loop sectors and Kira scalar-product
rules. The source scale normalization and coordinate substitutions are applied.
`InputRoot` defaults to the package root and can be specified for relocated
artifacts. No family name or process kinematics is embedded in the implementation.

`RequestedRows` restricts construction. `BasePoint` evaluates the kinematics,
using the DE coefficient variables, including rationalizing coordinate changes.
The source invariant rules are pulled back before substituting the point.
Integration variables receive fresh symbols.
The output preserves the original master identities, including artifacts whose
GLI head was serialized in a different Wolfram context.

The [two-loop example](../Examples/Transport/master_integral_expansion_orders.wl)
now supplies only momentum-space propagators and the DE. It no longer contains
manually supplied U, F or normalization prefactors:

```sh
wolframscript -file Scripts/Transport/determine_epsilon_orders.wls \
  Examples/Transport/master_integral_expansion_orders.wl /tmp/master-orders.wl
```

The same driver supports `Task -> "MasterIntegralRepresentations"` to save the
representations without determining orders.

## Ordinary-loop representation

`FCFeynmanParametrize` constructs the explicit homogeneous parameter integrand,
Gamma prefactor and parameter list. Negative indices are processed through its
numerator differentiation, not discarded. Common +i0 and -i0 prescriptions
are retained as opposite analytic continuations of the parameter expression.

The order code constructs primary sectors and extracts polynomial powers from
these expressions. It retains numerator cancellations within rational factors.
It does not apply `PowerExpand` across unestablished branches. A sign-indefinite
Feynman polynomial or unresolved interior singularity remains a pole-analysis
failure.

The generated representation is `ProjectiveFeynmanParameters`. The previous
`FeynmanParameters` interface for explicitly supplied U and F remains available,
but is no longer needed for ordinary topology inputs.

## Cut representation

For pure phase space the code constructs a Baikov representation from scalar
products. It completes incomplete denominator coordinates with scalar products,
computes their exact linear Jacobian, and reuses the family Gram polynomial
for every master exponent vector.

Let G be the Gram matrix of E independent external vectors, V the loop-external
scalar-product matrix, and W the loop-loop Gram matrix. In an external span
with one timelike direction the Euclidean transverse Gram matrix is

```text
T = V G^(-1) V^T - W.
```

Writing L for the phase-space loop count, the momentum-space Jacobian is

```text
|det A|^(-1) |det G|^(-L/2)
Pi^(L(D-E)/2 - L(L-1)/4)
 / Product[Gamma[(D-E-j+1)/2], {j,1,L}],
```

multiplying `det(T)^((D-E-L-1)/2)`. A is the linear map from independent scalar
products to inverse-propagator coordinates. This follows from the angular
integration of the transverse vectors (the real Gram-matrix integral).
It is multiplied by the AMFlow measure factor above.

The complete domain requires T positive semidefinite and every oriented cut
energy positive. These inequalities, the external-signature conditions, the
time direction and all pi/Gamma factors are stored explicitly.
`TimeDirection` can specify a future timelike reference; its default is the
sum of oriented cut momenta, assumed future directed. Unsupported/degenerate
external Gram matrices return an explicit construction failure.

For a cut inverse propagator z with positive integer power a, the integrand
contains

```text
(-1)^(a-1)/(a-1)! delta^(a-1)(z).
```

The positive-energy restriction remains in the domain. Nonpositive cut powers
give zero. Unit cuts additionally receive a reduced representation with their
coordinates set to zero.

Repeated cuts remain distributions on the full domain. Differentiating only
the Baikov density and dropping derivatives of the domain would be incorrect.
Fully localized cuts are differentiated when their support is strictly inside
the Gram and energy domain. Positive-dimensional cuts now use the stronger
mass-deformation and convergence argument in
[CutIntegralLaurentBounds.md](CutIntegralLaurentBounds.md), which justifies
the full-domain derivatives before analytic continuation.

The cut/Baikov method is discussed in
[Frellesvig and Papadopoulos](https://arxiv.org/abs/1701.07356) and
[Harley, Moriello and Schabinger](https://arxiv.org/abs/1705.03478).
The implementation stores the physical delta-plus domain rather than replacing
it by an unspecified residue contour.

Massless inclusive phase-space volumes are recognized from their cuts and
momentum routing. Recursive two-body factorization gives the complete Gamma
expression for any supported particle count, including its routing Jacobian.
At D=4 the independent normalization checks are `Phi_2=1/(8 Pi)` and
`Phi_3(s)=s/(256 Pi^3)`.

## Established scope and remaining calculation

The general code constructs ordinary scalar/numerator parameter integrals,
pure-phase-space Baikov integrals, and products of independent real/virtual
integrations. For the latter it constructs a graph of dependencies on loop
momenta using every active denominator and numerator. Disconnected components
factor exactly; sharing an external momentum alone does not couple them.
The resulting `ProductOfIntegrals` contains each factor's integral definition,
cut orientation and measure, with loop-independent factors in the prefactor.
A factor is not assigned a fictitious master identifier.

Pole bounds add across independent factors, including the valuation of the
prefactor. A tadpole times two-body phase space is covered from topology input
through the finite master-coefficient export. A numerator coupling the two
integrations prevents this factorization. Fully coupled real/virtual systems
and mixed virtual prescriptions still require a supported parameter
conversion; their explicit momentum-space definitions remain available.

A constructed representation alone does **not** imply a pole bound.
Compact phase-space integrals now receive a conservative pole-multiplicity
bound when the cut-mass deformation and Gram-boundary conditions are established.
An optional exact dimensional recurrence refines it. Unsupported interior
singularities still return an explicit failure.

All 23 CF269 definitions and their sufficient pole bounds are now automatic.
The dimensional recurrence proves at most triple poles, with two masters
holomorphic at the selected ordinary point. It permits the order planner to
finish without assumed lower bounds. See
[the derivation and reusable interfaces](CutIntegralLaurentBounds.md).
A requested recurrence uses the complete family basis, including lower sectors.

The focused assertions compare a numerator integral with an independent
tadpole identity numerically, check exact two-/three-particle volumes and
mass derivatives, exercise rescalings, and run the automatic path on saved
CF269 data. They do not run IBP reduction, global evolution or AMFlow.
