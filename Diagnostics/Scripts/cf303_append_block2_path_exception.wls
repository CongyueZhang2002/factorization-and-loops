#!/usr/bin/env wolframscript

(* Scratch-only, idempotent append of the accepted CF303 (25,2) fixed-path
   provider.  The source checkpoint and package repository are never changed. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["usage: cf303_append_block2_path_exception.wls " <>
    "SOURCE_CHECKPOINT RECORD OUTPUT_CHECKPOINT"];
  Exit[64]];
{sourceCheckpointFile, recordFile, outputCheckpointFile} =
  ExpandFileName /@ arguments;

utility =
  "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/" <>
    "exact_path_transport_exception.wl";
Get[utility];

lowerBlockSizes = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 4, 4, 2, 3, 2,
  1, 2, 4, 2, 2, 1, 2, 2};

putAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]];

exceptionRecordQ[record_] := Module[{artifact},
  If[! TrueQ[
      CodexDiagnostics`ExactPathTransportException`ExactPathTransportExceptionRecordQ[
        record]], Return[False]];
  artifact =
    CodexDiagnostics`ExactPathTransportException`LoadExactPathTransportExceptionArtifact[
      record];
  AssociationQ[artifact] &&
    Lookup[artifact, "Status", None] === "CF303Block2ExactStructuredPathV1" &&
    Lookup[artifact, "Acceptance", None] === "ExactPathForcingAccepted" &&
    Lookup[artifact, "PathExtension", None] === <|"Type" -> "None"|> &&
    Dimensions[Lookup[artifact, "PathForcing", None]] === {2, 1} &&
    Lookup[record, "Family", None] === "CF303" &&
    Lookup[record, "Sector", None] === 25 &&
    Lookup[record, "HardSector", None] === 25 &&
    Lookup[record, "LowerSector", None] === 2 &&
    Lookup[record, "Dimensions", None] === {2, 2, 1} &&
    Lookup[record, "RowRange", None] === {44, 45} &&
    Lookup[record, "ColumnRange", None] === {2} &&
    Lookup[record, "RowBlockBasis", None] === {5, 6} &&
    Lookup[record, "ColumnBlockBasis", None] === {39} &&
    Lookup[record, "Acceptance", None] === "ExactPathForcingAccepted"
];

existingExceptionQ[record_] := AssociationQ[record] &&
  Lookup[record, "Gauge", None] === "LiteralZero" &&
  Lookup[record, "Installed", True] === False &&
  Lookup[record, "ExactDLog", True] === False &&
  Switch[Lookup[record, "LowerSector", None],
    18, Lookup[record, "Method", None] === "TransportException" ||
      TrueQ[CodexDiagnostics`ExactPathTransportException`ExactPathTransportExceptionRecordQ[
        record]],
    14, (Lookup[record, "Status", None] ===
          "DeferredBundleTransportExceptionReadyV1" &&
        Lookup[record, "Method", None] ===
          "DeferredBundleTransportException" &&
        StringQ[Lookup[record, "InputFile", None]] &&
        FileExistsQ[Lookup[record, "InputFile", ""]] &&
        Lookup[record, "Dimensions", None] === {2, 2, 2}) ||
      TrueQ[CodexDiagnostics`ExactPathTransportException`ExactPathTransportExceptionRecordQ[
        record]],
    11,
      TrueQ[CodexDiagnostics`ExactPathTransportException`ExactPathTransportExceptionRecordQ[
        record]],
    2, exceptionRecordQ[record],
    _, False];

