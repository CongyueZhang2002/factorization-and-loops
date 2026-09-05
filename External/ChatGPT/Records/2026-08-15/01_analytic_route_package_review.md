# Analytic Route Package Review

## Question

The attached file is a working prototype for FACET's exact analytic-route classifier. It has now reproduced the known class-115 reduction exactly: the flat two-variable connection is proved to be the pullback of a one-variable connection with z = v w, and the resulting system is converted to an exactly equivalent second-order scalar equation. The production requirement is an exact analytic cut master, including epsilon and physical-branch information; fixed-point numerics are only independent checks.

Please review the attached Wolfram Language implementation line by line at the mathematical-algorithm level. In particular:

1. Identify any exactness, completeness, scoping, or complexity defects in the polynomial first-integral search, pullback verification, and cyclic scalar-operator construction.
2. Propose a deterministic classification sequence that can be made into reusable functions. Separate cheap tests that should run on every irreducible differential block from expensive tests reserved for unresolved blocks or genuinely new boundary periods.
3. Survey established analytic packages beyond our installed set. We already know CANONICA, Libra, SubTropica/HyperFLINT, HPL, PolyLogTools, AMFlow, Package-X, BaikovPackage, DlogBasis, SOFIA, INITIAL, MultiHypExp and MBConicHulls. Please consider wider amplitude and computer-algebra tools, especially exact holonomic/creative-telescoping software, hyperlogarithmic integration, Mellin-Barnes summation, recurrence solving, dlog/leading-singularity construction, finite or quasi-finite basis construction, and Picard-Fuchs factorization.
4. For each recommended package, state exactly what analytic object it returns, the mathematical input it requires, whether it preserves a physical cut/branch by construction or needs a separate certificate, and a concrete benchmark we should run before incorporating it.
5. We have a verified rational epsilon-form 4x4 CF300/PID26 block whose remaining difficulty is boundary periods. Explain which geometry/basis tools can still reduce the boundary work and which would merely repeat a solved canonicalization problem.

Do not recommend a numerical evaluator as the main analytic route. Do not assume every cut period is linearly reducible. Prefer community-standard packages over new custom algebra, but identify the small exact glue algorithms that still need to be written locally.

## Pro response

Overall assessment

The class-115 result can be accepted as an exact result provided the retained record contains three separate identities:

∂
v
	​

A
w
	​

−∂
w
	​

A
v
	​

+A
w
	​

A
v
	​

−A
v
	​

A
w
	​

=0,
A
v
	​

=(∂
v
	​

z)B(z),A
w
	​

=(∂
w
	​

z)B(z),z=vw,

and, for the selected scalar component f=cI,

L
z
	​

f=0,I=Q(z)
−1
	​

f
f
′
⋮
f
(n−1)
	​

	​

.

The prototype proves the first identity and most of the second, and its cyclic-row recursion is mathematically correct. It does not yet prove the full rational-field statement B∈Q(ϵ,z)
n×n
 robustly, and it does not return the state-reconstruction identity needed to call the scalar equation globally equivalent to the system.

The production classifier should distinguish at least:

DirectPfaffianRankOne,LocalSingleInvariant,RationalSingleInvariantPullback,AlgebraicSingleInvariantPullback.

The present Boolean "OneVariable" conflates these.

1. Audit of the Wolfram Language implementation
A. Rational normalization and exact-zero tests: lines 22–35
What is correct
Wolfram Language
rat[expr_] := Cancel[Together[expr]]

is an exact normal form for an expression already known to lie in a rational function field.

Defects
1. The coefficient field is never declared or checked

The functions silently assume entries in a field such as

K=Q(ϵ,v,w,…).

They do not reject:

machine reals;

ConditionalExpression;

branch-sensitive powers;

Root objects outside a declared algebraic extension;

hidden special functions;

dependence on undeclared variables.

Cancel[Together[expr]] can treat undeclared analytic objects as coefficients, which may be acceptable for some algebra, but then the result is not a rational connection over the advertised field.

Correction: make the field grammar explicit:

Wolfram Language
"Variables" -> {v,w},
"Parameters" -> {Epsilon, CA, CF},
"KinematicIdeal" -> {},
"AlgebraicExtensions" -> {}

and validate every entry before any classification.

2. exactZeroQ does not reduce modulo kinematic relations
Wolfram Language
exactZeroQ[expr_] := ...

tests literal rational equality. It does not test equality modulo an ideal such as

Q
2
−s−t−u=0

or a declared algebraic relation among coordinates.

For independent dimensionless variables this is fine. For a reusable classifier, exact zero should mean

NF
K
	​

