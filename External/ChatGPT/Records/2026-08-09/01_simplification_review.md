# Simplification Review

## Question

Please review the attached FACET simplification implementation and its exact test records. This is a file-level review: inspect the sources in the archive rather than relying on this prompt as a substitute.

Physics requirement: FACET must return exact analytic hard coefficients, including Epsilon and branch information. The process card, not reusable package code, must declare the physical input needed to simplify hadronic coefficients.

The intended card contract is:
1. positive momentum fractions and the twist-2 distribution product, each either explicit or exactly derivable;
2. an explicit Laurent valuation in those fractions, or exact derivation after additive cancellations;
3. the physical invariant chamber;
4. a positive dimensionful scale and an invertible set of dimensionless invariant coordinates;
5. variables forbidden in the hard coefficient;
6. the allowed branch grammar.

The intended unified API is SimplifyHardCoefficients. "Assembled" receives one exact expression per master. "ContributionWise" receives the additive contributions to each master coefficient and delays their sum until fraction-root cancellations have been certified. These are two input shapes within one NLO/NNLO normalization, not two order-specific prescriptions.

Please check, concretely:
- whether any pp -> h X assumptions remain hidden in FeynFacet/Private/Simplification.wl;
- whether the automatic derivation of the distribution product and Laurent valuation is mathematically sound, especially when square roots cancel only after summing contributions;
- whether the physical chamber, scale homogeneity, inverse coordinate map, forbidden-variable check, and branch grammar are enforced strongly enough;
- whether Assembled and ContributionWise return the same mathematical normalization when both apply;
- whether there are Mathematica semantic errors, branch errors, false certificates, or important exact-expression cases that currently fail;
- which helpers or layers are unnecessary and can be removed without weakening the checks;
- whether the three cards contain all process-specific information that the reusable code needs.

The archive includes the package files, active cards, synthetic and stored-data tests, the measured stored-data log, the project goal, and the current LaTeX report source. Give prioritized findings with exact function names and proposed corrections. Do not replace the exact analytic route with numerical evaluation.

## Follow-up question

The preceding file-level review request was stopped because its source archive was not recorded in the outgoing request. Review the archive attached to this turn against the immediately preceding request. Inspect the files themselves and return prioritized findings with exact function names and concrete corrections.

## Follow-up question

Review the exact FACET sources embedded below. This is not a summary: each marked block is the verbatim current file content. Apply the review criteria from the two immediately preceding requests. Return prioritized findings with exact function names and concrete corrections. Focus on hidden process assumptions, exact Laurent/distribution extraction, branch correctness, NLO/NNLO normalization, and Wolfram Language semantics.
===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\FeynFacet\Private\Simplification.wl =====
(* Card-driven exact simplification of physical master coefficients. *)

ClearAll[
  exactCoefficientNormalize,
  momentumFractionSymbols,
  singleMonomialData,
  positiveRootVariables,
  certifiedHalfIntegerPowerRule,
  canonicalizePhysicalBranches,
  minimumPolynomialExponents,
  fractionLaurentMonomial,
  normalizeHardFractionDependence,
  additiveTerms,
  structuralCommonAdditiveFactor,
  normalizeCoefficientKinematics,
  coefficientKinematicsFromCard,
  coefficientAutomaticForbiddenVariables,
  coefficientDeclaredFractions,
  coefficientLaurentValuation,
  coefficientExpectedFactorQ,
  coefficientDistributionObjectQ,
  coefficientCommonDistributionFactor,
  coefficientCanonicalRational,
  coefficientZeroStatus,
  coefficientFractionMonomialData,
  coefficientCertifiedPositiveQ,
  coefficientForbiddenFractionObjectQ,
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
  simplifyHardCoefficientContributionGroups,
  coefficientHomogeneousDegree,
  coefficientDimensionlessNormalize,
  normalizeHardCoefficientExpressions,
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

positiveRootVariables[powers_List, assumptions_] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    First /@ powers,
    symbol_Symbol /; Context[symbol] =!= "System`",
    Infinity
  ];
  Select[
    symbols,
    TimeConstrained[
      TrueQ @ FullSimplify[# > 0, Assumptions -> assumptions],
      5,
      False
    ] &
  ]
];

certifiedHalfIntegerPowerRule[
    power : Power[base_, exponent_Rational],
    positiveVariables_List,
    assumptions_
  ] := Module[{data, coefficient, powers, replacement},
  If[Denominator[exponent] =!= 2, Return[Nothing]];
  data = singleMonomialData[base, positiveVariables];
  If[data === $Failed, Return[Nothing]];
  {coefficient, powers} = data;
  If[
    ! TrueQ @ FullSimplify[
      base > 0 && coefficient > 0,
      Assumptions -> assumptions
    ],
    Return[Nothing]
  ];
  replacement = FullSimplify[
      coefficient^exponent,
      Assumptions -> assumptions
    ] Times @@ MapThread[
      Power,
      {positiveVariables, exponent powers}
    ];
  If[
    SameQ[power, replacement] ||
      ! TrueQ @ FullSimplify[
        power == replacement,
        Assumptions -> assumptions
      ],
    Nothing,
    power -> replacement
  ]
];

