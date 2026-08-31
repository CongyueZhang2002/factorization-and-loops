#!/usr/bin/env wolframscript

(* Capture the shell-3 fixed-core RHS on exactly the seed rows selected by the
   stacked core.  Seeds contributing no independent rows are not evaluated. *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
args = Rest[$ScriptCommandLine];
If[Length[args] < 2,
  Print["usage: cf259_shell3_stacked_rhs_capture.wls SHARD SHARDS [THREADS]"];
  Exit[64]];
shard = ToExpression[args[[1]]];
shards = ToExpression[args[[2]]];
threads = If[Length[args] >= 3, ToExpression[args[[3]]], 4];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
runtime = FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_stacked_taylor_core"}];
core = Get[FileNameJoin[{runtime, "core_report.wl"}]];
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
variables = record["Variables"]; epsilon = record["Regulator"];
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
directOptions = FeynFacet`Private`familyRowGaugeDirectAlphabetOptions[
  record["DeferredPreparation"]];
candidate = FeynFacet`Private`multiquadraticStripCandidateLetters[
  strip, stableOrder["Roots"], variables, epsilon, record,
  "AdditionalLetters" -> directOptions["AdditionalLetters"],
  "AlgebraicLetters" -> directOptions["AlgebraicLetters"],
  "DLogKernels" -> 1, "Deadline" -> Infinity];
prepared = FeynFacet`Private`multiquadraticStripPrepare[record, frame,
  "RootClassification" -> classification,
  "CoefficientProvider" -> "SplitBranch", "CompileCore" -> False,
  "LetterRecords" -> candidate["LetterRecords"],
  "GaugeDenominatorFactor" -> 1,
  "GaugeDenominator" -> census["GaugeDenominator"],
  "Support" -> supportData["Shells"][3], "Deadline" -> Infinity];
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

prime = core["Prime"];
seeds = core["Seeds"];
rowsPerSeed = core["AdditionalSeedFullRowCount"];
stackedRows = core["IndependentStackedRows"];
rowSeed[row_] := Quotient[row - 1, rowsPerSeed] + 1;
rowLocal[row_] := Mod[row - 1, rowsPerSeed] + 1;
usedSeeds = Sort[DeleteDuplicates[rowSeed /@ stackedRows]];
If[! SubsetQ[Range[Length[seeds]], usedSeeds], Exit[2]];
epsilonValues = Take[DeleteDuplicates[Join[
    FeynFacet`Private`$multiquadraticStripRegulatorScheduleDefault,
    Range[1, 72]]], 42];
indices = Select[Range[Length[epsilonValues]],
  Mod[#1 - 1, shards] === shard - 1 &];
outputDirectory = FileNameJoin[{runtime, "rhs_images"}];
If[! DirectoryQ[outputDirectory], CreateDirectory[outputDirectory,
  CreateIntermediateDirectories -> True]];
putAtomic[value_, file_String] := Module[{temporary = file <> ".tmp." <>
    ToString[$ProcessID]}, Put[value, temporary]; RenameFile[temporary, file,
    OverwriteTarget -> True]];
assemble[value_, seed_] := Block[
  {FeynFacet`Private`$multiquadraticStripTrustedProviderEvaluation = True,
   FeynFacet`Private`$multiquadraticStripTrustedLayoutEvaluation = True,
   $ProcessorCount = threads},
  FeynFacet`Private`multiquadraticStripAssembleSample[
    layout, provider, value, prime, "PointCount" -> core["PointCount"],
    "MaximumAttempts" -> Automatic, "RandomSeed" -> seed,
    "SplitPointsOnly" -> False]];

Print["CF259 shell3 stacked RHS shard ", shard, "/", shards,
  ": used seeds ", usedSeeds, ", images ", Length[indices]];
Do[
  value = epsilonValues[[index]];
  outputFile = FileNameJoin[{outputDirectory,
    "rhs_" <> IntegerString[index, 10, 3] <> ".wl"}];
  If[FileExistsQ[outputFile], Continue[]];
  {seconds, samples} = AbsoluteTiming[Association@Table[
    seedIndex -> assemble[value, seeds[[seedIndex]]],
    {seedIndex, usedSeeds}]];
  If[AnyTrue[Values[samples], Lookup[#, "Status", None] =!=
      "AssembledMultiquadraticSampleV1" &], Exit[3]];
  values = Developer`ToPackedArray[Table[
    samples[rowSeed[row]]["RightHandSide"][[rowLocal[row]]],
    {row, stackedRows}]];
  result = <|"Status" -> "CF259Shell3StackedRHSImageV1",
    "ImageIndex" -> index, "RegulatorValue" -> value,
    "EpsilonMod" -> FeynFacet`Private`multiquadraticStripModRational[
      value, prime], "Prime" -> prime, "Values" -> values,
    "UsedSeedIndices" -> usedSeeds, "SampleSeconds" -> N[seconds]|>;
  putAtomic[result, outputFile];
  Print["rhs ", index, " epsilon=", value, " saved in ", N[seconds], " s"];
  Clear[samples, values, result];,
  {index, indices}];
Exit[0];
