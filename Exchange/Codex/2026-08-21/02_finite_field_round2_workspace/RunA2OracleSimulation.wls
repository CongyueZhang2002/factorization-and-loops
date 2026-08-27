#!/usr/bin/env wolframscript

$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];
Get[FileNameJoin[{bundle, "CodexA2IncrementalRegulatorPrototype.wl"}]];

epsilonValues = (#/(# + 20)) & /@ Range[32];

fixtures = {
  <|
    "Name" -> "CF254_9_6",
    "ArtifactDirectory" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "BenchmarkStripBackends",
      "frozen_M0", "m1_run", "ff_artifacts_M1_CF254_9_6_000055"}],
    "ArtifactPrefix" -> "finite_field_strip_mod_"
  |>,
  <|
    "Name" -> "CF254_9_7",
    "ArtifactDirectory" -> FileNameJoin[{root, "External",
      "CodexExchange", "codex_ff_m1_m2_2026-08-20"}],
    "ArtifactPrefix" -> "m1_mod_"
  |>
};

primes = {1000003, 2147483423, 2147483477, 2147483489,
  2147483497, 2147483543, 2147483549};

results = Table[
  Print["A2 oracle simulation: ", fixture["Name"]];
  primeResults = Table[
    path = FileNameJoin[{fixture["ArtifactDirectory"],
      fixture["ArtifactPrefix"] <> ToString[prime] <> ".wl"}];
    reference = Get[path];
    synthetic = CodexA2SamplesFromInterpolation[reference,
      Take[epsilonValues, 16]];
    initialCount = If[prime === First[primes], 4, 7];
    measured = CodexA2IncrementalInterpolate[synthetic, prime,
      "InitialConstructionCount" -> initialCount,
      "HeldOutCount" -> 3,
      "MaximumTotalDegree" -> 22,
      "ExpectedDegrees" -> If[prime === First[primes], Automatic,
        Lookup[firstResult["Interpolations"], "Degrees"]]];
    If[! AssociationQ[measured] ||
        measured["Status"] =!= "HeldOutValidated",
      Print["FAILED at prime ", prime, ": ", InputForm[measured]];
      Exit[2]];
    same = CodexA2InterpolationCoreSameQ[measured, reference];
    If[! TrueQ[same],
      Print["Interpolation mismatch at prime ", prime]; Exit[3]];
    If[prime === First[primes], firstResult = measured];
    <|
      "Prime" -> prime,
      "SampleCount" -> measured["SampleCount"],
      "ConstructionCount" -> measured["ConstructionCount"],
      "ValidationCount" -> measured["ValidationCount"],
      "InterpolationSeconds" -> measured["InterpolationSeconds"],
      "DegreeHistogram" -> measured["DegreeHistogram"],
      "DeterministicShortfallCoordinateCount" ->
        Length[measured["DeterministicShortfallCoordinates"]],
      "ReferenceInterpolationSameQ" -> same,
      "Trace" -> measured["Trace"]
    |>,
    {prime, primes}];
  <|
    "Fixture" -> fixture["Name"],
    "PrimeResults" -> primeResults,
    "SampleCounts" -> Lookup[primeResults, "SampleCount"],
    "TotalSampleCount" -> Total[Lookup[primeResults, "SampleCount"]],
    "AllReferenceInterpolationsSameQ" ->
      And @@ Lookup[primeResults, "ReferenceInterpolationSameQ"]
  |>,
  {fixture, fixtures}];

output = <|
  "Status" -> "OracleSimulationPassed",
  "Scope" -> "ExternalA2NoPackageEdits",
  "Policy" -> <|
    "FirstPrimeInitialConstructionCount" -> 4,
    "LaterPrimeConstructionCountFromLearnedDegreeProfile" -> 7,
    "HeldOutCount" -> 3,
    "FailurePolicy" -> "PromoteFailedHeldOutsAndGrowNeverAccept"
  |>,
  "Results" -> results
|>;

Put[output, FileNameJoin[{bundle, "a2_oracle_simulation_result.wl"}]];
Print[InputForm[KeyDrop[#, "PrimeResults"] & /@ results]];
Print["Saved A2 oracle simulation."];
Exit[0];

