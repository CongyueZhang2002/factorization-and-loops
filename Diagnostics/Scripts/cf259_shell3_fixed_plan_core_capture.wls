#!/usr/bin/env wolframscript

(* Re-evaluate the accepted CF259 shell-3 row/column section at another
   prime.  The structural plan was discovered once at prime 1; no repeated
   RREF or support search is performed here. *)

$HistoryLength = 0;
args = Rest[$ScriptCommandLine];
If[Length[args] < 2,
  Print["usage: cf259_shell3_fixed_plan_core_capture.wls TAG PRIME [THREADS]"];
  Exit[64]];
tag = args[[1]];
prime = ToExpression[args[[2]]];
threads = If[Length[args] >= 3, ToExpression[args[[3]]], 4];
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
planRuntime = FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_stacked_taylor_core"}];
plan = Get[FileNameJoin[{planRuntime, "core_report.wl"}]];
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
prepared = FeynFacet`Private`multiquadraticStripPrepare[record, frame,
  "RootClassification" -> classification,
  "CoefficientProvider" -> "SplitBranch", "CompileCore" -> False,
  "LetterRecords" -> candidate["LetterRecords"],
  "GaugeDenominatorFactor" -> 1,
  "GaugeDenominator" -> census["GaugeDenominator"],
  "Support" -> supportData["Shells"][3], "Deadline" -> Infinity];
If[Lookup[prepared, "Status", None] =!= "PreparedMultiquadraticStripV1",
  Exit[1]];
If[prepared["GaugeUnknownCount"] =!= plan["GaugeUnknownCount"] ||
    prepared["ResidueUnknownCount"] =!= plan["ResidueUnknownCount"],
  Print["fixed-plan layout width changed"]; Exit[2]];
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

seed = First[plan["Seeds"]];
rows = plan["IndependentStackedRows"];
columns = plan["CoreColumns"];
If[Max[rows] > plan["AdditionalSeedFullRowCount"],
  Print["fixed plan unexpectedly depends on another seed"]; Exit[3]];
assemble[value_] := Block[
  {FeynFacet`Private`$multiquadraticStripTrustedProviderEvaluation = True,
   FeynFacet`Private`$multiquadraticStripTrustedLayoutEvaluation = True,
   $ProcessorCount = threads},
  FeynFacet`Private`multiquadraticStripAssembleSample[
    layout, provider, value, prime, "PointCount" -> plan["PointCount"],
    "MaximumAttempts" -> Automatic, "RandomSeed" -> seed,
    "SplitPointsOnly" -> False]];
timed = Association@Table[value -> AbsoluteTiming[assemble[value]],
  {value, {1/7, 8/7}}];
If[AnyTrue[Values[timed], Lookup[#[[2]], "Status", None] =!=
    "AssembledMultiquadraticSampleV1" &], Exit[4]];
base = Developer`ToPackedArray[
  timed[1/7][[2, "Matrix"]][[rows, columns]]];
slope = Developer`ToPackedArray[Mod[
  timed[8/7][[2, "Matrix"]][[rows, columns]] - base, prime]];
rights = Association@Table[value -> Developer`ToPackedArray[
    timed[value][[2, "RightHandSide"]][[rows]]],
  {value, {1/7, 8/7}}];
outputDirectory = FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_multprime", tag}];
If[! DirectoryQ[outputDirectory], CreateDirectory[outputDirectory,
  CreateIntermediateDirectories -> True]];
writeMatrix[file_String, magic_String, matrix_] := Module[{stream},
  stream = OpenWrite[file <> ".tmp", BinaryFormat -> True];
  BinaryWrite[stream, ToCharacterCode[magic], "UnsignedInteger8"];
  BinaryWrite[stream, {plan["CoreDimension"], plan["CoreDimension"], prime},
    "UnsignedInteger64", ByteOrdering -> -1];
  BinaryWrite[stream, Flatten[matrix], "UnsignedInteger64",
    ByteOrdering -> -1];
  Close[stream]; RenameFile[file <> ".tmp", file,
    OverwriteTarget -> True]];
baseFile = FileNameJoin[{outputDirectory, "core_base_eps1_7.bin"}];
slopeFile = FileNameJoin[{outputDirectory, "core_epsilon_slope.bin"}];
writeMatrix[baseFile, "CFK0B1\000", base];
writeMatrix[slopeFile, "CFK0S1\000", slope];
report = Join[KeyTake[plan, {"ExpansionPoint", "CoreDimension",
    "SupportShell", "SupportCount", "PointCount", "GaugeUnknownCount",
    "ResidueUnknownCount", "Seeds", "AdditionalSeedFullRowCount",
    "IndependentStackedRows",
    "CoreColumns", "NormalizationColumns", "GaugeNormalizationCount",
    "ResidueNormalizationCount", "Rank", "Nullity"}],
  <|"Status" -> "CF259Shell3FixedPlanCoreV1", "Prime" -> prime,
    "PrimeTag" -> tag, "RightHandSides" -> rights,
    "AssemblySeconds" -> AssociationMap[N[timed[#][[1]]] &,
      {1/7, 8/7}], "BaseFile" -> baseFile, "SlopeFile" -> slopeFile|>];
outputFile = FileNameJoin[{outputDirectory, "core_report.wl"}];
Put[report, outputFile];
Print[InputForm[KeyDrop[report, {"IndependentStackedRows", "CoreColumns",
  "NormalizationColumns", "RightHandSides"}]]];
Print["OUTPUT=", outputFile];
Exit[0];
