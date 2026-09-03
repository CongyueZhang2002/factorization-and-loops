# CF303 reduced six-mode endpoint frame

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

## Sparse moving frame

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
`BuildEndpointLeveltModeConnection` applies

```text
Gamma = V^-1 B_parallel V - V^-1 dV/dp
```

gives a 14-entry sparse tangential connection.  Both cross-eigenspace blocks
vanish identically:

```text
Gamma(1..5,6)=0,    Gamma(6,1..5)=0.
```

The five zero modes and the one nonzero mode therefore transport
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

## Production source frame

The transport input uses compact gauges rather than leaving the rational
exact-derivative kernels in the source diagonal.  For physical source modes
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

The exact canonical nonzero source mode extends into both accepted target
coordinates by the same coefficient

```text
y = -14(-2+13eps-27eps^2+18eps^3)/(eps^3(2+3eps)).
```

In the `g6` production normalization, this is
`-1/((1+4eps)(2+3eps)) (1,1)`.  It is encoded in the nonzero normal-mode
frame itself, not added again as an independent target boundary selector.
The selectors therefore contain six shared constant boundary coordinates:
four source modes followed by two independent target zero modes.  The
resulting `ProductionInput` contains:

- a four-mode source epsilon-form operator on `0` and the quadratic factor
  `1-2p^2`;
- the accepted two-mode target epsilon form on `0,1,-1`;
- six exact rational-in-`eps,p` incoming entries, with the fourth source
  column declared exactly zero;
- constant 4-by-6 source and 2-by-6 target boundary selectors for the four
  source modes and two independent target modes, without double-counting the
  extension already present in the nonzero frame column.

A bounded call to `BuildRationalEpsilonLayerTransport[...,"PrepareOnly"->True]`
accepts this record with dimensions `{2,4}` and shared boundary coordinates.
No dense 45-by-45 connection is involved.

## Accepted final-block gauge

The accepted endpoint specialization of `PhysicalGaugeByOrderPairs` acts
only on zero modes 4 and 5.  In the recorded convention

```text
I25 = T25 F25.
```

The rational-layer path gauge subsequently writes `F25=G25+H F_source`;
at its base point `H=0`, so `F25` and `G25` share boundary constants.

the frame `V . diag(I3,T25,1)` remains separated into the same `5+1` normal
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

This kernel census describes the exact Levelt-frame connection; it is not a
claim that the entire five-dimensional zero sector is already in one pure
epsilon-form gauge.  Its exact-derivative coupling matrices need not commute
with the dlog matrices.  The isolated nonzero mode and the accepted `T25`
target block are epsilon normalized as stated above; inherited particular
forcing and any remaining rational-layer normalization are separate steps.

## Construction and control

`build_cf303_six_mode_endpoint_frame.wls` reads only the already reduced
`CF303PhysicalSoftSixSystem.wl` and calls the package's public Levelt API.
On the reference run, construction of the residue, projector, frame, and
`Gamma` took 0.007 seconds; exact seven-kernel decomposition and recomposition
took 0.010 seconds.  No 45-by-45 object and no subkernel is used.

`Controls/t_cf303_six_mode_endpoint_frame.wls` independently recomputes the
normal residue and `Gamma` from the six-mode source artifact.  It checks the
rank-one spectral identities and independently calls
`BuildEndpointLeveltModeConnection`, requiring the expected exponent sectors
`{{1,2,3,4,5},{6}}`, integer/regulator spectrum
`{0,0,0,0,0,-2}+eps {0,0,0,0,0,-4}`, the stored `Gamma`, vanishing cross
blocks, exact kernel recomposition and primitives, and the rational-epsilon
coefficient contract.  It also rebuilds the accepted target frame through the
public API, checks the exact `T25` epsilon form, and checks the simultaneous
normal/tangential normalization of the nonzero scalar mode.  Finally it
rebuilds the production frame and requires the public rational-epsilon layer
preparation to accept its exact source, target, incoming, and boundary data.
