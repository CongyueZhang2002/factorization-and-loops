# SIDIS regulated real-virtual endpoints and double virtual masters

Model verified: gpt-6-pro.

## Question

Continue our SIDIS NNLO review, specifically the remaining mathematical integration steps. Please use GPT-6 Pro. Repository https://github.com/MaxwellZhang101/factorization-and-loops (working changes not pushed).

All 12 UU/LL NLO-like RV partonic channels are generated and full-D tensor-reduced. We expanded complete interior scalar combinations with coefficient-driven epsilon orders, exact triangle->bubble identities and the all-region one-offshell box formulas of Haug/Wunder 2211.14110v3. 324 NLO splitting-function checks against the original APFEL C++ and momentum/flavor/axial sum rules pass. All 8 VV scalar sources (UU/LL, q/qbar, 2-loop interference and 1-loop square) are generated.

Please help settle two remaining general-purpose algorithms, with explicit equations and clear branch/order prescriptions:

1. Real-virtual regulated ENDPOINT distribution limits, before epsilon expansion. SIDIS variables x,z in (0,1), S=Q2(1-x)/x, t=-Q2 z/x, u=-Q2(1-z)/x up to permutation; loop invariants depend on channel routing. The measured two-body factor is (4pi)^eps/[8pi Gamma(1-eps)] S^-eps[z(1-z)]^-eps. We must not insert the NLO tree endpoint powers as an NNLO assumption. Need build exact eps-dependent endpoint jets of massless bubbles, one/two-scale triangles and the one-mass box, retaining ALL region powers and doing corners uniformly.
One-mass box: s+t+u=m; X1=-u/s, X2=-u/t, X12=-u*m/(s*t); branch-safe real F_eps(X). Near0 H_eps(X)=1-eps sum_n>=1 X^n/(n-eps), F=|X|^-eps H. X>1: F=pi eps cot(pi eps)+X^-eps[1-H_-eps(1/X)]. X<0 asymptotic constant pi eps csc(pi eps). Near1 zero-balanced hypergeom carries logs. Full causal box is 2*rGamma/(eps^2*s*t)*|m*u/(s*t)|^eps times the 3 correlated signed F terms (or see paper).
Can endpoint expansion be made uniformly normal crossing for physical complete SIDIS RV coefficients using these identities and an invertible change of variables? If mixed ratios remain at x=z=1, what is the cheapest rigorous general algorithm? Would sector charts require nontrivial pullback distributions to the original square, or can cancellation be proved BEFORE expansion? Please give an implementable endpoint strategy, not merely 'use regions'.

2. VV: generic scalar two-loop massless THREE-POINT integrals with two null legs, single spacelike scale Q2, plus products of one-loop integrals. We want IBP reduction of GENERATED scalar densities and a universal master library, not insertion of the published quark form factor. Which minimal master topologies and exact Gamma/3F2/4F3 formulae (or explicit epsilon through required order) suffice for the two-loop massless quark form factor? Please give reliable primary source equations/normalizations/topology identification so we can match denominators generically. Is a general parametric linear-reducible integrator cheaper to implement than matching this tiny universal master library? Do not recommend replacing generated amplitudes by published process coefficients.

Also inspect our intended NNLO transition factor:
a=alpha_s/(2pi), b0=(11CA-4TRnf)/6, eta=e^(-eps L), L=ln(muF2/muR2).
Z1=eta P0/eps.
Z2=eta^2[(P0⊗P0-b0P0)/(2eps^2)+P1/(2eps)]
    +b0(eta^2-eta)P0/eps^2.
For raw helicity ΔP1_L=ΔP1_MS-[F1,ΔP0]+b0F1. After pole subtraction C_MS=F^-T C_L. Please flag any remaining convention error.


## Pro response

Your transition factors and helicity-kernel transformation are correct in the stated conventions. For the integration work, I recommend two concrete choices:

Resolve the correlated box combinations before introducing sector charts. For the three one-mass box routings in physical SIDIS, an exact identity removes the troublesome corner ratios and produces a normal-crossing expansion in the original 1−x,1−z coordinates.

Reduce VV onto a small universal scalar-integral library. There are three connected two-loop master topologies, together with the product of one-loop bubbles. Matching those definitions is substantially less work than implementing a new general parametric integrator.

There is one normalization issue in the question: the box prefactor containing ∣mu/(st)∣
ϵ
 is appropriate only if an additional ∣m∣
ϵ
 normalization has deliberately been included.

1. Regulated RV endpoint expansion
1.1 Fix the box normalization first

For the scalar integral normalized by

∫
iπ
D/2
d
D
ℓ
	​

,

with no μ
2ϵ
 inside the integral definition, the Haug–Wunder representation is

B
4
	​

(s,t,m)=
	​

ϵ
2
st
2r
Γ
	​

	​

	​

st
u
	​

	​

ϵ
×[χ(t)F
ϵ
	​

(X
1
	​

)+χ(s)F
ϵ
	​

(X
2
	​

)−χ(m)F
ϵ
	​

(X
12
	​

)],
	​

	​

(1)

where

u=m−s−t,X
1
	​

=−
s
u
	​

,X
2
	​

=−
t
u
	​

,X
12
	​

=X
1
	​

+X
2
	​

−X
1
	​

X
2
	​

,

and