(numerator(Togetherf))=0,

where NF
K
	​

 is polynomial reduction modulo the kinematic ideal.

3. firstNonzeroPosition chooses a poor pivot arbitrarily

It selects the first nonzero entry in row-major order. The resulting ratio

ρ=
(A
x
	​

)
ij
	​

(A
y
	​

)
ij
	​

	​


may be much more complicated than another valid pivot and may introduce avoidable exceptional divisors.

Use the nonzero entry of A
x
	​

 minimizing a deterministic complexity measure such as:

degnum+degden+LeafCount.

Also record the pivot divisor; the pullback certificate is initially valid only where that pivot does not vanish.

4. Repeated global Together is the principal complexity risk

The Krylov recursion and matrix flatness checks repeatedly call Together entry by entry. For larger blocks this will dominate.

Use:

common denominator extraction per matrix;

fraction-free matrix differentiation;

sparse polynomial maps;

modular zero detection followed by exact certification;

Ore-system packages for uncoupling rather than repeated native symbolic elimination.

B. CheckExactConnection: lines 37–56
What is correct

For a column-vector system

∂
x
	​

I=A
x
	​

I,∂
y
	​

I=A
y
	​

I,

the code computes

∂
x
	​

A
y
	​

−∂
y
	​

A
x
	​

+A
y
	​

A
x
	​

−A
x
	​

A
y
	​

.

This sign convention is correct.

Missing conditions

The function should also verify:

all variables are distinct unassigned symbols;

every matrix is square;

all matrices have the same dimension;

every entry belongs to the declared exact field;

no matrix depends on undeclared coordinates;

the connection is regular on at least one generic point in the physical chamber;

zero curvature holds modulo the kinematic ideal.

Currently an association with rectangular or differently sized matrices may survive the initial structural check until matrix arithmetic fails.

Recommended output

Return:

Wolfram Language
<|
  "Dimension" -> n,
  "Field" -> ...,
  "Curvatures" -> ...,
  "Flat" -> True,
  "SingularDivisor" -> ...,
  "ExceptionalParameterDivisor" -> ...
|>

Flatness should not be the only universal cheap diagnostic; singular-divisor extraction should happen at the same stage.

C. polynomialFirstIntegral: lines 60–98

Let

ρ=
q(x,y)
p(x,y)
	​

.

The direct-pullback condition requires a nonconstant z(x,y) satisfying

∂
y
	​

z−ρ∂
x
	​

z=0,

or equivalently

q∂
y
	​

z−p∂
x
	​

z=0.

The code implements this equation correctly.

Exact logical strength

After correction, this routine can be complete only for polynomial first integrals of total degree at most maxDegree, over generic values of the parameters. It is not a complete first-integral finder.

A negative result must be reported as:

NoPolynomialFirstIntegralFoundWithinDegreeBound

not as evidence that no one-variable reduction exists.

Correctness defect: valid z=x is rejected

The filter requires

Wolfram Language
! exactZeroQ[D[candidate,x]] &&
! exactZeroQ[D[candidate,y]]

A valid invariant may depend on only one coordinate. For example, if

ρ=0,

then

z=x

is a valid first integral, but ∂
y
	​

z=0, so the routine rejects it.

The correct condition is

(∂
x
	​

z,∂
y
	​

z)

=(0,0),

implemented as:

Wolfram Language
! (exactZeroQ[D[candidate,x]] &&
   exactZeroQ[D[candidate,y]])
Missing polynomial validation

Before CoefficientRules, require

Wolfram Language
PolynomialQ[numerator, {x,y}] &&
PolynomialQ[denominator, {x,y}]

over the declared coefficient field.

Generic-parameter issue

NullSpace over symbolic parameters computes a generic nullspace. Its basis may change on exceptional loci in ϵ or other parameters. The denominator of the resulting nullspace vectors must be retained as an exceptional-parameter divisor.

Search-space complexity

The number of nonconstant monomials through degree d is

N
d
	​

=
2
(d+1)(d+2)
	​

−1.

The nullspace problem grows rapidly with d, particularly with symbolic coefficients. The every-block search should therefore stop at a small degree, probably d=2 or 3. Degree 4+ belongs in the unresolved-block escalation.

Incompleteness beyond polynomials

The routine misses rational first integrals such as

z=
Q(x,y)
P(x,y)
	​


when no polynomial generator exists. A bounded rational ansatz is nonlinear in the coefficients of P,Q; it should not be implemented by simply extending the current linear nullspace.

For expensive escalation, use Darboux-polynomial or rational-first-integral algorithms, or accept candidate invariants from geometry and verify them exactly.

Minor defect

