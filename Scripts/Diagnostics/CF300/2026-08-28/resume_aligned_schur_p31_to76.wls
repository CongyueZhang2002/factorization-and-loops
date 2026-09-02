#!/usr/bin/env wolframscript

Module[{repo, runtime, fixtureFile, sourceFile, adapter, inputCheckpoint,
    outputCheckpoint, summaryFile, fixture, layout, provider, checkpoint,
    prime, fixedPoints, gaugeCoreRows, schurRows, records, existingValues,
    schedule, targetCount = 76, gaugeColumns = 2048,
    residueColumns = 212, runNative, value, sample, sampleSeconds,
    reduced, reduceSeconds, rawReduced, rejected = {}, result},
  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  fixtureFile = FileNameJoin[{runtime,
    "cf300_image_profile_20260827/profile_fixture_current_20260827.wxf"}];
  sourceFile = FileNameJoin[{runtime,
    "MultiquadraticStripSolve_affine25_capture_20260827.wl"}];
  adapter = FileNameJoin[{runtime,
    "flint_schur_reduce_cf300_20260828"}];
  inputCheckpoint = FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_42_checkpoint.wxf"}];
  outputCheckpoint = FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_76_checkpoint.wxf"}];
  summaryFile = FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_76_summary.wl"}];

  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FeynFacet`Private`feynFacetPrivateFile["FiniteFieldStripSolve.wl"]];
    Get[sourceFile]];
  fixture = Import[fixtureFile, "WXF"];
  layout = fixture["Layout"];
  provider = fixture["Provider"];
  checkpoint = Import[inputCheckpoint, "WXF"];
  prime = checkpoint["Prime"];
  fixedPoints = checkpoint["FixedPoints"];
  gaugeCoreRows = checkpoint["GaugeCoreRows"];
  schurRows = checkpoint["SchurRows"];
  records = checkpoint["Records"];
  existingValues = Lookup[records, "RegulatorValue"];
  schedule = Select[Join[Range[52, 128],
      Table[(2 index + 1)/(index + 53), {index, 1, 40}]],
    ! MemberQ[existingValues, #] &];

  runNative[inputMatrix_, inputRight_] := Module[{directory, inputFile,
      outputFile, stream, process, magic, header, values, augmented},
    directory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
      "cf300-schur-" <> StringReplace[CreateUUID[], "-" -> ""]}]];
    inputFile = FileNameJoin[{directory, "input.bin"}];
    outputFile = FileNameJoin[{directory, "output.bin"}];
    stream = OpenWrite[inputFile, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["FFSR1V1\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {Length[inputMatrix], gaugeColumns,
        residueColumns, Length[gaugeCoreRows], prime},
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, gaugeCoreRows - 1, "UnsignedInteger64",
      ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[inputMatrix], "UnsignedInteger64",
      ByteOrdering -> -1];
    BinaryWrite[stream, inputRight, "UnsignedInteger64",
      ByteOrdering -> -1];
    Close[stream];
    process = RunProcess[{adapter, inputFile, outputFile, "8"}];
    If[process["ExitCode"] =!= 0,
      DeleteDirectory[directory, DeleteContents -> True];
      Return[<|"Status" -> "NativeSchurFailed",
        "Process" -> process|>]];
    stream = OpenRead[outputFile, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    header = BinaryReadList[stream, "UnsignedInteger64", 5,
      ByteOrdering -> -1];
    values = BinaryReadList[stream, "UnsignedInteger64",
      header[[1]] header[[2]], ByteOrdering -> -1];
    Close[stream];
    DeleteDirectory[directory, DeleteContents -> True];
    If[magic =!= ToCharacterCode["FFSR1X1\000"] ||
        header[[1 ;; 3]] =!= {Length[inputMatrix] - gaugeColumns,
          residueColumns + 1, prime},
      Return[<|"Status" -> "NativeSchurOutputInvalid"|>]];
    augmented = ArrayReshape[values, header[[1 ;; 2]]];
    <|"Status" -> "Reduced", "SchurAugmented" -> augmented,
      "SchurRank" -> header[[4]], "AugmentedRank" -> header[[5]],
      "ProcessOutput" -> process["StandardOutput"]|>
  ];

  FeynFacet`Private`multiquadraticStripClearCaches[];
  Do[
    If[Length[records] >= targetCount, Break[]];
    Print["RESUME ALIGNED SCHUR image ", Length[records] + 1, "/",
      targetCount, " eps=", value, " start ", DateString[{"Time"}]];
    {sampleSeconds, sample} = AbsoluteTiming[
      Block[{
        FeynFacet`Private`$multiquadraticStripTrustedProviderEvaluation = True,
        FeynFacet`Private`$multiquadraticStripTrustedLayoutEvaluation = True},
        FeynFacet`Private`multiquadraticStripAssembleSample[
          layout, provider, value, prime,
          "PointCount" -> Length[fixedPoints],
          "MaximumAttempts" -> Length[fixedPoints],
          "RandomSeed" -> 2026082601,
          "CandidatePoints" -> fixedPoints,
          "SplitSparseEvaluationPlan" -> Automatic]]];
    If[Lookup[sample, "Status", None] =!=
        "AssembledMultiquadraticSampleV1" ||
        Lookup[sample, "AcceptedPoints", {}] =!= fixedPoints,
      AppendTo[rejected, <|"RegulatorValue" -> value,
        "Status" -> Lookup[sample, "Status", None]|>]; Continue[]];
    {reduceSeconds, reduced} = AbsoluteTiming[
      runNative[sample["Matrix"], sample["RightHandSide"]]];
    If[Lookup[reduced, "Status", None] =!= "Reduced" ||
        Lookup[reduced, {"SchurRank", "AugmentedRank"}, None] =!=
          {160, 160},
      AppendTo[rejected, <|"RegulatorValue" -> value,
        "Status" -> Lookup[reduced, "Status", None]|>]; Continue[]];
    rawReduced = reduced["SchurAugmented"][[schurRows]];
    If[MatrixRank[rawReduced[[All, 1 ;; residueColumns]],
          Modulus -> prime] =!= 160,
      AppendTo[rejected, <|"RegulatorValue" -> value,
        "Status" -> "FixedSchurRowsSingular"|>]; Continue[]];
    AppendTo[records, <|"RegulatorValue" -> value,
      "EpsilonMod" -> sample["EpsilonMod"],
      "SampleSeconds" -> sampleSeconds,
      "RawSchurSeconds" -> reduceSeconds,
      "RawReduced" -> rawReduced,
      "RawProcessOutput" -> reduced["ProcessOutput"]|>];
    Export[outputCheckpoint, <|"Status" -> "Sampling",
      "Prime" -> prime, "TargetImageCount" -> targetCount,
      "FixedPoints" -> fixedPoints, "GaugeCoreRows" -> gaugeCoreRows,
      "SchurRows" -> schurRows, "Records" -> records,
      "Rejected" -> rejected|>, "WXF"];
    Clear[sample, reduced, rawReduced],
    {value, schedule}];

  result = <|"Status" -> If[Length[records] >= targetCount,
      "CF300AlignedSchur76Sampled", "CF300AlignedSchur76Incomplete"],
    "Prime" -> prime, "ImageCount" -> Length[records],
    "NewImageCount" -> Length[records] - Length[checkpoint["Records"]],
    "Rejected" -> rejected,
    "TotalNewSampleSeconds" -> Total[Lookup[
      Drop[records, Length[checkpoint["Records"]]], "SampleSeconds", 0]],
    "TotalNewSchurSeconds" -> Total[Lookup[
      Drop[records, Length[checkpoint["Records"]]], "RawSchurSeconds", 0]]|>;
  Export[outputCheckpoint, Join[result, <|"FixedPoints" -> fixedPoints,
    "GaugeCoreRows" -> gaugeCoreRows, "SchurRows" -> schurRows,
    "Records" -> records|>], "WXF"];
  Put[result, summaryFile];
  Print[InputForm[result]];
  If[Length[records] < targetCount, Return[$Failed]];
  Null
]
