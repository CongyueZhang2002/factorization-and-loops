#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
rationalRecordFile = ExpandFileName[arguments[[2]]];
stateFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[rationalRecordFile];
state = Get[stateFile];
ranges = state["Ranges"];
sourceVariables = record["SourceVariables"];
epsilon = record["Regulator"];

(* The failed strip is (8,5); the immediately preceding solved gauge was
   (8,6), so its constant freedom feeds the lower connection A_(6,5). *)
sourcePair = state["A"][[All, ranges[[6]], ranges[[5]]]];
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
    TrueQ[Together[#1["RootSquare"] - usedRoots[[i, "RootSquare"]]] === 0] &,
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

dimensions = Dimensions[chartPair[[1]]];
zeroE = ConstantArray[0, {2, dimensions[[1]], dimensions[[1]]}];
zeroC = ConstantArray[0, {2, dimensions[[2]], dimensions[[2]]}];
couplingAlphabet = FeynFacet`Private`epsFormStripAlphabet[
  {zeroE, zeroC, chartPair}, record["Variables"], epsilon];
solveRecord = KeyTake[record,
  {"Family", "Sector", "LowerSector", "Variables", "Regulator", "Strip"}];
baseline = FeynFacet`PrepareEpsFormStripSampling[solveRecord];
candidateRecord = Join[solveRecord,
  <|"ExtraLetters" -> couplingAlphabet|>];
preparation = FeynFacet`PrepareEpsFormStripSampling[candidateRecord];

offsets = {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
  {2, 1}, {1, 2}, {2, 2}, {3, 0}, {0, 3}, {3, 1}, {1, 3},
  {3, 2}, {2, 3}, {3, 3}};
probes = {};
Do[
  sample = Quiet[FeynFacet`SampleEpsFormStripAffine[
    candidateRecord, 1/7, 1000003,
    "Preparation" -> preparation,
    "ExpectedFingerprint" -> preparation["Fingerprint"],
    "NumeratorDegreeOffset" -> offset,
    "Support" -> "Rectangle",
    "DiscoverPlan" -> False]];
  probe = <|"Offset" -> offset,
    "Status" -> If[AssociationQ[sample] &&
        TrueQ[Lookup[sample, "Consistent", False]],
      "Consistent", "Inconsistent"],
    "MatrixDimensions" -> If[AssociationQ[sample],
      sample["MatrixDimensions"], Missing[]],
    "Rank" -> If[AssociationQ[sample], sample["Rank"], Missing[]],
    "AugmentedRank" -> If[AssociationQ[sample],
      sample["AugmentedRank"], Missing[]]|>;
  AppendTo[probes, probe];
  Print["TRCOUPLING offset=", offset, " status=", probe["Status"],
    " ranks=", {probe["Rank"], probe["AugmentedRank"]}];
  If[probe["Status"] === "Consistent", Break[]],
  {offset, offsets}];

output = <|"SourceRecord" -> rationalRecordFile,
  "State" -> stateFile,
  "SourceBlockPair" -> {6, 5},
  "ChartPair" -> chartPair,
  "Rational" -> rationalQ,
  "BaselineAlphabet" -> baseline["Alphabet"],
  "CouplingAlphabet" -> couplingAlphabet,
  "ExpandedAlphabet" -> preparation["Alphabet"],
  "Probes" -> probes,
  "Consistent" -> AnyTrue[probes,
    Lookup[#1, "Status", None] === "Consistent" &]|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRCOUPLING RESULT rational=", rationalQ,
  " baseline_letters=", Length[baseline["Alphabet"]],
  " coupling_letters=", Length[couplingAlphabet],
  " expanded_letters=", Length[preparation["Alphabet"]],
  " consistent=", output["Consistent"]];
