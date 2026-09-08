# Mathematical terminology

The names below describe the mathematical objects computed by the live
package. Historical exchanges are evidence of earlier work, not definitions
of the current interface.

## Differential systems and blocks

Write `dI = A I`, with `I = T J` and
`A_J = T^-1 A T - T^-1 dT`. “Original basis” refers to the supplied master
integral list. “Physical region” and analytic continuation require separate
kinematic and branch data.

`DiagonalBlocksInCurrentBasis` means strongly connected components of the
dependency graph, ordered to make the connection block lower triangular.
This is a decomposition under permutations of the supplied basis, not a
claim of irreducibility under arbitrary basis transformations over a field.

## Integration kernels, residues, and epsilon form

For `A = Sum_i C_i omega_i`, the `C_i` are kernel coefficient matrices.
They are pole residues only when the kernels and their local normalizations
make that identification valid. For `A = eps Sum_i R_i dlog(phi_i)`,
the constant matrices `R_i` are the coefficients of the dlog forms;
the actual residue at a divisor includes epsilon and the orders of the
letters there.

For a smooth quartic curve `Y^2 = P4(u)`, `du/Y` is a holomorphic
differential. Its coefficient can be nonzero while its residues vanish.
The general elliptic reduction therefore uses `KernelCoefficientMatrices`,
`OffDiagonalKernelCoefficientMatrices` and
`ExactKernelCoefficientDecomposition`. These names make no dlog claim.
The rational and elliptic variation-of-constants equations are unchanged.

In the local Frobenius routine,
`EpsilonNormalizedConnectionResidue = R = Res(A/eps)`.
The full residue is `eps R`, and the solution is
`H(rho,eps) rho^(eps R) c`.
The general `ComputeConnectionResidueAtLocalExpansionPoint` instead returns
the residue of exactly the one-form supplied: it inserts no epsilon factor.
The block-triangular residue routine places the normalized diagonal residues
at epsilon order one.

## Rationalization and square roots

`FactorFamilyRegulatorDependenceInCoefficientPresentation` names the supplied
coefficient presentation explicitly. A missing catalogue entry is
`NoCataloguedRationalizingParametrization`.
`RegulatorFactorizationUnsuccessful` is an unsuccessful construction and
retains the catalogue result and square-root solver result separately.
Neither status is a geometric nonexistence theorem.

`RootCount` counts declared generators; `ParityComponentCount` counts their
formal square-root monomials. `ParityComponentMatrices` are coefficients of
those monomials. A parity index is not an epsilon order. Square-class
independence is an additional property, and a root count is not a matrix rank.

Three independent square roots give a degree-eight extension of the base
field, not a degree-three cover, and do not imply K3 geometry. For example,
sqrt(x), sqrt(y), sqrt(1+x) are rationalized by
`x=(t-1/t)^2/4, y=s^2`. Geometry depends on the actual radicands.

## Local solutions and matching

`BuildSingularPointMatchingData` records the relation between local solution
bases at a singular point. In the variation-of-constants convention
`FTarget = G + H FSource`, G is the transformed target block.

- `SourceModeCoefficientMatrices` and
  `TransformedTargetModeCoefficientMatrices` store Laurent coefficient
  matrices indexed by epsilon order.
- `LocalSolutionToBoundaryCoefficientMatrices` recover boundary
  coefficients from regularized local solution coefficients, with both
  epsilon orders recorded.
- `SingularPointMatchingEquationValidatedThroughFirstLocalOrder`
  reports a check at normal-coordinate orders zero and one, not an
  all-orders identity.
- `ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint` preserves
  the two distinct path-segment letter sequences.

A “jet” is a legitimate finite-order local expansion, but reports should
state its variable and retained orders. Use those explicit descriptions
instead of “deck”, “target-G map”, or “intertwining-jet evidence”.

## Valuations and validation

`ValidateBasisTransformationEpsilonValuationsAtRationalPoints` computes exact
univariate epsilon orders at rational kinematic points. It uses neither
p-adic lifting nor finite-field arithmetic. Exact sample arithmetic does
not make agreement a proof of the generic valuation; the certificate retains
`Probabilistic -> True, Exact -> False`.
The requested epsilon orders of master integrals remain separate from
basis-transformation valuations.

## Saved records

New producers and consumers use the names above without public aliases.
For saved Wolfram records, use
`Scripts/DifferentialEquations/update_mathematical_terminology.wls`
with an explicit record kind, input and output path. The updater writes a
new copy, refuses existing outputs, preserves the original, and does not
claim to revalidate the mathematics. Apply the appropriate current validator
after conversion. References are preserved; update explicit input paths
when selecting the converted records. Historical and pre-V2 records remain
historical and are not promoted to V2 by this operation.

Supported conversion kinds are `block-decomposition`, `local-frobenius`,
`kernel-solution`, `singular-point-matching`, `basis-valuations`, and
`root-parity`. For example:

```sh
wolframscript -file Scripts/DifferentialEquations/update_mathematical_terminology.wls \
  --kind block-decomposition --input /absolute/path/old.wl \
  --output /absolute/path/new.wl
```

The converter handles these standalone mathematical records, not an arbitrary
process-specific bundle. Rebuild such bundles with their updated producers.

The old lazy-transport launchers and public aliases are retired. The
[production guide](../Scripts/Transport/README.md) names the current commands.
Conversion of an archived record does not make its retired interface executable.

## Literature

- [Henn, lectures on differential equations for Feynman integrals](https://arxiv.org/abs/1412.2296):
  master-integral bases, epsilon form, and iterated integrals.
- [Gituliar and Magerya, Fuchsia](https://arxiv.org/abs/1701.04269):
  basis transformations and block-triangular systems.
- [Broedel, Duhr, Dulat and Tancredi, elliptic iterated integrals](https://arxiv.org/abs/1712.07089):
  elliptic integration kernels and their singularities.
- [Besier and Festi, rationalizability of square roots](https://arxiv.org/abs/2006.07121):
  geometric rationalizability depends on the defining polynomials.

## Verification, 2026-09-05

The 27 affected and integration Wolfram tests passed, including explicit
counterexamples distinguishing graph connectivity from differential
irreducibility and a holomorphic elliptic kernel coefficient from a residue.
The exported-interface test and the CF303 singular-point matching control
also passed, giving 29 distinct Wolfram test files. All five CF303 Python
tests passed. Each of the six conversion kinds preserved its source and
refused an existing output. No full-family physics regeneration was performed.

The [2026-09-06 audit](Stage1CostsAndEpsilonFormCriteria_2026-09-06.md)
separates fixed-target integrability incompatibility, finite transformation
ansatz failure, and nonexistence under arbitrary admissible bases. Distinct
constant residues on different geometric components are not varying residues
along one component.
