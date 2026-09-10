# Drell–Yan normalization, massive phase space and external distribution support

Verified model: gpt-6-pro. Request: 4e8cb7e0-cb05-4b8a-9978-e95dbac07b82.

## Question

Update: all 12 integrated SIDIS NLO UU/LL channel results are now explicit through epsilon^1, all poles cancel, and all finite coefficients agree exactly with the Bonino et al. ancillary tables (12 UU structure-function comparisons + 6 LL). Reference data is read only by the comparison driver. The pp qg -> observed g UU result also passes all 32 INCNLO checks. Incoming-LL scattering runs are proceeding on 8 cores. We next need the planned inclusive photon-mediated UU Drell-Yan NLO benchmark before SIDIS NNLO.

Please review this Drell-Yan current/phase-space extension, and one normalization scope point:
1. Observable d sigma/d Q2, integrated pair rapidity, transverse momentum and lepton angles. Write partonic d sigma_ab/d Q2 = [4 pi alpha_em^2/(3 Nc Q2 s)] C_ab(z), z=Q2/s; flavor charge squared stays inside C. Factor out the universal leptonic tensor, use the D-dimensional conserved-current contraction (-g_D^{mu nu}+q^mu q^nu/Q2), without averaging the outgoing virtual photon. The generated hard tensor uses the existing normalized incoming quark/gluon spin/color densities. Then C = Nc/(2 pi) times the current-contracted inclusive phase-space integral, including strong couplings but excluding the electromagnetic current coupling removed once on each amplitude side. At Born this gives e_q^2(1-eps) delta(1-z), retaining positive-eps Born terms for mass factorization. The physical cross-section prefactor is its four-dimensional limit; all contributions use the same factored leptonic convention. Does this normalization and Born-epsilon definition match a coherent standard MSbar coefficient convention, without an extra z or D-1 average? I derived the prefactor from the two-lepton tensor and dQ2/(2pi), not by matching the hard function.

The generic two-particle geometry will allow masses m1^2,m2^2 >=0, total P physical with P2=s>(m1+m2)^2, and null physical p with p.P=rho>0. Let beta=sqrt(lambda(s,m1²,m2²))/s, a_min=(s+m1²-m2²-sqrt(lambda))/(2s), y=(p.k1/rho-a_min)/beta in (0,1).
dPhi2/dy = (4pi)^eps/[8pi Gamma(1-eps)] s^-eps beta^(1-2eps) [y(1-y)]^-eps,
k_perp² = -(lambda/s)y(1-y).
Full-D scalar products follow k1²=m1²,k2²=m2²,k1.k2=(s-m1²-m2²)/2. The signed evanescent square is averaged with the same (-eps)_a/(1-eps)_a ratio. For Drell-Yan the final ordered state can be {gluon k1, photon q}, masses {0,Q2}, and p is either beam. We integrate y exactly using Beta functions after expressing the rational numerator and endpoint denominators in y and 1-y; only z remains for endpoint expansion. The measurement cut Jacobian for y is 2rho beta and is included once by the density. Virtual uses the same generated current and derived Born delta Jacobian, with timelike branches retained. Both incoming PDF counterterms act by standard Mellin convolution on z, with the declared full-D Born coefficients. Any missing factor or integrated-current dimensional subtlety here?

2. The observed-gluon virtual fraction check required SU(N), exact algebra among positive constants raised to affine epsilon powers, AND the card's Born relation x+y=1. All six common master coefficients become fraction-free after these operations. We now normalize prime^epsilon and pi^epsilon with formal Laurent generators, restoring the positive real branches afterward, and reduce numerator/denominator modulo the polynomial equalities explicitly present as top-level conjuncts in the declared physical coordinate region. Denominators that become zero are rejected. The present virtual phase space has a single unit-power external delta(s+t+u), and the loop integrals have no cut slots. I realize reducing coefficient functions on support is insufficient for an external delta derivative. What is the right narrow general guard before applying these coordinate equalities to coefficient normalization? Should it be allowed for fixed external kinematic identities and simple external deltas, but require normal jets for repeated external cuts? Internal dotted phase-space masters in a generic open chamber should remain unaffected. Please distinguish the current valid unit-delta case from the extension.


