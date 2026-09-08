If[Length[$ScriptCommandLine] < 4,
  Print["usage: wolframscript -file ValidateTwoSegmentRecurrence.wls <transport> <observable> <spectator>"];
  Exit[2]
];

transport = Get[$ScriptCommandLine[[2]]];
observable = Get[$ScriptCommandLine[[3]]];
spectator = Get[$ScriptCommandLine[[4]]];
nRows = Length[transport["PhysicalRows"]];
nColumns = Length[transport["BoundaryCoordinates"]];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];
ZeroMatrixQ[m_] := Union[Flatten[Map[Together, Normal[m], {2}]]] === {0};

firstMaps = Association@Map[
  Function[item,
    item["Word"] -> SparseFromEntries[
      item["Entries"], {nRows, nColumns}
    ]
  ],
  observable["ObservableWordMaps"]
];
kernelMatrices = SparseFromEntries[#, spectator["Shape"]] & /@
  spectator["KernelMatrices"];
maps = Association@Map[
  Function[item,
    {item["FirstPathWord"], item["SpectatorPathWord"]} ->
      SparseFromEntries[item["Entries"], {nRows, nColumns}]
  ],
  transport["ObservableMaps"]
];

initialChecks = KeyValueMap[
  Function[{firstWord, matrix},
    KeyExistsQ[maps, {firstWord, {}}] &&
      ZeroMatrixQ[maps[{firstWord, {}}] - matrix]
  ],
  firstMaps
];

recurrenceChecks = KeyValueMap[
  Function[{key, matrix},
    Module[{firstWord = key[[1]], secondWord = key[[2]], parent, kernel},
      If[secondWord === {},
        True,
        parent = {firstWord, Most[secondWord]};
        kernel = Last[secondWord];
        KeyExistsQ[maps, parent] &&
          ZeroMatrixQ[matrix - maps[parent].kernelMatrices[[kernel]]]
      ]
    ]
  ],
  maps
];

Print[<|
  "InitialMapCount" -> Length[initialChecks],
  "InitialMapsExact" -> And @@ initialChecks,
  "RecurrenceMapCount" -> Length[recurrenceChecks],
  "SpectatorRecurrenceExact" -> And @@ recurrenceChecks
|>];
