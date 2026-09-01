#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
operatorFile = FileNameJoin[{runtime,
  "cf303_final45_lazy_elliptic_operator_15_17_21.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_final45_low_order_materialization.wl"}];
requestedText = Environment["CF303_MATERIALIZE_ORDERS"];
requestedOrders = If[StringQ[requestedText] && requestedText =!= "",
  ToExpression /@ StringSplit[requestedText, ","], {-4}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[libraryFile];
artifact = Get[operatorFile];
operator = artifact["Operator"];
{seconds, coefficients} = AbsoluteTiming[
  AssociationMap[
    cf303FinalEllipticMaterializeCoefficient[operator, #, z,
      "MaxInternalWords" -> 20000,
      "MaxPhysicalTerms" -> 100000] &,
    requestedOrders]];
status = If[AllTrue[Values[coefficients], # ["Status"] === "OK" &],
  "CF303Final45LowOrderMaterializationAcceptedV1",
  "CF303Final45LowOrderMaterializationIncompleteV1"];
result = <|"Status" -> status, "Orders" -> requestedOrders,
  "Seconds" -> seconds,
  "Counts" -> AssociationMap[
    KeyTake[coefficients[#], {"Status", "InternalWordCount",
      "PhysicalTermCount"}] &, requestedOrders],
  "Coefficients" -> coefficients,
  "Operator" -> operatorFile,
  "Library" -> libraryFile|>;
Put[result, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[result, {"Coefficients"}]]];
Print["OUTPUT ", outputFile];
Exit[If[StringEndsQ[status, "AcceptedV1"], 0, 2]];
