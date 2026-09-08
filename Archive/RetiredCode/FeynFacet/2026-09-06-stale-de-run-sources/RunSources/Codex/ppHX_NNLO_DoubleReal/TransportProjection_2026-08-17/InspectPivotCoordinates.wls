Do[
  record = Get["SpectatorSystem_" <> family <> ".wl"];
  coordinates =
    record["LiftedCoordinates"][[record["IdentityPivotRows"]]];
  Print[<|
    "Family" -> family,
    "Orders" -> Counts[coordinates[[All, 1]]],
    "Coordinates" -> coordinates
  |>],
  {family, Drop[$ScriptCommandLine, 1]}
];
