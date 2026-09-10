# Hermitian interference and causal prescriptions

Model: gpt-6-pro; request HTTP status: 200.

Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Question

User asks (1) why not compute only triangular n(n+1)/2 diagram interferences, and (2) what justifies removing i0. The code still computes the full grid; this turn is an explanation/audit, not a claim of implemented triangular scheduling. Hermitian physical density gives H_ji=conj(H_ij), diagonal+2Re offdiagonal, even with original causal prescriptions kept. Must conjugate at amplitude/physical-integrand level or include conjugation of virtual prescriptions, loop momentum labels and normalized-master phases, rather than blindly conjugating GLI symbols. Tree/tree grid has 36^2=1296 ->666; virtual/tree rectangular grids are separate. Any caveat to this statement?

On i0: we already agree that an open absolute-convergence regulator domain plus meromorphic continuation is sufficient, and fixed sign alone isn't. Here is a potentially stronger proof for the CURRENT massless real-radiation route. Please challenge it, especially dotted cuts, fixed observed momentum and dimensional continuation.

Assume only compact final-state phase space at fixed timelike total momentum, fixed generic observed momentum, no virtual loops, integer ordinary propagator powers, polynomial numerators. All ordinary inverse denominators satisfy the fixed-sign theorem, so zeros occur only on soft/beam-collinear/final-collinear boundary loci. Before dotted cuts, parameterize the future-null phase space in invariant Gram variables in integer D sufficiently large. Let G>=0 be the Gram determinant (or product of relevant Gram/minor and energy-boundary polynomials) on a compact semialgebraic domain K. The analytic-D phase-space weight contains G^(c D + b), c>0 (more generally a product with positive coefficients of D). At generic fixed observed momenta the external Gram is nonzero. The invariant domain is D-independent once D is sufficiently large. Rank deficiency from any soft/collinear configuration forces a Gram determinant to vanish. Thus zero sets of every allowed denominator Q_j are contained in {G=0}. A semialgebraic Lojasiewicz inequality gives G^N <= C |prod Q_j^nu_j|, so inverse denominator growth is controlled by a finite negative Gram power. Increasing Re D (negative Re epsilon) then makes the whole term absolutely integrable. This would prove existence of a common convergence half-plane for any finite collection of admitted undotted real-radiation rational terms, without running sector decomposition for each family.

For dotted cuts one might need a separate finite-order distribution argument: derivatives of the off-shell cut constraints produce finitely many rational/singular weight terms and can be made legitimate in a higher-D convergence domain. But signs are only proved on the massless surface; cannot assume a uniform bound in a mass deformation. Is the undotted result sound, and can dotted cuts be justified by meromorphic IBP/recurrence transport from undotted integrals instead, provided there are no unaccounted surface terms? Please identify any actual gap rather than granting this automatically.

Toy illustration for explanation: lim_eta->0 integral_0^1 x^(-epsilon)/(x +/- i eta) dx = -1/epsilon for Re epsilon<0 by dominated convergence. Identical meromorphic continuations to epsilon~0. Expanding epsilon first at the divergent endpoint is not valid. Negative noninteger powers/logarithms and virtual thresholds retain their phases; no blanket i0 removal for AMFlow deformations.

Useful primary phase-space parametrization source: https://arxiv.org/pdf/0803.4177 section4 (eq38 has positive D coefficients in endpoint weights), and https://arxiv.org/pdf/hep-ph/0311276 . Answer narrowly: what can we claim now to the user, and which extra hypothesis is needed for a general proof?


## Pro response

The triangular-interference statement is correct and does not depend on removing i0. The undotted high-D argument is also sound once the Gram factor is identified in the actual beam-aware, measurement-constrained phase-space measure. The gaps are using an unspecified Gram determinant, inferring endpoint-distribution equality from fixed generic observed momentum, and treating dotted-cut IBP validity as automatic.

1. Triangular interferences: valid independently of the prescription argument

With amplitudes M
i
	​

 and a common Hermitian spin/color/measurement operator W, define

H
ij
	​

=M
j
†
	​

WM
i
	​

.

Then

H
ji
	​

=H
ij
∗
	​

,
i,j
∑
	​

H
ij
	​

=
i
∑
	​

H
ii
	​

+2Re
i<j
∑
	​

H
ij
	​

.

This requires Hermiticity, not positivity: it applies to UU and to Hermitian LL/TT spin-difference projectors.

Thus the 36×36 tree/tree grid can be represented by 36⋅37/2=666 evaluations. According to your description, that scheduling is not yet implemented. There is no mathematical reason to wait for an i0-removal theorem before implementing it.

The qualifications are:

