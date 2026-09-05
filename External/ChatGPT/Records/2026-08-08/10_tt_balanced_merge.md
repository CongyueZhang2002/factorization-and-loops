# TT Balanced Merge

## Question

We are optimizing exact analytic coefficient simplification for the NLO TT real-emission calculation in FACET. Please assess the measured result and recommend the next exact algebraic ordering, with the eventual NNLO scale (44,877 targets, 342 masters) in mind.

Required physics constraints:
- Exact analytic result, not numerical interpolation.
- Preserve BMHV, branches, endpoint dependence, and cut structure.
- The hadronic variables are mapped exactly to partonic Mandelstam variables before simplification.
- Momentum fractions xa, xb, zh must not enter the hard coefficients nontrivially.

Measured NLO TT facts:
- 87 Kira targets, 8 topology classes, 6 masters.
- Applying the exact hadronic map to complete targets, globally freezing maximal nonrational analytic objects, and doing Factor[Cancel[Together[...]]] on each complete target reduced 139,298,664 bytes to 10,562,384 bytes in 52.0 s on 4 kernels.
- Every local rational merge was checked exactly in the frozen polynomial ring; zero checks failed.
- On the largest target: 4,279,848 -> 72,136 bytes in 0.196 s by the rational merge, and -> 25,256 bytes after optional historical Beta/Hypergeometric collection plus Simplify.
- Splitting the target into separate analytic signatures before Together was substantially worse because it prevented cancellations between syntactically different but algebraically coupled terms.
- 40 complete targets still contain xa or xb, so fraction cancellation is not target-local.

Directly constructing each master coefficient from all reduced target images and simplifying it was poor: a 10.47 MB input grew to 101.5 MB in 179 s and retained xa,xb.

Current experiment:
- For each of the six masters, form its list of target contributions.
- Sort contributions by ByteCount and merge them in a balanced binary tree.
- At every binary node, use the same frozen whole-rational merge and exact certificate.
- Run the six masters across 4 kernels.
- Five masters appear complete. One worker has remained CPU-active for about 12 minutes and uses about 1.8 GB. Each merge node nominally has a 120 s TimeConstrained bound, but it may be traversing several difficult nodes.

Questions:
1. Is balanced binary merging the right exact next step after complete-target rational compression?
2. For the difficult master, should contributions be grouped first by denominator class, maximal analytic atom set, topology class, or some other mathematically justified invariant before balanced merging?
3. How should we preserve cancellations needed to remove xa,xb while avoiding a monolithic Together on the full master coefficient?
4. At NNLO, should the sparse Kira rows be streamed target-by-target into master accumulators, with bounded balanced merges and disk spill? Give a concrete exact ordering.
5. What exact local certificates should be retained so a timeout is reported as unresolved rather than silently accepting a changed expression?

Please distinguish advice that is exact algebra from heuristic expression-size scheduling.

## Pro response

Balanced binary merging is exact, but the twelve-minute difficult master shows that byte-count balancing alone is not the right next mathematical step. The next test should isolate the only cancellation known to require contributions from different targets: cancellation of x
a
	​

,x
b
	​

,z
h
	​

.

The recommended order is

	​

complete-target rational compression
⟶master accumulation over the momentum-fraction denominator ring
⟶exact certification that x
a
	​

,x
b
	​

,z
h
	​

 cancel
⟶balanced cleanup of the remaining s,t,u,ϵ coefficient.
	​

	​


This avoids asking Together to solve the momentum-fraction cancellation and all remaining kinematic simplification simultaneously.

1. Status of balanced binary merging

For exact leaves f
1
	​

,…,f
n
	​

, any binary tree computing

F=
i=1
∑
n
	​

f
i
	​


is mathematically valid. If every changed node is certified, merge order affects only time and memory.

Therefore, the current balanced tree is a sound fallback. It has two limitations.

First, sorting only by ByteCount does not reflect denominator compatibility. Two similarly sized expressions can have nearly coprime denominators, making their common denominator much larger than either input.

Second, a 120-second limit on each node is not a 120-second limit on the master. A worker traversing six difficult nodes can remain active for twelve minutes without violating any node-local bound.

A timed-out node should not be repeatedly reconsidered at every ancestor. Retain it as an exact structured sum,

