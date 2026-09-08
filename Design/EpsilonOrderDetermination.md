# Determining epsilon orders before constructing solutions

Mathematical review, 2026-09-05. Two Pro reviews are incorporated:
general order determination and a focused follow-up on endpoint matching.
The reviewed method is now implemented in the general package; the implementation
and its supported input classes are described below.

## Implementation (2026-09-05)

The [connected boundary-normalization workflow](MasterIntegralExpansionOrders.md)
now derives the integral bounds, fixes ordinary/Frobenius constants, and returns
all global and local expansion orders in one call. Polynomial endpoint
resolution and scalar Feynman primary sectors are implemented; a supplied
integer pole bound is no longer necessary for supported integral definitions.

The general modules are in `FeynFacet/Private/Transport/Orders/`. Public
routines derive resolved-integral Laurent bounds, propagate requirements
through linear combinations/products/convolutions, determine scalar or matrix
endpoint orders, compute finite Frobenius pole bounds, and close entrywise
fundamental-matrix requirements through the DE. The finite constructor uses
these limits automatically. Integral-bound records also feed requests for
explicit master coefficients in initial constants.

See [the API and executable example](../Examples/Transport/README.md) and
[the command-line driver](../Scripts/Transport/determine_epsilon_orders.wls).

A full CF269 comparison at existing requested U orders -3 through 4 retained
the maximum prepared order 7 but reduced finite integral definitions from
1194 to 905. Construction took 2.22 seconds. Stored coefficient identities
passed; source gauges, kernel pullbacks and basis series passed 80-digit
checks at rational points. This is an implementation example, not a choice
of physical NNLO truncation orders.

The 347-entry saved coefficient table is accepted without replacing its
coefficients by fabricated monomials. Before additional endpoint or
renormalization operations, it yields 345 nonzero-column input demands:
orders -1: 2, 0: 203, 1: 131, 2: 7, 3: 1, 4: 1.
All 345 still lack normalized integral lower bounds in that input table.
The result reports `AdditionalLaurentBoundsRequired` and
`PhysicalNNLOCoverageInferred -> False`.

The implementation establishes bounds only in its stated input classes.
It requires a cut/phase-space parameter representation for raw cut integrals,
does not discover the endpoint
expansion of a general observable, compute global matching functions, or
infer relations among unknown physical constants. Exact rational regularity
proofs have a time limit. Uniform source/basis series limits are still used
before pruning finite integral coefficients.

## What must be specified

An epsilon order belongs to a mathematical object and an operation, not to
the label NNLO. Distinguish the normalized physical masters I, a prepared
basis P, its fundamental matrix V, the original fundamental matrix
U=Q V Q(X0)^(-1), the initial constants, and the final distribution-valued
partonic coefficient. Renormalization and mass factorization also consume
lower-perturbative-order inputs.

The saved coefficient table must identify its actual assembly stage.
A bare double-real density, a distribution after endpoint subtraction, and
a renormalized, mass-factorized partonic coefficient need not have the same
order requirements, even if older records call all of them a hard function.

The requested result is correct if the omitted terms contribute only
O(epsilon^(N+1)) in the final output space. For a distribution this is a
statement after pairing with admissible test functions, not a pointwise
statement away from the boundary.

## Multiplication: sufficient and locally sharp orders

Write v(f) for the lowest nonzero epsilon power, with v(0)=Infinity. After
combining coefficients of identical masters, let

    F_alpha = sum_i R_alpha_i I_i,
    v(R_alpha_i) = a_alpha_i,     v(I_i) >= ell_i.

For outputs through epsilon^N_alpha, sufficient upper orders are

    n_i = max_alpha (N_alpha - a_alpha_i),
    R_alpha_i through N_alpha - ell_i.

An absent coefficient causes no direct demand. If I_i is stored through
n_i, its remainder starts at n_i+1; multiplication by R_alpha_i leaves a
remainder starting no earlier than N_alpha+1. The analogous argument gives
the coefficient order. An interval ell_i..n_i is empty when n_i<ell_i.

These upper orders are sharp for independent coefficient data with the
stated valuations: the leading coefficient of R multiplies I_i^[n_i].
They are not a basis-invariant optimum. Known identities or a different
basis can reduce the information needed.

For a specified output-order set K_alpha and known coefficient support,
the exact direct demands are

    { n >= ell_i : n=k-q for some k in K_alpha,
                     q in supp_epsilon(R_alpha_i) }.

Taking intervals is a safe compression of that set, not a proof that every
interior order is nonzero or indispensable.

