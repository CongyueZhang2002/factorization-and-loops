#!/usr/bin/env wolframscript

(* Scratch-only extraction of the exact diagonal data needed by the isolated
   CF303 (25,1) finite path-gauge pilot.  This does not modify the package or
   claim that the complete block-25 transfer is assembled. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
sourceFile = FileNameJoin[{runtime,
  "cf303_hybrid_elliptic_operator_15_17_21.wl"}];
transferFile = FileNameJoin[{runtime,
  "cf303_block25_general_elliptic_transfer.wl"}];
finalFile = FileNameJoin[{runtime,
  "cf303_final45_lazy_elliptic_operator_15_17_21.wl"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_block1_finite_gauge_inputs.wl"}];
jsonFile = FileNameJoin[{runtime,
  "cf303_block1_finite_gauge_inputs.json"}];

Get[libraryFile];
sourceArtifact = Get[sourceFile];
transfer = Get[transferFile];
finalArtifact = Get[finalFile];
operator = finalArtifact["Operator"];
If[sourceArtifact["Status"] =!= "CF303HybridEllipticOperatorAcceptedV1" ||
    transfer["Status"] =!=
      "CF303Block25GeneralEllipticTransferAcceptedV1" ||
    finalArtifact["Status"] =!=
      "CF303Final45LazyEllipticArtifactAcceptedV1" ||
    operator["Status"] =!= "CF303Final45LazyEllipticOperatorAcceptedV1",
  Print["REFUSED accepted source/diagonal inputs unavailable"];
  Exit[2]];

curve = transfer["Curve"];
basisShift = Together[
  Coefficient[curve, u, 3]/(2 Coefficient[curve, u, 4])];
definitions = operator["CompositeDefinitions"];
pairAdd[left_, right_] := left + right;

Clear[expandPair];
expandPair[label_] := expandPair[label] = Module[{definition},
  definition = Lookup[definitions, Key[label], Missing["Definition"]];
  If[! MissingQ[definition],
    Return[Total[(#[[1]] expandPair[#[[2]]]) & /@ definition]]];
  Which[
    MatchQ[label, {"GPLPole", _}], {1/(u - label[[2]]), 0},
    MatchQ[label, {"GPLFactor", _, _Integer}],
      {u^label[[3]]/label[[2]], 0},
    label === {"E4Omega0"}, {0, 1},
    label === {"E4OmegaInf"}, {0, u},
    label === {"E4Eta2"}, {0, u^2 + basisShift u},
    MatchQ[label, {"E4Pole", _}],
      {0, Yc[label[[2]]]/(u - label[[2]])},
    MatchQ[label, {"E4Factor", _, _Integer}],
      {0, u^label[[3]]/label[[2]]},
    True, Print["REFUSED unsupported letter ", InputForm[label]]; Exit[3]
  ]
];

source = sourceArtifact["Operator"];
sourcePosition = First@FirstPosition[sourceArtifact["OriginalRows"], 1];
s11 = Total@Table[
  source["Residues"][[letter, sourcePosition, sourcePosition]]
    expandPair[source["Letters"][[letter]] /. z -> u],
  {letter, Length[source["Letters"]]}];
(* The only radicals in S11 are a conjugate pole pair.  Their product is
   u^2-4 p (p-1), independent of the endpoint symbol and branch. *)
s11 = {Together[
  4 (-4 p + 4 p^2 - 4 p u + 4 p^2 u + u^2)/
    ((2 p - u) (-2 + 2 p^2 + p u) (u^2 - 4 p (p - 1)))], 0};

targetRows = transfer["Rows"];
targetPosition = AssociationThread[targetRows, Range[Length[targetRows]]];
d = Table[{0, 0}, {Length[targetRows]}, {Length[targetRows]}];
diagonalRecords = Select[transfer["EntryRecords"],
  MemberQ[targetRows, #[[1, 1]]] && MemberQ[targetRows, #[[1, 2]]] &];
If[Length[diagonalRecords] =!= 4,
  Print["REFUSED target diagonal record count ", Length[diagonalRecords]];
  Exit[4]];
Do[
  row = targetPosition[record[[1, 1]]];
  column = targetPosition[record[[1, 2]]];
  Do[
    coefficient = Together[term[[1]]/eps];
    If[! FreeQ[coefficient, eps],
      Print["REFUSED target diagonal is not epsilon-linear"];
      Exit[5]];
    d[[row, column]] += coefficient term[[2, 2]],
    {term, record[[4]]}],
  {record, diagonalRecords}];

result = <|
  "Status" -> "CF303Block1FiniteGaugeInputsV1",
  "Curve" -> curve,
  "Variable" -> u,
  "OuterParameter" -> p,
  "BasePoint" -> 1/2,
  "SourceOriginalRow" -> 1,
  "SourcePosition" -> sourcePosition,
  "SourceBoundaryOrders" -> Select[Keys[source["BoundarySelectors"]],
    MemberQ[source["ActiveRowsByOrder", #], sourcePosition] &],
  "TargetOutputTop" -> 2,
  "DemandedHOrders" -> {-3, -2, -1, 0, 1, 2},
  "RecurrenceWindow" -> {-3, 4},
  "S11" -> Together /@ s11,
  "D" -> Map[Together, d, {3}]
|>;
Put[result, outputFile];
rationalRecord[expression_] := Module[{value = Together[expression]}, <|
  "Numerator" -> (ToString[#, InputForm] & /@
    CoefficientList[Numerator[value], u]),
  "Denominator" -> (ToString[#, InputForm] & /@
    CoefficientList[Denominator[value], u])|>];
If[s11[[2]] =!= 0 || ! FreeQ[s11, Sqrt | uFinal] ||
    ! FreeQ[d, Sqrt | uFinal] || ! AllTrue[Flatten[d[[All, All, 2]]], # === 0 &],
  Print["REFUSED diagonal inputs did not reduce to rational path forms"];
  Exit[6]];
json = <|
  "status" -> "CF303Block1FiniteGaugeInputsV1",
  "source_boundary_orders" -> result["SourceBoundaryOrders"],
  "target_output_top" -> result["TargetOutputTop"],
  "demanded_h_orders" -> result["DemandedHOrders"],
  "recurrence_window" -> result["RecurrenceWindow"],
  "base_point" -> {1, 2},
  "curve" -> (ToString[#, InputForm] & /@ CoefficientList[curve, u]),
  "s11" -> rationalRecord[s11[[1]]],
  "d" -> Map[rationalRecord[#[[1]]] &, d, {2}]
|>;
Export[jsonFile, json, "RawJSON"];
Print[InputForm[KeyDrop[result, {"Curve", "S11", "D"}]]];
Print["OUTPUT ", outputFile];
Print["JSON ", jsonFile];
Exit[0];
