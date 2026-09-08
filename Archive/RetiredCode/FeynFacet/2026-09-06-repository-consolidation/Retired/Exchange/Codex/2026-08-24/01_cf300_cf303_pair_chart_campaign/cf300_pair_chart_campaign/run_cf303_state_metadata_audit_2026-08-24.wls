#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{stateFile, expectedHash, outdir, state, certificates, alphabetRecords,
    blockMetadata, stripSolverMetadata, regulatorMetadata, summary,
    reportFile, summaryFile, hashHex, safeKeys, smallValue, tag},
  stateFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1/sector_state_CF303_identity_capture_xh_v4.wl";
  expectedHash =
    "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_state_metadata_v1";
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  reportFile = FileNameJoin[{outdir, "report.txt"}];
  tag = Unique["CF303StateMetadataAuditV1$"];

  hashHex[file_String] := Quiet[Check[
    FileHash[file, "SHA256", "HexString"], Missing["HashFailed"]]];
  safeKeys[value_] := If[AssociationQ[value], Sort[Keys[value]], {}];
  smallValue[value_] := Which[
    AssociationQ[value], <|"Type" -> "Association", "Keys" -> safeKeys[value],
      "Length" -> Length[value]|>,
    ListQ[value], <|"Type" -> "List", "Length" -> Length[value],
      "Dimensions" -> Quiet[Check[Dimensions[value], Missing["Ragged"]]]|>,
    True, value];

  Catch[
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      Print["CF303META failure=not-pool-subkernel"];
      Throw[$Failed, tag]];
    If[Length[Kernels[]] =!= 0,
      Print["CF303META failure=nested-kernels-present"];
      Throw[$Failed, tag]];
    If[! FileExistsQ[stateFile] || hashHex[stateFile] =!= expectedHash,
      Print["CF303META failure=state-hash-mismatch"];
      Throw[$Failed, tag]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      Print["CF303META failure=output-exists"];
      Throw[$Failed, tag]];
    CreateDirectory[outdir];
    Print["CF303META stage=load-state"];
    state = Quiet[CheckAbort[Get[stateFile], $Aborted]];
    If[! AssociationQ[state],
      Print["CF303META failure=state-not-association"];
      Throw[$Failed, tag]];

    certificates = Lookup[state, "SectorCertificates", {}];
    alphabetRecords = DeleteDuplicates[Cases[
      certificates,
      association_Association /; KeyExistsQ[association, "Alphabet"] :>
        KeyTake[association, {"Sector", "LowerSector", "Status", "Method",
          "Route", "CoefficientField", "Chart", "Alphabet", "ExactDLog",
          "SourceDLog", "FrameFingerprint", "Fingerprint"}],
      {0, Infinity}], SameQ];
    blockMetadata = smallValue[Lookup[state, "Blocks", Missing["Absent"]]];
    stripSolverMetadata = smallValue[
      Lookup[state, "StripSolvers", Missing["Absent"]]];
    regulatorMetadata = smallValue[
      Lookup[state, "RegulatorFactorizations", Missing["Absent"]]];

    summary = <|
      "Status" -> "CF303StateMetadataAuditPassedV1",
      "StateFile" -> stateFile,
      "StateSHA256" -> expectedHash,
      "WorkerKernelID" -> $KernelID,
      "NestedKernelCount" -> Length[Kernels[]],
      "TopLevelKeys" -> Sort[Keys[state]],
      "CurrentSector" -> Lookup[state, "Sector", Missing["Absent"]],
      "SectorCertificateContainer" -> smallValue[certificates],
      "AlphabetRecordCount" -> Length[alphabetRecords],
      "AlphabetRecords" -> alphabetRecords,
      "DistinctAlphabets" -> DeleteDuplicates[
        Lookup[alphabetRecords, "Alphabet", {}], SameQ],
      "BlocksMetadata" -> blockMetadata,
      "StripSolversMetadata" -> stripSolverMetadata,
      "RegulatorFactorizationsMetadata" -> regulatorMetadata,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    Put[summary, summaryFile];
    Export[reportFile, ToString[summary, InputForm], "Text"];
    Print["CF303META status=PASS alphabets=", Length[alphabetRecords],
      " summary=", summaryFile];
    0,
    tag]
]
