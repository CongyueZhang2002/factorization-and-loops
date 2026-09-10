# Measured convergence and three-particle parameterization

Verified gpt-6-pro, standard, HTTP200. Request8f8bb7fc-50b6-4132-9319-ca9db8f44de7.

## Question

Thank you; implementing explicit physical P and epsilon BMHV lowering, with regulator-sensitive tests, is the next polarized algebra step. Please review two linked phase-space points before we connect actual SIDIS RR masters. Focus on gaps, do not infer an i0 proof from sign alone.

1. Existing ONE convergence certificate (not a new competing certificate): unmeasured compact forward-energy 3-body cuts with independent nonnegative mass increments. Every ordinary denominator zero lies on the true full transverse Gram boundary throughout those increments. A sufficiently large Re(D) suppresses all finite required cut-mass derivatives and allows ordinary eta->0; continue meromorphically. It currently demands particle cut count=L+1 and knows no linear measurement cut.

Proposed extension to a measured distribution z=2p.k1/J, J=2p.P>0, fixedgeneric x in(0,1): test the measured integral against any smooth compactly supported phi(z). Unit linear cut with Jacobian J gives phi(2p.k1/J); raised measurement cuts give exact derivatives of phi and factors J^{1-n}/(n-1)! (please verify sign/power). This is a smooth bounded insertion on the SAME compact mass-deformed phase space because J is external and nonzero. Thus reuse exactly the old ordinary-zero/Gram proof; the linear cut is removed only in the proof via its action on a test function, never silently dropped from integral definitions or IBPs. Does this justify i0-independence as a z-distribution at fixedgeneric x for every finite measurement cut order, and pointwise inside regular z chambers? What is still needed at external x endpoints? Do NOT assert joint x-endpoint uniformity from this argument. Need measured-family certificate metadata clearly distinguish particle mass derivatives and measurement test-function derivatives.

Fast SIDIS zero-boundary lemma already reviewed: for future K,P-K, nullp with2p.P>P^2, (p-K)^2<=0 with zero only nullcollinear; survives nonnegative cut masses. We can add this as another zero-containment witness within the same certificate, not another approval flag.

2. New direct three-variable parameterization (no literature coefficients). Let P^2=S>0,p^2=0,2p.P=J>0,taggedz=2p.k1/J in(0,1), masslesski,sumki=P. Variables t,y,a in(0,1), c=1-2a:
s23=S(1-z)t,
s12=S[y+zt-(1+z)ty-2sqrt(zt(1-t)y(1-y))*c],
s13=S-s12-s23,
2p.ki/J={z,(1-z)y,(1-z)(1-y)},
2P.ki={s12+s13,s12+s23,s13+s23}.
FullGram det(p,P,k1,k2)=-J^2 S^2 z(1-z)^2 t(1-t)y(1-y)a(1-a).
Measure=dPhi3/dz * independent normalized beta densities for
t~Beta(1-eps,1-eps), y~same, a~Beta(1/2-eps,1/2-eps).
dPhi3/dz= S/(2Pi)*Phi2(S)^2*z^(-eps)*(1-z)^(1-2eps),
using Lorentz invariant measure d^{D-1}k/[(2Pi)^{D-1}2E],D=4-2eps.
Derived recursively P->k1+K23 thenK23->k2+k3; first measured polarangle eliminated withitsJacobian. Exact tests pass total/masslessmomenta, fractionconservation, E[c^2]=1/(D-2), E[s12]=S(1+z)/4, E[s23]=S(1-z)/2, recursiveGamma normalization and fullGram determinant.
Is it correct as a full-D scalar integration representation AFTER joint evanescent averaging? Any missing azimuthal normalization or dimension branch? Would a normalized Gauss-Jacobi product rule at convergentnegativeeps be an appropriate cheap direct check/boundary seed, while singular or dotted-particle masters use analytic/mass-derivative treatment? Please give a concrete recommendation for implementing measured i0 proof and this integration geometry without weakening the current mathematical contract.


