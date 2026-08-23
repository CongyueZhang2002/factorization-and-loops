statePath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_state_CF254_standard.wl";
rangesPath =
  "/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819/" <>
    "family_epsform_CF254.wl";

state = Get[statePath];
rangesArtifact = Get[rangesPath];
{x, y, epsilon} = Symbol["Global`" <> #] & /@ {"x", "y", "eps"};

If[state["Sector"] =!= 8,
  Print["Expected the exact sector-8 CF254 state, found sector ",
    state["Sector"]];
  Exit[1]
];
If[Dimensions[state["S"]] =!= {23, 23} ||
    Dimensions /@ state["A"] =!= {{23, 23}, {23, 23}},
  Print["Unexpected CF254 state dimensions."];
  Exit[1]
];

ranges = rangesArtifact["Ranges"];
If[ranges =!= {{1}, {2}, {3}, {4, 5}, {6, 7}, {8},
    {9, 10, 11, 12}, {13, 14}, {15, 16, 17, 18}, {19},
    {20, 21, 22}, {23}},
  Print["Unexpected CF254 sector ranges: ", ranges];
  Exit[1]
];

If[! KeyExistsQ[state, "OriginalA"],
  {inverseSeconds, sInverse} = AbsoluteTiming[Together[Inverse[state["S"]]]];
  {reconstructionSeconds, originalA} = AbsoluteTiming[
    Table[
      Map[Together,
        state["S"] . state["A"][[mu]] . sInverse +
          D[state["S"], {x, y}[[mu]]] . sInverse,
        {2}
      ],
      {mu, 2}
    ]
  ];
  state["OriginalA"] = originalA;
  state["Ranges"] = ranges;
  state["OriginalAReconstruction"] = <|
    "FromSector" -> state["Sector"],
    "InverseSeconds" -> inverseSeconds,
    "ReconstructionSeconds" -> reconstructionSeconds
  |>;
  temporaryPath = statePath <> ".tmp";
  Put[state, temporaryPath];
  RenameFile[temporaryPath, statePath, OverwriteTarget -> True],
  Print["The cached original connection already exists."]
];

Print[<|
  "State" -> statePath,
  "Sector" -> state["Sector"],
  "Ranges" -> state["Ranges"],
  "OriginalADimensions" -> Dimensions /@ state["OriginalA"],
  "Reconstruction" -> state["OriginalAReconstruction"]
|>];
