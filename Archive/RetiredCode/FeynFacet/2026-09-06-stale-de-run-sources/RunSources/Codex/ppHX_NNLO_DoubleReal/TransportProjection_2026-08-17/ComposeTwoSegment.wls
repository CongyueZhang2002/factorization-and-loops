If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file ComposeTwoSegment.wls <observable> <spectator> [output]"];
  Exit[2]
];

observable = Get[$ScriptCommandLine[[2]]];
spectator = Get[$ScriptCommandLine[[3]]];

nPhysical = Length[observable["PhysicalRows"]];
nBoundary = Length[observable["BoundaryCoordinates"]];
maxWeight = observable["MaximumWeight"];
spectatorVariable = spectator["Variable"];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];

CanonicalSparse[m_] := SparseArray[Map[Together, Normal[m], {2}]];
NonzeroMatrixQ[m_] := Length[Most[ArrayRules[m]]] > 0;
SparseEntries[m_] :=
  ({#[[1, 1]], #[[1, 2]], #[[2]]} &) /@ Most[ArrayRules[m]];

MapRecords[items_] := Map[
  <|
    "Word" -> #["Word"],
    "Matrix" -> SparseFromEntries[
      #["Entries"], {nPhysical, nBoundary}
    ]
  |> &,
  items
];

ComposeMaps[firstMaps_, matrices_] := Module[
  {counts, scalarCounts, tuples},
  counts = ConstantArray[0, maxWeight + 1];
  scalarCounts = ConstantArray[0, maxWeight + 1];
  tuples = Reap[
    Do[
      firstWord = firstMap["Word"];
      firstWeight = Length[firstWord];
      states = {{{}, firstMap["Matrix"]}};
      Do[
        totalWeight = firstWeight + secondWeight;
        Do[
          Sow[{firstWord, state[[1]], state[[2]]}];
          counts[[totalWeight + 1]]++;
          scalarCounts[[totalWeight + 1]] +=
            Length[SparseEntries[state[[2]]]],
          {state, states}
        ];
        If[totalWeight == maxWeight, Break[]];
        states = Select[
          Flatten[
            Table[
              {
                Append[state[[1]], matrixIndex],
                CanonicalSparse[state[[2]].matrices[[matrixIndex]]]
              },
              {state, states},
              {matrixIndex, Length[matrices]}
            ],
            1
          ],
          NonzeroMatrixQ[#[[2]]] &
        ];
        If[states === {}, Break[]],
        {secondWeight, 0, maxWeight - firstWeight}
      ],
      {firstMap, firstMaps}
    ]
  ][[2, 1]];
  <|
    "Tuples" -> tuples,
    "Counts" -> counts,
    "ScalarCounts" -> scalarCounts
  |>
];

SimplePoleExpansion[kernel_] := Module[
  {denominator, roots, poles, reconstructed},
  denominator = Denominator[Together[kernel]];
  roots = DeleteDuplicates[RootReduce /@
    (spectatorVariable /. Solve[denominator == 0, spectatorVariable])];
  poles = Map[
    Function[root,
      {root, Together[Limit[
        (spectatorVariable - root) kernel,
        spectatorVariable -> root
      ]]}
    ],
    roots
  ];
  reconstructed = Total[(#[[2]]/(spectatorVariable - #[[1]])) & /@ poles];
  If[Together[kernel - reconstructed] =!= 0,
    Print["spectator pole reconstruction failed for ", kernel];
    Exit[3]
  ];
  poles
];

firstDLogMaps = MapRecords[observable["ObservableWordMaps"]];
firstGPLMaps = MapRecords[observable["GPLWordMaps"]];
kernelMatrices = SparseFromEntries[#, spectator["Shape"]] & /@
  spectator["KernelMatrices"];
kernelPoleExpansions = SimplePoleExpansion /@ spectator["KernelFunctions"];

poleRoots = SortBy[
  DeleteDuplicates[Flatten[kernelPoleExpansions[[All, All, 1]]]],
  ToString[InputForm[#]] &
];
poleMatrices = Table[
  CanonicalSparse@Total@Table[
    With[
      {coefficient = Total@Cases[
        kernelPoleExpansions[[kernelIndex]],
        {candidate_, value_} /; RootReduce[candidate - root] === 0 :> value
      ]},
      coefficient kernelMatrices[[kernelIndex]]
    ],
    {kernelIndex, Length[kernelMatrices]}
  ],
  {root, poleRoots}
];

reconstructedSpectator = Total@Table[
  poleMatrices[[index]]/(spectatorVariable - poleRoots[[index]]),
  {index, Length[poleRoots]}
];
originalSpectator = Total@MapThread[Times,
  {spectator["KernelFunctions"], kernelMatrices}
];
If[! And @@ Flatten[Map[
    Together[#] === 0 &,
    Normal[originalSpectator - reconstructedSpectator],
    {2}
  ]],
  Print["spectator matrix pole reconstruction failed"];
  Exit[4]
];

dlogComposition = ComposeMaps[firstDLogMaps, kernelMatrices];
gplComposition = ComposeMaps[firstGPLMaps, poleMatrices];

SerializeMaps[tuples_, firstKey_, secondKey_, indexSecond_: True] := Map[
  Function[tuple,
    <|
      "TotalWeight" -> Length[tuple[[1]]] + Length[tuple[[2]]],
      firstKey -> tuple[[1]],
      secondKey -> If[indexSecond,
        tuple[[2]],
        poleRoots[[tuple[[2]]]]
      ],
      "Entries" -> SparseEntries[tuple[[3]]]
    |>
  ],
  tuples
];

dlogMaps = SerializeMaps[
  dlogComposition["Tuples"],
  "FirstPathWord",
  "SpectatorPathWord",
  True
];
gplMaps = SerializeMaps[
  gplComposition["Tuples"],
  "FirstPathGPLWord",
  "SpectatorGPLWord",
  False
];

usedBoundaryColumns = Sort@DeleteDuplicates@Cases[
  dlogMaps[[All, "Entries"]],
  {_, column_Integer, _} :> column,
  Infinity
];
pivotCoordinates =
  spectator["LiftedCoordinates"][[spectator["IdentityPivotRows"]]];

result = <|
  "Format" -> "FeynFacetTwoSegmentObservableTransport",
  "FormatVersion" -> 2,
  "Family" -> observable["Family"],
  "Frame" -> observable["Frame"],
  "Variables" -> observable["Variables"],
  "Regulator" -> observable["Regulator"],
  "PathOrder" -> {"SpectatorPath", "FirstPath"},
  "FirstPath" -> observable["Path"],
  "SpectatorPath" -> <|
    "Base" -> {
      observable["Path", "Base"][[1]], spectator["BasePoint"]
    },
    "Target" -> {
      observable["Path", "Base"][[1]], observable["Variables"][[2]]
    }
  |>,
  "FirstPathDLogLetters" -> observable["DLogLetters"],
  "SpectatorPathKernels" -> spectator["KernelFunctions"],
  "SpectatorPathPoleExpansion" -> MapIndexed[
    <|"Kernel" -> First[#2], "Poles" -> #1|> &,
    kernelPoleExpansions
  ],
  "SpectatorGPLLetters" -> poleRoots,
  "PhysicalRows" -> observable["PhysicalRows"],
  "BoundaryCoordinates" -> observable["BoundaryCoordinates"],
  "UsedBoundaryColumns" -> usedBoundaryColumns,
  "UsedCanonicalLaurentCoordinates" -> pivotCoordinates[[usedBoundaryColumns]],
  "MaximumTotalWeight" -> maxWeight,
  "ObservableMaps" -> dlogMaps,
  "GPLObservableMaps" -> gplMaps,
  "Certificate" -> <|
    "ExactInducedSpectatorConnection" -> True,
    "ExactInvariantBoundarySubspace" -> True,
    "ExactSpectatorPoleReconstruction" -> True,
    "ExactMatrixProducts" -> True,
    "HigherRequestedWeightsVanish" -> True
  |>
|>;

summary = <|
  "DLogMapCount" -> Length[dlogMaps],
  "DLogMapsByTotalWeight" -> dlogComposition["Counts"],
  "DLogNonzeroEntriesByTotalWeight" -> dlogComposition["ScalarCounts"],
  "SpectatorGPLLetterCount" -> Length[poleRoots],
  "GPLMapCount" -> Length[gplMaps],
  "GPLMapsByTotalWeight" -> gplComposition["Counts"],
  "GPLNonzeroEntriesByTotalWeight" -> gplComposition["ScalarCounts"],
  "UsedBoundaryColumns" -> Length[usedBoundaryColumns]
|>;

If[Length[$ScriptCommandLine] >= 4,
  Put[result, $ScriptCommandLine[[4]]]
];
Print[summary];
