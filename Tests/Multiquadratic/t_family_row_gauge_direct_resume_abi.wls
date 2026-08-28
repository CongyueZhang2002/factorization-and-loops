#!/usr/bin/env wolframscript
(* The installed direct-multiquadratic route is resumable only when its
   complete implementation, policy and bundle-derived alphabet ABI are
   sealed.  The forcing fixture has rational factors, Galois-orbit norms and
   algebraic factors that exist only in the deferred bundle; its materialized
   BBar is a zero placeholder.  The expensive solver body is inherited-
   blocked while every resume identity/configuration/artifact/gauge/form gate
   remains real. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps, v, w];
variables = {x, y};
frame = <|"Name" -> "DirectResumeRank1", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Multiquadratic", "Variables" -> variables,
  "Subst" -> {v -> x, w -> y},
  "Roots" -> {<|"Root" -> Sqrt[1 + x],
    "RootSquare" -> 1 + v|>}|>;
driverPath = FileNameJoin[{root, "Scripts", "family_epsform_sector.wls"}];
driver = <|"family_epsform_sector.wls" -> driverPath|>;
driverSource = Import[driverPath, "Text"];

FTTest`FTAssert["driver separates helper kernels from direct native threads",
  StringContainsQ[driverSource, "FACET_MQ_NATIVE_THREADS"] &&
    StringContainsQ[driverSource, "FACET_MQ_IMAGE_KERNEL_COUNT"] &&
    StringContainsQ[driverSource,
      "PlanDiscoveryBackendThreads\" -> mqNativeThreads"] &&
    StringContainsQ[driverSource,
      "RegulatorReconstructionImageKernelCount\" ->"] &&
    StringContainsQ[driverSource,
      "LaunchKernels[kernelCount - Length[Kernels[]]]"] &&
    ! StringContainsQ[driverSource, "LaunchKernels[mqNativeThreads"]];
FTTest`FTAssert["driver retains the kernel-count fallback for native threads",
  StringContainsQ[driverSource, "Return[kernelCount]"]];
FTTest`FTAssert["driver checkpoints compact adaptive-prime telemetry",
  StringContainsQ[driverSource,
    "\"RegulatorReconstruction\" -> Join["] &&
    StringContainsQ[driverSource, "\"LiftAttemptHistory\""] &&
    StringContainsQ[driverSource,
      "KeyDrop[#1, {\"UnresolvedCoefficientLocations\"}]"] &&
    StringContainsQ[driverSource, "\"CoefficientHeight\""] &&
    StringContainsQ[driverSource, "\"ActualMinimumPrimeCount\""] &&
    StringContainsQ[driverSource, "\"PrimeCountOvershoot\""]];

(* Build the adversarial direct input before sealing its configuration.  No
   letter below can be rediscovered from placeholderStrip. *)
algebraicDivisor = 2 + x + Sqrt[1 + x];
strip = {{{{1}}, {{0}}}, {{{0}}, {{0}}},
  {{{1/(x algebraicDivisor)}},
   {{1/((1 - y) algebraicDivisor)}}}};
connection = ConstantArray[0, {2, 2, 2}];
Do[
  connection[[mu, 1, 1]] = eps strip[[2, mu, 1, 1]];
  connection[[mu, 2, 2]] = eps strip[[1, mu, 1, 1]];
  connection[[mu, 2, 1]] = strip[[3, mu, 1, 1]], {mu, 2}];
rootRecord = <|"Root" -> Sqrt[1 + x], "RootSquare" -> 1 + x|>;
bundle = FeynFacet`Private`blockEquationDeferredForcing[
  connection, {{1}, {2}}, 2, 1, <||>, variables, eps,
  "Output" -> "Bundle", "BundleRoots" -> {rootRecord}];
directAlphabetOptions =
  FeynFacet`Private`familyRowGaugeDirectAlphabetOptions[bundle];
bundleFactors = bundle["DivisorSummary", "Factors"];
expectedAlgebraicLetters = Lookup[Select[bundleFactors,
  TrueQ[Lookup[#1, "Algebraic", False]] &], "Factor", {}];
expectedAdditionalLetters = DeleteDuplicates[Join[
  Lookup[Select[bundleFactors,
    ! TrueQ[Lookup[#1, "Algebraic", False]] &], "Factor", {}],
  Lookup[bundle["DivisorSummary", "GaloisOrbits"], "Norm", {}]]];

FTTest`FTAssert["bundle-only rational, norm and algebraic letters are resolved",
  Lookup[FeynFacet`Private`blockEquationDeferredBundleValidate[bundle],
      "Status", None] === "BundleValid" &&
    expectedAlgebraicLetters =!= {} &&
    Lookup[bundle["DivisorSummary", "GaloisOrbits"], "Norm", {}] =!= {} &&
    directAlphabetOptions === <|
      "AdditionalLetters" -> expectedAdditionalLetters,
      "AlgebraicLetters" -> expectedAlgebraicLetters|>];

