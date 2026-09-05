# NNLO Selected Columns

## Question

Continue the same FACET-NLO discussion. I am attaching the actual Mathematica driver that will now construct three complete NNLO double-real UU master coefficients from all 44,877 physical targets and the complete Kira map.

New measured facts since your last review:

1. The corrected positive-root fraction-ring code now completes exact real-data tests for all six NLO UU masters. For every master it constructs every fraction leaf, assembles the full column, identifies the universal factor f1[xa] f1[xb] D1[zh]/(xa xb zh^2), reconstructs the original coefficient exactly, and returns a hard coefficient free of xa, xb, and zh. All 6 x 6 stated identities were True. Runtime including FeynCalc loading was 12.5 s.

2. The complete NNLO catalogue contains 342 masters. The deterministic sample is now:
   - small: master 329, 1 target, estimated product bytes 3,680;
   - median: master 185, 93 targets, estimated product bytes 289,968;
   - hard: master 1, 38,366 targets, estimated product bytes 2,170,045,984.

3. The attached driver scans the already certified physical-target shards and Kira-rule shards with at most three worker kernels because one user-owned kernel is active and the total requested core limit is four. Within each shard it caches repeated physicalized Kira image coefficients, converts each selected contribution into a certified sparse positive-root fraction leaf, and merges equal fraction denominators before writing. It then transposes only these merged records and assembles each complete master sequentially to bound memory.

4. After exact universal-factor extraction, cleanup follows the original analytic workflow rather than a single Simplify: exact rational-shell merging with protected analytic objects; conditional collection by the actual Beta/Hypergeometric master-function basis with local Factor[Cancel[Together]]; then bounded assumption-aware Simplify. A changed expression is accepted only if an exact equality test, or for the final physical step an assumption-aware equality test, succeeds and its byte count does not increase.

Please review the attached driver for mathematical or Mathematica-level errors, especially:

- whether per-shard denominator merging before complete-column assembly is exactly equivalent to direct accumulation;
- whether caching physicalized Kira image coefficients by HoldComplete is safe;
- whether the current common-denominator construction can grow unnecessarily for the 38,366-target column and what exact coefficient-field gcd/lcm implementation you would use instead;
- whether sequential complete-column assembly after a parallel shard scan is the right memory choice;
- any hidden issue in the universal-factor certificate or cleanup acceptance criteria.

Do not propose numerical evaluation as the main result. The deliverable remains the exact analytic coefficient with epsilon, cut, branch, BMHV, endpoint, and distributional information retained.

## Pro response

The mathematical decomposition is sound, but I would not run the 38,366-target hard column with the driver unchanged. Four changes are required first:

fail on missing or nonclosed Kira rows rather than silently omitting their contributions;

fingerprint shard artifacts instead of accepting them by file existence;

replace the in-memory entries = Join[entries, record] assembly by a two-pass column scan;

make the final exactness, fraction-independence, branch, and forbidden-object checks actual predicates rather than stored constants.

The per-shard denominator merge and the physicalized-coefficient cache are mathematically valid under the conditions below.

1. Per-shard denominator merging is exactly equivalent

For a fixed master M
m
	​

, suppose the certified leaves in shard s are

f
s,i
	​

=
D
s,i
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

)
N
s,i
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

)
	​

.

For each exact denominator expression D, the shard code replaces

{i:D
s,i
	​

=D}
∑
	​

D
N
s,i
	​

	​


by

D
{i:D
s,i
	​

=D}
∑
	​

N
s,i
	​

	​

.

Therefore

s
∑
	​

i
∑
	​

f
s,i
	​

=
s
∑
	​

D
∑
	​

D
∑
i:D
s,i
	​

=D
	​

N
s,i
	​

	​

.

This is ordinary associativity and distributivity in the exact coefficient field. The driver implements precisely this sequence: each leaf is certified first, equal denominators are merged inside a shard, and the resulting entries are later merged again across shards. 

BuildNNLOSelectedMasterColumns_…

The equivalence requires:

every relevant target–master contribution appears exactly once;

no timeout or failed leaf is dropped;

the root-variable order is fixed as (y
a
	​

,y
b
	​

,y
h
	​

);

equal-denominator grouping uses exact structural equality;

every leaf already reconstructs its source coefficient exactly.

The current shard function rejects the entire shard when any leaf times out or fails, so it does not silently keep a partial sum. That part is correct. Per-shard merging can fail to recognize two denominators that are mathematically proportional but not syntactically identical; that only misses compression and does not alter the sum.

Retain provenance

