# CF259 2719 Degree And Consistency

## Question

Continue the existing “Assess Multiquadratic Pipeline” review using gpt-6-pro.
Please review the current pushed code on branch
`codex/scientific-terminology-and-math-fixes`:

https://github.com/CongyueZhang2002/factorization-and-loops/tree/codex/scientific-terminology-and-math-fixes/FeynFacet/Private

Focus on the mathematics and the dominant algorithms, not on adding hashes,
provenance layers, or redundant validation.  Production keeps exactly one
off-diagonal-block acceptance: the defining identity evaluated at fresh random
points modulo a prime.  Do not propose a characteristic-zero symbolic fallback.

The unresolved corrected three-root block is CF259 `(27,19)`.  Its current
35-one-form residue-only integrability system is consistent at a sampled image
(640 by 140, rank equal to augmented rank, 15.66 s).  However, the complete
degree-zero rational basis-transformation ansatz is inconsistent (480 support
monomials, 15,500 unknowns, 15,616 by 15,500), and the complete degree-one
rectangular ansatz is also inconsistent (525 support monomials, 16,940
unknowns).  Thus we have excluded degrees zero and one for the current alphabet,
but have not proved that no rational dlog epsilon form exists at higher degree or
with a larger logarithmic one-form span.

Questions:

1. What is the cheapest mathematically valid way to obtain a finite upper bound
   on the numerator degree over the multiquadratic coefficient field?  Can
   valuations at finite divisors plus directional/projective infinity analysis
   prove that testing degrees zero and one is exhaustive here?  Give an
   implementable algorithm, including how homogeneous solutions and resonant
   leading matrices affect the bound.
2. How should we determine whether the current 35 one-forms span all logarithmic
   one-forms needed by this block?  In particular, what mixed-grade divisor or
   algebraic-letter construction is required before a no-dlog-epsilon-form claim
   is honest?
3. The complete modular systems are close to square, but an inconsistent ansatz
   may become inconsistent after far fewer kinematic points.  Is it sound to
   stream point rows into a native FLINT consistency-only elimination, returning
   only rank and augmented rank, and stop as soon as rank([A|b]) exceeds rank(A)?
   If still consistent after enough rows, the existing full affine-plan solve
   would run once.  Specify the safest incremental elimination design and what,
   if anything, must be retained between point batches.
4. Could this consistency-first route avoid retaining two dense Wolfram copies
   of the sample matrix?  Recommend a minimal streaming/preallocated interface,
   not a large rewrite.

Performance is a mandatory acceptance condition.  On the identical hard
CF259 `(27,23)` block, current solve plus pull-back is 951.4 s versus 1,436.8 s
before.  On the identical complete `(27,19)` degree-zero modular system, the
current terminal inconsistency takes 151.2 s versus an earlier unresolved run
already beyond about 538 s.  A provisional degree-one restricted-support
shortcut was removed because it made the hard block slower.  Any proposed code
change must be benchmarked against both hard blocks and retained only if it is
faster without weakening the one required modular identity test.

Please give a prioritized recommendation: first the next decisive mathematical
test for `(27,19)`, then the simplest major performance improvement.  Clearly
separate proven implications from probabilistic evidence and from heuristics.

## Pro response

Recommendation

For (27,19), do a small indicial/valuation calculation before another large numerator ladder. For performance, use a native forward-elimination path that can stop on inconsistency and, on success, continue into the existing affine-plan construction without refactoring.

Two conclusions are already firm:

The failures at offsets zero and one do not establish an exhaustive numerator bound.

The code’s algebraic-letter generator does not establish completeness of the 35-form alphabet.

I inspected the requested branch at commit 38b1f56, including the multiquadratic preparation, letter generation, support ladder, sample assembly, and native affine solver. I did not execute the production benchmarks. In particular, the current preparation constructs

numeratorDegrees=denominatorDegrees+degreeOffset

and then a rectangle. These are offset-zero and offset-one tests, not polynomial degrees zero and one. The denominator-Newton-support shortcut is separately restricted away from deferred bundles in the inspected code.

1. Next mathematical test: obtain bounds in the actual coefficient-field basis

Write the unknown transformation as

G=
I⊆{1,2,3}
∑
	​

r
I
	​

g
I
	​

,g
I
	​

