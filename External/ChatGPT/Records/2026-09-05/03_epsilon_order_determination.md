# Epsilon-order determination before implementation

2026-09-05. Requested mathematical review by the user. Reviewed with the
signed-in ChatGPT Pro conversation:
https://chatgpt.com/c/6a9c64ec-3cc4-83e8-b40c-9b568241fd3b

No production implementation changes were made during this review.
The initial prompt describes the local code; the GitHub base is not claimed
to include those uncommitted changes.

## Question

Please critically review the MATHEMATICS of choosing sufficient, economical epsilon orders for a general NNLO framework. The user explicitly asks us to think carefully and discuss with Pro BEFORE implementing. No implementation should be proposed as already justified. They also insist routine validation should not dominate computation; AMFlow will check physical masters later.

Repository: https://github.com/CongyueZhang2002/factorization-and-loops
Current Git base e8c62cce8d16370e78f9c428a204c4be52688d26; the new solver is in local uncommitted changes, so use the description here rather than assuming GitHub contains it. Your earlier review in this conversation helped us construct explicit finite quadratures, including all 45 CF303 masters. Current finite exports are U orders -3..4 for CF269/CF48 and -2..4 for CF303, NOT justified physical NNLO ranges.

Conventions: dI=A I, I(X,eps)=Q(X,eps) P(X,eps), dP=B P, with B regular in eps and B0 strictly lower triangular after explicit homogeneous reductions. V(X,X0;eps) solves this prepared system, V(X0)=1. Our current stored original fundamental matrix is U=Q V Q0^{-1}, so I=U C, C=I(X0,eps). Every required nested integral and epsilon convolution is materialized; the reader is not a lazy generator. Q includes all epsilon rescalings and homogeneous basis changes. It is meromorphic in eps. B may have any nonnegative epsilon orders, not necessarily eps*dlog.

CURRENT ORDER LOGIC (needs mathematical challenge):
* A producer accepts desired hard-function orders K and generic epsilon valuations a_i of rational coefficients multiplying physical masters. It reports upper bounds max(K)-a_i. With externally supplied lower bounds ell_i it gives the entire interval ell_i..max(K)-a_i. These lower bounds are merely labelled assumptions, not derived.
* Given requested U orders with maximum N, the solver computes V through max(0,N-min_entry val(Q)-min_entry val(Q0^{-1})); this uses global minima, all columns, and uniform internal order.
* To expand physical I coefficients, it assumes independent C_j series lower bounds ell_j, requests U through max physical order - min ell_j, then multiplies by C. This can be safe but wasteful. Physical constants may obey cancellation constraints not captured by separate lower bounds.
* It does not yet include future endpoint distribution extraction/integration, UV renormalization, or PDF mass-factorization operations in an end-to-end order derivation.

Please challenge/refine the following ideas, with equations, counterexamples and a clear boundary between proofs and sufficient bounds:

1. For a fixed final output F_alpha=sum_i R_alpha_i I_i through order N_alpha, after combining all rational coefficients of the SAME master, val(R_alpha_i)=a_alpha_i gives upper master demand N_i=max_alpha(N_alpha-a_alpha_i). It is generically sharp for independent master coefficient data, but not an invariant minimum after basis changes or known relations. Coefficients R themselves need expansion through N_alpha-ell_i. Gaps in epsilon support and exact zero coefficients could reduce demands further. What exactly is guaranteed, including errors/remainders?

2. We should propagate demanded (component,epsilon order) pairs backward through the actual linear operations, Q, V, Q0^{-1}, and the DE recurrence, instead of using global minima. For V_ab^[n], recurrence needs B_ak^[q] V_kb^[n-q], with q=0 using earlier rows. Weighted directed-path bounds give lower valuations d_kb on V_kb; B_ak only needs q<=n-d_kb. For factor E=R Q and D=Q0^{-1} C (if justified lower bounds d_b for D are known), V_ab need not go beyond N-val(E_a)-d_b; structural nonreachability eliminates entries. But computing all generic masters vs only a selected observable are different deliverables. Is this exact dependency closure (with conservative valuations) sufficient, and when is it minimal? Can costly cancellations be postponed safely? Must the final output demand cover all original masters to preserve generality, or can a general framework legitimately specialize to input requests without family-specific code?

