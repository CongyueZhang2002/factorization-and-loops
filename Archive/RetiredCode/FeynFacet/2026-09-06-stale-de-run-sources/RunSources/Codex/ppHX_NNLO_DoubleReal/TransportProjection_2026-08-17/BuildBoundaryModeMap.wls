If[Length[$ScriptCommandLine] < 6,
  Print["usage: wolframscript -file BuildBoundaryModeMap.wls <family-record> <frobenius-record> <endpoint-spec> <realizations> <output>"];
  Exit[2]
];

family = Get[$ScriptCommandLine[[2]]];
frobenius = Get[$ScriptCommandLine[[3]]];
spec = Get[$ScriptCommandLine[[4]]];
realizations = Get[$ScriptCommandLine[[5]]];
outputFile = $ScriptCommandLine[[6]];

dimension = family["Dim"];
epsilon = family["Regulator"];
variable = spec["Variable"];
localVariable = spec["LocalVariable"];
endpoint = spec["Endpoint"];
fixedRules = spec["FixedRules"];
relation = spec["PhysicalEndpointRelation"];
localPower = relation["LocalPower"];
endpointCoefficient = relation["LeadingCoefficient"];
ranges = family["Ranges"];
originalBlocks = family["Blocks"];
permutation = Flatten[originalBlocks];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];
SparseEntries[m_] :=
  ({#[[1, 1]], #[[1, 2]], #[[2]]} &) /@ Most[ArrayRules[SparseArray[m]]];
VectorEntries[v_] := Cases[
  MapIndexed[{First[#2], Together[#1]} &, v],
  {index_, value_} /; value =!= 0 :> {index, value}
];
ZeroVectorQ[v_] := AllTrue[Flatten[v], Together[#] === 0 &];

residue = Normal@SparseFromEntries[
  frobenius["ResidueEntries"],
  {dimension, dimension}
];
hPrefactor = Total@Map[
  Function[item,
    epsilon^item["EpsilonOrder"] *
      localVariable^item["SeriesOrder"] *
      SparseFromEntries[item["Entries"], {dimension, dimension}]
  ],
  frobenius["FrobeniusPrefactorCoefficients"]
];
tTotal = Map[
  Together,
  family["TTotal"] /. fixedRules /.
    variable -> endpoint + localVariable,
  {2}
];

RationalOrder[0] = Infinity;
RationalOrder[expr_] := Module[{numerator, denominator},
  {numerator, denominator} = NumeratorDenominator[Together[expr]];
  Exponent[numerator /. localVariable -> z localVariable, z, Min] -
    Exponent[denominator /. localVariable -> z localVariable, z, Min]
];

LeadingCoefficient[0, _] = 0;
LeadingCoefficient[expr_, order_] := Together[
  Limit[expr/localVariable^order, localVariable -> 0]
];

ParticularSolution[matrix_, target_] := Module[
  {columnCount, reduced, coefficientPart, rightHandSide, solution,
   pivotPositions},
  columnCount = Dimensions[matrix][[2]];
  reduced = RowReduce[Join[matrix, List /@ target, 2]];
  coefficientPart = reduced[[All, 1 ;; columnCount]];
  rightHandSide = reduced[[All, -1]];
  If[AnyTrue[Range[Length[rightHandSide]],
      Function[row,
        ZeroVectorQ[coefficientPart[[row]]] &&
          Together[rightHandSide[[row]]] =!= 0
      ]],
    Return[$Failed]
  ];
  solution = ConstantArray[0, columnCount];
  Do[
    pivotPositions = Position[
      coefficientPart[[row]],
      value_ /; Together[value] =!= 0,
      {1},
      1,
      Heads -> False
    ];
    If[pivotPositions =!= {},
      solution[[First[First[pivotPositions]]]] = rightHandSide[[row]]
    ],
    {row, Length[rightHandSide]}
  ];
  solution
];

ModeExtension[canonicalRows_, eigenvalue_, maximumLevel_] := Module[
  {operator, seedBasis, seed, prefix, target, level, globalBasis,
   coefficient, candidate, diagnostics = {}, found = $Failed},
  operator = residue - eigenvalue IdentityMatrix[dimension];
  seedBasis = NullSpace[operator[[canonicalRows, canonicalRows]]];
  If[Length[seedBasis] =!= 1,
    Return[<|"Status" -> "AmbiguousBlockEigenspace",
      "BlockNullity" -> Length[seedBasis]|>]
  ];
  seed = First[seedBasis];
  prefix = Range[Last[canonicalRows]];
  target = ConstantArray[0, Length[prefix]];
  target[[canonicalRows]] = seed;
  Do[
    globalBasis = Transpose[NullSpace[MatrixPower[operator, level + 1]]];
    If[Dimensions[globalBasis][[2]] > 0,
      AppendTo[diagnostics, <|
        "Level" -> level,
        "GlobalNullity" -> Dimensions[globalBasis][[2]],
        "ConstraintRank" -> MatrixRank[globalBasis[[prefix, All]]],
        "AugmentedRank" -> MatrixRank[Join[
          globalBasis[[prefix, All]], List /@ target, 2
        ]]
      |>];
      coefficient = ParticularSolution[globalBasis[[prefix, All]], target];
      If[coefficient =!= $Failed,
        candidate = Together[globalBasis.coefficient];
        If[ZeroVectorQ[candidate[[prefix]] - target],
          found = <|
            "Status" -> "Exact",
            "GeneralizedLevel" -> level,
            "Vector" -> candidate,
            "Residual" -> Together[MatrixPower[operator, level + 1].candidate]
          |>;
          Break[],
          diagnostics[[-1]] = Join[diagnostics[[-1]], <|
            "CandidatePrefixResidual" -> Together[candidate[[prefix]] - target]
          |>]
        ]
      ]
    ],
    {level, 0, maximumLevel}
  ];
  If[AssociationQ[found], Return[found]];
  <|"Status" -> "NoCompatibleGlobalMode",
    "Seed" -> seed,
    "Diagnostics" -> diagnostics|>
];

BuildRecord[realization_] := Module[
  {originalRows, positions, blockIndex, canonicalRows, localEigenvalue,
   extension, mode, mapped, selected, orders, expectedOrder,
   expectedCoefficient, candidates, normalizationRow, normalization,
   normalizedMode, normalizedMapped, normalizedOrders,
   normalizedLeading},
  originalRows = realization["OriginalRows"];
  positions = Flatten[FirstPosition[permutation, #] & /@ originalRows];
  blockIndex = First@FirstPosition[
    Sort /@ originalBlocks,
    Sort[originalRows]
  ];
  canonicalRows = ranges[[blockIndex]];
  If[positions =!= canonicalRows,
    Return[Join[realization, <|
      "Status" -> "PermutationMismatch",
      "PermutedPositions" -> positions,
      "CanonicalRows" -> canonicalRows
    |>]]
  ];
  localEigenvalue = localPower realization["EpsilonExponent"];
  extension = ModeExtension[
    canonicalRows,
    localEigenvalue,
    realization["LogLevel"]
  ];
  If[extension["Status"] =!= "Exact",
    Return[Join[realization, <|
      "Status" -> extension["Status"],
      "CanonicalRows" -> canonicalRows,
      "LocalEigenvalue" -> localEigenvalue,
      "ModeExtension" -> extension
    |>]]
  ];
  mode = extension["Vector"];
  mapped = Together[tTotal.hPrefactor.mode];
  selected = mapped[[positions]];
  orders = RationalOrder /@ selected;
  expectedOrder = localPower realization["IntegerValuation"];
  expectedCoefficient = endpointCoefficient^realization["IntegerValuation"];
  candidates = Flatten@Position[orders, expectedOrder];
  If[candidates === {},
    Return[Join[realization, <|
      "Status" -> "ValuationMismatch",
      "CanonicalRows" -> canonicalRows,
      "LocalEigenvalue" -> localEigenvalue,
      "ActualLocalOrders" -> orders,
      "ExpectedLocalOrder" -> expectedOrder,
      "ModeEntries" -> VectorEntries[mode]
    |>]]
  ];
  normalizationRow = First[candidates];
  normalization = Together[
    expectedCoefficient/
      LeadingCoefficient[selected[[normalizationRow]], expectedOrder]
  ];
  normalizedMode = Together[normalization mode];
  normalizedMapped = Together[tTotal.hPrefactor.normalizedMode];
  normalizedOrders = RationalOrder /@ normalizedMapped[[positions]];
  normalizedLeading = MapThread[
    LeadingCoefficient,
    {normalizedMapped[[positions]], normalizedOrders}
  ];
  Join[realization, <|
    "Status" -> "Exact",
    "CanonicalRows" -> canonicalRows,
    "PermutedPositions" -> positions,
    "LocalEigenvalue" -> localEigenvalue,
    "GeneralizedLevel" -> extension["GeneralizedLevel"],
    "FrobeniusSeriesOrderUsed" -> frobenius["MaximumSeriesOrder"],
    "FrobeniusEpsilonOrderUsed" -> frobenius["MaximumEpsilonOrder"],
    "NormalizationOriginalRow" -> originalRows[[normalizationRow]],
    "NormalizationFactor" -> normalization,
    "CanonicalModeEntries" -> VectorEntries[normalizedMode],
    "OriginalRowLocalOrders" -> normalizedOrders,
    "OriginalRowLeadingCoefficients" -> normalizedLeading,
    "ExpectedLocalOrder" -> expectedOrder,
    "ExpectedLeadingCoefficient" -> expectedCoefficient,
    "ExactGeneralizedEigenvector" ->
      ZeroVectorQ[extension["Residual"]]
  |>]
];

modeRecords = BuildRecord /@ realizations;
result = <|
  "Format" -> "FeynFacetBoundaryModeMap",
  "FormatVersion" -> 1,
  "Family" -> family["Family"],
  "Variable" -> variable,
  "Endpoint" -> endpoint,
  "FixedRules" -> fixedRules,
  "PhysicalEndpointRelation" -> relation,
  "Modes" -> modeRecords,
  "Certificate" -> <|
    "EveryRealizationMappedExactly" ->
      AllTrue[modeRecords, #1["Status"] === "Exact" &]
  |>
|>;

Put[result, outputFile];
Print[Dataset[Map[
  KeyTake[#,
    {"PeriodID", "OriginalRows", "Status", "CanonicalRows",
     "LocalEigenvalue", "GeneralizedLevel", "OriginalRowLocalOrders",
     "OriginalRowLeadingCoefficients"}
  ] &,
  modeRecords
]]];
