#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["Usage: SummarizeCompactTransportCampaign.wls " <>
    "CAMPAIGN_DIRECTORY OUTPUT.wl"];
  Exit[64]
];

campaignDirectory = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
If[! DirectoryQ[campaignDirectory], Exit[66]];

readGlobal[file_] := Block[
  {$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
  Quiet[Check[Get[file], $Failed]]
];

files = Sort[FileNames["projected_transport_CF*.wl", campaignDirectory]];
files = Select[files,
  ! StringContainsQ[FileBaseName[#], "_summary" | "_progress"] &];
records = readGlobal /@ files;

rows = MapThread[
  Function[{file, record},
    If[! AssociationQ[record],
      <|"File" -> file, "Status" -> "Unreadable", "Exact" -> False|>,
      reachability = Lookup[record, "ObservableReachabilityCertificate", <||>];
      automaton = Lookup[record, "CompactTransportAutomaton", <||>];
      certificates = Lookup[record, "Certificates", <||>];
      <|
        "Family" -> Lookup[record, "Family", Missing[]],
        "Status" -> Lookup[record, "Status", Missing[]],
        "Exact" ->
          Lookup[record, "Status", None] ===
            "ExactProjectedTransportUpToConstants" &&
          AssociationQ[certificates] &&
          And @@ (TrueQ /@ Values[certificates]),
        "PhysicalDemandPairs" ->
          Length[Lookup[record, "PhysicalDemandPairs", {}]],
        "BoundaryCoordinates" ->
          Lookup[record, "BoundaryCoordinates", Missing[]],
        "RequestedMaximumWeight" ->
          Lookup[record, "MaximumWeight", Missing[]],
        "ObservableMaximumFirstWeight" ->
          Lookup[record, "ObservableMaximumFirstSegmentWeight", Missing[]],
        "ReachableRanksByExactWeight" ->
          Lookup[reachability, "ObservableRankByExactWeight",
            Lookup[reachability, "ReachableRankByExactWeight", Missing[]]],
        "DemandedMapIsZeroByExactWeight" ->
          Lookup[reachability, "DemandedMapIsZero", Missing[]],
        "FirstAlphabetSize" -> If[AssociationQ[automaton],
          Length[Lookup[automaton, "FirstAlphabetIndices", {}]], Missing[]],
        "SecondAlphabetSize" -> If[AssociationQ[automaton],
          Length[Lookup[automaton, "SecondAlphabetIndices", {}]], Missing[]],
        "StageSeconds" -> Lookup[record, "StageSeconds", Missing[]],
        "TransportSeconds" -> Lookup[record, "TransportSeconds", Missing[]],
        "MaxMemoryUsedBytes" -> Lookup[record, "MaxMemoryUsedBytes", Missing[]],
        "ArtifactBytes" -> FileByteCount[file],
        "File" -> file,
        "SHA256" -> FileHash[file, "SHA256", "HexString"]
      |>
    ]],
  {files, records}
];

result = <|
  "Status" -> If[rows =!= {} && AllTrue[rows, TrueQ[Lookup[#, "Exact", False]] &],
    "AllExact", "SomeIncomplete"],
  "Representation" -> "ExactCompactTwoSegmentAutomaton",
  "Families" -> Lookup[rows, "Family", {}],
  "FamilyCount" -> Length[rows],
  "Rows" -> rows,
  "TotalTransportSeconds" -> Total[Cases[
    Lookup[rows, "TransportSeconds", {}], _?NumberQ]],
  "TotalArtifactBytes" -> Total[Cases[
    Lookup[rows, "ArtifactBytes", {}], _Integer]],
  "CampaignDirectory" -> campaignDirectory
|>;

temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print[InputForm[result]];
If[Lookup[result, "Status", None] =!= "AllExact", Exit[1]];
