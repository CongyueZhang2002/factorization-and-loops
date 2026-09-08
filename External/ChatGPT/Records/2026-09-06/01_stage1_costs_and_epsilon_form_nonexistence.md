# Stage 1 costs and epsilon-form nonexistence

Conversation: 6a9d1440-ba18-83e8-a2e8-f3ba1425bbf5. Model: gpt-6-pro.

## Question

Audit the mathematical validity of epsilon-form nonexistence claims in our general NNLO DE framework. Repository: https://github.com/CongyueZhang2002/factorization-and-loops (the current working tree contains uncommitted changes). Please reason independently from the following equations, not from previous verdicts.

Given fixed flat diagonal connections eps e and eps c and a fixed off-diagonal inhomogeneity b, the solver seeks G and constant matrices R_a satisfying
d_mu G = eps(e_mu G-G c_mu)+b_mu-eps sum_a R_a w_a,mu,
with a finite supplied alphabet of epsilon-independent closed one-forms w_a=dlog L_a. Cross-differentiation eliminates G using flatness and yields a linear system for R_a alone:
C_b=eps^2 sum_a [(w_a,y e_x-w_a,x e_y)R_a+R_a(w_a,x c_y-w_a,y c_x)],
C_b=d_y b_x-d_x b_y+eps(e_x b_y-e_y b_x+b_x c_y-b_y c_x).
The code evaluates this system at kinematic points on all sign branches of a multiquadratic field, at two configured and three fresh prime/epsilon pairs; checks diagonal flatness there; records rank and augmented rank, and an exact finite-field left witness. Repeated inconsistency returns AlphabetDLogAnsatzInconsistency, not a generic theorem. But old reports promoted this to no strict rational dlog epsilon form in any frame, claiming finite divisor and infinity degree bounds are complete. The runtime contract misleadingly says “the alphabet is missing letters.”

1. State exactly what such an inconsistency establishes and what it does not: target alphabet, fixed diagonal basis and previously fixed inter-sector transformations, exceptional epsilon values/bad primes, enlarging function fields or transcendental gauges.
2. Give small adversarial examples showing failure modes of promoting sampled inconsistency or finite-ansatz failure to no epsilon form. Is full flatness relevant when b represents a non-adjacent block with already transformed intermediate blocks?
3. What additional practically checkable hypotheses/certificates would justify an ansatz-independent rational no-go, distinguishing rational function fields on P1 or P2 from a multiquadratic algebraic surface? Please reference primary literature, especially Lee/Pomeransky 1707.07856 and Meyer 1611.01087. Do not extrapolate P1 theorems to a general cover without justification.
4. Recommend a cheap operational policy: these checks must not dominate canonicalization. Can we retain negative results as a reason to try another presentation or store general DEs, without falsely certifying mathematical impossibility? We want explicit mathematical scope fields and good criteria rather than blanket downgrades.
5. For stage-1 performance on three-root systems, comment on avoiding repeated all-sign symbolic evaluations, native finite-field batches, active-root reduction (three-root family does not imply every block has three roots), and how to benchmark actual solve costs.

A notable audit fact: CF300 sector (12,9), once described as obstructed for a 26-letter alphabet and rectangular support, has a retained successful exact dlog solution in a rationalizing two-root chart using projective simplex support. Its active root rank is two despite the three-root family. Distinguish this from other CF300 blocks and the separately discussed CF303 (25,18)/(25,14)/(25,11) conditional obstruction records. We are not assuming any entire family intrinsically lacks an epsilon form.


## Pro response

Your cross-differentiation is correct. The promotion to “no strict rational dlog epsilon form in any frame” is not justified by the stated evidence. However, the exact version of this test is substantially stronger than a failed finite ansatz for G: it is an obstruction to the fixed block-completion problem, independent of G’s degree or pole support. The appropriate correction is to preserve that strength while separating its alphabet, presentation, function-field, regulator, and arithmetic scopes.

