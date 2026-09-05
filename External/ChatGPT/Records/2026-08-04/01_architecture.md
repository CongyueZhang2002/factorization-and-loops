# Architecture

## Question

_The question was not preserved in the local bridge record._

## Pro response

Overall assessment

The package should be simplified around four internal objects:

ProcessSpec⟶FactorizedPair⟶TopologyRecord⟶LinearIntegralSum
	​


Everything after that should operate on versioned artifacts constructed from those objects.

The current source has strong fail-closed checks in the difficult places—especially topology equivalence and Kira rule closure—but it repeatedly reconstructs and revalidates the same information. The largest reductions will come from eliminating intermediate positional lists, partial topology records, repeated GLI conversion, repeated process normalization, whole-expression coefficient collection, and duplicated result/input assembly.

I would preserve every public symbol during the first rewrite. SimplifyAssum, FullSimplifyAssum, and GenerateCollinearFactorizePreIBPResult are internally redundant, but they should initially become compatibility wrappers rather than being deleted.

Correctness issues to patch before structural refactoring

These are not merely code-quality concerns.

1. The conjugate propagator prescriptions are not currently explicit

The code conjugates only the numerator:

Wolfram Language
completePair = <|
  "Amplitude" -> First[splitPair["Amplitude"]],
  "Conjugate" -> FeynCalc`ComplexConjugate[
    First[splitPair["Conjugate"]]
  ]
|>;

but constructs the denominator product from the original unconjugated factors:

Wolfram Language
Times @@ (Last /@ Values[splitPair])

Thus the conjugate-side denominators still carry the original FeynCalc prescription representation. The later AMFlow labels do not repair the physical propagator metadata.

This must be corrected before building topology records. Use a dedicated physical-prescription operation that changes the stored eta sign at fixed denominator polynomial. Do not use FCLoopSwitchEtaSign as physical conjugation: that function changes the eta convention while pulling out an overall minus from the propagator, so it preserves the represented denominator rather than taking its complex conjugate. 
FeynCalc

The required regression for every conjugate propagator is:

D
core
after
	​

=D
core
before
	​

,η
after
	​

=−η
before
	​

.

Apply the conjugation before splitAmplitude, or transform both returned pieces and verify that the complete product equals the conjugated amplitude.

2. Incomplete propagator metadata is still used to merge families

TopologyEquivalence correctly reports:

Wolfram Language
"PhysicalCausalStatus" -> "IncompletePropagatorMetadata"

but ibpKiraReductionCore applies the returned GLIRules without requiring "Verified" status.

That was acceptable under the earlier explicitly limited “cut-aware IBP” scope. It does not satisfy the current stated contract that mappings preserve causal side.

For production, either:

Wolfram Language
equivalence["PhysicalCausalStatus"] === "Verified"

must be mandatory before applying a GLI mapping, or every topology must remain separate. There should be no default option that accepts incomplete metadata.

The real fix is to make PropagatorData mandatory and construct it in the collinear-factorization stage rather than trying to infer it in TopologyEquivalence.

3. restoreCutTerm can restore the wrong power of a cut

The current cut power is:

Wolfram Language
power = Count[indices, First[position]]

This counts denominator objects, not their powers. A squared denominator represented as one StandardPropagatorDenominator[..., {2, eta}] is restored as Cut[...]^1.

Use the actual propagator power:

Wolfram Language
propagatorPowers = topologyPropagatorPower /@ propagators;

power = Total @ Pick[
  propagatorPowers,
  Thread[indices === First[position]]
];

and require power to be a positive integer.

This is important for dotted cuts produced by dimensional shifts and later NNLO use.

4. Cut projection must be applied after every one-step Tarasov recurrence

Currently:

Wolfram Language
dimensionalShiftRaiseToD[...]
...
dimensionalShiftPreserveCuts[result, cutIndices]

projects only after all dimension-lowering steps.

If an intermediate recurrence produces an integral with a nonpositive cut index, that integral is already zero in the cut quotient. Continuing to apply ordinary dimensional recurrences to it can generate apparently surviving terms. The cut projector must be applied after every call to dimensionalShiftRaiseOnce:

Wolfram Language
Fold[
  Function[{current, offset},
    Module[{raised},
      raised = dimensionalShiftRaiseOnce[
        current, topology, offset, dimension
      ];
      If[raised === $Failed, Return[$Failed]];
      dimensionalShiftPreserveCutsStrict[raised, cutIndices]
    ]
  ],
  expression,
  offsets
]

The strict projector should fail if a GLI index is not an explicit integer; it should not silently drop an unsupported term.

5. Generic Simplify is too broad for final physical coefficients

dynamicSimplifyExpressions calls:

Wolfram Language
Simplify[coefficient, Assumptions -> assumptions]

on complete coefficients. That can act inside endpoint powers, branch-sensitive functions, or custom distribution objects.

Replace it with a two-level policy:

A default exact rational normalizer that inertizes distributions, cuts, endpoint factors and branch objects, then applies only Together, Cancel and optionally Factor in the declared rational variables.

An explicitly requested branch-aware Simplify pass whose analytic context is part of the artifact metadata.

FullSimplify should not appear in the production pipeline outside basis validation.

Highest-value deletions and merges
Priority	Current functions	Replacement
P0	validAmplitudeSetupQ, resolveAmplitudeSelection, normalizePerturbativeSides, normalizeSides, selectedPairFromSetup, ibpBaseSetup	One normalizeProcess constructor and small accessors
P0	topologyRecordQ, safeTopologyRecordQ, validStoredTopologyQ, topologyRecordPhysicalDataCompleteQ, validation inside attachAMFlowInfo	One makeTopologyRecord and one validateTopologyRecord
P0	Partial topology output from BuildTopologies followed by attachAMFlowInfo	BuildTopologies constructs complete production-ready records immediately
P0	Repeated FCLoopToGLI, dimensionalShiftParameterPosition, FCLoopCreateRulesToGLI inside DimensionalShift	Store BaseGLI, family coefficient and cut-slot map in the topology record; compile one runtime kernel per topology/active sector
P0	Whole-expression Collect2/Coefficient passes in DimensionalShift, ibpLinearParts, target extraction and master collection	One sparse LinearIntegralSum representation
P1	ibpInputData, ibpInputFilesData, ibpFileSummary, ibpParallelFileSummaries	One item summarizer and one summary aggregator
P1	Empty and nonempty result assembly in ibpKiraReductionCore, plus separate final IBP assembly	One versioned reduction-artifact constructor
P1	dynamicSimplifyExpressions manual ParallelSubmit/WaitNext queue and the separate file-scan parallel path	One parallelMapHeavy abstraction; use it only for genuinely expensive tasks
P1	ibpStructuralCommonFactor plus global factor extraction plus per-master CommonFactorSafe	Store direct master coefficients; factoring becomes an optional presentation operation
P1	$FACETKiraExecutable, $FACETFermatExecutable, $FACETKernelLimit, $FACETResumeKira	Options or one explicit backend configuration association
P1	fail, preIBPFail, ibpFail, multiple tagged Catch blocks, safeTopologyRecordQ	Failure objects with Enclose/ConfirmBy/ConfirmMatch
P2	Print, Grid, Monitor, diagram painting inside mathematical routines	One reporter at public orchestration boundaries
P2	ToExpression["GlobalTopology..."], ToExpression["Globalffsp..."]	Deterministic symbols in a private package context, generated by one naming function
P2	Repeated Cases for propagator extraction	Shared propagator parser, using FeynCalc extraction functions where supported
Compatibility only	SimplifyAssum, FullSimplifyAssum	One-line wrappers around the new analytic-context functions; no internal use
Compatibility only	GenerateCollinearFactorizePreIBPResult	One-line wrapper around makePreIBPArtifact

The largest conceptual deletion is replacing expression-shaped intermediate data with LinearIntegralSum. That removes several hundred lines of repeated collection, target extraction, rule application and reconstruction logic.

Proposed internal data model
1. Normalized process schema

Raw notebook configuration should be accepted only at public boundaries. Every internal function should receive one normalized process object.

Wolfram Language
<|
  "Type" -> "FeynFacetProcess",
  "Version" -> 2,

  "Identity" -> <|
    "CardName" -> ...,
    "ProcessID" -> ...,
    "PhysicsContextID" -> ...
  |>,

  "Legs" -> <|
    "Incoming" -> {leg1, leg2, ...},
    "Outgoing" -> {leg1, leg2, ...}
  |>,

  "Sides" -> <|
    "Amplitude" -> <|
      "Role" -> 1,
      "LoopOrder" -> ...,
      "LoopMomenta" -> {...},
      "DiagramIndices" -> {...},
      "SelectedIndex" -> ...
    |>,
    "Conjugate" -> <|
      "Role" -> -1,
      "LoopOrder" -> ...,
      "LoopMomenta" -> {...},
      "DiagramIndices" -> {...},
      "SelectedIndex" -> ...
    |>
  |>,

  "PhaseSpace" -> <|
    "Momenta" -> {...},
    "IntegratedMomentum" -> ...,
    "RemainingMomenta" -> {...}
  |>,

  "LoopRouting" -> <|
    "Momenta" -> {phaseLoops..., amplitudeLoops..., conjugateLoops...},
    "AMFlowLabels" -> {0..., 1..., -1...}
  |>,

  "Kinematics" -> <|
    "MomentumEliminationRule" -> ...,
    "MasslessMomenta" -> {...},
    "FourDimensionalMomenta" -> {...},
    "Assumptions" -> ...
  |>,

  "AnalyticContext" -> <|
    "LoopDimension" -> D,
    "EpsilonConvention" -> HoldForm[D == 4 - 2 Epsilon],
    "Gamma5Scheme" -> "BMHV",
    "CutConvention" -> "OrientedDelta",
    "BranchConvention" -> ...,
    "DistributionConvention" -> ...,
    "DistributionZeros" -> {...}
  |>,

  "FeynArts" -> <|
    "Partons" -> ...,
    "Model" -> ...,
    "InsertionLevel" -> ...,
    "ExcludeTopologies" -> ...,
    "ExcludeParticles" -> ...
  |>,

  "Execution" -> <|
    "ResultDirectory" -> ...,
    "SourceNotebook" -> ...
  |>
|>

A leg should always use the same fields:

Wolfram Language
<|
  "Parton" -> ...,
  "Momentum" -> ...,
  "Fraction" -> ...,
  "HadronMomentum" -> ...,
  "LongDirection" -> ...,
  "DualDirection" -> ...,
  "LongSpin" -> ...,
  "TransSpin" -> ...
|>

normalizeProcess should be the only function that knows about the original incoming-to-outgoing Rule representation.

DiagramsBySide is derived execution data and should not be a required raw-physics key. Store it in a separate prepared-process object:

Wolfram Language
<|
  "Process" -> processSpec,
  "Diagrams" -> <|"Amplitude" -> ..., "Conjugate" -> ...|>
|>

This removes the current circularity where GenerateDiagram runs before normalizeProcess, but normalizeProcess requires "DiagramsBySide".

2. Factorized-pair schema

CollinearFactorize should internally return an association, not a six-element positional list:

Wolfram Language
<|
  "FractionMeasure" -> ...,
  "PreFactor" -> ...,
  "PhaseSpace" -> ...,
  "Numerator" -> ...,
  "Denominators" -> {
    propagatorDescriptor1,
    propagatorDescriptor2,
    ...
  },
  "LoopMomenta" -> {...}
|>

Each denominator descriptor should preserve provenance before any products are formed:

Wolfram Language
<|
  "Expression" -> ...,
  "Role" -> "Amplitude" | "Conjugate" | "Cut",
  "CausalSide" -> 1 | -1 | 0,
  "PhysicalEtaSign" -> 1 | -1 | Missing["NotApplicable"],
  "LineMomentum" -> ...,
  "CutID" -> ...,
  "EnergyDirection" -> ...,
  "MeasurementRole" -> ...
|>

The public CollinearFactorize wrapper can still convert this to the documented six-element list.

This is the correct point to preserve amplitude/conjugate provenance. Once the denominator products are multiplied together, reconstructing side information is unnecessarily difficult.

3. Topology record schema

A production topology record should be complete from its construction. PropagatorData should not be optional.

Wolfram Language
<|
  "Type" -> "FeynFacetTopologyRecord",
  "Version" -> 2,

  "Topology" -> ibpTopology,
  "BaseGLI" -> FeynCalc`GLI[...],
  "FamilyCoefficient" -> ...,

  (* Compatibility field *)
  "Propagators" -> sourcePartialFractionTerm,

  "CutMomenta" -> {...},
  "CutIndices" -> {...},
  "CutDirections" -> {...},

  "PropagatorData" -> {
    propagatorData1,
    propagatorData2,
    ...
  },

  "DiagramPair" -> <|
    "Forward" -> ...,
    "Conjugate" -> ...
  |>,

  "AMFlowInfo" -> <|
    "Family" -> ...,
    "Loop" -> {...},
    "Prescription" -> {...},
    "Cut" -> {...}
  |>,

  "AnalyticContextID" -> ...,
  "PhysicsContextID" -> ...