configuration = FeynFacet`Private`familyRowGaugeSolverConfiguration[
  "DirectMultiquadraticFiniteField", "Multiquadratic", frame,
  "Numerical", Automatic, 2, Automatic,
  "PlanDiscoveryBackendThreads" -> 8,
  "DriverProvenance" -> driver,
  "DirectAlphabetOptions" -> directAlphabetOptions];
defaults = FeynFacet`Private`familyRowGaugeDirectPolicyDefaults[];

FTTest`FTAssert["direct installed route has a valid schema-v5 configuration",
  AssociationQ[configuration] && configuration["Status"] === "OK" &&
    configuration["SchemaVersion"] === 5 &&
    configuration["Route"] === "DirectMultiquadraticFiniteField" &&
    configuration["CoefficientField"] === "Multiquadratic" &&
    FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      configuration]];

FTTest`FTAssert["direct configuration explicitly binds every promoted policy",
  configuration["ProviderKind"] === defaults["ProviderKind"] &&
    And @@ (configuration[#] === defaults[#] & /@
      {"BundleABIPolicy", "ProviderABIPolicy", "LayoutABIPolicy",
       "ReconstructionPolicy", "FreshValidationPolicy"}) &&
    configuration["DirectAlphabetOptions"] === directAlphabetOptions];

FTTest`FTAssert["direct configuration seals Automatic native discovery and eight threads",
  configuration["PlanDiscoveryBackend"] === Automatic &&
    configuration["PlanDiscoveryBackendThreads"] === 8];

defaultThreadConfiguration =
  FeynFacet`Private`familyRowGaugeSolverConfiguration[
    "DirectMultiquadraticFiniteField", "Multiquadratic", frame,
    "Numerical", Automatic, 2, Automatic,
    "DriverProvenance" -> driver,
    "DirectAlphabetOptions" -> directAlphabetOptions];
FTTest`FTAssert["configuration API defaults native threads to its existing backend count",
  defaultThreadConfiguration["Status"] === "OK" &&
    defaultThreadConfiguration["PlanDiscoveryBackendThreads"] === 2];
FTTest`FTAssert["direct native thread count is bounded from one through eight",
  And @@ (FeynFacet`Private`familyRowGaugeSolverConfiguration[
        "DirectMultiquadraticFiniteField", "Multiquadratic", frame,
        "Numerical", Automatic, 2, Automatic,
        "PlanDiscoveryBackendThreads" -> #,
        "DriverProvenance" -> driver,
        "DirectAlphabetOptions" -> directAlphabetOptions]["Status"] ===
      "InvalidSolverConfigurationArguments" & /@ {0, 9})];

requiredSources = {"MultiquadraticStripSolve.wl",
  "MultiquadraticAlgebra.wl", "MultiquadraticInstallation.wl",
  "BlockEquationDeferred.wl", "FiniteFieldStripSolve.wl",
  "TransportCharts.wl", "FamilyRowGauge.wl",
  "FamilyRowGaugeResume.wl"};
provenance = configuration["ImplementationProvenance"];
FTTest`FTAssert["direct provenance hashes the full implementation and driver",
  ContainsAll[Keys[provenance["SourceSHA256"]], requiredSources] &&
    AllTrue[Lookup[provenance["SourceSHA256"], requiredSources],
      StringQ[#] && StringLength[#] === 64 &] &&
    provenance["DriverProvenance", "family_epsform_sector.wls", "Path"] ===
      driverPath &&
    provenance["DriverProvenance", "family_epsform_sector.wls", "SHA256"] ===
      FileHash[driverPath, "SHA256", "HexString"]];

FTTest`FTAssert["direct route refuses the rational coefficient field",
  FeynFacet`Private`familyRowGaugeSolverConfiguration[
    "DirectMultiquadraticFiniteField", "Rational", <||>, "Numerical",
    Automatic, 2, Automatic,
    "PlanDiscoveryBackendThreads" -> 8]["Status"] ===
      "InconsistentSolverConfigurationRoute"];

(* Existing routes acquire None-valued direct-policy fields and stay valid. *)
zeroConfiguration = FeynFacet`Private`familyRowGaugeSolverConfiguration[
  "ZeroForcing", "Rational", <||>, None, None, None, None];
rationalConfiguration =
  FeynFacet`Private`familyRowGaugeSolverConfiguration[
    "DirectRationalFiniteField", "Rational", <||>, "Exact", Automatic,
    2, "Wolfram"];
FTTest`FTAssert["existing zero and rational routes remain valid",
  FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      zeroConfiguration] &&
    FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      rationalConfiguration] &&
    Lookup[zeroConfiguration,
      {"ProviderKind", "BundleABIPolicy", "ProviderABIPolicy",
       "LayoutABIPolicy", "ReconstructionPolicy",
       "FreshValidationPolicy", "DirectAlphabetOptions"}] ===
      ConstantArray[None, 7]];

FTTest`FTAssert["non-direct configurations carry no native discovery threads",
  zeroConfiguration["PlanDiscoveryBackendThreads"] === None &&
    rationalConfiguration["PlanDiscoveryBackendThreads"] === None &&
    rationalConfiguration["PlanDiscoveryBackend"] === "Wolfram"];

refingerprint[candidate_Association] := Module[{payload},
  payload = KeyDrop[candidate, "Fingerprint"];
  Append[payload, "Fingerprint" -> Hash[KeySort[payload],
    "SHA256", "HexString"]]
];

alphabetMutantUnsealed = configuration;
alphabetMutantUnsealed["DirectAlphabetOptions", "AdditionalLetters"] =
  Append[alphabetMutantUnsealed[
    "DirectAlphabetOptions", "AdditionalLetters"], 1 + x + y];
alphabetMutant = refingerprint[alphabetMutantUnsealed];
alphabetCheck =
  FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
    <|"Method" -> "DirectMultiquadraticFiniteField",
      "SolverConfiguration" -> alphabetMutant|>, configuration];
FTTest`FTAssert["alphabet mutation is fingerprinted and config-mismatched",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      alphabetMutantUnsealed] &&
    FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      alphabetMutant] &&
    Lookup[alphabetCheck, "Status", None] ===
      "ResumeSolverConfigurationMismatch" &&
    MemberQ[Lookup[alphabetCheck, "DifferingKeys", {}],
      "DirectAlphabetOptions"]];