=
Q(x,y,ϵ)
P
I
	​

(x,y,ϵ)
	​

.

For a 2×2 block, this gives 32 rational coefficient functions. The defining equation is

dG−ϵ(EG−GC)=B−ϵW,W=
a
∑
	​

M
a
	​

(ϵ)ω
a
	​

.
(1)

The relevant bound is a bound on the P
I
	​

, not simply on the growth of G. The roots themselves have finite-divisor and infinity valuations.

The cheapest useful representation is a 32-dimensional rational differential system

Multiplication by E
μ
	​

 and C
μ
	​

 is already represented by the package’s grade arithmetic. Differentiation adds

dr
I
	​

=r
I
	​

γ
I
	​

,γ
I
	​

=
2
1
	​

i∈I
∑
	​

dlogΔ
i
	​

.

Consequently, the vector g of the 32 rational coefficients satisfies

∂
μ
	​

g=[ϵM
μ
	​

−Λ
μ
	​

]g+b
μ
	​

−ϵW
μ
	​

m,
	​

(2)

where Λ
μ
	​

 contains the γ
I,μ
	​

, repeated for each matrix entry.

This is small enough for local indicial analysis. It is also the safest way to avoid missing half-integer root contributions or cancellations between apparent poles in the raw radical basis.

Universal-denominator and infinity-degree bounds obtained from local indicial equations are standard in rational-solution algorithms for linear differential systems; Barkatou’s method is the relevant algorithmic precedent, rather than a blind polynomial-support search. 
Algo Inria

Finite-pole bound

First consider a genuine local uniformizer t on the normalized algebraic cover. Suppose the diagonal connections are logarithmic:

E
t
	​

=
t
E
0
	​

	​

+O(1),C
t
	​

=
t
C
0
	​

	​

+O(1),

and

B
t
	​

=O(t
−b
).

A logarithmic target contributes at most t
−1
dt. If G had a pole of order

m>max(0,b−1),

its leading coefficient would obey

[−mI−ϵ(I⊗E
0
	​

−C
0
T
	​

⊗I)]vecG
−m
	​

=0.
	​

(3)

If E
0
	​

,C
0
	​

 are epsilon-independent, the determinant has constant term m
4

=0. Therefore such an extra pole is impossible over the generic field Q(ϵ).

But this argument is not valid merely because the package stores epsilon-linear diagonal blocks. The actual leading matrices can acquire epsilon-independent shifts from the radical coefficient basis or local shears. Diagonal residues may themselves depend rationally on epsilon.

For the rational coefficient system (2), use its actual local residue A
0
	​

(ϵ). The exceptional pole orders satisfy

det(−mI−A
0
	​

(ϵ))=0
	​

(4)

identically in epsilon and the transverse variables.

A determinant vanishing at one sampled epsilon is not a generic resonance.

A safe bound retains

m≤max{0, b−1, positive integer resonant orders from (4)}.
(5)

The same leading recursion can determine whether the resonant coefficient is actually admissible. For an upper bound, however, retaining all resonant orders is sufficient. Do not remove them merely by choosing a normalization for homogeneous freedom.

Infinity bound

Do the same calculation at:

x=∞, treating y as a parameter;

y=∞, treating x as a parameter.

Use t=1/x or 1/y, including the differential Jacobian. For each grade coefficient, a pole bound

ord
x=∞
	​

g
I
	​

≥−h
I,x
	​


implies

deg
x
	​

P
I
	​

≤deg
x
	​

Q+h
I,x
	​

.
	​

(6)

Likewise for y. Grade-specific bounds can be smaller than a common rectangle.

This first pair of infinity calculations is more directly useful than a general projective-resolution computation: your tested ansätze are rectangles. Weighted directions such as (1,1),(2,1),(1,2) can tighten the resulting polygon later, but are not needed to decide whether the existing rectangle is exhaustive.

The implementable finite calculation

Use the existing coefficient-field arithmetic to:

Form the 32-dimensional homogeneous operators in (2), without expanding the inhomogeneity.

Collect the finite singular factors from those operators, the root radicands, and the inhomogeneity denominator/norm data.

At each relevant factor and at the two coordinate infinities, compute only the local leading matrices and required principal parts.

Determine the finite integer resonance set and obtain bounds in the package’s actual coefficient basis.

