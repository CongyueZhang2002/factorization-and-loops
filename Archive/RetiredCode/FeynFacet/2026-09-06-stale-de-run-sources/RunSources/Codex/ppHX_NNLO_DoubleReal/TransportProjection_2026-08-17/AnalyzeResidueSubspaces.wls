#!/usr/bin/env wolframscript

ClearAll["Global`*"];
$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
dataDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical"}];

family = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "CF299"];
maxWeight = If[Length[$ScriptCommandLine] >= 3,
  ToExpression[$ScriptCommandLine[[3]]], 5];
seedSelection = If[Length[$ScriptCommandLine] >= 4,
  Flatten[{ToExpression[$ScriptCommandLine[[4]]]}], All];

record = Get[FileNameJoin[{dataDirectory, "FamilyEpsForms",
     "family_epsform_" <> family <> ".wl"}]];
de = Get[FileNameJoin[{dataDirectory, "DifferentialEquations",
     "nnlo_de_" <> family <> ".wl"}]];
valuations = Get[FileNameJoin[{dataDirectory, "MasterCoefficientValuations.wl"}]];

If[! AssociationQ[record] || ! TrueQ[record["GateVerdict"]],
  Print[family, ": exact epsilon-form record is unavailable"];
  Exit[2]
];

variables = record["Variables"];
regulator = record["Regulator"];
dimension = record["Dim"];
letters = DeleteDuplicatesBy[record["Letters"], Together[D[Log[#], variables]] &];
connection = Map[Together[#/regulator] &,
  {record["EpsFormX"], record["EpsFormY"]}, {3}];

zeroQ[expr_] := TrueQ[Together[expr] === 0];
matrixZeroQ[matrix_] := AllTrue[Flatten[matrix], zeroQ];

appendIndependentVector[basis_List, vector_List] :=
  If[basis === {} || MatrixRank[Append[basis, vector]] > Length[basis],
    Append[basis, vector], basis];

independentRows[rows_List] := Fold[appendIndependentVector, {}, rows];

independentColumns[matrix_?MatrixQ] :=
  If[Dimensions[matrix][[2]] == 0, ConstantArray[{}, Dimensions[matrix][[1]]],
    Transpose[independentRows[Transpose[matrix]]]];

samplePoints = Flatten[Table[
    Thread[variables -> {p0, u0}],
    {p0, {1/7, 2/7, 3/7, 4/7, 5/7, 6/7}},
    {u0, {1/11, 2/11, 3/11, 5/11, 7/11}}], 1];

dlog = Table[Together[D[Log[letter], variable]],
  {variable, variables}, {letter, letters}];

validPointQ[rules_] := FreeQ[(dlog /. rules), ComplexInfinity | Indeterminate | DirectedInfinity];
samplePoints = Select[samplePoints, validPointQ];

sampleMatrix = Flatten[Table[dlog[[direction]] /. rules,
    {rules, samplePoints}, {direction, 2}], 1];

letterColumns = independentColumns[Transpose[sampleMatrix]];
independentLetterCount = Dimensions[letterColumns][[2]];

(* Select an independent subset of the original dlog columns. *)
letterPivots = Module[{selected = {}, rank = 0, candidateRank},
  Do[
    candidateRank = MatrixRank[sampleMatrix[[All, Append[selected, j]]]];
    If[candidateRank > rank, selected = Append[selected, j]; rank = candidateRank],
    {j, Length[letters]}];
  selected
];
letters = letters[[letterPivots]];
dlog = dlog[[All, letterPivots]];
sampleMatrix = sampleMatrix[[All, letterPivots]];

rowPivots = Module[{selected = {}, rank = 0, candidateRank},
  Do[
    candidateRank = MatrixRank[sampleMatrix[[Append[selected, j], All]]];
    If[candidateRank > rank, selected = Append[selected, j]; rank = candidateRank],
    {j, Length[sampleMatrix]}];
  selected
];

If[Length[rowPivots] =!= Length[letters],
  Print[family, ": could not obtain an independent dlog sampling system"];
  Exit[3]
];

connectionSamples = Flatten[Table[
    connection[[direction]] /. rules,
    {rules, samplePoints}, {direction, 2}], 1];

residueRows = LinearSolve[sampleMatrix[[rowPivots, All]],
    Flatten /@ connectionSamples[[rowPivots]]];
residues = ArrayReshape[#, {dimension, dimension}] & /@ residueRows;

residueCheck = {
  matrixZeroQ[connection[[1]] - Sum[dlog[[1, a]] residues[[a]], {a, Length[letters]}]],
  matrixZeroQ[connection[[2]] - Sum[dlog[[2, a]] residues[[a]], {a, Length[letters]}]]
};

If[residueCheck =!= {True, True},
  Print[family, ": exact residue reconstruction failed: ", residueCheck];
  Exit[4]
];

rightClosure[seed_?MatrixQ] := Module[{basis, oldDimension = -1},
  basis = independentColumns[seed];
  While[Dimensions[basis][[2]] =!= oldDimension,
    oldDimension = Dimensions[basis][[2]];
    basis = independentColumns[Join[basis,
      Sequence @@ (Together[# . basis] & /@ residues), 2]];
  ];
  basis
];

leftClosure[seed_?MatrixQ] := Transpose[rightClosure[Transpose[seed]]];

(* The family record is ordered by Flatten[Blocks]. *)
permutation = Flatten[record["Blocks"]];
valuationByMaster = Association@Table[
    {entry["Family"], entry["Indices"]} -> entry["Valuation"],
    {entry, valuations}];
demandedOriginalRows = DeleteCases[Table[
    If[KeyExistsQ[valuationByMaster, {family, master[[2]]}], row, Nothing],
    {master, de["BlockBasis"]}, {row, {First@FirstPosition[de["BlockBasis"], master]}}],
  Nothing, Infinity];
demandedPermutedRows = DeleteDuplicates[
  First@FirstPosition[permutation, #] & /@ Flatten[demandedOriginalRows]];

genericPoint = Thread[variables -> {2/7, 3/11}];
genericRegulator = regulator -> 1/13;
selector = IdentityMatrix[dimension][[demandedPermutedRows]];
leftSeed = Together[selector . record["TTotal"] /. genericPoint /. genericRegulator];
leftBasis = leftClosure[leftSeed];

standardSeedDimensions = Table[
  Dimensions[rightClosure[UnitVector[dimension, j] // List // Transpose]][[2]],
  {j, dimension}];

(* Count words surviving after a left/right projection.  This is an exact
   diagnostic, not the transport representation proposed in the report. *)
wordCounts[left_, right_, weight_Integer] := Module[{states, next, counts = {}},
  states = {right};
  AppendTo[counts, Count[Together[left . #] & /@ states, value_ /; ! matrixZeroQ[value]]];
  Do[
    next = Flatten[Table[Together[residue . state],
        {state, states}, {residue, residues}], 1];
    states = next;
    AppendTo[counts,
      Count[Together[left . #] & /@ states, value_ /; ! matrixZeroQ[value]]],
    {weight}];
  counts
];

selectedSeeds = If[seedSelection === All, Range[dimension],
  Intersection[Range[dimension], seedSelection]];
rightSeeds = Association@Table[
  ToString[j] -> (UnitVector[dimension, j] // List // Transpose),
  {j, selectedSeeds}];

wordCountBySeed = Association@KeyValueMap[
  #1 -> wordCounts[leftSeed, #2, maxWeight] &, rightSeeds];

result = <|
  "Family" -> family,
  "Dimension" -> dimension,
  "Letters" -> letters,
  "ResidueCount" -> Length[residues],
  "ExactResidueReconstruction" -> residueCheck,
  "DemandedRowsInPermutedBasis" -> demandedPermutedRows,
  "DemandedRowRankAtGenericPoint" -> MatrixRank[leftSeed],
  "LeftClosureDimensionAtGenericPoint" -> MatrixRank[leftBasis],
  "RightClosureDimensionByStandardSeed" -> standardSeedDimensions,
  "WordCountsByStandardSeedAfterDemandProjection" -> wordCountBySeed,
  "MaxWeight" -> maxWeight
|>;

output = FileNameJoin[{DirectoryName[$InputFileName],
    "ResidueSubspaces_" <> family <> ".wl"}];
Put[result, output];

Print[family, ": dimension ", dimension, ", independent dlog residues ",
  Length[residues]];
Print["  demanded row rank = ", result["DemandedRowRankAtGenericPoint"],
  ", left closure dimension = ", result["LeftClosureDimensionAtGenericPoint"]];
Print["  right closure dimensions by standard seed = ", standardSeedDimensions];
Print["  result: ", output];