Finiteness of the final answer does not justify dropping intermediate
negative orders: analytic prefactors and counterterms can turn them into
finite contributions. Exact coefficients of the same independent object
should be combined before their valuations are taken.

## Lower bounds are mathematical input to be established

The DE alone does not determine the Laurent normalization of the physical
solution. Multiplying a solution by an arbitrary meromorphic function of
epsilon independent of kinematics leaves the same DE.

For a normalized integral, a lower bound can be derived from an established
convergent or meromorphically continued representation. Include the actual
measure, all Gamma factors, explicit epsilon normalization, dimension shifts,
propagator powers, irreducible numerators and the cut prescription.

In an appropriate resolved sector, endpoint factors and Taylor subtraction
make the possible poles explicit. If the regular remainder is analytic in
epsilon and sufficiently smooth at all subtracted faces, a possible bound
is the valuation of its explicit prefactor minus the number/order of
resonant endpoint denominators. Cancellations may improve this bound but
cannot make it unsafe. Counting overlapping regions as if they were
independent is not a proof.

Start with established analytic bounds or convergent representations.
Use more detailed sector/regions analysis only where a loose bound would
force expensive extra solution coefficients. A full numerical sector
integration is not needed merely to identify poles.

The quasi-finite-basis construction makes divergences explicit under its
stated Euclidean assumptions; the continuation or cut-integral application
must be justified separately. It does not establish a universal pole bound
for arbitrary NNLO masters. See
[von Manteuffel, Panzer and Schabinger](https://arxiv.org/abs/1411.7392).
Sector resolution provides a systematic fallback under the hypotheses of
the integral representation; see
[Bogner and Weinzierl](https://arxiv.org/abs/0709.4092).

## Propagate component and order demands through the actual operations

Let I=Q P and P=V D, with D=Q(X0)^(-1) C. After explicitly justified
constant lower bounds v(D_b)>=d_b, define E=R Q. For an output through N,

    V_ab is sufficient through N - v(E_a) - d_b.

For all original masters use E=Q with individual row targets. A general
framework can accept either an observable or an all-master request; its
algorithms must not contain family-specific selections.

An explicit counterexample to the current global-minimum bound is

    Q = {{1,epsilon},{1,0}},      V = diag(V1,V2).
    Q V Q^(-1) = {{V2,V1-V2},{0,V1}}.

Here min v(Q)=0 and min v(Q^(-1))=-1, so a global bound requests V
through N+1 for U through N. The displayed exact multiplication only needs
V through N. This saving follows from the matrix structure and requires
no boundary values or evaluation of V.

Compute valuations of known combined matrices such as R Q when inexpensive.
Do not replace all entry valuations by the worst entry of each matrix.
Structural zeros and absence of directed paths eliminate dependencies.

For the prepared DE, after pullback to the integration path,

    d V_ab^[n] = sum_(k,q>=0) b_ak^[q] V_kb^[n-q].

Order zero refers only to earlier rows because B0 is triangular; positive
q reduces epsilon order. If a proved lower bound for V_kb is d_kb, only
q<=n-d_kb can contribute. Directed shortest-path weights in the prepared
connection give useful lower bounds for V entries, including the empty
path on the diagonal. These are bounds: cancellations can raise valuations.

Starting from demanded output entries, close the finite dependence under
this recurrence and all basis convolutions. Known lower supports bound
both sides of every product. This gives sufficient exact dependencies
relative to the available nonzero information. It does not prove global
minimality among all algebraically equivalent formulations.

All coefficients admitted by this calculation must be constructed and
stored before export. Different requests may produce different finite
data; the reader must never generate missing coefficients.

## Constant correlations and basis choice

Componentwise lower bounds on C need not describe the physical subspace.
For nonzero constant N with N^2=0,

    dI/dx = (N/epsilon) I,
    U = 1 + (x-x0) N/epsilon.

If the physical I is regular at epsilon=0, then N C^[0]=0. Independently
arbitrary regular C_j would allow an unphysical pole away from the base.
Furthermore, I^[0](x) can depend on N C^[1], even though C^[0]=I^[0](x0).
One cannot discard the higher constant coefficient just because the
physical master is finite.

Independent component bounds are still safe sufficient bounds for a set
containing the physical constants. They can be wasteful. Improve them only
with established linear constraints or an explicitly adapted constant
basis. Retain these constraints without evaluating the constants.

An epsilon-finite reduction basis addresses spurious coefficient poles;
a finite or quasi-finite integral basis addresses integral divergences.
They are different properties. Neither necessarily coincides with the
simplest DE basis. For example, (I1-I2)/epsilon needs the order-one
difference in the original basis, while making that combination a new
master may require only its finite part. This is the motivation for
[epsilon-finite bases](https://arxiv.org/abs/hep-ph/0601165), rather than a
universal instruction to expand all old masters deeper.

Optimizing the basis must include the cost of the DE and boundary values.
Moving an epsilon pole between factors is not by itself a computational
saving.

## Endpoint distributions: different demands on different faces

For a nonzero constant a, analytic continuation gives as distributions
on [0,1], including the endpoint

    x^(-1-a epsilon)
      = -delta(x)/(a epsilon)
        + sum_(n>=0) (-a epsilon)^n/n! [log^n(x)/x]_+.

For an analytic regular coefficient f(x,epsilon), the finite distribution
requires f^[0](x) in the interior and f^[1](0) in the delta coefficient.
It need not require f^[1](x) everywhere.

With two independent resolved factors of this type and regular f(x,y,epsilon),
the analogous finite-order requirements are:

| Contribution | Coefficient information |
| --- | --- |
| Interior | f through epsilon^0 as a function of x,y |
| A single endpoint face | f through epsilon^1 on that face |
| The corner | f through epsilon^2 at the corner |

This distinction avoids increasing the order of the entire global solution
just to obtain a higher-order boundary coefficient. Extra prefactors or
poles in f shift these orders by the usual valuation rule.

Retain unexpanded endpoint powers and their logarithmic modes until
distribution extraction. A generic-point epsilon truncation does not
control integration through a singular endpoint. Overlapping endpoints
must first be resolved or treated with a valid joint asymptotic
description. This is standard in real-radiation sector decomposition;
see [Anastasiou, Melnikov and Petriello](https://arxiv.org/abs/hep-ph/0311311).

More generally, the analytically continued local moment is

    integral_0^1 x^(lambda(epsilon)+k) log^p(x) dx
      = (-1)^p p! / (lambda(epsilon)+k+1)^(p+1).

Its pole order follows from the valuation of the denominator. Higher
integer endpoint powers require Taylor subtraction and derivatives of
delta functions. Logarithmic modes and resonances can produce higher-order
denominators. An exponent identically at an unregulated resonance needs
additional cancellation or regulation, not an arbitrary epsilon order.

A matrix formulation avoids counting logarithms without their epsilon
prefactors. In a valid local representation with x^(M(epsilon)-1),

    integral_0^1 x^(M(epsilon)-1) x^k dx = (M(epsilon)+k*1)^(-1).

The inverse's entrywise Laurent valuations give the order loss of these
moments. For M=epsilon*1+J, J^r=0, poles can reach epsilon^(-r).
For M=epsilon*A with epsilon-independent invertible A, the inverse is only epsilon^(-1) A^(-1),
even if A has Jordan blocks. Diagonalizing nearly coincident exponents can
introduce spurious poles, so it should not precede this order determination
without accounting for the complete transformation.

A uniform remainder is essential. For example, epsilon/(x+epsilon)^2 is
O(epsilon) at every fixed x>0, yet its integral over [0,1] is 1/(1+epsilon).
A pointwise truncated series misses its leading integrated contribution.

Indicial data alone are not a complete endpoint description: integer
exponent differences, logarithmic blocks, transformations, local analytic
coefficients and their matching maps matter. A local Frobenius/regions
calculation can often establish the operator order loss before solving the
complete global coefficient functions, but this must be checked for each
representation. Bounds are also needed for the ordinary-point-to-local
matching matrix: the endpoint moment alone does not bound that map.

Requesting f^[1](0) instead of f^[1](x) reduces the requested information,
not necessarily the cost of obtaining it. It can still require fixed-endpoint
transport or a boundary calculation. On a face, the result can be a
nontrivial function of tangential variables and must be solved accordingly;
it cannot be renamed an arbitrary kinematics-independent constant.

## A finite local bound for endpoint matching

The follow-up establishes a sufficient route under explicit hypotheses.
At one smooth face x=0, work in a single frame with

    x dZ/dx = A(x,epsilon) Z,
    A = R(epsilon) + sum_(n>=1) A_n(epsilon) x^n,

where A is jointly holomorphic in x and epsilon on a common neighborhood.
Choose an epsilon-independent ordinary matching point rho in this
neighborhood and a fixed compact path from X0 to rho on which the full
connection is nonsingular and holomorphic in epsilon uniformly. Fix the
local normalization, branch and every meromorphic basis transformation.
The epsilon dependence must be sufficiently explicit to establish
valuations, including the order of vanishing of resonance denominators.

Define the Sylvester operators on matrices

    S_n(epsilon) = n Id - ad_R(epsilon),
    ad_R(H) = R H - H R,
    m = max({n>0 : det S_n(0)=0} union {0}).

The set is finite; this is the standard resonant structure of the
[Fuchsian local normal-form problem](https://yakovenko.wordpress.com/2014/11/10/lecture-3-nov-10-2014/).
The epsilon valuation bounds below are the conditional argument developed
in this review, not a claim that the cited lecture states this order-planning
result. For a local fundamental matrix

    Phi = H_loc(x,log(x),epsilon) x^R(epsilon),
    H_loc = 1 + sum_(n>=1) x^n H_n(log(x),epsilon),

the recurrence is

    (partial_log(x) + S_n) H_n = sum_(k=1)^n A_k H_(n-k).

At the finitely many resonant indices, resolve the actual linear
operators over the meromorphic epsilon field and fix the normalization.
An identically singular resonance requires logarithmic terms rather than
division by its zero determinant. The pole of S_n^(-1), where it exists,
can exceed one and must be bounded from the actual epsilon dependence.

For n>m the inverses S_n^(-1) are epsilon-regular. Polynomial inversion in
log(x) then cannot increase either the Laurent pole bound or logarithmic
degree. Thus the finite prefix through m bounds the entire local series.
Joint holomorphy and the uniform large-n bound ||S_n^(-1)||=O(1/n) provide
the convergence control needed to evaluate this statement at fixed rho.

The inverse has its own finite prefix. With G_loc=H_loc^(-1),

    G_0=1,
    G_n = -sum_(k=1)^n G_(n-k) H_k,

and its differential recurrence is

    (partial_log(x) + S_n) G_n = -sum_(k=1)^n G_(n-k) A_k.

Calculate this prefix consistently with H_loc's normalization. If its
coefficients through m, including every coefficient of the logarithmic
polynomials, have valuation at least -h_minus, the whole inverse
does too. The factor rho^(-R(epsilon)) is an epsilon-holomorphic unit, so

    val_epsilon(Phi(rho,epsilon)^(-1)) >= -h_minus.

This bounds the inverse without evaluating the local series at rho.
The normalized Wronskian gives a coarser alternative: if H_loc has pole
bound h_plus in a rank-r system, the adjugate gives inverse pole bound
(r-1) h_plus. The determinant normalization must be known; invertibility
only at nonzero epsilon is not enough.

If the local basis is additionally normalized by S(epsilon), original
masters are I=Q Z, and T_rho is the ordinary transport in this regular
frame, the local coefficient vector is

    c = M_loc C,
    M_loc = S^(-1) Phi(rho)^(-1) T_rho Q(X0)^(-1).

Ordinary transport and its inverse are epsilon-holomorphic under the path
hypothesis. A sufficient bound follows without evaluating T_rho:

    val(M_loc) >= val(S^(-1)) - h_minus + val(Q(X0)^(-1)).

Here matrix valuations mean minimum entry valuations; entrywise bounds
can refine this. Any projection extracting a requested endpoint coefficient
also contributes its valuation.

Two counterexamples identify indispensable inputs. A single resonance can
have arbitrarily high order: for

    A(x,epsilon) = {{1+epsilon^p, x},{0,0}},
    Phi = {{x^(1+epsilon^p), -x/epsilon^p},{0,1}},

the matching coefficients can have epsilon^(-p) poles although the
resonant index set is just {1}. Counting resonances or reading R(0) alone
does not determine the pole bound.

Separate fixed-epsilon regular-singular behavior is also insufficient.
For Z'=(1/x+epsilon/(x+epsilon)) Z, normalized at x0>0, the leading
coefficient of x at the endpoint is proportional to

    (epsilon/(x0+epsilon))^epsilon,

which contains epsilon log(epsilon), rather than a meromorphic Laurent
series. A second singularity approaches x=0 and destroys a common
holomorphic neighborhood.

On a positive-dimensional face, the argument is local in the tangential
variables or uniform only on a controlled compact patch. An intersection
with another singular face requires its own joint analysis. Failure to
establish these hypotheses must leave the bound unestablished; it does
not authorize a guessed extra epsilon order.

This is a bound for planning orders, not an endpoint solution. The actual
requested face coefficients must ultimately be explicit functions of the
tangential variables multiplying kinematics-independent constants. If a
separate set of boundary constants is used, its relation to the bulk
constants must be supplied; it is not additional independent data.

## Renormalization, mass factorization and ordering of operations

If starting from amplitudes, include the bilinear operations before treating
the subsequent assembly as linear. NNLO includes a one-loop squared term.
For a product g h with lower bounds ell_g, ell_h, sufficient cutoffs are

    g through N-ell_h,    h through N-ell_g.

The product/interference terms can then be regarded as entries of the
assembly input vector. Color, spin and evanescent projections are part of
the corresponding operations; a term proportional to epsilon can survive
multiplication by a later pole.

Compose the required Laurent-valued linear/convolution operations in their
actual order, with explicit input/output spaces. Counterterm poles can
require higher epsilon orders of lower-loop and Born ingredients.
Measurement functions, dimensional Jacobians and normalizations must be
included at the stage at which they act.

Do not multiply delta/plus distributions indiscriminately. Use operations
whose distributional action is defined; derive the associated order
requirements on smooth coefficients or valid convolutions.

A cancellation can reduce demands when it is an established identity
between contributions to the same final component. Expected real-virtual
pole cancellation alone is not sufficient to prune them.

## Current saved data: useful but not a final order determination

The saved input
ppHX_NNLO_DoubleReal/InputData/UU_08_10_canonical/HardFunctionMasterCoefficientEpsilonValuations.wl
contains 347 master coefficient entries. For an epsilon^0 request at that
recorded generic double-real stage, its direct upper demands are:

| Highest master order | Entries |
| --- | ---: |
| epsilon^-1 | 2 |
| epsilon^0 | 203 |
| epsilon^1 | 131 |
| epsilon^2 | 7 |
| epsilon^3 | 1 |
| epsilon^4 | 1 |
| Zero coefficient; no direct demand | 2 |

This is a census of saved valuations, not a new validation of their
reconstruction and not coverage of later distribution/counterterm operations.
All six directly occurring CF303 masters and all four directly occurring
CF269 masters have valuation-zero coefficients there. Other rows can
still be needed through DE coupling.

Consequently the current all-row U exports through epsilon^4 are
demonstrations at a declared finite order, not the output of a justified
minimum-cost physical order analysis. Master orders, U orders and V
orders must not be conflated.

## Recommended mathematical contract before implementation

1. Specify final perturbative, epsilon and distributional outputs.
2. Establish normalized integral lower bounds and required local endpoint
   structure, with assumptions and scope attached to each.
3. Combine known coefficients and propagate demands through every relevant
   operation, using componentwise valuations and sparse dependencies.
4. State allowed boundary-constant data and constraints; preserve them
   through basis changes.
5. Produce a finite order table with a reason for every requested order
   and an explicit final remainder bound.
6. Improve loose bounds only when the saved construction work justifies
   the analysis cost.

The final stopping criterion is that every admissible omitted tail maps
to O(epsilon^(N_alpha+1)) in each requested output space. For independent
tails beginning at M_i+1 and downstream valuation lower bounds v_alpha_i,
the sufficient inequality is

    M_i + 1 + v_alpha_i >= N_alpha + 1.

Endpoint projections and known constraints refine which tails can occur.
This is a compositional remainder argument, not repeated verification of
the complete DE solution.

This aims for justified sufficient orders with targeted reductions of
waste. Absolute minimality in the presence of unknown functional/constant
relations can be as difficult as the integral calculation itself.

Extra orders useful only for diagnostics should be separate requests,
not silently included in the physical order table. In particular, a
negative-power original DE can demand higher coefficients for an
original-basis residual; checking in a regular prepared basis can avoid
computing those extra coefficients just for validation.

Numerical/finite-field checks remain useful inexpensive validation.
A vanishing numerical sample is not proof that a Laurent coefficient
vanishes identically. An exact lower valuation bound plus a valid nonzero
finite-field witness can establish a rational coefficient valuation without
fully reconstructing it. AMFlow comparisons test computed masters later;
they cannot supply a mathematical justification for omitted orders.

## Pro review

The first review agrees with the valuation/remainder argument and sparse
DE dependence, and confirms that the current fixed U ranges do not imply
physical NNLO completeness. It emphasizes endpoint-only higher-order data,
the distinction between regular equations and regular physical constants,
matrix treatment of logarithmic/resonant modes, and bilinear amplitude
products before the linear assembly.

[Preserved question and Pro response](../External/ChatGPT/Records/2026-09-05/03_epsilon_order_determination.md).
The original conversation is
[available in ChatGPT](https://chatgpt.com/c/6a9c64ec-3cc4-83e8-b40c-9b568241fd3b).

The [focused endpoint-matching review](../External/ChatGPT/Records/2026-09-05/04_epsilon_orders_endpoint_matching.md)
confirms the finite-resonance argument under uniform Fuchsian hypotheses,
and sharpens it by bounding the inverse local series directly. This closes
the logical circularity in choosing matching orders under those hypotheses;
the actual matching functions remain a separate computation.
