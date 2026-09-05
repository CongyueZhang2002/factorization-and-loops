# CF259 Rank3 Module

## Question

Please assess the current CF259 triple-root off-diagonal epsilon-form bottleneck in the context of our existing "Assess Multiquadratic Pipeline" discussion. I need a concrete algorithmic recommendation, not generic cautions or more hashing/checks.

The exact block is CF259 (27,1), 3 radicals, 50-letter alphabet. The original rectangular gauge support had 320 monomials: 5,120 gauge unknowns + 100 residue unknowns, a 5,280 x 5,220 finite-field system, rank 5,172 and affine nullity 48. A 61-bit, exact modular run using one fixed normalization section collected enough images to reach total epsilon degree 64, but every non-pinned coordinate still failed rational reconstruction; adding primes cannot fix this.

We then found a rigorously smaller downward-closed support of 214 monomials. This reduces the system to 3,584 x 3,524, rank 3,476 and the same nullity 48. One fibre improved from about 17.5 s assembly + 54.8 s RREF to 10.4 s + 19.3 s. However, the same affine-section reconstruction failed through total degree 16 and a degree-32 run is currently underway.

Several exact diagnostics constrain the interpretation:

1. Three different fixed affine sections (native, free-column, residue-head) all failed at low degree with essentially the same split, so this is not merely one unlucky pinned coordinate choice.
2. A coupled affine-bundle solver parameterized each fibre as x_i = p_i + N_i t_i and directly searched for a representative P(epsilon)/D(epsilon) with one common scalar denominator. It found no solution through numerator degree 16 and denominator degree 16. This only disproves the overly restrictive single-common-denominator ansatz.
3. Forcing all 100 residue coordinates to be polynomial in epsilon was inconsistent through degree 16; degree 17 was only the trivial interpolation threshold. So per-block epsilon-independent residues are not valid in the current diagonal basis; family-level regulator factorization is still needed.
4. Most importantly, the 48-dimensional homogeneous nullspace projects with rank only 10 onto the gauge coordinates, while its residue-coordinate projection has rank 48. Thus 38 directions are pure alphabet/residue relations and only 10 directions can change the gauge.

What is the fastest mathematically sound route now? Please compare and, if possible, give implementable details for:

- quotienting the 38 pure residue relations and solving a minimal rational section on the 10-dimensional gauge-effective bundle;
- a polynomial-matrix/minimal-approximant-basis or Popov-form solution over F_p[epsilon];
- fixed-core Taylor recurrence plus Pade/Berlekamp-Massey reconstruction, reusing one factorization rather than rebuilding full matrices at every epsilon;
- any better physics normalization or module formulation that permits different coordinate denominators without symbolic radical algebra.

Please specify the unknowns/equations, expected asymptotic and practical cost for dimensions above, how to reuse the existing finite-field fibre provider, and a minimal probabilistic modular acceptance test. We explicitly do not want a production symbolic/Maple equality check or redundant defensive checks. Also say whether the 38/10 projection fact suggests a much smaller quotient problem and how to construct that quotient without changing the physical solution space.

## Pro response

Recommendation

GO: quotient the 38 pure-residue relations, then use fixed-core Taylor/Dixon lifting with coordinatewise Padé reconstruction. Retain the ten gauge-effective homogeneous directions as a small affine-bundle object, but do not make a full polynomial-kernel computation the first implementation.

NO-GO: more independent full RREFs at successive epsilon values, another low-degree common-scalar-denominator search, or forcing the residues to be polynomial before family regulator factorization.

The key distinction is:

The 38/10 split substantially reduces the solution representation, but only slightly reduces the large coefficient matrix. Taylor lifting removes the repeated expensive matrix factorizations; quotienting prevents reconstruction of 38 physically meaningless residue directions.

1. Construct the quotient explicitly

For the reduced support, write the physical system as

A
g
	​

(ϵ)g+A
r
	​

(ϵ)r=b(ϵ),

where

g∈F
ℓ
	​

(ϵ)
3424
,r∈F
ℓ
	​

(ϵ)
100
.

Indeed,

3424=214×16,3424+100=3524.

Write a homogeneous basis as

N=(
N
g
	​

N
r
	​

	​

),N
g
	​

:3424×48,N
r
	​

:100×48.

Your ranks imply

dimkerN
g
	​

=38.

If V spans kerN
g
	​