|>

Separate algebraic topology data from physical data:

Wolfram Language
<|
  "Algebraic" -> <|
    "Type" -> "QuadraticLorentzian",
    "Power" -> 1,
    "TopologyEtaSign" -> 1,
    "Core" -> ...
  |>,

  "Physical" -> <|
    "Role" -> "Cut" | "Amplitude" | "Conjugate" | "Auxiliary",
    "CausalSide" -> 0 | 1 | -1,
    "PhysicalEtaSign" -> Missing["NotApplicable"] | 1 | -1,
    "CutID" -> ...,
    "EnergyDirection" -> ...,
    "EnergyReference" -> ...,
    "CutConvention" -> ...,
    "MeasurementRole" -> ...
  |>
|>

This avoids conflating the formal eta sign used to present a cut denominator to FeynCalc with the physical fact that a delta cut has no ordinary +i0 or −i0 prescription.

For FeynCalc/Kira work, it is reasonable to use an eta-normalized FCTopology and retain the physical eta data in PropagatorData. The topology-equivalence certificate must compare the physical descriptors, not merely the normalized topology.

4. Sparse integral representation

Introduce one internal representation immediately after dimensional shifting:

Wolfram Language
<|
  "Terms" -> <|
    GLI[topo1, {...}] -> coefficient1,
    GLI[topo2, {...}] -> coefficient2,
    ...
  |>,
  "Remainder" -> remainder
