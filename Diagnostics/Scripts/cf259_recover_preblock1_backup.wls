#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
source = "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/" <>
  "Results/UU_08_10_canonical/FamilyEpsFormsSolving/" <>
  "triple_root_2026-08-28_codex_clean/CF259/" <>
  "sector_CF259_standard/CF259_27_strip_state.wl";
output = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_rank3_installed_backups/" <>
  "CF259_27_strip_state_before_block1.wl";
checkpoint = Get[source];
predecessor = Join[checkpoint, <|
  "PrevD" -> (Rest /@ checkpoint["PrevD"]),
  "StripSolvers" -> Most[checkpoint["StripSolvers"]]|>];
Put[predecessor, output];
Print[InputForm[<|"PrevDDimensions" -> Dimensions[predecessor["PrevD"]],
  "LastLowerSector" -> Last[predecessor["StripSolvers"]]["LowerSector"],
  "Output" -> output|>]];