3. Lower Laurent bounds are part of the mathematics, not a configurable guess. How should we derive them economically from normalized integral definitions, including cut integrals, higher propagator powers, dimension shifts, irreducible numerators, Gamma factors and external phase-space factors? Sector decomposition/resolution gives meromorphic bounds: independent logarithmic endpoint factors plus explicit Gamma poles, with cancellations able to improve the bound. Can a cheap analytic power-counting/sector analysis give sound master-specific bounds without evaluating them? Do NOT assume "NNLO means every master starts at eps^-4", or confuse UT epsilon normalization with intrinsic poles. Which portions can the DE alone infer, and which necessarily require integral/boundary input?

4. There is an additional trap: physical master lower bounds need not permit all independently chosen C_j series with those individual bounds. Example U=1+(x-x0)N/eps with nonzero constant N^2=0. If the physical I is regular, C^[0] must satisfy N C^[0]=0; just assuming each C_j starts at eps^0 allows spurious eps^-1 terms away from x0. How should we handle the allowed constant module/linear constraints, and can a good Laurent basis avoid excessive orders before the actual constants are evaluated? Please distinguish safe overestimates from falsely assuming arbitrary constants satisfy physical bounds. Is an epsilon-finite basis a better target than trying to make every original master shallow?

5. Endpoint operations can invalidate an ordinary-point epsilon order count. On 0<x<1,
x^(-1-a eps) = -delta(x)/(a eps) + sum_{n>=0} (-a eps)^n/n! [log^n(x)/x]_+.
Thus a coefficient regular at eps=0 at generic x can need one more epsilon order for the delta contribution. Multiple unresolved endpoints, subtraction derivatives for higher endpoint powers, resonant exponent differences and Jordan logarithms can change demands. We should retain exact x^(lambda(eps)) (and logs) until distribution extraction, not integrate a pointwise truncated epsilon series term-by-term. Give a precise operator-based order rule, prerequisites (including uniformity, regions and endpoint asymptotic data), and counterexamples. If endpoint exponents are not known before solving full masters, can a finite local Frobenius/regions analysis provide exactly what is needed for order planning without a circular full computation?

6. UV renormalization and mass factorization can require higher orders of lower-loop/born pieces, even if only final NNLO eps^0 is wanted. The framework should compose their Laurent-valued linear/convolution maps before requesting orders, and include Jacobians/normalizations/distribution factors in the correct stage. How should cancellations across sectors/real/virtual pieces be exploited without assuming finiteness to discard potentially needed information?

7. We do not want a costly proof engine worse than solving. Is a two-level strategy mathematically defensible: cheap guaranteed sufficient bounds from exact coefficient valuations + proved integral/endpoint bounds; then only optimize the entries that drive expensive extra orders using exact coefficient combination, epsilon-finite basis choices, known boundary constraints and sparse dependence? State stopping criteria and how to make truncation errors explicit. AMFlow sample values cannot prove a missing epsilon coefficient is zero.

Please give your best recommended mathematical design BEFORE implementation; identify any flaw in the above equations, particularly correlations of constants and endpoint distributions. Use standard amplitude/mathematics terminology. Primary literature pointers are welcome, e.g. Chetyrkin et al hep-ph/0601165 epsilon-finite bases, finite/quasi-finite integral bases, and sector decomposition. Do not substitute a universal weight-four prescription or an arbitrary safety margin for the argument.


## Pro response

The bridge preserves the displayed response text. Some displayed equations
lose their two-dimensional mathematical layout; the accompanying design
note rewrites the relevant equations explicitly.

Your fixed-output valuation rule is correct as a sufficient bound. The current global-minimum rules are also conservative, provided their input lower bounds are valid. What is not yet justified is interpreting the resulting ranges as physical NNLO completeness. That requires specifying the final operations, the admissible initial data, and the meaning of the remainder near integration endpoints.

