# Double-collinear coefficients

## Prompt


The hard component, all three single-collinear Gamma coefficients, and the exceptional zero mode are now fixed:32 unknown series233coefficients remain, all slope -4. The3collinear normalization and finite-angle tests passed. We have about4hours left of the overnight run, so prioritize reliable rank gain and general code.

A rank screen using ONLY original UNIT CUT masters observes all32 remaining directions. Their selected generator profiles are appended below. They look suitable for double-collinear coefficients; no need to evaluate dotted targets directly. Please challenge the following normalization/representation and identify which classes admit a complete coefficient proof and cheap Gamma evaluation first.

Let particles1,2 form the approaching collinear cluster, particle3 recoils oppositely. Set d=D-2=2alpha,beta=D-3. External direction offsets eta_P satisfy
|eta_P-eta_R|² = 2(P.R)/((P.Q)(R.Q)) atedge.
For our3external directions this gives collinear centers (one possible choice)
eta_a=0, eta_b=8/sqrt(3), eta_c=2/sqrt(3), with squared separations4/3,64/3,12.

Tentative raw measure derivation:
Use normalized light-front plus fractions y_i=k_i^+/Q^+, transverse K_i=k_iT/sqrt(z), sumy1, sumK0. Exact massless raw measure is
z^beta/4 * dy1 dy2/(y1*y2*y3) * d^dK1 d^dK2 *
delta(1-sum_i K_i²/y_i).
This reproduces the known Dirichlet raw prefactor after Gaussian integration.
Put y1=(1-y3)v,y2=(1-y3)(1-v), K1=y1*t1,K2=y2*t2,K3=-(K1+K2).
Write T=v*t1+(1-v)*t2,Delta=t1-t2. The constraint is
(1-y3)/y3*T²+(1-y3)*v*(1-v)*Delta²=1.
In the double-collinear scaling t_i=sqrt(z)*ell_i/2,
y3~z*|v ell1+(1-v)ell2|²/4. The y3 delta Jacobian cancels the explicit1/y3.
Thus the leading raw measure is
z^(beta+2alpha)/2^(4alpha+2) *
v^(2alpha-1)(1-v)^(2alpha-1) dv d^(2alpha)ell1 d^(2alpha)ell2.

Leading generators, with stored fraction scale s_P=±2(P.Q) for quadratic external factors and s_P=(P.Q) for linear factors:
- on cap particle1: denominator ~ s_P*z*v/4 * |ell1-eta_P|²;
- on cap particle2: ~s_P*z*(1-v)/4 * |ell2-eta_P|²;
- external factor on cluster {1,2}: ~s_P*z/4 *
 [v|ell1-eta_P|²+(1-v)|ell2-eta_P|²];
- external factor involving recoil particle3 stays at its nonzero fraction limit1;
- s12=(k1+k2)²~z²*v*(1-v)/4 * |ell1-ell2|²;
- s13~z*v, s23~z*(1-v).
All integer signs and the original overall measure/routing factors stay outside the positive integral.

For a general recognized profile this yields a positive v integral and a two-loop Euclidean Gaussian integral. Cluster denominators have a rank2 quadratic form; they are NOT ordinary one-loop-momentum-square propagators, but Schwinger parametrization still gives a2x2 Gaussian matrix, determinantU and F. We can feed the resulting actual Euler representation to SubTropica, without inventing a graph.

