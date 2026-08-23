#!/usr/bin/env wolframscript

$HistoryLength = 0;
Module[
  {expectedDispatchKernelID = 24, actualDispatchKernelID,
   taskBrokerMaxHelpers, nestedKernelsAtEntry, outerPoolKernelCount,
   arguments, outputFile, admissionDirectory, exactDirectory,
   files, expectedHashes, hashesBefore, hashesAfter, gateHashBefore,
   gateHashAfter, maximumOutputBytes = 2^24, deleteIfPresent,
   writeAtomic, stripShebang, removeByFullName, trackedContexts,
   parseOne, records, allPassed, result},

  (* The K24/helper/nested-kernel guard precedes argument parsing and I/O. *)
  actualDispatchKernelID = System`$KernelID;
  taskBrokerMaxHelpers = Quiet[Check[
    KernelPoolMission`$TaskBrokerMaxHelpers, $Failed]];
  nestedKernelsAtEntry = System`Kernels[];
  outerPoolKernelCount = System`$KernelCount;
  If[actualDispatchKernelID =!= expectedDispatchKernelID ||
      ! TrueQ[taskBrokerMaxHelpers === 0] ||
      nestedKernelsAtEntry =!= {},
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL preflight",
      " expected_kernel=", expectedDispatchKernelID,
      " actual_kernel=", actualDispatchKernelID,
      " broker_max_helpers=", InputForm[taskBrokerMaxHelpers],
      " nested_kernels=", InputForm[nestedKernelsAtEntry]];
    Return[$Failed]];

  arguments = Rest[$ScriptCommandLine];
  If[Length[arguments] =!= 1,
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL usage=<fresh-output.wl>"];
    Return[$Failed]];
  outputFile = ExpandFileName[First[arguments]];
  admissionDirectory = DirectoryName[$InputFileName];
  exactDirectory = FileNameJoin[{DirectoryName[admissionDirectory],
    "exact_qeps_left_obstruction_xh"}];
  files = <|
    "AdmissionDriver" -> FileNameJoin[{admissionDirectory,
      "run_cf300_sector12_exact_qeps_admitted_xh.wls"}],
    "FrozenDriver" -> FileNameJoin[{exactDirectory,
      "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"}],
    "ExactHelper" -> FileNameJoin[{exactDirectory,
      "CF300ExactQepsLeftObstruction.wl"}],
    "ModularReconstruction" -> FileNameJoin[{exactDirectory,
      "CF300ModularQepsWitnessReconstruction.wl"}],
    "PrerequisiteSchema" -> FileNameJoin[{exactDirectory,
      "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"}]|>;
  expectedHashes = <|
    "AdmissionDriver" ->
      "a4cc4466c9844e8d4d49206b4fd7498a923f306ea3765812af72fa35e635a6f9",
    "FrozenDriver" ->
      "446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174",
    "ExactHelper" ->
      "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
    "ModularReconstruction" ->
      "0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce",
    "PrerequisiteSchema" ->
      "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45"|>;
  If[! DirectoryQ[DirectoryName[outputFile]] || FileExistsQ[outputFile] ||
      ! AllTrue[Values[files], FileExistsQ],
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL missing_source_or_stale_output"];
    Return[$Failed]];
  gateHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
  hashesBefore = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  If[hashesBefore =!= expectedHashes,
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL immutable_hash_pin observed=",
      InputForm[hashesBefore]];
    Return[$Failed]];

  deleteIfPresent[file_String] := Module[{},
    If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
    ! FileExistsQ[file]];
  writeAtomic[value_Association] := Module[
    {temporary, written, renamed, reread},
    If[FileExistsQ[outputFile] || ByteCount[value] > maximumOutputBytes,
      Return[$Failed]];
    temporary = outputFile <> ".tmp-" <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = CheckAbort[Quiet[Check[Put[value, temporary], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[written === $Failed || ! FileExistsQ[temporary] ||
        FileByteCount[temporary] > maximumOutputBytes,
      deleteIfPresent[temporary]; Return[$Failed]];
    renamed = CheckAbort[Quiet[Check[RenameFile[temporary, outputFile,
      OverwriteTarget -> False], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[renamed === $Failed || ! FileExistsQ[outputFile] ||
        FileExistsQ[temporary] ||
        FileByteCount[outputFile] > maximumOutputBytes,
      deleteIfPresent[temporary]; deleteIfPresent[outputFile];
      Return[$Failed]];
    reread = Quiet[Check[Get[outputFile], $Failed]];
    If[! SameQ[reread, value],
      deleteIfPresent[outputFile]; Return[$Failed]];
    outputFile];
  stripShebang[text_String] := Module[{lines = StringSplit[text, "\n"]},
    If[lines =!= {} && StringStartsQ[First[lines], "#!"],
      StringRiffle[Rest[lines], "\n"], text]];
  removeByFullName[name_String] := ToExpression[name, InputForm,
    Function[heldSymbol, Quiet[System`Remove[heldSymbol]], HoldAll]];
  trackedContexts = {"Global`",
    "CodexCF300ExactQepsLeftObstructionDriverV1`",
    "CodexCF300ExactQepsLeftObstructionDriverV1`Private`",
    "CodexCF300ExactQepsLeftObstruction`",
    "CodexCF300ExactQepsLeftObstruction`Private`",
    "CodexCF300ModularQepsWitnessReconstruction`",
    "CodexCF300ModularQepsWitnessReconstruction`Private`",
    "CodexDirectRootChannelAssembler`"};

  parseOne[label_String, file_String] := Module[
    {source, parseText, lines, splitContextLines, parseContext,
     namesBefore, namesAfter, newNames, parsed, syntaxLength,
     parserMessages, cleanupPassed, record},
    source = Quiet[Check[Import[file, "Text"], $Failed]];
    If[! StringQ[source], Return[<|"Status" -> "ImportFailed",
      "Label" -> label, "File" -> file, "Passed" -> False|>]];
    parseText = stripShebang[source];
    lines = StringSplit[parseText, "\n"];
    splitContextLines = Pick[Range[Length[lines]],
      StringEndsQ[StringTrim[#1], "`"] & /@ lines];
    parseContext = "CodexCF300ExactHeldParse`c" <>
      StringReplace[CreateUUID[], "-" -> ""] <> "`";
    namesBefore = AssociationMap[System`Names[#1 <> "*"] &,
      trackedContexts];
    parserMessages = {};
    Block[{$Context = parseContext, $ContextPath = {"System`"},
        $MessageList = {}},
      parsed = Quiet[Check[
        ToExpression[parseText, InputForm, HoldComplete], $Failed]];
      syntaxLength = Quiet[Check[SyntaxLength[parseText], $Failed]];
      parserMessages = ToString[InputForm[#1]] & /@ $MessageList];
    record = <|
      "Status" -> "CF300ExactQepsHeldParseRecordXH",
      "Label" -> label, "File" -> file,
      "SHA256" -> FileHash[file, "SHA256", "HexString"],
      "CharacterCount" -> StringLength[parseText],
      "SyntaxLength" -> syntaxLength,
      "HoldCompleteExact" -> (Head[parsed] === HoldComplete),
      "SyntaxLengthExact" -> TrueQ[IntegerQ[syntaxLength] &&
        syntaxLength === StringLength[parseText]],
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
    Join[record, <|
      "ParseNamespaceCleanupPassed" -> cleanupPassed,
      "Passed" -> TrueQ[
        record["HoldCompleteExact"] && record["SyntaxLengthExact"] &&
        record["ParserMessages"] === {} &&
        record["SplitContextMarkerLines"] === {} && cleanupPassed]|>]
  ];

  records = KeyValueMap[parseOne, files];
  hashesAfter = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  gateHashAfter = FileHash[$InputFileName, "SHA256", "HexString"];
  allPassed = TrueQ[
    AllTrue[records, TrueQ[Lookup[#1, "Passed", False]] &] &&
    hashesAfter === hashesBefore === expectedHashes &&
    gateHashAfter === gateHashBefore &&
    System`$KernelID === expectedDispatchKernelID &&
    KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
    System`Kernels[] === {}];
  result = <|
    "Status" -> If[allPassed,
      "CF300ExactQepsRuntimeAdmissionHeldParsePassedXH",
      "CF300ExactQepsRuntimeAdmissionHeldParseFailedXH"],
    "AllPassed" -> allPassed,
    "ExpectedDispatchKernelID" -> expectedDispatchKernelID,
    "DispatchKernelID" -> actualDispatchKernelID,
    "TaskBrokerMaxHelpers" -> taskBrokerMaxHelpers,
    "OuterPoolKernelCount" -> outerPoolKernelCount,
    "NestedKernelCountAtEntry" -> Length[nestedKernelsAtEntry],
    "NestedKernelsAtEntry" -> nestedKernelsAtEntry,
    "MaximumOutputBytes" -> maximumOutputBytes,
    "SourceHashesBefore" -> hashesBefore,
    "SourceHashesAfter" -> hashesAfter,
    "ParseRecords" -> AssociationThread[Keys[files], records],
    "GateSHA256" -> gateHashBefore|>;
  If[writeAtomic[result] === $Failed,
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL atomic_output"];
    Return[$Failed]];
  If[allPassed,
    Print["CF300_EXACT_QEPS_HELD_PARSE PASS output=", outputFile]; 0,
    Print["CF300_EXACT_QEPS_HELD_PARSE FAIL parse_or_stability output=",
      outputFile]; $Failed]
]
