If[Length[$ScriptCommandLine] < 2,
  Print["Usage: wolframscript -file inspect_gauge_sample.wls sample.wl"];
  Exit[2]
];

result = Get[$ScriptCommandLine[[2]]];
particular = result["ParticularSolution"];
nullspace = result["NullspaceBasis"];

Print[<|
  "EpsilonValue" -> result["EpsilonValue"],
  "Prime" -> result["Prime"],
  "ParticularLength" -> Length[particular],
  "ParticularNonzero" -> Count[particular, Except[0]],
  "GaugeNonzero" -> Count[Take[particular, 1408], Except[0]],
  "ResidueValues" -> Take[particular, -17],
  "NullspaceDimensions" -> Dimensions[nullspace],
  "NullspaceNonzeroByVector" -> (Count[#, Except[0]] & /@ nullspace)
|>];

