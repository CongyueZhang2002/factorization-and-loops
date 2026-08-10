(* Collinear projectors and the factorized pre-IBP pipeline. *)

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


splitAmplitude[expr_, side_] := Module[
  {
    external, terms, factorLists, propagatorLists, commonPropagators,
    numeratorLists, propagators, numerator, remaining
  },

  external = ToFeynFacetForm[expr];
  If[external === $Failed, Return[$Failed]];
  external = Expand[external, _FeynCalc`FAD];
  terms = If[Head[external] === Plus, List @@ external, {external}];
  factorLists = topLevelFactors /@ terms;
  propagatorLists = Cases[#, HoldPattern[FeynCalc`FAD[___]]] & /@
    factorLists;
  commonPropagators = commonFactorMultiset[propagatorLists];
  numeratorLists = Fold[removeFactorOnce[#1, #2] &, #,
      commonPropagators] & /@ factorLists;
  propagators = Times @@ commonPropagators;
  numerator = Total[Times @@@ numeratorLists];
  remaining = DeleteDuplicates @ Cases[
    numerator,
    HoldPattern[FeynCalc`FAD[___]],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::propagators, side, remaining];
    Throw[$Failed, $collinearFailure]
  ];

  {numerator, propagators}
];


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


setDistributionsZero[expr_, {}] := expr;

distributionZeroRule[head_Symbol] := With[
  {distributionHead = head},
  HoldPattern[distributionHead[___]] :> 0
];

distributionZeroRule[object_] := With[
  {distributionObject = object},
  HoldPattern[distributionObject] :> 0
];

setDistributionsZero[expr_, specifications_List] :=
  expr /. (distributionZeroRule /@ specifications);


containsListedMomentumQ[expr_, momenta_List] :=
  ! FreeQ[Unevaluated[expr], Alternatives @@ momenta];

setEvanescentZero[expr_, {}] := expr;

setEvanescentZero[expr_, momenta_List] := Module[{external},
  external = ToFeynFacetForm[FeynCalc`ExpandScalarProduct[expr]];
  If[external === $Failed, Return[$Failed]];
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


setMassZero[expr_, {}] := expr;

setMassZero[expr_, momenta_List] :=
  FeynCalc`FCI[expr] /.
    Thread[FeynCalc`FCI[FeynCalc`SPD /@ momenta] -> 0];


applyKinematicZeros[expr_, process_Association] := setMassZero[
  setEvanescentZero[expr, process["SetEvanescentZero"]],
  process["SetMassZero"]
];


fractionMeasure[process_Association] := Module[{fractions},
  fractions = DeleteDuplicates @ Select[
    Lookup[Join[process["Incoming"], process["Outgoing"]], "Fraction"],
    ! MissingQ[#] &
  ];
  Times @@ (dFraction /@ fractions)
];


factorizePair[config_Association] := Catch[
  Module[
    {
      process, eliminationRule, phase, amplitudes, completePair, splitPair,
      result, spinTags, taggedNumerator, missingSpinTags,
      remainingSpinTags, cutLoopMomenta, allLoopMomenta, preFactor, integrand,
      commonFactor, key, converted,
      cutNormalizationFactor, loopNormalizationFactor,
      externalCuts, loopCuts, externalPropagators,
      ordinaryPropagators, propagators,
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
    completePair = <|
      "Amplitude" -> amplitudes["Amplitude"],
      "Conjugate" -> FeynCalc`ComplexConjugate[
        amplitudes["Conjugate"]
      ]
    |>;
    splitPair = AssociationMap[
      splitAmplitude[completePair[#], ToLowerCase[#]] &,
      sideNames
    ];
    If[MemberQ[Values[splitPair], $Failed],
      fail[
        "CollinearFactorize",
        splitPair,
        "An amplitude could not be converted to compact FeynCalc syntax."
      ]
    ];
    {externalPropagators, ordinaryPropagators} =
      splitPropagatorsByMomentum[
        Times @@ (Last /@ Values[splitPair]) /. eliminationRule,
        allLoopMomenta
      ];
    {externalCuts, loopCuts} = splitFactorsByMomentum[
      phase["Cuts"],
      allLoopMomenta
    ];

    spinTags = externalSpinTags[process];
    taggedNumerator = tagExternalSpinors[
      Times @@ (First /@ Values[splitPair]),
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
    result = reduceCollinearLoopProducts[
      result,
      process,
      allLoopMomenta
    ];
    remainingAlgebra = unresolvedAlgebraObjects[result];
    If[remainingAlgebra =!= {},
      Message[
        CollinearFactorize::algebra,
        Take[remainingAlgebra, UpTo[10]]
      ];
      Throw[$Failed, $collinearFailure]
    ];

    commonFactor = CommonFactorSafe[
      result,
      allLoopMomenta
    ];
    If[commonFactor === $Failed,
      fail[
        "CollinearFactorize",
        result,
        "The result could not be converted to compact FeynCalc syntax."
      ]
    ];
    {preFactor, integrand} = commonFactor;
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
    propagators = loopCuts ordinaryPropagators;
    result = <|
      "Process" -> process,
      "FractionMeasure" -> fractionMeasure[process],
      "PreFactor" -> preFactor,
      "PhaseSpace" -> phase["Measure"] externalCuts/cutNormalizationFactor,
      "Integrand" -> integrand,
      "Propagators" -> propagators,
      "LoopMomenta" -> allLoopMomenta
    |>;

    Do[
      converted = ToFeynFacetForm[result[key]];
      If[converted === $Failed,
        fail[
          "CollinearFactorize",
          key,
          "The output could not be converted to compact FeynCalc syntax."
        ]
      ];
      AssociateTo[result, key -> converted],
      {key, {
        "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
        "Propagators"
      }}
    ];

    If[! FreeQ[
        Lookup[result, {
          "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
          "Propagators", "LoopMomenta"
        }],
        process["IntegratedMomentum"]
      ],
      fail[
        "PartonIntegrated",
        process["IntegratedMomentum"],
        "The eliminated momentum survived in the output."
      ]
    ];
    If[
      ! exactDataQ @ Lookup[result, {
        "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
        "Propagators", "LoopMomenta"
      }],
      fail[
        "CollinearFactorize",
        result,
        "The analytic result contains inexact numerical data."
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

$preIBPFailure = "FeynFacetPreIBPFailure";


preIBPFail[stage_] := (
  Message[CollinearFactorizePreIBP::stage, stage];
  Throw[$Failed, $preIBPFailure]
);

completeTopologyRecord[
    family_Association,
    pair_Association,
    context_Association
  ] := Module[
  {
    topology, propagatorCount, cutIndices, cutDirections, record
  },

  topology = family["Topology"];
  propagatorCount = Length[topology[[2]]];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];

  If[
    Length[cutIndices] =!= Length[cutDirections] ||
      ! DuplicateFreeQ[cutIndices] ||
      ! AllTrue[cutIndices, IntegerQ[#] && 1 <= # <= propagatorCount &] ||
      ! AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    Return[$Failed]
  ];

  record = Join[
    family,
    <|
      "Type" -> "FeynFacetTopologyRecord",
      "Version" -> 3,
      "DiagramPair" -> pair,
      "AnalyticContext" -> context
    |>
  ];
  If[! topologyRecordQ[record], Return[$Failed]];
  record
];

CollinearFactorizePreIBP[config_Association] := Catch[
  Module[
    {
      amplitudeKeys, missing, forwardAmplitudes,
      conjugateAmplitudes, diagrams, pipelineConfig, factorized,
      fractions, families, pair, topologies, shiftedIntegrand, context,
      forbiddenMomenta, remainingMomenta
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

    context = analyticContext[factorized["Process"]];
    If[context === $Failed, preIBPFail["BMHV analytic context"]];
    pair = <|
      "Forward" -> forwardAmplitudes["SelectedIndex"],
      "Conjugate" -> conjugateAmplitudes["SelectedIndex"]
    |>;
    topologies = completeTopologyRecord[
        #,
        pair,
        context
      ] & /@ families;
    If[MemberQ[topologies, $Failed], preIBPFail["topology metadata"]];

    shiftedIntegrand = DimensionalShift[
      factorized["Integrand"],
      topologies,
      factorized["LoopMomenta"]
    ];
    If[shiftedIntegrand === $Failed, preIBPFail["DimensionalShift"]];
    shiftedIntegrand = ToFeynFacetForm[shiftedIntegrand];
    If[shiftedIntegrand === $Failed,
      preIBPFail["compact expression conversion"]
    ];
    forbiddenMomenta = DeleteDuplicates @ Join[
      Lookup[config, "PhaseSpaceMomentum", {}],
      factorized["LoopMomenta"]
    ];
    remainingMomenta = remainingDeclaredMomenta[
      shiftedIntegrand,
      forbiddenMomenta
    ];
    If[remainingMomenta =!= {},
      Message[DimensionalShift::numerator, remainingMomenta];
      preIBPFail["loop-dependent master coefficient"]
    ];

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
    topologies_List,
    resultDirectory_: Automatic
  ] := Module[
  {
    cardName, pair, sourceNotebook, directory, contexts, process, context,
    expressionFields
  },
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
  If[! AllTrue[topologies, topologyRecordQ[#, pair] &],
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  contexts = DeleteDuplicates[Lookup[topologies, "AnalyticContext"], SameQ];
  context = If[
    topologies === {},
    process = Catch[normalizeProcess[setup], $collinearFailure];
    If[! AssociationQ[process], $Failed, analyticContext[process]],
    If[Length[contexts] === 1, First[contexts], $Failed]
  ];
  If[context === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  If[
    ! exactDataQ @ HoldComplete[
      setup, fractionMeasure, preFactor, phaseSpace, integrand, topologies,
      context
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  expressionFields = ToFeynFacetForm /@ {
    fractionMeasure, preFactor, phaseSpace, integrand
  };
  If[MemberQ[expressionFields, $Failed],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
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
  directory = Replace[
    resultDirectory,
    Automatic :> Lookup[setup, "ResultDirectory", Missing["NotAvailable"]]
  ];
  directory = If[
    StringQ[directory] && StringLength[StringTrim[directory]] > 0,
    ExpandFileName[directory],
    Missing["NotAvailable"]
  ];
  Join[resultHeader["FeynFacet-CollinearFactorizePreIBP", 4], <|
    "CardName" -> StringTrim[cardName],
    "Pair" -> pair,
    "ResultDirectory" -> directory,
    "ExpressionForm" -> "FeynCalcExternal",
    "AnalyticContext" -> context,
    "SourceNotebook" -> sourceNotebook,
    "Setup" -> setup,
    "FractionMeasure" -> expressionFields[[1]],
    "PreFactor" -> expressionFields[[2]],
    "PhaseSpace" -> expressionFields[[3]],
    "Integrand" -> expressionFields[[4]],
    "Topologies" -> topologies
  |>]
];

GenerateCollinearFactorizePreIBPResult[___] := (
  Message[GenerateCollinearFactorizePreIBPResult::setup];
  $Failed
);
