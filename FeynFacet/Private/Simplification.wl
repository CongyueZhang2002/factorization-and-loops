(* Card-driven exact simplification of physical master coefficients. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[BuildSimplificationContext, SimplifyHardCoefficients];
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
  coefficientRootVariable,
  coefficientPositiveQuantities,
  coefficientRootSubstitutionSet,
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
  finiteFieldRootFail,
  finiteFieldRootMonomialData,
  finiteFieldRationalizePower,
  finiteFieldRationalize,
  finiteFieldCountDescend,
  finiteFieldRootFamilies,
  finiteFieldRootEvenRestore,
  finiteFieldRootPolynomialRestore,
  finiteFieldRootEvenOddParts,
  finiteFieldRootExactZeroQ,
  finiteFieldRootDescendReduced,
  finiteFieldRootDescend,
  finiteFieldDescendEntry,
  finiteFieldDescendEntries,
  finiteFieldTraceGrammarViolation,
  finiteFieldMonomialVariables,
  finiteFieldMonomialStep,
  finiteFieldMonomialSplit,
  finiteFieldEntryModule,
  finiteFieldCertifyRootFree,
  finiteFieldCombineSignatures,
  finiteFieldNormalizeTraceTarget,
  finiteFieldNormalizeTraceTargetCore,
  finiteFieldNormalizeTraceBatch,
  finiteFieldCoefficientSimplificationCore
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

(* Rationalizing square-root substitution variables (Design/
   RationalizedCoefficients.md).  Every quantity that the card region
   certifies positive - the momentum fractions, the scale and the
   dimensionless coordinates - can be traded for a dedicated positive
   root variable, q -> constant rootVariable^2, so that half-integer
   powers of monomials in those quantities become rational.  The
   constant is 2 for the declared scale, because the frame vectors
   carry s/2 combinations; it is 1 otherwise. *)

coefficientRootVariable[quantity_Symbol] :=
  Symbol["Global`FACETroot" <> SymbolName[quantity]];

coefficientPositiveQuantities[
    fractions_List,
    scale_,
    coordinates_List
  ] := DeleteDuplicates @ Join[
  fractions,
  If[MatchQ[scale, _Symbol], {scale}, {}],
  coordinates
];

(* The card's hadronic coordinates are the only source of half-integer
   powers in the coefficient pipeline, so the set of quantities that
   needs a root variable is fixed by the card and is the same for every
   target and every master coefficient of a run.  A quantity that never
   occurs under a root keeps its own name (no degree doubling); a root
   base that needs an undeclared one is a hard failure in
   finiteFieldRationalize, not a silent extension. *)
coefficientRootSubstitutionSet[
    hadronic_Association,
    quantities_List,
    scale_,
    dimensionlessRules_
  ] := Module[{coordinates, bases, needed},
  If[quantities === {}, Return[<||>]];
  coordinates = Values[Lookup[hadronic, "Coordinates", <||>]];
  bases = DeleteDuplicates @ Cases[
    coordinates /. dimensionlessRules,
    Power[base_, exponent_Rational /; ! IntegerQ[exponent]] :> base,
    {0, Infinity}
  ];
  needed = Select[quantities, ! FreeQ[bases, #] &];
  Association @ Map[
    Function[quantity,
      quantity -> <|
        "Root" -> coefficientRootVariable[quantity],
        "Constant" -> If[quantity === scale, 2, 1]
      |>
    ],
    needed
  ]
];

BuildSimplificationContext[config_Association] := Catch[
  Module[
    {
      hadronic, kinematics, sourceAssumptions, coordinateRegion,
      inferredFractions, fractions, roots, forbidden, scale, scalePositive,
      positiveQuantities, rootSubstitutions,
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
    positiveQuantities = coefficientPositiveQuantities[
      fractions,
      scale,
      Lookup[kinematics, "DimensionlessVariables", {}]
    ];
    rootSubstitutions = coefficientRootSubstitutionSet[
      hadronic,
      positiveQuantities,
      scale,
      kinematics["DimensionlessRules"]
    ];
    <|
      "FractionVariables" -> fractions,
      "FractionRootVariables" -> roots,
      "PositiveQuantities" -> positiveQuantities,
      "RootSubstitutions" -> rootSubstitutions,
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

(* Memoized per kernel: the same root-coefficient bases recur across
   thousands of targets, and a certification that succeeds once need
   not rerun FullSimplify. Only True is cached - a False may be a
   TimeConstrained artifact under load and must stay retryable. *)
coefficientCertifiedPositiveQ[
    expression_,
    assumptions_,
    timeLimit_: 60
  ] := With[
  {
    certified = TrueQ @ TimeConstrained[
      Quiet @ CheckAbort[
        Check[
          FullSimplify[expression > 0, Assumptions -> assumptions],
          False
        ],
        False
      ],
      timeLimit,
      False
    ]
  },
  If[certified,
    coefficientCertifiedPositiveQ[expression, assumptions, _] = True
  ];
  certified
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
            60
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
            Min[60, timeLimit]
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
$finiteFieldReconstructionVersion = 2;
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

(* --- rationalizing square-root substitution ------------------------ *)

$finiteFieldRootFailure = Unique["finiteFieldRootFailure$"];

CoefficientSimplification::rootbase =
  "A half-integer power survives rationalization: its base `1` is not an \
exact positive rational times a monomial in the declared positive \
quantities with a declared root substitution.";

CoefficientSimplification::rootparity =
  "A reconstructed coefficient is not even in the substitution variable \
`1`: the rationalized kinematics did not cancel.";

(* Structural decomposition base -> positive rational x monomial in the
   declared positive quantities.  Structural on purpose: positivity is
   read off the card region (0 < xa, xb, zh < 1, s > 0, x > 0, y > 0),
   never certified by FullSimplify. *)
finiteFieldRootMonomialData[base_, quantities_List] := Catch[
  Module[{factors, constant = 1, exponents},
    exponents = Association[# -> 0 & /@ quantities];
    factors = If[Head[base] === Times, List @@ base, {base}];
    Do[
      Which[
        KeyExistsQ[exponents, factor],
          exponents[factor] += 1,
        MatchQ[factor, Power[_, _Integer]] &&
            KeyExistsQ[exponents, factor[[1]]],
          exponents[factor[[1]]] += factor[[2]],
        MatchQ[factor, _Integer | _Rational] && TrueQ[factor > 0],
          constant *= factor,
        True,
          Throw[$Failed, $finiteFieldRootFailure]
      ],
      {factor, factors}
    ];
    <|"Constant" -> constant, "Exponents" -> exponents|>
  ],
  $finiteFieldRootFailure,
  $Failed &
];

(* Inject the value: HoldForm on the local symbol would leak the
   unevaluated variable name into the report. *)
finiteFieldRootFail[base_] := With[
  {reportedBase = base},
  Throw[HoldForm[reportedBase], $finiteFieldRootFailure]
];

(* base^(k/2) -> (rationalized base)^k.  The square root of the base is
   built symbolically: sqrt(constant) x product(rootVariable^power),
   with sqrt(constant) either rational or an exact constant root that
   the existing signature mechanism carries. *)
finiteFieldRationalizePower[
    power_,
    substitutions_Association,
    quantities_List
  ] := Module[{base, exponent, doubled, data, constant, monomial},
  base = power[[1]];
  exponent = power[[2]];
  If[FreeQ[base, Alternatives @@ quantities], Return[power]];
  doubled = 2 exponent;
  If[! IntegerQ[doubled], finiteFieldRootFail[base]];
  data = finiteFieldRootMonomialData[base, quantities];
  If[data === $Failed, finiteFieldRootFail[base]];
  constant = data["Constant"] Times @@ KeyValueMap[
    Function[{quantity, exponentValue},
      If[
        KeyExistsQ[substitutions, quantity],
        substitutions[quantity]["Constant"]^exponentValue,
        1
      ]
    ],
    data["Exponents"]
  ];
  monomial = Times @@ KeyValueMap[
    Function[{quantity, exponentValue},
      Which[
        KeyExistsQ[substitutions, quantity],
          substitutions[quantity]["Root"]^(exponentValue doubled),
        IntegerQ[exponentValue doubled/2],
          quantity^(exponentValue doubled/2),
        True,
          finiteFieldRootFail[base]
      ]
    ],
    data["Exponents"]
  ];
  constant^(doubled/2) monomial
];

(* No Cancel, no TimeConstrained, no FullSimplify: the reconstruction
   does not care whether the trace input is canceled. *)
finiteFieldRationalize[expression_, context_Association] := Catch[
  Module[{substitutions, quantities, powers, rules, substitutionRules},
    substitutions = Lookup[context, "RootSubstitutions", <||>];
    quantities = Lookup[context, "PositiveQuantities", {}];
    If[! AssociationQ[substitutions] || quantities === {},
      Return[expression]
    ];
    (* Level 0 included: a bare Sqrt can be the whole expression. *)
    powers = DeleteDuplicates @ Cases[
      expression,
      power : Power[_, _Rational] /; ! IntegerQ[power[[2]]] :> power,
      {0, Infinity}
    ];
    rules = Map[
      # -> finiteFieldRationalizePower[#, substitutions, quantities] &,
      powers
    ];
    substitutionRules = KeyValueMap[
      Function[{quantity, substitutionData},
        quantity -> substitutionData["Constant"] substitutionData["Root"]^2
      ],
      substitutions
    ];
    If[substitutionRules === {} && rules === {}, Return[expression]];
    (expression /. Dispatch[rules]) /. Dispatch[substitutionRules]
  ],
  $finiteFieldRootFailure,
  (Message[CoefficientSimplification::rootbase, #1]; $Failed) &
];

(* --- exact descend from the root ring back to physical variables ---

   Ported from the 2026-08-08 hadronic-simplification study
   (Codex/Documentation/HadronicCoefficientSimplification_2026-08-08/
   scripts/NNLOInvariantRootRing.wl).

   finiteFieldRationalize lifts an additive entry into Q(physical)[root].
   That lift must stay transient: FireFly probes the black box in the
   variables it is handed, and a root variable doubles the effective
   degree of its invariant (measured: ~100-fold probe inflation at NNLO,
   WORKLOG 2026-08-11).  The trace is therefore emitted in the physical
   variables, and the lift is undone here - entry by entry, before
   anything is written.

   For one family, an entry is N(r)/D(r) with r^2 = invariant.  Writing
   N = Ne + r No and D = De + r Do with Ne, No, De, Do free of r, the
   quotient is invariant under the branch flip r -> -r exactly when
   Ne Do - No De = 0, and then N/D = Ne/De.  The exact-zero
   certification runs on that SMALL combination only - never on a whole
   output.  Entries whose root content is already even skip the descend
   completely: their powers are restored structurally, with no rational
   algebra at all. *)

CoefficientSimplification::rootdescend =
  "An additive entry does not descend to the physical variables: its \
dependence on the root variable `1` is not even, and neither \
equal-denominator merging nor the merged remainder certified the odd \
part exactly zero.";

(* Per-kernel descend telemetry.  Block-bound around one target so the
   counters travel back with that target's record; Null outside means
   "not counting", never an error. *)
$finiteFieldDescendCounters = Null;

finiteFieldCountDescend[key_String, amount_: 1] := If[
  AssociationQ[$finiteFieldDescendCounters],
  $finiteFieldDescendCounters[key] =
    Lookup[$finiteFieldDescendCounters, key, 0] + amount
];

(* {root variable, invariant} per family; r^2 = quantity/constant. *)
finiteFieldRootFamilies[context_Association] := Module[{substitutions},
  substitutions = Lookup[context, "RootSubstitutions", <||>];
  If[! AssociationQ[substitutions], Return[{}]];
  KeyValueMap[
    Function[{quantity, substitutionData},
      {substitutionData["Root"], quantity/substitutionData["Constant"]}
    ],
    substitutions
  ]
];

finiteFieldRootEvenRestore[expression_, root_Symbol, invariant_] := With[
  {rootVariable = root, value = invariant},
  expression /. HoldPattern[
    Power[rootVariable, exponent_Integer /; EvenQ[exponent]]
  ] :> value^(exponent/2)
];

finiteFieldRootPolynomialRestore[
    polynomial_,
    root_Symbol,
    invariant_
  ] := Module[{direct, rules},
  direct = finiteFieldRootEvenRestore[polynomial, root, invariant];
  If[FreeQ[direct, root], Return[direct]];
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  If[! AllTrue[rules, EvenQ[First[First[#]]] &], Return[$Failed]];
  Total[(Last[#] invariant^(First[First[#]]/2)) & /@ rules]
];

finiteFieldRootEvenOddParts[
    polynomial_,
    root_Symbol,
    invariant_
  ] := Module[{rules},
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  <|
    "Even" -> Total @ Cases[
      rules,
      Rule[{power_Integer?EvenQ}, coefficient_] :>
        coefficient invariant^(power/2)
    ],
    "Odd" -> Total @ Cases[
      rules,
      Rule[{power_Integer?OddQ}, coefficient_] :>
        coefficient invariant^((power - 1)/2)
    ]
  |>
];

finiteFieldRootExactZeroQ[expression_, timeLimit_] := Module[{result},
  If[TrueQ[expression === 0], Return[True]];
  finiteFieldCountDescend["OddCertifications"];
  result = TimeConstrained[
    Quiet @ CheckAbort[
      Check[TrueQ[Cancel[Together[expression]] === 0], False],
      False
    ],
    timeLimit,
    $TimedOut
  ];
  If[result === $TimedOut, finiteFieldCountDescend["TimeConstrainedHits"]];
  result
];

(* The expression must already be a reduced N/D in the root variable. *)
finiteFieldRootDescendReduced[
    expression_,
    root_Symbol,
    invariant_,
    timeLimit_
  ] := Module[
  {
    numerator, denominator, restoredNumerator, restoredDenominator,
    numeratorParts, denominatorParts, pe, po, qe, qo, oddStatus,
    evenStatus, result
  },
  numerator = Numerator[expression];
  denominator = Denominator[expression];
  restoredNumerator = finiteFieldRootPolynomialRestore[
    numerator, root, invariant
  ];
  restoredDenominator = finiteFieldRootPolynomialRestore[
    denominator, root, invariant
  ];
  If[
    FreeQ[{restoredNumerator, restoredDenominator}, $Failed],
    finiteFieldCountDescend["EvenEntries"];
    Return @ finiteFieldCancel[
      restoredNumerator/restoredDenominator,
      timeLimit
    ]
  ];
  numeratorParts = finiteFieldRootEvenOddParts[numerator, root, invariant];
  denominatorParts = finiteFieldRootEvenOddParts[
    denominator, root, invariant
  ];
  If[MemberQ[{numeratorParts, denominatorParts}, $Failed],
    Return[$Failed]
  ];
  {pe, po} = Lookup[numeratorParts, {"Even", "Odd"}];
  {qe, qo} = Lookup[denominatorParts, {"Even", "Odd"}];
  (* The only nontrivial certification of the method, on the small
     combination pe qo - po qe - not on the entry itself. *)
  oddStatus = finiteFieldRootExactZeroQ[pe qo - po qe, timeLimit];
  If[oddStatus =!= True, Return[$Failed]];
  evenStatus = finiteFieldRootExactZeroQ[qe, timeLimit];
  result = Which[
    evenStatus === False, pe/qe,
    evenStatus === True,
      If[finiteFieldRootExactZeroQ[qo, timeLimit] === False,
        po/qo,
        Return[$Failed]
      ],
    True, Return[$Failed]
  ];
  finiteFieldCountDescend["DescendedEntries"];
  finiteFieldCancel[result, timeLimit]
];

finiteFieldRootDescend[
    expression_,
    root_Symbol,
    invariant_,
    timeLimit_
  ] := Module[{restored, rational, result},
  (* Structural first: an entry whose root powers are already even -
     the measured norm - never enters rational algebra at all. *)
  restored = finiteFieldRootEvenRestore[expression, root, invariant];
  If[FreeQ[restored, root],
    finiteFieldCountDescend["StructuralEntries"];
    Return[restored]
  ];
  rational = TimeConstrained[
    Quiet @ CheckAbort[
      Check[Cancel[Together[expression]], $Failed],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];
  If[rational === $TimedOut,
    finiteFieldCountDescend["TimeConstrainedHits"]
  ];
  If[MemberQ[{$Failed, $TimedOut}, rational], Return[$Failed]];
  result = finiteFieldRootDescendReduced[
    rational, root, invariant, timeLimit
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, result] || ! FreeQ[result, root] ||
      ! exactDataQ[result],
    $Failed,
    result
  ]
];

finiteFieldDescendEntry[entry_, families_List, timeLimit_] := Catch @ Module[
  {current = entry, descended},
  Do[
    If[FreeQ[current, First[family]], Continue[]];
    descended = finiteFieldRootDescend[
      current, First[family], Last[family], timeLimit
    ];
    If[descended === $Failed, Throw[$Failed]];
    current = descended,
    {family, families}
  ];
  current
];

(* Entry granularity of the 2026-08-08 study: descend the small pieces
   first and merge only exactly equal denominators when a piece does not
   descend on its own.  A whole-output Together never happens. *)
finiteFieldDescendEntries[
    entries_List,
    families_List,
    timeLimit_
  ] := Module[
  {roots, values, descended, residues, groups, sums, merged, failedRoot},
  If[families === {} || entries === {}, Return[entries]];
  roots = First /@ families;
  finiteFieldCountDescend["Entries", Length[entries]];
  values = Map[
    Function[entry,
      If[
        FreeQ[entry, Alternatives @@ roots],
        entry,
        finiteFieldDescendEntry[entry, families, timeLimit]
      ]
    ],
    entries
  ];
  descended = DeleteCases[values, $Failed];
  residues = MapThread[
    If[#2 === $Failed, #1, Nothing] &,
    {entries, values}
  ];
  If[residues === {}, Return[descended]];
  finiteFieldCountDescend["MergedEntries", Length[residues]];
  groups = Values @ GroupBy[residues, Denominator];
  sums = Total /@ groups;
  values = finiteFieldDescendEntry[#, families, timeLimit] & /@ sums;
  descended = Join[descended, DeleteCases[values, $Failed]];
  residues = MapThread[
    If[#2 === $Failed, #1, Nothing] &,
    {sums, values}
  ];
  If[residues === {}, Return[descended]];
  finiteFieldCountDescend["MergedRemainders"];
  merged = finiteFieldDescendEntry[Total[residues], families, timeLimit];
  If[merged === $Failed,
    failedRoot = SelectFirst[
      roots,
      ! FreeQ[residues, #] &,
      First[roots]
    ];
    Message[CoefficientSimplification::rootdescend, failedRoot];
    Return[$Failed]
  ];
  Append[descended, merged]
];

(* --- monomial variables carried by the signature, not by the trace ---

   Every entry is a monomial in the declared scale (mass-dimension
   homogeneity: exact on all measured outputs, WORKLOG 2026-08-11 16:30)
   and in the strong coupling.  Those powers ride along in the inert
   signature, so the trace variables reduce to the genuine rational
   kinematics.  The degree is read off structurally with the card's mass
   dimensions - no symbolic algebra, no evaluation at sample points.
   An entry that is not homogeneous simply keeps the variable: the
   emission stays exact, only the variable count grows. *)
finiteFieldMonomialVariables[context_Association] := Module[
  {scale, dimensions, scaleDimension},
  scale = Lookup[context, "Scale", None];
  dimensions = Lookup[context, "KinematicMassDimensions", <||>];
  scaleDimension = If[
    AssociationQ[dimensions] && MatchQ[scale, _Symbol],
    Lookup[dimensions, scale, 0],
    0
  ];
  Join[
    If[
      MatchQ[scale, _Symbol] && NumberQ[scaleDimension] &&
        TrueQ[scaleDimension > 0],
      {<|
        "Variable" -> scale,
        "Dimensions" -> KeyTake[dimensions, {scale}],
        "Unit" -> scaleDimension
      |>},
      {}
    ],
    {<|
      "Variable" -> FeynFacet`\[Alpha]s,
      "Dimensions" -> <|FeynFacet`\[Alpha]s -> 1|>,
      "Unit" -> 1
    |>}
  ]
];

finiteFieldMonomialStep[
    {monomial_, current_},
    data_Association
  ] := Module[{variable, degree, reduced},
  variable = data["Variable"];
  If[FreeQ[current, variable], Return[{monomial, current}]];
  degree = coefficientMassDimension[current, data["Dimensions"]];
  If[! NumberQ[degree], Return[{monomial, current}]];
  degree = degree/data["Unit"];
  If[! IntegerQ[degree], Return[{monomial, current}]];
  reduced = current /. variable -> 1;
  If[! FreeQ[reduced, variable], Return[{monomial, current}]];
  {monomial variable^degree, reduced}
];

finiteFieldMonomialSplit[entry_, monomialVariables_List] :=
  Fold[finiteFieldMonomialStep, {1, entry}, monomialVariables];

(* Signature module of a list of descended entries: an Association from
   an exact non-rational signature to an expression rational in the
   trace variables. *)
finiteFieldEntryModule[
    entries_List,
    monomialVariables_List
  ] := Module[{records},
  records = Catch @ Map[
    Function[term,
      Module[{monomial, reduced, split},
        {monomial, reduced} = finiteFieldMonomialSplit[
          term, monomialVariables
        ];
        split = finiteFieldSplitTerm[reduced];
        If[split === $Failed, Throw[$Failed]];
        If[
          TrueQ[monomial === 1],
          split,
          With[
            {signature = ReleaseHold[First[split]] monomial},
            (HoldComplete @@ {signature}) -> Last[split]
          ]
        ]
      ]
    ],
    Flatten[additiveTerms /@ entries, 1]
  ];
  If[records === $Failed, Return[$Failed]];
  Select[Merge[Association /@ records, Total], ! TrueQ[# === 0] &]
];

CoefficientSimplification::tracegrammar =
  "A normalized `1` is not rational in the physical trace variables: \
`2` survives the entrywise root descend.";

(* The offending object itself, so a normalization failure names its
   cause instead of only its target. *)
finiteFieldTraceGrammarViolation[
    expression_,
    context_Association
  ] := Module[{candidates, offenders},
  candidates = Join[
    First /@ finiteFieldRootFamilies[context],
    Lookup[context, "ForbiddenVariables", {}],
    {System`D}
  ];
  offenders = Select[candidates, ! FreeQ[expression, #] &];
  Which[
    offenders =!= {},
      First[offenders],
    finiteFieldForbiddenQ[expression, context],
      HoldForm["a distribution object"],
    True,
      None
  ]
];

(* Post-reconstruction guard.  The descend leaves no root variable in
   the trace, so a reconstructed coefficient that carries one is a
   regression, not a parity accident: report it with the parity message
   the root-variable path used. *)
finiteFieldCertifyRootFree[
    expression_,
    context_Association
  ] := Module[{substitutions, roots, remaining},
  substitutions = Lookup[context, "RootSubstitutions", <||>];
  If[! AssociationQ[substitutions] || substitutions === <||>,
    Return[expression]
  ];
  roots = #["Root"] & /@ Values[substitutions];
  remaining = Select[roots, ! FreeQ[expression, #] &];
  If[remaining =!= {},
    Message[CoefficientSimplification::rootparity, First[remaining]];
    Return[$Failed]
  ];
  expression
];

(* Constant roots that rationalization leaves behind (Sqrt[2] from a
   base carrying an odd power of 2) ride along in the signature. *)
finiteFieldCombineSignatures[
    first_HoldComplete,
    second_HoldComplete
  ] := Which[
  second === HoldComplete[1], first,
  first === HoldComplete[1], second,
  True,
    With[
      {value = ReleaseHold[first] ReleaseHold[second]},
      HoldComplete[value]
    ]
];

(* --- signature canonicalization modulo the trace-variable field -----

   Trace classes are equal modulo the multiplicative group of the
   rational function field of the trace variables (Codex convention,
   2026-08-11): any factor of a signature that is rational in the trace
   variables belongs to the coefficient, e.g. 2^(m + n Epsilon) puts
   2^m into the coefficient and keeps 2^(n Epsilon).  Without this,
   classes fragment into buckets differing by 2^k (measured: master 107
   split into 9 buckets, master 1 into 13 buckets of one rational
   class), which multiplies the FireFly probe count.  The declared
   scale and the strong coupling route through signatures and are never
   folded. *)

finiteFieldFoldableFactorQ[expression_, excluded_List] :=
  finiteFieldRationalQ[expression] &&
    FreeQ[expression, Alternatives @@ excluded];

(* base^exponent with the integer part of the exponent's exact-number
   component split off: {folded factor, kept factor}.  Splitting an
   INTEGER power off b^(m + r) -> b^m b^r is an exact identity for any
   nonzero base; no positivity assumption is used. *)
finiteFieldResidualPower[base_, exponent_] := Module[
  {terms, constant, integerPart, residual},
  terms = If[Head[exponent] === Plus, List @@ exponent, {exponent}];
  constant = Total @ Cases[terms, _Integer | _Rational];
  integerPart = Floor[constant];
  residual = exponent - integerPart;
  Which[
    TrueQ[residual === 0], {base^integerPart, 1},
    IntegerQ[residual], {base^(integerPart + residual), 1},
    True, {If[integerPart === 0, 1, base^integerPart], base^residual}
  ]
];

finiteFieldCanonicalizeSignature[
    held_HoldComplete,
    excluded_List
  ] := Module[
  {signature, factors, fold = 1, keep = {}, primes = <||>, bases = <||>,
   resolve},
  signature = ReleaseHold[held];
  If[finiteFieldFoldableFactorQ[signature, excluded],
    Return[{HoldComplete[1], signature}]
  ];
  factors = If[Head[signature] === Times, List @@ signature, {signature}];
  Scan[
    Function[factor,
      Which[
        finiteFieldFoldableFactorQ[factor, excluded],
          fold *= factor,
        (* A rational-number base decomposes over its primes: b^e with
           b = sign * Times[p^a] is exactly Times[p^(a e)] (positive
           base, principal branch), so 4^Epsilon and 2^(2 Epsilon) land
           in one class.  Exponents accumulate per prime, so pairs like
           2^Epsilon * 2^(1 - Epsilon) collapse before folding. *)
        MatchQ[factor, Power[_Integer | _Rational, _]],
          Module[{base = factor[[1]], exponent = factor[[2]], magnitude},
            magnitude = If[base < 0,
              primes[-1] = Lookup[primes, -1, 0] + exponent; -base,
              base
            ];
            Scan[
              If[#[[1]] =!= 1,
                primes[#[[1]]] = Lookup[primes, #[[1]], 0] + #[[2]] exponent
              ] &,
              FactorInteger[magnitude]
            ]
          ],
        MatchQ[factor, Power[_, _]] &&
            finiteFieldFoldableFactorQ[factor[[1]], excluded],
          bases[factor[[1]]] = Lookup[bases, factor[[1]], 0] + factor[[2]],
        True,
          AppendTo[keep, factor]
      ]
    ],
    factors
  ];
  resolve = Function[{base, exponent},
    Module[{pair = finiteFieldResidualPower[base, exponent]},
      fold *= First[pair];
      Last[pair]
    ]
  ];
  keep = Join[
    KeyValueMap[resolve, KeySort[primes]],
    KeyValueMap[
      resolve,
      KeySortBy[bases, ToString[#, InputForm] &]
    ],
    keep
  ];
  With[
    {canonical = Times @@ keep},
    {HoldComplete[canonical], fold}
  ]
];

finiteFieldNormalizeTarget[
    expression_,
    distributionFactor_,
    rationalLaurentFactor_,
    context_Association,
    timeLimit_
  ] := Module[
  {
    physical, distributionFreeTerms, distributionFree,
    dimensionless, rationalized, terms, descended, violation, module
  },
  physical = applyHadronicVariables[
    expression,
    context["HadronicVariables"]
  ];
  If[
    physical === $Failed || ! exactDataQ[physical],
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
  dimensionless = distributionFree /. context["DimensionlessRules"];
  rationalized = finiteFieldRationalize[dimensionless, context];
  If[rationalized === $Failed, Return[$Failed]];
  terms = finiteFieldCancel[#/rationalLaurentFactor, timeLimit] & /@
    additiveTerms[rationalized];
  If[MemberQ[terms, $Failed | $TimedOut], Return[$Failed]];
  descended = finiteFieldDescendEntries[
    terms,
    finiteFieldRootFamilies[context],
    timeLimit
  ];
  If[descended === $Failed, Return[$Failed]];
  violation = finiteFieldTraceGrammarViolation[descended, context];
  If[! exactDataQ[descended] || violation =!= None,
    Message[
      CoefficientSimplification::tracegrammar,
      "target coefficient",
      Replace[violation, None -> HoldForm["inexact data"]]
    ];
    Return[$Failed]
  ];
  module = finiteFieldEntryModule[
    descended,
    finiteFieldMonomialVariables[context]
  ];
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

(* Returns the signature module of the rationalized Kira coefficient:
   an Association from an exact non-rational signature (normally 1) to
   an expression rational in the trace variables. *)
finiteFieldPrepareReductionCoefficient[
    expression_,
    metadata_Association,
    context_Association,
    timeLimit_
  ] := Module[{prepared, descended, violation, module},
  prepared = expression /.
    metadata["ReverseRules"] /. metadata["DimensionRule"];
  prepared = applyHadronicVariables[
    prepared,
    context["HadronicVariables"]
  ];
  If[prepared === $Failed || ! exactDataQ[prepared], Return[$Failed]];
  prepared = prepared /. context["DimensionlessRules"];
  prepared = finiteFieldRationalize[prepared, context];
  If[prepared === $Failed, Return[$Failed]];
  descended = finiteFieldDescendEntries[
    additiveTerms[prepared],
    finiteFieldRootFamilies[context],
    timeLimit
  ];
  If[descended === $Failed, Return[$Failed]];
  violation = finiteFieldTraceGrammarViolation[descended, context];
  If[! exactDataQ[descended] || violation =!= None,
    Message[
      CoefficientSimplification::tracegrammar,
      "Kira reduction coefficient",
      Replace[violation, None -> HoldForm["inexact data"]]
    ];
    Return[$Failed]
  ];
  module = finiteFieldEntryModule[
    descended,
    finiteFieldMonomialVariables[context]
  ];
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

finiteFieldNormalizationKernelCount[value_, targetCount_Integer] := Module[
  {limit},
  limit = Which[
    IntegerQ[value] && value > 0,
      value,
    value === Automatic && ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      facetKernelCount[Global`$FACETKernelLimit, targetCount],
    value === Automatic,
      facetKernelCount[Automatic, targetCount],
    True,
      $Failed
  ];
  If[limit === $Failed, $Failed,
    facetKernelCount[limit, targetCount]]
];

finiteFieldNormalizeTraceTarget[
    job_List,
    workerData_Association
  ] := Block[
  {$finiteFieldDescendCounters = <||>},
  With[
    {record = finiteFieldNormalizeTraceTargetCore[job, workerData]},
    If[
      AssociationQ[record] && ! FailureQ[record],
      Append[record, "DescendStatistics" -> $finiteFieldDescendCounters],
      record
    ]
  ]
];

finiteFieldNormalizeTraceTargetCore[
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
    workerData["RationalLaurentFactor"],
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
      (* Inject the value: HoldComplete on the local symbol would leak
         the unevaluated variable name into the report. *)
      With[{failedMasterValue = failedMaster},
        <|
          "Target" -> HoldComplete[target],
          "Master" -> HoldComplete[failedMasterValue]
        |>
      ]
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
        "Detail" -> "the scalar remainder does not rationalize"
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
      distributionFactor, laurentFactor, rationalLaurentFactor,
      masters, masterIndices,
      signatures = {}, signatureBuckets = <||>, signatureID,
      symbolRules = <||>, aliasPrefix, registerSymbols, aliasRules,
      outputFiles = <||>, outputMetadata = <||>, firstTerm = <||>,
      contributionCounts = <||>, streams = <||>, streamOrder = {},
      streamLimit = 128, outputKey, outputFile, getStream, closeStreams,
      writeContribution, emitNormalizedTarget, targetTerms, ruleTerms,
      expected, keys, reductionString, masterIndex,
      processed = 0, selectedTargets, targetLimit, shard, remainder,
      remainderModule, outputOrder, traceVariables, signatureRegistry,
      descendStatistics = <||>, scalePowers, monomialExcluded,
      registerContribution,
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
    rationalLaurentFactor = finiteFieldRationalize[
      laurentFactor /. context["DimensionlessRules"],
      context
    ];
    If[rationalLaurentFactor === $Failed,
      finiteFieldFail[
        "physical normalization",
        "the declared distribution and Laurent factor do not rationalize"
      ]
    ];

    masters = metadata["Masters"];
    masterIndices = AssociationThread[masters, Range[Length[masters]]];
    monomialExcluded =
      #["Variable"] & /@ finiteFieldMonomialVariables[context];
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
      (* Zero contributions create nothing.  A stale 16-byte
         zero-content output file was found in the ghost set; an output
         that never receives a nonzero term must not exist at all. *)
      If[TrueQ[reductionCoefficient === 0] || targetString === "0",
        Return[Null]
      ];
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

    (* Every contribution registers through the canonicalized class:
       the rational-in-trace-variables part of the combined signature
       folds into the coefficient, so buckets differing by such a
       factor merge at registration. *)
    registerContribution[
        index_Integer,
        combined_HoldComplete,
        targetString_String,
        coefficient_
      ] := Module[{split},
      split = finiteFieldCanonicalizeSignature[combined, monomialExcluded];
      writeContribution[
        index,
        signatureID @ First[split],
        targetString,
        If[TrueQ[Last[split] === 1],
          coefficient,
          Last[split] coefficient
        ]
      ]
    ];

    emitNormalizedTarget[record_Association] := Module[
      {targetModule, preparedTerms, preparedRemainder},
      targetModule = record["TargetModule"];
      preparedTerms = record["PreparedTerms"];
      preparedRemainder = record["PreparedRemainder"];
      KeyValueMap[
        Function[{signature, rationalTarget},
          Module[{targetString},
            registerSymbols[rationalTarget];
            aliasRules = Dispatch[Normal[symbolRules]];
            targetString = finiteFieldToString[
              rationalTarget,
              aliasRules
            ];
            KeyValueMap[
              Function[{master, coefficientModule},
                masterIndex = Lookup[
                  masterIndices,
                  master,
                  Missing["UnknownMaster"]
                ];
                If[MissingQ[masterIndex],
                  finiteFieldFail["Kira image", HoldForm[master]]
                ];
                KeyValueMap[
                  Function[{coefficientSignature, reductionCoefficient},
                    registerContribution[
                      masterIndex,
                      finiteFieldCombineSignatures[
                        signature,
                        coefficientSignature
                      ],
                      targetString,
                      reductionCoefficient
                    ]
                  ],
                  coefficientModule
                ]
              ],
              preparedTerms
            ];
            KeyValueMap[
              Function[{remainderSignature, rationalRemainder},
                registerContribution[
                  0,
                  finiteFieldCombineSignatures[
                    signature,
                    remainderSignature
                  ],
                  targetString,
                  rationalRemainder
                ]
              ],
              preparedRemainder
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
      "RationalLaurentFactor" -> rationalLaurentFactor,
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
          (* Lookup on a list of Associations only threads in its
             two-argument form; the three-argument form reads the list
             as a rule list and quietly returns the default. *)
          descendStatistics = Merge[
            Join[
              {descendStatistics},
              Map[Lookup[#, "DescendStatistics", <||>] &, normalizedBatch]
            ],
            Total
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
          rationalLaurentFactor,
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
    (* An output key exists only once a nonzero contribution reached it;
       anything else is dropped from the trace instead of being written
       as a zero-content expression file. *)
    Scan[
      Function[key,
        If[TrueQ[firstTerm[key]],
          If[FileExistsQ[outputFiles[key]],
            DeleteFile[outputFiles[key]]
          ];
          KeyDropFrom[outputFiles, key];
          KeyDropFrom[outputMetadata, key];
          KeyDropFrom[contributionCounts, key]
        ]
      ],
      Keys[outputFiles]
    ];
    outputOrder = SortBy[
      Keys[outputFiles],
      {
        outputMetadata[#]["MasterIndex"],
        outputMetadata[#]["SignatureIndex"]
      } &
    ];
    Scan[
      Function[key,
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
    (* Scale monomiality is an exact property of the emitted data here:
       the scale rides in the signature, so its per-output power is read
       off the signature rather than fitted. *)
    scalePowers = If[
      MatchQ[context["Scale"], _Symbol],
      Map[
        Exponent[
          ReleaseHold[signatures[[outputMetadata[#]["SignatureIndex"]]]],
          context["Scale"]
        ] &,
        outputOrder
      ],
      ConstantArray[0, Length[outputOrder]]
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
      "ScalePowers" -> scalePowers,
      "DescendStatistics" -> descendStatistics,
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
  result = Quiet @ Check[RunProcess[command], $Failed];
  (* A fork failure from a large kernel (observed on WSL2 with a
     multi-GB session) returns no process Association at all. Say so,
     instead of exporting an unevaluated Lookup. *)
  If[! AssociationQ[result],
    Export[
      log,
      "RunProcess failed to launch the process (no result). " <>
        "Kernel MemoryInUse (MB): " <>
        ToString[Round[MemoryInUse[]/2.^20]] <>
        ". Re-running in a fresh kernel resumes from the trace " <>
        "checkpoint with a small footprint.",
      "Text"
    ];
    Return[$Failed]
  ];
  Export[
    log,
    Lookup[result, "StandardOutput", ""] <>
      Lookup[result, "StandardError", ""],
    "Text"
  ];
  If[DirectoryQ[temporary], DeleteDirectory[temporary, DeleteContents -> True]];
  If[Lookup[result, "ExitCode", 1] === 0, result, $Failed]
];

$finiteFieldTraceManifestName = "TraceManifest.wxf";

(* Version 2 is the physical-variable trace: a version-1 checkpoint
   holds root-variable expressions and must never be restored into the
   current emitter. *)
$finiteFieldTraceCheckpointVersion = 2;

finiteFieldTraceManifestFile[directory_String] :=
  FileNameJoin[{directory, $finiteFieldTraceManifestName}];

finiteFieldWriteTraceManifest[
    directory_String, traceData_Association,
    inputFingerprint_String, kiraHash_String
  ] := coefficientWriteRecord[
  finiteFieldTraceManifestFile[directory],
  <|
    "Format" -> "FeynFacet-TraceCheckpoint",
    "FormatVersion" -> $finiteFieldTraceCheckpointVersion,
    "InputFileFingerprint" -> inputFingerprint,
    "KiraFileHash" -> kiraHash,
    "TraceData" -> traceData
  |>
];

(* A valid checkpoint lets a fresh (small) kernel skip the
   normalization stage entirely: the expression files and the exact
   traceData are restored from disk, so the ratracer/FireFly forks
   happen from a low-RSS kernel. *)
finiteFieldRestoreTraceCheckpoint[
    directory_String, inputFingerprint_String, kiraHash_String
  ] := Module[{file, record, traceData, reason},
  file = finiteFieldTraceManifestFile[directory];
  If[! FileExistsQ[file], Return[$Failed]];
  record = Quiet @ Check[coefficientReadRecord[file], $Failed];
  reason = Which[
    ! AssociationQ[record],
      "the manifest record could not be read",
    record["Format"] =!= "FeynFacet-TraceCheckpoint",
      "unexpected manifest format",
    record["FormatVersion"] =!= $finiteFieldTraceCheckpointVersion,
      "the checkpoint predates the physical-variable trace (stored " <>
        ToString[record["FormatVersion"]] <> " vs current " <>
        ToString[$finiteFieldTraceCheckpointVersion] <> ")",
    record["InputFileFingerprint"] =!= inputFingerprint,
      "the pair-source fingerprint changed (stored " <>
        ToString[record["InputFileFingerprint"]] <> " vs current " <>
        inputFingerprint <> ")",
    record["KiraFileHash"] =!= kiraHash,
      "the Kira artifact hash changed",
    ! AssociationQ[record["TraceData"]],
      "the stored trace data is not an Association",
    ! AllTrue[
        record["TraceData"]["OutputFiles"],
        (* OutputFiles are absolute paths; FileNameJoin would
           concatenate, not reset, on an absolute second component. *)
        FileExistsQ[
          If[StringStartsQ[#, "/"], #, FileNameJoin[{directory, #}]]
        ] &
      ],
      "an expression file named by the checkpoint is missing",
    True,
      None
  ];
  If[reason =!= None,
    Print["Trace checkpoint present but not restorable: ", reason];
    Return[$Failed]
  ];
  record["TraceData"]
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
  (* A completed trace whose output list matches the checkpoint can be
     reused: rebuilding is deterministic given the same expressions. *)
  If[
    FileExistsQ[traceFile] && FileExistsQ[inputsFile] &&
      FileExistsQ[outputsFile] &&
      Length[
        Select[StringSplit[Import[outputsFile, "Text"], "\n"], # =!= "" &]
      ] === Length[traceData["OutputFiles"]],
    Print["Reusing the existing shared trace (",
      Round[FileByteCount[traceFile]/2.^20, 0.1], " MB)"];
    Return[<|
      "TraceFile" -> traceFile,
      "InputsFile" -> inputsFile,
      "OutputsFile" -> outputsFile,
      "BuildSeconds" -> 0,
      "TraceBytes" -> FileByteCount[traceFile]
    |>]
  ];
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
  (* RunProcess cannot launch a process with thousands of arguments
     (measured: 100 fine, 4400 returns no result), and one NNLO trace
     names 2203 expression files. Route the command through a script;
     the OS itself handles the argv fine (proven from a shell). *)
  Module[{script},
    script = FileNameJoin[{directory, "BuildTrace.sh"}];
    Export[
      script,
      StringRiffle[
        {
          "#!/bin/bash",
          "set -u",
          StringRiffle[
            "'" <> StringReplace[#, "'" -> "'\\''"] <> "'" & /@
              arguments,
            " "
          ]
        },
        "\n"
      ] <> "\n",
      "String"
    ];
    arguments = {"/bin/bash", script}
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
    reconstructionData, certifiedColumn, rootSubstitutions
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
  (* The trace is emitted in physical variables, so a reconstructed
     coefficient carrying a root variable is a regression of the
     descend, not a parity accident.  The check stays where it is
     cheap: on the small reconstructed output, never on trace inputs. *)
  certifiedColumn[entries_List] := finiteFieldCertifyRootFree[
    Total[
      Function[entry,
        ReleaseHold[
          traceData["Signatures"][entry["SignatureIndex"]]
        ] entry["RationalExpression"]
      ] /@ entries
    ],
    context
  ];
  coefficients = AssociationMap[
    Function[index, certifiedColumn[Lookup[grouped, index, {}]]],
    Range[Length[traceData["Masters"]]]
  ];
  remainder = certifiedColumn[Lookup[grouped, 0, {}]];
  If[MemberQ[Values[coefficients], $Failed] || remainder === $Failed,
    Return[$Failed]
  ];
  coefficients = (# /. directRules) & /@ coefficients;
  remainder = remainder /. directRules;
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
  rootSubstitutions = Lookup[context, "RootSubstitutions", <||>];
  remainingFractionObjects = Select[
    Join[
      context["FractionVariables"],
      context["FractionRootVariables"],
      If[
        AssociationQ[rootSubstitutions],
        #["Root"] & /@ Values[rootSubstitutions],
        {}
      ]
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
        "BranchGrammar" -> context["BranchGrammar"],
        (* Provenance of the root treatment.  The root variables are no
           longer a representation of the result - they are the
           transient lift of the entrywise descend, and what the result
           records is which of them were eliminated, with the exact
           relation used, plus the descend telemetry. *)
        "RootDescend" -> <|
          "EliminatedRoots" -> If[
            AssociationQ[rootSubstitutions],
            Association @ KeyValueMap[
              Function[{quantity, substitutionData},
                quantity ->
                  substitutionData["Constant"] substitutionData["Root"]^2
              ],
              rootSubstitutions
            ],
            <||>
          ],
          "TraceVariables" -> traceData["Variables"],
          "ScalePowers" -> Lookup[traceData, "ScalePowers", {}],
          "Statistics" -> Lookup[traceData, "DescendStatistics", <||>]
        |>
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
    traceData = finiteFieldRestoreTraceCheckpoint[
      traceDirectory,
      coefficientInputFileFingerprint[data["Sources"]],
      coefficientFileHash[kiraFile]
    ];
    If[AssociationQ[traceData],
      coefficientProgressStage["Restored the trace checkpoint"];
      Print["Reusing the normalized trace checkpoint (",
        Length[traceData["OutputFiles"]], " outputs)"],
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
      If[
        finiteFieldWriteTraceManifest[
          traceDirectory,
          traceData,
          coefficientInputFileFingerprint[data["Sources"]],
          coefficientFileHash[kiraFile]
        ] === $Failed,
        finiteFieldFail["trace checkpoint", "could not write the manifest"]
      ]
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
        {
          "Trace variables",
          ToString[traceData["Variables"], InputForm]
        },
        {
          "Scale powers",
          ToString[
            MinMax[Append[Lookup[traceData, "ScalePowers", {}], 0]],
            InputForm
          ]
        },
        {
          "Root descend",
          ToString[
            Normal @ Lookup[traceData, "DescendStatistics", <||>],
            InputForm
          ]
        },
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
