#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300PAIRPREP FAIL usage=<project-root> <chart-strip.wxf> <summary.wl> <preparation.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
chartStripFile = ExpandFileName[arguments[[2]]];
summaryFile = ExpandFileName[arguments[[3]]];
preparationFile = ExpandFileName[arguments[[4]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencies = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]
|>;
If[! DirectoryQ[projectRoot] || ! FileExistsQ[chartStripFile] ||
    ! AllTrue[Values[dependencies], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[preparationFile],
  Print["CF300PAIRPREP FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[preparationFile]],
  CreateDirectory[DirectoryName[preparationFile], CreateIntermediateDirectories -> True]];

chartStripHash = FileHash[chartStripFile, "SHA256", "HexString"];
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashes = Map[FileHash[#, "SHA256", "HexString"] &, dependencies];
If[System`Names["FeynFacet`PrepareEpsFormStripSampling"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencies] =!= dependencyHashes,
  Print["CF300PAIRPREP FAIL package changed while loading"];
  Exit[95]];

writeAtomic[value_, file_, format_: "WL"] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  If[FileExistsQ[file], Return[$Failed]];
  written = Quiet[Check[
    If[format === "WXF", Export[temporary, value, "WXF"], Put[value, temporary]],
    $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|
    "Status" -> status,
    "ChartStripFile" -> chartStripFile,
    "ChartStripSHA256" -> chartStripHash,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHash,
    "DependencyHashes" -> dependencyHashes,
    "PreparationFile" -> preparationFile
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRPREP FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRPREP RESULT status=", status, " output=", summaryFile];
  Exit[code]
];

Print["CF300PAIRPREP stage=import time=", DateString["ISODateTime"]];
payload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
If[! AssociationQ[payload] ||
    Lookup[payload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    FileHash[chartStripFile, "SHA256", "HexString"] =!= chartStripHash,
  finish["InvalidChartStripPayload", <||>, 66]];
record = <|
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "Variables" -> payload["Variables"],
  "Regulator" -> payload["Regulator"],
  "Strip" -> payload["Strip"]
|>;

Print["CF300PAIRPREP stage=prepare-start time=", DateString["ISODateTime"],
  " stripLeafCount=", LeafCount[record["Strip"]]];
{wallSeconds, preparation} = AbsoluteTiming[
  FeynFacet`PrepareEpsFormStripSampling[record]];
Print["CF300PAIRPREP stage=prepare-finished seconds=", wallSeconds,
  " status=", If[AssociationQ[preparation], "Association", Head[preparation]]];
If[! AssociationQ[preparation] ||
    ! And @@ (KeyExistsQ[preparation, #] & /@ {
      "Alphabet", "GaugeDenominator", "DenominatorDegrees",
      "SupportCensus", "SymbolicForms", "ResidueTriples"}),
  finish["PreparationFailed", <|"WallSeconds" -> wallSeconds|>, 2]];

If[writeAtomic[<|
    "Status" -> "CF300PairChartPreparationV1",
    "ChartStripFile" -> chartStripFile,
    "ChartStripSHA256" -> chartStripHash,
    "Preparation" -> preparation
  |>, preparationFile, "WXF"] === $Failed,
  finish["PreparationWriteFailed", <|"WallSeconds" -> wallSeconds|>, 97]];

alphabet = preparation["Alphabet"];
variables = preparation["Variables"];
epsilon = preparation["Regulator"];
alphabetDegrees = Table[
  With[{expression = Together[letter]}, <|
    "Numerator" -> (Exponent[Numerator[expression], #] & /@ variables),
    "Denominator" -> (Exponent[Denominator[expression], #] & /@ variables),
    "LeafCount" -> LeafCount[expression]|>],
  {letter, alphabet}];
finish["CF300PairChartPreparationPassedV1", <|
  "WallSeconds" -> wallSeconds,
  "ReportedPrepareSeconds" -> preparation["PrepareSeconds"],
  "PreparationSHA256" -> FileHash[preparationFile, "SHA256", "HexString"],
  "PreparationBytes" -> FileByteCount[preparationFile],
  "PreparationByteCountInKernel" -> ByteCount[preparation],
  "SymbolicFormsByteCount" -> ByteCount[preparation["SymbolicForms"]],
  "Dimensions" -> preparation["Dimensions"],
  "AlphabetLength" -> Length[alphabet],
  "AlphabetMaximumNumeratorDegrees" -> If[alphabetDegrees === {}, {0, 0},
    Max /@ Transpose[Lookup[alphabetDegrees, "Numerator"]]],
  "AlphabetMaximumDenominatorDegrees" -> If[alphabetDegrees === {}, {0, 0},
    Max /@ Transpose[Lookup[alphabetDegrees, "Denominator"]]],
  "MaximumAlphabetLeafCount" -> If[alphabetDegrees === {}, 0,
    Max[Lookup[alphabetDegrees, "LeafCount"]]],
  "FreeResidueCount" -> Length[preparation["ResidueTriples"]],
  "GaugeDenominatorDegrees" -> preparation["DenominatorDegrees"],
  "GaugeDenominatorLeafCount" -> LeafCount[preparation["GaugeDenominator"]],
  "GaugeDenominator" -> Factor[preparation["GaugeDenominator"]],
  "SupportCensus" -> preparation["SupportCensus"],
  "PackageUnmodified" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencies] === dependencyHashes)
|>, 0];
