# CF303 Laurent Deck Followup

## Question

# CF303 follow-up: six-prime lift failed; decide the finite Laurent-deck route

Please continue the established **Assess Multiquadratic Pipeline** conversation and give a decisive mathematical/algorithmic recommendation. Do not reopen the joint-chart question and do not recommend a giant symbolic check.

## New physical evidence

We replaced the full 681,378-sheet prime campaign by a targeted selected-sheet numerator campaign: 84 path images, nine regulator images, 64/62 `u` images, 96,768 selected evaluations per prime. Each additional 61-bit prime costs about 148 seconds on 16 CPU cores; FLINT interpolation itself is below one second.

The rational numerator coefficients nevertheless have enormous height. Using a disjoint next prime as an oracle, the number of uniquely selected EEA convergents among 66,381 coefficients is:

| construction modulus | uniquely recovered |
|---|---:|
| q1 (61 bits) | 1,395 |
| q1 q2 (122 bits) | 1,480 |
| q1 q2 q3 (183 bits) | 2,114 |
| q1 ... q4 (244 bits) | 2,651 |
| q1 ... q5 (305 bits) | 4,794 |

All missing cases have zero matching EEA convergents, not ambiguity. Fresh-prime functional tests show the same clean split every time: all 140 denominator coordinates and all 22 elliptic dynamic coordinates pass, while exactly the 126 rational primitive/remainder numerator coordinates fail. The evaluator, sheet projection, Hermite reduction, and targeted-prime layout are therefore not the defect. Naive 8--85 dimensional profile LLL is not attractive; one 85-dimensional SymPy LLL took 26.6 seconds and did not expose a short scale.

We have stopped accumulating full targeted primes. q7 and later are reserved for pointwise validation unless you identify a strong bound proving one last construction image sufficient.

## Existing machinery we can reuse

- `flint_deferred_path_jet` already evaluates the deferred rank-3 DAG with selected-sheet truncated path jets.
- `PathTransportNative.wl` already isolates a requested finite epsilon-order window from modular images and exposes `EdgeSeries` / `DiagonalSeries` providers.
- The rational and quartic Hermite reducers already act over the finite field; the curve and Hermite pole basis are epsilon-independent.
- On the full 45x45 CF303 final row, epsilon orders `-3..7` through path order 8 took about 48--51 seconds at one prime, and a fresh-prime differential/basepoint acceptance passed 2,430 modular equalities.
- The analytic deliverable is the compact weighted GPL/eMPL operator through physical `epsilon^2`, not an all-orders rational-in-epsilon gauge.

There is a bookkeeping discrepancy that must be resolved from mathematics rather than prose. Your prior response used exception incoming minimum `-2`, source boundary through order 4, and possible incoming/path-gauge range through `+6`. The current full final-row order table contains ordinary order `-3` edges, while the accepted exception decks themselves appeared to start at `-2`. A newer goal note says path-gauge window `-3..4` and source boundary through 5, but that may have conflated the full row with the exception gauge. Please state the exact rule for deriving the required `H_n`, remainder, and source-boundary windows from the actual 90-entry order table and target order `epsilon^2`; do not simply choose one of those recorded ranges.

## Proposed route to assess

1. Compile/evaluate the deferred expression DAG over truncated Laurent-series scalars in epsilon (Newton inversion after extracting each denominator valuation), rather than evaluating at 9--20 nonzero epsilon images and reconstructing the global rational-in-epsilon function.
2. Produce only the epsilon coefficients actually demanded by the triangular path-gauge recurrence and physical convolution.
3. For each demanded epsilon order, apply the existing rational/quartic Hermite reduction over `F_q(p)`; reconstruct rational functions of path parameter `p` using the already known supports/factored denominators.
4. Lift those finite-deck coefficients to `Q` adaptively and accept them by 2--3 unused-prime, unused-`(p,u)` pointwise replays. No full validation-prime reconstruction and no symbolic equality.