policyMutant = configuration;
policyMutant["FreshValidationPolicy"] =
  Append[policyMutant["FreshValidationPolicy"],
    "MinimumUnseenPrimes" -> 3];
policyMutant = refingerprint[policyMutant];
policyCheck = FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
  <|"Method" -> "DirectMultiquadraticFiniteField",
    "SolverConfiguration" -> policyMutant|>, configuration];
FTTest`FTAssert["a refingerprinted stale validation policy is refused",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[policyMutant] &&
    Lookup[policyCheck, "Status", None] ===
      "ResumeSolverConfigurationMismatch" &&
    MemberQ[Lookup[policyCheck, "DifferingKeys", {}],
      "FreshValidationPolicy"]];

threadMutant = refingerprint[Append[configuration,
  "PlanDiscoveryBackendThreads" -> 7]];
threadCheck = FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
  <|"Method" -> "DirectMultiquadraticFiniteField",
    "SolverConfiguration" -> threadMutant|>, configuration];
FTTest`FTAssert["a changed native thread count is sealed and refused on resume",
  FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[threadMutant] &&
    Lookup[threadCheck, "Status", None] ===
      "ResumeSolverConfigurationMismatch" &&
    MemberQ[Lookup[threadCheck, "DifferingKeys", {}],
      "PlanDiscoveryBackendThreads"]];

wolframMutant = refingerprint[Append[configuration,
  "PlanDiscoveryBackend" -> "Wolfram"]];
wolframCheck = FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
  <|"Method" -> "DirectMultiquadraticFiniteField",
    "SolverConfiguration" -> wolframMutant|>, configuration];
FTTest`FTAssert["direct hydration cannot switch Automatic discovery to Wolfram",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      wolframMutant] &&
    Lookup[wolframCheck, "Status", None] ===
      "ResumeSolverConfigurationMismatch" &&
    MemberQ[Lookup[wolframCheck, "DifferingKeys", {}],
      "PlanDiscoveryBackend"]];

sourceMutant = configuration;
sourceMutant["ImplementationProvenance", "SourceSHA256",
  "MultiquadraticInstallation.wl"] = StringRepeat["0", 64];
sourceMutant = refingerprint[sourceMutant];
sourceCheck = FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
  <|"Method" -> "DirectMultiquadraticFiniteField",
    "SolverConfiguration" -> sourceMutant|>, configuration];
FTTest`FTAssert["a refingerprinted stale source hash is refused",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[sourceMutant] &&
    Lookup[sourceCheck, "Status", None] ===
      "ResumeSolverConfigurationMismatch" &&
    MemberQ[Lookup[sourceCheck, "DifferingKeys", {}],
      "ImplementationProvenance"]];

