# Verified GPT-6 Pro review 18

Model: gpt-6-pro; message 03de3d46-49c7-4ba1-abc4-770f1ddf60d2; HTTP 200.

Please review the next concrete mathematical step for finishing integrated electromagnetic SIDIS NNLO UU/LL through our general code. Repository https://github.com/CongyueZhang2002/factorization-and-loops (local work is newer; do not infer unpushed code from GitHub). This continues your reviews 16 and 17.

Current facts: after exact affine identities and closure of their derivatives, the q-q RR system has 42 spanning masters. All 42 have UNIT powers on the three particle cuts and the one z measurement cut. Ordinary propagator powers and numerators vary. Thus the dotted-cut caveat does not obstruct physical boundary evaluation of this basis. The same N-variable finite solver has written and verified 192 explicit coefficients through requested epsilon^0, using derived ordinary-point bounds, but physical boundary constants are still unknown. There is no full NNLO claim.

Kinematics p^2=0, q^2=-Q2, 2p.q=Q2/x; P=p+q, S=P^2=Q2(1-x)/x, J=2p.P=Q2/x. Measurement z=2p.k1/J, k1+k2+k3=P. We have the normalized exact phase-space chart with independent beta measures in t,y,a:
alpha=1-eps, beta=1/2-eps;
t,y ~ Beta(alpha,alpha), a ~ Beta(beta,beta).
s23=S(1-z)t;
s12=S[y+z t-(1+z)t y-2 sqrt(z t(1-t)y(1-y))(1-2a)];
s13=S-s23-s12;
2p.{k1,k2,k3}=J {z,(1-z)y,(1-z)(1-y)}.
The full prefactor is the exact measured massless three-body volume.

Every active ordinary denominator in this 42-master basis is a final subset invariant, p minus a future subset invariant, or the physical-gauge factor P.k2=(s12+s23)/2. Their products were certified by the one compact-cut meromorphic continuation theorem. We retain all exact signs and normalization; no frozen unit-cut identities are used to redefine off-shell families.

Plan:
1. Implement a generic unit-cut chart provider accepting the actual normalized integral definition. It must prove the affine loop routing and exact measure conversion, rather than assume process normalization.
2. For rho=1-x ->0 at generic 0<z<1, reuse your uniform ratio bound 0<=K^2/S<=2p.K/J<=1 to expand (p-K)^2=-J alpha_K[1-rho f_K/alpha_K] uniformly. This gives whole-domain leading coefficients and finite Taylor jets. Final subset and P.k2 factors scale exactly with S; record the normal exponent per master.
3. Use the existing regular-singular/Frobenius and tangential-DE code to identify physical rho modes and boundary functions. Then fix the latter from the ordered z ->1 limit and exact beta/angular moments.
4. Do not equate the naive z=1 integrand with all boundary regions. Your earlier warning was the correlated P.k2 zero, with t-y~sqrt(1-z), a~1-z and scaling (1-z)^(1-eps-h) for power h.

Please focus on an IMPLEMENTABLE analytic strategy for the ordered z boundary:
- Can the angular integral over a be done exactly into a Gauss hypergeometric that makes all z=1 regions explicit, followed by t,y beta integrals? For our gauge factor P.k2 plus possible s12 denominators, what coordinate change best separates the correlated zero?
- Is there a useful spherical-convolution/Gegenbauer identity to reduce the boundary integral to Gamma functions/3F2(1), and expose the suppressed branch needed for all constants?
- How can the generic code establish enough independent physical boundary equations without performing 42 unrelated full integrations?
- State a practical completeness/rank check, and any flaw in the rho uniform expansion including numerator factors and the z-independent explicit measure.
Please give formulas with signs, normalization and convergence/continuation conditions. We must derive the result from the framework; published hard coefficients are validation only.


## Response

The plan is sound, and the unit-cut basis removes the main obstruction to direct physical boundary evaluation. I recommend changing the angular coordinates before integrating them. A rotation of the second decay’s polar axis, followed by a simple rational reparameterization, turns the correlated P⋅k
2
	​

 zero into

u+λr,λ=
z
1−z
	​

.

For your stated denominator inventory, this isolates the nonuniform z-dependence in one factor. The remaining boundary integrations can be organized into reusable Gamma/
3
	​

