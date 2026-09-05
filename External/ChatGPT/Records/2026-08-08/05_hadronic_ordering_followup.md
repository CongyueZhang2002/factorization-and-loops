# Hadronic Ordering Followup

## Question

We are continuing the same FACET analytic pp -> h X calculation. Please assess the measured NLO TT simplification-order experiment and criticize the planned exact comparison. The attached files are the active reduction and BMHV/Tarasov implementations, the TT card, and the representative TT benchmark log.

Project requirement: exact analytic Epsilon-, endpoint-, and distribution-dependent hard functions. Numerical data below are timing/size measurements only.

The hadronic card gives direct global-basis coordinates for Pa, Pb, Ph, nh, nhb, STvec, and SThvec in terms of xa, xb, zh, s, t, u, and azimuths. There are no eta or PhT intermediates. The physical chamber includes s>0, t<0, u<0, s+t+u>0, 0<xa,xb,zh<1, and real spin/angle variables.

The TT BMHV tensor reduction is now exact at rank one and rank two. Exact symbolic tests establish:
1. the rank-one projector identity;
2. the rank-two projector identity;
3. preservation of an original loop-free factor D;
4. the scalar r=0 denominator D-3;
5. the evanescent r=1 denominator D-1;
6. rejection of the wrong r=1 denominator D-3;
7. preservation of positive cut indices.

For the representative TT pair F1 C1, dimensional shift takes 63.78 s. The exact result has 9 GLIs, 14.76 MB in memory, and a 2.16 MB saved artifact. Applying the exact hadronic map takes 9.28 s and gives 5.95 MB. Simplifying additive terms separately takes 9.49 s and gives 311 kB. Simplifying each complete GLI coefficient takes 5.98 s and gives 16.7 kB with 9 additive terms. No xa, xb, zh or hadronic basis vectors remain in the hard coefficients.

The complete 25-pair TT run is still calculating the two difficult conjugate off-diagonal pairs F9 C10 and F10 C9. The other 23 are complete. After it finishes we will compare exactly:

A. target-first: sum equal target GLIs over all pairs; apply the hadronic map and complete-coefficient simplification to each target; apply the Kira map; simplify complete master coefficients;

B. pair-first: for each pair, apply the hadronic map and complete-coefficient simplification to each GLI coefficient; save compact pairs; then run Kira and simplify masters;

C. master-first: form exact target sums without coefficient simplification; apply the sparse Kira map; only then apply the hadronic map and complete-coefficient simplification to each master.

All three routes must reconstruct the same exact coefficients in the same master basis and yield hard coefficients free of xa, xb, zh. We will compare coefficient by coefficient after extracting the same certified common hard factor; no numerical point comparison will be accepted as proof.

Questions:

1. Given the measured TT behavior, which route is most likely to minimize intermediate expression growth, and why? Please distinguish algebraic cancellation before Kira from merely moving work between stages.

2. Is the proposed coefficient-wise exact comparison sufficient? State any additional branch, BMHV, cut, or tensor-basis checks needed so that equality of compact results proves that reordering did not change the analytic result.

3. Should F9 C10 and F10 C9 be calculated independently for this benchmark, or may one be obtained by a precisely defined conjugation operation after dimensional shift? If conjugation is safe, state exactly what is conjugated and what must remain unchanged (cuts, GLIs, Epsilon, kinematics, azimuthal phases, and causal data).

4. For later NNLO UU with 44,877 targets and 342 masters, what small, exact preliminary measurements should decide between A, B, and C without regenerating or globally loading enormous expressions? Avoid numerical-only methods.

Please focus on concrete analytic risks and an executable comparison design, not general workflow prose.

## Pro response

The comparison is well posed, but the three routes omit the most likely production optimum: pair-level physicalization and termwise cleanup, followed by complete target-level cleanup, Kira reduction, and complete master-level cleanup. The attached archive contains the active reduction, dimensional-shift implementation, TT card, and measured logs used below. 

hadronic_ordering_followup_2026…

1. Expected ordering of the three routes

Let

a
pα
	​

=P
p
	​

c
pα
	​


be the complete coefficient of canonical target G
α
	​

 from pair p, including the pair prefactor P
p
	​

