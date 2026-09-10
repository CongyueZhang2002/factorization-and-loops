# GPT-6 Pro review 21

Verified model: gpt-6-pro.

## Question

Review21, continuing general first-principles NNLO SIDIS UU/LL framework https://github.com/CongyueZhang2002/factorization-and-loops (local changes newer). Review20 led to a substantial permanent fix: complete on-unit-cut rational cancellation by spectator color/dimension monomials. Both UU q-q gluon scalar densities cancel P.k2 exactly at generic D; transverse 12 sectors require ~11sec versus one Together timing out; after decomposition transverse targets88->18, longitudinal88->14. The unrestricted source definition and common prescription certificate remain unchanged. Cancellation now runs generally before family decomposition; four new exact behavioral assertions and ten existing preparation assertions pass. We preserve the old55 master solution.

Next nontrivial implementation is real-virtual gamma*q->qg and gamma*g->qqbar. We generate full one-loop x tree interferences with open electromagnetic current, exact-D physical unobserved states (at most one covariant), normalized collinear incoming UU or LL and outgoing unpolarized correlators. Current wavefunction and exactly one external e coupling are amputated; FeynArts measure is (2pi)^(-D) for virtual loop. RR already used joint orthogonal angular averaging with physical plane span{p,q} and integrated vectors{k1,k2}. For RV propose the SAME algebraic correlated average with integrated vectors{k1,ell}, k2=p+q-k1, preserving full D denominators, before loop tensor reduction. This removes all BMHV physical/evanescent scalar numerator distinctions while retaining dimension-dependent trace factors. Then FeynCalc TID on ell (three external D-dimensional vectors p,q,k1), giving massless bubbles, triangles with at most two offshell external legs, and one-offshell scalar boxes. Apply exact two-body measured phase space at z=2p.k1/J: all remaining invariant products fixed by x,z, only normalized volume remains. Thus no new phase-space integrals are needed for RV. Evaluate the universal scalar masters to whatever epsilon order the complete coefficient plus endpoint analysis requires; generic direct loop provider uses d^D ell/(i pi^(D/2)), FeynCalc B0/C0/D0 convention conversion pi^(-epsilon). Causal prescription is retained for virtual loop, unlike compact RR.

Please critically check:
1. Legitimacy of averaging BOTH ell,k1 under common rotations preserving p,q before loop integration, including BMHV LL and a noncompact virtual integral. We rely on rotation covariance/analytic continuation, not positivity or compact-cut i0 removal. What exact covariance regression most directly checks the optimized helicity-current average for a loop numerator?
2. Correct universal scalar triangle with one null external leg and two nonzero squared invariants a,b, all orders epsilon: parameter integration gives minus rGamma/eps^2 * [(-a-i0)^(-eps)-(-b-i0)^(-eps)]/(b-a), with rGamma=Gamma(1+eps)Gamma(1-eps)^2/Gamma(1-2eps). Check sign and coincident limit. Single-offshell triangle remains -rGamma/eps^2 * (-a-i0)^(-eps)/(-a-i0)? We will derive/check rather than fix by matching.
3. We found Haug & Wunder arXiv2211.14110v3, JHEP02(2023)177 for all-order one-offshell box and branch-safe single-valued representation. Recommend minimal universal representation that is explicit ordinary Li_n/Log at any finite epsilon order and correct all physical chambers. Endpoint expansions must retain regulated powers before epsilon expansion (as their Appendix D warns). How best separate branch-safe finite values from generic regulated endpoint expansion, without falsely expanding endpoint logs first?
4. Any hidden NNLO vector-current pieces (singlet, external-leg LSZ, imaginary tree-current structures) that make simply integrated interference plus its conjugate insufficient? We retain full one-loop diagram inventory and do not multiply an arbitrary real-part factor before integration. No published process coefficient is inserted in production; universal integral formulas allowed.
Please prioritize correctness and permanent common code over a one-process shortcut.

## Pro response

