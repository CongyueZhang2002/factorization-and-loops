directory = DirectoryName[$InputFileName];
candidate = Get[FileNameJoin[{directory,
    "CF254_9_8_lifted_candidate.wl"}]];
check = Get[FileNameJoin[{directory,
    "CF254_9_8_lifted_exact_check.wl"}]];

If[! TrueQ[check["AllResidualsZero"]],
  Print["The CF254 (9,8) gauge has no complete exact certificate."];
  Exit[1]
];

gauge = candidate["Gauge"];
If[Dimensions[gauge] =!= {4, 2},
  Print["Unexpected gauge dimensions: ", Dimensions[gauge]];
  Exit[1]
];

checkpoint = <|
  "Sector" -> 9,
  "SubSize" -> 4,
  "Truncation" -> 18,
  "PrevD" -> gauge,
  "StripSolvers" -> {
    <|
      "Sector" -> 9,
      "LowerSector" -> 8,
      "Method" -> "SimultaneousFiniteFieldAffinePDE",
      "NumeratorDegree" -> {10, 10},
      "DenominatorDegree" -> {10, 10},
      "ExactDLog" -> True,
      "TwoVariableResidualZero" -> True,
      "FiniteFieldPrimes" -> candidate["Primes"]
    |>
  }
|>;

checkpointPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_strip_state.wl";
temporaryPath = checkpointPath <> ".tmp";
Put[checkpoint, temporaryPath];
RenameFile[temporaryPath, checkpointPath, OverwriteTarget -> True];
Print[<|"Checkpoint" -> checkpointPath,
  "GaugeDimensions" -> Dimensions[gauge],
  "ExactResidualsZero" -> check["AllResidualsZero"]|>];
