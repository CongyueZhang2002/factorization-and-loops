$HistoryLength = 0;
$LoadFeynArts = True;

root = "/home/maxzhang/FACET";
sampleFile = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Scratch",
  "Legacy_2026-08-06", "largest_nnlo_target_coefficient.wl"
}];
outputFile = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Validation",
  "ExactNormalizerBenchmark_20260807.wl"
}];

If[FileExistsQ[outputFile],
  Print["Refusing to overwrite the exact-normalizer benchmark."];
  Exit[1]
];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
expression = Get[sampleFile];
assumptions = True;

methods = <|
  "Simplify" -> Function[value,
    Simplify[value, Assumptions -> assumptions]
  ],
  "TermwiseSimplify" -> Function[value,
    Total[
      Simplify[#1, Assumptions -> assumptions] & /@
        FeynFacet`Private`additiveTerms[value]
    ]
  ],
  "CancelTogether" -> Function[value, Cancel[Together[value]]],
  "FactorTermsCancelTogether" -> Function[value,
    FactorTerms[Cancel[Together[value]]]
  ]
|>;

results = Association @ KeyValueMap[
  Function[{name, method}, Module[{seconds, value},
    {seconds, value} = AbsoluteTiming[
      TimeConstrained[method[expression], 120, $Aborted]
    ];
    name -> <|
      "Seconds" -> seconds,
      "Result" -> value,
      "Bytes" -> If[value === $Aborted, Missing["Aborted"], ByteCount[value]],
      "ExactData" -> If[
        value === $Aborted,
        False,
        FeynFacet`Private`exactDataQ[value]
      ]
    |>
  ]],
  methods
];
reference = results["Simplify", "Result"];
results = Association @ KeyValueMap[
  Function[{name, item},
    name -> Join[
      KeyDrop[item, "Result"],
      <|"ExactDifferenceZero" -> If[
        item["Result"] === $Aborted || reference === $Aborted,
        False,
        TrueQ[Cancel[Together[item["Result"] - reference]] === 0]
      ]|>
    ]
  ],
  results
];
Put[results, outputFile];
Print[InputForm[results]];
Exit[0];
