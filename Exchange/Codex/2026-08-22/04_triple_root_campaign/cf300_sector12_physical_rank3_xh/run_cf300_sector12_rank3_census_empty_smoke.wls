#!/usr/bin/env wolframscript

SetEnvironment["FACET_CENSUS_ALLOW_EMPTY" -> "True"];
Get[FileNameJoin[{DirectoryName[$InputFileName],
  "run_cf300_sector12_rank3_census.wls"}]];
