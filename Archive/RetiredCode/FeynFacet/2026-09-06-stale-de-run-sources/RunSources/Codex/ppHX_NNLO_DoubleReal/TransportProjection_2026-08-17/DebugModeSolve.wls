family = Get[$ScriptCommandLine[[2]]];
frobenius = Get[$ScriptCommandLine[[3]]];
dimension = family["Dim"];
residue = Normal@SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ frobenius["ResidueEntries"],
  {dimension, dimension}
];
canonicalRows = {6};
operator = residue;
seed = First[NullSpace[operator[[canonicalRows, canonicalRows]]]];
prefix = Range[Last[canonicalRows]];
target = ConstantArray[0, Length[prefix]];
target[[canonicalRows]] = seed;
basis = Transpose[NullSpace[operator]];
matrix = basis[[prefix, All]];
augmented = Join[matrix, List /@ target, 2];
reduced = RowReduce[augmented];
columnCount = Dimensions[matrix][[2]];
coefficientPart = reduced[[All, 1 ;; columnCount]];
rightHandSide = reduced[[All, -1]];
pivots = Table[
  Position[coefficientPart[[row]], Except[0], {1}, 1, Heads -> False],
  {row, Length[rightHandSide]}
];
solution = ConstantArray[0, columnCount];
Do[If[pivots[[row]] =!= {},
  solution[[First[First[pivots[[row]]]]]] = rightHandSide[[row]]],
  {row, Length[pivots]}];
zeroVectorQ[v_] := AllTrue[Flatten[v], Together[#] === 0 &];
Print[InputForm@<|
  "MatrixDimensions" -> Dimensions[matrix],
  "Ranks" -> {MatrixRank[matrix], MatrixRank[augmented]},
  "Seed" -> seed,
  "Pivots" -> pivots,
  "RightHandSide" -> rightHandSide,
  "Solution" -> solution,
  "Residual" -> Together[matrix.solution - target],
  "ZeroVectorQ" -> zeroVectorQ[Together[matrix.solution - target]]
|>];