Wolfram Language
ExactUnmergedSum[{leftBlock, rightBlock}]

rather than immediately forming a large explicit Plus. Its status is then

Wolfram Language
"NormalizationStatus" -> "TimedOutUnchanged"

while its exact algebraic status remains known. The timeout means that one compression attempt was unresolved, not that equality was unresolved.

The present measurement justifies keeping balanced merging, but after a more focused momentum-fraction cancellation stage.

2. How the difficult master should be grouped

Do not permanently divide the master contributions by:

Kira topology class;

original target family;

maximal syntactic analytic-atom set;

Gamma/Beta/hypergeometric spelling.

The measured target result already demonstrates that apparently different analytic structures can participate in the same required rational cancellation. A permanent division by syntactic analytic signatures would repeat the earlier failure.

The appropriate first classification is by the denominator factors involving

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

For a master contribution

f
αm
	​

=R
αm
	​

C
α
	​

,

write its reduced exact fraction as

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

θ=(s,t,u,ϵ,color variables,frozen analytic objects),

and

FreeQ[d
αm
(0)
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

The factor d
αm
(x)
	​

 contains precisely the irreducible denominator factors involving at least one momentum fraction. Examples include

ux
a
	​

+tx
b
	​

.

This classification is mathematically relevant because the Kira coefficients satisfy

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

Hence Kira can change the fraction-free denominator d
αm
(0)
	​

, but it cannot introduce a new momentum-fraction denominator geometry.

Recommended grouping order

Within each master:

Merge exactly equal complete denominators.

Identify and normalize the momentum-fraction denominator factor multisets.

Compute the common momentum-fraction denominator without combining all fraction-free denominators.

Accumulate coefficients of monomials in x
a
	​

,x
b
	​

,z
h
	​

.

Certify cancellation of the common momentum-fraction denominator.

Only afterward perform balanced merges in the remaining variables.

After fraction cancellation, denominator-overlap scheduling is preferable to pure byte-size scheduling. For two remaining blocks with denominators d
i
	​

 and d
j
	​

, use the exact quantity

g
ij
	​

=gcd(d
i
	​

,d
j
	​

)

or equivalently the growth of

lcm(d
i
	​

,d
j
	​

)=
g
ij
	​

d
i
	​

d
j
	​

	​

.

Merge pairs with the greatest denominator overlap or smallest predicted least-common-denominator growth first. This is a heuristic scheduling choice; the equality certificates make the result exact.

Topology class may still be used for disk organization, but all topology classes feeding the same master must eventually be combined.

3. Exact momentum-fraction cancellation without a monolithic master Together

This is the principal next test for the difficult master.

Let

K
m
	​

(x,θ)=
α∈T
m
	​

∑
	​

f
αm
	​

(x,θ).

For every leaf, first certify the decomposition

d
αm
	​

=d
αm
(x)
	​

d
αm
(0)
	​

.

Normalize each irreducible factor in d
αm
(x)
	​

 up to multiplication by a nonzero x-independent factor. For example,

ux
a
	​

+tx
b
	​


and

x
a
	​

+
u
t
	​

x
b
	​


must represent the same factor class.

Define the common momentum-fraction denominator

L
m
	​

(x,θ)=lcm
α∈T
m
	​

	​

d
αm
(x)
	​

.

Then

K
m
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
α∈T
m
	​

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

The key point is that P
m
	​

 need not be assembled as one large expression. Expand only with respect to x:

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
ν
,

where

x
ν
=x
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

Similarly,

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
ν
.

Each coefficient p
m,ν
	​

 is accumulated separately using exact equal-denominator buckets and bounded balanced merges in θ. There is no full-master common denominator in s,t,u,ϵ.

Exact fraction-independence test

After the common physical prefactor has been removed, the desired result is

K
m
	​

(x,θ)=H
m
	​

(θ).

This is equivalent to

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

Choose an exponent vector ν
0
	​

 for which

ℓ
m,ν
0
	​

	​


=0

and define

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

Then verify, for every exponent vector in the union of the two polynomial term sets,

p
m,ν
	​

−H
m
	​

ℓ
m,ν
	​

=0.
	​


Each of these is a rational identity only in θ, so it is much smaller than the original full-master difference.

If the expected remaining fraction dependence is a declared Laurent monomial

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

.

Necessary conditions

This certificate requires:

x
a
	​

,x
b
	​

,z
h
	​

 are algebraically independent over the coefficient field; inequalities such as 0<x
a
	​

,x
b
	​

,z
h
	​

<1 are allowed, but no algebraic relation among them may be imposed.

Every frozen analytic object must be free of x
a
	​

,x
b
	​

,z
h
	​

. An object such as

Γ(x
a
	​

+ϵ)

cannot be hidden inside an atom and then declared fraction-independent.

The Kira coefficients must be exactly free of x
a
	​

,x
b
	​

,z
h
	​

.

Endpoint distributions involving a momentum fraction must remain in a declared distributional basis; ordinary rational cancellation cannot be used across distinct distributional objects.

All Gamma/Beta/Pochhammer identities FACET intends to recognize must be canonicalized before freezing. A failed polynomial zero check is otherwise only unresolved, not proof of inequality.

Mathematica-level structure

Schematically:

Wolfram Language
xVariables = {xa, xb, zh};

leaves = Map[
  Cancel[kiraCoefficient[#] targetCoefficient[#]] &,
  targetIndicesForMaster
];

profiles = splitMomentumFractionDenominator[
  #,
  xVariables
] & /@ leaves;

If[
  MemberQ[profiles, $Failed] ||
    ! AllTrue[
      profiles,
      FreeQ[#["FractionFreeDenominator"],
        Alternatives @@ xVariables] &
    ],
  Return[$Failed]
];

commonXDenominator =
  exactFactorMultisetLCM[
    Lookup[profiles, "FractionDenominatorFactors"]
  ];

coefficientMaps = MapThread[
  xPolynomialCoefficientMap[
    Numerator[#1] *
      Cancel[
        commonXDenominator /
          #2["FractionDenominator"]
      ],
    #2["FractionFreeDenominator"],
    xVariables
  ] &,
  {leaves, profiles}
];

masterNumeratorMap =
  Merge[
    coefficientMaps,
    boundedExactRationalMerge
  ];

commonDenominatorMap =
  Association @ CoefficientRules[
    Expand[commonXDenominator],
    xVariables
  ];

hardCoefficient =
  certifyFractionIndependence[
    masterNumeratorMap,
    commonDenominatorMap
  ];

The first experiment should be run only on the difficult 559.6 MB master’s current leaf list. Record:

the number of distinct momentum-fraction denominator factors;

their maximum powers;

the number of resulting x
a
	​

,x
b
	​

,z
h
	​

 monomials;

the largest coefficient bucket;

time and peak memory;

whether the fraction-independence identities are established.

This test is more informative than another full binary-tree run.

4. What remains of balanced merging

After the momentum-fraction cancellation has produced

H
m
	​

(s,t,u,ϵ,color,analytic objects),

use the balanced merge tree on its remaining exact blocks.

The recommended scheduling is:

equal denominators first;

then maximum denominator gcd;

then minimum predicted least-common-denominator size;

byte count only as a tie-breaker;

maintain approximately balanced tree depth.

Do not permanently separate by maximal analytic atom set. Keep all special functions in one globally frozen polynomial ring unless their linear independence has been established.

It is safe to separate by a genuinely independent basis, for example:

distinct PDF/FF channels;

distinct Fourier harmonics;

a declared linearly independent TT tensor basis;

a fixed color basis;

a certified algebraic radical basis.

Within each such sector, all Gamma, Beta, hypergeometric, logarithmic, and noninteger-power atoms should still be allowed to participate in the same rational algebra after the narrow canonicalization.

5. NNLO streaming order

For 1,296 pair files, 44,877 targets, and 342 masters, use the following exact sequence.

Stage 1: complete targets

For one target α:

read every pair contribution to G
α
	​

;

divide out the already certified global pair factor;

form the complete target coefficient;

apply the exact hadronic map;

apply the fixed branch registry;

apply the narrow Gamma/Beta/Pochhammer canonicalization;

freeze maximal analytic, distributional, BMHV, and Fourier objects with a stable global dictionary;

perform the whole-target rational merge;

certify the changed target locally;

save its canonical fraction and source manifest.

The complete target remains the smallest currently established unit for this first rational merge. The measured failure of pre-Together signature separation gives no basis for using a smaller analytic-atom sector.

Stage 2: sparse Kira fan-out

For every nonzero entry R
αm
	​

:

read the compressed target once;

form

f
αm
	​

=R
αm
	​

C
α
	​

;

cancel only this product;

extract its momentum-fraction denominator profile;

append a compact leaf record to master m.

The leaf record should contain:

Wolfram Language
<|
  "Target" -> alpha,
  "TargetHash" -> ...,
  "KiraRuleHash" -> ...,
  "Numerator" -> ...,
  "FractionDenominator" -> ...,
  "FractionFreeDenominator" -> ...,
  "FractionFactorizationCertificate" -> ...
|>

No complete master expression is constructed.

Stage 3: momentum-fraction elimination per master

For each master:

compute L
m
	​

;

stream each leaf into the coefficient map of P
m
	​

;

merge the θ-coefficients with disk-backed balanced trees;

establish

P
m
	​

=H
m
	​

L
m
	​

;

save the fraction-free H
m
	​

.

This stage contains every target contributing to the master, so no x
a
	​

,x
b
	​

,z
h
	​

 cancellation is lost.

Stage 4: final bounded cleanup

Apply denominator-overlap-guided balanced cleanup to H
m
	​

. On timeout, retain the exact structured block sum. The final artifact may store

H
m
	​

=
j=1
∑
N
m
	​

	​

h
mj
	​


rather than forcing one enormous rational expression, provided exact reconstruction is retained.

6. Required local certificates

Every algebra-changing operation should produce one of three statuses:

Wolfram Language
"VerifiedExact"
"TimedOutUnchanged"
"FailedUnchanged"

There should be no status in which a changed expression is accepted without verification.

Target rational merge

If the input fraction tree represents N
0
	​

/D
0
	​

 and the proposed output is N
1
	​

/D
1
	​

, verify

N
0
	​

D
1
	​

−N
1
	​

D
0
	​

=0
	​


in the frozen polynomial ring.

For a binary merge

d
1
	​

n
1
	​

	​

+
d
2
	​

n
2
	​

	​

⟼
d
n
	​

,

retain the node certificate

nd
1
	​

d
2
	​

−d(n
1
	​

d
2
	​

+n
2
	​

d
1
	​

)=0.
	​

Momentum-fraction denominator split

For every leaf, retain

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

=0,
	​


and verify that d
αm
(0)
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

.

Common fraction denominator

Retain the normalized factor multiset defining L
m
	​

 and verify

d
αm
(x)
	​

L
m
	​

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

 for every leaf.

Polynomial coefficient map

For every leaf contribution, verify exact reconstruction from its monomial map:

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

−
ν
∑
	​

q
αm,ν
	​

x
ν
=0.
	​

Fraction-independence certificate

Retain H
m
	​

 and every exact result

p
m,ν
	​

−H
m
	​

ℓ
m,ν
	​

=0.

These identities are the direct proof that the momentum fractions have disappeared.

Context records

Every certificate must also identify:

the hadronic-map fingerprint;

the branch registry;

the analytic-atom dictionary;

the BMHV and tensor-basis conventions;

the common pair factor;

the Kira rule and master-basis fingerprint;

the physical cut indices and directions;

all source target hashes.

Exact algebra versus scheduling heuristics
Change	Status
Whole-target rational merge in a frozen ring	Exact algebra
Common x
a
	​

,x
b
	​

,z
h
	​

 denominator construction	Exact algebra
Coefficientwise proof P
m
	​

=H
m
	​

L
m
	​

	Exact algebra
Equal-denominator bucketing	Exact algebra
Binary merge cross-multiplication certificates	Exact algebra
Sorting by ByteCount	Heuristic
Merging the largest denominator gcd first	Heuristic
Smallest predicted lcm growth first	Heuristic
120-second node limit	Resource policy
Four or eight workers	Resource policy
Disk spill and checkpoint frequency	Resource policy

The present difficult-master result does not indicate a problem with exact balanced merging. It indicates that the merge tree is attempting to simplify the entire coefficient field before isolating the specific cross-target cancellation required by collinear factorization. The next mathematical test should therefore be the common momentum-fraction denominator construction and coefficientwise proof on that one master.
