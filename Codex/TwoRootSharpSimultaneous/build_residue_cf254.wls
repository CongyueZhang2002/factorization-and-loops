$feynFacetRoot = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{$feynFacetRoot, "FeynFacet", "Private",
   "EpsFormStrip.wl"}]];

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_residue_data.wl"}];

record = Get[recordPath];
strip = record["Strip"];
variables = record["Variables"];
epsilon = record["Regulator"];

{seconds, residueData} = AbsoluteTiming[
  epsFormStripBuildResidueCompatibility[
    strip, variables, epsilon, 4]
];

Print["Result head: ", Head[residueData]];
Print["Failure stage: ", $epsFormStripResidueFailureStage];
Print["Total seconds: ", seconds];

If[AssociationQ[residueData],
  Print["Alphabet count: ", Length[residueData["Alphabet"]]];
  Print["Free residue count: ", Length[residueData["FreeResidues"]]];
  Print["Equation count: ", residueData["EquationCount"]];
  Print["Recorded timings: ",
    KeyTake[residueData, {
      "CompatibilitySeconds", "EquationSeconds", "SolveSeconds",
      "NormalizationSeconds", "ExactCheckSeconds"
    }]];
  Print["Alphabet:"];
  Scan[Print["  ", InputForm[#]] &, residueData["Alphabet"]];
  Put[residueData, outputPath];
  Print["Saved: ", outputPath, " (", FileByteCount[outputPath], " bytes)"]
];
