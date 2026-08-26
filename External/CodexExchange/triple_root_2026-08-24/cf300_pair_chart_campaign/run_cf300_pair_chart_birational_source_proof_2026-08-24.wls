#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 8,
  Print["CF300PAIRBIRATIONAL FAIL usage=<project-root> <input.wl> <chart-strip.wxf> <solution.wxf> <direct-summary.wl> <common-summary.wl> <summary.wl> <certificate.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
chartStripFile = ExpandFileName[arguments[[3]]];
solutionFile = ExpandFileName[arguments[[4]]];
directSummaryFile = ExpandFileName[arguments[[5]]];
commonSummaryFile = ExpandFileName[arguments[[6]]];
summaryFile = ExpandFileName[arguments[[7]]];
certificateFile = ExpandFileName[arguments[[8]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencyFiles = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TransportCharts.wl"}],
  "MasterTransport" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "MasterTransport.wl"}]
|>;

requiredFiles = {inputFile, chartStripFile, solutionFile,
  directSummaryFile, commonSummaryFile};
If[! DirectoryQ[projectRoot] || ! AllTrue[requiredFiles, FileExistsQ] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[certificateFile],
  Print["CF300PAIRBIRATIONAL FAIL invalid input or stale output target"];
  Exit[65]];
Scan[If[! DirectoryQ[DirectoryName[#]],
    CreateDirectory[DirectoryName[#], CreateIntermediateDirectories -> True]] &,
  {summaryFile, certificateFile}];

fileHashesBefore = AssociationThread[requiredFiles,
  FileHash[#, "SHA256", "HexString"] & /@ requiredFiles];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[System`Names["FeynFacet`TransportChartVerify"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] =!= dependencyHashesBefore,
  Print["CF300PAIRBIRATIONAL FAIL package changed while loading"];
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
    "InputFilesSHA256" -> fileHashesBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "CertificateFile" -> certificateFile
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRBIRATIONAL FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRBIRATIONAL RESULT status=", status, " output=", summaryFile];
  Exit[code]
];
zeroQ[expression_] := AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];

Print["CF300PAIRBIRATIONAL stage=load time=", DateString["ISODateTime"]];
record = FeynFacet`FamilyArtifactRead[inputFile];
chartPayload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
solutionPayload = Quiet[Check[Import[solutionFile, "WXF"], $Failed]];
directSummary = Quiet[Check[Get[directSummaryFile], $Failed]];
commonSummary = Quiet[Check[Get[commonSummaryFile], $Failed]];
If[AssociationThread[requiredFiles,
      FileHash[#, "SHA256", "HexString"] & /@ requiredFiles] =!= fileHashesBefore,
  finish["InputChangedDuringLoad", <||>, 96]];

If[! And @@ (AssociationQ /@ {record, chartPayload, solutionPayload,
      directSummary, commonSummary}) ||
    Lookup[record, {"Family", "Sector", "LowerSector"}, None] =!= {"CF300", 12, 9} ||
    Lookup[chartPayload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[solutionPayload, "Status", None] =!= "CF300PairChartRationalSolutionV1" ||
    Lookup[directSummary, "Status", None] =!= "CF300PairChartDirectPullbackPassedV2" ||
    Lookup[commonSummary, "Status", None] =!= "CF300PairChartCommonRowsPassedV1",
  finish["PayloadStatusMismatch", <||>, 66]];

If[Lookup[chartPayload, "InputSHA256", None] =!= fileHashesBefore[inputFile] ||
    Lookup[solutionPayload, "InputSHA256", None] =!= fileHashesBefore[inputFile] ||
    Lookup[solutionPayload, "ChartStripSHA256", None] =!= fileHashesBefore[chartStripFile] ||
    Lookup[directSummary, "InputSHA256", None] =!= fileHashesBefore[inputFile] ||
    Lookup[directSummary, "ChartStripSHA256", None] =!= fileHashesBefore[chartStripFile] ||
    Lookup[commonSummary, "ChartStripSHA256", None] =!= fileHashesBefore[chartStripFile],
  finish["PayloadProvenanceMismatch", <||>, 67]];

solution = solutionPayload["Solution"];
chart = chartPayload["Chart"];
data = chartPayload["ChartData"];
coordinateMap = chartPayload["CoordinateMap"];
chartVariables = chartPayload["Variables"];
usedRoots = chartPayload["UsedRoots"];
rootImages = chartPayload["RootImages"];

Print["CF300PAIRBIRATIONAL stage=exact-chart time=", DateString["ISODateTime"]];
chartCertificate = FeynFacet`TransportChartVerify[chart];
chartBranchRoots = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
  usedRoots];
inverseForwardResidual = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    (chartVariables /. coordinateMap["Map"]) /. data["Subst"],
    chartBranchRoots, rootImages] - chartVariables];

conditions = <|
  "ChartRootIdentitiesExact" -> TrueQ[Lookup[chartCertificate, "OK", False]],
  "ChartJacobianNonzero" -> ! TrueQ[Together[data["JacobianDet"]] === 0],
  "InverseForwardCompositionExact" -> zeroQ[inverseForwardResidual],
  "CoordinateMapDeclaredExact" ->
    TrueQ[Lookup[coordinateMap, "CompositionExact", False]],
  "DirectOrdinaryDPullbackExact" ->
    TrueQ[Lookup[directSummary, "DirectResidualsZero", False]],
  "WrongJacobianMutantRejected" ->
    TrueQ[Lookup[directSummary, "WrongJacobianOrientationRejected", False]],
  "ChartExactPfaffianResidualsZero" ->
    TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]],
  "ChartExactDLog" -> TrueQ[Lookup[solution, "ExactDLog", False]],
  "CommonRowSimplexConsistent" ->
    TrueQ[Lookup[commonSummary, "SimplexConsistent", False]],
  "CommonRowRectangleInconsistent" ->
    ! TrueQ[Lookup[commonSummary, "RectangleConsistent", True]],
  "CommonAcceptedPointsExact" ->
    TrueQ[Lookup[commonSummary, "SameAcceptedPoints", False]]
|>;
If[! AllTrue[Values[conditions], TrueQ],
  finish["BirationalProofConditionFailed", <|"Conditions" -> conditions|>, 2]];

certificatePayload = <|
  "Status" -> "CF300PairChartBirationalSourceProofV1",
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "InputFile" -> inputFile, "InputSHA256" -> fileHashesBefore[inputFile],
  "ChartStripFile" -> chartStripFile,
  "ChartStripSHA256" -> fileHashesBefore[chartStripFile],
  "SolutionFile" -> solutionFile,
  "SolutionSHA256" -> fileHashesBefore[solutionFile],
  "Chart" -> chart,
  "CoordinateMap" -> coordinateMap,
  "Conditions" -> conditions,
  "LogicalCertificate" -> <|
    "PullbackInjective" -> True,
    "Reason" -> "The exact rational inverse makes the chart pullback an injective homomorphism of function fields on the declared nonempty open set.",
    "SourceResidualImplication" ->
      "Independent exact pullback(source strip) = chart strip and exact chart Pfaffian residual = 0 imply the original source-strip residual = 0 by injectivity.",
    "DLogImplication" ->
      "Exact chart dlog letters pull back through the birational inverse to exact algebraic source-field dlogs.",
    "MaterializedSourceExpansionRequired" -> False,
    "MaterializedSourceExpansionRole" ->
      "Optional stronger implementation oracle; not required for the function-field existence proof."
  |>,
  "PackageSourceUnmodified" -> True
|>;
If[exportWXFAtomic[certificatePayload, certificateFile] === $Failed,
  finish["CertificateWriteFailed", <||>, 97]];

finish["CF300PairChartBirationalSourceProofV1", <|
  "CertificateSHA256" -> FileHash[certificateFile, "SHA256", "HexString"],
  "CertificateBytes" -> FileByteCount[certificateFile],
  "Conditions" -> conditions,
  "PullbackInjective" -> True,
  "SourceResidualProvedByInjectivity" -> True,
  "MaterializedSourceExpansionRequired" -> False,
  "PackageUnmodifiedDuringProof" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] === dependencyHashesBefore)
|>, 0];
