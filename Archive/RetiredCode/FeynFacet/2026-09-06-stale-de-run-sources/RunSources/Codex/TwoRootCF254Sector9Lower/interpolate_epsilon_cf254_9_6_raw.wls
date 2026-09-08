#!/usr/bin/env wolframscript

$FacetInputPrefixOverride = "CF254_9_6_raw";
$FacetOutputPrefixOverride = "CF254_9_6_raw";

Get[FileNameJoin[{
  DirectoryName[$InputFileName],
  "interpolate_epsilon_cf254_9_7.wls"}]];
