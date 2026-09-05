#!/usr/bin/env wolframscript
(* CFFR1 plan-discovery backend ("PlanDiscoveryBackend" ->
   "FLINTAffineRREF"), Design/CFFR1Backend.md, wire format
   FeynFacet/Backends/flint/PROTOCOL_CFFR1.md.  The cases are:
   design note:
     (a) the native plan agrees with the Wolfram plan on rank/nullity,
         pivot/free columns and normalization columns;
     (b) an explicit request with a missing adapter is a typed failure
         and NEVER falls back to the Wolfram discoverer;
     (c) a truncated response is a typed failure naming the field;
     (d) a flipped byte in the echoed nonce is a typed failure;
     (e) an inconsistent affine system is adapter exit 5, surfaced as
         InconsistentModularSystem, with no response artifact written;
     (f) the reusable plan carries its defining mathematical input and
         validates directly against the coefficient layout;
     (g) follower solves on a CFFR-discovered plan reproduce the
         Wolfram-plan solution exactly at two primes.
   The designed system has a two-dimensional kernel whose RESIDUE columns
   are both zero, so the residue-first wire preference must fall back
   into the gauge columns -- the case that made the Wolfram normalization
   discovery fail on CF209/211/213/217. *)
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
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

binary = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary[];
check["adapter binary is available", StringQ[binary] && FileExistsQ[binary]];
check["the option surface accepts exactly Wolfram and FLINTAffineRREF",
  FeynFacet`Private`finiteFieldOffDiagonalBlockPlanDiscoveryBackendDecision[
      "FLINTAffineRREF"] ===
    <|"Status" -> "OK",
      "PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
      "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF"|> &&
  Lookup[FeynFacet`Private`finiteFieldOffDiagonalBlockPlanDiscoveryBackendDecision[
    Automatic], "Status", None] === "InvalidPlanDiscoveryBackendOption"];
check["direct eight-worker sampling divides a 16-core native quota",
  FeynFacet`Private`finiteFieldOffDiagonalBlockParallelBackendThreads[8, 8, 16] === 2 &&
  FeynFacet`Private`finiteFieldOffDiagonalBlockParallelBackendThreads[8, 4, 16] === 4 &&
  FeynFacet`Private`finiteFieldOffDiagonalBlockParallelBackendThreads[8, 1, 16] === 8];
nonces = Table[FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRNonce[], 32];
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
nativeRun = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRRun[matrix,
  rightHandSide, prime, preference, 2, scratch];
nativePlan = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRDiscoverPlan[matrix,
  rightHandSide, gaugeCount, residueCount, {1, 1}, {0, 0}, prime, 2,
  scratch, rank];
wolframPlan = FeynFacet`Private`finiteFieldOffDiagonalBlockDiscoverPlan[matrix,
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
      FeynFacet`Private`finiteFieldOffDiagonalBlockNormalizationColumns[
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
  "OffDiagonalBlockEquation" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}},
    {{{1 - epsCFFR xCFFR}}, {{0}}}}|>;
preparation = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[syntheticRecord];
solveOptions = {"Primes" -> {1000003},
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}}, "PointCount" -> 8,
  "KernelCount" -> 1, "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4, "MinimumPrimeCount" -> 1,
  "ArtifactDirectory" -> FileNameJoin[{scratch, "solve"}],
  "Verbose" -> False};
{decisionAbsent, runAbsent, solveAbsent, solveNoLocator} =
  Block[{FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary},
    FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary[] := missingBinary;
    {FeynFacet`Private`finiteFieldOffDiagonalBlockPlanDiscoveryBackendDecision[
       "FLINTAffineRREF"],
     FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRRun[matrix, rightHandSide,
       prime, preference, 1, scratch],
     FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[syntheticRecord,
       "PlanDiscoveryBackend" -> "FLINTAffineRREF",
       Sequence @@ solveOptions],
     Block[{FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary},
       FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary[] := None;
       FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[syntheticRecord,
         "PlanDiscoveryBackend" -> "FLINTAffineRREF",
         Sequence @@ solveOptions]]}];
check["(b) a nonexistent adapter path is a typed failure",
  Lookup[runAbsent, "Status", None] ===
      "CFFRAdapterBinaryUnavailable" &&
    Lookup[decisionAbsent, "Status", None] === "OK"];