Repository-specific observations below refer to the pushed codex/scientific-terminology-and-math-fixes snapshot e8c62cce…, not your uncommitted changes. I have not rerun the campaign benchmarks or independently replayed the retained CF300 solution. The mathematical audit uses your supplied equations.

1. What the residue-only inconsistency actually establishes

Define the induced connection on the space of off-diagonal matrices by

∇
μ
	​

X=∂
μ
	​

X−ϵ(e
μ
	​

X−Xc
μ
	​

),W
μ
	​

(R)=
a
∑
	​

R
a
	​

w
a,μ
	​

.

Your equation is

∇
μ
	​

G=b
μ
	​

−ϵW
μ
	​

(R).

Without assuming diagonal flatness, cross-differentiation gives

ϵF
e
	​

G−ϵGF
c
	​

+C
b
	​

=ϵ
2
Φ(R),

where

F
e
	​

=∂
y
	​

e
x
	​

−∂
x
	​

e
y
	​

+ϵ[e
x
	​

,e
y
	​

],

and similarly for F
c
	​

, while Φ(R) is precisely the residue expression in your question. Thus F
e
	​

=F
c
	​

=0 eliminates G. This also agrees with the formula documented in the pushed screen implementation.

The exact mathematical conclusion

Suppose the identity

C
b
	​

=ϵ
2
Φ(R)

has no solution in the declared class of constant matrices R
a
	​

, in characteristic zero. Then:

There is no G satisfying the stated differential equation with those fixed e,c,b and that target one-form span.

No degree bound, divisor bound, numerator support, or rational ansatz for G is needed for this conclusion. Indeed, it excludes even a local differentiable G for the same equation: a primitive cannot repair an incompatible curvature condition.

Conversely, consistency is only a necessary condition. It does not establish rational integrability, a globally defined gauge, or epsilon-independent residues.

What remains fixed in that conclusion

The target is a span, not a letter count. The relevant object is

W=span
allowed constants
	​

{dlogL
a
	​

},

including any restrictions on the residue matrices. Two alphabets with different names or numbers of letters can define the same span.

The presentation is fixed. The diagonal bases, effective inhomogeneity, and already chosen inter-sector transformations are part of the problem. A statement about this completion does not automatically quantify over other choices of those transformations, sector normalizations, filtrations, or unrestricted full-system gauges.

The regulator class must be explicit. These are different problems:

R
a
	​

∈Mat(k)versusR
a
	​

∈Mat(k(ϵ)).

The former is the strict epsilon-independent-residue target. Solving independently at each sampled ϵ generally tests a relaxation: it does not require the same residues at different regulator values. Inconsistency of that relaxation is useful; consistency does not certify a strict epsilon form.

Changing coordinates is not necessarily changing the problem. A birational coordinate change, with all fixed data and the alphabet pulled back correctly, preserves exact compatibility. Therefore, an exact residue-curvature obstruction cannot disappear merely because the same problem is written in a better rationalizing chart. A finite-support failure certainly can disappear.

Enlarging only the class of G does not repair exact incompatibility. Allowing algebraic or transcendental G, while retaining the same e,c,b,W, does not bypass cross-differentiation. Allowing new letters or a different full gauge changes the problem and can bypass it. An unrestricted local transcendental fundamental-matrix gauge can trivialize a flat connection, but that is not a rational canonicalization result.

Finally, the constant field and genuine branch relations matter. All-sign equations should use embeddings that fix the allowed residue constants. Independent sign flips of dependent roots—or sign flips that also conjugate an allowed algebraic constant while incorrectly holding R
a
	​

 fixed—can impose equations that are not part of the intended problem.

2. What five finite-field inconsistencies prove—and a cheap rigorous upgrade

Write a stacked residue system as

Mr=v.

An exact finite-field witness

λ
T
M=0,λ
T
v

=0

proves inconsistency of that particular finite-field system. It does not, by itself, prove characteristic-zero inconsistency.

Minimal specialization counterexamples

For any nonzero integer N,

Nr=1

