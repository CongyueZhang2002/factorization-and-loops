If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file TwoSegmentRowSpaces.wls <observable> <spectator>"];
  Exit[2]
];

observable = Get[$ScriptCommandLine[[2]]];
spectator = Get[$ScriptCommandLine[[3]]];

nPhysical = Length[observable["PhysicalRows"]];
nBoundary = Length[observable["BoundaryCoordinates"]];
maxFirstWeight = observable["MaximumWeight"];
maxWeight = 5;

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];

RowBasis[m_] := Module[{rr, nonzero},
  If[Length[m] == 0, Return[{}]];
  rr = RowReduce[m];
  nonzero = Select[rr, Not[And @@ PossibleZeroQ /@ #] &];
  nonzero
];

CompressedRowUnion[matrices_, chunkSize_: 16] := Module[
  {basis = {}, nonempty = Select[matrices, Length[#] > 0 &]},
  Do[
    basis = RowBasis[Join[basis, Sequence @@ chunk]],
    {chunk, Partition[nonempty, UpTo[chunkSize]]}
  ];
  basis
];

observableMaps = Map[
  <|
    "Weight" -> #["Weight"],
    "Matrix" -> Normal@SparseFromEntries[
      #["Entries"], {nPhysical, nBoundary}
    ]
  |> &,
  observable["ObservableWordMaps"]
];

kernelMatrices = Normal@SparseFromEntries[#, spectator["Shape"]] & /@
  spectator["KernelMatrices"];

Print[{"physical rows", nPhysical, "boundary coordinates", nBoundary,
  "observable maps", Length[observableMaps], "kernels", Length[kernelMatrices]}];

firstPathBases = Association@Table[
  weight -> CompressedRowUnion[
    Cases[observableMaps,
      entry_ /; entry["Weight"] == weight :> entry["Matrix"]
    ]
  ],
  {weight, 0, maxFirstWeight}
];
Print["first path ranks: ", Map[Length, firstPathBases]];

spaces = Association[];
perSplit = Association[];
Do[
  spaces[{firstWeight, 0}] = firstPathBases[firstWeight];
  perSplit[{firstWeight, 0}] = Length[spaces[{firstWeight, 0}]];
  Do[
    spaces[{firstWeight, secondWeight}] = If[
      Length[spaces[{firstWeight, secondWeight - 1}]] == 0,
      {},
      CompressedRowUnion[
        (spaces[{firstWeight, secondWeight - 1}] . #) & /@ kernelMatrices
      ]
    ];
    perSplit[{firstWeight, secondWeight}] =
      Length[spaces[{firstWeight, secondWeight}]],
    {secondWeight, 1, maxWeight - firstWeight}
  ],
  {firstWeight, 0, maxFirstWeight}
];

cumulative = {};
rankByWeight = {};
cumulativeRanks = {};
Do[
  sameWeight = CompressedRowUnion[
    KeyValueMap[
      If[Total[#1] == totalWeight, #2, Nothing] &,
      spaces
    ]
  ];
  cumulative = CompressedRowUnion[{cumulative, sameWeight}];
  AppendTo[rankByWeight, Length[sameWeight]];
  AppendTo[cumulativeRanks, Length[cumulative]];
  Print[{"total weight", totalWeight, "rank", Length[sameWeight],
    "cumulative", Length[cumulative]}],
  {totalWeight, 0, maxWeight}
];

Print[<|
  "PerSplitRanks" -> perSplit,
  "RankByTotalWeight" -> rankByWeight,
  "CumulativeObservableBoundaryRank" -> cumulativeRanks
|>];
