(* ==== moved whole from Private/Transport/PathTransportNative.wl on 2026-09-02 (user decision U1) ====
   Evidence: reachable only through the Libra path-ordered transport engines
   (TransportFamily / TransportPathArtifactRun), which the lazy-operator
   observable transport (Transport/ObservableTransport.wl) replaced as the
   production route; route_split.py: no helper of this module is used by
   ObservableTransport*, EpsForm or Geometry.
   This file is never loaded by FeynFacet.m. *)

(* Native finite-field providers for path transport.

   This module reuses the preserved BlockEquationDeferred arithmetic DAG and
   the existing FLINT regulator interpolator.  It contains no family data:
   callers supply a final two-form connection, its block ranges, the two
   kinematic variables, the regulator and the declared root squares.

   The first production seam is the block-pair regulator-order table.  It is
   obtained from every multiquadratic grade at two independent split points;
   no source entry is passed through Together or SeriesCoefficient. *)

ClearAll[
  pathTransportNativeWriteConnectionPreparation,
  pathTransportNativeSplitPoints,
  pathTransportNativeWriteScalarRequest,
  pathTransportNativeCoefficientOrder,
  pathTransportNativeSourceOrderTable
];

pathTransportNativeWriteConnectionPreparation[connection : {_List, _List},
    variables : {_Symbol, _Symbol}, regulator_Symbol, file_String] := Module[
  {dimensions, records, wrapper, seconds, writeResult},
  dimensions = Dimensions /@ connection;
  If[Length[DeleteDuplicates[dimensions]] =!= 1 ||
      ! MatchQ[First[dimensions], {_Integer?Positive, _Integer?Positive}],
    Return[<|"Status" -> "NativeTransportConnectionShapeInvalid",
      "Dimensions" -> dimensions|>]];
  records = Flatten[Table[
    With[{entry = connection[[form, row, column]]},
      Association["Target" -> {form, row, column},
        "Terms" -> If[TrueQ[entry === 0], {},
          {Association["Kind" -> "Base", "Coefficient" -> 1,
            "Operands" -> {entry}]}]]],
    {form, 2}, {row, dimensions[[1, 1]]},
    {column, dimensions[[1, 2]]}], 2];
  wrapper = <|"DeferredPreparation" -> <|"Preparation" -> <|
    "Status" -> "Prepared",
    "ABIVersion" -> $blockEquationDeferredABIVersion,
    "Variables" -> variables, "Regulator" -> regulator,
    "Dimensions" -> Prepend[First[dimensions], 2],
    "Records" -> records|>|>|>;
  {seconds, writeResult} = AbsoluteTiming[
    Quiet[Check[Put[wrapper, file], $Failed]]];
  If[writeResult === $Failed || ! FileExistsQ[file],
    <|"Status" -> "NativeTransportPreparationWriteFailed"|>,
    <|"Status" -> "NativeTransportPreparationV1",
      "Dimensions" -> First[dimensions], "RecordCount" -> Length[records],
      "NonzeroRecordCount" -> Count[records,
        record_ /; Lookup[record, "Terms", {}] =!= {}],
      "Seconds" -> N[seconds], "Bytes" -> FileByteCount[file],
      "File" -> file|>]
];
pathTransportNativeWriteConnectionPreparation[___] :=
  <|"Status" -> "NativeTransportConnectionShapeInvalid"|>;

