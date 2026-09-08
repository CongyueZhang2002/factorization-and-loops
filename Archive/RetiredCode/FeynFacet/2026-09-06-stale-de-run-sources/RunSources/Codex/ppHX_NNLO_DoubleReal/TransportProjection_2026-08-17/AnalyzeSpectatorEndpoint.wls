If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file AnalyzeSpectatorEndpoint.wls <record>"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];
variable = record["Variable"];
shape = record["Shape"];

matrixFromEntries[entries_, dims_] := SparseArray[
  Rule[#[[1 ;; 2]], #[[3]]] & /@ entries,
  dims
];

connection = matrixFromEntries[record["ConnectionEntries"], shape];
residue = matrixFromEntries[record["ResidueEntries"], shape];
connectionValues = record["ConnectionEntries"][[All, 3]];

denominatorFactors = DeleteDuplicates[
  Flatten[
    Rest[FactorList[Denominator[Together[#]]]][[All, 1]] & /@
      connectionValues
  ]
];

normalizedFactors = SortBy[
  DeleteDuplicates[
    FactorTerms[#/Coefficient[#, variable, Exponent[#, variable]], variable] & /@
      denominatorFactors
  ],
  ToString[InputForm[#]] &
];

maximumFiniteMultiplicity = Max[Prepend[
  Flatten[
    Rest[FactorList[Denominator[Together[#]]]][[All, 2]] & /@
      connectionValues
  ], 0]];

maximumInfinityDegree = Max[
  (Exponent[Numerator[Together[#]], variable] -
      Exponent[Denominator[Together[#]], variable]) & /@
    connectionValues
];

characteristicPolynomial = Factor[
  CharacteristicPolynomial[residue, lambda]
];

nullities = Table[
  shape[[1]] - MatrixRank[MatrixPower[residue, power]],
  {power, 1, 8}
];

Print[<|
  "Family" -> record["Family"],
  "Dimension" -> shape[[1]],
  "FinitePoleFactors" -> normalizedFactors,
  "MaximumFiniteMultiplicity" -> maximumFiniteMultiplicity,
  "MaximumInfinityDegree" -> maximumInfinityDegree,
  "EndpointResidueRank" -> MatrixRank[residue],
  "EndpointCharacteristicPolynomial" -> characteristicPolynomial,
  "NullitiesOfResiduePowers1Through8" -> nullities
|>];
