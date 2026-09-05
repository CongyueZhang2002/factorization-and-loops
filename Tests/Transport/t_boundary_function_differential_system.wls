#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

p = Symbol["Global`boundarySystemP"];
eps = Symbol["Global`eps"];
jordan = {{0, 1}, {0, 0}};
gamma = eps/p IdentityMatrix[2] + jordan/(1 - p);
firstID = {"f", 1};
secondID = "f2";

modeMatching = <|
  "DataType" -> "BoundaryAsymptoticModeMatching", "SchemaVersion" -> 2,
  "Status" -> "BoundaryAsymptoticsMatchedToFrobeniusModes",
  "Family" -> "SyntheticBoundaryFunctionSystem",
  "Regulator" -> eps,
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {p}|>,
  "FrobeniusModes" -> {
    <|"BoundaryFunctionID" -> firstID,
      "BoundaryFunctionEpsilonValuation" -> 0,
      "PhysicalToLocalMode" -> {1, 0}|>,
    <|"BoundaryFunctionID" -> secondID,
      "BoundaryFunctionEpsilonValuation" -> 1,
      "PhysicalToLocalMode" -> {0, 1}|>}
|>;

induced = <|
  "DataType" -> "InducedBoundaryConnection", "SchemaVersion" -> 2,
  "TangentialVariables" -> {p}, "DimensionalRegulator" -> eps,
  "InverseNormalFrobeniusBasis" -> IdentityMatrix[2],
  "NormalResidueNormalForm" -> jordan,
  "InducedTangentialConnectionMatrices" -> {gamma}|>;

system = ConstructBoundaryFunctionDifferentialSystem[
  modeMatching, induced, "ValidationMethod" -> "Exact"];
FTAssert["the induced boundary-function system retains mixing inside a Jordan sector",
  BoundaryFunctionDifferentialSystemQ[system] &&
    system["BoundaryFunctionConnectionMatrices"][p] === gamma &&
    system["NormalResidueNormalForm"] === jordan &&
    TrueQ[system["Validation", "Conditions",
      "NormalResidueHorizontal"]] &&
    TrueQ[system["Validation", "Conditions",
      "BoundaryModeSubspaceInvariant"]]];

FTAssert["the predicate rejects missing mathematical conditions or incomplete valuation data",
  ! BoundaryFunctionDifferentialSystemQ[
      ReplacePart[system, {"Validation", "Conditions"} -> <||>]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system, "BoundaryFunctionEpsilonValuations"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      ReplacePart[system, "BoundaryFunctionIDs" -> {}]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      ReplacePart[system,
        {"BoundaryFunctionConnectionMatrices", Key[p]} -> {{1}}]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system, "NormalResidueNormalForm"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system,
        "BoundaryModeCoefficientMatrixInNormalResidueBasis"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system, "InducedTangentialConnectionMatrices"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system,
        "BoundaryFunctionConnectionEpsilonValuations"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system, "DifferentialEquationConvention"]] &&
    ! BoundaryFunctionDifferentialSystemQ[
      KeyDrop[system, "BoundaryModeMatrixRowRankCertificate"]]];

FTAssert["the mode-matching regulator must equal the connection regulator",
  ConstructBoundaryFunctionDifferentialSystem[
    ReplacePart[modeMatching, "Regulator" ->
      Symbol["Global`differentBoundarySystemRegulator"]], induced,
    "ValidationMethod" -> "Exact"]["Status"] ===
      "BoundaryFunctionDifferentialSystemInputsInvalid"];

incompatible = Join[induced, <|
  "InducedTangentialConnectionMatrices" -> {{{0, 0}, {0, 1}}}|>];
FTAssert["a tangential connection that violates normal-residue horizontality is refused",
  ConstructBoundaryFunctionDifferentialSystem[modeMatching,
    incompatible, "ValidationMethod" -> "Exact"]["Status"] ===
      "BoundaryFunctionDifferentialSystemValidationFailed"];

badValuations = ReplacePart[modeMatching,
  {"FrobeniusModes", 1, "BoundaryFunctionEpsilonValuation"} -> 2];
FTAssert["declared boundary-function valuations must be preserved by the induced connection",
  ConstructBoundaryFunctionDifferentialSystem[badValuations,
    induced, "ValidationMethod" -> "Exact"]["Status"] ===
      "BoundaryFunctionEpsilonValuationsInconsistent"];

