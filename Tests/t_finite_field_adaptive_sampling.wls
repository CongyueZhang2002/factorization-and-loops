#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[xAdaptive, yAdaptive, epsAdaptive];
record = <|
  "Variables" -> {xAdaptive, yAdaptive},
  "Regulator" -> epsAdaptive,
  "Strip" -> {
    {{{1}}, {{0}}},
    {{{0}}, {{0}}},
    {{{1 - epsAdaptive xAdaptive}}, {{0}}}
  }
|>;

result = FeynFacet`SolveEpsFormStripFiniteField[
  record,
  "Primes" -> {1000003, 2147483423, 2147483477},
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}},
  "PointCount" -> 8,
  "KernelCount" -> 1,
  "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4,
  "MinimumPrimeCount" -> 3,
  "AdaptivePrimeSampling" -> True,
  "AdaptiveValidationMargin" -> 4,
  (* this test pins the DETERMINISTIC regulator schedule; the held-out
     schedule (A2, the default since 2026-08-21) has its own test *)
  "RegulatorSampling" -> "Deterministic",
  "Verbose" -> False
];

checks = <|
  "Association" -> AssociationQ[result],
  "ExactPfaffianIdentity" -> If[AssociationQ[result],
    TrueQ[result["ExactPfaffianResidualsZero"]], False],
  "ThreePrimes" -> If[AssociationQ[result],
    result["ModularPrimeCount"] === 3, False],
  "FirstPrimeUsesPilotSamples" -> If[AssociationQ[result],
    First[result["PrimeSampleCounts"]] === 12, False],
  "LaterPrimesUseFewerSamples" -> If[AssociationQ[result],
    AllTrue[Rest[result["PrimeSampleCounts"]], # < 12 &], False],
  "LaterPrimeDegreesAreBoundedByPilot" -> If[AssociationQ[result],
    AllTrue[Rest[result["PrimeMaximumTotalDegrees"]], # <= 4 &],
    False]
|>;

Print[InputForm[checks]];
Exit[If[And @@ Values[checks], 0, 1]];
