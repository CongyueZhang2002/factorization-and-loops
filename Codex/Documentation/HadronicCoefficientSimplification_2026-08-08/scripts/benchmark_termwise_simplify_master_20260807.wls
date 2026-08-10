$HistoryLength = 0;
$LoadFeynArts = True;
$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
work = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "CoefficientSimplification",
  "UU_08_05_1"
}];
validation = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Validation"
}];
input = FileNameJoin[{work, "MasterRecords", "Master_0008.bin"}];
current = FileNameJoin[{work, "FinalMasters", "Master_0008.bin"}];
output = FileNameJoin[{validation, "Master_0008_TermwiseSimplify.bin"}];
summaryFile = FileNameJoin[{
  validation, "Master_0008_TermwiseSimplifySummary.wl"
}];
pair = First @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{
    root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_05_1", "Pairs"
  }]
];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
assumptions = Get[pair]["AnalyticContext", "Assumptions"];
expression = FeynFacet`Private`coefficientBalancedRecordTotal[input];
If[expression === $Failed, Exit[2]];
terms = FeynFacet`Private`additiveTerms[expression];

CloseKernels[];
LaunchKernels[8];
ParallelEvaluate[
  $HistoryLength = 0;
  $LoadFeynArts = True;
  Block[{$Output = {}, $Messages = {}},
    Quiet @ Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"]
  ];
];
DistributeDefinitions[assumptions];

{seconds, outcomes} = AbsoluteTiming[
  ParallelMap[
    Function[term,
      TimeConstrained[
        {Quiet @ Simplify[term, Assumptions -> assumptions], False},
        300,
        {term, True}
      ]
    ],
    terms,
    Method -> "FinestGrained"
  ]
];
CloseKernels[];

result = Total[First /@ outcomes];
parts = FeynFacet`Private`structuralAdditiveFactor[result];
record = <|
  "PreFactor" -> First[parts],
  "Coefficient" -> Last[parts]
|>;
FeynFacet`Private`coefficientWriteRecord[output, record];

summary = <|
  "MasterIndex" -> 8,
  "KernelCount" -> 8,
  "TermCount" -> Length[terms],
  "TimedOutTerms" -> Count[Last /@ outcomes, True],
  "Seconds" -> seconds,
  "InputBytes" -> FileByteCount[input],
  "CurrentOutputBytes" -> FileByteCount[current],
  "TermwiseSimplifyOutputBytes" -> FileByteCount[output],
  "ExactData" -> FeynFacet`Private`exactDataQ[record]
|>;
Put[summary, summaryFile];
Print[InputForm[summary]];
