#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`mapleGaugeX"];
y = Symbol["Global`mapleGaugeY"];
eps = Symbol["Global`mapleGaugeEpsilon"];
rootRecord = <|"RootSquare" -> 1 + x,
  "Root" -> Sqrt[1 + x]|>;
rawGauge = {{1/(1 + Sqrt[1 + x])}};
capturedPayload = None;
canonicalRunner = Function[payload,
  capturedPayload = payload;
  <|"OutputLines" -> {"OK", "(-1+sqrt(1+mapleGaugeX))/mapleGaugeX"}|>];

canonical = FeynFacet`Private`transportChartMapleCanonicalGauge[
  rawGauge, {x, y}, eps, {rootRecord},
  "ScratchDirectory" -> $TemporaryDirectory,
  "Tag" -> "maple_canonical_gauge_test",
  "Runner" -> canonicalRunner];

FTAssert["the Maple bridge serializes declared square roots and requests algebraic Normal",
  AssociationQ[capturedPayload] &&
    StringContainsQ[capturedPayload["MapleText"], "sqrt(1+mapleGaugeX)"] &&
    StringContainsQ[capturedPayload["MapleText"],
      "evala(Normal(feynfacetGaugeEntries[i]))"]];

FTAssert["a square-root Maple normal form is parsed without changing shape",
  AssociationQ[canonical] &&
    canonical["Status"] === "MapleCanonicalGaugePrepared" &&
    Dimensions[canonical["Result"]] === Dimensions[rawGauge] &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      canonical["Result"][[1, 1]] - rawGauge[[1, 1]], {rootRecord}]]];

cacheScratch = FileNameJoin[{$TemporaryDirectory,
  "t_maple_entry_cache_" <> ToString[$ProcessID]}];
If[DirectoryQ[cacheScratch],
  DeleteDirectory[cacheScratch, DeleteContents -> True]];
CreateDirectory[cacheScratch, CreateIntermediateDirectories -> True];
cacheDirectory = FileNameJoin[{cacheScratch, "shared"}];
fakeLog = FileNameJoin[{cacheScratch, "fake_maple.log"}];
fakeMaple = FileNameJoin[{cacheScratch, "fake_maple.py"}];
Export[fakeMaple, StringJoin[
  "#!/usr/bin/env python3\n",
  "import re, sys\n",
  "text = open(sys.argv[-1], encoding='utf-8').read()\n",
  "out = re.search(r'fd := fopen\\(\\\"([^\\\"]+)\\\", WRITE\\):', text).group(1)\n",
  "entry = re.search(r'feynfacetGaugeEntries := \\[(.*)\\]:', text).group(1)\n",
  "open(", ToString[fakeLog, InputForm], ", 'a').write('run\\n')\n",
  "open(out, 'w', encoding='utf-8').write('OK\\n' + entry + '\\n')\n"],
  "Text"];
RunProcess[{"chmod", "+x", fakeMaple}];
cacheInput = {1/(1 + x), Sqrt[1 + x]/(2 + y)};
firstCacheRun = FeynFacet`Private`epsFormStripMapleCanonicalize[
  cacheInput, "MapleExecutable" -> fakeMaple,
  "ScratchDirectory" -> FileNameJoin[{cacheScratch, "first"}],
  "CacheDirectory" -> cacheDirectory, "Tag" -> "shared_payload",
  "TimeLimit" -> 30];
secondCacheRun = FeynFacet`Private`epsFormStripMapleCanonicalize[
  cacheInput, "MapleExecutable" -> fakeMaple,
  "ScratchDirectory" -> FileNameJoin[{cacheScratch, "second"}],
  "CacheDirectory" -> cacheDirectory, "Tag" -> "another_family",
  "TimeLimit" -> 30];
fakeRuns = If[FileExistsQ[fakeLog],
  Length[StringSplit[Import[fakeLog, "Text"]]], 0];
FTAssert["entry cache computes once and is shared across independent callers",
  firstCacheRun["Status"] === "MapleCanonicalGaugeV1" &&
    firstCacheRun["ComputedEntries"] === 2 &&
    secondCacheRun["CacheHits"] === 2 && fakeRuns === 2 &&
    And @@ MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {firstCacheRun["Result"], cacheInput}] &&
    And @@ MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {secondCacheRun["Result"], cacheInput}]];

legacyCache = FileNameJoin[{cacheScratch, "legacy_cache"}];
legacyScratch = FileNameJoin[{cacheScratch, "legacy"}];
CreateDirectory[legacyScratch, CreateIntermediateDirectories -> True];
Export[FileNameJoin[{legacyScratch, "resume.mpl"}],
  "feynfacetGaugeEntries := [" <> StringRiffle[
    FeynFacet`Private`epsFormStripMapleInputString /@ cacheInput, ","] <>
    "]:\n", "Text"];
Export[FileNameJoin[{legacyScratch, "resume.out"}],
  "OK\n1/(1+mapleGaugeX)\npartial-second-entry", "Text"];
legacyBefore = fakeRuns;
legacyRun = FeynFacet`Private`epsFormStripMapleCanonicalize[
  cacheInput, "MapleExecutable" -> fakeMaple,
  "ScratchDirectory" -> legacyScratch,
  "CacheDirectory" -> legacyCache, "Tag" -> "resume",
  "TimeLimit" -> 30];
legacyAfter = Length[StringSplit[Import[fakeLog, "Text"]]];
FTAssert["a killed combined output resumes only newline-complete entries",
  legacyRun["Status"] === "MapleCanonicalGaugeV1" &&
    legacyRun["LegacyEntriesSeeded"] === 1 &&
    legacyRun["CacheHits"] === 1 &&
    legacyRun["ComputedEntries"] === 1 &&
    legacyAfter - legacyBefore === 1 &&
    And @@ MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {legacyRun["Result"], cacheInput}]];

Quiet[DeleteDirectory[cacheScratch, DeleteContents -> True]];

FTDone[];