The merged record currently retains only denominator, sparse numerator, counts, and byte totals. For an independently auditable result, also retain:

Wolfram Language
"TargetShardHash"
"RuleShardHash"
"TargetKeyFingerprint"
"SelectedMaster"
"RunFingerprint"

The immutable source files plus these fingerprints are enough; individual leaf expressions need not be duplicated in every merged record.

2. The Kira-row handling has a correctness-critical omission
Missing rules are silently interpreted as identity rules

The driver uses

Wolfram Language
rhs = Lookup[rules, target, target];

so a missing rule silently becomes

Wolfram Language
target -> target

for every target, not merely for targets that are declared masters. If that target is not one of the three selected masters, its contribution is then ignored without error. 

BuildNNLOSelectedMasterColumns_…

The correct logic is:

Wolfram Language
rhs = Lookup[rules, target, Missing["NoRule"]];

If[MissingQ[rhs],
  If[
    KeyExistsQ[declaredMasterSet, target],
    rhs = target,
    Return[$Failed, Module]
  ]
];

Construct once:

Wolfram Language
declaredMasterSet = AssociationThread[
  metadata["Masters"],
  ConstantArray[True, Length[metadata["Masters"]]]
];
Unexpected terminal GLIs are silently ignored

After

Wolfram Language
image = linearIntegralSum[rhs];

the code iterates through image["Terms"] but retains only terms whose master belongs to selectedSet. It never verifies that every other GLI is a declared master. An undeclared Kira terminal would therefore be ignored rather than rejected. 

BuildNNLOSelectedMasterColumns_…

Add:

Wolfram Language
unexpected = Select[
  Keys[image["Terms"]],
  ! KeyExistsQ[declaredMasterSet, #] &
];

If[unexpected =!= {},
  Return[$Failed, Module]
];
Duplicate Kira rules currently overwrite one another

readRuleShard uses AssociateTo directly. If the same left-hand side occurs twice, the later rule silently replaces the earlier rule. 

BuildNNLOSelectedMasterColumns_…

Permit identical duplicates and reject conflicting ones:

Wolfram Language
readRuleShard[file_String] := Catch[
  Module[{rules = <||>, count},

    count = FeynFacet`Private`coefficientScanRecords[
      file,
      Function[record,
        If[! AssociationQ[record],
          Throw[$Failed, "RuleShardFailure"]
        ];

        KeyValueMap[
          Function[{lhs, rhs},
            If[
              KeyExistsQ[rules, lhs] &&
                ! SameQ[rules[lhs], rhs],
              Throw[$Failed, "RuleShardFailure"]
            ];
            AssociateTo[rules, lhs -> rhs]
          ],
          record
        ];

        True
      ]
    ];

    If[count === $Failed, $Failed, rules]
  ],
  "RuleShardFailure"
];

The use of Catch/Throw is preferable here because Return exits the innermost active control construct, which can be easy to misread inside nested callbacks. 
Wolfram Documentation Center

Compare the final leaf count to the catalogue

For each selected master, the catalogue already gives the number of targets with a nonzero coefficient:

1,93,38366.

After the complete column is assembled, require

Wolfram Language
column["LeafCount"] === expectedTargetCount

for that master. This catches missing rules, omitted target shards, and accidental zeroing in one inexpensive check.

3. Caching by HoldComplete is mathematically safe

The cache key is

Wolfram Language
imageKey = HoldComplete[rawImageCoefficient];

inside the named pure function whose formal parameter is rawImageCoefficient. Wolfram Function replaces formal parameters with its actual arguments before evaluating the body, while HoldComplete then prevents the substituted coefficient from evaluating further. Thus the key is the exact structural Kira coefficient, not the literal local symbol. 
Wolfram Documentation Center
+1

The cache is valid because physicalImageCoefficient depends only on:

raw coefficient,ReverseRules,DimensionRule,HadronicVariables,BranchRules,

and the latter four are immutable during one shard calculation.

Two structurally identical raw coefficients therefore have the same physicalized coefficient. Two algebraically equal but structurally different coefficients merely produce separate cache entries; that affects performance, not correctness.

I would nevertheless make the value capture explicit:

Wolfram Language
imageKey = With[
  {coefficientValue = rawImageCoefficient},
  HoldComplete[coefficientValue]
];

With is the standard way to insert a value into a completely held expression. 
Wolfram Documentation Center
+1

Additional fail-closed checks

physicalImageCoefficient should reject all abnormal statuses explicitly:

Wolfram Language
If[
  physical === $Failed ||
    physical === $TimedOut ||
    physical === $Aborted ||
    FailureQ[physical],
  Return[$Failed]
];

Then require after canonicalization:

Wolfram Language
ttExactDataQ[physical] &&
FreeQ[
  physical,
  Alternatives @@ Join[
    nnloFractionVariables,
    nnloRootVariables
  ]
] &&
FreeQ[
  physical,
  _FeynCalc`GLI | System`D |
  _FeynCalc`Pair | _FeynCalc`DiracTrace |
  _FeynCalc`DiracGamma | _FeynCalc`DOT |
  _FeynCalc`SPE
]

The cache is local to one shard, so its key does not need a context fingerprint. A persisted cache would need one.

4. Existing shard files can be stale and are accepted without verification

A shard is considered complete whenever its output and summary files both exist:

Wolfram Language
! FileExistsQ[output] || ! FileExistsQ[summary]

No code, context, Kira, target, or input-file fingerprint is checked. 

BuildNNLOSelectedMasterColumns_…

This is unsafe because the same output directory can contain records generated with:

an earlier NNLOFractionRing.wl;

different branch rules;

a different physical-target transformation;

a different Kira rule store;

a different selected-master set;

an older driver.

Define a run payload before shard processing:

Wolfram Language
runPayload = <|
  "Selection" -> selection,
  "PhysicalManifestFingerprint" ->
    physicalManifest["Fingerprint"],
  "KiraMetadataFingerprint" ->
    metadata["InputFingerprint"],
  "HadronicContextFingerprint" ->
    Hash[context, "SHA256", "HexString"],
  "FractionRingSourceHash" ->
    FileHash[fractionRingFile, "SHA256"],
  "DriverSourceHash" ->
    FileHash[ExpandFileName[$InputFileName], "SHA256"]
|>;

runFingerprint = Hash[
  runPayload,
  "SHA256",
  "HexString"
];

Each shard summary should additionally contain:

Wolfram Language
"RunFingerprint" -> runFingerprint
"TargetFileHash" -> FileHash[job["TargetFile"], "SHA256"]
"RuleFileHash" -> FileHash[job["RuleFile"], "SHA256"]
"OutputFileHash" -> FileHash[job["OutputFile"], "SHA256"]

A shard is reusable only when all fields agree.

Also validate all parallel results:

Wolfram Language
If[
  ! ListQ[pendingShardSummaries] ||
    ! AllTrue[pendingShardSummaries, AssociationQ],
  (* fail *)
];

The current test

Wolfram Language
MemberQ[pendingShardSummaries, $Failed]

does not reject $Aborted, Failure[...], a malformed atom, or a non-list result. The same issue occurs for columnSummaries. 

BuildNNLOSelectedMasterColumns_… +1

5. The current complete-column stage is sequential, but it is not memory-streamed

Processing the three columns sequentially is the correct outer policy:

small→median→hard.

Parallel complete-column assembly would multiply the peak memory of the hard column.

However, the implementation first loads every entry into one list:

Wolfram Language
entries = Join[entries, record];

and then constructs a second grouped representation:

Wolfram Language
grouped = nnloMergeFractionEntries[entries];

before assembling the column. 

BuildNNLOSelectedMasterColumns_…

For the 38,366-target column this has two problems:

repeated Join copies the growing list on every shard record;

entries, grouped, and later column coexist in memory.

The earlier transposition is itself memory bounded—it reads one shard and appends one list per selected master—but the later processCompleteColumn reverses that advantage. 

BuildNNLOSelectedMasterColumns_…

Replace it with a two-pass scan
First pass: denominator inventory

Scan the master input file without retaining numerators:

{D
e
	​

}
e=1
N
m
	​

	​

⟶L
m
	​

=lcm
K[y
a
	​

,y
b
	​

,y
h
	​

]
	​

D
e
	​

.

Also accumulate:

LeafCount;

number of shard records;

normalized denominator profiles;

input hashes.

Second pass: numerator accumulation

For each entry e, compute

Q
e
	​

=
D
e
	​

L
m
	​

	​

∈K[y
a
	​

,y
b
	​

,y
h
	​

],

then add

N
e
	​

Q
e
	​


to the sparse numerator map.

Process one shard record at a time. A practical exact implementation forms at most 256 shard-level sparse maps and then combines those maps in a balanced tree. It never holds 38,366 leaf entries simultaneously.

Schematically:

Wolfram Language
(* Pass 1 *)
commonData = scanDenominators[
  job["InputFile"]
];

(* Pass 2 *)
chunkFiles = scanNumeratorsByShard[
  job["InputFile"],
  commonData["CommonDenominator"]
];

assembledNumerator = balancedMergeSparseMaps[
  chunkFiles
];

This is the correct memory-bounded interpretation of “sequential complete-column assembly.”

6. Use an LCM over the correct coefficient field

Let

K=FracQ[s,t,u,ϵ,color generators,inert analytic generators]/I,

where I contains the exact declared kinematic and color relations. The fraction denominators are polynomials in

y=(y
a
	​

,y
b
	​

,y
h
	​

)

with coefficients in K:

D
e
	​

∈K[y].

A bare PolynomialLCM is not the appropriate defining operation for this ring. Wolfram documents that PolynomialGCD treats all symbolic parameters as polynomial variables; PolynomialLCM uses the corresponding polynomial algebra rather than an explicit user-specified root-variable list. 
Wolfram Documentation Center
+1

After monic normalization in y, it may often produce the desired result, but rational functions of s,t,u,ϵ and inert analytic coefficients can still lead to unnecessary products or expensive failure paths.

Exact coefficient-field factor-profile method

For each normalized denominator D
e
	​

:

Obtain its coefficients in y:

D
e
	​

=
ν
∑
	​

c
e,ν
	​

(θ)y
ν
.

Apply Together only to each coefficient c
e,ν
	​

, not to the complete master.

Multiply by any exact common multiple of the coefficient denominators, obtaining

D
e
	​

∈Q[θ,y].

Remove the factor independent of y. It is a unit in K.

Factor the resulting primitive polynomial under a bound:

D
e
prim
	​

=
j
∏
	​

q
e,j
r
e,j
	​

	​

.

Retain only factors depending on y, and normalize each factor to leading coefficient one in a fixed lexicographic order.

If factorization times out, retain the complete monic denominator as one indivisible factor. This is less economical but exact.

The common denominator is then

L
m
	​

=
q
∏
	​

q
max
e
	​

r
e
	​

(q)
.

This is an exact LCM when the factorization is complete. With unresolved denominators retained atomically, it remains an exact common multiple, though not necessarily minimal.

Exact divisibility certificate

For every denominator D
e
	​

, certify that

L
m
	​

=Q
e
	​

D
e
	​

,Q
e
	​

∈K[y].

Use PolynomialReduce/PolynomialReduction with the root variables explicitly specified and the coefficient domain set to rational functions. Wolfram documents that this mode treats all other symbols as parameters in a rational-function coefficient field. 
Wolfram Documentation Center

For example:

Wolfram Language
nnloKPolynomialQuotient[
    dividend_,
    divisor_
  ] := Module[{quotients, remainder},

  {quotients, remainder} = PolynomialReduce[
    dividend,
    {divisor},
    nnloRootVariables,
    CoefficientDomain -> RationalFunctions
  ];

  If[
    Length[quotients] === 1 &&
      nnloExactZeroQ[remainder, 60] === True &&
      PolynomialQ[First[quotients], nnloRootVariables],
    First[quotients],
    $Failed
  ]
];

After constructing L
m
	​

, require this certificate for every distinct denominator. If factor analysis is unavailable, the exact fallback is simply

L
new
	​

=L
old
	​

D
e
	​

,

followed by normalization and divisibility checks. This can grow, but it cannot give a wrong coefficient.

Scheduling heuristic

Once the exact factor profiles exist, process denominators with the greatest factor overlap first. This reduces intermediate growth but is only a scheduling choice. The factor-profile maxima and divisibility certificates establish the mathematics.

7. Universal-factor acceptance is almost correct, but the driver needs final guards

The driver correctly requires both

Wolfram Language
certificate["Verified"]
certificate["FractionFree"]

before accepting the hard coefficient. 

BuildNNLOSelectedMasterColumns_…

Assuming the corrected nnloCertifyUniversalFactor is the version that succeeded for all six NLO UU masters, the proportionality proof is suitable for the three NNLO columns.

The driver should additionally require that the certificate contains:

Wolfram Language
"DistributionFactor" ->
  f1[xa] f1[xb] D1[zh]

"UniversalRootExponent" ->
  {-2, -2, -4}

"ColumnReconstructionVerified" -> True

"CoefficientFieldConvention" ->
  "FormalRationalFunctionsWithInertAnalyticAtoms"

and store these fields in the output rather than relying on global definitions loaded from NNLOFractionRing.wl.

Do not hard-code exactness

The output currently contains

Wolfram Language
"ExactData" -> True

without evaluating an exactness predicate. 

BuildNNLOSelectedMasterColumns_…

Replace it with:

Wolfram Language
exactData = ttExactDataQ @ HoldComplete[
  column,
  certificate,
  hard,
  cleanup["Expression"]
];

fractionFree = FreeQ[
  cleanup["Expression"],
  Alternatives @@ Join[
    nnloFractionVariables,
    nnloRootVariables
  ]
];

forbiddenFree = FreeQ[
  cleanup["Expression"],
  System`D |
  _FeynCalc`GLI |
  _FeynCalc`Pair |
  _FeynCalc`SPE |
  _FeynCalc`DiracTrace |
  _FeynCalc`DiracGamma |
  _FeynCalc`DOT
];

If[! TrueQ[exactData && fractionFree && forbiddenFree],
  Return[$Failed]
];

For UU, any residual BMHV object should be rejected.

The output should also carry the Kira input fingerprint, analytic-context fingerprint, master cut data, and branch-registry fingerprint. The scalar coefficient routines do not change the master itself, but the durable artifact must identify which cut master the coefficient multiplies. The project contract explicitly requires cuts, branches, prescriptions, and BMHV information to remain linked to the exact analytic result. 

AGENTS

8. Cleanup acceptance never accepts an unproved change, but its status reporting is misleading

The three cleanup stages accept a candidate only when an equality check returns True and the candidate is no larger. This is mathematically conservative. 

BuildNNLOSelectedMasterColumns_…

However, timeout, formal mismatch, and checker failure are all collapsed into the Boolean value False. For example, an equality-check timeout after a successfully computed candidate is recorded as:

Wolfram Language
"Outcome" -> "Computed"
"Equality" -> False

That should be one of:

Wolfram Language
"EqualityStatus" -> "Verified"
"EqualityStatus" -> "TimedOut"
"EqualityStatus" -> "FormalMismatch"
"EqualityStatus" -> "Failed"

Only "Verified" permits acceptance.

For the assumption-aware stage:

Wolfram Language
equalityResult = TimeConstrained[
  FullSimplify[
    candidate == current,
    Assumptions -> workerAssumptions
  ],
  120,
  $TimedOut
];

equalityStatus = Which[
  TrueQ[equalityResult], "Verified",
  equalityResult === $TimedOut, "TimedOut",
  equalityResult === False, "NotProved",
  True, "Failed"
];

A result of False should normally be described as “not proved equal under this checker,” unless an independent argument establishes that the expression is genuinely nonzero.

Other cleanup patches

ttHistoricalFunctionalBasis[current] is called before testing whether current is below 64 MiB. Move the basis construction inside the size guard and place a time bound around it. 

BuildNNLOSelectedMasterColumns_…

Reject $Aborted and Failure[...] as well as $Failed and $TimedOut.

After every accepted candidate, recheck exact data and fraction independence.

Reject newly introduced ConditionalExpression, Piecewise, Abs, Sign, or unresolved noninteger-power branches unless the branch registry explicitly certifies them.

Preserve the exact endpoint/distribution heads and arguments unless an explicit distributional identity is part of the cleanup.

9. Recommended patch order before executing the hard column
Required before any new run

Replace missing-rule identity fallback with the declared-master-only rule.

Reject every undeclared terminal GLI.

Detect conflicting duplicate Kira rules.

Add run and per-shard fingerprints; do not reuse files by existence alone.

Validate parallel results with ListQ and AllTrue[..., AssociationQ].

Compare each completed master’s LeafCount with 1, 93, or 38366.

Compute rather than hard-code "ExactData".

Required before master 1

Replace entries = Join[entries, record] with the two-pass column scan.

Replace or wrap the coefficient-domain-blind PolynomialLCM with the factor-profile construction and exact rational-function divisibility checks.

Run the hard column in isolation after the small and median columns establish the expected counts and certificates.

Useful but not correctness-critical

Make the HoldComplete cache key explicit with With.

Separate cleanup timeout, mismatch, and failure statuses.

Move historical-basis discovery inside its resource bound.

Store the analytic-context, Kira, branch, and master-record fingerprints in every complete-column artifact.

With these patches, the driver has the correct mathematical structure:

	​

certified physical targets⟶closed exact Kira rows
⟶certified positive-root leaves⟶exact shard-local denominator merging
⟶two-pass complete-column assembly over K[y
a
	​

,y
b
	​

,y
h
	​

]
⟶
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

)
	​

H
m
	​

(s,t,u,ϵ,…),
	​

	​


with H
m
	​

 proved fraction-independent and every subsequent compactification accepted only after an exact equality certificate.

## Sources sent to Pro

- [buildnnloselectedmastercolumns.wls](Sources/14_nnlo_selected_columns/buildnnloselectedmastercolumns.wls)
