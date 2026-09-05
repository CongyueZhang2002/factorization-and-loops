# NNLO Factorized Root Lift Correction

## Question

_The question was not preserved in the local bridge record._

## Pro response

You are correct. My previous recommendation to retain the physicalized Kira coefficient as a root-independent scalar does not apply to the current workflow. Here both factors are elements of the positive-root rational function field:

Φ(T)=
D
T
	​

(y)
N
T
	​

(y)
	​

,Φ(I)=
D
I
	​

(y)
N
I
	​

(y)
	​

,y=(y
a
	​

,y
b
	​

,y
h
	​

),

and therefore

Φ(TI)=Φ(T)Φ(I)=
D
T
	​

D
I
	​

N
T
	​

N
I
	​

	​

.
	​


The measured record confirms that the factorized route reproduces the old whole-product leaf exactly on the completed contribution, while the difficult contribution constructs a valid exact leaf in 7.07 seconds without attempting the old product-level rationalization. Measured factorized-leaf record

1. Retain the unnormalized pair at leaf level

Yes. Given the measured 309-second failure, retaining

{N
T
	​

N
I
	​

,D
T
	​

D
I
	​

}
	​


without monic normalization is preferable.

Monic normalization is not part of the mathematical definition of the rational function. It merely replaces

D
N
	​


by

D/c
N/c
	​

,c∈K
×
,

where K is the exact coefficient field containing s,t,u,ϵ, color factors, and inert analytic objects. It improves denominator matching only when the division by c is cheap. It is not needed for exactness.

At the leaf stage, the appropriate invariants are only:

N
T
	​

,N
I
	​

,D
T
	​

,D
I
	​

∈K[y
a
±1
	​

,y
b
±1
	​

,y
h
±1
	​

],
D
T
	​


≡0,D
I
	​


≡0,

and

Φ(T)D
T
	​

=N
T
	​

,Φ(I)D
I
	​

=N
I
	​

.

Sparse convolution then gives

N
TI
	​

=N
T
	​

⋆N
I
	​

,D
TI
	​

=D
T
	​

⋆D
I
	​

,

where ⋆ denotes exponent-vector convolution. There is no reason to divide every coefficient of the potentially enormous N
TI
	​

 by the leading coefficient of D
TI
	​

.

A suitable leaf is therefore:

Wolfram Language
<|
  "Numerator" -> nnloSparseMultiply[
    targetLeaf["Numerator"],
    imageLeaf["Numerator"]
  ],
  "Denominator" -> nnloSparseMultiply[
    targetLeaf["Denominator"],
    imageLeaf["Denominator"]
  ],
  "Normalization" -> "Unnormalized",
  "TargetCertificate" -> targetLeaf["CertificateID"],
  "ImageCertificate" -> imageLeaf["CertificateID"]
|>

Keep both numerator and denominator as canonically key-sorted sparse maps. Do not reconstruct them as large Mathematica expressions merely to store the leaf.

Optional lazy units

If either factor already has a cheaply identified root-independent unit,

Φ(T)=u
T
	​

D
T
	​

N
T
	​

	​

,Φ(I)=u
I
	​

D
I
	​

N
I
	​

	​

,

store u
T
	​

u
I
	​

 separately rather than distributing it into the product numerator:

Wolfram Language
<|
  "ScalarUnit" -> uT uI,
  "Numerator" -> sparseNumerator,
  "Denominator" -> sparseDenominator
|>

This is optional. The fully unnormalized pair is already exact.

2. Minimal compositional certificate

No direct simplification of

Φ(TI)−
D
T
	​

D
I
	​

N
T
	​

N
I
	​

	​


is required. It is enough to certify each factor and record that the product was formed by exact sparse convolution.

For the stripped target T, persist:

D
T
	​

Φ(T)−N
T
	​

=0.
	​


For the physicalized Kira image I, persist:

D
I
	​

Φ(I)−N
I
	​

=0.
	​


These two identities imply the product identity because

	​

D
T
	​

D
I
	​

Φ(TI)−N
T
	​

N
I
	​

=D
I
	​

Φ(I)(D
T
	​

Φ(T)−N
T
	​

)+N
T
	​

(D
I
	​

Φ(I)−N
I
	​

)=0.
	​


This is a complete algebraic proof. It avoids constructing the 29 MB product or its full difference.

Minimal persisted fields per factor

Each factor certificate should retain:

Wolfram Language
<|
  "SourceHash" -> ...,
  "BranchContextFingerprint" -> ...,
  "PositiveBaseCertificateFingerprint" -> ...,
  "FractionVariables" -> {xa, xb, zh},
  "RootVariables" -> {facetYa, facetYb, facetYh},
  "NumeratorHash" -> ...,
  "DenominatorHash" -> ...,
  "ExactData" -> True,
  "IntegerExponentKeys" -> True,
  "RootFreeCoefficients" -> True,
  "NonzeroDenominator" -> True,
  "ReconstructionStatus" -> "Verified"
|>

For the target certificate, also retain:

Wolfram Language
"DistributionFactor" -> f1[xa] f1[xb] D1[zh]
"DistributionStrippingStatus" -> "Verified"

For the Kira image, require instead:

Wolfram Language
"DistributionFree" -> True

The Kira image may contain x
a
	​

,x
b
	​

,z
h
	​

, but it must not contain PDFs, FFs, GLIs, unresolved FeynCalc tensor objects, or an independent D.

Product-leaf certificate

The product record needs only:

Wolfram Language
<|
  "Construction" -> "ExactSparseFractionProduct",
  "TargetCertificateID" -> ...,
  "ImageCertificateID" -> ...,
  "Numerator" -> productNumeratorMap,
  "Denominator" -> productDenominatorMap,
  "NumeratorConvolutionHash" -> ...,
  "DenominatorConvolutionHash" -> ...,
  "ReconstructionStatus" -> "VerifiedByComposition"
|>

The source and code fingerprints must identify the exact implementation of sparse convolution. A property test should separately establish that for admissible maps A,B,

P(A⋆B)=P(A)P(B),

where

P(A)=
ν
∑
	​

A
ν
	​

y
ν
.

Once that implementation invariant is established, it need not be re-proved by expanding every large product.

Factor-level reconstruction without a large Together

The cleanest implementation is a recursive exact fraction constructor. It maps the expression grammar through

Frac(a+b)=
D
a
	​

D
b
	​

N
a
	​

D
b
	​

+N
b
	​

D
a
	​

	​

,
Frac(ab)=
D
a
	​

D
b
	​

N
a
	​

N
b
	​

	​

,
Frac(a
n
)={
(N
a
n
	​

,D
a
n
	​

),
(D
a
−n
	​

,N
a
−n
	​

),
	​

n≥0,
n<0,
	​


after the branch-certified root lift. Every node is correct by construction. This is preferable to obtaining each factor’s fraction through a global Together, although your measured 3.766-second image lift is already acceptable if its local reconstruction certificate is retained.

3. Group exact unnormalized denominators first

There is no mathematical flaw in the proposed order:

exact unnormalized leaves⟶merge structurally equal denominators⟶cancel grouped numerators⟶attempt bounded normalization.
	​


For a group with identical denominator D,

i=1
∑
r
	​

D
N
i
	​

	​

=
D
∑
i=1
r
	​

N
i
	​

	​

.

This requires no denominator normalization and exposes cancellations in

N
group
	​

=
i
∑
	​

N
i
	​


before any expensive division by a denominator leading coefficient.

Required canonical form for grouping

“Equal denominator” should mean exact equality of canonical sparse maps:

every exponent key is an integer triple;

keys are sorted deterministically;

exact zero coefficients already recognized cheaply are removed;

coefficients themselves are not globally simplified merely for grouping.

For example:

Wolfram Language
nnloCanonicalSparseMap[map_Association] :=
  KeySortBy[
    Select[map, ! SameQ[#, 0] &],
    Identity
  ];

Use a hash for indexing, followed by exact SameQ on the canonical sparse maps to guard against hash collisions.

Without monic normalization, denominators differing by a root-independent unit—such as D and −D—will fall into different groups. That only misses an early merge; it does not alter the coefficient.

After grouping

For each denominator group:

add numerator maps exactly;

perform bounded exact cleanup on each resulting coefficient;

remove coefficients proved zero;

if the entire numerator vanishes, discard the group;

optionally cancel a common root-polynomial factor between numerator and denominator;

only then attempt monic normalization.

At this stage the numerator may be orders of magnitude smaller, so dividing it by a root-independent leading coefficient can become inexpensive.

A bounded normalization should have the semantics:

Wolfram Language
"VerifiedNormalized"
"TimedOutUnchanged"
"FailedUnchanged"

A timeout must retain the exact unnormalized group.

Prefer lazy normalization to distributing a unit

If the denominator is

D=c
D
,c∈K
×
,

store

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


as

Wolfram Language
<|
  "ScalarUnit" -> 1/c,
  "Numerator" -> N,
  "Denominator" -> Dhat
|>

rather than immediately replacing N by N/c. This produces a monic denominator key without traversing and simplifying every coefficient of the large numerator map.

The certificate is simply

D−c
D
=0.

When groups with the same 
D
 are merged, their scalar units multiply their numerator maps only at that later, smaller stage.

Remaining caveat

Exact denominator grouping does not capture cancellation between unequal denominators. Such cancellation still occurs when shard-level or complete-master groups are subsequently combined. Therefore:

grouping equal unnormalized denominators is an exact first reduction;

it must not be treated as a decomposition into independent sectors;

groups cannot be discarded or certified fraction-independent separately unless the relevant identity is proved.

Recommended immediate change

Replace the old contribution-level route

Wolfram Language
nnloFractionLeaf[
  targetCoefficient physicalImageCoefficient,
  60
]

with:

Wolfram Language
targetLeaf = nnloCertifiedFactorLeaf[
  strippedTargetCoefficient
];

imageLeaf = nnloCertifiedFactorLeaf[
  physicalImageCoefficient
];

productLeaf = <|
  "Numerator" -> nnloSparseMultiply[
    targetLeaf["Numerator"],
    imageLeaf["Numerator"]
  ],
  "Denominator" -> nnloSparseMultiply[
    targetLeaf["Denominator"],
    imageLeaf["Denominator"]
  ],
  "TargetCertificateID" -> targetLeaf["CertificateID"],
  "ImageCertificateID" -> imageLeaf["CertificateID"],
  "ReconstructionStatus" -> "VerifiedByComposition"
|>;

Then:

Wolfram Language
grouped = nnloMergeExactlyEqualUnnormalizedDenominators[
  productLeaves
];

and apply bounded cancellation or normalization only to the grouped records.

Given the measurements, this is the correct production direction: the expensive monic normalization is a compression optimization, not part of the analytic proof, and should occur only after exact addition has reduced the objects on which it acts.
