#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`resumeMathX"];
y = Symbol["Global`resumeMathY"];
eps = Symbol["Global`resumeMathEps"];
variables = {x, y};
ranges = {{1}, {2}, {3}};
sector = 3;
family = "CFTEST";
connection = ConstantArray[0, {2, 3, 3}];
gauge = {{x + y}};
solvedBlocks = <|2 -> gauge|>;
form = ConstantArray[0, {2, 1, 1}];
forms = <|2 -> form|>;
frame = <|"CoefficientField" -> "Rational"|>;
acceptance = <|
  "Sector" -> 3, "LowerSector" -> 2,
  "Method" -> "RationalChart/Test/FiniteField",
  "Certificate" -> "NumericalResidual",
  "FrameCertificate" -> <|
    "CoordinateComposition" -> True,
    "GaugeRoundTrip" -> True,
    "TransformedOneFormPullBack" -> True,
    "BranchSigns" -> {1},
    "ValidationMode" -> "PostPullBackFiniteFieldResidual",
    "InnerCertificate" -> "NumericalResidual",
    "UnseenPrime" -> 1000003,
    "NumericalPfaffianResidualsZero" -> True|>,
  "SolverConfiguration" -> <|
    "Backend" -> "OldBackend", "Threads" -> 1,
    "SourceRevision" -> "old"|>|>;
checkpoint = <|
  "Family" -> family, "Sector" -> sector, "SubSize" -> 1,
  "Truncation" -> 3, "PrevD" -> {{x + y}},
  "ConnectionHash" -> Hash[connection /. eps -> CANONICA`eps,
    "SHA256", "HexString"],
  "StripSolvers" -> {acceptance}, "SolvedForms" -> forms|>;

temporary = CreateDirectory[];
checkpointFile = FileNameJoin[{temporary, "checkpoint.wl"}];
Put[checkpoint, checkpointFile];

call[record_, existing_: forms, blocks_: solvedBlocks,
    current_: connection, familyInput_: family, options___Rule] := Module[{},
  Put[record, checkpointFile];
  FeynFacet`Private`familyRowGaugeHydrateResume[
    record, checkpointFile, blocks, existing, familyInput, sector,
    variables, eps, frame, ranges, temporary, current, options]];

baseline = call[checkpoint,
  forms, solvedBlocks, connection, family,
  "KernelCount" -> 1,
  "FiniteFieldBackendThreads" -> 1,
  "PlanDiscoveryBackend" -> "Wolfram",
  "DriverProvenance" -> <|"Revision" -> "old"|>];
changedExecution = call[checkpoint,
  forms, solvedBlocks, connection, family,
  "KernelCount" -> 8,
  "FiniteFieldBackend" -> "FLINT",
  "FiniteFieldBackendThreads" -> 8,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "PlanDiscoveryBackendThreads" -> 8,
  "DriverProvenance" -> <|"Revision" -> "new"|>,
  "ResumeGate" -> "Exact",
  "Deadline" -> AbsoluteTime[] - 100];

FTAssert["resume accepts the banked block by mathematical identity",
  Lookup[baseline, "Status", None] === "VerifiedPartial" &&
    TrueQ[Lookup[baseline, "ExecutionSettingsIgnored", False]] &&
    SameQ[baseline["SolvedForms"], forms]];
FTAssert["backend, threads, provenance, gate and deadline do not affect admission",
  Lookup[changedExecution, "Status", None] ===
      Lookup[baseline, "Status", None] &&
    SameQ[changedExecution["SolvedForms"], baseline["SolvedForms"]] &&
    SameQ[changedExecution["AcceptanceRecords"],
      baseline["AcceptanceRecords"]]];

changedSummary = ReplacePart[checkpoint,
  "StripSolvers" -> {Append[acceptance,
    "SolverConfiguration" -> <|"Backend" -> "Anything",
      "Threads" -> 999, "SourceRevision" -> "different"|>]}];
FTAssert["execution metadata inside an acceptance record is ignored",
  MemberQ[{"Verified", "VerifiedPartial"},
    Lookup[call[changedSummary], "Status", None]]];

badConnection = ReplacePart[connection, {1, 1, 1} -> 1];
FTAssert["different connection content is rejected",
  Lookup[call[checkpoint, forms, solvedBlocks, badConnection],
    "Status", None] === "ResumeHydrationCheckpointIdentityMismatch"];

wrongFamily = ReplacePart[checkpoint, "Family" -> "OTHER"];
FTAssert["different family identity is rejected",
  Lookup[call[wrongFamily], "Status", None] ===
    "ResumeHydrationFamilyIdentityMismatch"];

missingAcceptance = ReplacePart[checkpoint,
  "StripSolvers" -> {KeyDrop[acceptance,
    {"Certificate", "FrameCertificate"}]}];
FTAssert["a banked block without a mathematical acceptance record is rejected",
  Lookup[call[missingAcceptance], "Status", None] ===
    "ResumeHydrationCheckpointMetadataInvalid"];

badBranch = ReplacePart[checkpoint,
  {"StripSolvers", 1, "FrameCertificate", "BranchSigns"} -> {2}];
FTAssert["a malformed acceptance record is rejected",
  Lookup[call[badBranch], "Status", None] ===
    "ResumeHydrationCheckpointMetadataInvalid"];

malformedForms = <|2 -> {{0}}|>;
formFallbackRecord = ReplacePart[checkpoint,
  "SolvedForms" -> malformedForms];
formFallback = call[formFallbackRecord, malformedForms];
FTAssert["malformed saved forms fall back to sparse propagation",
  Lookup[formFallback, "Status", None] === "VerifiedPartial" &&
    Lookup[formFallback, "SolvedForms", None] === <||> &&
    ! TrueQ[Lookup[formFallback, "ActivateInstalledRow", True]]];

wrongBlocks = <|2 -> {{x - y}}|>;
FTAssert["the exact banked gauge prefix must match the checkpoint",
  Lookup[call[checkpoint, forms, wrongBlocks], "Status", None] ===
    "ResumeHydrationSolvedBlocksMismatch"];

driver = Import[FileNameJoin[{root, "Scripts",
  "family_epsform_sector.wls"}], "Text"];
FTAssert["the production driver does not replay solvers during resume",
  ! StringContainsQ[driver, "familyRowGaugeHydrateResume["] &&
    StringContainsQ[driver, "execution settings ignored"]];

If[DirectoryQ[temporary],
  Quiet[DeleteDirectory[temporary, DeleteContents -> True]]];
FTReport[];