, then

Z=N
r
	​

V∈F
ℓ
100×38
	​


spans the pure-residue relations:

A
r
	​

Z=0.

They also imply

rankA
r
	​

=62,rankA
g
	​

=3424.
	​


The second equality follows because the residue projection of the full nullspace is injective: there is no nonzero homogeneous solution with residues zero.

Use a fixed quotient of the one-form map

Choose a constant complement T∈Q
100×62
 to Z, and a quotient map Π satisfying

ΠT=I
62
	​

,kerΠ=imZ.

Then replace

r⟼ρ=Πr,r
representative
	​

=Tρ.

The equivalent physical system is

A
g
	​

g+A
r
	​

Tρ=b,
	​


with

3486 unknowns,3476 rank,10 nullity.

This removes no physical gauge or target one-form. It only selects a representative of the zero-one-form residue relations.

Construct Z,T,Π from the actual one-form map, not independently from arbitrary numerical nullspace bases at every epsilon. With epsilon-free letters, the residue block is normally ϵA
r,0
	​

, up to row scalings, so its relation space is epsilon-independent. If that assumption is false for this implementation, the quotient must instead be constructed over F
ℓ
	​

(ϵ).

In the usual letter-times-matrix-entry layout, the 38 relations correspond to 19 redundant scalar forms for each of the two gauge entries: 50 forms reduce to 31. The coordinate-level 100→62 construction remains valid without assuming that factorization.

What the quotient does not do

It does not turn the physical solve into ten unknowns. It removes only 38 of 3,524 columns. Its large benefits are:

the homogeneous frame shrinks from 48 to ten columns;

particular-plus-homogeneous output shrinks from 49 to 11 columns;

normalization need only constrain actual gauge freedom;

residue aliases no longer contaminate degree discovery.

2. First production algorithm: one factorization, many Taylor coefficients

Choose ten fixed gauge-coordinate conditions that are nonsingular on the ten-dimensional gauge-effective nullspace. Set those coordinates to zero and remove them from the quotient system.

Select 3,476 independent physical rows. This gives a square core

K(ϵ)∈F
ℓ
	​

(ϵ)
3476×3476
.

It defines one coherent rational section. It need not be a minimum-degree section—but you can compute it much more cheaply than the present fibre-by-fibre approach.

Build the core as a univariate epsilon problem

At the fixed kinematic points:

Reuse the compiled deferred-DAG/provider evaluation.

Specialize kinematics and root data once.

Retain the remaining rational dependence on ϵ.

Clear denominators row by row in K.

Keep the RHS’s regulator denominator separately if including it would unnecessarily increase the matrix degree.

Do not assume that the RHS is epsilon-free or has the same degree as the left matrix. That was the failed premise in the earlier CF300 polynomial-system experiment.

Also, do not form a global LCM across all kinematic points. Mixed kinematic/regulator denominators become different univariate polynomials at different points; multiplying all of them together recreates the degree problem.

Choose a regular expansion point ϵ
0
	​

, put z=ϵ−ϵ
0
	​

, and write

K(z)=K
0
	​

+K
1
	​

z+⋯+K
δ
	​

z
δ
,h(z)=
j≥0
∑
	​

h
j
	​

z
j
.

Factor only K
0
	​

. The solution coefficients satisfy

K
0
	​

x
j
	​

=h
j
	​

−
a=1
∑
min(δ,j)
	​

K
a
	​

x
j−a
	​

.
	​

(1)

Every subsequent coefficient requires matrix-vector products and triangular substitution, not another RREF or numerical factorization.

This is standard power-series/Dixon solving. It is distinct from high-order Newton lifting and from computing a polynomial kernel basis; practical implementations often favor Dixon-style lifting despite more sophisticated asymptotic alternatives. 
arXiv

Start with one RHS, not eleven

For the first pilot, compute one particular section. You need neither all 48 old null directions nor all ten effective ones to determine whether coordinatewise reconstruction becomes practical.

If section optimization later requires the ten homogeneous directions, the same recurrence supports eleven RHS columns:

X
j
	​

=K
0
−1
	​

	​

B
j
	​

−
a=1
∑
min(δ,j)
	​

K
a
	​

X
j−a
	​

	​

.

FLINT’s nmod_mat_lu, nmod_mat_solve_tril, and nmod_mat_solve_triu provide the reusable factorization and substitutions. No new linear-algebra backend is needed. 
Flint Library

