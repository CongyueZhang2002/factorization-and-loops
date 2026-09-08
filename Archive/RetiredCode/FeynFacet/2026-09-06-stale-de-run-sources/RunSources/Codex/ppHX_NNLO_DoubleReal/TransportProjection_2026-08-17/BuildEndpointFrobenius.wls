If[Length[$ScriptCommandLine] < 4,
  Print["usage: wolframscript -file BuildEndpointFrobenius.wls <family-record> <endpoint-spec> <output>"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];
spec = Get[$ScriptCommandLine[[3]]];
outputFile = $ScriptCommandLine[[4]];

variable = spec["Variable"];
localVariable = Lookup[spec, "LocalVariable", ρ];
endpoint = Lookup[spec, "Endpoint", 0];
fixedRules = Lookup[spec, "FixedRules", {}];
connectionKey = spec["ConnectionKey"];
maximumSeriesOrder = Lookup[spec, "MaximumSeriesOrder", 4];
maximumEpsilonOrder = Lookup[spec, "MaximumEpsilonOrder", 3];
epsilon = record["Regulator"];
dimension = record["Dim"];

ZeroMatrixQ[m_] := AllTrue[Flatten[Normal[m]], Together[#] === 0 &];
CanonicalMatrix[m_] := SparseArray[Map[Together, Normal[m], {2}]];
SparseEntries[m_] :=
  ({#[[1, 1]], #[[1, 2]], #[[2]]} &) /@ Most[ArrayRules[SparseArray[m]]];

connection = Map[
  Together,
  (record[connectionKey]/epsilon) /. fixedRules /.
    variable -> endpoint + localVariable,
  {2}
];

If[! FreeQ[connection, epsilon],
  Print["the selected connection is not proportional to the regulator"];
  Exit[3]
];

residue = CanonicalMatrix@Map[
  Together[Limit[localVariable #, localVariable -> 0]] &,
  connection,
  {2}
];
regularConnection = Map[
  Together,
  Normal[connection] - Normal[residue]/localVariable,
  {2}
];

regularCoefficients = Table[
  CanonicalMatrix@Map[
    Together[Limit[
      D[#, {localVariable, order}], localVariable -> 0
    ]/Factorial[order]] &,
    regularConnection,
    {2}
  ],
  {order, 0, maximumSeriesOrder - 1}
];

If[! FreeQ[regularCoefficients, DirectedInfinity | Indeterminate],
  Print["the selected endpoint is not Fuchsian"];
  Exit[4]
];

h[0, 0] = IdentityMatrix[dimension, SparseArray];
Do[h[0, regulatorOrder] = SparseArray[{}, {dimension, dimension}],
  {regulatorOrder, 1, maximumEpsilonOrder}];

Do[
  h[seriesOrder, 0] = SparseArray[{}, {dimension, dimension}];
  Do[
    previous = h[seriesOrder, regulatorOrder - 1];
    source = Total@Table[
      regularCoefficients[[regularOrder + 1]].
        h[seriesOrder - 1 - regularOrder, regulatorOrder - 1],
      {regularOrder, 0, seriesOrder - 1}
    ];
    h[seriesOrder, regulatorOrder] = CanonicalMatrix[
      (residue.previous - previous.residue + source)/seriesOrder
    ],
    {regulatorOrder, 1, maximumEpsilonOrder}
  ],
  {seriesOrder, 1, maximumSeriesOrder}
];

regularTruncation = Sum[
  regularCoefficients[[order + 1]] localVariable^order,
  {order, 0, maximumSeriesOrder - 1}
];
hTruncation = Sum[
  epsilon^regulatorOrder localVariable^seriesOrder *
    h[seriesOrder, regulatorOrder],
  {seriesOrder, 0, maximumSeriesOrder},
  {regulatorOrder, 0, maximumEpsilonOrder}
];

directResidual = Expand[
  D[hTruncation, localVariable] +
  epsilon hTruncation.residue/localVariable -
  epsilon (residue/localVariable + regularTruncation).hTruncation
];

residualCoefficients = Flatten[Table[
  CanonicalMatrix@Map[
    Coefficient[Coefficient[#, epsilon, regulatorOrder], localVariable, seriesOrder] &,
    directResidual,
    {2}
  ],
  {seriesOrder, -1, maximumSeriesOrder - 1},
  {regulatorOrder, 0, maximumEpsilonOrder}
], 1];
directResidualZero = And @@ (ZeroMatrixQ /@ residualCoefficients);

If[! TrueQ[directResidualZero],
  Print["the Frobenius recurrence has a nonzero differential residual"];
  Exit[5]
];

residueEigenvalues = Tally[Eigenvalues[Normal[residue]]];

JordanBlockSizes[eigenvalue_, multiplicity_] := Module[
  {nullities, atLeast, exactCounts},
  nullities = Table[
    dimension - MatrixRank[MatrixPower[Normal[residue] -
      eigenvalue IdentityMatrix[dimension], power]],
    {power, 1, multiplicity}
  ];
  atLeast = Differences[Prepend[nullities, 0]];
  exactCounts = atLeast - Append[Rest[atLeast], 0];
  Flatten@MapIndexed[
    ConstantArray[First[#2], #1] &,
    exactCounts
  ]
];

residueModes = Map[
  Function[item,
    <|
      "Eigenvalue" -> item[[1]],
      "AlgebraicMultiplicity" -> item[[2]],
      "JordanBlockSizes" -> JordanBlockSizes[item[[1]], item[[2]]]
    |>
  ],
  residueEigenvalues
];

hRecords = Flatten@Table[
  <|
    "SeriesOrder" -> seriesOrder,
    "EpsilonOrder" -> regulatorOrder,
    "Entries" -> SparseEntries[h[seriesOrder, regulatorOrder]]
  |>,
  {seriesOrder, 0, maximumSeriesOrder},
  {regulatorOrder, 0, maximumEpsilonOrder}
];

result = <|
  "Format" -> "FeynFacetEndpointFrobeniusMap",
  "FormatVersion" -> 1,
  "Family" -> record["Family"],
  "Dimension" -> dimension,
  "Regulator" -> epsilon,
  "Variable" -> variable,
  "LocalVariable" -> localVariable,
  "Endpoint" -> endpoint,
  "FixedRules" -> fixedRules,
  "ConnectionKey" -> connectionKey,
  "MaximumSeriesOrder" -> maximumSeriesOrder,
  "MaximumEpsilonOrder" -> maximumEpsilonOrder,
  "ResidueEntries" -> SparseEntries[residue],
  "ResidueModes" -> residueModes,
  "RegularConnectionCoefficients" -> MapIndexed[
    <|"SeriesOrder" -> First[#2] - 1, "Entries" -> SparseEntries[#1]|> &,
    regularCoefficients
  ],
  "FrobeniusPrefactorCoefficients" -> hRecords,
  "LocalSolution" -> HoldForm[
    F[localVariable, epsilon] ==
      H[localVariable, epsilon].
      MatrixPower[localVariable, epsilon residue].c
  ],
  "Certificate" -> <|
    "ExactEpsilonFactorization" -> True,
    "FuchsianEndpoint" -> True,
    "ExactCoefficientRecurrence" -> True,
    "ExactDifferentialResidualThroughStoredOrders" -> directResidualZero
  |>
|>;

Put[result, outputFile];
Print[<|
  "Family" -> record["Family"],
  "Dimension" -> dimension,
  "ResidueRank" -> MatrixRank[residue],
  "ResidueModes" -> residueModes,
  "StoredFrobeniusMatrices" -> Length[hRecords],
  "NonzeroFrobeniusMatrices" -> Count[hRecords[[All, "Entries"]],
    entries_ /; entries =!= {}],
  "ExactDifferentialResidual" -> directResidualZero
|>];
