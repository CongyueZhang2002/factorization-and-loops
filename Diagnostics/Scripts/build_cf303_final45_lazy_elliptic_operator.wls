#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
requestedLayers = Environment["CF303_FINAL_SOURCE_LAYERS"];
If[! StringQ[requestedLayers] || requestedLayers === "",
  requestedLayers = "15_17"];
If[! MemberQ[{"15_17", "15_17_21"}, requestedLayers],
  Print["REFUSED: CF303_FINAL_SOURCE_LAYERS must be 15_17 or 15_17_21"];
  Exit[2]];
sourceFile = FileNameJoin[{runtime,
  "cf303_hybrid_elliptic_operator_" <> requestedLayers <> ".wl"}];
transferFile = FileNameJoin[{runtime,
  "cf303_block25_general_elliptic_transfer.wl"}];
libraryFile = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_final45_lazy_elliptic_operator_" <> requestedLayers <> ".wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[libraryFile];
sourceArtifact = Get[sourceFile];
transfer = Get[transferFile];
{buildSeconds, operator} = AbsoluteTiming[
  cf303BuildLazyFinalEllipticOperator[sourceArtifact, transfer,
    eps, z, {-2, 4}]];

boundaryProbe = cf303FinalEllipticWordCoefficient[operator, {}, 0, 0];
diagonalWord = {First[operator["DiagonalLetterIDs"]]};
diagonalProbe = cf303FinalEllipticWordCoefficient[
  operator, diagonalWord, 0, 1];
incomingKey = SelectFirst[Keys[operator["OffDiagonalResidues"]],
  -2 <= #[[1]] <= 2 &];
incomingWord = {incomingKey[[2]]};
incomingProbe = cf303FinalEllipticWordCoefficient[
  operator, incomingWord, 0, incomingKey[[1]]];
probeSummary = <|
  "Boundary" -> <|"Shape" -> Dimensions[boundaryProbe],
    "Nonzero" ->
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[boundaryProbe]|>,
  "Diagonal" -> <|"Word" -> diagonalWord,
    "Shape" -> Dimensions[diagonalProbe],
    "Nonzero" ->
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[diagonalProbe]|>,
  "Incoming" -> <|"Word" -> incomingWord,
    "EpsilonOrder" -> incomingKey[[1]],
    "Shape" -> Dimensions[incomingProbe],
    "Nonzero" ->
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[incomingProbe]|>
|>;
status = If[operator["Status"] ===
      "CF303Final45LazyEllipticOperatorAcceptedV1" &&
    AllTrue[Values[probeSummary], TrueQ[# ["Nonzero"]] &],
  "CF303Final45LazyEllipticArtifactAcceptedV1",
  "CF303Final45LazyEllipticArtifactFailedV1"];
artifact = <|
  "Status" -> status,
  "MasterCount" -> operator["N"],
  "SourceMasterCount" -> operator["SourceN"],
  "TargetRows" -> operator["TargetRows"],
  "BuildSeconds" -> buildSeconds,
  "Counts" -> <|
    "Letters" -> Length[operator["Letters"]],
    "SourceLetters" -> operator["SourceLetterCount"],
    "IncomingLetters" -> Length[operator["OffDiagonalLabels"]],
    "DiagonalGenerators" -> Length[operator["DiagonalLetterIDs"]],
    "IncomingResidueMatrices" ->
      Length[operator["OffDiagonalResidues"]],
    "IncomingResidueCoordinates" -> Total[
      Length[# ["NonzeroValues"]] & /@
        Values[operator["OffDiagonalResidues"]]],
    "BoundaryColumns" -> Length[operator["BoundaryColumns"]]
  |>,
  "Probes" -> probeSummary,
  "Operator" -> operator,
  "Library" -> libraryFile,
  "Source" -> sourceFile,
  "Transfer" -> transferFile
|>;
Put[artifact, outputFile];
Export[outputFile, StringReplace[ReadString[outputFile],
  RegularExpression["(?m)[ \\t]+$"] -> ""], "Text"];
Print[InputForm[KeyDrop[artifact, {"Operator"}]]];
Print["OUTPUT ", outputFile];
Exit[If[status === "CF303Final45LazyEllipticArtifactAcceptedV1", 0, 3]];
