# CF48 Tool

## Question

We need a technically decisive review of an exact analytic epsilon-form problem. Please inspect the attached measured CF48 note rather than answering generically.

The system is a flat two-variable differential connection for 27 NNLO cut master integrals. Its 20 diagonal blocks already have certified epsilon forms, but the assembled lower-triangular connection still contains 87 nonzero off-diagonal strips, of which 70 are not proportional to epsilon. A full Libra Fuchsify/FactorOut attempt is too expensive. Treating isolated two-block strips is not mathematically complete because transformations generate contributions through intermediate blocks. The attached exact test also shows that the physical-row/valuation quotient does not close before epsilon factorization.

We found that the newer C++ FUCHSIA (magv/fuchsia.cpp, described in Vitalii Magerya's thesis) has dedicated commands `fuchsify-off-diagonal-blocks` and multivariable `reduce`. Its algorithm treats the complete block-triangular connection in an order intended to preserve already-reduced blocks, then performs global epsilon factorization. This appears much closer to our missing step than our current code.

Please answer these points precisely:

1. Which existing public tool is best suited to construct the full rational transformation for this particular problem: C++ FUCHSIA, CANONICA, Libra, epsilon/Fuchsia Python, INITIAL, or another package? Distinguish software that constructs an epsilon form from software that only integrates or numerically transports a known differential system.
2. Does C++ FUCHSIA's full off-diagonal algorithm actually solve the whole triangular extension problem that invalidates isolated-strip treatment? Explain what it does during off-diagonal fuchsification and what remains for the factorization step.
3. Assess its limitations for our system: two variables, algebraic roots rationalized by a chart, irreducible denominator factors (some quadratic in a chart variable), epsilon powers from -3 through 4, and a 27x27 sparse lower-triangular matrix. Its README warns that multivariable reduction is under development and that higher powers of unfactorizable denominator polynomials are not implemented. Which condition should we test before investing in a run?
4. CANONICA has a published recursive subsector/off-diagonal algorithm for multiscale systems. Would invoking that recursion on the already-canonical diagonal blocks be more appropriate than a global `CalculateCanonicalBasis`, and what exact package entry points or input construction should be used?
5. Libra's paper says large systems should use block-triangular structure rather than be reduced whole. Does Libra expose a native whole-extension procedure that our scripts missed, or would we still need to implement the ordered off-diagonal algorithm ourselves from `Fuchsify` and `FactorOut`?
6. Is there a more automatic community method based on finite-field reconstruction, the Magnus expansion, leading singularities, INITIAL, or a rational transformation ansatz that is genuinely better here? State what input it needs and whether it returns an exact analytic transformation.
7. Give a short, ordered experiment plan with exact acceptance criteria and stop conditions. We want the cheapest conclusive tests first, not repeated long timeouts.

Do not suggest AMFlow, DiffExp, or numerical transport as the main route: the required output is an exact analytic hard function. They may be named only as independent numerical checks. Do not invent citations; identify the paper or official repository for every claimed package capability.

## Pro response

Decisive conclusion

The attached CF48 test rules out the proposed physical-row/valuation reduction before epsilon factorization:

the 14 demanded rows generate the full rank-27 differential module after one covariant derivative;

regularity removes only one direction at order ϵ
0
 and three directions in the two-order lift;

because the original connection begins at ϵ
−2
,

dI
(n)
⊃A
−2
	​

I
(n+2)
,

no finite Laurent window is invariant before the family epsilon form is constructed. 

codex_cf48_precanonical_quotien… +1

Therefore CF48 requires a full 27-dimensional family transformation. The correct reduction must treat all off-diagonal blocks consistently; an isolated two-block strip is not a complete object.

My ranking is:

CANONICA RecursivelyTransformSectors — most defensible production engine for the genuinely two-variable rational problem.

C++ FUCHSIA — highest-value and probably fastest first experiment, but accept it only after a strict denominator preflight and a full two-variable exact gate.

Libra block-aware routines — useful fallback and independent implementation, but not a clearly documented one-call whole-extension solver.

FiniteFlow-backed joint homological equations — strongest custom fallback if the three packages fail.

epsilon/Python Fuchsia, INITIAL, Magnus methods — not the right primary tools for this particular missing step.

The apparent paradox is resolved as follows:

C++ FUCHSIA has the most directly relevant one-variable complete off-diagonal algorithm, but CANONICA has the better-established multivariable rational transformation algorithm.

1. Which public tool is best suited?
Tool	Constructs exact rational T?	Multivariable	Full triangular extension	Also transports?	CF48 assessment
CANONICA	Yes	Yes	Yes, sector-recursively	No	Best production choice
C++ FUCHSIA	Yes	Experimental	Complete in one variable; sequential in several variables	No	Best first benchmark
Libra	Yes	Yes	Has block/dependent-block primitives; more user-directed	Yes	Third choice
epsilon	Yes	No: ordinary one-variable rational system	One-variable Lee algorithm	No	Not suitable for full CF48
Python Fuchsia	Yes	Essentially one-variable	One-variable Lee algorithm	No	Superseded here by C++ version
INITIAL	Yes	Can handle multiscale input through its construction	Reconstructs a basis from a known UT seed, not specifically the extension	No	Wrong starting information
FiniteFlow	Reconstructs one if an ansatz/evaluator is supplied	Yes	Only through a locally implemented algorithm	No	Excellent backend, not turnkey
Magnus expansion	Can organize transformations/solutions perturbatively	Formally	Not an automatic rational-extension solver	Yes, as series	Does not remove the basis problem

CANONICA is explicitly designed for rational transformations of multiscale systems, and its public high-level algorithm recursively processes sectors and their off-diagonal couplings. 
arXiv
+2
arXiv
+2

C++ FUCHSIA’s official interface has exactly the commands you identified:

reduce-diagonal-blocks⟶fuchsify-off-diagonal-blocks⟶factorize.

Its multivariable reduce computes a single transformation for all supplied matrices, but the official README explicitly labels that route “under development.” 
GitHub

Libra is a broader differential-system workbench: it reduces systems to Fuchsian and epsilon forms, applies transformations, builds path-ordered solutions, and constructs generalized local series. 
arXiv
+1

Production verdict

Use:

C++ FUCHSIA as the cheap go/no-go experiment;CANONICA recursion as the general multivariable route.
	​


If C++ FUCHSIA returns a transformation satisfying the complete exact two-variable gate, there is no need to rerun CANONICA. But its return alone is not enough.

2. Does C++ FUCHSIA solve the whole triangular extension?
In one variable: yes

Let the diagonal blocks already be canonical,

A
ii
	​

=ϵΩ
i
	​

,

and let B
ij
	​

, i>j, be a lower-triangular coupling. For one off-diagonal gauge block,

T=1+X
ij
	​

,X
ij
2
	​

=0,

the coupling transforms as

B
ij
′
	​

=B
ij
	​

+A
ii
	​

X
ij
	​

−X
ij
	​

A
jj
	​

−dX
ij
	​

.
	​

(1)

At a pole x=p, suppose an unwanted term is

(x−p)
m
b
	​

,m>1.

FUCHSIA uses an ansatz of the corresponding pole order for X
ij
	​

. The leading coefficient obeys a linear Sylvester-type equation of the form

b+cd−da−(k+1)d=0,
	​

(2)

where a,c are the diagonal residue blocks and d is the unknown strip transformation.

The important point is that the transformation is applied to the full matrix, not to a frozen 2×2 block system. For three blocks,

A=
	​

A
1
	​

B
21
	​

B
31
	​

	​

0
A
2
	​

B
32
	​

	​

0
0
A
3
	​

	​

	​

,

a transformation of B
21
	​

 also generates or changes

B
31
	​

⟼B
31
	​

+B
32
	​

X
21
	​

,

and a later transformation of B
32
	​

 changes

B
31
	​

⟼B
31
	​

−X
32
	​

B
21
	​

.

The C++ implementation orders the blocks and repeatedly restarts the affected strip, so generated contributions are subsequently processed rather than discarded. It sorts unwanted pole coefficients by Poincaré rank and clears each complete strip before proceeding. This is precisely what isolated-strip treatment was missing.

What remains after off-diagonal fuchsification?

After all strips have only simple poles, the full system is normalized Fuchsian. FUCHSIA then performs the global factorization step.

Schematically, for residue matrices C
a
	​

(ϵ), it seeks a kinematics-independent, generally epsilon-dependent matrix G such that

G
−1
C
a
	​

(ϵ)G=ϵR
a
	​

,∂
ϵ
	​

R
a
	​

=0.
(3)

The current implementation constructs linear intertwining equations comparing

ϵ
C
a
	​

(ϵ)
	​


with the same residue at an independent dummy regulator value. It first attempts a block-preserving constant transformation and, if that fails, falls back to a general constant transformation.

Thus, in one variable:

C++ FUCHSIA does solve the complete triangular extension problem.
	​

In two variables: qualification

The current multivariable driver reduces the matrices sequentially. Inspection of the source shows that after reducing the first variable it substitutes that variable at a chosen reference value while reducing the next matrix, on the assumption that the new transformation is independent of previously reduced variables. It then applies the resulting transformation back to the unspecialized matrices. 

main_collinear(3)

That is not the most general solution of the simultaneous two-variable homological equation. A required transformation of the form

X=X(x,y,ϵ)

can evade this sequential ansatz.

Therefore:

	​

complete for the one-variable triangular extension;
potentially sufficient, but not complete in general, for CF48’s two-variable system.
	​

	​


The official README’s warning that multivariable reduce may fail when it should not is consistent with this source-level limitation. 
GitHub

3. C++ FUCHSIA limitations and the necessary preflight
3.1 Rational chart and algebraic roots

The input matrices must lie in a declared rational field,

A
x
	​

,A
y
	​

∈Mat
27
	​

Q(x,y,ϵ).

If the chart has rationalized every square root, this condition is satisfied. Residual Sqrt, Root, or branch-dependent algebraic objects are a no-go for the current interface.

3.2 Irreducible polynomial denominators

The official README identifies the main missing feature as support for powers greater than one of unfactorizable denominator polynomials. 
GitHub

For every irreducible denominator factor p(x,y,ϵ), compute

deg
x
	​

p,deg
y
	​

p,m
x
	​

(p),m
y
	​

(p),
(4)

where m
μ
	​

(p) is its largest denominator multiplicity in A
μ
	​

.

The strict go/no-go test should be:

Every factor that requires pole-order reduction is linear in the active variable.
	​

(5)

A simple irreducible quadratic appearing only to the first power and already as a Fuchsian dlog letter may be tolerable. Do not assume this from the README alone: test that exact quadratic on the smallest genuine CF48 block prefix.

If any irreducible quadratic or higher polynomial appears with multiplicity >1 in the active variable, do not invest in a full C++ FUCHSIA run. Use CANONICA or a polynomial-factor homological ansatz instead.

3.3 Epsilon powers

The range

ϵ
−3
,…,ϵ
4

is not a formal obstruction. The program works with rational dependence on the regulator and may produce a transformation with poles in ϵ. The relevant checks are:

detT

≡0

over the rational field, and sufficient Laurent depth after applying T.

3.4 Matrix size and sparsity

A sparse 27×27 matrix with 20 diagonal blocks is structurally favorable for the block algorithm. That does not predict runtime because the decisive quantity is the size of the rational coefficients generated during strip transformations.

3.5 Sequential multivariable consistency test

Run the multivariable reduction twice with different nonsingular exact values for the previous-variable anchor, for example

x
0
	​

=
3
1
	​

,x
0
	​

=
5
2
	​

.

Let the returned transformations be T
(1)
 and T
(2)
. After a common normalization, require

C=T
(1)−1
T
(2)

to be kinematics independent:

∂
x
	​

C=∂
y
	​

C=0,
(6)

and require the two final connections to be related by

A
μ
(2)
	​

=C
−1
A
μ
(1)
	​

C.
(7)

If not, the sequential multivariable assumption is failing for CF48.

This is the most important test before a long run.

4. CANONICA: use the recursive sector algorithm

Yes: invoking CANONICA’s recursive subsector algorithm is more appropriate than launching a generic full-matrix basis search.

The public entry point is

Wolfram Language
RecursivelyTransformSectors

not CalculateCanonicalBasis. Its documented purpose is to construct a rational canonical transformation recursively over explicitly supplied sectors. It can resume from previously transformed lower sectors, and the off-diagonal ansatz size is controlled separately through DDeltaNumeratorDegree.

The input should be the already assembled family connection in the block-diagonal class frame:

Wolfram Language
aFull = {Ax, Ay};


invariants = {x, y};


sectorBoundaries = {
  {1, n1},
  {n1 + 1, n2},
  (* ... *)
  {n19 + 1, 27}
};


result = RecursivelyTransformSectors[
  aFull,
  invariants,
  sectorBoundaries,
  {1, Length[sectorBoundaries]},
  TDeltaNumeratorDegree -> 0,
  TDeltaDenominatorDegree -> 0,
  DDeltaNumeratorDegree -> d,
  VerbosityLevel -> 1
];

This is the same high-level interface used in CANONICA’s official multiscale examples. 

03_cut_families

Because the diagonal blocks are already certified:

start with diagonal ansatz degrees zero;

vary only DDeltaNumeratorDegree;

use epsilon-dependent denominator factors only in the transformation ansatz, not in the final alphabet;

gate after every newly completed sector;

checkpoint and resume using CANONICA’s documented trafoPrevious and aPrevious continuation arguments.

The lower-level public functions underlying the recursion include:

Wolfram Language
CalculateNexta
CalculateNextSubsectorD
FindAnsatzSubsectorD

FindAnsatzSubsectorD is specifically documented for a system that is already in epsilon form except for the highest-sector off-diagonal block.

For CF48, the high-level recursion is safer because it maintains every previously generated intermediate contribution.

5. Does Libra have a native whole-extension procedure?

Libra exposes more block-aware machinery than a simple whole-matrix Fuchsify call:

BlocksHierarchyIndices
OffDiagonalBlocksIndices
BlockTriangularToFuchsian
FuchsifyDependent
FuchsifyDependentBlocks
FactorOut
FactorDependence
IntertwiningMatrix

These names are present in the current public source. 

02_factorization

So your scripts may indeed have missed the more appropriate entry points:

BlockTriangularToFuchsianorFuchsifyDependentBlocks,

rather than applying an unrestricted Fuchsify to the complete 27×27 system.

However, I do not find a clearly documented single call in Libra equivalent to

C++ FUCHSIA reduce

or

CANONICA RecursivelyTransformSectors

that performs, unattended:

all diagonal reductions;

all off-diagonal pole-order reductions;

all intermediate-block updates;

global epsilon factorization;

the complete two-variable exact gate.

Libra is designed as an interactive transformation framework. Its block-dependent routines can supply the required mathematics, but you will probably still need to orchestrate:

FuchsifyDependentBlocks⟶FactorOut/FactorDependence⟶exact reconstruction.

Libra supports one- and multivariable systems, epsilon-form reduction, path-ordered transport, and generalized local series; its strength is broader than this one reduction problem. 
arXiv
+1

Decisive Libra test

Use the smallest actual three-block chain from CF48—not a two-block strip—and call the dependent-block routines. Require the transformation to account for the induced distance-two coupling.

If that prefix is not completed substantially faster than CANONICA’s corresponding prefix, do not use Libra for the full family.

6. Are any other methods genuinely better?
Finite-field homological reconstruction: credible fallback

This is the strongest alternative, but it requires a small FACET-specific algorithm.

Write the diagonal connection as

Ω
diag
	​

=diag(Ω
1
	​

,…,Ω
20
	​

),

and construct a strict lower-triangular transformation by block distance,

G=1+X
(1)
+X
(2)
+⋯.

At distance d, after applying all lower-distance transformations, solve

dX
(d)
−ϵ(Ω
diag
	​

X
(d)
−X
(d)
Ω
diag
	​

)=
B
(d)
−ϵ
a
∑
	​

C
a
(d)
	​

dlogϕ
a
	​

.
	​

(8)

All strips of the same distance should be solved jointly. This is linear in:

coefficients of the rational ansatz for X
(d)
;

constant residue matrices C
a
(d)
	​

.

FiniteFlow can evaluate these linear systems over finite fields and reconstruct the exact rational coefficients, avoiding large symbolic intermediate expressions. It returns an exact analytic transformation only after rational reconstruction and the complete characteristic-zero gate. 
arXiv

This is likely preferable to raising CANONICA ansatz degrees indefinitely.

INITIAL: not the right missing step

INITIAL reconstructs a canonical transformation from one known uniform-transcendental integral. It requires a suitable UT seed and uses FiniteFlow internally. 
GitHub

For CF48, the diagonal pure bases are already known. The problem is their relative off-diagonal completion. Unless you have one UT integral whose differential orbit demonstrably spans the full 27-dimensional family, INITIAL repeats a harder basis-construction problem.

Leading singularities

Leading singularities can propose pure integrals, but they do not by themselves construct the complete rational off-diagonal transformation. They are not the bottleneck here.

Magnus expansion

The Magnus/Dyson method can organize a transformation or solution when the dimensional dependence has a suitable structure, but it does not automatically solve this rational multivariable off-diagonal extension. It is closer to a representation of the solution than to a robust replacement for CANONICA/FUCHSIA. 
DOI

epsilon and Python Fuchsia

Both implement Lee-style reduction for ordinary one-variable rational systems. They are useful as slice checks, but they do not solve the full two-variable CF48 connection. 
arXiv
+1

Overall conclusion

There is no missed public package clearly superior to:

CANONICA recursionorC++ FUCHSIA when its multivariable assumptions happen to hold.
	​


The only potentially faster new route is the finite-field implementation of Eq. (8).

7. Ordered experiment plan
Experiment 0 — freeze the quotient result

Do no more pre-canonical observable/valuation quotient work. The attached calculation has already established that:

rankR
demanded
	​

=27,

and that the finite Laurent lift is not invariant because of A
−2
	​

. 

codex_cf48_precanonical_quotien… +1

Experiment 1 — exact denominator census

For both variable orders, compute for every denominator factor:

(p,deg
x
	​

p,deg
y
	​

p,m
x
	​

(p),m
y
	​

(p),ord
ϵ
	​

p).

Also compute:

polynomial part at x=∞ and y=∞;

epsilon-dependent apparent divisors;

whether every diagonal block remains exactly in epsilon form.

Stop condition

Skip C++ FUCHSIA if either variable order contains an irreducible factor of degree >1 that occurs with multiplicity >1 in a strip needing pole reduction.

This test should be essentially free compared with any transformation search.

Experiment 2 — minimal complete C++ FUCHSIA fixture

Choose the smallest real CF48 prefix containing a chain

B
1
	​

⟶B
2
	​

⟶B
3
	​


with:

at least one non-epsilon distance-one strip;

a generated distance-two contribution;

the most difficult denominator type from Experiment 1.

Run the multivariable command in both variable orders, using paranoid mode.

Run each order at two exact nonsingular anchor values via -0.

Acceptance

Require:

A
μ
	​

=T
−1
A
μ
	​

T−T
−1
∂
μ
	​

T,
∂ϵ
∂
	​

(
ϵ
A
μ
	​

	​

)=0,μ=x,y,
(9)

and

ϵ
A
μ
	​

	​

=
a
∑
	​

R
a
	​

∂
μ
	​

logϕ
a
	​

,∂
x
	​

R
a
	​

=∂
y
	​

R
a
	​

=∂
ϵ
	​

R
a
	​

=0.
(10)

Also require anchor independence through Eqs. (6)–(7).

Stop conditions

Stop C++ FUCHSIA immediately if:

it reports an unsupported polynomial factor;

transformations from the two anchors are not related by a constant gauge;

either component fails the exact dlog gate;

a previously canonical diagonal block is spoiled.

Experiment 3 — full CF48 C++ FUCHSIA run

Only after Experiment 2 passes.

Use the simpler variable first, as recommended by the official interface. Retain:

T and T
−1
;

both transformed matrices;

complete logs;

exact block permutation.

Acceptance

In addition to Eqs. (9)–(10), require:

detT

≡0,
d
A
−
A
∧
A
=0,

and exact reconstruction of all 20 declared diagonal blocks up to constant similarity.

If this succeeds, it is the production answer.

Experiment 4 — CANONICA prefix recursion

If C++ FUCHSIA fails its multivariable test, run CANONICA on the smallest prefix ending at the first noncanonical off-diagonal sector.

Use:

D-degree=0

first, then 1. Do not enlarge diagonal degrees.

After each sector, require the exact gate before checkpointing.

Stop condition

Do not continue increasing degree merely because a run times out. Before the next degree, measure the finite-field rank and number of unknown ansatz coefficients. Continue only if the enlarged ansatz introduces genuinely new rank rather than only a much larger null system.

If the prefix succeeds, resume sector by sector to block 20.

Experiment 5 — Libra dependent-block control

On the same three-block prefix, test:

BlockTriangularToFuchsian
FuchsifyDependentBlocks
FactorOut

with the known Projector warning issue disabled correctly.

Accept only by the same exact two-variable gate.

Use Libra for the full system only if the prefix is clearly cheaper than CANONICA.

Experiment 6 — FiniteFlow homological solver

If all three packages fail, implement Eq. (8).

Proceed by block distance:

d=1,2,…,19.

At each d:

construct the effective coupling after all previous transformations;

solve all distance-d strips jointly over finite fields;

reconstruct X
(d)
 and C
a
(d)
	​

;

verify the characteristic-zero equation exactly;

recheck all previously completed distances.

Final acceptance

The only final certificate should be

T
−1
A
μ
	​

T−T
−1
∂
μ
	​

T=ϵ
a
∑
	​

R
a
	​

∂
μ
	​

logϕ
a
	​

(μ=x,y),
	​


with exact constant residues, nonzero determinant, preserved flatness, and the original master ordering reconstructed.

Final recommendation

For CF48, run in this order:

Denominator compatibility census.

Three-block C++ FUCHSIA multivariable fixture at two anchors.

Full C++ FUCHSIA only if that fixture passes.

CANONICA RecursivelyTransformSectors as the primary general fallback.

Libra dependent-block routines as an independent control.

FiniteFlow block-distance homological reconstruction if the packages fail.

The key distinction is:

C++ FUCHSIA solves the correct full triangular problem in one variable,
	​


but

CANONICA is currently the safer public implementation for an unrestricted two-variable rational transformation.
	​

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/External/CodexExchange/codex_cf48_precanonical_quotient_2026-08-18.md` (not archived with this exchange)
