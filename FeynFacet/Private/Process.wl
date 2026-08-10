(* Process normalization, diagram generation, and phase-space routing. *)

GenerateDiagram::setup =
  "Setup must contain ForwardAmplitudes, ConjugateAmplitudes, Partons, Model, InsertionLevel, ExcludeTopologies and ExcludeParticles. Received `1`.";

GenerateDiagram::amplitudes =
  "`1` must contain LoopOrder, LoopMomenta and a nonempty list of positive DiagramIndices; SelectedIndex is optional and must belong to DiagramIndices. Received `2`.";

GenerateDiagram::index =
  "`1` contains diagram index `2`, but only `3` diagrams were generated.";


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
    "SetMassZero",
    "HadronicVariables",
    "CoefficientKinematics",
    "KinematicMassDimensions"
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

selectedPairFromSetup[setup_Association] := Module[{indices},
  indices = Lookup[Lookup[setup, #, <||>], "SelectedIndex", Missing[]] & /@
    {"ForwardAmplitudes", "ConjugateAmplitudes"};
  If[
    AllTrue[indices, IntegerQ[#] && Positive[#] &],
    AssociationThread[{"Forward", "Conjugate"}, indices],
    $Failed
  ]
];

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

fail[field_, value_, reason_] := (
  Message[CollinearFactorize::invalid, field, value, reason];
  Throw[$Failed, $collinearFailure]
);


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


inferFractionAssumptions[momentumFractions_] := Module[{fractions},
  fractions = DeleteDuplicates @ Cases[
    momentumFractions,
    fraction_Symbol /; fraction =!= NA,
    Infinity
  ];
  And @@ ((0 < # < 1) & /@ fractions)
];

emptyHadronicVariables[] := <|
  "Coordinates" -> <||>,
  "Assumptions" -> True
|>;

normalizeHadronicVariables[value_] := Module[
  {coordinates, assumptions},
  If[value === Missing["NotAvailable"], Return[emptyHadronicVariables[]]];
  If[
    ! AssociationQ[value] ||
      Sort[Keys[value]] =!= Sort[{"Coordinates", "Assumptions"}],
    fail[
      "HadronicVariables",
      value,
      "Expected an Association with Coordinates and Assumptions."
    ]
  ];
  coordinates = value["Coordinates"];
  assumptions = value["Assumptions"];
  If[
    ! AssociationQ[coordinates] ||
      ! AllTrue[Keys[coordinates], MatchQ[#, _Symbol] &] ||
      ! AllTrue[Values[coordinates], ListQ[#] && Length[#] === 4 &],
    fail[
      "HadronicVariables",
      value,
      "Coordinates must map vector symbols to four global-basis coefficients."
    ]
  ];
  If[! exactDataQ[{coordinates, assumptions}],
    fail[
      "HadronicVariables",
      value,
      "Hadronic kinematics must contain exact analytic data only."
    ]
  ];
  <|
    "Coordinates" -> coordinates,
    "Assumptions" -> assumptions
  |>
];

hadronicVariableRules[value_Association] := KeyValueMap[
  #1 -> Build4Vec[#2, globalBasis] &,
  value["Coordinates"]
];

inferPartonCoordinates[
    config_Association,
    hadronic_Association
  ] := Module[
  {
    partonSides, hadronSides, fractionSides, coordinates,
    inferSide
  },
  If[
    ! AllTrue[
      {"PartonMomentum", "HadronMomentum", "MomentumFraction"},
      KeyExistsQ[config, #] &
    ],
    Return[hadronic]
  ];
  partonSides = List @@ config["PartonMomentum"];
  hadronSides = List @@ config["HadronMomentum"];
  fractionSides = List @@ config["MomentumFraction"];
  If[
    ! And[
      Length[partonSides] === 2,
      Length[hadronSides] === 2,
      Length[fractionSides] === 2,
      Length /@ partonSides === Length /@ hadronSides,
      Length /@ partonSides === Length /@ fractionSides
    ],
    Return[hadronic]
  ];
  coordinates = hadronic["Coordinates"];
  inferSide[side_Integer, scaleFunction_] := MapThread[
    Function[{parton, hadron, fraction},
      If[
        MatchQ[parton, _Symbol] &&
          MatchQ[hadron, _Symbol] &&
          ! MissingQ[fraction] &&
          KeyExistsQ[coordinates, hadron],
        parton -> (scaleFunction[fraction] coordinates[hadron]),
        Nothing
      ]
    ],
    {partonSides[[side]], hadronSides[[side]], fractionSides[[side]]}
  ];
  Append[
    hadronic,
    "Coordinates" -> Join[
      Association @ Join[
        inferSide[1, Identity],
        inferSide[2, Function[fraction, 1/fraction]]
      ],
      coordinates
    ]
  ]
];

applyHadronicVariables[expr_, value_Association] := Module[{rules, result},
  If[value["Coordinates"] === <||>, Return[expr]];
  rules = hadronicVariableRules[value];
  result = FeynCalc`ExpandScalarProduct[
    expr /. rules,
    EpsEvaluate -> True
  ];
  ToFeynFacetForm[result]
];

cardHadronicVariables[config_Association] := inferPartonCoordinates[
  config,
  normalizeHadronicVariables[
    Lookup[config, "HadronicVariables", Missing["NotAvailable"]]
  ]
];

cardAssumptions[config_Association, hadronic_Association] := Module[
  {coefficientAssumptions},
  coefficientAssumptions = coefficientKinematicsAssumptions[config];
  If[coefficientAssumptions === $Failed, Return[$Failed]];
  inferFractionAssumptions[Lookup[config, "MomentumFraction", {}]] &&
    hadronic["Assumptions"] && coefficientAssumptions
];

(* Process cards are a supported convenience form for the public simplifiers. *)
SimplifyAssum[expr_, config_Association] := Module[
  {hadronic, reduced, assumptions},
  hadronic = cardHadronicVariables[config];
  reduced = applyHadronicVariables[expr, hadronic];
  If[reduced === $Failed, Return[$Failed]];
  assumptions = cardAssumptions[config, hadronic];
  If[assumptions === $Failed, Return[$Failed]];
  Simplify[reduced, Assumptions -> assumptions]
];

FullSimplifyAssum[expr_, config_Association] := Module[
  {hadronic, reduced, assumptions},
  hadronic = cardHadronicVariables[config];
  reduced = applyHadronicVariables[expr, hadronic];
  If[reduced === $Failed, Return[$Failed]];
  assumptions = cardAssumptions[config, hadronic];
  If[assumptions === $Failed, Return[$Failed]];
  FullSimplify[reduced, Assumptions -> assumptions]
];

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
      Head[Head[list]] =!= FeynArts`TopologyList ||
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
    fractionAssumptions, hadronicVariables, coefficientKinematics,
    massDimensions
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
  If[! exactDataQ[config],
    fail[
      "Setup",
      config,
      "Scientific input must contain exact numbers only."
    ]
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
  hadronicVariables = cardHadronicVariables[config];

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
      ! AllTrue[
        zeroDistributions,
        Function[specification,
          MemberQ[$twist2DistributionHeads, specification] ||
            MemberQ[$twist2DistributionHeads, Head[specification]]
        ]
      ],
    fail[
      "SetDistributionZero",
      zeroDistributions,
      "Expected twist-2 distribution heads or exact distribution objects."
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

  massDimensions = Lookup[config, "KinematicMassDimensions", <||>];
  If[
    ! AssociationQ[massDimensions] ||
      ! AllTrue[Keys[massDimensions], MatchQ[#, _Symbol] &] ||
      ! AllTrue[Values[massDimensions], IntegerQ],
    fail[
      "KinematicMassDimensions",
      massDimensions,
      "Expected an Association from invariant symbols to integer mass dimensions."
    ]
  ];
  coefficientKinematics = normalizeCoefficientKinematics[
    Lookup[config, "CoefficientKinematics", Missing["NotAvailable"]],
    massDimensions
  ];
  If[coefficientKinematics === $Failed,
    fail[
      "CoefficientKinematics",
      Lookup[config, "CoefficientKinematics", Missing["NotAvailable"]],
      "The coefficient coordinate declaration is invalid."
    ]
  ];
  fractionAssumptions =
    inferFractionAssumptions[Lookup[config, "MomentumFraction"]] &&
      hadronicVariables["Assumptions"] &&
      coefficientKinematics["PhysicalRegion"];

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
    "HadronicVariables" -> hadronicVariables,
    "CoefficientKinematics" -> coefficientKinematics,
    "KinematicMassDimensions" -> massDimensions,
    "Assumptions" -> fractionAssumptions
  |>
];


analyticContext[process_Association] := Module[{scheme, context},
  scheme = Quiet @ Check[FeynCalc`FCGetDiracGammaScheme[], $Failed];
  If[scheme =!= "BMHV", Return[$Failed]];
  context = <|
    "Gamma5Scheme" -> scheme,
    "GlobalBasis" -> globalBasis,
    "GlobalBasisGram" -> GlobalBasisGram,
    "SetEvanescentZero" -> process["SetEvanescentZero"],
    "SetMassZero" -> process["SetMassZero"],
    "SetDistributionZero" -> process["SetDistributionZero"],
    "CollinearRelations" -> collinearRelations[process],
    "HadronicVariables" -> process["HadronicVariables"],
    "CoefficientKinematics" -> process["CoefficientKinematics"],
    "Assumptions" -> process["Assumptions"],
    "KinematicMassDimensions" -> process["KinematicMassDimensions"],
    "LoopDimension" -> System`D,
    "DimensionRule" -> $dimensionRule,
    "CutConvention" -> "OrientedPositiveEnergyDelta",
    "DistributionConvention" -> "FeynFacet/Distributions.wl",
    "FeynFacetSourceHash" -> $feynFacetSourceHash
  |>;
  Append[context, "Fingerprint" -> reductionFingerprint[context]]
];


collinearRelations[process_Association] := Module[
  {legRelation},

  legRelation[leg_Association, fractionPower_Integer] := If[
    MissingQ[leg["HadronMomentum"]],
    Nothing,
    <|
      "PartonMomentum" -> leg["Momentum"],
      "HadronMomentum" -> leg["HadronMomentum"],
      "HadronScale" -> leg["Fraction"]^fractionPower,
      "LongDirection" -> leg["LongDirection"],
      "DualDirection" -> leg["DualDirection"]
    |>
  ];

  DeleteDuplicates @ Flatten[{
      legRelation[#, -1] & /@ process["Incoming"],
      legRelation[#, 1] & /@ process["Outgoing"]
    }, 1]
];


reduceCollinearLoopProducts[
    expression_,
    process_Association,
    loopMomenta_List
  ] := Module[{external, reduceOne},

  If[loopMomenta === {}, Return[expression]];
  external = FeynCalc`FCI @ FeynCalc`ExpandScalarProduct[expression];
  reduceOne[value_, relation_Association] := With[
    {
      momentum = relation["PartonMomentum"],
      hadron = relation["HadronMomentum"],
      hadronScale = relation["HadronScale"],
      direction = relation["LongDirection"],
      dual = relation["DualDirection"]
    },
    value /. {
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[a_, dimension_],
          FeynCalc`Momentum[hadron, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          hadronScale FeynCalc`Pair[
            FeynCalc`Momentum[a, dimension],
            FeynCalc`Momentum[momentum, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[hadron, dimension_],
          FeynCalc`Momentum[a_, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          hadronScale FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[a, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[a_, dimension_],
          FeynCalc`Momentum[direction, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          FeynCalc`Pair[
            FeynCalc`Momentum[a, dimension],
            FeynCalc`Momentum[momentum, dimension]
          ] / FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[dual, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[direction, dimension_],
          FeynCalc`Momentum[a_, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[a, dimension]
          ] / FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[dual, dimension]
          ]
    }
  ];

  Fold[
    reduceOne,
    external,
    collinearRelations[process]
  ]
];


remainingPhaseSpaceMomenta[process_Association] := DeleteCases[
  process["PhaseSpaceMomenta"],
  process["IntegratedMomentum"],
  {1},
  1
];

loopSectorsFromSetup[config_Association] := Module[
  {
    phaseMomenta, integratedMomenta, phaseLoops,
    forward, conjugate, forwardLoops, conjugateLoops, loops
  },

  phaseMomenta = Lookup[config, "PhaseSpaceMomentum", Missing[]];
  integratedMomenta = Lookup[config, "PartonIntegrated", Missing[]];
  forward = Lookup[config, "ForwardAmplitudes", Missing[]];
  conjugate = Lookup[config, "ConjugateAmplitudes", Missing[]];
  If[
    ! MatchQ[phaseMomenta, {_Symbol ...}] ||
      ! MatchQ[integratedMomenta, {_Symbol ...}] ||
      ! AssociationQ[forward] || ! AssociationQ[conjugate],
    fail[
      "LoopSectors",
      config,
      "Setup must declare phase-space, integrated, forward-loop and conjugate-loop momenta."
    ]
  ];
  forwardLoops = Lookup[forward, "LoopMomenta", Missing[]];
  conjugateLoops = Lookup[conjugate, "LoopMomenta", Missing[]];
  If[
    ! MatchQ[forwardLoops, {_Symbol ...}] ||
      ! MatchQ[conjugateLoops, {_Symbol ...}],
    fail[
      "LoopSectors",
      config,
      "LoopMomenta must be explicit symbol lists on both perturbative sides."
    ]
  ];
  phaseLoops = DeleteCases[
    phaseMomenta,
    Alternatives @@ integratedMomenta,
    {1},
    1
  ];
  loops = Join[phaseLoops, forwardLoops, conjugateLoops];
  If[! DuplicateFreeQ[loops],
    fail[
      "LoopSectors",
      loops,
      "Forward, conjugate and phase-space integrations require distinct loop momenta."
    ]
  ];
  <|
    "LoopMomenta" -> loops,
    "Sectors" -> Join[
      ConstantArray["PhaseSpace", Length[phaseLoops]],
      ConstantArray["Forward", Length[forwardLoops]],
      ConstantArray["Conjugate", Length[conjugateLoops]]
    ]
  |>
];

AMFlowPrescription[config_Association] := Catch[
  Module[{data},
    data = loopSectorsFromSetup[config];
    <|
      "LoopMomenta" -> data["LoopMomenta"],
      "Prescription" -> Replace[
        data["Sectors"],
        {"PhaseSpace" -> 0, "Forward" -> 1, "Conjugate" -> -1},
        {1}
      ]
    |>
  ],
  $collinearFailure
];

AMFlowPrescription[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);


momentumEliminationRule[process_Association] := Module[
  {momentum, incoming, outgoing},

  momentum = process["IntegratedMomentum"];
  incoming = Lookup[process["Incoming"], "Momentum"];
  outgoing = Lookup[process["Outgoing"], "Momentum"];

  momentum -> Expand[
    Total[incoming] - Total[DeleteCases[outgoing, momentum, {1}, 1]]
  ]
];


buildPhaseData[process_Association, eliminationRule_Rule] := Module[
  {momenta, remaining, outgoing, cutSources},

  momenta = process["PhaseSpaceMomenta"];
  remaining = remainingPhaseSpaceMomenta[process];
  outgoing = process["Outgoing"];
  cutSources = Map[
    Function[momentum, Module[{position, leg},
      position = First @ FirstPosition[
        Lookup[outgoing, "Momentum"],
        momentum
      ];
      leg = outgoing[[position]];
      With[{lineMomentum = Expand[momentum /. eliminationRule]},
        <|
          "SourceID" -> {"Cut", position},
          "Role" -> "Cut",
          "Expression" -> Cut[FeynCalc`SPD[lineMomentum], 1],
          "CutID" -> {"OutgoingLeg", position},
          "OriginalMomentum" -> momentum,
          "LineMomentum" -> lineMomentum,
          "Parton" -> leg["Parton"],
          "MeasurementRole" -> If[
            MissingQ[leg["HadronMomentum"]],
            "UnobservedPhaseSpace",
            "ObservedPhaseSpace"
          ],
          "EnergyReference" -> "PhysicalFuture",
          "EnergyDirection" -> 1
        |>
      ]
    ]],
    momenta
  ];

  <|
    "Prefactor" -> (2 Pi)^Expand[D - Length[momenta] (D - 1)],
    "Measure" -> Times @@ (FeynFacet`dD /@ remaining),
    "Cuts" -> Times @@ Lookup[cutSources, "Expression"],
    "CutSources" -> cutSources
  |>
];
