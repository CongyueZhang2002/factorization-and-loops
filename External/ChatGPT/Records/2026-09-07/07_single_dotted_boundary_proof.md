# Single doubled cut: physical coefficient proof

## Prompt


Your preceding advice was implemented: two-pair Euler representation reduced from a verified 4D angular form to your 3D hypergeometric-Euler form. Both match the independent invariant-simplex Gamma moment at D=10 to ~3e-13 in <0.5s. Three "linear" propagators are genuine P.k numerators and now recognized without the factor2. We have256 coefficients before those3; new homogeneous/identical relations give45 equations including volume, plus our evaluated Euler integral ->46 before any new integral. Primary rank accounting of current applied45free modes is exactly 9(-2)+3(-3)+32(-4)+1(0), as you predicted.

All87 raised cuts are SINGLE dots, never higher derivatives:
57 underlying profiles have no pair invariant,25 have one pair,5 have two. Thus the one-derivative operator is enough. Original unreduced momentum polynomials/cut convention are retained; no k_i^2=0 numerator simplification. Master/measure prefactors independent of masses.

Please review a concrete proof/acceptance criterion for this one-dot subclass before we apply these equations. I want a sufficient explicit large-D condition, not an unproved "differentiation assumed valid" flag.

1) With x fixed and h=1-sum(mu_j/x_j), raw massive measure is const z^beta prod(x_i)^(alpha-1) h_+^beta, beta=D-3. Original ordinary propagators are exactly:
   Q^2; (k_a+k_b)^2; or (sP+t sum_subset k)^2 with P future null; or an exact multiple of P.sum_subset k.
   All off-shell momentum expressions are preserved. Numerator powers are allowed, no generic cut-polynomial simplification. Pair invariants use your Y_ab(mu)=h*y_ab+x_ab(mu_a/x_a+mu_b/x_b).
2) At mu=0 the unsuppressed mass derivative is precisely:
   [(A_pair-beta)/x_i]F - sum_pairs_containing_i [a_e x_e/(x_i y_e)]F.
   An ordinary quadratic external-subset factor retains z*R^2 at finite z. Its mass derivative carries a further z; external-direction terms carry sqrt(z). They must be shown suppressed in the differentiated coefficient, not deleted a priori.
3) In light-cone variables, k_T=sqrt(h)K. At fixed x, d_mu_i k_T=-K/(2*x_i*sqrt(h)), and d_mu_i k^- consists of -K^2/(x_i*x_j)+delta_ij/x_j. Consequently d_mu of a finite-z external propagator is O(sqrt(z))/(x_i sqrt(h)) plus O(z)/x_i with bounded normalized transverse numerators. Differentiating its inverse power increases that denominator power by1. At mu=0 these suppressed terms are bounded by products of existing positive inverse fraction/pair marginals with total inverse power at most N+2, where N=sum positive ordinary external/pair powers. Holder/L2 thus suggests D>4(N+2)+2 suffices for uniform coalescence of the differentiated integrand.
4) Domain differentiation: retain h_+^beta until differentiating. For one dot, d h_+^beta=-beta/x_i h_+^(beta-1), with no omitted delta term if beta>1. Need justify under integral even when pair factors contribute h^-A and external angular denominators intersect x/h endpoints. A conservative condition like D>4(N+2)+2 gives substantial margin beta>N+2 and alpha>2(N+2), but I need the actual domination argument, or a more restrictive condition we can mechanically certify. For mu>=0, h in[0,1] and Y_e>=h*y_e; external massive future-subset inverse moments need an angular/Riesz bound uniform in the changing external center, not an independence assumption.
5) Is it enough to use analytically continued compact parameter distributions to identify the first derivative at mu=0 directly (then verify the differentiated z->0 limit), rather than a generic massive-family dominated bound? Can give explicit endpoint criterion for our positive rational profiles, perhaps split-domain proof.
6) Once such a bound is established, can we also eliminate the exceptional lambda0 mode by matching its finite generic Frobenius coefficients against O(z^(D-4-A_pair)) for a sufficiently large realD? We will test observability and exact rank, not presume it vanishes.

