# CF303 Exception Primitive IBP

## Question

# Continue the established “Assess Multiquadratic Pipeline” conversation

Please independently assess the shortest exact route from the current CF303 transport state to paper-facing GPL/eMPL coefficients. The attached Wolfram file is the current lazy final-layer engine. Do not recommend hashes, provenance machinery, or redundant validation; focus on the mathematics, the recurrence, and performance.

## New decisive evidence

The accepted block-25 deck used by the attached engine contained 76 entries (72 solved off-diagonal entries plus the 2x2 diagonal) and omitted exactly 14 entries from lower blocks `{1,2,11,14,18}`. We have now reconstructed those missing entries directly on the same two-parameter quartic path

`x=-a p`, `y=(1-a)(1-p)`, `a=(4p(1-p)-2u)/(u^2+4p(1-p))`,

with root images `{rho, a-p, 1+u a}` and `rho^2=P4/(4p^2-4p-u^2)^2`. Exact symbolic identities confirm all three roots, and block 2 has completed exact quotient/Hermite reduction.

For block 2, both entries are nonzero, both have rational epsilon tails of valuation `-2`, and both have **nonzero exact Hermite primitive parts**. Their remainders contain 32 GPL terms on 16 distinct epsilon-independent letters and no elliptic remainder letters. Thus the current fast `D...D B_r S...S` residue grammar is incomplete: it reads only `record[[4]]` and drops `record[[3]]` (the primitive pair).

The reusable Maple library already implements exact algebraic-pair arithmetic and the word-length-decreasing recursion. For `omega=dH+sum_l c_l kappa_l`,

`J(omega, empty)=H(u)-H(u0)+sum_l c_l G(l)`,

and for `w=l1 rest`,

`J(omega,w)=H(u)G(w)+sum_l c_l G(l,w)-J(H kappa_l1,rest)`.

It also handles subsequent target-diagonal propagation by applying the same reduction to the diagonal form times a pair-valued coefficient. The proposed implementation keeps the current residue-only fast path unchanged and adds a memoized primitive-correction branch keyed explicitly by `{epsilonOrder,boundaryOrder,wordID}`; IBP may change word length but not epsilon degree. Coefficients are stored as two sparse matrices `(rational,Y-part)`, not pair values inside `SparseArray`.

The accepted physical endpoint gauge is separately available as

`I_25 = T_25 F_25`, `T_25=sum_{a=0}^2 eps^a T25[a]`.

The intended final convolution is wordwise:

`C_phys[n,q,w] = sum_{a=0}^2 T25[a](u) C_can[n-a,q,w]`,

using quadratic-pair multiplication and retaining canonical boundary constants.

## Questions

1. Is the separate memoized primitive/IBP correction branch mathematically exact for the block-triangular final layer, including arbitrary sequences of target-diagonal letters before the incoming edge? State the invariant and epsilon grading precisely.
2. Is there a substantially simpler equivalent route—such as a path-only triangular gauge that absorbs the primitive parts—without merely moving the same recursive work into newly generated lower couplings? If so, give the exact transformed equations and say which route is likely faster here.
3. What is the smallest finite transition deck that Maple should precompile so Wolfram never performs symbolic Hermite reduction? We need coefficients only through target epsilon order 2, with incoming valuation -2 and the current finite source word operator.
4. Is the physical `T25` convolution above complete with canonical boundary constants, or does the base-point convention require an additional inverse-gauge transformation of boundary columns?
5. Your preceding audit warned that negative source gauges can require boundary orders 3--5 even when output stops at epsilon^2. Re-evaluate that warning for this final-layer recurrence and state exactly which boundary-order columns are required for complete coefficients at orders `-4..2`.
6. Identify any concrete correctness or asymptotic-performance defect in the attached implementation that must be fixed before adding the 14 entries. We want a compact sparse word table for the full result, not a giant expanded expression.

Please give a decisive recommendation and distinguish mandatory corrections from optional optimizations.

## Pro response

Verdict: CORRECT FIRST, then GO

The mixed GPL/eMPL direction is mathematically sound, and the shortest route is to keep the current residue-only engine unchanged and add an order-recursive primitive correction engine.

The correction must not represent dH as another ordinary letter. Two properties of the existing implementation cease to be valid once primitive parts are admitted:

epsilon degree can no longer be inferred from the final word length;

