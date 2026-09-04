#!/usr/bin/env wolframscript
(* A banked row-gauge block is a mathematical result.  Resume binds the
   family, connection, exact block prefix and each block's acceptance record;
   it neither replays a solver nor interprets execution metadata. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps];
variables = {x, y};
family = "CFMQRESUME";
sector = 2;
ranges = {{1}, {2}};
connection = {
  {{eps x, 0}, {x^2, 2 eps x}},
  {{eps y, 0}, {x y, 3 eps y}}};
gauge = {{x + y}};
(* Deliberately well-shaped and stale: it must remain telemetry only. *)
form = {{{-999}}, {{-999}}};
authoritativeRow = {{{-1 + x^2 + eps x (x + y)}},
  {{-1 + x y + 2 eps y (x + y)}}};
solvedBlocks = <|1 -> gauge|>;
solvedForms = <|1 -> form|>;
frame = <|"CoefficientField" -> "Multiquadratic"|>;

directAcceptance = <|
  "Sector" -> sector, "LowerSector" -> 1,
  "Method" -> "DirectMultiquadraticFiniteField",
  "SolutionContract" -> "InstallableMultiquadraticDLogV1",
  "Certificate" -> "NumericalResidual",
  "OneFormsCertified" -> True,
  "LettersEpsFree" -> True,
  "ResiduesKinematicsFree" -> True,
  "InstallationEvidence" -> <|
    "Status" -> "InstallationEvidenceAccepted",
    "Certificate" -> "NumericalResidual",
    "ValidationPrimeCount" -> 2,
    "ValidationImageCount" -> 6|>|>;

FTTest`FTAssert["direct multiquadratic acceptance is mathematical",
  FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[
    directAcceptance]];

executionMutant = Join[directAcceptance, <|
  "SolverConfiguration" -> <|
    "Backend" -> "DifferentBackend", "Threads" -> 999,
    "PrimePolicy" -> "Different", "Cache" -> "/different/cache",
    "SourceRevision" -> "different"|>,
  "ProviderImplementation" -> "different",
  "CoefficientLayoutVersion" -> 999|>];
FTTest`FTAssert["execution metadata cannot alter block acceptance",
  FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[
      executionMutant] ===
    FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[
      directAcceptance]];

badEvidence = ReplacePart[directAcceptance,
  {"InstallationEvidence", "Status"} -> "CandidateOnly"];
FTTest`FTAssert["missing mathematical installation evidence is rejected",
  ! FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[badEvidence]];

chartAcceptance = <|
  "Sector" -> sector, "LowerSector" -> 1,
  "Method" -> "RationalChart/Kallen1/FiniteField",
  "Certificate" -> "NumericalResidual",
  "FrameCertificate" -> <|
    "CoordinateComposition" -> True,
    "GaugeRoundTrip" -> True,
    "TransformedOneFormPullBack" -> True,
    "BranchSigns" -> {1},
    "ValidationMode" -> "PostPullBackFiniteFieldResidual",
    "InnerCertificate" -> "NumericalResidual",
    "UnseenPrime" -> 1000003,
    "NumericalPfaffianResidualsZero" -> True|>|>;
FTTest`FTAssert["chart acceptance binds the pulled-back identity",
  FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[chartAcceptance]];

badChart = ReplacePart[chartAcceptance,
  {"FrameCertificate", "NumericalPfaffianResidualsZero"} -> False];
FTTest`FTAssert["a failed pulled-back identity is rejected",
  ! FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[badChart]];

checkpoint = <|
  "Family" -> family, "Sector" -> sector,
  "SubSize" -> 1, "Truncation" -> 2,
  "PrevD" -> gauge,
  "TruncatedConnectionMatrices" ->
    (connection /. eps -> CANONICA`eps),
  "StripSolvers" -> {directAcceptance},
  "SolvedForms" -> solvedForms|>;

temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-direct-resume-identity-" <> CreateUUID[]}]];
checkpointFile = FileNameJoin[{temporary, "checkpoint.wl"}];

