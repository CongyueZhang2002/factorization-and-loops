#!/usr/bin/env wolframscript

(* V2 regression for an algebraic dlog epsilon form.  This keeps the
   mathematical coverage of the former V1 test without reconstructing retired
   certificate, hash, chart, or gauge records. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

Clear[v, w, x, y, eps, master];
family = "AlgebraicRequestedOutputToy";
sourceLetter = 1 + Sqrt[1 - v];
letter = 1 + Sqrt[1 - x];
sourceConnection = {
  {{eps Together[D[sourceLetter, v]/sourceLetter]}},
  {{0}}
};
connection = {
  {{eps Together[D[letter, x]/letter]}},
  {{0}}
};
presentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {1 - v}, {v, w}, {x, y}];
familySystem = <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family,
  "KinematicVariables" -> {v, w},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {master[family, 1]},
  "ConnectionMatrices" -> sourceConnection|>;
systemReference = <|
  "RelativePath" -> "Tests/Fixtures/algebraic_requested_output_toy.wl",
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family|>;
workingResult = <|
  "Family" -> family,
  "CoefficientPresentation" -> presentation,
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Blocks" -> {{1}},
  "Ranges" -> {{1}},
  "TTotal" -> {{1}},
  "TTotalInverse" -> {{1}},
  "EpsFormX" -> connection[[1]],
  "EpsFormY" -> connection[[2]]|>;
form = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  workingResult, familySystem, systemReference,
  "IdentityMethod" -> "Symbolic"];

path = ChooseRegularBasePointAndFirstPathParameterScale[form];
demand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 1}, {1, 1}},
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 0,
  "RegularBasePointAndFirstPathParameterScale" -> path|>;
operator = ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  form, demand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];
constantCoefficient = If[AssociationQ[operator],
  ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
    operator, {}, {}], $Failed];

FTAssert["the algebraic V2 family is validated",
  ExactlyValidatedFamilyDLogEpsilonFormQ[form] &&
    form["CoefficientPresentation", "DataType"] ===
      "SquareRootGeneratorsAndQuadraticRelations"];
FTAssert["the selected regular base point splits the declared square root",
  AssociationQ[path] && path["Status"] ===
    "RegularBasePointAndFirstPathParameterScaleSelected" &&
    Together[Sqrt[(1 - x) /. x -> path["FirstBase"]]] === 1/2];
FTAssert["the requested-output iterated-integral coefficient operator is valid",
  AssociationQ[operator] &&
    operator["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[operator]];
FTAssert["the algebraic connection is represented by its dlog residue",
  operator["FirstPathSegmentKernelMethod"] === "DLogResidues" &&
    Length[operator["FirstPathSegmentIteratedIntegralKernels"]] === 2];
FTAssert["the zero-length iterated-integral coefficient is computed exactly",
  AssociationQ[constantCoefficient] &&
    constantCoefficient["Status"] ===
      "IteratedIntegralCoefficientMatrixComputed" &&
    TrueQ[constantCoefficient["MatrixArithmeticExact"]]];

FTReport[];
