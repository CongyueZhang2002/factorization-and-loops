#!/usr/bin/env wolframscript

$HistoryLength = 0;

directory = DirectoryName[$InputFileName];
candidatePath = FileNameJoin[{directory,
    "CF254_9_6_raw_lifted_candidate.wl"}];
checkPath = FileNameJoin[{directory,
    "CF254_9_6_raw_lifted_exact_check.wl"}];
comparisonPath = FileNameJoin[{directory,
    "CF254_9_6_raw_residue_space_comparison.wl"}];
If[! AllTrue[{candidatePath, checkPath, comparisonPath}, FileExistsQ],
  Print["The lifted candidate, exact check, and residue-space comparison " <>
    "are required."];
  Exit[1]
];
candidate = Get[candidatePath];
check = Get[checkPath];
comparison = Get[comparisonPath];

certificateFields = {
  "Primes", "CombinedModulus", "SourceHashes", "NormalizationColumns",
  "GaugeDenominatorDegrees", "GaugeNumeratorDegrees", "ResidueRules",
  "ResidueMatrices", "Gauge"
};
If[! AssociationQ[candidate] || ! AssociationQ[check] ||
    ! AssociationQ[comparison] ||
    ! AllTrue[Append[certificateFields, "ExactPfaffianResidualsZero"],
      KeyExistsQ[candidate, #] &] ||
    ! AllTrue[Append[certificateFields, "AllResidualsZero"],
      KeyExistsQ[check, #] &],
  Print["The reconstruction artifacts do not contain a complete exact " <>
    "certificate."];
  Exit[1]
];
If[! TrueQ[candidate["RawResidues"]] ||
    ! TrueQ[candidate["ExactPfaffianResidualsZero"]] ||
    ! TrueQ[check["AllResidualsZero"]] ||
    ! TrueQ[check["ModularDenominatorsMonic"]] ||
    ! AllTrue[check["CoefficientLiftChecks"], TrueQ] ||
    ! And @@ Flatten[check["QuickChecksZero"]] ||
    ! TrueQ[comparison["ExactForcingAgreement"]],
  Print["The CF254 (9,6) candidate failed an exact reconstruction check."];
  Exit[1]
];
If[! AllTrue[certificateFields, SameQ[candidate[#], check[#]] &],
  Print["The lifted candidate and exact-check artifacts disagree."];
  Exit[1]
];

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl";
checkpointPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_strip_state.wl";
interpolationPaths = FileNameJoin[{directory,
      "CF254_9_6_raw_epsilon_interpolation_mod_" <> ToString[#] <> ".wl"}] & /@
    candidate["Primes"];
sourcePaths = Join[{recordPath, checkpointPath}, interpolationPaths];
If[! AllTrue[sourcePaths, FileExistsQ],
  Print["At least one certified source artifact is missing."];
  Exit[1]
];
currentSourceHashes = <|
  "RecordSHA256" -> FileHash[recordPath, "SHA256"],
  "InterpolationSHA256" -> AssociationThread[
    FileNameTake /@ interpolationPaths,
    FileHash[#, "SHA256"] & /@ interpolationPaths],
  "CheckpointSHA256" -> FileHash[checkpointPath, "SHA256"]
|>;
If[candidate["SourceHashes"] =!= currentSourceHashes,
  Print["A certified source artifact changed after reconstruction."];
  Exit[1]
];

gauge = candidate["Gauge"];
If[Dimensions[gauge] =!= {4, 1},
  Print["Unexpected gauge dimensions: ", Dimensions[gauge]];
  Exit[1]
];
checkpoint = Get[checkpointPath];
stripSolvers = Lookup[checkpoint, "StripSolvers", Missing["None"]];
If[! AssociationQ[checkpoint] ||
    Lookup[checkpoint, "Sector", Missing["None"]] =!= 9 ||
    Lookup[checkpoint, "SubSize", Missing["None"]] =!= 4 ||
    Lookup[checkpoint, "Truncation", Missing["None"]] =!= 18 ||
    Dimensions[Lookup[checkpoint, "PrevD", {}]] =!= {4, 6} ||
    ! ListQ[stripSolvers] || Length[stripSolvers] =!= 2 ||
    Lookup[stripSolvers, {"Sector", "LowerSector"}] =!=
      {{9, 8}, {9, 7}} ||
    ! AllTrue[Lookup[stripSolvers, "ExactDLog", False], TrueQ],
  Print["The sector checkpoint is not the certified (9,8),(9,7) state."];
  Exit[1]
];

newPrevD = MapThread[Join, {gauge, checkpoint["PrevD"]}];
newSolver = <|
  "Sector" -> 9,
  "LowerSector" -> 6,
  "Method" -> "RawResidueSimultaneousFiniteFieldPDE",
  "NumeratorDegree" -> candidate["GaugeNumeratorDegrees"],
  "DenominatorDegree" -> candidate["GaugeDenominatorDegrees"],
  "ExactDLog" -> True,
  "TwoVariableResidualZero" -> True,
  "ResidueCompatibilityAgreement" -> True,
  "AffineNullity" -> 4,
  "FiniteFieldPrimes" -> candidate["Primes"]
|>;
newCheckpoint = Join[checkpoint, <|
  "PrevD" -> newPrevD,
  "StripSolvers" -> Append[stripSolvers, newSolver]
|>];

backupPath = checkpointPath <> ".before_9_6";
If[FileExistsQ[backupPath],
  If[FileHash[backupPath, "SHA256"] =!= FileHash[checkpointPath, "SHA256"],
    Print["The existing backup differs from the current pre-install state."];
    Exit[1]
  ],
  CopyFile[checkpointPath, backupPath]
];
temporaryPath = checkpointPath <> ".tmp";
Put[newCheckpoint, temporaryPath];
RenameFile[temporaryPath, checkpointPath, OverwriteTarget -> True];
Print[<|
  "Checkpoint" -> checkpointPath,
  "GaugeDimensions" -> Dimensions[gauge],
  "CombinedPrevDDimensions" -> Dimensions[newPrevD],
  "ExactResidualsZero" -> True,
  "ResidueCompatibilityAgreement" -> True
|>];
Exit[0];
