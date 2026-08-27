#!/usr/bin/env wolframscript

(* This driver is intentionally reusable in a persistent kernel pool.  Clear
   every symbol that receives a delayed definition before parsing fixtures;
   otherwise a prior Global` association named record turns record[...] :=
   ... into an Association key assignment and silently leaves 0 assertions. *)
ClearAll[strictNonnegativeInteger, writeReportAtomic, record,
  rejectedAssociationQ, makeRankMatrix, fakePlanMetadata,
  runDifferentialCase, readBytes, writeBytes, setU64LE];

args = Rest[$ScriptCommandLine];
If[Length[args] < 3 || Length[args] > 5,
  Print["usage: run_flint_affine_rref_differential_smoke.wls " <>
    "<repository-root> <flint-affine-rref-binary> <report.wl> " <>
    "[random-case-count] [random-seed]"];
  Exit[64]];

strictNonnegativeInteger[text_String] := If[
  StringMatchQ[text, DigitCharacter ..], FromDigits[text], $Failed];

root = ExpandFileName[args[[1]]];
binary = ExpandFileName[args[[2]]];
reportFile = ExpandFileName[args[[3]]];
caseCount = If[Length[args] >= 4, strictNonnegativeInteger[args[[4]]], 24];
randomSeed = If[Length[args] >= 5, strictNonnegativeInteger[args[[5]]],
  2026082301];
If[! IntegerQ[caseCount] || caseCount < 1 || caseCount > 1000 ||
    ! IntegerQ[randomSeed], Exit[65]];

exchangeDirectory = FileNameJoin[{root, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
nativeDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh"}];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{root, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{root, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{root, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{root, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;
prototype = dependencyFiles["TripleRootReconstructionPrototype"];
adapter = FileNameJoin[{nativeDirectory, "FlintAffineRREFAdapter.wl"}];
If[! DirectoryQ[root] || ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! FileExistsQ[adapter] ||
    ! FileExistsQ[binary] || ! DirectoryQ[DirectoryName[reportFile]] ||
    FileExistsQ[reportFile], Exit[66]];

writeReportAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[reportFile], Return[$Failed]];
  temporary = reportFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, reportFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[reportFile] ||
      FileExistsQ[temporary],
    If[FileExistsQ[temporary], Quiet[DeleteFile[temporary]]];
    $Failed,
    reportFile]
];

dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
adapterHashBefore = FileHash[adapter, "SHA256", "HexString"];
binaryHashBefore = FileHash[binary, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];

savedMessageStreams = $Messages;
loadMessageFile = reportFile <> ".load-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
loadMessageStream = Quiet[Check[
  OpenWrite[loadMessageFile, CharacterEncoding -> "UTF8"], $Failed]];
If[loadMessageStream === $Failed, Exit[67]];
$Messages = {loadMessageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[prototype];
  Get[adapter];
  True,
  $Failed];
Close[loadMessageStream];
$Messages = savedMessageStreams;
loadMessageText = Quiet[Check[Import[loadMessageFile, "Text"], $Failed]];
If[FileExistsQ[loadMessageFile], Quiet[DeleteFile[loadMessageFile]]];

dependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
adapterHashAfterLoad = FileHash[adapter, "SHA256", "HexString"];
binaryHashAfterLoad = FileHash[binary, "SHA256", "HexString"];
driverHashAfterLoad = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesStableAfterLoad = TrueQ[
  dependencyHashesAfterLoad === dependencyHashesBefore &&
  adapterHashAfterLoad === adapterHashBefore &&
  binaryHashAfterLoad === binaryHashBefore &&
  driverHashAfterLoad === driverHashBefore];
loadedDefinitionsPresent = TrueQ[
  Length[DownValues[
    CodexTripleRootStrip`TRClassifyStripRecord]] > 0 &&
  Length[DownValues[
    CodexTripleRootPilot`TRSplitPointRows]] > 0 &&
  Length[DownValues[
    CodexTripleRootReconstruction`TRCanonicalAffineSolve]] > 0 &&
  Length[DownValues[
    CodexFLINTAffineRREFAdapter`CFFRRun]] > 0];
loadMessagesEmpty = StringQ[loadMessageText] &&
  StringTrim[loadMessageText] === "";
If[loadOutcome =!= True || ! loadMessagesEmpty ||
    ! loadedDefinitionsPresent || ! sourceHashesStableAfterLoad,
  loadFailureReport = <|
    "Status" -> "FLINTAffineRREFDifferentialSmokeLoadFailed",
    "Protocol" -> "CFFR1V1/CFFR1X1",
    "LoadOutcome" -> loadOutcome,
    "LoadedDefinitionsPresent" -> loadedDefinitionsPresent,
    "SourceHashesStableAfterLoad" -> sourceHashesStableAfterLoad,
    "CapturedLoadMessages" -> loadMessageText,
    "DependencyHashes" -> dependencyHashesBefore,
    "AdapterSHA256" -> adapterHashBefore,
    "BinarySHA256" -> binaryHashBefore,
    "DriverSHA256" -> driverHashBefore|>;
  If[writeReportAtomic[loadFailureReport] === $Failed, Exit[74]];
  Print["CFFR_DIFFERENTIAL load failed messages=", loadMessageText];
  Exit[67]];

runtimeMessageFile = reportFile <> ".runtime-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
runtimeMessageStream = Quiet[Check[
  OpenWrite[runtimeMessageFile, CharacterEncoding -> "UTF8"], $Failed]];
If[runtimeMessageStream === $Failed, Exit[68]];
$Messages = {runtimeMessageStream};

SeedRandom[randomSeed, Method -> "MersenneTwister"];
results = {};
caseSummaries = {};

record[label_String, condition_, details_: <||>] := Module[{passed},
  passed = TrueQ[condition];
  AppendTo[results, <|"Label" -> label, "Passed" -> passed,
    "Details" -> details|>];
  Print[If[passed, "PASS ", "FAIL "] <> label];
  passed
];

rejectedAssociationQ[result_, acceptedStatus_String] :=
  AssociationQ[result] && StringQ[Lookup[result, "Status", None]] &&
    Lookup[result, "Status", None] =!= acceptedStatus;

$planPayloadKeys = {
  "Status", "PlanVersion", "ABIFingerprint",
  "RootOrderingFingerprint", "MatrixDimensions", "PointCount",
  "NormalizationEquationCount", "BranchFlipMask",
  "IndependentEquationRows", "NormalizationColumns", "GenericRank",
  "Nullity", "UnknownCount", "GaugeUnknownCount", "FreeResidueCount",
  "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "GaugeSupport",
  "PilotPrime", "PilotEpsilonValue", "PilotRandomSeed",
  "PilotAcceptedPoints", "PilotPivotColumns", "PilotFreeColumns",
  "DiscoveryMethod"};

primeList = {1019, 10007, 1000003, 2147483647};

makeRankMatrix[rows_Integer, columns_Integer, rank_Integer,
    prime_Integer] := Module[{left, right, matrix, actualRank, attempts = 0},
  If[rank === 0, Return[ConstantArray[0, {rows, columns}]]];
  While[attempts < 200,
    attempts++;
    left = RandomInteger[{0, prime - 1}, {rows, rank}];
    right = RandomInteger[{0, prime - 1}, {rank, columns}];
    matrix = Mod[left . right, prime];
    actualRank = MatrixRank[matrix, Modulus -> prime];
    If[actualRank === rank, Return[matrix]]];
  $Failed
];

fakePlanMetadata[request_Association, index_Integer] := Module[
  {dimensions = request["MatrixDimensions"], rows, columns, prime,
   gaugeUnknownCount, normalizationCount, pointCount, preparation, sample},
  {rows, columns} = dimensions;
  prime = request["Prime"];
  gaugeUnknownCount = 0;
  normalizationCount = If[rows > 1, 1, 0];
  pointCount = rows - normalizationCount;
  preparation = <|
    "ABIFingerprint" -> "smoke-abi-" <> ToString[index],
    "RootOrderingFingerprint" -> "smoke-roots-" <> ToString[index],
    "UnknownCount" -> columns,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> columns - gaugeUnknownCount,
    "GaugeSupport" -> {{0, 0}},
    "GaugeDenominatorDegrees" -> {0, 0},
    "EquationsPerPoint" -> 1,
    "Normalizations" -> ConstantArray[<|"Smoke" -> True|>,
      normalizationCount]|>;
  sample = <|
    "MatrixDimensions" -> dimensions,
    "Matrix" -> request["Matrix"],
    "RightHandSide" -> request["RightHandSide"],
    "AcceptedPoints" -> Table[{2 + Mod[row, prime - 3],
      2 + Mod[2 row + 1, prime - 3]}, {row, 0, pointCount - 1}],
    "NormalizationCount" -> normalizationCount,
    "BranchFlipMask" -> 0,
    "Prime" -> prime,
    "EpsilonValue" -> 1|>;
  {preparation, sample}
];

runDifferentialCase[label_String, matrix_List, prime_Integer,
    preference_List, index_Integer, keep_: False] := Module[
  {columns = Length[First[matrix]], vector, right, baseline, request, run,
   certificate, comparison, metadata, plan, expectedPlanFingerprint,
   existingPlanValidator},
  vector = RandomInteger[{0, prime - 1}, columns];
  right = Mod[matrix . vector, prime];
  baseline = CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    matrix, right, prime];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    matrix, right, prime, preference,
    {2026082301 + index, 1469598103934665603 + index}];
  If[Lookup[baseline, "Status", None] =!= "CanonicalAffineSolution" ||
      Lookup[request, "Status", None] =!= "CFFRRequestV1",
    record[label <> ":setup", False]; Return[$Failed]];
  run = CodexFLINTAffineRREFAdapter`CFFRRun[binary, request, 4, keep];
  If[Lookup[run, "Status", None] =!= "VerifiedFLINTAffineRREFRun",
    record[label <> ":verified-run", False,
      <|"RunStatus" -> Lookup[run, "Status", None]|>]; Return[run]];
  certificate = run["Certificate"];
  comparison = TrueQ[
    certificate["Rank"] === baseline["Rank"] &&
    certificate["Nullity"] === baseline["Nullity"] &&
    certificate["PivotColumns"] === baseline["PivotColumns"] &&
    certificate["FreeColumns"] === baseline["FreeColumns"] &&
    certificate["ParticularSolution"] === baseline["ParticularSolution"] &&
    certificate["NullspaceBasis"] === baseline["NullspaceBasis"]];
  record[label <> ":canonical-differential", comparison,
    <|"Dimensions" -> Dimensions[matrix], "Prime" -> prime,
      "Rank" -> baseline["Rank"], "Nullity" -> baseline["Nullity"]|>];
  If[preference === Range[columns],
    metadata = fakePlanMetadata[request, index];
    plan = CodexFLINTAffineRREFAdapter`CFFRConstructCrossPrimePlanV1[
      metadata[[1]], metadata[[2]], randomSeed + index, request, certificate];
    expectedPlanFingerprint = If[AssociationQ[plan],
      Hash[ToString[InputForm[KeyTake[plan, $planPayloadKeys]]],
        "SHA256", "HexString"], $Failed];
    existingPlanValidator = If[AssociationQ[plan], TrueQ[
      CodexTripleRootReconstruction`Private`trCrossPrimeEliminationPlanValidQ[
        metadata[[1]], plan]], False];
    record[label <> ":v1-plan-fields",
      AssociationQ[plan] &&
        $planPayloadKeys ===
          CodexTripleRootReconstruction`Private`$trCrossPrimeEliminationPlanPayloadKeys &&
        Sort[Keys[plan]] === Sort[Append[$planPayloadKeys, "PlanFingerprint"]] &&
        Lookup[plan, "Status", None] === "CrossPrimeEliminationPlanV1" &&
        plan["IndependentEquationRows"] ===
          certificate["IndependentEquationRows"] &&
        plan["NormalizationColumns"] === certificate["NormalizationColumns"] &&
        StringQ[Lookup[plan, "PlanFingerprint", None]] &&
        plan["PlanFingerprint"] === expectedPlanFingerprint &&
        plan["PlanFingerprint"] ===
          CodexTripleRootReconstruction`Private`trCrossPrimeEliminationPlanFingerprint[
            plan] && existingPlanValidator,
      <|"PlanStatus" -> Lookup[plan, "Status", None]|>]];
  AppendTo[caseSummaries, <|"Label" -> label,
    "Dimensions" -> Dimensions[matrix], "Prime" -> prime,
    "Rank" -> baseline["Rank"], "Nullity" -> baseline["Nullity"],
    "Preference" -> preference|>];
  Join[run, <|"Request" -> request, "Baseline" -> baseline|>]
];

(* Explicit zero-rank and zero-nullity boundaries exercise all zero-size fields. *)
record["request-composite-modulus-rejected",
  rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    {{1, 0}, {0, 1}}, {1, 1}, 15, {1, 2}, {1, 2}],
    "CFFRRequestV1"]];
record["request-zero-nonce-rejected",
  rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    {{1, 0}, {0, 1}}, {1, 1}, 1019, {1, 2}, {0, 0}],
    "CFFRRequestV1"]];
record["request-bad-preference-rejected",
  rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    {{1, 0}, {0, 1}}, {1, 1}, 1019, {1, 1}, {1, 2}],
    "CFFRRequestV1"]];
inconsistentRequest = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
  ConstantArray[0, {2, 3}], {1, 0}, 1019, {1, 2, 3}, {7, 11}];
inconsistentRun = CodexFLINTAffineRREFAdapter`CFFRRun[
  binary, inconsistentRequest, 2, False];
record["inconsistent-system-fails-closed",
  Lookup[inconsistentRun, "Status", None] === "InconsistentAffineImage" &&
    Lookup[inconsistentRun, "ExitCode", None] === 5 &&
    Lookup[inconsistentRun, "FailureClass", None] ===
      "MathematicalImageInconsistency" &&
    TrueQ[Lookup[inconsistentRun, "RetryableWithDifferentImage", False]],
  <|"RunStatus" -> Lookup[inconsistentRun, "Status", None]|>];

rankZeroMatrix = ConstantArray[0, {3, 4}];
runDifferentialCase["boundary-rank-zero", rankZeroMatrix, 1019,
  {1, 2, 3, 4}, 1];
fullColumnMatrix = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1},
  {1, 2, 3}, {3, 1, 4}};
runDifferentialCase["boundary-nullity-zero", fullColumnMatrix, 10007,
  {1, 2, 3}, 2];

(* Pivots {1,3} make the free-column-2 canonical-order check distinguish
   pivot positions from the actual pivot column indices.  The historical
   position-indexed verifier reads the free identity entry in column 2 and
   rejects this valid certificate. *)
gappedPivotMatrix = {{1, 7, 0, 5}, {0, 0, 1, 9}};
gappedPivotRun = runDifferentialCase[
  "gapped-pivot-canonical-order", gappedPivotMatrix, 1019,
  {1, 2, 3, 4}, caseCount + 1003];
If[AssociationQ[gappedPivotRun],
  gappedPivotCertificate = Lookup[gappedPivotRun, "Certificate", <||>];
  gappedPivotVerification = Lookup[gappedPivotRun, "Verification", <||>],
  gappedPivotCertificate = <||>;
  gappedPivotVerification = <||>];
record["gapped-pivot-canonical-order:actual-column-regression",
  AssociationQ[gappedPivotCertificate] &&
    Lookup[gappedPivotCertificate, "PivotColumns", None] === {1, 3} &&
    Lookup[gappedPivotCertificate, "FreeColumns", None] === {2, 4} &&
    TrueQ[Lookup[
      Lookup[gappedPivotVerification, "Checks", <||>],
      "CanonicalPivotOrder", False]]];

Do[
  prime = primeList[[1 + Mod[index - 1, Length[primeList]]]];
  rows = RandomInteger[{1, 10}];
  columns = RandomInteger[{1, 10}];
  desiredRank = RandomInteger[{0, Min[rows, columns]}];
  matrix = makeRankMatrix[rows, columns, desiredRank, prime];
  If[matrix === $Failed,
    record["random-" <> ToString[index] <> ":matrix-construction", False],
    preference = RandomSample[Range[columns]];
    runDifferentialCase["random-" <> ToString[index], matrix, prime,
      preference, index + 2]],
  {index, caseCount}];

(* A stable rank-2/nullity-2 case supplies semantic and binary corruption tests. *)
corruptionMatrix = {{1, 2, 3, 4}, {0, 1, 5, 6},
  {1, 3, 8, 10}, {2, 7, 21, 26}};
runDifferentialCase["production-preference-rank-two", corruptionMatrix,
  1019, {1, 2, 3, 4}, caseCount + 3];
corruptionRun = runDifferentialCase["corruption-baseline", corruptionMatrix,
  1019, {4, 2, 3, 1}, caseCount + 4, True];

If[AssociationQ[corruptionRun] &&
    Lookup[corruptionRun, "Status", None] === "VerifiedFLINTAffineRREFRun",
  request = corruptionRun["Request"];
  certificate = corruptionRun["Certificate"];
  prime = request["Prime"];
  corruptParticular = ReplacePart[certificate, "ParticularSolution" ->
    ReplacePart[certificate["ParticularSolution"], 1 ->
      Mod[certificate["ParticularSolution"][[1]] + 1, prime]]];
  record["corrupt-particular-rejected",
    rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      request, corruptParticular], "VerifiedFLINTAffineRREFCertificate"]];
  corruptNullspace = ReplacePart[certificate, "NullspaceBasis" ->
    ReplacePart[certificate["NullspaceBasis"], {1, 1} ->
      Mod[certificate["NullspaceBasis"][[1, 1]] + 1, prime]]];
  record["corrupt-nullspace-rejected",
    rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      request, corruptNullspace], "VerifiedFLINTAffineRREFCertificate"]];
  corruptRowInverse = ReplacePart[certificate, "RowMinorInverse" ->
    ReplacePart[certificate["RowMinorInverse"], {1, 1} ->
      Mod[certificate["RowMinorInverse"][[1, 1]] + 1, prime]]];
  record["corrupt-row-inverse-rejected",
    rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      request, corruptRowInverse], "VerifiedFLINTAffineRREFCertificate"]];
  corruptNormalizationInverse = ReplacePart[certificate,
    "NormalizationMinorInverse" ->
      ReplacePart[certificate["NormalizationMinorInverse"], {1, 1} ->
        Mod[certificate["NormalizationMinorInverse"][[1, 1]] + 1, prime]]];
  record["corrupt-normalization-inverse-rejected",
    rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      request, corruptNormalizationInverse],
      "VerifiedFLINTAffineRREFCertificate"]];
  corruptNormalizationColumns = ReplacePart[certificate,
    "NormalizationColumns" -> ConstantArray[1, certificate["Nullity"]]];
  record["corrupt-normalization-columns-rejected",
    rejectedAssociationQ[CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      request, corruptNormalizationColumns],
      "VerifiedFLINTAffineRREFCertificate"]];

  readBytes[file_String] := Module[{stream, bytes},
    stream = OpenRead[file, BinaryFormat -> True];
    bytes = BinaryReadList[stream, "UnsignedInteger8"];
    Close[stream]; bytes];
  writeBytes[file_String, bytes_List] := Module[{stream},
    stream = OpenWrite[file, BinaryFormat -> True];
    BinaryWrite[stream, bytes, "UnsignedInteger8"];
    Close[stream]];
  setU64LE[bytes_List, start_Integer, value_Integer] := ReplacePart[
    bytes, Thread[Range[start, start + 7] ->
      Reverse[IntegerDigits[value, 256, 8]]]];
  responseBytes = readBytes[corruptionRun["ResponseFile"]];
  corruptionDirectory = corruptionRun["ArtifactDirectory"];
  particularByteOffset = 8 + 8 11 + 8 (2 request["MatrixDimensions"][[2]]) + 1;
  firstPivotRaw = certificate["PivotColumns"][[1]] - 1;
  secondPivotRaw = certificate["PivotColumns"][[2]] - 1;
  binaryCorruptions = <|
    "magic" -> ReplacePart[responseBytes, 1 -> Mod[responseBytes[[1]] + 1, 256]],
    "dimensions" -> ReplacePart[responseBytes, 9 -> Mod[responseBytes[[9]] + 1, 256]],
    "modulus" -> ReplacePart[responseBytes, 33 -> Mod[responseBytes[[33]] + 1, 256]],
    "rank-nullity" -> ReplacePart[responseBytes, 41 -> Mod[responseBytes[[41]] + 1, 256]],
    "flags" -> ReplacePart[responseBytes, 65 -> Mod[responseBytes[[65]] + 1, 256]],
    "nonce" -> ReplacePart[responseBytes, 73 -> Mod[responseBytes[[73]] + 1, 256]],
    "payload-word-count" ->
      ReplacePart[responseBytes, 89 -> Mod[responseBytes[[89]] + 1, 256]],
    "out-of-range-pivot" -> setU64LE[responseBytes, 97,
      request["MatrixDimensions"][[2]]],
    "duplicate-pivot" -> setU64LE[responseBytes, 97, secondPivotRaw],
    "unsorted-pivots" -> setU64LE[
      setU64LE[responseBytes, 97, secondPivotRaw], 105, firstPivotRaw],
    "noncanonical-residue" -> setU64LE[responseBytes,
      particularByteOffset, request["Prime"]],
    "truncated" -> Most[responseBytes],
    "trailing-byte" -> Append[responseBytes, 0]|>;
  KeyValueMap[Function[{label, bytes},
    corruptFile = FileNameJoin[{corruptionDirectory,
      "corrupt-" <> label <> ".bin"}];
    writeBytes[corruptFile, bytes];
    parsed = CodexFLINTAffineRREFAdapter`CFFRParseResponse[
      corruptFile, request];
    record["binary-corrupt-" <> label <> "-rejected",
      rejectedAssociationQ[parsed, "FLINTAffineRREFCertificateV1"],
      <|"ParseStatus" -> Lookup[parsed, "Status", None]|>]],
    binaryCorruptions];
  Quiet[DeleteDirectory[corruptionRun["ArtifactDirectory"],
    DeleteContents -> True]],
  record["corruption-suite-setup", False];
  If[AssociationQ[corruptionRun] &&
      StringQ[Lookup[corruptionRun, "ArtifactDirectory", None]] &&
      DirectoryQ[corruptionRun["ArtifactDirectory"]],
    Quiet[DeleteDirectory[corruptionRun["ArtifactDirectory"],
      DeleteContents -> True]]]];

dependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
adapterHashAtCompletion = FileHash[adapter, "SHA256", "HexString"];
binaryHashAtCompletion = FileHash[binary, "SHA256", "HexString"];
driverHashAtCompletion = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesStableAtCompletion = TrueQ[
  dependencyHashesAtCompletion === dependencyHashesBefore &&
  adapterHashAtCompletion === adapterHashBefore &&
  binaryHashAtCompletion === binaryHashBefore &&
  driverHashAtCompletion === driverHashBefore];
Close[runtimeMessageStream];
$Messages = savedMessageStreams;
runtimeMessageText = Quiet[Check[
  Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
runtimeMessagesEmpty = StringQ[runtimeMessageText] &&
  StringTrim[runtimeMessageText] === "";
record["runtime-emitted-no-messages", runtimeMessagesEmpty,
  <|"CapturedRuntimeMessages" -> runtimeMessageText|>];
record["source-and-binary-hashes-stable", sourceHashesStableAtCompletion,
  <|"DependencyHashesAtCompletion" -> dependencyHashesAtCompletion,
    "AdapterSHA256AtCompletion" -> adapterHashAtCompletion,
    "BinarySHA256AtCompletion" -> binaryHashAtCompletion,
    "DriverSHA256AtCompletion" -> driverHashAtCompletion|>];

minimumExpectedAssertions = caseCount + 20;
If[Length[results] < minimumExpectedAssertions,
  AppendTo[results, <|
    "Label" -> "assertion-cardinality-fail-closed",
    "Passed" -> False,
    "Details" -> <|"Observed" -> Length[results],
      "MinimumExpected" -> minimumExpectedAssertions|>|>]];

passCount = Count[Lookup[results, "Passed", False], True];
failureCount = Length[results] - passCount;
report = <|
  "Status" -> If[failureCount === 0,
    "FLINTAffineRREFDifferentialSmokePassed",
    "FLINTAffineRREFDifferentialSmokeFailed"],
  "Protocol" -> "CFFR1V1/CFFR1X1",
  "RandomSeed" -> randomSeed,
  "RandomCaseCount" -> caseCount,
  "LoadedDefinitionsPresent" -> loadedDefinitionsPresent,
  "CapturedLoadMessages" -> loadMessageText,
  "CapturedRuntimeMessages" -> runtimeMessageText,
  "DependencyHashes" -> dependencyHashesBefore,
  "AdapterSHA256" -> adapterHashBefore,
  "BinarySHA256" -> binaryHashBefore,
  "DriverSHA256" -> driverHashBefore,
  "SourceHashesStableAtCompletion" -> sourceHashesStableAtCompletion,
  "PassCount" -> passCount,
  "FailureCount" -> failureCount,
  "CaseSummaries" -> caseSummaries,
  "Results" -> results|>;
If[writeReportAtomic[report] === $Failed, Exit[74]];
Print["CFFR_DIFFERENTIAL passes=" <> ToString[passCount] <>
  " failures=" <> ToString[failureCount]];
Exit[If[failureCount === 0, 0, 1]];