F
2
	​

(1) moments and a one-dimensional Mellin–Barnes expansion, rather than 42 separate integrations.

The formulas below follow from your supplied normalized chart. They do not require a published master basis or boundary value.

1. The ρ-expansion is justified, with two normalization qualifications

Write

ρ=1−x,σ=1−z,S=Jρ,J=
1−ρ
Q
2
	​

.

For a future subset K, set

α
K
	​

=
J
2p⋅K
	​

,f
K
	​

=
S
K
2
	​

.

Your established inequality gives

0≤f
K
	​

≤α
K
	​

≤1,

and therefore

(p−K)
2
=−Jα
K
	​

(1−ρ
α
K
	​

f
K
	​

	​

).

For integer ordinary power n,

[(p−K)
2
]
n
1
	​

=(−1)
n
J
−n
α
K
−n
	​

j=0
∑
∞
	​

j!
(n)
j
	​

	​

ρ
j
(
α
K
	​

f
K
	​

	​

)
j
.
	​

(1)

For negative integer n, this terminates and is simply the numerator identity. Preserve the original causal phase if auxiliary noninteger propagator powers are introduced; (−1)
n
 is the integer-power specialization.

Because 0≤f
K
	​

/α
K
	​

≤1, the series is uniform for ∣ρ∣≤ρ
0
	​

<1. The singular factor α
K
−n
	​

 remains: its integrability is supplied by the existing convergence certificate, not by the geometric-series argument. At fixed generic z, the certificate and the uniform ratio bound justify integration of any specified finite Taylor jet in a common convergence domain, followed by meromorphic continuation.

For polynomial numerators, first expand them into finitely many homogeneous scalar-product terms. Determine the ρ-valuation after exact collection; cancellation may raise the onset. Do not replace this coordinate valuation by an epsilon valuation.

Two details must remain explicit:

The normalized beta weights are independent of x,z, but the full measure is not:

V
3
	​

(z)=N(ϵ)S
1−2ϵ
z
−ϵ
σ
1−2ϵ
.

Since S=Jρ, a factored J
ω
 contributes the smooth factor

J
ω
=(Q
2
)
ω
(1−ρ)
−ω
.

Include its Taylor coefficients and all other normalization factors.

For the stated raw unit-cut class, these facts give a strong physical restriction: after extracting the explicit dimensional power, each master has an ordinary Taylor expansion in ρ at generic z. Any different ρ-slope or logarithmic mode in a prepared DE basis must disappear after mapping back to these raw integrals, unless another explicit normalization accounts for it.

That can supply many exact zero boundary equations before evaluating an angular integral.

2. Rotate the chart so the gauge denominator becomes u+λr

Let

W=1−σt.

In the rest frame of K
23
	​

=k
2
	​

+k
3
	​

, introduce the polar variable measured relative to k
1
	​

,

u=
s
12
	​

+s
13
	​

s
12
	​

	​

=
SW
s
12
	​

	​

.

Thus u=(1−cosθ
12
	​

)/2. Replace the remaining relative azimuth by b∈(0,1).

The angle between p and k
1
	​

 in that frame has light-cone angular fraction

r=
1−σt
zt
	​

.

Define

Z(r)=z+σr.

Then

t=
Z(r)
r
	​

,W=
Z(r)
z
	​

,
dr
dt
	​

=
Z(r)
2
z
	​

.
	​

(2)

The original measured fraction y becomes

Y(r,u,b)=r+u−2ru−2
r(1−r)u(1−u)
	​

(1−2b).
	​

(3)

All square roots here are positive on the open cube.

The scalar invariants now take the particularly simple form

s
23
	​

s
12
	​

s
13
	​

2p⋅{k
1
	​

,k
2
	​

,k
3
	​

}
	​

=
Z(r)
Sσr
	​

,
=
Z(r)
Szu
	​

,
=
Z(r)
Sz(1−u)
	​

,
=J{z,σY,σ(1−Y)}.
	​

	​

(4)

In particular,

P⋅k
2
	​

=
2Z(r)
Sz
	​

(u+λr),λ=
z
σ
	​

.
	​

(5)

The old correlated region t−y=O(
σ
	​

), a=O(σ) is now the ordinary endpoint region

u=O(λr).
Exact measure conversion

Use

