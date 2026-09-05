# Latest

## Question

_The question was not preserved in the local bridge record._

## Pro response

Diagnosis

The regression is most likely two separate effects:

The 5× pair-payload growth is a serialization/data-layout issue, probably dominated by repeated pair-global objects inside every topology record and possibly by saving DiagramsBySide inside "Setup".

The >17-minute pre-pool stall is an algebraic scheduling regression in the sparse layer, not a Kira-target-count problem. The current code performs expensive exact rational normalization repeatedly and serially before reaching normalizeMasterCoefficients.

The second diagnosis is high confidence from the source path alone.

1. Most plausible causes
1.1 Pre-pool slowdown: linearDropZeros is performing hidden serial simplification

In Private/Core.wl, the current sparse operations call:

Wolfram Language
linearDropZeros

which tests every coefficient using:

Wolfram Language
exactZeroQ[expr_] :=
  TrueQ[
    Quiet[
      Cancel[Together[Expand[expr]]]
    ] === 0
  ];

This occurs through both:

Wolfram Language
linearAdd
linearMapIntegrals

and therefore repeatedly during the 25-source Fold.

For approximately 77 target keys, the current sequence can perform on the order of

25×77

increasingly expensive Expand–Together–Cancel operations before Kira-rule application is even complete. After reduction, linearApplyReduction invokes another merge and exact-zero pass on the six large master coefficients.

That directly contradicts the intended design:

Do no coefficient simplification until all pairs have been aggregated and reduced to the final masters.

The sparse implementation has inadvertently reintroduced general coefficient normalization under the name “drop zeros.”

First patch

Do not perform algebraic zero detection in linearAdd or linearMapIntegrals.

Wolfram Language
linearCanonicalize[data_?linearIntegralSumQ] := <|
  "Terms" -> canonicalizeLinearTerms[data["Terms"]],
  "Remainder" -> data["Remainder"]
|>;

linearAdd[parts_List] := Module[{result},
  If[! AllTrue[parts, linearIntegralSumQ],
    Return[Failure["InvalidLinearIntegralSum", <||>]]
  ];

  result = <|
    "Terms" -> If[
      parts === {},
      <||>,
      Merge[Lookup[parts, "Terms"], Total]
    ],
    "Remainder" -> Total[Lookup[parts, "Remainder", 0]]
  |>;

  linearCanonicalize[result]
];

