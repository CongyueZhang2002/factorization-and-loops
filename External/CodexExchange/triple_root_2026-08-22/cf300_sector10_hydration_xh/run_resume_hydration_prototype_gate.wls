#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
benchDir = FileNameJoin[{exchange, "cf300_sector10_hydration_xh"}];
scratch = FileNameJoin[{benchDir, "scratch"}];
sourceCheckpoint = FileNameJoin[{scratch,
  "CF300_10_legacy_strip_state.wl"}];
testCheckpoint = FileNameJoin[{benchDir,
  "CF300_10_legacy_strip_state_hydrated_test.wl"}];
partialTestCheckpoint = FileNameJoin[{benchDir,
  "CF300_10_partial_strip_state_hydrated_test.wl"}];
resultFile = FileNameJoin[{benchDir,
  "resume_hydration_prototype_gate_result.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{benchDir, "ResumeHydrationPrototype.wl"}]];
state = FeynFacet`FamilyArtifactRead[FileNameJoin[{scratch,
  "sector_state_CF300_post9.wl"}]];
checkpoint = FeynFacet`FamilyArtifactRead[sourceCheckpoint];
FeynFacet`FamilyArtifactWrite[checkpoint, testCheckpoint];
ranges = state["Ranges"];
gauge = checkpoint["PrevD"];
blocks = Module[{len = Length[gauge[[1]]], assoc = <||>,
    lowerSector = 9, column},
  column = len;
  While[column > 0 && lowerSector >= 1,
    assoc[lowerSector] = gauge[[All,
      column - Length[ranges[[lowerSector]]] + 1 ;; column]];
    column -= Length[ranges[[lowerSector]]]; lowerSector--];
  assoc];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = First[DeleteDuplicates[Cases[{state["A"], gauge},
  s_Symbol /; SymbolName[s] === "eps", Infinity]]];
frame = FeynFacet`TransportFamilyChart["CF300"];
expectedHash = checkpoint["ConnectionHash"];
currentConnection = state["A"];
corruptConnection = ReplacePart[currentConnection,
  {1, First[ranges[[10]]], First[ranges[[1]]]} ->
    currentConnection[[1, First[ranges[[10]]], First[ranges[[1]]]]] + 1];

initialFileHash = FileHash[testCheckpoint, "SHA256", "HexString"];
wrongHashResult = CodexResumeHydration`HydrateMissingSolvedForms[
  checkpoint, testCheckpoint, blocks, <||>, "CF300", 10,
  variables, epsilon, frame, ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> "deliberately-wrong",
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
wrongHashFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === initialFileHash;

wrongConnectionResult = CodexResumeHydration`HydrateMissingSolvedForms[
  checkpoint, testCheckpoint, blocks, <||>, "CF300", 10,
  variables, epsilon, frame, ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> expectedHash,
  "CurrentConnection" -> corruptConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
wrongConnectionFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === initialFileHash;

wrongBlocks = Join[blocks, <|1 -> ReplacePart[blocks[1],
  {1, 1} -> blocks[1][[1, 1]] + 1]|>];
wrongBlocksResult = CodexResumeHydration`HydrateMissingSolvedForms[
  checkpoint, testCheckpoint, wrongBlocks, <||>, "CF300", 10,
  variables, epsilon, frame, ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> expectedHash,
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
wrongBlocksFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === initialFileHash;

badInputScratch = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-hydration-bad-input-" <> CreateUUID[]}]];
badInputFile = FileNameJoin[{badInputScratch,
  "CF300_10_1_input.wl"}];
CopyFile[FileNameJoin[{scratch, "CF300_10_1_input.wl"}], badInputFile];
badInput = FeynFacet`FamilyArtifactRead[badInputFile];
badStrip = badInput["Strip"];
badStrip[[3, 1, 1, 1]] = badStrip[[3, 1, 1, 1]] + 1;
FeynFacet`FamilyArtifactWrite[Join[badInput, <|"Strip" -> badStrip|>],
  badInputFile];
wrongInputResult = CodexResumeHydration`HydrateMissingSolvedForms[
  checkpoint, testCheckpoint, blocks, <||>, "CF300", 10,
  variables, epsilon, frame, ranges, badInputScratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> expectedHash,
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
wrongInputFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === initialFileHash;

fabricatedLegacyForms = Association@Table[lowerSector ->
  ConstantArray[0, {2, Length[ranges[[10]]],
    Length[ranges[[lowerSector]]]}], {lowerSector, Range[9]}];
fabricatedLegacyResult = CodexResumeHydration`HydrateMissingSolvedForms[
  checkpoint, testCheckpoint, blocks, fabricatedLegacyForms,
  "CF300", 10, variables, epsilon, frame, ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> expectedHash,
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
fabricatedLegacyFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === initialFileHash;

{hydrateSeconds, hydrated} = AbsoluteTiming[
  CodexResumeHydration`HydrateMissingSolvedForms[
    checkpoint, testCheckpoint, blocks, <||>, "CF300", 10,
    variables, epsilon, frame, ranges, scratch,
    "KernelCount" -> 1, "FinalCheck" -> "Numerical",
    "ExpectedConnectionHash" -> expectedHash,
    "CurrentConnection" -> currentConnection,
    "WriteCheckpoint" -> True, "Verbose" -> True]];
writtenCheckpoint = FeynFacet`FamilyArtifactRead[testCheckpoint];
writtenHash = FileHash[testCheckpoint, "SHA256", "HexString"];
writtenForms = Lookup[writtenCheckpoint, "SolvedForms", <||>];
modernWrongForms = Join[writtenForms, <|1 ->
  ReplacePart[writtenForms[1], {1, 1, 1} ->
    writtenForms[1][[1, 1, 1]] + 1]|>];
modernWrongFormsResult =
  CodexResumeHydration`HydrateMissingSolvedForms[
    writtenCheckpoint, testCheckpoint, blocks, modernWrongForms,
    "CF300", 10, variables, epsilon, frame, ranges, scratch,
    "KernelCount" -> 1, "FinalCheck" -> "Numerical",
    "ExpectedConnectionHash" -> expectedHash,
    "CurrentConnection" -> currentConnection,
    "WriteCheckpoint" -> True, "Verbose" -> False];
modernWrongFormsFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === writtenHash;

{noOpSeconds, noOp} = AbsoluteTiming[
  CodexResumeHydration`HydrateMissingSolvedForms[
    writtenCheckpoint, testCheckpoint, blocks, writtenForms,
    "CF300", 10, variables, epsilon, frame, ranges, scratch,
    "KernelCount" -> 1, "FinalCheck" -> "Numerical",
    "ExpectedConnectionHash" -> expectedHash,
    "CurrentConnection" -> currentConnection,
    "WriteCheckpoint" -> True, "Verbose" -> False]];
noOpFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === writtenHash;

diskMismatchCheckpoint = Join[writtenCheckpoint,
  <|"ConnectionHash" -> "association-only-corruption"|>];
diskMismatch = CodexResumeHydration`HydrateMissingSolvedForms[
  diskMismatchCheckpoint, testCheckpoint, blocks, writtenForms,
  "CF300", 10, variables, epsilon, frame, ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> "association-only-corruption",
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
diskMismatchFileUnchanged = FileHash[testCheckpoint,
  "SHA256", "HexString"] === writtenHash;

(* A genuine recovered suffix is safe to hydrate and persist, but it must
   never be activated as a complete installed row. *)
partialBlocks = KeyTake[blocks, {8, 9}];
partialCheckpoint = Join[
  KeyDrop[checkpoint, {"SolvedForms", "SolvedFormsHydration"}], <|
    "PrevD" -> Join[partialBlocks[8], partialBlocks[9], 2],
    "StripSolvers" -> Select[checkpoint["StripSolvers"],
      MemberQ[{8, 9}, Lookup[#, "LowerSector", None]] &]|>];
FeynFacet`FamilyArtifactWrite[partialCheckpoint, partialTestCheckpoint];
{partialSeconds, partialHydrated} = AbsoluteTiming[
  CodexResumeHydration`HydrateMissingSolvedForms[
    partialCheckpoint, partialTestCheckpoint, partialBlocks, <||>,
    "CF300", 10, variables, epsilon, frame, ranges, scratch,
    "KernelCount" -> 1, "FinalCheck" -> "Numerical",
    "ExpectedConnectionHash" -> expectedHash,
    "CurrentConnection" -> currentConnection,
    "WriteCheckpoint" -> True, "Verbose" -> True]];
partialWrittenCheckpoint =
  FeynFacet`FamilyArtifactRead[partialTestCheckpoint];
partialWrittenHash = FileHash[partialTestCheckpoint,
  "SHA256", "HexString"];
partialWrittenForms = Lookup[partialWrittenCheckpoint,
  "SolvedForms", <||>];
partialNoOp = CodexResumeHydration`HydrateMissingSolvedForms[
  partialWrittenCheckpoint, partialTestCheckpoint, partialBlocks,
  partialWrittenForms, "CF300", 10, variables, epsilon, frame,
  ranges, scratch,
  "KernelCount" -> 1, "FinalCheck" -> "Numerical",
  "ExpectedConnectionHash" -> expectedHash,
  "CurrentConnection" -> currentConnection,
  "WriteCheckpoint" -> True, "Verbose" -> False];
partialNoOpFileUnchanged = FileHash[partialTestCheckpoint,
  "SHA256", "HexString"] === partialWrittenHash;

checks = <|
  "WrongHashRejected" -> Lookup[wrongHashResult, "Status", None] ===
    "CheckpointIdentityMismatch",
  "WrongHashNoWrite" -> wrongHashFileUnchanged,
  "WrongConnectionRejected" ->
    Lookup[wrongConnectionResult, "Status", None] ===
      "CheckpointIdentityMismatch" &&
    ! TrueQ[Lookup[wrongConnectionResult,
      "CurrentConnectionHashSameQ", True]],
  "WrongConnectionNoWrite" -> wrongConnectionFileUnchanged,
  "WrongSolvedBlocksRejected" ->
    Lookup[wrongBlocksResult, "Status", None] ===
      "CheckpointSolvedBlocksMismatch",
  "WrongSolvedBlocksNoWrite" -> wrongBlocksFileUnchanged,
  "WrongSavedInputRejected" ->
    Lookup[wrongInputResult, "Status", None] ===
      "StripInputCheckpointConnectionMismatch",
  "WrongSavedInputNoWrite" -> wrongInputFileUnchanged,
  "FabricatedLegacyFormsRejected" ->
    Lookup[fabricatedLegacyResult, "Status", None] ===
      "CheckpointSolvedFormsMismatch" &&
    ! TrueQ[Lookup[fabricatedLegacyResult,
      "ActivateInstalledRow", True]],
  "FabricatedLegacyFormsNoWrite" -> fabricatedLegacyFileUnchanged,
  "Hydrated" -> Lookup[hydrated, "Status", None] === "Hydrated",
  "FullHydrationActivated" ->
    TrueQ[Lookup[hydrated, "ActivateInstalledRow", False]],
  "AllNineReplayRecords" ->
    Length[Lookup[hydrated, "ReplayRecords", {}]] === 9,
  "AllNineInputsBoundToCheckpointConnection" ->
    AllTrue[Lookup[hydrated, "ReplayRecords", {}],
      TrueQ[Lookup[#, "CheckpointStripSameQ", False]] &],
  "CheckpointWritten" -> TrueQ[Lookup[hydrated,
    "CheckpointWritten", False]],
  "FullSolvedFormsCoverage" -> Sort[Keys[writtenForms]] === Range[9],
  "InstalledRowDimensions" -> Dimensions[Lookup[hydrated,
    "InstalledRow", {}]] === {2, 3, 17},
  "HydrationProvenanceWritten" -> AssociationQ[
    Lookup[writtenCheckpoint, "SolvedFormsHydration", None]],
  "NeutralHydrationProvenance" ->
    Lookup[Lookup[writtenCheckpoint, "SolvedFormsHydration", <||>],
      "Method", None] === "CachedArtifactReplay",
  "AlreadyCompleteNoOp" -> Lookup[noOp, "Status", None] ===
    "AlreadyComplete",
  "AlreadyCompleteActivated" ->
    TrueQ[Lookup[noOp, "ActivateInstalledRow", False]],
  "AlreadyCompleteNoRewrite" -> noOpFileUnchanged,
  "ModernReplacementFormsRejected" ->
    Lookup[modernWrongFormsResult, "Status", None] ===
      "CheckpointSolvedFormsMismatch" &&
    ! TrueQ[Lookup[modernWrongFormsResult,
      "ActivateInstalledRow", True]],
  "ModernReplacementFormsNoWrite" -> modernWrongFormsFileUnchanged,
  "DiskMismatchRejected" -> Lookup[diskMismatch, "Status", None] ===
    "CheckpointIdentityMismatch",
  "DiskMismatchNoWrite" -> diskMismatchFileUnchanged,
  "PartialHydrated" -> Lookup[partialHydrated, "Status", None] ===
    "HydratedPartial",
  "PartialNotActivated" ->
    ! TrueQ[Lookup[partialHydrated, "ActivateInstalledRow", True]] &&
      Lookup[partialHydrated, "InstalledRow", None] === Automatic,
  "PartialCoverageOnly" -> Sort[Keys[partialWrittenForms]] === {8, 9},
  "PartialInputsBoundToCheckpointConnection" ->
    AllTrue[Lookup[partialHydrated, "ReplayRecords", {}],
      TrueQ[Lookup[#, "CheckpointStripSameQ", False]] &],
  "AlreadyCompletePartialNoOp" ->
    Lookup[partialNoOp, "Status", None] === "AlreadyCompletePartial",
  "AlreadyCompletePartialNotActivated" ->
    ! TrueQ[Lookup[partialNoOp, "ActivateInstalledRow", True]],
  "AlreadyCompletePartialNoRewrite" -> partialNoOpFileUnchanged|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status,
  "Purpose" -> "ResumeHydrationPrototypeRealAtomicGate",
  "Family" -> "CF300", "Sector" -> 10,
  "Checks" -> checks, "HydrateSeconds" -> hydrateSeconds,
  "NoOpSeconds" -> noOpSeconds,
  "PartialHydrateSeconds" -> partialSeconds,
  "ReplayRecords" -> Lookup[hydrated, "ReplayRecords", {}],
  "InstalledRowLeafCount" -> If[ListQ[Lookup[hydrated,
      "InstalledRow", None]], LeafCount[hydrated["InstalledRow"]], 0],
  "InstalledRowByteCount" -> If[ListQ[Lookup[hydrated,
      "InstalledRow", None]], ByteCount[hydrated["InstalledRow"]], 0],
  "SourceCheckpointSHA256" -> FileHash[sourceCheckpoint,
    "SHA256", "HexString"],
  "HydratedTestCheckpointSHA256" -> writtenHash,
  "HydratedPartialTestCheckpointSHA256" -> partialWrittenHash,
  "ProductionCheckpointTouched" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
If[DirectoryQ[badInputScratch],
  Quiet[DeleteDirectory[badInputScratch, DeleteContents -> True]]];
Print["HYDRATION PROTOTYPE RESULT ", KeyTake[record,
  {"Status", "Checks", "HydrateSeconds", "NoOpSeconds",
   "PartialHydrateSeconds", "InstalledRowLeafCount",
   "InstalledRowByteCount"}],
  " written=", resultFile];
Clear[state, checkpoint, blocks, hydrated, writtenCheckpoint, writtenForms,
  noOp, diskMismatch, record];
Exit[If[status === "OK", 0, 1]];
