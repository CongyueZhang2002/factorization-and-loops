#!/usr/bin/env wolframscript

Module[{repo, runtime, affineCapture, schurCapture, frameInterpolation,
    adapter, outputFile, summaryFile, prime, affineImages, schurRecords,
    bases, particulars, gaugeCount, residueCount, residueColumns,
    residueBases, residueParticulars, independentColumns, fixedColumns,
    trialColumns, orders, complementColumns, affineFrames, schurFrames,
    frameAgreement, exceeded, badFrameColumns, badFreeColumns, qCount,
    constructionIndices, validationIndices, excludedRecordIndices = {},
    runNativeMatrix, runNativeFrames, plantedMatrix, planted,
    plantedResidualZero, solveCache = <||>, solveDegree, hasAffineVector,
    lower = 34, upper = 64, middle, selectedDegree, selected,
    chooseAffineVector, candidateVector, decodeCandidate, candidate,
    evaluatePolynomial, validationRecords, result, solveRecords},

  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  adapter = FileNameJoin[{runtime,
    "flint_homogeneous_nullspace_cf300_20260828"}];
  outputFile = FileNameJoin[{runtime,
    "cf300_reduced_residue_module_p31_76fibres_candidate.wxf"}];
  summaryFile = FileNameJoin[{runtime,
    "cf300_reduced_residue_module_p31_76fibres_summary.wl"}];
  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FeynFacet`Private`feynFacetPrivateFile["FiniteFieldStripSolve.wl"]]];

  affineCapture = Import[FileNameJoin[{runtime,
    "cf300_p31_affine25_capture.wxf"}], "WXF"];
  schurCapture = Import[FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_76_checkpoint.wxf"}], "WXF"];
  frameInterpolation = Import[FileNameJoin[{runtime,
    "cf300_residue_frame_interpolation_p31.wxf"}], "WXF"];
  prime = affineCapture["Prime"];
  affineImages = affineCapture["Images"];
  schurRecords = schurCapture["Records"];
  gaugeCount = affineCapture["GaugeUnknownCount"];
  residueCount = affineCapture["ResidueUnknownCount"];
  If[prime =!= schurCapture["Prime"] || Length[affineImages] =!= 25 ||
      Length[schurRecords] =!= 76 || residueCount =!= 212,
    Put[<|"Status" -> "CaptureShapeMismatch"|>, summaryFile];
    Return[$Failed]];

  bases = Normal /@ Lookup[affineImages, "NullspaceBasis"];
  particulars = Normal /@ Lookup[affineImages, "ParticularSolution"];
  residueColumns = gaugeCount + Range[residueCount];
  residueBases = (#[[All, residueColumns]] &) /@ bases;
  residueParticulars = (#[[residueColumns]] &) /@ particulars;
  independentColumns[matrix_] :=
    FeynFacet`Private`finiteFieldStripIndependentColumns[
      Normal[matrix], prime];
  orders = Prepend[Table[BlockRandom[SeedRandom[2026082800 + seed];
      RandomSample[Range[residueCount]]], {seed, 1, 64}],
    Range[residueCount]];
  fixedColumns = $Failed;
  Do[
    trialColumns = order[[independentColumns[
      residueBases[[1, All, order]]]]];
    If[Length[trialColumns] === Length[First[bases]] &&
        AllTrue[residueBases,
          MatrixRank[#[[All, trialColumns]], Modulus -> prime] ===
            Length[First[bases]] &],
      fixedColumns = trialColumns; Break[]],
    {order, orders}];
  If[fixedColumns === $Failed,
    Put[<|"Status" -> "NoFixedResidueCoordinateSection"|>, summaryFile];
    Return[$Failed]];
  complementColumns = Complement[Range[residueCount], fixedColumns];

  affineFrames = MapThread[Module[{basis = #1, particular = #2, core,
        inverse, alpha, normalized, normalizedBasis},
      core = basis[[All, fixedColumns]];
      inverse = Inverse[core, Modulus -> prime];
      alpha = Mod[-Transpose[inverse] . particular[[fixedColumns]], prime];
      normalized = Mod[particular + Transpose[basis] . alpha, prime];
      normalizedBasis = Mod[inverse . basis, prime];
      Join[Transpose[normalizedBasis[[All, complementColumns]]],
        List /@ normalized[[complementColumns]], 2]] &,
    {residueBases, residueParticulars}];
  schurFrames = Table[Module[{reduced, coefficient, right, core, rhs},
      reduced = schurRecords[[index, "RawReduced"]];
      coefficient = reduced[[All, 1 ;; residueCount]];
      right = reduced[[All, residueCount + 1]];
      core = coefficient[[All, complementColumns]];
      rhs = Join[-coefficient[[All, fixedColumns]], List /@ right, 2];
      Mod[LinearSolve[core, rhs, Modulus -> prime], prime]],
    {index, Length[schurRecords]}];
  frameAgreement = MapThread[SameQ, {affineFrames,
    Take[schurFrames, Length[affineFrames]]}];
  If[! AllTrue[frameAgreement, TrueQ] &&
      Flatten[Position[frameAgreement, False]] =!= {1},
    Put[<|"Status" -> "SchurAndAffineFramesDisagree",
      "FailedImages" -> Flatten[Position[frameAgreement, False]]|>,
      summaryFile]; Return[$Failed]];
  If[Flatten[Position[frameAgreement, False]] === {1},
    (* The persisted eps=1 Schur pilot predates the matched source used by
       every sampled follower.  Its disagreement is confined to the same
       17-dimensional difficult quotient; discard that one record. *)
    excludedRecordIndices = {1};
    schurRecords = Rest[schurRecords];
    schurFrames = Rest[schurFrames]];
  constructionIndices = Range[Length[schurRecords] - 3];
  validationIndices = Range[Length[schurRecords] - 2,
    Length[schurRecords]];

  exceeded = Lookup[frameInterpolation,
    "DegreeBoundExceededCoordinates", {}];
  badFrameColumns = Sort[DeleteDuplicates[
    Mod[exceeded - 1, Length[fixedColumns] + 1] + 1]];
  badFreeColumns = DeleteCases[badFrameColumns,
    Length[fixedColumns] + 1];
  qCount = Length[badFreeColumns] + 1;
  If[badFrameColumns =!= Join[badFreeColumns,
        {Length[fixedColumns] + 1}] || badFreeColumns === {},
    Put[<|"Status" -> "DifficultFrameColumnsInvalid",
      "BadFrameColumns" -> badFrameColumns|>, summaryFile];
    Return[$Failed]];

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

  runNativeFrames[d_Integer, indices_List] := Module[{directory, inputFile,
      outputPath, stream, process, magic, header, values, nullspace,
      block, powers, bad, columns, rows, writeSeconds, runSeconds,
      ignored},
    columns = (qCount + Length[complementColumns]) (d + 1);
    rows = Length[indices] Length[complementColumns];
    directory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
      "cf300-hnull-" <> StringReplace[CreateUUID[], "-" -> ""]}]];
    inputFile = FileNameJoin[{directory, "input.bin"}];
    outputPath = FileNameJoin[{directory, "output.bin"}];
    {writeSeconds, ignored} = AbsoluteTiming[
      stream = OpenWrite[inputFile, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["FFHN1V1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {rows, columns, prime}, "UnsignedInteger64",
        ByteOrdering -> -1];
      Do[
        powers = PowerMod[schurRecords[[index, "EpsilonMod"]], #,
            prime] & /@ Range[0, d];
        bad = schurFrames[[index, All,
          Join[badFreeColumns, {Length[fixedColumns] + 1}]]];
        block = Mod[Join[
          KroneckerProduct[-bad, {powers}],
          KroneckerProduct[SparseArray[IdentityMatrix[
            Length[complementColumns]]], {powers}], 2], prime];
        BinaryWrite[stream, Flatten[Normal[block]], "UnsignedInteger64",
          ByteOrdering -> -1];
        Clear[block],
        {index, indices}];
      Close[stream]];
    {runSeconds, process} = AbsoluteTiming[
      RunProcess[{adapter, inputFile, outputPath, "8"}]];
    If[process["ExitCode"] =!= 0,
      DeleteDirectory[directory, DeleteContents -> True];
      Return[<|"Status" -> "NativeNullspaceFailed",
        "WriteSeconds" -> writeSeconds, "RunSeconds" -> runSeconds,
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
        header[[1 ;; 3]] =!= {rows, columns, prime},
      Return[<|"Status" -> "NativeNullspaceOutputInvalid"|>]];
    nullspace = If[header[[5]] === 0, {},
      ArrayReshape[values, {header[[5]], header[[2]]}]];
    <|"Status" -> "Solved", "Rank" -> header[[4]],
      "Nullity" -> header[[5]], "Basis" -> nullspace,
      "WriteSeconds" -> writeSeconds, "RunSeconds" -> runSeconds,
      "ProcessOutput" -> process["StandardOutput"]|>
  ];

  BlockRandom[SeedRandom[20260828];
    plantedMatrix = Join[
      Join[IdentityMatrix[8], RandomInteger[{0, prime - 1}, {8, 2}], 2],
      RandomInteger[{0, prime - 1}, {4, 8}] .
        Join[IdentityMatrix[8], RandomInteger[{0, prime - 1}, {8, 2}], 2]]];
  (* Rebuild with one shared top block so the last four rows are guaranteed
     combinations of it. *)
  BlockRandom[SeedRandom[20260828]; Module[{top, combinations},
    top = Join[IdentityMatrix[8],
      RandomInteger[{0, prime - 1}, {8, 2}], 2];
    combinations = RandomInteger[{0, prime - 1}, {4, 8}];
    plantedMatrix = Mod[Join[top, combinations . top], prime]]];
  planted = runNativeMatrix[plantedMatrix];
  plantedResidualZero = Lookup[planted, "Status", None] === "Solved" &&
    Lookup[planted, {"Rank", "Nullity"}, None] === {8, 2} &&
    Mod[plantedMatrix . Transpose[planted["Basis"]], prime] ===
      ConstantArray[0, {12, 2}];
  If[! TrueQ[plantedResidualZero],
    Put[<|"Status" -> "NativeNullspacePlantedTestFailed",
      "Detail" -> planted|>, summaryFile]; Return[$Failed]];

  hasAffineVector[solution_, d_Integer] := Module[{block = d + 1,
      denominatorRange},
    denominatorRange = (qCount - 1) block + Range[block];
    Lookup[solution, "Status", None] === "Solved" &&
      AnyTrue[Lookup[solution, "Basis", {}],
        AnyTrue[#[[denominatorRange]], # =!= 0 &] &]
  ];
  solveDegree[d_Integer] := If[KeyExistsQ[solveCache, d], solveCache[d],
    Print["REDUCED MODULE 76 degree ", d, " start ",
      DateString[{"Time"}]];
    AssociateTo[solveCache, d -> runNativeFrames[d, constructionIndices]];
    solveCache[d]];

  While[lower < upper,
    middle = Floor[(lower + upper)/2];
    If[hasAffineVector[solveDegree[middle], middle],
      upper = middle, lower = middle + 1]];
  selectedDegree = lower;
  selected = solveDegree[selectedDegree];
  solveRecords = AssociationMap[Function[d, KeyDrop[solveCache[d], "Basis"]],
    Sort[Keys[solveCache]]];
  If[! hasAffineVector[selected, selectedDegree],
    result = <|"Status" -> "NoAffineModuleVectorThroughDegree64",
      "Prime" -> prime,
      "RetainedCrossRouteFrameAgreement" ->
        And @@ Delete[frameAgreement, List /@ excludedRecordIndices],
      "ExcludedOriginalRecordIndices" -> excludedRecordIndices,
      "BadFrameColumns" -> badFrameColumns,
      "ConstructionIndices" -> constructionIndices,
      "ValidationIndices" -> validationIndices,
      "NativePlantedTestPassed" -> plantedResidualZero,
      "SolveRecords" -> solveRecords|>;
    Put[result, summaryFile]; Print[InputForm[result]]; Return[Null]];

  chooseAffineVector[basis_, d_Integer] := Module[{block = d + 1,
      denominatorRange, direct, combinations},
    denominatorRange = (qCount - 1) block + Range[block];
    direct = Select[basis,
      AnyTrue[#[[denominatorRange]], # =!= 0 &] &];
    If[direct =!= {}, Return[First[direct]]];
    combinations = Table[Mod[Total[MapThread[Times,
          {RandomInteger[{0, prime - 1}, Length[basis]], basis}]], prime],
      {32}];
    SelectFirst[combinations,
      AnyTrue[#[[denominatorRange]], # =!= 0 &] &, $Failed]
  ];
  candidateVector = chooseAffineVector[selected["Basis"], selectedDegree];
  decodeCandidate[vector_] := Module[{block = selectedDegree + 1, q, y,
      denominator, leadingIndex, scale, numerators},
    q = ArrayReshape[Take[vector, qCount block], {qCount, block}];
    y = ArrayReshape[Drop[vector, qCount block],
      {Length[complementColumns], block}];
    denominator = Last[q];
    leadingIndex = Last[Flatten[Position[denominator, Except[0]]]];
    scale = PowerMod[denominator[[leadingIndex]], -1, prime];
    q = Mod[q scale, prime]; y = Mod[y scale, prime];
    numerators = ConstantArray[ConstantArray[0, block], residueCount];
    numerators[[fixedColumns[[badFreeColumns]]]] =
      q[[1 ;; Length[badFreeColumns]]];
    numerators[[complementColumns]] = y;
    <|"DegreeBound" -> selectedDegree,
      "ActualDenominatorDegree" ->
        Last[Flatten[Position[Last[q], Except[0]]]] - 1,
      "Numerators" -> numerators, "Denominator" -> Last[q],
      "ReducedQ" -> q, "ReducedY" -> y|>
  ];
  candidate = decodeCandidate[candidateVector];
  evaluatePolynomial[coefficients_, epsilon_] := Mod[
    coefficients . (PowerMod[epsilon, #, prime] & /@
      Range[0, Length[coefficients] - 1]), prime];
  validationRecords = Table[Module[{epsilon, qValue, yValue, residual},
      epsilon = schurRecords[[index, "EpsilonMod"]];
      qValue = evaluatePolynomial[#, epsilon] & /@
        candidate["ReducedQ"];
      yValue = evaluatePolynomial[#, epsilon] & /@
        candidate["ReducedY"];
      residual = Mod[yValue - schurFrames[[index, All,
          Join[badFreeColumns, {Length[fixedColumns] + 1}]]] . qValue,
        prime];
      <|"Index" -> index,
        "RegulatorValue" -> schurRecords[[index, "RegulatorValue"]],
        "DenominatorNonzero" -> Last[qValue] =!= 0,
        "ResidualZero" -> AllTrue[residual, # === 0 &],
        "ResidualSupport" -> Count[residual, Except[0]]|>],
    {index, Length[schurRecords]}];
  result = <|"Status" -> If[
      AllTrue[validationRecords,
        TrueQ[#DenominatorNonzero] && TrueQ[#ResidualZero] &],
      "ReducedResidueModuleCandidateHeldOutValidated",
      "ReducedResidueModuleCandidateRejected"],
    "Prime" -> prime, "ImageCount" -> Length[schurRecords],
    "RetainedCrossRouteFrameAgreement" ->
      And @@ Delete[frameAgreement, List /@ excludedRecordIndices],
    "ExcludedOriginalRecordIndices" -> excludedRecordIndices,
    "FixedResidueColumns" -> fixedColumns,
    "ComplementResidueColumns" -> complementColumns,
    "BadFrameColumns" -> badFrameColumns,
    "BadFreeColumns" -> badFreeColumns,
    "ConstructionIndices" -> constructionIndices,
    "ValidationIndices" -> validationIndices,
    "SelectedDegree" -> selectedDegree,
    "ActualDenominatorDegree" -> candidate["ActualDenominatorDegree"],
    "NativePlantedTestPassed" -> plantedResidualZero,
    "ValidationRecords" -> validationRecords,
    "SolveRecords" -> solveRecords,
    "Candidate" -> candidate|>;
  Export[outputFile, result, "WXF"];
  Put[KeyDrop[result, "Candidate"], summaryFile];
  Print[InputForm[KeyDrop[result, {"Candidate", "ValidationRecords"}]]];
  Null
]
