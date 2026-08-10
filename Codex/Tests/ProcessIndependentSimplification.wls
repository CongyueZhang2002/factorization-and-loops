$HistoryLength = 0;

root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Clear[$PrePrint];

assert[label_String, condition_] := If[
  TrueQ[condition],
  Print[label, "\tOK"],
  Print[label, "\tFAILED\t", InputForm[condition]];
  Quit[1]
];

uuCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
ttCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "TT.wl"}]];
nnloCard = Get[
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Cards", "UU.wl"}]
];

uuContext = BuildSimplificationContext[uuCard];
ttContext = BuildSimplificationContext[ttCard];
nnloContext = BuildSimplificationContext[nnloCard];

assert["UU context", AssociationQ[uuContext]];
assert["TT context", AssociationQ[ttContext]];
assert["NNLO context", AssociationQ[nnloContext]];
assert[
  "Card fraction inference",
  uuContext["FractionVariables"] === {xa, xb, zh}
];
assert[
  "Card coordinate inversion",
  uuContext["DimensionlessRules"] === {t -> -s x, u -> -s y}
];
assert[
  "Card assumptions imply the positive scale",
  TrueQ @ FullSimplify[s > 0, Assumptions -> uuContext["PhysicalAssumptions"]]
];
assert[
  "Source assumptions do not mix in dimensionless coordinates",
  FreeQ[uuContext["PhysicalAssumptions"], x | y]
];
assert[
  "Dimensionless chamber is nonvacuous",
  uuContext["DimensionlessAssumptions"] =!= False
];

syntheticCard = <|
  "PartonMomentum" -> ({pA, pB} -> {pH}),
  "PhaseSpaceMomentum" -> {k},
  "MomentumFraction" -> ({rhoA, rhoB} -> {rhoH}),
  "HadronicVariables" -> <|
    "Coordinates" -> <||>,
    "Assumptions" -> (
      Q2 > 0 && A < 0 && B < 0 && Q2 + A + B > 0 &&
      Element[{Q2, A, B}, Reals]
    )
  |>,
  "KinematicMassDimensions" -> <|Q2 -> 2, A -> 2, B -> 2|>,
  "CoefficientKinematics" -> <|
    "PositiveFractions" -> Automatic,
    "DistributionFactor" -> f1[rhoA] f1[rhoB] D1[rhoH],
    "LaurentValuation" -> <|rhoA -> -1, rhoB -> -1, rhoH -> -2|>,
    "Scale" -> Q2,
    "DimensionlessCoordinates" -> <|xx -> -A/Q2, yy -> -B/Q2|>,
    "ForbiddenVariables" -> {},
    "BranchGrammar" -> "PositiveMonomialRoots",
    "PhysicalRegion" -> (
      xx > 0 && yy > 0 && xx + yy < 1 && Element[{xx, yy}, Reals]
    )
  |>
|>;

assert[
  "Missing coefficient-kinematics block rejected",
  Quiet[
    BuildSimplificationContext[
      KeyDrop[syntheticCard, "CoefficientKinematics"]
    ],
    BuildSimplificationContext::invalid
  ] === $Failed
];
assert[
  "Incomplete coefficient-kinematics block rejected",
  Quiet[
    BuildSimplificationContext[
      ReplacePart[
        syntheticCard,
        "CoefficientKinematics" ->
          KeyDrop[syntheticCard["CoefficientKinematics"], "BranchGrammar"]
      ]
    ],
    BuildSimplificationContext::invalid
  ] === $Failed
];
assert[
  "Contradictory coordinate chamber rejected",
  Quiet[
    BuildSimplificationContext[
      ReplacePart[
        syntheticCard,
        {"CoefficientKinematics", "PhysicalRegion"} ->
          (xx < 0 && yy > 0 && Element[{xx, yy}, Reals])
      ]
    ],
    BuildSimplificationContext::invalid
  ] === $Failed
];
assert[
  "Dimensionful coordinate rejected",
  Quiet[
    BuildSimplificationContext[
      ReplacePart[
        syntheticCard,
        {"CoefficientKinematics", "DimensionlessCoordinates"} ->
          <|xx -> -A/Q2^2, yy -> -B/Q2|>
      ]
    ],
    BuildSimplificationContext::invalid
  ] === $Failed
];
assert[
  "Incomplete coordinate map rejected",
  Quiet[
    BuildSimplificationContext[
      ReplacePart[
        syntheticCard,
        {"CoefficientKinematics", "DimensionlessCoordinates"} ->
          <|xx -> -A/Q2, yy -> -2 A/Q2|>
      ]
    ],
    BuildSimplificationContext::invalid
  ] === $Failed
];

