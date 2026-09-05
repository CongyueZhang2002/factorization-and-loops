# CF303 Closed Target Obstruction Followup

## Question

Continue the existing CF303 analysis. We have now run the decisive test you
recommended: eliminate the target altogether and ask only whether the
transformed off-diagonal one-form can be closed.

For CF303 block (25,18), in the rational Kallen chart, the current gauge ansatz
has denominator total degree 56 and the complete simplex numerator support
through total degree 58: 1,770 monomials per 2x2 gauge, hence 7,080 gauge
unknowns. At 1,800 generic kinematic points the closed-target equation

    E_x d_y G - E_y d_x G + d_x G C_y - d_y G C_x
      = (d_x F_y - d_y F_x)/eps

gave a 7,200 x 7,080 coefficient matrix. One coefficient-only FLINT RREF was
reused for eps = 1, 3/17, 9. In every image:

    rank(A) = 7,076, rank([A|b]) = 7,077, defect = 1.

There were no rejected points. Three independent sign/assembly oracles passed.
The native factorization took 8.4 s; the whole streamed test took 95 s. This
therefore rules out every dlog + dH target, and indeed every closed rational
target, in the entire current gauge space. It also resolves the ambiguity in
the earlier finite rational-potential searches.

The original strip contains one square root and is rational after the Kallen
chart. The current pole rule gives G one order below each forcing pole; its
finite divisor valuations and the degree-58 infinity cap were previously
called saturated/exhaustive. The new result makes the next decision about the
gauge ansatz, not the target basis.

Please give a concrete GO/NO-GO recommendation for the smallest next decisive
experiment:

1. Is the one-order-below-forcing pole rule actually exhaustive in the presence
   of resonant homogeneous solutions, or can a solution require extra powers
   on selected divisors even though the forcing has lower order?
2. Should we first add homogeneous numerator shells at infinity, raise selected
   divisor powers, or admit an algebraic gauge/target? Which is mathematically
   most plausible for this block?
3. Can the 124-dimensional left cokernel of the 7,200 x 7,080 system be used to
   localize the missing divisor/infinity modes cheaply? Give the exact projected
   rank test you would run before rebuilding a full larger solve.
4. State a bounded ansatz ladder (including proposed degree or pole increments)
   and a stopping rule. We want a solution, but do not want another open-ended
   enumeration of target forms.

Please distinguish what the present obstruction proves rigorously within the
declared support from what still depends on the claimed valuation bounds.

## Pro response

Verdict

GO on a bounded enlargement of the gauge space—not another target-form search. Start with the degree-59 and degree-60 numerator shells at infinity, screened by the local principal-part equations of the closedness operator. Then test at most one or two locally admissible finite-divisor pole increments.

NO-GO on a new algebraic cover or multiplying the denominator by all 16 factors.

The key correction is:

The one-order-below-forcing rule is exhaustive for the previous logarithmic target. It is not an established bound for the new problem of reaching an arbitrary closed rational target.

1. What the obstruction now proves

Define

L(G)=E
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

.

Your result excludes a solution of

L(G)=
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


in

V
0
	​

={
Q(x,y)
N(x,y,ϵ)
	​

:deg
x,y
	​

N≤58}
2×2
,degQ=56.

There is a useful strengthening of the negative certificate. The four constant 2×2 matrices lie in V
0
	​

 and are exactly annihilated by L. Therefore the characteristic-zero coefficient rank is at most

7080−4=7076.

Your modular rank reaches that upper bound, while the augmented rank is 7077. Provided the sampled matrix is a faithful reduction of the rational coefficient matrix, this proves inconsistency of the corresponding characteristic-zero sampled equations, not merely a probabilistic rank guess. Consequently no functional solution in V
0
	​

 exists.

What remains unproved is that V
0
	​

 exhausts rational solutions of the closedness equation.

2. The old pole theorem survives—but only for its original target

For the original strip equation with a logarithmic target,

dG−ϵ(EG−GC)=F−logarithmic form,

an excessive gauge pole G∼f
−m
H leads to

−mH−ϵE
f
	​

H+ϵHC
f
	​

=0.

