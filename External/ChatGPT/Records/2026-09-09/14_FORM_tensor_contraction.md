# FORM BMHV tensor contraction

Verified model: gpt-6-pro; standard reasoning; request 8da1bbbf-f809-41eb-9e2b-f6f7520b1306; HTTP 200.

## Question

Continue review of our exact BMHV FORM implementation in FeynFacet (https://github.com/CongyueZhang2002/factorization-and-loops; current changes uncommitted). Native grade-four identity passes 57 algebra checks and 12 NLO comparisons, but LL SIDIS q->qgg still very slow. I want concrete algebra/performance review, not another long brute-force run.

Input: 64 trace words of 8,10,12 ordinary D-dimensional gammas plus one gamma5, current E4(mu,nu,p,q), physical unobserved-gluon projectors, propagator scalar factors kept opaque. p,q physical, k1,k2,k3 full D. Shifted slashes now aliased vectors until final scalar contraction. Ordinary trace evaluation of grade-four complement is <1s; physical-projector/epsilon contraction and expanding alias scalar products dominates minutes. Open traces cause huge uncanceled intermediates. We now test contraction before trace and sort before alias expansion; also Hide old Local traces, avoiding reprocessing them.

Native representation presently fT5/fPick4/fRest CFunctions. fT5 holds cyclic word with gamma5 last, then distrib_(-1,4,fPick4,fRest), E4(selected), g_(1,rest), tracen. Is declaring these as nonsymmetric FORM Tensors (instead of CFunctions) the appropriate exact way to let external d_(mu,nu) and vector components contract gamma-word indices before subset expansion? Tensor multilinearity should be exact, with vector aliases retained.

Can reduce repeated D-index gamma pairs inside the gamma5-last word before subset expansion:
gamma_mu A1...An gamma^mu =
(-1)^n D A1...An + 2 sum_{j=1}^n (-1)^(j-1) A1...A_(j-1) A_(j+1)...An Aj.
No gamma5 crosses this subword. Is this identity/order correct for arbitrary D/physical/evanescent Ai represented as ambient projected vectors? Repeated index must be full-D and occur exactly twice overall.

Also propose epsilon contraction rules for shared summed indices before generic -det P4:
E4(i,j,k,a)E4(i,j,k,b)=-6 P4(a,b),
E4(i,j,a,b)E4(i,j,c,d)=-2(P4(a,c)P4(b,d)-P4(a,d)P4(b,c)),
one shared index -> minus 3x3 determinant. Restrict shared variables to genuine Lorentz indices, not repeated vector arguments. Any sign/dimension traps? Please prioritize algorithm that is general and keeps all evanescent terms. Do not suggest 4D numerators plus manually restoring rational terms.

## Pro response

Yes: nonsymmetric commuting Tensors are the appropriate representation for the Lorentz slots of these trace words. Your repeated-index gamma identity and the proposed epsilon shortcuts are also correct. The main corrections are that d_ can already contract exposed CFunction indices, and that a pair joined through P
4
	​

 must not be reduced with a full-D sandwich rule.

Given your profile, the priority is now reducing the tensor contraction before producing an expanded trace, not changing the trace algorithm again.

1. Change the word containers to tensors—but retain their types and ordering

At the declaration level, use

form
Symbols D;
Dimension D;
Indices mu,nu,rho,sigma;
Vectors p,q,k1,k2,k3;
Tensors fT5,fPick4,fRest;
Tensor P4(symmetric),E4(antisymmetric);

Tensors are commuting by default. Their slots are Lorentz indices or vectors, with a vector argument interpreted as a contracted index. This supplies the multilinearity you need. Nonsymmetric refers to argument order; it does not require NTensors. Do not declare the gamma-word heads symmetric or cyclically symmetric. 
Form Dev

Thus the following contractions are valid before grade-four expansion:

g
μν
	​

T
5
	​

(…,μ,…,ν,…)=T
5
	​

(…,α,…,α,…),
v
μ
	​

T
5
	​

(…,μ,…)=T
5
	​

(…,v,…).

The same applies to the selected and remaining argument containers.

What this change does—and does not—fix

d_ already contracts direct, exposed index arguments of ordinary functions. It does not generally reach through a surrounding function-argument boundary. Consequently, the principal new benefit of tensors is correct vector-slot contraction and multilinearity, not the first introduction of metric contraction. Inspect nesting if d_ remains unexpectedly uncontracted. 
Form Dev

For example, keep

scalar label×T
5
	​

(μ,…)

at the top algebraic level, rather than hiding the tensor inside something equivalent to

TraceRecord(id,T
5
	​

(μ,…)).

Also keep trace IDs, spin-line IDs, and scalar coefficients outside tensor argument lists. A tensor slot is not a general metadata slot; a numerical argument can be interpreted as a fixed component rather than a spin-line label.

The tensor declaration does not itself evaluate

P
4
μν
	​

T
5
	​

(…,μ,…,ν,…)

or

E
4
μνpq
	​

T
5
	​

(…,μ,…,ν,…).

Those remain genuine tensor contractions requiring your algebraic rules.

Projected slots remain projected

For an integrated vector,

P
4
	​

(k,μ)T
5
	​

(…,μ,…)=T
5
	​

(…,
k
ˉ
,…),

not T
5
	​

(…,k,…).

Use declared projected-vector aliases with their exact mixed scalar-product table, or retain an explicit projector until it can be contracted. Do not serialize a projected slot as an ordinary unmarked ambient index. FeynCalc’s mixed-dimensional Pair objects distinguish precisely these cases. 
FeynCalc

Keep alias vectors unexpanded at this stage. Tensor multilinearity is mathematically correct, but explicitly substituting K=k
1
	​

+k
2
	​

 inside a long tensor word would activate the very distributive expansion you are trying to postpone.

2. Your repeated-index identity is correct, with exactly the stated order

Let each A
j
	​

 be one Clifford-linear object,

A
j
	​

=γ(a
j
	​

),

where a
j
	​

 can be full, physical, or evanescent. It need not be a physical vector.

Moving the leftmost γ
μ
	​

 through the ordered word gives

γ
μ
	​

A
1
	​

⋯A
n
	​

=(−1)
n
A
1
	​

⋯A
n
	​

γ
μ
	​

+2
j=1
∑
n
	​

(−1)
j−1
a
jμ
	​

A
1
	​

⋯
A
j
	​

⋯A
n
	​

.

Multiplying by γ
μ
 on the right therefore yields

γ
μ
	​

A
1
	​

⋯A
n
	​

γ
μ
=(−1)
n
DA
1
	​

⋯A
n
	​

+2
j=1
∑
n
	​

(−1)
j−1
A
1
	​

⋯
A
j
	​

⋯A
n
	​

A
j
	​

.
	​

(1)

The removed A
j
	​

 belongs at the right end, as you wrote. No gamma-five identity enters this derivation.

For n≥1, combine the j=n term with the first term:

γ
μ
	​

A
1
	​

⋯A
n
	​

γ
μ
=(−1)
n
(D−2)A
1
	​

⋯A
n
	​

+2
j=1
∑
n−1
	​

(−1)
j−1
A
1
	​

⋯
A
j
	​

⋯A
n
	​

A
j
	​

.
	​

(2)

This produces at most n words rather than n+1.

Useful short-gap specializations are

γ
μ
	​

γ
μ
γ
μ
	​

Aγ
μ
γ
μ
	​

ABγ
μ
γ
μ
	​

ABCγ
μ
	​

=D,
=(2−D)A,
=(D−4)AB+4(a⋅b)1,
=(4−D)ABC−2CBA.
	​

(3)

These are exact full-D identities, including when the arguments contain hatted components. The appearance of D−4 is not a four-dimensional approximation.

Scope guards

Apply (1) only when the contracted index is summed with the full metric, both endpoints belong to the same gamma word, and the index occurs nowhere else in the term. Each A
j
	​

 must be a single gamma-linear argument; scalar factors should already be outside the word.

Use the interval between the two positions in the gamma-five-last representation. Do not choose a shorter “cyclic interval” that crosses the implicit γ
5
	​

. Nor should the ordinary argument list be cyclically canonicalized while leaving γ
5
	​

 fixed.

The rule applies inside a larger trace:

T
5
	​

(U,μ,A
1
	​

,…,A
n
	​

,μ,V)

becomes the corresponding sum of

T
5
	​

(U,shortened word,V),

with U,V unchanged.

A useful exact extension for P
4
	​

-joined pairs

If the pair is contracted through a symmetric projector Q, the correct generalization is

Q
μν
	​

γ
μ
A
1
	​

⋯A
n
	​

γ
ν
=
	​

(−1)
n
tr(Q)A
1
	​

⋯A
n
	​

+2
j=1
∑
n
	​

(−1)
j−1
A
1
	​

⋯
A
j
	​

⋯A
n
	​

γ(Qa
j
	​

).
	​

	​

(4)

For Q=P
4
	​

, the trace is 4; for Q=H=g
D
	​

−P
4
	​

, it is D−4. Replacing D by 4 in (1) is insufficient: the moved argument must also become P
4
	​

a
j
	​

.

For example,

P
4,μν
	​

γ
μ
\slasheda
D
	​

γ
ν
=−4\slasheda
D
	​

+2\slashed
a
ˉ
=−2\slashed
a
ˉ
−4\slashed
a
^
.

This is an inexpensive way to reduce physical-projector links without prematurely expanding P
4
	​

=g
D
	​

−H. It preserves the BMHV split rather than replacing it by anticommuting gamma-five algebra. 
FeynCalc

Why doing this before distrib_ is worthwhile

A contracted pair removes two ordinary gamma positions before subset selection. Using your generic expansion counts:

Original length	Grade-four pairing count	Maximum after one full-D pair reduction using (2)
12	51,975	10×3,150=31,500
10	3,150	8×210=1,680
8	210	6×15=90

These are loose upper bounds; short-gap rules and sorting often reduce the branching further. They are not runtime predictions.

Choose adjacent pairs first, then the pair with the shortest eligible interior interval. Apply the short rules in (3) before the general rule. Avoid a pattern matcher that repeatedly enumerates every possible decomposition of the word when its positional data are already known.

3. The shared-index epsilon shortcuts are correct

With your real physical Minkowski epsilon tensor and

E
4
0123
	​

=+1,

the general identity is

E
4
i
1
	​

⋯i
r
	​

a
1
	​

⋯a
4−r
	​

	​

E
4,i
1
	​

⋯i
r
	​

b
1
	​

⋯b
4−r
	​

	​

=−r!det[P
4
a
u
	​

	​

b
v
	​

	​

]
u,v=1
4−r
	​

.
	​

(5)

It gives exactly

E
4
	​

(i,j,k,a)E
4
	​

(i,j,k,b)=−6P
4
	​

(a,b),

and

E
4
	​

(i,j,a,b)E
4
	​

(i,j,c,d)=−2[P
4
	​

(a,c)P
4
	​

(b,d)−P
4
	​

(a,d)P
4
	​

(b,c)].

With one shared index the result is minus a 3×3 determinant. With four, it is −24. There is no residual D-dependent factorial: the epsilons project the contracted indices into the rank-four physical space. FeynCalc explicitly distinguishes the physical result −24 from a full-D epsilon contraction. 
FeynCalc

Implement the contraction by shared-index count and parity

For each epsilon pair, identify their common summed index labels, move them to the front of both ordered argument lists, and retain the product of the two permutation signs. Then apply (5) to the remaining slots.

For example,

E
4
	​

(i,j,k,a)E
4
	​

(j,i,k,b)=+6P
4
	​

(a,b).

A rule that matches common indices without recording their relative order will have sign errors.

Apply the largest shared-index rule first:

r=4, 3, 2, 1,

and use the 4×4 determinant only when no contracted indices are shared. Simplify every resulting projector chain immediately.

Your restriction to genuine summed indices is essential. Repeated vector arguments are not shared Einstein sums. In particular,

E
4
	​

(p,q,a,b)E
4
	​

(p,q,c,d)

does not reduce to the two-shared-index rule: its dependence on the magnitude of p,q alone disproves that substitution. It remains a projected scalar-product determinant, perhaps simplifiable using the declared kinematics.

Also require that the shared dummy does not occur in a third factor. An occurrence inside an opaque definition counts: only genuinely Lorentz-scalar opaque coefficients are safe to ignore in the incidence check.

Do not invoke the native epsilon convention accidentally

Keep these as rules for your custom E4. Native FORM contract operates on e_ with its own convention; it is not an implementation of your custom physical-projector identity. 
Form Dev
 FeynCalc documents the phase difference between its default epsilon convention and FORM’s. 
FeynCalc

Similarly, if a connecting contraction is explicitly evanescent, HE
4
	​

=0. It is not a shared full-D contraction to which a nonzero factorial rule should be applied.

4. Recommended contraction schedule
Stage A: contract the actual tensor environment while the word is short

Do not first construct a reusable expanded open trace. Keep the actual current epsilon, polarization-projector terms, and vector components attached to the inert fT5 word.

At this stage:

Contract d_ and vector components into tensor slots.

Reduce P
4
2
	​

=P
4
	​

, H
2
=H, P
4
	​

H=0, P
4
	​

E
4
	​

=E
4
	​

, HE
4
	​

=0.

Keep shifted vectors aliased.

Eliminate eligible full-D repeated pairs using (2)–(3); use (4) for explicitly projected pairs when beneficial.

Sort the resulting shortened, unexpanded words. The goal is to combine them before each generates hundreds of selected quadruples.

Stage B: grade-four selection, cheap zeros, short traces

Use the verified distrib_ identity on the shortened tensor words. Convert fPick4 to E4 immediately, or emit E4 directly.

Before tracing the complement, eliminate epsilon terms containing a hatted selected argument or repeated physical arguments, and simplify any already shared epsilon indices. Keep the complement order unchanged.

Then evaluate the remaining ordinary trace. Your profile says this operation is already inexpensive; retain it rather than adding another trace evaluator.

Stage C: close the remaining Lorentz contractions without expanding aliases

After tracen, the resulting metrics expose additional common epsilon indices. Reapply the shared-index rules, then the smallest necessary determinant.

By the end of this stage there should be no open Lorentz indices and no unresolved projector chains. The result should be a polynomial in contractions of alias vectors:

S
D
	​

(A
i
	​

,A
j
	​

),S
4
	​

(A
i
	​

,A
j
	​

).

Sort here. An open-tensor expression and a closed scalar polynomial can differ enormously in cancellation opportunities, even when they represent the same trace.

Stage D: expand alias scalar products once

Let the canonical independent vectors be b
α
	​

, and declare each alias by

A
r
	​

=
α
∑
	​

L
rα
	​

b
α
	​

.

Precompute the two tables

S
D
	​

(A
r
	​

,A
s
	​

)=
α,β
∑
	​

L
rα
	​

L
sβ
	​

S
D
	​

(b
α
	​

,b
β
	​

),
	​

S
4
	​

(A
r
	​

,A
s
	​

)=
α,β
∑
	​

L
rα
	​

L
sβ
	​

S
4
	​

(b
α
	​

,b
β
	​

).
	​


Apply these tables to the closed, collected scalar result, not as component substitutions repeatedly during tensor contraction.

Canonicalize alias definitions so that two names representing the same vector—or opposite vectors—do not unnecessarily inhibit cancellations. This is a sparse linear-vector operation, not a large symbolic simplification.

For physical p,q, the two scalar-product tables coincide whenever one argument is physical. For integrated vectors, retain

S
4
	​

(k
i
	​

,k
j
	​

)=S
D
	​

(k
i
	​

,k
j
	​

)−H
ij
	​

.

Introduce the independent H
ij
	​

 polynomial and perform your joint angular average only after the complete scalar contraction. Do not turn an alias’s full-D on-shell square into a four-dimensional null relation.

A final sort after the scalar-table substitution is necessary: some cancellations become visible only when different aliases are expressed in the same invariant basis.

Keep contraction rules terminating and local

Each contraction pass should decrease a clear quantity: the number of explicit projector links, a repeated gamma pair, the number of epsilon tensors, or the number of alias scalar products awaiting conversion.

Avoid alternating representations such as H=g−P
4
	​

 and P
4
	​

=g−H, or expanding and rebuilding projected vectors in a repeat loop. Avoid exhaustive dummy renumbering on the large open tensors; FORM warns that exhaustive renumbering can involve factorial work. 
Form Dev

Your Hide correction is appropriate. Also ensure that per-trace processing does not reactivate already scalarized locals during the next trace’s contraction modules.

5. Small tests that isolate the proposed changes

These should precede another full RR run.

Tensor-container test. Verify that an external vector component enters the intended word slot, that an external metric joins two slots, and that a physical projector produces a projected slot rather than an unrestricted one. Run the metric example with both CFunction and Tensor containers; this distinguishes nesting failures from the expected multilinearity improvement.

Sandwich test. Compare the user’s rule, the short-gap rules, and the Q=P
4
	​

,H version against ordinary Clifford algebra with mixed arguments. I checked (1) and (4) using Gaussian-integer Clifford matrices in D=6,8, for word lengths 0–6 and full/physical/evanescent contractions: all 126 cases agreed exactly. These are small algebra checks, not a FORM performance benchmark.

A particularly discriminating chiral contraction uses

T
4
	​

=tr(
γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d
γ
5
	​

).

Then

g
μν
	​

tr(γ
μ
Γ
4
	​

γ
ν
γ
5
	​

)
P
4,μν
	​

tr(γ
μ
Γ
4
	​

γ
ν
γ
5
	​

)
H
μν
	​

tr(γ
μ
Γ
4
	​

γ
ν
γ
5
	​

)
	​

=(D−8)T
4
	​

,
=−4T
4
	​

,
=(D−4)T
4
	​

.
	​

	​


The last two must sum to the first. This catches precisely a projected-pair/full-D-pair confusion. Retain the existing 64ϵ
2
 test afterward.

Epsilon shortcut test. Compare each r=1,2,3,4 shortcut with the generic −detP
4
	​

 rule, including odd permutations of the shared labels. Include repeated-vector examples that must not trigger the shortcuts.

Scheduling test. On one short but nontrivial tensor expression, compare contract-first against trace-first while retaining symbolic D and independent full/physical scalar products. This should agree before angular averaging; a later average must not hide a contraction error.

Priority

The next production change should be:

tensor word containers→external contraction and repeated-pair reduction→grade-four selection and short traces→shared-index epsilon contraction→one scalar alias expansion.
	​


The highest-value distinction is not expanding an open trace that will immediately be contracted away. Your proposed identities support that reordering exactly. They retain all evanescent terms and require neither four-dimensional numerator replacement nor a later rational-term restoration.