Questions:

1. Is this the mathematically correct shortest exact route, or is there a cheaper exact representation that avoids the high global epsilon coefficient height?
2. Should the Laurent-series arithmetic live inside the packed deferred evaluator, or can the existing `PathTransportNative` epsilon interpolation be converted into exact Laurent extraction without retaining the same height pathology?
3. Give the exact window recurrence for `B_n`, `H_n`, source boundary orders, and target orders for `F25 = G25 + H L`, taking the full final-row versus exception-edge valuation distinction into account.
4. What is the best reconstruction object in `p`: coefficientwise rational functions with known factored denominators, a denominator-times-numerator primitive integer profile, or a factored/arithmetic-circuit representation?
5. Identify any hidden failure mode: epsilon-dependent curve/basis, pole-order growth under the gauge recurrence, basepoint subtraction, or cross terms `D H_{n-1} - H_{n-1} S`.
6. Give a concrete staged implementation and a go/no-go test that should finish in minutes before we commit to the full block.

We need an actionable answer aimed at finishing CF303 tonight, not a survey.

## Pro response

Verdict: GO on the finite Laurent deck; stop the all-orders coefficient lift

The required deliverable is finite in ϵ, so reconstructing complete rational functions of ϵ is unnecessary. But Laurent truncation is not guaranteed to reduce coefficient height. It can even increase denominator powers in p.

The smallest next step is therefore not another prime campaign or a new evaluator:

Expand the already reconstructed modular functions at q
1
	​

,…,q
6
	​

 into the demanded Laurent coefficients, then attempt to lift those coefficients offline.

That immediately tests whether the proposed change of reconstruction object removes the actual bottleneck. Keep the 140 accepted denominator coordinates and 22 elliptic coordinates; concentrate on the 126 failing rational profiles.

There is no evidence supporting “one last construction prime.” Keep q
7
	​

 and later available for the stated pointwise acceptance.

1. What the finite-deck route changes—and what it does not

At fixed p,u, write an exact rational DAG output as

f(ϵ)=ϵ
v
D(ϵ)
N(ϵ)
	​

,D(0)

=0.

Its Laurent coefficients are determined algebraically by finite series division. No rational reconstruction in ϵ is needed.

Moreover, with an epsilon-independent curve, pole basis, and fixed Hermite reduction convention,

[ϵ
n
]Hermite(f)=Hermite([ϵ
n
]f).

This is linear reduction of differentials in the same function field. The quartic reduction and integration-by-parts machinery already used by the campaign is appropriate for this coefficientwise construction. 
arXiv

Exploit the six existing modular images first

If the saved records contain the complete accepted rational functions over F
q
	​

(p)(ϵ), their Laurent expansion gives exactly the new reconstruction target. There is no reason to reevaluate the physical DAG to obtain those same coefficients.

For each of the 126 profiles:

extract its demanded Laurent coefficients modulo each existing q;

express those coefficients using the known factored p-denominators;

CRT/lift the finite coefficient deck;

submit a completed candidate to the existing unused-prime pointwise replay.

Alternatively, specialize the saved modular functions at the existing p points, perform cheap scalar series division there, and refit the resulting p-functions. This avoids symbolic arithmetic in F
q
	​

(p).

Height reduction is a hypothesis

For example,

a(p)+ϵ
1
	​

=
n≥0
∑
	​

a(p)
n+1
(−1)
n
	​

ϵ
n

shows that truncation can increase p-denominator degrees. A large rational prefactor independent of ϵ also retains its height at every order.

Thus:

finite truncation certainly removes unnecessary all-orders information;

it may remove the expensive normalization responsible for the failed lift;

it does not prove that the remaining coefficients fit inside six primes.

The offline conversion is the fastest way to distinguish these cases.

2. Derive the windows from entries and dependencies—not one global minimum

Use

dL=ϵSL,dF
25
	​

=ϵDF
25
	​

+BL,
F
25
	​