|>

Call it internally LinearIntegralSum.

Required operations are small:

Wolfram Language
linearIntegralSum[expr_]
linearIntegralSumQ[data_]
linearAdd[list_]
linearMapIntegrals[data_, function_]
linearApplyReduction[data_, reductionTable_]
linearToExpression[data_]

The invariants are:

every key is one GLI;

no coefficient contains a GLI;

coefficients are loop-momentum free at the post-shift stage;

duplicate GLIs are merged exactly by Total;

the remainder contains no GLI.

This representation should replace:

ibpLinearParts;

ibpMergeLinearParts;

repeated Collect2;

target extraction with Cases;

whole-expression topology mapping;

whole-expression IBP substitution;

repeated master collection.

Topology equivalence then maps integral keys only:

Wolfram Language
linearMapIntegrals[data, ReplaceAll[verifiedGLIRules]]

IBP reduction becomes sparse composition:

c
i
	​

I
i
	​

↦
A
∑
	​

c
i
	​

R
iA
	​

M
A
	​

,

without constructing a large intermediate expression.

5. Runtime topology kernel

Do not serialize this object. Build it once per topology and active positive-index sector during a pipeline run:

Wolfram Language
<|
  "Topology" -> ...,
  "Dimension" -> ...,
  "RulesToGLI" -> ...,
  "FeynmanPreparation" -> ...,
  "ParameterSlotMap" -> ...,
  "GramMomentFunction" -> ...,
  "RaiseDimensionCache" -> <||>
