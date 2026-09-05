# NNLO Hadronic Simplification

## Question

We have completed the full exact NLO TT simplification experiment discussed in this thread. Please assess the measured result and advise on the next NNLO UU experiment. This is an exact analytic hard-function calculation; numerical interpolation is not an acceptable main route.

Full NLO TT result:
- 87 Kira targets, 8 topology classes, 6 masters.
- Exact hadronic substitution on complete targets, followed by a globally frozen rational merge, reduced 139,298,664 bytes to 10,562,384 bytes in 52.02 s on four Mathematica kernels. Every frozen-ring equality certificate succeeded.
- After sparse Kira mapping, each master contribution was decomposed in the independent TT angular basis Cos[phi_a] Cos[phi_h] and Sin[phi_a] Sin[phi_h]. The two mixed basis coefficients were exactly zero.
- Within each master/angular channel, balanced exact rational merging was followed by Simplify under the card assumptions. Every accepted simplification satisfied an exact assumption-aware identity check.
- The completed master result took 30.36 s after the target stage, contains all six masters, is 750,504 bytes on disk, and is exactly free of xa, xb, zh and of hadronic auxiliary vectors.
- The formerly difficult master had 78 contributions. Its cc channel went 3,472,704 -> 3,162,376 -> 57,752 bytes; its ss channel went 4,107,256 -> 3,457,728 -> 61,768 bytes. The final Simplify calls took below one second per channel once the exact angular decomposition and rational merge were complete.

The measured successful order is therefore:
1. exact hadronic substitution on each complete target;
2. canonicalize known branch-safe positive bases;
3. freeze maximal nonrational analytic objects globally without separating the sum;
4. Factor[Cancel[Together[...]]] in the resulting rational ring, with exact frozen-ring equality certificate;
5. apply sparse Kira rows;
6. split only by a genuinely independent physical basis (TT angular structures here);
7. balanced rational merges inside each master/basis channel;
8. bounded Simplify under exact assumptions, accepted only after exact assumption-aware equality.

This is more than one replacement plus Simplify. It also agrees with the useful parts of the original real-emission notebook: after integration it collected composite Beta*Hypergeometric2F1 objects, then individual Beta/Hypergeometric objects, and applied local Factor[Cancel[Together[...]]] before an outer Simplify. Our measurements show that this historical collection is useful only after the complete rational cancellation; doing syntactic special-function grouping first blocks needed cancellations.

NNLO UU production data already exist:
- 1,296 pair files, 360 MB;
- KiraResult.wl, 798 MB;
- 44,877 targets, 342 masters;
- existing disk stores split target records and sparse Kira rows into 258 files, plus per-master records.

Questions:
1. For NNLO UU, should we first run the certified whole-target rational merge on every complete target and then stream sparse Kira rows into per-master accumulators, or should hadronic-fraction elimination be delayed until contributions are grouped by master?
2. Since NLO TT showed that 40 targets retained xa or xb while every final master was fraction-free, what exact bounded representation best permits cross-target fraction cancellation at NNLO without constructing all 44,877 targets or one full master in RAM?
3. Is it useful to characterize each master contribution by its denominator polynomial in xa,xb,zh and merge complementary denominator classes first? Please give a precise exact algorithm, not only a scheduling suggestion.
4. Which parts of the original Beta/Hypergeometric collection should be retained at NNLO, and at what stage?
5. Suggest acceptance criteria and a representative-shard experiment that can falsify the proposed ordering before an overnight run.

Please distinguish algebraically exact transformations from heuristics that only choose merge order.

## Pro response

The NLO TT measurement establishes a clear separation:

apply the hadronic map and compress each complete target before Kira,
	​


but

delay the final proof that x
a
	​

,x
b
	​

,z
h
	​

 disappear until all targets feeding a master have been combined.
	​


The target operation is valuable even though 40 targets retain x
a
	​

 or x
b
	​

: it reduced the complete target data by a factor of about 13.2,

139.30 MB⟶10.56 MB,

in 52.02 seconds, with an exact identity certificate for every changed coefficient. The failure of target-local fraction cancellation is not a reason to delay the hadronic map; it only shows that fraction elimination is a master-level statement.

The repository requirement is likewise that the result remain an exact analytic function with explicit regulator, endpoint, distributional, branch, cut, and BMHV information; fixed-point values are verification only. 

AGENTS

 

AGENTS

 The corrected production inventory fixes the NNLO basis at 342 masters, so the issue here is how to assemble their coefficients exactly from the 44,877 target coefficients. 

