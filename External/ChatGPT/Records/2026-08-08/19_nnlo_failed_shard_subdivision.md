# NNLO Failed Shard Subdivision

## Question

We implemented the shardwise exact positive-root factorization route discussed earlier and now have a sharply localized difficult case. Please assess the exact next step; do not propose numerical fitting.

Measured state:
- 256 NNLO shards and three selected master columns were scanned exactly on eight Mathematica kernels.
- A first shardwise extraction certified 246/256 shards completely.
- The remaining ten failures occur only in the hardest master column. Assembly succeeds; the universal-factor certificate times out or remains unresolved.
- For failed shard 237, 132 exact unnormalized denominator entries were divided into eight balanced blocks and evaluated on eight kernels.
- Seven blocks certified exactly as

    F_B(ya,yb,yh) = ya^(-2) yb^(-2) yh^(-4) H_B,

  with H_B independent of xa, xb, zh, ya, yb, yh.
- The sole unresolved block contains 22 entries. Merging equal denominators took 0.042 s and exact fraction assembly took 1.70 s. The assembled object is only 5.54 MB. The certificate then timed out at 300 s.
- Therefore the bottleneck is not constructing a common denominator. It is the coefficient zero test currently used in the proportionality certificate:

    n_k v_0 - n_0 v_k == 0,

  implemented by Cancel[Together[...]] over the remaining analytic coefficient field.

The other seven blocks have exact stored hard coefficients and hashes. No unresolved block is being treated as zero or accepted without proof.

Questions:
1. Is recursive exact subdivision of the 22-entry block mathematically sufficient if every child separately certifies the same universal monomial, followed by summing the child hard coefficients?
2. If individual children do not separately carry the universal monomial because cancellation is required across them, what exact grouping criterion should be used? A graph based on shared irreducible denominator factors, sparse root-monomial overlap, or another invariant?
3. Can the proportionality test be made cheaper by comparing the sparse root-polynomial maps before assembling analytic coefficients, or by choosing a pivot whose analytic coefficient is a monomial/unit? Please give a concrete exact algorithm.
4. What exact certificate should be stored for recursively subdivided blocks so that their sum proves the original shard identity without rebuilding the shard fraction?

The coefficient field contains exact rational functions in physical invariants and inert Gamma/log/power/BMHV atoms. Branch-sensitive powers must remain exact; PowerExpand and numerical sampling are forbidden.

## Pro response

1. Recursive subdivision is sufficient when every child certifies

Let the unresolved 22-entry block B contain the exact multiset of contributions

A
B
	​

={a
1
	​

,…,a
22
	​

},

and let a recursive subdivision produce a disjoint multiset partition

A
B
	​

=
r=1
⨆
R
	​

A
B
r
	​

	​

.

Define

F
B
r
	​

	​

(y
a
	​

,y
b
	​

,y
h
	​

)=
a∈A
B
r
	​

	​

∑
	​

f
a
	​

(y
a
	​

,y
b
	​

,y
h
	​

),

and

U(y
a
	​

,y
b
	​

,y
h
	​

)=y
a
−2
	​

y
b
−2
	​

y
h
−4
	​

.

If every child has an exact certificate

F
B
r
	​

	​

=UH
B
r
	​

	​

,H
B
r
	​

	​

∈K,

where K is the exact fraction-independent coefficient field, then

F
B
	​

	​

=
r=1
∑
R
	​

F
B
r
	​

	​

=U
r=1
∑
R
	​

H
B
r
	​

	​

.
	​


Therefore

H
B
	​

=
r=1
∑
R
	​

H
B
r
	​

	​

	​


is an exact result. The parent’s 5.54 MB rational expression never needs to be reconstructed.

This requires only:

the child contribution multisets are disjoint;

their multiset union is exactly the 22 original entries;

every child uses the same distribution stripping, positive-root map, branch registry, hadronic map, Kira artifact, and universal exponent;

each child’s result is proved, not merely returned unchanged after timeout;

each H
B
r
	​

	​

 is proved free of

x
a
	​

,x
b
	​

,z
h
	​

,y
a
	​

,y
b
	​

,y
h
	​

.

