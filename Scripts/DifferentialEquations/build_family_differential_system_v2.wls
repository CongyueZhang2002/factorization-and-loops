#!/usr/bin/env wolframscript

scriptRoot = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{scriptRoot, "Scripts", "DifferentialEquations",
  "FamilyDifferentialSystemV2.wl"}]];

parsed = FeynFacetCampaign`DifferentialEquations`ParseFamilyDifferentialSystemCLIArguments[
  Rest[$ScriptCommandLine]];
If[Lookup[parsed, "Status", None] === "HelpRequested",
  Print[parsed["Usage"]]; Exit[0]];
If[Lookup[parsed, "Status", None] =!=
    "FamilyDifferentialSystemCLIArgumentsParsed",
  Print[InputForm[parsed]]; Exit[2]];

Get[FileNameJoin[{scriptRoot, "Addon", "Load", "LoadFACET.wl"}]];
result = FeynFacetCampaign`DifferentialEquations`BuildFamilyDifferentialSystemV2[
  parsed];
If[! FeynFacetCampaign`DifferentialEquations`FamilyDifferentialSystemV2Q[
    Lookup[result, "FamilyDifferentialSystem", <||>]],
  Print[InputForm[result]]; Exit[1]];

Print[InputForm[<|
  "Status" -> result["Status"],
  "Family" -> result["FamilyDifferentialSystem", "Family"],
  "Dimension" -> Length[result["FamilyDifferentialSystem",
    "OriginalMasterIntegralBasis"]],
  "FlatnessValidationMethod" ->
    result["FamilyDifferentialSystem", "Validation",
      "ConnectionFlatness", "Method"],
  "FamilyDifferentialSystemFile" -> result["FamilyDifferentialSystemFile"],
  "ComputationMetricsFile" -> result["ComputationMetricsFile"],
  "PhaseTimings" -> result["ComputationMetrics", "PhaseTimings"]|>]];
