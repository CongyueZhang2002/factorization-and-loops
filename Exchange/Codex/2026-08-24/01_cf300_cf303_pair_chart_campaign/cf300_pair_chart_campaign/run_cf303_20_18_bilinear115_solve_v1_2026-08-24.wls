#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, finiteFieldFile,
    stateFile, outdir, artifactDirectory, resultFile, summaryFile,
    expectedHashes, dependencyFiles, dependencyHashes, hashHex,
    putAtomic, exportAtomic, fail, tag, result, badHashes, state, ranges,
    connection, sourceVariables, regulator, rowRange, lowerRange,
    rootSquares, frameChartVariables, frame, strip, currentRoots,
    classification, solveResult, solveSeconds, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  finiteFieldFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "FiniteFieldStripSolve.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_bilinear115_solve_v1";
  artifactDirectory = FileNameJoin[{outdir, "finite_field"}];
  resultFile = FileNameJoin[{outdir, "solution.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018Bilinear115SolveV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    finiteFieldFile ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "MultiquadraticStripSolve" -> multiquadraticFile,
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
      "Sector" -> 20, "LowerSector" -> 18,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 20->18 BILINEAR115 SOLVE FAILURE V1: ", status,
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
    Print["CF3032018B115V1 stage=load"];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    state = Get[stateFile];
    If[! AssociationQ[state], fail["InvalidPinnedStateABI"]];
    ranges = state["Ranges"];
    connection = state["A"];
    sourceVariables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[20]];
    lowerRange = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {35, 36} || lowerRange =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];
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
    frameChartVariables = {
      Symbol["CF303SourceFrame`p"], Symbol["CF303SourceFrame`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, sourceVariables, frameChartVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["SourceMultiquadraticFrameFailed"]];
    strip = {
      connection[[All, rowRange, rowRange]]/regulator,
      connection[[All, lowerRange, lowerRange]]/regulator,
      connection[[All, rowRange, lowerRange]]};
    currentRoots = FeynFacet`Private`transportChartCurrentRoots[
      frame, sourceVariables];
    classification = FeynFacet`Private`transportChartRootIndices[
      strip, currentRoots];
    If[! ListQ[currentRoots] ||
        Lookup[classification, "RootIndices", None] =!= {3} ||
        Lookup[classification, "UnclassifiedRadicalBases", {1}] =!= {},
      fail["UnexpectedActiveRootSet", <|
        "Classification" -> classification|>]];

    Print["CF3032018B115V1 stage=solve"];
    solveSeconds = First@AbsoluteTiming[
      solveResult = FeynFacet`SolveEpsFormStripInFrame[
        strip, sourceVariables, regulator, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldFallback" -> True,
        "CANONICAKernels" -> 5,
        "ScratchDirectory" -> outdir,
        "Tag" -> "CF303_20_18_bilinear115_v1",
        "FiniteFieldOptions" -> {
          "KernelCount" -> 5,
          "ArtifactDirectory" -> artifactDirectory,
          "ArtifactPrefix" -> "CF303_20_18_bilinear115_v1",
          "Backend" -> Automatic, "BackendThreads" -> 1,
          "PlanDiscoveryBackend" -> "FLINTAffineRREF",
          "SupportStrategy" -> "SimplexFirst",
          "SupportLearning" -> True,
          "RegulatorSampling" -> "HeldOut",
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "Verbose" -> True]];
    checks = <|
      "SolvedStatus" -> AssociationQ[solveResult] &&
        Lookup[solveResult, "Status", None] === "Solved",
      "Bilinear115Route" -> StringContainsQ[
        ToString[Lookup[solveResult, "Method", ""]], "Bilinear115"],
      "OnlyThirdRootUsed" ->
        Lookup[solveResult, "RootIndices", None] === {3},
      "ExactDLog" -> TrueQ[Lookup[solveResult, "ExactDLog", False]],
      "GaugeDimensions" ->
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
        "Exact", False]]|>;
    exportAtomic[<|
      "Status" -> If[And @@ Values[checks],
        "CF303Sector2018Bilinear115SolvedV1",
        "CF303Sector2018Bilinear115FailedV1"],
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Checks" -> checks, "SolveSeconds" -> solveSeconds,
      "SourceStrip" -> strip, "Frame" -> frame,
      "Solution" -> solveResult,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, resultFile];
    If[! And @@ Values[checks],
      fail["Bilinear115SolveNotExactlyCertified", <|
        "Checks" -> checks, "SolveSeconds" -> solveSeconds,
        "ResultSummary" -> If[AssociationQ[solveResult],
          KeyDrop[solveResult, {"Gauge", "ResidueMatrices",
            "EliminationPlan"}], solveResult]|>]];
    summary = <|
      "Status" -> "CF303Sector2018Bilinear115SolvedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "Method" -> solveResult["Method"],
      "RootIndices" -> solveResult["RootIndices"],
      "RootSquares" -> solveResult["RootSquares"],
      "GaugeDimensions" -> Dimensions[solveResult["Gauge"]],
      "GaugeLeafCount" -> LeafCount[solveResult["Gauge"]],
      "AlphabetLength" -> Length[Lookup[solveResult, "Alphabet", {}]],
      "ExactDLog" -> solveResult["ExactDLog"],
      "FrameCertificate" -> solveResult["FrameCertificate"],
      "SolveSeconds" -> solveSeconds,
      "ResultFile" -> resultFile,
      "ResultSHA256" -> hashHex[resultFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringSolve"]];
    Print["CF3032018B115V1 status=PASS seconds=",
      Round[solveSeconds, 0.1], " method=", solveResult["Method"]];
    0,
    tag];
  result
]