The central refinement is this:

Choose orders by propagating truncation errors through the actual requested maps—not by assigning a universal expansion depth to each master. When a singular map depends only on endpoint data, request the additional orders of that endpoint data, not automatically of the entire bulk function.

This is a mathematical design recommendation based on your local description, not an assessment that the uncommitted implementation already satisfies it.

1. Fixed rational combinations: the precise sufficient statement

Write ν(f)=val
ϵ
	​

f, with ν(0)=+∞. Initially, consider Laurent series whose coefficients are functions on an ordinary kinematic domain, not distributions.

Suppose

F
α
	​

=
i
∑
	​

R
αi
	​

I
i
	​

,ν(R
αi
	​

)=a
αi
	​

,ν(I
i
	​

)≥ℓ
i
	​

.

The coefficients multiplying the same normalized master should be combined before assigning an exact a
αi
	​

. Using the minimum valuation of uncombined terms remains safe, but may overestimate the demand.

For F
α
	​

 through ϵ
N
α
	​

, a sufficient master cutoff is

M
i
	​

=
α:R
αi
	​


=0
max
	​

(N
α
	​

−a
αi
	​

).
	​


Terms with a
αi
	​

+ℓ
i
	​

>N
α
	​

 cannot contribute and can be omitted.

If the rational coefficients are themselves expanded, the sufficient cutoff for each is

L
αi
	​

=N
α
	​

−ℓ
i
	​

.
	​


These formulas have a direct remainder proof. If

I
i
	​

−
I
i
	​

=O(ϵ
M
i
	​

+1
),R
αi
	​

−
R
αi
	​

=O(ϵ
L
αi
	​

+1
),

then

R
αi
	​

I
i
	​

−
R
αi
	​

I
i
	​

=R
αi
	​

(I
i
	​

−
I
i
	​

)+(R
αi
	​

−
R
αi
	​

)
I
i
	​

,

so its valuation is at least

min{a
αi
	​

+M
i
	​

+1,L
αi
	​

+ℓ
i
	​

+1}≥N
α
	​

+1.

Thus the guarantee is

F
α
	​

−
F
α
	​

=O(ϵ
N
α
	​

+1
),

in the same function space in which the input remainder statements hold. The last qualification becomes decisive at endpoints.

Sharpness and its limitations

The cutoff N
α
	​

−a
αi
	​

 is sharp relative to independent master-coefficient data: changing

I
i
[N
α
	​

−a
αi
	​

]
	​


changes F
α
[N
α
	​

]
	​

 through the nonzero leading coefficient of R
αi
	​

.

But actual master coefficients are not independent arbitrary functions. They satisfy differential equations, boundary constraints, and sometimes known identities. Therefore this is not a basis-invariant minimum.

For a nonconsecutive requested set K
α
	​

, the more precise demanded master orders are

{n−r:n∈K
α
	​

,R
αi
[r]
	​


=0,n−r≥ℓ
i
	​

}.

An interval is a convenient overestimate. Proven support gaps and exact zeros can reduce it; presumed transcendental-weight patterns or sampled zeros cannot.

2. Sparse backward dependence is sufficient—but generally not mathematically minimal

Your proposed replacement of global minima is sound.

Let

B=
q≥0
∑
	​

ϵ
q
B
[q]
,V=
n≥0
∑
	​

ϵ
n
V
[n]
.

Assign an edge k→a the weight

β
ak
	​

=
μ
min
	​

ν(B
μ,ak
	​

),

using all coordinate equations. Let d
ab
	​

 be the minimum total weight of a directed path b→a, including the empty path for a=b.

Then

ν(V
ab
	​

)≥d
ab
	​

.
	​


If there is no path, V
ab
	​

=0. These are lower bounds: cancellations between paths can increase the true valuation.

For a demanded coefficient V
ab
[n]
	​

, the recurrence contains

B
ak
[q]
	​

V
kb
[n−q]
	​

.

A potentially contributing term must satisfy

β
ak
	​

≤q≤n−d
kb
	​