|>

A suitable key is:

Wolfram Language
{
  topologyFingerprint,
  Unitize[Boole[baseGLI[[2]] > 0]]
}

or the equivalent exact positive-index mask.

This eliminates repeated calls to:

FCLoopCreateRulesToGLI;

FCFeynmanPrepare;

dimensionalShiftParameterPosition;

one-step dimension shifts for identical GLIs.

FCLoopCreateRulesToGLI accepts a topology list, so these rules can be prepared in one pass for all relevant topologies. 
FeynCalc

Proposed source organization

A small seven-file layout is sufficient, including the public façade.

FeynFacet.wl
Private/
  Core.wl
  Process.wl
  Collinear.wl
  Topologies.wl
  DimensionalShift.wl
  Reduction.wl
Distributions.wl
FeynFacet.wl

Only:

public usage messages;

options;

formatting definitions;

public wrappers;

package/runtime capability checks;

loading private files.

No scientific kernel should be implemented here.

Core.wl

Failure construction and public message translation;

exact-zero and exact-rational predicates;

canonical rule ordering;

LinearIntegralSum;

artifact header/constructor;

one reporter abstraction;

one worker-pool abstraction;

exact coefficient normalization.

Process.wl

global basis installation and validation;

scalar declarations;

process schema;

normalizeProcess;

amplitude-side normalization;

phase-space and loop-routing derivation;

version-1 setup migration.

Collinear.wl

diagram generation;

amplitude conversion and in-memory amplitude cache;

explicit physical conjugation;

spin/projector algebra;

factorized-pair construction;

kinematic zero application;

