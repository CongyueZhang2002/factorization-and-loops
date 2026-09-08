# Laurent bounds for compact cut integrals

The general order code now has two ways to bound pure phase-space masters.
Neither evaluates a master integral or assumes a universal NNLO pole order.
The input fixes the momentum-space integral, its cut powers, kinematics and
any explicit scalar master prefactor. The AMFlow measure is preserved.

## Cheap default: pole multiplicity

For a connected physical phase space, the future on-shell cut momenta sum to
a fixed future timelike momentum. If independent cut momenta determine all
phase-space loop momenta, their bounded energies make the domain compact.

The code verifies that every positive-power uncut denominator can vanish
only on the Gram boundary. It first uses exact causal decompositions and
linear algebra. For example, a null sum of future causal vectors forces
collinearity. A rank-intersection check verifies that the resulting dependence
actually lies in the momentum subspace of the integral. If this fails, a
bounded exact real-algebraic decision attempts zero containment. Failure
returns no bound.

Repeated cuts require a stronger statement than an on-shell identity.
The argument must hold throughout independent nonnegative increases of the
cut masses. Only **fixed external** null momenta can serve as null anchors;
a massless cut momentum becomes timelike under this deformation. A scalar
product identity valid only after setting the cut squares to zero is
insufficient. Interior massive resonances are explicitly rejected.

Compact semialgebraic domination then gives a half-plane of sufficiently
large Re(D) in which the full domain and its required mass derivatives have
integrable dominating functions. This establishes holomorphy in complex D,
not merely finite values at real integer dimensions. Moving Gram and
positive-energy boundaries contribute no omitted terms in that half-plane.
Normal derivatives of the density are taken there and continued meromorphically.

After eliminating the cut coordinates, combine the differentiated terms as

```text
N(epsilon) f(z,epsilon) P(z)^(a(epsilon)) / product_j D_j(z)^nu_j.
```

Suppose n integration coordinates remain and all singular divisors are
regulated by P. Resolution to normal crossings has at most n coordinates;
each coordinate contributes at most one simple pole in the Gram exponent.
Consequently, if nu_epsilon(a-a(0))=s,

```text
nu_epsilon(I) >= nu_epsilon(N) + nu_epsilon(f) - n s.
```

