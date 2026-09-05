# NNLO Factorized Root Lift

## Question

_The question was not preserved in the local bridge record._

## Pro response

The factorized construction is mathematically correct and is the appropriate fix for these failures. The diagnostic shows that all eight sampled missing shards reached the same 60-second ceiling after all preceding physical checks had succeeded, for products from 1.58 MB to 28.94 MB. Diagnostic record

One source-level clarification: in the attached NNLOFractionRing.wl, nnloPositiveRootLift itself only performs the branch-certified substitutions. The expensive operation is the subsequent

Wolfram Language
Cancel[Together[lifted]]

inside nnloFractionLeaf. The diagnostic stage name therefore covers the root lift plus this global rationalization.

The strongest simplification is even narrower than the proposed four-step multiplication: the current driver already requires every physicalized Kira image coefficient to be exactly free of x
a
	​

,x
b
	​

,z
h
	​

. Therefore the Kira coefficient is an element of the root-independent coefficient field and does not need its own root-polynomial denominator at all.

1. Separate lifting is exact

Let

F
dist
	​

=f
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

)D
1
	​

(z
h
	​

),

and write a complete physical target coefficient as

C
α
	​

=F
dist
	​

C
α
	​

.

Let R
αm
	​

 be the physicalized Kira coefficient multiplying master M
m
	​

. Under the present driver contract,

R
αm
	​

∈K,FreeQ[R
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

}]=True,

where K contains s,t,u,ϵ, color structures, and fraction-independent analytic objects.

In the physical chamber

x
a
	​

>0,x
b
	​

>0,z
h
	​

>0,

define

x
a
	​

=y
a
2
	​

,x
b
	​

=y
b
2
	​

,z
h
	​

=y
h
2
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

>0.

On the allowed expression class

R=K[x
a
±1/2
	​

,x
b
±1/2
	​

,z
h
±1/2
	​

],

the map

Φ:R⟶K[y
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

]

defined by

Φ(x
a
n/2
	​

)=y
a
n
	​

,Φ(x
b
n/2
	​

)=y
b
n
	​

,Φ(z
h
n/2
	​

)=y
h
n
	​


is a ring homomorphism. Hence

Φ(
C
α
	​

R
αm
	​

)=Φ(
C
α
	​

)Φ(R
αm
	​

)=R
αm
	​

Φ(
C
α
	​

).

Therefore it is exact to:

strip F
dist
	​

 from the target alone;

lift the target alone;

leave the root-independent Kira coefficient unchanged;

multiply only after the target has been represented in the root ring.

No PowerExpand or identity involving products of noninteger powers is needed.

Required fail-closed condition

Separate lifting is valid only because every noninteger fraction power has one of the forms

x
a
n/2
	​

,x
b
n/2
	​

,z
h
n/2
	​

,n∈Z,

with the positive branch declared.

The lift must reject, rather than manipulate,

(x
a
	​

+x
b
	​

)
1/2
,(x
a
	​

x
b
	​

)
1/2
,(ux
a
	​

+tx
b
	​

)
−ϵ
,logx
a
	​

,Γ(x
a
	​

+ϵ),

unless a separate exact branch certificate has first converted the object into the admitted grammar.

In particular, explicitly reject every noninteger power whose base contains a fraction variable but is not exactly one of the three individual positive variables:

Wolfram Language
badCompositePowers = Cases[
  expression,
  HoldPattern[Power[base_, exponent_]] /;
      ! IntegerQ[exponent] &&
      ! FreeQ[
        Unevaluated[base],
        Alternatives @@ nnloFractionVariables
      ] &&
      ! MemberQ[nnloFractionVariables, Unevaluated[base]],
  Infinity
];

If[badCompositePowers =!= {}, Return[$Failed]];
2. The current Kira coefficient should be a lazy scalar

Because physicalImageCoefficient already enforces

Wolfram Language
FreeQ[
  physical,
  Alternatives @@ nnloFractionVariables
]

the cleanest contribution representation is

Φ(
F
dist
	​

C
α
	​

	​

R
αm
	​

)=R
αm
	​

D
α
	​

(y)
N
α
	​

(y)
	​

.

Do not form

Wolfram Language
product = targetCoefficient imageCoefficient

and do not copy R
αm
	​

 into every coefficient of N
α
	​

 immediately. Store it as a root-independent scalar:

Wolfram Language
<|
  "Scalar" -> physicalKiraCoefficient,
  "Numerator" -> targetNumeratorMap,
  "Denominator" -> targetDenominator,
  "Target" -> target,
  "Master" -> master