has the rational solution r=1/N, but becomes inconsistent modulo every prime dividing N. Taking N to be the product of five tested primes defeats a universal claim based solely on five repetitions. Notice that the input has no rational denominator: checking input denominators alone does not eliminate this rank-drop mechanism.

When residues are permitted to depend rationally on the regulator,

(ϵ−a)r=1

has the generic solution r=(ϵ−a)
−1
, yet is inconsistent at ϵ=a. Any finite prescribed set of regulator values can be made exceptional by replacing ϵ−a with a polynomial vanishing on that set.

These are linear-algebra counterexamples to the proposed inference, not assertions that your production inputs exhibit these pathologies.

There is an important asymmetry here: an exact characteristic-zero contradiction at one regular regulator specialization does exclude a single epsilon-independent residue assignment valid identically in ϵ. A possible pole of G in ϵ does not invalidate that argument, because G has already disappeared from the identity. The exceptional-residue-pole caveat concerns the relaxed R(ϵ) problem.

The inexpensive certificate worth adding

A modular inconsistency can become rigorous without reconstructing a large rational gauge.

Suppose a certified characteristic-zero upper bound is available:

rankM≤r
∗
	​

.

If a valid modular image has

rank[M∣v]>r
∗
	​

,

a nonzero augmented minor certifies characteristic-zero inconsistency. The upper-bound certificate must cover the underlying coefficient system and reduce correctly at the chosen image.

Especially useful: full column rank. If there are n residue unknowns and

rank
F
p
	​

	​

M=n,rank
F
p
	​

	​

[M∣v]=n+1,

the upper bound rankM≤n is automatic. The nonzero (n+1)-minor gives the obstruction. No unknown denominator bound for R, repeated-prime argument, or degree bound for G is required.

For a rank-deficient image, useful upper-bound certificates include exact structural null relations, a verified rank factorization, or a small reconstructed characteristic-zero annihilator. Repeated observation of the same deficient rank is not itself such a certificate.

This promotion requires valid reduction of the declared algebraic model: exact coefficients, correct root relations and branches, well-defined denominators, and justification of the eliminated flatness identity. Passing flatness checks at finitely many points does not prove global flatness, although an existing exact flatness argument can be inherited rather than recomputed.

Thus the distinction should be:

exact inconsistency in each sampled image;

a lifted characteristic-zero incompatibility, with a stated regulator quantifier.

Five fresh images can be excellent scheduling evidence without being mislabeled as the second.

3. Full flatness and adversarial block examples
Non-adjacent blocks carry intermediate curvature

For a lower-triangular full connection A, when b=A
ij
	​

 is the actual current connection block,

0=F
ij
	​

=C
b
	​

+
i>k>j
∑
	​

(A
x,ik
	​

A
y,kj
	​

−A
y,ik
	​

A
x,kj
	​

).

Consequently, full flatness does not imply C
b
	​

=0 for a non-adjacent block.

For an effective inhomogeneity assembled from previously transformed blocks, the corresponding terms must be accounted for in the derivation of that effective equation. Omitting them can manufacture an apparent obstruction.

There is also a useful diagnostic:

For an isolated, genuinely flat two-block triangular system, C
b
	​

=0, so the residue-only curvature system is homogeneous and R=0 is always consistent.

The curvature screen therefore cannot detect all rational-completion failures even in this simplest case.

Example A: a fully canonical flat system fails a restricted block alphabet

Consider

M=
	​

0
1
0
	​

0
2
1
	​

0
0
1
	​

	​

,N=M
2
−M=
	​

0
1
1
	​

0
2
2
	​

0
0
0
	​

	​

,

and

A=ϵ(Mdlogx+Ndlogy).

Since N is a polynomial in M, [M,N]=0. This is already a flat strict dlog epsilon form.

For block (3,1),

e=dlogx,c=0,b=ϵdlogy.

Therefore,

C
b
	​

=
xy
ϵ
2
	​

.

With the supplied alphabet restricted to {dlogx}, the right-hand side of the residue condition vanishes identically. The residue system is exactly inconsistent.

Nevertheless, the full system is already canonical. Adding dlogy gives G=0, R
y
	​