unresolved-algebra checks.

Topologies.wl

Cut formatting and parsing;

cut-aware partial fractions;

denominator provenance transport;

topology-record constructor and validator;

topology construction;

topology-equivalence proposal parsing and physical certification.

DimensionalShift.wl

Only mathematical kernels and their thin orchestration:

numerator normalization;

Gram/Wishart recurrence;

parameter monomial mapping;

cached Tarasov lowering;

cut projection after every step;

LinearIntegralSum output.

FCLoopGLIRaiseDimension should remain the standard one-step Tarasov implementation; the custom code should cache and orchestrate it rather than reproduce its recurrence. 
FeynCalc

Reduction.wl

pre-IBP artifact construction;

result-file streaming and summary aggregation;

topology aggregation;

Kira project adapter;

Kira execution and import;

reduction-table closure;

sparse application of reduction tables;

final coefficient normalization;

one Kira/IBP artifact constructor.

Kira runtime configuration belongs here. Kira 3.1’s current installation documentation still lists Fermat as required even when FireFly and FLINT support are enabled, so the Fermat dependency check should not be deleted without testing the exact installed build. It should, however, be removed from global package state and placed in the backend configuration. 
GitLab

Error-handling architecture

Replace subsystem-specific Catch tags and boolean validator wrappers with failures carrying a stage path:

Wolfram Language
Failure[
  "InvalidCutPower",
  <|
    "Stage" -> "PartialFraction/RestoreCuts",
    "Topology" -> topologyName,
    "CutMomentum" -> q,
    "ObservedPower" -> value
  |>
]

Internal functions should return either a valid object or a Failure.

Public wrappers translate failures to existing messages and return $Failed for backward compatibility.

For Mathematica 14.2, Enclose, ConfirmBy and ConfirmMatch provide the intended fail-fast structure and retain information about the failed expression and predicate. 
Wolfram Documentation
+1

For example:

Wolfram Language
normalizeProcess[config_Association] := Enclose[
  Module[{...},
    missing = Complement[requiredKeys, Keys[config]];
    ConfirmBy[
      missing,
      EmptyQ,
      <|"Stage" -> "ProcessNormalization", "MissingKeys" -> missing|>
    ];
    ...
    process
  ]
]

Do not build a general-purpose schema language. Two explicit constructors—normalizeProcess and makeTopologyRecord—with shared primitive validators are simpler and easier to audit.

Parallelism

There should be exactly one Mathematica worker-pool abstraction, for example:

Wolfram Language
parallelMapHeavy[
  function_,
  items_,
  workerInitialization_,
  OptionsPattern[]
]

Its responsibilities:

decide serial versus parallel from item count and a configurable threshold;

launch only missing kernels;

initialize FeynCalc/FeynFacet and install the exact analytic context;

use one scheduling method;

close only the kernels it launched;

return results in deterministic input order;

fail if any worker returns $Failed, $Aborted, Failure or unresolved Missing.

For the small number of master coefficients with uneven complexity, ParallelMap[..., Method -> "FinestGrained"] already provides fine-grained load balancing and can replace the manual ParallelSubmit/WaitNext queue. 
Wolfram Documentation

Use it initially only for final master coefficients. Do not parallelize:

cut parsing;

topology-record validation;

result construction;

short topology mappings;

Kira file assembly.

Saved result files can be streamed through one ordinary Fold: load one user-supplied artifact, extract its validated summary/targets/topology records, and release the full integrand. This is not coefficient disk sharding and introduces no hidden temporary staging.

A later batch-pair driver can use the same worker abstraction for distinct amplitude conversions, after amplitude caching is implemented.

Overengineered constructs versus checks that must remain
Remove or reduce
Construct	Disposition
Six-element and five-element stage result lists	Internal associations; legacy lists only at public wrappers
Repeated raw setup validation	Normalize once
Partial topology records followed by AMFlow attachment	Construct one complete record
Boolean ...Q validators plus separate safe wrappers	One validator returning Failure
Manual dynamic task queue	ParallelMap through one wrapper
Structural common factor across all masters	Delete from production result construction
Per-master PreFactor plus coefficient split	Store exact coefficient directly
Repeated process comparison via modified raw Setup	Compare normalized physics contexts
Print inside kernels	Reporter only
ToExpression for generated symbols	Private deterministic naming
ToExpression for parsing Kira master indices	Strict integer parser
Global backend variables	Options/configuration association
Directory inference from a file’s grandparent directory	Require explicit artifact metadata
Multiple nested Quiet@CheckAbort@Check patterns	One failure boundary around external calls
General Simplify in intermediate stages	Exact restricted normalizer
Optional physical propagator metadata	Mandatory in production
Keep explicit

