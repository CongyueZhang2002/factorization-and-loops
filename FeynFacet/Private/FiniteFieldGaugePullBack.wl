(* Finite-field reconstruction of a chart gauge after an algebraic pullback.

   The live chart gauge is compact.  Substituting an algebraic inverse map
   before normalization can create a huge characteristic-zero intermediate
   whose reduced source-frame entries are small.  This module evaluates the
   compact composition directly in the declared multiquadratic quotient,
   reconstructs a reduced common rational denominator, and lifts the result.

   It deliberately does not verify the strip equation.  The caller's existing
   post-pullback modular residual is the production acceptance. *)

ClearAll[
  finiteFieldGaugePullBackFailure,
  finiteFieldGaugePullBackModRational,
  finiteFieldGaugePullBackPlan,
  finiteFieldGaugePullBackSpecialize,
  finiteFieldGaugePullBackEvaluatePoint,
  finiteFieldGaugePullBackCollectPoints,
  finiteFieldGaugePullBackTakeFibres,
  finiteFieldGaugePullBackEpsilonFibreBudget,
  finiteFieldGaugePullBackMonomialValues,
  finiteFieldGaugePullBackSliceDegrees,
  finiteFieldGaugePullBackFitDenominator,
  finiteFieldGaugePullBackFitNumerators,
  finiteFieldGaugePullBackFitFibre,
  finiteFieldGaugePullBackPrime,
  finiteFieldGaugePullBackLift,
  finiteFieldGaugePullBackDeadlineQ,
  finiteFieldGaugePullBackExpiredQ,
  finiteFieldGaugePullBackCommon,
  finiteFieldGaugePullBackModelRefusalQ,
  transportChartFiniteFieldCanonicalGauge
];

finiteFieldGaugePullBackFailure[status_String, data_: <||>] :=
  Join[<|"Status" -> status|>, If[AssociationQ[data], data, <||>]];

finiteFieldGaugePullBackModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

finiteFieldGaugePullBackDeadlineQ[deadline_] :=
  deadline === Infinity || (NumericQ[deadline] && Positive[deadline]);

finiteFieldGaugePullBackExpiredQ[deadline_] :=
  NumericQ[deadline] && AbsoluteTime[] >= deadline;