=G
25
	​

+HL,

and the normalized Hermite recursion

K
n
	​

H
n
	​

B
n
′
	​

	​

=B
n
	​

+DH
n−1
	​

−H
n−1
	​

S,
=Prim
0
	​

(K
n
	​

),
=K
n
	​

−dH
n
	​

,
	​

(1)

where Prim
0
	​

 subtracts the primitive’s value at u
0
	​

.

The four diagonal entries in the 90-entry table belong to ϵD. Do not include them in the incoming-edge valuation census.

A. Lower endpoint: full row versus primitive gauge

For each incoming entry, record

β
ij
	​

=ord
ϵ
	​

B
ij
	​

.

Separately record the first order with a nonzero normalized primitive:

π
ij
	​

=min{n:Prim
0
	​

(B
ij,n
	​

)

=0}.

These need not agree.

If ordinary order-−3 entries are already pure remainders, while all primitive-producing exceptions start at −2, then

B
min
′
	​

=−3,H
min
	​

=−2.
	​


Indeed, H
−3
	​

=0, while B
−3
′
	​

=B
−3
	​

. The cross terms in (1) raise the inherited gauge order by one; they cannot create H
−3
	​

 from H
−2
	​

.

If an ordinary order-−3 entry has a nonzero primitive, H must instead start at −3. An entry’s valuation alone does not establish whether its primitive vanishes.

B. Upper endpoint: use the lowest source order that actually reaches each column

Let

λ
j
	​

=ord
ϵ
	​

L
j
	​


for the source component multiplying column j, including all reachable source-boundary columns.

For canonical epsilon-linear L, this is obtained from the existing word operator:

λ
j
	​

=
b,w
e
j
T
	​

R
w
	​

B
b
	​


=0
	​

min
	​

(q
b
	​

+∣w∣).
(2)

Let t
i
	​

 be the highest canonical target order required in row i by the physical endpoint gauge. With T
25
	​

 beginning at order zero and physical output through order two, the usual value is t
i
	​

=2.

Then the required incoming and endpoint-gauge coefficients obey

B
ij,n
	​

, B
ij,n
′
	​

, H
ij,n
	​

are needed only throughn
max,ij
	​

=t
i
	​

−λ
j
	​

.
	​

(3)

For t
i
	​

=2:

Lowest source order λ
j
	​

	Required upper order for that column
0	2
−2	4
−4	6

This resolves the disputed upper limits:

H through +4 is sufficient only for columns with λ
j
	​

≥−2, after dependency closure.

H through +6 is needed where a source component beginning at −4 contributes.

Neither follows from the incoming valuation being −2 or −3.

Close these demands under (1):

D
ik
	​


=0:
S
kj
	​


=0:
	​

H
kj
	​

 is required through n
max,ij
	​

−1,
H
ik
	​

 is required through n
max,ij
	​

−1.
	​


This is a small support-and-integer-order calculation. A directly zero B
ij
	​

 does not justify omitting H
ij
	​

: the right action −HS can generate it.

C. Source-boundary upper orders

For a path containing endpoint-gauge order a, incoming order r, s source steps and t target-diagonal steps,

N=a+r+q+s+t.

Therefore

q≤2−a−r−s−t.
	​

(4)

The safe global consequences are:

full-row incoming minimum −3: source boundary orders through 5;

exception/primitive branch minimum −2: source boundary orders through 4.

Reachability may lower those bounds for individual boundary columns. It cannot increase them under the stated nonnegative endpoint-gauge orders and epsilon-linear source/target connections.

D. Target orders and recurrence initialization

For physical orders −4,…,2 and endpoint orders a=0,1,2, convolution formally requests canonical orders −6,…,2.

Nevertheless, the target recurrence must start at its actual lowest nonzero order, obtained from target boundary valuations and β
ij
	​

+λ
j
	​

, and propagate upward. One may discard orders below −4 only when they are genuinely zero—not because the output table starts at −4.