. Let H denote the exact hadronic-coordinate map, R
αm
	​

 the Kira reduction,

G
α
	​

=
m
∑
	​

R
αm
	​

M
m
	​

,

and N[⋅] an exact normalization that returns an analytically identical expression in the declared physical chamber.

The three proposed routes are

K
m
(A)
	​

=N
m
	​

[
α
∑
	​

R
αm
	​

N
α
	​

[H(
p
∑
	​

a
pα
	​

)]],
K
m
(B)
	​

=N
m
	​

[
α
∑
	​

R
αm
	​

p
∑
	​

N
p
	​

[H(a
pα
	​

)]],

and

K
m
(C)
	​

=N
m
	​

[H(
α,p
∑
	​

R
αm
	​

a
pα
	​

)].

Because H is an exact algebra homomorphism and the Kira coefficients are independent of x
a
	​

,x
b
	​

,z
h
	​

 and of the hadronic basis vectors,

H(R
αm
	​

)=R
αm
	​

,

so all three expressions are analytically equal when every normalization step is an exact identity in the same chamber.

Which one minimizes expression growth?

For peak pre-Kira expression size, the likely ranking is

B<A≪C.
	​


The measured F1/C1 reduction,

14.76 MB⟶5.95 MB⟶311 kB⟶16.7 kB,

shows that the pair-local hadronic map and scalar simplification remove almost all of the coordinate and tensor representation overhead. Route B therefore writes and accumulates much smaller pair objects.

For total symbolic work, the likely ranking is different:

A or the hybrid below<B≪C.
	​


Route A exposes cancellations between different pairs before Kira. In particular, off-diagonal interference pairs can cancel imaginary or noncanonical radical pieces after they are added at fixed G
α
	​

. Route B does not lose those cancellations mathematically, but it pays for complete simplification once per pair before the cancellation is visible. Route C is the most dangerous because every large unsimplified target coefficient is multiplied into every master appearing in its Kira image. This duplicates its algebra before either pair-level or target-level cancellations have been exposed.

Recommended hybrid route D

The strongest design is

a
pα
	​

C
α
	​

K
m
	​

	​

 H 
	​

H(a
pα
	​

)
termwise exact cleanup
	​

a
pα
	​

,
=
p
∑
	​

a
pα
	​

complete-coefficient cleanup
	​

C
α
	​

,
=
α
∑
	​

R
αm
	​

C
α
	​

complete master cleanup
	​

K
m
	​

.
	​

	​


This keeps the cheap, very large pair-level compression—from 14.76 MB to 311 kB in the measured example—while delaying the more consequential whole-coefficient simplification until all pair contributions to a target have been added.

A bounded whole-pair cleanup may still be used opportunistically. If it reaches the exact 16.7 kB result quickly, save that result; on timeout, retain the exact termwise-normalized 311 kB result. The timeout must return the exact input, not a partially transformed expression.

Concrete issue in the active Reduction.wl

The current target path is not exactly route A as described. It:

maps each pair to representative GLIs;

multiplies by the pair PreFactor;

sums equal targets;

applies the hadronic map;

calls normalizeLinearCoefficientParts.

However, normalizeLinearCoefficientParts invokes parallelNormalizeCoefficients with its default mode "Terms". It does not subsequently simplify each complete target coefficient in mode "Whole".

Expose the mode:

Wolfram Language
normalizeLinearCoefficientParts[
    parts_Association,
    assumptions_,
    mode_: "Terms"
  ] := Module[{keys, normalized, remainder},

  keys = Keys[parts["Terms"]];
  normalized = parallelNormalizeCoefficients[
    Values[parts["Terms"]],
    assumptions,
    targetCoefficientSimplifyTimeLimit[],
    mode
  ];
  If[normalized === $Failed, Return[$Failed]];

  remainder = exactCoefficientNormalize[
    Lookup[parts, "Remainder", 0],
    assumptions
  ];
  If[remainder === $Failed, Return[$Failed]];

  <|
    "Terms" -> AssociationThread[keys, First[normalized]],
    "Remainder" -> remainder
  |>
];

For route A or D:

Wolfram Language
targetParts = normalizeLinearCoefficientParts[
  targetParts,
  assumptions,
  "Terms"
];

