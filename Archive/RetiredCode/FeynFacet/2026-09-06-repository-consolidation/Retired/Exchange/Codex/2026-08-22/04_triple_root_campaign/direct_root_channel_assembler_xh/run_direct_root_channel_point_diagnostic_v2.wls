#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["DRCA_POINT_DIAGNOSTIC_V2 FAIL usage=<project-root> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
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

modRational[value_, prime_Integer] := Module[{r = Together[value], d},
  If[! MatchQ[r, _Integer | _Rational], Return[$Failed]];
  d = Mod[Denominator[r], prime];
  If[d === 0, Return[$Failed]];
  Mod[Numerator[r] PowerMod[d, -1, prime], prime]
];

Clear[x, y, eps];
allRootSquares = {x + 3, y + 5, x + y + 7};
allRoots = <|"Root" -> Sqrt[#1], "RootSquare" -> #1|> & /@
  allRootSquares;
gaugeDenominator = (1 + x) (1 + y);
makeField[seed_Integer, roots_List] :=
  CodexTripleRootStrip`TRFieldCompose[Table[Together[
    (seed + 3 grade + eps (1 + grade) x + (2 + grade) y)/
      (1 + x + 2 y)],
    {grade, 0, 2^Length[roots] - 1}], roots];
makeRecord[roots_List] := <|"Family" -> "DRCAPointDiagnosticV2",
  "Sector" -> Length[roots], "LowerSector" -> 0,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {
    Table[makeField[20 mu + 5 i + j, roots],
      {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[50 mu + 7 i + 2 j, roots],
      {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[90 mu + 11 i + 3 j, roots],
      {mu, 2}, {i, 2}, {j, 2}]}|>;
makeForms[roots_List] := Table[
  {makeField[130 + 9 letter, roots],
    makeField[170 + 11 letter, roots]}, {letter, 2}];
pointImageData[roots_List, prime_Integer, point : {_Integer, _Integer}] :=
 Module[{squares, substitutions, values, gaugeValue, channelValue,
   directAccepted, residues},
  squares = Lookup[roots, "RootSquare", {}];
  substitutions = Thread[{x, y} -> point];
  values = modRational[#1 /. substitutions, prime] & /@ squares;
  gaugeValue = modRational[gaugeDenominator /. substitutions, prime];
  channelValue = modRational[(1 + x + 2 y) /. substitutions, prime];
  directAccepted = TrueQ[
    Length[values] === Length[squares] &&
    AllTrue[values, IntegerQ[#1] && 0 < #1 < prime &] &&
    IntegerQ[gaugeValue] && gaugeValue =!= 0 &&
    IntegerQ[channelValue] && channelValue =!= 0];
  residues = If[directAccepted,
    JacobiSymbol[#1, prime] & /@ values, {}];
  <|"Point" -> point, "DeltaValues" -> values,
    "GaugeDenominatorValue" -> gaugeValue,
    "ChannelDenominatorValue" -> channelValue,
    "DirectAccepted" -> directAccepted,
    "ResidueCharacters" -> residues,
    "SplitAccepted" -> TrueQ[directAccepted &&
      AllTrue[residues, #1 === 1 &]]|>
];
findSplitPoint[roots_List, prime_Integer] := Module[{candidates},
  candidates = Table[
    {2 + Mod[index, 193], 2 + Mod[37 index, 191]},
    {index, 1, 1000}];
  SelectFirst[candidates,
    TrueQ[Lookup[pointImageData[roots, prime, #1],
      "SplitAccepted", False]] &, $Failed]
];

baseSupport = {{0, 0}, {0, 1}, {1, 0}};
prime = 10007;
epsilonValue = 1/21;
caseEvidence = Table[Module[
    {roots, candidates, point, assembly, primeForms, primeFormsAgain,
     primeCacheSize, primeCacheSizeAgain, epsilonForms,
     epsilonFormsAgain, epsilonCacheSize, epsilonCacheSizeAgain,
     pointResult, expectedDimensions, passed},
    roots = Take[allRoots, rank];
    candidates = Table[pointImageData[roots, prime,
      {2 + Mod[index, 193], 2 + Mod[37 index, 191]}],
      {index, 1, 8}];
    point = findSplitPoint[roots, prime];
    assembly = CodexDirectRootChannelAssembler`DRCACompileSystem[
      makeRecord[roots], roots, makeForms[roots], gaugeDenominator,
      baseSupport, {}, <|
        "SourceABIFingerprint" ->
          "point-diagnostic-v2-rank-" <> ToString[rank],
        "RootOrderingFingerprint" -> Hash[
          Lookup[roots, "RootSquare", {}], "SHA256", "HexString"]|>];
    CodexDirectRootChannelAssembler`DRCAClearCaches[];
    primeForms = If[
      Lookup[assembly, "Status", None] ===
        "PreparedDirectRootChannelsV1",
      CodexDirectRootChannelAssembler`DRCAPrimeForms[
        assembly, prime], $Failed];
    primeCacheSize = Length[
      CodexDirectRootChannelAssembler`Private`$drcaPrimeCache];
    primeFormsAgain = If[AssociationQ[primeForms],
      CodexDirectRootChannelAssembler`DRCAPrimeForms[
        assembly, prime], $Failed];
    primeCacheSizeAgain = Length[
      CodexDirectRootChannelAssembler`Private`$drcaPrimeCache];
    epsilonForms = If[
      AssociationQ[primeForms],
      CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
        assembly, prime, epsilonValue], $Failed];
    epsilonCacheSize = Length[
      CodexDirectRootChannelAssembler`Private`$drcaEpsilonCache];
    epsilonFormsAgain = If[AssociationQ[epsilonForms],
      CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
        assembly, prime, epsilonValue], $Failed];
    epsilonCacheSizeAgain = Length[
      CodexDirectRootChannelAssembler`Private`$drcaEpsilonCache];
    pointResult = If[point =!= $Failed && AssociationQ[epsilonForms] &&
        Lookup[epsilonForms, "Status", None] ===
          "DirectRootChannelEpsilonFormsV1",
      CodexDirectRootChannelAssembler`DRCAAssemblePoint[
        assembly, epsilonForms, prime, point], $Failed];
    expectedDimensions = If[AssociationQ[assembly],
      {Lookup[assembly, "EquationsPerPoint", None],
        Lookup[assembly, "UnknownCount", None]}, $Failed];
    passed = TrueQ[point =!= $Failed && AssociationQ[pointResult] &&
      Lookup[pointResult, "Status", None] ===
        "AssembledDirectRootChannelPointV1" &&
      MatrixQ[Lookup[pointResult, "Rows", None], IntegerQ] &&
      Dimensions[pointResult["Rows"]] === expectedDimensions &&
      Length[pointResult["RightHandSide"]] === First[expectedDimensions] &&
      AssociationQ[primeForms] && primeFormsAgain === primeForms &&
      primeCacheSize === 1 && primeCacheSizeAgain === 1 &&
      AssociationQ[epsilonForms] && epsilonFormsAgain === epsilonForms &&
      epsilonCacheSize === 1 && epsilonCacheSizeAgain === 1];
    <|"Rank" -> rank, "Passed" -> passed,
      "FirstEightCandidatePredicates" -> candidates,
      "SelectedPoint" -> point,
      "AssemblySummary" -> If[AssociationQ[assembly],
        KeyTake[assembly, {"Status", "FailureReason", "GradeCount",
          "GaugeUnknownCount", "CanonicalUnknownCount"}],
        <|"ObservedHead" -> Head[assembly]|>],
      "CacheEvidence" -> <|
        "PrimeFormsStatus" -> If[AssociationQ[primeForms],
          Lookup[primeForms, "Status", None],
          <|"ObservedHead" -> Head[primeForms]|>],
        "PrimeCacheSizeAfterInsert" -> primeCacheSize,
        "PrimeCacheSizeAfterReuse" -> primeCacheSizeAgain,
        "PrimeReuseExact" -> TrueQ[primeFormsAgain === primeForms],
        "EpsilonCacheSizeAfterInsert" -> epsilonCacheSize,
        "EpsilonCacheSizeAfterReuse" -> epsilonCacheSizeAgain,
        "EpsilonReuseExact" -> TrueQ[
          epsilonFormsAgain === epsilonForms]|>,
      "EpsilonSummary" -> If[AssociationQ[epsilonForms],
        KeyDrop[epsilonForms, {"Forms"}],
        <|"ObservedHead" -> Head[epsilonForms]|>],
      "PointSummary" -> If[AssociationQ[pointResult],
        Join[KeyDrop[pointResult, {"Rows", "RightHandSide"}], <|
          "RowsDimensions" -> Dimensions[
            Lookup[pointResult, "Rows", {}]],
          "RightHandSideLength" -> Length[
            Lookup[pointResult, "RightHandSide", {}]]|>],
        <|"ObservedHead" -> Head[pointResult]|>]|>
  ], {rank, 0, 3}];

