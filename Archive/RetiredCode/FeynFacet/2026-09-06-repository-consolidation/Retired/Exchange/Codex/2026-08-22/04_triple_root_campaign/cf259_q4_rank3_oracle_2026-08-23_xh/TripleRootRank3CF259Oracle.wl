BeginPackage["CodexTripleRootRank3CF259Oracle`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootReconstruction`"}];

TRBuildCF259Q4Rank3Oracle::usage =
  "TRBuildCF259Q4Rank3Oracle[] constructs a nonzero identity-frame rank-3 strip over CF259's ordered square classes lambda1, lambda3 and 4 x + y^2.";
TRCF259Q4Rank3ExpectedVector::usage =
  "TRCF259Q4Rank3ExpectedVector[oracle,preparation] packs the oracle gauge and residue in the preparation's canonical ABI.";
TRCF259Q4Rank3ForcingGradeCoverage::usage =
  "TRCF259Q4Rank3ForcingGradeCoverage[oracle,preparation] reports which canonical root grades occur nontrivially in the forcing.";
TRCF259Q4Rank3SquareClassCertificate::usage =
  "TRCF259Q4Rank3SquareClassCertificate[oracle] certifies that every nonempty product of the three CF259 root squares is nonsquare in Q(x,y).";

Begin["`Private`"];

trOracleZeroQ[expression_] :=
  AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];