canonicalizePhysicalBranches[expressions_List, assumptions_] := Module[
  {powers, positiveVariables, rules, canonical},
  powers = DeleteDuplicates @ Cases[
    expressions,
    power : Power[_, exponent_Rational] /;
        Denominator[exponent] === 2 :> power,
    Infinity
  ];
  positiveVariables = positiveRootVariables[powers, assumptions];
  rules = DeleteCases[
    certifiedHalfIntegerPowerRule[
      #,
      positiveVariables,
      assumptions
    ] & /@ powers,
    Nothing
  ];
  canonical = expressions /. Dispatch[rules];
  If[! exactDataQ[canonical], Return[$Failed]];
  <|
    "Expressions" -> canonical,
    "Rules" -> rules,
    "PositiveVariables" -> positiveVariables
  |>
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

normalizeHardFractionDependence[
    expressions_List,
    setup_Association,
    assumptions_
  ] := Module[
  {
    fractionVariables, branchData, canonical, nonzero,
    fractionMonomials, fractionMonomial, scaled, normalized,
    normalizedExpressions, remainingFractions
  },
  fractionVariables = momentumFractionSymbols[setup];
  If[expressions === {} || fractionVariables === {},
    Return[<|
      "PreFactor" -> 1,
      "Expressions" -> expressions,
      "FractionVariables" -> fractionVariables,
      "FractionMonomial" -> 1,
      "BranchRules" -> {},
      "PositiveVariables" -> {}
    |>]
  ];
  branchData = canonicalizePhysicalBranches[expressions, assumptions];
  If[branchData === $Failed, Return[$Failed]];
  canonical = branchData["Expressions"];
  nonzero = DeleteCases[canonical, 0];
  If[nonzero === {},
    Return[<|
      "PreFactor" -> 1,
      "Expressions" -> canonical,
      "FractionVariables" -> fractionVariables,
      "FractionMonomial" -> 1,
      "BranchRules" -> branchData["Rules"],
      "PositiveVariables" -> branchData["PositiveVariables"]
    |>]
  ];
  fractionMonomials = fractionLaurentMonomial[
      #,
      fractionVariables
    ] & /@ nonzero;
  If[
    MemberQ[fractionMonomials, $Failed] ||
      Length[DeleteDuplicates[fractionMonomials, SameQ]] =!= 1,
    Return[$Failed]
  ];
  fractionMonomial = First[fractionMonomials];
  scaled = (#/fractionMonomial) & /@ canonical;
  normalized = parallelNormalizeCoefficients[
    scaled,
    assumptions,
    targetCoefficientSimplifyTimeLimit[],
    "Whole"
  ];
  If[normalized === $Failed, Return[$Failed]];
  normalizedExpressions = First[normalized];
  remainingFractions = Select[
    fractionVariables,
    ! FreeQ[normalizedExpressions, #] &
  ];
  If[remainingFractions =!= {}, Return[$Failed]];
  <|
    "PreFactor" -> fractionMonomial,
    "Expressions" -> normalizedExpressions,
    "FractionVariables" -> fractionVariables,
    "FractionMonomial" -> fractionMonomial,
    "BranchRules" -> branchData["Rules"],
    "PositiveVariables" -> branchData["PositiveVariables"],
    "Kernels" -> normalized[[2]],
    "AdditiveTerms" -> normalized[[3]]
  |>
];

additiveTerms[expression_] := If[
  Head[expression] === Plus,
  List @@ expression,
  {expression}
];

structuralCommonAdditiveFactor[expressions_List] := Module[
  {nonzero, shared},
  nonzero = DeleteCases[expressions, 0];
  If[nonzero === {}, Return[{1, expressions}]];
  shared = commonFactorMultiset[
    Flatten[topLevelFactors /@ additiveTerms[#]] & /@ nonzero
  ];
  {
    Times @@ shared,
    Map[
      If[TrueQ[# === 0], 0, #/(Times @@ shared)] &,
      expressions
    ]
  }
];

normalizeCoefficientKinematics[
    value_,
    massDimensions_Association
  ] := Module[
  {
    allowed, required, scale, coordinates, variables, definitions,
    positiveFractions, distributionFactor, laurentValuation,
    forbidden, grammar, physicalRegion, sourceInvariants,
    solutions, rules
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

  scale = Lookup[value, "Scale", None];
  coordinates = Lookup[value, "DimensionlessCoordinates", <||>];
  positiveFractions = Lookup[value, "PositiveFractions", Automatic];
  distributionFactor = Lookup[value, "DistributionFactor", Automatic];
  laurentValuation = Lookup[value, "LaurentValuation", Automatic];
  forbidden = Lookup[value, "ForbiddenVariables", Automatic];
  grammar = Lookup[value, "BranchGrammar", "PositiveMonomialRoots"];
  physicalRegion = Lookup[value, "PhysicalRegion", True];
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

  sourceInvariants = Select[
    Keys[massDimensions],
    # =!= scale && ! FreeQ[definitions, #] &
  ];
  If[sourceInvariants === {},
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "no dimensionful source invariant occurs in the coordinate definitions"
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

  <|
    "PositiveFractions" -> positiveFractions,
    "DistributionFactor" -> distributionFactor,
    "LaurentValuation" -> laurentValuation,
    "Scale" -> scale,
    "DimensionlessCoordinates" -> coordinates,
    "DimensionlessVariables" -> variables,
    "DimensionlessRules" -> rules,
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
          "HadronMomentum", "HadronLongDirection",
          "HadronDualDirection", "HadronTransSpin"
        },
        {}
      ],
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

coefficientLaurentValuation[monomial_, variables_List] := Module[{data},
  data = singleMonomialData[monomial, variables];
  If[
    data === $Failed || ! TrueQ[First[data] === 1],
    $Failed,
    AssociationThread[variables, Last[data]]
  ]
];

coefficientExpectedFactorQ[actual_, Automatic, _] := True;

coefficientExpectedFactorQ[actual_, expected_, assumptions_] := TrueQ[
  exactCoefficientNormalize[actual - expected, assumptions] === 0
];

BuildSimplificationContext[config_Association] := Catch[
  Module[
    {
      hadronic, kinematics, assumptions, inferredFractions, fractions, roots,
      forbidden, scale, scalePositive, dimensionlessAssumptions
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
    assumptions = inferFractionAssumptions[
        Lookup[config, "MomentumFraction", {}]
      ] && hadronic["Assumptions"] && kinematics["PhysicalRegion"];
    scale = kinematics["Scale"];
    If[scale =!= None,
      scalePositive = TimeConstrained[
        TrueQ @ FullSimplify[scale > 0, Assumptions -> assumptions],
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
    roots = Table[
      Symbol["FeynFacet`Private`fractionRoot" <> ToString[index]],
      {index, Length[fractions]}
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
      assumptions,
      FullSimplify[
        assumptions /. kinematics["DimensionlessRules"],
        Assumptions -> kinematics["PhysicalRegion"]
      ]
    ];
    <|
      "FractionVariables" -> fractions,
      "FractionRootVariables" -> roots,
      "ExpectedDistributionFactor" -> kinematics["DistributionFactor"],
      "ExpectedLaurentValuation" -> kinematics["LaurentValuation"],
      "HadronicVariables" -> hadronic,
      "PhysicalAssumptions" -> assumptions,
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
    MemberQ[{$Failed, $TimedOut}, quotients] ||
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

coefficientFractionMonomialData[base_, fractions_List] := Module[
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
        Return[$Failed]
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
  ] := Module[{fractionPattern, forbiddenHeads, badObjects, badPowers},
  If[fractions === {}, Return[False]];
  fractionPattern = Alternatives @@ fractions;
  forbiddenHeads =
    _Log | _Gamma | _Beta | _Pochhammer | _Hypergeometric2F1 |
    _PolyLog | _Piecewise | _ConditionalExpression | _Abs | _Sign |
    _UnitStep | _DiracDelta;
  badObjects = Cases[
    HoldComplete[expression],
    object : forbiddenHeads /;
      ! FreeQ[Unevaluated[object], fractionPattern] :>
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
      coefficientForbiddenFractionObjectQ[expression, fractions],
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

simplifyHardCoefficientContributionGroups[
    groups_List,
    setup_Association,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    lengths, flat, distribution, strippedGroups, fractions, columns,
    certified, nonzero, valuations, valuation, monomial, hard,
    remainingForbidden, branchRules, leafCount
  },
  lengths = Length /@ groups;
  flat = Flatten[groups, 1];
  distribution = coefficientCommonDistributionFactor[flat, timeLimit];
  If[distribution === $Failed, Return[$Failed]];
  If[
    ! coefficientExpectedFactorQ[
      distribution["Factor"],
      context["ExpectedDistributionFactor"],
      context["PhysicalAssumptions"]
    ],
    Return[$Failed]
  ];
  strippedGroups = coefficientPartitionByLengths[
    distribution["Expressions"],
    lengths
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
  remainingForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[hard, #] &
  ];
  If[remainingForbidden =!= {}, Return[$Failed]];
  <|
    "PreFactor" -> distribution["Factor"] monomial,
    "DistributionFactor" -> distribution["Factor"],
    "FractionVariables" -> fractions,
    "FractionMonomial" -> monomial,
    "LaurentValuation" -> valuation,
    "BranchRules" -> branchRules,
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
    normalized, reconstructed, difference
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
  normalized = exactCoefficientNormalize[
    (transformed/scale^degree) /. scale -> 1,
    context["DimensionlessAssumptions"]
  ];
  If[normalized === $Failed || ! FreeQ[normalized, scale], Return[$Failed]];
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

normalizeHardCoefficientExpressions[
    expressions_List,
    setup_Association,
    assumptions_
  ] := Module[
  {
    distribution, stripped, fractionData, normalized,
    context, remainingForbidden, valuation
  },
  distribution = coefficientCommonDistributionFactor[expressions];
  If[distribution === $Failed, Return[$Failed]];
  context = BuildSimplificationContext[setup];
  If[context === $Failed, Return[$Failed]];
  If[
    ! coefficientExpectedFactorQ[
      distribution["Factor"],
      context["ExpectedDistributionFactor"],
      assumptions
    ],
    Return[$Failed]
  ];
  stripped = distribution["Expressions"];
  fractionData = normalizeHardFractionDependence[
    stripped,
    setup,
    assumptions
  ];
  If[fractionData === $Failed, Return[$Failed]];
  valuation = coefficientLaurentValuation[
    fractionData["FractionMonomial"],
    context["FractionVariables"]
  ];
  If[valuation === $Failed, Return[$Failed]];
  If[
    context["ExpectedLaurentValuation"] =!= Automatic &&
      ! SameQ[valuation, context["ExpectedLaurentValuation"]],
    Return[$Failed]
  ];
  normalized = fractionData["Expressions"];
  remainingForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[normalized, #] &
  ];
  If[remainingForbidden =!= {}, Return[$Failed]];
  Join[
    KeyDrop[fractionData, "Expressions"],
    <|
      "PreFactor" ->
        distribution["Factor"] fractionData["PreFactor"],
      "DistributionFactor" -> distribution["Factor"],
      "LaurentValuation" -> valuation,
      "Expressions" -> normalized,
      "ForbiddenVariables" -> context["ForbiddenVariables"],
      "RemainingForbiddenVariables" -> {}
    |>
  ]
];

SimplifyHardCoefficients[
    input_List,
    setup_Association,
    OptionsPattern[]
  ] := Module[
  {
    context, method, timeLimit, physical, lengths, normalization,
    dimensionless
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
  If[method === "Assembled",
    physical = applyHadronicVariables[input, context["HadronicVariables"]],
    lengths = Length /@ input;
    physical = applyHadronicVariables[
      Flatten[input, 1],
      context["HadronicVariables"]
    ];
    If[physical =!= $Failed,
      physical = coefficientPartitionByLengths[physical, lengths]
    ]
  ];
  If[physical === $Failed || ! exactDataQ[physical], Return[$Failed]];
  normalization = If[
    method === "Assembled",
    normalizeHardCoefficientExpressions[
      physical,
      setup,
      context["PhysicalAssumptions"]
    ],
    simplifyHardCoefficientContributionGroups[
      physical,
      setup,
      context,
      timeLimit
    ]
  ];
  If[normalization === $Failed, Return[$Failed]];
  dimensionless = coefficientDimensionlessNormalize[
      #,
      context,
      timeLimit
    ] & /@ normalization["Expressions"];
  If[MemberQ[dimensionless, $Failed], Return[$Failed]];
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

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\FeynFacet\Private\Simplification.wl =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\FeynFacet\FeynFacet.m =====
(* ::Package:: *)

If[Names["FeynCalc`$FeynCalcVersion"] === {}, Needs["FeynCalc`"]];

BeginPackage["FeynFacet`"];

ClearAll["FeynFacet`*"];
ClearAll["FeynFacet`Private`*"];

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
  "SimplifyAssum[expr, assumptions] applies Simplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

FullSimplifyAssum::usage =
  "FullSimplifyAssum[expr, assumptions] applies FullSimplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

BuildSimplificationContext::usage =
  "BuildSimplificationContext[setup] validates the required CoefficientKinematics block and derives exact coefficient-simplification data from the process card: positive fractions, expected or derived distribution and Laurent factors, physical invariant chamber, positive scale, dimensionless coordinates, forbidden variables, and branch grammar.";

SimplifyHardCoefficients::usage =
  "SimplifyHardCoefficients[data,setup] applies one card-defined exact normalization to NLO or NNLO coefficients: it derives or verifies the common twist-2 factor and fraction Laurent valuation, removes forbidden hadronic variables, and returns homogeneous dimensionless hard coefficients. data may be {c1,...} with Method->\"Assembled\" or {{c11,c12,...},...} with Method->\"ContributionWise\"; Automatic infers the input form.";

ToFeynFacetForm::usage =
  "ToFeynFacetForm[expr] converts FeynCalc internal expressions to compact external FeynCalc syntax such as SP, SPD, SPE, FAD and SFAD. It preserves the dimensional meaning of scalar products and returns $Failed if an internal scalar-product object remains.";

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

IdentifySafePropagator::usage =
  "IdentifySafePropagator[setup,propagator] returns True when a massless phase-space propagator Q^2 has one fixed sign, allowing zeros on the phase-space boundary, and returns $Failed otherwise.";

TopologyEquivalence::usage =
  "TopologyEquivalence[topologies,setup] finds conservative multiloop equivalence classes. Accepted mappings have exact rational unit Jacobian and preserve every propagator, cut slot, cut energy direction and the phase-space/forward/conjugate loop partition inferred from setup.";

GenerateDiagram::usage =
  "GenerateDiagram[setup] generates and returns the complete FeynArts diagram lists for Setup[\"ForwardAmplitudes\"] and Setup[\"ConjugateAmplitudes\"].";

DimensionalShift::usage =
  "DimensionalShift[integrand,families,{k1,...}] applies the topology-dependent dimensional shift to every integral family, collects the GLI coefficients without expensive simplification, prints a result summary, and returns the collected expression. With no families and no loop momenta, it returns integrand unchanged. Coefficients should be simplified after IBP and master aggregation. DimensionalShift[integrand,propagators,{k1,...},topology] applies the shift to one family.";

CommonFactorSafe::usage =
  "CommonFactorSafe[expr,{k1,...}] extracts a common prefactor while retaining scalar products that depend on loop momenta, propagators, cuts, measures and GLI master integrals in the remainder.";

CollinearFactorize::usage =
  "CollinearFactorize[config] returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Propagators,LoopMomentum}. LoopMomentum contains the remaining phase-space momenta followed by the forward and conjugate virtual-loop momenta.";

CollinearFactorizePreIBP::usage =
  "CollinearFactorizePreIBP[config] runs diagram generation, collinear factorization, partial fractioning, topology construction and dimensional shifting from one configuration Association. It returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Topologies}, where Integrand is the GLI expression and topology records contain algebraic and cut metadata. Causal prescriptions are inferred from config when needed.";

GenerateCollinearFactorizePreIBPResult::usage =
  "GenerateCollinearFactorizePreIBPResult[setup,fractionMeasure,preFactor,phaseSpace,integrand,topologies,resultDirectory] validates and packages one selected diagram-pair result. resultDirectory is optional for saved-file compatibility but required for an in-memory IBP input.";

KiraReduction::usage =
  "KiraReduction[inputs,file] identifies equivalent cut topologies, runs one exact-target Kira reduction, closes its exported rules against the solved database, writes and verifies the compact artifact, then removes the temporary Kira workspace.";

KiraImportReduction::usage =
  "KiraImportReduction[inputs,file] validates and imports the matching solved Kira workspace, closes its exact reduction rules, writes and verifies the compact artifact, then removes the workspace. It never reruns Kira.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraReduction] reconstructs and simplifies the master coefficients. kiraReduction may be an in-memory Association for small calculations or a saved KiraResult.wl path for bounded-memory processing.";

AMFlowPrescription::usage =
  "AMFlowPrescription[setup] derives AMFlow loop prescriptions from Setup: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops. AMFlowPrescription[setup,topology] additionally derives the cut mask and rejects active denominators that mix forward and conjugate virtual loops; it does not persist denominator-sign metadata.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";

SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[BuildSimplificationContext] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyHardCoefficients] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]}
};
SyntaxInformation[ToFeynFacetForm] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _, _.}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[KiraImportReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[IdentifySafePropagator] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[GenerateDiagram] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[DimensionalShift] = {"ArgumentsPattern" -> {_, _, _, _.}};

Options[PartialFraction] = {
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False
};


Begin["`Private`"];

$feynFacetDirectory = DirectoryName[ExpandFileName[$InputFileName]];
$feynFacetRoot = DirectoryName[$feynFacetDirectory];
$feynFacetPrivateDirectory = FileNameJoin[{$feynFacetDirectory, "Private"}];
$feynFacetPrivateFiles = FileNameJoin[{$feynFacetPrivateDirectory, #}] & /@ {
    "Core.wl", "Process.wl", "Topologies.wl",
    "DimensionalShift.wl", "Collinear.wl", "Reduction.wl",
    "Simplification.wl",
    "CoefficientStore.wl", "CoefficientModules.wl"
};
$feynFacetSourceFiles = Join[
  {ExpandFileName[$InputFileName], FileNameJoin[{$feynFacetDirectory, "Distributions.wl"}]},
  $feynFacetPrivateFiles
];
If[! AllTrue[$feynFacetSourceFiles, FileExistsQ],
  Print["FeynFacet: missing source files: ",
    Select[$feynFacetSourceFiles, ! FileExistsQ[#] &]];
  Abort[]
];
$feynFacetSourceHash = Hash[
  FileHash[#, "SHA256"] & /@ $feynFacetSourceFiles,
  "SHA256",
  "HexString"
];
$feynFacetEpsilon = Symbol["Global`Epsilon"];
$dimensionRule = System`D -> 4 - 2 $feynFacetEpsilon;

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

Scan[If[Get[#] === $Failed, Abort[]] &, $feynFacetPrivateFiles];

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

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\FeynFacet\FeynFacet.m =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NLO\Cards\UU.wl =====
(* Unpolarized pp -> h X real-emission input card. *)

With[
  {
    forwardIndices = {1, 2, 3, 9, 10},
    backwardIndices = {1, 2, 3, 9, 10}
  },
<|
  "ForwardAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> forwardIndices
  |>,
  "ConjugateAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> backwardIndices
  |>,
  "Partons" -> ({
    F[3, {1}], F[3, {1}]
  } -> {
    F[3, {1}], F[3, {1}], V[5]
  }),
  "Model" -> "SMQCD",
  "InsertionLevel" -> {Classes},
  "ExcludeTopologies" -> {Tadpoles, WFCorrections},
  "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
  "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke}),
  "PhaseSpaceMomentum" -> {kd, ke},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> ({xa, xb} -> {zh, NA, NA}),
  "HadronMomentum" -> ({Pa, Pb} -> {Ph, NA, NA}),
  "HadronLongDirection" -> ({n, nb} -> {nh, NA, NA}),
  "HadronDualDirection" -> ({nb, n} -> {nhb, NA, NA}),
  "HadronLongSpin" -> ({\[Lambda]a, 0} -> {\[Lambda]h, NA, NA}),
  "HadronTransSpin" -> ({STvec, 0} -> {SThvec, NA, NA}),
  "HadronicVariables" -> <|
    "Coordinates" -> <|
      Pa -> {0, Sqrt[s/(2 xa xb)], 0, 0},
      Pb -> {Sqrt[s/(2 xa xb)], 0, 0, 0},
      Ph -> {
        -zh t Sqrt[xb/(2 s xa)],
        -zh u Sqrt[xa/(2 s xb)],
        zh Sqrt[t u/s],
        0
      },
      nh -> {
        xb t/(xb t + xa u),
        xa u/(xb t + xa u),
        -Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      nhb -> {
        xa u/(xb t + xa u),
        xb t/(xb t + xa u),
        Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      STvec -> {0, 0, ST Cos[\[Phi]a], ST Sin[\[Phi]a]},
      SThvec -> {
        -STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        -STh (xb t - xa u) Cos[\[Phi]h]/(xb t + xa u),
        STh Sin[\[Phi]h]
      }
    |>,
    "Assumptions" -> (
      s > 0 && t < 0 && u < 0 && s + t + u > 0 &&
      CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 &&
      Element[{s, t, u, ST, STh, \[Phi]a, \[Phi]h}, Reals]
    )
  |>,
  "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>,
  "CoefficientKinematics" -> <|
    "PositiveFractions" -> Automatic,
    "DistributionFactor" -> f1[xa] f1[xb] D1[zh],
    "LaurentValuation" -> Automatic,
    "Scale" -> s,
    "DimensionlessCoordinates" -> <|x -> -t/s, y -> -u/s|>,
    "ForbiddenVariables" -> Automatic,
    "BranchGrammar" -> "PositiveMonomialRoots",
    "PhysicalRegion" -> (
      x > 0 && y > 0 && x + y < 1 && Element[{x, y}, Reals]
    )
  |>,
  "SetDistributionZero" -> {g1L, h1, G1L, H1},
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke}
|>
]

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NLO\Cards\UU.wl =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NLO\Cards\TT.wl =====
(* Transversely polarized pp -> h X real-emission input card. *)

With[
  {
    forwardIndices = {1, 2, 3, 9, 10},
    backwardIndices = {1, 2, 3, 9, 10}
  },
<|
  "ForwardAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> forwardIndices
  |>,
  "ConjugateAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> backwardIndices
  |>,
  "Partons" -> ({
    F[3, {1}], F[3, {1}]
  } -> {
    F[3, {1}], F[3, {1}], V[5]
  }),
  "Model" -> "SMQCD",
  "InsertionLevel" -> {Classes},
  "ExcludeTopologies" -> {Tadpoles, WFCorrections},
  "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
  "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke}),
  "PhaseSpaceMomentum" -> {kd, ke},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> ({xa, xb} -> {zh, NA, NA}),
  "HadronMomentum" -> ({Pa, Pb} -> {Ph, NA, NA}),
  "HadronLongDirection" -> ({n, nb} -> {nh, NA, NA}),
  "HadronDualDirection" -> ({nb, n} -> {nhb, NA, NA}),
  "HadronLongSpin" -> ({\[Lambda]a, 0} -> {\[Lambda]h, NA, NA}),
  "HadronTransSpin" -> ({STvec, 0} -> {SThvec, NA, NA}),
  "HadronicVariables" -> <|
    "Coordinates" -> <|
      Pa -> {0, Sqrt[s/(2 xa xb)], 0, 0},
      Pb -> {Sqrt[s/(2 xa xb)], 0, 0, 0},
      Ph -> {
        -zh t Sqrt[xb/(2 s xa)],
        -zh u Sqrt[xa/(2 s xb)],
        zh Sqrt[t u/s],
        0
      },
      nh -> {
        xb t/(xb t + xa u),
        xa u/(xb t + xa u),
        -Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      nhb -> {
        xa u/(xb t + xa u),
        xb t/(xb t + xa u),
        Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      STvec -> {0, 0, ST Cos[\[Phi]a], ST Sin[\[Phi]a]},
      SThvec -> {
        -STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        -STh (xb t - xa u) Cos[\[Phi]h]/(xb t + xa u),
        STh Sin[\[Phi]h]
      }
    |>,
    "Assumptions" -> (
      s > 0 && t < 0 && u < 0 && s + t + u > 0 &&
      CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 &&
      Element[{s, t, u, ST, STh, \[Phi]a, \[Phi]h}, Reals]
    )
  |>,
  "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>,
  "CoefficientKinematics" -> <|
    "PositiveFractions" -> Automatic,
    "DistributionFactor" -> h1[xa] f1[xb] H1[zh],
    "LaurentValuation" -> Automatic,
    "Scale" -> s,
    "DimensionlessCoordinates" -> <|x -> -t/s, y -> -u/s|>,
    "ForbiddenVariables" -> Automatic,
    "BranchGrammar" -> "PositiveMonomialRoots",
    "PhysicalRegion" -> (
      x > 0 && y > 0 && x + y < 1 && Element[{x, y}, Reals]
    )
  |>,
  "SetDistributionZero" -> {f1[xa], g1L, D1, G1L},
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke}
|>
]

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NLO\Cards\TT.wl =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NNLO_DoubleReal\Cards\UU.wl =====
(* Unpolarized pp -> h X NNLO double-real input card. *)

With[
  {diagramIndices = Range[36]},
<|
  "ForwardAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> diagramIndices
  |>,
  "ConjugateAmplitudes" -> <|
    "LoopOrder" -> 0,
    "LoopMomenta" -> {},
    "DiagramIndices" -> diagramIndices
  |>,
  "Partons" -> ({
    F[3, {1}], F[4, {1}]
  } -> {
    F[3, {1}], F[4, {1}], V[5], V[5]
  }),
  "Model" -> "SMQCD",
  "InsertionLevel" -> {Classes},
  "ExcludeTopologies" -> {Tadpoles, WFCorrections},
  "ExcludeParticles" -> {S[_], V[1], V[2], V[3]},
  "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke, kf}),
  "PhaseSpaceMomentum" -> {kd, ke, kf},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> ({xa, xb} -> {zh, NA, NA, NA}),
  "HadronMomentum" -> ({Pa, Pb} -> {Ph, NA, NA, NA}),
  "HadronLongDirection" -> ({n, nb} -> {nh, NA, NA, NA}),
  "HadronDualDirection" -> ({nb, n} -> {nhb, NA, NA, NA}),
  "HadronLongSpin" -> ({\[Lambda]a, 0} -> {\[Lambda]h, NA, NA, NA}),
  "HadronTransSpin" -> ({STvec, 0} -> {SThvec, NA, NA, NA}),
  "HadronicVariables" -> <|
    "Coordinates" -> <|
      Pa -> {0, Sqrt[s/(2 xa xb)], 0, 0},
      Pb -> {Sqrt[s/(2 xa xb)], 0, 0, 0},
      Ph -> {
        -zh t Sqrt[xb/(2 s xa)],
        -zh u Sqrt[xa/(2 s xb)],
        zh Sqrt[t u/s],
        0
      },
      nh -> {
        xb t/(xb t + xa u),
        xa u/(xb t + xa u),
        -Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      nhb -> {
        xa u/(xb t + xa u),
        xb t/(xb t + xa u),
        Sqrt[2 xa xb t u]/(xb t + xa u),
        0
      },
      STvec -> {0, 0, ST Cos[\[Phi]a], ST Sin[\[Phi]a]},
      SThvec -> {
        -STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        STh Sqrt[2 xa xb t u] Cos[\[Phi]h]/(xb t + xa u),
        -STh (xb t - xa u) Cos[\[Phi]h]/(xb t + xa u),
        STh Sin[\[Phi]h]
      }
    |>,
    "Assumptions" -> (
      s > 0 && t < 0 && u < 0 && s + t + u > 0 &&
      CA > 0 && CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 &&
      Element[{s, t, u, ST, STh, \[Phi]a, \[Phi]h}, Reals]
    )
  |>,
  "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>,
  "CoefficientKinematics" -> <|
    "PositiveFractions" -> Automatic,
    "DistributionFactor" -> f1[xa] f1[xb] D1[zh],
    "LaurentValuation" -> Automatic,
    "Scale" -> s,
    "DimensionlessCoordinates" -> <|x -> -t/s, y -> -u/s|>,
    "ForbiddenVariables" -> Automatic,
    "BranchGrammar" -> "PositiveMonomialRoots",
    "PhysicalRegion" -> (
      x > 0 && y > 0 && x + y < 1 && Element[{x, y}, Reals]
    )
  |>,
  "SetDistributionZero" -> {g1L, h1, G1L, H1},
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke, kf}
|>
]

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\ppHX_NNLO_DoubleReal\Cards\UU.wl =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\Codex\Tests\Results\ProcessIndependentSimplification.log =====
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Loading FeynCalc from /home/maxzhang/FACET/Addon/Mathematica_Addon/FeynCalc/
$PrePrint is set to FeynCalcForm. Use FI and FC to change the display format.
FeynCalc 10.2.1 (stable version). For help, use the DisplayForm[ButtonBox[online documentation,, ButtonData :> {URL[https://feyncalc.github.io/referenceDev], None}, BaseStyle -> Hyperlink, ButtonNote -> https://feyncalc.github.io/referenceDev]] visit the DisplayForm[ButtonBox[forum, ButtonData :> {URL[https://github.com/FeynCalc/feyncalc/discussions], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc/discussions/]] and have a look at the supplied DisplayForm[ButtonBox[examples., BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[FileNameJoin[{$FeynCalcDirectory, Examples}]], Evaluator -> Automatic, Method -> Preemptive]] The PDF-version of the manual can be downloaded DisplayForm[ButtonBox[here., ButtonData :> {URL[https://github.com/FeynCalc/feyncalc-manual/releases/download/dev-manual/FeynCalcManual.pdf], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc-manual/releases/download/dev-manual/FeynCalcManual.pdf]]
If you use FeynCalc in your research, please evaluate FeynCalcHowToCite[] to learn how to cite this software.
Please keep in mind that the proper academic attribution of our work is crucial to ensure the future development of this package!
FeynCalcLegacy 1.0.0
FeynCalcLegacy contains legacy functions and symbols that were removed in FeynCalc 10.2.1
FeynHelpers 2.0.0 (). For help, use the DisplayForm[ButtonBox[online documentation,, ButtonData :> {URL[https://feyncalc.github.io/referenceFeynHelpersDev], None}, BaseStyle -> Hyperlink, ButtonNote -> https://feyncalc.github.io/referenceFeynHelpersDev]] visit the DisplayForm[ButtonBox[forum, ButtonData :> {URL[https://github.com/FeynCalc/feyncalc/discussions], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc/discussions/]] and have a look at the supplied DisplayForm[ButtonBox[examples., BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[FileNameJoin[{$FeynHelpersDirectory, Examples}]], Evaluator -> Automatic, Method -> Preemptive]] The PDF-version of the manual can be downloaded DisplayForm[ButtonBox[here., ButtonData :> {URL[https://github.com/FeynCalc/feynhelpers-manual/releases/download/dev-manual/FeynHelpersManual.pdf], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feynhelpers-manual/releases/download/dev-manual/FeynHelpersManual.pdf]]
 If you use FeynHelpers in your research, please evaluate FeynHelpersHowToCite[] to learn how to cite this work.
Loading FeynArts from /home/maxzhang/FACET/Addon/Mathematica_Addon/FeynArts
FeynArts 3.12 (27 Mar 2025) patched for use with FeynCalc, for documentation see the DisplayForm[ButtonBox[manual, BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[First[FileNames[{*.pdf, *.PDF}, FileNameJoin[{$FeynArtsDirectory, manual}]]]], Evaluator -> Automatic, Method -> Preemptive]] or visit DisplayForm[ButtonBox[www.feynarts.de., ButtonData :> {URL[http://www.feynarts.de/], None}, BaseStyle -> Hyperlink, ButtonNote -> www.feynarts.de/]]
If you use FeynArts in your research, please cite
 • T. Hahn, Comput. Phys. Commun., 140, 418-431, 2001, arXiv:hep-ph/0012260
FeynFacet 0.1
UU context	OK
TT context	OK
NNLO context	OK
Card fraction inference	OK
Card coordinate inversion	OK
Card assumptions imply the positive scale	OK
Missing coefficient-kinematics block rejected	OK
Incomplete coefficient-kinematics block rejected	OK
Renamed-variable context	OK
Renamed fractions	OK
Renamed coordinate inversion	OK
Synthetic simplification	OK
Distribution factor derived	OK
Synthetic factors	InputForm[<|PreFactor -> (D1[rhoH]*f1[rhoA]*f1[rhoB])/(rhoA*rhoB*rhoH^2), FractionMonomial -> 1/(rhoA*rhoB*rhoH^2), DistributionFactor -> D1[rhoH]*f1[rhoA]*f1[rhoB]|>]
Laurent factor derived	OK
Fractions absent from hard coefficient	OK
Scale degree derived	OK
Dimensionless coefficient reconstructed	OK
Contribution-wise simplification	OK
Contribution-wise method recorded	OK
Contribution-wise distribution derived	OK
Contribution-wise Laurent valuation derived after cancellation	OK
Contribution-wise hard coefficients reconstructed	OK
Contribution-wise dimensionless coefficients reconstructed	OK
Assembled and contribution-wise normalizations agree	OK
Epsilon-dependent scale normalization	OK
Epsilon-dependent scale power	OK
Epsilon-dependent dimensionless coefficient	OK
PROCESS_INDEPENDENT_SIMPLIFICATION_OK

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\Codex\Tests\Results\ProcessIndependentSimplification.log =====

===== BEGIN FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\Codex\Tests\Results\ActualHardSimplification.log =====
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Failed to open configuaration file at path: /home/maxzhang/.config/Wolfram/WolframScript/WolframScript.conf
Loading FeynCalc from /home/maxzhang/FACET/Addon/Mathematica_Addon/FeynCalc/
$PrePrint is set to FeynCalcForm. Use FI and FC to change the display format.
FeynCalc 10.2.1 (stable version). For help, use the DisplayForm[ButtonBox[online documentation,, ButtonData :> {URL[https://feyncalc.github.io/referenceDev], None}, BaseStyle -> Hyperlink, ButtonNote -> https://feyncalc.github.io/referenceDev]] visit the DisplayForm[ButtonBox[forum, ButtonData :> {URL[https://github.com/FeynCalc/feyncalc/discussions], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc/discussions/]] and have a look at the supplied DisplayForm[ButtonBox[examples., BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[FileNameJoin[{$FeynCalcDirectory, Examples}]], Evaluator -> Automatic, Method -> Preemptive]] The PDF-version of the manual can be downloaded DisplayForm[ButtonBox[here., ButtonData :> {URL[https://github.com/FeynCalc/feyncalc-manual/releases/download/dev-manual/FeynCalcManual.pdf], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc-manual/releases/download/dev-manual/FeynCalcManual.pdf]]
If you use FeynCalc in your research, please evaluate FeynCalcHowToCite[] to learn how to cite this software.
Please keep in mind that the proper academic attribution of our work is crucial to ensure the future development of this package!
FeynCalcLegacy 1.0.0
FeynCalcLegacy contains legacy functions and symbols that were removed in FeynCalc 10.2.1
FeynHelpers 2.0.0 (). For help, use the DisplayForm[ButtonBox[online documentation,, ButtonData :> {URL[https://feyncalc.github.io/referenceFeynHelpersDev], None}, BaseStyle -> Hyperlink, ButtonNote -> https://feyncalc.github.io/referenceFeynHelpersDev]] visit the DisplayForm[ButtonBox[forum, ButtonData :> {URL[https://github.com/FeynCalc/feyncalc/discussions], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feyncalc/discussions/]] and have a look at the supplied DisplayForm[ButtonBox[examples., BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[FileNameJoin[{$FeynHelpersDirectory, Examples}]], Evaluator -> Automatic, Method -> Preemptive]] The PDF-version of the manual can be downloaded DisplayForm[ButtonBox[here., ButtonData :> {URL[https://github.com/FeynCalc/feynhelpers-manual/releases/download/dev-manual/FeynHelpersManual.pdf], None}, BaseStyle -> Hyperlink, ButtonNote -> https://github.com/FeynCalc/feynhelpers-manual/releases/download/dev-manual/FeynHelpersManual.pdf]]
 If you use FeynHelpers in your research, please evaluate FeynHelpersHowToCite[] to learn how to cite this work.
Loading FeynArts from /home/maxzhang/FACET/Addon/Mathematica_Addon/FeynArts
FeynArts 3.12 (27 Mar 2025) patched for use with FeynCalc, for documentation see the DisplayForm[ButtonBox[manual, BaseStyle -> Hyperlink, ButtonFunction :> SystemOpen[First[FileNames[{*.pdf, *.PDF}, FileNameJoin[{$FeynArtsDirectory, manual}]]]], Evaluator -> Automatic, Method -> Preemptive]] or visit DisplayForm[ButtonBox[www.feynarts.de., ButtonData :> {URL[http://www.feynarts.de/], None}, BaseStyle -> Hyperlink, ButtonNote -> www.feynarts.de/]]
If you use FeynArts in your research, please cite
 • T. Hahn, Comput. Phys. Commun., 140, 418-431, 2001, arXiv:hep-ph/0012260
FeynFacet 0.1
NLO UU exact simplification	OK
NLO UU distribution product	OK
NLO UU Laurent valuation	OK
NLO UU fractions absent	OK
NLO UU	65.61 s	6 coefficients	157.98 kB
NLO TT exact simplification	OK
NLO TT distribution product	OK
NLO TT Laurent valuation	OK
NLO TT fractions absent	OK
NLO TT smallest coefficient	3.5300000000000002 s	38.230000000000004 kB
NNLO UU contribution-wise simplification	OK
NNLO UU distribution product	OK
NNLO UU Laurent valuation	OK
NNLO UU fractions absent	OK
NNLO UU stored target	2 contributions	0.14 s	26.09 kB
ACTUAL_HARD_SIMPLIFICATION_OK

===== END FILE: \\wsl.localhost\Ubuntu\home\maxzhang\FACET\Codex\Tests\Results\ActualHardSimplification.log =====

## Follow-up question

Review the exact current Simplification.wl source below against the review criteria in the immediately preceding requests. Return prioritized findings with exact function names and concrete corrections. The active cards declare all eight CoefficientKinematics keys; stored-data tests currently reconstruct exact NLO UU, NLO TT, and NNLO UU coefficients.

===== BEGIN Simplification.wl =====
(* Card-driven exact simplification of physical master coefficients. *)

ClearAll[
  exactCoefficientNormalize,
  momentumFractionSymbols,
  singleMonomialData,
  positiveRootVariables,
  certifiedHalfIntegerPowerRule,
  canonicalizePhysicalBranches,
  minimumPolynomialExponents,
  fractionLaurentMonomial,
  normalizeHardFractionDependence,
  additiveTerms,
  structuralCommonAdditiveFactor,
  normalizeCoefficientKinematics,
  coefficientKinematicsFromCard,
  coefficientAutomaticForbiddenVariables,
  coefficientDeclaredFractions,
  coefficientLaurentValuation,
  coefficientExpectedFactorQ,
  coefficientDistributionObjectQ,
  coefficientCommonDistributionFactor,
  coefficientCanonicalRational,
  coefficientZeroStatus,
  coefficientFractionMonomialData,
  coefficientCertifiedPositiveQ,
  coefficientForbiddenFractionObjectQ,
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
  simplifyHardCoefficientContributionGroups,
  coefficientHomogeneousDegree,
  coefficientDimensionlessNormalize,
  normalizeHardCoefficientExpressions,
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

positiveRootVariables[powers_List, assumptions_] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    First /@ powers,
    symbol_Symbol /; Context[symbol] =!= "System`",
    Infinity
  ];
  Select[
    symbols,
    TimeConstrained[
      TrueQ @ FullSimplify[# > 0, Assumptions -> assumptions],
      5,
      False
    ] &
  ]
];

certifiedHalfIntegerPowerRule[
    power : Power[base_, exponent_Rational],
    positiveVariables_List,
    assumptions_
  ] := Module[{data, coefficient, powers, replacement},
  If[Denominator[exponent] =!= 2, Return[Nothing]];
  data = singleMonomialData[base, positiveVariables];
  If[data === $Failed, Return[Nothing]];
  {coefficient, powers} = data;
  If[
    ! TrueQ @ FullSimplify[
      base > 0 && coefficient > 0,
      Assumptions -> assumptions
    ],
    Return[Nothing]
  ];
  replacement = FullSimplify[
      coefficient^exponent,
      Assumptions -> assumptions
    ] Times @@ MapThread[
      Power,
      {positiveVariables, exponent powers}
    ];
  If[
    SameQ[power, replacement] ||
      ! TrueQ @ FullSimplify[
        power == replacement,
        Assumptions -> assumptions
      ],
    Nothing,
    power -> replacement
  ]
];

canonicalizePhysicalBranches[expressions_List, assumptions_] := Module[
  {powers, positiveVariables, rules, canonical},
  powers = DeleteDuplicates @ Cases[
    expressions,
    power : Power[_, exponent_Rational] /;
        Denominator[exponent] === 2 :> power,
    Infinity
  ];
  positiveVariables = positiveRootVariables[powers, assumptions];
  rules = DeleteCases[
    certifiedHalfIntegerPowerRule[
      #,
      positiveVariables,
      assumptions
    ] & /@ powers,
    Nothing
  ];
  canonical = expressions /. Dispatch[rules];
  If[! exactDataQ[canonical], Return[$Failed]];
  <|
    "Expressions" -> canonical,
    "Rules" -> rules,
    "PositiveVariables" -> positiveVariables
  |>
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

normalizeHardFractionDependence[
    expressions_List,
    setup_Association,
    assumptions_
  ] := Module[
  {
    fractionVariables, branchData, canonical, nonzero,
    fractionMonomials, fractionMonomial, scaled, normalized,
    normalizedExpressions, remainingFractions
  },
  fractionVariables = momentumFractionSymbols[setup];
  If[expressions === {} || fractionVariables === {},
    Return[<|
      "PreFactor" -> 1,
      "Expressions" -> expressions,
      "FractionVariables" -> fractionVariables,
      "FractionMonomial" -> 1,
      "BranchRules" -> {},
      "PositiveVariables" -> {}
    |>]
  ];
  branchData = canonicalizePhysicalBranches[expressions, assumptions];
  If[branchData === $Failed, Return[$Failed]];
  canonical = branchData["Expressions"];
  nonzero = DeleteCases[canonical, 0];
  If[nonzero === {},
    Return[<|
      "PreFactor" -> 1,
      "Expressions" -> canonical,
      "FractionVariables" -> fractionVariables,
      "FractionMonomial" -> 1,
      "BranchRules" -> branchData["Rules"],
      "PositiveVariables" -> branchData["PositiveVariables"]
    |>]
  ];
  fractionMonomials = fractionLaurentMonomial[
      #,
      fractionVariables
    ] & /@ nonzero;
  If[
    MemberQ[fractionMonomials, $Failed] ||
      Length[DeleteDuplicates[fractionMonomials, SameQ]] =!= 1,
    Return[$Failed]
  ];
  fractionMonomial = First[fractionMonomials];
  scaled = (#/fractionMonomial) & /@ canonical;
  normalized = parallelNormalizeCoefficients[
    scaled,
    assumptions,
    targetCoefficientSimplifyTimeLimit[],
    "Whole"
  ];
  If[normalized === $Failed, Return[$Failed]];
  normalizedExpressions = First[normalized];
  remainingFractions = Select[
    fractionVariables,
    ! FreeQ[normalizedExpressions, #] &
  ];
  If[remainingFractions =!= {}, Return[$Failed]];
  <|
    "PreFactor" -> fractionMonomial,
    "Expressions" -> normalizedExpressions,
    "FractionVariables" -> fractionVariables,
    "FractionMonomial" -> fractionMonomial,
    "BranchRules" -> branchData["Rules"],
    "PositiveVariables" -> branchData["PositiveVariables"],
    "Kernels" -> normalized[[2]],
    "AdditiveTerms" -> normalized[[3]]
  |>
];

additiveTerms[expression_] := If[
  Head[expression] === Plus,
  List @@ expression,
  {expression}
];

structuralCommonAdditiveFactor[expressions_List] := Module[
  {nonzero, shared},
  nonzero = DeleteCases[expressions, 0];
  If[nonzero === {}, Return[{1, expressions}]];
  shared = commonFactorMultiset[
    Flatten[topLevelFactors /@ additiveTerms[#]] & /@ nonzero
  ];
  {
    Times @@ shared,
    Map[
      If[TrueQ[# === 0], 0, #/(Times @@ shared)] &,
      expressions
    ]
  }
];

normalizeCoefficientKinematics[
    value_,
    massDimensions_Association
  ] := Module[
  {
    allowed, required, scale, coordinates, variables, definitions,
    positiveFractions, distributionFactor, laurentValuation,
    forbidden, grammar, physicalRegion, sourceInvariants,
    solutions, rules
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

  scale = Lookup[value, "Scale", None];
  coordinates = Lookup[value, "DimensionlessCoordinates", <||>];
  positiveFractions = Lookup[value, "PositiveFractions", Automatic];
  distributionFactor = Lookup[value, "DistributionFactor", Automatic];
  laurentValuation = Lookup[value, "LaurentValuation", Automatic];
  forbidden = Lookup[value, "ForbiddenVariables", Automatic];
  grammar = Lookup[value, "BranchGrammar", "PositiveMonomialRoots"];
  physicalRegion = Lookup[value, "PhysicalRegion", True];
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

  sourceInvariants = Select[
    Keys[massDimensions],
    # =!= scale && ! FreeQ[definitions, #] &
  ];
  If[sourceInvariants === {},
    Message[
      BuildSimplificationContext::invalid,
      "DimensionlessCoordinates",
      "no dimensionful source invariant occurs in the coordinate definitions"
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

  <|
    "PositiveFractions" -> positiveFractions,
    "DistributionFactor" -> distributionFactor,
    "LaurentValuation" -> laurentValuation,
    "Scale" -> scale,
    "DimensionlessCoordinates" -> coordinates,
    "DimensionlessVariables" -> variables,
    "DimensionlessRules" -> rules,
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
          "HadronMomentum", "HadronLongDirection",
          "HadronDualDirection", "HadronTransSpin"
        },
        {}
      ],
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

coefficientLaurentValuation[monomial_, variables_List] := Module[{data},
  data = singleMonomialData[monomial, variables];
  If[
    data === $Failed || ! TrueQ[First[data] === 1],
    $Failed,
    AssociationThread[variables, Last[data]]
  ]
];

coefficientExpectedFactorQ[actual_, Automatic, _] := True;

coefficientExpectedFactorQ[actual_, expected_, assumptions_] := TrueQ[
  exactCoefficientNormalize[actual - expected, assumptions] === 0
];

BuildSimplificationContext[config_Association] := Catch[
  Module[
    {
      hadronic, kinematics, assumptions, inferredFractions, fractions, roots,
      forbidden, scale, scalePositive, dimensionlessAssumptions
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
    assumptions = inferFractionAssumptions[
        Lookup[config, "MomentumFraction", {}]
      ] && hadronic["Assumptions"] && kinematics["PhysicalRegion"];
    scale = kinematics["Scale"];
    If[scale =!= None,
      scalePositive = TimeConstrained[
        TrueQ @ FullSimplify[scale > 0, Assumptions -> assumptions],
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
    roots = Table[
      Symbol["FeynFacet`Private`fractionRoot" <> ToString[index]],
      {index, Length[fractions]}
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
      assumptions,
      FullSimplify[
        assumptions /. kinematics["DimensionlessRules"],
        Assumptions -> kinematics["PhysicalRegion"]
      ]
    ];
    <|
      "FractionVariables" -> fractions,
      "FractionRootVariables" -> roots,
      "ExpectedDistributionFactor" -> kinematics["DistributionFactor"],
      "ExpectedLaurentValuation" -> kinematics["LaurentValuation"],
      "HadronicVariables" -> hadronic,
      "PhysicalAssumptions" -> assumptions,
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
    MemberQ[{$Failed, $TimedOut}, quotients] ||
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

coefficientFractionMonomialData[base_, fractions_List] := Module[
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
        Return[$Failed]
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
  ] := Module[{fractionPattern, forbiddenHeads, badObjects, badPowers},
  If[fractions === {}, Return[False]];
  fractionPattern = Alternatives @@ fractions;
  forbiddenHeads =
    _Log | _Gamma | _Beta | _Pochhammer | _Hypergeometric2F1 |
    _PolyLog | _Piecewise | _ConditionalExpression | _Abs | _Sign |
    _UnitStep | _DiracDelta;
  badObjects = Cases[
    HoldComplete[expression],
    object : forbiddenHeads /;
      ! FreeQ[Unevaluated[object], fractionPattern] :>
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
      coefficientForbiddenFractionObjectQ[expression, fractions],
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

simplifyHardCoefficientContributionGroups[
    groups_List,
    setup_Association,
    context_Association,
    timeLimit_: 60
  ] := Module[
  {
    lengths, flat, distribution, strippedGroups, fractions, columns,
    certified, nonzero, valuations, valuation, monomial, hard,
    remainingForbidden, branchRules, leafCount
  },
  lengths = Length /@ groups;
  flat = Flatten[groups, 1];
  distribution = coefficientCommonDistributionFactor[flat, timeLimit];
  If[distribution === $Failed, Return[$Failed]];
  If[
    ! coefficientExpectedFactorQ[
      distribution["Factor"],
      context["ExpectedDistributionFactor"],
      context["PhysicalAssumptions"]
    ],
    Return[$Failed]
  ];
  strippedGroups = coefficientPartitionByLengths[
    distribution["Expressions"],
    lengths
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
  remainingForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[hard, #] &
  ];
  If[remainingForbidden =!= {}, Return[$Failed]];
  <|
    "PreFactor" -> distribution["Factor"] monomial,
    "DistributionFactor" -> distribution["Factor"],
    "FractionVariables" -> fractions,
    "FractionMonomial" -> monomial,
    "LaurentValuation" -> valuation,
    "BranchRules" -> branchRules,
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
    normalized, reconstructed, difference
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
  normalized = exactCoefficientNormalize[
    (transformed/scale^degree) /. scale -> 1,
    context["DimensionlessAssumptions"]
  ];
  If[normalized === $Failed || ! FreeQ[normalized, scale], Return[$Failed]];
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

normalizeHardCoefficientExpressions[
    expressions_List,
    setup_Association,
    assumptions_
  ] := Module[
  {
    distribution, stripped, fractionData, normalized,
    context, remainingForbidden, valuation
  },
  distribution = coefficientCommonDistributionFactor[expressions];
  If[distribution === $Failed, Return[$Failed]];
  context = BuildSimplificationContext[setup];
  If[context === $Failed, Return[$Failed]];
  If[
    ! coefficientExpectedFactorQ[
      distribution["Factor"],
      context["ExpectedDistributionFactor"],
      assumptions
    ],
    Return[$Failed]
  ];
  stripped = distribution["Expressions"];
  fractionData = normalizeHardFractionDependence[
    stripped,
    setup,
    assumptions
  ];
  If[fractionData === $Failed, Return[$Failed]];
  valuation = coefficientLaurentValuation[
    fractionData["FractionMonomial"],
    context["FractionVariables"]
  ];
  If[valuation === $Failed, Return[$Failed]];
  If[
    context["ExpectedLaurentValuation"] =!= Automatic &&
      ! SameQ[valuation, context["ExpectedLaurentValuation"]],
    Return[$Failed]
  ];
  normalized = fractionData["Expressions"];
  remainingForbidden = Select[
    context["ForbiddenVariables"],
    ! FreeQ[normalized, #] &
  ];
  If[remainingForbidden =!= {}, Return[$Failed]];
  Join[
    KeyDrop[fractionData, "Expressions"],
    <|
      "PreFactor" ->
        distribution["Factor"] fractionData["PreFactor"],
      "DistributionFactor" -> distribution["Factor"],
      "LaurentValuation" -> valuation,
      "Expressions" -> normalized,
      "ForbiddenVariables" -> context["ForbiddenVariables"],
      "RemainingForbiddenVariables" -> {}
    |>
  ]
];

SimplifyHardCoefficients[
    input_List,
    setup_Association,
    OptionsPattern[]
  ] := Module[
  {
    context, method, timeLimit, physical, lengths, normalization,
    dimensionless
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
  If[method === "Assembled",
    physical = applyHadronicVariables[input, context["HadronicVariables"]],
    lengths = Length /@ input;
    physical = applyHadronicVariables[
      Flatten[input, 1],
      context["HadronicVariables"]
    ];
    If[physical =!= $Failed,
      physical = coefficientPartitionByLengths[physical, lengths]
    ]
  ];
  If[physical === $Failed || ! exactDataQ[physical], Return[$Failed]];
  normalization = If[
    method === "Assembled",
    normalizeHardCoefficientExpressions[
      physical,
      setup,
      context["PhysicalAssumptions"]
    ],
    simplifyHardCoefficientContributionGroups[
      physical,
      setup,
      context,
      timeLimit
    ]
  ];
  If[normalization === $Failed, Return[$Failed]];
  dimensionless = coefficientDimensionlessNormalize[
      #,
      context,
      timeLimit
    ] & /@ normalization["Expressions"];
  If[MemberQ[dimensionless, $Failed], Return[$Failed]];
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

===== END Simplification.wl =====

## Pro response

Verdict

I inspected the extracted source archive, including FeynFacet/Private/Simplification.wl, the three process cards, the reduction integration, the synthetic tests, the stored-data test scripts and log, the project goal, and the report source. 

process_independent_simplificat…

There are no literal pp→hX symbols or fixed Mandelstam-variable names hidden in Simplification.wl. The reusable code does not hard-code xa, xb, zh, s, t, u, the UU/TT distribution products, or the particular dimensionless coordinates. That part of the separation is successful.

However, the current implementation is not yet a production-safe realization of the stated card contract. Three correctness-critical issues remain:

the source and dimensionless physical chambers are not certified as consistent, so assumption-based equality checks can become vacuous;

the twist-2 distribution product is inferred from the computed expression rather than independently derived from the card, and the two input shapes do not implement the same distribution-level algebra;

the declared branch grammar is not enforced through the full simplification and dimensionless-normalization chain.

These matter because the repository requires an exact analytic result with explicit branch and dimensional-regulator information; fixed-point checks cannot substitute for those contracts. 

AGENTS

P0: correctness-critical findings
P0.1 — The physical chamber and coordinate map can yield vacuous certificates
Source

FeynFacet/Private/Simplification.wl:

normalizeCoefficientKinematics, lines 306–460;

BuildSimplificationContext, lines 515–616;

coefficientDimensionlessNormalize, lines 1550–1592.

Problem

The context combines two different sets of variables without first imposing the coordinate equations:

Wolfram Language
assumptions =
  inferFractionAssumptions[...] &&
  hadronic["Assumptions"] &&
  kinematics["PhysicalRegion"];

For the supplied cards this means combining

s>0,t<0,u<0,s+t+u>0

with

x>0,y>0,x+y<1,

but not yet imposing

x=−
s
t
	​

,y=−
s
u
	​

.

Later, dimensionlessAssumptions is formed by substituting

Wolfram Language
assumptions /. kinematics["DimensionlessRules"]

and simplifying under PhysicalRegion. If a card supplies a dimensionless chamber inconsistent with the source chamber, this can reduce to False. Subsequent calls such as

Wolfram Language
Simplify[expr, Assumptions -> False]

or FullSimplify under an inconsistent condition are not valid scientific certificates: identities can be accepted vacuously.

The coordinate validation also proves only that Solve returns one rule list. It does not prove that:

each declared coordinate is dimensionless;

the forward and inverse maps compose to the identity;

the inverse map is nonsingular in the declared chamber;

the source chamber maps into the declared dimensionless chamber;

the dimensionless chamber maps back into the source chamber;

all dimensionful invariants that can remain in a hard coefficient are covered by the scale and coordinates.

A bad declaration such as

Wolfram Language
"DimensionlessCoordinates" -> <|xx -> -A/Q2^2|>

can satisfy the current Solve test despite xx not being dimensionless.

Required correction

Separate the assumptions:

Wolfram Language
sourceAssumptions =
  inferFractionAssumptions[Lookup[config, "MomentumFraction", {}]] &&
  hadronic["Assumptions"];

coordinateRegion = kinematics["PhysicalRegion"];

Then certify all of the following before constructing the context.

1. Mass dimensions

For every coordinate definition z
i
	​

=f
i
	​

,

dimf
i
	​

=0,

and for the scale μ
2
,

dimμ
2
>0.

Implement an exact recursive dimension evaluator over Plus, Times, and Power, using KinematicMassDimensions.

2. Forward composition

If rules is the solved inverse map, require

Wolfram Language
And @@ MapThread[
  exactZeroQ[#1 - (#2 /. rules)] &,
  {variables, definitions}
]

or an assumption-aware equivalent where denominators require the source chamber.

3. Backward composition

Require

Wolfram Language
And @@ MapThread[
  TrueQ @ FullSimplify[
    #1 == (#2 /. Thread[variables -> definitions]),
    Assumptions -> sourceAssumptions
  ] &,
  {First /@ rules, Last /@ rules}
]
4. Nonempty mapped chamber

Use exact semialgebraic reasoning rather than sampling:

Wolfram Language
mappedSourceAssumptions = sourceAssumptions /. rules;

Reduce[
  mappedSourceAssumptions && coordinateRegion,
  realVariables,
  Reals
] =!= False
5. Chamber implications

At minimum require

(source chamber)
	​

inverse map
	​

⟹coordinate chamber.

Preferably also require the reverse implication for the kinematic part:

μ
2
>0 ∧ coordinate chamber⟹(source chamber)
	​

inverse map
	​

.

Do not create DimensionlessAssumptions until these tests have succeeded. Store it without simplifying under a potentially inconsistent condition:

Wolfram Language
dimensionlessAssumptions =
  mappedSourceAssumptions && coordinateRegion;
Necessary negative test

A synthetic card with

Wolfram Language
A < 0;
xx -> -A/Q2;
"PhysicalRegion" -> xx < 0;

must make BuildSimplificationContext return $Failed.

P0.2 — DistributionFactor -> Automatic is circular physical validation
Source

Simplification.wl:

coefficientExpectedFactorQ, lines 509–513;

coefficientCommonDistributionFactor, lines 631–699;

simplifyHardCoefficientContributionGroups, lines 1433–1523;

normalizeHardCoefficientExpressions, lines 1594–1650.

All three cards currently declare:

Wolfram Language
"DistributionFactor" -> Automatic
Problem

The implementation derives the common distribution monomial from the output expression itself. Then

Wolfram Language
coefficientExpectedFactorQ[actual_, Automatic, _] := True;

accepts whatever was found.

The algebraic derivation is generally conservative: it freezes all twist-2 objects and requires the quotient to be free of them. But it does not independently establish that the result belongs to the requested physical channel.

For example, a broken UU projector that produced

g
1
	​

(x
a
	​

)g
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

uniformly in every coefficient could be accepted under Automatic, even though the card is intended to calculate UU.

It also permits a common negative power of a distribution object in principle, because the fallback treats distribution atoms as Laurent variables. A physical twist-2 convolution factor should not be inferred merely as an arbitrary common Laurent monomial in function objects.

Assembled and ContributionWise are not equivalent here

In ContributionWise, the code flattens every contribution from every master:

Wolfram Language
flat = Flatten[groups, 1];
distribution = coefficientCommonDistributionFactor[flat, timeLimit];

Thus the same distribution monomial must already be present in each nonzero contribution.

Consider one master with contributions

FA,GB,−GB.

The assembled coefficient is

FA.

Assembled can derive F. ContributionWise sees both F and G before the cancellation and fails. Therefore the two methods do not currently represent one common mathematical normalization applied to two input shapes.

The implemented square-root cancellation does occur after summing contributions, but distribution-basis cancellation does not.

Required correction

For the current three production cards, declare the physical distribution factor explicitly:

Wolfram Language
(* NLO UU and NNLO double-real UU *)
"DistributionFactor" -> D1[zh] f1[xa] f1[xb]

(* NLO TT *)
"DistributionFactor" -> H1[zh] h1[xa] f1[xb]

Then the simplifier must:

divide by the declared factor;

certify reconstruction exactly;

require the quotient to contain no object whose head belongs to $twist2DistributionHeads;

reject negative or additional distribution powers.

If Automatic is retained as a supported option, its status should be explicitly reported as

Wolfram Language
"DistributionFactorStatus" -> "DerivedFromComputedCoefficients"

rather than treated as an independent physical check.

For full equivalence of the two input shapes, decompose contributions in a distribution monomial basis, sum the rational coefficient of each monomial within each master, and require that only the declared monomial survives. In symbols,

C
m
	​

=
ν
∑
	​

c
m,ν
	​

a
∏
	​

F
a
ν
a
	​

	​

,

with acceptance criterion

c
m,ν
	​

=0for all ν

=ν
card
	​

.

That permits exact cancellation before selecting the physical distribution product.

P0.3 — The branch grammar is declared but not enforced end to end
Source

Simplification.wl:

$coefficientBranchGrammars, line 73;

grammar validation, lines 348 and 364;

exactCoefficientNormalize, lines 75–78;

canonicalizePhysicalBranches, lines 159–183;

coefficientForbiddenFractionObjectQ, lines 761–788;

coefficientPositiveRootLift, lines 790–875;

coefficientDimensionlessNormalize, lines 1550–1592.

Problem

The card string

Wolfram Language
"BranchGrammar" -> "PositiveMonomialRoots"

is checked against a one-element list, but it does not control an end-to-end grammar validator.

The two input paths then behave differently:

Assembled uses canonicalizePhysicalBranches followed by unrestricted Simplify;

ContributionWise has an explicit but incomplete list of forbidden fraction-dependent heads;

dimensionless normalization again uses unrestricted Simplify.

The forbidden-head list contains Log, Gamma, Beta, Pochhammer, Hypergeometric2F1, PolyLog, Abs, Sign, and several distributional heads, but it is not a complete analytic grammar. An arbitrary object such as

Wolfram Language
f[xa]
Sin[xa]
ArcTan[xa]
MeijerG[..., xa]

is not explicitly rejected at that stage. Most such expressions eventually fail PolynomialQ, but the failure is indirect and does not certify branch preservation.

More importantly, non-fraction-dependent logarithms, noninteger powers, Gamma functions, endpoint powers, and BMHV structures are passed to general Simplify. Their physical values may remain mathematically equal in the declared chamber, but the code does not record which branch transformation occurred. That does not satisfy the requirement that branch information remain explicit and testable.

Required correction

Add one function with a single responsibility:

Wolfram Language
validateCoefficientBranchGrammar[
  expression_,
  context_Association
]

For "PositiveMonomialRoots":

every noninteger power involving a momentum fraction must have rational half-integer exponent;

its base must be a monomial in the declared positive fractions times a coefficient exactly proved positive;

all other fraction-dependent analytic heads must be rejected explicitly;

no PowerExpand is permitted;

all branch-sensitive objects independent of the fractions must be placed in an immutable registry before rational simplification.

Before any Together, Cancel, Factor, or assumption-aware simplification, freeze maximal objects such as

log(⋯),Γ(⋯),(⋯)
a+bϵ
,
2
	​

F
1
	​

(⋯),BMHV structures.

Perform rational algebra on the remaining shell, restore the objects, and require that the output branch registry differs from the input only by explicitly certified rules.

The same validator must run:

after hadronic substitution;

after fraction-root lifting;

after hard-factor extraction;

after the dimensionless coordinate map.

P1: important correctness, scale, and integration findings
P1.1 — The public TimeLimit is ignored by the Assembled path
Source

SimplifyHardCoefficients, lines 1652–1732;

normalizeHardCoefficientExpressions, lines 1594–1650;

normalizeHardFractionDependence, lines 213–282.

SimplifyHardCoefficients reads "TimeLimit", but the Assembled path calls

Wolfram Language
normalizeHardCoefficientExpressions[
  physical,
  setup,
  context["PhysicalAssumptions"]
]

without passing it.

normalizeHardFractionDependence instead uses

Wolfram Language
targetCoefficientSimplifyTimeLimit[]

from Reduction.wl, and fractionLaurentMonomial contains unbounded Cancel[Together[...]].

Thus

Wolfram Language
SimplifyHardCoefficients[..., "TimeLimit" -> 180]

does not give a 180-second bound to the main Assembled normalization.

Fix

Pass one time limit through every bounded algebraic operation:

Wolfram Language
normalizeHardCoefficientExpressions[
  expressions_,
  context_,
  timeLimit_
]

and remove the dependency on the global reduction-specific limit.

Return separate statuses:

Wolfram Language
"Verified"
"TimedOutUnchanged"
"Failed"

A timeout must never be conflated with inequality.

P1.2 — ContributionWise still uses the known non-scaling common-denominator algorithm
Source

coefficientCommonDenominatorStep, lines 1168–1202;

coefficientCommonFractionDenominator, lines 1204–1219;

coefficientAssembleRootColumn, lines 1221–1294;

coefficientCertifyRootColumn, lines 1299–1381.

When neither denominator divides the other, the code uses their product:

Wolfram Language
common denominator

followed by monic normalization. It then constructs one common denominator over the entire contribution group.

This is exact, but it is precisely the algebraic pattern that becomes unusable when almost every leaf has a distinct denominator. The proportionality certificate then performs a separate Cancel[Together[...]] zero test for every sparse coefficient.

The supplied NNLO test contains only the smallest stored target, split into two additive terms. It does not exercise the production-scale denominator diversity.

Fix

Use the already established exact hierarchy:

lift each factor separately;

retain exact unnormalized numerator/denominator pairs;

merge only structurally equal denominators;

certify the universal fraction monomial entrywise or in bounded blocks;

collapse each certified block to a fraction-free coefficient;

sum those coefficients.

For unresolved blocks, use recursive subdivision and coefficientwise sparse proportionality checks rather than one global denominator.

P1.3 — Production reduction bypasses the intended unified API
Source

FeynFacet/Private/Reduction.wl:

target physicalization and normalization, lines 2379–2415;

master normalization, lines 2491–2497;

normalizeMasterCoefficients, lines 1794–1909;

legacy hard normalization call, lines 1857–1861.

The production reducer calls the private function

Wolfram Language
normalizeHardCoefficientExpressions

rather than SimplifyHardCoefficients or a shared internal kernel. It therefore always uses the legacy Assembled route after prior target/master simplification.

Conversely, Simplification.wl calls parallelNormalizeCoefficients and targetCoefficientSimplifyTimeLimit from Reduction.wl. This creates circular module ownership:

Reduction.wl⟷Simplification.wl.
Fix

Create one internal mathematical kernel, for example:

Wolfram Language
simplifyPhysicalHardCoefficientGroups[
  groups_,
  context_,
  timeLimit_
]

It should accept already physicalized expressions.

The public wrapper applies hadronic variables, converts its input shape to groups, and calls this kernel.

The reduction layer calls the same kernel after its existing exact physicalization.

The dynamic worker scheduler belongs in Core.wl or Simplification.wl, not Reduction.wl.

P1.4 — Automatic forbidden variables are incomplete
Source

coefficientAutomaticForbiddenVariables, lines 469–484.

It includes:

momentum fractions;

hadron momenta;

long and dual directions;

transverse-spin vectors.

It does not include:

parton momenta;

remaining phase-space momenta;

virtual-loop momenta;

all keys of HadronicVariables["Coordinates"] unless they also occur in the selected card fields;

the global basis vectors, in particular transverse basis vectors such as xhat and yhat.

The reduction layer separately rejects integrated momenta, but the public simplification API does not.

Fix

Construct the automatic list from:

Wolfram Language
MomentumFraction
PartonMomentum
PhaseSpaceMomentum
ForwardAmplitudes["LoopMomenta"]
ConjugateAmplitudes["LoopMomenta"]
Keys[HadronicVariables["Coordinates"]]
globalBasis

excluding only symbols explicitly declared as allowed physical tensor or angular structures.

Run the check on both:

Wolfram Language
"Expressions"
"DimensionlessExpressions"
P1.5 — The coordinate map does not cover every possible dimensionful invariant

sourceInvariants is built only from dimensionful symbols that happen to occur in the coordinate definitions:

Wolfram Language
Select[
  Keys[massDimensions],
  # =!= scale && ! FreeQ[definitions, #] &
]

A dimensionful invariant omitted from the coordinate definitions can remain in the normalized result and be incorrectly treated as degree zero in the scale.

Fix

Require either:

{all nonzero-dimension hard variables except the scale}={source invariants solved by the coordinates},

or add an explicit card field declaring which dimensionful quantities are intentionally retained.

After normalization, independently compute the total mass dimension of the returned expression and require it to be zero.

P1.6 — Concrete Mathematica semantic bug in distribution normalization
Source

coefficientCommonDistributionFactor, lines 675–683.

After mapping exactCoefficientNormalize over a list, it tests

Wolfram Language
MemberQ[{$Failed, $TimedOut}, quotients]

This asks whether either sentinel matches the entire list quotients; it does not detect a sentinel contained in that list.

Fix
Wolfram Language
If[
  quotients === $TimedOut ||
    ! ListQ[quotients] ||
    MemberQ[quotients, $Failed | $TimedOut] ||
    ! FreeQ[quotients, Alternatives @@ atoms],
  Return[$Failed]
];

The later reconstruction normally prevents a false successful result, but the current test is semantically wrong and obscures diagnostics.

P1.7 — structuralCommonAdditiveFactor does not compute a common additive factor
Source

Simplification.wl, lines 290–304.

For

FA+FB,

the implementation flattens both term-factor lists into

{F,A,F,B}

and, for a single expression, identifies F
2
AB rather than F.

The distribution-factor code usually detects the over-extraction and falls back to the Laurent-monomial method, so this does not explain the successful stored tests. But the helper’s result is not what its name claims, and Reduction.wl later uses it for the artifact’s overall factor.

Exact replacement if retained
Wolfram Language
commonFactorWithinExpression[expression_] :=
  commonFactorMultiset[
    topLevelFactors /@ additiveTerms[expression]
  ];

shared = commonFactorMultiset[
  commonFactorWithinExpression /@ nonzeroExpressions
];

Prefer deleting this preliminary path and using one exact atom-Laurent factor routine.

P1.8 — Temporary root symbols are globally predictable and not reserved
Source

BuildSimplificationContext, lines 577–580.

Roots are created as

Wolfram Language
FeynFacet`Private`fractionRoot1
FeynFacet`Private`fractionRoot2
...

There is no input check that these symbols are absent.

Fix

Either use fresh symbols stored only in the context:

Wolfram Language
roots = Table[Unique["fractionRoot$"], Length[fractions]];

or explicitly reject an input containing any reserved root symbol before lifting.

P1.9 — The current test records are too narrow

The synthetic test verifies:

renamed variables;

coordinate inversion;

simple Assembled factor extraction;

one square-root cancellation in ContributionWise;

one ϵ-dependent scale power.

The stored-data log verifies:

all six NLO UU coefficients;

only the smallest single NLO TT coefficient;

one small NNLO target containing two additive contributions.

It does not verify:

Assembled and ContributionWise on the same input;

all six TT masters;

a complete NNLO master column;

wrong twist-2 channel rejection;

inconsistent source and dimensionless chambers;

a non-dimensionless coordinate;

a singular or noninvertible coordinate map;

unsupported branch expressions;

explicit expected distribution/valuation mismatch;

a timeout retaining the exact unchanged input;

full reconstruction

C
m
	​

=P
universal
	​

H
m
	​

;

absence of all hadronic and basis vectors.

Also, the archive is not independently runnable: FeynFacet.m fingerprints and loads source files not included in the archive, including Distributions.wl, Topologies.wl, DimensionalShift.wl, Collinear.wl, CoefficientStore.wl, and CoefficientModules.wl. The stored-data files referenced by the test scripts are also absent. I could inspect the sources and the stored log, but not independently rerun those recorded calculations from this archive.

P2: deletions and unifications

After the two input shapes use one normalization kernel, the following can be deleted or merged.

Remove the legacy Assembled fraction stack

These functions are then redundant:

Wolfram Language
singleMonomialData
positiveRootVariables
certifiedHalfIntegerPowerRule
canonicalizePhysicalBranches
minimumPolynomialExponents
fractionLaurentMonomial
normalizeHardFractionDependence
normalizeHardCoefficientExpressions

Represent Assembled input as singleton contribution groups:

Wolfram Language
groups = List /@ assembledExpressions;

and send both shapes through the same exact fraction-root kernel.

Remove coefficientValidEntryQ

It is only an alias for coefficientValidLeafQ.

Remove the unused setup argument

simplifyHardCoefficientContributionGroups receives setup but does not use it.

Build the context once

SimplifyHardCoefficients builds the context, but normalizeHardCoefficientExpressions builds it again. Pass the existing context.

Move the worker scheduler

parallelNormalizeCoefficients is generic independent-expression infrastructure. It should not live in Reduction.wl while Simplification.wl depends on it.

Define output metadata consistently

Currently "PositiveVariables" has different meanings:

Assembled reports symbols discovered while simplifying roots;

ContributionWise reports all momentum fractions.

Either remove the field or define one stable meaning, such as:

Wolfram Language
"CertifiedPositiveBases"

with exact proof records.

Similarly, "BranchRules" should not imply complete branch provenance unless every branch-sensitive rewrite is recorded.

Process-card assessment
What the three cards already provide correctly

All three cards provide:

the momentum fractions through MomentumFraction;

exact hadronic coordinates;

a source physical chamber;

invariant mass dimensions;

one positive scale s;

the invertible candidate coordinates

x=−t/s,y=−u/s;

the dimensionless chamber

x>0,y>0,x+y<1;

a declared branch grammar;

process-specific distribution projections through SetDistributionZero.

The TT card’s use of the exact object f1[xa] is appropriate for distinguishing the a-leg from f1[xb].

What is still missing for independent production validation

I recommend changing the cards to:

Wolfram Language
(* NLO UU *)
"DistributionFactor" -> D1[zh] f1[xa] f1[xb],
"LaurentValuation" -> <|xa -> -1, xb -> -1, zh -> -2|>

(* NLO TT *)
"DistributionFactor" -> H1[zh] h1[xa] f1[xb],
"LaurentValuation" -> <|xa -> -1, xb -> -1, zh -> -2|>

(* NNLO double-real UU *)
"DistributionFactor" -> D1[zh] f1[xa] f1[xb]

For NNLO, keep LaurentValuation -> Automatic until the complete 342-master result has established the same valuation, or declare it explicitly once that proof is part of the retained record.

The cards otherwise contain the necessary process-specific kinematics. The principal deficiency is not missing kinematic data; it is that the reusable implementation does not yet certify the consistency and branch meaning of those declarations strongly enough.

Required test additions before production use

The smallest adequate exact test matrix is:

Test	Acceptance criterion
Same input through both shapes	Identical distribution factor, Laurent valuation, hard coefficients, scale powers, and dimensionless coefficients
Distribution cancellation across contributions	Both shapes either derive the same declared product or both reject by a documented rule
Wrong UU/TT distribution product	$Failed
Reciprocal/additional distribution factor	$Failed
Contradictory coordinate chamber	BuildSimplificationContext returns $Failed
Non-dimensionless coordinate	$Failed
Noninvertible/singular map	$Failed
Sqrt[rhoA rhoB] with positive fractions	accepted with exact reconstruction
Sqrt[rhoA+rhoB]	$Failed
Log[rhoA] or Gamma[rhoA+\epsilon]	$Failed under the current grammar
Preexisting temporary root symbol	$Failed
Explicit wrong Laurent valuation	$Failed
Full NLO TT six-master vector	exact reconstruction and no forbidden variables
Representative complete NNLO master column	exact compositional reconstruction without a global common denominator
Timeout path	unchanged exact input retained and status recorded as unresolved

For every accepted coefficient C
m
	​

, retain the exact certificate

C
m
	​

=F
dist
	​

i
∏
	​

x
i
v
i
	​

	​

H
m
	​

,

with

∂x
i
	​

∂H
m
	​

	​

=0

represented computationally by exact absence of all fraction and root variables. For the dimensionless result 
H
m
	​

, retain

H
m
	​

(s,t,u,ϵ)=s
d
m
	​

H
m
	​

(x,y,ϵ),x=−
s
t
	​

,y=−
s
u
	​

,

together with the exact forward and inverse map certificates.

The core design—card-declared physics with one exact simplification API—is appropriate. The next implementation step should be to make the physical context nonvacuous, make the distribution and branch contracts independent of the computed answer, and route both input shapes and the production reduction through one shared certified kernel.

## Sources sent to Pro

- [process_independent_simplification_review.zip](Sources/01_simplification_review/process_independent_simplification_review.zip)
