directory = DirectoryName[$InputFileName];
auditDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit";

auditPaths = {
  FileNameJoin[{auditDirectory, "CF231_8_7_exact_strip.wl"}],
  FileNameJoin[{auditDirectory, "CF231_CF305_exact_audit.wl"}],
  FileNameJoin[{auditDirectory, "residue_compatibility_summary.wl"}],
  FileNameJoin[{auditDirectory, "AUDIT.md"}]
};
residuePath = FileNameJoin[{directory, "CF231_8_7_residue_space.wl"}];
polePath = FileNameJoin[{directory, "CF231_8_7_pole_bounds.wl"}];
exactCheckPath =
  FileNameJoin[{directory, "CF231_8_7_lifted_exact_check.wl"}];
outputPath =
  FileNameJoin[{directory, "CF231_8_7_sharp_certificate.wl"}];

requiredPaths = Join[auditPaths, {residuePath, polePath, exactCheckPath}];
If[! AllTrue[requiredPaths, FileExistsQ],
  Print["Missing required artifact(s): ",
    Select[requiredPaths, ! FileExistsQ[#] &]];
  Exit[1]
];

residue = Get[residuePath];
pole = Get[polePath];
exactCheck = Get[exactCheckPath];
If[! TrueQ[exactCheck["AllResidualsZero"]],
  Print["The exact two-PDE closure criterion is not satisfied."];
  Exit[1]
];

interpolationPaths = Sort[FileNames[
  "CF231_8_7_epsilon_interpolation_mod_*.wl", directory]];
interpolations = Get /@ interpolationPaths;
usedPrimes = exactCheck["Primes"];
interpolations = Select[interpolations,
  MemberQ[usedPrimes, #["Prime"]] &];

samplePaths = Flatten[Table[
  FileNames[
    "CF231_8_7_gauge_sample_*_p" <> ToString[prime] <> ".wl",
    directory],
  {prime, usedPrimes}
]];
samples = Select[Get /@ samplePaths,
  AssociationQ[#] && KeyExistsQ[#, "ParticularSolution"] &];

ClearAll[sha256];
sha256[path_String] := IntegerString[FileHash[path, "SHA256"], 16, 64];

sampleSummary = <|
  "Count" -> Length[samples],
  "CountsByPrime" -> Counts[samples[[All, "Prime"]]],
  "AllConsistent" -> AllTrue[samples, TrueQ[#["Consistent"]] &],
  "AllParticularChecksZero" ->
    AllTrue[samples, TrueQ[#["ParticularCheckZero"]] &],
  "AllNullspaceChecksZero" ->
    AllTrue[samples, TrueQ[#["NullspaceCheckZero"]] &],
  "Ranks" -> DeleteDuplicates[samples[[All, "Rank"]]],
  "AugmentedRanks" ->
    DeleteDuplicates[samples[[All, "AugmentedRank"]]],
  "Nullities" -> DeleteDuplicates[samples[[All, "Nullity"]]],
  "MatrixDimensions" ->
    DeleteDuplicates[samples[[All, "MatrixDimensions"]]],
  "NonzeroEntries" ->
    MinMax[samples[[All, "NonzeroEntries"]]],
  "TimingRanges" -> AssociationMap[
    MinMax[Lookup[samples, #]] &,
    {"PreprocessingSeconds", "SamplingSeconds", "RankSeconds",
      "AugmentedRankSeconds", "LinearSolveSeconds", "NullspaceSeconds"}
  ]
|>;

certificate = <|
  "Family" -> residue["Family"],
  "Pair" -> residue["Pair"],
  "Chart" -> residue["Chart"],
  "Variables" -> residue["Variables"],
  "Regulator" -> residue["Regulator"],
  "AuditInputs" -> AssociationMap[
    <|"SHA256" -> sha256[#], "Bytes" -> FileByteCount[#]|> &,
    auditPaths
  ],
  "ResidueCompatibility" -> <|
    "LetterCount" -> Length[residue["Alphabet"]],
    "UnknownCount" -> residue["ResidueUnknownCount"],
    "ExactRank" -> residue["ExactRank"],
    "ExactNullity" -> residue["FreeResidueParameterCount"],
    "FreeResidueParameterCount" ->
      residue["FreeResidueParameterCount"],
    "FiniteFieldSamples" -> residue["FiniteFieldSamples"],
    "AllExactClosureChecksZero" -> TrueQ[residue["ClosureZero"]],
    "Timings" -> residue["Timings"]
  |>,
  "PoleAnalysis" -> <|
    "Factors" -> pole["Factors"],
    "ForcingPoleOrders" -> pole["ForcingPoleOrders"],
    "GaugePoleOrders" -> pole["GaugePoleOrders"],
    "LeadingOperatorDeterminants" -> AssociationMap[
      pole["LeadingPoleOperatorChecks"][#]["Determinant"] &,
      Keys[pole["LeadingPoleOperatorChecks"]]
    ],
    "GaugeDenominatorDegrees" -> pole["GaugeDenominatorDegrees"],
    "NumeratorDegreeBounds" -> pole["NumeratorDegreeBounds"],
    "GaugeUnknownCount" -> pole["GaugeUnknownCount"],
    "TotalUnknownCount" -> pole["TotalUnknownCount"],
    "Timings" -> pole["Timings"]
  |>,
  "ModularGaugeSystems" -> sampleSummary,
  "EpsilonReconstruction" -> <|
    "Primes" -> usedPrimes,
    "CombinedModulus" -> exactCheck["CombinedModulus"],
    "Fields" -> Map[
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
    ]
  |>,
  "ExactGaugeClosure" -> <|
    "QuickCheckPoints" -> exactCheck["QuickCheckPoints"],
    "AllQuickChecksZero" ->
      And @@ Flatten[exactCheck["QuickChecksZero"]],
    "All32PDEEntriesZero" -> exactCheck["AllResidualsZero"],
    "LiftingSeconds" -> exactCheck["LiftingSeconds"],
    "ExactCheckSeconds" -> exactCheck["ParallelCheckSeconds"],
    "EntryCheckSeconds" -> exactCheck["ResidualSeconds"]
  |>,
  "ArtifactHashes" -> AssociationMap[
    <|"SHA256" -> sha256[#], "Bytes" -> FileByteCount[#]|> &,
    Join[{residuePath, polePath, exactCheckPath}, interpolationPaths]
  ]
|>;

Put[certificate, outputPath];
Print[<|
  "ResidueRank" -> certificate["ResidueCompatibility"]["ExactRank"],
  "ResidueNullity" ->
    certificate["ResidueCompatibility"]["ExactNullity"],
  "GaugeUnknownCount" ->
    certificate["PoleAnalysis"]["GaugeUnknownCount"],
  "UsedPrimes" -> certificate["EpsilonReconstruction"]["Primes"],
  "All32PDEEntriesZero" ->
    certificate["ExactGaugeClosure"]["All32PDEEntriesZero"],
  "Saved" -> outputPath
|>];