=1.

The intermediate contribution is

A
x,32
	​

A
y,21
	​

−A
y,32
	​

A
x,21
	​

=−
xy
ϵ
2
	​

,

which cancels C
b
	​

. This example simultaneously demonstrates alphabet scope and why non-adjacent full flatness must not be reduced to C
b
	​

=0.

Example B: the issue is a frozen epsilon normalization, not missing letters

Take

A=E
21
	​

dlogx.

For a fixed unitriangular completion with strict residue R,

dG=(1−ϵR)dlogx.

A rational derivative has zero residues, so no rational G works with epsilon-independent R.

But the rational, kinematics-independent gauge

T=diag(ϵ,1)

gives

T
−1
AT=ϵE
21
	​

dlogx.

The only needed letter was present throughout.

This is a fixed-gauge/strict-normalization failure, not a curvature inconsistency: the curvature test here is 0=0. It also shows why allowing R=1/ϵ at the block-completion stage is a different contract from demanding strict residues immediately.

Example C: finite support can fail while the rational solution is elementary

Let

e=c=0,b=d(x
2
+y
2
).

Then

G=x
2
+y
2
,R
a
	​

=0

is an exact solution.

The rectangular support

{1,x,y,xy}

cannot represent it, while the total-degree-two simplex can. This does not make simplices universally superior: a sufficiently large rectangle contains the simplex. The error is treating a particular finite support as exhaustive without proving that it contains every admissible solution.

Likewise,

b=d(
x+y
1
	​

)

is rationally exact but cannot be integrated within an ansatz whose allowed denominator factors are only x and y. Missing gauge denominators and missing target dlog letters are different diagnoses.

Example D: a rational no-go depends on the function field

The scalar equation

dI=(
2
1
	​

+ϵ)dlogxI

has no strict epsilon form by a scalar rational gauge over k(x,ϵ): a rational logarithmic derivative shifts its residue by an integer, not by 1/2.

After

x=z
2
,I=zJ,

it becomes

dJ=2ϵdlogzJ.

This enlarges the admissible function field. It is not a counterexample to a correctly scoped no-go over k(x,ϵ).

4. What can justify an ansatz-independent rational no-go?

There are three distinct achievements:

No completion with this target span
	​

No rational completion in this fixed presentation
	​

No rational strict epsilon form under all declared gauges
	​


Your exact curvature test can establish the first without a G-ansatz. Complete rational-function bounds can establish the second. The third additionally requires a gauge-independent obstruction or a proof that the fixed completion exhausts the admissible gauges.

4.1 What Lee–Pomeransky actually supplies on P
1

Lee–Pomeransky, 1707.07856, concerns rational differential systems on the Riemann sphere. Its constructive global-normalization criterion uses the transition matrix between locally normalized presentations and its Birkhoff–Grothendieck splitting. A nontrivial splitting obstructs global normalized Fuchsian form, hence epsilon form. Once globally normalized with the required residue normalization, an epsilon-form transformation must be independent of the coordinate; epsilon factorization is then an exact constant-intertwiner problem, including invertibility. The finite polynomial bound comes from that particular transition-matrix construction—not an arbitrary multivariate support choice. The paper’s further persistence statement under rational changes of the sphere coordinate has stated local-normalization hypotheses. None of this is a general theorem about vector bundles or rational gauges on algebraic surfaces. 
arXiv
+1

Operationally, this is a legitimate no-go route when the actual problem is over k(z), all singular points including infinity are covered, and the exact normalization/factorization criterion—not a timeout—is what failed.

4.2 What Meyer establishes—and does not establish

Meyer, 1611.01087, establishes a multiscale rational-transformation framework using Leinartas representations. The representability of every rational function in the unrestricted class does not make a selected finite subset complete. Its construction assumes a sufficiently large ansatz; failure of one chosen subset is not a general nonexistence theorem. 
arXiv