## Pro response

The proposed measured extension is sound as a consequence of the existing convergence certificate, provided its domination estimate remains valid with smooth insertions and the required particle-mass derivatives. The raised-measurement formula needs the sign (−1)
n−1
. Your three-variable parameterization and beta-product measure are correct, with no additional azimuthal normalization.

The two qualifications to retain are that distributional i0-independence does not by itself establish pointwise convergence of the regulated densities, and nothing in the fixed-x argument establishes uniformity at the external x endpoints.

1. Extend the existing certificate by a test-function operation
1.1 Exact action of the raised measurement cut

Set

f(k)=
J
2p⋅k
1
	​

	​

,G=J(f−z),J>0,

and retain your normalization

C
n
	​

(G)=
(n−1)!
(−1)
n−1
	​

δ
(n−1)
(G).

Then

∫
R
	​

dzϕ(z)JC
n
	​

(G)=
(n−1)!
(−1)
n−1
J
1−n
	​

ϕ
(n−1)
(f).
	​

(1)

The power of J you proposed is correct; the sign alternates. This follows from the defining action of delta derivatives. 
DLMF

For example,

n=1:
n=2:
n=3:
	​

ϕ(f),
−J
−1
ϕ
′
(f),
2J
2
1
	​

ϕ
′′
(f).
	​


Equivalently, when the rest of the integrand has no explicit z-dependence,

M
n
	​

(z)=
(n−1)!
J
1−n
	​

∂
z
n−1
	​

M
1
	​

(z).
	​

(2)

Equation (1) is the test-function action of (2), not a second sign convention.

One important generality guard: if the multiplier also depends explicitly on z, the derivative acts on the entire product:

∫dzJC
n
	​

(G)A(k,z)ϕ(z)=
(n−1)!
(−1)
n−1
J
1−n
	​

[∂
z
n−1
	​

(A(k,z)ϕ(z))]
z=f
	​

.
	​

(3)

This matters if family completion, partial fractions, or basis normalization introduced z into ordinary denominators. Differentiating them can increase ordinary denominator powers. The certificate must cover those actual terms; the insertion is not then merely ϕ
(n−1)
(f).

A useful initial scope is therefore to certify raw families whose ordinary denominator polynomials are independent of z, with z entering through the measurement alone. More general families can use (3), with the resulting denominator-power and zero-containment checks.

1.2 Why the same compact-domain proof transfers

Let T
ν,σ,η
	​

 denote the unmeasured phase-space functional containing particle-cut powers ν, ordinary prescription choices σ, and the ordinary regulator η.

For unit measurement,

⟨M
1
	​

,ϕ⟩=⟨T,ϕ∘f⟩.

For raised measurement powers, equation (1) gives the corresponding derivative of the test function.

On the entire allowed mass-deformed forward domain,

f
i
	​

=
J
2p⋅k
i
	​

	​

≥0,
i
∑
	​

f
i
	​

=1.

Thus

0≤f≤1

also when the particle masses receive nonnegative increments. At fixed x, p,P,J are fixed, J

=0, and f is a smooth affine function of the integration momentum.

Consequently, ϕ
(r)
∘f and all its required ambient momentum derivatives are bounded on the same compact domain. A cutoff equal to one on that domain can make this an ordinary compactly supported test function without changing the integral.

Suppose the existing certificate establishes convergence using a common integrable bound for the relevant finite particle-mass derivative orders, schematically

∣T
ν,σ,η
	​

[W]∣≤C(D,x)∥W∥
C
q
	​

,

together with the dominated η→0 limit, independently of the ordinary prescription signs. Then replacing W by

W=
(n−1)!
(−1)
n−1
J
1−n
	​

ϕ
(n−1)
∘f

uses the same domination proof. It changes the test-function seminorm being bounded, not the ordinary denominator zero set.

This is precisely a pushforward of the existing compactly supported phase-space distribution, followed by a z-derivative. Convergence of distributions is defined through their action on test functions, which is why this argument does not require first constructing a regular density on every measurement slice. 
DLMF

