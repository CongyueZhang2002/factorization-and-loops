#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{stateFile, expectedHash, outdir, state, stripSolvers, collectAlphabet,
    alphabetRecords, routeCounts, statusCounts, summary, summaryFile,
    hashHex, tag},
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/sector_state_CF303_identity_capture_xh_v4.wl";
  expectedHash =
    "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_strip_alphabets_v1";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF303StripAlphabetAuditV1$"];

  hashHex[file_String] := Quiet[Check[
    FileHash[file, "SHA256", "HexString"], Missing["HashFailed"]]];
  collectAlphabet[value_Association] := Join[
    If[KeyExistsQ[value, "Alphabet"],
      {KeyTake[value, {"Sector", "LowerSector", "Status", "Method", "Route",
        "CoefficientField", "Chart", "Alphabet", "ExtraLetters",
        "ExactDLog", "FrameFingerprint", "Fingerprint"}]}, {}],
    Flatten[collectAlphabet /@ Values[value], 1]];
  collectAlphabet[value_List] := Flatten[collectAlphabet /@ value, 1];
  collectAlphabet[_] := {};

  Catch[
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      Print["CF303ALPH failure=worker-contract"];
      Throw[$Failed, tag]];
    If[! FileExistsQ[stateFile] || hashHex[stateFile] =!= expectedHash,
      Print["CF303ALPH failure=state-hash-mismatch"];
      Throw[$Failed, tag]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      Print["CF303ALPH failure=output-exists"];
      Throw[$Failed, tag]];
    CreateDirectory[outdir];
    Print["CF303ALPH stage=load-state"];
    state = Quiet[CheckAbort[Get[stateFile], $Aborted]];
    If[! AssociationQ[state],
      Print["CF303ALPH failure=state-not-association"];
      Throw[$Failed, tag]];
    stripSolvers = Lookup[state, "StripSolvers", {}];
    alphabetRecords = DeleteDuplicates[collectAlphabet[stripSolvers], SameQ];
    routeCounts = Counts[Lookup[Select[stripSolvers, AssociationQ],
      "Route", Missing["Absent"]]];
    statusCounts = Counts[Lookup[Select[stripSolvers, AssociationQ],
      "Status", Missing["Absent"]]];
    summary = <|
      "Status" -> "CF303StripAlphabetAuditPassedV1",
      "StateFile" -> stateFile,
      "StateSHA256" -> expectedHash,
      "WorkerKernelID" -> $KernelID,
      "CurrentSector" -> Lookup[state, "Sector", Missing["Absent"]],
      "StripSolverCount" -> Length[stripSolvers],
      "RouteCounts" -> routeCounts,
      "StatusCounts" -> statusCounts,
      "AlphabetRecordCount" -> Length[alphabetRecords],
      "AlphabetRecords" -> alphabetRecords,
      "DistinctAlphabets" -> DeleteDuplicates[
        Lookup[alphabetRecords, "Alphabet", {}], SameQ],
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    Put[summary, summaryFile];
    Print["CF303ALPH status=PASS alphabetRecords=", Length[alphabetRecords],
      " distinct=", Length[summary["DistinctAlphabets"]],
      " summary=", summaryFile];
    0,
    tag]
]
