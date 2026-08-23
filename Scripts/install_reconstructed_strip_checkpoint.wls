#!/usr/bin/env wolframscript

$HistoryLength = 0;

ClearAll[requiredEnvironment];
requiredEnvironment[name_String] := Module[{value = Environment[name]},
  If[! StringQ[value] || StringLength[value] === 0,
    Print["Missing environment variable: ", name];
    Exit[1]
  ];
  value
];

candidatePath = requiredEnvironment["FACET_CANDIDATE_PATH"];
checkPath = requiredEnvironment["FACET_CHECK_PATH"];
recordPath = requiredEnvironment["FACET_RECORD_PATH"];
checkpointPath = requiredEnvironment["FACET_CHECKPOINT_PATH"];
sector = ToExpression[requiredEnvironment["FACET_SECTOR"]];
lowerSector = ToExpression[requiredEnvironment["FACET_LOWER_SECTOR"]];
method = Replace[Environment["FACET_METHOD"],
  value_ /; ! StringQ[value] || StringLength[value] === 0 :>
    "SimultaneousFiniteFieldPDE"];

sourcePaths = {candidatePath, checkPath, recordPath, checkpointPath};
If[! AllTrue[sourcePaths, FileExistsQ],
  Print["At least one reconstruction source file is missing: ",
    Pick[sourcePaths, FileExistsQ /@ sourcePaths, False]];
  Exit[1]
];

candidate = Get[candidatePath];
check = Get[checkPath];
record = Get[recordPath];
checkpoint = Get[checkpointPath];

certificateFields = {
  "Primes", "CombinedModulus", "SourceHashes", "NormalizationColumns",
  "GaugeDenominatorDegrees", "GaugeNumeratorDegrees", "ResidueRules",
  "ResidueMatrices", "Gauge"
};
If[! And @@ (AssociationQ /@ {candidate, check, record, checkpoint}) ||
    ! AllTrue[certificateFields, KeyExistsQ[candidate, #] &] ||
    ! AllTrue[certificateFields, KeyExistsQ[check, #] &],
  Print["The reconstruction files do not contain the required exact data."];
  Exit[1]
];
If[! TrueQ[candidate["ExactPfaffianResidualsZero"]] ||
    ! TrueQ[check["AllResidualsZero"]] ||
    ! TrueQ[check["ModularDenominatorsMonic"]] ||
    ! AllTrue[check["CoefficientLiftChecks"], TrueQ] ||
    ! And @@ Flatten[check["QuickChecksZero"]] ||
    ! AllTrue[certificateFields, SameQ[candidate[#], check[#]] &],
  Print["The reconstructed strip failed an exact certificate check."];
  Exit[1]
];

sourceHashes = candidate["SourceHashes"];
interpolationHashes = Lookup[sourceHashes, "InterpolationSHA256", <||>];
interpolationDirectory = DirectoryName[candidatePath];
interpolationPaths = FileNameJoin[{interpolationDirectory, #}] & /@
  Keys[interpolationHashes];
If[! AllTrue[interpolationPaths, FileExistsQ],
  Print["At least one modular interpolation file is missing."];
  Exit[1]
];
currentHashes = <|
  "RecordSHA256" -> FileHash[recordPath, "SHA256"],
  "InterpolationSHA256" -> AssociationThread[
    FileNameTake /@ interpolationPaths,
    FileHash[#, "SHA256"] & /@ interpolationPaths],
  "CheckpointSHA256" -> FileHash[checkpointPath, "SHA256"]
|>;
If[sourceHashes =!= currentHashes,
  Print["A certified reconstruction source changed after the exact check."];
  Exit[1]
];

{e, c, bbar} = record["Strip"];
gauge = candidate["Gauge"];
expectedGaugeDimensions = Rest[Dimensions[bbar]];
prevD = Lookup[checkpoint, "PrevD", Missing["None"]];
stripSolvers = Lookup[checkpoint, "StripSolvers", Missing["None"]];
If[Lookup[checkpoint, "Sector", Missing["None"]] =!= sector ||
    Dimensions[gauge] =!= expectedGaugeDimensions ||
    ! MatrixQ[prevD] ||
    Dimensions[prevD][[1]] =!= First[expectedGaugeDimensions] ||
    ! ListQ[stripSolvers] ||
    MemberQ[Lookup[stripSolvers, "LowerSector", {}], lowerSector],
  Print["The strip dimensions or checkpoint state are inconsistent."];
  Exit[1]
];
previousLowerSectors = Lookup[stripSolvers, "LowerSector", {}];
If[previousLowerSectors =!= ReverseSort[previousLowerSectors] ||
    AnyTrue[previousLowerSectors, # <= lowerSector &],
  Print["The checkpoint does not precede this strip in descending order."];
  Exit[1]
];

newSolver = <|
  "Sector" -> sector,
  "LowerSector" -> lowerSector,
  "Method" -> method,
  "NumeratorDegree" -> candidate["GaugeNumeratorDegrees"],
  "DenominatorDegree" -> candidate["GaugeDenominatorDegrees"],
  "ExactDLog" -> True,
  "TwoVariableResidualZero" -> True,
  "AffineNullity" -> Length[candidate["NormalizationColumns"]],
  "FiniteFieldPrimes" -> candidate["Primes"]
|>;
newCheckpoint = Join[checkpoint, <|
  "PrevD" -> MapThread[Join, {gauge, prevD}],
  "StripSolvers" -> Append[stripSolvers, newSolver]
|>];

backupPath = checkpointPath <> ".before_" <> ToString[sector] <> "_" <>
  ToString[lowerSector];
If[FileExistsQ[backupPath],
  If[FileHash[backupPath, "SHA256"] =!= FileHash[checkpointPath, "SHA256"],
    Print["The existing strip backup differs from the current checkpoint."];
    Exit[1]
  ],
  CopyFile[checkpointPath, backupPath]
];
temporaryPath = checkpointPath <> ".tmp";
Put[newCheckpoint, temporaryPath];
RenameFile[temporaryPath, checkpointPath, OverwriteTarget -> True];

Print[<|
  "InstalledStrip" -> {sector, lowerSector},
  "GaugeDimensions" -> Dimensions[gauge],
  "CombinedPrevDDimensions" -> Dimensions[newCheckpoint["PrevD"]],
  "ExactPfaffianResidualsZero" -> True,
  "Checkpoint" -> checkpointPath
|>];
Exit[0];
