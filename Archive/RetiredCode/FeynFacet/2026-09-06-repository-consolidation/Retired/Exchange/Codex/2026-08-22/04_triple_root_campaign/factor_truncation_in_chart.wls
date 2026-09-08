#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
stateFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[recordFile];
state = Get[stateFile];
epsilon = record["Regulator"];
sourceVariables = record["SourceVariables"];
chartVariables = record["Variables"];
sector = state["Sector"];
dimension = Last[state["Ranges"][[sector]]];
sourceConnection = state["A"][[All, 1 ;; dimension, 1 ;; dimension]];

epsFactoredQ[connection_] := AllTrue[Flatten[connection],
  TrueQ[Together[#1] === 0] || FreeQ[Together[#1/epsilon], epsilon] &];

rekeyed = record["RekeyedChart"];
data = FeynFacet`Private`masterTransportChartData[
  rekeyed, sourceVariables];
components = Map[
  Map[Together, #1 /. data["Subst"], {2}] &, sourceConnection];
chartConnection = FeynFacet`Private`masterTransportPullBackOneForm[
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
chartConnection = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    chartConnection, chartBranchRoots, rootImages], {3}];
rationalQ = FreeQ[chartConnection,
  Power[_, exponent_Rational /; Denominator[exponent] === 2]];

If[rationalQ,
  {seconds, factor} = AbsoluteTiming[
    FeynFacet`FactorFamilyRegulatorDependence[
      chartConnection, chartVariables, epsilon,
      "TimeLimit" -> 600, "Verbose" -> True]],
  seconds = 0.;
  factor = <|"Status" -> "ChartStillAlgebraic"|>];

sourceCheck = False;
If[AssociationQ[factor] && Lookup[factor, "Status", None] === "OK",
  sourceFactored = Table[
    FeynFacet`Private`familyRegulatorConjugate[
      factor["Inverse"], sourceConnection[[mu]],
      factor["Transformation"]], {mu, 2}];
  sourceCheck = epsFactoredQ[sourceFactored]];

output = <|"SourceRecord" -> recordFile,
  "SourceState" -> stateFile,
  "Sector" -> sector,
  "Dimension" -> dimension,
  "RootIndices" -> record["RootIndices"],
  "ChartRational" -> rationalQ,
  "BeforeEpsFactored" -> epsFactoredQ[sourceConnection],
  "Seconds" -> seconds,
  "Factor" -> If[AssociationQ[factor],
    KeyDrop[factor, {"Connection"}], factor],
  "SourceFrameEpsFactored" -> sourceCheck|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRFACTOR sector=", sector,
  " dimension=", dimension,
  " chart_rational=", rationalQ,
  " before_eps=", output["BeforeEpsFactored"],
  " status=", If[AssociationQ[factor],
    Lookup[factor, "Status", None], Head[factor]],
  " source_check=", sourceCheck,
  " seconds=", Round[seconds, .01]];
