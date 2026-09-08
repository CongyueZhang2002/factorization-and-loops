#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];

a2Results = Table[
  data = Get[FileNameJoin[{bundle, "a2_real_" <> name,
    "a2_frozen_end_to_end_result.wl"}]];
  KeyTake[data, {"FixtureName", "KernelCount", "PrimesUsed",
    "PrimeSampleCounts", "PrimeSamplingWallSeconds",
    "PrimeSchedulerWallSeconds", "DiscardedSampleCounts",
    "ReconstructionAttempts", "UnseenPrimeResidualPassedBeforeExactCheck",
    "ExactCheckWallSeconds", "ExactPfaffianResidualsZero",
    "OracleAgreement", "TotalWallSeconds"}],
  {name, {"CF254_9_6", "CF254_9_7"}}];

a3Results = Table[
  data = Get[FileNameJoin[{bundle,
    "a3_sparse_newton_result_" <> name <> ".wl"}]];
  KeyTake[data, {"Fixture", "DegreeOffset", "PoleBoundPlan",
    "OracleSupportUsedAsInput", "OracleSupportRegressionSameQ",
    "FullUnknownCount", "SparseUnknownCount", "FullPointCount",
    "SparsePointCount", "ReducedMatrixDimensions",
    "ReducedCoreDimensions", "ReducedRank", "Nullity",
    "ReducedSolveWallSeconds", "AllReducedRowsParticularCheckZero",
    "AllReducedRowsNullspaceCheckZero", "NormalizationCheck",
    "ModularParticularOracleSameQ", "SparseLiftWallSeconds",
    "ExactCheckWallSeconds", "ExactPfaffianResidualsZero",
    "ExactOracleAgreement"}],
  {name, {"CF254_9_6", "CF254_9_7"}}];

a4 = Get[FileNameJoin[{bundle, "a4_backend_benchmark_result.wl"}]];
a4Results = KeyTake[a4, {"Status", "Scope", "ExternalBackend",
  "FLINTVersion", "ThreadCounts", "ConversionAndTransferCounted",
  "Cases", "TotalWallSeconds"}];

summary = <|
  "Date" -> "2026-08-21",
  "Scope" -> "ExternalRound2NoPackageEdits",
  "A2" -> a2Results,
  "A3" -> a3Results,
  "A4" -> a4Results
|>;
Put[summary, FileNameJoin[{bundle,
  "codex_ff_round2_measured_summary.wl"}]];
Print[InputForm[<|
  "A2" -> (KeyTake[#, {"FixtureName", "PrimeSampleCounts",
      "TotalWallSeconds", "ExactPfaffianResidualsZero"}] & /@ a2Results),
  "A3" -> (KeyTake[#, {"Fixture", "FullUnknownCount",
      "SparseUnknownCount", "FullPointCount", "SparsePointCount",
      "ExactPfaffianResidualsZero"}] & /@ a3Results),
  "A4" -> (KeyTake[#, {"Label", "PrimeBitLength",
      "WolframSparseTotalWithCoreBuildSeconds",
      "WolframDenseTotalWithConversionSeconds",
      "FLINT1TotalWithConversionTransferSeconds",
      "FLINT4TotalWithConversionTransferSeconds"}] & /@
        a4Results["Cases"])
|>]];

