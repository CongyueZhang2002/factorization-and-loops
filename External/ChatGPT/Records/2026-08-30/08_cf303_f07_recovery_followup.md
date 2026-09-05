# CF303 F07 Recovery Followup

## Question

Continue the existing “Assess Multiquadratic Pipeline” conversation. We now have a decisive new CF303 (25,18) result and want a concrete recovery algorithm, not another broad review.

At p=2147483423, for three regulator images eps={1,3/17,9}, the direct closed-target base system has 7200 rows, 7080 columns, rank 7076, and left-nullity 124. A cached cokernel projector tested the next alphabet divisors. The very first quadratic divisor succeeds:

  f7 = -2 + 2 x^2 + x y.

With gauge denominator Q_new = Q_old*f7, one added pole, and the quotient support excluding monomials divisible by the leading monomial x^2, the projected new columns span the entire 124-dimensional cokernel at numerator cutoff 15. There are 31 scalar residue blocks = 124 gauge-entry columns. For all three eps images, projected rank = projected augmented rank = 124, so the enlarged system is consistent. Cutoffs 0 through 14 remain defect one. The run took 7.7 s from the cached projector. Exact artifact:

/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_higher_pole_f07_projection.wl

Base/cokernel artifacts:

/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_direct_closedness_base_cokernel.wl
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_direct_closedness_base_cokernel.bin
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_rational_gauge_space_audit.wl

Please advise the smallest, robust way to recover the actual rational gauge rather than merely certify existence. In particular:

1. Can we solve only the 124x124 projected system for the 31 added residue blocks, then recover the base Q_old coefficients with the already-factorized base matrix, instead of refactoring the full 7200x7564 system?
2. What exact decomposition/back-substitution data should be persisted to make this a fast multi-prime, multi-eps reconstruction?
3. How should the 4-dimensional constant gauge freedom be normalized coherently across eps images?
4. What is the best finite-field reconstruction order: solve all eps images at each prime and interpolate in eps, or first CRT each coefficient at fixed eps?
5. Give a minimal unseen-point acceptance protocol consistent with our production policy: exact modular random-point identity checks, not a full symbolic residual.

Please be explicit about matrix blocks, equations, and failure modes. We are simultaneously running CF259 and cannot spend another Wolfram main kernel on a redundant full solve.

## Pro response

GO on projected recovery—but not yet on declaring the higher-pole gauge solved

Yes: solve the 124×124 projected system, then back-substitute with the existing base factorization. Do not refactor the enlarged matrix.

However, this checkpoint again lands exactly at sample saturation:

rank(A)=7076,rank(WC)=124⟹rank[A C]=7200.

Thus [A C] fits every RHS on the current 7,200 rows. The three epsilon successes are automatic once WC is invertible; they do not yet establish that f
7
	​

 supplies a functional solution.

The useful new fact is that you can now recover a unique candidate modulo the four constant matrices, cheaply. Testing that candidate at fresh points is the next decisive step.

1. Recover through the projected system and the old core

Keep the gauge in the split representation

G(x,y,ϵ)=
Q
old
	​

(x,y)
N
0
	​

(x,y,ϵ)
	​

+
Q
old
	​

(x,y)f
7
	​

(x,y)
R
15
	​

(x,y,ϵ)
	​

.
	​


Here N
0
	​

 uses the existing degree-58 support, and each entry of R
15
	​

 uses

{1,y,…,y
15
, x,xy,…,xy
14
},

the 31 standard monomials with total degree at most 15 and no x
2
 factor. These are gauge quotient coefficients, not target one-form residues.

Let

A∈F
ℓ
7200×7080
	​

,C∈F
ℓ
7200×124
	​

,

and write the sampled equations as

Ac+Cz=b(ϵ).

The present restricted model therefore has

7080+124=7204

columns. The 7564-column model corresponds to retaining the entire quadratic-divisor complement through degree 60; you do not need that larger space yet.

Let W∈F
ℓ
124×7200
	​

 be the complete cached left-cokernel basis:

WA=0.

Set

P=WC.

Since P is invertible,

