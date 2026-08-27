#!/usr/bin/env wolframscript

(* External M1 experiment only.  Nothing in FeynFacet is modified. *)

$HistoryLength = 0;

bundleDirectory = DirectoryName[$InputFileName];
repositoryRoot = "/home/maxzhang/factorization-and-loops";
fixtureFile = FileNameJoin[{repositoryRoot,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "frozen_M0", "fixture_CF254_9_7.wl"}];
oracleFile = FileNameJoin[{repositoryRoot,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "frozen_M0",
  "result_fixture_CF254_9_7_FiniteField.wl"}];
pilotResultFile = FileNameJoin[{bundleDirectory,
  "m1_pilot_and_sample_result.wl"}];
outputFile = FileNameJoin[{bundleDirectory,
  "m1_end_to_end_result.wl"}];
loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
  "LoadFACET.wl"}];
prototypeFile = FileNameJoin[{bundleDirectory,
  "CodexM1ConstrainedAffinePrototype.wl"}];

workerCount = 4;
primes = {1000003, 2147483423, 2147483477, 2147483489,
  2147483497, 2147483543, 2147483549};
fullEpsilonSchedule = (#/(# + 20)) & /@ Range[32];
laterEpsilonSchedule = Take[fullEpsilonSchedule, 15];
replacementSchedule = (#/(# + 37)) & /@ Range[101, 260];
offset = {1, 0};

Get[loadFile];
Get[prototypeFile];

record = Get[fixtureFile];
oracleRun = Get[oracleFile];
oracle = oracleRun["BackendResult"];
pilotResult = Get[pilotResultFile];
plan = pilotResult["Plan"];
recordFingerprint = Hash[record, "SHA256", "HexString"];
planFingerprint = Hash[plan, "SHA256", "HexString"];

If[Length[Kernels[]] < workerCount,
  launchedKernels = Quiet[
    LaunchKernels[workerCount - Length[Kernels[]]]],
  launchedKernels = {}];
If[Length[Kernels[]] > workerCount,
  Print["FAILED: this fresh benchmark unexpectedly has more than ",
    workerCount, " Wolfram workers available."];
  Exit[1]];

Print["M1 end-to-end: using ", Length[Kernels[]],
  " Wolfram worker kernels (hard cap ", workerCount, ")."];

With[{package = loadFile, prototype = prototypeFile},
  ParallelEvaluate[
    Quiet[Get[package], General::shdw];
    Get[prototype]]];

ClearAll[codexM1EndToEndSample];
codexM1EndToEndSample[epsilonValue_, prime_Integer] := Module[
  {system, buildWallSeconds, constrained, totalSeconds},
  {buildWallSeconds, system} = AbsoluteTiming[
    Quiet[CodexM1BuildSampleSystem[
      record, epsilonValue, prime,
      "NumeratorDegreeOffset" -> offset]]];
  If[! AssociationQ[system],
    Return[<|
      "Status" -> "DiscardSystemBuildFailed",
      "EpsilonValue" -> epsilonValue,
      "Prime" -> prime,
      "SystemBuildWallSeconds" -> buildWallSeconds
    |>]];
  If[KeyExistsQ[system, "Status"],
    Return[Join[system, <|
      "EpsilonValue" -> epsilonValue,
      "Prime" -> prime,
      "SystemBuildWallSeconds" -> buildWallSeconds
    |>]]];
  constrained = Quiet[CodexM1SolveConstrainedSample[system, plan]];
  If[! AssociationQ[constrained],
    Return[<|
      "Status" -> "DiscardConstrainedSolveFailed",
      "EpsilonValue" -> epsilonValue,
      "Prime" -> prime,
      "SystemBuildWallSeconds" -> buildWallSeconds
    |>]];
  totalSeconds = buildWallSeconds +
    Lookup[constrained, "ConstrainedSolveSeconds", 0.];
  Join[constrained, <|
    "SystemBuildWallSeconds" -> buildWallSeconds,
    "EndToEndSampleSeconds" -> totalSeconds
  |>]
];

DistributeDefinitions[
  codexM1EndToEndSample, record, plan, offset];

ClearAll[codexM1AcceptedSampleBatch];
codexM1AcceptedSampleBatch[
    initialSchedule_List, targetCount_Integer, prime_Integer] := Module[
  {queue, accepted = {}, discarded = {}, attempted = {}, batch,
   batchResults, paired, wallSeconds, totalWallSeconds = 0.,
   maximumAttempts},
  queue = Join[initialSchedule,
    Select[replacementSchedule, ! MemberQ[initialSchedule, #] &]];
  maximumAttempts = targetCount + 40;
  While[Length[accepted] < targetCount &&
      Length[attempted] < maximumAttempts && queue =!= {},
    batch = Take[queue, UpTo[Min[
      workerCount, targetCount - Length[accepted]]]];
    queue = Drop[queue, Length[batch]];
    attempted = Join[attempted, batch];
    Print["  p=", prime, ": sampling ", InputForm[batch],
      " (accepted ", Length[accepted], "/", targetCount, ")"];
    {wallSeconds, batchResults} = AbsoluteTiming[
      ParallelMap[
        Quiet[Check[codexM1EndToEndSample[#, prime], $Failed]] &,
        batch, Method -> "FinestGrained",
        DistributedContexts -> Automatic]];
    totalWallSeconds += wallSeconds;
    paired = MapThread[
      If[AssociationQ[#1], #1,
        <|"Status" -> "DiscardWorkerFailure",
          "EpsilonValue" -> #2, "Prime" -> prime|>] &,
      {batchResults, batch}];
    accepted = Join[accepted, Select[paired,
      Lookup[#, "Status", ""] === "Solved" &&
        TrueQ[Lookup[#, "ParticularCheckZero", False]] &&
        TrueQ[Lookup[#, "NullspaceCheckZero", False]] &&
        TrueQ[Lookup[#, "NormalizationCheck", False]] &]];
    discarded = Join[discarded, Select[paired,
      Lookup[#, "Status", ""] =!= "Solved" ||
        ! TrueQ[Lookup[#, "ParticularCheckZero", False]] ||
        ! TrueQ[Lookup[#, "NullspaceCheckZero", False]] ||
        ! TrueQ[Lookup[#, "NormalizationCheck", False]] &]];
    Print["  batch wall seconds: ", NumberForm[wallSeconds, {8, 2}],
      "; accepted now ", Length[accepted], "/", targetCount];
  ];
  <|
    "Status" -> If[Length[accepted] >= targetCount,
      "Complete", "InsufficientAcceptedSamples"],
    "Samples" -> Take[accepted, UpTo[targetCount]],
    "Discarded" -> discarded,
    "AttemptedEpsilonValues" -> attempted,
    "BatchWallSeconds" -> totalWallSeconds
  |>
];

ClearAll[codexM1PutAtomic];
codexM1PutAtomic[expression_, file_String] := Module[
  {temporary = file <> ".tmp"},
  Put[expression, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

timingKeys = {
  "EpsilonValue", "Status", "SetupSeconds", "PreprocessingSeconds",
  "SamplingSeconds", "SystemBuildWallSeconds",
  "ConstrainedSolveSeconds", "EndToEndSampleSeconds",
  "MatrixDimensions", "NonzeroEntries", "Rank", "AugmentedRank",
  "Nullity", "ConstrainedCoreDimensions",
  "ConstrainedCoreNonzeroEntries", "ConstrainedPeakMemoryBytes",
  "ConstrainedPeakMemoryGrowthBytes", "ParticularCheckZero",
  "NullspaceCheckZero", "NormalizationCheck", "SolvePath"
};

modularData = {};
reconstructionAttempts = {};
solution = $Failed;
runStartTime = AbsoluteTime[];

Do[
  firstPrimeQ = prime === First[primes];
  epsilonSchedule = If[firstPrimeQ,
    fullEpsilonSchedule, laterEpsilonSchedule];
  targetCount = Length[epsilonSchedule];
  constructionCount = If[firstPrimeQ, 24, 7];
  maximumTotalDegree = If[firstPrimeQ, 22, 6];
  artifactFile = FileNameJoin[{bundleDirectory,
    "m1_mod_" <> ToString[prime] <> ".wl"}];

  If[FileExistsQ[artifactFile],
    interpolation = Quiet[Check[Get[artifactFile], $Failed]];
    If[! AssociationQ[interpolation] ||
        Lookup[interpolation, "RecordFingerprint", Missing[]] =!=
          recordFingerprint ||
        Lookup[interpolation, "PlanFingerprint", Missing[]] =!=
          planFingerprint,
      Print["FAILED: invalid cached M1 artifact ", artifactFile];
      Exit[1]];
    Print["Loaded external M1 artifact p=", prime, "."],

    Print["M1 prime ", prime, ": ", targetCount,
      " accepted regulator samples."];
    sampleBatch = codexM1AcceptedSampleBatch[
      epsilonSchedule, targetCount, prime];
    If[Lookup[sampleBatch, "Status", ""] =!= "Complete",
      Print["FAILED: could not replace discarded samples for p=", prime];
      Exit[1]];
    samples = sampleBatch["Samples"];
    {interpolationWallSeconds, interpolation} = AbsoluteTiming[
      Quiet[InterpolateEpsFormStripAffine[
        samples, prime,
        "ConstructionCount" -> constructionCount,
        "MaximumTotalDegree" -> maximumTotalDegree,
        "NormalizationColumns" -> plan["NormalizationColumns"]]]];
    If[! AssociationQ[interpolation] ||
        Lookup[interpolation, "UnresolvedCoordinates", {1}] =!= {},
      Print["FAILED: interpolation p=", prime];
      Exit[1]];
    interpolation = Join[interpolation, <|
      "SelectedNumeratorDegreeOffset" -> offset,
      "RecordFingerprint" -> recordFingerprint,
      "PlanFingerprint" -> planFingerprint,
      "M1Prototype" -> "OneConstrainedMultiRHSFactorization",
      "KernelCount" -> Length[Kernels[]],
      "BatchWallSeconds" -> sampleBatch["BatchWallSeconds"],
      "InterpolationWallSeconds" -> interpolationWallSeconds,
      "DiscardedSamples" -> (KeyTake[#,
        {"EpsilonValue", "Status", "ParticularCheckZero",
         "NullspaceCheckZero", "NormalizationCheck"}] & /@
          sampleBatch["Discarded"]),
      "AttemptedEpsilonValues" ->
        sampleBatch["AttemptedEpsilonValues"],
      "SampleTimings" -> (KeyTake[#, timingKeys] & /@ samples),
      "ParticularSolutionHashes" ->
        (Hash[#ParticularSolution, "SHA256", "HexString"] & /@ samples),
      "NullspaceBasisHashes" ->
        (Hash[#NullspaceBasis, "SHA256", "HexString"] & /@ samples)
    |>];
    codexM1PutAtomic[interpolation, artifactFile];
    Print["Saved ", artifactFile, "; sampling wall ",
      NumberForm[interpolation["BatchWallSeconds"], {9, 2}],
      " s; interpolation ",
      NumberForm[interpolationWallSeconds, {8, 2}], " s."]
  ];

  AppendTo[modularData, interpolation];
  If[Length[modularData] >= 3,
    Print["Exact reconstruction attempt after ",
      Length[modularData], " primes."];
    {reconstructionWallSeconds, candidateSolution} = AbsoluteTiming[
      Quiet[Check[
        ReconstructEpsFormStrip[record, modularData,
          "KernelCount" -> workerCount],
        $Failed],
        {ReconstructEpsFormStrip::data,
         ReconstructEpsFormStrip::modulus,
         ReconstructEpsFormStrip::check}]];
    AppendTo[reconstructionAttempts, <|
      "PrimeCount" -> Length[modularData],
      "CombinedModulus" -> Times @@ Lookup[modularData, "Prime"],
      "WallSeconds" -> reconstructionWallSeconds,
      "Succeeded" -> AssociationQ[candidateSolution]
    |>];
    Print["  reconstruction wall ",
      NumberForm[reconstructionWallSeconds, {8, 2}],
      " s; success=", AssociationQ[candidateSolution], "."];
    If[AssociationQ[candidateSolution],
      solution = candidateSolution;
      Break[]]
  ],
  {prime, primes}
];

If[! AssociationQ[solution],
  Print["FAILED: exact reconstruction did not succeed."];
  Exit[1]];

oracleAgreement = <|
  "GaugeSameQ" -> SameQ[solution["Gauge"], oracle["Gauge"]],
  "AlphabetSameQ" -> SameQ[solution["Alphabet"], oracle["Alphabet"]],
  "ResidueMatricesSameQ" -> SameQ[
    solution["ResidueMatrices"], oracle["ResidueMatrices"]],
  "NormalizationColumnsSameQ" -> SameQ[
    solution["NormalizationColumns"], oracle["NormalizationColumns"]]
|>;
oracleAgreement = Join[oracleAgreement, <|
  "AllSameQ" -> And @@ Values[oracleAgreement]
|>];

result = <|
  "Status" -> "Solved",
  "Scope" -> "ExternalM1PrototypeNoPackageEdits",
  "Fixture" -> fixtureFile,
  "Oracle" -> oracleFile,
  "KernelCount" -> workerCount,
  "Plan" -> plan,
  "PrimesUsed" -> Lookup[modularData, "Prime"],
  "PrimeSampleCounts" -> Lookup[modularData, "SampleCount"],
  "PrimeConstructionCounts" ->
    Lookup[modularData, "ConstructionCount"],
  "PrimeMaximumTotalDegrees" ->
    Lookup[modularData, "MaximumTotalDegree"],
  "PrimeBatchWallSeconds" -> Lookup[modularData, "BatchWallSeconds"],
  "PrimeInterpolationWallSeconds" ->
    Lookup[modularData, "InterpolationWallSeconds"],
  "DiscardedSampleCounts" ->
    (Length /@ Lookup[modularData, "DiscardedSamples"]),
  "ReconstructionAttempts" -> reconstructionAttempts,
  "TotalWallSeconds" -> N[AbsoluteTime[] - runStartTime],
  "ExactPfaffianResidualsZero" ->
    solution["ExactPfaffianResidualsZero"],
  "OracleAgreement" -> oracleAgreement,
  "Solution" -> solution
|>;

codexM1PutAtomic[result, outputFile];
Print["M1 exact result saved: ", outputFile];
Print[InputForm[KeyDrop[result, {"Plan", "Solution"}]]];

If[! TrueQ[result["ExactPfaffianResidualsZero"]] ||
    ! TrueQ[oracleAgreement["AllSameQ"]], Exit[1]];
