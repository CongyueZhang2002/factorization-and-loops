#!/usr/bin/env wolframscript

Module[{repo, runtime, capture, adapter, outputFile, summaryFile, prime,
    records, fixedColumns, complementColumns, frames, fullFrames,
    runNativeMatrix, stacked, common, commonKernel, commonKernelColumns,
    commonKernelComplement, commonCoreTranspose, quotientFrames,
    quotientHomogeneousRanks, independentColumns, parameterOrders,
    quotientBasisColumns = $Failed, trialColumns, reducedHomogeneous,
    independentRows, rowOrders, quotientFreeRows = $Failed, trialRows,
    quotientDependentRows, normalizedFrames,
    samples, interpolationTiming, interpolation, exceeded, locations,
    result},
  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  adapter = FileNameJoin[{runtime,
    "flint_homogeneous_nullspace_cf300_20260828"}];
  outputFile = FileNameJoin[{runtime,
    "cf300_fixed_common_kernel_quotient_p31.wxf"}];
  summaryFile = FileNameJoin[{runtime,
    "cf300_fixed_common_kernel_quotient_p31_summary.wl"}];
  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FileNameJoin[{repo, "FeynFacet", "Private",
      "FiniteFieldStripSolve.wl"}]]];
  capture = Import[FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_76_checkpoint.wxf"}], "WXF"];
  prime = capture["Prime"];
  records = Rest[capture["Records"]];
  fixedColumns = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 129, 130, 131, 132, 133, 134, 135, 136, 138, 140, 141, 145,
    146, 147, 148, 149, 153, 154, 155, 156, 157, 158, 159, 160, 169,
    170, 171, 172, 177, 178, 179, 180, 181, 182, 183, 184};
  complementColumns = Complement[Range[212], fixedColumns];
  frames = Table[Module[{reduced, coefficient, right, core, rhs},
      reduced = records[[index, "RawReduced"]];
      coefficient = reduced[[All, 1 ;; 212]];
      right = reduced[[All, 213]];
      core = coefficient[[All, complementColumns]];
      rhs = Join[-coefficient[[All, fixedColumns]], List /@ right, 2];
      Mod[LinearSolve[core, rhs, Modulus -> prime], prime]],
    {index, Length[records]}];
  fullFrames = Table[Module[{full = ConstantArray[0, {212, 53}]},
      full[[fixedColumns, 1 ;; 52]] = IdentityMatrix[52];
      full[[complementColumns]] = frames[[index]];
      full], {index, Length[frames]}];

  runNativeMatrix[matrix_] := Module[{directory, inputFile, outputPath,
      stream, process, magic, header, values, nullspace},
    directory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
      "cf300-hnull-" <> StringReplace[CreateUUID[], "-" -> ""]}]];
    inputFile = FileNameJoin[{directory, "input.bin"}];
    outputPath = FileNameJoin[{directory, "output.bin"}];
    stream = OpenWrite[inputFile, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["FFHN1V1\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {Length[matrix], Dimensions[matrix][[2]], prime},
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[matrix], "UnsignedInteger64",
      ByteOrdering -> -1];
    Close[stream];
    process = RunProcess[{adapter, inputFile, outputPath, "8"}];
    If[process["ExitCode"] =!= 0,
      DeleteDirectory[directory, DeleteContents -> True];
      Return[<|"Status" -> "NativeNullspaceFailed",
        "Process" -> process|>]];
    stream = OpenRead[outputPath, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    header = BinaryReadList[stream, "UnsignedInteger64", 5,
      ByteOrdering -> -1];
    values = BinaryReadList[stream, "UnsignedInteger64",
      header[[5]] header[[2]], ByteOrdering -> -1];
    Close[stream];
    DeleteDirectory[directory, DeleteContents -> True];
    If[magic =!= ToCharacterCode["FFHN1X1\000"] ||
        header[[1 ;; 3]] =!= {Length[matrix], Dimensions[matrix][[2]], prime},
      Return[<|"Status" -> "NativeNullspaceOutputInvalid"|>]];
    nullspace = If[header[[5]] === 0, {},
      ArrayReshape[values, {header[[5]], header[[2]]}]];
    <|"Status" -> "Solved", "Rank" -> header[[4]],
      "Nullity" -> header[[5]], "Basis" -> nullspace,
      "ProcessOutput" -> process["StandardOutput"]|>
  ];

  stacked = Join @@ (#[["RawReduced", All, 1 ;; 212]] & /@ records);
  common = runNativeMatrix[stacked];
  If[Lookup[common, "Status", None] =!= "Solved" ||
      Lookup[common, {"Rank", "Nullity"}, None] =!= {176, 36},
    Put[<|"Status" -> "CommonKernelDimensionUnexpected",
      "Detail" -> KeyDrop[common, "Basis"]|>, summaryFile];
    Return[$Failed]];
  commonKernel = common["Basis"];
  If[Mod[stacked . Transpose[commonKernel], prime] =!=
      ConstantArray[0, {Length[stacked], 36}],
    Put[<|"Status" -> "CommonKernelResidualNonzero"|>, summaryFile];
    Return[$Failed]];
  Clear[stacked];
  independentColumns[matrix_] :=
    FeynFacet`Private`finiteFieldStripIndependentColumns[
      Normal[matrix], prime];
  commonKernelColumns = independentColumns[commonKernel];
  commonKernelComplement = Complement[Range[212], commonKernelColumns];
  If[Length[commonKernelColumns] =!= 36 ||
      Length[commonKernelComplement] =!= 176,
    Put[<|"Status" -> "CommonKernelCoordinateSectionFailed"|>,
      summaryFile]; Return[$Failed]];
  commonCoreTranspose = Transpose[commonKernel[[All, commonKernelColumns]]];
  quotientFrames = Table[Module[{full = fullFrames[[index]], beta},
      beta = LinearSolve[commonCoreTranspose,
        full[[commonKernelColumns]], Modulus -> prime];
      Mod[full[[commonKernelComplement]] -
        Transpose[commonKernel[[All, commonKernelComplement]]] . beta,
        prime]],
    {index, Length[fullFrames]}];
  quotientHomogeneousRanks = MatrixRank[#[[All, 1 ;; 52]],
      Modulus -> prime] & /@ quotientFrames;
  If[! AllTrue[quotientHomogeneousRanks, # === 16 &],
    Put[<|"Status" -> "QuotientHomogeneousRankUnexpected",
      "RankHistogram" -> Counts[quotientHomogeneousRanks]|>, summaryFile];
    Return[$Failed]];

  parameterOrders = Prepend[Table[BlockRandom[SeedRandom[2026082900 + seed];
      RandomSample[Range[52]]], {seed, 1, 64}], Range[52]];
  Do[
    trialColumns = order[[independentColumns[
      quotientFrames[[1, All, order]]]]];
    If[Length[trialColumns] === 16 && AllTrue[quotientFrames,
        MatrixRank[#[[All, trialColumns]], Modulus -> prime] === 16 &],
      quotientBasisColumns = trialColumns; Break[]],
    {order, parameterOrders}];
  If[quotientBasisColumns === $Failed,
    Put[<|"Status" -> "NoStableQuotientBasisColumns"|>, summaryFile];
    Return[$Failed]];
  reducedHomogeneous = #[[All, quotientBasisColumns]] & /@ quotientFrames;
  independentRows[matrix_] :=
    FeynFacet`Private`finiteFieldStripIndependentRows[
      Normal[matrix], 16, prime];
  rowOrders = Prepend[Table[BlockRandom[SeedRandom[2026083000 + seed];
      RandomSample[Range[176]]], {seed, 1, 64}], Range[176]];
  Do[
    trialRows = order[[independentRows[
      reducedHomogeneous[[1, order]]]]];
    If[Length[trialRows] === 16 && AllTrue[reducedHomogeneous,
        MatrixRank[#[[trialRows]], Modulus -> prime] === 16 &],
      quotientFreeRows = trialRows; Break[]],
    {order, rowOrders}];
  If[quotientFreeRows === $Failed,
    Put[<|"Status" -> "NoStableQuotientCoordinateRows"|>, summaryFile];
    Return[$Failed]];
  quotientDependentRows = Complement[Range[176], quotientFreeRows];
  normalizedFrames = MapThread[Module[{basis = #1,
        particular = #2[[All, 53]], core, inverse, alpha,
        normalizedBasis, normalizedParticular},
      core = basis[[quotientFreeRows]];
      inverse = Inverse[core, Modulus -> prime];
      normalizedBasis = Mod[basis . inverse, prime];
      alpha = Mod[inverse . particular[[quotientFreeRows]], prime];
      normalizedParticular = Mod[particular - basis . alpha, prime];
      Join[normalizedBasis[[quotientDependentRows]],
        List /@ normalizedParticular[[quotientDependentRows]], 2]] &,
    {reducedHomogeneous, quotientFrames}];
  samples = MapThread[<|"EpsilonValue" -> #1["RegulatorValue"],
      "EpsilonMod" -> #1["EpsilonMod"], "Values" -> Flatten[#2]|> &,
    {records, normalizedFrames}];
  {interpolationTiming, interpolation} = AbsoluteTiming[
    FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
      samples, prime, "InitialConstructionCount" -> 4,
      "HeldOutCount" -> 3, "MaximumTotalDegree" -> 64]];
  exceeded = Lookup[interpolation, "DegreeBoundExceededCoordinates", {}];
  locations = ({Quotient[# - 1, 17] + 1,
       Mod[# - 1, 17] + 1} &) /@ exceeded;
  result = <|"Status" -> "CF300FixedCommonKernelQuotientTested",
    "Prime" -> prime, "ImageCount" -> Length[records],
    "CommonKernelRank" -> common["Rank"],
    "CommonKernelNullity" -> common["Nullity"],
    "CommonKernelColumns" -> commonKernelColumns,
    "QuotientBasisColumns" -> quotientBasisColumns,
    "QuotientFreeRows" -> quotientFreeRows,
    "FrameDimensions" -> Dimensions[First[normalizedFrames]],
    "InterpolationSeconds" -> interpolationTiming,
    "InterpolationStatus" -> Lookup[interpolation, "Status", None],
    "ConsumedSampleCount" -> Lookup[interpolation,
      "ConsumedSampleCount", Missing[]],
    "DegreeHistogram" -> Lookup[interpolation,
      "DegreeHistogram", Missing[]],
    "DegreeBoundExceededCount" -> Length[exceeded],
    "FailureColumns" -> Counts[If[locations === {}, {},
      locations[[All, 2]]]],
    "CoordinateStatusHistogram" -> Lookup[interpolation,
      "CoordinateStatusHistogram", Missing[]]|>;
  Export[outputFile, <|"Summary" -> result,
    "CommonKernel" -> commonKernel,
    "NormalizedFrames" -> normalizedFrames,
    "Interpolation" -> interpolation|>, "WXF"];
  Put[result, summaryFile];
  Print[InputForm[result]];
  Null
]