.
	​


The q=0 terms refer to earlier rows in the common triangular ordering. Consequently, the backward dependence closes after finitely many steps. Nonconsecutive support in B
ak
	​

 can further restrict the allowed q.

This establishes the sufficiency of a demand closure using conservative valuations. It does not require evaluating the iterated integrals or proving their independence.

Compose the requested row with the basis transformation where useful

For a selected output, write

F
α
	​

=E
α
	​

VD,E
α
	​

=R
α
	​

Q,D=Q
0
−1
	​

C.

Suppose

ν(E
αa
	​

)≥e
αa
	​

,ν(D
b
	​

)≥δ
b
	​

.

Then

E
αa
	​

V
ab
	​

D
b
	​


has lower valuation

e
αa
	​

+d
ab
	​

+δ
b
	​

,

and the sufficient upper demand on V
ab
	​

 is

M
ab
V
	​

=
α
max
	​

(N
α
	​

−e
αa
	​

−δ
b
	​

).
	​


No coefficient is needed when this cutoff lies below d
ab
	​

.

Corresponding sufficient bounds for the other factors are

M
αa
E
	​

=
b
max
	​

(N
α
	​

−d
ab
	​

−δ
b
	​

),
M
b
D
	​

=
α,a
max
	​

(N
α
	​

−e
αa
	​

−d
ab
	​

).

The same reasoning continues through Q, Q
0
−1
	​

, and their constituent transformations.

The valuations of E need not be determined by an expensive global simplification. A lower bound obtained from its uncombined terms is safe. Exact combination can be reserved for entries responsible for expensive extra orders.

What “minimal” would mean

Backward reachability gives the necessary inputs for the chosen expression structure, after the zeros already recognized. It need not give the smallest mathematical answer because it does not automatically detect

a
∑
	​

E
αa
	​

V
ab
	​

=0,

relations among constants, or cancellations between integrals.

Postponing such cancellations is safe: it increases work, not the truncation error. Exploiting them before they are established is unsafe.

Also, a general framework need not compute every master for every request. Generality means handling arbitrary supported input systems and output requests without family-specific mathematics. A selected-observable export and an all-master fundamental-matrix export are different, legitimate deliverables. Each must state its scope.

3. Lower Laurent bounds require integral information, but need not require integral evaluation

The DE cannot establish an absolute physical lower bound. If I solves

dI=AI,

then ϵ
−m
I solves the same equation for every integer m. Even dI=0 permits constants with arbitrary pole order.

The DE can establish transport valuations, propagate supplied bounds, and impose consistency relations among leading coefficients. It cannot identify the physical normalization’s absolute pole order without integral or boundary information.

A sound bound from a resolved integral representation

Sector decomposition isolates singular factors in parameter integrals, including applications to real-radiation phase-space integrals. This is the relevant mathematical mechanism—not a universal loop-counting prescription. 
arXiv

Suppose a valid representation of a normalized master has finitely many terms

I
i
	​

(ϵ)=
s
∑
	​

g
is
	​

(ϵ)∫
[0,1]
m
s
	​

	​

j
∏
	​

t
j
α
sj
	​

+β
sj
	​

ϵ
	​

(logt
j
	​

)
p
sj
	​

h
is
	​

(t,ϵ)dt,

where, after the stated resolution, h
is
	​

 is sufficiently smooth at the boundary and holomorphic in ϵ, with the required uniform control.

Taylor subtraction reduces the pole question to moments

∫
0
1
	​

t
α+βϵ+k
(logt)
p
dt=
(α+βϵ+k+1)
p+1
(−1)
p
p!
	​

.

For β

=0, a pole at ϵ=0 occurs only when

α+k+1=0.

Therefore a sufficient bound is

ν(I
i
	​

)≥
s
min
	​

	​

ν(g
is
	​

)−
j∈R
s
	​

∑
	​

(p
sj
	​

+1)
	​

,
	​


where R
s
	​

 contains the potentially resonant variables in that term. Known vanishing Taylor coefficients can improve the bound, but ignoring such cancellations remains safe.