the language D⋯DB
r
	​

S⋯S is no longer closed, because integration by parts produces algebraic prefactors multiplying words and can replace one word by words of different lengths.

The attached code currently reads only record[[4]], constructs OffDiagonalResidues, and never consumes the primitive pair in record[[3]]. 

cf303_lazy_final_elliptic_trans…

 Its present one-incoming-edge grammar is explicitly residue-only. 

cf303_lazy_final_elliptic_trans…

1. Exact primitive correction, including arbitrary target-diagonal prefixes

Let the source subsystem satisfy

dJ
S
	​

=ϵA
S
	​

J
S
	​

,

and let the final two-dimensional block satisfy

dJ
T
	​

=ϵA
T
	​

J
T
	​

+
r
∑
	​

ϵ
r
B
r
	​

J
S
	​

,

with

A
T
	​

=
d
∑
	​

D
d
	​

κ
d
	​

,B
r
	​

=dH
r
	​

+Ω
r
	​

.

Here H
r
	​

 is a 2×N
S
	​

 matrix over the quartic function field

K=Q(p,u,Y),Y
2
=P
4
	​

(p,u),

and Ω
r
	​

 is the already supported remainder-kernel part.

Let X
n
fast
	​

 be the coefficient generated by the current residue-only route using Ω
r
	​

. The missing primitive contribution ΔX
n
	​

 obeys the triangular recurrence

dΔX
n
	​

=ϵA
T
	​

ΔX
n−1
	​

+
r
∑
	​

ϵ
r
dH
r
	​

J
S
	​

.
	​


At fixed epsilon order this is

dΔX
n
	​

=
d
∑
	​

D
d
	​

κ
d
	​

ΔX
n−1
	​

+
r
∑
	​

dH
r
	​

S
n−r
	​

,ΔX
n
	​

(u
0
	​

)=0,
	​

(1)

where S
m
	​

 is the already available source coefficient operator at order m.

This recurrence automatically includes any number of target-diagonal letters before the incoming edge. There is no need to enumerate those prefixes manually: each application of the first term in (1) performs one further target-diagonal propagation.

Exact integration operator

For a pair-valued differential

η=dA+
λ
∑
	​

c
λ
	​

κ
λ
	​

,

define

J(η,w)=∫
u
0
	​

u
	​

η(t)E(w;t),

where E(w;u) is a base-u
0
	​

 mixed GPL/eMPL word.

For the empty word,

J(η,∅)=A(u)−A(u
0
	​

)+
λ
∑
	​

c
λ
	​

E(λ;u).
	​

(2)

For w=ℓv,

J(η,ℓv)=A(u)E(ℓv;u)+
λ
∑
	​

c
λ
	​

E(λ,ℓ,v;u)−J(Aκ
ℓ
	​

,v).
	​

(3)

The omitted boundary term

−A(u
0
	​

)E(ℓv;u
0
	​

)

is zero for a nonempty word at the stated regular base point u
0
	​

=1/2. It should nevertheless remain part of the abstract implementation rule, because it is not zero for every possible regularization convention.

For a target-diagonal step acting on a term M(u)E(w;u),

∫
u
0
	​

u
	​

D
d
	​

κ
d
	​

ME(w)=D
d
	​

J(Mκ
d
	​

,w).

Thus (2)–(3) handle both:

the initial incoming exact differential dH
r
	​

;

all subsequent target-diagonal propagation of pair-valued coefficients.

The recursion terminates because the only recursive call in (3) replaces w=ℓv by its proper tail v. Repeated poles may recur inside the Hermite reduction, but the word length strictly decreases.

Precise state invariant

At every target order n, store

ΔX
n
	​

(u)=
w
∑
	​

[A
n,w
(0)
	​

(u)+Y(u)A
n,w
(1)
	​

(u)]E(w;u),

where A
n,w
(0)
	​

 and A
n,w
(1)
	​

 are sparse 2×N
boundary
	​

 matrices.

The invariant is:

ΔX
n
	​

(u
0
	​

)=0,

and

dΔX
n
	​

=
d
∑
	​

D
d
	​

κ
d
	​

ΔX
n−1
	​

+
r
∑
	​

dH
r
	​

S
n−r
	​


entrywise in the two-component basis {1,Y}.

That is the theorem-level recurrence.

Epsilon grading

For a contribution originating from:

source boundary order q;

