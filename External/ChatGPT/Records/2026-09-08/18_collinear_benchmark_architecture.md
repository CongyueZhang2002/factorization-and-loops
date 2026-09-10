# Collinear benchmark architecture review

Verified model: gpt-6-pro. Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a. User request: d414d8b0-f033-4f64-bbea-978ae0bb3433.

## Question

Please review a general symbolic collinear-factorization framework development campaign. Use GPT-6 Pro; we need a mathematical architecture review, not reference formulas to substitute for production. Repository: https://github.com/CongyueZhang2002/factorization-and-loops (local dirty working tree is ahead; treat following description as authoritative).

User authorized overnight work, ending with complete transverse-momentum-integrated electromagnetic SIDIS at NNLO UU and incoming-lepton/nucleon LL (unpolarized FF). Before that: inclusive photon-mediated Drell-Yan at NLO, integrated SIDIS at NLO UU/LL, and hadroproduction qqprime, qqbar->qprime qbarprime, qg->qg at NLO UU/LL (both observed quark/gluon for qg). No TMD. No subagents. Desired outputs full explicit Mathematica coefficient functions, all delta/plus/regular pieces and scales, generated from cards by reusable code. Existing qqprime NLO already fully checked against Vogelsang and original INCNLO. Gluon collinear PDF/FF tensor projectors exist and qg Born dependencies are generated through epsilon1. Only one real subprocess currently handled per NLO card; this is being generalized. Core has diagrams/FeynCalc, Hermitian interferences, cut-aware Kira, epsilon lower-bound planning and omitted-tail audits, multivariate DEs/explicit finite solutions, physical boundary integration, and one-observed-threshold distribution assembly. NNLO double-real pp coefficients/masters already worked, but no full NNLO hard function yet.

Review concrete general extensions for SIDIS: current project compiler assumes 2 massless incoming partons and one observed massless outgoing parton; SIDIS needs spacelike current q^2=-Q^2, Bjorken x and fragmentation z constraints and hadronic tensor projections. What minimal operator/current interface avoids explicit external offshell photon polarizations and remains suitable for inclusive DY crossing? How express the measurement cuts for IBP and determine physical branches? How organize double endpoint distributions x,z, including corner subtractions, without arbitrary order dependence? State required epsilon orders of LO, NLO real/virtual and NNLO ingredients through finite order with matrix PDF/FF mass factorization; distinguish exact-in-epsilon kinematic tensors from saved coefficient windows. Current NLO analytic box evaluator only supports on-shell external legs through epsilon0, so give exact prerequisites rather than assuming it suffices. Discuss gauge/helicity BMHV vs Larin transformations, specifically corrected flavor-basis scheme assignment in JHEP03(2026)109 and updated arXiv:2404.08597v3. How should a from-diagrams NNLO result be independently compared to arXiv:2401.16281 and updated polarized expressions without using them as production input? Identify mathematical obstructions and prioritize reusable implementation. Be candid about scale; no fabricated assurance of overnight feasibility. For qg->q+X remember qgg, qqbarq and distinct-flavor qqprime qbarprime, flavor multiplicities, required Born mixing channels and inclusive tag combinatorics. Provide clear equations and concrete interfaces; use standard terms.


## Pro response

The architecture is viable, but the remaining work is not just adding SIDIS cards. The main gaps are an open-current tensor interface, measurement-aware phase-space compilation, genuinely two-variable distribution assembly, complete flavor/tag closure, and regulator-depth contracts that extend through real–virtual and double-virtual contributions. Your existing reduction, differential-equation, boundary, and omitted-tail machinery should remain the computational core.

I would not infer overnight feasibility from the completed pp double-real campaign. That establishes substantial infrastructure, but not the missing SIDIS measurement integrals, off-shell real–virtual amplitudes, double-virtual contribution, or their finite assembly. I treat your description as authoritative; this review does not certify execution of the dirty working tree.

Below, D=4−2ϵ, a
s
	​

=α
s
	​

/(2π), and C
ba
	​

 means observed final parton b, incoming parton a.

1. Introduce a current insertion, not an off-shell photon state

For the stated massless, leading-power electromagnetic target, UU requires both transverse and longitudinal structure functions; LL requires g
1
	​

, with a polarized incoming PDF and an unpolarized FF. “Longitudinal polarization” of the beam/target must not be confused with the longitudinal-photon structure function. 
arXiv
+1

