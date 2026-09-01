#!/usr/bin/env wolframscript

Get[FileNameJoin[{DirectoryName[$InputFileName],
  "cf303_finite_path_gauge_adapter.wl"}]];

assert[condition_, label_] := If[! TrueQ[condition],
  Print["FAILED ", label]; Exit[2]];

original = <|
  "Status" -> "CF303Block25GeneralEllipticTransferAcceptedV1",
  "Rows" -> {44, 45},
  "EntryRecords" -> {
    {{44, 44}, {"Diagonal"}, {0, 0}, {}},
    {{44, 45}, {"Diagonal"}, {0, 0}, {}},
    {{45, 44}, {"Diagonal"}, {0, 0}, {}},
    {{45, 45}, {"Diagonal"}, {0, 0}, {}}},
  "DiagonalLetters" -> {}, "ConstantGeneratorMatrices" -> {},
  "ConstantCompositeKernels" -> {}|>;
path = <|
  "Status" -> "CF303Block25FinitePathGaugeAcceptedV1",
  "TargetRows" -> {44, 45}, "SourceRows" -> {2, 1},
  "LetterRecords" -> {
    {{"GPLPole", 0}, {1/u, 0}}, {{"E4Omega0"}, {0, 1}}},
  "TransformedResidueRecords" -> {
    {-2, 1, {{44, 1, a}, {45, 2, b}}},
    {0, 2, {{44, 1, c}}}},
  "HByOrder" -> {
    {-2, {{44, 1, {h01, h11}}, {45, 2, {h02, h12}}}},
    {-1, {}}}|>;

synthetic = cf303BuildPathGaugeSyntheticTransfer[original, path, eps];
assert[synthetic["SyntheticIncomingRecordCount"] === 2,
  "synthetic incoming sparsity"];
assert[Length[synthetic["EntryRecords"]] === 6,
  "four diagonal records retained"];
assert[Sort[synthetic["EntryRecords"][[;; 2, 1]]] ===
    {{44, 1}, {45, 2}}, "source coordinates retained"];

hCompiled = cf303PathGaugeCompileH[path];
assert[Normal[hCompiled[-2][[1]]] === {{0, h01}, {h02, 0}},
  "sourceRows ordering in H rational side"];
assert[Normal[hCompiled[-2][[2]]] === {{0, h11}, {h12, 0}},
  "sourceRows ordering in H curve side"];

left = {SparseArray[{{l00, l01}, {l10, l11}}],
  SparseArray[{{m00, m01}, {m10, m11}}]};
right = {SparseArray[{{r0}, {r1}}], SparseArray[{{s0}, {s1}}]};
product = Normal /@ cf303PathGaugePairLeftMultiply[left, right, P4];
assert[Expand[product[[1]] - {
      l00 r0 + l01 r1 + P4 (m00 s0 + m01 s1),
      l10 r0 + l11 r1 + P4 (m10 s0 + m11 s1)}] === {{0}, {0}},
  "quadratic-pair rational convolution"];
assert[Expand[product[[2]] - {
      l00 s0 + l01 s1 + m00 r0 + m01 r1,
      l10 s0 + l11 s1 + m10 r0 + m11 r1}] === {{0}, {0}},
  "quadratic-pair curve convolution"];

Print["CF303 finite path-gauge adapter synthetic tests: PASS"];
Exit[0];
