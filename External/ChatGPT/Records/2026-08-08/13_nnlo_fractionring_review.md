# NNLO Fractionring Review

## Question

Continue the existing FACET discussion. I am attaching the exact Mathematica source for the proposed NNLO momentum-fraction algebra. This code has not yet been run on a complete NNLO master column; the full physical-target transformation is still running. Please review the source itself rather than restating the earlier general algorithm.

Physics objective: after stripping f1[xa] f1[xb] D1[zh], a complete master coefficient must be proved to equal

  xa^(-1) xb^(-1) zh^(-2) H(s,t,u,Epsilon,...)

with H independent of xa, xb, zh. The input may contain only explicit half-integer Laurent powers of xa, xb, zh; fraction-dependent Log/Gamma/Hypergeometric objects must cause immediate failure. The code lifts xa=ya^2, xb=yb^2, zh=yh^2, accumulates each complete master as a sparse rational function in ya,yb,yh, and then compares numerator coefficients against the expected universal Laurent monomial times the common denominator.

Please do four things:
1. Check the algebraic proof in nnloCertifyUniversalFactor line by line. State whether it is necessary and sufficient under the stated input class.
2. Check whether PolynomialLCM and the denominator normalization are valid over the coefficient field of expressions in s,t,u,Epsilon,color factors and inert analytic objects. If not, give a precise replacement that remains exact and does not create one global Together over all variables.
3. Identify Mathematica-language errors or scoping/Return behavior that could make this source fail or silently return a wrong result.
4. Suggest the smallest set of synthetic and real-data tests needed before applying it to three complete NNLO master columns. Do not propose numerical verification as the analytic calculation.

Keep the response concrete and tied to the attached file.

## Pro response

Not yet production-correct. The proportionality argument in nnloCertifyUniversalFactor is mathematically sound, but the implementation has several correctness-critical gaps: the pivot is not proved nonzero, "Verified" -> True does not require a fraction-free output, the distribution-factor “certificate” is tautological, and the DeleteDuplicates call at line 240 is syntactically wrong. PolynomialLCM also does not explicitly implement the intended coefficient field.

Source reviewed: NNLOFractionRing.wl.

1. Audit of nnloCertifyUniversalFactor

Let

K=Frac(Q[s,t,u,ϵ,color generators,inert analytic generators]/I),

where I contains every exact algebraic relation already imposed, and all remaining inert analytic generators are treated as algebraically independent. Define

y=(y
a
	​

,y
b
	​

,y
h
	​

)=(facetYa,facetYb,facetYh),

and let the assembled column be

C(y)=
D(y)
N(y)
	​

,N,D∈K[y],D

=0.

After stripping f
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

), the required factor is

U(y)=y
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

The desired statement is

C(y)=U(y)H,H∈K.

Equivalently,

N(y)=HU(y)D(y).

Write

N=
ν
∑
	​

n
ν
	​

y
ν
,V:=UD=
ν
∑
	​

v
ν
	​

y
ν
.

For any index ν
0
	​

 with v
ν
0
	​

	​


=0,

N=HV

holds if and only if

n
ν
	​

v
ν
0
	​

	​

−n
ν
0
	​

	​

v
ν
	​

=0for every exponent ν.
	​


Then

H=
v
ν
0
	​

	​

n
ν
0
	​

	​

	​

.

This remains valid when N=0, in which case H=0.

Lines 290–292: input extraction
Wolfram Language
numeratorMap = column["Numerator"];
denominatorMap = nnloPolynomialMap[column["Denominator"]];

The operation is mathematically appropriate, but the function does not validate that:

"Numerator" exists and is an Association;

every key is an integer vector of length three;

every coefficient is exact;

every coefficient is free of x
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

;

the denominator is nonzero.

These are prerequisites for the proof, not optional diagnostics.

Lines 293–301: construction of UD and common exponent shift
Wolfram Language
universalMap = nnloSparseShift[
  denominatorMap,
  nnloUniversalRootExponent
];

