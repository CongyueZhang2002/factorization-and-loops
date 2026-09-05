# Implementation Review

## Question

Continue reviewing the same FACET/FeynFacet rewrite. This is the first complete implementation after applying your architecture advice. Review the full source below as code, not as a proposal.

Scientific contract:
- Exact analytic hard functions; numerical values are verification only.
- Preserve physical cuts, energy directions, causal eta signs, branches, endpoint/distribution objects, BMHV information, and exact rational normalization.
- Fail closed when metadata or algebraic structure is unsupported.

What changed:
1. Normalized FeynFacetProcess and internal FactorizedPair associations; legacy public list outputs retained only at the API boundary.
2. Complete FeynFacetTopologyRecord metadata separates eta-normalized algebraic FCTopology from physical side/eta/cut direction.
3. Conjugate denominators flip eta while preserving the denominator core.
4. Dotted cut powers are retained. Every Tarasov D+2 step immediately projects pinched cuts and rejects symbolic cut indices.
5. Topology equivalence now requires an exact affine rational unit-Jacobian map and verifies propagator type/power/eta, physical provenance, cut index/momentum/direction, and AMFlow loop routing before emitting a GLI rule.
6. IBP reconstruction uses sparse LinearIntegralSum maps, composes topology/Kira rules on GLI keys, and never constructs then recollects the giant intermediate expression.
7. Coefficient normalization inertizes cuts, distributions, branch-sensitive special functions, and noninteger powers, then applies only exact Cancel[Together] to the rational shell.
8. Process normalization is performed once and reused through pre-IBP/AMFlow construction.
9. The prior broad, staged simplification path is gone. A single dynamic worker pool simplifies independent final master coefficients. ParallelMap with shared progress deadlocked under Linux, so the proven ParallelSubmit/WaitNext scheduler is retained.

Current source metrics:
- Before: 148273 bytes, 5166 lines.
- Current: 146188 bytes, 5027 lines.
- Diff: 757 inserted lines, 896 deleted lines (net -139 lines).

Exact regression evidence:
- Actual NLO UU F1/C2 full pre-IBP pipeline: 4 GLIs, 2 topologies, 191.32 kB, no surviving SPE.
- Dotted cut, causal eta, side provenance, eta normalization, cut projection, symbolic cut rejection, and branch preservation all pass.
- PartialFraction two-loop, BuildTopologies, DimensionalShift, Gram recurrence, pre-IBP, and sparse LinearIntegralSum tests pass.
- Topology stress: 39 NLO records -> 8 classes and 31 certified mappings; 20 input-order trials; 39/39 propagator permutations; 40 affine one-loop variants; synthetic two- and three-loop unimodular orbits; 22 adversarial mutants; 800/800 random GLI index transformations all pass.

Review requests:
A. Identify concrete correctness bugs or scientific-contract violations, with exact function names and replacement logic.
B. Identify genuinely redundant functions/validation passes and specific ways to reduce source size and nesting without weakening checks.
C. Review the sparse LinearIntegralSum reduction composition and the split between eta-normalized algebraic topologies and physical causal metadata.
D. Say whether a facade plus private module files would materially improve maintainability, or only move the same complexity around.
E. Do not recommend deleting the two-level overall/per-master common factors: that is a user-required artifact format.
F. Return a prioritized patch list. Avoid a wholesale new architecture unless a concrete defect requires it.

FULL SOURCE FOLLOWS
===================

(* ::Package:: *)

If[Names["FeynCalc`$FeynCalcVersion"] === {}, Needs["FeynCalc`"]];

BeginPackage["FeynFacet`"];

Get[FileNameJoin[{DirectoryName[$InputFileName], "Distributions.wl"}]];

DeclareScalar::usage =
  "DeclareScalar[expr] declares the scalar pieces of expr as FeynCalc variables.";

BuildBasis::usage =
  "BuildBasis[{nb,n,xhat,yhat}, assumptions] validates a light-cone basis.";

Build4Vec::usage =
  "Build4Vec[coordinates, basis] constructs a vector from basis coordinates.";

BuildGlobalBasis::usage =
  "BuildGlobalBasis[{nb,n,xhat,yhat}] installs and validates the global basis.";

GlobalBasisGram::usage =
  "GlobalBasisGram is the Gram matrix of {nb,n,xhat,yhat}.";

NA::usage =
  "NA marks a parton with no associated hadron quantity.";

SimplifyAssum::usage =
  "SimplifyAssum[expr, assumptions] applies Simplify with assumptions.";

FullSimplifyAssum::usage =
  "FullSimplifyAssum[expr, assumptions] applies FullSimplify with assumptions.";

FeynFacet`dD::usage =
  "dD[k] is the remaining D-dimensional integration measure for k.";

dFraction::usage =
  "dFraction[x] is the differential measure for a momentum fraction x.";

Cut::usage =
  "Cut[SPD[q],direction] is an oriented on-shell cut propagator. direction=1 denotes theta(q^0) delta(q^2), direction=-1 denotes theta(-q^0) delta(q^2), and Cut[SPD[q]] is shorthand for direction=1.";

PartialFraction::usage =
  "PartialFraction[expr,{k1,...}] applies ApartFF while retaining every Cut propagator and its positive-energy orientation in each returned term. With no loop momenta, PartialFraction[expr,{}] returns expr unchanged.";

BuildTopologies::usage =
  "BuildTopologies[fractions,{k1,...},setup] constructs a complete cut-aware FCTopology for every denominator family in a partial-fraction result, names it TopologyF<forward SelectedIndex>C<conjugate SelectedIndex>N<n>, prints a topology summary including cut directions, and returns the family data with CutMomenta, CutIndices and CutDirections. External momenta and on-shell rules are inferred from the denominators and setup. With no loop momenta and fractions equal to 1, it returns an empty family list.";

TopologyEquivalence::usage =
  "TopologyEquivalence[topologies] finds conservative multiloop equivalence classes. Accepted mappings have exact rational unit Jacobian and preserve every propagator, eta sign, cut slot, cut energy direction and AMFlow loop prescription.";

GenerateDiagram::usage =
  "GenerateDiagram[setup] generates and returns the complete FeynArts diagram lists for Setup[\"ForwardAmplitudes\"] and Setup[\"ConjugateAmplitudes\"].";

DimensionalShift::usage =
  "DimensionalShift[integrand,families,{k1,...}] applies the topology-dependent dimensional shift to every integral family, collects the GLI coefficients without expensive simplification, prints a result summary, and returns the collected expression. With no families and no loop momenta, it returns integrand unchanged. Coefficients should be simplified after IBP and master aggregation. DimensionalShift[integrand,propagators,{k1,...},topology] applies the shift to one family.";

CommonFactorSafe::usage =
  "CommonFactorSafe[expr,{k1,...}] extracts a common prefactor while retaining scalar products that depend on loop momenta, propagators, cuts, measures and GLI master integrals in the remainder.";

CollinearFactorize::usage =
  "CollinearFactorize[config] returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Propagators,LoopMomentum}. LoopMomentum contains the remaining phase-space momenta followed by the forward and conjugate virtual-loop momenta.";

CollinearFactorizePreIBP::usage =
  "CollinearFactorizePreIBP[config] runs diagram generation, collinear factorization, partial fractioning, topology construction and dimensional shifting from one configuration Association. It returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Topologies}, where Integrand is the GLI expression and every topology record contains cut and AMFlow prescription metadata.";

GenerateCollinearFactorizePreIBPResult::usage =
  "GenerateCollinearFactorizePreIBPResult[setup,fractionMeasure,preFactor,phaseSpace,integrand,topologies] validates and packages one selected diagram-pair result into the stable FeynFacet storage Association.";

KiraReduction::usage =
  "KiraReduction[inputs] identifies equivalent cut topologies, runs one combined Kira reduction and returns exact reduction rules. inputs is a list of saved result files or pre-IBP Associations.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraReduction] reconstructs and simplifies the master coefficients. Saved files are read one at a time; only final master coefficients enter the dynamic kernel pool.";

IBP::usage =
  "IBP[results] is equivalent to CoefficientSimplification[results,KiraReduction[results]].";

AMFlowPrescription::usage =
  "AMFlowPrescription[config] returns the loop-momentum ordering and Feynman-prescription list required by AMFlow: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";

SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[IBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateDiagram] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[DimensionalShift] = {"ArgumentsPattern" -> {_, _, _, _.}};

Options[PartialFraction] = {
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False
};

Begin["`Private`"];

$feynFacetRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];

NA = Missing["NotApplicable"];

GlobalBasisGram = {
  {0, 1, 0, 0},
  {1, 0, 0, 0},
  {0, 0, -1, 0},
  {0, 0, 0, -1}
};

globalBasis = Missing["NotSet"];
internalSetEvanescentZero = Missing["NotSet"];

resultHeader[format_, version_Integer] := <|
  "Format" -> format,
  "FormatVersion" -> version,
  "Created" -> DateString[{"ISODate", "T", "Time"}]
|>;

resultContext[data_Association] := KeyTake[
  data,
  {"CardName", "ResultDirectory", "Pairs", "Setup"}
];

Clear[DeclareScalar];

DeclareScalar[scalars_List] := Module[{pieces},
  pieces = DeleteDuplicates @ Cases[
    scalars,
    x_ /; ! ListQ[Unevaluated[x]] &&
      ! MatchQ[x, _Integer | _Rational] &&
      ! TrueQ[PossibleZeroQ[x]],
    {1, Infinity},
    Heads -> False
  ];
  Scan[(FeynCalc`DataType[#, FeynCalc`FCVariable] = True) &, pieces];
  scalars
];

DeclareScalar[scalar_] := First[DeclareScalar[{scalar}]];

BuildBasis::length = "Expected four basis vectors, but received `1`.";
BuildBasis::relation = "Basis relations failed: `1`.";

Clear[BuildBasis];