Its determinant has nonzero constant term m
4
, so there is no generic resonance over Q(ϵ). Exceptional fixed regulator values do not invalidate that conclusion. This is the setting of the off-diagonal bound ord
f
	​

G≤ord
f
	​

F−1 in CANONICA. 
arXiv
+1

Thus the earlier argument was not missing a generic homogeneous resonance.

But after eliminating the target and requiring only dT
G
	​

=0, the governing operator is L, not d−ϵ(E⋅−⋅C). The identity term −mH is gone. Higher poles can now be balanced by the higher-pole closed target itself.

Calling the old bounds “saturated” for this new problem would therefore overstate what was proved.

Correct local principal-part equation

At a generic smooth point of a divisor, choose coordinates t=f, s, and write

E=E
f
	​

t
dt
	​

+E
s
	​

ds+O(t),C=C
f
	​

t
dt
	​

+C
s
	​

ds+O(t).

For

G=t
−m
H(s)+O(t
−m+1
),

the leading coefficient of E∧dG+dG∧C is

I
f,m
	​

(H)=E
f
	​

H
′
−H
′
C
f
	​

+m(E
s
	​

H−HC
s
	​

).
	​

(1)

This is a differential operator along the divisor, not a 4×4 algebraic matrix with determinant m
4
.

Use the restrictions of E
s
	​

,C
s
	​

 to t=0. At singular points, work at the generic point of the normalized component; intersections can be handled in subsequent Laurent coefficients.

Two cases must not be confused:

If the RHS has no term of order t
−m−1
, require I
f,m
	​

(H)=0.

If it does, solve the corresponding inhomogeneous equation.

In particular, the first pole increment can be needed to match the differentiated forcing. It need not arise from a homogeneous resonance.

Use the same calculation at infinity, with, for example,

t=1/x,s=y/x,

including the one-form Jacobian. Residues alone are insufficient; the tangential restrictions in (1) matter.

3. Which gauge enlargement should come first?
First: infinity orders three and four

The present space permits generic growth

G=O(x
2
)

at infinity because degN−degQ≤2. Test:

V
∞,1
	​

=
Q
P
≤59
	​

	​

,V
∞,2
	​

=
Q
P
≤60
	​

	​

.

These add only the homogeneous shells:

Enlargement	New scalar monomials	New gauge columns
Degree 59	60	240
Degree 60, beyond 59	61	244
Both shells	121	484

This is the cheapest controlled enlargement. It changes no finite pole order and directly addresses the infinity cap whose justification changed when the target class changed.

Before assembling all new columns, impose equation (1) on the candidate leading homogeneous numerator. Retain its admissible affine space, including a particular solution when the leading equation is inhomogeneous.

This ordering is computationally justified, not evidence that infinity is physically responsible. The current rank data cannot identify a particular finite divisor.

Second: only locally admissible finite-divisor increments

For a selected existing factor f of degree δ, test

V
f
	​

=
Qf
P
≤58+δ
	​

	​

.

This raises the pole order of f by one while preserving the original order-two infinity allowance. It contains V
0
	​

 through

N/Q=(fN)/(Qf).

Construct only a complement of fP
≤58
	​

, not the complete enlarged numerator space again. With a degree-compatible monomial order, standard monomials modulo f provide such a complement.

Before local pruning, the increments are:

degf	New scalar directions	New gauge columns
1	60	240
2	121	484
3	183	732

Equation (1), followed by the global cokernel test, decides which of these directions deserve a full solve.

Do not add an algebraic cover

A finite algebraic extension cannot be intrinsically necessary for this linear rational closedness problem. If G solves it in a finite extension L/K, then

G
ˉ
=
[L:K]
1
	​

Tr
L/K
	​

G

is rational and satisfies the same equation, because trace commutes with differentiation and the coefficients of L lie in K.

This does not imply that 
G
ˉ
 belongs to the present bounded support. It means that a cover is not the way to address an insufficient rational pole/degree ansatz.

4. Use the 124-dimensional cokernel—but not as another saturation trap

Let

A
0
	​

c=b,WA
0
	​

=0,

where W has 124 independent rows. For candidate gauge functions H
a
	​

, assemble

C
a
	​

=sample(L(H
a
	​

)),P=WC.

For each regulator image, the exact sampled extension test is

rankP=rank[P∣Wb].
	​

