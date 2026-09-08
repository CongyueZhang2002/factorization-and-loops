# Explicit singular-boundary matching

## Question

Continue our physical boundary reduction review. Repository https://github.com/CongyueZhang2002/factorization-and-loops (latest local work not pushed).
We validated the uniform large-real-D phase-space bound you reviewed. Exact full connection SCCs give a 348-dimensional spanning DE; exact requested closure is346. After retaining the one unobserved raised-cut CF248 scalar and fixing known volume, at most83 unknown meromorphic series. All91 saved finite ordinary-point solutions were actually changed to a shared basis (345 unknown series,2192 Laurent slots). Each is finite epsilon coefficients built from explicit scalar nested integrals and algebraic definitions, evaluable at ordinary points. Need now APPLY physical constraints, not stop at a count.

Available code: rational original master DE in v,w, epsilon; all237 diagonal SCC blocks fuchsifiable at z=1-v-w by diagonal integer powers, sizes1..4. General residues R(eps), slopes -4,-3,-2,-1,0,+1. Union SCC graph lower triangular; interblock sources may initially have higher poles. Local epsilon-form H(z)z^(eps R0) code exists but assumes strict epsilon form. Original finite solution constructor has general zero-epsilon transport and explicit integral DAG, not lazy path-ordering.
Shared ordinary points: almost all (v,w)=(1/4,1/6), four CF269 inputs at(1/4,1/3), with lower-sector conversion already explicit. Bound calculated at interior v=3/5, but original rational connections available with v symbolic. Could choose boundary anchor v=1/4 instead if generic, and normal z path to ordinary points.

Need your most concrete general method to construct exact finite-epsilon connection from surviving singular modes to saved ordinary constants, including all sourced modes, Jordan chains and integer resonances. Constraints: symbolic result up to constants (finite quadrature definitions acceptable as current solution, a truncated kinematic Taylor series or an unspecified connection/generator is not); realistic storage; verification cheap rational/numerical; no need minimize boundary IBP this step.
Questions:
1. Best constructive route: global Fuchsification and normalized residue then regularized iterated integrals, blockwise variation-of-constants with endpoint subtraction, or solve adjoint forbidden-mode functionals?
2. How exactly fix sourced particular solution so forbidden homogeneous slopes vanish without incorrectly setting ordinary constants zero? Can asymptotic projection of existing finite-eps nested integrals be made finite by explicit endpoint subtraction?
3. Epsilon expansion collides slopes at eps0 and can hide generic-eps growth constraints: which order guarantees physical matching and required epsilon orders? How retain epsilon poles in spectral projectors?
4. Suggest an implementation-friendly exact recurrence producing finite expressions and a minimal nontrivial sourced/Jordan/resonant test. Flag any hidden need to first solve non-epsilon zero-order homogeneous blocks.
Please challenge oversimplified approaches. Our purpose is now actual substitution with<=83 unknown series, not another dimension argument.

## Pro response

Use blockwise variation of constants, with a finite generic-ϵ Frobenius jet as an endpoint counterterm and an exact integral of its differential-equation residual. This constructs the singular-to-ordinary map without global Fuchsification, a dense connection matrix, or using a truncated kinematic series as the answer.

The intended output is genuinely

C
shared
	​

(ϵ)=c
known
	​

(ϵ)+M(ϵ)p(ϵ),dimp≤83,
	​

(1)

where every required Laurent coefficient of M is an explicit finite expression in your scalar-integral DAG. The surviving amplitudes p need not yet have simpler boundary-integral evaluations.

The key identity is the following. For a sourced block

F
′
=AF+s,

let H
′
=AH, H(z
o
	​

)=1, and let J be a sufficiently complete finite local jet specifying the desired boundary amplitudes. Then

F(z)=J(z)−H(z)∫
0
z
	​

H(t)
−1
[J
′
(t)−A(t)J(t)−s(t)]dt.
	​

(2)

Choose the jet depth so that the combined integrand is convergent. At the ordinary point,

