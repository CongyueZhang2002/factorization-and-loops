#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
resultFile = FileNameJoin[{outDir, "cf300_sector8_future_target_census.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private",
  "FamilyRowGaugeFiniteField.wl"}]];
End[];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];
stateFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_state_CF300_codex_triple_root.wl"}];
checkpointFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_CF300_codex_triple_root", "CF300_8_strip_state.wl"}];
state = FeynFacet`FamilyArtifactRead[stateFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
frame = FeynFacet`TransportFamilyChart["CF300"];
roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
k = checkpoint["Sector"];
rows = state["Ranges"][[k]]; stop = Last[rows];
{prepareSeconds, prep} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeFiniteFieldPrepare[state["A"],
    state["S"], state["SInverse"], rows, checkpoint["PrevD"],
    variables, roots]];
If[prep["Status"] =!= "Prepared", Exit[2]];
future = Select[prep["Records", "Connection"],
  #1["Target"][[2]] > stop &];
deferredExpressions = Total[Lookup[#1["Terms"], "Expression", {}]] & /@ future;
targetRows = Lookup[future, "Target"][[All, 2]];
targetSectors = targetRows /. row_Integer :> First[FirstPosition[
  state["Ranges"], range_ /; MemberQ[range, row]]];
record = <|"Status" -> "OK", "Family" -> "CF300", "Sector" -> k,
  "Rows" -> rows, "PrepareSeconds" -> prepareSeconds,
  "FutureTouched" -> Length[future],
  "TargetRowCounts" -> Counts[targetRows],
  "TargetSectorCounts" -> Counts[targetSectors],
  "NextSectorRows" -> state["Ranges"][[k + 1]],
  "Targets" -> Lookup[future, "Target"],
  "TermCounts" -> (Length[#1["Terms"]] & /@ future),
  "DeferredLeafCounts" -> (LeafCount /@ deferredExpressions),
  "DeferredTotalLeafCount" -> Total[LeafCount /@ deferredExpressions],
  "DeferredByteCount" -> ByteCount[deferredExpressions],
  "DeferredInputByteCount" -> ByteCount[future],
  "TransformationTouched" ->
    Length[prep["Records", "Transformation"]],
  "InverseTouched" -> Length[prep["Records", "Inverse"]]|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["FUTURE CENSUS ", KeyTake[record,
  {"Status", "PrepareSeconds", "FutureTouched", "TargetRowCounts",
   "TargetSectorCounts", "DeferredTotalLeafCount", "DeferredByteCount"}],
  " written=", resultFile];
Clear[state, checkpoint, prep, future, deferredExpressions];
Exit[0];
