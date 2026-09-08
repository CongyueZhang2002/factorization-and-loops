# Pro consultation: coalescing null directions and the physical leading coefficient

Model: gpt-6-pro.

## Prompt

Follow-up on your recommended first physical coefficient. Please check this proposed reusable construction before we accept any new amplitude relation.

Three massless unit cuts k1+k2+k3=Q, Q^2=z ->0+, standard phase-space measure. All active ordinary factors are (s P+t R)^2 with s,t=+/-1, P a future-null external vector with P.Q positive finite at the edge, R a nonempty subset of cut momenta; optionally Q^2 factors. We exclude two-cut invariant denominators and raised cuts for this first constructor. Ordinary numerators can be included only if they have the same recognized external-subset form.

In Q rest frame define x_i=k_i^+/Q^+ relative to one external null direction. As z->0 all external null directions coalesce because 1-cos(theta_P P')=z (P.P')/((P.Q)(P'.Q)). Thus each external factor tends to (2 s t P.Q_edge) sum_{i in R} x_i. The whole-domain leading coefficient has z^(D-3-m), where m is the total power of explicit Q^2 factors.

I derive the normalized light-cone fractions as Dirichlet(alpha,alpha,alpha), alpha=(D-2)/2, by integrating transverse momenta at fixed x_i:
dPhi3/z^(D-3) times [Gamma(3alpha)/Gamma(alpha)^3] (x1 x2 x3)^(alpha-1) dx1 dx2.
The overall volume is c2^2 Gamma(alpha)Gamma(2alpha)/Gamma(3alpha), c2=Pi^((D-1)/2)/(2^(D-2)Gamma((D-1)/2)), multiplied by existing AMFlow phase-space (2Pi) factors and routing determinant^-D.

Use x1=t,x2=(1-t)u,x3=(1-t)(1-u), producing an explicit unit-square Euler integral with integrand t^(alpha-1)(1-t)^(2alpha-1)u^(alpha-1)(1-u)^(alpha-1) times the inverse subset fractions and exact scales. Uniform integrability follows from the earlier Holder moment argument with positive denominator powers multiplied by 1+delta (e.g. delta=1) and D>4N+2. This proves the full leading coefficient for these recognized propagators in a real large-D interval, then continue meromorphically. It only supplies slope -2 equations; no statements about the -3/-4 branches.

Are the Dirichlet law, normalization, coalescence limit and L^(1+delta) justification correct under these restrictions? Any subtle sign or Jacobian problem? I will test against exact volume and single-eikonal Beta moments and require generic-epsilon rank gain before claiming a new amplitude determination.


## Retrieved response

The Dirichlet law, your c
2
2
	​

B(α,2α) volume factor, the unit-square exponents, and the D>4N+2 sufficient threshold are correct. Two qualifications should be explicit in the reusable constructor: coalescence requires bounded external pair invariants P⋅P
′
, and the routing Jacobian is ∣detM∣
−D
, not a signed determinant raised to a noninteger power.

Also, your c
2
	​

 is the normalization for raw δ
+
	​

 measures. It becomes the standard phase-space normalization only after inserting the appropriate 2π factors. Under these conditions, the uniform-integrability argument proves the full coefficient, not merely a candidate region contribution.

1. The light-cone Dirichlet law is exact

Define the fractions invariantly:

x
i
	​

=
P
∗
	​

⋅Q
P
∗
	​

⋅k
i
	​

	​

,x
i
	​

≥0,x
1
	​

+x
2
	​

+x
3
	​

=1,
	​

(1)

where P
∗
	​

 is one chosen future-null reference vector.

This avoids a light-cone convention ambiguity. With the usual k
±
=k
0
±k
D−1
, a P
∗
	​

 pointing along the positive spatial axis measures k
−
, not k
+
. Either naming convention works, but the code should enforce (1).

For any fixed z>0, the marginal distribution of these fractions under normalized massless three-body phase space is

dP
D
	​

(x)=
Γ(α)
3
Γ(3α)
	​

(x
1
	​

x
2
	​

x
3
	​

)
α−1
dx
1
	​

dx
2
	​

,α=
2
D−2
	​

.
	​

(2)

Thus the Dirichlet law itself does not require the recoil limit. The limit is needed to express all external denominators using the same fractions.

Direct transverse-momentum derivation

Use the raw measure

dΦ
3
raw
	​

(Q)=
i=1
∏
3
	​

d
D
k
i
	​

δ
+
	​

(k
i
2
	​

)δ
(D)
(Q−
i
∑
	​

k
i
	​

).

Choose Q
⊥
	​

=0, Q
+
Q
−
=z, and put

k
i
+
	​

=x
i
	​

Q
+
,k
i⊥
	​

=
z
	​

p
i
	​

.

After integrating the minus components and imposing momentum conservation, the measure becomes

4
z
D−3
	​

x
1
	​

x
2
	​

x
3
	​

dx
1
	​

dx
2
	​

	​

∫d
D−2
p
1
	​

d
D−2
p
2
	​

δ(1−
x
1
	​

p
1
2
	​

	​

−
x
2
	​

p
2
2
	​

	​

−
x
3
	​

(p
1
	​

+p
2
	​

)
2
	​

).

The quadratic-form matrix for each transverse component is

M
x
	​

=(
x
1
−1
	​

+x
3
−1
	​

x
3
−1
	​

	​

x
3
−1
	​

x
2
−1
	​

+x
3
−1
	​

	​

),detM
x
	​

=
x
1
	​

x
2
	​

x
3
	​

1
	​

.

The transverse integral therefore yields

dΦ
3,marginal
raw
	​

=z
D−3
4Γ(D−2)
π
D−2
	​

(x
1
	​

x
2
	​

x
3
	​

)
α−1
dx
1
	​

dx
2
	​

.
	​

(3)

Normalizing this with the simplex beta integral gives (2). 
DLMF

This derivation also confirms that there is no additional restriction on the fractions beyond the simplex. The transverse variables carry the remaining phase-space geometry and have already been integrated out.

These are light-cone fractions, not the rest-frame energy fractions 2Q⋅k
i
	​

/z. The latter sum to two and have a different interpretation.

2. Your volume factor is correct, with a normalization convention to pin down

Let

V
3
raw
	​

(D)=z
−(D−3)
∫dΦ
3
raw
	​

(Q).

Integrating (3),

V
3
raw
	​

(D)=
4Γ(2α)Γ(3α)
π
D−2
Γ(α)
3
	​

.

Your expression is equivalent:

V
3
raw
	​

(D)=c
2
2
	​

Γ(3α)
Γ(α)Γ(2α)
	​

,c
2
	​

=
2
D−2
Γ((D−1)/2)
π
(D−1)/2
	​

.
	​

(4)

The equivalence follows from the gamma duplication formula. 
DLMF

For the standard convention

dΦ
3
std
	​

=(2π)
D
δ
(D)
(Q−
i
∑
	​

k
i
	​

)
i
∏
	​

(2π)
D−1
2E
i
	​

d
D−1
k
i
	​

	​

,

the conversion is

dΦ
3
std
	​

=(2π)
3−2D
dΦ
3
raw
	​

.
	​

(5)

In particular,

∫dΦ
3
raw
	​

	​

D=4
	​

=
8
π
2
	​

z,∫dΦ
3
std
	​

	​

D=4
	​

=
256π
3
z
	​

,

consistent with the standard dimensionally regulated three-body measure. 
Scipp Legacy
+1

There are two equivalent ways to store the coefficient measure:

V
3
raw
	​

(D)dP
D
	​

(x),

or

4Γ(D−2)
π
D−2
	​

(x
1
	​

x
2
	​

x
3
	​

)
α−1
dx
1
	​

dx
2
	​

.

Do not combine the total-volume factor with the second, already unnormalized density. That would count the normalization twice.

For an affine transformation of the two independent integration momenta,

(k
1
	​

,k
2
	​

)
T
=M(ℓ
1
	​

,ℓ
2
	​

)
T
+external shifts,

the real measure contributes

∣detM∣
−D
.
	​


A permutation with determinant −1 must not produce a phase. For a nonunit routing, require this determinant to be independent of z, or account explicitly for its additional scaling.

Finally, no 1/3! belongs in the labelled master-integral measure unless it was part of the original definition. AMFlow loop normalizations and the normalization of the cut discontinuities should remain an explicit conversion factor checked against your known volume.

3. The coalescence limit is correct under bounded hard invariants

In the Q-rest frame,

P
0
=
z
	​

P⋅Q
	​

,

so your identity is exact:

1−cosθ
PP
′
	​

=
(P⋅Q)(P
′
⋅Q)
zP⋅P
′
	​

.
	​

(6)

For the reusable theorem, require

P⋅Q⟶c
P
	​

∈(0,∞),P⋅P
′
=O(1).

Then all the external directions coalesce.

The second condition is not implied by the first. For example, in the Q-rest frame,

Q=(
z
	​

,0),P=z
−1/2
(1,n),P
′
=z
−1/2
(1,−n)

have P⋅Q=P
′
⋅Q=1, but their directions remain opposite because P⋅P
′
=2/z. Your fixed-hard-invariant recoil kinematics exclude this counterexample.

Choose the rest-frame spatial axes so that P
∗
	​

 always points in a fixed direction. On the resulting fixed unit-mass phase space,

P⋅Q
P⋅k
i
	​

	​

⟶x
i
	​

.

For a subset R=∑
i∈R
	​

k
i
	​

, define

X
R
	​

=
i∈R
∑
	​

x
i
	​

.

Since R
2
=O(z),

(sP+tR)
2
=R
2
+2stP⋅R⟶2stc
P
	​

X
R
	​

.
	​

(7)

The sign st must survive in the coefficient integral. Absolute values are appropriate for convergence estimates, not for the answer.

No interior denominator zero has been overlooked

For a future-causal subset sum R, the inequality established earlier gives

R
2
≤
P⋅Q
z
	​

P⋅R.

Hence

(P+R)
2
≥2P⋅R,

and

∣(P−R)
2
∣≥2P⋅R(1−
2P⋅Q
z
	​

).
	​

(8)

For sufficiently small z, the latter factor is bounded away from zero uniformly over the complete phase space.

Thus the minus-sign factors remain negative away from their endpoint zeros; they do not develop an interior pinch. In the large-D absolutely convergent domain, the i0 boundary values reduce to these signed functions. Retain the prescription in the definition and subsequent continuation, especially if noninteger propagator powers are introduced later.

Recognized numerator factors are uniformly bounded because

0≤P⋅R≤P⋅Q,0≤R
2
≤z.

Finite polynomial combinations are therefore admissible, provided any singular kinematic prefactors have first been extracted explicitly.

A numerator cancellation may make the coefficient in (7) vanish after integration. In that case you have proved a zero coefficient at the proposed power, not identified the next nonzero leading term.

4. The L
1+δ
 justification is sufficient

Let N=∑
a
	​

ν
a
	​

 be the sum of positive powers of the ordinary external-subset denominators. Do not include the explicit z
−m
 factor in this count; it has already been extracted.

For each denominator choose one constituent k
i
a
	​

	​

 of its subset and define

Y
a
	​

=
P
a
	​

⋅Q
P
a
	​

⋅k
i
a
	​

	​

	​

.

Equations (8) and P
a
	​

⋅R
a
	​

≥P
a
	​

⋅k
i
a
	​

	​

 imply, after bounding the numerator,

∣f
z
	​

∣
r
≤C(D)
a
∏
	​

Y
a
−rν
a
	​

	​

,r=1+δ>1.

At every finite z, each Y
a
	​

 has the same Beta(α,2α) marginal, regardless of the relative external directions.

Hölder with exponents N/ν
a
	​

 gives

∫∣f
z
	​

∣
r
dP
D
	​

⟨Y
a
−rN
	​

⟩
D
	​

	​

≤C(D)
a
∏
	​

⟨Y
a
−rN
	​

⟩
D
ν
a
	​

/N
	​

,
=
Γ(α)Γ(3α−rN)
Γ(α−rN)Γ(3α)
	​

.
	​

(9)

Therefore

D>2(1+δ)N+2
	​

(10)

is sufficient. With δ=1, this is exactly your

D>4N+2.
	​


For N=0, boundedness is immediate and no Hölder step is needed.

The limit of the integrand exists almost everywhere: the excluded subset-fraction zeros lie on measure-zero boundaries. The uniform L
1+δ
 bound then supplies uniform integrability, so the integrals converge to the integral of the limit. This is the relevant convergence theorem; pointwise convergence alone would not suffice. 
Mathematics Department at UC Davis

For the meromorphic argument, formulate this on a fixed parameter domain with a positive dimensionally continued angular measure for real sufficiently large D. Do not establish it only at integer dimensions and then infer the coefficient identity. The required continuous real-D representation is available through the angular/Gram integrations underlying this phase-space construction.

This proof rules out a concentrating soft/collinear contribution at the extracted leading order. It does not rule out subleading region contributions.

5. The reusable coefficient formula

Suppose the raw integral is

I(z,D)=N(D)z
−m
∫dΦ
3
raw
	​

(Q)
∏
a
	​

[(s
a
	​

P
a
	​

+t
a
	​

R
a
	​

)
2
]
ν
a
	​

P
z
	​

	​

,

where N(D) includes the verified routing and convention factors, but no unaccounted z-dependence.

Form

f
0
	​

(x)=
a
∏
	​

[2s
a
	​

t
a
	​

c
P
a
	​

	​

X
R
a
	​

	​

]
ν
a
	​

P
0
	​

(x)
	​

.

Then the proven coefficient is

z→0
+
lim
	​

z
−(D−3−m)
I(z,D)=N(D)
4Γ(D−2)
π
D−2
	​

∫
Δ
2
	​

	​

(x
1
	​

x
2
	​

x
3
	​

)
α−1
f
0
	​

(x)dx
1
	​

dx
2
	​

.
	​

(11)

Under

x
1
	​

=t,x
2
	​

=(1−t)u,x
3
	​

=(1−t)(1−u),

the Jacobian is 1−t. Thus your square representation is exactly

N(D)
4Γ(D−2)
π
D−2
	​

∫
0
1
	​

dt∫
0
1
	​

dut
α−1
(1−t)
2α−1
u
α−1
(1−u)
α−1
f
0
	​

(t,(1−t)u,(1−t)(1−u)).
	​

(12)

There is an additional implementation simplification: every nonempty subset fraction is one of

x
1
	​

,x
2
	​

,x
3
	​

,1−x
1
	​

,1−x
2
	​

,1−x
3
	​

,1.

The limiting integrands can therefore be canonicalized into these six nonconstant factors, plus a polynomial numerator and exact external scales.

A two-element subset fraction X
{1,2}
	​

=1−x
3
	​

 is legitimate here. It is not an identification of the excluded invariant (k
1
	​

+k
2
	​

)
2
/z with 1−x
3
	​

.

At D=4−2ϵ, the extracted power is

z
1−m−2ϵ
.

Continue the resulting coefficient identity meromorphically. Do not assert that the same scaled limit exists for epsilon near zero: the −3 and −4 branches can behave differently there.

A finite large-D limit also forces the complete logarithmic coefficients at this same power to vanish. Match the no-log coefficient and those zero-log conditions against the generic-epsilon Frobenius solution, after combining all contributing directions.

6. Tests that distinguish the possible mistakes

Besides the volume, use the normalized moments

⟨x
1
−ν
	​

⟩=
Γ(α)Γ(3α−ν)
Γ(α−ν)Γ(3α)
	​

,
	​

⟨(x
1
	​

+x
2
	​

)
−ν
⟩=
Γ(2α)Γ(3α−ν)
Γ(2α−ν)Γ(3α)
	​

,
	​


and

⟨x
1
−p
	​

x
2
−q
	​

⟩=
Γ(3α−p−q)Γ(α)
2
Γ(3α)Γ(α−p)Γ(α−q)
	​

.
	​

(13)

These follow from the beta/simplex integrals in their convergence domains and then by meromorphic continuation. 
DLMF
+1

The singleton test checks the exact factor 2P⋅Q. An odd power of (P−k
1
	​

)
2
 checks the minus sign. The two-element subset test checks subset handling. A product involving two distinct external directions, compared with its coalesced mixed moment, checks the actual limit rather than only single-direction normalization.

With these normalization and eligibility guards, this constructor is a sound route to new physical amplitude relations. Its strength is that it integrates a certified full leading coefficient over the whole phase space. Your generic-epsilon rank-gain requirement is the right final gate: a valid coefficient formula becomes a new amplitude determination only when its exact Frobenius row supplies an independent relation.