Compare the resulting universal denominator and numerator rectangle with the already tested support.

The local coefficient operations can use the existing modular/DAG evaluators to discover leading data. A proved bound requires establishing the resulting small indicial identities generically; a bound inferred from a few specializations remains a heuristic. This is a local mathematical calculation, not a symbolic fallback for solving the block or another production residual.

If the coefficient system is not Fuchsian in its current local basis, first perform a small local regular-singular reduction and track the basis valuation shifts. Applying (3) directly to a higher-pole coefficient matrix is invalid.

Decisive outcomes
Local result	Consequence
Universal denominator divides the current Q, and all numerator bounds lie inside the tested offset-one rectangle	Higher numerator offsets are unnecessary for the specified target class and pole assumptions
A bound exceeds that rectangle	The calculation identifies exactly which direction/grades need additional support
A resonant leading matrix remains	Retain its finite exceptional orders; do not declare the old support exhaustive
The logarithmic/local-lattice hypothesis fails	The present “one order below the forcing” rule is not a proved bound

The two support counts alone cannot choose between these outcomes. The branch currently obtains a denominator and adds the requested offsets; that is an ansatz construction, not the above indicial proof.

2. The 35-form alphabet is not yet certified complete

The residue-only integrability screen is correctly a necessary condition: once the diagonal curvatures vanish and the candidate forms are closed, cross-differentiation eliminates G. Its consistency does not imply that the resulting inhomogeneity has a rational primitive in the twisted system. The inspected implementation describes and implements this distinction.

What is missing from the automatic letter search

multiquadraticOffDiagonalBlockAlgebraicLetters currently searches each declared root separately for letters

A±r
i
	​

,A
2
−Δ
i
	​

=cM,

where M ranges over a bounded collection of products of polar factors. The defaults are

MaximumNormFactors  -> 2
MaximumNormExponent -> 2

That is a practical candidate generator, not a completeness theorem. It does not automatically cover the four additional quadratic subfields generated by

r
1
	​

r
2
	​

,r
1
	​

r
3
	​

,r
2
	​

r
3
	​

,r
1
	​

r
2
	​

r
3
	​

.

Some of these may already occur in inherited or supplied letters, so the installed 35 records must be inspected before declaring a particular direction missing.

A useful exact simplification: seven quadratic subfields suffice for dlog spanning

Let K/F have Galois group (Z/2)
3
. For a character χ, define

L
χ
	​

=
σ∈Gal(K/F)
∏
	​

σ(L)
χ(σ)
.

Then

8
1
	​

σ
∑
	​

χ(σ)σ(dlogL)=
8
1
	​

dlogL
χ
	​

.
	​

(7)

For nontrivial χ, L
χ
	​

 lies in the associated quadratic subfield F(r
χ
	​

), and its nontrivial conjugate is L
χ
−1
	​

.

Therefore every K-valued dlog decomposes into:

a rational dlog;

character components coming from the seven quadratic subfields.

This does not give a finite-degree completeness theorem, but it supplies a much more systematic search than only the three declared generators.

Smallest useful alphabet extension

For each of the four product-root square classes not already represented, search for letters

L
χ
	​

=
A−Br
χ
	​

A+Br
χ
	​

	​

,
(8)

where the divisor of A
2
−B
2
Δ
χ
	​

 lies over the admitted polar divisor.

Use the existing grade-based LetterDLogDataInField machinery to compute their dlogs, and retain only forms that enlarge the constant-coefficient span of the installed alphabet. Do not test span with kinematics-dependent coefficients.

This is a targeted candidate extension. Do not simultaneously widen every norm-factor exponent and every numerator degree.

Norms alone cannot establish completeness: the ratio in (8) has norm one, although its dlog can be nonzero and distinguish conjugate divisor components.

What would justify an actual completeness claim?

On a normal projective model 
X
ˉ
 of the coefficient-field cover, let D contain the admitted polar components, their conjugates and infinity. Rational letters with zeros and poles supported there correspond to units on 
X
ˉ
∖D, modulo constants. Their divisors lie in

ker(
j
⨁
	​

Z[D
j
	​

]⟶Cl(
X
ˉ
)).
(9)

A generating set of this principal-divisor lattice gives the required dlog span. The units/divisor-class relation is standard; it is also why factorization of norms downstairs is not enough to enumerate functions upstairs. 
arXiv