The following checks are not overengineering:

oriented-cut parsing and conflict detection;

exact cut-power preservation;

complete and non-overdetermined topology basis;

one symbolic loop dimension;

strict top-level GLI permutation;

exact real-rational affine momentum map;

determinant ±1;

no external momentum replacement;

exact external basis and kinematic-rule agreement;

per-propagator polynomial/type/power checks;

physical eta and causal-side checks;

cut-slot bijection;

momentum-sign-induced delta-orientation check;

AMFlow routing restriction;

FeynCalc mapping coverage;

conservative separation after rejected witnesses;

unsupported SPE grammar rejection;

rank-by-rank Gram-moment validation;

positive cut indices after every Tarasov step;

one GLI per shifted term;

no unresolved loop-dependent scalar products;

Kira cut_propagators insertion;

requested-target cut audit;

Kira rule transitive closure;

declared-master validation;

post-import cut audit;

exact reconstruction of the final master expansion;

safe project-directory deletion.

Those checks define the scientific contract.

Staged rewrite order
Stage 0: correctness patch and frozen baseline

Before moving code:

Correct conjugate-side denominator prescriptions.

Make production merging reject incomplete physical metadata.

Correct cut-power restoration.

Project cut sectors after every one-step dimension recurrence.

Replace critical PossibleZeroQ uses with the exact rational zero predicate.

Add explicit branch/distribution protection around final coefficient normalization.

Regression gate:

current NLO physics fixtures reproduce the established result after the intended causal correction;

synthetic dotted-cut test preserves exponent;

synthetic two-step Tarasov test cannot resurrect a removed cut;

conjugate propagator cores remain unchanged while eta signs flip.

Stage 1: process normalization

Implement normalizeProcess and convert:

GenerateDiagram;

AMFlowPrescription;

CollinearFactorize;

CollinearFactorizePreIBP

to call it exactly once at their public boundary.

Delete the duplicate side/setup validation functions only after all public tests pass.

Regression gate:

normalized process is deterministic and idempotent;

all existing valid cards normalize;

all current invalid-card tests fail at the same or more precise stage;

normalized physics contexts are identical across diagram-pair selections except for the pair field.

Stage 2: denominator provenance and topology records

Make amplitude/conjugate/cut provenance explicit before multiplying denominators.

Implement makeTopologyRecord and validateTopologyRecord.

Make BuildTopologies return complete records with:

BaseGLI;

family coefficient;

complete PropagatorData;

AMFlow metadata;

pair;

context IDs.

Delete attachAMFlowInfo, validStoredTopologyQ, safeTopologyRecordQ, and repeated record checks.

Regression gate:

every generated record validates through the same function;

every source partial-fraction term is reconstructed exactly from its stored coefficient and base GLI;

every cut index maps to the declared momentum and direction;

every ordinary propagator has the correct physical side and eta sign;

the 39-record NLO fixture still gives eight conservative classes and 31 accepted mappings;

changing one role, eta sign, cut direction or AMFlow label prevents merging.

Stage 3: sparse integral sums and dimensional shift

Introduce LinearIntegralSum.

Refactor DimensionalShift into:

normalize numerator
→ expand SPE polynomial
→ Gram moment
→ parameter monomial mapping
→ one-step Tarasov lowering with cut projection
→ numerator-to-GLI mapping
→ sparse merge

Use one runtime kernel per topology/active sector.

Delete repeated Collect2, dimensionalShiftParameterPosition calls and repeated rules-to-GLI generation.

Regression gate:

rank-zero shift is identity;

rank-one through rank-four moments agree with the existing pairing or symbolic reference tests;

one- and two-loop dimension-shift fixtures agree exactly;

every intermediate GLI retains positive cut powers;

no coefficient contains loop momenta, FAD, SFAD, SP, SPD or SPE involving loop momenta;

serial ordering changes do not affect output.

Stage 4: collinear orchestration

Split CollinearFactorize into small kernels:

convert selected amplitudes
→ physical conjugation
→ denominator/numerator split
→ spin and polarization processing
→ density projectors
→ BMHV/kinematic zeros
→ Calc boundary
→ factorized-pair construction

Add an in-memory amplitude cache keyed by:

diagram topology/insertion identity;

