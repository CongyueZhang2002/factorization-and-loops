# Retrospective source and endpoint audit

Verified outgoing gpt-6-pro, HTTP 200.

## Question

User asks: "is there any unjustified removal in the NLO/NNLO processes we computed". I am auditing actual saved artifacts, not treating a missing new certificate as evidence a result is wrong. Please review the mathematical distinction for these specific geometries.

NLO: complete unpolarized/double incoming helicity/transversity qq' -> q(observed)+X, real q q' g final state; two unit cuts in surviving real master basis expected, angular masters computed as exact Beta/Gauss functions first in Re alpha > sum ordinary powers, alpha=(D-2)/2. Virtual massless bubble/box causal logs retain +/-i pi; virtual interference plus conjugate. Complete UU/LL/TT results exactly equal saved independently generated results; 53 checks against Werner/INCNLO pass including delta/plus/regular. This supports correctness but not a causal proof solely by agreement.

NNLO: ONLY bare double-real q q' -> q(observed)+q' g g, plus ghost subtraction. Three massless positive-energy cuts. Raw Kira masters347 (345 nonzero combined requested). All positive ordinary denominators pass the exact strict-interior sign theorem. Original amplitude terms have unit cuts, polynomial loop numerator, rational massless propagators. New original-term Gram certificate passes a hard 7-topology pair, not yet all saved source terms. All345 requested masters' 2220 coefficients numerically agree with independent AMFlow at v=1/4,w=1/5; both definitions use ordinary Prescription=0, so this comparison cannot test an omitted causal contribution.

Both processes' independent external frame is {ka,kb,kc}: null, s=2ka.kb>0, t=-2ka.kc<0,u=-2kb.kc<0. Fixed generic v keeps beam/observed collinearity away. In saved NNLO coordinates v=-t/s,w=-u/s, endpoint x=1-v-w=Qrec^2/s ->0 at fixed 0<v<1, with distributions on x in [0,1-v), test support away from x=1-v (w=0). At x=0 external Gram det=s*t*u/4 remains nonzero! The residual recoil becomes null, forcing residual cuts collinear. Earlier warnings that the generic fixed-point certificate does not establish endpoint contact terms are correct, but perhaps the proof extends directly here:

Integrate against smooth bounded test phi(x) supported in 0<=x<=b<1-v. On this compact x interval, external frame Gram and observed-coordinate Jacobians remain bounded/nonzero. Use exactly the same Wishart scalar-product measure G(x,z)^((D-3-L-1)/2), L=1 (NLO) or2 (NNLO), with all PSD conditions and nonnegative energies, now a compact semialgebraic union over x. Cut equations linear in scalar products with constant full rank Jacobian throughout x=0. Ordinary denominator zeros, and any external rational poles x^-p, lie on G=0 also at x=0 because all recoil cuts are collinear. Lojasiewicz yields G^N <= C|product denominators| uniformly on this enlarged compact domain. Smooth phi and the actual BMHV fixed-four-dimensional observed measure are bounded factors (no fictitious D-dimensional observed angular integration); large Re D suppresses endpoints. This would establish equality of the original undotted amplitude contributions as distributions in x, including delta/plus coefficients, rather than only generic values. Is this valid, or is a missing Jacobian/rank/factor an obstruction? Does retaining the fixed-4D observed measure affect the existence proof if it supplies no additional unbounded factor on this interval?

Separately, direct independently chosen dotted-cut masters were evaluated at zero ordinary prescription by both DE/boundary and AMFlow. A source undotted equality + valid fixed-oriented-cycle IBP does not imply independent dotted master prescription independence. For honest audit should these be called an unproved physical identification (unless cut normal-derivative/boundary proof exists), rather than an established erroneous removal? Please distinguish endpoint source proof from individual dotted-master semantics. Do not overstate AMFlow agreement as independent evidence for i0 removal.


## Pro response

Yes—the smeared-x extension is valid for these specific undotted real-radiation geometries. The external Gram does not degenerate at x=0, and there is no unavoidable singular cut Jacobian there. This supplies a source-level argument including endpoint distributions, rather than merely generic values. It does not, by itself, identify independently evaluated zero-prescription dotted masters with the masters defined by the physical oriented-cut reduction.

Accordingly, the facts reported do not establish an erroneous causal removal. They do leave a specific proof obligation for any such dotted-master identification, and a coverage obligation for the saved source terms.

