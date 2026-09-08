root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

assumptions = a > 0;
expression =
  (a^2 - 1)/(a - 1) GLI[testTopology, {1}] +
  (2 a + 2) GLI[testTopology, {1}] +
  (b - b) GLI[vanishingTopology, {1}];

result = Collect2[
  expression,
  GLI,
  Factoring -> (SimplifyAssum[#, assumptions] &)
];

check = TrueQ[
  Collect2[
    result - 3 (a + 1) GLI[testTopology, {1}],
    GLI,
    Factoring -> Together
  ] === 0
];

Print[<|"MasterCoefficientsSimplified" -> check|>];
If[! check, Exit[1]];
Exit[0];
