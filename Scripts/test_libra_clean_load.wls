#!/usr/bin/env wolframscript
(* Verify that suppressing the banner through $Output preserves option keys. *)

$HistoryLength = 0;
file = "/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/Libra/Source/Libra.m";
Quiet[Block[{$Output = {}}, Get[file]], {General::shdw}];
newDSystemOptions = Options[Libra`NewDSystem];
historyAppendOptions = Options[Libra`HistoryAppend];
projectorOptions = Options[Libra`Projector];
criterion = MemberQ[newDSystemOptions, Print -> True] &&
  MemberQ[historyAppendOptions, Print -> True];
Print[InputForm[<|"NewDSystem" -> newDSystemOptions,
  "HistoryAppend" -> historyAppendOptions,
  "Projector" -> projectorOptions,
  "OptionKeysPreserved" -> criterion|>]];
If[! criterion, Exit[1]];
