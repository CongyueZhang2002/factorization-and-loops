#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 6,
  Print["CF300PAIRDEGREE FAIL usage=<project-root> <chart-strip.wxf> <preparation.wxf> <support:simplex|rectangle> <epsilon-rational> <summary.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
chartStripFile = ExpandFileName[arguments[[2]]];
preparationFile = ExpandFileName[arguments[[3]]];
supportLabel = arguments[[4]];
epsilonText = arguments[[5]];
summaryFile = ExpandFileName[arguments[[6]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencies = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]
|>;
parseRational[text_String] := Module[{held, value},
  If[! StringMatchQ[text, RegularExpression["-?[0-9]+(?:/[1-9][0-9]*)?"]], Return[$Failed]];
  held = Quiet[Check[ToExpression[text, InputForm, HoldComplete], $Failed]];
  If[held === $Failed, Return[$Failed]];
  value = ReleaseHold[held];
  If[MatchQ[value, _Integer | _Rational], value, $Failed]
];
epsilonValue = parseRational[epsilonText];
supportKind = Switch[supportLabel,
  "simplex", Automatic,
  "rectangle", "Rectangle",
  _, $Failed];
If[! DirectoryQ[projectRoot] || ! FileExistsQ[chartStripFile] ||
    ! FileExistsQ[preparationFile] || ! AllTrue[Values[dependencies], FileExistsQ] ||
    supportKind === $Failed || epsilonValue === $Failed || FileExistsQ[summaryFile],
  Print["CF300PAIRDEGREE FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];

chartStripHash = FileHash[chartStripFile, "SHA256", "HexString"];
preparationHash = FileHash[preparationFile, "SHA256", "HexString"];
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashes = Map[FileHash[#, "SHA256", "HexString"] &, dependencies];
If[System`Names["FeynFacet`SampleEpsFormStripAffine"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencies] =!= dependencyHashes,
  Print["CF300PAIRDEGREE FAIL package changed while loading"];
  Exit[95]];

writeAtomic[value_, file_] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|
    "Status" -> status,
    "ChartStripFile" -> chartStripFile, "ChartStripSHA256" -> chartStripHash,
    "PreparationFile" -> preparationFile, "PreparationSHA256" -> preparationHash,
    "DriverFile" -> $InputFileName, "DriverSHA256" -> driverHash,
    "DependencyHashes" -> dependencyHashes,
    "SupportLabel" -> supportLabel, "EpsilonValue" -> epsilonValue,
    "Prime" -> 1000003
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRDEGREE FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRDEGREE RESULT status=", status,
    " support=", supportLabel, " output=", summaryFile];
  Exit[code]
];

Print["CF300PAIRDEGREE stage=import support=", supportLabel,
  " time=", DateString["ISODateTime"]];
chartPayload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
preparationPayload = Quiet[Check[Import[preparationFile, "WXF"], $Failed]];
If[! AssociationQ[chartPayload] || ! AssociationQ[preparationPayload] ||
    Lookup[chartPayload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[preparationPayload, "Status", None] =!= "CF300PairChartPreparationV1" ||
    Lookup[preparationPayload, "ChartStripSHA256", None] =!= chartStripHash ||
    FileHash[chartStripFile, "SHA256", "HexString"] =!= chartStripHash ||
    FileHash[preparationFile, "SHA256", "HexString"] =!= preparationHash,
  finish["PayloadProvenanceMismatch", <||>, 66]];
preparation = preparationPayload["Preparation"];
record = <|
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "Variables" -> chartPayload["Variables"],
  "Regulator" -> chartPayload["Regulator"],
  "Strip" -> chartPayload["Strip"]
|>;

Print["CF300PAIRDEGREE stage=rank-start support=", supportLabel,
  " epsilon=", epsilonValue, " time=", DateString["ISODateTime"]];
{wallSeconds, probe} = AbsoluteTiming[
  FeynFacet`SampleEpsFormStripAffine[
    record, epsilonValue, 1000003,
    "NumeratorDegreeOffset" -> {0, 0},
    "Support" -> supportKind,
    "SupportShell" -> 0,
    "SolveAffineSystem" -> False,
    "Backend" -> "Wolfram",
    "BackendThreads" -> 1,
    "PlanDiscoveryBackend" -> "Wolfram",
    "Preparation" -> preparation,
    "ExpectedFingerprint" -> preparation["Fingerprint"]]];
Print["CF300PAIRDEGREE stage=rank-finished support=", supportLabel,
  " seconds=", wallSeconds,
  " consistent=", If[AssociationQ[probe], Lookup[probe, "Consistent", None], None]];
If[! AssociationQ[probe],
  finish["DegreeProbeFailed", <|"WallSeconds" -> wallSeconds, "Probe" -> probe|>, 2]];

finish["CF300PairChartDegreeProbeCompletedV1", <|
  "WallSeconds" -> wallSeconds,
  "Consistent" -> probe["Consistent"],
  "Rank" -> probe["Rank"], "AugmentedRank" -> probe["AugmentedRank"],
  "Nullity" -> probe["Nullity"],
  "MatrixDimensions" -> probe["MatrixDimensions"],
  "NonzeroEntries" -> probe["NonzeroEntries"],
  "GaugeNumeratorDegrees" -> probe["GaugeNumeratorDegrees"],
  "GaugeDenominatorDegrees" -> probe["GaugeDenominatorDegrees"],
  "GaugeSupportCount" -> probe["GaugeSupportCount"],
  "SupportMaximumDegrees" -> probe["SupportMaximumDegrees"],
  "GaugeUnknownCount" -> probe["GaugeUnknownCount"],
  "FreeResidueCount" -> probe["FreeResidueCount"],
  "AcceptedPointCount" -> Length[probe["AcceptedPoints"]],
  "AttemptCount" -> probe["AttemptCount"],
  "SetupSeconds" -> probe["SetupSeconds"],
  "PreprocessingSeconds" -> probe["PreprocessingSeconds"],
  "SamplingSeconds" -> probe["SamplingSeconds"],
  "RankSeconds" -> probe["RankSeconds"],
  "AugmentedRankSeconds" -> probe["AugmentedRankSeconds"],
  "PeakMemoryBytes" -> probe["PeakMemoryBytes"],
  "PreparationReused" -> probe["PreparationReused"],
  "PackageUnmodified" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencies] === dependencyHashes)
|>, 0];
