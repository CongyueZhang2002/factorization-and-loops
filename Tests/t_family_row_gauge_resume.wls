#!/usr/bin/env wolframscript
(* Focused fail-closed tests for read-only resume hydration. *)

root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps];
temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-row-gauge-resume-test-" <> CreateUUID[]}]];
ranges = {{1}, {2}, {3}};
variables = {x, y};
connection = ConstantArray[0, {2, 3, 3}];
frame = <||>;

(* A nonzero 1x1 rational strip exercises the driver's direct artifact layout
   (finite_field_k_j) and the real finite-field replay path, not only the
   zero-forcing shortcut used by the cheap corruption fixtures below. *)
Clear[xDirect, yDirect, epsDirect];
directVariables = {xDirect, yDirect};
directRecord = <|"Family" -> "CFDIRECT", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> directVariables,
  "Regulator" -> epsDirect,
  "Strip" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}},
    {{{1 - epsDirect xDirect}}, {{0}}}}, "ExtraLetters" -> {}|>;
directArtifactDirectory = FileNameJoin[{temporary, "finite_field_2_1"}];
directSolution = FeynFacet`SolveEpsFormStripFiniteField[directRecord,
  "KernelCount" -> 1, "FinalCheck" -> "Exact",
  "ArtifactDirectory" -> directArtifactDirectory,
  "ArtifactPrefix" -> "CFDIRECT_2_1", "Verbose" -> False];
directSetupQ = AssociationQ[directSolution] &&
  Lookup[directSolution, "Status", None] === "Solved" &&
  TrueQ[Lookup[directSolution, "ExactDLog", False]];
directReplay = If[directSetupQ,
  directConnection = ConstantArray[0, {2, 2, 2}];
  Do[
    directConnection[[mu, 1, 1]] = epsDirect
      directRecord["Strip"][[2, mu, 1, 1]];
    directConnection[[mu, 2, 2]] = epsDirect
      directRecord["Strip"][[1, mu, 1, 1]];
    directConnection[[mu, 2, 1]] =
      directRecord["Strip"][[3, mu, 1, 1]], {mu, 2}];
  directInput = KeyDrop[directRecord, "ExtraLetters"];
  directInputFile = FileNameJoin[{temporary, "CFDIRECT_2_1_input.wl"}];
  FeynFacet`FamilyArtifactWrite[directInput, directInputFile];
  directForm = FeynFacet`Private`familyRowGaugeDLogForm[
    directSolution, directVariables, epsDirect, {1, 1}];
  directSolverConfiguration =
    FeynFacet`Private`familyRowGaugeSolverConfiguration[
      "DirectRationalFiniteField", "Rational",
      <|"CoefficientField" -> "Rational"|>, "Exact", Automatic, 2,
      "Wolfram"];
  directCheckpoint = <|"Sector" -> 2, "SubSize" -> 1,
    "Truncation" -> 2, "PrevD" -> directSolution["Gauge"],
    "ConnectionHash" -> Hash[
      directConnection /. epsDirect -> CANONICA`eps,
      "SHA256", "HexString"],
    "StripSolvers" -> {<|"Sector" -> 2, "LowerSector" -> 1,
      "Method" -> directSolution["Method"], "ExtraLetters" -> {},
      "ExactDLog" -> True,
      "SolverConfiguration" -> directSolverConfiguration|>},
    "SolvedForms" -> <|1 -> directForm|>|>;
  directCheckpointFile = FileNameJoin[{temporary,
    "direct_checkpoint.wl"}];
  FeynFacet`FamilyArtifactWrite[directCheckpoint, directCheckpointFile];
  FeynFacet`Private`familyRowGaugeHydrateResume[
    directCheckpoint, directCheckpointFile,
    <|1 -> directSolution["Gauge"]|>, directCheckpoint["SolvedForms"],
    "CFDIRECT", 2, directVariables, epsDirect,
    <|"CoefficientField" -> "Rational"|>, {{1}, {2}}, temporary,
    directConnection, "KernelCount" -> 1, "FinalCheck" -> "Exact"],
  <|"Status" -> "DirectFiniteFieldFixtureSetupFailed",
    "ActivateInstalledRow" -> False|>];

FTTest`FTAssert["nonzero rational cache replays gauge and form directly",
  directSetupQ && Lookup[directReplay, "Status", None] === "Verified" &&
    TrueQ[Lookup[directReplay, "ActivateInstalledRow", False]] &&
    Lookup[Lookup[directReplay, "ReplayRecords", {}], "Route"] ===
      {"DirectFiniteField"} &&
    SameQ[Lookup[directReplay, "SolvedForms", <||>],
      directCheckpoint["SolvedForms"]]];

writeInput[lowerSector_] := FeynFacet`FamilyArtifactWrite[
  <|"Family" -> "CFTEST", "Sector" -> 3,
    "LowerSector" -> lowerSector, "Variables" -> variables,
    "Regulator" -> eps,
    "Strip" -> ConstantArray[0, {3, 2, 1, 1}]|>,
  FileNameJoin[{temporary,
    "CFTEST_3_" <> ToString[lowerSector] <> "_input.wl"}]];