Two details matter:

Count simultaneously occurring singular factors within a term, not all sectors added together. Adding sectors cannot increase the maximum pole order beyond the worst sector.

Power divergences are not counted by their power. For example, by analytic continuation,

∫
0
1
	​

x
−2−ϵ
dx=−
1+ϵ
1
	​


is regular at ϵ=0, whereas

∫
0
1
	​

x
−2−ϵ
(1+x)dx=−
1+ϵ
1
	​

−
ϵ
1
	​

.

The pole comes from the relevant Taylor coefficient. An exponent −m−ϵ does not automatically produce an ϵ
−m
 pole.

If a resonant exponent is independent of ϵ, dimensional regularization may not regulate that singularity. An additional regulator or a separately justified cancellation may be required. A Laurent-order rule cannot repair an undefined regulated integral.

How economical can this be?

A useful hierarchy of mathematical inputs is:

Bounds from an already established finite or quasi-finite representation.

Complete scaling analysis in a domain where its applicability is proved.

Resolution only for the singular configurations not covered by simpler arguments.

For example, if an existing exact reduction gives

I
i
	​

=
j
∑
	​

S
ij
	​

J
j
	​

,ν(J
j
	​

)≥λ
j
	​

,

then

ν(I
i
	​

)≥
j
min
	​

(ν(S
ij
	​

)+λ
j
	​

)

without evaluating any J
j
	​

.

Quasi-finite bases have convergent parameter integrals after extracting the overall Gamma prefactor; in the conventional normalization, that prefactor can retain a simple pole. The original existence construction is for Euclidean integrals and explicitly does not establish the same result for arbitrary physical or phase-space integrals. 
arXiv

There is no justification for promising that a tight, master-specific bound will always be cheap. A broader theorem-backed bound may be cheaper, and refinement can be confined to the masters for which that bound causes substantial extra work.

Normalizations and cut integrals

The bound must apply to the actual integral definition, including dimension shifts, propagator powers, irreducible numerators, and Gamma or reciprocal-Gamma prefactors. Multiplying by ϵ
r
 changes the bound; calling that normalization “UT” does not establish the original integral’s pole order.

Cut propagator powers require the corresponding derivatives of delta distributions, not the uncut power-counting rule applied without modification. Reverse unitarity explicitly relates these derivatives to higher cut-propagator powers. 
APS Journals

External phase-space factors must be assigned to the correct stage. A factor excluded from the master definition belongs in a later multiplication or endpoint map; it must neither be omitted nor counted twice.

4. Constant correlations: a safe overestimate is not the same as an admissible generic solution

Your nilpotent example identifies a genuine flaw in treating physical bounds as independent initial-data bounds.

Take

U=(
1
0
	​

(x−x
0
	​

)/ϵ
1
	​

),C=(
C
1
	​

C
2
	​

	​

).

If both physical masters are regular, then

C
2
[0]
	​

=0.

Assuming merely C
1
	​

,C
2
	​

∈C[[ϵ]] permits a spurious pole in I
1
	​

.

There are two valid but different domains of validity.

Independent point data. For arbitrary constants satisfying

ν(C
j
	​

)≥c
j
	​

,

the propagated generic bound is

ν(I
i
	​

)≥
j
min
	​

(ν(U
ij
	​

)+c
j
	​

).
	​


This is safe without knowing physical correlations.

Physically constrained data. Proven integral bounds may imply a smaller allowed set of constants, on which stronger bounds for I
i
	​

 hold. Those stronger bounds must not be advertised as holding for every independently chosen C
j
	​

.

Formally, let K
0
	​

 be the field of kinematics-independent constants. The constants compatible with component bounds ℓ
i
	​

 form the module

C
ℓ
	​

={C∈K
0
	​

((ϵ))
r
:(UC)
i
	​

∈ϵ
ℓ
i
	​

F[[ϵ]] for every i},
	​


where F is the specified space of kinematic functions. This is the module allowed by those bounds, not necessarily the complete set selected by the physical integral definitions.

Its conditions include

j
∑
	​

