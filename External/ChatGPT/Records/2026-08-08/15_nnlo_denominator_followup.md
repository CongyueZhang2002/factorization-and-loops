# NNLO Denominator Followup

## Question

Continue the same FACET-NLO discussion. I implemented the correctness-critical parts of your review before launching the eight-worker NNLO scan: missing Kira rows now fail unless the target is a declared master; every terminal GLI must be one of the 342 declared masters; conflicting duplicate rules fail; source and output hashes define reusable shard artifacts; completed master columns must reproduce their catalogue target counts; and complete-column assembly is now a two-scan, disk-backed balanced sparse merge rather than entries = Join[...]. The exact synthetic fraction tests give 29/29 True, all six real NLO UU masters reconstruct exactly and are fraction-free, and the previously failing real NNLO leaf is now represented with denominator ya^2 yb^2 yh^4.

The first completed large NNLO shards reveal an important measured fact. Typical shards have about 153-160 selected leaves, but 142-150 structurally distinct normalized denominators. Thus the current common-denominator fallback that multiplies two denominators whenever neither divides the other is not acceptable for the 38,366-target hard column. The running scan is only constructing certified shard records, so it is still useful; I will not trust the hard-column stage with that denominator rule.

Please assess the best exact next step using these measured counts:

1. Is your coefficient-field factor-profile LCM still the preferred construction when almost every leaf initially has a distinct denominator? Give the most concise Wolfram Language design that treats ya,yb,yh as polynomial variables and all physical/analytic objects as coefficient-field elements, including normalization, bounded factorization fallback, and exact divisibility checks.

2. Would it be mathematically and computationally better to sum all target contributions to a given selected master inside each shard before positive-root fraction decomposition, so cancellations occur before denominators are catalogued? The physicalized expressions in one shard are exact but can be several MB. Compare this with decomposing every target contribution first and merging denominator factors later.

3. Because the expected final dependence is H/(ya^2 yb^2 yh^4), is there an exact extraction/certificate that avoids constructing a global LCM, for example obtaining H at a nonsingular root point and then proving fraction independence by a sparse polynomial identity? It must remain a fully analytic derivation, not numerical sampling.

Please distinguish mathematical equivalence from expected Mathematica cost. The deliverable is the exact analytic coefficient, and no numerical evaluator may replace it.

## Pro response

Main conclusion

The measured ratio

153–160 leaves⟶142–150 distinct normalized denominators

changes the preferred order.

Do not construct a coefficient-field LCM from the individual target–master leaves. First sum all contributions to the selected master within each shard, multiply by the expected universal root monomial

