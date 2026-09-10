# Evanescent virtual-loop numerator averages

Verified outgoing model gpt-6-pro; standard thinking effort; HTTP 200.
Request: 98a67dea-7b00-4cc4-ba46-e44237373082.
Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.

## Question

Please review the new general evanescent-loop numerator treatment before I rely on it more broadly.

Generated SIDIS one-loop vector-current interference for LL contains ell_bar^2 as well as ell_D^2 and ell.p, ell.q. FeynCalc TID with the mixed 4D/D scalar numerator produced a spurious Gram 0/0 after on-shell kinematics. I did not replace ell_bar^2 by ell_D^2. Instead the new helper first uses the declared physical external basis p,q (p^2=0,q^2=-Q2,p.q=Q2/2); their 2x2 Gram matrix is nondegenerate. Let r be its rank, ell_parallel^2 = (ell.p_i) G^{-1}_{ij} (ell.p_j), and ell_perp^2=ell_D^2-ell_parallel^2. Set ell_bar^2=ell_D^2-kappa, then average every polynomial kappa^a linearly using
<kappa^a> = ((D-4)/2)_a / ((D-r)/2)_a * (ell_perp^2)^a.
All propagators are ordinary full-D massless quadratic denominators with shifts in the physical span p,q, so their transverse dependence is rotationally invariant. The entire scalar numerator is averaged before TID. Residual unsupported four-dimensional loop objects or nonpolynomial kappa denominators fail. No loop momentum is set to four dimensions. For r=2,a=1 this reproduces (D-4)/(D-2) ell_perp^2. The resulting generated UU and LL virtual coefficient vectors agree exactly through epsilon^1, including the familiar -2/eps^2-3/eps quark form-factor poles, without importing a form factor.

The exact scalar evaluator now derives arbitrary-power bubbles and single-off-shell massless triangles from the Dirichlet parameter integral, with normalization d^D ell/(i pi^(D/2)); FeynCalc B0/C0 carry 1/(i pi^2), so the adapter multiplies them by pi^(-eps). The FeynArts loop conversion already retained (2pi)^(-D), and the conjugate one-loop term is included only after integration via A B* + conjugate(A B*). Born delta support and its Jacobian are derived once from the measurement card and reused by virtual.

Please challenge the averaging identity and its domain, particularly timelike/spacelike physical spans, cut vs virtual contours, arbitrary numerator powers and any BMHV scheme caveat. Also check whether all-order exact-D equality of the electromagnetic vector form factor between the g1 projection and transverse unpolarized projection is indeed expected with physical external p,q, although the current tensor indices are D-dimensional. Any missing finite renormalization belongs in the separate universal helicity PDF scheme conversion, not in this generated virtual amplitude. We have not claimed complete NLO or NNLO SIDIS yet.


## Pro response

The averaging identity is correct for the stated one-loop virtual problem, and the π
−ϵ
 adapter is correct in the direction you describe. The main qualification is that transverse invariance must hold for everything multiplying κ
a
, not just the propagators. Your scalar SIDIS virtual numerator satisfies that condition as described; a numerator containing another transverse direction, a degenerate external span, or a loop attached to D-dimensional real-emission momenta need not.

Exact-D equality between the transverse UU and g
1
	​

 purely virtual coefficient corrections, with your normalized Born projectors, is expected. It follows from the vector amplitude’s Lorentz structure, not from discarding evanescent terms or applying an axial-current renormalization.

1. The identity is an exact tensor-integration identity

Let S be a nondegenerate physical subspace with basis p
i
	​

, i=1,…,r, and define

G
ij
	​

=p
i
	​

⋅p
j
	​

,Π
∥
μν
	​

=p
i
μ
	​

(G
−1
)
ij
	​

p
j
ν
	​

,Π
⊥
μν
	​

=g
D
μν
	​

−Π
∥
μν
	​

.

Then

trΠ
⊥
	​

=D−r,
g
^
	​

Π
∥
	​

=0,
g
^
	​

Π
⊥
	​

=
g
^
	​

.

This is the standard decomposition underlying transverse integration identities; the inverse Gram matrix requires a nondegenerate subspace. 
arXiv

Write

d=D−r,m=D−4,κ=
ℓ
^
2
,ℓ
⊥
2
	​

=ℓ
D
2
	​

−ℓ
∥
2
	​

.

For an invariant weight F, the even-rank transverse tensor integral has the form

	​

∫d
D
ℓℓ
⊥
μ
1
	​

	​

⋯ℓ
⊥
μ
2a
	​

	​

F
=
d(d+2)⋯(d+2a−2)
∫d
D
ℓ(ℓ
⊥
2
	​

)
a
F
	​