Please correct any faulty estimate, especially derivative/domain control and discarded finite-z terms. We can implement algebra provisionally but will not mark an unsupported physical coefficient as established.


## Pro response

Your one-dot operator is correct for the stated factorized profiles, and D>4(N+2)+2 is a sufficient real-D condition. The missing ingredient is a conditional angular estimate that remains uniform under the massive deformation. It can be proved explicitly; independence of the denominators is not needed.

Two qualifications matter. First, β>1 alone is not the relevant domain condition when pair denominators supply negative powers of h; use β minus those powers. Second, the displayed insertion operator does not capture additional explicit mass dependence in a general off-shell numerator. Differentiate that dependence before taking the massless limit.

There is also a useful simplification for implementation: a single dot can be lowered by an exact cut-IBP identity to unit cuts, without constructing a massive family. For your zero-, one-, and two-pair classes, the resulting integrals still require at most two distinct pair denominators.

1. A direct one-dot identity provides an independent acceptance route

Choose distinct i,j,ℓ, take k
i
	​

,k
ℓ
	​

 as independent, and write

k
j
	​

=Q−k
i
	​

−k
ℓ
	​

,s
ij
	​

=(k
i
	​

+k
j
	​

)
2
=(Q−k
ℓ
	​

)
2
.

All derivatives below hold Q,k
ℓ
	​

, and the external vectors fixed.

Let f contain the original ordinary factors and numerator, before imposing cut equations. With

Δ
1
	​

(k
2
)=θ(k
0
)δ(k
2
),Δ
2
	​

(k
2
)=−θ(k
0
)δ
′
(k
2
),

the identity is

I
i
˙
	​

[f]=I
unit
	​

[
s
ij
	​

k
j
	​

⋅∂
k
i
	​

	​

f−(D−3)f
	​

].
	​

(1)

Here I
i
˙
	​

 replaces only cut i by Δ
2
	​

; the right-hand side has three unit cuts. This uses ordinary integration by parts on cut distributions, rather than replacing a doubled cut by an ordinary on-shell restriction. That distinction is essential for doubled propagators. 
arXiv
+1

Derivation and boundary issue

Apply

∂
k
i
μ
	​

	​

[
s
ij
	​

k
j
μ
	​

	​

fΔ
1
	​

(k
i
2
	​

)Δ
1
	​

(k
j
2
	​

)].

Since s
ij
	​

 is independent of k
i
	​

,

∂
k
i
	​

	​

⋅
s
ij
	​

k
j
	​

	​

=−
s
ij
	​

D
	​

.

The derivatives of the two cut arguments supply

s
ij
	​

2k
i
	​

⋅k
j
	​

	​

δ
′
(k
i
2
	​

)δ(k
j
2
	​

)=δ
′
(k
i
2
	​

)δ(k
j
2
	​

)+
s
ij
	​

δ(k
i
2
	​

)δ(k
j
2
	​

)
	​

,

and

−
s
ij
	​

2k
j
2
	​

	​

δ
′
(k
j
2
	​

)=
s
ij
	​

2
	​

δ(k
j
2
	​

).

The coefficient is therefore 1+2−D=3−D, giving (1).

At fixed s
ij
	​

>0, energy-step-function contact terms are absent: k
i
	​

=0 or k
j
	​

=0 would force s
ij
	​

=0. A cutoff depending only on s
ij
	​

 is annihilated by this derivative. The remaining endpoint limit can be taken in the sufficiently convergent large-D domain and then continued meromorphically.

Why it fits all three of your subclasses

The right-hand side introduces s
ij
−1
	​

, and differentiating an existing inverse factor can increase its power by one. Thus its positive denominator count is at most N+2.

Choose j so that (i,j) is already an active pair whenever possible. Then:

No original pair becomes at most one pair.

