#!/usr/bin/env wolframscript

(* Project the exact mathematical data needed by the CF303 demand-pruned
   normal/bulk coefficient accessor out of the accepted temporary adapter.
   Provider paths, campaign manifests, hashes, and evaluator provenance are
   deliberately not part of the durable V2 operator. *)

$AllowInternet = False;
$HistoryLength = 0;

ClearAll[cf303NormalBulkV2Projection, cf303NormalBulkV2PathStringQ,
  cf303NormalBulkV2NonzeroMatrixQ, cf303NormalBulkV2BaseLetterQ,
  cf303NormalBulkV2ExpressionHeadNamedQ,
  cf303NormalBulkV2RelativePath];

cf303NormalBulkV2Projection[input_Association] := Module[
  {sourceArtifact, sourceOperator, gOperator, retainedTopLevel},
  sourceArtifact = input["SourceArtifact"];
  sourceOperator = KeyDrop[sourceArtifact["Operator"], "Provider"];
  sourceArtifact = Join[
    KeyTake[sourceArtifact, {"Status", "IncludedExtensionBlocks",
      "OriginalRows", "MasterCount", "RationalMasterCount",
      "ExtensionMasterCount", "Curve", "RequiredSourceTop",
      "RequiredSourceTopDerivation", "Path"}],
    <|"Operator" -> sourceOperator|>];
  gOperator = Join[
    KeyDrop[input["GOperator"], "SourceArtifact"],
    <|"SourceArtifact" -> sourceArtifact|>];
  retainedTopLevel = KeyTake[input, {"Status", "Route", "SourceRows",
    "TargetRows", "BoundaryColumns", "HByOrderPairs", "HOrders",
    "PhysicalGaugeByOrderPairs", "PhysicalGaugeOrders", "Curve",
    "Variable", "PairConvention", "CanonicalRelation",
    "PhysicalRelation", "BoundaryConvention"}];
  Join[retainedTopLevel,
    <|"SourceArtifact" -> sourceArtifact, "GOperator" -> gOperator|>]
];

cf303NormalBulkV2PathStringQ[value_] := StringQ[value] &&
  StringContainsQ[value, "factorization-and-loops-codex"];

cf303NormalBulkV2NonzeroMatrixQ[matrix_] :=
  Length[SparseArray[matrix]["NonzeroPositions"]] > 0;

cf303NormalBulkV2BaseLetterQ[label_] := MatchQ[label,
  {("GPLPole" | "GPLFactor" | "E4Pole" | "E4Factor" |
    "E4Omega0" | "E4OmegaInf" | "E4Eta2"), ___}];

cf303NormalBulkV2ExpressionHeadNamedQ[expression_, name_String] :=
  With[{head = Head[expression]},
    Head[head] === Symbol && SymbolName[head] === name];

cf303NormalBulkV2RelativePath[fromDirectory_String, target_String] :=
 Module[{from = FileNameSplit[ExpandFileName[fromDirectory]],
   to = FileNameSplit[ExpandFileName[target]], common = 0},
  While[common < Min[Length[from], Length[to]] &&
      from[[common + 1]] === to[[common + 1]], common++];
  FileNameJoin[Join[ConstantArray["..", Length[from] - common],
    Drop[to, common]]]
];

