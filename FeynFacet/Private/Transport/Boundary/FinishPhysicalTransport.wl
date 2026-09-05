(* Terminal V2 master-integral solutions.

   A point-boundary solution is stored as

     L_T(target) . C_canonical(path) . b,

   where L_T is the target-dependent Laurent functional, C_canonical is a
   graded exact coefficient circuit, and b is the ordered vector of boundary-
   constant epsilon coefficients.  A positive-dimensional boundary-stratum
   solution is stored as N . U . b, with the normal/bulk and tangential
   sequence-indexed operators kept as separate sparse factors.  Neither form
   enumerates the Cartesian product of the factors' letter sequences. *)

Clear[ConstructMasterIntegralSolution, MasterIntegralSolutionQ];

ClearAll[finishFailure, finishExactZeroQ,
  finishExactMatrixNonzeroPositions, finishActiveMatrixColumns,
  finishBoundaryDataStatus, finishInputFiles,
  finishFamilyDifferentialSystemReferenceQ,
  finishMasterIntegralEpsilonOrderRequirementsReferenceQ,
  finishBoundaryPointModeMatchingQ, finishKnownZeroBoundaryData,
  finishTargetFunctionalData, finishNormalizeBoundaryPath,
  finishPointBoundaryRequirements, finishPrunePointGrades,
  finishPointBoundaryConstantWorklist, finishPointMasterIntegralSolution,
  finishPointMasterIntegralSolutionQ, finishPointCoefficientCircuitQ,
  finishFactorizedMasterIntegralSolution,
  finishFactorizedMasterIntegralSolutionQ];

finishFailure[status_String, extra_: <||>] :=
  Failure[status, Join[<|"Status" -> status|>, extra]];

finishFamilyDifferentialSystemReferenceQ[reference_, family_String] :=
  AssociationQ[reference] &&
    Lookup[reference, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[reference, "SchemaVersion", None] === 2 &&
    Lookup[reference, "Family", None] === family &&
    StringQ[Lookup[reference, "RelativePath", None]] &&
    StringLength[reference["RelativePath"]] > 0;
finishFamilyDifferentialSystemReferenceQ[___] := False;

finishMasterIntegralEpsilonOrderRequirementsReferenceQ[reference_] :=
  AssociationQ[reference] &&
    Lookup[reference, "DataType", None] ===
      "MasterIntegralEpsilonOrderRequirements" &&
    Lookup[reference, "SchemaVersion", None] === 2 &&
    StringQ[Lookup[reference, "RelativePath", None]] &&
    StringLength[reference["RelativePath"]] > 0 &&
    AssociationQ[Lookup[reference, "MathematicalInputReferences", None]];

finishExactZeroQ[value_] :=
  TrueQ[value === 0] || Quiet[TrueQ[PossibleZeroQ[value]]];

finishExactMatrixNonzeroPositions[matrix_?MatrixQ] :=
  First /@ Select[Most[ArrayRules[SparseArray[matrix]]],
    ! finishExactZeroQ[Last[#]] &];
finishExactMatrixNonzeroPositions[_] := {};

finishActiveMatrixColumns[matrix_?MatrixQ] :=
  Sort@DeleteDuplicates@Cases[
    finishExactMatrixNonzeroPositions[matrix], {_, column_} :> column];
finishActiveMatrixColumns[_] := {};

finishBoundaryDataStatus[coordinates_List] := Module[{statuses},
  statuses = Lookup[coordinates, "Status", "Unevaluated"];
  Which[
    coordinates === {}, "Determined",
    AllTrue[statuses, MemberQ[{"KnownZero", "Exact"}, #] &], "Determined",
    AnyTrue[statuses, MemberQ[{"KnownZero", "Exact"}, #] &], "Partial",
    True, "Undetermined"]
];

Options[ConstructMasterIntegralSolution] = {
  "InputFiles" -> Automatic,
  "MaximumConnectorWords" -> 500000,
  "OutputDirectory" -> None,
  "Verbose" -> False
};

finishInputFiles[inputFiles_] := Module[
  {required, missing, files, values},
  required = {"FamilyDLogEpsilonForm",
    "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    "BoundaryAsymptoticModeMatching"};
  If[! AssociationQ[inputFiles],
    Return[finishFailure["MasterIntegralSolutionInputFilesRequired", <|
      "RequiredKeys" -> required|>]]];
  missing = Complement[required, Keys[inputFiles]];
  If[missing =!= {},
    Return[finishFailure["MasterIntegralSolutionInputFilesMissing", <|
      "MissingKeys" -> missing|>]]];
  files = KeyTake[inputFiles, required];
  If[! AllTrue[Values[files], StringQ[#] && FileExistsQ[#] &],
    Return[finishFailure["MasterIntegralSolutionInputFileMissing", <|
      "InputFiles" -> files|>]]];
  values = Map[FamilyArtifactRead, files];
  If[! AllTrue[Values[values], AssociationQ],
    Return[finishFailure["MasterIntegralSolutionInputsUnreadable", <|
      "InputFiles" -> files|>]]];
  <|"InputFiles" -> files, "Values" -> values|>
];

finishBoundaryPointModeMatchingQ[record_] :=
  AssociationQ[record] &&
    Lookup[record, "DataType", None] ===
      "BoundaryAsymptoticModeMatching" &&
    Lookup[record, "SchemaVersion", None] === 2 &&
    Lookup[record, "Status", None] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    StringQ[Lookup[record, "Family", Missing[]]] &&
    Lookup[record, "BoundaryDataType", None] === "BoundaryConstant" &&
    AssociationQ[Lookup[record, "BoundaryDomain", Missing[]]] &&
    Lookup[record["BoundaryDomain"], "Type", None] ===
      "PhysicalBoundaryPoint" &&
    MatchQ[Lookup[record, "Regulator", Missing[]], _Symbol] &&
    ListQ[Lookup[record, "FrobeniusModes", Missing[]]] &&
    Lookup[record, "FrobeniusModes", {}] =!= {};

finishKnownZeroBoundaryData[modeMap_Association] := Module[{pairs},
  pairs = Map[Function[mode, With[
      {id = Lookup[mode, "BoundaryConstantID",
          Lookup[mode, "FrobeniusModeID", Missing[]]]},
      If[MissingQ[id] ||
          ! finishExactZeroQ[Lookup[mode, "KnownCoefficient", Missing[]]],
        Nothing,
        id -> <|"BoundaryDataType" -> "BoundaryConstant",
          "BoundaryConstantID" -> id, "Status" -> "KnownZero"|>]]],
    modeMap["FrobeniusModes"]];
  Association[pairs]
];

finishTargetFunctionalData[operator_Association] := Module[
  {automaton, demanded, nonzeroDemanded, ambientSlots, initial,
   nonzeroRows, rules, full, activeColumns, canonicalSlots, functional,
   selectors},
  automaton = Lookup[operator,
    "ExactIteratedIntegralCoefficientOperator", Missing[]];
  demanded = Lookup[operator,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs", Missing[]];
  nonzeroDemanded = Lookup[operator,
    "NonzeroRequestedMasterIntegralEpsilonOrderAndRowPairs", Missing[]];
  ambientSlots = Lookup[operator, "BoundaryAmbientSlots", Missing[]];
  initial = Lookup[automaton, "InitialRequestedOutputMap", Missing[]];
  If[! AssociationQ[automaton] ||
      ! MatchQ[demanded, {{_Integer, _Integer} ...}] ||
      ! MatchQ[nonzeroDemanded, {{_Integer, _Integer} ...}] ||
      ! DuplicateFreeQ[demanded] || ! DuplicateFreeQ[nonzeroDemanded] ||
      ! ContainsAll[demanded, nonzeroDemanded] || ! ListQ[ambientSlots] ||
      ! MatrixQ[initial] ||
      Dimensions[initial] =!= {Length[nonzeroDemanded],
        Length[ambientSlots]},
    Return[finishFailure[
      "MasterIntegralSolutionTargetFunctionalNotWellFormed"]]];
  nonzeroRows = (FirstPosition[demanded, #, Missing[]] & /@
    nonzeroDemanded);
  If[MemberQ[nonzeroRows, _Missing],
    Return[finishFailure[
      "MasterIntegralSolutionRequestedOutputLabelsMismatch"]]];
  nonzeroRows = First /@ nonzeroRows;
  rules = Cases[Most[ArrayRules[SparseArray[initial]]],
    HoldPattern[{row_Integer, column_Integer} -> value_] :>
      ({nonzeroRows[[row]], column} -> value)];
  full = SparseArray[rules, {Length[demanded], Length[ambientSlots]}];
  activeColumns = Sort@DeleteDuplicates@Cases[
    finishExactMatrixNonzeroPositions[full], {_, column_} :> column];
  canonicalSlots = If[activeColumns === {}, {},
    ambientSlots[[activeColumns]]];
  functional = If[activeColumns === {},
    SparseArray[{}, {Length[demanded], 0}],
    SparseArray[full[[All, activeColumns]]]];
  selectors = SparseArray[
    Table[{row, activeColumns[[row]]} -> 1,
      {row, Length[activeColumns]}],
    {Length[activeColumns], Length[ambientSlots]}];
  <|
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> demanded,
    "NonzeroRequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      nonzeroDemanded,
    "CanonicalMasterIntegralEpsilonOrderAndRowPairs" -> canonicalSlots,
    "ActiveBoundaryAmbientSlotIndices" -> activeColumns,
    "TargetBasisTransformationLaurentFunctional" -> functional,
    "InitialRequestedOutputRowSelectorMatrix" -> selectors|>
];

finishNormalizeBoundaryPath[path_Association] := Module[{segments},
  segments = Map[Function[segment, Join[KeyDrop[segment, "Role"], <|
      "Role" -> Switch[Lookup[segment, "Role", None],
        "EndpointFirst", "BoundaryPathFirstSegment",
        "EndpointSecond", "BoundaryPathSecondSegment",
        other_, other]|>]], Lookup[path, "Segments", {}]];
  <|
    "BoundaryPoint" -> Lookup[path, "Endpoint", Missing[]],
    "InteriorBasePoint" -> Lookup[path, "InteriorBase", Missing[]],
    "Segments" -> segments,
    "MultiplicationOrder" ->
      Lookup[path, "MultiplicationOrder", Missing[]],
    "BoundaryPrescription" ->
      Lookup[path, "BoundaryPrescription", Missing[]],
    "LocalCoordinateNormalization" ->
      Lookup[path, "LocalCoordinateNormalization", Missing[]]|>
];

finishPointBoundaryRequirements[modeMap_Association, records_List,
    demands_List] := Map[Function[group, Module[{first, id, mode},
    first = First[group];
    id = first["BoundaryConstantID"];
    mode = SelectFirst[modeMap["FrobeniusModes"],
      Lookup[#, "BoundaryConstantID",
        Lookup[#, "FrobeniusModeID", Missing[]]] === id &, <||>];
    <|
      "BoundaryDataType" -> "BoundaryConstant",
      "BoundaryConstantID" -> id,
      "FrobeniusModeID" -> Lookup[first, "FrobeniusModeID",
        Lookup[mode, "FrobeniusModeID", Missing[]]],
      "DeclaredBoundaryConstantAnalyticClass" -> Lookup[mode,
        "DeclaredBoundaryConstantAnalyticClass", Missing[]],
      "Family" -> modeMap["Family"],
      "BoundaryDomain" -> modeMap["BoundaryDomain"],
      "PhysicalKinematicLimit" ->
        Lookup[modeMap, "PhysicalKinematicLimit", Missing[]],
      "LocalExpansionSpecification" ->
        Lookup[modeMap, "LocalExpansionSpecification", Missing[]],
      "BoundaryConstantEpsilonCoefficientLabels" ->
        ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@ group,
      "RequiredMasterIntegralEpsilonOrderAndRowPairs" -> demands,
      "DegenerateResidueEigenspaceBasis" ->
        Lookup[first, "DegenerateResidueEigenspaceBasis", None],
      "Status" -> "Unevaluated"|>
  ]], GatherBy[records, #["BoundaryConstantID"] &]];

finishPrunePointGrades[grades_Association, columns_List] :=
  Map[Function[grade, Module[{terms},
    terms = If[columns === {}, {}, Map[Function[term, With[
        {matrix = SparseArray[
            term["IteratedIntegralCoefficientMatrix"][[All, columns]]]},
        If[finishExactMatrixNonzeroPositions[matrix] === {}, Nothing,
          Join[KeyDrop[term, "IteratedIntegralCoefficientMatrix"], <|
            "IteratedIntegralCoefficientMatrix" -> matrix|>]]]],
      Lookup[grade,
        "BoundaryPathIteratedIntegralCoefficientMatrixTerms", {}]]];
    Join[KeyDrop[grade, {
        "CurrentWeight", "BoundaryDataRequirements", "EndpointPath",
        "RetainedBoundaryPathCoefficientMatrixTermCount",
        "VisitedConnectorStateCount", "PrunedConnectorChildCount"}], <|
      "BoundaryPathIteratedIntegralCoefficientMatrixTerms" -> terms|>]
  ]], grades];

finishPointBoundaryConstantWorklist[grades_Association,
    records_List] := MapIndexed[Function[{record, position}, Module[
    {column = First[position], supporting},
    supporting = Flatten@Reap[
        KeyValueMap[Function[{weight, grade},
          Do[If[MemberQ[finishActiveMatrixColumns[
                term["IteratedIntegralCoefficientMatrix"]], column],
              Sow[<|
                "CanonicalIteratedIntegralWeight" -> weight,
                "BoundaryPathFirstSegmentLetterIndices" -> Lookup[term,
                  "BoundaryPathFirstSegmentLetterIndices", {}],
                "BoundaryPathSecondSegmentLetterIndices" -> Lookup[term,
                  "BoundaryPathSecondSegmentLetterIndices", {}]|>]],
            {term, Lookup[grade,
              "BoundaryPathIteratedIntegralCoefficientMatrixTerms", {}]}]],
          grades]][[2]];
    supporting = DeleteDuplicates[supporting];
    If[Lookup[record, "Status", "Unevaluated"] =!= "Unevaluated",
      Nothing,
      <|
        "BoundaryConstantEpsilonCoefficientIndex" -> column,
        "BoundaryConstantID" -> record["BoundaryConstantID"],
        "EpsilonOrder" -> record["EpsilonOrder"],
        "Coefficient" -> record["Coefficient"],
        "SupportingBoundaryPathLetterIndexSequenceRecords" -> supporting|>]
  ]], records];

finishPointMasterIntegralSolution[family_String, inputs_Association,
    maximumConnectorWords_Integer] := Catch@Module[
  {fail, form, operator, modeMap, variables, regulator, targetData,
   selectorMatrix, binding, knownZeroData, grades, terms, usedColumns,
   records, requirements, worklist, boundaryPath, canonicalOperator,
   familySystemReference, requirementsReference, inputReferences,
   factorization, result},
  fail[status_, extra_: <||>] := Throw[finishFailure[status, extra]];
  form = inputs["FamilyDLogEpsilonForm"];
  operator = inputs[
    "IteratedIntegralCoefficientOperatorForRequestedOutputs"];
  modeMap = inputs["BoundaryAsymptoticModeMatching"];
  If[! ValidatedFamilyDLogEpsilonFormQ[form],
    fail["ValidatedFamilyDLogEpsilonFormRequired"]];
  If[! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[operator],
    fail[
      "IteratedIntegralCoefficientOperatorForRequestedOutputsRequired"]];
  If[Lookup[operator, "IteratedIntegralCoefficientRepresentation", None] =!=
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    fail["ExactIteratedIntegralCoefficientOperatorRequired"]];
  If[! finishBoundaryPointModeMatchingQ[modeMap],
    fail["ValidatedBoundaryPointModeMatchingRequired"]];
  If[! AllTrue[{form, operator, modeMap},
      Lookup[#, "Family", Missing[]] === family &],
    fail["MasterIntegralSolutionFamilyMismatch"]];
  familySystemReference = Lookup[
    Lookup[form, "BlockDecomposition", <||>],
    "FamilyDifferentialSystemReference", Missing[]];
  requirementsReference = Lookup[operator,
    "MasterIntegralEpsilonOrderRequirementsReference", Missing[]];
  If[! finishFamilyDifferentialSystemReferenceQ[
      familySystemReference, family],
    fail["FamilyDifferentialSystemReferenceRequired"]];
  If[Lookup[operator, "FamilyDifferentialSystemReference", Missing[]] =!=
      familySystemReference,
    fail["FamilyDifferentialSystemReferenceMismatch"]];
  If[! finishMasterIntegralEpsilonOrderRequirementsReferenceQ[
      requirementsReference],
    fail["MasterIntegralEpsilonOrderRequirementsReferenceRequired"]];
  inputReferences = <|
    "FamilyDifferentialSystemReference" -> familySystemReference,
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      requirementsReference|>;
  variables = operator["CoefficientVariables"];
  regulator = operator["DimensionalRegulator"];
  If[Lookup[form, "CoefficientVariables", Missing[]] =!= variables ||
      Lookup[form, "DimensionalRegulator", Missing[]] =!= regulator ||
      Lookup[modeMap, "Regulator", Missing[]] =!= regulator,
    fail["MasterIntegralSolutionVariableOrRegulatorMismatch"]];

  targetData = finishTargetFunctionalData[operator];
  If[FailureQ[targetData], Throw[targetData]];
  selectorMatrix = targetData[
    "InitialRequestedOutputRowSelectorMatrix"];
  knownZeroData = finishKnownZeroBoundaryData[modeMap];
  binding = If[Last[Dimensions[selectorMatrix]] === 0 ||
      First[Dimensions[selectorMatrix]] === 0,
    <|"Status" -> "GradedPhysicalEndpointTransportBuilt",
      "BoundaryConstantEpsilonCoefficientRecords" -> {},
      "BoundaryDataRequirements" -> {}, "GradesByWeight" -> <||>,
      "EndpointPath" -> <||>|>,
    FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
      operator, modeMap, knownZeroData,
      "MaximumConnectorWords" -> maximumConnectorWords,
      "BoundaryDataEpsilonOrderWindow" -> Automatic,
      "InitialRequestedOutputRowSelectorMatrix" -> selectorMatrix]];
  If[FailureQ[binding] || Lookup[binding, "Status", None] =!=
      "GradedPhysicalEndpointTransportBuilt",
    fail["CanonicalBoundaryCoefficientCircuitConstructionFailed", <|
      "Result" -> binding|>]];
  grades = Lookup[binding, "GradesByWeight", <||>];
  records = Lookup[binding,
    "BoundaryConstantEpsilonCoefficientRecords", {}];
  If[! AssociationQ[grades] || ! ListQ[records] ||
      ! AllTrue[records, AssociationQ],
    fail["CanonicalBoundaryCoefficientCircuitNotWellFormed"]];
  terms = Flatten[Lookup[Values[grades],
    "BoundaryPathIteratedIntegralCoefficientMatrixTerms", {}]];
  usedColumns = Sort@DeleteDuplicates@Flatten[
    finishActiveMatrixColumns /@
      Lookup[terms, "IteratedIntegralCoefficientMatrix", {}]];
  usedColumns = Select[usedColumns, 1 <= # <= Length[records] &];
  records = If[usedColumns === {}, {}, records[[usedColumns]]];
  grades = finishPrunePointGrades[grades, usedColumns];
  requirements = finishPointBoundaryRequirements[modeMap,
    Select[records, Lookup[#, "Status", "Unevaluated"] ===
        "Unevaluated" &],
    targetData["RequestedMasterIntegralEpsilonOrderAndRowPairs"]];
  worklist = finishPointBoundaryConstantWorklist[grades, records];
  boundaryPath = finishNormalizeBoundaryPath[
    Lookup[binding, "EndpointPath", <||>]];
  canonicalOperator = Join[
    operator["ExactIteratedIntegralCoefficientOperator"], <|
      "InitialRequestedOutputMap" -> selectorMatrix|>];
  factorization = <|
    "ProductConvention" ->
      "TargetBasisTransformationLaurentFunctional.CanonicalIteratedIntegralCoefficientMap.BoundaryConstantEpsilonCoefficientVector",
    "ActionOrder" -> {
      "BoundaryConstantEpsilonCoefficientVector",
      "CanonicalIteratedIntegralCoefficientMap",
      "TargetBasisTransformationLaurentFunctional"},
    "MathematicalInputReferences" -> inputReferences,
    "TargetBasisTransformationLaurentFunctional" -> <|
      "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
        targetData[
          "RequestedMasterIntegralEpsilonOrderAndRowPairs"],
      "CanonicalMasterIntegralEpsilonOrderAndRowPairs" ->
        targetData[
          "CanonicalMasterIntegralEpsilonOrderAndRowPairs"],
      "BoundaryAmbientSlotIndices" ->
        targetData["ActiveBoundaryAmbientSlotIndices"],
      "SparseMatrix" -> targetData[
        "TargetBasisTransformationLaurentFunctional"]|>,
    "CanonicalIteratedIntegralCoefficientMap" -> <|
      "Representation" -> "GradedExactCoefficientCircuit",
      "CanonicalMasterIntegralEpsilonOrderAndRowPairs" ->
        targetData[
          "CanonicalMasterIntegralEpsilonOrderAndRowPairs"],
      "ExactCurrentPathCoefficientOperator" -> canonicalOperator,
      "CurrentPath" -> <|
        "CoefficientVariables" -> variables,
        "RegularBasePointAndFirstPathParameterScale" -> operator[
          "RegularBasePointAndFirstPathParameterScale"],
        "FirstPathSegmentIteratedIntegralKernels" -> Lookup[operator,
          "FirstPathSegmentIteratedIntegralKernels", {}],
        "SecondPathSegmentIteratedIntegralKernels" -> Lookup[operator,
          "SecondPathSegmentIteratedIntegralKernels", {}]|>,
      "RegularizedBoundaryPath" -> boundaryPath,
      "RegularizedBoundaryToBasePointCoefficientMapsByIteratedIntegralWeight" ->
        grades,
      "BoundaryConstantEpsilonCoefficientColumnOrder" ->
        ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@ records|>,
    "BoundaryConstantEpsilonCoefficientVector" ->
      Lookup[records, "Coefficient", {}]|>;
  result = <|
    "DataType" -> "MasterIntegralSolution", "SchemaVersion" -> 2,
    "Status" -> "MasterIntegralSolutionConstructed",
    "SolutionType" ->
      "MasterIntegralSolutionInTermsOfBoundaryConstants",
    "SolutionRepresentation" ->
      "TargetLaurentFunctionalTimesGradedExactCoefficientCircuit",
    "Family" -> family, "CoefficientVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "FamilyDifferentialSystemReference" -> familySystemReference,
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      requirementsReference,
    "BoundaryDomain" -> modeMap["BoundaryDomain"],
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      targetData["RequestedMasterIntegralEpsilonOrderAndRowPairs"],
    "DemandCoverage" -> "Complete",
    "BoundaryDataStatus" -> finishBoundaryDataStatus[records],
    "Factorization" -> factorization,
    "BoundaryConstantEpsilonCoefficientRecords" -> records,
    "BoundaryConstantEpsilonCoefficientLabels" ->
      ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@ records,
    "BoundaryDataRequirements" -> requirements,
    "BoundaryConstantEpsilonCoefficientEvaluationWorklist" -> worklist,
    "BoundaryConstantRelations" ->
      Lookup[modeMap, "BoundaryRelations", {}]|>;
  If[! finishPointCoefficientCircuitQ[result],
    fail["MasterIntegralSolutionFactorInterfaceInvalid"]];
  result
];

finishPointCoefficientCircuitQ[record_Association] := Module[
  {factorization, target, canonical, core, currentPath, grades, records,
   labels, vector, demands, canonicalSlots, ambientIndices, functional,
   inputReferences, familySystemReference, requirementsReference,
   selector, maximumWeight, firstAlphabet, firstMatrices, firstBoundary,
   secondAlphabet, secondMatrices, finalEmbedding, firstDimension,
   secondDimension, boundaryDimension, gradeQ, activeColumns, worklist,
   expectedWorklist, requirements, unknownLabels, requirementLabels,
   expectedSelector, gradeTerms},
  factorization = Lookup[record, "Factorization", Missing[]];
  If[! AssociationQ[factorization] ||
      Lookup[factorization, "ProductConvention", None] =!=
        "TargetBasisTransformationLaurentFunctional.CanonicalIteratedIntegralCoefficientMap.BoundaryConstantEpsilonCoefficientVector" ||
      Lookup[factorization, "ActionOrder", None] =!= {
        "BoundaryConstantEpsilonCoefficientVector",
        "CanonicalIteratedIntegralCoefficientMap",
        "TargetBasisTransformationLaurentFunctional"}, Return[False]];
  familySystemReference = Lookup[record,
    "FamilyDifferentialSystemReference", Missing[]];
  requirementsReference = Lookup[record,
    "MasterIntegralEpsilonOrderRequirementsReference", Missing[]];
  inputReferences = Lookup[factorization,
    "MathematicalInputReferences", Missing[]];
  If[! finishFamilyDifferentialSystemReferenceQ[familySystemReference,
        Lookup[record, "Family", ""]] ||
      ! finishMasterIntegralEpsilonOrderRequirementsReferenceQ[
        requirementsReference] ||
      inputReferences =!= <|
        "FamilyDifferentialSystemReference" -> familySystemReference,
        "MasterIntegralEpsilonOrderRequirementsReference" ->
          requirementsReference|>, Return[False]];
  target = Lookup[factorization,
    "TargetBasisTransformationLaurentFunctional", Missing[]];
  canonical = Lookup[factorization,
    "CanonicalIteratedIntegralCoefficientMap", Missing[]];
  records = Lookup[record,
    "BoundaryConstantEpsilonCoefficientRecords", Missing[]];
  labels = Lookup[record,
    "BoundaryConstantEpsilonCoefficientLabels", Missing[]];
  vector = Lookup[factorization,
    "BoundaryConstantEpsilonCoefficientVector", Missing[]];
  demands = Lookup[record,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs", Missing[]];
  If[! AssociationQ[target] || ! AssociationQ[canonical] ||
      ! ListQ[records] || ! AllTrue[records, AssociationQ] ||
      ! MatchQ[demands, {{_Integer, _Integer} ...}] ||
      ! DuplicateFreeQ[demands] ||
      Lookup[target,
        "RequestedMasterIntegralEpsilonOrderAndRowPairs", Missing[]] =!=
        demands, Return[False]];
  canonicalSlots = Lookup[target,
    "CanonicalMasterIntegralEpsilonOrderAndRowPairs", Missing[]];
  ambientIndices = Lookup[target,
    "BoundaryAmbientSlotIndices", Missing[]];
  functional = Lookup[target, "SparseMatrix", Missing[]];
  If[! MatchQ[canonicalSlots, {{_Integer, _Integer} ...}] ||
      ! DuplicateFreeQ[canonicalSlots] ||
      ! VectorQ[ambientIndices, IntegerQ[#] && # > 0 &] ||
      ! DuplicateFreeQ[ambientIndices] ||
      Length[ambientIndices] =!= Length[canonicalSlots] ||
      ! MatrixQ[functional] ||
      Dimensions[functional] =!= {Length[demands],
        Length[canonicalSlots]} || FreeQ[functional, _Real] =!= True ||
      finishActiveMatrixColumns[functional] =!=
        Range[Length[canonicalSlots]] ||
      Lookup[canonical,
        "CanonicalMasterIntegralEpsilonOrderAndRowPairs", Missing[]] =!=
        canonicalSlots ||
      Lookup[canonical, "Representation", None] =!=
        "GradedExactCoefficientCircuit", Return[False]];

  core = Lookup[canonical,
    "ExactCurrentPathCoefficientOperator", Missing[]];
  currentPath = Lookup[canonical, "CurrentPath", Missing[]];
  grades = Lookup[canonical,
    "RegularizedBoundaryToBasePointCoefficientMapsByIteratedIntegralWeight",
    Missing[]];
  If[! AssociationQ[core] || ! AssociationQ[currentPath] ||
      ! AssociationQ[grades] ||
      ! AssociationQ[Lookup[canonical,
        "RegularizedBoundaryPath", Missing[]]], Return[False]];
  maximumWeight = Lookup[core,
    "MaximumIteratedIntegralWeight", Missing[]];
  selector = Lookup[core, "InitialRequestedOutputMap", Missing[]];
  firstAlphabet = Lookup[core,
    "FirstPathSegmentAlphabetLetterIndices", Missing[]];
  firstMatrices = Lookup[core,
    "FirstPathSegmentOperatorMatrices", Missing[]];
  firstBoundary = Lookup[core,
    "FirstPathSegmentBoundaryMap", Missing[]];
  secondAlphabet = Lookup[core,
    "SecondPathSegmentAlphabetLetterIndices", Missing[]];
  secondMatrices = Lookup[core,
    "SecondPathSegmentOperatorMatrices", Missing[]];
  finalEmbedding = Lookup[core, "FinalBoundaryEmbedding", Missing[]];
  If[Lookup[core, "Status", None] =!=
        "IteratedIntegralCoefficientOperatorConstructed" ||
      ! IntegerQ[maximumWeight] || maximumWeight < 0 ||
      ! MatrixQ[selector] || ! MatrixQ[firstBoundary] ||
      ! MatrixQ[finalEmbedding] ||
      ! VectorQ[firstAlphabet, IntegerQ[#] && # > 0 &] ||
      ! VectorQ[secondAlphabet, IntegerQ[#] && # > 0 &] ||
      ! DuplicateFreeQ[firstAlphabet] || ! DuplicateFreeQ[secondAlphabet] ||
      ! ListQ[firstMatrices] || ! AllTrue[firstMatrices, MatrixQ] ||
      ! ListQ[secondMatrices] || ! AllTrue[secondMatrices, MatrixQ] ||
      Length[firstAlphabet] =!= Length[firstMatrices] ||
      Length[secondAlphabet] =!= Length[secondMatrices], Return[False]];
  firstDimension = Last[Dimensions[selector]];
  secondDimension = Last[Dimensions[firstBoundary]];
  boundaryDimension = Last[Dimensions[finalEmbedding]];
  expectedSelector = SparseArray[
    Table[{row, ambientIndices[[row]]} -> 1,
      {row, Length[ambientIndices]}],
    {Length[ambientIndices], firstDimension}];
  If[Dimensions[selector] =!= {Length[canonicalSlots], firstDimension} ||
      Max[Append[ambientIndices, 0]] > firstDimension ||
      Normal[selector] =!= Normal[expectedSelector] ||
      First[Dimensions[firstBoundary]] =!= firstDimension ||
      First[Dimensions[finalEmbedding]] =!= secondDimension ||
      ! AllTrue[firstMatrices,
        Dimensions[#] === {firstDimension, firstDimension} &] ||
      ! AllTrue[secondMatrices,
        Dimensions[#] === {secondDimension, secondDimension} &] ||
      Length[Lookup[currentPath,
          "FirstPathSegmentIteratedIntegralKernels", {}]] =!=
        Length[firstAlphabet] ||
      Length[Lookup[currentPath,
          "SecondPathSegmentIteratedIntegralKernels", {}]] =!=
        Length[secondAlphabet], Return[False]];

  gradeQ[weight_, grade_] := Module[
    {basis, rank, columns, inverse, terms},
    If[! IntegerQ[weight] || weight < 0 || weight > maximumWeight ||
        ! AssociationQ[grade], Return[False]];
    basis = Lookup[grade, "CurrentRowBasis", Missing[]];
    columns = Lookup[grade, "ProjectionColumns", Missing[]];
    inverse = Lookup[grade, "ProjectionInverse", Missing[]];
    terms = Lookup[grade,
      "BoundaryPathIteratedIntegralCoefficientMatrixTerms", Missing[]];
    If[! MatrixQ[basis] || Last[Dimensions[basis]] =!= boundaryDimension ||
        ! VectorQ[columns, IntegerQ[#] && # > 0 &] ||
        ! DuplicateFreeQ[columns] ||
        Max[Append[columns, 0]] > boundaryDimension ||
        ! MatrixQ[inverse] || ! ListQ[terms] ||
        ! AllTrue[terms, AssociationQ], Return[False]];
    rank = First[Dimensions[basis]];
    If[Length[columns] =!= rank ||
        Dimensions[inverse] =!= {rank, rank} ||
        ! AllTrue[Flatten[Normal[
            basis[[All, columns]] . inverse - IdentityMatrix[rank]]],
          finishExactZeroQ], Return[False]];
    AllTrue[terms, Function[term,
      ListQ[Lookup[term,
        "BoundaryPathFirstSegmentLetterIndices", Missing[]]] &&
      ListQ[Lookup[term,
        "BoundaryPathSecondSegmentLetterIndices", Missing[]]] &&
      MatrixQ[Lookup[term,
        "IteratedIntegralCoefficientMatrix", Missing[]]] &&
      Dimensions[term["IteratedIntegralCoefficientMatrix"]] ===
        {rank, Length[records]} &&
      FreeQ[term["IteratedIntegralCoefficientMatrix"], _Real]]]
  ];
  If[! AllTrue[Normal[grades], gradeQ[First[#], Last[#]] &],
    Return[False]];

  If[labels =!= ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@
        records || ! DuplicateFreeQ[labels] ||
      vector =!= Lookup[records, "Coefficient", {}] ||
      Lookup[canonical,
        "BoundaryConstantEpsilonCoefficientColumnOrder", Missing[]] =!=
        labels ||
      ! AllTrue[records,
        KeyExistsQ[#, "BoundaryConstantID"] &&
          IntegerQ[Lookup[#, "EpsilonOrder", None]] &&
          KeyExistsQ[#, "Coefficient"] &], Return[False]];
  gradeTerms = Flatten[Lookup[Values[grades],
    "BoundaryPathIteratedIntegralCoefficientMatrixTerms", {}], 1];
  activeColumns = Sort@DeleteDuplicates@Flatten[
    finishActiveMatrixColumns /@
      Lookup[gradeTerms, "IteratedIntegralCoefficientMatrix", {}]];
  If[activeColumns =!= Range[Length[records]] ||
      finishBoundaryDataStatus[records] =!=
        Lookup[record, "BoundaryDataStatus", None], Return[False]];
  worklist = Lookup[record,
    "BoundaryConstantEpsilonCoefficientEvaluationWorklist", Missing[]];
  expectedWorklist = finishPointBoundaryConstantWorklist[grades, records];
  If[worklist =!= expectedWorklist, Return[False]];
  requirements = Lookup[record, "BoundaryDataRequirements", Missing[]];
  If[! ListQ[requirements], Return[False]];
  unknownLabels = ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@
    Select[records,
      Lookup[#, "Status", "Unevaluated"] === "Unevaluated" &];
  requirementLabels = DeleteDuplicates@Flatten[
    Lookup[requirements,
      "BoundaryConstantEpsilonCoefficientLabels", {}], 1];
  ContainsAll[unknownLabels, requirementLabels] &&
    ContainsAll[requirementLabels, unknownLabels]
];
finishPointCoefficientCircuitQ[_] := False;

finishPointMasterIntegralSolutionQ[record_Association] := Module[{},
  If[Lookup[record, "DataType", None] =!= "MasterIntegralSolution" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "MasterIntegralSolutionConstructed" ||
      Lookup[record, "SolutionType", None] =!=
        "MasterIntegralSolutionInTermsOfBoundaryConstants" ||
      Lookup[record, "SolutionRepresentation", None] =!=
        "TargetLaurentFunctionalTimesGradedExactCoefficientCircuit" ||
      Lookup[record, "DemandCoverage", None] =!= "Complete" ||
      ! MemberQ[{"Undetermined", "Partial", "Determined"},
        Lookup[record, "BoundaryDataStatus", None]] ||
      AnyTrue[{"Expressions", "Terms", "CanonicalExpansions",
          "IteratedIntegralCoefficientMatrixTerms"},
        KeyExistsQ[record, #] &], Return[False]];
  StringQ[Lookup[record, "Family", Missing[]]] &&
    MatchQ[Lookup[record, "CoefficientVariables", Missing[]],
      {_Symbol, _Symbol}] &&
    MatchQ[Lookup[record, "DimensionalRegulator", Missing[]], _Symbol] &&
    AssociationQ[Lookup[record, "BoundaryDomain", Missing[]]] &&
    Lookup[record["BoundaryDomain"], "Type", None] ===
      "PhysicalBoundaryPoint" &&
    finishPointCoefficientCircuitQ[record]
];
finishPointMasterIntegralSolutionQ[_] := False;

(* Positive-dimensional boundary strata. *)
finishFactorizedMasterIntegralSolution[boundaryMap_Association,
    evolution_Association] := Catch@Module[
  {fail, family, ids, idRecords, baseConstantIDs, valuations, functionIndex,
   inputCoordinates, inputLabels, coefficientMaps, evolutionWindow,
   familySystemReference, requirementsReference,
   evolutionValuation, minimumBoundaryValuation, requiredHigh,
   requiredWindow, coordinatePieces, outputCoordinates, outputIndex,
   outputCount, rightRecords, leftRecords, leftPositions, rightPositions,
   leftActiveColumnsByRecord, rightActiveRowsByRecord, activeLeftColumns,
   requiredOutputIndices, activeInterfaceIndices, dependencies,
   leftRecordIndices, rightRecordIndices, constantIndices,
   pathKeys, requiredPathSequences, requiredTangentialSequences,
   unevaluatedConstantIndices, requirements, outputWindow,
   boundaryDataStatus, product},
  fail[status_, extra_: <||>] := Throw[finishFailure[status, extra]];
  If[! boundaryFunctionToMasterIntegralSolutionMapQ[boundaryMap],
    fail["ValidatedBoundaryFunctionToMasterIntegralSolutionMapRequired"]];
  If[! TangentialBoundaryEvolutionOperatorQ[evolution],
    fail["TangentialBoundaryEvolutionOperatorRequired"]];
  family = boundaryMap["Family"];
  If[family =!= evolution["Family"],
    fail["MasterIntegralSolutionFamilyMismatch"]];
  familySystemReference = Lookup[boundaryMap,
    "FamilyDifferentialSystemReference", Missing[]];
  requirementsReference = Lookup[boundaryMap,
    "MasterIntegralEpsilonOrderRequirementsReference", Missing[]];
  If[! finishFamilyDifferentialSystemReferenceQ[
      familySystemReference, family],
    fail["FamilyDifferentialSystemReferenceRequired"]];
  If[! finishMasterIntegralEpsilonOrderRequirementsReferenceQ[
      requirementsReference],
    fail["MasterIntegralEpsilonOrderRequirementsReferenceRequired"]];
  If[Lookup[boundaryMap, "BoundaryDomain", Missing[]] =!=
        evolution["BoundaryDomain"],
    fail["MasterIntegralSolutionBoundaryDomainMismatch"]];
  If[Lookup[boundaryMap, "DimensionalRegulator", Missing[]] =!=
        evolution["DimensionalRegulator"],
    fail["MasterIntegralSolutionDimensionalRegulatorMismatch"]];
  ids = evolution["BoundaryFunctionIDs"];
  idRecords = evolution[
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs"];
  baseConstantIDs = tangentialEvolutionBaseConstantIDs[idRecords];
  valuations = evolution["BoundaryFunctionEpsilonValuations"];
  functionIndex = tangentialEvolutionFunctionIndex[ids];
  inputCoordinates =
    boundaryMap["BoundaryFunctionEpsilonCoefficientRecords"];
  inputLabels =
    boundaryMap["BoundaryFunctionEpsilonCoefficientLabels"];
  If[! AllTrue[inputCoordinates,
      IntegerQ[tangentialEvolutionLookup[functionIndex,
          #["BoundaryFunctionID"]]] &&
        #["EpsilonOrder"] >= tangentialEvolutionLookup[valuations,
          #["BoundaryFunctionID"]] &],
    fail["MasterIntegralSolutionBoundaryFunctionCoordinateInvalid"]];
  coefficientMaps = evolution[
    "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder"];
  evolutionWindow = evolution["EpsilonOrderWindow"];
  evolutionValuation = evolution["EvolutionOperatorEpsilonValuation"];
  minimumBoundaryValuation = Min[
    tangentialEvolutionLookup[valuations, #] & /@ ids];
  requiredHigh = If[inputCoordinates === {}, evolutionValuation,
    Max[Lookup[inputCoordinates, "EpsilonOrder"]] -
      minimumBoundaryValuation];
  requiredWindow = {evolutionValuation, requiredHigh};
  If[Last[evolutionWindow] < requiredHigh,
    fail["TangentialBoundaryEvolutionEpsilonWindowInsufficient", <|
      "RequiredEpsilonOrderWindow" -> requiredWindow,
      "AvailableEpsilonOrderWindow" -> evolutionWindow|>]];
  coordinatePieces = Reap[Do[
      KeyValueMap[Function[{sequence, matrix},
          Do[With[{sourceIndex = tangentialEvolutionLookup[functionIndex,
                coordinate["BoundaryFunctionID"]],
              targetOrder = coordinate["EpsilonOrder"] - order},
            If[targetOrder >= tangentialEvolutionLookup[valuations,
                  ids[[targetColumn]]] &&
                ! finishExactZeroQ[matrix[[sourceIndex, targetColumn]]],
              Sow[tangentialEvolutionOutputCoordinate[
                tangentialEvolutionLookup[baseConstantIDs,
                  ids[[targetColumn]]], ids[[targetColumn]], targetOrder,
                tangentialEvolutionLookup[valuations,
                  ids[[targetColumn]]]]]]],
            {coordinate, inputCoordinates},
            {targetColumn, Length[ids]}]],
        tangentialEvolutionLookup[coefficientMaps, order]],
      {order, Range @@ requiredWindow}]][[2]];
  coordinatePieces = If[coordinatePieces === {}, {}, First[coordinatePieces]];
  outputCoordinates = DeleteDuplicatesBy[coordinatePieces,
    tangentialEvolutionCoordinateKey[
      #["BoundaryConstantID"], #["EpsilonOrder"]] &];
  outputIndex = AssociationThread[
    (tangentialEvolutionCoordinateKey[
        #["BoundaryConstantID"], #["EpsilonOrder"]] &) /@
      outputCoordinates, Range[Length[outputCoordinates]]];
  outputCount = Length[outputCoordinates];
  rightRecords = Flatten[Table[
      KeyValueMap[Function[{sequence, matrix}, With[
          {lifted = tangentialEvolutionTransformation[order, matrix,
              inputCoordinates, outputIndex, functionIndex, ids,
              baseConstantIDs, valuations, outputCount]},
          If[finishExactMatrixNonzeroPositions[lifted] === {}, Nothing,
            <|"TangentialEvolutionEpsilonOrder" -> order,
              "TangentialBoundaryPathIteratedIntegralLetterSequence" ->
                sequence,
              "IteratedIntegralCoefficientMatrix" -> lifted|>]]],
        tangentialEvolutionLookup[coefficientMaps, order]],
      {order, Range @@ requiredWindow}], 1];
  leftRecords = boundaryMap["IteratedIntegralCoefficientMatrixRecords"];
  leftPositions = finishExactMatrixNonzeroPositions /@
    Lookup[leftRecords, "IteratedIntegralCoefficientMatrix"];
  leftActiveColumnsByRecord =
    (DeleteDuplicates[Cases[#, {_, column_} :> column]] &) /@
      leftPositions;
  activeLeftColumns = Sort@DeleteDuplicates@Flatten[
    leftActiveColumnsByRecord];
  rightPositions = finishExactMatrixNonzeroPositions /@
    Lookup[rightRecords, "IteratedIntegralCoefficientMatrix", {}];
  requiredOutputIndices = Sort@DeleteDuplicates@Flatten[
    Map[Cases[#, {row_, column_} :>
          If[MemberQ[activeLeftColumns, row], column, Nothing]] &,
      rightPositions]];
  If[requiredOutputIndices === {},
    outputCoordinates = {}; rightRecords = {},
    outputCoordinates = outputCoordinates[[requiredOutputIndices]];
    rightRecords = Map[Function[record, Join[
        KeyDrop[record, "IteratedIntegralCoefficientMatrix"], <|
          "IteratedIntegralCoefficientMatrix" -> SparseArray[
            record["IteratedIntegralCoefficientMatrix"][[All,
              requiredOutputIndices]]]|>]], rightRecords];
    rightRecords = Select[rightRecords,
      Intersection[activeLeftColumns,
          Cases[finishExactMatrixNonzeroPositions[
            #["IteratedIntegralCoefficientMatrix"]],
            {row_, _} :> row]] =!= {} &]];
  rightPositions = finishExactMatrixNonzeroPositions /@
    Lookup[rightRecords, "IteratedIntegralCoefficientMatrix", {}];
  rightActiveRowsByRecord =
    (DeleteDuplicates[Cases[#, {row_, _} :> row]] &) /@ rightPositions;
  activeInterfaceIndices = Sort@Intersection[activeLeftColumns,
    DeleteDuplicates@Flatten[rightActiveRowsByRecord]];
  dependencies = Table[
    leftRecordIndices = Select[Range[Length[leftRecords]],
      MemberQ[leftActiveColumnsByRecord[[#]], interfaceIndex] &];
    rightRecordIndices = Select[Range[Length[rightRecords]],
      MemberQ[rightActiveRowsByRecord[[#]], interfaceIndex] &];
    constantIndices = Sort@DeleteDuplicates@Flatten[
      Cases[rightPositions[[#]], {row_, column_} :>
          If[row === interfaceIndex, column, Nothing]] & /@
        rightRecordIndices];
    <|"BoundaryFunctionEpsilonCoefficientIndex" -> interfaceIndex,
      "LeftFactorRecordIndices" -> leftRecordIndices,
      "RightFactorRecordIndices" -> rightRecordIndices,
      "BoundaryConstantEpsilonCoefficientIndices" -> constantIndices|>,
    {interfaceIndex, activeInterfaceIndices}];
  unevaluatedConstantIndices = Flatten@Position[
    Lookup[outputCoordinates, "Status", "Unevaluated"], "Unevaluated"];
  dependencies = Select[Map[ReplacePart[#,
        "BoundaryConstantEpsilonCoefficientIndices" -> Intersection[
          #["BoundaryConstantEpsilonCoefficientIndices"],
          unevaluatedConstantIndices]] &, dependencies],
    #["BoundaryConstantEpsilonCoefficientIndices"] =!= {} &];
  pathKeys = {"CurrentPathFirstSegmentLetterIndices",
    "CurrentPathSecondSegmentLetterIndices",
    "BoundaryPathFirstSegmentLetterIndices",
    "BoundaryPathSecondSegmentLetterIndices"};
  leftRecordIndices = Sort@DeleteDuplicates@Flatten[
    Lookup[dependencies, "LeftFactorRecordIndices", {}]];
  requiredPathSequences = If[leftRecordIndices === {}, {},
    DeleteDuplicates[KeyTake[#, pathKeys] & /@
      leftRecords[[leftRecordIndices]]]];
  rightRecordIndices = Sort@DeleteDuplicates@Flatten[
    Lookup[dependencies, "RightFactorRecordIndices", {}]];
  requiredTangentialSequences = If[rightRecordIndices === {}, {},
    DeleteDuplicates[Lookup[rightRecords[[rightRecordIndices]],
      "TangentialBoundaryPathIteratedIntegralLetterSequence"]]];
  requirements = If[unevaluatedConstantIndices === {}, {},
    tangentialEvolutionRequirement[#, evolution["TangentialBasePoint"]] & /@
      GatherBy[outputCoordinates[[unevaluatedConstantIndices]],
        #["BoundaryConstantID"] &]];
  outputWindow = If[outputCoordinates === {}, {},
    MinMax[Lookup[outputCoordinates, "EpsilonOrder"]]];
  boundaryDataStatus = finishBoundaryDataStatus[outputCoordinates];
  product = <|
    "ProductConvention" -> "LeftFactor.RightFactor",
    "ActionOrder" -> {"RightFactor", "LeftFactor"},
    "LeftFactor" -> boundaryMap,
    "RightFactor" -> <|
      "TangentialBoundaryEvolutionOperator" -> evolution,
      "EpsilonLiftedIteratedIntegralCoefficientMatrixRecords" ->
        rightRecords|>,
    "BoundaryFunctionEpsilonCoefficientInterface" -> <|
      "CoordinateRecords" -> inputCoordinates,
      "CoordinateLabels" -> inputLabels,
      "LeftFactorColumnOrder" -> "CoordinateRecords",
      "RightFactorRowOrder" -> "CoordinateRecords",
      "Identification" ->
        "ExactBoundaryFunctionIDAndEpsilonOrder"|>|>;
  <|
    "DataType" -> "MasterIntegralSolution", "SchemaVersion" -> 2,
    "Status" -> "MasterIntegralSolutionConstructed",
    "SolutionType" ->
      "MasterIntegralSolutionInTermsOfBoundaryConstants",
    "SolutionRepresentation" -> "OrderedSparseCoefficientOperatorProduct",
    "Family" -> family,
    "FamilyDifferentialSystemReference" -> familySystemReference,
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      requirementsReference,
    "BoundaryDomain" -> evolution["BoundaryDomain"],
    "DimensionalRegulator" -> evolution["DimensionalRegulator"],
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> boundaryMap[
      "RequestedMasterIntegralEpsilonOrderAndRowPairs"],
    "DemandCoverage" -> "Complete",
    "BoundaryDataStatus" -> boundaryDataStatus,
    "OrderedSparseCoefficientOperatorProduct" -> product,
    "BoundaryConstantEpsilonCoefficientRecords" -> outputCoordinates,
    "BoundaryConstantEpsilonCoefficientLabels" ->
      ({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@
        outputCoordinates,
    "BoundaryDataRequirements" -> requirements,
    "BoundaryConstantEpsilonCoefficientEvaluationWorklist" -> <|
      "BoundaryFunctionInterfaceCoordinateDependencies" -> dependencies,
      "RequiredPathSegmentLetterIndexSequenceRecords" ->
        requiredPathSequences,
      "RequiredTangentialIteratedIntegralLetterSequences" ->
        requiredTangentialSequences,
      "RequiredBoundaryConstantEpsilonCoefficientIndices" ->
        unevaluatedConstantIndices|>,
    "EpsilonOrderCoverage" -> <|
      "RequiredTangentialEvolutionEpsilonOrderWindow" -> requiredWindow,
      "AvailableTangentialEvolutionEpsilonOrderWindow" -> evolutionWindow,
      "OutputBoundaryConstantEpsilonOrderWindow" -> outputWindow|>,
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
    "SolutionConvention" ->
      "The right tangential-evolution factor acts first; its result is multiplied by the left boundary-function-to-master-integral factor, and the two segment-specific iterated integrals remain an ordered product."|>
];

finishFactorizedMasterIntegralSolutionQ[record_Association] := Module[
  {product, leftFactor, rightFactor, evolution, expected, requiredKeys},
  If[Lookup[record, "DataType", None] =!= "MasterIntegralSolution" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "MasterIntegralSolutionConstructed" ||
      Lookup[record, "SolutionType", None] =!=
        "MasterIntegralSolutionInTermsOfBoundaryConstants" ||
      Lookup[record, "SolutionRepresentation", None] =!=
        "OrderedSparseCoefficientOperatorProduct" ||
      Lookup[record, "DemandCoverage", None] =!= "Complete" ||
      AnyTrue[{"IteratedIntegralCoefficientMatrixTerms", "Expressions",
          "Terms"}, KeyExistsQ[record, #] &], Return[False]];
  product = Lookup[record,
    "OrderedSparseCoefficientOperatorProduct", Missing[]];
  If[! AssociationQ[product], Return[False]];
  leftFactor = Lookup[product, "LeftFactor", Missing[]];
  rightFactor = Lookup[product, "RightFactor", Missing[]];
  If[! AssociationQ[leftFactor] || ! AssociationQ[rightFactor],
    Return[False]];
  evolution = Lookup[rightFactor,
    "TangentialBoundaryEvolutionOperator", Missing[]];
  If[! AssociationQ[evolution], Return[False]];
  expected = finishFactorizedMasterIntegralSolution[leftFactor, evolution];
  If[FailureQ[expected] || ! AssociationQ[expected], Return[False]];
  requiredKeys = Keys[expected];
  SameQ[KeyTake[record, requiredKeys], expected]
];
finishFactorizedMasterIntegralSolutionQ[_] := False;

ConstructMasterIntegralSolution[boundaryMap_Association,
    evolution_Association] :=
  finishFactorizedMasterIntegralSolution[boundaryMap, evolution];

ConstructMasterIntegralSolution[family_String, OptionsPattern[]] := Module[
  {loaded, result, directory},
  loaded = finishInputFiles[OptionValue["InputFiles"]];
  If[FailureQ[loaded], Return[loaded]];
  If[! IntegerQ[OptionValue["MaximumConnectorWords"]] ||
      OptionValue["MaximumConnectorWords"] < 1,
    Return[finishFailure["InvalidConnectorWordBudget"]]];
  result = finishPointMasterIntegralSolution[family, loaded["Values"],
    OptionValue["MaximumConnectorWords"]];
  directory = OptionValue["OutputDirectory"];
  If[AssociationQ[result] && StringQ[directory],
    If[! DirectoryQ[directory],
      CreateDirectory[directory, CreateIntermediateDirectories -> True]];
    Put[result, FileNameJoin[{directory,
      "master_integral_solution_" <> family <> ".wl"}]]];
  result
];

ConstructMasterIntegralSolution[___] :=
  finishFailure["MasterIntegralSolutionInputsNotWellFormed"];

MasterIntegralSolutionQ[record_Association] := Switch[
  Lookup[record, "SolutionRepresentation", None],
  "OrderedSparseCoefficientOperatorProduct",
    finishFactorizedMasterIntegralSolutionQ[record],
  "TargetLaurentFunctionalTimesGradedExactCoefficientCircuit",
    finishPointMasterIntegralSolutionQ[record],
  _, False
];
MasterIntegralSolutionQ[___] := False;
