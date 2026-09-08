BeginPackage["CodexTripleRootPilot`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`"}];

TRSplitPointRows::usage =
  "TRSplitPointRows[record, roots, oneForms, denominator, support, epsValue, prime, point] builds all 2^r conjugate equations at one split point.";
TRSampleAffinePilot::usage =
  "TRSampleAffinePilot[record, frame, epsValue, prime] constructs and checks one coupled multiquadratic modular affine system.";

Begin["`Private`"];

trModNumber[value_, prime_Integer] := Module[
  {rational = Together[value], numerator, denominator},
  If[! MatchQ[rational, _Integer | _Rational], Return[$Failed]];
  numerator = Mod[Numerator[rational], prime];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

trBranchValue[expression_, variables_List, epsilon_Symbol,
    point_List, epsilonValue_, roots_List, rootValues_List,
    signs_List, prime_Integer] := Module[{branched},
  branched = CodexTripleRootStrip`TRApplyRootBranches[
    expression, roots, Mod[signs rootValues, prime]];
  trModNumber[
    branched /. Thread[variables -> point] /. epsilon -> epsilonValue,
    prime]
];

trMatrixBranchValue[matrix_List, variables_List, epsilon_Symbol,
    point_List, epsilonValue_, roots_List, rootValues_List,
    signs_List, prime_Integer] :=
  Map[trBranchValue[#1, variables, epsilon, point, epsilonValue,
    roots, rootValues, signs, prime] &, matrix, {2}];

trPairBranchValue[pair_List, variables_List, epsilon_Symbol,
    point_List, epsilonValue_, roots_List, rootValues_List,
    signs_List, prime_Integer] :=
  trMatrixBranchValue[#1, variables, epsilon, point, epsilonValue,
    roots, rootValues, signs, prime] & /@ pair;

trScalarPairBranchValue[pair : {_, _}, variables_List,
    epsilon_Symbol, point_List, epsilonValue_, roots_List,
    rootValues_List, signs_List, prime_Integer] :=
  trBranchValue[#1, variables, epsilon, point, epsilonValue,
    roots, rootValues, signs, prime] & /@ pair;

trParity[mask_Integer, rank_Integer] :=
  Mod[Total[BitGet[mask, Range[0, rank - 1]]], 2];

trCharacter[signMask_Integer, grade_Integer, rank_Integer] :=
  If[trParity[BitAnd[signMask, grade], rank] === 0, 1, -1];

Options[TRSplitPointRows] = {};

TRSplitPointRows[record_Association, roots_List, oneForms_List,
    gaugeDenominator_, support_List, epsilonValue_, prime_Integer,
    point : {_, _}, OptionsPattern[]] := Catch[Module[
  {variables = record["Variables"], epsilon = record["Regulator"],
   strip = record["Strip"], e, c, bbar, dimensions,
   upperDimension, lowerDimension, rank = Length[roots], gradeCount,
   supportCount = Length[support], gaugeUnknownCount,
   residueUnknownCount, unknownCount, epsilonMod, deltaValues,
   rootValues, denominatorValue, denominatorDerivatives,
   deltaLogDerivatives, rootProducts, basisValues, basisDerivatives,
   eValues, cValues, bbarValues, oneFormValues, rows = {}, right = {},
   signs, signMask, mu, i, j, a, b, grade, monomial,
   xPower, yPower, monomialValue, monomialLogDerivative,
   basisValue, row, add, gaugeIndex, residueIndex, value},
  {e, c, bbar} = strip;
  dimensions = Dimensions[bbar[[1]]];
  If[Length[dimensions] =!= 2 || Dimensions[bbar[[2]]] =!= dimensions,
    Throw[$Failed]];
  {upperDimension, lowerDimension} = dimensions;
  gradeCount = 2^rank;
  gaugeUnknownCount = upperDimension lowerDimension gradeCount supportCount;
  residueUnknownCount = Length[oneForms] upperDimension lowerDimension;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  epsilonMod = trModNumber[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0, Throw[$Failed]];
  deltaValues = trModNumber[#1 /. Thread[variables -> point], prime] & /@
    Lookup[roots, "RootSquare", {}];
  If[MemberQ[deltaValues, $Failed | 0] ||
      ! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Throw[$Failed]];
  rootValues = CodexTripleRoot`TRSquareRoots[deltaValues, prime];
  If[rootValues === $Failed, Throw[$Failed]];
  denominatorValue = trModNumber[
    gaugeDenominator /. Thread[variables -> point] /.
      epsilon -> epsilonValue, prime];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Throw[$Failed]];
  denominatorDerivatives = trModNumber[
      D[gaugeDenominator, #1] /. Thread[variables -> point] /.
        epsilon -> epsilonValue, prime] & /@ variables;
  If[MemberQ[denominatorDerivatives, $Failed], Throw[$Failed]];
  deltaLogDerivatives = Table[
    value = trModNumber[
      D[roots[[grade, "RootSquare"]], variables[[mu]]] /
        roots[[grade, "RootSquare"]] /.
        Thread[variables -> point], prime];
    If[value === $Failed, Throw[$Failed]];
    value,
    {grade, rank}, {mu, 2}];
  rootProducts = CodexTripleRoot`TRMaskFactor[#1, rootValues] & /@
    Range[0, gradeCount - 1];
  basisValues = ConstantArray[0, {gradeCount, gradeCount, supportCount}];
  basisDerivatives = ConstantArray[0,
    {2, gradeCount, gradeCount, supportCount}];
  Do[
    signs = Table[If[BitGet[signMask, grade - 1] === 0, 1, -1],
      {grade, rank}];
    Do[
      {xPower, yPower} = support[[monomial]];
      monomialValue = Mod[
        PowerMod[Mod[point[[1]], prime], xPower, prime]
        PowerMod[Mod[point[[2]], prime], yPower, prime], prime];
      basisValue = Mod[
        trCharacter[signMask, grade, rank] rootProducts[[grade + 1]]
          monomialValue PowerMod[denominatorValue, -1, prime], prime];
      basisValues[[signMask + 1, grade + 1, monomial]] = basisValue;
      Do[
        monomialLogDerivative = If[mu === 1,
          If[xPower === 0, 0, Mod[xPower PowerMod[Mod[point[[1]], prime], -1, prime], prime]],
          If[yPower === 0, 0, Mod[yPower PowerMod[Mod[point[[2]], prime], -1, prime], prime]]];
        value = Mod[monomialLogDerivative -
          denominatorDerivatives[[mu]] PowerMod[denominatorValue, -1, prime] +
          PowerMod[2, -1, prime] Sum[
            If[BitGet[grade, a - 1] === 1,
              deltaLogDerivatives[[a, mu]], 0], {a, rank}], prime];
        basisDerivatives[[mu, signMask + 1, grade + 1, monomial]] =
          Mod[basisValue value, prime],
        {mu, 2}],
      {grade, 0, gradeCount - 1}, {monomial, supportCount}],
    {signMask, 0, gradeCount - 1}];
  eValues = Table[
    signs = Table[If[BitGet[signMask, grade - 1] === 0, 1, -1],
      {grade, rank}];
    trPairBranchValue[e, variables, epsilon, point, epsilonValue,
      roots, rootValues, signs, prime],
    {signMask, 0, gradeCount - 1}];
  cValues = Table[
    signs = Table[If[BitGet[signMask, grade - 1] === 0, 1, -1],
      {grade, rank}];
    trPairBranchValue[c, variables, epsilon, point, epsilonValue,
      roots, rootValues, signs, prime],
    {signMask, 0, gradeCount - 1}];
  bbarValues = Table[
    signs = Table[If[BitGet[signMask, grade - 1] === 0, 1, -1],
      {grade, rank}];
    trPairBranchValue[bbar, variables, epsilon, point, epsilonValue,
      roots, rootValues, signs, prime],
    {signMask, 0, gradeCount - 1}];
  oneFormValues = Table[
    signs = Table[If[BitGet[signMask, grade - 1] === 0, 1, -1],
      {grade, rank}];
    trScalarPairBranchValue[oneForms[[a]], variables, epsilon,
      point, epsilonValue, roots, rootValues, signs, prime],
    {signMask, 0, gradeCount - 1}, {a, Length[oneForms]}];
  If[! FreeQ[{eValues, cValues, bbarValues, oneFormValues}, $Failed],
    Throw[$Failed]];
  gaugeIndex[ii_, jj_, gg_, mm_] :=
    (((ii - 1) lowerDimension + (jj - 1)) gradeCount + gg) supportCount + mm;
  residueIndex[letter_, ii_, jj_] := gaugeUnknownCount +
    ((letter - 1) upperDimension + (ii - 1)) lowerDimension + jj;
  Do[
    row = <||>;
    add[column_, coefficient_] := Module[{updated},
      updated = Mod[Lookup[row, column, 0] + coefficient, prime];
      If[updated === 0, KeyDropFrom[row, column],
        AssociateTo[row, column -> updated]]];
    Do[
      add[gaugeIndex[i, j, grade, monomial],
        basisDerivatives[[mu, signMask + 1, grade + 1, monomial]]];
      Do[
        add[gaugeIndex[a, j, grade, monomial],
          -epsilonMod eValues[[signMask + 1, mu, i, a]]
            basisValues[[signMask + 1, grade + 1, monomial]]],
        {a, upperDimension}];
      Do[
        add[gaugeIndex[i, b, grade, monomial],
          epsilonMod cValues[[signMask + 1, mu, b, j]]
            basisValues[[signMask + 1, grade + 1, monomial]]],
        {b, lowerDimension}],
      {grade, 0, gradeCount - 1}, {monomial, supportCount}];
    Do[
      add[residueIndex[a, i, j],
        epsilonMod oneFormValues[[signMask + 1, a, mu]]],
      {a, Length[oneForms]}];
    AppendTo[rows, SparseArray[Normal[row], unknownCount]];
    AppendTo[right, bbarValues[[signMask + 1, mu, i, j]]],
    {signMask, 0, gradeCount - 1}, {mu, 2},
    {i, upperDimension}, {j, lowerDimension}];
  <|"Point" -> point, "DeltaValues" -> deltaValues,
    "RootValues" -> rootValues, "Rows" -> rows,
    "RightHandSide" -> right, "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "EquationCount" -> Length[rows]|>
]];

Options[TRSampleAffinePilot] = {
  "OneForms" -> Automatic,
  "GaugeDenominator" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  "PointCount" -> Automatic,
  "RandomSeed" -> 20260822,
  "MaximumAttempts" -> Automatic,
  "Solve" -> True,
  "Verbose" -> True
};

TRSampleAffinePilot[record_Association, frame_Association,
    epsilonValue_, prime_Integer, OptionsPattern[]] := Module[
  {classification, roots, strip, variables, epsilon, channelForcing,
   oneFormData, oneForms, gaugeDenominator, denominatorDegrees,
   degreeOffset, numeratorDegrees, support, dimensions, gradeCount,
   gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, pointCount, maximumAttempts, randomSeed,
   accepted = {}, attempts = 0, point, pointData, matrix, right,
   rankSeconds, rank, augmentedRankSeconds, augmentedRank, augmented,
   solution = Missing["NotRun"], residual = Missing["NotRun"],
   solveSeconds = 0., verbose, log},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["TRPILOT ", items]];
  If[! PrimeQ[prime] || Mod[prime, 4] =!= 3,
    Return[<|"Status" -> "PrimeMustBe3Mod4"|>]];
  classification = CodexTripleRootStrip`TRClassifyStripRecord[record, frame];
  If[Lookup[classification, "Status", None] =!= "ExactRootClassification" ||
      Lookup[classification, "RootCount", 0] < 1,
    Return[classification]];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  strip = record["Strip"];
  roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables][[
    classification["RootIndices"]]];
  channelForcing = Map[
    CodexTripleRootStrip`TRFieldDecompose[#1, roots] &,
    strip[[3]], {3}];
  If[! FreeQ[channelForcing, $Failed],
    Return[Join[classification,
      <|"Status" -> "ForcingChannelDecompositionFailed"|>]]];
  oneFormData = OptionValue["OneForms"];
  If[oneFormData === Automatic,
    oneFormData = CodexTripleRootStrip`TRCandidateOneFormBasis[
      strip, roots, variables, epsilon]];
  oneForms = If[AssociationQ[oneFormData],
    Lookup[oneFormData, "OneForms", $Failed], oneFormData];
  If[! MatchQ[oneForms, {{_, _} ..}],
    Return[Join[classification,
      <|"Status" -> "OneFormBasisFailed"|>]]];
  gaugeDenominator = Replace[OptionValue["GaugeDenominator"],
    Automatic :> CodexTripleRootStrip`TRRationalGaugeDenominator[
      channelForcing, variables]];
  If[! FreeQ[gaugeDenominator,
      Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[Join[classification,
      <|"Status" -> "GaugeDenominatorNotRational"|>]]];
  denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset,
      {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[<|"Status" -> "InvalidDegreeOffset"|>]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  If[support === Automatic,
    support = Flatten[Table[{i, j}, {i, 0, numeratorDegrees[[1]]},
      {j, 0, numeratorDegrees[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support,
        MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[<|"Status" -> "InvalidSupport"|>]];
  dimensions = Dimensions[strip[[3, 1]]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  pointCount = Replace[OptionValue["PointCount"],
    Automatic :> Max[4, Ceiling[(unknownCount + equationsPerPoint)/
      equationsPerPoint]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  SeedRandom[randomSeed];
  log["roots=", classification["RootIndices"], " dimensions=", dimensions,
    " one_forms=", Length[oneForms], " denominator=", InputForm[gaugeDenominator],
    " support=", Length[support], " unknowns=", unknownCount,
    " points=", pointCount];
  While[Length[accepted] < pointCount && attempts < maximumAttempts,
    attempts++;
    point = RandomInteger[{2, prime - 2}, 2];
    pointData = Quiet[TRSplitPointRows[record, roots, oneForms,
      gaugeDenominator, support, epsilonValue, prime, point]];
    If[AssociationQ[pointData], AppendTo[accepted, pointData]]];
  If[Length[accepted] < pointCount,
    Return[Join[classification, <|"Status" -> "InsufficientSplitPoints",
      "AcceptedPointCount" -> Length[accepted],
      "AttemptCount" -> attempts|>]]];
  matrix = SparseArray[Join @@ Lookup[accepted, "Rows"]];
  right = Join @@ Lookup[accepted, "RightHandSide"];
  {rankSeconds, rank} = AbsoluteTiming[
    MatrixRank[matrix, Modulus -> prime]];
  augmented = Join[matrix, SparseArray[List /@ right], 2];
  {augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
    MatrixRank[augmented, Modulus -> prime]];
  If[rank === augmentedRank && TrueQ[OptionValue["Solve"]],
    {solveSeconds, solution} = AbsoluteTiming[
      Quiet[Check[LinearSolve[matrix, right, Modulus -> prime], $Failed]]];
    If[VectorQ[solution, IntegerQ],
      residual = AllTrue[Mod[matrix . solution - right, prime], #1 === 0 &]]];
  Join[classification, <|
    "Status" -> If[rank === augmentedRank, "ConsistentPilot",
      "InconsistentPilot"],
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "Roots" -> roots, "OneFormBasis" -> oneForms,
    "OneFormMetadata" -> oneFormData,
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeSupport" -> support,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "MatrixDimensions" -> Dimensions[matrix],
    "Rank" -> rank, "AugmentedRank" -> augmentedRank,
    "Nullity" -> unknownCount - rank,
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "AttemptCount" -> attempts,
    "RankSeconds" -> rankSeconds,
    "AugmentedRankSeconds" -> augmentedRankSeconds,
    "SolveSeconds" -> solveSeconds,
    "Solution" -> solution,
    "ResidualZero" -> residual|>]
];

End[];
EndPackage[];
