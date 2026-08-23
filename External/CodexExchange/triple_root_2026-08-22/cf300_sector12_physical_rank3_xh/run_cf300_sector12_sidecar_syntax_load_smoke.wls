#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["CF300S12SMOKE FAIL usage=<project-root> <result.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
resultFile = ExpandFileName[arguments[[2]]];
If[FileExistsQ[resultFile] || FileExistsQ[resultFile <> ".tmp"],
  Print["CF300S12SMOKE FAIL stale result target"];
  Exit[93]];
scriptDirectory = DirectoryName[$InputFileName];
targets = FileNameJoin[{scriptDirectory, #1}] & /@ {
  "run_cf300_sector12_sidecar_derivation.wls",
  "run_cf300_sector12_sidecar_checked.wls",
  "run_cf300_sector12_safety_adversarial_smoke.wls",
  "run_cf300_sector12_rank3_census.wls",
  "run_cf300_physical_rank3_reconstruction.wls",
  "run_cf300_rank2_cross_prime_plan_adversarial_smoke.wls",
  "run_cf300_sector12_rank2_extension_prepare.wls",
  "run_cf300_sector12_rank2_extension_prime.wls",
  "run_cf300_sector12_rank2_extension_aggregate.wls"};
tripleRootAlgebraFile = FileNameJoin[{DirectoryName[scriptDirectory],
  "TripleRootAlgebra.wl"}];
stripAdapterFile = FileNameJoin[{DirectoryName[scriptDirectory],
  "TripleRootStripAdapter.wl"}];
affinePilotFile = FileNameJoin[{DirectoryName[scriptDirectory],
  "TripleRootAffinePilot.wl"}];
reconstructionPrototypeFile = FileNameJoin[{
  DirectoryName[scriptDirectory],
  "TripleRootReconstructionPrototype.wl"}];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet",
    "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> tripleRootAlgebraFile,
  "TripleRootStripAdapter" -> stripAdapterFile,
  "TripleRootAffinePilot" -> affinePilotFile,
  "TripleRootReconstructionPrototype" ->
    reconstructionPrototypeFile|>;
sourceFiles = Join[targets, Values[dependencyFiles]];
If[! AllTrue[sourceFiles, FileExistsQ],
  Print["CF300S12SMOKE FAIL missing source target"];
  Exit[65]];
sourceHashesBefore = AssociationMap[
  FileHash[#1, "SHA256", "HexString"] &, sourceFiles];
parseContextPrefix = "CF300S12SyntaxParse`c";

writeAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file],
      CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> False]
];

