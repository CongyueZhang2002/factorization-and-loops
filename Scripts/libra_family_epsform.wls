#!/usr/bin/env wolframscript
(* Standalone entry point for one whole-family Libra calculation. *)

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
argv = Rest[$ScriptCommandLine];
If[Length[argv] < 2,
  Print["usage: libra_family_epsform.wls <family> <output-directory> [time-limit]"];
  Exit[64]];

Get[FileNameJoin[{root, "Scripts", "LibraFamilyEpsFormWorker.wl"}]];
result = FACETBatch`RunLibraFamilyEpsForm[
  argv[[1]], ExpandFileName[argv[[2]]],
  If[Length[argv] >= 3, ToExpression[argv[[3]]], 1800]];
Print[InputForm[result]];
Exit[If[AssociationQ[result] && Lookup[result, "Status", None] === "EpsForm",
  0, 1]];

