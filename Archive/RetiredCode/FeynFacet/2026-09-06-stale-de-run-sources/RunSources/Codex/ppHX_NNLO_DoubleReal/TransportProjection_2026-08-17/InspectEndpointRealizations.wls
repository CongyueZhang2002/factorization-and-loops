ClearAll[gli];

root = "/home/maxzhang/factorization-and-loops";
deDir = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations"}];

spec = <|
  "CF299" -> {7, 8, 10, 11, 14},
  "CF300" -> {3, 4, 5, 23, 24},
  "CF388" -> {1},
  "CF407" -> {21},
  "CF267" -> Range[1, 30]
|>;

Do[
  data = Get[FileNameJoin[{deDir, "nnlo_de_" <> family <> ".wl"}]];
  basis = data["BlockBasis"];
  rows = Select[spec[family], 1 <= # <= Length[basis] &];
  Print[family, " basis length = ", Length[basis]];
  Scan[Print["  row ", #, ": ", InputForm[basis[[#]]]] &, rows],
  {family, Keys[spec]}
];