Minimal separation of external objects

The compiler should distinguish:

Factorized parton legs, carrying PDF/FF operator, species, polarization, and scheme.

On-shell final-state particles, carrying phase-space and tagging information.

Current insertions, carrying an operator, momentum, virtuality, and open Lorentz indices.

An electromagnetic insertion is

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

q
ˉ
	​

f
	​

γ
μ
q
f
	​

,A
a
μ
	​

(F)=⟨F∣J
em
μ
	​

∣a(p)⟩.

FeynArts may represent this insertion using an external photon line as a diagram-generation device, but the amplitude adapter must amputate its external wavefunction and retain the Lorentz index. It must not impose q
2
=0, perform a photon polarization sum, or introduce a photon spin average.

A schematic proposed card—not an existing API—would be:

Wolfram Language
<|
  "Current" -> <|
    "Operator" -> EMVectorCurrent,
    "Momentum" -> q,
    "Virtuality" -> -Q2,
    "OpenIndices" -> {mu, nu}
  |>,
  "FactorizedLegs" -> {
    PDFLeg[a, p, incomingPolarization, pdfScheme],
    FFLeg[b, observedTag, Unpolarized, ffScheme]
  },
  "Kinematics" -> {
    SP[p, p] -> 0, SP[q, q] -> -Q2,
    2 SP[p, q] -> Q2/x
  },
  "Measurement" -> TaggedSum[
    b, DiracDelta[z - SP[p, k]/SP[p, q]]
  ],
  "Observables" -> <|"UU" -> {FT, FL}, "LL" -> {g1}|>,
  "BornAlphaSPower" -> 0,
  "RelativeOrder" -> 2,
  "DimensionalScheme" -> dimensionalScheme,
  "DiracScheme" -> diracScheme,
  "Scales" -> {muR, muPDF, muFF}
|>

Current legs should not require dummy hadron momenta, momentum fractions, or polarization data merely to satisfy the existing parton-leg schema. The public card layer currently groups those properties together, making this a useful boundary to separate.

A material hazard: scalar Hermitian interference is not enough

Define the tagged tensor schematically by

W
ba
μν
	​

=N
a
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

)A
a
μ
	​

(F)A
a
ν∗
	​

(F),

with the appropriate spin-density and color contractions.

Do not apply componentwise 2Re to an open-index interference. For two different diagrams, the required contribution is

W
ij
μν
	​

=A
i
μ
	​

A
j
ν∗
	​

+A
j
μ
	​

A
i
ν∗
	​

.

The tensor obeys

W
μν
=(W
νμ
)
∗
,

not componentwise reality. Its antisymmetric imaginary part is precisely what the g
1
	​

 projector needs.

There are two safe implementations: Hermitian completion with the Lorentz-index exchange, or contraction with the correctly normalized Hermitian tensor projector before scalar interference completion.

Tensor projection should be defined by a dual basis

For the parity-even sector, a convenient D-dimensional basis is

h
μν
=g
μν
−
q
2
q
μ
q
ν
	​

,e
L
μ
	​

=
p⋅q
Q
	​

(p
μ
−
q
2
p⋅q
	​

q
μ
),
B
L
μν
	​

=e
L
μ
	​

e
L
ν
	​

,B
T
μν
	​

=−h
μν
+B
L
μν
	​

.

Here e
L
2
	​

=1, and the dual projectors are

P
L
	​

=B
L
	​

,P
T
	​

=
D−2
B
T
	​

	​

.

For the antisymmetric sector, use a tensor proportional to

B
A
μν
	​

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

,

with its normalization fixed in the declared γ
5
	​

/Levi-Civita prescription. More generally, construct

G
ij
	​

=B
i
	​

:B
j
	​

,P
i
	​

=(G
−1
)
ij
	​

B
j
	​

,

retaining any necessary evanescent structures. The conversion between these scalar projections and F
T
	​

,F
L
	​

,g
1
	​

 belongs in the tensor-definition interface, not in a later fit to known coefficients.

Keep the leptonic tensor, photon propagator, and physical lepton–hadron flux outside this QCD current tensor. In particular, do not inherit the 1/(2s) flux of two massless incoming partons.

For inclusive DY, reuse the same operator interface with an outgoing timelike current, two PDF legs, and no FF leg. Integrating the leptonic decay tensor supplies the current contraction. Crossing applies to amplitudes, prescriptions, and phase space—not directly to already mass-factorized SIDIS coefficient functions.

