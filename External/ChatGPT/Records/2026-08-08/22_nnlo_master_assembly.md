# NNLO Master Assembly

## Question

We completed the exact hadronic cleanup and exact denominator consolidation for three representative NNLO double-real UU master coefficients. Please assess the algebraic representation and propose a more efficient exact next step, while preserving an analytic result rather than replacing it by numerical reconstruction.

Measured results:

1. Entrywise positive-s root-ring cleanup:
   - 38,400 denominator entries and 38,460 target leaves were covered.
   - Serialized input 859,107,253 bytes -> cleaned output 131,787,741 bytes.
   - Independent source/hash/grammar audit returned exact equality certificates for every entry.

2. Small master:
   - 1 input fraction -> 1 final fraction.
   - Whole coefficient exists and the exact difference from the fraction representation is zero.

3. Median master:
   - 93 input fractions in 11 exact denominator classes -> 8 final fractions.
   - Whole coefficient is 25,328 bytes and the exact difference from the fraction representation is zero.

4. Hard master:
   - 38,306 input fractions, 38,366 target leaves.
   - Initial 6,870 exact denominator classes.
   - Iteration 1: 38,306 -> 6,625 nonzero fractions; 6,299 distinct output denominators.
   - Iteration 2: 6,625 -> 6,298; 6,291 distinct denominators.
   - Iteration 3: 6,298 -> 6,290; 6,290 distinct denominators.
   - Exact consolidation took 6,375.22 s on 8 Mathematica kernels.
   - Worker cancellation time summed to only 959.48 s; most wall time was serial exact grouping and equality checking.
   - Input fraction ByteCount was 422,282,520 bytes; final 6,290-fraction ByteCount grew to 1,727,567,608 bytes; serialized output is 488,886,853 bytes.
   - Independent audit confirms exact data, complete entry counts and hashes, unique final denominator hashes, no momentum-fraction roots, no positive-root placeholder, integer powers of s, nonzero denominators, and no failed or timed-out cancellation.
   - A single global Together was deliberately not attempted.

The exact operation is only

  Sum_i n_i/d = (Sum_i n_i)/d

within classes whose denominators are structurally identical, followed by exact Cancel. Hashes only index candidates; structural SameQ confirms equality.

Questions:

A. Is the 6,290-fraction representation a sensible final exact representation for this hard coefficient, despite its larger ByteCount, or should we preserve the 38,306 entrywise cleaned fractions because they serialize much smaller?

B. Can exact denominator-class construction be accelerated without relying on hash equality as a mathematical proof? In particular, is direct expression-key grouping in Mathematica, or a canonical exact polynomial identifier followed by one representative equality check, preferable to comparing every large denominator to a representative?

C. What exact algebraic organization would likely reduce both count and size: factorized multivariate polynomials, partial-fraction bases, grouping by inert analytic signature before denominator merging, or another representation?

D. Given that all momentum fractions have already been stripped and the coefficient lies in the exact rational function field in s,t,u,Epsilon with inert analytic atoms, what bounded simplification should be attempted next, and what stopping criterion should be used?

The attached Mathematica script is the exact consolidation implementation. Please distinguish steps that provably preserve the analytic coefficient from numerical diagnostics.

## Pro response

The consolidation is algebraically correct, but the hard-master measurements show that the number of stored fractions is no longer a useful proxy for simplicity. The eager reduction

38306 fractions⟶6290 fractions

reduced the number of summands while increasing the in-memory expression size from 422 MB to 1.73 GB and the serialized artifact to 489 MB. The next step should not continue the same iteration or attempt a global common denominator.

Source reviewed: AssembleNNLOSelectedMasterCoefficients.wls.

A. Which exact representation should be retained?

The 6290-fraction result is a valid exact representation,

H
m
	​

=
α=1
∑
6290
	​

D
α
	​

N
α
	​

	​

,

but it is not the best durable representation. The eager Total[numerators] at lines 80–81 destroys structural sharing: many relatively small numerator contributions are replaced by one large expanded numerator. Cancel[numerator/denominator] can then make that numerator substantially more expensive even when it removes a common factor.

Retain two layers:

Authoritative source representation: the 38306 entrywise-cleaned fractions and their existing coverage and equality certificates.

Compact computational representation: an exact denominator dictionary with lazy numerator sums,

H
m
	​

=
δ∈D
m
	​

∑
	​

d
δ
	​

i∈I
δ
	​

