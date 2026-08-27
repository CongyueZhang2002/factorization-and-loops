#!/usr/bin/env wolframscript

(* External A4 backend benchmark.  No package files are modified. *)

$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];
priorBundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_m1_m2_2026-08-20"}];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
fixtureFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
  "fixture_CF254_9_7.wl"}];
system31File = FileNameJoin[{bundle, "a4_system_CF254_9_7_p31.wl"}];
pilotResultFile = FileNameJoin[{priorBundle,
  "m1_pilot_and_sample_result.wl"}];
referenceSystemFile = FileNameJoin[{priorBundle,
  "m1_later_system_cache.wl"}];
system61File = FileNameJoin[{bundle, "a4_system_CF254_9_7_p61.wl"}];
safeBuilderValidationFile = FileNameJoin[{bundle,
  "a4_safe_builder_validation.wl"}];
flintBinary = FileNameJoin[{bundle, "codex_a4_flint_solve"}];
resultFile = FileNameJoin[{bundle, "a4_backend_benchmark_result.wl"}];
prime31 = 2147483423;
prime61 = 2305843009213693951;

Get[loadFile];

ClearAll[codexA4PutAtomic];
codexA4PutAtomic[expression_, file_String] := Module[
  {temporary = file <> ".tmp"},
  Put[expression, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

ClearAll[codexA4BuildCore];
codexA4BuildCore[system_Association, plan_Association] := Module[
  {matrix, rightHandSide, independentRows, normalizationColumns,
   rank, nullity, unknownCount, selector, selectedMatrix,
   selectedRightHandSide, core, top, bottom, multipleRightHandSides},
  matrix = system["Matrix"];
  rightHandSide = system["RightHandSide"];
  independentRows = plan["IndependentEquationRows"];
  normalizationColumns = plan["NormalizationColumns"];
  rank = plan["GenericRank"];
  nullity = plan["Nullity"];
  unknownCount = plan["UnknownCount"];
  If[Dimensions[matrix][[2]] =!= unknownCount ||
      Length[independentRows] =!= rank ||
      Length[normalizationColumns] =!= nullity ||
      rank + nullity =!= unknownCount, Return[$Failed]];
  selector = SparseArray[
    MapIndexed[{First[#2], #1} -> 1 &, normalizationColumns],
    {nullity, unknownCount}];
  selectedMatrix = matrix[[independentRows]];
  selectedRightHandSide = rightHandSide[[independentRows]];
  core = Join[selectedMatrix, selector];
  top = Join[List /@ selectedRightHandSide,
    ConstantArray[0, {rank, nullity}], 2];
  bottom = Join[ConstantArray[0, {nullity, 1}],
    IdentityMatrix[nullity], 2];
  multipleRightHandSides = Developer`ToPackedArray[Join[top, bottom]];
  <|
    "Core" -> core,
    "RightHandSides" -> multipleRightHandSides,
    "Dimensions" -> Dimensions[core],
    "RightHandSideDimensions" -> Dimensions[multipleRightHandSides],
    "NonzeroEntries" -> Length[core["NonzeroValues"]]
  |>
];

ClearAll[codexA4ExportBinary];
codexA4ExportBinary[denseCore_List, denseRightHandSides_List,
    prime_Integer, file_String] := Module[
  {stream, seconds, rows, columns, rhsColumns},
  {rows, columns} = Dimensions[denseCore];
  rhsColumns = Dimensions[denseRightHandSides][[2]];
  {seconds, stream} = AbsoluteTiming[
    stream = OpenWrite[file, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["CFFA4V1\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {rows, columns, rhsColumns, prime},
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[denseCore], "UnsignedInteger64",
      ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[denseRightHandSides],
      "UnsignedInteger64", ByteOrdering -> -1];
    Close[stream]];
  <|"WallSeconds" -> seconds, "FileBytes" -> FileByteCount[file]|>
];

ClearAll[codexA4ImportSolution];
codexA4ImportSolution[file_String] := Module[
  {stream, magic, rows, rhsColumns, prime, values},
  stream = OpenRead[file, BinaryFormat -> True];
  magic = BinaryReadList[stream, "UnsignedInteger8", 8];
  {rows, rhsColumns, prime} = BinaryReadList[stream,
    "UnsignedInteger64", 3, ByteOrdering -> -1];
  values = BinaryReadList[stream, "UnsignedInteger64",
    rows rhsColumns, ByteOrdering -> -1];
  Close[stream];
  If[magic =!= ToCharacterCode["CFFA4X1\000"] ||
      Length[values] =!= rows rhsColumns, Return[$Failed]];
  <|"Prime" -> prime,
    "Solution" -> ArrayReshape[values, {rows, rhsColumns}]|>
];

ClearAll[codexA4RunFlint];
codexA4RunFlint[inputFile_String, outputFile_String,
    threads_Integer] := Module[{process, parsed, importSeconds, imported},
  process = RunProcess[{flintBinary, inputFile, outputFile,
    ToString[threads]}];
  parsed = Quiet[Check[
    ImportString[process["StandardOutput"], "RawJSON"], $Failed]];
  {importSeconds, imported} = AbsoluteTiming[
    codexA4ImportSolution[outputFile]];
  <|
    "ExitCode" -> process["ExitCode"],
    "StandardError" -> process["StandardError"],
    "Timing" -> parsed,
    "SolutionImportWallSeconds" -> importSeconds,
    "Imported" -> imported
  |>
];

(* Clone the current O2 sampler externally, replacing every packed-array
   constructor by Identity.  This preserves the current algebra and point
   schedule while forcing arbitrary-precision integer products at 61 bits.
   MatrixRank is intercepted only to expose the sampled matrix and RHS. *)
ClearAll[codexA4InstallSafeBuilder, CodexA4SafePrimeForms,
  CodexA4SafeSample, CodexA4BuildSafeSampleSystem, codexA4SystemQ];
$codexA4SafePrimeFormCache = <||>;
codexA4InstallSafeBuilder[] := Module[{primeFormRules, sampleRules},
  primeFormRules = DownValues[
    FeynFacet`Private`finiteFieldStripPrimeForms] /.
      FeynFacet`Private`finiteFieldStripPrimeForms ->
        CodexA4SafePrimeForms /.
      FeynFacet`Private`$finiteFieldStripPrimeFormCache ->
        $codexA4SafePrimeFormCache /.
      Developer`ToPackedArray -> Identity;
  sampleRules = DownValues[SampleEpsFormStripAffine] /.
      SampleEpsFormStripAffine -> CodexA4SafeSample /.
      FeynFacet`Private`finiteFieldStripPrimeForms ->
        CodexA4SafePrimeForms /.
      Developer`ToPackedArray -> Identity;
  DownValues[CodexA4SafePrimeForms] = primeFormRules;
  Options[CodexA4SafeSample] = Options[SampleEpsFormStripAffine];
  DownValues[CodexA4SafeSample] = sampleRules;
  If[DownValues[CodexA4SafePrimeForms] === {} ||
      DownValues[CodexA4SafeSample] === {}, $Failed, True]
];

CodexA4BuildSafeSampleSystem[record_Association, epsilonValue_,
    prime_Integer, preparation_Association] := Module[
  {rankCallCount = 0, capturedMatrix = Missing["NotCaptured"],
   capturedAugmented = Missing["NotCaptured"], sample,
   rightHandSide, metadata},
  sample = Internal`InheritedBlock[{MatrixRank},
    Unprotect[MatrixRank];
    MatrixRank[argument_?(
        MatrixQ[#] && Length[Dimensions[#]] === 2 &&
          Min[Dimensions[#]] > 1000 &), rankOptions___] := Module[{},
      rankCallCount++;
      Switch[rankCallCount,
        1, capturedMatrix = argument; 0,
        2, capturedAugmented = argument; 0,
        _, 0]];
    CodexA4SafeSample[
      record, epsilonValue, prime,
      "NumeratorDegreeOffset" -> {1, 0},
      "SolveAffineSystem" -> False,
      "RandomSeed" -> 2540908,
      "Preparation" -> preparation,
      "ExpectedFingerprint" -> preparation["Fingerprint"]]
  ];
  If[! AssociationQ[sample] || rankCallCount =!= 2 ||
      ! MatrixQ[capturedMatrix] || ! MatrixQ[capturedAugmented] ||
      Dimensions[capturedAugmented] =!=
        Dimensions[capturedMatrix] + {0, 1}, Return[$Failed]];
  rightHandSide = Normal[capturedAugmented[[All, -1]]];
  metadata = KeyDrop[sample,
    {"Rank", "AugmentedRank", "Nullity", "Consistent",
     "RankSeconds", "AugmentedRankSeconds"}];
  Join[metadata, <|
    "UnknownCount" -> Dimensions[capturedMatrix][[2]],
    "Matrix" -> capturedMatrix,
    "RightHandSide" -> rightHandSide,
    "CaptureMethod" ->
      "ExternalUnpackedO2SamplerWithMatrixRankInterception"
  |>]
];

codexA4SystemQ[system_, prime_Integer] := AssociationQ[system] &&
  Lookup[system, "Prime", Missing[]] === prime &&
  KeyExistsQ[system, "Matrix"] && KeyExistsQ[system, "RightHandSide"] &&
  MatrixQ[system["Matrix"]] && VectorQ[system["RightHandSide"]] &&
  Dimensions[system["Matrix"]] === {2176, 2144} &&
  Length[system["RightHandSide"]] === 2176;

If[! FileExistsQ[flintBinary],
  Print["FAILED: compile codex_a4_flint_solve first."]; Exit[2]];
record = Get[fixtureFile];
pilotResult = Get[pilotResultFile];
plan = pilotResult["Plan"];

If[codexA4InstallSafeBuilder[] === $Failed,
  Print["FAILED to install scalar-safe builder."]; Exit[4]];
preparation = PrepareEpsFormStripSampling[record];
If[! AssociationQ[preparation],
  Print["FAILED sampling preparation."]; Exit[5]];

If[FileExistsQ[safeBuilderValidationFile],
  safeBuilderValidation = Get[safeBuilderValidationFile],
  referenceSystem = Get[referenceSystemFile];
  Print["Validating unpacked sampler against the frozen p=1000003 matrix."];
  {safeBuilderValidationWallSeconds, validationSystem} = AbsoluteTiming[
    CodexA4BuildSafeSampleSystem[
      record, 1/11, 1000003, preparation]];
  safeBuilderValidation = <|
    "Prime" -> 1000003,
    "WallSeconds" -> safeBuilderValidationWallSeconds,
    "MatrixSameQ" -> (AssociationQ[validationSystem] &&
      SameQ[validationSystem["Matrix"], referenceSystem["Matrix"]]),
    "RightHandSideSameQ" -> (AssociationQ[validationSystem] &&
      SameQ[validationSystem["RightHandSide"],
        referenceSystem["RightHandSide"]]),
    "AcceptedPointsSameQ" -> (AssociationQ[validationSystem] &&
      SameQ[validationSystem["AcceptedPoints"],
        referenceSystem["AcceptedPoints"]])
  |>;
  safeBuilderValidation = Join[safeBuilderValidation,
    <|"AllSameQ" -> And @@ Values[KeyDrop[
      safeBuilderValidation, {"Prime", "WallSeconds"}]]|>];
  codexA4PutAtomic[safeBuilderValidation, safeBuilderValidationFile]
];
If[! TrueQ[safeBuilderValidation["AllSameQ"]],
  Print["FAILED scalar-safe builder validation: ",
    InputForm[safeBuilderValidation]]; Exit[6]];

system31 = If[FileExistsQ[system31File],
  Quiet[Check[Get[system31File], $Failed]], $Failed];
If[codexA4SystemQ[system31, prime31],
  Print["Loaded cached true 31-bit sampled system."],
  Print["Building true 31-bit sampled system with scalar-safe arithmetic."];
  {system31BuildWallSeconds, system31} = AbsoluteTiming[
    CodexA4BuildSafeSampleSystem[
      record, 1/11, prime31, preparation]];
  If[! codexA4SystemQ[system31, prime31],
    Print["FAILED true 31-bit system build."]; Exit[7]];
  system31 = Join[system31, <|
    "A4Builder" -> "UnpackedCurrentO2ActualFiniteFieldSample",
    "A4BuildWallSeconds" -> system31BuildWallSeconds,
    "RecordFingerprint" -> Hash[record, "SHA256", "HexString"]
  |>];
  codexA4PutAtomic[system31, system31File];
  Print["Saved true 31-bit system; build wall ",
    system31BuildWallSeconds, " s."]
];

system61 = If[FileExistsQ[system61File],
  Quiet[Check[Get[system61File], $Failed]], $Failed];
If[codexA4SystemQ[system61, prime61],
  Print["Loaded cached true 61-bit sampled system."],
  Print["Building true 61-bit sampled system with scalar-safe arithmetic."];
  {system61BuildWallSeconds, system61} = AbsoluteTiming[
    CodexA4BuildSafeSampleSystem[
      record, 1/11, prime61, preparation]];
  If[! codexA4SystemQ[system61, prime61],
    Print["FAILED true 61-bit system build."]; Exit[8]];
  system61 = Join[system61, <|
    "A4Builder" -> "UnpackedCurrentO2ActualFiniteFieldSample",
    "A4BuildWallSeconds" -> system61BuildWallSeconds,
    "RecordFingerprint" -> Hash[record, "SHA256", "HexString"]
  |>];
  codexA4PutAtomic[system61, system61File];
  Print["Saved true 61-bit system; build wall ",
    system61BuildWallSeconds, " s."]
];

ClearAll[codexA4BenchmarkCase];
codexA4BenchmarkCase[system_Association, label_String] := Module[
  {prime, coreBuildSeconds, coreData, core, rightHandSides,
   sparseSolveSeconds, sparseSolution, denseConversionSeconds,
   denseCore, denseRightHandSides, denseSolveSeconds, denseSolution,
   inputFile, exportRecord, flint1, flint4, flint1Solution,
   flint4Solution, solutionReference, sparseDenseSameQ,
   flint1SameQ, flint4SameQ, result},
  prime = system["Prime"];
  Print["A4 ", label, " p=", prime, ": constructing core."];
  {coreBuildSeconds, coreData} = AbsoluteTiming[
    codexA4BuildCore[system, plan]];
  If[! AssociationQ[coreData], Return[$Failed]];
  core = coreData["Core"];
  rightHandSides = coreData["RightHandSides"];

  Print["  Wolfram sparse solve."];
  {sparseSolveSeconds, sparseSolution} = AbsoluteTiming[
    Quiet[Check[LinearSolve[core, rightHandSides,
      Modulus -> prime], $Failed]]];

  Print["  dense packed conversion and solve."];
  {denseConversionSeconds, {denseCore, denseRightHandSides}} =
    AbsoluteTiming[{
      Developer`ToPackedArray[Normal[core]],
      Developer`ToPackedArray[rightHandSides]}];
  {denseSolveSeconds, denseSolution} = AbsoluteTiming[
    Quiet[Check[LinearSolve[denseCore, denseRightHandSides,
      Modulus -> prime], $Failed]]];

  inputFile = FileNameJoin[{bundle,
    "a4_core_" <> label <> ".bin"}];
  exportRecord = codexA4ExportBinary[
    denseCore, denseRightHandSides, prime, inputFile];
  Print["  FLINT one thread."];
  flint1 = codexA4RunFlint[inputFile,
    FileNameJoin[{bundle, "a4_solution_" <> label <> "_t1.bin"}], 1];
  Print["  FLINT four threads."];
  flint4 = codexA4RunFlint[inputFile,
    FileNameJoin[{bundle, "a4_solution_" <> label <> "_t4.bin"}], 4];

  flint1Solution = If[AssociationQ[flint1["Imported"]],
    flint1["Imported", "Solution"], $Failed];
  flint4Solution = If[AssociationQ[flint4["Imported"]],
    flint4["Imported", "Solution"], $Failed];
  solutionReference = Which[
    MatrixQ[denseSolution, IntegerQ], denseSolution,
    MatrixQ[sparseSolution, IntegerQ], sparseSolution,
    True, $Failed];
  sparseDenseSameQ = MatrixQ[sparseSolution, IntegerQ] &&
    MatrixQ[denseSolution, IntegerQ] &&
    SameQ[sparseSolution, denseSolution];
  flint1SameQ = MatrixQ[solutionReference, IntegerQ] &&
    MatrixQ[flint1Solution, IntegerQ] &&
    SameQ[solutionReference, flint1Solution];
  flint4SameQ = MatrixQ[solutionReference, IntegerQ] &&
    MatrixQ[flint4Solution, IntegerQ] &&
    SameQ[solutionReference, flint4Solution];
  result = <|
    "Label" -> label,
    "Prime" -> prime,
    "PrimeBitLength" -> IntegerLength[prime, 2],
    "ActualSampledSystem" -> True,
    "CoreDimensions" -> coreData["Dimensions"],
    "RightHandSideDimensions" -> coreData["RightHandSideDimensions"],
    "CoreNonzeroEntries" -> coreData["NonzeroEntries"],
    "CoreBuildWallSeconds" -> coreBuildSeconds,
    "WolframSparseSolveWallSeconds" -> sparseSolveSeconds,
    "WolframSparseTotalWithCoreBuildSeconds" ->
      coreBuildSeconds + sparseSolveSeconds,
    "DensePackedQ" -> Developer`PackedArrayQ[denseCore],
    "DensePackedConversionWallSeconds" -> denseConversionSeconds,
    "WolframDenseSolveWallSeconds" -> denseSolveSeconds,
    "WolframDenseTotalWithConversionSeconds" ->
      denseConversionSeconds + denseSolveSeconds,
    "SparseDenseSolutionSameQ" -> sparseDenseSameQ,
    "BinaryExport" -> exportRecord,
    "FLINT1" -> KeyDrop[flint1, "Imported"],
    "FLINT4" -> KeyDrop[flint4, "Imported"],
    "FLINT1SolutionSameQ" -> flint1SameQ,
    "FLINT4SolutionSameQ" -> flint4SameQ,
    "FLINT1TotalWithConversionTransferSeconds" ->
      denseConversionSeconds + exportRecord["WallSeconds"] +
        Lookup[flint1["Timing"], "total_seconds", Infinity] +
        flint1["SolutionImportWallSeconds"],
    "FLINT4TotalWithConversionTransferSeconds" ->
      denseConversionSeconds + exportRecord["WallSeconds"] +
        Lookup[flint4["Timing"], "total_seconds", Infinity] +
        flint4["SolutionImportWallSeconds"]
  |>;
  Print[InputForm[result]];
  result
];

runStart = AbsoluteTime[];
benchmark31 = codexA4BenchmarkCase[system31, "p31"];
If[! AssociationQ[benchmark31],
  Print["FAILED 31-bit benchmark."]; Exit[7]];
benchmark61 = codexA4BenchmarkCase[system61, "p61"];
If[! AssociationQ[benchmark61],
  Print["FAILED 61-bit benchmark."]; Exit[8]];

result = <|
  "Status" -> "Complete",
  "Scope" -> "ExternalA4NoPackageEdits",
  "Fixture" -> fixtureFile,
  "ExternalBackend" -> "FLINT-nmod_mat_solve",
  "FLINTVersion" -> "3.0.1",
  "ThreadCounts" -> {1, 4},
  "ConversionAndTransferCounted" -> True,
  "Cases" -> {benchmark31, benchmark61},
  "TotalWallSeconds" -> N[AbsoluteTime[] - runStart]
|>;
codexA4PutAtomic[result, resultFile];
Print["A4 result saved: ", resultFile];
