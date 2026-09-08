$FacetInputPrefixOverride = "CF254_9_6_raw";
$FacetOutputPrefixOverride = "CF254_9_6_raw";
$FacetRawResiduesOverride = True;
$FacetRecordPathOverride =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl";
$FacetCheckpointPathOverride =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_strip_state.wl";

Get[FileNameJoin[{DirectoryName[$InputFileName],
  "lift_and_check_cf254_9_7.wls"}]];
