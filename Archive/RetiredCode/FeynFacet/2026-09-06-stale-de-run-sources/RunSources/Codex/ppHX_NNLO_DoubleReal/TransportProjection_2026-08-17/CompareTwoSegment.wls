If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file CompareTwoSegment.wls <left> <right>"];
  Exit[2]
];

left = Get[$ScriptCommandLine[[2]]];
right = Get[$ScriptCommandLine[[3]]];
nRows = Length[left["PhysicalRows"]];
nColumns = Length[left["BoundaryCoordinates"]];

MapAssociation[record_] := Association@Map[
  Function[item,
    {item["FirstPathWord"], item["SpectatorPathWord"]} ->
      SparseArray[
        ({#[[1]], #[[2]]} -> #[[3]]) & /@ item["Entries"],
        {nRows, nColumns}
      ]
  ],
  record["ObservableMaps"]
];

leftMaps = MapAssociation[left];
rightMaps = MapAssociation[right];
sameKeys = Sort[Keys[leftMaps]] === Sort[Keys[rightMaps]];
residuals = If[sameKeys,
  KeyValueMap[
    Function[{key, matrix},
      Union[Flatten[Map[Together, Normal[matrix - rightMaps[key]], {2}]]]
    ],
    leftMaps
  ],
  {{Missing["DifferentKeys"]}}
];

Print[<|
  "SameKeys" -> sameKeys,
  "MapCount" -> Length[leftMaps],
  "ExactMatrixAgreement" -> And @@ (# === {0} & /@ residuals)
|>];
