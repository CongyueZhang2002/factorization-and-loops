#!/usr/bin/env wolframscript

(* Read-only census of validated requested-output coefficient operators versus
   physical boundary-mode bindings.  This distinguishes a coefficient operator
   from a completed physical solution and is intentionally family neutral. *)

$AllowInternet = False;
$HistoryLength = 0;
repositoryRoot = DirectoryName[ExpandFileName[$InputFileName], 4];
arguments = Rest[$ScriptCommandLine];
resultRoot = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical"}];
transportDirectory = FileNameJoin[{resultRoot,
  "ObservableTransport_2026-09-01_codex", "families"}];
modeDirectory = FileNameJoin[{resultRoot, "PhysicalBoundaryModes"}];

files = SortBy[FileNames["observable_transport_CF*.wl",
    transportDirectory], ToExpression@First@StringCases[FileBaseName[#],
      "CF" ~~ digits : DigitCharacter .. :> digits] &];
records = Map[Function[file, Module[
    {transport, family, kernel, dimensions, modeFile},
    transport = Quiet[Check[Get[file], $Failed]];
    If[! AssociationQ[transport], Return[<|"File" -> file,
      "Status" -> "Unreadable"|>]];
    family = Lookup[transport, "Family", FileBaseName[file]];
    kernel = Lookup[transport, "BoundaryKernelAtBase", Missing[]];
    dimensions = If[MatrixQ[kernel], Dimensions[kernel], Missing[]];
    modeFile = FileNameJoin[{modeDirectory,
      "boundary_mode_" <> family <> ".wl"}];
    <|"Family" -> family, "Status" -> Lookup[transport, "Status", None],
      "IteratedIntegralCoefficientRepresentation" ->
        Lookup[transport, "IteratedIntegralCoefficientRepresentation", None],
      "BoundaryKernelDimensions" -> dimensions,
      "BoundaryNullity" -> If[MatchQ[dimensions, {_Integer, _Integer}],
        Last[dimensions], Missing[]],
      "BoundaryCoordinateCount" ->
        Lookup[transport, "BoundaryCoordinates", Missing[]],
      "RequestedMasterIntegralEpsilonCoefficientCount" -> Length[Lookup[
        transport, "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}]],
      "PhysicalModeMapPresent" -> FileExistsQ[modeFile],
      "IteratedIntegralCoefficientOperatorFile" -> file,
      "ModeFile" -> modeFile|>
  ]], files];

summary = <|
  "Status" -> "PhysicalMasterIntegralSolutionInputInventory",
  "ValidatedIteratedIntegralCoefficientOperatorCount" -> Count[records,
    record_ /; record["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated"],
  "PhysicalModeMapCount" -> Count[records,
    record_ /; TrueQ[record["PhysicalModeMapPresent"]]],
  "MissingPhysicalModeMapCount" -> Count[records,
    record_ /; ! TrueQ[record["PhysicalModeMapPresent"]]],
  "BoundaryNullityCounts" -> Counts[Lookup[records, "BoundaryNullity"]],
  "MissingModeFamiliesByNullity" -> GroupBy[
    Select[records, ! TrueQ[#PhysicalModeMapPresent] &],
    #BoundaryNullity &, #Family &],
  "Records" -> records|>;
Print[InputForm[KeyDrop[summary, "Records"]]];
If[arguments =!= {}, Put[summary, ExpandFileName[First[arguments]]]];