2. Compile measurements, support, and branches together

Use x,z below for the partonic variables, distinguished in the card from x
B
	​

/ξ and z
h
	​

/ζ:

p
2
=0,q
2
=−Q
2
,2p⋅q=
x
Q
2
	​

,(p+q)
2
=
x
Q
2
(1−x)
	​

.
The fragmentation constraint is a linear cut

For a tagged momentum k, define

G
z
	​

(k)=2p⋅k−
x
zQ
2
	​

.

Then

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


The Jacobian is part of the compiled measurement, not a convention to be reconstructed during final normalization.

The variable x normally fixes an external invariant. It does not require a second, redundant reverse-unitarity cut. An x-measurement cut is appropriate only in a representation where the quantity determining p⋅q is itself integrated.

The RR reverse-unitarity representation with a linear fragmentation cut is established independently of your existing pp families; the associated SIDIS phase-space integrals have their own reduction and differential-equation problem. 
arXiv

A useful return contract is

Wolfram Language
CompileMeasurement[measurement, phaseSpace]
  -> <|
    "Cuts" -> cuts,
    "Jacobian" -> jacobian,
    "PhysicalDomain" -> domain,
    "ContinuationData" -> prescriptions
  |>

Distinguish particle cuts δ
+
	​

(k
i
2
	​

) from measurement cuts δ(G). The latter do not acquire an independent positive-energy condition. With the convention

δ(G)=
2πi
1
	​

[
G−i0
1
	​

−
G+i0
1
	​

],

higher cut powers represent derivatives:

2πi
1
	​

[
(G−i0)
n
1
	​

−
(G+i0)
n
1
	​

]=
(n−1)!
(−1)
n−1
	​

δ
(n−1)
(G).

Consequently, the compiler must preserve raised measurement cuts, set sectors with a missing required cut to zero, and avoid prematurely imposing G=0:

Gδ
′
(G)=−δ(G),

not zero. Denominator rescalings must preserve cut normalization and prescription orientation.

There is a useful reuse of your null-beam geometry

Although q is spacelike, define

n=q+xp.

Then

n
2
=0,p⋅n=
2x
Q
2
	​

>0,p+q=n+(1−x)p.

Thus, for 0<x<1, the final-state total can still be represented as the sum of two future null vectors. This can reuse your phase-space geometry and positivity machinery.

But n and (1−x)p are auxiliary phase-space anchors, not two physical incoming partons. PDF assignments, current couplings, and momentum routing must retain p,q. The auxiliary representation degenerates at x=1, where a separate endpoint treatment is required.

For future final momenta,

z
t
	​

=
p⋅q
p⋅k
t
	​

	​

≥0,
t
∑
	​

z
t
	​

=1,

which directly establishes the tagging support.

Physical sheets require more than a DE alphabet

For the two-particle real–virtual kinematics,

s=
x
Q
2
(1−x)
	​

>0,t=(q−k)
2
=−
x
Q
2
(1−z)
	​

<0,u=(p−k)
2
=−
x
Q
2
z
	​

<0,

and s+t+u=−Q
2
.

Continue loop integrals with their original Feynman prescriptions; for example,

log(−s−i0)=logs−iπ.

Conjugation reverses the prescriptions before the interference is assembled. Boundary values must come from the physical cut integral or a justified continuation from a domain where it is defined.

The boundaries x=z and x+z=1 can separate convenient representations of the one-loop functions. They are not additional factorization endpoints: the unpolarized calculation explicitly reports continuity across its four representation regions. Do not create delta distributions on those lines. 
arXiv

3. Two-variable distributions need a joint subtraction algebra

Let

D
m
	​

(x)=[
1−x
log
m
(1−x)
	​

]
+
	​

.

For normal-crossing endpoint factors,

(1−x)
−1−aϵ
=−
aϵ
δ(1−x)
	​

+
m≥0
∑
	​

m!
(−aϵ)
m
	​

D
m
	​

(x),

and similarly for z.

The correct construction is a joint distribution at finite regulator, followed by its Laurent expansion—not two unrelated one-variable routines that independently discard endpoint terms.

Define endpoint operators acting on a test function:

E
x
	​

ϕ(x,z)=ϕ(1,z),E
z
	​

ϕ(x,z)=ϕ(x,1).

They commute, so the joint remainder is

