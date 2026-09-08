#!/usr/bin/env wolframscript
(* Exact package-path certificate for the CF300 sector-8 installed-row
   shortcut.  The post-sector9 state supplies invariant row-8 slices, so no
   dense symbolic conjugation is rerun. *)
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
If[! DirectoryQ[outDir],
  CreateDirectory[outDir, CreateIntermediateDirectories -> True]];
resultFile = FileNameJoin[{outDir,
  "cf300_sector8_installed_row_package_benchmark.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
preFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_state_CF300_codex_triple_root.wl"}];
checkpointFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_CF300_codex_triple_root", "CF300_8_strip_state.wl"}];
postFile = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-23", "CF300", "sector_state_CF300_standard.wl"}];
pre = FeynFacet`FamilyArtifactRead[preFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
post = FeynFacet`FamilyArtifactRead[postFile];
If[! And @@ (AssociationQ /@ {pre, checkpoint, post}), Exit[2]];
Print["INSTALLED ROW fixtures loaded preSector=", pre["Sector"],
  " checkpointSector=", checkpoint["Sector"],
  " postSector=", post["Sector"]];
k = checkpoint["Sector"];
rows = pre["Ranges"][[k]];
start = First[rows]; stop = Last[rows];
n = Length[pre["S"]];
lowerColumns = Range[start - 1];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
installedRow = post["A"][[All, rows, lowerColumns]];
memoryBefore = MemoryInUse[];
{applySeconds, applied} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeApply[pre["A"], pre["S"],
    pre["SInverse"], rows, checkpoint["PrevD"], variables,
    installedRow]];
memoryAfter = MemoryInUse[];
Print["INSTALLED ROW applySeconds=", N[applySeconds],
  " status=", Lookup[applied, "Status", None],
  " statistics=", Lookup[applied, "Statistics", <||>]];
If[! AssociationQ[applied] || applied["Status"] =!= "OK",
  Print["INSTALLED ROW failed status=", Lookup[applied, "Status", None]];
  Exit[3]];
checks = <|
  "ConnectionCurrentRowInvariant" -> SameQ[
    applied["Connection"][[All, rows, lowerColumns]],
    post["A"][[All, rows, lowerColumns]]],
  "TransformationThroughRowInvariant" -> SameQ[
    applied["Transformation"][[Range[stop], lowerColumns]],
    post["S"][[Range[stop], lowerColumns]]],
  "InverseCurrentRowInvariant" -> SameQ[
    applied["Inverse"][[rows, All]], post["SInverse"][[rows, All]]],
  "FutureCouplingStructurallyZero" -> AllTrue[
    Flatten[pre["A"][[All, Range[stop + 1, n], rows]]],
    SameQ[#, 0] &],
  "NoFutureAProducts" -> applied["Statistics", "A", "Products"] === 0,
  "AllCurrentAEntriesInstalled" ->
    applied["Statistics", "A", "InstalledRowEntries"] ===
      2 Length[rows] Length[lowerColumns],
  "ExpectedSparseSProducts" ->
    applied["Statistics", "S", "Products"] === 36,
  "ExpectedSparseInverseProducts" ->
    applied["Statistics", "SInverse", "Products"] === 36|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status,
  "Purpose" -> "ExactInstalledRowProductionShortcut",
  "Family" -> "CF300", "Sector" -> k, "Rows" -> rows,
  "Sources" -> <|
    "PreSector8State" -> preFile,
    "PreSector8StateSHA256" -> FileHash[preFile, "SHA256", "HexString"],
    "Sector8Checkpoint" -> checkpointFile,
    "Sector8CheckpointSHA256" ->
      FileHash[checkpointFile, "SHA256", "HexString"],
    "PostSector9State" -> postFile,
    "PostSector9StateSHA256" ->
      FileHash[postFile, "SHA256", "HexString"]|>,
  "PostStateSector" -> post["Sector"], "Checks" -> checks,
  "ApplySeconds" -> applySeconds,
  "Statistics" -> applied["Statistics"],
  "MemoryBytes" -> <|"BeforeApply" -> memoryBefore,
    "AfterApply" -> memoryAfter, "MaxMemoryUsed" -> MaxMemoryUsed[]|>,
  "Decision" -> "The installed dlog row removes current-row recomputation; CF300 sector 8 retains nonzero future-row A corrections, covered by the separate explicit target census."|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["INSTALLED ROW RESULT ", KeyTake[record,
  {"Status", "PostStateSector", "Checks", "ApplySeconds", "Statistics"}],
  " written=", resultFile];
Clear[pre, checkpoint, post, installedRow, applied];
Exit[If[status === "OK", 0, 1]];