Recursive subdivision should therefore be the immediate next test. Start with 2 children of 11 entries, then split only the unresolved child. There is no need to begin with 22 single-entry tasks.

A timeout means only that the chosen child was too difficult for the checker. A proved nonzero cross-minor means that the child genuinely requires cancellation with another child.

2. When cancellation crosses child boundaries

If some children do not separately contain the universal monomial, they must be regrouped. The correct invariant is the exact root-dependent pole structure, not the syntactic analytic signature and not root-monomial overlap alone.

First multiply each unresolved child by U
−1
:

G
i
	​

(y)=U
−1
F
i
	​

(y)=y
a
2
	​

y
b
2
	​

y
h
4
	​

F
i
	​

(y)=
Q
i
	​

(y)
P
i
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

).

Cancel every exactly certified common root-polynomial factor of P
i
	​

 and Q
i
	​

. Then write the root-dependent denominator as

Q
i
	​

(y)=u
i
	​

α
∏
	​

q
α
	​

(y)
e
iα
	​

,u
i
	​

∈K
×
,

where the q
α
	​

 are monic irreducible polynomials in

K[y
a
	​

,y
b
	​

,y
h
	​

].
Exact denominator-factor graph

Construct a graph whose vertices are the unresolved children. Join i and j when

K[y]
gcd
	​

(Q
i
	​

,Q
j
	​

)∈
/
K
×
.

Equivalently, they are joined when their denominators contain a common root-dependent irreducible factor.

The connected components are exact independent units for cancellation of rational poles. To see this, consider an irreducible factor q. Only terms whose denominators contain q have negative q-adic valuation. Terms outside that component are regular on q=0 and cannot cancel its principal part.

Thus:

proper rational pieces in different denominator-factor components cannot cancel one another’s poles.
	​


If exact factorization times out, place the affected children in one conservative catch-all component. Do not infer independence from incomplete factorization.

Polynomial parts must be handled separately

A child may also have a polynomial contribution in the root variables. Under a fixed monomial order, perform exact division

P
i
	​

=A
i
	​

Q
i
	​

+R
i
	​

,

so that

G
i
	​

=A
i
	​

+
Q
i
	​

R
i
	​

	​

.

Accumulate all polynomial parts

A
tot
	​

(y)=
i
∑
	​

A
i
	​

(y)

as one sparse root-polynomial map. Nonconstant root monomials in A
tot
	​

 may cancel between denominator-factor components, so they must not be discarded or certified component by component.

The proper fractions R
i
	​

/Q
i
	​

 are processed by the denominator-factor graph.

Root-monomial overlap is only a scheduling heuristic

Sparse root-monomial overlap is useful after denominators have been aligned, but it is not a sound primary grouping rule. Two expressions with different current root monomials may generate the same monomials after multiplication by denominator quotients. Conversely, matching monomials do not imply that the corresponding poles can cancel.

Use:

shared irreducible denominator factors for exact grouping;

root-monomial overlap only to choose a merge order inside a component.

Within one component, merge pairs with the largest denominator gcd first:

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
g(Q
1
	​

/g)(Q
2
	​

/g)
P
1
	​

(Q
2
	​

/g)+P
2
	​

(Q
1
	​

/g)
	​

,g=gcd(Q
1
	​

,Q
2
	​

).

This is exact and avoids multiplying by the full product Q
1
	​

Q
2
	​

.

3. A cheaper exact proportionality test

The present test compares the sparse root-polynomial maps

P(y)=
ν
∑
	​

p
ν
	​

y
ν
,V(y)=
ν
∑
	​

v
ν
	​

y
ν
,

where the desired relation is

P=HV,H∈K.

The cross-minor criterion

p
ν
	​

v
ν
0
	​

	​

−p
ν
0
	​

	​

v
ν
	​

=0

is correct. The expense comes from asking Mathematica to canonicalize each coefficient difference from scratch with Cancel[Together[...]].

Step 1: work directly on sparse maps

Do not reconstruct P and V as complete expressions.

First take

K=keys(P)∪keys(V).

For any ν∈K:

if v
ν
	​

=0, then p
ν
	​

 must be zero;

if p
ν
	​

=0, then either H=0 or v
ν
	​

=0.