a source word generated by s source-connection steps;

incoming coefficient order r;

t target-diagonal steps;

the epsilon order is

n=q+s+r+t.
	​

(4)

Integration by parts can change the displayed word length, but it does not change any of q,s,r,t. Therefore it does not change n.

This is the most important correction to the current implementation. The residue-only routine currently derives the incoming epsilon order from

order-boundaryOrder-(Length[word]-1),

which is valid only when there is one explicit incoming remainder letter and every other displayed letter represents one epsilon-linear source or target step. 

cf303_lazy_final_elliptic_trans…

 That formula must not be reused by the primitive branch.

Memoization key

The proposed key

{epsilonOrder, boundaryOrder, wordID}

is sufficient only if the memo table is additionally scoped to:

one fixed target order;

one fixed current algebraic primitive/pair state.

In the generic implementation it is incomplete. Different primitive matrices, or the same primitive after different target-diagonal reductions, can share those three values.

Use two memo tables:

HermiteTransition[{pairStateID, kernelID}]
IBPIntegral[{pairStateID, wordID}]

and index the order recurrence separately by targetOrder.

Equivalently, a complete contribution key is

{targetOrder, incomingOrder, boundaryOrder,
 pairStateID, sourceWordID}

with the remaining target-diagonal depth determined by (4).

2. A triangular path gauge is equivalent, but not simpler here

Set

J
T
	​

=
J
T
	​

+KJ
S
	​

.

Then

d
J
T
	​

=ϵA
T
	​

J
T
	​

+B
′
J
S
	​

,

where

B
′
=B−dK+ϵ(A
T
	​

K−KA
S
	​

).
	​

(5)

Choosing

K=
r
∑
	​

ϵ
r
H
r
	​


removes the original dH
r
	​

 pieces, but generates

ϵ(A
T
	​

H
r
	​

−H
r
	​

A
S
	​

)

at the next regulator order. Those new couplings must again be Hermite-reduced. Their exact parts require further terms in K, and the H
r
	​

A
S
	​

 term generally spreads the transformation into predecessor columns that were absent from the original 14-entry set.

Order by order,

B
r
′
	​

=B
r
	​

−dK
r
	​

+A
T
	​

K
r−1
	​

−K
r−1
	​

A
S
	​

.

A recursively chosen K
r
	​

 can make every B
r
′
	​

 residue-only along the path. This is mathematically legitimate, but it is essentially a matrix-level resummation of the same integration-by-parts recursion.

It also changes the boundary data:

J
T
	​

(u
0
	​

)=J
T
	​

(u
0
	​

)−K(u
0
	​

)J
S
	​

(u
0
	​

).

For this calculation, the direct primitive branch is likely faster because:

only 14 incoming entries are missing;

only two target rows are involved;

the required total depth is at most four or five;

the source word operator is already finite;

the direct branch touches only source words that actually contribute;

the path gauge can densify the 2×43 incoming matrix through KA
S
	​

.

Recommendation: do not introduce the path gauge first. It merely moves the same reductions into a larger transformed coupling deck.

3. Smallest finite Maple transition deck

Maple should not precompute all words. It should precompute a finite pair-kernel transition automaton.

For every reachable algebraic pair A
i
	​

(u) and every actual kernel κ
ℓ
	​

, store

A
i
	​

κ
ℓ
	​

=dA
j
	​

+
b
∑
	​

c
iℓb
	​

κ
b
	​

.
	​

(6)

The exported record needs:

PairState[i]             -> {A0_i(u), A1_i(u)}
BaseValue[i]             -> {A0_i(u0), A1_i(u0)}
Transition[{i,letter}]   -> {
    PrimitiveState -> j,
    RemainderTerms -> {{c1,label1},...}
}

The initial pair-state set is the set of nonzero scalar pair entries in all relevant H
r
	​

. Subsequent states are generated by (6).

The transition alphabet must include:

all source GPL/eMPL kernels that can occur as word heads;

all target-diagonal kernels;

all kernels generated by Hermite reduction;

the corrected quartic second-kind-at-infinity kernel if it arises recursively.

Even though the two block-2 remainders contain no elliptic remainder letters, products such as

H
r
	​

κ
ℓ
	​


can generate the holomorphic, third-kind, or second-kind elliptic kernels. The transition library must therefore use the complete quartic reduction basis, not only the letters present in the initial block-2 remainder.