This correctly constructs the Laurent-polynomial map of

UD=y
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

D.

The subsequent common shift applied to both N and UD is also correct:

N↦y
δ
N,UD↦y
δ
UD.

It does not alter proportionality.

It is, however, unnecessary. Associations can use negative integer exponent vectors directly. Removing lines 297–301 simplifies the proof and avoids failure when an exponent map is empty or malformed.

Lines 302–310: pivot selection is not safe

The current test is

Wolfram Language
! TrueQ[Lookup[shiftedUniversal, #, 0] === 0] &

This proves only that the coefficient is not syntactically identical to 0. It does not prove that it is nonzero in K.

For example, a coefficient such as

Wolfram Language
1 - (s + t)/(s + t)

is not necessarily SameQ to zero before rational normalization. Selecting it as v
ν
0
	​

	​

 makes

Wolfram Language
hardCoefficient = Cancel[n0/v0]

invalid.

The pivot coefficient must first be reduced in the declared formal coefficient field:

Wolfram Language
nnloCanonicalCoefficient[expression_, timeLimit_: 60] :=
  TimeConstrained[
    Quiet @ CheckAbort[
      Check[Cancel[Together[expression]], $Failed],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];

nnloCoefficientZeroStatus[expression_, timeLimit_: 60] :=
  Replace[
    nnloCanonicalCoefficient[expression, timeLimit],
    {
      0 -> True,
      $TimedOut -> $TimedOut,
      $Failed -> $Failed,
      _ -> False
    }
  ];

Under the stated formal-field convention:

True means proved zero;

False means proved nonzero in the formal rational-function field;

$TimedOut means unresolved;

$Failed means invalid algebra.

The pivot must be a coefficient whose status is exactly False.

Lines 311–318: cross-minor test
Wolfram Language
Lookup[shiftedNumerator, #, 0] v0 -
  n0 Lookup[shiftedUniversal, #, 0]

This is the correct necessary-and-sufficient test, provided:

v
0
	​

 has been proved nonzero;

all coefficients lie in one integral domain K;

nnloExactZeroQ is complete for the declared formal coefficient grammar;

exact relations in I have already been imposed.

If Gamma functions, color structures, or other analytic objects are retained as inert independent generators, a successful zero test is still an exact proof. A failed formal test does not prove analytic inequality unless the generators have been proved independent.

Lines 319–325: status accounting is incomplete

The current result counts only:

Wolfram Language
$TimedOut
False

A check that returns $Failed, $Aborted, an unevaluated expression, or another unexpected result causes "Verified" -> False, but is counted neither as unresolved nor as failed.

Return separate counts:

Wolfram Language
"TimeoutCount"
"FormalNonzeroCount"
"FailureCount"

and give the overall result one of:

Wolfram Language
"Verified"
"FormalMismatch"
"Unresolved"
"InvalidInput"

Do not call False a mathematical nonzero unless algebraic independence of the inert generators is part of the contract.

Lines 327–337: "Verified" does not enforce fraction independence

The function currently returns

Wolfram Language
"Verified" -> True,
"FractionFree" -> FreeQ[...]

even if "FractionFree" is False.

That contradicts the stated objective. Acceptance requires both:

N=HUD

and

H∈K,

with no fraction or root variables hidden in H.

Replace the final acceptance by:

Wolfram Language
hardCoefficient = nnloCanonicalCoefficient[n0/v0, timeLimit];

If[
  MemberQ[{hardCoefficient}, $Failed | $TimedOut] ||
    ! FreeQ[
      hardCoefficient,
      Alternatives @@ Join[
        nnloFractionVariables,
        nnloRootVariables
      ]
    ],
  Return[$Failed]
];
Corrected logical core

The common exponent shift can be removed:

Wolfram Language
nnloCertifyUniversalFactor[
    column_Association,
    timeLimit_: 60
  ] := Module[
  {
    numeratorMap, denominatorMap, universalMap, keys,
    pivot, pivotStatus, n0, v0, checks, values,
    hardCoefficient, failureCount
  },

  numeratorMap = Lookup[column, "Numerator", $Failed];

  If[
    ! AssociationQ[numeratorMap] ||
      ! AllTrue[
        Keys[numeratorMap],
        MatchQ[#, {_Integer, _Integer, _Integer}] &
      ],
    Return[$Failed]
  ];

  denominatorMap = nnloPolynomialMap[
    Lookup[column, "Denominator", $Failed]
  ];
  If[
    denominatorMap === $Failed ||
      denominatorMap === <||>,
    Return[$Failed]
  ];

  If[
    ! FreeQ[
      Values[numeratorMap],
      Alternatives @@ Join[
        nnloFractionVariables,
        nnloRootVariables
      ]
    ],
    Return[$Failed]
  ];

  universalMap = nnloSparseShift[
    denominatorMap,
    nnloUniversalRootExponent
  ];

  keys = Union[Keys[numeratorMap], Keys[universalMap]];

  pivot = SelectFirst[
    keys,
    nnloCoefficientZeroStatus[
      Lookup[universalMap, #, 0],
      timeLimit
    ] === False &,
    Missing["NoCertifiedNonzeroPivot"]
  ];

  If[MissingQ[pivot],
    Return[<|
      "Verified" -> False,
      "Status" -> "Unresolved",
      "Reason" -> "No certified nonzero universal coefficient"
    |>]
  ];

  n0 = Lookup[numeratorMap, pivot, 0];
  v0 = nnloCanonicalCoefficient[
    Lookup[universalMap, pivot, 0],
    timeLimit
  ];

  If[MemberQ[{v0}, $Failed | $TimedOut | 0],
    Return[$Failed]
  ];

  checks = AssociationMap[
    nnloCoefficientZeroStatus[
      Lookup[numeratorMap, #, 0] v0 -
        n0 Lookup[universalMap, #, 0],
      timeLimit
    ] &,
    keys
  ];

  values = Values[checks];
  failureCount = Count[
    values,
    Except[True | False | $TimedOut]
  ];

  If[failureCount > 0,
    Return[<|
      "Verified" -> False,
      "Status" -> "InvalidInput",
      "Checks" -> checks,
      "FailureCount" -> failureCount
    |>]
  ];

  If[MemberQ[values, $TimedOut],
    Return[<|
      "Verified" -> False,
      "Status" -> "Unresolved",
      "Checks" -> checks,
      "TimeoutCount" -> Count[values, $TimedOut]
    |>]
  ];

  If[MemberQ[values, False],
    Return[<|
      "Verified" -> False,
      "Status" -> "FormalMismatch",
      "Checks" -> checks,
      "FormalNonzeroCount" -> Count[values, False]
    |>]
  ];

  hardCoefficient = nnloCanonicalCoefficient[n0/v0, timeLimit];

  If[
    MemberQ[{hardCoefficient}, $Failed | $TimedOut] ||
      ! FreeQ[
        hardCoefficient,
        Alternatives @@ Join[
          nnloFractionVariables,
          nnloRootVariables
        ]
      ],
    Return[$Failed]
  ];

  <|
    "Verified" -> True,
    "Status" -> "Verified",
    "HardCoefficient" -> hardCoefficient,
    "Pivot" -> pivot,
    "Checks" -> checks
  |>
];

Subject to the stated coefficient-field assumptions, this is necessary and sufficient.

2. PolynomialLCM and denominator normalization
PolynomialLCM does not explicitly use the intended field

The intended ring is

K[y
a
	​

,y
b
	​

,y
h
	​

],

where every nonzero expression in

s,t,u,ϵ,color,inert atoms

is a coefficient-field unit.

The call

Wolfram Language
PolynomialLCM[previous, denominator]

has no variable-list argument and therefore does not explicitly distinguish the root variables from symbolic parameters. Wolfram documents that polynomial GCD operations treat symbolic parameters as polynomial variables; the available Extension option concerns algebraic-number extensions, not a symbolic rational-function coefficient field. 
Wolfram Documentation Center
+1

Therefore, the returned expression should not be treated as a certified least common multiple in K[y].

The current quotient checks:

Wolfram Language
PolynomialQ[
  Cancel[common/denominator],
  nnloRootVariables
]

do protect algebraic correctness: when they succeed, common is at least a common multiple over K[y]. The main risk is severe overgrowth, not necessarily a wrong sum.

Exact replacement: explicit divisibility over rational-function parameters

PolynomialReduce accepts an explicit root-variable list and can work over the field of rational functions in all other parameters. 
Wolfram Documentation Center
+1

Use:

Wolfram Language
nnloPolynomialQuotientK[
    dividend_,
    divisor_,
    timeLimit_: 60
  ] := Module[
  {result, quotients, remainder, zeroStatus},

  result = TimeConstrained[
    Quiet @ CheckAbort[
      Check[
        PolynomialReduce[
          dividend,
          {divisor},
          nnloRootVariables,
          CoefficientDomain -> RationalFunctions
        ],
        $Failed
      ],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];

  If[! MatchQ[result, {{_}, _}],
    Return[result]
  ];

  {quotients, remainder} = result;

  zeroStatus = nnloCoefficientZeroStatus[
    remainder,
    timeLimit
  ];

  If[
    zeroStatus === True &&
      PolynomialQ[
        First[quotients],
        nnloRootVariables
      ],
    First[quotients],
    If[zeroStatus === $TimedOut, $TimedOut, $Failed]
  ]
];

A correctness-first common-multiple construction is then:

Wolfram Language
nnloCommonFractionDenominator[
    denominators_List,
    timeLimit_: 60
  ] := Catch[
  Fold[
    Function[{common, denominator},
      Module[
        {
          commonOverDenominator,
          denominatorOverCommon,
          normalized
        },

        commonOverDenominator =
          nnloPolynomialQuotientK[
            common,
            denominator,
            timeLimit
          ];

        If[
          commonOverDenominator =!= $Failed &&
            commonOverDenominator =!= $TimedOut,
          Return[common, Module]
        ];

        denominatorOverCommon =
          nnloPolynomialQuotientK[
            denominator,
            common,
            timeLimit
          ];

        If[
          denominatorOverCommon =!= $Failed &&
            denominatorOverCommon =!= $TimedOut,
          normalized =
            nnloNormalizeFractionDenominator[denominator];
          If[normalized === $Failed,
            Throw[$Failed]
          ];
          Return[First[normalized], Module]
        ];

        normalized =
          nnloNormalizeFractionDenominator[
            Expand[common denominator]
          ];

        If[normalized === $Failed,
          Throw[$Failed]
        ];

        First[normalized]
      ]
    ],
    1,
    DeleteDuplicates[denominators, SameQ]
  ]
];

This does not find partial common factors, but it is exact and never forms one global denominator in s,t,u,ϵ. It multiplies denominators only when neither divides the other.

Optional exact performance layer

For NNLO scale, add factor profiles:

Clear coefficient denominators separately for each y-polynomial.

Represent every nonrational coefficient object by an inert symbol.

Remove factors free of y
a
	​

,y
b
	​

,y
h
	​

; they are units in K.

Factor the remaining primitive polynomial under a bound.

Normalize every root-dependent factor to leading coefficient one.

If factorization times out, retain the entire normalized denominator as one indivisible factor.

Construct the common multiple by taking the maximum exponent of each factor key.

Certify every quotient using PolynomialReduce[..., CoefficientDomain -> RationalFunctions].

Even when some denominators are retained as indivisible factors, the resulting product remains a valid common multiple. It may only be nonminimal.

Denominator normalization

Dividing a denominator by its leading coefficient is valid over K, provided that coefficient is proved nonzero. The operation is a meromorphic normalization:

D
N
	​

=
D/c
N/c
	​

,c∈K
×
.

The current nnloNormalizeFractionDenominator does not:

canonicalize the leading coefficient;

prove it is nonzero;

impose a time bound;

verify

D=cD
normalized
	​

.

CoefficientRules uses lexicographic ordering by default, so the existing lexicographic choice is well defined. 
Wolfram Documentation Center

Add an exact reconstruction check and a proved-nonzero leading coefficient.

3. Wolfram Language and source defects
Correctness-critical
Line 240: invalid DeleteDuplicates form

The source uses

Wolfram Language
DeleteDuplicates[
  denominators,
  SameTest -> SameQ
]

DeleteDuplicates takes its comparison function as the second positional argument:

Wolfram Language
DeleteDuplicates[data, test]

and defaults to SameQ. It does not take a SameTest option. 
Wolfram Documentation Center

Replace with either:

Wolfram Language
DeleteDuplicates[denominators]

or:

Wolfram Language
DeleteDuplicates[denominators, SameQ]

The current form will generally fail to recognize duplicates. If PolynomialLCM subsequently times out, identical denominators can be multiplied repeatedly, artificially increasing powers.

Lines 136–141: distribution certificate is tautological

The code defines

Wolfram Language
quotient = Cancel[expression/nnloDistributionFactor];

and then checks

Wolfram Language
expression - nnloDistributionFactor quotient

This reconstructs by construction and does not prove that the expected distribution factor was present exactly once.

A missing distribution factor, an extra power, or another distribution channel must be rejected explicitly.

Freeze

Wolfram Language
{f1[xa], f1[xb], D1[zh]}

to three unique symbols, divide by their product, and require the quotient to be free of all three symbols and of every remaining PDF/FF object.

Line 59: hidden dependency can fail open

nnloPositiveRootLift calls

Wolfram Language
ttAnalyticObjectQ

but that symbol is neither defined nor declared in this file.

If it lacks a definition in the loading environment, the pattern condition need not evaluate to True, and a forbidden fraction-dependent analytic object may escape the intended immediate check.

Replace it with a local fail-closed rational-grammar check. After lifting, require that Together[lifted] have numerator and denominator polynomial in the three root variables. Explicitly reject fraction-dependent:

Wolfram Language
Log
Gamma
Beta
Pochhammer
Hypergeometric2F1
PolyLog
Piecewise
ConditionalExpression
Abs
Sign
UnitStep
DiracDelta

before expensive column assembly.

Lines 303–310: unproved pivot

As discussed above, =!= 0 is insufficient. Select a coefficient proved nonzero in the formal coefficient field.

Lines 327–336: false acceptance

"Verified" -> True must require "FractionFree" -> True.

Failure-reporting defects
Lines 268–275: timeouts are silently hidden
Wolfram Language
TimeConstrained[
  Cancel[Together[#]],
  timeLimit,
  #
]

correctly retains the exact input on timeout, but the result does not record which coefficients timed out. TimeConstrained returns its third argument on timeout; that should be retained together with a status record. 
Wolfram Documentation Center

Return separate data:

Wolfram Language
"CoefficientNormalizationStatus" -> <|
  exponent1 -> "VerifiedChanged",
  exponent2 -> "TimedOutUnchanged",
  ...
|>
Lines 235–237: unchecked failed normalization

The fallback contains

Wolfram Language
common = First @ nnloNormalizeFractionDenominator[
  previous denominator
]

If normalization returns $Failed, First[$Failed] propagates a malformed expression rather than a controlled failure.

Store the result, test it, and only then take First.

Input-validation gaps

Add checks for:

inexact Real or Complex values;

malformed sparse exponent keys;

exponent vectors not of length three;

noninteger root exponents;

root variables in sparse coefficients;

zero denominators;

missing keys in leaf and column associations;

invalid leaf objects entering nnloMergeFractionLeaves.

Not a defect

The forms

Wolfram Language
Return[$Failed, Module]

are legal Wolfram Language and explicitly return from the enclosing Module; this usage appears in Wolfram’s own documented examples. 
Wolfram Documentation Center

They are nevertheless harder to audit than a tagged Catch/Throw.

4. Minimum tests before three complete NNLO columns
Synthetic algebra tests
Test	Input	Required result
Universal monomial	f
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

)x
a
−1
	​

x
b
−1
	​

z
h
−2
	​

H	Verified, hard coefficient H
Rational cross-leaf cancellation	Two leaves proportional to 
ux
a
	​

+tx
b
	​

ux
a
	​

	​

 and 
ux
a
	​

+tx
b
	​

tx
b
	​

	​

	Sum verifies to the universal monomial
Half-power cancellation	Two leaves proportional to 
x
a
	​

	​

+
x
b
	​

	​

x
a
	​

	​

	​

 and 
x
a
	​

	​

+
x
b
	​

	​

x
b
	​

	​

	​

	Sum verifies exactly
Zero coefficient	Two opposite leaves	Verified with H=0
Wrong universal power	x
a
−1
	​

x
b
−1
	​

z
h
−1
	​

H	Formal mismatch
Rationally zero pivot	Universal denominator with a leading coefficient such as 1−(s+t)/(s+t)	Zero coefficient skipped; another pivot used
Proportional denominators	(s+t)(y
a
	​

+y
b
	​

) and y
a
	​

+y
b
	​

	Same normalized denominator
Rational coefficient denominators	y
a
	​

+(t/u)y
b
	​

 and uy
a
	​

+ty
b
	​

	Same denominator up to a coefficient-field unit
Partially shared factors	(y
a
	​

+y
b
	​

)(y
a
	​

+sy
h
	​

) and (y
a
	​

+y
b
	​

)(y
b
	​

+ty
h
	​

)	Certified common multiple and polynomial quotients
Duplicate denominators	Repeated identical denominator list	Exactly one unique denominator processed
Fail-closed grammar tests

Each of the following must fail before column assembly:

Wolfram Language
xa^(-Epsilon)
Log[xa]
Gamma[xa + Epsilon]
Hypergeometric2F1[a, b, c, xa]
Sqrt[xa + xb]
0.5 xa

Also reject:

missing f1[xa];

an extra f1[xa];

the wrong fragmentation object;

a different PDF/FF channel;

residual distribution objects after stripping.

The zero expression may be accepted explicitly as the special case H=0.

Sparse-map structural tests

Require failure for:

Wolfram Language
<|{1, 2} -> c|>          (* wrong key length *)
<|{1, 2, 1/2} -> c|>    (* noninteger exponent *)
<|{1, 2, 3} -> c facetYa|>  (* root variable in coefficient *)

Verify exact reconstruction after every nnloSparseAdd, nnloSparseMultiply, and nnloSparseShift.

Existing real-data calculation

Before any complete NNLO column, run the exact code on the known NLO UU result:

all six masters;

the same stripped factor

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

);

expected exponent

(−2,−2,−4);

exact agreement with the established NLO hard coefficients.

This is the strongest real-data acceptance test because the final fraction cancellation is already known analytically.

Small NNLO data tests

From completed physical-target shards, select:

one target already fraction-free;

one target containing ux
a
	​

+tx
b
	​

;

one target containing half-powers;

one large target by byte count.

For each, require:

exact distribution stripping;

exact positive-root lift;

exact leaf reconstruction;

no forbidden fraction-dependent analytic object.

Then construct one small exact mini-column from a manageable set of NNLO target contributions and compare:

D
sparse
	​

N
sparse
	​

	​


against the direct exact sum by coefficientwise cross multiplication in y
a
	​

,y
b
	​

,y
h
	​

.

Only after these tests should the three complete NNLO master columns be attempted:

a small column;

a median column;

the column with the largest predicted denominator/fan-in complexity.

## Sources sent to Pro

- [nnlofractionring.wl](Sources/13_nnlo_fractionring_review/nnlofractionring.wl)