This branch is unnecessary and potentially unsafe:

Wolfram Language
If[TrueQ[equation === 0],
  result = First[monomials];
  Break[]
]

If the whole ansatz equation vanishes, return a validated nonconstant monomial rather than assuming the first one is suitable.

D. firstIntegralFromPDE: lines 100–114

This is a heuristic, not a deterministic classifier.

Problems

DSolveValue is not a complete rational-first-integral algorithm.

Its output format for arbitrary functions is version dependent.

Extracting the first argument of C[_][argument] is syntactic.

The 120-second limit is hard-coded.

The resulting argument may be algebraic, transcendental, conditional, or branch dependent.

rat is applied before its field is known.

The subsequent code does verify the candidate equation, which prevents a false positive in many cases. But production should label this source:

HeuristicCandidateFromDSolve

and accept it only after the same exact pullback verification as a user-supplied candidate.

I would remove DSolve from the default every-block route. Keep it as a suggestion generator for unresolved two-variable blocks.

E. invariantMatrix: lines 116–135

The routine forms

B(x,y)=
∂
x
	​

z
A
x
	​

	​


and checks

(∂
y
	​

z)∂
x
	​

B−(∂
x
	​

z)∂
y
	​

B=0.

This tangent derivative is correct: it tests whether B is constant along the level sets of z.

Main conceptual defect

The condition

(∂
y
	​

z)∂
x
	​

B−(∂
x
	​

z)∂
y
	​

B=0

proves only that B is locally constant along the leaves. It does not prove that

B∈K(z)
n×n
.

For example, B may be algebraic over K(z). The function currently names this condition "DependsOnlyOnInvariant", which is too strong.

Rename it:

"TangentDerivativeZero"

and reserve "RationalGeneratorInInvariant" for a later exact field-membership test.

Chart issue

Division by ∂
x
	​

z is valid only on the chart

∂
x
	​

z

=0.

The routine must return its chart divisor and, if needed, a second chart based on ∂
y
	​

z.

API defect

The function receives one matrix, not both A
x
	​

,A
y
	​

. A reusable verifier should receive the complete connection and select the valid chart itself.

F. FindSingleInvariantConnection: lines 143–213
Correct part

The exact proportionality test

A
y
	​

−ρA
x
	​

=0

is a valid cheap test for a direct pullback in the current basis.

It is not a test for a connection that becomes one-variable after a gauge transformation.

Completeness limitation

A connection may satisfy

A=G
−1
B(z)G\ddz−G
−1
\ddG

without A
x
	​

 and A
y
	​

 being scalar proportional. The current function will classify such a connection as not one-variable.

Rename the mathematical claim:

DirectSingleInvariantPullbackInCurrentBasis
Zero-connection case
Wolfram Language
"OneVariable" -> False,
"Reason" -> "Zero connection"

is misleading. The zero connection is a trivial pullback of every variable.

Return:

"Class" -> "TrivialConnection"
A
x
	​

=0 branch

When A
x
	​

=0 and A
y
	​


=0, flatness implies

∂
x
	​

A
y
	​

=0.

The routine returns a one-variable result without checking that condition locally. AnalyzeMasterAnalyticRoute checks flatness beforehand, but the public function should be correct independently.

Candidate-list construction
Wolfram Language
DeleteDuplicates@Flatten@{...}

can destroy structured candidates and conditions. Build the list explicitly with Join and remove only Missing objects.

Candidate verification divides by ∂
x
	​

z

The filter tests

∂
x
	​

z
∂
y
	​

z
	​

−ρ=0.

This:

excludes valid z=x only if earlier search fails;

introduces avoidable singularities;

risks 0/0.

Use the cross-multiplied equation:

q∂
y
	​

z−p∂
x
	​

z=0.
Premature positive classification

The function can return "OneVariable" -> True from:

scalar proportionality;

tangent derivative zero;

pullback in x,y.

It has not yet proved that the generator is a rational matrix in z.

The correct hierarchy is:

"PfaffianRank" -> 1
"InvariantVerified" -> True
"LocalLeafConstantGenerator" -> True
"GeneratorField" -> "Unresolved"

Only after exact field membership should it return:

"Class" -> "RationalSingleInvariantPullback"
Physical-domain condition

For use as a physical variable, also record:

the critical set \ddz=0;

whether z is real on the physical chamber;

the image interval of the chamber;

the endpoint direction;

whether multiple sheets are involved.

The DE may be a local pullback even when z is not globally injective. That distinction matters for branch transport.

G. expressGeneratorInInvariant: lines 275–290

This is the weakest correctness point in the prototype.

Problems

It uses Solve to choose an inverse branch.

