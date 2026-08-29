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
  finiteFieldGaugePullBackMonomialValues,
  finiteFieldGaugePullBackSliceDegrees,
  finiteFieldGaugePullBackFitDenominator,
  finiteFieldGaugePullBackFitNumerators,
  finiteFieldGaugePullBackFitFibre,
  finiteFieldGaugePullBackPrime,
  finiteFieldGaugePullBackLift,
  finiteFieldGaugePullBackDeadlineQ,
  finiteFieldGaugePullBackExpiredQ,
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
    generator_, required_Integer, maximumAttempts_Integer] := Module[
  {accepted = {}, attempts = 0, point, result},
  While[Length[accepted] < required && attempts < maximumAttempts,
    attempts++;
    point = generator[attempts];
    result = finiteFieldGaugePullBackEvaluatePoint[specialized, point];
    If[Lookup[result, "Status", None] ===
        "FiniteFieldGaugePullBackPointV1",
      AppendTo[accepted, result]]];
  If[Length[accepted] < required,
    finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackInsufficientRegularPoints",
      <|"Required" -> required, "Accepted" -> Length[accepted],
        "Attempts" -> attempts|>],
    <|"Status" -> "FiniteFieldGaugePullBackPointSetV1",
      "Records" -> accepted, "Attempts" -> attempts|>]
];
finiteFieldGaugePullBackCollectPoints[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackPointCollectionArgumentsInvalid"];

finiteFieldGaugePullBackMonomialValues[support_List,
    point : {x_Integer, y_Integer}, prime_Integer] := Developer`ToPackedArray[
  Mod[PowerMod[x, #[[1]], prime] PowerMod[y, #[[2]], prime], prime] & /@
    support];

finiteFieldGaugePullBackSliceDegrees[specialized_Association,
    pilotFibre_Integer, maximumTotalDegree_Integer,
    heldOut_Integer] := Module[
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
    sampleCount, sampleCount + 256];
  If[Lookup[xSet, "Status", None] =!=
      "FiniteFieldGaugePullBackPointSetV1", Return[xSet]];
  ySet = finiteFieldGaugePullBackCollectPoints[specialized,
    Function[k, {xFixed, PowerMod[primitive, k + 17, prime]}],
    sampleCount, sampleCount + 256];
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
    Lookup[#, "Status", None] ===
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
   expectedEpsilon, expectedNumerator, expectedDenominator,
   expectedActive, expectedAnchors, expectedNormalization, deadline,
   verbose, epsilonCandidates, specialized, pilotFibre, degrees,
   numeratorBounds, denominatorBounds, activeOutputs, numeratorSupport,
   denominatorSupport, denominatorSupportCandidates, numeratorCount,
   denominatorCount, anchors,
   requiredPoints, primitive, pointSet, records, points, fibreValues,
   pilotFit, candidateFit, normalization, fits = {}, acceptedImages = {},
   fit, vector,
   canonicalSamples, interpolation, expectedProfile, log},
  maximumKinematic = OptionValue["MaximumKinematicTotalDegree"];
  maximumEpsilon = OptionValue["MaximumEpsilonTotalDegree"];
  heldOut = OptionValue["HeldOutPointCount"];
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
      ! PrimeQ[prime] || ! finiteFieldGaugePullBackDeadlineQ[deadline],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackPrimeInputInvalid"]]];
  If[finiteFieldGaugePullBackExpiredQ[deadline],
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackDeadlineExpired",
      <|"Stage" -> "PrimeEntry", "Prime" -> prime|>]]];
  epsilonCandidates = Range[2, 2 maximumEpsilon + 9];
  specialized = finiteFieldGaugePullBackSpecialize[
    plan, epsilonCandidates, prime];
  If[Lookup[specialized, "Status", None] =!=
      "FiniteFieldGaugePullBackSpecializationV1", Return[specialized]];
  pilotFibre = 1;
  If[expectedNumerator === Automatic || expectedDenominator === Automatic ||
      expectedActive === Automatic,
    degrees = finiteFieldGaugePullBackSliceDegrees[
      specialized, pilotFibre, maximumKinematic, heldOut];
    If[Lookup[degrees, "Status", None] =!=
        "FiniteFieldGaugePullBackSliceDegreesV1", Return[degrees]];
    numeratorBounds = degrees["NumeratorBounds"];
    denominatorBounds = degrees["DenominatorBounds"];
    activeOutputs = degrees["ActiveOutputs"],
    numeratorBounds = expectedNumerator;
    denominatorBounds = expectedDenominator;
    activeOutputs = expectedActive];
  If[AssociationQ[degrees],
    numeratorBounds = {
      Max[(#[[1]] + denominatorBounds[[1]] - #[[2]]) & /@
        degrees["XDegrees"][[activeOutputs]]],
      Max[(#[[1]] + denominatorBounds[[2]] - #[[2]]) & /@
        degrees["YDegrees"][[activeOutputs]]]
    }];
  numeratorSupport = Flatten[Table[{px, py},
    {px, 0, numeratorBounds[[1]]},
    {py, 0, numeratorBounds[[2]]}], 1];
  denominatorSupport = Flatten[Table[{px, py},
    {px, 0, denominatorBounds[[1]]},
    {py, 0, denominatorBounds[[2]]}], 1];
  denominatorSupportCandidates = If[expectedDenominator === Automatic,
    SortBy[
      (Function[bounds, Flatten[Table[{px, py},
          {px, 0, bounds[[1]]}, {py, 0, bounds[[2]]}], 1]] /@
        Tuples[{Range[0, denominatorBounds[[1]]],
          Range[0, denominatorBounds[[2]]]}]),
      {-Length[#], -Total[Last[#]]} &],
    {denominatorSupport}];
  numeratorCount = Length[numeratorSupport];
  denominatorCount = Length[denominatorSupport];
  log["[finite-field gauge pullback] inferred active outputs ",
    Length[activeOutputs], ", bounds ", numeratorBounds, "/",
    denominatorBounds];
  anchors = Replace[expectedAnchors, Automatic :> If[
    AssociationQ[degrees],
    {First[MaximalBy[activeOutputs, Function[output,
      With[{xDegree = degrees["XDegrees"][[output]],
          yDegree = degrees["YDegrees"][[output]]},
        {Boole[{xDegree[[2]], yDegree[[2]]} === denominatorBounds],
          xDegree[[2]] + yDegree[[2]],
          xDegree[[1]] + yDegree[[1]]}]]]]},
    {First[activeOutputs]}]];
  requiredPoints = Max[numeratorCount + heldOut,
    Ceiling[(Length[anchors] numeratorCount + denominatorCount - 1)/
      Length[anchors]] + heldOut];
  primitive = PrimitiveRoot[prime];
  pointSet = finiteFieldGaugePullBackCollectPoints[specialized,
    Function[k, {PowerMod[primitive, k + 211, prime],
      PowerMod[primitive, k^2 + 17 k + 307, prime]}],
    requiredPoints, requiredPoints + 512];
  If[Lookup[pointSet, "Status", None] =!=
      "FiniteFieldGaugePullBackPointSetV1", Return[pointSet]];
  records = pointSet["Records"];
  points = Lookup[records, "Point"];
  fibreValues = Transpose[Lookup[records, "Values"], {2, 1, 3}];
  pilotFit = finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackNoReducedDenominatorModel"];
  Do[
    candidateFit = finiteFieldGaugePullBackFitFibre[
      points, fibreValues[[pilotFibre]], activeOutputs,
      numeratorSupport, candidateSupport, prime, heldOut,
      anchors, expectedNormalization];
    log["[finite-field gauge pullback] denominator candidate ",
      Max /@ Transpose[candidateSupport], " -> ",
      Lookup[candidateFit, "Status", None]];
    pilotFit = candidateFit;
    If[Lookup[candidateFit, "Status", None] ===
        "FiniteFieldGaugePullBackFibreFitV1",
      denominatorSupport = candidateSupport;
      denominatorBounds = Max /@ Transpose[denominatorSupport];
      Break[]],
    {candidateSupport, denominatorSupportCandidates}];
  If[Lookup[pilotFit, "Status", None] =!=
      "FiniteFieldGaugePullBackFibreFitV1", Return[pilotFit]];
  anchors = pilotFit["Anchors"];
  normalization = pilotFit["NormalizationIndex"];
  Do[
    If[finiteFieldGaugePullBackExpiredQ[deadline], Break[]];
    fit = If[index === pilotFibre, pilotFit,
      finiteFieldGaugePullBackFitFibre[
        points, fibreValues[[index]], activeOutputs,
        numeratorSupport, denominatorSupport, prime, heldOut,
        anchors, normalization]];
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
  interpolation = finiteFieldStripHeldOutInterpolate[
    canonicalSamples, prime,
    "InitialConstructionCount" -> 4,
    "HeldOutCount" -> 3,
    "MaximumTotalDegree" -> maximumEpsilon,
    "ExpectedDegrees" -> expectedEpsilon];
  If[Lookup[interpolation, "Status", None] =!= "HeldOutValidated",
    Return[finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackRegulatorInterpolationFailed",
      <|"Prime" -> prime, "Detail" -> interpolation,
        "AcceptedFibres" -> Length[fits]|>]]];
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

Options[transportChartFiniteFieldCanonicalGauge] = {
  "Primes" -> {1000003, 2147483423, 2147483477, 2147483489,
    2147483497, 2147483543, 2147483549, 2147483563,
    2147483587, 2147483629, 2147483647},
  "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 11,
  "MaximumKinematicTotalDegree" -> 12,
  "MaximumEpsilonTotalDegree" -> 22,
  "HeldOutPointCount" -> 8,
  "Deadline" -> Infinity,
  "Verbose" -> False
};

transportChartFiniteFieldCanonicalGauge[chartGauge_List,
    chartDenominator_, chartVariables : {_Symbol, _Symbol},
    coordinateImages : {_, _}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, roots_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], primes, minimumPrimeCount, maximumPrimeCount,
   deadline, verbose, plan, modularData = {}, first = None, record, lift,
   selectedPrimes, terminal = None},
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
      If[verbose, Print["[finite-field gauge pullback] rejected prime ",
        prime, ": ", Lookup[record, "Status", None]]];
      If[MemberQ[{"FiniteFieldGaugePullBackSliceDegreeExceeded",
            "FiniteFieldGaugePullBackDenominatorModelInconsistent",
            "FiniteFieldGaugePullBackCommonDenominatorInsufficient"},
          Lookup[record, "Status", None]],
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
    finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackNotEnoughGoodPrimes",
      <|"GoodPrimeCount" -> Length[modularData]|>],
    finiteFieldGaugePullBackFailure[
      "FiniteFieldGaugePullBackModulusTooSmall",
      <|"GoodPrimeCount" -> Length[modularData]|>]]
];
transportChartFiniteFieldCanonicalGauge[___] :=
  finiteFieldGaugePullBackFailure[
    "FiniteFieldGaugePullBackArgumentsInvalid"];