linearMapIntegrals[
    data_?linearIntegralSumQ,
    rules_
  ] := Module[{terms},

  terms = KeyValueMap[
    Replace[#1, rules, {0}] -> #2 &,
    data["Terms"]
  ];

  If[
    ! AllTrue[First /@ terms, MatchQ[#, _FeynCalc`GLI] &],
    Return[Failure["InvalidIntegralMap", <||>]]
  ];

  linearCanonicalize @ <|
    "Terms" -> If[terms === {}, <||>, Merge[terms, Total]],
    "Remainder" -> data["Remainder"]
  |>
];

Retain algebraically zero keys until normalizeMasterCoefficients, where only the six final coefficients enter the dynamic pool and exactCoefficientNormalize already detects exact zeros.

This patch alone is likely to remove a large fraction of the 17-minute stall.

1.2 PreFactor Integrand is formed too early

Current code:

Wolfram Language
sourceParts = linearIntegralSum[
  result["PreFactor"] result["Integrand"]
];

This asks linearIntegralSum to extract GLI coefficients from a product whose left factor can contain:

external propagators;

distributions;

endpoint powers;

dimension-dependent normalization;

branch-sensitive exact objects.

linearIntegralSum then calls Coefficient once for each GLI and performs a full reconstruction check involving:

Wolfram Language
Expand[expression - reconstructed]

The common prefactor should not be expanded into the GLI sum merely to extract coefficients.

Replacement

Add an exact structural scaling operation:

Wolfram Language
linearScale[
    data_?linearIntegralSumQ,
    factor_
  ] := linearCanonicalize @ <|
  "Terms" -> Map[factor # &, data["Terms"]],
  "Remainder" -> factor data["Remainder"]
|>;

Then change addSource to:

Wolfram Language
sourceParts = linearIntegralSum[result["Integrand"]];

If[FailureQ[sourceParts],
  ibpFail[
    "target coefficient collection",
    "a pre-IBP integrand is not linear in explicit GLI objects"
  ]
];

sourceParts = linearMapIntegrals[
  sourceParts,
  equivalence["GLIRules"]
];

If[FailureQ[sourceParts], ...];

sourceParts = linearScale[
  sourceParts,
  result["PreFactor"]
];

The topology rule should be applied before scaling because it changes keys only. This preserves PreFactor as an unexpanded exact multiplicative object.

1.3 linearApplyReduction reconstructs and reparses 77 large expressions

Current implementation:

Wolfram Language
linearIntegralSum[
  coefficient *
    ((target /. rules) /. reverseRules)
]

for every target.

If 77 targets each reduce to up to six masters, this repeatedly:

multiplies a large source coefficient into a master sum;

scans the result for GLIs;

calls Coefficient for each master;

reconstructs and expands the expression to prove linearity.

The reduction rules are already closed. They should be parsed into a sparse map once, and sparse maps should then be composed directly.

Compile the closed reduction once

Prefer the already physicalized:

Wolfram Language
kira["ReductionRules"]

because it has had the auxiliary kinematic symbols and dimension convention restored.

Wolfram Language
compileSparseReduction[
    targets_List,
    physicalRules_List
  ] := Module[
  {dispatch, images},

  dispatch = Dispatch[physicalRules];

  images = AssociationMap[
    Function[target,
      linearIntegralSum[
        Replace[target, dispatch, {0}]
      ]
    ],
    targets
  ];

  If[
    AnyTrue[Values[images], FailureQ],
    Failure["InvalidSparseReduction", <||>],
    images
  ]
];

A master target absent from the rule left-hand sides remains itself and therefore compiles to the identity map.

Compose without constructing intermediate expressions
Wolfram Language
linearComposeReduction[
    data_?linearIntegralSumQ,
    reduction_Association
  ] := Module[
  {termPieces, remainderPieces, terms, remainder, image},

  termPieces = KeyValueMap[
    Function[{target, coefficient},
      image = Lookup[
        reduction,
        target,
        Missing["UnknownTarget"]
      ];

      If[MissingQ[image],
        Return[
          Failure[
            "MissingReductionTarget",
            <|"Target" -> target|>
          ]
        ]
      ];

      Map[coefficient # &, image["Terms"]]
    ],
    data["Terms"]
  ];

  If[AnyTrue[termPieces, FailureQ],
    Return[FirstCase[termPieces, _Failure]]
  ];

  remainderPieces = KeyValueMap[
    Function[{target, coefficient},
      coefficient reduction[target]["Remainder"]
    ],
    data["Terms"]
  ];

  terms = If[
    termPieces === {},
    <||>,
    Merge[termPieces, Total]
  ];

  remainder =
    data["Remainder"] +
      Total[remainderPieces];

  linearCanonicalize @ <|
    "Terms" -> terms,
    "Remainder" -> remainder
  |>
];

Then the coefficient path becomes:

Wolfram Language
sparseReduction = compileSparseReduction[
  kira["Targets"],
  kira["ReductionRules"]
];

physicalParts = linearComposeReduction[
  targetParts,
  sparseReduction
];

No product is recollected, and no coefficient is simplified before the final six-master pool.

2. Recommended exact operation order

The production order should be:

For each pair:
    parse Integrand alone as a sparse GLI sum
    map topology-equivalent GLI keys
    multiply sparse coefficients by the pair PreFactor structurally
    merge into the global target map without simplification

Once:
    compile each closed Kira target rule into a sparse master map
    compose target map with reduction map by association multiplication
    apply D -> 4 - 2 Epsilon coefficient-wise
    validate master keys and cuts
    normalize only the final master coefficients in the worker pool

Equivalently:

Wolfram Language
sourceParts =
  linearIntegralSum[result["Integrand"]];

sourceParts =
  linearMapIntegrals[
    sourceParts,
    equivalence["GLIRules"]
  ];

sourceParts =
  linearScale[
    sourceParts,
    result["PreFactor"]
  ];

targetParts =
  linearAdd[{targetParts, sourceParts}];

...

physicalParts =
  linearComposeReduction[
    targetParts,
    sparseReduction
  ];

physicalParts =
  linearMapCoefficients[
    physicalParts,
    ReplaceAll[$dimensionRule]
  ];

Applying the dimension rule before sparse composition is also algebraically valid. I would first retain the current placement to minimize the patch and benchmark it separately.

3. Likely sources of the 5× payload growth

The payload increase and algebraic slowdown should not be assumed to have the same cause.

3.1 First inspect "Setup" -> setup

GenerateCollinearFactorizePreIBPResult stores the supplied setup verbatim.

If the supplied association contains:

Wolfram Language
"DiagramsBySide"

then every saved pair may contain complete FeynArts topology lists.

Strip derived execution objects before persistence:

Wolfram Language
storedSetup = KeyDrop[
  setup,
  {
    "DiagramsBySide"
  }
];

and store:

Wolfram Language
"Setup" -> storedSetup

The selected indices, loop orders, loop momenta, model, and source fingerprint are sufficient to regenerate the diagrams.

This is the cheapest field to inspect first.

3.2 Pair-global data is duplicated in every topology record

In the modular source previously reviewed, every topology record carried identical copies of:

Wolfram Language
"AnalyticContext"
"ExternalPropagatorData"

while the pre-IBP artifact also carried the analytic context at top level.

That duplication grows linearly with the number of fractions/topologies and fits the observation that a hard pair such as F9_C10 is disproportionately large.

These fields should be pair-global:

Wolfram Language
preIBPResult["AnalyticContext"]
preIBPResult["ExternalPropagatorData"]

Each topology record needs only:

Wolfram Language
"AnalyticContextFingerprint"
"ExternalPropagatorDataFingerprint"

or can be validated against the enclosing artifact directly.

A minimal durable representation is:

Wolfram Language
compactTopology = KeyDrop[
  fullTopology,
  {
    "AnalyticContext",
    "ExternalPropagatorData"
  }
];

compactTopology = Join[
  compactTopology,
  <|
    "AnalyticContextFingerprint" ->
      context["Fingerprint"],
    "ExternalPropagatorDataFingerprint" ->
      reductionFingerprint[externalPropagatorData]
  |>
];

The public in-memory CollinearFactorizePreIBP output can remain unchanged. Only GenerateCollinearFactorizePreIBPResult needs to compact records for persistence, and ibpInputSummary can validate compact records using the enclosing fields.

This requires an artifact-version bump but no physics change.

3.3 Inspect PropagatorData descriptors

Each algebraic descriptor may contain a complete:

Wolfram Language
"UnitCore"

that can be recomputed from:

Wolfram Language
record["Topology"]

If field counts show these dominate, retain only the physical source coverage and a descriptor fingerprint in durable files. Recompute exact algebraic descriptors during validation.

Do not remove the source-side powers, cut IDs, or source IDs.

3.4 CommonFactorSafe may now leave common external analytic factors in Integrand

The newer branch-safe implementation protects every non-rational analytic object and then refuses to move any protected atom into PreFactor.

That is stronger than required. A branch-sensitive or distributional object may be extracted as a common factor without being algebraically rewritten.

This is a conditional patch: apply it only if field-level counts show that "Integrand" rather than topology metadata is responsible for most of the growth.

For the pre-IBP call with explicit loop momenta, distinguish:

protected objects depending on loop momenta: must remain in the integrand;

protected objects independent of loop momenta: may be moved to the prefactor if Factor found them structurally common.

Wolfram Language
immovableAtoms = If[
  loopMomenta === {},
  atoms,
  Pick[
    atoms,
    ! FreeQ[
      #,
      Alternatives @@ loopMomenta
    ] & /@ protected
  ]
];

prefactor = Times @@ Select[
  factors,
  FreeQ[
    #,
    Alternatives @@ immovableAtoms
  ] &
];

Because the analytic objects were first replaced by inert atoms, this does not alter their branches or distributional meaning.

Keep the current behavior for CommonFactorSafe[coefficient] with no loop-momentum argument, so the requested local per-master factor format does not change unexpectedly.

4. Functions to patch first
Immediate, low-risk performance patches
Private/Core.wl

linearDropZeros

stop calling exactZeroQ during sparse accumulation;

either delete it from the hot path or make it structural-only.

linearAdd

merge associations and canonicalize keys only.

linearMapIntegrals

map and merge keys without exact coefficient normalization.

Add linearScale.

Replace or supplement linearApplyReduction with sparse-map composition.

Private/Reduction.wl

Nested addSource in coefficientSimplificationCore

change from:

Wolfram Language
linearIntegralSum[PreFactor Integrand]

to:

Wolfram Language
linearScale[
  linearMapIntegrals[
    linearIntegralSum[Integrand],
    topologyRules
  ],
  PreFactor
]

Before applying reductions:

compile kira["ReductionRules"] once into sparse maps.

Replace:

Wolfram Language
linearApplyReduction[
  targetParts,
  Dispatch[kira["KiraRules"]],
  kira["ReverseRules"]
]

with direct sparse composition.

Payload patches
Private/Collinear.wl

GenerateCollinearFactorizePreIBPResult

strip "DiagramsBySide" from persisted setup;

hoist pair-global context/external data from topology records.

completeTopologyRecord

retain full records in memory;

add a separate compact serialization projection rather than weakening the in-memory validator.

Private/Core.wl

CommonFactorSafe

only if the "Integrand" field is shown to dominate size;

allow structurally common loop-independent analytic atoms into PreFactor.

5. Minimal benchmark matrix

Use the same 25 new pair files and the same new Kira artifact for every algebra benchmark.

5.1 Field-level payload accounting
Wolfram Language
topLevelByteCounts[result_Association] :=
  Association @ KeyValueMap[
    #1 -> ByteCount[#2] &,
    result
  ];

topologyFieldByteCounts[result_Association] := Module[
  {records},

  records = result["Topologies"];

  If[records === {}, Return[<||>]];

  Merge[
    (Association @ KeyValueMap[
      #1 -> ByteCount[#2] &,
      #
    ]) & /@ records,
    Total
  ]
];

For F9_C10, record:

Total
Setup
Setup/DiagramsBySide
PreFactor
Integrand
Topologies
Topologies/Topology
Topologies/Propagators
Topologies/PropagatorData
Topologies/AnalyticContext
Topologies/ExternalPropagatorData
Topologies/BaseGLI
Topologies/FamilyCoefficient

Interpretation:

large Setup/DiagramsBySide: strip generated diagrams;

large repeated context/external data: hoist pair-global fields;

large Integrand: benchmark CommonFactorSafe;

large PropagatorData: compact recomputable descriptors.

5.2 Source-extraction microbenchmark

For old and new F9_C10:

Variant	Operation
Current	linearIntegralSum[PreFactor Integrand]
Patch A	linearScale[linearIntegralSum[Integrand], PreFactor]
Patch B	Patch A with no exact-zero pruning
Optional	Persisted sparse integrand loaded directly

Measure:

wall time
peak memory
ByteCount[Terms]
number of target keys
5.3 Pair aggregation

Run the 25-pair fold with:

Variant	linearAdd behavior
Current	exactZeroQ after every merge
Patched	no algebraic zero tests
Diagnostic	exact-zero test only once after all 25 pairs

The patched result should have the same target keys as Kira. Zero-valued targets may remain until final normalization.

5.4 Reduction composition
Variant	Method
Current	linearIntegralSum[coefficient reductionImage] per target
Patched	precompiled sparse reduction map
Patched + early D rule	substitute before composition

Measure separately:

rule compilation
target-to-master composition
D substitution
final six-coefficient normalization
5.5 Exact equivalence gates

Do not compare giant reconstructed expressions first. Compare sparse maps coefficient by coefficient:

Wolfram Language
sparseDifference =
  linearAdd[{
    oldParts,
    linearScale[newParts, -1]
  }];

normalizedDifferences =
  exactCoefficientNormalize /@
    Values[sparseDifference["Terms"]];

And[
  AllTrue[normalizedDifferences, SameQ[#, 0] &],
  SameQ[
    exactCoefficientNormalize[
      sparseDifference["Remainder"]
    ],
    0
  ]
]

Then retain the existing final artifact reconstruction check.

The benchmark must also verify:

identical topology-equivalence representative mapping;

identical Kira target set;

identical six master keys;

identical cut indices and physical metadata;

no independent D;

exact final coefficient equality;

same overall and per-master factor reconstruction.

Recommended patch sequence

Remove exactZeroQ from linearAdd and linearMapIntegrals.

Extract GLI coefficients from Integrand before applying PreFactor.

Compile Kira rules into sparse master maps and compose associations directly.

Re-run the 25-pair coefficient stage before changing any artifact schema.

Strip DiagramsBySide from persisted setup.

Hoist repeated AnalyticContext and ExternalPropagatorData.

Only if "Integrand" remains the dominant field, loosen CommonFactorSafe to extract common loop-independent protected factors.

The first three changes should restore—and likely substantially improve upon—the old NLO post-Kira performance without removing any exactness, cut, BMHV, topology, or reconstruction check.
