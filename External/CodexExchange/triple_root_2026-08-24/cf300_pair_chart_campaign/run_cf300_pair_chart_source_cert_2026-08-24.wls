#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 6,
  Print["CF300PAIRCERT FAIL usage=<project-root> <input.wl> <chart-strip.wxf> <solution.wxf> <summary.wl> <certificate.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
chartStripFile = ExpandFileName[arguments[[3]]];
solutionFile = ExpandFileName[arguments[[4]]];
summaryFile = ExpandFileName[arguments[[5]]];
certificateFile = ExpandFileName[arguments[[6]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencyFiles = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TransportCharts.wl"}],
  "MasterTransport" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "MasterTransport.wl"}]
|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[inputFile] ||
    ! FileExistsQ[chartStripFile] || ! FileExistsQ[solutionFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[certificateFile],
  Print["CF300PAIRCERT FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[certificateFile]],
  CreateDirectory[DirectoryName[certificateFile], CreateIntermediateDirectories -> True]];

inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
chartStripHashBefore = FileHash[chartStripFile, "SHA256", "HexString"];
solutionHashBefore = FileHash[solutionFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[System`Names["FeynFacet`VerifyEpsFormStrip"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] =!= dependencyHashesBefore,
  Print["CF300PAIRCERT FAIL package changed while loading"];
  Exit[95]];

writeAtomic[value_, file_] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  If[FileExistsQ[file], Return[$Failed]];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
exportWXFAtomic[value_, file_] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  If[FileExistsQ[file], Return[$Failed]];
  written = Quiet[Check[Export[temporary, value, "WXF"], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|
    "Status" -> status,
    "InputFile" -> inputFile, "InputSHA256" -> inputHashBefore,
    "ChartStripFile" -> chartStripFile, "ChartStripSHA256" -> chartStripHashBefore,
    "SolutionFile" -> solutionFile, "SolutionSHA256" -> solutionHashBefore,
    "DriverFile" -> $InputFileName, "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "CertificateFile" -> certificateFile
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRCERT FAIL atomic summary write output=", summaryFile];
    Exit[98]];
  Print["CF300PAIRCERT RESULT status=", status, " output=", summaryFile];
  Exit[code]
];

zeroQ[expression_] := AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];

Print["CF300PAIRCERT stage=load-payloads time=", DateString["ISODateTime"]];
{loadSeconds, loaded} = AbsoluteTiming[
  {FeynFacet`FamilyArtifactRead[inputFile],
   Quiet[Check[Import[chartStripFile, "WXF"], $Failed]],
   Quiet[Check[Import[solutionFile, "WXF"], $Failed]]}];
{sourceRecord, chartPayload, solutionPayload} = loaded;
If[FileHash[inputFile, "SHA256", "HexString"] =!= inputHashBefore ||
    FileHash[chartStripFile, "SHA256", "HexString"] =!= chartStripHashBefore ||
    FileHash[solutionFile, "SHA256", "HexString"] =!= solutionHashBefore,
  finish["InputChangedDuringLoad", <||>, 96]];
If[! AssociationQ[sourceRecord] || ! AssociationQ[chartPayload] ||
    ! AssociationQ[solutionPayload] ||
    Lookup[sourceRecord, {"Family", "Sector", "LowerSector"}, None] =!= {"CF300", 12, 9} ||
    Lookup[chartPayload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[solutionPayload, "Status", None] =!= "CF300PairChartRationalSolutionV1" ||
    Lookup[chartPayload, "InputSHA256", None] =!= inputHashBefore ||
    Lookup[solutionPayload, "InputSHA256", None] =!= inputHashBefore ||
    Lookup[solutionPayload, "ChartStripSHA256", None] =!= chartStripHashBefore,
  finish["PayloadProvenanceMismatch", <|"LoadSeconds" -> loadSeconds|>, 66]];

solution = solutionPayload["Solution"];
chart = chartPayload["Chart"];
data = chartPayload["ChartData"];
usedRoots = chartPayload["UsedRoots"];
rootImages = chartPayload["RootImages"];
coordinateMap = chartPayload["CoordinateMap"];
chartVariables = chartPayload["Variables"];
sourceVariables = sourceRecord["Variables"];
epsilon = sourceRecord["Regulator"];
If[! AssociationQ[solution] || Lookup[solution, "Status", None] =!= "Solved" ||
    ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]] ||
    ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
    ! AssociationQ[coordinateMap] || Lookup[coordinateMap, "Status", None] =!= "OK" ||
    ! TrueQ[Lookup[coordinateMap, "CompositionExact", False]],
  finish["UncertifiedChartSolutionPayload", <||>, 67]];

chartCertificate = FeynFacet`TransportChartVerify[chart];
If[! TrueQ[Lookup[chartCertificate, "OK", False]] ||
    Lookup[data, "Status", None] =!= "OK",
  finish["ChartReverificationFailed", <|"ChartCertificate" -> chartCertificate|>, 68]];

Print["CF300PAIRCERT stage=source-gauge-compose time=", DateString["ISODateTime"],
  " chartGaugeLeafCount=", LeafCount[solution["Gauge"]]];
{composeSeconds, sourceGauge} = AbsoluteTiming[
  Map[Together, solution["Gauge"] /. coordinateMap["Map"], {2}]];
sourceAlphabet = DeleteDuplicates[Together /@
  (solution["Alphabet"] /. coordinateMap["Map"])];
Print["CF300PAIRCERT stage=source-gauge-composed seconds=", composeSeconds,
  " sourceGaugeLeafCount=", LeafCount[sourceGauge],
  " sourceAlphabetLength=", Length[sourceAlphabet]];

chartBranchRoots = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
  usedRoots];
signChoices = Tuples[{1, -1}, Length[usedRoots]];
acceptedSigns = Select[signChoices, Function[signs,
  branchImages = MapThread[Times, {signs, rootImages}];
  roundTripGauge = FeynFacet`Private`transportChartApplyRootBranches[
    sourceGauge, usedRoots, branchImages];
  zeroQ[(roundTripGauge /. data["Subst"]) - solution["Gauge"]]
]];
If[acceptedSigns === {},
  finish["GaugeBranchRoundTripFailed", <|
    "ComposeSeconds" -> composeSeconds,
    "SignChoices" -> signChoices
  |>, 69]];

sourceSolution = <|
  "Gauge" -> sourceGauge,
  "Alphabet" -> sourceAlphabet,
  "ResidueMatrices" -> solution["ResidueMatrices"]
|>;
Print["CF300PAIRCERT stage=exact-source-pfaffian-start time=", DateString["ISODateTime"],
  " branchSigns=", First[acceptedSigns]];
{verifySeconds, verification} = AbsoluteTiming[
  FeynFacet`VerifyEpsFormStrip[
    sourceRecord, sourceSolution,
    "Method" -> "Exact", "KernelCount" -> 1]];
Print["CF300PAIRCERT stage=exact-source-pfaffian-finished seconds=", verifySeconds,
  " certified=", If[AssociationQ[verification],
    Lookup[verification, "DLogFormCertified", False], False]];
If[! AssociationQ[verification] ||
    ! TrueQ[Lookup[verification, "ExactPfaffianResidualsZero", False]] ||
    ! TrueQ[Lookup[verification, "DLogFormCertified", False]],
  finish["ExactSourcePfaffianFailed", <|
    "ComposeSeconds" -> composeSeconds,
    "VerifySeconds" -> verifySeconds,
    "Verification" -> If[AssociationQ[verification],
      KeyDrop[verification, "Residuals"], verification]
  |>, 2]];

certificatePayload = <|
  "Status" -> "CF300PairChartSourceCertifiedV1",
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "InputFile" -> inputFile, "InputSHA256" -> inputHashBefore,
  "ChartStripFile" -> chartStripFile, "ChartStripSHA256" -> chartStripHashBefore,
  "SolutionFile" -> solutionFile, "SolutionSHA256" -> solutionHashBefore,
  "Chart" -> chart,
  "BranchSigns" -> First[acceptedSigns],
  "SourceGauge" -> sourceGauge,
  "SourceAlphabet" -> sourceAlphabet,
  "ResidueMatrices" -> solution["ResidueMatrices"],
  "Verification" -> KeyDrop[verification, "Residuals"],
  "Certificate" -> <|
    "ChartRootIdentitiesExact" -> True,
    "ChartJacobianNonzero" -> True,
    "CoordinateCompositionExact" -> True,
    "GaugeBranchRoundTripExact" -> True,
    "ExactSourcePfaffianResidualsZero" -> True,
    "SourceDLogFormCertified" -> True,
    "PackageSourceUnmodified" -> True
  |>
|>;
If[exportWXFAtomic[certificatePayload, certificateFile] === $Failed,
  finish["CertificateWriteFailed", <|
    "ComposeSeconds" -> composeSeconds, "VerifySeconds" -> verifySeconds|>, 97]];
certificateHash = FileHash[certificateFile, "SHA256", "HexString"];

finish["CF300PairChartSourceCertifiedV1", <|
  "LoadSeconds" -> loadSeconds,
  "ComposeSeconds" -> composeSeconds,
  "VerifySeconds" -> verifySeconds,
  "CertificateSHA256" -> certificateHash,
  "CertificateBytes" -> FileByteCount[certificateFile],
  "BranchSigns" -> First[acceptedSigns],
  "SourceGaugeDimensions" -> Dimensions[sourceGauge],
  "SourceGaugeLeafCount" -> LeafCount[sourceGauge],
  "SourceAlphabetLength" -> Length[sourceAlphabet],
  "Verification" -> KeyTake[verification, {
    "ExactPfaffianResidualsZero", "ExactPfaffianIdentitiesZero",
    "LettersEpsFree", "ResiduesKinematicsFree", "ResiduesEpsFree",
    "DLogFormCertified", "CanonicalEpsFormCertified", "ExactCheckSeconds"}],
  "PackageUnmodifiedDuringCertification" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] === dependencyHashesBefore)
|>, 0];