1. The endpoint source proof works here

Use your saved coordinates

t=−sv,u=−sw,w=1−v−x,0≤x≤b<1−v.

For the external Gram matrix E=Gram(k
a
	​

,k
b
	​

,k
c
	​

),

detE=
4
stu
	​

=
4
s
3
v(1−v−x)
	​

≥
4
s
3
v(1−v−b)
	​

>0.

Thus E
−1
 and the external-frame Jacobians remain bounded throughout the smeared domain, including x=0.

The cut-constraint Jacobian can be checked explicitly

Choose the independent residual momenta as ℓ
1
	​

,…,ℓ
L
	​

, with

q
L+1
	​

=Q−
i=1
∑
L
	​

ℓ
i
	​

,Q=k
a
	​

+k
b
	​

−k
c
	​

,Q
2
=sx.

Introduce scalar products

u
iA
	​

=ℓ
i
	​

⋅e
A
	​

,M
ij
	​

=ℓ
i
	​

⋅ℓ
j
	​

,e
A
	​

∈{k
a
	​

,k
b
	​

,k
c
	​

}.

The cut constraints are

d
i
	​

=M
ii
	​

(i=1,…,L),

and

d
L+1
	​

=sx−2
i
∑
	​

(u
ia
	​

+u
ib
	​

−u
ic
	​

)+
i
∑
	​

M
ii
	​

+2
i<j
∑
	​

M
ij
	​

.

Eliminating the variables

(M
11
	​

,…,M
LL
	​

,u
Lc
	​

)

gives

	​

det
∂(M
11
	​

,…,M
LL
	​

,u
Lc
	​

)
∂(d
1
	​

,…,d
L+1
	​

)
	​

	​

=2.

This holds for both L=1 and L=2, independently of x. There is no 1/x Jacobian generated by this cut elimination. The collapse of the physical domain at x=0 is instead encoded in its Gram/positivity constraints.

With

T=UE
−1
U
T
−M,G=detT,

the scalar-product measure, after the unit cuts, has the form

dμ
D
	​

=C
L
	​

(D)∣detE∣
−L/2
G
(D−L−4)/2
dζ

on the physical semialgebraic domain. Constant normalization and cut-Jacobian factors are included in C
L
	​

. The exponent follows from the usual Baikov/Wishart measure; using the Schur complement converts the full Gram determinant to G and leaves the external factor shown above. 
arXiv

Why the new endpoint is covered by G=0

At x=0, Q is future null. Since it is the sum of future null residual momenta,

0=Q
2
=2
i<j
∑
	​

q
i
	​

⋅q
j
	​


forces every nonsoft residual momentum to be collinear with Q. Because Q belongs to the external span,

ℓ
i
⊥
	​

=0,T=0.

Hence the entire x=0 fibre lies in G=0.

For x>0, positive-definite T excludes the soft, beam-collinear, observed-collinear, and residual pair-collinear configurations that could give zeros of your accepted ordinary denominators. The fixed observed momentum remains nonsoft and away from both beams on the selected interval. Therefore the required implication holds over the enlarged domain:

Z(x
p
j
∏
	​

Q
j
ν
j
	​

	​

)∩K⊆Z(G)∩K.

This is stronger than a generic fixed-x certificate: it explicitly includes the recoil-null boundary.

Uniform domination and distributional continuation

After scaling invariants by s, K is compact. G is continuous semialgebraic there, even though its expression contains E
−1
, since detE is bounded away from zero. The semialgebraic Łojasiewicz inequality gives

G
N
≤C
	​

x
p
j
∏
	​

Q
j
ν
j
	​

	​

	​


for some finite N, uniformly on K. 
Cambridge University Press

The polynomial numerator, the smooth test function, and the nonsingular external factors are bounded. Consequently, the absolute integrand is bounded by a constant times

G
(ReD−L−4)/2−N
.

Taking ReD sufficiently large makes this bounded and integrable on the compact remaining-coordinate domain. A finite collection of source terms has a common half-plane.

For positive integer ordinary powers,

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

.

Dominated convergence therefore establishes equality for every test function in the stated class, including test functions nonzero at x=0. Meromorphic continuation of that common distribution-valued family then fixes the delta and plus coefficients as well. No additional prescription-dependent h(D)δ(x) can be added while preserving equality on the open convergence domain.

