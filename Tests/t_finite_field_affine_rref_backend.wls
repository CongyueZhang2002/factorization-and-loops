#!/usr/bin/env wolframscript
(* CFFR1 plan-discovery backend ("PlanDiscoveryBackend" ->
   "FLINTAffineRREF"), Design/CFFR1Backend.md, wire format
   FeynFacet/Backends/flint/PROTOCOL_CFFR1.md.  The seven cases of the
   design note:
     (a) the native plan agrees with the Wolfram plan on rank/nullity,
         pivot/free columns and normalization columns;
     (b) an explicit request with a missing adapter is a typed failure
         and NEVER falls back to the Wolfram discoverer;
     (c) a truncated response is a typed failure naming the field;
     (d) a flipped byte in the echoed nonce is a typed failure;
     (e) an inconsistent affine system is adapter exit 5, surfaced as
         InconsistentModularSystem, with no response artifact written;
     (f) the sealed plan carries every binding field of item 5 inside its
         fingerprint, and validates;
     (g) follower solves on a CFFR-discovered plan reproduce the
         Wolfram-plan solution exactly at two primes.
   The designed system has a two-dimensional kernel whose RESIDUE columns
   are both zero, so the residue-first wire preference must fall back
   into the gauge columns -- the case that made the Wolfram normalization
   discovery fail on CF209/211/213/217. *)
$HistoryLength = 0;
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]]);

scratch = FileNameJoin[{$TemporaryDirectory,
  "t_cffr1_" <> ToString[$ProcessID]}];
If[! DirectoryQ[scratch],
  CreateDirectory[scratch, CreateIntermediateDirectories -> True]];
writeBytes[file_, bytes_] := Module[{stream},
  stream = OpenWrite[file, BinaryFormat -> True];
  BinaryWrite[stream, bytes, "UnsignedInteger8"];
  Close[stream]; file];

binary = FeynFacet`Private`finiteFieldStripCFFRBinary[];
source = FeynFacet`Private`finiteFieldStripCFFRSource[];
adapterHashes = FeynFacet`Private`finiteFieldStripCFFRAdapterHashes[];
check["adapter located and hashed once per session",
  StringQ[binary] && StringQ[source] &&
    adapterHashes["Status"] === "OK" &&
    adapterHashes["AdapterSourceSHA256"] ===
      FileHash[source, "SHA256", "HexString"] &&
    adapterHashes["AdapterBinarySHA256"] ===
      FileHash[binary, "SHA256", "HexString"]];
check["the option surface accepts exactly Wolfram and FLINTAffineRREF",
  FeynFacet`Private`finiteFieldStripPlanDiscoveryBackendDecision[
      "FLINTAffineRREF"] ===
    <|"Status" -> "OK",
      "PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
      "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF"|> &&
  Lookup[FeynFacet`Private`finiteFieldStripPlanDiscoveryBackendDecision[
    Automatic], "Status", None] === "InvalidPlanDiscoveryBackendOption"];