hex = StringRepeat["a", 64];
directSolution = <|"Status" -> "Solved",
  "Method" -> "DirectMultiquadraticFiniteField",
  "SolutionContract" -> "InstallableMultiquadraticDLogV1",
  "Gauge" -> {{0}}, "Alphabet" -> {}, "ResidueMatrices" -> {},
  "OneForms" -> {}, "RootIndices" -> {1},
  "Provider" -> "SplitBranch", "ProviderFingerprint" -> hex,
  "LayoutFingerprint" -> hex,
  "ReconstructedVectorFingerprint" -> hex,
  "Certificate" -> "NumericalResidual",
  "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
  "OneFormsCertified" -> True, "LettersEpsFree" -> True,
  "ResiduesKinematicsFree" -> True,
  "InstallationEvidence" -> <|
    "Status" -> "InstallationEvidenceAccepted",
    "Certificate" -> "NumericalResidual", "Exact" -> False,
    "ValidationPrimeCount" -> 2, "ValidationImageCount" -> 6|>|>;

FTTest`FTAssert["direct installed method has an accepted frame certificate",
  FeynFacet`Private`familyRowGaugeResumeFrameCertificateQ[directSolution,
    configuration["FreshValidationPolicy"]]];
FTTest`FTAssert["insufficient fresh evidence invalidates the direct certificate",
  ! FeynFacet`Private`familyRowGaugeResumeFrameCertificateQ[
    Append[directSolution, "InstallationEvidence" ->
      Append[directSolution["InstallationEvidence"],
        "ValidationPrimeCount" -> 1]],
    configuration["FreshValidationPolicy"]]];

(* One real hydration pass with a bounded inherited solver fixture.  The
   direct route persists a nonzero deferred forcing as an authenticated DAG
   plus a zero-shape placeholder and has no rational `_mod_*.wl` cache. *)
temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-direct-resume-abi-" <> CreateUUID[]}]];
placeholderStrip = {strip[[1]], strip[[2]],
  ConstantArray[0, Dimensions[strip[[3]]]]};
input = <|"Family" -> "CFMQRESUME", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> variables, "Regulator" -> eps,
  "Strip" -> placeholderStrip, "DeferredBundle" -> bundle|>;
inputFile = FileNameJoin[{temporary, "CFMQRESUME_2_1_input.wl"}];
FeynFacet`FamilyArtifactWrite[input, inputFile];
solvedForm = ConstantArray[0, {2, 1, 1}];
checkpoint = <|"Sector" -> 2, "SubSize" -> 1, "Truncation" -> 2,
  "PrevD" -> {{0}},
  "ConnectionHash" -> Hash[connection /. eps -> CANONICA`eps,
    "SHA256", "HexString"],
  "StripSolvers" -> {<|"Sector" -> 2, "LowerSector" -> 1,
    "Method" -> "DirectMultiquadraticFiniteField", "ExtraLetters" -> {},
    "SolverConfiguration" -> configuration|>},
  "SolvedForms" -> <|1 -> solvedForm|>|>;