The remaining analytic requirement is the actual common meromorphic continuation, not just agreement at large integer dimensions. Endpoint subtraction/sector decomposition provides the standard construction for these dimensionally regulated phase-space distributions. 
arXiv

All other scalar poles must be accounted for: an additional divisor vanishing at a physical point with G>0 would invalidate this bound. The proof is about the complete original term, not an arbitrary rational intermediate expression.

2. Keeping the observed momentum four-dimensional is not an obstruction

No fictitious D-dimensional observed angular integration is needed. In the beam center-of-mass frame,

E
c
	​

=
2
s
	​

	​

(v+w),p
cz
	​

=
2
s
	​

	​

(w−v),p
cT
2
	​

=svw.

The ordinary four-dimensional one-particle measure satisfies

2E
c
	​

d
3
k
c
	​

	​

=
4
s
	​

dvdwdφ=
4
s
	​

dvdxdφ

with absolute Jacobians. In particular, fixing generic v and smearing in x introduces no singular observed-measure factor at x=0.

The residual D-dimensional phase space already supplies increasing endpoint suppression. As an independent check, without ordinary denominators,

Φ
2
	​

(sx)∝(sx)
(D−4)/2
,Φ
3
	​

(sx)∝(sx)
D−3
.

These agree with the standard two- and three-particle volumes. 
arXiv

Thus a bounded fixed-four-dimensional observed weight does not undermine the existence proof. This does not authorize replacing a different D-dimensional measure by its four-dimensional limit in an existing calculation; the proof must use the measure actually defining the result. Likewise, BMHV numerator structures must be retained or averaged exactly, not discarded to obtain a scalar integrand.

3. Dotted-master identification remains a distinct obligation

Write the justified source relation and a valid fixed-cycle reduction as

S
σ
=S
τ
=
r
∑
	​

c
r
	​

M
r
τ
	​

,

where τ is the chosen family prescription.

If the evaluator instead returns objects 
M
r
0
	​

, the saved assembly computes

S
=
r
∑
	​

c
r
	​

M
r
0
	​

.

The source theorem does not alone establish

M
r
0
	​

=M
r
τ
	​

.

A dotted cut probes normal derivatives, not merely the restriction to the massless surface:

⟨δ
′
(u),f(u)⟩=−f
′
(0).

Thus its identification requires the corresponding normal-derivative/boundary argument, or another valid identity fixing the required values. Generic contour-cut identities cannot simply substitute for that argument: the Baikov cut reference explicitly distinguishes its contour cuts from physical cuts with positive-energy theta constraints. 
arXiv

“Unproved physical identification” is the accurate audit classification—not “established erroneous removal.” An even more precise wording is:

The zero-prescription dotted-master values have not yet been identified with the chosen fixed-oriented-cycle master definitions.

You need not prove independence under every conceivable prescription. Identifying the evaluator with the chosen family definition is enough. Alternatively, proving

r
∑
	​

c
r
	​

(
M
r
0
	​

−M
r
τ
	​

)=0

for the required assembly would suffice without establishing every master separately.

4. What the present audit supports

NLO: On the definitions reported, there is no identified unjustified real-radiation i0 deletion once the saved surviving masters are confirmed to have unit cuts and the source hypotheses are checked. The Beta/Gauss convergence domain justifies their angular definition; the smeared proof above supplies the endpoint extension. “Two unit cuts expected” should still be checked against the saved indices. The described virtual calculation retains causal phases, so it is not an application of this removal argument. The external comparisons support the result but are not the proof of prescription independence.

NNLO bare double-real: The original undotted source terms admit the same endpoint-inclusive justification under the stated assumptions, including the ghost-subtraction terms. A seven-topology certificate pass demonstrates one implementation case, not coverage of all saved sources. Independently evaluated dotted masters remain in the unresolved-identification category until the additional argument is supplied.

AMFlow: Agreement of all 2,220 reported coefficients is a substantial check that the two computational routes evaluate the same zero-prescription objects. Because both use that same ordinary-prescription convention, it does not test the difference from a physically prescribed dotted definition.

The defensible conclusion is therefore: no erroneous causal removal has been demonstrated; the undotted source removal can be justified even at the observed endpoint, while complete saved-source coverage and the dotted-master identification remain separate audit items.