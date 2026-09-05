(* Finite-field reconstruction of a chart basisTransformationBlock after an algebraic pullback.

   The live chart basisTransformationBlock is compact.  Substituting an algebraic inverse map
   before normalization can create a huge characteristic-zero intermediate
   whose reduced source-frame entries are small.  This module evaluates the
   compact composition directly in the declared multiquadratic quotient,
   reconstructs a reduced common rational denominator, and lifts the result.

   It deliberately does not verify the offDiagonalBlockEquation equation.  The caller's existing
   post-pullback modular residual is the production acceptance.

   Coefficient lift (round 4, 2026-09-02): finiteFieldBasisTransformationReexpressionLift
   pads each coordinate's per-prime coefficient lists to the recorded
   degrees (epsFormFiniteFieldPaddedCoordinate) and lifts them with
   modularLift (Core/ModularArithmetic.wl), the same CRT and rational
   reconstruction it used to spell out.  Two things are stronger than
   the spelled-out version and provably change no accepted result:
   modularLift verifies every reconstructed rational against its image
   at every prime (redundant after modularRationalReconstruct's residual
   check, kept as defence in depth) and refuses a prime list that is not
   a list of distinct primes.  The typed statuses keep their meaning:
   "...CRTFailed" = the per-prime degree records disagree,
   "...ModulusTooSmall" = a coefficient did not reconstruct. *)

ClearAll[
  finiteFieldBasisTransformationReexpressionFailure,
  finiteFieldBasisTransformationReexpressionModRational,
  finiteFieldBasisTransformationReexpressionPlan,
  finiteFieldBasisTransformationReexpressionSpecialize,
  finiteFieldBasisTransformationReexpressionEvaluatePoint,
  finiteFieldBasisTransformationReexpressionCollectPoints,
  finiteFieldBasisTransformationReexpressionTakeFibres,
  finiteFieldBasisTransformationReexpressionEpsilonFibreBudget,
  finiteFieldBasisTransformationReexpressionMonomialValues,
  finiteFieldBasisTransformationReexpressionSliceDegrees,
  finiteFieldBasisTransformationReexpressionFitDenominator,
  finiteFieldBasisTransformationReexpressionFitNumerators,
  finiteFieldBasisTransformationReexpressionFitFibre,
  finiteFieldBasisTransformationReexpressionPrime,
  finiteFieldBasisTransformationReexpressionPrimeTask,
  finiteFieldBasisTransformationReexpressionLift,
  finiteFieldBasisTransformationReexpressionDeadlineQ,
  finiteFieldBasisTransformationReexpressionExpiredQ,
  finiteFieldBasisTransformationReexpressionCommon,
  finiteFieldBasisTransformationReexpressionModelRefusalQ,
  reexpressBasisTransformationInSourceVariablesFiniteField
];

finiteFieldBasisTransformationReexpressionFailure[status_String, data_: <||>] :=
  Join[<|"Status" -> status|>, If[AssociationQ[data], data, <||>]];

finiteFieldBasisTransformationReexpressionModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

finiteFieldBasisTransformationReexpressionDeadlineQ[deadline_] :=
  deadline === Infinity || (NumericQ[deadline] && Positive[deadline]);

finiteFieldBasisTransformationReexpressionExpiredQ[deadline_] :=
  NumericQ[deadline] && AbsoluteTime[] >= deadline;

