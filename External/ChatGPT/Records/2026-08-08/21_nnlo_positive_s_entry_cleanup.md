# NNLO Positive S Entry Cleanup

## Question

We found a more specific structure than the generic analytic-signature case.

For the selected NNLO UU master coefficients after exact removal of xa, xb,
zh and their positive roots, inspection of the smallest, median, and largest
shard coefficients found that every remaining noninteger power is a
half-integer power of the physical invariant s.  No Gamma, Log,
Hypergeometric2F1, BMHV, or other analytic atom occurs in these coefficients.
The card assumptions include s>0, t<0, u<0.

We therefore introduced one exact positive root rs with s=rs^2 and rs>0.
The attached NNLOInvariantRootRing.wl maps every certified s^(n/2) and
(s^n)^(p/2) to an integer Laurent power of rs, rejecting any other
noninteger power involving s.  It restores to s only after exact rational
normalization and only when numerator and denominator contain even powers of
rs.

Measured hard case:
- One source entry in shard 40 had a 63,076,536-byte hard coefficient.
- Cancel[Together[...]] after the positive-s lift completed in 96.75 s and
  returned 366,888 bytes.
- An independent exact comparison
  Cancel[Together[candidate-input]] reached exactly 0 in 604.42 s.
- Exact evaluation at rs=5, t=-2, u=-3, Epsilon=1/17 also gave 0.
- In an eight-kernel run over all 164 entries of that shard, 163 independent
  equality checks completed within 120 s.  Only the above entry exceeded the
  120 s verification bound; its isolated 900 s check is now proven exactly.

The source entry itself is first converted to a hard coefficient through the
already certified universal positive-fraction-root factor.  Thus each input
entry and the source coverage are exact before the s-root cleanup.

Please review the attached helper and answer concretely:
1. Is the s=rs^2 map branch-safe and complete for the observed grammar under
   s>0? Identify any Mathematica evaluation or pattern issue in the code.
2. For a completed exact Cancel[Together] in Q(rs,t,u,Epsilon), is rerunning
   Cancel[Together[candidate-input]] mathematically necessary for every entry,
   or can the exact algorithm plus structural source/lift certificates be the
   proof, with independent equality calculations restricted to tests?
3. What exact accumulation order should be used for roughly 38,400 cleaned
   rational entries: denominator buckets, balanced rational addition, or
   another representation? We must avoid constructing the previous 818 MB
   shard sums.
4. What exact criterion should be used to restore rs to s if a rational
   function is invariant under rs -> -rs but numerator and denominator are
   not separately even before cancellation?

Do not recommend numerical reconstruction, PowerExpand, or treating numerical
checks as the analytic result.

## Pro response

Source reviewed: NNLOInvariantRootRing.wl.

The measured result justifies using the s-root ring as the production coefficient algebra. Under the observed grammar, the transformation

s=r
s
2
	​

,r
s
	​

>0

converts every coefficient into an exact rational function of

r
s
	​

, t, u, ϵ

with no remaining branch-sensitive objects. Cancel[Together[...]] is then ordinary exact rational-function arithmetic.

1. Branch safety and source audit
Mathematical status of the lift

Let

K=Q(t,u,ϵ,color variables,…)

and consider the admitted Laurent algebra

R
s
	​

=K[s
1/2
,s
−1/2
].

In the physical chamber s>0, define the positive root

r
s
	​

=
s
	​

>0.

The substitution

Φ
s
	​

(s
n/2
)=r
s
n
	​

,n∈Z,

is a branch-fixed algebra isomorphism

Φ
s
	​

:R
s
	​

⟶K[r
s
	​

,r
s
−1
	​

].

For the nested form accepted by lines 12–14,

(s
n
)
p
,n∈Z,p∈Q,2np∈Z,

one has, because s
n
>0,

(s
n
)
p
=s
np
=r
s
2np
	​

.

Thus the rules on lines 31–38 are branch-safe for the stated grammar. Neither t<0 nor u<0 is required for this particular map; only s>0 is used.

The helper is complete for the observed grammar, with four source-level qualifications
A. The symbol contexts are hard-coded

The patterns on lines 11–14 and the replacement on line 38 refer to an unqualified symbol s. Their correctness requires that this be exactly the same symbol as the physical invariant in the coefficients.

If the file is loaded under a private context, s can become a different symbol and the rules can silently stop matching.

Parameterize both symbols:

Wolfram Language
nnloInvariantRootLift[
    expression_,
    invariant_Symbol,
    root_Symbol
  ] := ...

and call it explicitly, for example,

