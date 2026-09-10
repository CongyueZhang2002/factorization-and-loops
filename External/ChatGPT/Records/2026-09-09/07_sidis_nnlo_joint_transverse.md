# SIDIS NNLO correlated angular moments and measurement cuts

Verified outgoing model: gpt-6-pro. HTTP 200. Request: 4adef881-4b7c-47d9-ac88-a5bfd4619bb9.

## Question

We are continuing the card-driven FeynFacet collinear benchmark campaign, no subagents and at most two main Wolfram kernels/eight cores. Repo https://github.com/CongyueZhang2002/factorization-and-loops branch codex/scientific-terminology-and-math-fixes; latest edits are local, do not assume remote has them.

The full integrated SIDIS NLO calculation is now independently generated for all six channels q-q, q-g, antiquark analogues, g-q/g-qbar in UU (2F1,FL/x) and incoming LL (2g1) with unpolarized FF. Every finite coefficient including all PDF/FF scale dependence matches the original Bonino ancillary files exactly (12 UU and 6 LL comparisons). Production retains NLO epsilon one and Born epsilon two. References never feed production. The Drell–Yan implementation follows your review06.

Next is complete SIDIS NNLO from generated amplitudes, IBP/DE and actual boundary integration, not importing a published hard function or master table. Please review the most efficient GENERAL production architecture for the double-real current contribution, especially evanescent geometry. Context:

p,q physical, p^2=0, q^2=-Q2, 2p.q=Q2/x. Total P=p+q is physical timelike, three outgoing massless momenta k1,k2,k3=P-k1-k2 are D-dimensional. Tagged k1 has z=p.k1/(p.P). RR should have three positive-energy quadratic mass-shell cuts and the separate linear measurement delta delta(z-p.k1/(p.P)), normalized by Q2/x when written as delta(2p.k1-z Q2/x). This linear measurement is NOT a positive-energy cut. Existing framework handles quadratic phase-space cuts, ordinary virtual loops, cut-aware Kira IBP, general DE transport and boundary integration, but does not yet have an appropriate typed linear measurement cut for RR. Existing mass-deformation i0-removal certificate is for a compact quadratic phase space and must not be blindly extended.

At NLO, exact two-body measured density with k_perp^2=-s z(1-z) and <(khat^2)^a>=(-eps)_a/(1-eps)_a*(k_perp^2)^a suffices. We also have a virtual one-loop average over the orthogonal complement of a NONDEGENERATE PHYSICAL external span. You correctly warned it cannot be used for RV with external integrated D-dimensional k1/k2 carrying hatted components.

Please give a concrete review of:
1. For RR, may the entire BMHV numerator be reduced to the ordinary full-D scalar-product field BEFORE IBP by averaging the projection of the joint transverse vectors k1_perp,k2_perp into the (D-4)-dimensional subspace, with physical span{p,q}? Derive low-degree mixed moment identities and a general algorithm (tensor projector/Gram/Wishart moments), retaining their correlations. Specify polynomial-degree and transverse-invariance restrictions. Is this a reusable, fast alternative to dimensional recurrences?
2. For RV, can one keep all integrated vectors (loop ell,k1,k2) together in such a joint angular tensor reduction before performing the loop integral, instead of pretending k1 is physical? What fixed external invariants must the averaging hold constant; do causal propagators obstruct this because they are full-D scalar invariants? Derive the general validity statement or identify the failure.
3. A practical typed reverse-unitarity interface for linear measurement deltas, higher powers under IBP, uncut linear numerators/denominators, and preservation of support/normalization. Which proof parts are needed specifically at fixed 0<x,z<1 before generic coefficient reduction? Can old quadratic-cut compactness plus a smooth slicing delta justify the same ordinary i0-removal at generic kinematics, and when not?
4. Compare nested phase-space integration using a massive two-body factorization versus direct reverse-unitarity for RR. Which route avoids unmanageable intermediate growth while preserving a general framework rather than process-specific formulas? We expect roughly 21 RR masters/13 families from literature, but must discover/reduce them ourselves.
5. Please list two cheap independent checks for each genuinely new ingredient and flag any epsilon-order/normal-derivative traps. Do not suggest hardcoding known SIDIS master tables or tuning to references.

We intend to implement the mathematical core once, then use cards to select all channels. The user cares most about general first-principles code, compact explicit final coefficients, and fast production. We can reference public papers only to review/verify the derivation.

