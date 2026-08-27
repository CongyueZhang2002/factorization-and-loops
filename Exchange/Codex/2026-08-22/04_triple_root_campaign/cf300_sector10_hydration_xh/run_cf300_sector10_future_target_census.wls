#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
benchDir = FileNameJoin[{exchange, "cf300_sector10_hydration_xh"}];
scratch = FileNameJoin[{benchDir, "scratch"}];
resultFile = FileNameJoin[{benchDir,
  "cf300_sector10_future_target_census.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh",
  "FamilyRowGaugeDeferredPrototype.wl"}]];
state = FeynFacet`FamilyArtifactRead[FileNameJoin[{scratch,
  "sector_state_CF300_post9.wl"}]];
checkpoint = FeynFacet`FamilyArtifactRead[FileNameJoin[{scratch,
  "CF300_10_legacy_strip_state.wl"}]];
rows = state["Ranges"][[10]]; stop = Last[rows]; n = Length[state["S"]];
lowerColumns = Range[First[rows] - 1];
dummyInstalled = ConstantArray[0, {2, Length[rows], Length[lowerColumns]}];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
{seconds, deferred} = AbsoluteTiming[
  CodexRowGaugeDeferred`ApplyDeferredFutureRowGauge[
    state["A"], state["S"], state["SInverse"], rows,
    checkpoint["PrevD"], variables, dummyInstalled]];
targets = Flatten[Table[
  If[! SameQ[deferred["Connection"][[mu, row, column]],
      state["A"][[mu, row, column]]], {mu, row, column}, Nothing],
  {mu, 2}, {row, stop + 1, n}, {column, lowerColumns}], 2];
sectorOfRow[row_] := First@FirstPosition[state["Ranges"],
  range_ /; MemberQ[range, row]];
record = <|"Status" -> If[Lookup[deferred, "Status", None] === "OK",
    "OK", "Failed"], "Family" -> "CF300", "Sector" -> 10,
  "Rows" -> rows, "BuildSeconds" -> seconds,
  "FutureTargetCount" -> Length[targets], "FutureTargets" -> targets,
  "TargetRowHistogram" -> Counts[targets[[All, 2]]],
  "TargetSectorHistogram" -> Counts[sectorOfRow /@ targets[[All, 2]]],
  "Statistics" -> Lookup[deferred, "Statistics", <||>],
  "ProductionCheckpointTouched" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["S10 FUTURE CENSUS ", KeyTake[record,
  {"Status", "BuildSeconds", "FutureTargetCount", "TargetRowHistogram",
   "TargetSectorHistogram", "Statistics"}]];
Clear[state, checkpoint, deferred, targets];
Exit[If[record["Status"] === "OK", 0, 1]];