nonces = Table[FeynFacet`Private`finiteFieldStripCFFRNonce[], 32];
check["the 128-bit nonce is nonzero and not repeated",
  AllTrue[nonces, IntegerQ[#] && 0 < # < 2^128 &] &&
    Length[DeleteDuplicates[nonces]] === 32];

(* ------------------------------------------------------------------
   the designed system: kernel spanned by e1 + e2 and e3 - e4, so the
   RREF pivots are {1, 3, 5, 6} and the free columns {2, 4}; the two
   residue columns 5 and 6 are zero in the kernel.  Row 1 is duplicated,
   so the first `rank` rows are NOT a row basis. *)
prime = 1000003;
gaugeCount = 4; residueCount = 2;
generators = {{1, -1, 0, 0, 0, 0}, {0, 0, 1, 1, 0, 0},
  {0, 0, 0, 0, 1, 0}, {0, 0, 0, 0, 0, 1}};
SeedRandom[20260823];
matrix = Mod[RandomInteger[{1, 40}, {7, 4}] . generators, prime];
matrix = Prepend[matrix, First[matrix]];
solution0 = RandomInteger[{0, prime - 1}, 6];
rightHandSide = Mod[matrix . solution0, prime];
rank = MatrixRank[matrix, Modulus -> prime];
nullspace = NullSpace[matrix, Modulus -> prime];
preference = Join[gaugeCount + Range[residueCount], Range[gaugeCount]];
reduced = RowReduce[matrix, Modulus -> prime];
wolframPivots = DeleteMissing[Function[row,
  FirstCase[Range[Length[row]], index_ /; row[[index]] =!= 0,
    Missing["NoPivot"]]] /@ reduced];
check["fixture has the designed rank 4, nullity 2 and pivots {1,3,5,6}",
  rank === 4 && Length[nullspace] === 2 &&
    wolframPivots === {1, 3, 5, 6} &&
    MatrixRank[matrix[[Range[rank]]], Modulus -> prime] =!= rank];

(* (a) agreement of the native plan with the Wolfram plan *)
nativeRun = FeynFacet`Private`finiteFieldStripCFFRRun[matrix,
  rightHandSide, prime, preference, 2, scratch];
nativePlan = FeynFacet`Private`finiteFieldStripCFFRDiscoverPlan[matrix,
  rightHandSide, gaugeCount, residueCount, {1, 1}, {0, 0}, prime, 2,
  scratch, rank];
wolframPlan = FeynFacet`Private`finiteFieldStripDiscoverPlan[matrix,
  rank, nullspace, gaugeCount, residueCount, {1, 1}, {0, 0}, prime];
check["(a) one adapter call verified in Wolfram",
  Lookup[nativeRun, "Status", None] === "OK" &&
    nativeRun["AdapterExitCode"] === 0 && nativeRun["Threads"] === 2 &&
    Lookup[nativePlan, "Status", None] === "OK"];
check["(a) rank and nullity agree with the Wolfram plan",
  nativePlan["GenericRank"] === wolframPlan["GenericRank"] === rank &&
    nativePlan["Nullity"] === wolframPlan["Nullity"] === 2];
(* the convention pins gauge columns in DESCENDING index order (the
   low-degree representative, 2026-08-23), so the expected set is
   computed from the convention rather than hardcoded; the load-bearing
   claims are native === wolfram, admissibility, and that the residue
   columns (zero in this fixture's nullspace) were not chosen *)
check["(a) normalization columns agree (residue-first, gauge fallback)",
  nativePlan["NormalizationColumns"] === wolframPlan["NormalizationColumns"] &&
    Length[nativePlan["NormalizationColumns"]] === 2 &&
    nativePlan["NormalizationColumns"] ===
      FeynFacet`Private`finiteFieldStripNormalizationColumns[
        nullspace, gaugeCount, residueCount, prime] &&
    MatrixRank[nullspace[[All, nativePlan["NormalizationColumns"]]],
      Modulus -> prime] === 2 &&
    ! IntersectingQ[nativePlan["NormalizationColumns"],
      gaugeCount + Range[residueCount]]];
check["(a) pivot and free columns agree with the Wolfram RREF",
  nativePlan["PivotColumns"] === wolframPivots &&
    nativePlan["FreeColumns"] === {2, 4}];
check["(a) the returned independent rows are a row basis",
  MatrixRank[matrix[[nativePlan["IndependentEquationRows"]]],
    Modulus -> prime] === rank];
check["(a) request and response files are removed on success",
  FileNames["cffr1_*", scratch] === {}];

(* (b) missing binary: typed failure, no fallback.  The locator is
   Blocked -- the real bin/ is never touched. *)
missingBinary = FileNameJoin[{scratch, "absent_flint_affine_rref"}];
Clear[xCFFR, yCFFR, epsCFFR];
syntheticRecord = <|"Variables" -> {xCFFR, yCFFR}, "Regulator" -> epsCFFR,
  "Strip" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}},
    {{{1 - epsCFFR xCFFR}}, {{0}}}}|>;
preparation = FeynFacet`PrepareEpsFormStripSampling[syntheticRecord];
solveOptions = {"Primes" -> {1000003},
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}}, "PointCount" -> 8,
  "KernelCount" -> 1, "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4, "MinimumPrimeCount" -> 1,
  "ArtifactDirectory" -> FileNameJoin[{scratch, "solve"}],
  "Verbose" -> False};
{decisionAbsent, hashesAbsent, runAbsent, solveAbsent, solveNoLocator} =
  Block[{FeynFacet`Private`finiteFieldStripCFFRBinary},
    FeynFacet`Private`finiteFieldStripCFFRBinary[] := missingBinary;
    {FeynFacet`Private`finiteFieldStripPlanDiscoveryBackendDecision[
       "FLINTAffineRREF"],
     FeynFacet`Private`finiteFieldStripCFFRAdapterHashes[],
     FeynFacet`Private`finiteFieldStripCFFRRun[matrix, rightHandSide,
       prime, preference, 1, scratch],
     FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
       "PlanDiscoveryBackend" -> "FLINTAffineRREF",
       Sequence @@ solveOptions],
     Block[{FeynFacet`Private`finiteFieldStripCFFRBinary},
       FeynFacet`Private`finiteFieldStripCFFRBinary[] := None;
       FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
         "PlanDiscoveryBackend" -> "FLINTAffineRREF",
         Sequence @@ solveOptions]]}];
check["(b) a nonexistent adapter path is a typed hash failure",
  Lookup[hashesAbsent, "Status", None] ===
      "CFFRAdapterBinaryUnavailable" &&
    Lookup[runAbsent, "Status", None] ===
      "CFFRAdapterBinaryUnavailable" &&
    Lookup[decisionAbsent, "Status", None] === "OK"];
check["(b) an absent adapter makes the decision unavailable",
  Lookup[Block[{FeynFacet`Private`finiteFieldStripCFFRBinary},
    FeynFacet`Private`finiteFieldStripCFFRBinary[] := None;
    FeynFacet`Private`finiteFieldStripPlanDiscoveryBackendDecision[
      "FLINTAffineRREF"]], "Status", None] ===
    "PlanDiscoveryBackendUnavailable"];
check["(b) the solve propagates the typed failure and never falls back",
  AssociationQ[solveAbsent] &&
    Lookup[solveAbsent, "Status", None] === "PlanDiscoveryBackendFailed" &&
    Lookup[solveAbsent, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF" &&
    Lookup[Lookup[solveAbsent, "PlanDiscoveryFailure", <||>], "Status",
      None] === "CFFRAdapterBinaryUnavailable" &&
    AssociationQ[solveNoLocator] &&
    Lookup[solveNoLocator, "Status", None] ===
      "PlanDiscoveryBackendUnavailable" &&
    Lookup[solveNoLocator, "PlanDiscoveryBackendUsed", None] === None];
check["(b) the real adapter is untouched",
  FeynFacet`Private`finiteFieldStripCFFRBinary[] === binary &&
    FileHash[binary, "SHA256", "HexString"] ===
      adapterHashes["AdapterBinarySHA256"]];

(* item 5: the hashes are cached per session, and a binary replaced
   after that is a typed failure rather than a plan sealed against an
   executable nobody hashed.  A COPY of the adapter is mutated here; the
   real bin/ is never written to. *)
adapterCopy = CopyFile[binary, FileNameJoin[{scratch, "adapter_copy"}],
  OverwriteTarget -> True];
{copyHashes, mutatedHashes, mutatedRun} =
  Block[{FeynFacet`Private`finiteFieldStripCFFRBinary},
    FeynFacet`Private`finiteFieldStripCFFRBinary[] := adapterCopy;
    Module[{first, second, run},
      first = FeynFacet`Private`finiteFieldStripCFFRAdapterHashes[];
      With[{stream = OpenAppend[adapterCopy, BinaryFormat -> True]},
        BinaryWrite[stream, {0}, "UnsignedInteger8"]; Close[stream]];
      second = FeynFacet`Private`finiteFieldStripCFFRAdapterHashes[];
      run = FeynFacet`Private`finiteFieldStripCFFRRun[matrix,
        rightHandSide, prime, preference, 1, scratch];
      {first, second, run}]];
check["a binary whose hash changes mid-session is a typed failure",
  Lookup[copyHashes, "Status", None] === "OK" &&
    copyHashes["AdapterBinarySHA256"] ===
      adapterHashes["AdapterBinarySHA256"] &&
    Lookup[mutatedHashes, "Status", None] === "CFFRAdapterHashChanged" &&
    Lookup[mutatedRun, "Status", None] === "CFFRAdapterHashChanged"];

(* (c) and (d): a captured response, corrupted on disk and re-parsed *)
captureNonce = FeynFacet`Private`finiteFieldStripCFFRNonce[];
captureRequest = FeynFacet`Private`finiteFieldStripCFFRRequest[matrix,
  rightHandSide, prime, preference, captureNonce];
captureRequestFile = FileNameJoin[{scratch, "capture_request.bin"}];
captureResponseFile = FileNameJoin[{scratch, "capture_response.bin"}];
captureWritten = FeynFacet`Private`finiteFieldStripCFFRWriteRequest[
  captureRequest, captureRequestFile];
captureProcess = RunProcess[{binary, captureRequestFile,
  captureResponseFile, "1"}];
captureParsed = FeynFacet`Private`finiteFieldStripCFFRResponse[
  captureResponseFile, captureRequest];
captureBytes = BinaryReadList[captureResponseFile, "Byte"];
check["captured response parses and echoes the nonce",
  Lookup[captureWritten, "Status", None] === "OK" &&
    captureProcess["ExitCode"] === 0 &&
    Lookup[captureParsed, "Status", None] === "OK" &&
    captureParsed["Nonce"] === captureNonce &&
    captureParsed["ResponseSHA256"] ===
      FileHash[captureResponseFile, "SHA256", "HexString"]];
truncatedPayload = FeynFacet`Private`finiteFieldStripCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "truncated_payload.bin"}],
    captureBytes[[1 ;; -9]]], captureRequest];
truncatedHeader = FeynFacet`Private`finiteFieldStripCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "truncated_header.bin"}],
    captureBytes[[1 ;; 40]]], captureRequest];
check["(c) a truncated payload is typed and names the field",
  Lookup[truncatedPayload, "Status", None] === "CFFRResponseTruncated" &&
    truncatedPayload["DivergentField"] === "Payload" &&
    truncatedPayload["ExpectedByteCount"] === Length[captureBytes]];
check["(c) a truncated header is typed and names the field",
  Lookup[truncatedHeader, "Status", None] === "CFFRResponseTruncated" &&
    truncatedHeader["DivergentField"] === "Header"];
(* the echoed nonce_hi occupies bytes 73..80: 8 magic bytes plus the
   first eight header words *)
nonceCorrupted = FeynFacet`Private`finiteFieldStripCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "nonce_corrupted.bin"}],
    ReplacePart[captureBytes, 73 -> BitXor[captureBytes[[73]], 1]]],
  captureRequest];
nonceLowCorrupted = FeynFacet`Private`finiteFieldStripCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "nonce_low_corrupted.bin"}],
    ReplacePart[captureBytes, 81 -> BitXor[captureBytes[[81]], 128]]],
  captureRequest];
check["(d) a flipped echoed-nonce byte is refused (high and low word)",
  Lookup[nonceCorrupted, "Status", None] ===
      "CFFRResponseNonceMismatch" &&
    nonceCorrupted["DivergentField"] === "Nonce" &&
    Lookup[nonceLowCorrupted, "Status", None] ===
      "CFFRResponseNonceMismatch"];
check["(d) a response written for another request is refused",
  Lookup[FeynFacet`Private`finiteFieldStripCFFRResponse[
    captureResponseFile,
    FeynFacet`Private`finiteFieldStripCFFRRequest[matrix, rightHandSide,
      prime, preference,
      FeynFacet`Private`finiteFieldStripCFFRNonce[]]], "Status", None] ===
    "CFFRResponseNonceMismatch"];

(* (e) an inconsistent system: rows 1 and 2 are equal, the right-hand
   side is not *)
inconsistentRun = FeynFacet`Private`finiteFieldStripCFFRRun[matrix,
  Mod[rightHandSide + UnitVector[Length[rightHandSide], 2], prime],
  prime, preference, 1, scratch];
check["(e) exit 5 surfaces as InconsistentModularSystem",
  Lookup[inconsistentRun, "Status", None] ===
      "InconsistentModularSystem" &&
    inconsistentRun["AdapterExitCode"] === 5];
check["(e) no response artifact is written, the request is kept",
  ! FileExistsQ[inconsistentRun["ResponseFile"]] &&
    FileExistsQ[inconsistentRun["RequestFile"]]];

(* (f) and (g) run on two strip fixtures: the synthetic block above
   (nullity 0, and the two discoverers pick DIFFERENT independent row
   bases) and a 1x1 block with e = c, whose constant-gauge direction
   gives nullity 1 and forces the residue-first preference into a gauge
   normalization column. *)
Clear[xGauge, yGauge, epsGauge];
gaugeDLog[letter_] := {D[Log[letter], xGauge], D[Log[letter], yGauge]};
gaugeLetters = {xGauge, yGauge, 1 - xGauge - yGauge};
gaugeDiagonal = Table[
  Sum[{{{1}}, {{-1}}, {{2}}}[[a]] gaugeDLog[gaugeLetters[[a]]][[mu]],
    {a, Length[gaugeLetters]}], {mu, 2}];
gaugeRecord = <|"Variables" -> {xGauge, yGauge}, "Regulator" -> epsGauge,
  "Strip" -> {gaugeDiagonal, gaugeDiagonal, Table[Together[
    epsGauge Sum[{{{1}}, {{2}}, {{-3}}}[[a]] *
        gaugeDLog[gaugeLetters[[a]]][[mu]], {a, Length[gaugeLetters]}] +
      D[{{xGauge + yGauge}}, {xGauge, yGauge}[[mu]]]], {mu, 2}]}|>;
gaugePreparation = FeynFacet`PrepareEpsFormStripSampling[gaugeRecord];
sampleCommon = {"PointCount" -> 10, "NumeratorDegreeOffset" -> {0, 0},
  "SolveAffineSystem" -> True, "Preparation" -> gaugePreparation,
  "ExpectedFingerprint" -> gaugePreparation["Fingerprint"]};
syntheticCommon = {"PointCount" -> 8,
  "NumeratorDegreeOffset" -> {1, 0}, "SolveAffineSystem" -> True,
  "Preparation" -> preparation,
  "ExpectedFingerprint" -> preparation["Fingerprint"]};
nativePilot = FeynFacet`SampleEpsFormStripAffine[gaugeRecord, 1/21,
  prime, Sequence @@ sampleCommon, "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "ArtifactDirectory" -> scratch];
wolframPilot = FeynFacet`SampleEpsFormStripAffine[gaugeRecord, 1/21,
  prime, Sequence @@ sampleCommon, "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "Wolfram"];
syntheticNativePilot = FeynFacet`SampleEpsFormStripAffine[
  syntheticRecord, 1/21, prime, Sequence @@ syntheticCommon,
  "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "ArtifactDirectory" -> scratch];
syntheticWolframPilot = FeynFacet`SampleEpsFormStripAffine[
  syntheticRecord, 1/21, prime, Sequence @@ syntheticCommon,
  "DiscoverPlan" -> True, "PlanDiscoveryBackend" -> "Wolfram"];
sealed = Lookup[nativePilot, "EliminationPlan", <||>];
sealedWolfram = Lookup[wolframPilot, "EliminationPlan", <||>];
syntheticSealed = Lookup[syntheticNativePilot, "EliminationPlan", <||>];
syntheticSealedWolfram = Lookup[syntheticWolframPilot,
  "EliminationPlan", <||>];
check["(a) the two discoverers agree on a strip pilot with nullity 1",
  Lookup[sealed, "Status", None] === "OK" &&
    Lookup[sealedWolfram, "Status", None] === "OK" &&
    sealed["GenericRank"] === sealedWolfram["GenericRank"] &&
    sealed["Nullity"] === sealedWolfram["Nullity"] === 1 &&
    sealed["NormalizationColumns"] ===
      sealedWolfram["NormalizationColumns"] &&
    First[sealed["NormalizationColumns"]] <= sealed["GaugeUnknownCount"]];
bindingKeys = {"AdapterSourceSHA256", "AdapterBinarySHA256", "Protocol",
  "Nonce", "RequestSHA256", "ResponseSHA256", "Threads"};
validate[plan_, sample_] :=
  FeynFacet`Private`finiteFieldStripValidateEliminationPlan[plan,
    sample["MatrixDimensions"], sample["GaugeUnknownCount"],
    sample["FreeResidueCount"], sample["GaugeNumeratorDegrees"],
    sample["GaugeDenominatorDegrees"], sample["GaugeSupport"],
    gaugePreparation["Fingerprint"]];
check["(f) the native pilot sealed a plan and named the backend",
  Lookup[sealed, "Status", None] === "OK" &&
    sealed["PlanDiscoveryBackendRequested"] === "FLINTAffineRREF" &&
    sealed["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF" &&
    Lookup[nativePilot, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF"];
check["(f) the sealed plan carries every binding field of item 5",
  AllTrue[bindingKeys, KeyExistsQ[sealed, #] &] &&
    sealed["Protocol"] === "CFFR1" &&
    sealed["AdapterSourceSHA256"] ===
      adapterHashes["AdapterSourceSHA256"] &&
    sealed["AdapterBinarySHA256"] ===
      adapterHashes["AdapterBinarySHA256"] &&
    IntegerQ[sealed["Nonce"]] && 0 < sealed["Nonce"] < 2^128 &&
    StringLength[sealed["RequestSHA256"]] === 64 &&
    StringLength[sealed["ResponseSHA256"]] === 64 &&
    sealed["Threads"] === 2];
check["(f) the key set is the Wolfram one plus exactly the binding",
  Sort[Complement[Keys[sealed], Keys[sealedWolfram]]] ===
      Sort[bindingKeys] &&
    Complement[Keys[sealedWolfram], Keys[sealed]] === {}];
check["(f) the binding is inside the plan fingerprint",
  sealed["PlanFingerprint"] ===
      FeynFacet`Private`finiteFieldStripEliminationPlanFingerprint[
        sealed] &&
    FeynFacet`Private`finiteFieldStripEliminationPlanFingerprint[
        Join[sealed, <|"Nonce" -> sealed["Nonce"] + 1|>]] =!=
      sealed["PlanFingerprint"]];
tamperedBinding = Module[{payload},
  payload = KeyDrop[Join[sealed,
    <|"AdapterBinarySHA256" -> StringRepeat["0", 64]|>],
    "PlanFingerprint"];
  Join[payload, <|"PlanFingerprint" ->
    FeynFacet`Private`finiteFieldStripEliminationPlanFingerprint[
      payload]|>]];
check["(f) the sealed plan validates; a re-sealed foreign adapter does not",
  Lookup[validate[sealed, nativePilot], "Status", None] === "OK" &&
    Lookup[validate[sealedWolfram, wolframPilot], "Status", None] ===
      "OK" &&
    Lookup[validate[tamperedBinding, nativePilot], "Status", None] ===
      "PlanAdapterBindingMismatch" &&
    Lookup[validate[KeyDrop[sealed, "Nonce"], nativePilot], "Status",
      None] === "PlanSchemaKeysMismatch"];

(* (g) follower solves on the CFFR-discovered plan reproduce the
   Wolfram-plan solution exactly at two primes, on both fixtures *)
followerPrimes = {1000003, 2147483423};
followerAgreement[record_, options_, nativePlan_, wolframPlan_,
    followerPrime_] :=
  Module[{native, wolfram, columns, normalizedNative, normalizedWolfram},
    columns = wolframPlan["NormalizationColumns"];
    native = FeynFacet`SampleEpsFormStripAffine[record, 1/21,
      followerPrime, Sequence @@ options,
      "PlanDiscoveryBackend" -> "FLINTAffineRREF",
      "EliminationPlan" -> nativePlan];
    wolfram = FeynFacet`SampleEpsFormStripAffine[record, 1/21,
      followerPrime, Sequence @@ options,
      "PlanDiscoveryBackend" -> "Wolfram",
      "EliminationPlan" -> wolframPlan];
    normalizedNative = FeynFacet`NormalizeEpsFormAffineSample[native,
      columns, followerPrime];
    normalizedWolfram = FeynFacet`NormalizeEpsFormAffineSample[wolfram,
      columns, followerPrime];
    AssociationQ[native] && AssociationQ[wolfram] &&
      Lookup[Lookup[native, "PlanValidationStatus", <||>], "Status",
        None] === "OK" &&
      Lookup[Lookup[wolfram, "PlanValidationStatus", <||>], "Status",
        None] === "OK" &&
      native["SolvePath"] === "OneConstrainedMultiRHSFactorization" &&
      TrueQ[native["ParticularCheckZero"]] &&
      TrueQ[native["NullspaceCheckZero"]] &&
      TrueQ[native["NormalizationCheck"]] &&
      AssociationQ[normalizedNative] && AssociationQ[normalizedWolfram] &&
      normalizedNative["ParticularSolution"] ===
        normalizedWolfram["ParticularSolution"] &&
      normalizedNative["NullspaceBasis"] ===
        normalizedWolfram["NullspaceBasis"]];
check["(g) nullity-1 follower solves agree at two primes",
  Table[followerAgreement[gaugeRecord, sampleCommon, sealed,
    sealedWolfram, followerPrime], {followerPrime, followerPrimes}] ===
    {True, True}];
check["(g) follower solves agree where the row bases differ",
  syntheticSealed["IndependentEquationRows"] =!=
      syntheticSealedWolfram["IndependentEquationRows"] &&
    Table[followerAgreement[syntheticRecord, syntheticCommon,
      syntheticSealed, syntheticSealedWolfram, followerPrime],
      {followerPrime, followerPrimes}] === {True, True}];

nativeSolution = FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF", Sequence @@ solveOptions];
check["(g) a whole block solves through the native plan discovery",
  AssociationQ[nativeSolution] &&
    TrueQ[nativeSolution["ExactPfaffianResidualsZero"]] &&
    TrueQ[nativeSolution["DLogFormCertified"]] &&
    Lookup[nativeSolution, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF"];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];
Print["t_finite_field_affine_rref_backend: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
