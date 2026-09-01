#!/usr/bin/env wolframscript

$HistoryLength = 0;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
layers = Environment["CF303_FINAL_SOURCE_LAYERS"];
If[! StringQ[layers] || layers === "", layers = "15_17"];
artifactFile = FileNameJoin[{runtime,
  "cf303_final45_lazy_elliptic_operator_" <> layers <> ".wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}]];
artifact = Get[artifactFile];
operator = artifact["Operator"];
source = operator["SourceArtifact", "Operator"];
sourceN = operator["SourceN"];
fullN = operator["N"];
sourceBoundaryCount = operator["SourceBoundaryCount"];
boundaryDimension = Length[operator["BoundaryColumns"]];
sourceLetterCount = operator["SourceLetterCount"];
diagonalIDs = operator["DiagonalLetterIDs"];
offResidues = operator["OffDiagonalResidues"];

embedRules[matrix_, rowShift_, columnShift_] :=
  (First[#] + {rowShift, columnShift} -> Last[#] &) /@
    Select[ArrayRules[matrix],
      MatchQ[First[#], {_Integer, _Integer}] &];

fullBoundarySelector[q_] := Module[{rules = {}, sourceSelector,
    targetSelector},
  sourceSelector = Lookup[source["BoundarySelectors"], q,
    SparseArray[{}, {sourceN, sourceBoundaryCount}]];
  targetSelector = Lookup[operator["TargetBoundarySelectors"], q,
    SparseArray[{}, {2, boundaryDimension}]];
  rules = Join[embedRules[sourceSelector, 0, 0],
    embedRules[targetSelector, sourceN, 0]];
  SparseArray[rules, {fullN, boundaryDimension}]];

fullResidue[letter_Integer, epsilonOrder_Integer] := Module[
  {matrix, rules},
  Which[
    letter <= sourceLetterCount && epsilonOrder === 1,
      matrix = source["Residues"][[letter]];
      rules = embedRules[matrix, 0, 0],
    MemberQ[diagonalIDs, letter] && epsilonOrder === 1,
      matrix = operator["DiagonalResidues"][letter];
      rules = embedRules[matrix, sourceN, sourceN],
    KeyExistsQ[offResidues, {epsilonOrder, letter}],
      matrix = offResidues[{epsilonOrder, letter}];
      rules = embedRules[matrix, sourceN, 0],
    True, rules = {}];
  SparseArray[rules, {fullN, fullN}]];

letterOrders[letter_] := Which[
  letter <= sourceLetterCount, {1},
  MemberQ[diagonalIDs, letter], {1},
  True, Sort@Cases[Keys[offResidues],
    {epsilonOrder_, letter} :> epsilonOrder]];

directCoefficient[word_List, boundaryOrder_Integer,
    order_Integer] := Module[{assignments, selector, total},
  selector = fullBoundarySelector[boundaryOrder];
  assignments = If[word === {}, {{}},
    Select[Tuples[letterOrders /@ word],
      Total[#] === order - boundaryOrder &]];
  total = Total[Map[Function[orders,
      Fold[fullResidue[#2[[1]], #2[[2]]] . #1 &,
        selector, Reverse[Transpose[{word, orders}]]]], assignments]];
  If[Head[total] =!= SparseArray, total = SparseArray[total]];
  total[[sourceN + 1 ;; fullN, All]]];

sameQ[word_, q_, n_] := Module[{lazy, direct, residual},
  lazy = cf303FinalEllipticWordCoefficient[operator, word, q, n];
  direct = directCoefficient[word, q, n];
  residual = Normal[lazy - direct];
  <|"Word" -> word, "BoundaryOrder" -> q, "Order" -> n,
    "Equal" -> AllTrue[Flatten[residual], TrueQ[# === 0] &],
    "Nonzero" ->
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[lazy]|>];

incomingKey = SelectFirst[Keys[offResidues], -2 <= #[[1]] <= 2 &];
incomingID = incomingKey[[2]];
incomingOrder = incomingKey[[1]];
sourcePair = SelectFirst[
  Flatten[Table[{key, sourceLetter}, {key, Keys[offResidues]},
    {sourceLetter, sourceLetterCount}], 1],
  With[{word = {#[[1, 2]], #[[2]]},
      n = #[[1, 1]] + 1},
    FeynFacet`Private`masterTransportCWNonzeroSparseQ[
      cf303FinalEllipticWordCoefficient[operator, word, 0, n]]] &,
  Missing["NoReachablePair"]];
If[MissingQ[sourcePair], Print["NO_REACHABLE_SOURCE_PAIR"]; Exit[3]];
sourceIncomingKey = sourcePair[[1]];
sourceLetter = sourcePair[[2]];

records = {
  sameQ[{}, 0, 0],
  sameQ[{First[diagonalIDs]}, 0, 1],
  sameQ[Take[diagonalIDs, UpTo[2]], 0,
    Length[Take[diagonalIDs, UpTo[2]]]],
  sameQ[{incomingID}, 0, incomingOrder],
  sameQ[{First[diagonalIDs], incomingID}, 0, incomingOrder + 1],
  sameQ[{sourceIncomingKey[[2]], sourceLetter}, 0,
    sourceIncomingKey[[1]] + 1]
};
status = If[AllTrue[records, TrueQ[# ["Equal"]] &] &&
    Count[records[[All, "Nonzero"]], True] >= 5,
  "CF303FinalLazyWeightedRecurrenceAcceptedV1",
  "CF303FinalLazyWeightedRecurrenceFailedV1"];
Print[InputForm[<|"Status" -> status, "Cases" -> records|>]];
Exit[If[StringEndsQ[status, "AcceptedV1"], 0, 4]];
