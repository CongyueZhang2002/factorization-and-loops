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
baseline = FeynFacet`PrepareEpsFormStripSampling[solveRecord];
alphabet = baseline["Alphabet"];
factor = Times @@ alphabet;
candidateRecord = Join[solveRecord,
  <|"GaugeDenominatorFactor" -> factor|>];
preparation = FeynFacet`PrepareEpsFormStripSampling[candidateRecord];
offsets = {{0, 0}, {2, 2}, {4, 4}, {6, 6}};
probes = {};

Do[
  {seconds, sample} = AbsoluteTiming[Quiet[
    FeynFacet`SampleEpsFormStripAffine[
      candidateRecord, 1/7, 1000003,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"],
      "NumeratorDegreeOffset" -> offset,
      "Support" -> "Rectangle",
      "SolveAffineSystem" -> False,
      "DiscoverPlan" -> False]]];
  probe = <|"Offset" -> offset,
    "Status" -> If[AssociationQ[sample],
      If[TrueQ[Lookup[sample, "Consistent", False]],
        "Consistent", "Inconsistent"], "SampleFailed"],
    "Seconds" -> seconds,
    "MatrixDimensions" -> If[AssociationQ[sample],
      Lookup[sample, "MatrixDimensions", Missing[]], Missing[]],
    "Rank" -> If[AssociationQ[sample],
      Lookup[sample, "Rank", Missing[]], Missing[]],
    "AugmentedRank" -> If[AssociationQ[sample],
      Lookup[sample, "AugmentedRank", Missing[]], Missing[]],
    "Nullity" -> If[AssociationQ[sample],
      Lookup[sample, "Nullity", Missing[]], Missing[]]|>;
  AppendTo[probes, probe];
  Print["TRFULLDEN offset=", offset,
    " dimensions=", probe["MatrixDimensions"],
    " ranks=", {probe["Rank"], probe["AugmentedRank"]},
    " nullity=", probe["Nullity"],
    " status=", probe["Status"],
    " seconds=", Round[seconds, .01]];
  If[probe["Status"] === "Consistent", Break[]],
  {offset, offsets}];

output = <|"Source" -> recordFile,
  "Prime" -> 1000003, "EpsilonValue" -> 1/7,
  "Alphabet" -> alphabet,
  "GaugeDenominatorFactor" -> factor,
  "GaugeDenominator" -> preparation["GaugeDenominator"],
  "GaugeDenominatorDegrees" -> preparation["DenominatorDegrees"],
  "Probes" -> probes,
  "FirstConsistent" -> SelectFirst[probes,
    Lookup[#1, "Status", None] === "Consistent" &,
    Missing["NotFound"]]|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRFULLDEN RESULT degrees=",
  preparation["DenominatorDegrees"],
  " first_consistent=", InputForm[output["FirstConsistent"]]];