## Pro response

Yes: a joint transverse-angular reduction is valid for both RR and RV, and it is the most direct extension of your existing evanescent treatment. It must preserve the entire transverse Gram matrix, rather than average the vectors independently. For these SIDIS contributions, momentum conservation leaves only two independent transverse vectors in either case, so one cached moment engine can cover both.

My recommendation is to use joint angular reduction followed by direct reverse-unitarity reduction as the main RR production route, and use nested phase-space factorization for boundary construction, simple subtopologies, and independent checks. The linear measurement cut should become a first-class distributional object. Its introduction does not, by itself, extend the existing i0-removal certificate.

1. Joint evanescent reduction for RR
1.1 Define the geometry without imposing four-dimensional Gram relations

Let S=span{p,q}, with

G=(
0
Q
2
/(2x)
	​

Q
2
/(2x)
−Q
2
	​

),detG=−
4x
2
(Q
2
)
2
	​


=0.

Define

Π
∥
μν
	​

=p
a
μ
	​

(G
−1
)
ab
	​

p
b
ν
	​

,g
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

The transverse dimension and evanescent dimension are

d=D−2,m=D−4,

so here m=d−2=−2ϵ.

For any integrated vectors v
i
	​

, introduce

v
i⊥
	​

=g
⊥
	​

v
i
	​

,T
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

In particular,

T
ij
	​

=v
i
	​

⋅v
j
	​

−(v
i
	​

⋅p
a
	​

)(G
−1
)
ab
	​

(p
b
	​

⋅v
j
	​

).
	​


Every T
ij
	​

 is an ordinary full-D scalar-product expression.

For RR,

k
3⊥
	​

=−k
1⊥
	​

−k
2⊥
	​

,
k
^
3
	​

=−
k
^
1
	​

−
k
^
2
	​

.

Thus eliminate all H
i3
	​

 in favor of

H
11
	​

, H
12
	​

, H
22
	​

.

For example,

H
33
	​

=H
11
	​

+2H
12
	​

+H
22
	​

.

The relevant operation is transverse tensor integration: an invariant integration measure allows noninvariant numerator tensors to be replaced by their invariant projection. This is distinct from an integrand identity at fixed loop-momentum components. 
arXiv

1.2 What is being averaged?

Keep the vectors’ complete Gram matrix T fixed, and rotate all transverse vectors by the same R∈O(d). The evanescent metric selects an m-dimensional subspace of this transverse space.

Equivalently, average a rank-m orthogonal projector P over its orientation. In Euclidean transverse coordinates,

H
ij
	​

=−v
i
T
	​

Pv
j
	​

,T
ij
	​

=−v
i
T
	​

v
j
	​

.

The minus signs reflect the mostly-minus spacetime metric. They cancel consistently between products of the same degree; no extra sign should be added to the moment coefficients below.

This is a fixed-Gram projection problem, not an average over independent Gaussian vectors. An unconditioned Wishart calculation would change the Gram matrix and give the wrong moments. Haar-moment methods provide the general framework for this projection. 
arXiv

1.3 Low-degree mixed moments

The first moment is

⟨H
ij
	​

⟩=
d
m
	​

T
ij
	​

.
	​


For the second moment, rotational invariance gives

⟨H
ij
	​

H
kl
	​

⟩=AT
ij
	​

T
kl
	​

+B(T
ik
	​

T
jl
	​

+T
il
	​

T
jk
	​

),
	​


where

A=
d(d−1)(d+2)
m[(d+1)m−2]
	​

,B=
d(d−1)(d+2)
m(d−m)
	​

.
	​


A short derivation is to write

⟨P
ab
	​

P
cd
	​

⟩=Aδ
ab
	​

δ
cd
	​

+B(δ
ac
	​

δ
bd
	​

+δ
ad
	​

δ
bc
	​

)

and impose

(trP)
2
=m
2
,trP
2
=m.

These produce

d
2
A+2dB=m
2
,dA+d(d+1)B=m,

which determine A,B.

For the two-vector engine, useful explicit cases are

⟨H
11
	​

H
22
	​

⟩
⟨H
12
2
	​

⟩
⟨H
11
	​

H
12
	​

⟩
⟨H
11
2
	​

⟩
	​

=AT
11
	​

T
22
	​

+2BT
12
2
	​

,
=BT
11
	​

T
22
	​