Wolfram Language
nnloInvariantRootLift[
  expression,
  Global`s,
  FeynFacet`Private`facetRs
]

The same change should be made to the restoration functions.

Also require before lifting:

Wolfram Language
FreeQ[expression, root]

so an existing occurrence of the temporary root variable cannot be conflated with the generated one.

B. The current precheck rejects bad powers but not other s-dependent functions

Lines 18–29 reject unsupported noninteger powers containing s. They do not reject objects such as

Wolfram Language
Log[s]
Gamma[s + Epsilon]
Sin[s]
Hypergeometric2F1[a, b, c, s]
ConditionalExpression[..., s > 0]

Such objects would be changed to functions of facetRs^2 by line 38. The final test on lines 40–49 only rejects noninteger powers involving facetRs; it does not reject these other heads.

The measured coefficients contain none of them, so this does not invalidate the current result. For a fail-closed helper, add an explicit grammar test before substitution:

allowed expressions=exact rational combinations of s
n/2
,t,u,ϵ,…

and reject every s-dependent object outside Plus, Times, and admitted Power.

In particular, require after lifting that the expression belongs to the rational function field in r
s
	​

. This can be established structurally during parsing; it should not require another large global Together.

C. Exact input should be checked locally

The surrounding workflow already certifies exactness, but the helper itself does not reject machine reals. Add:

Wolfram Language
If[! exactDataQ[expression], Return[$Failed]];

or the corresponding project predicate.

D. The final restoration Cancel is unbounded

Lines 64–68 place the first Cancel[Together[...]] under TimeConstrained, but line 78 applies another unrestricted Cancel:

Wolfram Language
Cancel[restoredNumerator/restoredDenominator]

Place this operation under the same bound, or return the exact numerator–denominator pair without an additional cancellation.

Mathematica evaluation of nested powers

A nested expression such as

Wolfram Language
Power[Power[s, n], p]

may already have been canonicalized by the evaluator before the rule sees it. This is not a mathematical defect here: when it becomes Power[s, n p], the rule on lines 35–37 recognizes the same total half-integer exponent.

It should nevertheless be covered by tests for both syntactic forms:

Wolfram Language
s^(3/2)
(s^3)^(1/2)
(s^2)^(1/4)
(s^-2)^(1/4)

under s>0.

2. A second full equality calculation is not required per entry

Once the following conditions have been certified:

the source contains exact data only;

every noninteger s-dependent power belongs to the admitted grammar;

s>0 and r
s
	​

=
s
	​

>0 are part of the analytic context;

the lift is the exact homomorphism Φ
s
	​

;

the lifted expression is a rational function in

Q(r
s
	​

,t,u,ϵ,…);

Cancel[Together[...]] completed rather than timing out or failing;

then the returned candidate is exactly equal to the lifted input as an element of the rational function field.

Together and Cancel do not apply assumptions, alter logarithms, combine powers, or select branches. In this grammar they perform only

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

⟼
Q
1
	​

Q
2
	​

P
1
	​

Q
2
	​

+P
2
	​

Q
1
	​

	​


and polynomial common-factor cancellation.

The equality is meromorphic: cancellation may remove a removable singularity from a particular numerator–denominator presentation. That is the appropriate equality notion for the analytic hard coefficient.

Therefore rerunning

Wolfram Language
Cancel[Together[candidate - input]]

for every entry is mathematically redundant. It repeats essentially the same denominator construction and polynomial cancellation, sometimes at much greater cost.

The production certificate should record:

Wolfram Language
<|
  "SourceHash" -> ...,
  "PhysicalContextFingerprint" -> ...,
  "PositiveRootAssumption" -> HoldComplete[s > 0 && facetRs > 0],
  "LiftGrammar" -> "HalfIntegerLaurentPowersOfS",
  "LiftedExpressionHash" -> ...,
  "Transformation" -> "Cancel[Together]",
  "TransformationStatus" -> "Completed",
  "CandidateHash" -> ...,
  "NumeratorHash" -> ...,
  "DenominatorHash" -> ...,
  "ExactData" -> True
|>

The exact comparison performed for 163 entries, together with the isolated 900-second proof for the exceptional entry, is a strong independent implementation test. It need not become the per-entry production algorithm.

The exact evaluation at

r
s
	​

=5,t=−2,u=−3,ϵ=
17
1
	​


is useful diagnostic evidence, but it is not part of the analytic proof.

3. Exact accumulation order for the cleaned entries

Because no Gamma, logarithmic, hypergeometric, BMHV, or other analytic atoms remain, analytic-signature separation is unnecessary. All entries live in one rational function field.

Keep r
s
	​

 until the complete master coefficient has been assembled. Odd powers can cancel between entries.

For each cleaned entry, store

h
i
	​

(r
s
	​

,t,u,ϵ)=
Q
i
	​

P
i
	​

	​

,

where Cancel[Together] has already produced an exact reduced rational expression.

Stage 1: attempt immediate descent to s

Apply the exact r
s
	​

↦−r
s
	​

 invariance test described in Section 4 below.

If an entry descends to

h
i
	​

(s,t,u,ϵ),

move it immediately to a root-free accumulator. It no longer needs to participate in r
s
	​

-dependent denominator algebra.

Stage 2: group exact equal denominators

For the remaining entries, use a deterministic denominator key:

Wolfram Language
denominatorKey[q_] := HoldComplete[q]

indexed by a hash and confirmed with SameQ.

For every exact denominator Q,

i:Q
i
	​

=Q
∑
	​

Q
P
i
	​

	​

=
Q
∑
i
	​

P
i
	​

	​

.

Sum the numerators in a balanced tree, remove coefficients proved zero, and apply bounded exact cancellation to the resulting bucket.

Do not perform expensive symbolic monic normalization merely to enlarge the buckets. Failure to recognize denominators that differ by a root-independent unit only misses an early merge; it does not alter the result.

Stage 3: retry descent after each bucket sum

Cross-entry cancellation may make

Q
P
Q
	​

	​


even in r
s
	​

, although its individual leaves were not. Whenever a bucket descends to s, remove it from the root-dependent queue.

Stage 4: GCD-aware balanced rational addition

For two remaining fractions,

f
1
	​

=
Q
1
	​

P
1
	​

	​

,f
2
	​

=
Q
2
	​

P
2
	​

	​

,

compute, under a resource bound,

g=gcd(Q
1
	​

,Q
2
	​

),A=
g
Q
1
	​

	​

,B=
g
Q
2
	​

	​

.

Then

f
1
	​

+f
2
	​

=
gAB
P
1
	​

B+P
2
	​

A
	​

.
	​


This uses the polynomial least common denominator rather than Q
1
	​

Q
2
	​

.

After every merge:

cancel a certified common polynomial factor between numerator and denominator;

retry the r
s
	​

-invariance/descent test;

spill the resulting exact pair to disk;

retain the unreduced exact pair if the bounded GCD or cancellation times out.

Choose merge pairs by:

greatest exact denominator gcd;

smallest predicted output size;

balanced serialized size.

Those choices affect cost only; the addition formula is exact.

Stage 5: sum all descended coefficients in the s-ring

Once terms descend, accumulate them directly in

Q(s,t,u,ϵ,…)

using the same exact denominator-bucket and balanced GCD-aware addition.

The production order is therefore

	​

entrywise exact r
s
	​

-cleanup
→immediate r
s
	​

↦s descent where possible
→equal-denominator buckets
→GCD-aware balanced merges of unresolved r
s
	​

 fractions
→descent after every successful cancellation
→balanced rational sum in s,t,u,ϵ.
	​

	​


This avoids reconstructing the previous 818 MB shard expressions.

4. Exact restoration when numerator and denominator are not separately even

The current nnloInvariantRootRestore first reduces the rational function and then requires both numerator and denominator to contain only even powers of r
s
	​

. That is a valid fast path.

A more complete criterion begins with

F(r
s
	​

)=
Q(r
s
	​

)
P(r
s
	​

)
	​

,P,Q∈K[r
s
	​

],Q

=0.

The rational function descends to a function of s=r
s
2
	​

 if and only if

F(−r
s
	​

)=F(r
s
	​

).
	​


Without dividing, this is the polynomial identity

P(−r
s
	​

)Q(r
s
	​

)−P(r
s
	​

)Q(−r
s
	​

)=0.
	​


This criterion is necessary and sufficient.

Even–odd decomposition

Write uniquely

P(r
s
	​

)=P
e
	​

(s)+r
s
	​

P
o
	​

(s),
Q(r
s
	​

)=Q
e
	​

(s)+r
s
	​

Q
o
	​

(s).

Then

F(−r
s
	​

)=F(r
s
	​

)

is equivalent to

P
e
	​

Q
o
	​

−P
o
	​

Q
e
	​

=0.
	​


If Q
e
	​


=0, the descended function is

F(r
s
	​

)=
Q
e
	​

(s)
P
e
	​

(s)
	​

.
	​


Indeed,

Q
e
	​

P−P
e
	​

Q=r
s
	​

(Q
e
	​

P
o
	​

−P
e
	​

Q
o
	​

)=0.

If Q
e
	​

=0, then Q=r
s
	​

Q
o
	​

. Since Q

=0, one has Q
o
	​


=0, and invariance implies P
e
	​

=0. Therefore

F(r
s
	​

)=
Q
o
	​

(s)
P
o
	​

(s)
	​

.
	​


This method restores every invariant rational function, even when its current numerator and denominator are not individually even.

Wolfram Language structure
Wolfram Language
nnloInvariantRootEvenOddParts[
    polynomial_,
    root_Symbol,
    invariant_Symbol
  ] := Module[
  {rules, even, odd},

  If[! PolynomialQ[polynomial, root],
    Return[$Failed]
  ];

  rules = CoefficientRules[
    polynomial,
    {root}
  ];

  even = Total @ Cases[
    rules,
    Rule[{power_Integer?EvenQ}, coefficient_] :>
      coefficient invariant^(power/2)
  ];

  odd = Total @ Cases[
    rules,
    Rule[{power_Integer?OddQ}, coefficient_] :>
      coefficient invariant^((power - 1)/2)
  ];

  <|"Even" -> even, "Odd" -> odd|>
];

The descent is then:

Wolfram Language
nnloInvariantRootDescend[
    expression_,
    invariant_Symbol,
    root_Symbol,
    timeLimit_: 120
  ] := Module[
  {
    rational, numerator, denominator,
    numeratorParts, denominatorParts,
    pe, po, qe, qo, condition,
    qeStatus, qoStatus, result
  },

  rational = TimeConstrained[
    Quiet @ CheckAbort[
      Check[
        Cancel[Together[expression]],
        $Failed
      ],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];

  If[
    MemberQ[{$Failed, $TimedOut}, rational],
    Return[rational]
  ];

  numerator = Numerator[rational];
  denominator = Denominator[rational];

  numeratorParts =
    nnloInvariantRootEvenOddParts[
      numerator,
      root,
      invariant
    ];

  denominatorParts =
    nnloInvariantRootEvenOddParts[
      denominator,
      root,
      invariant
    ];

  If[
    MemberQ[
      {numeratorParts, denominatorParts},
      $Failed
    ],
    Return[$Failed]
  ];

  {pe, po} = Lookup[
    numeratorParts,
    {"Even", "Odd"}
  ];

  {qe, qo} = Lookup[
    denominatorParts,
    {"Even", "Odd"}
  ];

  condition = nnloExactZeroQ[
    pe qo - po qe,
    timeLimit
  ];

  If[condition =!= True,
    Return[
      If[condition === $TimedOut,
        $TimedOut,
        $Failed
      ]
    ]
  ];

  qeStatus = nnloExactZeroQ[qe, timeLimit];

  result = Which[
    qeStatus === False,
      Cancel[pe/qe],

    qeStatus === True,
      qoStatus = nnloExactZeroQ[qo, timeLimit];
      If[
        qoStatus === False,
        Cancel[po/qo],
        Return[
          If[qoStatus === $TimedOut,
            $TimedOut,
            $Failed
          ]
        ]
      ],

    qeStatus === $TimedOut,
      Return[$TimedOut],

    True,
      Return[$Failed]
  ];

  If[
    FreeQ[result, root] &&
      exactDataQ[result],
    result,
    $Failed
  ]
];

The final Cancel operations should also be bounded in production.

Relation to the current even-power test

If Cancel[Together] has produced a coprime numerator and denominator and

F(−r
s
	​

)=F(r
s
	​

),

then over a characteristic-zero coefficient field the reduced numerator and denominator must both be even. If they were both odd, they would share a factor r
s
	​

, contradicting coprimality.

Thus the current lines 53–59 are an efficient fast path after complete cancellation. The even–odd criterion is the robust fallback when the current presentation has not exposed separate evenness.

Recommended source patches

Parameterize s and facetRs; do not rely on the loading context.

Reject an input already containing the temporary root symbol.

Add an exact rational-grammar check that rejects every other s-dependent analytic head.

Record s>0, r
s
	​

>0, and the mass dimension of r
s
	​

 in the analytic context.

Treat completed Cancel[Together] as the exact production transformation; do not rerun a giant difference per entry.

Keep the current even-numerator/even-denominator restoration as a fast path.

Add the even–odd invariance criterion as the complete rational descent test.

Bound the final Cancel after restoration.

Keep r
s
	​

 during accumulation and descend opportunistically after every exact cancellation.

## Sources sent to Pro

- Original source reference: `../../ppHX_NNLO_DoubleReal/HadronicSimplification/NNLOInvariantRootRing.wl` (not archived with this exchange)