pathTransportNativeSplitPoints[variables : {_Symbol, _Symbol},
    rootSquares_List, prime_Integer, count_Integer?Positive,
    seed_Integer, maximumAttempts_Integer?Positive] := Module[
  {points = {}, attempts = 0, candidate, scalarValues, evaluations,
   deltas, roots, result},
  If[! PrimeQ[prime] || prime <= 3 ||
      (rootSquares =!= {} && Mod[prime, 4] =!= 3),
    Return[<|"Status" -> "NativeTransportPrimeInvalid",
      "Prime" -> prime, "RootCount" -> Length[rootSquares]|>]];
  BlockRandom[
    SeedRandom[seed, Method -> "MersenneTwister"];
    While[Length[points] < count && attempts < maximumAttempts,
      attempts++;
      candidate = RandomInteger[{2, prime - 2}, 2];
      scalarValues = AssociationThread[variables, candidate];
      evaluations = blockEquationDeferredModEvaluate[
          #1, scalarValues, {}, prime] & /@ rootSquares;
      If[AllTrue[evaluations,
          Lookup[#1, "Status", None] === "OK" &],
        deltas = Lookup[evaluations, "Value"];
        If[FreeQ[deltas, 0] && AllTrue[deltas,
            PowerMod[#1, Quotient[prime - 1, 2], prime] === 1 &],
          roots = PowerMod[#1, Quotient[prime + 1, 4], prime] & /@ deltas;
          AppendTo[points, <|"Point" -> candidate,
            "RootSquares" -> deltas, "RootValues" -> roots|>]]]]];
  result = If[Length[points] === count,
    <|"Status" -> "NativeTransportSplitPointsV1", "Prime" -> prime,
      "Points" -> points, "AttemptCount" -> attempts|>,
    <|"Status" -> "NativeTransportSplitPointSearchExhausted",
      "Prime" -> prime, "AcceptedPointCount" -> Length[points],
      "RequestedPointCount" -> count, "AttemptCount" -> attempts|>];
  result
];
pathTransportNativeSplitPoints[___] :=
  <|"Status" -> "NativeTransportSplitPointArgumentsInvalid"|>;

pathTransportNativeWriteScalarRequest[file_String,
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    rootSquares_List, prime_Integer, images : {__Association}] := Module[
  {rootLines, imageLines, lines, result},
  rootLines = ("root " <> ToString[#1, InputForm,
      PageWidth -> Infinity]) & /@ rootSquares;
  imageLines = Function[image,
      "image " <> StringRiffle[ToString /@ Join[
        image["Point"], {image["EpsilonMod"]},
        Flatten[Transpose[{image["RootSquares"],
          image["RootValues"]}]]], " "]] /@ images;
  lines = Join[{"DeferredASTRequestV1", "prime " <> ToString[prime],
      "variables " <> StringRiffle[
        SymbolName /@ Join[variables, {regulator}], " "],
      "rank " <> ToString[Length[rootSquares]]}, rootLines,
    {"base_count " <> ToString[Length[images]]}, imageLines];
  result = Quiet[Check[
    Export[file, StringRiffle[lines, "\n"] <> "\n", "Text"], $Failed]];
  If[result === $Failed || ! FileExistsQ[file],
    <|"Status" -> "NativeTransportRequestWriteFailed"|>,
    <|"Status" -> "NativeTransportScalarRequestV1",
      "BaseCount" -> Length[images], "File" -> file|>]
];
pathTransportNativeWriteScalarRequest[___] :=
  <|"Status" -> "NativeTransportRequestArgumentsInvalid"|>;

pathTransportNativeCoefficientOrder[interpolation_Association] := Module[
  {numerator, denominator, numeratorPosition, denominatorPosition},
  If[Lookup[interpolation, "Degrees", None] === {-Infinity, 0},
    Return[Infinity]];
  numerator = Lookup[interpolation, "Numerator", {}];
  denominator = Lookup[interpolation, "Denominator", {}];
  numeratorPosition = SelectFirst[Range[Length[numerator]],
    numerator[[#1]] =!= 0 &, Missing["ZeroNumerator"]];
  denominatorPosition = SelectFirst[Range[Length[denominator]],
    denominator[[#1]] =!= 0 &, Missing["ZeroDenominator"]];
  If[MissingQ[numeratorPosition] || MissingQ[denominatorPosition],
    Infinity, numeratorPosition - denominatorPosition]
];
pathTransportNativeCoefficientOrder[___] := Infinity;

Options[pathTransportNativeSourceOrderTable] = {
  "Prime" -> 2305843009213691819,
  "PointCount" -> 2,
  "EpsilonImageCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "HeldOutCount" -> 3,
  "Seed" -> 2026083101,
  "MaximumPointAttempts" -> 10000,
  "Threads" -> Automatic
};

pathTransportNativeSourceOrderTable[assembly_Association,
    connection : {_List, _List}, variables : {_Symbol, _Symbol},
    regulator_Symbol, rootSquares_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], prime, pointCount, epsilonImageCount,
   maximumTotalDegree, heldOutCount, seed, maximumPointAttempts, threads,
   actualThreads, ranges, dimensions, binary, directory = None,
   preparationFile, requestFile, outputFile, preparation, split,
   epsilonValues, images, request, process, processSeconds, providerShape,
   response, readSeconds, fits, fit, fitSeconds, indices, samples,
   valuationArrays, pointTables, orderTable, strictLowerEdges,
   result},
  prime = OptionValue["Prime"];
  pointCount = OptionValue["PointCount"];
  epsilonImageCount = OptionValue["EpsilonImageCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  heldOutCount = OptionValue["HeldOutCount"];
  seed = OptionValue["Seed"];
  maximumPointAttempts = OptionValue["MaximumPointAttempts"];
  threads = Replace[OptionValue["Threads"], Automatic :>
    Clip[taskBrokerNativeThreadLimit[8], {1, 8}]];
  ranges = Lookup[assembly, "Ranges", Missing["NoRanges"]];
  dimensions = Dimensions /@ connection;
  If[! MatchQ[ranges, {{__Integer?Positive} ..}] ||
      Length[DeleteDuplicates[dimensions]] =!= 1 ||
      dimensions[[1]] =!= {Total[Length /@ ranges],
        Total[Length /@ ranges]} ||
      ! PrimeQ[prime] || ! IntegerQ[pointCount] || pointCount < 1 ||
      ! IntegerQ[epsilonImageCount] || epsilonImageCount < 7 ||
      ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0 ||
      ! IntegerQ[heldOutCount] || heldOutCount < 1 ||
      ! IntegerQ[threads] || ! Between[threads, {1, 8}] ||
      Length[rootSquares] > 3,
    Return[<|"Status" -> "NativeTransportOrderTableInputInvalid"|>]];
  actualThreads = Min[threads, pointCount epsilonImageCount];
  binary = multiquadraticStripNativeDeferredBinary[];
  If[! StringQ[binary],
    Return[<|"Status" -> "NativeTransportEvaluatorUnavailable"|>]];
  result = Internal`WithLocalSettings[
    directory = CreateDirectory[];
    preparationFile = FileNameJoin[{directory, "connection.wl"}];
    requestFile = FileNameJoin[{directory, "request.txt"}];
    outputFile = FileNameJoin[{directory, "response.bin"}];,
    Catch[
      preparation = pathTransportNativeWriteConnectionPreparation[
        connection, variables, regulator, preparationFile];
      If[Lookup[preparation, "Status", None] =!=
          "NativeTransportPreparationV1", Throw[preparation]];
      split = pathTransportNativeSplitPoints[variables, rootSquares,
        prime, pointCount, seed, maximumPointAttempts];
      If[Lookup[split, "Status", None] =!=
          "NativeTransportSplitPointsV1", Throw[split]];
      BlockRandom[
        SeedRandom[seed + 1, Method -> "MersenneTwister"];
        epsilonValues = RandomSample[Range[101, 1000000],
          epsilonImageCount]];
      images = Flatten[Table[Join[split["Points"][[pointIndex]],
          <|"EpsilonMod" -> epsilonValue|>],
        {pointIndex, pointCount}, {epsilonValue, epsilonValues}], 1];
      request = pathTransportNativeWriteScalarRequest[requestFile,
        variables, regulator, rootSquares, prime, images];
      If[Lookup[request, "Status", None] =!=
          "NativeTransportScalarRequestV1", Throw[request]];
      {processSeconds, process} = AbsoluteTiming[RunProcess[
        taskBrokerNativeCommand[{binary, preparationFile, requestFile,
          outputFile, "--threads", ToString[actualThreads]},
          actualThreads]]];
      If[! AssociationQ[process] || process["ExitCode"] =!= 0 ||
          ! FileExistsQ[outputFile],
        Throw[<|"Status" -> "NativeTransportEvaluationFailed",
          "ExitCode" -> If[AssociationQ[process],
            process["ExitCode"], Missing["NoProcess"]],
          "StandardError" -> If[AssociationQ[process],
            StringTrim[process["StandardError"]], Missing["NoProcess"]]|>]];
      providerShape = <|"Dimensions" -> First[dimensions],
        "RootCount" -> Length[rootSquares],
        "GradeCount" -> 2^Length[rootSquares]|>;
      {readSeconds, response} = AbsoluteTiming[
        multiquadraticStripNativeDeferredReadOutput[outputFile,
          providerShape, prime, Length[images]]];
      If[Lookup[response, "Status", None] =!=
          "MultiquadraticNativeDeferredBatchV1", Throw[response]];
      fits = Table[
        indices = Range[(pointIndex - 1) epsilonImageCount + 1,
          pointIndex epsilonImageCount];
        samples = MapThread[<|"EpsilonMod" -> #1,
            "Values" -> Flatten[#2]|> &,
          {epsilonValues, response["BBarBatch"][[indices]]}];
        {fitSeconds, fit} = AbsoluteTiming[
          finiteFieldStripHeldOutInterpolate[samples, prime,
            "InitialConstructionCount" -> 4,
            "HeldOutCount" -> heldOutCount,
            "MaximumTotalDegree" -> maximumTotalDegree]];
        Append[fit, "WallSeconds" -> N[fitSeconds]],
        {pointIndex, pointCount}];
      If[! AllTrue[fits,
          Lookup[#1, "Status", None] === "HeldOutValidated" &],
        Throw[<|"Status" -> "NativeTransportInterpolationFailed",
          "PointResults" -> (KeyDrop[#1, "Interpolations"] & /@ fits)|>]];
      valuationArrays = ArrayReshape[
          pathTransportNativeCoefficientOrder /@
            Lookup[#1, "Interpolations"],
          Join[{2}, First[dimensions], {2^Length[rootSquares]}]] & /@ fits;
      pointTables = Table[Table[
          If[rowBlock > columnBlock,
            Min[Flatten[valuationArrays[[pointIndex, All,
              ranges[[rowBlock]], ranges[[columnBlock]], All]]]],
            Infinity],
          {rowBlock, Length[ranges]},
          {columnBlock, Length[ranges]}],
        {pointIndex, pointCount}];
      orderTable = MapThread[Min, pointTables, 2];
      strictLowerEdges = Flatten[Table[{i, j}, {i, Length[ranges]},
        {j, i - 1}], 1];
      If[! AllTrue[strictLowerEdges,
          MatchQ[orderTable[[#[[1]], #[[2]]]],
            _Integer | Infinity] &],
        Throw[<|"Status" -> "NativeTransportOrderTableInvalid"|>]];
      <|"Status" -> "NativeTransportOrderTableV1",
        "OrderTable" -> orderTable,
        "PointOrderTables" -> pointTables,
        "PointTablesAgreeQ" -> SameQ @@ pointTables,
        "DifferingEdges" -> Select[strictLowerEdges,
          Length[DeleteDuplicates[
            pointTables[[All, #[[1]], #[[2]]]]]] > 1 &],
        "Prime" -> prime, "Points" -> split["Points"],
        "EpsilonImageCount" -> epsilonImageCount,
        "InterpolationSampleCounts" -> Lookup[fits, "SampleCount"],
        "DegreeHistograms" -> Lookup[fits, "DegreeHistogram"],
        "PhaseSeconds" -> <|"PreparationWrite" -> preparation["Seconds"],
          "NativeWall" -> N[processSeconds],
          "NativeParse" -> response["ParseSeconds"],
          "NativeEvaluate" -> response["EvaluationSeconds"],
          "ResponseRead" -> N[readSeconds],
          "InterpolationWall" -> Lookup[fits, "WallSeconds"]|>,
        "Threads" -> actualThreads|>],
    If[StringQ[directory] && DirectoryQ[directory],
      Quiet[DeleteDirectory[directory, DeleteContents -> True]]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - started]],
    <|"Status" -> "NativeTransportOrderTableFailed"|>]
];
pathTransportNativeSourceOrderTable[___] :=
  <|"Status" -> "NativeTransportOrderTableInputInvalid"|>;

(* ---- selected-sheet truncated path jets --------------------------- *)

ClearAll[
  pathTransportNativePathJetBinary,
  pathTransportNativePathData,
  pathTransportNativeWriteJetRequest,
  pathTransportNativeReadJetOutput,
  pathTransportNativeEvaluateJets,
  pathTransportNativeLaurentCoefficient,
  pathTransportNativeInterpolateJets,
  pathTransportNativeJetMul,
  pathTransportNativeSeriesData,
  pathTransportNativeEdgeSeries,
  pathTransportNativeDiagonalSeries,
  pathTransportNativeFormalGraph,
  pathTransportNativeFormalEvaluate,
  pathTransportNativeFormalAccept,
  pathTransportNativeArtifactCreate,
  pathTransportNativeArtifactOpen,
  pathTransportNativeConnectionFromArtifact,
  pathTransportNativeRunArtifact
];

pathTransportNativePathJetBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_deferred_path_jet"}]}, If[FileExistsQ[file], file, None]];

pathTransportNativePathData[contract_Association,
    endpoints : {_, _}, tau_Symbol, prime_Integer,
    order_Integer?NonNegative, sheetValue_] := Module[
  {z, ztau, variables, sourcePath, rootSquares, rootBranches,
   extension, rootSymbol, rootSquareOnPath, baseSquareJet,
   chosenSheet, sheetData = None, evaluate, xExpression, yExpression,
   xJet, yJet, deltaExpressions, deltaJets, branchExpressions, rootJets,
   failure},
  If[! pathTransportExceptionContractQ[contract] || ! PrimeQ[prime] ||
      order > 64,
    Return[<|"Status" -> "NativeTransportPathDataInputInvalid"|>]];
  z = contract["PathVariable"];
  ztau = endpoints[[1]] + tau (endpoints[[2]] - endpoints[[1]]);
  variables = contract["Variables"];
  sourcePath = contract["SourcePath"];
  rootSquares = contract["SourceRootSquares"];
  rootBranches = contract["SourceRootBranches"];
  extension = Lookup[contract, "PathExtension", <|"Type" -> "None"|>];
  evaluate[expression_, sheet_] := Catch[
    pathTransportExceptionJetOfExpression[expression, tau, prime, order,
      sheet], $pathTransportExceptionJetTag];
  xExpression = sourcePath[variables[[1]]] /. z -> ztau;
  yExpression = sourcePath[variables[[2]]] /. z -> ztau;
  xJet = evaluate[xExpression, None];
  yJet = evaluate[yExpression, None];
  If[AssociationQ[xJet] || AssociationQ[yJet],
    Return[<|"Status" -> "NativeTransportPathCoordinateJetFailed",
      "X" -> xJet, "Y" -> yJet|>]];
  If[extension["Type"] === "Quadratic",
    rootSymbol = Lookup[extension, "Root", Missing["NoRoot"]];
    rootSquareOnPath = extension["RootSquare"] /. z -> ztau;
    baseSquareJet = evaluate[rootSquareOnPath, None];
    If[AssociationQ[baseSquareJet] || First[baseSquareJet] === 0,
      Return[<|"Status" -> "NativeTransportPathOriginRamified"|>]];
    chosenSheet = Replace[sheetValue, {
      Automatic :> If[Mod[prime, 4] === 3,
        PowerMod[First[baseSquareJet], Quotient[prime + 1, 4], prime],
        Missing["AutomaticSquareRootUnavailable"]],
      1 :> If[Mod[prime, 4] === 3,
        PowerMod[First[baseSquareJet], Quotient[prime + 1, 4], prime],
        Missing["AutomaticSquareRootUnavailable"]],
      -1 :> If[Mod[prime, 4] === 3,
        Mod[-PowerMod[First[baseSquareJet], Quotient[prime + 1, 4], prime],
          prime], Missing["AutomaticSquareRootUnavailable"]]}];
    If[! IntegerQ[chosenSheet] ||
        Mod[chosenSheet^2 - First[baseSquareJet], prime] =!= 0,
      Return[<|"Status" -> "NativeTransportSheetValueInvalid",
        "BaseSquare" -> First[baseSquareJet]|>]];
    chosenSheet = Mod[chosenSheet, prime];
    sheetData = Association[rootSquareOnPath -> chosenSheet],
    rootSymbol = None; rootSquareOnPath = None; chosenSheet = None];
  deltaExpressions = (#1 /. Thread[variables ->
        Lookup[sourcePath, variables]]) /. z -> ztau & /@ rootSquares;
  deltaJets = evaluate[#1, None] & /@ deltaExpressions;
  branchExpressions = ((#1 /. If[rootSymbol === None, {},
          {rootSymbol -> Sqrt[rootSquareOnPath]}]) /. z -> ztau) & /@
    rootBranches;
  rootJets = evaluate[#1, sheetData] & /@ branchExpressions;
  failure = SelectFirst[Join[deltaJets, rootJets], AssociationQ,
    Missing["NoFailure"]];
  If[! MissingQ[failure],
    Return[<|"Status" -> "NativeTransportRootJetFailed",
      "Failure" -> failure|>]];
  <|"Status" -> "NativeTransportPathDataV1", "Prime" -> prime,
    "Order" -> order, "Variables" -> variables,
    "RootSquares" -> rootSquares, "XJet" -> xJet, "YJet" -> yJet,
    "XDerivativeJet" -> Append[Rest[Range[0, order] xJet], 0],
    "YDerivativeJet" -> Append[Rest[Range[0, order] yJet], 0],
    "DeltaJets" -> deltaJets, "RootJets" -> rootJets,
    "SheetValue" -> chosenSheet, "RootSquareOnPath" -> rootSquareOnPath,
    "Endpoints" -> endpoints|>
];
pathTransportNativePathData[___] :=
  <|"Status" -> "NativeTransportPathDataInputInvalid"|>;

pathTransportNativeWriteJetRequest[file_String,
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    pathData_Association, epsilonValues : {__Integer}] := Module[
  {prime, order, rootSquares, lines, rootLines, epsilonLines, rootJetLines,
   result},
  prime = pathData["Prime"];
  order = pathData["Order"];
  rootSquares = pathData["RootSquares"];
  If[! AllTrue[epsilonValues, 0 <= #1 < prime &],
    Return[<|"Status" -> "NativeTransportJetRequestInvalid"|>]];
  rootLines = ("root " <> ToString[#1, InputForm,
      PageWidth -> Infinity]) & /@ rootSquares;
  epsilonLines = ("epsilon " <> ToString[#1]) & /@ epsilonValues;
  rootJetLines = Flatten[MapThread[{
      "delta_jet " <> StringRiffle[ToString /@ #1, " "],
      "root_jet " <> StringRiffle[ToString /@ #2, " "]} &,
    {pathData["DeltaJets"], pathData["RootJets"]}]];
  lines = Join[{"DeferredPathJetRequestV1",
      "prime " <> ToString[prime],
      "variables " <> StringRiffle[
        SymbolName /@ Join[variables, {regulator}], " "],
      "order " <> ToString[order],
      "rank " <> ToString[Length[rootSquares]]}, rootLines,
    {"epsilon_count " <> ToString[Length[epsilonValues]]}, epsilonLines,
    {"x_jet " <> StringRiffle[ToString /@ pathData["XJet"], " "],
      "y_jet " <> StringRiffle[ToString /@ pathData["YJet"], " "]},
    rootJetLines];
  result = Quiet[Check[
    Export[file, StringRiffle[lines, "\n"] <> "\n", "Text"], $Failed]];
  If[result === $Failed || ! FileExistsQ[file],
    <|"Status" -> "NativeTransportJetRequestWriteFailed"|>,
    <|"Status" -> "NativeTransportJetRequestV1", "File" -> file,
      "EpsilonCount" -> Length[epsilonValues]|>]
];
pathTransportNativeWriteJetRequest[___] :=
  <|"Status" -> "NativeTransportJetRequestInvalid"|>;

pathTransportNativeReadJetOutput[file_String, expectedPrime_Integer,
    expectedOrder_Integer, expectedRank_Integer,
    expectedEpsilonCount_Integer, expectedDimensions_List] := Module[
  {stream = None, magic, status, header, prime, order, rank, epsilonCount,
   recordCount, termCount, uniqueCount, dimensions, parseNanoseconds,
   evaluationNanoseconds, targets, jets = {}, expectedTargets, trailing, result},
  result = Quiet[Check[
    stream = OpenRead[file, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    status = BinaryRead[stream, "UnsignedInteger64", ByteOrdering -> -1];
    header = BinaryReadList[stream, "UnsignedInteger64", 12,
      ByteOrdering -> -1];
    If[magic =!= ToCharacterCode["DAPJ1V1\000"] ||
        ! IntegerQ[status] || Length[header] =!= 12,
      Return[<|"Status" -> "NativeTransportJetOutputHeaderInvalid"|>,
        Module]];
    If[status =!= 0,
      Return[<|"Status" -> "NativeTransportJetEvaluatorRefused",
        "NativeStatusCode" -> status, "DetailIndex" -> header[[8]],
        "DetailOffset" -> header[[9]]|>, Module]];
    {prime, order, rank, epsilonCount, recordCount, termCount,
      uniqueCount} = Take[header, 7];
    dimensions = header[[8 ;; 10]];
    {parseNanoseconds, evaluationNanoseconds} = header[[11 ;; 12]];
    If[{prime, order, rank, epsilonCount, dimensions, recordCount} =!=
        {expectedPrime, expectedOrder, expectedRank,
          expectedEpsilonCount, expectedDimensions,
          Times @@ expectedDimensions},
      Return[<|"Status" -> "NativeTransportJetOutputShapeMismatch",
        "Observed" -> {prime, order, rank, epsilonCount, dimensions,
          recordCount}|>, Module]];
    targets = Table[
      With[{target = BinaryReadList[stream, "UnsignedInteger64", 3,
          ByteOrdering -> -1]},
        AppendTo[jets, ArrayReshape[BinaryReadList[stream,
          "UnsignedInteger64", epsilonCount (order + 1),
          ByteOrdering -> -1], {epsilonCount, order + 1}]];
        target], {recordCount}];
    trailing = BinaryRead[stream, "UnsignedInteger8"];
    Close[stream]; stream = None;
    expectedTargets = Flatten[Table[{form, row, column},
      {form, dimensions[[1]]}, {row, dimensions[[2]]},
      {column, dimensions[[3]]}], 2];
    If[targets =!= expectedTargets || trailing =!= EndOfFile ||
        ! AllTrue[Flatten[jets], IntegerQ[#1] && 0 <= #1 < prime &],
      Return[<|"Status" -> "NativeTransportJetOutputPayloadInvalid"|>,
        Module]];
    <|"Status" -> "NativeTransportJetBatchV1", "Prime" -> prime,
      "Order" -> order, "Rank" -> rank,
      "EpsilonCount" -> epsilonCount, "Dimensions" -> dimensions,
      "RecordCount" -> recordCount, "TermCount" -> termCount,
      "UniqueExpressionCount" -> uniqueCount,
      "ParseSeconds" -> N[parseNanoseconds/10.^9],
      "EvaluationSeconds" -> N[evaluationNanoseconds/10.^9],
      "Jets" -> jets|>,
    <|"Status" -> "NativeTransportJetOutputReadFailed"|>]];
  If[Head[stream] === InputStream, Quiet[Close[stream]]];
  result
];
pathTransportNativeReadJetOutput[___] :=
  <|"Status" -> "NativeTransportJetOutputArgumentsInvalid"|>;

Options[pathTransportNativeEvaluateJets] = {"Threads" -> Automatic};
pathTransportNativeEvaluateJets[preparationFile_String,
    dimensions : {_Integer?Positive, _Integer?Positive},
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    pathData_Association, epsilonValues : {__Integer},
    OptionsPattern[]] := Module[
  {binary, directory = None, requestFile, outputFile, request,
   threads, actualThreads, process, processSeconds, result},
  binary = pathTransportNativePathJetBinary[];
  threads = Replace[OptionValue["Threads"], Automatic :>
    Clip[taskBrokerNativeThreadLimit[8], {1, 8}]];
  If[! StringQ[binary] || ! FileExistsQ[preparationFile] ||
      Lookup[pathData, "Status", None] =!= "NativeTransportPathDataV1" ||
      ! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[<|"Status" -> "NativeTransportJetEvaluationInputInvalid"|>]];
  actualThreads = Min[threads, Length[epsilonValues]];
  result = Internal`WithLocalSettings[
    directory = CreateDirectory[];
    requestFile = FileNameJoin[{directory, "request.txt"}];
    outputFile = FileNameJoin[{directory, "response.bin"}];,
    Catch[
      request = pathTransportNativeWriteJetRequest[requestFile,
        variables, regulator, pathData, epsilonValues];
      If[Lookup[request, "Status", None] =!=
          "NativeTransportJetRequestV1", Throw[request]];
      {processSeconds, process} = AbsoluteTiming[RunProcess[
        taskBrokerNativeCommand[{binary, preparationFile, requestFile,
          outputFile, "--threads", ToString[actualThreads]},
          actualThreads]]];
      If[! AssociationQ[process] || process["ExitCode"] =!= 0 ||
          ! FileExistsQ[outputFile],
        Throw[<|"Status" -> "NativeTransportJetEvaluationFailed",
          "ExitCode" -> If[AssociationQ[process], process["ExitCode"],
            Missing["NoProcess"]],
          "StandardError" -> If[AssociationQ[process],
            StringTrim[process["StandardError"]],
            Missing["NoProcess"]]|>]];
      result = pathTransportNativeReadJetOutput[outputFile,
        pathData["Prime"], pathData["Order"],
        Length[pathData["RootSquares"]], Length[epsilonValues],
        Prepend[dimensions, 2]];
      If[Lookup[result, "Status", None] =!=
          "NativeTransportJetBatchV1", Throw[result]];
      Join[result, <|"WallSeconds" -> N[processSeconds],
        "Threads" -> actualThreads|>]],
    If[StringQ[directory] && DirectoryQ[directory],
      Quiet[DeleteDirectory[directory, DeleteContents -> True]]]];
  result
];
pathTransportNativeEvaluateJets[___] :=
  <|"Status" -> "NativeTransportJetEvaluationInputInvalid"|>;

pathTransportNativeLaurentCoefficient[interpolation_Association,
    requestedOrder_Integer, prime_Integer] := Module[
  {numerator, denominator, numeratorPosition, denominatorPosition,
   valuation, shiftedNumerator, shiftedDenominator, target, inverseLead,
   coefficients, degree, source},
  If[Lookup[interpolation, "Degrees", None] === {-Infinity, 0},
    Return[0]];
  numerator = Lookup[interpolation, "Numerator", {}];
  denominator = Lookup[interpolation, "Denominator", {}];
  numeratorPosition = SelectFirst[Range[Length[numerator]],
    numerator[[#1]] =!= 0 &, Missing["ZeroNumerator"]];
  denominatorPosition = SelectFirst[Range[Length[denominator]],
    denominator[[#1]] =!= 0 &, Missing["ZeroDenominator"]];
  If[MissingQ[numeratorPosition] || MissingQ[denominatorPosition],
    Return[0]];
  valuation = numeratorPosition - denominatorPosition;
  If[requestedOrder < valuation, Return[0]];
  shiftedNumerator = Drop[numerator, numeratorPosition - 1];
  shiftedDenominator = Drop[denominator, denominatorPosition - 1];
  target = requestedOrder - valuation;
  inverseLead = PowerMod[First[shiftedDenominator], -1, prime];
  coefficients = ConstantArray[0, target + 1];
  Do[
    source = If[degree + 1 <= Length[shiftedNumerator],
      shiftedNumerator[[degree + 1]], 0];
    coefficients[[degree + 1]] = Mod[inverseLead (source - Sum[
      If[k + 1 <= Length[shiftedDenominator],
        shiftedDenominator[[k + 1]], 0] coefficients[[degree - k + 1]],
      {k, 1, degree}]), prime],
    {degree, 0, target}];
  Last[coefficients]
];
pathTransportNativeLaurentCoefficient[___] := $Failed;

pathTransportNativeInterpolateJets[batch_Association,
    epsilonValues : {__Integer}, requestedOrders : {__Integer},
    maximumTotalDegree_Integer?NonNegative, heldOutCount_Integer?Positive] :=
 Module[{prime, jetOrder, dimensions, samples, fit, fitSeconds,
   interpolations, coefficientJets},
  If[Lookup[batch, "Status", None] =!= "NativeTransportJetBatchV1" ||
      Length[epsilonValues] =!= batch["EpsilonCount"],
    Return[<|"Status" -> "NativeTransportJetInterpolationInputInvalid"|>]];
  prime = batch["Prime"];
  jetOrder = batch["Order"];
  dimensions = batch["Dimensions"];
  samples = Table[<|"EpsilonMod" -> epsilonValues[[image]],
      "Values" -> Flatten[batch["Jets"][[All, image, All]]]|>,
    {image, Length[epsilonValues]}];
  {fitSeconds, fit} = AbsoluteTiming[
    finiteFieldStripHeldOutInterpolate[samples, prime,
      "InitialConstructionCount" -> 4,
      "HeldOutCount" -> heldOutCount,
      "MaximumTotalDegree" -> maximumTotalDegree]];
  If[Lookup[fit, "Status", None] =!= "HeldOutValidated",
    Return[<|"Status" -> "NativeTransportJetInterpolationFailed",
      "Interpolation" -> KeyDrop[fit, "Interpolations"]|>]];
  interpolations = fit["Interpolations"];
  coefficientJets = AssociationThread[requestedOrders,
    (ArrayReshape[
        pathTransportNativeLaurentCoefficient[#1, #2, prime] & @@@
          Transpose[{interpolations,
            ConstantArray[#, Length[interpolations]]}],
        Join[dimensions, {jetOrder + 1}]]) & /@ requestedOrders];
  <|"Status" -> "NativeTransportInterpolatedJetsV1",
    "Prime" -> prime, "JetOrder" -> jetOrder,
    "Dimensions" -> dimensions, "RequestedOrders" -> requestedOrders,
    "CoefficientJets" -> coefficientJets,
    "DegreeHistogram" -> fit["DegreeHistogram"],
    "SampleCount" -> fit["SampleCount"],
    "InterpolationSeconds" -> fit["InterpolationSeconds"],
    "InterpolationWallSeconds" -> N[fitSeconds]|>
];
pathTransportNativeInterpolateJets[___] :=
  <|"Status" -> "NativeTransportJetInterpolationInputInvalid"|>;

pathTransportNativeJetMul[a_List, b_List, prime_Integer] := Module[
  {order = Min[Length[a], Length[b]] - 1},
  Table[Mod[Sum[a[[k + 1]] b[[degree - k + 1]],
    {k, 0, degree}], prime], {degree, 0, order}]
];
pathTransportNativeJetMul[___] := $Failed;

Options[pathTransportNativeSeriesData] = {
  "EpsilonImageCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "HeldOutCount" -> 3,
  "Seed" -> 2026083105,
  "SheetValue" -> Automatic,
  "Threads" -> Automatic
};

pathTransportNativeSeriesData[connection : {_List, _List},
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    rootSquares_List, contract_Association, endpoints : {_, _},
    tau_Symbol, requestedOrders : {__Integer}, prime_Integer,
    jetOrder_Integer?NonNegative, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], dimensions, epsilonImageCount,
   maximumTotalDegree, heldOutCount, seed, threads, directory = None,
   preparationFile, preparation, pathData, epsilonValues, batch,
   interpolated, sourceJets, pathJets, result},
  dimensions = Dimensions /@ connection;
  epsilonImageCount = OptionValue["EpsilonImageCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  heldOutCount = OptionValue["HeldOutCount"];
  seed = OptionValue["Seed"];
  threads = OptionValue["Threads"];
  If[Length[DeleteDuplicates[dimensions]] =!= 1 ||
      First[dimensions] =!= Reverse[First[dimensions]] ||
      rootSquares =!= contract["SourceRootSquares"] ||
      ! PrimeQ[prime] || jetOrder > 64 || epsilonImageCount < 7,
    Return[<|"Status" -> "NativeTransportSeriesInputInvalid"|>]];
  result = Internal`WithLocalSettings[
    directory = CreateDirectory[];
    preparationFile = FileNameJoin[{directory, "connection.wl"}];,
    Catch[
      preparation = pathTransportNativeWriteConnectionPreparation[
        connection, variables, regulator, preparationFile];
      If[Lookup[preparation, "Status", None] =!=
          "NativeTransportPreparationV1", Throw[preparation]];
      pathData = pathTransportNativePathData[contract, endpoints, tau,
        prime, jetOrder, OptionValue["SheetValue"]];
      If[Lookup[pathData, "Status", None] =!=
          "NativeTransportPathDataV1", Throw[pathData]];
      BlockRandom[
        SeedRandom[seed, Method -> "MersenneTwister"];
        epsilonValues = RandomSample[Range[101, 1000000],
          epsilonImageCount]];
      batch = pathTransportNativeEvaluateJets[preparationFile,
        First[dimensions], variables, regulator, pathData, epsilonValues,
        "Threads" -> threads];
      If[Lookup[batch, "Status", None] =!=
          "NativeTransportJetBatchV1", Throw[batch]];
      interpolated = pathTransportNativeInterpolateJets[batch,
        epsilonValues, DeleteDuplicates[requestedOrders],
        maximumTotalDegree, heldOutCount];
      If[Lookup[interpolated, "Status", None] =!=
          "NativeTransportInterpolatedJetsV1", Throw[interpolated]];
      sourceJets = interpolated["CoefficientJets"];
      pathJets = Map[Function[tensor,
        Table[Mod[
          pathTransportNativeJetMul[pathData["XDerivativeJet"],
            tensor[[1, row, column]], prime] +
          pathTransportNativeJetMul[pathData["YDerivativeJet"],
            tensor[[2, row, column]], prime], prime],
          {row, First[dimensions][[1]]},
          {column, First[dimensions][[2]]}]], sourceJets];
      <|"Status" -> "NativeTransportSeriesDataV1", "Prime" -> prime,
        "JetOrder" -> jetOrder, "Dimensions" -> First[dimensions],
        "RequestedOrders" -> Keys[pathJets], "PathCoefficientJets" -> pathJets,
        "SheetValue" -> pathData["SheetValue"],
        "RootSquareOnPath" -> pathData["RootSquareOnPath"],
        "PathData" -> KeyDrop[pathData,
          {"XJet", "YJet", "XDerivativeJet", "YDerivativeJet",
           "DeltaJets", "RootJets"}],
        "PhaseSeconds" -> <|"PreparationWrite" -> preparation["Seconds"],
          "NativeWall" -> batch["WallSeconds"],
          "NativeParse" -> batch["ParseSeconds"],
          "NativeEvaluate" -> batch["EvaluationSeconds"],
          "InterpolationWall" -> interpolated["InterpolationWallSeconds"]|>,
        "DegreeHistogram" -> interpolated["DegreeHistogram"],
        "InterpolationSampleCount" -> interpolated["SampleCount"],
        "Threads" -> batch["Threads"]|>],
    If[StringQ[directory] && DirectoryQ[directory],
      Quiet[DeleteDirectory[directory, DeleteContents -> True]]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - started]],
    <|"Status" -> "NativeTransportSeriesFailed"|>]
];
pathTransportNativeSeriesData[___] :=
  <|"Status" -> "NativeTransportSeriesInputInvalid"|>;

pathTransportNativeEdgeSeries[data_Association, ranges_List,
    edge : {_Integer, _Integer}, order_Integer,
    requestedJetOrder_Integer, requestedPrime_Integer, requestedSheet_] :=
 Module[{tensor},
  If[Lookup[data, "Status", None] =!= "NativeTransportSeriesDataV1" ||
      requestedPrime =!= data["Prime"] ||
      requestedJetOrder > data["JetOrder"] ||
      ! KeyExistsQ[data["PathCoefficientJets"], order] ||
      !(requestedSheet === data["SheetValue"] || requestedSheet === None),
    Return[<|"Status" -> "NativeTransportEdgeSeriesUnavailable",
      "Edge" -> edge, "Order" -> order|>]];
  tensor = data["PathCoefficientJets"][order][[
    ranges[[edge[[1]]]], ranges[[edge[[2]]]],
    1 ;; requestedJetOrder + 1]];
  tensor
];
pathTransportNativeEdgeSeries[___] :=
  <|"Status" -> "NativeTransportEdgeSeriesUnavailable"|>;

pathTransportNativeDiagonalSeries[data_Association, ranges_List,
    block_Integer, requestedJetOrder_Integer,
    requestedPrime_Integer, requestedSheet_] :=
  pathTransportNativeEdgeSeries[data, ranges, {block, block}, 1,
    requestedJetOrder, requestedPrime, requestedSheet];
pathTransportNativeDiagonalSeries[___] :=
  <|"Status" -> "NativeTransportDiagonalSeriesUnavailable"|>;

(* A provider-backed formal graph contains only block dimensions, the exact
   epsilon-depth schedule and opaque provider handles.  It deliberately does
   not retain Ahat: all connection coefficients come from one native series
   cache at evaluation time. *)
pathTransportNativeFormalGraph[assembly_Association,
    budget_Association, kmin_List, constantTop_List,
    tau_Symbol, regulator_] := Module[
  {ranges, nb, rmin, need, schedule, edges, edgeWindows,
   requiredOrders, extraction, diagonal, prepared, graph},
  ranges = Lookup[assembly, "Ranges", Missing["NoRanges"]];
  nb = Length[Lookup[assembly, "Blocks", {}]];
  rmin = Lookup[budget, "RMin", Missing["NoRMin"]];
  need = Lookup[budget, "Need", Missing["NoNeed"]];
  If[! MatchQ[ranges, {{__Integer?Positive} ..}] ||
      Length[ranges] =!= nb || Dimensions[rmin] =!= {nb, nb} ||
      ! MatchQ[need, {___Integer}] || Length[need] =!= nb ||
      ! MatchQ[kmin, {___Integer}] || Length[kmin] =!= nb ||
      ! MatchQ[constantTop, {___Integer}] ||
      Length[constantTop] =!= nb,
    Return[<|"Status" -> "NativeTransportFormalGraphInputInvalid"|>]];
  schedule = masterTransportBWSchedule[rmin, kmin, need];
  edges = Flatten[Table[
    If[i > j && rmin[[i, j]] =!= Infinity, {i, j}, Nothing],
    {i, nb}, {j, nb}], 1];
  edgeWindows = Association @@ Table[edge ->
      {rmin[[edge[[1]], edge[[2]]]],
        schedule["Top"][[edge[[1]]]] -
          schedule["Low"][[edge[[2]]]]},
    {edge, edges}];
  requiredOrders = If[edgeWindows === <||>, {},
    Union @@ (Range @@ # & /@ Values[edgeWindows])];
  extraction = Association @@ Table[edge -> Function[order, $Failed],
    {edge, edges}];
  diagonal = Association @@ Table[i -> ConstantArray[0,
      {Length[ranges[[i]]], Length[ranges[[i]]]}], {i, nb}];
  prepared = <|"Status" -> "PathTransportExceptionPreparedV1",
    "Budget" -> budget, "Ahat" -> None|>;
  graph = pathTransportExceptionFormalLower[prepared, assembly, tau,
    regulator, "OrderExtraction" -> extraction,
    "DiagonalOrderOne" -> diagonal, "KMinPerBlock" -> kmin,
    "ConstantTopPerBlock" -> constantTop];
  If[Lookup[graph, "Status", None] =!= "OKFormalLowerGraph",
    Return[graph]];
  $pathTransportExceptionFormalGraphs[graph["GraphID"],
    "ProviderOnly"] = True;
  Join[graph, <|"ProviderRoute" -> "NativeTransportSeriesDataV1",
    "EdgeOrderWindows" -> edgeWindows,
    "RequiredCouplingOrders" -> requiredOrders|>]
];
pathTransportNativeFormalGraph[___] :=
  <|"Status" -> "NativeTransportFormalGraphInputInvalid"|>;

Options[pathTransportNativeFormalEvaluate] = {
  "ConstantValues" -> None,
  "Requests" -> Automatic,
  "TauOrder" -> Automatic
};

pathTransportNativeFormalEvaluate[graph_Association,
    seriesData_Association, assembly_Association,
    OptionsPattern[]] := Module[
  {ranges, windows, requests, tauOrder, requiredOrders,
   availableOrders, edgeProvider, diagonalProvider},
  ranges = Lookup[assembly, "Ranges", Missing["NoRanges"]];
  windows = Lookup[graph, "Windows", Missing["NoWindows"]];
  requiredOrders = Lookup[graph, "RequiredCouplingOrders", {}];
  availableOrders = Lookup[seriesData, "RequestedOrders", {}];
  If[Lookup[graph, "Status", None] =!= "OKFormalLowerGraph" ||
      Lookup[seriesData, "Status", None] =!=
        "NativeTransportSeriesDataV1" ||
      ! MatchQ[ranges, {{__Integer?Positive} ..}] ||
      ! AssociationQ[windows] ||
      Complement[requiredOrders, availableOrders] =!= {},
    Return[<|"Status" -> "NativeTransportFormalEvaluationInputInvalid",
      "MissingCouplingOrders" -> Complement[requiredOrders,
        availableOrders]|>]];
  requests = Replace[OptionValue["Requests"], Automatic :>
    Flatten[Table[{block, order}, {block, Length[ranges]},
      {order, windows["Low"][[block]], windows["Top"][[block]]}], 1]];
  tauOrder = Replace[OptionValue["TauOrder"], Automatic :>
    seriesData["JetOrder"]];
  edgeProvider = Function[{edge, order, requestedJetOrder,
      requestedPrime, requestedSheet},
    pathTransportNativeEdgeSeries[seriesData, ranges, edge, order,
      requestedJetOrder, requestedPrime, requestedSheet]];
  diagonalProvider = Function[{block, requestedJetOrder,
      requestedPrime, requestedSheet},
    pathTransportNativeDiagonalSeries[seriesData, ranges, block,
      requestedJetOrder, requestedPrime, requestedSheet]];
  pathTransportExceptionFormalEvaluate[graph, requests,
    "TauOrder" -> tauOrder, "Prime" -> seriesData["Prime"],
    "SheetData" -> seriesData["SheetValue"],
    "ConstantValues" -> OptionValue["ConstantValues"],
    "EdgeSeries" -> edgeProvider,
    "DiagonalSeries" -> diagonalProvider]
];
pathTransportNativeFormalEvaluate[___] :=
  <|"Status" -> "NativeTransportFormalEvaluationInputInvalid"|>;

(* One production acceptance: compare every returned coefficient jet with
   the original block differential equation and with its declared origin
   constant, in exact arithmetic modulo the provider prime. *)
pathTransportNativeFormalAccept[graph_Association,
    evaluation_Association, seriesData_Association,
    assembly_Association, constants_] := Module[
  {p, t, ranges, nb, windows, constantWindows, nodes, edgeWindows,
   edges, zeroJet, jetMul, matVec, nodeSeries, constantAt,
   derivative, residualFailure = None, basepointFailure = None,
   residualCount = 0, basepointCount = 0, diag, rhs, lhs, edge,
   beta, lowerOrder, edgeMatrix, actualBase, expectedBase},
  p = Lookup[seriesData, "Prime", None];
  t = Lookup[evaluation, "TruncationOrder", None];
  ranges = Lookup[assembly, "Ranges", Missing["NoRanges"]];
  nb = Length[Lookup[assembly, "Blocks", {}]];
  windows = Lookup[graph, "Windows", Missing["NoWindows"]];
  constantWindows = Lookup[graph, "ConstantWindows",
    Missing["NoConstantWindows"]];
  nodes = Lookup[evaluation, "Nodes", Missing["NoNodes"]];
  edgeWindows = Lookup[graph, "EdgeOrderWindows", <||>];
  If[Lookup[graph, "Status", None] =!= "OKFormalLowerGraph" ||
      Lookup[evaluation, "Status", None] =!=
        "OKModularGraphSeriesBatch" ||
      Lookup[seriesData, "Status", None] =!=
        "NativeTransportSeriesDataV1" ||
      ! PrimeQ[p] || ! IntegerQ[t] || t < 1 ||
      ! MatchQ[ranges, {{__Integer?Positive} ..}] ||
      Length[ranges] =!= nb || ! AssociationQ[windows] ||
      ! AssociationQ[constantWindows] || ! AssociationQ[nodes] ||
      ! AssociationQ[edgeWindows],
    Return[<|"Status" -> "NativeTransportFormalAcceptanceInputInvalid"|>]];
  zeroJet = ConstantArray[0, t + 1];
  jetMul[a_List, b_List] := Table[Mod[Sum[
      a[[k + 1]] b[[degree - k + 1]], {k, 0, degree}], p],
    {degree, 0, t}];
  matVec[matrix_, vector_] := Table[Mod[Total[Table[
      jetMul[matrix[[row, column]], vector[[column]]],
      {column, Length[vector]}]], p], {row, Length[matrix]}];
  nodeSeries[block_, order_] := If[
    windows["Low"][[block]] <= order <= windows["Top"][[block]] &&
      KeyExistsQ[nodes, {block, order}],
    nodes[{block, order}]["Series"],
    Table[zeroJet, {Length[ranges[[block]]]}]];
  constantAt[block_, order_, component_] := Module[{value},
    value = Which[
      AssociationQ[constants], Lookup[constants,
        Key[{block, order, component}], Missing["NoConstant"]],
      constants =!= None, constants[block, order, component],
      True, Missing["NoConstant"]];
    If[! IntegerQ[value], Missing["NoConstant"], Mod[value, p]]];
  derivative[jet_List] := Table[Mod[degree jet[[degree + 1]], p],
    {degree, 1, t}];
  edges = Keys[edgeWindows];
  Do[
    Module[{block = request[[1]], order = request[[2]], value},
      value = nodeSeries[block, order];
      diag = pathTransportNativeDiagonalSeries[seriesData, ranges,
        block, t, p, seriesData["SheetValue"]];
      If[AssociationQ[diag],
        residualFailure = <|"Status" -> "DiagonalSeriesUnavailable",
          "Block" -> block|>; Break[]];
      rhs = matVec[diag, nodeSeries[block, order - 1]];
      Do[
        edge = candidateEdge;
        If[edge[[1]] =!= block, Continue[]];
        Do[
          lowerOrder = order - beta;
          If[windows["Low"][[edge[[2]]]] <= lowerOrder <=
              windows["Top"][[edge[[2]]]],
            edgeMatrix = pathTransportNativeEdgeSeries[seriesData,
              ranges, edge, beta, t, p, seriesData["SheetValue"]];
            If[AssociationQ[edgeMatrix],
              residualFailure = <|"Status" -> "EdgeSeriesUnavailable",
                "Edge" -> edge, "Order" -> beta|>; Break[]];
            rhs = Mod[rhs + matVec[edgeMatrix,
              nodeSeries[edge[[2]], lowerOrder]], p]],
          {beta, edgeWindows[edge][[1]], edgeWindows[edge][[2]]}];
        If[residualFailure =!= None, Break[]],
        {candidateEdge, edges}];
      If[residualFailure =!= None, Break[]];
      lhs = derivative /@ value;
      residualCount += Length[Flatten[lhs]];
      If[lhs =!= (Take[#, t] & /@ rhs),
        residualFailure = <|"Status" -> "DifferentialEquationMismatch",
          "Block" -> block, "Order" -> order|>; Break[]];
      actualBase = value[[All, 1]];
      expectedBase = If[
        constantWindows["Low"][[block]] <= order <=
          constantWindows["Top"][[block]],
        Table[constantAt[block, order, component],
          {component, Length[ranges[[block]]]}],
        ConstantArray[0, Length[ranges[[block]]]]];
      basepointCount += Length[actualBase];
      If[AnyTrue[expectedBase, MissingQ] || actualBase =!= expectedBase,
        basepointFailure = <|"Status" -> "BasepointConditionMismatch",
          "Block" -> block, "Order" -> order|>; Break[]]],
    {request, Keys[nodes]}];
  Which[
    residualFailure =!= None, residualFailure,
    basepointFailure =!= None, basepointFailure,
    True, <|"Status" -> "NativeTransportFormalAcceptedV1",
      "Prime" -> p, "TauOrder" -> t,
      "NodeCount" -> Length[nodes],
      "ResidualCoefficientCount" -> residualCount,
      "BasepointCoefficientCount" -> basepointCount|>]
];
pathTransportNativeFormalAccept[___] :=
  <|"Status" -> "NativeTransportFormalAcceptanceInputInvalid"|>;

(* A serializable artifact stores the recurrence itself, not its process-local
   registry id and not expanded nested quadratures.  SourceDescriptor is
   caller-owned provenance for rebuilding the accepted connection. *)
pathTransportNativeArtifactCreate[graph_Association,
    assembly_Association, contract_Association, endpoints : {_, _},
    sourceDescriptor_Association, evidence_Association] := Module[
  {gid, data, blockData},
  gid = Lookup[graph, "GraphID", None];
  data = Lookup[$pathTransportExceptionFormalGraphs, Key[gid],
    Missing["GraphReleased"]];
  If[Lookup[graph, "Status", None] =!= "OKFormalLowerGraph" ||
      MissingQ[data] || ! pathTransportExceptionContractQ[contract] ||
      ! MatchQ[Lookup[assembly, "Ranges", None],
        {{__Integer?Positive} ..}] ||
      Length[assembly["Ranges"]] =!=
        Length[Lookup[assembly, "Blocks", {}]],
    Return[<|"Status" -> "NativeTransportArtifactInputInvalid"|>]];
  blockData = Map[KeyTake[#,
      {"Dimension", "Feeders", "KernelMin", "RequiredInverseOrder"}] &,
    data["Blocks"]];
  <|"Status" -> "NativeTransportFormalArtifactV1",
    "ArtifactVersion" -> 1,
    "Assembly" -> KeyTake[assembly, {"Family", "Blocks", "Ranges"}],
    "PathContract" -> contract, "Endpoints" -> endpoints,
    "SourceDescriptor" -> sourceDescriptor,
    "Recurrence" -> <|"Blocks" -> blockData,
      "Selected" -> data["Selected"], "Low" -> data["Low"],
      "Top" -> data["Top"], "RMin" -> data["RMin"],
      "KMin" -> data["KMin"], "ConstantTop" -> data["ConstantTop"],
      "Tau" -> data["Tau"], "Regulator" -> data["Regulator"],
      "ConstantHead" -> data["ConstantHead"],
      "EdgeOrderWindows" -> graph["EdgeOrderWindows"],
      "RequiredCouplingOrders" -> graph["RequiredCouplingOrders"]|>,
    "Evidence" -> evidence,
    "Claim" -> "Serializable formal variation-of-constants recurrence on the declared path, up to independent boundary constants. Native coefficient providers instantiate it at exact finite-field images. A truncated origin jet is not an endpoint value."|>
];
pathTransportNativeArtifactCreate[___] :=
  <|"Status" -> "NativeTransportArtifactInputInvalid"|>;

pathTransportNativeArtifactOpen[artifact_Association] := Module[
  {assembly, recurrence, ranges, nb, blocks, gid, graph},
  assembly = Lookup[artifact, "Assembly", Missing["NoAssembly"]];
  recurrence = Lookup[artifact, "Recurrence", Missing["NoRecurrence"]];
  If[Lookup[artifact, "Status", None] =!=
        "NativeTransportFormalArtifactV1" ||
      Lookup[artifact, "ArtifactVersion", None] =!= 1 ||
      ! AssociationQ[assembly] || ! AssociationQ[recurrence],
    Return[<|"Status" -> "NativeTransportArtifactInvalid"|>]];
  ranges = Lookup[assembly, "Ranges", Missing["NoRanges"]];
  nb = Length[Lookup[assembly, "Blocks", {}]];
  blocks = Lookup[recurrence, "Blocks", Missing["NoBlocks"]];
  If[! MatchQ[ranges, {{__Integer?Positive} ..}] ||
      Length[ranges] =!= nb || ! AssociationQ[blocks] ||
      Sort[Keys[blocks]] =!= Range[nb] ||
      ! AllTrue[Range[nb], Function[i,
        Lookup[blocks[i], "Dimension", None] === Length[ranges[[i]]] &&
          MatchQ[Lookup[blocks[i], "Feeders", None],
            {___Integer?Positive}] &&
          IntegerQ[Lookup[blocks[i], "KernelMin", None]] &&
          IntegerQ[Lookup[blocks[i], "RequiredInverseOrder", None]]]],
    Return[<|"Status" -> "NativeTransportArtifactShapeInvalid"|>]];
  blocks = Map[Function[blockData, Join[blockData, <|
      "M" -> ConstantArray[0,
        {blockData["Dimension"], blockData["Dimension"]}],
      "EdgeHandles" -> Association @@ Table[
        feeder -> Function[order, $Failed],
        {feeder, blockData["Feeders"]}]|>]], blocks];
  gid = Unique["pathTransportFormalGraph"];
  $pathTransportExceptionFormalGraphs[gid] = <|
    "Blocks" -> blocks, "Selected" -> recurrence["Selected"],
    "Low" -> recurrence["Low"], "Top" -> recurrence["Top"],
    "RMin" -> recurrence["RMin"], "KMin" -> recurrence["KMin"],
    "ConstantTop" -> recurrence["ConstantTop"],
    "Tau" -> recurrence["Tau"],
    "Regulator" -> recurrence["Regulator"],
    "ConstantHead" -> recurrence["ConstantHead"],
    "ProviderOnly" -> True|>;
  graph = <|"Status" -> "OKFormalLowerGraph", "GraphID" -> gid,
    "Blocks" -> recurrence["Selected"],
    "Windows" -> <|"Low" -> recurrence["Low"],
      "Top" -> recurrence["Top"]|>,
    "ConstantWindows" -> <|"Low" -> recurrence["KMin"],
      "Top" -> recurrence["ConstantTop"]|>,
    "IOrders" -> Association @@ Table[i -> Association @@ Table[
        order -> pathTransportFormalLowerNode[gid, i, order],
        {order, recurrence["Low"][[i]], recurrence["Top"][[i]]}],
      {i, recurrence["Selected"]}],
    "ConstantHead" -> recurrence["ConstantHead"],
    "ProviderRoute" -> "NativeTransportSeriesDataV1",
    "EdgeOrderWindows" -> recurrence["EdgeOrderWindows"],
    "RequiredCouplingOrders" -> recurrence["RequiredCouplingOrders"],
    "Artifact" -> artifact|>;
  graph
];
pathTransportNativeArtifactOpen[___] :=
  <|"Status" -> "NativeTransportArtifactInvalid"|>;

Options[pathTransportNativeConnectionFromArtifact] = {
  "RepositoryRoot" -> Automatic,
  "ScratchRoot" -> Automatic
};

pathTransportNativeConnectionFromArtifact[artifact_Association,
    OptionsPattern[]] := Module[
  {repositoryRoot, scratchRoot, descriptor, kind, stateRelative,
   stateFile, state, field, connection, assembly, ranges, dimension,
   checkpointRelative, checkpointFile, checkpoint, hardBlock,
   lowerColumns, installedRow, variables, rowSeconds = 0.},
  If[Lookup[artifact, "Status", None] =!=
      "NativeTransportFormalArtifactV1",
    Return[<|"Status" -> "NativeTransportSourceArtifactInvalid"|>]];
  repositoryRoot = Replace[OptionValue["RepositoryRoot"],
    Automatic :> DirectoryName[$feynFacetDirectory]];
  scratchRoot = Replace[OptionValue["ScratchRoot"],
    Automatic :> repositoryRoot <> "-codex"];
  descriptor = Lookup[artifact, "SourceDescriptor", <||>];
  kind = Lookup[descriptor, "Kind", None];
  stateRelative = Lookup[descriptor, "ScratchRelativeStateFile",
    Lookup[descriptor, "RepositoryRelativeStateFile", Missing["NoState"]]];
  If[! StringQ[repositoryRoot] || ! StringQ[scratchRoot] ||
      ! StringQ[stateRelative],
    Return[<|"Status" -> "NativeTransportSourceDescriptorInvalid"|>]];
  stateFile = FileNameJoin[{If[
      KeyExistsQ[descriptor, "ScratchRelativeStateFile"], scratchRoot,
      repositoryRoot], stateRelative}];
  If[! FileExistsQ[stateFile],
    Return[<|"Status" -> "NativeTransportSourceStateMissing",
      "File" -> stateFile|>]];
  state = Quiet[Check[Get[stateFile], $Failed]];
  If[! AssociationQ[state],
    Return[<|"Status" -> "NativeTransportSourceStateInvalid"|>]];
  field = Lookup[descriptor, "ConnectionField", "A"];
  connection = Lookup[state, field, Missing["NoConnection"]];
  assembly = artifact["Assembly"];
  ranges = assembly["Ranges"];
  dimension = Total[Length /@ ranges];
  If[Dimensions /@ connection =!= {{dimension, dimension},
      {dimension, dimension}} ||
      Lookup[state, "Ranges", ranges] =!= ranges,
    Return[<|"Status" -> "NativeTransportSourceConnectionInvalid"|>]];
  Which[
    kind === "StateConnectionV1", Null,
    kind === "AcceptedCompletedFamilyRowV1",
      checkpointRelative = Lookup[descriptor,
        "RepositoryRelativeCheckpointFile", Missing["NoCheckpoint"]];
      hardBlock = Lookup[descriptor, "HardBlock", Missing["NoHardBlock"]];
      If[! StringQ[checkpointRelative] || ! IntegerQ[hardBlock] ||
          ! Between[hardBlock, {1, Length[ranges]}],
        Return[<|"Status" -> "NativeTransportSourceDescriptorInvalid"|>]];
      checkpointFile = FileNameJoin[{repositoryRoot, checkpointRelative}];
      If[! FileExistsQ[checkpointFile],
        Return[<|"Status" -> "NativeTransportSourceCheckpointMissing",
          "File" -> checkpointFile|>]];
      checkpoint = Quiet[Check[Get[checkpointFile], $Failed]];
      variables = artifact["PathContract"]["Variables"];
      If[! AssociationQ[checkpoint] ||
          ! KeyExistsQ[checkpoint, "PrevD"],
        Return[<|"Status" -> "NativeTransportSourceCheckpointInvalid"|>]];
      {rowSeconds, installedRow} = AbsoluteTiming[
        familyRowGaugeAssembleInstalledRow[connection,
          ranges[[hardBlock]], checkpoint["PrevD"], variables]];
      lowerColumns = Flatten[Take[ranges, hardBlock - 1]];
      If[Dimensions[installedRow] =!=
          {2, Length[ranges[[hardBlock]]], Length[lowerColumns]},
        Return[<|"Status" -> "NativeTransportAcceptedRowInvalid",
          "ObservedDimensions" -> Dimensions[installedRow]|>]];
      connection[[All, ranges[[hardBlock]], lowerColumns]] = installedRow,
    True,
      Return[<|"Status" -> "NativeTransportSourceKindUnsupported",
        "Kind" -> kind|>]];
  <|"Status" -> "NativeTransportConnectionV1",
    "Connection" -> connection,
    "Variables" -> artifact["PathContract"]["Variables"],
    "Regulator" -> artifact["Recurrence"]["Regulator"],
    "RootSquares" -> artifact["PathContract"]["SourceRootSquares"],
    "StateFile" -> stateFile, "RowAssemblySeconds" -> N[rowSeconds]|>
];
pathTransportNativeConnectionFromArtifact[___] :=
  <|"Status" -> "NativeTransportSourceArtifactInvalid"|>;

Options[pathTransportNativeRunArtifact] = {
  "RepositoryRoot" -> Automatic,
  "ScratchRoot" -> Automatic,
  "EpsilonImageCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "HeldOutCount" -> 3,
  "Seed" -> 2026083111,
  "SheetValue" -> Automatic,
  "Threads" -> Automatic,
  "ConstantValues" -> Automatic,
  "TauOrder" -> 8
};

pathTransportNativeRunArtifact[artifact_Association, prime_Integer,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], source, connection, contract, recurrence,
   requestedOrders, tauOrder, seriesData, graph, constants, evaluation,
   acceptance, result},
  source = pathTransportNativeConnectionFromArtifact[artifact,
    "RepositoryRoot" -> OptionValue["RepositoryRoot"],
    "ScratchRoot" -> OptionValue["ScratchRoot"]];
  If[Lookup[source, "Status", None] =!= "NativeTransportConnectionV1",
    Return[source]];
  connection = source["Connection"];
  contract = artifact["PathContract"];
  recurrence = artifact["Recurrence"];
  requestedOrders = recurrence["RequiredCouplingOrders"];
  tauOrder = OptionValue["TauOrder"];
  seriesData = pathTransportNativeSeriesData[connection,
    source["Variables"], source["Regulator"], source["RootSquares"],
    contract, artifact["Endpoints"], recurrence["Tau"],
    requestedOrders, prime, tauOrder,
    "EpsilonImageCount" -> OptionValue["EpsilonImageCount"],
    "MaximumTotalDegree" -> OptionValue["MaximumTotalDegree"],
    "HeldOutCount" -> OptionValue["HeldOutCount"],
    "Seed" -> OptionValue["Seed"],
    "SheetValue" -> OptionValue["SheetValue"],
    "Threads" -> OptionValue["Threads"]];
  Clear[connection];
  If[Lookup[seriesData, "Status", None] =!=
      "NativeTransportSeriesDataV1", Return[seriesData]];
  graph = pathTransportNativeArtifactOpen[artifact];
  If[Lookup[graph, "Status", None] =!= "OKFormalLowerGraph",
    Return[graph]];
  constants = Replace[OptionValue["ConstantValues"], Automatic :>
    With[{p = prime}, Function[Mod[
      1000003 #1 + 1009 (#2 + 100) + #3, p]]]];
  result = Internal`WithLocalSettings[Null,
    evaluation = pathTransportNativeFormalEvaluate[graph, seriesData,
      artifact["Assembly"], "ConstantValues" -> constants,
      "TauOrder" -> tauOrder];
    acceptance = pathTransportNativeFormalAccept[graph, evaluation,
      seriesData, artifact["Assembly"], constants];
    <|"Status" -> If[Lookup[acceptance, "Status", None] ===
        "NativeTransportFormalAcceptedV1",
      "NativeTransportArtifactRunAcceptedV1",
      Lookup[acceptance, "Status", "NativeTransportArtifactRunFailed"]],
      "Prime" -> prime, "TauOrder" -> tauOrder,
      "SeriesData" -> seriesData, "Evaluation" -> evaluation,
      "Acceptance" -> acceptance,
      "Source" -> KeyDrop[source, "Connection"],
      "Seconds" -> N[AbsoluteTime[] - started]|>,
    pathTransportExceptionFormalRelease[graph]];
  result
];
pathTransportNativeRunArtifact[___] :=
  <|"Status" -> "NativeTransportArtifactRunInputInvalid"|>;

Options[TransportPathArtifactRun] = Options[pathTransportNativeRunArtifact];

TransportPathArtifactRun[file_String, prime_Integer,
    opts : OptionsPattern[]] := Module[{artifact},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "TransportPathArtifactFileMissing",
      "File" -> file|>]];
  artifact = Quiet[Check[Get[file], $Failed]];
  If[! AssociationQ[artifact],
    Return[<|"Status" -> "TransportPathArtifactFileInvalid",
      "File" -> file|>]];
  pathTransportNativeRunArtifact[artifact, prime, opts]
];
TransportPathArtifactRun[artifact_Association, prime_Integer,
    opts : OptionsPattern[]] :=
  pathTransportNativeRunArtifact[artifact, prime, opts];
TransportPathArtifactRun[___] :=
  <|"Status" -> "TransportPathArtifactRunInputInvalid"|>;