k+m=n
∑
	​

U
ij
[k]
	​

(X)C
j
[m]
	​

=0,n<ℓ
i
	​

,

as identities in X, not merely at X
0
	​

. Given finite lower bounds on U and C, only finitely many constant coefficients enter these forbidden-order conditions.

A better Laurent basis can expose the constraints

In the example,

C=(
1
0
	​

0
ϵ
	​

)
C

gives

UC=(
1
0
	​

x−x
0
	​

ϵ
	​

)
C
,

with independently regular 
C
.

This removes an artificial singular presentation. But it does not remove genuine information:

I
1
[0]
	​

=C
1
[0]
	​

+(x−x
0
	​

)C
2
[1]
	​

.

The formerly higher-order coefficient C
2
[1]
	​

 has become a leading coefficient of 
C
.

Once the relevant exact constraints are known, linear algebra over the Laurent-series ring can provide an adapted basis. Finding all functional relations needed to construct the optimal module can be expensive; it should not be a prerequisite for obtaining conservative sufficient orders.

In particular, regularity of the prepared connection does not imply regularity of its physical initial data:

D=Q
0
−1
	​

C.

The transformation can introduce poles in D. Assuming ν(D
b
	​

)≥0 merely because B is regular would be incorrect.

Epsilon-finite versus finite masters

An ϵ-finite basis eliminates spurious poles in the reduction coefficients for the integral combinations under consideration. It does not mean that the masters themselves are finite, nor that subsequent renormalization and endpoint operators are pole-free. Chetyrkin et al. explicitly distinguish the bare highest-loop contribution from lower-loop contributions multiplied by renormalization constants. 
arXiv

An ϵ-finite basis is therefore a useful optimization target for the requested maps. Making every original master “shallow” is not an invariant objective. The meaningful target is reducing the difficult information needed by the final expression.

5. Endpoint extraction requires a different remainder statement

The identity

x
−1−aϵ
=−
aϵ
δ(x)
	​

+
n≥0
∑
	​

n!
(−aϵ)
n
	​

[
x
log
n
x
	​

]
+
	​


is a distributional identity including the endpoint, such as on [0,1]. It is not an identity of functions merely on 0<x<1. Such expansions are used explicitly in NNLO real-radiation calculations. 
arXiv

The operator rule

Let E describe the allowed endpoint data, including the necessary smoothness, asymptotic factors, and boundary jets. Suppose a linear endpoint operation is a meromorphic family

T(ϵ)=
q≥v
T
	​

∑
	​

ϵ
q
T
[q]
:E⟶D,

where D is the target distribution space.

If the input truncation obeys

f−
f
	​

∈ϵ
M+1
E[[ϵ]],

then

T(f−
f
	​

)∈ϵ
M+1+v
T
	​

D[[ϵ]].

Hence

M≥N−v
T
	​

	​


is sufficient.

A pointwise remainder O(ϵ
M+1
) at every fixed interior point does not establish the required E-valued remainder.

For example,

f
ϵ
	​

(x)=
(x+ϵ)
2
ϵ
	​


is O(ϵ) at every fixed x>0, but

∫
0
1
	​

f
ϵ
	​

(x)dx=
1+ϵ
1
	​


has a nonzero limit. This illustrates precisely what a missing uniform endpoint statement can conceal.

Important economy: the extra order often belongs only to a boundary jet

Let

f(x,ϵ)=f
0
	​

(x)+ϵf
1
	​

(x)+⋯

be smooth at zero. For a test function φ,

⟨[x
−1−aϵ
f]
[0]
,φ⟩=
	​

−
a
f
1
	​

(0)
	​

φ(0)
+∫
0
1
	​

x
f
0
	​

(x)φ(x)−f
0
	​

(0)φ(0)
	​

dx.
	​


Thus the finite distribution needs f
0
	​

(x) in the bulk and f
1
	​

(0) at the endpoint. It does not require the full function f
1
	​

(x).

More generally, write

T=
p=1
∑
P
	​

ϵ
−p
T
−p
	​

+T
≥0
	​

