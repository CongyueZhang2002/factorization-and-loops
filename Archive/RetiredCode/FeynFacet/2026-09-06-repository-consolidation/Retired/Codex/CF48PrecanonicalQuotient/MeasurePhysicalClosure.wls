#!/usr/bin/env wolframscript

repo = "/home/maxzhang/factorization-and-loops";
data = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF48.wl"}];
output = FileNameJoin[{repo, "Codex", "CF48PrecanonicalQuotient",
    "PhysicalClosure_CF48.wl"}];

record = Get[data];
av = record["Av"];
aw = record["Aw"];
dimension = Length[av];
demandedRows = Range[Length[record["CanonicalMasters"]]];

samplePoints = {
   {v -> 1/5, w -> 1/4, eps -> 1/11},
   {v -> 2/7, w -> 1/5, eps -> 1/13},
   {v -> 3/10, w -> 1/6, eps -> 2/17}
   };

EvaluateRows[rows_, point_] := Together[rows /. point];

basis = UnitVector[dimension, #] & /@ demandedRows;
frontier = basis;
rankHistory = {MatrixRank[EvaluateRows[basis, First[samplePoints]]]};
wordHistory = {ConstantArray[{}, Length[basis]]};
basisWords = ConstantArray[{}, Length[basis]];

Do[
  candidates = Flatten[
    MapThread[
      Function[{row, word}, {
        {D[row, v] + row . av, Append[word, v]},
        {D[row, w] + row . aw, Append[word, w]}
        }],
      {frontier, Last[wordHistory]}],
    1];

  currentEvaluation = EvaluateRows[basis, First[samplePoints]];
  currentRank = MatrixRank[currentEvaluation];
  newRows = {};
  newWords = {};

  Do[
    candidateEvaluation = EvaluateRows[{candidate[[1]]}, First[samplePoints]];
    trialRank = MatrixRank[Join[currentEvaluation, candidateEvaluation]];
    If[trialRank > currentRank,
      AppendTo[newRows, candidate[[1]]];
      AppendTo[newWords, candidate[[2]]];
      currentEvaluation = Join[currentEvaluation, candidateEvaluation];
      currentRank = trialRank;
      If[currentRank == dimension, Break[]]
      ],
    {candidate, candidates}];

  basis = Join[basis, newRows];
  basisWords = Join[basisWords, newWords];
  frontier = newRows;
  AppendTo[wordHistory, newWords];
  AppendTo[rankHistory, currentRank];
  Print["depth ", depth, ": rank ", currentRank,
    ", new rows ", Length[newRows]];

  If[currentRank == dimension || newRows === {}, Break[]],
  {depth, 1, dimension}];

verificationRanks = MatrixRank[EvaluateRows[basis, #]] & /@ samplePoints;

result = <|
   "Family" -> "CF48",
   "Connection" -> "OriginalIBPBasis",
   "Dimension" -> dimension,
   "DemandedRows" -> demandedRows,
   "DemandedDimension" -> Length[demandedRows],
   "RankHistory" -> rankHistory,
   "ClosureDimension" -> Last[rankHistory],
   "SelectedDerivativeWords" -> basisWords,
   "VerificationPoints" -> samplePoints,
   "VerificationRanks" -> verificationRanks,
   "ExactAtRationalPoints" -> True
   |>;

Put[result, output];
Print[result];

