#!/usr/bin/env wolframscript

$HistoryLength = 0;
Module[
  {expectedDispatchKernelID = 24, actualDispatchKernelID,
   taskBrokerMaxHelpers, nestedKernelsAtEntry, outerPoolKernelCount,
   arguments, projectRoot, v6dArtifactFile, prerequisiteFile,
   heldParseArtifactFile, outputFile, receiptFile, admissionDirectory,
   exactDirectory, heldParseGateFile, heldParseArtifact,
   heldParseArtifactHashBefore, heldParseArtifactHashAfter,
   heldParseGateHashBefore, heldParseGateHashAfter, heldParseEvidenceValid,
   files, expectedHashes, hashesBefore, hashesAfter,
   heldExpectedHashes,
   wrapperHashBefore, wrapperHashAfter, prerequisiteHashBefore,
   prerequisiteHashAfter, maximumCertificateBytes = 2^30,
   maximumReceiptBytes = 2^24, deleteIfPresent, writeReceiptAtomic,
   finish, readPinnedASCIIText, stripShebangExact, sourceText, parseText,
   transformedText,
   exitCount, ceilingPattern, ceilingReplacement, rereadPattern,
   rereadReplacement, transformedHash,
   expectedTransformedHash =
    "0b71743d40da509bef35cbadbae0df5f27263ce7ff6b283e9c481a91e89a8f66",
   splitContextLines, heldParseRecord, heldParsePassed,
   driverCode, outputExists, outputFileByteCount, outputHash,
   outputAssociation, outputStatus, sourceStable, prerequisiteStable,
   admissionStateStable, passed, failureReason, rollbackPerformed = False,
   receipt, trackedContexts, namesBefore, namesAfter, newNames,
   removeByFullName, parseContext, parsed, parserMessages,
   syntaxLength, cleanupPassed},

  (* Admission is checked before argument parsing or source I/O. *)
  actualDispatchKernelID = System`$KernelID;
  taskBrokerMaxHelpers = Quiet[Check[
    KernelPoolMission`$TaskBrokerMaxHelpers, $Failed]];
  nestedKernelsAtEntry = System`Kernels[];
  outerPoolKernelCount = System`$KernelCount;
  If[actualDispatchKernelID =!= expectedDispatchKernelID ||
      ! TrueQ[taskBrokerMaxHelpers === 0] ||
      nestedKernelsAtEntry =!= {},
    Print["CF300_EXACT_QEPS_ADMISSION FAIL preflight",
      " expected_kernel=", expectedDispatchKernelID,
      " actual_kernel=", actualDispatchKernelID,
      " broker_max_helpers=", InputForm[taskBrokerMaxHelpers],
      " nested_kernels=", InputForm[nestedKernelsAtEntry]];
    Return[$Failed]];

  arguments = Rest[$ScriptCommandLine];
  If[Length[arguments] =!= 6,
    Print["CF300_EXACT_QEPS_ADMISSION FAIL usage=<project-root> " <>
      "<v6d-result.wl> <captured-prerequisite.wl> " <>
      "<passed-held-parse-artifact.wl> <fresh-certificate-output.wl> " <>
      "<fresh-admission-receipt.wl>"];
    Return[$Failed]];
  projectRoot = ExpandFileName[arguments[[1]]];
  v6dArtifactFile = ExpandFileName[arguments[[2]]];
  prerequisiteFile = ExpandFileName[arguments[[3]]];
  heldParseArtifactFile = ExpandFileName[arguments[[4]]];
  outputFile = ExpandFileName[arguments[[5]]];
  receiptFile = ExpandFileName[arguments[[6]]];
  admissionDirectory = DirectoryName[$InputFileName];
  heldParseGateFile = FileNameJoin[{admissionDirectory,
    "held_parse_cf300_exact_qeps_runtime_admission_v2_xh.wls"}];
  exactDirectory = FileNameJoin[{DirectoryName[admissionDirectory],
    "exact_qeps_left_obstruction_xh"}];

  files = <|
    "FrozenDriver" -> FileNameJoin[{exactDirectory,
      "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"}],
    "ExactHelper" -> FileNameJoin[{exactDirectory,
      "CF300ExactQepsLeftObstruction.wl"}],
    "ModularReconstruction" -> FileNameJoin[{exactDirectory,
      "CF300ModularQepsWitnessReconstruction.wl"}],
    "PrerequisiteSchema" -> FileNameJoin[{exactDirectory,
      "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"}],
    "FrozenManifest" -> FileNameJoin[{exactDirectory,
      "SHA256SUMS_EXACT_QEPS_LEFT_OBSTRUCTION_V1"}],
    "KpSubmit" -> FileNameJoin[{projectRoot, "Scripts", "kpsubmit.sh"}],
    "V6dArtifact" -> v6dArtifactFile|>;
  expectedHashes = <|
    "FrozenDriver" ->
      "446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174",
    "ExactHelper" ->
      "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
    "ModularReconstruction" ->
      "0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce",
    "PrerequisiteSchema" ->
      "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
    "FrozenManifest" ->
      "642fb0b403c1c68e04e9943945e32b3b66b923265e50777c3fef3da85e451757",
    "KpSubmit" ->
      "138315a11149c14fc3491a008e6e7ad4d23623d29a2228fbdea31d4384707ddc",
    "V6dArtifact" ->
      "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf"|>;

  deleteIfPresent[file_String] := Module[{},
    If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
    ! FileExistsQ[file]];
  writeReceiptAtomic[value_Association] := Module[
    {temporary, written, renamed, reread},
    If[FileExistsQ[receiptFile] || ByteCount[value] > maximumReceiptBytes,
      Return[$Failed]];
    temporary = receiptFile <> ".tmp-" <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = CheckAbort[Quiet[Check[Put[value, temporary], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[written === $Failed || ! FileExistsQ[temporary] ||
        FileByteCount[temporary] > maximumReceiptBytes,
      deleteIfPresent[temporary]; Return[$Failed]];
    renamed = CheckAbort[Quiet[Check[RenameFile[temporary, receiptFile,
      OverwriteTarget -> False], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[renamed === $Failed || ! FileExistsQ[receiptFile] ||
        FileExistsQ[temporary] ||
        FileByteCount[receiptFile] > maximumReceiptBytes,
      deleteIfPresent[temporary]; deleteIfPresent[receiptFile];
      Return[$Failed]];
    reread = Quiet[Check[Get[receiptFile], $Failed]];
    If[! SameQ[reread, value],
      deleteIfPresent[receiptFile]; Return[$Failed]];
    receiptFile];
  finish[value_Association, successQ_] := Module[{written},
    written = writeReceiptAtomic[value];
    If[written === $Failed,
      If[TrueQ[successQ],
        rollbackPerformed = deleteIfPresent[outputFile]];
      Print["CF300_EXACT_QEPS_ADMISSION FAIL receipt_atomic_write",
        " certificate_rollback=", rollbackPerformed];
      Return[$Failed]];
    If[TrueQ[successQ],
      Print["CF300_EXACT_QEPS_ADMISSION PASS output=", outputFile,
        " receipt=", receiptFile],
      Print["CF300_EXACT_QEPS_ADMISSION FAIL reason=",
        Lookup[value, "FailureReason", "Unknown"],
        " driver_code=", Lookup[value, "DriverCode", "Unknown"],
        " output_status=", Lookup[value, "DriverOutputStatus", "Missing"],
        " receipt=", receiptFile]];
    If[TrueQ[successQ], 0, $Failed]];

  If[! DirectoryQ[projectRoot] || ! FileExistsQ[prerequisiteFile] ||
      ! FileExistsQ[heldParseArtifactFile] ||
      ! FileExistsQ[heldParseGateFile] ||
      ! DirectoryQ[DirectoryName[outputFile]] ||
      ! DirectoryQ[DirectoryName[receiptFile]] ||
      outputFile === receiptFile || FileExistsQ[outputFile] ||
      FileExistsQ[receiptFile] || ! AllTrue[Values[files], FileExistsQ],
    Print["CF300_EXACT_QEPS_ADMISSION FAIL missing_input_or_stale_output"];
    Return[$Failed]];

  wrapperHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
  prerequisiteHashBefore = FileHash[prerequisiteFile,
    "SHA256", "HexString"];
  heldParseArtifactHashBefore = FileHash[heldParseArtifactFile,
    "SHA256", "HexString"];
  heldParseGateHashBefore = FileHash[heldParseGateFile,
    "SHA256", "HexString"];
  hashesBefore = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  If[hashesBefore =!= expectedHashes,
    Print["CF300_EXACT_QEPS_ADMISSION FAIL immutable_hash_pin observed=",
      InputForm[hashesBefore]];
    Return[$Failed]];
  heldExpectedHashes = <|
    "AdmissionDriver" -> wrapperHashBefore,
    "FrozenDriver" -> expectedHashes["FrozenDriver"],
    "ExactHelper" -> expectedHashes["ExactHelper"],
    "ModularReconstruction" -> expectedHashes["ModularReconstruction"],
    "PrerequisiteSchema" -> expectedHashes["PrerequisiteSchema"]|>;
  heldParseArtifact = Quiet[Check[Get[heldParseArtifactFile], $Failed]];
  heldParseEvidenceValid = TrueQ[
    AssociationQ[heldParseArtifact] &&
    Lookup[heldParseArtifact, "Status", None] ===
      "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH" &&
    TrueQ[Lookup[heldParseArtifact, "AllPassed", False]] &&
    Lookup[heldParseArtifact, "ExpectedDispatchKernelID", None] === 24 &&
    Lookup[heldParseArtifact, "DispatchKernelID", None] === 24 &&
    Lookup[heldParseArtifact, "TaskBrokerMaxHelpers", None] === 0 &&
    Lookup[heldParseArtifact, "NestedKernelCountAtEntry", None] === 0 &&
    Lookup[heldParseArtifact, "GateSHA256", None] ===
      heldParseGateHashBefore &&
    Lookup[heldParseArtifact, "SourceHashesBefore", <||>] ===
      heldExpectedHashes &&
    Lookup[heldParseArtifact, "SourceHashesAfter", <||>] ===
      heldExpectedHashes &&
    Length[Lookup[heldParseArtifact, "ParseRecords", <||>]] === 5 &&
    AllTrue[Values[Lookup[heldParseArtifact, "ParseRecords", <||>]],
      TrueQ[Lookup[#1, "Passed", False]] &]];
  If[! heldParseEvidenceValid,
    Print["CF300_EXACT_QEPS_ADMISSION FAIL held_parse_evidence"];
    Return[$Failed]];

  readPinnedASCIIText[file_String] := Module[{bytes},
    bytes = Quiet[Check[BinaryReadList[file, "Byte"], $Failed]];
    If[! ListQ[bytes] || ! VectorQ[bytes,
        Function[byte, IntegerQ[byte] && 0 <= byte <= 127]],
      Return[$Failed]];
    FromCharacterCode[bytes]];
  stripShebangExact[text_String] := Module[{newlinePosition},
    If[! StringStartsQ[text, "#!"], Return[text]];
    newlinePosition = StringPosition[text, "\n", 1];
    If[newlinePosition === {}, "",
      StringDrop[text, Last[First[newlinePosition]]]]];
  sourceText = readPinnedASCIIText[files["FrozenDriver"]];
  If[! StringQ[sourceText] || ! StringEndsQ[sourceText, "\n"],
    Print["CF300_EXACT_QEPS_ADMISSION FAIL driver_binary_read_or_terminal_lf"];
    Return[$Failed]];
  parseText = stripShebangExact[sourceText];
  exitCount = StringCount[parseText, "Exit["];
  ceilingPattern =
    "If[FileExistsQ[outputFile], Return[$Failed]];";
  ceilingReplacement =
    "If[FileExistsQ[outputFile] || ByteCount[value] > 2^30,\n" <>
    "    Return[$Failed]];";
  rereadPattern =
    "reread = Quiet[Check[Get[outputFile], $Failed]];";
  rereadReplacement =
    "If[FileByteCount[outputFile] > 2^30,\n" <>
    "    deleteIfPresent[outputFile]; Return[$Failed]];\n" <>
    "  reread = Quiet[Check[Get[outputFile], $Failed]];";
  If[exitCount =!= 4 || StringCount[parseText, ceilingPattern] =!= 1 ||
      StringCount[parseText, rereadPattern] =!= 1,
    Print["CF300_EXACT_QEPS_ADMISSION FAIL transform_precondition"];
    Return[$Failed]];
  transformedText = StringReplace[parseText, {
    "Exit[" -> "Throw[", ceilingPattern -> ceilingReplacement,
    rereadPattern -> rereadReplacement}];
  transformedHash = Hash[transformedText, "SHA256", "HexString"];
  If[transformedHash =!= expectedTransformedHash ||
      StringCount[transformedText, "Exit["] =!= 0 ||
      StringCount[transformedText, "Throw["] < 4 ||
      ! StringContainsQ[transformedText,
        "ByteCount[value] > 2^30"] ||
      ! StringContainsQ[transformedText,
        "FileByteCount[outputFile] > 2^30"],
    Print["CF300_EXACT_QEPS_ADMISSION FAIL transformed_driver_pin hash=",
      transformedHash];
    Return[$Failed]];

  splitContextLines = Pick[Range[Length[StringSplit[transformedText, "\n"]]],
    StringEndsQ[StringTrim[#1], "`"] & /@
      StringSplit[transformedText, "\n"]];
  trackedContexts = {"Global`",
    "CodexCF300ExactQepsLeftObstructionDriverV1`",
    "CodexCF300ExactQepsLeftObstructionDriverV1`Private`",
    "CodexCF300ExactQepsLeftObstruction`",
    "CodexCF300ModularQepsWitnessReconstruction`",
    "CodexDirectRootChannelAssembler`"};
  namesBefore = AssociationMap[System`Names[#1 <> "*"] &,
    trackedContexts];
  parseContext = "CodexCF300ExactAdmissionParse`c" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  removeByFullName[name_String] := ToExpression[name, InputForm,
    Function[heldSymbol, Quiet[System`Remove[heldSymbol]], HoldAll]];
  parserMessages = {};
  Block[{$Context = parseContext, $ContextPath = {"System`"},
      $MessageList = {}},
    parsed = Quiet[Check[
      ToExpression[transformedText, InputForm, HoldComplete], $Failed]];
    syntaxLength = Quiet[Check[SyntaxLength[transformedText], $Failed]];
    parserMessages = ToString[InputForm[#1]] & /@ $MessageList];
  heldParseRecord = <|
    "HoldCompleteExact" -> (Head[parsed] === HoldComplete),
    "SyntaxLength" -> syntaxLength,
    "CharacterCount" -> StringLength[transformedText],
    "SyntaxLengthExact" -> TrueQ[IntegerQ[syntaxLength] &&
      syntaxLength === StringLength[transformedText]],
    "ParserMessages" -> parserMessages,
    "SplitContextMarkerLines" -> splitContextLines|>;
  parsed =.;
  namesAfter = AssociationMap[System`Names[#1 <> "*"] &,
    trackedContexts];
  newNames = Flatten[MapThread[Complement,
    {Values[namesAfter], Values[namesBefore]}]];
  Scan[removeByFullName, newNames];
  Scan[removeByFullName, System`Names[parseContext <> "*"]];
  cleanupPassed = TrueQ[
    AssociationMap[System`Names[#1 <> "*"] &, trackedContexts] ===
      namesBefore && System`Names[parseContext <> "*"] === {}];
  heldParsePassed = TrueQ[
    heldParseRecord["HoldCompleteExact"] &&
    heldParseRecord["SyntaxLengthExact"] &&
    heldParseRecord["ParserMessages"] === {} &&
    splitContextLines === {} && cleanupPassed];
  If[! heldParsePassed,
    Print["CF300_EXACT_QEPS_ADMISSION FAIL transformed_held_parse record=",
      InputForm[heldParseRecord], " cleanup=", cleanupPassed];
    Return[$Failed]];

  (* The frozen driver always requests Exit; the source-pinned transform
     converts only those four requests to Throw so the persistent K24 worker
     survives and admission can validate/rollback its fresh output. *)
  driverCode = Catch[
    Block[{$ScriptCommandLine = {files["FrozenDriver"], projectRoot,
          v6dArtifactFile, prerequisiteFile, outputFile},
        $InputFileName = files["FrozenDriver"]},
      ToExpression[transformedText, InputForm]]];

  outputExists = FileExistsQ[outputFile];
  outputFileByteCount = If[outputExists,
    Quiet[Check[FileByteCount[outputFile], $Failed]], Missing["NoOutput"]];
  If[IntegerQ[outputFileByteCount] &&
      outputFileByteCount > maximumCertificateBytes,
    rollbackPerformed = deleteIfPresent[outputFile];
    outputExists = False];
  outputAssociation = If[outputExists,
    Quiet[Check[Get[outputFile], $Failed]], $Failed];
  outputStatus = If[AssociationQ[outputAssociation],
    Lookup[outputAssociation, "Status", Missing["Absent"]],
    Missing["Unreadable"]];
  outputHash = If[outputExists,
    Quiet[Check[FileHash[outputFile, "SHA256", "HexString"], $Failed]],
    Missing["NoOutput"]];
  hashesAfter = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  wrapperHashAfter = FileHash[$InputFileName, "SHA256", "HexString"];
  prerequisiteHashAfter = FileHash[prerequisiteFile,
    "SHA256", "HexString"];
  heldParseArtifactHashAfter = FileHash[heldParseArtifactFile,
    "SHA256", "HexString"];
  heldParseGateHashAfter = FileHash[heldParseGateFile,
    "SHA256", "HexString"];
  sourceStable = TrueQ[hashesAfter === hashesBefore === expectedHashes &&
    wrapperHashAfter === wrapperHashBefore];
  prerequisiteStable = TrueQ[
    prerequisiteHashAfter === prerequisiteHashBefore];
  heldParseEvidenceValid = TrueQ[heldParseEvidenceValid &&
    heldParseArtifactHashAfter === heldParseArtifactHashBefore &&
    heldParseGateHashAfter === heldParseGateHashBefore];
  admissionStateStable = TrueQ[
    System`$KernelID === expectedDispatchKernelID &&
    KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
    System`Kernels[] === {}];
  passed = TrueQ[driverCode === 0 && outputExists &&
    IntegerQ[outputFileByteCount] &&
    outputFileByteCount <= maximumCertificateBytes &&
    outputStatus ===
      "CF300Sector12ExactQepsLeftObstructionCertifiedV1" &&
    sourceStable && prerequisiteStable && heldParseEvidenceValid &&
    admissionStateStable];
  failureReason = Which[
    passed, None,
    driverCode =!= 0, "FrozenDriverNonzeroCode",
    rollbackPerformed, "CertificateOutputCeilingExceeded",
    ! outputExists, "CertificateOutputMissing",
    outputStatus =!=
      "CF300Sector12ExactQepsLeftObstructionCertifiedV1",
      "FrozenDriverDidNotCertify",
    ! sourceStable, "ImmutableSourceChangedDuringRun",
    ! prerequisiteStable, "PrerequisiteChangedDuringRun",
    ! heldParseEvidenceValid, "HeldParseEvidenceChangedDuringRun",
    ! admissionStateStable, "AdmissionStateChangedDuringRun",
    True, "UnknownAdmissionFailure"];
  If[! passed && outputStatus ===
      "CF300Sector12ExactQepsLeftObstructionCertifiedV1",
    rollbackPerformed = deleteIfPresent[outputFile];
    outputExists = False];
  receipt = <|
    "Status" -> If[passed,
      "CF300ExactQepsRuntimeAdmissionPassedV2XH",
      "CF300ExactQepsRuntimeAdmissionFailedV2XH"],
    "AdmissionPassed" -> passed,
    "FailureReason" -> failureReason,
    "ExpectedDispatchKernelID" -> expectedDispatchKernelID,
    "DispatchKernelID" -> actualDispatchKernelID,
    "TaskBrokerMaxHelpers" -> taskBrokerMaxHelpers,
    "OuterPoolKernelCount" -> outerPoolKernelCount,
    "NestedKernelCountAtEntry" -> Length[nestedKernelsAtEntry],
    "NestedKernelsAtEntry" -> nestedKernelsAtEntry,
    "AdmissionStateStable" -> admissionStateStable,
    "FrozenDriverSHA256" -> expectedHashes["FrozenDriver"],
    "TransformedDriverSHA256" -> transformedHash,
    "SourceReadMode" -> "PinnedASCIIBytesPreserveTerminalLF",
    "FrozenDriverTerminalLFPresent" -> StringEndsQ[sourceText, "\n"],
    "TransformedDriverHeldParse" -> heldParseRecord,
    "TransformedParseCleanupPassed" -> cleanupPassed,
    "ContextBacktickSplitGuardPassed" -> (splitContextLines === {}),
    "HeldParseArtifactFile" -> heldParseArtifactFile,
    "HeldParseArtifactSHA256" -> heldParseArtifactHashBefore,
    "HeldParseGateSHA256" -> heldParseGateHashBefore,
    "HeldParseEvidenceValid" -> heldParseEvidenceValid,
    "DriverCode" -> driverCode,
    "DriverOutputFile" -> outputFile,
    "DriverOutputStatus" -> outputStatus,
    "DriverOutputSHA256" -> outputHash,
    "DriverOutputFileByteCount" -> outputFileByteCount,
    "MaximumCertificateBytes" -> maximumCertificateBytes,
    "MaximumReceiptBytes" -> maximumReceiptBytes,
    "OutputRollbackPerformed" -> rollbackPerformed,
    "PrerequisiteFile" -> prerequisiteFile,
    "PrerequisiteSHA256" -> prerequisiteHashBefore,
    "PrerequisiteStable" -> prerequisiteStable,
    "SourceHashesBefore" -> hashesBefore,
    "SourceHashesAfter" -> hashesAfter,
    "ImmutableSourcePinsStable" -> sourceStable,
    "AdmissionWrapperSHA256" -> wrapperHashBefore|>;
  finish[receipt, passed]
]
