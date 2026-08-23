#!/usr/bin/env wolframscript
(* Post-integration adversarial gate for backend semantics and the sealed M1
   plan.  This driver is deliberately serial and launches no subkernels. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
defaultRoot = ParentDirectory[ParentDirectory[ParentDirectory[
  DirectoryName[ExpandFileName[$InputFileName]]]]];
root = If[Length[arguments] >= 1, ExpandFileName[arguments[[1]]],
  defaultRoot];
resultFile = If[Length[arguments] >= 2,
  ExpandFileName[arguments[[2]]], None];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
checks = <||>;
putResult[value_, file_String] := Module[{temporary = file <> ".tmp"},
  Put[value, temporary]; RenameFile[temporary, file,
    OverwriteTarget -> True]];

decision = FeynFacet`Private`finiteFieldStripBackendDecision;
planDecision =
  FeynFacet`Private`finiteFieldStripPlanDiscoveryBackendDecision;
checks["UnknownBackendRejected"] =
  decision["TypoBackend", 1, 600]["Status"] ===
    "InvalidBackendOption";
checks["NonStringBackendRejected"] =
  decision[17, 1, 600]["Status"] === "InvalidBackendOption";
checks["BadThreadCountsRejected"] = And @@
  (decision[Automatic, #, 600]["Status"] ===
      "InvalidBackendThreads" & /@ {0, 5, 1.5, "2"});
checks["WolframNeverRequestsNative"] =
  decision["Wolfram", 4, 1000]["Status"] === "OK" &&
  decision["Wolfram", 4, 1000]["UseBackend"] === "Wolfram" &&
  ! TrueQ[decision["Wolfram", 4, 1000]["FallbackAllowed"]];
checks["ExplicitFLINTNeverAllowsFallback"] =
  ! TrueQ[Lookup[decision["FLINT", 2, 600],
    "FallbackAllowed", True]] &&
  Lookup[decision["FLINT", 2, 600], "UseBackend", None] =!=
    "Wolfram";
checks["PlanDiscoveryWolframRecordedSeparately"] =
  planDecision["Wolfram"] === <|"Status" -> "OK",
    "PlanDiscoveryBackendRequested" -> "Wolfram",
    "PlanDiscoveryBackendUsed" -> "Wolfram"|>;
checks["NativeAffineRREFNotSmuggledThroughFixedCore"] =
  planDecision["FLINTAffineRREF"]["Status"] ===
    "PlanDiscoveryBackendUnavailable" &&
  decision["FLINT", 2, 600]["UseBackend"] =!= "FLINTAffineRREF";
checks["UnknownPlanDiscoveryBackendRejected"] =
  planDecision["TypoDiscovery"]["Status"] ===
    "InvalidPlanDiscoveryBackendOption";

coreFixture = IdentityMatrix[2];
rhsFixture = {{3}, {7}};
canonicalSolution = rhsFixture;
noncanonicalSolution = {{3 + 1000003}, {7}};
checks["CanonicalNativeResiduesAccepted"] =
  FeynFacet`Private`finiteFieldStripCoreSolutionQ[
    coreFixture, rhsFixture, canonicalSolution, 1000003];
checks["CongruentButNoncanonicalNativeResiduesRejected"] =
  ! FeynFacet`Private`finiteFieldStripCoreSolutionQ[
    coreFixture, rhsFixture, noncanonicalSolution, 1000003];

wolframBackendConfiguration =
  FeynFacet`Private`finiteFieldStripBackendConfiguration["Wolfram", 2];
otherBackendConfiguration = Join[wolframBackendConfiguration,
  <|"BackendRequested" -> "FLINT"|>];
artifactFixture = <|"RecordFingerprint" -> "record-fixture",
  "SelectedNumeratorDegreeOffset" -> {0, 0},
  "SelectedSupportShell" -> 0,
  "EliminationPlanFingerprint" -> "plan-fixture",
  "BackendConfiguration" -> wolframBackendConfiguration,
  "PlanDiscoveryBackend" -> "Wolfram"|>;
artifactValid =
  FeynFacet`Private`finiteFieldStripModularArtifactValidQ;
checks["FullyBoundModularArtifactAccepted"] = artifactValid[
  artifactFixture, "record-fixture", {0, 0}, 0, "plan-fixture",
  wolframBackendConfiguration, "Wolfram"];
checks["LegacyUnboundModularArtifactIsStale"] = ! artifactValid[
  KeyDrop[artifactFixture,
    {"EliminationPlanFingerprint", "BackendConfiguration"}],
  "record-fixture", {0, 0}, 0, "plan-fixture",
  wolframBackendConfiguration, "Wolfram"];
checks["WolframCacheRejectedForDifferentFixedCoreRequest"] =
  ! artifactValid[artifactFixture, "record-fixture", {0, 0}, 0,
    "plan-fixture", otherBackendConfiguration, "Wolfram"];
checks["CacheRejectedForChangedPlanFingerprint"] =
  ! artifactValid[artifactFixture, "record-fixture", {0, 0}, 0,
    "another-plan", wolframBackendConfiguration, "Wolfram"];

basePlan = <|"Status" -> "OK", "NormalizationColumns" -> {4},
  "IndependentEquationRows" -> {1, 2, 3}, "GenericRank" -> 3,
  "Nullity" -> 1, "UnknownCount" -> 4, "GaugeUnknownCount" -> 3,
  "FreeResidueCount" -> 1, "GaugeNumeratorDegrees" -> {1, 0},
  "GaugeDenominatorDegrees" -> {0, 0},
  "GaugeSupport" -> {{0, 0}, {1, 0}, {0, 1}},
  "PilotPrime" -> 1000003|>;
sealed = FeynFacet`Private`finiteFieldStripSealEliminationPlan[
  basePlan, "prep-fixture"];
validate[plan_] :=
  FeynFacet`Private`finiteFieldStripValidateEliminationPlan[plan,
    {6, 4}, 3, 1, {1, 0}, {0, 0},
    {{0, 0}, {1, 0}, {0, 1}}, "prep-fixture"]["Status"];
reseal[plan_] :=
  FeynFacet`Private`finiteFieldStripSealEliminationPlan[
    KeyDrop[plan, {"PlanFingerprint", "PlanSchema", "PlanSchemaVersion",
      "PreparationFingerprint", "SolverProvenance"}], "prep-fixture"];
checks["SealedPlanAccepted"] = validate[sealed] === "OK";
checks["PlanHasExactVersionedSchema"] =
  sealed["PlanSchema"] ===
      "FeynFacetFiniteFieldStripEliminationPlan" &&
    sealed["PlanSchemaVersion"] === 1 &&
    StringLength[sealed["PlanFingerprint"]] === 64;
checks["ExtraKeyRejected"] =
  validate[Join[sealed, <|"Injected" -> 1|>]] ===
    "PlanSchemaKeysMismatch";
checks["MissingKeyRejected"] =
  validate[KeyDrop[sealed, "PilotPrime"]] === "PlanSchemaKeysMismatch";
checks["VersionMutationRejected"] =
  validate[Join[sealed, <|"PlanSchemaVersion" -> 2|>]] ===
    "PlanSchemaVersionMismatch";
checks["FingerprintMutationRejected"] =
  validate[Join[sealed, <|"PlanFingerprint" ->
    StringRepeat["0", 64]|>]] === "PlanFingerprintMismatch";
checks["PreparationMutationRejected"] =
  FeynFacet`Private`finiteFieldStripValidateEliminationPlan[sealed,
    {6, 4}, 3, 1, {1, 0}, {0, 0},
    {{0, 0}, {1, 0}, {0, 1}}, "another-preparation"]["Status"] ===
      "PlanPreparationFingerprintMismatch";
checks["ProvenanceMutationRejected"] = validate[Join[sealed,
  <|"SolverProvenance" -> Join[sealed["SolverProvenance"],
    <|"ImplementationVersion" -> 99|>]|>]] ===
      "PlanSolverProvenanceMismatch";
checks["DuplicateRowsRejectedAfterValidReseal"] =
  validate[reseal[Join[sealed,
    <|"IndependentEquationRows" -> {1, 1, 3}|>]]] ===
      "PlanEquationRowsInvalid";
checks["OutOfRangeRowsRejectedAfterValidReseal"] =
  validate[reseal[Join[sealed,
    <|"IndependentEquationRows" -> {1, 2, 7}|>]]] ===
      "PlanEquationRowsInvalid";
checks["DuplicateNormalizationRejectedAfterValidReseal"] =
  validate[reseal[Join[sealed, <|"NormalizationColumns" -> {4, 4},
    "Nullity" -> 2, "GenericRank" -> 2,
    "IndependentEquationRows" -> {1, 2}|>]]] ===
      "PlanNormalizationColumnsInvalid";
checks["SupportMutationRejectedAfterValidReseal"] =
  validate[reseal[Join[sealed,
    <|"GaugeSupport" -> {{0, 0}, {1, 0}, {1, 1}}|>]]] ===
      "PlanAnsatzMismatch";

(* A core just above the Automatic threshold exercises the real Sample API.
   The native adapter is replaced only inside Internal`InheritedBlock so the
   two failure policies see the same prepared rows and sealed plan. *)
Clear[xBackend, yBackend, epsBackend];
record = <|"Variables" -> {xBackend, yBackend},
  "Regulator" -> epsBackend,
  "Strip" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}},
    {{{1 - epsBackend xBackend}}, {{0}}}}|>;
preparation = FeynFacet`PrepareEpsFormStripSampling[record];
largeSupport = Take[Flatten[Table[{i, j}, {i, 0, 31},
  {j, 0, 31}], 1], 256];
common = {"Support" -> largeSupport, "PointCount" -> Automatic,
  "NumeratorDegreeOffset" -> {0, 0}, "Preparation" -> preparation,
  "ExpectedFingerprint" -> preparation["Fingerprint"],
  "RandomSeed" -> 731991};
pilot = FeynFacet`SampleEpsFormStripAffine[record, 1/21, 1000003,
  "Backend" -> "Wolfram", "DiscoverPlan" -> True,
  Sequence @@ common];
physicalPlan = If[AssociationQ[pilot],
  Lookup[pilot, "EliminationPlan", None], None];
checks["PhysicalPlanSealed"] = AssociationQ[physicalPlan] &&
  physicalPlan["Status"] === "OK" &&
  physicalPlan["PlanSchemaVersion"] === 1;

If[TrueQ[checks["PhysicalPlanSealed"]],
  Internal`InheritedBlock[{
      FeynFacet`Private`finiteFieldStripFLINTBinary,
      FeynFacet`Private`finiteFieldStripFLINTSolve},
    Clear[FeynFacet`Private`finiteFieldStripFLINTBinary,
      FeynFacet`Private`finiteFieldStripFLINTSolve];
    FeynFacet`Private`finiteFieldStripFLINTBinary[] :=
      "/simulated/flint_modular_solve";
    FeynFacet`Private`finiteFieldStripFLINTSolve[___] := $Failed;
    automaticFailure = FeynFacet`SampleEpsFormStripAffine[
      record, 2/23, 1000003, "Backend" -> Automatic,
      "EliminationPlan" -> physicalPlan, Sequence @@ common];
    explicitFailure = FeynFacet`SampleEpsFormStripAffine[
      record, 2/23, 1000003, "Backend" -> "FLINT",
      "EliminationPlan" -> physicalPlan, Sequence @@ common];
    invalidExplicit = FeynFacet`SampleEpsFormStripAffine[
      record, 2/23, 1000003, "Backend" -> "FLINT",
      "EliminationPlan" -> Join[physicalPlan,
        <|"PlanFingerprint" -> StringRepeat["0", 64]|>],
      Sequence @@ common]];
  checks["AutomaticNativeFailureFallsBackAndRecords"] =
    AssociationQ[automaticFailure] &&
    automaticFailure["BackendUsed"] === "Wolfram" &&
    automaticFailure["BackendFallbackReason"] ===
      "FLINTExecutionFailed" &&
    TrueQ[automaticFailure["Consistent"]];
  checks["ExplicitNativeFailureFailsClosed"] =
    AssociationQ[explicitFailure] &&
    explicitFailure["Status"] === "DiscardBackendFailure" &&
    explicitFailure["BackendUsed"] === None &&
    explicitFailure["BackendFailure"] === "FLINTExecutionFailed";
  checks["ExplicitNativeInvalidPlanNeverFallsBack"] =
    AssociationQ[invalidExplicit] &&
    invalidExplicit["Status"] === "DiscardBackendFailure" &&
    invalidExplicit["BackendUsed"] === None &&
    invalidExplicit["BackendFailure"] ===
      "FLINTRequiresValidatedEliminationPlan",
  checks["AutomaticNativeFailureFallsBackAndRecords"] = False;
  checks["ExplicitNativeFailureFailsClosed"] = False;
  checks["ExplicitNativeInvalidPlanNeverFallsBack"] = False];

result = <|"Status" -> If[And @@ Values[checks], "OK", "Failed"],
  "Purpose" -> "FiniteFieldBackendPlanAndCacheAdversarialV2",
  "Checks" -> checks,
  "SourceHashes" -> Association@Table[file ->
    FileHash[FileNameJoin[{root, file}], "SHA256", "HexString"],
    {file, {"FeynFacet/Private/FiniteFieldStripSolve.wl"}}]|>;
If[StringQ[resultFile], putResult[result, resultFile]];
Print["FINITE_FIELD_BACKEND_PLAN status=", result["Status"],
  " checks=", Count[Values[checks], True], "/", Length[checks]];
If[result["Status"] =!= "OK", Print[InputForm[result]]];
Exit[If[result["Status"] === "OK", 0, 1]];
