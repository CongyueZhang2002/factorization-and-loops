Verdict: GO—use SparseFirst for this oversized block, with a bounded preliminary ladder

Changing the support search order is mathematically sound. A smaller support need only contain one valid rational basis transformation; it need not reproduce the representative selected by the full simplex. The existing held-out regulator tests and original-equation residual remain the acceptance criteria.

The immediate intervention should be smaller support before the first factorization, not a new sparse linear-algebra backend. The inspected implementation performs support learning after the first full plan-discovery solve, so support learning cannot rescue the current 11.7k-column startup cost.

Source scope: the renamed FiniteFieldOffDiagonalBlockSolve.wl was not available on public main. I inspected its accessible predecessor, FiniteFieldStripSolve.wl, including the support constructor, ladder, degree probes, normalization, and learning code. The code-specific observations below refer to that version; the live dimensions and timings are from your report.

1. SparseFirst is sound; an unconditional long sparse ladder may be slow

Write the block equation as

L
μ
	​

(G)+ϵ
a
∑
	​

R
a
	​

ω
a,μ
	​

=B
μ
	​

,L
μ
	​

(G)=∂
μ
	​

G−ϵ(E
μ
	​

G−GC
μ
	​

).

For a fixed denominator Q, choose

G
ij
	​

=
Q
1
	​

α∈S
∑
	​

g
ij,α
	​

x
α
1
	​

y
α
2
	​

.

Restricting S sets some unknown coefficients to zero. It does not alter the equation, denominator, alphabet, or mathematical meaning of a solution.

Therefore:

Success on a smaller support is sufficient, once the reconstructed candidate passes the original block equation.

Failure on a smaller support is only failure of that ansatz.

A different affine representative is not a coherence defect. Subsequent blocks must use the transformation actually returned, rather than mixing it with coefficients or normalization data from another representative.

For this off-diagonal convention, the complete transformation remains

U=(
I
G
	​

0
I
	​

),U
−1
=(
I
−G
	​

0
I
	​

).

There is no additional invertibility requirement on G.

What the inspected ladder actually does

The code confirms the intended distinction:

"Sparse" means the denominator-degree rectangle plus offsets, intersected with the total-degree bound.

"Simplex"/Automatic means the complete total-degree simplex.

"SparseFirst" ultimately tries the full certified simplex if the preliminary support ladder finds no consistent candidate.

An inconsistent rectangle skips its intermediate sub-supports, which is a valid containment argument.

The historical x-degree-six versus denominator-degree-three example therefore argues against treating the rectangle as exhaustive, not against trying it first.

Two relevant subtleties in the code

First, SupportStrategy changes the default only when "Support" -> Automatic. An explicitly supplied support or "Rectangle" overrides that route. Keep this distinction when selecting the production option.

Second, terminal fallback must remain reachable after a misleading pilot success. A small support may work at ϵ=ϵ
0
	​

 because a missing coefficient contains ϵ−ϵ
0
	​

, then fail during regulator reconstruction. The inspected terminal-simplex branch is entered when no support was selected during the initial ladder—not automatically after every later failure. Its support-learning wrapper also returns any association immediately, including a typed failure association. This cannot falsely certify a solution, but it can cause a premature false negative rather than returning to the unshrunk support.

The correct policy is:

A failed learned or accidentally consistent small support returns to the retained broader support; it does not become evidence that the full simplex is inconsistent.

Affine normalization

Freeze one support layout and one admissible normalization section for the subsequent epsilon/prime reconstruction. A new support requires a corresponding plan; raw column numbers from the old support have no invariant meaning.

The existing normalization routine deliberately prefers trailing transformation coefficients before residue coordinates, because earlier residue-first choices produced unnecessarily complicated representatives. Preserve that intent. Changing support may still change the chosen representative and its regulator degree, but that is a complexity issue, not incorrect mathematics.

Recommendation: use sparse-first for this large-system case. Do not infer from this one case that it should run an unrestricted preliminary ladder for every easy family.

2. The immediate gain can be large

The degree-75 simplex contains

M
full
	​

=(
2
77
	​

)=2926

monomials. Your dimensions are consistent with four transformation entries and 60 residue unknowns:

N
full
	​

=4(2926)+60=11764.

Thus nearly all columns are numerator-support coordinates.

For a candidate with M monomials,

N(M)=4M+60.

The following gives the potential reduction under a rough dense cubic elimination model, not a measured wall-time prediction:

Candidate monomials	Unknowns	Matrix storage relative to full	Dense elimination work relative to full
1,000	4,060	0.12	0.041
1,500	6,060	0.27	0.137
2,000	8,060	0.47	0.322
2,926	11,764	1	1

This is why reducing the initial support is a plausible multi-fold intervention, whereas optimizing a few matrix passes is not.

Count the actual candidate supports before submitting them. A rectangle is not necessarily smaller than the simplex, and the two need not contain one another.

Bound the preliminary search by matrix size

For this block, I would:

try the smallest existing rectangle-cut candidate;

permit only a few genuinely different enlargements that remain substantially smaller than the full system;

then go directly to the full simplex.

A practical initial ceiling is about 60% of the full unknown count, approximately 7,060 columns or 1,750 monomials here. This is a performance heuristic, not a mathematical bound.

Do not run all 25 offset combinations merely because they exist. The inspected default offset ladder covers offsets through four in each variable; several costly failed probes can erase the advantage of sparse-first.

If the smallest rectangle-cut already has almost 2,926 monomials, changing the strategy label alone is unlikely to help substantially.

3. Can the differential equation give a better support?

Yes, through directional infinity bounds. No, not by taking the numerator support of the forcing or denominator alone.

The denominator controls finite poles. It does not determine numerator growth at infinity, and it does not determine the support of a particular solution modulo homogeneous freedom.

Best next support calculation: directional infinity bounds

Keep the certified total-degree constraint

i+j≤75,

and try to derive additional bounds on i, j, or weighted degrees. Begin with x→∞ at generic fixed y, and y→∞ at generic fixed x. These are the directions most directly relevant to improving a rectangle.

More generally, use

x=ξt
w
x
	​

,y=ηt
w
y
	​

,t→∞,

with a small set of weights such as

(1,0), (0,1), (1,1), (2,1), (1,2).

Contract the one-form equation with

V
w
	​

=w
x
	​

x∂
x
	​

+w
y
	​

y∂
y
	​

.

Suppose the contracted diagonal connections have finite limits E
w,∞
	​

,C
w,∞
	​

, the dlog target is O(1), and the contracted inhomogeneity grows at most as t
b
w
	​

. If

G∼t
h
G
h
	​

,h>max(0,b
w
	​

),

the leading equation is

[hI−ϵ(I⊗E
w,∞
	​

−C
w,∞
T
	​

⊗I)]vecG
h
	​

=0.

When E
w,∞
	​

 and C
w,∞
	​

 are epsilon-independent and h

=0, this operator has determinant with nonzero constant term h
4
. It cannot support such a leading homogeneous term over Q(ϵ). Consequently,

deg
w
	​

P≤deg
w
	​

Q+max(0,b
w
	​

),G=P/Q.
	​


Intersect the resulting half-spaces to obtain a smaller numerator polygon.

This calculation is small: it concerns leading coefficients and a four-dimensional matrix operator, not an 11.7k-dimensional solve.

The qualification matters: logarithmic behavior at ordinary projective infinity does not automatically establish the same hypothesis at every weighted or coordinate infinity. If the contracted diagonal connection grows, or its leading operator is resonant, retain that direction as inconclusive. Do not turn it into a guessed hard bound.

What Newton polytopes can safely provide

For the factored denominator

Q=
ν
∏
	​

f
ν
m
ν
	​

	​

,

the Newton polytope satisfies

Newt(Q)=
ν
∑
	​

m
ν
	​

Newt(f
ν
	​

).

Its support function gives deg
w
	​

Q without expanding the product. This is useful for the preceding calculation.

But simply “subtracting the denominator polytope” from the inhomogeneity polytope does not recover the numerator support. The differential operator contains sums whose leading parts may cancel, and homogeneous solutions are invisible in the inhomogeneity.

The deferred DAG can supply inexpensive directional evaluations or conservative growth bounds. A degree observed on one modular specialization is a candidate bound, not a theorem. It is perfectly usable to propose a smaller pilot support, provided failure returns to the complete support and success goes through the existing residual.

For now, run the existing small-support pilot before implementing a general Newton-polytope engine.

4. Sparse linear algebra is probably not the first answer

SparseFirst means fewer monomial columns. It does not imply that the sampled matrix is sparse.

For a 2×2 block, one equation for G
ij
	​

 couples to

G
ij
	​

,G
aj
	​

,G
ib
	​


through differentiation, EG, and GC. With dense 2×2 diagonal blocks, that is up to three complete monomial blocks per row. At generic nonzero sample points, those blocks are generally dense: roughly 75% of the transformation columns may be populated.

