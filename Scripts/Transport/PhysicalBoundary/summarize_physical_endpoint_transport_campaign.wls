#!/usr/bin/env wolframscript

$AllowInternet = False;
$HistoryLength = 0;
repositoryRoot = DirectoryName[ExpandFileName[$InputFileName], 4];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 1,
  Print["Usage: summarize_physical_endpoint_transport_campaign.wls " <>
    "<physical-endpoint-output-directory>"];
  Exit[64]];
outputDirectory = ExpandFileName[First[arguments]];
modeDirectory = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical", "PhysicalBoundaryModes"}];

familyFrom[file_, prefix_] := StringReplace[FileBaseName[file], prefix -> ""];
expectedFamilies = SortBy[
  familyFrom[#, "boundary_mode_"] & /@
    FileNames["boundary_mode_CF*.wl", modeDirectory],
  ToExpression@StringDrop[#, 2] &];
resultFiles = FileNames["physical_endpoint_transport_CF*.wl",
  outputDirectory];
records = Quiet[Check[Get[#], $Failed]] & /@ resultFiles;
accepted = Select[records, AssociationQ[#] &&
    Lookup[#, "Status", None] === "GradedPhysicalEndpointTransportBuilt" &&
    Lookup[#, "CampaignRecordStatus", None] ===
      "PhysicalEndpointTransportAcceptedV1" &];
acceptedFamilies = SortBy[Lookup[accepted, "Family", {}],
  ToExpression@StringDrop[#, 2] &];
missingFamilies = Complement[expectedFamilies, acceptedFamilies];

coordinateKey[coordinate_] := With[
  {key = Lookup[coordinate, "RealizationKey",
      Lookup[coordinate, "PeriodID", Missing[]]],
   order = Lookup[coordinate, "EpsilonOrder", Missing[]]},
  HoldComplete[key, order]];
coordinates = DeleteDuplicatesBy[
  Flatten[Lookup[accepted, "PeriodCoordinates", {}]], coordinateKey];
seriesKeys = DeleteDuplicates[Lookup[coordinates, "RealizationKey",
  Lookup[coordinates, "PeriodID", Missing[]]]];
ledgers = Flatten[Lookup[accepted, "Stage3NeedsLedger", {}]];
modeKey[entry_] := With[{id = Lookup[entry, "PeriodID", Missing[]]},
  HoldComplete[id]];
ledgerGroups = GatherBy[ledgers, modeKey];
mergedLedger = Map[Function[group, Join[First[group], <|
      "AffectedBoundaryCoordinates" -> DeleteDuplicates@Flatten[
        Lookup[group, "AffectedBoundaryCoordinates", {}]]|>]], ledgerGroups];
knownZeroModes = Select[mergedLedger,
  Lookup[#, "Status", None] === "KnownZero" &];
unevaluatedModes = Select[mergedLedger,
  Lookup[#, "Status", None] === "Unevaluated" &&
    Lookup[#, "AffectedBoundaryCoordinates", {}] =!= {} &];

summary = <|
  "Status" -> If[missingFamilies === {},
    "PhysicalEndpointTransportCampaignComplete",
    "PhysicalEndpointTransportCampaignIncomplete"],
  "ExpectedFamilies" -> expectedFamilies,
  "AcceptedFamilies" -> acceptedFamilies,
  "MissingFamilies" -> missingFamilies,
  "FamilyCount" -> Length[acceptedFamilies],
  "ModeRealizationCount" -> Length[mergedLedger],
  "KnownZeroModeRealizations" -> Lookup[knownZeroModes, "PeriodID", {}],
  "UnevaluatedModeRealizations" -> Lookup[unevaluatedModes, "PeriodID", {}],
  "Stage3SeriesCount" -> Length[seriesKeys],
  "Stage3CoordinateCount" -> Length[coordinates],
  "Stage3Coordinates" -> coordinates,
  "Stage3NeedsLedger" -> mergedLedger,
  "EndpointConnectionDataSources" -> Counts[
    Lookup[accepted, "EndpointConnectionDataSource", Missing[]]],
  "TotalFamilyBuildSeconds" -> Total[Lookup[accepted, "TotalSeconds", 0]],
  "MaximumFamilyBuild" -> If[accepted === {}, Missing["NoFamilies"],
    With[{record = First@TakeLargestBy[accepted,
          Lookup[#, "TotalSeconds", 0] &, 1]},
      <|"Family" -> Lookup[record, "Family", Missing["Family"]],
        "Seconds" -> Lookup[record, "TotalSeconds", Missing["Seconds"]]|>]]|>;
temporary = FileNameJoin[{outputDirectory,
  "campaign_summary.wl.tmp-" <> ToString[$ProcessID]}];
Put[summary, temporary];
RenameFile[temporary, FileNameJoin[{outputDirectory,
  "campaign_summary.wl"}], OverwriteTarget -> True];
Print[InputForm[KeyTake[summary, {"Status", "FamilyCount",
  "ModeRealizationCount", "Stage3SeriesCount", "Stage3CoordinateCount",
  "EndpointConnectionDataSources", "TotalFamilyBuildSeconds",
  "MaximumFamilyBuild", "MissingFamilies"}]]];
If[summary["Status"] =!= "PhysicalEndpointTransportCampaignComplete",
  Exit[1]];
