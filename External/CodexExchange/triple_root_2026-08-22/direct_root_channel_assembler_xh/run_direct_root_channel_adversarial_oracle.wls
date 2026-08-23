#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["DRCA_ORACLE FAIL usage=<project-root> <native-binary> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
nativeBinary = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
adapterFile = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh", "FlintAffineRREFAdapter.wl"}];
nativeSourceFile = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh", "flint_affine_rref.c"}];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
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
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[nativeBinary] ||
    ! FileExistsQ[nativeSourceFile] ||
    ! FileExistsQ[adapterFile] || ! FileExistsQ[assemblerFile] ||
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

dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
adapterHashBefore = FileHash[adapterFile, "SHA256", "HexString"];
assemblerHashBefore = FileHash[assemblerFile, "SHA256", "HexString"];
binaryHashBefore = FileHash[nativeBinary, "SHA256", "HexString"];
nativeSourceHashBefore = FileHash[nativeSourceFile,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashes[] := <|
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Adapter" -> FileHash[adapterFile, "SHA256", "HexString"],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "NativeSource" -> FileHash[nativeSourceFile, "SHA256", "HexString"],
  "NativeBinary" -> FileHash[nativeBinary, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedHashes = <|"Dependencies" -> dependencyHashesBefore,
  "Adapter" -> adapterHashBefore, "Assembler" -> assemblerHashBefore,
  "NativeSource" -> nativeSourceHashBefore,
  "NativeBinary" -> binaryHashBefore, "Driver" -> driverHashBefore|>;

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
  Get[adapterFile];
  Get[assemblerFile];
  True, $Failed];
Close[loadMessageStream];
$Messages = savedMessages;
loadMessages = Quiet[Check[Import[loadMessageFile, "Text"], $Failed]];
If[FileExistsQ[loadMessageFile], Quiet[DeleteFile[loadMessageFile]]];
If[loadOutcome =!= True || ! StringQ[loadMessages] ||
    StringTrim[loadMessages] =!= "" || sourceHashes[] =!= expectedHashes,
  report = <|"Status" -> "DirectRootChannelOracleLoadFailed",
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
record[label_String, condition_, details_: <||>] := Module[{passed},
  passed = TrueQ[condition];
  AppendTo[results, <|"Label" -> label, "Passed" -> passed,
    "Details" -> details|>];
  Print[If[passed, "PASS ", "FAIL "] <> label];
  passed
];
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
makeField[seed_Integer, roots_List] :=
  CodexTripleRootStrip`TRFieldCompose[Table[Together[
    (seed + 3 grade + eps (1 + grade) x + (2 + grade) y)/
      (1 + x + 2 y)],
    {grade, 0, 2^Length[roots] - 1}], roots];
makeRecord[roots_List] := <|"Family" -> "DRCAOracle",
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
gaugeDenominator = (1 + x) (1 + y);
baseSupport = {{0, 0}, {0, 1}, {1, 0}};
imageSpecs = {
  <|"Prime" -> 10007, "EpsilonValue" -> 1/21|>,
  <|"Prime" -> 10007, "EpsilonValue" -> 1/11|>,
  <|"Prime" -> 10039, "EpsilonValue" -> 1/21|>,
  <|"Prime" -> 10039, "EpsilonValue" -> 1/11|>};

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
      AllTrue[residues, #1 === 1 &]],
    "NonsplitAccepted" -> TrueQ[directAccepted &&
      MemberQ[residues, -1]]|>
];
findPointByImageType[roots_List, prime_Integer, key_String] := Module[
  {candidates},
  candidates = Table[
    {2 + Mod[index, 193], 2 + Mod[37 index, 191]},
    {index, 1, 1000}];
  SelectFirst[candidates,
    TrueQ[Lookup[pointImageData[roots, prime, #1], key, False]] &,
    $Failed]
];
findSplitPoint[roots_List, prime_Integer] :=
  findPointByImageType[roots, prime, "SplitAccepted"];
findNonsplitPoint[roots_List, prime_Integer] :=
  findPointByImageType[roots, prime, "NonsplitAccepted"];

assemblies = <||>;
Do[
  roots = Take[allRoots, rank];
  recordData = makeRecord[roots];
  formData = makeForms[roots];
  {compileSeconds, assembly} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      recordData, roots, formData, gaugeDenominator, baseSupport, {},
      <|"SourceABIFingerprint" -> "oracle-rank-" <> ToString[rank],
        "RootOrderingFingerprint" -> Hash[
          Lookup[roots, "RootSquare", {}], "SHA256", "HexString"]|>]];
  record["rank-" <> ToString[rank] <> ":compile",
    Lookup[assembly, "Status", None] === "PreparedDirectRootChannelsV1" &&
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly], <|"CompileSeconds" -> compileSeconds|>];
  If[Lookup[assembly, "Status", None] =!= "PreparedDirectRootChannelsV1",
    Continue[]];
  AssociateTo[assemblies, rank -> assembly];
  activeForcingGrades = Select[Range[0, 2^rank - 1],
    ! AllTrue[Flatten[assembly["ExactChannelForms", "BBar"][[
      All, All, All, #1 + 1]]], TrueQ[Together[#1] === 0] &] &];
  record["rank-" <> ToString[rank] <> ":all-grades-active",
    activeForcingGrades === Range[0, 2^rank - 1],
    <|"ActiveForcingGrades" -> activeForcingGrades|>];
  Do[
    prime = image["Prime"];
    epsilonValue = image["EpsilonValue"];
    point = findSplitPoint[roots, prime];
    label = "rank-" <> ToString[rank] <> "-p" <> ToString[prime] <>
      "-eps-" <> ToString[Numerator[epsilonValue]] <> "-" <>
      ToString[Denominator[epsilonValue]];
    If[point === $Failed,
      record[label <> ":split-point", False,
        <|"CandidateDiagnostics" -> Table[
          pointImageData[roots, prime,
            {2 + Mod[index, 193], 2 + Mod[37 index, 191]}],
          {index, 1, 8}]|>]; Continue[]];
    record[label <> ":split-point", True,
      pointImageData[roots, prime, point]];
    epsilonForms =
      CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
        assembly, prime, epsilonValue];
    epsilonFormsPassed = record[label <> ":epsilon-collapse",
      AssociationQ[epsilonForms] &&
        Lookup[epsilonForms, "Status", None] ===
          "DirectRootChannelEpsilonFormsV1",
      If[AssociationQ[epsilonForms],
        KeyDrop[epsilonForms, {"Forms"}],
        <|"ObservedHead" -> Head[epsilonForms]|>]];
    If[! epsilonFormsPassed, Continue[]];
    directPoint =
      CodexDirectRootChannelAssembler`DRCAAssemblePoint[
        assembly, epsilonForms, prime, point];
    directPointPassed = record[label <> ":direct-point-assembly",
      AssociationQ[directPoint] &&
        Lookup[directPoint, "Status", None] ===
          "AssembledDirectRootChannelPointV1" &&
        Dimensions[directPoint["Rows"]] ===
          {assembly["EquationsPerPoint"], assembly["UnknownCount"]} &&
        Length[directPoint["RightHandSide"]] ===
          assembly["EquationsPerPoint"],
      If[AssociationQ[directPoint],
        KeyDrop[directPoint, {"Rows", "RightHandSide"}],
        <|"ObservedHead" -> Head[directPoint]|>]];
    If[! directPointPassed, Continue[]];
    differential =
      CodexDirectRootChannelAssembler`DRCADifferentialCheckPoint[
        assembly, epsilonValue, prime, point, 2^rank - 1];
    differentialPassed = record[label <> ":legacy-differential",
      AssociationQ[differential] &&
        Lookup[differential, "Status", None] ===
          "DirectLegacyPointDifferentialPassed" &&
        TrueQ[Lookup[differential, "Passed", False]] &&
        AssociationQ[Lookup[differential, "Telemetry", None]] &&
        AllTrue[Lookup[Lookup[differential, "Telemetry", <||>],
          {"DirectPointSeconds", "LegacyPointSeconds", "TotalSeconds"},
          {}], Internal`RealValuedNumberQ],
      If[AssociationQ[differential],
        KeyDrop[differential, {"SignTransform"}],
        <|"ObservedHead" -> Head[differential]|>]];
    rootsAtPoint = CodexTripleRoot`TRSquareRoots[
      directPoint["DeltaValues"], prime];
    signTransform = If[ListQ[rootsAtPoint],
      CodexDirectRootChannelAssembler`DRCASignTransform[
        rootsAtPoint, prime], $Failed];
    record[label <> ":sign-transform-invertible",
      MatrixQ[signTransform, IntegerQ] &&
        MatrixRank[signTransform, Modulus -> prime] === 2^rank,
      <|"RootsAtPoint" -> rootsAtPoint|>];
    differentialTelemetry = If[AssociationQ[differential],
      Lookup[differential, "Telemetry", <||>], <||>];
    AppendTo[caseSummaries, <|"Rank" -> rank, "Prime" -> prime,
      "EpsilonValue" -> epsilonValue, "Point" -> point,
      "DifferentialPassed" -> differentialPassed,
      "DirectSeconds" -> Lookup[differentialTelemetry,
        "DirectPointSeconds", None],
      "LegacySeconds" -> Lookup[differentialTelemetry,
        "LegacyPointSeconds", None]|>],
    {image, imageSpecs}],
  {rank, 0, 3}];

