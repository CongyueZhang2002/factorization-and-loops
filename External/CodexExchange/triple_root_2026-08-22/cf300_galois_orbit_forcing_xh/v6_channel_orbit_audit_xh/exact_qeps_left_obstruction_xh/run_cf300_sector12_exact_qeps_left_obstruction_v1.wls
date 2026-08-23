#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300ExactQepsLeftObstructionDriverV1`"];
Begin["`Private`"];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300_EXACT_QEPS_WITNESS FAIL usage=<project-root> " <>
    "<v6d-result.wl> <captured-prerequisite.wl|-> <output.wl>"];
  End[]; EndPackage[]; Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
v6dArtifactFile = ExpandFileName[arguments[[2]]];
prerequisiteArgument = arguments[[3]];
prerequisiteFile = If[prerequisiteArgument === "-", None,
  ExpandFileName[prerequisiteArgument]];
outputFile = ExpandFileName[arguments[[4]]];
driverDirectory = DirectoryName[$InputFileName];
v6Directory = DirectoryName[driverDirectory];
galoisDirectory = DirectoryName[v6Directory];
exchangeDirectory = DirectoryName[galoisDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
supportDirectory = FileNameJoin[{exchangeDirectory,
  "cf300_sector12_next_ansatz_xh"}];

expectedV6dSHA256 =
  "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf";
expectedOrbitCoreSHA256 =
  "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed";
expectedHelperSHA256 =
  "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b";
expectedReconstructionSHA256 =
  "0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce";

files = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}],
  "Assembler" -> FileNameJoin[{directDirectory,
    "DirectRootChannelAssembler.wl"}],
  "WitnessReference" -> FileNameJoin[{supportDirectory,
    "AffineInconsistencyWitness.wl"}],
  "OrbitCoreV6d" -> FileNameJoin[{v6Directory,
    "GaloisChannelOrbitCoreV6d.wl"}],
  "ExactWitnessHelper" -> FileNameJoin[{driverDirectory,
    "CF300ExactQepsLeftObstruction.wl"}],
  "ModularReconstruction" -> FileNameJoin[{driverDirectory,
    "CF300ModularQepsWitnessReconstruction.wl"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "NativeFixedSquareBinary" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Backends", "flint", "bin", "flint_modular_solve"}]|>;
expectedHashes = <|
  "LoadFACET" ->
    "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
  "TripleRootAlgebra" ->
    "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "TripleRootStripAdapter" ->
    "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "TripleRootAffinePilot" ->
    "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "TripleRootReconstructionPrototype" ->
    "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "Assembler" ->
    "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "WitnessReference" ->
    "6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f",
  "OrbitCoreV6d" -> expectedOrbitCoreSHA256,
  "ExactWitnessHelper" -> expectedHelperSHA256,
  "ModularReconstruction" -> expectedReconstructionSHA256,
  "FiniteFieldStripSolve" ->
    "8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70",
  "NativeFixedSquareBinary" ->
    "e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b"|>;

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
fileHashes[] := AssociationMap[
  If[FileExistsQ[#1], FileHash[#1, "SHA256", "HexString"],
    $Failed] &, files];
deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]
];
writeAtomic[value_] := Module[{temporary, written, renamed, reread},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  reread = Quiet[Check[Get[outputFile], $Failed]];
  If[! SameQ[reread, value],
    deleteIfPresent[outputFile]; Return[$Failed]];
  outputFile
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status|>, data];
  If[writeAtomic[result] === $Failed,
    Print["CF300_EXACT_QEPS_WITNESS FAIL atomic output race"];
    End[]; EndPackage[]; Exit[98]];
  Print["CF300_EXACT_QEPS_WITNESS status=", status,
    " output=", outputFile];
  End[]; EndPackage[]; Exit[code]
];

readInDedicatedContext[file_String, context_String] := Block[
  {$Context = context, $ContextPath = {context, "System`"}},
  Quiet[CheckAbort[Get[file], $Aborted]]
];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>
];