Reconstruct coordinates separately

For each coordinate, recover

x
i
	​

(z)=
q
i
	​

(z)
p
i
	​

(z)
	​

,q
i
	​

(0)=1,

from its Taylor coefficients. Use extended-Euclidean Padé reconstruction, or Berlekamp–Massey with correct treatment of a possible polynomial part.

Do not combine the denominators q
i
	​

. FLINT already supplies streaming Berlekamp–Massey and univariate polynomial arithmetic. 
Flint Library

The failed bounded common-denominator test does not preclude this:

degq
i
	​

 small for each i

⇒deglcm
i
	​

q
i
	​

 small.

Conversely, Taylor lifting does not magically lower the degrees of a bad section. It makes reaching sufficiently high order affordable.

3. Why not eliminate the gauge block first?

Your ranks imply that eliminating the 3,424 gauge columns produces a residue system of shape

160×100,rank=52,

and, after quotienting the 38 relations,

160×62,rank=52,nullity=10.
	​


This is a valuable conceptual quotient, but do not symbolically construct it by inverting a 3,424-square polynomial matrix. That produces determinant-heavy Schur coefficients again.

A constant residue-first elimination is safer when available. If A
r
	​

=ϵA
r,0
	​

, eliminate the 62 residue directions using a constant 62-square minor. The resulting gauge-only system has

3522×3424,rank=3414,nullity=10.

However, if its row combinations mix many different epsilon denominators, leave the 62 residue coordinates in the core. Saving 62 dimensions is not worth producing a high-degree common denominator. The 3476-square original-row core is the robust default.

4. Use the ten-dimensional bundle for section optimization—not arbitrary repinning

Three failed fixed sections justify stopping the search for a lucky coordinate pinning. They do not prove that every rational representative has equally large coordinate degrees.

The completed fibres already permit a small bundle experiment without resampling.

After quotienting residues, select ten residue coordinates J whose projection is nonsingular on the effective homogeneous space. Normalize that projection to I
10
	​

, and normalize the particular solution to zero on J. Then

ρ
J
	​

=t,ρ
J
c
	​

=H
ρ
	​

(ϵ)t+p
ρ
	​

(ϵ),

where J
c
 has 52 coordinates. The nontrivial residue graph is therefore

Y(ϵ)=[H
ρ
	​

∣p
ρ
	​

]∈F
ℓ
	​

(ϵ)
52×11
.
	​


Apply the same change of affine parameters to the stored gauge values.

This is where a minimal interpolant/approximant basis or matrix-fraction representation becomes attractive:

X(ϵ)=N(ϵ)D(ϵ)
−1
,D:11×11,

for the full effective solution frame X=[H∣p]. Shifted minimal interpolation bases are designed for precisely these matrix rational-reconstruction and relation problems. 
arXiv

Two important limits

First: a compact denominator for the 52×11 residue graph need not clear the gauge coordinates. Gauge reconstruction must still use the original equations. Do not repeat the earlier mistake of assuming the eliminated residue frame contains the complete degree information.

Second: the common-denominator no-go still constrains matrix-fraction proposals. Append the affine tag

ℓ=(0,…,0,1).

If a full polynomial representation satisfies

(
X
ℓ
	​

)D=(
N
ℓD
	​

),

then any column with (ℓD)
j
	​


=0 yields an affine solution

x=
(ℓD)
j
	​

N
j
	​

	​

.

Thus a full numerator/denominator representation bounded by degree 16 would contradict your affine-bundle test. Matrix fractions avoid forming large scalar LCMs computationally; they cannot evade a genuine degree bound.

Use this reduced-bundle method if Taylor lifting exposes genuinely expensive sections. It is not a guaranteed low-degree escape.

5. Polynomial-kernel/Popov route: mathematically general, second-line computationally

After quotienting, the original augmented polynomial system is

[
A
g
	​

∣
A
r
	​

T∣−
b
]∈F
ℓ
	​

[ϵ]
3584×3487
,

with generic right-kernel dimension 11.

A shifted minimal right kernel basis is a correct general solution object. If a library computes left kernels, its input is the transpose,

3487×3584,

and the output has eleven rows.

