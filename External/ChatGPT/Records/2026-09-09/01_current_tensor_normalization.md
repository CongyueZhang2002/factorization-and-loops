# Current tensor normalization

Verified model: gpt-6-pro. Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a. Request: dd9bd845-b2ba-484d-a061-d3d14fad0b21.

## Question

Continue the verified GPT-6 Pro review. Repository https://github.com/CongyueZhang2002/factorization-and-loops; local dirty working tree ahead. We have now generated distinct-flavor annihilation NLO UU and incoming-LL from diagrams, all counterterms, in 149/161 seconds; all 32 UU INCNLO coefficients and four exact LL=-UU identities pass. Full qg channels are running. Joint normal-crossing endpoint subtraction now uses commuting endpoint restrictions and finite Laurent products; exact regulated-moment tests pass.

Before implementing the current front end, review these precise dimensional/normalization issues. We must avoid importing process hard functions or fitting Born factors. Existing factorization front end attaches hadron vectors and fraction/dual-null-vector data to every PDF/FF leg, then removes distributions. Quark correlators use four-dimensional GS[n]/2 plus BMHV gamma5 structures. It automatically sets evanescent components to zero for declared external vectors other than phase-space integration momenta. This is appropriate for the existing fixed-observed-momentum pp calculation but is not obviously a sound representation for transverse-momentum-integrated SIDIS: the tagged outgoing parton itself becomes a D-dimensional integrated momentum, constrained only by z.

Proposed generalization: distinguish current insertions, factorized parton spin-density operators, and on-shell cuts. Keep the diagram-generation amplitude converter; retain the current Lorentz indices by replacing external photon wavefunction slots before contraction, and contract with a Hermitian current projector before scalar Hermitian completion. Replace hadronic-coordinate-dependent correlator removal for these inclusive current tensors by normalized partonic PDF/FF projectors defined centrally in Physics/Distributions.wl. Incoming massless p is physical four-dimensional; tagged outgoing unpolarized k remains D-dimensional. The source is exact in D until final epsilon demands. Current photon carries no spin average or massless two-parton flux. No leptonic tensor is included in the QCD coefficient object.

Please pin down a coherent from-definitions convention:
1. For incoming U quark/antiquark and incoming L quark/antiquark, and unpolarized tagged outgoing quark/antiquark, what spin-density matrices, signs, color factors and averaging factors should replace spinor sums? In particular, outgoing unpolarized fragmentation should retain GSD[k], not prematurely project k to four dimensions. Reconcile these with the PDF and FF convolution measures. Incoming U gluon can use the D-2 average, incoming L gluon a BMHV four-dimensional antisymmetric tensor; unpolarized outgoing gluon D1 should be an unaveraged transverse sum.
2. Define the normalization of the partonic current tensor and its exact-D dual projections, including 1/(4 pi), one-particle phase space, and the fragmentation measurement Jacobian, so the standard electromagnetic SIDIS FT, FL, g1 coefficient normalizations follow algebraically. For example with r=p-(p.q/q^2)q, BL=r r/r^2, BT=-g+q q/q^2+BL, PT=BT/(D-2), PL=BL. The coefficient of BT is F1 and that of BL is FL/(2x), so FT=2x F1; the usual antisymmetric tensor gives g1. Which additional x/z factors depend on choosing tensor structure functions versus coefficient functions C_T,C_L,Delta C? Preserve exact eps and clarify the difference between convention and a fitted normalization.
3. How should the BMHV-to-helicity-MSbar finite PDF kernel already used at hadronic NLO extend here? Do we need a distinct finite FF factor for integrating an unpolarized tagged parton in D dimensions, or is this precisely the usual unpolarized timelike MSbar definition? Universal operator renormalization is allowed, process-specific finite patches are not.
4. Can the same normalized spin-density/operator interface be used for inclusive timelike DY with no FF and for fixed-pT hadroproduction, so this becomes a general front-end extension rather than a second process-specific production path? Identify any genuine evanescent projector issues before implementation.

Please distinguish established identities from assumptions that need verification. No assurance of full NNLO completion based solely on these interfaces.

## Pro response

