#!/usr/bin/env wolframscript

(* The point-boundary terminal record keeps the target-dependent Laurent
   functional leftmost and the canonical path coefficient map as a graded
   exact circuit.  It never enumerates the Cartesian product of the current
   and regularized-boundary letter sequences. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

x = Symbol["Global`finishX"];
y = Symbol["Global`finishY"];
eps = Symbol["Global`eps"];
family = "FinishToy";
canonicalConnection = {
  eps {{0, 0}, {1/x, 0}},
  eps {{0, 0}, {1/y, 0}}};
basisTransformation = {{x, 0}, {0, 1}};
inverseBasisTransformation = {{1/x, 0}, {0, 1}};
sourceConnection = {
  {{1/x, 0}, {eps/x^2, 0}},
  {{0, 0}, {eps/(x y), 0}}};
candidate = <|
  "Family" -> family,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}, {2}}, "Blocks" -> {{1}, {2}},
  "TTotal" -> basisTransformation,
  "TTotalInverse" -> inverseBasisTransformation,
  "EpsFormX" -> canonicalConnection[[1]],
  "EpsFormY" -> canonicalConnection[[2]],
  "Letters" -> {x, y}|>;
system = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family, "KinematicVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" ->
    {master[family, {1}], master[family, {2}]},
  "ConnectionMatrices" -> sourceConnection|>;
systemReference = <|
  "RelativePath" -> "finish_toy_system.wl",
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family|>;
form = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  candidate, system, systemReference, "IdentityMethod" -> "Symbolic"];

path = <|
  "FirstVariable" -> x, "SecondVariable" -> y,
  "FirstBase" -> 3, "SecondBase" -> 1/2,
  "FirstPathParameterScale" -> 1|>;
hardFunctionRequest = <|
  "DataType" -> "HardFunctionEpsilonOrderRequest", "SchemaVersion" -> 2,
  "Status" -> "HardFunctionEpsilonOrdersRequested",
  "RequestedHardFunctionEpsilonOrders" -> {0, 1},
  "Reference" -> <|
    "RelativePath" -> "finish_toy_hard_function_orders.wl",
    "DataType" -> "HardFunctionEpsilonOrderRequest",
    "SchemaVersion" -> 2|>|>;
coefficientValuations = <|
  "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
  "SchemaVersion" -> 2,
  "Status" ->
    "HardFunctionMasterCoefficientEpsilonValuationsDetermined",
  "Reference" -> <|
    "RelativePath" -> "finish_toy_coefficient_valuations.wl",
    "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
    "SchemaVersion" -> 2|>,
  "Entries" -> Table[<|
      "MasterIntegralIndex" -> id,
      "MasterIntegral" -> <|
        "Family" -> family, "PropagatorPowers" -> {id}|>,
      "HardFunctionCoefficientEpsilonValuation" -> 0,
      "DeterminationMethod" -> "ExactToyInput"|>, {id, 2}]|>;
requirements = DeriveMasterIntegralEpsilonOrderRequirements[
  hardFunctionRequest, coefficientValuations];
requirementsReference = <|
  "RelativePath" -> "Tests/Fixtures/finish_toy_requirements.wl",
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "MathematicalInputReferences" ->
    requirements["MathematicalInputReferences"]|>;
operator = ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  form, requirements,
  "RegularBasePointAndFirstPathParameterScale" -> path,
  "MasterIntegralEpsilonOrderRequirementsReference" ->
    requirementsReference,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];
If[! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[operator],
  Print["FORM: ", InputForm[form]];
  Print["REQUIREMENTS: ", InputForm[requirements]];
  Print["OPERATOR: ", InputForm[operator]]];

FTAssert["the synthetic family and requested-output operator are exact V2 inputs",
  ExactlyValidatedFamilyDLogEpsilonFormQ[form] &&
    MasterIntegralEpsilonOrderRequirementsQ[requirements] &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[operator] &&
    operator["RequestedMasterIntegralEpsilonOrderAndRowPairs"] ===
      {{0, 1}, {0, 2}, {1, 1}, {1, 2}}];

