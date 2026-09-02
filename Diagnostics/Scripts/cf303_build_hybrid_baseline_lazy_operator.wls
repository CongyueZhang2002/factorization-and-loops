#!/usr/bin/env wolframscript

(* Build the scratch-only CF303 final-row lazy GPL/eMPL operator from the
   accepted deferred baseline circuit.  No baseline H/K matrix is expanded. *)
Module[
  {root, runtime, load, source, transfer, physicalGauge, circuitManifest,
   adapterManifest, seconds, adapter, output, temporary},

  $HistoryLength = 0;
  root = DirectoryName[DirectoryName[DirectoryName[
    ExpandFileName[$InputFileName]]]];
  runtime = FileNameJoin[{root, "Runtime",
    "2026-08-31_cf303_native_dlog_residues"}];
  load[file_] := Get[FileNameJoin[{root, "Diagnostics", "Scripts", file}]];

  If[DownValues[FeynFacet`Private`masterTransportZeroQ] === {},
    Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]
  ];
  If[DownValues[
      FeynFacet`Private`masterTransportCWNonzeroSparseQ] === {},
    Get[FileNameJoin[{root, "FeynFacet", "Private",
      "CanonicalWordTransport.wl"}]]
  ];
  load["cf303_lazy_final_elliptic_transport.wl"];
  load["cf303_finite_path_gauge_adapter.wl"];
  load["cf303_hybrid_circuit_path_gauge_adapter.wl"];
  load["cf303_hybrid_baseline_lazy_circuit_adapter.wl"];

  source = Get[FileNameJoin[{runtime,
    "cf303_hybrid_elliptic_operator_15_17_21.wl"}]];
  transfer = Get[FileNameJoin[{runtime,
    "cf303_block25_general_elliptic_transfer.wl"}]];
  physicalGauge = Get[FileNameJoin[{runtime,
    "cf303_block25_physical_gauge.wl"}]];
  circuitManifest = Import[FileNameJoin[{runtime,
    "cf303_hybrid_baseline_modular_circuit_manifest.json"}], "RawJSON"];
  adapterManifest = Import[FileNameJoin[{runtime,
    "cf303_hybrid_baseline_lazy_adapter_manifest.json"}], "RawJSON"];

  {seconds, adapter} = AbsoluteTiming[
    cf303BuildHybridBaselineLazyCircuitAdapter[
      source, transfer, physicalGauge, circuitManifest, adapterManifest,
      eps, z]
  ];
  output = FileNameJoin[{runtime,
    "cf303_final45_hybrid_baseline_lazy_operator.wl"}];
  temporary = output <> ".tmp-" <> ToString[$ProcessID];
  Put[Join[adapter, <|"BuildSeconds" -> seconds,
    "EvaluatorLibrary" -> FileNameJoin[{root, "Diagnostics", "Scripts",
      "cf303_hybrid_baseline_lazy_circuit_adapter.wl"}]|>], temporary];
  RenameFile[temporary, output, OverwriteTarget -> True];
  Print[Lookup[adapter, "Status", "MissingStatus"], " in ",
    Round[seconds, 0.01], " s; ", output];
  If[Lookup[adapter, "Status", None] =!=
      "CF303HybridBaselineLazyCircuitAdapterAcceptedV1", $Failed, Null]
]