+(A+B)T
12
2
	​

,
=
d(d+2)
m(m+2)
	​

T
11
	​

T
12
	​

,
=
d(d+2)
m(m+2)
	​

T
11
2
	​

.
	​

	​


In particular,

⟨H
11
	​

H
22
	​

−H
12
2
	​

⟩=
d(d−1)
m(m−1)
	​

(T
11
	​

T
22
	​

−T
12
2
	​

).
	​


The cross term in the first equation is essential. Replacing it by

⟨H
11
	​

⟩⟨H
22
	​

⟩=
d
2
m
2
	​

T
11
	​

T
22
	​


loses both the correct diagonal coefficient and the relative-angle correlation.

1.4 A general exact algorithm

For a monomial of degree a in the H
ij
	​

, collect its 2a vector labels into

b=(i
1
	​

,j
1
	​

,…,i
a
	​

,j
a
	​

).

Let τ be the pairing that joins each original H-factor:

τ=(12)(34)⋯(2a−1,2a).

For pairings π,σ of these 2a positions, let c(π,σ) denote the number of closed components obtained by overlaying the two pairings. Construct

G
πσ
	​

(d)=d
c(π,σ)
,v
σ
	​

(m)=m
c(σ,τ)
.

Solve, at generic symbolic d,m,

Gw=v.

Then

⟨
α=1
∏
a
	​

H
i
α
	​

j
α
	​

	​

⟩=
π
∑
	​

w
π
	​

(d,m)
(u,v)∈π
∏
	​

T
b
u
	​

b
v
	​

	​

.
	​


This is an invariant-tensor Gram-projector construction. It yields the low-degree formulas above and arbitrary polynomial moments.

For implementation, do not invert a (2a−1)!!-dimensional symbolic matrix for every diagram. Instead:

Census the actual hatted-monomial degrees after the complete BMHV trace.

Cache the universal moment maps by contraction pattern, with symmetry-equivalent pairings combined.

Substitute the vector labels and scalar Gram entries only afterward.

The matrix being inverted depends on dimension, not on kinematics. Consequently, this method introduces no inverse Gram determinant of k
1
	​

,k
2
	​

. That is an important advantage over repeated momentum-specific tensor decompositions.

At sufficiently high rank, an uncontracted pairing matrix can become singular at special integer d. Work at generic d, contract and simplify the resulting scalar polynomial, then set

m=d−2,d=2−2ϵ.

Do not evaluate the tensor-projector matrix at d=2, and do not impose four-dimensional rank conditions on the full-D T.

1.5 Domain and BMHV restrictions

The replacement is valid when the scalar numerator can be written

N=
a
∑
	​

n
a
	​

(full-D invariants)
i≤j
∏
	​

H
ij
a
ij
	​

	​

,a
ij
	​

≥0,

and everything outside those H-monomials is invariant under the joint transverse rotation.

For the requested UU and g
1
	​

 projections, this is the expected closure after all Lorentz indices and Levi-Civita tensors have been dealt with consistently. For g
1
	​

, the current projector and polarized density provide the relevant paired parity-odd structures. Nevertheless, verify polynomial closure rather than assuming it from the channel label.

Reject or separately handle a residual physical transverse vector, uncontracted Lorentz indices, a denominator depending on H
ij
	​

, or an unreduced parity-odd structure. A vanishing parity-odd average can be established separately, but it should not be silently equated to “unsupported terms vanish.”

There is no fixed mathematical degree limit. There is a computational degree limit. Do not assume that NNLO implies degree at most two; measure the generated degree. For the modest ranks usually produced here, the cached projection should be substantially simpler than introducing dimension-shifted master families. That is an architectural expectation, not a timing guarantee.

This operation preserves the BMHV calculation. It is not a finite helicity-scheme conversion.

2. RV: joint averaging before the loop integral is valid

For RV,

k
1
	​

+k
2
	​

=P,k
2⊥
	​

=−k
1⊥
	​

.

Together with the virtual momentum ℓ, there are again only two independent transverse vectors:

ℓ
⊥
	​

,k
1⊥
	​

.

Thus the same engine handles

H
ℓℓ
	​

,H
ℓ1
	​

,H
11
	​

.
2.1 The precise validity statement

Consider a regulated combined integral

I[N]=∫d
D
ℓdΦ
2
	​

(P;k
1
	​

,k
2
	​

)δ(z−
p⋅P
p⋅k
1
	​

	​

)FN,

