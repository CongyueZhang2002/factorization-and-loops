#!/usr/bin/env wolframscript

$FacetRecordPathOverride =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl";
$FacetResiduePathOverride = FileNameJoin[{
  DirectoryName[$InputFileName], "CF254_9_6_residue_data.wl"}];
$FacetOutputPrefixOverride = "CF254_9_6_raw";
$FacetRawResiduesOverride = True;

Get[FileNameJoin[{
  DirectoryName[$InputFileName],
  "sample_rank_by_points_cf254_9_7.wls"}]];