targetParts = normalizeLinearCoefficientParts[
  targetParts,
  assumptions,
  "Whole"
];

The second step should retain the termwise result exactly when its bounded whole-coefficient call expires.

For route B, simplify the full quantity P
p
	​

c
pα
	​

, not merely the coefficient extracted from result["Integrand"]. The current route multiplies result["PreFactor"] before target summation; a pair-first benchmark must preserve that convention.

Do not extract the supposed universal x
a
	​

,x
b
	​

,z
h
	​

 monomial separately for every pair. That factor is safest to certify after targets are summed, and authoritatively after master accumulation.

2. Exact route comparison

Coefficient-wise equality in a fixed master basis is the correct central test, but comparison only after stripping a common factor is insufficient. Two routes could choose compensating but different signs, radical branches, or normalization factors.

For each route, construct the complete map

K
(r)
={M
m
	​

↦K
m
(r)
	​

},r∈{A,B,C,D},

before extracting the common hard factor.

The acceptance criterion should be

K
m
(r)
	​

−K
m
(s)
	​

=0

for every master M
m
	​

, together with equality of the GLI-free remainder.

Then separately require equality after the common factor is removed:

K
m
(r)
	​

=F
TT
	​

H
m
(r)
	​

,H
m
(r)
	​

−H
m
(s)
	​

=0.
Required metadata and analytic checks
Same integral basis and cut data

Require identical:

Kira target and master lists;

Kira reduction fingerprint;

topology-equivalence rules;

propagator ordering after canonicalization;

cut indices;

positive-energy cut directions.

For every final master,

ν
c
	​

>0

must hold at every physical cut slot c. Equality of two expressions containing the same printed GLI name is not enough if their topology records or cut directions differ.

Same causal sector

For the tree-times-tree NLO calculation, the ordinary phase-space denominators may be treated as real only under the already established no-interior-zero and endpoint-meromorphy certificates. The route comparison should require the same causal classification record. Simplification ordering must not be allowed to change whether a denominator is regarded as an ordinary real denominator or as a branch-sensitive object.

Same BMHV data

Require identical values of:

Gamma5Scheme=BMHV,D=4−2ϵ,

the declared physical four-dimensional vector list, and the evanescent-zero declarations.

Each route must be free of:

SPE;

loop-dependent SP or SPD;

an independent D;

open Dirac or Lorentz tensors;

the temporary tensor-reduction dimension.

The seven tensor tests in the supplied log are appropriate upstream acceptance conditions, but the final route comparison should also verify that the dimensional-shift source fingerprint and analytic context are identical.

Fixed azimuthal basis

Do not compare arbitrary trigonometric forms directly. Reduce every result to one fixed basis before coefficient comparison. For example, use a Fourier-Laurent representation

z
a
	​

=e
iϕ
a
	​

,z
h
	​

=e
iϕ
h
	​

,

with

cosϕ=
2
z+z
−1
	​

,sinϕ=
2i
z−z
−1
	​

.

The TT coefficient then becomes a finite Laurent polynomial in z
a
	​

,z
h
	​

. Equality is checked harmonic by harmonic. This prevents a false difference between, for example,

cos(ϕ
a
	​

−ϕ
h
	​

)

and its expanded sine-cosine form.

Fixed distribution and color basis

The expected TT distribution structure should remain an exact atom,

h
1
	​

(x
a
	​

)f
1
	​

(x
b
	​

)H
1
	​

(z
h
	​

),

rather than being mixed with another distribution channel. Reduce all color factors to one declared basis before comparison.

Fixed branch canonicalizer

The active branch normalizer discovers half-integer rules from the expression presented to it. That can produce different syntactic rule lists for A, B, and C. For this comparison, generate one branch registry from the TT card and use it in all routes.

At minimum, it must contain certified positivity data for

s,−t,−u,x
a
	​

,x
b
	​

,z
h
	​

,−(x
b
	​

t+x
a
	​

u),

and every applied rule must satisfy

FullSimplify[lhs=rhs∣A
phys
	​

]=True.

The actual persisted assumptions must prove

0<x
a
	​

,x
b
	​

,z
h
	​

<1;

these inequalities are not written explicitly inside the displayed HadronicVariables["Assumptions"] block in the TT card, so the comparison should verify that the process normalizer has added them.