F(z
o
	​

)=J(z
o
	​

)−∫
0
z
o
	​

	​

H(t)
−1
[J
′
(t)−A(t)J(t)−s(t)]dt.
	​

(3)

Below I specify how to construct J, make this finite order by order in epsilon, and handle the resonances and sources correctly.

1. Choose one normal path and reuse the existing homogeneous machinery

Provided it is generic for your symbolic residue and observability certificates, choose

v=v
∗
	​

=
4
1
	​

,w=
4
3
	​

−z.

The original rational normal connection is

dz
dG
	​

=−A
w
	​

(
4
1
	​

,
4
3
	​

−z,ϵ)G.

The two ordinary points become

z
o
	​

=
12
7
	​

andz
CF269
	​

=
12
5
	​

.

Thus the same boundary construction can supply the common-point constants and the four CF269 inputs by evaluating the appropriate rows at two different values of z. No tangential connection or dense CF269 bridge is needed. Check that specialization to v=1/4 does not lower the relevant ranks or make the chosen gauges singular.

After your known integer gauges and any existing epsilon preparation, write the lower-triangular system as

F
j
′
	​

=A
j
	​

F
j
	​

+s
j
	​

,s
j
	​

=
k<j
∑
	​

B
jk
	​

F
k
	​

.
(4)

Only A
j
	​

 needs a homogeneous propagator, of dimension at most four. Higher poles in B
jk
	​

 are handled as source valuations, not by globally Fuchsifying the connection.

Do not invert a demand-restricted solution map. Reuse square diagonal-block propagators from the existing constructor; where they were not retained, generate them by supplying identity initial data to that constructor.

The pushed BuildEndpointFrobenius explicitly divides the connection by epsilon and rejects residual epsilon dependence. Its related mode-connection helper also verifies a diagonal residue frame. Neither is presently the generic resonant/Jordan helper needed here. This requires a new local-jet constructor, not just removing the epsilon-form check.

Why this route rather than the alternatives?

Global Fuchsification would solve a larger gauge problem than necessary and can spread interblock expressions. Adjoint forbidden-mode functionals are useful for selected constraints, but here you want the surviving solution map: constructing at most 83 columns blockwise is more direct than transporting roughly 260 forbidden rows.

The proposed method separates two small tasks: rational local coefficient algebra, and the homogeneous finite-quadrature transport you already possess.

2. Construct generic-ϵ local jets with sources and resonances

For one Fuchsian diagonal block, write

zA
j
	​

(z,ϵ)=R
j
	​

(ϵ)+
m≥1
∑
	​

z
m
A
j,m
	​

(ϵ),S
j
	​

=zs
j
	​

.

Use generalized power/log coefficients

F
j
	​

=
λ,n
∑
	​

z
λ(ϵ)+n
f
j,λ,n
	​

(L,ϵ),L=logz,
(5)

where each f is a vector polynomial in L. Include exponents inherited from lower-sector sources, and choose integer starting valuations low enough to accommodate their poles.

Generalized local expansions are applicable to noncanonical systems; strict epsilon form is not required. The important requirement is regular singularity of the homogeneous problem. 
arXiv

Substitution gives the exact recurrence

[(λ+n)1−R
j
	​

+∂
L
	​

]f
j,λ,n
	​

=
m≥1
∑
	​

A
j,m
	​

f
j,λ,n−m
	​

+S
j,λ,n
	​

.
	​

(6)

Compute this over Q(ϵ), or the already declared exact coefficient field. Do not expand epsilon yet.

An implementable polynomial solver

Put

M=(λ+n)1−R
j
	​

,(M+∂
L
	​

)f=g.

If M is invertible, the polynomial particular solution is finite:

f=
r=0
∑
deg
L
	​

g
	​

(−1)
r
M
−r−1
∂
L
r
	​

g.
	​

(7)

If M is singular, split its generalized zero eigenspace from its invertible part, using exact linear algebra. On the generalized zero eigenspace M is nilpotent, so

