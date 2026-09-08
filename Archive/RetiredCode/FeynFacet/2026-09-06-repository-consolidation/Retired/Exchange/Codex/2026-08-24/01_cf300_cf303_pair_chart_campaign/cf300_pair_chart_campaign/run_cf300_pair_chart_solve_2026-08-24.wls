#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 5,
  Print["CF300PAIRSOLVE FAIL usage=<project-root> <chart-strip.wxf> <artifact-dir> <summary.wl> <solution.wxf>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
chartStripFile = ExpandFileName[arguments[[2]]];
artifactDirectory = ExpandFileName[arguments[[3]]];
summaryFile = ExpandFileName[arguments[[4]]];
solutionFile = ExpandFileName[arguments[[5]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencyFiles = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "FiniteFieldEpsForm.wl"}],
  "TaskBroker" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TaskBroker.wl"}]
|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[chartStripFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[summaryFile] || FileExistsQ[solutionFile] ||
    FileExistsQ[summaryFile <> ".tmp"] || FileExistsQ[solutionFile <> ".tmp"],
  Print["CF300PAIRSOLVE FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[artifactDirectory],
  CreateDirectory[artifactDirectory, CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];
If[! DirectoryQ[DirectoryName[solutionFile]],
  CreateDirectory[DirectoryName[solutionFile], CreateIntermediateDirectories -> True]];

chartStripHashBefore = FileHash[chartStripFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[System`Names["FeynFacet`SolveEpsFormStripFiniteField"] === {}, Get[loadFile]];
dependencyHashesAfterLoad = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[dependencyHashesAfterLoad =!= dependencyHashesBefore,
  Print["CF300PAIRSOLVE FAIL package changed while loading"];
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
    "ChartStripFile" -> chartStripFile,
    "ChartStripSHA256" -> chartStripHashBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "ArtifactDirectory" -> artifactDirectory,
    "SolutionFile" -> solutionFile
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRSOLVE FAIL atomic summary write output=", summaryFile];
    Exit[98]];
  Print["CF300PAIRSOLVE RESULT status=", status, " output=", summaryFile];
  Exit[code]
];

Print["CF300PAIRSOLVE stage=load-chart-strip time=", DateString["ISODateTime"]];
{importSeconds, payload} = AbsoluteTiming[
  Quiet[Check[Import[chartStripFile, "WXF"], $Failed]]];
If[FileHash[chartStripFile, "SHA256", "HexString"] =!= chartStripHashBefore,
  finish["ChartStripChangedDuringImport", <||>, 96]];
If[! AssociationQ[payload] ||
    Lookup[payload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[payload, {"Family", "Sector", "LowerSector"}, None] =!= {"CF300", 12, 9},
  finish["InvalidChartStripPayload", <|"ImportSeconds" -> importSeconds|>, 66]];

chartVariables = payload["Variables"];
epsilon = payload["Regulator"];
chartStrip = payload["Strip"];
If[! MatchQ[chartVariables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] || ! ListQ[chartStrip],
  finish["InvalidChartStripABI", <||>, 67]];
If[! FreeQ[chartStrip, _Root | Power[_, exponent_Rational /; Denominator[exponent] > 1]],
  finish["ChartStripContainsRadicals", <||>, 68]];

record = <|
  "Family" -> "CF300",
  "Sector" -> 12,
  "LowerSector" -> 9,
  "Variables" -> chartVariables,
  "Regulator" -> epsilon,
  "Strip" -> chartStrip
|>;
Print["CF300PAIRSOLVE stage=finite-field-start time=", DateString["ISODateTime"],
  " leafCount=", LeafCount[chartStrip],
  " broker=", Environment["FACET_TASK_BROKER"],
  " helperLimit=", KernelPoolMission`$TaskBrokerMaxHelpers];
{solveSeconds, solution} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[
    record,
    "KernelCount" -> 8,
    "ArtifactDirectory" -> artifactDirectory,
    "ArtifactPrefix" -> "CF300_12_9_pair_chart_v1",
    "Backend" -> Automatic,
    "BackendThreads" -> 1,
    "PlanDiscoveryBackend" -> "Wolfram",
    "SupportStrategy" -> "SimplexFirst",
    "SupportLearning" -> True,
    "RegulatorSampling" -> "HeldOut",
    "FinalCheck" -> "Exact",
    "Verbose" -> True]];
Print["CF300PAIRSOLVE stage=finite-field-finished seconds=", solveSeconds,
  " status=", If[AssociationQ[solution], Lookup[solution, "Status", None], Head[solution]]];

If[! AssociationQ[solution] || Lookup[solution, "Status", None] =!= "Solved" ||
    ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
    ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]],
  finish["RationalChartFiniteFieldNotSolved", <|
    "SolveSeconds" -> solveSeconds,
    "SolutionSummary" -> If[AssociationQ[solution],
      KeyDrop[solution, {"Gauge", "ResidueMatrices", "EliminationPlan"}], solution]
  |>, 2]];

solutionPayload = <|
  "Status" -> "CF300PairChartRationalSolutionV1",
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
  "ChartStripFile" -> chartStripFile,
  "ChartStripSHA256" -> chartStripHashBefore,
  "InputFile" -> payload["InputFile"],
  "InputSHA256" -> payload["InputSHA256"],
  "Variables" -> chartVariables,
  "Regulator" -> epsilon,
  "Solution" -> solution
|>;
If[exportWXFAtomic[solutionPayload, solutionFile] === $Failed,
  finish["SolutionWriteFailed", <|"SolveSeconds" -> solveSeconds|>, 97]];
solutionHash = FileHash[solutionFile, "SHA256", "HexString"];

finish["CF300PairChartRationalSolvePassedV1", <|
  "ImportSeconds" -> importSeconds,
  "SolveSeconds" -> solveSeconds,
  "SolutionSHA256" -> solutionHash,
  "SolutionBytes" -> FileByteCount[solutionFile],
  "GaugeDimensions" -> Dimensions[solution["Gauge"]],
  "GaugeLeafCount" -> LeafCount[solution["Gauge"]],
  "AlphabetLength" -> Length[solution["Alphabet"]],
  "ResidueMatrixCount" -> Length[solution["ResidueMatrices"]],
  "Method" -> solution["Method"],
  "Certificate" -> Lookup[solution, "Certificate", "ExactDLog"],
  "ExactDLog" -> solution["ExactDLog"],
  "ExactPfaffianResidualsZero" -> solution["ExactPfaffianResidualsZero"],
  "GaugeNumeratorDegrees" -> solution["GaugeNumeratorDegrees"],
  "GaugeDenominatorDegrees" -> solution["GaugeDenominatorDegrees"],
  "SelectedSupportShell" -> Lookup[solution, "SelectedSupportShell", None],
  "GaugeSupportCount" -> Lookup[solution, "GaugeSupportCount", None],
  "ModularPrimeCount" -> Lookup[solution, "ModularPrimeCount", None],
  "Primes" -> Lookup[solution, "Primes", {}],
  "BackendConfiguration" -> Lookup[solution, "BackendConfiguration", None],
  "PackageUnmodifiedDuringSolve" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] === dependencyHashesBefore)
|>, 0];
