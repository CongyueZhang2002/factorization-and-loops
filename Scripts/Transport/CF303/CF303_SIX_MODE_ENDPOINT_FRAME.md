# CF303 reduced six-mode basis at the path endpoint

Date: 2026-09-03

## Exact normal system

In the physical six-master basis with state-canonical row order

```text
{42,43,40,41,44,45},
```

the homogeneous soft normal residue has only four nonzero entries.  With

```text
A = (1+2 eps)(2+5 eps),
b = 2(1+2 eps),
```

they are

```text
R(4,3)= A/p^2,    R(4,4)= -b,
R(6,3)=-A/p^4,    R(6,4)=  b/p^2.
```

Thus `R=u v^T` is rank one, where

```text
u = e4-p^-2 e6,
v^T = (A/p^2)e3^T-b e4^T,
```

and its only nonzero eigenvalue is

```text
lambda = -2(1+2 eps).
```

The exact spectral projector is `P=R/lambda`; its nonzero entries are

```text
P(4,3)=-(2+5 eps)/(2p^2),  P(4,4)=1,
P(6,3)= (2+5 eps)/(2p^4),  P(6,4)=-p^-2.
```

## Sparse moving basis

Let `c=(2+5 eps)/(2p^2)`.  The columns

```text
z1=e1,
z2=e2,
z3=e3+c e4,
z4=e5,
z5=e6,
n =e4-p^-2 e6
```

form a sparse matrix `V` with determinant one.  The first five columns span
the zero eigenspace and the last is the nonzero mode.  Exactly,

```text
V^-1 R V = diag(0,0,0,0,0,-2(1+2 eps)).
```

The `p` dependence of `V` is essential.  The package API
`TransformTangentialConnectionToNormalResidueEigenbasis` applies

```text
Gamma = V^-1 B_parallel V - V^-1 dV/dp
```

gives a 14-entry sparse tangential connection.  Both cross-eigenspace blocks
vanish identically:

```text
Gamma(1..5,6)=0,    Gamma(6,1..5)=0.
```

The five zero modes and the one nonzero mode therefore evolve
independently.  The scalar nonzero block is

```text
Gamma(6,6) = -1/(1+p) + 1/(1-p) + 4 eps/p
             + 8(1+2 eps) p/(1-2p^2).
```

The integer part of the normal exponent and the epsilon-independent part of
this scalar tangential connection are both removable without touching the
other five modes.  With

```text
J6 = rho^-2 R6 K6,
R6 = 1 / ((1-p^2)(1-2p^2)^2),
```

the normalized mode obeys

```text
d_rho K6 = (-4 eps/rho) K6,
d_p   K6 = eps (4/p + 16p/(1-2p^2)) K6.
```

Thus the unique nonzero normal mode is in simultaneous rational GPL epsilon
form after one integer shear and one scalar rational prefactor.

## Production source basis

The variation-of-constants input uses compact basis transformations rather
than leaving the rational exact-derivative kernels in the source diagonal.
For physical source modes
1 and 2 define

```text
C0  = {{1/[p^2(p^2-1)], 0},
       {1/[p^2(p^2-1)], 1/[p^3(p^2-1)]}},
C12 = C0 . {{1,0},{p eps(3+4eps)/(1+eps),1}}.
```

Then the transformed block is exactly `-2 eps/p I2`.  The exact soft
`rho^0` slice of `TDiagonal.S` differs from `C12` only by the stored
right-hand matrix `M24(eps)`, independent of `p`; this is the accepted
canonical-coordinate binding, not a new basis guess.

For the two block-23 scalar sectors,

```text
g3 = 1/[p^4(p^2-1)]
g6 = 1/[(1-p^2)(1-2p^2)^2]
```

give respectively

```text
-8 eps/p,
eps (4/p + 16p/(1-2p^2)).
```

The accepted normal-residue deck gives the nonzero source mode the same
extension in both `G25` coordinates,

```text
y = -14(-2+13eps-27eps^2+18eps^3)/(eps^3(2+3eps)).
```

