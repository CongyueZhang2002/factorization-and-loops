# Integrated SIDIS two-particle phase space and BMHV angular moments

Verified outgoing model: gpt-6-pro; thinking effort: standard; HTTP 200.
Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.
Request: 5b51f9de-71e0-4f83-877b-8c5d8b3fffc9.

## Question

Continue the integrated electromagnetic SIDIS framework review. Repository: https://github.com/CongyueZhang2002/factorization-and-loops, active unpushed work is on codex/scientific-terminology-and-math-fixes. No imported hard coefficients may enter production.

We have now generated the FeynArts quark/photon Born vertex through a shared FCFAConvert path with Contract->False, TransversePolarizationVectors->{}, then replacing the external polarization Momentum by a D-dimensional open current index before any contraction. Exactly one electromagnetic coupling e is removed by a linear-degree check; the generated 2/3 and -1/3 flavor charges remain. Normalized incoming spin density is slash(p)/2 or gamma5.slash(p)/2 (antiquark minus sign), outgoing integrated tagged quark slash(k) in D. Current index order is conjugate, amplitude. The eight generated-vertex tests pass C_T=e_q^2, C_L=0 and DeltaC=e_q^2 including antiquark, exact-D color average and the off-shell Ward identity, using dPhi1/(4pi)=delta(1-x)/(2 Q^2). We have not generated a complete NLO SIDIS coefficient yet.

Please audit the next GENERAL phase-space provider, especially BMHV evanescent angular terms:
p^2=0, q^2=-Q^2, 2p.q=Q^2/x, P=p+q, sX=P^2=Q^2(1-x)/x. Two massless outgoing momenta k+r=P, both D-dimensional, with a tagged measurement z=p.k/(p.q).
Proposed exact density:
dPhi_2/dz = (4pi)^epsilon/[8pi Gamma(1-epsilon)] * sX^(-epsilon) * [z(1-z)]^(-epsilon).
Proposed invariants: 2p.k=z Q^2/x, 2p.r=(1-z)Q^2/x, 2k.r=sX, 2q.k=sX-z Q^2/x, 2q.r=sX-(1-z)Q^2/x.
The eliminated tagged momentum must retain its evanescent component. For a Lorentz scalar projected hard tensor depending only on (p,q,k) and BMHV gamma5, its leftover angular dependence should be polynomial in k_hat^2. We propose
< (k_hat^2)^a > = Pochhammer((D-4)/2,a)/Pochhammer((D-2)/2,a) * (k_perp^2)^a,
where k_perp is orthogonal to physical p and q and k_perp^2=-sX*z*(1-z).
Both metric signs and the analytic continuation of the angular average matter. Is this sufficient for every NLO UU (transverse and longitudinal) / incoming LL g1 channel gamma*q->qg and gamma*g->q qbar, including observed gluon vs observed quark? What residual structures would invalidate this provider? Please derive/check the normalization by integrating over z and explain precisely where no additional 1/z or FF spin-average factor enters.
Also specify the forward/conjugate loop normalization needed to reuse the existing exact-epsilon one-loop quark form factor integrals with this current tensor. We want the NLO bare coefficient through epsilon one for NNLO counterterms, with enough extra smooth-factor coefficients at x/z corners determined by our endpoint-order planner. Flag any false assumption, charge/flavor multiplicity issue, or missing finite helicity scheme conversion; do not solve the process by supplying final literature coefficient functions.


## Pro response

Your two-body density, invariant relations, and Pochhammer angular-moment formula are correct. They suffice for the stated NLO real channels after complete scalar projection and reduction to the single evanescent invariant 
k
^
2
. The important qualifications are that the angular average is a linear, not multiplicative, operation; every positive-power evanescent moment starts at O(ϵ), not O(ϵ
a
); and the loop normalization must distinguish conjugation of the integration measure from reversal of propagator prescriptions.

The following checks use your supplied definitions. The named branch was not retrievable remotely, so observations about the public normalization code below are not assertions about the unpushed implementation.

1. Kinematics and phase-space normalization

Write s=s
X
	​

>0 and introduce the physical null vector

n=q+xp,n
2
=0,2p⋅n=
x
Q
2
	​

.

Then

