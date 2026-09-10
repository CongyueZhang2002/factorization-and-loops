# NNLO polarized raw-operator scheme and finite matching

Verified model: gpt-6-pro; standard reasoning; request e98de3e7-a6a2-4b26-abfe-101c915f08d0; HTTP 200.

## Question

Review the remaining NNLO polarized PDF scheme decision for our general FeynFacet workflow (https://github.com/CongyueZhang2002/factorization-and-loops; current work uncommitted). We have generated all NLO SIDIS UU/LL channels; finite coefficients match independent Bonino ancillary formulas. We now have NNLO RR scalar integrands and are constructing their measured-cut IBPs. References remain validation-only for hard coefficients and masters.

Current raw LL definition is genuine BMHV: p,q physical 4D, integrated momenta full D, rank-four P4, E4*E4=-det(P4), helicity quark density gamma5 slash(p_4)/2 and a physical epsilon gluon helicity density. DIS g1 current projector is the physical rank-four epsilon dual (not the Larin 1/[(D-2)(D-3)] dual). Tagged FF is unpolarized/full D. We jointly average evanescent scalar products only after the complete scalar contraction. NLO PDF conversion z_qq^(1)=-4 CF(1-x), in a_s=alpha_s/(2pi), was independently checked at finite NLO. No second application of that conversion.

Your prior review 01 correctly warned that NLO agreement does not certify reusing higher-order Larin finite renormalizations for this exact BMHV operator definition. Need now decide the reusable NNLO route:
A) identify a PRIMARY source supplying the full flavor-space two-loop BMHV-to-standard-helicity-MSbar operator conversion for exactly these raw projectors, including quark, antiquark, pure singlet and gluon. Does Matiounine-Smith-van Neerven or the corrected JHEP03(2026)109 operator normalization actually cover it, or only Larin? If needed, what universal BMHV-to-Larin matching calculation is missing?
B) add an explicitly declared Larin raw-PDF/current-projector path for the SIDIS NNLO cards, with the known Larin splitting/finite kernels, while retaining our BMHV path for general polarized scattering/TT. This may avoid inventing an unproved two-loop matching and can reuse the same scalar master-integral infrastructure. It must be a fixed operator definition, not an ad hoc correction to the hard result.

If recommending B, specify a correct minimal gamma operator and epsilon-contraction contract: Larin slash(p) gamma5 uses epsilon(p,a,b,c) gamma^a gamma^b gamma^c/6 with the convention-consistent phase; remaining epsilon products contract in D dimensions. Gamma5 alone is not an anticommuting matrix. Incoming quark/gluon helicity density and g1 dual normalizations must be consistent, including the corrected quark-projector discussion in JHEP03(2026)109. Which finite kernels in alpha_s/(2pi) and which flavor-basis assignments must be used, and which exact NLO/Born comparisons should prove the new path before NNLO?

Please distinguish established equivalences from assumptions. Give a recommendation and precise primary sources; no process-specific finite term fitted to SIDIS is acceptable. Universal splitting/operator counterterms are legitimate production inputs; full hard coefficients and master values from ancillary files are not.

## Pro response

Use an explicitly declared Larin-to-standard-
MS
 factorization contract for NNLO, but do not build a second amplitude or master-integral pipeline. There is also a stronger result than the earlier warning suggested: for your restricted electromagnetic g
1
	​

 observable, the BMHV and appropriately normalized Larin scalar projections can be related by an exact joint-angular identity. Establishing that identity in the tensor layer can authorize reuse of your existing BMHV-generated scalar integrands.

The source distinction needs correction: Matiounine–Smith–van Neerven explicitly use HVBM. They are not merely a source for an unrelated Larin calculation. What still needs checking is the correspondence between their operator projection, your raw definition, and the normalization of the current–density pair—not whether their paper contains the word “Larin.”

1. What the primary sources establish

