BeginPackage["CodexTripleRootRank3Oracle`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootReconstruction`"}];

TRBuildCF300Rank3Oracle::usage =
  "TRBuildCF300Rank3Oracle[] constructs a nonzero identity-frame CF300 rank-3 strip using lambda2, lambda3 and 1-4 x y in every one of the eight root grades.";
TRCF300Rank3ExpectedVector::usage =
  "TRCF300Rank3ExpectedVector[oracle,preparation] packs the oracle gauge and residue in the preparation's canonical ABI.";
TRCF300Rank3ForcingGradeCoverage::usage =
  "TRCF300Rank3ForcingGradeCoverage[oracle,preparation] reports which canonical root grades occur nontrivially in the forcing.";
TRCF300Rank3SquareClassCertificate::usage =
  "TRCF300Rank3SquareClassCertificate[oracle] certifies that every nonempty product of the three root squares is nonsquare in Q(x,y).";

Begin["`Private`"];

trOracleZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Together[#1] === 0] &];

trNonsquarePolynomialQ[polynomial_, variables_List] := Module[
  {factored},
  If[! PolynomialQ[polynomial, variables] ||
      TrueQ[Expand[polynomial] === 0], Return[False]];
  factored = Rest[FactorList[polynomial]];
  AnyTrue[factored, OddQ[Last[#1]] &]
];

TRBuildCF300Rank3Oracle[] := Module[
  {x = Symbol["Global`x"], y = Symbol["Global`y"],
   epsilon = Symbol["Global`eps"], lambda2, lambda3, bilinear,
   rootLambda2, rootLambda3, rootBilinear, roots, denominator,
   support, channelNumerators, gaugeChannels, gauge, oneForms,
   residue, e, c, bbar, frame, record, normalizations},
  lambda2 = Expand[(1 + x - y)^2 + 4 x y];
  lambda3 = Expand[(1 - x + y)^2 + 4 x y];
  bilinear = Expand[1 - 4 x y];
  rootLambda2 = Sqrt[lambda2];
  rootLambda3 = Sqrt[lambda3];
  rootBilinear = Sqrt[bilinear];
  roots = {rootLambda2, rootLambda3, rootBilinear};
  denominator = 1 + x + y;
  support = {{0, 0}, {0, 1}, {1, 0}};
  (* Each numerator uses every support monomial and differs from the
     denominator, so all 24 gauge coefficients and every derivative
     grade are exercised.  Mask order is the (Z/2)^3 basis ABI. *)
  channelNumerators = Table[
    (2 mask + 2) + (2 mask + 3) x + (2 mask + 5) y,
    {mask, 0, 7}];
  gaugeChannels = Together[#1/denominator] & /@ channelNumerators;
  gauge = Total[Table[
    gaugeChannels[[mask + 1]] *
      CodexTripleRoot`TRMaskFactor[mask, roots],
    {mask, 0, 7}]];
  oneForms = {{1/x, 0}};
  residue = 37;
  e = {{{0}}, {{0}}};
  c = {{{0}}, {{0}}};
  bbar = {
    {{Together[D[gauge, x] + epsilon residue oneForms[[1, 1]]]}},
    {{Together[D[gauge, y] + epsilon residue oneForms[[1, 2]]]}}
  };
  frame = <|
    "Name" -> "CF300ConstructedIdentityFrameRank3",
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
    "Sector" -> "ConstructedRank3Oracle",
    "LowerSector" -> "ConstructedBoundary",
    "Variables" -> {x, y},
    "Regulator" -> epsilon,
    "Strip" -> {e, c, bbar}|>;
  normalizations = {<|
    "Kind" -> "GaugeCoefficient",
    "Upper" -> 1, "Lower" -> 1,
    "Grade" -> 0, "Monomial" -> {0, 0},
    "Value" -> 2|>};
  <|"Status" -> "ConstructedRank3Oracle",
    "Family" -> "CF300",
    "Record" -> record,
    "Frame" -> frame,
    "ActiveRootSquares" -> {lambda2, lambda3, bilinear},
    "Gauge" -> Together[gauge],
    "GaugeChannelsInCatalogOrder" -> gaugeChannels,
    "GaugeDenominator" -> denominator,
    "GaugeSupport" -> support,
    "OneForms" -> oneForms,
    "ResidueMatrices" -> {{{residue}}},
    "NormalizationEquations" -> normalizations,
    "UsesEveryRank3Grade" -> True,
    "Notes" -> "Constructed identity-frame rank-3 oracle over all three CF300 square classes; no rationalizing chart is used."|>
];

TRCF300Rank3ExpectedVector[oracle_Association,
    preparation_Association] := Module[
  {gauge, roots, channels, denominator, support, variables,
   dimensions, gradeCount, gaugeCoefficients, residues, vector},
  If[Lookup[oracle, "Status", None] =!= "ConstructedRank3Oracle" ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
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
  If[dimensions =!= {1, 1} || gradeCount =!= 8,
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

TRCF300Rank3ForcingGradeCoverage[oracle_Association,
    preparation_Association] := Module[
  {forcing, roots, channels, coverage},
  If[Lookup[oracle, "Status", None] =!= "ConstructedRank3Oracle" ||
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

TRCF300Rank3SquareClassCertificate[oracle_Association] := Module[
  {variables, squares, masks, products, nonsquare},
  If[Lookup[oracle, "Status", None] =!= "ConstructedRank3Oracle",
    Return[<|"Status" -> "InvalidOracle"|>]];
  variables = oracle["Record"]["Variables"];
  squares = oracle["ActiveRootSquares"];
  masks = Range[1, 7];
  products = Table[
    Expand[CodexTripleRoot`TRMaskFactor[mask, squares]], {mask, masks}];
  nonsquare = trNonsquarePolynomialQ[#1, variables] & /@ products;
  <|"Status" -> If[AllTrue[nonsquare, TrueQ],
      "IndependentSquareClasses", "DependentSquareClasses"],
    "Masks" -> masks,
    "Products" -> products,
    "Nonsquare" -> nonsquare,
    "Rank" -> If[AllTrue[nonsquare, TrueQ], 3, Missing["NotCertified"]]|>
];

End[];
EndPackage[];
