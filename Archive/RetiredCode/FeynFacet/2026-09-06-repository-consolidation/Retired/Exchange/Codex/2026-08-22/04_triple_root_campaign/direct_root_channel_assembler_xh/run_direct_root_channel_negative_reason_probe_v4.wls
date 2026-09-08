#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["DRCA_NEGATIVE_REASON_V4 FAIL usage=<project-root> " <>
    "<fresh-output.wl>"];
  Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
expectedAssemblerHash =
  "10d9aa51e5d184abffab2fc3efc9b9806ac73cf9e7247cc0f37b8767353609fa";
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;
If[! DirectoryQ[projectRoot] || ! FileExistsQ[assemblerFile] ||
    FileHash[assemblerFile, "SHA256", "HexString"] =!=
      expectedAssemblerHash ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Exit[65]];

writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];
sourceHashes[] := <|
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedHashes = sourceHashes[];

savedMessages = $Messages;
messageFile = outputFile <> ".messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
messageStream = OpenWrite[messageFile, CharacterEncoding -> "UTF8"];
$Messages = {messageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[dependencyFiles["TripleRootReconstructionPrototype"]];
  Get[assemblerFile];
  True, $Failed];

Clear[x, y, eps];
rootSquares = {x + 3, y + 5, x + y + 7};
roots = <|"Root" -> Sqrt[#1], "RootSquare" -> #1|> & /@ rootSquares;
makeField[seed_Integer] := CodexTripleRootStrip`TRFieldCompose[
  Table[Together[(seed + 3 grade + eps (1 + grade) x +
      (2 + grade) y)/(1 + x + 2 y)], {grade, 0, 7}], roots];
record = <|"Family" -> "DRCANegativeReasonV4", "Sector" -> 3,
  "LowerSector" -> 0, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {
    Table[makeField[20 mu + 5 i + j], {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[50 mu + 7 i + 2 j],
      {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[90 mu + 11 i + 3 j],
      {mu, 2}, {i, 2}, {j, 2}]}|>;
oneForms = Table[{makeField[130 + 9 letter],
  makeField[170 + 11 letter]}, {letter, 2}];
gaugeDenominator = (1 + x) (1 + y);
assembly = CodexDirectRootChannelAssembler`DRCACompileSystem[
  record, roots, oneForms, gaugeDenominator,
  {{0, 0}, {0, 1}, {1, 0}}, {}, <|
    "SourceABIFingerprint" -> "negative-reason-probe-v4",
    "RootOrderingFingerprint" -> Hash[
      rootSquares, "SHA256", "HexString"]|>];
epsilonForms = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
  assembly, 10007, 1/21];
zeroGaugePoint = {10006, 2};
zeroDeltaPoint = {10004, 2};
zeroGaugeResult = CodexDirectRootChannelAssembler`DRCAAssemblePoint[
  assembly, epsilonForms, 10007, zeroGaugePoint];
zeroDeltaResult = CodexDirectRootChannelAssembler`DRCAAssemblePoint[
  assembly, epsilonForms, 10007, zeroDeltaPoint];

Close[messageStream];
$Messages = savedMessages;
messages = Quiet[Check[Import[messageFile, "Text"], $Failed]];
If[FileExistsQ[messageFile], Quiet[DeleteFile[messageFile]]];
completionHashes = sourceHashes[];
hashesStable = TrueQ[completionHashes === expectedHashes];
messagesEmpty = StringQ[messages] && StringTrim[messages] === "";
passed = TrueQ[loadOutcome === True &&
  AssociationQ[zeroGaugeResult] &&
  Lookup[zeroGaugeResult, "FailureReason", None] ===
    "RationalChannelPole" &&
  AssociationQ[zeroDeltaResult] &&
  Lookup[zeroDeltaResult, "FailureReason", None] ===
    "RationalChannelPole" && messagesEmpty && hashesStable];
status = If[passed, "DirectRootChannelNegativeReasonProbeV4Passed",
  "DirectRootChannelNegativeReasonProbeV4Failed"];
report = <|"Status" -> status,
  "Protocol" -> "DirectRootChannelNegativeReasonProbeV4",
  "PinnedPreGuardAssemblerSHA256" -> expectedAssemblerHash,
  "ZeroGaugePoint" -> zeroGaugePoint,
  "ZeroGaugeResult" -> zeroGaugeResult,
  "ZeroDeltaPoint" -> zeroDeltaPoint,
  "ZeroDeltaResult" -> zeroDeltaResult,
  "Interpretation" ->
    "Dependent logarithmic-derivative poles mask typed primitive guards",
  "CapturedMessages" -> messages, "MessagesEmpty" -> messagesEmpty,
  "ExpectedSourceHashes" -> expectedHashes,
  "CompletionSourceHashes" -> completionHashes,
  "SourceHashesStableAtCompletion" -> hashesStable|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCA_NEGATIVE_REASON_V4 status=", status,
  " output=", outputFile];
Exit[If[passed, 0, 1]];
