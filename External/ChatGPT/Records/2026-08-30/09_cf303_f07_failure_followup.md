# CF303 F07 Failure Followup

## Question

Follow-up in the same “Assess Multiquadratic Pipeline” conversation: the fresh-point validation you correctly required rejected the 31-block f7 candidate.

The recovery system used exactly the projected basis at 1,805 new points:

- coefficient matrix 7220 x 7204,
- coefficient rank 7200, nullity 4,
- free columns {1730,3531,5332,7133},
- all three regulator RHS inconsistent.

We found the precise flaw in interpreting the earlier projection. The base matrix at the original 1,800 points was 7200 x 7080 with rank 7076, hence cokernel dimension exactly 124. The 31 scalar f7 blocks add exactly 31*4=124 columns and their projected rank was 124. Therefore the enlarged old-point matrix was row-full rank 7200 and every possible RHS was automatically consistent. It was a saturation witness, not evidence that cutoff 15 suffices globally. At 7,220 fresh rows, the same basis has rank 7,200 and leaves a 20-dimensional cokernel containing the surviving obstruction.

The complete one-added-f7-pole quotient shell has 121 scalar blocks / 484 columns. A direct overdetermined test would use 7,564 unknowns and 7,580 rows (1,895 points, margin 16), about a 459 MB request. Alternatively, we can build a more overdetermined base cokernel cache and project complete shells for f7..f16 cheaply.

Which next experiment gives the best mathematical discrimination per cost?

1. Directly solve the complete f7 one-pole shell at 7,580 x 7,564, then move to f8..f16 only if inconsistent.
2. Build a base projector with enough extra rows that its cokernel is larger than every early candidate shell, then screen all divisors/cutoffs before any full solve.
3. Skip single-divisor shells and test combinations or higher pole order because the persistent defect-one pattern suggests no single added divisor can fix it.

Please be concrete about how many extra base rows are needed to avoid another automatic saturation, and whether a full-rank projected candidate plus 16 residual rows is sufficient as the first reliable modular discriminator. Do not propose full symbolic verification; production acceptance is fresh random-point exact arithmetic modulo primes.

## Pro response

Choose option 2: extend one reusable base projector

Build a common 2,000-point base system, giving 8,000 rows, and screen the complete one-pole shells through its cokernel. Test the complete f
7
	​

 shell first; proceed to the other divisors only if it fails.

Option 1 is mathematically sound, but repeatedly factoring a roughly 7,600-column system wastes the existing base factorization. Option 3 is not justified: for any single RHS,

rank[A∣b]−rankA∈{0,1}.

A persistent defect of one therefore says nothing about whether one divisor, several divisors, or a higher pole order is needed.

1. How many rows are sufficient?

Let

n
0
	​

=7080,r
0
	​

=7076.

On m common equation rows, the base cokernel has dimension

ℓ
0
	​

=m−r
0
	​

.

If a candidate shell adds c columns, automatic saturation is excluded by

m−r
0
	​

>c.
	​


For a desired projected residual margin h, use

m≥r
0
	​

+c+h.
	​


The four exact constant-gauge directions explain the distinction between “rows minus columns” and the actual residual dimension.

Complete one-pole shell dimensions

For a divisor of degree δ, preserving the current infinity allowance gives

Q
old
	​

f
P
≤58+δ
	​

	​

.

Modulo the embedded old space fP
≤58
	​

, the added number of matrix coefficients is

c
δ
	​

=4[(
2
60+δ
	​

)−(
2
60
	​

)].

Thus:

Complete shell	Added columns c	Total unknowns	Rows with 16-row nominal overdetermination	Projected rows	Residual dimension if rankP=c
Quadratic divisor	484	7,564	7,580 = 1,895 points	504	20
Cubic divisor	732	7,812	7,828 = 1,957 points	752	20

Your proposed 7580×7564 complete-f
7
	​

 test is therefore genuinely overdetermined. It has 20, not 16, independent residual constraints when the added columns have full projected rank.

For exactly 16 projected residual rows, the minima are:

quadratic: 7576 rows, 1,894 points;

cubic: 7824 rows, 1,956 points.

Recommended common cache

Use

m=8000,ℓ
0
	​

=8000−7076=924.
	​


This covers every single quadratic or cubic shell from the previously established divisor census:

quadratic shell: at least 924−484=440 residual dimensions;

cubic shell: at least 924−732=192.

It requires 800 additional base rows, or 200 points, beyond the original 1,800-point cache. The difference from the minimum cubic setup is only 43 points.

Reuse suitable points from the recent 1,805-point recovery if their base-column data were retained. There is no reason to resample them.

2. Extend the projector without refactoring the base

Fix the four constant-gauge normalizations. Let J denote the remaining 7,076 base columns and I a set of 7,076 independent rows. Retain

K=A
I,J
	​

.

Let R denote the other 924 rows of the enlarged common point set. Compute

L=A
R,J
	​

K
−1

through the transposed multi-RHS solve

K
T
L
T
=A
R,J
T
	​

,

not by forming K
−1
.

For each candidate shell matrix C
f
	​

, form only

P
f
	​

=C
f,R
	​

−LC
f,I
	​

,
	​


and for each regulator RHS,

d
ϵ
	​

=b
ϵ,R
	​

−Lb
ϵ,I
	​

.
	​


The full sampled system is consistent precisely when

P
f
	​

z=d
ϵ
	​


is consistent. This is ordinary exact block elimination. FLINT’s reusable triangular and matrix-RHS solves support this organization. 
Flint Library

The substantial base work is performed once. Each divisor subsequently requires:

evaluation of its additional gauge columns;

the projected matrix product;

elimination of at most a 924×732 matrix.

If the existing cache already contains a usable projector, append the new-row residual operator rather than rebuilding its original 124 rows. If no replayable base solve was retained, factor K once; do not factor a new enlarged system for each divisor.

3. Screen complete shells, not successive saturation cutoffs

For f
7
	​

, assemble the complete 121-scalar-block complement immediately. Do not resume cutoff 16,17,… as separate sampling campaigns.

On the 8,000 common rows, compute

r
f
	​

=rankP
f
	​


and test all three regulator RHSs together:

rank[
P
f
	​

	​

d
1
	​

	​

d
3/17
	​

	​

d
9
	​

	​

]=r
f
	​

.
	​


The three solution vectors may differ; their coefficients are allowed to depend on ϵ.

Failure: rejects the complete f
7
	​

 one-pole space at that modular image, including every smaller cutoff.

Success: recover a gauge by projected solve and base back-substitution. Stop screening unrelated divisors and use the existing reconstruction/fresh-point acceptance.

Rank-deficient P
f
	​

: retain its affine solution space. Do not mistake its extra kernel for a failure or arbitrarily discard it before subsequent equations are imposed.

If the full shell passes, lower cutoffs can then be tested by restricting columns of the already assembled P
f
	​

. That is inexpensive and can locate a smaller successful support without another sampler run.

If it fails, reuse L and the same point set for the complete shells of f
8
	​

,…,f
16
	​

. No full 7,000-column refactorization is needed.

4. Is a 16-row residual margin enough?

Yes—as a first nonvacuous modular discriminator. It is fundamentally different from the old square 124×124 projection:

old projection: every RHS was solvable;

overdetermined projection: consistency imposes genuine equations on the RHS.

But it remains sampled evidence, not a functional identity theorem. Moreover, four equations at one kinematic point are correlated evaluations; 16 residual rows should not be advertised as 16 independent random-point tests or as an automatic ℓ
−16
 error probability.

A positive 7580×7564 result would justify recovering a candidate and applying the existing fresh-point protocol. It would not justify calling the strip solved from the rank result alone.

For this campaign, the 8,000-row common cache is preferable because you expect to test multiple shells. It substantially increases discrimination while sharing all expensive base elimination.

Immediate sequence

Extend the original base cache to 2,000 common points, avoiding zeros of the candidate divisors.

Build the reusable 924-row residual operator with the existing base factorization.

Project the complete f
7
	​

 shell: 924×484, with the three regulator RHSs.

If inconsistent, project the other complete single-divisor shells using the same cache.

At the first surviving shell, recover the gauge and proceed to the existing independent random-point acceptance—not another existence-only rank report.

Do not skip to combinations based on defect one. Consider combinations only after the complete single-divisor spaces have been rejected. Before doing so, increase the common row budget according to the actual dimension of that combined candidate space; the 8,000-row cache is deliberately sized for single-divisor shells, not an unrestricted union of them.