dμ
α
	​

(v)=
B(α,α)
v
α−1
(1−v)
α−1
	​

dv,α=1−ϵ,β=α−
2
1
	​

.

Rotating the polar axis preserves the normalized angular measure. The radial change (2) gives

dμ
α
	​

(t)=z
α
Z(r)
−2α
dμ
α
	​

(r).

Consequently,

[dΦ
3
	​

]
z
	​

=V
3
	​

(z)z
α
Z(r)
−2α
dμ
α
	​

(r)dμ
α
	​

(u)dμ
β
	​

(b).
	​

(6)

There is no additional azimuthal factor. A useful normalization identity is

∫
0
1
	​

dμ
α
	​

(r)z
α
Z(r)
−2α
=1.
	​

(7)

It follows either from (2) or directly from the Euler beta representation. 
DLMF

This is an integration-coordinate change after full-D scalarization. It does not declare K
23
	​

 or k
1
	​

 to be physical four-dimensional vectors, and it does not redefine an off-shell family.

Why this isolates the difficult z-dependence

Near z=1,

Z(r)=1−σ(1−r)

is uniformly bounded away from zero. The other subset fractions are

z,σY,σ(1−Y),σ,1−σY,1−σ(1−Y).

After explicit powers of σ are removed, the last two factors have uniformly convergent Taylor expansions.

Therefore, at each finite ρ-jet and each required finite smooth σ-jet, your stated denominator inventory reduces to finite sums of kernels built from

r,u,1−u,Y,1−Y,u+λr.

The only nonuniform small-λ factor is the last one. That is the main simplification to implement.

3. Integrating the original a first is possible, but not the best default

For one affine factor,

∫
0
1
	​

dμ
β
	​

(a)(A+Ba)
−h
=A
−h
2
	​

F
1
	​

(h,β;2β;−
A
B
	​

).
	​

(8)

This is the ordinary Euler representation, initially for convergent parameters and a consistent branch. 
DLMF

Two distinct factors, such as s
12
−b
	​

(P⋅k
2
	​

)
−h
, generically produce an Appell F
1
	​

, not one Gauss function. A third affine factor can produce a higher multivariable Euler function. Integer-power partial fractions can reduce the number of factors, but may introduce large artificial powers of 1/σ. 
DLMF

More importantly, in the original chart

A=(
(1−t)y
	​

−
zt(1−y)
	​

)
2

itself vanishes on a correlated t,y locus. Equation (8) does not make all subsequent t,y regions explicit.

Use (8) as an integration primitive and a check, not as the universal boundary strategy. The rotated chart separates the problematic geometry before invoking special functions.

4. A reusable spherical-convolution rule gives the hard-boundary constants

Define

K
α
	​

(b,c)=
Γ(α)
2
Γ(2α−b−c)
Γ(2α)Γ(α−b)Γ(α−c)
	​

.

With Y from (3),

∫dμ
α
	​

(u)dμ
β
	​

(b
ang
	​

)Y(r,u,b
ang
	​

)
−b
u
−c
=K
α
	​

(b,c)
2
	​

F
1
	​

(b,c;α;1−r).
	​

(9)

Here b
ang
	​

 denotes the angular integration variable, distinct from the exponent b.

One derivation combines the two denominators with a Feynman parameter, performs the rotational average using

⟨(
n
⋅
v
)
2j
⟩=
(α+1/2)
j
	​

(1/2)
j
	​

	​


on the full spatial sphere, and evaluates the remaining Euler integral. Equivalently, this is a zonal spherical convolution. General dimensionally regulated angular integrals are naturally organized in this way. 
arXiv

Replacing exactly one of Y,u by its complement changes the argument from 1−r to r. Replacing both leaves 1−r.

Useful checks are

C
0,c
	​

(r)=
B(α,α)
B(α−c,α)
	​


and

⟨Yu⟩
u,b
ang
	​

∣r
	​

=
2(2α+1)
α+1−r
	​

.
	​

(10)

I checked twelve polynomial specializations of (9) symbolically, retaining α and r as variables.

One remaining beta integral produces 
3
	​

F
2
	​

(1)

For an outer weight r
R
(1−r)
T
, set

A=α+R,B=α+T,B
0
	​

=B(α,α).

Then

	​