Matiounine, Smith and van Neerven, Phys. Rev. D58 (1998) 076002, hep-ph/9803439, calculate the polarized twist-two operator matrix elements and the two-loop finite restoration factors. Their section II explicitly adopts HVBM, replaces the single axial insertion by its epsilon–three-gamma form, performs D-dimensional tensor integration, and only then projects onto the physical tensor structures. Equations (2.41)–(2.43) and (2.50) supply the non-singlet and pure-singlet information. Their complete Z
5
 expressions also contain pole and evanescent terms; those entire expressions must not be copied as the finite PDF transformation matrix. 
arXiv

Moch, Vermaseren and Vogt, Nucl. Phys. B889 (2014) 351, arXiv:1409.5131, explicitly state that their Larin prescription is equivalent to the ’t Hooft–Veltman treatment for the massless case considered. Equations (2.11)–(2.14) define the prescription and transformation direction; Appendix A gives the conventional transformation, called the M scheme, using the earlier operator results. Do not substitute their alternative finite scheme used in discussing large-x behavior. 
arXiv
+1

Bonino et al., JHEP03(2026)109, arXiv:2510.00100, clarify two separate issues: the polarized quark projection in section 4.1, and the finite transformation’s assignment in the individual quark-flavor basis in Appendix A. Their equation (4.17) is especially relevant: after the g
1
	​

 epsilon contraction, two otherwise different quark insertions coincide. That does not make them interchangeable for every polarized structure function. 
Springer

Thus a source-supported conventional massless HVBM transformation exists. The unsupported step would be to identify any implementation called BMHV with that operator scheme solely from finite NLO agreement.

2. A minimal, explicit Larin contract for your electromagnetic g
1
	​

 sector

The following contract uses your existing Minkowski convention and current-index ordering. It specifies the normalization before looking at a hard coefficient.

2.1 Axial insertion and epsilon algebra

Define

L(p)=
6
i
	​

E
D
abcd
	​

p
d
	​

γ
a
	​

γ
b
	​

γ
c
	​

.
	​

(1)

At D=4, this equals \slashedpγ
5
	​

 in your convention. For a momentum-first epsilon ordering, the permutation sign must be included; do not transplant the i from a source using FORM’s native epsilon convention without translating it.

Use ordinary full-D Clifford algebra with

tr1=4,

and define the epsilon pair by

E
D
μ
1
	​

μ
2
	​

μ
3
	​

μ
4
	​

	​

E
D,ν
1
	​

ν
2
	​

ν
3
	​

ν
4
	​

	​

=−det[g
D
μ
i
	​

	​

ν
j
	​

	​

].
	​

(2)

Here E
D
	​

 is a formal four-index antisymmetric object with this prescribed contraction rule. It is not your physical rank-four epsilon, and it is not a genuine D-index volume tensor. Do not attach P
4
	​

, use four-dimensional Schouten identities, or introduce an anticommuting standalone γ
5
	​

. The Larin prescription is an axial-operator replacement followed by dimensionally continued contractions. 
arXiv
+1

For the stated electromagnetic LL calculation, there are exactly two relevant epsilon tensors: one from the incoming helicity insertion and one from the current projector. Their pairing is unambiguous. An extension with additional axial-current vertices needs an explicit pairing prescription; that is a separate issue.

2.2 Incoming densities

Since your BMHV quark density is γ
5
	​

\slashedp/2, define its Larin counterpart by

ρ
Δq
L
	​

=−
2
L(p)
	​

,ρ
Δ
q
ˉ
	​

L
	​

=+
2
L(p)
	​

.
	​

(3)

Multiply these by the existing δ
ij
	​

/N
c
	​

. These signs specify the continuation of the ordered operators; they are not obtained by anticommuting a D-dimensional γ
5
	​

. Preserve the established antiquark trace ordering.

For an incoming gluon, choose

n=q+xp,n
2
=0,p⋅n=p⋅q,

and use

ρ
Δg
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
E
D
αβρσ
	​

p
ρ
	​

n
σ
	​

	​

,N
A
	​

=N
c
2
	​

−1,
	​

(4)