rankThreeAssembly = Lookup[assemblies, 3, $Failed];
If[AssociationQ[rankThreeAssembly],
  CodexDirectRootChannelAssembler`DRCAClearCaches[];
  cachePrimeForms = CodexDirectRootChannelAssembler`DRCAPrimeForms[
    rankThreeAssembly, 10007];
  cachePrimeSizeAfterInsert = Length[
    CodexDirectRootChannelAssembler`Private`$drcaPrimeCache];
  cachePrimeFormsAgain =
    CodexDirectRootChannelAssembler`DRCAPrimeForms[
      rankThreeAssembly, 10007];
  cachePrimeSizeAfterReuse = Length[
    CodexDirectRootChannelAssembler`Private`$drcaPrimeCache];
  cacheEpsilonForms =
    CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      rankThreeAssembly, 10007, 1/21];
  cacheEpsilonSizeAfterInsert = Length[
    CodexDirectRootChannelAssembler`Private`$drcaEpsilonCache];
  cacheEpsilonFormsAgain =
    CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      rankThreeAssembly, 10007, 1/21];
  cacheEpsilonSizeAfterReuse = Length[
    CodexDirectRootChannelAssembler`Private`$drcaEpsilonCache];
  record["cache:held-symbol-insertion-and-reuse",
    AssociationQ[cachePrimeForms] &&
      Lookup[cachePrimeForms, "Status", None] ===
        "DirectRootChannelPrimeFormsV1" &&
      cachePrimeFormsAgain === cachePrimeForms &&
      cachePrimeSizeAfterInsert === 1 &&
      cachePrimeSizeAfterReuse === 1 &&
      AssociationQ[cacheEpsilonForms] &&
      Lookup[cacheEpsilonForms, "Status", None] ===
        "DirectRootChannelEpsilonFormsV1" &&
      cacheEpsilonFormsAgain === cacheEpsilonForms &&
      cacheEpsilonSizeAfterInsert === 1 &&
      cacheEpsilonSizeAfterReuse === 1,
    <|"PrimeCacheSizeAfterInsert" -> cachePrimeSizeAfterInsert,
      "PrimeCacheSizeAfterReuse" -> cachePrimeSizeAfterReuse,
      "EpsilonCacheSizeAfterInsert" -> cacheEpsilonSizeAfterInsert,
      "EpsilonCacheSizeAfterReuse" -> cacheEpsilonSizeAfterReuse|>]];
If[AssociationQ[rankThreeAssembly],
  prime = 10007; epsilonValue = 1/21;
  point = findSplitPoint[Take[allRoots, 3], prime];
  epsilonForms = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
    rankThreeAssembly, prime, epsilonValue];
  validPoint = CodexDirectRootChannelAssembler`DRCAAssemblePoint[
    rankThreeAssembly, epsilonForms, prime, point];
  zeroDenominatorPoint = {prime - 1, 2};
  rejectedDenominator = Quiet[
    CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      rankThreeAssembly, epsilonForms, prime, zeroDenominatorPoint]];
  record["rank-3:zero-gauge-denominator-rejected",
    Lookup[rejectedDenominator, "Status", None] ===
      "DirectRootChannelAssemblyFailure" &&
    Lookup[rejectedDenominator, "FailureReason", None] ===
      "ZeroGaugeDenominator", rejectedDenominator];
  zeroDeltaPoint = {prime - 3, 2};
  rejectedDelta = Quiet[
    CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      rankThreeAssembly, epsilonForms, prime, zeroDeltaPoint]];
  record["rank-3:zero-delta-rejected",
    Lookup[rejectedDelta, "Status", None] ===
      "DirectRootChannelAssemblyFailure" &&
    Lookup[rejectedDelta, "FailureReason", None] ===
      "DegenerateRootImage", rejectedDelta];
  badEpsilon = Quiet[
    CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      rankThreeAssembly, prime, 1/prime]];
  record["rank-3:singular-epsilon-rejected", badEpsilon === $Failed];
  cachedAgain = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
    rankThreeAssembly, prime, epsilonValue];
  record["rank-3:epsilon-cache-exact", cachedAgain === epsilonForms];
  validPointPassed = record["rank-3:baseline-direct-point",
    AssociationQ[validPoint] &&
      Lookup[validPoint, "Status", None] ===
        "AssembledDirectRootChannelPointV1",
    If[AssociationQ[validPoint],
      KeyDrop[validPoint, {"Rows", "RightHandSide"}],
      <|"ObservedHead" -> Head[validPoint]|>]];
  If[validPointPassed,
  malformedEpsilonForms = ReplacePart[epsilonForms,
    "EpsilonMod" -> Mod[epsilonForms["EpsilonMod"] + 1, prime]];
  malformedPoint = Quiet[
    CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      rankThreeAssembly, malformedEpsilonForms, prime, point]];
  record["rank-3:malformed-epsilon-image-rejected",
    Lookup[malformedPoint, "FailureReason", None] ===
      "InvalidEpsilonForms"];
  tamperedPoint = ReplacePart[validPoint, "Rows" -> ReplacePart[
    validPoint["Rows"], {1, 1} -> Mod[validPoint["Rows"][[1, 1]] + 1,
      prime]]];
  rootsAtPoint = CodexTripleRoot`TRSquareRoots[
    validPoint["DeltaValues"], prime];
  tamperedSigns =
    CodexDirectRootChannelAssembler`DRCATransformPointToSigns[
      tamperedPoint, rootsAtPoint, prime, 0];
  validSigns = CodexDirectRootChannelAssembler`DRCATransformPointToSigns[
    validPoint, rootsAtPoint, prime, 0];
  record["rank-3:perturbed-channel-detected",
    tamperedSigns["Rows"] =!= validSigns["Rows"]];
  badRootValues = ReplacePart[rootsAtPoint, 1 ->
    Mod[rootsAtPoint[[1]] + 1, prime]];
  badRootTransform =
    CodexDirectRootChannelAssembler`DRCATransformPointToSigns[
      validPoint, badRootValues, prime, 0];
  record["rank-3:wrong-root-image-rejected",
    Lookup[badRootTransform, "Status", None] ===
      "DirectRootChannelAssemblyFailure"];
  nonsplitPoint = findNonsplitPoint[Take[allRoots, 3], prime];
  nonsplitDirect = If[nonsplitPoint === $Failed, $Failed,
    CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      rankThreeAssembly, epsilonForms, prime, nonsplitPoint]];
  nonsplitDifferential = If[nonsplitPoint === $Failed, $Failed,
    CodexDirectRootChannelAssembler`DRCADifferentialCheckPoint[
      rankThreeAssembly, epsilonValue, prime, nonsplitPoint, 0]];
  record["rank-3:nonresidue-direct-point-accepted",
    AssociationQ[nonsplitDirect] &&
    Lookup[nonsplitDirect, "Status", None] ===
      "AssembledDirectRootChannelPointV1" &&
    AssociationQ[nonsplitDifferential] &&
    Lookup[nonsplitDifferential, "FailureReason", None] ===
      "DifferentialPointNotSplit", <|"Point" -> nonsplitPoint,
      "ExpectedSplitAttemptFactor" -> 8|>],
  record["rank-3:baseline-dependent-checks", False]],
  record["rank-3:adversarial-setup", False]];

(* Resource and semantic mutation guards are bounded and deterministic. *)
rankZeroAssembly = Lookup[assemblies, 0, $Failed];
If[AssociationQ[rankZeroAssembly],
  mutatedAssembly = ReplacePart[rankZeroAssembly,
    "Regulator" -> Unique["mutatedEpsilon$"]];
  record["source-semantic-mutation-rejected",
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      mutatedAssembly]];
  rankZeroRecord = makeRecord[{}];
  rankZeroForms = makeForms[{}];
  largeExponentAssembly =
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      rankZeroRecord, {}, rankZeroForms, gaugeDenominator,
      {{10^9, 0}}, {}, <|"SourceABIFingerprint" ->
        "oracle-large-support-exponent",
        "RootOrderingFingerprint" -> "oracle-rank-0"|>];
  largeExponentForms =
    CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
      largeExponentAssembly, 10007, 1/21];
  largeExponentPoint =
    CodexDirectRootChannelAssembler`DRCAAssemblePoint[
      largeExponentAssembly, largeExponentForms, 10007, {2, 3}];
  record["sparse-large-support-exponent-bounded",
    Lookup[largeExponentPoint, "Status", None] ===
      "AssembledDirectRootChannelPointV1"];
  badEpsilonStrip = rankZeroRecord["Strip"];
  badEpsilonStrip[[3, 1, 1, 1]] = eps^257;
  badEpsilonRecord = Join[rankZeroRecord, <|"Strip" -> badEpsilonStrip|>];
  badEpsilonAssembly =
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      badEpsilonRecord, {}, rankZeroForms, gaugeDenominator,
      baseSupport];
  record["epsilon-degree-resource-cap",
    Lookup[badEpsilonAssembly, "Status", None] ===
      "DirectRootChannelAssemblyFailure"];
  fourthRoot = <|"Root" -> Sqrt[x + 2 y + 11],
    "RootSquare" -> x + 2 y + 11|>;
  rankFourRoots = Append[allRoots, fourthRoot];
  rankFourAssembly =
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      makeRecord[rankFourRoots], rankFourRoots,
      makeForms[rankFourRoots], gaugeDenominator, baseSupport];
  record["root-count-resource-cap",
    Lookup[rankFourAssembly, "Status", None] ===
      "DirectRootChannelAssemblyFailure"]];

