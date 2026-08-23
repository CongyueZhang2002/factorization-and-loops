#!/usr/bin/env wolframscript

$HistoryLength = 0;

repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 5,
  Print[
    "Usage: build_observable_transport_manifest.wls " <>
    "<differential-system-directory> <valuations.wl> <manifest.tsv> " <>
    "<report.wl> <epsilon-form-directory> ... [--card=<card.wl>]"
  ];
  Exit[64]
];

cardArguments = Select[arguments, StringStartsQ[#, "--card="] &];
If[Length[cardArguments] > 1, Exit[64]];
card = If[cardArguments === {}, None,
  StringDrop[First[cardArguments], StringLength["--card="]]];
arguments = Select[arguments, ! StringStartsQ[#, "--card="] &];
If[Length[arguments] < 5, Exit[64]];

{differentialDirectory, valuationsFile, manifestFile, reportFile} =
  Take[arguments, 4];
epsilonDirectories = Drop[arguments, 4];

result = BuildObservableTransportManifest[
  epsilonDirectories, differentialDirectory, valuationsFile, manifestFile,
  "Card" -> card, "ReportFile" -> reportFile];

Print["Exact epsilon forms: ", Lookup[result, "ExactFamilyCount", 0],
  "/", Lookup[result, "DifferentialFamilyCount", 0]];
If[Lookup[result, "MissingFamilies", {}] =!= {},
  Print["Missing exact families: ", result["MissingFamilies"]]];
If[Lookup[result, "Status", None] =!= "CompleteExactInventory", Exit[1]];