The conclusion is

M
ν,n
(+i0)
	​

=M
ν,n
(−i0)
	​

in D
′
(R
z
	​

),
	​


for the prescribed finite cut orders and fixed generic x, initially in the common convergence domain and then by the same meromorphic continuation.

This proof does not remove the measurement from the integral definition or from IBP. It removes it only after pairing with a test function inside the proof.

1.3 The gap to inspect in the existing certificate

The parent theorem must control smooth insertions, not just establish an unweighted scalar equality for W=1.

For unit particle cuts, multiplying an absolutely dominated integrand by a bounded insertion is straightforward. For dotted particle cuts, boundedness of the insertion alone is insufficient: the relevant normal derivatives can act on it.

Let

α
i
	​

=ν
i
	​

−1

be the particle-mass derivative orders. In a mass-dependent parameterization,

∂
μ
α
	​

[ϕ
(n−1)
(f(k(μ,u)))]

contains derivatives of ϕ and derivatives of the parameterization. The latter can have soft-boundary singularities even though f is smooth in ambient momentum coordinates.

The appropriate audit is therefore:

Does the existing mass-derivative bound already bound the normal differential operators acting on an arbitrary smooth ambient insertion?

If yes, the extension is immediate. If the implementation specialized that argument to a constant numerator, generalize that part of the same estimate, including its existing Gram-power losses. Do not assert that all mass-coordinate derivatives are bounded merely because ϕ is smooth.

Once this is done, raising the measurement order mainly increases the required test-function differentiability. It does not itself add particle-mass derivatives or ordinary poles. Explicit z-dependent denominators in (3) are the exception because their differentiation changes the ordinary pole budget.

Equality must hold on an open common domain in D, not just at several sufficiently large integer dimensions, before invoking meromorphic continuation.

1.4 Distributional versus pointwise scope

Choose

ϕ∈C
c
∞
	​

(R)

or smooth test functions defined on a neighborhood of [0,1]. This tests the entire measured distribution, including possible endpoint-supported terms after continuation.

Using only C
c
∞
	​

((0,1)) would establish equality in the open interval but leave possible differences supported at z=0,1 undetected.

No submersion theorem is needed for the distributional pushforward itself. Critical values of f can produce singular distributions, but do not invalidate its definition on compact support.

Pointwise claims are separate:

If the two continued results are represented by continuous functions on a regular open z-chamber, their distributional equality implies equality of those functions there.

Pointwise convergence of M
η
	​

(z), or differentiation under a fixed-z integral, requires corresponding local fiberwise bounds.

A regular slice in the smooth phase-space interior does not automatically provide those bounds at soft/collinear boundary strata.

Thus the extension can certify distributional i0-independence first, without making pointwise convergence a prerequisite or an automatic conclusion.

1.5 What remains at the x endpoints

The statement is fixed-x. At fixed Q
2
,

S=Q
2
x
1−x
	​

,J=
x
Q
2
	​

.

As x→1, the available phase space and allowed positive mass-deformation neighborhood collapse with S. As x→0, the same unscaled phase-space domain is no longer uniformly compact. The constants in the existing bounds can therefore become singular.

A proof for every interior x does not exclude a difference such as

δ(1−x)A(z).

Before discarding prescriptions in an object that will be extended distributionally through an x endpoint, you still need either a joint test-function bound there or an endpoint analysis that establishes the same continuation. Rescaling momenta and mass increments with S may make that analysis efficient, but it is not supplied by the present argument.

1.6 The subset lemma is a valid zero-containment witness

Your sign lemma can enter the existing certificate exactly as proposed.

For a nonzero subset K, equality in

(p−K)
2
≤0

under J>S requires K to be null and parallel to p. Since K is a linear combination of P,k
1
	​

,k
2
	​

, this yields linear dependence among

p, P, k
1
	​

, k
2
	​

.

Hence the full Gram determinant vanishes. The same reasoning uses future causality rather than masslessness, so it survives the allowed nonnegative mass increments.

