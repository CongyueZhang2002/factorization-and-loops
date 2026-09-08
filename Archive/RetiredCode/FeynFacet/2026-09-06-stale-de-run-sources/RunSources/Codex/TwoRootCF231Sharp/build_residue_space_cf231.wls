auditDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit";
outputDirectory = DirectoryName[$InputFileName];
stripPath = FileNameJoin[{auditDirectory, "CF231_8_7_exact_strip.wl"}];
summaryPath =
  FileNameJoin[{auditDirectory, "residue_compatibility_summary.wl"}];
outputPath = FileNameJoin[{outputDirectory, "CF231_8_7_residue_space.wl"}];

record = Get[stripPath];
summary = Get[summaryPath];
{y, s} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record /@ {"E", "C", "Bbar"};
alphabet = summary["Alphabet"];
dlog = Table[
  Together[D[Log[alphabet[[a]]], record["Variables"][[mu]]]],
  {a, Length[alphabet]}, {mu, 2}
];

matrixDimension = First[Dimensions[e[[1]]]];
residueUnknownCount = Length[alphabet] matrixDimension^2;

ClearAll[columnIndex];
columnIndex[a_, i_, j_] :=
  ((a - 1) matrixDimension + i - 1) matrixDimension + j;

ClearAll[modNumber];
modNumber[value_, prime_] := Module[{numerator, denominator},
  If[! FreeQ[value, _Symbol], Throw[$Failed, "BadCoefficient"]];
  numerator = Mod[Numerator[value], prime];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Throw[$Failed, "BadCoefficient"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

ClearAll[polynomialRules];
polynomialRules[polynomial_, prime_] :=
  ({First[#], modNumber[Last[#], prime]} &) /@
    (List @@@ CoefficientRules[polynomial, {y, s}]);

ClearAll[rationalForm];
rationalForm[expression_, prime_] := Module[{q},
  q = Together[expression];
  {
    polynomialRules[Numerator[q], prime],
    polynomialRules[Denominator[q], prime]
  }
];

ClearAll[evaluatePolynomial];
evaluatePolynomial[rules_List, yValue_Integer, sValue_Integer, prime_] :=
  Mod[
    Total[
      (#[[2]] PowerMod[Mod[yValue, prime], #[[1, 1]], prime]
          PowerMod[Mod[sValue, prime], #[[1, 2]], prime]) & /@ rules
    ],
    prime
  ];

ClearAll[evaluateRational];
evaluateRational[
    form_List, yValue_Integer, sValue_Integer, prime_] := Module[
  {numerator, denominator},
  numerator = evaluatePolynomial[form[[1]], yValue, sValue, prime];
  denominator = evaluatePolynomial[form[[2]], yValue, sValue, prime];
  If[denominator === 0, Throw[$Failed, "BadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

ClearAll[buildRowsFromValues];
buildRowsFromValues[eValue_, cValue_, dlogValue_, modulus_: None] := Module[
  {rows, rowIndex, row, coefficient, a, p, q, i, j},
  rows = ConstantArray[0, {matrixDimension^2, residueUnknownCount}];
  rowIndex = 0;
  Do[
    rowIndex++;
    row = rows[[rowIndex]];
    Do[
      coefficient =
        dlogValue[[a, 2]] (
          If[q === j, eValue[[1, i, p]], 0] -
          If[p === i, cValue[[1, q, j]], 0]
        ) -
        dlogValue[[a, 1]] (
          If[q === j, eValue[[2, i, p]], 0] -
          If[p === i, cValue[[2, q, j]], 0]
        );
      If[modulus =!= None, coefficient = Mod[coefficient, modulus]];
      If[coefficient =!= 0,
        row[[columnIndex[a, p, q]]] = coefficient
      ],
      {a, Length[alphabet]}, {p, matrixDimension},
      {q, matrixDimension}
    ];
    rows[[rowIndex]] = row,
    {i, matrixDimension}, {j, matrixDimension}
  ];
  SparseArray[rows]
];

ClearAll[modularSample];
modularSample[prime_Integer, seed_Integer, requestedPointCount_Integer] :=
 Module[
  {preprocessingSeconds, forms, eForms, cForms, dlogForms,
   buildPointRows, acceptedPoints = {}, pointRows = {}, attempts = 0,
   point, pointResult, samplingSeconds, matrix, rankSeconds, rank,
   rrefSeconds, transposeRref, pivotRows},

  {preprocessingSeconds, forms} = AbsoluteTiming[{
    Map[rationalForm[#, prime] &, e, {3}],
    Map[rationalForm[#, prime] &, c, {3}],
    Map[rationalForm[#, prime] &, dlog, {2}]
  }];
  {eForms, cForms, dlogForms} = forms;

  buildPointRows[yValue_Integer, sValue_Integer] := Catch[
    Module[{eValue, cValue, dlogValue},
      eValue =
        Map[evaluateRational[#, yValue, sValue, prime] &, eForms, {3}];
      cValue =
        Map[evaluateRational[#, yValue, sValue, prime] &, cForms, {3}];
      dlogValue =
        Map[evaluateRational[#, yValue, sValue, prime] &, dlogForms, {2}];
      buildRowsFromValues[eValue, cValue, dlogValue, prime]
    ],
    "BadPoint"
  ];

  SeedRandom[seed];
  {samplingSeconds, samplingResult} = AbsoluteTiming[
    While[Length[acceptedPoints] < requestedPointCount,
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      pointResult = buildPointRows @@ point;
      If[pointResult =!= $Failed,
        AppendTo[acceptedPoints, point];
        AppendTo[pointRows, pointResult]
      ]
    ]
  ];
  matrix = Join @@ pointRows;
  {rankSeconds, rank} = AbsoluteTiming[
    MatrixRank[matrix, Modulus -> prime]
  ];
  {rrefSeconds, transposeRref} = AbsoluteTiming[
    RowReduce[Transpose[matrix], Modulus -> prime]
  ];
  pivotRows = Map[
    Function[row,
      With[{positions = Position[row, Except[0], {1}, Heads -> False]},
        If[positions === {}, Nothing, First[First[positions]]]
      ]
    ],
    Normal[transposeRref]
  ];
  If[Length[pivotRows] =!= rank,
    Print["Pivot extraction failed: ", Length[pivotRows], " != ", rank];
    Exit[2]
  ];

  <|
    "Prime" -> prime,
    "Seed" -> seed,
    "AcceptedPoints" -> acceptedPoints,
    "AttemptCount" -> attempts,
    "MatrixDimensions" -> Dimensions[matrix],
    "NonzeroEntries" -> Length[matrix["NonzeroValues"]],
    "Rank" -> rank,
    "Nullity" -> residueUnknownCount - rank,
    "PivotRows" -> pivotRows,
    "PreprocessingSeconds" -> preprocessingSeconds,
    "SamplingSeconds" -> samplingSeconds,
    "RankSeconds" -> rankSeconds,
    "RREFSeconds" -> rrefSeconds
  |>
];

Print["Building independent finite-field residue samples."];
{sampleSeconds, samples} = AbsoluteTiming[{
  modularSample[1000003, 231087, 20],
  modularSample[1000033, 305087, 20]
}];
Print[KeyDrop[#, {"AcceptedPoints", "PivotRows"}] & /@ samples];

If[Length[DeleteDuplicates[samples[[All, "Rank"]]]] =!= 1,
  Print["Finite-field ranks disagree: ", samples[[All, "Rank"]]];
  Exit[3]
];

referenceSample = First[samples];
pivotRows = referenceSample["PivotRows"];
acceptedPoints = referenceSample["AcceptedPoints"];
requiredPointIndices = DeleteDuplicates[Ceiling[pivotRows/matrixDimension^2]];

Print["Building exact rows from ", Length[requiredPointIndices],
  " rational chart points."];
{exactRowSeconds, exactPointRows} = AbsoluteTiming[
  Association@Table[
    pointIndex -> Module[{rules, eValue, cValue, dlogValue},
      rules = Thread[{y, s} -> acceptedPoints[[pointIndex]]];
      eValue = Map[Together[# /. rules] &, e, {3}];
      cValue = Map[Together[# /. rules] &, c, {3}];
      dlogValue = Map[Together[# /. rules] &, dlog, {2}];
      buildRowsFromValues[eValue, cValue, dlogValue]
    ],
    {pointIndex, requiredPointIndices}
  ]
];

ClearAll[exactRowForIndex];
exactRowForIndex[rowIndex_Integer] := Module[{pointIndex, localRowIndex},
  pointIndex = Ceiling[rowIndex/matrixDimension^2];
  localRowIndex = Mod[rowIndex - 1, matrixDimension^2] + 1;
  exactPointRows[pointIndex][[localRowIndex]]
];

exactMatrix = SparseArray[Normal /@ (exactRowForIndex /@ pivotRows)];
{exactRankSeconds, exactRank} = AbsoluteTiming[MatrixRank[exactMatrix]];
{nullspaceSeconds, exactNullspace} = AbsoluteTiming[NullSpace[exactMatrix]];

If[exactRank =!= referenceSample["Rank"] ||
    Length[exactNullspace] =!= referenceSample["Nullity"],
  Print["Exact and finite-field dimensions disagree."];
  Exit[4]
];

ClearAll[residueMatricesFromVector];
residueMatricesFromVector[vector_List] :=
  ArrayReshape[vector, {Length[alphabet], matrixDimension, matrixDimension}];

residueBasis = residueMatricesFromVector /@ exactNullspace;

ClearAll[compatibilityForResidues];
compatibilityForResidues[residueMatrices_List] :=
  Sum[
    dlog[[a, 2]] (e[[1]].residueMatrices[[a]] -
        residueMatrices[[a]].c[[1]]) -
    dlog[[a, 1]] (e[[2]].residueMatrices[[a]] -
        residueMatrices[[a]].c[[2]]),
    {a, Length[alphabet]}
  ];

Print["Checking every exact nullspace direction in the full rational PDE."];
{closureSeconds, closureMatrices} = AbsoluteTiming[
  Map[Together, compatibilityForResidues[#], {2}] & /@ residueBasis
];
closureZero = AllTrue[Flatten[closureMatrices], TrueQ[# === 0] &];

parameters = Array[rho, Length[residueBasis]];
generalResidues = Sum[
  parameters[[index]] residueBasis[[index]],
  {index, Length[residueBasis]}
];
generalForcing = Table[
  bbar[[mu]] - epsilon Sum[
    generalResidues[[a]] dlog[[a, mu]],
    {a, Length[alphabet]}
  ],
  {mu, 2}
];

result = <|
  "Family" -> record["Family"],
  "Pair" -> record["Pair"],
  "Chart" -> record["Chart"],
  "Variables" -> record["Variables"],
  "Regulator" -> epsilon,
  "Alphabet" -> alphabet,
  "DLog" -> dlog,
  "ResidueUnknownCount" -> residueUnknownCount,
  "FiniteFieldSamples" -> samples,
  "ExactRank" -> exactRank,
  "FreeResidueParameterCount" -> Length[residueBasis],
  "Parameters" -> parameters,
  "ResidueBasis" -> residueBasis,
  "GeneralResidues" -> generalResidues,
  "Forcing" -> generalForcing,
  "ClosureZero" -> closureZero,
  "Timings" -> <|
    "AllFiniteFieldSamples" -> sampleSeconds,
    "ExactRows" -> exactRowSeconds,
    "ExactRank" -> exactRankSeconds,
    "ExactNullspace" -> nullspaceSeconds,
    "ExactClosure" -> closureSeconds
  |>
|>;

Put[result, outputPath];
Print[KeyDrop[result, {
  "DLog", "FiniteFieldSamples", "ResidueBasis", "GeneralResidues",
  "Forcing"
}]];
Print["Finite-field summaries: ",
  KeyDrop[#, {"AcceptedPoints", "PivotRows"}] & /@ samples];
Print["Saved: ", outputPath, " (", FileByteCount[outputPath], " bytes)"];

If[! TrueQ[closureZero], Exit[5]];