.

For the coefficient at order N, the extra data are

T
−p
	​

f
[N+p]
,

not necessarily all of f
[N+p]
.

For local endpoint extension, these singular operators depend on finitely many normal derivatives. At a face they can still produce functions of tangential variables; at a corner they can reduce to corner data. This distinction offers a major reduction in the required bulk quadratures.

Higher powers, logarithms, and resonances

For

x
−m−aϵ
(logx)
p
,m≥1,

Taylor subtraction involves derivatives through order m−1. With a nonzero linear regulator slope, the potential pole order is p+1, not m.

More generally, if

λ(ϵ)+m=O(ϵ
r
)

with exact vanishing order r, the resonant Taylor moment can have pole order

r(p+1).

Multiple independent endpoint factors can add their pole orders. But this count must be made in resolved local terms, with their explicit ϵ-prefactors retained.

Jordan logarithms require particular care. A useful alternative to diagonalizing nearly coincident exponents is to retain a local matrix power. In a representation containing x
M(ϵ)−1
,

∫
0
1
	​

x
M(ϵ)−1
x
k
dx=(M(ϵ)+k1)
−1
,
	​


initially in a convergence domain and then by meromorphic continuation.

The Laurent valuation of this finite matrix inverse gives the endpoint order loss, including Jordan effects.

For example,

M(ϵ)=ϵ1+J,J
r
=0,

can give inverse entries with poles through ϵ
−r
. Conversely, if

M(ϵ)=ϵA,A invertible,

then M
−1
=ϵ
−1
A
−1
, even when A has Jordan blocks. Counting individual logarithmic terms without their ϵ-prefactors would overestimate the loss.

This matrix treatment can also avoid spurious poles caused by diagonalizing a degenerating exponent basis. It does not eliminate the need for a valid local normal form.

Can local analysis plan orders without solving everything?

Yes, for regular-singular endpoint problems with a sufficiently complete local description. A finite Frobenius calculation can determine the potentially nonintegrable powers, required normal Taylor orders, logarithmic structure, and relevant regulator denominators. It need not determine every bulk coefficient or fix any physical constant.

But indicial roots alone are insufficient. The analysis must include:

The actual measure and rational prefactors.

Meromorphic normalizations or matching factors that can carry ϵ-poles.

Intersections of singular boundaries and the required tangential data.

A remainder that is uniformly integrable after the prescribed subtractions.

A list of candidate regions is not automatically a proof of completeness. Likewise, a normal expansion at generic tangential kinematics does not control an unresolved corner.

Local analysis can therefore avoid a circular full computation, but only when it supplies these bounds. It does not automatically supply the map from ordinary-point constants to endpoint coefficients.

6. Renormalization and factorization belong in the same order calculation

At fixed perturbative order, organize the relevant bare contributions into a vector W. Renormalization and mass factorization then act through Laurent-valued matrices, differential operators, and convolutions. Schematically,

H
(2)
=L
22
	​

W
(2)
+L
21
	​

W
(1)
+L
20
	​

W
(0)
.

The lower-loop demand is determined by the actual operator valuations. For example, a contribution

ϵ
L
−1
	​

	​

W
(1)
+
ϵ
2
M
−2
	​

	​

W
(0)

requires the relevant projections of W
(1)
 through order 1 and of W
(0)
 through order 2 for a finite final result. Additional endpoint operations can alter those demands.

Mass factorization is not merely multiplication by a number: its kernels act by convolution, and its cancellations are between appropriately matched distributions and channels. The NNLO bottom-fusion calculation provides a concrete example of separate real, virtual, and collinear-counterterm contributions. 
arXiv

There is also one qualification to the proposed all-linear picture: starting from amplitudes, an NNLO cross section includes products such as

∣M
(1)
∣
2
.

These require the product rule for Laurent orders, or must first be included as entries of a vector of interference/product contributions. Renormalization and factorization can then be treated as linear maps on that chosen input vector.

