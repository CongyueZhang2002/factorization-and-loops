#!/usr/bin/env wolframscript

(* A square-root presentation prefers a regular rational base at which its
   declared generators take nonzero rational values.  The selected third
   scalar is exposed only through the first path parameter's affine scale. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`splitPathX"];
y = Symbol["Global`splitPathY"];
u = Symbol["Global`splitPathU"];
z = Symbol["Global`splitPathZ"];
eps = Symbol["Global`eps"];

sourceVariablePresentation = <|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "SourceVariables" -> {x, y},
  "CoefficientVariables" -> {x, y},
  "SourceVariableSubstitution" -> {x -> x, y -> y},
  "DifferentialPullbackMatrix" -> IdentityMatrix[2],
  "JacobianDeterminant" -> 1|>;
baseRecord = <|
  "CoefficientVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "BasisTransformationMatrix" -> {{1}},
  "CachedInverseBasisTransformationMatrix" -> {{1}},
  "Letters" -> {x, y, 1 - x, 1 - y},
  "ConstantResidueMatrices" -> ConstantArray[{{0}}, 4],
  "CoefficientPresentation" -> sourceVariablePresentation|>;

squareRootPresentation =
  BuildSquareRootGeneratorsAndQuadraticRelations[
    {1 - x, 1 - y}, {x, y}, {u, z}];
algebraicRecord = <|
  "CoefficientVariables" -> {u, z},
  "DimensionalRegulator" -> eps,
  "BasisTransformationMatrix" -> {{1}},
  "CachedInverseBasisTransformationMatrix" -> {{1}},
  "Letters" -> {u, z, 1 - u, 1 - z},
  "ConstantResidueMatrices" -> ConstantArray[{{0}}, 4],
  "CoefficientPresentation" -> squareRootPresentation|>;
algebraicPath = ChooseRegularBasePointAndFirstPathParameterScale[
  algebraicRecord];
algebraicBase = Lookup[algebraicPath, {"FirstBase", "SecondBase"}, {}];
algebraicSquares = ({1 - u, 1 - z} /.
  Thread[{u, z} -> algebraicBase]);

FTAssert["a square-root presentation prefers a rational split base",
  Lookup[algebraicPath, "Status", None] ===
      "RegularBasePointAndFirstPathParameterScaleSelected" &&
    algebraicBase === {3/4, 3/4} &&
    FeynFacet`Private`observableTransportRecordRegularQ[algebraicRecord,
      Thread[{u, z} -> algebraicBase]]];
FTAssert["every declared square root is nonzero and rational at that base",
  algebraicSquares === {1/4, 1/4} &&
    VectorQ[Sqrt[algebraicSquares],
      MatchQ[#, _Integer | _Rational] && # =!= 0 &]];

rationalPath = ChooseRegularBasePointAndFirstPathParameterScale[baseRecord];
FTAssert["the rational presentation retains deterministic candidate order",
  Lookup[rationalPath,
    {"FirstBase", "SecondBase", "FirstPathParameterScale"}, {}] ===
      {1/4, 1/4, 1/12}];

constantSquareRootPresentation =
  BuildSquareRootGeneratorsAndQuadraticRelations[{2}, {x, y}, {u, z}];
fallbackRecord = Join[algebraicRecord, <|
  "CoefficientPresentation" -> constantSquareRootPresentation|>];
fallbackPath = ChooseRegularBasePointAndFirstPathParameterScale[
  fallbackRecord, "Candidates" -> {{1/4, 1/4, 1/3}}];
FTAssert["a presentation with no split candidate uses the regular fallback",
  Lookup[fallbackPath,
    {"Status", "FirstBase", "SecondBase",
      "FirstPathParameterScale"}, {}] ===
      {"RegularBasePointAndFirstPathParameterScaleSelected",
        1/4, 1/4, 1/12}];

FTReport[];
