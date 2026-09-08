If[Length[$ScriptCommandLine] < 4,
  Print["usage: wolframscript -file AnalyzeEndpointModes.wls <family-record> <frobenius-record> <output>"];
  Exit[2]
];

family = Get[$ScriptCommandLine[[2]]];
frobenius = Get[$ScriptCommandLine[[3]]];
outputFile = $ScriptCommandLine[[4]];

dimension = family["Dim"];
variable = frobenius["Variable"];
localVariable = frobenius["LocalVariable"];
endpoint = frobenius["Endpoint"];
fixedRules = frobenius["FixedRules"];
ranges = family["Ranges"];
originalBlocks = family["Blocks"];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];

residue = SparseFromEntries[
  frobenius["ResidueEntries"],
  {dimension, dimension}
];

RationalOrder[0] = Infinity;
RationalOrder[expr_] := Module[{numerator, denominator},
  {numerator, denominator} = NumeratorDenominator[Together[expr]];
  Exponent[numerator /. localVariable -> z localVariable, z, Min] -
    Exponent[denominator /. localVariable -> z localVariable, z, Min]
];

JordanBlockSizes[matrix_, eigenvalue_, multiplicity_] := Module[
  {blockDimension, nullities, atLeast, exactCounts},
  blockDimension = Length[matrix];
  nullities = Table[
    blockDimension - MatrixRank[MatrixPower[
      matrix - eigenvalue IdentityMatrix[blockDimension], power]],
    {power, 1, multiplicity}
  ];
  atLeast = Differences[Prepend[nullities, 0]];
  exactCounts = atLeast - Append[Rest[atLeast], 0];
  Flatten@MapIndexed[ConstantArray[First[#2], #1] &, exactCounts]
];

ResidueModes[matrix_] := Map[
  Function[item,
    <|
      "Eigenvalue" -> item[[1]],
      "AlgebraicMultiplicity" -> item[[2]],
      "JordanBlockSizes" -> JordanBlockSizes[
        matrix, item[[1]], item[[2]]
      ]
    |>
  ],
  Tally[Eigenvalues[matrix]]
];

tTotal = Map[
  Together,
  family["TTotal"] /. fixedRules /.
    variable -> endpoint + localVariable,
  {2}
];

blockRecords = MapThread[
  Function[{canonicalRows, originalRows},
    Module[{rBlock, tBlock, entryOrders, rowOrders, determinantOrder},
      rBlock = Normal[residue[[canonicalRows, canonicalRows]]];
      (* TTotal acts on the family basis after the permutation
         Flatten[family["Blocks"]].  Its row positions therefore coincide
         with canonicalRows; originalRows are labels in the unpermuted
         differential-equation basis. *)
      tBlock = tTotal[[canonicalRows, canonicalRows]];
      entryOrders = Map[RationalOrder, tBlock, {2}];
      rowOrders = Map[Min, entryOrders];
      determinantOrder = If[Length[canonicalRows] == Length[originalRows],
        RationalOrder[Det[tBlock]],
        Missing["RectangularBlock"]
      ];
      <|
        "CanonicalRows" -> canonicalRows,
        "OriginalRows" -> originalRows,
        "ResidueModes" -> ResidueModes[rBlock],
        "TransformationEntryOrders" -> entryOrders,
        "OriginalRowMinimumOrders" -> rowOrders,
        "TransformationDeterminantOrder" -> determinantOrder
      |>
    ]
  ],
  {ranges, originalBlocks}
];

result = <|
  "Format" -> "FeynFacetEndpointModeCensus",
  "FormatVersion" -> 1,
  "Family" -> family["Family"],
  "Variable" -> variable,
  "Endpoint" -> endpoint,
  "FixedRules" -> fixedRules,
  "Blocks" -> blockRecords,
  "Certificate" -> <|
    "EveryCanonicalRowOccursOnce" ->
      Sort[Flatten[ranges]] === Range[dimension],
    "EveryOriginalRowOccursOnce" ->
      Sort[Flatten[originalBlocks]] === Range[dimension]
  |>
|>;

Put[result, outputFile];
Print[Dataset[blockRecords][
  All,
  {"CanonicalRows", "OriginalRows", "ResidueModes",
   "OriginalRowMinimumOrders", "TransformationDeterminantOrder"}
]];
