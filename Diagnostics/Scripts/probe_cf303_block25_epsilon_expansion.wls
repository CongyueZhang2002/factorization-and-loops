#!/usr/bin/env wolframscript

runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues";
transfer = Get[FileNameJoin[{runtime,
  "cf303_block25_general_elliptic_transfer.wl"}]];
offDiagonal = Select[transfer["EntryRecords"], #[[1, 2]] < 44 &];
coefficients = Flatten[offDiagonal[[All, 4, All, 1]]];
{seconds, expansions} = AbsoluteTiming[
  Normal[Series[#, {eps, 0, 4}]] & /@ coefficients];
nonzeroByOrder = Association@Table[
  order -> Count[Coefficient[#, eps, order] & /@ expansions,
    value_ /; ! TrueQ[value === 0]],
  {order, -2, 4}];
Print[InputForm[<|
  "Status" -> "CF303Block25EpsilonExpansionProbeV1",
  "EntryCount" -> Length[offDiagonal],
  "CoefficientCount" -> Length[coefficients],
  "Orders" -> Range[-2, 4],
  "NonzeroByOrder" -> nonzeroByOrder,
  "Seconds" -> seconds,
  "MaxByteCountPerSeries" -> Max[ByteCount /@ expansions],
  "TotalByteCount" -> Total[ByteCount /@ expansions]
|>]];