which in the `g6` production normalization is
`-1/((1+4eps)(2+3eps)) (1,1)`. The physical `p`-path basis already contains
the source-dependent target behavior, so its ordinary target selectors add
only the two independent zero modes.  This does **not** by itself identify
the raw `F25=T25^-1 I25` columns at the path endpoint with `G25`: that conversion must
contract the principal and finite local deck of `H` against the source
Frobenius jets.  The junction record keeps the known `G25` extension and the
independent `F25` columns separate and marks the full target map incomplete.

The resulting `ProductionInput` contains:

- a four-mode source epsilon-form operator on `0` and the quadratic factor
  `1-2p^2`;
- the accepted two-mode target epsilon form on `0,1,-1`;
- six exact rational-in-`eps,p` incoming entries, with the fourth source
  column declared exactly zero;
- constant 4-by-6 source and 2-by-6 target boundary selectors for the four
  source modes and two independent target modes, without double-counting the
  extension already present in the nonzero basis vector.

A bounded call to
`SolveRationalEpsilonDependentBlockByVariationOfConstants[...,
"PrepareOnly"->True]` accepts this record with dimensions `{2,4}` and shared
boundary coordinates. No dense 45-by-45 connection is involved.

The full symbolic-path-endpoint calculation is also exercised, not only
prepared. For requested outputs `{{0,1},{0,2}}` it used three reconstruction
primes plus a fresh validation prime, reconstructed six nonzero rational
functions in the off-diagonal basis-transformation block at epsilon order
zero, and produced a validated solution and lazy iterated-integral
coefficient operator. The reference build took about `0.05 s` after package
load; the off-diagonal basis-transformation block, solution, and coefficient
operator occupied about `3.1 KB`, `37.7 KB` and `26.3 KB`, respectively.
Exact machine values and primes are stored in
`ProductionInput["FullRunEvidence"]`.

## Junction to the accepted z-path operator

`ProductionInput["AcceptedZPathJunction"]` supplies the exact local source
mode map in the accepted 43-row order.  It is supported only on source
positions `{34,35,36,37}`, corresponding to state rows `{40,41,42,43}`.
The junction is

```text
p = pFinal,  z = 2 pFinal,  rho = 2p-z -> 0
```

with a tangentially regularized prescription.  Direct substitution into the
accepted z-path operator's 293 selectors is invalid: those selectors live at
the regular base `z=1/2`, whereas the junction is singular.

The smallest connector should consume a junction record with:

1. the exact 43-by-N source mode map and 2-by-N target-mode data at the soft
   limit, including the local exponents and root-sign/direction prescription;
2. an accepted interior coefficient operator that can return a requested
   source or target iterated-integral coefficient without enumerating every
   letter sequence;
3. the symbolic off-diagonal basis-transformation coefficients, evaluated
   locally only after their principal and finite terms are multiplied by the
   required source Frobenius jets;
4. the original Stage-3 coordinate keys, carried through unchanged.

Its operation is a tangentially regularized, order-by-order triangular solve
for the 293 base constants at `z=1/2`, followed by the existing lazy z-path
action. If `Z_q[l_z]` is a requested z-path iterated-integral coefficient,
`J_r` the regularized junction solution, and `P_s[l_p]` a p-path
iterated-integral coefficient, the composed sparse coefficient
is

```text
sum_(q+r+s=n) Z_q[w_z] . J_r . P_s[w_p].
```

The key should remain the ordered pair
`{pPathLetterSequence,zPathLetterSequence}`. Expanding this product into a
sum of iterated integrals on a concatenated path is unnecessary and can cause
combinatorial growth. The connector must preserve the six (later
inherited-extended)
Stage-3 boundary-coordinate keys instead of exposing the intermediate 293
regular-base constants as new physical boundary constants.

The accepted z adapter already exposes the needed requested-output interface:

- source rows through `masterTransportCanonicalChenWordCoefficient` on its
  embedded 43-row source operator;
- final rows through `cf303HybridBaselineCanonicalWordCoefficient` or
  `cf303HybridBaselinePhysicalWordCoefficient`;
- standard GPL/eMPL leaves through
  `cf303HybridBaselineResolvedPhysicalWordTerms`.