imageByID[result_Association, imageID_String] := Module[{matches},
  matches = Select[Lookup[result, "ImageResults", {}],
    AssociationQ[#1] && Lookup[#1, "ImageID", None] === imageID &];
  If[Length[matches] === 1, First[matches], $Failed]
];
requirementsFromFrozen[result_Association] := Module[
  {images, anchor, fullRanks, coefficients, augmented, scores,
   scoreBug},
  images = Lookup[result, "ImageResults", $Failed];
  anchor = imageByID[result, "I00"];
  fullRanks = If[ListQ[images], Lookup[images, "FullRank", $Failed],
    $Failed];
  coefficients = If[ListQ[fullRanks],
    Lookup[fullRanks, "CoefficientCertificate", $Failed], $Failed];
  augmented = If[ListQ[fullRanks],
    Lookup[fullRanks, "AugmentedCertificate", $Failed], $Failed];
  scores = If[ListQ[images], Lookup[images,
    "AppendedOrbitColumnWitnessScore", $Failed], $Failed];
  If[! MatchQ[images, {_Association, _Association, _Association,
        _Association}] || anchor === $Failed ||
      ! AllTrue[coefficients, AssociationQ] ||
      ! AllTrue[augmented, AssociationQ] ||
      ! AllTrue[scores, AssociationQ], Return[$Failed]];
  scoreBug = AllTrue[scores, Function[score,
    Lookup[score, "CandidateMatrixDimensions", {0, 0}][[2]] === 288 &&
    Lookup[score, "NonzeroScoreCount", -1] === 289 &&
    Lookup[score, "NonzeroScoreColumns", {}] === Range[0, 288]]];
  If[Lookup[result, "MaximalAssemblyFingerprint", None] =!=
        "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7" ||
      Lookup[result, "PointCount", None] =!= 30 ||
      Lookup[anchor, "AcceptedPointsFingerprint", None] =!=
        "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50" ||
      ! AllTrue[coefficients,
        Lookup[#1, "PivotFingerprint", None] ===
            "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377" &&
          Lookup[#1, "FreeColumnFingerprint", None] ===
            "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534" &&
          Lookup[#1, "RowWitnessFingerprint", None] ===
            "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914" &] ||
      ! AllTrue[augmented,
        Lookup[#1, "PivotFingerprint", None] ===
            "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761" &&
          Lookup[#1, "FreeColumnFingerprint", None] ===
            "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534" &&
          Lookup[#1, "RowWitnessFingerprint", None] ===
            "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7" &],
    Return[$Failed]];
  <|"Status" -> "CF300V6dExactLiftRequirementsV1",
    "SourceV6dArtifactSHA256" -> expectedV6dSHA256,
    "OrbitCoreV6dSHA256" -> expectedOrbitCoreSHA256,
    "MaximalAssemblyFingerprint" ->
      "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7",
    "MatrixDimensions" -> {960, 912},
    "CoefficientRank" -> 888, "AugmentedRank" -> 889,
    "AnchorImageID" -> "I00", "AnchorPrime" -> 10007,
    "AnchorEpsilonValue" -> 1/21, "PointCount" -> 30,
    "AnchorAcceptedPointsFingerprint" ->
      "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50",
    "CoefficientPivotFingerprint" ->
      "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377",
    "CoefficientFreeFingerprint" ->
      "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534",
    "CoefficientIndependentRowFingerprint" ->
      "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914",
    "AugmentedPivotFingerprint" ->
      "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761",
    "AugmentedFreeFingerprint" ->
      "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534",
    "AugmentedIndependentRowFingerprint" ->
      "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7",
    "CrossImagePlanFingerprintStable" -> True,
    "V6dScorePositionHeadTraversalBugDetected" -> scoreBug,
    "V6dPersistedAcceptedPointValues" ->
      KeyExistsQ[anchor, "AcceptedPoints"],
    "V6dPersistedPivotAndRowArrays" -> And @@ {
      KeyExistsQ[First[coefficients], "PivotColumns"],
      KeyExistsQ[First[coefficients], "FreeColumns"],
      KeyExistsQ[First[coefficients], "IndependentEquationRows"],
      KeyExistsQ[First[augmented], "PivotColumns"],
      KeyExistsQ[First[augmented], "FreeColumns"],
      KeyExistsQ[First[augmented], "IndependentEquationRows"]}|>
];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[v6dArtifactFile] ||
    FileHash[v6dArtifactFile, "SHA256", "HexString"] =!=
      expectedV6dSHA256 ||
    ! DirectoryQ[DirectoryName[outputFile]] || FileExistsQ[outputFile] ||
    fileHashes[] =!= expectedHashes,
  Print["CF300_EXACT_QEPS_WITNESS FAIL invalid or unpinned inputs"];
  End[]; EndPackage[]; Exit[65]];

driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = fileHashes[];
v6dResult = readInDedicatedContext[v6dArtifactFile,
  "CodexCF300ExactQepsFrozenV6dArtifactV1`"];
If[! AssociationQ[v6dResult] ||
    Lookup[v6dResult, "Status", None] =!=
      "CF300Sector12GaloisOrbitForcingScreenPassedV6d",
  finish["CF300ExactQepsWitnessFrozenV6dReadFailedV1", <|
    "V6dArtifactSHA256" -> expectedV6dSHA256|>, 66]];

(* Requirement extraction is local and read-only.  In particular, the
   current frozen V6d artifact can reach the capture-required result without
   loading FACET or starting any plan discovery. *)
requirements = requirementsFromFrozen[v6dResult];
If[! AssociationQ[requirements] || Lookup[requirements, "Status", None] =!=
      "CF300V6dExactLiftRequirementsV1",
  finish["CF300ExactQepsWitnessRequirementExtractionFailedV1", <|
    "RequirementResult" -> requirements|>, 68]];

If[prerequisiteFile === None || ! FileExistsQ[prerequisiteFile],
  finish["CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1", <|
    "Conclusion" ->
      "The frozen V6d result stores only fingerprints, not the 30 point values or pivot/free/independent-row arrays. Exact lifting is intentionally not started.",
    "Requirements" -> requirements,
    "RequiredCaptureStatus" ->
      "CF300V6dExactLiftPrerequisiteV1",
    "RequiredCaptureFields" -> {
      "SourceV6dArtifactSHA256", "MaximalAssemblyFingerprint",
      "MaximalAssembly", "AnchorAcceptedPointResidues",
      "ExactRationalPointLifts", "PointLiftCertificate",
      "AnchorPlanRevalidation", "StablePlan"},
    "StablePlanRequiredFields" -> {
      "CoefficientPivotColumns", "CoefficientFreeColumns",
      "CoefficientIndependentEquationRows",
      "AugmentedPivotColumns", "AugmentedFreeColumns",
      "AugmentedIndependentEquationRows"},
    "PlanDiscoveryForbiddenInThisDriver" -> True,
    "AnchorImageID" -> "I00",
    "AnchorPointInterpretation" ->
      "The exact points are deterministic minimum-height balanced rational lifts of the recovered I00 residues; every coordinate must reduce back modulo 10007 and preserve the original V6d order.",
    "V6dScoreMetadataExcludedFromPlan" -> True,
    "V6dScoreBug" ->
      "The recorded 288-column score lists indices 0..288; this driver never consumes it and uses Pick on explicit 1-based ranges.",
    "V6dArtifactFile" -> v6dArtifactFile,
    "V6dArtifactSHA256" -> expectedV6dSHA256,
    "OrbitCoreV6dSHA256" -> expectedOrbitCoreSHA256,
    "DriverSHA256" -> driverHashBefore,
    "SourceHashes" -> sourceHashesBefore|>, 78]];

(* Only a present captured prerequisite authorizes the heavy runtime load.
   The exact driver still never discovers a plan. *)
loadOutcomes = AssociationMap[loadSource[files[#1]] &,
  {"LoadFACET", "TripleRootAlgebra", "TripleRootStripAdapter",
   "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
   "Assembler", "ExactWitnessHelper", "ModularReconstruction"}];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &],
  finish["CF300ExactQepsWitnessPinnedSourceLoadFailedV1", <|
    "LoadOutcomes" -> loadOutcomes|>, 67]];
helperRequirements =
  CodexCF300ExactQepsLeftObstruction`EQWRequirementsFromV6d[v6dResult];
If[helperRequirements =!= requirements,
  finish["CF300ExactQepsWitnessIndependentRequirementMismatchV1", <|
    "LocalRequirements" -> requirements,
    "HelperRequirements" -> helperRequirements|>, 68]];

prerequisiteHashBefore = FileHash[prerequisiteFile,
  "SHA256", "HexString"];
prerequisite = readInDedicatedContext[prerequisiteFile,
  "CodexCF300ExactQepsPrerequisiteArtifactV1`"];
If[! AssociationQ[prerequisite] ||
    ! TrueQ[CodexCF300ExactQepsLeftObstruction`EQWPrerequisiteValidQ[
      prerequisite, requirements]],
  finish["CF300ExactQepsWitnessPrerequisiteRejectedV1", <|
    "PrerequisiteFile" -> prerequisiteFile,
    "PrerequisiteSHA256" -> prerequisiteHashBefore,
    "Requirements" -> requirements,
    "PlanDiscoveryForbiddenInThisDriver" -> True|>, 79]];

assembly = prerequisite["MaximalAssembly"];
points = prerequisite["ExactRationalPointLifts"];
plan = prerequisite["StablePlan"];
epsilon = assembly["Regulator"];
reconstruction =
  CodexCF300ModularQepsWitnessReconstruction`EQMRReconstruct[
    assembly, epsilon, points, plan, files["NativeFixedSquareBinary"],
    "NativeThreads" -> 4,
    "FiniteFieldSourceFile" -> files["FiniteFieldStripSolve"]];
If[Lookup[reconstruction, "Status", None] =!=
    "ReconstructedCF300ExactQepsWitnessSupportV1",
  finish["CF300ExactQepsWitnessModularReconstructionFailedV1", <|
    "ReconstructionResult" -> KeyDrop[reconstruction,
      "ReconstructedSupportFunctions"]|>, 80]];
exactSample =
  CodexCF300ExactQepsLeftObstruction`EQWAssembleExactSample[
    assembly, epsilon, points];
If[Lookup[exactSample, "Status", None] =!=
    "AssembledCF300ExactQepsSampleV1",
  finish["CF300ExactQepsWitnessSampleAssemblyFailedV1", <|
    "SampleResult" -> KeyDrop[exactSample, {"Matrix",
      "RightHandSide"}]|>, 80]];

certificate = CodexCF300ExactQepsLeftObstruction`EQWConstruct[
  exactSample["Matrix"], exactSample["RightHandSide"], epsilon, plan,
  reconstruction];
If[Lookup[certificate, "Status", None] =!=
    "CertifiedCF300ExactQepsLeftObstructionV1",
  finish["CF300ExactQepsWitnessConstructionFailedV1", <|
    "CertificateResult" -> KeyDrop[certificate, "Witness"]|>, 81]];

If[fileHashes[] =!= sourceHashesBefore ||
    FileHash[v6dArtifactFile, "SHA256", "HexString"] =!=
      expectedV6dSHA256 ||
    FileHash[prerequisiteFile, "SHA256", "HexString"] =!=
      prerequisiteHashBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!=
      driverHashBefore,
  finish["CF300ExactQepsWitnessInputChangedDuringRunV1", <||>, 95]];

finish["CF300Sector12ExactQepsLeftObstructionCertifiedV1", <|
  "Field" -> "Q(eps)",
  "V6dArtifactFile" -> v6dArtifactFile,
  "V6dArtifactSHA256" -> expectedV6dSHA256,
  "OrbitCoreV6dSHA256" -> expectedOrbitCoreSHA256,
  "PrerequisiteFile" -> prerequisiteFile,
  "PrerequisiteSHA256" -> prerequisiteHashBefore,
  "Requirements" -> requirements,
  "ModularReconstructionSummary" -> KeyDrop[reconstruction,
    "ReconstructedSupportFunctions"],
  "ExactSampleSummary" -> KeyDrop[exactSample,
    {"Matrix", "RightHandSide"}],
  "Certificate" -> certificate,
  "PlanDiscoveryPerformed" -> False,
  "DriverSHA256" -> driverHashBefore,
  "SourceHashes" -> sourceHashesBefore|>, 0];

End[];
EndPackage[];
