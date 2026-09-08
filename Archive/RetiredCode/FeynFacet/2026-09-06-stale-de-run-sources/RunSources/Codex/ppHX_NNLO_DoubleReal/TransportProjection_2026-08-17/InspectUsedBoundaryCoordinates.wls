If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file InspectUsedBoundaryCoordinates.wls <transport> <spectator>"];
  Exit[2]
];

transport = Get[$ScriptCommandLine[[2]]];
spectator = Get[$ScriptCommandLine[[3]]];
used = Sort@DeleteDuplicates@Cases[
  transport["ObservableMaps"][[All, "Entries"]],
  {_, column_Integer, _} :> column,
  Infinity
];
pivotCoordinates =
  spectator["LiftedCoordinates"][[spectator["IdentityPivotRows"]]];

Print[<|
  "Family" -> transport["Family"],
  "UsedColumnCount" -> Length[used],
  "UsedColumns" -> used,
  "UsedCanonicalLaurentCoordinates" -> pivotCoordinates[[used]],
  "Orders" -> Counts[pivotCoordinates[[used, 1]]]
|>];