Exact depth bound

For an incoming order r, source boundary order q, source-tail length s, and target-diagonal depth t,

s+t=n−r−q.

For target orders through n
max
	​

=2,

s+t≤2−r−q.
	​

(7)

Thus the deck should be generated from the actual source boundary keys and actual incoming orders, not from a rectangular global alphabet closure.

For the new block-2 entries:

r
min
	​

=−2.

If the relevant source boundary orders begin at q=0, then

s+t≤4.

So their primitive closure requires at most four nested transition steps.

The already accepted row contains incoming entries of order −3. Those retain a full-row maximum depth of five:

s+t≤5.

A breadth-first closure through these depths, restricted to actually reachable source word heads and nonzero target-diagonal residue transitions, is the smallest finite Maple deck.

Wolfram should perform only:

pair-state lookup;

sparse matrix multiplication;

word interning;

addition and merging.

No symbolic Hermite reduction should remain in Wolfram.

4. Physical T
25
	​

 convolution and boundary convention

The convolution

C
phys
	​

[n,q,w]=
a=0
∑
2
	​

T
25
(a)
	​

(u)C
can
	​

[n−a,q,w]
	​

(8)

is complete when the retained boundary columns are canonical boundary constants.

The product in (8) must use the quadratic-pair law. If

T=T
0
	​

+YT
1
	​

,C=C
0
	​

+YC
1
	​

,

then

TC=(T
0
	​

C
0
	​

+P
4
	​

T
1
	​

C
1
	​

)+Y(T
0
	​

C
1
	​

+T
1
	​

C
0
	​

).

No inverse target gauge is needed merely to express the physical result in terms of canonical constants.

At the base point,

I
25
	​

(u
0
	​

)=T
25
	​

(u
0
	​

)c
25
	​

,

where c
25
	​

 is the canonical target boundary vector.

If the paper instead parametrizes the result by physical target boundary constants b
25
	​

, then one must use

c
25
	​

(ϵ)=T
25
−1
	​

(u
0
	​

,ϵ)b
25
	​

(ϵ).

Equivalently, replace the target boundary selectors by

H
q
(25)
	​

=[ϵ
q
]T
25
−1
	​

(u
0
	​

,ϵ)
m
∑
	​

ϵ
m
b
25,m
	​

.

The current file explicitly appends identity target-boundary selectors only for orders 0,1,2. 

cf303_lazy_final_elliptic_trans…

 Those columns therefore represent canonical, not automatically physical, target constants.

5. Boundary orders required through physical order 2

There are two separate questions.

Canonical target orders required by T
25
	​


For physical orders

N=−4,…,2

and

T
25
	​

=
a=0
∑
2
	​

ϵ
a
T
25
(a)
	​

,

one formally needs canonical target orders

n=N−a,

hence

−6≤n≤2.

If the established canonical valuation is genuinely

F
25
(n)
	​

=0(n<−4),

then only

−4≤n≤2
	​


need be constructed. If TargetLow -> -4 is merely a truncation choice rather than a proven valuation, F
25
(−5)
	​

 and F
25
(−6)
	​

 are also required by T
25
(1,2)
	​

.

Source boundary orders feeding block 25

For any incoming record of order r,

n=q+r+s+t,s,t≥0.

Therefore a necessary upper bound is

q≤2−r.
	​

(9)

For the new block-2 entries with r
min
	​

=−2,

q≤4.
	​


Thus source boundary columns q=3,4 can be required, but q=5 cannot be required by those two new entries.

For the previously accepted entries with r
min
	​

=−3,

q≤5.
	​


Therefore the previous warning remains correct for the complete block-25 row:

source boundary orders 3,4,5 may still contribute through the pre-existing order-−3 entries;

the newly added block-2 entries only extend through order 4.

The exact required set is

Q
req
	​

={q∈Q
source
	​

:∃r,s,t,n with −4≤n≤2,n=q+r+s+t,},
	​


with s restricted to actually reachable source words and t to actually nonzero target-diagonal paths.

The target block’s own homogeneous boundary columns q=0,1,2 are sufficient for output through order two because every target-diagonal step raises epsilon order by one.

6. Mandatory implementation corrections and performance issues
Mandatory mathematical corrections
A. Consume record[[3]]

The builder currently constructs its labels and residues exclusively from record[[4]]. 