⟨r
R
(1−r)
T
Y
−b
u
−c
⟩
=K
α
	​

(b,c)
B
0
	​

B(A,B)
	​

3
	​

F
2
	​

(
b,c,B
α,A+B
	​

;1).
	​

	​

(11)

For the opposite-axis case, replace the third upper parameter B by A.

This follows by integrating the Gauss series termwise in a convergence domain and then continuing the resulting Euler identity. 
DLMF

Sufficient initial conditions include

ℜα>ℜb,ℜc,ℜA,ℜB>0,

and, for (11),

ℜ(A+α−b−c)>0.

For the opposite-axis case, the final condition uses B instead of A. These are convergence conditions, not restrictions on the final meromorphically continued answer.

Because your ordinary powers are integers, partial-fraction Y
−m
(1−Y)
−n
, and likewise u
−b
(1−u)
−c
, into single-endpoint terms plus polynomials. Equation (11) then covers the hard-boundary kernels after finite Taylor expansion.

An important Gamma-only subcase

For

H(a,b,c)=⟨r
−a
Y
−b
u
−c
⟩,

the upper α cancels in (11), and Gauss summation gives

H(a,b,c)=
Γ(α)
3
Γ(2α−a−b)Γ(2α−a−c)Γ(2α−b−c)
Γ(2α)
2
Γ(α−a)Γ(α−b)Γ(α−c)Γ(2α−a−b−c)
	​

.
	​

(12)

The summation is initially valid where the corresponding Euler integrals and Gauss series converge. 
DLMF

This explains why many corner constants are Gamma products, while opposite-axis or two-endpoint weights naturally leave 
3
	​

F
2
	​

(1). It provides a kernel classification, not an assumed count of independent constants.

5. Extract the gauge branch before expanding in epsilon
5.1 The elementary endpoint connection formula

For fixed r>0, let η=λr. Define

J(A,B,h;η)=
B
0
	​

1
	​

∫
0
1
	​

duu
A−1
(1−u)
B−1
(u+η)
−h
.

Then

J=
B
0
	​

B(A,B)
	​

η
−h
2
	​

F
1
	​

(h,A;A+B;−1/η).

The connection formula at η=0 gives

J=
	​

B
0
	​

B(A−h,B)
	​

2
	​

F
1
	​

(h,1−A−B+h;1−A+h;−η)
+
Γ(h)B
0
	​

Γ(A)Γ(h−A)
	​

η
A−h
2
	​

F
1
	​

(A,1−B;1+A−h;−η).
	​

	​

(13)

This is an exact continuation identity at generic parameters, not only a leading asymptotic formula. 
DLMF

The first line is the ordinary Taylor branch. The second is the endpoint branch.

For u
−b
(u+η)
−h
,

A=α−b,

so the additional exponent is

η
α−b−h
=η
1−ϵ−b−h
.
	​

(14)

The earlier 1−ϵ−h estimate was the b=0 case. An active s
12
−b
	​

 changes it.

At generic negative ϵ, the second branch may be suppressed. It must still be retained: after continuation, its exponent collides with integer powers and produces logarithms. This is the same reason that an epsilon expansion of an angular integral cannot be substituted into a singular outer integral before its small-scale behavior has been extracted. 
arXiv

For resonant A−h∈Z, take the limit of the sum in (13). Do not separately set the divergent Gamma coefficients to zero or discard one branch.

5.2 A finite-dimensional kernel library can capture the complete expansion

After uniform expansion of the smooth factors in (6), define the core kernels

Q
±
	​

(a,b,c,m,h;λ)=⟨r
−a
u
−b
(1−u)
−c
Y
±
−m
	​

(u+λr)
−h
⟩,
	​

(15)

where

Y
+
	​

=Y,Y
−
	​

=1−Y,

and the average uses the three normalized beta measures.

For your stated denominator inventory, polynomial numerators and integer-power partial fractions reduce the required finite jets to finitely many shifted versions of (15). Factors r
R
(1−r)
T
 with nonnegative integer T can be expanded into powers of r. Keep any unrecognized denominator outside this acceptance rule.

For h>0, use

Q
±
	​

=
2πiΓ(h)
1
	​

∫
C
	​

dwΓ(−w)Γ(h+w)λ
w
M
±
	​

(w).
	​

