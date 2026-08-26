#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 5,
  Print["CF300PAIRPROBE FAIL usage=<project-root> <input.wl> <scratch-dir> <summary.wl> <chart-strip.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
scratchDirectory = ExpandFileName[arguments[[3]]];
summaryFile = ExpandFileName[arguments[[4]]];
chartStripFile = ExpandFileName[arguments[[5]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
chartTableFile = FileNameJoin[{projectRoot, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "TransportFamilyCharts.wl"}];
dependencyFiles = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TransportCharts.wl"}],
  "MasterTransport" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "MasterTransport.wl"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}],
  "TransportFamilyChartsProject" -> chartTableFile
|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[inputFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[chartStripFile] ||
    FileExistsQ[summaryFile <> ".tmp"] || FileExistsQ[chartStripFile <> ".tmp"],
  Print["CF300PAIRPROBE FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[scratchDirectory],
  CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[chartStripFile]],
  CreateDirectory[DirectoryName[chartStripFile], CreateIntermediateDirectories -> True]];

inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[System`Names["FeynFacet`TransportChartVerify"] === {}, Get[loadFile]];
dependencyHashesAfterLoad = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[dependencyHashesAfterLoad =!= dependencyHashesBefore,
  Print["CF300PAIRPROBE FAIL package changed while loading"];
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
    "InputFile" -> inputFile,
    "InputSHA256" -> inputHashBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "ChartStripFile" -> chartStripFile
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRPROBE FAIL atomic summary write output=", summaryFile];
    Exit[98]];
  Print["CF300PAIRPROBE RESULT status=", status, " output=", summaryFile];
  Exit[code]
];

zeroQ[expression_] := AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];
rationalEntryQ[expression_, variables_List] := Module[{q = Together[expression]},
  FreeQ[Unevaluated[q], _Root | Power[_, exponent_Rational /; Denominator[exponent] > 1]] &&
    PolynomialQ[Numerator[q], variables] && PolynomialQ[Denominator[q], variables]
];
entryDegree[expression_, variables_List] := Module[{q = Together[expression], numerator, denominator},
  numerator = Numerator[q]; denominator = Denominator[q];
  <|"Numerator" -> (Exponent[numerator, #] & /@ variables),
    "Denominator" -> (Exponent[denominator, #] & /@ variables),
    "LeafCount" -> LeafCount[q]|>
];

Print["CF300PAIRPROBE stage=read-input time=", DateString["ISODateTime"]];
record = FeynFacet`FamilyArtifactRead[inputFile];
If[FileHash[inputFile, "SHA256", "HexString"] =!= inputHashBefore,
  finish["InputChangedDuringRead", <||>, 96]];
If[! AssociationQ[record] ||
    Lookup[record, {"Family", "Sector", "LowerSector"}, None] =!= {"CF300", 12, 9},
  finish["InvalidCF300Sector12Input", <|
    "RecordHead" -> Head[record],
    "RecordAssociationQ" -> AssociationQ[record],
    "RecordIdentity" -> If[AssociationQ[record],
      Lookup[record, {"Family", "Sector", "LowerSector"}, None], None]
  |>, 66]];

variables = record["Variables"];
epsilon = record["Regulator"];
strip = record["Strip"];
If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] || ! ListQ[strip],
  finish["InvalidStripABI", <||>, 67]];
{sourceX, sourceY} = variables;
Quiet[Remove["CodexCF300PairChart`*", "CodexCF300PairFrame`*"]];
chartP = Symbol["CodexCF300PairChart`p"];
chartQ = Symbol["CodexCF300PairChart`q"];
frameP = Symbol["CodexCF300PairFrame`p"];
frameQ = Symbol["CodexCF300PairFrame`q"];
registryLoad = FeynFacet`TransportFamilyChartLoad[chartTableFile];
frame = FeynFacet`TransportFamilyChart["CF300", variables, {frameP, frameQ}];
If[! AssociationQ[registryLoad] ||
    Lookup[registryLoad, "Status", None] =!= "FamilyChartsRegistered" ||
    ! AssociationQ[frame],
  finish["CF300AlgebraicFrameUnavailable", <|
    "RegistryLoad" -> registryLoad,
    "Frame" -> frame
  |>, 66]];

rootSquareA = 1 - 2 sourceX + sourceX^2 + 2 sourceY +
  2 sourceX sourceY + sourceY^2;
rootSquareB = 1 - 4 sourceX sourceY;
denominatorChart = Expand[(1 - chartP^2)^2 - chartQ^2];
numeratorChart = Expand[2 (1 - chartP + chartP^2 + chartP^3 +
  (1 + chartP) chartQ)];
imageX = Together[numeratorChart/denominatorChart];
imageY = Together[chartP (denominatorChart - chartP numeratorChart)/denominatorChart];
imageRootA = Together[((1 + chartP) denominatorChart + chartQ numeratorChart)/denominatorChart];
imageRootB = Together[(denominatorChart - 2 chartP numeratorChart)/denominatorChart];
chart = <|
  "Name" -> "CF300KallenBilinearPairExternalV1",
  "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational",
  "Variables" -> {chartP, chartQ},
  "Subst" -> {sourceX -> imageX, sourceY -> imageY},
  "Root" -> imageRootA,
  "RootSquare" -> rootSquareA,
  "Roots" -> {
    <|"Root" -> imageRootA, "RootSquare" -> rootSquareA|>,
    <|"Root" -> imageRootB, "RootSquare" -> rootSquareB|>
  },
  "Notes" -> "External sector-wise simultaneous rationalization; package source unchanged"
|>;

Print["CF300PAIRPROBE stage=verify-chart time=", DateString["ISODateTime"]];
{chartVerifySeconds, chartCertificate} = AbsoluteTiming[
  FeynFacet`TransportChartVerify[chart]];
data = FeynFacet`Private`masterTransportChartData[chart, variables];
If[! TrueQ[Lookup[chartCertificate, "OK", False]] ||
    Lookup[data, "Status", None] =!= "OK",
  finish["ChartVerificationFailed", <|
    "ChartCertificate" -> chartCertificate,
    "ChartDataStatus" -> If[AssociationQ[data], KeyTake[data, {"Status", "JacobianDet"}], data]
  |>, 68]];

allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
classification = FeynFacet`Private`transportChartRootIndices[strip, allRoots];
If[! ListQ[allRoots] || Lookup[classification, "RootIndices", None] =!= {2, 3} ||
    Lookup[classification, "UnclassifiedRadicalBases", {1}] =!= {},
  finish["UnexpectedActiveRootSet", <|"Classification" -> classification|>, 69]];
usedRoots = allRoots[[classification["RootIndices"]]];
chartRoots = chart["Roots"];
rootImages = Table[
  matching = SelectFirst[chartRoots,
    TrueQ[Together[#1["RootSquare"] - usedRoots[[index]]["RootSquare"]] === 0] &,
    Missing["RootNotRationalized"]];
  If[MissingQ[matching], matching, matching["Root"]],
  {index, Length[usedRoots]}];
If[AnyTrue[rootImages, MissingQ],
  finish["RootImageMissing", <|"RootImages" -> rootImages|>, 70]];
chartBranchRoots = Map[
  <|"RootSquare" -> Together[#1["RootSquare"] /. data["Subst"]]|> &,
  usedRoots];

inverseP = Together[(1 - usedRoots[[2]]["Root"])/(2 sourceX)];
inverseQ = Together[(usedRoots[[1]]["Root"] - 1 - inverseP)/sourceX];
inverseRoundTrip = Map[Together,
  FeynFacet`Private`transportChartApplyRootBranches[
    {inverseP, inverseQ} /. data["Subst"], chartBranchRoots, rootImages] -
      {chartP, chartQ}];
If[! zeroQ[inverseRoundTrip],
  finish["InverseBranchRoundTripFailed", <|"Residual" -> inverseRoundTrip|>, 71]];

Print["CF300PAIRPROBE stage=coordinate-composition time=", DateString["ISODateTime"]];
identityData = <|
  "Status" -> "OK", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Multiquadratic",
  "Variables" -> variables, "SourceVariables" -> variables,
  "Subst" -> Thread[variables -> variables],
  "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
  "Root" -> allRoots[[1]]["Root"],
  "RootSquare" -> allRoots[[1]]["RootSquare"],
  "Roots" -> allRoots
|>;
{coordinateSeconds, coordinateMap} = AbsoluteTiming[
  FeynFacet`Private`masterTransportRecordCoordinateMap[
    <|"Variables" -> {chartP, chartQ}, "Chart" -> chart|>,
    identityData, Automatic]];
If[! AssociationQ[coordinateMap] || Lookup[coordinateMap, "Status", None] =!= "OK" ||
    ! TrueQ[Lookup[coordinateMap, "CompositionExact", False]],
  finish["CoordinateCompositionFailed", <|"CoordinateMap" -> coordinateMap|>, 72]];

pullEarly[pair_] := Module[{components},
  components = Map[
    Function[matrix,
      Map[Together,
        FeynFacet`Private`transportChartApplyRootBranches[
          matrix /. data["Subst"], chartBranchRoots, rootImages], {2}]],
    pair];
  FeynFacet`Private`masterTransportPullBackOneForm[
    components[[1]], components[[2]], data["Jacobian"]]
];

Print["CF300PAIRPROBE stage=pullback-start time=", DateString["ISODateTime"],
  " sourceLeafCount=", LeafCount[strip]];
{pullbackSeconds, chartStrip} = AbsoluteTiming[pullEarly /@ strip];
Print["CF300PAIRPROBE stage=pullback-finished seconds=", pullbackSeconds,
  " chartLeafCount=", LeafCount[chartStrip]];
entries = Flatten[chartStrip];
rationalFlags = rationalEntryQ[#, {chartP, chartQ, epsilon}] & /@ entries;
survivingSourceSymbols = DeleteDuplicates[Cases[chartStrip,
  symbol_Symbol /; MemberQ[SymbolName /@ variables, SymbolName[symbol]],
  {0, Infinity}, Heads -> True]];
foreignSymbols = Complement[
  DeleteDuplicates[Cases[chartStrip,
    symbol_Symbol /; Context[symbol] =!= "System`", {0, Infinity}, Heads -> True]],
  {chartP, chartQ, epsilon}];
If[! AllTrue[rationalFlags, TrueQ] || survivingSourceSymbols =!= {} ||
    foreignSymbols =!= {},
  finish["ChartStripNotRational", <|
    "NonRationalEntryPositions" -> Flatten[Position[rationalFlags, False]],
    "SurvivingSourceSymbols" -> survivingSourceSymbols,
    "ForeignSymbols" -> foreignSymbols,
    "PullbackSeconds" -> pullbackSeconds
  |>, 73]];

Print["CF300PAIRPROBE stage=degree-census time=", DateString["ISODateTime"]];
degreeCensus = entryDegree[#, {chartP, chartQ, epsilon}] & /@ entries;
maximumNumeratorDegrees = Max /@ Transpose[Lookup[degreeCensus, "Numerator"]];
maximumDenominatorDegrees = Max /@ Transpose[Lookup[degreeCensus, "Denominator"]];
maximumEntryLeafCount = Max[Lookup[degreeCensus, "LeafCount"]];

chartPayload = <|
  "Status" -> "CF300PairChartRationalStripV1",
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "InputFile" -> inputFile, "InputSHA256" -> inputHashBefore,
  "Variables" -> {chartP, chartQ}, "Regulator" -> epsilon,
  "SourceVariables" -> variables, "Chart" -> chart,
  "ChartData" -> data, "UsedRoots" -> usedRoots,
  "RootImages" -> rootImages, "CoordinateMap" -> coordinateMap,
  "Strip" -> chartStrip
|>;
Print["CF300PAIRPROBE stage=write-chart-strip time=", DateString["ISODateTime"]];
If[exportWXFAtomic[chartPayload, chartStripFile] === $Failed,
  finish["ChartStripWriteFailed", <||>, 97]];
chartStripHash = FileHash[chartStripFile, "SHA256", "HexString"];

finish["CF300PairChartProbePassedV1", <|
  "Chart" -> chart,
  "ChartCertificate" -> chartCertificate,
  "ChartVerifySeconds" -> chartVerifySeconds,
  "Classification" -> classification,
  "BranchInverseRoundTripExact" -> True,
  "CoordinateComposition" -> KeyTake[coordinateMap,
    {"Status", "Frame", "Map", "CompositionIdentity", "CompositionExact"}],
  "CoordinateCompositionSeconds" -> coordinateSeconds,
  "PullbackSeconds" -> pullbackSeconds,
  "SourceLeafCount" -> LeafCount[strip],
  "ChartLeafCount" -> LeafCount[chartStrip],
  "ChartEntryCount" -> Length[entries],
  "MaximumEntryLeafCount" -> maximumEntryLeafCount,
  "MaximumNumeratorDegreesPQEpsilon" -> maximumNumeratorDegrees,
  "MaximumDenominatorDegreesPQEpsilon" -> maximumDenominatorDegrees,
  "ChartStripSHA256" -> chartStripHash,
  "ChartStripBytes" -> FileByteCount[chartStripFile],
  "PackageUnmodifiedDuringProbe" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] === dependencyHashesBefore)
|>, 0];
