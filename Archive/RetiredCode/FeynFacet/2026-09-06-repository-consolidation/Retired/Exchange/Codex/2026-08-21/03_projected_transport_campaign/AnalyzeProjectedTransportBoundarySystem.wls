#!/usr/bin/env wolframscript

(* Read-only structural census of an extracted exact boundary system. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["Usage: AnalyzeProjectedTransportBoundarySystem.wls INPUT.wl OUTPUT.wl"];
  Exit[64]
];
{inputFile, outputFile} = ExpandFileName /@ arguments;
record = Quiet[Check[Get[inputFile], $Failed]];
If[! AssociationQ[record] ||
    Lookup[record, "Status", None] =!=
      "DiagnosticBoundaryConstraintMatrix",
  Print["Malformed boundary-system record"];
  Exit[65]
];

matrix = record["ConstraintMatrix"];
variables = record["Variables"];
If[! MatrixQ[matrix] || ! MatchQ[variables, {_Symbol, _Symbol}], Exit[65]];
{rows, columns} = Dimensions[matrix];
nonzeroQ[x_] := ! TrueQ[x === 0];
positions = Position[matrix, x_ /; nonzeroQ[x], {2}];
rowNonzeros = Count[#, x_ /; nonzeroQ[x]] & /@ matrix;
columnNonzeros = Count[#, x_ /; nonzeroQ[x]] & /@ Transpose[matrix];

samplePoints = {
  Thread[variables -> {2/7, 3/11}],
  Thread[variables -> {3/8, 4/13}],
  Thread[variables -> {4/9, 5/17}]
};
pivotPattern[rules_] := Module[{reduced, pivots},
  reduced = RowReduce[matrix /. rules];
  pivots = DeleteMissing[(Replace[
      FirstPosition[#, x_ /; ! TrueQ[x === 0], Missing["ZeroRow"],
        {1}, Heads -> False], {position_Integer} :> position] &) /@ reduced];
  pivots
];
pivotPatterns = pivotPattern /@ samplePoints;
pivotColumns = First[pivotPatterns];
freeColumns = Reverse[Complement[Range[columns], pivotColumns]];
pivotSquare = matrix[[All, pivotColumns]];
freeBlock = matrix[[All, freeColumns]];

componentSummary[m_?MatrixQ] := Module[
  {nr, nc, edges, components},
  {nr, nc} = Dimensions[m];
  edges = Flatten@Table[
    If[nonzeroQ[m[[i, j]]], {UndirectedEdge[i, nr + j]}, {}],
    {i, nr}, {j, nc}];
  components = ConnectedComponents[Graph[Range[nr + nc], edges]];
  SortBy[
    (<|"Rows" -> Count[#, x_ /; x <= nr],
       "Columns" -> Count[#, x_ /; x > nr],
       "Vertices" -> Length[#]|> &) /@ components,
    -#Vertices &]
];

nonzeroEntries = Extract[matrix, positions];
degreeRow[x_] := Module[{fraction, numerator, denominator},
  fraction = Together[x];
  numerator = Numerator[fraction];
  denominator = Denominator[fraction];
  <|
    "NumeratorDegrees" -> (Exponent[numerator, #] & /@ variables),
    "DenominatorDegrees" -> (Exponent[denominator, #] & /@ variables),
    "LeafCount" -> LeafCount[fraction]
  |>
];
degreeRows = degreeRow /@ nonzeroEntries;

result = <|
  "Status" -> "ExactBoundarySystemCensus",
  "Family" -> record["Family"],
  "Variables" -> variables,
  "Dimensions" -> {rows, columns},
  "ExactRank" -> record["ConstraintRank"],
  "NonzeroEntries" -> Length[positions],
  "Density" -> N[Length[positions]/(rows columns)],
  "RowNonzeroRange" -> MinMax[rowNonzeros],
  "ColumnNonzeroRange" -> MinMax[columnNonzeros],
  "RowNonzeros" -> rowNonzeros,
  "ColumnNonzeros" -> columnNonzeros,
  "SamplePivotPatterns" -> pivotPatterns,
  "StablePivotPattern" -> SameQ @@ pivotPatterns,
  "PivotColumns" -> pivotColumns,
  "FreeColumnsCanonicalOrder" -> freeColumns,
  "FullBipartiteComponents" -> componentSummary[matrix],
  "PivotSquareBipartiteComponents" -> componentSummary[pivotSquare],
  "PivotSquareNonzeros" -> Count[Flatten[pivotSquare], x_ /; nonzeroQ[x]],
  "FreeBlockNonzeros" -> Count[Flatten[freeBlock], x_ /; nonzeroQ[x]],
  "MaximumNumeratorDegrees" ->
    Max /@ Transpose[Lookup[degreeRows, "NumeratorDegrees"]],
  "MaximumDenominatorDegrees" ->
    Max /@ Transpose[Lookup[degreeRows, "DenominatorDegrees"]],
  "MaximumEntryLeafCount" -> Max[Lookup[degreeRows, "LeafCount"]],
  "MatrixByteCount" -> ByteCount[matrix],
  "InputSHA256" -> FileHash[inputFile, "SHA256", "HexString"]
|>;

Put[result, outputFile];
Print[InputForm[result]];