checkpointFile = FileNameJoin[{temporary, "checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[checkpoint, checkpointFile];
seal = FeynFacet`Private`familyRowGaugeStripInputSeal[
  "CFMQRESUME", 2, 1, 2, checkpoint["ConnectionHash"], <|1 -> {{0}}|>,
  Hash[{placeholderStrip, bundle["BundleFingerprint"]},
    "SHA256", "HexString"],
  Hash[{variables, eps}, "SHA256", "HexString"],
  FileHash[driverPath, "SHA256", "HexString"]];
FeynFacet`FamilyArtifactWrite[seal,
  StringReplace[inputFile, "_input.wl" -> "_input_seal.wl"]];

capturedMultiquadraticOptions = Missing["SolverNotCalled"];
hydrated = Internal`InheritedBlock[{FeynFacet`SolveEpsFormStripInFrame},
  Unprotect[FeynFacet`SolveEpsFormStripInFrame];
  Clear[FeynFacet`SolveEpsFormStripInFrame];
  FeynFacet`SolveEpsFormStripInFrame[args___] := (
    capturedMultiquadraticOptions = First[
      Cases[{args}, HoldPattern[
        "MultiquadraticOptions" -> value_] :> value],
      Missing["MultiquadraticOptionsMissing"]];
    directSolution);
  Protect[FeynFacet`SolveEpsFormStripInFrame];
  FeynFacet`Private`familyRowGaugeHydrateResume[
    checkpoint, checkpointFile, <|1 -> {{0}}|>,
    checkpoint["SolvedForms"], "CFMQRESUME", 2, variables, eps, frame,
    {{1}, {2}}, temporary, connection, "KernelCount" -> 1,
    "PlanDiscoveryBackendThreads" -> 8,
    "MultiquadraticImageKernelCount" -> 2,
    "FinalCheck" -> "Numerical", "ResumeGate" -> "Exact",
    "DriverProvenance" -> driver]];

FTTest`FTAssert["direct installed method hydrates through its own route",
  Lookup[hydrated, "Status", None] === "Verified" &&
    TrueQ[Lookup[hydrated, "ActivateInstalledRow", False]] &&
    Lookup[Lookup[hydrated, "ReplayRecords", {}], "Route"] ===
      {"DirectMultiquadratic"} &&
    Lookup[Lookup[hydrated, "ReplayRecords", {}], "Method"] ===
      {"DirectMultiquadraticFiniteField"} &&
    Lookup[Lookup[hydrated, "ReplayRecords", {}],
      "SolverConfigurationFingerprint"] === {configuration["Fingerprint"]} &&
    SameQ[Lookup[hydrated, "SolvedForms", <||>],
      checkpoint["SolvedForms"]]];
capturedReplayOptions = If[ListQ[capturedMultiquadraticOptions],
  Association[capturedMultiquadraticOptions], <||>];
FTTest`FTAssert["resume replays the exact bundle-only alphabet payload",
  KeyTake[capturedReplayOptions,
      {"AdditionalLetters", "AlgebraicLetters"}] ===
    directAlphabetOptions &&
    Lookup[capturedReplayOptions,
      {"IntegrabilityScreen", "ScreenFirst", "GaugeScreen"}] ===
      {False, False, False}];
FTTest`FTAssert["one-kernel hydration preserves Automatic eight-thread native discovery",
  Lookup[capturedReplayOptions, "PlanDiscoveryBackend", None] ===
      Automatic &&
    Lookup[capturedReplayOptions, "PlanDiscoveryBackendThreads", None] ===
      8 &&
    Lookup[capturedReplayOptions,
      "RegulatorReconstructionImageKernelCount", None] === 2];
FTTest`FTAssert["direct deferred replay requires no rational prime cache",
  ! DirectoryQ[FileNameJoin[{temporary,
      "CFMQRESUME_2_1_finite_field"}]]];

(* Even a structurally valid, refingerprinted alphabet mutation is stale
   against the payload re-derived from the authenticated input bundle. *)
mutantCheckpoint = ReplacePart[checkpoint,
  {"StripSolvers", 1, "SolverConfiguration"} -> alphabetMutant];
mutantCheckpointFile = FileNameJoin[{temporary, "checkpoint_mutant.wl"}];
FeynFacet`FamilyArtifactWrite[mutantCheckpoint, mutantCheckpointFile];
mutantSolverCalls = 0;
mutantHydrated = Internal`InheritedBlock[
  {FeynFacet`SolveEpsFormStripInFrame},
  Unprotect[FeynFacet`SolveEpsFormStripInFrame];
  Clear[FeynFacet`SolveEpsFormStripInFrame];
  FeynFacet`SolveEpsFormStripInFrame[___] :=
    (mutantSolverCalls++; directSolution);
  Protect[FeynFacet`SolveEpsFormStripInFrame];
  FeynFacet`Private`familyRowGaugeHydrateResume[
    mutantCheckpoint, mutantCheckpointFile, <|1 -> {{0}}|>,
    mutantCheckpoint["SolvedForms"], "CFMQRESUME", 2, variables, eps,
    frame, {{1}, {2}}, temporary, connection, "KernelCount" -> 1,
    "PlanDiscoveryBackendThreads" -> 8,
    "FinalCheck" -> "Numerical", "ResumeGate" -> "Exact",
    "DriverProvenance" -> driver]];
FTTest`FTAssert["hydration refuses a refingerprinted alphabet mutation before solve",
  Lookup[mutantHydrated, "Status", None] ===
      "ResumeSolverConfigurationMismatch" && mutantSolverCalls === 0];

If[DirectoryQ[temporary],
  Quiet[DeleteDirectory[temporary, DeleteContents -> True]]];
FTTest`FTReport[];