f
part
	​

(L)=e
−ML
∫
0
L
	​

e
Mu
g(u)du
(8)

is again a finite polynomial. Add the homogeneous polynomial

e
−ML
c

on that subspace. These c's are the local amplitude coordinates.

This handles Jordan chains without numerically constructing a Jordan frame. It also handles exact integer resonances: at a later integer order, the recurrence can generate a forced logarithm as well as a new homogeneous amplitude.

Group exponent lattices consistently. Two exponents differing by an integer must not be treated as unrelated Taylor series with duplicated coefficients.

How to apply the physical condition

Construct the complete sourced jet in a slope-adapted normalization. Retain the allowed new homogeneous amplitudes and the explicitly exempt unobserved freedom. Set excluded local homogeneous amplitudes to zero—not ordinary-point constants.

When all inherited source components have allowed slopes, recurrence (6) produces particular terms with those same slopes, shifted only by integers and supplemented by logarithms. It does not require adding forbidden-slope homogeneous terms.

There is one exception worth checking explicitly: an inherited unconstrained component, such as the retained raised-cut exception, could feed a forbidden slope into an observed downstream block. Then the complete physical condition may impose a relation on inherited amplitudes. Do not silently retain a forbidden sourced component merely because its coefficient was introduced earlier.

The resulting jet is affine-linear in a common amplitude vector:

J
j
	​

(z,ϵ)=J
j,known
	​

(z,ϵ)+J
j
	​

(z,ϵ)p(ϵ).
(9)

The known volume belongs in the known part, not in an additional free column.

What not to assume

A representation H(z)z
R
 with H holomorphic need not exist with the original residue R in an integer-resonant system. For example,

θx=0,θy=y+zx

has

x=P,y=z(Q+Plogz),

although the residue is diagonal. The logarithm comes from a resonant regular coefficient. Recurrence (6) sees it; a residue-only exponential does not.

3. Turn the finite jet into an exact finite-quadrature solution

Suppose the lower blocks have already been constructed exactly through the required epsilon orders. In (4), use their full finite expressions in s
j
	​

.

Let J
j
	​

 be the finite local jet from the preceding step. Define its defect against the untruncated rational DE and exact lower-sector source:

D
j
	​

(z,ϵ)=J
j
′
	​

−A
j
	​

J
j
	​

−s
j
	​

.
(10)

Let H
j
	​

 be the ordinary-normalized diagonal homogeneous propagator. Then define

E
j
	​

=H
j
−1
	​

D
j
	​

,F
j
	​

=J
j
	​

−H
j
	​

∫
0
z
	​

E
j
	​

(t,ϵ)dt.
(11)

This is not an approximation. Differentiating gives

F
j
′
	​

=J
j
′
	​

−A
j
	​

H
j
	​

∫
0
z
	​

E
j
	​

−D
j
	​

=A
j
	​

F
j
	​

+s
j
	​

.

The correction supplies exactly the terms missing from the local jet.

The jet need not converge at the ordinary point. It is a finite counterterm that can be evaluated anywhere along the path. Accuracy is supplied by the exact residual integral, not by extrapolating a Taylor series.

Required endpoint condition

Choose J
j
	​

 sufficiently deep that

H
j
−1
	​

D
j
	​

=O(z
η
log
K
z),η>−1,
(12)

uniformly in a sufficiently small punctured epsilon neighborhood, after accounting for a finite meromorphic epsilon pole.

Also ensure that the jet includes every independent local amplitude and is deep enough that the omitted tail vanishes in homogeneous coordinates:

H
j
−1
	​

(F
j,formal
	​

−J
j
	​

)⟶0.
(13)

This is stronger than “the leading coefficient is correct.” It prevents missing a homogeneous mode that first appears at a later integer valuation.

Neither condition requires knowing the analytic local-to-ordinary connection. Write locally

H
j
	​

=Φ
j
	​

K
j
	​


