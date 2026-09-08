#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: classify_triple_root_strip.wls <project-root> <strip-input.wl> [report.wl] [decompose]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
reportFile = If[Length[arguments] >= 3 && StringLength[arguments[[3]]] > 0,
  ExpandFileName[arguments[[3]]], None];
decomposeQ = Length[arguments] >= 4 && arguments[[4]] === "decompose";

If[! FileExistsQ[inputFile],
  Print["TRCLASSIFY FAIL missing_input=", inputFile];
  Exit[65]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
adapterDirectory = DirectoryName[$InputFileName];
Get[FileNameJoin[{adapterDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{adapterDirectory, "TripleRootStripAdapter.wl"}]];

record = Get[inputFile];
If[! AssociationQ[record],
  Print["TRCLASSIFY FAIL invalid_record"];
  Exit[66]];
family = Lookup[record, "Family", None];
If[! StringQ[family],
  Print["TRCLASSIFY FAIL missing_family"];
  Exit[67]];

frame = FeynFacet`TransportFamilyChart[family];
If[! AssociationQ[frame] ||
    Lookup[frame, "CoefficientField", None] =!= "Multiquadratic",
  Print["TRCLASSIFY FAIL invalid_frame family=", family];
  Exit[68]];

classification = CodexTripleRootStrip`TRClassifyStripRecord[record, frame];
result = If[decomposeQ &&
    Lookup[classification, "Status", None] === "ExactRootClassification",
  CodexTripleRootStrip`TRDecomposeStripRecord[record, frame],
  classification];

If[StringQ[reportFile],
  If[! DirectoryQ[DirectoryName[reportFile]],
    CreateDirectory[DirectoryName[reportFile],
      CreateIntermediateDirectories -> True]];
  temporary = reportFile <> ".tmp";
  Put[result, temporary];
  RenameFile[temporary, reportFile, OverwriteTarget -> True]];

Print["TRCLASSIFY family=", family,
  " strip=", {Lookup[record, "Sector", None],
    Lookup[record, "LowerSector", None]},
  " status=", Lookup[result, "Status", None],
  " root_indices=", InputForm[Lookup[result, "RootIndices", {}]],
  " root_count=", Lookup[result, "RootCount", 0],
  " channels=", Lookup[result, "ChannelCount", Missing["NotRun"]],
  " roundtrip=", Lookup[result, "RoundTripExact", Missing["NotRun"]]];

Exit[If[MemberQ[{"ExactRootClassification", "ExactChannelDecomposition"},
  Lookup[result, "Status", None]], 0, 1]];