One original pair becomes at most two pairs.

With two original pairs, at least one contains i; choosing that pair introduces no third denominator.

Derivatives of external-subset factors produce numerators such as P⋅k
j
	​

 and k
j
	​

⋅R. After differentiation, the unit-cut equations reduce these to your existing external and pair numerator structures. A third pair occurring only polynomially can be eliminated using the unit-cut invariant sum rule.

Differentiate first, impose unit-cut identities afterward. Equation (1), for example, correctly gives

I
i
˙
	​

[k
i
2
	​

]=I
unit
	​

[1].

Reducing k
i
2
	​

 to zero before differentiating would lose this.

I would implement (1) as a cross-check and potentially as the production reduction for these 87 targets. It turns their whole-domain coefficients into integrals accepted by the unit-cut constructor, with the same conservative threshold

D>4(N+2)+2.

It does not imply that these new unit-cut targets are already reduced by the existing global Kira tables.

2. The massive construction has a uniform angular bound

Here is a proof supporting your proposed massive route independently.

Use

α=
2
D−2
	​

,β=D−3=2α−1,h=1−
j
∑
	​

x
j
	​

μ
j
	​

	​

,

and retain the fixed massless fraction/angular probability measure dν
D
	​

(x,ω). The massive measure is that measure multiplied by the known normalization and h
+
β
	​

.

The transverse coordinates satisfy

j
∑
	​

K
j
	​

=0,
j
∑
	​

x
j
	​

K
j
2
	​

	​

=1,K
j
2
	​

≤x
j
	​

(1−x
j
	​

).

For each j, define

W
j
	​

=
x
j
	​

(1−x
j
	​

)
	​

K
j
	​

	​

.

Conditional on x, its marginal is the projection of the uniform sphere in 2(D−2) dimensions onto D−2 components:

dπ
α
	​

(W)=C
α
	​

(1−∣W∣
2
)
α−1
d
2α
W,∣W∣<1.
(2)

Its normalization and radial moments are beta integrals. 
DLMF

Exact massive external fraction

Choose the reference light-cone direction so that

Y
P,j
	​

:=
P⋅Q
P⋅k
j
	​

	​

=a
P
	​

x
j
	​

+b
P
	​

x
j
	​

hK
j
2
	​

+μ
j
	​

	​

−2
a
P
	​

b
P
	​

h
	​

e
P
	​

⋅K
j
	​

,

where

a
P
	​

+b
P
	​

=1,a
P
	​

≥a
0
	​

>0,b
P
	​

=O(z)

for the small-positive-z coalescing kinematics.

Equivalently,

Y
P,j
	​

=∣Ae
P
	​

−BW
j
	​

∣
2
+η,
	​

(3)

with

A
2
=a
P
	​

x
j
	​

,B
2
=b
P
	​

h(1−x
j
	​

),η=
x
j
	​

b
P
	​

μ
j
	​

	​

≥0.

This expression supplies the needed uniform estimate:

E
ω
	​

[Y
P,j
−p
	​

∣x]≤C
α,p,a
0
	​

	​

x
j
−p
	​

,α>max(p,1).
	​

(4)

The constant is independent of z,μ,h, and the external transverse direction, within the stated domain.

Proof of the uniformity

If B<A/2, then

∣Ae
P
	​

−BW
j
	​

∣≥A/2.

If B≥A/2, factor out B
2
. The remaining singularity is centered at (A/B)e
P
	​

, whose distance from the origin is at most two. The density in (2) is bounded for α≥1, and the translated Riesz kernel

∣W−w
0
	​

∣
−2p

has a uniformly finite integral over the unit ball when 2p<2α. Multiplication by B
−2p
≤2
2p
A
−2p
 gives (4). The nonnegative η can only improve the estimate.

This proof also works for real noninteger D. Use one parallel coordinate and a perpendicular radius with weight r
⊥
2α−2
	​

. Near the translated singularity, the radial integral is bounded by

