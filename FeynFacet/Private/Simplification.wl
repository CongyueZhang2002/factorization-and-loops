(* Card-driven exact simplification of physical master coefficients. *)

ClearAll[
  exactCoefficientNormalize,
  momentumFractionSymbols,
  singleMonomialData,
  minimumPolynomialExponents,
  fractionLaurentMonomial,
  additiveTerms,
  structuralCommonAdditiveFactor,
  coefficientMassDimension,
  coefficientKinematicAssumptions,
  normalizeCoefficientKinematics,
  coefficientKinematicsFromCard,
  coefficientAutomaticForbiddenVariables,
  coefficientDeclaredFractions,
  coefficientDistributionObjectQ,
  coefficientCommonDistributionFactor,
  coefficientNormalizeDistributionGroups,
  coefficientCanonicalRational,
  coefficientZeroStatus,
  coefficientFractionMonomialData,
  coefficientCertifiedPositiveQ,
  coefficientForbiddenFractionObjectQ,
  validateCoefficientBranchGrammar,
  coefficientPositiveRootLift,
  coefficientValidExponentQ,
  coefficientValidSparseMapQ,
  coefficientSparseLookup,
  coefficientSparseExpression,
  coefficientSparseAdd,
  coefficientSparseMultiply,
  coefficientSparseShift,
  coefficientPolynomialMap,
  coefficientNormalizePolynomialDenominator,
  coefficientPolynomialQuotient,
  coefficientFractionLeaf,
  coefficientValidLeafQ,
  coefficientMergeFractionLeaves,
  coefficientValidEntryQ,
  coefficientCommonDenominatorStep,
  coefficientCommonFractionDenominator,
  coefficientAssembleRootColumn,
  coefficientSparseMinimumExponent,
  coefficientCertifyRootColumn,
  coefficientPartitionByLengths,
  coefficientBalancedExactSum,
  coefficientContributionColumn,
  coefficientBranchSensitiveObjectQ,
  coefficientSimplifyWithFrozenBranches,
  simplifyHardCoefficientContributionGroups,
  coefficientHomogeneousDegree,
  coefficientDimensionlessNormalize,
  coefficientFormatDuration,
  coefficientProgressStart,
  coefficientProgressUpdate,
  coefficientProgressStage,
  coefficientProgressFinish,
  coefficientProgressFailure,
  $coefficientLateSetupKeys,
  coefficientAnalyticContextQ,
  coefficientKiraReductionQ,
  coefficientPairFileKey,
  coefficientResolveResultDirectory,
  coefficientRunProject,
  finiteFieldNormalizationKernelCount,
  finiteFieldNormalizeTraceTarget,
  finiteFieldNormalizeTraceBatch,
  finiteFieldCoefficientSimplificationCore,
  BuildSimplificationContext,
  SimplifyHardCoefficients
];

BuildSimplificationContext::invalid =
  "Invalid coefficient-simplification data in `1`: `2`.";

SimplifyHardCoefficients::input =
  "Expected exact assembled coefficients or exact contribution groups and a process card.";

SimplifyHardCoefficients::method =
  "Unknown simplification method `1`. Use \"Assembled\", \"ContributionWise\", or Automatic.";

Options[SimplifyHardCoefficients] = {
  "Method" -> Automatic,
  "TimeLimit" -> 60
};

Options[CoefficientSimplification] = {
  "RatracerExecutable" -> Automatic,
  "Threads" -> Automatic,
  "NormalizationKernels" -> Automatic,
  "TargetTimeLimit" -> 300,
  "MaximumTargets" -> All,
  "KeepWorkingFiles" -> True,
  "FactorScan" -> True,
  "ShiftScan" -> True
};

$coefficientBranchGrammars = {"PositiveMonomialRoots"};

CoefficientSimplification::project =
  "Could not run coefficient reconstruction for project `1`, card `2`: `3`.";

FeynFacet`$CoefficientSimplificationProgress = <|
  "Stage" -> "Idle",
  "Completed" -> 0,
  "Total" -> 1,
  "StartedAt" -> AbsoluteTime[],
  "ElapsedSeconds" -> 0.,
  "RemainingSeconds" -> Indeterminate,
  "Fraction" -> 0.,
  "Running" -> False,
  "Failed" -> False
|>;

coefficientFormatDuration[value_] := Module[
  {seconds, hours, minutes},
  If[! NumericQ[value] || ! TrueQ[value >= 0], Return["--"]];
  seconds = Round[value];
  hours = Quotient[seconds, 3600];
  minutes = Quotient[Mod[seconds, 3600], 60];
  Which[
    hours > 0,
      ToString[hours] <> " h " <> ToString[minutes] <> " min",
    minutes > 0,
      ToString[minutes] <> " min " <> ToString[Mod[seconds, 60]] <> " s",
    True,
      ToString[seconds] <> " s"
  ]
];

coefficientProgressStart[stage_String, total_Integer] := (
  FeynFacet`$CoefficientSimplificationProgress = <|
    "Stage" -> stage,
    "Completed" -> 0,
    "Total" -> Max[1, total],
    "StartedAt" -> AbsoluteTime[],
    "ElapsedSeconds" -> 0.,
    "RemainingSeconds" -> Indeterminate,
    "Fraction" -> 0.,
    "Running" -> True,
    "Failed" -> False
  |>
);

coefficientProgressUpdate[completed_Integer, total_Integer] := Module[
  {state, started, elapsed, remaining, fraction},
  state = FeynFacet`$CoefficientSimplificationProgress;
  started = Lookup[state, "StartedAt", AbsoluteTime[]];
  elapsed = N[AbsoluteTime[] - started];
  fraction = Clip[N[completed/Max[1, total]], {0., 1.}];
  remaining = If[completed > 0 && completed < total,
    elapsed (total - completed)/completed,
    If[completed >= total, 0., Indeterminate]
  ];
  FeynFacet`$CoefficientSimplificationProgress = Join[
    state,
    <|
      "Completed" -> completed,
      "Total" -> Max[1, total],
      "ElapsedSeconds" -> elapsed,
      "RemainingSeconds" -> remaining,
      "Fraction" -> fraction,
      "Running" -> True,
      "Failed" -> False
    |>
  ]
];

coefficientProgressStage[stage_String] := (
  FeynFacet`$CoefficientSimplificationProgress = Join[
    FeynFacet`$CoefficientSimplificationProgress,
    <|
      "Stage" -> stage,
      "RemainingSeconds" -> Indeterminate,
      "Running" -> True,
      "Failed" -> False
    |>
  ]
);

coefficientProgressFinish[] := Module[{state, elapsed},
  state = FeynFacet`$CoefficientSimplificationProgress;
  elapsed = N[
    AbsoluteTime[] - Lookup[state, "StartedAt", AbsoluteTime[]]
  ];
  FeynFacet`$CoefficientSimplificationProgress = Join[
    state,
    <|
      "Stage" -> "Finished",
      "Completed" -> Lookup[state, "Total", 1],
      "ElapsedSeconds" -> elapsed,
      "RemainingSeconds" -> 0.,
      "Fraction" -> 1.,
      "Running" -> False,
      "Failed" -> False
    |>
  ]
];

coefficientProgressFailure[stage_, detail_] := (
  FeynFacet`$CoefficientSimplificationProgress = Join[
    FeynFacet`$CoefficientSimplificationProgress,
    <|
      "Stage" -> "Failed during " <> ToString[stage],
      "Detail" -> ToString[detail, InputForm],
      "RemainingSeconds" -> Indeterminate,
      "Running" -> False,
      "Failed" -> True
    |>
  ]
);

CoefficientProgressPanel[] := Dynamic[
  Refresh[
    Module[
      {state, elapsed, remaining, completed, total, fraction, detail},
      state = FeynFacet`$CoefficientSimplificationProgress;
      completed = Lookup[state, "Completed", 0];
      total = Max[1, Lookup[state, "Total", 1]];
      fraction = Clip[Lookup[state, "Fraction", 0.], {0., 1.}];
      elapsed = If[TrueQ[Lookup[state, "Running", False]],
        N[
          AbsoluteTime[] - Lookup[state, "StartedAt", AbsoluteTime[]]
        ],
        Lookup[state, "ElapsedSeconds", 0.]
      ];
      remaining = If[
        TrueQ[Lookup[state, "Running", False]] && completed > 0 &&
          completed < total,
        elapsed (total - completed)/completed,
        Lookup[state, "RemainingSeconds", Indeterminate]
      ];
      detail = Lookup[state, "Detail", Missing["NotAvailable"]];
      Column[
        DeleteCases[
          {
            Style[Lookup[state, "Stage", "Idle"], Bold],
            ProgressIndicator[fraction, {0, 1}, ImageSize -> 520],
            Grid[
              {
                {"Targets", Row[{completed, " / ", total}]},
                {"Elapsed", coefficientFormatDuration[elapsed]},
                {"Estimated remaining", coefficientFormatDuration[remaining]}
              },
              Alignment -> Left,
              Spacings -> {2, 0.7}
            ],
            If[MissingQ[detail], Nothing, Style[detail, Red]]
          },
          Nothing
        ],
        Spacings -> 0.8
      ]
    ],
    UpdateInterval -> 1,
    TrackedSymbols :> {FeynFacet`$CoefficientSimplificationProgress}
  ]
];

exactCoefficientNormalize[expression_, assumptions_: True] := Module[{result},
  result = Simplify[expression, Assumptions -> assumptions];
  If[exactDataQ[result], result, $Failed]
];

momentumFractionSymbols[setup_Association] := DeleteDuplicates @ Cases[
  Lookup[setup, "MomentumFraction", {}],
  variable_Symbol /; variable =!= NA,
  Infinity
];

