#!/usr/bin/env wolframscript

Module[
  {root, runtime, adapterFile, libraryFile, adapter, labels, position,
   letterID, physical, seconds, resolved, ellipticPosition,
   ellipticLetterID, ellipticPhysical, ellipticSeconds,
   ellipticResolved, accepted, report, output, temporary},

  $HistoryLength = 0;
  root = DirectoryName[DirectoryName[DirectoryName[
    ExpandFileName[$InputFileName]]]];
  runtime = FileNameJoin[{root, "Runtime",
    "2026-08-31_cf303_native_dlog_residues"}];
  adapterFile = FileNameJoin[{runtime,
    "cf303_final45_hybrid_baseline_lazy_operator.wl"}];
  libraryFile = FileNameJoin[{root, "Diagnostics", "Scripts",
    "cf303_hybrid_baseline_lazy_circuit_adapter.wl"}];

  If[DownValues[FeynFacet`Private`masterTransportZeroQ] === {},
    Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
  If[DownValues[
      FeynFacet`Private`masterTransportCWNonzeroSparseQ] === {},
    Get[FileNameJoin[{root, "FeynFacet", "Private",
      "CanonicalWordTransport.wl"}]]];
  Get[libraryFile];
  adapter = Get[adapterFile];
  labels = Lookup[Lookup[adapter, "GOperator", <||>], "Letters", {}];
  position = FirstPosition[labels,
    {"CF303AcceptedIncomingKLeaf", 77, 0, 44, 2}];
  letterID = If[MissingQ[position], Missing["Letter"], First[position]];

  {seconds, resolved} = If[IntegerQ[letterID], AbsoluteTiming[
    cf303HybridBaselineResolvedPhysicalWordTerms[
      adapter, {letterID}, <||>, <||>, z]], {0., {}}];
  physical = If[IntegerQ[letterID],
    cf303HybridBaselinePhysicalWordCoefficient[
      adapter, {letterID}, 0, 0], $Failed];
  ellipticPosition = FirstPosition[labels,
    {"CF303AcceptedIncomingKLeaf", 79, 0, 44, 12}];
  ellipticLetterID = If[MissingQ[ellipticPosition],
    Missing["EllipticLetter"], First[ellipticPosition]];
  {ellipticSeconds, ellipticResolved} = If[IntegerQ[ellipticLetterID],
    AbsoluteTiming[cf303HybridBaselineResolvedPhysicalWordTerms[
      adapter, {ellipticLetterID}, <||>, <||>, z]], {0., {}}];
  ellipticPhysical = If[IntegerQ[ellipticLetterID],
    cf303HybridBaselinePhysicalWordCoefficient[
      adapter, {ellipticLetterID}, 0, 0], $Failed];
  accepted = Lookup[adapter, "Status", None] ===
      "CF303HybridBaselineLazyCircuitAdapterAcceptedV1" &&
    FileExistsQ[Lookup[adapter, "AcceptedIncomingLeafProviderFile", ""]] &&
    IntegerQ[letterID] && ListQ[resolved] && resolved =!= {} &&
    FreeQ[resolved, "CF303AcceptedIncomingKLeaf"] &&
    AllTrue[resolved, ListQ[#[[2]]] && #[[2]] =!= {} &&
      AllTrue[#[[2]], MatchQ[#,
        {"GPLPole", _} | {"E4Pole", _}] &] &] &&
    MatchQ[physical, {_SparseArray, _SparseArray}] &&
    (Dimensions /@ physical) === {{2, 293}, {2, 293}} &&
    cf303PathGaugePairNonzeroQ[physical] &&
    IntegerQ[ellipticLetterID] && ellipticResolved =!= {} &&
    FreeQ[ellipticResolved, "CF303AcceptedIncomingKLeaf"] &&
    MemberQ[Flatten[ellipticResolved[[All, 2]], 1][[All, 1]],
      "E4Pole"] &&
    MatchQ[ellipticPhysical, {_SparseArray, _SparseArray}] &&
    (Dimensions /@ ellipticPhysical) === {{2, 293}, {2, 293}} &&
    cf303PathGaugePairNonzeroQ[ellipticPhysical];
  report = <|
    "Status" -> If[accepted,
      "CF303HybridBaselineLazyOperatorValidatedV1",
      "CF303HybridBaselineLazyOperatorValidationFailedV1"],
    "Adapter" -> adapterFile,
    "SerializedReload" -> True,
    "BoundaryDimension" -> Length[Lookup[adapter, "BoundaryColumns", {}]],
    "AcceptedIncomingLetterID" -> letterID,
    "ResolvedTermCount" -> Length[resolved],
    "ResolvedLetterKinds" -> If[ListQ[resolved] && resolved =!= {},
      DeleteDuplicates[Flatten[resolved[[All, 2]], 1][[All, 1]]], {}],
    "ResolutionSeconds" -> seconds,
    "PhysicalCoefficientDimensions" -> If[ListQ[physical],
      Dimensions /@ physical, Missing["NotAvailable"]],
    "PhysicalCoefficientNonzero" -> If[ListQ[physical],
      cf303PathGaugePairNonzeroQ[physical], False],
    "EllipticIncomingLetterID" -> ellipticLetterID,
    "EllipticResolvedTermCount" -> Length[ellipticResolved],
    "EllipticResolvedLetterKinds" -> If[
      ListQ[ellipticResolved] && ellipticResolved =!= {},
      DeleteDuplicates[
        Flatten[ellipticResolved[[All, 2]], 1][[All, 1]]], {}],
    "EllipticResolutionSeconds" -> ellipticSeconds,
    "EllipticPhysicalCoefficientNonzero" -> If[
      ListQ[ellipticPhysical],
      cf303PathGaugePairNonzeroQ[ellipticPhysical], False],
    "Accepted" -> accepted
  |>;
  output = FileNameJoin[{runtime,
    "cf303_final45_hybrid_baseline_lazy_operator_validation.wl"}];
  temporary = output <> ".tmp-" <> ToString[$ProcessID];
  Put[report, temporary];
  RenameFile[temporary, output, OverwriteTarget -> True];
  Print[InputForm[report]];
  If[accepted, Null, $Failed]
]
