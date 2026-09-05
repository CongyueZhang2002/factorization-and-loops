#!/usr/bin/env wolframscript

$HistoryLength = 0;

repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 5,
  Print[
    "Usage: write_requested_output_iterated_integral_coefficient_input_summary.wls " <>
    "<differential-system-directory> <valuations.wl> <input-table.tsv> " <>
    "<summary.wl> <epsilon-form-directory> ... [--card=<card.wl>]"
  ];
  Exit[64]
];

cardArguments = Select[arguments, StringStartsQ[#, "--card="] &];
If[Length[cardArguments] > 1, Exit[64]];
card = If[cardArguments === {}, None,
  StringDrop[First[cardArguments], StringLength["--card="]]];
arguments = Select[arguments, ! StringStartsQ[#, "--card="] &];
If[Length[arguments] < 5, Exit[64]];

{differentialDirectory, valuationsFile, inputTableFile, summaryFile} =
  Take[arguments, 4];
epsilonDirectories = Drop[arguments, 4];

(* This CLI states its campaign-specific file patterns and numeric family
   ordering explicitly; the package discovery functions assume neither. *)
familyPrefix = FeynFacet`Private`$canonicalFamilyPrefix;
familySortKey = Function[name,
  ToExpression[StringDrop[name, StringLength[familyPrefix]]]];

found = FindRequestedOutputIteratedIntegralCoefficientInputFiles[
  epsilonDirectories, differentialDirectory,
  "DifferentialFilePattern" -> "nnlo_de_" <> familyPrefix <> "*.wl",
  "EpsFormFilePattern" -> "family_epsform_" <> familyPrefix <> "*.wl"];

If[Lookup[found, "Status", None] === "NoDifferentialFamiliesFound",
  Print["No differential-equation family matched ",
    Lookup[found, "DifferentialFilePattern", ""], " in ",
    Lookup[found, "DifferentialSystemDirectory", differentialDirectory]];
  Exit[1]];

classified = ClassifyRequestedOutputIteratedIntegralCoefficientInputs[found];
selected = SelectValidatedFamilyDLogEpsilonFormInputs[
  classified, valuationsFile,
  "Card" -> card, "FamilySortKey" -> familySortKey];
result = WriteRequestedOutputIteratedIntegralCoefficientInputSummary[
  selected, inputTableFile, "SummaryFile" -> summaryFile];

Print["Validated family dlog epsilon forms: ",
  Lookup[result, "ValidatedFamilyCount", 0], "/",
  Lookup[result, "DifferentialFamilyCount", 0]];
If[Lookup[result, "FamiliesWithoutValidatedInputs", {}] =!= {},
  Print["Families without a validated dlog epsilon form: ",
    result["FamiliesWithoutValidatedInputs"]]];
If[Lookup[result, "SelectionCompleteness", None] =!= "Complete" ||
    Lookup[result, "Status", None] =!=
      "RequestedOutputIteratedIntegralCoefficientInputSummaryWritten",
  Exit[1]];