trNonsquarePolynomialQ[polynomial_, variables_List] := Module[
  {factors},
  If[! PolynomialQ[polynomial, variables] ||
      TrueQ[Expand[polynomial] === 0], Return[False]];
  factors = Rest[FactorList[polynomial]];
  AnyTrue[factors, OddQ[Last[#]] &]
];

TRBuildCF259Q4Rank3Oracle[] := Module[
  {x = Symbol["Global`x"], y = Symbol["Global`y"],
   epsilon = Symbol["Global`eps"], lambda1, lambda3, q4,
   rootLambda1, rootLambda3, rootQ4, roots, denominator, support,
   channelNumerators, gaugeChannels, gauge, oneForms, residue,
   e, c, bbar, frame, record, normalizations},
  lambda1 = Expand[(1 - x - y)^2 - 4 x y];
  lambda3 = Expand[(1 - x + y)^2 + 4 x y];
  q4 = Expand[4 x + y^2];
  rootLambda1 = Sqrt[lambda1];
  rootLambda3 = Sqrt[lambda3];
  rootQ4 = Sqrt[q4];
  roots = {rootLambda1, rootLambda3, rootQ4};
  denominator = 1 + x + y;
  support = {{0, 0}, {0, 1}, {1, 0}};
  (* Every channel uses every support monomial.  Q4 is the third grade
     generator, so masks 4--7 exercise the new CF259 square class. *)
  channelNumerators = Table[
    (3 mask + 2) + (3 mask + 5) x + (3 mask + 7) y,
    {mask, 0, 7}];
  gaugeChannels = Together[#/denominator] & /@ channelNumerators;
  gauge = Total[Table[
    gaugeChannels[[mask + 1]] *
      CodexTripleRoot`TRMaskFactor[mask, roots],
    {mask, 0, 7}]];
  oneForms = {{1/x, 0}};
  residue = 43;
  e = {{{0}}, {{0}}};
  c = {{{0}}, {{0}}};
  bbar = {
    {{Together[D[gauge, x] + epsilon residue oneForms[[1, 1]]]}},
    {{Together[D[gauge, y] + epsilon residue oneForms[[1, 2]]]}}
  };
  frame = <|
    "Name" -> "CF259ConstructedIdentityFrameRank3Q4",
    "Kind" -> "TwoVariable",
    "FieldKind" -> "Multiquadratic",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y},
    "Subst" -> {x -> x, y -> y},
    "Root" -> rootLambda1,
    "RootSquare" -> lambda1,
    "Roots" -> {
      <|"Root" -> rootLambda1, "RootSquare" -> lambda1,
        "SourceIndex" -> 1|>,
      <|"Root" -> rootLambda3, "RootSquare" -> lambda3,
        "SourceIndex" -> 3|>,
      <|"Root" -> rootQ4, "RootSquare" -> q4,
        "SourceIndex" -> 4|>}
  |>;
  record = <|
    "Family" -> "CF259",
    "Sector" -> "ConstructedRank3Q4Oracle",
    "LowerSector" -> "ConstructedBoundary",
    "Variables" -> {x, y},
    "Regulator" -> epsilon,
    "Strip" -> {e, c, bbar}|>;
  normalizations = {<|
    "Kind" -> "GaugeCoefficient",
    "Upper" -> 1, "Lower" -> 1,
    "Grade" -> 0, "Monomial" -> {0, 0},
    "Value" -> 2|>};
  <|
    "Status" -> "ConstructedCF259Q4Rank3Oracle",
    "Family" -> "CF259",
    "Record" -> record,
    "Frame" -> frame,
    "ActiveRootSquares" -> {lambda1, lambda3, q4},
    "Gauge" -> Together[gauge],
    "GaugeChannelsInCatalogOrder" -> gaugeChannels,
    "GaugeDenominator" -> denominator,
    "GaugeSupport" -> support,
    "OneForms" -> oneForms,
    "ResidueMatrices" -> {{{residue}}},
    "NormalizationEquations" -> normalizations,
    "UsesEveryRank3Grade" -> True,
    "Notes" -> "Constructed identity-frame rank-3 oracle over CF259 lambda1, lambda3 and Q4=4 x+y^2; no rationalizing chart is used."|>
];

TRCF259Q4Rank3ExpectedVector[oracle_Association,
    preparation_Association] := Module[
  {gauge, roots, channels, denominator, support, variables,
   dimensions, gradeCount, gaugeCoefficients, residues, vector},
  If[Lookup[oracle, "Status", None] =!=
        "ConstructedCF259Q4Rank3Oracle" ||
      Lookup[preparation, "Status", None] =!=
        "PreparedReconstruction" ||
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
      Coefficient[
        Expand[Together[channels[[grade]] denominator]],
        variables[[1]], support[[monomial, 1]]],
      variables[[2]], support[[monomial, 2]]],
    {grade, gradeCount}, {monomial, Length[support]}]];
  If[! AllTrue[Table[
      TrueQ[Together[channels[[grade]] -
        Sum[gaugeCoefficients[[
            (grade - 1) Length[support] + monomial]] *
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
      "Actual" -> Length[vector]|>]];
  <|"Status" -> "ExpectedOracleVector",
    "Vector" -> Together /@ vector,
    "GaugeChannels" -> channels,
    "Residues" -> oracle["ResidueMatrices"]|>
];

TRCF259Q4Rank3ForcingGradeCoverage[oracle_Association,
    preparation_Association] := Module[
  {forcing, roots, channels, coverage},
  If[Lookup[oracle, "Status", None] =!=
        "ConstructedCF259Q4Rank3Oracle" ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidOracleOrPreparation"|>]];
  forcing = oracle["Record"]["Strip"][[3]];
  roots = preparation["Roots"];
  channels = Map[
    CodexTripleRootStrip`TRFieldDecompose[#, roots] &, forcing, {3}];
  If[! FreeQ[channels, $Failed],
    Return[<|"Status" -> "OracleForcingDecompositionFailed"|>]];
  coverage = Table[
    ! trOracleZeroQ[channels[[All, All, All, grade]]],
    {grade, preparation["GradeCount"]}];
  <|"Status" -> "OracleForcingGradeCoverage",
    "Coverage" -> coverage,
    "AllGradesNonzero" -> AllTrue[coverage, TrueQ]|>
];

TRCF259Q4Rank3SquareClassCertificate[oracle_Association] := Module[
  {variables, squares, masks, products, nonsquare, factorLists},
  If[Lookup[oracle, "Status", None] =!=
      "ConstructedCF259Q4Rank3Oracle",
    Return[<|"Status" -> "InvalidOracle"|>]];
  variables = oracle["Record"]["Variables"];
  squares = oracle["ActiveRootSquares"];
  masks = Range[1, 7];
  products = Table[
    Expand[CodexTripleRoot`TRMaskFactor[mask, squares]],
    {mask, masks}];
  nonsquare = trNonsquarePolynomialQ[#, variables] & /@ products;
  factorLists = FactorList /@ products;
  <|"Status" -> If[AllTrue[nonsquare, TrueQ],
      "IndependentSquareClasses", "DependentSquareClasses"],
    "Masks" -> masks,
    "Products" -> products,
    "FactorLists" -> factorLists,
    "Nonsquare" -> nonsquare,
    "Rank" -> If[AllTrue[nonsquare, TrueQ], 3,
      Missing["NotCertified"]]|>
];

End[];
EndPackage[];