check["(b) an absent adapter makes the decision unavailable",
  Lookup[Block[{FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary},
    FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRBinary[] := None;
    FeynFacet`Private`finiteFieldOffDiagonalBlockPlanDiscoveryBackendDecision[
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
(* (c) and (d): a captured response, corrupted on disk and re-parsed *)
captureNonce = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRNonce[];
captureRequest = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRRequest[matrix,
  rightHandSide, prime, preference, captureNonce];
captureRequestFile = FileNameJoin[{scratch, "capture_request.bin"}];
captureResponseFile = FileNameJoin[{scratch, "capture_response.bin"}];
captureWritten = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRWriteRequest[
  captureRequest, captureRequestFile];
captureProcess = RunProcess[{binary, captureRequestFile,
  captureResponseFile, "1"}];
captureParsed = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
  captureResponseFile, captureRequest];
captureBytes = BinaryReadList[captureResponseFile, "Byte"];
check["captured response parses and echoes the nonce",
  Lookup[captureWritten, "Status", None] === "OK" &&
    captureProcess["ExitCode"] === 0 &&
    Lookup[captureParsed, "Status", None] === "OK" &&
    captureParsed["Nonce"] === captureNonce];
truncatedPayload = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "truncated_payload.bin"}],
    captureBytes[[1 ;; -9]]], captureRequest];
truncatedHeader = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
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
nonceCorrupted = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
  writeBytes[FileNameJoin[{scratch, "nonce_corrupted.bin"}],
    ReplacePart[captureBytes, 73 -> BitXor[captureBytes[[73]], 1]]],
  captureRequest];
nonceLowCorrupted = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
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
  Lookup[FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRResponse[
    captureResponseFile,
    FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRRequest[matrix, rightHandSide,
      prime, preference,
      FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRNonce[]]], "Status", None] ===
    "CFFRResponseNonceMismatch"];

(* (e) an inconsistent system: rows 1 and 2 are equal, the right-hand
   side is not *)
inconsistentRun = FeynFacet`Private`finiteFieldOffDiagonalBlockCFFRRun[matrix,
  Mod[rightHandSide + UnitVector[Length[rightHandSide], 2], prime],
  prime, preference, 1, scratch];
check["(e) exit 5 surfaces as InconsistentModularSystem",
  Lookup[inconsistentRun, "Status", None] ===
      "InconsistentModularSystem" &&
    inconsistentRun["AdapterExitCode"] === 5];
check["(e) a mathematical inconsistency retains dimensions, not a dense request",
  inconsistentRun["MatrixDimensions"] === Dimensions[matrix] &&
    MissingQ[inconsistentRun["ResponseFile"]] &&
    MissingQ[inconsistentRun["RequestFile"]]];

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
  "OffDiagonalBlockEquation" -> {gaugeDiagonal, gaugeDiagonal, Table[Together[
    epsGauge Sum[{{{1}}, {{2}}, {{-3}}}[[a]] *
        gaugeDLog[gaugeLetters[[a]]][[mu]], {a, Length[gaugeLetters]}] +
      D[{{xGauge + yGauge}}, {xGauge, yGauge}[[mu]]]], {mu, 2}]}|>;
gaugePreparation = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[gaugeRecord];
sampleCommon = {"PointCount" -> 10, "NumeratorDegreeOffset" -> {0, 0},
  "SolveAffineSystem" -> True, "Preparation" -> gaugePreparation};
syntheticCommon = {"PointCount" -> 8,
  "NumeratorDegreeOffset" -> {1, 0}, "SolveAffineSystem" -> True,
  "Preparation" -> preparation};
