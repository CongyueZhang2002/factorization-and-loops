$feynFacetRoot = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{$feynFacetRoot, "FeynFacet", "Private",
  "EpsFormStrip.wl"}]];

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_7_input.wl";
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
  "CF254_9_7_residue_data.wl"}];

record = Get[recordPath];
strip = record["Strip"];
variables = record["Variables"];
epsilon = record["Regulator"];

{seconds, residueData} = AbsoluteTiming[
  epsFormStripBuildResidueCompatibility[
    strip, variables, epsilon, 8]
];

Print[<|
  "ResultHead" -> Head[residueData],
  "FailureStage" -> $epsFormStripResidueFailureStage,
  "Seconds" -> seconds
|>];
If[! AssociationQ[residueData], Exit[1]];
Print[<|
  "AlphabetCount" -> Length[residueData["Alphabet"]],
  "FreeResidueCount" -> Length[residueData["FreeResidues"]],
  "EquationCount" -> residueData["EquationCount"],
  "Timings" -> KeyTake[residueData, {
    "CompatibilitySeconds", "EquationSeconds", "SolveSeconds",
    "NormalizationSeconds", "ExactCheckSeconds"}]
|>];
Put[residueData, outputPath];
Print["Saved: ", outputPath];
