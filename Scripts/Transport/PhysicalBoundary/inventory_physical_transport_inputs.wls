#!/usr/bin/env wolframscript

(* Read-only census of accepted observable transports versus physical
   boundary-mode bindings.  This distinguishes a completed path operator
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
      "WordRepresentation" -> Lookup[transport, "WordRepresentation", None],
      "BoundaryKernelDimensions" -> dimensions,
      "BoundaryNullity" -> If[MatchQ[dimensions, {_Integer, _Integer}],
        Last[dimensions], Missing[]],
      "BoundaryCoordinateCount" ->
        Lookup[transport, "BoundaryCoordinates", Missing[]],
      "PhysicalDemandCount" ->
        Length[Lookup[transport, "PhysicalDemandPairs", {}]],
      "PhysicalModeMapPresent" -> FileExistsQ[modeFile],
      "TransportFile" -> file, "ModeFile" -> modeFile|>
  ]], files];

summary = <|
  "Status" -> "PhysicalTransportInputInventory",
  "AcceptedObservableTransportCount" -> Count[records,
    record_ /; MemberQ[{"ExactObservableTransport",
      "ModularlyVerifiedObservableTransport"}, record["Status"]]],
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
