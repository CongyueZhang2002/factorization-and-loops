# NNLO Coefficient Simplification Assessment

## Question

We now have the corrected exact NNLO Kira artifact and are working only on the subsequent analytic coefficient collection/simplification stage. Please assess the current design and propose a materially faster exact alternative if one exists. The project must return exact Mathematica expressions with Epsilon, endpoint, distributional, branch, cut, and BMHV information; numerical reconstruction without exact verification is not an acceptable final result.

Measured problem:
- 1,296 double-real amplitude/conjugate pair files.
- KiraResult.wl is complete: 44,877 targets reduce to 342 masters; file size about 798 MB.
- Applying the indexed Kira rules and transposing contributions gives about 3.7 GB of per-master records. The largest master files are 1.607 GB and 0.904 GB; the next are 130 MB, 84 MB, 76 MB, 75 MB, and 72 MB, with the rest much smaller.
- Loading the Kira result monolithically expands to tens of GB, so all processing is streamed/indexed.
- Generic Simplify on whole large master coefficients is unusable and previously grew each worker to roughly 5 GB.

Exact algebra benchmarks:
- For an 83.7 MB stored master (308.5 MB Mathematica expression, 2,591 additive terms), exact termwise Cancel took 191 s, produced a 137.7 MB expression / 54.6 MB binary output, and used 1.92 GB maximum memory.
- Cancel[Together[term]] was slower with no size benefit. FactorTerms after simplification greatly expanded the expression and was rejected.
- Four coarse ~400 MB chunks of the largest master ran for 24 minutes with no completion and about 3.2 GB per worker.

Current design:
1. Kira targets are first distributed among 256 disk batches. After applying Kira rules, each batch contributes one already-summed exact expression to each relevant master. Thus the largest master has 256 partial coefficients, not 44,877 separate jobs.
2. Masters below 256 MB are processed directly.
3. Each very large master is split on those existing 256 record boundaries. Each record is simplified by exact Cancel on every additive term in a dynamic worker pool. A bounded term may fall back to the original exact term, never to a numerical approximation.
4. Partial results are combined in a balanced exact 8-way merge tree: 256 -> 32 -> 4 -> 1, simplifying after every merge.
5. Every completed partial/merge has a source hash manifest, so interrupted jobs resume without recomputing completed algebra.

Measured current result for the 1.607 GB master:
- All 256 first-level partial coefficients completed in 35.6 minutes on 4 kernels.
- Memory stayed around 0.8-1.4 GB per worker, with no growth/OOM.
- The first merge level has 32 groups. Four groups finished after roughly 8 minutes on 4 kernels. We are resuming it with 8 kernels.

Questions:
1. Is this record-wise simplification plus balanced merge tree the right exact production architecture?
2. Can the merge cost and final size be reduced substantially by splitting each expression into rational coefficients times inert signatures (Gamma/log/noninteger powers/BMHV/FeynCalc structures)? Give a concrete, safe Mathematica algorithm for choosing rational variables versus inert atoms and grouping signatures.
3. Which exact operation should be used within a signature: Cancel, Together then Cancel, denominator bucketing, polynomial GCD/content extraction, or another method? We need measured reasoning, not a generic recommendation to FullSimplify.
4. How should exact equality and branch safety be verified when structurally different denominator forms make Expand-based equality checks time out?
5. Identify any flaw that could silently lose cancellations across records or alter analytic branches.

Please give actionable pseudocode or Wolfram Language function structure suitable for this concrete expression grammar, and distinguish proven exact transformations from heuristics/fallbacks.

## Pro response

Assessment

The current record-wise exact simplification plus balanced merge tree is production-safe. It has the properties that matter most:

bounded worker memory;

exact timeout fallback;

no dropped terms;

resumable, hash-addressed stages;

eventual inclusion of all 256 records.

It is therefore a valid fallback.

It is probably not the fastest exact representation for the merge levels. The main inefficiency is that every merge reconstructs a large ordinary Mathematica sum and repeatedly traverses identical Gamma functions, noninteger powers, distributions, and FeynCalc/BMHV structures even though only their rational prefactors need algebra.

