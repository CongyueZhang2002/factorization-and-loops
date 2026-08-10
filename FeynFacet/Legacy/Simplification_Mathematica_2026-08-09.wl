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

$coefficientBranchGrammars = {"PositiveMonomialRoots"};

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