(16)

Initially take −ℜh<ℜw<0, together with sufficiently large ℜα to make the angular integrals absolutely convergent. This Mellin–Barnes decomposition follows from the Euler/Barnes representation of (u+λr)
−h
. 
DLMF

The angular factor in (16) can itself be evaluated by (9)–(11). Put

a
′
=a−w,d
′
=b+h+w,A=α−d
′
,B=α−c.

Then

M
+
	​

(w)
M
−
	​

(w)
	​

=K
α
	​

(a
′
,m)
B
0
	​

B(A,B)
	​

3
	​

F
2
	​

(
a
′
,m,B
α,A+B
	​

;1),
=K
α
	​

(a
′
,m)
B
0
	​

B(A,B)
	​

3
	​

F
2
	​

(
a
′
,m,A
α,A+B
	​

;1).
	​

	​

(17)

This is a useful endpoint algorithm: one Barnes variable, with an explicitly known Gamma/
3
	​

F
2
	​

(1) coefficient, rather than a new three-variable region integration for every master.

5.3 For this core, the two right-pole families can be established

Do not treat a pole of a bottom hypergeometric parameter as a separate pole before combining it with

Γ(A+B)
1
	​


from B(A,B). Use the corresponding regularized 
3
	​

F
2
	​

 representation.

Its parametric excess is

M
+
	​

:
M
−
	​

:
	​

2α−a−b−h−m,
2α−c−a−m+w.
	​


Choose the initial large-D domain so these have positive real part on the required rightward contour strips. The regularized series is then analytic there, apart from the displayed Gamma factors. Absolute convergence and parameter analyticity of these series are controlled by precisely this excess. 
DLMF

The possible right-pole families are consequently

w=n,w=α−b−h+n,n=0,1,2,….
	​

(18)

Some residues can vanish. At special epsilon values the families collide.

Thus the compiled core has a hard series in integer powers of λ and a second series beginning at λ
α−b−h
. The other angular boundary strata are included in M
±
	​

; they have not been discarded by restricting r away from its endpoints.

To turn this into a complete asymptotic certificate through a requested order, shift the contour past all poles below that order and bound the remaining vertical integral—or implement the equivalent finite Euler endpoint subtractions. Merely listing Gamma poles without verifying the remainder would not establish the expansion.

The right-pole enumeration above is conditional on the core form (15). A future denominator outside that form can introduce more pole families.

5.4 Both sets of coefficients are inexpensive to generate

At the hard poles, the coefficients are

n!
(−1)
n
(h)
n
	​

	​

M
±
	​

(n).
	​

(19)

They are Gamma/
3
	​

F
2
	​

(1) expressions.

At the second family:

For M
−
	​

, the upper parameter A=−n, so the 
3
	​

F
2
	​

 terminates.

For M
+
	​

, the third upper parameter B and the bottom parameter B−n differ by the integer n. Their Pochhammer ratio is a polynomial in the summation index. The residue reduces to a finite sum of Gauss-summable 
2
	​

F
1
	​

(1) functions.

Hence these endpoint residues reduce to finite Gamma sums.

For example, the leading extra branch is

Q
+
	​

Q
−
	​

	​

⊃λ
α−b−h
Γ(h)B
0
2
	​

Γ(α−b)Γ(b+h−α)
	​

B(2α−a−b−h−m,α),
⊃λ
α−b−h
Γ(h)B
0
2
	​

Γ(α−b)Γ(b+h−α)
	​

B(2α−a−b−h,α−m).
	​

	​

(20)

These are dimensionless normalized-kernel coefficients. Restore all factors from the actual integral definition. In particular,

(P⋅k
2
	​

)
−h
=(
Sz
2Z(r)
	​

)
h
(u+λr)
−h
.

The factor 2
h
 must not disappear.

For h=0, use the angular-moment rules directly. For negative integer h, the gauge factor is a polynomial and the expansion terminates.

6. Determine boundary data by rank, not by integrating every master

Use the existing Frobenius machinery to define the unknown homogeneous amplitudes c
ℓ
	​

(ϵ), after all proven differential relations have been imposed. Their number is the dimension of that solution space, not automatically 42.

For every candidate physical asymptotic functional,

B
j
	​

[I]=
ℓ
∑
	​

L
jℓ
	​

