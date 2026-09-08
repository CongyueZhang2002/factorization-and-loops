# Conditional final-state pair moment

## Prompt

The first non-elementary physical Euler coefficient is evaluated through eps^2 and expressed in ordinary zeta values/logs. The primitive unit-pivot implementation passes your four regressions. Applying two exact equal-integral relations plus the new coefficient now gives 80 remaining regular amplitude series and 543 demanded coefficients in all 91 saved solutions, down from 83/565, preserving the old pole bounds. Numerical preprocessing maps these new coordinates back to the old normalized DE. The present 155 external-subset-only coefficients observe rank4 (including the known volume), so only 3 of the unknown directions; this explains the modest reduction.

I propose extending the physical constructor to one distinct final-state pair invariant, and want your check of the conditional moment formula.

Let x_i=(P_ref.k_i)/(P_ref.Q), x1+x2+x3=1, alpha=(D-2)/2. In light-cone transverse coordinates at Q^2=1 let x12=x1+x2, K=k1perp+k2perp=-k3perp and q=k1perp-(x1/x12)K. Then
sum kiperp^2/x_i = (x12/(x1*x2)) q^2 + K^2/(x12*x3).
Set q=sqrt(x1*x2/x12) u and K=sqrt(x12*x3) v. The constraint becomes u^2+v^2=1 in two D-2 dimensional Euclidean vectors. Conditional on the fractions, rho=u^2 is Beta(alpha,alpha), independent of x. The scaled invariant y12=(k1+k2)^2/Q^2 equals x12*rho=(1-x3)rho. Thus for integer a,
E[y12^(-a) | x] = (1-x3)^(-a) Gamma(alpha-a)Gamma(2alpha)/(Gamma(alpha)Gamma(2alpha-a)).
This is exact in a common large-D convergence domain then meromorphically continued.

Consequences:
- An ordinary factor ((k1+k2)^2)^(-a) extracts z^(-a), shifts the spectator complement power b3 by a in the same 2D Dirichlet Euler integral, and multiplies by the above Beta moment.
- Arbitrary external-subset denominators still tend to functions of the same x_i, so the formula integrates the conditional transverse degrees exactly.
- Restrict this first extension to at most one distinct nontrivial pair invariant among all active factors. Other pair denominators remain unresolved, as do raised cuts.
- Numerator powers of the same pair are handled by negative a.
- The uniform L^2 argument uses total positive powers N of both external-subset and pair-invariant factors; D>4N+2 is still sufficient.
- The Beta prefactor can itself have an epsilon pole, so its valuation must be included by the existing bound/order code.
As a check, integrating x gives the known marginal E[y12^-a]=Gamma(alpha-a)Gamma(3alpha)/(Gamma(alpha)Gamma(3alpha-a)).
Is the conditional law and its use in the full coalescence limit correct? Any factor of two, orientation or dimension shift missing?


## Pro response

Your conditional law and its use in the full coalescence limit are correct. There is no missing factor of two, orientation factor, or dimension shift. The important qualification is that the conditional Beta integration applies to the limiting integrand: at finite z, external factors associated with distinct null directions still depend on transverse angles.

For integer a, the Beta prefactor is actually a rational function of D. Simplify it before assigning its epsilon valuation; apparent Gamma-function poles can cancel.

1. The transverse transformation gives exactly Beta(α,α)

Write d
⊥
	​

=D−2=2α. At fixed interior fractions, your inverse transformation is

k
1⊥
	​

=q+
x
12
	​

x
1
	​

	​

K,k
2⊥
	​

=−q+
x
12
	​

x
2
	​

	​

K.

Its determinant is 1 for each transverse component. Thus

d
d
⊥
	​

k
1⊥
	​

d
d
⊥
	​

k
2⊥
	​

=d
d
⊥
	​

qd
d
⊥
	​

K.

The quadratic identity is

i=1
∑
3
	​

x
i
	​

k
i⊥
2
	​

	​

=
x
1
	​

x
2
	​

x
12
	​

	​

q
2
+
x
12
	​