(1−E
x
	​

)(1−E
z
	​

)ϕ=ϕ(x,z)−ϕ(1,z)−ϕ(x,1)+ϕ(1,1).
	​


For example,

⟨D
0
	​

(x)D
0
	​

(z),ϕ⟩=∫
0
1
	​

dx∫
0
1
	​

dz
(1−x)(1−z)
ϕ(x,z)−ϕ(1,z)−ϕ(x,1)+ϕ(1,1)
	​

.

For a smooth coefficient F(x,z), use the corresponding decomposition

F(x,z)=
	​

F(1,1)+[F(x,1)−F(1,1)]+[F(1,z)−F(1,1)]
+[F(x,z)−F(x,1)−F(1,z)+F(1,1)].
	​


This assigns the corner once, and only once. Order independence follows from the commuting endpoint operators, rather than being imposed as a preferred integration order.

Required output representation

The normal-crossing part has the tensor-product structure

{δ,D
m
	​

,regular}
x
	​

⊗{δ,D
n
	​

,regular}
z
	​

.

Store axis-aware distribution objects and provide their action on test functions and their convolutions. Ordinary multiplication of distributions on the same axis is not an acceptable implementation of mass-factorization convolution.

There is an important generality limit: a raw expression need not admit this decomposition before overlapping singularities are resolved. A factor such as

[(1−x)+(1−z)]
−2−aϵ

does not have a coefficient smooth at the corner after extracting independent powers of 1−x and 1−z.

Resolve such overlaps into sector charts, perform the subtractions there, and push the distributions back with their Jacobians. Preserve a genuine joint-distribution representation until conversion to the promised delta/plus/regular basis is established. Do not silently force every master or intermediate contribution into a separable endpoint ansatz.

Your existing omitted-tail audit must therefore include endpoint expansion and pushforward: a term negligible at an interior point can contribute to a finite corner coefficient after multiplication by regulator poles.

4. Epsilon requirements: coefficient windows and exact tensors are different objects

This is the main place where the current “Born through ϵ
1
” and “box through ϵ
0
” statements can be misinterpreted.

First derive the windows from matrix factorization

Define the orientation of the collinear transition matrices by

W
UV
	​

=Γ
F
	​

⊗
z
	​

C⊗
x
	​

Γ
I
	​

,C=Γ
F
−1
	​

⊗
z
	​

W
UV
	​

⊗
x
	​

Γ
I
−1
	​

.

Here Γ
I
	​

 contains spacelike PDF kernels; Γ
F
	​

 contains the appropriately oriented timelike FF kernels. Fix transposes by this definition, not by recalling a notation from another paper.

Write

Γ
F
−1
	​

=1+a
s
	​

L
1
	​

+a
s
2
	​

L
2
	​

,Γ
I
−1
	​

=1+a
s
	​

R
1
	​

+a
s
2
	​

R
2
	​

.

Then

C
(1)
=W
(1)
+L
1
	​

W
(0)
+W
(0)
R
1
	​

,
C
(2)
=
	​

W
(2)
+L
1
	​

W
(1)
+W
(1)
R
1
	​

+L
2
	​

W
(0)
+W
(0)
R
2
	​

+L
1
	​

W
(0)
R
1
	​

.
	​

	​


Products include flavor sums and the indicated convolutions.

Because L
1
	​

,R
1
	​

 have simple poles and L
2
	​

,R
2
	​

 can have double poles, the generic saved-window requirements are:

Object	Finite NLO assembly	Finite NNLO assembly
Born coefficient entering collinear counterterms	Through ϵ
1
	Through ϵ
2

Integrated, UV-renormalized NLO real contribution	Through ϵ
0
	Through ϵ
1

Integrated, UV-renormalized NLO virtual contribution	Through ϵ
0
	Through ϵ
1

NNLO RR, RV, VV contributions	—	Through ϵ
0
, with all poles retained

These are requirements for the integrated coefficient objects in this assembly. A proved cancellation or a zero Born structure can lower a particular requirement; it must not lower the generic provider contract.

NNLO mass factorization needs P
(0)
,P
(1)
 on each factorized leg, not P
(2)
. Coupling renormalization also multiplies lower-order contributions by poles. The compiler must retain the overall Born power of α
s
	​

: zero for these SIDIS/DY coefficient functions, two for the stated QCD hadroproduction processes.

Exact-in-ϵ tensors must remain available

