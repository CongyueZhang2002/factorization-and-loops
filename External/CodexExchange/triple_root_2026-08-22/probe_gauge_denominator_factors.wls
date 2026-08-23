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
  {"Family", "Sector", "LowerSector", "Variables", "Regulator", "Strip"}];
baseline = FeynFacet`PrepareEpsFormStripSampling[solveRecord];
If[! AssociationQ[baseline],
  Print["TRDENOM FAIL preparation"];
  Exit[65]];
alphabet = baseline["Alphabet"];
baselineDenominator = baseline["GaugeDenominator"];
offsets = {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
  {2, 1}, {1, 2}, {2, 2}};
prime = 1000003;
epsilonValue = 1/7;

(* Single letters first, then pair products.  The baseline factor 1 is
   included to make this a self-contained regression record. *)
candidates = Join[
  {<|"Indices" -> {}, "Factor" -> 1|>},
  Table[<|"Indices" -> {i}, "Factor" -> alphabet[[i]]|>,
    {i, Length[alphabet]}],
  Flatten[Table[
    <|"Indices" -> {i, j}, "Factor" -> Together[alphabet[[i]] alphabet[[j]]]|>,
    {i, Length[alphabet]}, {j, i + 1, Length[alphabet]}], 1]];

results = {};
Do[
  candidateRecord = If[candidate["Indices"] === {}, solveRecord,
    Join[solveRecord,
      <|"GaugeDenominatorFactor" -> candidate["Factor"]|>]];
  preparation = FeynFacet`PrepareEpsFormStripSampling[candidateRecord];
  If[! AssociationQ[preparation],
    AppendTo[results, Join[candidate,
      <|"Status" -> "PreparationFailed"|>]];
    Continue[]];
  probes = {};
  Do[
    sample = Quiet[FeynFacet`SampleEpsFormStripAffine[
      candidateRecord, epsilonValue, prime,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"],
      "NumeratorDegreeOffset" -> offset,
      "Support" -> "Rectangle",
      "DiscoverPlan" -> False]];
    AppendTo[probes, <|"Offset" -> offset,
      "Status" -> If[AssociationQ[sample],
        If[TrueQ[Lookup[sample, "Consistent", False]], "Consistent",
          "Inconsistent"], "SampleFailed"],
      "MatrixDimensions" -> If[AssociationQ[sample],
        Lookup[sample, "MatrixDimensions", Missing[]], Missing[]],
      "Rank" -> If[AssociationQ[sample],
        Lookup[sample, "Rank", Missing[]], Missing[]],
      "AugmentedRank" -> If[AssociationQ[sample],
        Lookup[sample, "AugmentedRank", Missing[]], Missing[]]|>];
    If[AssociationQ[sample] && TrueQ[Lookup[sample, "Consistent", False]],
      Break[]],
    {offset, offsets}];
  candidateResult = Join[candidate,
    <|"GaugeDenominator" -> preparation["GaugeDenominator"],
      "GaugeDenominatorDegrees" -> preparation["DenominatorDegrees"],
      "Probes" -> probes,
      "Consistent" -> AnyTrue[probes,
        Lookup[#1, "Status", None] === "Consistent" &]|>];
  AppendTo[results, candidateResult];
  Print["TRDENOM indices=", candidate["Indices"],
    " degrees=", preparation["DenominatorDegrees"],
    " result=", Last[probes]["Status"],
    " offset=", Last[probes]["Offset"]];
  If[TrueQ[candidateResult["Consistent"]], Break[]],
  {candidate, candidates}];

output = <|"Source" -> recordFile,
  "Prime" -> prime, "EpsilonValue" -> epsilonValue,
  "Alphabet" -> alphabet,
  "BaselineGaugeDenominator" -> baselineDenominator,
  "Results" -> results,
  "FirstConsistent" -> SelectFirst[results,
    TrueQ[Lookup[#1, "Consistent", False]] &, Missing["NotFound"]]|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];

Print["TRDENOM RESULT first_consistent=",
  InputForm[output["FirstConsistent"] /. association_Association :>
    KeyTake[association, {"Indices", "Factor", "GaugeDenominatorDegrees",
      "Consistent"}]]];
