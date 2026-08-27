(* ::Package:: *)

(* External A3 prototype.  No FeynFacet definitions are changed. *)

ClearAll[
  CodexA3PolynomialTotalDegree,
  CodexA3InfinityDegree,
  CodexA3MaximumFinitePoleOrder,
  CodexA3PoleBoundPlan,
  CodexA3KeepColumns,
  CodexA3ReduceSystem,
  CodexA3ModRational,
  CodexA3OracleVector,
  CodexA3SparseLiftCandidate
];

CodexA3PolynomialTotalDegree[0, _List] := -Infinity;
CodexA3PolynomialTotalDegree[polynomial_, variables_List] := Module[
  {rules = CoefficientRules[Expand[polynomial], variables]},
  If[rules === {}, -Infinity, Max[Total /@ rules[[All, 1]]]]
];

CodexA3InfinityDegree[0, _List] := -Infinity;
CodexA3InfinityDegree[expression_, variables_List] := Module[{rational},
  rational = Cancel[Together[expression]];
  CodexA3PolynomialTotalDegree[Numerator[rational], variables] -
    CodexA3PolynomialTotalDegree[Denominator[rational], variables]
];

CodexA3MaximumFinitePoleOrder[expressions_List] := Module[{pairs},
  pairs = Flatten[
    Rest[FactorList[Denominator[Cancel[Together[#]]]]] & /@
      Flatten[expressions], 1];
  If[pairs === {}, 0, Max[pairs[[All, 2]]]]
];

CodexA3PoleBoundPlan[record_Association, preparation_Association,
    degreeOffset : {_Integer, _Integer}] := Module[
  {variables, epsilon, strip, e, c, bbar, alphabet, dlog,
   denominator, denominatorDegrees, numeratorDegrees, rectangle,
   forcingFactorPairs, forcingFactors, forcingPowers,
   expectedDenominator, denominatorRatio, forcingInfinityDegree,
   gaugeInfinityDegreeBound, denominatorTotalDegree,
   numeratorTotalDegreeBound, support, derivativeShifts,
   diagonalInfinityDegrees, dlogInfinityDegrees,
   diagonalFinitePoleOrder, dlogFinitePoleOrder, growthCounts,
   closureCertificate},
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  strip = record["Strip"];
  {e, c, bbar} = strip;
  alphabet = preparation["Alphabet"];
  dlog = Table[D[Log[alphabet[[a]]], variables[[mu]]],
    {a, Length[alphabet]}, {mu, 2}];
  denominator = preparation["GaugeDenominator"];
  denominatorDegrees = preparation["DenominatorDegrees"];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  rectangle = Flatten[Table[{px, py},
    {px, 0, numeratorDegrees[[1]]},
    {py, 0, numeratorDegrees[[2]]}], 1];

  forcingFactorPairs = Flatten[
    Rest[FactorList[Denominator[Cancel[Together[#]]]]] & /@
      Flatten[bbar], 1];
  forcingFactors = If[forcingFactorPairs === {}, {},
    DeleteDuplicates[forcingFactorPairs[[All, 1]], SameQ]];
  forcingPowers = Table[
    {factor, Max[Cases[forcingFactorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, forcingFactors}];
  expectedDenominator = Times @@
    ((First[#]^(Last[#] - 1)) & /@
      Select[forcingPowers,
        Last[#] > 1 &&
          ! FreeQ[First[#], Alternatives @@ variables] &]);
  denominatorRatio = Cancel[Together[
    denominator/expectedDenominator]];

  forcingInfinityDegree = Max[
    CodexA3InfinityDegree[#, variables] & /@ Flatten[bbar]];
  (* A first-order Fuchsian operator permits one more infinity order than
     the forcing; a homogeneous constant gauge supplies the floor at zero. *)
  gaugeInfinityDegreeBound = Max[0, forcingInfinityDegree + 1];
  denominatorTotalDegree =
    CodexA3PolynomialTotalDegree[denominator, variables];
  numeratorTotalDegreeBound =
    denominatorTotalDegree + gaugeInfinityDegreeBound;
  support = Select[rectangle,
    Total[#] <= numeratorTotalDegreeBound &];

  derivativeShifts = DeleteDuplicates[Flatten[Table[
    Select[{monomial - {1, 0}, monomial - {0, 1}},
      Min[#] >= 0 &], {monomial, support}], 1]];
  diagonalInfinityDegrees = DeleteCases[
    CodexA3InfinityDegree[#, variables] & /@ Flatten[{e, c}],
    -Infinity];
  dlogInfinityDegrees = DeleteCases[
    CodexA3InfinityDegree[#, variables] & /@ Flatten[dlog],
    -Infinity];
  diagonalFinitePoleOrder =
    CodexA3MaximumFinitePoleOrder[{e, c}];
  dlogFinitePoleOrder = CodexA3MaximumFinitePoleOrder[dlog];
  growthCounts = Table[Length[Select[rectangle,
      Total[#] <= bound &]],
    {bound, numeratorTotalDegreeBound, Total[numeratorDegrees]}];
  closureCertificate = <|
    "DerivativeShiftsContainedQ" ->
      SubsetQ[support, derivativeShifts],
    "DiagonalInfinityMaximum" -> Max[diagonalInfinityDegrees],
    "DiagonalInfinityLogarithmicQ" ->
      Max[diagonalInfinityDegrees] <= -1,
    "DLogInfinityMaximum" -> Max[dlogInfinityDegrees],
    "DLogInfinityLogarithmicQ" -> Max[dlogInfinityDegrees] <= -1,
    "DiagonalFinitePoleMaximum" -> diagonalFinitePoleOrder,
    "DiagonalFinitePolesAtMostSimpleQ" ->
      diagonalFinitePoleOrder <= 1,
    "DLogFinitePoleMaximum" -> dlogFinitePoleOrder,
    "DLogFinitePolesAtMostSimpleQ" -> dlogFinitePoleOrder <= 1,
    "FiniteForcingPoleBoundsReproduceGaugeDenominatorQ" ->
      FreeQ[denominatorRatio, Alternatives @@ variables],
    "FiniteForcingPoleBoundRatio" -> denominatorRatio
  |>;
  <|
    "DegreeOffset" -> degreeOffset,
    "GaugeDenominator" -> denominator,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "DenominatorTotalDegree" -> denominatorTotalDegree,
    "ForcingInfinityDegree" -> forcingInfinityDegree,
    "GaugeInfinityDegreeBound" -> gaugeInfinityDegreeBound,
    "NumeratorTotalDegreeBound" -> numeratorTotalDegreeBound,
    "RectangularSupport" -> rectangle,
    "RectangularSupportCount" -> Length[rectangle],
    "SparseSupport" -> support,
    "SparseSupportCount" -> Length[support],
    "GrowthLadderTotalDegreeBounds" ->
      Range[numeratorTotalDegreeBound, Total[numeratorDegrees]],
    "GrowthLadderSupportCounts" -> growthCounts,
    "RectangularFallbackCount" -> Length[rectangle],
    "ClosureCertificate" -> closureCertificate
  |>
];

CodexA3KeepColumns[gaugeDimensions : {_Integer, _Integer},
    rectangularSupport_List, sparseSupport_List,
    freeResidueCount_Integer] := Module[
  {entryCount, rectangularCount, sparsePositions, gaugeColumns,
   fullGaugeCount},
  entryCount = Times @@ gaugeDimensions;
  rectangularCount = Length[rectangularSupport];
  sparsePositions = Flatten[
    Position[rectangularSupport, #] & /@ sparseSupport];
  If[Length[sparsePositions] =!= Length[sparseSupport], Return[$Failed]];
  gaugeColumns = Flatten[Table[
    (entry - 1) rectangularCount + sparsePositions,
    {entry, entryCount}]];
  fullGaugeCount = entryCount rectangularCount;
  Join[gaugeColumns,
    fullGaugeCount + Range[freeResidueCount]]
];

CodexA3ReduceSystem[system_Association, keepColumns_List,
    pointCount_Integer, equationCount_Integer] := Module[
  {rowCount = pointCount equationCount},
  If[rowCount > Length[system["Matrix"]] ||
      Max[keepColumns] > Dimensions[system["Matrix"]][[2]],
    Return[$Failed]];
  <|
    "Prime" -> system["Prime"],
    "Matrix" -> system["Matrix"][[Range[rowCount], keepColumns]],
    "RightHandSide" -> system["RightHandSide"][[Range[rowCount]]],
    "PointCount" -> pointCount,
    "AcceptedPoints" -> Take[system["AcceptedPoints"], pointCount]
  |>
];

CodexA3ModRational[value_, prime_Integer] := Module[{denominator},
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[value] PowerMod[denominator, -1, prime], prime]
];

CodexA3OracleVector[record_Association, solution_Association,
    sparseSupport_List, epsilonValue_, prime_Integer] := Module[
  {variables, epsilon, denominator, numerators, gaugeValues,
   residueValues},
  variables = record["Variables"];
  epsilon = record["Regulator"];
  denominator = solution["GaugeDenominator"];
  numerators = Expand /@ Flatten[
    Map[Cancel[Together[# denominator]] &,
      solution["Gauge"], {2}]];
  gaugeValues = Flatten[Table[
    CodexA3ModRational[
      Coefficient[
        Coefficient[numerator, variables[[1]], monomial[[1]]],
        variables[[2]], monomial[[2]]] /. epsilon -> epsilonValue,
      prime],
    {numerator, numerators}, {monomial, sparseSupport}]];
  residueValues = CodexA3ModRational[# /. epsilon -> epsilonValue,
      prime] & /@ Flatten[solution["ResidueMatrices"]];
  If[MemberQ[Join[gaugeValues, residueValues], $Failed], $Failed,
    Join[gaugeValues, residueValues]]
];

CodexA3SparseLiftCandidate[record_Association, modularData_List,
    sparseSupport_List] := Module[
  {primes, coordinateCount, combinedModulus, combined, liftedPairs,
   liftedVector, variables, epsilon, bbar, dimensions,
   upperDimension, lowerDimension, gaugeUnknownCount, alphabet,
   residueCount, denominator, gauge, residueMatrices, entryIndex,
   liftingSeconds},
  primes = Lookup[modularData, "Prime", Missing["Prime"]];
  If[modularData === {} || ! DuplicateFreeQ[primes] ||
      ! AllTrue[primes, PrimeQ], Return[$Failed]];
  coordinateCount = Length[First[modularData]["Interpolations"]];
  combinedModulus = Times @@ primes;
  combined = Table[
    FeynFacet`Private`epsFormFiniteFieldCombineCoordinate[
      modularData[[All, "Interpolations", coordinate]], primes],
    {coordinate, coordinateCount}];
  If[MemberQ[combined, $Failed], Return[$Failed]];
  {liftingSeconds, liftedPairs} = AbsoluteTiming[Map[
    Function[data, <|
      "NumeratorCoefficients" ->
        (FeynFacet`Private`epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ data["Numerator"]),
      "DenominatorCoefficients" ->
        (FeynFacet`Private`epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ data["Denominator"])
    |>], combined]];
  If[! FreeQ[liftedPairs, $Failed], Return[$Failed]];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  bbar = record["Strip"][[3]];
  dimensions = Dimensions[bbar[[1]]];
  {upperDimension, lowerDimension} = dimensions;
  gaugeUnknownCount = Times @@ dimensions Length[sparseSupport];
  alphabet = FeynFacet`Private`epsFormStripAlphabet[
    record["Strip"], variables, epsilon];
  residueCount = Length[alphabet] Times @@ dimensions;
  If[coordinateCount =!= gaugeUnknownCount + residueCount,
    Return[$Failed]];
  liftedVector = Together[
      FromDigits[Reverse[#NumeratorCoefficients], epsilon]/
        FromDigits[Reverse[#DenominatorCoefficients], epsilon]] & /@
    liftedPairs;
  denominator = FeynFacet`Private`epsFormFiniteFieldGaugeDenominator[
    bbar, variables];
  entryIndex[i_, j_] := (i - 1) lowerDimension + j;
  gauge = Table[
    Sum[liftedVector[[(entryIndex[i, j] - 1) Length[sparseSupport] + k]]
        variables[[1]]^sparseSupport[[k, 1]]
        variables[[2]]^sparseSupport[[k, 2]],
      {k, Length[sparseSupport]}]/denominator,
    {i, upperDimension}, {j, lowerDimension}];
  residueMatrices = ArrayReshape[
    Drop[liftedVector, gaugeUnknownCount],
    {Length[alphabet], upperDimension, lowerDimension}];
  <|
    "Status" -> "SparseLiftedUnverified",
    "Gauge" -> gauge,
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "GaugeDenominator" -> denominator,
    "SparseSupport" -> sparseSupport,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> residueCount,
    "LiftingSeconds" -> liftingSeconds
  |>
];
