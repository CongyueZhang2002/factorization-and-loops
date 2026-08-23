#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[recordFile];
solveRecord = KeyTake[record,
  {"Family", "Sector", "LowerSector", "Variables", "Regulator",
    "Strip"}];
{e, c, bbar} = solveRecord["Strip"];
variables = solveRecord["Variables"];
epsilon = solveRecord["Regulator"];

{seconds, compatibility} = AbsoluteTiming[
  Quiet[FeynFacet`Private`epsFormStripBuildResidueCompatibility[
    {e, c, bbar}, variables, epsilon, 1]]];
stage = FeynFacet`Private`$epsFormStripResidueFailureStage;
summary = If[AssociationQ[compatibility],
  KeyTake[compatibility,
    {"Alphabet", "FreeResidues", "EquationCount",
      "CompatibilityZero", "CompatibilitySeconds", "EquationSeconds",
      "SolveSeconds", "NormalizationSeconds", "ExactCheckSeconds"}],
  compatibility];
output = <|"Source" -> recordFile,
  "Seconds" -> seconds,
  "FailureStage" -> stage,
  "Succeeded" -> AssociationQ[compatibility],
  "Summary" -> summary|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRRESIDUE succeeded=", output["Succeeded"],
  " stage=", InputForm[stage],
  " seconds=", Round[seconds, .01],
  " summary=", InputForm[If[AssociationQ[summary],
    KeyDrop[summary, {"Alphabet", "FreeResidues"}], summary]]];