It accepts the first branch that eliminates x,y.

It does not verify

B(x,y)=
B
(z(x,y))

after choosing the candidate.

It may accept radicals or ConditionalExpression.

It does not identify the coefficient field.

It is incomplete when Solve does not provide an explicit inverse.

For z=vw, the method happens to work cleanly because

w=
v
z
	​


is rational and the unwanted v-dependence cancels. That success should be retained as an exact class-115 certificate, but the function is not general.

Minimum correction

For every candidate 
B
(z), require exactly:

B(x,y)−
B
(z(x,y))=0.

Return one of:

"GeneratorField" -> "Rational"
"GeneratorField" -> "Algebraic"
"GeneratorField" -> "Unresolved"

and retain every inverse-branch condition.

Better exact approach

For the common case where z=P(x,y)/Q(x,y) is linear in one coordinate:

solve rationally for that coordinate;

substitute into each entry of B;

require independence of the transverse coordinate;

reconstruct 
B
(z);

substitute back and prove exact equality.

For nonlinear cases, use elimination or algebraic-function-field machinery. Do not infer rationality merely from the vanishing tangent derivative.

H. BuildCyclicScalarOperator: lines 215–248
What is mathematically correct

For the system

I
′
=AI

and row covector c
0
	​

, the recursion

c
k+1
	​

=c
k
′
	​

+c
k
	​

A

is correct, because

\ddz
k
\dd
k
	​

(c
0
	​

I)=c
k
	​

I.

The coefficient solve is also oriented correctly. If

Q=
	​

c
0
	​

c
1
	​

⋮
c
n−1
	​

	​

	​

,

then solving

Q
T
a=c
n
T
	​


gives

c
n
	​

=
k=0
∑
n−1
	​

a
k
	​

c
k
	​

.
Naming defect

The returned "ReconstructionMatrix" is actually

Q
T
,

not the matrix that maps the state to the derivative vector.

The exact equivalence uses

	​

f
f
′
⋮
f
(n−1)
	​

	​

=QI,I=Q
−1
	​

f
f
′
⋮
f
(n−1)
	​

	​

.

Return:

"ObservabilityMatrix" -> Q
"StateReconstructionMatrix" -> Inverse[Q]
Missing equivalence domain

The scalar equation is equivalent to the full system only on

detQ(z,ϵ)

=0.

Zeros of detQ may generate apparent singularities in the scalar ODE. The determinant and its factorization must be part of the classification record.

Missing exact reconstruction check

In addition to the last-row relation, verify the complete companion gauge identity:

Q
′
+QA=CQ,

where C is the companion matrix constructed from the scalar coefficients.

This proves both the scalar equation and reconstruction of the original system.

Operator representation is inadequate

The held equation is useful for display, but factorization requires the Ore operator

L=∂
z
n
	​

−
k=0
∑
n−1
	​

a
k
	​

(z,ϵ)∂
z
k
	​

.

Return:

numerator-cleared primitive operator;

monic rational operator;

leading coefficient;

singular divisor;

indicial polynomials;

observability determinant.

Symbol scoping

The displayed scalar function y is an unlocalized private symbol. Use a supplied scalar head or return the operator rather than a held equation.

Complexity

AppendTo, repeated differentiation, repeated Together, symbolic determinant, and symbolic LinearSolve will grow badly.

For production, use OreSys or another established uncoupling implementation, then independently verify its operator and reconstruction. OreSys is specifically a Mathematica package for uncoupling systems of linear differential or difference equations into higher-order scalar equations. 
RISC - Johannes Kepler University

I. FindCyclicScalarOperator: lines 250–273
Incompleteness

The tested covectors are:

e
i
	​

,e
1
	​

+e
i
	​

,(1,…,1).

Failure of this finite set does not imply absence of a cyclic covector. The cyclic-vector theorem guarantees cyclic vectors over the differential field under broad conditions, but the cyclic vector may not occur in this list.

Return:

"Status" -> "NoCyclicCovectorFoundAmongTestedCandidates"

not simply "Cyclic" -> False.

“Smallest scalar equation” is misleading

Every cyclic covector for an n-dimensional system produces an order-n equation. The code minimizes LeafCount, not order.

Rename the function or usage string to:

FindLowestComplexityTestedCyclicOperator
Timeout semantics

The 300-second limit is applied separately to every candidate, so total runtime can be proportional to the number of candidates. Timeouts are discarded before the final result, making “no tested covector” indistinguishable from “all difficult candidates timed out.”

Return complete per-candidate diagnostics.

Better production route

Use:

OreSys for exact uncoupling;

