#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300PAIRCOMMON FAIL usage=<project-root> <chart-strip.wxf> <preparation.wxf> <summary.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
chartStripFile = ExpandFileName[arguments[[2]]];
preparationFile = ExpandFileName[arguments[[3]]];
summaryFile = ExpandFileName[arguments[[4]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencies = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]
|>;
prime = 1000003;
epsilonValue = 1/21;
pointCount = 206;
randomSeed = 2540908;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[chartStripFile] ||
    ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[dependencies], FileExistsQ] || FileExistsQ[summaryFile],
  Print["CF300PAIRCOMMON FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];

chartStripHash = FileHash[chartStripFile, "SHA256", "HexString"];
preparationHash = FileHash[preparationFile, "SHA256", "HexString"];
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashes = Map[FileHash[#, "SHA256", "HexString"] &, dependencies];
If[System`Names["FeynFacet`SampleEpsFormStripAffine"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencies] =!= dependencyHashes,
  Print["CF300PAIRCOMMON FAIL package changed while loading"];
  Exit[95]];

writeAtomic[value_, file_] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  If[FileExistsQ[file], Return[$Failed]];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|
    "Status" -> status,
    "ChartStripFile" -> chartStripFile, "ChartStripSHA256" -> chartStripHash,
    "PreparationFile" -> preparationFile,
    "PreparationSHA256" -> preparationHash,
    "DriverFile" -> $InputFileName, "DriverSHA256" -> driverHash,
    "DependencyHashes" -> dependencyHashes,
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "PointCount" -> pointCount, "RandomSeed" -> randomSeed
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRCOMMON FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRCOMMON RESULT status=", status, " output=", summaryFile];
  Exit[code]
];

Print["CF300PAIRCOMMON stage=import time=", DateString["ISODateTime"]];
chartPayload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
preparationPayload = Quiet[Check[Import[preparationFile, "WXF"], $Failed]];
If[! AssociationQ[chartPayload] || ! AssociationQ[preparationPayload] ||
    Lookup[chartPayload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[preparationPayload, "Status", None] =!= "CF300PairChartPreparationV1" ||
    Lookup[preparationPayload, "ChartStripSHA256", None] =!= chartStripHash,
  finish["PayloadProvenanceMismatch", <||>, 66]];

preparation = preparationPayload["Preparation"];
record = <|
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "Variables" -> chartPayload["Variables"],
  "Regulator" -> chartPayload["Regulator"],
  "Strip" -> chartPayload["Strip"]
|>;
commonOptions = {
  "PointCount" -> pointCount,
  "RandomSeed" -> randomSeed,
  "NumeratorDegreeOffset" -> {0, 0},
  "SupportShell" -> 0,
  "SolveAffineSystem" -> False,
  "Backend" -> "Wolfram",
  "BackendThreads" -> 1,
  "PlanDiscoveryBackend" -> "Wolfram",
  "Preparation" -> preparation,
  "ExpectedFingerprint" -> preparation["Fingerprint"]
};

Print["CF300PAIRCOMMON stage=simplex time=", DateString["ISODateTime"]];
{simplexSeconds, simplex} = AbsoluteTiming[
  FeynFacet`SampleEpsFormStripAffine[record, epsilonValue, prime,
    Sequence @@ Join[commonOptions, {"Support" -> Automatic}]]];
Print["CF300PAIRCOMMON stage=rectangle time=", DateString["ISODateTime"]];
{rectangleSeconds, rectangle} = AbsoluteTiming[
  FeynFacet`SampleEpsFormStripAffine[record, epsilonValue, prime,
    Sequence @@ Join[commonOptions, {"Support" -> "Rectangle"}]]];

If[! AssociationQ[simplex] || ! AssociationQ[rectangle],
  finish["SamplingFailed", <|
    "SimplexAssociationQ" -> AssociationQ[simplex],
    "RectangleAssociationQ" -> AssociationQ[rectangle]|>, 2]];

samePoints = simplex["AcceptedPoints"] === rectangle["AcceptedPoints"];
simplexSupport = simplex["GaugeSupport"];
rectangleSupport = rectangle["GaugeSupport"];
simplexOnly = Complement[simplexSupport, rectangleSupport];
rectangleOnly = Complement[rectangleSupport, simplexSupport];
intersection = Intersection[simplexSupport, rectangleSupport];
acceptedPointHash = Hash[simplex["AcceptedPoints"], "SHA256", "HexString"];
certified = samePoints && Length[simplex["AcceptedPoints"]] === pointCount &&
  TrueQ[simplex["Consistent"]] && ! TrueQ[rectangle["Consistent"]] &&
  simplex["Rank"] === simplex["AugmentedRank"] &&
  rectangle["Rank"] < rectangle["AugmentedRank"] &&
  First[simplex["MatrixDimensions"]] === First[rectangle["MatrixDimensions"]];

If[! certified,
  finish["CommonRowCertificateFailed", <|
    "SameAcceptedPoints" -> samePoints,
    "SimplexConsistent" -> simplex["Consistent"],
    "RectangleConsistent" -> rectangle["Consistent"],
    "SimplexRanks" -> {simplex["Rank"], simplex["AugmentedRank"]},
    "RectangleRanks" -> {rectangle["Rank"], rectangle["AugmentedRank"]},
    "SimplexMatrixDimensions" -> simplex["MatrixDimensions"],
    "RectangleMatrixDimensions" -> rectangle["MatrixDimensions"]
  |>, 2]];

finish["CF300PairChartCommonRowsPassedV1", <|
  "SimplexSeconds" -> simplexSeconds,
  "RectangleSeconds" -> rectangleSeconds,
  "SameAcceptedPoints" -> True,
  "AcceptedPointCount" -> Length[simplex["AcceptedPoints"]],
  "AcceptedPointSHA256" -> acceptedPointHash,
  "SimplexConsistent" -> True,
  "SimplexRank" -> simplex["Rank"],
  "SimplexAugmentedRank" -> simplex["AugmentedRank"],
  "SimplexNullity" -> simplex["Nullity"],
  "SimplexMatrixDimensions" -> simplex["MatrixDimensions"],
  "RectangleConsistent" -> False,
  "RectangleRank" -> rectangle["Rank"],
  "RectangleAugmentedRank" -> rectangle["AugmentedRank"],
  "RectangleNullity" -> rectangle["Nullity"],
  "RectangleMatrixDimensions" -> rectangle["MatrixDimensions"],
  "SimplexSupportCount" -> Length[simplexSupport],
  "RectangleSupportCount" -> Length[rectangleSupport],
  "IntersectionSupportCount" -> Length[intersection],
  "SimplexOnlySupportCount" -> Length[simplexOnly],
  "RectangleOnlySupportCount" -> Length[rectangleOnly],
  "PackageUnmodifiedDuringCheck" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencies] === dependencyHashes)
|>, 0];