The later CANONICA paper, 1705.06252, is particularly relevant: §§2.4–2.5 provide actual alphabet and denominator restrictions under its rational hypotheses, including upper bounds on denominator powers for the off-diagonal equation. The numerator support still has a tunable degree parameter. These results justify retaining proven pole bounds while rejecting unsupported claims that a particular finite numerator support is exhaustive. 
arXiv

4.3 A direct, checkable completeness certificate on the rational plane

Here is a local argument directly for your equation.

Assume e,c are logarithmic along a divisor D, with a genuine local uniformizer t:

e=E
D
	​

t
dt
	​

+⋯,c=C
D
	​

t
dt
	​

+⋯.

If

G=t
−m
G
0
	​

+⋯,m>0,

then the leading normal term of ∇G is

−[mG
0
	​

+ϵ(E
D
	​

G
0
	​

−G
0
	​

C
D
	​

)]
t
m+1
dt
	​

.

Define the Sylvester operator

S
D
	​

(X)=E
D
	​

X−XC
D
	​

.

If

mI+ϵS
D
	​


is invertible and the right-hand side has normal pole order at most s
D
	​

, then

m≤s
D
	​

−1.

For strictly epsilon-independent diagonal residues, invertibility holds generically in ϵ for every positive integer m, since the determinant has nonzero constant term. For epsilon-dependent diagonals, that conclusion needs a separate check.

This yields a real certificate when applied to every possible polar divisor and infinity. In particular, at a divisor where e,c,b are regular, a pole of G would create an uncancellable higher-order pole; a new logarithmic target pole cannot compensate for it.

Now suppose K=k(x,y), and the proved finite-divisor bounds give a common denominator

Q(x,y)=
D
∏
	​

p
D
	​

(x,y)
m
D
	​

.

Then every admissible entry has the form P/Q. If the independently proved pole bound at the line at infinity is m
∞
	​

, then

degP≤degQ+m
∞
	​

.

Therefore,

{
Q
x
i
y
j
	​

:i,j≥0, i+j≤degQ+m
∞
	​

}

is a complete spanning space for the bounded rational functions.

That is a valid reason for a projective simplex bound. It is not evidence that an unrelated rectangle is complete.

A certified inconsistency in this complete space excludes every rational G in the stated class. Epsilon dependence must also be handled: solving exactly over k(ϵ), or proving a finite regulator reconstruction bound, is different from stopping at a finite Laurent order. Inconsistency even after relaxing the residues to k(ϵ) is sufficient to exclude the stricter residue class.

The geometric model matters: P
2
 supplies a total-degree infinity condition; P
1
×P
1
 supplies separate boundary divisors and naturally different bounds.

4.4 Why the same certificate does not transfer automatically to a multiquadratic surface

For

K=k(x,y)(r
1
	​

,…,r
s
	​

),r
i
2
	​

=Δ
i
	​

,

one needs divisorial information on a model of that field, not just denominator polynomials downstairs.

A sufficient framework is to choose a normal projective model X, account for split and ramified divisors above finite poles and infinity, and prove

G
ij
	​

∈H
0
(X,O
X
	​

(D
ij
	​

))

for explicit bounding divisors. These spaces are finite-dimensional by properness/coherence, but computing a complete basis may require integral-closure or module calculations. A uniform polynomial rectangle attached independently to every root character is not automatically that basis. 
The Stacks Project

Likewise, base-field denominator factors do not necessarily span all admissible logarithmic forms on the cover. Their pullbacks can split into distinct divisors with different residues.

A simple counterexample to a naive “zero residues implies rational primitive” extension is

z
2
=x(x−1)(x−a),a

=0,1,ω=
z
dx
	​

.

On the associated elliptic curve, ω is nonzero and holomorphic, so all residues vanish. It has no rational primitive: a meromorphic function whose differential is holomorphic cannot have poles, hence is constant on the compact curve. The same example extends to the surface obtained by adjoining an independent y.

Thus rational-plane integration criteria cannot simply be reused on a general cover. This is a counterexample to the proposed criterion, not a claim that every system involving this root lacks an epsilon form.

4.5 What is additionally needed for “in any rational frame”

Two possible routes are legitimate.

