#!/usr/bin/env wolframscript

(* Export the epsilon-linear lower and target diagonal path connections as
   algebraic one-form pairs for the finite path-gauge completion of block 25.
   The complete incoming reduction deck stays in its native Maple artifact. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
sourceFile = FileNameJoin[{runtime,
  "cf303_hybrid_elliptic_operator_15_17_21.wl"}];
transferFile = FileNameJoin[{runtime,
  "cf303_block25_general_elliptic_transfer.wl"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_block25_path_dlog_gauge_inputs.maple"}];
metadataFile = FileNameJoin[{runtime,
  "cf303_block25_path_dlog_gauge_inputs_metadata.wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[libraryFile];
sourceArtifact = Get[sourceFile];
transfer = Get[transferFile];
If[sourceArtifact["Status"] =!=
      "CF303HybridEllipticOperatorAcceptedV1" ||
    transfer["Status"] =!=
      "CF303Block25GeneralEllipticTransferAcceptedV1" ||
    Sort[Lookup[transfer, "ExceptionBlocks", {}]] =!= {1, 2, 11, 14, 18} ||
    Length[transfer["EntryRecords"]] =!= 90,
  Print["REFUSED complete accepted source/transfer artifacts are required"];
  Exit[2]];

operator = cf303BuildLazyFinalEllipticOperator[
  sourceArtifact, transfer, eps, u, {-2, 4}];
If[operator["Status"] =!= "CF303Final45LazyEllipticOperatorAcceptedV1",
  Print["REFUSED lazy operator assembly failed"]; Exit[3]];
source = sourceArtifact["Operator"];
curve = transfer["Curve"];
basisShift = Together[
  Coefficient[curve, u, 3]/(2 Coefficient[curve, u, 4])];
definitions = operator["CompositeDefinitions"];

pairAdd[left_, right_] := {left[[1]] + right[[1]],
  left[[2]] + right[[2]]};
pairScale[scalar_, pair_] := scalar pair;

Clear[expandPair];
expandPair[label_] := expandPair[label] = Module[{definition},
  definition = Lookup[definitions, Key[label], Missing["Definition"]];
  If[! MissingQ[definition],
    Return[Fold[pairAdd, {0, 0},
      pairScale[#[[1]], expandPair[#[[2]]]] & /@ definition]]];
  Which[
    MatchQ[label, {"GPLPole", _}],
      {1/(u - label[[2]]), 0},
    MatchQ[label, {"GPLFactor", _, _Integer}],
      {u^label[[3]]/label[[2]], 0},
    label === {"E4Omega0"},
      {0, 1},
    label === {"E4OmegaInf"},
      {0, u},
    label === {"E4Eta2"},
      {0, u^2 + basisShift u},
    MatchQ[label, {"E4Pole", _}],
      {0, Yc[label[[2]]]/(u - label[[2]])},
    MatchQ[label, {"E4Factor", _, _Integer}],
      {0, u^label[[3]]/label[[2]]},
    True,
      Print["REFUSED unsupported source letter ", InputForm[label]];
      Exit[4]
  ]
];

pairMatrixFromResidues[labels_List, residues_List, dimension_Integer] :=
 Module[{matrix, label, pair, rules},
  matrix = Table[{0, 0}, {dimension}, {dimension}];
  Do[
    label = labels[[letter]] /. z -> u;
    pair = expandPair[label];
    rules = Select[ArrayRules[residues[[letter]]],
      MatchQ[First[#], {_Integer, _Integer}] &];
    Do[
      matrix[[rule[[1, 1]], rule[[1, 2]]]] = pairAdd[
        matrix[[rule[[1, 1]], rule[[1, 2]]]],
        pairScale[rule[[2]], pair]],
      {rule, rules}],
    {letter, Length[labels]}];
  matrix
];

matrixRecords[matrix_List] := Module[{rows, columns, harvested, pair},
  {rows, columns} = Dimensions[matrix][[;; 2]];
  harvested = Reap[Do[
    pair = Together /@ matrix[[row, column]];
    If[! TrueQ[pair === {0, 0}], Sow[{row, column, pair}]],
    {row, rows}, {column, columns}]][[2]];
  If[harvested === {}, {}, First[harvested]]
];

{compileSeconds, compiled} = AbsoluteTiming[
  sourceMatrix = pairMatrixFromResidues[
    source["Letters"], source["Residues"], source["N"]];
  targetMatrix = Table[{0, 0}, {2}, {2}];
  KeyValueMap[Function[{letterID, residue}, Module[
      {label = operator["Letters"][[letterID]], pair, rules},
      pair = expandPair[label];
      rules = Select[ArrayRules[residue],
        MatchQ[First[#], {_Integer, _Integer}] &];
      Do[targetMatrix[[rule[[1, 1]], rule[[1, 2]]]] = pairAdd[
          targetMatrix[[rule[[1, 1]], rule[[1, 2]]]],
          pairScale[rule[[2]], pair]],
        {rule, rules}]]], operator["DiagonalResidues"]];
  sourceRecords = matrixRecords[sourceMatrix];
  targetRecords = matrixRecords[targetMatrix]];

markedPoints = DeleteDuplicates[Cases[
  {sourceRecords, targetRecords}, Yc[point_] :> point, Infinity]];
markedSymbols = Table[Symbol["yc" <> ToString[index]],
  {index, Length[markedPoints]}];
markedRules = Thread[(Yc /@ markedPoints) -> markedSymbols];
mapleString[value_] := StringReplace[
  ToString[value /. markedRules, InputForm, PageWidth -> Infinity],
  {"Global`" -> "", "FeynFacet`Private`" -> "",
    "{" -> "[", "}" -> "]"}];

text = StringRiffle[{
  "curve := " <> mapleString[curve] <> ":",
  "basePoint := 1/2:",
  "sourceDimension := " <> ToString[source["N"]] <> ":",
  "targetDimension := 2:",
  "sourceRows := " <> mapleString[sourceArtifact["OriginalRows"]] <> ":",
  "sourceFormRecords := " <> mapleString[sourceRecords] <> ":",
  "targetFormRecords := " <> mapleString[targetRecords] <> ":",
  "markedPointDefinitions := " <>
    mapleString[Transpose[{markedSymbols, markedPoints}]] <> ":"
}, "\n"] <> "\n";
Export[outputFile, text, "Text"];
metadata = <|
  "Status" -> "CF303Block25PathDLogGaugeInputsV1",
  "SourceDimension" -> source["N"],
  "SourceRows" -> sourceArtifact["OriginalRows"],
  "SourceFormRecordCount" -> Length[sourceRecords],
  "TargetFormRecordCount" -> Length[targetRecords],
  "MarkedPointCount" -> Length[markedPoints],
  "CompileSeconds" -> compileSeconds,
  "OutputBytes" -> FileByteCount[outputFile],
  "Output" -> outputFile|>;
Put[metadata, metadataFile];
Print[InputForm[metadata]];
Exit[0];