where F includes the causal propagators and all remaining scalar factors.

A simultaneous transverse rotation keeps fixed

p,q,v
i
	​

⋅p,v
i
	​

⋅q,v
i
	​

⋅v
j
	​


for all integrated vectors v
i
	​

. In particular, it preserves

ℓ
2
,ℓ⋅k
1
	​

,k
1
2
	​

,

rather than averaging the relative angle between ℓ and k
1
	​

.

For each rotation R,

I[N]=I[N∘R].

Averaging this equality gives

I[N]=I[⟨N⟩
joint
	​

].
	​


The values of the full scalar invariants are held fixed during the orientation average, not fixed numerically in the subsequent integral.

2.2 The causal denominators do not obstruct this proof

The span of p,q contains a timelike direction, so the transverse transformations are spatial rotations. They leave loop energy unchanged. For example,

(ℓ+k
1
	​

)
2
+i0

is unchanged because ℓ and k
1
	​

 rotate together.

Therefore this argument does not deform the Feynman contour or cross a pole. Positive-energy phase-space conditions are also unchanged. Establish the change of variables with symmetry-preserving regulators where the manipulations are justified, then continue meromorphically.

The operation does not remove the i0, and it is not generally valid for the standalone loop integral with the orientation of k
1
	​

 held fixed. The proven equality is for the combined observable.

After joint averaging, the integrand contains only full-D scalar products. You can then choose either:

ordinary full-D loop integration⟶measured two-body phase space,

or a combined cut-integral reduction.

For this campaign, the first route is a reasonable default for RV, using the generated one-loop numerators and sufficiently deep single-off-shell scalar integrals. Crucially, it requires no fiction that the original integrated k
1
	​

 was physical four-dimensional.

The remaining exclusions are substantive: an angular measurement or regulator selecting an extra transverse direction, nonpolynomial hatted dependence, or averaging different vectors separately would invalidate this argument.

3. Typed linear measurement cuts
3.1 Separate polynomial form from distributional role

A minimal proposed denominator record is:

Wolfram Language
<|
  "Polynomial" -> G,
  "MomentumDegree" -> 1,
  "Role" -> "MeasurementCut",
  "Power" -> 1,
  "NormalVariable" -> G,
  "EnergyCondition" -> None
|>

Use the same polynomial infrastructure for distinct roles:

Role	Meaning
ParticleCut	Mass-shell discontinuity with a declared positive-energy orientation
MeasurementCut	Delta or delta derivative of a measurement polynomial; no energy condition
OrdinaryPropagator	Uncut denominator with its causal prescription
ScalarProduct	Algebraic numerator coordinate, or explicitly justified algebraic inverse

“Linear” and “cut” are independent properties. A linear measurement is affine in the scalar-product coordinates and fits the ordinary reverse-unitarity IBP construction; it is not necessary to turn it into a quadratic mass-shell denominator. This treatment is used explicitly for SIDIS measurement constraints. 
arXiv

For RR, define

D
1
	​

=k
1
2
	​

,D
2
	​

=k
2
2
	​

,D
3
	​

=(P−k
1
	​

−k
2
	​

)
2
,
G=2p⋅k
1
	​

−
x
zQ
2
	​

,J=
x
Q
2
	​

.

After eliminating k
3
	​

, your phase-space normalization is

[dΦ
3
	​

]
z
	​

=(2π)
3−2D
J∫d
D
k
1
	​

d
D
k
2
	​

δ
+
	​

(D
1
	​

)δ
+
	​

(D
2
	​

)δ
+
	​

(D
3
	​

)δ(G).
	​


Keep this physical measure normalization separate from any normalized-loop-measure conversion used by the scalar backend.

3.2 Higher powers must have one fixed definition

Define

C
ν
	​

(G)=
2πi
1
	​

[
(G−i0)
ν
1
	​

−
(G+i0)
ν
1
	​

]=
(ν−1)!
(−1)
ν−1
	​

δ
(ν−1)
(G).

Then

GC
ν
	​

=C
ν−1
	​

(ν>1),GC
1
	​

=0,
	​


and

∂
λ
	​

C
ν
	​

(G)=−ν(∂
λ
	​

G)C
ν+1
	​

(G).
	​


In particular, at fixed x,

∂
z
	​

C
ν
	​

(G)=νJC
ν+1
	​