The proposed separation is correct. In particular, the tagged SIDIS momentum must remain D-dimensional when it is integrated, and the outgoing unpolarized cut carries a spin/color sum, not another incoming-state average. Two qualifications are essential: the current-index continuation must match its dual projectors, and the normalized partonic spin matrices must be distinguished from the projectors that extract scalar PDFs or FFs from operator matrix elements.

Below is one coherent convention in which the electromagnetic Born normalization follows directly from the current definition, spin sums, and phase space. No hard-function normalization is fitted.

1. Normalized partonic spin and color insertions

Take

D=4−2ϵ,g
μν
=diag(1,−1,−1,−1)on the physical subspace,
Tr1=4,γ
5
	​

=iγ
0
γ
1
γ
2
γ
3
,ε
0123
=+1.

In BMHV,

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
]=0.

The split between D, four, and D−4 dimensions is part of the algebra, not an optional simplification. FeynCalc implements that algebra, but does not itself supply the required finite operator-scheme transformations. 
FeynCalc

Let h=±1 denote physical particle helicity, with

f=f
+
	​

+f
−
	​

,Δf=f
+
	​

−f
−
	​

.

The coefficient multiplying Δf therefore uses the half-difference of the two partonic helicity cross sections, not their full difference. This is the polarized-PDF convention used in the updated SIDIS calculation. 
arXiv

Quarks and antiquarks

For a physical, massless incoming momentum p=
p
ˉ
	​

,

u
h
	​

(p)
u
ˉ
h
	​

(p)=
2
1+hγ
5
	​

	​

\slashedp,v
h
	​

(p)
v
ˉ
h
	​

(p)=
2
1−hγ
5
	​

	​

\slashedp.

Consequently, the following table applies to the literal spinor outer products in the amplitude and its conjugate:

Leg and polarization	Spin insertion	Color insertion
Incoming q, U	\slashedp/2	δ
ij
	​

/N
c
	​


Incoming 
q
ˉ
	​

, U	\slashedp/2	δ
ij
	​

/N
c
	​


Incoming q, L	γ
5
	​

\slashedp/2=−\slashedpγ
5
	​

/2	δ
ij
	​

/N
c
	​


Incoming 
q
ˉ
	​

, L	−γ
5
	​

\slashedp/2=+\slashedpγ
5
	​

/2	δ
ij
	​

/N
c
	​


Outgoing tagged q, U	\slashedk
D
	​

	δ
ij
	​


Outgoing tagged 
q
ˉ
	​

, U	\slashedk
D
	​

	δ
ij
	​


The first four rows already contain the incoming spin normalization. Do not also multiply the assembled result by a global 1/2 for each such leg.

There is no extra minus sign in the unpolarized antiquark cut:

h
∑
	​

v
h
	​

(k)
v
ˉ
h
	​

(k)=\slashedk
D
	​

.

Fermion-flow reversal, exchange signs, and the ordering of the resulting trace belong to the diagram algebra.

The longitudinal signs require care when translating your existing correlators. A coefficient multiplying \slashednγ
5
	​

, a coefficient multiplying γ
5
	​

\slashedn, and an antiquark correlator with transposed Dirac indices are not interchangeable conventions. The table fixes the convention at the spinor-outer-product level; derive the map from the existing Φ,
Φ
ˉ
 definitions to it.

Your incoming-LL checks cannot alone determine the absolute single-helicity sign: reversing every longitudinal insertion leaves a two-incoming-helicity observable unchanged. A current-tensor g
1
	​

 test or a direct helicity-spinor test is needed to fix that remaining convention.

Gluons

For null v,n, define

d
D
αβ
	​

(v,n)=−g
D
αβ
	​

+
v⋅n
v
α
n
β
+n
α
v
β
	​

,N
A
	​

=N
c
2
	​

−1.

The unpolarized incoming insertion is

ρ
g,U
AB;αβ
	​

(p,n)=
N
A
	​

(D−2)
δ
AB
	​

d
D
αβ
	​

(p,n).
	​


For incoming longitudinal polarization, define the index order first: let α be the polarization slot in the amplitude and β the slot in its conjugate. Then

ρ
g,L
AB;αβ
	​

=
2N
A
	​

δ
AB
	​

(ϵ
+
α
	​

ϵ
+
β∗
	​

−ϵ
−
α
	​

ϵ
−
β∗
	​

).

For p along +z, a reference n along −z, and
ϵ
±
	​

