#!/usr/bin/env wolframscript

(* Assemble the complete 45-master CF303 endpoint operator after the finite
   path-only triangular gauge has removed every exact primitive from the
   block-25 incoming row.  This stays lazy: no Chen words are enumerated. *)

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
pathGaugeFile = FileNameJoin[{runtime,
  "cf303_block25_finite_path_gauge.wl"}];
physicalGaugeFile = FileNameJoin[{runtime,
  "cf303_block25_physical_gauge.wl"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
adapterFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_finite_path_gauge_adapter.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_final45_finite_path_gauge_operator.wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[libraryFile];
Get[adapterFile];
sourceArtifact = Get[sourceFile];
transfer = Get[transferFile];
pathGauge = Get[pathGaugeFile];
physicalGauge = Get[physicalGaugeFile];

{buildSeconds, adapter} = AbsoluteTiming[
  cf303BuildFinitePathGaugeAdapter[sourceArtifact, transfer, pathGauge,
    physicalGauge, eps, z, {-2, 4}]];
status = If[adapter["Status"] ===
    "CF303FinitePathGaugeAdapterAcceptedV1",
  "CF303Final45FinitePathGaugeOperatorAcceptedV1",
  "CF303Final45FinitePathGaugeOperatorFailedV1"];
artifact = <|
  "Status" -> status,
  "Family" -> "CF303",
  "MasterCount" -> 45,
  "SourceMasterCount" -> 43,
  "TargetRows" -> Lookup[adapter, "TargetRows", {}],
  "TargetOrders" -> {-4, 2},
  "IncomingOrders" -> {-2, 4},
  "EndpointVariable" -> z,
  "BuildSeconds" -> buildSeconds,
  "Representation" ->
    "I25=T25.(G25+H.L), with G25 residue-only and H(base)=0",
  "BoundaryConvention" -> Lookup[adapter, "BoundaryConvention", None],
  "Adapter" -> adapter,
  "Inputs" -> <|"Source" -> sourceFile, "Transfer" -> transferFile,
    "PathGauge" -> pathGaugeFile,
    "PhysicalGauge" -> physicalGaugeFile|>,
  "Libraries" -> {libraryFile, adapterFile}|>;
Put[artifact, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[artifact, {"Adapter"}]]];
Print["OUTPUT ", outputFile];
Exit[If[StringEndsQ[status, "AcceptedV1"], 0, 2]];