A gauge-independent invariant may already obstruct the target. For example, with I=TJ,

trA−trA
′
=dlogdetT.

For rational T, its divisorial residues are integers. An incompatible determinant equation can therefore obstruct rational canonicalization without enumerating G. Meyer discusses determinant constraints as part of the rational-transformation analysis. Such trace information, however, is usually insensitive to a purely off-diagonal obstruction. 
arXiv

Alternatively, prove frame completeness: every admissible full-system epsilon form can be aligned with your fixed diagonal bases and prior transformations while preserving the target class and the freedoms retained in the solve. CANONICA’s uniqueness result for rational canonical forms up to constant transformations can help with this alignment, but it does not automatically certify an arbitrary frozen partial completion. 
arXiv

Ordinary constant basis changes are covariances, not escape routes:

(e,c,b,G,R)↦(P
−1
eP, Q
−1
cQ, P
−1
bQ, P
−1
GQ, P
−1
RQ).

Their compatibility systems are equivalent. A proposed alternative presentation should therefore change something mathematically material, not merely rename the same equation.

5. Recommended operational contract

Retain the negative results. Change their scope and their explanatory text, not their usefulness.

The runtime explanation should be something like:

The supplied dlog span is incompatible with the fixed block-completion equation at the tested finite-field images.

When a lift certificate exists:

The supplied dlog span is incompatible with the fixed block-completion equation in characteristic zero, with the stated regulator scope.

Neither sentence diagnoses missing letters. That diagnosis needs additional evidence.

A small distinction between outcomes is sufficient:

Outcome	Mathematical meaning	Appropriate action
Sampled residue inconsistency	Exact inconsistency at recorded images	Deprioritize this completion; retain it as sampling evidence
Certified residue-curvature inconsistency	No completion with the fixed data and target span, independent of G-support	Do not enlarge G’s degree for the same problem
Finite gauge-ansatz inconsistency	No solution in the enumerated support	Consider justified support, denominator, or chart changes
Certified rational no-go	A complete rational search or invariant excludes the explicitly quantified gauge class	Record the theorem and its hypotheses
Timeout, admission refusal, invalid image	No algebraic conclusion	Preserve the general DE or try another affordable route

The existing AlphabetDLogAnsatzInconsistency name can remain, provided its record distinguishes residue-curvature evidence from finite-gauge-ansatz evidence.

Mathematical scope fields worth storing

These do not require a new heavyweight infrastructure layer:

Field group	Essential content
Fixed problem	Family/block pair; diagonal presentation; effective b; previously fixed transformations
Function field	Constant field; root relations; active subfield; chart and whether it is birational or a field extension
Target and gauge	Actual dlog span; residue restrictions; epsilon-independent versus rational-in-epsilon residues; fixed block gauge versus full GL
n
	​

 gauge
Quantifiers	Sampled, specified, or generic ϵ; excluded loci; exact/inherited versus sampled flatness
Evidence	Images, ranks, left witness; optional rank-upper-bound/nonzero-minor lift certificate
Completeness	G-support only when applicable; proved divisor/infinity bounds; alphabet and frame completeness when claimed

A pushed helper merits separate cleanup: OffDiagonalBlockEpsilonFormObstructions.wl can return PrimitiveNotRational after an Integrate-based primitive routine returns $Failed. Failure of that routine is not a proof of nonexistence of a rational primitive. Similarly, a finite sequence of unobstructed Laurent orders is not by itself a proof of a rational-in-ϵ gauge. These observations concern the pushed helper; your uncommitted changes may already address them.

Keep certification off the expensive path

Use the existing screen as a bounded-cost routing decision. Attempt a stronger certificate when it is cheap—particularly the full-column-rank augmented-minor case or already known structural null relations. Do not make every block pay for symbolic witness reconstruction, global surface geometry, or a complete rational nonexistence proof.

A general DE and valid partial transformation remain useful outputs without any nonexistence theorem. The reason for storing them may simply be “the attempted completion was rejected within its stated scope and budget.”