The most promising replacement is to keep each master coefficient as an exact module

C
m
	​

=
σ
∑
	​

R
m,σ
	​

(ϵ,z)Σ
σ
	​

,

where:

R
m,σ
	​

 is a rational function over a deliberately declared scalar field;

Σ
σ
	​

 is an exactly interned, branch-preserving syntactic signature;

no identity between distinct signatures is assumed.

This should materially reduce the merge cost. It may also reduce first-level work because Cancel sees only the rational factor rather than the full term.

1. Recommended production architecture

Keep the existing 256 record boundaries and manifests, but change what is stored after first-level processing:

Current:
    record expression
      -> termwise Cancel
      -> large Mathematica expression

Recommended:
    record expression
      -> exact rational/signature decomposition
      -> denominator-bucketed rational module
      -> compact module checkpoint

Then merge module maps:

256 module records
    -> 32 merged modules
    -> 4 merged modules
    -> 1 master module
    -> rehydrate signatures once
    -> optional bounded final presentation cleanup

Do not rehydrate the analytic signatures at intermediate merge levels.

The fixed 8-way tree is acceptable, but a byte-budgeted fan-in is better:

Wolfram Language
merge while Total[ByteCount /@ inputs] <= $FACETMergeByteBudget

For the largest masters, a fan-in of 2–4 may be preferable if rational numerator buckets themselves become large. For compact modules, 8-way may remain appropriate.

The already completed 256 first-level outputs for the 1.607 GB master need not be discarded. They can be converted into module records and used as the new leaves.

2. Exact rational/signature decomposition
2.1 Declare the rational field explicitly

Do not automatically treat every symbol as algebraic. Construct an explicit list such as:

Wolfram Language
rationalVariables = {
  Epsilon,
  x1, x2,
  s, t, u,
  Nc, Nf,
  alphaS,
  (* dimension-tagged scalar-product generators *)
  spD1, spD2, spE1, ...
};

Prefer algebraically independent variables. For example, eliminate one of s,t,u using the exact kinematic relation before this stage rather than asking every rational operation to rediscover it.

Treat as rational generators:

Epsilon;

declared invariant and momentum-fraction symbols;

commuting color scalars such as Nc, Nf, CA, CF;

external scalar products after exact canonicalization;

exact integer and rational constants.

Do not treat as rational generators:

Pi, EulerGamma, zeta values;

Gamma, Log, polylogarithms, HPLs/GPLs;

noninteger powers;

distributions and cut objects;

Dirac, Lorentz, color-tensor, spin, or Levi-Civita objects;

Piecewise or ConditionalExpression;

algebraic roots unless a specific algebraic extension is deliberately implemented.

FeynCalc/BMHV scalar products

Commuting scalar products may be replaced by scalar generators, but their dimensions must remain part of their identities. SPD represents a D-dimensional scalar product, whereas SPE represents the D−4-dimensional component; they must never map to the same generator. 
FeynCalc
+1

A safe preliminary pass is:

Wolfram Language
canonical = FeynCalc`FCI[expression];

canonical = canonical /. authorizedExactKinematicRules;

scalarObjects = DeleteDuplicates @ Cases[
  canonical,
  _FeynCalc`Pair,
  Infinity
];

scalarRules = MapIndexed[
  #1 -> Unique["facetScalar$"] &,
  scalarObjects
];

Store the exact reverse dictionary. Reject any scalar product that still contains an integration momentum at this stage.

2.2 Rational grammar

Use a strict structural predicate, not Simplify:

Wolfram Language
ClearAll[rationalExpressionQ];

