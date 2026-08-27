#!/usr/bin/env wolframscript
(* Real CF300 gate for the package-private, read-only resume hydration path.
   All source state/checkpoint/artifacts are isolated copies under External. *)

repo = "/home/maxzhang/factorization-and-loops";
benchDir = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22", "cf300_sector10_hydration_xh"}];
scratch = FileNameJoin[{benchDir, "scratch"}];
stateFile = FileNameJoin[{scratch, "sector_state_CF300_post9.wl"}];
checkpointFile = FileNameJoin[{scratch,
  "CF300_10_legacy_strip_state.wl"}];
resultFile = FileNameJoin[{benchDir,
  "cf300_resume_hydration_production_gate_result.wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
state = FeynFacet`FamilyArtifactRead[stateFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
ranges = state["Ranges"];
rows = ranges[[10]];
lowerColumns = Range[First[rows] - 1];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = First[DeleteDuplicates[Cases[{state["A"], checkpoint["PrevD"]},
  symbol_Symbol /; SymbolName[symbol] === "eps", Infinity]]];
frame = FeynFacet`TransportFamilyChart["CF300"];
gauge = checkpoint["PrevD"];
blocks = Module[{length = Length[gauge[[1]]], association = <||>,
    lowerSector = 9, column},
  column = length;
  While[column > 0 && lowerSector >= 1,
    association[lowerSector] = gauge[[All,
      column - Length[ranges[[lowerSector]]] + 1 ;; column]];
    column -= Length[ranges[[lowerSector]]]; lowerSector--];
  association];

sourceFiles = Sort[FileNames["*.wl", scratch, Infinity]];
sourceHashesBefore = Association@Table[
  file -> FileHash[file, "SHA256", "HexString"], {file, sourceFiles}];

{hydrateSeconds, hydrated} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeHydrateResume[
    checkpoint, checkpointFile, blocks,
    Lookup[checkpoint, "SolvedForms", <||>], "CF300", 10,
    variables, epsilon, frame, ranges, scratch, state["A"],
    "KernelCount" -> 1, "FinalCheck" -> "Numerical",
    "Verbose" -> True]];
sourceHashesAfterHydration = Association@Table[
  file -> FileHash[file, "SHA256", "HexString"], {file, sourceFiles}];

If[Lookup[hydrated, "Status", None] =!= "Hydrated" ||
    ! TrueQ[Lookup[hydrated, "ActivateInstalledRow", False]],
  FeynFacet`FamilyArtifactWrite[
    <|"Status" -> "HydrationFailed",
      "HydrationResult" -> hydrated,
      "ProductionCheckpointTouched" -> False|>, resultFile];
  Exit[2]];

installedRow = hydrated["InstalledRow"];
{applySeconds, applied} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeApply[
    state["A"], state["S"], state["SInverse"], rows, gauge,
    variables, installedRow]];
sourceHashesAfterApply = Association@Table[
  file -> FileHash[file, "SHA256", "HexString"], {file, sourceFiles}];

statistics = Lookup[applied, "Statistics", <||>];
checks = <|
  "ProductionPrivateHelperLoaded" ->
    Length[DownValues[
      FeynFacet`Private`familyRowGaugeHydrateResume]] > 0,
  "Hydrated" -> Lookup[hydrated, "Status", None] === "Hydrated",
  "AllNineReplayRecords" ->
    Length[Lookup[hydrated, "ReplayRecords", {}]] === 9,
  "AllNineInputsBoundToCurrentConnection" ->
    AllTrue[Lookup[hydrated, "ReplayRecords", {}],
      TrueQ[Lookup[#, "CheckpointStripSameQ", False]] &],
  "AllNineLegacyFormsHydratedAsMissing" ->
    Lookup[Lookup[hydrated, "ReplayRecords", {}], "Action", {}] ===
      ConstantArray["HydratedMissing", 9],
  "InstalledRowDimensions" -> Dimensions[installedRow] === {2, 3, 17},
  "InstalledRowActivated" ->
    TrueQ[Lookup[hydrated, "ActivateInstalledRow", False]],
  "NoCheckpointWriteCapabilityReturned" ->
    ! KeyExistsQ[hydrated, "CheckpointWritten"],
  "SourceTreeReadOnlyAfterHydration" ->
    sourceHashesAfterHydration === sourceHashesBefore,
  "PackageRowApplyOK" -> Lookup[applied, "Status", None] === "OK",
  "DefaultTogetherModePreserved" ->
    Lookup[Lookup[statistics, "A", <||>],
      "FutureAMode", None] === "Together",
  "InstalledRowUsedVerbatim" ->
    SameQ[applied["Connection"][[All, rows, lowerColumns]], installedRow],
  "AllInstalledEntriesAccounted" ->
    Lookup[Lookup[statistics, "A", <||>],
      "InstalledRowEntries", None] ===
      Times @@ Dimensions[installedRow],
  "FutureTargetCount36" ->
    Lookup[Lookup[statistics, "A", <||>],
      "FutureTouched", None] === 36,
  "DeferredModeNotEnabled" ->
    Lookup[Lookup[statistics, "A", <||>],
      "DeferredFutureEntries", None] === 0,
  "SourceTreeReadOnlyAfterApply" ->
    sourceHashesAfterApply === sourceHashesBefore|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status,
  "Purpose" -> "CF300PackageReadOnlyResumeHydrationGate",
  "Family" -> "CF300", "Sector" -> 10, "Rows" -> rows,
  "Checks" -> checks, "HydrationSeconds" -> hydrateSeconds,
  "ApplySeconds" -> applySeconds,
  "ReplayRecords" -> hydrated["ReplayRecords"],
  "Statistics" -> statistics,
  "InstalledRowLeafCount" -> LeafCount[installedRow],
  "InstalledRowByteCount" -> ByteCount[installedRow],
  "StateSHA256" -> FileHash[stateFile, "SHA256", "HexString"],
  "CheckpointSHA256" ->
    FileHash[checkpointFile, "SHA256", "HexString"],
  "ProductionHook" -> True,
  "CheckpointWriter" -> "SectorDriverOnly",
  "DeferredFutureAEnabled" -> False,
  "Scope" -> "Resume replay and current-row materialization only; the " <>
    "36 future sector-12 targets retain default Together normalization.",
  "ProductionCheckpointTouched" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["CF300 PRODUCTION HYDRATION GATE ", KeyTake[record,
  {"Status", "Checks", "HydrationSeconds", "ApplySeconds",
   "InstalledRowLeafCount", "InstalledRowByteCount"}],
  " written=", resultFile];
Clear[state, checkpoint, blocks, hydrated, applied, installedRow, record];
Exit[If[status === "OK", 0, 1]];