selected index;

loop momentum convention;

FCFAConvert option hash;

model/gauge;

BMHV scheme;

FeynCalc/FeynArts versions.

Do not introduce a persistent disk cache in this rewrite.

Regression gate:

converted amplitude cache hit and miss give SameQ results after dummy-index canonicalization;

integrated momentum is absent;

all external spin tags are consumed;

no unresolved algebra remains;

forward and conjugate side denominator inventories are preserved.

Stage 5: artifacts and Kira

Implement:

Wolfram Language
makeArtifact[type_, context_, payload_]
validateArtifact[artifact_]

and one reduction-specific constructor for both Kira and final IBP outputs.

Unify association and file inputs through:

Wolfram Language
summarizePreIBPItem[item_]
aggregatePreIBPSummaries[summaries_]

The file form loads one artifact at a time.

Move Kira-specific YAML and process handling entirely into the backend adapter.

Regression gate:

old pre-IBP format version 1 loads through an explicit migration;

old Kira and IBP artifacts migrate or fail with a version-specific message;

empty and nonempty reductions have the same schema;

all requested targets are present;

imported rules close;

all terminal masters preserve cuts;

mapped results agree exactly in a common master basis.

Stage 6: coefficient normalization and parallelism

Separate:

ApplyReduction

from:

NormalizeMasterCoefficients

The first is pure sparse exact linear algebra. The second may use the one worker pool.

Delete ibpStructuralCommonFactor and make output factoring optional.

Regression gate:

unsimplified sparse master expansion reconstructs exactly;

normalized expansion reconstructs exactly;

one-kernel and eight-kernel results are SameQ after deterministic key sorting;

inventory of distributions, endpoint factors and branch heads is unchanged;

held causal and cut metadata is unchanged.

Stage 7: optional FeynCalc bulk replacements

Only after all previous gates pass, benchmark replacing per-term topology discovery with:

FCLoopIsolate
→ FCLoopFindTopologies
→ controlled completion
→ FACET physical-record validation

FeynCalc documents this as the intended bulk workflow and returns both the GLI-rewritten expression and identified topologies. It may return incomplete topologies, so FACET completion and cut-slot checks remain necessary. 
FeynCalc
+1

This is an optimization phase, not part of the initial structural rewrite.

Safe standard-function replacements
Safe to adopt now
Enclose, ConfirmBy, ConfirmMatch

Replace custom tagged Catch scaffolding while preserving detailed stage data. 
Wolfram Documentation
+1

ParallelMap

Replace the manual task queue for uneven final coefficients:

Wolfram Language
ParallelMap[
  normalizeCoefficient[#, context] &,
  coefficients,
  Method -> "FinestGrained",
  DistributedContexts -> None
]

Initialize workers explicitly before the call. 
Wolfram Documentation

VerificationTest and TestReport

Use the built-in testing framework for exact fixtures, with SameTest -> SameQ or a deliberately defined exact canonical comparison. VerificationTest supports expected messages, time limits and memory limits. 
Wolfram Documentation

FCLoopGetFeynAmpDenominators

Use instead of repeated raw Cases where the task is simply to extract denominator objects. Keep the FACET parser for powers, eta signs, physical roles and cuts.

FCLoopPropagatorsToLineMomenta

Use for supported standard propagators instead of independently parsing their momentum argument. Still verify the result against the exact propagator polynomial and preserve the separate cut orientation.

FCLoopCreateRulesToGLI

Generate once per topology or for a list of topologies, then cache. Do not call it once per numerator monomial. 
FeynCalc

FeynAmpDenominatorSplit

The current use for separating loop-dependent and loop-independent denominator factors is appropriate and should remain. FeynCalc explicitly supports splitting according to a specified momentum list. 
FeynCalc

FCLoopGLIRaiseDimension

Keep as the one-step dimensional recurrence and memoize its result. 
FeynCalc

Adopt only after dedicated tests
FCLoopFindTopologies and FCLoopIsolate

Good candidates for bulk topology extraction, but they do not know FACET cut orientation, measurement identity or causal provenance. Use only with sidecar metadata and mandatory postvalidation. 
FeynCalc
+1

FCLoopRewriteIncompleteTopologies

It can automate basis completion, but its choice and ordering of added propagators must not silently alter fixed cut slots or the chosen parent-family convention. Use only if the resulting topology record passes the full validator. 
FeynCalc

Do not use as replacements

FCLoopFindTopologyMappings without the existing physical certificate layer. It supplies candidate loop shifts and GLI mappings, not a physical equivalence proof. 
FeynCalc

FCLoopSwitchEtaSign for physical conjugation.

FCLoopTensorReduce for BMHV SPE moments.

generic FullSimplify for production coefficients.

PowerExpand.

automatic external-momentum exchanges.

automatic topology completion without cut-slot validation.

Exact regression invariants

The rewrite should be gated by invariants, not by output size or numerical spot checks.

Process and BMHV invariants

normalizeProcess is deterministic.

Every external momentum declared four-dimensional has zero SPE with every vector after scalar-product expansion.

No phase-space or virtual loop momentum is accidentally declared four-dimensional.

The BMHV scheme and four-dimensional-momentum set are stored in every artifact.

The momentum-elimination rule removes exactly one declared outgoing phase-space momentum.

No eliminated momentum survives.

Partial-fraction invariants

For every term:

AlgebraizeCuts[original−
i
∑
	​

term
i
	​

]=0.

Additionally:

every required cut occurs;

its exact positive integer power is preserved;

the cut momentum agrees up to sign;

its direction transforms with that sign;

no ordinary propagator changes causal role;

no opposite-prescription denominators are identified;

no unsupported new denominator is introduced.

Topology-record invariants

For every record:

FCLoopValidTopologyQ is true;

incomplete and overdetermined tests are false;

topology loop ordering equals the process loop ordering;

every topology propagator has unit family power;

BaseGLI has the correct arity;

source term equals stored coefficient times the explicit base integral;

cut indices are distinct and positive;

cut momentum, direction and propagator slot agree;

PropagatorData length equals topology length;

causal side, physical eta and role are complete;

context IDs agree with the process.

Topology-equivalence invariants

For every accepted certificate:

A∈GL(L,Q),detA=±1.

And:

the GLI map is a strict permutation;

every mapped propagator core is identical;

type and power agree;

physical descriptors agree;

cut slots map bijectively;

delta orientation is preserved;

no external momentum is replaced;

AMFlow routing is compatible;

the synthesized verified GLI rule agrees with the FeynCalc witness;

the class partition covers every input name exactly once.

Dimensional-shift invariants

rank-zero identity;

rank-one and rank-two moments match closed formulas;

higher-rank moments match a reference pairing implementation in tests;

every one-step recurrence is followed by cut projection;

no cut index is ever nonpositive in a surviving intermediate expression;

every output term contains exactly one GLI;

coefficients contain no loop momentum;

no SPE survives;

no general simplification is applied;

exact D dependence remains symbolic.

Reduction invariants

target set equals the keys of the aggregated sparse input;

topology mapping changes keys only, not coefficients;

every Kira target preserves all cuts;

Kira output closes transitively;

every terminal integral is a declared master;

every master preserves all cuts;

imported rules reproduce the original equations at exact rational test substitutions;

final reduction is independent of file versus in-memory input;

no physical family is merged without verified metadata.

Final-artifact invariants

The stored master data must reconstruct:

Expression=PreFactor[Remainder+
m
∑
	​

c
m
	​

M
m
	​

]

exactly.

Also require:

no $Failed or $Aborted;

no unsupported Missing in scientific fields;

no machine-real numbers;

no loop-dependent coefficient;

no unresolved denominator objects;

identical inventory of distributions, cuts, endpoint powers and branch heads before and after coefficient normalization;

one-kernel and multikernel results agree exactly.

Recommended end state

The public call chain remains:

Wolfram Language
CollinearFactorizePreIBP[config]
KiraReduction[resultsOrFiles]
CoefficientSimplification[results, reduction]
IBP[results]

but internally becomes:

normalizeProcess
→ prepare diagrams and cached amplitudes
→ factorized pair with denominator provenance
→ cut-aware partial fractions
→ complete validated topology records
→ cached exact dimensional shift
→ sparse pre-IBP integral sum
→ verified topology-key aggregation
→ exact Kira reduction table
→ sparse reduction composition
→ protected final coefficient normalization
→ one versioned IBP artifact

The immediate implementation order should be:

fix causal conjugation, mandatory metadata, cut powers and stepwise cut projection;

introduce normalized process and topology constructors;

introduce LinearIntegralSum;

refactor dimensional shift around topology kernels;

unify artifacts and Kira input handling;

replace the worker queue and broad coefficient simplification;

only then test bulk FeynCalc topology discovery.

That sequence reduces code while strengthening, rather than weakening, the exact physical contract.