x
3
	​

K
2
	​

,

where x
12
	​

+x
3
	​

=1 has been used. Your rescalings therefore give

d
d
⊥
	​

qd
d
⊥
	​

K=(x
1
	​

x
2
	​

x
3
	​

)
α
d
d
⊥
	​

ud
d
⊥
	​

v.

Combined with the light-cone measure’s 1/(x
1
	​

x
2
	​

x
3
	​

), this reproduces the existing Dirichlet weight. There is no new fraction-dependent Jacobian.

Conditional on x, the remaining normalized measure is proportional to

d
d
⊥
	​

ud
d
⊥
	​

vδ(1−u
2
−v
2
).

Putting ρ=u
2
 and integrating both angular measures yields

dP(ρ∣x)=
B(α,α)
ρ
α−1
(1−ρ)
α−1
	​

dρ.
	​

(1)

It is independent of x. The normalization follows directly from Euler’s beta integral. 
DLMF

The independence statement concerns the underlying normalized phase-space measure. It does not assert independence under a measure already reweighted by external denominators.

2. The invariant is y
12
	​

=x
12
	​

ρ, with no factor of two missing

Using light-cone components consistently,

(k
1
	​

+k
2
	​

)
2
=x
12
	​

(
x
1
	​

k
1⊥
2
	​

	​

+
x
2
	​

k
2⊥
2
	​

	​

)−K
2
=
x
1
	​

x
2
	​

x
12
2
	​

	​

q
2
.

At Q
2
=1, your substitution gives

y
12
	​

=x
12
	​

u
2
=(1−x
3
	​

)ρ.
	​

(2)

For general z, rescale the transverse momenta by 
z
	​

; then

(k
1
	​

+k
2
	​

)
2
=z(1−x
3
	​

)ρ.

Consequently,

E[y
12
−a
	​

∣x]=(1−x
3
	​

)
−a
C
a
	​

(α),C
a
	​

(α)=
Γ(α)Γ(2α−a)
Γ(α−a)Γ(2α)
	​

.
	​

(3)

The conditional integral initially requires

Reα>0,Re(α−a)>0.

Equation (3) then extends meromorphically. 
DLMF

The normalization check is a=0: C
0
	​

=1, so this operation leaves the original volume unchanged.

For the propagator as written,

(k
1
	​

+k
2
	​

)
2
=2k
1
	​

⋅k
2
	​

.

Thus there is no extra factor. A denominator stored as k
1
	​

⋅k
2
	​

, however, contributes an additional 2
a
. Reversing the overall pair momentum changes nothing; replacing a sum by a difference gives

(k
1
	​

−k
2
	​

)
2
=−(k
1
	​

+k
2
	​

)
2

on the unit cuts and requires its explicit sign and prescription to be retained.

No effective replacement D↦D−2 is involved. Both transverse vectors have dimension D−2; integrating them conditionally generates the Beta ratio at the same D.

3. The full coefficient reduces to the existing fraction-profile family

Let f
z
	​

 contain the recognized external-subset factors and bounded numerators, including their exact scale factors, after extracting any explicit z
−m
. Define

I(z,D)=z
−m
∫dΦ
3
	​

(Q)[(k
1
	​

+k
2
	​

)
2
]
−a
f
z
	​

.

If f
0
	​

(x) is the coalesced integrand, the coefficient is

z→0
+
lim
	​

z
−(D−3−m−a)
I(z,D)=V
3
	​

(D)C
a
	​

(α)E
Dir(α,α,α)
	​

[(1−x
3
	​

)
−a
f
0
	​

(x)],
	​

(4)

with V
3
	​

(D) carrying exactly the previously established measure normalization. The Dirichlet normalization is unchanged. 
DLMF

Therefore, with the convention that the profile contains (1−x
3
	​

)
−b
3
	​

, your update is precisely

m↦m+a,b
3
	​

↦b
3
	​

+a,prefactor↦C
a
	​

(α)×prefactor.
	​

(5)

For a<0, the same formulas handle numerator powers, including the positive extracted power of z.

