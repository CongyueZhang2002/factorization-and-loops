(* ::Package:: *)

(*
  External M2 prototype: carry an upstream normalized affine solution

      u(eps) = p(eps) + N(eps) alpha

  into a dependent strip at the same (prime, eps) image.  The downstream
  PDE only receives the image C = L N, so N never has to be interpolated
  or lifted unless it is part of the final surviving row state.

  This file deliberately defines only CodexM2* symbols and does not alter
  FeynFacet or CANONICA definitions.
*)

ClearAll[
  CodexM2DecodeGaugeVector,
  CodexM2ModularValue,
  CodexM2ForcingDirectionMatrix,
  CodexM2SchurCarryAnalysis,
  CodexM2CanonicalSampleValues,
  CodexM2InterpolateCoordinateVectors
];

CodexM2DecodeGaugeVector[
    vector_List, dimensions : {upper_Integer, lower_Integer},
    numeratorDegrees : {degreeX_Integer, degreeY_Integer},
    gaugeDenominator_, variables : {x_, y_}] := Module[
  {gaugeUnknownCount, columnIndex},
  gaugeUnknownCount = upper lower (degreeX + 1) (degreeY + 1);
  If[Length[vector] < gaugeUnknownCount, Return[$Failed]];
  columnIndex[i_, j_, px_, py_] :=
    (((i - 1) lower + (j - 1)) (degreeX + 1) + px)
      (degreeY + 1) + py + 1;
  Table[
    Sum[vector[[columnIndex[i, j, px, py]]] x^px y^py,
      {px, 0, degreeX}, {py, 0, degreeY}]/gaugeDenominator,
    {i, upper}, {j, lower}]
];

CodexM2ModularValue[
    expression_, variables : {x_, y_}, point : {_Integer, _Integer},
    prime_Integer] := Module[
  {value, numerator, denominator},
  value = Together[expression /. Thread[variables -> point]];
  If[! MatchQ[value, _Integer | _Rational], Return[$Failed]];
  numerator = Mod[Numerator[value], prime];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

CodexM2ForcingDirectionMatrix[
    directionGauges_List, cmix : {_, _}, epsilonValue_,
    acceptedPoints_List, variables : {_, _}, prime_Integer] := Module[
  {upper, priorWidth, lower, directionCount, deltaPrevious,
   deltaForcing, columns},
  If[directionGauges === {} || acceptedPoints === {} ||
      ! AllTrue[directionGauges, MatrixQ], Return[$Failed]];
  {upper, priorWidth} = Dimensions[First[directionGauges]];
  If[Dimensions[cmix][[1]] =!= 2 ||
      Dimensions[cmix[[1]]][[1]] < priorWidth,
    Return[$Failed]];
  lower = Dimensions[cmix[[1]]][[2]];
  directionCount = Length[directionGauges];
  deltaPrevious = Map[
    Join[#, ConstantArray[0,
      {upper, Dimensions[cmix[[1]]][[1]] - priorWidth}], 2] &,
    directionGauges];
  deltaForcing = Table[
    -epsilonValue deltaPrevious[[direction]].cmix[[mu]],
    {direction, directionCount}, {mu, 2}];
  columns = Table[
    Flatten[Table[
      CodexM2ModularValue[
        deltaForcing[[direction, mu, i, j]],
        variables, point, prime],
      {point, acceptedPoints}, {mu, 2}, {i, upper}, {j, lower}]],
    {direction, directionCount}];
  If[! FreeQ[columns, $Failed], Return[$Failed]];
  SparseArray[Transpose[columns]]
];

