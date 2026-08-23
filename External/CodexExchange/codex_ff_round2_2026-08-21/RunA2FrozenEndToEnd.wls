#!/usr/bin/env wolframscript

(* External A2 acceptance runner.  It does not modify FeynFacet. *)

$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
prototypeFile = FileNameJoin[{bundle,
  "CodexA2IncrementalRegulatorPrototype.wl"}];
workerCount = 4;
offset = {1, 0};
primes = {1000003, 2147483423, 2147483477, 2147483489,
  2147483497, 2147483543, 2147483549};
unseenPrime = 2147483563;
epsilonSchedule = (#/(# + 20)) & /@ Range[64];

fixtureSpecifications = {
  <|
    "Name" -> "CF254_9_6",
    "Fixture" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "BenchmarkStripBackends",
      "fixtures", "fixture_CF254_9_6.wl"}],
    "Oracle" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "BenchmarkStripBackends",
      "frozen_M0", "m1_run", "result_M1_CF254_9_6_FiniteField.wl"}],
    "ReferenceArtifactDirectory" -> FileNameJoin[{root,
      "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
      "BenchmarkStripBackends", "frozen_M0", "m1_run",
      "ff_artifacts_M1_CF254_9_6_000055"}],
    "ReferenceArtifactPrefix" -> "finite_field_strip_mod_"
  |>,
  <|
    "Name" -> "CF254_9_7",
    "Fixture" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "BenchmarkStripBackends",
      "frozen_M0", "fixture_CF254_9_7.wl"}],
    "Oracle" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "BenchmarkStripBackends",
      "frozen_M0", "result_fixture_CF254_9_7_FiniteField.wl"}],
    "ReferenceArtifactDirectory" -> FileNameJoin[{root, "External",
      "CodexExchange", "codex_ff_m1_m2_2026-08-20"}],
    "ReferenceArtifactPrefix" -> "m1_mod_"
  |>
};

