# Epsilon-order bounds for endpoint matching

2026-09-05. Focused follow-up to the mathematical review, before implementation.
Conversation: https://chatgpt.com/c/6a9c64ec-3cc4-83e8-b40c-9b568241fd3b

## Question

Thank you; your corrections about distributions on [0,1], Laurent-valued endpoint maps, matrix powers, and amplitude products will be included. I have one focused mathematical question before finalizing the design.

How can we establish a SAFE FINITE epsilon valuation bound for the map from ordinary-point constants to local endpoint coefficients, without first computing the complete global solution/matching matrix? Your review rightly says indicial data alone does not supply that map.

Possible route to challenge: work in an epsilon-regular system that is regular-singular at the boundary, before any homogeneous gauge with complicated logarithms. Frobenius coefficient recursions have denominators n+lambda_i(eps)-lambda_j(eps). Only finitely many integer n are resonant at eps=0; outside that range their inverses are epsilon-regular. Thus one might bound the Laurent poles of the entire local fundamental matrix by a finite computation through the resonant range, retaining matrix powers/logarithms and accounting for all meromorphic normalization factors. A determinant/Wronskian argument might bound its inverse at an ordinary matching point. Transport over a compact nonsingular path in an epsilon-regular system is epsilon-regular, so the global part introduces no additional poles. Does this yield a sound constructive bound under explicit hypotheses? If not, give a counterexample and the missing information. Do not claim this covers corners, irregular singularities or arbitrary cut kinematics without their own hypotheses.

Related qualification: requiring only f^[1](0), rather than f^[1](x) everywhere, still may require higher-order transport at a fixed endpoint or a boundary calculation. It is a reduction of requested information, not necessarily a guarantee of lower computational complexity. On a positive-dimensional face, that object remains a function of tangential variables; it must not be relabelled an arbitrary constant. Please make the honest deliverable precise for solutions up to kinematics-independent constants.

For context, the saved generic double-real coefficient table has 347 entries: direct finite-output upper orders -1 for 2, 0 for 203, 1 for 131, 2 for 7, 3 for 1, 4 for 1, and 2 zero coefficients. All six directly occurring CF303 masters have valuation-zero coefficients there. This is before downstream endpoint/counterterm effects, not a final NNLO order table.

Please keep this follow-up focused on a noncircular endpoint-matching bound and the conditions for failing honestly.


## Pro response

Displayed text preserved by the Pro bridge. The design note rewrites the
relevant equations in ordinary mathematical notation.

Yes—your proposed route can give a sound, constructive, noncircular bound under uniform Fuchsian hypotheses and a specified local normalization. Two corrections are essential:

Bound the actual resonant linear operators, not merely the number of resonances or the indicial roots at ϵ=0.

Bound the inverse local fundamental matrix as well. This can also be done from a finite local calculation, without evaluating the global matching matrix.

The resulting statement is an order-planning theorem. It does not supply the endpoint coefficient functions themselves.

1. Hypotheses under which the argument works

Let x=0 be one smooth boundary face, with tangential variables y. Suppress y temporarily and choose a frame Z in which

x
∂x
∂Z
	​

=A(x,ϵ)Z,A(x,ϵ)=R(ϵ)+
n≥1
∑
	​

A
n
	​

(ϵ)x
n
.

Require the following.

Joint local regularity. The matrix A is holomorphic jointly in (x,ϵ) on a common neighborhood of (0,0). Thus the normal equation is Fuchsian, and its residue and regular coefficients are ϵ-regular. These two properties must hold in the same frame.

Uniform ordinary transport. An ϵ-independent matching point x=ρ

=0 lies inside this neighborhood. There is a fixed compact path from X
0
	​

 to (ρ,y) on which the full connection is holomorphic in ϵ and nonsingular in kinematics, uniformly for sufficiently small ϵ.

Specified normalization and branches. Fix the branch of logx, the local Frobenius normalization, and every meromorphic basis-change factor. Arbitrary rescalings of local modes change the matching-map valuation.

Effective coefficient information. The ϵ-dependence must be available sufficiently exactly to establish valuations and distinguish an identically singular resonance operator from one whose determinant merely vanishes to high order. Rational or explicitly controlled algebraic dependence is suitable; a finite sample of an otherwise unspecified analytic function is not.