The table does not imply that all Born algebra may be truncated at the displayed order.

For example, a virtual singular operator proportional to ϵ
−2
 can require a Born trace or normalization through ϵ
2
 to obtain a finite NLO term. At NNLO, physical poles can reach ϵ
−4
, requiring smooth prefactors through ϵ
4
. The universal two-loop infrared structure supplies precisely this higher-pole environment. 
arXiv

Therefore keep rational D-dependent projectors, spin averages, phase-space normalizations, and elementary kinematic tensors exact, or make them expandable to a requested order. A saved coefficient window is a downstream product, not a replacement for that exact source.

Your qg Born through ϵ
1
 can satisfy an NLO collinear-counterterm dependency. It does not, by itself, certify every NLO virtual dependency or NNLO readiness.

Amplitude-level prerequisites

For direct, unsubtracted amplitude assembly:

A finite NLO virtual interference ordinarily needs the one-loop amplitude through ϵ
0
.

Its use as the NLO input to NNLO factorization needs the corresponding integrated coefficient through ϵ
1
.

The NNLO term ∣M
(1)
∣
2
 generally needs the one-loop amplitude through ϵ
2
, since it starts at ϵ
−2
.

The two-loop amplitude is required through ϵ
0
 for 2Re(M
(2)
M
(0)∗
), with exact tensor contractions handled consistently.

In RV, one-loop information through ϵ
0
 can suffice in the interior, but endpoint distributions can promote ϵ
1
 terms on an edge and ϵ
2
 terms at a double endpoint into the finite result.

A subtraction formulation can reduce some positive-ϵ amplitude requirements, but only after the requisite cancellation identities are implemented. It cannot be presumed for the current direct analytic route.

For each master contribution c
i
	​

(ϵ)I
i
	​

(ϵ), propagate the valuation of all downstream operations, including endpoint poles. If the target is order N, and the downstream valuation is ν, the basic requirement is

depth(I
i
	​

)≥N−v
ϵ
	​

(c
i
	​

)−ν.

Spurious reduction poles can demand deeper master windows than the amplitude-level orders above.

The box limitation: distinguish NLO SIDIS from NNLO SIDIS

NLO SIDIS does not require a box amplitude. Its virtual process is the one-loop electromagnetic quark form factor, while its real processes are tree-level γ
∗
q→qg and γ
∗
g→q
q
ˉ
	​

. The electromagnetic LL calculation still uses a vector current, not an axial photon vertex. 
arXiv

NNLO RV does require massless-internal single-off-shell, or one-mass, boxes, with three on-shell legs and q
2
=−Q
2
, together with their crossed configurations. An on-shell box through ϵ
0
 is not that provider. The single-off-shell box has nontrivial branch structure and an all-order epsilon representation specifically relevant to such higher-order applications. 
arXiv

The missing provider contract includes external virtualities, causal prescriptions, positive-ϵ depth, endpoint-uniform expansions, and all bubble/triangle or dimension-shifted integrals required by tensor reduction. NNLO VV additionally needs the generated two-loop vector-current form factor and the one-loop square. None of these is supplied merely by having RR masters.

5. BMHV/Larin matching must act in full flavor space

Keep four declarations separate: dimensional external-state prescription, γ
5
	​

 algebra, PDF factorization scheme, and FF factorization scheme.

In BMHV, the distinction

g
μν
=
g
ˉ
	​

μν
+
g
^
	​

μν

and the evanescent contributions must survive until they can no longer multiply poles. Selecting a FeynCalc Dirac scheme performs algebraic bookkeeping; it does not automatically supply every finite symmetry-restoring or operator-scheme counterterm. 
feyncalc.github.io

For a Larin route, use Larin-defined polarized spacelike kernels during mass factorization, then transform the finite polarized PDFs and coefficients consistently. The FF side remains unpolarized. For the hadroproduction LL campaign, the analogous PDF transformation acts on both incoming legs. Universal operator-renormalization data are legitimate shared inputs; process-specific SIDIS hard functions are not substitutes for production. 
arXiv
+1

The corrected assignment

JHEP03(2026)109, §4.3 and Appendix A, identifies finite terms assigned to the wrong qq versus 
q
ˉ
	​

q channels. Their sum could agree while the individually tagged channels were wrong. The non-singlet transformation must be resolved into flavor transitions before application. 
arXiv

Implement