(G).

These are identities of distributions, not replacements obtained by setting G=0. The distinction follows directly from distributional differentiation. 
DLMF

Missing mandatory cut slots give zero. Missing ordinary linear denominators do not. Negative powers of an ordinary linear polynomial can represent numerator insertions.

Do not create an independently prescribed ordinary factor 1/(G+i0) multiplying δ(G) and silently identify it with a raised cut. Such a product requires a definition at the underlying discontinuity level; coincident ordinary and cut slots should be detected.

For an external constant c>0,

C
ν
	​

(cG)=c
−ν
C
ν
	​

(G).

For negative c, the discontinuity orientation must also be transformed. Store the normal polynomial and its rescaling, rather than reconstructing signs from a canonicalized expression later.

The original J belongs to the unit measurement definition. It must not be reattached as though every raised cut were a fresh unit delta. External differentiation must act on J as well whenever J depends on the differentiated variable.

3.3 Do not disguise the measurement as a quadratic cut

Using k
1
2
	​

=0, one can write a quadratic expression equal to G on the original cut. That does not authorize replacing its normal coordinate throughout a dotted-cut family.

Changing from G to G+cD
1
	​

 changes how derivatives normal to the intersecting cut surfaces are represented. It is legal only with the full cut-coordinate transformation and derivative mixing. A typed linear slot avoids this unnecessary complication.

There are

2
L(L+1)
	​

+LE=3+4=7

independent scalar products for L=2,E=2. The four mandatory cuts generically occupy four independent affine combinations. Complete families in this seven-dimensional scalar-product space, partial-fraction overcomplete denominator sets, and preserve the cut roles during equivalence mapping.

An unobserved-momentum permutation may be a symmetry; moving the observed momentum without transforming G is not.

3.4 What must be proved at fixed 0<x,z<1?

Before ordinary coefficient reduction, require:

Correct support and a regular measurement. The future mass-shell component, momentum conservation, and measurement must be compatible. On the smooth phase-space interior, the measurement should define a regular slice. Its ambient gradient is null,

∂
k
1
	​

	​

G=2p,(∂G)
2
=0,

but nonzero. Nullness is not failure of regularity. Do not use

(∂G)
2
∂G
	​


as a normal vector. For example,

W
μ
=
2p⋅q
q
μ
	​


satisfies W⋅∂G=1.

A consistent distributional IBP algebra. Keep cut derivatives and derive identities before imposing support relations. Tangent IBP vectors are a possible later optimization, but ordinary raised measurement cuts are the simpler initial implementation for this linear constraint. Tangent and weakly tangent constructions require their off-support terms to be retained correctly. 
arXiv

A valid scalar-product map and equivalence map. The map must be invertible on the declared generic chamber and preserve the measurement, energy orientations, and any ordinary prescriptions.

An i0-removal proof is not a prerequisite to performing IBP with prescriptions retained. It is a prerequisite to identifying differently prescribed values or erasing that information.

4. Compactness plus slicing: what transfers, and what does not

The original future three-body phase space has compact closure in the rest frame of P. A fixed measurement selects a subset, so it preserves compactness.

But

compact support+regular slice 

⇒ i0 independence.
	​


For example,

∫
0
1
	​

du∫
0
1
	​

dv
u−
2
1
	​

+i0
δ(v−z)
	​


has compact support and a regular measurement for 0<z<1, yet its causal prescription matters.

There are two distinct inheritance cases.

Strong parent certificate

If the existing theorem establishes absence of the relevant denominator zeros—or the required prescription independence—on the entire permitted mass-deformed quadratic domain, then restricting to a compatible measurement slice does not invalidate that pointwise part of the proof.

You still need to verify that the slice is defined and sufficiently regular, and that the argument remains valid under the required mass and measurement derivatives. This can be a small extension of an existing strong certificate, not a new proof for every integral.

Compactness or on-shell sign information only

This is insufficient. A zero confined to an unresolved boundary may still matter after slicing, differentiation, or regulator continuation. A sign property proved only at zero cut masses does not justify mass derivatives in dotted-cut integrals.

The narrow extension should establish, on the relevant mass-deformed sliced domain:

the same allowed denominator-sign or no-pinch property;

sufficient regularity of the slice, including its boundary strata;

a common regulated definition in which slicing, the required normal derivatives, and the prescription limit commute.