For a positive-dimensional face, apply the argument at fixed y, or uniformly on a compact tangential patch where the required ranks and denominators are controlled. A generic meromorphic statement in y is not automatically uniform at another tangential singularity.

These are stronger assumptions than “regular-singular for every nonzero ϵ.”

2. The finite resonant calculation

Define the Sylvester operator on matrices

L
n
	​

(ϵ)=nId−ad
R(ϵ)
	​

,ad
R
	​

(H)=RH−HR.

Its eigenvalues are n−λ
i
	​

+λ
j
	​

. Let

S={n∈Z
>0
	​

:detL
n
	​

(0)=0},m=max(S∪{0}).

There are only finitely many such positive integers. This is the finite-resonance structure underlying the usual Fuchsian normal-form construction. Equal eigenvalues are not a positive-n resonance here; their Jordan logarithms can remain in x
R(ϵ)
. 
Yakovenko
+1

First, the case with no persistent positive resonance

Suppose every L
n
	​

(ϵ) is invertible over the field of meromorphic ϵ-germs, although some become singular at ϵ=0. Seek

Φ(x,ϵ)=H(x,ϵ)x
R(ϵ)
,H=1+
n≥1
∑
	​

H
n
	​

(ϵ)x
n
.

Then

L
n
	​

H
n
	​

=
k=1
∑
n
	​

A
k
	​

H
n−k
	​

.
	​


For n>m, L
n
−1
	​

 is ϵ-regular. Therefore the recurrence introduces no new Laurent poles after m: it only propagates those already present.

If

s
n
	​

=max(0,−ν
ϵ
	​

(L
n
−1
	​

)),

a sufficient bound is

ν
ϵ
	​

(H
n
	​

)≥−h
+
	​

,h
+
	​

=
n∈S
∑
	​

s
n
	​

.

Computing the finite prefix H
1
	​

,…,H
m
	​

, or propagating sharper bounds through it, can improve this:

h
+
	​

=
0≤n≤m
max
	​

max(0,−ν
ϵ
	​

(H
n
	​

))

is sufficient for the entire tail.

Here ν
ϵ
	​

 of a matrix means the minimum entry valuation. Importantly, s
n
	​

 concerns the full inverse Sylvester operator. Jordan structure can make its pole order larger than one would infer by counting scalar denominators.

Persistent resonances require logarithms, not division by zero

When detL
n
	​

≡0, the log-free construction need not exist. Retain

Φ(x,ϵ)=H(x,L,ϵ)x
R(ϵ)
,L=logx,

with

H=1+
n≥1
∑
	​

x
n
H
n
	​

(L,ϵ),

where each H
n
	​

 is polynomial in L. The recurrence becomes

(∂
L
	​

+L
n
	​

)H
n
	​

=
k=1
∑
n
	​

A
k
	​

H
n−k
	​

.
	​


At the finitely many resonant indices, solve this polynomial equation over the meromorphic coefficient field, fixing its free normalization choices. On the generalized zero-eigenspace of L
n
	​

, the equation is solved by polynomial integration with a nilpotent matrix; on its invertible complement, by a finite algebraic inverse on polynomials. This is the role of logarithmic terms in resonant Frobenius/Levelt solutions. 
arXiv

For n>m, if the right-hand side has logarithmic degree at most d,

(∂
L
	​

+L
n
	​

)
−1
S=
j=0
∑
d
	​

(−1)
j
L
n
−j−1
	​

∂
L
j
	​

S.

All these inverse matrices are ϵ-regular. Consequently, neither the pole order nor the logarithmic degree can increase after the finite resonant range.

Thus the finite prefix again supplies a bound for every local coefficient.

Why an infinite tail cannot secretly create additional poles

This also needs convergence, not merely coefficientwise formal reasoning. Under joint holomorphy, R(ϵ) is uniformly bounded for small ϵ, and

∥L
n
−1
	​

∥=O(1/n)

uniformly for sufficiently large n. After multiplying by the finite factor ϵ
h
+
	​