cf303_lazy_final_elliptic_trans…

 Add

OffDiagonalPrimitivesByOrder[r]
    -> {rational sparse matrix, Y-part sparse matrix}

assembled from record[[3]].

B. Do not infer epsilon degree from final word length

The current expression

epsilonOrder =
    order - boundaryOrder - (Length[word] - 1)

is not valid after IBP, because the displayed word may gain or lose letters while the regulator order stays unchanged. 

cf303_lazy_final_elliptic_trans…

 The primitive branch must be driven by recurrence order n, incoming order r, and counted source/target connection steps.

C. Extend the internal alphabet with transition-deck outputs

The current alphabet contains:

source letters;

remainder labels in record[[4]];

target-diagonal labels.

A recursive reduction Aκ
ℓ
	​

 can produce a kernel absent from all three sets. Every kernel returned by the Maple transition deck must receive an internal letter ID and paper-facing definition.

D. Include primitive base-point subtraction

Every primitive state must carry its value at u
0
	​

. Omitting

A(u
0
	​

)

gives the correct derivative but the wrong boundary normalization.

E. Use a complete cache key

At minimum include pairStateID and the current target order or remaining diagonal depth. The proposed triple alone can alias distinct primitive states.

Main asymptotic issue

The existing implementation first enumerates candidate target prefixes with

Wolfram Language
Tuples[diagonalIDs, diagonalLength]

and then evaluates candidate words individually. 

cf303_lazy_final_elliptic_trans…

 Do not copy that strategy into the primitive branch.

Use the order recurrence (1):

Delta[-4], Delta[-3], ..., Delta[2]

with each Delta[n] a sparse map

internalWordID -> {rational sparse matrix, Y-part sparse matrix}.

This explores only nonzero states and automatically merges identical words.

Do not globally materialize physical words

cf303FinalEllipticPhysicalWordTerms expands every composite letter into marked-point choices by Cartesian multiplication, and cf303FinalEllipticMaterializeCoefficient immediately sums the resulting expressions. 

cf303_lazy_final_elliptic_trans… +1

For the full paper result, retain:

{epsilonOrder, boundaryColumn, internalWordID}
    -> {rational coefficient, Y coefficient}

as the canonical output.

Expand composite labels only:

for a selected manuscript coefficient;

or while writing the ancillary word table.

Memoizing each individual composite-letter expansion is useful, but secondary to avoiding global Cartesian expansion.

Smallest implementation sequence

Extend transfer ingestion

collect the remainder terms from record[[4]] as before;

collect primitive pair matrices from record[[3]].

Generate the finite Maple transition deck

complete quartic Hermite basis;

actual source and target kernels only;

depth four for the new block-2 entries;

depth five for the complete existing row;

primitive base-point values included.

Implement the correction recurrence

dΔX
n
	​

=A
T
	​

ΔX
n−1
	​

+
r
∑
	​

dH
r
	​

S
n−r
	​


for n=−4,…,2, using explicit epsilon order rather than word length.

Merge

X
n
	​

=X
n
fast
	​

+ΔX
n
	​

.

Convolve with T
25
	​


using pair-matrix multiplication and canonical boundary columns.

Emit a compact sparse word table
and expand only selected paper-facing coefficients.

Final judgment
Item	Judgment
Separate primitive correction branch	GO
Encoding dH as another incoming letter	STOP
Epsilon order inferred from final word length	STOP for primitive terms
Memo key {r,q,wordID} alone	Insufficient unless narrowly scoped
Path-only triangular cleanup gauge	Exact but not shorter here
Maple transition deck	GO; finite depth 4 for block 2, 5 for the full row
T
25
	​

 convolution with canonical constants	Complete
Additional T
25
−1
	​

(u
0
	​

)	Only when converting to physical boundary constants
Full-row source boundary depth	Through q=5 because old entries reach r=−3
New block-2 source boundary depth	Through q=4
Full expanded GPL/eMPL expression	Avoid; retain sparse pair-word coefficients

The shortest exact route is therefore not a new general mixed-word solver. It is a seven-order pair-word correction recurrence, driven by a small precompiled quartic transition deck and added to the already working residue-only operator.

## Sources sent to Pro

- Original source reference: `../../../../factorization-and-loops-codex/Diagnostics/Scripts/cf303_lazy_final_elliptic_transport.wl` (not archived with this exchange)
