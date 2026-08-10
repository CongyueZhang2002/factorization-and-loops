facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];
resultDirectory = FileNameJoin[{
  facetRoot, "ppHX_NLO", "Results", "UU_08_05_10x10_1"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
kira = Get[FileNameJoin[{resultDirectory, "KiraResult.wl"}]];
records = Get /@ Sort @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{resultDirectory, "Pairs"}]
];
radicalTest = Get[FileNameJoin[{
  workDirectory, "RadicalNormalizationTest.wl"
}]];
equivalenceRules = Lookup[kira["TopologyEquivalence"], "GLIRules", {}];

physicalFactor =
  FeynFacet`\[Alpha]s^3*FeynFacet`D1[zh]*FeynFacet`f1[xa]*
    FeynFacet`f1[xb]/(xa*xb*zh^2);

mergeLinearParts[parts_List] := Module[{terms = <||>, remainder = 0},
  Scan[
    Function[part,
      KeyValueMap[
        Function[{integral, coefficient},
          AssociateTo[
            terms,
            integral -> (Lookup[terms, integral, 0] + coefficient)
          ]
        ],
        part["Terms"]
      ];
      remainder += Lookup[part, "Remainder", 0]
    ],
    parts
  ];
  <|
    "Terms" -> FeynFacet`Private`canonicalizeLinearTerms[terms],
    "Remainder" -> remainder
  |>
];

pairParts = Map[
  Function[record,
    Module[{part},
      part = FeynFacet`Private`linearIntegralSum[record["Integrand"]];
      If[equivalenceRules =!= {},
        part = FeynFacet`Private`linearMapIntegrals[part, equivalenceRules]
      ];
      FeynFacet`Private`linearScale[part, record["PreFactor"]]
    ]
  ],
  records
];
rawTargets = mergeLinearParts[pairParts];
targetInput = FeynFacet`Private`applyHadronicVariables[
  Append[Values[rawTargets["Terms"]], rawTargets["Remainder"]] /.
    kira["DimensionRule"],
  hadronic
];

{targetSeconds, normalized} = AbsoluteTiming[
  FeynFacet`Private`parallelNormalizeCoefficients[
    targetInput,
    assumptions,
    60
  ]
];
targetExpressions = First[normalized];

stripTarget[expression_] := TimeConstrained[
  Total[
    Simplify[
      (# /. Dispatch[radicalTest["Rules"]])/physicalFactor,
      Assumptions -> assumptions
    ] & /@ FeynFacet`Private`additiveTerms[expression]
  ],
  60,
  Missing["TimeLimit"]
];

LaunchKernels[4];
DistributeDefinitions[
  stripTarget, physicalFactor, radicalTest, assumptions
];
{stripSeconds, stripped} = AbsoluteTiming[
  ParallelMap[stripTarget, targetExpressions, Method -> "FinestGrained"]
];
CloseKernels[];

fractionFree = FreeQ[#, Alternatives[xa, xb, zh]] & /@ stripped;
result = <|
  "TargetCount" -> Length[rawTargets["Terms"]],
  "TargetSimplificationSeconds" -> targetSeconds,
  "FactorExtractionSeconds" -> stripSeconds,
  "InputBytes" -> ByteCount[targetExpressions],
  "OutputBytes" -> Total[ByteCount /@ DeleteMissing[stripped]],
  "TimedOut" -> Count[stripped, _Missing],
  "FractionFreeCount" -> Count[fractionFree, True],
  "NonFractionFreePositions" -> Flatten @ Position[
    fractionFree,
    Except[True],
    {1},
    Heads -> False
  ],
  "PhysicalFactor" -> physicalFactor,
  "TargetKeys" -> Append[Keys[rawTargets["Terms"]], "Remainder"],
  "Stripped" -> stripped
|>;

Put[result, FileNameJoin[{
  workDirectory, "TargetFactorizationTest.wl"
}]];
Clear[$PrePrint];
Print[InputForm[KeyDrop[result, "Stripped"]]];