Scan[writeInput, {1, 2}];

fullBlocks = <|2 -> {{0}}, 1 -> {{0}}|>;
fullCheckpoint = <|"Sector" -> 3, "SubSize" -> 1,
  "Truncation" -> 3, "PrevD" -> {{0, 0}},
  "ConnectionHash" -> Hash[connection /. eps -> CANONICA`eps,
    "SHA256", "HexString"],
  "StripSolvers" -> {
    <|"Sector" -> 3, "LowerSector" -> 2,
      "Method" -> "ZeroForcing", "ExactDLog" -> True|>,
    <|"Sector" -> 3, "LowerSector" -> 1,
      "Method" -> "ZeroForcing", "ExactDLog" -> True|>}|>;
fullFile = FileNameJoin[{temporary, "full_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[fullCheckpoint, fullFile];
fullHashBefore = FileHash[fullFile, "SHA256", "HexString"];
full = FeynFacet`Private`familyRowGaugeHydrateResume[
  fullCheckpoint, fullFile, fullBlocks, <||>, "CFTEST", 3,
  variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];

FTTest`FTAssert["complete legacy checkpoint hydrates both forms",
  Lookup[full, "Status", None] === "Hydrated" &&
    Sort[Keys[Lookup[full, "SolvedForms", <||>]]] === {1, 2} &&
    Length[Lookup[full, "ReplayRecords", {}]] === 2];
FTTest`FTAssert["rational resumes use the direct finite-field replay route",
  Lookup[Lookup[full, "ReplayRecords", {}], "Route"] ===
    ConstantArray["DirectFiniteField", 2]];
FTTest`FTAssert["complete hydration activates one exact installed row",
  TrueQ[Lookup[full, "ActivateInstalledRow", False]] &&
    Dimensions[Lookup[full, "InstalledRow", {}]] === {2, 1, 2} &&
    Flatten[full["InstalledRow"]] === ConstantArray[0, 4]];
FTTest`FTAssert["hydration never rewrites its checkpoint",
  FileHash[fullFile, "SHA256", "HexString"] === fullHashBefore &&
    SameQ[FeynFacet`FamilyArtifactRead[fullFile], fullCheckpoint]];

modernCheckpoint = Join[fullCheckpoint,
  <|"SolvedForms" -> full["SolvedForms"]|>];