∫
0
C
	​

r
2α−1−2p
dr,

which has the same condition α>p. No inference from integer dimensions alone is being made.

Subset denominators and pair denominators

For a future-causal subset sum R,

R
2
≤
P⋅Q
z
	​

P⋅R.

Therefore, for sufficiently small z,

∣(P−R)
2
∣≥cP⋅R,(P+R)
2
≥2P⋅R,

with c>0 uniform under the nonnegative mass deformation. Choosing any constituent k
j
	​

 gives P⋅R≥P⋅k
j
	​

. Thus (4) bounds every recognized external denominator.

For a pair,

Y
e
	​

(μ)≥hy
e
	​

,

and the conditional moment already established gives

E
ω
	​

[y
e
−p
	​

∣x]=C
p
	​

(α)x
e
−p
	​

,α>p.
	​

(5)

These beta moments follow from the same conditional spherical measure. 
DLMF

No joint independence is required. Equations (4)–(5) are marginal bounds to which Hölder can be applied.

3. Your derivative estimates have the necessary endpoint control

In scaled transverse variables,

∂
μ
i
	​

	​

(
h
	​

K
j
	​

)=−
2x
i
	​

h
	​

K
j
	​

	​

.

Restoring the longitudinal scale,

∂
μ
i
	​

	​

k
j
−
	​

=
Q
+
z
	​

[−
x
i
	​

x
j
	​

K
j
2
	​

	​

+
x
j
	​

δ
ij
	​

	​

].
	​

(6)

The apparent extra x
j
−1
	​

 is harmless:

x
j
	​

K
j
2
	​

	​

≤1,
x
j
	​

δ
ij
	​

	​

=
x
i
	​

δ
ij
	​

	​

.

Thus the longitudinal derivative has only one required inverse fraction, x
i
−1
	​

.

For an external-subset propagator, (3), b
P
	​

=O(z), and 
a
P
	​

b
P
	​

	​

=O(
z
	​

) give

∣∂
μ
i
	​

	​

E
P
	​

∣≤C[
x
i
	​

h
	​

z
	​

	​

+
x
i
	​

z
	​

].
	​

(7)

For a quadratic external factor, the derivative of its zR
2
/z term supplies the additional O(z)/x
i
	​

 contribution. Linear P⋅R factors obey the same bound without that term.

For a pair,

∂
μ
i
	​

	​

Y
e
	​

=
x
i
	​

−y
e
	​

+1
i∈e
	​

x
e
	​

	​

,∣∂
μ
i
	​

	​

Y
e
	​

∣≤
x
i
	​

2
	​

.
	​

(8)

Recognized numerator factors are bounded on the massive phase space after the explicit normal powers have been extracted. Differentiating them obeys these same estimates, but does not increase the positive denominator count.

The N+2 count

Let

A
+
	​

=
e
∑
	​

max(a
e
	​

,0),N=N
external
	​

+A
+
	​

.

Every term in the first derivative has:

at most one explicit x
i
−1
	​

;

conditional angular inverse powers totaling at most N+1;

an explicit h-power bounded below by

β−A
+
	​

−1.

The last bound covers measure differentiation, an increased pair power, and the h
−1/2
 from an external derivative.

For the square of a derivative term, conditional Hölder uses moments of order at most 2(N+1). Equations (4)–(5) then leave fraction factors with total inverse degree at most

2+2(N+1)=2(N+2).

Replace any complement x
e
−p
	​

 by x
j
−p
	​

 for a selected j∈e. The remaining integral is bounded by a Dirichlet integral, which converges whenever each singleton exponent is smaller than α. The stronger single condition

α>2(N+2)

therefore suffices. 
DLMF

At the same time,

α>2(N+2)⟹β−A
+
	​

−1>0.

Hence the h-factor can be bounded by one.

Combining these facts proves

0<z<z
0
	​

μ≥0
	​

sup
	​

∥∂
μ
i
	​

	​

