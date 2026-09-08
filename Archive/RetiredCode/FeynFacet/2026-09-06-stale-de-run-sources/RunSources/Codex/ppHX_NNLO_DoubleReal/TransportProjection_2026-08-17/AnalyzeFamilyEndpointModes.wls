If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file AnalyzeFamilyEndpointModes.wls <family-record>"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];
variables = record["Variables"];
epsilon = record["Regulator"];
dimension = record["Dim"];
baseFirst = If[record["Frame"] === "Chart", 1/2, 1/4];
ranges = record["Ranges"];

connection = Together[record["EpsFormY"]/epsilon /. variables[[1]] -> baseFirst];
residue = Map[
  Together[Limit[variables[[2]] #, variables[[2]] -> 0]] &,
  connection,
  {2}
];

blockData = MapIndexed[
  Function[{rows, index},
    block = residue[[rows, rows]];
    <|
      "Block" -> First[index],
      "Rows" -> rows,
      "Dimension" -> Length[rows],
      "CharacteristicPolynomial" ->
        Factor[CharacteristicPolynomial[block, lambda]],
      "Rank" -> MatrixRank[block]
    |>
  ],
  ranges
];

Print[<|
  "Family" -> record["Family"],
  "BaseCurve" -> {variables[[1]] -> baseFirst},
  "Endpoint" -> {variables[[2]] -> 0},
  "Dimension" -> dimension,
  "CharacteristicPolynomial" ->
    Factor[CharacteristicPolynomial[residue, lambda]],
  "Rank" -> MatrixRank[residue],
  "Blocks" -> blockData
|>];
