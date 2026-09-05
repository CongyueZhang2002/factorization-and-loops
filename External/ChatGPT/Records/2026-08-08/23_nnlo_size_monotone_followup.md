# NNLO Size Monotone Followup

## Question

We tested a simpler exact correction while your response was being generated. Please assess whether this changes the recommended stopping point.

For each exact equal-denominator class we now form both:

  rawPair = {Sum of numerators, common denominator}

and, under time and memory bounds,

  cancelledPair = NumeratorDenominator[Cancel[raw numerator/common denominator]].

We retain whichever exact pair has smaller ByteCount. Singleton classes are left unchanged. Hashes only index candidate classes; every class is checked by structural SameQ inside one of eight workers. Iteration stops when all output denominator hashes are distinct.

Measured hard-master result:

- 38,306 input fractions, 38,366 leaves, 6,870 initial denominator classes.
- Iteration 1: 38,306 -> 6,640 nonzero fractions; 6,558 output denominator hashes.
  Outcomes: 230 exact zeros, 207 cancelled forms selected, 3,694 raw numerator sums selected, 2,739 unchanged singletons.
- Iteration 2: 6,640 -> 6,557; all 6,557 output denominators distinct.
  Outcomes: 1 exact zero, 10 cancelled forms selected, 52 raw sums selected, 6,495 unchanged singletons.
- Wall time: 1,260.22 s on 8 kernels, versus 6,375.22 s for eager Cancel.
- In-memory fraction data: 422,282,520 -> 351,559,840 bytes.
- Serialized output: 99,892,985 bytes, versus 131,787,741 bytes for the full entrywise cleaned three-master store and 488,886,853 bytes for the eager hard-master artifact.
- Independent audit in 7.66 s confirms complete source coverage, exact data, 6,557 distinct denominator hashes, no momentum fractions or auxiliary roots, integer powers of s, nonzero denominators, and exact zero differences for the small and median whole coefficients.

This representation therefore improves count, memory, serialized size, and wall time simultaneously, while retaining an exact list of fractions rather than a lazy numerator tree.

Questions:

1. Is this now a sensible durable exact representation for each master, while retaining the entrywise store as provenance?
2. Should dimensionless normalization x=-t/s, y=-u/s and a shared denominator-factor dictionary still be implemented immediately, or only benchmarked on the deterministic subsets you proposed?
3. Are there any hidden algebraic costs in retaining an uncancelled raw numerator sum when it is smaller than the cancelled pair? Both are exact rational representations, and later operations can still cancel it locally if needed.

## Pro response

1. The new form is a sensible durable exact representation

Yes. The new result changes the stopping point. For the hard master, the 6,557-fraction representation is a reasonable production artifact, while the 38,306-fraction entrywise store should remain the authoritative provenance layer.

For an exact equal-denominator class C,

C={
d
n
i
	​

	​

}
i∈I
C
	​

	​

,

the raw class result is

R
C
	​

=
d
∑
i∈I
C
	​

	​

n
i
	​

	​

.

When bounded cancellation completes, the alternative result is

R
C
	​

=Cancel(R
C
	​

)=
d
C
	​

n
C
	​

	​

.

Both represent the same element of the exact rational-function field:

R
C
	​

=
R
C
	​

.

Selecting

R
C
stored
	​

=
X∈{R
C
	​

,
R
C
	​

}
argmin
	​

ByteCount(X)

is therefore only a representation choice. It does not alter the coefficient. A timeout or memory limit must select R
C
	​

, not a partially computed candidate, which is the stated behavior.

The full result follows inductively. At each iteration, the input list is partitioned into exact equal-denominator classes, and each class is replaced by an exactly equal rational function. Consequently,

i=1
∑
38306
	​

d
i
	​

n
i
	​

	​

=
j=1
∑
6557
	​

D
j
	​

N
j
	​

	​

.

No full hard-master Together is needed to establish this identity.

The measured outcome is favorable in every relevant resource:

422.3 MB⟶351.6 MB

in memory, and approximately

131.8 MB⟶99.9 MB

for the serialized data, with a fivefold wall-time improvement relative to eager cancellation. There is no mathematical reason to continue iterating once every remaining denominator hash is distinct. Since equal expressions necessarily have equal deterministic hashes, distinct hashes imply structural inequality; equal hashes still require the SameQ check already used to exclude collisions.

Durable artifact contents

For each final fraction, retain:

Wolfram Language
<|
  "Numerator" -> numerator,
  "Denominator" -> denominator,
  "Representation" -> "Raw" | "Cancelled" | "Singleton",
  "SourceClassID" -> classID,
  "SourceEntryCount" -> count,
  "SourceEntryManifestHash" -> sourceHash,
  "InputBytes" -> inputBytes,
  "RawPairBytes" -> rawBytes,
  "CancelledPairBytes" -> cancelledBytes,
  "SelectedPairHash" -> selectedHash,
  "TransformationStatus" -> status
|>

The complete artifact should retain:

Wolfram Language
"ExpectedEntryCount" -> 38306
"ExpectedLeafCount" -> 38366
"CoveredEntryCount" -> 38306
"CoveredLeafCount" -> 38366
"ExactClassPartitionVerified" -> True

The smaller and median whole-coefficient comparisons are valuable independent tests of the implementation. For the hard master, the compositional class certificates and exact source coverage are already a complete proof.