rho = Symbol["Global`finishRho"];
frobeniusSpec = <|
  "Variable" -> y, "Regulator" -> eps, "LocalVariable" -> rho,
  "LocalExpansionPoint" -> 1, "LocalDirection" -> -1,
  "FixedRules" -> {x -> 2}|>;
frobenius = ComputeTruncatedLocalFrobeniusExpansion[
  canonicalConnection[[2]], frobeniusSpec,
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 3];
realizations = Table[<|
    "BoundaryConstantID" -> {family, id},
    "FrobeniusModeID" -> {family, id},
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id},
    "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> {{0, 1}, {0, 2}, {1, 1}, {1, 2}},
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 0|>, {id, 2}];
modeMap = MatchBoundaryAsymptoticsToFrobeniusModes[
  frobenius, basisTransformation,
  <|"Family" -> family, "Limit" -> "toyEdge",
    "FixedRules" -> {x -> 2},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
      "Coordinates" -> {x -> 2, y -> 1}|>,
    "PhysicalEndpointRelation" -> <|
      "Stratum" -> "toyEdge", "LocalPower" -> 1,
      "LeadingCoefficient" -> 1|>|>, realizations];

FTAssert["the point-boundary mode matching is complete",
  modeMap["DataType"] === "BoundaryAsymptoticModeMatching" &&
    modeMap["SchemaVersion"] === 2 &&
    modeMap["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    modeMap["BoundaryDataType"] === "BoundaryConstant"];

directory = FileNameJoin[{$TemporaryDirectory,
  "finish_toy_" <> ToString[$ProcessID]}];
CreateDirectory[directory];
formPath = FileNameJoin[{directory, "family_epsform.wl"}];
operatorPath = FileNameJoin[{directory, "coefficient_operator.wl"}];
modePath = FileNameJoin[{directory, "boundary_modes.wl"}];
Put[form, formPath];
Put[operator, operatorPath];
Put[modeMap, modePath];
inputFiles = <|
  "FamilyDLogEpsilonForm" -> formPath,
  "IteratedIntegralCoefficientOperatorForRequestedOutputs" -> operatorPath,
  "BoundaryAsymptoticModeMatching" -> modePath|>;

solution = ConstructMasterIntegralSolution[family,
  "InputFiles" -> inputFiles];
If[FailureQ[solution], Print["SOLUTION: ", InputForm[solution]]];
factorization = Lookup[solution, "Factorization", <||>];
targetFactor = Lookup[factorization,
  "TargetBasisTransformationLaurentFunctional", <||>];
canonicalFactor = Lookup[factorization,
  "CanonicalIteratedIntegralCoefficientMap", <||>];
boundaryRecords = Lookup[solution,
  "BoundaryConstantEpsilonCoefficientRecords", {}];
worklist = Lookup[solution,
  "BoundaryConstantEpsilonCoefficientEvaluationWorklist", {}];

FTAssert["the terminal object is one complete V2 solution in terms of boundary constants",
  solution["DataType"] === "MasterIntegralSolution" &&
    solution["SchemaVersion"] === 2 &&
    solution["Status"] === "MasterIntegralSolutionConstructed" &&
    solution["SolutionType"] ===
      "MasterIntegralSolutionInTermsOfBoundaryConstants" &&
    solution["SolutionRepresentation"] ===
      "TargetLaurentFunctionalTimesGradedExactCoefficientCircuit" &&
    solution["FamilyDifferentialSystemReference"] === systemReference &&
    solution["MasterIntegralEpsilonOrderRequirementsReference"] ===
      operator["MasterIntegralEpsilonOrderRequirementsReference"] &&
    solution["DemandCoverage"] === "Complete" &&
    solution["BoundaryDataStatus"] === "Undetermined" &&
    MasterIntegralSolutionQ[solution]];

FTAssert["the target-dependent Laurent functional remains the leftmost factor",
  factorization["ActionOrder"] === {
      "BoundaryConstantEpsilonCoefficientVector",
      "CanonicalIteratedIntegralCoefficientMap",
      "TargetBasisTransformationLaurentFunctional"} &&
    MatrixQ[targetFactor["SparseMatrix"]] &&
    ! FreeQ[Normal[targetFactor["SparseMatrix"]], x] &&
    Normal[targetFactor["SparseMatrix"]] =!=
      (Normal[targetFactor["SparseMatrix"]] /. x -> 3)];

sourceInitial = operator[
  "ExactIteratedIntegralCoefficientOperator",
  "InitialRequestedOutputMap"];
sourcePositions = Most[ArrayRules[SparseArray[sourceInitial]]];
activeAmbientIndices = Sort@DeleteDuplicates@Cases[
  First /@ sourcePositions, {_, column_Integer} :> column];
expectedCanonicalSlots = operator["BoundaryAmbientSlots"][[
  activeAmbientIndices]];
selector = canonicalFactor["ExactCurrentPathCoefficientOperator",
  "InitialRequestedOutputMap"];

FTAssert["selector rows are exactly the symbolic support columns of the target functional",
  targetFactor["CanonicalMasterIntegralEpsilonOrderAndRowPairs"] ===
      expectedCanonicalSlots &&
    Dimensions[selector] === {
      Length[activeAmbientIndices],
      Length[operator["BoundaryAmbientSlots"]]} &&
    Normal[selector] === Normal[SparseArray[
      Table[{row, activeAmbientIndices[[row]]} -> 1,
        {row, Length[activeAmbientIndices]}], Dimensions[selector]]]];

grades = canonicalFactor[
  "RegularizedBoundaryToBasePointCoefficientMapsByIteratedIntegralWeight"];
FTAssert["the canonical factor is a graded exact circuit with explicit boundary coordinates",
  canonicalFactor["Representation"] === "GradedExactCoefficientCircuit" &&
    AssociationQ[grades] && grades =!= <||> &&
    AllTrue[Values[grades],
      MatrixQ[#["CurrentRowBasis"]] &&
        ListQ[#["BoundaryPathIteratedIntegralCoefficientMatrixTerms"]] &] &&
    factorization["BoundaryConstantEpsilonCoefficientVector"] ===
      Lookup[boundaryRecords, "Coefficient"] &&
    Length[boundaryRecords] > 0];

FTAssert["the exact worklist contains only active unevaluated boundary coefficients",
  Length[worklist] === Length[boundaryRecords] &&
    AllTrue[worklist,
      Lookup[#, "SupportingBoundaryPathLetterIndexSequenceRecords", {}] =!=
        {} &] &&
    AllTrue[boundaryRecords,
      Lookup[#, "Status", None] === "Unevaluated" &] &&
    Sort[Lookup[worklist, "BoundaryConstantEpsilonCoefficientIndex"]] ===
      Range[Length[boundaryRecords]]];

FTAssert["no eager sequence product or repeated certificate layer is stored",
  Intersection[Keys[solution], {
      "Expressions", "Terms", "CanonicalExpansions",
      "IteratedIntegralCoefficientMatrixTerms", "Certificates",
      "Timings", "PeakMemoryBytes"}] === {}];

tampered = ReplacePart[solution,
  {"Factorization", "CanonicalIteratedIntegralCoefficientMap",
    "BoundaryConstantEpsilonCoefficientColumnOrder"} ->
      Reverse[solution["BoundaryConstantEpsilonCoefficientLabels"]]];
FTAssert["the stored-size structural predicate rejects a changed factor-interface order",
  ! MasterIntegralSolutionQ[tampered] &&
    ! MasterIntegralSolutionQ[ReplacePart[solution,
      {"MasterIntegralEpsilonOrderRequirementsReference", "SchemaVersion"} ->
        1]] &&
    ! MasterIntegralSolutionQ[
      Join[solution, <|"Status" -> "MasterIntegralSolutionIncomplete"|>]]];

DeleteDirectory[directory, DeleteContents -> True];
FTReport[];
