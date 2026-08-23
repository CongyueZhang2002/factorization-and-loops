directory = DirectoryName[$InputFileName];
candidatePath = FileNameJoin[{directory,
    "CF254_9_7_lifted_candidate.wl"}];
checkPath = FileNameJoin[{directory,
    "CF254_9_7_lifted_exact_check.wl"}];
If[! FileExistsQ[candidatePath] || ! FileExistsQ[checkPath],
  Print["The lifted candidate and exact-check artifacts are both required."];
  Exit[1]
];
candidate = Get[candidatePath];
check = Get[checkPath];

certificateFields = {
  "Primes", "CombinedModulus", "SourceHashes", "NormalizationColumns",
  "GaugeDenominatorDegrees", "GaugeNumeratorDegrees", "ResidueRules",
  "Gauge"
};
If[! AssociationQ[candidate] || ! AssociationQ[check] ||
    ! AllTrue[Append[certificateFields, "ExactPfaffianResidualsZero"],
      KeyExistsQ[candidate, #] &] ||
    ! AllTrue[Append[certificateFields, "AllResidualsZero"],
      KeyExistsQ[check, #] &],
  Print["The lifted artifacts do not contain a complete exact certificate."];
  Exit[1]
];

If[! TrueQ[check["AllResidualsZero"]] ||
    ! TrueQ[candidate["ExactPfaffianResidualsZero"]] ||
    ! TrueQ[check["ModularDenominatorsMonic"]] ||
    ! AllTrue[check["CoefficientLiftChecks"], TrueQ] ||
    ! And @@ Flatten[check["QuickChecksZero"]],
  Print["The CF254 (9,7) gauge has no complete exact certificate."];
  Exit[1]
];
If[! AllTrue[certificateFields,
    SameQ[candidate[#], check[#]] &],
  Print["The lifted candidate and exact-check artifacts disagree."];
  Exit[1]
];

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_7_input.wl";
residuePath = FileNameJoin[{directory, "CF254_9_7_residue_data.wl"}];
checkpointPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_strip_state.wl";
interpolationPaths = FileNameJoin[{directory,
      "CF254_9_7_epsilon_interpolation_mod_" <> ToString[#] <> ".wl"}] & /@
    candidate["Primes"];
sourcePaths = Join[{recordPath, residuePath, checkpointPath},
  interpolationPaths];
If[! AllTrue[sourcePaths, FileExistsQ],
  Print["At least one source artifact named by the certificate is missing."];
  Exit[1]
];
currentSourceHashes = <|
  "RecordSHA256" -> FileHash[recordPath, "SHA256"],
  "ResidueSHA256" -> FileHash[residuePath, "SHA256"],
  "CheckpointSHA256" -> FileHash[checkpointPath, "SHA256"],
  "InterpolationSHA256" -> AssociationThread[
    FileNameTake /@ interpolationPaths,
    FileHash[#, "SHA256"] & /@ interpolationPaths
  ]
|>;
If[candidate["SourceHashes"] =!= currentSourceHashes,
  Print["A source artifact changed after the exact certificate was written."];
  Exit[1]
];

gauge = candidate["Gauge"];
If[Dimensions[gauge] =!= {4, 4},
  Print["Unexpected gauge dimensions: ", Dimensions[gauge]];
  Exit[1]
];

checkpoint = Get[checkpointPath];
If[! AssociationQ[checkpoint] ||
    Lookup[checkpoint, "Sector", Missing["None"]] =!= 9 ||
    Lookup[checkpoint, "SubSize", Missing["None"]] =!= 4 ||
    Lookup[checkpoint, "Truncation", Missing["None"]] =!= 18 ||
    Dimensions[Lookup[checkpoint, "PrevD", {}]] =!= {4, 2},
  Print["The existing sector-9 checkpoint is not the certified (9,8) state."];
  Exit[1]
];
stripSolvers = Lookup[checkpoint, "StripSolvers", Missing["None"]];
If[! ListQ[stripSolvers] || Length[stripSolvers] =!= 1,
  Print["The existing checkpoint must contain exactly the (9,8) strip."];
  Exit[1]
];
previousSolver = First[stripSolvers];
previousPrimes = Lookup[previousSolver, "FiniteFieldPrimes", Missing["None"]];
If[! AssociationQ[previousSolver] ||
    Lookup[previousSolver, "Sector", Missing["None"]] =!= 9 ||
    Lookup[previousSolver, "LowerSector", Missing["None"]] =!= 8 ||
    ! TrueQ[Lookup[previousSolver, "ExactDLog", False]] ||
    ! TrueQ[Lookup[previousSolver, "TwoVariableResidualZero", False]] ||
    ! ListQ[previousPrimes] || ! AllTrue[previousPrimes, PrimeQ],
  Print["The existing (9,8) strip lacks its exact certificate."];
  Exit[1]
];

newPrevD = MapThread[Join, {gauge, checkpoint["PrevD"]}];
numeratorDegrees = {
  Max[Exponent[Numerator[Together[#]], x] & /@ Flatten[gauge]],
  Max[Exponent[Numerator[Together[#]], y] & /@ Flatten[gauge]]
};
denominatorDegrees = {
  Max[Exponent[Denominator[Together[#]], x] & /@ Flatten[gauge]],
  Max[Exponent[Denominator[Together[#]], y] & /@ Flatten[gauge]]
};

newCheckpoint = Join[checkpoint, <|
  "PrevD" -> newPrevD,
  "StripSolvers" -> Append[checkpoint["StripSolvers"], <|
    "Sector" -> 9,
    "LowerSector" -> 7,
    "Method" -> "SimultaneousFiniteFieldAffinePDE",
    "NumeratorDegree" -> numeratorDegrees,
    "DenominatorDegree" -> denominatorDegrees,
    "ExactDLog" -> True,
    "TwoVariableResidualZero" -> True,
    "FiniteFieldPrimes" -> candidate["Primes"]
  |>]
|>];

backupPath = checkpointPath <> ".before_9_7";
If[FileExistsQ[backupPath],
  If[FileHash[backupPath, "SHA256"] =!=
      FileHash[checkpointPath, "SHA256"],
    Print["The existing backup is not the current pre-install checkpoint."];
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
  "ExactResidualsZero" -> True
|>];