with the sign tied to your amplitude/conjugate slot order. There is no incoming 1/(D−2) average in this helicity difference. The corresponding epsilon form of the polarized gluon projector is part of the established Larin calculation. 
arXiv

The tagged FF and its hard-side spin/color sums remain unpolarized and full dimensional.

2.3 The current dual supplies the dimensional normalization

Let

d=D−2,R
ϵ
	​

=
2
d(d−1)
	​

=(1−ϵ)(1−2ϵ),

and

A
D
μν
	​

=
p⋅q
iE
D
μνρσ
	​

p
ρ
	​

q
σ
	​

	​

.

With p
2
=0, equation (2) gives

A
D
	​

:A
D
	​

=−d(d−1).

Therefore use

P
g
1
	​

,L
μν
	​

=−
(D−2)(D−3)
A
D
μν
	​

	​

,P
g
1
	​

,L
	​

:A
D
	​

=1.
	​

(5)

Keep your coefficient extraction

ΔC=2P
g
1
	​

,L
	​

:w
Δ
	​

.

With (1), (3), and (5), the generated quark Born trace gives

w
Δ,q
(0)μν
	​

=
2
e
q
2
	​

	​

A
D
μν
	​

δ(1−x)δ(1−z),

and consequently

ΔC
qq
(0)
	​

=e
q
2
	​

δ(1−x)δ(1−z)
	​


exactly in D. All positive-ϵ Born coefficients vanish in this convention. The antiquark result follows with its density sign and fermion-line ordering.

This is an algebraic normalization condition, not a factor inferred by dividing by a reference Born answer.

2.4 The corrected quark projector: do not count R
ϵ
−1
	​

 twice

Introduce the unnormalized alternative insertion

K(p,n)=−
2p⋅n
i
	​

E
D
abρσ
	​

p
ρ
	​

n
σ
	​

γ
a
	​

γ
b
	​

\slashedp.
	​

(6)

The relevant identity is

E
D
μνpq
	​

L(p)=E
D
μνpq
	​

K(p,n),
	​

(7)

after the epsilon pair is contracted by (2). This is the content of the corrected paper’s equation (4.17). Its normalized external-quark prescription in equation (4.16) contains K/R
ϵ
	​

, while equation (4.17) compares the unnormalized insertions. 
Springer

For the minimal g
1
	​

 contract above, either L or K can be used in (3), with the current dual (5). But replacing L by K/R
ϵ
	​

 while retaining (5) would introduce an additional 1/R
ϵ
	​

, visible already at Born level.

The normalization is a property of the density–dual pair. Copying a normalized operator-extraction projector into a separately normalized current coefficient is unsafe.

For the other polarized tensor structures discussed in the paper, the correction is more than an overall factor: the naive projection weights two structures that coincide in four dimensions differently at nonzero ϵ. A general electroweak extension should construct that dual tensor basis. Electromagnetic g
1
	​

 can use the restricted contract above.

3. An exact bridge can reuse your BMHV integrands

For your stated sector, there is a direct derivation that is stronger than checking NLO coefficients.

Let the physical longitudinal span be {p,n}. Its full transverse complement has dimension d=D−2, while the BMHV physical transverse plane has dimension two. Write its oriented antisymmetric tensor as ω
4
ij
	​

, normalized in the spatial transverse metric by

ω
4,ij
	​

ω
4
ij
	​

=2.

Averaging the orientation of that physical two-plane while holding the full transverse Gram data fixed gives

⟨ω
4
ij
	​

ω
4
kl
	​

⟩=
d(d−1)
2
	​

(g
⊥
ik
	​

g
⊥
jl
	​

−g
⊥
il
	​

g
⊥
jk
	​

).
	​

(8)

The coefficient follows by contracting both sides: the antisymmetric identity has trace d(d−1), whereas the original two-form has norm two.

For the gluon density, the incoming and current epsilons are directly proportional to this transverse two-form. For the quark density, first use the physical version of (6)–(7). The same two-form product appears, multiplying ordinary full-D gamma matrices and \slashedp.

