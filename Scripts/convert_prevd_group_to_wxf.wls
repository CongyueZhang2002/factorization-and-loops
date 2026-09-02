#!/usr/bin/env wolframscript

(* Pool-safe mission: parse one size-balanced PrevD text group and write WXF.
   Usage: convert_prevd_group_to_wxf.wls GROUP.wl GROUP.wxf *)
Module[
  {arguments = Rest[$ScriptCommandLine], inputFile, outputFile, group,
   dimensions, positions, values, payload, temporary, exported, renamed},
  If[Length[arguments] =!= 2,
    Print["Usage: convert_prevd_group_to_wxf.wls GROUP.wl GROUP.wxf"];
    Return[$Failed, Module]];
  {inputFile, outputFile} = ExpandFileName /@ arguments;
  If[! FileExistsQ[inputFile],
    Print["PrevD group does not exist: ", inputFile];
    Return[$Failed, Module]];
  group = Quiet[Check[Get[inputFile], $Failed]];
  If[! AssociationQ[group] ||
      Lookup[group, "Schema", None] =!= "PrevDCheckpointGroupTextV1",
    Print["Invalid PrevD text group: ", inputFile];
    Return[$Failed, Module]];
  {dimensions, positions, values} =
    Lookup[group, {"Dimensions", "Positions", "Values"}, $Failed];
  If[! MatchQ[dimensions, {_Integer?Positive, _Integer?Positive}] ||
      ! MatchQ[positions, {{_Integer?Positive, _Integer?Positive} ..}] ||
      ! ListQ[values] || Length[positions] =!= Length[values],
    Print["Malformed PrevD group inventory: ", inputFile];
    Return[$Failed, Module]];
  payload = <|"Schema" -> "PrevDCheckpointGroupWXFV1",
    "Dimensions" -> dimensions, "Positions" -> positions,
    "Values" -> values|>;
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp-" <> ToString[$ProcessID];
  If[FileExistsQ[temporary], Quiet[DeleteFile[temporary]]];
  exported = Quiet[Check[Export[temporary, payload, "WXF"], $Failed]];
  If[exported === $Failed || ! FileExistsQ[temporary],
    Quiet[DeleteFile[temporary]];
    Print["WXF export failed for ", inputFile];
    Return[$Failed, Module]];
  renamed = Quiet[Check[
    RenameFile[temporary, outputFile, OverwriteTarget -> True], $Failed]];
  If[renamed === $Failed,
    Quiet[DeleteFile[temporary]];
    Print["Atomic WXF rename failed for ", outputFile];
    Return[$Failed, Module]];
  Print["PrevD group ", FileNameTake[inputFile], ": ", Length[values],
    " entries -> ", outputFile, " (", FileByteCount[outputFile], " bytes)"];
  Null
]