movingModes = Join[modeMatching, <|"FrobeniusModes" -> {
    <|"BoundaryFunctionID" -> "moving1",
      "BoundaryFunctionEpsilonValuation" -> 0,
      "PhysicalToLocalMode" -> {p, 0}|>,
    <|"BoundaryFunctionID" -> "moving2",
      "BoundaryFunctionEpsilonValuation" -> 0,
      "PhysicalToLocalMode" -> {0, 1}|>}|>];
zeroInduced = Join[induced, <|
  "NormalResidueNormalForm" -> ConstantArray[0, {2, 2}],
  "InducedTangentialConnectionMatrices" ->
    {ConstantArray[0, {2, 2}]}|>];
movingSystem = ConstructBoundaryFunctionDifferentialSystem[
  movingModes, zeroInduced, "ValidationMethod" -> "Exact"];
FTAssert["a moving boundary-mode basis contributes with the minus derivative sign",
  BoundaryFunctionDifferentialSystemQ[movingSystem] &&
    movingSystem["BoundaryFunctionConnectionMatrices"][p] ===
      {{-1/p, 0}, {0, 0}}];

dependentModes = ReplacePart[modeMatching, {
  {"FrobeniusModes", 2, "PhysicalToLocalMode"} -> {1, 0},
  {"FrobeniusModes", 2, "BoundaryFunctionEpsilonValuation"} -> 0}];
FTAssert["a supplied connection cannot bypass injectivity of the boundary-mode matrix",
  ConstructBoundaryFunctionDifferentialSystem[dependentModes, zeroInduced,
    "ValidationMethod" -> "Exact",
    "BoundaryFunctionConnectionMatrices" ->
      {ConstantArray[0, {2, 2}]}]["Status"] ===
        "BoundaryFunctionModesLinearlyDependent"];

q = Symbol["Global`boundarySystemQ"];
a = {{0, 1}, {0, 0}};
b = {{0, 0}, {1, 0}};
gammaP = a;
gammaQ = (IdentityMatrix[2] + p a) . b .
  (IdentityMatrix[2] - p a);
twoVariableModes = Join[modeMatching, <|
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {p, q}|>,
  "FrobeniusModes" -> Map[Join[#,
      <|"BoundaryFunctionEpsilonValuation" -> 0|>] &,
    modeMatching["FrobeniusModes"]]|>];
twoVariableInduced = Join[zeroInduced, <|
  "TangentialVariables" -> {p, q},
  "InducedTangentialConnectionMatrices" -> {gammaP, gammaQ}|>];
twoVariableSystem = ConstructBoundaryFunctionDifferentialSystem[
  twoVariableModes, twoVariableInduced, "ValidationMethod" -> "Exact"];
FTAssert["the multivariate flatness convention has the correct noncommuting commutator order",
  BoundaryFunctionDifferentialSystemQ[twoVariableSystem] &&
    gammaP . gammaQ =!= gammaQ . gammaP &&
    twoVariableSystem["BoundaryFunctionConnectionMatrices"][p] === gammaP &&
    twoVariableSystem["BoundaryFunctionConnectionMatrices"][q] === gammaQ];

finiteFieldSystem = ConstructBoundaryFunctionDifferentialSystem[
  modeMatching, induced, "ValidationMethod" -> "FiniteField",
  "BoundaryFunctionConnectionMatrices" -> {gamma}];