Two qualifications matter:

A multiquadratic cover is not P
2
. Do not reuse the rational-surface assertion that component dlogs exhaust all logarithmic forms.

General logarithmic differentials can include holomorphic directions that are not dlogs of algebraic functions. If the required target is a dlog epsilon form, the relevant completeness problem is the dlog/unit span, not every closed differential.

Thus the honest current statement is:

The specified 35-form target fails in the two tested transformation spaces. Neither transformation-degree completeness nor logarithmic-alphabet completeness has yet been proved.

An added divisor visible only in a forcing numerator is not automatically useful. At a divisor where the original equation and transformation are regular, a strict dlog target must have zero total residue. Focus on split components above the admitted polar divisor, not indiscriminate numerator factorization.

3. Streaming inconsistency detection is sound—but do not perform two eliminations on successful blocks

For a fixed prime, epsilon, support and alphabet, let

A
k
	​

x=b
k
	​


contain the first k point batches.

If

rank[A
k
	​

∣b
k
	​

]>rankA
k
	​

,

then every extension of that sampled system is inconsistent. Stopping immediately is exact finite-field linear algebra.

The returned ranks are ranks of the processed prefix, not of the unprocessed complete matrix. With one RHS, the defect is exactly one.

What the current branch does

The current multiquadraticOffDiagonalBlockAffineConsistencyEvidence calls ...PlanDiscoverySolve. It does not have a separate incremental consistency engine. On native inconsistency it correctly avoids a second homogeneous RREF and reports missing absolute ranks rather than inventing them. Preserve that improvement.

In flint_affine_rref.c, the current flow is:

allocate original A and augmented [A∣b];

read the complete matrix into both;

run _nmod_mat_rref on the augmented matrix;

only afterward detect an RHS pivot;

if consistent, construct the affine plan and its other outputs.

FLINT 3.0.1’s actual _nmod_mat_rref first computes LU/echelon form, then allocates triangular/nonpivot blocks and performs the additional reduction to RREF. Consequently consistency can be decided before the RREF completion.

Safest incremental design

Maintain an echelon system with coefficient pivots only. After k batches, write it schematically as

[U  V∣c],

where U is triangular and invertible on the current pivot columns.

For a new batch

[Z
P
	​

  Z
F
	​

∣z],

eliminate the existing pivots:

L=Z
P
	​

U
−1
,
Z
F
	​

=Z
F
	​

−LV,
z
=z−Lc.
	​

(10)

Apply rank-revealing forward elimination to the remaining coefficient block, carrying the RHS through the same operations.

A row [0⋯0∣β], β

=0, ends the calculation.

A new coefficient pivot is retained.

A zero row with zero RHS is discarded.

Use blocked triangular solves and matrix multiplication, rather than restarting RREF after every batch or implementing a large scalar row-by-row loop. FLINT supplies the required dense triangular and multiplication kernels. 
Flint Library

A natural initial panel size is 4–8 kinematic points, or 256–512 rows here. This is a benchmark parameter, not a mathematical prescription.

State that must survive between panels

Retain only:

the echelon coefficients and transformed RHS;

pivot-column indices and row permutations/original independent-row indices;

the current rank and number of processed rows;

enough original-row storage to complete the existing affine-plan operation if consistent.

No inverse witness or full nullspace is needed while inconsistency is still being tested.

Do not mix different primes, epsilon values, supports or alphabets inside this state.

Also, test the physical PDE rows, not arbitrary normalization equations inherited from a different ansatz. Such normalization can remove a valid affine representative and create a false no-go.

The important performance objection

A design that performs:

a complete consistency elimination, and then

a fresh full affine-plan elimination

will likely slow the successful (27,23) block.

Instead, use one native computation with two exits:

inconsistent prefix
    -> return immediately

all requested rows consistent
    -> finish the affine plan from the retained factorization

The public result of the inconsistency phase may contain only ranks/status, but its native factorization must remain available on the consistent path.

There is no reason to assume contradiction will appear much earlier. If a prefix has full row rank, it fits every RHS. The 140-residue integrability test being consistent may mean that the expensive obstruction appears only when the transformation coefficients become overdetermined.

Therefore early exit is a hypothesis to measure, not an automatic multi-fold speedup.