Work uniformly on compact subsets of 0<x,z<1 where appropriate, but remember that unobserved soft/collinear boundaries remain even there. Coarea regularity in the smooth interior does not automatically establish convergence at those boundaries.

If this extension is not established, retain the prescriptions. Do not make prescription erasure a compulsory preprocessing step. The same algebraic IBP matrix can often be used while keeping distinct causal master definitions.

For RV, the loop integration is noncompact and can have physical discontinuities. The RR compactness argument is not its prescription-removal theorem, even though joint angular averaging remains valid.

5. Production route: reduce first, integrate selected objects directly
5.1 Recommended RR sequence

The efficient shared sequence is

generated, tagged scalar interferences
↓
hatted-Gram polynomial collection and joint projection
↓
typed measured families and shared IBP reduction
↓
DEs plus physically integrated boundary data
↓
complete coefficient assembly and endpoint expansion.
	​

	​


Collect common denominator structures and hatted monomials before expanding them into long full-D polynomials. Memoize the moment substitutions. Discover the union of required sectors and numerator powers across UU, LL, and all tags, rather than launching separate reductions for each channel.

The angular replacement increases scalar numerator rank but introduces no new physical denominator or scale. Thus it should let UU and LL share the same scalar-family infrastructure. Whether a higher numerator power exposes a previously unused sector is determined by the generated reduction, not by an assumed master count.

Combine common-master coefficients, exact color declarations, and rational factors before expensive function conversion or simplification. There is little value in producing a separate GPL-expanded expression for every interference.

5.2 Where nested phase space is especially useful

Let

K=k
2
	​

+k
3
	​

,M
2
=K
2
,u=
s
M
2
	​

,s=P
2
.

The exact factorization is

dΦ
3
	​

(P;k
1
	​

,k
2
	​

,k
3
	​

)=
2π
dM
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

).
	​


For the first decay,

z=(1−u)y,

so the measured support is

0<u<1−z,y=
1−u
z
	​

,

with Jacobian dy/dz=1/(1−u).

This yields, with

A
ϵ
	​

=
8πΓ(1−ϵ)
(4π)
ϵ
	​

,

the first measured two-body factor

dz
dΦ
2
	​

(P;k
1
	​

,K)
	​

=A
ϵ
	​

s
−ϵ
[z(1−u−z)]
−ϵ
.

Integrating both decays with unit numerator gives the useful first-principles normalization check

dz
dΦ
3
	​

	​

=
128π
3
(4π)
2ϵ
	​

s
1−2ϵ
Γ(2−2ϵ)
2
Γ(1−ϵ)
2
	​

z
−ϵ
(1−z)
1−2ϵ
.
	​


In four dimensions,

dz
dΦ
3
	​

	​

=
128π
3
s
	​

(1−z),Φ
3
	​

=
256π
3
s
	​

.

No current normalization, spin average, or flavor factor belongs in this scalar measure.

This representation is particularly useful for automatic support derivation, low-sector integrals, boundary-region integrands, and independent checks. Direct angular/radial integration and reverse-unitarity/DE methods have both been used for these SIDIS integrals. 
arXiv

5.3 Do not perform a new local BMHV average in the cluster rest frame

Although P is physical,

K
^
=−
k
^
1
	​


is generally nonzero. Treating K as a new physical four-dimensional anchor for a second application of the old one-vector BMHV rule would lose the correlations you just identified.

Perform the global BMHV projection first. Once only full-D scalar quantities remain, ordinary D-covariant phase-space factorization and a cluster rest frame are legitimate.

Likewise, the nested route does not imply that every integral reduces to Beta functions. Denominators involving the decay angles can produce nontrivial angular functions, and integrating each unreduced interference separately is a plausible source of expression growth. Use nested integration on the reduced boundary basis or generically recognized simple subtopologies—not as the default way to integrate the full squared amplitude.

Boundary constants must come from the actual region integrals, with their Jacobians and prescriptions. Do not assume one region, commuting endpoint limits, or zero boundary modes merely because those properties hold in a published basis.

A count correction: the cited RR study’s v2 reports 20 masters after its initial reduction in 13 families, then proves two additional relations using DEs and boundary data. Neither 21 nor 20 is a production acceptance criterion for your independently discovered basis. 
arXiv

5.4 Resource organization

Use one main process to own family discovery, shared reductions, and coefficient assembly. A second can perform independent boundary integrations or checks. Keep a single eight-core allocation across Wolfram, Kira, and external threaded libraries; do not allow per-channel launches to multiply that allocation.