Equation (8) then says

⟨E
4
	​

E
4
	​

⟩
joint
	​

=R
ϵ
−1
	​

(E
D
	​

E
D
	​

)
contracted
	​


for these longitudinally anchored epsilon products. That is exactly the factor changing the physical current dual −A
4
	​

/2 into (5).

Therefore,

⟨BMHV helicity density×P
g
1
	​

,B
	​

×H
D
	​

⟩
joint
	​

=Larin helicity density×P
g
1
	​

,L
	​

×H
D
	​

.
	​

(9)

This is a derived tensor identity, subject to explicit hypotheses:

there are precisely the two helicity/current epsilons;

all other numerator tensors and state sums are full-D covariant;

no additional physical transverse direction or P
4
	​

 remains outside those epsilons;

the measurement, propagators, and reference vectors are invariant under the same joint transverse rotation;

every integrated vector is rotated jointly, including RV loop and phase-space momenta.

Those hypotheses match the electromagnetic integrated setup you describe when the physical-gluon references lie in the p,q span.

Implement (9) as a tensor-level equivalence check for quark, antiquark, and gluon insertions. Once established, it authorizes reuse of the BMHV scalar integrands for this Larin-normalized g
1
	​

 contract at generic D, independently of perturbative order or flavor topology. It does not require a process-specific finite correction.

It is not a universal equivalence statement for TT, arbitrary spin observables, extra axial vertices, or arbitrary evanescent operator bases. Those remain outside this bridge. This limited derivation is consistent with the published massless HVBM–Larin equivalence, rather than an assumption that all implementations with those names coincide. 
arXiv

4. The finite transformation in full flavor space

Use

a
s
	​

=
2π
α
s
	​

	​

,Δf
M
=Z⊗
x
	​

Δf
L
,Z=I+a
s
	​

Z
[1]
+a
s
2
	​

Z
[2]
+O(a
s
3
	​

).
(10)

Here M denotes the standard helicity-
MS
 convention.

Define four scalar functions

h=z
qq
[1]
	​

,v=z
qq
v,[2]
	​

,
v
ˉ
=z
q
ˉ
	​

q
v,[2]
	​

,s
f
	​

=z
qq
s,[2]
	​

=z
q
ˉ
	​

q
s,[2]
	​

.

The bracketed superscripts here denote the power of a
s
	​

; they avoid the shifted superscript convention used in some tables.

Writing L=lnx,

h(x)=−4C
F
	​

(1−x).
	​

(11)

The finite two-loop functions are

v(x)=
	​

C
F
	​

T
R
	​

n
f
	​

(1−x)(
9
20
	​

+
3
4
	​

L)
−C
F
2
	​

[4(1−x)+(2(2+x)−4(1−x)ln(1−x))L]
−C
F
	​

C
A
	​

[
9
148
	​

(1−x)−
3
π
2
	​

(1−x)+
3
2
	​

(10−x)L+(1−x)L
2
],
	​

	​

(12)
v
ˉ
(x)=
	​

−C
F
	​

(C
F
	​

−
2
C
A
	​

	​

)[−14(1−x)+
3
2π
2
	​

(1+x)−2(1+x)L
2
−(1+x)(6−8ln(1+x))L+8(1+x)Li
2
	​

(−x)],
	​

	​

(13)

and

s
f
	​

(x)=C
F
	​

T
R
	​

[2(1−x)+(3−x)L+
2
1
	​

(2+x)L
2
].
	​

(14)

These are universal operator kernels, not SIDIS hard coefficients. Their explicit flavor-resolved normalization is given in Appendix A.28–A.31 of the corrected paper and agrees with the older operator results after translating conventions. 
Springer
+1

For i,j=1,…,n
f
	​

,

Z
q
i
	​

q
j
	​

	​

Z
q
ˉ
	​

i
	​

q
j
	​

	​

Z
q
ˉ
	​

i
	​

q
ˉ
	​

j
	​

	​

Z
q
i
	​

q
ˉ
	​

j
	​

	​

	​