requestedFixture = Environment["CODEX_A2_FIXTURE"];
If[StringQ[requestedFixture] && requestedFixture =!= "",
  fixtureSpecifications = Select[fixtureSpecifications,
    #["Name"] === requestedFixture &]];
If[fixtureSpecifications === {},
  Print["Unknown CODEX_A2_FIXTURE: ", requestedFixture]; Exit[2]];

Get[loadFile];
Get[prototypeFile];

ClearAll[codexA2PutAtomic];
codexA2PutAtomic[expression_, file_String] := Module[
  {temporary = file <> ".tmp"},
  Put[expression, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

ClearAll[codexA2AcceptedSampleQ];
codexA2AcceptedSampleQ[sample_] := AssociationQ[sample] &&
  TrueQ[Lookup[sample, "Consistent", False]] &&
  TrueQ[Lookup[sample, "ParticularCheckZero", False]] &&
  TrueQ[Lookup[sample, "NullspaceCheckZero", False]];

allResults = Table[
  name = specification["Name"];
  outputDirectory = FileNameJoin[{bundle, "a2_real_" <> name}];
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory,
      CreateIntermediateDirectories -> True]];
  outputFile = FileNameJoin[{outputDirectory,
    "a2_frozen_end_to_end_result.wl"}];
  Print["A2 frozen run: ", name, "."];
  record = Get[specification["Fixture"]];
  oracleRun = Get[specification["Oracle"]];
  oracle = Lookup[oracleRun, "BackendResult", oracleRun];
  recordFingerprint = Hash[record, "SHA256", "HexString"];

  {preparationWallSeconds, preparation} = AbsoluteTiming[
    PrepareEpsFormStripSampling[record]];
  If[! AssociationQ[preparation],
    Print["FAILED preparation for ", name]; Exit[3]];
  Print["  preparation wall ", NumberForm[preparationWallSeconds, {8, 2}],
    " s."];

  {pilotWallSeconds, pilotSample} = AbsoluteTiming[
    Quiet[SampleEpsFormStripAffine[
      record, First[epsilonSchedule], First[primes],
      "NumeratorDegreeOffset" -> offset,
      "SolveAffineSystem" -> True,
      "DiscoverPlan" -> True,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"]]]];
  plan = If[AssociationQ[pilotSample],
    Lookup[pilotSample, "EliminationPlan", None], None];
  If[! codexA2AcceptedSampleQ[pilotSample] || ! AssociationQ[plan] ||
      Lookup[plan, "Status", ""] =!= "OK",
    Print["FAILED constrained pilot for ", name]; Exit[4]];
  Print["  pilot wall ", NumberForm[pilotWallSeconds, {8, 2}],
    " s; core ", InputForm[plan["CoreDimensions"]], "."];

  launchedKernels = If[Length[Kernels[]] < workerCount,
    Quiet[LaunchKernels[workerCount - Length[Kernels[]]]], {}];
  If[Length[Kernels[]] =!= workerCount,
    Print["FAILED: expected exactly ", workerCount,
      " worker kernels, got ", Length[Kernels[]], "."];
    Exit[5]];
  With[{package = loadFile},
    ParallelEvaluate[Quiet[Get[package], General::shdw]]];

  ClearAll[codexA2RealSample];
  codexA2RealSample[epsilonValue_, prime_Integer] := Quiet[
    SampleEpsFormStripAffine[
      record, epsilonValue, prime,
      "NumeratorDegreeOffset" -> offset,
      "SolveAffineSystem" -> True,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"],
      "EliminationPlan" -> plan]];
  DistributeDefinitions[codexA2RealSample, codexA2AcceptedSampleQ,
    record, offset, preparation, plan];

  ClearAll[codexA2SamplePhase];
  codexA2SamplePhase[acceptedStart_List, queueStart_List,
      targetCount_Integer, prime_Integer] := Module[
    {accepted = acceptedStart, queue = queueStart, discarded = {},
     attempted = {}, batch, batchResults, paired, seconds,
     wallSeconds = 0.},
    While[Length[accepted] < targetCount && queue =!= {} &&
        Length[attempted] < targetCount + 40,
      batch = Take[queue, UpTo[Min[workerCount,
        targetCount - Length[accepted]]]];
      queue = Drop[queue, Length[batch]];
      attempted = Join[attempted, batch];
      {seconds, batchResults} = AbsoluteTiming[ParallelMap[
        Quiet[Check[codexA2RealSample[#, prime], $Failed]] &,
        batch, Method -> "FinestGrained",
        DistributedContexts -> Automatic]];
      wallSeconds += seconds;
      paired = MapThread[If[AssociationQ[#1], #1,
          <|"EpsilonValue" -> #2, "Prime" -> prime,
            "Status" -> "DiscardWorkerFailure"|>] &,
        {batchResults, batch}];
      accepted = Join[accepted,
        Select[paired, codexA2AcceptedSampleQ]];
      discarded = Join[discarded,
        Select[paired, ! codexA2AcceptedSampleQ[#] &]];
      Print["    p=", prime, " batch ", InputForm[batch],
        ": wall ", NumberForm[seconds, {7, 2}], " s; accepted ",
        Length[accepted], "/", targetCount, "."];
    ];
    <|
      "Status" -> If[Length[accepted] >= targetCount,
        "Complete", "InsufficientAcceptedSamples"],
      "Accepted" -> Take[accepted, UpTo[targetCount]],
      "RemainingQueue" -> queue,
      "Discarded" -> discarded,
      "Attempted" -> attempted,
      "WallSeconds" -> wallSeconds
    |>
  ];

  modularData = {};
  reconstructionAttempts = {};
  firstDegrees = Automatic;
  solution = $Failed;
  runStart = AbsoluteTime[];
  Do[
    firstPrimeQ = prime === First[primes];
    artifactFile = FileNameJoin[{outputDirectory,
      "a2_mod_" <> ToString[prime] <> ".wl"}];
    If[FileExistsQ[artifactFile],
      interpolation = Quiet[Check[Get[artifactFile], $Failed]];
      If[! AssociationQ[interpolation] ||
          Lookup[interpolation, "RecordFingerprint", Missing[]] =!=
            recordFingerprint,
        Print["FAILED invalid cached artifact ", artifactFile]; Exit[6]];
      Print["  loaded p=", prime, " A2 artifact."],

      acceptedSeed = If[firstPrimeQ, {pilotSample}, {}];
      sampleQueue = Select[epsilonSchedule,
        ! MemberQ[Lookup[acceptedSeed, "EpsilonValue", {}], #] &];
      constructionPhase = codexA2SamplePhase[
        acceptedSeed, sampleQueue, 7, prime];
      If[constructionPhase["Status"] =!= "Complete",
        Print["FAILED construction sampling p=", prime]; Exit[7]];
      heldOutPhase = codexA2SamplePhase[
        constructionPhase["Accepted"],
        constructionPhase["RemainingQueue"], 10, prime];
      If[heldOutPhase["Status"] =!= "Complete",
        Print["FAILED held-out sampling p=", prime]; Exit[8]];
      samples = heldOutPhase["Accepted"];
      canonicalSamples = CodexA2CanonicalizeSamples[
        samples, prime, plan["NormalizationColumns"]];
      If[! ListQ[canonicalSamples],
        Print["FAILED canonicalization p=", prime]; Exit[9]];
      {schedulerWallSeconds, interpolation} = AbsoluteTiming[
        CodexA2IncrementalInterpolate[
          canonicalSamples, prime,
          "InitialConstructionCount" -> If[firstPrimeQ, 4, 7],
          "HeldOutCount" -> 3,
          "MaximumTotalDegree" -> 22,
          "ExpectedDegrees" -> firstDegrees]];
      If[! AssociationQ[interpolation] ||
          interpolation["Status"] =!= "HeldOutValidated",
        Print["FAILED incremental interpolation p=", prime, ": ",
          InputForm[interpolation]]; Exit[10]];
      If[firstPrimeQ,
        firstDegrees = Lookup[interpolation["Interpolations"],
          "Degrees"]];
      referenceArtifact = Get[FileNameJoin[{
        specification["ReferenceArtifactDirectory"],
        specification["ReferenceArtifactPrefix"] <>
          ToString[prime] <> ".wl"}]];
      referenceSameQ = CodexA2InterpolationCoreSameQ[
        interpolation, referenceArtifact];
      If[! TrueQ[referenceSameQ],
        Print["FAILED modular oracle comparison p=", prime]; Exit[11]];
      interpolation = Join[interpolation,
        KeyTake[First[samples], {"GaugeUnknownCount",
          "FreeResidueCount", "GaugeNumeratorDegrees"}], <|
          "NormalizationColumns" -> plan["NormalizationColumns"],
          "GenericRank" -> Max[Lookup[samples, "Rank"]],
          "SelectedNumeratorDegreeOffset" -> offset,
          "RecordFingerprint" -> recordFingerprint,
          "SamplingSeconds" -> If[firstPrimeQ, pilotWallSeconds, 0.] +
            constructionPhase["WallSeconds"] +
            heldOutPhase["WallSeconds"],
          "ConstructionPhaseWallSeconds" ->
            constructionPhase["WallSeconds"],
          "HeldOutPhaseWallSeconds" -> heldOutPhase["WallSeconds"],
          "SchedulerWallSeconds" -> schedulerWallSeconds,
          "ReferenceInterpolationSameQ" -> referenceSameQ,
          "DiscardedSamples" -> Join[
            constructionPhase["Discarded"],
            heldOutPhase["Discarded"]],
          "AttemptedEpsilonValues" -> Join[
            constructionPhase["Attempted"], heldOutPhase["Attempted"]],
          "SampleTimings" -> (KeyTake[#, {"EpsilonValue", "Prime",
            "Status", "SetupSeconds", "PreprocessingSeconds",
            "SamplingSeconds", "ConstrainedSolveSeconds",
            "MatrixDimensions", "NonzeroEntries", "Rank", "Nullity",
            "SolvePath"}] & /@ samples)
        |>];
      codexA2PutAtomic[interpolation, artifactFile];
      Print["  saved p=", prime, ": 10 samples, wall ",
        NumberForm[interpolation["SamplingSeconds"], {8, 2}],
        " s, scheduler ",
        NumberForm[schedulerWallSeconds, {7, 2}], " s."]
    ];

    If[firstDegrees === Automatic,
      firstDegrees = Lookup[interpolation["Interpolations"], "Degrees"]];
    AppendTo[modularData, interpolation];
    If[Length[modularData] >= 3,
      {liftWallSeconds, candidate} = AbsoluteTiming[
        Quiet[CodexA2LiftCandidate[record, modularData]]];
      liftSucceeded = AssociationQ[candidate];
      unseenCheck = If[liftSucceeded,
        CodexA2UnseenPrimeResidualCheck[record, candidate, unseenPrime],
        $Failed];
      unseenPassed = AssociationQ[unseenCheck] &&
        TrueQ[unseenCheck["AllResidualsZero"]];
      AppendTo[reconstructionAttempts, <|
        "PrimeCount" -> Length[modularData],
        "CombinedModulus" -> Times @@ Lookup[modularData, "Prime"],
        "LiftWallSeconds" -> liftWallSeconds,
        "LiftSucceeded" -> liftSucceeded,
        "UnseenPrime" -> unseenPrime,
        "UnseenPrimeResidualPassed" -> unseenPassed,
        "UnseenPrimeWallSeconds" -> If[AssociationQ[unseenCheck],
          unseenCheck["WallSeconds"], 0.]
      |>];
      Print["  lift after ", Length[modularData], " primes: success=",
        liftSucceeded, ", unseen-prime residual=", unseenPassed, "."];
      If[unseenPassed,
        {exactCheckWallSeconds, exactVerification} = AbsoluteTiming[
          VerifyEpsFormStrip[record, candidate,
            "KernelCount" -> workerCount]];
        If[AssociationQ[exactVerification] &&
            TrueQ[exactVerification["ExactPfaffianResidualsZero"]],
          solution = Join[candidate,
            KeyDrop[exactVerification, "Residuals"],
            <|"Status" -> "Solved", "ExactDLog" -> True|>];
          Break[]]
      ]
    ],
    {prime, primes}];

  If[! AssociationQ[solution],
    Print["FAILED exact reconstruction for ", name]; Exit[12]];
  oracleAgreement = <|
    "GaugeSameQ" -> SameQ[solution["Gauge"], oracle["Gauge"]],
    "AlphabetSameQ" -> SameQ[
      solution["Alphabet"], oracle["Alphabet"]],
    "ResidueMatricesSameQ" -> SameQ[
      solution["ResidueMatrices"], oracle["ResidueMatrices"]],
    "NormalizationColumnsSameQ" -> SameQ[
      solution["NormalizationColumns"], oracle["NormalizationColumns"]]
  |>;
  oracleAgreement = Join[oracleAgreement,
    <|"AllSameQ" -> And @@ Values[oracleAgreement]|>];
  result = <|
    "Status" -> "Solved",
    "Scope" -> "ExternalA2NoPackageEdits",
    "FixtureName" -> name,
    "Fixture" -> specification["Fixture"],
    "Oracle" -> specification["Oracle"],
    "KernelCount" -> workerCount,
    "PreparationWallSeconds" -> preparationWallSeconds,
    "PilotWallSeconds" -> pilotWallSeconds,
    "PrimesUsed" -> Lookup[modularData, "Prime"],
    "PrimeSampleCounts" -> Lookup[modularData, "SampleCount"],
    "PrimeConstructionCounts" ->
      Lookup[modularData, "ConstructionCount"],
    "PrimeSamplingWallSeconds" ->
      Lookup[modularData, "SamplingSeconds"],
    "PrimeSchedulerWallSeconds" ->
      Lookup[modularData, "SchedulerWallSeconds"],
    "PrimeReferenceInterpolationSameQ" ->
      Lookup[modularData, "ReferenceInterpolationSameQ"],
    "DiscardedSampleCounts" ->
      (Length /@ Lookup[modularData, "DiscardedSamples"]),
    "ReconstructionAttempts" -> reconstructionAttempts,
    "UnseenPrimeResidualPassedBeforeExactCheck" -> True,
    "ExactCheckWallSeconds" -> exactCheckWallSeconds,
    "ExactPfaffianResidualsZero" ->
      solution["ExactPfaffianResidualsZero"],
    "OracleAgreement" -> oracleAgreement,
    "TotalWallSeconds" -> N[AbsoluteTime[] - runStart],
    "Solution" -> solution
  |>;
  codexA2PutAtomic[result, outputFile];
  Print["A2 result saved for ", name, ": ", outputFile];
  Print[InputForm[KeyDrop[result, "Solution"]]];
  If[! TrueQ[oracleAgreement["AllSameQ"]], Exit[13]];
  If[launchedKernels =!= {}, Quiet[CloseKernels[launchedKernels]]];
  result,
  {specification, fixtureSpecifications}];

summary = KeyTake[#, {"FixtureName", "PrimeSampleCounts",
  "PrimeSamplingWallSeconds", "TotalWallSeconds",
  "ExactPfaffianResidualsZero", "OracleAgreement"}] & /@ allResults;
codexA2PutAtomic[summary,
  FileNameJoin[{bundle, "a2_frozen_end_to_end_summary.wl"}]];
Print["A2 frozen summary: ", InputForm[summary]];