z(ϵ)=P
−1
Wb(ϵ).
	​

(1)

Then solve

Ac(ϵ)=b(ϵ)−Cz(ϵ).
(2)

The right-hand side is guaranteed to lie in imA on the construction rows.

Back-substitution with an independent minor

Choose the fixed four normalization coordinates F, set c
F
	​

=0, and let J be the remaining 7,076 columns. Choose 7,076 independent rows I, with

K=A
I,J
	​

∈F
ℓ
7076×7076
	​


invertible. Then

c
J
	​

(ϵ)=K
−1
[b
I
	​

(ϵ)−C
I
	​

z(ϵ)],c
F
	​

=0.
	​

(3)

Use the cached factorization of K, not an explicit inverse.

Important storage distinction: a saved RREF[A] and the cokernel W alone do not provide the transformation of an arbitrary new RHS. You need LU/PLUQ factors, replayable row operations, or an equivalent solve operator. If those were not retained, factor this one base minor once—not the enlarged system.

FLINT’s LU and matrix-RHS triangular solves support precisely this reuse. 
Flint Library
+1

Batch the three available epsilon images immediately

With

B=[b(1)∣b(3/17)∣b(9)],

perform

Z=P
−1
WB,C
J
sol
	​

=K
−1
(B
I
	​

−C
I
	​

Z)

as two multi-RHS solves. No new elimination-plan discovery is needed.

2. What to persist

Retain mathematical solve data, not another full enlarged matrix.

Object	Purpose
Ordered base and 31-mode quotient supports; Q
old
	​

, f
7
	​

	Defines the two-piece gauge without ambiguity
Four constant-nullspace vectors and normalization coordinates F	Fixes the same affine representative everywhere
Independent row indices I, complementary rows, and columns J	Replays the base solve
LU/PLUQ factors and permutations for K	Back-substitution for every epsilon RHS
W, C
I
	​

, and factors of P=WC	Computes the higher-pole coefficients
Completed z(ϵ), c(ϵ), and partial epsilon/CRT reconstruction	Resumes without resampling completed fibres

All numerical factors are prime-specific. Reuse the support, row selection, and normalization semantics across primes, but not numerical W, LU factors, or P.

Efficient alternative when preparing a new prime

You need not recompute an explicit cokernel. Partition the rows into I and its 124-row complement R. Compute once:

T=K
−1
C
I
	​

,
S=C
R
	​

−A
R,J
	​

T.

Then for each epsilon image,

t=K
−1
b
I
	​

,
Sz=b
R
	​

−A
R,J
	​

t,c
J
	​

=t−Tz.
	​

(4)

This is the same projected solve in a canonical Schur-coordinate basis. Persist T and the factors of S. The 7076×124 matrix T is modest compared with the base factorization.

For the current prime, use the already available W. Do not compute T solely for three RHSs unless it is already available; its 124-column solve becomes worthwhile when preparing reusable prime state.

3. Normalize the four constant matrices—not a freshly selected modular nullspace

The exact homogeneous freedom is

G⟼G+H(ϵ),H∈Mat
2×2
	​

Q(ϵ).

In the split representation, this acts only through

N
0
	​

⟼N
0
	​

+Q
old
	​

H,R
15
	​

⟼R
15
	​

.

Therefore the cleanest normalization is the existing four base-coordinate conditions.

Let Z
0
	​

∈Q
7080×4
 contain the coefficient vectors of Q
old
	​

E
ab
	​

. Require

det(Z
0
	​

)
F
	​


=0,

then impose c
F
	​

=0 at every epsilon image and prime.

A convenient concrete choice is one fixed monomial with a nonzero coefficient in Q
old
	​

, applied to each of the four matrix entries. Alternatively, retain the already certified free-coordinate selection.

Do not:

rediscover normalization columns at every epsilon;

normalize the 124 added coefficients independently;

change normalization after combining f
7
	​

N
0
	​

+R
15
	​

;

reconstruct arbitrary RREF representatives from different primes.

Because WC is nonsingular, the enlarged sampled nullspace is exactly

ker[A C]={(c,0):c∈kerA}.