Apply this reduction after establishing the full limiting integrand. At finite z, distinct external directions generally prevent pulling the external factors outside the conditional transverse expectation. The valid sequence is

full finite-z integrand⟶justified coalescence limit⟶conditional Beta integration.

Restricting all active pair dependence to this one invariant makes that last step sufficient. A second distinct pair invariant generally introduces dependence on the relative transverse angle; its conditional moments cannot be multiplied independently.

This extension still determines coefficients with epsilon slope −2, now at the shifted integer power 1−m−a. It makes no exclusion statement about the −3 or −4 branches.

4. Your L
2
 threshold remains sufficient

Set

a
+
	​

=max(a,0),N=a
+
	​

+
j
∑
	​

ν
j
	​

,

where the ν
j
	​

>0 are the external-subset denominator powers. Negative pair powers need not contribute to N, because 0≤y
12
	​

≤1.

The previous denominator inequalities imply

∣y
12
−a
	​

f
z
	​

∣
2
≤C(D)y
12
−2a
+
	​

	​

j
∏
	​

Y
j
−2ν
j
	​

	​

,

where each Y
j
	​

 is a normalized external-single-cut fraction.

Both Y
j
	​

 and y
12
	​

 have the marginal inverse moments

E[X
−p
]=
Γ(α)Γ(3α−p)
Γ(α−p)Γ(3α)
	​

,Reα>p.
	​

(6)

For y
12
	​

, this also follows by averaging (3) over the Dirichlet fractions. 
DLMF

Hölder bounds the product using individual moments of order 2N. Hence

α>2N⟺
D>4N+2
	​


is sufficient. No independence between the pair invariant and the external fractions is required for this bound.

The new collinear singularity y
12
	​

=0 is therefore covered by the same uniform-integrability argument, including its intersections with soft and external-collinear boundaries. As before, formulate the argument for a real interval of large D using the positive dimensionally continued measure, then continue the resulting coefficient identity—not the convergence inequality—meromorphically.

5. Simplify the Beta prefactor before Laurent-order analysis

For positive integer a, Gamma recurrence gives

C
a
	​

(α)=
j=1
∏
a
	​

α−j
2α−j
	​

.
	​

(7)

For a=−r, r≥0,

C
−r
	​

(α)=
(2α)
r
	​

(α)
r
	​

	​

.
	​

(8)

Thus this extension adds a rational prefactor, not a new Gamma-function evaluation problem. 
DLMF

At α=1−ϵ,

C
1
	​

=−
ϵ
1−2ϵ
	​

,C
2
	​

=−
1+ϵ
2(1−2ϵ)
	​

,C
−1
	​

=
2
1
	​

.

In particular, C
2
	​

 has no epsilon pole, despite poles in individual Gamma factors. Feed the simplified rational expression into the existing valuation and demand machinery.

The negative analytically continued values near D=4 do not contradict positivity of the convergent large-D integral.

6. Add one mixed-moment regression

Your marginal check is correct:

E[y
12
−a
	​

]=
Γ(α)Γ(3α−a)
Γ(α−a)Γ(3α)
	​

.
	​

(9)

Also test a spectator-fraction insertion:

E[y
12
−a
	​

x
3
−b
	​

]=
Γ(α)
2
Γ(3α−a−b)
Γ(α−a)Γ(α−b)Γ(3α)
	​

.
	​

(10)

This follows from (3) and one beta integral over x
3
	​

. It detects an implementation that incorrectly treats y
12
	​

, rather than ρ, as independent of x. 
DLMF

For example,

E[y
12
	​

∣x]=
2
1−x
3
	​

	​

,E[y
12
	​

x
3
	​

]=
3(3α+1)
α
	​

.

This is a sound reusable extension. It introduces no additional integration variable in the final Euler coefficient: it shifts an existing complement exponent and supplies an exact rational prefactor. Preserve the extracted integer z-power, external signs, and prefactor when canonicalizing profiles, then apply the same generic-epsilon rank-gain test before eliminating any further amplitude.