with Φ
j
	​

 a formal local fundamental frame. Since K
j
	​

 is constant in z, local integrability and vanishing can be checked using finite jets and valuation bounds for Φ
j
−1
	​

.

In practice, demand a nonnegative integer power in the transformed defect at epsilon zero. That provides a margin for the small bϵ shifts.

Higher-pole sources determine backward jet demands

Suppose B
jk
	​

∼z
−p
. To know the source defect through z
q
, the lower-block jet must extend through the corresponding q+p range. Propagate these requirements backward along the sector DAG.

Thus jet depth is dictated by source poles and inverse-homogeneous valuations—not by a universal MaximumSeriesOrder -> 4, and not by the desired numerical accuracy.

Cutoff independence is a useful exact check

For two counterterms J,
J
 representing the same local amplitudes, their constructed solutions differ by

ΔF=H(z)
t→0
lim
	​

H(t)
−1
[
J
(t)−J(t)].
(14)

Once both cutoffs satisfy the normalization requirement, this is zero.

Consequently, increasing the local cutoff changes the presentation of the integrals but not the connection. This gives a strong regression test without evaluating a full analytic connection matrix.

Why this fixes sourced ordinary constants correctly

At the ordinary normalization point,

F
j
	​

(z
o
	​

)=J
j
	​

(z
o
	​

)−∫
0
z
o
	​

	​

E
j
	​

(t,ϵ)dt.
	​

(15)

There is no additional ordinary homogeneous constant to choose. The prescribed local amplitudes and inherited source already determine it.

Equivalently, an ordinary-point variation-of-constants formula would require a generally nonzero constant to cancel the forbidden local component of its particular solution. Equation (15) computes precisely that constant.

This is also the preferred way to perform asymptotic projection of the existing finite-integral machinery: subtract at the DE level before integration, rather than trying to extract endpoint constants recursively from a large, already-expanded nested-integral expression.

4. Materialize the construction order by order in epsilon

The equations above use H
j
	​

(z,ϵ) to state the identity. The implementation must replace it by explicit, finitely many coefficient expressions.

The zero-epsilon homogeneous solution is a real prerequisite

In an epsilon-regular prepared frame, write

A
j
	​

(z,ϵ)=
r≥0
∑
	​

ϵ
r
A
j,r
	​

(z).

Obtain the exact ordinary-normalized solution

H
j,0
′
	​

=A
j,0
	​

H
j,0
	​

.
(16)

Fuchsianity and a known residue do not solve (16). Splitting A
j
	​

=R
j
	​

/z+regular and iterating the regular part can require infinitely many order-zero insertions. That is not a finite epsilon-coefficient construction.

Your existing zero-epsilon transport is therefore essential. Reuse its explicit algebraic/quadrature definitions. If a newly assembled diagonal block lacks the necessary square homogeneous solution, obtaining it is a genuine prerequisite; endpoint subtraction does not manufacture it.

Likewise, if a diagonal connection has negative epsilon powers, first use the existing preparation that permits a finite order-by-order construction. Do not assume that rationality in epsilon makes the following nonnegative-order recurrence valid. Order-by-order DE integration and one-dimensional transport are standard, but their finite implementation depends on handling the order-zero homogeneous problem. 
arXiv

Homogeneous coefficient recurrence

Once H
j,0
	​

 is available, for n>0,

H
j,n
	​

(z)=H
j,0
	​

(z)∫
z
o
	​

z
	​

H
j,0
	​

(t)
−1
r=1
∑
n
	​

A
j,r
	​

(t)H
j,n−r
	​

(t)dt.
	​

(17)

All these integrals have ordinary endpoints.

For

W
j
	​

=H
j
−1
	​

=
n
∑
	​

ϵ
n
W
j,n
	​

,

use

W
j,0
	​

=H
j,0
−1
	​

,W
j,n
	​

=−H
j,0
−1
	​

r=1
∑
n
	​

H
j,r
	​

W
j,n−r
	​

.
(18)