The supplied summaries do not determine every λ
j
	​

. Consequently they do not establish one numerical global H-window. Equations (1)–(4), applied to the actual entry table and source operator, determine it without ambiguity.

3. Put Laurent arithmetic inside the native evaluator

For future sampling, use valuation-aware epsilon jets inside flint_deferred_path_jet, keeping EdgeSeries and DiagonalSeries as the interface to transport.

Store each scalar as

ϵ
v
(a
0
	​

+a
1
	​

ϵ+⋯+a
L−1
	​

ϵ
L−1
),a
0
	​


=0.

Extract the valuation before inversion, then invert the unit series. FLINT already provides truncated multiplication and series inversion/division; its standard series-inversion routine requires an invertible constant coefficient. For these short windows, use its existing dispatcher rather than introducing a separate high-order algorithm. 
Flint Library

Truncation must be demand-aware

For a product fg required through order N, with valuations v
f
	​

,v
g
	​

,

f is needed through N−v
g
	​

,g through N−v
f
	​

.

A denominator with positive valuation can require internal coefficients above the final output cutoff. Truncating every DAG node to the same interval -3..7 is not sound.

Because the roots are epsilon-independent, their selected-sheet values and all purely kinematic DAG nodes are evaluated once per (q,p,u). Carry the epsilon arrays only through nodes that actually depend on epsilon.

Existing epsilon interpolation is not automatically Laurent extraction

There are two legitimate uses:

A fully reconstructed modular rational function can be expanded exactly at epsilon zero. Use this now on the six saved images.

A finite set of values at nonzero epsilon does not determine the Laurent coefficients unless sufficient rational degree information is retained.

Changing PathTransportNative to interpolate a short polynomial from those values would not be an exact replacement.

Also, the accepted path jet through order eight demonstrates the local transport machinery. It does not by itself reconstruct a global rational-in-u kernel or its eMPL decomposition. Continue using the rational/quartic kernel representation for that step.

4. Reconstruct in p without rebuilding the height problem

The preferred output is

c
n
	​

(p)=
s
n
	​

∏
α
	​

f
α
	​

(p)
e
α,n
	​

P
n
	​

(p)
	​

,

with known primitive factors f
α
	​

, explicit scalar content s
n
	​

, and numerator P
n
	​

. Do not force a monic expanded denominator and independently lift all resulting coefficient ratios.

At a fixed modular p, Hermite reduction is linear. Process all demanded epsilon coefficients as multiple RHSs against the same reduction map, grouped by their common finite pole budget. Do not perform the full reducer symbolically over F
q
	​

(p) at every step.

There is no need to relift the accepted denominator factors or elliptic coordinates.

If finite-deck heights remain enormous

The cheaper exact representation is an arithmetic circuit for the coefficient functions, retained inside the weighted GPL/eMPL operator.

It must be a circuit over the original exact rational inputs, with finite additions, multiplications, inversions and the fixed Hermite linear maps—not merely an oracle returning modular values. Such a circuit defines an exact element of the coefficient function field without expanding its huge polynomial numerator.

This fits the already chosen paper-facing automaton representation. The expensive rational coefficients need not be printed as expanded polynomials.

Do not spend another construction-prime campaign merely to flatten coefficient circuits whose inputs and arithmetic are already exact. First determine whether finite Laurent coefficients lift from the six existing primes; if not, retain circuit coefficients for the stubborn rational part.

5. Two important failure modes
Pole support may be fixed while multiplicity grows

Even with an epsilon-independent curve,

f(u,p)+ϵg(u,p)
1
	​

=
k≥0
∑
	​

f
k+1
(−g)
k
	​

ϵ
k

generates higher powers of f. Likewise, DH
n−1
	​

−H
n−1
	​

S can increase pole orders before reduction.