Close[messageStream];
$Messages = savedMessages;
messages = Quiet[Check[Import[messageFile, "Text"], $Failed]];
If[FileExistsQ[messageFile], Quiet[DeleteFile[messageFile]]];
completionHashes = sourceHashes[];
hashesStable = TrueQ[completionHashes === expectedHashes];
messagesEmpty = StringQ[messages] && StringTrim[messages] === "";
passed = TrueQ[loadOutcome === True &&
  AllTrue[caseEvidence, TrueQ[Lookup[#1, "Passed", False]] &] &&
  messagesEmpty && hashesStable];
status = If[passed, "DirectRootChannelPointDiagnosticV2Passed",
  "DirectRootChannelPointDiagnosticV2Failed"];
report = <|"Status" -> status,
  "Protocol" -> "DirectRootChannelPointDiagnosticV2",
  "CaseEvidence" -> caseEvidence,
  "LoadOutcome" -> loadOutcome,
  "CapturedMessages" -> messages,
  "MessagesEmpty" -> messagesEmpty,
  "ExpectedSourceHashes" -> expectedHashes,
  "CompletionSourceHashes" -> completionHashes,
  "SourceHashesStableAtCompletion" -> hashesStable|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCA_POINT_DIAGNOSTIC_V2 status=", status,
  " output=", outputFile];
Exit[If[passed, 0, 1]];
