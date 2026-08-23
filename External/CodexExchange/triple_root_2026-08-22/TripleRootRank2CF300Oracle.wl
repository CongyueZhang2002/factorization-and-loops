BeginPackage["CodexTripleRootRank2Oracle`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootReconstruction`"}];

TRBuildCF300Rank2Oracle::usage =
  "TRBuildCF300Rank2Oracle[] constructs a nonzero identity-frame CF300 rank-2 strip using lambda3 and 1-4 x y, with all four root grades.";
TRCF300Rank2ExpectedVector::usage =
  "TRCF300Rank2ExpectedVector[oracle,preparation] packs the oracle gauge and residue in the preparation's canonical ABI.";
TRCF300Rank2ForcingGradeCoverage::usage =
  "TRCF300Rank2ForcingGradeCoverage[oracle,preparation] reports which canonical root grades occur nontrivially in the forcing.";

Begin["`Private`"];

trOracleZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Together[#1] === 0] &];

TRBuildCF300Rank2Oracle[] := Module[
  {x = Symbol["Global`x"], y = Symbol["Global`y"],
   epsilon = Symbol["Global`eps"], lambda2, lambda3, bilinear,
   rootLambda2, rootLambda3, rootBilinear, denominator, gauge,
   oneForms, residue, e, c, bbar, frame, record, support,
   normalizations},
  lambda2 = Expand[(1 + x - y)^2 + 4 x y];
  lambda3 = Expand[(1 - x + y)^2 + 4 x y];
  bilinear = Expand[1 - 4 x y];
  rootLambda2 = Sqrt[lambda2];
  rootLambda3 = Sqrt[lambda3];
  rootBilinear = Sqrt[bilinear];
  denominator = Expand[lambda3 bilinear];
  (* In canonical channels this is 2/Q plus three inverse-root terms.
     Every one of the four rank-2 grades is nonzero, and differentiating
     the last three terms exercises root logarithmic derivatives. *)
  gauge = 2/denominator + 3/rootLambda3 + 5/rootBilinear +
    7/(rootLambda3 rootBilinear);
  oneForms = {{1/x, 0}};
  residue = 11;
  e = {{{0}}, {{0}}};
  c = {{{0}}, {{0}}};
  bbar = {
    {{Together[D[gauge, x] + epsilon residue oneForms[[1, 1]]]}},
    {{Together[D[gauge, y] + epsilon residue oneForms[[1, 2]]]}}
  };
  frame = <|
    "Name" -> "CF300ConstructedIdentityFrame",
    "Kind" -> "TwoVariable",
    "FieldKind" -> "Multiquadratic",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y},
    "Subst" -> {x -> x, y -> y},
    "Root" -> rootLambda2,
    "RootSquare" -> lambda2,
    "Roots" -> {
      <|"Root" -> rootLambda2, "RootSquare" -> lambda2|>,
      <|"Root" -> rootLambda3, "RootSquare" -> lambda3|>,
      <|"Root" -> rootBilinear, "RootSquare" -> bilinear|>}
  |>;
  record = <|
    "Family" -> "CF300",
    "Sector" -> "ConstructedRank2Oracle",
    "LowerSector" -> "ConstructedBoundary",
    "Variables" -> {x, y},
    "Regulator" -> epsilon,
    "Strip" -> {e, c, bbar}|>;
  support = Sort[Flatten[Table[{i, j},
    {i, 0, Exponent[denominator, x]},
    {j, 0, Exponent[denominator, y]}], 1]];
  (* Fix the rational integration constant through one numerator
     coefficient.  This is boundary data, not an inferred obstruction. *)
  normalizations = {<|
    "Kind" -> "GaugeCoefficient",
    "Upper" -> 1, "Lower" -> 1,
    "Grade" -> 0, "Monomial" -> {0, 0},
    "Value" -> 2|>};
  <|"Status" -> "ConstructedRank2Oracle",
    "Family" -> "CF300",
    "Record" -> record,
    "Frame" -> frame,
    "ActiveRootSquares" -> {lambda3, bilinear},
    "InactiveCatalogRootSquare" -> lambda2,
    "Gauge" -> gauge,
    "GaugeDenominator" -> denominator,
    "GaugeSupport" -> support,
    "OneForms" -> oneForms,
    "ResidueMatrices" -> {{{residue}}},
    "NormalizationEquations" -> normalizations,
    "UsesEveryRank2Grade" -> True,
    "UsesInverseRoots" -> True,
    "Notes" -> "Identity-frame rank-2 oracle. No joint rational chart is used or required; this does not claim that no such chart exists."|>
];

