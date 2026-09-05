# Hadronic Simplification Followup

## Question

Continue the same FACET hadronic-coefficient discussion. I am attaching the exact measured NLO UU benchmark summary.

New exact result: an earlier diagnostic used a mojibake symbol instead of FeynFacet`\[Alpha]s. After correcting that error and applying only branch-certified square-root identities, every one of the seven reduced UU master coefficients has the same Laurent valuation {-1,-1,-2} in {xa,xb,zh}. After removing

  FeynFacet`\[Alpha]s^3 FeynFacet`D1[zh] FeynFacet`f1[xa] FeynFacet`f1[xb]/(xa xb zh^2),

each coefficient is exactly FreeQ of xa, xb, zh. Thus collinear factorization is satisfied analytically.

Measured routes for 100 NLO UU pairs, 116 summed targets, and seven masters are in the attachment. Target-first is much faster than master-only. Target followed by bounded master cleanup is smaller than target-only. On the largest target, simplifying each additive term separately took 4.84 s and produced 49 kB, whereas Simplify of the complete coefficient took 86.4 s and produced 328 kB. A global Cancel[Together] after radical normalization increased the seven coefficients from about 1.04 MB to 2.60 MB.

Please now give a concrete exact algorithm for the complete-coefficient cleanup that captures cancellations missed by termwise Simplify without invoking global Together on the full coefficient. In particular:

1. Define useful signatures for grouping additive terms in UU and TT (distribution/PDF/FF, color, azimuthal tensor, BMHV or gamma-function structure, and branch-certified radical monomial).
2. State which objects should be inert while rational functions of s,t,u,Epsilon are combined.
3. Explain how to certify exact reconstruction and branch preservation.
4. Advise whether the common xa xb zh monomial should be stripped at target level, master level, or both.
5. Give Mathematica-level pseudocode concise enough to implement, but organize the answer around the analytic coefficient, not software architecture.

The main output must remain an exact analytic function; numerical values are checks only.

## Pro response

The measured result supports a two-stage exact cleanup:

sum and normalize each target coefficient first, then perform a bounded normalization of each summed master coefficient.
	​


The benchmark gives 23.72 s for target-first normalization, while master-only remained unfinished beyond 281 s. Target normalization followed by master cleanup produced the smallest final master data, about 1.04 MB, whereas a global Cancel[Together[...]] increased the coefficient set from about 1.04 MB to 2.60 MB. BenchmarkSummary.wl

The benchmark association still contains the older fields

Wolfram Language
"CommonFactor" -> alphaS^3 D1[zh] f1[xa] f1[xb]/zh^2
"FractionFreeAfterCommonFactor" -> False

so those two fields predate the corrected FeynFacetα
s
	​

 diagnostic. For the physics acceptance criterion, the corrected result in the prompt is authoritative:

F
UU
	​

=
x
a
	​

x
b
	​

z
h
2
	​

α
s
3
	​

D
1
	​

(z
h
	​

)f
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

)
	​

,

and every reduced master coefficient satisfies

C
m
	​

=F
UU
	​

H
m
	​

(s,t,u,ϵ;color),FreeQ[H
m
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
1. Decompose the complete coefficient by analytic signature

For a summed target or master coefficient C, use a decomposition

C=
σ
∑
	​

S
σ
	​

R
σ
	​

,

where S
σ
	​

 is an inert analytic signature and R
σ
	​

 is a rational function. Before the hadronic monomial has been removed,

R
σ
	​

∈Q(s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

).

After removing the certified common factor,

R
σ
	​

∈Q(s,t,u,ϵ).

The signature should be the tuple

σ=(σ
dist
	​

,σ
col
	​

,σ
az
	​

,σ
BMHV
	​

,σ
an
	​

,σ
rad
	​

).

Terms are combined only when all six entries agree.

Distribution and coupling signature

This records the exact product of coupling powers, PDFs, FFs, and any endpoint distributions:

σ
dist
	​

=α
s
n
α
	​

	​

i
∏
	​

f
i
	​

(x
i
	​

)
j
∏
	​

D
j
	​

(z
j
	​

)
k
∏
	​

D
k
	​

.

For the present UU channel,

σ
dist
UU
	​

=α
s
3
	​

f
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

).

The arguments are part of the signature. Thus f
1
	​

(x
a
	​

) and f
1
	​

(x
b
	​

) are distinct atoms even when the functional head is the same.

For TT, the corresponding products involving h
1
	​

, H
1
	​

, or whichever correlators occur in the declared projector remain distinct signatures. Do not combine different partonic distributions merely because their scalar coefficients happen to be algebraically identical.

Color signature

First reduce the color algebra to one fixed basis. Do not allow one part of the calculation to use C
F
	​

,C
A
	​

,T
F
	​

 while another uses unreduced powers of N
c
	​

.

For example, choose either

C
λ
	​

∈{C
F
3
	​

,C
F
2
	​

C
A
	​

,C
F
	​

C
A
2
	​

,C
F
2
	​

T
F
	​

n
f
	​

,…},

or a fixed Laurent basis in N
c
	​

, but not both. Then

σ
col
	​

=C
λ
	​

.

Any exact color identity must be applied before assigning the signature. Otherwise, expressions such as

C
F
	​

−
2
C
A
	​

	​


and their equivalent N
c
	​

-representations would be placed into different groups and a legitimate cancellation would be missed.

Azimuthal or spin-tensor signature

UU has only

σ
az
UU
	​

=1.

For TT, choose one exact independent basis and reduce every spin contraction to it before grouping. Depending on the projector convention, this can be a covariant tensor basis,

A
λ
	​

∈{S
Ta
	​

⋅S
Th
	​

,(S
Ta
	​

⋅
x
^
)(S
Th
	​

⋅
x
^
),…},

or a harmonic basis such as

A
λ
	​

∈{cos(ϕ
a
	​

−ϕ
h
	​

),cos(ϕ
a
	​

+ϕ
h
	​

),…}.

Use one basis throughout. Trigonometric identities must be applied before signature assignment; otherwise equivalent forms such as products of sines and cosines will not be combined.

BMHV signature

The BMHV entry records only declared, irreducible scheme-dependent scalar or tensor structures after the Dirac algebra is complete:

σ
BMHV
	​

=E
λ
	​

.

An unresolved object such as

DiracTrace[⋯],γ
μ
,
ℓ
2
,SPE[ℓ,⋯]

with an integration momentum is not an inert signature. It is an error at this stage. The coefficient cleanup should fail if such an object survives.

If the BMHV calculation has already reduced all evanescent dependence to rational factors of D−4=−2ϵ, those factors belong to R
σ
	​

, not to the inert signature.

Analytic-function signature

Treat the following as inert unless a separately certified identity has already put them in a common basis:

Γ(⋯),(a)
n
	​

,log(⋯),Li
n
	​

(⋯),
2
	​

F
1
	​

(⋯),ζ
n
	​

,

together with

X
a+bϵ

when a+bϵ∈
/
Z.

Integer shifts of Gamma functions may be normalized using the meromorphic identity

Γ(z+n)=(z)
n
	​

Γ(z),n∈Z,

but logarithm, polylogarithm, and noninteger-power transformations must not be inferred from algebraic appearance alone.

In particular, do not use

(ab)
ϵ
=a
ϵ
b
ϵ

unless the physical chamber proves the required signs and the branch convention explicitly permits the factorization.

Radical signature

Use only the branch-certified positive radicals already introduced for the direct coordinates, for example

r
s
2
	​

=
2x
a
	​

x
b
	​

s
	​

,r
T
2
	​

=
s
tu
	​

,r
s
	​

>0,r
T
	​

>0.

Every integer radical power can be reduced to

r
s
e
s
	​

	​

r
T
e
T
	​

	​

,e
s
	​

,e
T
	​

∈{0,1},

with all even powers absorbed into the rational coefficient. Hence

σ
rad
	​

=(e
s
	​

,e
T
	​

).

The four possible sectors are

1,r
s
	​

,r
T
	​

,r
s
	​

r
T
	​

.

In UU, all sectors except 1 must cancel in the complete target or master coefficient. A surviving odd-radical sector should cause failure; it must not be removed with PowerExpand.

2. Objects that remain inert

When combining rational functions, atomize all of the following:

α
s
	​

, PDFs, FFs, and distributional objects;

the chosen color-basis monomial;

the chosen TT tensor or azimuthal harmonic;

declared irreducible BMHV structures;

Gamma, Pochhammer, logarithm, polylogarithm, zeta, and hypergeometric objects;

all noninteger powers;

the certified radical monomial;

any physical branch label carried by an analytic object.

After atomization, the only active algebra should involve

{s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

}

before hadronic-factor removal, and

{s,t,u,ϵ}

afterward.

Also impose

q
2
=s+t+u

and all other declared rational kinematic identities before rational grouping. An unreduced scalar product or an unknown square root should be rejected rather than atomized.

3. Complete-coefficient cleanup without a global Together

Termwise simplification and complete-coefficient simplification should be combined as follows.

Step A: normalize each additive term locally

For every top-level additive term:

apply only certified radical rules;

reduce the color and azimuthal structures to fixed bases;

extract its analytic signature;

simplify its rational kernel locally.

The benchmark result—4.84 s and 49 kB for termwise simplification versus 86.4 s and 328 kB for whole-coefficient Simplify—shows that this local stage should be retained.

Step B: sum kernels with identical signatures

For each signature σ, form

R
σ
	​

=
i:σ
i
	​

=σ
∑
	​

r
i
	​

.

This is the first place where cancellations between different original
additive terms are exposed.

Do not immediately call

Together(R
σ
	​

)

on a large block. Instead use exact denominator buckets.

Step C: exact-denominator bucketing

Write each locally reduced kernel as

r
i
	​

=
d
i
	​

n
i
	​

	​

,n
i
	​

,d
i
	​

∈Q[s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

],

with the numerator and denominator made primitive and the denominator sign
canonical.

Group terms with exactly equal d
i
	​

:

i:d
i
	​

=d
∑
	​

d
n
i
	​

	​

=
d
∑
i
	​

n
i
	​

	​

.

Then cancel the polynomial gcd of the summed numerator and denominator. This
captures a large fraction of complete-coefficient cancellations without
forming a common denominator for unrelated terms.

Step D: balanced gcd-aware merging

To expose cancellations between different denominator buckets, merge two
fractions at a time. Given

f
1
	​

=
d
1
	​

n
1
	​

	​

,f
2
	​

=
d
2
	​

n
2
	​

	​

,

compute

g=gcd(d
1
	​

,d
2
	​

),d
1
	​

=ga,d
2
	​

=gb,

and form

f
1
	​

+f
2
	​

=
gab
n
1
	​

b+n
2
	​

a
	​

.

Then compute

h=gcd(n
1
	​

b+n
2
	​

a,gab)

and divide numerator and denominator by h.

This is algebraically the same as Cancel[Together[f1+f2]], but it:

avoids building a common denominator for the full coefficient;

exploits denominator overlap immediately;

permits balanced merging;

keeps intermediate expression growth bounded;

provides a natural exact fallback.

Sort buckets by denominator size and merge them in a balanced tree. A better
heuristic, when inexpensive, is to merge pairs with the largest denominator
gcd first.

If one merge exceeds a resource limit, retain its two exact fractions as
separate summands. This loses compression but not exactness. A final
coefficient need not be represented as one enormous rational fraction.

The normal form is therefore

C=
σ
∑
	​

S
σ
	​

b=1
∑
N
σ
	​

	​

D
σb
	​

N
σb
	​

	​

,

where N
σ
	​

 should remain small, but need not equal one.

4. When to remove the common x
a
	​

,x
b
	​

,z
h
	​

 monomial

Use the two levels for different purposes.

Target level: strip only after an exact target-by-target certificate

The factor

F
UU
	​

=
x
a
	​

x
b
	​

z
h
2
	​

α
s
3
	​

D
1
	​

(z
h
	​

)f
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

)
	​


may be removed before Kira only if every nonzero summed target coefficient is
proved to contain it.

For every target coefficient C
α
	​

, compute its Laurent valuation

v(C
α
	​

)=(v
x
a
	​

	​

(C
α
	​

),v
x
b
	​

	​

(C
α
	​

),v
z
h
	​

	​

(C
α
	​

))

from the canonical fraction blocks. If

v(C
α
	​

)=(−1,−1,−2)

for every nonzero target and division by F
UU
	​

 leaves no
x
a
	​

,x
b
	​

,z
h
	​

, then factor F
UU
	​

 once before applying Kira. Since
the Kira map is independent of these hadronic fractions, carrying the factor
outside the sparse reduction is exact.

If the target coefficients do not all satisfy this criterion, do not impose
the final monomial at target level. Different targets may have different
fraction powers that cancel only after IBP.

Master level: always repeat the certificate

The authoritative factorization check is performed after all targets have
been accumulated into each master coefficient. For every nonzero master
coefficient C
m
	​

, require

v(C
m
	​

)=(−1,−1,−2)

and

H
m
	​

=
F
UU
	​

C
m
	​

	​

,FreeQ[H
m
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

Thus the recommendation is:

	​

strip at target level only when all targets have been certified;
always extract and verify again at master level.
	​

	​


For the current benchmark, the common factor has been established for all
seven final master coefficients. The same test should now be applied to the
116 summed targets before deciding whether to remove it before Kira.

5. Exact reconstruction and branch certification

Do not verify reconstruction by forming one global difference and calling
FullSimplify.

Instead, canonicalize the original and reconstructed expressions into
signature maps:

M
C
	​

:σ⟼{
D
σ1
	​

N
σ1
	​

	​

,…,
D
σN
σ
	​

	​

N
σN
σ
	​

	​

	​

}.

For

Δ=C
original
	​

−C
reconstructed
	​

,

subtract these maps signature by signature. Exact reconstruction is
established when every rational block reduces to zero.

This check is stronger than numerical comparison because distinct
distribution, color, tensor, BMHV, branch, and radical sectors cannot cancel
against one another.

Branch preservation requires:

every radical rewrite rule has an exact proof under the physical
assumptions;

no PowerExpand is used;

no product or quotient of noninteger powers is split unless positivity and
branch compatibility have been proved;

logarithms and polylogarithms remain inert except for explicitly declared
identities;

the same branch registry is used for the original expression and its
reconstruction;

any unexpected analytic atom or radical sector causes failure.

A suitable rule certificate is

Wolfram Language
certifiedRuleQ[lhs_ :> rhs_] :=
  TrueQ @ FullSimplify[
    lhs == rhs,
    Assumptions -> physicalAssumptions
  ];

The production radical rules should be accepted only if every entry satisfies
this test.

6. Mathematica-level structure

The following is pseudocode, but its helper contracts are sufficiently narrow
for direct implementation.

Wolfram Language
rationalVariablesBefore =
  {s, t, u, Epsilon, xa, xb, zh};

rationalVariablesAfter =
  {s, t, u, Epsilon};

(* Each returned rule is:
     HoldComplete[signature] -> rationalKernel
   One original additive term may generate several rules after reduction
   in the color, azimuthal, or radical basis. *)
ClearAll[signatureTerms];

signatureTerms[term_] := Module[
  {
    normalized, pieces, distributionKey, colorKey, azimuthKey,
    bmhvKey, analyticKey, radicalKey, rationalKernel
  },

  normalized = applyCertifiedRadicalRules[term];
  normalized = reduceColorToDeclaredBasis[normalized];
  normalized = reduceAzimuthToDeclaredBasis[normalized];
  normalized = reduceRadicalPowers[normalized];

  If[! FreeQ[normalized, forbiddenCoefficientObjects],
    Return[$Failed]
  ];

  pieces = splitInDeclaredBases[normalized];

  Map[
    Function[piece,
      {
        distributionKey,
        colorKey,
        azimuthKey,
        bmhvKey,
        analyticKey,
        radicalKey,
        rationalKernel
      } = classifyCoefficientPiece[piece];

      If[
        ! rationalFunctionQ[
          rationalKernel,
          rationalVariablesBefore
        ],
        Return[$Failed]
      ];

      HoldComplete[{
        distributionKey,
        colorKey,
        azimuthKey,
        bmhvKey,
        analyticKey,
        radicalKey
      }] -> Cancel[rationalKernel]
    ],
    pieces
  ]
];

Canonicalize one rational kernel into a numerator-denominator pair:

Wolfram Language
ClearAll[canonicalFraction];

canonicalFraction[r_, variables_List] := Module[
  {z, numerator, denominator, gcd, rules, leadingCoefficient},

  z = Cancel[r];
  numerator = Expand[Numerator[z]];
  denominator = Expand[Denominator[z]];

  If[
    ! PolynomialQ[numerator, variables] ||
    ! PolynomialQ[denominator, variables],
    Return[$Failed]
  ];

  gcd = PolynomialGCD[numerator, denominator];
  numerator = Expand[numerator/gcd];
  denominator = Expand[denominator/gcd];

  rules = CoefficientRules[
    denominator,
    variables,
    MonomialOrder -> DegreeLexicographic
  ];
  If[rules === {}, Return[$Failed]];

  leadingCoefficient = Last[First[rules]];
  If[TrueQ[leadingCoefficient < 0],
    numerator = -numerator;
    denominator = -denominator
  ];

  {numerator, denominator}
];

Merge two fractions without a full global Together:

Wolfram Language
ClearAll[mergeFractions];

mergeFractions[
    {n1_, d1_},
    {n2_, d2_},
    variables_List
  ] := Module[
  {g, a, b, numerator, denominator, h},

  g = PolynomialGCD[d1, d2];
  a = Expand[Cancel[d1/g]];
  b = Expand[Cancel[d2/g]];

  numerator = Expand[n1 b + n2 a];
  denominator = Expand[g a b];

  h = PolynomialGCD[numerator, denominator];

  canonicalFraction[
    (numerator/h)/(denominator/h),
    variables
  ]
];

Normalize one complete signature block:

Wolfram Language
ClearAll[normalizeRationalBlock];

normalizeRationalBlock[kernels_List, variables_List] := Module[
  {fractions, buckets, bucketFractions, round},

  fractions = canonicalFraction[#, variables] & /@ kernels;
  If[MemberQ[fractions, $Failed], Return[$Failed]];

  fractions = Select[fractions, ! TrueQ[First[#] === 0] &];

  (* Exact equal-denominator buckets. *)
  buckets = GatherBy[fractions, Last];

  bucketFractions = Map[
    Function[bucket,
      canonicalFraction[
        Total[bucket[[All, 1]]] / bucket[[1, 2]],
        variables
      ]
    ],
    buckets
  ];

  (* Balanced exact merge. *)
  round[list_] := Map[
    Function[pair,
      If[
        Length[pair] == 1,
        First[pair],
        mergeFractions[pair[[1]], pair[[2]], variables]
      ]
    ],
    Partition[
      SortBy[list, LeafCount[Last[#]] &],
      UpTo[2]
    ]
  ];

  First @ NestWhile[round, bucketFractions, Length[#] > 1 &]
];

Construct the full signature map:

Wolfram Language
ClearAll[coefficientSignatureMap];

coefficientSignatureMap[coefficient_] := Module[
  {terms, rules, grouped, normalized},

  terms = If[
    Head[coefficient] === Plus,
    List @@ coefficient,
    {coefficient}
  ];

  rules = Flatten[signatureTerms /@ terms];
  If[MemberQ[rules, $Failed], Return[$Failed]];

  grouped = GroupBy[rules, First -> Last];

  normalized = Association @ KeyValueMap[
    #1 -> normalizeRationalBlock[
      #2,
      rationalVariablesBefore
    ] &,
    grouped
  ];

  If[MemberQ[Values[normalized], $Failed], $Failed, normalized]
];

The actual production version should allow a signature block to retain several
canonical fractions when a bounded merge is not beneficial. The exact data
type is then

Wolfram Language
signature -> {{n1, d1}, {n2, d2}, ...}

rather than forcing one {n,d} pair.

Finally, verify reconstruction by comparing two signature maps:

Wolfram Language
ClearAll[exactSignatureMapEqualQ];

exactSignatureMapEqualQ[first_, second_] := Module[
  {keys, differences},

  keys = Union[Keys[first], Keys[second]];

  differences = AssociationMap[
    Function[key,
      normalizeRationalBlock[
        Join[
          Lookup[first, key, {}],
          ({-First[#], Last[#]} & /@
            Lookup[second, key, {}])
        ],
        rationalVariablesBefore
      ]
    ],
    keys
  ];

  AllTrue[
    Values[differences],
    TrueQ[First[#] === 0] &
  ]
];
Recommended order for the current UU calculation

For each of the 116 summed targets:

branch-certified radical reduction
→termwise rational cleanup
→signature grouping
→equal-denominator summation
→balanced gcd-aware merging.
	​

	​


Then apply the sparse Kira map and repeat the same block normalization on each
of the seven complete master coefficients.

This retains the speed advantage of termwise simplification, exposes
cross-term cancellations that termwise treatment alone misses, and avoids the
expression growth caused by forcing every coefficient into one global common
denominator.

## Sources sent to Pro

- Original source reference: `../../ppHX_NLO/HadronicSimplification/UU_10x10/BenchmarkSummary.wl` (not archived with this exchange)