Known meromorphic gauge factors can be applied afterward with full Laurent bookkeeping.

Exact boundary-lift recurrence

Expand the already selected generic-epsilon jet and source to the required Laurent ranges. Form

D
j,n
	​

=J
j,n
′
	​

−
r
∑
	​

A
j,r
	​

J
j,n−r
	​

−s
j,n
	​

,
(19)

then

E
j,n
	​

=
r
∑
	​

W
j,r
	​

D
j,n−r
	​

.
(20)

Define the explicit scalar quadratures

I
j,n
	​

(z)=∫
0
z
	​

E
j,n
	​

(t)dt.

Finally,

F
j,n
	​

(z)=J
j,n
	​

(z)−
r
∑
	​

H
j,r
	​

(z)I
j,n−r
	​

(z).
	​

(21)

At the ordinary point this simplifies to

F
j,n
	​

(z
o
	​

)=J
j,n
	​

(z
o
	​

)−I
j,n
	​

(z
o
	​

).
	​

(22)

These recurrences terminate at the requested epsilon orders. Unroll them into actual DAG nodes. No path-ordering object, unspecified connection coefficient, or kinematic series remainder remains.

Form the complete coefficient E
j,n
	​

 before integrating. Its individual convolution summands may be divergent even when their sum is convergent. Do not assign independent finite parts to terms whose divergences cancel.

5. Generic epsilon must precede physical projection

The safe order is:

generic-ϵ mode construction and exclusion→endpoint counterterms→Laurent expansion→finite quadratures.
	​

(23)

This distinction is visible already in one primitive:

P
γ
	​

[z
γ−1
]=
γ
z
γ
	​

.

If γ=cϵ, retain

cϵ
z
cϵ
	​

=
cϵ
1
	​

+logz+
2
cϵ
	​

log
2
z+⋯.
(24)

It is not interchangeable with the primitive logz obtained by first setting epsilon to zero.

For an exactly resonant exponent, γ≡0, a logarithmic primitive with a specified integration constant is appropriate. For a near resonance, γ=cϵ

=0, the meromorphic 1/ϵ term is part of the generic boundary normalization.

The same applies to the matrix denominators

n+λ
i
	​

(ϵ)−λ
j
	​

(ϵ),

and to spectral projectors whose poles arise when slopes coalesce. Keep them exact before expansion. Do not calculate a projector at epsilon zero and infer that it represents the generic physical subspace.

There is no universal number of extra epsilon orders

Required depth is a valuation calculation.

For an output row through ϵ
N
i
	​

, suppose

F
i
	​

=
a
∑
	​

M
ia
	​

p
a
	​

,ν
ia
	​

=ord
ϵ
	​

M
ia
	​

,ℓ
a
	​

=ord
ϵ
	​

p
a
	​

.

Then the demands include

p
a
	​

:through N
i
	​

−ν
ia
	​

,M
ia
	​

:through N
i
	​

−ℓ
a
	​

.
(25)

The internal construction must include the additional padding required by poles in gauges, recurrence inverses and projectors.

Propagate these orders through the operation DAG using exact Laurent valuations. Start conservatively and reduce demands only after certified cancellations.

Your existing 2,192 slots are therefore not automatically sufficient for the new coordinate system. Some will disappear, but a boundary map with a double epsilon pole can require two additional orders of a surviving input. This affects coefficient depth, not the number of independent series.

Generic-epsilon selection establishes which modes are absent. Adequately padded finite expansion then guarantees the resulting substitution through the requested orders. Matching only the epsilon-zero system cannot supply that guarantee.

6. A four-component sourced/Jordan/resonant regression test

The following test exercises the essential cases without family-specific information. Set

α=−2ϵ,θ=z
dz
d
	​

,

and consider

θx
θr
θy
2
	​

θy
1
	​

	​

=αx,
=(1+α)r+zx,
=y
2
	​

+
1−z
zx
	​

,
=y
1
	​

+y
2
	​