Promising simple selected classes:
A) 3generators: one external factor on each cap particle plus s12. Transverse integral is the massless two-loop sunset propagator, Gamma-evaluable. With all powers1 it has a convergence strip1<alpha<3/2. Expected normal exponent4alpha-5=-1-4eps.
B) 4single-particle external factors, two distinct directions on each cap particle, no pair: two independent Euclidean bubbles times a Beta energy integral. Six independent observed rows, all powers1; strip1<alpha<2.
C) 2external cluster factors on the SAME cluster but distinct null directions: after ell1->sqrt(v)ell1,ell2->sqrt(1-v)ell2 this is a massless bubble in4alpha dimensions, times Beta(alpha,alpha), hence Gamma. For powers1 the strip1/2<alpha<1 appears possible; normal exponent4alpha-3=1-4eps.
D) 1cluster external factor plus1single-cap external factor. Integrating the other transverse loop gives Gamma and then a bubble. At original powers a=b=1 no common dimension strip exists (single IR demandsalpha>1, cluster UV demandsalpha<1). There IS a strip after independently varying powers, e.g a1,b2 and1<alpha<3/2. Can we rigorously continue the full coefficient in analytic propagator weights to a=b=1, with complete coefficient/overlap accounting? Or should we defer these six targets until an exact Mellin/hypergeometric derivation?
E) The remaining14targets have4ordinary factors, including1/2cluster external factors or2pair invariants. They fit the positive Gaussian/v representation, but may require analytic regulators and sum of multiple cap assignments.

Questions:
1) Check the raw measure, delta-Jacobian, factors4, energy exponents, and all leading generator formulas.
2) Give explicit Gamma formulas and mechanically checkable completeness conditions for A,B,C; ifD is valid, explain the analytic-weight continuation and whether regulator poles/other caps need summing.
3) How do we ensure ALL contributions at each targeted -4 power are included? A cluster can be one of3particle pairs. Some assignments may be scaleless; must prove or retain them. Selected profiles strongly pick a pair, but we must not infer completeness solely from projected rank.
4) For general positive Schwinger form, derive normalization of the Gaussian determinant/F representation including v powers and projective Gamma factor. Is there a practical exact positivity/convergence criterion (e.g finite parameter power counting) sufficient to justify a region coefficient by meromorphic continuation, rather than constructing a general physical-region classifier?
5) Recommend which subset to implement immediately, and how to avoid wasting hours on14complicated targets if they reduce to a few common boundary integrals. We can use exact linear identities/IBP and existing SubTropica, with two4-core jobs maximum.

Current selected targets (Subset labels are their original cut order; freely permute but preserve signs/scales):