hydrate[record_, blocks_: solvedBlocks, forms_: <||>,
    current_: connection, requestedFamily_: family, options___Rule] := Module[{},
  FeynFacet`FamilyArtifactWrite[record, checkpointFile];
  FeynFacet`Private`familyRowGaugeHydrateResume[
    record, checkpointFile, blocks, forms, requestedFamily, sector,
    variables, eps, frame, ranges, temporary, current, options]];

solverCalls = 0;
baseline = Internal`InheritedBlock[{FeynFacet`SolveEpsFormStripInFrame},
  Unprotect[FeynFacet`SolveEpsFormStripInFrame];
  Clear[FeynFacet`SolveEpsFormStripInFrame];
  FeynFacet`SolveEpsFormStripInFrame[___] := (solverCalls++; $Failed);
  Protect[FeynFacet`SolveEpsFormStripInFrame];
  hydrate[checkpoint, solvedBlocks, <||>, connection, family,
    "KernelCount" -> 8,
    "FiniteFieldBackend" -> "FLINT",
    "FiniteFieldBackendThreads" -> 8,
    "PlanDiscoveryBackend" -> "FLINTAffineRREF",
    "PlanDiscoveryBackendThreads" -> 8,
    "DriverProvenance" -> <|"Revision" -> "different"|>,
    "ResumeGate" -> "Exact",
    "Deadline" -> AbsoluteTime[] - 100]];

FTTest`FTAssert["resume trusts the accepted block without replay",
  Lookup[baseline, "Status", None] === "Verified" &&
    TrueQ[Lookup[baseline, "ExecutionSettingsIgnored", False]] &&
    solverCalls === 0];
FTTest`FTAssert["caller-side form caches are not resume identity",
  SameQ[Lookup[baseline, "SolvedForms", None], solvedForms] &&
    TrueQ[Lookup[baseline, "ActivateInstalledRow", False]] &&
    And @@ (TrueQ[Together[#1] === 0] & /@
      Flatten[baseline["InstalledRow"] - authoritativeRow]) &&
    baseline["InstalledRow"] =!= form];

mutantCheckpoint = ReplacePart[checkpoint,
  "StripSolvers" -> {executionMutant}];
mutant = hydrate[mutantCheckpoint, solvedBlocks, <|99 -> "junk"|>,
  connection, family, "KernelCount" -> 1,
  "FiniteFieldBackend" -> "AnythingElse"];
FTTest`FTAssert["checkpoint execution settings are invisible to resume",
  Lookup[mutant, "Status", None] === "Verified" &&
    SameQ[mutant["AcceptanceRecords"], baseline["AcceptanceRecords"]]];

wrongFamily = ReplacePart[checkpoint, "Family" -> "OTHER"];
FTTest`FTAssert["family identity is enforced",
  Lookup[hydrate[wrongFamily], "Status", None] ===
    "ResumeHydrationFamilyIdentityMismatch"];

wrongConnection = ReplacePart[connection, {1, 1, 1} -> 1];
FTTest`FTAssert["connection content is enforced",
  Lookup[hydrate[checkpoint, solvedBlocks, <||>, wrongConnection],
    "Status", None] === "ResumeHydrationCheckpointIdentityMismatch"];

wrongBlocks = <|1 -> {{x}}|>;
FTTest`FTAssert["the exact banked gauge prefix is enforced",
  Lookup[hydrate[checkpoint, wrongBlocks], "Status", None] ===
    "ResumeHydrationSolvedBlocksMismatch"];

noAcceptance = ReplacePart[checkpoint,
  "StripSolvers" -> {KeyDrop[directAcceptance,
    {"Certificate", "InstallationEvidence"}]}];
FTTest`FTAssert["every banked block needs mathematical acceptance",
  Lookup[hydrate[noAcceptance], "Status", None] ===
    "ResumeHydrationCheckpointMetadataInvalid"];

malformedForms = ReplacePart[checkpoint,
  "SolvedForms" -> <|1 -> {{0}}|>];
fallback = hydrate[malformedForms];
FTTest`FTAssert["malformed optional forms cannot disable authoritative row reconstruction",
  Lookup[fallback, "Status", None] === "Verified" &&
    Lookup[fallback, "SolvedForms", None] === <||> &&
    TrueQ[Lookup[fallback, "ActivateInstalledRow", False]] &&
    And @@ (TrueQ[Together[#1] === 0] & /@
      Flatten[fallback["InstalledRow"] - authoritativeRow])];

If[DirectoryQ[temporary],
  Quiet[DeleteDirectory[temporary, DeleteContents -> True]]];
FTTest`FTReport[];
