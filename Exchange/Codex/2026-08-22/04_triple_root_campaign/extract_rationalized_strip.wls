#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: extract_rationalized_strip.wls <project-root> <input.wl> <output.wl> [obstruction-output.wl]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
obstructionFile = If[Length[arguments] >= 4,
  ExpandFileName[arguments[[4]]], None];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[inputFile];
family = record["Family"];
variables = record["Variables"];
epsilon = record["Regulator"];
strip = record["Strip"];
frame = FeynFacet`TransportFamilyChart[family];

allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
classification = FeynFacet`Private`transportChartRootIndices[strip, allRoots];
rootIndices = classification["RootIndices"];
usedRoots = allRoots[[rootIndices]];
rootSquares = Lookup[usedRoots, "RootSquare", {}];
If[Length[rootIndices] > 2,
  Print["TRRATIONALIZE STOP root_count=", Length[rootIndices]];
  Exit[69]];

chart = FeynFacet`TransportRootSetChart[rootSquares, variables];
If[MissingQ[chart],
  Print["TRRATIONALIZE FAIL no_chart roots=", rootIndices];
  Exit[70]];
chartVariables = {
  Symbol["CodexTripleRootScratch`chartX"],
  Symbol["CodexTripleRootScratch`chartY"]};
rekeyed = FeynFacet`Private`transportChartRekey[
  chart, variables, chartVariables];
data = FeynFacet`Private`masterTransportChartData[rekeyed, variables];
If[Lookup[data, "Status", None] =!= "OK",
  Print["TRRATIONALIZE FAIL chart_data=", Lookup[data, "Status", None]];
  Exit[71]];

chartStrip = FeynFacet`Private`transportChartPullBackStrip[strip, data];
chartRoots = Lookup[rekeyed, "Roots", {}];
rootImages = Table[
  matching = SelectFirst[chartRoots,
    TrueQ[Together[#1["RootSquare"] - usedRoots[[i, "RootSquare"]]] === 0] &,
    Missing["RootNotRationalized"]];
  If[MissingQ[matching], matching, matching["Root"]],
  {i, Length[usedRoots]}];
If[AnyTrue[rootImages, MissingQ],
  Print["TRRATIONALIZE FAIL root_image"];
  Exit[72]];
chartBranchRoots = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]],
    "Root" -> Sqrt[Together[#1["RootSquare"] /. data["Subst"]]]|> &,
  usedRoots];
chartStrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    chartStrip, chartBranchRoots, rootImages], {4}];

rationalQ = FreeQ[chartStrip,
  Power[_, exponent_Rational /; Denominator[exponent] === 2]];
chartRecord = <|"Family" -> family,
  "Sector" -> record["Sector"],
  "LowerSector" -> record["LowerSector"],
  "Variables" -> chartVariables,
  "Regulator" -> epsilon,
  "Strip" -> chartStrip,
  "SourceInput" -> inputFile,
  "SourceVariables" -> variables,
  "RootIndices" -> rootIndices,
  "RootSquares" -> rootSquares,
  "Chart" -> chart,
  "RekeyedChart" -> rekeyed,
  "ChartData" -> KeyTake[data,
    {"Status", "Subst", "Jacobian", "JacobianDet"}],
  "Rational" -> rationalQ|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[chartRecord, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];

If[StringQ[obstructionFile],
  {obstructionSeconds, obstruction} = AbsoluteTiming[
    Quiet[TimeConstrained[
      FeynFacet`EpsFormStripObstruction[chartRecord,
        "MaximumOrder" -> 4], 900, $TimedOut]]];
  obstructionRecord = <|"Source" -> outputFile,
    "Seconds" -> obstructionSeconds,
    "Result" -> obstruction|>;
  temporary = obstructionFile <> ".tmp";
  Put[obstructionRecord, temporary];
  RenameFile[temporary, obstructionFile, OverwriteTarget -> True]];

Print["TRRATIONALIZE family=", family,
  " strip=", {record["Sector"], record["LowerSector"]},
  " roots=", InputForm[rootIndices],
  " chart=", chart["Name"],
  " rational=", rationalQ,
  If[StringQ[obstructionFile],
    " obstruction=" <> ToString[If[AssociationQ[obstruction],
      KeyTake[obstruction, {"Status", "Order", "MissingLetters",
        "GaugeNumeratorDegrees"}], obstruction], InputForm], ""]];

Exit[If[TrueQ[rationalQ], 0, 1]];