## Pro response

Your Drell–Yan normalization and massive two-body density are correct in the stated factored-leptonic convention. The present reduction using x+y=1 is also valid for the virtual term supported by a single unit-power external delta. Three boundaries should be explicit: 
MS
 does not uniquely specify the positive-ϵ normalization; the integrated photon momentum in real emission must remain D-dimensional; and support reduction must be authorized by the distribution attached to the term, not merely by an equality appearing in its region declaration.

1. Drell–Yan normalization and phase space
1.1 Deriving C=N
c
	​

/(2π)∫dΦH

Define the electromagnetic current without its electromagnetic coupling,

J
μ
=
f
∑
	​

e
f
	​

ψ
ˉ
	​

f
	​

γ
μ
ψ
f
	​

,

and let

H
ab
μν
	​

=[A
ab
μ∗
	​

A
ab
ν
	​

]
incoming averages, outgoing sums
	​

.

The incoming spin/color averages are already contained in H. Set

P
D
μν
	​

(q)=−g
D
μν
	​

+
Q
2
q
μ
q
ν
	​

,q
2
=Q
2
.

After full lepton-angle integration, current conservation fixes the leptonic tensor to a scalar times this conserved-current contraction. There is no outgoing-current polarization average. 
arXiv

With electromagnetic couplings excluded from the leptonic trace, its four-dimensional integral is

∫dΦ
ℓ
+
ℓ
−
	​

(q)Tr[\slashedℓ
−
	​

γ
μ
	​

\slashedℓ
+
	​

γ
ν
	​

]=
6π
Q
2
	​

P
4,μν
	​

.

Using the physical incoming flux 1/(2s), the photon propagator squared 1/Q
4
, and the phase-space factorization

dΦ
X+ℓ
+
ℓ
−
	​

(P)=
2π
dQ
2
	​

dΦ
X+q
	​

(P)dΦ
ℓ
+
ℓ
−
	​

(q),

gives

dQ
2
d
σ
ab
	​

	​

=
3Q
2
s
2α
em
2
	​

	​

∫dΦ
X+q
	​

P
D
μν
	​

H
ab,μν
	​


in your chosen dimensional continuation of the QCD contraction.

Therefore,

C
ab
	​

(z,ϵ)=
2π
N
c
	​

	​

∫dΦ
X+q
	​

P
D
μν
	​

H
ab,μν
	​

	​


indeed yields

dQ
2
d
σ
ab
	​

	​

=
3N
c
	​

Q
2
s
4πα
em
2
	​

	​

C
ab
	​

(z,ϵ),z=
s
Q
2
	​

.
	​


There is no additional z and no 1/(D−1) average in this definition.

One adapter-level warning: if the common current backend already returns

W
μν
=
4π
1
	​

∫dΦH
μν
,

then the equivalent DY extraction is

C=2N
c
	​

P
D
	​

:W.
	​


Do not multiply that pre-normalized W by N
c
	​

/(2π) again. Likewise, the SIDIS scalar extraction 2P
T
	​

, 2P
L
	​

, or 2P
A
	​

 is not the DY extraction.

1.2 The Born factor is exactly 1−ϵ

For q
i
	​

(k
a
	​

)
q
ˉ
	​

i
	​

(k
b
	​

)→J(q),

H
0
μν
	​

=
4N
c
	​

e
i
2
	​

	​

Tr[\slashedk
b
	​

γ
μ
\slashedk
a
	​

γ
ν
].

Current conservation and 2k
a
	​

⋅k
b
	​

=s give

P
D
	​

:H
0
	​

=
N
c
	​

e
i
2
	​

	​

2
D−2
	​

s=
N
c
	​

e
i
2
	​

	​

(1−ϵ)s.

The one-particle phase space is

dΦ
1
	​

(P;q)=2πδ
+
	​

(s−Q
2
),

so

C
q
i
	​

q
ˉ
	​

i
	​

(0)
	​

(z,ϵ)=e
i
2
	​

(1−ϵ)δ(1−z).
	​


