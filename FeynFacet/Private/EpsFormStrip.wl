(* Exact off-diagonal epsilon-form strip solver.

   For diagonal connections eps e and eps c and an off-diagonal block bbar,
   the gauge D obeys

     d_mu D = eps (e_mu D - D c_mu) + F_mu,

   where the transformed strip must be a dlog one-form.  CANONICA is tried
   first in isolated kernels.  Maple is used only after the configured
   CANONICA ansatz degrees have all failed to produce an exactly checked
   dlog gauge.
*)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[SolveResidueRationalGauge, SolveEpsFormStrip];
ClearAll[
  epsFormStripCanonicaSymbol,
  epsFormStripLoadCanonica,
  epsFormStripZeroQ,
  epsFormStripShapeQ,
  epsFormStripAlphabet,
  epsFormStripExactDLogQ,
  epsFormStripExactPotentialGauge,
  epsFormStripBuildResidueCompatibility,
  epsFormStripRationalLinearEquations,
  epsFormStripMonicPolynomial,
  epsFormStripVariableFactors,
  epsFormStripRunCanonicaOne,
  epsFormStripRunCanonica,
  epsFormStripUnknownNameCollisions,
  epsFormStripSafeTag,
  epsFormStripMapleSqrtToInputForm,
  epsFormStripMapleInputString,
  epsFormStripMapleCacheKey,
  epsFormStripMapleCompleteOutputLines,
  epsFormStripMapleCacheLineSyntaxQ,
  epsFormStripMaplePutTextAtomic,
  epsFormStripMapleCanonicalizeEntries,
  epsFormStripMapleCanonicalize
];

SolveResidueRationalGauge::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveResidueRationalGauge::canonica =
  "CANONICA functions needed for the residue equations are unavailable.";
SolveResidueRationalGauge::residue =
  "The exact residue construction failed at stage `1`.";
SolveResidueRationalGauge::maple =
  "Maple did not produce a rational gauge satisfying both differential equations exactly.";
SolveResidueRationalGauge::symbols =
  "Maple serialization found distinct Mathematica symbols with the same unqualified name: `1`.";
SolveResidueRationalGauge::unknownname =
  "The generated Maple unknowns collide with the caller's symbols `1`; \
rename the variables or the regulator.";

SolveEpsFormStrip::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveEpsFormStrip::canonica =
  "CANONICA could not be loaded from `1`.";
SolveEpsFormStrip::degrees =
  "CANONICA numerator degrees must be a nonempty list of nonnegative integers.";
SolveEpsFormStrip::failed =
  "Neither the configured CANONICA searches nor the exact Maple construction found a gauge.";

(* Add-on and tool locations: the add-on tree through
   $feynFacetAddonRoot and the package's own tool through
   $feynFacetDirectory, so an installation whose add-ons or package
   directory do not sit under one parent still resolves them
   (generality pass 2026-08-23; defaults unchanged). *)
$epsFormStripCanonicaFile = FileNameJoin[{
  $feynFacetAddonRoot, "Addon", "Mathematica_Addon", "CANONICA", "src",
  "CANONICA.m"
}];
$epsFormStripMapleLibrary = FileNameJoin[{
  $feynFacetAddonRoot, "Addon", "Other_Addon", "Maple",
  "IntegrableConnections"
}];
$epsFormStripCPURunner = FileNameJoin[{
  $feynFacetDirectory, "Tools", "RunWithCPUList.sh"
}];

(* Entrywise Maple normal form for an already-exact array of algebraic
   expressions (including declared Sqrt radicals).  This is deliberately a
   representation service, not an
   acceptance test: its caller must prove that the returned expressions are
   the same elements of its coefficient field.  The bridge uses the same
   context-stripping, CPU runner, hard process timeout and private parse
   context as SolveResidueRationalGauge below.  A private Runner seam lets a
   focused suite exercise serialization and parsing without requiring Maple. *)
Options[epsFormStripMapleCanonicalize] = {
  "MapleExecutable" -> "maple",
  "ScratchDirectory" -> Automatic,
  "CacheDirectory" -> Automatic,
  "Tag" -> "maple_canonical",
  "TimeLimit" -> 1800,
  "Runner" -> Automatic,
  "InternalSingleEntry" -> False,
  "Verbose" -> False
};

(* Maple prints algebraic radicals as sqrt(...), whereas Wolfram function
   application uses square brackets.  Convert only the balanced sqrt calls;
   ordinary parentheses remain grouping parentheses and nested radicals are
   handled recursively. *)
epsFormStripMapleSqrtToInputForm[text_String] := Module[{convert},
  convert[string_String] := Module[
    {position, start, index, depth, length, character, close, inner},
    position = StringPosition[string, "sqrt(", 1];
    If[position === {}, Return[string]];
    start = position[[1, 1]];
    length = StringLength[string];
    index = start + 5;
    depth = 1;
    While[index <= length && depth > 0,
      character = StringTake[string, {index}];
      If[character === "(", depth++];
      If[character === ")", depth--];
      index++];
    If[depth =!= 0, Return[$Failed]];
    close = index - 1;
    inner = If[close === start + 5, "",
      StringTake[string, {start + 5, close - 1}]];
    convert[StringTake[string, start - 1] <> "Sqrt[" <>
      convert[inner] <> "]" <> StringDrop[string, close]]];
  convert[text]
];
epsFormStripMapleSqrtToInputForm[___] := $Failed;

epsFormStripMapleInputString[expression_] := StringReplace[
  ToString[expression, InputForm],
  {RegularExpression["(?:[A-Za-z$][A-Za-z0-9$]*`)+"] -> "",
   "Sqrt[" -> "sqrt(", "[" -> "(", "]" -> ")", " " -> ""}];

epsFormStripMapleCacheKey[expression_] := Hash[
  {"MapleCanonicalEntryV1", epsFormStripMapleInputString[expression]},
  "SHA256", "HexString"];

(* Keep only newline-terminated records.  A killed Maple process may leave
   the next expression half-written; that suffix is never a checkpoint. *)
epsFormStripMapleCompleteOutputLines[file_String] := Module[
  {stream, bytes, text, lines},
  If[! FileExistsQ[file], Return[{}]];
  text = Quiet[Check[
    stream = OpenRead[file, BinaryFormat -> True];
    bytes = BinaryReadList[stream, "UnsignedInteger8"];
    Close[stream];
    StringReplace[FromCharacterCode[bytes], "\r" -> ""], $Failed]];
  If[Head[stream] === InputStream, Quiet[Close[stream]]];
  If[! StringQ[text], Return[{}]];
  lines = StringSplit[text, "\n"];
  If[lines === {}, Return[{}]];
  If[StringEndsQ[text, "\n"], lines, Most[lines]]
];
epsFormStripMapleCompleteOutputLines[___] := {};

epsFormStripMapleCacheLineSyntaxQ[line_String] := Module[{converted},
  converted = epsFormStripMapleSqrtToInputForm[line];
  StringQ[converted] && TrueQ[Quiet[Check[
    Block[{$Context = "FeynFacetMapleCacheSyntax`",
      $ContextPath = {"System`"}}, ToExpression[converted]; True], False]]]
];
epsFormStripMapleCacheLineSyntaxQ[___] := False;

epsFormStripMaplePutTextAtomic[text_String, file_String] := Module[
  {temporary = file <> ".next." <> ToString[$ProcessID] <> "." <>
      StringReplace[CreateUUID[], "-" -> ""]},
  Quiet[Check[
    Export[temporary, text, "Text"];
    RenameFile[temporary, file, OverwriteTarget -> True]; file,
    If[FileExistsQ[temporary], Quiet[DeleteFile[temporary]]]; $Failed]]
];
epsFormStripMaplePutTextAtomic[___] := $Failed;

(* Production normalization is entry-resumable.  Each algebraic entry is
   an independent exact Normal call; a shared cache lets equal blocks in
   different families do that work once.  The injected Runner seam keeps
   the historical whole-array contract for focused tests. *)