ore_algebra for operator normalization, factorization, desingularization, local series, and exact operator arithmetic. ore_algebra provides Ore-polynomial factorization-related arithmetic, creative telescoping, desingularization, and generalized power-series solvers. 
SageMath
+1

The local Wolfram implementation remains valuable as an independent verifier.

J. AnalyzeMasterAnalyticRoute: lines 298–344
Wrong decision ordering

The code prioritizes a second-order scalar operator over a verified epsilon form:

Wolfram Language
scalar order 2 -> Picard-Fuchs route
...
epsilonForm -> iterated-integral route

For a block with an exactly verified rational dlog epsilon form, the kinematic function class is already constructively known. Scalarization may simplify a special calculation, but it is not the next required route.

The order should be:

exact verified rational dlog form;

direct one-invariant pullback as an optional simplification;

scalar-operator classification only for unresolved diagonal blocks;

geometry/parametric escalation.

The epsilon-form flag is not a certificate
Wolfram Language
"VerifiedEpsilonForm" -> True

is trusted without checking:

T
−1
A
i
	​

T−T
−1
∂
i
	​

T=ϵ
a
∑
	​

R
a
	​

∂
i
	​

logϕ
a
	​

.

The report’s earlier false 87/91 count arose precisely from accepting a structural shape instead of exact reconstruction; only 40 blocks were verified after applying the exact dlog gate. 

pasted-text

Pass a complete epsilon-form certificate, not a Boolean.

"ExactDiagnosticsComplete" overstates the result

The returned state is used even when:

invariant discovery is inconclusive;

generator field membership fails;

scalarization times out;

only a finite covector set was tested.

Use stage-specific states:

ConnectionVerified
DirectPullbackVerified
InvariantSearchInconclusive
RationalGeneratorNotEstablished
ScalarUncouplingInconclusive
Route strings are too coarse

The classifier should return mathematical objects and exact next tests, not prose-only recommendations.

2. Deterministic production classification sequence
Cheap stages for every irreducible differential block
Stage A0 — exact connection validation

Input

(x,ϵ,K,C,{A
i
	​

}).

Output

A normalized rational connection and its singular divisor.

Exact criterion

common square dimension;

every entry in the declared field;

exact data only;

exact flatness modulo K.

Fallback

Reject the block and repair the derivative/IBP construction.

Stage A1 — verified epsilon-form gate

Input

Candidate T, residues R
a
	​

, letters ϕ
a
	​

.

Output

Either a verified rational dlog system or a failed certificate.

Exact criterion

T
−1
A
i
	​

T−T
−1
∂
i
	​

T=ϵ
a
∑
	​

R
a
	​

∂
i
	​

logϕ
a
	​


for every i, with R
a
	​

 constant and T invertible.

Consequence

A verified rational dlog form is a constructive certificate for the block’s kinematic transport. Do not require Picard–Fuchs classification before proceeding to its boundary problem.

Stage A2 — cheap direct-pullback test

Vectorize the matrices and test whether the connection one-form has rank one over the rational field:

A
i
	​

=ρ
i
	​

A
⋆
	​

.

For two variables, this means all exact 2×2 minors of

(
vecA
x
	​

vecA
y
	​

	​

)

vanish.

Output

PfaffianRank = 0, 1, or >1

This avoids relying on one arbitrary matrix entry.

Stage A3 — cheap invariant verification

Try, in order:

user- or geometry-supplied candidates;

monomial candidates

z=x
a
y
b
;

simple rational products and ratios;

polynomial first integrals through degree 2 or 3.

Exact criterion

q∂
y
	​

z−p∂
x
	​

z=0,\ddz

≡0.

A bounded search failure is inconclusive.

Stage A4 — exact pullback-field verification

Given z, construct B on a valid chart and require:

A
i
	​

=(∂
i
	​

z)B,
(∂
y
	​

z)∂
x
	​

B−(∂
x
	​

z)∂
y
	​

B=0,

and finally

B(x,y)=
B
(z(x,y))

for an explicitly reconstructed 
B
.

Output

One of:

RationalSingleInvariantPullback
AlgebraicSingleInvariantPullback
LocalSingleInvariantOnly
Unresolved

Record the chart and exceptional divisors.

Stage A5 — singularity and residue pre-pass

For every block, regardless of route, compute:

irreducible singular divisors;

Poincaré ranks;

residue spectra;

candidate physical and apparent loci.

This is cheap relative to integration and informs later boundary choices.

Expensive stages only for unresolved diagonal blocks
Stage B1 — exact uncoupling

Use OreSys or a verified local cyclic-vector algorithm.

Output

Lf=0

plus exact reconstruction of the original state.