The same holds for the reversed incoming ordering. This 1−ϵ is the usual full-D Born trace factor; some DY conventions explicitly divide it out when defining their coefficient functions. 
Pure UVA
+1

Thus, unlike your normalized SIDIS Born coefficient, the DY coefficient has

[C
(0)
]
ϵ
1
	​

=−e
i
2
	​

δ(1−z),[C
(0)
]
ϵ
n
	​

=0(n≥2)

in this convention.

Retaining it in the counterterms is necessary. A simple collinear pole multiplying −ϵC
0
	​

 contributes at finite order.

1.3 What “factored leptonic convention” must mean at finite D

If the leptons themselves are integrated in D dimensions, the exact tensor is

L
D
μν
	​

=ℓ
D
	​

(Q
2
,ϵ)P
D
μν
	​

,

where direct contraction of the leptonic trace gives

ℓ
D
	​

(Q
2
,ϵ)=
D−1
2(D−2)
	​

Q
2
Φ
2
	​

(Q
2
;0,0).
	​


Here

Φ
2
	​

(Q
2
;0,0)=
8π
(4π)
ϵ
	​

Γ(2−2ϵ)
Γ(1−ϵ)
	​

(Q
2
)
−ϵ
.

At D=4, this reduces to Q
2
/(6π).

The factor 1/(D−1) above belongs to extracting the scalar leptonic coefficient, because P
D
	​

:P
D
	​

=D−1. It is not a further average to apply to the QCD tensor.

Your prescription is coherent provided you remove this entire universal scalar leptonic factor from the regulated QCD object and restore its physical four-dimensional normalization externally. Do not retain selected ϵ-dependent pieces of ℓ
D
	​

 in only some contributions.

More generally, multiplying all regulated QCD contributions by a common scalar F(Q
2
,ϵ), with F(Q
2
,0)=1, changes their positive-ϵ convention but not the finite result after consistent mass factorization:

Γ
a
−1
	​

⊗[F
C
]⊗Γ
b
−1
	​

=F[Γ
a
−1
	​

⊗
C
⊗Γ
b
−1
	​

].

This works because F depends on Q
2
, not on the convolution variable.

Therefore your definition gives a coherent standard-
MS
 finite coefficient. It is not the only possible positive-ϵ completion. For comparison with a convention that normalizes the Born coefficient to unity in D dimensions, the factor 1−ϵ must be translated consistently before comparing higher Laurent coefficients.

1.4 Standard Mellin convolutions follow from the 1/s prefactor

Let the hadronic energy be S, with s=x
a
	​

x
b
	​

S and τ=Q
2
/S. Your definition gives

dQ
2
dσ
	​

=
3N
c
	​

Q
2
S
4πα
em
2
	​

	​

a,b
∑
	​

∫
x
a
	​

dx
a
	​

	​

x
b
	​

dx
b
	​

	​

f
a
	​

(x
a
	​

)f
b
	​

(x
b
	​

)C
ab
	​

(
x
a
	​

x
b
	​

τ
	​

).

Equivalently,

dQ
2
dσ
	​

=
3N
c
	​

Q
2
S
4πα
em
2
	​

	​

a,b
∑
	​

∫
τ
1
	​

z
dz
	​

L
ab
	​

(τ/z)C
ab
	​

(z).

This is the usual luminosity-convolution organization. 
arXiv

At the partonic level, rescaling one incoming momentum by η gives

s→ηs,z→z/η,

and

∫
z
1
	​

dηΓ(η)
ηs
1
	​

C(z/η)=
s
1
	​

∫
z
1
	​

η
dη
	​

Γ(η)C(z/η).

Thus both incoming counterterms act by the standard Mellin convolution, with no extra z-weighted kernel.

Use the full-D Born coefficient in both terms. Do not normalize only the Born counterterm to e
i
2
	​

δ(1−z) while retaining 1−ϵ in the generated bare result.

2. The massive two-body provider
2.1 Geometry, normalization, and the measurement Jacobian

In the rest frame of the physical timelike P,

E
1
	​

=
2
s
	​

s+m
1
2
	​

−m
2
2
	​

	​

,∣k
1
	​

∣=
2
s
	​

λ
	​

	​

,

where