modernFile = FileNameJoin[{temporary, "modern_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[modernCheckpoint, modernFile];
modernHashBefore = FileHash[modernFile, "SHA256", "HexString"];
verified = FeynFacet`Private`familyRowGaugeHydrateResume[
  modernCheckpoint, modernFile, fullBlocks, modernCheckpoint["SolvedForms"],
  "CFTEST", 3, variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["complete existing forms are replayed before activation",
  Lookup[verified, "Status", None] === "Verified" &&
    TrueQ[Lookup[verified, "ActivateInstalledRow", False]] &&
    Length[Lookup[verified, "ReplayRecords", {}]] === 2 &&
    Lookup[verified["ReplayRecords"], "Action"] ===
      ConstantArray["VerifiedExisting", 2]];
FTTest`FTAssert["verification of existing forms is checkpoint-read-only",
  FileHash[modernFile, "SHA256", "HexString"] === modernHashBefore &&
    SameQ[FeynFacet`FamilyArtifactRead[modernFile], modernCheckpoint]];

corruptForms = modernCheckpoint["SolvedForms"];
corruptForms[1] = ReplacePart[corruptForms[1],
  {1, 1, 1} -> corruptForms[1][[1, 1, 1]] + 1];
corruptCheckpoint = Join[modernCheckpoint,
  <|"SolvedForms" -> corruptForms|>];
corruptFile = FileNameJoin[{temporary, "corrupt_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[corruptCheckpoint, corruptFile];
corruptHashBefore = FileHash[corruptFile, "SHA256", "HexString"];
corruptReplay = FeynFacet`Private`familyRowGaugeHydrateResume[
  corruptCheckpoint, corruptFile, fullBlocks, corruptForms, "CFTEST", 3,
  variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["dimension-valid one-entry form corruption fails closed",
  Lookup[corruptReplay, "Status", None] ===
      "ResumeHydrationExistingFormReplayMismatch" &&
    ! TrueQ[Lookup[corruptReplay, "ActivateInstalledRow", True]] &&
    FileHash[corruptFile, "SHA256", "HexString"] === corruptHashBefore &&
    SameQ[FeynFacet`FamilyArtifactRead[corruptFile], corruptCheckpoint]];

corruptGaugeBlocks = <|2 -> {{0}}, 1 -> {{1}}|>;
corruptGaugeCheckpoint = Join[fullCheckpoint, <|"PrevD" -> {{1, 0}}|>];
corruptGaugeFile = FileNameJoin[{temporary,
  "corrupt_gauge_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[corruptGaugeCheckpoint, corruptGaugeFile];
corruptGaugeHashBefore = FileHash[corruptGaugeFile,
  "SHA256", "HexString"];
corruptGaugeReplay = FeynFacet`Private`familyRowGaugeHydrateResume[
  corruptGaugeCheckpoint, corruptGaugeFile, corruptGaugeBlocks, <||>,
  "CFTEST", 3, variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["dimension-valid checkpoint gauge corruption fails closed",
  Lookup[corruptGaugeReplay, "Status", None] ===
      "ResumeHydrationReplayIdentityFailed" &&
    ! TrueQ[Lookup[corruptGaugeReplay, "ActivateInstalledRow", True]] &&
    FileHash[corruptGaugeFile, "SHA256", "HexString"] ===
      corruptGaugeHashBefore &&
    SameQ[FeynFacet`FamilyArtifactRead[corruptGaugeFile],
      corruptGaugeCheckpoint]];
invalidatedRow =
  FeynFacet`Private`familyRowGaugeResumeInvalidatedState[1];
FTTest`FTAssert["typed replay failure resets the complete recovered row",
  SameQ[invalidatedRow, <|"PrevD" -> {{}}, "SolvedBlocks" -> <||>,
    "SolvedForms" -> <||>, "StripSolvers" -> {},
    "InstalledRow" -> Automatic|>]];

algebraicFrame = <|"CoefficientField" -> "Multiquadratic"|>;
algebraicZeroReplay = FeynFacet`Private`familyRowGaugeHydrateResume[
  fullCheckpoint, fullFile, fullBlocks, <||>, "CFTEST", 3,
  variables, eps, algebraicFrame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["multiquadratic zero forcing retains the in-frame route",
  Lookup[algebraicZeroReplay, "Status", None] === "Hydrated" &&
    TrueQ[Lookup[algebraicZeroReplay, "ActivateInstalledRow", False]] &&
    Lookup[Lookup[algebraicZeroReplay, "ReplayRecords", {}], "Route"] ===
      ConstantArray["InFrame", 2]];

partialBlocks = <|2 -> {{0}}|>;
partialCheckpoint = Join[fullCheckpoint, <|
  "PrevD" -> {{0}}, "StripSolvers" -> {First[fullCheckpoint["StripSolvers"]]}|>];
partialFile = FileNameJoin[{temporary, "partial_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[partialCheckpoint, partialFile];
partialHashBefore = FileHash[partialFile, "SHA256", "HexString"];
partial = FeynFacet`Private`familyRowGaugeHydrateResume[
  partialCheckpoint, partialFile, partialBlocks, <||>, "CFTEST", 3,
  variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["partial suffix hydrates but is never activated",
  Lookup[partial, "Status", None] === "HydratedPartial" &&
    Sort[Keys[Lookup[partial, "SolvedForms", <||>]]] === {2} &&
    ! TrueQ[Lookup[partial, "ActivateInstalledRow", True]] &&
    Lookup[partial, "InstalledRow", None] === Automatic];
FTTest`FTAssert["partial hydration is also checkpoint-read-only",
  FileHash[partialFile, "SHA256", "HexString"] === partialHashBefore &&
    SameQ[FeynFacet`FamilyArtifactRead[partialFile], partialCheckpoint]];

fabricatedForms = Association@Table[lowerSector ->
  ConstantArray[0, {2, 1, 1}], {lowerSector, {1, 2}}];
fabricated = FeynFacet`Private`familyRowGaugeHydrateResume[
  fullCheckpoint, fullFile, fullBlocks, fabricatedForms, "CFTEST", 3,
  variables, eps, frame, ranges, temporary, connection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["caller-injected forms are rejected before activation",
  Lookup[fabricated, "Status", None] ===
      "ResumeHydrationSolvedFormsMismatch" &&
    ! TrueQ[Lookup[fabricated, "ActivateInstalledRow", True]] &&
    FileHash[fullFile, "SHA256", "HexString"] === fullHashBefore];

wrongConnection = ReplacePart[connection, {1, 3, 1} -> 1];
identityFailure = FeynFacet`Private`familyRowGaugeHydrateResume[
  fullCheckpoint, fullFile, fullBlocks, <||>, "CFTEST", 3,
  variables, eps, frame, ranges, temporary, wrongConnection,
  "FinalCheck" -> "Exact"];
FTTest`FTAssert["connection identity failure is typed and nonactivating",
  Lookup[identityFailure, "Status", None] ===
      "ResumeHydrationCheckpointIdentityMismatch" &&
    ! TrueQ[Lookup[identityFailure, "ActivateInstalledRow", True]] &&
    FileHash[fullFile, "SHA256", "HexString"] === fullHashBefore];

fallback = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[3], IdentityMatrix[3], {3},
  {{0, 0}}, variables, Automatic];
FTTest`FTAssert["typed hydration failure leaves exact sparse fallback usable",
  Lookup[fallback, "Status", None] === "OK" &&
    SameQ[fallback["Connection"], connection] &&
    SameQ[fallback["Transformation"], IdentityMatrix[3]] &&
    SameQ[fallback["Inverse"], IdentityMatrix[3]]];

If[DirectoryQ[temporary],
  Quiet[DeleteDirectory[temporary, DeleteContents -> True]]];
FTTest`FTReport[];