Acceptance

Q
′
+QA=CQ,detQ

≡0.
Stage B2 — Ore-operator classification

Use ore_algebra to:

primitive-normalize L;

desingularize;

factor over the declared rational/algebraic field;

compute local exponents and generalized series.

A scalar operator derived from an integral period is a Picard–Fuchs
annihilator. Call it the minimal Picard–Fuchs operator only after
cyclicity/minimality or an independent minimal-order proof.

Stage B3 — geometry escalation

Only when the diagonal block remains unresolved:

leading singularities and dlog candidates;

loop-by-loop Baikov;

maximal cut;

Picard–Fuchs factorization;

Landau/SOFIA candidate singularities;

rational/algebraic/elliptic classification;

geometry-adapted basis attempt.

A failed canonicalizer is not an ellipticity certificate.

Expensive stages only for genuinely new boundary periods
Stage C1 — residual boundary nullity

Before integrating anything, assemble all exact inherited constraints and
compute

n
free
	​

=dimkerC(ϵ).
Stage C2 — direct physical representation

Derive a branch-certified phase-space integral for a minimal basis of the
residual nullspace.

Stage C3 — analytic route classifier

Apply, in order:

known formula or inherited period;

Euler/beta/Gauss/Appell recognition;

SubTropica/HyperInt/HyperFORM if linearly reducible;

holonomic creative telescoping;

GKZ/hypergeometric series;

Mellin–Barnes plus exact summation;

physically certified finite/quasi-finite cut basis;

elliptic/general period methods.

Numerical transport remains a separate comparison.

3. Established packages worth adding
OreSys

Returns: exact uncoupled scalar differential or recurrence equations from a coupled linear Ore system.

Input: a coupled rational differential system.

Cut/branch: none; it manipulates the differential module, not the physical cycle.

Benchmark: feed the class-115 one-variable matrix and require the same second-order operator as the prototype, together with exact reconstruction of the original two-component state. OreSys is expressly intended for uncoupling systems of linear Ore equations. 
RISC - Johannes Kepler University

Recommendation: first external package to test. It directly replaces the least complete part of the current prototype.

ore_algebra

Returns: exact Ore operators; factorization-related arithmetic, gcrd/lclm, desingularization, creative telescoping, and generalized power-series solutions.

Input: scalar differential operators or D-finite objects over a declared coefficient field.

Cut/branch: no physical branch information; boundary conditions remain external.

Benchmark: export the class-115 operator over
Q(ϵ,z); require exact round-trip equality, singular loci,
indicial exponents, and factorization. Then test the known NLO hypergeometric
operator. 
SageMath
+1

Recommendation: production operator backend.

HolonomicFunctions

Returns: annihilating ideals, telescopers, and creative-telescoping certificates for holonomic sums and integrals.

Input: a holonomic or hyperexponential integrand with an annihilating ideal and an integration variable.

Cut/branch: not preserved automatically. The telescoping certificate must be integrated over the physical endpoints, including all nonzero boundary terms.

Benchmark: use the NLO Euler integral

h(z,ϵ)=∫
0
1
	​

1−zτ
(1−τ)
−1−ϵ
	​

\ddτ.

The package must reproduce either the inhomogeneous first-order equation,
including the bubble boundary term, or the homogeneous second-order operator.
Dropping the endpoint term is a failed benchmark. HolonomicFunctions supports
annihilating ideals, closure operations, integration, and creative
telescoping. 
RISC - Johannes Kepler University
+1

Caution: the official Mathematica release is old, so compatibility with
the active Wolfram version must be tested before relying on it. 
RISC - Johannes Kepler University

Lairez–Vanhove Griffiths–Dwork algorithms

Returns: exact Picard–Fuchs operators for rational projective period
integrals, with algorithms aimed at minimal operators.

Input: a rational projective integral or graph-polynomial representation.

Cut/branch: the operator is branch neutral; it annihilates all periods in
the relevant local system. The physical positive-energy cycle and boundary
constant remain separate.

Benchmark: apply the method to a rationalized representation of class 115
or a known selected boundary period and compare the resulting minimal operator
with the uncoupled DE operator. The method derives Fuchsian
Picard–Fuchs operators and has been used to distinguish Liouvillian and
elliptic sectors. 
arXiv
+1

Recommendation: escalation tool, not an every-block dependency. I did not
find a polished general-purpose public package interface comparable to
ore_algebra; treat available implementations as research code until
benchmarked.

Macaulay2 Dmodules or Singular dmod.lib

Returns: annihilating ideals, holonomic-system data, Bernstein–Sato
objects, and algebraic D-module constructions.