finiteFieldBasisTransformationReexpressionPlan[parametrizedBasisTransformationBlock_List, parametrizedBasisTransformationDenominator_,
    parametrizingVariables : {_Symbol, _Symbol}, coordinateImages : {_, _},
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List] := Module[
  {started = AbsoluteTime[], dimensions, rank, width, numerators,
   offDiagonalBasisTransformationRules, denominatorRules, supports, supportIndex, ruleIndices,
   coordinateChannels, rootSquares, maximumP, maximumQ},
  dimensions = Dimensions[parametrizedBasisTransformationBlock];
  rank = Length[roots];
  width = 2^rank;
  If[Length[dimensions] =!= 2 || Min[dimensions] < 1 ||
      ! Between[rank, {0, $multiquadraticOffDiagonalBlockMaximumRootCount}],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionPlanShapeInvalid"]]];
  rootSquares = If[rank === 0, {},
    squareRootRecordRadicand /@ roots];
  If[! ListQ[rootSquares] || Length[rootSquares] =!= rank ||
      ! FreeQ[rootSquares, $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionRootFrameInvalid"]]];
  numerators = Flatten[parametrizedBasisTransformationBlock] parametrizedBasisTransformationDenominator;
  If[! AllTrue[Join[numerators, {parametrizedBasisTransformationDenominator}],
      PolynomialQ[#, parametrizingVariables] &],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionInputNotPolynomialOverDenominator"]]];
  offDiagonalBasisTransformationRules = CoefficientRules[#, parametrizingVariables] & /@ numerators;
  denominatorRules = CoefficientRules[Expand[parametrizedBasisTransformationDenominator],
    parametrizingVariables];
  supports = Sort[DeleteDuplicates[Join[
    Join @@ (First /@ # & /@ offDiagonalBasisTransformationRules), First /@ denominatorRules]]];
  If[supports === {} || ! MatchQ[supports, {{_Integer, _Integer} ..}] ||
      Min[Flatten[supports]] < 0,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionParametrizingVariableSupportInvalid"]]];
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionCoordinateMapOutsideField"]]];
  maximumP = Max[supports[[All, 1]]];
  maximumQ = Max[supports[[All, 2]]];
  <|
    "Status" -> "FiniteFieldBasisTransformationReexpressionPlanV1",
    "Dimensions" -> dimensions,
    "EntryCount" -> Times @@ dimensions,
    "Variables" -> variables,
    "ParametrizingVariables" -> parametrizingVariables,
    "Regulator" -> epsilon,
    "Roots" -> roots,
    "RootSquares" -> rootSquares,
    "RootCount" -> rank,
    "GradeCount" -> width,
    "CoordinateChannels" -> coordinateChannels,
    "ParametrizingVariableSupport" -> supports,
    "ParametrizingVariableSupportCount" -> Length[supports],
    "MaximumParametrizingVariableDegrees" -> {maximumP, maximumQ},
    "OffDiagonalBasisTransformationRuleIndices" -> (ruleIndices /@ offDiagonalBasisTransformationRules),
    "OffDiagonalBasisTransformationRuleCoefficients" -> (Last /@ # & /@ offDiagonalBasisTransformationRules),
    "OffDiagonalBasisTransformationNumeratorTermCounts" -> (Length /@ offDiagonalBasisTransformationRules),
    "DenominatorRuleIndices" -> ruleIndices[denominatorRules],
    "DenominatorRuleCoefficients" -> (Last /@ denominatorRules),
    "DenominatorTermCount" -> Length[denominatorRules],
    "BuildSeconds" -> N[AbsoluteTime[] - started]
  |>
];
finiteFieldBasisTransformationReexpressionPlan[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionPlanArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionSpecialize[plan_Association,
    epsilonImages_List, prime_Integer] := Module[
  {epsilon, specialize, accepted = {}, offDiagonalBasisTransformationFibres = {},
   denominatorFibres = {}, basisTransformationBlock, denominator},
  If[Lookup[plan, "Status", None] =!= "FiniteFieldBasisTransformationReexpressionPlanV1" ||
      ! PrimeQ[prime] || ! (3 < prime < $multiquadraticOffDiagonalBlockWordPrimeLimit) ||
      epsilonImages === {},
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionSpecializationInvalid"]]];
  epsilon = plan["Regulator"];
  specialize[value_, image_] :=
    finiteFieldBasisTransformationReexpressionModRational[value /. epsilon -> image, prime];
  Do[
    basisTransformationBlock = Map[specialize[#, image] &,
      plan["OffDiagonalBasisTransformationRuleCoefficients"], {2}];
    denominator = specialize[#, image] & /@
      plan["DenominatorRuleCoefficients"];
    If[FreeQ[{basisTransformationBlock, denominator}, $Failed],
      AppendTo[accepted, image];
      AppendTo[offDiagonalBasisTransformationFibres, basisTransformationBlock];
      AppendTo[denominatorFibres, denominator]],
    {image, epsilonImages}];
  If[accepted === {},
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionNoRegularRegulatorImages"]]];
  Join[plan, <|
    "Status" -> "FiniteFieldBasisTransformationReexpressionSpecializationV1",
    "Prime" -> prime,
    "EpsilonImages" -> accepted,
    "OffDiagonalBasisTransformationCoefficientFibres" -> offDiagonalBasisTransformationFibres,
    "DenominatorCoefficientFibres" -> denominatorFibres
  |>]
];
finiteFieldBasisTransformationReexpressionSpecialize[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionSpecializationArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionEvaluatePoint[specialized_Association,
    sourcePoint : {_, _}] := Module[
  {prime, width, variables, sourceRules, deltas, p, q, one, maximumP,
   maximumQ, pPowers, qPowers, multiply, monomials, assemble, fibres},
  If[Lookup[specialized, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionSpecializationV1",
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionEvaluationInvalid"]]];
  prime = specialized["Prime"];
  width = specialized["GradeCount"];
  variables = specialized["Variables"];
  sourceRules = Thread[variables -> Mod[sourcePoint, prime]];
  deltas = finiteFieldBasisTransformationReexpressionModRational[# /. sourceRules, prime] & /@
    specialized["RootSquares"];
  p = finiteFieldBasisTransformationReexpressionModRational[# /. sourceRules, prime] & /@
    specialized["CoordinateChannels"][[1]];
  q = finiteFieldBasisTransformationReexpressionModRational[# /. sourceRules, prime] & /@
    specialized["CoordinateChannels"][[2]];
  If[MemberQ[Join[deltas, p, q], $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionPointOutsideDomain"]]];
  multiply[a_, b_] := multiquadraticMultiply[a, b, deltas, prime];
  one = UnitVector[width, 1];
  {maximumP, maximumQ} = specialized["MaximumParametrizingVariableDegrees"];
  pPowers = FoldList[multiply[#1, p] &, one, Range[maximumP]];
  qPowers = FoldList[multiply[#1, q] &, one, Range[maximumQ]];
  If[! FreeQ[{pPowers, qPowers}, $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionCoordinatePowerFailed"]]];
  monomials = multiply[pPowers[[#[[1]] + 1]],
      qPowers[[#[[2]] + 1]]] & /@ specialized["ParametrizingVariableSupport"];
  If[MemberQ[monomials, $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionMonomialEvaluationFailed"]]];
  assemble[offDiagonalBasisTransformationCoefficients_, denominatorCoefficients_] := Module[
    {numerators, denominator, inverse, basisTransformationBlocks},
    numerators = MapThread[
      Function[{indices, coefficients}, If[indices === {},
        ConstantArray[0, width],
        Mod[Total[MapThread[#1 monomials[[#2]] &,
          {coefficients, indices}]], prime]]],
      {specialized["OffDiagonalBasisTransformationRuleIndices"], offDiagonalBasisTransformationCoefficients}];
    denominator = Mod[Total[MapThread[#1 monomials[[#2]] &,
      {denominatorCoefficients,
       specialized["DenominatorRuleIndices"]}]], prime];
    inverse = multiquadraticOffDiagonalBlockModularInverse[denominator, deltas, prime];
    If[inverse === $Failed,
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionParametrizedBasisTransformationDenominatorSingular"]]];
    basisTransformationBlocks = multiply[#, inverse] & /@ numerators;
    If[MemberQ[basisTransformationBlocks, $Failed],
      finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionModularDivisionFailed"],
      Mod[Flatten[basisTransformationBlocks], prime]]];
  fibres = MapThread[assemble,
    {specialized["OffDiagonalBasisTransformationCoefficientFibres"],
     specialized["DenominatorCoefficientFibres"]}];
  If[AnyTrue[fibres, AssociationQ],
    Return[FirstCase[fibres, failure_Association :> failure]]];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionPointV1",
    "Point" -> Mod[sourcePoint, prime], "Values" -> fibres|>
];
finiteFieldBasisTransformationReexpressionEvaluatePoint[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionEvaluationArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionCollectPoints[specialized_Association,
    generator_, required_Integer, maximumAttempts_Integer,
    deadline_: Infinity] := Module[
  {accepted = {}, attempts = 0, point, result},
  While[Length[accepted] < required && attempts < maximumAttempts,
    If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline], Break[]];
    attempts++;
    point = generator[attempts];
    result = finiteFieldBasisTransformationReexpressionEvaluatePoint[specialized, point];
    If[Lookup[result, "Status", None] ===
        "FiniteFieldBasisTransformationReexpressionPointV1",
      AppendTo[accepted, result]]];
  If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
      <|"Stage" -> "PointCollection", "Accepted" -> Length[accepted],
        "Attempts" -> attempts|>]]];
  If[Length[accepted] < required,
    finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionInsufficientRegularPoints",
      <|"Required" -> required, "Accepted" -> Length[accepted],
        "Attempts" -> attempts|>],
    <|"Status" -> "FiniteFieldBasisTransformationReexpressionPointSetV1",
      "Records" -> Take[accepted, required], "Attempts" -> attempts|>]
];
finiteFieldBasisTransformationReexpressionCollectPoints[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionPointCollectionArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionTakeFibres[specialized_Association,
    count_Integer] := Module[{take},
  take = Min[count, Length[Lookup[specialized, "EpsilonImages", {}]]];
  If[Lookup[specialized, "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionSpecializationV1" || take < 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionFibreSelectionInvalid"]]];
  Join[specialized, <|
    "EpsilonImages" -> Take[specialized["EpsilonImages"], take],
    "OffDiagonalBasisTransformationCoefficientFibres" ->
      Take[specialized["OffDiagonalBasisTransformationCoefficientFibres"], take],
    "DenominatorCoefficientFibres" ->
      Take[specialized["DenominatorCoefficientFibres"], take]|>]
];
finiteFieldBasisTransformationReexpressionTakeFibres[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionFibreSelectionArgumentsInvalid"];

(* Infer the regulator budget at two generic source points while evaluation
   is still cheap.  Only those two points see the full degree-cap schedule;
   the kinematic grids use the inferred requirement plus two safety fibres.
   Later primes already know the exact degree profile and skip this probe. *)
finiteFieldBasisTransformationReexpressionEpsilonFibreBudget[
    specialized_Association, maximumTotalDegree_Integer,
    heldOut_Integer, deadline_: Infinity] := Module[
  {prime, primitive, probe, records, samples, interpolation, consumed},
  prime = specialized["Prime"];
  primitive = PrimitiveRoot[prime];
  probe = finiteFieldBasisTransformationReexpressionCollectPoints[specialized,
    Function[index, {PowerMod[primitive, 401 + 13 index, prime],
      PowerMod[primitive, 509 + 17 index, prime]}], 2, 64, deadline];
  If[Lookup[probe, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionPointSetV1",
    Return[Length[specialized["EpsilonImages"]]]];
  records = probe["Records"];
  consumed = Table[
    samples = MapThread[<|"EpsilonMod" -> Mod[#1, prime],
        "Values" -> #2|> &,
      {specialized["EpsilonImages"], record["Values"]}];
    interpolation = finiteFieldOffDiagonalBlockHeldOutInterpolate[samples, prime,
      "InitialConstructionCount" -> 4,
      "HeldOutCount" -> heldOut,
      "MaximumTotalDegree" -> maximumTotalDegree];
    If[Lookup[interpolation, "Status", None] === "HeldOutValidated",
      Lookup[interpolation, "SampleCount", Length[samples]],
      Length[samples]],
    {record, records}];
  Min[Length[specialized["EpsilonImages"]], Max[consumed] + 2]
];
finiteFieldBasisTransformationReexpressionEpsilonFibreBudget[___] := $Failed;

finiteFieldBasisTransformationReexpressionMonomialValues[support_List,
    point : {x_Integer, y_Integer}, prime_Integer] := Developer`ToPackedArray[
  Mod[PowerMod[x, #[[1]], prime] PowerMod[y, #[[2]], prime], prime] & /@
    support];

finiteFieldBasisTransformationReexpressionSliceDegrees[specialized_Association,
    pilotFibre_Integer, maximumTotalDegree_Integer,
    heldOut_Integer, deadline_: Infinity] := Module[
  {prime, primitive, outputCount, construction, sampleCount,
   xFixed, yFixed, xSet, ySet, xRecords, yRecords, xData, yData,
   xFits, yFits, fit, active, numeratorBounds, denominatorBounds},
  prime = specialized["Prime"];
  outputCount = specialized["EntryCount"] specialized["GradeCount"];
  If[! Between[pilotFibre, {1, Length[specialized["EpsilonImages"]]}] ||
      maximumTotalDegree < 0 || heldOut < 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionSliceOptionsInvalid"]]];
  primitive = PrimitiveRoot[prime];
  construction = maximumTotalDegree + 1;
  sampleCount = Max[construction + heldOut,
    2 maximumTotalDegree + 1];
  xFixed = PowerMod[primitive, 101, prime];
  yFixed = PowerMod[primitive, 137, prime];
  xSet = finiteFieldBasisTransformationReexpressionCollectPoints[specialized,
    Function[k, {PowerMod[primitive, k + 11, prime], yFixed}],
    sampleCount, sampleCount + 256, deadline];
  If[Lookup[xSet, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionPointSetV1", Return[xSet]];
  ySet = finiteFieldBasisTransformationReexpressionCollectPoints[specialized,
    Function[k, {xFixed, PowerMod[primitive, k + 17, prime]}],
    sampleCount, sampleCount + 256, deadline];
  If[Lookup[ySet, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionPointSetV1", Return[ySet]];
  xRecords = xSet["Records"];
  yRecords = ySet["Records"];
  xData = Table[{record["Point"][[1]],
      record["Values"][[pilotFibre, output]]},
    {output, outputCount}, {record, xRecords}];
  yData = Table[{record["Point"][[2]],
      record["Values"][[pilotFibre, output]]},
    {output, outputCount}, {record, yRecords}];
  xFits = finiteFieldOffDiagonalBlockInterpolateCoordinate[
      #, prime, construction, maximumTotalDegree] & /@ xData;
  yFits = finiteFieldOffDiagonalBlockInterpolateCoordinate[
      #, prime, construction, maximumTotalDegree] & /@ yData;
  If[MemberQ[Join[xFits, yFits], $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionSliceDegreeExceeded",
      <|"MaximumTotalDegree" -> maximumTotalDegree|>]]];
  active = Select[Range[outputCount],
    Lookup[xFits[[#]], "Degrees", {-Infinity, 0}][[1]] =!= -Infinity ||
      Lookup[yFits[[#]], "Degrees", {-Infinity, 0}][[1]] =!= -Infinity &];
  If[active === {},
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionInputIdenticallyZero"]]];
  numeratorBounds = {
    Max[Replace[Lookup[xFits[[active]], "Degrees"][[All, 1]],
      -Infinity -> 0, {1}]],
    Max[Replace[Lookup[yFits[[active]], "Degrees"][[All, 1]],
      -Infinity -> 0, {1}]]};
  denominatorBounds = {
    Max[Lookup[xFits[[active]], "Degrees"][[All, 2]]],
    Max[Lookup[yFits[[active]], "Degrees"][[All, 2]]]};
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionSliceDegreesV1",
    "ActiveOutputs" -> active,
    "NumeratorBounds" -> numeratorBounds,
    "DenominatorBounds" -> denominatorBounds,
    "XDegrees" -> Lookup[xFits, "Degrees"],
    "YDegrees" -> Lookup[yFits, "Degrees"],
    "XPointCount" -> Length[xRecords],
    "YPointCount" -> Length[yRecords]|>
];
finiteFieldBasisTransformationReexpressionSliceDegrees[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionSliceArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionFitDenominator[points_List, values_List,
    anchors_List, numeratorSupport_List, denominatorSupport_List,
    prime_Integer, normalizationInput_: Automatic] := Module[
  {numeratorCount, denominatorCount, anchorCount, numeratorUnknownCount,
   unknownCount, rows = {}, numeratorValues, denominatorValues, row,
   matrix, rightHandSide, preference, native, response, verification,
   nullspace, vector, denominatorCoefficients, normalization, scale,
   backend = "WolframNullSpace"},
  numeratorCount = Length[numeratorSupport];
  denominatorCount = Length[denominatorSupport];
  anchorCount = Length[anchors];
  If[anchorCount < 1 || ! MatrixQ[values, IntegerQ] ||
      Length[points] =!= Length[values] || numeratorCount < 1 ||
      denominatorCount < 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDenominatorFitInvalid"]]];
  (* The rational relation is homogeneous:

       N_a(x,y) - value_a(x,y) D(x,y) == 0

     for every anchor a and sampled point.  The former implementation
     deleted one coefficient, fixed it to one, and repeated the complete
     row construction and native solve for every possible denominator
     normalization.  A wrong 176-monomial model therefore paid as many as
     176 identical-rank solves before it could be rejected.  One nullspace
     computation finds the projective relation directly; only after that do
     we choose and normalize a nonzero denominator coordinate. *)
  numeratorUnknownCount = anchorCount numeratorCount;
  unknownCount = numeratorUnknownCount + denominatorCount;
  Do[
    numeratorValues = finiteFieldBasisTransformationReexpressionMonomialValues[
      numeratorSupport, points[[pointIndex]], prime];
    denominatorValues = finiteFieldBasisTransformationReexpressionMonomialValues[
      denominatorSupport, points[[pointIndex]], prime];
    Do[
      row = ConstantArray[0, unknownCount];
      row[[1 + (anchorIndex - 1) numeratorCount ;;
          anchorIndex numeratorCount]] = numeratorValues;
      row[[numeratorUnknownCount + 1 ;; unknownCount]] = Mod[
        -values[[pointIndex, anchors[[anchorIndex]]]] denominatorValues,
        prime];
      AppendTo[rows, row],
      {anchorIndex, anchorCount}],
    {pointIndex, Length[points]}];
  If[Length[rows] < unknownCount - 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDenominatorFitInvalid"]]];
  matrix = Developer`ToPackedArray[rows];
  rightHandSide = ConstantArray[0, Length[rows]];
  (* Prefer a denominator coordinate as the adapter's normalization.  The
     returned nullspace is still verified on every original row below. *)
  preference = Join[Range[numeratorUnknownCount + 1, unknownCount],
    Range[numeratorUnknownCount]];
  (* round 8 (2026-09-02, stage-1 speed): a fibre relation of fewer than 256
     unknowns is a sub-millisecond in-kernel nullspace; the native RREF
     adapter costs a process round trip per call (measured 0.1-0.2 s), which
     dominated the fits (6.2 s of the (12,9) normalizer's 11.5 s).  The
     same 256 threshold as finiteFieldOffDiagonalBlockBackendDecision; the returned
     nullspace is verified on every original row below either way. *)
  If[unknownCount >= 256,
  native = Quiet[Check[finiteFieldOffDiagonalBlockCFFRRun[
      matrix, rightHandSide, prime, preference, 8, Automatic], $Failed]];
  If[AssociationQ[native] && Lookup[native, "Status", None] === "OK",
    response = native["Response"];
    verification = finiteFieldOffDiagonalBlockCFFRVerify[
      matrix, rightHandSide, prime, response, Automatic];
    If[Lookup[verification, "Status", None] === "OK",
      nullspace = response["NullspaceBasis"];
      backend = "FLINTAffineRREF",
      nullspace = $Failed],
    nullspace = $Failed];
  If[nullspace === $Failed,
    nullspace = Quiet[Check[NullSpace[matrix, Modulus -> prime], $Failed]]],
    nullspace = Quiet[Check[NullSpace[matrix, Modulus -> prime], $Failed]]];
  If[! ListQ[nullspace],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular"]]];
  Which[
    nullspace === {},
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionDenominatorModelInconsistent"]],
    Length[nullspace] =!= 1,
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
        <|"RelationNullity" -> Length[nullspace]|>]]];
  vector = First[nullspace];
  denominatorCoefficients = Take[vector, -denominatorCount];
  normalization = If[IntegerQ[normalizationInput], normalizationInput,
    FirstCase[Range[denominatorCount],
      index_ /; denominatorCoefficients[[index]] =!= 0,
      Missing["NoDenominatorCoordinate"]]];
  If[! IntegerQ[normalization] ||
      ! Between[normalization, {1, denominatorCount}] ||
      denominatorCoefficients[[normalization]] === 0,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular"]]];
  scale = PowerMod[denominatorCoefficients[[normalization]], -1, prime];
  vector = Mod[scale vector, prime];
  denominatorCoefficients = Take[vector, -denominatorCount];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionDenominatorFitV1",
    "NormalizationIndex" -> normalization,
    "Anchors" -> anchors,
    "DenominatorCoefficients" -> denominatorCoefficients,
    "AnchorNumeratorCoefficients" -> ArrayReshape[
      Take[vector, numeratorUnknownCount],
      {anchorCount, numeratorCount}],
    "UnknownCount" -> unknownCount,
    "RelationNullity" -> 1,
    "Backend" -> backend|>
];
finiteFieldBasisTransformationReexpressionFitDenominator[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionDenominatorFitArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionFitNumerators[points_List, values_List,
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionNumeratorFitInvalid"]]];
  monomialMatrix = finiteFieldBasisTransformationReexpressionMonomialValues[
      numeratorSupport, #, prime] & /@ points;
  constructionIndices = finiteFieldOffDiagonalBlockIndependentRows[
    Developer`ToPackedArray[monomialMatrix], numeratorCount, prime];
  If[constructionIndices === $Failed,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionNumeratorCoreSingular"]]];
  construction = Developer`ToPackedArray[
    monomialMatrix[[constructionIndices]]];
  denominatorValues = Mod[
    (finiteFieldBasisTransformationReexpressionMonomialValues[
        denominatorSupport, #, prime] & /@ points).
      denominatorCoefficients, prime];
  If[AnyTrue[denominatorValues, # === 0 &],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionReducedDenominatorSingular"]]];
  rhs = Developer`ToPackedArray[Mod[
    values[[constructionIndices]]
      denominatorValues[[constructionIndices]], prime]];
  (* round 8 (2026-09-02): the numerator core is numeratorCount x
     numeratorCount (tens of unknowns per fibre); below the 256 threshold the
     in-kernel modular solve beats the adapter's process round trip, and the
     held-out rows below validate the solution either way *)
  solution = If[numeratorCount < 256,
    Quiet[Check[LinearSolve[construction, rhs, Modulus -> prime], $Failed]],
    finiteFieldOffDiagonalBlockFLINTSolve[construction, rhs, prime, 8]];
  If[Dimensions[solution] =!= {numeratorCount, outputCount},
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionNumeratorSolveFailed"]]];
  validationIndices = Complement[Range[pointCount], constructionIndices];
  Do[
    predicted = Mod[monomialMatrix[[index]].solution -
      denominatorValues[[index]] values[[index]], prime];
    failures = Union[failures,
      Flatten[Position[predicted, Except[0], {1}, Heads -> False]]],
    {index, validationIndices}];
  If[failures =!= {},
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionCommonDenominatorInsufficient",
      <|"FailedOutputs" -> failures|>]]];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionNumeratorFitV1",
    "NumeratorCoefficients" -> solution,
    "ValidationPointCount" -> Length[validationIndices]|>
];
finiteFieldBasisTransformationReexpressionFitNumerators[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionNumeratorFitArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionFitFibre[points_List, values_List,
    activeOutputs_List, numeratorSupport_List, denominatorSupport_List,
    prime_Integer, heldOut_Integer, anchorsInput_: Automatic,
    normalizationInput_: Automatic] := Module[
  {anchors, denominator, numerators, failures, candidate, status},
  anchors = Replace[anchorsInput, Automatic :>
    Take[activeOutputs, UpTo[2]]];
  While[True,
    denominator = finiteFieldBasisTransformationReexpressionFitDenominator[
      points, values, anchors, numeratorSupport, denominatorSupport,
      prime, normalizationInput];
    status = Lookup[denominator, "Status", None];
    If[status =!= "FiniteFieldBasisTransformationReexpressionDenominatorFitV1",
      If[status === "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
        candidate = SelectFirst[activeOutputs,
          ! MemberQ[anchors, #] &, None];
        If[candidate =!= None,
          anchors = Append[anchors, candidate]; Continue[]]];
      Return[denominator]];
    numerators = finiteFieldBasisTransformationReexpressionFitNumerators[
      points, values, numeratorSupport, denominatorSupport,
      denominator["DenominatorCoefficients"], prime, heldOut];
    If[Lookup[numerators, "Status", None] ===
        "FiniteFieldBasisTransformationReexpressionNumeratorFitV1",
      Return[<|"Status" -> "FiniteFieldBasisTransformationReexpressionFibreFitV1",
        "Anchors" -> anchors,
        "NormalizationIndex" -> denominator["NormalizationIndex"],
        "NumeratorCoefficients" -> numerators["NumeratorCoefficients"],
        "DenominatorCoefficients" ->
          denominator["DenominatorCoefficients"]|>]];
    If[Lookup[numerators, "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionCommonDenominatorInsufficient",
      Return[numerators]];
    failures = Complement[Lookup[numerators, "FailedOutputs", {}], anchors];
    If[failures === {}, Return[numerators]];
    candidate = SelectFirst[failures, MemberQ[activeOutputs, #] &, None];
    If[candidate === None, Return[numerators]];
    anchors = Append[anchors, candidate];
    If[Length[anchors] > Length[activeOutputs], Return[numerators]]]
];
finiteFieldBasisTransformationReexpressionFitFibre[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionFibreFitArgumentsInvalid"];

Options[finiteFieldBasisTransformationReexpressionPrime] = {
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

finiteFieldBasisTransformationReexpressionPrime[plan_Association, prime_Integer,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], phaseSeconds = <||>, maximumKinematic, maximumEpsilon, heldOut,
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
  If[Lookup[plan, "Status", None] =!= "FiniteFieldBasisTransformationReexpressionPlanV1" ||
      ! PrimeQ[prime] || ! finiteFieldBasisTransformationReexpressionDeadlineQ[deadline] ||
      ! IntegerQ[maximumKinematic] || maximumKinematic < 0 ||
      ! IntegerQ[maximumEpsilon] || maximumEpsilon < 0 ||
      ! IntegerQ[heldOut] || heldOut < 1 ||
      ! IntegerQ[epsilonHeldOut] || epsilonHeldOut < 1 ||
      ! MemberQ[{"Maximum", "ProductCeiling"},
        denominatorAggregation] ||
      ! IntegerQ[maximumDenominatorCandidates] ||
        maximumDenominatorCandidates < 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionPrimeInputInvalid"]]];
  If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
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
  fullSpecialized = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionSpecialize[
    plan, epsilonCandidates, prime]]}, phaseSeconds["SpecializeSeconds"] = Lookup[phaseSeconds, "SpecializeSeconds", 0.] + First[timed]; Last[timed]];
  If[Lookup[fullSpecialized, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionSpecializationV1",
    Return[fullSpecialized]];
  availableFibreCount = Length[fullSpecialized["EpsilonImages"]];
  fibreBudget = If[IntegerQ[fibreBudget], fibreBudget,
    finiteFieldBasisTransformationReexpressionEpsilonFibreBudget[
      fullSpecialized, maximumEpsilon, epsilonHeldOut, deadline]];
  If[! IntegerQ[fibreBudget] || fibreBudget < 1,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionFibreBudgetFailed",
      <|"Prime" -> prime|>]]];
  specialized = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionTakeFibres[
    fullSpecialized, fibreBudget]]}, phaseSeconds["TakeFibresSeconds"] = Lookup[phaseSeconds, "TakeFibresSeconds", 0.] + First[timed]; Last[timed]];
  If[Lookup[specialized, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionSpecializationV1", Return[specialized]];
  pilotFibre = 1;
  If[expectedNumerator === Automatic || expectedDenominator === Automatic ||
      expectedActive === Automatic,
    degrees = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionSliceDegrees[
      specialized, pilotFibre, maximumKinematic, heldOut, deadline]]}, phaseSeconds["SliceDegreesSeconds"] = Lookup[phaseSeconds, "SliceDegreesSeconds", 0.] + First[timed]; Last[timed]];
    If[Lookup[degrees, "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionSliceDegreesV1", Return[degrees]];
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDegreeBoundsInvalid"]]];
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
      If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline], Break[]];
      pointAttempts++;
      evaluated = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionEvaluatePoint[
        specialized, pointGenerator[pointAttempts]]]}, phaseSeconds["EvaluatePointSeconds"] = Lookup[phaseSeconds, "EvaluatePointSeconds", 0.] + First[timed]; Last[timed]];
      If[Lookup[evaluated, "Status", None] ===
          "FiniteFieldBasisTransformationReexpressionPointV1",
        AppendTo[records, evaluated]]];
    If[Length[records] < required,
      finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionInsufficientRegularPoints",
        <|"Required" -> required, "Accepted" -> Length[records],
          "Attempts" -> pointAttempts|>], True]
  ];
  pilotFit = finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionNoReducedDenominatorModel"];
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
    candidateFit = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionFitFibre[
      points, fibreValues[[pilotFibre]], activeOutputs,
      candidateNumeratorSupport, candidateDenominatorSupport,
      prime, heldOut,
      anchors, expectedNormalization]]}, phaseSeconds["FitFibreSeconds"] = Lookup[phaseSeconds, "FitFibreSeconds", 0.] + First[timed]; Last[timed]];
    log["[finite-field basisTransformationBlock pullback] denominator candidate ",
      candidateBounds, " with numerator ", candidateNumeratorBounds,
      " -> ",
      Lookup[candidateFit, "Status", None]];
    pilotFit = candidateFit;
    candidateStatus = Lookup[candidateFit, "Status", None];
    If[candidateStatus ===
        "FiniteFieldBasisTransformationReexpressionFibreFitV1",
      numeratorBounds = candidateNumeratorBounds;
      denominatorBounds = candidateBounds;
      numeratorSupport = candidateNumeratorSupport;
      denominatorSupport = candidateDenominatorSupport;
      Break[]];
    If[candidateIndex === 1,
      denominatorBoundCandidates = Take[Join[
        denominatorBoundCandidates,
        If[candidateStatus ===
            "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
          Join[smallerBounds, largerBounds], largerBounds]],
        UpTo[maximumDenominatorCandidates]]];
    If[! MemberQ[{
          "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
          "FiniteFieldBasisTransformationReexpressionDenominatorModelInconsistent",
          "FiniteFieldBasisTransformationReexpressionCommonDenominatorInsufficient"},
        candidateStatus], Return[candidateFit]];
    candidateIndex++];
  If[Lookup[pilotFit, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionFibreFitV1",
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
      If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline], Break[]];
      fit = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionFitFibre[
        points, fibreValues[[index]], activeOutputs,
        numeratorSupport, denominatorSupport, prime, heldOut,
        anchors, normalization]]}, phaseSeconds["FitFibreSeconds"] = Lookup[phaseSeconds, "FitFibreSeconds", 0.] + First[timed]; Last[timed]];
      If[Lookup[fit, "Status", None] =!=
          "FiniteFieldBasisTransformationReexpressionFibreFitV1", Continue[]];
      vector = Join[Flatten[Transpose[fit["NumeratorCoefficients"]]],
        Delete[fit["DenominatorCoefficients"], normalization]];
      AppendTo[acceptedImages, specialized["EpsilonImages"][[index]]];
      AppendTo[fits, vector],
      {index, Length[specialized["EpsilonImages"]]}];
    If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline],
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
        <|"Stage" -> "RegulatorFibres", "Prime" -> prime,
          "CompletedFibres" -> Length[fits]|>]]];
    canonicalSamples = MapThread[
      <|"EpsilonMod" -> Mod[#1, prime], "Values" -> #2|> &,
      {acceptedImages, fits}];
    interpolation = If[Length[canonicalSamples] < 4 + epsilonHeldOut,
      <|"Status" -> "MoreSamplesRequired",
        "RequiredAdditionalSampleCount" ->
          4 + epsilonHeldOut - Length[canonicalSamples],
        "Reason" -> "InsufficientRegularBasisTransformationFibres"|>,
      finiteFieldOffDiagonalBlockHeldOutInterpolate[
        canonicalSamples, prime,
        "InitialConstructionCount" -> 4,
        "HeldOutCount" -> epsilonHeldOut,
        "MaximumTotalDegree" -> maximumEpsilon,
        "ExpectedDegrees" -> expectedEpsilon]];
    interpolationStatus = Lookup[interpolation, "Status", None];
    If[interpolationStatus === "HeldOutValidated", Break[]];
    If[interpolationStatus =!= "MoreSamplesRequired",
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionRegulatorInterpolationFailed",
        <|"Prime" -> prime, "Detail" -> interpolation,
          "AcceptedFibres" -> Length[fits]|>]]];
    requiredAdditional = Max[1, Lookup[interpolation,
      "RequiredAdditionalSampleCount", 1]];
    nextFibreBudget = Min[availableFibreCount,
      Length[specialized["EpsilonImages"]] +
        Max[4, requiredAdditional]];
    If[nextFibreBudget <= Length[specialized["EpsilonImages"]],
      Return[finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionRegulatorInterpolationFailed",
        <|"Prime" -> prime, "Detail" -> interpolation,
          "AcceptedFibres" -> Length[fits],
          "AvailableFibres" -> availableFibreCount|>]]];
    specialized = With[{timed = AbsoluteTiming[finiteFieldBasisTransformationReexpressionTakeFibres[
      fullSpecialized, nextFibreBudget]]}, phaseSeconds["TakeFibresSeconds"] = Lookup[phaseSeconds, "TakeFibresSeconds", 0.] + First[timed]; Last[timed]];
    records = {};
    pointAttempts = 0;
    pointResult = ensurePointCount[requiredPoints];
    If[AssociationQ[pointResult], Return[pointResult]];
    points = Lookup[records, "Point"]];
  expectedProfile = Lookup[interpolation["Interpolations"], "Degrees"];
  log["[finite-field basisTransformationBlock pullback] prime ", prime,
    ": points ", Length[points], ", fibres ", Length[fits],
    ", outputs ", plan["EntryCount"] plan["GradeCount"],
    ", bounds ", numeratorBounds, "/", denominatorBounds];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionPrimeV1",
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
    (* round-8 phase timers (2026-09-02) *)
    Sequence @@ Normal[phaseSeconds],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
finiteFieldBasisTransformationReexpressionPrime[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionPrimeArgumentsInvalid"];

(* Helper-side follower-prime entry point.  The first good prime remains on
   the mission kernel because it discovers the degree/support model.  This
   task receives that immutable model and computes one independent later
   prime; the mission admits results in the original prime order. *)
finiteFieldBasisTransformationReexpressionPrimeTask[dataFile_String, prime_Integer] := Module[
  {payload, result},
  payload = taskBrokerRead[dataFile];
  If[! AssociationQ[payload] ||
      Lookup[Lookup[payload, "Plan", <||>], "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionPlanV1" ||
      ! MatchQ[Lookup[payload, "Options", None], {___Rule}],
    Return[$Failed]];
  result = finiteFieldBasisTransformationReexpressionPrime[payload["Plan"], prime,
    Sequence @@ payload["Options"]];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionPrimeTaskV1",
    "Prime" -> prime, "Result" -> result|>
];
finiteFieldBasisTransformationReexpressionPrimeTask[___] := $Failed;

finiteFieldBasisTransformationReexpressionLift[plan_Association,
    modularData_List] := Module[
  {primes, coordinateCount, combinedModulus, padded, liftedPairs,
   liftedVector, epsilon, first, numeratorSupport, denominatorSupport,
   normalization, outputCount, numeratorCount, denominatorCount,
   numeratorFunctions, denominatorFunctions, denominatorCoefficients,
   numeratorCoefficientPairs, denominatorCoefficientPairs,
   coefficientRepresentation, denominator, channelNumerators, entries},
  If[modularData === {} || ! AllTrue[modularData,
      Lookup[#, "Status", None] === "FiniteFieldBasisTransformationReexpressionPrimeV1" &],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionLiftInputInvalid"]]];
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionPrimeRecordsIncompatible"]]];
  coordinateCount = Length[first["Interpolations"]];
  combinedModulus = Times @@ primes;
  padded = Table[epsFormFiniteFieldPaddedCoordinate[
      modularData[[All, "Interpolations", coordinate]]],
    {coordinate, coordinateCount}];
  If[MemberQ[padded, $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionCRTFailed"]]];
  liftedPairs = Map[<|
      "NumeratorCoefficients" -> modularLift[#["Numerator"], primes],
      "DenominatorCoefficients" -> modularLift[#["Denominator"], primes]|> &,
    padded];
  If[! FreeQ[liftedPairs, $Failed],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionModulusTooSmall",
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionLiftShapeInvalid"]]];
  numeratorFunctions = ArrayReshape[
    Take[liftedVector, outputCount numeratorCount],
    {outputCount, numeratorCount}];
  numeratorCoefficientPairs = ArrayReshape[
    Take[liftedPairs, outputCount numeratorCount],
    {plan["EntryCount"], plan["GradeCount"], numeratorCount}];
  denominatorFunctions = Drop[liftedVector, outputCount numeratorCount];
  denominatorCoefficients = Insert[denominatorFunctions, 1, normalization];
  denominatorCoefficientPairs = Insert[
    Drop[liftedPairs, outputCount numeratorCount],
    <|"NumeratorCoefficients" -> {1},
      "DenominatorCoefficients" -> {1}|>, normalization];
  coefficientRepresentation = <|
    "Status" ->
      "FiniteFieldBasisTransformationCoefficientRepresentationV1",
    "Dimensions" -> plan["Dimensions"],
    "Variables" -> plan["Variables"],
    "Regulator" -> epsilon,
    "RootCount" -> plan["RootCount"],
    "GradeCount" -> plan["GradeCount"],
    "NumeratorSupport" -> numeratorSupport,
    "NumeratorCoefficientPairs" -> numeratorCoefficientPairs,
    "DenominatorSupport" -> denominatorSupport,
    "DenominatorCoefficientPairs" -> denominatorCoefficientPairs|>;
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
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionComposeFailed"]]];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionLiftedV1",
    "Result" -> ArrayReshape[entries, plan["Dimensions"]],
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "NumeratorSupport" -> numeratorSupport,
    "DenominatorSupport" -> denominatorSupport,
    "NormalizationIndex" -> normalization,
    "Denominator" -> denominator,
    "CoefficientRepresentation" -> coefficientRepresentation|>
];
finiteFieldBasisTransformationReexpressionLift[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionLiftArgumentsInvalid"];

Options[finiteFieldBasisTransformationReexpressionCommon] = {
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

finiteFieldBasisTransformationReexpressionCommon[parametrizedBasisTransformationBlock_List,
    parametrizedBasisTransformationDenominator_, parametrizingVariables : {_Symbol, _Symbol},
    coordinateImages : {_, _}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, roots_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], primes, minimumPrimeCount, maximumPrimeCount,
   deadline, verbose, plan, modularData = {}, first = None, record, lift,
   selectedPrimes, terminal = None, lastModelRefusal = None,
   primeOptions, computePrime, admitPrime, primeIndex = 1, helperCount,
   wave, waveOptions, dataFile, helperPrimes, codes, handle, localRecord,
   helperRecords, waveRecords, timeout, unwrapFollower},
  primes = DeleteDuplicates[OptionValue["Primes"]];
  minimumPrimeCount = OptionValue["MinimumPrimeCount"];
  maximumPrimeCount = OptionValue["MaximumPrimeCount"];
  deadline = OptionValue["Deadline"];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! finiteFieldBasisTransformationReexpressionDeadlineQ[deadline] ||
      ! IntegerQ[minimumPrimeCount] || minimumPrimeCount < 1 ||
      ! IntegerQ[maximumPrimeCount] ||
      maximumPrimeCount < minimumPrimeCount,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionOptionsInvalid"]]];
  selectedPrimes = Take[Select[primes,
    PrimeQ[#] && 3 < # < $multiquadraticOffDiagonalBlockWordPrimeLimit &],
    UpTo[maximumPrimeCount]];
  If[Length[selectedPrimes] < minimumPrimeCount,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionPrimeScheduleInsufficient"]]];
  plan = finiteFieldBasisTransformationReexpressionPlan[parametrizedBasisTransformationBlock, parametrizedBasisTransformationDenominator,
    parametrizingVariables, coordinateImages, variables, epsilon, roots];
  If[Lookup[plan, "Status", None] =!= "FiniteFieldBasisTransformationReexpressionPlanV1",
    Return[plan]];
  primeOptions[] := {
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
    "Deadline" -> deadline, "Verbose" -> verbose};
  computePrime[prime_Integer] := finiteFieldBasisTransformationReexpressionPrime[
    plan, prime, Sequence @@ primeOptions[]];
  admitPrime[prime_Integer, candidate_] := Module[{candidateStatus},
    If[Lookup[candidate, "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionPrimeV1",
      candidateStatus = Lookup[candidate, "Status", None];
      If[verbose, Print["[finite-field basisTransformationBlock pullback] rejected prime ",
        prime, ": ", candidateStatus]];
      If[candidateStatus === "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
        terminal = candidate; Return["Terminal"]];
      If[candidateStatus ===
          "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
        lastModelRefusal = candidate; Return["Continue"]];
      If[MemberQ[{"FiniteFieldBasisTransformationReexpressionSliceDegreeExceeded",
            "FiniteFieldBasisTransformationReexpressionDenominatorModelInconsistent",
            "FiniteFieldBasisTransformationReexpressionCommonDenominatorInsufficient",
            "FiniteFieldBasisTransformationReexpressionNoReducedDenominatorModel"},
          candidateStatus],
        terminal = candidate; Return["Terminal"]];
      Return["Continue"]];
    AppendTo[modularData, candidate];
    If[first === None, first = candidate];
    If[Length[modularData] >= minimumPrimeCount,
      lift = finiteFieldBasisTransformationReexpressionLift[plan, modularData];
      If[Lookup[lift, "Status", None] ===
          "FiniteFieldBasisTransformationReexpressionLiftedV1",
        terminal = Join[lift, <|
          "Status" -> "FiniteFieldBasisTransformationReexpressionConstructed",
          "Seconds" -> N[AbsoluteTime[] - started],
          "Plan" -> KeyTake[plan, {"Dimensions", "RootCount",
            "GradeCount", "ParametrizingVariableSupportCount", "OffDiagonalBasisTransformationNumeratorTermCounts",
            "DenominatorTermCount", "BuildSeconds"}],
          "PrimeRecords" -> (KeyDrop[#, "Interpolations"] & /@
            modularData)|>];
        Return["Terminal"]]];
    "Accepted"
  ];
  (* Model discovery is adaptive and therefore serial until the first good
     prime.  Exceptional primes retain the historical skip/terminal policy. *)
  While[primeIndex <= Length[selectedPrimes] && first === None &&
      terminal === None,
    If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline],
      terminal = finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
        <|"Stage" -> "PrimeLoop", "CompletedPrimes" -> Length[modularData],
          "Seconds" -> N[AbsoluteTime[] - started]|>];
      Break[]];
    record = computePrime[selectedPrimes[[primeIndex]]];
    admitPrime[selectedPrimes[[primeIndex]], record];
    primeIndex++];
  (* Once the model exists, later primes are independent.  Use waves of at
     most three (one local, two helpers), then admit them in schedule order;
     a lift at an earlier prefix discards only bounded speculative work. *)
  unwrapFollower[wrapped_, prime_Integer, options_List] := If[
    AssociationQ[wrapped] &&
      Lookup[wrapped, "Status", None] ===
        "FiniteFieldBasisTransformationReexpressionPrimeTaskV1" &&
      Lookup[wrapped, "Prime", None] === prime &&
      AssociationQ[Lookup[wrapped, "Result", None]],
    wrapped["Result"],
    finiteFieldBasisTransformationReexpressionPrime[plan, prime, Sequence @@ options]];
  While[primeIndex <= Length[selectedPrimes] && terminal === None,
    If[finiteFieldBasisTransformationReexpressionExpiredQ[deadline],
      terminal = finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionDeadlineExpired",
        <|"Stage" -> "PrimeLoop", "CompletedPrimes" -> Length[modularData],
          "Seconds" -> N[AbsoluteTime[] - started]|>];
      Break[]];
    helperCount = If[taskBrokerActiveQ[],
      Min[2, taskBrokerFreeKernels[],
        Length[selectedPrimes] - primeIndex], 0];
    wave = Take[selectedPrimes[[primeIndex ;;]],
      UpTo[1 + helperCount]];
    waveOptions = primeOptions[];
    If[helperCount > 0,
      dataFile = taskBrokerDataFile[
        "ffgpb_" <> StringReplace[CreateUUID[], "-" -> ""],
        <|"Plan" -> plan, "Options" -> waveOptions|>];
      helperPrimes = Rest[wave];
      codes = Map[StringJoin[
          "FeynFacet`Private`finiteFieldBasisTransformationReexpressionPrimeTask[",
          ToString[dataFile, InputForm], ", ", ToString[#], "]"] &,
        helperPrimes];
      timeout = If[NumericQ[deadline],
        Max[1., deadline - AbsoluteTime[]], 7200];
      handle = taskBrokerSubmit[codes, "Timeout" -> timeout,
        "Label" -> "ffgpb"];
      localRecord = finiteFieldBasisTransformationReexpressionPrime[plan, First[wave],
        Sequence @@ waveOptions];
      helperRecords = taskBrokerCollect[handle];
      waveRecords = Prepend[MapThread[
        unwrapFollower[#1, #2, waveOptions] &,
        {helperRecords, helperPrimes}], localRecord],
      waveRecords = {finiteFieldBasisTransformationReexpressionPrime[
        plan, First[wave], Sequence @@ waveOptions]}];
    Do[
      admitPrime[wave[[position]], waveRecords[[position]]];
      If[terminal =!= None, Break[]],
      {position, Length[wave]}];
    primeIndex += Length[wave]];
  If[AssociationQ[terminal], Return[terminal]];
  If[Length[modularData] < minimumPrimeCount,
    If[AssociationQ[lastModelRefusal], lastModelRefusal,
      finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionNotEnoughGoodPrimes",
        <|"GoodPrimeCount" -> Length[modularData]|>]],
    finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionModulusTooSmall",
      <|"GoodPrimeCount" -> Length[modularData]|>]]
];
finiteFieldBasisTransformationReexpressionCommon[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionArgumentsInvalid"];

finiteFieldBasisTransformationReexpressionModelRefusalQ[result_Association] := MemberQ[{
    "FiniteFieldBasisTransformationReexpressionSliceDegreeExceeded",
    "FiniteFieldBasisTransformationReexpressionDenominatorFitSingular",
    "FiniteFieldBasisTransformationReexpressionDenominatorModelInconsistent",
    "FiniteFieldBasisTransformationReexpressionCommonDenominatorInsufficient",
    "FiniteFieldBasisTransformationReexpressionNoReducedDenominatorModel"},
  Lookup[result, "Status", None]];
finiteFieldBasisTransformationReexpressionModelRefusalQ[_] := False;

Options[reexpressBasisTransformationInSourceVariablesFiniteField] = Join[
  Options[finiteFieldBasisTransformationReexpressionCommon],
  {"KinematicDegreeSchedule" -> Automatic,
   "SymbolicPreDispatchSeconds" -> 1.}];

(* A tiny compact composition gets one bounded canonical Together attempt.
   Otherwise try the reduced common model, then a bounded common-multiple
   model before independently widened entries.  The middle path is cheap
   when the shared model missed by only a few degrees, and its refusal leaves
   the existing per-entry fallback unchanged.  No raw composition is ever
   returned. *)
reexpressBasisTransformationInSourceVariablesFiniteField[parametrizedBasisTransformationBlock_List,
    parametrizedBasisTransformationDenominator_, parametrizingVariables : {_Symbol, _Symbol},
    coordinateImages : {_, _}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, roots_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], baseCap, schedule, common, expandedCommon,
   commonCap = None, expandedCandidateLimit, entrySchedule, runCommon,
   dimensions, entries, reconstructed, entryRecords = {}, result,
   attemptRecords, accepted, acceptedCap, entry, row, column,
   symbolicLimit, symbolicBudget, symbolicSeconds, symbolic,
   validationPlan, deadline, entryFailure = None},
  baseCap = OptionValue["MaximumKinematicTotalDegree"];
  symbolicLimit = OptionValue["SymbolicPreDispatchSeconds"];
  deadline = OptionValue["Deadline"];
  If[! IntegerQ[baseCap] || baseCap < 0,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionOptionsInvalid"]]];
  If[! NumericQ[symbolicLimit] || symbolicLimit < 0,
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionOptionsInvalid"]]];
  runCommon[basisTransformationBlock_, cap_Integer, aggregation_String,
      candidateLimit_: Automatic] :=
    finiteFieldBasisTransformationReexpressionCommon[basisTransformationBlock, parametrizedBasisTransformationDenominator,
      parametrizingVariables, coordinateImages, variables, epsilon, roots,
      "Primes" -> OptionValue["Primes"],
      "MinimumPrimeCount" -> OptionValue["MinimumPrimeCount"],
      "MaximumPrimeCount" -> OptionValue["MaximumPrimeCount"],
      "MaximumKinematicTotalDegree" -> cap,
      "MaximumEpsilonTotalDegree" ->
        OptionValue["MaximumEpsilonTotalDegree"],
      "HeldOutPointCount" -> OptionValue["HeldOutPointCount"],
      "EpsilonHeldOutCount" -> OptionValue["EpsilonHeldOutCount"],
      "DenominatorDegreeAggregation" -> aggregation,
      "MaximumDenominatorCandidates" -> Replace[candidateLimit,
        Automatic -> OptionValue["MaximumDenominatorCandidates"]],
      "Deadline" -> OptionValue["Deadline"],
      "Verbose" -> OptionValue["Verbose"]];
  validationPlan = finiteFieldBasisTransformationReexpressionPlan[parametrizedBasisTransformationBlock,
    parametrizedBasisTransformationDenominator, parametrizingVariables, coordinateImages, variables,
    epsilon, roots];
  If[Lookup[validationPlan, "Status", None] =!=
      "FiniteFieldBasisTransformationReexpressionPlanV1", Return[validationPlan]];
  symbolicBudget = If[deadline === Infinity, symbolicLimit,
    Min[symbolicLimit, Max[0., N[deadline - AbsoluteTime[]]]]];
  If[symbolicBudget > 0.,
    {symbolicSeconds, symbolic} = AbsoluteTiming[TimeConstrained[
      Map[Together,
        parametrizedBasisTransformationBlock /. Thread[parametrizingVariables -> coordinateImages], {2}],
      symbolicBudget, $Aborted]];
    If[ListQ[symbolic] && Dimensions[symbolic] === Dimensions[parametrizedBasisTransformationBlock] &&
        FreeQ[symbolic, Alternatives @@ parametrizingVariables],
      Return[<|"Status" -> "FiniteFieldBasisTransformationReexpressionConstructed",
        "Result" -> symbolic, "Model" -> "SymbolicSmallV1",
        "Plan" -> KeyTake[validationPlan, {"Dimensions", "RootCount",
          "GradeCount", "ParametrizingVariableSupportCount", "OffDiagonalBasisTransformationNumeratorTermCounts",
          "DenominatorTermCount", "BuildSeconds"}],
        "Seconds" -> N[AbsoluteTime[] - started],
        "SymbolicSeconds" -> N[symbolicSeconds]|>]]];
  schedule = Replace[OptionValue["KinematicDegreeSchedule"],
    Automatic :> {baseCap, Ceiling[3 baseCap/2], 2 baseCap,
      3 baseCap, 4 baseCap, 6 baseCap, 8 baseCap}];
  If[! ListQ[schedule] ||
      ! AllTrue[schedule, IntegerQ[#] && # >= baseCap &],
    Return[finiteFieldBasisTransformationReexpressionFailure[
      "FiniteFieldBasisTransformationReexpressionDegreeScheduleInvalid",
      <|"Schedule" -> schedule, "BaseDegree" -> baseCap|>]]];
  schedule = Sort[DeleteDuplicates[Prepend[schedule, baseCap]]];
  acceptedCap = None;
  Do[
    common = runCommon[parametrizedBasisTransformationBlock, cap, "Maximum"];
    If[Lookup[common, "Status", None] ===
        "FiniteFieldBasisTransformationReexpressionConstructed",
      acceptedCap = cap; Break[]];
    If[Lookup[common, "Status", None] =!=
        "FiniteFieldBasisTransformationReexpressionSliceDegreeExceeded",
      commonCap = cap; Break[]],
    {cap, schedule}];
  If[IntegerQ[acceptedCap],
    Return[Join[common, <|"Model" -> "CommonDenominatorV1",
      "KinematicDegreeCap" -> acceptedCap|>]]];
  If[! finiteFieldBasisTransformationReexpressionModelRefusalQ[common], Return[common]];
  (* Slice discovery has already established that this cap contains every
     output.  A common denominator can be slightly wider than the component-
     wise maximum of the reduced output denominators.  Search only the first
     eight product-ceiling candidates: a measured production block took 207.3 s here
     versus 717.0 s through four independent reconstructions.  A genuinely
     wide least common multiple falls through after this bounded attempt. *)
  If[IntegerQ[commonCap],
    expandedCandidateLimit = Min[8,
      OptionValue["MaximumDenominatorCandidates"]];
    expandedCommon = runCommon[parametrizedBasisTransformationBlock, commonCap, "ProductCeiling",
      expandedCandidateLimit];
    If[Lookup[expandedCommon, "Status", None] ===
        "FiniteFieldBasisTransformationReexpressionConstructed",
      Return[Join[expandedCommon,
        <|"Model" -> "ExpandedCommonDenominatorV1",
          "KinematicDegreeCap" -> commonCap|>]]]];
  (* Every entry is a subset of the already successful whole-basisTransformationBlock slice
     census, so caps below commonCap cannot add information. *)
  entrySchedule = If[IntegerQ[commonCap],
    Select[schedule, # >= commonCap &], schedule];
  dimensions = Dimensions[parametrizedBasisTransformationBlock];
  entries = Flatten[parametrizedBasisTransformationBlock];
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
          "FiniteFieldBasisTransformationReexpressionConstructed",
        accepted = result; acceptedCap = cap; Break[]];
      (* A larger slice cap can repair only a slice interpolation that hit
         that cap.  Once slice degrees were discovered, denominator-model
         inconsistency is independent of the cap; retrying it at every rung
         repeated the same 64-candidate scan at 36, 48, 72 and 96. *)
      If[Lookup[result, "Status", None] =!=
          "FiniteFieldBasisTransformationReexpressionSliceDegreeExceeded",
        entryFailure = Join[result, <|"Entry" -> {row, column},
          "DegreeCaps" -> entrySchedule,
          "EntryAttempts" -> attemptRecords|>];
        Break[]],
      {cap, entrySchedule}];
    If[AssociationQ[entryFailure], Break[]];
    If[! AssociationQ[accepted],
      entryFailure = finiteFieldBasisTransformationReexpressionFailure[
        "FiniteFieldBasisTransformationReexpressionReducedModelRefused",
        <|"Entry" -> {row, column}, "DegreeCaps" -> entrySchedule,
          "EntryAttempts" -> attemptRecords,
          "Detail" -> result|>];
      Break[]];
    reconstructed[[index]] = accepted["Result"][[1, 1]];
    AppendTo[entryRecords, <|"Entry" -> {row, column},
      "Status" -> "FiniteFieldBasisTransformationReexpressionConstructed",
      "DegreeCap" -> acceptedCap,
      "Primes" -> accepted["Primes"],
      "Seconds" -> accepted["Seconds"]|>],
    {index, Length[entries]}];
  If[AssociationQ[entryFailure], Return[entryFailure]];
  <|"Status" -> "FiniteFieldBasisTransformationReexpressionConstructed",
    "Result" -> ArrayReshape[reconstructed, dimensions],
    "Model" -> "PerEntryDenominatorsV1",
    "EntryRecords" -> entryRecords,
    "CommonModelRefusal" -> KeyDrop[common, {"Result", "Interpolations"}],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
reexpressBasisTransformationInSourceVariablesFiniteField[___] :=
  finiteFieldBasisTransformationReexpressionFailure[
    "FiniteFieldBasisTransformationReexpressionArgumentsInvalid"];
