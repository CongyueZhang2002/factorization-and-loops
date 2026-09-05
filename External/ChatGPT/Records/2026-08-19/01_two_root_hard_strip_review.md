# Two Root Hard Strip Review

## Question

# Request: diagnose the last two unresolved two-root epsilon-form classes

We are constructing exact analytic master integrals for an NNLO double-real
QCD calculation.  The differential systems are rationalized, flat, and
block-lower-triangular.  All diagonal blocks are already in epsilon form.  At
this point only two inequivalent two-root classes remain unresolved:

1. the Kallen-23 class, represented by family `CF231`, with the first hard
   off-diagonal block pair `(8,7)`; `CF305` is related to the same class by an
   exact family transformation;
2. the Kallen-13 class, represented by family `CF254`, with the first hard
   off-diagonal block pair `(9,8)`; `CF265` is related to the same class by an
   exact family transformation.

The attached archive contains the current implementation, the exact charts,
the exact hard-strip data, and the measured logs.  Please inspect the files,
not just this summary.

## Mathematical problem

Let the upper and lower diagonal blocks already be in epsilon form,

\[
 dF_E=\epsilon\,\Omega_E F_E,\qquad
 dF_C=\epsilon\,\Omega_C F_C,
\]

and let the off-diagonal one-form be

\[
 \overline B=\sum_{\mu=1}^{2}\overline B_\mu\,dz_\mu .
\]

For this strip we seek a rational matrix (R(z_1,z_2,\epsilon)) and constant
matrices (K_a) such that

\[
 \partial_\mu R-
 \epsilon\bigl(E_\mu R-RC_\mu\bigr)
 =\overline B_\mu-
 \epsilon\sum_a K_a\,\partial_\mu\log W_a,
 \qquad \mu=1,2.
\]

Here (E_\mu) and (C_\mu) are the two diagonal epsilon-form connections and
(W_a) are irreducible polynomial letters in the rationalized chart.  The
code first solves the exact compatibility equations for the constant
residues (K_a).  It then solves the resulting inhomogeneous rational system
for (R), first in one variable and finally checks both equations exactly.

## Rationalized charts

The two square roots are rationalized simultaneously before the strip solve.
The exact substitutions and square identities are in `TransportCharts.wl`.
The unresolved representatives use:

- `CF231`: `Kallen23`, with chart variables `(y,s)`;
- `CF254`: `Kallen13`, with chart variables `(y,s)` and an exported hard-strip
  record in variables `(x,y)` after chart composition.

Both chart identities were checked exactly.  The transformed Pfaffian systems
are flat, and their diagonal blocks satisfy the epsilon-form identities.

## Methods already attempted

### Whole-family and blockwise routes

- Complete-sector CANONICA was attempted first.
- When that did not find a transformation, individual off-diagonal strips
  were attempted with CANONICA numerator degrees `0,1,2,3`, denominator degree
  `0`, and 120 seconds per degree.
- Libra transformations (`FuchsifyFinite`, `FuchsifyInfinity`, and
  `FactorOut` where applicable) were attempted in both chart variables.
- These routes solved the other two-root classes, but not the two classes
  above.

### Current exact Maple route

`SolveResidueRationalGauge` performs the following steps.

1. Construct a constant-residue dlog ansatz from every irreducible polynomial
   letter of the strip.
2. Solve the exact two-variable compatibility equations for those residues.
3. For each choice of first variable, call Maple
   `IntegrableConnections:-Mratsolde(A_i,z_i,b_i)`.
4. If that returns no solution, use

   \[
   R_j(z_i)=
   \frac{\sum_{k=0}^{\deg_{z_i}D+q}a_{jk}z_i^k}{D(z_i)},
   \qquad
   D(z_i)=\left(\prod_{W_a\,:\,\partial_{z_i}W_a\ne0}
   W_a\right)^p,
   \]

   with (p\in\{1,2,3\}) and (q\in\{0,1,2\}).
5. Substitute a candidate into both Pfaffian equations and into the complete
   transformed dlog identity using exact rational arithmetic.

For `CF254 (9,8)` and `CF265 (14,13)`, both variable orientations reached
Maple.  The enclosing jobs ended after about 3740 seconds.  For `CF231 (8,7)`,
the first orientation returned no result before the job was interrupted; the
second orientation was not completed.  A separate standardized `CF254` run
spent 16854 seconds before reporting no exact gauge.

Important limitation: the Maple script writes its candidate ledger only after
the complete nested search.  The enclosing timeout killed several runs before
that write.  Therefore these records do **not** establish that every
((p,q)\in\{1,2,3\}\times\{0,1,2\}) candidate was actually solved and rejected.
They establish only that the requested finite search did not return a checked
gauge within the allotted time.