λ=λ(s,m
1
2
	​

,m
2
2
	​

).

For null physical p, let θ be the angle between p and k
1
	​

. Then

ρ
p⋅k
1
	​

	​

=
2s
s+m
1
2
	​

−m
2
2
	​

	​

−
2s
λ
	​

	​

cosθ,

so your variable is exactly

y=
2
1−cosθ
	​

.

The radial phase-space integration produces

dΦ
2
	​

=
4
s
	​

(2π)
2−D
	​

(
2
s
	​

λ
	​

	​

)
D−3
dΩ
D−2
	​

.

Changing θ to y and integrating the residual angular volume gives

dy
dΦ
2
	​

	​

=
8πΓ(1−ϵ)
(4π)
ϵ
	​

s
−ϵ
β
1−2ϵ
[y(1−y)]
−ϵ
.
	​


Consequently,

Φ
2
	​

(s;m
1
2
	​

,m
2
2
	​

)=
8π
(4π)
ϵ
	​

s
−ϵ
β
1−2ϵ
Γ(2−2ϵ)
Γ(1−ϵ)
	​

.
	​


At D=4, this is β/(8π), as required.

Your transverse invariant also follows:

k
⊥
2
	​

=−∣k
1
	​

∣
2
sin
2
θ=−
s
λ
	​

y(1−y).
	​


For a linear measurement cut,

G
y
	​

=2p⋅k
1
	​

−2ρ(a
min
	​

+βy),

the delta identity is

δ(y−
β
p⋅k
1
	​

/ρ−a
min
	​

	​

)=2ρβδ(G
y
	​

).
	​


The displayed density already contains that normalization. Multiplying it by 2ρβ again would double count the Jacobian.

There is no missing ds/dz or dQ
2
/dz factor in C(z): C is the function appearing in a cross section differentiated with respect to Q
2
, not a newly defined d
σ
/dz.

2.2 Evanescent averages remain unchanged

The physical span of P,p has Gram determinant

det(
s
ρ
	​

ρ
0
	​

)=−ρ
2

=0.

It contains a timelike direction, so its orthogonal complement is spatial. The mass dependence fixes the transverse radius but does not alter the angular ratio:

⟨(
k
^
1
2
	​

)
a
⟩=
(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

(k
⊥
2
	​

)
a
.
	​


Also,

k
^
2
	​

=−
k
^
1
	​

.

The previous domain restrictions still apply: average the complete polynomial linearly, require the remaining weight to be transverse-invariant, and do not average correlated factors separately. No new spin average is associated with a massive phase-space leg merely because its mass is nonzero.

2.3 DY specialization and the endpoint order of operations

For {k
1
	​

,q} with masses {0,Q
2
},

β=1−z,a
min
	​

=0,

and, taking p=k
a
	​

,

2k
a
	​

⋅k
1
	​

2k
b
	​

⋅k
1
	​

k
⊥
2
	​

	​

=s(1−z)y,
=s(1−z)(1−y),
=−s(1−z)
2
y(1−y).
	​

	​


Hence

dy
dΦ
2
	​

	​

=
8πΓ(1−ϵ)
(4π)
ϵ
	​

s
−ϵ
(1−z)
1−2ϵ
[y(1−y)]
−ϵ
.

Integrating y exactly before expanding the z endpoint is appropriate. For terms whose remaining denominator factors are powers of y and 1−y,

∫
0
1
	​

dyy
m−ϵ
(1−y)
n−ϵ
=B(m+1−ϵ,n+1−ϵ)

by analytic continuation. Include the angular-moment factors and their additional powers of y(1−y) before performing this integration.

The geometry is more general than a Beta-only rational-integrand evaluator. Generic massive amplitudes can contain denominators A+By with a root away from 0,1; those require additional functions or another integration method. The Beta evaluator should accept the factorization pattern it can prove, rather than assume that all two-body massive integrals have that pattern.

At threshold, β=0 and the coordinate y degenerates. Use the density on 0<z<1, integrate at finite regulator, then expand distributions in 1−z. Do not evaluate the measurement Jacobian at z=1 first. The virtual/Born term has its separate one-particle measure and does not require an artificial y-distribution.

The y-integration can generate a collinear 1/ϵ, followed by another pole from the soft z endpoint. The endpoint planner must therefore see the complete integrated coefficient; a one-variable final answer does not imply only one source of regulator poles.

2.4 The integrated photon is not a physical four-dimensional vector

This is the main dimensional issue to enforce in the current frontend.

For real emission,

q=P−k
1
	​

,
P
^
=0,

so

q
^
	​

=−
k
^
1
	​

.
	​


Although the beams and P are physical, the integrated photon momentum is D-dimensional in this phase-space prescription. Its mass constraint is

q
D
2
	​

=Q
2
,
q
ˉ
	​

2
=Q
2
−
q
^
	​

2
,

and the current contraction and Ward identity must use q
D
	​

.

Setting 
q
^
	​

=0 would also force 
k
^
1
	​

=0, contradicting the proposed dimensionally integrated two-body geometry. The distinction between full, physical, and evanescent objects must survive until the contractions have removed it; FeynCalc’s BMHV algebra explicitly distinguishes those spaces. 
FeynCalc

For the virtual term, q=P is physical automatically. Thus “current insertion” must not itself imply either Physical4 or IntegratedD; that property comes from the measurement geometry.

For the timelike virtual amplitude retain, for example,

(−Q
2
−i0)
−ϵ
=(Q
2
)
−ϵ
e
iπϵ
,

and conjugate the integrated expression. The interference contains the resulting real phase combination; replacing the timelike scalar functions by their spacelike values loses finite terms generated by poles. 
DLMF

The same geometry covers the Compton channels with a massless quark or antiquark replacing k
1
	​

. Keep the two beam orderings and flavors explicit. There is no FF or inclusive-tag multiplicity in this benchmark.

3. The narrow guard for support-dependent normalization

The right distinction is:

an identity of the kinematic parameter spaceversusan equation that only holds on a distribution’s support.
	​


Extracting only top-level conjunctive equalities is a reasonable syntactic restriction. It is not, by itself, a semantic authorization to impose those equalities on every coefficient.

3.1 Current unit-delta case: valid

Let

g=s+t+u,

and consider the current virtual term

c(s,t,u,ϵ)M(s,t,u,ϵ)δ(g).

For a multiplier with a well-defined restriction to the support,

cδ(g)=c∣
g=0
	​

δ(g).
	​


Thus replacing c by an equal rational function modulo g, or the corresponding relation x+y−1=0, is valid. This is the defining evaluation property of the delta distribution. 
DLMF

Your present setting—one external unit-power delta, ordinary virtual masters, and no external normal derivative—falls within that scope. On-support master data suffice for this case; one does not need their normal derivatives.

Preserve the delta’s defining function and Jacobian. If

g=h(x,y)[x+y−1],

with h

=0 on the support, then

δ(g)=
∣h∣
x+y=1
	​

δ(x+y−1)
	​

.

A polynomial quotient of the coefficient does not perform this distributional change of variables.

3.2 Proposed minimal authorization rule

A practical conservative guard is:

Relation being used	Permitted normalization
Exact external identity, fixed under all subsequent differentiations	Ordinary algebraic reduction
Smooth defining equation of an attached unit external delta	Restriction to its support
Defining equation of an attached differentiated external delta	Normal-jet reduction, not value-only restriction
Equation describing an endpoint of a plus distribution or regular term	No support restriction of that term
Internal cut equation involving integration variables	No external-coordinate restriction inferred from it

In addition, require that the external constraints define a regular local support, that the multiplier has the required restriction or derivatives, and that no unapplied normal differential operator will later act on information being discarded.

A useful abstract acceptance condition is

(c−c
normalized
	​

)T
external
	​

=0,
	​


where T
external
	​

 is the actual external distribution of that term. For a simple delta, the defining equation belongs to its annihilator. For a delta derivative, it generally does not.

This guard should be term-local. The Born relation must not become a global assumption for the real contribution. Under a momentum rescaling or convolution, push forward the already defined distribution; do not keep the original Born equation as an unchanged side condition.

3.3 Repeated external cuts require normal jets

With the usual reverse-unitarity normalization,

2πi
1
	​

[
(g−i0)
ν
1
	​

−
(g+i0)
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
(g).

Thus a raised cut carries derivatives of the delta, not merely the same support with a different label. 
arXiv

The elementary counterexample is

gδ
′
(g)=−δ(g),
	​


where setting g=0 in the multiplier would incorrectly give zero.

Choose local normal/tangential coordinates (g,t). Then

c(g,t)δ
(n)
(g)=
j=0
∑
n
	​

(−1)
j
(
j
n
	​

)∂
g
j
	​

c(g,t)
	​

g=0
	​

δ
(n−j)
(g).
	​


This follows directly from the definition of distributional derivatives. 
DLMF

Therefore a cut of power ν requires the normal Taylor data through order ν−1. Algebraically, retain the coefficient modulo g
ν
, not merely modulo g.

For several independent external constraints g
i
	​

 with cut powers ν
i
	​

, retain the corresponding mixed normal jets:

0≤α
i
	​

<ν
i
	​

.

In suitable local coordinates, this is the truncated algebra associated with

(g
1
ν
1
	​

	​

,…,g
c
ν
c
	​

	​

),

rather than the value-only ideal (g
1
	​

,…,g
c
	​

).

When assembling an explicit delta-derivative basis, these derivatives act on all normal-dependent factors: rational coefficients, measure Jacobians, analytic prefactors, and master functions. A coefficient-only jet is not enough if the master’s normal dependence has already been discarded. The actual cut/deformation definition must determine that continuation; an arbitrary extension of an on-shell master is not sufficient.

Likewise, nonlinear changes of the normal coordinate generate lower-order delta derivatives. Preserve the original cut definition until the transformation has been carried out.

3.4 Denominator and differentiation qualifications

Rejecting denominators that reduce identically to zero is necessary, but not sufficient for unrestricted use over a support. A nonzero polynomial remainder can still vanish on part of that support. Work in a declared open chart where the relevant denominators are nonzero, or retain the necessary singular-locus information.

Before restriction, cancel genuinely removable factors in the complete rational coefficient. If numerator and denominator both vanish on the support, a 0/0 substitution is not a valid restriction. A removable extension may exist, but it requires an actual cancellation or local-limit calculation.

Also distinguish a coefficient certified on support from an off-support function available for differentiation. A later normal derivative cannot act on the former as though it retained the discarded dependence. Perform normal restriction or jet construction at exact ϵ, then feed the resulting regulator valuations into the epsilon-order planner.

3.5 Internal dotted masters should not trigger this guard

An internal dotted phase-space master

M
ν
	​

(s,t,u,ϵ)

can be an ordinary function of external invariants throughout an open chamber. Its internal delta derivatives do not make it an external distribution supported on s+t+u=0.

Consequently, do not reject coefficient normalization merely because a master has dotted cut slots. The guard concerns the external distribution and the particular coordinate equation being imposed.

Conversely, internal cuts do not authorize imposing a Born relation on an otherwise open external chamber. The relevant information is the origin and role of the constraint, not a global count of cut powers.

4. Positive-constant epsilon generators

Your normalization of positive constants is mathematically sound:

c
a+bϵ
=c
a
exp(bϵlnc),c>0,

with the real logarithm. Multiplicative identities among such constants can therefore be imposed exactly before restoring the analytic representation. 
DLMF

The generator declaration must preserve all intended exponent relations. For example,

4
ϵ
=(2
ϵ
)
2
,(2
ϵ/2
)
2
=2
ϵ
.

For rational affine slopes, a common fractional-exponent generator avoids accidentally treating related powers as independent.

Keep this normalization separate from prescription-bearing powers such as

(−s−i0)
a+bϵ
.

They cannot be reduced by positive-real power rules with the phase discarded. Kinematic powers also differ from numerical constants when normal jets are needed: their derivatives must be retained.

This gives the appropriate scope for the present result: the six coefficients may be normalized using the declared color algebra, exact positive-constant identities, and the unit-delta Born support. The extension to repeated external cuts should be disabled unless the required normal-jet data are available. That restriction leaves ordinary internal dotted masters and open-chamber coefficient algebra unaffected.