=(0,1,±i,0)/
2
	​

, this becomes

ρ
g,L
AB;αβ
	​

=−
2N
A
	​

iδ
AB
	​

p⋅n
ε
αβρσ
p
ρ
	​

n
σ
	​

	​

.
	​


Reversing the amplitude/conjugate index order reverses this antisymmetric sign.

Thus the longitudinal insertion has a physical-helicity factor 1/2, not 1/(D−2). Using a D−2 unpolarized average and a four-dimensional helicity difference defines a dimensional continuation; at nonzero ϵ, they should not be interpreted as the sum and difference of only two states.

The outgoing unpolarized gluon insertion is

ρ
g,out
AB;αβ
	​

(k,n)=δ
AB
d
D
αβ
	​

(k,n),
	​


without either incoming average. Reference-vector dependence must cancel in the gauge-complete amplitude/interference sum. Replacing d
D
	​

 by −g
D
	​

 is not justified diagram by diagram merely because the eventual answer is gauge invariant.

Why the FF does not introduce another outgoing average

The scalar FF’s operator definition contains a normalized spin/color extraction. For example, the standard dimensionally regulated quark-FF definition has the characteristic prefactor z
D−3
/(4N
c
	​

) multiplying a light-cone Dirac/color trace, with the Fourier measure and future-pointing gauge links. 
arXiv

That extraction is dual to the hard-side embedding. It does not mean that a hard process producing a tagged quark should use \slashedk/(2N
c
	​

). The hard coefficient sums over the produced parton’s spin and color; the FF describes fragmentation from the corresponding unpolarized parent.

Accordingly, distinguish two operations in the registry:

extract a scalar PDF/FF from an operator matrix element

=insert its normalized hard-side spin/color tensor.
2. Define the current tensor before defining coefficient functions

Let

J
em
μ
	​

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

where e
f
	​

 is the dimensionless quark charge. The electromagnetic coupling e, photon propagator, leptonic tensor, and physical scattering flux are outside this QCD object.

Write

A
a
ν
	​

(F)=⟨F∣J
em
ν
	​

∣a(p)⟩.

For definiteness, use the current-index order

A
a
μ∗
	​

A
a
ν
	​

.

This choice matters for the sign of the antisymmetric projector.

For b the tagged species and χ=U,Δ, define the tensor density per dz by

w
ba,χ
μν
	​

(p,q,z;ϵ)=
	​

4π
1
	​

F
∑
	​

S
F
	​

1
	​

∫dΦ
F
	​

(p+q)
×
t∈F
∑
	​

1
species(t)=b
	​

δ(z−
p⋅q
p⋅k
t
	​

	​

)[A
a
μ∗
	​

(F)A
a
ν
	​

(F)]
ρ
a,χ
	​

	​

.
	​

	​


All final spin/color sums are understood, and the initial averages are already in ρ
a,χ
	​

. S
F
	​

 is the final-state symmetry factor for the chosen labeled phase-space convention.

There is no photon spin average and no 1/(2s) factor here.

Phase-space and measurement normalization

Use

dΦ
F
	​