P=n+(1−x)p.

A useful exact decomposition is

k
r
	​

=zn+(1−x)(1−z)p+k
⊥
	​

,
=(1−z)n+(1−x)zp−k
⊥
	​

,
	​

	​

p⋅k
⊥
	​

=n⋅k
⊥
	​

=0.

The on-shell conditions give

k
⊥
2
	​

=−sz(1−z).
	​


Because p,q,n are physical, 
k
^
=
k
^
⊥
	​

 and 
r
^
=−
k
^
.

Your invariant relations consequently follow:

2p⋅k
2q⋅k
	​

=
x
zQ
2
	​

,
=s−
x
zQ
2
	​

,
	​

2p⋅r
2q⋅r
	​

=
x
(1−z)Q
2
	​

,
=s−
x
(1−z)Q
2
	​

.
	​

2k⋅r
=s,

They are full D-dimensional scalar products. They do not imply that k or r has zero evanescent component.

Derivation of the density

Use the phase-space convention already adopted for the Born calculation:

dΦ
2
	​

(P)=(2π)
D
δ
(D)
(P−k−r)
(2π)
D−1
2E
k
	​

d
D−1
k
	​

(2π)
D−1
2E
r
	​

d
D−1
r
	​

.

In the rest frame of P, let θ be the angle between p and k. Since E
k
	​

=
s
	​

/2,

z=
p⋅P
p⋅k
	​

=
2
1−cosθ
	​

.

After the radial integration,

dΦ
2
	​

=
8
(2π)
2−D
	​

(
2
s
	​

	​

)
D−4
dΩ
D−2
	​

.

Using

dΩ
D−2
	​

=(sinθ)
D−3
dθdΩ
D−3
	​

,Ω
m
	​

=
Γ((m+1)/2)
2π
(m+1)/2
	​

,

and integrating the remaining angular volume gives precisely

ρ
2
	​

(s,z;ϵ)≡
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

s
−ϵ
[z(1−z)]
−ϵ
.
	​


The support is 0<z<1, with Q
2
>0 and 0<x<1. Endpoint distributions arise from analytic continuation of the complete integrand, not from adding endpoint terms to this density by hand.

Integrating over z,

Φ
2
	​

(s)
	​

=
8πΓ(1−ϵ)
(4π)
ϵ
s
−ϵ
	​

B(1−ϵ,1−ϵ)
=
8π
(4π)
ϵ
	​

Γ(2−2ϵ)
Γ(1−ϵ)
	​

s
−ϵ
.
	​

	​


In particular,

Φ
2
	​

	​

D=4
	​

=
8π
1
	​

,Φ
2
	​

	​

D=6
	​

=
192π
2
s
	​

.

The beta-function factor is essential: the prefactor of the differential density alone is not the integrated phase space.

The density already includes the full residual angular volume. Multiplying it by an angular average normalized to one is correct; multiplying by another solid-angle factor is not.

2. BMHV angular integration: the proposed moments are exact

Define the signed Minkowski invariant

κ≡
k
^
2
=
g
^
	​

μν
	​

k
μ
k
ν
,K≡sz(1−z)=−k
⊥
2
	​

>0.

The BMHV split keeps the physical and evanescent metrics distinct; it does not permit replacing physical scalar products by full-dimensional ones when both momenta have integrated evanescent components. 
FeynCalc

Before angular averaging, impose

r
^
=−
k
^
,
r
^
2
=κ,
k
^
⋅
r
^
=−κ,
k
ˉ
2
=
r
ˉ
2
=−κ,
k
ˉ
⋅
r
ˉ
=
2
s
	​

+κ.
	​

	​


These relations must also hold when one outgoing momentum has been eliminated from the independent variable list.

Angular derivation and analytic continuation

The transverse space has dimension

d
⊥
	​

=D−2,

and decomposes into two physical transverse dimensions and

d
ev
	​

=D−4

evanescent dimensions.

Initially take D>4, where ordinary angular geometry applies, and define

u=
K
−
k
^
2
	​

=
k
⊥
2
	​

k
^
2
	​

.

The squared-radius fraction in the evanescent subspace has normalized beta measure

B(d
ev
	​

/2,1)
u
d
ev
	​