Row 10 at -1 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {2}, kb, 1}, {"FinalStatePairInvariant", {1, 2}, None, 1}}
Row 21 at -1 - 4*eps: {{"ExternalSubsetInvariant", {2}, kb, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}, {"FinalStatePairInvariant", {1, 2}, None, 1}}
Row 81 at -1 - 4*eps: {{"FinalStatePairInvariant", {1, 3}, None, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 67 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 85 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 102 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 268 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}}
Row 273 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 297 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 60 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 71 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 166 at 1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}}
Row 216 at 1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 27 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 2}, kb, 1}}
Row 45 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1, 2}, kb, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 323 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 311 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 178 at -1 - 4*eps: {{"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}}
Row 182 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}}
Row 213 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 233 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1}, kb, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 283 at -2 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 2}, kb, 1}, {"FinalStatePairInvariant", {1, 2}, None, 1}, {"FinalStatePairInvariant", {2, 3}, None, 1}}
Row 287 at -2 - 4*eps: {{"ExternalSubsetInvariant", {2, 3}, kb, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"FinalStatePairInvariant", {1, 2}, None, 1}, {"FinalStatePairInvariant", {2, 3}, None, 1}}
Row 150 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 316 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}}
Row 327 at 1 - 4*eps: {{"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 161 at -1 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 319 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}}
Row 330 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 152 at -1 - 4*eps: {{"ExternalSubsetInvariant", {1}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}, {"ExternalSubsetInvariant", {1}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}
Row 333 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {3}, ka, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, ka, 1}}
Row 336 at -1 - 4*eps: {{"ExternalSubsetInvariant", {3}, kb, 1}, {"ExternalSubsetInvariant", {1, 3}, kb, 1}, {"ExternalSubsetInvariant", {3}, kc, 1}, {"ExternalSubsetInvariant", {1, 3}, kc, 1}}

## Pro response

Your leading measure and generator formulas are correct, provided the y
i
	​

 are plus fractions along the common spatial direction—not the invariant fractions used by the coalescing-null constructor. Classes A, B and C have the convergence domains you propose. Class D should not be deferred: an exact conditional two-body average reduces it to C times a Beta moment.

There is a second useful reduction: after stripping known scales, the 14 harder leading representations can be reduced algebraically to at most five candidate scalar integrals before IBP. That becomes a statement about physical amplitude inputs only after the corresponding coefficient-completeness checks.

I would implement the Gamma classes and this algebraic reduction before starting new SubTropica evaluations.

1. Measure and leading generators

Write d=2α=D−2, and reserve v∈(0,1) below for the cluster energy-sharing variable, not the fixed external invariant.

Your exact light-front measure is

dΦ
3
raw
	​

=
4
z
β
	​

y
1
	​

y
2
	​

y
3
	​

dy
1
	​

dy
2
	​

	​

d
d
K
1
	​

d
d
K
2
	​

δ(1−
i
∑
	​

y
i
	​

K
i
2
	​

	​

).
(1)

With q=y
3
	​

, y
1
	​

=(1−q)v, y
2
	​

=(1−q)(1−v), the fraction Jacobian is 1−q. The transverse change K
i
	​

=y
i
	​

t
i
	​

 contributes y
1
d
	​

y
2
d
	​

. The constraint is exactly

q
1−q
	​

T
2
+(1−q)v(1−v)Δ
2
=1.

For fixed scaled transverse coordinates,

t
i
	​

=
2
z
	​

	​

ℓ
i
	​

,

its small positive root obeys

q=
4
z
	​

∣vℓ
1
	​

+(1−v)ℓ
2
	​

∣
2
+O(z
2
).

The derivative of the constraint is

−
q
2
T
2
	​

−v(1−v)Δ
2
.

Thus its inverse Jacobian cancels 1/q at leading order. Solve the root at positive z before taking the limit; setting q=0 inside the delta function first can create an erroneous endpoint factor.

The resulting measure is

dΦ
3,dc
raw
	​

=
2
4α+2
z
β+2α
	​

v
2α−1
(1−v)
2α−1
dvd
2α
ℓ
1
	​

d
2α
ℓ
2
	​

.
	​

(2)

There is no extra c
2
	​

 multiplying (2). Both transverse integrations and their angular volumes are still present.

A useful independent exact parametrization

For checking both normalization and completeness, use the two physical directions n
1
	​

,n
2
	​

 and

v=
z
	​

2E
1
	​

	​

,λ=
2
1−n
1
	​

⋅n
2
	​

	​

.

The second energy is

z
	​

2E
2
	​

	​

=
1−vλ
1−v
	​

,

and the exact measure is

dΦ
3
raw
	​

=
2
4α+2
z
β
	​

(1−vλ)
2α
v
2α−1
(1−v)
2α−1
	​

dvdΩ
2α
	​

(n
1
	​

)dΩ
2α
	​

(n
2
	​

).
	​

(3)

Taking both angles into the common O(
z
	​

) cap immediately recovers (2). This representation avoids the light-front root degeneracy in proofs and numerical checks.

Generator normalization

Define

Q
P1
	​

=∣ℓ
1
	​

−η
P
	​

∣
2
,Q
P2
	​

=∣ℓ
2
	​

−η
P
	​

∣
2
,

and

Q
PC
	​

=vQ
P1
	​

+(1−v)Q
P2
	​

.

With your stored fraction scales s
P
	​

,

factor
external on particle 1
external on particle 2
external on cluster 12
s
12
	​

s
13
	​

s
23
	​

	​

leading expression
s
P
	​

zvQ
P1
	​

/4
s
P
	​

z(1−v)Q
P2
	​

/4
s
P
	​

zQ
PC
	​

/4
z
2
v(1−v)∣ℓ
1
	​

−ℓ
2
	​

∣
2
/4
zv
z(1−v).
	​

	​

(4)

All are correct. A subset containing the recoil particle has invariant fraction tending to one, so its external factor tends to its stored scale.

In particular, do not substitute the present y
1
	​

→v into the old external-fraction formulas. For an external direction in the common cap, the old invariant fraction on particle 1 instead tends to zvQ
P1
	​

/4.

Your centers satisfy

L
ac
	​

=
3
4
	​

,L
ab
	​

=
3
64
	​

,L
bc
	​

=12.

Use squared distances

L
PR
	​

=∣η
P
	​

−η
R
	​

∣
2

in the final formulas. Require L
PR
	​

>0 whenever a two-center formula is invoked.

For cluster quadratic denominators, replacing (P±K)
2
 by ±2P⋅K at the leading coefficient is justified by the previously proved uniform inequality

2P⋅K
K
2
	​

≤
2P⋅Q
z
	​

.
(5)

This is stronger than just a local cap estimate.

2. Explicit Gamma coefficients

Let N(D) denote the complete raw-measure-to-master prefactor, including routing and signs not already included in s
P
	​

.

Define the Euclidean bubble

B
α
	​

(a,b;L)=π
α
L
α−a−b
Γ(a)Γ(b)Γ(2α−a−b)
Γ(a+b−α)Γ(α−a)Γ(α−b)
	​

.
	​

(6)

It is the integral over 2α Euclidean dimensions with no π
−α
 normalization. Its derivation uses Gaussian integration and Euler’s Beta integral. 
DLMF

A. Two single-particle factors and the internal pair

Let the powers be a,b,c>0:

(s
P
	​

zvQ
P1
	​

/4)
−a
(s
R
	​

z(1−v)Q
R2
	​

/4)
−b
(z
2
v(1−v)∣ℓ
1
	​

−ℓ
2
	​

∣
2
/4)
−c
.

Put S=a+b+c. The transverse sunset integral is

T
α
	​

(a,b,c;L)=π
2α
L
2α−S
Γ(a)Γ(b)Γ(c)Γ(3α−S)
Γ(S−2α)Γ(α−a)Γ(α−b)Γ(α−c)
	​

.
	​

(7)

The complete coefficient is

C
A
	​

=N(D)
2
4α+2
s
P
a
	​

s
R
b
	​

4
S
	​

B(2α−a−c,2α−b−c)T
α
	​

(a,b,c;L
PR
	​

),
	​

(8)

at exponent

4α−1−a−b−2c.
	​


A sufficient convergence domain is

max(a,b,c)<α<
2
a+b+c
	​

.
	​

(9)

It also ensures convergence of both energy endpoints and all one-loop ultraviolet sublimits. For unit powers this is 1<α<3/2, and the exponent is −1−4ϵ.

Rows 10, 21 and 81 therefore require the same Gamma function of dimension, with their respective L
PR
	​

 and external scales.

B. Two eikonals on each cap particle

Let the powers on particle 1 be a
1
	​

,a
2
	​

, with sum A, and on particle 2 be b
1
	​

,b
2
	​

, with sum B. Then

C
B
	​

=
	​

N(D)
2
4α+2
s
P
a
1
	​

	​

s
R
a
2
	​

	​

s
U
b
1
	​

	​

s
V
b
2
	​

	​

4
A+B
	​

×B(2α−A,2α−B)B
α
	​

(a
1
	​

,a
2
	​

;L
PR
	​

)B
α
	​

(b
1
	​

,b
2
	​

;L
UV
	​

),
	​

	​

(10)

at exponent

4α−1−A−B.
	​


Sufficient conditions are

max(a
1
	​

,a
2
	​

)<α<A,max(b
1
	​

,b
2
	​

)<α<B.
	​

(11)

The energy Beta arguments are then positive automatically.

For all powers one, the energy Beta function cancels the two bubble denominators:

C
B
	​

=N(D)
2
4α+2
s
P
	​

s
R
	​

s
U
	​

s
V
	​

4
4
π
2α
	​

(L
PR
	​

L
UV
	​

)
α−2
Γ(4α−4)
Γ(2−α)
2
Γ(α−1)
4
	​

.
	​

(12)

The strip is 1<α<2, and the exponent is −1−4ϵ.

No new integral evaluation is needed for the six rows in this class.

C. Two external factors on the same cluster

For powers a,b, set S=a+b. The transformation

X
1
	​

=
v
	​

ℓ
1
	​

,X
2
	​

=
1−v
	​

ℓ
2
	​


has Jacobian [v(1−v)]
−α
. Both cluster quadratics become ordinary squared distances in 4α dimensions, with squared center separation L
PR
	​

. Therefore

C
C
	​

=N(D)
2
4α+2
s
P
a
	​

s
R
b
	​

4
S
	​

B(α,α)B
2α
	​

(a,b;L
PR
	​

),
	​

(13)

at exponent

4α−1−a−b.
	​


Its convergence conditions are

max(a,b)<2α<a+b.
	​

(14)

For unit powers, 1/2<α<1, and the exponent is 1−4ϵ. The Beta factor is exactly B(α,α), not the original B(2α,2α).

3. D reduces exactly to C; no new region integral is needed

Let K=k
1
	​

+k
2
	​

. At fixed timelike K, average over its two-body massless decay. For future-null R,

R⋅K
R⋅k
1
	​

	​

∼Beta(α,α).

Consequently,

∫dΦ
2
	​

(K)(2R⋅k
1
	​

)
−b
=V
2
	​

(K)(2R⋅K)
−b
M
b
	​

(α),
	​

(15)

where

M
b
	​

(α)=
Γ(α)Γ(2α−b)
Γ(α−b)Γ(2α)
	​

.
	​

(16)

This is an exact conditional identity in Reα>Reb, followed by meromorphic continuation. It follows from the normalized Beta moment, with the two-body phase-space volume retained. 
DLMF

Any other factor depending only on K is a spectator to this exact inner integration. Thus class D, with cluster power a and single-particle power b, satisfies

C
D
	​

=M
b
	​

(α)C
C
	​

(a,b)
	​

(17)

after matching the signed external scales. More explicitly,

C
D
	​

=
	​

N(D)
2
4α+2
s
P
a
	​

s
R
b
	​

4
a+b
π
2α
L
PR
2α−a−b
	​

	​

×
Γ(a)Γ(b)Γ(4α−a−b)
Γ(a+b−2α)Γ(2α−a)Γ(α−b)Γ(α)
	​

.
	​

	​

(18)

For a=b=1,

C
D
	​

=
α−1
2α−1
	​

C
C
	​

.
	​

(19)

This applies to all six listed D profiles.

Why the missing common strip at unit powers is not an obstruction

You correctly identified that the naive double-cap integral at a=b=1 has no common convergence strip. But equation (15) is an identity of the full finite-z integral, not an isolated-region prescription. It transfers the already determined meromorphic class-C coefficient to D.

For a quadratic cluster factor, keep that factor unchanged during the inner integration. Only the single-particle eikonal is replaced by a linear cluster eikonal. Class C’s leading-coefficient proof applies equally to this mixed quadratic/linear form, using (5).

Thus no auxiliary-regulator overlap assignment is necessary for these six targets.

For a direct regulated check, the example with a common strip is:

cluster power a=2,single-particle power b=1,1<α<
2
3
	​

.

The reversed assignment does not have that strip.

This is preferable to accepting D merely because a regulated Euclidean integral analytically continues to a finite formula.

4. Why A, B and C determine complete coefficients

For the listed restricted classes, completeness can be established without a general region classifier.

A: localization of the only joint angular singularity

Use the exact measure (3). Inside a fixed small common cap, 1−vλ is bounded away from zero uniformly in v. The energy factors become

v
2α−a−c−1
(1−v)
2α−b−c−1
,

which are integrable under (9).

Stereographic rescaling of both directions gives the full sunset integrand in (7). Its convergence controls the expanding-cap tails.

Outside that common cap, the external centers can coalesce without generating the same joint singularity. The pair-collinear singularity remains integrable because c<α; the single external singularities remain integrable because a,b<α. Energy-soft boundaries are controlled by the same positive Beta arguments. The complement is subleading relative to the cap because

S−2α>0.

This establishes the coefficient of the full integral. There is no factor of three for choosing which particle recoils: the original denominator pattern selects the relevant joint singularity.

B: product of two localized angular measures

Each two-eikonal angular factor has a normalized small-separation limit concentrated at the common direction. Under (11), its scaled limit is the corresponding Euclidean bubble.

Where both directions lie in the cap, the energy kernel in (3) tends uniformly to the Beta kernel. Where only one lies in the cap, the contribution has only one bubble enhancement and is suppressed relative to the product by either

z
A−α
orz
B−α
.

The soft-energy endpoints are integrable because 2α>A,B.

This proves the complete double-collinear coefficient, rather than multiplying two presumed region contributions.

C: integrate the internal two-body phase space first

Class C depends on k
1
	​

,k
2
	​

 only through K. Its exact representation is a massive-K/massless-recoil phase space weighted by

V
2
	​

(K)=c
2
	​

(K
2
)
α−1
.

The double-collinear limit is the joint limit of small K
2
/z and small angle between K and the coalescing external directions.

There is a useful global parametrization. Let t∈R
2α
 be the stereographic coordinate of K's direction, a
P
	​

,a
R
	​

 the external stereographic coordinates, and set

q=
1−K
2
/z
K
2
/z
	​

(1+t
2
).

For linear cluster eikonals, the full integral is

I
C
lin
	​

=
	​

2s
P
a
	​

s
R
b
	​

N(D)c
2
	​

z
β
	​

∫
R
2α
	​

d
2α
t∫
0
∞
	​

dqq
α−1
×
[q+
1+a
P
2
	​

∣t−a
P
	​

∣
2
	​

]
a
[q+
1+a
R
2
	​

∣t−a
R
	​

∣
2
	​

]
b
(1+t
2
+q)
a+b−3α
	​

.
	​

	​

(20)

Rescaling t∼
z
	​

 and q∼z produces the 4α-dimensional bubble. Its local singularities require a,b<2α. At infinity, the rescaled weight can be bounded by

(1+∣X∣
2
)
max(a+b−3α,0)
.

Combined with the bubble denominators, this is integrable when a+b>2α and α>0. Thus (14) supplies a genuine whole-integral convergence argument.

The proof extends to the quadratic factors through (5). D then follows from the exact identity (15).

Real noninteger dimension and logarithms

These arguments should be implemented in radial/angular parameter measures with Gamma-normalized angular factors, not justified only for integer-dimensional spheres. For A and B the stated unit-power strips have d>2; the relative-angle weights are positive and integrable. C has the positive mass variable q and a one-axis stereographic representation, valid in its stated strip.

A finite, nonzero scaled limit in an open real-dimensional domain gives the meromorphic coefficient identity. It also excludes generic-dimensional logarithms multiplying that leading power. It does not remove the logarithms produced by expanding z
a−4ϵ
 in epsilon.

The distinction between proving a full coefficient and simply evaluating a region integral matters in the more general cases: overlap contributions can be necessary, especially under analytic regularization. 
arXiv

5. The 14 harder profiles have substantial exact reductions

Use scale-stripped leading denominators

p
1
	​

=v∣ℓ
1
	​

−η
P
	​

∣
2
,p
2
	​

=(1−v)∣ℓ
2
	​

−η
P
	​

∣
2
,p
C
	​

=p
1
	​

+p
2
	​

,

and similarly for another external direction.

These identities act on the actual leading integrands; they are not classifications by geometry alone.

One cluster denominator: pair the six targets into three

The identity

p
1
	​

p
C
	​

1
	​

+
p
2
	​

p
C
	​

1
	​

=
p
1
	​

p
2
	​

1
	​

	​

(21)

combined with particle exchange 1↔2, v↔1−v, pairs the six one-cluster/three-single profiles.

After stripping their stored signs and scales, the listed pairs satisfy

C
323
	​

+
C
311
	​

C
178
	​

+
C
182
	​

C
213
	​

+
C
233
	​

	​

=
C
273
	​

,
=
C
85
	​

,
=
C
102
	​

.
	​

(22)

The right-hand sides are class B.

The hats are important: reconstruct the relation with the actual prefactors before applying it to original-master coefficient rows.

Two cluster denominators: six targets reduce to one new two-center function

Let

I
same
	​

=∫
p
1
	​

r
1
	​

p
C
	​

r
C
	​

dμ
	​

,I
cross
	​

=∫
p
1
	​

r
2
	​

p
C
	​

r
C
	​

dμ
	​

.

Then

2I
same
	​

+2I
cross
	​

=∫
p
1
	​

p
2
	​

r
1
	​

r
2
	​

dμ
	​

.
	​

(23)

This follows by expanding

p
C
	​

r
C
	​

1
	​

(
p
1
	​

1
	​

+
p
2
	​

1
	​

)(
r
1
	​

1
	​

+
r
2
	​

1
	​

).

It pairs

(152,161),(333,319),(336,330),

with class-B right-hand sides 67,268,297, respectively.

Moreover, each pair involves only two external centers. Translation, rotation and dilation give the exact common dependence

L
PR
2α−4
	​

.

After stripping this factor and the external scales, the three “same” profiles are the same scalar integral, and the three “cross” profiles are the same scalar integral. Equation (23) leaves only one new function of dimension.

The two internal-plus-cross-pair targets share one function

Rows 283 and 287 become the same profile after cut relabeling:

one cluster factor;

one single factor on cap particle 1;

the internal pair 12;

the cross pair 23.

They involve two external centers and scale as

L
PR
2α−3
	​


after stripping external factors. Therefore they require one common scalar integral, not two separate evaluations.

Consequence

Before IBP, the 14 listed leading representations need at most:

three three-center, one-cluster representatives;

one two-center, two-cluster representative;

one internal-plus-cross-pair representative.

That is five candidate scalar integrals. This count follows from explicit algebraic identities and scale covariance. It is not yet a completeness claim for their physical coefficients.

Apply the corresponding physical amplitude equations only after either proving the relevant full coefficients or deriving the relations directly from exact finite-z integral identities with the necessary expansion terms retained.

6. General Gaussian/projective representation

For the remaining profiles, your rank-two Gaussian construction is correct and does not require inventing a graph.

After extracting powers of z, 4, external scales and cross-pair energy factors, write

C=K
ext
	​

∫
0
1
	​

dvv
u−1
(1−v)
w−1
∫d
d
ℓ
1
	​

d
d
ℓ
2
	​

e=1
∏
m
	​

Q
e
	​

(ℓ
1
	​

,ℓ
2
	​

;v)
−ν
e
	​

.
(24)

For denominator-only profiles, let:

h
1
	​

,h
2
	​

: total single-particle external powers on the two caps;

h
C
	​

: total cluster-external powers;

c: internal pair power;

r
13
	​

,r
23
	​

: cross-pair powers;

m
0
	​

: explicit Q
2
 power.

Then

λ
dc
	​

=4α−1−h
1
	​

−h
2
	​

−h
C
	​

−2c−r
13
	​

−r
23
	​

−m
0
	​

,
	​

(25)
u=2α−h
1
	​

−c−r
13
	​

,w=2α−h
2
	​

−c−r
23
	​

,
	​

(26)

and

K
ext
	​

=
2
4α+2
N(D)4
h
1
	​

+h
2
	​

+h
C
	​

+c
	​

external
∏
	​

s
e
−ν
e
	​

	​

,
(27)

including any constant recoil-subset factors separately.

Write each transverse quadratic as

Q
e
	​

=ℓ
T
M
e
	​

ℓ−2b
e
	​

⋅ℓ+c
e
	​

.

The matrices are

M
P1
	​

=(
1
0
	​

0
0
	​

),M
P2
	​

=(
0
0
	​

0
1
	​

),
M
PC
	​

=(
v
0
	​

0
1−v
	​

),M
12
	​

=(
1
−1
	​

−1
1
	​

).

The shifts b
e
	​

,c
e
	​

 follow directly from the squared-distance expressions.

For Schwinger parameters x
e
	​

, define

M=
e
∑
	​

x
e
	​

M
e
	​

,b=
e
∑
	​

x
e
	​

b
e
	​

,c
0
	​

=
e
∑
	​

x
e
	​

c
e
	​

,
U=detM,F=Uc
0
	​

−b
T
adj(M)b.
	​

(28)

The vector products in F are ordinary Euclidean products over the transverse components.

Let ν=∑
e
	​

ν
e
	​

. Gaussian integration and integration over the overall Schwinger scale give

C=
	​

K
ext
	​

∏
e
	​

Γ(ν
e
	​

)
π
2α
Γ(ν−2α)
	​

∫
0
1
	​

dvv
u−1
(1−v)
w−1
×∫
Δ
m−1
	​

	​

e
∏
	​

x
e
ν
e
	​

−1
	​

F
ν−2α
U
ν−3α
	​

dΩ
x
	​

.
	​

	​

(29)

In particular, the projective Gamma factor is Γ(ν−2α), and the numerator power is U
ν−3α
. This is the usual Gaussian-to-parametric algebra, applicable to your quadratic forms whether or not they arise from ordinary graph propagators. 
arXiv

Check M>0 for positive parameters and 0<v<1. Also,

F/U=
ℓ
min
	​

e
∑
	​

x
e
	​

Q
e
	​


is nonnegative; it is strictly positive when the positive-weight quadratics have no common zero.

For your external geometry, set the centers to 0,1,1/4 after extracting the common scale L
ab
	​

. This makes the Euler polynomials rational without storing square roots.

7. Convergence and completeness are separate acceptance tests

A resolved projective Euler integral has a mechanically checkable convergence domain. After sector decomposition, each sector should have the form

j
∏
	​

t
j
ρ
j
	​

(α,δ)−1
	​

×bounded resolved units.

Require

Reρ
j
	​

>0

for every sector, together with the overall-scale condition. These are finite linear inequalities in dimension and analytic weights. Resolution of singularities is a constructive way to obtain such endpoint forms. 
arXiv

But this certifies the limiting integral, not its equality to the full physical coefficient.

For each unresolved E profile, use one of the following stronger certificates:

A fixed-cap/complement proof like A or B, with uniform bounds at v=0,1.

An exact conditional integration identity like D.

A coefficient-targeted resolution of the finite-z integral, including z among the sector variables, showing that all omitted sectors have strictly higher powers or supplying their residues at the targeted power.

The third option can be phrased as a Mellin-pole calculation in z: retain every sector contributing to the target pole and sum its residue. It need not become a general-purpose physical-region classifier.

Analytic propagator weights are legitimate when an identity has first been established on a nonempty open convergence domain. If different contributions acquire regulator poles or coincident exponents as the weights return to integers, combine those contributions before removing the regulators. A convergent regulated cap integral alone does not establish that it is the whole coefficient. 
arXiv

Three possible cap assignments

For a generic profile, enumerate all three candidate recoil particles. Formula (25) gives the preliminary valuation for each assignment.

An assignment whose first power is higher than the target cannot contribute through its ordinary higher-order expansion. An assignment beginning below the target may require subleading terms. Equal powers must be combined.

However, endpoint regions of v must still be checked; leading power counting at fixed v does not replace that step. Similarly, call an assignment scaleless only after an exact homogeneity argument in the specified regulator scheme—not because the Gaussian matrix is singular or its coefficient is inconvenient.

For A–D, the complete proofs above handle this bookkeeping. For the five remaining candidate integrals, retain it explicitly.

8. Concrete sequence

First implement A, B, C and the exact D-to-C reduction. This covers 18 of your selected rows using Gamma functions only. For each accepted coefficient, also impose the justified absence of generic leading logarithms, then apply the primitive unit-pivot update and recompute demands.

Next apply the representation-level identities (21)–(23) and the two-center scale reductions. Recompute projected rank before evaluating anything. This reduces the 14 complex entries to at most five candidate right-hand sides.

Use one of the two jobs for the exact Gamma/identity/rank updates. Use the other for convergence and completeness checks on the highest-rank remaining representative. Only then submit its finite Euler coefficients to SubTropica. There is no benefit in launching 14 independent integrations.

For validation, compare the A–C formulas against the exact representations at dimensions strictly inside their strips, and test D against the exact conditional average. Keep these separate from artificial-amplitude DE transport tests and from AMFlow physics validation.

The immediate general-code gain is larger than four unrelated constructors: a universal double-cap measure, three Gamma kernels, an exact conditional moment operator, and two partial-fraction identities cover most of the selected system. The remaining work should be directed at a small set of actual Euler integrals with coefficient-specific completeness certificates, not at the original list of 14 target rows.