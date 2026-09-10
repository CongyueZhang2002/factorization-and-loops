# GPT-6 Pro review 22

Verified model: gpt-6-pro.

## Question

Review22, general NNLO SIDIS framework completion. Repository https://github.com/CongyueZhang2002/factorization-and-loops; local changes newer. Review21 is implemented in part: generated15loop×2tree q-q RV, full-D TID gives4bubbles, one/two-offshell triangles and3one-offshellboxes. Exact triangle divided difference and coincidence pass parameter quadrature; triangle->bubble IBPs added. Universal box arbitrary-epsilon-order provider in ordinary Li_n/Log, causal phases from original invariant signs, passes7sign configurations througheps2 vs Cauchy coefficients of independent correlated hypergeometric expression. Internal diagonal limit required approaching full assembled integral, not substituting separately at Xi=1. We retain original prescribed external tree factors alongside their interior rational values; no endpoint permission inferred. Full12channelUU/LL RV generation/reduction batch active. BothUU/LL RR complete densities cancel gluon-reference factorP.k2 exactly, LL cancellation167s; new shared graph-only reduction planned. Full requested NNLO remains incomplete.

Two decisions to review before implementation:

A. Complete electromagnetic flavor dependence from generated amplitudes. Current FeynArts SMQCD cards use actual u,c,d charges2/3,2/3,-1/3, multiplicitiesnU,nD. q-q RR includes Gluons, SameFlavor, DifferentFlavorUp, DifferentFlavorDown, but NNLO adds q->qbar(same flavor), q->qprime/qbarprime, g->g. Need general symbolic charges without process-specific fitted factors. Candidates:
(1) At each generated TREE diagram, identify the fermion line attached to the single electromagnetic current vertex and replace its model Q_f by a declared symbolic Q_f BEFORE scalar contraction. Best done at FeynArts coupling/field level. QCD remainingvertices unchanged; current e amputated once. This exposes A=Q_a A_a+Q_b A_b directly.
(2) Treat full first-principles computations at three charge assignments (Qa,Qb)=(2/3,2/3),(2/3,-1/3),(-1/3,2/3) as exact polynomial interpolation in {Qa^2,Qb^2,QaQb}, after relabeling distinct fermion species. This is a permanent generic reconstruction routine, not a numerical fit to published coefficients. Does any flavor/crossing/identical-particle issue invalidate that interpolation for distinct-flavor q->qprime and q->qbarprime? Can charge conjugation be applied universally to UU/LL g1 coefficient definitions, or should we generate the conjugates once to certify the sign? Is arbitrary charge tagging at a single vertex preferable?

B. NNLO mass factorization and Mellin algebra. Framework's NLO subtraction adds +P0/epsilon convolved with Born using a=alpha_s/(2pi); leading kernels include Pqq=CF[2D0-(1+x)+3/2delta]. For normalized UV-renormalized bare W (matrix of incoming/observed individual parton species), do we use
 C = ZS^T convol_x W convol_z ZT,
 Z=1+a P0/e +a²[(P0⊗P0-b0P0)/(2e²)+P1/(2e)] ?
