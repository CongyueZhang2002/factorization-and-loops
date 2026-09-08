# Shared constants and physical boundary reduction

The former 1,556 count was a count of family-local ordinary-point series.
It was not a count of independent new boundary integrals.

## Exact substitution in the finite solutions

`FindCutIntegralEquivalences` uses unit-Jacobian affine changes to independent
oriented cut momenta. It preserves the complete powered propagators, cut
orientations, ordinary prescriptions, external kinematics and normalization.
It identifies 355 classes among the 1,561 closed-system positions.

`ConstructGlobalMasterDifferentialSystem` combines their DEs. Repeated equations
give seven further exact integral relations, leaving a 348-integral spanning
system. The identities and differential compatibility are checked at exact
rational points. This is not a proof of minimal IBP rank.

`ReduceMasterIntegralSolutionConstants` applies these relations to the actual
finite coefficient expressions. It propagates Laurent convolutions and reuses
stronger bounds only through exact unit identities at the same point.
It also evaluates elementary phase-space normalizations already supported by
the integral definitions.

The first shared ordinary-point result required 345 unknown series and 2,192
Laurent-coefficient slots, compared with 1,556 and 8,811 before reduction.
This includes fixing the massless phase-space volume analytically.
The CF269 conversion imports explicit lower-sector coefficient expressions at
its other base point. Only their required scalar integral definitions are
imported. Values at different points are never equated.

## A physical bound of dozens

The 345 nonzero requested masters generate a closed 346-dimensional system.
The other two positions in the 348-dimensional system are excluded by exact
derivative-closure checks, not merely because their final coefficients vanish.

At the vanishing recoil-mass boundary, the general code checks 259 eligible
unit-cut masters. Symbolic residue characteristic polynomials and differential
observation tests give at most 84 free meromorphic input series for this
requested system. The known nonzero phase-space volume fixes one scalar sector,
leaving **at most 83 unknown series**.

One raised-cut scalar direction in CF248 remains conservatively unexcluded.
No assumption of its vanishing is made. The theorem and its hypotheses are
given in [the scaling argument](ThreeParticlePhaseSpaceBoundaryScaling.md).

This is an upper bound on free DE boundary data. It is not a claim that 83
new integrals must be evaluated, or that all 83 are independent after
boundary IBP. The old 17/33 type counts do not establish either statement.

## Applied singular-boundary representation

The singular-mode substitutions are now applied to all 91 solutions:
**83 unknown series and 565 required Laurent coefficients**. Full source
terms and generalized eigenspaces are retained, and affected transport
orders have been extended. See
[explicit singular matching](ExplicitSingularBoundaryMatching_2026-09-07.md)
for the finite integral construction, schema 5, storage and validation.

The limiting integrals still need to be identified and reduced. Direct
endpoint collocation is unstable for a tested family; Frobenius endpoint
initialization is the remaining numerical interface. The 83 count is an
upper bound on unknown physical input series, not a minimal boundary-IBP count.

Historical hard-corner evidence is useful: 152 leading hard-region integrals
were reduced to seven boundary masters. It does not prove completeness of the
hard region, cover all higher Taylor targets or include every derivative-closure
integral. Those seven also include an elementary dotted phase-space volume.
It must not be promoted into a complete current boundary answer without matching.

## Earlier ordinary-point solution schema 4

The fundamental-matrix coefficients keep their original family dimension,
recorded by `SystemDimension`. `LocalInitialConstants` describes that old
ordinary-point basis. `MasterIntegralCoefficients` contains the rewritten
finite expressions in the shared `C[j,k]`.

`BoundaryBasis[j]` identifies the original master, its reference point and its
Laurent lower bound. `InitialConstants` describes this shared basis.
`LocalBoundaryCoefficientSubstitutions` records the local row, epsilon order
and the explicit shared expression, without reusing a global constant index
as a local label. `KnownBoundaryValues` contains exact normalization values
and their finite coefficient rules.

The standalone numerical reader continues to evaluate the finite expressions.
A second expansion of an already changed boundary basis is rejected.
