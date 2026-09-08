#!/usr/bin/env wolframscript

(* Current frozen-schema measurement for the M2 representation decision.
   Samples are recomputed externally and are not installed anywhere. *)

$HistoryLength = 0;

bundleDirectory = DirectoryName[$InputFileName];
repositoryRoot = "/home/maxzhang/factorization-and-loops";
fixtureFile = FileNameJoin[{repositoryRoot,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "frozen_M0", "fixture_CF254_9_7.wl"}];
loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
  "LoadFACET.wl"}];
prototypeM1File = FileNameJoin[{bundleDirectory,
  "CodexM1ConstrainedAffinePrototype.wl"}];
prototypeM2File = FileNameJoin[{bundleDirectory,
  "CodexM2AffineCarryPrototype.wl"}];
pilotResultFile = FileNameJoin[{bundleDirectory,
  "m1_pilot_and_sample_result.wl"}];
m1InterpolationFile = FileNameJoin[{bundleDirectory,
  "m1_mod_1000003.wl"}];
outputFile = FileNameJoin[{bundleDirectory,
  "m2_current_frozen_interpolation_result.wl"}];

workerCount = 4;
prime = 1000003;
epsilonSchedule = (#/(# + 20)) & /@ Range[32];
offset = {1, 0};

Get[loadFile];
Get[prototypeM1File];
Get[prototypeM2File];
record = Get[fixtureFile];
plan = Get[pilotResultFile]["Plan"];
m1Interpolation = Get[m1InterpolationFile];

If[Length[Kernels[]] < workerCount,
  launchedKernels = Quiet[
    LaunchKernels[workerCount - Length[Kernels[]]]],
  launchedKernels = {}];
If[Length[Kernels[]] > workerCount,
  Print["FAILED: more than four Wolfram workers in fresh benchmark."];
  Exit[1]];
With[{package = loadFile, prototype1 = prototypeM1File,
    prototype2 = prototypeM2File},
  ParallelEvaluate[
    Quiet[Get[package], General::shdw];
    Get[prototype1];
    Get[prototype2]]];

ClearAll[codexM2CurrentSample];
codexM2CurrentSample[epsilonValue_] := Module[
  {system, constrained},
  system = Quiet[CodexM1BuildSampleSystem[
    record, epsilonValue, prime,
    "NumeratorDegreeOffset" -> offset]];
  If[! AssociationQ[system] || KeyExistsQ[system, "Status"],
    Return[$Failed]];
  constrained = Quiet[CodexM1SolveConstrainedSample[system, plan]];
  If[! AssociationQ[constrained] ||
      Lookup[constrained, "Status", ""] =!= "Solved" ||
      ! TrueQ[Lookup[constrained, "ParticularCheckZero", False]] ||
      ! TrueQ[Lookup[constrained, "NullspaceCheckZero", False]] ||
      ! TrueQ[Lookup[constrained, "NormalizationCheck", False]],
    Return[$Failed]];
  constrained
];
DistributeDefinitions[codexM2CurrentSample, record, prime, offset, plan];

Print["Current frozen M2 benchmark: 32 samples on ",
  Length[Kernels[]], " workers."];
{samplingWallSeconds, samples} = AbsoluteTiming[
  ParallelMap[codexM2CurrentSample, epsilonSchedule,
    Method -> "FinestGrained", DistributedContexts -> Automatic]];
If[MemberQ[samples, $Failed] || Length[samples] =!= 32,
  Print["FAILED: a current frozen sample was rejected."]; Exit[1]];

canonicalSamples = CodexM2CanonicalSampleValues[
    #, plan["NormalizationColumns"], prime] & /@ samples;
If[MemberQ[canonicalSamples, $Failed],
  Print["FAILED: current samples did not normalize."]; Exit[1]];

memoryBeforeParticular = MaxMemoryUsed[];
{particularInterpolationSeconds, particularInterpolations} =
  AbsoluteTiming[CodexM2InterpolateCoordinateVectors[
    canonicalSamples, "ParticularValues", prime, 24, 22]];
memoryAfterParticular = MaxMemoryUsed[];
particularUnresolved = Flatten[
  Position[particularInterpolations, $Failed]];
particularByteCount = ByteCount[particularInterpolations];
particularMatchesM1Artifact = SameQ[
  particularInterpolations, m1Interpolation["Interpolations"]];

memoryBeforeFull = MaxMemoryUsed[];
{fullInterpolationSeconds, fullInterpolations} =
  AbsoluteTiming[CodexM2InterpolateCoordinateVectors[
    canonicalSamples, "FullAffineValues", prime, 24, 22]];
memoryAfterFull = MaxMemoryUsed[];
fullUnresolved = Flatten[Position[fullInterpolations, $Failed]];
fullByteCount = ByteCount[fullInterpolations];
fullDegreeHistogram = Counts[
  Cases[fullInterpolations,
    interpolation_Association :> interpolation["Degrees"]]];

sampleStageKeys = {
  "SetupSeconds", "PreprocessingSeconds", "SamplingSeconds",
  "ConstrainedSolveSeconds", "EndToEndSampleSeconds",
  "ConstrainedPeakMemoryBytes", "ConstrainedPeakMemoryGrowthBytes"
};
sampleStageTotals = AssociationMap[
  Total[Lookup[samples, #, 0.]] &, sampleStageKeys];

result = <|
  "Status" -> "Measured",
  "Scope" -> "ExternalM2CurrentFrozenNoPackageEdits",
  "Fixture" -> fixtureFile,
  "Prime" -> prime,
  "KernelCount" -> workerCount,
  "SampleCount" -> Length[samples],
  "SamplingWallSeconds" -> samplingWallSeconds,
  "SampleStageTotals" -> sampleStageTotals,
  "ParticularCoordinateCount" ->
    Length[First[canonicalSamples]["ParticularValues"]],
  "NullspaceCoordinateCount" ->
    Length[First[canonicalSamples]["NullspaceValues"]],
  "FullAffineCoordinateCount" ->
    Length[First[canonicalSamples]["FullAffineValues"]],
  "ParticularInterpolationSeconds" ->
    particularInterpolationSeconds,
  "ParticularUnresolvedCoordinateCount" ->
    Length[particularUnresolved],
  "ParticularInterpolationByteCount" -> particularByteCount,
  "ParticularPeakMemoryGrowthBytes" -> Max[0,
    memoryAfterParticular - memoryBeforeParticular],
  "ParticularMatchesM1Artifact" -> particularMatchesM1Artifact,
  "FullAffineInterpolationSeconds" -> fullInterpolationSeconds,
  "FullAffineInterpolationSlowdown" ->
    fullInterpolationSeconds/particularInterpolationSeconds,
  "FullAffineUnresolvedCoordinateCount" ->
    Length[fullUnresolved],
  "FullAffineInterpolationByteCount" -> fullByteCount,
  "FullAffinePeakMemoryGrowthBytes" -> Max[0,
    memoryAfterFull - memoryBeforeFull],
  "FullAffineDegreeHistogram" -> fullDegreeHistogram,
  "AllOriginalRowChecks" -> And @@ Flatten[
    Lookup[samples,
      {"ParticularCheckZero", "NullspaceCheckZero",
       "NormalizationCheck"}, False]]
|>;

temporaryOutputFile = outputFile <> ".tmp";
Put[result, temporaryOutputFile];
RenameFile[temporaryOutputFile, outputFile, OverwriteTarget -> True];
Print["Current frozen M2 measurement saved: ", outputFile];
Print[InputForm[KeyDrop[result,
  {"FullAffineDegreeHistogram", "SampleStageTotals"}]]];

If[Length[particularUnresolved] =!= 0 ||
    Length[fullUnresolved] =!= 0 ||
    ! TrueQ[particularMatchesM1Artifact] ||
    ! TrueQ[result["AllOriginalRowChecks"]], Exit[1]];
