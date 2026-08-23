#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["DRCAV2_ADVERSARIAL FAIL usage=<project-root> <fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
assemblerFile = FileNameJoin[{assemblerDirectory,
  "DirectRootChannelAssembler.wl"}];
compilerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelCompilerV2.wl"}];
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
    ! FileExistsQ[compilerFile] ||
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
  "CompilerV2" -> FileHash[compilerFile, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedHashes = sourceHashes[];

savedMessages = $Messages;
loadMessageFile = outputFile <> ".load-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
loadMessageStream = OpenWrite[loadMessageFile, CharacterEncoding -> "UTF8"];
$Messages = {loadMessageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[dependencyFiles["TripleRootReconstructionPrototype"]];
  Get[assemblerFile];
  Get[compilerFile];
  True, $Failed];
Close[loadMessageStream];
$Messages = savedMessages;
loadMessages = Quiet[Check[Import[loadMessageFile, "Text"], $Failed]];
If[FileExistsQ[loadMessageFile], Quiet[DeleteFile[loadMessageFile]]];
If[loadOutcome =!= True || ! StringQ[loadMessages] ||
    StringTrim[loadMessages] =!= "" || sourceHashes[] =!= expectedHashes,
  report = <|"Status" -> "DirectRootChannelCompilerV2LoadFailed",
    "LoadOutcome" -> loadOutcome, "CapturedLoadMessages" -> loadMessages,
    "ExpectedSourceHashes" -> expectedHashes,
    "ObservedSourceHashes" -> sourceHashes[]|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[66]];

runtimeMessageFile = outputFile <> ".runtime-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
runtimeMessageStream = OpenWrite[runtimeMessageFile,
  CharacterEncoding -> "UTF8"];
$Messages = {runtimeMessageStream};
results = {};
caseSummaries = {};
recordCheck[label_String, condition_, details_: <||>] := Module[{passed},
  passed = TrueQ[condition];
  AppendTo[results, <|"Label" -> label, "Passed" -> passed,
    "Details" -> details|>];
  Print[If[passed, "PASS ", "FAIL "] <> label];
  passed
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

Clear[x, y, eps];
allRootSquares = {x + 3, y + 5, x y + x + y + 7};
allRoots = <|"Root" -> Sqrt[#1], "RootSquare" -> #1|> & /@
  allRootSquares;

makeChannels[seed_Integer, roots_List] := Table[Together[
  (seed + 2 grade + (grade + 1) x + (seed + grade) y +
      eps (1 + grade x))/((2 + x) (3 + y))],
  {grade, 0, 2^Length[roots] - 1}];
makeDenominatorChannels[seed_Integer, roots_List] := Table[Together[
  If[grade === 0, (11 + seed + x + y)/(5 + x + y),
    (grade + seed)/(37 + 3 grade + x + 2 y)]],
  {grade, 0, 2^Length[roots] - 1}];
makeField[seed_Integer, roots_List] := Module[{numerator, denominator},
  numerator = CodexTripleRootStrip`TRFieldCompose[
    makeChannels[seed, roots], roots];
  denominator = CodexTripleRootStrip`TRFieldCompose[
    makeDenominatorChannels[seed, roots], roots];
  Together[numerator/denominator]
];
makeRecord[roots_List] := Module[{a, b},
  a = makeField[7, roots];
  b = makeField[13, roots];
  <|"Family" -> "DRCAV2Synthetic", "Sector" -> Length[roots],
    "LowerSector" -> 0, "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {{{{a}}, {{a}}}, {{{a}}, {{b}}},
      {{{b}}, {{a}}}}|>
];
makeForms[roots_List] := {{makeField[19, roots], makeField[23, roots]}};
gaugeDenominator = (1 + x) (1 + y);
baseSupport = {{0, 0}, {0, 1}, {1, 0}};
extendedSupport = Append[baseSupport, {1, 1}];
comparisonKeys = {"Status", "SourceABIFingerprint",
  "RootOrderingFingerprint", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelForms", "CompiledForms",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "SourceSemanticFingerprint",
  "AssemblyFingerprint"};

Do[
  roots = Take[allRoots, rank];
  sourceRecord = makeRecord[roots];
  oneForms = makeForms[roots];
  metadata = <|"SourceABIFingerprint" ->
      fingerprint[{"DRCAV2Synthetic", rank}],
    "RootOrderingFingerprint" ->
      fingerprint[Lookup[roots, "RootSquare", {}]]|>;
  {legacySeconds, legacy} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      sourceRecord, roots, oneForms, gaugeDenominator, baseSupport, {},
      metadata]];
  {v2Seconds, v2} = AbsoluteTiming[
    CodexDirectRootChannelCompilerV2`DRCAV2CompileSystem[
      sourceRecord, roots, oneForms, gaugeDenominator, baseSupport, {},
      metadata]];
  v1View = CodexDirectRootChannelCompilerV2`DRCAV2ToV1Assembly[v2];
  valid = AssociationQ[legacy] && AssociationQ[v2] &&
    AssociationQ[v1View] &&
    CodexDirectRootChannelCompilerV2`DRCAV2AssemblyValidQ[v2] &&
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[v1View];
  exactEqual = valid && SameQ[
    KeyTake[v1View, comparisonKeys], KeyTake[legacy, comparisonKeys]];
  recordCheck["rank-" <> ToString[rank] <> "-v1-exact-assembly", exactEqual,
    <|"LegacySeconds" -> N[legacySeconds], "V2Seconds" -> N[v2Seconds],
      "LegacyFingerprint" -> Lookup[legacy, "AssemblyFingerprint", None],
      "V2AdapterFingerprint" ->
        Lookup[v1View, "AssemblyFingerprint", None]|>];
  If[valid,
    legacyEpsilon = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      legacy, 10007, 1/21];
    v2Epsilon = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      v1View, 10007, 1/21];
    legacyPoint = CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      legacy, legacyEpsilon, 10007, {11, 19}];
    v2Point = CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      v1View, v2Epsilon, 10007, {11, 19}];
    recordCheck["rank-" <> ToString[rank] <> "-point-differential",
      Lookup[legacyPoint, "Status", None] ===
        "AssembledDirectRootChannelPointV1" &&
      Lookup[v2Point, "Status", None] ===
        "AssembledDirectRootChannelPointV1" &&
      legacyPoint["Rows"] === v2Point["Rows"] &&
      legacyPoint["RightHandSide"] === v2Point["RightHandSide"],
      <|"Point" -> {11, 19}, "Prime" -> 10007|>],
    recordCheck["rank-" <> ToString[rank] <> "-point-differential",
      False, <|"Reason" -> "CompileOrValidationFailed"|>]];
  If[AssociationQ[v2],
    coreTelemetry = v2["Core", "Telemetry"];
    recordCheck["rank-" <> ToString[rank] <> "-telemetry-contract",
      AssociationQ[coreTelemetry] &&
      Lookup[coreTelemetry["RationalBundle"],
        "RootFreeFastPathCount", 0] > 0 &&
      Lookup[coreTelemetry["AlgebraicBundle"], "ScalarPoolHits", 0] > 0 &&
      If[rank === 0,
        Lookup[coreTelemetry["AlgebraicBundle"],
          "RootFreeFastPathCount", 0] > 0,
        Lookup[coreTelemetry["AlgebraicBundle"],
          "RecursiveInverseCalls", 0] > 0 &&
        Lookup[coreTelemetry["AlgebraicBundle"],
          "IndependentInverseChecks", 0] > 0], coreTelemetry],
    recordCheck["rank-" <> ToString[rank] <> "-telemetry-contract",
      False, <||>]];
  AppendTo[caseSummaries, <|"Rank" -> rank,
    "LegacySeconds" -> N[legacySeconds], "V2Seconds" -> N[v2Seconds],
    "AssemblyExact" -> exactEqual|>],
  {rank, 0, 3}];

roots = Take[allRoots, 2];
sourceRecord = makeRecord[roots];
oneForms = makeForms[roots];
metadata = <|"SourceABIFingerprint" -> fingerprint["rebind"],
  "RootOrderingFingerprint" ->
    fingerprint[Lookup[roots, "RootSquare", {}]]|>;
baseAssembly = CodexDirectRootChannelCompilerV2`DRCAV2CompileSystem[
  sourceRecord, roots, oneForms, gaugeDenominator, baseSupport, {}, metadata];
supportRebind = CodexDirectRootChannelCompilerV2`DRCAV2RebindAnsatz[
  baseAssembly, oneForms, extendedSupport, {}];
supportFresh = CodexDirectRootChannelCompilerV2`DRCAV2InstantiateAnsatz[
  baseAssembly["Core"], oneForms, extendedSupport, {}];
recordCheck["support-only-rebind-is-compile-free-and-exact",
  Lookup[supportRebind, "Status", None] ===
      "PreparedDirectRootChannelsV2" &&
  supportRebind["Telemetry", "Mode"] === "SupportOrNormalizationOnly" &&
  supportRebind["CompatibilityAssemblyV1"] ===
    supportFresh["CompatibilityAssemblyV1"], <||>];

extendedForms = Join[oneForms,
  {{makeField[29, roots], makeField[31, roots]}}];
formRebind = CodexDirectRootChannelCompilerV2`DRCAV2RebindAnsatz[
  baseAssembly, extendedForms, baseSupport, {}];
formFresh = CodexDirectRootChannelCompilerV2`DRCAV2InstantiateAnsatz[
  baseAssembly["Core"], extendedForms, baseSupport, {}];
recordCheck["one-form-prefix-extension-compiles-only-suffix-and-is-exact",
  Lookup[formRebind, "Status", None] ===
      "PreparedDirectRootChannelsV2" &&
  formRebind["Telemetry", "Mode"] === "OneFormPrefixExtension" &&
  formRebind["Telemetry", "AppendedOneFormCount"] === 1 &&
  formRebind["CompatibilityAssemblyV1"] ===
    formFresh["CompatibilityAssemblyV1"], <||>];

nonPrefixForms = ReplacePart[extendedForms, 1 -> Last[extendedForms]];
recordCheck["non-prefix-one-form-change-rejected",
  Lookup[CodexDirectRootChannelCompilerV2`DRCAV2RebindAnsatz[
      baseAssembly, nonPrefixForms, baseSupport, {}],
    "FailureReason", None] === "OneFormsNotPrefixExtension", <||>];

zeroDivisorInverse =
  CodexDirectRootChannelCompilerV2`Private`drcav2RecursiveFieldInverse[
    {1, 1}, {1}, <||>];
recordCheck["recursive-norm-zero-divisor-fails-closed",
  zeroDivisorInverse === $Failed, <||>];

goodInverse =
  CodexDirectRootChannelCompilerV2`Private`drcav2RecursiveFieldInverse[
    {2, 3}, {x + 3}, <||>];
recordCheck["recursive-norm-inverse-independent-check",
  AssociationQ[goodInverse] &&
  CodexDirectRootChannelCompilerV2`Private`drcav2ZeroQ[
    CodexTripleRoot`TRMultiply[{2, 3}, goodInverse["Inverse"], {x + 3}] -
      {1, 0}], <||>];

tooManyRoots = Join[allRoots,
  {<|"Root" -> Sqrt[x + 2 y + 11],
    "RootSquare" -> x + 2 y + 11|>}];
recordCheck["rank-four-rejected",
  Lookup[CodexDirectRootChannelCompilerV2`DRCAV2CompileCore[
      makeRecord[{}], tooManyRoots, gaugeDenominator],
    "FailureReason", None] === "InvalidCoreInput", <||>];

fractionalRecord = makeRecord[{}];
fractionalRecord = ReplacePart[fractionalRecord,
  {"Strip", 3, 1, 1, 1} -> x^(1/3)];
recordCheck["unsupported-fractional-power-rejected",
  Lookup[CodexDirectRootChannelCompilerV2`DRCAV2CompileSystem[
      fractionalRecord, {}, {}, gaugeDenominator, baseSupport],
    "Status", None] === "DirectRootChannelCompilerV2Failure", <||>];

corruptPool = ReplacePart[baseAssembly,
  {"PolynomialPoolSeed", "Values", 1} ->
    (baseAssembly["PolynomialPoolSeed", "Values", 1] + 1)];
recordCheck["polynomial-pool-corruption-rejected",
  ! CodexDirectRootChannelCompilerV2`DRCAV2AssemblyValidQ[corruptPool],
  <||>];
corruptSource = ReplacePart[baseAssembly,
  "CompilerSourceSHA256" -> StringReverse[
    baseAssembly["CompilerSourceSHA256"]]];
recordCheck["compiler-source-corruption-rejected",
  ! CodexDirectRootChannelCompilerV2`DRCAV2AssemblyValidQ[corruptSource],
  <||>];

Close[runtimeMessageStream];
$Messages = savedMessages;
runtimeMessages = Quiet[Check[Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
hashesStable = TrueQ[sourceHashes[] === expectedHashes];
messagesEmpty = StringQ[runtimeMessages] && StringTrim[runtimeMessages] === "";
passedCount = Count[Lookup[results, "Passed", False], True];
failedLabels = Lookup[Select[results, ! TrueQ[#1["Passed"]] &],
  "Label", {}];
allPassed = failedLabels === {} && hashesStable && messagesEmpty;
report = <|
  "Status" -> If[allPassed,
    "DirectRootChannelCompilerV2AdversarialPassed",
    "DirectRootChannelCompilerV2AdversarialFailed"],
  "Protocol" -> "DirectRootChannelCompilerV2DifferentialV1",
  "PassCount" -> passedCount, "CheckCount" -> Length[results],
  "FailedLabels" -> failedLabels, "Checks" -> results,
  "CaseSummaries" -> caseSummaries,
  "CapturedRuntimeMessages" -> runtimeMessages,
  "MessagesEmpty" -> messagesEmpty,
  "SourceHashesStable" -> hashesStable,
  "ExpectedSourceHashes" -> expectedHashes,
  "ObservedSourceHashes" -> sourceHashes[]|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCAV2_ADVERSARIAL status=", report["Status"],
  " pass=", passedCount, "/", Length[results], " output=", outputFile];
Exit[If[allPassed, 0, 1]];