4. Avoiding the dense Wolfram copies

There is a direct insertion point in the pushed code.

multiquadraticOffDiagonalBlockAssembleSample already obtains native row batches through

multiquadraticOffDiagonalBlockNativeRowAssembleBatch

but reads those rows back into Wolfram, places them in per-point accepted records, concatenates them into pointRows, and then builds the packed matrix. This is exactly the duplication a row sink can avoid.

Minimal interface

Keep the existing coefficient provider and row arithmetic. Add a native sink immediately after each row batch:

BeginImage(prime, unknownCount, rowBudget)
AppendPointRows(rows, rhs)
    -> consistent prefix / inconsistent prefix
FinishImage()
    -> full affine plan if consistent

An append-only binary spool plus a persistent native process is sufficient. A new general matrix service is unnecessary.

In Wolfram, retain only accepted-point metadata and at most the current panel. Do not retain accepted[[...,"Rows"]] and then concatenate the entire sample.

For your baseline matrix:

15616×15500×8=1.936 GB≈1.803 GiB

per dense limb array. A 256-row augmented panel occupies only about 30.3 MiB. These figures explain the memory opportunity independently of any elimination speedup.

On the native side, keep one working elimination buffer. Original rows required by the consistent-plan path can reside in a file or memory-mapped backing store instead of a second resident copy allocated before an inconsistency verdict is known.

The final fresh-point defining-identity acceptance remains unchanged.

5. Prioritized execution and stopping criteria
First: the decisive mathematical calculation

Compute local indicial bounds, starting with x=∞ and y=∞, then reconcile the finite-divisor bounds in the actual eight-grade representation.

The output should be a finite table:

{divisor/direction, grade, allowed pole order, allowed numerator degree, resonant exceptions}.

Then:

If the bound fits the tested offset-one support: stop enlarging numerator degree for the current target space. Move to the missing mixed-character dlog span.

If it exceeds that support: solve the explicitly bounded enlargement identified by the calculation—not a blind offset ladder.

If a local logarithmic hypothesis fails: stop calling the current rectangle exhaustive. Resolve that local basis issue before making a no-go claim.

The first alphabet extension should be the unrepresented product-root characters, filtered by actual pole support and constant-coefficient span. The generator’s bounded norm search is not grounds for a global no-dlog conclusion.

Second: the performance pilot

Use the already captured complete matrices, before changing live physics sampling:

Run the proposed incremental forward elimination on the identical (27,19) row order. Measure where the first contradiction occurs and the total time.

Run the same backend on the successful (27,23) pilot, finishing its affine plan from the retained state.

Only then connect the existing row assembler to the native sink and measure end-to-end solve/pullback.

Keep the change only if it improves both current benchmarks, not merely the older unresolved timings:

(27,19): below the current 151.2 s, beyond measurement noise;

(27,23): below the current 951.4 s solve-plus-pullback time.

If contradiction appears only near the final panel and incremental processing is slower, reject that elimination strategy. A memory-saving preallocated sink can still be evaluated separately, but it must meet your same performance rule.

Do not retain:

repeated RREF of growing prefixes;

a full consistency pass followed by a second full factorization;

a scalar incremental loop that loses the existing eight-thread efficiency;

another restricted-support shortcut without a mathematical reason and a winning benchmark.

What is proved, and what is not
Statement	Status
An inconsistent sampled prefix remains inconsistent after adding rows	Proved
A full-row-rank prefix supports every RHS	Proved; consistency there is not evidence
The 35-form integrability screen is necessary for the proposed completion	Proved under its flat-diagonal/closed-form hypotheses
Offset-zero and offset-one inconsistency excludes all higher numerator degrees	Not established
The current automatic letter generator spans all needed algebraic dlogs	Not established
Local indicial data can give a finite denominator/numerator bound	Yes, with the actual local coefficient basis and resonances included
Modular instances establish the generic characteristic-zero no-go	Probabilistic evidence unless the generic-rank/degree argument is supplied
Streaming will outperform 151.2 s and 951.4 s	Unmeasured; benchmark required

Bottom line: the next mathematical work should reduce uncertainty about the finite search space, not merely enlarge it. The next performance work should fuse row production with forward elimination and reuse that factorization on success. Both changes preserve the one required fresh-point modular identity test; neither requires characteristic-zero materialization.