TRCF300Rank2ExpectedVector[oracle_Association,
    preparation_Association] := Module[
  {gauge, roots, channels, denominator, support, variables,
   dimensions, gradeCount, gaugeCoefficients, residues, vector},
  If[Lookup[oracle, "Status", None] =!= "ConstructedRank2Oracle" ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidOracleOrPreparation"|>]];
  gauge = oracle["Gauge"];
  roots = preparation["Roots"];
  channels = CodexTripleRootStrip`TRFieldDecompose[gauge, roots];
  If[channels === $Failed,
    Return[<|"Status" -> "OracleGaugeDecompositionFailed"|>]];
  denominator = preparation["GaugeDenominator"];
  support = preparation["GaugeSupport"];
  variables = preparation["Variables"];
  dimensions = preparation["Dimensions"];
  gradeCount = preparation["GradeCount"];
  If[dimensions =!= {1, 1} || gradeCount =!= 4,
    Return[<|"Status" -> "OraclePreparationShapeMismatch",
      "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>]];
  gaugeCoefficients = Flatten[Table[
    Coefficient[
      Coefficient[Expand[Together[channels[[grade]] denominator]],
        variables[[1]], support[[monomial, 1]]],
      variables[[2]], support[[monomial, 2]]],
    {grade, gradeCount}, {monomial, Length[support]}]];
  If[! AllTrue[Table[
      TrueQ[Together[channels[[grade]] -
        Sum[gaugeCoefficients[[(grade - 1) Length[support] + monomial]] *
          variables[[1]]^support[[monomial, 1]] *
          variables[[2]]^support[[monomial, 2]],
          {monomial, Length[support]}]/denominator] === 0],
      {grade, gradeCount}], TrueQ],
    Return[<|"Status" -> "OracleGaugeOutsideSupport"|>]];
  residues = Flatten[oracle["ResidueMatrices"]];
  vector = Join[gaugeCoefficients, residues];
  If[Length[vector] =!= preparation["UnknownCount"],
    Return[<|"Status" -> "OracleVectorLengthMismatch",
      "Expected" -> preparation["UnknownCount"],
      "Observed" -> Length[vector]|>]];
  <|"Status" -> "ExpectedOracleVector",
    "Vector" -> Together /@ vector,
    "GaugeChannels" -> channels,
    "Residues" -> oracle["ResidueMatrices"]|>
];

TRCF300Rank2ForcingGradeCoverage[oracle_Association,
    preparation_Association] := Module[
  {forcing, roots, channels, coverage},
  If[Lookup[oracle, "Status", None] =!= "ConstructedRank2Oracle" ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidOracleOrPreparation"|>]];
  forcing = oracle["Record"]["Strip"][[3]];
  roots = preparation["Roots"];
  channels = Map[
    CodexTripleRootStrip`TRFieldDecompose[#1, roots] &, forcing, {3}];
  If[! FreeQ[channels, $Failed],
    Return[<|"Status" -> "OracleForcingDecompositionFailed"|>]];
  coverage = Table[
    ! trOracleZeroQ[channels[[All, All, All, grade]]],
    {grade, preparation["GradeCount"]}];
  <|"Status" -> "OracleForcingGradeCoverage",
    "Coverage" -> coverage,
    "AllGradesNonzero" -> AllTrue[coverage, TrueQ]|>
];

End[];
EndPackage[];
