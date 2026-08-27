#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, inputFile, expectedInputHash, outdir,
    artifactDirectory, summaryFile, solutionFile, dependencyFiles,
    dependencyHashesBefore, dependencyHashesAfter, inputHashBefore,
    payload, chartVariables, regulator, strip, record, solveSeconds,
    solution, solutionPayload, summary, hashHex, putAtomic, exportAtomic,
    fail, tag, result},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  inputFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_strip_v1/CF303_17_12_pair_chart_strip_v1.wxf";
  expectedInputHash =
    "246b89517021211fd41470a4ff7ec6591c674b9f694481c820a8b9b8bf3779d4";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  solutionFile = FileNameJoin[{outdir, "solution.wxf"}];
  tag = Unique["CF303PairChartSolveV1$"];
  dependencyFiles = <|
    "LoadFACET" -> loadFile,
    "FeynFacetPublic" -> FileNameJoin[{repositoryRoot, "FeynFacet",
      "FeynFacet.m"}],
    "FiniteFieldStripSolve" -> FileNameJoin[{repositoryRoot, "FeynFacet",
      "Private", "FiniteFieldStripSolve.wl"}],
    "FiniteFieldEpsForm" -> FileNameJoin[{repositoryRoot, "FeynFacet",
      "Private", "FiniteFieldEpsForm.wl"}],
    "TaskBroker" -> FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "TaskBroker.wl"}]|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  exportAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Export[temporary, expression, "WXF"];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := Module[{failureSummary},
    failureSummary = Join[<|"Status" -> status,
      "InputFile" -> inputFile, "InputSHA256" -> expectedInputHash,
      "DependencyHashes" -> dependencyHashesBefore,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir] && ! FileExistsQ[summaryFile],
      Quiet[Check[putAtomic[failureSummary, summaryFile], Null]]];
    Print["CF303 PAIR CHART SOLVE FAILURE V1: " <> status];
    Throw[$Failed, tag]];

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      Print["CF303 PAIR CHART SOLVE FAILURE V1: wrapper takes no arguments"];
      Throw[$Failed, tag]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      Print["CF303 PAIR CHART SOLVE FAILURE V1: pool worker required"];
      Throw[$Failed, tag]];
    If[Length[Kernels[]] =!= 0,
      Print["CF303 PAIR CHART SOLVE FAILURE V1: nested kernels pre-exist"];
      Throw[$Failed, tag]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 4),
      Print["CF303 PAIR CHART SOLVE FAILURE V1: helper ceiling must be four"];
      Throw[$Failed, tag]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir] ||
        hashHex[inputFile] =!= expectedInputHash ||
        ! AllTrue[Values[dependencyFiles], FileExistsQ],
      Print["CF303 PAIR CHART SOLVE FAILURE V1: invalid immutable inputs"];
      Throw[$Failed, tag]];
    CreateDirectory[outdir];
    CreateDirectory[artifactDirectory];
    inputHashBefore = hashHex[inputFile];
    dependencyHashesBefore = Map[hashHex, dependencyFiles];

    Print["CF303SOLVEV1 stage=load-package"];
    Get[loadFile];
    dependencyHashesAfter = Map[hashHex, dependencyFiles];
    If[dependencyHashesAfter =!= dependencyHashesBefore,
      fail["PackageChangedDuringLoad"]];
    payload = Quiet[Check[Import[inputFile, "WXF"], $Failed]];
    If[hashHex[inputFile] =!= inputHashBefore,
      fail["InputChangedDuringImport"]];
    If[! AssociationQ[payload] ||
        Lookup[payload, "Status", None] =!=
          "CF303PairChartRationalStripV1" ||
        Lookup[payload, {"Family", "Sector", "LowerSector"}, None] =!=
          {"CF303", 17, 12},
      fail["InvalidChartStripPayload"]];
    chartVariables = payload["Variables"];
    regulator = payload["Regulator"];
    strip = payload["Strip"];
    If[Dimensions /@ strip =!= {{2, 1, 1}, {2, 4, 4}, {2, 1, 4}} ||
        ! FreeQ[strip,
          _Root | Power[_, exponent_Rational /;
            Denominator[exponent] > 1]],
      fail["InvalidRationalStripABI"]];
    record = <|"Family" -> "CF303", "Sector" -> 17,
      "LowerSector" -> 12, "Variables" -> chartVariables,
      "Regulator" -> regulator, "Strip" -> strip|>;

    Print["CF303SOLVEV1 stage=finite-field-start leafCount=",
      LeafCount[strip], " helperLimit=",
      KernelPoolMission`$TaskBrokerMaxHelpers];
    solveSeconds = First@AbsoluteTiming[
      solution = FeynFacet`SolveEpsFormStripFiniteField[
        record,
        "KernelCount" -> 5,
        "ArtifactDirectory" -> artifactDirectory,
        "ArtifactPrefix" -> "CF303_17_12_pair_chart_v1",
        "Backend" -> Automatic,
        "BackendThreads" -> 1,
        "PlanDiscoveryBackend" -> "Wolfram",
        "SupportStrategy" -> "SimplexFirst",
        "SupportLearning" -> True,
        "RegulatorSampling" -> "HeldOut",
        "FinalCheck" -> "Exact",
        "Verbose" -> True]];
    Print["CF303SOLVEV1 stage=finite-field-finished seconds=",
      solveSeconds, " status=",
      If[AssociationQ[solution], Lookup[solution, "Status", None],
        Head[solution]]];
    If[! AssociationQ[solution] ||
        Lookup[solution, "Status", None] =!= "Solved" ||
        ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
        ! TrueQ[Lookup[solution, "ExactPfaffianResidualsZero", False]],
      fail["RationalChartFiniteFieldNotSolved", <|
        "SolveSeconds" -> solveSeconds,
        "SolutionSummary" -> If[AssociationQ[solution],
          KeyDrop[solution, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], solution]|>]];

    solutionPayload = <|
      "Status" -> "CF303PairChartRationalSolutionV1",
      "Family" -> "CF303", "Sector" -> 17, "LowerSector" -> 12,
      "InputFile" -> inputFile, "InputSHA256" -> expectedInputHash,
      "Variables" -> chartVariables, "Regulator" -> regulator,
      "Solution" -> solution|>;
    exportAtomic[solutionPayload, solutionFile];
    dependencyHashesAfter = Map[hashHex, dependencyFiles];
    If[dependencyHashesAfter =!= dependencyHashesBefore,
      fail["PackageChangedDuringSolve"]];
    summary = <|
      "Status" -> "CF303PairChartRationalSolvePassedV1",
      "InputFile" -> inputFile, "InputSHA256" -> expectedInputHash,
      "SolutionFile" -> solutionFile,
      "SolutionSHA256" -> hashHex[solutionFile],
      "SolutionBytes" -> FileByteCount[solutionFile],
      "SolveSeconds" -> solveSeconds,
      "GaugeDimensions" -> Dimensions[solution["Gauge"]],
      "GaugeLeafCount" -> LeafCount[solution["Gauge"]],
      "AlphabetLength" -> Length[solution["Alphabet"]],
      "ResidueMatrixCount" -> Length[solution["ResidueMatrices"]],
      "Method" -> solution["Method"],
      "ExactDLog" -> solution["ExactDLog"],
      "ExactPfaffianResidualsZero" ->
        solution["ExactPfaffianResidualsZero"],
      "SelectedSupportShell" ->
        Lookup[solution, "SelectedSupportShell", None],
      "GaugeSupportCount" -> Lookup[solution, "GaugeSupportCount", None],
      "ModularPrimeCount" -> Lookup[solution, "ModularPrimeCount", None],
      "Primes" -> Lookup[solution, "Primes", {}],
      "BackendConfiguration" ->
        Lookup[solution, "BackendConfiguration", None],
      "DependencyHashes" -> dependencyHashesBefore,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303SOLVEV1 status=PASS seconds=", Round[solveSeconds, 0.1],
      " solution=", solutionFile];
    0,
    tag];
  result
]
