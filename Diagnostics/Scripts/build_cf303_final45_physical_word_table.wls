#!/usr/bin/env wolframscript

(* Emit compact physical block-25 coefficients as sparse quadratic-pair
   matrices keyed by {boundary order, internal word}.  Composite and factor
   letters remain interned; expansion to marked-point GPL/eMPL words is an
   explicit on-demand presentation step, not part of production assembly. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
operatorFile = FileNameJoin[{runtime,
  "cf303_final45_finite_path_gauge_operator.wl"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
adapterFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_finite_path_gauge_adapter.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_final45_physical_word_table.wl"}];
requestedText = Environment["CF303_FINAL_ORDERS"];
requestedOrders = If[StringQ[requestedText] && requestedText =!= "",
  ToExpression /@ StringSplit[requestedText, ","], Range[-4, 2]];
capText = Environment["CF303_MAX_INTERNAL_WORDS"];
wordCap = If[StringQ[capText] && capText =!= "",
  ToExpression[capText], 200000];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[libraryFile];
Get[adapterFile];
operatorArtifact = Get[operatorFile];
If[operatorArtifact["Status"] =!=
    "CF303Final45FinitePathGaugeOperatorAcceptedV1",
  Print["REFUSED accepted finite path-gauge operator is required"];
  Exit[2]];
adapter = operatorArtifact["Adapter"];

{buildSeconds, tables} = AbsoluteTiming[AssociationMap[
  cf303PathGaugePhysicalCoefficientRecords[adapter, #,
    "MaxInternalWords" -> wordCap] &, requestedOrders]];
status = If[AllTrue[Values[tables], # ["Status"] === "OK" &],
  "CF303Final45PhysicalWordTableAcceptedV1",
  "CF303Final45PhysicalWordTableIncompleteV1"];
result = <|
  "Status" -> status,
  "Family" -> "CF303",
  "Rows" -> adapter["TargetRows"],
  "Orders" -> requestedOrders,
  "BuildSeconds" -> buildSeconds,
  "InternalWordCap" -> wordCap,
  "Counts" -> AssociationMap[
    KeyTake[tables[#], {"Status", "InternalWordCount"}] &,
    requestedOrders],
  "CoefficientTables" -> tables,
  "PairConvention" -> adapter["PairConvention"],
  "Curve" -> adapter["Curve"],
  "Letters" -> adapter["GOperator", "Letters"],
  "CompositeDefinitions" ->
    adapter["GOperator", "CompositeDefinitions"],
  "BoundaryColumns" -> adapter["BoundaryColumns"],
  "BoundaryConvention" -> adapter["BoundaryConvention"],
  "WordConvention" ->
    "Each InternalWord is an ordered list of one-based IDs into Letters",
  "Operator" -> operatorFile|>;
Put[result, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[result,
  {"CoefficientTables", "Letters", "CompositeDefinitions"}]]];
Print["OUTPUT ", outputFile];
Exit[If[StringEndsQ[status, "AcceptedV1"], 0, 3]];