CodexM2SchurCarryAnalysis[
    downstreamMatrix_, downstreamRightHandSide_List,
    forcingDirections_, prime_Integer] := Module[
  {leftNullspace, leftNullspaceSeconds, schurMatrix, schurSeconds,
   schurRank, schurRankSeconds, allowedParameters,
   allowedNullity, selectedAllowedParameter, carriedRightHandSide,
   downstreamSolution, downstreamSolveSeconds, carriedResidualZero,
   forbiddenDirection, forbiddenLeftResidual,
   combinedMatrix, combinedRank, combinedRankSeconds,
   baseLeftResidualZero},
  If[! MatrixQ[downstreamMatrix] ||
      ! MatrixQ[forcingDirections] ||
      Dimensions[downstreamMatrix][[1]] =!=
        Length[downstreamRightHandSide] ||
      Dimensions[forcingDirections][[1]] =!=
        Length[downstreamRightHandSide], Return[$Failed]];
  {leftNullspaceSeconds, leftNullspace} = AbsoluteTiming[
    NullSpace[Transpose[downstreamMatrix], Modulus -> prime]];
  {schurSeconds, schurMatrix} = AbsoluteTiming[
    Mod[leftNullspace.forcingDirections, prime]];
  {schurRankSeconds, schurRank} = AbsoluteTiming[
    MatrixRank[schurMatrix, Modulus -> prime]];
  allowedParameters = NullSpace[schurMatrix, Modulus -> prime];
  allowedNullity = Length[allowedParameters];
  selectedAllowedParameter = If[allowedParameters === {},
    ConstantArray[0, Dimensions[forcingDirections][[2]]],
    First[allowedParameters]];
  carriedRightHandSide = Mod[
    downstreamRightHandSide +
      forcingDirections.selectedAllowedParameter, prime];
  {downstreamSolveSeconds, downstreamSolution} = AbsoluteTiming[
    Quiet[Check[LinearSolve[
      downstreamMatrix, carriedRightHandSide, Modulus -> prime],
      $Failed]]];
  carriedResidualZero = downstreamSolution =!= $Failed &&
    AllTrue[Mod[
      downstreamMatrix.downstreamSolution - carriedRightHandSide,
      prime], # === 0 &];
  forbiddenDirection = SelectFirst[
    Range[Dimensions[forcingDirections][[2]]],
    AnyTrue[schurMatrix[[All, #]], # =!= 0 &] &,
    Missing["NoForbiddenCoordinateDirection"]];
  forbiddenLeftResidual = If[MissingQ[forbiddenDirection], {},
    schurMatrix[[All, forbiddenDirection]]];
  combinedMatrix = Join[
    downstreamMatrix, SparseArray[Mod[-forcingDirections, prime]], 2];
  {combinedRankSeconds, combinedRank} = AbsoluteTiming[
    MatrixRank[combinedMatrix, Modulus -> prime]];
  baseLeftResidualZero = AllTrue[
    Flatten[Mod[leftNullspace.downstreamRightHandSide, prime]],
    # === 0 &];
  <|
    "DownstreamMatrixDimensions" -> Dimensions[downstreamMatrix],
    "DownstreamRank" -> MatrixRank[
      downstreamMatrix, Modulus -> prime],
    "DownstreamNullity" ->
      Dimensions[downstreamMatrix][[2]] - MatrixRank[
        downstreamMatrix, Modulus -> prime],
    "ForcingDirectionDimensions" -> Dimensions[forcingDirections],
    "ForcingDirectionNonzeroEntries" ->
      Length[SparseArray[forcingDirections]["NonzeroValues"]],
    "LeftNullspaceDimensions" -> Dimensions[leftNullspace],
    "LeftNullspaceSeconds" -> leftNullspaceSeconds,
    "BaseLeftResidualZero" -> baseLeftResidualZero,
    "SchurMatrix" -> schurMatrix,
    "SchurRank" -> schurRank,
    "SchurSeconds" -> schurSeconds,
    "SchurRankSeconds" -> schurRankSeconds,
    "AllowedUpstreamParameterBasis" -> allowedParameters,
    "AllowedUpstreamParameterNullity" -> allowedNullity,
    "SelectedAllowedParameter" -> selectedAllowedParameter,
    "CarriedDownstreamSolveSeconds" -> downstreamSolveSeconds,
    "CarriedDownstreamResidualZero" -> carriedResidualZero,
    "ForbiddenCoordinateDirection" -> forbiddenDirection,
    "ForbiddenLeftResidual" -> forbiddenLeftResidual,
    "CombinedMatrixDimensions" -> Dimensions[combinedMatrix],
    "CombinedRank" -> combinedRank,
    "CombinedNullity" -> Dimensions[combinedMatrix][[2]] - combinedRank,
    "CombinedRankSeconds" -> combinedRankSeconds
  |>
];

CodexM2CanonicalSampleValues[
    sample_Association, normalizationColumns_List,
    prime_Integer] := Module[{normalized},
  normalized = NormalizeEpsFormAffineSample[
    sample, normalizationColumns, prime];
  If[! AssociationQ[normalized], Return[$Failed]];
  <|
    "EpsilonValue" -> sample["EpsilonValue"],
    "EpsilonMod" -> Mod[
      Numerator[sample["EpsilonValue"]]
        PowerMod[Mod[Denominator[sample["EpsilonValue"]], prime],
          -1, prime], prime],
    "ParticularValues" -> normalized["ParticularSolution"],
    "NullspaceValues" -> Flatten[normalized["NullspaceBasis"]],
    "FullAffineValues" -> Join[
      normalized["ParticularSolution"],
      Flatten[normalized["NullspaceBasis"]]]
  |>
];

CodexM2InterpolateCoordinateVectors[
    canonicalSamples_List, valueKey_String, prime_Integer,
    constructionCount_Integer, maximumTotalDegree_Integer] := Module[
  {coordinateCount},
  If[canonicalSamples === {} ||
      ! AllTrue[canonicalSamples, AssociationQ] ||
      ! AllTrue[canonicalSamples, KeyExistsQ[#, valueKey] &],
    Return[$Failed]];
  coordinateCount = Length[First[canonicalSamples][valueKey]];
  Table[
    FeynFacet`Private`finiteFieldStripInterpolateCoordinate[
      ({#EpsilonMod, #[valueKey][[coordinate]]} &) /@
        canonicalSamples,
      prime, constructionCount, maximumTotalDegree],
    {coordinate, coordinateCount}]
];