|>

with

y=(y
a
	​

,y
b
	​

,y
h
	​

).

This has three advantages:

the denominator is exactly the target denominator;

the potentially large Kira coefficient is stored once;

the 28.94 MB expanded product is never constructed.

When equal denominators are merged, form the numerator map coefficientwise:

N
D
	​

(y)=
α:D
α
	​

=D
∑
	​

R
αm
	​

N
α
	​

(y).

Only then should the scalar multiplications be materialized.

A concise implementation is:

Wolfram Language
nnloScaleSparseNumerator[
    numerator_Association,
    scalar_
  ] := Map[scalar # &, numerator];

nnloMaterializeLeaf[leaf_Association] := <|
  "Denominator" -> leaf["Denominator"],
  "Numerator" -> nnloScaleSparseNumerator[
    leaf["Numerator"],
    leaf["Scalar"]
  ],
  "LeafCount" -> 1
|>;

For large scalar coefficients, leaving "Scalar" separate until equal-denominator merging is preferable.

3. Exact reconstruction certificate

Suppose the stripped target and, in a more general implementation, the Kira coefficient have certified root-ring representations

Φ(
C
α
	​

)=
D
T
	​

N
T
	​

	​

,Φ(R
αm
	​

)=
D
R
	​

N
R
	​

	​

.

The local certificates are

D
T
	​

Φ(
C
α
	​

)−N
T
	​

=0,

and

D
R
	​

Φ(R
αm
	​

)−N
R
	​

=0.

Sparse multiplication constructs

N
P
	​

=N
T
	​

N
R
	​

,D
P
	​

=D
T
	​

D
R
	​

.

These two local identities imply

D
P
	​

Φ(
C
α
	​

R
αm
	​

)−N
P
	​

=0

because

	​

D
T
	​

D
R
	​

Φ(
C
α
	​

R
αm
	​

)−N
T
	​

N
R
	​

=D
R
	​

Φ(R
αm
	​

)[D
T
	​

Φ(
C
α
	​

)−N
T
	​

]+N
T
	​

[D
R
	​

Φ(R
αm
	​

)−N
R
	​

].
	​


Thus no direct simplification of the giant product difference is necessary.

In the current production case

Since

N
R
	​

=R
αm
	​

,D
R
	​

=1,

the product certificate reduces to:

the previously verified target-leaf certificate;

the exact check that R
αm
	​

 is root- and fraction-independent;

the exact sparse scaling identity

P(R
αm
	​

N
T
	​

)=R
αm
	​

P(N
T
	​

),

where P reconstructs a polynomial from its exponent map.

That third identity can be checked coefficientwise without Together:

Wolfram Language
scaledMap = Map[imageCoefficient # &, targetNumeratorMap];

scalingVerified = And @@ KeyValueMap[
  Function[{exponent, coefficient},
    SameQ[
      scaledMap[exponent],
      imageCoefficient coefficient
    ]
  ],
  targetNumeratorMap
];

Since the map is produced by this rule, the check is largely structural. The independent mathematical content is the certified target representation and the proof that the Kira coefficient lies in K.

Records to retain

Each contribution should record:

Wolfram Language
<|
  "Target" -> target,
  "Master" -> master,
  "TargetLeafHash" -> ...,
  "TargetLeafCertificate" -> "Verified",
  "KiraCoefficientHash" -> ...,
  "KiraCoefficientRootFree" -> True,
  "KiraCoefficientDistributionFree" -> True,
  "Construction" -> "RootFreeScalarTimesTargetFraction",
  "Scalar" -> imageCoefficient,
  "Numerator" -> targetNumeratorMap,
  "Denominator" -> targetDenominator
|>

Linearity then certifies every later sum.

4. Strip the distribution factor from the target only

This is also the physically correct placement. The Kira reduction coefficient is independent of PDFs and fragmentation functions, so require explicitly

Wolfram Language
FreeQ[
  imageCoefficient,
  _f1 | _D1 | _h1 | _H1
]

or the precise set of declared distribution heads.

The target artifact should already carry a certificate that

C
α
	​

=f
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

)D
1
	​

(z
h
	​

)
C
α
	​


and that 
C
α
	​

 contains no remaining distribution object.

Do not use only

Wolfram Language
quotient = Cancel[expression/nnloDistributionFactor];
expression - nnloDistributionFactor quotient

as the certificate. Since the quotient was defined by division, that check does not establish the intended distribution multiplicity. Either reuse the exact target-level common-factor certificate or atomize the three distribution objects and require the exact exponent vector

(1,1,1)

in every nonzero term.

5. Direct sparse fraction representation

Yes. Each contribution should be represented directly as

(S,N(y),D(y)),S∈K,
	​


rather than as one Mathematica expression.

A practical association is:

Wolfram Language
<|
  "Scalar" -> scalar,
  "NumeratorMap" -> numeratorMap,
  "DenominatorMap" -> denominatorMap,
  "LaurentShift" -> {ra, rb, rh}
|>

The separate Laurent shift is useful if negative root exponents are present. After the shift, numerator and denominator maps have nonnegative integer exponent keys.

Sparse multiplication

For a future case where both factors depend on the root variables,

Wolfram Language
productNumerator =
  nnloSparseMultiply[targetNumerator, imageNumerator];

productDenominator =
  nnloSparseMultiply[targetDenominator, imageDenominator];

is exact exponent-vector convolution.

For the current UU Kira map, do not call nnloSparseMultiply with a one-term image map. Keep the image as "Scalar".

Addition

Postpone addition across unequal denominators. The exact order should be:

build or retrieve the certified target fraction once;

attach each selected Kira scalar lazily;

merge equal target denominators;

form one exact partial master sum per shard;

multiply by the expected monomial

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

;

attempt the shard-level fraction-independence cancellation;

combine only unresolved shard nodes in a balanced tree.

This avoids both the per-product global Together and the unusable LCM over tens of thousands of raw leaves.

6. Best treatment of the 28.94 MB case

The best exact alternative is:

never construct the 28.94 MB product.
	​


For that contribution:

retrieve the already certified complete-target rational representation;

strip the distribution factor at target level;

lift the target once;

store its N
T
	​

,D
T
	​

;

retrieve the cached, fraction-free Kira coefficient R
αm
	​

;

create the lazy leaf

(R
αm
	​

,N
T
	​

,D
T
	​

).

No Together is required.

The target should be lifted only once even if its Kira image contains many masters. Cache by the target GLI and the analytic-context fingerprint:

Wolfram Language
targetLeafCache[target] = certifiedTargetRootLeaf;

This is more important than caching only repeated Kira image coefficients. The current code repeats nnloFractionLeaf for every target–selected-master pair even though the expensive target part is unchanged.

If the target itself is still difficult

The complete physical-target transformation already performed a certified whole-target rational merge. The most robust long-term change is to persist, alongside each physical target,

Wolfram Language
"FrozenNumerator"
"FrozenDenominator"
"AnalyticAtomDictionary"
"RationalMergeCertificate"

so the NNLO master driver never has to call Together on that target again.

For already written target files, perform the root conversion once per target. If even target-only conversion times out, use a balanced exact fraction tree over its additive terms:

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

⟶
d
1
	​

d
2
	​

n
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

	​

,

with local cross-multiplication certificates and unchanged-node fallback. This remains exact but should be needed only for exceptional targets.

7. Minimal patch to the current driver

Replace:

Wolfram Language
leaf = nnloFractionLeaf[
  targetCoefficient imageCoefficient,
  60
];

by:

Wolfram Language
targetLeaf = If[
  KeyExistsQ[targetLeafCache, target],
  targetLeafCache[target],
  With[
    {computed = nnloTargetFractionLeaf[targetCoefficient, 60]},
    If[MemberQ[{computed}, $Failed | $TimedOut],
      Return[$Failed, Module]
    ];
    AssociateTo[targetLeafCache, target -> computed];
    computed
  ]
];

If[
  ! FreeQ[
    imageCoefficient,
    Alternatives @@ Join[
      nnloFractionVariables,
      nnloRootVariables
    ]
  ] ||
    ! distributionFreeQ[imageCoefficient],
  Return[$Failed, Module]
];

leaf = Join[
  targetLeaf,
  <|
    "Scalar" -> imageCoefficient,
    "Master" -> master
  |>
];

Then modify nnloMergeFractionLeaves so that it combines

S
i
	​

N
i
	​


within each equal-denominator group instead of assuming each numerator has already been scaled.

Acceptance test

Rerun the same eight diagnostic shards. The acceptance criterion is:

all eight target leaves are constructed without a product-level Together;

no root-lift timeout occurs;

every physical Kira coefficient is root-, fraction-, and distribution-free;

each contribution reconstructs compositionally from the certified target leaf and Kira scalar;

the number of selected target–master contributions is unchanged;

any timeout retains the exact uncombined leaf and is reported as unresolved.

This construction preserves the exact analytic coefficient, physical branches, endpoint objects, cut-master identity, and BMHV data while removing the measured source of the timeout.