Φ(z,μ;⋅)∥
L
2
(dν
D
	​

)
	​

<∞,D>4(N+2)+2,
	​

(9)

where the density Φ includes h
+
β
	​

 and is extended by zero outside h>0.

For the terms obtained by differentiating external factors, the stronger estimate is

∥∂
μ
i
	​

	​

Φ
external derivative
	​

∥
L
2
	​

≤C(D)
z
	​

.
	​

(10)

Thus their suppression survives integration. It is not merely a pointwise assertion.

4. Domain differentiation: no missing surface term in this domain

The elementary identity

∂
μ
i
	​

	​

h
+
β
	​

=−
x
i
	​

β
	​

h
+
β−1
	​


does not by itself settle the integral with singular pair factors. The relevant behavior of the whole density is at worst

h
+
β−A
+
	​

	​

,

and that of its derivative is at worst

h
+
β−A
+
	​

−1
	​

.

Your proposed dimension condition makes the density vanish at h=0 and its first derivative integrable there. For fixed interior fractions and almost every angular configuration, its zero extension is locally absolutely continuous in the varied mass. There is therefore no omitted delta contribution from crossing h=0.

Equation (9) upgrades this pointwise statement to the full integral. On the finite base measure, the derivatives are uniformly integrable. Their almost-everywhere convergence as μ
i
	​

↓0 implies convergence in L
1
, and the fundamental theorem of calculus gives

∂μ
i
	​

∂
	​

∫Φ(z,μ)dν
D
	​

	​

μ=0
+
	​

=∫∂
μ
i
	​

	​

Φ(z,μ)∣
μ=0
	​

dν
D
	​

.
	​

(11)
A particularly simple single-mass endpoint check

Since only μ
i
	​

=μ is varied, the physical domain is exactly

x
i
	​

>μ.

Split off x
i
	​

≤2μ. The Dirichlet marginal gives

ν
D
	​

(x
i
	​

≤2μ)=O(μ
α
).

A uniform L
2
 bound for the density therefore gives

μ
1
	​

∫
x
i
	​

≤2μ
	​

(∣Φ(z,μ)∣+∣Φ(z,0)∣)dν
D
	​

=O(μ
α/2−1
).
(12)

This tends to zero for α>2, well inside your sufficient domain.

On the complementary region x
i
	​

>2μ, one has h>1/2, so there is no moving-h-endpoint singularity. The angular bound and the first-derivative estimates justify differentiation there. This supplies an explicit split-domain proof that the lost massive support contributes nothing to the first derivative.

It also explains why a naive argument based only on differentiating the massless integrand would have been insufficient: the missing strip has now been bounded, rather than ignored.

5. The resulting physical coefficient and its numerator qualification

Let

F(x,ω)=f
ext
	​

(x)
e
∏
	​

y
e
−a
e
	​

	​

,A
pair
	​

=
e
∑
	​

a
e
	​

,

where the sum is signed, so pair numerators correspond to negative a
e
	​

.

Equations (7) and (10) remove the external-derivative terms from the leading coefficient. Differentiating the measure and pair factors gives exactly

D
i
	​

F=
x
i
	​

A
pair
	​

−β
	​

F−
e∋i
∑
	​

x
i
	​

y
e
	​

a
e
	​

x
e
	​

	​

F.
	​

(13)

Suppose the explicit Q
2
 factors contribute z
−m
. Since

∂
m
i
2
	​

	​

	​

z
	​

=z
−1
∂
μ
i
	​

	​

,

the dotted integral satisfies

I
i
˙
	​

(z,D)=z
D−4−m−A
pair
	​

[C
i
˙
	​

(D)+o(1)],
	​

(14)

where C
i
˙
	​

 is the existing normalized fraction/angular integral of D
i
	​

F, including the retained external scales and measure factors.

The argument proves both the coefficient limit and an absolute bound with this power. If the coefficient vanishes, it remains a valid zero coefficient and bound; it does not identify the next nonzero power.