Please derive the correct signs/orientations and where coupling renormalization belongs, from RG and the established +P0/e NLO convention rather than relying on a possibly mismatched literature Gamma. b0=(11CA-4TRnf)/6; finite PDF helicity schemeZ1,Z2 should be applied once with the raw BMHV/Larin normalization contract.
We plan to implement universal P1 space-likeUU/LL and time-likeUU kernels from primary formulas/APFEL++ public analytic code (after conversion from their alpha_s/(4pi) convention, if that's indeed used), never import SIDIS coefficient functions as production.
For convolutions needed at NNLO, the LO singular kernel has onlyD0. A derivation with K_b=(1-x)^(b-1) gave
 D0⊗K_b = d_b K_b -[log x+gammaE+psi(b)]K_b.
If correct it implies
 D0⊗D_m = (m+2)/(m+1)D_(m+1) -log x log^m(1-x)/(1-x)
 +sum(k=1..m) (-1)^k m!/(m-k)! zeta(k+1)D_(m-k)
 +(-1)^(m+1)m!zeta(m+2)delta.
Please check: I may have lost a Jacobian during the Mellin variable substitution. It agrees with the known D0⊗D0 and simple N=1,2 moments. If wrong give the corrected general method.
Regular⊗regular and D0⊗regular of NLOepsiloncoefficients can be explicit GPL integrals; no unevaluated integral in exports. Two-axis distributions are tensor products, with the other axis' coefficients carried as a parameter. Identify any missing NNLO convolution or polarized-flavor component that this would fail to cover.

## Pro response

Your two-loop pole kernel and the proposed D
0
	​

⊗D
m
	​

 identity are correct. The main risks are not their signs or a missing Mellin Jacobian. They are the orientation of the time-like flavor matrix, reconstructing distinct flavors without changing the physical problem, and omitting convolutions between the regular part of P
(0)
 and the higher plus distributions in the NLO epsilon coefficients.

I recommend symbolic charge tagging at the current vertex for production, with your three-charge reconstruction as an exact independent test or a way to recover already generated results.

1. Electromagnetic charges: vertex tagging is the preferred general interface

For a fixed massless distinct-flavor topology with one electromagnetic current insertion,

A(Q
a
	​

,Q
b
	​

)=Q
a
	​

A
a
	​

+Q
b
	​

A
b
	​

.

Consequently, every projected density is a homogeneous quadratic polynomial,

W(Q
a
	​

,Q
b
	​

)=Q
a
2
	​

W
aa
	​

+Q
b
2
	​

W
bb
	​

+Q
a
	​

Q
b
	​

W
ab
	​

,
	​

(1)

where W
ab
	​

 contains the complete Hermitian cross interference. This remains true for LL: its spin/current contraction need not be positive, but it is still bilinear in the amplitude. The independently published flavor decomposition has precisely these three charge structures for distinct-flavor SIDIS. 
arXiv

Tag the current coupling, not a numerical factor in the completed amplitude

The reliable operation is

eQ
f
model
	​

γ
μ
⟼eQ
f
symbolic
	​

γ
μ

at the generated current vertex, before the electric charge has merged with other rational coefficients. Then remove the single external e using your existing degree check.

Do not replace every occurrence of 2/3 or −1/3 in an amplitude. Those numbers can also arise from unrelated algebra. If the FeynArts coupling has separate left/right components, both must implement the same declared vector-current charge.

The charge symbol should be attached to the flavor of the fermion field at the current vertex, not automatically to the incoming or observed flavor. This also extends correctly to a current attached to a closed fermion line.

For an antiquark, retain the same flavor parameter Q
f
	​

 in

J
μ
=
f
∑
	​

Q
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

.

The fermion-flow and spinor conventions produce the antiquark signs. Introducing a second manual replacement Q
f
ˉ
	​

	​

=−Q
f
	​

 in addition to those conventions would double-count that sign.

Useful algebraic assertions are

deg
Q
	​

A=1,deg
Q
	​

W=2,

and that no electromagnetic charge enters propagator definitions, QCD vertices, or phase-space normalization. Charges then remain spectator coefficients throughout IBP and master integration.

2. Your three assignments give an invertible exact interpolation

Define the three results for the same ordered, distinct-flavor problem:

F
++
	​

=W(2/3,2/3),F
+−
	​

=W(2/3,−1/3),F
−+
	​

=W(−1/3,2/3).

The reconstruction matrix is

9
1
	​

	​

4
4
1
	​

4
1
4
	​

4
−2
−2
	​

	​

,det=
27
4
	​


=0.

Direct inversion gives

W
aa
	​

W
bb
	​

W
ab
	​

	​

=
2
1
	​

F
++
	​

+2F
+−
	​

−F
−+
	​

,
=
2
1
	​

F
++
	​

−F
+−
	​

+2F
−+
	​

,
=
4
5
	​

F
++
	​

−F
+−
	​

−F
−+
	​

.
	​

	​

(2)

This is exact polynomial reconstruction of generated results, not fitting a published coefficient.

The conditions are important:

The equal-charge sample must still contain distinct species. For example, u,c is suitable only after both are treated as massless and all non-QCD flavor differences are excluded. Using two identical u fields instead changes the graph inventory and exchange interference.

Keep the roles fixed. Relabeling species must not swap the incoming line, the tagged line, their momenta, or the helicity insertion. Replacing (u,d) by (d,u) is a flavor relabeling of the same ordered problem, not a crossing operation.

Do not include different flavor multiplicities in the three samples. Reconstruct one fixed secondary flavor first. Apply n
U
	​

,n
D
	​

, excluding any distinguished flavor where necessary, afterward.

Identical-flavor production is a separate topology class. Setting Q
b
	​

=Q
a
	​

 in a distinct-flavor result does not generate the exchange diagrams or identical-particle/tag combinatorics of q
a
	​

q
a
	​

q
ˉ
	​

a
	​

.

There is no need to repeat three complete IBP and boundary campaigns. Equation (2) can act on the generated scalar coefficients or on their already common-master coefficients.

Charge conjugation

For pure electromagnetic exchange, with your definitions of UU and g
1
	​

,

C
a→b
	​

=C
a
ˉ
→
b
ˉ
	​

,ΔC
a→b
	​

=ΔC
a
ˉ
→
b
ˉ
	​

,
g
ˉ
	​

=g.
	​

(3)

This is full charge conjugation, including the external density and fermion-line ordering. It introduces no additional LL sign. The corrected polarized calculation states this relation explicitly for the g
1
	​

 coefficient functions. 
arXiv

Charge conjugating only the distinct secondary line instead relates

q
a
	​

→q
b
	​

andq
a
	​

→
q
ˉ
	​

b
	​

.

After the corresponding momentum/tag relabeling, their Q
a
2
	​

,Q
b
2
	​

 pieces agree and the Q
a
	​

Q
b
	​

 interference changes sign. That structure is independently exhibited in the polarized SIDIS decomposition. 
arXiv

Generate the conjugate representatives once to certify your adapter’s density signs, charge labels, and tag map; then use the proven transformation generically. Do not promote the same rule to parity-odd or charged-current observables without their own operator transformation.

Flavor bookkeeping that must remain explicit

The q→
q
ˉ
	​

 same-flavor contribution, distinct q→q
b
	​

,
q
ˉ
	​

b
	​

, and g→g must all enter the individual-species matrix. For g→g, the generated quark-pair channels produce a sum over Q
f
2
	​

; no extra factor two should be inserted merely because both q
f
	​

 and 
q
ˉ
	​

f
	​

 are present.

A useful new check follows from charge counting alone:

For a

=b, the Q
a
	​

Q
b
	​

 contribution first appears at NNLO RR. Born and NLO coefficients contain only charge squares, and the universal QCD counterterms carry no electric charges.

Therefore no NNLO collinear or finite PDF-scheme counterterm can cancel a Q
a
	​

Q
b
	​

 pole. Its complete generated contribution must already be finite. A surviving pole in that charge component is a strong diagnostic of an incomplete or misassembled RR result.

3. Derive the pole matrix from the evolution equation

Use one notation for a leg’s evolution matrix:

dlnμ
2
df
	​

=P(a)⊗f,P(a)=aP
(0)
+a
2
P
(1)
+⋯,

with

a=
2π
α
s
	​

	​

,
dlnμ
2
da
	​

=−ϵa−b
0
	​

a
2
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

.

Define the pole matrix by

f
bare
=Z
col
	​

⊗f.
	​

(4)

Independence of the bare operator from μ implies

dlnμ
2
dZ
col
	​

	​

=−Z
col
	​

⊗P.
	​

(5)

Insert

Z
col
	​

=I+
ϵ
a
	​

Z
11
	​

+a
2
(
ϵ
2
Z
22
	​

	​

+
ϵ
Z
21
	​

	​

)+⋯.

Matching powers gives

Z
11
	​

=P
(0)
,Z
21
	​

=
2
1
	​

P
(1)
,Z
22
	​

=
2
1
	​

(P
(0)
⊗P
(0)
−b
0
	​

P
(0)
).

Thus your proposed matrix is correct:

Z
col
	​

=I+
ϵ
a
	​

P
(0)
+a
2
[
2ϵ
2
P
(0)
⊗P
(0)
−b
0
	​

P
(0)
	​

+
2ϵ
P
(1)
	​

].
	​

(6)

The inverse is

Z
col
−1
	​

=I−
ϵ
a
	​

P
(0)
+a
2
[
2ϵ
2
P
(0)
⊗P
(0)
+b
0
	​

P
(0)
	​

−
2ϵ
P
(1)
	​

].
	​

(7)

This explains why formulas labeled “Γ” elsewhere can appear to have the opposite signs. The definition of the matrix, rather than its name, fixes the convention.

The convolution product in these equations includes matrix multiplication over every individual intermediate parton species.

Matrix orientation: fix it through the observable

Suppose W
ab
	​

 has incoming species a as its row and fragmenting species b as its column:

F=(f
bare
)
T
⊗
x
	​

W⊗
z
	​

D
bare
.

Define

f
bare
=Z
S
	​

f,D
bare
=Z
D
	​

D.

Then

C=Z
S
T
	​

⊗
x
	​

W⊗
z
	​

Z
D
	​

.
	​

(8)

This is your proposed orientation, provided your Z
T
	​

 means the matrix Z
D
	​

 associated with

dlnμ
D
2
	​

dD
i
	​

	​

=
j
∑
	​

P
ij
D
	​

⊗D
j
	​

.

Here i is the fragmenting parent and j the daughter whose FF appears after a splitting. If a source instead labels a time-like kernel by daughter first, transpose it before constructing P
D
.

The component equation is unambiguous:

C
ab
	​

=
i,j
∑
	​

(Z
S
	​

)
ia
	​

⊗
x
	​

W
ij
	​

⊗
z
	​

(Z
D
	​

)
jb
	​

.

If your stored coefficients use the earlier observed-first convention W
ba
	​

, use instead

C=Z
D
T
	​

⊗
z
	​

W⊗
x
	​

Z
S
	​

.
	​

(9)

Do not change data layout and retain formula (8).

Two inexpensive anchors fix the off-diagonal orientation:

P
qg
S
	​

(x)=T
R
	​

[x
2
+(1−x)
2
],

whereas

P
qg
D
	​

(z)=C
F
	​

z
1+(1−z)
2
	​

.

The first feeds an incoming gluon into a quark hard channel; the second feeds a produced quark into a gluon FF. The public APFEL++ time-like and space-like implementations reflect this difference in their off-diagonal entries.

4. Expand the complete matrix product, not channel-specific subtraction recipes

Write

W=W
(0)
+aW
(1)
+a
2
W
(2)
+⋯,

where W is UV-renormalized but not yet collinearly subtracted. Denote the order-a
n
 parts of the two pole matrices by Z
S
[n]
	​

,Z
D
[n]
	​

.

Then

C
(1)
=W
(1)
+(Z
S
[1]
	​

)
T
W
(0)
+W
(0)
Z
D
[1]
	​

,
	​


and

C
(2)
=
	​

W
(2)
+(Z
S
[1]
	​

)
T
W
(1)
+W
(1)
Z
D
[1]
	​

+(Z
S
[2]
	​

)
T
W
(0)
+W
(0)
Z
D
[2]
	​

+(Z
S
[1]
	​

)
T
W
(0)
Z
D
[1]
	​

.
	​

	​

(10)

All axis labels in (8) are understood.

The final line is essential. It generates contributions even in channels with no Born coefficient, including g→g, through an intermediate Born quark channel.

Likewise, the matrix square in (6) includes

P
qg
(0)
	​

⊗P
gq
(0)
	​


inside quark entries. It is not merely the square of the diagonal P
qq
(0)
	​

.

Do not insert your completed finite NLO C
(1)
 in place of W
(1)
 in (10). A formula using finite NLO coefficients can be derived, but it has different explicit counterterm terms.

Coupling renormalization belongs in W

For these current processes, the Born term has strong-coupling power zero. With your dimensional coupling normalization,

a
0
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
R
	​

(1−
ϵ
b
0
	​

a
R
	​

	​

+⋯).

At NNLO, this produces

W
UV
(2)
	​

=W
bare
(2)
	​

−
ϵ
b
0
	​

	​

W
bare
(1)
	​

,
	​

(11)

after expressing both terms in the same normalization and scale convention.

The −b
0
	​

P
(0)
 in (6) is not a substitute for (11). Conversely, do not add (11) a second time when the amplitude counterterms already implement it. For other cards, the coupling-renormalization multiplicities depend on the Born power of α
s
	​

.

Unequal scales require the dimensional running relation

Equation (6) is simplest at the leg’s subtraction scale. To express it using a
R
	​

=a(μ
R
	​

), define

L
F
	​

=ln
μ
R
2
	​

μ
F
2
	​

	​

,η
F
	​

=e
−ϵL
F
	​

.

Solving the D-dimensional running equation gives

a(μ
F
	​

)=η
F
	​

a
R
	​

+
ϵ
b
0
	​

	​

(η
F
2
	​

−η
F
	​

)a
R
2
	​

+O(a
R
3
	​

).
	​

(12)

Substitute this into (6), separately for the PDF and FF scales. This generates their regulator powers and finite logarithms without guessing.

Simply multiplying the order-a
n
 counterterm by η
F
n
	​

 while leaving all beta-function terms unchanged misses the second term of (12).

Your retained W
(1)
 through ϵ
1
 and Born through ϵ
2
 are the generic lower-order windows needed by (10). Keep the exact scale factors to the corresponding depth.

5. APFEL++ is usable, but its conventions need an explicit adapter

The public evolution builder uses α
s
	​

/(4π). Therefore, for your convention,

P
α
s
	​

/(2π)
(0)
	​

=
2
1
	​

P
APFEL
(0)
	​

,P
α
s
	​

/(2π)
(1)
	​

=
4
1
	​

P
APFEL
(1)
	​

.
	​

(13)

This is visible both in the builder and in the LO kernel normalization.

Three other conversions are equally important.

Distribution representation

For example, APFEL++ stores the LO non-singlet pieces as

Regular(x)
Singular(x)
Local(x)
	​

=−2C
F
	​

(1+x),
=
1−x
4C
F
	​

	​

,
=4C
F
	​

ln(1−x)+3C
F
	​

.
	​


Local(x) is not the delta coefficient. Its logarithm accounts for the lower endpoint of the numerical convolution. The corresponding distribution is

4C
F
	​

D
0
	​

−2C
F
	​

(1+x)+3C
F
	​

δ,

before the factor 1/2 in (13). This recovers exactly your

P
qq
(0)
	​

=C
F
	​

[2D
0
	​

−(1+x)+
2
3
	​

δ].

The same distinction occurs at NLO.

Singlet versus individual flavors

Construct the individual-flavor matrix before multiplying charges. At order a
2
,

P
q
i
	​

q
j
	​

(1)
	​

P
q
ˉ
	​

i
	​

q
j
	​

(1)
	​

P
qq
v,(1)
	​

P
q
q
ˉ
	​

v,(1)
	​

P
qq
s,(1)
	​

	​

=δ
ij
	​

P
qq
v,(1)
	​

+P
qq
s,(1)
	​

,
=δ
ij
	​

P
q
q
ˉ
	​

v,(1)
	​

+P
qq
s,(1)
	​

,
=
2
1
	​

(P
ns
+,(1)
	​

+P
ns
−,(1)
	​

),
=
2
1
	​

(P
ns
+,(1)
	​

−P
ns
−,(1)
	​

),
=
2n
f
	​

P
ps
(1)
	​

	​

.
	​

	​

(14)

The singlet qg entry must similarly be divided into individual-flavor entries according to the declared evolution basis.

Do not identify the polarized non-singlet labels with their unpolarized names by inspection: APFEL++ implements the NLO polarized plus kernel using the unpolarized minus kernel, and conversely.

For time-like evolution, first establish the parent/daughter orientation discussed above, then perform the singlet-to-flavor conversion. The public time-like off-diagonal functions already contain their singlet multiplicities.

Exact symbolic formulas, not floating-point outputs

The documented time-like implementation uses exact analytic expressions at LO and NLO, while higher-order routines may use parameterizations. You need only the former for NNLO mass factorization.

Translate source expressions such as 17 / 6. into the exact rational 17/6, and numerical named constants into their exact π
2
,ζ
3
	​

,… definitions. Do not reconstruct symbolic kernels from evaluated double-precision numbers.

Audit fixed T
R
	​

=1/2 or SU(3) specializations in the source. For a general-color framework, restore them using the underlying analytic formula, not an unproved rule that every occurrence of n
f
	​

 should receive another T
R
	​

.

Raw polarized subtraction must use raw-scheme kernels

If your LL production object is the declared BMHV/Larin-equivalent raw coefficient, use ΔP
L
(1)
	​

 during pole subtraction—not the standard-helicity-
MS
 kernel without translation. This ordering is explicitly part of the polarized SIDIS factorization calculation. 
arXiv

Let the finite PDF transformation be

Δf
M
	​

=F⊗Δf
L
	​

,F=I+aF
1
	​

+a
2
F
2
	​

+⋯.

Then

ΔP
L
(1)
	​

=ΔP
M
(1)
	​

−[F
1
	​

,ΔP
(0)
]+b
0
	​

F
1
	​

.
	​

(15)

After raw-scheme mass factorization, apply

C
M
	​

=F
−T
⊗
x
	​

C
L
	​

	​

(16)

for the incoming-first convention. Thus

C
M
(2)
	​

=C
L
(2)
	​

−F
1
T
	​

C
L
(1)
	​

+(F
1
	​

⊗F
1
	​

−F
2
	​

)
T
C
(0)
.

Use the full individual-flavor F
2
	​

 assignment already verified in your previous step. The corrected flavor-basis prescription is essential because the final parton is identified. 
arXiv

There is no second application of F
1
	​

, no polarized FF conversion, and no axial-current renormalization of the electromagnetic vector vertex.

6. Your D
0
	​

 convolution formula is exact

Define

(f⊗g)(x)=∫
x
1
	​

y
dy
	​

f(y)g(x/y),K
b
	​

(x)=(1−x)
b−1
.

Initially take ℜb>0.

The Mellin transforms are

M[K
b
	​

](N)=B(N,b),
M[D
0
	​

](N)=−ψ(N)−γ
E
	​

.

Using the beta-function derivatives,

∂
b
	​

B=(ψ(b)−ψ(N+b))B,
∂
N
	​

B=(ψ(N)−ψ(N+b))B,

gives

M[∂
b
	​

K
b
	​

−(lnx+γ
E
	​

+ψ(b))K
b
	​

]
	​

=∂
b
	​

B−∂
N
	​

B−(γ
E
	​

+ψ(b))B
=(−ψ(N)−γ
E
	​

)B.
	​


Therefore

D
0
	​

⊗K
b
	​

=∂
b
	​

K
b
	​

−[lnx+γ
E
	​

+ψ(b)]K
b
	​

.
	​

(17)

The beta and digamma identities used here are standard meromorphic identities. 
DLMF
+1

The −lnx term is precisely the Mellin-measure effect. It is present in your formula.

Now expand distributionally:

K
b
	​

=
b
δ(1−x)
	​

+
m≥0
∑
	​

m!
b
m
	​

D
m
	​

(x),
γ
E
	​

+ψ(b)=−
b
1
	​

+
k≥1
∑
	​

(−1)
k+1
ζ(k+1)b
k
.

Matching coefficients gives exactly

D
0
	​

⊗D
m
	​

=
	​

m+1
m+2
	​

D
m+1
	​

−
1−x
lnxln
m
(1−x)
	​

+
k=1
∑
m
	​

(−1)
k
(m−k)!
m!
	​

ζ(k+1)D
m−k
	​

+(−1)
m+1
m!ζ(m+2)δ(1−x).
	​

	​

(18)

The displayed logarithmic term is an ordinary locally integrable function at x=1, not another plus distribution.

For example,

D
0
	​

⊗D
1
	​

=
2
3
	​

D
2
	​

−ζ
2
	​

D
0
	​

+ζ
3
	​

δ−
1−x
lnxln(1−x)
	​

.

As an additional check, I evaluated the first-moment formulas numerically for m=0,…,4 and Mellin indices N=1,2,4; all 15 comparisons agreed to the 45-digit working precision. The Mellin derivation above establishes the identity; the moment checks test its implementation.

An independent generating-function regression is

K
a
	​

⊗K
b
	​

=B(a,b)(1−x)
a+b−1
2
	​

F
1
	​

(a,b;a+b;1−x).
	​

(19)

Its a
0
b
m
 coefficient reproduces (18).

7. The missing convolution class is R
(0)
⊗D
m
	​


Decompose the LO kernel as

P
(0)
=Aδ+BD
0
	​

+R
(0)
.

The products in (10) require not only D
0
	​

⊗D
m
	​

, D
0
	​

⊗R, and regular–regular convolutions, but also

R
(0)
⊗D
m
	​

	​


for every D
m
	​

 present in W
(1)
, including its positive-epsilon coefficients. The finite F
1
	​

 transformation needs the same operation.

A single endpoint-subtracted formula handles the general case:

(D
m
	​

⊗r)(x)=
	​

∫
x
1
	​

dy
1−y
ln
m
(1−y)
	​

[
y
r(x/y)
	​

−r(x)]
+
m+1
r(x)
	​

ln
m+1
(1−x).
	​

	​

(20)

Scalar Mellin convolution is commutative, so this also computes r⊗D
m
	​

. Flavor matrices are not commutative; retain their ordered index sums.

The subtraction in brackets is what makes the upper endpoint integrable. The last term is mandatory: it keeps the plus prescription defined on [0,1], rather than renormalizing it silently on the truncated interval [x,1].

For efficiency, all LO massless QCD regular kernels needed here lie in the span

{x
−1
,1,x,x
2
}.

The finite NLO helicity kernel F
1
	​

∝1−x is in the same span. Cache these monomial convolutions with D
m
	​

; then reserve the GPL integrator for the genuinely nontrivial NLO regular functions.

At NNLO, P
(1)
 multiplies only Born coefficients. You do not need a general P
(1)
⊗W
(1)
 engine yet. Nor is D
1
	​

⊗D
1
	​

 an independent requirement of the pole matrices in (10), although it may be useful in a broader convolution library.

For two-axis distributions, apply (18)–(20) to the convolution axis while carrying the other axis as a distribution-valued parameter. A coefficient depending on the active variable must remain inside the substitution x↦x/y; it cannot be frozen merely because it multiplies a plus-distribution record. Canonicalize edge coefficients and retain the joint corner terms before exporting explicit GPL expressions.

8. Recommended implementation gates

The next step should be three small common components: a symbolic current-charge map, a flavor-explicit pole-matrix constructor, and a one-axis Mellin algebra used by both axes.

The decisive checks are:

Component	Independent check
Charge tagging	Recover the three generated charge samples with (2), plus one unused charge assignment; preserve distinct species
Flavor conjugation	Generate one quark and one antiquark representative with the actual density/tag conventions
Pole matrix	Verify β
D
	​

∂
a
	​

Z
col
	​

+Z
col
	​

P=O(a
3
) using noncommuting test matrices
Kernel adapter	LO normalization, individual-flavor reconstruction, momentum/valence sum rules, and the polarized axial non-singlet first moment
Mellin algebra	Equations (17)–(19), lower-limit terms in (20), and moments beyond N=1,2
Complete subtraction	Every pole vanishes separately by flavor and charge monomial; the two PDF/FF scale equations hold

For incoming-first coefficients, those scale equations are

∂lnμ
F
2
	​

∂C
	​

=−P
S
T
	​

⊗
x
	​

C,
∂lnμ
D
2
	​

∂C
	​

=−C⊗
z
	​

P
D
	​

,

with the appropriate raw or final polarized scheme on the PDF side.

The formulas you proposed do not need correction. The production changes needed are to make their definitions unambiguous and their coverage complete: tag charges before numerical coupling collapse, build counterterms by full matrix multiplication, translate APFEL++ distributions and flavor normalization explicitly, and add the general D
m
	​

-with-regular convolution. These operations preserve the generated nature of the hard result while supplying the universal operator algebra required to finish it.