## Questions requiring a concrete answer

1. **Is the isolated-strip equation mathematically complete?**  Once every
   diagonal block is in epsilon form, must an epsilon-form transformation
   exist as a sum of independently solvable off-diagonal strip gauges, or can
   the required lower-triangular transformation couple several source blocks
   in one row?  If coupling is possible, write the coupled equation that
   should replace the isolated-strip solve and identify the smallest row of
   blocks that must be solved together.

2. **Can existence of a rational strip gauge be decided before an ansatz
   sweep?**  Please formulate the relevant local-residue, differential-module,
   or cohomological criterion.  We want an exact certificate of either:
   - existence, together with denominator and numerator-degree bounds; or
   - nonexistence within rational functions in the chosen chart.

3. **How should the denominator divisor be derived?**  Is
   (D=(\prod_aW_a)^p) unnecessarily large or incomplete?  Give a method to
   determine pole orders separately at each letter, including infinity, from
   local exponents or residue equations.  State whether apparent letters or
   factors introduced by the chart must be excluded or assigned different
   powers.

4. **Does failure in one-variable integration diagnose anything?**  Is it
   sound to solve
   (partial_{z_1}R-A_1R=b_1) over the field
   (mathbb Q(z_2,\epsilon)(z_1)), then impose the second equation?  If both
   orientations fail, does that imply the absence of a rational two-variable
   solution, or can a rational solution still be missed by `Mratsolde` and the
   finite denominator ansatz?

5. **Which established method is best for this exact extension problem?**
   Compare, specifically for these attached systems:
   - CANONICA's off-diagonal recursion;
   - Libra's dependent-block transformations;
   - Maple `IntegrableConnections`;
   - a coupled sparse linear system over a rational-function field, solved by
     modular exact linear algebra and rational reconstruction;
   - any method used in published multiloop differential-equation work that
     we have omitted.

6. **What is the next decisive calculation?**  Give a prioritized procedure
   that distinguishes these possibilities with minimal wasted runtime.  We
   especially need to know whether to:
   - instrument and complete the ((p,q)) candidate grid;
   - infer sharp pole bounds and solve one sparse exact linear system;
   - solve a coupled block row instead of one strip;
   - change gauge or rationalizing chart;
   - test for a non-polylogarithmic obstruction.

7. If you recommend a sparse modular solve, specify the unknowns and equations
   and explain how to retain the complete affine solution space rather than a
   single particular solution.  If you recommend a different tool, give the
   exact mathematical input it requires.

Please challenge any premise that is mathematically wrong.  Do not merely
recommend longer time limits or higher degrees.  We need a reasoned diagnosis,
a finite test sequence, and explicit alternatives.  Cite only references you
can identify precisely; do not invent citations.

## Pro response

Decisive diagnosis

The two unresolved pairs should not yet be interpreted as rationally nonsplittable extensions, and there is no evidence here for a non-polylogarithmic sector.

The source packet identifies the exact strip solver, the two rationalizing charts, the whole-family driver, and the measured logs. 

09_conclusions

 The decisive findings from the implementation are:

For these two adjacent block pairs, the isolated-strip equation is mathematically complete, provided the diagonal epsilon-form blocks and the block filtration are held fixed. A coupled whole-row solve cannot rescue a genuinely nonsplittable (8,7) or (9,8) adjacent extension.

The recorded Maple failures are not valid nonexistence evidence. The wrapper:

emits SymbolName::sym before or during Maple serialization;

erases the homogeneous affine freedom of the first-variable equation by setting every free ansatz coefficient to zero;

uses a denominator family that excludes epsilon-dependent divisors even though the CF254 strip contains a squared epsilon-dependent divisor;

writes its attempt ledger only after the entire nested search, so timed-out jobs do not establish which candidates were actually completed.

The next calculation should not be another uniform (p,q) grid. It should derive divisor-by-divisor pole bounds, construct one simultaneous two-PDE linear system with those sharp bounds, and solve for the complete affine solution space.

Maple IntegrableConnections remains relevant, but the appropriate use is the full rational-solution algorithm for an augmented integrable connection, not the current Mratsolde wrapper followed by a restricted denominator sweep.

There is also a source-packet limitation: the README lists blockwise_local_CF231.wl, but I could not locate a corresponding BEGIN FILE section or the actual CF231 strip matrices in the concatenated attachment. The packet contains only the CF231 process log. Therefore the CF231-specific divisor census cannot be audited from this attachment, whereas the full CF254 strip is present. 

ProClass77BoundarySpectrumFollo…