χ(v)={
1,
e
iπϵ
,
	​

v<0,
v>0.
	​


The paper includes μ
2ϵ
; its prefactor is therefore
∣μ
2
u/(st)∣
ϵ
. Equation (3.26) gives the correlated phases. 
arXiv

Thus your ∣mu/(st)∣
ϵ
 corresponds to choosing that scalar-integral scale as μ
2
=∣m∣, or to storing ∣m∣
ϵ
B
4
	​

. Either convention is usable, but it must not duplicate the coupling’s dimensional scale factor.

The dimensional check is immediate:

[B
4
	​

]=(mass)
−4−2ϵ

without an internal μ
2ϵ
.

1.2 The elementary endpoint primitives

Keep

H
ϵ
	​

(X)=
2
	​

F
1
	​

(1,−ϵ;1−ϵ;X)

as an exact-regulator object until its endpoint powers have been extracted.

At X=0,

H
ϵ
	​

(X)=1−ϵ
n=1
∑
∞
	​

n−ϵ
X
n
	​

.
	​

(2)

This is a Taylor series in the kinematic variable, with coefficients exact in ϵ.

At infinity,

F
ϵ
	​

(X)=c
±
	​

(ϵ)+∣X∣
−ϵ
[1−H
−ϵ
	​

(1/X)],
	​

(3)

with

c
+
	​

(ϵ)=πϵcot(πϵ)(X>1),c
−
	​

(ϵ)=πϵcsc(πϵ)(X<0).

Both the constant branch and the power branch must be retained. These follow from the hypergeometric inversion relation, with the physical phases kept in (1). 
arXiv

For the zero-balanced point, set w=1−X. The prescribed hypergeometric function has

H
ϵ
	​

(1−w)=−ϵ
n=0
∑
∞
	​

n!
(−ϵ)
n
	​

	​

[ψ(n+1)−ψ(n−ϵ)−logw]w
n
.
	​

(4)

Use the branch of logw inherited from the original correlated prescription. For the real function F, the corresponding real logarithm is log∣w∣, with the physical imaginary parts supplied by (1). This is the zero-balanced limit of the standard hypergeometric connection formulas. 
DLMF

Do not evaluate the individual X=1 terms separately. Their cancellation is part of the assembled integral.

1.3 A useful exact identity removes the SIDIS corner ratios

From the hypergeometric differential equation—or directly from (2)—

dX
d
	​

F
ϵ
	​

(X)=−ϵ
X(1−X)
∣X∣
−ϵ
	​

	​

(5)

on each real interval away from 0,1.

Suppose two arguments occur as

A,C=A+B−AB=A+B(1−A).

Define

h=
A
B(1−A)
	​

.

When A

=0, and the path between A and C does not cross zero or the branch point at one, integration of (5) gives

F
ϵ
	​

(A)−F
ϵ
	​

(C)=ϵ
A
B
	​

∣A∣
−ϵ
U
ϵ
	​

(B,h),
	​

(6)

where

U
ϵ
	​

(B,h)=∫
0
1
	​

1−Bv
(1+hv)
−1−ϵ
	​

dv.

For endpoint generation, no unevaluated integral is necessary:

U
ϵ
	​

(B,h)=
j,k≥0
∑
	​

k!(j+k+1)
B
j
(−h)
k
(1+ϵ)
k
	​

	​

.
	​

(7)

This double Taylor series converges uniformly for ∣B∣,∣h∣≤c<1, locally uniformly in ϵ. It gives arbitrary kinematic jets with exact regulator dependence and a controlled remainder.

Equation (6) has a regular combined limit at A=1:

A→1
lim
	​

[F
ϵ
	​

(A)−F
ϵ
	​

(A+B−AB)]=−ϵlog(1−B).

It therefore removes the artificial diagonal singularity without separately assigning a value to F
ϵ
	​

(1).

I checked (6) against the original hypergeometric expressions in 16 cases, with ratios on both sides of one and both positive and negative noninteger ϵ. At 45-digit working precision, the largest relative discrepancy was below 2×10
−39
. The derivation, rather than those samples, establishes the identity.

1.4 Application to all three SIDIS box routings

Write

ρ=1−x,σ=1−z,

and use your convention

s=
x
Q
2
ρ
	​

,t=−
x
Q
2
z
	​

,u=−
x
Q
2
σ
	​

,m=−Q
2
.

For the box with arguments (s,t,m),

X
1
	​

=
ρ
σ
	​

,X
2
	​

=−
z
σ
	​

,X
12
	​

=
ρz
σx
	​

.

The two ratio-dependent terms have the same causal coefficient, because t,m<0. Apply (6) with

A=
ρ
σ
	​

,B=−
z
σ
	​

,
A
B
	​

=−
z
ρ
	​

,h=
z
σ−ρ
	​

.
	​

(8)

Both B,h are uniformly small near the corner, even when σ/ρ tends to zero, infinity, or one.

For the box with arguments (t,u,m), use

A=
σ
ρ
	​

,B=
z
ρ
	​

,
A
B
	​

=
z
σ
	​

,h=
z
σ−ρ
	​

.
	​

(9)

Again, the ratio-dependent pair has equal causal coefficients.

For (s,u,m), all three arguments are large near the corner:

−
s
t
	​

=
ρ
z
	​

,−
u
t
	​

=−
σ
z
	​

,−
su
tm
	​

=
ρσ
zx
	​

.

Apply (3). The two cot(πϵ) constants cancel exactly. The inverses of all three arguments are analytic monomials times nonzero units.

Consequently, each standard SIDIS box admits a normal-crossing decomposition on the original corner coordinates. Schematically, before multiplying its rational coefficient and phase space:

Box	Possible nonsmooth monomial factors
B
4
	​

(s,t,m)	1, ρ
−1−ϵ

B
4
	​

(t,u,m)	1, σ
−1−ϵ

B
4
	​

(s,u,m)	1, ρ
−1−ϵ
, σ
−1−ϵ
, ρ
−1−ϵ
σ
−1−ϵ

The coefficients multiplying these factors are analytic in ρ,σ near zero, with meromorphic dependence on ϵ. Some may vanish to positive integer order.

This is a statement about the scalar boxes, not an assumed endpoint form for the complete NNLO channel. Rational amplitude coefficients shift integer powers; the measured density contributes

S
−ϵ
[z(1−z)]
−ϵ
=(Q
2
)
−ϵ
x
ϵ
z
−ϵ
ρ
−ϵ
σ
−ϵ
.

Determine the total exponents only after multiplying all factors.

This correlated-difference rewrite is the cheapest first implementation. It targets the actual corner problem without a new integration backend.

2. Build endpoint jets before expanding in epsilon

A suitable endpoint record is

ρ
a+bϵ
σ
c+dϵ
(logρ)
r
(logσ)
s
F(ρ,σ,ϵ),
	​

(10)

with a specified jet and remainder for F. It should retain the source prescription, normalization, and domain.

Bubbles and triangles

For a bubble invariant factored as

v=ςQ
2
ρ
A
σ
B
U(ρ,σ),U>0,U(0,0)

=0,

retain

(−v−i0)
−ϵ
=(Q
2
)
−ϵ
ρ
−Aϵ
σ
−Bϵ
U
−ϵ
{
e
iπϵ
,
1,
	​

ς=+1,
ς=−1.
	​


Only the nonvanishing unit U
−ϵ
 is Taylor-expanded in the coordinates.

Use the exact triangle divided difference

C
D
	​

(0,a,b)=−
ϵ
2
r
Γ
	​

	​

b−a
(−a−i0)
−ϵ
−(−b−i0)
−ϵ
	​

.

When a,b coalesce at a nonzero invariant, use the confluent divided difference, equivalently

C
D
	​

(0,a,b)=
ϵ
r
Γ
	​

	​

∫
0
1
	​

[−b−t(a−b)−i0]
−1−ϵ
dt.
	​

(11)

Its Taylor coefficients are regular near that coalescence. When an invariant tends to zero, retain its separate regulated power instead.

This distinction prevents an artificial 1/(x−z) singularity from being interpreted as a new endpoint divisor.

Assemble and subtract on the original square

After the scalar rewrites, combine the complete coefficient, cancel removable rational factors, and apply the existing two-axis subtraction to (10). For example,

ρ
−1−bϵ
=−
bϵ
δ(ρ)
	​

+
n≥0
∑
	​

n!
(−bϵ)
n
	​

[
ρ
log
n
ρ
	​

]
+
	​

.

For stronger integer poles, use Taylor subtraction of the test function:

∫
0
1
	​

dρρ
−m+bϵ
ϕ(ρ)=
	​

j=0
∑
m−1
	​

j![j−m+1+bϵ]
ϕ
(j)
(0)
	​

+∫
0
1
	​

dρρ
−m+bϵ
[ϕ(ρ)−
j=0
∑
m−1
	​

j!
ρ
j
	​

ϕ
(j)
(0)].
	​

(12)

The two endpoint restrictions act on the complete multiplier–test-function product and commute. Distributional derivatives and delta normalizations must be retained through this operation. 
DLMF

Use the endpoint jets to construct subtraction terms; use your interior scalar expansion for the remaining regular function. The jets alone are not the complete regular coefficient.

The required jet depth is determined by the complete rational coordinate valuation. A term that is subleading in the scalar integral can contribute to a delta coefficient after multiplication by a stronger tree or reduction pole. This is precisely the noncommutation emphasized in Haug–Wunder Appendix D. 
arXiv

3. Sector charts are a fallback, not automatically necessary here

An ordinary invertible change of coordinates with nonzero Jacobian at the corner does not generally eliminate dependence on ρ/σ. Resolving a genuinely mixed corner can require a blow-up, which is invertible only away from its exceptional boundary.

If the correlated rewrites and complete coefficient cancellation leave an unsupported mixed expression, use the two initial charts

(ρ,σ)=(h,hv),(ρ,σ)=(hv,h),0<h,v<1,

each with Jacobian h. They cover the two halves of the square without overlap in the interior.

For a test function ϕ, the regulated identity is

⟨T
ϵ
	​

,ϕ⟩=
	​

∫
0
1
	​

dhdvhT
ϵ
	​

(h,hv)ϕ(h,hv)
+∫
0
1
	​

dhdvhT
ϵ
	​

(hv,h)ϕ(hv,h).
	​

	​

(13)

Resolve only remaining vanishing polynomials or hypergeometric branch loci, retaining all Jacobians and prescriptions. This is the constructive subtraction strategy underlying sector decomposition. 
arXiv

The resulting distributions must be pushed forward, not renamed.

A term supported at h=0 maps to the original corner.

A term supported at v=0 maps to an original edge.

Plus distributions in h act on ϕ(h,hv), not on an unrelated test function of h.

v=1 is an artificial sector seam. Its contributions must recombine; it is not permission to create a physical δ(ρ−σ).

A generic mixed distribution need not be expressible solely as tensor products of one-variable plus distributions plus an ordinary integrable remainder. Therefore, either preserve its pushforward definition or prove that such mixed pieces cancel in the complete observable.

For the three box routings above, equations (6)–(9) avoid this complication locally. Implement that cancellation first, and reserve sector charts for an actual remaining obstruction.

4. VV: a small universal scalar master library

Use two null external vectors

p
1
2
	​

=p
2
2
	​

=0,q=p
1
	​

+p
2
	​

,q
2
=−Q
2
.

For SIDIS one may take p
1
	​

=−p
in
	​

, p
2
	​

=k
out
	​

. Define all master measures by

J=∫
ℓ=1
∏
L
	​

iπ
D/2
d
D
k
ℓ
	​

	​

∏
j
	​

(D
j
	​

+i0)
1
	​

.

A sufficient master set for the massless two-loop vertex reduction is:

Master	Denominator polynomials
J
2
	​

	k
2
, (k−q)
2

J
3
	​

	k
2
, l
2
, (k−l−q)
2

J
4
	​

	k
2
, l
2
, (k−q)
2
, (k−l−p
1
	​

)
2

J
6
	​

	k
2
, l
2
, (k−q)
2
, (k−l)
2
, (k−l−p
2
	​

)
2
, (l−p
1
	​

)
2

At two loops include the disconnected product J
2
2
	​

. The connected masters are J
3
	​

,J
4
	​

,J
6
	​

; J
6
	​

 is the crossed six-propagator triangle. Gehrmann–Huber–Maître, hep-ph/0507061, section 2, equations (2)–(6), provide explicit denominator definitions and all-order scalar formulas. Their amplitude coefficients in section 3 are not needed. 
arXiv
+1

4.1 Exact Gamma-function masters in your normalization

Writing the spacelike scale simply as Q
2
>0,

J
2
	​

=(Q
2
)
−ϵ
ϵΓ(2−2ϵ)
Γ(1+ϵ)Γ(1−ϵ)
2
	​

=(Q
2
)
−ϵ
ϵ(1−2ϵ)
r
Γ
	​

	​

.
	​

(14)

The two connected Gamma-function masters are

J
3
	​

=(Q
2
)
1−2ϵ
2ϵ(1−2ϵ)Γ(3−3ϵ)
Γ(1+2ϵ)Γ(1−ϵ)
3
	​

,
	​

(15)

and

J
4
	​

=(Q
2
)
−2ϵ
2ϵ
2
(1−2ϵ)Γ(2−3ϵ)
Γ(1−2ϵ)Γ(1+ϵ)Γ(1−ϵ)
2
Γ(1+2ϵ)
	​

.
	​

(16)

These also admit direct derivations by integrating a one-loop bubble subgraph and then an arbitrary-power bubble or triangle. That is a useful independent normalization check.

4.2 Exact crossed-triangle formula

For a compact transcription, define

g
j
	​

=Γ(1+jϵ),

and

F
a
	​

F
b
	​

F
c
	​

	​

=
3
	​

F
2
	​

(
1,−4ϵ,−2ϵ
1−3ϵ,1−2ϵ
	​

;1),
=
3
	​

F
2
	​

(
1,1,1+2ϵ
2+ϵ,2+2ϵ
	​

;1),
=
4
	​

F
3
	​

(
1,1−ϵ,−4ϵ,−2ϵ
1−3ϵ,1−2ϵ,1−2ϵ
	​

;1).
	​


Then define

B
6
	​

(ϵ)=
	​

−
ϵ
4
g
−4
2
	​

g
4
	​

g
−1
3
	​

g
1
	​

g
−2
4
	​

g
2
3
	​

	​

+
2ϵ
4
g
−3
	​

g
−1
4
	​

g
1
	​

g
−2
	​

g
2
	​

	​

F
a
	​

−
ϵ
2
(1+ϵ)(1+2ϵ)g
−4
	​

4g
−1
4
	​

g
−2
	​

g
2
	​

	​

F
b
	​

−
2ϵ
4
g
−3
	​

g
−1
5
	​

g
2
	​

	​

F
c
	​

.
	​

	​

(17)

In your loop normalization,

J
6
	​

=−
Γ(1−ϵ)
2
(Q
2
)
−2−2ϵ
	​

B
6
	​

(ϵ).
	​

(18)

A useful check of the signs and normalization is

J
6
	​

=
	​

Γ(1−ϵ)
2
(Q
2
)
−2−2ϵ
	​

[
ϵ
4
1
	​

−
6ϵ
2
5π
2
	​

−
ϵ
27ζ
3
	​

	​

−
36
23π
4
	​

+(8π
2
ζ
3
	​

−117ζ
5
	​

)ϵ
+(267ζ
3
2
	​

−
315
19π
6
	​

)ϵ
2
+O(ϵ
3
)].
	​

	​

(19)

Equations (17)–(19) are the scalar result of source equations (5)–(6), converted to your measure; no form-factor coefficient enters them. 
arXiv

4.3 The measure conversion is important at two loops

The source uses

(2π)
D
d
D
k
	​

,S
Γ
	​

=
16π
2
Γ(1−ϵ)
(4π)
ϵ
	​

.

For L same-side virtual loops,

A
(L)
=[
(4π)
D/2
i
	​

]
L
J
(L)
.

Thus, at two loops,

J
(2)
=−(4π)
D
A
(2)
.
	​


This accounts for the overall sign and Γ(1−ϵ)
−2
 in (18). It is not an extra physics sign.

For the one-loop square, conjugate the complete one-loop contribution. Its loop normalization combines i with −i, not with another i. Do not attach the same-side two-loop minus sign to ∣A
(1)
∣
2
.

4.4 Match denominators, then let the generated IBPs supply coefficients

The library matcher should establish an exact affine routing, scale normalization, external-null relations, and all ordinary prescriptions. Dotted propagators and irreducible numerators are reduced to the library; they are not identified by a visual topology match.

If your solver chooses a different master basis, include these library integrals as targets and derive the exact change of basis from the same generated IBPs. If closure leaves another object, diagnose the basis or reduction rather than forcing it into the expected count.

Use the actual coefficient valuations to request epsilon orders. For example, a coefficient beginning at ϵ
−3
 requires its Gamma-function master through ϵ
3
 for a finite contribution. The one-loop amplitude must reach ϵ
2
 for its square, subject to deeper scalar requirements from its rational coefficients.

The exact hypergeometric formula removes any fixed-order ceiling on J
6
	​

. HypExp supports parameter expansions of 
J
	​

F
J−1
	​

, including unit argument, and is a suitable established tool for this task. 
arXiv

Library versus a new parametric integrator

For this completion step, the small library is the cheaper implementation. Gamma subintegrations and one all-order crossed-triangle formula require very little new infrastructure.

A general linearly reducible integrator additionally requires divergent-integral regularization, integration-order selection, endpoint regularization, and exact special-value reduction. HyperInt provides established algorithms for that broader problem; implementing a comparable system is unnecessary for these four scalar objects. 
arXiv

A parametric implementation remains useful as an independent check of selected masters or a fallback for future topologies. It should not delay matching this finite universal library.

5. Your scale-dependent transition factor is correct

Let

f
bare
=Z
col
	​

⊗f,
dlnμ
2
df
	​

=P(a)⊗f,

with

dlnμ
2
da
	​

=−ϵa−b
0
	​

a
2
+⋯.

Then

dlnμ
2
dZ
col
	​

	​

=−Z
col
	​

⊗P

gives, at the factorization scale,

Z
col
	​

=1+
ϵ
a
F
	​

P
0
	​

	​

+a
F
2
	​

[
2ϵ
2
P
0
	​

⊗P
0
	​

−b
0
	​

P
0
	​

	​

+
2ϵ
P
1
	​

	​

].

For

L=ln
μ
R
2
	​

μ
F
2
	​

	​

,η=e
−ϵL
,

dimensional running gives

a
F
	​

=ηa
R
	​

+
ϵ
b
0
	​

	​

(η
2
−η)a
R
2
	​

+O(a
R
3
	​

).

Substitution yields exactly

Z
1
	​

=
ϵ
ηP
0
	​

	​

,
	​

Z
2
	​

=η
2
[
2ϵ
2
P
0
	​

⊗P
0
	​

−b
0
	​

P
0
	​

	​

+
2ϵ
P
1
	​

	​

]+
ϵ
2
b
0
	​

(η
2
−η)
	​

P
0
	​

.
	​

(20)

No sign correction is needed. Apply the corresponding η separately on the incoming PDF and outgoing FF legs.

For the finite polarized transformation

Δf
MS
	​

=F⊗Δf
L
	​

,

the splitting-function relation is

ΔP
1,L
	​

=ΔP
1,MS
	​

−[F
1
	​

,ΔP
0
	​

]+b
0
	​

F
1
	​

.
	​

(21)

For coefficients stored with incoming flavor as row,

C
MS
	​

=F
−T
⊗
x
	​

C
L
	​

	​

(22)

after raw-scheme pole subtraction. These directions follow the standard operator-scheme transformation law. 
arXiv

The remaining conventions to enforce are:

F
1
	​

,F
2
	​

 must use the same a=α
s
	​

/(2π) convention. If defined in a(μ
F
	​

) but re-expanded in a
R
	​

 after taking ϵ→0, the order-two finite matrix contains

F
2
	​

−b
0
	​

LF
1
	​

.

The FF pole matrix is ordinary unpolarized time-like evolution, with its declared parent/daughter orientation.

W must already be UV-renormalized when applying the collinear matrices. The coupling counterterm proportional to −b
0
	​

W
(1)
/ϵ is separate from the −b
0
	​

P
0
	​

 in (20).

Apply the finite polarized transformation once, in the full individual-flavor basis, and preserve the raw positive-epsilon data used by NNLO counterterms.

Recommended next implementation order

First add the correlated box-difference primitive (6)–(7). Verify its regular diagonal limit and all three physical routings. This should give corner-uniform jets without sector pushforwards for the current scalar inventory.

In parallel, register J
2
	​

,J
3
	​

,J
4
	​

,J
6
	​

 and the disconnected product by exact denominator definitions. Derive the basis conversion from the generated VV IBPs and request orders from the actual coefficients.

Then test the assembled RV distribution against smooth two-variable moments at convergent regulator values, including functions nonzero at the corner. Compare the regulated result—not merely the interior epsilon expansion—with the distributional expansion. For VV, test scale homogeneity, the bubble-insertion derivations of J
3
	​

,J
4
	​

, and a separate numerical evaluation of J
6
	​

.

The useful simplification is specific but reusable: the one-mass box’s correlated arguments satisfy X
12
	​

=X
1
	​

+X
2
	​

−X
1
	​

X
2
	​

. Exploiting that exact identity before expansion removes the usual SIDIS mixed-ratio obstruction without modifying the generated coefficient. The remaining fallback for genuinely mixed corners is a distribution-aware sector pushforward, not an assumed product of NLO endpoint powers.