.
	​

(26)

Retain the slope-−2 inputs and exclude the slope-zero homogeneous solutions.

The first two solutions are

x=Pz
α
,r=z
1+α
(Q+Plogz).
	​

(27)

The logarithm in r is caused by an exact integer resonance at generic epsilon, not by expanding epsilon.

For the Jordan pair, define

F
α
	​

(z)=
α
z
α
	​

+∫
0
z
	​

1−t
t
α
	​

dt,
(28)

and

K
α
	​

(z)=
α
2
z
α
	​

+∫
0
z
	​

1−t
t
α
	​

log
t
z
	​

dt.
(29)

The remaining integrals converge for Reα>−1 and 0<z<1. Every required epsilon coefficient is a finite logarithmic quadrature.

The physically selected solution is

y
2
	​

=PzF
α
	​

(z),y
1
	​

=PzK
α
	​

(z).
	​

(30)

The excluded homogeneous solutions would add

C
2
	​

zto y
2
	​

,z(C
1
	​

+C
2
	​

logz)to y
1
	​

.

Thus C
1
	​

=C
2
	​

=0 in local coordinates, but y
1
	​

(z
o
	​

) and y
2
	​

(z
o
	​

) are nonzero sourced ordinary data.

The counterterm is particularly small

For y=(y
1
	​

,y
2
	​

)
T
, choose

J
y
	​

=Pz
1+α
(
α
−2
α
−1
	​

),A
y
	​

=
z
1
	​

(
1
0
	​

1
1
	​

).

Its exact derivative defect is

D
y
	​

=
	​

0
−
1−z
Pz
1+α
	​

	​

	​

.
	​

(31)

After multiplication by the inverse Jordan propagator, this is integrable near epsilon zero. Formula (2) gives exactly (28)–(30).

This test checks five distinct requirements at once: an inherited source, a persistent integer resonance, a Jordan chain, nonzero ordinary constants despite vanishing forbidden local amplitudes, and a 1/ϵ
2
 matching pole.

Apply the additional gauge

y
	​

=z
−2
y

to create a higher-pole interblock source. The result after undoing the gauge must remain identical. That tests source-valuation propagation and gauge independence.

For epsilon-depth testing, the α
−2
=1/(4ϵ
2
) term makes the required padding explicit: computing y
1
	​

 through order N generally needs P through order N+2.

7. Implementation and completion criteria

I would implement this as two passes over the existing sector DAG.

Local pass. Construct generic-epsilon sourced jets, allocate retained amplitudes, impose the established physical exclusions, and propagate the necessary jet depths backward. Retain exact mode coordinates and normalization rules, including all resonance-generated logarithms.

Finite-expression pass. Reuse or construct each small H
j,0
	​

, materialize the needed homogeneous epsilon coefficients and inverses, then apply (19)–(22) bottom-up using exact lower-sector expressions. Evaluate common-point rows at 7/12 and the four CF269 rows at 5/12, undo all gauges, and form (1).

For storage, preserve shared homogeneous kernels, counterterm coefficients and integral nodes. Do not expand the same source expression separately for every surviving input or family. Only construct columns that can reach requested rows. The integral definitions must be fully instantiated to finite epsilon order, but need not be flattened into large expressions.

For verification, the strongest inexpensive checks are the exact generic-epsilon jet recurrence, the differential identity behind (2), correct endpoint valuations, and cutoff independence. Numerical checks can compare two counterterm depths and compare the reconstructed normal solution with ordinary-point evolution for randomly assigned retained amplitudes. No AMFlow values are needed to verify this connection construction.

Finally substitute the resulting coefficient map into all 91 saved finite solutions, performing the required Laurent convolutions and closing the imported scalar-definition dependencies.

The completion criterion is an explicit substitution for every old shared ordinary-point symbol, with at most 83 remaining meromorphic input series and no unresolved connection objects. The finite jet is only the endpoint counterterm; the exact residual integral is what turns the physical mode count into that substitution.
