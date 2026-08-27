#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, transportFile, stateFile, solutionFile,
    outdir, censusFile, summaryFile, expectedHashes, dependencyFiles,
    dependencyHashes, hashHex, putAtomic, exportAtomic, fail, tag, result,
    badHashes, state, solutionPayload, solution, ranges, connection,
    variables, regulator, rowRange, range18, rootSquares,
    frameVariables, frame, allRoots, gauge2018, rootCensus, zeroPairQ,
    records, upperDiagonal, upperCensus, gaugeCensus, j, lowerRange,
    rawDirect, row18Connection, forcing, lowerDiagonal, rawDirectCensus,
    row18Census, forcingCensus, lowerCensus, strip, stripCensus,
    activeRootSquares, chart, route, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  transportFile = FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
    "TransportCharts.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  solutionFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_bilinear115_solve_v1/solution.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector20_post18_frontier_census_v1";
  censusFile = FileNameJoin[{outdir, "census.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector20Post18FrontierCensusV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    transportFile ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    solutionFile ->
      "687cc3815fd18be7e3a5a9f4f9ad893e7062012366fdab66a33faea88681ef9f"|>;
  dependencyFiles = <|"LoadFACET" -> loadFile,
    "TransportCharts" -> transportFile|>;

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
      "Sector" -> 20, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 SECTOR20 POST18 CENSUS FAILURE V1: ", status,
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
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["HelperCeilingMustBeZero"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    dependencyHashes = Map[hashHex, dependencyFiles];
    Get[loadFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringLoad"]];
    state = Get[stateFile];
    solutionPayload = Import[solutionFile, "WXF"];
    If[! AssociationQ[state] || ! AssociationQ[solutionPayload] ||
        Lookup[solutionPayload, "Status", None] =!=
          "CF303Sector2018Bilinear115SolvedV1",
      fail["InvalidInputABI"]];
    solution = Lookup[solutionPayload, "Solution", $Failed];
    If[! AssociationQ[solution] ||
        Lookup[solution, "Status", None] =!= "Solved" ||
        Lookup[solution, "RootIndices", None] =!= {3} ||
        ! TrueQ[Lookup[solution, "ExactDLog", False]] ||
        ! TrueQ[Lookup[Lookup[solution, "FrameCertificate", <||>],
          "Exact", False]],
      fail["Pinned2018SolutionNotExact"]];
    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[20]];
    range18 = ranges[[18]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {35, 36} || range18 =!= {29, 30},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Post18Census`p"],
      Symbol["CF303Post18Census`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["SourceMultiquadraticFrameFailed"]];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    If[! ListQ[allRoots] || Length[allRoots] =!= 3,
      fail["InvalidCurrentRoots"]];
    rootCensus[expression_] := Module[{census},
      census = FeynFacet`Private`transportChartRootIndices[
        expression, allRoots];
      If[! AssociationQ[census] ||
          Lookup[census, "UnclassifiedRadicalBases", {1}] =!= {},
        fail["UnclassifiedRadical", <|"Census" -> census|>]];
      census];
    zeroPairQ[pair_] := AllTrue[Flatten[Map[Together, pair, {3}]],
      TrueQ[# === 0] &];

    gauge2018 = Map[Together, solution["Gauge"], {2}];
    If[Dimensions[gauge2018] =!= {2, 2},
      fail["Unexpected2018GaugeShape"]];
    gaugeCensus = rootCensus[gauge2018];
    upperDiagonal = connection[[All, rowRange, rowRange]]/regulator;
    upperCensus = rootCensus[upperDiagonal];
    records = Table[
      lowerRange = ranges[[j]];
      rawDirect = connection[[All, rowRange, lowerRange]];
      row18Connection = connection[[All, range18, lowerRange]];
      forcing = Table[Map[Together,
        rawDirect[[mu]] - gauge2018 . row18Connection[[mu]], {2}],
        {mu, 2}];
      lowerDiagonal = connection[[All, lowerRange, lowerRange]]/regulator;
      rawDirectCensus = rootCensus[rawDirect];
      row18Census = rootCensus[row18Connection];
      forcingCensus = rootCensus[forcing];
      lowerCensus = rootCensus[lowerDiagonal];
      strip = {upperDiagonal, lowerDiagonal, forcing};
      stripCensus = rootCensus[strip];
      activeRootSquares = Lookup[
        allRoots[[Lookup[stripCensus, "RootIndices", {}]]],
        "RootSquare", {}];
      chart = If[zeroPairQ[forcing], None,
        FeynFacet`TransportRootSetChart[activeRootSquares, variables]];
      route = If[zeroPairQ[forcing], "ZeroForcing",
        If[AssociationQ[chart], Lookup[chart, "Name", "UnnamedChart"],
          "NoJointRationalChart"]];
      <|"LowerSector" -> j, "Dimensions" ->
          Dimensions[forcing[[1]]],
        "RawDirectZero" -> zeroPairQ[rawDirect],
        "Row18ConnectionZero" -> zeroPairQ[row18Connection],
        "AssembledForcingZero" -> zeroPairQ[forcing],
        "RawDirectRootIndices" -> rawDirectCensus["RootIndices"],
        "Row18ConnectionRootIndices" -> row18Census["RootIndices"],
        "AssembledForcingRootIndices" -> forcingCensus["RootIndices"],
        "LowerDiagonalRootIndices" -> lowerCensus["RootIndices"],
        "DependencyClosedStripRootIndices" -> stripCensus["RootIndices"],
        "Route" -> route, "ForcingLeafCount" -> LeafCount[forcing],
        "StripLeafCount" -> LeafCount[strip]|>,
      {j, 17, 1, -1}];
    checks = <|
      "Gauge2018UsesOnlyThirdRoot" ->
        gaugeCensus["RootIndices"] === {3},
      "UpperDiagonalUsesOnlyThirdRoot" ->
        upperCensus["RootIndices"] === {3},
      "Block2017ForcingExactlyZero" -> TrueQ[
        Lookup[SelectFirst[records,
          Lookup[#, "LowerSector", None] === 17 &, <||>],
          "AssembledForcingZero", False]],
      "AllCensusesClassified" -> AllTrue[records,
        ListQ[Lookup[#, "DependencyClosedStripRootIndices", None]] &]|>;
    If[! And @@ Values[checks],
      fail["CensusChecksFailed", <|"Checks" -> checks|>]];
    exportAtomic[<|
      "Status" -> "CF303Sector20Post18FrontierCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "InstalledGaugeSectors" -> {18}, "Gauge2018" -> gauge2018,
      "Gauge2018Census" -> gaugeCensus,
      "UpperDiagonalCensus" -> upperCensus,
      "Records" -> records, "Checks" -> checks,
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, censusFile];
    summary = <|
      "Status" -> "CF303Sector20Post18FrontierCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 20,
      "InstalledGaugeSectors" -> {18},
      "NonzeroForcingSectors" -> Lookup[
        Select[records, ! TrueQ[Lookup[#, "AssembledForcingZero", True]] &],
        "LowerSector", {}],
      "ZeroForcingSectors" -> Lookup[
        Select[records, TrueQ[Lookup[#, "AssembledForcingZero", False]] &],
        "LowerSector", {}],
      "Routes" -> Map[KeyTake[#, {"LowerSector", "AssembledForcingZero",
          "DependencyClosedStripRootIndices", "Route", "StripLeafCount"}] &,
        records],
      "Checks" -> checks, "CensusFile" -> censusFile,
      "CensusSHA256" -> hashHex[censusFile],
      "InputHashes" -> expectedHashes,
      "DependencyHashes" -> dependencyHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    If[Map[hashHex, dependencyFiles] =!= dependencyHashes,
      fail["PackageChangedDuringCensus"]];
    Print["CF303S20POST18CENSUSV1 status=PASS routes=",
      Lookup[summary, "Routes", {}]];
    0,
    tag];
  result
]