nativePilot = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[gaugeRecord, 1/21,
  prime, Sequence @@ sampleCommon, "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "ArtifactDirectory" -> scratch];
wolframPilot = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[gaugeRecord, 1/21,
  prime, Sequence @@ sampleCommon, "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "Wolfram"];
syntheticNativePilot = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[
  syntheticRecord, 1/21, prime, Sequence @@ syntheticCommon,
  "DiscoverPlan" -> True,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "ArtifactDirectory" -> scratch];
syntheticWolframPilot = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[
  syntheticRecord, 1/21, prime, Sequence @@ syntheticCommon,
  "DiscoverPlan" -> True, "PlanDiscoveryBackend" -> "Wolfram"];
sealed = Lookup[nativePilot, "EliminationPlan", <||>];
sealedWolfram = Lookup[wolframPilot, "EliminationPlan", <||>];
syntheticSealed = Lookup[syntheticNativePilot, "EliminationPlan", <||>];
syntheticSealedWolfram = Lookup[syntheticWolframPilot,
  "EliminationPlan", <||>];
check["the native pilot bypasses Wolfram rank/solve/nullspace discovery",
  nativePilot["SolvePath"] === "NativeAffineRREFPlanDiscovery" &&
    syntheticNativePilot["SolvePath"] ===
      "NativeAffineRREFPlanDiscovery" &&
    nativePilot["RankSeconds"] === 0. &&
    nativePilot["AugmentedRankSeconds"] === 0. &&
    nativePilot["LinearSolveSeconds"] === 0. &&
    nativePilot["NullspaceSeconds"] === 0. &&
    TrueQ[nativePilot["ParticularCheckZero"]] &&
    TrueQ[nativePilot["NullspaceCheckZero"]]];
check["(a) the two discoverers agree on a strip pilot with nullity 1",
  Lookup[sealed, "Status", None] === "OK" &&
    Lookup[sealedWolfram, "Status", None] === "OK" &&
    sealed["GenericRank"] === sealedWolfram["GenericRank"] &&
    sealed["Nullity"] === sealedWolfram["Nullity"] === 1 &&
    sealed["NormalizationColumns"] ===
      sealedWolfram["NormalizationColumns"] &&
    First[sealed["NormalizationColumns"]] <= sealed["OffDiagonalBasisTransformationUnknownCount"]];
validate[plan_, sample_] :=
  FeynFacet`Private`finiteFieldOffDiagonalBlockValidateEliminationPlan[plan,
    sample["MatrixDimensions"], sample["OffDiagonalBasisTransformationUnknownCount"],
    sample["FreeResidueCount"], sample["OffDiagonalBasisTransformationNumeratorDegrees"],
    sample["OffDiagonalBasisTransformationDenominatorDegrees"], sample["OffDiagonalBasisTransformationNumeratorSupport"],
    gaugePreparation["DefiningInput"]];
check["(f) the native pilot completed a plan and named the backend",
  Lookup[sealed, "Status", None] === "OK" &&
    sealed["PlanDiscoveryBackendRequested"] === "FLINTAffineRREF" &&
    sealed["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF" &&
    Lookup[nativePilot, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF"];
check["(f) both plans store the defining mathematical input",
  sealed["DefiningInput"] === gaugePreparation["DefiningInput"] &&
    sealedWolfram["DefiningInput"] === gaugePreparation["DefiningInput"]];
planArtifactIdentity =
  FeynFacet`Private`finiteFieldOffDiagonalBlockEliminationPlanArtifactIdentity[
    sealed];
artifact = <|
  "DefiningInput" -> gaugePreparation["DefiningInput"],
  "SelectedNumeratorDegreeOffset" -> {0, 0},
  "SelectedSupportShell" -> 0,
  "OffDiagonalBasisTransformationNumeratorSupport" -> sealed["OffDiagonalBasisTransformationNumeratorSupport"],
  "EliminationPlanIdentity" -> planArtifactIdentity|>;
check["resumable prime identity ignores every execution detail",
  planArtifactIdentity ===
      KeyTake[sealed, {"GenericRank", "NormalizationColumns"}] &&
    planArtifactIdentity ===
      FeynFacet`Private`finiteFieldOffDiagonalBlockEliminationPlanArtifactIdentity[
        Join[sealed, <|"PlanDiscoveryBackendUsed" -> "Wolfram",
          "IndependentEquationRows" ->
            Reverse[sealed["IndependentEquationRows"]]|>]] &&
    FeynFacet`Private`finiteFieldOffDiagonalBlockModularArtifactValidQ[
      Join[artifact, <|
        "BackendConfiguration" -> <|"BackendThreads" -> 7|>,
        "PlanDiscoveryBackend" -> "Wolfram"|>],
      gaugePreparation["DefiningInput"], {0, 0}, 0,
      sealed["OffDiagonalBasisTransformationNumeratorSupport"],
      planArtifactIdentity] &&
    ! FeynFacet`Private`finiteFieldOffDiagonalBlockModularArtifactValidQ[
      Join[artifact, <|"EliminationPlanIdentity" ->
        <|"GenericRank" -> sealed["GenericRank"],
          "NormalizationColumns" -> {}|>|>],
      gaugePreparation["DefiningInput"], {0, 0}, 0,
      sealed["OffDiagonalBasisTransformationNumeratorSupport"],
      planArtifactIdentity] &&
    ! FeynFacet`Private`finiteFieldOffDiagonalBlockModularArtifactValidQ[
      artifact, gaugePreparation["DefiningInput"], {0, 0}, 0,
      Reverse[sealed["OffDiagonalBasisTransformationNumeratorSupport"]], planArtifactIdentity]];
changedInputPlan = Join[sealed, <|"DefiningInput" ->
  preparation["DefiningInput"]|>];
check["(f) plans validate against their mathematical input and layout",
  Lookup[validate[sealed, nativePilot], "Status", None] === "OK" &&
    Lookup[validate[sealedWolfram, wolframPilot], "Status", None] ===
      "OK" &&
    Lookup[validate[changedInputPlan, nativePilot], "Status", None] ===
      "PlanDefiningInputMismatch" &&
    Lookup[validate[Join[sealed, <|"OffDiagonalBasisTransformationUnknownCount" -> 1|>],
      nativePilot], "Status", None] === "PlanUnknownLayoutMismatch"];

(* (g) follower solves on the CFFR-discovered plan reproduce the
   Wolfram-plan solution exactly at two primes, on both fixtures *)
followerPrimes = {1000003, 2147483423};
followerAgreement[record_, options_, nativePlan_, wolframPlan_,
    followerPrime_] :=
  Module[{native, wolfram, columns, normalizedNative, normalizedWolfram},
    columns = wolframPlan["NormalizationColumns"];
    native = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 1/21,
      followerPrime, Sequence @@ options,
      "PlanDiscoveryBackend" -> "FLINTAffineRREF",
      "EliminationPlan" -> nativePlan];
    wolfram = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[record, 1/21,
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

nativeSolution = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[syntheticRecord,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF", Sequence @@ solveOptions];
check["(g) a whole block solves through the native plan discovery",
  AssociationQ[nativeSolution] &&
    TrueQ[nativeSolution["ExactPfaffianResidualsZero"]] &&
    TrueQ[nativeSolution["DLogFormCertified"]] &&
    Lookup[nativeSolution, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF"];
artifactResume = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[syntheticRecord,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF", "BackendThreads" -> 7,
  Sequence @@ solveOptions];
check["completed primes resume across an execution-thread change",
  AssociationQ[artifactResume] && artifactResume["PrimeWallSeconds"] === {} &&
    artifactResume["OffDiagonalBasisTransformationBlock"] === nativeSolution["OffDiagonalBasisTransformationBlock"] &&
    artifactResume["ResidueMatrices"] === nativeSolution["ResidueMatrices"]];
changedRecord = ReplacePart[syntheticRecord,
  {"OffDiagonalBlockEquation", 3, 1, 1, 1} -> 2 (1 - epsCFFR xCFFR)];
changedInputSolution = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[changedRecord,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF", Sequence @@ solveOptions];
check["a changed connection does not reuse the completed prime",
  AssociationQ[changedInputSolution] &&
    Length[changedInputSolution["PrimeWallSeconds"]] === 1 &&
    changedInputSolution["OffDiagonalBasisTransformationBlock"] === {{2 xCFFR}}];

resumeOptions = DeleteCases[solveOptions,
  HoldPattern[("NumeratorDegreeOffsets" | "ArtifactDirectory") -> _]];
resumedSolution = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[syntheticRecord,
  "PlanDiscoveryBackend" -> "FLINTAffineRREF",
  "Preparation" -> preparation,
  "EliminationPlan" -> syntheticSealed,
  "Support" -> syntheticNativePilot["OffDiagonalBasisTransformationNumeratorSupport"],
  "SupportLearning" -> False,
  "NumeratorDegreeOffsets" -> {{1, 0}},
  "ArtifactDirectory" -> FileNameJoin[{scratch, "resume"}],
  Sequence @@ resumeOptions];
check["a prepared solve reuses its sealed affine section",
  AssociationQ[resumedSolution] &&
    TrueQ[resumedSolution["ExactPfaffianResidualsZero"]] &&
    TrueQ[resumedSolution["DLogFormCertified"]] &&
    Lookup[resumedSolution, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF"];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];
Print["t_finite_field_affine_rref_backend: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
