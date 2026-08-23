If[Length[$ScriptCommandLine] < 5,
  Print["usage: wolframscript -file BuildObservableBoundarySubstitution.wls <spectator-system> <transport> <mode-map> <output>"];
  Exit[2]
];

spectator = Get[$ScriptCommandLine[[2]]];
transport = Get[$ScriptCommandLine[[3]]];
modeMap = Get[$ScriptCommandLine[[4]]];
outputFile = $ScriptCommandLine[[5]];

If[Length[DeleteDuplicates[{
      spectator["Family"], transport["Family"], modeMap["Family"]
    }]] =!= 1,
  Print["family names disagree"];
  Exit[3]
];

epsilon = transport["Regulator"];
labels = transport["BoundaryCoordinates"];
coordinateSlots =
  spectator["LiftedCoordinates"][[spectator["IdentityPivotRows"]]];
nCoordinates = Length[labels];
dimension = Max[spectator["LiftedCoordinates"][[All, 2]]];

If[Length[coordinateSlots] =!= nCoordinates,
  Print["boundary-coordinate dimensions disagree"];
  Exit[4]
];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];
VectorFromEntries[entries_] := SparseArray[
  (#[[1]] -> #[[2]]) & /@ entries,
  dimension
];
SparseEntries[m_] :=
  ({#[[1, 1]], #[[1, 2]], #[[2]]} &) /@
    Most[ArrayRules[SparseArray[m]]];
ExactZeroQ[expr_] := And @@ (Together[#] === 0 & /@ Flatten[expr]);
KnownZeroQ[mode_] :=
  KeyExistsQ[mode, "KnownCoefficient"] &&
    mode["KnownCoefficient"] === 0;

embedding = SparseFromEntries[
  spectator["BoundaryEmbeddingEntries"],
  spectator["BoundaryEmbeddingShape"]
];
identityAtPivots = Normal[embedding[[spectator["IdentityPivotRows"], All]]];
If[identityAtPivots =!= IdentityMatrix[nCoordinates],
  Print["identity-pivot certificate is false"];
  Exit[5]
];

activeModes = Select[
  modeMap["Modes"],
  #1["Status"] === "Exact" && ! KnownZeroQ[#1] &
];
If[! AllTrue[activeModes,
    #1["LocalEigenvalue"] === 0 && #1["GeneralizedLevel"] === 0 &],
  Print["the current exact endpoint substitution requires ordinary zero modes"];
  Exit[6]
];

modeVectors = Association@Map[
  #1["PeriodID"] -> Normal@VectorFromEntries[
      #1["CanonicalModeEntries"]
    ] &,
  activeModes
];

CoordinateContribution[{order_, row_}] := Total@Map[
  Function[mode,
    With[{coefficient = modeVectors[mode["PeriodID"]][[row]]},
      If[Together[coefficient] === 0,
        0,
        Inactive[SeriesCoefficient][
          coefficient BoundaryPeriod[mode["PeriodID"], epsilon],
          {epsilon, 0, order}
        ]
      ]
    ]
  ],
  activeModes
];

coordinateVector = CoordinateContribution /@ coordinateSlots;
mappedIndices = Flatten@Position[
  coordinateVector,
  value_ /; value =!= 0,
  {1},
  Heads -> False
];
mappedRules = Thread[labels[[mappedIndices]] ->
  coordinateVector[[mappedIndices]]];

MapRecord[item_] := Module[{matrix, values, entries},
  matrix = SparseFromEntries[
    item["Entries"],
    {Length[transport["PhysicalRows"]], nCoordinates}
  ];
  values = matrix.coordinateVector;
  entries = Cases[
    MapIndexed[{transport["PhysicalRows"][[First[#2]]], #1} &, values],
    {row_, value_} /; value =!= 0 :> {row, value}
  ];
  If[entries === {}, Nothing,
    Join[KeyDrop[item, "Entries"], <|"PhysicalEntries" -> entries|>]
  ]
];

periodObservableMaps = MapRecord /@ transport["GPLObservableMaps"];
usedPeriodIDs = activeModes[[All, "PeriodID"]];

result = <|
  "Format" -> "FeynFacetObservableBoundarySubstitution",
  "FormatVersion" -> 1,
  "Family" -> transport["Family"],
  "Regulator" -> epsilon,
  "PhysicalEndpointRelation" -> modeMap["PhysicalEndpointRelation"],
  "BoundaryCoordinateSlots" -> coordinateSlots,
  "MappedCoordinateRules" -> mappedRules,
  "UnmappedCoordinates" -> Delete[labels, List /@ mappedIndices],
  "BoundaryPeriodGeneratingVectors" -> Association@Map[
    #1["PeriodID"] -> <|
      "CanonicalModeEntries" -> #1["CanonicalModeEntries"],
      "GeneratingFunction" ->
        BoundaryPeriod[#1["PeriodID"], epsilon]
    |> &,
    activeModes
  ],
  "KnownZeroPeriodIDs" -> Cases[
    modeMap["Modes"], mode_ /; KnownZeroQ[mode] :> mode["PeriodID"]
  ],
  "UnresolvedPeriodIDs" -> usedPeriodIDs,
  "PeriodObservableGPLMaps" -> periodObservableMaps,
  "Certificate" -> <|
    "IdentityPivotRowsExact" -> True,
    "OrdinaryZeroModesOnly" -> True,
    "ExactLaurentCoefficientGeneratingFunctions" -> True,
    "PartialBoundaryMap" ->
      (Length[mappedIndices] < nCoordinates)
  |>
|>;

Put[result, outputFile];
Print[<|
  "Family" -> transport["Family"],
  "ActivePeriodIDs" -> usedPeriodIDs,
  "KnownZeroPeriodIDs" -> result["KnownZeroPeriodIDs"],
  "MappedBoundaryCoordinates" -> Length[mappedIndices],
  "TotalBoundaryCoordinates" -> nCoordinates,
  "NonzeroGPLMaps" -> Length[periodObservableMaps]
|>];
