#!/usr/bin/env wolframscript

(* Append the accepted CF259 (27,1) direct-multiquadratic gauge to a copy of
   the contiguous 26..2 checkpoint.  The source checkpoint is never changed. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["usage: cf259_append_block1_solution.wls " <>
    "SOURCE_CHECKPOINT SOLUTION OUTPUT_CHECKPOINT"];
  Exit[64]];
{sourceCheckpointFile, solutionFile, outputCheckpointFile} =
  ExpandFileName /@ arguments;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
lowerBlockSizes = {1, 1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 1,
  4, 4, 2, 4, 1, 2, 1, 3, 2, 1, 1};

putAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]];
checkpointQ[checkpoint_, lowest_Integer] := Module[
  {expectedWidth = Total[lowerBlockSizes[[lowest ;; 26]]]},
  AssociationQ[checkpoint] &&
    Lookup[checkpoint, "Family", None] === "CF259" &&
    Lookup[checkpoint, "Sector", None] === 27 &&
    Lookup[checkpoint, "SubSize", None] === 2 &&
    Lookup[checkpoint, "Truncation", None] === 47 &&
    Dimensions[Lookup[checkpoint, "PrevD", None]] === {2, expectedWidth} &&
    TrueQ[FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
      checkpoint["PrevD"], 2, lowerBlockSizes]] &&
    TrueQ[FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
      Lookup[checkpoint, "StripSolvers", None], checkpoint["PrevD"], 27,
      lowerBlockSizes]] &&
    Lookup[Lookup[checkpoint, "StripSolvers", {}], "LowerSector", None] ===
      Reverse[Range[lowest, 26]]];

If[sourceCheckpointFile === outputCheckpointFile,
  Print["source and output checkpoint must differ"]; Exit[2]];
If[! FileExistsQ[sourceCheckpointFile] || ! FileExistsQ[solutionFile],
  Print["source checkpoint or solution is missing"]; Exit[2]];
solution = Quiet[Check[Get[solutionFile], $Failed]];
If[! AssociationQ[solution] || Lookup[solution, "Status", None] =!= "Solved" ||
    Dimensions[Lookup[solution, "Gauge", None]] =!= {2, 1} ||
    ! TrueQ[FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[solution]],
  Print["block-1 solution fails the package installation contract"];
  Exit[3]];
summary = Join[<|"Sector" -> 27, "LowerSector" -> 1|>,
  KeyTake[solution, {"Method", "Primes", "ModularPrimeCount",
    "MaximumRegulatorDegree", "Alphabet", "RootIndices", "RootSquares",
    "SolutionContract", "Certificate", "Provider", "OneFormsCertified",
    "LettersEpsFree", "ResiduesKinematicsFree", "ResiduesEpsFree",
    "InstallationEvidence", "PhaseSeconds"}], <|"ExtraLetters" -> {}|>];
If[! TrueQ[FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[summary]],
  Print["block-1 summary fails the package installation contract"];
  Exit[4]];
checkpoint = Quiet[Check[Get[sourceCheckpointFile], $Failed]];
If[! TrueQ[checkpointQ[checkpoint, 2]],
  Print["source is not the accepted contiguous CF259 26..2 checkpoint"];
  Exit[5]];
updated = Join[checkpoint, <|
  "PrevD" -> MapThread[Join, {solution["Gauge"], checkpoint["PrevD"]}],
  "StripSolvers" -> Append[checkpoint["StripSolvers"], summary],
  "SolvedForms" -> <||>|>];
If[! TrueQ[checkpointQ[updated, 1]],
  Print["updated full CF259 row failed the mathematical validator"];
  Exit[6]];
putAtomic[updated, outputCheckpointFile];
Print[InputForm[<|"Status" -> "CF259RowTransportCompleteV1",
  "SolvedLowerSectors" -> Lookup[updated["StripSolvers"],
    "LowerSector", {}], "PrevDDimensions" -> Dimensions[updated["PrevD"]],
  "TransportReady" -> True, "Output" -> outputCheckpointFile|>]];
Exit[0];