pairings
∑
	​

Π
⊥
μ
i
1
	​

	​

μ
i
2
	​

	​

	​

⋯Π
⊥
μ
i
2a−1
	​

	​

μ
i
2a
	​

	​

	​

.
	​


Contracting the indices in pairs with 
g
^
	​

 produces

m(m+2)⋯(m+2a−2)

in the numerator. Therefore

∫d
D
ℓκ
a
F=
(d/2)
a
	​

(m/2)
a
	​

	​

∫d
D
ℓ(ℓ
⊥
2
	​

)
a
F.
	​


Thus your replacement is exact under the integral, including its dimensional continuation:

κ
a
⟼
∫
	​

((D−r)/2)
a
	​

((D−4)/2)
a
	​

	​

(ℓ
⊥
2
	​

)
a
.
	​


It is not a pointwise identity between numerator functions.

Your SIDIS Gram matrix is genuinely nondegenerate

At the virtual Born kinematics,

G=(
0
Q
2
/2
	​

Q
2
/2
−Q
2
	​

),detG=−
4
(Q
2
)
2
	​


=0.

Direct inversion gives

G
−1
=(
4/Q
2
2/Q
2
	​

2/Q
2
0
	​

),

and hence

ℓ
∥
2
	​

=
Q
2
4(ℓ⋅p)(ℓ⋅p+ℓ⋅q)
	​

=
Q
2
4(ℓ⋅p)(ℓ⋅k)
	​

,k=p+q.
	​


For r=2,