Mass counterterms can introduce derivatives with respect to masses; those derivatives may act on endpoint factors. Jacobians, spin projections, normalization factors, and evanescent terms must be included before the final truncation decision. A factor of ϵ is not negligible when a later map contains 1/ϵ.

Finiteness is not a license to discard information

Consider

F(ϵ)=
ϵ
f(ϵ)−f(0)
	​

.

It is finite, but

F
[0]
=f
[1]
.

Knowing finiteness does not remove the need for f
[1]
.

Cancellations should be exploited when there is an exact identity between the relevant input combinations or operator coefficients. Combining rational coefficients of the same master is the simplest example. Relations between real and virtual pieces require a common distributional setting; cancellation of poles does not by itself determine the finite remainder.

7. A two-level strategy is mathematically defensible

The appropriate separation is between sufficient order selection and optional reduction of overestimates.

First level: establish a sufficient finite demand

Use exact or conservative coefficient valuations, proved integral lower bounds, and endpoint operator bounds. Propagate demanded component/order pairs through the actual maps and the triangular DE recurrence.

At this level:

Unrecognized cancellations remain unexploited.

Bounds may be broader than the true valuations.

Constants remain unevaluated.

No minimal function basis is required.

No full symbolic cancellation proof is required merely to obtain sufficient orders.

A conditional bound remains useful, but its consequence is also conditional. Labeling an assumed ℓ
i
	​

 does not turn the resulting NNLO claim into a theorem.

Second level: optimize only expensive overestimates

Refinement is justified where a particular pole or lower bound forces costly extra coefficient functions. Appropriate tools include exact coefficient combination, an ϵ-finite basis for the selected reductions, established constant constraints, tighter integral bounds, and endpoint-jet demands in place of whole-function demands.

Chetyrkin et al. give a relevant warning against optimizing isolated original masters: their example contains a particular combination of masters with apparently singular coefficients whose expression in an ϵ-finite basis is regular. The useful object is the combination entering the calculation. 
arXiv

Optimization can stop while conservative excess work remains. Finding the absolute minimum is not part of establishing correctness.

The stopping condition is a remainder inclusion

Let R be the set of omitted input tails consistent with the proved bounds and any constraints actually used. Let L
α
	​

 be the complete downstream map to output α. The sufficient stopping condition is

L
α
	​

(R)⊆ϵ
N
α
	​

+1
Y
α
	​

[[ϵ]]for every requested α,
	​


where Y
α
	​

 is the appropriate ordinary-function or distribution space.

With independent tails of order M
i
	​

+1 and downstream valuation bounds v
αi
	​

, a cheap sufficient test is

M
i
	​

+1+v
αi
	​

≥N
α
	​

+1
	​


for every contributing input. Sparse support and endpoint projections sharpen this without changing the principle.

This proof is compositional: elementary valuation inequalities, finite dependence closure, and previously established integral/endpoint bounds. It should not entail repeatedly verifying the full solved DE or evaluating masters numerically. AMFlow remains valuable for later physical checks, but sampled values cannot establish that an omitted coefficient or endpoint distribution is zero.

Recommended conclusion for the current exports

The CF269/CF48 and CF303 files demonstrate the construction of the stated transport coefficients. Their ranges alone do not establish physical NNLO sufficiency.

For example, an ordinary-point finite output with a coefficient of valuation −2 requires its master through ϵ
2
. If independent initial-data bounds start at ϵ
−4
, the conservative transport demand reaches ϵ
6
, already beyond the present upper cutoff 4. An endpoint pole can increase the demand further—although its additional information may be only an endpoint projection.

The mathematical design should therefore retain three distinct claims:

Transport completeness: the declared coefficients of U are explicitly available.

Sufficiency for requested master or observable coefficients: a remainder argument establishes that no omitted transport or constant coefficient contributes.

Sufficiency for final NNLO distributions or integrated outputs: that argument also includes endpoint extraction, renormalization, factorization, and the actual normalization conventions.

The strongest economical approach is not to prove every master’s exact leading pole or compute every master uniformly. It is to establish sound lower bounds, propagate precise requested information through the actual operations, and refine only the bounds that force expensive additional work.