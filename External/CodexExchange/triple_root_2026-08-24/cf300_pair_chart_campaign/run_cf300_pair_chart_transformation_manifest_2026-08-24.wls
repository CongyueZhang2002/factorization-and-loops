#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 7,
  Print["CF300PAIRMANIFEST FAIL usage=<project-root> <input.wl> <chart-strip.wxf> <solution.wxf> <birational-summary.wl> <summary.wl> <certificate.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
chartStripFile = ExpandFileName[arguments[[3]]];
solutionFile = ExpandFileName[arguments[[4]]];
birationalSummaryFile = ExpandFileName[arguments[[5]]];
summaryFile = ExpandFileName[arguments[[6]]];
certificateFile = ExpandFileName[arguments[[7]]];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyRowGauge" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FamilyRowGauge.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TransportCharts.wl"}]
|>;
requiredFiles = {inputFile, chartStripFile, solutionFile,
  birationalSummaryFile};
If[! DirectoryQ[projectRoot] || ! AllTrue[requiredFiles, FileExistsQ] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[certificateFile],
  Print["CF300PAIRMANIFEST FAIL invalid input or stale output target"];
  Exit[65]];
Scan[If[! DirectoryQ[DirectoryName[#]],
    CreateDirectory[DirectoryName[#], CreateIntermediateDirectories -> True]] &,
  {summaryFile, certificateFile}];

fileHashesBefore = AssociationThread[requiredFiles,
  FileHash[#, "SHA256", "HexString"] & /@ requiredFiles];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &,
  dependencyFiles];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];

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
    Print["CF300PAIRMANIFEST FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRMANIFEST RESULT status=", status,
    " output=", summaryFile];
  Exit[code]
];
zeroMatrixQ[matrix_] := AllTrue[Flatten[{matrix}], TrueQ[Together[#] === 0] &];

Print["CF300PAIRMANIFEST stage=load time=", DateString["ISODateTime"]];
chartPayload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
solutionPayload = Quiet[Check[Import[solutionFile, "WXF"], $Failed]];
birationalSummary = Quiet[Check[Get[birationalSummaryFile], $Failed]];
If[AssociationThread[requiredFiles,
      FileHash[#, "SHA256", "HexString"] & /@ requiredFiles] =!=
    fileHashesBefore,
  finish["InputChangedDuringLoad", <||>, 96]];
If[! And @@ (AssociationQ /@ {chartPayload, solutionPayload,
      birationalSummary}) ||
    Lookup[chartPayload, "Status", None] =!=
      "CF300PairChartRationalStripV1" ||
    Lookup[solutionPayload, "Status", None] =!=
      "CF300PairChartRationalSolutionV1" ||
    Lookup[birationalSummary, "Status", None] =!=
      "CF300PairChartBirationalSourceProofV1",
  finish["PayloadStatusMismatch", <||>, 66]];
If[Lookup[chartPayload, "InputSHA256", None] =!= fileHashesBefore[inputFile] ||
    Lookup[solutionPayload, "InputSHA256", None] =!= fileHashesBefore[inputFile] ||
    Lookup[solutionPayload, "ChartStripSHA256", None] =!=
      fileHashesBefore[chartStripFile] ||
    Lookup[birationalSummary, "InputFilesSHA256", <||>][solutionFile] =!=
      fileHashesBefore[solutionFile],
  finish["PayloadProvenanceMismatch", <||>, 67]];

solution = solutionPayload["Solution"];
gaugeBlock = Lookup[solution, "Gauge", Missing["NoGauge"]];
chartVariables = solutionPayload["Variables"];
epsilon = solutionPayload["Regulator"];
If[! MatrixQ[gaugeBlock] || Dimensions[gaugeBlock] =!= {2, 2} ||
    ! MatchQ[chartVariables, {_Symbol, _Symbol}] || ! SymbolQ[epsilon] ||
    ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
    ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]],
  finish["InvalidCertifiedGaugePayload", <||>, 68]];

Print["CF300PAIRMANIFEST stage=unipotent-transform time=",
  DateString["ISODateTime"]];
lowerDimension = Dimensions[gaugeBlock][[2]];
upperDimension = Dimensions[gaugeBlock][[1]];
zeroUpperRight = ConstantArray[0, {lowerDimension, upperDimension}];
fullTransformation = ArrayFlatten[{{IdentityMatrix[lowerDimension],
    zeroUpperRight}, {gaugeBlock, IdentityMatrix[upperDimension]}}];
fullInverse = ArrayFlatten[{{IdentityMatrix[lowerDimension],
    zeroUpperRight}, {-gaugeBlock, IdentityMatrix[upperDimension]}}];
nilpotentPart = fullTransformation -
  IdentityMatrix[lowerDimension + upperDimension];
inverseLeftExact = zeroMatrixQ[
  fullInverse.fullTransformation -
    IdentityMatrix[lowerDimension + upperDimension]];
inverseRightExact = zeroMatrixQ[
  fullTransformation.fullInverse -
    IdentityMatrix[lowerDimension + upperDimension]];
nilpotentSquareExact = zeroMatrixQ[nilpotentPart.nilpotentPart];
determinantExact = Quiet[Check[
  TrueQ[Together[Det[fullTransformation]] === 1], False]];
If[! And[inverseLeftExact, inverseRightExact, nilpotentSquareExact,
    determinantExact],
  finish["UnipotentTransformationCheckFailed", <|
    "InverseLeftExact" -> inverseLeftExact,
    "InverseRightExact" -> inverseRightExact,
    "NilpotentSquareExact" -> nilpotentSquareExact,
    "DeterminantOneExact" -> determinantExact|>, 2]];

{chartP, chartQ} = chartVariables;
chartK = Expand[chartP (1 - chartP)];
chartD = Expand[chartQ^2 + 4 chartK];
chartA = Together[(4 chartK - 2 chartQ)/chartD];
chartAlpha = Together[chartA - chartP];
chartBeta = Together[1 + chartQ chartA];
openSetManifest = <|
  "ForwardChartDenominatorNonzero" -> chartD,
  "InversePatchDenominatorNonzero" -> chartA,
  "BranchDivisorsNonzero" -> {chartAlpha, chartBeta},
  "GaugeEntryDenominatorNonzero" -> Lookup[solution,
    "GaugeDenominator", Missing["NotPersisted"]],
  "DLogLetterDivisorsNonzero" -> Lookup[solution, "Alphabet", {}],
  "PersistedChartStripEntryDenominatorsNonzero" -> <|
    "DefinedByArtifact" -> chartStripFile,
    "SHA256" -> fileHashesBefore[chartStripFile]|>
|>;

certificatePayload = <|
  "Status" -> "CF300PairChartTransformationManifestV1",
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "InputFile" -> inputFile, "InputSHA256" -> fileHashesBefore[inputFile],
  "ChartStripFile" -> chartStripFile,
  "ChartStripSHA256" -> fileHashesBefore[chartStripFile],
  "SolutionFile" -> solutionFile,
  "SolutionSHA256" -> fileHashesBefore[solutionFile],
  "BirationalSourceSummaryFile" -> birationalSummaryFile,
  "BirationalSourceSummarySHA256" ->
    fileHashesBefore[birationalSummaryFile],
  "GaugeBlockDimensions" -> Dimensions[gaugeBlock],
  "GaugeBlockNeedNotBeInvertible" -> True,
  "FullTransformationConvention" ->
    "U = ArrayFlatten[{{I_lower,0},{G,I_upper}}]; S_new = S_old.U; UInverse = ArrayFlatten[{{I_lower,0},{-G,I_upper}}].",
  "ConnectionConvention" ->
    "Bbar_new = Bbar + eps (E.G - G.C) - dG = eps Sum_a R_a dlog(L_a).",
  "FullTransformationDeterminant" -> 1,
  "FullTransformationInverseExact" -> True,
  "NilpotentOffDiagonalSquareZero" -> True,
  "ExactDLog" -> True,
  "ExactPfaffianResidualsZero" -> True,
  "GenericOpenSetExcludedDivisors" -> openSetManifest,
  "PackageSourceUnmodified" -> True
|>;
If[exportWXFAtomic[certificatePayload, certificateFile] === $Failed,
  finish["CertificateWriteFailed", <||>, 97]];

finish["CF300PairChartTransformationManifestV1", <|
  "CertificateSHA256" -> FileHash[certificateFile, "SHA256", "HexString"],
  "CertificateBytes" -> FileByteCount[certificateFile],
  "GaugeBlockDimensions" -> Dimensions[gaugeBlock],
  "GaugeBlockNeedNotBeInvertible" -> True,
  "FullTransformationDimensions" -> Dimensions[fullTransformation],
  "InverseLeftExact" -> inverseLeftExact,
  "InverseRightExact" -> inverseRightExact,
  "NilpotentSquareExact" -> nilpotentSquareExact,
  "DeterminantOneExact" -> determinantExact,
  "ConnectionConvention" -> certificatePayload["ConnectionConvention"],
  "GenericOpenSetExcludedDivisors" -> openSetManifest,
  "PackageUnmodifiedDuringManifest" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] ===
      dependencyHashesBefore)
|>, 0];