Exclude identically vanishing “ordinary denominators” from this classification. The lemma supplies zero containment, not an integrability exponent, a uniform limit, or an independent approval flag.

2. The three-variable geometry is correct

Let

u=
S
s
23
	​

	​

=(1−z)t,K=k
2
	​

+k
3
	​

,K
2
=uS.

The factorization

dΦ
3
	​

=
2π
dK
2
	​

dΦ
2
	​

(P;k
1
	​

,K)dΦ
2
	​

(K;k
2
	​

,k
3
	​

)

provides a direct derivation.

2.1 Reconstruction of the scalar products

In the K rest frame, let θ
1
	​

 be the angle between p and k
1
	​

, and θ
2
	​

 the angle between p and k
2
	​

. The fixed tag gives

cosθ
1
	​

=
1−(1−z)t
1−(1+z)t
	​

,sinθ
1
	​

=
1−(1−z)t
2
zt(1−t)
	​

	​

.

Your second fraction variable is

p⋅K
p⋅k
2
	​

	​

=y,

so

cosθ
2
	​

=1−2y,sinθ
2
	​

=2
y(1−y)
	​

.

Let c=1−2a be the cosine of the relative transverse angle. Then

cosθ
12
	​

=cosθ
1
	​

cosθ
2
	​

+sinθ
1
	​

sinθ
2
	​

c.

Using the two-body energies in the K rest frame gives

S
s
12
	​

	​

=y+zt−(1+z)ty−2
zt(1−t)y(1−y)
	​

c,
	​


exactly as stated.

The fraction assignments

J
2p⋅k
i
	​

	​

={z,(1−z)y,(1−z)(1−y)}

and

2P⋅k
i
	​

=s
ij
	​

+s
ik
	​


then reconstruct the complete scalar-product data.

There is a useful positivity representation. Define

A=(1−t)y,B=zt(1−y).

Then

S
s
12
	​

	​

=(
A
	​

−
B
	​

)
2
+4a
AB
	​

.
	​

(4)

Similarly, with

C=(1−t)(1−y),E=zty,
S
s
13
	​

	​

=(
C
	​

−
E
	​

)
2
+4(1−a)
CE
	​

.
	​

(5)

Together with

s
23
	​

=S(1−z)t,

these establish positivity throughout the open cube and describe the pair-collinear boundary loci.

2.2 The independent beta densities follow from the recursion

Define the fully integrated massless two-body volume

Φ
2
	​

(S)=
8π
(4π)
ϵ
	​

S
−ϵ
Γ(2−2ϵ)
Γ(1−ϵ)
	​

.

Also define normalized symmetric beta densities

b
α
	​

(v)=
B(α,α)
v
α−1
(1−v)
α−1
	​

,

with

α=1−ϵ,β=
2
1
	​

−ϵ.

Eliminating the first decay’s measured polar variable gives the Jacobian 1/(1−u). After combining it with the first two-body measure and setting u=(1−z)t, the residual u-dependence is

u
−ϵ
(1−z−u)
−ϵ
du=(1−z)
1−2ϵ
[t(1−t)]
−ϵ
dt.

The second polar angle gives b
α
	​

(y). The relative transverse angle gives b
β
	​

(a).

Consequently, for a full-D scalar integrand F,

	​

∫dΦ
3
	​

δ(z−
J
2p⋅k
1
	​

	​

)F
=V
3
	​

(z)∫
0
1
	​

dtdydab
α
	​

(t)b
α
	​

(y)b
β
	​

(a)F(s
ij
	​

(t,y,a),p⋅k
i
	​

(t,y,a)),
	​

	​

(6)

where

V
3
	​

(z)=
2π
S
	​

Φ
2
	​

(S)
2
z
−ϵ
(1−z)
1−2ϵ
.
	​

(7)

The beta normalization uses the ordinary Euler beta integral and its meromorphic continuation. 
DLMF

Integrating over the measured fraction gives