singleMonomialData[expression_, variables_List] := Module[
  {rational, numerator, denominator, numeratorRules, denominatorRules},
  rational = Cancel[Together[expression]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[
    ! PolynomialQ[numerator, variables] ||
      ! PolynomialQ[denominator, variables],
    Return[$Failed]
  ];
  numeratorRules = CoefficientRules[numerator, variables];
  denominatorRules = CoefficientRules[denominator, variables];
  If[
    Length[numeratorRules] =!= 1 ||
      Length[denominatorRules] =!= 1,
    Return[$Failed]
  ];
  {
    Last[First[numeratorRules]]/Last[First[denominatorRules]],
    First[First[numeratorRules]] - First[First[denominatorRules]]
  }
];

minimumPolynomialExponents[polynomial_, variables_List] := Module[{rules},
  rules = CoefficientRules[polynomial, variables];
  If[rules === {}, Return[ConstantArray[0, Length[variables]]]];
  Min /@ Transpose[First /@ rules]
];

fractionLaurentMonomial[expression_, variables_List] := Module[
  {
    rational, numerator, denominator,
    numeratorMinimum, denominatorMinimum
  },
  If[variables === {}, Return[1]];
  rational = Cancel[Together[expression]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[
    ! PolynomialQ[numerator, variables] ||
      ! PolynomialQ[denominator, variables],
    Return[$Failed]
  ];
  numeratorMinimum = minimumPolynomialExponents[numerator, variables];
  denominatorMinimum = minimumPolynomialExponents[denominator, variables];
  Times @@ MapThread[
    Power,
    {variables, numeratorMinimum - denominatorMinimum}
  ]
];

additiveTerms[expression_] := If[
  Head[expression] === Plus,
  List @@ expression,
  {expression}
];

structuralCommonAdditiveFactor[expressions_List] := Module[
  {nonzero, within, shared},
  nonzero = DeleteCases[expressions, 0];
  If[nonzero === {}, Return[{1, expressions}]];
  within = commonFactorMultiset[
      topLevelFactors /@ additiveTerms[#]
    ] & /@ nonzero;
  shared = commonFactorMultiset[within];
  {
    Times @@ shared,
    Map[
      If[TrueQ[# === 0], 0, #/(Times @@ shared)] &,
      expressions
    ]
  }
];

coefficientMassDimension[
    expression_,
    massDimensions_Association
  ] := Module[{dimensionful, walk},
  dimensionful = Keys @ Select[massDimensions, ! TrueQ[# === 0] &];
  walk[node_] := Which[
    NumberQ[node],
      0,
    AtomQ[Unevaluated[node]],
      Lookup[massDimensions, Unevaluated[node], 0],
    Head[Unevaluated[node]] === Plus,
      With[{dimensions = DeleteDuplicates[walk /@ List @@ node, SameQ]},
        If[Length[dimensions] === 1 && FreeQ[dimensions, $Failed],
          First[dimensions],
          $Failed
        ]
      ],
    Head[Unevaluated[node]] === Times,
      With[{dimensions = walk /@ List @@ node},
        If[FreeQ[dimensions, $Failed], Total[dimensions], $Failed]
      ],
    Head[Unevaluated[node]] === Power,
      With[
        {
          baseDimension = walk[node[[1]]],
          exponentDimension = walk[node[[2]]]
        },
        If[
          MemberQ[{baseDimension, exponentDimension}, $Failed] ||
            ! TrueQ[exponentDimension === 0],
          $Failed,
          baseDimension node[[2]]
        ]
      ],
    dimensionful === {} ||
        FreeQ[Unevaluated[node], Alternatives @@ dimensionful],
      0,
    True,
      $Failed
  ];
  walk[expression]
];

coefficientKinematicAssumptions[assumptions_, variables_List] := Module[
  {pattern, terms, restrictElement},
  If[variables === {}, Return[True]];
  pattern = Alternatives @@ variables;
  restrictElement[Element[object_, Reals]] := Module[{objects, selected},
    objects = If[Head[Unevaluated[object]] === Alternatives,
      List @@ object,
      {object}
    ];
    selected = Select[objects, ! FreeQ[#, pattern] &];
    If[selected === {}, True, Element[selected, Reals]]
  ];
  restrictElement[term_] := If[FreeQ[term, pattern], True, term];
  terms = If[Head[Unevaluated[assumptions]] === And,
    List @@ assumptions,
    {assumptions}
  ];
  And @@ DeleteCases[restrictElement /@ terms, True]
];

normalizeCoefficientKinematics[
    value_,
    massDimensions_Association
  ] := Module[
  {
    allowed, required, scale, coordinates, variables, definitions,
    positiveFractions, distributionFactor, laurentValuation,
    forbidden, grammar, physicalRegion, sourceInvariants,
    scaleDimension, coordinateDimensions, uncovered,
    solutions, rules, directRules, forwardCheck, backwardCheck
  },

  allowed = {
    "PositiveFractions", "DistributionFactor", "LaurentValuation",
    "Scale", "DimensionlessCoordinates", "ForbiddenVariables",
    "BranchGrammar", "PhysicalRegion"
  };
  required = allowed;
  If[
    ! AssociationQ[value] || Complement[Keys[value], allowed] =!= {},
    Message[
      BuildSimplificationContext::invalid,
      "CoefficientKinematics",
      "expected only " <> ToString[allowed, InputForm]
    ];
    Return[$Failed]
  ];
  If[Complement[required, Keys[value]] =!= {},
    Message[
      BuildSimplificationContext::invalid,
      "CoefficientKinematics",
      "missing declarations " <>
        ToString[Complement[required, Keys[value]], InputForm]
    ];
    Return[$Failed]
  ];

  scale = value["Scale"];
  coordinates = value["DimensionlessCoordinates"];
  positiveFractions = value["PositiveFractions"];
  distributionFactor = value["DistributionFactor"];
  laurentValuation = value["LaurentValuation"];
  forbidden = value["ForbiddenVariables"];
  grammar = value["BranchGrammar"];
  physicalRegion = value["PhysicalRegion"];
  If[
    ! MatchQ[scale, None | _Symbol] ||
      ! AssociationQ[coordinates] ||
      ! AllTrue[Keys[coordinates], MatchQ[#, _Symbol] &] ||
      ! DuplicateFreeQ[Keys[coordinates]] ||
      ! MatchQ[positiveFractions, Automatic | {_Symbol ...}] ||
      (ListQ[positiveFractions] && ! DuplicateFreeQ[positiveFractions]) ||
      ! MatchQ[laurentValuation, Automatic | _Association] ||
      (AssociationQ[laurentValuation] && ! AllTrue[
        Values[laurentValuation],
        MatchQ[#, _Integer | _Rational] &
      ]) ||
      ! MatchQ[forbidden, Automatic | {_Symbol ...}] ||
      (ListQ[forbidden] && ! DuplicateFreeQ[forbidden]) ||
      ! MemberQ[$coefficientBranchGrammars, grammar] ||
      ! exactDataQ[{
        coordinates, distributionFactor, laurentValuation, physicalRegion
      }],
    Message[
      BuildSimplificationContext::invalid,
      "CoefficientKinematics",
      value
    ];
    Return[$Failed]
  ];

  variables = Keys[coordinates];
  definitions = Values[coordinates];
  If[
    coordinates === <||>,
    Return[<|
      "PositiveFractions" -> positiveFractions,
      "DistributionFactor" -> distributionFactor,
      "LaurentValuation" -> laurentValuation,
      "Scale" -> scale,
      "DimensionlessCoordinates" -> coordinates,
      "DimensionlessVariables" -> variables,
      "DimensionlessRules" -> {},
      "DirectRules" -> {},
      "SourceInvariants" -> {},
      "ForbiddenVariables" -> forbidden,
      "BranchGrammar" -> grammar,
      "PhysicalRegion" -> physicalRegion
    |>]
  ];
  If[
    scale === None || MemberQ[variables, scale] ||
      ! KeyExistsQ[massDimensions, scale],
    Message[
      BuildSimplificationContext::invalid,
      "CoefficientKinematics",
      "dimensionless coordinates require a declared scale with a mass dimension"
    ];
    Return[$Failed]
  ];

  scaleDimension = coefficientMassDimension[scale, massDimensions];
  coordinateDimensions = coefficientMassDimension[#, massDimensions] & /@
    definitions;
  If[
    scaleDimension === $Failed || ! TrueQ[scaleDimension > 0] ||
      MemberQ[coordinateDimensions, $Failed] ||
      ! AllTrue[coordinateDimensions, TrueQ[# === 0] &] ||
      ! FreeQ[definitions, Alternatives @@ variables],
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "the scale must have positive mass dimension and every coordinate definition must have mass dimension zero"
    ];
    Return[$Failed]
  ];

  sourceInvariants = Select[
    Keys[massDimensions],
    # =!= scale && ! TrueQ[Lookup[massDimensions, #] === 0] &
  ];
  uncovered = Select[sourceInvariants, FreeQ[definitions, #] &];
  If[sourceInvariants === {} || uncovered =!= {},
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "the coordinates must determine every declared dimensionful invariant other than the scale; missing " <>
        ToString[uncovered, InputForm]
    ];
    Return[$Failed]
  ];
  solutions = TimeConstrained[
    Quiet @ Check[
      Solve[
        Thread[variables == definitions],
        sourceInvariants
      ],
      $Failed
    ],
    10,
    $TimedOut
  ];
  If[
    ! MatchQ[solutions, {_List}] || Length[solutions] =!= 1,
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "the coordinate definitions must determine one exact inverse map"
    ];
    Return[$Failed]
  ];
  rules = First[solutions];
  If[
    Sort[First /@ rules] =!= Sort[sourceInvariants] ||
      ! exactDataQ[rules],
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "the inverse map does not determine every source invariant"
    ];
    Return[$Failed]
  ];
  directRules = Thread[variables -> definitions];
  forwardCheck = And @@ MapThread[
    TrueQ @ FullSimplify[#1 == (#2 /. rules), scale != 0] &,
    {variables, definitions}
  ];
  backwardCheck = And @@ Map[
    TrueQ @ FullSimplify[
      First[#] == (Last[#] /. directRules),
      scale != 0
    ] &,
    rules
  ];
  If[! forwardCheck || ! backwardCheck,
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "the forward and inverse coordinate maps do not compose to the identity"
    ];
    Return[$Failed]
  ];

  <|
    "PositiveFractions" -> positiveFractions,
    "DistributionFactor" -> distributionFactor,
    "LaurentValuation" -> laurentValuation,
    "Scale" -> scale,
    "DimensionlessCoordinates" -> coordinates,
    "DimensionlessVariables" -> variables,
    "DimensionlessRules" -> rules,
    "DirectRules" -> directRules,
    "SourceInvariants" -> sourceInvariants,
    "ForbiddenVariables" -> forbidden,
    "BranchGrammar" -> grammar,
    "PhysicalRegion" -> physicalRegion
  |>
];

coefficientKinematicsFromCard[config_Association] :=
  normalizeCoefficientKinematics[
    Lookup[config, "CoefficientKinematics", Missing["NotAvailable"]],
    Lookup[config, "KinematicMassDimensions", <||>]
  ];

coefficientAutomaticForbiddenVariables[config_Association] :=
  DeleteDuplicates @ Join[
    momentumFractionSymbols[config],
    Cases[
      Lookup[
        config,
        {
          "PartonMomentum", "PhaseSpaceMomentum", "HadronMomentum",
          "HadronLongDirection", "HadronDualDirection",
          "HadronTransSpin"
        },
        {}
      ],
      symbol_Symbol /; symbol =!= NA,
      Infinity
    ],
    Cases[
      {
        Lookup[
          Lookup[config, "ForwardAmplitudes", <||>],
          "LoopMomenta",
          {}
        ],
        Lookup[
          Lookup[config, "ConjugateAmplitudes", <||>],
          "LoopMomenta",
          {}
        ],
        Keys @ Lookup[
          Lookup[config, "HadronicVariables", <||>],
          "Coordinates",
          <||>
        ],
        If[ListQ[globalBasis], globalBasis, {}]
      },
      symbol_Symbol /; symbol =!= NA,
      Infinity
    ]
  ];

coefficientDeclaredFractions[
    inferred_List,
    declaration_
  ] := Which[
  declaration === Automatic,
    inferred,
  ListQ[declaration] &&
      Complement[inferred, declaration, SameTest -> SameQ] === {} &&
      Complement[declaration, inferred, SameTest -> SameQ] === {},
    inferred,
  True,
    $Failed
];

BuildSimplificationContext[config_Association] := Catch[
  Module[
    {
      hadronic, kinematics, sourceAssumptions, coordinateRegion,
      inferredFractions, fractions, roots, forbidden, scale, scalePositive,
      sourceVariables, sourceKinematicAssumptions,
      mappedSourceKinematics, sourceNonempty, coordinateNonempty,
      forwardChamberCheck, backwardChamberCheck,
      dimensionlessAssumptions
    },
    hadronic = cardHadronicVariables[config];
    kinematics = coefficientKinematicsFromCard[config];
    If[kinematics === $Failed, Return[$Failed]];
    inferredFractions = momentumFractionSymbols[config];
    fractions = coefficientDeclaredFractions[
      inferredFractions,
      kinematics["PositiveFractions"]
    ];
    If[fractions === $Failed,
      Message[
        BuildSimplificationContext::invalid,
        "CoefficientKinematics[PositiveFractions]",
        "the declaration differs from MomentumFraction"
      ];
      Return[$Failed]
    ];
    If[
      AssociationQ[kinematics["LaurentValuation"]] &&
        (
          Complement[
            fractions,
            Keys[kinematics["LaurentValuation"]],
            SameTest -> SameQ
          ] =!= {} ||
          Complement[
            Keys[kinematics["LaurentValuation"]],
            fractions,
            SameTest -> SameQ
          ] =!= {}
        ),
      Message[
        BuildSimplificationContext::invalid,
        "CoefficientKinematics[LaurentValuation]",
        "its keys must equal the declared momentum fractions"
      ];
      Return[$Failed]
    ];
    sourceAssumptions = inferFractionAssumptions[
        Lookup[config, "MomentumFraction", {}]
      ] && hadronic["Assumptions"];
    coordinateRegion = kinematics["PhysicalRegion"];
    scale = kinematics["Scale"];
    If[scale =!= None,
      scalePositive = TimeConstrained[
        TrueQ @ FullSimplify[
          scale > 0,
          Assumptions -> sourceAssumptions
        ],
        10,
        False
      ];
      If[! scalePositive,
        Message[
          BuildSimplificationContext::invalid,
          "CoefficientKinematics[Scale]",
          "positivity is not implied by the card assumptions"
        ];
        Return[$Failed]
      ]
    ];
    If[kinematics["DimensionlessRules"] =!= {},
      sourceVariables = Join[
        {scale},
        kinematics["SourceInvariants"]
      ];
      sourceKinematicAssumptions = coefficientKinematicAssumptions[
        sourceAssumptions,
        sourceVariables
      ];
      mappedSourceKinematics =
        sourceKinematicAssumptions /. kinematics["DimensionlessRules"];
      sourceNonempty = TimeConstrained[
        Quiet @ Check[
          Reduce[
            sourceKinematicAssumptions,
            sourceVariables,
            Reals
          ] =!= False,
          False
        ],
        15,
        False
      ];
      coordinateNonempty = TimeConstrained[
        Quiet @ Check[
          Reduce[
            coordinateRegion && scale > 0,
            Join[{scale}, kinematics["DimensionlessVariables"]],
            Reals
          ] =!= False,
          False
        ],
        15,
        False
      ];
      forwardChamberCheck = TimeConstrained[
        TrueQ @ FullSimplify[
          coordinateRegion /. kinematics["DirectRules"],
          Assumptions -> sourceAssumptions
        ],
        15,
        False
      ];
      backwardChamberCheck = TimeConstrained[
        TrueQ @ FullSimplify[
          mappedSourceKinematics,
          Assumptions -> coordinateRegion && scale > 0
        ],
        15,
        False
      ];
      If[
        ! sourceNonempty || ! coordinateNonempty ||
          ! forwardChamberCheck || ! backwardChamberCheck,
        Message[
          BuildSimplificationContext::invalid,
          "CoefficientKinematics[PhysicalRegion]",
          "the source and dimensionless chambers are not nonempty equivalent descriptions under the declared coordinate map"
        ];
        Return[$Failed]
      ]
    ];
    roots = Table[
      Unique["fractionRoot$"],
      Length[fractions]
    ];
    forbidden = DeleteDuplicates @ Join[
      coefficientAutomaticForbiddenVariables[config],
      If[
        kinematics["ForbiddenVariables"] === Automatic,
        {},
        kinematics["ForbiddenVariables"]
      ]
    ];
    dimensionlessAssumptions = If[
      kinematics["DimensionlessRules"] === {},
      sourceAssumptions,
      (sourceAssumptions /. kinematics["DimensionlessRules"]) &&
        coordinateRegion
    ];
    <|
      "FractionVariables" -> fractions,
      "FractionRootVariables" -> roots,
      "ExpectedDistributionFactor" -> kinematics["DistributionFactor"],
      "ExpectedLaurentValuation" -> kinematics["LaurentValuation"],
      "HadronicVariables" -> hadronic,
      "PhysicalAssumptions" -> sourceAssumptions,
      "CoordinateRegion" -> coordinateRegion,
      "DimensionlessAssumptions" -> dimensionlessAssumptions,
      "Scale" -> scale,
      "DimensionlessCoordinates" ->
        kinematics["DimensionlessCoordinates"],
      "DimensionlessVariables" ->
        Lookup[kinematics, "DimensionlessVariables", {}],
      "DimensionlessRules" -> kinematics["DimensionlessRules"],
      "SourceInvariants" -> Lookup[kinematics, "SourceInvariants", {}],
      "ForbiddenVariables" -> forbidden,
      "BranchGrammar" -> kinematics["BranchGrammar"],
      "KinematicMassDimensions" ->
        Lookup[config, "KinematicMassDimensions", <||>]
    |>
  ],
  $collinearFailure
];

BuildSimplificationContext[config_] := (
  Message[BuildSimplificationContext::invalid, "Setup", config];
  $Failed
);

coefficientDistributionObjectQ[object_] := MemberQ[
  $twist2DistributionHeads,
  Head[Unevaluated[object]]
];

coefficientCommonDistributionFactor[
    expressions_List,
    timeLimit_: 60
  ] := Module[
  {
    objects, atoms, forward, backward, frozen, nonzero,
    factorData, shared, candidate, quotients, monomials,
    reconstruction
  },
  objects = DeleteDuplicates @ Cases[
    HoldComplete[expressions],
    object_ /; coefficientDistributionObjectQ[Unevaluated[object]] :>
      object,
    Infinity
  ];
  If[objects === {},
    Return[<|"Factor" -> 1, "Expressions" -> expressions|>]
  ];
  atoms = Array[Unique["distribution$"] &, Length[objects]];
  forward = Dispatch[Thread[objects -> atoms]];
  backward = Dispatch[Thread[atoms -> objects]];
  frozen = expressions /. forward;
  nonzero = DeleteCases[frozen, 0];
  If[nonzero === {},
    Return[<|"Factor" -> 1, "Expressions" -> expressions|>]
  ];

  factorData = structuralCommonAdditiveFactor[nonzero];
  shared = First[factorData];
  candidate = Times @@ Select[
    topLevelFactors[shared],
    ! FreeQ[#, Alternatives @@ atoms] &
  ];
  quotients = (#/candidate) & /@ frozen;
  If[! FreeQ[quotients, Alternatives @@ atoms],
    monomials = fractionLaurentMonomial[#, atoms] & /@ nonzero;
    If[
      MemberQ[monomials, $Failed] ||
        Length[DeleteDuplicates[monomials, SameQ]] =!= 1,
      Return[$Failed]
    ];
    candidate = First[monomials];
    quotients = (#/candidate) & /@ frozen
  ];
  quotients = TimeConstrained[
    exactCoefficientNormalize[#, True] & /@ quotients,
    timeLimit,
    $TimedOut
  ];
  If[
    quotients === $TimedOut || ! ListQ[quotients] ||
      MemberQ[quotients, $Failed | $TimedOut] ||
      ! FreeQ[quotients, Alternatives @@ atoms],
    Return[$Failed]
  ];
  reconstruction = TimeConstrained[
    And @@ MapThread[
      TrueQ[exactCoefficientNormalize[#1 - candidate #2, True] === 0] &,
      {frozen, quotients}
    ],
    timeLimit,
    $TimedOut
  ];
  If[reconstruction =!= True, Return[$Failed]];
  <|
    "Factor" -> (candidate /. backward),
    "Expressions" -> (quotients /. backward),
    "Objects" -> objects
  |>
];

coefficientNormalizeDistributionGroups[
    groups_List,
    expected_,
    assumptions_,
    timeLimit_: 60
  ] := Module[
  {
    objects, atoms, forward, backward, frozenGroups, assembled,
    automaticData, candidate, candidateData, status, normalizeGroup,
    strippedGroups, factor
  },
  objects = DeleteDuplicates @ Cases[
    HoldComplete[
      groups,
      If[expected === Automatic, Nothing, expected]
    ],
    object_ /; coefficientDistributionObjectQ[Unevaluated[object]] :>
      object,
    Infinity
  ];
  atoms = Array[Unique["distribution$"] &, Length[objects]];
  forward = Dispatch[Thread[objects -> atoms]];
  backward = Dispatch[Thread[atoms -> objects]];
  frozenGroups = groups /. forward;

  If[expected === Automatic,
    assembled = coefficientBalancedExactSum[#, timeLimit] & /@
      frozenGroups;
    If[MemberQ[assembled, $Failed | $TimedOut], Return[$Failed]];
    automaticData = coefficientCommonDistributionFactor[
      assembled /. backward,
      timeLimit
    ];
    If[automaticData === $Failed, Return[$Failed]];
    factor = automaticData["Factor"];
    candidate = factor /. forward;
    status = "DerivedFromComputedCoefficients",
    factor = expected;
    candidate = expected /. forward;
    status = "DeclaredAndVerified"
  ];

  If[atoms === {},
    If[! TrueQ[candidate === 1], Return[$Failed]],
    candidateData = singleMonomialData[candidate, atoms];
    If[
      candidateData === $Failed ||
        ! TrueQ[First[candidateData] === 1] ||
        ! AllTrue[Last[candidateData], IntegerQ[#] && NonNegative[#] &],
      Return[$Failed]
    ]
  ];

  normalizeGroup[group_List] := Module[
    {termQuotients, sum, quotient, stripped, reconstruction},
    termQuotients = coefficientCanonicalRational[
        #/candidate,
        timeLimit
      ] & /@ group;
    stripped = If[
      ! MemberQ[termQuotients, $Failed | $TimedOut] &&
        FreeQ[termQuotients, Alternatives @@ atoms],
      termQuotients,
      sum = coefficientBalancedExactSum[group, timeLimit];
      If[sum === $Failed, Return[$Failed]];
      quotient = coefficientCanonicalRational[sum/candidate, timeLimit];
      If[
        MemberQ[{$Failed, $TimedOut}, quotient] ||
          ! FreeQ[quotient, Alternatives @@ atoms],
        Return[$Failed]
      ];
      {quotient}
    ];
    reconstruction = coefficientCanonicalRational[
      Total[group] - candidate Total[stripped],
      timeLimit
    ];
    If[! TrueQ[reconstruction === 0], Return[$Failed]];
    stripped
  ];

  strippedGroups = normalizeGroup /@ frozenGroups;
  If[MemberQ[strippedGroups, $Failed], Return[$Failed]];
  <|
    "Factor" -> factor,
    "Groups" -> (strippedGroups /. backward),
    "Status" -> status,
    "Objects" -> objects,
    "ReconstructionVerified" -> True
  |>
];

coefficientCanonicalRational[expression_, timeLimit_: 60] :=
  TimeConstrained[
    Quiet @ CheckAbort[
      Check[Cancel[Together[expression]], $Failed],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];

coefficientZeroStatus[expression_, timeLimit_: 60] := Module[{canonical},
  If[TrueQ[expression === 0], Return[True]];
  canonical = coefficientCanonicalRational[expression, timeLimit];
  Which[
    MemberQ[{$Failed, $TimedOut}, canonical], canonical,
    TrueQ[canonical === 0], True,
    True, False
  ]
];

coefficientFractionMonomialData[base_, fractions_List] := Catch @ Module[
  {factors, exponents, coefficient = 1, position},
  factors = If[Head[base] === Times, List @@ base, {base}];
  exponents = ConstantArray[0, Length[fractions]];
  Do[
    position = FirstPosition[fractions, factor, Missing["NotFound"]];
    Which[
      ! MissingQ[position],
        exponents[[First[position]]]++,
      Head[factor] === Power && IntegerQ[factor[[2]]] &&
          MemberQ[fractions, factor[[1]]],
        position = First @ FirstPosition[fractions, factor[[1]]];
        exponents[[position]] += factor[[2]],
      FreeQ[factor, Alternatives @@ fractions],
        coefficient *= factor,
      True,
        Throw[$Failed]
    ],
    {factor, factors}
  ];
  If[
    ! FreeQ[coefficient, Alternatives @@ fractions],
    $Failed,
    <|"Coefficient" -> coefficient, "Exponents" -> exponents|>
  ]
];

coefficientCertifiedPositiveQ[
    expression_,
    assumptions_,
    timeLimit_: 10
  ] := TrueQ @ TimeConstrained[
  Quiet @ CheckAbort[
    Check[FullSimplify[expression > 0, Assumptions -> assumptions], False],
    False
  ],
  timeLimit,
  False
];

coefficientForbiddenFractionObjectQ[
    expression_,
    fractions_List
  ] := Module[{fractionPattern, badObjects, badPowers},
  If[fractions === {}, Return[False]];
  fractionPattern = Alternatives @@ fractions;
  badObjects = Cases[
    HoldComplete[expression],
    object_ /; (
      Head[Unevaluated[object]] =!= HoldComplete &&
      ! AtomQ[Unevaluated[object]] &&
      ! FreeQ[Unevaluated[object], fractionPattern] &&
      ! MemberQ[{Plus, Times, Power}, Head[Unevaluated[object]]] &&
      ! coefficientDistributionObjectQ[Unevaluated[object]]
    ) :>
        HoldComplete[object],
    Infinity
  ];
  badPowers = Cases[
    HoldComplete[expression],
    object : Power[_, exponent_] /; (
      ! FreeQ[Unevaluated[object], fractionPattern] &&
      ! IntegerQ[exponent] &&
      ! (MatchQ[exponent, _Rational] && IntegerQ[2 exponent])
    ) :> HoldComplete[object],
    Infinity
  ];
  badObjects =!= {} || badPowers =!= {}
];

validateCoefficientBranchGrammar[
    expression_,
    context_Association
  ] := Module[{fractions, assumptions, powers, checks},
  If[context["BranchGrammar"] =!= "PositiveMonomialRoots", Return[False]];
  fractions = context["FractionVariables"];
  assumptions = context["PhysicalAssumptions"];
  If[
    coefficientForbiddenFractionObjectQ[expression, fractions],
    Return[False]
  ];
  If[fractions === {}, Return[True]];
  powers = DeleteDuplicates @ Cases[
    expression,
    power : Power[base_, exponent_] /; (
      ! IntegerQ[exponent] &&
      ! FreeQ[base, Alternatives @@ fractions]
    ) :> power,
    Infinity
  ];
  checks = Map[
    Function[power,
      Module[{data, rootExponents},
        If[
          ! MatchQ[power[[2]], _Rational] ||
            ! IntegerQ[2 power[[2]]],
          Return[False]
        ];
        data = coefficientFractionMonomialData[
          power[[1]],
          fractions
        ];
        If[data === $Failed, Return[False]];
        rootExponents = 2 power[[2]] data["Exponents"];
        AllTrue[rootExponents, IntegerQ] &&
          coefficientCertifiedPositiveQ[
            data["Coefficient"],
            assumptions,
            10
          ]
      ]
    ],
    powers
  ];
  AllTrue[checks, TrueQ]
];

coefficientPositiveRootLift[
    expression_,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    fractions, roots, assumptions, powers, rules, data, coefficient,
    exponents, rootExponents, prepared, powerRules, lifted, rational,
    numerator, denominator
  },
  fractions = context["FractionVariables"];
  roots = context["FractionRootVariables"];
  assumptions = context["PhysicalAssumptions"];
  If[fractions === {},
    Return[<|"Expression" -> expression, "Rules" -> {}|>]
  ];
  If[
    ! exactDataQ[expression] ||
      ! validateCoefficientBranchGrammar[expression, context],
    Return[$Failed]
  ];
  powers = DeleteDuplicates @ Cases[
    expression,
    power : Power[base_, exponent_Rational] /; (
      ! IntegerQ[exponent] &&
      ! FreeQ[base, Alternatives @@ fractions]
    ) :> power,
    Infinity
  ];
  rules = Catch @ Map[
    Function[power,
      data = coefficientFractionMonomialData[power[[1]], fractions];
      If[data === $Failed, Throw[$Failed]];
      coefficient = data["Coefficient"];
      exponents = data["Exponents"];
      rootExponents = 2 power[[2]] exponents;
      If[
        ! AllTrue[rootExponents, IntegerQ] ||
          ! coefficientCertifiedPositiveQ[
            coefficient,
            assumptions,
            Min[10, timeLimit]
          ],
        Throw[$Failed]
      ];
      power -> (
        coefficient^power[[2]]
          Times @@ MapThread[Power, {roots, rootExponents}]
      )
    ],
    powers
  ];
  If[rules === $Failed, Return[$Failed]];
  prepared = expression /. Dispatch[rules];
  powerRules = Flatten @ MapThread[
    Function[{fraction, root},
      With[{f = fraction, r = root},
        {
          HoldPattern[Power[f, exponent_Rational]] :>
            r^(2 exponent),
          f -> r^2
        }
      ]
    ],
    {fractions, roots}
  ];
  lifted = prepared /. Dispatch[powerRules];
  If[! FreeQ[lifted, Alternatives @@ fractions], Return[$Failed]];
  numerator = Numerator[lifted];
  denominator = Denominator[lifted];
  If[
    ! PolynomialQ[numerator, roots] ||
      ! PolynomialQ[denominator, roots],
    rational = coefficientCanonicalRational[lifted, timeLimit];
    If[MemberQ[{$Failed, $TimedOut}, rational], Return[rational]];
    numerator = Numerator[rational];
    denominator = Denominator[rational];
    If[
      ! PolynomialQ[numerator, roots] ||
        ! PolynomialQ[denominator, roots],
      Return[$Failed]
    ];
    lifted = rational
  ];
  <|"Expression" -> lifted, "Rules" -> rules|>
];

coefficientValidExponentQ[exponent_, length_Integer] :=
  MatchQ[exponent, {_Integer ...}] && Length[exponent] === length;

coefficientValidSparseMapQ[
    map_,
    roots_List,
    fractions_List
  ] := AssociationQ[map] &&
  AllTrue[Keys[map], coefficientValidExponentQ[#, Length[roots]] &] &&
  exactDataQ[Values[map]] &&
  FreeQ[Values[map], Alternatives @@ Join[roots, fractions]];

coefficientSparseLookup[map_Association, exponent_List] :=
  If[KeyExistsQ[map, exponent], map[exponent], 0];

coefficientSparseExpression[map_Association, roots_List] := Total @
  KeyValueMap[
    #2 Times @@ MapThread[Power, {roots, #1}] &,
    map
  ];

coefficientSparseAdd[
    maps_List,
    roots_List,
    fractions_List
  ] := Module[{result},
  If[
    ! AllTrue[
      maps,
      coefficientValidSparseMapQ[#, roots, fractions] &
    ],
    Return[$Failed]
  ];
  result = Select[Merge[maps, Total], ! TrueQ[# === 0] &];
  If[
    coefficientValidSparseMapQ[result, roots, fractions],
    result,
    $Failed
  ]
];

coefficientSparseMultiply[
    first_Association,
    second_Association,
    roots_List,
    fractions_List
  ] := Module[{terms, result},
  If[
    ! coefficientValidSparseMapQ[first, roots, fractions] ||
      ! coefficientValidSparseMapQ[second, roots, fractions],
    Return[$Failed]
  ];
  terms = Flatten @ KeyValueMap[
    Function[{firstExponent, firstCoefficient},
      KeyValueMap[
        Function[{secondExponent, secondCoefficient},
          (firstExponent + secondExponent) ->
            (firstCoefficient secondCoefficient)
        ],
        second
      ]
    ],
    first
  ];
  result = Select[Merge[Association /@ terms, Total], ! TrueQ[# === 0] &];
  If[
    coefficientValidSparseMapQ[result, roots, fractions],
    result,
    $Failed
  ]
];

coefficientSparseShift[
    map_Association,
    shift_List,
    roots_List,
    fractions_List
  ] := Module[{result},
  If[
    ! coefficientValidSparseMapQ[map, roots, fractions] ||
      ! coefficientValidExponentQ[shift, Length[roots]],
    Return[$Failed]
  ];
  result = Association @ KeyValueMap[(#1 + shift) -> #2 &, map];
  If[
    coefficientValidSparseMapQ[result, roots, fractions],
    result,
    $Failed
  ]
];

coefficientPolynomialMap[
    polynomial_,
    roots_List,
    fractions_List
  ] := Module[{rules, map},
  If[
    ! exactDataQ[polynomial] || ! PolynomialQ[polynomial, roots],
    Return[$Failed]
  ];
  If[FreeQ[polynomial, Alternatives @@ roots],
    Return[
      If[
        TrueQ[polynomial === 0],
        <||>,
        <|ConstantArray[0, Length[roots]] -> polynomial|>
      ]
    ]
  ];
  rules = Quiet @ Check[CoefficientRules[polynomial, roots], $Failed];
  If[rules === $Failed, Return[$Failed]];
  map = Association[rules];
  If[
    coefficientValidSparseMapQ[map, roots, fractions],
    map,
    $Failed
  ]
];

coefficientNormalizePolynomialDenominator[
    denominator_,
    roots_List,
    fractions_List,
    timeLimit_: 60
  ] := Module[
  {
    canonical, rules, leadingRule, leadingCoefficient,
    normalized, reconstruction
  },
  canonical = If[
    exactDataQ[denominator] && PolynomialQ[denominator, roots],
    denominator,
    coefficientCanonicalRational[denominator, timeLimit]
  ];
  If[MemberQ[{$Failed, $TimedOut}, canonical], Return[canonical]];
  If[
    ! PolynomialQ[canonical, roots] ||
      coefficientZeroStatus[canonical, timeLimit] =!= False,
    Return[$Failed]
  ];
  rules = CoefficientRules[canonical, roots];
  If[rules === {}, Return[$Failed]];
  leadingRule = First @ Reverse @ SortBy[rules, First];
  leadingCoefficient = coefficientCanonicalRational[
    Last[leadingRule],
    timeLimit
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, leadingCoefficient] ||
      coefficientZeroStatus[leadingCoefficient, timeLimit] =!= False,
    Return[$Failed]
  ];
  normalized = coefficientCanonicalRational[
    canonical/leadingCoefficient,
    timeLimit
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, normalized] ||
      ! PolynomialQ[normalized, roots] ||
      ! FreeQ[normalized, Alternatives @@ fractions],
    Return[$Failed]
  ];
  reconstruction = coefficientZeroStatus[
    canonical - leadingCoefficient normalized,
    timeLimit
  ];
  If[reconstruction =!= True, Return[reconstruction]];
  {normalized, leadingCoefficient}
];

coefficientPolynomialQuotient[
    dividend_,
    divisor_,
    roots_List,
    timeLimit_: 60
  ] := Module[{quotient, reconstruction},
  If[coefficientZeroStatus[divisor, timeLimit] =!= False,
    Return[$Failed]
  ];
  quotient = coefficientCanonicalRational[dividend/divisor, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, quotient], Return[quotient]];
  If[! PolynomialQ[quotient, roots], Return[Missing["NotDivisible"]]];
  reconstruction = coefficientZeroStatus[
    dividend - divisor quotient,
    timeLimit
  ];
  Which[
    reconstruction === True, quotient,
    reconstruction === $TimedOut, $TimedOut,
    True, $Failed
  ]
];

coefficientFractionLeaf[
    expression_,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    roots, fractions, liftedData, lifted, numerator, denominator,
    denominatorData, normalizedDenominator, leadingCoefficient,
    normalizedNumerator, numeratorMap, reconstruction
  },
  roots = context["FractionRootVariables"];
  fractions = context["FractionVariables"];
  liftedData = coefficientPositiveRootLift[expression, context, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, liftedData], Return[liftedData]];
  lifted = liftedData["Expression"];
  numerator = Numerator[lifted];
  denominator = Denominator[lifted];
  denominatorData = coefficientNormalizePolynomialDenominator[
    denominator,
    roots,
    fractions,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, denominatorData],
    Return[denominatorData]
  ];
  {normalizedDenominator, leadingCoefficient} = denominatorData;
  normalizedNumerator = numerator/leadingCoefficient;
  numeratorMap = coefficientPolynomialMap[
    normalizedNumerator,
    roots,
    fractions
  ];
  If[numeratorMap === $Failed, Return[$Failed]];
  reconstruction = coefficientZeroStatus[
    coefficientSparseExpression[numeratorMap, roots] leadingCoefficient -
      numerator,
    timeLimit
  ];
  If[reconstruction =!= True, Return[reconstruction]];
  <|
    "Denominator" -> normalizedDenominator,
    "Numerator" -> numeratorMap,
    "BranchRules" -> liftedData["Rules"],
    "LeafCount" -> 1
  |>
];

coefficientValidLeafQ[leaf_, roots_List, fractions_List] :=
  AssociationQ[leaf] &&
  ContainsAll[
    Keys[leaf],
    {"Denominator", "Numerator", "BranchRules", "LeafCount"}
  ] &&
  coefficientValidSparseMapQ[leaf["Numerator"], roots, fractions] &&
  PolynomialQ[leaf["Denominator"], roots] &&
  exactDataQ[leaf];

coefficientMergeFractionLeaves[
    leaves_List,
    roots_List,
    fractions_List
  ] := Module[{groups, entries},
  If[
    ! AllTrue[leaves, coefficientValidLeafQ[#, roots, fractions] &],
    Return[$Failed]
  ];
  groups = GroupBy[leaves, HoldComplete[#1["Denominator"]] &];
  entries = KeyValueMap[
    Function[{heldDenominator, group},
      With[{
        numerator = coefficientSparseAdd[
          Lookup[group, "Numerator"],
          roots,
          fractions
        ]
      },
        If[
          numerator === $Failed,
          $Failed,
          <|
            "Denominator" -> ReleaseHold[heldDenominator],
            "Numerator" -> numerator,
            "BranchRules" ->
              DeleteDuplicates @ Flatten[Lookup[group, "BranchRules"]],
            "LeafCount" -> Total[Lookup[group, "LeafCount"]]
          |>
        ]
      ]
    ],
    groups
  ];
  If[MemberQ[entries, $Failed], $Failed, entries]
];

coefficientValidEntryQ[entry_, roots_List, fractions_List] :=
  coefficientValidLeafQ[entry, roots, fractions];

coefficientCommonDenominatorStep[
    common_,
    denominator_,
    roots_List,
    fractions_List,
    timeLimit_: 60
  ] := Module[{firstQuotient, secondQuotient, normalized},
  firstQuotient = coefficientPolynomialQuotient[
    common,
    denominator,
    roots,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, firstQuotient],
    Return[firstQuotient]
  ];
  If[! MissingQ[firstQuotient], Return[common]];
  secondQuotient = coefficientPolynomialQuotient[
    denominator,
    common,
    roots,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, secondQuotient],
    Return[secondQuotient]
  ];
  If[! MissingQ[secondQuotient], Return[denominator]];
  normalized = coefficientNormalizePolynomialDenominator[
    common denominator,
    roots,
    fractions,
    timeLimit
  ];
  If[ListQ[normalized], First[normalized], normalized]
];

coefficientCommonFractionDenominator[
    denominators_List,
    roots_List,
    fractions_List,
    timeLimit_: 60
  ] := Fold[
  coefficientCommonDenominatorStep[
    #1,
    #2,
    roots,
    fractions,
    timeLimit
  ] &,
  1,
  DeleteDuplicates[denominators, SameQ]
];

coefficientAssembleRootColumn[
    entries_List,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    roots, fractions, commonDenominator, numeratorMaps,
    assembledNumerator
  },
  roots = context["FractionRootVariables"];
  fractions = context["FractionVariables"];
  If[
    entries === {} ||
      ! AllTrue[
        entries,
        coefficientValidEntryQ[#, roots, fractions] &
      ],
    Return[$Failed]
  ];
  commonDenominator = coefficientCommonFractionDenominator[
    Lookup[entries, "Denominator"],
    roots,
    fractions,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, commonDenominator],
    Return[commonDenominator]
  ];
  numeratorMaps = Catch @ Map[
    Function[entry,
      Module[{quotient, quotientMap, product},
        quotient = coefficientPolynomialQuotient[
          commonDenominator,
          entry["Denominator"],
          roots,
          timeLimit
        ];
        If[
          MemberQ[{$Failed, $TimedOut}, quotient] || MissingQ[quotient],
          Throw[$Failed]
        ];
        quotientMap = coefficientPolynomialMap[
          quotient,
          roots,
          fractions
        ];
        If[quotientMap === $Failed, Throw[$Failed]];
        product = coefficientSparseMultiply[
          entry["Numerator"],
          quotientMap,
          roots,
          fractions
        ];
        If[product === $Failed, Throw[$Failed]];
        product
      ]
    ],
    entries
  ];
  If[numeratorMaps === $Failed, Return[$Failed]];
  assembledNumerator = coefficientSparseAdd[
    numeratorMaps,
    roots,
    fractions
  ];
  If[assembledNumerator === $Failed, Return[$Failed]];
  <|
    "Denominator" -> commonDenominator,
    "Numerator" -> assembledNumerator,
    "BranchRules" ->
      DeleteDuplicates @ Flatten[Lookup[entries, "BranchRules"]],
    "LeafCount" -> Total[Lookup[entries, "LeafCount"]]
  |>
];

coefficientSparseMinimumExponent[map_Association] :=
  Min /@ Transpose[Keys[map]];

coefficientCertifyRootColumn[
    column_Association,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    roots, fractions, numeratorMap, denominatorMap, rootValuation,
    referenceMap, keys, pivot, referenceCoefficient, numeratorCoefficient,
    checks, hardCoefficient, fractionValuation
  },
  roots = context["FractionRootVariables"];
  fractions = context["FractionVariables"];
  numeratorMap = Lookup[column, "Numerator", $Failed];
  If[numeratorMap === <||>,
    Return[<|
      "Zero" -> True,
      "HardCoefficient" -> 0,
      "LaurentValuation" -> Missing["ZeroCoefficient"],
      "BranchRules" -> Lookup[column, "BranchRules", {}],
      "LeafCount" -> Lookup[column, "LeafCount", 0]
    |>]
  ];
  If[
    ! coefficientValidSparseMapQ[numeratorMap, roots, fractions],
    Return[$Failed]
  ];
  denominatorMap = coefficientPolynomialMap[
    column["Denominator"],
    roots,
    fractions
  ];
  If[denominatorMap === $Failed || denominatorMap === <||>,
    Return[$Failed]
  ];
  rootValuation =
    coefficientSparseMinimumExponent[numeratorMap] -
    coefficientSparseMinimumExponent[denominatorMap];
  referenceMap = coefficientSparseShift[
    denominatorMap,
    rootValuation,
    roots,
    fractions
  ];
  If[referenceMap === $Failed, Return[$Failed]];
  keys = Union[Keys[numeratorMap], Keys[referenceMap]];
  pivot = SelectFirst[
    keys,
    coefficientZeroStatus[
      coefficientSparseLookup[referenceMap, #],
      timeLimit
    ] === False &,
    Missing["NoNonzeroPivot"]
  ];
  If[MissingQ[pivot], Return[$Failed]];
  referenceCoefficient = coefficientSparseLookup[referenceMap, pivot];
  numeratorCoefficient = coefficientSparseLookup[numeratorMap, pivot];
  checks = coefficientZeroStatus[
      coefficientSparseLookup[numeratorMap, #] referenceCoefficient -
        numeratorCoefficient coefficientSparseLookup[referenceMap, #],
      timeLimit
    ] & /@ keys;
  If[! AllTrue[checks, TrueQ], Return[$Failed]];
  hardCoefficient = coefficientCanonicalRational[
    numeratorCoefficient/referenceCoefficient,
    timeLimit
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, hardCoefficient] ||
      ! FreeQ[
        hardCoefficient,
        Alternatives @@ Join[fractions, roots]
      ],
    Return[$Failed]
  ];
  fractionValuation = AssociationThread[fractions, rootValuation/2];
  <|
    "Zero" -> False,
    "HardCoefficient" -> hardCoefficient,
    "LaurentValuation" -> fractionValuation,
    "BranchRules" -> Lookup[column, "BranchRules", {}],
    "LeafCount" -> Lookup[column, "LeafCount", 0]
  |>
];

coefficientPartitionByLengths[values_List, lengths_List] := Module[
  {offsets},
  offsets = Most @ FoldList[Plus, 0, lengths];
  MapThread[Take[values, {#1 + 1, #1 + #2}] &, {offsets, lengths}]
];

coefficientBalancedExactSum[expressions_List, timeLimit_: 60] := Module[
  {level, next},
  If[expressions === {}, Return[0]];
  level = expressions;
  While[Length[level] > 1,
    next = Map[
      Function[pair,
        coefficientCanonicalRational[Total[pair], timeLimit]
      ],
      Partition[level, UpTo[2]]
    ];
    If[AnyTrue[next, MemberQ[{$Failed, $TimedOut}, #] &], Return[$Failed]];
    level = next
  ];
  First[level]
];

coefficientContributionColumn[
    group_List,
    context_Association,
    timeLimit_: 60
  ] := Module[{nonzeroGroup, leaves, entries},
  nonzeroGroup = DeleteCases[group, 0];
  If[nonzeroGroup === {},
    Return[<|
      "Denominator" -> 1,
      "Numerator" -> <||>,
      "BranchRules" -> {},
      "LeafCount" -> Length[group]
    |>]
  ];
  leaves = coefficientFractionLeaf[#, context, timeLimit] & /@ nonzeroGroup;
  If[AnyTrue[leaves, MemberQ[{$Failed, $TimedOut}, #] &],
    Return[$Failed]
  ];
  entries = coefficientMergeFractionLeaves[
    leaves,
    context["FractionRootVariables"],
    context["FractionVariables"]
  ];
  If[entries === $Failed, Return[$Failed]];
  coefficientAssembleRootColumn[entries, context, timeLimit]
];

coefficientBranchSensitiveObjectQ[object_] := Which[
  AtomQ[Unevaluated[object]],
    False,
  Head[Unevaluated[object]] === Power,
    ! IntegerQ[object[[2]]],
  MemberQ[{Plus, Times, List}, Head[Unevaluated[object]]],
    False,
  Head[Unevaluated[object]] === HoldComplete,
    False,
  True,
    True
];

coefficientSimplifyWithFrozenBranches[
    expressions_List,
    assumptions_,
    timeLimit_: 60
  ] := Module[
  {
    objects, atoms, forward, backward, frozen, normalized,
    restored, checks
  },
  objects = DeleteDuplicates @ Cases[
    HoldComplete[expressions],
    object_ /; coefficientBranchSensitiveObjectQ[Unevaluated[object]] :>
      object,
    Infinity
  ];
  atoms = Array[Unique["branchObject$"] &, Length[objects]];
  forward = Dispatch[Thread[objects -> atoms]];
  backward = Dispatch[Thread[atoms -> objects]];
  frozen = expressions /. forward;
  normalized = parallelNormalizeCoefficients[
    frozen,
    assumptions,
    timeLimit,
    "Whole"
  ];
  If[normalized === $Failed, Return[$Failed]];
  restored = First[normalized] /. backward;
  checks = MapThread[
    TrueQ[
      coefficientCanonicalRational[
        (#1 /. forward) - (#2 /. forward),
        timeLimit
      ] === 0
    ] &,
    {expressions, restored}
  ];
  If[! AllTrue[checks, TrueQ], Return[$Failed]];
  <|
    "Expressions" -> restored,
    "FrozenBranchObjectCount" -> Length[objects],
    "FrozenBranchRegistryHash" -> Hash[
      HoldComplete[objects],
      "SHA256",
      "HexString"
    ],
    "Kernels" -> normalized[[2]],
    "AdditiveTerms" -> normalized[[3]],
    "ReconstructionVerified" -> True
  |>
];

simplifyHardCoefficientContributionGroups[
    groups_List,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    flat, distribution, strippedGroups, fractions, columns,
    certified, nonzero, valuations, valuation, monomial, hard,
    hardSimplification, remainingForbidden, branchRules, leafCount
  },
  flat = Flatten[groups, 1];
  If[
    ! AllTrue[flat, validateCoefficientBranchGrammar[#, context] &],
    Return[$Failed]
  ];
  distribution = coefficientNormalizeDistributionGroups[
    groups,
    context["ExpectedDistributionFactor"],
    context["PhysicalAssumptions"],
    timeLimit
  ];
  If[distribution === $Failed, Return[$Failed]];
  strippedGroups = distribution["Groups"];
  If[! AllTrue[
      Flatten[strippedGroups, 1],
      validateCoefficientBranchGrammar[#, context] &
    ],
    Return[$Failed]
  ];
  fractions = context["FractionVariables"];
  If[fractions === {},
    hard = coefficientBalancedExactSum[#, timeLimit] & /@ strippedGroups;
    If[MemberQ[hard, $Failed], Return[$Failed]];
    valuation = <||>;
    monomial = 1;
    branchRules = {};
    leafCount = Length[flat],
    columns = coefficientContributionColumn[
        #,
        context,
        timeLimit
      ] & /@ strippedGroups;
    If[AnyTrue[columns, MemberQ[{$Failed, $TimedOut}, #] &],
      Return[$Failed]
    ];
    certified = coefficientCertifyRootColumn[#, context, timeLimit] & /@
      columns;
    If[MemberQ[certified, $Failed], Return[$Failed]];
    nonzero = Select[certified, ! TrueQ[#1["Zero"]] &];
    If[nonzero === {},
      valuation = AssociationThread[fractions, ConstantArray[0, Length[fractions]]];
      monomial = 1,
      valuations = DeleteDuplicates[
        Lookup[nonzero, "LaurentValuation"],
        SameQ
      ];
      If[Length[valuations] =!= 1, Return[$Failed]];
      valuation = First[valuations];
      monomial = Times @@ MapThread[
        Power,
        {fractions, Lookup[valuation, fractions]}
      ]
    ];
    If[
      context["ExpectedLaurentValuation"] =!= Automatic &&
        ! SameQ[valuation, context["ExpectedLaurentValuation"]],
      Return[$Failed]
    ];
    hard = Lookup[certified, "HardCoefficient"];
    branchRules = DeleteDuplicates @ Flatten[
      Lookup[certified, "BranchRules"]
    ];
    leafCount = Total[Lookup[certified, "LeafCount"]]
  ];
  hardSimplification = coefficientSimplifyWithFrozenBranches[
    hard,
    context["PhysicalAssumptions"],
    timeLimit
  ];
  If[hardSimplification === $Failed, Return[$Failed]];
  hard = hardSimplification["Expressions"];
  remainingForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[hard, #] &
  ];
  If[
    remainingForbidden =!= {} ||
      ! AllTrue[hard, validateCoefficientBranchGrammar[#, context] &],
    Return[$Failed]
  ];
  <|
    "PreFactor" -> distribution["Factor"] monomial,
    "DistributionFactor" -> distribution["Factor"],
    "DistributionFactorStatus" -> distribution["Status"],
    "FractionVariables" -> fractions,
    "FractionMonomial" -> monomial,
    "LaurentValuation" -> valuation,
    "BranchRules" -> branchRules,
    "FrozenBranchObjectCount" ->
      hardSimplification["FrozenBranchObjectCount"],
    "FrozenBranchRegistryHash" ->
      hardSimplification["FrozenBranchRegistryHash"],
    "PositiveVariables" -> fractions,
    "Expressions" -> hard,
    "ForbiddenVariables" -> context["ForbiddenVariables"],
    "RemainingForbiddenVariables" -> {},
    "ContributionCount" -> leafCount
  |>
];

coefficientHomogeneousDegree[expression_, variable_Symbol] := Module[{walk},
  walk[node_] := Which[
    SameQ[Unevaluated[node], variable], 1,
    FreeQ[node, variable], 0,
    Head[Unevaluated[node]] === Plus,
      With[{degrees = DeleteDuplicates[walk /@ List @@ node]},
        If[Length[degrees] === 1 && FreeQ[degrees, $Failed],
          First[degrees],
          $Failed
        ]
      ],
    Head[Unevaluated[node]] === Times,
      With[{degrees = walk /@ List @@ node},
        If[FreeQ[degrees, $Failed], Total[degrees], $Failed]
      ],
    Head[Unevaluated[node]] === Power && FreeQ[node[[2]], variable],
      With[{degree = walk[node[[1]]]},
        If[degree === $Failed, $Failed, node[[2]] degree]
      ],
    True,
      $Failed
  ];
  walk[expression]
];

coefficientDimensionlessNormalize[
    expression_,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    scale, rules, inverseRules, transformed, degree,
    normalized, normalizedDimension, reconstructed, difference
  },
  scale = context["Scale"];
  rules = context["DimensionlessRules"];
  inverseRules = Normal[context["DimensionlessCoordinates"]];
  If[scale === None || rules === {},
    Return[<|
      "ScalePower" -> 0,
      "Expression" -> expression,
      "ReconstructionVerified" -> True
    |>]
  ];
  transformed = expression /. rules;
  degree = coefficientHomogeneousDegree[transformed, scale];
  If[degree === $Failed, Return[$Failed]];
  normalized = coefficientCanonicalRational[
    (transformed/scale^degree) /. scale -> 1,
    timeLimit
  ];
  normalizedDimension = coefficientMassDimension[
    normalized,
    context["KinematicMassDimensions"]
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, normalized] ||
      ! FreeQ[normalized, scale] ||
      ! TrueQ[normalizedDimension === 0] ||
      ! validateCoefficientBranchGrammar[normalized, context],
    Return[$Failed]
  ];
  reconstructed = scale^degree normalized /. inverseRules;
  difference = TimeConstrained[
    exactCoefficientNormalize[
      expression - reconstructed,
      context["PhysicalAssumptions"]
    ],
    timeLimit,
    $TimedOut
  ];
  If[difference =!= 0, Return[$Failed]];
  <|
    "ScalePower" -> degree,
    "Expression" -> normalized,
    "ReconstructionVerified" -> True
  |>
];

SimplifyHardCoefficients[
    input_List,
    setup_Association,
    OptionsPattern[]
  ] := Module[
  {
    context, method, timeLimit, groups, physical, lengths,
    normalization, dimensionless, remainingDimensionlessForbidden
  },
  method = OptionValue["Method"];
  timeLimit = OptionValue["TimeLimit"];
  If[
    ! MatchQ[timeLimit, Infinity | _Integer | _Real] ||
      (timeLimit =!= Infinity && timeLimit <= 0),
    Message[SimplifyHardCoefficients::input];
    Return[$Failed]
  ];
  If[method === Automatic,
    method = If[
      input =!= {} && AllTrue[input, ListQ],
      "ContributionWise",
      "Assembled"
    ]
  ];
  If[! MemberQ[{"Assembled", "ContributionWise"}, method],
    Message[SimplifyHardCoefficients::method, method];
    Return[$Failed]
  ];
  If[
    input === {} || ! exactDataQ[input] ||
      (method === "Assembled" && AnyTrue[input, ListQ]) ||
      (method === "ContributionWise" &&
        (! AllTrue[input, ListQ] || AnyTrue[input, # === {} &])),
    Message[SimplifyHardCoefficients::input];
    Return[$Failed]
  ];
  context = BuildSimplificationContext[setup];
  If[context === $Failed, Return[$Failed]];
  groups = If[method === "Assembled", List /@ input, input];
  lengths = Length /@ groups;
  physical = applyHadronicVariables[
    Flatten[groups, 1],
    context["HadronicVariables"]
  ];
  If[physical =!= $Failed,
    physical = coefficientPartitionByLengths[physical, lengths]
  ];
  If[physical === $Failed || ! exactDataQ[physical], Return[$Failed]];
  normalization = simplifyHardCoefficientContributionGroups[
    physical,
    context,
    timeLimit
  ];
  If[normalization === $Failed, Return[$Failed]];
  dimensionless = coefficientDimensionlessNormalize[
      #,
      context,
      timeLimit
    ] & /@ normalization["Expressions"];
  If[MemberQ[dimensionless, $Failed], Return[$Failed]];
  remainingDimensionlessForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[Lookup[dimensionless, "Expression"], #] &
  ];
  If[remainingDimensionlessForbidden =!= {}, Return[$Failed]];
  Join[
    KeyDrop[normalization, "Expressions"],
    <|
      "Method" -> method,
      "Expressions" -> normalization["Expressions"],
      "ScalePowers" -> Lookup[dimensionless, "ScalePower"],
      "DimensionlessExpressions" -> Lookup[dimensionless, "Expression"],
      "SimplificationContext" -> context
    |>
  ]
];

SimplifyHardCoefficients[___] := (
  Message[SimplifyHardCoefficients::input];
  $Failed
);

(* Shared finite-field reconstruction of exact master coefficients. *)

$finiteFieldReconstructionFormat =
  "FeynFacet-SharedFiniteFieldReconstruction";
$finiteFieldReconstructionVersion = 1;
$finiteFieldFailure = Unique["finiteFieldFailure$"];

CoefficientSimplification::finitefield =
  "Finite-field coefficient reconstruction failed during `1`: `2`.";

finiteFieldFail[stage_, detail_] := (
  coefficientProgressFailure[stage, detail];
  Message[CoefficientSimplification::finitefield, stage, detail];
  Throw[$Failed, $finiteFieldFailure]
);

finiteFieldResolveExecutable[value_] := Module[{environment, candidates},
  environment = Environment["FACET_RATRACER"];
  candidates = DeleteDuplicates @ Select[
    {
      value,
      If[ValueQ[Global`$FACETRatracerExecutable],
        Global`$FACETRatracerExecutable,
        Nothing
      ],
      If[StringQ[environment] && environment =!= "", environment, Nothing],
      FileNameJoin[{
        $feynFacetRoot, "Addon", "Other_Addon", "Ratracer", "bin",
        "ratracer"
      }],
      Quiet @ Check[FindExecutable["ratracer"], Nothing]
    },
    StringQ
  ];
  SelectFirst[
    candidates,
    FileExistsQ[#] && TrueQ[FileType[#] === File] &,
    $Failed
  ]
];

finiteFieldThreadCount[value_] := Which[
  IntegerQ[value] && value > 0, value,
  value === Automatic && ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] && Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
  value === Automatic, Max[1, $ProcessorCount],
  True, $Failed
];

finiteFieldPhysicalFactor[context_Association] := Module[
  {distribution, valuation, fractions},
  distribution = context["ExpectedDistributionFactor"];
  valuation = context["ExpectedLaurentValuation"];
  fractions = context["FractionVariables"];
  If[
    distribution === Automatic || ! AssociationQ[valuation] ||
      Sort[Keys[valuation]] =!= Sort[fractions],
    Return[$Failed]
  ];
  distribution Times @@ MapThread[
    Power,
    {fractions, Lookup[valuation, fractions]}
  ]
];

finiteFieldRationalQ[expression_] := Which[
  IntegerQ[expression] || MatchQ[expression, _Rational], True,
  Head[Unevaluated[expression]] === Symbol,
    ! MemberQ[
      {Pi, E, EulerGamma, I, Infinity, ComplexInfinity},
      Unevaluated[expression]
    ],
  Head[Unevaluated[expression]] === Plus ||
      Head[Unevaluated[expression]] === Times,
    AllTrue[List @@ expression, finiteFieldRationalQ],
  Head[Unevaluated[expression]] === Power && IntegerQ[expression[[2]]],
    finiteFieldRationalQ[expression[[1]]],
  True, False
];

finiteFieldSplitTerm[term_] := Module[
  {factors, rationalMask, rational, signature},
  factors = If[Head[term] === Times, List @@ term, {term}];
  rationalMask = finiteFieldRationalQ /@ factors;
  rational = Times @@ Pick[factors, rationalMask, True];
  signature = Times @@ Pick[factors, rationalMask, False];
  If[! SameQ[term, rational signature], Return[$Failed]];
  (HoldComplete @@ {signature}) -> rational
];

finiteFieldSignatureModule[expression_] := Module[
  {entries, merged},
  entries = finiteFieldSplitTerm /@ additiveTerms[expression];
  If[MemberQ[entries, $Failed], Return[$Failed]];
  merged = Merge[Association /@ entries, Total];
  Select[merged, ! TrueQ[# === 0] &]
];

finiteFieldCancel[expression_, timeLimit_] := Module[{result},
  result = If[
    timeLimit === Infinity,
    Quiet @ CheckAbort[Check[Cancel[expression], $Failed], $Failed],
    TimeConstrained[
      Quiet @ CheckAbort[Check[Cancel[expression], $Failed], $Failed],
      timeLimit,
      $TimedOut
    ]
  ];
  If[exactDataQ[result], result, $Failed]
];

finiteFieldForbiddenQ[expression_, context_Association] := Module[
  {forbidden, distributionObjects},
  forbidden = context["ForbiddenVariables"];
  distributionObjects = Cases[
    HoldComplete[expression],
    object_ /; coefficientDistributionObjectQ[Unevaluated[object]] :>
      HoldComplete[object],
    Infinity
  ];
  distributionObjects =!= {} ||
    AnyTrue[forbidden, ! FreeQ[expression, #] &] ||
    ! FreeQ[expression, System`D]
];

finiteFieldNormalizeTarget[
    expression_,
    distributionFactor_,
    liftedLaurentFactor_,
    context_Association,
    timeLimit_
  ] := Module[
  {
    physical, distributionFreeTerms, distributionFree,
    liftedData, lifted, terms, stripped, dimensionless, module
  },
  physical = applyHadronicVariables[
    expression,
    context["HadronicVariables"]
  ];
  If[
    physical === $Failed || ! exactDataQ[physical] ||
      ! validateCoefficientBranchGrammar[physical, context],
    Return[$Failed]
  ];
  distributionFreeTerms =
    finiteFieldCancel[#/distributionFactor, timeLimit] & /@
      additiveTerms[physical];
  If[MemberQ[distributionFreeTerms, $Failed | $TimedOut], Return[$Failed]];
  distributionFree = Total[distributionFreeTerms];
  If[
    ! FreeQ[
      distributionFree,
      object_ /; coefficientDistributionObjectQ[Unevaluated[object]]
    ],
    Return[$Failed]
  ];
  liftedData = coefficientPositiveRootLift[
    distributionFree,
    context,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, liftedData], Return[$Failed]];
  lifted = liftedData["Expression"];
  terms = finiteFieldCancel[#/liftedLaurentFactor, timeLimit] & /@
    additiveTerms[lifted];
  If[MemberQ[terms, $Failed | $TimedOut], Return[$Failed]];
  stripped = Total[terms];
  dimensionless = stripped /. context["DimensionlessRules"];
  dimensionless = finiteFieldCertifiedPowerExpand[
    dimensionless,
    context,
    timeLimit,
    context["DimensionlessAssumptions"]
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, dimensionless] ||
      ! exactDataQ[dimensionless] ||
      finiteFieldForbiddenQ[dimensionless, context],
    Return[$Failed]
  ];
  module = finiteFieldSignatureModule[dimensionless];
  If[
    module === $Failed ||
      ! AllTrue[Values[module], finiteFieldRationalQ] ||
      AnyTrue[
        Keys[module],
        finiteFieldForbiddenQ[ReleaseHold[#], context] &
      ],
    Return[$Failed]
  ];
  module
];

finiteFieldCertifiedPowerExpand[
    expression_,
    context_Association,
    timeLimit_,
    assumptions_: Automatic
  ] := Module[{bases, effectiveAssumptions, expanded},
  bases = DeleteDuplicates @ Cases[
    expression,
    Power[base_, exponent_] /; ! IntegerQ[exponent] :> base,
    Infinity
  ];
  effectiveAssumptions = Replace[
    assumptions,
    Automatic :> context["PhysicalAssumptions"]
  ];
  If[
    ! AllTrue[
      bases,
      coefficientCertifiedPositiveQ[
        #,
        effectiveAssumptions,
        Min[10, timeLimit]
      ] &
    ],
    Return[$Failed]
  ];
  expanded = PowerExpand[expression];
  finiteFieldCancel[expanded, timeLimit]
];

finiteFieldPrepareReductionCoefficient[
    expression_,
    metadata_Association,
    context_Association,
    timeLimit_
  ] := Module[{prepared, liftedData},
  prepared = expression /.
    metadata["ReverseRules"] /. metadata["DimensionRule"];
  prepared = applyHadronicVariables[
    prepared,
    context["HadronicVariables"]
  ];
  If[prepared === $Failed, Return[$Failed]];
  If[! validateCoefficientBranchGrammar[prepared, context], Return[$Failed]];
  liftedData = coefficientPositiveRootLift[prepared, context, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, liftedData], Return[$Failed]];
  prepared = finiteFieldCancel[liftedData["Expression"], timeLimit];
  If[
    MemberQ[{$Failed, $TimedOut}, prepared] ||
      ! FreeQ[
        prepared,
        Alternatives @@ context["FractionRootVariables"]
      ],
    Return[$Failed]
  ];
  prepared = finiteFieldCertifiedPowerExpand[prepared, context, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, prepared], Return[$Failed]];
  prepared = prepared /. context["DimensionlessRules"];
  If[
    ! exactDataQ[prepared] || ! finiteFieldRationalQ[prepared] ||
      finiteFieldForbiddenQ[prepared, context],
    $Failed,
    prepared
  ]
];

finiteFieldNormalizationKernelCount[value_, targetCount_Integer] := Module[
  {limit},
  limit = Which[
    IntegerQ[value] && value > 0,
      value,
    value === Automatic && ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
    value === Automatic,
      Min[8, $ProcessorCount],
    True,
      $Failed
  ];
  If[limit === $Failed, $Failed, Max[1, Min[limit, targetCount]]]
];

finiteFieldNormalizeTraceTarget[
    {target_, expression_, rhs_},
    workerData_Association
  ] := Module[
  {
    targetModule, image, preparedTerms, preparedRemainder,
    failedMaster
  },
  targetModule = finiteFieldNormalizeTarget[
    expression,
    workerData["DistributionFactor"],
    workerData["LiftedLaurentFactor"],
    workerData["Context"],
    workerData["TimeLimit"]
  ];
  If[
    targetModule === $Failed,
    Return @ Failure[
      "TargetNormalization",
      <|"Target" -> HoldComplete[target]|>
    ]
  ];
  image = linearIntegralSum[rhs];
  If[
    FailureQ[image],
    Return @ Failure["KiraImage", <|"Target" -> HoldComplete[target]|>]
  ];
  preparedTerms = Association @ KeyValueMap[
    Function[{master, coefficient},
      master -> finiteFieldPrepareReductionCoefficient[
        coefficient,
        workerData["ReductionMetadata"],
        workerData["Context"],
        workerData["TimeLimit"]
      ]
    ],
    image["Terms"]
  ];
  failedMaster = SelectFirst[
    Keys[preparedTerms],
    preparedTerms[#] === $Failed &,
    Missing["NotFound"]
  ];
  If[
    ! MissingQ[failedMaster],
    Return @ Failure[
      "KiraCoefficientNormalization",
      <|
        "Target" -> HoldComplete[target],
        "Master" -> HoldComplete[failedMaster]
      |>
    ]
  ];
  preparedRemainder = finiteFieldPrepareReductionCoefficient[
    image["Remainder"],
    workerData["ReductionMetadata"],
    workerData["Context"],
    workerData["TimeLimit"]
  ];
  If[
    preparedRemainder === $Failed,
    Return @ Failure[
      "KiraCoefficientNormalization",
      <|
        "Target" -> HoldComplete[target],
        "Detail" -> "the scalar remainder is not rational"
      |>
    ]
  ];
  <|
    "Target" -> target,
    "TargetModule" -> targetModule,
    "PreparedTerms" -> preparedTerms,
    "PreparedRemainder" -> preparedRemainder
  |>
];

finiteFieldNormalizeTraceBatch[batch_List] :=
  finiteFieldNormalizeTraceTarget[
    #,
    $finiteFieldTraceWorkerData
  ] & /@ batch;

finiteFieldMergeAssociationRecords[file_String, repeated_: True] := Module[
  {result = <||>, count},
  count = coefficientScanRecords[
    file,
    Function[record,
      If[! AssociationQ[record], Return[$Failed]];
      KeyValueMap[
        Function[{key, value},
          If[KeyExistsQ[result, key],
            If[repeated,
              AssociateTo[result, key -> (result[key] + value)],
              If[! SameQ[result[key], value], Return[$Failed]]
            ],
            AssociateTo[result, key -> value]
          ]
        ],
        record
      ];
      True
    ]
  ];
  If[count === $Failed, $Failed, result]
];

finiteFieldRationalSymbols[expression_] := DeleteDuplicates @ Cases[
  expression,
  symbol_Symbol /; finiteFieldRationalQ[symbol] :> symbol,
  Infinity,
  Heads -> False
];

finiteFieldToString[expression_, rules_] := Module[{text},
  text = ToString[
    expression /. rules,
    InputForm,
    CharacterEncoding -> "ASCII"
  ];
  StringReplace[text, WhitespaceCharacter .. -> ""]
];

finiteFieldTraceInputs[
    targetDirectory_String,
    store_String,
    metadata_Association,
    context_Association,
    physicalFactor_,
    directory_String,
    timeLimit_,
    maximumTargets_,
    normalizationKernels_: Automatic
  ] := Catch[
  Module[
    {
      manifest, shardCount, expectedByShard, expressionDirectory,
      distributionFactor, laurentFactor, liftedFactorData,
      liftedLaurentFactor, masters, masterIndices,
      signatures = {}, signatureBuckets = <||>, signatureID,
      symbolRules = <||>, aliasPrefix, registerSymbols, aliasRules,
      outputFiles = <||>, outputMetadata = <||>, firstTerm = <||>,
      contributionCounts = <||>, streams = <||>, streamOrder = {},
      streamLimit = 128, outputKey, outputFile, getStream, closeStreams,
      writeContribution, emitNormalizedTarget, targetTerms, ruleTerms,
      expected, keys, reductionString, masterIndex,
      processed = 0, selectedTargets, targetLimit, shard, remainder,
      remainderModule, outputOrder, traceVariables, signatureRegistry,
      workerCount, workerData, jobs, chunks, chunkSize,
      normalizedChunks, normalizedBatch, failedResult, processingResult,
      existingKernels, launchedKernels = {}, loadFile, initialized,
      closeWorkers, progressTotal
    },

    manifest = Get[coefficientStoreManifestFile[store]];
    shardCount = manifest["ShardCount"];
    expectedByShard = GroupBy[
      metadata["Targets"],
      coefficientShardIndex[#, shardCount] &
    ];
    expressionDirectory = FileNameJoin[{directory, "Expressions"}];
    CreateDirectory[
      expressionDirectory,
      CreateIntermediateDirectories -> True
    ];

    distributionFactor = context["ExpectedDistributionFactor"];
    laurentFactor = Cancel[physicalFactor/distributionFactor];
    liftedFactorData = coefficientPositiveRootLift[
      laurentFactor,
      context,
      timeLimit
    ];
    If[MemberQ[{$Failed, $TimedOut}, liftedFactorData],
      finiteFieldFail[
        "physical normalization",
        "the declared distribution and Laurent factor could not be lifted on the physical branch"
      ]
    ];
    liftedLaurentFactor = liftedFactorData["Expression"];

    masters = metadata["Masters"];
    masterIndices = AssociationThread[masters, Range[Length[masters]]];
    aliasPrefix = "FACETff" <>
      StringReplace[StringTake[CreateUUID[], 8], "-" -> ""] <> "v";

    signatureID[signature_] := Module[
      {hash, candidates, existing, id},
      hash = Hash[signature, "SHA256", "HexString"];
      candidates = Lookup[signatureBuckets, hash, {}];
      existing = SelectFirst[
        candidates,
        SameQ[signatures[[#]], signature] &,
        Missing["NotFound"]
      ];
      If[! MissingQ[existing], Return[existing]];
      AppendTo[signatures, signature];
      id = Length[signatures];
      AssociateTo[signatureBuckets, hash -> Append[candidates, id]];
      id
    ];

    registerSymbols[expression_] := Scan[
      Function[symbol,
        If[! KeyExistsQ[symbolRules, symbol],
          AssociateTo[
            symbolRules,
            symbol -> Symbol[
              "Global`" <> aliasPrefix <> ToString[Length[symbolRules] + 1]
            ]
          ]
        ]
      ],
      SortBy[
        finiteFieldRationalSymbols[expression],
        ToString[Unevaluated[#], InputForm] &
      ]
    ];

    outputKey[index_Integer, id_Integer] :=
      IntegerString[index, 10, 6] <> "_" <> IntegerString[id, 10, 6];

    getStream[key_String] := Module[{oldest, stream},
      If[KeyExistsQ[streams, key],
        streamOrder = Append[DeleteCases[streamOrder, key], key];
        Return[streams[key]]
      ];
      If[Length[streams] >= streamLimit,
        oldest = First[streamOrder];
        Close[streams[oldest]];
        KeyDropFrom[streams, oldest];
        streamOrder = Rest[streamOrder]
      ];
      stream = OpenAppend[outputFiles[key]];
      If[Head[stream] =!= OutputStream,
        finiteFieldFail["trace emission", "an expression file could not be opened"]
      ];
      AssociateTo[streams, key -> stream];
      AppendTo[streamOrder, key];
      stream
    ];

    closeStreams[] := (
      Scan[Close, Values[streams]];
      streams = <||>;
      streamOrder = {};
    );

    writeContribution[
        index_Integer,
        id_Integer,
        targetString_String,
        reductionCoefficient_
      ] := Module[{key, stream, separator},
      registerSymbols[reductionCoefficient];
      aliasRules = Dispatch[Normal[symbolRules]];
      reductionString = finiteFieldToString[
        reductionCoefficient,
        aliasRules
      ];
      key = outputKey[index, id];
      If[! KeyExistsQ[outputFiles, key],
        outputFile = FileNameJoin[{
          expressionDirectory,
          "Output_" <> key <> ".expr"
        }];
        If[FileExistsQ[outputFile], DeleteFile[outputFile]];
        Close[OpenWrite[outputFile]];
        AssociateTo[outputFiles, key -> outputFile];
        AssociateTo[firstTerm, key -> True];
        AssociateTo[contributionCounts, key -> 0];
        AssociateTo[
          outputMetadata,
          key -> <|
            "MasterIndex" -> index,
            "SignatureIndex" -> id
          |>
        ]
      ];
      stream = getStream[key];
      separator = If[TrueQ[firstTerm[key]], "", "+"];
      WriteString[
        stream,
        separator, "(", targetString, ")*(", reductionString, ")"
      ];
      firstTerm[key] = False;
      contributionCounts[key] = contributionCounts[key] + 1;
    ];

    emitNormalizedTarget[record_Association] := Module[
      {targetModule, preparedTerms, preparedRemainder},
      targetModule = record["TargetModule"];
      preparedTerms = record["PreparedTerms"];
      preparedRemainder = record["PreparedRemainder"];
      KeyValueMap[
        Function[{signature, rationalTarget},
          Module[{id, targetString},
            id = signatureID[signature];
            registerSymbols[rationalTarget];
            aliasRules = Dispatch[Normal[symbolRules]];
            targetString = finiteFieldToString[
              rationalTarget,
              aliasRules
            ];
            KeyValueMap[
              Function[{master, reductionCoefficient},
                masterIndex = Lookup[
                  masterIndices,
                  master,
                  Missing["UnknownMaster"]
                ];
                If[MissingQ[masterIndex],
                  finiteFieldFail["Kira image", HoldForm[master]]
                ];
                writeContribution[
                  masterIndex,
                  id,
                  targetString,
                  reductionCoefficient
                ]
              ],
              preparedTerms
            ];
            If[! TrueQ[preparedRemainder === 0],
              writeContribution[
                0,
                id,
                targetString,
                preparedRemainder
              ]
            ]
          ]
        ],
        targetModule
      ];
      processed++
    ];

    targetLimit = If[maximumTargets === All, Infinity, maximumTargets];
    If[
      ! (targetLimit === Infinity ||
          (IntegerQ[targetLimit] && targetLimit > 0)),
      finiteFieldFail[
        "trace emission",
        "MaximumTargets must be All or a positive integer"
      ]
    ];
    progressTotal = Min[targetLimit, Length[metadata["Targets"]]];
    coefficientProgressStart["Normalizing target coefficients", progressTotal];
    workerCount = finiteFieldNormalizationKernelCount[
      normalizationKernels,
      Min[
        Length[metadata["Targets"]],
        If[targetLimit === Infinity, Length[metadata["Targets"]], targetLimit]
      ]
    ];
    If[workerCount === $Failed,
      finiteFieldFail[
        "normalization kernel configuration",
        normalizationKernels
      ]
    ];
    workerData = <|
      "DistributionFactor" -> distributionFactor,
      "LiftedLaurentFactor" -> liftedLaurentFactor,
      "Context" -> context,
      "TimeLimit" -> timeLimit,
      "ReductionMetadata" -> KeyTake[
        metadata,
        {"ReverseRules", "DimensionRule"}
      ]
    |>;
    closeWorkers[] := (
      If[workerCount > 1 && Kernels[] =!= {},
        Quiet @ ParallelEvaluate[
          Clear[FeynFacet`Private`$finiteFieldTraceWorkerData],
          Kernels[]
        ]
      ];
      If[launchedKernels =!= {},
        Quiet[CloseKernels[launchedKernels]];
        launchedKernels = {}
      ]
    );
    If[workerCount > 1,
      existingKernels = Kernels[];
      If[Length[existingKernels] < workerCount,
        launchedKernels = LaunchKernels[
          workerCount - Length[existingKernels]
        ]
      ];
      If[Kernels[] === {},
        workerCount = 1,
        workerCount = Length[Kernels[]];
        loadFile = FileNameJoin[{
          $feynFacetRoot, "Addon", "Load", "LoadFACET.wl"
        }];
        initialized = With[{file = loadFile, data = workerData},
          And @@ ParallelEvaluate[
            Block[{$Output = {}, $Messages = {}},
              Global`$FeynCalcStartupMessages = False;
              Quiet[Get[file]];
              FeynFacet`Private`$finiteFieldTraceWorkerData = data;
              Length[
                DownValues[
                  FeynFacet`Private`finiteFieldNormalizeTraceBatch
                ]
              ] > 0
            ],
            Kernels[]
          ]
        ];
        If[! TrueQ[initialized],
          closeWorkers[];
          finiteFieldFail[
            "parallel target normalization",
            "the Mathematica workers did not initialize"
          ]
        ]
      ]
    ];

    processingResult = CheckAbort[
      Catch[
        Do[
          If[processed >= targetLimit, Break[]];
          targetTerms = finiteFieldMergeAssociationRecords[
            coefficientShardFile[targetDirectory, "Targets", shard],
            True
          ];
          ruleTerms = finiteFieldMergeAssociationRecords[
            coefficientShardFile[store, "Rules", shard],
            False
          ];
          If[targetTerms === $Failed || ruleTerms === $Failed,
            finiteFieldFail[
              "stored target reading",
              "a target or Kira-rule shard is invalid"
            ]
          ];
          expected = Lookup[expectedByShard, shard, {}];
          keys = Keys[targetTerms];
          If[
            Length[keys] =!= Length[expected] ||
              ! ContainsAll[keys, expected] ||
              ! ContainsAll[expected, keys],
            finiteFieldFail[
              "stored target reading",
              "the target and Kira shard keys differ"
            ]
          ];
          selectedTargets = Take[
            SortBy[keys, ToString[Unevaluated[#], InputForm] &],
            UpTo[
              If[
                targetLimit === Infinity,
                Length[keys],
                targetLimit - processed
              ]
            ]
          ];
          jobs = Function[currentTarget,
            {
              currentTarget,
              targetTerms[currentTarget] /. metadata["DimensionRule"],
              Lookup[ruleTerms, currentTarget, currentTarget]
            }
          ] /@ selectedTargets;
          normalizedBatch = If[workerCount === 1,
            finiteFieldNormalizeTraceTarget[#, workerData] & /@ jobs,
            chunkSize = Max[
              1,
              Ceiling[Length[jobs]/(4 workerCount)]
            ];
            chunks = Partition[jobs, UpTo[chunkSize]];
            normalizedChunks = ParallelMap[
              FeynFacet`Private`finiteFieldNormalizeTraceBatch,
              chunks,
              Method -> "FinestGrained",
              DistributedContexts -> None
            ];
            If[! ListQ[normalizedChunks],
              $Failed,
              Flatten[normalizedChunks, 1]
            ]
          ];
          failedResult = If[ListQ[normalizedBatch],
            SelectFirst[normalizedBatch, FailureQ, Missing["NotFound"]],
            $Failed
          ];
          If[
            normalizedBatch === $Failed || ! MissingQ[failedResult],
            finiteFieldFail[
              "parallel target normalization",
              If[failedResult === $Failed, "a worker failed", failedResult]
            ]
          ];
          Scan[emitNormalizedTarget, normalizedBatch];
          coefficientProgressUpdate[processed, progressTotal];
          Clear[
            targetTerms, ruleTerms, jobs, chunks, normalizedChunks,
            normalizedBatch
          ];
          ClearSystemCache[],
          {shard, shardCount}
        ];
        True,
        $finiteFieldFailure
      ],
      closeWorkers[];
      Abort[]
    ];
    closeWorkers[];
    If[processingResult === $Failed,
      Throw[$Failed, $finiteFieldFailure]
    ];

    If[processed >= Length[metadata["Targets"]],
      remainder = coefficientBalancedRecordTotal[
        FileNameJoin[{targetDirectory, "Remainder.bin"}]
      ];
      If[remainder === $Failed,
        finiteFieldFail["stored target reading", "the scalar remainder is invalid"]
      ];
      If[! TrueQ[remainder === 0],
        remainderModule = finiteFieldNormalizeTarget[
          remainder /. metadata["DimensionRule"],
          distributionFactor,
          liftedLaurentFactor,
          context,
          timeLimit
        ];
        If[remainderModule === $Failed,
          finiteFieldFail["target normalization", "the scalar remainder failed"]
        ];
        KeyValueMap[
          Function[{signature, rationalRemainder},
            Module[{id, targetString},
              id = signatureID[signature];
              registerSymbols[rationalRemainder];
              aliasRules = Dispatch[Normal[symbolRules]];
              targetString = finiteFieldToString[
                rationalRemainder,
                aliasRules
              ];
              writeContribution[0, id, targetString, 1]
            ]
          ],
          remainderModule
        ]
      ]
    ];

    closeStreams[];
    outputOrder = SortBy[
      Keys[outputFiles],
      {
        outputMetadata[#]["MasterIndex"],
        outputMetadata[#]["SignatureIndex"]
      } &
    ];
    Scan[
      Function[key,
        If[
          TrueQ[firstTerm[key]],
          Export[outputFiles[key], "0\n", "Text"],
          Module[{stream = OpenAppend[outputFiles[key]]},
            If[Head[stream] =!= OutputStream,
              finiteFieldFail[
                "trace emission",
                "an expression file could not be finalized"
              ]
            ];
            WriteString[stream, "\n"];
            Close[stream]
          ]
        ]
      ],
      outputOrder
    ];
    traceVariables = SortBy[
      Keys[symbolRules],
      ToString[Unevaluated[#], InputForm] &
    ];
    signatureRegistry = AssociationThread[
      Range[Length[signatures]],
      signatures
    ];
    <|
      "PhysicalFactor" -> physicalFactor,
      "NormalizationKernels" -> workerCount,
      "ProcessedTargetCount" -> processed,
      "CompleteTargetSet" -> TrueQ[processed === Length[metadata["Targets"]]],
      "TargetCount" -> Length[metadata["Targets"]],
      "Masters" -> masters,
      "Signatures" -> signatureRegistry,
      "SymbolRules" -> symbolRules,
      "Variables" -> traceVariables,
      "OutputOrder" -> outputOrder,
      "OutputFiles" -> Lookup[outputFiles, outputOrder],
      "OutputMetadata" -> Lookup[outputMetadata, outputOrder],
      "ContributionCounts" -> Lookup[contributionCounts, outputOrder],
      "ExpressionBytes" -> FileByteCount /@ Lookup[outputFiles, outputOrder]
    |>
  ],
  $finiteFieldFailure
];

finiteFieldRunProcess[arguments_List, directory_String, log_String] := Module[
  {temporary, command, result},
  temporary = FileNameJoin[{directory, "Temporary"}];
  If[DirectoryQ[temporary], DeleteDirectory[temporary, DeleteContents -> True]];
  CreateDirectory[temporary, CreateIntermediateDirectories -> True];
  command = Join[{"/usr/bin/env", "TMPDIR=" <> temporary}, arguments];
  result = RunProcess[command];
  Export[
    log,
    Lookup[result, "StandardOutput", ""] <>
      Lookup[result, "StandardError", ""],
    "Text"
  ];
  If[DirectoryQ[temporary], DeleteDirectory[temporary, DeleteContents -> True]];
  If[Lookup[result, "ExitCode", 1] === 0, result, $Failed]
];

finiteFieldBuildTrace[
    traceData_Association,
    executable_String,
    directory_String
  ] := Module[
  {traceFile, inputsFile, outputsFile, arguments, result, seconds},
  traceFile = FileNameJoin[{directory, "MasterCoefficients.trace.gz"}];
  inputsFile = FileNameJoin[{directory, "TraceInputs.txt"}];
  outputsFile = FileNameJoin[{directory, "TraceOutputs.txt"}];
  arguments = Join[
    {executable},
    Flatten[
      {"trace-expression", #} & /@ traceData["OutputFiles"]
    ],
    {
      "optimize", "finalize", "save-trace", traceFile,
      "list-inputs", "--to=" <> inputsFile,
      "list-outputs", "--to=" <> outputsFile
    }
  ];
  {seconds, result} = AbsoluteTiming @ finiteFieldRunProcess[
    arguments,
    directory,
    FileNameJoin[{directory, "BuildTrace.log"}]
  ];
  If[result === $Failed, Return[$Failed]];
  <|
    "TraceFile" -> traceFile,
    "InputsFile" -> inputsFile,
    "OutputsFile" -> outputsFile,
    "BuildSeconds" -> seconds,
    "TraceBytes" -> FileByteCount[traceFile]
  |>
];

finiteFieldParseRational[expression_, aliasNames_List] := Which[
  IntegerQ[expression] || MatchQ[expression, _Rational], True,
  Head[Unevaluated[expression]] === Symbol,
    MemberQ[aliasNames, SymbolName[Unevaluated[expression]]],
  Head[Unevaluated[expression]] === Plus ||
      Head[Unevaluated[expression]] === Times,
    AllTrue[
      List @@ expression,
      finiteFieldParseRational[#, aliasNames] &
    ],
  Head[Unevaluated[expression]] === Power && IntegerQ[expression[[2]]],
    finiteFieldParseRational[expression[[1]], aliasNames],
  True, False
];

finiteFieldParseReconstruction[
    file_String,
    outputFiles_List,
    symbolRules_Association
  ] := Module[
  {
    text, markers, positions, strings, held, aliasNames,
    aliasOriginals, parsedAliases, reverseRules, expressions
  },
  text = Import[file, "Text"];
  markers = (# <> " =") & /@ outputFiles;
  positions = StringPosition[text, #, 1] & /@ markers;
  If[AnyTrue[positions, # === {} &], Return[$Failed]];
  positions = First /@ positions;
  strings = Table[
    StringTrim @ StringReplace[
      StringTake[
        text,
        {
          positions[[index, 2]] + 1,
          If[index < Length[positions],
            positions[[index + 1, 1]] - 1,
            StringLength[text]
          ]
        }
      ],
      RegularExpression[";\\s*$"] -> ""
    ],
    {index, Length[positions]}
  ];
  held = Quiet @ Check[
    Map[ToExpression[#, InputForm, HoldComplete] &, strings],
    $Failed
  ];
  If[held === $Failed || Length[held] =!= Length[outputFiles],
    Return[$Failed]
  ];
  aliasNames = SymbolName /@ Values[symbolRules];
  aliasOriginals = AssociationThread[aliasNames, Keys[symbolRules]];
  expressions = ReleaseHold /@ held;
  If[
    ! AllTrue[
      expressions,
      finiteFieldParseRational[#, aliasNames] &
    ],
    Return[$Failed]
  ];
  parsedAliases = DeleteDuplicates @ Cases[
    expressions,
    symbol_Symbol /; MemberQ[aliasNames, SymbolName[symbol]] :> symbol,
    Infinity
  ];
  reverseRules = Dispatch[
    (# -> aliasOriginals[SymbolName[#]]) & /@ parsedAliases
  ];
  expressions /. reverseRules
];

finiteFieldReconstructTrace[
    traceData_Association,
    trace_Association,
    executable_String,
    directory_String,
    threads_Integer,
    factorScan_,
    shiftScan_
  ] := Module[
  {resultFile, arguments, result, seconds, expressions},
  resultFile = FileNameJoin[{directory, "Reconstructed.txt"}];
  arguments = Join[
    {
      executable, "load-trace", trace["TraceFile"], "reconstruct",
      "--to=" <> resultFile,
      "--threads=" <> ToString[threads],
      "--inmem"
    },
    If[TrueQ[factorScan], {"--factor-scan"}, {}],
    If[TrueQ[shiftScan], {"--shift-scan"}, {}]
  ];
  {seconds, result} = AbsoluteTiming @ finiteFieldRunProcess[
    arguments,
    directory,
    FileNameJoin[{directory, "Reconstruct.log"}]
  ];
  If[result === $Failed, Return[$Failed]];
  expressions = finiteFieldParseReconstruction[
    resultFile,
    traceData["OutputFiles"],
    traceData["SymbolRules"]
  ];
  If[expressions === $Failed, Return[$Failed]];
  <|
    "Expressions" -> expressions,
    "ResultFile" -> resultFile,
    "ReconstructionSeconds" -> seconds,
    "ResultBytes" -> FileByteCount[resultFile]
  |>
];

finiteFieldAssembleResult[
    data_Association,
    metadata_Association,
    kiraFile_String,
    context_Association,
    traceData_Association,
    trace_Association,
    reconstruction_Association,
    executable_String,
    threads_Integer
  ] := Module[
  {
    outputs, grouped, directRules, coefficients, remainder,
    recordsByName, equivalence, classByName, masterData,
    reconstructed, forbiddenMomenta, remainingMomenta,
    remainingFractionObjects, cutCheck,
    reconstructionData
  },
  outputs = MapThread[
    Join[#1, <|"RationalExpression" -> #2|>] &,
    {
      traceData["OutputMetadata"],
      reconstruction["Expressions"]
    }
  ];
  grouped = GroupBy[outputs, #1["MasterIndex"] &];
  directRules = Normal[context["DimensionlessCoordinates"]];
  coefficients = AssociationMap[
    Function[index,
      Total[
        Function[entry,
          ReleaseHold[
            traceData["Signatures"][entry["SignatureIndex"]]
          ] entry["RationalExpression"]
        ] /@ Lookup[grouped, index, {}]
      ] /. directRules
    ],
    Range[Length[traceData["Masters"]]]
  ];
  remainder = Total[
      Function[entry,
        ReleaseHold[
          traceData["Signatures"][entry["SignatureIndex"]]
        ] entry["RationalExpression"]
      ] /@ Lookup[grouped, 0, {}]
    ] /. directRules;
  recordsByName = Association[
    #1["Topology"][[1]] -> #1 & /@ metadata["Topologies"]
  ];
  equivalence = metadata["TopologyEquivalence"];
  classByName = If[
    AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
    Association[#1["Representative"] -> #1 & /@ equivalence["Classes"]],
    <||>
  ];
  masterData = DeleteCases[
    MapIndexed[
      Function[{master, position},
        Module[{coefficient, record},
          coefficient = coefficients[First[position]];
          If[TrueQ[coefficient === 0], Return[Nothing]];
          record = recordsByName[master[[1]]];
          <|
            "Master" -> master,
            "PreFactor" -> 1,
            "Coefficient" -> coefficient,
            "TopologyName" -> master[[1]],
            "CutMomenta" -> record["CutMomenta"],
            "CutIndices" -> record["CutIndices"],
            "CutDirections" -> record["CutDirections"],
            "TopologyClass" -> Lookup[
              classByName,
              master[[1]],
              Missing["NotFound"]
            ]
          |>
        ]
      ],
      traceData["Masters"]
    ],
    Nothing
  ];
  reconstructed = traceData["PhysicalFactor"] (
    Total[#1["Coefficient"] #1["Master"] & /@ masterData] + remainder
  );
  forbiddenMomenta = coefficientForbiddenMomenta[data["Setup"]];
  remainingMomenta = remainingDeclaredMomenta[
    {Lookup[masterData, "Coefficient"], remainder},
    forbiddenMomenta
  ];
  remainingFractionObjects = Select[
    Join[
      context["FractionVariables"],
      context["FractionRootVariables"]
    ],
    ! FreeQ[{Lookup[masterData, "Coefficient"], remainder}, #] &
  ];
  If[
    remainingMomenta =!= {} || remainingFractionObjects =!= {} ||
      ! FreeQ[reconstructed, System`D],
    Return[$Failed]
  ];
  cutCheck = validateCutGLIs[
    Lookup[masterData, "Master"],
    metadata["Topologies"]
  ];
  If[cutCheck =!= True, Return[$Failed]];
  reconstructionData = <|
    "Format" -> $finiteFieldReconstructionFormat,
    "FormatVersion" -> $finiteFieldReconstructionVersion,
    "Method" -> "SharedMultiOutputTrace",
    "CompleteTargetSet" -> traceData["CompleteTargetSet"],
    "ProcessedTargetCount" -> traceData["ProcessedTargetCount"],
    "TargetCount" -> traceData["TargetCount"],
    "OutputCount" -> Length[traceData["OutputOrder"]],
    "SignatureCount" -> Length[traceData["Signatures"]],
    "RationalVariableCount" -> Length[traceData["Variables"]],
    "TraceBytes" -> trace["TraceBytes"],
    "ReconstructedBytes" -> reconstruction["ResultBytes"],
    "TraceBuildSeconds" -> trace["BuildSeconds"],
    "ReconstructionSeconds" -> reconstruction["ReconstructionSeconds"],
    "Threads" -> threads,
    "RatracerExecutable" -> executable,
    "RatracerExecutableHash" -> FileHash[
      executable,
      "SHA256",
      "HexString"
    ],
    "TraceFile" -> trace["TraceFile"],
    "TraceFileHash" -> FileHash[
      trace["TraceFile"],
      "SHA256",
      "HexString"
    ],
    "ResultFile" -> reconstruction["ResultFile"],
    "ResultFileHash" -> FileHash[
      reconstruction["ResultFile"],
      "SHA256",
      "HexString"
    ]
  |>;
  Join[
    resultHeader["FeynFacet-IBP", 8],
    resultContext[data],
    <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> traceData["PhysicalFactor"],
      "Remainder" -> remainder,
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "HadronicNormalization" -> <|
        "PreFactor" -> traceData["PhysicalFactor"],
        "DistributionFactor" -> context["ExpectedDistributionFactor"],
        "LaurentValuation" -> context["ExpectedLaurentValuation"],
        "DimensionlessCoordinates" -> context["DimensionlessCoordinates"],
        "BranchGrammar" -> context["BranchGrammar"]
      |>,
      "FiniteFieldReconstruction" -> reconstructionData,
      "Topologies" -> metadata["Topologies"],
      "KiraArtifact" -> ExpandFileName[kiraFile],
      "ReverseRules" -> metadata["ReverseRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> metadata["MassDimensions"],
      "KiraManifest" -> metadata["KiraManifest"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> metadata["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> metadata["SourceInputFingerprint"]
    |>
  ]
];

finiteFieldCoefficientSimplificationCore[
    inputs_List,
    kiraFile_String,
    options_Association
  ] := Catch[
  Module[
    {
      executable, threads, normalizationKernels, timeLimit,
      maximumTargets, keepFiles,
      store, storeManifest, metadata, data, sortedPairs,
      coefficientSetup, resultSetup, processSetup, process,
      currentContext, resultData,
      workDirectory, targetDirectory, context, physicalFactor,
      traceDirectory, traceData, trace, reconstruction, result,
      manifestFile
    },
    coefficientProgressStart["Preparing coefficient inputs", 1];
    executable = finiteFieldResolveExecutable[
      options["RatracerExecutable"]
    ];
    threads = finiteFieldThreadCount[options["Threads"]];
    normalizationKernels = options["NormalizationKernels"];
    timeLimit = options["TargetTimeLimit"];
    maximumTargets = options["MaximumTargets"];
    keepFiles = TrueQ[options["KeepWorkingFiles"]];
    If[executable === $Failed,
      finiteFieldFail[
        "Ratracer discovery",
        "set FACET_RATRACER or install the executable under Addon/Other_Addon/Ratracer/bin"
      ]
    ];
    If[threads === $Failed,
      finiteFieldFail["thread configuration", options["Threads"]]
    ];
    If[
      ! MatchQ[timeLimit, Infinity | _Integer | _Real] ||
        (timeLimit =!= Infinity && timeLimit <= 0),
      finiteFieldFail["target time limit", timeLimit]
    ];

    store = coefficientEnsureKiraStore[kiraFile];
    If[store === $Failed,
      finiteFieldFail["Kira store", kiraFile]
    ];
    storeManifest = Get[coefficientStoreManifestFile[store]];
    metadata = coefficientReadRecord[coefficientStoreMetadataFile[store]];
    If[
      ! AssociationQ[metadata] ||
        ! coefficientKiraReductionQ[Append[metadata, "KiraRules" -> {}]],
      finiteFieldFail["Kira store", "the indexed metadata is invalid"]
    ];
    data = Block[
      {analyticContextQ = coefficientAnalyticContextQ},
      ibpInputData[inputs, False]
    ];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= metadata["CardName"] ||
        data["ResultDirectory"] =!= metadata["ResultDirectory"] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[metadata["Pairs"]],
      finiteFieldFail[
        "input validation",
        "the Kira artifact belongs to another diagram set"
      ]
    ];
    coefficientSetup = Lookup[options, "CoefficientSetup", Automatic];
    resultSetup = If[
      AssociationQ[coefficientSetup],
      Join[
        data["Setup"],
        KeyTake[coefficientSetup, $coefficientLateSetupKeys]
      ],
      data["Setup"]
    ];
    processSetup = Join[
      resultSetup,
      <|
        "ForwardAmplitudes" -> Append[
          resultSetup["ForwardAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Forward"]
        ],
        "ConjugateAmplitudes" -> Append[
          resultSetup["ConjugateAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Conjugate"]
        ]
      |>
    ];
    process = Catch[
      normalizeProcess[processSetup],
      $collinearFailure
    ];
    currentContext = If[
      AssociationQ[process],
      analyticContext[process],
      $Failed
    ];
    If[currentContext === $Failed,
      finiteFieldFail[
        "card validation",
        "the current card does not define a valid analytic context"
      ]
    ];
    resultData = Join[
      data,
      <|
        "Setup" -> resultSetup,
        "AnalyticContext" -> currentContext
      |>
    ];
    context = BuildSimplificationContext[resultSetup];
    If[context === $Failed,
      finiteFieldFail["card validation", "the simplification context is invalid"]
    ];
    physicalFactor = finiteFieldPhysicalFactor[context];
    If[physicalFactor === $Failed,
      finiteFieldFail[
        "card validation",
        "finite-field reconstruction requires a declared distribution factor and Laurent valuation"
      ]
    ];

    workDirectory = coefficientWorkDirectory[kiraFile];
    targetDirectory = FileNameJoin[{workDirectory, "TargetRecords"}];
    If[
      ! coefficientTargetStoreValidQ[
        data,
        metadata,
        targetDirectory,
        storeManifest["ShardCount"]
      ],
      coefficientProgressStart[
        "Collecting diagram-pair coefficients",
        Length[data["Sources"]]
      ];
      If[
        Block[
          {analyticContextQ = coefficientAnalyticContextQ},
          coefficientCollectTargetRecords[
            data,
            metadata,
            targetDirectory,
            storeManifest["ShardCount"]
          ]
        ] === $Failed,
        finiteFieldFail[
          "target collection",
          "the diagram-pair coefficients could not be indexed"
        ]
      ]
    ];

    traceDirectory = FileNameJoin[{workDirectory, "FiniteField"}];
    If[coefficientResetDirectory[traceDirectory] === $Failed,
      finiteFieldFail["working directory", traceDirectory]
    ];
    traceData = finiteFieldTraceInputs[
      targetDirectory,
      store,
      metadata,
      context,
      physicalFactor,
      traceDirectory,
      timeLimit,
      maximumTargets,
      normalizationKernels
    ];
    If[traceData === $Failed,
      finiteFieldFail["trace emission", "target normalization failed"]
    ];
    If[traceData["OutputFiles"] === {},
      finiteFieldFail["trace emission", "all reconstructed coefficients are zero"]
    ];
    coefficientProgressStage["Building the shared rational trace"];
    trace = finiteFieldBuildTrace[traceData, executable, traceDirectory];
    If[trace === $Failed,
      finiteFieldFail["shared trace construction", "Ratracer returned an error"]
    ];
    coefficientProgressStage["Reconstructing rational coefficients"];
    reconstruction = finiteFieldReconstructTrace[
      traceData,
      trace,
      executable,
      traceDirectory,
      threads,
      options["FactorScan"],
      options["ShiftScan"]
    ];
    If[reconstruction === $Failed,
      finiteFieldFail["rational reconstruction", "FireFly returned an error"]
    ];
    coefficientProgressStage["Assembling master coefficients"];
    result = finiteFieldAssembleResult[
      resultData,
      metadata,
      kiraFile,
      context,
      traceData,
      trace,
      reconstruction,
      executable,
      threads
    ];
    If[result === $Failed,
      finiteFieldFail[
        "result assembly",
        "the reconstructed coefficients violate the declared kinematics or cut data"
      ]
    ];
    coefficientProgressStage["Writing reconstruction metadata"];
    manifestFile = FileNameJoin[{traceDirectory, "Manifest.wl"}];
    Put[
      <|
        "Format" -> $finiteFieldReconstructionFormat,
        "FormatVersion" -> $finiteFieldReconstructionVersion,
        "InputFileFingerprint" -> coefficientInputFileFingerprint[
          data["Sources"]
        ],
        "KiraFileHash" -> coefficientFileHash[kiraFile],
        "PhysicalFactor" -> physicalFactor,
        "TraceData" -> KeyDrop[
          traceData,
          {"SymbolRules", "Signatures"}
        ],
        "Signatures" -> traceData["Signatures"],
        "SymbolRules" -> traceData["SymbolRules"],
        "Reconstruction" -> result["FiniteFieldReconstruction"]
      |>,
      manifestFile
    ];
    If[! keepFiles,
      If[DirectoryQ[FileNameJoin[{traceDirectory, "Expressions"}]],
        DeleteDirectory[
          FileNameJoin[{traceDirectory, "Expressions"}],
          DeleteContents -> True
        ]
      ]
    ];
    Print @ Grid[
      {
        {"Targets", traceData["ProcessedTargetCount"]},
        {"Normalization kernels", traceData["NormalizationKernels"]},
        {"Masters", Length[result["Masters"]]},
        {"Analytic signatures", Length[traceData["Signatures"]]},
        {"Shared outputs", Length[traceData["OutputOrder"]]},
        {"Trace size (MB)", Round[trace["TraceBytes"]/2.^20, 0.01]},
        {
          "FireFly time (s)",
          Round[reconstruction["ReconstructionSeconds"], 0.01]
        }
      },
      Frame -> All
    ];
    coefficientProgressFinish[];
    result
  ],
  $finiteFieldFailure
];