syntheticContext = BuildSimplificationContext[syntheticCard];
assert["Renamed-variable context", AssociationQ[syntheticContext]];
assert[
  "Renamed fractions",
  syntheticContext["FractionVariables"] === {rhoA, rhoB, rhoH}
];
assert[
  "Renamed coordinate inversion",
  syntheticContext["DimensionlessRules"] === {
    A -> -Q2 xx,
    B -> -Q2 yy
  }
];

distributionFactor = f1[rhoA] f1[rhoB] D1[rhoH];
syntheticExpression =
  distributionFactor (A + B)/(rhoA rhoB rhoH^2);
syntheticResult = SimplifyHardCoefficients[
  {syntheticExpression},
  syntheticCard
];

assert["Synthetic simplification", AssociationQ[syntheticResult]];
assert[
  "Distribution factor derived",
  TrueQ @ Simplify[
    syntheticResult["DistributionFactor"] == distributionFactor,
    Assumptions -> syntheticContext["PhysicalAssumptions"]
  ]
];
assert[
  "Declared distribution factor verified",
  syntheticResult["DistributionFactorStatus"] === "DeclaredAndVerified"
];
Print[
  "Synthetic factors\t",
  InputForm @ KeyTake[
    syntheticResult,
    {"PreFactor", "FractionMonomial", "DistributionFactor"}
  ]
];
assert[
  "Laurent factor derived",
  TrueQ @ Simplify[
    syntheticResult["FractionMonomial"] == 1/(rhoA rhoB rhoH^2),
    Assumptions -> syntheticContext["PhysicalAssumptions"]
  ]
];
assert[
  "Fractions absent from hard coefficient",
  FreeQ[
    syntheticResult["Expressions"],
    Alternatives @@ syntheticContext["FractionVariables"]
  ]
];
assert["Scale degree derived", syntheticResult["ScalePowers"] === {1}];
assert[
  "Dimensionless coefficient reconstructed",
  TrueQ @ FullSimplify[
    First[syntheticResult["DimensionlessExpressions"]] == -(xx + yy),
    Assumptions -> syntheticContext["DimensionlessAssumptions"]
  ]
];

syntheticContributionGroups = {
  {
    distributionFactor Sqrt[rhoA rhoB] A/(rhoA rhoB rhoH^2),
    distributionFactor (B - Sqrt[rhoA rhoB] A)/(
      rhoA rhoB rhoH^2
    )
  },
  {
    distributionFactor Q2/(rhoA rhoB rhoH^2)
  }
};
syntheticContributionResult = SimplifyHardCoefficients[
  syntheticContributionGroups,
  syntheticCard,
  "Method" -> "ContributionWise"
];
syntheticReassembledResult = SimplifyHardCoefficients[
  Total /@ syntheticContributionGroups,
  syntheticCard,
  "Method" -> "Assembled"
];

assert[
  "Contribution-wise simplification",
  AssociationQ[syntheticContributionResult]
];
assert[
  "Contribution-wise method recorded",
  syntheticContributionResult["Method"] === "ContributionWise"
];
assert[
  "Contribution-wise distribution derived",
  TrueQ @ FullSimplify[
    syntheticContributionResult["DistributionFactor"] ==
      distributionFactor,
    Assumptions -> syntheticContext["PhysicalAssumptions"]
  ]
];

otherDistribution = g1L[rhoA] f1[rhoB] D1[rhoH];
distributionCancellationGroups = {{
  distributionFactor A/(rhoA rhoB rhoH^2),
  otherDistribution B/(rhoA rhoB rhoH^2),
  -otherDistribution B/(rhoA rhoB rhoH^2)
}};
distributionCancellationContribution = SimplifyHardCoefficients[
  distributionCancellationGroups,
  syntheticCard,
  "Method" -> "ContributionWise"
];
distributionCancellationAssembled = SimplifyHardCoefficients[
  Total /@ distributionCancellationGroups,
  syntheticCard,
  "Method" -> "Assembled"
];
assert[
  "Distribution-basis cancellation agrees in both input shapes",
  AssociationQ[distributionCancellationContribution] &&
    AssociationQ[distributionCancellationAssembled] &&
    SameQ[
      distributionCancellationContribution["Expressions"],
      distributionCancellationAssembled["Expressions"]
    ] &&
    SameQ[distributionCancellationContribution["Expressions"], {A}]
];

wrongDistributionExpression =
  g1L[rhoA] f1[rhoB] D1[rhoH] A/(rhoA rhoB rhoH^2);
