directory = DirectoryName[$InputFileName];
outputPath =
  FileNameJoin[{directory, "CF231_8_7_modular_summary.wl"}];

samplePaths = Sort[FileNames[
  "CF231_8_7_gauge_sample_*_p*.wl", directory]];
samples = Select[Get /@ samplePaths, AssociationQ];
interpolationPaths = Sort[FileNames[
  "CF231_8_7_epsilon_interpolation_mod_*.wl", directory]];
interpolations = Select[Get /@ interpolationPaths, AssociationQ];

ClearAll[numberRange];
numberRange[values_List] := Module[{numbers = Select[values, NumberQ]},
  If[numbers === {}, Missing["NotRecorded"], MinMax[numbers]]
];

ClearAll[summarizePrime];
summarizePrime[prime_Integer, primeSamples_List] := Module[
  {affineSamples},
  affineSamples = Select[primeSamples,
    KeyExistsQ[#, "ParticularSolution"] &];
  <|
    "Prime" -> prime,
    "SampleCount" -> Length[primeSamples],
    "AffineSampleCount" -> Length[affineSamples],
    "EpsilonValues" -> Sort[primeSamples[[All, "EpsilonValue"]]],
    "MatrixDimensions" ->
      DeleteDuplicates[primeSamples[[All, "MatrixDimensions"]]],
    "Ranks" -> DeleteDuplicates[primeSamples[[All, "Rank"]]],
    "AugmentedRanks" ->
      DeleteDuplicates[primeSamples[[All, "AugmentedRank"]]],
    "Nullities" -> DeleteDuplicates[primeSamples[[All, "Nullity"]]],
    "AllConsistent" ->
      AllTrue[primeSamples, TrueQ[#["Consistent"]] &],
    "AllAffineParticularChecksZero" ->
      AllTrue[affineSamples, TrueQ[#["ParticularCheckZero"]] &],
    "AllAffineNullspaceChecksZero" ->
      AllTrue[affineSamples, TrueQ[#["NullspaceCheckZero"]] &],
    "NonzeroEntryRange" ->
      numberRange[Lookup[primeSamples, "NonzeroEntries"]],
    "TimingRanges" -> AssociationMap[
      numberRange[Lookup[primeSamples, #, {}]] &,
      {"PreprocessingSeconds", "SamplingSeconds", "RankSeconds",
        "AugmentedRankSeconds", "LinearSolveSeconds", "NullspaceSeconds"}
    ]
  |>
];

sampleCensus = KeyValueMap[
  summarizePrime[#1, #2] &,
  GroupBy[samples, #["Prime"] &]
];
sampleCensus = SortBy[sampleCensus, #["Prime"] &];

interpolationCensus = SortBy[
  Map[
    <|
      "Prime" -> #["Prime"],
      "SampleCount" -> #["SampleCount"],
      "ConstructionCount" -> #["ConstructionCount"],
      "ValidationCount" -> #["ValidationCount"],
      "MaximumTotalDegree" -> #["MaximumTotalDegree"],
      "UnresolvedCoordinates" -> #["UnresolvedCoordinates"],
      "DegreeHistogram" -> #["DegreeHistogram"],
      "InterpolationSeconds" -> #["InterpolationSeconds"]
    |> &,
    interpolations
  ],
  #["Prime"] &
];

result = <|
  "SampleCensus" -> sampleCensus,
  "InterpolationCensus" -> interpolationCensus
|>;
Put[result, outputPath];
Print[result];