epsFormStripMapleCanonicalizeEntries[array_List, OptionsPattern[
    epsFormStripMapleCanonicalize]] := Module[
  {started = AbsoluteTime[], dimensions = Dimensions[array], expressions,
   scratchDirectory, cacheDirectory, tag, timeLimit, verbose, outputFile,
   inputSymbols, duplicateNames, mapleInputs, legacyMapleFile,
   legacyMapleText, legacyPayloadQ = False, legacyLines, cacheFiles,
   parsed = {}, records = {},
   rawLines = {}, remaining, result, cacheLines, failure, i, seeded = 0},
  expressions = Flatten[array];
  inputSymbols = DeleteDuplicates@Cases[expressions,
    symbol_Symbol /; Context[symbol] =!= "System`",
    {0, Infinity}, Heads -> True];
  duplicateNames = Select[GatherBy[inputSymbols, SymbolName],
    Length[DeleteDuplicates[Context /@ #1]] > 1 &];
  If[duplicateNames =!= {},
    Return[<|"Status" -> "MapleCanonicalSymbolNameCollision",
      "Symbols" -> Map[ToString[InputForm[#1]] &,
        duplicateNames, {2}]|>]];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  cacheDirectory = Replace[OptionValue["CacheDirectory"],
    Automatic :> FileNameJoin[{scratchDirectory,
      "MapleCanonicalCache"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  timeLimit = OptionValue["TimeLimit"];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! DirectoryQ[cacheDirectory], Quiet[CreateDirectory[cacheDirectory,
    CreateIntermediateDirectories -> True]]];
  If[! DirectoryQ[cacheDirectory],
    Return[<|"Status" -> "MapleCanonicalCacheUnavailable",
      "CacheDirectory" -> cacheDirectory|>]];
  mapleInputs = epsFormStripMapleInputString /@ expressions;
  cacheFiles = FileNameJoin[{cacheDirectory, # <> ".out"}] & /@
    (epsFormStripMapleCacheKey /@ expressions);
  outputFile = FileNameJoin[{scratchDirectory, tag <> ".out"}];
  legacyLines = epsFormStripMapleCompleteOutputLines[outputFile];
  legacyMapleFile = FileNameJoin[{scratchDirectory, tag <> ".mpl"}];
  If[FileExistsQ[legacyMapleFile],
    legacyMapleText = Quiet[Check[Import[legacyMapleFile, "Text"],
      $Failed]];
    legacyPayloadQ = StringQ[legacyMapleText] && StringContainsQ[
      legacyMapleText, "feynfacetGaugeEntries := [" <>
        StringRiffle[mapleInputs, ","] <> "]:"]];
  If[legacyPayloadQ && legacyLines =!= {} && First[legacyLines] === "OK",
    legacyLines = Take[Rest[legacyLines],
      UpTo[Length[expressions]]];
    Do[If[! FileExistsQ[cacheFiles[[i]]] &&
          epsFormStripMapleCacheLineSyntaxQ[legacyLines[[i]]],
        If[StringQ[epsFormStripMaplePutTextAtomic[
            "OK\n" <> legacyLines[[i]] <> "\n", cacheFiles[[i]]]],
          seeded++]], {i, Length[legacyLines]}]];
  failure = Catch[Do[
    remaining = timeLimit - (AbsoluteTime[] - started);
    If[remaining <= 0,
      Throw[<|"Status" -> "MapleCanonicalTimedOut",
        "Seconds" -> N[AbsoluteTime[] - started],
        "CompletedEntries" -> Length[parsed],
        "EntryCount" -> Length[expressions], "Resumable" -> True|>,
        "MapleEntryFailure"]];
    result = Function[{}, epsFormStripMapleCanonicalize[
      {expressions[[i]]},
      "MapleExecutable" -> OptionValue["MapleExecutable"],
      "ScratchDirectory" -> scratchDirectory,
      "CacheDirectory" -> cacheDirectory,
      "Tag" -> tag <> "_entry_" <> IntegerString[i, 10, 3],
      "TimeLimit" -> remaining, "Runner" -> Automatic,
      "InternalSingleEntry" -> True, "Verbose" -> verbose]][];
    If[Lookup[result, "Status", None] =!= "MapleCanonicalGaugeV1",
      Throw[<|"Status" -> Lookup[result, "Status",
          "MapleCanonicalEntryFailed"], "EntryIndex" -> i,
        "CompletedEntries" -> Length[parsed],
        "EntryCount" -> Length[expressions], "Detail" -> result,
        "Resumable" -> True|>, "MapleEntryFailure"]];
    AppendTo[parsed, First[result["Result"]]];
    AppendTo[records, KeyDrop[result, "Result"]];
    cacheLines = epsFormStripMapleCompleteOutputLines[cacheFiles[[i]]];
    If[Length[cacheLines] =!= 2 || First[cacheLines] =!= "OK",
      Throw[<|"Status" -> "MapleCanonicalCacheRecordInvalid",
        "EntryIndex" -> i, "CacheFile" -> cacheFiles[[i]]|>,
        "MapleEntryFailure"]];
    AppendTo[rawLines, Last[cacheLines]],
    {i, Length[expressions]}], "MapleEntryFailure"];
  If[AssociationQ[failure], Return[failure]];
  epsFormStripMaplePutTextAtomic[
    "OK\n" <> StringRiffle[rawLines, "\n"] <> "\n", outputFile];
  <|"Status" -> "MapleCanonicalGaugeV1",
    "Result" -> ArrayReshape[parsed, dimensions],
    "Seconds" -> N[AbsoluteTime[] - started],
    "EntryCount" -> Length[expressions],
    "Route" -> "MapleEntryCache",
    "CacheDirectory" -> cacheDirectory,
    "CacheHits" -> Count[Lookup[records, "CacheHit", False], True],
    "ComputedEntries" -> Count[Lookup[records, "CacheHit", False], False],
    "LegacyEntriesSeeded" -> seeded,
    "EntryRecords" -> records|>
];

epsFormStripMapleCanonicalize[array_List, OptionsPattern[]] := Module[
  {started = AbsoluteTime[], dimensions = Dimensions[array], expressions,
   mapleExecutable, scratchDirectory, cacheDirectory, tag, timeLimit,
   runner, internalSingleEntry, verbose,
   toMaple, inputSymbols, duplicateNames, symbolByName, parseContext,
   mapleFile, outputFile, mapleOutputFile, diagnosticFile, mapleText,
   mapleCommand, processCommand, lockedCommand, shellScript, lockFile,
   process, runnerResult, lines, parsed, parseRules, unresolved, log,
   maplePath, cacheFile = None, cacheHit = False, useCache = False},
  expressions = Flatten[array];
  If[expressions === {},
    Return[<|"Status" -> "MapleCanonicalGaugeV1", "Result" -> array,
      "Seconds" -> 0., "EntryCount" -> 0|>]];
  If[dimensions === {} || Times @@ dimensions =!= Length[expressions],
    Return[<|"Status" -> "MapleCanonicalInputNotRectangular"|>]];
  mapleExecutable = OptionValue["MapleExecutable"];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  cacheDirectory = Replace[OptionValue["CacheDirectory"],
    Automatic :> FileNameJoin[{scratchDirectory,
      "MapleCanonicalCache"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  timeLimit = OptionValue["TimeLimit"];
  runner = OptionValue["Runner"];
  internalSingleEntry = TrueQ[OptionValue["InternalSingleEntry"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! StringQ[mapleExecutable] || ! StringQ[scratchDirectory] ||
      ! NumericQ[timeLimit] || timeLimit <= 0,
    Return[<|"Status" -> "MapleCanonicalOptionsInvalid"|>]];
  If[runner === Automatic && Length[expressions] > 1 &&
      ! internalSingleEntry,
    Return[epsFormStripMapleCanonicalizeEntries[array,
      "MapleExecutable" -> mapleExecutable,
      "ScratchDirectory" -> scratchDirectory,
      "CacheDirectory" -> cacheDirectory, "Tag" -> tag,
      "TimeLimit" -> timeLimit, "Runner" -> Automatic,
      "InternalSingleEntry" -> False, "Verbose" -> verbose]]];
  log[items___] := If[verbose, Print[items]];
  If[! DirectoryQ[scratchDirectory],
    Quiet[CreateDirectory[scratchDirectory,
      CreateIntermediateDirectories -> True]]];
  If[! DirectoryQ[scratchDirectory],
    Return[<|"Status" -> "MapleCanonicalScratchUnavailable",
      "ScratchDirectory" -> scratchDirectory|>]];

  toMaple[expr_] := epsFormStripMapleInputString[expr];
  inputSymbols = DeleteDuplicates@Cases[expressions,
    symbol_Symbol /; Context[symbol] =!= "System`",
    {0, Infinity}, Heads -> True];
  duplicateNames = Select[GatherBy[inputSymbols, SymbolName],
    Length[DeleteDuplicates[Context /@ #1]] > 1 &];
  If[duplicateNames =!= {},
    Return[<|"Status" -> "MapleCanonicalSymbolNameCollision",
      "Symbols" -> Map[ToString[InputForm[#1]] &, duplicateNames, {2}]|>]];
  symbolByName = AssociationThread[SymbolName /@ inputSymbols -> inputSymbols];
  parseContext = "FeynFacetMapleCanonicalParse" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";

  mapleFile = FileNameJoin[{scratchDirectory, tag <> ".mpl"}];
  outputFile = FileNameJoin[{scratchDirectory, tag <> ".out"}];
  diagnosticFile = FileNameJoin[{scratchDirectory, tag <> ".log"}];
  useCache = runner === Automatic && Length[expressions] === 1;
  If[useCache,
    If[! DirectoryQ[cacheDirectory], Quiet[CreateDirectory[cacheDirectory,
      CreateIntermediateDirectories -> True]]];
    If[! DirectoryQ[cacheDirectory],
      Return[<|"Status" -> "MapleCanonicalCacheUnavailable",
        "CacheDirectory" -> cacheDirectory|>]];
    cacheFile = FileNameJoin[{cacheDirectory,
      epsFormStripMapleCacheKey[First[expressions]] <> ".out"}];
    cacheHit = With[{cached =
        epsFormStripMapleCompleteOutputLines[cacheFile]},
      Length[cached] === 2 && First[cached] === "OK" &&
        epsFormStripMapleCacheLineSyntaxQ[Last[cached]]];
    If[FileExistsQ[cacheFile] && ! cacheHit,
      Quiet[DeleteFile[cacheFile]]];
    outputFile = cacheFile];
  mapleOutputFile = If[useCache && ! cacheHit,
    cacheFile <> ".next." <> ToString[$ProcessID] <> "." <>
      StringReplace[CreateUUID[], "-" -> ""], outputFile];
  If[! useCache && FileExistsQ[outputFile], Quiet[DeleteFile[outputFile]]];
  If[FileExistsQ[mapleOutputFile] && mapleOutputFile =!= outputFile,
    Quiet[DeleteFile[mapleOutputFile]]];
  If[FileExistsQ[diagnosticFile], Quiet[DeleteFile[diagnosticFile]]];
  maplePath[path_String] := StringReplace[path,
    {"\\" -> "/", "\"" -> "\\\""}];
  mapleText = StringJoin[
    "restart:\ninterface(prettyprint=0):\n",
    "feynfacetGaugeEntries := [",
      StringRiffle[toMaple /@ expressions, ","], "]:\n",
    "fd := fopen(\"", maplePath[mapleOutputFile], "\", WRITE):\n",
    "fprintf(fd, \"OK\\n\"):\n",
    "for i from 1 to nops(feynfacetGaugeEntries) do\n",
    "  fprintf(fd, \"%a\\n\", ",
      "evala(Normal(feynfacetGaugeEntries[i]))):\n",
    "end do:\nfclose(fd):\nquit:\n"];
  Export[mapleFile, mapleText, "Text"];

  If[runner === Automatic,
    If[! cacheHit,
      mapleCommand = If[$OperatingSystem === "Unix" &&
          FileExistsQ[$epsFormStripCPURunner],
        {$epsFormStripCPURunner, facetCPUList[], mapleExecutable, "-q",
          mapleFile},
        {mapleExecutable, "-q", mapleFile}];
      lockedCommand = mapleCommand;
      If[useCache && $OperatingSystem === "Unix" &&
          FileExistsQ["/usr/bin/flock"],
        lockFile = cacheFile <> ".lock";
        shellScript = "cache=\"$1\"; temp=\"$2\"; shift 2; " <>
          "if [ -s \"$cache\" ]; then exit 0; fi; " <>
          "\"$@\"; status=$?; " <>
          "if [ \"$status\" -eq 0 ] && [ -s \"$temp\" ]; then " <>
          "mv -f -- \"$temp\" \"$cache\"; fi; exit \"$status\"";
        lockedCommand = {"/usr/bin/flock", "-x", lockFile,
          "/bin/sh", "-c", shellScript, "sh", cacheFile,
          mapleOutputFile, Sequence @@ mapleCommand}];
      processCommand = If[$OperatingSystem === "Unix" &&
          FileExistsQ["/usr/bin/timeout"],
        {"/usr/bin/timeout", "--signal=TERM", "--kill-after=5s",
          ToString[Ceiling[timeLimit]] <> "s",
          Sequence @@ lockedCommand}, lockedCommand];
      process = Quiet[TimeConstrained[RunProcess[processCommand],
        timeLimit + 15, $TimedOut]];
      If[AssociationQ[process],
        Export[diagnosticFile, StringRiffle[{
          "ExitCode: " <> ToString[Lookup[process, "ExitCode", Missing[]]],
          "StandardOutput:", Lookup[process, "StandardOutput", ""],
          "StandardError:", Lookup[process, "StandardError", ""]}, "\n"],
          "Text"]];
      If[process === $TimedOut,
        Return[<|"Status" -> "MapleCanonicalTimedOut",
          "Seconds" -> N[AbsoluteTime[] - started],
          "Resumable" -> useCache|>]];
      If[AssociationQ[process] && Lookup[process, "ExitCode", -1] === 0 &&
          useCache && ! FileExistsQ[cacheFile] &&
          FileExistsQ[mapleOutputFile],
        Quiet[RenameFile[mapleOutputFile, cacheFile,
          OverwriteTarget -> True]]];
      If[! AssociationQ[process] || Lookup[process, "ExitCode", -1] =!= 0 ||
          ! FileExistsQ[outputFile],
        Return[<|"Status" -> "MapleCanonicalExecutionFailed",
          "DiagnosticFile" -> diagnosticFile,
          "Seconds" -> N[AbsoluteTime[] - started],
          "Resumable" -> useCache|>]]];
    lines = epsFormStripMapleCompleteOutputLines[outputFile],
    runnerResult = Quiet[Check[runner[<|
        "Expressions" -> expressions, "Dimensions" -> dimensions,
        "MapleText" -> mapleText, "MapleFile" -> mapleFile,
        "OutputFile" -> outputFile|>], $Failed]];
    If[AssociationQ[runnerResult] &&
        MatchQ[Lookup[runnerResult, "Expressions", None], {_ ..}],
      parsed = runnerResult["Expressions"];
      If[Length[parsed] =!= Length[expressions],
        Return[<|"Status" -> "MapleCanonicalRunnerOutputInvalid"|>]];
      Return[<|"Status" -> "MapleCanonicalGaugeV1",
        "Result" -> ArrayReshape[parsed, dimensions],
        "Seconds" -> N[AbsoluteTime[] - started],
        "EntryCount" -> Length[expressions], "Route" -> "InjectedRunner"|>]];
    lines = If[AssociationQ[runnerResult],
      Lookup[runnerResult, "OutputLines", $Failed], runnerResult]];

  If[! ListQ[lines] || ! AllTrue[lines, StringQ] || lines === {} ||
      First[lines] =!= "OK" || Length[Rest[lines]] =!= Length[expressions],
    log["Maple canonical output invalid: ", lines];
    Return[<|"Status" -> "MapleCanonicalOutputInvalid",
      "DiagnosticFile" -> diagnosticFile|>]];
  parsed = Quiet[Check[
    Block[{$Context = parseContext, $ContextPath = {"System`"}},
      ToExpression /@ (epsFormStripMapleSqrtToInputForm /@ Rest[lines])],
    $Failed]];
  If[! ListQ[parsed] || Length[parsed] =!= Length[expressions],
    Return[<|"Status" -> "MapleCanonicalParseFailed"|>]];
  parseRules = KeyValueMap[
    Function[{name, symbol}, Symbol[parseContext <> name] -> symbol],
    symbolByName];
  parsed = parsed /. parseRules;
  unresolved = DeleteDuplicates@Cases[parsed,
    symbol_Symbol /; Context[symbol] === parseContext,
    {0, Infinity}, Heads -> True];
  If[unresolved =!= {},
    Return[<|"Status" -> "MapleCanonicalUnknownOutputSymbols",
      "Symbols" -> (SymbolName /@ unresolved)|>]];
  <|"Status" -> "MapleCanonicalGaugeV1",
    "Result" -> ArrayReshape[parsed, dimensions],
    "Seconds" -> N[AbsoluteTime[] - started],
    "EntryCount" -> Length[expressions],
    "Route" -> If[useCache, "MapleEntryCache", "Maple"],
    "CacheHit" -> cacheHit,
    "CacheFile" -> If[useCache, cacheFile, None]|>
];
epsFormStripMapleCanonicalize[___] :=
  <|"Status" -> "MapleCanonicalInputInvalid"|>;

epsFormStripCanonicaSymbol[name_String] := Module[{public, private},
  public = ToExpression["CANONICA`" <> name];
  private = ToExpression["CANONICA`Private`" <> name];
  Which[
    DownValues[Evaluate[public]] =!= {}, public,
    DownValues[Evaluate[private]] =!= {}, private,
    True, $Failed
  ]
];

epsFormStripLoadCanonica[] := Module[{findD, path},
  findD = epsFormStripCanonicaSymbol["FindD"];
  If[findD === $Failed,
    If[! FileExistsQ[$epsFormStripCanonicaFile], Return[False]];
    (* restore $ContextPath after the load: leaving CANONICA` on the
       path makes every later bare Get in the session parse eps/x/y
       into CANONICA` (the measured 2026-08-20 certification failures);
       masterTransportLoadLibra uses the same pattern *)
    path = $ContextPath;
    Quiet[Get[$epsFormStripCanonicaFile]];
    $ContextPath = path;
    findD = epsFormStripCanonicaSymbol["FindD"]
  ];
  If[findD === $Failed, Return[False]];
  CANONICA`$ComputeParallel = False;
  CANONICA`Private`$ComputeParallel = False;
  True
];

epsFormStripZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

epsFormStripShapeQ[{e_List, c_List, bbar_List}] := Module[
  {de, dc, db, ni, nj},
  If[Length[e] =!= 2 || Length[c] =!= 2 || Length[bbar] =!= 2,
    Return[False]];
  de = Dimensions /@ e;
  dc = Dimensions /@ c;
  db = Dimensions /@ bbar;
  If[! SameQ @@ de || ! SameQ @@ dc || ! SameQ @@ db,
    Return[False]];
  If[Length[de[[1]]] =!= 2 || Length[dc[[1]]] =!= 2 ||
     Length[db[[1]]] =!= 2, Return[False]];
  ni = de[[1, 1]];
  nj = dc[[1, 1]];
  de[[1]] === {ni, ni} && dc[[1]] === {nj, nj} &&
    db[[1]] === {ni, nj}
];

epsFormStripAlphabet[{e_, c_, bbar_}, variables_List, epsilon_Symbol] :=
 Module[{extract, converted, irreducibles},
  If[! epsFormStripLoadCanonica[], Return[$Failed]];
  extract = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
  If[extract === $Failed, Return[$Failed]];
  converted = {e, c, bbar} /. epsilon -> CANONICA`eps;
  irreducibles = extract[
    converted, CANONICA`AllowEpsDependence -> True];
  Union[variables, Select[irreducibles, FreeQ[#, CANONICA`eps] &]]
];

epsFormStripExactDLogQ[
    gauge_List, {e_, c_, bbar_}, variables_List, epsilon_Symbol,
    alphabet_List] := Module[{check, ec, cc, bc, dc, transformed},
  If[! epsFormStripLoadCanonica[], Return[False]];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  If[check === $Failed, Return[False]];
  {ec, cc, bc, dc} = ({e, c, bbar, gauge} /.
    epsilon -> CANONICA`eps);
  transformed = Table[
    Map[Together,
      bc[[mu]] + CANONICA`eps (ec[[mu]].dc - dc.cc[[mu]]) -
        D[dc, variables[[mu]]],
      {2}],
    {mu, Length[variables]}];
  TrueQ[check[transformed, variables, alphabet]]
];

epsFormStripExactPotentialGauge[
    strip : {e_, c_, bbar_}, variables : {x_, y_},
    epsilon_Symbol, alphabet_List] := Module[
  {candidate, remainder, correction, gauge, residuals},
  If[! epsFormStripZeroQ[e] || ! epsFormStripZeroQ[c], Return[$Failed]];
  candidate = Quiet[Check[
    Map[Integrate[#, x] &, bbar[[1]], {2}], $Failed]];
  If[candidate === $Failed || ! FreeQ[candidate, _Integrate],
    Return[$Failed]];
  remainder = Map[Together, bbar[[2]] - D[candidate, y], {2}];
  If[! FreeQ[remainder, x], Return[$Failed]];
  correction = Quiet[Check[
    Map[Integrate[#, y] &, remainder, {2}], $Failed]];
  If[correction === $Failed || ! FreeQ[correction, _Integrate],
    Return[$Failed]];
  gauge = Map[Together, candidate + correction, {2}];
  residuals = Table[
    Map[Together, bbar[[mu]] - D[gauge, variables[[mu]]], {2}],
    {mu, 2}];
  If[epsFormStripZeroQ[residuals] &&
      epsFormStripExactDLogQ[
        gauge, strip, variables, epsilon, alphabet],
    gauge, $Failed]
];

(* The residue equations are linear in the constant residue matrices.
   Keeping that linear structure explicit avoids Together on one large
   expression containing every unknown.  For each scalar compatibility
   equation we clear the least common denominator of its rational
   coefficient functions and then equate the coefficients in the two
   kinematic variables to zero. *)
epsFormStripRationalLinearEquations[
    entry_, residueVariables_List, variables_List] := Module[
  {normalizedEntry, arrays, constant, linear, positions, weights,
   functions, fractions,
   denominators, commonDenominator, numerator},
  normalizedEntry = Together[entry];
  If[TrueQ[normalizedEntry === 0], Return[{}]];
  arrays = Quiet[CoefficientArrays[{normalizedEntry}, residueVariables]];
  If[! ListQ[arrays] || Length[arrays] < 2, Return[$Failed]];
  constant = First[Normal[arrays[[1]]]];
  linear = First[Normal[arrays[[2]]]];
  positions = Flatten[Position[linear, Except[0], {1}, Heads -> False]];
  weights = Prepend[residueVariables[[positions]], 1];
  functions = Together /@ Prepend[linear[[positions]], constant];
  If[AllTrue[functions, TrueQ[# === 0] &], Return[{}]];
  fractions = {Numerator[#], Denominator[#]} & /@ functions;
  denominators = fractions[[All, 2]];
  commonDenominator = If[Length[denominators] === 1,
    First[denominators], Apply[PolynomialLCM, denominators]];
  numerator = Expand[Total[MapThread[
    #1 #2[[1]] Cancel[commonDenominator/#2[[2]]] &,
    {weights, fractions}]]];
  If[! PolynomialQ[numerator, variables], Return[$Failed]];
  Values[CoefficientRules[numerator, variables]]
];

epsFormStripBuildResidueCompatibility[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    kernelCount_Integer : 1] :=
 Module[
  {extract, dimensions, alphabet, residueTag,
   rawResidueMatrices, residueVariables, dlog, forcing, compatibility,
   rawCompatibility, equationLists,
   equations, solutions, residueRules, residueMatrices, freeResidues,
   solvedForcing, solvedCompatibility, compatibilitySeconds,
   equationSeconds, solveSeconds, normalizationSeconds, exactCheckSeconds,
   compatibilityZero, needed,
   launched = {}, closedDLog, parallelAvailable, forcingDimensions,
   forcingCount, normalizedEntries},

  $epsFormStripResidueFailureStage = "Shape";
  If[! epsFormStripShapeQ[strip], Return[$Failed]];
  $epsFormStripResidueFailureStage = "LoadCANONICA";
  If[! epsFormStripLoadCanonica[], Return[$Failed]];
  extract = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
  $epsFormStripResidueFailureStage = "ExtractIrreducibles";
  If[extract === $Failed, Return[$Failed]];

  dimensions = Dimensions[bbar[[1]]];
  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  $epsFormStripResidueFailureStage = "Alphabet";
  If[alphabet === $Failed, Return[$Failed]];

  residueTag = StringReplace[SymbolName[Unique["r"]], "$" -> "u"];
  rawResidueMatrices = Table[
    Table[
      Symbol["Global`k" <> residueTag <> "a" <> ToString[a] <>
        "i" <> ToString[i] <> "j" <> ToString[j]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    {a, Length[alphabet]}];
  residueVariables = Flatten[rawResidueMatrices];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  closedDLog = AllTrue[Range[Length[alphabet]],
    TrueQ[Together[
      D[dlog[[#, 2]], variables[[1]]] -
      D[dlog[[#, 1]], variables[[2]]]] === 0] &];
  $epsFormStripResidueFailureStage = "ClosedDLogAlphabet";
  If[! closedDLog, Return[$Failed]];
  forcing = Table[
    bbar[[mu]] - epsilon Sum[
      rawResidueMatrices[[a]] dlog[[a, mu]],
      {a, Length[alphabet]}],
    {mu, 2}];

  {compatibilitySeconds, rawCompatibility} = AbsoluteTiming[
    D[bbar[[2]], variables[[1]]] -
      D[bbar[[1]], variables[[2]]] -
      epsilon (e[[1]].bbar[[2]] - bbar[[2]].c[[1]]) +
      epsilon (e[[2]].bbar[[1]] - bbar[[1]].c[[2]]) +
      Total[Table[
        epsilon^2 (
          dlog[[a, 2]] (e[[1]].rawResidueMatrices[[a]] -
            rawResidueMatrices[[a]].c[[1]]) -
          dlog[[a, 1]] (e[[2]].rawResidueMatrices[[a]] -
            rawResidueMatrices[[a]].c[[2]])),
        {a, Length[alphabet]}]]];
  needed = Min[Max[1, kernelCount], Length[Flatten[rawCompatibility]]];
  If[needed > 1 && Length[Kernels[]] < needed,
    launched = Quiet[LaunchKernels[needed - Length[Kernels[]]]]];
  parallelAvailable = needed > 1 && Length[Kernels[]] >= needed;
  If[parallelAvailable,
    DistributeDefinitions[epsFormStripRationalLinearEquations];
    {equationSeconds, equationLists} = AbsoluteTiming[
      With[{residues = residueVariables, vars = variables},
        ParallelMap[
          Function[entry,
            epsFormStripRationalLinearEquations[entry, residues, vars]],
          Flatten[rawCompatibility],
          Method -> "FinestGrained",
          DistributedContexts -> Automatic]]],
    {equationSeconds, equationLists} = AbsoluteTiming[
      epsFormStripRationalLinearEquations[
        #, residueVariables, variables] & /@ Flatten[rawCompatibility]]];
  If[MemberQ[equationLists, $Failed],
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    $epsFormStripResidueFailureStage = "LinearEquations";
    Return[$Failed]];
  compatibility = rawCompatibility;
  equations = DeleteCases[DeleteDuplicates@Flatten[equationLists], 0];
  If[equations === {},
    solveSeconds = 0.;
    solutions = {{}};
    residueRules = {},
    {solveSeconds, solutions} = AbsoluteTiming[
      Quiet[Solve[Thread[equations == 0], residueVariables]]];
    If[solutions === {},
      If[launched =!= {}, Quiet[CloseKernels[launched]]];
      $epsFormStripResidueFailureStage = "SolveResidues";
      Return[$Failed]];
    residueRules = FixedPoint[
      Function[rules,
        Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]],
      First[solutions],
      50]
  ];
  residueMatrices = rawResidueMatrices /. residueRules;
  freeResidues = Select[residueVariables, ! FreeQ[residueMatrices, #] &];
  forcingDimensions = Dimensions[forcing];
  forcingCount = Times @@ forcingDimensions;
  {normalizationSeconds, normalizedEntries} = AbsoluteTiming[
    If[parallelAvailable,
      ParallelMap[Together,
        Join[Flatten[forcing /. residueRules],
          Flatten[compatibility /. residueRules]],
        Method -> "FinestGrained", DistributedContexts -> Automatic],
      Together /@ Join[Flatten[forcing /. residueRules],
        Flatten[compatibility /. residueRules]]]];
  solvedForcing = ArrayReshape[
    Take[normalizedEntries, forcingCount], forcingDimensions];
  solvedCompatibility = ArrayReshape[
    Drop[normalizedEntries, forcingCount], dimensions];
  If[launched =!= {}, Quiet[CloseKernels[launched]]];
  {exactCheckSeconds, compatibilityZero} = AbsoluteTiming[
    epsFormStripZeroQ[solvedCompatibility]];
  $epsFormStripResidueFailureStage = "ExactCompatibility";
  If[! compatibilityZero, Return[$Failed]];

  $epsFormStripResidueFailureStage = None;

  <|
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "ResidueVariables" -> residueVariables,
    "ResidueRules" -> residueRules,
    "FreeResidues" -> freeResidues,
    "DLog" -> dlog,
    "Forcing" -> solvedForcing,
    "EquationCount" -> Length[equations],
    "CompatibilityZero" -> True,
    "CompatibilitySeconds" -> compatibilitySeconds,
    "EquationSeconds" -> equationSeconds,
    "SolveSeconds" -> solveSeconds,
    "ResidueSystemSeconds" ->
      Total[{compatibilitySeconds, equationSeconds, solveSeconds}],
    "NormalizationSeconds" -> normalizationSeconds,
    "ExactCheckSeconds" -> exactCheckSeconds
  |>
];

epsFormStripMonicPolynomial[polynomial_, variable_] := Module[
  {expanded, degree, leading},
  expanded = Expand[polynomial];
  degree = Exponent[expanded, variable];
  If[! IntegerQ[degree] || degree <= 0, Return[expanded]];
  leading = Coefficient[expanded, variable, degree];
  Together[expanded/leading]
];

epsFormStripVariableFactors[
    alphabet_List, variables_List, variable_] :=
  DeleteDuplicates[
    epsFormStripMonicPolynomial[#, variable] & /@
      Select[alphabet,
        PolynomialQ[#, variables] && ! FreeQ[#, variable] &]];

(* Which of the caller's symbols would be swallowed by the generated
   Maple unknowns: the unknown head's own name, and any name of the form
   <free-constant prefix><digits>.  With Unique-tagged names this is
   empty by construction; it is checked, not assumed, because the whole
   failure mode (Global`c against a variable named c) was silent
   (generality pass 2026-08-23). *)
epsFormStripUnknownNameCollisions[symbols_List, unknownName_String,
    freeConstantPrefix_String] :=
  Select[Cases[symbols, _Symbol],
    SymbolName[#] === unknownName ||
      StringMatchQ[SymbolName[#],
        freeConstantPrefix ~~ DigitCharacter ..] &];

Options[SolveResidueRationalGauge] = {
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "ScratchDirectory" -> Automatic,
  "Tag" -> "residue_strip",
  "TimeLimit" -> 1800,
  "MethodTimeLimit" -> 120,
  "ResidueKernels" -> Automatic,
  "LetterDenominatorPowers" -> {1, 2, 3},
  "NumeratorDegreeOffsets" -> {0, 1, 2},
  "Verbose" -> False
};

SolveResidueRationalGauge[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {mapleExecutable, mapleLibrary, scratchDirectory, tag, timeLimit,
   methodTimeLimit,
   residueKernels, denominatorPowers, numeratorOffsets, verbose, residueData,
   freeResidues, forcing, shape, dimension,
   connection, externalIndices, mapleUnknownHead, mapleUnknowns,
   forcingUnknown, source, toMaple, normalizeRegulator,
   mapleInputSymbols, mapleDuplicateNames, mapleSymbolByName,
   parseContext, parseSymbolByName, variableNames,
   rationalZeroCoefficients, firstVariableIndex, variableFactors,
   ansatzDenominator, mapleFile, outputFile, diagnosticFile,
   mapleText, mapleCommand, processCommand, process, elapsed, raw, lines,
   solutionText, residueText,
   methodText, methodParts, mapleMethod, denominatorPower,
   numeratorOffset,
   mapleUnknownName, mapleFreeConstantPrefix, mapleNameCollisions,
   indexedConstantTokens, indexedConstantSymbols, indexedConstantRules,
   parseMaple, gaugeVectorParametric, residueValuesParametric,
   gaugeParametric, residueRulesParametric, forcingParametric,
   odeResidualParametric, parameterVariables, parameterEquations,
   parameterSolutions, parameterRules, remainingParameters, gauge,
   residueValues, residueRules, solvedForcing, residueMatrices, dlog,
   odeResidual, transformedResidual, result = $Failed, log},

  If[! epsFormStripShapeQ[strip],
    Message[SolveResidueRationalGauge::shape]; Return[$Failed]];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = Replace[OptionValue["MapleLibrary"],
    Automatic -> $epsFormStripMapleLibrary];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  timeLimit = OptionValue["TimeLimit"];
  methodTimeLimit = OptionValue["MethodTimeLimit"];
  residueKernels = facetKernelCount[OptionValue["ResidueKernels"]];
  denominatorPowers = DeleteDuplicates[
    OptionValue["LetterDenominatorPowers"]];
  numeratorOffsets = DeleteDuplicates[
    OptionValue["NumeratorDegreeOffsets"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! IntegerQ[residueKernels] || residueKernels < 1 ||
     ! NumericQ[timeLimit] || timeLimit <= 0 ||
     ! NumericQ[methodTimeLimit] || methodTimeLimit <= 0 ||
     denominatorPowers === {} || numeratorOffsets === {} ||
     ! AllTrue[denominatorPowers, IntegerQ[#] && # >= 1 &] ||
     ! AllTrue[numeratorOffsets, IntegerQ[#] && # >= 0 &],
    Message[SolveResidueRationalGauge::maple]; Return[$Failed]];
  log[items___] := If[verbose, Print[items]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];

  residueData = epsFormStripBuildResidueCompatibility[
    strip, variables, epsilon, residueKernels];
  If[residueData === $Failed,
    Message[SolveResidueRationalGauge::residue,
      $epsFormStripResidueFailureStage]; Return[$Failed]];
  rationalZeroCoefficients =
    epsFormStripCanonicaSymbol["RatFunctionZeroCoeffs"];
  If[rationalZeroCoefficients === $Failed,
    Message[SolveResidueRationalGauge::canonica]; Return[$Failed]];

  freeResidues = residueData["FreeResidues"];
  forcing = residueData["Forcing"];
  shape = Dimensions[bbar[[1]]];
  dimension = Times @@ shape;
  connection = Table[
    epsilon (
      KroneckerProduct[e[[mu]], IdentityMatrix[shape[[2]]]] -
      KroneckerProduct[IdentityMatrix[shape[[1]]],
        Transpose[c[[mu]]]]),
    {mu, 2}];
  externalIndices = Range[1001, 1000 + Length[freeResidues]];
  (* The names Maple sees.  toMaple strips contexts, so what reaches the
     Maple file is the SymbolName alone: the old Global`c head and the
     Global`cc<n> free constants below claimed two of the likeliest
     names in a caller's own alphabet, and a system written in variables
     c and cc1 had its unknowns identified with its kinematics with no
     diagnosis at all.  Both are now Unique-tagged -- letters and digits
     only, which is what a Maple identifier admits -- and a residual
     collision with a variable or the regulator is refused by name
     (generality pass 2026-08-23). *)
  mapleUnknownHead = Unique["mapleUnknownC"];
  mapleUnknownName = SymbolName[mapleUnknownHead];
  mapleFreeConstantPrefix = SymbolName[Unique["mapleFreeC"]] <> "x";
  mapleNameCollisions = epsFormStripUnknownNameCollisions[
    Join[variables, {epsilon}], mapleUnknownName, mapleFreeConstantPrefix];
  If[mapleNameCollisions =!= {},
    Message[SolveResidueRationalGauge::unknownname,
      SymbolName /@ mapleNameCollisions];
    Return[$Failed]];
  mapleUnknowns = mapleUnknownHead /@ externalIndices;
  forcingUnknown = forcing /. Thread[freeResidues -> mapleUnknowns];
  source = Flatten /@ forcingUnknown;

  toMaple[expr_] := StringReplace[ToString[expr, InputForm],
    {RegularExpression["(?:[A-Za-z$][A-Za-z0-9$]*`)+"] -> "",
     " " -> ""}];
  mapleInputSymbols = DeleteDuplicates@Cases[
    {connection, source, variables, epsilon, mapleUnknowns},
    symbol_Symbol /; Context[symbol] =!= "System`",
    {0, Infinity}, Heads -> True];
  mapleDuplicateNames = Select[
    GatherBy[mapleInputSymbols, SymbolName], Length[#] > 1 &];
  If[mapleDuplicateNames =!= {},
    Message[SolveResidueRationalGauge::symbols,
      Map[SymbolName, mapleDuplicateNames, {2}]];
    Return[$Failed]];
  mapleSymbolByName = AssociationThread[
    SymbolName /@ mapleInputSymbols -> mapleInputSymbols];
  parseContext = "FeynFacetMapleParse" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  variableNames = toMaple /@ variables;
  normalizeRegulator[expr_] := Module[{symbols},
    symbols = DeleteDuplicates[Cases[expr,
      symbol_Symbol /; MemberQ[
        {"eps", "Eps", "epsilon", "Epsilon", "ep"},
        SymbolName[symbol]],
      Infinity, Heads -> True]];
    expr /. Thread[symbols -> epsilon]
  ];

  Do[
    variableFactors = epsFormStripVariableFactors[
      residueData["Alphabet"], variables,
      variables[[firstVariableIndex]]];
    ansatzDenominator = Times @@ variableFactors;
    mapleFile = FileNameJoin[{scratchDirectory,
      tag <> "_first_" <> ToString[firstVariableIndex] <> ".mpl"}];
    outputFile = FileNameJoin[{scratchDirectory,
      tag <> "_first_" <> ToString[firstVariableIndex] <> ".out"}];
    diagnosticFile = FileNameJoin[{scratchDirectory,
      tag <> "_first_" <> ToString[firstVariableIndex] <> ".log"}];
    If[FileExistsQ[outputFile], DeleteFile[outputFile]];
    If[FileExistsQ[diagnosticFile], DeleteFile[diagnosticFile]];
    mapleText = StringJoin[
      "restart:\ninterface(prettyprint=0):\nlibname := \"",
        mapleLibrary, "\", libname:\n",
      "with(IntegrableConnections):\nwith(linalg):\n",
      "A1 := matrix(", ToString[dimension], ",", ToString[dimension],
        ",[", StringRiffle[toMaple /@ Flatten[connection[[1]]], ","],
        "]):\n",
      "A2 := matrix(", ToString[dimension], ",", ToString[dimension],
        ",[", StringRiffle[toMaple /@ Flatten[connection[[2]]], ","],
        "]):\n",
      "b1 := vector(", ToString[dimension], ",[",
        StringRiffle[toMaple /@ source[[1]], ","], "]):\n",
      "b2 := vector(", ToString[dimension], ",[",
        StringRiffle[toMaple /@ source[[2]], ","], "]):\n",
      "C := vector(", ToString[Length[mapleUnknowns]], ",[",
        StringRiffle[toMaple /@ mapleUnknowns, ","], "]):\n",
      "errors := []:\nattempts := []:\n",
      "solved := false:\nmethod := \"None\":\n",
      "try\n",
      "  Vtry := timelimit(", ToString[methodTimeLimit],
        ",Mratsolde(A", ToString[firstVariableIndex], ",",
        variableNames[[firstVariableIndex]], ",b",
        ToString[firstVariableIndex], ")):\n",
      "  if Vtry <> {} then V := Vtry: solved := true: ",
        "method := \"IntegrableConnections\" end if:\n",
      "catch: errors := [op(errors),lastexception]: end try:\n",
      "if not solved then\n",
      "  denbase := ", toMaple[ansatzDenominator], ":\n",
      "  for denpower in [",
        StringRiffle[ToString /@ denominatorPowers, ","],
        "] while not solved do\n",
      "    den := denbase^denpower:\n",
      "    basedegree := degree(den,",
        variableNames[[firstVariableIndex]], "):\n",
      "    for degreeoffset in [",
        StringRiffle[ToString /@ numeratorOffsets, ","],
        "] while not solved do\n",
      "      ansatzdegree := basedegree + degreeoffset:\n",
      "      Vtry := vector(", ToString[dimension], ",[seq(add(",
        "aa[i,k]*",
        variableNames[[firstVariableIndex]],
        "^k,k=0..ansatzdegree)/den,i=1..",
        ToString[dimension], ")]):\n",
      "      residual := map(normal,evalm(map(diff,Vtry,",
        variableNames[[firstVariableIndex]], ")-A",
        ToString[firstVariableIndex], "&*Vtry-b",
        ToString[firstVariableIndex], ")):\n",
      "      equations := {}:\n",
      "      for i from 1 to ", ToString[dimension], " do\n",
      "        equations := equations union {coeffs(numer(residual[i]),",
        variableNames[[firstVariableIndex]], ")}:\n",
      "      end do:\n",
      "      ansatzcoeffs := {seq(seq(aa[i,k],k=0..ansatzdegree),",
        "i=1..", ToString[dimension], ")}:\n",
      "      unknowns := ansatzcoeffs union ",
        toMaple[mapleUnknowns], ":\n",
      "      try\n",
      "        ansatzsolution := timelimit(", ToString[methodTimeLimit],
        ",solve(equations,unknowns)):\n",
      "        attempts := [op(attempts),[",
        ToString[firstVariableIndex],
        ",denpower,degreeoffset,nops(equations),nops(unknowns),",
        "type(ansatzsolution,set)]]:\n",
      "        if type(ansatzsolution,set) then\n",
      "          Vraw := map(normal,eval(Vtry,ansatzsolution)):\n",
      "          Craw := map(normal,eval(C,ansatzsolution)):\n",
      "          freeaa := indets([op(convert(Vraw,list)),",
        "op(convert(Craw,list))]) intersect ansatzcoeffs:\n",
      "          freeaarules := {seq(q=0,q in freeaa)}:\n",
      "          Vcandidate := map(normal,eval(Vraw,freeaarules)):\n",
      "          Ccandidate := map(normal,eval(Craw,freeaarules)):\n",
      "          Crules := {seq(C[i]=Ccandidate[i],",
        "i=1..", ToString[Length[mapleUnknowns]], ")}:\n",
      "          bcandidate := map(normal,eval(b",
        ToString[firstVariableIndex], ",Crules)):\n",
      "          candidatecheck := map(normal,evalm(map(diff,Vcandidate,",
        variableNames[[firstVariableIndex]], ")-A",
        ToString[firstVariableIndex], "&*Vcandidate-bcandidate)):\n",
      "          if convert(candidatecheck,set) = {0} then\n",
      "            V := Vcandidate: C := Ccandidate: solved := true:\n",
      "            method := cat(\"ExactLetterAnsatz:\",denpower,\":\",",
        "degreeoffset):\n",
      "          end if:\n",
      "        end if:\n",
      "      catch: errors := [op(errors),lastexception]: end try:\n",
      "    end do:\n",
      "  end do:\n",
      "end if:\n",
      "fd := fopen(\"", outputFile, "\", WRITE):\n",
      "if solved then fprintf(fd, \"OK\\n%a\\n%a\\n%s\\n\",",
        "convert(V,list),convert(C,list),method) ",
        "else fprintf(fd, \"FAIL\\n%a\\n%a\\n\",errors,attempts) ",
        "end if:\n",
      "fclose(fd):\nquit:\n"];
    Export[mapleFile, mapleText, "Text"];
    mapleCommand = If[
      $OperatingSystem === "Unix" &&
          FileExistsQ[$epsFormStripCPURunner],
      {$epsFormStripCPURunner, facetCPUList[],
        mapleExecutable, "-q", mapleFile},
      {mapleExecutable, "-q", mapleFile}];
    processCommand = If[
      $OperatingSystem === "Unix" && FileExistsQ["/usr/bin/timeout"],
      {"/usr/bin/timeout", "--signal=TERM", "--kill-after=5s",
        ToString[Ceiling[timeLimit]] <> "s", Sequence @@ mapleCommand},
      mapleCommand];
    {elapsed, process} = AbsoluteTiming[
      Quiet[TimeConstrained[
        RunProcess[processCommand], timeLimit + 15, $TimedOut]]];
    If[AssociationQ[process],
      Export[diagnosticFile, StringRiffle[{
        "ExitCode: " <> ToString[Lookup[process, "ExitCode", Missing[]]],
        "StandardOutput:", Lookup[process, "StandardOutput", ""],
        "StandardError:", Lookup[process, "StandardError", ""]}, "\n"],
        "Text"]];
    If[process === $TimedOut || ! FileExistsQ[outputFile],
      log["Maple produced no result for first variable ",
        firstVariableIndex, "; diagnostics: ", diagnosticFile];
      Continue[]];
    raw = Import[outputFile, "Text"];
    lines = StringSplit[raw, "\n"];
    If[lines === {} || First[lines] =!= "OK" || Length[lines] < 3,
      log["Maple result for first variable ", firstVariableIndex,
        ": ", If[lines === {}, "empty", First[lines]]];
      Continue[]];
    solutionText = lines[[2]];
    residueText = lines[[3]];
    methodText = If[Length[lines] >= 4, lines[[4]],
      "IntegrableConnections"];
    methodParts = StringSplit[methodText, ":"];
    mapleMethod = If[First[methodParts] === "ExactLetterAnsatz",
      "MapleExactLetterAnsatz", "MapleResidueCompatibility"];
    denominatorPower = If[Length[methodParts] >= 2,
      ToExpression[methodParts[[2]]], Missing["NotApplicable"]];
    numeratorOffset = If[Length[methodParts] >= 3,
      ToExpression[methodParts[[3]]], Missing["NotApplicable"]];

    (* The free constants Maple left in the answer are of TWO families
       and both must be read back: the unknowns we passed in, which print
       under the generated head, and Maple's OWN integration constants,
       which print as c[1], c[2], ... -- a Maple convention, not a name
       of ours, and the reason our external indices start at 1001.  The
       old code scanned a single "c[" pattern and so caught both by
       accident; naming ours privately (C5) makes the two patterns
       explicit.  Dropping Maple's constants here leaves them in the
       gauge and returns a different, non-minimal member of the
       solution family (measured 2026-08-23: 1/x*(x*c[1]+1) instead of
       1/x on the t_eps_form_strip fixture). *)
    indexedConstantTokens = Union[StringCases[
      solutionText <> residueText,
      (mapleUnknownName | "c") ~~ "[" ~~ DigitCharacter .. ~~ "]"]];
    indexedConstantSymbols = Table[
      Symbol[mapleFreeConstantPrefix <> ToString[i]],
      {i, Length[indexedConstantTokens]}];
    indexedConstantRules = Table[
      indexedConstantTokens[[i]] ->
        SymbolName[indexedConstantSymbols[[i]]],
      {i, Length[indexedConstantTokens]}];
    parseSymbolByName = Join[mapleSymbolByName,
      AssociationThread[
        SymbolName /@ indexedConstantSymbols -> indexedConstantSymbols]];
    parseMaple[text_] := Module[{parsed, rules},
      parsed = Block[{$Context = parseContext, $ContextPath = {"System`"}},
        ToExpression[StringReplace[text,
          Join[indexedConstantRules, {"[" -> "{", "]" -> "}"}]]]];
      rules = KeyValueMap[
        Function[{name, symbol}, Symbol[parseContext <> name] -> symbol],
        parseSymbolByName];
      normalizeRegulator[parsed /. rules]
    ];
    gaugeVectorParametric = Map[Together, parseMaple[solutionText]];
    residueValuesParametric = Map[Together, parseMaple[residueText]];
    If[Length[gaugeVectorParametric] =!= dimension ||
       Length[residueValuesParametric] =!= Length[freeResidues],
      log["Maple result has the wrong vector length."]; Continue[]];

    gaugeParametric = ArrayReshape[gaugeVectorParametric, shape];
    residueRulesParametric =
      Thread[freeResidues -> residueValuesParametric];
    forcingParametric = Map[Together,
      forcing /. residueRulesParametric, {3}];
    odeResidualParametric = Table[
      Map[Together,
        D[gaugeParametric, variables[[mu]]] -
          epsilon (e[[mu]].gaugeParametric -
            gaugeParametric.c[[mu]]) - forcingParametric[[mu]],
        {2}],
      {mu, 2}];
    parameterVariables = Select[indexedConstantSymbols,
      ! FreeQ[{gaugeParametric, residueValuesParametric}, #] &];
    parameterEquations = DeleteCases[DeleteDuplicates@Flatten[
      rationalZeroCoefficients[#, variables] & /@
        Flatten[odeResidualParametric]], 0];
    parameterSolutions = If[parameterEquations === {}, {{}},
      Quiet[Solve[
        Thread[parameterEquations == 0], parameterVariables]]];
    If[parameterSolutions === {}, Continue[]];
    parameterRules = First[parameterSolutions];
    If[parameterRules =!= {},
      parameterRules = FixedPoint[
        Function[rules,
          Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]],
        parameterRules,
        50]];
    remainingParameters = Select[parameterVariables,
      ! FreeQ[{gaugeParametric, residueValuesParametric} /.
        parameterRules, #] &];
    parameterRules = Join[
      parameterRules, Thread[remainingParameters -> 0]];

    gauge = Map[Together, gaugeParametric /. parameterRules, {2}];
    residueValues = Map[Together,
      residueValuesParametric /. parameterRules];
    residueRules = Thread[freeResidues -> residueValues];
    solvedForcing = Map[Together, forcing /. residueRules, {3}];
    residueMatrices = residueData["ResidueMatrices"] /. residueRules;
    dlog = residueData["DLog"];
    odeResidual = Table[
      Map[Together,
        D[gauge, variables[[mu]]] -
          epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
          solvedForcing[[mu]],
        {2}],
      {mu, 2}];
    transformedResidual = Table[
      Map[Together,
        bbar[[mu]] + epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
          D[gauge, variables[[mu]]] - epsilon Sum[
            residueMatrices[[a]] dlog[[a, mu]],
            {a, Length[residueMatrices]}],
        {2}],
      {mu, 2}];
    If[epsFormStripZeroQ[odeResidual] &&
       epsFormStripZeroQ[transformedResidual],
      result = <|
        "Status" -> "Solved",
        "Method" -> mapleMethod,
        "Gauge" -> gauge,
        "ResidueRules" -> residueRules,
        "ResidueMatrices" -> residueMatrices,
        "FreeResidues" -> freeResidues,
        "ParameterRules" -> parameterRules,
        "ParameterEquationCount" -> Length[parameterEquations],
        "Alphabet" -> residueData["Alphabet"],
        "FirstVariableIndex" -> firstVariableIndex,
        "FirstVariable" -> variables[[firstVariableIndex]],
        "LetterDenominatorPower" -> denominatorPower,
        "NumeratorDegreeOffset" -> numeratorOffset,
        "MapleSeconds" -> elapsed,
        "MapleMethodTimeLimit" -> methodTimeLimit,
        "ResiduePreparationSeconds" -> Total[Lookup[residueData,
          {"CompatibilitySeconds", "EquationSeconds", "SolveSeconds"}]],
        "ResidueKernels" -> residueKernels,
        "ODEEquationZero" -> True,
        "TransformedDLogZero" -> True,
        "ExactDLog" -> True
      |>;
      Break[]],
    {firstVariableIndex, 1, 2}];

  If[AssociationQ[result], result,
    Message[SolveResidueRationalGauge::maple]; $Failed]
];

epsFormStripSafeTag[tag_] := StringReplace[
  ToString[tag], RegularExpression["[^A-Za-z0-9_-]"] -> "_"];

epsFormStripRunCanonicaOne[
    strip : {_, _, _}, variables : {_, _}, epsilon_Symbol,
    alphabet_List, denominatorDegree_Integer, timeLimit_, degree_Integer] :=
 Module[
  {converted, findD, checkDlog, elapsed, gauge, transformed, exactQ},

  If[! epsFormStripLoadCanonica[],
    Return[<|"NumeratorDegree" -> degree,
      "DenominatorDegree" -> denominatorDegree,
      "Status" -> "CANONICAFunctionMissing", "ExactDLog" -> False|>]];
  converted = strip /. epsilon -> CANONICA`eps;
  findD = epsFormStripCanonicaSymbol["FindD"];
  checkDlog = epsFormStripCanonicaSymbol["CheckDlogForm"];
  If[MemberQ[{findD, checkDlog}, $Failed],
    Return[<|"NumeratorDegree" -> degree,
      "DenominatorDegree" -> denominatorDegree,
      "Status" -> "CANONICAFunctionMissing", "ExactDLog" -> False|>]];
  {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
    findD[converted[[1]], converted[[2]], converted[[3]], alphabet,
      variables, {}, CANONICA`DDeltaNumeratorDegree -> degree,
      CANONICA`DDeltaDenominatorDegree -> denominatorDegree,
      CANONICA`VerbosityLevel -> 0],
    timeLimit, $TimedOut]]];
  If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
    Return[<|"NumeratorDegree" -> degree,
      "DenominatorDegree" -> denominatorDegree, "Seconds" -> elapsed,
      "Status" -> Which[gauge === $TimedOut, "TimedOut",
        gauge === False, "NoGauge", True, "InvalidResult"],
      "ExactDLog" -> False|>]];
  transformed = Table[
    Map[Together,
      converted[[3, mu]] + CANONICA`eps (
        converted[[1, mu]].gauge - gauge.converted[[2, mu]]) -
        D[gauge, variables[[mu]]], {2}],
    {mu, Length[variables]}];
  exactQ = TrueQ[checkDlog[transformed, variables, alphabet]];
  <|"NumeratorDegree" -> degree,
    "DenominatorDegree" -> denominatorDegree, "Seconds" -> elapsed,
    "Status" -> If[exactQ, "ExactDLog", "FailedDLogIdentity"],
    "ExactDLog" -> exactQ,
    "Gauge" -> If[exactQ, gauge /. CANONICA`eps -> epsilon,
      Missing["Rejected"]]|>
];

epsFormStripRunCanonica[
    strip : {_, _, _}, variables : {_, _}, epsilon_Symbol,
    alphabet_List, degrees_List, denominatorDegree_Integer,
    timeLimit_, kernelCount_Integer] :=
 Module[
  {needed, launched = {}, canonicaFile, converted, rawResults = {},
   evaluations, next, remaining, completedDegrees = {},
   exactDegrees = {}, bestExactDegree, attempts = {}, candidates = {},
   raw, exact, summary},

  If[kernelCount <= 1,
    (* one kernel of our own: serial ladder, or -- inside a KernelPool
       mission -- degree 0 locally and the other degrees on the pool's
       free subkernels (TaskBroker.wl, 2026-08-21) *)
    rawResults = If[taskBrokerActiveQ[] && Length[degrees] > 1,
      taskBrokerCanonicaLadder[strip, variables, epsilon, alphabet,
        degrees, denominatorDegree, timeLimit],
      (epsFormStripRunCanonicaOne[
        strip, variables, epsilon, alphabet, denominatorDegree,
        timeLimit, #] &) /@ degrees],

  needed = Min[Length[degrees], kernelCount];
  If[Length[Kernels[]] < needed,
    launched = Quiet[LaunchKernels[needed - Length[Kernels[]]]]];
  If[Length[Kernels[]] < needed,
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    Return[<|
      "Attempts" -> (<|"NumeratorDegree" -> #,
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelKernelUnavailable",
        "ParentExactDLog" -> False|> & /@ degrees),
      "Candidates" -> {}|>]];

  canonicaFile = $epsFormStripCanonicaFile;
  With[{file = canonicaFile},
    ParallelEvaluate[
      If[DownValues[CANONICA`FindD] === {} &&
          DownValues[CANONICA`Private`FindD] === {},
        Block[{$Output = {}}, Quiet[Get[file], General::shdw]]];
      CANONICA`$ComputeParallel = False;
      CANONICA`Private`$ComputeParallel = False;
      Off[General::shdw];
    ]];
  converted = strip /. epsilon -> CANONICA`eps;
  evaluations = With[
    {ec = converted[[1]], cc = converted[[2]], bc = converted[[3]],
     vars = variables, letters = alphabet, denDegree = denominatorDegree,
     seconds = timeLimit, originalEpsilon = epsilon},
    Function[degree,
      With[{degreeValue = degree}, ParallelSubmit[
        Module[{findD, elapsed, gauge},
          findD = Which[
            DownValues[CANONICA`FindD] =!= {}, CANONICA`FindD,
            DownValues[CANONICA`Private`FindD] =!= {},
              CANONICA`Private`FindD,
            True, $Failed];
          If[findD === $Failed,
            Return[<|"NumeratorDegree" -> degreeValue,
              "DenominatorDegree" -> denDegree,
              "Status" -> "CANONICAFunctionMissing",
              "ExactDLog" -> False|>]];
          {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
            findD[ec, cc, bc, letters, vars, {},
              CANONICA`DDeltaNumeratorDegree -> degreeValue,
              CANONICA`DDeltaDenominatorDegree -> denDegree,
              CANONICA`VerbosityLevel -> 0],
            seconds, $TimedOut]]];
          If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
            Return[<|
              "NumeratorDegree" -> degreeValue,
              "DenominatorDegree" -> denDegree,
              "Seconds" -> elapsed,
              "Status" -> Which[
                gauge === $TimedOut, "TimedOut",
                gauge === False, "NoGauge",
                True, "InvalidResult"],
              "ExactDLog" -> False|>]];
          <|
            "NumeratorDegree" -> degreeValue,
            "DenominatorDegree" -> denDegree,
            "Seconds" -> elapsed,
            "Status" -> "CandidateGauge",
            "ExactDLog" -> Missing["ParentCheckPending"],
            "Gauge" -> gauge /. CANONICA`eps -> originalEpsilon|>
        ]]]] /@ degrees];
  remaining = evaluations;
  While[remaining =!= {},
    next = WaitNext[remaining];
    raw = next[[1]];
    remaining = next[[3]];
    If[AssociationQ[raw],
      AppendTo[completedDegrees,
        Lookup[raw, "NumeratorDegree", Infinity]];
      exact = ListQ[Lookup[raw, "Gauge", $Failed]] &&
        epsFormStripExactDLogQ[
          raw["Gauge"], strip, variables, epsilon, alphabet];
      raw = Join[raw, <|
        "Status" -> If[exact, "ExactDLog", "FailedDLogIdentity"],
        "ExactDLog" -> exact,
        "ParentExactDLog" -> exact|>];
      If[exact,
        AppendTo[exactDegrees, raw["NumeratorDegree"]];
        bestExactDegree = Min[exactDegrees];
        If[AllTrue[Select[degrees, # < bestExactDegree &],
            MemberQ[completedDegrees, #] &],
          (* abort only kernels this module launched: under a shared
             pool an unconditional AbortKernels[] kills sibling
             evaluations (2026-08-20 review) *)
          If[remaining =!= {} && launched =!= {},
            Quiet[AbortKernels[]]];
          remaining = {}]]];
    (* inside the While: every completed degree's result is recorded.
       A misplaced bracket here (found in the 2026-08-20 review) ran
       this append once, after the loop, so only the last-completed
       degree survived and an exactly-checked gauge could be silently
       discarded. *)
    AppendTo[rawResults, raw]];
  ParallelEvaluate[On[General::shdw]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]]];

  Do[
    If[AssociationQ[raw],
      exact = Lookup[raw, "ParentExactDLog", Missing["NotChecked"]];
      If[! MemberQ[{True, False}, exact],
        exact = TrueQ[Lookup[raw, "ExactDLog", False]] &&
          ListQ[Lookup[raw, "Gauge", $Failed]] &&
          epsFormStripExactDLogQ[
            raw["Gauge"], strip, variables, epsilon, alphabet]];
      summary = Join[
        KeyDrop[raw, "Gauge"],
        <|"ParentExactDLog" -> exact|>];
      If[exact,
        AppendTo[candidates,
          <|"NumeratorDegree" -> raw["NumeratorDegree"],
            "Gauge" -> raw["Gauge"], "Attempt" -> summary|>]],
      summary = <|
        "NumeratorDegree" -> Missing["Unknown"],
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelEvaluationFailed",
        "ParentExactDLog" -> False|>];
    AppendTo[attempts, summary],
    {raw, rawResults}];

  <|"Attempts" -> SortBy[attempts, Lookup[#, "NumeratorDegree", Infinity] &],
    "Candidates" -> SortBy[candidates, #["NumeratorDegree"] &]|>
];

Options[SolveEpsFormStrip] = {
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICADenominatorDegree" -> 0,
  "CANONICATimeLimit" -> 120,
  "CANONICAKernels" -> Automatic,
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "MapleTimeLimit" -> 1800,
  "MapleMethodTimeLimit" -> 120,
  "MapleResidueKernels" -> Automatic,
  "MapleLetterDenominatorPowers" -> {1, 2, 3},
  "MapleNumeratorDegreeOffsets" -> {0, 1, 2},
  "UseMaple" -> True,
  "ScratchDirectory" -> Automatic,
  "Tag" -> "strip",
  "Verbose" -> False
};

SolveEpsFormStrip[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {degrees, denominatorDegree, canonicaTime, canonicaKernels,
   mapleExecutable, mapleLibrary, mapleTime, mapleMethodTime,
   mapleResidueKernels,
   mapleDenominatorPowers,
   mapleNumeratorOffsets, scratchDirectory,
   tag, verbose, alphabet, converted, irreducibles,
   check, alreadyDLog, exactPotential, canonica, selected, maple, result},

  If[! epsFormStripShapeQ[strip],
    Message[SolveEpsFormStrip::shape]; Return[$Failed]];
  degrees = DeleteDuplicates[OptionValue["CANONICANumeratorDegrees"]];
  (* an EMPTY degree list means "dlog recognition only": the strip-method
     benchmark of 2026-08-22 (20 real strips) showed the finite field
     3-130x faster than the CANONICA ladder wherever both solve and the
     ladder burning 480 s on every strip it cannot solve, so the
     production route runs recognition, then the finite field *)
  If[! AllTrue[degrees, IntegerQ[#] && # >= 0 &],
    Message[SolveEpsFormStrip::degrees]; Return[$Failed]];
  denominatorDegree = OptionValue["CANONICADenominatorDegree"];
  canonicaTime = OptionValue["CANONICATimeLimit"];
  canonicaKernels = facetKernelCount[
    OptionValue["CANONICAKernels"], Length[degrees]];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = OptionValue["MapleLibrary"];
  mapleTime = OptionValue["MapleTimeLimit"];
  mapleMethodTime = OptionValue["MapleMethodTimeLimit"];
  mapleResidueKernels = facetKernelCount[
    OptionValue["MapleResidueKernels"]];
  mapleDenominatorPowers = OptionValue[
    "MapleLetterDenominatorPowers"];
  mapleNumeratorOffsets = OptionValue[
    "MapleNumeratorDegreeOffsets"];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];
  If[! epsFormStripLoadCanonica[],
    Message[SolveEpsFormStrip::canonica, $epsFormStripCanonicaFile];
    Return[$Failed]];

  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  exactPotential = epsFormStripExactPotentialGauge[
    strip, variables, epsilon, alphabet];
  If[ListQ[exactPotential],
    Return[<|
      "Status" -> "Solved",
      "Method" -> "ExactPotential",
      "Gauge" -> exactPotential,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];
  converted = strip /. epsilon -> CANONICA`eps;
  irreducibles = epsFormStripCanonicaSymbol["ExtractIrreducibles"][
    converted, CANONICA`AllowEpsDependence -> True];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  alreadyDLog = FreeQ[irreducibles, CANONICA`eps] &&
    (epsFormStripZeroQ[converted[[3]]] ||
      TrueQ[check[converted[[3]], variables, alphabet]]);
  If[alreadyDLog,
    Return[<|
      "Status" -> "Solved",
      "Method" -> "AlreadyDLog",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];

  If[verbose,
    Print["CANONICA strip search: numerator degrees ", degrees,
      ", ", canonicaTime, " s each"]];
  canonica = If[degrees === {}, <|"Attempts" -> {}, "Candidates" -> {}|>,
    epsFormStripRunCanonica[
      strip, variables, epsilon, alphabet, degrees, denominatorDegree,
      canonicaTime, canonicaKernels]];
  If[canonica["Candidates"] =!= {},
    selected = First[canonica["Candidates"]];
    result = <|
      "Status" -> "Solved",
      "Method" -> "CANONICA",
      "Gauge" -> selected["Gauge"],
      "NumeratorDegree" -> selected["NumeratorDegree"],
      "DenominatorDegree" -> denominatorDegree,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> canonica["Attempts"]
    |>;
    Return[result]];

  (* "UseMaple" -> False: dlog recognition + CANONICA ladder only (the
     strip-method benchmark of 2026-08-21 measures the routes separately) *)
  If[! TrueQ[OptionValue["UseMaple"]],
    Return[<|"Status" -> If[degrees === {}, "NotRecognized", "CANONICAFailed"],
      "Method" -> If[degrees === {}, "Recognition", "CANONICA"],
      "CANONICAAttempts" -> canonica["Attempts"]|>]];
  If[verbose, Print["CANONICA found no exact dlog gauge; invoking Maple"]];
  maple = SolveResidueRationalGauge[
    strip, variables, epsilon,
    "MapleExecutable" -> mapleExecutable,
    "MapleLibrary" -> mapleLibrary,
    "ScratchDirectory" -> scratchDirectory,
    "Tag" -> tag,
    "TimeLimit" -> mapleTime,
    "MethodTimeLimit" -> mapleMethodTime,
    "ResidueKernels" -> mapleResidueKernels,
    "LetterDenominatorPowers" -> mapleDenominatorPowers,
    "NumeratorDegreeOffsets" -> mapleNumeratorOffsets,
    "Verbose" -> verbose];
  If[AssociationQ[maple],
    Return[Join[maple,
      <|"CANONICAAttempts" -> canonica["Attempts"]|>]]];

  Message[SolveEpsFormStrip::failed];
  $Failed
];
