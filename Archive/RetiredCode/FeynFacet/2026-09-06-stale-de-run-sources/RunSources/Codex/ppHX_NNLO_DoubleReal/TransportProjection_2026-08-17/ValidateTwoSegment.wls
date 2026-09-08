If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file ValidateTwoSegment.wls <transport> <spectator>"];
  Exit[2]
];

transport = Get[$ScriptCommandLine[[2]]];
spectator = Get[$ScriptCommandLine[[3]]];

Print[<|
  "TransportAssociation" -> AssociationQ[transport],
  "MapCount" -> Length[transport["ObservableMaps"]],
  "MapsByWeight" -> Counts[transport["ObservableMaps"][[All, "TotalWeight"]]],
  "SpectatorAssociation" -> AssociationQ[spectator],
  "BoundaryEmbeddingShape" -> spectator["BoundaryEmbeddingShape"],
  "BoundaryEmbeddingNonzeroEntries" ->
    Length[spectator["BoundaryEmbeddingEntries"]],
  "UsedBoundaryColumns" -> Length@DeleteDuplicates@Cases[
    transport["ObservableMaps"][[All, "Entries"]],
    {_, column_Integer, _} :> column,
    Infinity
  ],
  "ExactCertificates" -> And @@ Values[transport["Certificate"]]
|>];
