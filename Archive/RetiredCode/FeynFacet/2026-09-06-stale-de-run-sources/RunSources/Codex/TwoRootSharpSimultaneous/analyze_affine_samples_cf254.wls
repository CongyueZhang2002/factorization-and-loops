directory = DirectoryName[$InputFileName];
files = Sort[FileNames["CF254_9_8_point_sample_rank_*.wl", directory]];

ClearAll[independentColumns];
independentColumns[matrix_List, prime_Integer] := Module[
  {columns = {}, rank = 0, trialRank},
  Do[
    trialRank = MatrixRank[matrix[[All, Append[columns, column]]],
      Modulus -> prime];
    If[trialRank > rank,
      AppendTo[columns, column];
      rank = trialRank
    ];
    If[rank === Length[matrix], Break[]],
    {column, Length[First[matrix]]}
  ];
  columns
];

ClearAll[canonicalizeAffineSample];
canonicalizeAffineSample[data_Association, fixedColumns_: Automatic] := Module[
  {prime, particular, nullspace, columns, block,
    parameters, canonical},

  prime = data["Prime"];
  particular = data["ParticularSolution"];
  nullspace = Normal[data["NullspaceBasis"]];
  columns = If[fixedColumns === Automatic,
    independentColumns[nullspace, prime],
    fixedColumns
  ];
  block = nullspace[[All, columns]];
  If[MatrixRank[block, Modulus -> prime] =!= Length[nullspace],
    Return[$Failed]
  ];
  parameters = LinearSolve[
    Transpose[block],
    Mod[-particular[[columns]], prime],
    Modulus -> prime
  ];
  canonical = Mod[particular + Transpose[nullspace].parameters, prime];

  <|
    "FixedColumns" -> columns,
    "CanonicalParticular" -> canonical,
    "FixedColumnsZero" -> AllTrue[canonical[[columns]], # === 0 &],
    "NonzeroGaugeCoefficients" -> Count[canonical[[1 ;; 968]],
      value_ /; value =!= 0],
    "NonzeroResidueCoefficients" -> Count[canonical[[969 ;; 977]],
      value_ /; value =!= 0],
    "ResidueCoefficients" -> canonical[[969 ;; 977]]
  |>
];

samples = Get /@ files;
reference = canonicalizeAffineSample[First[samples]];
fixedColumns = reference["FixedColumns"];
referencePrime = First[samples]["Prime"];
referenceNullspace = Normal[First[samples]["NullspaceBasis"]];
residueRelativeColumns = independentColumns[
  referenceNullspace[[All, 969 ;; 977]], referencePrime];
residueColumns = residueRelativeColumns + 968;
residueBlockRank = MatrixRank[
  referenceNullspace[[All, 969 ;; 977]], Modulus -> referencePrime];

Print["Affine sample count: ", Length[samples]];
Print["Normalization columns: ", fixedColumns];
Print["Normalization lies in residue coordinates: ",
  AllTrue[fixedColumns, 969 <= # <= 977 &]];
Print["Residue-block rank: ", residueBlockRank];
Print["Independent residue columns: ", residueColumns];

Do[
  analysis = canonicalizeAffineSample[sample, fixedColumns];
  Print[<|
    "EpsilonValue" -> sample["EpsilonValue"],
    "Prime" -> sample["Prime"],
    "FixedColumnsZero" -> analysis["FixedColumnsZero"],
    "NonzeroGaugeCoefficients" ->
      analysis["NonzeroGaugeCoefficients"],
    "NonzeroResidueCoefficients" ->
      analysis["NonzeroResidueCoefficients"],
    "ResidueCoefficients" -> analysis["ResidueCoefficients"]
  |>],
  {sample, samples}
];

If[residueBlockRank === 8,
  Print["Residue-normalized affine samples:"];
  Do[
    analysis = canonicalizeAffineSample[sample, residueColumns];
    Print[<|
      "EpsilonValue" -> sample["EpsilonValue"],
      "Prime" -> sample["Prime"],
      "FixedColumnsZero" -> analysis["FixedColumnsZero"],
      "NonzeroGaugeCoefficients" ->
        analysis["NonzeroGaugeCoefficients"],
      "NonzeroResidueCoefficients" ->
        analysis["NonzeroResidueCoefficients"],
      "ResidueCoefficients" -> analysis["ResidueCoefficients"]
    |>],
    {sample, Take[samples, UpTo[5]]}
  ]
];
