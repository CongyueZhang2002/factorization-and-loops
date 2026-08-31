#!/usr/bin/env wolframscript

(* Append the accepted source-frame CF259 (27,7) gauge to a strip checkpoint.
   SolvedForms is disposable telemetry and is cleared: the production driver
   reconstructs the mathematical row from PrevD and the current connection. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["usage: cf259_append_block7_source_solution.wls " <>
    "SOURCE_CHECKPOINT SOURCE_SOLUTION OUTPUT_CHECKPOINT"];
  Exit[64]];
{sourceCheckpointFile, solutionFile, outputCheckpointFile} =
  ExpandFileName /@ arguments;

repo = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];

lowerBlockSizes = {1, 1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 1,
  4, 4, 2, 4, 1, 2, 1, 3, 2, 1, 1};
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = Symbol["Global`eps"];

putAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]];

residuesEpsFree[solution_Association] := Which[
  BooleanQ[Lookup[solution, "ResiduesEpsFree", Missing[]]],
    solution["ResiduesEpsFree"],
  AssociationQ[Lookup[solution, "InnerSolution", None]] &&
      BooleanQ[Lookup[solution["InnerSolution"], "ResiduesEpsFree",
        Missing[]]],
    solution["InnerSolution", "ResiduesEpsFree"],
  True, Missing["ResidueEpsilonDependenceNotReported"]];

solverSummary[solution_Association] := Join[
  <|"Sector" -> 27, "LowerSector" -> 7|>,
  KeyTake[solution, {"Method", "NumeratorDegree", "DenominatorDegree",
    "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "Primes",
    "ModularPrimeCount", "SelectedNumeratorDegreeOffset",
    "BackendRequested", "BackendThreads", "BackendsUsed",
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads", "EliminationPlanFingerprint",
    "PrimeSamplingSeconds", "PrimeInterpolationSeconds",
    "TotalSamplingSeconds", "TotalInterpolationSeconds", "LiftingSeconds",
    "ExactCheckSeconds", "FirstVariable", "MapleSeconds",
    "ResiduePreparationSeconds", "ResidueKernels",
    "LetterDenominatorPower", "NumeratorDegreeOffset", "ExactDLog",
    "ODEEquationZero", "TransformedDLogZero", "Alphabet", "RootIndices",
    "FrameCertificate", "SolutionContract", "Certificate", "Provider",
    "ProviderFingerprint", "LayoutFingerprint", "CoefficientABIFingerprint",
    "ReconstructedVectorFingerprint", "OneFormsCertified", "LettersEpsFree",
    "ResiduesKinematicsFree", "InstallationEvidence", "PhaseSeconds"}],
  <|"ResiduesEpsFree" -> residuesEpsFree[solution], "ExtraLetters" -> {}|>];

checkpointQ[checkpoint_, expectedLowest_Integer] := Module[
  {expectedWidth = Total[lowerBlockSizes[[expectedLowest ;; 26]]]},
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
      Reverse[Range[expectedLowest, 26]]
];

If[sourceCheckpointFile === outputCheckpointFile,
  Print["source and output checkpoint must differ"]; Exit[2]];
If[! FileExistsQ[sourceCheckpointFile] || ! FileExistsQ[solutionFile],
  Print["source checkpoint or source solution is missing"]; Exit[2]];

solution = Quiet[Check[Get[solutionFile], $Failed]];
If[! AssociationQ[solution] || Lookup[solution, "Status", None] =!= "Solved" ||
    Dimensions[Lookup[solution, "Gauge", None]] =!= {2, 2},
  Print["source solution has the wrong status or gauge shape"]; Exit[3]];
summary = solverSummary[solution];
If[! TrueQ[FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[summary]],
  Print["source solution summary fails package acceptance: ",
    InputForm[KeyTake[summary, {"Method", "Certificate",
      "FrameCertificate"}]]]; Exit[4]];

If[FileExistsQ[outputCheckpointFile],
  existing = Quiet[Check[Get[outputCheckpointFile], $Failed]];
  If[TrueQ[checkpointQ[existing, 7]] &&
      Last[existing["StripSolvers"]] === summary,
    Print["CF259 block 7 is already present; output checkpoint valid"];
    Exit[0],
    Print["existing output checkpoint is not the requested append result"];
    Exit[5]]];

checkpoint = Quiet[Check[Get[sourceCheckpointFile], $Failed]];
If[! TrueQ[checkpointQ[checkpoint, 8]],
  Print["source checkpoint is not the accepted contiguous 26..8 prefix"];
  Exit[6]];

updated = Join[checkpoint, <|
  "PrevD" -> MapThread[Join, {solution["Gauge"], checkpoint["PrevD"]}],
  "StripSolvers" -> Append[checkpoint["StripSolvers"], summary],
  "SolvedForms" -> <||>|>];
If[! TrueQ[checkpointQ[updated, 7]],
  Print["updated checkpoint failed the package mathematical validator"];
  Exit[7]];
putAtomic[updated, outputCheckpointFile];
Print["appended CF259 (27,7); solved prefix 26..7; PrevD ",
  Dimensions[updated["PrevD"]], "; wrote ", outputCheckpointFile];