Δf
MS
=Z⊗
x
	​

Δf
L
,ΔC
MS
=ΔC
L
⊗
x
	​

Z
−1
,

with a full 2n
f
	​

+1 flavor matrix. Writing Z=1+a
s
	​

Z
1
	​

+a
s
2
	​

Z
2
	​

, matrix inversion gives

ΔC
MS
(2)
	​

=ΔC
L
(2)
	​

−ΔC
L
(1)
	​

Z
1
	​

+ΔC
(0)
(Z
1
	​

Z
1
	​

−Z
2
	​

).

This is an algebraic operation, not a collection of manually assigned channel corrections.

At second order, the corrected quark blocks have the structure

(Z
2
	​

)
q
i
	​

q
j
	​

	​

=δ
ij
	​

z
qq
v
	​

+z
s
,(Z
2
	​

)
q
ˉ
	​

i
	​

q
j
	​

	​

=δ
ij
	​

z
q
ˉ
	​

q
v
	​

+z
s
,z
s
=
2n
f
	​

z
PS
	​

	​

,

with charge-conjugate blocks. In the conventional transformation, the full gluon block is the identity distribution; its correction vanishes. 
arXiv
+1

A useful unit test follows immediately. For j

=i, the Born term selected by the matrix multiplication is C
q
j
	​

q
j
	​

(0)
	​

, so the sea transformation contributes, in Born-unit normalization,

δΔC
q
j
	​

q
i
	​

(2)
	​

=−e
q
j
	​

2
	​

δ(1−z)z
s
(x).

The charge is that of the intermediate Born channel, not automatically the incoming label q
i
	​

. Preserve flavor indices and charge polynomials until after the transformation.

Also, the paper’s unaffected longitudinal polarized structure function G
L
	​

, whose Born term vanishes, is not electromagnetic LL g
1
	​

. Its separate electroweak-projector issue should not be imported indiscriminately into the electromagnetic calculation. 
arXiv

Use the updated 2404.08597v3, dated September 30, 2025; its version record explicitly says the ancillary files were updated. Pin the ancillary bytes used by the comparison, not merely the arXiv identifier. 
arXiv

6. Generalize subprocesses together with tags and Born mixing

A list of real subprocess names is insufficient. Each contribution should carry

(field content, flavor constraints, ℓ
amplitude
	​

,ℓ
conjugate
	​

, S
F
	​

, allowed tags),

and the compiler should derive the lower-order channels required by collinear mixing.

For q
i
	​

g→q
i
	​

+X, the real-state inventory includes

q
i
	​

g→q
i
	​

gg,q
i
	​

g→q
i
	​

q
i
	​

q
ˉ
	​

i
	​

,q
i
	​

g→q
i
	​

q
j
	​

q
ˉ
	​

j
	​

,j

=i.

The tagging rule must act on the full final state:

Final state	Inclusive-tag consequence
q
i
	​

gg	One q
i
	​

 tag; two gluon tags. With fully labeled phase space, retain the 1/2! gluon symmetry factor.
q
i
	​

q
i
	​

q
ˉ
	​

i
	​

	Two q
i
	​

 tags; identical-quark exchange interference is essential. This is not a distinct-flavor result times a multiplicity.
q
i
	​

q
j
	​

q
ˉ
	​

j
	​

, j

=i	An n
f
	​

−1 factor is justified only when the remaining flavors are genuinely equivalent for the specified tag. A distinguished q
j
	​

 or 
q
ˉ
	​

j
	​

 tag must remain flavor resolved.

For an observed gluon, only q
i
	​

gg among these real states contains a gluon tag. That does not eliminate quark-induced Born mixing counterterms.

Schematically, a hadroproduction counterterm contains

d
∑
	​

P
da
	​

⊗H
db;c
(0)
	​

+
d
∑
	​

P
db
	​

⊗H
ad;c
(0)
	​

+
d
∑
	​

H
ab;d
(0)
	​

⊗P
cd
F
	​

,

with the proper helicity kernels and kinematic maps.

Thus the q
i
	​

g campaign can require Born dependencies including gg→q
i
	​

q
ˉ
	​

i
	​

, q
i
	​

q
j
	​

→q
i
	​

q
j
	​

, q
i
	​

q
ˉ
	​

j
	​

→q
i
	​

q
ˉ
	​

j
	​

, identical-flavor versions, and the alternate observed leg of q
i
	​

g→q
i
	​

