$HistoryLength = 0;

root = "/home/maxzhang/FACET";
studyDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering"
}];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{studyDirectory, "Common.wl"}]];

physical = Get[FileNameJoin[{studyDirectory, "PhysicalTargets.wl"}]];
prepared = Get[FileNameJoin[{studyDirectory, "Prepared.wl"}]];
card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "TT.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
branchRules = prepared["BranchRules"];
expressions = ttPartExpressions[physical["Part"]];

historicalFunctionalBasis[value_] := DeleteDuplicates @ Join[
  Cases[value, _Beta*_Hypergeometric2F1, Infinity],
  Cases[value, _Beta, Infinity],
  Cases[value, _Hypergeometric2F1, Infinity]
];

historicalCollect[value_] := Simplify[
  Collect[
    value,
    historicalFunctionalBasis[value],
    Factor[Cancel[Together[#]]] &
  ],
  Assumptions -> assumptions
];

methods = <|
  "WholeTogether" -> Function[value,
    Factor[Cancel[Together[value]]]
  ],
  "WholeSimplify" -> Function[value,
    Simplify[value, Assumptions -> assumptions]
  ],
  "TogetherThenSimplify" -> Function[value,
    Simplify[
      Factor[Cancel[Together[value]]],
      Assumptions -> assumptions
    ]
  ],
  "SimplifyThenTogether" -> Function[value,
    Factor @ Cancel @ Together @ Simplify[
      value,
      Assumptions -> assumptions
    ]
  ],
  "HistoricalCollect" -> Function[value,
    historicalCollect[value]
  ],
  "TogetherThenHistoricalCollect" -> Function[value,
    historicalCollect[Factor[Cancel[Together[value]]]]
  ]
|>;

positions = {9, 6, 44, 80, 73};

measure[position_Integer, method_String] := Module[
  {canonical, seconds, outcome, equality},
  canonical = ttCanonicalCoefficient[
    expressions[[position]],
    branchRules
  ];
  {seconds, outcome} = AbsoluteTiming[
    TimeConstrained[methods[method][canonical], 180, $TimedOut]
  ];
  equality = If[
    MemberQ[{$TimedOut, $Failed}, outcome],
    Missing["NotAvailable"],
    TimeConstrained[
      TrueQ[Cancel[Together[outcome - canonical]] === 0],
      60,
      Missing["TimedOut"]
    ]
  ];
  <|
    "Position" -> position,
    "Method" -> method,
    "Seconds" -> seconds,
    "InputBytes" -> ByteCount[canonical],
    "OutputBytes" -> If[
      MemberQ[{$TimedOut, $Failed}, outcome], 0, ByteCount[outcome]
    ],
    "InputTerms" -> Length[ttAdditiveTerms[canonical]],
    "OutputTerms" -> If[
      MemberQ[{$TimedOut, $Failed}, outcome],
      0,
      Length[ttAdditiveTerms[outcome]]
    ],
    "RemainingFractionVariables" -> If[
      MemberQ[{$TimedOut, $Failed}, outcome],
      Missing["NotAvailable"],
      Select[{xa, xb, zh}, ! FreeQ[outcome, #] &]
    ],
    "ExactData" -> If[
      MemberQ[{$TimedOut, $Failed}, outcome],
      False,
      ttExactDataQ[outcome]
    ],
    "ExactEquality" -> equality,
    "TimedOut" -> (outcome === $TimedOut),
    "Failed" -> (outcome === $Failed)
  |>
];

results = Flatten @ Table[
  Print["Target ", position, ", ", method];
  result = measure[position, method];
  Print[InputForm[result]];
  result,
  {position, positions},
  {method, Keys[methods]}
];

Put[
  results,
  FileNameJoin[{studyDirectory, "TargetBenchmarkGrid.wl"}]
];
Quit[];
