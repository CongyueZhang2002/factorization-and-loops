#!/usr/bin/env wolframscript

If[Length[$ScriptCommandLine] =!= 5,
  Print["usage: wolframscript -file build_coefficient_presentation_v2.wls " <>
    "FAMILY_DIFFERENTIAL_SYSTEM SPECIFICATIONS OUTPUT OVERWRITE"];
  Exit[64]];

scriptRoot = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{scriptRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{scriptRoot, "Scripts", "DifferentialEquations",
  "CoefficientPresentationV2.wl"}]];

overwrite = Switch[ToLowerCase[$ScriptCommandLine[[5]]],
  "true", True, "false", False, _,
  Print["OVERWRITE must be true or false"]; Exit[64]];

result =
  FeynFacetCampaign`DifferentialEquations`BuildCoefficientPresentationV2[
    $ScriptCommandLine[[2]], $ScriptCommandLine[[3]],
    $ScriptCommandLine[[4]], "RepositoryRoot" -> scriptRoot,
    "Overwrite" -> overwrite];
Print[InputForm[KeyDrop[result, "CoefficientPresentation"]]];
If[Lookup[result, "Status", None] =!= "CoefficientPresentationWritten",
  Exit[1]];
