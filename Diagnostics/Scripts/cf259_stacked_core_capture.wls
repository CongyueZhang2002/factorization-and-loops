#!/usr/bin/env wolframscript

(* Discover the CF259 fixed core on two independent kinematic point sets.
   The first seed contributes its already-proven 3,476-row basis; the second
   seed kills pointwise gauge freedoms while preserving true residue relations. *)

$HistoryLength = 0;
args = Rest[$ScriptCommandLine];
supportShell = If[Length[args] >= 1, ToExpression[args[[1]]], 0];
configuredPointCount = If[Length[args] >= 2,
  ToExpression[args[[2]]], Automatic];
seedCount = If[Length[args] >= 3, ToExpression[args[[3]]], 2];
captureMode = Length[args] >= 4 && args[[4]] === "capture";
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
inputFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-28_codex_clean", "CF259",
  "sector_CF259_standard", "CF259_27_1_input.wl"}];
record = Get[inputFile];
census = Get[FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_rank3_modular_pole_census",
  "cf259_modular_pole_census.wl"}]];
supportData = Get[FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_rank3_modular_pole_census",
  "cf259_denominator_support.wl"}]];
singleCore = Get[FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_downward_taylor_core", "core_report.wl"}]];
variables = record["Variables"];
epsilon = record["Regulator"];
strip = record["Strip"];
rawPreparation = record["DeferredPreparation"]["Preparation"];
roots = (<|"Root" -> Sqrt[#1], "RootSquare" -> #1|> &) /@
  record["DeferredPreparation"]["RootSquares"];
frame = <|"Name" -> "CF259RawRank3DownwardCore",
  "Kind" -> "TwoVariable", "CoefficientField" -> "Algebraic",
  "Variables" -> variables, "Subst" -> Thread[variables -> variables],
  "Roots" -> roots|>;
allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
classification = FeynFacet`Private`multiquadraticStripRootCensusWithBundle[
  strip, allRoots, variables, epsilon, Missing["NoDeferredBundle"]];
stableFrame = FeynFacet`Private`blockEquationDeferredRootFrame[
  KeyTake[#1, {"Root", "RootSquare"}] & /@ allRoots, variables, epsilon];
classification = Join[classification, <|
  "BundleRootIndices" -> Range[Length[allRoots]],
  "RequiredRootIndices" -> Lookup[stableFrame["Roots"],
    "SourceIndex", {}]|>];
stableOrder = FeynFacet`Private`multiquadraticStripRootOrder[
  frame, variables, Sort[classification["RequiredRootIndices"]], epsilon];
If[Lookup[stableOrder, "Status", None] =!= "StableRootOrder", Exit[1]];
directOptions = FeynFacet`Private`familyRowGaugeDirectAlphabetOptions[
  record["DeferredPreparation"]];
candidate = FeynFacet`Private`multiquadraticStripCandidateLetters[
  strip, stableOrder["Roots"], variables, epsilon, record,
  "AdditionalLetters" -> directOptions["AdditionalLetters"],
  "AlgebraicLetters" -> directOptions["AlgebraicLetters"],
  "DLogKernels" -> 1, "Deadline" -> Infinity];
If[Lookup[candidate, "Status", None] =!=
    "MultiquadraticCandidateLettersV1", Exit[1]];
selectedSupport = If[supportShell <= 3, supportData["Shells"][supportShell],
  Tuples[Range[0, #] & /@ supportData["Degrees"]]];
prepared = FeynFacet`Private`multiquadraticStripPrepare[record, frame,
  "RootClassification" -> classification,
  "CoefficientProvider" -> "SplitBranch", "CompileCore" -> False,
  "LetterRecords" -> candidate["LetterRecords"],
  "GaugeDenominatorFactor" -> 1,
  "GaugeDenominator" -> census["GaugeDenominator"],
  "Support" -> selectedSupport,
  "Deadline" -> Infinity];
If[Lookup[prepared, "Status", None] =!= "PreparedMultiquadraticStripV1",
  Exit[1]];
layout = FeynFacet`Private`multiquadraticStripAssemblyLayout[prepared];
providerRecord = KeyDrop[prepared["Record"],
  {"DeferredBundle", "DeferredPreparation", "DeferredPreparationFile"}];
provider = FeynFacet`Private`multiquadraticStripDirectProvider[
  providerRecord, prepared["Roots"], "Kind" -> "SplitBranch",
  "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
  "SourceFingerprint" -> rawPreparation["SourceFingerprint"]];
provider = FeynFacet`Private`multiquadraticStripAttachDeferredPreparation[
  provider, rawPreparation, inputFile];

prime = 2305843009213693951;
threads = 8;
seeds = Take[{2026083101, 2026083199, 2026083271}, seedCount];
firstRows = If[supportShell === 0, singleCore["IndependentEquationRows"],
  Automatic];
firstRowCount = Length[firstRows];
assemble[value_, seed_] := Block[
  {FeynFacet`Private`$multiquadraticStripTrustedProviderEvaluation = True,
   FeynFacet`Private`$multiquadraticStripTrustedLayoutEvaluation = True,
   $ProcessorCount = threads},
  FeynFacet`Private`multiquadraticStripAssembleSample[
    layout, provider, value, prime, "PointCount" -> configuredPointCount,
    "MaximumAttempts" -> Automatic, "RandomSeed" -> seed,
    "SplitPointsOnly" -> False]];
stackSamples[value_] := Module[{timed, samples, selectedMatrices,
    selectedRights},
  timed = Table[AbsoluteTiming[assemble[value, seed]], {seed, seeds}];
  samples = timed[[All, 2]];
  If[AnyTrue[samples, Lookup[#, "Status", None] =!=
      "AssembledMultiquadraticSampleV1" &], Return[$Failed]];
  selectedMatrices = Prepend[Rest[Lookup[samples, "Matrix"]],
    If[ListQ[firstRows], samples[[1, "Matrix"]][[firstRows]],
      samples[[1, "Matrix"]]]];
  selectedRights = Prepend[Rest[Lookup[samples, "RightHandSide"]],
    If[ListQ[firstRows], samples[[1, "RightHandSide"]][[firstRows]],
      samples[[1, "RightHandSide"]]]];
  <|"Matrix" -> Join @@ selectedMatrices,
    "RightHandSide" -> Join @@ selectedRights,
    "Seconds" -> N[timed[[All, 1]]],
    "FirstSelectedRowCount" -> Length[First[selectedRights]],
    "AdditionalFullRowCount" -> If[Length[selectedRights] > 1,
      Length[selectedRights[[2]]], 0]|>];

Print["discover stacked core at epsilon=1/7"];
anchor = stackSamples[1/7];
If[anchor === $Failed, Exit[2]];
firstRowCount = anchor["FirstSelectedRowCount"];
{solveSeconds, solution} = AbsoluteTiming[
  FeynFacet`Private`multiquadraticStripPlanDiscoverySolve[
    anchor["Matrix"], anchor["RightHandSide"], prime,
    prepared["GaugeUnknownCount"], prepared["ResidueUnknownCount"],
    "FLINTAffineRREF", threads, 0]];
If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution",
  probe = <|"Status" -> "CF259StackedSupportProbeV1",
    "SupportShell" -> supportShell,
    "PointCount" -> configuredPointCount,
    "SupportCount" -> Length[selectedSupport],
    "Consistent" -> False, "Detail" -> KeyDrop[solution,
      {"ParticularSolution", "NullspaceBasis"}],
    "AssemblySeconds" -> anchor["Seconds"],
    "SolveSeconds" -> N[solveSeconds]|>;
  probeDirectory = FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_stacked_support_probes"}];
  If[! DirectoryQ[probeDirectory], CreateDirectory[probeDirectory,
    CreateIntermediateDirectories -> True]];
  Put[probe, FileNameJoin[{probeDirectory,
    "shell_" <> ToString[supportShell] <> ".wl"}]];
  Print[InputForm[probe]]; Exit[3]];
rank = solution["Rank"];
nullity = solution["Nullity"];
If[supportShell =!= 0 && ! captureMode,
  probe = <|"Status" -> "CF259StackedSupportProbeV1",
    "SupportShell" -> supportShell,
    "PointCount" -> configuredPointCount,
    "SupportCount" -> Length[selectedSupport],
    "Consistent" -> True, "Rank" -> rank, "Nullity" -> nullity,
    "MatrixDimensions" -> Dimensions[anchor["Matrix"]],
    "AssemblySeconds" -> anchor["Seconds"],
    "SolveSeconds" -> N[solveSeconds]|>;
  probeDirectory = FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_stacked_support_probes"}];
  If[! DirectoryQ[probeDirectory], CreateDirectory[probeDirectory,
    CreateIntermediateDirectories -> True]];
  Put[probe, FileNameJoin[{probeDirectory,
    "shell_" <> ToString[supportShell] <> ".wl"}]];
  Print[InputForm[probe]]; Exit[0]];
expectedStructure = Which[
  supportShell === 0, {3486, 38},
  supportShell === 3, {4588, 40},
  True, {rank, nullity}];
If[{rank, nullity} =!= expectedStructure,
  Print[InputForm[<|"Status" -> "UnexpectedStackedRank",
    "Rank" -> rank, "Nullity" -> nullity|>]]; Exit[3]];
rows = solution["IndependentEquationRows"];
normalizationColumns = solution["NativeNormalizationColumns"];
gaugeNormalizationCount = Length[Select[normalizationColumns,
  # <= prepared["GaugeUnknownCount"] &]];
residueNormalizationCount = Length[normalizationColumns] -
  gaugeNormalizationCount;
If[residueNormalizationCount =!= 38 ||
    gaugeNormalizationCount =!= nullity - 38,
  Print["unexpected stacked gauge/residue normalization split"]; Exit[3]];
columns = Complement[Range[prepared["UnknownCount"]], normalizationColumns];
cores = <|1/7 -> Developer`ToPackedArray[
    anchor["Matrix"][[rows, columns]]]|>;
rights = <|1/7 -> Developer`ToPackedArray[
    anchor["RightHandSide"][[rows]]]|>;
timings = <|1/7 -> anchor["Seconds"]|>;
additionalFullRowCount = anchor["AdditionalFullRowCount"];
Clear[anchor];
Do[
  Print["stacked core sample epsilon=", value];
  stacked = stackSamples[value];
  If[stacked === $Failed, Exit[4]];
  cores[value] = Developer`ToPackedArray[
    stacked["Matrix"][[rows, columns]]];
  rights[value] = Developer`ToPackedArray[
    stacked["RightHandSide"][[rows]]];
  timings[value] = stacked["Seconds"];
  Clear[stacked];,
  {value, {8/7, 15/7}}];
base = cores[1/7];
slope = Developer`ToPackedArray[Mod[cores[8/7] - base, prime]];
linearCheck = TrueQ[Mod[base + 2 slope, prime] === cores[15/7]];
If[! linearCheck, Print["stacked core pencil is not affine"]; Exit[5]];

outputDirectory = FileNameJoin[{codexRoot, "Runtime",
  If[supportShell === 0, "2026-08-31_cf259_stacked_taylor_core",
    "2026-08-31_cf259_shell" <> ToString[supportShell] <>
      "_stacked_taylor_core"]}];
If[! DirectoryQ[outputDirectory], CreateDirectory[outputDirectory,
  CreateIntermediateDirectories -> True]];
writeMatrix[file_String, magic_String, matrix_] := Module[{stream},
  stream = OpenWrite[file <> ".tmp", BinaryFormat -> True];
  BinaryWrite[stream, ToCharacterCode[magic], "UnsignedInteger8"];
  BinaryWrite[stream, {rank, rank, prime}, "UnsignedInteger64",
    ByteOrdering -> -1];
  BinaryWrite[stream, Flatten[matrix], "UnsignedInteger64",
    ByteOrdering -> -1];
  Close[stream]; RenameFile[file <> ".tmp", file,
    OverwriteTarget -> True]];
baseFile = FileNameJoin[{outputDirectory, "core_base_eps1_7.bin"}];
slopeFile = FileNameJoin[{outputDirectory, "core_epsilon_slope.bin"}];
writeMatrix[baseFile, "CFK0B1\000", base];
writeMatrix[slopeFile, "CFK0S1\000", slope];
sourceCounts = <|"FirstSeedBasisRows" -> Count[rows, _?(# <= firstRowCount &)],
  "SecondSeedRows" -> Count[rows, _?(# > firstRowCount &)]|>;
report = <|"Status" -> "CF259StackedTaylorCoreV1", "Prime" -> prime,
  "ExpansionPoint" -> 1/7, "CoreDimension" -> rank,
  "SupportShell" -> supportShell, "SupportCount" -> Length[selectedSupport],
  "PointCount" -> configuredPointCount,
  "GaugeUnknownCount" -> prepared["GaugeUnknownCount"],
  "ResidueUnknownCount" -> prepared["ResidueUnknownCount"],
  "Seeds" -> seeds, "FirstSeedBasisRows" -> firstRows,
  "FirstSeedBasisRowCount" -> firstRowCount,
  "AdditionalSeedFullRowCount" -> additionalFullRowCount,
  "IndependentStackedRows" -> rows, "RowSourceCounts" -> sourceCounts,
  "CoreColumns" -> columns, "NormalizationColumns" -> normalizationColumns,
  "GaugeNormalizationCount" -> gaugeNormalizationCount,
  "ResidueNormalizationCount" -> residueNormalizationCount,
  "Rank" -> rank, "Nullity" -> nullity,
  "AnchorSolveSeconds" -> N[solveSeconds], "AssemblySeconds" -> timings,
  "MatrixDegree" -> 1, "AffineLawValidated" -> linearCheck,
  "RightHandSides" -> rights, "BaseFile" -> baseFile,
  "SlopeFile" -> slopeFile|>;
outputFile = FileNameJoin[{outputDirectory, "core_report.wl"}];
Put[report, outputFile];
Print[InputForm[KeyDrop[report, {"FirstSeedBasisRows",
  "IndependentStackedRows", "CoreColumns", "NormalizationColumns",
  "RightHandSides"}]]];
Print["OUTPUT=", outputFile];
Exit[0];