The proposed RV route is correct on its stated domain, and both triangle formulas have the correct sign. After the joint angular reduction and full-D loop integration, fixed x,z leave only the known measured two-body density—no new scalar phase-space integration is required. The remaining risks are incomplete covariance closure before TID, inconsistent loop normalizations, and using a fixed-kinematics epsilon expansion of the box as though it were an endpoint-uniform expansion.

1. Joint averaging of ℓ and k
1
	​

 is legitimate

Let Π
∥
	​

 project onto the physical plane span{p,q}, and define

v
⊥
	​

=(1−Π
∥
	​

)v,T
ij
	​

=v
i⊥
	​

⋅v
j⊥
	​

,H
ij
	​

=
v
^
i
	​

⋅
v
^
j
	​

.

The plane is nondegenerate and contains the timelike vector P=p+q. Its orthogonal complement is therefore spatial.

For the RV integral, use one common rotation of

ℓ
⊥
	​

,k
1⊥
	​

,k
2⊥
	​

=−k
1⊥
	​

.

It preserves

ℓ
2
,ℓ⋅k
1
	​

,ℓ⋅p,ℓ⋅q,k
1
	​

⋅p,k
1
	​

⋅q,

and every other full scalar product. Thus a denominator such as

(ℓ+k
1
	​

−p)
2
+i0

is unchanged, including its prescription.

Writing A
⊥
	​

 for the normalized common angular projection,

∫d
D
ℓ[dΦ
2
	​

]
z
	​

FN
BMHV
	​

=∫d
D
ℓ[dΦ
2
	​

]
z
	​

FA
⊥
	​

N
BMHV
	​

,
	​

(1)

provided F contains only rotation-invariant factors. This is the tensor-integration mechanism underlying transverse-integration identities. 
arXiv

Noncompactness does not invalidate the change of variables

These are spatial rotations with unit Jacobian, not contour deformations. They leave the loop-energy coordinate, Feynman prescriptions, forward-energy conditions, and the z-measurement unchanged.

Nevertheless, a common absolutely convergent domain in ϵ alone need not exist for every numerator rank and topology. Establish (1) with symmetry-preserving analytic regulators where necessary, then continue the complete identity. Do not justify exchanging conditionally divergent integrations by compactness of the real-emission phase space.

The equality is for the combined measured integral. It does not say that the standalone loop integral at a fixed orientation of k
1
	​

 is unchanged by replacing its BMHV numerator with the jointly averaged numerator.

The precise acceptance condition

After the complete scalar current/spin contraction, require a polynomial in

H
ℓℓ
	​

,H
ℓ1
	​

,H
11
	​

,

whose coefficients depend only on full-D scalar products. All denominators, reference-vector factors, and measurements must preserve the same rotation.

An extra physical transverse reference, a residual open tensor, or a nonpolynomial hatted denominator is outside this rule. Averaging ℓ and k
1
	​

 independently is also outside it.

Once that check passes, do not set 
k
^
1
	​

=0. Instead, the joint projection removes the explicit physical/evanescent split from the scalar numerator. TID then receives an ordinary full-D scalar/tensor integral.

A direct covariance regression for the optimized LL contraction

Use the real physical transverse two-form Ω
4
	​

, with its known longitudinal normalization and factors of i stripped off, normalized by

Ω
4,μν
	​

Ω
4
μν
	​

=2.

For d=D−2,

A
⊥
	​

[(Ω
4,μν
	​

ℓ
⊥
μ
	​

k
⊥
ν
	​

)
2
]=
d(d−1)
2
	​

(T
ℓℓ
	​

T
kk
	​

−T
ℓk
2
	​

).
	​

(2)

This directly exercises the normalized two-epsilon helicity/current contraction on a correlated loop numerator.

Multiply it by a shifted bubble with

K=k−p,K
2
=−2p⋅k

=0,
K
^
=
k
^
:
B
D
	​

(K
2
)=∫
iπ
D/2
d
D
ℓ
	​

(ℓ
2
+i0)((ℓ+K)
2
+i0)
1
	​

.

An independent Feynman-parameter calculation gives

∫
iπ
D/2
d
D
ℓ
	​

(ℓ
2
+i0)((ℓ+K)
2
+i0)
ℓ
μ
ℓ
ν
	​

=
4(D−1)
B
D
	​