1. Is the isolated-strip equation mathematically complete?
General block row: no, the strips are not independent

Let the diagonal blocks be

dF
i
	​

=ϵΩ
i
	​

F
i
	​

,

and let the already assembled lower subsystem below block i be

dF
<i
	​

=ϵΩ
<i
	​

F
<i
	​

.

Write the entire lower-triangular gauge row from the lower subsystem into block i as

R
i
	​

=(
R
i1
	​

	​

R
i2
	​

	​

⋯
	​

R
i,i−1
	​

	​

),

and the corresponding off-diagonal connection row as

B
i
	​

=(
B
i1
	​

	​

B
i2
	​

	​

⋯
	​

B
i,i−1
	​

	​

).

The complete row equation is

dR
i
	​

−ϵ(Ω
i
	​

R
i
	​

−R
i
	​

Ω
<i
	​

)=
B
i
	​

−ϵ
a
∑
	​

K
i,a
	​

dlogW
a
	​

.
	​

(1)

In components,

dR
ij
	​

−ϵ(Ω
i
	​

R
ij
	​

−R
ij
	​

Ω
j
	​

)=
	​

B
ij
	​

−ϵ
a
∑
	​

K
ij,a
	​

dlogW
a
	​

−ϵ
k=j+1
∑
i−1
	​

R
ik
	​

Ω
kj
	​

.
	​

(2)

The final sum is why arbitrary off-diagonal strips cannot be solved as unrelated raw two-block problems. Transforming one strip generates terms in strips farther from the diagonal.

The current family driver does account for this triangular recursion: it calls CANONICA’s NextEquationD using the accumulated prevD, appends each accepted gauge, and only then constructs the next effective strip. 

two_root_hard_strip_sources(1)

The two hard pairs are special: they are adjacent

For the adjacent block j=i−1, the sum in Eq. (2) is empty:

dR
i,i−1
	​

−ϵ(Ω
i
	​

R
i,i−1
	​

−R
i,i−1
	​

Ω
i−1
	​

)=
B
i,i−1
	​

−ϵ
a
∑
	​

K
i,i−1,a
	​

dlogW
a
	​

.
	​

(3)

Therefore:

CF231 (8,7) and CF254 (9,8) are complete adjacent-extension problems.
	​


A simultaneous solve of the rest of row 8 or row 9 cannot cancel an obstruction in these adjacent extension classes. Later strips depend on the adjacent one; the adjacent one does not depend on later strips.

This conclusion assumes that:

the block filtration is preserved;

the diagonal blocks remain in their certified epsilon-form modules;

only rational transformations in the chosen chart are allowed.

Changing the canonical basis within a diagonal block by a constant similarity changes the matrix representative of the extension but not whether its rational extension class splits. CANONICA’s underlying result that canonical forms are unique up to constant transformations supports this interpretation. 
arXiv

A completely non-block-triangular transformation that abandons the sector filtration is formally a broader problem. There is no evidence that such a transformation is needed, and it would discard the subsector structure on which all completed family reductions rely.

One additional convention must be clarified

At the off-diagonal fuchsification stage, it is usually safest to allow

K
a
	​

=K
a
	​

(ϵ)

to be rational in ϵ but independent of the kinematic variables. A later constant transformation can factor out the remaining epsilon dependence.

The current implementation effectively follows that broader convention: the residue variables are kinematic constants, but solving their compatibility equations can make them rational functions of ϵ; the family driver subsequently invokes TransformDlogToEpsForm. 

CodexAssessmentOfFableRound6_20…

If the proposed mathematical equation instead requires every K
a
	​

 to be epsilon-independent immediately, that is a stronger ansatz than the current package route and can reject valid intermediate normalized-dlog gauges.

2. Exact existence criterion before an ansatz sweep

Let

K=Q(z
1
	​

,z
2
	​

,ϵ)

and define the induced differential module

H=Hom
K
	​

(M
C
	​

,M
E
	​

).

Its connection acts on a rational matrix R as

∇
H
	​

R=dR−ϵ(Ω
E
	​

R−RΩ
C
	​

).
	​

(4)

Let

ω=
B

be the given off-diagonal one-form. Let L
log
	​

 be the space of allowed logarithmic one-forms

ℓ(K)=ϵ
a
∑
	​

K
a
	​

(ϵ)dlogW
a
	​

,
(5)

subject to the exact compatibility condition

∇
H
	​

(ω−ℓ(K))=0.
(6)

The rational gauge exists if and only if there is an allowed ℓ such that

ω−ℓ∈im∇
H
	​

.
	​

(7)

Equivalently, the compatible one-form must represent the zero class in the twisted rational de Rham cohomology:

[ω−ℓ]=0inH
∇
H
	​

1
	​

(K).
	​

(8)

The current residue-compatibility code checks Eq. (6): it constructs constant dlog residues, computes the two-variable compatibility equations, solves them linearly, and verifies closure exactly. 

CodexAssessmentOfFableRound6_20…

That is necessary but not sufficient. A closed rational one-form need not be rationally exact in the Hom-connection.

Exact existence certificates

An exact existence certificate consists of explicit rational data

R,K
a
	​


satisfying both Pfaffian equations:

∂
μ
	​

R−ϵ(E
μ
	​

R−RC
μ
	​

)−
B
μ
	​

+ϵ
a
∑
	​

K
a
	​

∂
μ
	​

logW
a
	​

=0,μ=1,2.
	​

(9)
Exact nonexistence certificates

There are two useful forms.

Local obstruction

At an irreducible divisor q=0, a required principal-part coefficient may lie outside the image of the local homological operator. One then retains a left-null covector λ over the residue field such that

λH
q
	​

=0,λb
q
	​


=0.
(10)

This proves that no rational gauge with the required local pole behavior exists.

Global obstruction after proved bounds

After deriving complete denominator and numerator-degree bounds, substitution gives a finite linear system

A(ϵ)u=b(ϵ).
(11)

An exact left-null certificate

ℓ
T
A=0,ℓ
T
b

=0
	​

(12)

proves that no rational gauge exists within the complete bounded rational function space.

Without a proof that the bounded space contains every rational solution, inconsistency of a finite ansatz proves only failure of that ansatz.

3. Deriving the denominator divisor sharply

The current denominator choice

D=(
a
∏
	​

W
a
	​

)
p
(13)

is both too large and incomplete.

Why it is too large

Different divisors generally require different pole orders:

D=
q
∏
	​

q
ν
q
	​

.
(14)

A common exponent p forces unnecessary powers at most letters and causes large numerator degrees and large linear systems.

Why it is incomplete in the current code

The alphabet builder explicitly discards every irreducible factor that depends on ϵ:

Wolfram Language
Select[irreducibles, FreeQ[#, CANONICA`eps] &]

CodexAssessmentOfFableRound6_20…

But the exported CF254 hard strip contains, in its off-diagonal block, the squared epsilon-dependent divisor

q
ϵ
	​

(x,y)=
	​

−9−11ϵ+12x+24ϵx+12x
2
+12ϵx
2
−6y−6ϵy+12xy+16ϵxy+3y
2
+5ϵy
2
.
	​

(15)

It occurs as q
ϵ
−2
	​

 in the denominator. 

Class77LowerChartSystem

At ϵ=0,

q
ϵ
	​

	​

ϵ=0
	​

=3Q(x,y),

with

Q(x,y)=−3+4x+4x
2
−2y+4xy+y
2
.
(16)

Thus q
ϵ
	​

 is an epsilon-dependent deformation of an ordinary chart letter. It is presumably an apparent divisor introduced by the assembled basis transformation.

Because it is not an allowed final epsilon-form letter, the correct condition is:

include q
ϵ
	​

 among possible poles of R;

require its final logarithmic residue to vanish:

K
q
ϵ
	​

	​

=0;

cancel it completely in the transformed strip.

A denominator ansatz built only from the epsilon-independent Alphabet cannot do that. A completed (p,q) grid using the current denominator builder would therefore still not be exhaustive.

Local divisor algorithm

For every irreducible divisor q(z
1
	​

,z
2
	​

,ϵ) in the actual poles of

E,C,
B
,

work at a generic smooth point of q=0, over the residue field

K
q
	​

=Frac(Q(ϵ)[z
1
	​

,z
2
	​

]/(q)).
(17)

First check

gcd(q,∂
z
1
	​

	​

q,∂
z
2
	​

	​

q)=1.
(18)

If this fails, the divisor must be decomposed or normalized before applying the simple local recurrence.

Suppose locally

Ω
E
	​

=E
q
	​

dlogq+regular,Ω
C
	​

=C
q
	​

dlogq+regular,
(19)

and the compatible forcing has normal principal part

F=
r=1
∑
m
q
	​

	​

F
q,r
	​

q
r
dq
	​

+tangential terms.
(20)

Seek

R=
k=1
∑
m
q
	​

−1
	​

q
k
R
q,k
	​

	​

+R
reg
	​

.
(21)

Define the local Sylvester operator

S
q
	​

(X)=E
q
	​

X−XC
q
	​

.
(22)

At successive pole orders one obtains

(kid+ϵS
q
	​

)R
q,k
	​

=−F
q,k+1
eff
	​

.
	​

(23)

For k≥1, the operator has constant term

kid

at ϵ=0; hence it is generically invertible over K
q
	​

(ϵ). This gives a sharp generic bound

ν
q
	​

(R)≤max(0,m
q
	​

−1).
	​

(24)

It also determines the higher-order principal parts uniquely, rather than introducing a full numerator polynomial for every matrix entry.

After all higher poles are removed, the remaining simple pole determines:

the permitted dlog residue K
q
	​

, if q is an allowed letter;

an obstruction, if the residue lies outside the allowed constant-residue subspace;

complete cancellation, if q is apparent or epsilon-dependent.

Intersections of divisors are not ignored: after the generic divisor analysis, the full two-variable identity must be checked globally.

Infinity

Polynomial numerator bounds must be derived separately at infinity.

For each direction, use

t
1
	​

=
z
1
	​

1
	​

,ort
2
	​

=
z
2
	​

1
	​

,

transform the Hom-connection, and perform the same local valuation analysis at t
i
	​

=0. For a genuinely two-variable polynomial remainder, use the corresponding projective compactification or a bidegree/Newton-polytope bound.

This replaces the present heuristic

deg(numerator)=deg(D)+q.
Chart-induced factors

A factor is not excluded merely because it arose from the rationalizing chart. The rule is:

if it is an actual pole of the transformed connection or forcing, include it in the local divisor census;

if it is absent from the physical alphabet, require its final residue to vanish;

if it is a Jacobian zero outside the physical chart patch, it may still be algebraically relevant to the global rational gauge.

The Kallen13 and Kallen23 charts themselves are exact: the packet rechecks both root-square identities and the nonvanishing Jacobian symbolically. 

Class77CompactEpsilonZeroFundam…

 There is currently no reason to abandon them.

4. What does one-variable rational integration establish?
The method is mathematically sound in principle

Consider the first equation over

Q(z
2
	​

,ϵ)(z
1
	​

).

A complete rational ODE solver should return the full affine solution space

R(z
1
	​

,z
2
	​

,ϵ)=R
p
	​

+
α=1
∑
h
	​

H
α
	​

(z
1
	​

,z
2
	​

,ϵ)λ
α
	​

(z
2
	​

,ϵ),
	​

(25)

where:

R
p
	​

 is one rational particular solution;

H
α
	​

 form a basis of rational homogeneous solutions in z
1
	​

;

the λ
α
	​

 are arbitrary rational functions of the spectator variable and ϵ.

The second Pfaffian equation then determines the λ
α
	​

.

Every rational two-variable solution necessarily belongs to this affine family. Therefore a complete rational ODE algorithm proving no rational solution for the first equation would exclude a global rational gauge for that fixed residue choice.

The rational-solution algorithm of Barkatou, Cluzeau, El Bacha, and Weil is specifically designed to compute rational and hyperexponential solutions of integrable multivariate connections recursively from ordinary differential-system algorithms. 
doczz.net
+1

The current implementation is not complete
It sets the homogeneous affine freedom to zero

After Maple’s finite ansatz solve, the code finds free ansatz coefficients and then applies

maple
freeaarules := {seq(q=0,q in freeaa)}

before imposing the complete two-variable equation. 

ConstructClass77SecondEpsilonFr…

This is the first mathematically invalid operation in that fallback route.

A nonzero homogeneous rational solution of the first equation may be precisely what is required to satisfy the second equation. Once those parameters are set to zero, the later Mathematica check cannot recover them.

The Maple bridge is not fail-closed

The CF254 and CF265 jobs emit SymbolName::sym on objects that are not symbols, including the entire list of external constants, before reporting that Maple produced no result. 

Class77LowerChartSystem +1

The source constructs mapleInputSymbols, applies GatherBy[...,SymbolName], and then creates an association from SymbolName /@ mapleInputSymbols. 

ConstructClass77SecondEpsilonFr…

The diagnostic logs and generated .mpl files are not included in the packet, so it is not possible to determine whether Maple received a valid system. At minimum, the symbol extraction and serialization path violated its own assumed type contract.

It should fail immediately unless

Wolfram Language
VectorQ[mapleInputSymbols, MatchQ[#, _Symbol] &]

is true.

A safer bridge should explicitly enumerate:

the two chart variables;

the regulator;

the named residue parameters;

any other scalar coefficient symbols;

rather than stripping Mathematica contexts from arbitrary expressions with a regular expression.

The CF231 evidence is weaker still

The CF231 log records only:

start of the mission;

no result for the first orientation;

no completed second orientation;

no ledger.

ProClass77BoundarySpectrumFollo…

The CF305 log contains package-loading and symbol-shadowing messages but no retained solve result. 

ProClass77BoundarySpectrumFollo…

Therefore:

Neither Kallen23 representative currently has meaningful negative rational-gauge evidence.
	​

Does failure in both orientations prove nonexistence?

Only if all of the following hold:

the rational ODE solver is complete over the coefficient field;

the residue parameters are treated generically or exhaustively;

the full affine homogeneous solution space is retained;

the spectator dependence of the homogeneous constants is solved;

the external bridge is correct and fail-closed.

The current runs satisfy none of these conditions strongly enough to support nonexistence.

5. Which established method is best here?
A. Coupled, sharp rational linear system: best practical primary route

For these particular adjacent strips, the most controllable route is:

solve the constant-residue compatibility equations;

derive sharp local pole orders at every divisor and at infinity;

build a finite matrix-valued basis for R;

substitute into both Pfaffian equations simultaneously;

solve the resulting exact affine system.

This avoids the uniform denominator sweep and produces either:

an explicit gauge;

or an exact inconsistency certificate.

It is not a novel mathematical method; it is the finite realization of the rational Hom-connection problem after local rational-solution analysis.

B. Maple IntegrableConnections: best existing package-level existence test

The public IntegrableConnections package is designed to compute rational and hyperexponential solutions of linear PDE systems written as integrable connections. The associated ISSAC 2012 algorithm recursively reduces the multivariate rational-solution problem to ordinary rational-system problems. 
doczz.net
+1

The correct input is the whole augmented two-variable connection, not merely

maple
Mratsolde(A1,z1,b1)

followed by a restricted finite ansatz.

After residue compatibility, write

K
a
	​

(ϵ)=K
a,0
	​

(ϵ)+
ρ
∑
	​

κ
ρ
	​

K
a,ρ
	​

(ϵ).
(26)

Vectorize R:

r=vecR.

Then

∂
μ
	​

r=M
μ
	​

r+f
μ,0
	​

+
ρ
∑
	​

κ
ρ
	​

f
μ,ρ
	​

,
(27)

with

M
μ
	​

=ϵ[I⊗E
μ
	​

−C
μ
T
	​

⊗I].
(28)

Introduce the augmented vector

Y=
	​

r
1
κ
	​

	​


and the homogeneous integrable system

∂
μ
	​

Y=
	​

M
μ
	​

0
0
	​

f
μ,0
	​

0
0
	​

F
μ
	​

0
0
	​

	​

Y,μ=1,2.
	​

(29)

Call the package’s full RationalSolutions procedure on the pair of augmented matrices and the two variables. Select linear combinations of the returned rational basis with constant coordinate equal to one.

This construction automatically retains the entire affine space instead of choosing one particular solution.

The OpenXM documentation independently identifies IntegrableConnections[RationalSolutions] as the intended whole-Pfaffian rational-solution interface. 
Kobe University Math Department

C. CANONICA: structurally correct but use a sharp user ansatz

CANONICA is the established multiscale package for constructing rational transformations to canonical form. Its algorithm is applicable to multiple kinematic variables and rational dependence on the dimensional regulator. 
arXiv
+1

The current CANONICA route fails because it searches generic numerator degrees 0,1,2,3 with denominator degree zero. That is not an existence test.

Use CANONICA only after supplying a divisor-derived ansatz. Prefer a matrix-valued basis

R=
α
∑
	​

u
α
	​

M
α
	​

(z
1
	​

,z
2
	​

,ϵ),
(30)

where the M
α
	​

 already encode correlations found by the local Sylvester equations. A scalar rational-function list independently multiplied into every matrix entry loses this structure and creates many unnecessary unknowns.

D. Libra: useful transformation workbench, not an existence certificate here

Libra handles one- and multivariable differential systems, epsilon-form transformations, path-ordered solutions, and local generalized series. 
arXiv

Its FuchsifyFinite, FuchsifyInfinity, and FactorOut attempts are balance-based searches. Failure does not prove that the rational extension class is nontrivial.

As established in the earlier source inspection, the public Libra source exposes several dependent-block names only as declarations without operative DownValues; the implemented route is the general Fuchsify. Therefore there is no missing public one-call dependent-extension solver that should supersede the rational Hom-connection calculation.

E. FiniteFlow: backend, not ansatz generator

FiniteFlow is well suited to evaluating a known sparse linear system over finite fields and reconstructing exact rational functions without expression swell. It does not derive the divisor bounds or the rational ansatz automatically. 
GitHub
+1

It becomes valuable after the exact local analysis has produced the finite system.

F. MultivariateApart: useful preprocessing

Before deriving principal parts, canonicalize the rational forcing with MultivariateApart. Its algorithm is designed to produce generalized multivariate partial fractions while systematically avoiding spurious denominator factors. 
arXiv

It does not solve the connection equation; it gives a more reliable divisor and principal-part representation.

G. Fuchsia/epsilon/Lee algorithms

The public Python Fuchsia implements Lee’s algorithm for ordinary one-variable rational differential systems. 
arXiv
+1

Those tools are useful for slices or for the one-variable subproblems inside a multivariate rational-solution algorithm. They are not a replacement for the two-variable adjacent extension calculation.

H. Leading singularities, INITIAL, Picard–Fuchs

These are not the missing operation:

leading singularities and INITIAL propose or reconstruct pure bases;

the diagonal pure modules are already known;

scalar Picard–Fuchs equations solve periods or combinations of periods, not the rational splitting of a known module extension.

They should not be run before the rational extension test is completed.

6. The next decisive calculation
Step 0: repair the evidence chain

Before another long algebra run:

Export and include the actual CF231 (8,7) hard-strip record. The current packet does not contain it.

Fix the Maple symbol serializer so it is fail-closed.

Persist:

generated Maple input;

process exit code;

Maple exception;

every Mratsolde result;

every denominator/degree attempt;

equation count;

unknown count;

elapsed time;
immediately after each attempt.

Remove:

maple
freeaa := ...;
freeaarules := {seq(q=0,q in freeaa)};

and retain the full affine family.

Do not derive the gauge denominator from the final dlog alphabet alone.

These changes are required even if the final production route is not Maple.

Step 1: start with CF254, because its complete strip is present

For CF254 (9,8):

E is 4×4;

C is 2×2;

R is 4×2;

the vectorized Hom-connection has dimension 8.

The sector dimensions follow from the retained log: sector 8 occupies rows 13–14, and sector 9 occupies rows 15–18. 

Class77LowerChartSystem

This is small enough that a sharp simultaneous system should be manageable.

Step 2: solve residue compatibility, but keep its full affine solution

Write

K
a
	​

=K
a,0
	​

+
ρ
∑
	​

κ
ρ
	​

K
a,ρ
	​

.

Do not set any free residue parameter to zero before the rational gauge problem is solved.

Step 3: perform an exact divisor census of the compatible forcing

For every entry of

F
μ
	​

=
B
μ
	​

−ϵ
a
∑
	​

K
a
	​

∂
μ
	​

logW
a
	​

,

record:

(q,ord
q
	​

F
1
	​

,ord
q
	​

F
2
	​

,ϵ-dependence,allowed/apparent).

Explicitly include q
ϵ
	​

 from Eq. (15).

Use the local recurrence (23) to determine all higher principal parts.

Step 4: determine the polynomial remainder from infinity

After subtracting every forced finite principal part, transform to reciprocal variables and determine the exact allowed bidegree.

This gives a finite, complete basis

{M
α
	​

}
α=1
N
	​

.
Step 5: build one simultaneous exact system

Use

R=
α=1
∑
N
	​

u
α
	​

(ϵ)M
α
	​

.

Substitute into both equations, clear only the proven common denominators, and collect in both chart variables.

Solve the complete affine system

A(ϵ)u=b(ϵ).

Do not solve one orientation first unless using a complete rational-solution algorithm that retains its homogeneous space.

Step 6: solve over finite fields only if useful

If the exact coefficient system is large, evaluate at good epsilon values and finite primes, determine stable pivot and free columns, and reconstruct the full affine solution.

The final characteristic-zero certificate must be

Au
0
	​

=b,AN=0,
(31)

where

u=u
0
	​

+Nλ.

If inconsistent, reconstruct a left-null certificate (12).

Step 7: exact differential gates

For every candidate require Eq. (9) entry by entry.

Then insert it into the complete sector transformation and require:

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

T=A
μ
new
	​

,
(32)
∂
ϵ
	​

(
ϵ
A
μ
new
	​

	​

)=0,
(33)
dA
new
−A
new
∧A
new
=0.
(34)
Step 8: use the equivalent families as complexity alternatives

For each pair:

CF231↔CF305,CF254↔CF265,

compare:

number of divisors;

maximal local pole orders;

polynomial degree at infinity;

number of free residue parameters;

predicted ansatz dimension.

Solve the smaller representative, then transport the gauge through the exact family map and verify the complete transformed connection.

The actual family maps are not present in the attached packet, so I cannot display them or audit their normalization here.

Step 9: only then consider another chart or obstruction class

A birational chart change cannot change whether a rational connection extension splits over isomorphic rational function fields. It can change the size and degree of the formulas substantially.

Change chart only if the local complexity census predicts a much smaller divisor structure.

A complete rational nonexistence certificate would establish:

no rational epsilon-form transformation preserving this block filtration in this rational function field.

It would not, by itself, establish elliptic or non-polylogarithmic master integrals. All diagonal composition factors already have epsilon forms, and the two square roots have been rationalized. The obstruction could instead be:

an extension not split by rational functions;

an incomplete alphabet;

a needed epsilon-dependent intermediate letter;

an unnecessarily rigid block filtration.

A function-class diagnosis would require additional maximal-cut or Picard–Fuchs geometry.

7. Sparse modular solve with complete affine output

Let the local analysis produce matrix-valued basis elements

M
α
	​

(z
1
	​

,z
2
	​

,ϵ)∈Mat
m×n
	​

(K),α=1,…,N.

Write

R=
α=1
∑
N
	​

u
α
	​

(ϵ)M
α
	​

.
(35)

For every allowed dlog letter, write

K
a
	​

=K
a,0
	​

+
ρ
∑
	​

κ
a,ρ
	​

K
a,ρ
	​

.
(36)

The complete unknown vector is

U=(
u
1
	​

	​

⋯
	​

u
N
	​

	​

κ
	​

)
T
.

Substitution into both Pfaffian equations gives a rational linear system. After exact denominator clearing and bivariate coefficient extraction,

A(ϵ)U=b(ϵ).
	​

(37)
Modular evaluation

For several good primes p and regulator values ϵ=ϵ
j
	​

:

evaluate A,b in F
p
	​

;

compute RREF;

require a stable rank and pivot pattern;

retain:

one particular solution;

a basis of the nullspace.

At each point,

U=U
0
	​

+Nλ.
(38)

Reconstruct every entry of U
0
	​

(ϵ) and N(ϵ) as a rational function of ϵ by Chinese remaindering and rational reconstruction.

FiniteFlow can orchestrate the modular evaluations and rational reconstruction once this finite system is supplied. 
GitHub
+1

Do not collapse the affine space

The output must remain

U(ϵ)=U
0
	​

(ϵ)+N(ϵ)λ,
	​

(39)

not merely U
0
	​

.

The free parameters may be needed to:

satisfy the second variable equation;

remove apparent poles;

make the full sector epsilon-factorizable;

simplify the connection;

match a later constant transformation.

Only after all exact two-variable and full-sector constraints have been imposed may unused free parameters be fixed.

Characteristic-zero verification

Require

AU
0
	​

−b=0,AN=0
(40)

exactly over Q(ϵ), followed by the original differential identities (9).

A modularly stable result is interpolation data; Eqs. (40) and (9) are the analytic certificate.

Recommended order for the two classes
CF254 / Kallen13

Fix the Maple serializer and remove freeaa -> 0.

Explicitly include the epsilon-dependent divisor q
ϵ
	​

.

Derive sharp local pole orders.

Build and solve the simultaneous 4×2 rational-gauge system.

In parallel, call full IntegrableConnections:-RationalSolutions on the augmented 10-dimensional connection:

8 gauge components+1+residue parameters.

Use CF265 only if its divisor census is smaller or as an independent transformed-gauge check.

This is the most mature immediate fixture because the complete strip is present.

CF231 / Kallen23

Regenerate and retain the actual (8,7) strip record; it is absent from the attachment.

Complete both one-variable orientations with valid per-attempt ledgers.

Apply the same local divisor and infinity analysis.

Compare the CF231 and CF305 representative complexities before selecting one.

Solve the sharp simultaneous system or augmented RationalSolutions problem.

The existing CF231/CF305 logs do not warrant changing chart, increasing degree, or inferring an obstruction.

Final conclusion

The shortest mathematically conclusive route is:

	​

repair the Maple bridge and preserve affine freedom;
derive sharp local pole orders, including ϵ-dependent apparent divisors;
solve both Pfaffian equations simultaneously;
retain a complete affine rational solution space;
verify the full sector gauge and epsilon-form identities exactly.
	​

	​


Do not spend more time completing the current uniform

(∏W
a
	​

)
p
,p=1,2,3,q=0,1,2

grid. Even completed, it is not exhaustive for CF254 because it excludes the explicit q
ϵ
−2
	​

 divisor, and its implementation destroys the first-equation homogeneous solution space before testing the second equation.

The present records establish that the generic searches did not return a checked gauge within their budgets. They do not establish that either Kallen13 or Kallen23 lacks a rational epsilon-form extension.

## Sources sent to Pro

- [two_root_hard_strip_review_two_root_hard_strip_review.zip](Sources/01_two_root_hard_strip_review/two_root_hard_strip_review_two_root_hard_strip_review.zip)