Explicit cancellations in f and zeros of inverse Gamma factors are included.
Inactive external directions are removed and the angular prefactor is
**recomputed**, so n is the integration dimension of that representation.
The bound can be conservative; no actual sector decomposition is needed.
The analytic continuation by resolution is based on
[Atiyah, Resolution of Singularities and Division of Distributions](https://onlinelibrary.wiley.com/doi/10.1002/cpa.3160230202).
The physical cut representations are described in
[Harley, Moriello and Schabinger](https://arxiv.org/abs/1705.03478).

`DetermineIntegralLaurentBound` selects this calculation for supported
positive-dimensional Baikov cut integrals. Fully localized cuts and explicit
inclusive volumes retain their direct formulas.

## Refinement: a dimensional recurrence

The previous argument proves eventual holomorphy at large dimension without
having to calculate a quantitative convergence dimension. An exact rational
dimensional recurrence turns that existence statement into tighter bounds.

For L phase-space loops, E external vectors, transverse Gram polynomial P,
and the AMFlow phase-space measure,

```text
I(D+2) = (2 Pi)^(-L) R(D) I(D),
R(D) = [IBP reduction of multiplication by P]
       / product_(j=1,...,L) (D-E-j+1).
```

These are bare GLI integrals. Multiplication by a cut coordinate lowers its
cut power; a nonpositive cut power gives zero. No additional factorial is
inserted. Kira reduces the finite list of Gram insertions at exact rational
kinematics, leaving D symbolic. The basis includes every required lower sector.
The constructor converts Kira's chosen master basis to the requested basis
by a rational matrix, so it does not require Kira to select a particular
preferred basis. A nonclosed or dependent requested basis returns a failure.

Let S(D)=R(D)^(-1), and expand at D=D0-2 epsilon. Factor the cancelled rational
denominators of S over Q. Every pole on the grid D0+2j is a rational root and
therefore occurs in a linear factor. This finds all such poles, including
remote ones; there is no bounded numerical root search.

Choose D_h on this grid beyond the last pole. Every S(D_h+2j-2 epsilon) is
holomorphic at epsilon zero. Eventual high-dimensional holomorphy supplies
some finite J for which I(D_h+2J-2 epsilon) is holomorphic. The finite downward
recurrence proves I(D_h-2 epsilon) holomorphic. J need not be computed:
there is no infinite product or limit in this argument.

Thus, for D_h=D0+2K,

```text
M(epsilon) = S(D0-2 epsilon) ... S(D_h-2-2 epsilon),
I(D0-2 epsilon) = (2 Pi)^(K L) M(epsilon) I(D_h-2 epsilon),
nu_epsilon(I_i) >= min_j nu_epsilon(M_ij).
```

The matrix product is formed exactly and cancellations are retained.
`HolomorphicDimension` reports D_h; it does **not** assert direct convergence
of the original integral representation at D_h. `LoweringMatrixPoleDimensions`
reports the exceptional grid points. Any extra scalar master prefactor is
applied after bounding the bare integrals. The complete dimension-shift
normalization is a constant, so it introduces no unscanned tail poles.

The result concerns the **specified kinematic point**, which is sufficient
for bounding the constants I(X0,epsilon). It does not claim that special-point
cancellations give a uniform bound throughout phase space.

Using dimensional recurrences and finite higher-dimensional phase-space
integrals follows the amplitude-community practice illustrated by
[Gituliar, Magerya and Pikelner, Five-Particle Phase-Space Integrals in QCD](https://arxiv.org/abs/1803.09084).
The finite-descent argument used here is recorded with its Pro review in
[exchange 06](../External/ChatGPT/Records/2026-09-05/06_dimensional_recurrence_laurent_bounds.md);
the mass-deformation qualifications are in
[exchange 05](../External/ChatGPT/Records/2026-09-05/05_cut_integral_pole_bounds.md).

## General interfaces

```wl
representations = ConstructMasterIntegralRepresentations[
  system, <|"BasePoint" -> point|>];

recurrence = ConstructMasterIntegralDimensionalRecurrence[
  representations, "WorkingDirectory" -> "/absolute/path/to/new-reduction"];

bounds = DetermineLaurentBoundsFromDimensionalRecurrence[recurrence];

orders = DetermineMasterIntegralExpansionOrders[system,
  <|"BasePoint" -> point,
    "RequestedMasterIntegralOrderRanges" -> requestedRanges,
    "DimensionalRecurrence" -> recurrence|>];
```

`ConstructMasterIntegralDimensionalRecurrence` uses one complete family basis.
Options include `KiraExecutable`, `FermatExecutable`, `Threads` (default 2) and
`RegularityProofTimeLimit`. A recurrence requiring only its existing master
entries skips IBP entirely. Otherwise Kira produces the exact reduction.
The working directory stores ordinary integral definitions and the completed
recurrence. Reuse requires equality of the definitions, basis and kinematics;
a changed explicit scalar prefactor refreshes the bound while reusing the
bare recurrence.

The planner accepts a list in `DimensionalRecurrences` for several families.
Alternatively, request `CutPoleBoundMethod -> "DimensionalRecurrence"` and
supply `DimensionalRecurrenceOptions -> <|"WorkingDirectory" -> directory|>`.
The planner constructs the full represented family bases and uses a separate
subdirectory for each family. Without that request or a supplied recurrence,
the inexpensive geometric calculation is the default.

The command-line driver also accepts `Task -> "MasterIntegralDimensionalRecurrence"`
or `Task -> "DimensionalRecurrenceLaurentBounds"` and an optional `Options`
association. Inputs and outputs are finite records.

## CF269 result and limits

At (v,w)=(1/4,1/3), the 23-master basis has sufficient lower bounds

```text
{-3,-3,-3,-3,0,0,-1,-1,-3,-3,-3,-3,-3,-3,-1,-2,-2,-3,-2,-3,-3,-3,-3}.
```

The lowering matrix has grid poles at D=4 and D=6, giving D_h=8.
Zero bounds prove holomorphy; negative bounds are upper bounds on pole order,
not claims that the leading pole coefficient is nonzero.

Requesting every original master through epsilon^0 gives boundary upper orders

```text
{0,0,0,0,3,2,0,1,0,1,1,0,0,0,0,1,0,0,0,0,1,0,1}.
```

The prepared evolution must reach epsilon^4. The general planner derives the
entrywise orders and their basis-conversion contributions. It does not set
every boundary component to the same order.

The [saved records](../ppHX_NNLO_DoubleReal/Results/EpsilonOrderDetermination/CF269/README.md)
contain the actual matrices, bounds, proof inputs and order tables.
These are sufficient orders for declared master targets. A final NNLO demand
still needs the full observable, endpoint integration, renormalization and
mass-factorization operations. Mixed real/virtual integral conversion remains
outside this implementation; an unestablished convergence hypothesis returns
a failure. No all-family production campaign is claimed.