assert[
  "Wrong twist-2 channel rejected",
  Quiet[
    SimplifyHardCoefficients[{wrongDistributionExpression}, syntheticCard]
  ] === $Failed
];
assert[
  "Reciprocal distribution factor rejected",
  Quiet[
    SimplifyHardCoefficients[
      {
        f1[rhoB] D1[rhoH] A/(
          f1[rhoA] rhoA rhoB rhoH^2
        )
      },
      syntheticCard
    ]
  ] === $Failed
];
assert[
  "Wrong Laurent valuation rejected",
  Quiet[
    SimplifyHardCoefficients[
      {syntheticExpression},
      ReplacePart[
        syntheticCard,
        {"CoefficientKinematics", "LaurentValuation"} ->
          <|rhoA -> -1, rhoB -> -1, rhoH -> -1|>
      ]
    ]
  ] === $Failed
];
assert[
  "Nonmonomial fraction root rejected",
  Quiet[
    SimplifyHardCoefficients[
      {
        distributionFactor Sqrt[rhoA + rhoB] A/(
          rhoA rhoB rhoH^2
        )
      },
      syntheticCard
    ]
  ] === $Failed
];
assert[
  "Unsupported fraction-dependent analytic head rejected",
  Quiet[
    SimplifyHardCoefficients[
      {
        distributionFactor Sin[rhoA] A/(
          rhoA rhoB rhoH^2
        )
      },
      syntheticCard
    ]
  ] === $Failed
];
assert[
  "Residual parton momentum rejected",
  Quiet[
    SimplifyHardCoefficients[
      {
        distributionFactor pA A/(rhoA rhoB rhoH^2)
      },
      syntheticCard
    ]
  ] === $Failed
];

branchSensitiveResult = SimplifyHardCoefficients[
  {
    distributionFactor Log[-A/Q2] Gamma[1 + Epsilon]/(
      rhoA rhoB rhoH^2
    )
  },
  syntheticCard
];
assert[
  "Fraction-independent branch objects retained exactly",
  AssociationQ[branchSensitiveResult] &&
    branchSensitiveResult["FrozenBranchObjectCount"] >= 2 &&
    SameQ[
      branchSensitiveResult["Expressions"],
      {Log[-A/Q2] Gamma[1 + Epsilon]}
    ]
];
assert[
  "Branch objects mapped without PowerExpand",
  SameQ[
    branchSensitiveResult["DimensionlessExpressions"],
    {Log[xx] Gamma[1 + Epsilon]}
  ]
];
assert[
  "Contribution-wise Laurent valuation derived after cancellation",
  syntheticContributionResult["LaurentValuation"] === <|
    rhoA -> -1,
    rhoB -> -1,
    rhoH -> -2
  |>
];
assert[
  "Contribution-wise hard coefficients reconstructed",
  And @@ MapThread[
    TrueQ @ FullSimplify[
      #1 == #2,
      Assumptions -> syntheticContext["PhysicalAssumptions"]
    ] &,
    {syntheticContributionResult["Expressions"], {B, Q2}}
  ]
];
assert[
  "Contribution-wise dimensionless coefficients reconstructed",
  And @@ MapThread[
    TrueQ @ FullSimplify[
      #1 == #2,
      Assumptions -> syntheticContext["DimensionlessAssumptions"]
    ] &,
    {
      syntheticContributionResult["DimensionlessExpressions"],
      {-yy, 1}
    }
  ]
];
assert[
  "Assembled and contribution-wise normalizations agree",
  AssociationQ[syntheticReassembledResult] &&
    SameQ[
      syntheticReassembledResult["DistributionFactor"],
      syntheticContributionResult["DistributionFactor"]
    ] &&
    SameQ[
      syntheticReassembledResult["LaurentValuation"],
      syntheticContributionResult["LaurentValuation"]
    ] &&
    And @@ MapThread[
      TrueQ @ FullSimplify[
        #1 == #2,
        Assumptions -> syntheticContext["PhysicalAssumptions"]
      ] &,
      {
        syntheticReassembledResult["Expressions"],
        syntheticContributionResult["Expressions"]
      }
    ] &&
    And @@ MapThread[
      TrueQ @ FullSimplify[
        #1 == #2,
        Assumptions -> syntheticContext["DimensionlessAssumptions"]
      ] &,
      {
        syntheticReassembledResult["DimensionlessExpressions"],
        syntheticContributionResult["DimensionlessExpressions"]
      }
    ]
];

epsilonScaleResult = SimplifyHardCoefficients[
  {
    distributionFactor (A + B)/(
      rhoA rhoB rhoH^2 Q2^(2 + Epsilon)
    )
  },
  syntheticCard
];
assert["Epsilon-dependent scale normalization", AssociationQ[epsilonScaleResult]];
assert[
  "Epsilon-dependent scale power",
  epsilonScaleResult["ScalePowers"] === {-1 - Epsilon}
];
assert[
  "Epsilon-dependent dimensionless coefficient",
  TrueQ @ FullSimplify[
    First[epsilonScaleResult["DimensionlessExpressions"]] ==
      -(xx + yy),
    Assumptions -> syntheticContext["DimensionlessAssumptions"]
  ]
];

Print["PROCESS_INDEPENDENT_SIMPLIFICATION_OK"];
Quit[0];