What must be added for more general numerators

Equation (13) assumes that all unsuppressed mass dependence has been represented by the Y
e
	​

's. For a remaining numerator P(x,ω,μ), add

∂
μ
i
	​

	​

P∣
0
	​


times the other massless factors.

A decisive test is

k
i
2
	​

Δ
2
	​

(k
i
2
	​

)=Δ
1
	​

(k
i
2
	​

).

A numerator whose massless restriction vanishes can therefore contribute to the dotted integral. Preserving the original polynomial is necessary; actually differentiating it is necessary as well.

For your recognized external and pair monomials, (13) already includes the pair-numerator derivatives, and (10) handles the external-numerator derivatives. Any additional numerator structure should either pass the same derivative estimate or produce an explicitly retained extra insertion.

The identification of a cut derivative with a derivative of the full on-shell measure is precisely why changes in the kinematic measure must accompany changes in the displayed integrand. 
Springer

6. Compact distributions are acceptable—but not a substitute for this endpoint check

You may define the coefficient using analytically continued compact parameter distributions, retaining

h
+
β
	​

,Y
e
	​

(μ),and the original numerator

through differentiation.

The safe logical order is:

identity in a real large-D convergence interval⟶meromorphic continuation of that identity.
	​


Equations (9)–(12) provide the convergence-interval justification. After that, the distributional formulation is a convenient exact representation, not an assumption.

Do not instead discard endpoint distributions and invoke analytic continuation to justify their absence. Nor should continuation of (14) be interpreted as convergence of the same scaled limit near D=4: other epsilon slopes may dominate there.

No generic massive-family reduction is needed for this proof. It concerns a single mass derivative at zero, with the specified domain and generators.

7. The exceptional zero-slope mode can now be tested against the same physical bound

Yes. For any eligible dotted row, equation (14) gives a large-real-D bound of the same D-slope as the unit-cut bound. The dot shifts only the fixed integer power by −1.

A nonzero zero-slope Frobenius component, even if it first appears at a later integer normal power, cannot obey

O(z
D−4−m−A
pair
	​

)

for arbitrarily large real D. Logarithms do not repair that mismatch.

Therefore, if one of the newly eligible dotted observations sees the exceptional direction as a complete generic-epsilon germ, its amplitude must vanish meromorphically. In the saturated/current coordinates this may be a linear or affine relation, rather than setting one stored coordinate to zero.

Check the exact observation of that direction, then its projected rank against the already imposed equations. This is an additional physical constraint only if the projected rank increases.

8. Minimal acceptance record and regressions

For each accepted profile, the mechanical certificate can contain the following bounds:

	​

explicit fraction inverse degree≤1,
conditional angular inverse degree≤N+1,
remaining h exponent≥β−A
+
	​

−1,
discarded external-derivative factor=O(
z
	​

).
	​


Together with the exact off-shell generator match, these imply the sufficient threshold

D>4(N+2)+2.
	​


A term that exceeds one of these bounds need not be rejected permanently. Recount its actual inverse degrees and derive a larger threshold. What should be rejected is treating that term as covered by the N+2 certificate without checking it.

The most useful regressions are the dotted volume, the cut-numerator identity above, and agreement between the massive insertion operator (13) and the dot-lowering identity (1) for representative zero-, one-, and two-pair profiles. For the volume,

V
V
i
˙
	​

	​

=−
(D−4)z
(D−3)(3D−8)
	​

=
ϵz
(1−2ϵ)(2−3ϵ)
	​

,

which checks the cut sign and the mass-to-μ scaling simultaneously.

Under the stated generator restrictions, your proposed threshold can therefore be promoted from a heuristic to a sufficient acceptance condition. The conditional angular estimate controls moving collinear centers, the h-power and strip estimates control the domain derivative, and the external-derivative terms vanish in norm. For computation, the exact one-dot identity offers an especially direct way to reuse the already verified unit-cut boundary machinery while checking the massive construction independently.