Use the same external-state labeling and measurement on both sides. Conjugation exchanges the amplitude and conjugate amplitude, including complex couplings, virtual prescriptions, loop-variable labels, and normalization phases. It does not assert that an abstract GLI is real. Nor is multiplying every off-diagonal contribution by two equivalent to taking 2Re.

A virtual/tree rectangle is not triangular. Nevertheless, one can compute one oriented rectangle and obtain the reverse rectangle by conjugation, rather than computing both and then applying another factor of two.

For complex D, use Schwarz reflection, not a nonholomorphic real-part operation. The continued identity is

H
ji
	​

(D)=
H
ij
	​

(
D
)
	​


at real physical external kinematics, with the prescribed branch conjugation. At the Laurent-coefficient level this reduces to the expected conjugation. Literal Re of a symbolic complex-D function is not the appropriate analytic operation.

2. Undotted convergence: the Łojasiewicz step works; the choice of Gram factor matters

Your inequality has the correct direction. On a compact semialgebraic set, for continuous semialgebraic f,G,

Z(f)⊆Z(G)⟹G
N
≤C∣f∣

for some finite N, taking G≥0. Here

f=
j
∏
	​

Q
j
ν
j
	​

	​

.

This is precisely the applicable semialgebraic Łojasiewicz statement. 
Cambridge University Press

A concrete gap: a final-state Gram need not detect beam collinearity

For two final particles,

detGram(p
1
	​

,p
2
	​

)=−(p
1
	​

⋅p
2
	​

)
2
=−
4
s
2
	​

,

including at p
1
	​

=k
a
	​

, p
2
	​

=k
b
	​

, where k
a
	​

⋅p
1
	​

=0. Therefore beam collinearity does not imply that a Gram determinant built only from final particles vanishes.

The same problem persists with fixed observed momentum: a residual two-body phase space can have one particle parallel to a beam while its two-particle Gram remains nonzero. Conversely, putting every incoming and outgoing vector into one Gram matrix makes it identically singular by momentum conservation.

A suitable construction is instead to choose an independent external frame spanning k
a
	​

,k
b
	​

,p
c
	​

, of dimension E, and L independent unobserved momenta after eliminating the remaining recoil. Project those momenta orthogonally to the external frame and use

G=det[−ℓ
i
⊥
	​

⋅ℓ
j
⊥
	​

]
i,j=1
L
	​

.

Because the external frame contains a timelike vector, its orthogonal complement is Euclidean. In sufficiently large integer dimension, G≥0 and is generically nonzero.

For this construction, a soft momentum, a beam/observed-collinear momentum, or two mutually collinear unobserved momenta produce a nontrivial linear relation among the transverse vectors. The eliminated recoil causes no exception: its transverse part is minus their sum. Thus these loci do imply G=0.

The scalar-product/Baikov Jacobian carries the exponent

G
(D−E−L−1)/2
,

up to external factors and the cut-coordinate Jacobian. The positive-semidefinite conditions on the transverse Gram matrix must also be retained; G≥0 alone does not describe the domain for arbitrary L. 
arXiv
+1

The resulting convergence proof

Choose a sufficiently large reference dimension D
0
	​

, with finite positive phase-space measure dμ
D
0
	​

	​

. After normalizing G by a fixed scale, the needed relation is

dμ
D
	​

=C(D,X)G
(D−D
0
	​

)/2
dμ
D
0
	​

	​

.

A finite-chart version, or a product of genuinely D-weighted boundary factors, works as well.

Since the polynomial numerator is bounded on the compact domain,

	​

∏
j
	​

Q
j
ν
j
	​

	​

N
	​

	​

≤C
′
G
−N
∗
	​


away from the measure-zero zero locus. Consequently,

	​

∏
j
	​

Q
j
ν
j
	​

	​

N
	​

dμ
D
	​

	​

≤C
′′
(D,X)G
(ReD−D
0
	​

)/2−N
∗
	​

dμ
D
0
	​

	​

.

For sufficiently large ReD, the extra factor is bounded. This proves absolute convergence. Taking the largest required N
∗
	​

 gives a common half-plane for any fixed finite collection, including arbitrary but finitely bounded ordinary propagator powers.

One cannot simply append boundary polynomials to G. They must actually receive positive-D suppression from the measure, or have a separately controlled integrable weight. Otherwise the inequality may be true but irrelevant to convergence.

Heinrich’s Eq. (38) and the four-particle formulas in hep-ph/0311276 explicitly exhibit the required positive-D endpoint powers for their parametrizations. They support this mechanism, but their decay measures alone do not establish the beam-sensitive, fixed-observed version. 
arXiv
+1

