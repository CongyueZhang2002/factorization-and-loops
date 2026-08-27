#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = FileNameJoin[{projectRoot, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
assemblerFile = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh", "DirectRootChannelAssembler.wl"}];
files = {
  FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}],
  FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}],
  FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}],
  FileNameJoin[{exchangeDirectory, "TripleRootAffinePilot.wl"}],
  FileNameJoin[{exchangeDirectory, "TripleRootReconstructionPrototype.wl"}],
  assemblerFile};
If[FileExistsQ[outputFile] || ! AllTrue[files, FileExistsQ], Exit[65]];
Scan[(If[Get[#1] === $Failed, Exit[66]]) &, files];

Clear[x, y, eps];
prime = 10007;
epsilonValue = 1/21;
candidate = {3, 39};
rules = Thread[{x, y} -> candidate];
gaugeDenominator = (1 + x) (1 + y);
baseSupport = {{0, 0}, {0, 1}, {1, 0}};
rankZeroConditionParts = <|
  "Rules" -> rules,
  "GaugeDenominatorValue" -> (gaugeDenominator /. rules),
  "GaugeDenominatorMod" -> Mod[gaugeDenominator /. rules, prime],
  "OtherDenominatorValue" -> (1 + x + 2 y /. rules),
  "OtherDenominatorMod" -> Mod[1 + x + 2 y /. rules, prime],
  "GaugeNonzero" ->
    (Mod[gaugeDenominator /. rules, prime] =!= 0),
  "OtherNonzero" -> (Mod[1 + x + 2 y /. rules, prime] =!= 0)|>;
returnLoopProbe = Module[{},
  Do[If[index === 1, Return[7]], {index, 1, 3}]; 9];
findRankZeroPoint = Module[{point},
  Do[
    point = {2 + Mod[index, 193], 2 + Mod[37 index, 191]};
    If[Mod[gaugeDenominator /. Thread[{x, y} -> point], prime] =!= 0 &&
        Mod[1 + point[[1]] + 2 point[[2]], prime] =!= 0,
      Return[point]],
    {index, 1, 1000}];
  $Failed];

makeField[seed_Integer] := Together[
  (seed + eps x + 2 y)/(1 + x + 2 y)];
record = <|"Family" -> "DRCARuntimeDiagnostic", "Sector" -> 0,
  "LowerSector" -> 0, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {
    Table[makeField[20 mu + 5 i + j], {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[50 mu + 7 i + 2 j], {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[90 mu + 11 i + 3 j], {mu, 2}, {i, 2}, {j, 2}]}|>;
forms = Table[{makeField[130 + 9 letter],
  makeField[170 + 11 letter]}, {letter, 2}];
assembly = CodexDirectRootChannelAssembler`DRCACompileSystem[
  record, {}, forms, gaugeDenominator, baseSupport, {},
  <|"SourceABIFingerprint" -> "runtime-diag-rank-0",
    "RootOrderingFingerprint" ->
      Hash[{}, "SHA256", "HexString"]|>];
primeForms = If[AssociationQ[assembly],
  CodexDirectRootChannelAssembler`DRCAPrimeForms[assembly, prime], $Failed];
compiledRationals = If[AssociationQ[assembly], Cases[
  assembly["CompiledForms"], association_Association /;
    Lookup[association, "Type", None] === "DRCARationalExactV1" :>
      association, {0, Infinity}], {}];
primeReductionResults =
  CodexDirectRootChannelAssembler`Private`drcaReduceRational[
    #1, prime] & /@ compiledRationals;
badPrimeReductionIndices = Flatten[Position[
  primeReductionResults, $Failed, {1}, Heads -> False]];
epsilonMod = CodexDirectRootChannelAssembler`Private`drcaModRational[
  epsilonValue, prime];
collapseResults = If[AssociationQ[primeForms],
  CodexDirectRootChannelAssembler`Private`drcaCollapseRational[
    #1, epsilonMod, prime] & /@ Cases[
      primeForms["Forms"], association_Association /;
        Lookup[association, "Type", None] ===
          "DRCARationalPrimeV1" :> association, {0, Infinity}], {}];
badCollapseIndices = Flatten[Position[
  collapseResults, $Failed, {1}, Heads -> False]];
epsilonForms = If[AssociationQ[assembly],
  CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
    assembly, prime, epsilonValue], $Failed];
pointResult = If[AssociationQ[assembly] && AssociationQ[epsilonForms],
  CodexDirectRootChannelAssembler`DRCAAssemblePoint[
    assembly, epsilonForms, prime, candidate], $Failed];
report = <|
  "Status" -> "DirectRootChannelRuntimeDiagnosticV1",
  "SymbolContexts" -> AssociationMap[Context, {x, y, eps}],
  "SymbolAttributes" -> AssociationMap[Attributes, {x, y, eps}],
  "RankZeroConditionParts" -> rankZeroConditionParts,
  "RankZeroCondition" -> And @@ Values[
    KeyTake[rankZeroConditionParts, {"GaugeNonzero", "OtherNonzero"}]],
  "ReturnLoopProbe" -> returnLoopProbe,
  "FindRankZeroPoint" -> findRankZeroPoint,
  "AssemblerSHA256" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "AssemblyStatus" -> If[AssociationQ[assembly],
    Lookup[assembly, "Status", None], assembly],
  "AssemblyValid" -> If[AssociationQ[assembly],
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[assembly],
    False],
  "AssemblyKeys" -> If[AssociationQ[assembly], Keys[assembly], {}],
  "CompiledRationalCount" -> Length[compiledRationals],
  "PrimeFormsStatus" -> If[AssociationQ[primeForms],
    Lookup[primeForms, "Status", None], primeForms],
  "BadPrimeReductionIndices" -> badPrimeReductionIndices,
  "EpsilonMod" -> epsilonMod,
  "CollapseResultCount" -> Length[collapseResults],
  "BadCollapseIndices" -> badCollapseIndices,
  "FirstBadCollapseInput" -> If[AssociationQ[primeForms] &&
      badCollapseIndices =!= {}, Cases[
      primeForms["Forms"], association_Association /;
        Lookup[association, "Type", None] ===
          "DRCARationalPrimeV1" :> association,
      {0, Infinity}][[First[badCollapseIndices]]], None],
  "EpsilonFormsStatus" -> If[AssociationQ[epsilonForms],
    Lookup[epsilonForms, "Status", None], epsilonForms],
  "EpsilonFormsKeys" -> If[AssociationQ[epsilonForms],
    Keys[epsilonForms], {}],
  "PointResult" -> pointResult|>;
Put[report, outputFile];
Print["DRCA_RUNTIME_DIAG rankZeroCondition=", report["RankZeroCondition"],
  " assembly=", report["AssemblyStatus"], " epsilon=",
  report["EpsilonFormsStatus"], " point=",
  If[AssociationQ[pointResult], Lookup[pointResult, "Status", None],
    pointResult], " reason=",
  If[AssociationQ[pointResult],
    Lookup[pointResult, "FailureReason", None], None]];
Exit[0];