(* Nested A0/AS/AL/ASL column projections must preserve every direct row. *)
projectionResults = {};
If[AssociationQ[rankThreeAssembly],
  projectionSupports = <|"A0" -> Take[baseSupport, 2],
    "AS" -> baseSupport, "AL" -> Take[baseSupport, 2],
    "ASL" -> baseSupport|>;
  fullForms = makeForms[Take[allRoots, 3]];
  projectionForms = <|"A0" -> Take[fullForms, 1],
    "AS" -> Take[fullForms, 1], "AL" -> fullForms,
    "ASL" -> fullForms|>;
  projectionAssemblies = Association@Table[label ->
    CodexDirectRootChannelAssembler`DRCACompileSystem[
      makeRecord[Take[allRoots, 3]], Take[allRoots, 3],
      projectionForms[label], gaugeDenominator,
      projectionSupports[label], {}, <|
        "SourceABIFingerprint" -> "oracle-projection-" <> label,
        "RootOrderingFingerprint" -> "oracle-rank-3"|>],
    {label, {"A0", "AS", "AL", "ASL"}}];
  projectionPoint = findSplitPoint[Take[allRoots, 3], 10007];
  projectionPointResults = Association@Table[label -> Module[{ef},
      ef = CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
        projectionAssemblies[label], 10007, 1/21];
      CodexDirectRootChannelAssembler`DRCAAssemblePoint[
        projectionAssemblies[label], ef, 10007, projectionPoint]],
    {label, {"A0", "AS", "AL", "ASL"}}];
  projectionPointsPassed = record["projection:all-direct-points-assembled",
    AllTrue[Values[projectionPointResults],
      AssociationQ[#1] && Lookup[#1, "Status", None] ===
        "AssembledDirectRootChannelPointV1" &],
    Map[If[AssociationQ[#1],
        KeyDrop[#1, {"Rows", "RightHandSide"}],
        <|"ObservedHead" -> Head[#1]|>] &,
      projectionPointResults]];
  If[projectionPointsPassed,
  fullAssembly = projectionAssemblies["ASL"];
  fullPoint = projectionPointResults["ASL"];
  Do[
    localAssembly = projectionAssemblies[label];
    supportPositions = First[FirstPosition[
          fullAssembly["GaugeSupport"], #1]] & /@
      localAssembly["GaugeSupport"];
    formPositions = First[FirstPosition[
          fullAssembly["OneForms"], #1]] & /@
      localAssembly["OneForms"];
    {upper, lower} = localAssembly["Dimensions"];
    gradeCount = localAssembly["GradeCount"];
    fullSupportCount = Length[fullAssembly["GaugeSupport"]];
    fullGaugeCount = fullAssembly["GaugeUnknownCount"];
    columnMap = Join[
      Flatten[Table[
        (((i - 1) lower + (j - 1)) gradeCount + grade)
          fullSupportCount + supportPositions[[monomial]],
        {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
        {monomial, Length[supportPositions]}]],
      Flatten[Table[fullGaugeCount +
        ((formPositions[[letter]] - 1) upper + (i - 1)) lower + j,
        {letter, Length[formPositions]}, {i, upper}, {j, lower}]]];
    projectionPassed = TrueQ[
      fullPoint["Rows"][[All, columnMap]] ===
        projectionPointResults[label]["Rows"] &&
      fullPoint["RightHandSide"] ===
        projectionPointResults[label]["RightHandSide"]];
    record["projection-" <> label <> "-from-ASL", projectionPassed,
      <|"ColumnCount" -> Length[columnMap]|>];
    AppendTo[projectionResults, <|"Label" -> label,
      "ColumnMap" -> columnMap, "Passed" -> projectionPassed|>],
    {label, {"A0", "AS", "AL", "ASL"}}],
  Null]];

(* A constructed zero row makes the inconsistent affine perturbation exact. *)
nativeEvidence = <||>;
If[AssociationQ[rankThreeAssembly] && AssociationQ[validPoint] &&
    Lookup[validPoint, "Status", None] ===
      "AssembledDirectRootChannelPointV1",
  prime = 10007;
  coefficientMatrix = Join[Take[validPoint["Rows"], UpTo[24]],
    {ConstantArray[0, validPoint["UnknownCount"]]}];
  witness = Table[Mod[17 index + 3, prime],
    {index, validPoint["UnknownCount"]}];
  consistentRight = Developer`ToPackedArray[
    Append[Mod[Take[validPoint["Rows"], UpTo[24]] . witness, prime], 0]];
  inconsistentRight = ReplacePart[consistentRight, -1 -> 1];
  augmentedConsistent = MapThread[Append,
    {coefficientMatrix, consistentRight}];
  augmentedInconsistent = MapThread[Append,
    {coefficientMatrix, inconsistentRight}];
  nativeRank[matrix_List, tag_String, nonceBase_Integer] := Module[
    {request, run, verification},
    request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
      matrix, ConstantArray[0, Length[matrix]], prime,
      Range[Length[First[matrix]]], {2026082309, nonceBase}];
    run = CodexFLINTAffineRREFAdapter`CFFRRun[
      nativeBinary, request, 1, False, 120];
    verification = Lookup[run, "Verification", <||>];
    <|"Tag" -> tag, "RunStatus" -> Lookup[run, "Status", None],
      "Verified" -> TrueQ[Lookup[verification, "Status", None] ===
        "VerifiedFLINTAffineRREFCertificate" &&
        AllTrue[Values[Lookup[verification, "Checks", <||>]], TrueQ]],
      "Rank" -> Lookup[Lookup[run, "Certificate", <||>],
        "Rank", None],
      "Nullity" -> Lookup[Lookup[run, "Certificate", <||>],
        "Nullity", None]|>
  ];
  rankA = nativeRank[coefficientMatrix, "A", 3001];
  rankConsistent = nativeRank[augmentedConsistent, "A|b-consistent", 3002];
  rankInconsistent = nativeRank[augmentedInconsistent,
    "A|b-inconsistent", 3003];
  nativeEvidence = <|"Coefficient" -> rankA,
    "ConsistentAugmented" -> rankConsistent,
    "InconsistentAugmented" -> rankInconsistent|>;
  record["native-rank-consistent-affine",
    TrueQ[rankA["Verified"] && rankConsistent["Verified"] &&
      rankA["Rank"] === rankConsistent["Rank"]], nativeEvidence];
  record["native-rank-perturbed-inconsistent-affine",
    TrueQ[rankInconsistent["Verified"] &&
      rankInconsistent["Rank"] === rankA["Rank"] + 1],
    nativeEvidence]];

Close[runtimeMessageStream];
$Messages = savedMessages;
runtimeMessages = Quiet[Check[Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
hashesAtCompletion = sourceHashes[];
hashesStable = TrueQ[hashesAtCompletion === expectedHashes];
messagesEmpty = StringQ[runtimeMessages] &&
  StringTrim[runtimeMessages] === "";
passedCount = Count[Lookup[results, "Passed", {}], True];
failureCount = Length[results] - passedCount;
status = If[failureCount === 0 && messagesEmpty && hashesStable,
  "DirectRootChannelAdversarialOraclePassed",
  "DirectRootChannelAdversarialOracleFailed"];
report = <|"Status" -> status,
  "Protocol" -> "DirectRootChannelSparsePolynomialABIV1",
  "PassCount" -> passedCount, "FailureCount" -> failureCount,
  "Checks" -> results, "CaseSummaries" -> caseSummaries,
  "ProjectionEvidence" -> projectionResults,
  "ProductionPointAcceptanceModel" -> <|
    "DirectRequirement" -> "NonzeroDeltasAndDenominators",
    "LegacySignRequirement" -> "AllDeltasQuadraticResidues",
    "ExpectedRank2AttemptReduction" -> 4,
    "ExpectedRank3AttemptReduction" -> 8|>,
  "NativeRankEvidence" -> nativeEvidence,
  "CapturedLoadMessages" -> loadMessages,
  "CapturedRuntimeMessages" -> runtimeMessages,
  "MessagesEmpty" -> messagesEmpty,
  "ExpectedSourceHashes" -> expectedHashes,
  "CompletionSourceHashes" -> hashesAtCompletion,
  "SourceHashesStableAtCompletion" -> hashesStable|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCA_ORACLE status=", status, " passes=", passedCount,
  " failures=", failureCount, " output=", outputFile];
Exit[If[status === "DirectRootChannelAdversarialOraclePassed", 0, 1]];
