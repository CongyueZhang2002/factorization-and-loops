#!/usr/bin/env wolframscript

$FacetSampleScriptOverride = FileNameJoin[{
  DirectoryName[$InputFileName],
  "sample_rank_by_points_cf254_9_6.wls"}];
$FacetOutputPrefixOverride = "CF254_9_6_raw";

Get[FileNameJoin[{
  DirectoryName[$InputFileName],
  "run_epsilon_samples_parallel_cf254_9_7.wls"}]];