zeroExceptionColumnsQ[checkpoint_Association, lowest_Integer] := Module[
  {prevD, exceptions, sector, zeroStart, zeroWidth},
  prevD = Lookup[checkpoint, "PrevD", None];
  exceptions = Lookup[checkpoint, "TransportExceptions", {}];
  AllTrue[exceptions, Function[exception,
    sector = Lookup[exception, "LowerSector", None];
    If[! IntegerQ[sector] || sector < lowest, Return[False]];
    zeroStart = 1 + If[sector === lowest, 0,
      Total[lowerBlockSizes[[lowest ;; sector - 1]]]];
    zeroWidth = lowerBlockSizes[[sector]];
    And @@ Flatten[Map[TrueQ[# === 0] &,
      prevD[[All, zeroStart ;; zeroStart + zeroWidth - 1]], {2}]]]]
];

checkpointQ[checkpoint_, lowest_Integer, expectedExceptions_List] := Module[
  {solvers, exceptions, prevD, solvedForms, expectedWidth},
  If[! AssociationQ[checkpoint] ||
      Lookup[checkpoint, "Family", None] =!= "CF303" ||
      Lookup[checkpoint, "Sector", None] =!= 25 ||
      Lookup[checkpoint, "SubSize", None] =!= 2,
    Return[False]];
  solvers = Lookup[checkpoint, "StripSolvers", None];
  exceptions = Lookup[checkpoint, "TransportExceptions", None];
  prevD = Lookup[checkpoint, "PrevD", None];
  solvedForms = Lookup[checkpoint, "SolvedForms", <||>];
  expectedWidth = Total[lowerBlockSizes[[lowest ;; 24]]];
  ListQ[solvers] && AllTrue[solvers, AssociationQ] &&
    Lookup[solvers, "LowerSector", None] === Reverse[Range[lowest, 24]] &&
    ListQ[exceptions] && AllTrue[exceptions, existingExceptionQ] &&
    Lookup[exceptions, "LowerSector", None] === expectedExceptions &&
    AssociationQ[solvedForms] &&
    AllTrue[expectedExceptions, ! KeyExistsQ[solvedForms, #] &] &&
    Dimensions[prevD] === {2, expectedWidth} &&
    TrueQ[zeroExceptionColumnsQ[checkpoint, lowest]]
];

If[sourceCheckpointFile === outputCheckpointFile,
  Print["source and output checkpoint must be different files"];
  Exit[2]];
If[! FileExistsQ[sourceCheckpointFile] || ! FileExistsQ[recordFile],
  Print["missing source checkpoint or record"];
  Exit[2]];

record = Quiet[Check[Get[recordFile], $Failed]];
If[! exceptionRecordQ[record],
  Print["block-2 path record or artifact failed the exact-path contract"];
  Exit[3]];

If[FileExistsQ[outputCheckpointFile],
  existing = Quiet[Check[Get[outputCheckpointFile], $Failed]];
  If[TrueQ[checkpointQ[existing, 2, {18, 14, 11, 2}]] &&
      Last[existing["StripSolvers"]] === record &&
      Last[existing["TransportExceptions"]] === record,
    Print["block-2 path exception already present; output checkpoint valid"];
    Exit[0],
    Print["existing output checkpoint is not the requested idempotent result"];
    Exit[4]]];

checkpoint = Quiet[Check[Get[sourceCheckpointFile], $Failed]];
If[! TrueQ[checkpointQ[checkpoint, 3, {18, 14, 11}]],
  Print["source checkpoint is not the accepted contiguous 24..3 prefix: ",
    InputForm[<|
      "Family" -> Lookup[checkpoint, "Family", None],
      "Sector" -> Lookup[checkpoint, "Sector", None],
      "SubSize" -> Lookup[checkpoint, "SubSize", None],
      "LowerSectors" -> Lookup[Lookup[checkpoint, "StripSolvers", {}],
        "LowerSector", None],
      "Exceptions" -> Lookup[Lookup[checkpoint, "TransportExceptions", {}],
        "LowerSector", None],
      "ExceptionValidity" -> (existingExceptionQ /@
        Lookup[checkpoint, "TransportExceptions", {}]),
      "PrevDDimensions" -> Dimensions[Lookup[checkpoint, "PrevD", None]],
      "ExpectedWidth" -> Total[lowerBlockSizes[[3 ;; 24]]],
      "ZeroExceptionColumns" -> Quiet[Check[
        zeroExceptionColumnsQ[checkpoint, 3], $Failed]],
      "SolvedFormExceptionKeys" -> (KeyExistsQ[
          Lookup[checkpoint, "SolvedForms", <||>], #] & /@ {18, 14, 11})
    |>]];
  Exit[5]];
If[StringQ[Lookup[record, "SourceCheckpointSHA256", None]] &&
    FileHash[sourceCheckpointFile, "SHA256", "HexString"] =!=
      record["SourceCheckpointSHA256"],
  Print["source checkpoint hash changed since the record was derived"];
  Exit[6]];

updated = Join[checkpoint, <|
  "PrevD" -> Join[ConstantArray[0, {2, 1}], checkpoint["PrevD"], 2],
  "StripSolvers" -> Append[checkpoint["StripSolvers"], record],
  "SolvedForms" -> KeyDrop[Lookup[checkpoint, "SolvedForms", <||>], 2],
  "TransportExceptions" ->
    Append[checkpoint["TransportExceptions"], record]|>];

If[! TrueQ[checkpointQ[updated, 2, {18, 14, 11, 2}]],
  Print["updated checkpoint failed the contiguous scratch validator"];
  Exit[7]];
putAtomic[updated, outputCheckpointFile];
Print["appended exact block-2 path provider; solved prefix 24..2; wrote ",
  outputCheckpointFile];