(2)

For all three RHS images together, test

rankP=rank[P∣Wb
1
	​

∣Wb
3/17
	​

∣Wb
9
	​

].

The extension coefficients may depend on ϵ; this does not require one coefficient vector to solve all three RHSs.

Use the full 124-row cokernel, not a single left witness. “Defect one” concerns one RHS; it does not make the cokernel one-dimensional.

A projected pass on the old points is not acceptance

The first infinity shell adds 240 columns. Its projection can have rank 124 and fit every old projected RHS. That would repeat the previous full-row-rank false positive.

Use the old cokernel for cheap rejection and localization, then append rows without rediscovering the original core.

Fix the four constant-gauge freedoms and choose the existing invertible 7076×7076 core A
I
	​

. For remaining or new rows R, eliminate the old coordinates:

(C
R
	​

−A
R
	​

A
I
−1
	​

C
I
	​

)θ=b
R
	​

−A
R
	​

A
I
−1
	​

b
I
	​

.
	​

(3)

This reuses the original factorization and converts every additional point into four more equations for only the new modes.

For the first two infinity shells, use 2,000 common points:

8,000 full equations;

7,564 gauge unknowns;

924 projected equations for the 484 new coordinates.

The same point count suffices for any single degree-≤3 divisor increment before local pruning.

A failed projected test rejects that candidate space immediately. A pass must survive the appended rows; do not discard projection-null directions prematurely, because they may be needed to satisfy those rows.

5. Bounded ladder and stopping rule
Stage 1 — infinity-only, no new denominator factors

Test degree 59, then degree 60, using:

the principal-part restrictions at infinity;

the common 2,000-point set;

equation (3);

all three available regulator RHSs.

If one passes, reconstruct there immediately. Do not continue enlarging.

Stage 2 — one extra copy on selected existing divisors

For each of the 16 divisors, examine equation (1) at the first excluded gauge pole order. This is the local discriminator, not a full gauge solve.

Project only the locally admissible modes. Test each useful divisor space separately and in combination with the degree-60 infinity space. An individual failure does not exclude a combination.

Stage 3 — one bounded joint attempt

Permit at most two total finite-pole increments, selected by the local equations and projected obstruction. They may be:

one extra copy on two divisors; or

two copies on one divisor, only if its next local principal-part equation permits that order.

Keep the infinity allowance at four. The corresponding single-denominator space is

G=
Qf
i
	​

f
j
	​

N
	​

,degN≤60+degf
i
	​

+degf
j
	​

.
	​


For two cubic increments, the maximum numerator degree is 66:

4(
2
68
	​

)=9112

gauge unknowns. Use at least 2,300 points, giving 9,200 equations, or reduce this dimension through the local constraints before global sampling.

Including the joint denominator matters: a sum of separate one-divisor spaces need not contain all mixed-pole modes.

Stop after this bounded class

If all these spaces fail, stop numerator/pole enumeration. The conclusion is:

No closed rational target is reachable within the tested extension of the current gauge pole divisor and infinity order.

It is not a proof that no rational closed target exists anywhere. To claim that, derive pole bounds for L itself—through its local differential equations on divisor normalizations and its characteristic divisors—or change to a genuinely nonrational transformation method. Generalized epsilon-factorization methods can require additional functions, but a failed bounded rational search alone does not identify their class. 
arXiv

The closedness operator can also admit characteristic polar curves not present in the original forcing. Consequently, the old “only forcing denominator factors” theorem cannot silently be extended to unrestricted closed targets either. That is a later rational-PDE issue, not a reason to search arbitrary new curves tonight.

Immediate calculation

Run the degree-59/60 infinity-mode projection first, with the local infinity principal-part filter and appended-point Schur residual (3).

Keep the existing compiled evaluator and exact channel arithmetic; there is no reason to return to whole-expression normalization, whose cost the campaign has already isolated. 

codex_overnight_optimization_tr…

The decision is:

Pass after overdetermination: reconstruct the smallest successful enlarged gauge.

Fail: test only finite-divisor modes admitted by the new local operator (1).

No bounded success: stop calling the old valuation rules exhaustive for closed targets and move to rational-PDE pole analysis—not another alphabet or algebraic-cover search.