=δ
ij
	​

δ(1−x)+a
s
	​

δ
ij
	​

h+a
s
2
	​

(δ
ij
	​

v+s
f
	​

),
=a
s
2
	​

(δ
ij
	​

v
ˉ
+s
f
	​

),
=Z
q
i
	​

q
j
	​

	​

,
=Z
q
ˉ
	​

i
	​

q
j
	​

	​

.
	​

	​

(15)

For the conventional transformation,

Z
q
i
	​

g
	​

=Z
q
ˉ
	​

i
	​

g
	​

=Z
gq
i
	​

	​

=Z
g
q
ˉ
	​

i
	​

	​

=0,Z
gg
	​

=δ(1−x).
	​

(16)

A zero listed for the gluon correction is not a zero full Z
gg
	​

: the transformation must have an identity term.

The pure-singlet kernel is

z
PS
[2]
	​

=2n
f
	​

s
f
	​

.
	​


The non-singlet eigenvalues contain v+
v
ˉ
 or v−
v
ˉ
, while the singlet quark entry contains v+
v
ˉ
+2n
f
	​

s
f
	​

. This is why one combined non-singlet function cannot simply be assigned to every tagged quark channel.

Older convention conversions

When importing the 1998 or 2014 formulas, account for

a
4
	​

=
4π
α
s
	​

	​

=
2
a
s
	​

	​

.

An order-a
4
n
	​

 finite kernel is divided by 2
n
 when expressed as an order-a
s
n
	​

 kernel. The 1998 dimensional regulator is also defined with the opposite sign and a factor two relative to D=4−2ϵ.

Do not identify the older Mellin-parity “plus/minus” functions with modern q±
q
ˉ
	​

 components merely by their labels. The modern flavor assignment in (15) avoids that ambiguity. 
arXiv
+1

5. Mass factorization, splitting functions, and application order

Let b label the observed parton and a the incoming one. The finite coefficient transforms as

ΔC
M
=ΔC
L
⊗
x
	​

Z
−1
.
	​


Hence

ΔC
M
(1)
	​

ΔC
M
(2)
	​

	​

=ΔC
L
(1)
	​

−ΔC
(0)
Z
[1]
,
=ΔC
L
(2)
	​

−ΔC
L
(1)
	​

Z
[1]
+ΔC
(0)
(Z
[1]
Z
[1]
−Z
[2]
).
	​

	​

(17)

Products include flavor sums and x-convolutions. The z-convolution with the unpolarized FF is unchanged.

An immediate flavor check is

δΔC
q
j
	​

q
i
	​

(2)
	​

	​

j

=i
	​

=−e
q
j
	​

2
	​

δ(1−z)s
f
	​

(x).
(18)

The charge belongs to the intermediate Born channel selected by matrix multiplication, not automatically to the original incoming flavor. This is precisely the class of assignment that a scalar “apply the non-singlet correction” routine can mishandle.

Which splitting kernels are needed?

For an NNLO coefficient, initial-state pole subtraction needs

ΔP
L
(0)
	​

,ΔP
L
(1)
	​

,

and the FF side needs the usual unpolarized timelike

P
T
(0)
	​

,P
T
(1)
	​

.

Three-loop splitting functions are not needed for this coefficient’s NNLO collinear counterterms.

The initial kernels must be in the raw scheme being subtracted. Equivalently, obtain the NLO Larin kernels from standard helicity-
MS
 kernels and the known Z
[1]
. With

dlnμ
2
da
s
	​

	​

=−b
0
	​

a
s
2
	​

+⋯,b
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

the matrix transformation gives

ΔP
M
(1)
	​

=ΔP
L
(1)
	​

+[Z
[1]
,ΔP
(0)
]−b
0
	​

Z
[1]
.
	​

(19)

This fixes all quark/gluon channels consistently. The general transformation law is given in MVV equation (2.14). 
arXiv

Use one declared coupling scale for Z, naturally μ
PDF
	​

. If everything is re-expanded in a
s
	​

(μ
R
	​

),