Φ
3
	​

(S)=
128π
3
(4π)
2ϵ
	​

S
1−2ϵ
Γ(2−2ϵ)Γ(3−3ϵ)
Γ(1−ϵ)
3
	​

.
	​


At ϵ=0,

V
3
	​

(z)=
128π
3
S
	​

(1−z),Φ
3
	​

(S)=
256π
3
S
	​

.

Here Φ
2
	​

(S) must mean the integrated two-body volume. Using the prefactor of its differential polar density would miss beta-function factors.

2.3 No missing azimuthal factor

At D=4, a has the arcsine density

b
1/2
	​

(a)=
π
a(1−a)
	​

1
	​

.

Equivalently,

c=1−2a,dμ(c)=
π
1−c
2
	​

dc
	​

,−1<c<1.

This already includes the two angular orientations having the same cosine. There is no extra factor two or 2π.

More generally,

⟨c
2
⟩=
2β+1
1
	​

=
D−2
1
	​

,

as in your check.

The branches in (4)–(6) are the positive real square roots on the open cube. For real ϵ<1/2, all three beta densities define positive normalized measures. For complex D, or outside the elementary integrability range, equation (6) is an analytically continued integral representation, not a probability interpretation.

2.4 The full Gram determinant agrees

Let

T
ij
	​

=k
i⊥
	​

⋅k
j⊥
	​

,

where the perpendicular complement is taken relative to span{p,P}. Since

detG(p,P)=−
4
J
2
	​

,

the block Gram identity gives

detG(p,P,k
1
	​

,k
2
	​

)=−
4
J
2
	​

detT.

Your scalar products yield

detT=4S
2
z(1−z)
2
t(1−t)y(1−y)a(1−a).

Thus

detG(p,P,k
1
	​

,k
2
	​

)=−J
2
S
2
z(1−z)
2
t(1−t)y(1−y)a(1−a).
	​


I independently checked this determinant directly from the supplied scalar products.

2.5 Scope after joint evanescent averaging

Equation (6) is a valid representation once the integrand depends only on full-D scalar products.

The preceding joint evanescent average is normalized at fixed full Gram data. It does not remove the relative-angle integration represented by a: a parametrizes remaining full scalar-product data, not the absolute orientation of the evanescent subspace. Therefore the two operations do not double-count an angular volume.

Do not redefine the physical four-dimensional subspace in the K rest frame before the joint average. K generally has a hatted component in the original BMHV split. After scalarization, the full-D Lorentz transformation used in the recursion is legitimate.

A residual oriented Levi-Civita scalar is outside this scalar-product-only interface. Its handedness has been integrated out by the cosine representation. Such a term must either have been eliminated exactly or shown to integrate to zero by a separate symmetry argument.

3. Gauss–Jacobi quadrature is an appropriate first direct check

For real negative ϵ in a proven convergence region, normalized tensor-product Gauss–Jacobi quadrature is well matched to (6). It incorporates the three measure endpoint weights exactly and leaves only the scalar integrand to evaluate. Gaussian quadrature has positive weights in this setting and is exact for polynomials through the corresponding degree. 
DLMF

Use Jacobi exponents

(−ϵ,−ϵ)

for t,y, and

(−
2
1
	​

−ϵ,−
2
1
	​

−ϵ)

for a. Normalize each one-dimensional weight set to sum to one. Then the constant-integrand test returns V
3
	​

(z) directly.

For speed, compute the invariant table once per product node and evaluate a vector of master integrands there. The t and y rules are identical and can share nodes and weights.

The main numerical limitation is correlated boundary singularities

The beta weights absorb the measure singularities, not every ordinary denominator singularity.

For example, equation (4) shows that

s
12
	​

=0

occurs at

a=0,(1−t)y=zt(1−y).

The singularity lies on a correlated locus within the face a=0, not necessarily at an independent t or y endpoint.

Thus a product rule can converge slowly even when sufficiently negative ϵ makes the integral convergent. Agreement at one order does not certify the value. Refine the directions independently, and use a local variable change, subtraction, or sector decomposition when these correlated regions dominate.