Therefore a generic sparse RREF implementation may do more bookkeeping while still experiencing nearly dense fill-in. Sparse/black-box finite-field methods are advantageous when the matrix is genuinely sparse or admits much cheaper matrix-vector products; they are not an automatic improvement for polynomial collocation matrices.
arXiv

A real block decomposition is worth using

Construct the dependency graph of the four entries of G from

I⊗E
μ
	​

−C
μ
T
	​

⊗I,μ=x,y.

If its strongly connected components are smaller than four, solve those components in triangular order, retaining their associated residue unknowns.

This can give a genuine reduction. But do not split by output row or column merely because G is 2×2:

left multiplication by E couples rows;

right multiplication by C couples columns.

The actual E,C entries were not supplied, so I cannot assert that this block decomposes.

A Schur complement is not a free shortcut

Writing the matrix as

[A
G
	​

∣A
R
	​

]

and eliminating transformation coefficients to leave approximately 60 residue coordinates still requires eliminating the large A
G
	​

 block. It may simplify subsequent solves, but it does not remove the first large factorization.

Likewise, a small integrability system for residues can constrain those 60 coordinates; it does not by itself recover the 11,704 transformation coefficients.

Best deeper alternative, only if the large support is unavoidable

Clear denominators in the differential equation and match polynomial coefficients:

Q∂
μ
	​

P−(∂
μ
	​

Q)P−ϵQ(E
μ
	​

P−PC
μ
	​

)+ϵQ
2
a
∑
	​

R
a
	​

ω
a,μ
	​

=Q
2
B
μ
	​

.

After clearing the remaining coefficient denominators, multiplication by known polynomials becomes sparse shifted convolution of numerator coefficients. This can yield a genuinely sparse coefficient matrix, unlike pointwise monomial collocation.

That is a substantive algorithm change: RHS reconstruction and polynomial coefficient support must also be handled. It is not the smallest intervention for this run.

If a backend change is eventually needed, rank-revealing LU plus the necessary triangular solves is a more natural first comparison than a wholesale Wiedemann implementation. FLINT’s RREF itself is documented as LU followed by an additional triangular reduction, so merely replacing the name of the routine cannot remove the dominant elimination cost.
Flint Library

5. Minimum acceptance—unchanged

Use the existing production contract:

∂
μ
	​

G−ϵ(E
μ
	​

G−GC
μ
	​

)−B
μ
	​

+ϵ
a
∑
	​

R
a
	​

dlogL
a
	​

=0,μ=x,y,

at the existing fresh kinematic/regulator/prime images, together with the existing alphabet/residue conditions.

Three requirements belong to the construction, not to additional certification:

Overdetermine every candidate using its actual column count. The inspected PointCount -> Automatic does this, with eight equations per kinematic point for the inferred 2×2 case. Do not use a tiny underdetermined fit as evidence that a support works—the previous CF303 saturation episodes already established that failure mode.

Keep one affine section during reconstruction. Do not mix differently normalized epsilon images or reuse an old plan after changing monomial coordinates.

Treat learned zeros as provisional. A coefficient zero at the pilot can be nonzero at another epsilon or prime. The existing held-out tests decide whether the reduced support remains valid; they need not be duplicated. Learning and removing zero unknowns after a pilot is also a standard finite-field strategy described in FiniteFlow.
arXiv

There is no need to solve the full degree-75 simplex afterward merely to confirm an accepted smaller-support solution. The full simplex is the completeness fallback within the specified denominator, target alphabet, and degree assumptions, not a mandatory success certificate.

Immediate recommendation

Use the existing route with

Support             -> Automatic
SupportStrategy     -> "SparseFirst"
SupportLearning     -> True
PointCount          -> Automatic
PlanDiscoveryBackend -> "FLINTAffineRREF"

but put a size/cost-bounded prefix in front of the terminal simplex:

Try the smallest rectangle-cut support if it substantially reduces the 11,764 columns.

Allow only a few distinct, inexpensive enlargements.

On the first useful consistent support, proceed directly to learning and the existing reconstruction.

If those candidates fail, use the complete simplex once; do not exhaust many near-full-size rectangles first.

If the current running RREF has already completed, reuse its pilot and learned support rather than discarding it solely because the policy changed.

The intervention to make now is “smaller first system,” not “different RREF.” It is mathematically sound, uses machinery already present, and has a credible multi-fold payoff. Directional infinity bounds are the next support refinement; a new sparse backend should wait until a genuinely sparse or decomposable operator has been identified.