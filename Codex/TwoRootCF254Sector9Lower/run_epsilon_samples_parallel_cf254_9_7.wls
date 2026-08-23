directory = DirectoryName[$InputFileName];
sampleScript = If[ValueQ[$FacetSampleScriptOverride],
  $FacetSampleScriptOverride,
  If[StringQ[Environment["FACET_SAMPLE_SCRIPT"]] &&
      StringLength[Environment["FACET_SAMPLE_SCRIPT"]] > 0,
    Environment["FACET_SAMPLE_SCRIPT"],
    FileNameJoin[{directory,
      "sample_rank_by_points_cf254_9_7.wls"}]]];
outputPrefix = Which[
  ValueQ[$FacetOutputPrefixOverride], $FacetOutputPrefixOverride,
  StringQ[Environment["FACET_OUTPUT_PREFIX"]] &&
    StringLength[Environment["FACET_OUTPUT_PREFIX"]] > 0,
    Environment["FACET_OUTPUT_PREFIX"],
  True, "CF254_9_7"
];

ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

prime = ToExpression[environmentValue["FACET_PRIME", "1000003"]];
sampleStart = ToExpression[
  environmentValue["FACET_SAMPLE_START", "1"]];
sampleEnd = ToExpression[
  environmentValue["FACET_SAMPLE_END", "32"]];
pointCount = ToExpression[
  environmentValue["FACET_POINT_COUNT", "64"]];
requestedKernelCount = ToExpression[
  environmentValue["FACET_SUBKERNEL_COUNT", "8"]];
numeratorExtraX = ToExpression[
  environmentValue["FACET_NUMERATOR_EXTRA_X", "0"]];
numeratorExtraY = ToExpression[
  environmentValue["FACET_NUMERATOR_EXTRA_Y", "0"]];
If[! PrimeQ[prime] || prime <= 3 || ! IntegerQ[sampleStart] ||
    ! IntegerQ[sampleEnd] || sampleStart > sampleEnd ||
    ! IntegerQ[pointCount] || pointCount <= 0 ||
    ! IntegerQ[requestedKernelCount] || requestedKernelCount <= 0 ||
    ! IntegerQ[numeratorExtraX] || ! IntegerQ[numeratorExtraY],
  Print["Invalid prime, epsilon range, point count, or kernel count."];
  Exit[1]
];
sampleIndices = Range[sampleStart, sampleEnd];
If[MemberQ[sampleIndices, -20],
  Print["The epsilon sampling range contains the pole k = -20."];
  Exit[1]
];
kernelCount = Min[8, requestedKernelCount];
epsilonSamples = (#/(# + 20) &) /@ sampleIndices;
If[AnyTrue[epsilonSamples,
    Mod[Denominator[#], prime] === 0 &],
  Print["An epsilon sample has no image in the requested finite field."];
  Exit[1]
];

LaunchKernels[kernelCount];
DistributeDefinitions[sampleScript, prime, pointCount,
  numeratorExtraX, numeratorExtraY];
{seconds, summaries} = AbsoluteTiming[
  ParallelMap[
    Function[epsilonSample,
      Block[{
        $FacetEpsilonOverride = epsilonSample,
        $FacetPrimeOverride = prime,
        $FacetPointCountOverride = pointCount,
        $FacetSolveAffineOverride = True,
        $FacetNumeratorExtraXOverride = numeratorExtraX,
        $FacetNumeratorExtraYOverride = numeratorExtraY,
        $FacetQuietOverride = True
      },
        Get[sampleScript];
        KeyTake[$FacetLastSampleResult, {
          "EpsilonValue", "Prime", "Rank", "AugmentedRank",
          "Nullity", "Consistent", "SamplingSeconds", "RankSeconds",
          "AugmentedRankSeconds", "LinearSolveSeconds",
          "NullspaceSeconds", "ParticularCheckZero",
          "NullspaceCheckZero"
        }]
      ]
    ],
    epsilonSamples,
    Method -> "FinestGrained"
  ]
];
CloseKernels[];

result = <|
  "Prime" -> prime,
  "KernelCount" -> kernelCount,
  "SampleCount" -> Length[epsilonSamples],
  "Seconds" -> seconds,
  "AllConsistent" -> And @@ Lookup[summaries, "Consistent"],
  "AllAffineChecksZero" ->
    And @@ Flatten[Lookup[summaries,
      {"ParticularCheckZero", "NullspaceCheckZero"}]],
  "RankNullityCensus" -> Counts[
    Lookup[summaries, {"Rank", "Nullity"}]],
  "Samples" -> summaries
|>;
Put[result, FileNameJoin[{directory,
  outputPrefix <> "_parallel_sample_batch_p" <> ToString[prime] <> ".wl"}]];
Print[KeyDrop[result, "Samples"]];
