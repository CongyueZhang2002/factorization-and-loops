If[Length[$ScriptCommandLine] < 6,
  Print["usage: wolframscript -file ValidateBoundaryModeMap.wls <family-record> <frobenius-record> <endpoint-spec> <mode-map> <output>"];
  Exit[2]
];

family = Get[$ScriptCommandLine[[2]]];
frobenius = Get[$ScriptCommandLine[[3]]];
spec = Get[$ScriptCommandLine[[4]]];
modeMap = Get[$ScriptCommandLine[[5]]];
outputFile = $ScriptCommandLine[[6]];

dimension = family["Dim"];
epsilon = family["Regulator"];
variable = spec["Variable"];
localVariable = spec["LocalVariable"];
endpoint = spec["Endpoint"];
fixedRules = spec["FixedRules"];
localPower = spec["PhysicalEndpointRelation", "LocalPower"];
endpointCoefficient =
  spec["PhysicalEndpointRelation", "LeadingCoefficient"];
permutation = Flatten[family["Blocks"]];

SparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries,
  shape
];
VectorFromEntries[entries_] := SparseArray[
  (#[[1]] -> #[[2]]) & /@ entries,
  dimension
];
ExactZeroQ[expr_] := And @@ (Together[#] === 0 & /@ Flatten[expr]);

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

ValidateMode[mode_] := Module[
  {vector, operator, nilpotentResidual, minimalLevel, mapped,
   positions, selected, orders, leading, expectedOrder,
   expectedLeading, storedOrders, storedLeading, checks},
  vector = Normal@VectorFromEntries[mode["CanonicalModeEntries"]];
  operator = residue -
    mode["LocalEigenvalue"] IdentityMatrix[dimension];
  nilpotentResidual =
    Together[MatrixPower[operator, mode["GeneralizedLevel"] + 1].vector];
  minimalLevel = If[mode["GeneralizedLevel"] == 0,
    ! ExactZeroQ[vector],
    ! ExactZeroQ[MatrixPower[operator, mode["GeneralizedLevel"]].vector]
  ];
  mapped = Together[tTotal.hPrefactor.vector];
  positions = Flatten[FirstPosition[permutation, #] & /@
    mode["OriginalRows"]];
  selected = mapped[[positions]];
  orders = RationalOrder /@ selected;
  leading = MapThread[LeadingCoefficient, {selected, orders}];
  expectedOrder = localPower mode["IntegerValuation"];
  expectedLeading = endpointCoefficient^mode["IntegerValuation"];
  storedOrders = mode["OriginalRowLocalOrders"];
  storedLeading = mode["OriginalRowLeadingCoefficients"];
  checks = <|
    "ExactGeneralizedEigenvector" -> ExactZeroQ[nilpotentResidual],
    "MinimalGeneralizedLevel" -> minimalLevel,
    "IndependentMappedOrders" -> (orders === storedOrders),
    "IndependentLeadingCoefficients" ->
      ExactZeroQ[leading - storedLeading],
    "ExpectedValuationOccurs" -> MemberQ[orders, expectedOrder],
    "ExpectedNormalizationOccurs" ->
      MemberQ[Together /@ leading, Together[expectedLeading]]
  |>;
  <|
    "PeriodID" -> mode["PeriodID"],
    "OriginalRows" -> mode["OriginalRows"],
    "ComputedOrders" -> orders,
    "ComputedLeadingCoefficients" -> leading,
    "Checks" -> checks,
    "EveryCheckExact" -> And @@ Values[checks]
  |>
];

validations = ValidateMode /@ modeMap["Modes"];
result = <|
  "Format" -> "FeynFacetBoundaryModeValidation",
  "FormatVersion" -> 1,
  "Family" -> family["Family"],
  "Validations" -> validations,
  "Certificate" -> <|
    "IndependentReconstruction" -> True,
    "EveryModeExact" -> And @@ validations[[All, "EveryCheckExact"]]
  |>
|>;

Put[result, outputFile];
Print[Dataset[Map[
  KeyTake[#, {"PeriodID", "OriginalRows", "ComputedOrders",
    "ComputedLeadingCoefficients", "EveryCheckExact"}] &,
  validations
]]];
If[! result["Certificate", "EveryModeExact"], Exit[3]];