So these four conditions remove all sampled freedom.

4. Reconstruction order: epsilon within each prime, then CRT

Use all needed epsilon RHSs at one prime, interpolate there, then CRT/lift the resulting polynomial coefficients.

The closedness operator, Q
old
	​

, and f
7
	​

 are epsilon-independent in this campaign. Consequently,

A, C, K, P

are all epsilon-independent. Each prime needs one base factorization and one small projected factorization.

This is importantly simpler than the earlier CF300 epsilon-dependent Schur problem: the present inversions introduce no new epsilon poles. Every reconstructed coordinate is a constant linear combination of entries of b(ϵ).

Exploit a known regulator denominator when available

If the forcing supplies a compact common denominator h(ϵ) such that

h(ϵ)b(ϵ)=
j=0
∑
d
	​

b
j
	​

ϵ
j
,

then

h(ϵ)z(ϵ),h(ϵ)c(ϵ)

are polynomials of degree at most d. You may either:

solve d+1 regulator fibres and polynomial-interpolate; or

interpolate the RHS first and apply (1)–(3) directly to its coefficient columns b
j
	​

.

The second ordering avoids separately rediscovering rational denominators for thousands of gauge coefficients.

If no compact h is available, reuse the existing rational-in-epsilon interpolation. Fix one denominator normalization per reconstructed coordinate, interpolate over each prime, and CRT the coefficient arrays—not unrelated rational values at fixed epsilon. This follows the established finite-field functional-reconstruction organization. 
arXiv

Three epsilon images are enough for the immediate recovery pilot, but not a general reconstruction unless the actual regulator degree bounds make them sufficient.

5. Minimal fresh-point test—and why it comes before CRT

The rank-124 projection has saturated the original cokernel. Do the first back-substitution now, then test fresh points before spending on additional primes.

At a new point, form only

A
∗
	​

,C
∗
	​

,b
∗
	​

(ϵ)

or evaluate the candidate gauge directly through the existing closedness evaluator. Require

A
∗
	​

c(ϵ)+C
∗
	​

z(ϵ)−b
∗
	​

(ϵ)=0.
	​

(5)

There is no new factorization.

Since the candidate on the original rows is unique modulo constants, and constants are annihilated by the closedness operator:

A nonzero residual at even one admissible fresh point rejects this entire restricted 31-mode extension at that modular image. Re-normalizing the four constants cannot fix it.

One added point supplies four new constraints. A short stream of fresh points is therefore the cheapest way to distinguish a real higher-pole solution from the same interpolation saturation encountered previously.

If this passes, finish reconstruction and use the existing production rule: eight fresh disjoint images distributed over two primes, with regulator values not used for reconstruction and all evaluated denominators nonzero. That is already the stated campaign acceptance policy; no symbolic residual or additional acceptance layer is needed. 

11_reconstruct_dont_simplify

Check the reconstructed gauge against the actual equation

E
x
	​

∂
y
	​

G−E
y
	​

∂
x
	​

G+∂
x
	​

GC
y
	​

−∂
y
	​

GC
x
	​

=
ϵ
∂
x
	​

F
y
	​

−∂
y
	​

F
x
	​

	​

,

not merely against an interpolated training RHS.

A pass certifies, under that modular policy, a rational gauge making

T
G
	​

=F+ϵ(EG−GC)−dG

closed. It does not by itself establish that T
G
	​

/ϵ is epsilon-independent or that the result is strict dlog canonical form. Those remain the corresponding downstream target/family conditions.

Immediate execution sequence

Factor the existing 124×124 P=WC.

Recover z and back-substitute c for the three available epsilon RHSs.

Test the resulting candidates at fresh points before CRT.

If they pass, freeze the constant-matrix normalization and reuse the same native solve objects for all remaining epsilon images.

At each additional prime, factor only the base minor and the 124-square Schur block; never build or refactor the full 7,564-column model.

Interpolate in epsilon, CRT/lift, and apply the existing fresh-image acceptance.

The next action is a small projected solve plus base back-substitution, not another rank test. The critical acceptance question is whether its uniquely recovered candidate survives new kinematic points.
