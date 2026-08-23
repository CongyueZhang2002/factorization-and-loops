#!/usr/bin/env wolframscript

$HistoryLength = 0;

bundleDirectory = DirectoryName[$InputFileName];
repositoryRoot = "/home/maxzhang/factorization-and-loops";
fixtureFile = FileNameJoin[{repositoryRoot,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "frozen_M0", "fixture_CF254_9_7.wl"}];
outputFile = FileNameJoin[{bundleDirectory,
  "m1_pilot_and_sample_result.wl"}];
pilotSystemCacheFile = FileNameJoin[{bundleDirectory,
  "m1_pilot_system_cache.wl"}];
laterSystemCacheFile = FileNameJoin[{bundleDirectory,
  "m1_later_system_cache.wl"}];

Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{bundleDirectory,
  "CodexM1ConstrainedAffinePrototype.wl"}]];

Off[Thread::tdlen];

record = Get[fixtureFile];
prime = 1000003;
epsilonSamples = (#/(# + 20)) & /@ Range[32];
offset = {1, 0};

Print["M1 pilot build: eps=", First[epsilonSamples], ", p=", prime];
pilotSystem = If[FileExistsQ[pilotSystemCacheFile],
  Print["Loading external pilot-system cache"];
  Get[pilotSystemCacheFile],
  With[{built = CodexM1BuildSampleSystem[
      record, First[epsilonSamples], prime,
      "NumeratorDegreeOffset" -> offset]},
    If[AssociationQ[built] && ! KeyExistsQ[built, "Status"],
      Put[built, pilotSystemCacheFile]];
    built]];
If[! AssociationQ[pilotSystem],
  Print["FAILED: pilot system build"]; Exit[1]];
If[KeyExistsQ[pilotSystem, "Status"],
  Print["FAILED: pilot system build: ", InputForm[pilotSystem]];
  Exit[1]];
Print["Captured system: ", InputForm[KeyTake[pilotSystem,
  {"MatrixDimensions", "NonzeroEntries", "GaugeUnknownCount",
   "FreeResidueCount", "CaptureMethod", "SetupSeconds",
   "PreprocessingSeconds", "SamplingSeconds"}]]];

Print["M1 pilot discovery"];
pilotDiscovery = CodexM1DiscoverPilotPlan[pilotSystem];
If[! AssociationQ[pilotDiscovery],
  Print["FAILED: pilot discovery"]; Exit[1]];
If[KeyExistsQ[pilotDiscovery, "Status"],
  Print["FAILED: pilot discovery: ", InputForm[pilotDiscovery]];
  Exit[1]];
plan = pilotDiscovery["Plan"];
pilotBaseline = pilotDiscovery["PilotSample"];

Print["M1 constrained solve on pilot matrix"];
pilotConstrained = CodexM1SolveConstrainedSample[pilotSystem, plan];
If[Lookup[pilotConstrained, "Status", "Failed"] =!= "Solved",
  Print["FAILED: constrained pilot solve: ",
    Lookup[pilotConstrained, "Status", "Unknown"]]; Exit[1]];
pilotAgreement = CodexM1CanonicalAgreementQ[
  pilotBaseline, pilotConstrained,
  plan["NormalizationColumns"], prime];

Print["M1 later build: eps=", epsilonSamples[[2]], ", p=", prime];
laterSystem = If[FileExistsQ[laterSystemCacheFile],
  Print["Loading external later-system cache"];
  Get[laterSystemCacheFile],
  With[{built = CodexM1BuildSampleSystem[
      record, epsilonSamples[[2]], prime,
      "NumeratorDegreeOffset" -> offset]},
    If[AssociationQ[built] && ! KeyExistsQ[built, "Status"],
      Put[built, laterSystemCacheFile]];
    built]];
If[! AssociationQ[laterSystem],
  Print["FAILED: later system build"]; Exit[1]];
If[KeyExistsQ[laterSystem, "Status"],
  Print["FAILED: later system build: ", InputForm[laterSystem]];
  Exit[1]];

Print["M1 baseline four-elimination solve for comparison"];
laterBaseline = CodexM1BaselineSolveSystem[laterSystem];
If[! AssociationQ[laterBaseline],
  Print["FAILED: later baseline solve"]; Exit[1]];

Print["M1 one-factorization constrained solve"];
laterConstrained = CodexM1SolveConstrainedSample[laterSystem, plan];
If[Lookup[laterConstrained, "Status", "Failed"] =!= "Solved",
  Print["FAILED: constrained later solve: ",
    Lookup[laterConstrained, "Status", "Unknown"]]; Exit[1]];
laterAgreement = CodexM1CanonicalAgreementQ[
  laterBaseline, laterConstrained,
  plan["NormalizationColumns"], prime];

stageKeys = {
  "SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
  "RankSeconds", "AugmentedRankSeconds", "LinearSolveSeconds",
  "NullspaceSeconds", "ConstrainedSolveSeconds",
  "PeakMemoryBytes", "ConstrainedPeakMemoryBytes",
  "MatrixDimensions", "NonzeroEntries", "Rank", "Nullity"
};

baselineStageTotal[sample_] := Total[Lookup[sample,
  {"SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
   "RankSeconds", "AugmentedRankSeconds", "LinearSolveSeconds",
   "NullspaceSeconds"}, 0]];
constrainedStageTotal[sample_] := Total[Lookup[sample,
  {"SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
   "ConstrainedSolveSeconds"}, 0]];

result = <|
  "Fixture" -> fixtureFile,
  "Prime" -> prime,
  "Offset" -> offset,
  "PilotEpsilonValue" -> First[epsilonSamples],
  "LaterEpsilonValue" -> epsilonSamples[[2]],
  "Plan" -> plan,
  "PilotCanonicalAgreement" -> pilotAgreement,
  "LaterCanonicalAgreement" -> laterAgreement,
  "PilotBaselineStages" -> KeyTake[pilotBaseline, stageKeys],
  "PilotConstrainedStages" -> KeyTake[pilotConstrained, stageKeys],
  "LaterBaselineStages" -> KeyTake[laterBaseline, stageKeys],
  "LaterConstrainedStages" -> KeyTake[laterConstrained, stageKeys],
  "PilotBaselineStageTotalSeconds" ->
    baselineStageTotal[pilotBaseline],
  "PilotConstrainedStageTotalSeconds" ->
    constrainedStageTotal[pilotConstrained],
  "LaterBaselineStageTotalSeconds" ->
    baselineStageTotal[laterBaseline],
  "LaterConstrainedStageTotalSeconds" ->
    constrainedStageTotal[laterConstrained],
  "PilotParticularHash" -> Hash[
    pilotConstrained["ParticularSolution"], "SHA256", "HexString"],
  "PilotNullspaceHash" -> Hash[
    pilotConstrained["NullspaceBasis"], "SHA256", "HexString"],
  "LaterParticularHash" -> Hash[
    laterConstrained["ParticularSolution"], "SHA256", "HexString"],
  "LaterNullspaceHash" -> Hash[
    laterConstrained["NullspaceBasis"], "SHA256", "HexString"],
  "AllOriginalRowChecks" -> And @@ Flatten[
    (Lookup[#,
      {"ParticularCheckZero", "NullspaceCheckZero",
       "NormalizationCheck"}, False] &) /@
      {pilotConstrained, laterConstrained}]
|>;

Put[result, outputFile];
Print[InputForm[result]];

If[! TrueQ[pilotAgreement && laterAgreement &&
    result["AllOriginalRowChecks"]], Exit[1]];
