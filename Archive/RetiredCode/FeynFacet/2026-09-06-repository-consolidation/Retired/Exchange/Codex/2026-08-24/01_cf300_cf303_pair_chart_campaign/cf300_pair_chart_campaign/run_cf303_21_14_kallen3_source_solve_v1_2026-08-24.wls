#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, finiteFieldFile,
    censusFile, outdir, artifactDirectory, resultFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex, putAtomic,
    exportAtomic, fail, tag, result, badHashes, census, sourceVariables,
    regulator, strip, rootSquares, frameVariables, frame, allRoots,
    classification, chart, solveResult, solveSeconds, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  censusFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_14_dependency_closed_local_channel_census_v1_retry/census.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_21_14_kallen3_source_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  resultFile = FileNameJoin[{outdir, "solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032114Kallen3SourceSolveV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    censusFile ->
      "b22b2a5bad42605aed549b5fb17872a10d2a8045a9cfce5dd71becac14b263b3"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile,
    "FiniteFieldStripSolve" -> finiteFieldFile|>;

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
  fail[status_String, data_: <||>] := Module[{failureFile, failure},
    failure = Join[<|"Status" -> status, "Family" -> "CF303",
      "Sector" -> 21, "LowerSector" -> 14,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 21->14 KALLEN3 SOURCE SOLVE FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]];

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["PoolWorkerRequired"]];
    If[Length[Kernels[]] =!= 0,
      fail["MissionWorkerAlreadyOwnsNestedKernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 4),
      fail["HelperCeilingMustBeFour"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    CreateDirectory[artifactDirectory];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];

    census = Import[censusFile, "WXF"];
    If[! AssociationQ[census] ||
        Lookup[census, "Status", None] =!=
          "CF303Sector2114DependencyClosedLocalChannelCensusPassedV1" ||
        Lookup[census, "ForcingRootIndices", None] =!= {2} ||
        Lookup[census, "StripRootIndices", None] =!= {2} ||
        Lookup[census, "SelectedRoute", None] =!= "Kallen3" ||
        ! And @@ Values[Lookup[census, "Checks", <||>]],
      fail["InvalidDependencyClosedCensusABI"]];
    sourceVariables = census["Variables"];
    regulator = census["Regulator"];
    strip = census["Strip"];
    If[! MatchQ[sourceVariables, {_Symbol, _Symbol}] ||
        ! MatchQ[regulator, _Symbol] || Dimensions[strip] =!= {3, 2, 2, 2} ||
        ! TrueQ[census["AssembledForcing"] === strip[[3]]],
      fail["InvalidPinnedStripShape"]];
    rootSquares = {
      1 + 2 sourceVariables[[1]] + sourceVariables[[1]]^2 -
        2 sourceVariables[[2]] +
        2 sourceVariables[[1]] sourceVariables[[2]] +
        sourceVariables[[2]]^2,
      1 - 2 sourceVariables[[1]] + sourceVariables[[1]]^2 +
        2 sourceVariables[[2]] +
        2 sourceVariables[[1]] sourceVariables[[2]] +
        sourceVariables[[2]]^2,
      1 - 4 sourceVariables[[1]] sourceVariables[[2]]};
    frameVariables = {Symbol["CF303Sector2114Kallen3`p"],
      Symbol["CF303Sector2114Kallen3`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, sourceVariables, frameVariables];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, sourceVariables];
    classification = FeynFacet`Private`transportChartRootIndices[
      strip, allRoots];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
          "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]] ||
        ! AssociationQ[classification] ||
        classification["RootIndices"] =!= {2} ||
        classification["UnclassifiedRadicalBases"] =!= {},
      fail["ExactFrameOrRootCensusFailed", <|
        "Classification" -> classification|>]];
    chart = FeynFacet`TransportRootSetChart[
      rootSquares[[classification["RootIndices"]]], sourceVariables];
    If[! AssociationQ[chart] || Lookup[chart, "Name", None] =!= "Kallen3" ||
        ! TrueQ[Lookup[FeynFacet`TransportChartVerify[chart], "OK", False]],
      fail["Kallen3ChartNotExactlySelected"]];

    Print["CF3032114K3V1 stage=solve stripLeaves=", LeafCount[strip]];
    solveSeconds = First@AbsoluteTiming[
      solveResult = FeynFacet`SolveEpsFormStripInFrame[
        strip, sourceVariables, regulator, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldFallback" -> True,
        "MultiquadraticDispatch" -> False,
        "CANONICAKernels" -> 5,
        "ScratchDirectory" -> outdir,
        "Tag" -> "CF303_21_14_kallen3_source_v1",
        "FiniteFieldOptions" -> {
          "KernelCount" -> 5,
          "ArtifactDirectory" -> artifactDirectory,
          "ArtifactPrefix" -> "CF303_21_14_kallen3_source_v1",
          "Backend" -> Automatic, "BackendThreads" -> 1,
          "PlanDiscoveryBackend" -> "FLINTAffineRREF",
          "SupportStrategy" -> "SimplexFirst",
          "SupportLearning" -> True,
          "RegulatorSampling" -> "HeldOut",
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "Verbose" -> True]];
    checks = <|
      "DependencyClosedCensusPassed" ->
        And @@ Values[census["Checks"]],
      "SolvedStatus" -> AssociationQ[solveResult] &&
        Lookup[solveResult, "Status", None] === "Solved",
      "OnlySecondRootUsed" ->
        Lookup[solveResult, "RootIndices", None] === {2},
      "Kallen3Method" -> StringStartsQ[
        Lookup[solveResult, "Method", ""], "RationalChart/Kallen3/"],
      "ExactDLog" -> TrueQ[Lookup[solveResult, "ExactDLog", False]],
      "GaugeDimensionsExact" ->
        Dimensions[Lookup[solveResult, "Gauge", {}]] === {2, 2},
      "GaugeRoundTrip" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "GaugeRoundTrip", False]],
      "TransformedOneFormPullBack" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "TransformedOneFormPullBack", False]],
      "SourceDLog" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "SourceDLog", False]],
      "FrameCertificateExact" -> TrueQ[Lookup[
        Lookup[solveResult, "FrameCertificate", <||>],
        "Exact", False]],
      "AlphabetEpsilonFree" ->
        FreeQ[Lookup[solveResult, "Alphabet", {}], regulator]|>;
    If[! And @@ Values[checks],
      fail["Kallen3SourceSolveFailed", <|
        "Checks" -> checks,
        "Result" -> If[AssociationQ[solveResult],
          KeyDrop[solveResult, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], solveResult]|>]];

    exportAtomic[<|
      "Status" -> "CF303Sector2114Kallen3SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 14,
      "SourceStrip" -> strip, "SourceSolution" -> solveResult,
      "Checks" -> checks, "SolveSeconds" -> solveSeconds,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    summary = <|
      "Status" -> "CF303Sector2114Kallen3SourceSolvedV1",
      "Family" -> "CF303", "Sector" -> 21, "LowerSector" -> 14,
      "Method" -> solveResult["Method"],
      "RootIndices" -> solveResult["RootIndices"],
      "GaugeDimensions" -> Dimensions[solveResult["Gauge"]],
      "GaugeLeafCount" -> LeafCount[solveResult["Gauge"]],
      "AlphabetLength" -> Length[Lookup[solveResult, "Alphabet", {}]],
      "SolveSeconds" -> solveSeconds, "Checks" -> checks,
      "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032114K3V1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " method=", solveResult["Method"]];
    0,
    tag];
  result
]