Therefore the finite deck can share a pole dictionary, but cannot blindly reuse the old multiplicities or the old 64/62-u-point interpolation bounds. Derive the finite-order denominator powers from the jet recurrence, then reuse or enlarge only the necessary univariate reconstruction.

Base-point normalization can enlarge the constant field in p

For the quartic supplied earlier in this conversation,

Y
0
	​

(p)
2
=P
4
	​

(p,1/2)=
16
256p
6
−544p
4
+448p
3
−351p
2
+164p+36
	​

.

This is not generically a square in Q(p). Thus, for a primitive A=a+bY,

A(u)−A(u
0
	​

)=a(u)+b(u)Y(u)−a(u
0
	​

)−b(u
0
	​

)Y
0
	​

(p).

Do not attempt to reconstruct a coefficient containing Y
0
	​

(p) as rational in p. Either retain the base-point term as an explicit evaluation of the lifted raw primitive, or carry Y
0
	​

 as a separate algebraic constant with rational coefficient channels.

This does not change the elliptic curve in the integration variable u. It changes the parameter-dependent constant field. The subsequent cross terms must use the normalized H, including that constant subtraction.

6. Smallest staged implementation
Stage 1 — lift-only experiment using work already completed

Choose one of the failing rational profiles, including its highest actually demanded epsilon coefficient, and:

expand it modulo q
1
	​

,…,q
6
	​

;

retain the known factored p-denominator rather than monic normalization;

attempt the finite-deck lift;

replay a completed candidate at unused (p,u) points modulo q
7
	​

.

This should require no physical DAG sampling. Put a two-minute pilot cap on this representative test.

Pass: the demanded finite coefficients recover and replay with the existing modulus. Apply the same conversion to all 126 profiles.

Failure: no candidate after the existing six-prime information, or rapid p-support growth. Do not infer that additional native jet sampling will solve the height problem. Move the stubborn coefficients to the exact circuit representation.

Stage 2 — native finite-deck production

For genuinely new evaluations:

derive the entrywise demand windows;

add epsilon jets to the packed DAG;

reconstruct all demanded u-kernels at each p together;

apply the fixed Hermite maps as multi-RHS reductions;

run (1) in increasing epsilon order;

reconstruct only the required p-coefficient functions.

The unresolved (25,1) correction can usually be isolated further. If S is block lower triangular and source block 1 is its first block, a correction supported in column block 1 remains there under right multiplication by S. Its recurrence is only

δK
n
	​

=δB
n
	​

+DδH
n−1
	​

−δH
n−1
	​

S
11
	​

.

Keep the accepted rest of the row fixed. There is no reason to reevaluate all 90 entries for each trial of the last coupling.

Stage 3 — acceptance at the finite-deck level

Use the existing unused-prime differential/base-point evaluator on the demanded Laurent coefficients.

Do not compare a truncated Laurent polynomial with the untruncated rational function at an arbitrary nonzero epsilon value. Their higher-order tails should differ. Compare coefficients in the appropriately truncated Laurent ring at fresh (p,u,q), then perform the final G+HL and T
25
	​

 convolution in the demand-complete windows.

The requested two or three unused-prime pointwise replays are sufficient under your stated production policy; no full validation-prime reconstruction is necessary.

Immediate decision

Stop all-orders epsilon lifting. First convert the six saved modular functions to the demanded finite deck offline.

Then:

If finite-deck lifting succeeds: finish the coefficient lift and existing acceptance.

If it does not: keep the finite deck, but represent the unresolved rational coefficients by exact arithmetic circuits rather than paying for expanded coefficient height.

For new evaluations: use packed, valuation-aware epsilon jets and multi-RHS Hermite reduction.

For order bookkeeping: full-row −3 edges imply boundary depth up to five; primitive exceptions beginning at −2 can still have H
min
	​

=−2. The upper H-order is 2−λ
j
	​

, not something determined by either of those minima.

That is the shortest route to the required reusable GPL/eMPL operator through physical ϵ
2
, without another uncontrolled prime campaign.