Exact zero test without one global Together

After the common branch, distribution, color, and azimuthal bases have been fixed, split each difference into analytic signatures,

Δ
m
	​

=
σ
∑
	​

S
σ
	​

R
m,σ
	​

(s,t,u,ϵ).

Then require

R
m,σ
	​

=0

for every (m,σ). Each R
m,σ
	​

 is a small rational block and can be tested by

Wolfram Language
exactRationalZeroQ[r_] :=
  TrueQ[Cancel[Together[r]] === 0];

or, for larger blocks, by denominator bucketing and exact polynomial cross-multiplication. This is not a numerical check.

A suitable route comparison is schematically:

Wolfram Language
compareRouteMaps[first_, second_, context_] := Module[
  {masters, differences, blocks},

  masters = Union[Keys[first], Keys[second]];

  differences = AssociationMap[
    Lookup[first, #, 0] - Lookup[second, #, 0] &,
    masters
  ];

  differences = canonicalizeWithFixedBranchRegistry[
    differences,
    context
  ];

  blocks = Map[
    coefficientSignatureBlocks[#, context] &,
    differences
  ];

  AllTrue[
    Flatten[Values /@ Values[blocks]],
    exactRationalZeroQ
  ]
];

Also compare each route against the original unsimplified sum, not only against another reordered route. Two routes sharing the same erroneous normalization could otherwise agree with one another.

3. F9/C10 and F10/C9

For the benchmark, calculate both independently.

They should satisfy a precise conjugation relation, but computing both is the strongest test of:

the new rank-one and rank-two TT tensor reduction;

pair ordering;

the amplitude/conjugate projectors;

topology mapping;

branch normalization;

off-diagonal cancellation.

Deriving one from the other during the benchmark would remove this independent check exactly where the calculation is most difficult.

After that relation has been established once, production may construct one from the other.

Let

P
9,10
	​

=
α
∑
	​

c
9,10;α
	​

G
9,10;α
	​

.

Define a certified propagator permutation and topology map

Π
9,10→10,9
	​

:G
9,10;α
	​

⟼G
10,9;π(α)
	​


that preserves the cut slots and their energy directions. Then the required relation is

P
10,9
	​

=Π
9,10→10,9
	​

[P
9,10
∗
	​

].
	​

What is conjugated

Conjugate:

explicit factors of i;

genuinely complex couplings, if any;

explicit phases such as e
iϕ
;

branch-sensitive analytic functions according to the declared physical chamber.

Under the TT card’s reality assumptions,

s,t,u,x
a
	​

,x
b
	​

,z
h
	​

,ϵ,S
T
	​

,S
Th
	​

,ϕ
a
	​

,ϕ
h
	​

,C
A
	​

,C
F
	​

,α
s
	​


remain unchanged. Therefore

cosϕ↦cosϕ,sinϕ↦sinϕ,e
iϕ
↦e
−iϕ
.

Treat ϵ as real:

ϵ
∗
=ϵ.
What remains unchanged

The physical cut distributions are real:

[θ(q
0
)δ(q
2
)]
∗
=θ(q
0
)δ(q
2
).

Hence:

cut momenta remain unchanged;

positive-energy cut directions remain unchanged;

cut powers remain unchanged;

the phase-space measure remains unchanged.

The GLI itself may be treated as real only because the ordinary shared denominators of this NLO process have already been certified as real meromorphic phase-space denominators. The topology map may permute its denominator indices, but it must not reverse a cut direction.

For a virtual correction, this statement would change: conjugation would exchange the +i0 and −i0 sectors. One could not simply leave the same GLI unchanged.

Causal and pair metadata

When constructing F10/C9 from F9/C10:

swap the forward and conjugate diagram identifiers;

swap any amplitude-side and conjugate-side provenance labels;

preserve shared phase-space classifications;

preserve cut data;

apply the certified GLI index permutation.

Conjugation is safest after all Dirac and tensor structures have been reduced to scalar coefficients. Do not attempt to obtain one pair from the other by merely applying Mathematica Conjugate to an unreduced fermion-chain expression.

Before using this production optimization, require the independently calculated result to obey the exact relation above coefficient by coefficient.

4. Small NNLO measurements

Use the existing 1,296 pair artifacts and the indexed Kira map. No dimensional-shift regeneration and no monolithic load are needed.

A. Build a metadata-only incidence index

Stream the pair files once and record, without retaining coefficients:

p⟼{α:c
pα
	​


=0},

together with:

pair file size;

number of GLIs;

coefficient byte counts;

number of additive terms;

topology class;

maximum Kira fan-out

f
α
	​

=#{m:R
αm
	​


=0}.

Build the reverse index

α⟼{p:c
pα
	​


=0}

and the master dependency index

m⟼{α:R
αm
	​


=0}.

This requires only one pair file or one Kira rule at a time.

B. Compare A, B, and D on complete target fibres

Select deterministic target fibres containing all pairs that contribute to a chosen target. Include:

the targets with the largest raw total bytes;

the targets with the largest number of contributing pairs;

the targets with the largest Kira fan-out;

several median-size targets;

targets from distinct topology classes.

For each selected α, calculate exactly:

C
α
(A)
	​

=N
whole
	​

[
p
∑
	​

H(a
pα
	​

)],
C
α
(B)
	​

=
p
∑
	​

N
whole
	​

[H(a
pα
	​

)],

and

C
α
(D)
	​

=N
whole
	​

[
p
∑
	​

N
terms
	​

[H(a
pα
	​

)]].

Require exact equality, then record:

wall time;

MaxMemoryUsed;

peak and final ByteCount;

additive-term count;

number of bounded simplification fallbacks;

serialized output size.

Do not benchmark an incomplete subset of the pairs contributing to a target; that would mismeasure the cancellations route A is designed to expose.

C. Compare target-first and master-first on complete Kira columns

Select masters with:

the largest number of incoming targets;

the largest predicted raw coefficient size;

median fan-in;

small fan-in;

different topology classes.

For a selected master M
m
	​

, load every target in

T
m
	​

={α:R
αm
	​


=0}

and no others. Compute the complete coefficient

K
m
	​

=
α∈T
m
	​

∑
	​

C
α
	​

R
αm
	​


by A or D and by C. This is a complete master coefficient, not a sampled truncation, so exact equality is meaningful.

D. Measure the three distinct effects separately

For each target or master record:

Pair-local compression

ρ
pair
	​

=
∑
p
	​

ByteCount(N
terms
	​

[H(a
pα
	​

)])
∑
p
	​

ByteCount(H(a
pα
	​

))
	​

.

Cancellation between pairs at fixed target

ρ
target
	​

=
ByteCount(N
whole
	​

[∑
p
	​

N
terms
	​

[H(a
pα
	​

)]])
∑
p
	​

ByteCount(N
terms
	​

[H(a
pα
	​

)])
	​

.

Kira amplification

ρ
Kira
	​

=
ByteCount(K
m
	​

)
∑
α∈T
m
	​

	​

ByteCount(C
α
	​

R
αm
	​

)
	​

.

These are representation and timing measurements, not numerical evaluations of the hard function.

Expected NNLO decision

For NNLO UU, route C is unlikely to be competitive because 44,877 targets feed only 342 masters: the average master fan-in is large, and unsimplified targets will be replicated through the sparse Kira map.

The decision is more likely between A and D:

choose A when cancellation between different pairs is so large that even termwise pair processing is wasted work;

choose D when pair-local coordinate and radical normalization gives substantial compression before target accumulation.

The NLO TT result strongly favors D for memory. The earlier NLO UU result favoring target-first simplification indicates that complete pair-level simplification should not automatically replace target-level simplification.

Recommended benchmark outcome

Use the two independent off-diagonal TT calculations to certify conjugation. Then compare A, B, C, and the hybrid D from the same raw pair artifacts. The expected result is:

smallest pre-Kira files:
best total exact workflow:
largest algebraic growth:
	​

B,
D or A,
C.
	​

	​


Route D should be treated as the principal production candidate because it combines the measured pair-local compression with the target-level cancellations that route B does not deliberately expose.

## Sources sent to Pro

- [hadronic_ordering_followup_sources.zip](Sources/05_hadronic_ordering_followup/hadronic_ordering_followup_sources.zip)