(K
2
)
	​

(DK
μ
K
ν
−K
2
g
D
μν
	​

).
	​

(3)

Applying (3) after the right-hand side of (2) gives

−
2d(D−1)
K
2
T
kk
	​

	​

B
D
	​

(K
2
).
	​

(4)

Integrating the original physical two-form expression first and then averaging the remaining k-dependence must give the same result.

Also test (H
ℓk
	​

)
2
. The independent loop-first result is

4(D−1)
B
D
	​

(K
2
)
	​

[D
d(d+2)
m(m+2)
	​

T
kk
2
	​

−K
2
d
m
	​

T
kk
	​

],m=D−4.
	​

(5)

These tests detect lost correlations and an accidental physical-k substitution. Repeating with K=k+p tests timelike continuation without changing the tensor identities.

For the helicity shortcut itself, compare the explicit BMHV density–current contraction and the optimized contraction before integration, at symbolic full/hatted Gram data. Equations (2)–(5) then test its integration compatibility independently.

2. After TID, the phase space really is exhausted

At fixed x,z,

S=(p+q)
2
=
x
Q
2
(1−x)
	​

,J=
x
Q
2
	​

,

and

2p⋅k
1
	​

=zJ,2q⋅k
1
	​

=S−zJ,k
1
2
	​

=0.

Consequently, a full-D scalar loop result can depend only on Q
2
,x,z, not on the remaining orientation of k
1
	​

.

The external Gram determinant relevant to a generic rank-three tensor reduction is

detG(p,q,k
1
	​

)=
4
J
2
Sz(1−z)
	​

.
	​

(6)

It is nonzero in the open physical rectangle and degenerates at the endpoints. Perform TID at generic kinematics; do not insert x=1 or z=1 into its Gram denominators before the regulated endpoint analysis.

The factor multiplying the integrated loop result is

dz
dΦ
2
	​

	​

=
8πΓ(1−ϵ)
(4π)
ϵ
	​

S
−ϵ
[z(1−z)]
−ϵ
,
	​

(7)

not the fully integrated Φ
2
	​

(S). There is no second angular volume or measurement Jacobian to attach. The independent SIDIS calculation likewise finds the RV phase space fully constrained at fixed partonic x,z. 
arXiv

For the stated four-point massless amplitudes, ordinary one-loop tensor reduction closes on massless bubbles, triangles with at least one null external leg, and one-off-shell boxes. TID supports reduction to scalar Passarino–Veltman integrals, but its PaVeLimitTo4 option is explicitly an epsilon-zero simplification and must remain disabled here. 
FeynCalc

Normalization chain

With

J
N
	​

=∫
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

,

and FeynCalc’s

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

(D
j
	​

+i0)
ν
j
	​

1
	​

,

the conversion is

PV
N
	​

=π
−ϵ
J
N
	​

.
	​


Therefore

(2π)
−D
(iπ
2
)π
−ϵ
J
N
	​

=
(4π)
D/2
i
	​

J
N
	​

.
	​

(8)

The iπ
2
 is the factor from expressing the unnormalized integral through the PV object. Do not apply another loop-measure conversion afterward. 
FeynCalc
+1

Keep the scalar-provider contract explicit about whether it includes μ
2ϵ
, e
γ
E
	​

ϵ
, or r
Γ
−1
	​

. These are separate normalization conventions in the documented scalar-integral interfaces. 
FeynCalc

3. The two-off-shell triangle: sign and coincident limit

Define the massless triangle C
D
	​

(0,a,b) with one null external leg and the other squared invariants a,b, using the J
N
	​

 normalization above. Then

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

,
	​

(9)

where

r
Γ
	​

=
Γ(1−2ϵ)
Γ(1+ϵ)Γ(1−ϵ)
2
	​

.

A short derivation fixes the sign without comparison to a hard function. In a spacelike convergence region, choose Feynman parameters so that the Symanzik polynomial is

t(1−t)[−av−b(1−v)].

The triangle’s odd number of propagators gives

C
D
	​

(0,a,b)
	​

=−Γ(1+ϵ)B(−ϵ,1−ϵ)∫
0
1
	​

