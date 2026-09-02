#!/usr/bin/env wolframscript

Module[{repo, runtime, fixtureFile, pilotSampleFile, pilotSchurFile,
    affineFile, adapter, checkpointFile, summaryFile,
    fixture, layout, provider, pilotSample, pilotSchur, affine,
    regulatorValues, prime, fixedPoints, gaugeCoreRows, schurRows,
    gaugeColumns = 2048, residueColumns = 212, equationRows,
    runNative, rowScaleFor, records = {}, sample, sampleSeconds, matrix,
    right, rawTiming, raw, scaledMatrix, scaledRight, scaleTiming, scaled,
    rawReduced, scaledReduced, value, index, rawSamples, scaledSamples,
    rawInterpolationTiming, rawInterpolation, scaledInterpolationTiming,
    scaledInterpolation, result, abortResult = None},
  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  fixtureFile = FileNameJoin[{runtime,
    "cf300_image_profile_20260827/profile_fixture_current_20260827.wxf"}];
  pilotSampleFile = FileNameJoin[{runtime,
    "cf300_system_sample_eps1_p31.wxf"}];
  pilotSchurFile = FileNameJoin[{runtime, "cf300_schur_pilot_p31.wxf"}];
  affineFile = FileNameJoin[{runtime, "cf300_p31_affine25_capture.wxf"}];
  adapter = FileNameJoin[{runtime, "flint_schur_reduce_cf300_20260828"}];
  checkpointFile = FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_checkpoint.wxf"}];
  summaryFile = FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_summary.wl"}];

  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FileNameJoin[{repo, "FeynFacet", "Private", "EpsForm",
      "FiniteFieldStripSolve.wl"}]];
    Get["/home/maxzhang/factorization-and-loops-codex/Runtime/MultiquadraticStripSolve_affine25_capture_20260827.wl"]];
  fixture = Import[fixtureFile, "WXF"];
  layout = fixture["Layout"];
  provider = fixture["Provider"];
  pilotSample = Import[pilotSampleFile, "WXF"];
  pilotSchur = Import[pilotSchurFile, "WXF"];
  affine = Import[affineFile, "WXF"];
  regulatorValues = Lookup[affine["Images"], "RegulatorValue"];
  prime = pilotSample["Prime"];
  fixedPoints = pilotSample["AcceptedPoints"];
  gaugeCoreRows = pilotSchur["GaugeCoreRows"];
  schurRows = pilotSchur["SchurRows"];
  equationRows = layout["EquationsPerPoint"];
  If[Length[fixedPoints] equationRows =!= Length[pilotSample["Matrix"]] ||
      Length[gaugeCoreRows] =!= gaugeColumns ||
      Length[schurRows] =!= 160,
    Put[<|"Status" -> "AlignedSchurPilotShapeMismatch"|>, summaryFile];
    Return[$Failed]];

  runNative[inputMatrix_, inputRight_] := Module[{directory, inputFile,
      outputFile, stream, process, magic, header, values, augmented},
    directory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
      "cf300-schur-" <> StringReplace[CreateUUID[], "-" -> ""]}]];
    inputFile = FileNameJoin[{directory, "input.bin"}];
    outputFile = FileNameJoin[{directory, "output.bin"}];
    stream = OpenWrite[inputFile, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["FFSR1V1\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {Length[inputMatrix], gaugeColumns, residueColumns,
        Length[gaugeCoreRows], prime}, "UnsignedInteger64",
      ByteOrdering -> -1];
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
      Return[<|"Status" -> "NativeSchurFailed", "Process" -> process|>]];
    stream = OpenRead[outputFile, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    header = BinaryReadList[stream, "UnsignedInteger64", 5,
      ByteOrdering -> -1];
    values = BinaryReadList[stream, "UnsignedInteger64",
      header[[1]] header[[2]], ByteOrdering -> -1];
    Close[stream];
    DeleteDirectory[directory, DeleteContents -> True];
    If[magic =!= ToCharacterCode["FFSR1X1\000"] ||
        header[[1 ;; 3]] =!=
          {Length[inputMatrix] - gaugeColumns, residueColumns + 1, prime} ||
        Length[values] =!= header[[1]] header[[2]],
      Return[<|"Status" -> "NativeSchurOutputInvalid"|>]];
    augmented = ArrayReshape[values, header[[1 ;; 2]]];
    <|"Status" -> "Reduced", "SchurAugmented" -> augmented,
      "SchurRank" -> header[[4]], "AugmentedRank" -> header[[5]],
      "ProcessOutput" -> process["StandardOutput"]|>
  ];

  rowScaleFor[regulatorValue_] := Module[{variables, regulator,
      denominator, qValues, pointScales},
    variables = provider["Variables"];
    regulator = provider["Regulator"];
    denominator = provider["GaugeDenominator"];
    qValues = Table[
      FeynFacet`Private`multiquadraticStripModRational[
        denominator /. Thread[variables -> point] /.
          regulator -> regulatorValue, prime],
      {point, fixedPoints}];
    If[! VectorQ[qValues, IntegerQ] || MemberQ[qValues, 0], Return[$Failed]];
    pointScales = Mod[qValues qValues, prime];
    Developer`ToPackedArray[Flatten[
      ConstantArray[#, equationRows] & /@ pointScales]]
  ];

  FeynFacet`Private`multiquadraticStripClearCaches[];
  Do[
    value = regulatorValues[[index]];
    Print["ALIGNED SCHUR image ", index, "/", Length[regulatorValues],
      " eps=", value, " start ", DateString[{"Time"}]];
    If[index === 1,
      sample = pilotSample; sampleSeconds = 0.,
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
            "SplitSparseEvaluationPlan" -> Automatic]]]];
    If[index > 1 && (Lookup[sample, "Status", None] =!=
          "AssembledMultiquadraticSampleV1" ||
        Lookup[sample, "AcceptedPoints", {}] =!= fixedPoints),
      result = <|"Status" -> "AlignedSampleFailed", "Index" -> index,
        "RegulatorValue" -> value, "Detail" ->
          KeyDrop[sample, {"Matrix", "RightHandSide"}],
        "Records" -> records|>;
      abortResult = result; Break[]];
    matrix = sample["Matrix"];
    right = sample["RightHandSide"];
    {rawTiming, raw} = AbsoluteTiming[runNative[matrix, right]];
    If[Lookup[raw, "Status", None] =!= "Reduced" ||
        Lookup[raw, {"SchurRank", "AugmentedRank"}, None] =!= {160, 160},
      result = <|"Status" -> "RawSchurFailed", "Index" -> index,
        "RegulatorValue" -> value, "Detail" -> raw,
        "Records" -> records|>;
      abortResult = result; Break[]];
    {scaleTiming, scaled} = AbsoluteTiming[Module[{rowScale, scaledRun},
      rowScale = rowScaleFor[value];
      If[rowScale === $Failed, Return[<|"Status" -> "RowScaleFailed"|>]];
      scaledMatrix = Developer`ToPackedArray[MapThread[
        Mod[#1 #2, prime] &, {matrix, rowScale}]];
      scaledRight = Developer`ToPackedArray[Mod[right rowScale, prime]];
      scaledRun = runNative[scaledMatrix, scaledRight];
      Clear[scaledMatrix, scaledRight];
      scaledRun]];
    If[Lookup[scaled, "Status", None] =!= "Reduced" ||
        Lookup[scaled, {"SchurRank", "AugmentedRank"}, None] =!= {160, 160},
      result = <|"Status" -> "ScaledSchurFailed", "Index" -> index,
        "RegulatorValue" -> value, "Detail" -> scaled,
        "Records" -> records|>;
      abortResult = result; Break[]];
    rawReduced = raw["SchurAugmented"][[schurRows]];
    scaledReduced = scaled["SchurAugmented"][[schurRows]];
    If[MatrixRank[rawReduced[[All, 1 ;; residueColumns]],
          Modulus -> prime] =!= 160 ||
        MatrixRank[scaledReduced[[All, 1 ;; residueColumns]],
          Modulus -> prime] =!= 160,
      result = <|"Status" -> "FixedSchurRowsSingular", "Index" -> index,
        "RegulatorValue" -> value, "Records" -> records|>;
      abortResult = result; Break[]];
    AppendTo[records, <|"RegulatorValue" -> value,
      "EpsilonMod" -> Lookup[sample, "EpsilonMod",
        FeynFacet`Private`multiquadraticStripModRational[value, prime]],
      "SampleSeconds" -> sampleSeconds, "RawSchurSeconds" -> rawTiming,
      "ScaledSchurSeconds" -> scaleTiming,
      "RawReduced" -> rawReduced, "ScaledReduced" -> scaledReduced,
      "RawProcessOutput" -> raw["ProcessOutput"],
      "ScaledProcessOutput" -> scaled["ProcessOutput"]|>];
    Export[checkpointFile, <|"Status" -> "Sampling", "Prime" -> prime,
      "FixedPoints" -> fixedPoints, "GaugeCoreRows" -> gaugeCoreRows,
      "SchurRows" -> schurRows, "Records" -> records|>, "WXF"];
    Clear[sample, matrix, right, raw, scaled, rawReduced, scaledReduced],
    {index, Length[regulatorValues]}];

  If[AssociationQ[abortResult],
    Export[checkpointFile, abortResult, "WXF"];
    Put[KeyDrop[abortResult, "Records"], summaryFile];
    Print[InputForm[KeyDrop[abortResult, "Records"]]];
    Return[$Failed]];

  rawSamples = (<|"EpsilonValue" -> #RegulatorValue,
      "EpsilonMod" -> #EpsilonMod,
      "Values" -> Flatten[#RawReduced]|> &) /@ records;
  scaledSamples = (<|"EpsilonValue" -> #RegulatorValue,
      "EpsilonMod" -> #EpsilonMod,
      "Values" -> Flatten[#ScaledReduced]|> &) /@ records;
  {rawInterpolationTiming, rawInterpolation} = AbsoluteTiming[
    FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
      rawSamples, prime, "InitialConstructionCount" -> 4,
      "HeldOutCount" -> 3, "MaximumTotalDegree" -> 22]];
  {scaledInterpolationTiming, scaledInterpolation} = AbsoluteTiming[
    FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
      scaledSamples, prime, "InitialConstructionCount" -> 4,
      "HeldOutCount" -> 3, "MaximumTotalDegree" -> 22]];
  result = <|"Status" -> "CF300AlignedSchurSampled",
    "Prime" -> prime, "ImageCount" -> Length[records],
    "FixedPoints" -> fixedPoints, "GaugeCoreRows" -> gaugeCoreRows,
    "SchurRows" -> schurRows, "Records" -> records,
    "RawInterpolation" -> rawInterpolation,
    "ScaledInterpolation" -> scaledInterpolation|>;
  Export[checkpointFile, result, "WXF"];
  Export[FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_interpolations.wxf"}],
    <|"Raw" -> rawInterpolation, "Scaled" -> scaledInterpolation|>, "WXF"];
  Put[<|"Status" -> result["Status"], "Prime" -> prime,
    "ImageCount" -> Length[records],
    "TotalSampleSeconds" -> Total[Lookup[records, "SampleSeconds"]],
    "TotalRawSchurSeconds" -> Total[Lookup[records, "RawSchurSeconds"]],
    "TotalScaledSchurSeconds" -> Total[Lookup[records, "ScaledSchurSeconds"]],
    "RawInterpolationSeconds" -> rawInterpolationTiming,
    "RawInterpolationStatus" -> Lookup[rawInterpolation, "Status", None],
    "RawDegreeHistogram" -> Lookup[rawInterpolation, "DegreeHistogram",
      Missing["Unavailable"]],
    "RawDegreeBoundExceededCount" -> Length[Lookup[rawInterpolation,
      "DegreeBoundExceededCoordinates", {}]],
    "ScaledInterpolationSeconds" -> scaledInterpolationTiming,
    "ScaledInterpolationStatus" -> Lookup[scaledInterpolation, "Status", None],
    "ScaledDegreeHistogram" -> Lookup[scaledInterpolation, "DegreeHistogram",
      Missing["Unavailable"]],
    "ScaledDegreeBoundExceededCount" -> Length[Lookup[scaledInterpolation,
      "DegreeBoundExceededCoordinates", {}]]|>, summaryFile];
  Print[InputForm[Get[summaryFile]]];
  Null
]