Input: polynomial/rational integrands represented in Weyl algebras.

Cut/branch: none. Integration ideals do not select the physical cut cycle.

Benchmark: a small rational boundary density for which the exact
annihilator is already known. Require the integration ideal to contain the
known scalar operator and verify its certificate algebraically.
Macaulay2’s Dmodules collection includes Weyl-algebra, holonomic-system, and
Bernstein–Sato functionality; Singular provides dedicated algebraic
D-module libraries. 
Macaulay2
+1

Recommendation: geometry research tool for difficult cases, not the first production route.

HyperInt and HyperFORM

Returns: exact hyperlogarithmic or multiple-polylogarithmic expressions
for linearly reducible parametric integrals.

Input: a rational parametric integrand and an integration order for which
the singular polynomials are linearly reducible.

Cut/branch: only insofar as the supplied parameterization and domain
already encode it. Neither package determines the physical cut contour.

Benchmark: first use a known NLO or selected NNLO boundary period through
the required ϵ order. Require exact agreement with the retained
analytic expression and exact reconstruction of the original real-domain
integral. HyperInt implements symbolic integration of hyperlogarithms with
rational functions; HyperFORM provides analogous functionality in FORM for
larger expressions. 
arXiv
+1

Recommendation: HyperInt for initial integration tests; HyperFORM when
expression size becomes the bottleneck.

FeynGKZ

Returns: a GKZ system and local hypergeometric series solutions obtained
from triangulations or Gröbner deformations.

Input: a Lee–Pomeransky/Euler–Mellin representation, together with its
polynomial data.

Cut/branch: local series cones do not select the physical cut branch.
The physical chamber and connection coefficients must be supplied separately.

Benchmark: a boundary period already known to reduce to an Appell or
other multivariate hypergeometric function. Require matching differential
operators, convergence cone, and exact series coefficients. FeynGKZ derives
GKZ systems and hypergeometric series for one- and two-loop examples.

arXiv
+1

Recommendation: useful when the boundary density visibly has Euler–Mellin structure; not a generic block classifier.

AMBRE, MB.m, MBresolve, and MBsums

Returns:

AMBRE: Mellin–Barnes representations;

MB.m: analytic continuation in ϵ and singularity resolution;

MBresolve: an alternative singularity-resolution algorithm;

MBsums: multiple residue sums.

Input: a Feynman-parameter or loop-by-loop integral with a chosen MB
decomposition and contours.

Cut/branch: not automatic. The physical causal phases, contour positions,
closure direction, and convergence regions must be derived from the original
physical integral.

Benchmark: one residual boundary period that is not immediately linearly
reducible but has a low-dimensional MB representation. Require:

exact reconstruction of the physical integral;

exact ϵ-continuation;

consistent residue cones;

exact agreement with a known Laurent series.

The package roles are documented in their original papers.

arXiv
+3
arXiv
+3
arXiv
+3

Recommendation: fallback for isolated periods, not a bulk 4×4-system route.

Sigma, EvaluateMultiSums, and HarmonicSums

Returns: exact recurrence solutions and nested-sum or iterated-integral
representations when the sums lie in the supported difference-field classes.

Input: hypergeometric or nested sums, often obtained from MB residues,
series solutions, or coefficient recurrences.

Cut/branch: series convergence and analytic continuation must be matched to
the physical chamber separately.

Benchmark: convert a known MB representation to sums and require exact
reproduction of a known NLO or NNLO period through ϵ
2
.
Sigma/EvaluateMultiSums are designed for symbolic nested summation in loop
integrals, while HarmonicSums manipulates harmonic, generalized, and
cyclotomic sums and their iterated-integral counterparts.

arXiv
+1

Recommendation: pair with MBsums or formal series recurrences; not useful on an unsummed physical integral by itself.

Quasi-finite and finite-basis constructions

Returns: exact IBP/dimensional-recurrence relations to shifted-dimensional
and/or dotted integrals with improved convergence properties.

Input: a complete family, dimensional recurrences, IBP rules, and a
power-counting analysis.

Cut/branch: the standard quasi-finite construction is cleanest in Euclidean
kinematics. It does not certify convergence or causal meaning on a
positive-energy cut cycle.

Benchmark: choose one difficult CF300/PID26 residual boundary period.
Construct one shifted/dotted candidate and require:

B
(D)
=
i
∑
	​

r
i
	​

(D)
B
i
(D+2r
i
	​

)
	​


exactly, positive physical cut indices, the same cut orientations, a nonempty
physical convergence domain, and exact reconstruction after dimensional
lowering. Quasi-finite bases expose divergences through shifted dimensions
and higher propagator powers, but their standard construction is formulated
for Euclidean Feynman integrals. 
arXiv