M(y
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

,

and perform one bounded, branch-safe rational merge on that partial master sum. Attempt the universal-factor certificate immediately. Only residual shard sums that remain root-dependent should enter denominator factorization or an LCM calculation.

Thus the recommended hierarchy is

contributions→shard-level partial master→M×partial master→local rational cancellation→universal-factor certificate→factor-profile fallback only if unresolved.
	​


The current certified leaf scan is still useful: its records can be reconstructed into exact shard sums without rerunning the targets.

1. Role of the coefficient-field factor-profile LCM
It remains the correct LCM construction, but only as a fallback

The raw number of structurally distinct denominators does not determine the number of distinct irreducible factors. For example, 150 denominators could be different products of ten recurring factors. Therefore a factor-profile diagnostic is still worthwhile.

But if factorization reveals nearly one new irreducible factor per denominator, the LCM

L=
q
∏
	​

q
max
i
	​

e
i,q
	​


will itself grow essentially linearly with the number of leaves, while each lifted numerator N
i
	​

L/D
i
	​

 can grow combinatorially. That is exactly the regime in which a global common denominator is the wrong primary representation.

Use factor profiles only after:

contributions have been summed within a shard;

the expected monomial M has been multiplied in;

exact rational cancellation has been attempted;

certified root-independent partial results have been removed from further fraction processing.

Then there are at most 256 unresolved shard nodes rather than 38,366 leaves, and probably substantially fewer.

Coefficient field

Let

y=(y
a
	​

,y
b
	​

,y
h
	​

),

and let

K=Frac(Q[s,t,u,ϵ,color symbols,inert analytic atoms]).

All known identities among the physical and analytic objects must be applied before they are frozen. After that, the frozen atoms are treated as algebraically independent coefficient-field generators. Missing identities can make the factorization less economical, but cannot make a certified equality false.

The denominator algebra is then performed in

K[y].

A bare PolynomialGCD or analogous full-expression LCM is not the desired operation because the documented polynomial GCD treats all symbolic parameters as polynomial variables. By contrast, PolynomialReduce with the root variables explicitly supplied works over rational functions of the remaining parameters, which matches the intended coefficient field. 
Wolfram Documentation Center
+2
Wolfram Documentation Center
+2

Canonical denominator normalization

For every denominator D, obtain

D=u
D
	​

D
,u
D
	​

∈K
×
,

where 
D
∈K[y] is monic in a fixed lexicographic order.

The numerator must be adjusted simultaneously:

D
N
	​

=
D
N/u
D
	​

	​

.

A concise Wolfram Language skeleton is:

Wolfram Language
rootVariables = {ya, yb, yh};

rootFreeQ[expr_] :=
  FreeQ[Unevaluated[expr], Alternatives @@ rootVariables];

normalizeRootDenominator[d_] := Module[
  {rat, numerator, coefficientDenominator, rules, leadingRule,
   leadingCoefficient, monic, unit},

  rat = Cancel[Together[d]];
  numerator = Expand[Numerator[rat]];
  coefficientDenominator = Denominator[rat];

  If[
    ! rootFreeQ[coefficientDenominator] ||
      ! PolynomialQ[numerator, rootVariables],
    Return[$Failed]
  ];

  rules = CoefficientRules[numerator, rootVariables];
  If[rules === {}, Return[$Failed]];

  (* Fixed lexicographic convention for exponent vectors. *)
  leadingRule = Last @ SortBy[rules, First];
  leadingCoefficient = Last[leadingRule];

  monic = Cancel[numerator/leadingCoefficient];
  unit = Cancel[leadingCoefficient/coefficientDenominator];

  If[
    ! rootFreeQ[unit] ||
      ! PolynomialQ[monic, rootVariables] ||
      ! TrueQ[nnloExactZeroQ[d - unit monic, 60]],
    Return[$Failed]
  ];

  <|
    "Unit" -> unit,
    "MonicDenominator" -> monic
  |>
];
Bounded factor profile

To factor 
D
 over K:

use one deterministic, column-wide registry to freeze composite analytic objects;

clear denominators of the coefficients of 
D
 as a polynomial in y;

factor the resulting primitive polynomial over the ordinary polynomial ring;

discard factors independent of y, since they are units in K;

normalize every root-dependent factor to monic form;

reconstruct 
D
 up to a root-independent unit.

This is justified by the ordinary primitive-polynomial factorization over the coefficient ring. FactorList supplies the irreducible factor list, while FactorTermsList[poly,{ya,yb,yh}] can separate factors independent of the designated root variables. 
Wolfram Documentation Center
+1

Conceptually:

Wolfram Language
factorProfile[d_, seconds_: 30] := Module[
  {normalized, monic, frozen, thawRules, coefficients,
   coefficientDenominators, clearingFactor, polynomial,
   factorization, rootFactors, profile, reconstructed, ratio},

  normalized = normalizeRootDenominator[d];
  If[normalized === $Failed, Return[$Failed]];

  monic = normalized["MonicDenominator"];

  {frozen, thawRules} =
    freezeCoefficientAtoms[monic];  (* One persistent registry per column. *)

  coefficients = Last /@ CoefficientRules[frozen, rootVariables];

  coefficientDenominators =
    DeleteDuplicates[
      Denominator[Cancel[Together[#]]] & /@ coefficients
    ];

  If[! AllTrue[coefficientDenominators, rootFreeQ],
    Return[$Failed]
  ];

  (* Any exact common multiple suffices here. *)
  clearingFactor = Times @@ coefficientDenominators;
  polynomial = Expand[clearingFactor frozen];

  factorization = TimeConstrained[
    FactorList[polynomial],
    seconds,
    $TimedOut
  ];

  If[factorization === $TimedOut,
    (* Exact but potentially nonminimal fallback. *)
    Return[<|
      "Profile" -> <|monic -> 1|>,
      "FactorizationStatus" -> "Unresolved"
    |>]
  ];

  rootFactors = Cases[
    Rest[factorization],
    {factor_, exponent_Integer?Positive} /;
        ! rootFreeQ[factor] :>
      {canonicalRootMonic[factor /. thawRules], exponent}
  ];

  profile = Merge[
    AssociationThread[First /@ rootFactors, Last /@ rootFactors],
    Total
  ];

  reconstructed = Times @@
    KeyValueMap[#1^#2 &, profile];

  ratio = Cancel[Together[monic/reconstructed]];

  If[
    ! rootFreeQ[ratio] ||
      TrueQ[nnloExactZeroQ[ratio, 60]],
    Return[$Failed]
  ];

  <|
    "Profile" -> profile,
    "Unit" -> ratio,
    "FactorizationStatus" -> "Complete"
  |>
];

If bounded factorization fails, treating the complete monic denominator as one factor remains exact. It merely produces an overlarge common multiple.

LCM profile and divisibility

For profiles

D
i
	​

=u
i
	​

q
∏
	​

q
e
i,q
	​

,

define

E
q
	​

=
i
max
	​

e
i,q
	​

,L=
q
∏
	​

q
E
q
	​

.

In Wolfram Language:

Wolfram Language
lcmProfile = Merge[Lookup[profiles, "Profile"], Max];

commonDenominator =
  Times @@ KeyValueMap[#1^#2 &, lcmProfile];

The fastest exact quotient is obtained directly from the profiles:

Q
i
	​

=u
i
−1
	​

q
∏
	​

q
E
q
	​

−e
i,q
	​

,Q
i
	​

D
i
	​

=L.

The primary certificate should therefore be the exact reconstruction of every denominator from its factor profile. As an independent audit, use

Wolfram Language
{quotients, remainder} = PolynomialReduce[
  commonDenominator,
  {monicDenominator},
  rootVariables,
  CoefficientDomain -> RationalFunctions
];

and require

Wolfram Language
Length[quotients] === 1 &&
TrueQ[nnloExactZeroQ[remainder, 60]] &&
PolynomialQ[First[quotients], rootVariables]

PolynomialReduce explicitly returns the quotient representation and remainder, and its rational-function coefficient domain treats all symbols outside the listed polynomial variables as coefficient parameters. 
Wolfram Documentation Center
+1

2. Sum inside each shard before fraction decomposition
Mathematical equivalence

For shard s, target t, and master m, write the contribution as

C
t
	​

R
tm
	​

,

where C
t
	​

 is the complete physical target coefficient and R
tm
	​

 is the physicalized Kira coefficient.

The current leaf-first route constructs

F
sm
	​

=
t∈s
∑
	​

Leaf(C
t
	​

R
tm
	​

).

The proposed route first forms

F
sm
	​

=
t∈s
∑
	​

C
t
	​

R
tm
	​


and performs the root-ring decomposition only once. These are mathematically identical because the root lift, addition, and multiplication are exact field operations.

A further exact reduction is available when the same image coefficient occurs repeatedly. Let ρ run over the distinct physicalized Kira coefficients in the shard:

F
sm
	​

=
ρ
∑
	​

ρ
	​

t∈s
R
tm
	​

=ρ
	​

∑
	​

C
t
	​

	​

.

This should be performed before multiplying out the image coefficients.

Expected Mathematica cost

Under the measured counts, sum-first is strongly preferred:

leaf-first normalizes roughly 150 rational functions separately;

almost none of their complete denominators coincide;

all cross-target cancellations are postponed;

factorization and LCM bookkeeping are paid before knowing which poles cancel.

Sum-first processes one several-megabyte partial master expression. That is larger than an individual leaf, but it allows the exact cancellations that the final fraction-free hard coefficient requires.

Use a balanced merge rather than raw repeated Join or a single unrestricted Together:

Wolfram Language
mergePartialMaster[expressions_List] :=
  balancedMerge[
    expressions,
    Function[{left, right},
      certifiedFrozenRationalMerge[left + right]
    ]
  ];

The merge ordering by ByteCount, estimated term count, or denominator overlap is heuristic. The equality at every node is exact.

If a bounded merge times out, retain the unchanged pair of children as an unresolved exact node. A timeout is not a mathematical failure and must not be recorded as a changed expression.

Recommended shard calculation

For every selected master in every shard:

collect all C
t
	​

R
tm
	​

;

group identical R
tm
	​

;

sum the corresponding C
t
	​

;

apply the certified positive-root substitution;

multiply by M=y
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

;

perform a bounded frozen whole-rational merge;

try the root-independence certificate;

if successful, store a root-free hard shard coefficient;

otherwise store one unresolved exact rational node for the entire shard.

This reduces the hard column from approximately 38,366 leaves to at most 256 shard nodes before any column-wide denominator operation.

Because the current leaf scan is already certified, it need not be discarded. Each shard’s existing leaves can be reconstructed exactly, summed, multiplied by M, and recertified.

3. Avoiding a global LCM with a direct universal-factor certificate

This should be the primary method.

Let

F
m
	​

(y)

be the complete coefficient after stripping the distribution functions, and define

G
m
	​

(y)=M(y)F
m
	​

(y),M(y)=y
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

.

The required statement is

G
m
	​

(y)=H
m
	​

,H
m
	​

∈K.
Necessary-and-sufficient local certificate

After applying all certified branch identities and freezing the nonrational analytic objects, write the reduced rational expression as

G
m
	​

(y)=
D
m
	​

(y)
N
m
	​

(y)
	​

,gcd(N
m
	​

,D
m
	​

)=1.

Then G
m
	​

∈K if and only if:

D
m
	​

 is independent of y
a
	​

,y
b
	​

,y
h
	​

;

every nonconstant root monomial in N
m
	​

 has zero coefficient.

Equivalently,

D
m
	​

∈K
×
,

and

N
m
	​

(y)=n
0
	​

,[y
α
]N
m
	​

=0for every α

=0.

This is necessary and sufficient under the stated rational positive-root input class.

A concise implementation is:

Wolfram Language
universalMonomial = ya^2 yb^2 yh^4;

certifyUniversalNode[f_] := Module[
  {frozen, thawRules, merged, numerator, denominator,
   coefficientRules, nonconstantRules, hard, reconstruction},

  {frozen, thawRules} = freezeCoefficientAtoms[
    universalMonomial f
  ];

  merged = certifiedFrozenRationalMerge[frozen];
  If[MemberQ[{$Failed, $TimedOut}, merged],
    Return[<|"Status" -> "Unresolved"|>]
  ];

  merged = Cancel[Together[merged]];
  numerator = Expand[Numerator[merged]];
  denominator = Denominator[merged];

  If[
    ! rootFreeQ[denominator] ||
      ! PolynomialQ[numerator, rootVariables],
    Return[<|"Status" -> "RootDependent"|>]
  ];

  coefficientRules = CoefficientRules[
    numerator,
    rootVariables
  ];

  nonconstantRules = Select[
    coefficientRules,
    First[#] =!= {0, 0, 0} &&
      ! TrueQ[nnloExactZeroQ[Last[#], 60]] &
  ];

  If[nonconstantRules =!= {},
    Return[<|
      "Status" -> "RootDependent",
      "NonconstantMonomials" -> First /@ nonconstantRules
    |>]
  ];

  hard = Cancel[
    Lookup[
      Association[coefficientRules],
      {0, 0, 0},
      0
    ]/denominator
  ] /. thawRules;

  reconstruction = nnloExactZeroQ[
    universalMonomial f - hard,
    120
  ];

  If[! TrueQ[reconstruction], Return[$Failed]];

  <|
    "Status" -> "Verified",
    "HardCoefficient" -> hard,
    "FractionFree" -> True
  |>
];

Together and Cancel are being used only in the frozen rational ring, where they perform exact rational-function transformations; no logarithm, Gamma function, noninteger power, BMHV object, or branch-sensitive expression participates in that algebra. 
Wolfram Documentation Center

Certificate tree

Apply this certificate to each shard-level G
sm
	​

=MF
sm
	​

.

If G
sm
	​

=H
sm
	​

∈K, remove it from all future root-denominator work.

Sum the certified pieces as

H
m
certified
	​

=
s
∑
	​

H
sm
	​

.

Merge only the unresolved G
sm
	​

 nodes in a balanced tree.

Retry the certificate after every merge.

If all nodes eventually certify, then

F
m
	​

=
y
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

H
m
certified
	​

+H
m
merged
	​

	​


has been proved without ever constructing a common denominator over all 38,366 leaves.

The retained proof record should contain, for every merge node:

Wolfram Language
"ChildHashes"
"InputHash"
"Transformation"
"EqualityStatus"
"RootIndependenceStatus"
"OutputHash"
"BranchRegistryFingerprint"

Linearity then proves the complete column from the local certificates.

4. Why an exact root point is not enough

Choose an exact positive rational point

ρ=(ρ
a
	​

,ρ
b
	​

,ρ
h
	​

)∈Q
>0
3
	​


at which every denominator is nonzero, and define

H
ρ
	​

=M(ρ)F
m
	​

(ρ).

This gives an exact candidate for H
m
	​

, but it does not prove that

M(y)F
m
	​

(y)=H
ρ
	​

.

Evaluation at one point is not injective: a nonconstant rational function can have the same value at ρ.

An exact deterministic interpolation proof would be possible if rigorous multidegree bounds were available and enough exact rational points were evaluated. That would not be numerical interpolation in the approximate sense, but it would usually require a grid whose size is governed by the denominator-cleared degree—precisely the quantity that becomes large in the present problem. It is therefore unlikely to improve either memory or CPU cost.

Similarly, proving

∂y
a
	​

∂
	​

(MF
m
	​

)=
∂y
b
	​

∂
	​

(MF
m
	​

)=
∂y
h
	​

∂
	​

(MF
m
	​

)=0

would be sufficient together with one exact anchor value, but checking those three rational identities requires essentially the same denominator algebra as checking MF
m
	​

−H=0.

Exact point values can be retained as independent diagnostics, but they cannot replace the symbolic certificate. This is also consistent with the project requirement that numerical or fixed-point data remain verification rather than the analytic result. 

AGENTS

5. Recommended next experiment

Use the already completed certified shard leaves for the hard master.

For 8–16 representative shards:

reconstruct the exact selected-master shard sum from the saved leaves;

multiply by M=y
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

;

perform the bounded whole-rational merge;

run certifyUniversalNode;

record:

input and output bytes;

number of leaves;

whether the shard becomes root-free;

residual denominator term count;

number of irreducible root-dependent factors if unresolved;

time and peak memory.

The decision is then exact:

If shard nodes become root-free: continue with hard-coefficient accumulation; no LCM is required.

If pairs or small groups of shard nodes become root-free: use the balanced certificate tree.

If unresolved nodes remain but share a small factor inventory: use the coefficient-field factor-profile LCM on only those nodes.

If the irreducible factor inventory grows approximately with the unresolved-node count: do not construct the global LCM; continue cancellation-first balanced merging, with disk spill and exact unchanged-node fallback.

The key distinction is:

summing contributions, multiplying by M, factor-profile reconstruction, and every accepted rational rewrite are exact algebra;

choosing shard boundaries, merge order, time limits, and which denominator to factor first affects only resource use.

The best immediate production representation is therefore not

i=1
∑
38366
	​

D
i
	​

N
i
	​

	​

⟶
lcm(D
1
	​

,…,D
38366
	​

)
N
	​

,

but

G
m
	​

=y
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

s=1
∑
256
	​

(
t∈s
∑
	​

C
t
	​

R
tm
	​

),
	​


with exact cancellation and root-independence certification applied first to each shard and then along a balanced merge tree.
