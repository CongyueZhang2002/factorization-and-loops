#!/usr/bin/env wolframscript

$HistoryLength = 0;
Module[{arguments, outputFile, gateDirectory, prototypeDirectory,
    v6Directory, files, expectedHashes, observedBefore, observedAfter,
    driverHash, deleteIfPresent, writeAtomic, stripShebang, parseOne,
    results, allPassed, result, expectedDispatchKernelID,
    actualDispatchKernelID, taskBrokerMaxHelpers,
    nestedKernelsAtEntry, outerPoolKernelCount},
  expectedDispatchKernelID = 24;
  actualDispatchKernelID = System`$KernelID;
  If[actualDispatchKernelID =!= expectedDispatchKernelID,
    Print["CF300_V6E_HELD_PARSE_GATE FAIL wrong dispatch kernel expected=",
      expectedDispatchKernelID, " actual=", actualDispatchKernelID];
    System`Exit[69]];
  taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers;
  nestedKernelsAtEntry = System`Kernels[];
  outerPoolKernelCount = System`$KernelCount;
  If[! TrueQ[taskBrokerMaxHelpers === 0] || nestedKernelsAtEntry =!= {},
    Print["CF300_V6E_HELD_PARSE_GATE FAIL helper ceiling or nested kernels",
      " broker_max_helpers=", InputForm[taskBrokerMaxHelpers],
      " nested_kernels=", InputForm[nestedKernelsAtEntry]];
    System`Exit[65]];
  arguments = Rest[$ScriptCommandLine];
  If[! MemberQ[{1, 2}, Length[arguments]] ||
      (Length[arguments] === 2 && Last[arguments] =!= "core-only"),
    Print["CF300_V6E_HELD_PARSE_GATE FAIL usage=<fresh-output.wl> " <>
      "[core-only]"];
    System`Exit[64]];
  outputFile = ExpandFileName[First[arguments]];
  parsePrerequisiteSourcesQ = Length[arguments] === 1;
  gateDirectory = DirectoryName[$InputFileName];
  prototypeDirectory = DirectoryName[gateDirectory];
  v6Directory = DirectoryName[prototypeDirectory];
  files = <|
    "RuntimeDriver" -> FileNameJoin[{gateDirectory,
      "run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls"}],
    "V6eHelper" -> FileNameJoin[{prototypeDirectory,
      "DirectRootChannelExactOneFormRebindV6e.wl"}],
    "V6eIntegrationReference" -> FileNameJoin[{prototypeDirectory,
      "V6E_DRIVER_INTEGRATION_BLOCK.wl"}],
    "V6dOrbitCore" -> FileNameJoin[{v6Directory,
      "GaloisChannelOrbitCoreV6d.wl"}],
    "V6CorrectnessOracleHelper" -> FileNameJoin[{v6Directory,
      "DirectRootChannelExactOneFormRebindV6.wl"}],
    "ExactLiftPrerequisiteSchema" -> FileNameJoin[{v6Directory,
      "exact_qeps_left_obstruction_xh",
      "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"}],
    "ExactLiftConsumerHelper" -> FileNameJoin[{v6Directory,
      "exact_qeps_left_obstruction_xh",
      "CF300ExactQepsLeftObstruction.wl"}]|>;
  expectedHashes = <|
    "RuntimeDriver" ->
      "2f83b12a6d33e5f8f34afb56bc349471580913bc4269c265f6a919c3e1ccc884",
    "V6eHelper" ->
      "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8",
    "V6eIntegrationReference" ->
      "7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe",
    "V6dOrbitCore" ->
      "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
    "V6CorrectnessOracleHelper" ->
      "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44",
    "ExactLiftPrerequisiteSchema" ->
      "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
    "ExactLiftConsumerHelper" ->
      "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b"|>;
  allFiles = files;
  allExpectedHashes = expectedHashes;
  optionalPrerequisiteSources = {"ExactLiftPrerequisiteSchema",
    "ExactLiftConsumerHelper"};
  files = If[parsePrerequisiteSourcesQ, allFiles,
    KeyDrop[allFiles, optionalPrerequisiteSources]];
  expectedHashes = If[parsePrerequisiteSourcesQ, allExpectedHashes,
    KeyDrop[allExpectedHashes, optionalPrerequisiteSources]];
  If[! AllTrue[Values[files], FileExistsQ] || FileExistsQ[outputFile] ||
      ! DirectoryQ[DirectoryName[outputFile]],
    Print["CF300_V6E_HELD_PARSE_GATE FAIL missing source or stale output"];
    System`Exit[65]];
  driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
  observedBefore = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  If[observedBefore =!= expectedHashes,
    Print["CF300_V6E_HELD_PARSE_GATE FAIL pinned source mismatch observed=",
      InputForm[observedBefore]];
    System`Exit[66]];

  deleteIfPresent[file_String] := Module[{},
    If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
    ! FileExistsQ[file]];
  writeAtomic[value_] := Module[{temporary, written, renamed, reread},
    If[FileExistsQ[outputFile] || ByteCount[value] > 2^24,
      Return[$Failed]];
    temporary = outputFile <> ".tmp-" <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = CheckAbort[Quiet[Check[Put[value, temporary], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[written === $Failed || ! FileExistsQ[temporary],
      deleteIfPresent[temporary]; Return[$Failed]];
    renamed = CheckAbort[Quiet[Check[RenameFile[temporary, outputFile,
      OverwriteTarget -> False], $Failed]],
      (deleteIfPresent[temporary]; Abort[])];
    If[renamed === $Failed || ! FileExistsQ[outputFile] ||
        FileExistsQ[temporary],
      deleteIfPresent[temporary]; Return[$Failed]];
    reread = Quiet[Check[Get[outputFile], $Failed]];
    If[! SameQ[reread, value],
      deleteIfPresent[outputFile]; Return[$Failed]];
    outputFile];
  stripShebang[text_String] := Module[{lines},
    lines = StringSplit[text, "\n"];
    If[lines =!= {} && StringStartsQ[First[lines], "#!"],
      StringRiffle[Rest[lines], "\n"], text]];
  parseOne[label_String, file_String] := Module[
    {source, parseText, parseContext, globalBefore, parsed, messages,
     syntaxLength, globalAfter, newGlobal, parseNamesAfter,
     removeByFullName, cleanupPassed, record},
    source = Quiet[Check[Import[file, "Text"], $Failed]];
    If[! StringQ[source], Return[<|"Status" -> "ImportFailed",
      "Label" -> label, "File" -> file|>]];
    parseText = stripShebang[source];
    parseContext = "CodexV6eHeldParseXH`c" <>
      StringReplace[CreateUUID[], "-" -> ""] <> "`";
    globalBefore = System`Names["Global`*"];
    removeByFullName[name_String] := ToExpression[name, InputForm,
      Function[heldSymbol, Quiet[System`Remove[heldSymbol]], HoldAll]];
    messages = {};
    Block[{$Context = parseContext, $ContextPath = {"System`"},
        $MessageList = {}},
      parsed = Quiet[Check[
        ToExpression[parseText, InputForm, HoldComplete], $Failed]];
      syntaxLength = Quiet[Check[SyntaxLength[parseText], $Failed]];
      messages = ToString[InputForm[#1]] & /@ $MessageList];
    record = <|
      "Status" -> "CF300V6eHeldParseRecordXH",
      "Label" -> label, "File" -> file,
      "SHA256" -> FileHash[file, "SHA256", "HexString"],
      "SourceCharacterCount" -> StringLength[source],
      "ParseCharacterCount" -> StringLength[parseText],
      "ParsedHead" -> ToString[Head[parsed], InputForm],
      "SyntaxLength" -> syntaxLength,
      "ParserMessages" -> messages,
      "HoldCompleteExact" -> (Head[parsed] === HoldComplete),
      "SyntaxLengthExact" ->
        (IntegerQ[syntaxLength] && syntaxLength === StringLength[parseText]),
      "ZeroParserMessages" -> (messages === {})|>;
    parsed =.;
    newGlobal = Complement[System`Names["Global`*"], globalBefore];
    parseNamesAfter = System`Names[parseContext <> "*"];
    Scan[removeByFullName, newGlobal];
    Scan[removeByFullName, parseNamesAfter];
    globalAfter = System`Names["Global`*"];
    cleanupPassed = TrueQ[
      globalAfter === globalBefore &&
      System`Names[parseContext <> "*"] === {}];
    Join[record, <|"ParseNamespaceCleanupPassed" -> cleanupPassed,
      "Passed" -> TrueQ[
        record["HoldCompleteExact"] && record["SyntaxLengthExact"] &&
        record["ZeroParserMessages"] && cleanupPassed]|>]];

  results = KeyValueMap[parseOne, files];
  observedAfter = Map[FileHash[#1, "SHA256", "HexString"] &, files];
  allPassed = TrueQ[
    AllTrue[results, TrueQ[Lookup[#1, "Passed", False]] &] &&
    observedAfter === observedBefore === expectedHashes &&
    FileHash[$InputFileName, "SHA256", "HexString"] === driverHash];
  result = <|
    "Status" -> If[allPassed,
      "CF300Sector12V6eHeldParseGatePassedXH",
      "CF300Sector12V6eHeldParseGateFailedXH"],
    "GateSHA256" -> driverHash,
    "PrerequisiteSourcesParsed" -> parsePrerequisiteSourcesQ,
    "ExpectedDispatchKernelID" -> expectedDispatchKernelID,
    "DispatchKernelID" -> actualDispatchKernelID,
    "TaskBrokerMaxHelpers" -> taskBrokerMaxHelpers,
    "OuterPoolKernelCount" -> outerPoolKernelCount,
    "NestedKernelCount" -> Length[nestedKernelsAtEntry],
    "NestedKernelsAtEntry" -> nestedKernelsAtEntry,
    "SourceHashesBefore" -> observedBefore,
    "SourceHashesAfter" -> observedAfter,
    "ParseRecords" -> AssociationThread[Keys[files], results],
    "AllPassed" -> allPassed|>;
  If[writeAtomic[result] === $Failed,
    Print["CF300_V6E_HELD_PARSE_GATE FAIL atomic output race"];
    System`Exit[98]];
  Print["CF300_V6E_HELD_PARSE_GATE status=", result["Status"],
    " output=", outputFile];
  System`Exit[If[allPassed, 0, 2]]]