/2−1
(1−u)
2/2−1
	​

du.

For D=4−2ϵ, this becomes

(−ϵ)u
−1−ϵ
du,0<u<1,

initially for Reϵ<0. Therefore

⟨u
a
⟩=
(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

,

and analytic continuation gives your formula:

⟨(
k
^
2
)
a
⟩
Ω
	​

=
((D−2)/2)
a
	​

((D−4)/2)
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


For implementation, the following simplification is particularly useful:

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
a=1,2,….
	​

	​


Thus

⟨
k
^
2
⟩=
1−ϵ
ϵ
	​

K,⟨(
k
^
2
)
2
⟩=−
2−ϵ
ϵ
	​

K
2
.

For positive ϵ near zero, these signs can look incompatible with ordinary geometric positivity. That is expected: an angular integral continued to negative evanescent dimension is not a positive probability measure. Do not alter its signs or insert absolute values.

If another component of the library instead stores the positive Euclidean quantity

μ
k
2
	​

=−
k
^
2
,

its moment is

⟨(μ
k
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

K
a
.

The distinction between μ
k
2
	​

 and signed 
k
^
2
 must be explicit at the interface.

Two implementation consequences

First, every positive-power moment is O(ϵ):

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
),a≥1.

A term containing (
k
^
2
)
3
 is not automatically O(ϵ
3
).

Second, averaging must act on the complete polynomial:

H(x,z,κ;ϵ)=
a=0
∑
A
	​

h
a
	​

(x,z;ϵ)κ
a
,
⟨H⟩
Ω
	​

=
a=0
∑
A
	​

h
a
	​

(x,z;ϵ)
(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

[−sz(1−z)]
a
.
	​


It is wrong to replace κ by ⟨κ⟩ and then evaluate powers. Likewise, average the forward–conjugate product, not the two amplitudes separately:

⟨AB⟩

=⟨A⟩⟨B⟩.
A combined moment test

A useful process-independent test of the density and angular map together is

	​

∫
0
1
	​

dzz
m
(1−z)
n
ρ
2
	​

(s,z;ϵ)⟨(
k
^
2
)
a
⟩
=
8πΓ(1−ϵ)
(4π)
ϵ
	​

(−1)
a
s
a−ϵ
(1−ϵ)
a
	​

(−ϵ)
a
	​

	​

B(m+a+1−ϵ,n+a+1−ϵ).
	​

	​


At D=6, the angular ratio reduces to 1/(a+1), providing a check in ordinary positive-dimensional angular geometry.

3. Scope: sufficient for the stated channels, but certify scalar closure

For

γ
∗
q→qg,γ
∗
q
ˉ
	​

→
q
ˉ
	​

g,γ
∗
g→q
i
	​

q
ˉ
	​

i
	​

,

the proposed provider is sufficient for all three scalar projections T,L,g
1
	​

, under the following conditions.

The current and spin indices must be fully contracted, the measurement must depend only on z, and any polarization reference vectors must either lie in the physical p,q plane or have disappeared through Ward identities. The propagator denominators then depend only on the full scalar invariants already fixed by x,z,Q
2
. The remaining BMHV numerator dependence is polynomial in κ.

This can be established structurally: there is only one independent transverse vector, and after scalar projection there is no physical transverse direction with which to form another independent invariant. Its physical transverse norm is determined by

k
ˉ
⊥
2
	​

=k
⊥
2
	​

−κ.

All evanescent products involving r reduce to κ.

With your fully D-dimensional UU projectors and unpolarized spin sums, the final UU scalar should in fact be independent of κ. A residual dependence there is a useful diagnostic of an unintended four-dimensional contraction. The g
1
	​

 scalar can legitimately retain it.

The provider should verify this closure, not infer it from the subprocess name. After exact simplification, require a representation polynomial in κ whose coefficients contain no residual angular objects.

Structures outside that contract include:

An additional transverse direction or measurement, such as an unintegrated lepton plane, azimuthal weighting, transverse spin, or a surviving gauge-reference vector outside the p,q plane.

Nonpolynomial angular dependence, such as a denominator depending on κ or on a residual angle. Such an expression needs a more general angular integral, or removal of a spurious denominator before using the polynomial provider.

Uncontracted tensors, for which scalar moments are insufficient. These need isotropic tensor moments before projection.

More than two final momenta, where independent evanescent vectors and mixed products occur. Separate one-vector averages do not reproduce their correlations.

The last point limits generalization to double-real NNLO geometry. Conversely, the two-body provider can still accept loop functions multiplying a polynomial in κ, once loop tensors have been reduced and their branches fixed. That does not make it a one-loop numerator or real–virtual integral evaluator.

Finally, angular closure does not certify endpoint regularity. A regulator-dependent kinematic denominator remaining in h
a
	​

(x,z;ϵ) still requires the existing uniform-expansion and omitted-tail checks.

4. Current normalization, tagging, and flavor factors

Let the projected squared-amplitude scalar include the coefficient-function projection:

H
i
	​

=2P
i
μν
	​

[A
μ
∗
	​

A
ν
	​

],i=T,L,Δ.

Here the amplitude contains the generated flavor charge, its QCD coupling, incoming averages, and outgoing sums. Then

C
i,ba
R
	​

(x,z;ϵ)=
4π
ρ
2
	​

(s,z;ϵ)
	​

⟨H
i,ba
	​

(x,z,κ;ϵ)⟩
Ω
	​

,
	​


with the final-state symmetry factor and tag sum included once.

This keeps three distinct operations separate: the 2P
i
	​

 coefficient projection, the current-definition factor 1/(4π), and the phase-space integration. None is a photon polarization average or a partonic scattering flux.

No additional measurement Jacobian

The density above was derived with

δ(z−
p⋅q
p⋅k
	​

).

Equivalently,

δ(z−
p⋅q
p⋅k
	​

)=
x
Q
2
	​

δ(2p⋅k−
x
zQ
2
	​

).

The Q
2
/x is already accounted for in ρ
2
	​

. Do not multiply the density by it again when connecting to the linear-cut representation.

There is no further 1/z. The FF convolution measure comes from a different delta function:

∫dζD
b
h
	​

(ζ)∫dz
C
b
	​

(z)δ(z
h
	​

−ζz)=∫
z
h
	​

1
	​

ζ
dζ
	​

D
b
h
	​

(ζ)
C
b
	​

(z
h
	​

/ζ).

The convolution’s 1/ζ is not part of the partonic angular density.

No outgoing FF spin average

The tagged final parton remains summed:

s
∑
	​

u
s
	​

(k)
u
ˉ
s
	​

(k)=\slashedk
D
	​

,
s
∑
	​

v
s
	​

(k)
v
ˉ
s
	​

(k)=\slashedk
D
	​

,

and a tagged unpolarized gluon has the unaveraged transverse sum. The normalized scalar-FF extraction in the operator definition does not impose another hard-side 1/2, 1/(D−2), or color average. The polarized SIDIS factorization likewise pairs a polarized incoming PDF with an ordinary unpolarized FF. 
arXiv

At this order, the color traces provide direct normalization tests:

N
c
	​

1
	​

A,i,j
∑
	​

T
ji
A
	​

T
ij
A
	​

=C
F
	​

,
N
A
	​

1
	​

A
∑
	​

Tr(T
A
T
A
)=T
R
	​

.

These correspond to quark-initiated and gluon-initiated real processes, respectively; the spin normalization remains a separate factor.

Tags and charges

For a qg final state, observing the gluon instead of the quark uses the same density with the measurement attached to the other momentum. Since z
r
	​

=1−z
k
	​

, the complete bare real density obeys the corresponding pushforward under z↦1−z. This is a useful generated-amplitude test; no extra outgoing spin or tag factor accompanies that relabeling.

For γ
∗
g→q
i
	​

q
ˉ
	​

i
	​

, the final particles are distinguishable, so there is no 1/2!. There is one eligible q
i
	​

 tag and one eligible 
q
ˉ
	​

i
	​

 tag. Produce them as separate tagged coefficients before any aggregation.

For fixed flavor, the charge factor is e
i
2
	​

. Summing flavors gives ∑
i
	​

e
i
2
	​

 only when the remaining factors are genuinely flavor independent; with distinct FFs, keep the sum explicit. Neither a generic n
f
	​

e
q
2
	​

 nor an unconditional factor two is correct. The flavor-resolved charge organization is also explicit in the updated polarized calculation. 
arXiv

The measurement implies the event-level identity

z
k
	​

+z
r
	​

=1.

Thus the energy-weighted sum over both eligible tags recovers the untagged contribution. An unweighted sum counts tagged particles instead.

Also distinguish z=0 from the usual z→1 fragmentation endpoint. A valid normalization integral of the phase-space density does not imply that the unweighted hard density has an ordinary integral down to z=0. For the intended convolution at z
h
	​

>0, do not automatically manufacture plus-distributions at zero from small-z singularities.

5. Forward and conjugate loop normalization

Define the scalar integrals before assigning any overall amplitude factor. One consistent convention is

J
+
	​

[N]=∫
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

N(ℓ)
	​

,
J
−
	​

[N
∗
]=∫
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

N(ℓ)
∗
	​

.

For real external kinematics and real ϵ,

J
−
	​

=J
+
∗
	​

.
	​


The corresponding ordinary loop measures are

∫
(2π)
D
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

N
	​

∫
(2π)
D
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

N
∗
	​

	​

=
(4π)
D/2
i
	​

J
+
	​

,
=
(4π)
D/2
−i
	​

J
−
	​

.
	​

	​


These conversion factors multiply, rather than replace, the vertex and propagator phases already generated in the amplitude.

FeynCalc explicitly distinguishes the 1/(iπ
D/2
), textbook 1/(2π)
D
, e
γ
E
	​

ϵ
-modified, and r
Γ
	​

-normalized conventions. They are not interchangeable at positive epsilon orders. 
FeynCalc

An equally valid convention with a different conjugation rule

If both prescription choices are stored with 1/(iπ
D/2
), define

J
−
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

−i0)
ν
j
	​

N
∗
	​

.

Then

J
−
	​

=−J
+
∗
	​

	​


at one loop, with (−1)
L
 for L conjugated loop integrations.

The retrieved public normalizer uses a common (iπ
D/2
)
N
loops
	​

. That is compatible with the second convention, but only if the anti-Feynman master evaluation respects this conjugation sign. A uniform prefactor alone neither proves nor disproves correctness.

The invalid combination is to use that uniform normalization and identify the oppositely prescribed normalized master with J
+
∗
	​

 without the sign.

Coupling and scale factors

For example, choose

g
s,0
2
	​

=4πα
s
	​

(μ
R
	​

)μ
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
Z
α
s
	​

	​

.

Then

g
s,0
2
	​

(4π)
D/2
i
	​

=i
4π
α
s
	​

	​

e
γ
E
	​

ϵ
μ
R
2ϵ
	​

Z
α
s
	​

	​

.

This is only a convention, but it must be used identically for the real and virtual terms.

Do not additionally insert the same μ
R
2ϵ
	​

 or e
γ
E
	​

ϵ
 through the master-integral measure. Likewise, retain or remove

r
Γ
	​

=
Γ(1−2ϵ)
Γ(1+ϵ)Γ(1−ϵ)
2
	​


exactly once according to the stored scalar-integral definition.

A universal loop–phase-space check

The normalized massless bubble is

B
+
	​

(s)=
Γ(2−2ϵ)
Γ(ϵ)Γ(1−ϵ)
2
	​

(−s−i0)
−ϵ
.

This follows directly from its Feynman-parameter integral in the normalization above. 
FeynCalc

For s>0,

(4π)
D/2
2
	​

ImB
+
	​

(s)=Φ
2
	​

(s).
	​


Indeed, the identity reduces to

sin(πϵ)Γ(ϵ)=
Γ(1−ϵ)
π
	​

.

This checks the loop normalization, the phase-space normalization, and the branch sign together without importing a hard coefficient.

For an additional spacelike check, the triangle with denominators
ℓ
2
,(ℓ+p)
2
,(ℓ+k)
2
, p
2
=k
2
=0, and (k−p)
2
=−Q
2
, has

J
3,+
	​

=−
ϵ
2
r
Γ
	​

	​

(Q
2
)
−1−ϵ

in the same 1/(iπ
D/2
) convention. Its minus sign follows from integrating three quadratic Feynman denominators.

Application to the vector form factor

For the virtual contribution,

k=p+q,x=z=1,k
2
=0.

Its nonzero scale is Q
2
=−q
2
, not s
X
	​

, which vanishes on this support.

If the generated, consistently normalized amplitude satisfies

A
(1)μ
=f
(1)
(Q
2
,ϵ)A
(0)μ
,

then

w
V
μν
	​

=2Ref
(1)
w
0
μν
	​

.
	​


Count the forward and conjugate contributions either explicitly or through this 2Re, not both.

The relevant object is the vector form factor even for g
1
	​

; the polarization projector does not turn the photon vertex into an axial current. 
arXiv
 No timelike continuation factor belongs in the spacelike virtual contribution.

Retain a consistent external-field/on-shell renormalization convention. Massless on-shell self-energy integrals are scaleless in pure dimensional regularization; setting the complete scaleless contribution to zero must not be combined with an incompatible separately retained field counterterm. Coupling renormalization first changes these SIDIS coefficients at O(α
s
2
	​

), since their Born term is O(α
s
0
	​

).

6. Epsilon depth and finite helicity conversion

Your target—NLO bare coefficients through ϵ
1
—is the right generic input for their multiplication by simple poles in NNLO counterterms. It does not mean that every smooth factor can be truncated at ϵ
1
.

For a representative real term

S(x,z,ϵ)(1−x)
−1−aϵ
(1−z)
−1−bϵ
,

with S genuinely smooth and without additional epsilon poles, the termwise requirements for output through ϵ
1
 are:

Contribution	Required smooth-factor depth
Interior, with no endpoint pole	ϵ
1

Single-delta edge, with one endpoint pole	ϵ
2

Double-delta corner, with two endpoint poles	ϵ
3

Virtual factor beginning at ϵ
−2
	Smooth prefactors through ϵ
3

The one-loop scalar-integral Laurent series itself must reach ϵ
1
; coefficients multiplying its leading poles can be needed deeper.

More generally, for target order N, downstream valuation ν, and multiplier c(ϵ), require the corresponding source through

N−v
ϵ
	​

(c)−ν.

Apply this to the full term after angular averaging, including the epsilon factor in the moment ratio and the powers of sz(1−z), which can remove endpoint singularities. Exact cancellations can lower a requirement; presumed cancellations cannot.

Angular integration does not perform the helicity scheme transformation

Keep the raw BMHV coefficient through the requested epsilon window. Apply the universal incoming-PDF conversion consistently with the definition

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
,ΔC
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

With a
s
	​

=α
s
	​

/(2π), the conventional first-order quark kernel is

z
qq
(1)
	​

(x)=−4C
F
	​

(1−x),

with the corresponding antiquark diagonal entry. Its direction and normalization must match the kernel already used in your hadronic calculation. At higher order, retain the full flavor-basis assignment rather than applying a combined non-singlet correction to individually tagged channels. 
arXiv

Do not apply this finite term twice—once inside a modified collinear subtraction and again to the assembled coefficient. Nor should the finite four-dimensional conversion overwrite the raw positive-epsilon coefficients required by the NNLO assembly.

There is no additional finite unpolarized FF conversion caused by the evanescent angular average. Ordinary unpolarized timelike mass factorization remains necessary; an extra helicity-restoring FF factor does not. The initial-state finite transformation leaves the fragmentation convolution unaffected. 
arXiv

Implementation conclusion

The proposed provider is mathematically sufficient for the stated NLO real SIDIS channels. Its acceptance condition should be:

fully projected scalar⟶
a
∑
	​

h
a
	​

(x,z,ϵ)(
k
^
2
)
a
⟶ρ
2
	​

a
∑
	​

h
a
	​

⟨(
k
^
2
)
a
⟩.
	​


The most consequential failures to exclude are premature removal of the eliminated momentum’s evanescent component, averaging powers multiplicatively, double-counting the measurement or angular normalization, and inconsistent conjugate-loop normalization. The beta-moment identity, tag-exchange tests, energy-weighted inclusive check, and bubble-discontinuity identity provide independent tests of those interfaces without using any process hard coefficients. They establish the provider and its normalization—not yet the correctness of an assembled NLO SIDIS result.