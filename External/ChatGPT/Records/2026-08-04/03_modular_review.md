# Modular Review

## Question

_The question was not preserved in the local bridge record._

## Pro response

Not fully production-safe yet. The modular split is justified and the main algebraic architecture is sound, but several fail-closed gaps remain in topology-record validation, dimensional-shift output validation, and Kira import handling.

1. P0 correctness defects
P0.1 — Missing causal certification defaults to "Verified"

Function: topologyRecordQ

Current code:

Wolfram Language
Lookup[amflow, "PhysicalCausalStatus", "Verified"] === "Verified"

A record with no certification field passes. This directly violates fail-closed semantics.

Require the key and remove the permissive default:

Wolfram Language
If[
  ! ContainsAll[
    Keys[amflow],
    {
      "Family", "Loop", "Prescription", "Cut",
      "PhysicalCausalStatus"
    }
  ],
  Return[False]
];

...

Lookup[
  amflow,
  "PhysicalCausalStatus",
  Missing["Absent"]
] === "Verified"

Also require the topology-record schema itself:

Wolfram Language
Lookup[record, "Type", Missing[]] ===
  "FeynFacetTopologyRecord" &&
Lookup[record, "Version", Missing[]] === 2

Required test: delete "PhysicalCausalStatus" from an otherwise valid record and verify that TopologyEquivalence rejects it.

P0.2 — The analytic context records the gamma scheme but does not enforce BMHV

Functions:

analyticContext

validPreIBPResultQ

ibpInputData

Current code accepts:

Wolfram Language
scheme = Missing["NotAvailable"]

or a non-BMHV scheme, fingerprints it, and proceeds. The scientific contract specifically requires BMHV information.

Fail before constructing the context:

Wolfram Language
scheme = Quiet @ Check[
  FeynCalc`FCGetDiracGammaScheme[],
  $Failed
];

If[scheme =!= "BMHV",
  preIBPFail["the active Dirac gamma scheme is not BMHV"]
];

The context should also include the data that determine branch and distribution handling:

Wolfram Language
context = <|
  "Gamma5Scheme" -> scheme,
  "GlobalBasis" -> globalBasis,
  "GlobalBasisGram" -> GlobalBasisGram,
  "SetEvanescentZero" -> process["SetEvanescentZero"],
  "SetMassZero" -> process["SetMassZero"],
  "SetDistributionZero" -> process["SetDistributionZero"],
  "Assumptions" -> process["Assumptions"],
  "LoopDimension" -> System`D,
  "DimensionRule" -> $dimensionRule,
  "CutConvention" -> "OrientedPositiveEnergyDelta",
  "DistributionConvention" -> "FeynFacet/Distributions.wl",
  "FeynFacetSourceHash" -> $feynFacetSourceHash
|>;

validPreIBPResultQ must verify that the top-level context equals the context in every topology record:

Wolfram Language
context = result["AnalyticContext"];

AssociationQ[context] &&
Lookup[context, "Fingerprint", Missing[]] ===
  reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
AllTrue[
  result["Topologies"],
  SameQ[#["AnalyticContext"], context] &
]

At present, a persisted artifact can advertise context B while its topology records were constructed under context A.

Required tests:

BMHV passes.

NDR/Larin/unknown scheme fails.

Changing only the top-level analytic context invalidates the artifact.

Changing only one topology’s context invalidates the artifact.

P0.3 — An active physical denominator can still be silently classified as auxiliary

Functions:

BuildTopologies

topologyPropagatorData

completeTopologyRecord

topologyRecordQ

Current behavior:

Wolfram Language
factors === {}  ->  "Role" -> "Auxiliary"

There is no check that the corresponding slot has zero power in the original family. If physical-source matching fails unexpectedly, a genuine denominator can become an auxiliary slot and the record can still be certified.

Store the mapped base GLI when constructing the family:

Wolfram Language
mappedFamily = Quiet @ CheckAbort[
  converted[[1]] /.
    FeynCalc`FCLoopCreateRuleGLIToGLI[
      completed,
      converted[[2]]
    ],
  $Failed
];

baseGLIs = Cases[mappedFamily, _FeynCalc`GLI, Infinity];

If[Length[baseGLIs] =!= 1,
  Message[BuildTopologies::term, term];
  Throw[$Failed, $buildTopologiesFailure]
];

baseGLI = First[baseGLIs];
familyCoefficient = mappedFamily /. baseGLI -> 1;

Store:

Wolfram Language
"BaseGLI" -> baseGLI,
"FamilyCoefficient" -> familyCoefficient

Then in topologyPropagatorData:

Wolfram Language
activeSlots = Flatten @ Position[
  family["BaseGLI"][[2]],
  _Integer?Positive,
  {1},
  Heads -> False
];

Require:

Wolfram Language
If[
  MemberQ[activeSlots, index] && factors === {},
  Return[$Failed]
];

If[
  ! MemberQ[activeSlots, index] && factors =!= {},
  Return[$Failed]
];

Additionally, every loop-dependent source factor should match exactly one topology slot. Give each source a stable "SourceID" and reject unmatched or multiply matched source IDs.

This also removes repeated FCLoopToGLI work from DimensionalShift.

Required tests:

Mutate the source core of one active denominator; record construction must fail rather than mark it auxiliary.

Completion slots remain auxiliary.

Every physical source is consumed exactly once.

Dotted source denominators preserve their source power in metadata.

P0.4 — restoreCutTerm still identifies cuts by line momentum rather than denominator core

Functions:

cutIndex

restoreCutTerm

Current code:

Wolfram Language
sameMomentumQ[propagatorMomentum, cutMomentum]

can misclassify q
2
−m
2
 as the cut q
2
. The earlier cut/ordinary collision check does not prevent this because those cores are different.

Build exact cut descriptors:

Wolfram Language
cutDescriptors = Map[
  Function[{record},
    With[
      {
        core = topologyPropagatorCore[
          FeynCalc`SFAD[First[record]],
          {},
          {}
        ]
      },
      If[core === $Failed, Return[$Failed]];
      <|
        "Momentum" -> First[record],
        "Direction" -> Last[record],
        "UnitCore" -> core
      |>
    ]
  ],
  cutRecords
];

Replace cutIndex by:

Wolfram Language
cutIndex[propagator_, cutDescriptors_List] := Module[
  {descriptor},

  descriptor = propagatorDescriptor[propagator];
  If[descriptor === $Failed, Return[$Failed]];

  FirstCase[
    Range[Length[cutDescriptors]],
    i_ /; exactZeroQ[
      descriptor["UnitCore"] -
        cutDescriptors[[i, "UnitCore"]]
    ] :> i,
    Missing["NotCut"]
  ]
];

Use the descriptor both in restoreCutTerm and any public cut-slot discovery path.

Also move:

Wolfram Language
cutRecords = cutData[expr]

before:

Wolfram Language
If[loopMomenta === {}, Return[expr]]

so malformed zero-loop cuts do not bypass validation.

Required tests:

A massless cut q
2
 plus an ordinary denominator q
2
−m
2
 is not conflated.

A momentum sign reversal still maps correctly.

An invalid zero-loop cut direction fails.

P0.5 — The dimensional-shift result is not certified to have loop-free coefficients

Functions:

DimensionalShift

dimensionalShiftNormalizeNumerator

The current postcondition checks unresolved SP, SPD, and SPE, but an unsupported object such as

Wolfram Language
f[k1] FeynCalc`GLI[...]

can pass.

At the end of the single-family shift:

Wolfram Language
parts = linearIntegralSum[result];

If[
  FailureQ[parts] ||
    ! exactZeroQ[parts["Remainder"]] ||
    ! FreeQ[
      Values[parts["Terms"]],
      Alternatives @@ loopMomenta
    ],
  Message[
    DimensionalShift::numerator,
    "the shifted GLI coefficients are not loop-momentum free"
  ];
  Throw[$Failed, $dimensionalShiftFailure]
];

The GLI-free remainder should be zero for a nonzero-loop integral family.

The implementation also rejects the valid one-argument form SPE[k]. FeynCalc defines SPE[k] to mean SPE[k,k]. 
FeynCalc

Extend the grammar:

Wolfram Language
validSPEQ[FeynCalc`SPE[a_]] :=
  MemberQ[loopMomenta, a];

validSPEQ[FeynCalc`SPE[a_, b_]] :=
  MemberQ[loopMomenta, a] &&
    MemberQ[loopMomenta, b];

and:

Wolfram Language
spePair[FeynCalc`SPE[a_]] := Module[{i},
  i = First @ FirstPosition[loopMomenta, a];
  {i, i}
];

spePair[FeynCalc`SPE[a_, b_]] := {
  First @ FirstPosition[loopMomenta, a],
  First @ FirstPosition[loopMomenta, b]
};

Required tests:

SPE[k] agrees exactly with SPE[k,k].

A coefficient containing f[k] is rejected.

A shifted family with a nonzero GLI-free remainder is rejected.

One-loop and two-loop existing fixtures remain identical.

P0.6 — Kira imports are not shape-validated and cut-pinched GLIs are not audited

Functions:

ibpImportRules

ibpCloseReductionRules

ibpValidateMasters

CheckAbort catches an abort, but does not prove that KiraImportResults returned a list of rules. Validate explicitly:

Wolfram Language
imported = Quiet @ CheckAbort[
  Check[
    FeynCalc`KiraImportResults[
      name,
      path,
      FeynCalc`FCReplaceD -> {dimension},
      FeynCalc`FCVerbose -> -1
    ],
    $Failed
  ],
  $Failed
];

If[
  imported === $Failed ||
    ! ListQ[imported] ||
    ! AllTrue[
      imported,
      MatchQ[#, _Rule | _RuleDelayed] &
    ],
  ibpFail[
    "Kira import",
    "the imported reduction table is not a list of rules: " <> path
  ]
];

Add one shared cut validator:

Wolfram Language
validateCutGLIs[expression_, records_List] := Module[
  {recordByName, glis, bad},

  recordByName = Association[
    #["Topology"][[1]] -> # & /@ records
  ];

  glis = DeleteDuplicates @ Cases[
    HoldComplete[expression],
    _FeynCalc`GLI,
    Infinity
  ];

  bad = Select[
    glis,
    Function[gli,
      ! KeyExistsQ[recordByName, gli[[1]]] ||
      Length[gli[[2]]] =!=
        Length[recordByName[gli[[1]], "Topology"][[2]]] ||
      ! AllTrue[
        gli[[
          2,
          recordByName[gli[[1]], "CutIndices"]
        ]],
        IntegerQ[#] && Positive[#] &
      ]
    ]
  ];

  If[bad === {}, True, bad]
];

Run it on:

all imported rules;

closure["Images"];

declared masters;

final sparse master keys.

The present final-master-only check is insufficient to certify that cut_propagators was correctly applied throughout the imported system.

Required tests:

Import returning $Failed, an unevaluated call, or a non-rule list fails immediately.

Injecting a cut-pinched GLI into an imported RHS fails.

Wrong GLI arity fails.

Existing Kira fixtures pass unchanged.

P0.7 — ibpCompleteKinematics makes topology records internally inconsistent

Function: ibpCompleteKinematics

The function replaces:

Wolfram Language
record["Topology"]

with a topology containing generated ffsp rules but leaves:

Wolfram Language
record["PropagatorData", All, "Algebraic"]

computed under the old kinematic rules. The records stored in the Kira artifact are therefore no longer guaranteed to satisfy topologyRecordQ.

Do not mutate physical topology records. Return separate objects:

Wolfram Language
<|
  "PhysicalRecords" -> records,
  "KiraFamilies" -> MapThread[
    <|
      "Topology" -> #2,
      "CutIndices" -> #1["CutIndices"]
    |> &,
    {records, augmentedTopologies}
  ],
  "MassDimensions" -> massDimensions,
  "ReverseRules" -> reverseRules
|>

Use "KiraFamilies" only for Kira export. Store the original validated representative records under:

Wolfram Language
"Topologies"

in the Kira and final artifacts.

If augmented records are needed for diagnostics, recompute every algebraic descriptor under the augmented rules and validate them separately.

Required tests:

Wolfram Language
AllTrue[
  kiraResult["Topologies"],
  safeTopologyRecordQ
]

must remain true after kinematic completion.

Also verify that the Kira-exported topology names and propagator ordering agree with the physical records.

P0.8 — Every Kira invariant is assigned mass dimension two without proof

Function: ibpCompleteKinematics

Current code:

Wolfram Language
massDimensions =
  Thread[DeleteDuplicates[invariants] -> 2];

This is valid only if every returned symbol is a mass-squared invariant. The package supports symbolic momentum fractions, so this must be certified rather than assumed.

Introduce a declared dimension map in the normalized context, for example:

Wolfram Language
"KinematicMassDimensions" -> <|
  s -> 2,
  t -> 2,
  u -> 2,
  x -> 0,
  z -> 0
|>

The public function signatures remain unchanged; this can be an optional configuration field.

Generated ffsp symbols are dimension two. For every other symbol:

Wolfram Language
missingDimensions = Complement[
  invariants,
  Keys[dimensionMap]
];

If[missingDimensions =!= {},
  ibpFail[
    "kinematic completion",
    "missing mass dimensions for " <>
      ToString[missingDimensions, InputForm]
  ]
];

Never default an unknown invariant to dimension two.

Required tests:

s,t,u receive dimension two.

x,z receive dimension zero.

An undeclared invariant aborts Kira project generation.

Existing Kira YAML remains unchanged for current NLO fixtures.

P0.9 — Approximate scientific input is not rejected

Functions:

normalizeProcess

GenerateCollinearFactorizePreIBPResult

ibpImportRules

final artifact construction

Add to Core.wl:

Wolfram Language
inexactNumberQ[value_] :=
  NumberQ[value] && ! ExactNumberQ[value];

exactDataQ[expression_] := FreeQ[
  HoldComplete[expression],
  value_ /; inexactNumberQ[value]
];

Validate all scientific fields, excluding timestamps and paths. At minimum:

normalized process data;

factorized expressions;

topology records;

imported Kira rules;

final coefficients and prefactors.

A machine number such as 0.5 must not silently turn the production path into an approximate calculation.

Required tests:

1/2 passes.

0.5 fails.

arbitrary-precision reals fail unless an explicit verification-only path is used.

no machine reals occur in stored scientific fields.

P0.10 — The zero-topology Kira branch does not produce a usable reduction artifact

Function: ibpKiraReductionCore

When:

Wolfram Language
records === {}

the returned artifact omits:

SourceInputFingerprint;

ReductionInputFingerprint;

DimensionRule;

a normal empty topology-equivalence object.

CoefficientSimplification then rejects the artifact.

Construct the same schema in both branches. For the empty case, compute the source fingerprint from the empty record and target sets and use:

Wolfram Language
"TopologyEquivalence" -> <|
  "Scope" -> "CutAwareIBP",
  "PhysicalCausalStatus" -> "NoTopologies",
  "SearchStatus" -> "Complete",
  "Representatives" -> {},
  "Classes" -> {},
  "Mappings" -> {},
  "GLIRules" -> {},
  "RejectedCandidateMappings" -> {}
|>

The empty reduction should allow the GLI-free remainder to flow through coefficient normalization.

Required test: run IBP on a valid leading-order pre-IBP artifact with no topology records and verify exact reconstruction.

2. Prioritized concrete code reductions
Priority 1 — Repair the module dependency graph

The split is physically useful, but three reverse dependencies remain:

Topologies.wl calls reductionFingerprint, defined in Reduction.wl.

Topologies.wl calls dimensionalShiftParameterPosition, defined in DimensionalShift.wl.

DimensionalShift.wl calls linearIntegralSum, linearAdd, and linearToExpression, defined in Reduction.wl.

Move to Core.wl:

Wolfram Language
exactZeroQ
exactRationalQ
reductionFingerprint
linearIntegralSum
linearIntegralSumQ
linearToExpression
linearDropZeros
linearMapCoefficients
linearAdd
linearMapIntegrals

These are general exact-algebra utilities, not Kira functionality.

Move and rename:

Wolfram Language
dimensionalShiftParameterPosition

to Topologies.wl as:

Wolfram Language
topologyPropagatorIndex

It is a topology-slot mapping operation, not a dimensional-shift kernel.

After this change the dependency direction becomes:

Core
├── Process
├── Topologies
│   └── DimensionalShift
└── Process + Topologies + DimensionalShift
    └── Collinear
        └── Reduction

This is the highest-value maintainability patch.

Priority 2 — Delete redundant validators and wrappers

After the P0 fixes:

Delete safeTopologyRecordQ

Make the public predicate itself safe:

Wolfram Language
topologyRecordQ[record_] := TrueQ @ Quiet @ CheckAbort[
  Check[topologyRecordQCore[record], False],
  False
];
Delete topologyNormalizeEtaSigns

topologyRecordQ already requires every algebraic eta sign to be +1. Pass the stored topology directly to FCLoopFindTopologyMappings.

Merge validStoredTopologyQ

Use:

Wolfram Language
topologyRecordQ[record_, pair_Association] :=
  topologyRecordQ[record] &&
    SameQ[record["DiagramPair"], pair];
Delete topologyAmplitudeTag

Reuse selectedPairFromSetup.

Delete dimensionalShiftCutIndex

Use topologyPropagatorIndex directly, or stored "CutIndices" for complete records.

Merge ibpAssumptions with inferFractionAssumptions

There should be one momentum-fraction assumption constructor.

Remove duplicate mapping fields

In parseTopologyMapping, keep only one of:

Wolfram Language
"MappedProbeGLI"
"MappedProbe"

"SourceTopology" is also unnecessary after source-name validation.

Priority 3 — Normalize the process once in the private pre-IBP path

CollinearFactorizePreIBP currently validates amplitude setup in GenerateDiagram, then factorizePair calls normalizeProcess and validates it again.

Use:

Wolfram Language
process = normalizeProcess[config];
diagrams = generateDiagrams[process, config];
preparedProcess = prepareProcess[process, diagrams];
factorized = factorizePreparedProcess[preparedProcess];

Keep the current public functions as compatibility wrappers:

Wolfram Language
GenerateDiagram[config_] :=
  generateDiagrams[normalizeProcess[config], config];

CollinearFactorize[config_] := ...

Also remove the second full call to normalizeAmplitudeSelection inside GenerateDiagram. After generation, only the index-range condition needs to be checked.

Priority 4 — Canonicalize denominators before custom common-denominator extraction

At the beginning of splitAmplitude:

Wolfram Language
external = FeynCalc`FeynAmpDenominatorSplit[
  setDenominatorEta[
    expr,
    If[side === "conjugate", -1, 1]
  ],
  FeynCalc`FCI -> False,
  FeynCalc`FCE -> True
];

FeynAmpDenominatorSplit is explicitly designed to split compound denominator heads into products of single propagators. 
FeynCalc

This makes the custom multiset logic independent of whether FeynCalc emitted:

Wolfram Language
SFAD[a, b]

or:

Wolfram Language
SFAD[a] SFAD[b]

FeynCalc also exposes FCLoopGetFeynAmpDenominators for denominator extraction; it is worth testing as a replacement for the raw Cases block in propagatorFactors, while retaining the FACET descriptor and causal validation layer. 
FeynCalc

Priority 5 — Replace commonFactorMultiset with Counts and KeyIntersection

The current implementation manually computes minimum multiplicities.

A shorter exact replacement is:

Wolfram Language
commonFactorMultiset[lists : {__List}] := Module[
  {alignedCounts, commonCounts},

  alignedCounts = KeyIntersection[Counts /@ lists];
  commonCounts = Merge[alignedCounts, Min];

  Flatten @ KeyValueMap[
    ConstantArray[#1, #2] &,
    commonCounts
  ]
];

Counts returns exact element multiplicities, and KeyIntersection restricts associations to keys present in every input while aligning their key order. 
Wolfram Documentation
+1

Keep removeFactorOnce, since it avoids algebraic division through protected objects.

Priority 6 — Store the base GLI and compiled topology data

BuildTopologies already performs the conversion required to obtain the family GLI. Persist:

Wolfram Language
"BaseGLI"
"FamilyCoefficient"

Then build one runtime topology kernel:

Wolfram Language
<|
  "RulesToGLI" ->
    Flatten @ FeynCalc`FCLoopCreateRulesToGLI[topology],
  "CutIndices" -> record["CutIndices"],
  "BaseGLI" -> record["BaseGLI"],
  "ParameterPositions" -> ...,
  "RaiseCache" -> <||>
|>

This removes from the internal record path:

repeated FCLoopToGLI;

repeated FCLoopCreateRuleGLIToGLI;

cut-index rediscovery;

repeated numerator-to-GLI rule generation.

FCLoopCreateRuleGLIToGLI also supports list-based topology/subtopology mappings, so bulk preparation can be tested after the direct record path is stable. 
FeynCalc

Priority 7 — Simplify Kira process handling

Replace the global mutation:

Wolfram Language
SetEnvironment["FERMATPATH" -> fermat];

with:

Wolfram Language
process = RunProcess[
  {kira, "--parallel=" <> ToString[parallel], "jobs.yaml"},
  All,
  ProcessDirectory -> directory,
  ProcessEnvironment -> <|
    "FERMATPATH" -> fermat
  |>
];

RunProcess supports ProcessEnvironment directly, avoiding a persistent mutation of the Wolfram kernel’s environment. 
Wolfram Documentation

Replace:

Wolfram Language
ToExpression /@ StringCases[...]

with:

Wolfram Language
FromDigits /@ StringCases[
  log,
  RegularExpression[
    "unreduced integrals: ([0-9]+)"
  ] -> "$1"
]

Also hash the Fermat support file:

Wolfram Language
"SupportFileHash" -> FileHash[supportFile, "SHA256"]

because it participates in the runtime used for a resumable reduction.

Priority 8 — Store the internal cache manifest as WXF

Current cache loading uses:

Wolfram Language
Get[payloadPath]

which evaluates Wolfram Language source.

Use:

Wolfram Language
payloadPath =
  FileNameJoin[{project, "reduction_input.wxf"}];

storedPayload = If[
  FileExistsQ[payloadPath],
  Quiet @ Check[Import[payloadPath, "WXF"], $Failed],
  $Failed
];

Export[payloadPath, payload, "WXF"];

WXF is a versioned, platform-independent symbolic serialization format supported directly by Import and Export. 
Wolfram Documentation

This change applies only to the private Kira cache manifest. The public saved-result API can remain unchanged.

The separate .sha256 file is currently written but never consulted. Either:

verify it on load; or

retain it explicitly as a human-readable audit file and document that purpose.

Otherwise delete it.

Priority 9 — Make sparse ordering deterministic at every merge

linearIntegralSum sorts initial keys, but Merge can reintroduce order dependent on input traversal.

Use:

Wolfram Language
canonicalizeLinearTerms[terms_Association] :=
  KeySortBy[
    terms,
    ToString[InputForm[#]] &
  ];

Apply it in:

linearAdd;

linearMapIntegrals;

linearApplyReduction;

immediately before normalizeMasterCoefficients.

This makes the overall and per-master factor artifact deterministic under input permutation.

Priority 10 — Retain the scheduler, but extract two small helpers

The custom ParallelSubmit/WaitNext scheduler is justified by the observed ParallelMap deadlock and the requirement for visible progress.

Reduce nesting by extracting:

Wolfram Language
coefficientKernelLimit[count_Integer]
waitForCoefficientTasks[tasks_List, count_Integer]

Also validate the remainder normalization:

Wolfram Language
simplifiedRemainder =
  exactCoefficientNormalize[remainder];

If[simplifiedRemainder === $Failed,
  ibpFail[label, "remainder normalization failed"]
];

The current code catches $Failed returned by worker coefficients at the end, but not a $Failed returned by the serial remainder normalization.

Do not remove the Monitor/ProgressIndicator.

Priority 11 — Make BuildGlobalBasis transactional

Current order mutates scalar products before validation.

At minimum:

require four distinct symbols;

inspect any existing SP, SPD, and SPE values;

reject incompatible existing assignments;

install the new values;

assign globalBasis and internalSetEvanescentZero only after success.

Do not leave global basis state changed after a failed call.

Priority 12 — Replace generated-symbol ToExpression

Use:

Wolfram Language
topologyID = Symbol[
  "Global`TopologyF" <> forwardTag <>
    "C" <> conjugateTag <>
    "N" <> ToString[index]
];

rather than ToExpression.

For generated ffsp symbols, use deterministic collision-resistant alphanumeric names based on the source/context fingerprint, clear them explicitly, and verify that they have no values before use.

3. Suggested replacement Wolfram Language

The following replacements are safe and useful:

Current custom operation	Replacement
Compound denominator splitting	FeynAmpDenominatorSplit
Candidate denominator extraction	Test FCLoopGetFeynAmpDenominators; retain FACET validation
Multiset common factors	Counts + KeyIntersection + Merge
Global subprocess environment mutation	ProcessEnvironment option to RunProcess
Executable-log integer parsing	FromDigits
Evaluated cache manifest	Export/Import with "WXF"
Repeated key sorting	KeySortBy
ToExpression solely to construct a symbol	Symbol
Repeated topology/subtopology GLI rules	Batch-capable FCLoopCreateRuleGLIToGLI where applicable

I would not replace:

the physical topology-equivalence certificate;

oriented-cut restoration;

the Gram/Wishart recurrence;

stepwise cut projection;

sparse reduction composition;

the dynamic coefficient task scheduler;

the two-level overall/per-master factor extraction.

Those contain project-specific physical invariants that the built-ins do not encode.

4. Regression tests for each nontrivial change
Change	Required regression
Fail-closed causal status	Remove/alter certification field; record must fail
BMHV enforcement	BMHV passes; NDR/Larin/unknown fails
Context consistency	Top-level/topology context mismatch fails
Base-GLI provenance coverage	Active unmatched slot fails; auxiliary completion passes
Exact cut-core matching	q
2
 cut is not confused with q
2
−m
2

One-argument SPE	SPE[k] equals SPE[k,k] after shift
Loop-free coefficients	Inject f[k] GLI[...]; shift fails
Kira import validation	$Failed, malformed list, wrong arity all fail
Cut audit	Pinched cut in any imported RHS fails
Kinematic completion split	Stored physical records remain valid after Kira preparation
Mass dimensions	dimension-two and dimension-zero variables emitted correctly
Exact-number enforcement	rational passes; machine/precision real fails
Empty reduction	LO IBP completes with zero masters
Denominator canonicalization	SFAD[a,b] and SFAD[a] SFAD[b] yield identical split
Counts-based common factors	Property test against old implementation on random exact factor lists
WXF cache	Exact SameQ round trip; altered payload invalidates resume
ProcessEnvironment	Parent FERMATPATH is unchanged after Kira run
Deterministic sparse ordering	Randomized pair/file ordering gives SameQ master artifacts
Transactional basis	Conflicting or duplicate basis fails without changing prior state
Module dependency cleanup	Every private file loads in declared order without forward private-symbol dependencies
Public API preservation	Same public names, options, syntax information, and accepted argument patterns

Retain all current physics regressions in addition to these.

5. Module ownership and dependency assessment

The modular split is now clearly worthwhile. The files correspond to meaningful scientific and operational boundaries, rather than arbitrary line ranges.

Ownership is not yet fully clean, because of the three reverse dependencies:

Topologies -> Reduction
    through reductionFingerprint

Topologies -> DimensionalShift
    through dimensionalShiftParameterPosition

DimensionalShift -> Reduction
    through LinearIntegralSum functions

After moving the generic exact predicates, fingerprinting, and sparse linear algebra to Core.wl, and moving the propagator-slot lookup to Topologies.wl, the ownership becomes clean:

Core
  ├─ Process
  ├─ Topologies
  │    └─ DimensionalShift
  └─ Process + Topologies + DimensionalShift
         └─ Collinear
              └─ Reduction

analyticContext would fit better in Process.wl or Core.wl than in Collinear.wl, because it describes the normalized calculation context and is consumed by topology and reduction artifacts.

With those moves, the modular structure is justified and should be retained. The remaining source reduction should come from eliminating reverse dependencies, duplicate validation wrappers, repeated topology conversion, and manual standard-library operations—not by recombining the files.