g. For a gluon tag, gg→gg and q
i
	​

q
ˉ
	​

i
	​

→gg also arise in the appropriate incoming-mixing terms.

Generate this dependency set from nonzero splitting-kernel support and tag eligibility. Do not maintain it as a second hand-written channel list.

The same machinery should enumerate SIDIS RR states, photon attachments to different fermion lines, and all eligible tags before charge/flavor aggregation. The observable-level perturbative order must govern the inventory; a channel first appearing at a
s
	​

 is not entitled to redefine that contribution as “its LO” when deciding the requested NNLO content.

7. Independent comparison must test the distribution, not just its interior

Keep the coefficients from 2401.16281 and updated polarized ancillary files in a benchmark-only path. They must not supply production boundary constants, missing finite pieces, or branch choices selected by agreement. The unpolarized reference provides the complete coefficient-function target with scale dependence, rather than only a threshold approximation. 
arXiv

The comparison needs an explicit convention adapter covering a
s
	​

, dimensional-regulator sign, structure-function normalization, LL sign, spin/color averages, final/initial index order, flavor charges, FF Jacobians, and plus-distribution definitions. Keep μ
R
	​

,μ
PDF
	​

,μ
FF
	​

 independent.

Compare every flavor/charge/color component in the delta/plus/regular blocks. Interior high-precision points should cover all representation regions and approach their boundaries; distributional tests should include edge-sensitive and corner-sensitive test functions, not just smooth points away from x=z=1. Numerical agreement is a strong check, not by itself an exact identity proof.

A particularly useful independent check is the energy-weighted inclusive relation. Event by event,

t∈F
∑
	​

z
t
	​

=1.

Therefore, with matched coefficient normalization,

b
∑
	​

∫
0
1
	​

dzzC
ba
SIDIS
	​

(x,z)=C
a
DIS
	​

(x).
	​


Apply this to UU and g
1
	​

, ideally against a separately generated inclusive-current calculation. An unweighted sum counts tagged-particle multiplicity and is the wrong inclusive check.

Before declaring completion, require pole cancellation as distributions, current Ward identities, gluon reference-vector independence, and the three scale equations. For conventions

dlogμ
PDF
2
	​

df
	​

=P
S
	​

f,
dlogμ
FF
2
	​

dD
	​

=P
D
	​

D,F=D
T
Cf,

these include

∂logμ
PDF
2
	​

∂C
	​

=−C⊗
x
	​

P
S
	​

,
∂logμ
FF
2
	​

∂C
	​

=−P
D
T
	​

⊗
z
	​

C.

Renormalization-scale invariance must include the observable’s overall power of α
s
	​

.

The Mathematica export is complete only when its dependency closure contains no unresolved master integrals or boundary constants, every special function has a declared branch, and every distribution has defined support and action.

8. Prioritize reusable completion gates
Priority	Extension	Acceptance condition
1	Flavor-resolved subprocesses, inclusive tags, Born mixing dependencies	Existing qq
′
 stays correct; all requested qg tags and counterterm channels are generated automatically.
2	Open-current tensor, non-massless external kinematics, current normalization	Inclusive DY NLO works without an external photon polarization sum; SIDIS Born projections and Ward identities pass.
3	SIDIS NLO plus joint endpoint algebra and matrix factorization	Complete F
T
	​

,F
L
	​

,g
1
	​

, independent scales, and NNLO-ready lower-order epsilon windows.
4	Remaining hadroproduction NLO UU/LL	Full real-state inventories, identical-particle interferences, both qg tags, and all mixing Born channels pass.
5	NNLO SIDIS RR/RV/VV providers and final assembly	Physical branches, sufficient regulator depth, corrected flavor-scheme transformation, distributional pole cancellation, and independent comparisons all pass.

The important architectural choice is to make these observable-completion gates, not backend-progress milestones. “All RR masters solved,” “all diagrams reduced,” and “regular terms agree numerically” are useful intermediate results, but none is a full NNLO coefficient function.

My recommendation is to preserve the verified computational core and generalize the mathematical objects passed through it. The highest-risk shortcuts are componentwise real-part projection of the current tensor, independent endpoint expansions without corner control, premature epsilon truncation, incomplete tag/mixing inventories, and channelwise polarized-scheme patches. Resolving those gives a reusable factorization framework; bypassing them can produce plausible finite formulas that still represent the wrong observable.