Dimensional continuation must be defined on an open domain

Agreement at all sufficiently large integer dimensions is not itself a uniqueness proof for meromorphic continuation. The explicit Gram-power representation must define the integral for complex D in an open convergence half-plane; equality is established there and then continued.

Do not impose four-dimensional Gram identities before that continuation. A Gram determinant that is nonzero at large D can become rank-constrained at integer D=4; the dimension-dependent angular normalization and distributional continuation account for this.

3. Fixed observed momentum does not yet prove equality of the full distribution

For the fixed-observed argument, require not only a nonsingular external Gram but also

Q
rec
	​

=k
a
	​

+k
b
	​

−p
c
	​

,Q
rec
2
	​

>0,

and a nondegenerate residual phase-space domain. A nonzero external Gram does not exclude Q
rec
2
	​

=0, the observed endpoint where the residual massless system becomes collinear.

Equality at every generic p
c
	​

 cannot determine a term supported at that endpoint, such as δ(1−w).

To claim equality of the full single-inclusive distribution, pair with a smooth bounded test function of the observed variables before applying the high-D convergence argument. The clean construction includes p
c
	​

 among the integrated final momenta and uses the fixed beams as the external frame. Then the observed endpoint is part of the compact integration domain, rather than an omitted exceptional slice.

This is an extension of the same geometric proof, not a demand for a separate sector decomposition of each family. But it is necessary before claiming that no prescription-dependent endpoint contact term remains.

Once that common dominating integral exists,

∣Q
j
	​

+iσ
j
	​

η∣
−ν
j
	​

≤∣Q
j
	​

∣
−ν
j
	​


for integer ν
j
	​

>0. Dominated convergence then gives prescription independence throughout the convergence domain.

Your toy example is exactly correct:

η↓0
lim
	​

∫
0
1
	​

x±iη
x
−ϵ
	​

dx=∫
0
1
	​

x
−1−ϵ
dx=−
ϵ
1
	​

,Reϵ<0.

The common meromorphic continuation follows afterward, not from expanding first at the divergent endpoint.

4. Dotted cuts: transport is possible, but must not be circular

An undotted cut samples the restriction of a function to the mass shell; a dotted cut samples its normal derivatives:

⟨δ
′
(u),f(u)⟩=−f
′
(0).

Knowing the undotted value alone does not determine the dotted value. This is why replacing off-shell polynomials by equalities valid only on the cut surface is insufficient.

A promising direct extension is to keep the ordinary η regulators finite, apply the finite number of normal derivatives in regular cut coordinates, and only then restrict to the massless surface. The resulting terms have higher ordinary denominator powers and finitely lowered Gram powers. If all these terms and boundary contributions satisfy the same high-D bounds, prescription independence follows without any uniform sign assumption under a mass deformation.

What must actually be established is finite-order regularity of this operation, including cut-coordinate Jacobians, moving Gram boundaries, and the positive-energy restrictions. Higher residues involve derivatives of the Baikov weight; the cut literature explicitly uses the Gram boundary to justify vanishing surface terms. 
arXiv

There is an additional reference caveat: the generalized contour cuts in Frellesvig–Papadopoulos are explicitly distinguished from physical cuts because they omit the positive-energy theta constraints. Their IBP statement cannot simply replace the corresponding argument for your oriented physical cuts. 
arXiv

Meromorphic IBP/recurrence transport is sufficient when it supplies an actual identity

J
dotted
(σ)
	​

(D,X)=
r
∑
	​

c
r
	​

(D,X)I
undotted,r
(σ)
	​

(D+2k
r
	​

,X)

for the same physical cut cycle and prescriptions, with all surface terms controlled and the dotted quantities uniquely determined. Then the established undotted prescription independence transfers.

But a formal Kira relation does not independently prove the absence of surface terms. Nor does a recurrence by itself determine a solution without boundary data. An integrable integrand also need not have a vanishing boundary flux: convergence and the IBP boundary condition are distinct obligations.

What can be claimed now

Triangular scheduling is an exact available optimization, independent of i0, but is not yet implemented in the described code.

For undotted real-radiation integrals, the proposed argument can establish a common convergence half-plane once per phase-space geometry, provided the actual analytic-D measure has a nontrivial Gram suppression factor covering every allowed denominator zero. The Łojasiewicz step then removes the need for family-by-family convergence analysis.

Dotted cuts and the full observed-endpoint distribution require the extensions above. Until those are established, claim prescription independence only for the certified undotted domain—not for arbitrary dotted masters, auxiliary-mass deformations, virtual thresholds, or noninteger powers and their phases.