# Mathematical terminology

These conventions describe the mathematical objects in the current framework.
Interface availability is defined by the loaded package and
[the production guide](../Scripts/Transport/README.md). Historical names are
recorded in [the earlier terminology revision](../Archive/History/Design/MathematicalTerminology_2026-09-05.md).

## Differential systems and bases

Write `dI = A I`. For `I = T J` the transformed connection is
`A_J = T^-1 A T - T^-1 dT`. The original basis is the supplied master-integral
list; a basis transformation is distinct from a kinematic change of variables.

`DiagonalBlocksInCurrentBasis` describes strongly connected components of the
dependency graph, ordered to make the connection block triangular. This is a
decomposition under permutations of the supplied basis. It does not prove
irreducibility under arbitrary basis transformations over a specified field.

Canonical integral families are representatives under momentum relabeling and
the declared cut conventions. Epsilon-form canonicalization concerns the
differential equation. These are different operations.

## Integration kernels, residues and epsilon form

For `A = Sum_i C_i omega_i`, the `C_i` are kernel coefficient matrices.
Calling them pole residues requires specifying the kernels and their local
normalization. For `A = eps Sum_i R_i dlog(phi_i)`, the actual residue at a
divisor includes epsilon and each letter's vanishing or pole order there.

A holomorphic elliptic differential can have a nonzero coefficient while all
its pole residues vanish. An exact decomposition into integration kernels
therefore does not establish dlog form or epsilon form.

A sampled inconsistency rules out the tested ansatz under the stated
conditions. It is not a general theorem that epsilon form is impossible.
A statement about nonexistence must specify the coefficient field and allowed
basis transformations. [The criteria audit](Stage1CostsAndEpsilonFormCriteria_2026-09-06.md)
distinguishes these conclusions.

## Square roots and rationalizing parametrizations

`RootCount` counts declared square-root generators; `ParityComponentCount`
counts their formal square-root monomials. A parity index is not an epsilon
order, and a root count is not matrix rank. Square-class independence is an
additional mathematical property.

Three independent square roots give a degree-eight extension, not a
degree-three extension. This does not determine the geometry of the associated
variety. Rationalizability depends on the radicands. A missing catalogue entry
or unsuccessful search does not prove non-rationalizability.

## Finite solutions, orders and boundary data

A finite solution through specified epsilon orders contains the explicit
coefficient expressions, their scalar integral definitions and their
dependence on initial constants. A routine that generates coefficients on
demand is not itself that stored solution.

The constants are independent of kinematics; their numerical or analytic
physical values are separate data. For an ordinary base point X0, they are
related to the value of the chosen solution basis at X0. At singular points,
one instead needs local asymptotic data, branch choices and a matching
convention. A local Frobenius expansion alone is not a connection matrix
between different local solutions.

The epsilon valuation is the lowest nonzero epsilon power. A Laurent bound is
a bound on that valuation. Requested output orders, the orders needed during
DE evolution, and the orders needed for boundary coefficients are distinct.
Exact arithmetic at a few rational kinematic points does not by itself prove
a generic valuation.

General regularized singular matching and continuation in the finite-solution
format remain unfinished. The old coefficient-map composition interfaces and
saved-record terminology converter are retired; no compatibility aliases are
part of the production path.

## References

- [Henn, lectures on differential equations for Feynman integrals](https://arxiv.org/abs/1412.2296)
- [Gituliar and Magerya, Fuchsia](https://arxiv.org/abs/1701.04269)
- [Broedel, Duhr, Dulat and Tancredi, elliptic iterated integrals](https://arxiv.org/abs/1712.07089)
- [Besier and Festi, rationalizability of square roots](https://arxiv.org/abs/2006.07121)
