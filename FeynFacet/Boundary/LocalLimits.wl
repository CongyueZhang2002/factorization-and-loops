
(* Local homogeneous block analysis at a declared smooth boundary.
   This uses a general residue R(epsilon), not an epsilon-form assumption.
   Algebraic multiplicities are retained: a repeated eigenvalue does not
   identify two integration constants. Higher poles that cannot be removed
   by a diagonal integer-power gauge are reported without a mode count. *)
Clear[ConstructHomogeneousBlockLimits, BoundBoundaryDataByScaling];
ClearAll[boundaryBlockDiagonalGauge, boundaryBlockObservability, boundaryBlockJointObservability];

boundaryBlockDiagonalGauge[a_, z_] := Module[
  {n, positions, values, orders, shifts, changed, i, j, next, residue},
  n = Length[a];
  positions = Select[Tuples[Range[n], 2], Extract[a, #] =!= 0 &];
  values = Extract[a, positions];
  If[! AllTrue[values, PolynomialQ[Numerator[#], z] &&
      PolynomialQ[Denominator[#], z] &], Return[None]];
  orders = (Exponent[Denominator[#], z, Min] -
    Exponent[Numerator[#], z, Min] &) /@ values;
  shifts = ConstantArray[0, n]; changed = False;
  Do[
    changed = False;
    Do[
      i = positions[[k, 1]]; j = positions[[k, 2]];
      next = shifts[[j]] + orders[[k]] - 1;
      If[shifts[[i]] < next, shifts[[i]] = next; changed = True],
      {k, Length[positions]}];
    If[!changed, Break[]], {n + 1}];
  If[changed, Return[None]];
  residue = DiagonalMatrix[shifts];
  Do[
    If[orders[[k]] === shifts[[positions[[k, 1]]]] -
        shifts[[positions[[k, 2]]]] + 1,
      residue[[Sequence@@positions[[k]]]] +=
        (Cancel[z^orders[[k]] values[[k]]] /. z -> 0)],
    {k, Length[positions]}];
  <|"DiagonalPowers" -> shifts, "Residue" -> residue|>
];

ConstructHomogeneousBlockLimits[system_Association, chart_Association] :=
 Catch@Module[{vars, z, epsilon, rules, fixed, connection, n, positions,
   components, records, a, gauge, polynomial, factors, exponents, degree,
   value, slope, lambda, count, fail, originalConnections},
  fail[tag_] := Throw[Failure[tag, <||>]];
  vars = system["KinematicVariables"]; epsilon = system["DimensionalRegulator"];
  z = Lookup[chart, "NormalVariable", None];
  rules = Lookup[chart, "CoordinateSubstitution", None];
  fixed = Lookup[chart, "TangentialPointRules", {}];
  If[! MatchQ[z, _Symbol] || ! MatchQ[rules, {__Rule}] ||
      (First /@ rules) =!= vars, fail["BoundaryChartRequired"]];
  connection = Together /@ Total[MapThread[Times,
    {D[Last /@ rules, z], Normal /@ system["ConnectionMatrices"]}]] /. rules /. fixed;
  connection = Together /@ connection;
  n = Length[connection];
  If[! MatrixQ[connection] || Dimensions[connection] =!= {n, n},
    fail["SquareNormalConnectionRequired"]];
  originalConnections = Together /@ (Normal /@ system["ConnectionMatrices"]);
  positions = Union@@(Position[#, value_ /; value =!= 0, {2}, Heads -> False] & /@ originalConnections);
  components = ConnectedComponents[Graph[Range[n], DirectedEdge@@# & /@ positions]];
  records = Table[
    a = connection[[rows, rows]]; gauge = boundaryBlockDiagonalGauge[a, z];
    If[gauge === None,
      <|"Rows" -> rows, "Dimension" -> Length[rows],
        "Status" -> "NondiagonalLocalGaugeRequired",
        "NormalHomogeneousConnection" -> a,
        "OriginalHomogeneousConnections" -> (#[[rows, rows]] & /@ originalConnections)|>,
      polynomial = Together[CharacteristicPolynomial[gauge["Residue"], lambda]];
      factors = FactorList[Numerator[polynomial]];
      exponents = Flatten[Map[Function[factor,
        degree = Exponent[First[factor], lambda];
        Which[degree === 0, {},
          degree === 1,
            value = Cancel[-Coefficient[First[factor], lambda, 0]/
              Coefficient[First[factor], lambda, 1]];
            slope = If[PolynomialQ[value, epsilon] && Exponent[value, epsilon] <= 1,
              Coefficient[value, epsilon, 1], Missing["NonlinearRegulatorDependence"]];
            {<|"Value" -> value, "AlgebraicMultiplicity" -> Last[factor],
              "EpsilonSlope" -> slope|>},
          True, {<|"CharacteristicFactor" -> First[factor],
            "AlgebraicMultiplicity" -> degree Last[factor],
            "EpsilonSlope" -> Missing["AlgebraicExponents"]|>}]], factors], 1];
      count = Total[Lookup[exponents, "AlgebraicMultiplicity"]];
      If[count =!= Length[rows], fail["CharacteristicFactorizationIncomplete"]];
      <|"Rows" -> rows, "Dimension" -> Length[rows],
        "Status" -> "RegularSingularHomogeneousBlock",
        "NormalHomogeneousConnection" -> a,
        "OriginalHomogeneousConnections" -> (#[[rows, rows]] & /@ originalConnections),
        "DiagonalGaugePowers" -> gauge["DiagonalPowers"],
        "GaugeConvention" -> "F=DiagonalMatrix[z^DiagonalGaugePowers].G",
        "Residue" -> gauge["Residue"], "Exponents" -> exponents|>],
    {rows, components}];
  <|"DataType" -> "HomogeneousBoundaryBlockLimits", "SchemaVersion" -> 1,
    "NormalVariable" -> z, "DimensionalRegulator" -> epsilon,
    "OriginalKinematicVariables" -> vars,
    "Chart" -> chart, "MasterIntegralBasis" -> system["MasterIntegralBasis"],
    "Blocks" -> records, "Dimension" -> n,
    "Scope" -> "Homogeneous freedom of each diagonal block with lower sectors fixed. No physical mode has been removed."|>
];

boundaryBlockObservability[a_, initialRows_, z_, point_] := Module[
  {n = Length[a], rows, candidates, image, pivots, rank, oldRank = -1},
  rows = IdentityMatrix[n][[initialRows]];
  If[rows === {}, Return[<|"FullRank" -> False, "Rank" -> 0|>]];
  Do[
    image = rows /. point;
    If[! AllTrue[Flatten[image], MatchQ[#, _Integer | _Rational] &],
      Return[<|"FullRank" -> False, "Status" -> "InvalidRationalPoint"|>]];
    pivots = globalDEIndependentRows[image]; rank = Length[pivots];
    rows = rows[[pivots]];
    If[rank === n || rank === oldRank, Break[]]; oldRank = rank;
    candidates = D[rows, z] + rows.a;
    rows = Join[rows, Together /@ candidates],
    {n + 1}];
  <|"FullRank" -> (rank === n), "Rank" -> rank,
    "Method" -> "ExactRationalDifferentialRowSpan",
    "Point" -> point, "IndependentRowsAtPoint" -> (rows /. point)|>
];


boundaryBlockJointObservability[connections_, variables_, initialRows_, point_] := Module[
  {n = Length[First[connections]], rows, candidates, image, pivots, rank, oldRank = -1},
  rows = IdentityMatrix[n][[initialRows]];
  If[rows === {}, Return[<|"FullRank" -> False, "Rank" -> 0|>]];
  Do[
    image = rows /. point;
    If[! AllTrue[Flatten[image], MatchQ[#, _Integer | _Rational] &],
      Return[<|"FullRank" -> False, "Status" -> "InvalidRationalPoint"|>]];
    pivots = globalDEIndependentRows[image]; rank = Length[pivots];
    rows = rows[[pivots]];
    If[rank === n || rank === oldRank, Break[]]; oldRank = rank;
    candidates = Join@@Table[
      Together /@ (D[rows, variables[[q]]] + rows.connections[[q]]),
      {q, Length[variables]}];
    rows = Join[rows, candidates],
    {n + 1}];
  <|"FullRank" -> (rank === n), "Rank" -> rank,
    "Method" -> "ExactRationalNormalAndTangentialDifferentialRowSpan",
    "Point" -> point, "IndependentRowsAtPoint" -> (rows /. point)|>
];

(* A scaling condition is a mathematical input, with its justification,
   not a mode inferred solely from a residue. Unobserved blocks and unresolved
   exponents retain their entire freedom. The bound does not supply the
   connection matrix or identify the number of new limiting integrals. *)
BoundBoundaryDataByScaling[limits_Association, conditions_Association,
    point_List] := Module[
  {z = limits["NormalVariable"], blocks, selected, observation, cutoff, retained,
   rows, records, eligible, originalPoint},
  eligible = Lookup[conditions, "MasterRows", {}];
  cutoff = Lookup[conditions, "MaximumEpsilonSlope", None];
  If[! VectorQ[eligible, IntegerQ] || ! MatchQ[cutoff, _Integer | _Rational] ||
      ! KeyExistsQ[conditions, "Justification"],
    Return[Failure["PhysicalScalingConditionRequired", <||>]]];
  records = Table[
    rows = block["Rows"];
    selected = Select[Range[Length[rows]], MemberQ[eligible, rows[[#]]] &];
    observation = boundaryBlockObservability[
      block["NormalHomogeneousConnection"], selected, z, point];
    If[!TrueQ[observation["FullRank"]] &&
        TrueQ[Lookup[conditions,"UniformInTangentialNeighborhood",False]],
      originalPoint = Join[
        Thread[limits["OriginalKinematicVariables"] ->
          (Last /@ limits["Chart"]["CoordinateSubstitution"] /.
            Lookup[limits["Chart"],"TangentialPointRules",{}] /. point)], point];
      observation = boundaryBlockJointObservability[
        block["OriginalHomogeneousConnections"],
        limits["OriginalKinematicVariables"], selected, originalPoint]];

    retained = If[block["Status"] === "RegularSingularHomogeneousBlock" &&
        TrueQ[observation["FullRank"]],
      Total[(If[MatchQ[#["EpsilonSlope"], _Integer | _Rational] &&
          #["EpsilonSlope"] > cutoff, 0, #["AlgebraicMultiplicity"]] &) /@
        block["Exponents"]],
      block["Dimension"]];
    <|"Rows" -> rows, "Dimension" -> block["Dimension"],
      "RetainedHomogeneousDimensionBound" -> retained,
      "Observation" -> observation|>,
    {block, limits["Blocks"]}];
  <|"DataType" -> "BoundaryHomogeneousDimensionBound", "SchemaVersion" -> 1,
    "InputDimension" -> limits["Dimension"],
    "RemainingDimensionUpperBound" ->
      Total[Lookup[records, "RetainedHomogeneousDimensionBound"]],
    "PhysicalScalingCondition" -> conditions, "Blocks" -> records,
    "OrdinaryPointConstantsSubstituted" -> False,
    "BoundaryIntegralEvaluationCountDetermined" -> False|>
];
