#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, stateFile, outdir, auditFile,
    summaryFile, expectedHashes, hashHex, putAtomic, exportAtomic, fail,
    tag, result, badHashes, state, ranges, connection, variables, regulator,
    rowRange, rootSquares, frameVariables, frame, allRoots, rootCensus,
    zeroPairQ, diagonal, diagonalCensus, priorRecords, frontierRecords,
    k, lowerRange, block, census, checks, summary},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/" <>
    "sector_state_CF303_identity_capture_xh_v4.wl";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_sector21_prior_coupling_census_v1";
  auditFile = FileNameJoin[{outdir, "audit.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303Sector21PriorCouplingCensusV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06"|>;

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
      "Sector" -> 21, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, data];
    If[DirectoryQ[outdir],
      failureFile = FileNameJoin[{outdir,
        "failure_" <> StringReplace[CreateUUID[], "-" -> ""] <> ".wl"}];
      Quiet[Check[putAtomic[failure, failureFile], Null]]];
    Print["CF303 SECTOR21 PRIOR COUPLING CENSUS FAILURE V1: ", status,
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
    Get[loadFile];
    state = Get[stateFile];
    If[! AssociationQ[state], fail["InvalidStateABI"]];
    ranges = state["Ranges"];
    connection = state["A"];
    variables = {Symbol["Global`x"], Symbol["Global`y"]};
    regulator = Symbol["Global`eps"];
    rowRange = ranges[[21]];
    If[Dimensions[connection] =!= {2, 45, 45} ||
        rowRange =!= {37, 38},
      fail["UnexpectedPinnedStateShape"]];
    rootSquares = {
      1 + 2 variables[[1]] + variables[[1]]^2 - 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 2 variables[[1]] + variables[[1]]^2 + 2 variables[[2]] +
        2 variables[[1]] variables[[2]] + variables[[2]]^2,
      1 - 4 variables[[1]] variables[[2]]};
    frameVariables = {Symbol["CF303Sector21Census`p"],
      Symbol["CF303Sector21Census`q"]};
    frame = FeynFacet`BuildAlgebraicTransportFrame[
      rootSquares, variables, frameVariables];
    If[! AssociationQ[frame] || Lookup[frame, "Status", None] =!=
        "ExactFrame" || ! TrueQ[frame["ChartCertificate"]["OK"]],
      fail["SourceMultiquadraticFrameFailed"]];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
    rootCensus[expression_] := Module[{record},
      record = FeynFacet`Private`transportChartRootIndices[
        expression, allRoots];
      If[! AssociationQ[record] ||
          Lookup[record, "UnclassifiedRadicalBases", {1}] =!= {},
        fail["UnclassifiedRadical", <|"Census" -> record|>]];
      record];
    zeroPairQ[pair_] := AllTrue[Flatten[Map[Together, pair, {3}]],
      TrueQ[# === 0] &];
    diagonal = connection[[All, rowRange, rowRange]]/regulator;
    diagonalCensus = rootCensus[diagonal];
    priorRecords = Table[
      lowerRange = ranges[[k]];
      block = connection[[All, rowRange, lowerRange]];
      census = rootCensus[block];
      <|"LowerSector" -> k, "Dimensions" -> Dimensions[block[[1]]],
        "ExactlyZero" -> zeroPairQ[block],
        "RootIndices" -> census["RootIndices"],
        "LeafCount" -> LeafCount[block]|>,
      {k, 20, 17, -1}];
    frontierRecords = Table[
      lowerRange = ranges[[k]];
      block = connection[[All, rowRange, lowerRange]];
      census = rootCensus[block];
      <|"LowerSector" -> k, "Dimensions" -> Dimensions[block[[1]]],
        "ExactlyZero" -> zeroPairQ[block],
        "RootIndices" -> census["RootIndices"],
        "LeafCount" -> LeafCount[block]|>,
      {k, 20, 1, -1}];
    checks = <|
      "AllPriorRowsPresent" ->
        Lookup[priorRecords, "LowerSector", {}] === {20, 19, 18, 17},
      "AllCensusesClassified" -> AllTrue[frontierRecords,
        ListQ[Lookup[#, "RootIndices", None]] &]|>;
    If[! And @@ Values[checks],
      fail["CensusChecksFailed", <|"Checks" -> checks|>]];
    exportAtomic[<|
      "Status" -> "CF303Sector21PriorCouplingCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21,
      "DiagonalCensus" -> diagonalCensus,
      "PriorRowCouplings" -> priorRecords,
      "RawFrontier" -> frontierRecords, "Checks" -> checks,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, auditFile];
    summary = <|
      "Status" -> "CF303Sector21PriorCouplingCensusPassedV1",
      "Family" -> "CF303", "Sector" -> 21,
      "DiagonalRootIndices" -> diagonalCensus["RootIndices"],
      "PriorRowCouplings" -> priorRecords,
      "RawNonzeroFrontier" -> Select[frontierRecords,
        ! TrueQ[Lookup[#, "ExactlyZero", True]] &],
      "AuditFile" -> auditFile, "AuditSHA256" -> hashHex[auditFile],
      "Checks" -> checks, "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF303S21PRIORCENSUSV1 status=PASS diagonalRoots=",
      diagonalCensus["RootIndices"], " priorCouplings=", priorRecords];
    0,
    tag];
  result
]
