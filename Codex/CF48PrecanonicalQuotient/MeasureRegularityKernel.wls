#!/usr/bin/env wolframscript

repo = "/home/maxzhang/factorization-and-loops";
data = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF48.wl"}];
output = FileNameJoin[{repo, "Codex", "CF48PrecanonicalQuotient",
    "RegularityKernel_CF48.wl"}];

record = Get[data];
av = record["Av"];
aw = record["Aw"];
dimension = Length[av];

LaurentMatrix[matrix_, order_] :=
  Map[Cancel[SeriesCoefficient[#, {eps, 0, order}]] &, matrix, {2}];

orders = Range[-4, -1];
avLaurent = Association[Table[order -> LaurentMatrix[av, order], {order, orders}]];
awLaurent = Association[Table[order -> LaurentMatrix[aw, order], {order, orders}]];
nonzeroOrders = Select[orders,
   ! TrueQ[avLaurent[#] === ConstantArray[0, {dimension, dimension}]] ||
     ! TrueQ[awLaurent[#] === ConstantArray[0, {dimension, dimension}]] &];

minimumOrder = Min[nonzeroOrders];
If[minimumOrder =!= -2,
  Print["unexpected minimum epsilon order: ", minimumOrder];
  Exit[1]];

zero = ConstantArray[0, {dimension, dimension}];
leadingConstraints = Join[avLaurent[-2], awLaurent[-2]];
jetConstraints = Join[
   ArrayFlatten[{{avLaurent[-2], zero}}],
   ArrayFlatten[{{awLaurent[-2], zero}}],
   ArrayFlatten[{{avLaurent[-1], avLaurent[-2]}}],
   ArrayFlatten[{{awLaurent[-1], awLaurent[-2]}}]
   ];

samplePoints = {
   {v -> 1/5, w -> 1/4},
   {v -> 2/7, w -> 1/5},
   {v -> 3/10, w -> 1/6}
   };

leadingRanks = MatrixRank[Together[leadingConstraints /. #]] & /@ samplePoints;
jetRanks = MatrixRank[Together[jetConstraints /. #]] & /@ samplePoints;

result = <|
   "Family" -> "CF48",
   "Connection" -> "OriginalIBPBasis",
   "Dimension" -> dimension,
   "MinimumEpsilonOrder" -> minimumOrder,
   "NonzeroNegativeOrders" -> nonzeroOrders,
   "LeadingCoefficientDimension" -> dimension,
   "LeadingConstraintRanks" -> leadingRanks,
   "LeadingAllowedDimensions" -> (dimension - # & /@ leadingRanks),
   "TwoJetDimension" -> 2 dimension,
   "TwoJetConstraintRanks" -> jetRanks,
   "TwoJetAllowedDimensions" -> (2 dimension - # & /@ jetRanks),
   "VerificationPoints" -> samplePoints,
   "ExactAtRationalPoints" -> True
   |>;

Put[result, output];
Print[result];