finiteFieldGaugePullBackPlan[chartGauge_List, chartDenominator_,
    chartVariables : {_Symbol, _Symbol}, coordinateImages : {_, _},
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List] := Module[
  {started = AbsoluteTime[], dimensions, rank, width, numerators,
   gaugeRules, denominatorRules, supports, supportIndex, ruleIndices,
   coordinateChannels, rootSquares, maximumP, maximumQ},
  dimensions = Dimensions[chartGauge];
  rank = Length[roots];
  width = 2^rank;
  If[Length[dimensions] =!= 2 || Min[dimensions] < 1 ||
      ! Between[rank, {0, $multiquadraticStripMaximumRootCount}],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPlanShapeInvalid"]]];
  rootSquares = If[rank === 0, {},
    Lookup[roots, "RootSquare", $Failed]];
  If[! ListQ[rootSquares] || Length[rootSquares] =!= rank ||
      ! FreeQ[rootSquares, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackRootFrameInvalid"]]];
  numerators = Flatten[chartGauge] chartDenominator;
  If[! AllTrue[Join[numerators, {chartDenominator}],
      PolynomialQ[#, chartVariables] &],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackChartGaugeNotPolynomialOverDenominator"]]];
  gaugeRules = CoefficientRules[#, chartVariables] & /@ numerators;
  denominatorRules = CoefficientRules[Expand[chartDenominator],
    chartVariables];
  supports = Sort[DeleteDuplicates[Join[
    Join @@ (First /@ # & /@ gaugeRules), First /@ denominatorRules]]];
  If[supports === {} || ! MatchQ[supports, {{_Integer, _Integer} ..}] ||
      Min[Flatten[supports]] < 0,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackChartSupportInvalid"]]];
  supportIndex = AssociationThread[
    ToString[#, InputForm] & /@ supports -> Range[Length[supports]]];
  ruleIndices[rules_] := Lookup[supportIndex,
    ToString[#, InputForm] & /@ (First /@ rules)];
  coordinateChannels = Quiet[
    multiquadraticFieldDecompose[#, roots] & /@ coordinateImages];
  If[! MatchQ[coordinateChannels,
      {channels_List, channels2_List} /;
        Length[channels] === width && Length[channels2] === width] ||
      ! FreeQ[coordinateChannels, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackCoordinateMapOutsideField"]]];
  maximumP = Max[supports[[All, 1]]];
  maximumQ = Max[supports[[All, 2]]];
  <|
    "Status" -> "FiniteFieldGaugePullBackPlanV1",
    "Dimensions" -> dimensions,
    "EntryCount" -> Times @@ dimensions,
    "Variables" -> variables,
    "ChartVariables" -> chartVariables,
    "Regulator" -> epsilon,
    "Roots" -> roots,
    "RootSquares" -> rootSquares,
    "RootCount" -> rank,
    "GradeCount" -> width,
    "CoordinateChannels" -> coordinateChannels,
    "ChartSupport" -> supports,
    "ChartSupportCount" -> Length[supports],
    "MaximumChartDegrees" -> {maximumP, maximumQ},
    "GaugeRuleIndices" -> (ruleIndices /@ gaugeRules),
    "GaugeRuleCoefficients" -> (Last /@ # & /@ gaugeRules),
    "GaugeTermCounts" -> (Length /@ gaugeRules),
    "DenominatorRuleIndices" -> ruleIndices[denominatorRules],
    "DenominatorRuleCoefficients" -> (Last /@ denominatorRules),
    "DenominatorTermCount" -> Length[denominatorRules],
    "BuildSeconds" -> N[AbsoluteTime[] - started]
  |>
];
finiteFieldGaugePullBackPlan[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackPlanArgumentsInvalid"];

finiteFieldGaugePullBackSpecialize[plan_Association,
    epsilonImages_List, prime_Integer] := Module[
  {epsilon, specialize, accepted = {}, gaugeFibres = {},
   denominatorFibres = {}, gauge, denominator},
  If[Lookup[plan, "Status", None] =!= "FiniteFieldGaugePullBackPlanV1" ||
      ! PrimeQ[prime] || ! (3 < prime < $multiquadraticStripWordPrimeLimit) ||
      epsilonImages === {},
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackSpecializationInvalid"]]];
  epsilon = plan["Regulator"];
  specialize[value_, image_] :=
    finiteFieldGaugePullBackModRational[value /. epsilon -> image, prime];
  Do[
    gauge = Map[specialize[#, image] &,
      plan["GaugeRuleCoefficients"], {2}];
    denominator = specialize[#, image] & /@
      plan["DenominatorRuleCoefficients"];
    If[FreeQ[{gauge, denominator}, $Failed],
      AppendTo[accepted, image];
      AppendTo[gaugeFibres, gauge];
      AppendTo[denominatorFibres, denominator]],
    {image, epsilonImages}];
  If[accepted === {},
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackNoRegularRegulatorImages"]]];
  Join[plan, <|
    "Status" -> "FiniteFieldGaugePullBackSpecializationV1",
    "Prime" -> prime,
    "EpsilonImages" -> accepted,
    "GaugeCoefficientFibres" -> gaugeFibres,
    "DenominatorCoefficientFibres" -> denominatorFibres
  |>]
];
finiteFieldGaugePullBackSpecialize[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackSpecializationArgumentsInvalid"];

finiteFieldGaugePullBackEvaluatePoint[specialized_Association,
    sourcePoint : {_, _}] := Module[
  {prime, width, variables, sourceRules, deltas, p, q, one, maximumP,
   maximumQ, pPowers, qPowers, multiply, monomials, assemble, fibres},
  If[Lookup[specialized, "Status", None] =!=
      "FiniteFieldGaugePullBackSpecializationV1",
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackEvaluationInvalid"]]];
  prime = specialized["Prime"];
  width = specialized["GradeCount"];
  variables = specialized["Variables"];
  sourceRules = Thread[variables -> Mod[sourcePoint, prime]];
  deltas = finiteFieldGaugePullBackModRational[# /. sourceRules, prime] & /@
    specialized["RootSquares"];
  p = finiteFieldGaugePullBackModRational[# /. sourceRules, prime] & /@
    specialized["CoordinateChannels"][[1]];
  q = finiteFieldGaugePullBackModRational[# /. sourceRules, prime] & /@
    specialized["CoordinateChannels"][[2]];
  If[MemberQ[Join[deltas, p, q], $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPointOutsideDomain"]]];
  multiply[a_, b_] := multiquadraticMultiply[a, b, deltas, prime];
  one = UnitVector[width, 1];
  {maximumP, maximumQ} = specialized["MaximumChartDegrees"];
  pPowers = FoldList[multiply[#1, p] &, one, Range[maximumP]];
  qPowers = FoldList[multiply[#1, q] &, one, Range[maximumQ]];
  If[! FreeQ[{pPowers, qPowers}, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackCoordinatePowerFailed"]]];
  monomials = multiply[pPowers[[#[[1]] + 1]],
      qPowers[[#[[2]] + 1]]] & /@ specialized["ChartSupport"];
  If[MemberQ[monomials, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackMonomialEvaluationFailed"]]];
  assemble[gaugeCoefficients_, denominatorCoefficients_] := Module[
    {numerators, denominator, inverse, gauges},
    numerators = MapThread[
      Function[{indices, coefficients}, If[indices === {},
        ConstantArray[0, width],
        Mod[Total[MapThread[#1 monomials[[#2]] &,
          {coefficients, indices}]], prime]]],
      {specialized["GaugeRuleIndices"], gaugeCoefficients}];
    denominator = Mod[Total[MapThread[#1 monomials[[#2]] &,
      {denominatorCoefficients,
       specialized["DenominatorRuleIndices"]}]], prime];
    inverse = multiquadraticStripModularInverse[denominator, deltas, prime];
    If[inverse === $Failed,
      Return[finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackChartDenominatorSingular"]]];
    gauges = multiply[#, inverse] & /@ numerators;
    If[MemberQ[gauges, $Failed],
      finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackGaugeProductFailed"],
      Mod[Flatten[gauges], prime]]];
  fibres = MapThread[assemble,
    {specialized["GaugeCoefficientFibres"],
     specialized["DenominatorCoefficientFibres"]}];
  If[AnyTrue[fibres, AssociationQ],
    Return[FirstCase[fibres, failure_Association :> failure]]];
  <|"Status" -> "FiniteFieldGaugePullBackPointV1",
    "Point" -> Mod[sourcePoint, prime], "Values" -> fibres|>
];
finiteFieldGaugePullBackEvaluatePoint[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackEvaluationArgumentsInvalid"];

finiteFieldGaugePullBackCollectPoints[specialized_Association,
    generator_, required_Integer, maximumAttempts_Integer,
    deadline_: Infinity] := Module[
  {accepted = {}, attempts = 0, point, result},
  While[Length[accepted] < required && attempts < maximumAttempts,
    If[finiteFieldGaugePullBackExpiredQ[deadline], Break[]];
    attempts++;
    point = generator[attempts];
    result = finiteFieldGaugePullBackEvaluatePoint[specialized, point];
    If[Lookup[result, "Status", None] ===
        "FiniteFieldGaugePullBackPointV1",
      AppendTo[accepted, result]]];
  If[finiteFieldGaugePullBackExpiredQ[deadline],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDeadlineExpired",
      <|"Stage" -> "PointCollection", "Accepted" -> Length[accepted],
        "Attempts" -> attempts|>]]];
  If[Length[accepted] < required,
    finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackInsufficientRegularPoints",
      <|"Required" -> required, "Accepted" -> Length[accepted],
        "Attempts" -> attempts|>],
    <|"Status" -> "FiniteFieldGaugePullBackPointSetV1",
      "Records" -> Take[accepted, required], "Attempts" -> attempts|>]
];
finiteFieldGaugePullBackCollectPoints[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackPointCollectionArgumentsInvalid"];

finiteFieldGaugePullBackTakeFibres[specialized_Association,
    count_Integer] := Module[{take},
  take = Min[count, Length[Lookup[specialized, "EpsilonImages", {}]]];
  If[Lookup[specialized, "Status", None] =!=
        "FiniteFieldGaugePullBackSpecializationV1" || take < 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackFibreSelectionInvalid"]]];
  Join[specialized, <|
    "EpsilonImages" -> Take[specialized["EpsilonImages"], take],
    "GaugeCoefficientFibres" ->
      Take[specialized["GaugeCoefficientFibres"], take],
    "DenominatorCoefficientFibres" ->
      Take[specialized["DenominatorCoefficientFibres"], take]|>]
];
finiteFieldGaugePullBackTakeFibres[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackFibreSelectionArgumentsInvalid"];

(* Infer the regulator budget at two generic source points while evaluation
   is still cheap.  Only those two points see the full degree-cap schedule;
   the kinematic grids use the inferred requirement plus two safety fibres.
   Later primes already know the exact degree profile and skip this probe. *)
finiteFieldGaugePullBackEpsilonFibreBudget[
    specialized_Association, maximumTotalDegree_Integer,
    heldOut_Integer, deadline_: Infinity] := Module[
  {prime, primitive, probe, records, samples, interpolation, consumed},
  prime = specialized["Prime"];
  primitive = PrimitiveRoot[prime];
  probe = finiteFieldGaugePullBackCollectPoints[specialized,
    Function[index, {PowerMod[primitive, 401 + 13 index, prime],
      PowerMod[primitive, 509 + 17 index, prime]}], 2, 64, deadline];
  If[Lookup[probe, "Status", None] =!=
      "FiniteFieldGaugePullBackPointSetV1",
    Return[Length[specialized["EpsilonImages"]]]];
  records = probe["Records"];
  consumed = Table[
    samples = MapThread[<|"EpsilonMod" -> Mod[#1, prime],
        "Values" -> #2|> &,
      {specialized["EpsilonImages"], record["Values"]}];
    interpolation = finiteFieldStripHeldOutInterpolate[samples, prime,
      "InitialConstructionCount" -> 4,
      "HeldOutCount" -> heldOut,
      "MaximumTotalDegree" -> maximumTotalDegree];
    If[Lookup[interpolation, "Status", None] === "HeldOutValidated",
      Lookup[interpolation, "SampleCount", Length[samples]],
      Length[samples]],
    {record, records}];
  Min[Length[specialized["EpsilonImages"]], Max[consumed] + 2]
];
finiteFieldGaugePullBackEpsilonFibreBudget[___] := $Failed;

finiteFieldGaugePullBackMonomialValues[support_List,
    point : {x_Integer, y_Integer}, prime_Integer] := Developer`ToPackedArray[
  Mod[PowerMod[x, #[[1]], prime] PowerMod[y, #[[2]], prime], prime] & /@
    support];

finiteFieldGaugePullBackSliceDegrees[specialized_Association,
    pilotFibre_Integer, maximumTotalDegree_Integer,
    heldOut_Integer, deadline_: Infinity] := Module[
  {prime, primitive, outputCount, construction, sampleCount,
   xFixed, yFixed, xSet, ySet, xRecords, yRecords, xData, yData,
   xFits, yFits, fit, active, numeratorBounds, denominatorBounds},
  prime = specialized["Prime"];
  outputCount = specialized["EntryCount"] specialized["GradeCount"];
  If[! Between[pilotFibre, {1, Length[specialized["EpsilonImages"]]}] ||
      maximumTotalDegree < 0 || heldOut < 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackSliceOptionsInvalid"]]];
  primitive = PrimitiveRoot[prime];
  construction = maximumTotalDegree + 1;
  sampleCount = Max[construction + heldOut,
    2 maximumTotalDegree + 1];
  xFixed = PowerMod[primitive, 101, prime];
  yFixed = PowerMod[primitive, 137, prime];
  xSet = finiteFieldGaugePullBackCollectPoints[specialized,
    Function[k, {PowerMod[primitive, k + 11, prime], yFixed}],
    sampleCount, sampleCount + 256, deadline];
  If[Lookup[xSet, "Status", None] =!=
      "FiniteFieldGaugePullBackPointSetV1", Return[xSet]];
  ySet = finiteFieldGaugePullBackCollectPoints[specialized,
    Function[k, {xFixed, PowerMod[primitive, k + 17, prime]}],
    sampleCount, sampleCount + 256, deadline];
  If[Lookup[ySet, "Status", None] =!=
      "FiniteFieldGaugePullBackPointSetV1", Return[ySet]];
  xRecords = xSet["Records"];
  yRecords = ySet["Records"];
  xData = Table[{record["Point"][[1]],
      record["Values"][[pilotFibre, output]]},
    {output, outputCount}, {record, xRecords}];
  yData = Table[{record["Point"][[2]],
      record["Values"][[pilotFibre, output]]},
    {output, outputCount}, {record, yRecords}];
  xFits = finiteFieldStripInterpolateCoordinate[
      #, prime, construction, maximumTotalDegree] & /@ xData;
  yFits = finiteFieldStripInterpolateCoordinate[
      #, prime, construction, maximumTotalDegree] & /@ yData;
  If[MemberQ[Join[xFits, yFits], $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackSliceDegreeExceeded",
      <|"MaximumTotalDegree" -> maximumTotalDegree|>]]];
  active = Select[Range[outputCount],
    Lookup[xFits[[#]], "Degrees", {-Infinity, 0}][[1]] =!= -Infinity ||
      Lookup[yFits[[#]], "Degrees", {-Infinity, 0}][[1]] =!= -Infinity &];
  If[active === {},
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackGaugeIdenticallyZero"]]];
  numeratorBounds = {
    Max[Replace[Lookup[xFits[[active]], "Degrees"][[All, 1]],
      -Infinity -> 0, {1}]],
    Max[Replace[Lookup[yFits[[active]], "Degrees"][[All, 1]],
      -Infinity -> 0, {1}]]};
  denominatorBounds = {
    Max[Lookup[xFits[[active]], "Degrees"][[All, 2]]],
    Max[Lookup[yFits[[active]], "Degrees"][[All, 2]]]};
  <|"Status" -> "FiniteFieldGaugePullBackSliceDegreesV1",
    "ActiveOutputs" -> active,
    "NumeratorBounds" -> numeratorBounds,
    "DenominatorBounds" -> denominatorBounds,
    "XDegrees" -> Lookup[xFits, "Degrees"],
    "YDegrees" -> Lookup[yFits, "Degrees"],
    "XPointCount" -> Length[xRecords],
    "YPointCount" -> Length[yRecords]|>
];
finiteFieldGaugePullBackSliceDegrees[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackSliceArgumentsInvalid"];

finiteFieldGaugePullBackFitDenominator[points_List, values_List,
    anchors_List, numeratorSupport_List, denominatorSupport_List,
    prime_Integer, normalizationInput_: Automatic] := Module[
  {numeratorCount, denominatorCount, anchorCount, unknownCount,
   normalizations, fitAt, result, failures = {}},
  numeratorCount = Length[numeratorSupport];
  denominatorCount = Length[denominatorSupport];
  anchorCount = Length[anchors];
  If[anchorCount < 1 || ! MatrixQ[values, IntegerQ] ||
      Length[points] =!= Length[values] || numeratorCount < 1 ||
      denominatorCount < 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDenominatorFitInvalid"]]];
  unknownCount = anchorCount numeratorCount + denominatorCount - 1;
  normalizations = If[IntegerQ[normalizationInput],
    {normalizationInput}, Join[{1}, Range[2, denominatorCount]]];
  fitAt[normalization_] := Module[
    {rest, rows = {}, rhs = {}, numeratorValues, denominatorValues,
     normValues, row, constructionRows, constructionRhs, solution,
     coefficients, denominatorCoefficients, trainingOK, rowIndices, fail},
    fail[stage_String] := (AppendTo[failures, stage]; $Failed);
    If[! Between[normalization, {1, denominatorCount}], Return[$Failed]];
    rest = Delete[Range[denominatorCount], normalization];
    Do[
      numeratorValues = finiteFieldGaugePullBackMonomialValues[
        numeratorSupport, points[[pointIndex]], prime];
      denominatorValues = finiteFieldGaugePullBackMonomialValues[
        denominatorSupport[[rest]], points[[pointIndex]], prime];
      normValues = finiteFieldGaugePullBackMonomialValues[
        {denominatorSupport[[normalization]]}, points[[pointIndex]],
        prime][[1]];
      Do[
        row = ConstantArray[0, unknownCount];
        row[[1 + (anchorIndex - 1) numeratorCount ;;
            anchorIndex numeratorCount]] = numeratorValues;
        If[rest =!= {},
          row[[anchorCount numeratorCount + 1 ;; unknownCount]] =
            Mod[-values[[pointIndex, anchors[[anchorIndex]]]]
              denominatorValues, prime]];
        AppendTo[rows, row];
        AppendTo[rhs, Mod[values[[pointIndex, anchors[[anchorIndex]]]]
          normValues, prime]],
        {anchorIndex, anchorCount}],
      {pointIndex, Length[points]}];
    If[Length[rows] < unknownCount, Return[$Failed]];
    rowIndices = finiteFieldStripIndependentRows[
      Developer`ToPackedArray[rows], unknownCount, prime];
    If[rowIndices === $Failed, Return[fail["Singular"]]];
    constructionRows = Developer`ToPackedArray[rows[[rowIndices]]];
    constructionRhs = Developer`ToPackedArray[
      Transpose[{rhs[[rowIndices]]}]];
    solution = finiteFieldStripFLINTSolve[
      constructionRows, constructionRhs, prime, 8];
    If[Dimensions[solution] =!= {unknownCount, 1},
      Return[fail["SolveFailed"]]];
    coefficients = Flatten[solution];
    trainingOK = Mod[Developer`ToPackedArray[rows].coefficients - rhs,
      prime] === ConstantArray[0, Length[rhs]];
    If[! trainingOK, Return[fail["Inconsistent"]]];
    denominatorCoefficients = Insert[
      Drop[coefficients, anchorCount numeratorCount], 1, normalization];
    <|"Status" -> "FiniteFieldGaugePullBackDenominatorFitV1",
      "NormalizationIndex" -> normalization,
      "Anchors" -> anchors,
      "DenominatorCoefficients" -> denominatorCoefficients,
      "AnchorNumeratorCoefficients" -> ArrayReshape[
        Take[coefficients, anchorCount numeratorCount],
        {anchorCount, numeratorCount}],
      "UnknownCount" -> unknownCount|>
  ];
  result = SelectFirst[fitAt /@ normalizations,
    AssociationQ[#] && Lookup[#, "Status", None] ===
      "FiniteFieldGaugePullBackDenominatorFitV1" &, $Failed];
  If[result === $Failed,
    finiteFieldGaugePullBackFailure[If[MemberQ[failures, "Inconsistent"],
      "FiniteFieldGaugePullBackDenominatorModelInconsistent",
      "FiniteFieldGaugePullBackDenominatorFitSingular"]], result]
];
finiteFieldGaugePullBackFitDenominator[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackDenominatorFitArgumentsInvalid"];

finiteFieldGaugePullBackFitNumerators[points_List, values_List,
    numeratorSupport_List, denominatorSupport_List,
    denominatorCoefficients_List, prime_Integer,
    heldOut_Integer] := Module[
  {numeratorCount, outputCount, pointCount, monomialMatrix,
   construction, rhs, solution, denominatorValues, predicted,
   failures = {}, constructionIndices, validationIndices},
  numeratorCount = Length[numeratorSupport];
  outputCount = Last[Dimensions[values]];
  pointCount = Length[points];
  If[pointCount =!= Length[values] || pointCount < numeratorCount + heldOut ||
      Length[denominatorSupport] =!= Length[denominatorCoefficients],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackNumeratorFitInvalid"]]];
  monomialMatrix = finiteFieldGaugePullBackMonomialValues[
      numeratorSupport, #, prime] & /@ points;
  constructionIndices = finiteFieldStripIndependentRows[
    Developer`ToPackedArray[monomialMatrix], numeratorCount, prime];
  If[constructionIndices === $Failed,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackNumeratorCoreSingular"]]];
  construction = Developer`ToPackedArray[
    monomialMatrix[[constructionIndices]]];
  denominatorValues = Mod[
    (finiteFieldGaugePullBackMonomialValues[
        denominatorSupport, #, prime] & /@ points).
      denominatorCoefficients, prime];
  If[AnyTrue[denominatorValues, # === 0 &],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackReducedDenominatorSingular"]]];
  rhs = Developer`ToPackedArray[Mod[
    values[[constructionIndices]]
      denominatorValues[[constructionIndices]], prime]];
  solution = finiteFieldStripFLINTSolve[construction, rhs, prime, 8];
  If[Dimensions[solution] =!= {numeratorCount, outputCount},
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackNumeratorSolveFailed"]]];
  validationIndices = Complement[Range[pointCount], constructionIndices];
  Do[
    predicted = Mod[monomialMatrix[[index]].solution -
      denominatorValues[[index]] values[[index]], prime];
    failures = Union[failures,
      Flatten[Position[predicted, Except[0], {1}, Heads -> False]]],
    {index, validationIndices}];
  If[failures =!= {},
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackCommonDenominatorInsufficient",
      <|"FailedOutputs" -> failures|>]]];
  <|"Status" -> "FiniteFieldGaugePullBackNumeratorFitV1",
    "NumeratorCoefficients" -> solution,
    "ValidationPointCount" -> Length[validationIndices]|>
];
finiteFieldGaugePullBackFitNumerators[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackNumeratorFitArgumentsInvalid"];

finiteFieldGaugePullBackFitFibre[points_List, values_List,
    activeOutputs_List, numeratorSupport_List, denominatorSupport_List,
    prime_Integer, heldOut_Integer, anchorsInput_: Automatic,
    normalizationInput_: Automatic] := Module[
  {anchors, denominator, numerators, failures, candidate, status},
  anchors = Replace[anchorsInput, Automatic :>
    Take[activeOutputs, UpTo[2]]];
  While[True,
    denominator = finiteFieldGaugePullBackFitDenominator[
      points, values, anchors, numeratorSupport, denominatorSupport,
      prime, normalizationInput];
    status = Lookup[denominator, "Status", None];
    If[status =!= "FiniteFieldGaugePullBackDenominatorFitV1",
      If[status === "FiniteFieldGaugePullBackDenominatorFitSingular",
        candidate = SelectFirst[activeOutputs,
          ! MemberQ[anchors, #] &, None];
        If[candidate =!= None,
          anchors = Append[anchors, candidate]; Continue[]]];
      Return[denominator]];
    numerators = finiteFieldGaugePullBackFitNumerators[
      points, values, numeratorSupport, denominatorSupport,
      denominator["DenominatorCoefficients"], prime, heldOut];
    If[Lookup[numerators, "Status", None] ===
        "FiniteFieldGaugePullBackNumeratorFitV1",
      Return[<|"Status" -> "FiniteFieldGaugePullBackFibreFitV1",
        "Anchors" -> anchors,
        "NormalizationIndex" -> denominator["NormalizationIndex"],
        "NumeratorCoefficients" -> numerators["NumeratorCoefficients"],
        "DenominatorCoefficients" ->
          denominator["DenominatorCoefficients"]|>]];
    If[Lookup[numerators, "Status", None] =!=
        "FiniteFieldGaugePullBackCommonDenominatorInsufficient",
      Return[numerators]];
    failures = Complement[Lookup[numerators, "FailedOutputs", {}], anchors];
    If[failures === {}, Return[numerators]];
    candidate = SelectFirst[failures, MemberQ[activeOutputs, #] &, None];
    If[candidate === None, Return[numerators]];
    anchors = Append[anchors, candidate];
    If[Length[anchors] > Length[activeOutputs], Return[numerators]]]
];
finiteFieldGaugePullBackFitFibre[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackFibreFitArgumentsInvalid"];

Options[finiteFieldGaugePullBackPrime] = {
  "MaximumKinematicTotalDegree" -> 12,
  "MaximumEpsilonTotalDegree" -> 22,
  "HeldOutPointCount" -> 8,
  "EpsilonHeldOutCount" -> 3,
  "DenominatorDegreeAggregation" -> "Maximum",
  "MaximumDenominatorCandidates" -> 64,
  "ExpectedEpsilonDegrees" -> Automatic,
  "ExpectedNumeratorBounds" -> Automatic,
  "ExpectedDenominatorBounds" -> Automatic,
  "ExpectedActiveOutputs" -> Automatic,
  "ExpectedAnchors" -> Automatic,
  "ExpectedNormalizationIndex" -> Automatic,
  "Deadline" -> Infinity,
  "Verbose" -> False
};

finiteFieldGaugePullBackPrime[plan_Association, prime_Integer,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], maximumKinematic, maximumEpsilon, heldOut,
   epsilonHeldOut, denominatorAggregation, maximumDenominatorCandidates,
   expectedEpsilon, expectedNumerator, expectedDenominator,
   expectedActive, expectedAnchors, expectedNormalization, deadline,
   verbose, epsilonCandidates, epsilonCandidateCount, fullSpecialized,
   fibreBudget, availableFibreCount, specialized, pilotFibre, degrees,
   numeratorBounds, denominatorBounds, baseDenominatorBounds,
   maximumDenominatorBounds, activeOutputs, numeratorSupport = {},
   denominatorSupport = {}, denominatorBoundCandidates, smallerBounds,
   largerBounds, candidateBounds, candidateIndex,
   candidateNumeratorBounds,
   candidateNumeratorSupport, candidateDenominatorSupport,
   numeratorCount, denominatorCount, anchors,
   requiredPoints, primitive, records = {}, pointAttempts = 0,
   pointGenerator, ensurePointCount, pointResult, points, fibreValues,
   pilotFit, candidateFit, normalization, fits = {}, acceptedImages = {},
   fit, vector, candidateStatus,
   canonicalSamples, interpolation, interpolationStatus,
   requiredAdditional, nextFibreBudget, expectedProfile, log},
  maximumKinematic = OptionValue["MaximumKinematicTotalDegree"];
  maximumEpsilon = OptionValue["MaximumEpsilonTotalDegree"];
  heldOut = OptionValue["HeldOutPointCount"];
  epsilonHeldOut = OptionValue["EpsilonHeldOutCount"];
  denominatorAggregation = OptionValue["DenominatorDegreeAggregation"];
  maximumDenominatorCandidates =
    OptionValue["MaximumDenominatorCandidates"];
  expectedEpsilon = OptionValue["ExpectedEpsilonDegrees"];
  expectedNumerator = OptionValue["ExpectedNumeratorBounds"];
  expectedDenominator = OptionValue["ExpectedDenominatorBounds"];
  expectedActive = OptionValue["ExpectedActiveOutputs"];
  expectedAnchors = OptionValue["ExpectedAnchors"];
  expectedNormalization = OptionValue["ExpectedNormalizationIndex"];
  deadline = OptionValue["Deadline"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print[items]];
  If[Lookup[plan, "Status", None] =!= "FiniteFieldGaugePullBackPlanV1" ||
      ! PrimeQ[prime] || ! finiteFieldGaugePullBackDeadlineQ[deadline] ||
      ! IntegerQ[maximumKinematic] || maximumKinematic < 0 ||
      ! IntegerQ[maximumEpsilon] || maximumEpsilon < 0 ||
      ! IntegerQ[heldOut] || heldOut < 1 ||
      ! IntegerQ[epsilonHeldOut] || epsilonHeldOut < 1 ||
      ! MemberQ[{"Maximum", "ProductCeiling"},
        denominatorAggregation] ||
      ! IntegerQ[maximumDenominatorCandidates] ||
        maximumDenominatorCandidates < 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPrimeInputInvalid"]]];
  If[finiteFieldGaugePullBackExpiredQ[deadline],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDeadlineExpired",
      <|"Stage" -> "PrimeEntry", "Prime" -> prime|>]]];
  fibreBudget = If[ListQ[expectedEpsilon],
    Max[4, Max[Prepend[Cases[expectedEpsilon,
        {numerator_Integer, denominator_Integer} :>
          numerator + denominator], 0]] + 1] + epsilonHeldOut + 2,
    Automatic];
  (* Later primes need only the accepted profile plus held-outs.  Generate a
     few spare images so isolated regulator poles do not shorten that round. *)
  epsilonCandidateCount = If[IntegerQ[fibreBudget], fibreBudget + 4,
    2 maximumEpsilon + 8];
  epsilonCandidates = Range[2, 1 + epsilonCandidateCount];
  fullSpecialized = finiteFieldGaugePullBackSpecialize[
    plan, epsilonCandidates, prime];
  If[Lookup[fullSpecialized, "Status", None] =!=
      "FiniteFieldGaugePullBackSpecializationV1",
    Return[fullSpecialized]];
  availableFibreCount = Length[fullSpecialized["EpsilonImages"]];
  fibreBudget = If[IntegerQ[fibreBudget], fibreBudget,
    finiteFieldGaugePullBackEpsilonFibreBudget[
      fullSpecialized, maximumEpsilon, epsilonHeldOut, deadline]];
  If[! IntegerQ[fibreBudget] || fibreBudget < 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackFibreBudgetFailed",
      <|"Prime" -> prime|>]]];
  specialized = finiteFieldGaugePullBackTakeFibres[
    fullSpecialized, fibreBudget];
  If[Lookup[specialized, "Status", None] =!=
      "FiniteFieldGaugePullBackSpecializationV1", Return[specialized]];
  pilotFibre = 1;
  If[expectedNumerator === Automatic || expectedDenominator === Automatic ||
      expectedActive === Automatic,
    degrees = finiteFieldGaugePullBackSliceDegrees[
      specialized, pilotFibre, maximumKinematic, heldOut, deadline];
    If[Lookup[degrees, "Status", None] =!=
        "FiniteFieldGaugePullBackSliceDegreesV1", Return[degrees]];
    activeOutputs = degrees["ActiveOutputs"];
    baseDenominatorBounds = {
      Max[degrees["XDegrees"][[activeOutputs, 2]]],
      Max[degrees["YDegrees"][[activeOutputs, 2]]]};
    maximumDenominatorBounds = If[
      denominatorAggregation === "ProductCeiling",
      {Total[degrees["XDegrees"][[activeOutputs, 2]]],
       Total[degrees["YDegrees"][[activeOutputs, 2]]]},
      baseDenominatorBounds],
    numeratorBounds = expectedNumerator;
    denominatorBounds = expectedDenominator;
    activeOutputs = expectedActive;
    baseDenominatorBounds = expectedDenominator;
    maximumDenominatorBounds = expectedDenominator];
  If[! MatchQ[{baseDenominatorBounds, maximumDenominatorBounds},
      {{_Integer, _Integer}, {_Integer, _Integer}}] ||
      Min[Join[baseDenominatorBounds, maximumDenominatorBounds]] < 0,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDegreeBoundsInvalid"]]];
  smallerBounds = If[AssociationQ[degrees],
    Take[Flatten[Table[SortBy[Table[
          baseDenominatorBounds - {dx, distance - dx},
          {dx, Max[0, distance - baseDenominatorBounds[[2]]],
            Min[distance, baseDenominatorBounds[[1]]]}],
        -Times @@ (# + 1) &],
      {distance, 1, Total[baseDenominatorBounds]}], 1],
      UpTo[maximumDenominatorCandidates - 1]], {}];
  largerBounds = If[AssociationQ[degrees] &&
      maximumDenominatorBounds =!= baseDenominatorBounds,
    Take[Flatten[Table[SortBy[Table[
          baseDenominatorBounds + {dx, distance - dx},
          {dx, Max[0, distance -
              (maximumDenominatorBounds[[2]] -
                baseDenominatorBounds[[2]])],
            Min[distance, maximumDenominatorBounds[[1]] -
              baseDenominatorBounds[[1]]]}],
        Times @@ (# + 1) &],
      {distance, 1,
        Total[maximumDenominatorBounds - baseDenominatorBounds]}], 1],
      UpTo[maximumDenominatorCandidates - 1]], {}];
  denominatorBoundCandidates = {baseDenominatorBounds};
  anchors = Replace[expectedAnchors, Automatic :> If[
    AssociationQ[degrees],
    {First[MaximalBy[activeOutputs, Function[output,
      With[{xDegree = degrees["XDegrees"][[output]],
          yDegree = degrees["YDegrees"][[output]]},
        {xDegree[[2]] + yDegree[[2]],
          xDegree[[1]] + yDegree[[1]]}]]]]},
    {First[activeOutputs]}]];
  primitive = PrimitiveRoot[prime];
  pointGenerator[k_] := {PowerMod[primitive, k + 211, prime],
    PowerMod[primitive, k^2 + 17 k + 307, prime]};
  ensurePointCount[required_Integer] := Module[
    {evaluated},
    While[Length[records] < required &&
        pointAttempts < required + 512,
      If[finiteFieldGaugePullBackExpiredQ[deadline], Break[]];
      pointAttempts++;
      evaluated = finiteFieldGaugePullBackEvaluatePoint[
        specialized, pointGenerator[pointAttempts]];
      If[Lookup[evaluated, "Status", None] ===
          "FiniteFieldGaugePullBackPointV1",
        AppendTo[records, evaluated]]];
    If[Length[records] < required,
      finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackInsufficientRegularPoints",
        <|"Required" -> required, "Accepted" -> Length[records],
          "Attempts" -> pointAttempts|>], True]
  ];
  pilotFit = finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackNoReducedDenominatorModel"];
  candidateIndex = 1;
  While[candidateIndex <= Length[denominatorBoundCandidates],
    candidateBounds = denominatorBoundCandidates[[candidateIndex]];
    candidateNumeratorBounds = If[AssociationQ[degrees], {
      Max[0, Max[Replace[
        (#[[1]] + candidateBounds[[1]] - #[[2]]) & /@
          degrees["XDegrees"][[activeOutputs]],
        -Infinity -> 0, {1}]]],
      Max[0, Max[Replace[
        (#[[1]] + candidateBounds[[2]] - #[[2]]) & /@
          degrees["YDegrees"][[activeOutputs]],
        -Infinity -> 0, {1}]]]}, expectedNumerator];
    candidateNumeratorSupport = Flatten[Table[{px, py},
      {px, 0, candidateNumeratorBounds[[1]]},
      {py, 0, candidateNumeratorBounds[[2]]}], 1];
    candidateDenominatorSupport = Flatten[Table[{px, py},
      {px, 0, candidateBounds[[1]]},
      {py, 0, candidateBounds[[2]]}], 1];
    numeratorCount = Length[candidateNumeratorSupport];
    denominatorCount = Length[candidateDenominatorSupport];
    requiredPoints = Max[numeratorCount + heldOut,
      Ceiling[(Length[anchors] numeratorCount + denominatorCount - 1)/
        Length[anchors]] + heldOut];
    pointResult = ensurePointCount[requiredPoints];
    If[AssociationQ[pointResult], Return[pointResult]];
    points = Lookup[records, "Point"];
    fibreValues = Transpose[Lookup[records, "Values"], {2, 1, 3}];
    candidateFit = finiteFieldGaugePullBackFitFibre[
      points, fibreValues[[pilotFibre]], activeOutputs,
      candidateNumeratorSupport, candidateDenominatorSupport,
      prime, heldOut,
      anchors, expectedNormalization];
    log["[finite-field gauge pullback] denominator candidate ",
      candidateBounds, " with numerator ", candidateNumeratorBounds,
      " -> ",
      Lookup[candidateFit, "Status", None]];
    pilotFit = candidateFit;
    candidateStatus = Lookup[candidateFit, "Status", None];
    If[candidateStatus ===
        "FiniteFieldGaugePullBackFibreFitV1",
      numeratorBounds = candidateNumeratorBounds;
      denominatorBounds = candidateBounds;
      numeratorSupport = candidateNumeratorSupport;
      denominatorSupport = candidateDenominatorSupport;
      Break[]];
    If[candidateIndex === 1,
      denominatorBoundCandidates = Take[Join[
        denominatorBoundCandidates,
        If[candidateStatus ===
            "FiniteFieldGaugePullBackDenominatorFitSingular",
          Join[smallerBounds, largerBounds], largerBounds]],
        UpTo[maximumDenominatorCandidates]]];
    If[! MemberQ[{
          "FiniteFieldGaugePullBackDenominatorFitSingular",
          "FiniteFieldGaugePullBackDenominatorModelInconsistent",
          "FiniteFieldGaugePullBackCommonDenominatorInsufficient"},
        candidateStatus], Return[candidateFit]];
    candidateIndex++];
  If[Lookup[pilotFit, "Status", None] =!=
      "FiniteFieldGaugePullBackFibreFitV1",
    Return[Join[pilotFit, <|
      "BaseDenominatorBounds" -> baseDenominatorBounds,
      "MaximumDenominatorBounds" -> maximumDenominatorBounds,
      "CandidateLimit" -> maximumDenominatorCandidates,
      "CandidateCount" -> Length[denominatorBoundCandidates],
      "XDegrees" -> If[AssociationQ[degrees], degrees["XDegrees"], {}],
      "YDegrees" -> If[AssociationQ[degrees], degrees["YDegrees"], {}]
      |>]]];
  anchors = pilotFit["Anchors"];
  normalization = pilotFit["NormalizationIndex"];
  While[True,
    fits = {};
    acceptedImages = {};
    fibreValues = Transpose[Lookup[records, "Values"], {2, 1, 3}];
    Do[
      If[finiteFieldGaugePullBackExpiredQ[deadline], Break[]];
      fit = finiteFieldGaugePullBackFitFibre[
        points, fibreValues[[index]], activeOutputs,
        numeratorSupport, denominatorSupport, prime, heldOut,
        anchors, normalization];
      If[Lookup[fit, "Status", None] =!=
          "FiniteFieldGaugePullBackFibreFitV1", Continue[]];
      vector = Join[Flatten[Transpose[fit["NumeratorCoefficients"]]],
        Delete[fit["DenominatorCoefficients"], normalization]];
      AppendTo[acceptedImages, specialized["EpsilonImages"][[index]]];
      AppendTo[fits, vector],
      {index, Length[specialized["EpsilonImages"]]}];
    If[finiteFieldGaugePullBackExpiredQ[deadline],
      Return[finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackDeadlineExpired",
        <|"Stage" -> "RegulatorFibres", "Prime" -> prime,
          "CompletedFibres" -> Length[fits]|>]]];
    canonicalSamples = MapThread[
      <|"EpsilonMod" -> Mod[#1, prime], "Values" -> #2|> &,
      {acceptedImages, fits}];
    interpolation = If[Length[canonicalSamples] < 4 + epsilonHeldOut,
      <|"Status" -> "MoreSamplesRequired",
        "RequiredAdditionalSampleCount" ->
          4 + epsilonHeldOut - Length[canonicalSamples],
        "Reason" -> "InsufficientRegularGaugeFibres"|>,
      finiteFieldStripHeldOutInterpolate[
        canonicalSamples, prime,
        "InitialConstructionCount" -> 4,
        "HeldOutCount" -> epsilonHeldOut,
        "MaximumTotalDegree" -> maximumEpsilon,
        "ExpectedDegrees" -> expectedEpsilon]];
    interpolationStatus = Lookup[interpolation, "Status", None];
    If[interpolationStatus === "HeldOutValidated", Break[]];
    If[interpolationStatus =!= "MoreSamplesRequired",
      Return[finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackRegulatorInterpolationFailed",
        <|"Prime" -> prime, "Detail" -> interpolation,
          "AcceptedFibres" -> Length[fits]|>]]];
    requiredAdditional = Max[1, Lookup[interpolation,
      "RequiredAdditionalSampleCount", 1]];
    nextFibreBudget = Min[availableFibreCount,
      Length[specialized["EpsilonImages"]] +
        Max[4, requiredAdditional]];
    If[nextFibreBudget <= Length[specialized["EpsilonImages"]],
      Return[finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackRegulatorInterpolationFailed",
        <|"Prime" -> prime, "Detail" -> interpolation,
          "AcceptedFibres" -> Length[fits],
          "AvailableFibres" -> availableFibreCount|>]]];
    specialized = finiteFieldGaugePullBackTakeFibres[
      fullSpecialized, nextFibreBudget];
    records = {};
    pointAttempts = 0;
    pointResult = ensurePointCount[requiredPoints];
    If[AssociationQ[pointResult], Return[pointResult]];
    points = Lookup[records, "Point"]];
  expectedProfile = Lookup[interpolation["Interpolations"], "Degrees"];
  log["[finite-field gauge pullback] prime ", prime,
    ": points ", Length[points], ", fibres ", Length[fits],
    ", outputs ", plan["EntryCount"] plan["GradeCount"],
    ", bounds ", numeratorBounds, "/", denominatorBounds];
  <|"Status" -> "FiniteFieldGaugePullBackPrimeV1",
    "Prime" -> prime,
    "Interpolations" -> interpolation["Interpolations"],
    "EpsilonDegreeProfile" -> expectedProfile,
    "NumeratorBounds" -> numeratorBounds,
    "DenominatorBounds" -> denominatorBounds,
    "NumeratorSupport" -> numeratorSupport,
    "DenominatorSupport" -> denominatorSupport,
    "ActiveOutputs" -> activeOutputs,
    "Anchors" -> anchors,
    "NormalizationIndex" -> normalization,
    "PointCount" -> Length[points],
    "FibreBudget" -> Length[specialized["EpsilonImages"]],
    "AvailableFibreCount" -> availableFibreCount,
    "DenominatorDegreeAggregation" -> denominatorAggregation,
    "BaseDenominatorBounds" -> baseDenominatorBounds,
    "MaximumDenominatorBounds" -> maximumDenominatorBounds,
    "AcceptedFibreCount" -> Length[fits],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
finiteFieldGaugePullBackPrime[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackPrimeArgumentsInvalid"];

finiteFieldGaugePullBackLift[plan_Association,
    modularData_List] := Module[
  {primes, coordinateCount, combinedModulus, combined, liftedPairs,
   liftedVector, epsilon, first, numeratorSupport, denominatorSupport,
   normalization, outputCount, numeratorCount, denominatorCount,
   numeratorFunctions, denominatorFunctions, denominatorCoefficients,
   denominator, channelNumerators, entries},
  If[modularData === {} || ! AllTrue[modularData,
      Lookup[#, "Status", None] === "FiniteFieldGaugePullBackPrimeV1" &],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackLiftInputInvalid"]]];
  primes = Lookup[modularData, "Prime"];
  first = First[modularData];
  If[! DuplicateFreeQ[primes] ||
      Length[DeleteDuplicates[Lookup[modularData,
        "EpsilonDegreeProfile"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "NumeratorSupport"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "DenominatorSupport"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "NormalizationIndex"]]] =!= 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPrimeRecordsIncompatible"]]];
  coordinateCount = Length[first["Interpolations"]];
  combinedModulus = Times @@ primes;
  combined = Table[epsFormFiniteFieldCombineCoordinate[
      modularData[[All, "Interpolations", coordinate]], primes],
    {coordinate, coordinateCount}];
  If[MemberQ[combined, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackCRTFailed"]]];
  liftedPairs = Map[<|
      "NumeratorCoefficients" ->
        (epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ #1["Numerator"]),
      "DenominatorCoefficients" ->
        (epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ #1["Denominator"])|> &,
    combined];
  If[! FreeQ[liftedPairs, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackModulusTooSmall",
      <|"PrimeCount" -> Length[primes],
        "CombinedModulusBits" -> IntegerLength[combinedModulus, 2]|>]]];
  epsilon = plan["Regulator"];
  liftedVector = Together[
      FromDigits[Reverse[#NumeratorCoefficients], epsilon]/
        FromDigits[Reverse[#DenominatorCoefficients], epsilon]] & /@
    liftedPairs;
  numeratorSupport = first["NumeratorSupport"];
  denominatorSupport = first["DenominatorSupport"];
  normalization = first["NormalizationIndex"];
  outputCount = plan["EntryCount"] plan["GradeCount"];
  numeratorCount = Length[numeratorSupport];
  denominatorCount = Length[denominatorSupport];
  If[Length[liftedVector] =!=
      outputCount numeratorCount + denominatorCount - 1,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackLiftShapeInvalid"]]];
  numeratorFunctions = ArrayReshape[
    Take[liftedVector, outputCount numeratorCount],
    {outputCount, numeratorCount}];
  denominatorFunctions = Drop[liftedVector, outputCount numeratorCount];
  denominatorCoefficients = Insert[denominatorFunctions, 1, normalization];
  denominator = Total[MapThread[#1 plan["Variables"][[1]]^#2[[1]]
        plan["Variables"][[2]]^#2[[2]] &,
      {denominatorCoefficients, denominatorSupport}]];
  channelNumerators = Map[Total[MapThread[
      #1 plan["Variables"][[1]]^#2[[1]]
        plan["Variables"][[2]]^#2[[2]] &,
      {#, numeratorSupport}]] &, numeratorFunctions];
  entries = multiquadraticFieldCompose[#/denominator, plan["Roots"]] & /@
    Partition[channelNumerators, plan["GradeCount"]];
  If[MemberQ[entries, $Failed],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackComposeFailed"]]];
  <|"Status" -> "FiniteFieldGaugePullBackLiftedV1",
    "Result" -> ArrayReshape[entries, plan["Dimensions"]],
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "NumeratorSupport" -> numeratorSupport,
    "DenominatorSupport" -> denominatorSupport,
    "NormalizationIndex" -> normalization,
    "Denominator" -> denominator|>
];
finiteFieldGaugePullBackLift[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackLiftArgumentsInvalid"];

Options[finiteFieldGaugePullBackCommon] = {
  "Primes" -> {1000003, 2147483423, 2147483477, 2147483489,
    2147483497, 2147483543, 2147483549, 2147483563,
    2147483587, 2147483629, 2147483647},
  "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 11,
  "MaximumKinematicTotalDegree" -> 12,
  "MaximumEpsilonTotalDegree" -> 22,
  "HeldOutPointCount" -> 8,
  "EpsilonHeldOutCount" -> 3,
  "DenominatorDegreeAggregation" -> "Maximum",
  "MaximumDenominatorCandidates" -> 64,
  "Deadline" -> Infinity,
  "Verbose" -> False
};

finiteFieldGaugePullBackCommon[chartGauge_List,
    chartDenominator_, chartVariables : {_Symbol, _Symbol},
    coordinateImages : {_, _}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, roots_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], primes, minimumPrimeCount, maximumPrimeCount,
   deadline, verbose, plan, modularData = {}, first = None, record, lift,
   selectedPrimes, terminal = None, lastModelRefusal = None, status},
  primes = DeleteDuplicates[OptionValue["Primes"]];
  minimumPrimeCount = OptionValue["MinimumPrimeCount"];
  maximumPrimeCount = OptionValue["MaximumPrimeCount"];
  deadline = OptionValue["Deadline"];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! finiteFieldGaugePullBackDeadlineQ[deadline] ||
      ! IntegerQ[minimumPrimeCount] || minimumPrimeCount < 1 ||
      ! IntegerQ[maximumPrimeCount] ||
      maximumPrimeCount < minimumPrimeCount,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackOptionsInvalid"]]];
  selectedPrimes = Take[Select[primes,
    PrimeQ[#] && 3 < # < $multiquadraticStripWordPrimeLimit &],
    UpTo[maximumPrimeCount]];
  If[Length[selectedPrimes] < minimumPrimeCount,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPrimeScheduleInsufficient"]]];
  plan = finiteFieldGaugePullBackPlan[chartGauge, chartDenominator,
    chartVariables, coordinateImages, variables, epsilon, roots];
  If[Lookup[plan, "Status", None] =!= "FiniteFieldGaugePullBackPlanV1",
    Return[plan]];
  Do[
    If[finiteFieldGaugePullBackExpiredQ[deadline],
      terminal = finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackDeadlineExpired",
        <|"Stage" -> "PrimeLoop", "CompletedPrimes" -> Length[modularData],
          "Seconds" -> N[AbsoluteTime[] - started]|>];
      Break[]];
    record = finiteFieldGaugePullBackPrime[plan, prime,
      "MaximumKinematicTotalDegree" ->
        OptionValue["MaximumKinematicTotalDegree"],
      "MaximumEpsilonTotalDegree" ->
        OptionValue["MaximumEpsilonTotalDegree"],
      "HeldOutPointCount" -> OptionValue["HeldOutPointCount"],
      "EpsilonHeldOutCount" -> OptionValue["EpsilonHeldOutCount"],
      "DenominatorDegreeAggregation" ->
        OptionValue["DenominatorDegreeAggregation"],
      "MaximumDenominatorCandidates" ->
        OptionValue["MaximumDenominatorCandidates"],
      "ExpectedEpsilonDegrees" -> If[AssociationQ[first],
        first["EpsilonDegreeProfile"], Automatic],
      "ExpectedNumeratorBounds" -> If[AssociationQ[first],
        first["NumeratorBounds"], Automatic],
      "ExpectedDenominatorBounds" -> If[AssociationQ[first],
        first["DenominatorBounds"], Automatic],
      "ExpectedActiveOutputs" -> If[AssociationQ[first],
        first["ActiveOutputs"], Automatic],
      "ExpectedAnchors" -> If[AssociationQ[first],
        first["Anchors"], Automatic],
      "ExpectedNormalizationIndex" -> If[AssociationQ[first],
        first["NormalizationIndex"], Automatic],
      "Deadline" -> deadline, "Verbose" -> verbose];
    If[Lookup[record, "Status", None] =!=
        "FiniteFieldGaugePullBackPrimeV1",
      status = Lookup[record, "Status", None];
      If[verbose, Print["[finite-field gauge pullback] rejected prime ",
        prime, ": ", status]];
      If[status === "FiniteFieldGaugePullBackDeadlineExpired",
        terminal = record; Break[]];
      If[status === "FiniteFieldGaugePullBackDenominatorFitSingular",
        lastModelRefusal = record; Continue[]];
      If[MemberQ[{"FiniteFieldGaugePullBackSliceDegreeExceeded",
            "FiniteFieldGaugePullBackDenominatorModelInconsistent",
            "FiniteFieldGaugePullBackCommonDenominatorInsufficient",
            "FiniteFieldGaugePullBackNoReducedDenominatorModel"},
          status],
        terminal = record; Break[]];
      Continue[]];
    AppendTo[modularData, record];
    If[first === None, first = record];
    If[Length[modularData] >= minimumPrimeCount,
      lift = finiteFieldGaugePullBackLift[plan, modularData];
      If[Lookup[lift, "Status", None] ===
          "FiniteFieldGaugePullBackLiftedV1",
        terminal = Join[lift, <|
          "Status" -> "FiniteFieldCanonicalGaugePrepared",
          "Seconds" -> N[AbsoluteTime[] - started],
          "Plan" -> KeyTake[plan, {"Dimensions", "RootCount",
            "GradeCount", "ChartSupportCount", "GaugeTermCounts",
            "DenominatorTermCount", "BuildSeconds"}],
          "PrimeRecords" -> (KeyDrop[#, "Interpolations"] & /@
            modularData)|>];
        Break[]]],
    {prime, selectedPrimes}];
  If[AssociationQ[terminal], Return[terminal]];
  If[Length[modularData] < minimumPrimeCount,
    If[AssociationQ[lastModelRefusal], lastModelRefusal,
      finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackNotEnoughGoodPrimes",
        <|"GoodPrimeCount" -> Length[modularData]|>]],
    finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackModulusTooSmall",
      <|"GoodPrimeCount" -> Length[modularData]|>]]
];
finiteFieldGaugePullBackCommon[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackArgumentsInvalid"];

finiteFieldGaugePullBackModelRefusalQ[result_Association] := MemberQ[{
    "FiniteFieldGaugePullBackSliceDegreeExceeded",
    "FiniteFieldGaugePullBackDenominatorFitSingular",
    "FiniteFieldGaugePullBackDenominatorModelInconsistent",
    "FiniteFieldGaugePullBackCommonDenominatorInsufficient",
    "FiniteFieldGaugePullBackNoReducedDenominatorModel"},
  Lookup[result, "Status", None]];
finiteFieldGaugePullBackModelRefusalQ[_] := False;

Options[transportChartFiniteFieldCanonicalGauge] = Join[
  Options[finiteFieldGaugePullBackCommon],
  {"KinematicDegreeSchedule" -> Automatic,
   "SymbolicPreDispatchSeconds" -> 1.}];

(* A tiny compact composition gets one bounded canonical Together attempt.
   Otherwise prefer one common modular denominator for the complete gauge;
   on exact model refusal reconstruct each algebraic entry independently,
   widening only that entry's denominator and degree cap.  No raw composition
   is ever returned. *)
transportChartFiniteFieldCanonicalGauge[chartGauge_List,
    chartDenominator_, chartVariables : {_Symbol, _Symbol},
    coordinateImages : {_, _}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, roots_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], baseCap, schedule, common, runCommon,
   dimensions, entries, reconstructed, entryRecords = {}, result,
   attemptRecords, accepted, acceptedCap, entry, row, column,
   symbolicLimit, symbolicBudget, symbolicSeconds, symbolic,
   validationPlan, deadline},
  baseCap = OptionValue["MaximumKinematicTotalDegree"];
  symbolicLimit = OptionValue["SymbolicPreDispatchSeconds"];
  deadline = OptionValue["Deadline"];
  If[! IntegerQ[baseCap] || baseCap < 0,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackOptionsInvalid"]]];
  If[! NumericQ[symbolicLimit] || symbolicLimit < 0,
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackOptionsInvalid"]]];
  runCommon[gauge_, cap_Integer, aggregation_String] :=
    finiteFieldGaugePullBackCommon[gauge, chartDenominator,
      chartVariables, coordinateImages, variables, epsilon, roots,
      "Primes" -> OptionValue["Primes"],
      "MinimumPrimeCount" -> OptionValue["MinimumPrimeCount"],
      "MaximumPrimeCount" -> OptionValue["MaximumPrimeCount"],
      "MaximumKinematicTotalDegree" -> cap,
      "MaximumEpsilonTotalDegree" ->
        OptionValue["MaximumEpsilonTotalDegree"],
      "HeldOutPointCount" -> OptionValue["HeldOutPointCount"],
      "EpsilonHeldOutCount" -> OptionValue["EpsilonHeldOutCount"],
      "DenominatorDegreeAggregation" -> aggregation,
      "MaximumDenominatorCandidates" ->
        OptionValue["MaximumDenominatorCandidates"],
      "Deadline" -> OptionValue["Deadline"],
      "Verbose" -> OptionValue["Verbose"]];
  validationPlan = finiteFieldGaugePullBackPlan[chartGauge,
    chartDenominator, chartVariables, coordinateImages, variables,
    epsilon, roots];
  If[Lookup[validationPlan, "Status", None] =!=
      "FiniteFieldGaugePullBackPlanV1", Return[validationPlan]];
  symbolicBudget = If[deadline === Infinity, symbolicLimit,
    Min[symbolicLimit, Max[0., N[deadline - AbsoluteTime[]]]]];
  If[symbolicBudget > 0.,
    {symbolicSeconds, symbolic} = AbsoluteTiming[TimeConstrained[
      Map[Together,
        chartGauge /. Thread[chartVariables -> coordinateImages], {2}],
      symbolicBudget, $Aborted]];
    If[ListQ[symbolic] && Dimensions[symbolic] === Dimensions[chartGauge] &&
        FreeQ[symbolic, Alternatives @@ chartVariables],
      Return[<|"Status" -> "FiniteFieldCanonicalGaugePrepared",
        "Result" -> symbolic, "Model" -> "SymbolicSmallV1",
        "Plan" -> KeyTake[validationPlan, {"Dimensions", "RootCount",
          "GradeCount", "ChartSupportCount", "GaugeTermCounts",
          "DenominatorTermCount", "BuildSeconds"}],
        "Seconds" -> N[AbsoluteTime[] - started],
        "SymbolicSeconds" -> N[symbolicSeconds]|>]]];
  common = runCommon[chartGauge, baseCap, "Maximum"];
  If[Lookup[common, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared",
    Return[Join[common, <|"Model" -> "CommonDenominatorV1"|>]]];
  If[! finiteFieldGaugePullBackModelRefusalQ[common], Return[common]];
  schedule = Replace[OptionValue["KinematicDegreeSchedule"],
    Automatic :> {baseCap, Ceiling[3 baseCap/2], 2 baseCap}];
  If[! ListQ[schedule] ||
      ! AllTrue[schedule, IntegerQ[#] && # >= baseCap &],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDegreeScheduleInvalid",
      <|"Schedule" -> schedule, "BaseDegree" -> baseCap|>]]];
  schedule = Sort[DeleteDuplicates[Prepend[schedule, baseCap]]];
  dimensions = Dimensions[chartGauge];
  entries = Flatten[chartGauge];
  reconstructed = ConstantArray[0, Length[entries]];
  Do[
    entry = entries[[index]];
    {row, column} = QuotientRemainder[index - 1, dimensions[[2]]] + {1, 1};
    If[TrueQ[entry === 0],
      AppendTo[entryRecords, <|"Entry" -> {row, column},
        "Status" -> "ExactZero"|>]; Continue[]];
    attemptRecords = {};
    accepted = None;
    acceptedCap = None;
    Do[
      result = runCommon[{{entry}}, cap, "ProductCeiling"];
      AppendTo[attemptRecords, <|"DegreeCap" -> cap,
        "Status" -> Lookup[result, "Status", None],
        "Seconds" -> Lookup[result, "Seconds", Missing["NotAvailable"]],
        "BaseDenominatorBounds" ->
          Lookup[result, "BaseDenominatorBounds", Missing["NotAvailable"]],
        "MaximumDenominatorBounds" -> Lookup[result,
          "MaximumDenominatorBounds", Missing["NotAvailable"]]|>];
      If[Lookup[result, "Status", None] ===
          "FiniteFieldCanonicalGaugePrepared",
        accepted = result; acceptedCap = cap; Break[]];
      If[! finiteFieldGaugePullBackModelRefusalQ[result],
        Return[Join[result, <|"Entry" -> {row, column},
          "DegreeCaps" -> schedule,
          "EntryAttempts" -> attemptRecords|>]]],
      {cap, schedule}];
    If[! AssociationQ[accepted],
      Return[finiteFieldGaugePullBackFailure[
        "FiniteFieldGaugePullBackReducedModelRefused",
        <|"Entry" -> {row, column}, "DegreeCaps" -> schedule,
          "EntryAttempts" -> attemptRecords,
          "Detail" -> result|>]]];
    reconstructed[[index]] = accepted["Result"][[1, 1]];
    AppendTo[entryRecords, <|"Entry" -> {row, column},
      "Status" -> "FiniteFieldCanonicalGaugePrepared",
      "DegreeCap" -> acceptedCap,
      "Primes" -> accepted["Primes"],
      "Seconds" -> accepted["Seconds"]|>],
    {index, Length[entries]}];
  <|"Status" -> "FiniteFieldCanonicalGaugePrepared",
    "Result" -> ArrayReshape[reconstructed, dimensions],
    "Model" -> "PerEntryDenominatorsV1",
    "EntryRecords" -> entryRecords,
    "CommonModelRefusal" -> KeyDrop[common, {"Result", "Interpolations"}],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartFiniteFieldCanonicalGauge[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackArgumentsInvalid"];