A newer method constructs locally finite higher-dimensional integrals and
relations among fixed-order ϵ-expanded master coefficients, but
its applicability to oriented cut phase space still requires a separate
physical-cycle proof. 
arXiv

Recommendation: selective boundary optimization, not a universal replacement basis.

4. Small exact glue algorithms FACET still needs

Even after adopting established packages, the following local code remains necessary.

1. Rational-connection validator
ValidateExactConnection

It must know the coefficient field, kinematic ideal, exactness grammar,
singular divisor, and physical chamber.

2. Direct-Pfaffian-rank detector
ConnectionOneFormRank

Compute the rank of the span of the vectorized A
i
	​

 over the rational
field without choosing an arbitrary pivot.

3. Exact invariant verifier
VerifyFirstIntegral[rho,z]

Check the cross-multiplied PDE and nonvanishing gradient, returning chart and
critical divisors.

4. Rational subfield membership
ExpressConnectionInInvariantField

Prove that every entry of B(x,y) lies in K(z), reconstruct

B
(z), and verify by substitution.

This is the most important missing exact glue.

5. Scalar-equivalence verifier

Given an OreSys or local cyclic result, verify:

Q
′
+QA=CQ,I=Q
−1
f
der
	​

.
6. Physical-branch wrapper

No algebra package above knows that a solution is the desired
positive-energy cut. FACET must attach:

(Γ,C,cuts,causal signs,endpoint mode)

to every operator, series, and boundary period.

7. Exact route state machine

Do not use one Boolean. Use a finite set of proved states and keep
Undetermined distinct from False.

5. The verified CF300/PID26 4×4 epsilon-form block

For this block, the bulk kinematic problem is already solved if the retained
certificate proves

\ddJ=ϵ
a
∑
	​

R
a
	​

\ddlogϕ
a
	​

J.
Tools that remain useful
Libra

Still useful for:

generalized local series;

residue/Jordan analysis;

determining which original-basis asymptotic coefficients are needed;

noncommuting fixed-depth transport.

Libra explicitly includes epsilon-form transformations, generalized
power-series solutions, and tools for identifying the boundary coefficients
needed to fix a solution. 
arXiv

Leading singularities and maximal cuts

Useful only insofar as they:

identify a simpler normalized top period;

show that several boundary constants are one period;

expose a factorized or inherited homogeneous boundary solution;

suggest a boundary integral with constant leading singularity.

They are no longer needed to classify the bulk 4×4 function space.

Finite or quasi-finite cut representations

Potentially very useful for a difficult residual boundary period. They may
turn a sector-decomposed divergent density into a directly expandable
convergent one, provided the cut-specific checks above are satisfied.

HolonomicFunctions or Lairez–Vanhove methods

Useful on the boundary period itself if it retains a deformation
parameter. They can derive an exact scalar operator that may identify a
Gauss, Appell, Liouvillian, or elliptic structure.

HyperInt/HyperFORM/SubTropica

Use first if the exact physical boundary representation is linearly reducible.

FeynGKZ

Use when the boundary representation has a small Euler–Mellin polynomial and
a recognizable hypergeometric cone.

Mellin–Barnes plus Sigma

Use when the boundary integral yields a low-dimensional MB representation
whose residue sums are tractable.

Tools that would mainly repeat solved work

For the bulk CF300/PID26 connection:

another unrestricted CANONICA run;

a new dlog-basis search;

SOFIA solely to rediscover the existing alphabet;

a Picard–Fuchs operator merely to establish polylogarithmic kinematic
transport;

scalarization of the whole 4×4 system with no boundary objective.

A scalar operator may still be useful if a specific boundary combination
decouples to order one or two, but that is a boundary simplification, not
a reclassification of the verified epsilon-form block.

Recommended CF300/PID26 order
	​

verified 4×4 epsilon form
⟶exact boundary family and local modes
⟶inherit lower periods and compute residual nullity
⟶choose a minimal new-period basis
⟶
⎩
⎨
⎧
	​

direct Euler/SubTropica/HyperInt,
finite cut representation,
holonomic/GKZ/MB route,
	​

⟶Libra transport
⟶exact original-DE and boundary residuals.
	​

	​


The geometry tools should now be judged by whether they reduce the dimension
or analytic difficulty of the boundary nullspace, not by whether they
can rediscover the already verified canonical connection.

## Sources sent to Pro

- Original source reference: `../../MasterEvaluationWorkflow/PackageEvaluation/MasterAnalyticRoutePrototype.wl` (not archived with this exchange)