rationalExpressionQ[
    expression_,
    variableSet_Association
  ] := Which[

  IntegerQ[expression] || RationalQ[expression],
    True,

  AtomQ[Unevaluated[expression]],
    KeyExistsQ[variableSet, Unevaluated[expression]],

  Head[Unevaluated[expression]] === Plus ||
      Head[Unevaluated[expression]] === Times,
    AllTrue[
      List @@ Unevaluated[expression],
      rationalExpressionQ[#, variableSet] &
    ],

  MatchQ[Unevaluated[expression], Power[_, _Integer]],
    rationalExpressionQ[
      Unevaluated[expression][[1]],
      variableSet
    ],

  True,
    False
];

Only literal integer powers are rational. Thus:

Wolfram Language
(x + y)^-2

is rational, while:

Wolfram Language
(x + y)^(-2 Epsilon)
Sqrt[x + y]

are protected signatures.

2.3 Endpoint/distribution variables

A rational field is not automatically a valid coefficient field for distributions.

For a variable z on which a delta or plus distribution is supported, use one of these fail-closed rules:

permit polynomial dependence on z;

permit rational dependence only if every denominator is certified smooth and nonzero on the distribution support;

otherwise place the complete z-dependent factor in the inert signature.

For example, do not let a generic rational normalizer manipulate

1−z
1
	​

[
1−z
1
	​

]
+
	​


as if both factors were ordinary rational functions. The distribution and any uncertified singular multiplier should be held together as one signature.

2.4 Split each additive term
Wolfram Language
topLevelTerms[expression_] :=
  If[Head[expression] === Plus,
    List @@ expression,
    {expression}
  ];

topLevelFactors[term_] :=
  If[Head[term] === Times,
    List @@ term,
    {term}
  ];

Then:

Wolfram Language
splitTerm[
    term_,
    variableSet_Association,
    signatureRegistry_Association
  ] := Module[
  {factors, rationalMask, rationalPart, signaturePart, signatureID},

  factors = topLevelFactors[term];

  rationalMask =
    rationalExpressionQ[#, variableSet] & /@ factors;

  rationalPart =
    Times @@ Pick[factors, rationalMask, True];

  signaturePart =
    Times @@ Pick[factors, rationalMask, False];

  signatureID = internSignature[
    signaturePart,
    signatureRegistry
  ];

  <|
    "SignatureID" -> signatureID,
    "RationalPart" -> rationalPart
  |>
];

This is conservative. If a factor is:

Wolfram Language
x + y Gamma[1 - Epsilon]

the complete factor becomes a signature. FACET misses a possible linear decomposition but cannot change a branch or Gamma identity.

2.5 Stable signature interning

Use one registry for the entire master, not one registry per record.

Wolfram Language
internSignature[
    signature_,
    registry_Association
  ] := Module[
  {held, hash},

  held = With[
    {value = signature},
    HoldComplete[value]
  ];

  hash = Hash[held, "SHA256", "HexString"];

  If[
    KeyExistsQ[registry, hash] &&
      registry[hash] =!= held,
    Return[
      Failure[
        "SignatureHashCollision",
        <|"Hash" -> hash|>
      ]
    ]
  ];

  registry[hash] = held;
  hash
];

HoldComplete uses complete holding semantics and prevents normal evaluation and upvalue processing inside the stored signature. 
Wolfram Documentation
+1

The registry must store the full held expression, not only its hash.

3. Exact rational representation inside one signature
Recommended order

For every raw rational contribution r:

Cancel[r].

Convert to numerator/denominator.

Group by identical normalized denominator.

Add numerators exactly.

Periodically run Cancel[numerator/denominator].

Only optionally combine different denominators with bounded balanced Together.

This ordering matches your measurements.

Cancel cancels the numerator–denominator polynomial GCD but does not generally put a sum over a common denominator. Together constructs a common denominator, typically an LCM, and then cancels. Therefore Cancel[Together[term]] has no reason to help when term is already one rational contribution; it adds common-denominator work without exposing cross-term cancellation. 
Wolfram Documentation
+1

3.1 Canonical fraction
Wolfram Language
needsTogetherQ[expression_] :=
  Head[expression] === Plus &&
    AnyTrue[
      List @@ expression,
      Denominator[#] =!= 1 &
    ];

canonicalFraction[
    rational_,
    variables_List
  ] := Module[
  {value, numerator, denominator},

  value = Cancel[rational];

  If[needsTogetherQ[value],
    value = Cancel[Together[value]]
  ];

  numerator = Numerator[value];
  denominator = Denominator[value];

  If[
    ! PolynomialQ[numerator, variables] ||
      ! PolynomialQ[denominator, variables],
    Return[
      Failure[
        "NonRationalCoefficient",
        <|"Expression" -> rational|>
      ]
    ]
  ];

  <|
    "Numerator" -> numerator,
    "Denominator" -> denominator
  |>
];

A cheap denominator normalization can additionally divide numerator and denominator by a rational leading coefficient obtained from CoefficientRules. Do not factor the denominator merely to create the bucket key.

3.2 Denominator buckets

The module for one signature should be:

Wolfram Language
<|
  denominatorHash1 -> <|
    "Denominator" -> d1,
    "Numerator" -> n1
  |>,
  denominatorHash2 -> <|
    "Denominator" -> d2,
    "Numerator" -> n2
  |>
|>

Insertion is exact:

Wolfram Language
insertFraction[
    buckets_Association,
    fraction_Association
  ] := Module[
  {denominator, numerator, hash, oldNumerator},

  denominator = fraction["Denominator"];
  numerator = fraction["Numerator"];

  hash = Hash[
    HoldComplete[denominator],
    "SHA256",
    "HexString"
  ];

  If[KeyExistsQ[buckets, hash],
    If[
      buckets[hash, "Denominator"] =!= denominator,
      Return[Failure["DenominatorHashCollision", <||>]]
    ];

    oldNumerator = buckets[hash, "Numerator"];
    buckets[hash, "Numerator"] =
      oldNumerator + numerator,

    buckets[hash] = <|
      "Denominator" -> denominator,
      "Numerator" -> numerator
    |>
  ];

  buckets
];

When a bucket exceeds a byte or term threshold:

Wolfram Language
normalizeBucket[bucket_Association] := Module[
  {fraction},

  fraction = canonicalFraction[
    bucket["Numerator"] / bucket["Denominator"],
    rationalVariables
  ];

  fraction
];

If cancellation changes the denominator, remove the old bucket and reinsert the normalized fraction under its new key.

This exposes cancellation among all records with the same signature and denominator without forming an LCM.

3.3 Combining distinct denominator buckets

Do not automatically Together an entire large signature coefficient.

For a bounded number of buckets, use a balanced tree:

Wolfram Language
combinePair[{first_, second_}] :=
  Cancel[Together[first + second]];

balancedTogether[fractions_List] := NestWhile[
  Function[current,
    Map[
      If[Length[#] === 2,
        combinePair[#],
        First[#]
      ] &,
      Partition[current, UpTo[2]]
    ]
  ],
  fractions,
  Length[#] > 1 &
][[1]];

Run this in the same recycled bounded-worker mechanism. If a combine times out, retain:

Wolfram Language
first + second

exactly.

A final coefficient is allowed to remain:

Wolfram Language
n1/d1 + n2/d2 + n3/d3

There is no requirement that it be one rational fraction.

Operation ranking

For this workload:

Per-contribution Cancel on the rational part: default.

Exact denominator bucketing: default.

Cancel after numerator accumulation in one bucket: default.

Bounded balanced Together across a small bucket set: optional.

FactorTermsList on a bounded final numerator: presentation-only experiment.

Factor, FactorTerms, or FullSimplify on a large signature/master: avoid.

FactorTermsList extracts numerical and variable-independent content but does not replace rational cancellation and can still increase representation size; your measured full-expression expansion is sufficient reason not to put it in the hot path. 
Wolfram Documentation

Explicit PolynomialGCD is normally redundant because Cancel already computes the numerator–denominator GCD. It is useful only if you implement a custom pairwise fraction-adder and have measured that it outperforms bounded Together.

4. Module merge structure

A record checkpoint should resemble:

Wolfram Language
<|
  "Format" -> "FACET-RationalSignatureModule",
  "Version" -> 1,
  "RationalVariables" -> rationalVariables,
  "ScalarGeneratorDictionary" -> scalarDictionary,
  "SignatureRegistryFingerprint" -> ...,
  "Terms" -> <|
    signatureID1 -> denominatorBuckets1,
    signatureID2 -> denominatorBuckets2,
    ...
  |>,
  "SourceFingerprint" -> ...
|>

Merging records is then nested association addition:

Wolfram Language
mergeModules[modules_List] := Module[
  {allSignatureIDs},

  allSignatureIDs = Union @@
    (Keys[#["Terms"]] & /@ modules);

  AssociationMap[
    mergeSignatureBuckets[
      DeleteMissing[
        Lookup[
          Lookup[modules, "Terms"],
          #,
          Missing["Absent"]
        ]
      ]
    ] &,
    allSignatureIDs
  ]
];

mergeSignatureBuckets combines equal denominator keys by numerator addition and triggers normalization only when a bucket exceeds its resource threshold.

This removes the need to run termwise Cancel over already normalized terms at every merge level.

5. Rehydration

At finalization:

Wolfram Language
signatureExpression[
    signatureID_,
    registry_Association
  ] :=
  ReleaseHold[registry[signatureID]];

bucketExpression[buckets_Association] :=
  Total[
    (#["Numerator"] / #["Denominator"]) & /@
      Values[buckets]
  ];

rehydrateModule[
    module_Association,
    registry_Association
  ] := Total @ KeyValueMap[
  bucketExpression[#2] *
    signatureExpression[#1, registry] &,
  module["Terms"]
];

Perform the reverse scalar-product replacements after rehydrating signatures.

A bounded final cleanup may be attempted on each signature coefficient separately, not on the whole master.

6. Exact equality without a giant Expand
6.1 Structural decomposition certificate

For every source term, verify immediately:

Wolfram Language
SameQ[
  term,
  rationalPart signaturePart
]

after normal Mathematica canonical ordering. This proves that atomization did not alter the term.

Also verify signature registration:

Wolfram Language
SameQ[
  ReleaseHold[registry[signatureID]],
  signaturePart
]

These are cheap local checks.

6.2 Rational equality per bounded bucket

For two rational forms

d
1
	​

n
1
	​

	​

,
d
2
	​

n
2
	​

	​

,

verify

n
1
	​

d
2
	​

−n
2
	​

d
1
	​

=0.

If the rational variables are algebraically independent, use:

Wolfram Language
CoefficientRules[
  Expand[n1 d2 - n2 d1],
  rationalVariables
] === {}

only at bounded bucket size.

If the variables obey exact polynomial relations, precompute a Gröbner basis and use:

Wolfram Language
Last @ PolynomialReduce[
  n1 d2 - n2 d1,
  groebnerBasis,
  rationalVariables
] === 0

PolynomialReduce gives an exact remainder, and reduction by a Gröbner basis gives the ideal-membership test needed here. 
Wolfram Documentation

Do this per signature or per merge checkpoint. Do not cross-multiply the complete 1.6 GB master.

6.3 End-to-end verification by module subtraction

For regression comparisons:

Wolfram Language
differenceModule = mergeModules[{
  oldModule,
  scaleModule[newModule, -1]
}];

Then check every signature coefficient independently. Equal-denominator buckets cancel by direct numerator addition; only the remaining small set needs cross-denominator rational verification.

This is much cheaper than constructing:

Wolfram Language
Expand[oldExpression - newExpression]
6.4 Exactness by construction

For production, the strongest practical contract is a chain of local exact transformations:

structural term partition;

literal signature intern/restore;

exact numerator addition;

trusted Cancel/Together on certified rational expressions;

exact association merges;

complete source-manifest coverage.

No single global expansion is mathematically necessary.

Finite-field evaluation may be retained as an independent corruption/regression check, but not as the exact proof.

7. Branch and distribution safety

The following transformations are safe in the proposed pipeline:

addition and multiplication of exact rational coefficients;

Cancel within the certified rational field;

bounded Together within one exact signature;

exact reordering of commutative top-level Times factors;

exact interning and restoration of held signatures.

The following must remain prohibited:

Wolfram Language
PowerExpand
ComplexExpand
FunctionExpand
Trig -> True
Extension -> Automatic
generic Simplify before atomization
log expansion or contraction
combining noninteger powers

Do not use Extension -> Automatic in Cancel or Together: it can recognize algebraic dependencies that FACET has not explicitly declared. The Wolfram documentation notes that Extension -> Automatic changes the coefficient field by recognizing algebraic-number relations. 
Wolfram Documentation
+1

Noncommutative structures

Never sort factors inside:

Wolfram Language
FeynCalc`DOT
NonCommutativeMultiply
Dirac chains
ordered color products

Treat the complete ordered word as one signature.

BMHV structures

Do not identify:

Wolfram Language
SP[p, q]
SPD[p, q]
SPE[p, q]

or scalar products with distinct internal momentum-dimension tags. SPD and SPE encode different dimensional subspaces in FeynCalc. 
FeynCalc
+1

Signature granularity

Using signatures that are too coarse can miss cancellation but cannot change the result.

Using signatures that are too fine is dangerous only if FACET then assumes two different IDs are unequal analytically. It should not. Signature IDs are grouping keys, not claims of analytic independence.

In particular:

Wolfram Language
Gamma[1 + Epsilon]
Epsilon Gamma[Epsilon]

should remain distinct signatures unless FACET explicitly implements and certifies the Gamma recurrence. Missing that relation affects compactness only.

8. Silent-failure risks in the current and proposed designs
Current design

The present merge tree does not lose cancellations mathematically, but it may fail to expose them because:

Cancel does not combine distinct denominators;

equivalent branch atoms may be repeatedly traversed without being grouped;

timeouts preserve unsimplified exact terms.

That is a performance issue, not a correctness issue.

Proposed design

The important safeguards are:

One global signature registry per master.
Per-record registries would assign different IDs to equal signatures and lose merge opportunities.

Hash collision checking against full held expressions.

No rational denominator depending on a distribution variable without a smoothness certificate.

No integration momentum in a rational coefficient or signature at this stage.

No independent D; only the declared Epsilon convention.

Atomic checkpoint writes.
Write to a temporary path, close it, hash it, then rename.

Manifest versioning.
Include:

rational-variable set;

scalar-generator dictionary fingerprint;

signature-registry fingerprint;

BMHV and analytic-context fingerprints;

simplifier algorithm/version;

source record hashes.

No deletion based on numerical zero or PossibleZeroQ.
Delete only literal zero or a rational coefficient proven zero exactly.

9. Benchmark before replacing the running path

Use the completed 256 first-level records of the 1.607 GB master.

For each record and for the full set, measure:

number of additive terms
number of unique signatures
terms per signature
number of denominator buckets per signature
bytes in signature registry
bytes in rational buckets
decomposition time
bucket-normalization time
module merge time
rehydrated output size

Compare four variants:

A. Current termwise Cancel + 8-way expression merges
B. Rational/signature module + denominator buckets, no Together
C. B + bounded balanced Together per signature
D. C + optional finite-field reconstruction only for pathological
   rational signature buckets

Exact gates:

each source term reconstructs structurally
each record reconstructs signature-wise
all 256 source hashes are represented exactly once
module result equals the current result signature-by-signature
cuts/topology/master metadata are unchanged
no independent D
no inexact number
no unregistered analytic atom
Expected outcomes

The module approach should give the largest benefit when:

many terms share Gamma/power/distribution/BMHV signatures;

many rational fractions share denominators;

branch-sensitive structures account for a significant fraction of serialized size.

It may provide only a modest improvement if nearly every term has a unique signature and denominator. Even then, rational-only Cancel avoids repeatedly traversing protected structures.

The likely resource pattern is:

first-level CPU: modest to substantial improvement;

merge CPU: potentially substantial improvement;

peak memory: substantial improvement because merges operate on compact maps;

final size: dependent on signature and denominator reuse;

correctness: unchanged.

Production recommendation

Keep the current expression merge tree as a validated fallback. Implement the rational-signature module first on the completed 83.7 MB master and 16–32 records of the 1.607 GB master.

If the module representation substantially reduces either merge time or checkpoint size, convert the already completed 256 leaves and continue the large-master run using module merges. Do not rerun Kira or the contribution-transposition stage.