Run these one-coefficient zero tests first. They often remove many keys without constructing a cross-minor.

Step 2: choose the pivot by algebraic cost

Do not use the first nonzero v
ν
	​

. Choose a pivot ν
0
	​

 minimizing a deterministic complexity score for the pair

(p
ν
	​

,v
ν
	​

).

Prefer, in order:

v
ν
	​

=±1;

v
ν
	​

 a single exact monomial or root-independent unit;

v
ν
	​

 with a one-term numerator and denominator after analytic atoms are frozen;

minimal combined ByteCount, additive-term count, and denominator complexity of p
ν
	​

 and v
ν
	​

.

For example:

Wolfram Language
pivotScore[exponent_] := Module[
  {
    p = Lookup[pMap, exponent, 0],
    v = Lookup[vMap, exponent, 0]
  },
  {
    If[MemberQ[{1, -1}, v], 0, 1],
    If[simpleCoefficientUnitQ[v], 0, 1],
    ByteCount[p] + ByteCount[v],
    LeafCount[p] + LeafCount[v]
  }
];

pivot = First @ SortBy[
  certifiedNonzeroVKeys,
  pivotScore
];

If v
ν
0
	​

	​

 is a simple unit, compute

H=
v
ν
0
	​

	​

p
ν
0
	​

	​

	​


structurally and test

p
ν
	​

−Hv
ν
	​

=0.

This is usually substantially cheaper than fraction-free cross-minors.

Step 3: represent coefficient-field elements as exact fractions

Freeze the branch-sensitive objects with one block-wide dictionary:

Γ(⋯),log(⋯),(⋯)
a+bϵ
,BMHV tensors

become inert generators A
1
	​

,A
2
	​

,…. Apply all certified branch identities before freezing them. No PowerExpand is used.

Represent each coefficient only once as

c=
b
a
	​

,

where a and b are sparse polynomials in the physical invariants, color generators, and inert analytic generators. Construct this fraction by bounded termwise rational parsing and balanced exact merging, rather than by applying Together to every later cross-minor.

For

p
ν
	​

=
b
ν
	​

a
ν
	​

	​

,v
ν
	​

=
d
ν
	​

c
ν
	​

	​

,

and pivot

p
0
	​

=
b
0
	​

a
0
	​

	​

,v
0
	​

=
d
0
	​

c
0
	​

	​

,

the cross-minor vanishes if and only if

a
ν
	​

c
0
	​

b
0
	​

d
ν
	​

−a
0
	​

c
ν
	​

b
ν
	​

d
0
	​

=0.
	​


This is a sparse polynomial identity. It requires no Together and no division.

Use sparse exponent convolution for the products and Merge[...,Total] for subtraction. The result is zero exactly when every sparse polynomial coefficient is zero after the declared algebraic relations have been applied.

Conceptually:

Wolfram Language
coefficientCrossMinorZeroQ[p_, v_, p0_, v0_] := Module[
  {pf, vf, p0f, v0f, left, right, difference},

  pf  = coefficientFraction[p];
  vf  = coefficientFraction[v];
  p0f = coefficientFraction[p0];
  v0f = coefficientFraction[v0];

  If[MemberQ[{pf, vf, p0f, v0f}, $Failed | $TimedOut],
    Return["Unresolved"]
  ];

  left = sparsePolynomialProduct[
    pf["Numerator"],
    v0f["Numerator"],
    p0f["Denominator"],
    vf["Denominator"]
  ];

  right = sparsePolynomialProduct[
    p0f["Numerator"],
    vf["Numerator"],
    pf["Denominator"],
    v0f["Denominator"]
  ];

  difference = sparsePolynomialSubtract[left, right];

  If[
    AllTrue[Values[difference], exactBaseCoefficientZeroQ],
    True,
    False
  ]
];

The coefficient-fraction representations should be cached by HoldComplete[coefficient], because the same v
ν
	​

, pivot coefficient, and analytic atoms recur across checks.

Step 4: optional direct polynomial-division test

There is also a single-operation exact formulation. Treat P and V as polynomials only in {y
a
	​

,y
b
	​

,y
h
	​

}, with all other symbols belonging to the rational-function coefficient field. Compute

P=QV+R.

The universal-factor identity is established when