∑
	​

n
i
	​

	​

,

where d
δ
	​

 is stored once and ∑
i∈I
δ
	​

	​

n
i
	​

 remains a balanced addition tree or a list of references, not an eagerly evaluated Total.

A suitable artifact is conceptually

Wolfram Language
<|
  "DenominatorTable" -> <|
    denominatorID1 -> denominator1,
    denominatorID2 -> denominator2,
    ...
  |>,
  "Buckets" -> <|
    denominatorID1 -> {
      numeratorRecordID1,
      numeratorRecordID2,
      ...
    },
    ...
  |>,
  "NumeratorRecords" -> ...
|>

This simultaneously preserves:

the 6870-class denominator dictionary from the initial grouping;

the smaller serialized numerator records;

exact source provenance;

the ability to perform bounded cancellation one denominator class at a time.

The already computed 6290-fraction artifact is useful as an independently verified derived record, but it should not replace the smaller entrywise data.

The relevant exact identity is simply

d
n
1
	​

	​

+⋯+
d
n
r
	​

	​

=
d
n
1
	​

+⋯+n
r
	​

	​

.

There is no requirement that the sum n
1
	​

+⋯+n
r
	​

 be materialized immediately.

The current stopping rule

The loop at lines 126–169 continues until no two output denominators are structurally equal. That fixed point is exact, but it is not economically meaningful. In the measured hard column:

6625⟶6298⟶6290.

The third iteration removed only eight fractions. Future runs should not seek this fixed point automatically. A single pass, followed by optional bounded processing of unusually large or highly repeated denominator classes, is preferable.

B. Faster exact denominator classification

The current construction is mathematically safe:

the stored hash is used only to locate candidates;

SameQ at lines 59 and 64 establishes exact structural equality.

A hash collision cannot cause a false merge. However, repeatedly comparing large denominators to a representative and rebuilding the jobs at lines 135 and 152 is expensive.

Preferred design: intern denominators once

Assign each exact denominator an immutable integer ID at the stage where the cleaned entry is written. The cleaned artifact should contain

Wolfram Language
"DenominatorID" -> id

rather than repeatedly storing and regrouping the full denominator.

The dictionary can be built with the complete held expression as the exact key:

Wolfram Language
denominatorKey[denominator_] :=
  HoldComplete[denominator];

An association or GroupBy can then use the full held expression as the grouping key. Any internal hashing performed by Mathematica is only an indexing device; the complete expression is the key being compared.

Conceptually:

Wolfram Language
groups = GroupBy[
  records,
  HoldComplete[Last[Last[#]]] &
];

This removes the explicit hash-group-then-Gather layer in splitDenominatorHashGroup.

For the current files, the least disruptive patch is:

Wolfram Language
exactDenominatorJobs[records_List] :=
  KeyValueMap[
    Function[{heldDenominator, pairs},
      {
        First[heldDenominator],
        First /@ pairs
      }
    ],
    GroupBy[
      records,
      HoldComplete[Last[Last[#]]] &
    ]
  ];

The exact syntax should be adapted so that the held denominator is extracted without premature reconstruction, but the principle is to use the complete expression as the identifier.

Canonical polynomial identifier

If the denominator has a certified polynomial grammar, a smaller exact identifier is preferable. Freeze every nonrational analytic object through one global dictionary, choose a fixed variable ordering

z=(s,t,u,ϵ,A
1
	​

,…,A
k
	​

),

and define

κ(D)=CoefficientRules(D;z).

In Mathematica:

Wolfram Language
canonicalPolynomialKey[
    denominator_,
    variables_List
  ] := Module[{rules},

  If[! PolynomialQ[denominator, variables],
    Return[$Failed]
  ];

  rules = CoefficientRules[
    Expand[denominator],
    variables
  ];

  HoldComplete[
    SortBy[rules, First]
  ]
];

Under a fixed variable list, the complete coefficient-rule list is an injective exact encoding of the polynomial. Two equal keys mean the denominator polynomials are equal; no representative comparison is mathematically necessary.

This is distinct from hashing the key. A hash may still index the records, but the complete key remains the equality certificate.

Normalize only the denominator, not its large numerator

To identify denominators differing by a coefficient-field unit, write

D=c
D
,c∈K
×
,

where 
D
 is monic in a fixed monomial order. Store the fraction as

D
N
	​

=
c
1
	​

D
N
	​

.

Do not replace N by N/c immediately. Store 1/c as a lazy scalar:

Wolfram Language
<|
  "ScalarUnit" -> 1/c,
  "NumeratorTree" -> ...,
  "MonicDenominatorID" -> id
|>

This avoids the earlier failure mode in which denominator normalization traversed and transformed a huge numerator.

If monic normalization exceeds its bound, retain the exact unnormalized denominator. That only misses a grouping opportunity.

C. Algebraic organization most likely to reduce both count and size

The best next representation is not a full multivariate partial-fraction expansion. It is:

dimensionless kinematics+shared denominator-factor dictionary+lazy numerator trees+GCD-aware bounded addition.
	​

1. First remove the overall invariant scale

The coefficient is now rational in s,t,u,ϵ, with only integer powers of s. Introduce

x=−
s
t
	​

,y=−
s
u
	​

.

In the declared physical chamber,

s>0,t<0,u<0,s+t+u>0,

one has

x>0,y>0,x+y<1.

The substitution

t=−sx,u=−sy

is purely rational and does not change a branch. No noninteger-power identity is used.

For each master coefficient, determine its exact mass dimension Δ
m
	​

 and test whether

H
m
	​

(s,t,u,ϵ)=s
Δ
m
	​

h
m
	​

(x,y,ϵ).

More locally, each fraction can be mapped as

d
i
	​

(s,t,u,ϵ)
n
i
	​

(s,t,u,ϵ)
	​

=s
Δ
i
	​

d
i
	​

(x,y,ϵ)
n
i
	​

(x,y,ϵ)
	​

.

This change is likely to remove a large amount of artificial denominator diversity:

s+t=s(1−x),
s+u=s(1−y),
s+t+u=s(1−x−y),
t+u=−s(x+y).

Denominators that currently differ by powers of s or by homogeneous presentations can become identical low-degree polynomials in x,y.

This should be the first measured next step.

The acceptance criteria are:

exact reconstruction after t=−sx, u=−sy;

all extracted s-powers are integers;

the remainder is exactly free of s;

the physical chamber is recorded as

s>0,x>0,y>0,x+y<1.
2. Build a factor dictionary for the dimensionless denominators

For each primitive denominator,

d
i
	​

(x,y,ϵ),

attempt bounded exact factorization:

d
i
	​

=c
i
	​

α
∏
	​

f
α
	​

(x,y,ϵ)
e
iα
	​

.

Store each distinct factor f
α
	​

 once, together with the exponent profile

e
i
	​

=(e
i1
	​

,e
i2
	​

,…).

If factorization times out, retain the complete denominator as one indivisible factor. This remains exact, though less compact.

The representation then becomes

Wolfram Language
<|
  "FactorTable" -> <|
    factorID1 -> factor1,
    factorID2 -> factor2,
    ...
  |>,
  "Fractions" -> {
    <|
      "ScalarUnit" -> unit1,
      "NumeratorTree" -> ...,
      "DenominatorProfile" -> <|factorID1 -> 1, factorID3 -> 2|>
    |>,
    ...
  }
|>

This can reduce serialized size even when nearly every complete denominator is distinct, because the same irreducible factors may recur in many combinations.

3. Use GCD-aware balanced addition

For two fractions

Q
1
	​

P
1
	​

	​

,
Q
2
	​

P
2
	​

	​

,

let

G=gcd(Q
1
	​

,Q
2
	​

),Q
1
	​

=GA,Q
2
	​

=GB.

Then

Q
1
	​

P
1
	​

	​

+
Q
2
	​

P
2
	​

	​

=
GAB
P
1
	​

B+P
2
	​

A
	​

.

With factor profiles, G,A,B are obtained by minimum and difference of exponent vectors; no repeated polynomial GCD is needed.

Merge first the pair with:

greatest denominator-factor overlap;

smallest predicted output factor profile;

closest expression sizes.

The identity is exact. The merge order is only a resource heuristic.

4. Do not use generic multivariate partial fractions yet

A multivariate partial-fraction decomposition can:

increase the number of terms;

depend on the chosen monomial order;

introduce many intermediate denominator combinations;

require expensive algebraic-dependence checks among denominator factors.

It should not be the next full-scale transformation.

A later univariate partial fraction in y over the coefficient field

Q(x,ϵ,…)

may be profitable if the factor inventory shows that most denominators are low degree in y. That is an exact, measurable follow-up, not the first step.

5. Do not group by analytic signature before rational cancellation

For the measured selected UU coefficients, the main algebra is rational. Any inert analytic object should be frozen globally and treated as a coefficient-field element. Splitting the sum by syntactic analytic signatures before rational combination risks repeating the NLO TT failure, where necessary cancellation crossed the chosen signatures.

D. Bounded exact simplification and stopping criterion

The coefficient is already a valid exact analytic answer. Every additional transformation is optional compression. The next bounded sequence should be:

Stage 1: dimensionless normalization

For every fraction:

apply

t=−sx,u=−sy;

extract its exact overall s-power;

remove root-independent denominator content;

store the resulting primitive denominator in x,y,ϵ.

Accept only after exact reconstruction.

Stage 2: bounded denominator factorization

Factor denominators only, not the accumulated large numerators.

For example:

Wolfram Language
factorization = TimeConstrained[
  MemoryConstrained[
    FactorList[denominator],
    denominatorMemoryLimit,
    $MemoryExceeded
  ],
  denominatorTimeLimit,
  $TimedOut
];

A timeout keeps the complete denominator as one atomic factor.

Stage 3: lazy exact denominator classes

Do not evaluate

Wolfram Language
Total[numerators]

for every large class. Store a balanced numerator tree. Materialize and cancel a tree node only when it is below fixed bounds.

For a changed node, require:

D
old
	​

N
new
	​

−D
new
	​

N
old
	​

=0

or the corresponding compositional certificate from exact child operations.

Stage 4: bounded GCD-aware merges

Attempt only merges whose predicted denominator profile is not larger than a chosen bound. After every merge:

cancel exact common factors;

retain the result only if the chosen cost decreases;

otherwise keep the two original children.

Cost function and exact stopping rule

Define a representation cost such as

C=B
serialized
	​

+λN
frac
	​

+μB
factor table
	​

+νB
largest node
	​

,

with fixed positive weights chosen before the run.

A transformation is accepted only if:

exact equality is certified;

branch and exact-data checks are satisfied;

C
new
	​

<C
old
	​

;

no individual node exceeds the memory limit.

Stop after one complete sweep in which no certified transformation reduces the cost.

A simpler practical criterion is:

B
serialized
	​

ΔB
serialized
	​

	​

<0.02,
N
frac
	​

ΔN
frac
	​

	​

<0.01,

with no reduction in the number of distinct denominator-factor profiles. At that point further passes should stop.

By this criterion, the measured third consolidation iteration,

6298⟶6290,

would not justify another pass.

Exact benchmark before applying this to all 6290 fractions

Use four deterministic datasets:

Dataset	Purpose
Complete median master	Exact end-to-end comparison against its known 25328-byte whole coefficient
100 largest hard-master fractions	Peak-memory and large-numerator behavior
512 stratified hard-master fractions	Representative denominator-factor inventory
512 fractions chosen for maximal denominator overlap	Best-case test of factor-profile merging

Compare:

the entrywise cleaned representation;

the current eager 6290-fraction representation restricted to the same entries;

dimensionless lazy denominator buckets;

dimensionless factor profiles with GCD-aware merges.

For every changed representation require:

exact source coverage;

exact reconstruction;

no x
a
	​

,x
b
	​

,z
h
	​

 or temporary roots;

only integer invariant powers;

no inexact data;

unchanged branch registry;

timeout recorded as unchanged, never as equality;

lower serialized size or lower declared representation cost.

Recommendation

Do not perform another whole hard-master consolidation pass. Preserve the 38306 entrywise cleaned fractions as the authoritative exact data. Replace the eager 6290-fraction form by a structured artifact

H
m
	​

=s
Δ
m
	​

α
∑
	​

∏
j
	​

f
j
	​

(x,y,ϵ)
e
αj
	​

N
α
	​

(x,y,ϵ)
	​

,x=−t/s,y=−u/s,
	​


where:

the f
j
	​

 are stored once in a factor dictionary;

each numerator is a lazy exact addition tree;

denominator profiles are sparse exponent maps;

only bounded, exactly certified GCD-aware merges are materialized.

That representation is more likely to reduce both storage and later symbolic cost than either the 38306 fully duplicated fractions or the 6290 eagerly summed numerators.

## Sources sent to Pro

- [assemblennloselectedmastercoefficients.wls](Sources/22_nnlo_master_assembly/assemblennloselectedmastercoefficients.wls)