(K)=(2π)
D
δ
(D)
(K−
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

.

For one massless particle,

dΦ
1
	​

(K)=2πθ(K
0
)δ(K
2
).
	​


This identity is exact in D. No (4π)
ϵ
 or gamma-function factor is generated by one-particle phase space.

Set

p
2
=0,q
2
=−Q
2
,x=
2p⋅q
Q
2
	​

.

The fragmentation measurement can be compiled into the linear cut

G
z
	​

(k)=2p⋅k−
x
zQ
2
	​

,

with

δ(z−
p⋅q
p⋅k
	​

)=
x
Q
2
	​

δ(G
z
	​

(k)).
	​


That Jacobian is compulsory. There is no additional 1/z in this partonic measurement: the later FF convolution produces its own dζ/ζ.

Exact-D symmetric dual projectors

With

r
μ
=p
μ
−
q
2
p⋅q
	​

q
μ
,r
2
=
Q
2
(p⋅q)
2
	​

,

define

B
L
μν
	​

=
r
2
r
μ
r
ν
	​

,B
T
μν
	​

=−g
D
μν
	​

+
q
2
q
μ
q
ν
	​

+B
L
μν
	​

.

Direct contraction gives

B
T
	​

:B
T
	​

=D−2,B
L
	​

:B
L
	​

=1,B
T
	​

:B
L
	​

=0.

Therefore

P
T
	​

=
D−2
B
T
	​

	​

,P
L
	​

=B
L
	​

.

For the integrated unpolarized tensor,

w
U
μν
	​

=B
T
μν
	​

F
1
	​

+B
L
μν
	​

2x
F
L
	​

	​

,

so

F
1
	​

=P
T
	​

:w
U
	​

,
F
L
	​

=2xP
L
	​

:w
U
	​

,
F
T
	​

=2xP
T
	​

:w
U
	​

.
	​


The 1/(D−2) here is a dual-basis normalization, not a photon spin average.

BMHV antisymmetric dual projector

With the current-index order specified above, define

A
μν
=
p⋅q
iε
μνρσ
p
ρ
	​

q
σ
	​

	​

.

The Levi-Civita tensor is four-dimensional. Direct contraction yields

A:A=−2,A
∗
:A=2.

Thus

P
A,μν
	​

=−
2
1
	​

A
μν
	​

,P
A
	​

:A=1,
g
	​

1
	​

=P
A
	​

:w
Δ
	​

.
	​


Here w
Δ
	​

 is the half-difference of target-parton helicities. “Δ” avoids confusing it with the longitudinal-photon projection P
L
	​

.

All three projectors satisfy the appropriate Hermitian condition

P
μν
∗
	​

=P
νμ
	​

.

Contracting with them before scalar Hermitian completion is therefore sound. Taking a componentwise real part of the unprojected tensor would still destroy the antisymmetric contribution.

Born normalization follows without a calibration factor

For the tree process J(q)+q(p)→q(k),

k=p+q,k
2
=
x
Q
2
(1−x)
	​

,

and hence

δ(k
2
)=
Q
2
1
	​

δ(1−x),δ(z−
p⋅q
p⋅k
	​

)=δ(1−z).

The color average and final color sum cancel. The unpolarized spin trace is

T
U
μν
	​

=
2
e
q
2
	​

	​

Tr[\slashedpγ
μ
\slashedkγ
ν
]=2e
q
2
	​

(p
μ
k
ν
+p
ν
k
μ
−g
D
μν
	​

p⋅k).

On the one-particle support,

T
U
μν
	​

=e
q
2
	​

Q
2
B
T
μν
	​

.

With the stated helicity and Levi-Civita conventions, the corresponding helicity trace is

T
Δ
μν
	​

=e
q
2
	​

Q
2
A
μν
.

Combining the trace with dΦ
1
	​

/(4π) gives

w
U
(0)μν
	​

=
2
e
q
2
	​

	​

δ(1−x)δ(1−z)B
T
μν
	​

,
	​

w
Δ
(0)μν
	​

=
2
e
q
2
	​

	​

δ(1−x)δ(1−z)A
μν
.
	​


These are exact-D identities in this convention.

For an incoming antiquark, the opposite helicity-density sign is accompanied by reversal of the fermion-line trace ordering. Its electromagnetic g
1
	​

 Born contribution consequently has the same positive charge-squared normalization, not its negative.

This is the appropriate Born test: evaluate the definitions and demand these identities. Do not divide subsequent results by a numerically or symbolically inferred Born ratio.

3. Where the x and z factors belong

Let

p=ξP,x=
ξ
x
B
	​

	​

,z=
ζ
z
h
	​

	​

,

where ζ is the hadron’s fragmentation fraction relative to the tagged parton.

Choose number-density PDFs and FFs, with the conventional convolution

[f⊗C⊗D](x
B
	​

,z
h
	​

)=∫
x
B
	​

1
	​

ξ
dξ
	​

∫
z
h
	​

1
	​

ζ
dζ
	​

f(ξ)C(
ξ
x
B
	​

	​

,
ζ
z
h
	​

	​

)D(ζ).

After UV and collinear factorization, define the finite coefficient functions by

C
T
	​

=2P
T
	​

:w
U
fin
	​

,C
L
	​

=2P
L
	​

:w
U
fin
	​

,ΔC=2P
A
	​

:w
Δ
fin
	​

.
	​


Equivalently,

C
T
	​

=
x
F
T
fin
	​

	​

,C
L
	​

=
x
F
L
fin
	​

	​

,ΔC=2
g
	​

1
fin
	​

.

The physical leading-power structure functions are then

F
T
h
	​

(x
B
	​

,z
h
	​

)
F
L
h
	​

(x
B
	​

,z
h
	​

)
2g
1
h
	​

(x
B
	​

,z
h
	​

)
	​

=x
B
	​

a,b
∑
	​

f
a
	​

⊗C
T,ba
	​

⊗D
b
h
	​

,
=x
B
	​

a,b
∑
	​

f
a
	​

⊗C
L,ba
	​

⊗D
b
h
	​

,
=
a,b
∑
	​

Δf
a
	​

⊗ΔC
ba
	​

⊗D
b
h
	​

.
	​

	​


In particular, 2F
1
h
	​

, rather than F
T
h
	​

, has a convolution without the overall x
B
	​

. The updated polarized SIDIS paper explicitly uses the 2F
1
	​

 and 2g
1
	​

 coefficient conventions. 
arXiv

The Born result above therefore gives

C
T
(0)
	​

=ΔC
(0)
=e
q
2
	​

δ(1−x)δ(1−z),C
L
(0)
	​

=0.

Born agreement alone cannot distinguish these x/z conventions. For example, multiplication by x or z leaves the Born double delta unchanged. The convention must be fixed by the tensor decomposition and convolution definition, not inferred from agreement at x=z=1.

Origin of the convolution measures

For quarks, the incoming 1/ξ can already be seen in the relation between the hadronic leading-twist embedding and the normalized partonic one:

\slashedP=
ξ
\slashedp
	​

.

The full operator factorization supplies the analogous measure for every incoming species.

On the fragmentation side, the number-density measurement gives directly

∫dζD(ζ)∫dzw(z)δ(z
h
	​

−ζz)=∫
ζ
dζ
	​

D(ζ)w(z
h
	​

/ζ).

Thus the convolution’s 1/ζ is not an outgoing spin average and is not the partonic linear-cut Jacobian.

For comparison, when the invariant observed spectrum itself is continued to D dimensions,

E
h
	​

d
D−1
P
h
	​

dσ
h
	​

	​

=
b
∑
	​

∫dζζ
−(D−2)
D
b
h
	​

(ζ)E
k
	​

d
D−1
k
d
σ
b
	​

	​

	​

k=P
h
	​

/ζ
	​

.

The factor follows from

dΠ(P
h
	​

)=ζ
D−2
dΠ(k).

Integrating the observed momentum and imposing z
h
	​

=ζz cancels that invariant-measure power and leaves dζ/ζ. The standard bare FF definition’s D-dependent powers must be used consistently with this continuation. 
arXiv

The publicly visible adapter contains an outgoing 2/ζ
3
 factor and sends both GS and GSD through the same hadronic correlator replacement. Those belong to its existing correlator/measure convention; they must not be copied into the new dz-density definition.

Changing to momentum-weighted distributions such as ξf(ξ) or ζD(ζ) is allowed, but shifts explicit powers into the coefficient functions. Apply such changes as distributional multiplication, not only to regular pieces.

4. Genuine evanescent issues to resolve before implementation
The tagged momentum is not a physical external vector

For an integrated tagged momentum,

k
2
=0⟹
k
ˉ
2
=−
k
^
2
,

not 
k
ˉ
2
=0.

Moreover, if momentum conservation eliminates it,

k=p+q−
i
∑
	​

ℓ
i
	​

,
k
^
=−
i
∑
	​

ℓ
^
i
	​

.

It remains D-dimensional even if it is an “external leg” of the amplitude or no longer an independent integration variable.

Consequently,

(\slashedk
D
	​

)
2
=0,(\slashed
k
ˉ
)
2
=−
k
^
2
.

Replacing GSD[k] by GS[k] prematurely is not merely selecting another normalization. It changes the cut spin sum and can invalidate the Dirac-equation manipulations used in Ward identities.

The dimensional declaration should therefore attach to the integration geometry, and propagate through momentum conservation. “External to the loop amplitude” must not imply “physical four-dimensional.”

For example, under an invariant transverse angular integration,

∫k
⊥
μ
	​

k
⊥
ν
	​

F=
D−2
g
⊥,D
μν
	​

	​

∫k
⊥
2
	​

F,

so

∫
k
^
2
F=
D−2
D−4
	​

∫k
⊥
2
	​

F.

These terms are O(ϵ), but can contribute finite terms when multiplied by poles. This is an algebraic reason to preserve them, independent of any reference hard function.

Physical external momenta do not force physical current indices

There are two possible current-index continuations:

J
D
μ
	​

,B
T
D
	​

,P
T
D
	​

=B
T
D
	​

/(D−2),

or a consistently physically projected current with

J
phys
μ
ˉ
	​

	​

,
B
ˉ
T
	​

,
P
ˉ
T
	​

=
B
ˉ
T
	​

/2.

For the proposed front end, the first is the straightforward choice for UU. Keep the vector-current vertex D-dimensional, then apply the exact-D dual.

A mixed implementation—physically projected current indices but the D-dimensional dual—already changes the Born transverse projection by

D−2
2
	​

=
1−ϵ
1
	​

.

That is not a harmless difference once poles occur.

Likewise, the BMHV antisymmetric dual above has denominator 2. Treating pairs of Levi-Civita tensors with a D-dimensional determinant changes the corresponding norm to one involving

(D−2)(D−3)=2(1−ϵ)(1−2ϵ).

That is a Larin-type continuation, not the four-dimensional BMHV contraction used above. Do not combine its normalization factors with otherwise four-dimensional epsilon algebra.

JHEP03(2026)109 discusses a nontrivial Larin quark-projector correction, but explicitly establishes that its g
1
	​

 projection is unaffected by that particular modification. It is not a reason to insert an additional factor into your electromagnetic BMHV g
1
	​

 projector. Its separate flavor-scheme correction remains relevant. 
Springer

Exact source versus stored epsilon windows

Keep these objects exact or expandable on demand:

D−2
1
	​

,d
D
μν
	​

,\slashedk
D
	​

,phase-space factors,operator/measurement Jacobians.

Only downstream coefficient objects should receive planned Laurent windows.

The exact-D electromagnetic Born identities derived above happen to have no residual epsilon dependence after projection. That does not license truncating other Born channels, unresolved-limit tensors, or virtual prefactors.

5. Finite PDF matching, and why no new unpolarized FF factor is needed

Define the polarized PDF scheme transformation with an explicit direction:

Δf
H
=Z
H←B
	​

⊗
x
	​

Δf
B
,

where B denotes the precisely defined BMHV minimal-subtraction operator convention and H the chosen helicity-
MS
 convention.

Then the hard coefficient transforms oppositely:

ΔC
H
=ΔC
B
⊗
x
	​

Z
H←B
−1
	​

.
	​


With a
s
	​

=α
s
	​

/(2π), the conventional NLO quark helicity-restoring kernel is

Z
H←B
	​

=I+a
s
	​

z
(1)
+O(a
s
2
	​

),z
qq
(1)
	​

(x)=−4C
F
	​

(1−x),

with the corresponding antiquark diagonal term. This is universal operator renormalization, not a SIDIS hard-function correction. 
D-NB
+1

Thus

ΔC
H
(1)
	​

=ΔC
B
(1)
	​

−ΔC
(0)
⊗
x
	​

z
(1)
.

Your existing NLO kernel extends unchanged provided it represents this same operator transformation. Check whether the stored object is Z, Z
−1
, or the finite term already included in a modified collinear counterterm. Applying it again after such a subtraction would double count it.

At NNLO, matrix inversion gives

ΔC
H
(2)
	​

=ΔC
B
(2)
	​

−ΔC
B
(1)
	​

⊗
x
	​

z
(1)
+ΔC
(0)
⊗
x
	​

(z
(1)
⊗
x
	​

z
(1)
−z
(2)
).
	​


The higher-order z
(2)
 must be supplied in full flavor space. The corrected quark, antiquark, and pure-singlet assignments in JHEP03(2026)109 are relevant here; equal sums of incorrectly assigned channels are insufficient. 
Springer

Also, an NLO BMHV check does not by itself establish that every higher-order Larin operator normalization can be reused without translation. Use the higher-order transformation for the exact raw operator definition, or establish the universal BMHV–Larin matching. This is a matching requirement, not evidence that the schemes are inequivalent.

Final-state unpolarized fragmentation

For the standard dimensionally regulated unpolarized FF operator, with

\slashedk
D
	​

ord
D
αβ
	​

(k,n)

on the hard side and ordinary timelike 
MS
 collinear subtraction,

Z
F,additional finite
	​

=I.
	​


There is no additional helicity-restoring FF factor merely because the incoming PDF is polarized or because the tagged momentum is integrated in D dimensions. The updated polarized SIDIS calculation likewise uses polarized initial-state factorization and ordinary unpolarized final-state fragmentation. 
arXiv

This does not set final-state mass factorization to the identity: the ordinary timelike transition matrix and its poles remain necessary.

A four-dimensional tagged spin sum combined inconsistently with a D-dimensional measurement is not automatically repaired by a universal “SIDIS FF factor.” First determine whether it defines a legitimate alternative FF scheme or is simply an inconsistent cut calculation.

Finally, the electromagnetic vertex remains a vector current. Do not attach an axial-current finite Z
5
	​

 to that photon vertex in addition to the polarized-PDF transformation.

6. One front end, with distinct observable adapters

The normalized spin/operator layer can serve all three applications. Its input must distinguish at least:

Wolfram Language
<|
  "Role" -> "PDF" | "FF",
  "Species" -> species,
  "Polarization" -> "U" | "L",
  "Momentum" -> momentum,
  "MomentumSpace" -> "Physical4" | "IntegratedD",
  "SpinContinuation" -> spinPrescription,
  "OperatorScheme" -> operatorScheme,
  "IndexOrder" -> indexOrder
|>

Its output should contain the hard-side spin tensor, color tensor, and whether averages are already included. Keep scalar operator extraction projectors separately identified. Fractions and hadron-coordinate embeddings are optional adapters, not prerequisites for constructing these tensors.

The observable layer supplies the current insertion, tensor normalization, phase space, tagging measurement, external flux where applicable, and the conversion from tensor scalars to named coefficient functions.

For inclusive DY, use the same incoming quark/gluon density matrices and the same electromagnetic current insertion, with timelike momentum and no FF. Its tensor basis and outer leptonic/flux normalization are those of the DY observable; they are not obtained by blindly reusing the SIDIS P
T
	​

,P
L
	​

.

For fixed-p
T
	​

 hadroproduction, use the same hard-side density definitions but declare the fixed observed momentum physical when that is the chosen regulator prescription. Then GSD[k] and GS[k] coincide for that momentum. The observed-spectrum Jacobian and the physical partonic flux belong to the hadroproduction adapter.

One remaining distinction matters especially for gluons: a physical four-dimensional momentum does not determine whether its spin sum contains two or D−2 polarizations. Preserve the verified fixed-p
T
	​

 spin continuation, or supply its universal scheme conversion when changing it.

Keeping the diagram converter is reasonable, but the current wavefunction must be removed before any transformation uses a massless-photon condition or physical-polarization assumption. The public converter currently enables contraction during conversion, so this ordering deserves a direct test rather than an assumption.

Implementation gates

The established algebra above gives a compact set of acceptance conditions:

Spin/color and sign tests: reproduce the explicit helicity outer products and the exact-D quark and antiquark Born tensors, including P
L
	​

:w
(0)
=0. No fitted ratios.

Dimensional and gauge tests: preserve 
k
^
=−∑
i
	​

ℓ
^
i
	​

, verify current Ward identities, and cancel gluon reference-vector dependence without dropping evanescent terms.

Operator/measurement tests: derive the dξ/ξdζ/ζ convention from the chosen embeddings and measurement; verify the energy-weighted sum over all eligible tags against the separately defined inclusive current tensor.

Scheme and regression tests: reproduce the universal spacelike/timelike collinear subtraction and finite PDF rotation, then show that the legacy fixed-p
T
	​

 adapter maps into the same normalized hard-side tensors with its own measure intact.

The architectural boundary should be: universal spin/operator definitions, explicit dimensional geometry, and observable-specific measurements—not a second SIDIS production pipeline. The remaining unverified points are the implementation’s index/sign mapping, its preservation of integrated evanescent momenta, and its exact operator-scheme matching. The interface definitions settle how those tests should be formulated; they do not establish that the NNLO ingredients or their assembly are complete.