R=0

and

Q∈K

is independent of y
a
	​

,y
b
	​

,y
h
	​

.

In Wolfram Language:

Wolfram Language
{quotientList, remainder} = PolynomialReduce[
  sparseToPolynomial[pMap],
  {sparseToPolynomial[vMap]},
  {ya, yb, yh},
  CoefficientDomain -> RationalFunctions,
  MonomialOrder -> Lexicographic
];

verified =
  Length[quotientList] === 1 &&
  exactCoefficientZeroQ[remainder] === True &&
  FreeQ[First[quotientList], ya | yb | yh];

This is worth testing on the 5.54 MB block. If it is faster, it replaces all cross-minors with one exact division. If it times out, retain the sparse pivot algorithm above.

Do not infer inequality from a failed formal check

The inert analytic atoms are treated as algebraically independent after certified canonicalization. Therefore:

a proved zero is a valid analytic identity;

a formal nonzero may mean either genuine root dependence or a missing identity between analytic atoms;

a timeout remains unresolved.

Store these statuses separately.

4. Compositional certificate for recursively subdivided blocks

For every leaf contribution, retain its existing factorized-fraction certificate. For every recursively certified child B
r
	​

, retain:

Wolfram Language
<|
  "BlockID" -> blockID,
  "ParentBlockID" -> parentID,

  "ContributionIDs" -> contributionIDs,
  "ContributionManifestHash" -> manifestHash,
  "ContributionCount" -> Length[contributionIDs],

  "AnalyticContextFingerprint" -> contextHash,
  "BranchRegistryFingerprint" -> branchHash,
  "KiraFingerprint" -> kiraHash,
  "PositiveRootMapFingerprint" -> rootMapHash,

  "UniversalExponent" -> {-2, -2, -4},

  "NumeratorMapHash" -> numeratorHash,
  "DenominatorMapHash" -> denominatorHash,

  "PivotExponent" -> pivotExponent,
  "PivotCoefficientHash" -> pivotHash,
  "CoefficientCheckCount" -> checkCount,
  "CoefficientCheckStatuses" -> checkStatusManifest,

  "HardCoefficient" -> hardCoefficient,
  "HardCoefficientHash" -> hardHash,

  "FractionFree" -> True,
  "ExactData" -> True,
  "Status" -> "Verified"
|>

The parent certificate should not contain a rebuilt parent fraction. It needs only:

Wolfram Language
<|
  "ParentBlockID" -> parentID,
  "OriginalContributionIDs" -> originalIDs,

  "ChildCertificateIDs" -> childIDs,
  "ChildCertificateHashes" -> childHashes,

  "DisjointChildren" -> True,
  "CompleteMultisetUnion" -> True,

  "UniversalExponent" -> {-2, -2, -4},

  "HardCoefficient" ->
    Total[childHardCoefficients],

  "Derivation" ->
    "ExactLinearityFromCertifiedChildren",

  "FractionFree" -> True,
  "Status" -> "Verified"
|>

The two crucial identities are the multiset partition

A
B
	​

=
r
⨆
	​

A
B
r
	​

	​

,

and the child identities

F
B
r
	​

	​

=UH
B
r
	​

	​

.

They imply the parent result without another symbolic equality test.

A Merkle-tree arrangement is natural: each parent hash is formed from the ordered child hashes, universal exponent, analytic-context fingerprint, and contribution manifest. This makes interruption and recomputation safe without duplicating large expressions.

Recommended immediate test on the 22-entry block

Divide 22 into two balanced groups of 11.

Run the map-level certificate with pivot selection based on coefficient complexity.

If both certify, add their H's and close shard 237.

If one times out, subdivide only that group.

If a child is formally root-dependent:

multiply by U
−1
;

cancel exact numerator–denominator gcds;

separate polynomial and proper rational parts;

build the exact denominator-factor graph for the root-dependent pieces;

merge within each connected component using greatest-gcd-first ordering.

Replace Cancel[Together[crossMinor]] by cached coefficient fractions and sparse polynomial cross-products, or by the one-shot PolynomialReduce test if the measured result is better.

This preserves every branch-sensitive atom as an inert exact object and keeps the proof entirely analytic.