(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

=
⎩
⎨
⎧
	​

1,
−
a−ϵ
ϵ
	​

,
	​

a=0,
a≥1.
	​


In particular,

ℓ
ˉ
2
=ℓ
D
2
	​

−κ
⟼
∫
	​

D−2
2
	​

ℓ
D
2
	​

+
D−2
D−4
	​

ℓ
∥
2
	​

=
1−ϵ
ℓ
D
2
	​

−ϵℓ
∥
2
	​

	​

.
	​


This is different from 
ℓ
ˉ
2
↦ℓ
D
2
	​

, including precisely the regulator-suppressed terms that can multiply poles.

The nonzero determinant establishes that there is no unavoidable Gram singularity associated with the physical two-vector span. It does not independently identify the origin of the earlier TID 0/0: an overcomplete basis, mixed-dimensional intermediate representation, or a separately singular subtopology could still produce it. Removing mixed-dimensional scalar numerators before ordinary tensor reduction is nevertheless a mathematically justified treatment, rather than a workaround that changes the integral.

Arbitrary polynomial powers are allowed

For fixed nonnegative integer a, the identity holds at arbitrary numerator rank. But

⟨κ
a
⟩

=⟨κ⟩
a
.

Your decision to average the entire polynomial linearly is essential.

For r<4, every positive-power moment is generically O(ϵ), not O(ϵ
a
). At r=2,

(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

=−
a
ϵ
	​

+O(ϵ
2
).

High powers must therefore not be discarded by counting one power of ϵ for each κ.

There is a useful exception: for r=4, the entire perpendicular space is evanescent, so

κ=ℓ
⊥
2
	​

,
((D−4)/2)
a
	​

((D−4)/2)
a
	​

	​

=1.

Simplify that identity before taking D→4; it is not a physical 0/0.

2. The domain needs stronger conditions than invariant denominators alone
All residual numerator directions must be accounted for

Your present numerator coefficients depend on

ℓ
D
2
	​

,ℓ⋅p,ℓ⋅q,

which are invariant under transformations in S
⊥
. That is sufficient.

However, suppose an additional physical vector a
⊥
	​

, orthogonal to S, remains in the numerator:

κ(ℓ⋅a
⊥
	​

)
2
.

Even with exactly the same invariant denominators, averaging κ while leaving the second factor untouched is wrong. The correct rank-four identity gives

⟨κ(ℓ⋅a
⊥
	​

)
2
⟩=
d(d+2)
ma
⊥
2
	​

	​

(ℓ
⊥
2
	​

)
2
.
	​


A premature scalar replacement of κ, followed by averaging the remaining quadratic factor, would instead give

d
2
ma
⊥
2
	​

	​

(ℓ
⊥
2
	​

)
2
.

Thus the acceptance condition should be:

After reducing barred products, the numerator is polynomial in κ, and every coefficient of that polynomial is transverse-invariant with respect to the declared span.

A surviving full-D product ℓ⋅a can violate this condition just as a surviving four-dimensional product can. Checking only for unsupported barred objects is insufficient in the general helper. Either include the relevant physical direction in a nondegenerate span or use a tensor moment that retains its correlations.

Timelike versus spacelike spans

A span containing a timelike direction. Its orthogonal complement is spacelike. At integer D>4, the rule has an ordinary Euclidean angular derivation, followed by dimensional continuation. Your SIDIS span is of this type: its Gram matrix has one positive and one negative eigenvalue.

With the mostly-minus metric, ℓ
⊥
2
	​

 and 
ℓ
^
2
 are signed Minkowski squares. Do not insert additional factors of (−1)
a
 into the displayed ratio: those signs are already present in (ℓ
⊥
2
	​

)
a
. Apparent violations of positivity after continuation to D<4 are not a reason to change the formula.

A purely spacelike span. Its orthogonal complement contains a timelike direction. There is then no normalized compact real “angular average” on that complement. Nevertheless, the same formula holds for ordinary Feynman integrals as a Lorentz-covariant tensor-integration identity, established in a convergent analytically regulated region and continued with the Feynman prescription.

In this case, do not interpret ℓ
⊥
2
	​

 as an everywhere-negative radial coordinate or perform a real-sphere substitution directly on the Minkowski contour. The tensor identity, not a literal hyperbolic angular probability measure, is the justification.

A degenerate span. Here the stated construction fails. In particular, the span of one nonzero null vector has dimension one but a zero Gram matrix. Taking “r=rankG=0” does not make that external vector disappear. This exceptional case is explicitly excluded in the usual inverse-Gram transverse decomposition. 
arXiv

Consequently, r should mean the dimension of a nondegenerate declared subspace, not the rank used to silently discard null directions. Reject a degenerate declaration or construct an explicitly declared nondegenerate completion; do not use a pseudoinverse as an unproved substitute.

Virtual contours, cuts, and measurements

For the current same-side virtual integral, all ordinary propagators carry the same Feynman prescription. The identity applies before integration and remains valid under analytic continuation. The anti-Feynman result follows by conjugating the fully normalized result.

A cut extension needs a separate support check. It is valid when the cut constraints, energy orientation, and measurement preserve the transverse symmetry used in the proof. For a timelike physical span, one can choose a frame in which the perpendicular space is purely spatial; positive-energy conditions on momenta shifted within the span then do not depend on the transverse angles.

But a generic δ
+
	​

 prescription is not exhausted by writing a discontinuity of 1/(D
i
	​

±i0): the positive-energy restriction must also be preserved. Nor does a Euclidean proof automatically justify a mixed-prescription integral with additional pinches or an angularly restrictive measurement.

The major NNLO real–virtual limitation

In SIDIS real–virtual kinematics, the loop can have propagator shifts involving a tagged or recoil momentum k with

k
^

=0.

Then, for example,

(ℓ+k)
2

depends on 
ℓ
^
⋅
k
^
. Rotating 
ℓ
^
 while holding k fixed does not leave the denominator invariant.

This helper must not treat such a k as physical merely because it is external to the loop amplitude. The current physical-span rule should reject that input. A more general treatment must retain the additional evanescent invariants or perform the corresponding joint tensor integration.

Similarly, two-loop denominators involving (ℓ
1
	​

−ℓ
2
	​

)
2
 correlate the transverse loop directions. Independent one-vector averages are not a general multiloop rule.

3. Scalar-integral and conjugation normalization
The π
−ϵ
 conversion is correct

Define your scalar evaluator by

J
N
(D)
	​

=
iπ
D/2
1
	​

∫d
D
ℓ
∏
j
	​

D
j
ν
j
	​

	​

1
	​

.

FeynCalc’s scalar Passarino–Veltman objects use

PV
N
	​

=
iπ
2
1
	​

∫d
D
ℓ
∏
j
	​

D
j
ν
j
	​

	​

1
	​

,

as documented for its PaVe functions. 
FeynCalc

Therefore

PV
N
	​

=π
D/2−2
J
N
(D)
	​

=π
−ϵ
J
N
(D)
	​

.
	​


Thus the substitution

B
0
	​

⟼π
−ϵ
J
2
(D)
	​

,C
0
	​

⟼π
−ϵ
J
3
(D)
	​


is correct. The inverse conversion would contain π
+ϵ
.

With the already retained (2π)
−D
 and the iπ
2
 generated when an unnormalized loop integral is expressed through PaVe,

(2π)
−D
iπ
2
π
−ϵ
J
N
(D)
	​

=
(4π)
D/2
i
	​

J
N
(D)
	​

.
	​


There must be no second loop-measure conversion after this identity.

Also ensure that the scalar evaluator does not already include e
γ
E
	​

ϵ
, r
Γ
−1
	​

, or the coupling’s μ
R
2ϵ
	​

. FeynCalc explicitly distinguishes these alternative scalar-integral normalizations. 
FeynCalc

For your higher-order epsilon target, avoid PaVeLimitTo4: its documented purpose is an ϵ
0
-accurate simplification of suitable one-loop results, not preservation of exact-D coefficients. 
FeynCalc

Arbitrary-power Dirichlet evaluation is appropriate

For positive integer propagator powers, ν=∑
j
	​

ν
j
	​

, the normalized one-loop parameter representation is

J
N
(D)
	​

=
	​

∏
j
	​

Γ(ν
j
	​

)
(−1)
ν
Γ(ν−D/2)
	​

∫
α
j
	​

≥0
	​

[dα]δ(1−
j
∑
	​

α
j
	​

)
×
j
∏
	​

α
j
ν
j
	​

−1
	​

[F(α)−i0]
D/2−ν
,
	​


with, for massless denominators,

F(α)=−
i<j
∑
	​

α
i
	​

α
j
	​

(P
i
	​

−P
j
	​

)
2
.

For the single-off-shell triangle, this reduces to a single scale times a product of two parameters, so the remaining integrals are Dirichlet integrals. This is a derivation of the scalar integrals, not an imported hard amplitude.

The required guards are chiefly at the boundaries of that formula. Pinching a propagator, ν
j
	​

=0, should dispatch to the lower topology rather than naively substituting into factors containing Γ(ν
j
	​

). Negative indices require numerator treatment. Scaleless on-shell bubbles must be handled as scaleless integrals in the stated dimensional prescription, not as an ordinary numerical limit of a singular off-shell formula.

Arbitrary numerator powers can also remove a common convergence strip in D. Derivation with auxiliary analytic powers, followed by meromorphic continuation, is sufficient; an unjustified exchange of divergent ordinary integrals is not.

Conjugating after integration avoids the earlier measure ambiguity

Your procedure

A
(1)
A
(0)∗
+(A
(1)
A
(0)∗
)
∗

is correct once the current projection and index order have been fixed. It conjugates the loop normalization, generated phases, and scalar functions together.

In particular,

[∫
iπ
D/2
d
D
ℓ
	​

∏
j
	​

(D
j
	​

+i0)
ν
j
	​

1
	​

]
∗
=∫
−iπ
D/2
d
D
ℓ
	​

∏
j
	​

(D
j
	​

−i0)
ν
j
	​

1
	​

.

No additional “conjugate-loop minus sign” should be inserted after conjugating the complete integrated expression.

Keep the prescriptions during continuation: spacelike integrals are real after removing the conventional integration phase, whereas timelike functions require conjugation of their branch values, not merely a declaration that the invariant is real.

4. Exact-D UU–g
1
	​

 virtual equality is expected

The decisive fact is that the loop amplitude is a vector-current amplitude with no γ
5
	​

 in the vertex calculation. The massless two-quark vector-current matrix element has a single vector form factor; the polarized SIDIS literature likewise identifies its virtual g
1
	​

 contribution with the vector, not axial, form factor. 
arXiv
+1

For your kinematics, the integrated vertex satisfies, between on-shell spinors,

u
ˉ
(k)Γ
D
μ
	​

(p,k)u(p)=F
V
	​

(Q
2
,D)
u
ˉ
(k)γ
D
μ
	​

u(p).
	​


Equivalently, one can test the stronger spin-summed matrix identity

\slashedkΓ
D
μ
	​

\slashedp=F
V
	​

\slashedkγ
D
μ
	​

\slashedp.

The dimensional statement can be understood without assuming four-dimensional gamma identities. The vertex is constructed from p,k,g
D
	​

,γ
D
	​

, with only two independent external vectors. Terms proportional to p
μ
\slashedp, p
μ
\slashedk, and their k
μ
 counterparts vanish between the on-shell spinors. Odd higher gamma strings reduce to the same vector structure; antisymmetric strings requiring more independent vectors cannot furnish an additional structure. For example,

u
ˉ
(k)\slashedpγ
D
μ
	​

\slashedku(p)=−2p⋅k
u
ˉ
(k)γ
D
μ
	​

u(p).

There is no independent barred-versus-hatted vector form factor generated by this D-covariant vector vertex. The dimensional split appears when applying the external helicity projector, after the common scalar form factor can already be factored out.

Consequently,

w
U
	​

=∣F
V
	​

∣
2
w
U
(0)
	​

,w
Δ
	​

=∣F
V
	​

∣
2
w
Δ
(0)
	​

.

With your exact Born normalizations,

C
T,V
	​

=ΔC
V
	​

,C
L,V
	​

=0
	​


as exact functions of D for the purely virtual contribution. At one loop, both receive 2ReF
V
(1)
	​

; at two loops, both receive the same combination of the two-loop interference and one-loop square.

The D-dimensional current indices do not spoil this result. The UU dual divides by D−2, while the BMHV antisymmetric dual has its four-dimensional normalization; each extracts its own correctly normalized Born tensor multiplied by the same F
V
	​

.

Your equality through ϵ
1
 is therefore a substantive check. It is not yet an all-epsilon verification of the implementation. Since the relevant exact bubbles and triangles contain gamma functions differing by integer shifts, their recurrence relations should allow you to simplify the generated difference to zero before Laurent expansion. Use that as a test; do not impose equality as a production replacement.

What this equality does not say

It does not assert equality of full real-plus-virtual SIDIS coefficients, or of arbitrary factorization-scheme coefficient functions. It also does not equate vector and axial-current form factors.

The BMHV algebra must remain intact through the trace and angular reduction. In particular,

{γ
5
	​

,
γ
ˉ
	​

μ
}=0,[γ
5
	​

,
γ
^
	​

μ
]=0,

rather than anticommuting γ
5
	​

 through every D-dimensional gamma matrix. FeynCalc implements this split but does not automatically supply finite operator counterterms. 
FeynCalc
+1

For the electromagnetic vector current, there is no axial-current finite Z
5
	​

 to attach to the photon vertex. Ordinary coupling/field renormalization remains whatever your declared amplitude convention requires. The finite helicity-PDF transformation belongs separately in

Δf
H
=Z
H←B
	​

⊗Δf
B
,ΔC
H
=ΔC
B
⊗Z
H←B
−1
	​

.

The corresponding inverse transformation of the coefficient is the operator-factorization requirement, not a correction to the generated vector amplitude. 
arXiv

5. Acceptance checks that directly exercise the new helper

The most useful additional checks are mathematical identities that do not share the same numerator-averaging implementation.

Dimension-shift check. For scalar denominators shifted only by physical vectors, and your 1/(iπ
D/2
) normalization,

J
D
	​

[(
ℓ
^
2
)
a
]=(−1)
a
(
2
D−4
	​

)
a
	​

J
D+2a
	​

[1].
	​


Equivalently, for μ
ℓ
2
	​

=−
ℓ
^
2
,

J
D
	​

[(μ
ℓ
2
	​

)
a
]=(−ϵ)
a
	​

J
D+2a
	​

[1].

This follows independently by integrating the evanescent Gaussian after Feynman parametrization. Test several powers on an off-shell bubble and the triangle. In this check, only the scalar integration dimension shifts; do not shift the original Dirac algebra, BMHV physical dimension, or coupling normalization.

Basis and signature checks. The bases {p,q} and {p,k} must give the same result. A timelike and a spacelike off-shell bubble should satisfy the same tensor identity with their respective prescribed branches. Include the r=4 identity case and explicit rejection of a null degenerate span.

Whole-numerator and normalization checks. Include the correlated numerator κ(ℓ⋅a
⊥
	​

)
2
 as a rejection test unless its extra direction is handled. Separately verify the chain

(2π)
−D
×iπ
2
×π
−ϵ
=
(4π)
D/2
i
	​

.

UU–LL agreement alone cannot detect a normalization error common to both channels.

Finally, record the perturbative convention when checking the quoted poles. If

F
V
	​

=1+
4π
α
s
	​

	​

F
V
(1)
	​

+⋯,

the interference contains α
s
	​

/(2π)ReF
V
(1)
	​

. Thus the same pole numbers can appear in an α
s
	​

/(2π)-expanded coefficient; they would be doubled in an α
s
	​

/(4π)-expanded coefficient.

The described treatment is suitable as a general one-loop scalar transverse-integration rule on its declared domain. Its essential boundary is not “virtual versus real” by itself, but nondegeneracy of the physical span and transverse invariance of the complete integration weight. Preserve those conditions explicitly, particularly before applying it to real–virtual loops with integrated D-dimensional external momenta.
## Implementation follow-up

The scalar averaging helper now rejects unlisted full-D momentum directions
in both numerator and propagator shifts, not merely unresolved barred
products. Its declared nondegenerate external span may have dimension four;
the Pochhammer ratio then cancels identically. Generic cut/measurement and
mixed-prescription forms are rejected by this virtual-only caller. The
real–virtual extension with integrated D-dimensional external momenta remains
unimplemented and must preserve their additional evanescent invariants.