(ϵ)c
ℓ
	​

(ϵ).

The right-hand side of the physical matching equation is obtained from the chart:

L(ϵ)c(ϵ)=b
chart
	​

(ϵ).
	​

(21)

Choose rows in this order:

Zero rows from the proved ρ-Taylor structure. These can eliminate inadmissible slopes and logarithmic modes without integration.

Gamma-only hard moments, including the volume and monomial kernels.

The endpoint residues (20) and their required higher orders.

Remaining 
3
	​

F
2
	​

(1) hard moments.

Evaluate a candidate row only if it increases the exact rank of the accumulated matching matrix or provides a useful independent consistency check. The same exponent-pattern kernel will generally serve several master rows and several Taylor coefficients; cache it independently of the master name.

This avoids 42 full integrations. It does not assume that the answer needs only the number of constants found in a different published basis. Independent SIDIS work confirms the usefulness of the double-threshold strategy and of Gamma/
3
	​

F
2
	​

 boundary data, but its specific constants are not needed here. 
arXiv

A practical completeness criterion

Require all three conditions:

Asymptotic coverage. Every matching coefficient used has a derived expansion with a remainder beyond the retained order. For gauge kernels, this includes both families (18), not just the limit of the integrand.

Exact rank. The accumulated physical rows have full column rank over the meromorphic/rational epsilon field appropriate to the normalized Frobenius amplitudes. If rank is deficient, compute another asymptotic order or another inexpensive physical functional. Do not set the remaining constants to zero.

Sufficient Laurent depth. A nonzero matching determinant can vanish at ϵ=0. The inverse matching matrix can therefore demand deeper boundary coefficients than the nominal ϵ
0
 master output. Feed these valuations into the existing order planner.

The 192 interior coefficients do not determine that last requirement by themselves. Boundary matching and singular basis transformations belong in the same dependency-depth calculation.

Keep exponents such as

λ
α−b−h

unexpanded while matching modes. Expand in epsilon only after combining the relevant branches and normalization factors. At epsilon zero, colliding powers produce logarithms and pole cancellations; matching the expanded logarithms too early can obscure which data remain unknown.

7. Recommended implementation sequence and checks

The smallest reusable addition is a boundary-kernel compiler, not a new general three-variable integrator:

Stage	Output
Normalize the actual unit-cut definition	Proven loop routing, exact physical-measure conversion, ordinary signs, numerator polynomial
Produce finite ρ-jets	Explicit normal powers and uniformly derived angular kernels
Apply (2)–(6)	Fixed beta measures, smooth z,Z(r) factors, isolated u+λr
Compile exponent patterns	Gamma/
3
	​

F
2
	​

 hard moments and Barnes kernels (15)
Generate required residues	Both pole families, with exact epsilon dependence
Rank-select physical equations	Only as many independent boundary evaluations as required
Substitute and audit	Original targets, DE compatibility, unused physical checks

The most discriminating inexpensive checks are:

Geometry: verify (2)–(7), reconstruct the full Gram determinant in the new coordinates, and compare several nontrivial polynomial moments in both charts. This checks the rotation and the nontrivial z
α
Z
−2α
 Jacobian separately from the original volume test.

Angular algebra: verify (9) on polynomial numerator powers and compare selected convergent noninteger examples with the original beta quadrature. The exact polynomial checks test normalization without relying on singular numerical integration.

Suppressed branch: use a kernel with h>0 and ℜα>b+h, where the second term is genuinely subleading. Subtract the hard series and check the predicted power and coefficient in (20). This specifically detects the error of keeping only the naive z=1 integrand.

Matching: after solving (21), check additional physical moments not used as pivots and both tangential DEs. Flatness alone is not a normalization or boundary check.

All manipulations should begin in a common convergence domain with positive z,λ, then continue meromorphically with the original prescriptions. The existing certificate supplies the authorized ordinary-i0 limit; none of the angular changes or hypergeometric identities supplies a new one.

The decisive improvement is the rotated chart: it changes a correlated square-root zero into one additive endpoint denominator. For the stated active factors, that permits a finite library of universal angular moments plus two explicitly controlled Mellin pole families. Combined with exact boundary-rank selection, it is a concrete route to the missing physical constants without solving every master integral independently or importing any boundary data.