BOUNDARY_FAMILY_INVENTORY

 

BOUNDARY_FAMILY_INVENTORY

1. Recommended NNLO ordering

Let the common pair factor already certified from the amplitudes be F
com
	​

, and let the complete coefficient of target G
α
	​

, after removing F
com
	​

, be

C
α
	​

(x
a
	​

,x
b
	​

,z
h
	​

;θ)=
p∈P
α
	​

∑
	​

P
p
	​

c
pα
	​

,

where

θ=(s,t,u,ϵ,color data,frozen analytic objects).

Let the exact Kira reduction be

G
α
	​

=
m=1
∑
342
	​

R
αm
	​

(θ)M
m
	​

.

The Kira coefficients must satisfy

FreeQ[R
αm
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True.

The recommended sequence is

C
α
	​

	​

exact hadronic map
	​

C
α
phys
	​

fixed branch canonicalization
	​

C
α
	​

globally freeze nonrational objects
	​

C
α
fr
	​

Factor∘Cancel∘Together
	​

C
α
fr
	​

sparse Kira fan-out
	​

R
αm
	​

C
α
fr
	​

disk-backed master accumulation
	​

K
m
fr
	​

master-level fraction certificate
	​

H
m
	​

(θ).
	​

	​


Thus:

hadronic substitution occurs at complete-target level;

whole-target rational compression occurs before Kira;

the final cancellation of x
a
	​

,x
b
	​

,z
h
	​

 is proved at complete-master level.

Do not require each of the 44,877 targets to be fraction-free. NLO TT directly disproves that as a necessary intermediate condition.

2. Exact bounded representation for cross-target cancellation

A full master expression is not required. The appropriate representation isolates only the denominator dependence on

x=(x
a
	​

,x
b
	​

,z
h
	​

).

For each nonzero Kira image

f
αm
	​

=R
αm
	​

C
α
fr
	​

,

perform an exact local cancellation and write

f
αm
	​

=
d
αm
(x)
	​

(x,θ)d
αm
(0)
	​

(θ)
n
αm
	​

(x,θ)
	​

,

where

FreeQ[d
αm
(0)
	​

,x]=True.

Here d
αm
(x)
	​

 is a product of normalized irreducible factors that depend on at least one of x
a
	​

,x
b
	​

,z
h
	​

. The decomposition must be certified by

d
αm
	​

−d
αm
(x)
	​

d
αm
(0)
	​

=0.
Common hadronic denominator

For each master m, define

L
m
	​

(x,θ)=lcm
α:R
αm
	​


=0
	​

d
αm
(x)
	​

.

This is computed from normalized factor multisets, without constructing the master coefficient.

Then

K
m
	​

=
α
∑
	​

f
αm
	​

=
L
m
	​

(x,θ)
P
m
	​

(x,θ)
	​

,

where

P
m
	​

=
α
∑
	​

d
αm
(0)
	​

n
αm
	​

(L
m
	​

/d
αm
(x)
	​

)
	​

.

Expand only with respect to x:

P
m
	​

=
ν
∑
	​

p
m,ν
	​

(θ)x
a
ν
a
	​

	​

x
b
ν
b
	​

	​

z
h
ν
h
	​

	​

,

and

L
m
	​

=
ν
∑
	​

ℓ
m,ν
	​

(θ)x
a
ν
a
	​

	​

x
b
ν
b
	​

	​

z
h
ν
h
	​

	​

.

Each p
m,ν
	​

 is accumulated independently on disk as an exact sum of rational leaves in θ. This is the bounded representation:

Wolfram Language
<|
  "Master" -> master,
  "XDenominatorFactors" -> factorMultiset,
  "CommonXDenominator" -> Lm,
  "NumeratorCoefficientFiles" -> <|
    {nuA, nuB, nuH} -> path,
    ...
  |>
|>

The complete Plus expression for K
m
	​

 is never needed.

Exact fraction-independence certificate

Assume the common pair factor already contains the complete expected x
a
	​

,x
b
	​

,z
h
	​

 monomial, so the remaining hard coefficient should be independent of x:

K
m
	​

=H
m
	​

(θ).

Then

P
m
	​

=H
m
	​

L
m
	​

.

Choose an exponent ν
0
	​

 for which

ℓ
m,ν
0
	​

	​


=0.

There is no need to form H
m
	​

 first. Verify for every exponent ν

p
m,ν
	​

ℓ
m,ν
0
	​

	​

−p
m,ν
0
	​

	​

ℓ
m,ν
	​

=0.
	​


These are exact rational identities in θ, usually much smaller than the full master expression. Once they are established,

H
m
	​

=
ℓ
m,ν
0
	​

	​

p
m,ν
0
	​

	​

	​

.

If the card declares a residual Laurent monomial

M
x
	​

=x
a
r
a
	​

	​

x
b
r
b
	​

	​

z
h
r
h
	​

	​

,

apply the same test to K
m
	​

/M
x
	​

, implemented as an exponent shift rather than by forming a large quotient.

Necessary condition on frozen objects

Before this construction, require every frozen atom A
j
	​

 to satisfy

FreeQ[A
j
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True.

An object such as

Γ(x
a
	​

+ϵ),(ux
a
	​

+tx
b
	​

)
−ϵ
,log(ux
a
	​

+tx
b
	​

)

cannot be hidden inside an atom and then treated as part of the coefficient field. Such a target must be retained in a coarser exact block until the nonrational hadronic dependence has been related or cancelled.

This is the main fail-closed condition for the NNLO representation.

3. Denominator-factor classes

Yes, characterize each contribution by its denominator polynomial in x
a
	​

,x
b
	​

,z
h
	​

, but use that characterization to construct an exact common denominator—not as a claim that the classes are analytically independent.

For each contribution, factor

d
αm
(x)
	​

=
j=1
∏
r
αm
	​

	​

q
j
	​

(x,θ)
e
αm,j
	​

.

Each factor must be normalized up to multiplication by a nonzero x-independent factor. With a fixed monomial order in x, one may normalize

q
j
	​

⟼
LC
x
	​

(q
j
	​

)
q
j
	​

	​

,

moving the leading coefficient into d
αm
(0)
	​

.

Define the exact denominator-factor profile

d
αm
	​

={(q
j
	​

,e
αm,j
	​

)}
j=1
r
αm
	​

	​

.
Exact algorithm

For each master:

First streaming pass: compute

E
m
	​

(q)=
α
max
	​

e
αm
	​

(q)

over every normalized factor q.

Construct

L
m
	​

=
q
∏
	​

q
E
m
	​

(q)
.

Second streaming pass: for each contribution, verify

L
m
	​

/d
αm
(x)
	​


is polynomial in x.

Expand

n
αm
	​

d
αm
(x)
	​

L
m
	​

	​


only in x
a
	​

,x
b
	​

,z
h
	​

.

Append each monomial coefficient, divided by
d
αm
(0)
	​

, to its disk bucket.

Merge each monomial bucket with exact rational arithmetic in
θ.

Apply the coefficientwise certificate

P
m
	​

=H
m
	​

L
m
	​

.

Exact equal profiles should be combined first because they share the same multiplier L
m
	​

/d
αm
(x)
	​

. After that, the order in which different profiles are processed affects only time and memory.

“Merge complementary denominator classes first” is not itself a mathematical rule. A useful scheduling heuristic is:

cost(i,j)∼LeafCount[lcm(d
i
(x)
	​

,d
j
(x)
	​

)].

Process pairs with the smallest predicted least-common-denominator growth or largest polynomial gcd first. This is only scheduling; the two-pass L
m
	​

 construction and the local certificates establish exactness.

Topology class should remain provenance data. It is not a valid permanent partition because different topology classes can contribute to the same master and cancel.

4. Beta, Gamma, and hypergeometric collection

Retain two parts of the historical method.

Before whole-target rational merging

Apply only a narrow, deterministic canonicalization of identities FACET has explicitly accepted, for example

B(a,b)=
Γ(a+b)
Γ(a)Γ(b)
	​


or the reverse direction, but not both, and

Γ(z+n)=(z)
n
	​

Γ(z),n∈Z.

Also use the symmetry

2
	​

F
1
	​

(a,b;c;z)=
2
	​

F
1
	​

(b,a;c;z)

if one fixed argument order is chosen.

Do not use broad FunctionExpand, Gamma reflection, Gamma duplication, Euler/Pfaff transformations, hypergeometric contiguous transformations, or noninteger-power factorizations. Those can change the physical branch representation or introduce conditions not contained in the coefficient.

After this narrow canonicalization, globally freeze maximal special-function objects but leave the complete target sum intact. The NLO TT result shows that separating by syntactic special-function keys before Together is wrong for this stage.

After whole-target rational merging

Optional collection by the monomials of the frozen atoms is useful for storage:

C
α
	​

=
n
∑
	​

A
1
n
1
	​

	​

⋯A
k
n
k
	​

	​

R
α,n
	​

.

Normalize each R
α,n
	​

 locally. This must occur only after the complete target cancellation.

After inserting analytic master solutions

The historical composite ordering becomes most relevant once the masters have been replaced by exact Beta/hypergeometric/polylogarithmic functions:

collect composite

B(…)
2
	​

F
1
	​

(…)

structures;

collect individual Beta and hypergeometric structures;

apply local

Factor[Cancel[Together(coefficient)]];

use a bounded outer Simplify, accepted only after an exact identity check.

Do not add this evaluated-master cleanup to the pre-IBP target stage when those functions are not yet present.

5. Representative NNLO experiment

The experiment should contain two parts: a complete-target sample and several complete master columns.

Step 1: metadata catalogue

Without loading target expressions together, record for all 44,877 targets:

serialized and in-memory size;

additive-term count;

Kira fan-out;

number of contributing pair files;

number and degree of x
a
	​

,x
b
	​

,z
h
	​

-dependent denominator factors;

number of frozen analytic atoms;

whether any atom contains x
a
	​

,x
b
	​

,z
h
	​

.

This identifies the genuinely difficult targets and master columns.

Step 2: deterministic target sample

Choose complete targets from the following strata:

32 largest by serialized size;

32 largest by additive-term count;

32 largest by Kira fan-out;

32 with the most complicated hadronic denominator profile;

32 near the median size, distributed across topology classes.

After deduplication, run the exact whole-target route in fresh worker processes.

For every target, record:

input and output size;

elapsed time and peak RSS;

timeout status;

exact frozen-ring certificate;

whether frozen atoms are free of x
a
	​

,x
b
	​

,z
h
	​

;

denominator-factor profile before and after merging.

Acceptance criterion

Every changed target must have a verified exact certificate. A timeout must retain the unchanged canonical target. The ordering is rejected before an overnight run if the largest and denominator-complex targets systematically expand, time out, or contain unresolved nonrational hadronic dependence.

A target retaining rational x
a
	​

,x
b
	​

,z
h
	​

 dependence is not a rejection condition.

Step 3: complete master-column experiment

Select at least five masters:

the largest predicted input byte count;

the largest target fan-in;

the largest number of distinct hadronic denominator factors;

a median column;

a small column.

For each selected m, stream all targets satisfying

R
αm
	​


=0.

Do not use a partial master column: the required fraction cancellation may involve omitted targets.

Compare two exact routes:

Route T
whole-target merge→Kira multiplication→hadronic-denominator coefficient map.
Route U
unmerged canonical target→Kira multiplication→same hadronic-denominator coefficient map.

The final coefficient maps must agree through exact cross-multiplication. This directly measures whether the target merge is worth its cost at NNLO.

Master acceptance criteria

For every selected master:

every target listed in the sparse Kira column is accounted for;

each denominator split is exactly certified;

every L
m
	​

/d
αm
(x)
	​

 is polynomial in x
a
	​

,x
b
	​

,z
h
	​

;

every monomial coefficient merge is exact or unchanged after timeout;

the coefficientwise identities proving

P
m
	​

=H
m
	​

L
m
	​


are established;

H
m
	​

 is free of x
a
	​

,x
b
	​

,z
h
	​

;

no branch, endpoint-distribution, cut, BMHV, or topology metadata changes;

peak RSS remains below the production memory budget.

An unresolved identity is recorded as unresolved. It is not accepted as zero and is not reported as inequality.

Exact transformations and heuristics
Procedure	Status
Exact hadronic substitution	Exact
Fixed branch-certified radical rules	Exact
Global freezing with an injective inverse map	Exact
Whole-target Factor[Cancel[Together[...]]] in the frozen ring	Exact when locally certified
Multiplication by a sparse Kira coefficient	Exact
Separation of d
(x)
d
(0)
	Exact when certified
Construction of L
m
	​

 by factor-multiset maxima	Exact
Expansion only in x
a
	​

,x
b
	​

,z
h
	​

	Exact
Coefficientwise proof P
m
	​

=H
m
	​

L
m
	​

	Exact
Collection by a proved Fourier, color, or tensor basis	Exact
Sorting by byte count	Heuristic
Merging greatest-gcd denominators first	Heuristic
Selecting representative targets and masters	Empirical experiment design
Time and memory limits	Resource policy
Disk-shard size and worker count	Resource policy

The next NNLO experiment should therefore not attempt all 342 masters immediately. First establish on the difficult target strata and several complete master columns that the NLO TT ordering still provides compression and that the hadronic-denominator coefficient map proves the final x
a
	​

,x
b
	​

,z
h
	​

 cancellation without constructing a monolithic master expression.
