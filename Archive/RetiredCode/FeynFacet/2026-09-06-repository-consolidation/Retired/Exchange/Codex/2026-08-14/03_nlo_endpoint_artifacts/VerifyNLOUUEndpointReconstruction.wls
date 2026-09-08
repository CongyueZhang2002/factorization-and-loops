$HistoryLength = 0;
$MaxExtraPrecision = 20000;

directory = "/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/NLOEndpoint";
input = Get[FileNameJoin[{directory, "NLOUUExactEndpointInput.wl"}]];
rawCoefficients = Get[FileNameJoin[{directory, "NLOUUEndpointCoefficients.wl"}]];
distribution = Get[FileNameJoin[{directory, "NLOUUEndpointDistributions.wl"}]];

If[! AssociationQ[distribution],
  Print["INVALID_DISTRIBUTION_RECORD"];
  Exit[1]
];

conversion = -I 2^(2 - 2 Epsilon) Pi^(-Epsilon);
hard = conversion input["EndpointExpression"] /. w -> 1 - rho;

exactCoefficientDifferences = AssociationMap[
  Function[a,
    FullSimplify[
      distribution["ExactCoefficients", a] -
        conversion rawCoefficients["EndpointPowers", a, "Coefficient"],
      Assumptions ->
        s > 0 && 0 < v < 1 && 0 < Epsilon < 1/2 &&
          Element[{s, v, Epsilon, CA, CF}, Reals]
    ]
  ],
  {1, 2}
];

parameters = {
  s -> SetPrecision[10, 250],
  v -> SetPrecision[2/5, 250],
  CA -> SetPrecision[3, 250],
  CF -> SetPrecision[4/3, 250],
  Epsilon -> SetPrecision[1/10, 250]
};
c1 = N[distribution["ExactCoefficients", 1] /. parameters, 200];
c2 = N[distribution["ExactCoefficients", 2] /. parameters, 200];

endpointRows = Table[
  Module[{rhoValue, value, a2Ratio, a1Ratio},
    rhoValue = SetPrecision[10^-power, 250];
    value = N[hard /. parameters /. rho -> rhoValue, 200];
    a2Ratio = N[rhoValue^(1 + 2/10) value/c2, 60];
    a1Ratio = N[
      rhoValue^(1 + 1/10) (value - c2 rhoValue^(-1 - 2/10))/c1,
      60
    ];
    <|"Power" -> power, "a2Ratio" -> a2Ratio, "a1Ratio" -> a1Ratio|>
  ],
  {power, {10, 20, 30, 40, 60, 80, 100}}
];

Print["RECORD_ASSOCIATION=", AssociationQ[distribution]];
Print["EXACT_COEFFICIENT_DIFFERENCES=", InputForm[exactCoefficientDifferences]];
Print["ENDPOINT_ROWS=", InputForm[endpointRows]];

result = <|
  "ExactCoefficientDifferences" -> exactCoefficientDifferences,
  "EndpointRows" -> endpointRows,
  "AcceptanceCriteria" -> <|
    "ExactCoefficientDifferences" -> "IdenticallyZero",
    "a2RatioAtSmallestRhoAbsoluteError" -> 10^-8,
    "a1RatioAtSmallestRhoAbsoluteError" -> 10^-5
  |>
|>;
Put[result, FileNameJoin[{directory, "NLOUUEndpointVerification.wl"}]];

If[
  AllTrue[Values[exactCoefficientDifferences], TrueQ[# === 0] &] &&
    Abs[endpointRows[[-1, "a2Ratio"]] - 1] < 10^-8 &&
    Abs[endpointRows[[-1, "a1Ratio"]] - 1] < 10^-5,
  Exit[0],
  Exit[1]
];