, a standard majorant argument gives locally uniform convergence at the ordinary matching point. The usual Fuchsian convergence theorem supplies the underlying mechanism; the uniform parameter estimate is what makes it applicable to this valuation argument. 
Yakovenko
+1

Only the finite resonant prefix is needed to bound the tail. The tail need not be computed to establish the bound.

3. The inverse has its own finite-prefix bound

This is the useful strengthening of your proposal.

Write

G=H
−1
=1+
n≥1
∑
	​

x
n
G
n
	​

(L,ϵ).

It satisfies

(∂
L
	​

+L
n
	​

)G
n
	​

=−
k=1
∑
n
	​

G
n−k
	​

A
k
	​

.
	​


Construct its coefficients through m from the finite formal inversion

G
n
	​

=−
k=1
∑
n
	​

G
n−k
	​

H
k
	​

,G
0
	​

=1.

This fixes the inverse’s resonant normalization consistently with H. Beyond m, its differential recurrence again has only ϵ-regular inverses.

Therefore a sufficient bound is

h
−
	​

=
0≤n≤m
max
	​

max(0,−ν
ϵ
	​

(G
n
	​

)),

taking the minimum valuation over the coefficients of the logarithmic polynomials. It follows that

ν
ϵ
	​

(Φ(ρ,ϵ)
−1
)≥−h
−
	​

.
	​


The factor

ρ
−R(ϵ)
=exp[−R(ϵ)logρ]

is holomorphic and invertible in ϵ, so it contributes no additional poles.

This avoids computing either the full local fundamental matrix at ρ or the global connection matrix.

Your Wronskian argument also works—with the normalization included

For the normalization above,

detΦ(x,ϵ)=x
trR(ϵ)
exp[
n≥1
∑
	​

n
trA
n
	​

(ϵ)
	​

x
n
].

At fixed ρ

=0, this determinant is an ϵ-holomorphic unit. For a rank-r system, the adjugate formula consequently gives the coarser bound

ν
ϵ
	​

(Φ
−1
)≥−(r−1)h
+
	​

.

The direct inverse recurrence may be substantially sharper. Merely knowing that a determinant is nonzero for ϵ

=0 would not suffice: its order of vanishing at ϵ=0 must be controlled. The specified local normalization is what controls it here.

A useful special case follows immediately:

If R(0) has no positive-integer eigenvalue differences, then m=0, h
+
	​

=h
−
	​

=0, and this normalized local matching introduces no ϵ-poles.

In particular, this applies when R(0) is nilpotent. Jordan logarithms retained inside the matrix power do not invalidate that statement.

4. The ordinary-to-endpoint bound

Let T
ρ
	​

(y,ϵ) be transport in the ϵ-regular frame from X
0
	​

 to (ρ,y). Analytic dependence of ordinary differential equations on parameters, continued over a compact nonsingular path, gives

T
ρ
	​

, T
ρ
−1
	​

holomorphic in ϵ.

Their values need not be computed to use this conclusion. 
Faculty of Mathematics

Suppose the original basis is

I=GZ,C=I(X
0
	​

,ϵ),

and the desired local fundamental matrix is ΦS, where S(y,ϵ) is a specified meromorphic normalization. Then its local coefficient vector is

c(y,ϵ)=M(y,ϵ)C(ϵ),

with

M=S
−1
Φ(ρ)
−1
T
ρ
	​

G(X
0
	​

)
−1
.

Hence

ν
ϵ
	​

(M)≥ν
ϵ
	​

(S
−1
)−h
−
	​

+ν
ϵ
	​

(G(X
0
	​

)
−1
).
	​


This is the requested noncircular sufficient bound. With no additional meromorphic transformations, it reduces to

ν
ϵ
	​

(M)≥−h
−
	​

.

If the endpoint quantities actually requested are

f
β
	​

(y,ϵ)=K
β
	​

(y,ϵ)c(y,ϵ),

where K
β
	​

 extracts specified local coefficients, include its valuation:

ν
ϵ
	​

(K
β
	​

M)≥ν
ϵ
	​

(K
β
	​

)+ν
ϵ
	​

(M).

Such factors include original-basis reconstruction, mode decompositions, and local normalization factors. They must not be omitted merely because the core local system is regular.