For CF300 (12,9), your retained successful exact solution in the rationalizing two-root chart is the decisive positive record. Its old any-frame obstruction claim must be superseded; an accurately described historical rectangular-support failure may remain. The active rank-two/projective-simplex solution should be a regression fixture. If a later negative claims the identical equation and pulled-back target span, the two cannot both be exact: the scope, arithmetic lift, or implementation must differ.

That conclusion does not transfer to other CF300 blocks or to the separate CF303 (25,18), (25,14), and (25,11) conditional records.

6. Stage-1 performance on three-root systems
Compile once; evaluate values and derivatives numerically

The pushed screen already documents exponent/coefficient compilation and the root chain rule

∂
x
	​

=∂
x
explicit
	​

+
i
∑
	​

2r
i
	​

∂
x
	​

Δ
i
	​

	​

∂
r
i
	​

	​

.

It also has a factor-preserving scalar path, although the visible comments distinguish that value-only path from the derivative-screen compiler. Thus this recommendation is partly an extension of existing machinery, not a claim that compilation is absent.

The desired hot path is:

shared expression plan⟶modular values/first derivatives⟶row assembly⟶rank and witness.

Avoid repeated symbolic branch substitution, Together, or whole-expression expansion inside the prime/point/sign loops. Preserve factored expressions and compute derivative jets through the same native plan. Batch points and branches so interpreter/native-boundary overhead is amortized.

For a character representation

f=
χ∈(Z/2)
r
∑
	​

f
χ
	​

r
χ
,

sign changes act by (−1)
σ⋅χ
. All-sign values and character components are related by a Walsh–Hadamard transform when the sampled roots are nonzero and the characteristic is not two. This can replace repeated symbolic conjugation with small numerical transforms. But obtaining a full symbolic character decomposition must not itself become the expensive prerequisite for a cheap screen.

Determine active root rank from the whole block problem

Inspect e,c,b, the target forms, and all deferred dependencies—not just the family label or one forcing entry.

Three named roots do not imply rank three. For example, support generated only by r
1
	​

r
2
	​

 and r
2
	​

r
3
	​

 has character rank two.

There is also a rigorous reason that active-field reduction can be safe here. Suppose the entire fixed linear completion problem is defined over K
0
	​

, and K/K
0
	​

 is finite separable. If G∈K solves it, then

G
=
[K:K
0
	​

]
1
	​

Tr
K/K
0
	​

	​

G

also solves it, because differentiation commutes with the trace and the coefficients lie in K
0
	​

. Thus the linear block problem can descend to the active subfield.

This argument requires the target forms and residue constants to be included correctly. It does not justify averaging arbitrary invertible full gauges: an averaged matrix can be singular.

For your CF300 (12,9) fixture, active rank two means four genuine sign branches rather than eight. That is a structural reduction, not a guaranteed factor-two end-to-end speedup.

Benchmark completed work, not one attractive subroutine

Measure separately:

t
total
	​

=
	​

t
extraction/root analysis
	​

+t
compilation
	​

+t
evaluation/jets
	​

+t
row assembly
	​

+t
residue solve/witness
	​

+t
gauge solve/reconstruction
	​

+t
verification
	​

+t
I/O
	​

.
	​


Use cold and warm runs with the same inputs, actual supports, primes, points, native thread counts, and downstream acceptance checks. Record wall time, total CPU, peak memory, matrix dimensions and sparsity, active rank, number of evaluated branches, and cache reuse.

The useful comparisons are screen enabled versus disabled; interpreted versus native batches; family-root versus active-root evaluation; and support choices that still contain the required solution. Keep successful solves, conditional rejections, and budget exhaustion separate. Include the rank-two CF300 positive fixture and genuinely rank-three cases rather than reporting all of CF300 as a three-root benchmark.

The resulting policy is precise: sampled negatives guide scheduling; lifted curvature negatives exclude the fixed completion regardless of G’s ansatz; proved function-space bounds exclude all rational G in the declared field; and only an invariant or frame-completeness argument supports an any-frame rational no-go.