This is consistent with using direct radial/angular integration as an independent route to the same measured SIDIS integrals; it need not replace your IBP/DE production route. 
arXiv

Do not infer i0-independence from quadrature stability. Either use the existing certificate as extended above or retain the prescriptions in the numerical definition.

Dotted cuts and boundary seeds

The massless chart is not an off-shell extension for particle-mass derivatives. To evaluate dotted particle cuts, differentiate a correctly defined mass-deformed integral or use a justified analytic reduction to evaluable objects. Do not differentiate the massless scalar-product table after setting k
i
2
	​

=0.

Raised measurement cuts are simpler: equation (2) can be used when its explicit-z condition holds. Differentiating the fixed-cube representation then acts on both V
3
	​

(z) and every z-dependent invariant in F. It does not act only on the prefactor.

A converged quadrature value is suitable as a numerical check or as boundary data for numerical transport at that fixed regulator. It is not, by itself, an exact analytic boundary constant or a determination of the Laurent series at ϵ=0. For exact production, retain the derived boundary integral and perform its analytic continuation/region expansion before extracting the required coefficients. Do not obtain an endpoint seed by setting z=1 inside the integrand before establishing the limit.

4. Minimal implementation that preserves the contract

The measured extension needs two separate derivative budgets in the existing certificate:

Data	Meaning
Particle-cut orders ν
i
	​

	Independent mass derivatives α
i
	​

=ν
i
	​

−1, with the original normal and energy definitions
Measurement-cut order n	Test-function derivative order n−1, coefficient (−1)
n−1
J
1−n
/(n−1)!
Ordinary denominator powers	Include increases caused by any explicit-z differentiation in (3)
Smooth-insertion bound	The ambient derivative order controlled by the parent mass-derivative argument
External scope	Fixed generic x, with equality as a z-distribution; no implicit x-endpoint claim
Zero-containment witnesses	The same mass-deformed full Gram boundary, including the subset lemma where applicable

The particle-count test should count particle cuts, not all mandatory slots:

#{particle cuts}=L
phase
	​

+1.

Keep the compact-domain hypothesis unchanged, including the absence of additional unconstrained virtual-loop integrations. A linear measurement is neither another particle cut nor an additional mass-deformation variable.

The proof adapter should return a smooth test-function insertion and the corresponding derivative requirements to the current certificate. It should not mutate the typed family or remove its measurement slot.

Three inexpensive additions would exercise the remaining gaps:

Raised-measurement sign and endpoint tests. With test functions equal to 1,z,z
2
 on a neighborhood of [0,1],

⟨M
2
	​

,1⟩=0,⟨M
2
	​

,z⟩=−
J
1
	​

⟨M
1
	​

,1⟩,⟨M
3
	​

,z
2
⟩=
J
2
1
	​

⟨M
1
	​

,1⟩.

Run these first in a convergence region with adequate endpoint suppression, then as identities of the continued distributions.

A second-moment geometry regression. Your first moments do not fully constrain the relative-angle weight. With α=1−ϵ, the proposed geometry gives

S
2
⟨s
12
2
	​

⟩
	​

=
4(2α+1)
2
(α+1)[α(1+z)
2
+1+z
2
]
	​

.
	​


At D=4, this is

9
1+z+z
2
	​

.

This tests the square-root cross term and its angular second moment together.

A deformed smooth-insertion test. Apply the existing particle-mass derivative machinery to a simple integral with a nonconstant insertion ϕ(f), rather than testing only the volume. This directly exercises the part of the parent estimate that the measured extension needs.

Recommendation: implement the test-function adapter and smooth-insertion audit inside the one convergence certificate, and register the three-variable map as an independent scalar integration geometry. The former establishes the allowed ordinary-i0 limit as a z-distribution at fixed x; the latter evaluates the resulting scalar integrals and checks boundary constructions. Neither should silently broaden the other’s scope.