dv[−av−b(1−v)]
−1−ϵ
=
ϵ
r
Γ
	​

	​

∫
0
1
	​

dv[−av−b(1−v)]
−1−ϵ
.
	​


The elementary v-integral gives (9); then continue with the Feynman prescription. This uses the ordinary Dirichlet/Beta representation. 
DLMF
+1

Coincident nonzero invariants

Taking b→a

=0,

C
D
	​

(0,a,a)=
ϵ
r
Γ
	​

	​

(−a−i0)
−1−ϵ
.
	​

(10)

The sign is positive in front of r
Γ
	​

/ϵ. For negative ϵ and spacelike a, the integral is negative, consistently with the parameter representation.

Implement (9) as an exact divided difference with a derivative-based coincident branch. It should not become a literal 0/0 or be evaluated by subtracting nearly equal floating-point powers.

One-off-shell limit

Taking b→0 in the initial infrared-convergent domain, before expanding in epsilon,

C
D
	​

(0,0,a)=−
ϵ
2
r
Γ
	​

	​

−a−i0
(−a−i0)
−ϵ
	​

.
	​

(11)

This is also the formula you proposed. The all-zero case is scaleless; it is not obtained by substituting zero into the singular expression (11).

A useful independent reduction check is

B
D
	​

(a)=
ϵ(1−2ϵ)
r
Γ
	​

	​

(−a−i0)
−ϵ
,

which implies

(b−a)C
D
	​

(0,a,b)=−
ϵ
1−2ϵ
	​

[B
D
	​

(a)−B
D
	​

(b)].
	​

(12)

It also shows that these triangles need not become independent master objects, although retaining their divided-difference representation can be numerically preferable.

4. One-off-shell box: one definition, two evaluation modes

Use the exact causal scalar integral as the common definition. Provide two outputs from it:

a fixed-kinematics Laurent expansion into ordinary polylogarithms and logarithms;

a regulated endpoint expansion retaining powers whose exponents contain epsilon.

The second must not be obtained by taking limits of an already truncated first output.

4.1 A compact branch-safe fixed-point representation

Let s
1
	​

,s
2
	​

 be the two adjacent box invariants, let M
2
 be the off-shell external squared momentum, and put

s
3
	​

=M
2
−s
1
	​

−s
2
	​

,
X
1
	​

=−
s
1
	​

s
3
	​

	​

,X
2
	​

=−
s
2
	​

s
3
	​

	​

,X
12
	​

=−
s
1
	​

s
2
	​

s
3
	​

M
2
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

.

For nonzero generic invariants, define