These are conservative bounds for the map itself. They do not require knowing the physical constants or exploiting correlations among them.

5. What can fail, and what must then be reported
One resonance can produce arbitrarily many Laurent poles

Consider

xZ
′
=(
1+ϵ
p
0
	​

x
0
	​

)Z,p≥1.

There is only one positive resonant index at ϵ=0: n=1. A normalized log-free Frobenius matrix is

Φ(x,ϵ)=(
x
1+ϵ
p
0
	​

−x/ϵ
p
1
	​

).

At x
0
	​

=1,

c
1
	​

=C
1
	​

+ϵ
−p
C
2
	​

,c
2
	​

=C
2
	​

.

The ordinary transport is nevertheless ϵ-regular:

U(x,1;ϵ)=
	​

x
1+ϵ
p
0
	​

ϵ
p
x
1+ϵ
p
−x
	​

1
	​

	​

.

Thus the number of resonances and the residue at ϵ=0 do not bound the matching poles. The order with which the resonance is approached matters. Setting the splitting identically to zero instead gives a logarithmic local solution, not permission to divide by the zero resonance denominator.

Pointwise Fuchsian behavior is not uniform Fuchsian behavior

For x
0
	​

>0, consider

Z
′
=(
x
1
	​

+
x+ϵ
ϵ
	​

)Z,Z(x
0
	​

)=C.

For each fixed nonzero ϵ, x=0 is Fuchsian. At each fixed positive x, the connection is holomorphic in ϵ. Nevertheless,

Z(x,ϵ)=
x
0
	​

x
	​

(
x
0
	​

+ϵ
x+ϵ
	​

)
ϵ
C,

so the leading coefficient of x is

c(ϵ)=
x
0
	​

1
	​

(
x
0
	​

+ϵ
ϵ
	​

)
ϵ
C.

It contains ϵlogϵ and is not meromorphic in ϵ.

The missing hypothesis is the common local neighborhood: the other singularity x=−ϵ approaches the boundary. Indeed, expanding the regular part about x=0 produces unbounded negative powers of ϵ.

This is a concrete reason not to infer your theorem from separate fixed-ϵ regular-singular statements.

The normalization itself can invalidate an unqualified bound

Even for dZ=0, choosing Φ=ϵ
p
1 makes the local coefficients ϵ
−p
C. There is no normalization-independent bound on an arbitrarily normalized endpoint coefficient map.

Accordingly, failure should be reported specifically: no uniform Fuchsian neighborhood established; resonant meromorphic normalization unresolved; normalization factor’s valuation unknown; or tangential patch approaching an uncontrolled singularity. None licenses substituting an arbitrary safety margin.

6. The honest deliverable

There are two distinct achievements.

Before computing the matching functions, the deliverable is a proved finite bound for M or for the requested projections K
β
	​

M, together with its local frame, domain, and normalization. This establishes which finite orders may be required. It is not yet an explicit endpoint solution. Local expansions and matching are separate operations in practical Feynman-DE methods as well. 
arXiv

For an endpoint result up to kinematics-independent constants, the requested quantities must ultimately be supplied as

f
β
[q]
	​

(y)=
j,m
∑
	​

F
βj
[q−m]
	​

(y)C
j
[m]
	​

,∂
y
	​

C
j
[m]
	​

=0,
	​


with the required F
βj
	​

 explicitly defined.

On a positive-dimensional face, these are functions of y. Requesting f
[1]
(0,y) rather than the full f
[1]
(x,y) reduces the information requested; it does not prove that computing it is cheaper.

An alternative presentation

c(y,ϵ)=W(y,y
∗
	​

;ϵ)b(ϵ)

is also genuinely “up to constants” if W is explicit and b is kinematics-independent. But to combine it with a bulk answer normalized by C=I(X
0
	​

,ϵ), the relation between b and C must be supplied; they cannot be treated as additional independent data.

The proposed finite-resonance analysis therefore closes the order-planning gap under explicit hypotheses, without closing—or pretending to close—the endpoint-matching computation itself. Your coefficient table, including the valuation-zero coefficients of the six directly occurring CF303 masters, remains the direct-output input to that calculation, not a final endpoint-adjusted NNLO order table.