parseFile[file_String, globalBefore_List] := Module[
  {text, lines, body, held, parseContext, newGlobal, parseFailed},
  text = Quiet[Check[Import[file, "Text"], $Failed]];
  If[! StringQ[text], Return[{False, None}]];
  lines = StringSplit[text, "\n"];
  body = If[lines =!= {} && StringStartsQ[First[lines], "#!"],
    StringRiffle[Rest[lines], "\n"], text];
  (* Held parsing still interns names.  Isolate each target in a valid
     disposable context with only System` visible, and remove both that
     context and any explicitly-qualified Global` names on every exit. *)
  parseContext = parseContextPrefix <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  held = CheckAbort[
    Block[{$Context = parseContext, $ContextPath = {"System`"}},
      Quiet[Check[ToExpression[body, InputForm, HoldComplete],
        $Failed]]],
    (held =.;
     newGlobal = Complement[System`Names["Global`*"], globalBefore];
     Scan[(Quiet[System`Remove[#1]]) &, newGlobal];
     Quiet[System`Remove[parseContext <> "*"]];
     Abort[])];
  parseFailed = held === $Failed || Head[held] =!= HoldComplete;
  held =.;
  {! TrueQ[parseFailed], parseContext}
];

createdParseContexts = {};
parseDiagnostics = <||>;
parseGates = <||>;
createdContextResidualsRaw = <||>;
createdContextResidualDiagnostics = <||>;
globalAdded = {};
globalRemoved = {};
parserIsolationGates = <||>;

nameSummary[names_List] := Module[{ordered = Sort[names]},
  <|"Count" -> Length[ordered],
    "SHA256" -> Hash[ordered, "SHA256", "HexString"],
    "Sample" -> Take[ordered, UpTo[5]]|>
];

residualConfinedToContextQ[context_String, names_List] :=
  AllTrue[names, StringStartsQ[#1, context] &&
    ! StringContainsQ[StringDrop[#1, StringLength[context]], "`"] &];

parseTarget[file_String] := Module[
  {globalBefore, outcome, parsedQ, parseContext, globalIntroduced,
   globalAfter, added, removed, residual},
  globalBefore = System`Names["Global`*"];
  outcome = parseFile[file, globalBefore];
  parsedQ = MatchQ[outcome, {True, _String}];
  parseContext = If[MatchQ[outcome, {_?BooleanQ, _String}],
    outcome[[2]], None];
  If[StringQ[parseContext], AppendTo[createdParseContexts, parseContext]];
  (* Normal cleanup deliberately happens only after parseFile has returned,
     so its held syntax tree is no longer retained on that evaluator stack. *)
  globalIntroduced = Complement[
    System`Names["Global`*"], globalBefore];
  Scan[(Quiet[System`Remove[#1]]) &, globalIntroduced];
  If[StringQ[parseContext],
    Quiet[System`Remove[parseContext <> "*"]]];
  globalAfter = System`Names["Global`*"];
  added = Complement[globalAfter, globalBefore];
  removed = Complement[globalBefore, globalAfter];
  residual = If[StringQ[parseContext],
    System`Names[parseContext <> "*"], {}];
  AssociateTo[parseDiagnostics, file -> <|
    "ParsedQ" -> parsedQ, "Context" -> parseContext,
    "GlobalIntroducedBeforeCleanup" -> nameSummary[globalIntroduced],
    "GlobalAdded" -> added, "GlobalRemoved" -> removed,
    "ContextResidual" -> Join[nameSummary[residual], <|
      "ConfinedToExactContextQ" -> If[StringQ[parseContext],
        residualConfinedToContextQ[parseContext, residual],
        residual === {}]|>]|>];
  parsedQ
];

parseGates = AssociationMap[parseTarget, targets];
createdContextResidualsRaw = AssociationMap[
  System`Names[#1 <> "*"] &, createdParseContexts];
createdContextResidualDiagnostics = Association[
  KeyValueMap[Function[{context, names}, context ->
    Join[nameSummary[names], <|
      "ConfinedToExactContextQ" ->
        residualConfinedToContextQ[context, names]|>]],
    createdContextResidualsRaw]];
globalAdded = DeleteDuplicates[Flatten[
  Lookup[Values[parseDiagnostics], "GlobalAdded", {}]]];
globalRemoved = DeleteDuplicates[Flatten[
  Lookup[Values[parseDiagnostics], "GlobalRemoved", {}]]];
parserIsolationGates = <|
  "CreatedContextsUnique" ->
    Length[createdParseContexts] ===
      Length[DeleteDuplicates[createdParseContexts]],
  "CreatedContextsAbsentFromContextPath" ->
    Intersection[createdParseContexts, $ContextPath] === {},
  "ResidualSymbolsConfinedToExactCreatedContexts" ->
    AllTrue[KeyValueMap[residualConfinedToContextQ,
      createdContextResidualsRaw], TrueQ],
  "NoGlobalSymbolsAddedAfterCleanup" -> globalAdded === {},
  "NoGlobalSymbolsRemovedAfterCleanup" -> globalRemoved === {}|>;
dependencyHashSmoke = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
messageCount = Length[$MessageList];
Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[tripleRootAlgebraFile];
Get[stripAdapterFile];
Get[affinePilotFile];
Get[reconstructionPrototypeFile];
canonicalSolveSmoke =
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    {{1, 2, 0}, {0, 1, 1}}, {3, 4}, 103];
newMessages = Drop[$MessageList, messageCount];
dependencyGates = <|
  "DependencyManifestValueMapping" ->
    AssociationQ[dependencyHashSmoke] &&
      Keys[dependencyHashSmoke] === Keys[dependencyFiles] &&
      AllTrue[Values[dependencyHashSmoke], StringQ],
  "FamilyRowGaugeApplyLoaded" ->
    Length[DownValues[FeynFacet`Private`familyRowGaugeApply]] > 0,
  "CheckpointGaugeShapeValidatorLoaded" ->
    Length[DownValues[
      FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ]] > 0,
  "CheckpointSolverValidatorLoaded" ->
    Length[DownValues[
      FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ]] > 0,
  "ReplayAllHydratorLoaded" ->
    Length[DownValues[
      FeynFacet`Private`familyRowGaugeHydrateResume]] > 0,
  "StripClassifierLoaded" ->
    Length[DownValues[CodexTripleRootStrip`TRClassifyStripRecord]] > 0,
  "StripDecomposerLoaded" ->
    Length[DownValues[CodexTripleRootStrip`TRDecomposeStripRecord]] > 0,
  "LocalChannelLiftLoaded" ->
    Length[DownValues[CodexTripleRootStrip`TRLiftLocalChannels]] > 0,
  "Rank0PolynomialReducerLoaded" ->
    Length[DownValues[CodexTripleRoot`TRFromPolynomial]] > 0,
  "RationalAffinePrimeInterpolatorLoaded" ->
    Length[DownValues[
      CodexTripleRootReconstruction`TRInterpolateRationalAffinePrime]] > 0,
  "RationalAffineBatchLifterLoaded" ->
    Length[DownValues[
      CodexTripleRootReconstruction`TRLiftRationalAffineBatch]] > 0,
  "CrossPrimeEliminationPlanValidatorLoaded" ->
    Length[DownValues[
      CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ]] > 0,
  "CanonicalAffineSolveSemanticSmoke" ->
    AssociationQ[canonicalSolveSmoke] &&
      Lookup[canonicalSolveSmoke, "Status", None] ===
        "CanonicalAffineSolution" &&
      Lookup[canonicalSolveSmoke, "Rank", None] === 2 &&
      Lookup[canonicalSolveSmoke, "Nullity", None] === 1 &&
      TrueQ[Lookup[canonicalSolveSmoke, "ResidualZero", False]] &&
      TrueQ[Lookup[canonicalSolveSmoke,
        "NullspaceResidualZero", False]]|>;
sourceHashesAtCompletion = AssociationMap[
  FileHash[#1, "SHA256", "HexString"] &, sourceFiles];
cleanQ = sourceHashesAtCompletion === sourceHashesBefore &&
  AllTrue[Values[parseGates], TrueQ] &&
  AllTrue[Values[parserIsolationGates], TrueQ] &&
  AllTrue[Values[dependencyGates], TrueQ] && newMessages === {};
result = <|"Status" -> If[cleanQ, "SyntaxLoadSmokePassed",
    "SyntaxLoadSmokeFailed"],
  "ParseGates" -> parseGates,
  "ParserIsolationGates" -> parserIsolationGates,
  "ParserIsolationDiagnostics" -> <|
    "GlobalAdded" -> globalAdded, "GlobalRemoved" -> globalRemoved,
    "CreatedContexts" -> createdParseContexts,
    "CreatedContextResiduals" -> createdContextResidualDiagnostics,
    "PerTarget" -> parseDiagnostics|>,
  "DependencyGates" -> dependencyGates,
  "SourceHashesStable" ->
    sourceHashesAtCompletion === sourceHashesBefore,
  "MessageNames" -> newMessages,
  "TargetHashes" -> KeyTake[sourceHashesBefore, targets],
  "DependencyHashes" -> AssociationThread[
    Keys[dependencyFiles],
    Lookup[sourceHashesBefore, Values[dependencyFiles]]]|>;
writeAtomic[result, resultFile];
Print["CF300S12SMOKE RESULT status=", result["Status"],
  " output=", resultFile];
Exit[If[cleanQ, 0, 92]];