result = Block[{$HistoryLength = 0}, Catch@Module[
  {fail, scriptDirectory, repository, arguments, inputPath, junctionPath,
   outputPath, outputDirectory, bundleManifestPath, bundleManifest,
   input, junction, operatorData,
   sourceOperator, gOperator, sourceModeMap, logarithmicDeck,
   logarithmicOrders, resonantInheritedModeIndices = {2, 3, 4, 6},
   resonantModeIDs, resonantCombinedModeIndices, sourceSupportByOrder,
   sourceSupportIndices, sourceSupportMasterRows, offDiagonalResidues,
   compositeDefinitions, contributingSourceOrders,
   relevantOffDiagonalKeys, relevantLetterRecords, missingLetterRecords,
   deferredClasses = {"CF303AcceptedIncomingKLeaf",
     "CF303HybridBaselineCrossK", "CF303CircuitGPLKernel",
     "CF303ExactEllipticKernel"}, allDeferredLabels,
   encodedDeferredCounts, contributingDeferredCounts,
   hNodes, hNodeCountsByOrder, transferProvider,
   exactCoefficientCircuitRequirement, junctionReference,
   singularPointResidueData, conditions, validation},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
  repository = DirectoryName[scriptDirectory, 3];
  arguments = Rest[$ScriptCommandLine];
  inputPath = If[Length[arguments] >= 1, arguments[[1]],
    FileNameJoin[{DirectoryName[repository],
      "factorization-and-loops-codex", "Runtime",
      "2026-08-31_cf303_native_dlog_residues",
      "cf303_final45_hybrid_baseline_lazy_operator.wl"}]];
  junctionPath = If[Length[arguments] >= 2, arguments[[2]],
    FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "DifferentialEquationDataV2", "CF303",
      "CF303TangentialJunctionMapReconstructed.wl"}]];
  outputPath = If[Length[arguments] >= 3, arguments[[3]],
    FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "DifferentialEquationDataV2", "CF303",
      "CF303NormalBulkIteratedIntegralCoefficientOperatorV2.wl"}]];
  outputDirectory = DirectoryName[ExpandFileName[outputPath]];
  bundleManifestPath = FileNameJoin[{scriptDirectory, "data",
    "normal_factor_exact_circuit", "bundle_manifest.json"}];
  If[! FileExistsQ[inputPath] || ! FileExistsQ[junctionPath],
    fail["CF303NormalBulkTemporaryInputMissing"]];
  Get[FileNameJoin[{repository, "Addon", "Load", "LoadFACET.wl"}]];
  input = Quiet[Check[FeynFacet`FamilyArtifactRead[inputPath], $Failed]];
  junction = Quiet[Check[
    FeynFacet`FamilyArtifactRead[junctionPath], $Failed]];
  bundleManifest = Quiet[Check[
    Import[bundleManifestPath, "RawJSON"], $Failed]];
  If[! AssociationQ[input] || Lookup[input, "Status", None] =!=
      "CF303HybridBaselineLazyCircuitAdapterAcceptedV1",
    fail["CF303NormalBulkTemporaryInputInvalid"]];
  If[! AssociationQ[junction] || Lookup[junction, "Status", None] =!=
        "CF303TangentialJunctionMapReconstructedV1" ||
      Lookup[junction, "IndependentValidationComparisonCount", 0] =!= 112,
    fail["CF303NormalBulkTangentialJunctionInputInvalid"]];
  If[! AssociationQ[bundleManifest] ||
      Lookup[bundleManifest, "DataType", None] =!=
        "CF303NormalFactorExactCircuitBundle" ||
      Lookup[bundleManifest, "SchemaVersion", None] =!= 2,
    fail["CF303NormalBulkExactCircuitBundleManifestInvalid"]];
  operatorData = cf303NormalBulkV2Projection[input];
  sourceOperator = operatorData["SourceArtifact", "Operator"];
  gOperator = operatorData["GOperator"];
  sourceModeMap = junction["SourceModeMap"];
  logarithmicDeck = junction["ResonantZeroSector",
    "LogarithmicJordanCoefficientC"];
  logarithmicOrders = Range[-3, 4];
  resonantModeIDs = junction["InheritedModeOrder"][[
    resonantInheritedModeIndices]];
  resonantCombinedModeIndices =
    (First@FirstPosition[junction["CombinedModeOrder"], #]) & /@
      resonantModeIDs;
  sourceSupportByOrder = AssociationMap[
    Sort@DeleteDuplicates[First /@ SparseArray[
      sourceModeMap[#][[All, resonantCombinedModeIndices]]][
        "NonzeroPositions"]] &,
    Keys[sourceModeMap]];
  sourceSupportIndices = Sort@DeleteDuplicates@Flatten[
    Values[sourceSupportByOrder]];
  sourceSupportMasterRows =
    gOperator["SourceRows"][[sourceSupportIndices]];
  offDiagonalResidues = gOperator["OffDiagonalResidues"];
  compositeDefinitions = Lookup[gOperator, "CompositeDefinitions", <||>];
  contributingSourceOrders[key_] := Select[Keys[sourceModeMap],
    MemberQ[logarithmicOrders, First[key] + #] &&
      cf303NormalBulkV2NonzeroMatrixQ[
        offDiagonalResidues[key] .
          sourceModeMap[#][[All, resonantCombinedModeIndices]]] &];
  relevantOffDiagonalKeys = Select[Keys[offDiagonalResidues],
    contributingSourceOrders[#] =!= {} &];
  relevantLetterRecords = Map[Function[key, Module[
      {letterID = Last[key], label, sourceOrders, activeIndices},
      label = gOperator["Letters"][[letterID]];
      sourceOrders = contributingSourceOrders[key];
      activeIndices = Sort@DeleteDuplicates[Last /@ Select[
        offDiagonalResidues[key]["NonzeroPositions"],
        MemberQ[sourceSupportIndices, Last[#]] &]];
      <|"EpsilonOrder" -> First[key], "LetterID" -> letterID,
        "Letter" -> label,
        "ContributingSourceModeEpsilonOrders" -> sourceOrders,
        "ResultingLogarithmicEpsilonOrders" ->
          (First[key] + # & /@ sourceOrders),
        "GOperatorSourceColumnIndices" -> activeIndices,
        "SourceMasterIntegralRows" ->
          gOperator["SourceRows"][[activeIndices]],
        "EndpointOneFormDefinitionAvailable" ->
          (cf303NormalBulkV2BaseLetterQ[label] ||
            KeyExistsQ[compositeDefinitions, label]),
        "RequiredData" ->
          "Exact normal one-form residue at z=2p as a rational function of p, or an exact composite definition in the supported inert alphabet"|>]],
    relevantOffDiagonalKeys];
  missingLetterRecords = Select[relevantLetterRecords,
    ! TrueQ[#["EndpointOneFormDefinitionAvailable"]] &];
  allDeferredLabels = Select[gOperator["Letters"],
    MatchQ[#, {head_String /; MemberQ[deferredClasses, head], ___}] &];
  encodedDeferredCounts = AssociationThread[deferredClasses,
    Lookup[Counts[First /@ allDeferredLabels], deferredClasses, 0]];
  contributingDeferredCounts = AssociationThread[deferredClasses,
    Lookup[Counts[First[#["Letter"]] & /@ missingLetterRecords],
      deferredClasses, 0]];
  hNodes = Cases[Normal /@ Flatten[
      Values[operatorData["HByOrderPairs"]], 1],
    expression_ /; cf303NormalBulkV2ExpressionHeadNamedQ[
      expression, "CF303HybridBaselineH"], Infinity];
  hNodeCountsByOrder = Counts[First[List @@ #] & /@ hNodes];
  transferProvider = Lookup[gOperator, "TransferProvider", Missing[]];
  exactCoefficientCircuitRequirement = <|
    "Status" -> "CF303NormalBulkCompletionInputsMissing",
    "BlockingScope" ->
      "Compatibility of the exact normal factor with tangential evolution",
    "PortableExactDataAlreadyPreserved" -> <|
      "BaseTransferEntryRecordCount" -> If[
        AssociationQ[transferProvider],
        Length[Lookup[transferProvider, "EntryRecords", {}]], 0],
      "BaseTransferProviderContainsNoScratchPath" ->
        AssociationQ[transferProvider] &&
          FreeQ[transferProvider, _?cf303NormalBulkV2PathStringQ]|>,
    "PortableExactCircuitBundleCandidate" -> <|
      "Reference" -> <|
        "RelativePath" -> cf303NormalBulkV2RelativePath[
          outputDirectory, bundleManifestPath],
        "DataType" -> bundleManifest["DataType"],
        "SchemaVersion" -> bundleManifest["SchemaVersion"]|>,
      "Status" -> bundleManifest["Status"],
      "DefinitionClosure" -> bundleManifest["DefinitionClosure"],
      "BlockingConditions" -> bundleManifest["BlockingConditions"]|>,
    "InertOffDiagonalBasisTransformationNodes" -> <|
      "Head" -> "CF303HybridBaselineH",
      "OccurrenceCount" -> Length[hNodes],
      "UniqueNodeCount" -> Length[DeleteDuplicates[hNodes]],
      "CountsByEpsilonOrder" -> hNodeCountsByOrder|>,
    "InertOffDiagonalKernelLabels" -> <|
      "CountsByClass" -> encodedDeferredCounts,
      "TotalCount" -> Total[Values[encodedDeferredCounts]]|>,
    "DemandReachabilityWitness" -> <|
      "PhysicalMasterIntegralEpsilonOrder" -> -4,
      "SurvivingNormalWordCount" -> 10,
      "ReachableInertHOccurrenceCount" -> 48,
      "ReachableDeferredLetterIDs" ->
        {176, 184, 192, 200, 208, 216, 224, 232},
      "ReachableDeferredLabelClass" ->
        "CF303AcceptedIncomingKLeaf",
      "Method" ->
        "Exact demand-pruned coefficient enumeration at the lowest requested epsilon order"|>,
    "MissingDurableMathematicalData" -> {
      "An executable characteristic-zero compiler from the preserved CF303 block-1 source leaf to the exact Hermite input, with at least one actual reachable node replay",
      "The ambient tangential connection A_p|rho=A_p|z+2*A_z in the same basis as the normal factor, or an equivalent independently validated moving-boundary mode-matching record"},
    "MissingInputContract" -> <|
      "FamilyDifferentialSystem" -> <|
        "DataType" -> "FamilyDifferentialSystem",
        "SchemaVersion" -> 2,
        "RequiredFields" -> {"Family", "KinematicVariables",
          "DimensionalRegulator", "OriginalMasterIntegralBasis",
          "ConnectionMatrices"}|>,
      "RequiredCoordinatePullback" -> <|
        "NormalCoordinate" -> HoldForm[
          Evaluate[Global`rho == 2 Global`p - Global`z]],
        "TangentialDerivative" ->
          "partial_p at fixed rho = partial_p at fixed z + 2 partial_z",
        "RequiredConnection" ->
          "A_p|rho=A_p|z+2*A_z in the exact 45-component normal-factor basis"|>,
      "BoundaryAsymptoticModeMatching" -> <|
        "DataType" -> "BoundaryAsymptoticModeMatching",
        "SchemaVersion" -> 2,
        "RequiredModeCount" -> 13,
        "RequiredCoefficientWindow" -> {-4, 3},
        "RequiredModeEmbedding" ->
          "The accepted 45x13 SourceModeMap/TargetGModeMap in the same basis as A_p|rho"|>,
      "RequiredIdentity" ->
        "B.Omega=(A_p|rho).B-D[B,p], together with normal-residue horizontality",
      "SmallestUnrecordedMatrix" ->
        "The 2x43 target-from-source block of A_p|rho in the G25 basis, or its exact 2x13 contraction with SourceModeMap; TangentialTargetConnection records only the 2x2 homogeneous target block",
      "PreservedLegacyCandidateAudit" -> <|
        "ConnectionMatrixDimensions" -> {2, 45, 45},
        "BasisTransformationDimensions" -> {45, 45},
        "CoefficientSymbols" -> {Global`x, Global`y, Global`eps},
        "CanonicalFamilyConnectionInFBasisAvailable" -> True,
        "CanonicalToPhysicalConvention" ->
          "I=(TDiagonal.S).F",
        "NormalPathGaugeConvention" ->
          "F25=G25+H.Fsource",
        "SuppliesG25TangentialConnectionWithoutHAndDpH" -> False,
        "V2FamilyDifferentialSystemAvailable" -> False,
        "NormalFactorBasisBindingAvailable" -> False|>|>,
    "RequiredEvaluationContract" -> <|
      "Representation" ->
        "A path-independent exact arithmetic DAG over preserved mathematical leaves is sufficient; eager rational-function expansion is not required",
      "Operations" -> {"Add", "Multiply", "Derivative",
        "DeterministicRationalHermite",
        "DeterministicQuarticHermite", "NormalizeHAtBasePoint",
        "AcceptedIncomingRemainderLeaf", "CrossHermiteRemainder",
        "T25Convolution"},
      "Inputs" ->
        {"p", "z", "dimensional regulator", "epsilon order",
         "target master integral row", "source master integral row",
         "rational/elliptic channel"},
      "Output" ->
        "Exact characteristic-zero coefficient or exact finite-field image with reconstruction metadata",
      "TangentialCompatibilityIdentity" ->
        "D[N,p] at fixed rho = (A_p at fixed z + 2 A_z).N - N.Omega, where rho=2p-z",
      "PathPolicy" ->
        "All evaluator code and mathematical leaves must be stored in the repository and referenced by ordinary relative paths"|>|>;
  junctionReference = <|
    "RelativePath" -> cf303NormalBulkV2RelativePath[
      outputDirectory, junctionPath],
    "DataType" -> "CF303TangentialJunctionMap",
    "SchemaVersion" -> 1,
    "SourceStatus" -> junction["Status"]|>;
  singularPointResidueData = <|
    "DataType" -> "NormalSingularPointResidueData",
    "SchemaVersion" -> 2,
    "NormalCoordinate" -> Symbol["Global`rho"],
    "SingularPointRelation" ->
      HoldForm[Evaluate[Symbol["Global`rho"] ==
        2 Symbol["Global`p"] - Symbol["Global`z"]]],
    "ResonantInheritedModeIndices" -> resonantInheritedModeIndices,
    "ResonantInheritedModeIDs" -> resonantModeIDs,
    "LogarithmicJordanCoefficientDeck" -> logarithmicDeck,
    "EpsilonOrderWindow" -> {-3, 4},
    "AuthoritativeSource" -> Join[junctionReference, <|
      "ProjectionField" -> {"InheritedNormalResidueProjection"},
      "LogarithmicDeckField" ->
        {"ResonantZeroSector", "LogarithmicJordanCoefficientC"}|>],
    "MathematicalSourceRelation" -> <|
      "Construction" ->
        "The junction point engine forms the effective rho^-1 residue from accepted K entries, recurrence cross-K entries, and block-1 circuit residues, projects it onto the seven inherited source modes, reconstructs the rational functions in Q(p), and extracts the four resonant logarithmic columns",
      "DefiningConvolution" ->
        "C_r(p)=Sum_{h+q=r} Sum_id Res_{z=2p}(omega_id) R_{h,id}(p) V_q(p), restricted to the four resonant inherited mode columns",
      "IndependentValidationComparisonCount" ->
        junction["IndependentValidationComparisonCount"],
      "RegularizationStatus" ->
        junction["Regularization", "Status"]|>,
    "ProviderFreeOperatorProjectionReplay" -> <|
      "Status" -> If[missingLetterRecords === {},
        "NormalSingularPointResidueReplayDataComplete",
        "NormalSingularPointResidueDeferredOneFormDefinitionsMissing"],
      "RepresentationLimitationOnly" -> True,
      "GOperatorResonantSourceSupportByEpsilonOrder" ->
        sourceSupportByOrder,
      "GOperatorResonantSourceColumnIndices" -> sourceSupportIndices,
      "ResonantSourceMasterIntegralRows" -> sourceSupportMasterRows,
      "EncodedDeferredLetterCountsByClass" -> encodedDeferredCounts,
      "ContributingMissingLetterCountsByClass" ->
        contributingDeferredCounts,
      "ContributingMissingLetterRecordCount" ->
        Length[missingLetterRecords],
      "ContributingMissingLetterRecords" -> missingLetterRecords,
      "Block1ContributionToResonantProjection" ->
        (Lookup[contributingDeferredCounts, "CF303CircuitGPLKernel", 0] +
          Lookup[contributingDeferredCounts,
            "CF303ExactEllipticKernel", 0]),
      "Reason" ->
        "The durable provider-free GOperator retains these kernels as inert deferred labels but does not retain their exact one-form definitions; the accepted junction reconstruction is therefore the sole authoritative replay of the Levelt residue"|>,
    "Validation" -> <|
      "Method" ->
        "AcceptedJunctionReconstructionProvenanceAndExactDeckShape",
      "Conditions" -> <|
        "JunctionReconstructionAccepted" ->
          junction["Status"] ===
            "CF303TangentialJunctionMapReconstructedV1",
        "IndependentValidationCount" ->
          junction["IndependentValidationComparisonCount"] === 112,
        "RegularizedIntertwiningJetsAccepted" ->
          junction["Regularization", "Status"] ===
            "TangentialJunctionIntertwiningJetsAccepted",
        "LogarithmicDeckOrderCoverage" ->
          Sort[Keys[logarithmicDeck]] === logarithmicOrders,
        "LogarithmicDeckDimensions" -> AllTrue[Values[logarithmicDeck],
          MatrixQ[#] && Dimensions[#] === {2, 4} &],
        "NonzeroLogarithmicCoefficientPresent" ->
          AnyTrue[Values[logarithmicDeck],
            cf303NormalBulkV2NonzeroMatrixQ]|>|>|>;
  conditions = <|
    "ExactProjectionReDerived" ->
      operatorData === cf303NormalBulkV2Projection[input],
    "TemporaryProviderPathsEliminated" ->
      FreeQ[operatorData, _?cf303NormalBulkV2PathStringQ],
    "SourceCanonicalOperatorComplete" ->
      Lookup[sourceOperator, "Status", None] ===
        "CanonicalGPLChenOperatorV1" &&
      Lookup[sourceOperator, "N", None] === 43 &&
      AllTrue[Lookup[sourceOperator, "Residues", {}],
        MatrixQ[#] && Dimensions[#] === {43, 43} &],
    "FinalLayerOperatorComplete" ->
      Lookup[gOperator, "Status", None] ===
        "CF303Final45LazyEllipticOperatorAcceptedV1" &&
      Lookup[gOperator, "SourceN", None] === 43 &&
      Lookup[gOperator, "N", None] === 45 &&
      Lookup[operatorData, "TargetRows", {}] === {44, 45},
    "LaurentEndpointOperatorsComplete" ->
      AssociationQ[Lookup[operatorData, "HByOrderPairs", None]] &&
      Sort[Keys[operatorData["HByOrderPairs"]]] ===
        Sort[operatorData["HOrders"]] &&
      AssociationQ[Lookup[operatorData,
        "PhysicalGaugeByOrderPairs", None]] &&
      Sort[Keys[operatorData["PhysicalGaugeByOrderPairs"]]] ===
        Sort[operatorData["PhysicalGaugeOrders"]],
    "AuthoritativeLeveltInputAccepted" ->
      And @@ Values[singularPointResidueData["Validation",
        "Conditions"]],
    "PortableBaseTransferProviderPreserved" ->
      TrueQ[exactCoefficientCircuitRequirement[
        "PortableExactDataAlreadyPreserved",
        "BaseTransferProviderContainsNoScratchPath"]] &&
        exactCoefficientCircuitRequirement[
          "PortableExactDataAlreadyPreserved",
          "BaseTransferEntryRecordCount"] === 76,
    "PortableBundleCorrectlyRemainsIncomplete" ->
      bundleManifest["Status"] ===
        "CF303NormalFactorExactCircuitBundleIncomplete" &&
      TrueQ[bundleManifest["DefinitionClosure",
        "FreshPrimeBlock1ReplayValidated"]] &&
      TrueQ[bundleManifest["DefinitionClosure",
        "FreshPrimeFullNinetyEntryReplayValidated"]] &&
      ! TrueQ[bundleManifest["DefinitionClosure",
        "CharacteristicZeroHermiteNodeClosure"]] &&
      ! TrueQ[bundleManifest["DefinitionClosure",
        "TangentialIntertwiningIdentityValidated"]],
    "LazyCircuitRepresentationPreciselyQuantified" ->
      exactCoefficientCircuitRequirement["Status"] ===
          "CF303NormalBulkCompletionInputsMissing" &&
        Length[hNodes] === 224 &&
        Total[Values[encodedDeferredCounts]] === 226|>;
  If[! And @@ Values[conditions],
    fail["CF303NormalBulkV2ProjectionValidationFailed",
      <|"Conditions" -> conditions,
        "ObservedInertHNodeCount" -> Length[hNodes],
        "ObservedDeferredLabelCount" ->
          Total[Values[encodedDeferredCounts]]|>]];
  validation = <|
    "Method" ->
      "ExactMathematicalFieldProjectionShapeReplayAndEvaluabilityAudit",
    "Conditions" -> conditions|>;
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  <|
    "DataType" ->
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    "SchemaVersion" -> 2,
    "Status" ->
      "CF303NormalBulkCompletionInputsMissing",
    "Family" -> "CF303", "RequestedMasterIntegralRows" -> {44, 45},
    "OperatorData" -> operatorData,
    "NormalSingularPointResidueData" -> singularPointResidueData,
    "CompletionRequirement" ->
      exactCoefficientCircuitRequirement,
    "ConstructionInputReferences" -> <|
      "TangentialJunctionMap" -> junctionReference,
      "PortableExactNormalFactorBundleCandidate" ->
        exactCoefficientCircuitRequirement[
          "PortableExactCircuitBundleCandidate", "Reference"]|>,
    "MathematicalSourceRelation" -> <|
      "SourceStatus" -> input["Status"],
      "Operation" ->
        "Exact projection of embedded canonical residues, final-layer residues, endpoint basis-transformation blocks, and physical-output basis transformation",
      "ExcludedNonMathematicalData" ->
        {"provider file paths", "campaign manifests", "evaluator paths",
         "hashes and settings fingerprints"}|>,
    "Validation" -> validation, "OutputPath" -> outputPath|>
]];

If[AssociationQ[result] && MemberQ[{
      "CF303NormalBulkIteratedIntegralCoefficientOperatorValidated",
      "CF303NormalBulkCompletionInputsMissing"},
    Lookup[result, "Status", None]],
  outputPath = result["OutputPath"];
  Put[KeyDrop[result, "OutputPath"], outputPath];
  If[result["Status"] ===
      "CF303NormalBulkIteratedIntegralCoefficientOperatorValidated",
    Print["PASS status=", result["Status"], " output=", outputPath];
    Quit[0],
    Print["BLOCKED status=", result["Status"],
      " hNodes=", result["CompletionRequirement",
        "InertOffDiagonalBasisTransformationNodes", "OccurrenceCount"],
      " deferredLabels=", result["CompletionRequirement",
        "InertOffDiagonalKernelLabels", "TotalCount"],
      " output=", outputPath];
    Quit[3]],
  Print["FAIL ", InputForm[result]];
  Quit[2]
];
