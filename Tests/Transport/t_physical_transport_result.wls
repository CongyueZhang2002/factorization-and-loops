#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`physicalResultU"];
eps = Symbol["Global`physicalResultEps"];
source = <|"Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {ConstantArray[0, {2, 2}]}|>;
layer = <|"Rows" -> {3, 4},
  "PathVariable" -> u, "Regulator" -> eps,
  "BasePoint" -> 0, "PathEndpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -2}, ConstantArray[0, {2, 2}]}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>
  }|>;
boundaryCoefficientLabels = {{"a", 0}, {"b", 0}, {"c", 0}, {"d", 0}};
boundarySelectors = <|
  "Status" -> "FormalBoundarySelectorMatricesConstructed",
  "BoundaryDataType" -> "BoundaryConstant",
  "BoundaryConstantEpsilonCoefficientLabels" -> boundaryCoefficientLabels,
  "BoundarySelectorMatricesByEpsilonOrder" ->
    <|0 -> IdentityMatrix[4]|>|>;
boundary = <|
  "Status" -> "FormalBoundaryConstantValueVectorConstructed",
  "BoundaryDataType" -> "BoundaryConstant",
  "BoundaryDataStatus" -> "FormalNotEvaluated",
  "BoundaryConstantEpsilonCoefficientRecords" -> Map[
    <|"BoundaryDataType" -> "BoundaryConstant",
      "BoundaryConstantID" -> First[#],
      "DeclaredBoundaryConstantAnalyticClass" ->
        If[First[#] === "b", "Elliptic", "GPL"],
      "EpsilonOrder" -> Last[#]|> &, boundaryCoefficientLabels],
  "BoundaryConstantEpsilonCoefficientLabels" -> boundaryCoefficientLabels,
  "BoundaryConstantVector" -> {
    BoundaryConstantEpsilonCoefficient["a", 0],
    BoundaryConstantEpsilonCoefficient["b", 0],
    BoundaryConstantEpsilonCoefficient["c", 0],
    BoundaryConstantEpsilonCoefficient["d", 0]},
  "BoundaryDataRequirements" -> Table[
    <|"BoundaryDataType" -> "BoundaryConstant",
      "BoundaryConstantID" -> id,
      "BoundaryConstantEpsilonCoefficientLabels" -> {{id, 0}},
      "Status" -> "Unevaluated"|>, {id, {"a", "b", "c", "d"}}]
|>;

attached = AttachBoundarySelectorsToRationalEpsilonDependentBlock[
  source, layer, boundarySelectors, {1, 2}, {3, 4}];
demand = <|"RequestedOutputPairs" -> {{0, 1}, {0, 2}}|>;
transport = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  attached["Source"], attached["Block"], demand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator", "PrimeCount" -> 3];
operator = ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
  attached["Source"], attached["Block"], transport];

FTAssert["full-system boundary selector matrices are split into one shared boundary-constant coefficient space and bound to the solved block",
  attached["Status"] ===
    "BoundarySelectorsAttachedToRationalEpsilonDependentBlock" &&
  transport["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
  transport["IteratedIntegralCoefficientRepresentation"] === "LazyCoefficientOperator" &&
  transport["OffDiagonalBasisTransformationBlockAtPathEndpoint"][0] === IdentityMatrix[2] &&
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator] &&
  operator["BoundaryLayout"] === "Shared" &&
  operator["Dimensions", "TotalBoundary"] === 4];

coefficient = ConstructMasterIntegralEpsilonExpansionCoefficient[operator, boundary,
  {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
    "PathEndpoint" -> 1|>];
FTAssert["the off-diagonal basis-transformation block at the path endpoint and target boundary combine into a master-integral epsilon-expansion coefficient",
  coefficient["Status"] ===
    "MasterIntegralEpsilonExpansionCoefficientConstructed" &&
  coefficient["IteratedIntegralTermCount"] === 1 &&
  coefficient["Expression"] ===
    BoundaryConstantEpsilonCoefficient["a", 0] +
      BoundaryConstantEpsilonCoefficient["c", 0] &&
  coefficient["ActiveBoundaryDataRequirements",
      "ActiveBoundaryEpsilonCoefficientLabels"] ===
    {{"a", 0}, {"c", 0}} &&
  Length[coefficient["ActiveBoundaryDataRequirements",
      "BoundaryDataRequirements"]] === 2];

boundaryFunctionLabels =
  {{"fa", 0}, {"fb", 0}, {"fc", 0}, {"fd", 0}};
boundaryFunctionSelectors = <|
  "Status" -> "FormalBoundarySelectorMatricesConstructed",
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryFunctionEpsilonCoefficientLabels" -> boundaryFunctionLabels,
  "BoundarySelectorMatricesByEpsilonOrder" ->
    <|0 -> IdentityMatrix[4]|>|>;
boundaryFunctions = <|
  "Status" -> "FormalBoundaryFunctionValueVectorConstructed",
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryDataStatus" -> "FormalNotEvaluated",
  "BoundaryFunctionEpsilonCoefficientRecords" -> Map[
    <|"BoundaryDataType" -> "BoundaryFunction",
      "BoundaryFunctionID" -> First[#],
      "DeclaredBoundaryFunctionClass" -> "GPL",
      "EpsilonOrder" -> Last[#]|> &, boundaryFunctionLabels],
  "BoundaryFunctionEpsilonCoefficientLabels" -> boundaryFunctionLabels,
  "BoundaryFunctionVector" ->
    (BoundaryFunctionEpsilonCoefficient @@ # & /@ boundaryFunctionLabels),
  "BoundaryDataRequirements" -> Map[
    <|"BoundaryDataType" -> "BoundaryFunction",
      "BoundaryFunctionID" -> First[#],
      "BoundaryFunctionEpsilonCoefficientLabels" -> {#},
      "Status" -> "Unevaluated"|> &, boundaryFunctionLabels]|>;
functionAttached = AttachBoundarySelectorsToRationalEpsilonDependentBlock[
  source, layer, boundaryFunctionSelectors, {1, 2}, {3, 4}];
functionSolution = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  functionAttached["Source"], functionAttached["Block"], demand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator",
  "PrimeCount" -> 3];
functionOperator =
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    functionAttached["Source"], functionAttached["Block"],
    functionSolution];
functionCoefficient = ConstructMasterIntegralEpsilonExpansionCoefficient[
  functionOperator, boundaryFunctions, {0, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "PathEndpoint" -> 1|>];
FTAssert["a positive-dimensional boundary stratum remains typed as boundary functions through the requested master-integral coefficient",
  functionCoefficient["Status"] ===
    "MasterIntegralEpsilonExpansionCoefficientConstructed" &&
  functionCoefficient["Expression"] ===
    BoundaryFunctionEpsilonCoefficient["fa", 0] +
      BoundaryFunctionEpsilonCoefficient["fc", 0] &&
  functionCoefficient["ActiveBoundaryDataRequirements",
      "BoundaryDataType"] === "BoundaryFunction" &&
  functionCoefficient["ActiveBoundaryDataRequirements",
      "ActiveBoundaryEpsilonCoefficientLabels"] ===
    {{"fa", 0}, {"fc", 0}}];

rebasedOperator = ChangeRationalEpsilonDependentBlockSolutionBasePoint[
  operator, 1/2,
  attached["Source", "BoundarySelectors"],
  attached["Block", "TargetBoundarySelectors"],
  "OffDiagonalTransformationBlockAtNewBase" -> <|0 -> 2/3 IdentityMatrix[2]|>,
  "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
    "LocalDirection" -> -1|>];
rebasedCoefficient = ConstructMasterIntegralEpsilonExpansionCoefficient[
  rebasedOperator, boundary, {0, 1},
  <|"Variable" -> u, "BasePoint" -> 1/2, "PathEndpoint" -> 1,
    "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
      "LocalDirection" -> -1|>|>];
FTAssert["the coefficient operator changes its lower integration limit and initial data without inverting an old-base series",
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[rebasedOperator] &&
  rebasedOperator["BasePointChange", "Method"] ===
    "SameDifferentialEquationWithNewBasePoint" &&
  Normal[rebasedOperator["TargetBoundarySelectors", 0][[1]]] ===
    {-2/3, 0, 1, 0} &&
  rebasedCoefficient["Status"] ===
    "MasterIntegralEpsilonExpansionCoefficientConstructed" &&
  rebasedCoefficient["Expression"] ===
    1/3 BoundaryConstantEpsilonCoefficient["a", 0] +
      BoundaryConstantEpsilonCoefficient["c", 0] &&
  rebasedCoefficient["Path", "BasePoint"] === 1/2 &&
  rebasedCoefficient["Path", "BasePointPrescription", "Type"] ===
    "TangentialRegularized"];

FTAssert["changing the base point refuses to guess a nonzero off-diagonal basis-transformation block or missing selector geometry",
  ChangeRationalEpsilonDependentBlockSolutionBasePoint[operator, 1/2,
    attached["Source", "BoundarySelectors"],
    attached["Block", "TargetBoundarySelectors"]]["Status"] ===
      "OffDiagonalBasisTransformationBlockAtNewBasePointRequired" &&
  ChangeRationalEpsilonDependentBlockSolutionBasePoint[operator, 1/2,
    <|0 -> {{1}}|>, attached["Block", "TargetBoundarySelectors"],
    "OffDiagonalTransformationBlockAtNewBase" -> <|0 -> 2/3 IdentityMatrix[2]|>]["Status"] ===
      "RationalEpsilonDependentBlockBasePointChangeSelectorsInvalid"];

gauged = ConstructMasterIntegralEpsilonExpansionCoefficient[operator, boundary,
  {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
    "PathEndpoint" -> 1|>,
  "CanonicalToPhysicalMasterIntegralMapByEpsilonOrder" ->
    <|0 -> {{0, 1}, {1, 0}}|>];
FTAssert["an epsilon-dependent map from the canonical target block to physical master integrals is applied after F=G+H source",
  gauged["Expression"] ===
    BoundaryConstantEpsilonCoefficient["b", 0] +
      BoundaryConstantEpsilonCoefficient["d", 0] &&
  gauged["ActiveBoundaryDataRequirements",
      "ActiveBoundaryEpsilonCoefficientLabels"] ===
    {{"b", 0}, {"d", 0}}];

curve = u^4 - u^3 + 5 u^2 - 2 u + 1;
ellipticLayer = Join[attached["Block"], <|
  "Curve" -> curve,
  "CurvePointValues" -> <||>,
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> eps,
      "Letter" -> {"E4Omega0"}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> eps,
      "Letter" -> {"E4Omega0"}|>
  }|>];
ellipticDemand = <|"RequestedOutputPairs" -> {{1, 1}}|>;
ellipticTransport = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  attached["Source"], ellipticLayer, ellipticDemand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator"];
ellipticOperator = ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
  attached["Source"], ellipticLayer, ellipticTransport];
ellipticCoefficient = ConstructMasterIntegralEpsilonExpansionCoefficient[
  ellipticOperator, boundary, {1, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "PathEndpoint" -> 1,
    "Curve" -> curve|>];
FTAssert["a mixed multiple/elliptic-polylogarithm solution keeps its surviving iterated-integral letter sequence explicit and restricts the outstanding boundary data to active coefficients",
  ellipticTransport["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
  ellipticTransport["Certificate", "VariationOfConstantsMethod"] === "ExactDLogDecomposition" &&
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[ellipticOperator] &&
  ellipticCoefficient["FunctionSpace"] === "GPL+Elliptic" &&
  ! FreeQ[ellipticCoefficient["Expression"],
    FormalChenIteratedIntegral[{{"E4Omega0"}}, ___]] &&
  ellipticCoefficient["ActiveBoundaryDataRequirements",
      "ActiveBoundaryEpsilonCoefficientLabels"] ===
    {{"a", 0}}];

tangentialEllipticOperator = ChangeRationalEpsilonDependentBlockSolutionBasePoint[
  ellipticOperator, 0, attached["Source", "BoundarySelectors"],
  attached["Block", "TargetBoundarySelectors"],
  "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
    "LocalDirection" -> 1|>];
tangentialEllipticCoefficient = ConstructMasterIntegralEpsilonExpansionCoefficient[
  tangentialEllipticOperator, boundary, {1, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "PathEndpoint" -> 1,
    "Curve" -> curve,
    "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
      "LocalDirection" -> 1|>|>];
tangentialFunction =
  tangentialEllipticCoefficient["IteratedIntegralTerms"][[1]][
    "FormalIteratedIntegral"];
FTAssert["a letter sequence from a singular base point carries its tangential prescription in the formal integral",
  tangentialEllipticCoefficient["Status"] ===
      "MasterIntegralEpsilonExpansionCoefficientConstructed" &&
  Head[tangentialFunction] === FeynFacet`FormalChenIteratedIntegral &&
  First[List @@ tangentialFunction] === {{"E4Omega0"}} &&
  Last[List @@ tangentialFunction] ===
    <|"Type" -> "TangentialRegularized", "LocalDirection" -> 1|>];

FTAssert["paper expansion caps fail closed",
  ConstructMasterIntegralEpsilonExpansionCoefficient[ellipticOperator, boundary,
    {1, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "PathEndpoint" -> 1, "Curve" -> curve|>,
    "MaximumExpandedTerms" -> 0]["Status"] ===
      "MasterIntegralExpandedTermLimitInvalid"];

FTAssert["a different path, same-length different boundary basis, and an out-of-demand coefficient are refused",
  ConstructMasterIntegralEpsilonExpansionCoefficient[operator, boundary,
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "PathEndpoint" -> 2|>]["Status"] ===
      "MasterIntegralSolutionPathDoesNotMatchCoefficientOperator" &&
  ConstructMasterIntegralEpsilonExpansionCoefficient[operator,
    Join[boundary, <|"BoundaryConstantEpsilonCoefficientLabels" ->
      Reverse[boundary["BoundaryConstantEpsilonCoefficientLabels"]]|>],
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "PathEndpoint" -> 1|>]["Status"] ===
      "BoundaryValueVectorNotBoundToCoefficientOperator" &&
  ConstructMasterIntegralEpsilonExpansionCoefficient[operator, boundary,
    {1, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "PathEndpoint" -> 1|>]["Status"] ===
      "RequestedOutputOutsideSolvedPairs"];

FTSummary[];
