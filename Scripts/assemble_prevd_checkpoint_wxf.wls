#!/usr/bin/env wolframscript

(* Pool-safe mission: import converted groups, restore PrevD, and write the
   complete checkpoint as WXF.
   Usage: assemble_prevd_checkpoint_wxf.wls MANIFEST.wl CHECKPOINT.wxf *)
Module[
  {arguments = Rest[$ScriptCommandLine], manifestFile, outputFile, manifest,
   skeletonFile, skeleton, dimensions, groups, prevD, filled, record,
   groupFile, group, positions, values, position, index, full,
   temporary, exported, renamed},
  If[Length[arguments] =!= 2,
    Print["Usage: assemble_prevd_checkpoint_wxf.wls MANIFEST.wl CHECKPOINT.wxf"];
    Return[$Failed, Module]];
  {manifestFile, outputFile} = ExpandFileName /@ arguments;
  If[! FileExistsQ[manifestFile],
    Print["PrevD split manifest does not exist: ", manifestFile];
    Return[$Failed, Module]];
  manifest = Quiet[Check[Get[manifestFile], $Failed]];
  If[! AssociationQ[manifest] ||
      Lookup[manifest, "Schema", None] =!= "PrevDCheckpointSplitV1",
    Print["Invalid PrevD split manifest: ", manifestFile];
    Return[$Failed, Module]];
  {skeletonFile, dimensions, groups} =
    Lookup[manifest, {"SkeletonFile", "Dimensions", "Groups"}, $Failed];
  If[! StringQ[skeletonFile] ||
      ! MatchQ[dimensions, {_Integer?Positive, _Integer?Positive}] ||
      ! MatchQ[groups, {__Association}],
    Print["Malformed PrevD split manifest: ", manifestFile];
    Return[$Failed, Module]];
  skeleton = Quiet[Check[Get[skeletonFile], $Failed]];
  If[! AssociationQ[skeleton],
    Print["Invalid checkpoint skeleton: ", skeletonFile];
    Return[$Failed, Module]];

  prevD = ConstantArray[Missing["UnfilledPrevD"], dimensions];
  filled = ConstantArray[False, dimensions];
  Do[
    record = groups[[index]];
    groupFile = Lookup[record, "WXFFile", None];
    If[! StringQ[groupFile] || ! FileExistsQ[groupFile],
      Print["Converted PrevD group is missing: ", groupFile];
      Return[$Failed, Module]];
    group = Quiet[Check[Import[groupFile, "WXF"], $Failed]];
    If[! AssociationQ[group] ||
        Lookup[group, "Schema", None] =!= "PrevDCheckpointGroupWXFV1" ||
        Lookup[group, "Dimensions", None] =!= dimensions,
      Print["Invalid converted PrevD group: ", groupFile];
      Return[$Failed, Module]];
    {positions, values} = Lookup[group, {"Positions", "Values"}, $Failed];
    If[! MatchQ[positions, {{_Integer?Positive, _Integer?Positive} ..}] ||
        ! ListQ[values] || Length[positions] =!= Length[values],
      Print["Malformed converted PrevD inventory: ", groupFile];
      Return[$Failed, Module]];
    Do[
      position = positions[[entryIndex]];
      If[! And @@ MapThread[Between,
          {position, ({1, #} &) /@ dimensions}] ||
          TrueQ[Extract[filled, position]],
        Print["Invalid or duplicate PrevD position ", position,
          " in ", groupFile];
        Return[$Failed, Module]];
      prevD[[Sequence @@ position]] = values[[entryIndex]];
      filled[[Sequence @@ position]] = True,
      {entryIndex, Length[positions]}];
    group =.; values =.; positions =.,
    {index, Length[groups]}];
  If[! And @@ Flatten[filled],
    Print["Converted groups do not cover the complete PrevD matrix"];
    Return[$Failed, Module]];

  full = Join[skeleton, <|"PrevD" -> prevD|>];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp-" <> ToString[$ProcessID];
  If[FileExistsQ[temporary], Quiet[DeleteFile[temporary]]];
  exported = Quiet[Check[Export[temporary, full, "WXF"], $Failed]];
  If[exported === $Failed || ! FileExistsQ[temporary],
    Quiet[DeleteFile[temporary]];
    Print["Full checkpoint WXF export failed: ", outputFile];
    Return[$Failed, Module]];
  renamed = Quiet[Check[
    RenameFile[temporary, outputFile, OverwriteTarget -> True], $Failed]];
  If[renamed === $Failed,
    Quiet[DeleteFile[temporary]];
    Print["Atomic checkpoint WXF rename failed: ", outputFile];
    Return[$Failed, Module]];
  Print["PrevD checkpoint ", dimensions[[1]], "x", dimensions[[2]],
    " assembled -> ", outputFile, " (", FileByteCount[outputFile],
    " bytes)"];
  Null
]