The important optimization is shared mathematical work, especially common reductions and cached moment maps, rather than parallelizing every channel independently.

6. Two inexpensive independent checks per new ingredient

These test implementation independently of published SIDIS hard functions.

New ingredient	Check 1	Check 2
Joint hatted-Gram projector	Set v
2
	​

=λv
1
	​

; every mixed moment must reduce to the already verified one-vector Pochhammer rule.	Integrate low-degree numerators against a coupled Gaussian e
−av
1
2
	​

−2bv
1
	​

⋅v
2
	​

−cv
2
2
	​

, with b

=0, using independent Gaussian/Wick integration.
RV application of joint averaging	Use a bubble subloop with a 
ℓ
^
⋅
k
^
 insertion: integrate the loop by Feynman parameters first, then apply the outer one-vector phase-space average; compare with joint reduction first.	Repeat a timelike test with conjugate prescriptions and verify conjugation of the fully normalized result, not just its real part.
Measurement-cut algebra	Compare the unit-cut integral and its z-derivative against direct measured phase-space integration, including the factor J.	Test GC
2
	​

=C
1
	​

 and the transformations G↦2G, G↦−G on analytic test functions.
Linear-slot family/backend mapping	Reconstruct every scalar product and cut polynomial exactly from the completed affine denominator basis; verify that missing mandatory cuts vanish but missing ordinary linear denominators do not.	Obtain a z-derivative both by differentiating a direct low-sector integral and by generating the dotted measurement cut and reducing it.
Sliced prescription-removal guard	A uniformly nonzero denominator on a regular compact mass-deformed domain must retain its certificate after slicing.	The compact interior-pole example above, and a denominator that changes sign under an allowed mass deformation, must be rejected.
Nested three-body geometry	Derive the measured volume above and its fully integrated limit using the two-body providers.	Independently integrate simple energy-fraction moments; permutation symmetry must give ∫z
i
	​

dΦ
3
	​

=Φ
3
	​

/3 and ∑
i
	​

z
i
	​

=1.

The guard tests check that the software enforces the intended theorem. They do not replace a certificate for the actual generated denominators. Numerical angular or integral samples are useful supplementary diagnostics, not proofs of the universal identities.

7. Epsilon and normal-derivative traps

Keep exact D through the moment projection and rational reduction. A positive power of an evanescent Gram entry is not automatically a correspondingly high power of ϵ. Already

⟨H
11
a
	​

⟩=
(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

T
11
a
	​


starts at O(ϵ) for every a≥1. Mixed moments require their own exact valuation after contraction and cancellation.

Let the assembled expression determine master depth. Angular-projector denominators, IBP coefficients, virtual poles, and endpoint distributions all contribute. A finite NNLO coefficient can require smooth factors through ϵ
4
 when multiplied by a fourth-order pole, and individual master coefficients can require more because of spurious poles. Your retained Born ϵ
2
 and integrated NLO ϵ
1
 windows address lower-order counterterm dependencies; they do not replace the new NNLO depth analysis.

A raised measurement cut carries normal information. In the present convention,

GC
2
	​

=C
1
	​

,

not zero. Do not impose G=0, k
i
2
	​

=0, or another cut-support relation inside a differentiated expression as though all cut powers remained one.

Normal changes of variables act on the whole integrand. Cut rescalings, Jacobians, coefficients, and any normal-dependent integral representation must be transformed together. The original on-shell spin numerator is a valid starting unit-cut distribution; it is not a license to redefine all dotted descendants by the same value-only substitution.

Interior DE identities are not a complete endpoint-distribution definition. Measurement derivatives correspond to derivatives of the spectrum, including its support. Differentiating only an interior function and omitting boundary terms can miss delta contributions. Assemble the regulated coefficient and its prescribed endpoint extension before declaring the derivative operation complete.

No new helicity finite factor is supplied by angular integration. Keep the existing universal polarized-PDF scheme transformation separate, with the required NNLO flavor structure. The final-state FF remains unpolarized.

The core implementation should therefore be one invariant moment projector, one typed polynomial-cut algebra, and two complementary scalar-integration backends. That removes the evanescent complication without creating an independent process-specific production path. The principal remaining mathematical work is the measured integral reduction and its physical boundary data—not a new prescription for BMHV at every channel.