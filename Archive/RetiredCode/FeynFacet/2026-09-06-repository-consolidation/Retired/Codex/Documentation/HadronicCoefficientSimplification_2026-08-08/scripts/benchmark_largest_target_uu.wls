facetRoot = "/home/maxzhang/FACET";
resultDirectory = FileNameJoin[{
  facetRoot, "ppHX_NLO", "Results", "UU_08_05_10x10_1"
}];
outputPath = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification",
  "UU_10x10", "LargestTargetStrategies.wl"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
kira = Get[FileNameJoin[{resultDirectory, "KiraResult.wl"}]];
records = Get /@ Sort @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{resultDirectory, "Pairs"}]
];
equivalenceRules = Lookup[kira["TopologyEquivalence"], "GLIRules", {}];

targetTerms = <||>;
Scan[
  Function[record,
    Module[{part},
      part = FeynFacet`Private`linearIntegralSum[record["Integrand"]];
      If[equivalenceRules =!= {},
        part = FeynFacet`Private`linearMapIntegrals[part, equivalenceRules]
      ];
      part = FeynFacet`Private`linearScale[part, record["PreFactor"]];
      KeyValueMap[
        Function[{integral, coefficient},
          AssociateTo[
            targetTerms,
            integral -> (Lookup[targetTerms, integral, 0] + coefficient)
          ]
        ],
        part["Terms"]
      ]
    ]
  ],
  records
];

inputs = FeynFacet`Private`applyHadronicVariables[
  Values[FeynFacet`Private`canonicalizeLinearTerms[targetTerms]] /.
    kira["DimensionRule"],
  hadronic
];
input = First @ MaximalBy[inputs, ByteCount];

termwise[expression_] := Total[
  Simplify[#1, Assumptions -> assumptions] & /@
    FeynFacet`Private`additiveTerms[expression]
];

whole[expression_] := Simplify[expression, Assumptions -> assumptions];

wholeFull[expression_] := FullSimplify[
  expression,
  Assumptions -> assumptions
];

signatureBlock[expression_] := Module[
  {factor, reduced},
  {factor, reduced} = FeynFacet`Private`structuralAdditiveFactor[expression];
  factor Cancel[Together[reduced]]
];

measure[name_String, function_] := Module[{elapsed, output, difference},
  {elapsed, output} = AbsoluteTiming[
    TimeConstrained[function[input], 120, Missing["TimeLimit"]]
  ];
  difference = If[
    MissingQ[output],
    Missing["NotChecked"],
    TimeConstrained[
      Simplify[output - input, Assumptions -> assumptions],
      60,
      Missing["TimeLimit"]
    ]
  ];
  result = <|
    "Strategy" -> name,
    "Seconds" -> elapsed,
    "InputBytes" -> ByteCount[input],
    "OutputBytes" -> If[MissingQ[output], Missing[], ByteCount[output]],
    "ExactDifference" -> difference,
    "Output" -> output
  |>;
  Print[InputForm[KeyDrop[result, "Output"]]];
  result
];

results = {
  measure["TermwiseSimplify", termwise],
  measure["WholeSimplify", whole],
  measure["WholeFullSimplify", wholeFull],
  measure["StructuralFactorThenTogetherCancel", signatureBlock]
};

Put[results, outputPath];
