#!/usr/bin/env wolframscript

(* The only block acceptance performed here: assemble one fresh random modular
   image and check every original equation A.x=b exactly with FLINT. *)

$HistoryLength = 0;
args = Rest[$ScriptCommandLine];
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
mode = If[Length[args] >= 1 && (MemberQ[{"downward", "shell3"}, args[[1]]] ||
      StringMatchQ[args[[1]], "lift" ~~ NumberString]),
  args[[1]], "downward"];
liftQ = StringStartsQ[mode, "lift"];
argumentOffset = If[mode === "downward" &&
    ! (Length[args] >= 1 && args[[1]] === "downward"), 0, 1];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
runtime = Which[
  mode === "downward", FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_downward_taylor_core"}],
  mode === "shell3", FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_shell3_stacked_taylor_core"}],
  liftQ, FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_shell3_multprime"}]];
modular = Get[FileNameJoin[{runtime, Switch[mode,
  "downward", "cf259_active_fixed_core_modular_vector_prime1.wl",
  "shell3", "cf259_shell3_fixed_core_modular_vector_prime1.wl",
  _, "rational_lift_" <> StringDrop[mode, 4] <> "_plus_1.wl"]}]];
core = Get[FileNameJoin[{If[mode === "downward", runtime,
    FileNameJoin[{codexRoot, "Runtime",
      "2026-08-31_cf259_shell3_stacked_taylor_core"}]],
  "core_report.wl"}]];
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
frame = <|"Name" -> "CF259RawRank3Acceptance",
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
  "Support" -> supportData["Shells"][If[mode === "downward", 0, 3]],
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

prime = If[liftQ, modular["ValidationPrime"], modular["Prime"]];
epsilonValue = If[Length[args] >= argumentOffset + 1,
  ToExpression[args[[argumentOffset + 1]]], 41/43];
validationSeed = If[Length[args] >= argumentOffset + 2,
  ToExpression[args[[argumentOffset + 2]]], 2026083359];
{sampleSeconds, sample} = AbsoluteTiming[Block[
  {FeynFacet`Private`$multiquadraticStripTrustedProviderEvaluation = True,
   FeynFacet`Private`$multiquadraticStripTrustedLayoutEvaluation = True,
   $ProcessorCount = 4},
  FeynFacet`Private`multiquadraticStripAssembleSample[
    layout, provider, epsilonValue, prime, "PointCount" ->
      If[mode === "downward", Automatic, core["PointCount"]],
    "MaximumAttempts" -> Automatic, "RandomSeed" -> validationSeed,
    "SplitPointsOnly" -> False]]];
If[Lookup[sample, "Status", None] =!=
    "AssembledMultiquadraticSampleV1", Exit[2]];
modValue[value_] := Mod[Numerator[value]
  PowerMod[Denominator[value], -1, prime], prime];
evaluate[coefficients_List, point_Integer] := Fold[
  Mod[#1 point + #2, prime] &, 0, Reverse[coefficients]];
t = Mod[modValue[epsilonValue] -
  modValue[modular["ExpansionPoint"]], prime];
interpolations = If[liftQ, modular["LiftedInterpolations"],
  modular["Interpolations"]];
vector = Developer`ToPackedArray[Table[
  item = interpolations[[coordinate]];
  numeratorCoefficients = If[liftQ,
    modValue /@ item["NumeratorCoefficients"], item["Numerator"]];
  denominatorCoefficients = If[liftQ,
    modValue /@ item["DenominatorCoefficients"], item["Denominator"]];
  denominator = evaluate[denominatorCoefficients, t];
  If[denominator === 0, Print["validation point is a pole"]; Exit[3]];
  Mod[evaluate[numeratorCoefficients, t]
    PowerMod[denominator, -1, prime], prime],
  {coordinate, modular["UnknownCount"]}]];

binaryFile = FileNameJoin[{runtime, "fresh_modular_residual_input.bin"}];
stream = OpenWrite[binaryFile <> ".tmp", BinaryFormat -> True];
BinaryWrite[stream, ToCharacterCode["CFK0V1\000"], "UnsignedInteger8"];
BinaryWrite[stream, Join[sample["MatrixDimensions"], {prime}],
  "UnsignedInteger64", ByteOrdering -> -1];
BinaryWrite[stream, Flatten[sample["Matrix"]], "UnsignedInteger64",
  ByteOrdering -> -1];
BinaryWrite[stream, sample["RightHandSide"], "UnsignedInteger64",
  ByteOrdering -> -1];
BinaryWrite[stream, vector, "UnsignedInteger64", ByteOrdering -> -1];
Close[stream]; RenameFile[binaryFile <> ".tmp", binaryFile,
  OverwriteTarget -> True];
Clear[sample, vector];
binary = FileNameJoin[{codexRoot, "Diagnostics", "Scripts",
  "cf259_modular_residual"}];
process = RunProcess[{binary, binaryFile, "8"}];
telemetry = Quiet[Check[ImportString[process["StandardOutput"], "RawJSON"],
  process["StandardOutput"]]];
report = <|"Status" -> If[process["ExitCode"] === 0,
    "CF259FreshModularAcceptanceV1", "CF259FreshModularRejectionV1"],
  "Accepted" -> (process["ExitCode"] === 0), "Prime" -> prime,
  "RegulatorValue" -> epsilonValue, "RandomSeed" -> validationSeed,
  "SampleSeconds" -> N[sampleSeconds], "ResidualTelemetry" -> telemetry|>;
output = FileNameJoin[{runtime, "fresh_modular_acceptance_seed" <>
  ToString[validationSeed] <> ".wl"}];
Put[report, output]; Print[InputForm[report]]; Print["OUTPUT=", output];
Exit[If[TrueQ[report["Accepted"]], 0, 4]];
