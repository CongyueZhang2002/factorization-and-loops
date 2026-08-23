#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 6, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
rationalRecordFile = ExpandFileName[arguments[[2]]];
stateFile = ExpandFileName[arguments[[3]]];
sourceSector = ToExpression[arguments[[4]]];
lowerSector = ToExpression[arguments[[5]]];
outputFile = ExpandFileName[arguments[[6]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[rationalRecordFile];
state = Get[stateFile];
ranges = state["Ranges"];
sourceVariables = record["SourceVariables"];
epsilon = record["Regulator"];

sourcePair = state["A"][[All, ranges[[sourceSector]],
  ranges[[lowerSector]]]];
rekeyed = record["RekeyedChart"];
data = FeynFacet`Private`masterTransportChartData[
  rekeyed, sourceVariables];
components = Map[
  Map[Together, #1 /. data["Subst"], {2}] &, sourcePair];
chartPair = FeynFacet`Private`masterTransportPullBackOneForm[
  components[[1]], components[[2]], data["Jacobian"]];

frame = FeynFacet`TransportFamilyChart[record["Family"]];
allRoots = FeynFacet`Private`transportChartCurrentRoots[
  frame, sourceVariables];
usedRoots = allRoots[[record["RootIndices"]]];
chartRoots = Lookup[rekeyed, "Roots", {}];
rootImages = Table[
  matching = SelectFirst[chartRoots,
    TrueQ[Together[#1["RootSquare"] -
      usedRoots[[i, "RootSquare"]]] === 0] &,
    Missing["RootNotRationalized"]];
  If[MissingQ[matching], matching, matching["Root"]],
  {i, Length[usedRoots]}];
chartBranchRoots = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
  usedRoots];
chartPair = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    chartPair, chartBranchRoots, rootImages], {3}];
rationalQ = FreeQ[chartPair,
  Power[_, exponent_Rational /; Denominator[exponent] === 2]];

dimensions = Dimensions[chartPair];
zeroE = ConstantArray[0,
  {2, dimensions[[2]], dimensions[[2]]}];
zeroC = ConstantArray[0,
  {2, dimensions[[3]], dimensions[[3]]}];
couplingAlphabet = FeynFacet`Private`epsFormStripAlphabet[
  {zeroE, zeroC, chartPair}, record["Variables"], epsilon];

output = <|"SourceRecord" -> rationalRecordFile,
  "State" -> stateFile,
  "SourceBlockPair" -> {sourceSector, lowerSector},
  "ChartPair" -> chartPair,
  "Dimensions" -> dimensions,
  "Rational" -> rationalQ,
  "CouplingAlphabet" -> couplingAlphabet|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRCOUPLING EXTRACT pair=", {sourceSector, lowerSector},
  " dimensions=", dimensions,
  " rational=", rationalQ,
  " letters=", Length[couplingAlphabet]];