What remains genuinely missing is the regularized junction solve, especially
the full local `F25 -> G25=F25-H F_source` contraction and the inherited
source modes.  A generic connector should require these as typed inputs; it
must not silently treat `z=2p` as an ordinary base-point evaluation.

## Accepted final-block basis transformation

The accepted path-endpoint value of the physical-to-canonical
master-integral map acts only on zero modes 4 and 5. In the recorded
convention

```text
I25 = T25 F25.
```

The rational-epsilon-dependent block solution subsequently writes
`F25=G25+H F_source`;
at its base point `H=0`, so `F25` and `G25` share boundary constants.

the basis `V . diag(I3,T25,1)` remains separated into the same `5+1` normal
eigenspaces.  Its lower-right zero-sector block is exactly

```text
eps {{-(-3-2p+6p^2)/((p-1)p(p+1)),
       (-1+4p)/(2(p-1)(p+1))},
     {2/((p-1)(p+1)),
      -(-3+2p+4p^2)/((p-1)p(p+1))}}.
```

The epsilon-zero part vanishes identically.  Its alphabet is only
`{0,1,-1}`; the three constant residue matrices multiplying
`{1/p,1/(1-p),1/(1+p)}` are stored in the artifact.  Hence this target block
is rational GPL epsilon form after the already accepted `T25`, not elliptic.

## Rational/GPL kernel decomposition

The complete `Gamma` is reconstructed exactly from seven rational kernels:

| kernel | role | primitive |
|---|---|---|
| `1/p` | GPL letter 0 | `log p` |
| `1/(1-p)` | GPL letter 1 | `-log(1-p)` |
| `1/(1+p)` | GPL letter -1 | `log(1+p)` |
| `p/(1-2p^2)` | quadratic dlog | `-1/4 log(1-2p^2)` |
| `1/p^3` | exact rational derivative | `-1/(2p^2)` |
| `1/p^5` | exact rational derivative | `-1/(4p^4)` |
| `p` | exact rational derivative | `p^2/2` |

Consequently the transcendental alphabet is only

```text
{0,1,-1,1/sqrt(2),-1/sqrt(2)}.
```

The last three kernels generate rational prefactors and introduce no new
transcendental functions.  All coupling matrices are independent of `p` and
rational in `eps`; their maximum numerator/denominator degrees are `2/1`.
The exact sparse coupling records are in
`Artifacts/CF303SixModeEndpointFrame.wl`.

This kernel census describes the exact connection in the normal-residue
eigenbasis; it is not a
claim that the entire five-dimensional zero sector is already in one pure
epsilon-form basis. Its exact-derivative coupling matrices need not commute
with the dlog matrices.  The isolated nonzero mode and the accepted `T25`
target block are epsilon normalized as stated above; inherited particular
forcing and any remaining rational-epsilon-dependent block normalization are
separate steps.

## Construction and control

`build_cf303_six_mode_endpoint_frame.wls` reads only the already reduced
`CF303PhysicalSoftSixSystem.wl` and calls the package's public
normal-residue-eigenbasis API. On the reference run, construction of the
residue, projector, basis, and
`Gamma` took 0.007 seconds; exact seven-kernel decomposition and recomposition
took 0.010 seconds.  No 45-by-45 object and no subkernel is used.

`Controls/t_cf303_six_mode_endpoint_frame.wls` independently recomputes the
normal residue and `Gamma` from the six-mode source artifact.  It checks the
rank-one spectral identities and independently calls
`TransformTangentialConnectionToNormalResidueEigenbasis`, requiring the
expected exponent sectors
`{{1,2,3,4,5},{6}}`, integer/regulator spectrum
`{0,0,0,0,0,-2}+eps {0,0,0,0,0,-4}`, the stored `Gamma`, vanishing cross
blocks, exact kernel recomposition and primitives, and the rational-epsilon
coefficient contract. It also rebuilds the accepted target basis through the
public API, checks the exact `T25` epsilon form, and checks the simultaneous
normal/tangential normalization of the nonzero scalar mode.  Finally it
rebuilds the production basis and requires the public
rational-epsilon-dependent block preparation to accept its exact source,
target, incoming, and boundary data.
