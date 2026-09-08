$HistoryLength = 0;
Global`$FACETKernelLimit = 4;
root = "/home/maxzhang/FACET";
studyDirectory = FileNameJoin[{root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering"}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
commonFile = FileNameJoin[{studyDirectory, "Common.wl"}];
Get[loader];
Get[commonFile];
Clear[$PrePrint];

prepared = Get[FileNameJoin[{studyDirectory, "Prepared.wl"}]];
physical = Get[FileNameJoin[{studyDirectory, "PhysicalTargets.wl"}]];
cleaned = Get[FileNameJoin[{studyDirectory, "PhysicalTargetsRational.wl"}]];
targetPart = ttReplacePartExpressions[physical["Part"], cleaned["Expressions"]];
reduction = prepared["PhysicalReduction"];
hardMaster = GLI[TopologyF10C10N1, {1, 0, 0, 1}];
contributions = DeleteCases[
  KeyValueMap[
    Function[{target, targetCoefficient},
      targetCoefficient Lookup[reduction[target]["Terms"], hardMaster, 0]
    ],
    targetPart["Terms"]
  ],
  0
];

angularBasis = {
  Cos[\[Phi]a] Cos[\[Phi]h],
  Sin[\[Phi]a] Sin[\[Phi]h],
  Cos[\[Phi]a] Sin[\[Phi]h],
  Sin[\[Phi]a] Cos[\[Phi]h]
};
angularAtoms = {ttCosA, ttSinA, ttCosH, ttSinH};
splitAngular[expression_] := Module[{polynomial, coefficients, remainder},
  polynomial = TrigExpand[expression] /. Dispatch[{
    Cos[\[Phi]a] -> ttCosA,
    Sin[\[Phi]a] -> ttSinA,
    Cos[\[Phi]h] -> ttCosH,
    Sin[\[Phi]h] -> ttSinH
  }];
  coefficients = {
    Coefficient[Coefficient[polynomial, ttCosA], ttCosH],
    Coefficient[Coefficient[polynomial, ttSinA], ttSinH],
    Coefficient[Coefficient[polynomial, ttCosA], ttSinH],
    Coefficient[Coefficient[polynomial, ttSinA], ttCosH]
  };
  remainder = Expand[polynomial - Total[(angularBasis /. Dispatch[{
    Cos[\[Phi]a] -> ttCosA,
    Sin[\[Phi]a] -> ttSinA,
    Cos[\[Phi]h] -> ttCosH,
    Sin[\[Phi]h] -> ttSinH
  }]) coefficients]];
  If[! TrueQ[remainder === 0], Return[$Failed]];
  coefficients
];

splitContributions = splitAngular /@ contributions;
If[MemberQ[splitContributions, $Failed], Print["ANGULAR_SPLIT_FAILED"]; Quit[1]];
channels = MapThread[
  Function[{basis, index}, <|
    "Basis" -> basis,
    "Contributions" -> DeleteCases[splitContributions[[All, index]], 0]
  |>],
  {angularBasis, Range[Length[angularBasis]]}
];

balancedCertifiedMerge[expressions_List, timeLimit_] := Catch[
  Module[{level, pairs, next, seconds = 0., nodes = 0, timing, outcome, depth = 0},
    level = DeleteCases[expressions, 0];
    If[level === {}, Return[<|"Expression" -> 0, "Seconds" -> 0., "MergeNodes" -> 0, "Depth" -> 0|>]];
    While[Length[level] > 1,
      depth++;
      level = SortBy[level, ByteCount];
      pairs = Partition[level, UpTo[2]];
      next = Map[
        Function[pair,
          If[Length[pair] === 1,
            First[pair],
            timing = AbsoluteTiming[outcome = ttFrozenWholeRationalMerge[Total[pair], timeLimit]];
            seconds += First[timing];
            nodes++;
            If[MemberQ[{$TimedOut, $Failed}, outcome],
              Throw[<|"Failure" -> outcome, "Depth" -> depth, "MergeNodes" -> nodes, "Seconds" -> seconds,
                "PairBytes" -> (ByteCount /@ pair)|>]
            ];
            outcome
          ]
        ],
        pairs
      ];
      level = next
    ];
    <|"Expression" -> First[level], "Seconds" -> seconds, "MergeNodes" -> nodes, "Depth" -> depth|>
  ]
];

CloseKernels[];
kernels = LaunchKernels[2];
With[{load = loader, common = commonFile},
  ParallelEvaluate[
    $HistoryLength = 0;
    $LoadFeynArts = True;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
    Get[common];
    Clear[$PrePrint],
    kernels
  ]
];
DistributeDefinitions[balancedCertifiedMerge];
{wallSeconds, channelResults} = AbsoluteTiming[
  ParallelMap[
    Function[channel,
      merge = balancedCertifiedMerge[channel["Contributions"], 180];
      If[KeyExistsQ[merge, "Failure"],
        Join[KeyDrop[channel, "Contributions"], merge, <|"KernelID" -> $KernelID|>],
        Join[
          KeyDrop[channel, "Contributions"],
          KeyDrop[merge, "Expression"],
          <|
            "Expression" -> merge["Expression"],
            "InputBytes" -> Total[ByteCount /@ channel["Contributions"]],
            "OutputBytes" -> ByteCount[merge["Expression"]],
            "RemainingFractionVariables" -> Select[{xa, xb, zh}, ! FreeQ[merge["Expression"], #] &],
            "KernelID" -> $KernelID
          |>
        ]
      ]
    ],
    channels,
    Method -> "CoarsestGrained"
  ]
];
CloseKernels[kernels];

successful = AllTrue[channelResults, ! KeyExistsQ[#, "Failure"] &];
reconstructed = If[successful,
  Total[Lookup[channelResults, "Basis"] Lookup[channelResults, "Expression"]],
  $Failed
];
result = <|
  "Master" -> hardMaster,
  "ContributionCount" -> Length[contributions],
  "InputBytes" -> Total[ByteCount /@ contributions],
  "WallSeconds" -> wallSeconds,
  "Channels" -> Map[KeyDrop[#, "Expression"] &, channelResults],
  "Successful" -> successful,
  "FractionFree" -> If[successful, FreeQ[reconstructed, xa | xb | zh], False],
  "ExactData" -> If[successful, ttExactDataQ[reconstructed], False],
  "Expression" -> reconstructed
|>;
Put[result, FileNameJoin[{studyDirectory, "HardMasterAngular_01.wl"}]];
Print[ToString[InputForm[KeyDrop[result, "Expression"]]]];
Quit[];