a
s
	​

(μ
PDF
	​

)=a
s
	​

(μ
R
	​

)+b
0
	​

a
s
2
	​

(μ
R
	​

)ln
μ
PDF
2
	​

μ
R
2
	​

	​

+O(a
s
3
	​

),

so the corresponding order-two logarithmic contribution multiplying Z
[1]
 must be included once.

Your existing NLO transformation is not reapplied to a coefficient already in the final scheme. Preserve distinct raw and transformed objects. In particular, do not overwrite the NLO raw ϵ
1
 data required by NNLO counterterms.

There is no extra finite unpolarized FF transformation and no axial-current Z
5
	​

 on the electromagnetic photon vertex. The published polarized SIDIS calculation uses polarized initial-state scheme conversion with an ordinary unpolarized FF. 
arXiv

6. When a separate BMHV-to-Larin operator calculation really is needed

It is needed if you want a universal identification outside the assumptions of (9), or if your actual implementation contains additional evanescent operator choices that cannot be removed by that identity.

The appropriate calculation is a forward twist-two operator matching, not a fit to SIDIS. Evaluate the quark, antiquark, and gluon operator matrix elements using the same infrared regulator and the same physical/EOM/evanescent projection in both schemes. Off-shell external partons are one established way to separate the ultraviolet operator information. Retain one-loop positive-ϵ terms needed by two-loop subtraction. The MSvN calculation provides the relevant methodological model. 
arXiv

For example, define

O
B
ren
	​

=R
B←L
	​

⊗O
L
ren
	​

.

For consistently normalized matrix elements,

R
[1]
=M
B
(1)
	​

−M
L
(1)
	​

,
R
[2]
=M
B
(2)
	​

−M
L
(2)
	​

−R
[1]
M
L
(1)
	​

.

Then

Z
M←B
	​

=Z
M←L
	​

⊗R
B←L
−1
	​

.
	​

(20)

The matching must resolve both non-singlet combinations, pure singlet, and the gluon mixing blocks. Do not assume that the matching matrix R has vanishing gluon corrections merely because the conventional Z
M←L
	​

 does.

A supposed universal matching that retains fragmentation z, photon charge factors, or a particular final-state tag is not an operator conversion.

7. Acceptance gates before using the NNLO kernels

The smallest useful sequence is:

Gate	Required exact check
Larin algebra and normalization	Equations (1)–(7); quark and antiquark Born coefficients equal e
q
2
	​

δ
x
	​

δ
z
	​

, with zero ϵ
1
,ϵ
2
 terms; no duplicated R
ϵ
−1
	​


BMHV–Larin bridge	Prove (9) for the quark, antiquark, and gluon tensor insertions under the actual state-sum/reference declarations
NLO raw data	Compare the newly defined Larin bare real and virtual objects with the BMHV joint-averaged ones through ϵ
1
, not merely their finite scheme-transformed sums
Factorization and flavor algebra	Exact ZZ
−1
=I+O(a
s
3
	​

), non-singlet/singlet decomposition, and matrix-generated charge assignments such as (18)
End-to-end NLO	Larin pole subtraction followed by one application of (11), reproducing all finite channels and independent scale dependence

Two inexpensive kernel moment checks, obtained directly from the displayed functions, are

∫
0
1
	​

h(x)dx=−2C
F
	​

,∫
0
1
	​

s
f
	​

(x)dx=
8
3
	​

C
F
	​

T
R
	​

.

They test normalization but do not replace the full x-dependent or flavor checks.

Recommendation: add the Larin density–current pair as a small, explicitly scoped algebra mode and implement the full finite matrix (15)–(16). Use the exact two-epsilon bridge to certify reuse of the existing BMHV scalar integrands wherever its hypotheses hold. Keep the current BMHV implementation for general polarization and TT, without declaring a universal two-loop operator equivalence beyond the proven scope.

That resolves the NNLO scheme decision without importing a hard coefficient, changing the scalar-master infrastructure, or inventing a SIDIS-specific finite term.