FTAssert["the same essential identities can be checked without symbolic common-denominator assembly",
  BoundaryFunctionDifferentialSystemQ[finiteFieldSystem] &&
    finiteFieldSystem["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling" &&
    Length[finiteFieldSystem["Validation", "Evidence",
      "AcceptedPoints"]] === 3];

sparseInduced = Join[induced, <|
  "InverseNormalFrobeniusBasis" -> SparseArray[IdentityMatrix[2]],
  "NormalResidueNormalForm" -> SparseArray[jordan],
  "InducedTangentialConnectionMatrices" -> {SparseArray[gamma]}|>];
sparseFiniteFieldSystem = ConstructBoundaryFunctionDifferentialSystem[
  modeMatching, sparseInduced, "ValidationMethod" -> "FiniteField"];
FTAssert["automatic finite-field validation evaluates sparse residual entries",
  BoundaryFunctionDifferentialSystemQ[sparseFiniteFieldSystem] &&
    sparseFiniteFieldSystem["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling"];

nonLaurentConnection = {{Sqrt[eps], 0}, {0, 0}};
FTAssert["epsilon-coefficient equations refuse a non-Laurent regulator dependence",
  ConstructBoundaryFunctionDifferentialSystem[modeMatching, zeroInduced,
    "ValidationMethod" -> "Exact",
    "BoundaryFunctionConnectionMatrices" -> {nonLaurentConnection}][
      "Status"] ===
    "BoundaryFunctionConnectionNotLaurentRationalInDimensionalRegulator"];

algebraicInduced = Join[induced, <|
  "InducedTangentialConnectionMatrices" ->
    {gamma + Sqrt[1 + p] IdentityMatrix[2]}|>];
FTAssert["the rational finite-field evaluator refuses an undeclared algebraic coefficient domain before sampling",
  ConstructBoundaryFunctionDifferentialSystem[modeMatching,
    algebraicInduced, "ValidationMethod" -> "FiniteField",
    "BoundaryFunctionConnectionMatrices" ->
      {gamma + Sqrt[1 + p] IdentityMatrix[2]}]["Status"] ===
    "BoundaryFunctionFiniteFieldCoefficientDomainUnsupported"];

coefficientEquations =
  ConstructBoundaryFunctionEpsilonCoefficientEquations[system, {0, 1}];
equations = coefficientEquations["Equations"];
FTAssert["epsilon expansion exposes the coupled tangential equations and their actual coefficient orders",
  coefficientEquations["Status"] ===
      "BoundaryFunctionEpsilonCoefficientEquationsConstructed" &&
    Length[equations] === 3 &&
    coefficientEquations[
      "RequiredBoundaryFunctionEpsilonOrders"][[Key[firstID]]] === {0, 1} &&
    coefficientEquations[
      "RequiredBoundaryFunctionEpsilonOrders"][secondID] === {1} &&
    system["BoundaryFunctionEpsilonValuations"][[Key[firstID]]] === 0 &&
    equations[[Key[{p, 1, 1}]]] ===
      (Derivative[1][BoundaryFunctionEpsilonCoefficient[firstID, 1]][p] ==
        BoundaryFunctionEpsilonCoefficient[firstID, 0][p]/p +
          BoundaryFunctionEpsilonCoefficient[secondID, 1][p]/(1 - p))];

representativeEntry[i_, j_] := If[
  i === 3 j || Mod[7 i + 11 j, 10] < 2,
  ((i + 2 j) + (1 + Mod[i + j, 5]) p +
      (1 + Mod[2 i + j, 7]) q + Mod[i j, 3] eps)/
    ((1 + Mod[i, 7] p + Mod[j, 5] q) *
      (2 + Mod[i + j, 11] p + Mod[3 i + j, 7] q + eps)),
  0];
representativeModeMatrix = SparseArray[
  Table[representativeEntry[i, j], {i, 45}, {j, 13}]];
{rowRankSeconds, representativeRowRankCertificate} = AbsoluteTiming[
  TimeConstrained[
    FeynFacet`Private`boundaryFunctionSystemFiniteFieldRowRankCertificate[
      representativeModeMatrix, {p, q}, eps, {2147483647}, 20260904,
      Automatic], 10, $Aborted]];
FTAssert["a representative sparse 45 by 13 rational mode matrix has bounded replayable row-rank evidence",
  AssociationQ[representativeRowRankCertificate] &&
    representativeRowRankCertificate["Status"] ===
      "BoundaryModeMatrixRowRankCertified" &&
    representativeRowRankCertificate["Method"] ===
      "FiniteFieldNonzeroMinor" &&
    representativeRowRankCertificate["MatrixDimensions"] === {45, 13} &&
    Length[representativeRowRankCertificate["RowRankProfile"]] === 13 &&
    FeynFacet`Private`boundaryFunctionSystemRowRankCertificateQ[
      representativeModeMatrix, representativeRowRankCertificate,
      {p, q}, eps]];
Print["BOUNDARY_ROW_RANK_BENCH finite_field_seconds=",
  N[rowRankSeconds, 5], " nonzero_entries=",
  Length[representativeModeMatrix["NonzeroPositions"]]];

FTReport[];