But a kernel dimension of eleven does not mean that its computation costs the same as an eleven-square solve. General kernel algorithms still manipulate the roughly 3,500-dimensional input, often with substantial polynomial fill-in. FLINT’s basic polynomial nullspace is not generally reduced, and its fraction-free polynomial solve does not guarantee a minimal denominator. 
Flint Library

My ordering is therefore:

Route	Decision
Exact 38-dimensional residue quotient	Do now
Fixed-core Taylor recurrence plus separate Padé fractions	First physical recovery implementation
Reduced 11-column affine-frame interpolation/Popov reduction	Next if section degree remains the problem
Full shifted kernel basis of the original polynomial matrix	Fallback when smaller representation/lifting routes fail
Smith–McMillan form or repeated dense Toeplitz degree ladders	Not the next computation

PML is a suitable later reduced-basis engine. Its current version is 0.5; the NTL implementation and FLINT implementation have different dependencies, and the FLINT side requires FLINT 3.4 or later. It should not block a pilot on the existing FLINT installation. 
GitHub

6. Cost and a bounded next experiment

Let n=3476, let δ be the actual primitive matrix degree, and let

s=
a=1
∑
δ
	​

nnz(K
a
	​

).

For one RHS, the straightforward recurrence costs approximately

O(n
ω
)+O(L(n
2
+s))
	​


field operations for L Taylor coefficients. Storage is approximately

O(n
2
+s+nL).

The expensive factorization is paid once per prime. A dense 3476-square matrix contains about 12.1 million field elements—roughly 97 MB at eight bytes each—before polynomial coefficients and work buffers.

By contrast, the measured current route costs approximately

10.4+19.3=29.7 s

per newly solved fibre. Producing 128 such fibres would take about 63 minutes at that rate.

Smallest pilot

Reuse the 214-monomial support and completed fibres. Do not restart the live degree-32 run.

Build the fixed residue quotient and ten-coordinate gauge normalization.

At one prime, export the epsilon-polynomial core or its rowwise rational coefficient representation from the existing provider.

Factor K(ϵ
0
	​

) once.

Generate 32 Taylor coefficients of one particular solution.

If throughput is favorable, continue the same recurrence to orders 64, 128, then 256, attempting coordinatewise Padé reconstruction at each stage.

Use the measured first 32 coefficients to decide implementation viability:

Keep: extrapolated 128-term solve plus reconstruction is below roughly five minutes.

Reject the simple recurrence implementation: it is not at least several times faster than the corresponding fibre collection.

Escalate representation, not primes: if no useful coordinate degree profile stabilizes by order 256, use the stored effective bundle for minimal-interpolant/Popov analysis rather than starting another blind scalar degree ladder.

Those are engineering stopping thresholds, not nonexistence bounds.

If the matrix cannot be polynomialized at modest rowwise degree, use series arithmetic directly or block/high-order lifting. Do not force a global denominator just to obtain a polynomial matrix.

7. Normalization, physics, and acceptance

There is no evidence here that another root field or a new physical function class is required. The issue is rational dependence on ϵ in an underdetermined linear problem.

The only inexpensive regulator normalization worth applying immediately is an already identified common scalar factor of the forcing. If

F=q(ϵ)
F
,

then set

G=q(ϵ)
G
,M
a
	​

=q(ϵ)
M
a
	​

.

Because q is kinematics-independent, it factors through the strip differential operator. Restore it after reconstruction. Do not force polynomial or epsilon-independent residues when the family normalization has not yet been performed.

For acceptance, keep the current rule: eight fresh disjoint images across two primes, with generic regulator values, evaluating the actual source strip

F+ϵ(EG−GC)−dG−ϵ
a
∑
	​

M
a
	​

(ϵ)ω
a
	​

=0

in every grade and both differential components. That is the existing campaign policy, not a new layer. 

11_reconstruct_dont_simplify

 The evaluations use exact finite-field arithmetic; their identity-testing conclusion is probabilistic, not a symbolic characteristic-zero proof.

Bottom line

The 38/10 result is valuable because it identifies the correct reconstruction object: one particular solution plus ten gauge-changing directions, with the 38 zero-form residue directions removed.

For immediate wall-time reduction, however, the decisive change is:

one native factorization⟶Taylor recurrence⟶separate Pad
e
ˊ
 denominators
	​


rather than another sequence of full RREFs. Use reduced-bundle Popov/matrix-fraction methods to improve the section only if the fast series calculation shows that section complexity—not fibre generation—remains the dominant obstacle.