χ(v)={
1,
e
iπϵ
,
	​

v<0,
v>0.
	​


Haug–Wunder’s equation (3.26), with their μ
2ϵ
 removed to match your scalar-provider normalization, reads

B
4
	​

(s
1
	​

,s
2
	​

,M
2
)=
	​

ϵ
2
s
1
	​

s
2
	​

2r
Γ
	​

	​

	​

s
1
	​

s
2
	​

s
3
	​

	​

	​

ϵ
×[χ(s
2
	​

)F(ϵ;X
1
	​

)+χ(s
1
	​

)F(ϵ;X
2
	​

)−χ(M
2
)F(ϵ;X
12
	​

)].
	​

	​

(13)

The interchange of s
1
	​

,s
2
	​

 in the first two phase coefficients is intentional. 
arXiv

A minimal implementation of the real function F, directly in classical polylogarithms, is

F(ϵ;X)=
⎩
⎨
⎧
	​

∣X∣
−ϵ
[1−
n≥1
∑
	​

ϵ
n
Li
n
	​

(X)],
πϵcot(πϵ)+X
−ϵ
n≥1
∑
	​

(−ϵ)
n
Li
n
	​

(1/X),
	​

X<1, X

=0,
X>1.
	​

	​

(14)

At any finite epsilon order, this is a finite expression in ordinary Li
n
	​

, logarithms, and zeta values. All displayed polylogarithm arguments are below their real branch cut. Use Li
1
	​

(X)=−log(1−X).

Equation (14) follows from

2
	​

F
1
	​

(1,−ϵ;1−ϵ;X)=1−
n≥1
∑
	​

ϵ
n
Li
n
	​

(X)

and hypergeometric inversion with its prescribed branches. 
DLMF
+2
DLMF
+2

The bounded single-valued-polylogarithm form in the paper is a useful internal representation for cancellation and numerical stability. It need not become a new function in the final exported coefficient: it can be lowered to the ordinary functions in (14).

4.2 Exceptional surfaces require limits of the assembled expression

Individual F terms diverge at X=1, while their box combination can remain finite. Do not assign a standalone finite value there.

Similarly, s
1
	​

s
2
	​

s
3
	​

=0 requires a regulated limit or the corresponding degenerate integral. The generic formula’s apparent 0/0 is not an integral definition.

In physical SIDIS, representation changes can occur on x=z and x+z=1. They are not additional factorization endpoints and must not acquire invented delta terms. The independently derived RV expressions are continuous across their representation-sector boundaries. 
arXiv

Canonicalize the box by its ordered propagator shifts and cyclic external ordering—not just a sorted list of invariants. Crossing must preserve the identification of s
1
	​

,s
2
	​

,M
2
 and the causal branch.

I checked (13) against the independently integrated two-parameter Feynman representation at two spacelike points, including one with X
1
	​

,X
2
	​

>1; they agreed to about 10
−16
 relative accuracy. That checks normalization and cancellation of artificial branches in those examples, not the full physical absorptive continuation.

5. Endpoint expansion must retain exact regulator-dependent powers

The exact hypergeometric representation is the appropriate source for endpoint analysis. Its auxiliary branch choices are correlated across the three terms; assigning the same independent +i0 to every hypergeometric argument is not valid. Haug–Wunder give those correlations explicitly. 
arXiv

For example, with

H
ϵ
	​

(X)=
2
	​

F
1
	​

(1,−ϵ;1−ϵ;X),

an exact inversion identity for X>1 is

H
ϵ
	​

(X±i0)=1−H
−ϵ
	​

(1/X)+
sin(πϵ)
πϵ
	​

(−X∓i0)
ϵ
.
	​

(15)

It separates contributions with different endpoint scalings before epsilon expansion. The logarithmic connection at X=1 must likewise be taken as the appropriate resonant hypergeometric limit. 
DLMF

A suitable endpoint output is a sum of terms

η
a+bϵ
(logη)
m
F(η,other variables,ϵ),

with a specified remainder and sufficient smooth-factor depth. For two endpoints, retain separate powers in each chart or sector; a single-variable connection does not establish uniformity when an argument tends to a ratio of the two small variables.

Why a fixed-point epsilon truncation is insufficient

Already

∫
0
1
	​

dηη
−1−ϵ
η
−ϵ
=−
2ϵ
1
	​


in the initial convergence domain. Expanding the second factor to any fixed number of logarithms before treating the endpoint does not reproduce its regulator role uniformly.

The box has precisely this issue: its regulated kinematic powers change the pole multiplying the endpoint delta, and suppressed terms can become finite after multiplication by a singular prefactor. Appendix D of Haug–Wunder demonstrates this explicitly. 
arXiv

The practical ordering should be

exact scalar integrals and rational coefficients
⟶regulated endpoint branches and required jets
⟶measured phase-space factors
⟶delta/plus expansion and Laurent collection.
	​

	​

(16)

Combining the phase-space factors before identifying the total regulated exponent is essential; the displayed separation is an implementation organization, not permission to expand either factor prematurely.

For fixed-point scalar-box output through ϵ
N
, its 1/ϵ
2
 prefactor requires the bracket through ϵ
N+2
. For finite RV distributions, one endpoint pole can require the integrated loop scalar through ϵ
1
, and a double endpoint can require ϵ
2
. Spurious reduction poles can demand more. Keep your planner in control rather than imposing a universal “boxes through ϵ
2
” ceiling.

Also do not use the saved NLO coefficient window as a replacement for exact-D tree numerators in the interference. Smooth spin/tensor factors multiplying loop and endpoint poles may be needed substantially deeper.

6. Diagram inventory and renormalization
The interference plus its conjugate is the complete RV bilinear

With your current-index order,

w
RV
μν
	​

=∫[dΦ
2
	​

]
z
	​

[A
0
μ∗
	​

A
1
ν
	​

+A
1
μ∗
	​

A
0
ν
	​

].
	​

(17)

For a Hermitian projector,

P
μν
∗
	​

=P
νμ
	​

,

this equals twice the real part of the complete projected, integrated interference.

It does not justify replacing every scalar loop integral by its real part independently. If

I=
j
∑
	​

c
j
	​

J
j
	​


and some c
j
	​

 are complex, then

2ℜI

=2
j
∑
	​

c
j
	​

ℜJ
j
	​

.

The g
1
	​

 projector itself is imaginary and antisymmetric. Preserve the existing Hermitian completion; there is no extra “imaginary tree-current contribution” outside (17).

No missing vector-current singlet triangle at this order

A candidate closed-quark-loop contribution in which the photon couples to two gluons cancels between the two loop orientations. The three vector vertices give the relative minus sign, and the color factor is

tr(T
a
T
b
)−tr(T
b
T
a
)=0.

This applies to the electromagnetic vector current, including an off-shell photon. It is not an axial triangle.

Thus that topology supplies no extra RV singlet term. This does not remove ordinary quark-loop contributions elsewhere or the genuine pure-singlet/flavor structures in RR. Retain the full generated inventory and verify the vector-loop cancellation, rather than deleting all closed-fermion-loop graphs by category.

For the full NNLO result, the one-loop square of the one-particle current amplitude belongs in VV. The square of the one-loop two-particle amplitude is one perturbative order higher than the RV interference here. RR, RV, VV, UV renormalization, and both collinear factorizations remain separate required pieces. 
arXiv

External legs and UV counterterms must use one convention

For bare on-shell massless amplitudes in pure dimensional regularization, external self-energy integrals are scaleless. Do not set those integrals to zero and then append an isolated external-field counterterm from a different off-shell/LSZ convention. Either use the consistent bare on-shell convention or include fields, vertices, and LSZ factors consistently.

The conserved electromagnetic vector current does not acquire an axial finite Z
5
	​

. The polarized-PDF transformation remains a separate operator-factorization operation.

Coupling renormalization is required at this order. With

a
s
	​

=
2π
α
s
	​

	​

,b
0
	​

=
6
11C
A
	​

−4T
R
	​

n
f
	​

	​

,

write

a
s,0
	​

=μ
R
2ϵ
	​

(4π)
−ϵ
e
γ
E
	​

ϵ
a
s
	​

(1−
ϵ
b
0
	​

	​

a
s
	​

+⋯).

The NLO real contribution therefore supplies the NNLO counterterm

−
ϵ
b
0
	​

	​

C
real
(1)
	​

(ϵ),
	​

(18)

with all normalization factors consistently expressed. Equivalently, the one-loop amplitude counterterm is −b
0
	​

/(2ϵ) times the corresponding tree amplitude in an a
s
	​

 expansion. Do not count both forms. Universal infrared-factorization identities provide a further independent check of the UV-renormalized one-loop poles. 
arXiv

7. Recommended next implementation order

The smallest permanent extension is:

Validate the joint RV contraction with the symbolic two-form identity and shifted-bubble tests (2)–(5), including one timelike continuation.

Close the scalar loop provider with the exact triangle divided difference, coincident branch, bubble identity (12), and an explicitly normalized one-off-shell box.

Expose distinct fixed-point and regulated-endpoint outputs. Test the latter with a box limit having two different regulated powers, not only a leading singular term.

Assemble complete RV coefficients before expensive expansion, cancel rational Gram artifacts, restore UV counterterms, and check current/gluon Ward identities and the universal pole structure.

Only then generate the requested delta/plus/regular coefficients, using the common order planner and the existing single application of the polarized-PDF conversion.

The architecture does not require new RV phase-space masters. It requires an exact loop-scalar provider whose causal finite values and regulated endpoint limits are two consistent views of the same integral. That distinction—not another integration backend—is the principal remaining mathematical requirement.