2. Dimensionless variables and a factor dictionary are now optional optimizations

Do not make either transformation an immediate requirement for the production result. The current representation is already compact enough to be retained as the exact answer, and further algebra can be evaluated independently.

The rational change of variables

x=−
s
t
	​

,y=−
s
u
	​

,

is exact because the physical chamber includes

s>0.

Its inverse is

t=−sx,u=−sy.

No logarithm, square root, or noninteger power is transformed, so this substitution has no branch ambiguity. It may reduce denominator diversity through identities such as

s+t=s(1−x),s+u=s(1−y),s+t+u=s(1−x−y).

However, it can also enlarge numerators, introduce additional powers of s, and make polynomial normalization expensive. The measured consolidation no longer creates an urgent need for it.

Benchmark dimensionless normalization separately

Use these deterministic calculations:

the complete median master, whose 25,328-byte whole result is known;

the 256 largest final hard-master fractions;

512 hard-master fractions stratified by numerator size, denominator size, and degree;

512 fractions chosen to maximize repeated denominator-factor occurrence.

Measure:

wall time;

maximum memory;

serialized size;

number of exact denominator classes;

total denominator term count;

maximum numerator size;

exact reconstruction status.

Adopt the transformation only if it gives a material improvement—for example, at least a 20% reduction in serialized size or peak memory—without creating substantially larger intermediate expressions.

Benchmark the factor dictionary only after that

A shared factor dictionary is valuable only if the denominators contain a small recurring factor alphabet. Define a denominator factorization

D
j
	​

=c
j
	​

α=1
∏
r
	​

f
α
e
jα
	​

	​

,

where c
j
	​

 is independent of the chosen polynomial variables. Its usefulness can be estimated by

ρ
reuse
	​

=
#{f
α
	​

}
j
∑
	​

α
∑
	​

1
e
jα
	​

>0
	​

	​

.

If ρ
reuse
	​

 is close to one, the dictionary adds complexity without meaningful compression. If a modest number of factors occurs throughout thousands of denominators, a factor table may reduce storage and accelerate later gcd-aware addition.

Factorization must remain bounded. An unresolved denominator is stored as one exact atomic factor; it is never approximated.

Thus the recommended order is:

retain the current 6,557-fraction artifact→benchmark (x,y) normalization→benchmark factor reuse→adopt only measured improvements.
	​

3. Keeping the smaller uncancelled raw pair is mathematically safe

There is no correctness defect in retaining

D
N
	​


instead of its cancelled form

D/g
N/g
	​

,g=gcd(N,D).

They are equal as meromorphic rational functions. Since the target deliverable is an exact analytic coefficient, meromorphic equality is the correct notion.

Cancel does not modify logarithmic branches or noninteger powers here. Any branch-sensitive objects are treated as exact coefficient-field elements, and no PowerExpand is involved.

Costs of an uncancelled representation

There are three possible later costs, none of which invalidates the result.

1. Removable singularities remain visible

The raw representation can display a denominator zero at which the numerator also vanishes:

N(z
0
	​

)=D(z
0
	​

)=0.

The rational function has a removable singularity there, but direct substitution into the raw pair may give 0/0. Any pointwise evaluation near such a location should first use a locally cancelled form. The durable record should mark raw pairs as "NotReduced".

2. A latent denominator match may be hidden

Suppose two raw classes are

gD
N
1
	​

	​

,
D
N
2
	​

	​

,

and g∣N
1
	​

. If the first class is stored raw because it is smaller, the two denominators do not match structurally even though cancellation would place both terms over D. This can prevent a later merge.

This is a compression issue, not an equality issue.

3. Later gcd or common-denominator operations can cost more

An uncancelled denominator may have higher degree and more factors than necessary. If that fraction later enters a larger merge, local cancellation may need to be repeated.

Again, this is optional future algebra. It does not require changing the durable artifact.

A cheap one-step look-ahead

Because the cancelled candidate was already computed for 207+10 selected classes and many raw-selected classes, retain the cancelled denominator hash even when the raw pair wins:

Wolfram Language
"SelectedRepresentation" -> "Raw"
"RawDenominatorHash" -> ...
"CancelledDenominatorHash" -> ...
"CancelledPairBytes" -> ...

Then inspect whether two or more raw-selected classes have the same cancelled-denominator hash, confirming equality with SameQ. Only those classes need a selective look-ahead:

materialize their cancelled forms;

merge the newly equal denominators;

compare the combined representation cost with the original raw classes;

retain the change only if exact equality is certified and total cost decreases.

This can discover globally beneficial cancellations that the local ByteCount rule misses, without another full consolidation sweep.

It is optional. If no repeated cancelled-denominator keys appear, the current stopping point is especially well justified.

Recommended stopping decision

The exact denominator consolidation should stop at the present result:

38,306 entrywise fractions⟶6,557 durable exact fractions.
	​


Retain:

the entrywise cleaned store as provenance;

the 6,557-fraction artifact as the primary computational representation;

the class manifests and raw/cancelled selection records as the compositional proof.

Do not immediately replace it by dimensionless variables, denominator factorization, a lazy tree, or a global rational expression. Those are now optional, separately benchmarked compression layers. The only low-cost additional analysis worth doing immediately is the cancelled-denominator look-ahead for raw-selected classes.