BuildBasis[basis_List, assumptions_: True] := Module[
  {heads, expected, actual, bad},

  If[Length[basis] =!= 4,
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  expected = {
    GlobalBasisGram,
    GlobalBasisGram,
    ConstantArray[0, {4, 4}]
  };
  actual = FullSimplify[
    Table[
      FeynCalc`ExpandScalarProduct[
        heads[[kind]][basis[[i]], basis[[j]]]
      ],
      {kind, 3}, {i, 4}, {j, 4}
    ],
    Assumptions -> assumptions
  ];
  bad = Position[MapThread[SameQ, {actual, expected}, 3], False];

  If[bad =!= {},
    Message[
      BuildBasis::relation,
      Function[pos, {
        heads[[pos[[1]]]],
        basis[[pos[[2]]]],
        basis[[pos[[3]]]],
        expected[[Sequence @@ pos]],
        actual[[Sequence @@ pos]]
      }] /@ bad
    ];
    Return[$Failed]
  ];

  basis
];

BuildBasis[basis_, assumptions_: True] := (
  Message[BuildBasis::length, basis];
  $Failed
);

Clear[Build4Vec];

Build4Vec[coordinates_List, basis_List] /;
    Length[coordinates] === Length[basis] := (
  DeclareScalar[coordinates];
  Total[coordinates basis]
);

Clear[declareGlobalBasis, BuildGlobalBasis];

declareGlobalBasis[basis_List] := Do[
  With[
    {p = basis[[i]], q = basis[[j]], value = GlobalBasisGram[[i, j]]},
    FeynCalc`SP[p, q] = value;
    FeynCalc`SPD[p, q] = value;
    FeynCalc`SPE[p, q] = 0
  ],
  {i, 4}, {j, i, 4}
];

BuildGlobalBasis[basis_List] := Module[{},
  If[Length[basis] =!= 4,
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];
  globalBasis = basis;
  internalSetEvanescentZero = basis[[{2, 1, 3, 4}]];
  declareGlobalBasis[basis];
  BuildBasis[basis]
];

Clear[SimplifyAssum, FullSimplifyAssum];

SimplifyAssum[expr_, assumptions_: True] :=
  Simplify[expr, Assumptions -> assumptions];

FullSimplifyAssum[expr_, assumptions_: True] :=
  FullSimplify[expr, Assumptions -> assumptions];

Clear[FeynFacet`dD, dFraction, Cut];

SetAttributes[Cut, HoldAll];

FeynFacet`dD /: MakeBoxes[
    FeynFacet`dD[k_, dim_: D],
    form : StandardForm | TraditionalForm
  ] := RowBox[{
  SuperscriptBox["d", ToBoxes[dim, form]],
  ToBoxes[k, form]
}];

dFraction /: MakeBoxes[
    dFraction[x_],
    form : StandardForm | TraditionalForm
  ] := With[
  {xBoxes = ToBoxes[x, form]},
  InterpretationBox[
    RowBox[{"\[DifferentialD]", xBoxes}],
    dFraction[x]
  ]
];

Cut /: MakeBoxes[
    cut : Cut[argument_, direction_: 1],
    form : StandardForm | TraditionalForm
  ] := Module[{shown, boxes, sign},
  shown = argument /. FeynCalc`SPD[q_] :> HoldForm[q^2];
  boxes = MakeBoxes[shown, form];
  sign = Switch[direction, 1, "+", -1, "-", _, ToBoxes[direction, form]];
  InterpretationBox[
    RowBox[{SubscriptBox["\[Delta]", sign], "(", boxes, ")"}],
    cut
  ]
];

GenerateDiagram::setup =
  "Setup must contain ForwardAmplitudes, ConjugateAmplitudes, Partons, Model, InsertionLevel, ExcludeTopologies and ExcludeParticles. Received `1`.";

GenerateDiagram::amplitudes =
  "`1` must contain LoopOrder, LoopMomenta and a nonempty list of positive DiagramIndices; SelectedIndex is optional and must belong to DiagramIndices. Received `2`.";

GenerateDiagram::index =
  "`1` contains diagram index `2`, but only `3` diagrams were generated.";

Clear[normalizeAmplitudeSelection];

normalizeAmplitudeSelection[
    diagrams_,
    setup_Association,
    label_String,
    required_: False
  ] := Module[
  {allowed, order, loops, indices, selected, invalid, index},

  allowed = {"LoopOrder", "LoopMomenta", "DiagramIndices", "SelectedIndex"};
  order = Lookup[setup, "LoopOrder", -1];
  loops = Lookup[setup, "LoopMomenta", None];
  indices = Lookup[setup, "DiagramIndices", None];
  selected = Lookup[setup, "SelectedIndex", None];
  invalid = Complement[Keys[setup], allowed] =!= {} ||
    ! IntegerQ[order] || order < 0 || ! MatchQ[loops, {_Symbol ...}] ||
    Length[loops] =!= order || ! DuplicateFreeQ[loops] ||
    ! MatchQ[indices, {__Integer?Positive}] || ! DuplicateFreeQ[indices] ||
    (selected =!= None && ! MemberQ[indices, selected]);
  If[invalid,
    Message[GenerateDiagram::amplitudes, label, setup];
    Return[$Failed]
  ];
  If[diagrams =!= All,
    index = FirstCase[indices, _?(# > Length[diagrams] &), None];
    If[index =!= None,
      Message[GenerateDiagram::index, label, index, Length[diagrams]];
      Return[$Failed]
    ]
  ];
  If[selected === None,
    If[required, Message[GenerateDiagram::amplitudes, label, setup]];
    Return[If[required, $Failed, setup]]
  ];
  Join[setup, <|"DiagramIndex" -> selected|>]
];

Clear[GenerateDiagram];

GenerateDiagram[setup_Association] := Module[
  {
    setupKeys, sideSetups, generateAtLoopOrder,
    loopOrders, diagramsByLoopOrder, diagramsBySide, resolved
  },

  setupKeys = {
    "ForwardAmplitudes", "ConjugateAmplitudes",
    "Partons", "Model", "InsertionLevel",
    "ExcludeTopologies", "ExcludeParticles"
  };
  If[! AllTrue[setupKeys, KeyExistsQ[setup, #] &],
    Message[GenerateDiagram::setup, setup];
    Return[$Failed]
  ];

  sideSetups = <|
    "Amplitude" -> setup["ForwardAmplitudes"],
    "Conjugate" -> setup["ConjugateAmplitudes"]
  |>;
  If[! AllTrue[Values[sideSetups], AssociationQ],
    Message[GenerateDiagram::setup, setup];
    Return[$Failed]
  ];
  resolved = MapThread[
    normalizeAmplitudeSelection,
    {
      ConstantArray[All, Length[sideNames]],
      Values[sideSetups],
      {"ForwardAmplitudes", "ConjugateAmplitudes"}
    }
  ];
  If[MemberQ[resolved, $Failed], Return[$Failed]];
  generateAtLoopOrder[loopOrder_Integer] := FeynArts`InsertFields[
    FeynArts`CreateTopologies[
      loopOrder,
      Length /@ setup["Partons"],
      FeynArts`ExcludeTopologies -> setup["ExcludeTopologies"]
    ],
    setup["Partons"],
    FeynArts`Model -> setup["Model"],
    FeynArts`InsertionLevel -> setup["InsertionLevel"],
    FeynArts`ExcludeParticles -> setup["ExcludeParticles"]
  ];

  loopOrders = DeleteDuplicates @ Lookup[
    Values[sideSetups],
    "LoopOrder"
  ];
  diagramsByLoopOrder = AssociationMap[generateAtLoopOrder, loopOrders];
  diagramsBySide = <|
    "Amplitude" -> diagramsByLoopOrder[
      sideSetups["Amplitude"]["LoopOrder"]
    ],
    "Conjugate" -> diagramsByLoopOrder[
      sideSetups["Conjugate"]["LoopOrder"]
    ]
  |>;
  resolved = MapThread[
    normalizeAmplitudeSelection,
    {
      Values[diagramsBySide],
      Values[sideSetups],
      {"ForwardAmplitudes", "ConjugateAmplitudes"}
    }
  ];
  If[MemberQ[resolved, $Failed], Return[$Failed]];
  diagramsBySide
];

GenerateDiagram[setup_] := (
  Message[GenerateDiagram::setup, setup];
  $Failed
);

Clear[printSelectedDiagrams];

printSelectedDiagrams[
    diagramsBySide_Association,
    setup_Association
  ] := Module[{printOne},

  printOne[label_String, side_String, key_String] := Module[
    {index},
    index = setup[key]["SelectedIndex"];
    Print[Style[label <> " " <> ToString[index], Bold, 14]];
    FeynArts`Paint[
      FeynArts`DiagramExtract[diagramsBySide[side], index],
      FeynArts`ColumnsXRows -> {1, 1},
      FeynArts`Numbering -> None,
      FeynArts`SheetHeader -> None,
      DisplayFunction -> (Print /@ FeynArts`Render[#, ImageSize -> 320] &)
    ]
  ];

  printOne["Forward", "Amplitude", "ForwardAmplitudes"];
  printOne["Conjugate", "Conjugate", "ConjugateAmplitudes"];
  Null
];

Clear[CommonFactorSafe];

CommonFactorSafe[expr_, loopMomenta_List : {}] := Module[
  {
    external, protected, atoms, toAtoms, fromAtoms,
    factored, factors, prefactor
  },

  If[TrueQ[expr === 0], Return[{1, 0}]];

  external = FeynCalc`FCE[expr];
  protected = DeleteDuplicates @ Cases[
    external,
    object_ /; With[
      {head = Head[Unevaluated[object]]},
      MemberQ[
        {
          FeynCalc`FAD, FeynCalc`SFAD, FeynCalc`CFAD,
          FeynCalc`GFAD, FeynCalc`PD, FeynCalc`GLI,
          FeynFacet`dD, dFraction, Cut
        },
        head
      ] || (
        MemberQ[
          {
            FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE,
            FeynCalc`CSP, FeynCalc`CSPD, FeynCalc`CSPE
          },
          head
        ] &&
        loopMomenta =!= {} &&
        ! FreeQ[Unevaluated[object], Alternatives @@ loopMomenta]
      )
    ] :> object,
    Infinity
  ];
  If[protected === {},
    factors = If[
      Head[external] === Times,
      List @@ external,
      {external}
    ];
    prefactor = Times @@ Select[factors, Head[#] =!= Plus &];
    Return[{
      prefactor,
      Times @@ Select[factors, Head[#] === Plus &]
    }]
  ];

  atoms = Table[Unique["protected$"], Length[protected]];
  toAtoms = Thread[protected -> atoms];
  fromAtoms = Thread[atoms -> protected];
  factored = Factor[external /. toAtoms];
  factors = If[Head[factored] === Times, List @@ factored, {factored}];
  prefactor = Times @@ Select[
    factors,
    FreeQ[#, Alternatives @@ atoms] &
  ];

  {
    Factor[prefactor /. fromAtoms],
    Factor[(factored/prefactor) /. fromAtoms]
  }
];

PartialFraction::loops =
  "Loop momenta must be given as a list, but received `1`.";

PartialFraction::cut =
  "Cut propagators must have the form Cut[SPD[q]] or Cut[SPD[q],direction], with direction equal to 1 or -1. Invalid objects: `1`.";

PartialFraction::cutorientation =
  "The same quadratic cut denominator was assigned incompatible positive-energy orientations: `1`.";

PartialFraction::nocut =
  "ApartFF produced no term retaining all required cut propagators `1`.";

PartialFraction::cutpower =
  "ApartFF produced an unsupported cut power `1` for cut momentum `2`.";

Clear[
  termList,
  momentumRelativeSign,
  sameMomentumQ,
  sameOrientedCutQ,
  propagatorMomentum,
  parseHeldCut,
  cutData
];

termList[expr_] := Module[{expanded = Expand[expr]},
  If[Head[expanded] === Plus, List @@ expanded, {expanded}]
];

momentumRelativeSign[q_, target_] := Which[
  TrueQ[Expand[q - target] === 0], 1,
  TrueQ[Expand[q + target] === 0], -1,
  True, Missing["NotSameMomentum"]
];

sameMomentumQ[q_, target_] :=
  MemberQ[{1, -1}, momentumRelativeSign[q, target]];

sameOrientedCutQ[first_List, second_List] := Module[{sign},
  sign = momentumRelativeSign[first[[1]], second[[1]]];
  MemberQ[{1, -1}, sign] &&
    TrueQ[first[[2]] sign === second[[2]]]
];

propagatorMomentum[
    pd : (FeynCalc`PropagatorDenominator |
      FeynCalc`StandardPropagatorDenominator)[___]
  ] := Expand[
  First[pd] /. {
    FeynCalc`Momentum[q_, ___] :> q,
    I FeynCalc`Momentum[q_, ___] :> q
  }
];

parseHeldCut[HoldComplete[Cut[FeynCalc`SPD[q_]]]] := {q, 1};
parseHeldCut[
    HoldComplete[Cut[FeynCalc`SPD[q_], direction_]]
  ] := If[MemberQ[{1, -1}, direction], {q, direction}, $Failed];
parseHeldCut[_] := $Failed;

cutData[expr_] := Module[{objects, records, invalid, conflicts},
  objects = Cases[expr, cut_Cut :> HoldComplete[cut], Infinity];
  records = parseHeldCut /@ objects;
  invalid = Pick[
    objects,
    $Failed === # & /@ records
  ];
  If[invalid =!= {},
    Message[PartialFraction::cut, ReleaseHold /@ invalid];
    Return[$Failed]
  ];
  conflicts = Select[
    Subsets[records, {2}],
    sameMomentumQ[#[[1, 1]], #[[2, 1]]] &&
      ! sameOrientedCutQ[#[[1]], #[[2]]] &
  ];
  If[conflicts =!= {},
    Message[PartialFraction::cutorientation, conflicts];
    Return[$Failed]
  ];
  DeleteDuplicates[records, sameOrientedCutQ]
];

Clear[cutIndex, propagatorPower, restoreCutTerm];

cutIndex[q_, cutMomenta_List] := FirstCase[
  Range[Length[cutMomenta]],
  i_ /; sameMomentumQ[q, cutMomenta[[i]]] :> i,
  Missing["NotCut"]
];

propagatorPower[_FeynCalc`PropagatorDenominator] := 1;

propagatorPower[pd_FeynCalc`StandardPropagatorDenominator] :=
  If[MatchQ[pd[[4]], {_Integer?Positive, _}], pd[[4, 1]], $Failed];

restoreCutTerm[term_, cutRecords_List] := Module[
  {
    internal, propagators, indices, ordinary, coefficient,
    cutMomenta, powers, cutPowers, cutFactors, external
  },

  cutMomenta = First /@ cutRecords;
  internal = FeynCalc`FCI[term];
  propagators = Cases[
    internal,
    _FeynCalc`PropagatorDenominator |
      _FeynCalc`StandardPropagatorDenominator,
    Infinity
  ];
  indices = cutIndex[propagatorMomentum[#], cutMomenta] & /@ propagators;
  powers = propagatorPower /@ propagators;

  If[! ContainsAll[DeleteMissing[indices], Range[Length[cutMomenta]]],
    Return[Nothing]
  ];
  cutPowers = Table[
    Total @ Pick[powers, indices, cutPosition],
    {cutPosition, Length[cutMomenta]}
  ];
  If[! VectorQ[cutPowers, IntegerQ[#] && # > 0 &],
    With[{bad = FirstPosition[cutPowers, power_ /; ! IntegerQ[power] || power <= 0]},
      Message[
        PartialFraction::cutpower,
        cutPowers[[First[bad]]],
        cutMomenta[[First[bad]]]
      ]
    ];
    Return[$Failed]
  ];

  ordinary = Pick[propagators, MissingQ /@ indices];
  coefficient = internal /.
    HoldPattern[FeynCalc`FeynAmpDenominator[___]] -> 1;
  external = FeynCalc`FCE[
    coefficient If[
      ordinary === {},
      1,
      Apply[FeynCalc`FeynAmpDenominator, ordinary]
    ]
  ];
  cutFactors = MapIndexed[
    Function[{record, position},
      With[
        {
          power = cutPowers[[First[position]]],
          momentum = record[[1]],
          direction = record[[2]]
        },
        Cut[FeynCalc`SPD[momentum], direction]^power
      ]
    ],
    cutRecords
  ];

  external Times @@ cutFactors
];

Clear[PartialFraction];

PartialFraction[expr_, loopMomenta_List, OptionsPattern[]] := Module[
  {cutRecords, algebraic, reduced, result},

  If[loopMomenta === {}, Return[expr]];
  cutRecords = cutData[expr];
  If[cutRecords === $Failed, Return[$Failed]];

  algebraic = expr /. {
    HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`FAD[q],
    HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`FAD[q]
  };
  reduced = FeynCalc`ApartFF[
    algebraic,
    loopMomenta,
    FeynCalc`DropScaleless -> OptionValue[FeynCalc`DropScaleless],
    FeynCalc`FDS -> OptionValue[FeynCalc`FDS],
    FeynCalc`FCE -> False
  ];

  If[cutRecords === {}, Return[FeynCalc`FCE[reduced]]];
  result = restoreCutTerm[#, cutRecords] & /@ termList[reduced];
  If[MemberQ[result, $Failed], Return[$Failed]];
  If[result === {},
    Message[PartialFraction::nocut, cutRecords];
    Return[$Failed]
  ];
  Total[result]
];

PartialFraction[expr_, loopMomenta_, OptionsPattern[]] := (
  Message[PartialFraction::loops, loopMomenta];
  $Failed
);

DimensionalShift::loops =
  "Loop momenta must be a nonempty list identical to the topology loop-momentum ordering. Received `1`; topology uses `2`.";

DimensionalShift::topology =
  "The supplied object is not a valid complete FCTopology: `1`.";

DimensionalShift::dimension =
  "The topology must use exactly one symbolic loop dimension. Found `1`.";

DimensionalShift::propagators =
  "Could not map the propagator product into the supplied topology: `1`.";

DimensionalShift::cut =
  "Could not identify the required Cut propagators in the supplied topology: `1`.";

DimensionalShift::numerator =
  "The numerator is outside the supported polynomial SP/SPD/SPE grammar: `1`.";

DimensionalShift::evanescent =
  "Evanescent scalar products may contain only declared loop momenta. Unsupported objects: `1`.";

DimensionalShift::shift =
  "The topology-dependent dimensional recurrence failed at `1`.";

DimensionalShift::families =
  "Integral families must be a nonempty list of associations containing Propagators and Topology. Received `1`.";

$dimensionalShiftFailure = "FeynFacetDimensionalShiftFailure";

Clear[
  dimensionalShiftGramMomentFunction,
  dimensionalShiftParameterPosition,
  dimensionalShiftParameterPolynomial,
  dimensionalShiftRaiseOnce,
  dimensionalShiftRaiseToD,
  dimensionalShiftMultiplyNumerator,
  dimensionalShiftCutIndex,
  dimensionalShiftPreserveCuts,
  dimensionalShiftNormalizeNumerator
];

dimensionalShiftGramMomentFunction[
    covariance_,
    componentDimension_
  ] := Module[
  {
    loopCount, pairs, variables, sourceMatrix,
    determinantRules, beta, coefficient
  },

  loopCount = Length[covariance];
  pairs = Flatten[
    Table[{i, j}, {i, loopCount}, {j, i, loopCount}],
    1
  ];
  variables = Array[gramSource, Length[pairs]];
  sourceMatrix = ConstantArray[0, {loopCount, loopCount}];
  Do[
    With[
      {
        i = pairs[[position, 1]],
        j = pairs[[position, 2]],
        value = variables[[position]]
      },
      If[
        i === j,
        sourceMatrix[[i, i]] = value,
        sourceMatrix[[i, j]] = value/2;
        sourceMatrix[[j, i]] = value/2
      ]
    ],
    {position, Length[pairs]}
  ];
  determinantRules = Select[
    CoefficientRules[
      Expand @ Det[
        IdentityMatrix[loopCount] - 2 covariance . sourceMatrix
      ],
      variables
    ],
    Total[First[#]] > 0 &
  ];
  beta = componentDimension/2;
  coefficient[powers_List] /; Total[powers] === 0 := 1;
  coefficient[powers_List] /; Total[powers] > 0 :=
    coefficient[powers] = Module[{position, admissible},
      position = First @ FirstPosition[powers, _?(# > 0 &)];
      admissible = Select[
        determinantRules,
        And @@ Thread[First[#] <= powers] &
      ];
      -Total[
        Last[#] *
          (powers[[position]] +
            (beta - 1) First[#][[position]]) *
          coefficient[powers - First[#]] & /@ admissible
      ]/powers[[position]]
    ];

  Function[bilinears,
    Module[{normalized, powers},
      normalized = Sort /@ bilinears;
      If[! AllTrue[normalized, MemberQ[pairs, #] &], Return[$Failed]];
      powers = Count[normalized, #] & /@ pairs;
      Times @@ (Factorial /@ powers) coefficient[powers]
    ]
  ]
];

dimensionalShiftParameterPosition[
    propagator_,
    topology_FeynCalc`FCTopology,
    loopMomenta_List
  ] := Module[{converted, mapped, glis, positions},
  converted = CheckAbort[
    FeynCalc`FCLoopToGLI[propagator, loopMomenta],
    $Failed
  ];
  If[! MatchQ[converted, {_, _FeynCalc`FCTopology}], Return[$Failed]];
  mapped = CheckAbort[
    converted[[1]] /.
      FeynCalc`FCLoopCreateRuleGLIToGLI[topology, converted[[2]]],
    $Failed
  ];
  If[mapped === $Failed, Return[$Failed]];
  glis = Cases[mapped, _FeynCalc`GLI, {0, Infinity}];
  If[Length[glis] =!= 1, Return[$Failed]];
  positions = Flatten @ Position[
    glis[[1, 2]],
    _?(# =!= 0 &),
    {1},
    Heads -> False
  ];
  If[Length[positions] =!= 1, Return[$Failed]];
  First[positions]
];

dimensionalShiftParameterPolynomial[
    polynomial_,
    parameters_List,
    positions_List,
    base_FeynCalc`GLI
  ] := Module[{indices, rules, oneTerm},
  indices = base[[2]];
  rules = CoefficientRules[Expand[polynomial], parameters];
  oneTerm[powers_List -> coefficient_] := Module[{dots, factor},
    dots = ConstantArray[0, Length[indices]];
    Scan[
      Function[i, dots[[positions[[i]]]] = powers[[i]]],
      Range[Length[parameters]]
    ];
    factor = (-1)^Total[powers] Times @@ Table[
      Pochhammer[indices[[positions[[i]]]], powers[[i]]],
      {i, Length[powers]}
    ];
    coefficient factor FeynCalc`GLI[base[[1]], indices + dots]
  ];
  Total[oneTerm /@ rules]
];

dimensionalShiftRaiseOnce[
    expression_,
    topology_FeynCalc`FCTopology,
    offset_,
    dimension_
  ] := Module[{glis, rules},
  glis = DeleteDuplicates @ Cases[
    expression,
    _FeynCalc`GLI,
    {0, Infinity}
  ];
  rules = Map[
    Function[gli,
      gli -> CheckAbort[
        FeynCalc`FCLoopGLIRaiseDimension[
          gli,
          topology,
          FeynCalc`Collecting -> False,
          FeynCalc`FCE -> True
        ] /. dimension -> dimension + offset,
        $Failed
      ]
    ],
    glis
  ];
  If[! FreeQ[rules, $Failed], Return[$Failed]];
  Expand[expression /. rules]
];

dimensionalShiftRaiseToD[
    expression_,
    topology_FeynCalc`FCTopology,
    rank_Integer?NonNegative,
    dimension_,
    cutIndices_List
  ] := Module[{offsets},
  If[rank === 0, Return[dimensionalShiftPreserveCuts[expression, cutIndices]]];
  offsets = 2 Reverse[Range[0, rank - 1]];
  Fold[
    If[#1 === $Failed,
      $Failed,
      With[{raised = dimensionalShiftRaiseOnce[#1, topology, #2, dimension]},
        If[
          raised === $Failed,
          $Failed,
          dimensionalShiftPreserveCuts[raised, cutIndices]
        ]
      ]
    ] &,
    expression,
    offsets
  ]
];

dimensionalShiftMultiplyNumerator[
    numerator_,
    integral_,
    rules_List
  ] := Module[{converted},
  converted = FeynCalc`ExpandScalarProduct[numerator] /. rules;
  Expand[converted integral] /.
    FeynCalc`GLI -> FeynCalc`GLIMultiply /.
    FeynCalc`GLIMultiply -> FeynCalc`GLI
];

dimensionalShiftCutIndex[
    momentum_,
    topology_FeynCalc`FCTopology,
    loopMomenta_List
  ] := dimensionalShiftParameterPosition[
  FeynCalc`SFAD[momentum],
  topology,
  loopMomenta
];

dimensionalShiftPreserveCuts[expression_, cutIndices_List] := Module[
  {terms, projectTerm, projected},
  If[cutIndices === {}, Return[expression]];
  terms = termList[Expand[expression]];
  projectTerm[term_] := Module[{glis, indices},
    glis = Cases[term, _FeynCalc`GLI, {0, Infinity}];
    If[Length[glis] =!= 1, Return[$Failed]];
    indices = glis[[1, 2, cutIndices]];
    If[! VectorQ[indices, IntegerQ], Return[$Failed]];
    If[AllTrue[indices, Positive], term, 0]
  ];
  projected = projectTerm /@ terms;
  If[MemberQ[projected, $Failed], $Failed, Total[projected]]
];

dimensionalShiftNormalizeNumerator[expression_, loopMomenta_List] := Module[
  {expanded, dependsOnLoopQ},
  dependsOnLoopQ[object_] :=
    ! FreeQ[Unevaluated[object], Alternatives @@ loopMomenta];
  expanded = FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expression];
  expanded = expanded /. {
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      dependsOnLoopQ[{a, b}] :>
        FeynCalc`SPD[a, b] - FeynCalc`SPE[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      dependsOnLoopQ[a] :>
        FeynCalc`SPD[a] - FeynCalc`SPE[a]
  };
  FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expanded]
];

Clear[DimensionalShift];

DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_List,
    topology_FeynCalc`FCTopology
  ] := Catch[
  Module[
    {
      valid, incomplete, dimensions, dimension,
      cutRecords, cutMomenta, cutDirections, cutIndices,
      algebraicPropagators, convertedPropagators, mappedPropagators,
      baseGLIs, base, propagatorCoefficient,
      rulesToGLI,
      expanded, denominatorObjects, speObjects, badSPE,
      atoms, polynomial, coefficientRules,
      prepared, powers, matrix, parameters, positions, covariance,
      spePair, gramMoment, oneMonomial, result, unresolved, termGLICounts
    },

    If[loopMomenta === {} || loopMomenta =!= topology[[3]],
      Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    valid = Quiet @ CheckAbort[
      FeynCalc`FCLoopValidTopologyQ[topology],
      $Failed
    ];
    incomplete = Quiet @ CheckAbort[
      FeynCalc`FCLoopBasisIncompleteQ[topology],
      $Failed
    ];
    If[! TrueQ[valid] || ! TrueQ[incomplete === False],
      Message[DimensionalShift::topology, topology];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimensions = Quiet @ CheckAbort[
      FeynCalc`FCGetDimensions[FeynCalc`FCI[topology[[2]]]],
      $Failed
    ];
    If[! MatchQ[dimensions, {_Symbol}],
      Message[DimensionalShift::dimension, dimensions];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimension = First[dimensions];

    cutRecords = cutData[propagators];
    If[cutRecords === $Failed,
      Message[DimensionalShift::cut, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    cutMomenta = First /@ cutRecords;
    cutDirections = Last /@ cutRecords;

    algebraicPropagators = propagators /. {
      HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
      HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
    };
    convertedPropagators = CheckAbort[
      FeynCalc`FCLoopToGLI[algebraicPropagators, loopMomenta],
      $Failed
    ];
    If[! MatchQ[
        convertedPropagators,
        {_, _FeynCalc`FCTopology}
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    mappedPropagators = CheckAbort[
      convertedPropagators[[1]] /.
        FeynCalc`FCLoopCreateRuleGLIToGLI[
          topology,
          convertedPropagators[[2]]
        ],
      $Failed
    ];
    baseGLIs = Cases[
      mappedPropagators,
      _FeynCalc`GLI,
      {0, Infinity}
    ];
    If[mappedPropagators === $Failed || Length[baseGLIs] =!= 1,
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    base = First[baseGLIs];
    rulesToGLI = CheckAbort[
      Flatten @ FeynCalc`FCLoopCreateRulesToGLI[topology],
      $Failed
    ];
    If[rulesToGLI === $Failed,
      Message[DimensionalShift::shift, "rules to GLI"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = mappedPropagators /. base -> 1;
    If[
      ! FreeQ[propagatorCoefficient, FeynCalc`GLI] ||
      ! FreeQ[
        propagatorCoefficient,
        Alternatives @@ loopMomenta
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = FeynCalc`FCE @
      FeynCalc`FeynAmpDenominatorExplicit[
        propagatorCoefficient,
        FeynCalc`FCI -> True
      ];

    cutIndices = dimensionalShiftCutIndex[
      #,
      topology,
      loopMomenta
    ] & /@ cutMomenta;
    If[! FreeQ[cutIndices, $Failed],
      Message[DimensionalShift::cut, cutMomenta];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    expanded = dimensionalShiftNormalizeNumerator[
      propagatorCoefficient integrand,
      loopMomenta
    ];
    denominatorObjects = Cases[
      expanded,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      {0, Infinity}
    ];
    If[denominatorObjects =!= {},
      Message[DimensionalShift::numerator, denominatorObjects];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    speObjects = DeleteDuplicates @ Cases[
      expanded,
      HoldPattern[FeynCalc`SPE[__]],
      {0, Infinity}
    ];
    badSPE = Select[
      speObjects,
      ! MatchQ[
        #,
        FeynCalc`SPE[a_, b_] /;
          MemberQ[loopMomenta, a] && MemberQ[loopMomenta, b]
      ] &
    ];
    If[badSPE =!= {},
      Message[DimensionalShift::evanescent, badSPE];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    If[speObjects === {},
      result = dimensionalShiftMultiplyNumerator[
        expanded,
        base,
        rulesToGLI
      ],
      atoms = Table[Unique["spe$"], Length[speObjects]];
      polynomial = Expand[
        expanded /. Thread[speObjects -> atoms]
      ];
      If[! PolynomialQ[polynomial, atoms],
        Message[DimensionalShift::numerator, integrand];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      coefficientRules = CoefficientRules[polynomial, atoms];
      prepared = CheckAbort[
        FeynCalc`FCFeynmanPrepare[base, topology],
        $Failed
      ];
      If[! MatchQ[prepared, {_, _, _, _, _, _, _, _}],
        Message[DimensionalShift::shift, "FCFeynmanPrepare"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      powers = prepared[[3]];
      matrix = prepared[[4]];
      If[exactZeroQ[Det[matrix]],
        Message[DimensionalShift::shift, "singular loop matrix"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      parameters = powers[[All, 1]];
      positions = dimensionalShiftParameterPosition[
        #[[2]],
        topology,
        loopMomenta
      ] & /@ powers;
      If[! FreeQ[positions, $Failed],
        Message[DimensionalShift::shift, "parameter mapping"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      covariance = Adjugate[matrix]/2;
      gramMoment = dimensionalShiftGramMomentFunction[
        covariance,
        dimension - 4
      ];
      spePair[FeynCalc`SPE[a_, b_]] := {
        First @ FirstPosition[loopMomenta, a],
        First @ FirstPosition[loopMomenta, b]
      };
      oneMonomial[atomPowers_List -> coefficient_] := Module[
        {rank, bilinears, moment, shifted},
        rank = Total[atomPowers];
        bilinears = Flatten[
          MapThread[
            ConstantArray[spePair[#1], #2] &,
            {speObjects, atomPowers}
          ],
          1
        ];
        moment = gramMoment[bilinears];
        If[moment === $Failed, Return[$Failed]];
        shifted = dimensionalShiftParameterPolynomial[
          moment,
          parameters,
          positions,
          base
        ];
        shifted = dimensionalShiftRaiseToD[
          shifted,
          topology,
          rank,
          dimension,
          cutIndices
        ];
        If[shifted === $Failed, Return[$Failed]];
        dimensionalShiftMultiplyNumerator[
          coefficient,
          shifted,
          rulesToGLI
        ]
      ];
      result = Total[oneMonomial /@ coefficientRules]
    ];

    If[result === $Failed || ! FreeQ[result, $Failed],
      Message[DimensionalShift::shift, "Tarasov recurrence"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result = Expand[result];
    unresolved = DeleteDuplicates @ Cases[
      result,
      object : HoldPattern[
        (FeynCalc`SP | FeynCalc`SPD | FeynCalc`SPE)[___]
      ] /; ! FreeQ[object, Alternatives @@ loopMomenta],
      {0, Infinity}
    ];
    If[unresolved =!= {} || ! FreeQ[result, FeynCalc`SPE],
      Message[DimensionalShift::numerator, unresolved];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    If[exactZeroQ[result], Return[0]];
    termGLICounts = Length @ Cases[
      #,
      _FeynCalc`GLI,
      {0, Infinity}
    ] & /@ termList[result];
    If[! AllTrue[termGLICounts, # === 1 &],
      Message[DimensionalShift::shift, "nonlinear GLI output"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result = dimensionalShiftPreserveCuts[result, cutIndices];
    If[result === $Failed,
      Message[DimensionalShift::shift, "noninteger cut index"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result
  ],
  $dimensionalShiftFailure
];

DimensionalShift[
    integrand_,
    families : {__Association},
    loopMomenta_List
  ] := Module[
  {shiftFamily, shifted, sparse, result, masters, size},

  If[! AllTrue[
      families,
      KeyExistsQ[#, "Propagators"] &&
        MatchQ[Lookup[#, "Topology", Missing[]], _FeynCalc`FCTopology] &
    ],
    Message[DimensionalShift::families, families];
    Return[$Failed]
  ];

  shiftFamily[family_Association] := DimensionalShift[
    integrand,
    family["Propagators"],
    loopMomenta,
    family["Topology"]
  ];

  shifted = shiftFamily /@ families;
  If[MemberQ[shifted, $Failed], Return[$Failed]];
  sparse = linearNormalize[linearAdd[linearIntegralSum /@ shifted]];
  result = linearToExpression[sparse];
  masters = Keys[sparse["Terms"]];
  size = Round[ByteCount[result]/1024., 0.01];
  Print @ Grid[
    {{"Master integrals", "Size (kB)"}, {Length[masters], size}},
    Frame -> All
  ];
  result
];

DimensionalShift[integrand_, {}, {}] := Module[{size},
  size = Round[ByteCount[integrand]/1024., 0.01];
  Print @ Grid[
    {{"Master integrals", "Size (kB)"}, {0, size}},
    Frame -> All
  ];
  integrand
];

DimensionalShift[integrand_, families_List, loopMomenta_List] := (
  Message[DimensionalShift::families, families];
  $Failed
);

DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_,
    topology_FeynCalc`FCTopology
  ] := (
  Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
  $Failed
);

DimensionalShift[integrand_, propagators_, loopMomenta_, topology_] := (
  Message[DimensionalShift::topology, topology];
  $Failed
);

BuildTopologies::loops =
  "Loop momenta must be given as a list, but received `1`.";

BuildTopologies::zeroloop =
  "With no loop momenta, the propagator product must be 1 after external cuts and propagators have been separated. Received `1`.";

BuildTopologies::config =
  "SetMassZero in the setup must be a list, but received `1`.";

BuildTopologies::choice =
  "ForwardAmplitudes and ConjugateAmplitudes must identify one diagram each by a positive SelectedIndex. Received `1` and `2`.";

BuildTopologies::term =
  "Could not construct an integral topology from partial-fraction term `1`.";

BuildTopologies::partial =
  "Partial-fraction term `1` still contains linearly dependent propagators.";

BuildTopologies::rules =
  "The setup mass rules conflict with existing topology rules: `1`.";

BuildTopologies::topology =
  "The generated topology is not valid, complete and linearly independent: `1`.";

BuildTopologies::cut =
  "Could not map every cut propagator into the generated topology for term `1`.";

$buildTopologiesFailure = "FeynFacetBuildTopologiesFailure";

Clear[topologyAmplitudeTag, BuildTopologies];

topologyAmplitudeTag[amplitudes_Association] := Which[
  KeyExistsQ[amplitudes, "SelectedIndex"] &&
    IntegerQ[amplitudes["SelectedIndex"]] &&
    amplitudes["SelectedIndex"] >= 1,
    ToString[amplitudes["SelectedIndex"]],
  True,
    $Failed
];

BuildTopologies[
    partialFractions_,
    loopMomenta_List,
    config_Association
  ] := Catch[
  Module[{
    massless, forwardAmplitudes, conjugateAmplitudes,
    forwardTag, conjugateTag,
    terms, buildOne, families
  },

    If[loopMomenta === {},
      If[FeynCalc`FCE[partialFractions] =!= 1,
        Message[BuildTopologies::zeroloop, partialFractions];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      Print @ Grid[
        {
          {"Topology", "External momenta", "Cut indices", "Cut directions"},
          {"None", {}, {}, {}}
        },
        Frame -> All
      ];
      Return[{}]
    ];
    massless = Lookup[config, "SetMassZero", {}];
    If[! ListQ[massless],
      Message[BuildTopologies::config, massless];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    forwardAmplitudes = Lookup[config, "ForwardAmplitudes", <||>];
    conjugateAmplitudes = Lookup[config, "ConjugateAmplitudes", <||>];
    forwardTag = topologyAmplitudeTag[forwardAmplitudes];
    conjugateTag = topologyAmplitudeTag[conjugateAmplitudes];
    If[forwardTag === $Failed || conjugateTag === $Failed,
      Message[
        BuildTopologies::choice,
        forwardAmplitudes,
        conjugateAmplitudes
      ];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    terms = termList[partialFractions];

    buildOne[term_, index_Integer] := Module[
      {
        cutRecords, cutMomenta, cutDirections, algebraic, converted,
        topology, topologyID, external, massRules, conflicts, completed,
        checks, cutIndices
      },

      cutRecords = cutData[term];
      If[cutRecords === $Failed,
        Throw[$Failed, $buildTopologiesFailure]
      ];
      cutMomenta = First /@ cutRecords;
      cutDirections = Last /@ cutRecords;
      algebraic = term /. {
        HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
        HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
      };
      converted = Quiet @ CheckAbort[
        FeynCalc`FCLoopToGLI[algebraic, loopMomenta],
        $Failed
      ];
      If[! MatchQ[converted, {_, _FeynCalc`FCTopology}],
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topology = converted[[2]];
      If[
        topology[[3]] =!= loopMomenta ||
        TrueQ[Quiet @ FeynCalc`FCLoopBasisOverdeterminedQ[topology]],
        Message[BuildTopologies::partial, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topologyID = ToExpression[
        "Global`TopologyF" <> forwardTag <>
          "C" <> conjugateTag <>
          "N" <> ToString[index]
      ];
      external = topology[[4]];
      massRules = (FeynCalc`SPD[#] -> 0 &) /@
        Select[external, MemberQ[massless, #] &];
      conflicts = Select[
        topology[[5]],
        Function[rule,
          AnyTrue[
            massRules,
            SameQ[First[rule], First[#]] &&
              ! TrueQ[PossibleZeroQ[Last[rule] - Last[#]]] &
          ]
        ]
      ];
      If[conflicts =!= {},
        Message[BuildTopologies::rules, conflicts];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      topology = FeynCalc`FCTopology[
        topologyID,
        topology[[2]],
        loopMomenta,
        external,
        DeleteDuplicates[Join[topology[[5]], massRules]],
        topology[[6]]
      ];
      completed = Quiet @ CheckAbort[
        FeynCalc`FCLoopBasisFindCompletion[
          topology,
          FeynCalc`Names -> (# &)
        ],
        $Failed
      ];
      If[! MatchQ[completed, _FeynCalc`FCTopology],
        Message[BuildTopologies::topology, topology];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      checks = Quiet @ CheckAbort[
        {
          FeynCalc`FCLoopValidTopologyQ[completed],
          ! FeynCalc`FCLoopBasisIncompleteQ[completed],
          ! FeynCalc`FCLoopBasisOverdeterminedQ[completed]
        },
        $Failed
      ];
      If[checks =!= {True, True, True},
        Message[BuildTopologies::topology, completed];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      cutIndices = dimensionalShiftParameterPosition[
        FeynCalc`SFAD[#],
        completed,
        loopMomenta
      ] & /@ cutMomenta;
      If[
        ! VectorQ[cutIndices, IntegerQ] ||
        Length[DeleteDuplicates[cutIndices]] =!= Length[cutIndices],
        Message[BuildTopologies::cut, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      Association[
        "Propagators" -> term,
        "Topology" -> completed,
        "CutMomenta" -> cutMomenta,
        "CutIndices" -> cutIndices,
        "CutDirections" -> cutDirections
      ]
    ];

    families = MapIndexed[buildOne[#1, First[#2]] &, terms];
    Print @ Grid[
      Prepend[
        {
          #["Topology"][[1]],
          #["Topology"][[4]],
          #["CutIndices"],
          #["CutDirections"]
        } & /@ families,
        {"Topology", "External momenta", "Cut indices", "Cut directions"}
      ],
      Frame -> All
    ];
    families
  ],
  $buildTopologiesFailure
];

BuildTopologies[partialFractions_, loopMomenta_, config_] := (
  If[! MatchQ[loopMomenta, {__}],
    Message[BuildTopologies::loops, loopMomenta],
    Message[BuildTopologies::config, config]
  ];
  $Failed
);

TopologyEquivalence::input =
  "Expected a list of cut-aware topology records, but received `1`.";

TopologyEquivalence::record =
  "Topology record `1` is missing or has inconsistent topology, cut or AMFlow metadata.";

TopologyEquivalence::names =
  "Topology names must be unique, but received `1`.";

TopologyEquivalence::mapping =
  "FeynCalc could not determine topology mappings for `1`.";

TopologyEquivalence::coverage =
  "FeynCalc returned incomplete or inconsistent mapping coverage for `1`.";

$topologyEquivalenceFailure = "FeynFacetTopologyEquivalenceFailure";

Clear[
  exactZeroQ,
  exactRationalQ,
  topologyRecordQ,
  topologyPropagatorInfo,
  topologyNormalizeEtaSigns,
  topologyPropagatorCore,
  safeTopologyRecordQ,
  parseTopologyMapping,
  topologyGLIIndexMap,
  topologyVerifiedGLIRule,
  topologyMomentumSign,
  topologyCutMapping,
  topologyAffineMapping,
  topologyPropagatorMapping,
  topologyPhysicalSignature,
  topologyPrescriptionMapping,
  topologyPhysicalMapping,
  TopologyEquivalence
];

exactZeroQ[expr_] := TrueQ[
  Quiet[Cancel[Together[Expand[expr]]]] === 0
];

exactRationalQ[value_] := MatchQ[value, _Integer | _Rational];

topologyPhysicalSignature[data_Association] := Module[
  {physical = data["Physical"], factors},
  factors = If[physical["Role"] === "Cut",
    KeyDrop[#, "EnergyDirection"] & /@ physical["Factors"],
    physical["Factors"]
  ];
  <|
    "Role" -> physical["Role"],
    "Factors" -> SortBy[
      factors,
      ToString[InputForm[#]] &
    ]
  |>
];

topologyPropagatorInfo[propagator_] := Module[
  {objects, denominator, quadratic, linear, eta, type, power},
  objects = Cases[
    FeynCalc`FCI[propagator],
    denominator : (
      FeynCalc`PropagatorDenominator |
      FeynCalc`StandardPropagatorDenominator
    )[___] :> denominator,
    Infinity
  ];
  If[Length[objects] =!= 1, Return[$Failed]];
  denominator = First[objects];
  {type, power} = If[Head[denominator] === FeynCalc`PropagatorDenominator,
    {"QuadraticLorentzian", 1},
    quadratic = ! exactZeroQ[denominator[[1]]];
    linear = ! exactZeroQ[denominator[[2]]];
    {
      Which[
        quadratic && ! linear, "QuadraticLorentzian",
        ! quadratic && linear, "LinearLorentzian",
        True, $Failed
      ],
      If[MatchQ[denominator[[4]], {_, _}], denominator[[4, 1]], $Failed]
    }
  ];
  eta = Quiet @ Check[
    FeynCalc`FCLoopGetEtaSigns[
      FeynCalc`FCI[propagator],
      FeynCalc`FCI -> True
    ],
    $Failed
  ];
  If[
    MemberQ[{type, power}, $Failed] || ! MatchQ[eta, {_}],
    $Failed,
    <|
      "Momentum" -> propagatorMomentum[denominator],
      "Type" -> type,
      "Power" -> power,
      "EtaSign" -> First[eta]
    |>
  ]
];

topologyNormalizeEtaSigns[topology_FeynCalc`FCTopology] := ReplacePart[
  topology,
  2 -> Map[
    Function[propagator,
      FeynCalc`FCI[propagator] /. HoldPattern[
        FeynCalc`StandardPropagatorDenominator[
          momentum_, scalarProduct_, mass_, {power_, _}
        ]
      ] :> FeynCalc`StandardPropagatorDenominator[
        momentum, scalarProduct, mass, {power, 1}
      ]
    ],
    topology[[2]]
  ]
];

topologyPropagatorCore[propagator_, shift_List, kinematics_List] :=
  Module[{mapped, explicit, core},
    mapped = FeynCalc`FCReplaceMomenta[
      FeynCalc`FCI[propagator],
      shift
    ];
    explicit = Quiet @ Check[
      FeynCalc`FeynAmpDenominatorExplicit[
        mapped,
        FeynCalc`FCI -> True
      ],
      $Failed
    ];
    If[explicit === $Failed || exactZeroQ[explicit], Return[$Failed]];
    core = Quiet @ Check[
      Cancel[Together[(1/explicit) /. kinematics]],
      $Failed
    ];
    If[
      core === $Failed ||
        ! FreeQ[
          core,
          FeynCalc`FeynAmpDenominator |
            FeynCalc`PropagatorDenominator |
            FeynCalc`StandardPropagatorDenominator
        ],
      $Failed,
      core
    ]
];

topologyRecordQ[record_Association] := Module[
  {
    required, topology, cutMomenta, cutIndices, cutDirections,
    amflow, cutMask, propagatorInfo, propagatorMomenta, propagatorTypes,
    propagatorPowers, propagatorEtaSigns, incomplete, overdetermined,
    normalizedTopology, propagatorData, physicalData, validPhysicalQ
  },

  required = {
    "Topology", "CutMomenta", "CutIndices", "CutDirections",
    "PropagatorData", "AMFlowInfo"
  };
  If[! ContainsAll[Keys[record], required], Return[False]];

  topology = record["Topology"];
  cutMomenta = record["CutMomenta"];
  cutIndices = record["CutIndices"];
  cutDirections = record["CutDirections"];
  propagatorData = record["PropagatorData"];
  amflow = record["AMFlowInfo"];
  If[
    ! MatchQ[topology, _FeynCalc`FCTopology] ||
      ! AssociationQ[amflow] ||
      ! ContainsAll[
        Keys[amflow],
        {"Family", "Loop", "Prescription", "Cut"}
      ],
    Return[False]
  ];

  cutMask = amflow["Cut"];
  propagatorInfo = topologyPropagatorInfo /@ topology[[2]];
  If[MemberQ[propagatorInfo, $Failed], Return[False]];
  propagatorMomenta = Lookup[propagatorInfo, "Momentum"];
  propagatorTypes = Lookup[propagatorInfo, "Type"];
  propagatorPowers = Lookup[propagatorInfo, "Power"];
  propagatorEtaSigns = Lookup[propagatorInfo, "EtaSign"];
  If[
    ! ListQ[propagatorData] ||
      Length[propagatorData] =!= Length[propagatorInfo] ||
      ! AllTrue[propagatorData, AssociationQ],
    Return[False]
  ];
  If[! And @@ MapThread[
      SameQ[Lookup[#1, "Algebraic", Missing[]], #2] &,
      {propagatorData, propagatorInfo}
    ],
    Return[False]
  ];
  physicalData = Lookup[propagatorData, "Physical", Missing[]];
  validPhysicalQ[physical_, index_] := Which[
    ! AssociationQ[physical], False,
    MemberQ[cutIndices, index],
      physical["Role"] === "Cut" &&
        MatchQ[physical["Factors"], {_Association}] &&
        physical["Factors"][[1, "CausalSide"]] === 0 &&
        physical["Factors"][[1, "EnergyDirection"]] ===
          cutDirections[[First @ FirstPosition[cutIndices, index]]],
    physical["Role"] === "Auxiliary",
      physical["Factors"] === {},
    physical["Role"] === "Uncut",
      MatchQ[physical["Factors"], {__Association}] &&
        AllTrue[
          physical["Factors"],
          MemberQ[{"Amplitude", "Conjugate"}, #1["Role"]] &&
            MemberQ[{1, -1}, #1["CausalSide"]] &&
            #1["CausalSide"] === #1["PhysicalEtaSign"] &
        ],
    True, False
  ];
  normalizedTopology = topologyNormalizeEtaSigns[topology];
  incomplete = Quiet @ CheckAbort[Check[
    FeynCalc`FCLoopBasisIncompleteQ[normalizedTopology],
    $Failed
  ], $Failed];
  overdetermined = Quiet @ CheckAbort[Check[
    FeynCalc`FCLoopBasisOverdeterminedQ[normalizedTopology],
    $Failed
  ], $Failed];
  And[
    TrueQ @ Quiet @ CheckAbort[
      Check[FeynCalc`FCLoopValidTopologyQ[normalizedTopology], False],
      False
    ],
    incomplete === False,
    overdetermined === False,
    topology[[1]] === amflow["Family"],
    topology[[3]] === amflow["Loop"],
    Lookup[amflow, "PhysicalCausalStatus", Missing[]] === "Verified",
    Length[amflow["Prescription"]] === Length[topology[[3]]],
    AllTrue[amflow["Prescription"], MemberQ[{0, 1, -1}, #] &],
    Length[cutMomenta] === Length[cutIndices] === Length[cutDirections],
    DuplicateFreeQ[cutIndices],
    AllTrue[
      cutIndices,
      IntegerQ[#] && 1 <= # <= Length[topology[[2]]] &
    ],
    AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    AllTrue[cutMomenta, ! exactZeroQ[#] &],
    AllTrue[propagatorPowers, SameQ[#, 1] &],
    And @@ MapThread[
      MemberQ[{1, -1}, topologyMomentumSign[#1, #2]] &,
      {cutMomenta, propagatorMomenta[[cutIndices]]}
    ],
    AllTrue[
      propagatorTypes[[cutIndices]],
      SameQ[#, "QuadraticLorentzian"] &
    ],
    ListQ[cutMask] && Length[cutMask] === Length[topology[[2]]],
    Sort[Flatten @ Position[cutMask, 1]] === Sort[cutIndices],
    AllTrue[cutMask, MemberQ[{0, 1}, #] &],
    And @@ MapIndexed[validPhysicalQ[#1, First[#2]] &, physicalData]
  ]
];

topologyRecordQ[_] := False;

safeTopologyRecordQ[record_] := TrueQ @ Quiet @ CheckAbort[
  Check[topologyRecordQ[record], False],
  False
];

parseTopologyMapping[
    {sourceTopology_FeynCalc`FCTopology, shift_List, gliRule_},
    recordByName_Association
  ] := Module[
  {indices, inputGLI, outputGLI, sourceName, targetName},

  If[
    ! MemberQ[{Rule, RuleDelayed}, Head[gliRule]] ||
      ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[Failure[
      "MalformedMapping",
      <|"Mapping" -> {sourceTopology, shift, gliRule}|>
    ]]
  ];
  sourceName = sourceTopology[[1]];
  If[! KeyExistsQ[recordByName, sourceName],
    Return[Failure[
      "UnknownMappingSource",
      <|"Source" -> sourceName|>
    ]]
  ];
  indices = Table[
    Unique["topologyIndex$"],
    {Length[sourceTopology[[2]]]}
  ];
  inputGLI = FeynCalc`GLI[sourceName, indices];
  outputGLI = Replace[inputGLI, gliRule, {0}];
  If[
    ! MatchQ[outputGLI, _FeynCalc`GLI] || outputGLI === inputGLI,
    Return[Failure[
      "InapplicableGLIRule",
      <|"Source" -> sourceName, "Rule" -> gliRule|>
    ]]
  ];
  targetName = outputGLI[[1]];
  If[! KeyExistsQ[recordByName, targetName],
    Return[Failure[
      "UnknownMappingTarget",
      <|"Source" -> sourceName, "Target" -> targetName|>
    ]]
  ];
  <|
    "SourceTopology" -> sourceTopology,
    "Source" -> sourceName,
    "Target" -> targetName,
    "LoopMomentumRules" -> shift,
    "GLIRule" -> gliRule,
    "ProbeGLI" -> inputGLI,
    "MappedProbeGLI" -> outputGLI,
    "ProbeIndices" -> indices,
    "MappedProbe" -> outputGLI
  |>
];

parseTopologyMapping[other_, _Association] := Failure[
  "MalformedMapping",
  <|"Mapping" -> other|>
];

topologyGLIIndexMap[parsed_Association, source_, target_] := Module[
  {indices, mappedIndices, positions},

  indices = parsed["ProbeIndices"];
  mappedIndices = parsed["MappedProbe"][[2]];
  If[
    Length[source[[2]]] =!= Length[target[[2]]] ||
      Length[mappedIndices] =!= Length[indices],
    Return[$Failed]
  ];
  If[! VectorQ[mappedIndices, MemberQ[indices, #] &], Return[$Failed]];
  positions = Position[
      mappedIndices,
      #,
      {1},
      Heads -> False
    ] & /@ indices;
  If[
    ! AllTrue[positions, MatchQ[#, {{_Integer}}] &],
    Return[$Failed]
  ];
  positions[[All, 1, 1]]
];

topologyVerifiedGLIRule[sourceName_, targetName_, indexMap_List] := Module[
  {count, variables, left, right},

  count = Length[indexMap];
  If[Sort[indexMap] =!= Range[count], Return[$Failed]];
  variables = Table[Unique["gliIndex$"], {count}];
  left = FeynCalc`GLI[
    sourceName,
    Pattern[#, Blank[]] & /@ variables
  ];
  right = FeynCalc`GLI[
    targetName,
    variables[[Ordering[indexMap]]]
  ];
  With[
    {verifiedLeft = left, verifiedRight = right},
    HoldPattern[verifiedLeft] :> verifiedRight
  ]
];

topologyMomentumSign[mapped_, target_] := Module[{same, opposite},
  same = exactZeroQ[mapped - target];
  opposite = exactZeroQ[mapped + target];
  Which[
    same && ! opposite, 1,
    opposite && ! same, -1,
    True, 0
  ]
];

topologyCutMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceIndices, targetIndices, sourceMomenta, targetMomenta,
    sourceDirections, targetDirections, mappedIndices, targetPosition,
    sign, checks, failure
  },

  sourceIndices = source["CutIndices"];
  targetIndices = target["CutIndices"];
  sourceMomenta = source["CutMomenta"];
  targetMomenta = target["CutMomenta"];
  sourceDirections = source["CutDirections"];
  targetDirections = target["CutDirections"];
  mappedIndices = indexMap[[sourceIndices]];
  If[Sort[mappedIndices] =!= Sort[targetIndices],
    Return[{False, "cut indices do not map one-to-one"}]
  ];

  checks = Table[
    targetPosition = First @ FirstPosition[
      targetIndices,
      mappedIndices[[index]]
    ];
    sign = topologyMomentumSign[
      Expand[sourceMomenta[[index]] /. shift],
      targetMomenta[[targetPosition]]
    ];
    Which[
      sign === 0,
        {False, "mapped cut momentum is not the target cut momentum"},
      sign sourceDirections[[index]] =!= targetDirections[[targetPosition]],
        {False, "cut energy direction is reversed"},
      True,
        {True, Null}
    ],
    {index, Length[sourceIndices]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, mappedIndices}
];

topologyAffineMapping[source_, target_, shift_List] := Module[
  {
    sourceTopology, targetTopology, sourceLoops, targetLoops,
    sourceExternal, targetExternal, external, mappedLoops, matrix,
    translation, translationMatrix, remainder, determinant, coefficients,
    leftSides
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourceLoops = sourceTopology[[3]];
  targetLoops = targetTopology[[3]];
  sourceExternal = sourceTopology[[4]];
  targetExternal = targetTopology[[4]];
  If[Length[sourceLoops] =!= Length[targetLoops],
    Return[{False, "loop counts differ"}]
  ];
  If[
    Sort[sourceExternal] =!= Sort[targetExternal] ||
      Sort[sourceTopology[[5]]] =!= Sort[targetTopology[[5]]],
    Return[{False, "external momentum bases or kinematic rules differ"}]
  ];
  If[
    ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[{False, "loop mapping contains malformed rules"}]
  ];
  leftSides = First /@ shift;
  If[
    ! DuplicateFreeQ[leftSides] ||
      ! AllTrue[leftSides, MemberQ[sourceLoops, #] &],
    Return[{False, "mapping contains non-loop replacement rules"}]
  ];

  mappedLoops = Expand[sourceLoops /. shift];
  matrix = Table[
    Coefficient[mappedLoops[[i]], targetLoops[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[targetLoops]}
  ];
  external = Sort[sourceExternal];
  translation = Expand[mappedLoops - matrix.targetLoops];
  translationMatrix = Table[
    Coefficient[translation[[i]], external[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[external]}
  ];
  remainder = Expand[translation - translationMatrix.external];
  coefficients = Flatten[{matrix, translationMatrix}];
  If[! AllTrue[coefficients, exactRationalQ],
    Return[{False, "mapping coefficients are not exact real rationals"}]
  ];
  If[! And @@ (exactZeroQ /@ remainder),
    Return[{False, "loop mapping is not affine-linear in declared momenta"}]
  ];
  determinant = Cancel[Det[matrix]];
  If[
    ! exactZeroQ[determinant - 1] &&
      ! exactZeroQ[determinant + 1],
    Return[{False, "loop mapping does not have unit Jacobian"}]
  ];

  {True, <|
    "LoopMatrix" -> matrix,
    "TranslationMatrix" -> translationMatrix,
    "ExternalBasis" -> external,
    "Determinant" -> determinant
  |>}
];

topologyPropagatorMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceTopology, targetTopology, sourcePropagators, targetPropagators,
    sourceInfo, targetInfo, sourceTypes, targetTypes, sourcePowers,
    targetPowers, sourceEta, targetEta, sourcePhysical, targetPhysical,
    sourceCore, targetCore, checks, failure
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourcePropagators = sourceTopology[[2]];
  targetPropagators = targetTopology[[2]];
  sourceInfo = Lookup[source["PropagatorData"], "Algebraic"];
  targetInfo = Lookup[target["PropagatorData"], "Algebraic"];
  If[MemberQ[Join[sourceInfo, targetInfo], $Failed],
    Return[{False, "unsupported propagator representation"}]
  ];
  sourceTypes = Lookup[sourceInfo, "Type"];
  targetTypes = Lookup[targetInfo, "Type"];
  sourcePowers = Lookup[sourceInfo, "Power"];
  targetPowers = Lookup[targetInfo, "Power"];
  sourceEta = Lookup[sourceInfo, "EtaSign"];
  targetEta = Lookup[targetInfo, "EtaSign"];
  sourcePhysical = topologyPhysicalSignature /@ source["PropagatorData"];
  targetPhysical = topologyPhysicalSignature /@ target["PropagatorData"];

  checks = Table[
    sourceCore = topologyPropagatorCore[
      sourcePropagators[[index]],
      shift,
      sourceTopology[[5]]
    ];
    targetCore = topologyPropagatorCore[
      targetPropagators[[indexMap[[index]]]],
      {},
      targetTopology[[5]]
    ];
    Which[
      sourceTypes[[index]] =!= targetTypes[[indexMap[[index]]]],
        {False, "propagator types do not match"},
      sourceEta[[index]] =!= targetEta[[indexMap[[index]]]],
        {False, "stored propagator eta signs do not match"},
      sourcePowers[[index]] =!= targetPowers[[indexMap[[index]]]],
        {False, "propagator powers do not match"},
      sourcePhysical[[index]] =!= targetPhysical[[indexMap[[index]]]],
        {False, "physical propagator provenance does not match"},
      sourceCore === $Failed || targetCore === $Failed,
        {False, "could not extract a propagator polynomial"},
      ! exactZeroQ[sourceCore - targetCore],
        {False, "mapped propagator polynomials do not match"},
      True,
        {True, Null}
    ],
    {index, Length[sourcePropagators]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, "Verified"}
];

topologyPrescriptionMapping[source_, target_, matrix_] := Module[
  {
    sourcePrescription, targetPrescription, targetPositions,
    checks, failure
  },

  sourcePrescription = source["AMFlowInfo"]["Prescription"];
  targetPrescription = target["AMFlowInfo"]["Prescription"];

  checks = Table[
    targetPositions = Flatten @ Position[
      matrix[[i]],
      coefficient_ /; coefficient =!= 0,
      {1},
      Heads -> False
    ];
    If[
      targetPositions === {} ||
        ! AllTrue[
          targetPrescription[[targetPositions]],
          SameQ[#, sourcePrescription[[i]]] &
        ],
      {False, "AMFlow loop-routing labels are mixed"},
      {True, Null}
    ],
    {i, Length[sourcePrescription]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, True}
];

topologyPhysicalMapping[source_, target_, mapping_Association] := Module[
  {
    shift, indexMap, affineCheck, propagatorCheck, cutCheck,
    prescriptionCheck, verifiedGLIRule
  },

  shift = mapping["LoopMomentumRules"];
  indexMap = topologyGLIIndexMap[
    mapping,
    source["Topology"],
    target["Topology"]
  ];
  If[indexMap === $Failed,
    Return[{False, "GLI rule is not a strict propagator permutation"}]
  ];
  affineCheck = topologyAffineMapping[source, target, shift];
  If[! TrueQ[First[affineCheck]], Return[affineCheck]];
  propagatorCheck = topologyPropagatorMapping[
    source,
    target,
    shift,
    indexMap
  ];
  If[! TrueQ[First[propagatorCheck]], Return[propagatorCheck]];
  cutCheck = topologyCutMapping[source, target, shift, indexMap];
  If[! TrueQ[First[cutCheck]], Return[cutCheck]];
  prescriptionCheck = topologyPrescriptionMapping[
    source,
    target,
    affineCheck[[2, "LoopMatrix"]]
  ];
  If[! TrueQ[First[prescriptionCheck]], Return[prescriptionCheck]];
  verifiedGLIRule = topologyVerifiedGLIRule[
    source["Topology"][[1]],
    target["Topology"][[1]],
    indexMap
  ];
  If[verifiedGLIRule === $Failed,
    Return[{False, "could not construct the verified GLI rule"}]
  ];
  If[
    ! SameQ[
      Replace[mapping["ProbeGLI"], verifiedGLIRule, {0}],
      mapping["MappedProbeGLI"]
    ],
    Return[{False, "verified GLI rule disagrees with candidate mapping"}]
  ];

  {
    True,
    <|
      "Source" -> source["Topology"][[1]],
      "Target" -> target["Topology"][[1]],
      "LoopMomentumRules" -> shift,
      "LoopMomentumMatrix" -> affineCheck[[2, "LoopMatrix"]],
      "LoopTranslationMatrix" ->
        affineCheck[[2, "TranslationMatrix"]],
      "JacobianDeterminant" -> affineCheck[[2, "Determinant"]],
      "PropagatorIndexMap" -> indexMap,
      "CutIndexMap" -> Last[cutCheck],
      "CausalStatus" -> Last[propagatorCheck],
      "AMFlowRoutingCompatible" -> True,
      "GLIRule" -> verifiedGLIRule,
      "FeynCalcCandidateGLIRule" -> mapping["GLIRule"]
    |>
  }
];

TopologyEquivalence[topologies_List] := Catch[
  Module[
    {
      names, recordByName, classes = {}, mappings = {},
      rejectedCandidates = {}, partition, classRows, representatives,
      causalStatus, searchStatus
    },

    If[! AllTrue[topologies, safeTopologyRecordQ],
      Message[
        TopologyEquivalence::record,
        FirstCase[
          topologies,
          record_ /; ! safeTopologyRecordQ[record],
          Missing["InvalidRecord"]
        ]
      ];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    If[topologies === {},
      Print @ Grid[
        {{"Representative", "Count", "Members"}, {"None", 0, {}}},
        Frame -> All
      ];
      Return[<|
        "Scope" -> "CutAwareIBP",
        "PhysicalCausalStatus" -> "NoTopologies",
        "SearchStatus" -> "Complete",
        "Representatives" -> {},
        "Classes" -> {},
        "Mappings" -> {},
        "GLIRules" -> {},
        "RejectedCandidateMappings" -> {}
      |>]
    ];

    names = #["Topology"][[1]] & /@ topologies;
    If[! DuplicateFreeQ[names],
      Message[TopologyEquivalence::names, names];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    recordByName = AssociationThread[names, topologies];

    partition[records_List] := Module[
      {
        result, rawMappings, rawRepresentatives, parsedMappings,
        representativeNames, mappingSources, mappingTargets,
        currentNames, targetName, sourceMaps, representative, members,
        incompatible, check
      },

      If[records === {}, Return[Null]];
      result = Quiet @ CheckAbort[
        FeynCalc`FCLoopFindTopologyMappings[
          topologyNormalizeEtaSigns /@ Lookup[records, "Topology"],
          FeynCalc`Momentum -> {},
          FeynCalc`SubtopologyMarker -> False,
          FeynCalc`FCVerbose -> -1
        ],
        $Failed
      ];
      If[
        ! MatchQ[result, {{___List}, {___FeynCalc`FCTopology}}],
        Message[
          TopologyEquivalence::mapping,
          Lookup[records, "Topology"][[All, 1]]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      rawMappings = result[[1]];
      rawRepresentatives = result[[2]];
      parsedMappings = parseTopologyMapping[#, recordByName] & /@
        rawMappings;
      If[AnyTrue[parsedMappings, FailureQ],
        Message[
          TopologyEquivalence::mapping,
          FirstCase[parsedMappings, _Failure]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      currentNames = Lookup[records, "Topology"][[All, 1]];
      representativeNames = rawRepresentatives[[All, 1]];
      mappingSources = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Source"]
      ];
      mappingTargets = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Target"]
      ];
      If[
        ! DuplicateFreeQ[mappingSources] ||
          Sort[Join[mappingSources, representativeNames]] =!=
            Sort[currentNames] ||
          Complement[mappingTargets, representativeNames] =!= {},
        Message[TopologyEquivalence::coverage, currentNames];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];

      Do[
        targetName = rawRepresentatives[[index, 1]];
        representative = recordByName[targetName];
        sourceMaps = Select[
          parsedMappings,
          #["Target"] === targetName &
        ];
        members = {targetName};
        incompatible = {};
        Do[
          check = topologyPhysicalMapping[
            recordByName[mapping["Source"]],
            representative,
            mapping
          ];
          If[TrueQ[First[check]],
            AppendTo[members, mapping["Source"]];
            AppendTo[mappings, Last[check]],
            AppendTo[incompatible, recordByName[mapping["Source"]]];
            AppendTo[rejectedCandidates, <|
              "Source" -> mapping["Source"],
              "Candidate" -> targetName,
              "Reason" -> Last[check]
            |>]
          ],
          {mapping, sourceMaps}
        ];
        AppendTo[classes, <|
          "Representative" -> targetName,
          "Members" -> members,
          "PhysicalCausalStatus" -> "Verified",
          "SearchStatus" -> If[
            incompatible === {},
            "FeynCalcWitnessesAccepted",
            "ConservativelySeparated"
          ]
        |>];
        partition[incompatible],
        {index, Length[rawRepresentatives]}
      ]
    ];

    partition[topologies];
    classRows = {
      #["Representative"],
      Length[#["Members"]],
      #["Members"]
    } & /@ classes;
    Print @ Grid[
      Prepend[classRows, {"Representative", "Count", "Members"}],
      Frame -> All
    ];
    representatives = recordByName /@ Lookup[classes, "Representative"];
    causalStatus = "Verified";
    searchStatus = If[
      rejectedCandidates === {},
      "AllFeynCalcCandidatesAccepted",
      "ConservativelySeparated"
    ];

    <|
      "Scope" -> "CutAwareIBP",
      "PhysicalCausalStatus" -> causalStatus,
      "SearchStatus" -> searchStatus,
      "Representatives" -> representatives,
      "Classes" -> classes,
      "Mappings" -> mappings,
      "GLIRules" -> Lookup[mappings, "GLIRule"],
      "RejectedCandidateMappings" -> rejectedCandidates
    |>
  ],
  $topologyEquivalenceFailure
];

TopologyEquivalence[topologies_] := (
  Message[TopologyEquivalence::input, topologies];
  $Failed
);

$collinearFailure = "FeynFacetCollinearFailure";

requiredKeys = {
  "ForwardAmplitudes",
  "ConjugateAmplitudes",
  "Partons",
  "PartonMomentum",
  "PhaseSpaceMomentum",
  "PartonIntegrated",
  "MomentumFraction",
  "HadronMomentum",
  "HadronLongDirection",
  "HadronDualDirection",
  "HadronLongSpin",
  "HadronTransSpin"
};

feynArtsKeys = {
  "Model",
  "InsertionLevel",
  "ExcludeTopologies",
  "ExcludeParticles"
};

optionalKeys = Join[
  {
    "CardName",
    "SourceNotebook",
    "DiagramsBySide",
    "SetDistributionZero",
    "SetMassZero"
  },
  feynArtsKeys
];

legInputKeys = {
  "Partons",
  "PartonMomentum",
  "MomentumFraction",
  "HadronMomentum",
  "HadronLongDirection",
  "HadronDualDirection",
  "HadronLongSpin",
  "HadronTransSpin"
};

legFields = {
  "Parton",
  "Momentum",
  "Fraction",
  "HadronMomentum",
  "LongDirection",
  "DualDirection",
  "LongSpin",
  "TransSpin"
};

sideNames = {"Amplitude", "Conjugate"};

amplitudeNames = <|
  "Amplitude" -> "ForwardAmplitudes",
  "Conjugate" -> "ConjugateAmplitudes"
|>;

CollinearFactorize::config =
  "Expected a configuration Association, but received `1`.";

CollinearFactorize::missing =
  "Configuration is missing required keys `1`.";

CollinearFactorize::unknown =
  "Configuration contains unknown keys `1`.";

CollinearFactorize::invalid =
  "Invalid value for `1`: `2`. `3`";

CollinearFactorize::basis =
  "No global basis is installed. Run BuildGlobalBasis[{nb,n,xhat,yhat}] first.";

CollinearFactorize::polarization =
  "External boson polarizations remain after summing momenta `1`: `2`.";

CollinearFactorize::propagators =
  "Amplitude `1` is not a product of a numerator and literal FAD factors. Remaining denominator objects: `2`.";

CollinearFactorize::algebra =
  "Calc left unresolved algebraic objects: `1`.";

CollinearFactorize::spinprojector =
  "External spin projector tagging failed. Missing before the spin sum: `1`; remaining after the density replacement: `2`.";

Clear[fail];

fail[field_, value_, reason_] := (
  Message[CollinearFactorize::invalid, field, value, reason];
  Throw[$Failed, $collinearFailure]
);

Clear[normalizeSides];

normalizeSides[name_, value_, counts_] := Module[{sides},
  If[Head[value] =!= Rule,
    fail[name, value, "Expected incoming -> outgoing."]
  ];
  sides = List @@ value;
  If[! AllTrue[sides, ListQ],
    fail[name, value, "Both sides must be lists."]
  ];
  If[Length /@ sides =!= counts,
    fail[
      name,
      value,
      "Side lengths must match Partons: " <> ToString[counts, InputForm] <> "."
    ]
  ];
  sides
];

Clear[normalizeProcess, inferFractionAssumptions];

inferFractionAssumptions[momentumFractions_] := Module[{fractions},
  fractions = DeleteDuplicates @ Cases[
    momentumFractions,
    fraction_Symbol /; fraction =!= NA,
    Infinity
  ];
  And @@ ((0 < # < 1) & /@ fractions)
];

SimplifyAssum[expr_, config_Association] := Simplify[
  expr,
  Assumptions -> inferFractionAssumptions[
    Lookup[config, "MomentumFraction", {}]
  ]
];

FullSimplifyAssum[expr_, config_Association] := FullSimplify[
  expr,
  Assumptions -> inferFractionAssumptions[
    Lookup[config, "MomentumFraction", {}]
  ]
];

Clear[normalizeAmplitudeSides, prepareProcess];

normalizeAmplitudeSides[config_Association, externalMomenta_List] := Module[
  {setups, sides, loops},
  setups = AssociationThread[
    sideNames,
    Lookup[config, {"ForwardAmplitudes", "ConjugateAmplitudes"}]
  ];
  sides = AssociationMap[
    normalizeAmplitudeSelection[
      All,
      setups[#],
      amplitudeNames[#],
      True
    ] &,
    sideNames
  ];
  If[MemberQ[Values[sides], $Failed],
    fail[
      "ForwardAmplitudes/ConjugateAmplitudes",
      setups,
      "Both perturbative sides require a selected valid diagram."
    ]
  ];
  loops = Flatten[Lookup[Values[sides], "LoopMomenta"]];
  If[! DuplicateFreeQ[loops] || Intersection[loops, externalMomenta] =!= {},
    fail[
      "ForwardAmplitudes/ConjugateAmplitudes",
      setups,
      "Virtual-loop momenta must be unique and distinct from external momenta."
    ]
  ];
  <|"Sides" -> sides, "VirtualLoopMomenta" -> loops|>
];

prepareProcess[process_Association, diagrams_Association] := Module[{sides},
  If[Sort[Keys[diagrams]] =!= Sort[sideNames],
    fail[
      "DiagramsBySide",
      diagrams,
      "Expected exactly the keys " <> ToString[sideNames, InputForm] <> "."
    ]
  ];
  sides = AssociationMap[Function[name, Module[{list, side},
    list = diagrams[name];
    side = process["Sides"][name];
    If[
      ! MatchQ[Head[list], _FeynArts`TopologyList] ||
        side["DiagramIndex"] > Length[list],
      fail[
        "DiagramsBySide[\"" <> name <> "\"]",
        list,
        "Expected generated diagrams containing the selected index."
      ]
    ];
    Append[side, "Diagrams" -> list]
  ]], sideNames];
  Join[process, <|"Sides" -> sides|>]
];

prepareProcess[_, diagrams_] := fail[
  "DiagramsBySide",
  diagrams,
  "Expected the Association returned by GenerateDiagram."
];

normalizeProcess[config_Association] := Module[
  {
    missing, unknown, partonSides, counts, columns, makeLegs,
    phaseMomenta, integratedMomenta, allMomenta, amplitudeSides,
    declaredVectors, zeroDistributions, zeroEvanescent, zeroMass,
    fractionAssumptions
  },

  missing = Complement[requiredKeys, Keys[config]];
  unknown = Complement[Keys[config], Join[requiredKeys, optionalKeys]];
  If[missing =!= {},
    Message[CollinearFactorize::missing, missing];
    Throw[$Failed, $collinearFailure]
  ];
  If[unknown =!= {},
    Message[CollinearFactorize::unknown, unknown];
    Throw[$Failed, $collinearFailure]
  ];

  partonSides = Lookup[config, "Partons"];
  If[Head[partonSides] =!= Rule || ! AllTrue[List @@ partonSides, ListQ],
    fail["Partons", partonSides, "Expected incoming -> outgoing lists."]
  ];
  partonSides = List @@ partonSides;
  counts = Length /@ partonSides;

  columns = AssociationThread[
    legFields,
    normalizeSides[#, Lookup[config, #], counts] & /@ legInputKeys
  ];
  makeLegs[side_] := AssociationThread[legFields, #] & /@
    Transpose[Lookup[columns, legFields][[All, side]]];
  fractionAssumptions = inferFractionAssumptions[
    Lookup[config, "MomentumFraction"]
  ];

  allMomenta = Flatten[columns["Momentum"]];
  If[! DuplicateFreeQ[allMomenta],
    fail["PartonMomentum", columns["Momentum"], "Momenta must be unique."]
  ];

  phaseMomenta = Lookup[config, "PhaseSpaceMomentum"];
  If[! ListQ[phaseMomenta] || phaseMomenta === {},
    fail["PhaseSpaceMomentum", phaseMomenta, "Expected a nonempty list."]
  ];
  If[Complement[phaseMomenta, columns["Momentum"][[2]]] =!= {},
    fail[
      "PhaseSpaceMomentum",
      phaseMomenta,
      "Every phase-space momentum must be an outgoing parton momentum."
    ]
  ];

  integratedMomenta = Lookup[config, "PartonIntegrated"];
  If[! ListQ[integratedMomenta] || Length[integratedMomenta] =!= 1,
    fail[
      "PartonIntegrated",
      integratedMomenta,
      "One overall momentum delta eliminates exactly one outgoing momentum."
    ]
  ];
  If[Complement[integratedMomenta, phaseMomenta] =!= {},
    fail[
      "PartonIntegrated",
      integratedMomenta,
      "The eliminated momentum must belong to PhaseSpaceMomentum."
    ]
  ];

  amplitudeSides = normalizeAmplitudeSides[config, allMomenta];

  zeroDistributions = Lookup[config, "SetDistributionZero", {}];
  If[
    ! ListQ[zeroDistributions] ||
      ! AllTrue[zeroDistributions, MatchQ[#, _Symbol] &],
    fail[
      "SetDistributionZero",
      zeroDistributions,
      "Expected a list of distribution heads."
    ]
  ];

  declaredVectors = DeleteDuplicates @ Cases[
    Flatten @ Lookup[
      columns,
      {"Momentum", "HadronMomentum", "LongDirection", "DualDirection",
        "TransSpin"}
    ],
    vector_Symbol /; vector =!= NA
  ];
  zeroEvanescent = DeleteDuplicates @ Join[
    internalSetEvanescentZero,
    Complement[declaredVectors, phaseMomenta]
  ];

  zeroMass = Lookup[config, "SetMassZero", {}];
  If[
    ! ListQ[zeroMass] || ! AllTrue[zeroMass, MatchQ[#, _Symbol] &],
    fail[
      "SetMassZero",
      zeroMass,
      "Expected a list of momentum symbols."
    ]
  ];

  <|
    "Type" -> "FeynFacetProcess",
    "Version" -> 2,
    "Sides" -> amplitudeSides["Sides"],
    "VirtualLoopMomenta" -> amplitudeSides["VirtualLoopMomenta"],
    "Incoming" -> makeLegs[1],
    "Outgoing" -> makeLegs[2],
    "PhaseSpaceMomenta" -> phaseMomenta,
    "IntegratedMomentum" -> First[integratedMomenta],
    "SetDistributionZero" -> DeleteDuplicates[zeroDistributions],
    "SetEvanescentZero" -> zeroEvanescent,
    "SetMassZero" -> DeleteDuplicates[zeroMass],
    "Assumptions" -> fractionAssumptions
  |>
];

Clear[remainingPhaseSpaceMomenta, amflowPrescription, AMFlowPrescription];

remainingPhaseSpaceMomenta[process_Association] := DeleteCases[
  process["PhaseSpaceMomenta"],
  process["IntegratedMomentum"],
  {1},
  1
];

amflowPrescription[process_Association] :=
  Module[{phaseLoops, forwardLoops, conjugateLoops},
    phaseLoops = remainingPhaseSpaceMomenta[process];
    forwardLoops = process["Sides"]["Amplitude"]["LoopMomenta"];
    conjugateLoops = process["Sides"]["Conjugate"]["LoopMomenta"];

    <|
      "LoopMomenta" -> Join[phaseLoops, forwardLoops, conjugateLoops],
      "Prescription" -> Join[
        ConstantArray[0, Length[phaseLoops]],
        ConstantArray[1, Length[forwardLoops]],
        ConstantArray[-1, Length[conjugateLoops]]
      ]
    |>
  ];

AMFlowPrescription[config_Association] := Catch[
  amflowPrescription[normalizeProcess[config]],
  $collinearFailure
];

AMFlowPrescription[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);

Clear[momentumEliminationRule];

momentumEliminationRule[process_Association] := Module[
  {momentum, incoming, outgoing},

  momentum = process["IntegratedMomentum"];
  incoming = Lookup[process["Incoming"], "Momentum"];
  outgoing = Lookup[process["Outgoing"], "Momentum"];

  momentum -> Expand[
    Total[incoming] - Total[DeleteCases[outgoing, momentum, {1}, 1]]
  ]
];

Clear[buildPhaseData];

buildPhaseData[process_Association, eliminationRule_Rule] := Module[
  {momenta, remaining},

  momenta = process["PhaseSpaceMomenta"];
  remaining = remainingPhaseSpaceMomenta[process];

  <|
    "Prefactor" -> (2 Pi)^Expand[D - Length[momenta] (D - 1)],
    "Measure" -> Times @@ (FeynFacet`dD /@ remaining),
    "Cuts" -> Times @@ Map[
      Function[momentum,
        With[
          {q = Expand[momentum /. eliminationRule]},
          Cut[FeynCalc`SPD[q], 1]
        ]
      ],
      momenta
    ]
  |>
];

Clear[convertAmplitudeSide, convertAmplitudePair];

lightQuarkMassRules = {
  FeynCalc`SMP["m_u"] -> 0,
  FeynCalc`SMP["m_d"] -> 0,
  FeynCalc`SMP["m_s"] -> 0
};

convertAmplitudeSide[process_Association, name_String] := Module[
  {side, amplitudeFA, converted, momenta, selectedDiagram},

  side = process["Sides"][name];
  momenta = {
    Lookup[process["Incoming"], "Momentum"],
    Lookup[process["Outgoing"], "Momentum"]
  };
  selectedDiagram = FeynArts`DiagramExtract[
    side["Diagrams"],
    side["DiagramIndex"]
  ];
  amplitudeFA = FeynArts`CreateFeynAmp[
    selectedDiagram,
    FeynArts`Truncated -> False,
    FeynArts`PreFactor -> 1
  ];
  converted = FeynCalc`FCFAConvert[
    amplitudeFA,
    FeynCalc`IncomingMomenta -> momenta[[1]],
    FeynCalc`OutgoingMomenta -> momenta[[2]],
    FeynCalc`LoopMomenta -> side["LoopMomenta"],
    FeynCalc`ChangeDimension -> D,
    FeynCalc`DropSumOver -> True,
    FeynCalc`UndoChiralSplittings -> True,
    FeynCalc`SMP -> True,
    FeynCalc`Contract -> True,
    List -> True
  ] /. lightQuarkMassRules;

  If[! ListQ[converted] || Length[converted] =!= 1,
    fail[
      "DiagramsBySide[\"" <> name <> "\"]",
      side["DiagramIndex"],
      "The selected diagram did not convert to exactly one amplitude."
    ]
  ];

  First[converted]
];

convertAmplitudePair[process_Association] := AssociationMap[
  convertAmplitudeSide[process, #] &,
  sideNames
];

Clear[
  setDenominatorEta,
  splitAmplitude,
  topLevelFactors,
  commonFactorMultiset,
  removeFactorOnce
];

setDenominatorEta[expr_, sign : (1 | -1)] := FeynCalc`FCE[
  FeynCalc`ToSFAD[FeynCalc`FCI[expr], FeynCalc`FCI -> True] /.
    FeynCalc`StandardPropagatorDenominator[q_, sp_, mass_, {power_, _}] :>
      FeynCalc`StandardPropagatorDenominator[
        q,
        sp,
        mass,
        {power, sign}
      ]
];

topLevelFactors[expr_] := If[Head[expr] === Times, List @@ expr, {expr}];

commonFactorMultiset[lists_List] := Module[{first, unique},
  first = First[lists];
  unique = DeleteDuplicates[first];
  Flatten[
    Table[factor, {factor, unique},
      {Min[Count[#, factor] & /@ lists]}],
    1
  ]
];

removeFactorOnce[list_List, factor_] := DeleteCases[list, factor, {1}, 1];

splitAmplitude[expr_, side_] := Module[
  {
    external, terms, factorLists, propagatorLists, commonPropagators,
    numeratorLists, propagators, numerator, remaining
  },

  external = setDenominatorEta[
    expr,
    If[side === "conjugate", -1, 1]
  ];
  terms = If[Head[external] === Plus, List @@ external, {external}];
  factorLists = topLevelFactors /@ terms;
  propagatorLists = Cases[
      #,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]]
    ] & /@ factorLists;
  commonPropagators = commonFactorMultiset[propagatorLists];
  numeratorLists = Fold[removeFactorOnce[#1, #2] &, #,
      commonPropagators] & /@ factorLists;
  propagators = Times @@ commonPropagators;
  numerator = Total[Times @@@ numeratorLists];
  remaining = DeleteDuplicates @ Cases[
    numerator,
    HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::propagators, side, remaining];
    Throw[$Failed, $collinearFailure]
  ];

  {numerator, propagators}
];

Clear[splitFactorsByMomentum, splitPropagatorsByMomentum];

splitFactorsByMomentum[expr_, {}] := {expr, 1};

splitFactorsByMomentum[expr_, momenta_List] := Module[
  {factors, independent, dependent},

  factors = topLevelFactors[expr];
  independent = Select[
    factors,
    FreeQ[#, Alternatives @@ momenta] &
  ];
  dependent = Select[
    factors,
    ! FreeQ[#, Alternatives @@ momenta] &
  ];
  {Times @@ independent, Times @@ dependent}
];

splitPropagatorsByMomentum[expr_, momenta_List] := Module[
  {split},

  If[momenta === {}, Return[{expr, 1}]];
  split = FeynCalc`FeynAmpDenominatorSplit[
    FeynCalc`FCI[expr],
    FeynCalc`Momentum -> momenta,
    FeynCalc`FCI -> True,
    FeynCalc`FCE -> True
  ];
  splitFactorsByMomentum[split, momenta]
];

Clear[propagatorSources];

propagatorSources[expr_, role_String, eta : (1 | -1)] := Map[
  Function[propagator,
    <|
      "Expression" -> propagator,
      "Role" -> role,
      "PhysicalEtaSign" -> eta,
      "LineMomentum" -> propagatorMomentum @ First @ Cases[
        FeynCalc`FCI[propagator],
        _FeynCalc`PropagatorDenominator |
          _FeynCalc`StandardPropagatorDenominator,
        Infinity
      ]
    |>
  ],
  Cases[
    topLevelFactors[expr],
    HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]]
  ]
];

Clear[sumUnobservedPolarizations];

sumUnobservedPolarizations[expr_, process_Association] := Module[
  {momenta, result, remaining},

  momenta = Lookup[#, "Momentum"] & /@ Select[
    process["Outgoing"],
    MatchQ[#["Parton"], FeynArts`V[__]] &&
      MissingQ[#["HadronMomentum"]] &
  ];
  result = Fold[
    Function[{current, momentum},
      Quiet[
        FeynCalc`DoPolarizationSums[current, momentum, 0],
        FeynCalc`PolarizationSum::notmassless
      ]
    ],
    expr,
    DeleteDuplicates[momenta]
  ];
  remaining = DeleteDuplicates @ Cases[
    result,
    FeynCalc`Polarization[___],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::polarization, momenta, remaining];
    Throw[$Failed, $collinearFailure]
  ];
  result
];

Clear[unresolvedAlgebraObjects];

unresolvedAlgebraObjects[expr_] := DeleteDuplicates @ Cases[
  FeynCalc`FCI[expr],
  object_ /; MemberQ[
    {
      FeynCalc`Calc,
      FeynCalc`DiracTrace,
      FeynCalc`DiracGamma,
      FeynCalc`DOT,
      FeynCalc`Polarization,
      FeynCalc`LorentzIndex,
      FeynCalc`CartesianIndex,
      FeynCalc`SUNIndex,
      FeynCalc`SUNT,
      FeynCalc`SUNF,
      FeynCalc`SUNDelta
    },
    Head[Unevaluated[object]]
  ] :> object,
  Infinity
];

Clear[
  densityHead, densityLegs, externalSpinTags, tagExternalSpinors,
  densityRule, densityRules
];

densityHead[parton_, side_] := Which[
  MatchQ[parton, FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi], \[CapitalDelta]],
  MatchQ[parton, -FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi]b, \[CapitalDelta]b],
  True,
    fail[
      "Partons",
      parton,
      "A hadron-associated leg must currently be a quark or antiquark."
    ]
];

densityLegs[process_Association] := Select[
  Join[process["Incoming"], process["Outgoing"]],
  ! MissingQ[#["HadronMomentum"]] &
];

externalSpinTags[process_Association] := AssociationThread[
  Lookup[densityLegs[process], "Momentum"],
  Unique["externalSpin$"] & /@ densityLegs[process]
];

tagExternalSpinors[expr_, tags_Association] := expr /.
  spinor_FeynCalc`Spinor :> (spinor /. Normal[tags]);

densityRule[leg_Association, side_, tags_Association] := Module[
  {head, normalization, spinMomentum},

  If[MissingQ[leg["HadronMomentum"]], Return[{}]];
  head = densityHead[leg["Parton"], side];
  spinMomentum = Lookup[tags, leg["Momentum"]];
  normalization = FeynCalc`SPD[
    leg["HadronMomentum"],
    leg["DualDirection"]
  ];
  If[side === "Outgoing",
    normalization *= 2/leg["Fraction"]^3
  ];

  Thread[
    FeynCalc`FCI[{
      FeynCalc`GS[spinMomentum],
      FeynCalc`GSD[spinMomentum]
    }] -> normalization head[
      leg["Fraction"],
      leg["HadronMomentum"],
      leg["LongSpin"],
      leg["TransSpin"],
      leg["LongDirection"]
    ]
  ]
];

densityRules[process_Association, tags_Association] := Join[
  Flatten[densityRule[#, "Incoming", tags] & /@ process["Incoming"]],
  Flatten[densityRule[#, "Outgoing", tags] & /@ process["Outgoing"]]
];

Clear[setDistributionsZero];

setDistributionsZero[expr_, {}] := expr;

setDistributionsZero[expr_, heads_List] := With[
  {alternatives = Alternatives @@ heads},
  expr /. HoldPattern[alternatives[___]] :> 0
];

Clear[containsListedMomentumQ, setEvanescentZero];

containsListedMomentumQ[expr_, momenta_List] :=
  ! FreeQ[Unevaluated[expr], Alternatives @@ momenta];

setEvanescentZero[expr_, {}] := expr;

setEvanescentZero[expr_, momenta_List] := Module[{external},
  external = FeynCalc`FCE[FeynCalc`ExpandScalarProduct[expr]];
  FeynCalc`FCI[external /. {
    HoldPattern[FeynCalc`SPE[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> 0,
    HoldPattern[FeynCalc`SPE[a_]] /;
      containsListedMomentumQ[a, momenta] :> 0,
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> FeynCalc`SPD[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      containsListedMomentumQ[a, momenta] :> FeynCalc`SPD[a]
  }]
];

Clear[setMassZero];

setMassZero[expr_, {}] := expr;

setMassZero[expr_, momenta_List] :=
  FeynCalc`FCI[expr] /.
    Thread[FeynCalc`FCI[FeynCalc`SPD /@ momenta] -> 0];

Clear[applyKinematicZeros];

applyKinematicZeros[expr_, process_Association] := setMassZero[
  setEvanescentZero[expr, process["SetEvanescentZero"]],
  process["SetMassZero"]
];

Clear[fractionMeasure];

fractionMeasure[process_Association] := Module[{fractions},
  fractions = DeleteDuplicates @ Select[
    Lookup[Join[process["Incoming"], process["Outgoing"]], "Fraction"],
    ! MissingQ[#] &
  ];
  Times @@ (dFraction /@ fractions)
];

Clear[factorizePair, CollinearFactorize];

factorizePair[config_Association] := Catch[
  Module[
    {
      process, eliminationRule, phase, amplitudes, completePair, splitPair,
      result, spinTags, taggedNumerator, missingSpinTags,
      remainingSpinTags, cutLoopMomenta, allLoopMomenta, preFactor, integrand,
      cutNormalizationFactor, loopNormalizationFactor,
      externalCuts, loopCuts, sidePropagators, externalPropagators,
      ordinaryPropagators, propagators, sources,
      remainingPropagators,
      remainingAlgebra
    },

    If[! MatchQ[globalBasis, {_, _, _, _}],
      Message[CollinearFactorize::basis];
      Throw[$Failed, $collinearFailure]
    ];
    declareGlobalBasis[globalBasis];

    process = prepareProcess[
      normalizeProcess[config],
      Lookup[config, "DiagramsBySide", Missing["NotAvailable"]]
    ];
    eliminationRule = momentumEliminationRule[process];
    phase = buildPhaseData[process, eliminationRule];
    cutLoopMomenta = remainingPhaseSpaceMomenta[process];
    allLoopMomenta = DeleteDuplicates @ Join[
      cutLoopMomenta,
      process["VirtualLoopMomenta"]
    ];
    loopNormalizationFactor =
      (I Pi^(D/2))^Length[allLoopMomenta];
    cutNormalizationFactor =
      (I Pi^(D/2))^Length[cutLoopMomenta];
    amplitudes = convertAmplitudePair[process];
    splitPair = AssociationMap[
      splitAmplitude[amplitudes[#], ToLowerCase[#]] &,
      sideNames
    ];
    completePair = <|
      "Amplitude" -> First[splitPair["Amplitude"]],
      "Conjugate" -> FeynCalc`ComplexConjugate[
        First[splitPair["Conjugate"]]
      ]
    |>;
    sidePropagators = AssociationMap[
      splitPropagatorsByMomentum[
        Last[splitPair[#]] /. eliminationRule,
        allLoopMomenta
      ] &,
      sideNames
    ];
    externalPropagators = Times @@ (First /@ Values[sidePropagators]);
    ordinaryPropagators = Times @@ (Last /@ Values[sidePropagators]);
    sources = Join[
      propagatorSources[
        Last[sidePropagators["Amplitude"]],
        "Amplitude",
        1
      ],
      propagatorSources[
        Last[sidePropagators["Conjugate"]],
        "Conjugate",
        -1
      ]
    ];
    {externalCuts, loopCuts} = splitFactorsByMomentum[
      phase["Cuts"],
      allLoopMomenta
    ];

    spinTags = externalSpinTags[process];
    taggedNumerator = tagExternalSpinors[
      Times @@ Values[completePair],
      spinTags
    ];
    missingSpinTags = Select[Values[spinTags], FreeQ[taggedNumerator, #] &];
    result = FeynCalc`FermionSpinSum[taggedNumerator];
    result = sumUnobservedPolarizations[result, process];

    result = result /. densityRules[process, spinTags];
    remainingSpinTags = Select[Values[spinTags], ! FreeQ[result, #] &];
    If[missingSpinTags =!= {} || remainingSpinTags =!= {},
      Message[
        CollinearFactorize::spinprojector,
        missingSpinTags,
        remainingSpinTags
      ];
      Throw[$Failed, $collinearFailure]
    ];
    result = setDistributionsZero[
      result,
      process["SetDistributionZero"]
    ];
    result = applyKinematicZeros[result, process];
    result = FeynCalc`Calc[
      result,
      Assumptions -> process["Assumptions"]
    ];
    result = applyKinematicZeros[result, process];
    result = applyKinematicZeros[result /. eliminationRule, process];
    remainingAlgebra = unresolvedAlgebraObjects[result];
    If[remainingAlgebra =!= {},
      Message[
        CollinearFactorize::algebra,
        Take[remainingAlgebra, UpTo[10]]
      ];
      Throw[$Failed, $collinearFailure]
    ];

    {preFactor, integrand} = CommonFactorSafe[
      result,
      allLoopMomenta
    ];
    remainingPropagators = DeleteDuplicates @ Cases[
      integrand,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      Infinity
    ];
    If[remainingPropagators =!= {},
      Message[
        CollinearFactorize::propagators,
        "contracted integrand",
        remainingPropagators
      ];
      Throw[$Failed, $collinearFailure]
    ];

    preFactor = Factor[
      phase["Prefactor"] loopNormalizationFactor preFactor
        FeynCalc`FeynAmpDenominatorExplicit[
          externalPropagators,
          FeynCalc`ExpandScalarProduct -> False,
          FeynCalc`FCE -> True
        ] /.
        FeynCalc`SMP["g_s"] -> Sqrt[4 Pi \[Alpha]s]
    ];
    propagators = loopCuts setDenominatorEta[ordinaryPropagators, 1];
    result = <|
      "Process" -> process,
      "FractionMeasure" -> fractionMeasure[process],
      "PreFactor" -> preFactor,
      "PhaseSpace" -> phase["Measure"] externalCuts/cutNormalizationFactor,
      "Integrand" -> integrand,
      "Propagators" -> propagators,
      "LoopMomenta" -> allLoopMomenta,
      "PropagatorSources" -> sources
    |>;

    If[! FreeQ[
        Lookup[result, {
          "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
          "Propagators", "LoopMomenta", "PropagatorSources"
        }],
        process["IntegratedMomentum"]
      ],
      fail[
        "PartonIntegrated",
        process["IntegratedMomentum"],
        "The eliminated momentum survived in the output."
      ]
    ];

    result
  ],
  $collinearFailure
];

CollinearFactorize[config_Association] := Module[{result = factorizePair[config]},
  If[result === $Failed,
    $Failed,
    Lookup[result, {
      "FractionMeasure",
      "PreFactor",
      "PhaseSpace",
      "Integrand",
      "Propagators",
      "LoopMomenta"
    }]
  ]
];

CollinearFactorize[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);

CollinearFactorizePreIBP::config =
  "Expected one complete configuration Association, but received `1`.";

CollinearFactorizePreIBP::missing =
  "Setup is missing required amplitude keys `1`.";

CollinearFactorizePreIBP::stage =
  "The pre-IBP pipeline failed at stage `1`.";

CollinearFactorizePreIBP::amflow =
  "Could not attach consistent AMFlow metadata to topology `1`.";

$preIBPFailure = "FeynFacetPreIBPFailure";

Clear[
  preIBPFail,
  topologyPropagatorData,
  completeTopologyRecord,
  CollinearFactorizePreIBP
];

preIBPFail[stage_] := (
  Message[CollinearFactorizePreIBP::stage, stage];
  Throw[$Failed, $preIBPFailure]
);

topologyPropagatorData[family_Association, sources_List] := Module[
  {topology, algebraicData, sourceData, cutIndices, cutDirections},

  topology = family["Topology"];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];
  algebraicData = topologyPropagatorInfo /@ topology[[2]];
  sourceData = Map[
    Function[source,
      Append[source, "Algebraic" -> topologyPropagatorInfo[source["Expression"]]]
    ],
    sources
  ];
  If[
    MemberQ[algebraicData, $Failed] ||
      AnyTrue[sourceData, #1["Algebraic"] === $Failed &],
    Return[$Failed]
  ];

  MapIndexed[
    Function[{algebraic, position},
      Module[{index, cutPosition, matches, factors},
        index = First[position];
        cutPosition = FirstPosition[cutIndices, index];
        If[! MissingQ[cutPosition],
          <|
            "Algebraic" -> algebraic,
            "Physical" -> <|
              "Role" -> "Cut",
              "Factors" -> {<|
                "CausalSide" -> 0,
                "PhysicalEtaSign" -> Missing["NotApplicable"],
                "EnergyDirection" -> cutDirections[[First[cutPosition]]]
              |>}
            |>
          |>,
          matches = Select[
            sourceData,
            #1["Algebraic", "Type"] === algebraic["Type"] &&
              sameMomentumQ[
                #1["Algebraic", "Momentum"],
                algebraic["Momentum"]
              ] &
          ];
          factors = (<|
              "Role" -> #1["Role"],
              "CausalSide" -> If[#1["Role"] === "Amplitude", 1, -1],
              "PhysicalEtaSign" -> #1["PhysicalEtaSign"]
            |> &) /@ matches;
          <|
            "Algebraic" -> algebraic,
            "Physical" -> If[
              factors === {},
              <|"Role" -> "Auxiliary", "Factors" -> {}|>,
              <|"Role" -> "Uncut", "Factors" -> factors|>
            ]
          |>
        ]
      ]
    ],
    algebraicData
  ]
];

completeTopologyRecord[
    family_Association,
    amflow_Association,
    pair_Association,
    sources_List
  ] := Module[
  {
    topology, loopMomenta, prescription, propagatorCount,
    cutIndices, cutDirections, cutMask, propagatorData, record
  },

  topology = family["Topology"];
  loopMomenta = amflow["LoopMomenta"];
  prescription = amflow["Prescription"];
  propagatorCount = Length[topology[[2]]];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];

  If[
    topology[[3]] =!= loopMomenta ||
      Length[prescription] =!= Length[loopMomenta] ||
      ! AllTrue[prescription, MemberQ[{0, 1, -1}, #] &] ||
      Length[cutIndices] =!= Length[cutDirections] ||
      ! DuplicateFreeQ[cutIndices] ||
      ! AllTrue[cutIndices, IntegerQ[#] && 1 <= # <= propagatorCount &] ||
      ! AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    Message[CollinearFactorizePreIBP::amflow, topology[[1]]];
    Return[$Failed]
  ];

  cutMask = ReplacePart[
    ConstantArray[0, propagatorCount],
    Thread[cutIndices -> ConstantArray[1, Length[cutIndices]]]
  ];
  propagatorData = topologyPropagatorData[family, sources];
  If[propagatorData === $Failed,
    Message[CollinearFactorizePreIBP::amflow, topology[[1]]];
    Return[$Failed]
  ];
  record = Join[
    family,
    <|
      "Type" -> "FeynFacetTopologyRecord",
      "Version" -> 2,
      "DiagramPair" -> pair,
      "PropagatorData" -> propagatorData,
      "AMFlowInfo" -> <|
        "Family" -> topology[[1]],
        "Loop" -> loopMomenta,
        "Prescription" -> prescription,
        "Cut" -> cutMask,
        "PhysicalCausalStatus" -> "Verified"
      |>
    |>
  ];
  If[TrueQ[safeTopologyRecordQ[record]], record, $Failed]
];

CollinearFactorizePreIBP[config_Association] := Catch[
  Module[
    {
      amplitudeKeys, missing, forwardAmplitudes,
      conjugateAmplitudes, diagrams, pipelineConfig, factorized,
      fractions, families, amflow, pair, topologies,
      shiftedIntegrand
    },

    amplitudeKeys = {"ForwardAmplitudes", "ConjugateAmplitudes"};
    missing = Complement[amplitudeKeys, Keys[config]];
    If[missing =!= {},
      Message[CollinearFactorizePreIBP::missing, missing];
      Throw[$Failed, $preIBPFailure]
    ];

    forwardAmplitudes = config["ForwardAmplitudes"];
    conjugateAmplitudes = config["ConjugateAmplitudes"];
    If[
      ! AllTrue[
        {forwardAmplitudes, conjugateAmplitudes},
        AssociationQ[#] && KeyExistsQ[#, "SelectedIndex"] &
      ],
      preIBPFail["diagram selection"]
    ];
    diagrams = GenerateDiagram[config];
    If[diagrams === $Failed, preIBPFail["GenerateDiagram"]];
    printSelectedDiagrams[diagrams, config];

    pipelineConfig = Join[
      config,
      <|
        "DiagramsBySide" -> diagrams
      |>
    ];
    factorized = factorizePair[pipelineConfig];
    If[! AssociationQ[factorized],
      preIBPFail["CollinearFactorize"]
    ];
    fractions = PartialFraction[
      factorized["Propagators"],
      factorized["LoopMomenta"]
    ];
    If[fractions === $Failed, preIBPFail["PartialFraction"]];
    families = BuildTopologies[
      fractions,
      factorized["LoopMomenta"],
      pipelineConfig
    ];
    If[families === $Failed, preIBPFail["BuildTopologies"]];

    amflow = amflowPrescription[factorized["Process"]];
    If[! AssociationQ[amflow], preIBPFail["AMFlowPrescription"]];
    pair = <|
      "Forward" -> forwardAmplitudes["SelectedIndex"],
      "Conjugate" -> conjugateAmplitudes["SelectedIndex"]
    |>;
    topologies = completeTopologyRecord[
        #,
        amflow,
        pair,
        factorized["PropagatorSources"]
      ] & /@ families;
    If[MemberQ[topologies, $Failed], preIBPFail["AMFlow metadata"]];

    shiftedIntegrand = DimensionalShift[
      factorized["Integrand"],
      topologies,
      factorized["LoopMomenta"]
    ];
    If[shiftedIntegrand === $Failed, preIBPFail["DimensionalShift"]];

    Join[
      Lookup[factorized, {"FractionMeasure", "PreFactor", "PhaseSpace"}],
      {shiftedIntegrand, topologies}
    ]
  ],
  $preIBPFailure
];

CollinearFactorizePreIBP[config_] := (
  Message[CollinearFactorizePreIBP::config, config];
  $Failed
);

GenerateCollinearFactorizePreIBPResult::setup =
  "Setup must contain a nonempty CardName and positive selected forward and conjugate diagram indices.";

GenerateCollinearFactorizePreIBPResult::failed =
  "At least one supplied pre-IBP output contains $Failed.";

GenerateCollinearFactorizePreIBPResult::topologies =
  "Topologies contains an invalid or pair-inconsistent topology record.";

Clear[
  selectedPairFromSetup,
  validStoredTopologyQ,
  sourceNotebookFile,
  GenerateCollinearFactorizePreIBPResult
];

selectedPairFromSetup[setup_Association] := Module[{indices},
  indices = Lookup[Lookup[setup, #, <||>], "SelectedIndex", Missing[]] & /@
    {"ForwardAmplitudes", "ConjugateAmplitudes"};
  If[
    AllTrue[indices, IntegerQ[#] && Positive[#] &],
    AssociationThread[{"Forward", "Conjugate"}, indices],
    $Failed
  ]
];

validStoredTopologyQ[topology_, pair_Association] :=
  safeTopologyRecordQ[topology] &&
    SameQ[Lookup[topology, "DiagramPair", Missing[]], pair];

sourceNotebookFile[] := Module[{file},
  file = Quiet @ Check[NotebookFileName[], $Failed];
  If[StringQ[file] && StringLength[file] > 0,
    ExpandFileName[file],
    Missing["NotAvailable"]
  ]
];

GenerateCollinearFactorizePreIBPResult[
    setup_Association,
    fractionMeasure_,
    preFactor_,
    phaseSpace_,
    integrand_,
    topologies_List
  ] := Module[{cardName, pair, sourceNotebook},
  cardName = Lookup[setup, "CardName", Missing["NotAvailable"]];
  pair = selectedPairFromSetup[setup];
  If[
    ! StringQ[cardName] || StringLength[StringTrim[cardName]] === 0 ||
      pair === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::setup];
    Return[$Failed]
  ];
  If[
    ! FreeQ[
      HoldComplete[
        fractionMeasure, preFactor, phaseSpace, integrand, topologies
      ],
      $Failed
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  If[! AllTrue[topologies, validStoredTopologyQ[#, pair] &],
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  sourceNotebook = Lookup[setup, "SourceNotebook", Automatic];
  sourceNotebook = If[
    sourceNotebook === Automatic,
    sourceNotebookFile[],
    If[
      StringQ[sourceNotebook] && StringLength[sourceNotebook] > 0,
      ExpandFileName[sourceNotebook],
      Missing["NotAvailable"]
    ]
  ];
  Join[resultHeader["FeynFacet-CollinearFactorizePreIBP", 1], <|
    "CardName" -> StringTrim[cardName],
    "Pair" -> pair,
    "SourceNotebook" -> sourceNotebook,
    "Setup" -> setup,
    "FractionMeasure" -> fractionMeasure,
    "PreFactor" -> preFactor,
    "PhaseSpace" -> phaseSpace,
    "Integrand" -> integrand,
    "Topologies" -> topologies
  |>]
];

GenerateCollinearFactorizePreIBPResult[___] := (
  Message[GenerateCollinearFactorizePreIBPResult::setup];
  $Failed
);

IBP::input =
  "IBP expects a nonempty list of valid FeynFacet pre-IBP result Associations.";

IBP::stage =
  "IBP failed during `1`: `2`.";

KiraReduction::input =
  "KiraReduction expects a nonempty list of valid FeynFacet pre-IBP result Associations or saved result files.";

CoefficientSimplification::input =
  "CoefficientSimplification expects the original pre-IBP result list and its matching FeynFacet-KiraReduction Association.";

$ibpFailure = "FeynFacetIBPFailure";

Clear[
  ibpFail,
  validPreIBPResultQ,
  ibpBaseSetup,
  ibpInputSummary,
  ibpInputData,
  ibpKiraReductionCore,
  ibpCompleteKinematics,
  ibpInsertCuts,
  ibpResetProject,
  ibpPrepareKiraProject,
  ibpRunKira,
  ibpImportRules,
  ibpDeclaredMasters,
  ibpCloseReductionRules,
  ibpValidateMasters,
  ibpAssumptions,
  KiraReduction,
  CoefficientSimplification,
  IBP
];

ibpFail[stage_, detail_] := (
  Message[IBP::stage, stage, detail];
  Throw[$Failed, $ibpFailure]
);

validPreIBPResultQ[result_] := Module[{pair},
  If[
    ! AssociationQ[result] ||
      Lookup[result, "Format", None] =!=
        "FeynFacet-CollinearFactorizePreIBP" ||
      ! And @@ (KeyExistsQ[result, #] & /@ {
        "CardName", "Pair", "Setup", "FractionMeasure",
        "PreFactor", "PhaseSpace", "Integrand", "Topologies"
      }),
    Return[False]
  ];
  pair = result["Pair"];
  AssociationQ[pair] &&
    IntegerQ[Lookup[pair, "Forward", None]] &&
    IntegerQ[Lookup[pair, "Conjugate", None]] &&
    ListQ[result["Topologies"]] &&
    AllTrue[result["Topologies"], validStoredTopologyQ[#, pair] &]
];

ibpBaseSetup[setup_Association] := Join[
  setup,
  <|
    "ForwardAmplitudes" -> KeyDrop[
      Lookup[setup, "ForwardAmplitudes", <||>],
      "SelectedIndex"
    ],
    "ConjugateAmplitudes" -> KeyDrop[
      Lookup[setup, "ConjugateAmplitudes", <||>],
      "SelectedIndex"
    ]
  |>
];

ibpInputSummary[item_, includeTargets_] := Module[
  {file, result, directory},
  file = If[StringQ[item], ExpandFileName[item], Missing["InMemory"]];
  If[StringQ[item] && ! FileExistsQ[file], Return[$Failed]];
  result = If[StringQ[item], Quiet @ Check[Get[file], $Failed], item];
  If[! validPreIBPResultQ[result], Return[$Failed]];
  directory = Lookup[result, "ResultDirectory", Missing[]];
  If[! StringQ[directory] || ! DirectoryQ[directory],
    directory = If[StringQ[file], DirectoryName[DirectoryName[file]], $Failed]
  ];
  If[directory === $Failed || ! DirectoryQ[directory], Return[$Failed]];
  <|
    "CardName" -> result["CardName"],
    "Pair" -> result["Pair"],
    "Setup" -> ibpBaseSetup[result["Setup"]],
    "FractionMeasure" -> result["FractionMeasure"],
    "PhaseSpace" -> result["PhaseSpace"],
    "ResultDirectory" -> ExpandFileName[directory],
    "Records" -> result["Topologies"],
    "Targets" -> If[TrueQ[includeTargets],
      DeleteDuplicates[Cases[result["Integrand"], _FeynCalc`GLI, Infinity]],
      {}
    ],
    "Source" -> If[StringQ[file], file, result]
  |>
];

ibpInputData[items_List, includeTargets_: False] := Module[
  {summaries, unique, pairs, data},
  If[items === {} || ! (AllTrue[items, AssociationQ] || AllTrue[items, StringQ]),
    ibpFail["input validation", "expected nonempty Associations or saved result files"]
  ];
  summaries = ibpInputSummary[#, includeTargets] & /@ items;
  If[MemberQ[summaries, $Failed],
    ibpFail["input validation", "a pre-IBP result is missing, invalid or has no result directory"]
  ];
  pairs = Lookup[summaries, "Pair"];
  If[! DuplicateFreeQ[pairs],
    ibpFail["input validation", "diagram pairs must be unique"]
  ];
  unique[key_] := DeleteDuplicates[Lookup[summaries, key], SameQ];
  If[! AllTrue[
      {"CardName", "Setup", "FractionMeasure", "PhaseSpace", "ResultDirectory"},
      Length[unique[#]] === 1 &
    ],
    ibpFail["input validation", "results do not share one card, setup, measure and directory"]
  ];
  data = AssociationMap[First[unique[#]] &,
    {"CardName", "Setup", "FractionMeasure", "PhaseSpace", "ResultDirectory"}
  ];
  Join[data, <|
    "Pairs" -> pairs,
    "Records" -> Flatten[Lookup[summaries, "Records"], 1],
    "RawTargets" -> DeleteDuplicates[Flatten[Lookup[summaries, "Targets"], 1]],
    "Sources" -> Lookup[summaries, "Source"]
  |>]
];

ibpCompleteKinematics[records_List] := Module[
  {
    topologies, externalLists, loopLists, ruleLists, external,
    baseRules, pairs, generatedRules = {}, reverseRules = {},
    counter = 0, lhs, invariant, rhs, augmentedTopologies,
    augmentedRecords, invariants, massDimensions
  },

  topologies = Lookup[records, "Topology"];
  externalLists = #[[4]] & /@ topologies;
  loopLists = #[[3]] & /@ topologies;
  ruleLists = #[[5]] & /@ topologies;
  If[
    Length[DeleteDuplicates[externalLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[loopLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[ruleLists, SameQ]] =!= 1,
    ibpFail[
      "kinematic completion",
      "representative topologies do not share one external basis"
    ]
  ];
  external = First[externalLists];
  baseRules = First[ruleLists];
  pairs = Flatten[
    Table[{external[[i]], external[[j]]},
      {i, Length[external]}, {j, i, Length[external]}],
    1
  ];

  Do[
    lhs = FeynCalc`FCI[FeynCalc`SPD[pair[[1]], pair[[2]]]];
    If[SameQ[lhs /. baseRules, lhs],
      counter++;
      invariant = ToExpression["Global`ffsp" <> ToString[counter]];
      rhs = If[
        SameQ[pair[[1]], pair[[2]]],
        invariant,
        invariant/2
      ];
      AppendTo[generatedRules, lhs -> rhs];
      AppendTo[
        reverseRules,
        invariant -> If[
          SameQ[pair[[1]], pair[[2]]],
          FeynCalc`SPD[pair[[1]]],
          2 FeynCalc`SPD[pair[[1]], pair[[2]]]
        ]
      ]
    ],
    {pair, pairs}
  ];

  augmentedTopologies = Replace[
    topologies,
    FeynCalc`FCTopology[
        name_, propagators_, loops_, ext_, rules_, options_
      ] :> FeynCalc`FCTopology[
        name,
        propagators,
        loops,
        ext,
        DeleteDuplicates[Join[rules, generatedRules]],
        options
      ],
    {1}
  ];
  If[
    ! AllTrue[
      augmentedTopologies,
      TrueQ[FeynCalc`FCLoopValidTopologyQ[#]] &&
        ! TrueQ[FeynCalc`FCLoopBasisIncompleteQ[#]] &
    ],
    ibpFail[
      "kinematic completion",
      "the completed FCTopology basis is invalid or incomplete"
    ]
  ];
  invariants = FeynCalc`FCLoopGetKinematicInvariants[
    augmentedTopologies,
    Check -> False,
    FeynCalc`FCFeynmanPrepare -> False,
    FeynCalc`FCVerbose -> -1,
    Union -> True
  ];
  invariants = DeleteCases[Flatten[{invariants}], 0 | 1];
  massDimensions = Thread[DeleteDuplicates[invariants] -> 2];
  augmentedRecords = MapThread[
    Append[#1, "Topology" -> #2] &,
    {records, augmentedTopologies}
  ];

  <|
    "Records" -> augmentedRecords,
    "MassDimensions" -> massDimensions,
    "ReverseRules" -> reverseRules
  |>
];

ibpInsertCuts[path_String, cutIndices_List] := Module[
  {lines, position},
  lines = Import[path, "Lines"];
  lines = DeleteCases[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "cut_propagators:"]
  ];
  position = FirstPosition[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "top_level_sectors:"]
  ];
  If[MissingQ[position],
    ibpFail["Kira configuration", "missing top_level_sectors"]
  ];
  lines = Insert[
    lines,
    "    cut_propagators: [" <>
      StringRiffle[ToString /@ Sort[cutIndices], ", "] <> "]",
    position[[1]] + 1
  ];
  Export[path, StringRiffle[lines, "\n"] <> "\n", "String"];
];

ibpResetProject[projectDirectory_String, allowedRoot_String] := Module[
  {root, project},
  root = ExpandFileName[allowedRoot];
  project = ExpandFileName[projectDirectory];
  If[! DirectoryQ[root],
    ibpFail["project setup", "the result directory does not exist"]
  ];
  If[
    project === root || ! StringStartsQ[
      project <> $PathnameSeparator,
      root <> $PathnameSeparator
    ],
    ibpFail["project setup", "unsafe IBP project path"]
  ];
  If[
    DirectoryQ[project] && ! TrueQ[Global`$FACETResumeKira],
    DeleteDirectory[project, DeleteContents -> True]
  ];
  If[
    ! DirectoryQ[project],
    CreateDirectory[project, CreateIntermediateDirectories -> True]
  ];
  project
];

ibpPrepareKiraProject[
    records_List,
    targets_List,
    projectDirectory_String,
    massDimensions_List
  ] := Module[
  {
    familyRoot, combinedDirectory, manifest, record, topology,
    name, familyTargets, familyDirectory, cutIndices, familyBlocks,
    kinematics, reduceLines, jobLines
  },

  familyRoot = FileNameJoin[{projectDirectory, "families"}];
  combinedDirectory = FileNameJoin[{projectDirectory, "kira"}];
  If[
    ! DirectoryQ[familyRoot],
    CreateDirectory[familyRoot, CreateIntermediateDirectories -> True]
  ];

  manifest = Table[
    record = records[[index]];
    topology = record["Topology"];
    name = topology[[1]];
    cutIndices = Sort[record["CutIndices"]];
    familyTargets = Select[targets, SameQ[#[[1]], name] &];
    If[familyTargets === {},
      ibpFail["Kira target construction", "empty target family"]
    ];
    If[
      ! AllTrue[
        familyTargets,
        AllTrue[#[[2, cutIndices]], IntegerQ[#] && # > 0 &] &
      ],
      ibpFail[
        "Kira target construction",
        "a requested integral removes an oriented cut propagator"
      ]
    ];

    If[
      CheckAbort[
        Quiet[
          FeynCalc`KiraCreateConfigFiles[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraMassDimensions -> massDimensions,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateIntegralFile[
            Total[familyTargets],
            topology,
            familyRoot,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateJobFile[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraIntegrals -> {"KiraLoopIntegrals"},
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          True
        ],
        False
      ] =!= True,
      ibpFail[
        "Kira configuration",
        "FeynHelpers could not export the topology"
      ]
    ];
    familyDirectory = FileNameJoin[{
      familyRoot,
      ToString[name, InputForm]
    }];
    ibpInsertCuts[
      FileNameJoin[{
        familyDirectory,
        "config",
        "integralfamilies.yaml"
      }],
      cutIndices
    ];
    <|
      "Name" -> name,
      "Directory" -> familyDirectory,
      "Targets" -> familyTargets,
      "CutIndices" -> cutIndices,
      "Ordinal" -> index
    |>,
    {index, Length[records]}
  ];

  If[
    ! DirectoryQ[FileNameJoin[{combinedDirectory, "config"}]],
    CreateDirectory[
      FileNameJoin[{combinedDirectory, "config"}],
      CreateIntermediateDirectories -> True
    ]
  ];
  familyBlocks = Flatten @ Table[
    Rest @ Import[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "config",
        "integralfamilies.yaml"
      }],
      "Lines"
    ],
    {index, Length[manifest]}
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "integralfamilies.yaml"
    }],
    StringRiffle[Prepend[familyBlocks, "integralfamilies:"], "\n"] <>
      "\n",
    "String"
  ];
  kinematics = Import[
    FileNameJoin[{
      #["Directory"],
      "config",
      "kinematics.yaml"
    }],
    "Text"
  ] & /@ manifest;
  If[Length[DeleteDuplicates[kinematics]] =!= 1,
    ibpFail[
      "Kira configuration",
      "families generated different external kinematics"
    ]
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "kinematics.yaml"
    }],
    First[kinematics],
    "String"
  ];

  reduceLines = Flatten @ Table[
    Select[
      Import[
        FileNameJoin[{manifest[[index, "Directory"]], "job.yaml"}],
        "Lines"
      ],
      StringStartsQ[StringTrim[#], "- {topologies:"] &
    ],
    {index, Length[manifest]}
  ];
  Do[
    CopyFile[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "KiraLoopIntegrals"
      }],
      FileNameJoin[{
        combinedDirectory,
        "integrals_" <> ToString[index]
      }],
      OverwriteTarget -> True
    ],
    {index, Length[manifest]}
  ];
  jobLines = Join[
    {"jobs:", "  - reduce_sectors:", "      reduce:"},
    reduceLines,
    {"      select_integrals:", "        select_mandatory_list:"},
    Table[
      "          - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ],
    {
      "      run_initiate: true",
      "      run_triangular: true",
      "      run_back_substitution: true",
      "      integral_ordering: 2",
      "  - kira2math:",
      "      target:"
    },
    Table[
      "        - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ]
  ];
  Export[
    FileNameJoin[{combinedDirectory, "jobs.yaml"}],
    StringRiffle[jobLines, "\n"] <> "\n",
    "String"
  ];

  <|
    "Directory" -> combinedDirectory,
    "Manifest" -> manifest
  |>
];

ibpRunKira[project_Association] := Module[
  {
    directory, manifest, kira, fermat, supportFile, parallel,
    process, log, logPath, unreduced, resultPaths
  },

  directory = project["Directory"];
  manifest = project["Manifest"];
  kira = If[
    ValueQ[Global`$FACETKiraExecutable],
    Global`$FACETKiraExecutable,
    FileNameJoin[{
      $feynFacetRoot,
      "Addon",
      "Other_Addon",
      "Kira",
      "bin",
      "kira"
    }]
  ];
  fermat = If[
    ValueQ[Global`$FACETFermatExecutable],
    Global`$FACETFermatExecutable,
    FileNameJoin[{DirectoryName[kira], "fer64"}]
  ];
  supportFile = FileNameJoin[{
    DirectoryName[fermat],
    "BACKWARD",
    "chdat"
  }];
  If[
    ! FileExistsQ[kira] || ! FileExistsQ[fermat] ||
      ! FileExistsQ[supportFile],
    ibpFail[
      "Kira launch",
      "the complete Kira/Fermat runtime is not installed"
    ]
  ];
  parallel = Min[
    Max[1, $ProcessorCount],
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      8
    ]
  ];
  SetEnvironment["FERMATPATH" -> fermat];
  logPath = FileNameJoin[{directory, "kira.log"}];
  resultPaths = Table[
    FileNameJoin[{
      directory,
      "results",
      ToString[manifest[[index, "Name"]], InputForm],
      "kira_integrals_" <> ToString[index] <> ".m"
    }],
    {index, Length[manifest]}
  ];
  If[
    TrueQ[Global`$FACETResumeKira] &&
      AllTrue[resultPaths, FileExistsQ],
    Return[logPath]
  ];
  process = RunProcess[
    {kira, "--parallel=" <> ToString[parallel], "jobs.yaml"},
    All,
    ProcessDirectory -> directory
  ];
  log = StringJoin[
    Lookup[process, "StandardOutput", ""],
    Lookup[process, "StandardError", ""]
  ];
  Export[logPath, log, "String"];
  If[Lookup[process, "ExitCode", 1] =!= 0,
    ibpFail[
      "Kira reduction",
      "Kira exited with code " <>
        ToString[Lookup[process, "ExitCode", "unknown"]] <>
        "; see " <> logPath
    ]
  ];
  unreduced = ToExpression /@ StringCases[
    log,
    RegularExpression["unreduced integrals: ([0-9]+)"] -> "$1"
  ];
  If[
    Length[unreduced] < Length[manifest] ||
      ! AllTrue[unreduced, # === 0 &],
    ibpFail[
      "Kira reduction",
      "Kira did not report zero unreduced integrals for every family"
    ]
  ];
  logPath
];

ibpImportRules[project_Association] := Module[
  {directory, manifest, rules, path, dimension},
  directory = project["Directory"];
  manifest = project["Manifest"];
  dimension = Symbol["Global`d"] ->
    4 - 2 Symbol["Global`Epsilon"];
  rules = Flatten @ Table[
    path = FileNameJoin[{
      directory,
      "results",
      ToString[manifest[[index, "Name"]], InputForm],
      "kira_integrals_" <> ToString[index] <> ".m"
    }];
    If[! FileExistsQ[path],
      ibpFail["Kira import", "missing reduction table " <> path]
    ];
    CheckAbort[
      Quiet @ FeynCalc`KiraImportResults[
        manifest[[index, "Name"]],
        path,
        FeynCalc`FCReplaceD -> {dimension},
        FeynCalc`FCVerbose -> -1
      ],
      ibpFail["Kira import", "FeynHelpers could not import " <> path]
    ],
    {index, Length[manifest]}
  ];
  DeleteDuplicates[rules]
];

ibpDeclaredMasters[project_Association] := Module[
  {
    directory, manifest, nameMap, paths, lines, parseLine, masters
  },
  directory = project["Directory"];
  manifest = project["Manifest"];
  nameMap = Association[
    ToString[#1["Name"], InputForm] -> #1["Name"] & /@ manifest
  ];
  paths = FileNameJoin[{
      directory,
      "results",
      ToString[#1["Name"], InputForm],
      "masters.final"
    }] & /@ manifest;
  If[! AllTrue[paths, FileExistsQ],
    ibpFail["Kira master validation", "a masters.final file is missing"]
  ];
  parseLine[line_String] := Module[
    {integral, pieces, name, indices},
    integral = StringTrim[First[StringSplit[line, "#"]]];
    pieces = StringSplit[integral, {"[", "]"}];
    If[Length[pieces] < 2 || ! KeyExistsQ[nameMap, First[pieces]],
      ibpFail[
        "Kira master validation",
        "cannot parse master integral " <> integral
      ]
    ];
    name = nameMap[First[pieces]];
    indices = Quiet @ Check[
      ToExpression["{" <> pieces[[2]] <> "}", InputForm],
      $Failed
    ];
    If[! MatchQ[indices, {___Integer}],
      ibpFail[
        "Kira master validation",
        "invalid master indices in " <> integral
      ]
    ];
    FeynCalc`GLI[name, indices]
  ];
  lines = Flatten[Select[Import[#1, "Lines"],
      StringTrim[#1] =!= "" &] & /@ paths];
  masters = DeleteDuplicates[parseLine /@ lines];
  masters
];

ibpCloseReductionRules[rules_List, targets_List] := Module[
  {
    groups, uniqueRules, leftSides, dispatch, current, next,
    converged = False, unresolved, closedRules, masters
  },
  groups = GatherBy[rules, First];
  If[
    ! AllTrue[
      groups,
      Length[DeleteDuplicates[Last /@ #1, SameQ]] === 1 &
    ],
    ibpFail[
      "Kira rule closure",
      "the imported tables contain conflicting rules for one integral"
    ]
  ];
  uniqueRules = First /@ groups;
  leftSides = First /@ uniqueRules;
  dispatch = Dispatch[uniqueRules];
  current = targets;
  Do[
    next = current /. dispatch;
    If[SameQ[next, current],
      converged = True;
      Break[]
    ];
    current = next,
    {Length[uniqueRules] + 2}
  ];
  unresolved = Intersection[
    DeleteDuplicates @ Cases[current, _FeynCalc`GLI, Infinity],
    leftSides,
    SameTest -> SameQ
  ];
  If[! converged || unresolved =!= {},
    ibpFail[
      "Kira rule closure",
      "the imported tables do not reduce transitively to terminal integrals"
    ]
  ];
  closedRules = Select[
    MapThread[Rule, {targets, current}],
    ! SameQ[First[#1], Last[#1]] &
  ];
  masters = DeleteDuplicates @ Cases[current, _FeynCalc`GLI, Infinity];
  <|
    "Rules" -> closedRules,
    "Images" -> current,
    "Masters" -> masters
  |>
];

ibpValidateMasters[
    masters_List,
    declaredMasters_List,
    records_List
  ] := Module[{undeclared, recordByName, badMaster},
  undeclared = Complement[
    masters,
    declaredMasters,
    SameTest -> SameQ
  ];
  If[undeclared =!= {},
    ibpFail[
      "Kira master validation",
      ToString[Length[undeclared]] <>
        " terminal integrals are absent from Kira's declared master list; " <>
        "the exported rule set is not closed"
    ]
  ];
  recordByName = Association[
    #1["Topology"][[1]] -> #1 & /@ records
  ];
  badMaster = FirstCase[
    masters,
    master_ /; ! KeyExistsQ[recordByName, master[[1]]] ||
      ! AllTrue[
        master[[2, recordByName[master[[1]], "CutIndices"]]],
        IntegerQ[#1] && #1 > 0 &
      ],
    Missing["NotFound"]
  ];
  If[! MissingQ[badMaster],
    ibpFail[
      "cut validation",
      "the reduction returned a master without every required cut"
    ]
  ];
  True
];

ibpAssumptions[setup_Association] := Module[{rule, fractions},
  rule = Lookup[setup, "MomentumFraction", {}];
  fractions = If[
    MatchQ[rule, _Rule],
    DeleteCases[
      DeleteDuplicates @ Flatten[List @@ rule],
      0 | _Missing
    ],
    {}
  ];
  And @@ (0 < # < 1 & /@ fractions)
];

Clear[
  linearIntegralSum,
  linearIntegralSumQ,
  linearAdd,
  linearMapIntegrals,
  linearApplyReduction,
  linearNormalize,
  linearToExpression,
  ibpStructuralCommonFactor,
  branchSensitiveObjectQ,
  exactCoefficientNormalize,
  dynamicSimplifyExpressions,
  parallelSimplifyByMaster
];

linearIntegralSum[expression_] := Module[
  {objects, coefficients, remainder, reconstructed},
  objects = DeleteDuplicates @ Cases[
    expression,
    _FeynCalc`GLI,
    Infinity
  ];
  coefficients = AssociationMap[Coefficient[expression, #] &, objects];
  remainder = expression /. Dispatch[Thread[objects -> 0]];
  reconstructed = Total[KeyValueMap[#1 #2 &, coefficients]] + remainder;
  If[
    ! FreeQ[Values[coefficients], _FeynCalc`GLI] ||
      ! TrueQ[Expand[expression - reconstructed] === 0],
    ibpFail[
      "linear integral extraction",
      "the expression is not linear in explicit GLI objects"
    ]
  ];
  <|
    "Terms" -> coefficients,
    "Remainder" -> remainder
  |>
];

linearIntegralSumQ[data_] := AssociationQ[data] &&
  AssociationQ[Lookup[data, "Terms", None]] &&
  AllTrue[Keys[data["Terms"]], MatchQ[#, _FeynCalc`GLI] &] &&
  FreeQ[Values[data["Terms"]], _FeynCalc`GLI] &&
  FreeQ[Lookup[data, "Remainder", 0], _FeynCalc`GLI];

linearToExpression[data_?linearIntegralSumQ] :=
  Total[KeyValueMap[#1 #2 &, data["Terms"]]] + data["Remainder"];

linearNormalize[data_?linearIntegralSumQ] := <|
  "Terms" -> Map[exactCoefficientNormalize, data["Terms"]],
  "Remainder" -> exactCoefficientNormalize[data["Remainder"]]
|>;

linearAdd[parts_List] := Module[{result},
  If[! AllTrue[parts, linearIntegralSumQ],
    ibpFail["linear integral addition", "received an invalid sparse sum"]
  ];
  result = <|
    "Terms" -> Merge[Lookup[parts, "Terms"], Total],
    "Remainder" -> Total[Lookup[parts, "Remainder"]]
  |>;
  If[linearIntegralSumQ[result], result,
    ibpFail["linear integral addition", "sparse sums did not merge linearly"]
  ]
];

linearMapIntegrals[data_?linearIntegralSumQ, rules_] := Module[{terms, result},
  terms = KeyValueMap[(Replace[#1, rules, {0}] -> #2) &, data["Terms"]];
  If[! AllTrue[First /@ terms, MatchQ[#, _FeynCalc`GLI] &],
    ibpFail["integral mapping", "a verified rule did not return one GLI"]
  ];
  result = <|
    "Terms" -> Merge[terms, Total],
    "Remainder" -> data["Remainder"]
  |>;
  If[linearIntegralSumQ[result], result,
    ibpFail["integral mapping", "mapped coefficients contain GLI objects"]
  ]
];

linearApplyReduction[data_?linearIntegralSumQ, rules_, reverseRules_] :=
  linearAdd @ Join[
    KeyValueMap[
      linearIntegralSum[#2 ((#1 /. rules) /. reverseRules)] &,
      data["Terms"]
    ],
    {linearIntegralSum[data["Remainder"] /. reverseRules]}
  ];

ibpStructuralCommonFactor[expressions_List] := Module[
  {factorLists, shared, removeShared, common, reduced},
  If[expressions === {}, Return[{1, {}}]];
  factorLists = If[Head[#1] === Times, List @@ #1, {#1}] & /@
    expressions;
  shared = Fold[
    Function[{current, next},
      Select[
        current,
        Function[factor, AnyTrue[next, Function[item, SameQ[factor, item]]]]
      ]
    ],
    First[factorLists],
    Rest[factorLists]
  ];
  shared = DeleteDuplicates[shared, SameQ];
  removeShared[factors_List] := Fold[
    Function[{remaining, factor},
      With[{position = FirstPosition[remaining, factor]},
        If[MissingQ[position], remaining, Delete[remaining, position]]
      ]
    ],
    factors,
    shared
  ];
  common = Times @@ shared;
  reduced = Times @@ removeShared[#1] & /@ factorLists;
  {common, reduced}
];

branchSensitiveObjectQ[object_] := MatchQ[
  Unevaluated[object],
  _Cut | _DiracDelta | _Log | _PolyLog | _Hypergeometric2F1 |
    _Gamma | _Pochhammer | _Zeta | _ConditionalExpression | _Piecewise |
    (Power[_, power_] /; ! IntegerQ[power])
];

exactCoefficientNormalize[expression_] := Module[
  {protected, atoms, forward, backward, rational},
  protected = DeleteDuplicates @ Cases[
    Unevaluated[expression],
    object_ /; branchSensitiveObjectQ[object],
    {0, Infinity}
  ];
  atoms = Unique["analytic$"] & /@ protected;
  forward = Dispatch[Thread[protected -> atoms]];
  backward = Dispatch[Thread[atoms -> protected]];
  rational = expression /. forward;
  rational = Cancel[Together[rational]];
  rational /. backward
];

dynamicSimplifyExpressions[
    expressions_List
  ] := Module[
  {
    count, limit, existingKernels, launchedKernels,
    tasks, pending, nextResult, finishedTask, results, value,
    activeKernels, valid, completed, waitForTasks
  },

  count = Length[expressions];
  If[count === 0, Return[{{}, 0}]];
  limit = Min[
    count,
    $ProcessorCount,
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      $ProcessorCount
    ]
  ];
  existingKernels = Kernels[];
  launchedKernels = If[
    Length[existingKernels] < limit,
    LaunchKernels[limit - Length[existingKernels]],
    {}
  ];
  activeKernels = Min[count, Length[Kernels[]]];
  If[activeKernels === 0,
    Return[{
      exactCoefficientNormalize /@ expressions,
      1
    }]
  ];

  DistributeDefinitions[branchSensitiveObjectQ, exactCoefficientNormalize];
  tasks = MapIndexed[
    Function[{expression, position}, With[
      {index = First[position], coefficient = expression},
      ParallelSubmit[{
        index,
        exactCoefficientNormalize[coefficient]
      }]
    ]],
    expressions
  ];
  pending = tasks;
  results = ConstantArray[Missing["Pending"], count];
  valid = True;
  completed = 0;
  waitForTasks[] := While[pending =!= {},
    {nextResult, finishedTask, pending} = WaitNext[pending];
    If[! MatchQ[nextResult, {_Integer, _}],
      valid = False;
      Break[]
    ];
    results[[First[nextResult]]] = Last[nextResult];
    completed++
  ];
  value = CheckAbort[
    Quiet @ Check[
      If[
        TrueQ[$Notebooks],
        Monitor[
          waitForTasks[],
          Column[{
            ProgressIndicator[completed, {0, count}],
            Row[{completed, " / ", count, " master coefficients"}]
          }]
        ],
        waitForTasks[]
      ];
      If[valid, results, $Failed],
      $Failed
    ],
    If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
    Abort[]
  ];
  If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
  If[
    value === $Failed || MemberQ[value, $Failed | $Aborted | _Missing],
    Return[$Failed]
  ];
  {value, activeKernels}
];

parallelSimplifyByMaster[
    parts_Association,
    label_String
  ] := Module[
  {
    coefficientAssociation, masters, coefficients, remainder,
    elapsed, simplified, simplifiedCoefficients, nonzero,
    expressionsForFactor, factorResult, commonPreFactor,
    normalizedExpressions, normalizedCoefficients,
    simplifiedRemainder, coefficientParts, localPreFactors,
    reducedCoefficients, reconstructed, kernelCount
  },
  coefficientAssociation = parts["Terms"];
  masters = Keys[coefficientAssociation];
  coefficients = Values[coefficientAssociation];
  remainder = Lookup[parts, "Remainder", 0];
  If[masters === {},
    simplifiedRemainder = exactCoefficientNormalize[remainder];
    Return[<|
      "PreFactor" -> 1,
      "Masters" -> {},
      "PreFactors" -> {},
      "Coefficients" -> {},
      "Remainder" -> simplifiedRemainder,
      "Expression" -> simplifiedRemainder
    |>]
  ];
  {elapsed, simplified} = AbsoluteTiming[
    dynamicSimplifyExpressions[coefficients]
  ];
  If[simplified === $Failed,
    ibpFail[label, "parallel coefficient simplification failed"]
  ];
  {simplifiedCoefficients, kernelCount} = simplified;
  nonzero = Flatten @ Position[
    simplifiedCoefficients,
    coefficient_ /; ! TrueQ[coefficient === 0],
    {1},
    Heads -> False
  ];
  masters = masters[[nonzero]];
  simplifiedCoefficients = simplifiedCoefficients[[nonzero]];
  simplifiedRemainder = exactCoefficientNormalize[remainder];
  expressionsForFactor = Join[
    simplifiedCoefficients,
    If[TrueQ[simplifiedRemainder === 0], {}, {simplifiedRemainder}]
  ];
  Print["Extracting overall factor"];
  factorResult = ibpStructuralCommonFactor[expressionsForFactor];
  commonPreFactor = First[factorResult];
  normalizedExpressions = Last[factorResult];
  normalizedCoefficients = Take[
    normalizedExpressions,
    Length[simplifiedCoefficients]
  ];
  simplifiedRemainder = If[
    TrueQ[simplifiedRemainder === 0],
    0,
    Last[normalizedExpressions]
  ];
  coefficientParts = CommonFactorSafe /@ normalizedCoefficients;
  localPreFactors = First /@ coefficientParts;
  reducedCoefficients = Last /@ coefficientParts;
  reconstructed =
    Total[MapThread[Times, {
      localPreFactors,
      reducedCoefficients,
      masters
    }]] + simplifiedRemainder;
  Print[
    label, ": ", Length[masters], " masters on ", kernelCount,
    " kernels in ", Round[elapsed, 0.01], " s"
  ];
  <|
    "PreFactor" -> commonPreFactor,
    "Masters" -> masters,
    "PreFactors" -> localPreFactors,
    "Coefficients" -> reducedCoefficients,
    "Remainder" -> simplifiedRemainder,
    "Expression" -> commonPreFactor reconstructed
  |>
];

ibpKiraReductionCore[data_Association] := Module[
  {
    records, equivalence, targets, representativeNames,
    representatives, completed, projectDirectory, project, logPath,
    importedRules, closure, declaredMasters, physicalRules, compactSize
  },
  records = data["Records"];
  If[records === {},
    Return[Join[
      resultHeader["FeynFacet-KiraReduction", 1],
      resultContext[data],
      <|
      "Targets" -> {},
      "Masters" -> {},
      "KiraRules" -> {},
      "ReverseRules" -> {},
      "ReductionRules" -> {},
      "Topologies" -> {},
      "TopologyEquivalence" -> <||>,
      "MassDimensions" -> {},
      "KiraManifest" -> {},
      "KiraProject" -> Missing["NotApplicable"],
      "KiraLog" -> Missing["NotApplicable"]
      |>
    ]]
  ];

  equivalence = TopologyEquivalence[records];
  If[
    ! AssociationQ[equivalence] ||
      equivalence["PhysicalCausalStatus"] =!= "Verified",
    ibpFail["topology equivalence", "classification failed"]
  ];
  targets = DeleteDuplicates[
    data["RawTargets"] /. equivalence["GLIRules"],
    SameQ
  ];
  representativeNames = DeleteDuplicates[First /@ targets];
  representatives = Select[
    equivalence["Representatives"],
    MemberQ[representativeNames, #1["Topology"][[1]]] &
  ];
  If[targets === {} || representatives === {},
    ibpFail["target extraction", "the input contains no GLI targets"]
  ];
  completed = ibpCompleteKinematics[representatives];
  projectDirectory = ibpResetProject[
    FileNameJoin[{data["ResultDirectory"], ".Kira"}],
    data["ResultDirectory"]
  ];
  project = ibpPrepareKiraProject[
    completed["Records"],
    targets,
    projectDirectory,
    completed["MassDimensions"]
  ];
  Print["Running Kira"];
  logPath = ibpRunKira[project];
  Print["Importing Kira rules"];
  importedRules = ibpImportRules[project];
  closure = ibpCloseReductionRules[importedRules, targets];
  declaredMasters = ibpDeclaredMasters[project];
  ibpValidateMasters[
    closure["Masters"],
    declaredMasters,
    completed["Records"]
  ];
  physicalRules = closure["Rules"] /. completed["ReverseRules"];
  compactSize = ByteCount[{
    closure["Rules"],
    physicalRules,
    closure["Masters"],
    completed["Records"]
  }];
  Print @ Grid[
    {
      {"Input integrals", Length[targets]},
      {"Master integrals", Length[closure["Masters"]]},
      {"Reduction data size (kB)", Round[compactSize/1024., 0.01]}
    },
    Frame -> All
  ];
  Join[
    resultHeader["FeynFacet-KiraReduction", 1],
    resultContext[data],
    <|
    "Targets" -> targets,
    "Masters" -> closure["Masters"],
    "DeclaredMasters" -> declaredMasters,
    "KiraRules" -> closure["Rules"],
    "ReverseRules" -> completed["ReverseRules"],
    "ReductionRules" -> physicalRules,
    "Topologies" -> completed["Records"],
    "TopologyEquivalence" -> equivalence,
    "MassDimensions" -> completed["MassDimensions"],
    "KiraManifest" -> project["Manifest"],
    "KiraProject" -> project["Directory"],
    "KiraLog" -> logPath
    |>
  ]
];

KiraReduction[inputs : ({__String} | {__Association})] := Catch[
  Module[{data},
    data = ibpInputData[inputs, True];
    ibpKiraReductionCore[data]
  ],
  $ibpFailure
];

Clear[coefficientSimplificationCore];

coefficientSimplificationCore[inputs_List, kira_Association] := Catch[
  Module[
    {
      data, sortedPairs, equivalence, targetParts, addSource,
      targets, reductionDispatch, physicalParts, unexpectedMasters, assumptions,
      coefficientResult, commonPreFactor, masters,
      coefficientPreFactors, reducedCoefficients, recordByName,
      classByName, masterData, reconstructed, compactSize
    },
    If[
      Lookup[kira, "Format", None] =!= "FeynFacet-KiraReduction",
      Message[CoefficientSimplification::input];
      Throw[$Failed, $ibpFailure]
    ];
    data = ibpInputData[inputs];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= kira["CardName"] ||
        data["ResultDirectory"] =!= kira["ResultDirectory"] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[kira["Pairs"]],
      ibpFail[
        "coefficient input validation",
        "the Kira reduction does not belong to this result set"
      ]
    ];
    equivalence = kira["TopologyEquivalence"];
    Print["Collecting target coefficients"];
    addSource[parts_, source_] := Module[{result, sourceParts},
      result = If[StringQ[source], Quiet @ Check[Get[source], $Failed], source];
      If[! validPreIBPResultQ[result],
        ibpFail["target coefficient collection", "could not read a pre-IBP result"]
      ];
      sourceParts = linearIntegralSum[
        result["PreFactor"] result["Integrand"]
      ];
      If[AssociationQ[equivalence] && KeyExistsQ[equivalence, "GLIRules"],
        sourceParts = linearMapIntegrals[
          sourceParts,
          equivalence["GLIRules"]
        ]
      ];
      linearAdd[{parts, sourceParts}]
    ];
    targetParts = Fold[
      addSource,
      <|"Terms" -> <||>, "Remainder" -> 0|>,
      data["Sources"]
    ];
    targets = Keys[targetParts["Terms"]];
    If[
      Complement[targets, kira["Targets"], SameTest -> SameQ] =!= {} ||
        Complement[kira["Targets"], targets, SameTest -> SameQ] =!= {},
      ibpFail[
        "target coefficient collection",
        "the collected targets differ from the targets reduced by Kira"
      ]
    ];
    Print["Applying Kira rules"];
    reductionDispatch = Dispatch[kira["KiraRules"]];
    Print["Restoring physical kinematics"];
    Print["Collecting master coefficients"];
    physicalParts = linearApplyReduction[
      targetParts,
      reductionDispatch,
      kira["ReverseRules"]
    ];
    unexpectedMasters = Complement[
      Keys[physicalParts["Terms"]],
      kira["Masters"],
      SameTest -> SameQ
    ];
    If[unexpectedMasters =!= {},
      ibpFail[
        "master coefficient collection",
        "the reduction produced a master outside the validated Kira set"
      ]
    ];

    assumptions = ibpAssumptions[data["Setup"]];
    Print["Simplifying master coefficients"];
    coefficientResult = parallelSimplifyByMaster[
      physicalParts,
      "Master coefficients"
    ];
    commonPreFactor = coefficientResult["PreFactor"];
    masters = coefficientResult["Masters"];
    coefficientPreFactors = coefficientResult["PreFactors"];
    reducedCoefficients = coefficientResult["Coefficients"];
    recordByName = Association[
      #1["Topology"][[1]] -> #1 & /@ kira["Topologies"]
    ];
    classByName = If[
      AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
      Association[
        #1["Representative"] -> #1 & /@ equivalence["Classes"]
      ],
      <||>
    ];
    masterData = MapThread[
      Function[{master, coefficientPreFactor, coefficient},
        With[{record = recordByName[master[[1]]]},
          <|
            "Master" -> master,
            "PreFactor" -> coefficientPreFactor,
            "Coefficient" -> coefficient,
            "TopologyName" -> master[[1]],
            "CutMomenta" -> record["CutMomenta"],
            "CutIndices" -> record["CutIndices"],
            "CutDirections" -> record["CutDirections"],
            "AMFlowInfo" -> record["AMFlowInfo"],
            "TopologyClass" -> Lookup[
              classByName,
              master[[1]],
              Missing["NotFound"]
            ]
          |>
        ]
      ],
      {masters, coefficientPreFactors, reducedCoefficients}
    ];
    reconstructed = commonPreFactor (
      Total[
        #1["PreFactor"] #1["Coefficient"] #1["Master"] & /@
          masterData
      ] + coefficientResult["Remainder"]
    );
    If[! TrueQ[Expand[coefficientResult["Expression"] - reconstructed] === 0],
      ibpFail[
        "master coefficient extraction",
        "the stored factors do not reconstruct the simplified expression"
      ]
    ];
    compactSize = ByteCount[{
      commonPreFactor,
      coefficientResult["Remainder"],
      masterData,
      kira["ReductionRules"],
      equivalence
    }];
    Print @ Grid[
      {
        {"Pairs", Length[inputs]},
        {"Topology classes", Length[kira["Topologies"]]},
        {"Input integrals", Length[kira["Targets"]]},
        {"Master integrals", Length[masters]},
        {"Compact result size (kB)", Round[compactSize/1024., 0.01]}
      },
      Frame -> All
    ];
    Join[
      resultHeader["FeynFacet-IBP", 4],
      resultContext[data],
      <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> commonPreFactor,
      "Remainder" -> coefficientResult["Remainder"],
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "Topologies" -> kira["Topologies"],
      "ReductionRules" -> kira["ReductionRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> assumptions,
      "MassDimensions" -> kira["MassDimensions"],
      "KiraManifest" -> kira["KiraManifest"],
      "KiraProject" -> kira["KiraProject"],
      "KiraLog" -> kira["KiraLog"]
      |>
    ]
  ],
  $ibpFailure
];

CoefficientSimplification[
    inputs : ({__Association} | {__String}),
    kira_Association
  ] := coefficientSimplificationCore[inputs, kira];

IBP[inputs : ({__Association} | {__String})] := Module[{reduction},
  reduction = KiraReduction[inputs];
  If[reduction === $Failed,
    $Failed,
    CoefficientSimplification[inputs, reduction]
  ]
];

KiraReduction[___] := (
  Message[KiraReduction::input];
  $Failed
);

CoefficientSimplification[___] := (
  Message[CoefficientSimplification::input];
  $Failed
);

IBP[___] := (
  Message[IBP::input];
  $Failed
);

End[];

Quiet[EndPackage[], General::shdw];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Quiet[
    Block[{FeynCalc`$FeynCalcStartupMessages = False},
      FeynCalc`FCReloadAddOns[{"FeynCalcLegacy"}]
    ],
    General::shdw
  ]
];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Print["FeynFacet: the FeynCalcLegacy add-on is required but could not be loaded."];
  Abort[]
];

Print[
  Style["FeynFacet ", "Text", Bold],
  Style["0.1", "Text"]
];

## Follow-up question

The immediately preceding message contains the complete rewritten FeynFacet source and test evidence, but its generation ended without an assistant response. Do not restate the architecture. Review that source now and return only:

1. concrete correctness defects, with function names and exact fixes;
2. genuinely redundant validation/functions that can be deleted or merged without weakening the physical contract;
3. a prioritized patch list for further source simplification;
4. whether splitting the monolith into a public facade plus private files improves maintainability enough to justify it.

Since sending that source, I made only these mechanical/safe changes: replaced 42 scattered Clear blocks with one public-context and one private-context ClearAll at package entry (net -127 lines), changed the BuildTopologies mass-rule conflict test from PossibleZeroQ to exactZeroQ, and renamed the internal coefficient workers to parallelNormalizeCoefficients and normalizeMasterCoefficients. The full regression matrix still passes.

## Pro response

Not yet production-safe. The rewrite is materially better, and the sparse reduction composition is sound, but several concrete defects remain. The most serious are: mixed +i0/−i0 factors can still be collapsed into one algebraic GLI index, physical source propagators are matched too weakly, external propagator prescriptions are erased, Kira resume/reuse is not bound to an exact input fingerprint, and the final coefficients can contain independent D and Epsilon symbols.

A. Correctness and scientific-contract issues
P0.1 — prepareProcess contains an incorrect head check

Current code:

Wolfram Language
! MatchQ[Head[list], _FeynArts`TopologyList]

Head[list] is normally the symbol FeynArtsTopologyList. The pattern _FeynArtsTopologyList matches an expression whose head is FeynArtsTopologyList`, not the symbol itself.

Use either:

Wolfram Language
Head[list] =!= FeynArts`TopologyList

or:

Wolfram Language
! MatchQ[list, _FeynArts`TopologyList]

Therefore:

Wolfram Language
If[
  ! MatchQ[list, _FeynArts`TopologyList] ||
    side["DiagramIndex"] > Length[list],
  fail[...]
];

Add a direct regression on the actual object returned by GenerateDiagram:

Wolfram Language
VerificationTest[
  MatchQ[diagrams["Amplitude"], _FeynArts`TopologyList],
  True
]

Even if the current full-pipeline test happens to pass through an evaluation peculiarity or a slightly different local definition, the pasted predicate is structurally wrong.

P0.2 — Opposite causal prescriptions can be collapsed into one GLI power

This is the main scientific issue.

In factorizePair, amplitude and conjugate denominators are initially retained separately:

Wolfram Language
sidePropagators["Amplitude"]    (* +i0 *)
sidePropagators["Conjugate"]    (* -i0 *)

but then all ordinary propagators are normalized to +i0:

Wolfram Language
propagators = loopCuts setDenominatorEta[ordinaryPropagators, 1];

Suppose the same denominator core occurs on both sides:

D+i0
1
	​

D−i0
1
	​

.

After the normalization this becomes algebraically indistinguishable from

(D+i0)
2
1
	​

.

A single GLI index a
i
	​

=2 cannot record that the two factors originally carried opposite prescriptions. PropagatorData["Physical"]["Factors"] currently permits both factors to be attached to one topology slot, but the dimensional shift, Kira reduction, and resulting master index no longer know how the power is split between the two prescriptions.

This is not repaired by preserving the multiset in metadata. Mixed-prescription powers form a different integral object and can be pinch-sensitive.

Required fail-closed patch

Before setDenominatorEta[ordinaryPropagators, 1], group all loop-dependent ordinary source factors by their exact unit-power denominator core. For each group require:

Wolfram Language
Length[
  DeleteDuplicates[Lookup[group, "PhysicalEtaSign"], SameQ]
] === 1

Otherwise fail with a stage-specific message such as:

Wolfram Language
CollinearFactorize::mixedeta =
  "The denominator core `1` occurs with both +i0 and -i0 prescriptions. \
It cannot be represented by one ordinary GLI index.";

Also require this invariant in topologyRecordQ:

Wolfram Language
validUncutPhysicalQ[physical_] := Module[{etas},
  etas = DeleteDuplicates[
    Lookup[physical["Factors"], "PhysicalEtaSign"],
    SameQ
  ];
  Length[etas] === 1
];

Do not permit a topology record with one uncut slot containing both signs until there is a dedicated mixed-prescription integral representation.

Cut–ordinary collisions must also fail

If the same denominator core occurs both as:

Wolfram Language
Cut[SPD[q], direction]

and as an ordinary propagator, PartialFraction replaces the cut by an ordinary FAD[q]. The powers then become indistinguishable and restoreCutTerm restores the entire combined power as a cut.

Add a preflight check in PartialFraction:

Wolfram Language
cutOrdinaryCoreCollisionQ[expr_, cutRecords_]

that compares every cut core with every ordinary denominator core before algebraization. If one matches, fail. Do not silently reinterpret

δ
+
	​

(D)
D+i0
1
	​


as a dotted cut.

P0.3 — topologyPropagatorData can assign false physical provenance

Current matching:

Wolfram Language
matches = Select[
  sourceData,
  #["Algebraic", "Type"] === algebraic["Type"] &&
    sameMomentumQ[
      #["Algebraic", "Momentum"],
      algebraic["Momentum"]
    ] &
];

This is insufficient.

It ignores:

mass terms;

linear/eikonal scalar products;

additive denominator terms;

actual denominator polynomial;

actual stored eta sign;

propagator normalization.

It is particularly incorrect for linear propagators. topologyPropagatorInfo obtains "Momentum" through propagatorMomentum, which reads the first field of StandardPropagatorDenominator. For a linear/eikonal propagator, that first field is normally zero and the actual scalar product is held in the second field. Consequently, distinct linear denominators can all appear to have momentum 0 and can all match each other. FeynCalc’s standard propagator representation explicitly places eikonal scalar products in that separate linear field. 
FeynCalc
+1

The same problem occurs for two quadratic propagators with the same momentum but different masses.

Required replacement

Create one canonical propagator parser and include a unit-power core:

Wolfram Language
topologyPropagatorDescriptor[propagator_, kinematics_: {}] := Module[
  {internal, denominator, type, power, eta, unitPropagator, unitCore},

  internal = FeynCalc`FCI[propagator];

  denominator = FirstCase[
    internal,
    d_FeynCalc`StandardPropagatorDenominator :> d,
    Missing["NotFound"],
    Infinity
  ];

  If[MissingQ[denominator], Return[$Failed]];

  power = denominator[[4, 1]];
  eta = denominator[[4, 2]];

  unitPropagator = internal /. HoldPattern[
      FeynCalc`StandardPropagatorDenominator[
        q_, sp_, mass_, {_, eta0_}
      ]
    ] :>
      FeynCalc`StandardPropagatorDenominator[
        q, sp, mass, {1, eta0}
      ];

  unitCore = topologyPropagatorCore[
    unitPropagator,
    {},
    kinematics
  ];

  If[unitCore === $Failed, Return[$Failed]];

  <|
    "Type" -> type,
    "Power" -> power,
    "EtaSign" -> eta,
    "UnitCore" -> unitCore
  |>
];

The source-to-topology match must then require:

Wolfram Language
source["Descriptor", "Type"] === target["Type"] &&
exactZeroQ[
  source["Descriptor", "UnitCore"] - target["UnitCore"]
]

For a quadratic propagator, q and −q naturally have the same unit core. For a linear propagator they generally do not, which is the correct behavior.

Also verify source metadata rather than trusting the supplied sign:

Wolfram Language
source["Descriptor", "EtaSign"] === source["PhysicalEtaSign"]

At present, propagatorSources sets "PhysicalEtaSign" from its argument but never checks it against the actual converted propagator.

Reject legacy PropagatorDenominator in production records

The legacy FAD/PropagatorDenominator form does not carry an iη sign, while SFAD/StandardPropagatorDenominator does. Treating a legacy propagator as though FCLoopGetEtaSigns had established physical causality is not fail-closed. 
FeynCalc
+1

topologyRecordQ should require every production topology slot to use StandardPropagatorDenominator. Legacy FAD can remain an internal temporary representation inside PartialFraction, where the cut orientation is separately held, but it should not enter a certified topology record.

P0.4 — External propagator eta signs are erased in factorizePair

Current code:

Wolfram Language
preFactor = Factor[
  phase["Prefactor"] loopNormalizationFactor preFactor
    FeynCalc`FeynAmpDenominatorExplicit[
      externalPropagators,
      ...
    ]
];

externalPropagators contains amplitude and conjugate denominators with explicit +i0 and −i0, but FeynAmpDenominatorExplicit converts them to ordinary rational denominator cores. FeynCalc’s own examples show that propagators with opposite eta signs produce the same explicit rational expression after this conversion. 
FeynCalc
+1

Therefore the output currently preserves causal prescriptions only for loop-dependent topology data, not for loop-independent propagators in PreFactor.

Required patch

Keep the external propagators in SFAD form:

Wolfram Language
preFactor =
  phase["Prefactor"] loopNormalizationFactor preFactor
    externalPropagators /.
      FeynCalc`SMP["g_s"] -> Sqrt[4 Pi \[Alpha]s];

Then apply a branch-safe/common-factor routine that treats FAD/SFAD as inert atoms.

Also store:

Wolfram Language
"ExternalPropagatorData" -> {
  <|
    "Role" -> "Amplitude",
    "PhysicalEtaSign" -> 1,
    "Descriptor" -> ...
  |>,
  ...
}

inside the internal FactorizedPair and the saved pre-IBP artifact.

If a rationalized external prefactor is required for display, make it a separately derived field and only construct it after proving that the relevant cores cannot vanish in the declared physical region. Do not silently discard the eta signs.

P0.5 — Kira resume can import stale reductions

Current resume logic in ibpRunKira is:

Wolfram Language
If[
  TrueQ[Global`$FACETResumeKira] &&
    AllTrue[resultPaths, FileExistsQ],
  Return[logPath]
];

This can reuse an existing reduction after changing:

topology propagators;

cut indices;

target list;

kinematic rules;

generated ffsp invariants;

integral ordering;

Kira settings;

package code;

FeynCalc/FeynHelpers/Kira versions.

The files can exist and still belong to a different exact problem.

Required patch

Construct a canonical reduction input payload containing at least:

Wolfram Language
HoldComplete @ <|
  "SchemaVersion" -> ...,
  "Topologies" -> canonicalized topology records,
  "Targets" -> canonical sorted target list,
  "CutIndices" -> ...,
  "KinematicRules" -> ...,
  "MassDimensions" -> ...,
  "IntegralOrdering" -> 2,
  "KiraExecutable" -> canonical path,
  "KiraVersion" -> ...,
  "FeynCalcVersion" -> ...,
  "FeynHelpersVersion" -> ...
|>

Store both the payload and a SHA-256 fingerprint in the project directory.

Resume only if:

Wolfram Language
SameQ[storedPayload, currentPayload]

and all expected result files exist.

A hash alone is useful for quick comparison, but retaining the exact payload makes mismatches auditable.

The same fingerprint must be checked in coefficientSimplificationCore

Current validation only compares:

Wolfram Language
CardName
ResultDirectory
Pairs

and later compares bare GLI targets.

That does not prevent applying a table generated for different propagator definitions that reused the same topology names and GLI indices.

Store:

Wolfram Language
"ReductionInputFingerprint" -> ...

in the Kira artifact, recompute it from data["Records"] and the collected target set, and require exact equality before applying any rule.

This also resolves the unsafe reliance on card name and directory as scientific identifiers.

P0.6 — D and Epsilon are not unified

DimensionalShift and the amplitude algebra produce coefficients involving D.

ibpImportRules imports Kira coefficients using:

Wolfram Language
Global`d -> 4 - 2 Global`Epsilon

No subsequent code replaces D.

Therefore a final coefficient can contain both:

Wolfram Language
D
Global`Epsilon

as mathematically independent symbols.

Unless an external session value happens to relate them—which this package neither sets nor records—the result is not a single exact function of the regulator.

Required patch

Use one convention throughout.

The cleaner option is to import Kira in D:

Wolfram Language
FeynCalc`FCReplaceD -> {
  Symbol["Global`d"] -> D
}

Then, after sparse IBP composition and before final coefficient normalization, apply exactly once:

Wolfram Language
dimensionRule = D -> 4 - 2 epsilonSymbol;

to all coefficients and the remainder.

Add:

Wolfram Language
linearMapCoefficients[data_, function_] := <|
  "Terms" -> Map[function, data["Terms"]],
  "Remainder" -> function[data["Remainder"]]
|>;

and then:

Wolfram Language
physicalParts = linearMapCoefficients[
  physicalParts,
  ReplaceAll[dimensionRule]
];

Store:

Wolfram Language
"DimensionRule" -> dimensionRule

in the Kira and final IBP artifacts.

Add a final invariant:

Wolfram Language
FreeQ[finalExpression, D]

when the selected output convention is epsilon. Also choose one exact epsilon symbol; do not mix GlobalEpsilon` with a FeynCalc or package-context epsilon.

P0.7 — Cut identity is not represented

A cut currently carries:

topology slot;

line momentum;

energy direction.

It does not carry an immutable identity such as:

originating outgoing leg;

particle species;

observed versus unobserved role;

measurement role;

fragmentation/jet assignment;

declared cut-symmetry class.

Consequently, TopologyEquivalence can exchange two cuts whenever their momenta transform appropriately and their directions agree, even if the process distinguishes them physically.

Required patch

buildPhaseData should return cut descriptors, not only a product:

Wolfram Language
"CutSources" -> {
  <|
    "CutID" -> ...,
    "OriginalMomentum" -> ...,
    "LineMomentum" -> ...,
    "Parton" -> ...,
    "MeasurementRole" -> ...,
    "EnergyReference" -> ...,
    "EnergyDirection" -> 1
  |>,
  ...
}

Attach the descriptor to PropagatorData for each cut slot.

topologyPhysicalSignature may drop LineMomentum and EnergyDirection, because those are checked separately, but it must retain:

Wolfram Language
"CutID"
"Parton"
"MeasurementRole"
"EnergyReference"

unless an explicit process-level symmetry authorizes exchanging them.

Without this, "PhysicalCausalStatus" -> "Verified" is stronger than what was actually verified.

P0.8 — The public in-memory result path is internally inconsistent

GenerateCollinearFactorizePreIBPResult does not store:

Wolfram Language
"ResultDirectory"

but ibpInputSummary requires it for an in-memory association:

Wolfram Language
directory = Lookup[result, "ResultDirectory", Missing[]];

If[! StringQ[directory] || ! DirectoryQ[directory],
  directory = If[StringQ[file], ..., $Failed]
];

Therefore:

Wolfram Language
KiraReduction[{
  GenerateCollinearFactorizePreIBPResult[...]
}]

fails unless some external code mutates the result association.

Required patch

Make "ResultDirectory" an explicit required artifact field, supplied through the setup or an option to GenerateCollinearFactorizePreIBPResult.

Remove the fallback:

Wolfram Language
DirectoryName[DirectoryName[file]]

Inferring a scientific project directory from file placement is not fail-closed.

Additional P1 correctness patches
1. Protect all analytic objects, not a whitelist

branchSensitiveObjectQ does not cover:

the custom heads from Distributions.wl;

FeynCalc FCHPL, FCGPL, or other iterated-integral heads;

HypergeometricPFQ;

Appell functions;

MeijerG;

Exp, inverse trigonometric functions, Abs, Sign, HeavisideTheta;

future exact master-function heads.

The source claims distributions are inertized, but the predicate has no connection to Distributions.wl.

Use a shared registry:

Wolfram Language
$feynFacetDistributionHeads = {...};
$feynFacetAnalyticHeads = Join[
  $feynFacetDistributionHeads,
  {
    Cut,
    DiracDelta,
    Log,
    PolyLog,
    ...
  }
];

Better still, protect every non-arithmetic functional object and allow only the rational shell:

integers and rationals;

symbols;

Plus;

Times;

integer powers.

Every other head should be treated as an atomic coefficient object.

Use the same protection mechanism in:

Wolfram Language
exactCoefficientNormalize
CommonFactorSafe

and the final construction of the process prefactor.

The two-level common-factor format should remain exactly as requested; the patch is to make both levels branch-safe, not to remove them.

Add an invariant comparing the exact multiset of protected analytic objects before and after normalization.

2. DimensionalShift must reject overdetermined public inputs

The single-family form checks validity and incompleteness but not:

Wolfram Language
FCLoopBasisOverdeterminedQ

Add:

Wolfram Language
overdetermined = Quiet @ CheckAbort[
  FeynCalc`FCLoopBasisOverdeterminedQ[topology],
  $Failed
];

If[
  ! TrueQ[valid] ||
    incomplete =!= False ||
    overdetermined =!= False,
  ...
]

Families built internally already pass this check, but the public API currently accepts a direct topology.

3. Require eta-normalized algebraic records explicitly

The design is clearer if every Kira-facing algebraic topology satisfies:

Wolfram Language
AllTrue[
  Lookup[propagatorInfo, "EtaSign"],
  SameQ[#, 1] &
]

Physical eta signs then live only in PropagatorData.

Currently topologyRecordQ allows any algebraic eta value as long as the record is otherwise consistent. That weakens the claimed separation between algebraic topology and physical prescription.

4. Persist the BMHV and analytic context

The normalized process contains:

Wolfram Language
"SetEvanescentZero"
"SetMassZero"
"Assumptions"

and depends on the installed global basis, but the pre-IBP artifact stores only the raw setup.

The actual BMHV context used in the calculation should be stored:

Wolfram Language
"AnalyticContext" -> <|
  "Gamma5Scheme" -> ...,
  "GlobalBasis" -> globalBasis,
  "GlobalBasisGram" -> GlobalBasisGram,
  "SetEvanescentZero" -> process["SetEvanescentZero"],
  "LoopDimension" -> D,
  "DimensionRule" -> ...,
  "CutConvention" -> ...,
  "DistributionConvention" -> ...
|>

Give it a fingerprint and propagate it to the final artifact.

The scalar IBP table may be reusable across BMHV contexts after the evanescent numerator has been eliminated, but the hard-function artifact must retain which context produced its coefficients.

5. BuildGlobalBasis validates after mutating global state

Current order:

Wolfram Language
globalBasis = basis;
internalSetEvanescentZero = ...;
declareGlobalBasis[basis];
BuildBasis[basis]

This overwrites scalar products and then checks the values it just installed. It cannot detect a conflicting preexisting basis assignment, and a failure would leave global state mutated.

Use:

inspect existing assigned scalar products;

reject incompatible existing values;

construct and validate the proposed relation table locally;

install the relations;

assign globalBasis and internalSetEvanescentZero.

At minimum, commit global state only after all checks succeed.

6. Replace remaining heuristic zero tests

The rewrite introduced exactZeroQ, but the following still use PossibleZeroQ:

Wolfram Language
DeclareScalar
BuildTopologies   (* mass-rule conflict *)

For production exactness, use:

Wolfram Language
exactZeroQ

where the expression belongs to the supported rational grammar. Otherwise prefer a conservative false result rather than a heuristic positive zero determination.

Also merge:

Wolfram Language
momentumRelativeSign
topologyMomentumSign

into one exact momentum-sign function based on exactZeroQ.

7. Version the changed schemas

The topology-record schema is version 2, but the outer pre-IBP result is still:

Wolfram Language
"FormatVersion" -> 1

and validPreIBPResultQ does not inspect the version.

This allows two incompatible schemas to carry the same format/version pair.

Required changes:

Wolfram Language
"FeynFacet-CollinearFactorizePreIBP", 2
"FeynFacet-KiraReduction", 2

if the Kira artifact gains fingerprints and context.

Each validator must require a supported exact version. Older files should pass through an explicit migration function or fail with a version-specific message.

8. Add per-master physical data directly

Final masterData contains:

Wolfram Language
"AMFlowInfo"
"CutMomenta"
"CutIndices"
"CutDirections"

but not:

Wolfram Language
"PropagatorData"

Per-loop AMFlow labels are not a substitute for per-propagator physical eta signs.

Add:

Wolfram Language
"PropagatorData" -> record["PropagatorData"],
"PhysicalSignature" -> topologyRecordPhysicalSignature[record]

to each master entry. Keeping the full topologies at artifact level is useful, but each master record should remain causally interpretable when inspected independently.

B. Redundant code and validation passes

The source reduction is modest because several old and new paths coexist.

Highest-value merges
Current functions	Concrete merge
propagatorMomentum, propagatorPower, topologyPropagatorInfo, extraction inside propagatorSources	One parsePropagatorDescriptor returning type, power, eta, unit core, and display momentum
momentumRelativeSign, sameMomentumQ, topologyMomentumSign	One exact momentumSign plus one Boolean wrapper
topologyAmplitudeTag, selectedPairFromSetup	One selectedDiagramPair/pair accessor
safeTopologyRecordQ, topologyRecordQ	Make topologyRecordQ internally quiet and exception-safe; delete wrapper
inferFractionAssumptions, ibpAssumptions	One fraction-assumption constructor
BuildTopologies partial record plus completeTopologyRecord	Private constructor builds a full record once; public BuildTopologies projects the legacy subset
Repeated dimensionalShiftParameterPosition calls	Store BaseGLI, cut-slot map, and active parameter-slot map in the completed topology record
Repeated FCLoopCreateRulesToGLI	Cache once per topology in a runtime association
linearNormalize immediately after dimensional shifting	Remove, or restrict it to exact zero pruning; coefficient normalization belongs after IBP
Fixed causalStatus = "Verified" and trusted AMFlow status field	Derive status from validation; do not store a self-declared verified flag in input metadata
Empty/nonempty Kira result assembly	One makeKiraReductionArtifact[data_, payload_] constructor
Repeated raw setup validation in GenerateDiagram, normalizeAmplitudeSides, and factorizePair	Private pre-IBP orchestration normalizes once and passes the normalized process to diagram generation and factorization
Process normalization is not yet truly once-per-pre-IBP call

CollinearFactorizePreIBP currently:

calls GenerateDiagram, which validates the amplitude setups;

calls factorizePair, which calls normalizeProcess;

normalizeProcess calls normalizeAmplitudeSides, which validates the same amplitude setups again.

Refactor private orchestration to:

Wolfram Language
process = normalizeProcess[config];
diagrams = generateDiagrams[process, config["FeynArts"...]];
prepared = prepareProcess[process, diagrams];
factorized = factorizePreparedProcess[prepared];

Public GenerateDiagram and CollinearFactorize can remain compatibility wrappers that normalize independently.

Keep the dynamic scheduler

Given the observed Linux deadlock with shared progress under ParallelMap, retaining the ParallelSubmit/WaitNext scheduler is reasonable. It is already the only worker-pool implementation in the current source.

Two small fixes remain:

if more kernels already exist than $FACETKernelLimit, the current scheduler can use more than the requested limit;

a worker result containing Failure[...] is accepted by the pattern {_Integer,_}.

At least add:

Wolfram Language
If[
  ! MatchQ[nextResult, {_Integer, _}] ||
    FailureQ[Last[nextResult]],
  valid = False;
  Break[]
];

Document that the limit applies only to kernels launched by FeynFacet unless you implement an isolated subkernel pool.

C. Sparse LinearIntegralSum and eta-normalized topology assessment
Sparse composition

The sparse design is correct.

In particular:

Wolfram Language
linearMapIntegrals

maps only GLI keys and merges collisions, while:

Wolfram Language
linearApplyReduction

distributes each source coefficient over one closed reduction image and merges the resulting masters. This is algebraically equivalent to whole-expression replacement but avoids constructing and recollecting the complete intermediate expression.

The reconstruction check in linearIntegralSum correctly rejects nonlinear uses such as:

products of GLIs;

inverse GLIs;

GLIs inside unsupported functions.

Small improvements

Canonically sort GLI keys before serialization and fingerprinting.

Remove exact zero terms after every merge:

Wolfram Language
linearDropZeros[data_] := <|
  "Terms" -> Select[data["Terms"], ! exactZeroQ[#] &],
  "Remainder" -> data["Remainder"]
|>;

Use level-zero replacement consistently:

Wolfram Language
Replace[key, rules, {0}]

instead of key /. rules.

Remove pre-IBP linearNormalize unless a benchmark demonstrates a benefit. It currently performs Cancel[Together] on all shifted coefficients before Kira even though the design goal was to delay coefficient normalization.

Bind every sparse sum to a family/context fingerprint when it crosses an artifact boundary.

Add a validator that post-shift coefficients are free of:

loop momenta;

FAD, SFAD, GFAD, CFAD;

loop-dependent SP, SPD, SPE;

machine real numbers.

Eta-normalized algebraic topologies plus physical metadata

The split is conceptually sound under one essential invariant:

Each algebraic propagator slot must correspond to exactly one physical causal class.
	​


Multiple same-sign factors are acceptable; they correspond to an ordinary dotted propagator. Mixed signs are not.

The completed topology record should therefore contain a slot-level structure such as:

Wolfram Language
"Physical" -> <|
  "Role" -> "Uncut",
  "CausalSide" -> 1,
  "PhysicalEtaSign" -> 1,
  "Sources" -> {...}
|>

rather than deriving the slot’s causal class only from an unrestricted factor list.

For cuts, the slot-level structure should include immutable cut identity and energy-reference metadata.

Once those invariants are enforced, Kira can legitimately see eta-normalized algebraic families while the physical master records retain the causal interpretation.

D. Facade plus private files

Splitting the package would materially improve maintainability, but only after the consolidations above. It will not by itself reduce scientific complexity.

The current file has:

forward references to symbols defined thousands of lines later;

several independent failure domains;

topology, process, dimensional-shift, and Kira code interleaved;

global state and backend state in the same private context.

A practical split is:

FeynFacet.wl
Private/
  Core.wl
  ProcessAndDiagrams.wl
  CutsAndTopologies.wl
  DimensionalShift.wl
  LinearReduction.wl
  KiraBackend.wl

FeynFacet.wl should contain only:

usages;

syntax information;

options;

public compatibility wrappers;

package loading;

dependency/version checks.

The split is worthwhile because it establishes explicit dependency direction:

Core
  ↓
ProcessAndDiagrams
  ↓
CutsAndTopologies
  ↓
DimensionalShift
  ↓
LinearReduction
  ↓
KiraBackend

Do not introduce separate schema validators or worker pools in each file. All files can remain in the same FeynFacetPrivate`` context initially.

The split should occur after the P0 fixes, otherwise it would make a causal bug or stale-cache bug harder to patch across files.

F. Prioritized patch list
Blocking before production

Fix prepareProcess

Wolfram Language
MatchQ[list, _FeynArts`TopologyList]

Reject mixed-prescription core collisions and cut–ordinary collisions
in factorizePair, PartialFraction, topologyPropagatorData, and topologyRecordQ.

Replace source matching by exact unit-core matching
in topologyPropagatorInfo, propagatorSources, and topologyPropagatorData. Reject legacy causally ambiguous PropagatorDenominator records.

Preserve external propagator eta signs
by removing FeynAmpDenominatorExplicit[externalPropagators] from the physical prefactor path.

Add an exact Kira input fingerprint
and require it for both resume and CoefficientSimplification.

Unify D and the chosen epsilon symbol
and record the exact dimension rule.

Add immutable cut identity/measurement metadata
and include it in topology-equivalence certification.

Store an explicit ResultDirectory
in generated pre-IBP artifacts; remove directory inference.

Next correctness and reproducibility pass

Replace the analytic-function whitelist with a shared rational-shell protector used by both exactCoefficientNormalize and CommonFactorSafe.

Persist the BMHV/global-basis/branch/distribution context and its fingerprint.

Require algebraic topology eta signs to be normalized and add the missing overdetermined check in public DimensionalShift.

Bump and enforce artifact format versions.

Add PropagatorData directly to each final master record.

Make BuildGlobalBasis validate before mutating global state.

Replace remaining PossibleZeroQ uses in production validation.

Source reduction and maintainability

Merge the four propagator parsers into one descriptor function.

Build complete topology records directly in the private pipeline; retain the current BuildTopologies output only through a compatibility projection.

Cache topology-to-GLI rules and parameter-slot maps.

Remove pre-IBP linearNormalize, prune exact zero sparse terms, and impose deterministic GLI-key ordering.

Normalize the process once in the private pre-IBP orchestration.

Split into the facade plus the six private files above.

The existing regression suite is strong for affine mappings and ordinary cut-aware topology equivalence. It should now be extended specifically with:

one core carrying both +i0 and −i0;

a cut and ordinary propagator sharing one core;

two distinct eikonal denominators;

equal momentum with unequal masses;

external amplitude/conjugate propagators surviving in PreFactor;

a stale Kira project with changed cuts or targets;

a same-name GLI family with changed propagators;

a final expression that would otherwise contain both D and Epsilon;

two algebraically exchangeable cuts with different measurement identities;

custom distribution and GPL objects passing unchanged through both common-factor levels.
