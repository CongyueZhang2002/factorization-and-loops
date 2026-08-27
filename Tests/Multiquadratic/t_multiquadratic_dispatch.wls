#!/usr/bin/env wolframscript
(* Chartless multiquadratic dispatch, root-order ABI and the scalar-local
   root-free fast path (Design/GeneralityFixes2.md F1, F2, F6.1;
   2026-08-23).  The fixtures are rebuilt here from the construction of
   Exchange/Codex/2026-08-23/16_standardization_generality_audit/
   test_standardization_generality_adversarial.wls; the Exchange file
   itself is evidence and is never imported by a test.

   Acceptance criteria, stated before the run.

   F1, root-order ABI.  The DECLARATION order of a basis of square
   classes is not mathematical data.  Two frames that declare the same
   root triple in opposite order must produce BIT-IDENTICAL preparation
   fingerprints and bit-identical hashed payloads, and the canonical
   roots and canonical equations must be identical text.  The hashed
   payload must no longer carry "RootSourceIndices"; the preparation
   must still carry it as non-hashed provenance, and it must record the
   two declaration orders faithfully.  The preparation schema is
   "MultiquadraticStripPreparationV2".

   F2, chartless dispatch in the public solver.  On the audit's rank
   three {s,t} fixture with u = 1-s-t (no joint rational chart) the
   PUBLIC SolveEpsFormStripInFrame must reach "ModularConsistent" with
   root rank 3, eight grades and all eight sign branches certified with
   zero residual, must never say "Solved", and must carry the
   uninstallable contract "OneFormsNotCertified".  The recorded artifact
   must round-trip through an explicit artifact context.  The historical
   "NoRationalStripChart" answer survives ONLY where the engine refuses
   the input as outside its scope (then flagged "OutOfScope" with the
   engine's typed refusal attached) or where the dispatch is switched
   off; a caller option error comes back as the engine typed it.

   F6.1, scalar-local root-free fast path.  A scalar free of every
   declared root must decompose to the grade-zero channel padded to the
   full 2^rank width, must be counted once in "RootFreeFastPathCount",
   and must have been accepted only after the exact compose check (the
   compose-check counter advances with it).  A scalar containing a
   declared root must still take the algebraic path and recompose
   exactly.  An undeclared radical must still fail closed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

private[name_String] := Symbol["FeynFacet`Private`" <> name];
{prepare, decompose, compose, currentRoots, statistics, artifactWrite,
  artifactLoadRaw} = private /@ {"multiquadraticStripPrepare",
  "multiquadraticFieldDecompose", "multiquadraticFieldCompose",
  "transportChartCurrentRoots", "multiquadraticFieldPathStatistics",
  "multiquadraticStripArtifactWrite", "multiquadraticStripArtifactLoadRaw"};

s = Symbol["Global`mqds"]; t = Symbol["Global`mqdt"];
u = Symbol["Global`mqdu"]; eta = Symbol["Global`mqdeta"];
cs = Symbol["Global`mqdcs"]; ct = Symbol["Global`mqdct"];
Clear[s, t, u, eta, cs, ct];

(* ------------------------------------------------------------------ *)
(* the audit's rank-three fixture, rebuilt                              *)
(* ------------------------------------------------------------------ *)

rootSquares = {s, t, u} /. u -> 1 - s - t;
frame = BuildAlgebraicTransportFrame[rootSquares, {s, t}, {cs, ct}];
FTAssert["the rank-three Mandelstam frame is exact after u is eliminated",
  AssociationQ[frame] && frame["Status"] === "ExactFrame" &&
    Length[frame["Roots"]] === 3 &&
    frame["ChartCertificate", "RootIdentities"] === {True, True, True}];

FTAssert["the root triple {s,t,1-s-t} has no joint rational chart",
  MissingQ[TransportRootSetChart[rootSquares, {s, t}]]];

denominator = 1 - s - t;
gauge = Sqrt[s] Sqrt[t] Sqrt[denominator]/denominator;
zeroDiagonal = {{{0}}, {{0}}};
forcing = Table[{{Together[D[gauge, {s, t}[[mu]]]]}}, {mu, 2}];
strip = {zeroDiagonal, zeroDiagonal, forcing};
record = <|"Family" -> "ARBITRARY_PROCESS_ALPHA", "Variables" -> {s, t},
  "Regulator" -> eta, "Strip" -> strip|>;
prepareOptions = Sequence["OneForms" -> {}, "GaugeDenominator" -> denominator,
  "Support" -> {{0, 0}}];

(* ------------------------------------------------------------------ *)
(* F1: the declaration order of the roots is not part of the ABI        *)
(* ------------------------------------------------------------------ *)

forwardPreparation = prepare[record, frame, prepareOptions];
frameReversed = BuildAlgebraicTransportFrame[
  Reverse[rootSquares], {s, t}, {cs, ct}];
reversedPreparation = prepare[record, frameReversed, prepareOptions];

FTAssert["both root declaration orders prepare",
  Lookup[forwardPreparation, "Status", None] ===
      "PreparedMultiquadraticStripV1" &&
    Lookup[reversedPreparation, "Status", None] ===
      "PreparedMultiquadraticStripV1" &&
    forwardPreparation["RootCount"] === 3 &&
    reversedPreparation["RootCount"] === 3];

FTAssert["the preparation schema is MultiquadraticStripPreparationV2",
  forwardPreparation["ABIPayload"]["Schema"] ===
      "MultiquadraticStripPreparationV2" &&
    forwardPreparation["PreparationSchema"] ===
      "MultiquadraticStripPreparationV2"];

FTAssert["the hashed payload no longer carries the root source indices",
  ! KeyExistsQ[forwardPreparation["ABIPayload"], "RootSourceIndices"] &&
    FreeQ[forwardPreparation["ABIPayload"], "RootSourceIndices"]];

FTAssert["forward and reversed declaration give bit-identical fingerprints",
  forwardPreparation["ABIFingerprint"] ===
    reversedPreparation["ABIFingerprint"]];

FTAssert["forward and reversed declaration give bit-identical hashed payloads",
  forwardPreparation["ABIPayload"] === reversedPreparation["ABIPayload"]];

FTAssert["the canonical roots are identical text under either declaration",
  forwardPreparation["ABIPayload"]["RootCanonicalSquares"] ===
      reversedPreparation["ABIPayload"]["RootCanonicalSquares"] &&
    forwardPreparation["ABIPayload"]["RootCanonicalExpressions"] ===
      reversedPreparation["ABIPayload"]["RootCanonicalExpressions"] &&
    forwardPreparation["RootOrderingFingerprint"] ===
      reversedPreparation["RootOrderingFingerprint"]];

FTAssert["the canonical equations are identical text under either declaration",
  forwardPreparation["ABIPayload"]["EquationCanonical"] ===
      reversedPreparation["ABIPayload"]["EquationCanonical"] &&
    forwardPreparation["ABIPayload"]["EquationFingerprint"] ===
      reversedPreparation["ABIPayload"]["EquationFingerprint"]];

FTAssert["the canonical root squares themselves are the same objects",
  Lookup[forwardPreparation["Roots"], "RootSquare", {}] ===
    Lookup[reversedPreparation["Roots"], "RootSquare", {}]];

FTAssert["the source indices survive as non-hashed provenance",
  forwardPreparation["RootSourceIndices"] === {1, 2, 3} &&
    reversedPreparation["RootSourceIndices"] === {3, 2, 1}];

(* ------------------------------------------------------------------ *)
(* F2: the public in-frame solver dispatches the chartless strip        *)
(* ------------------------------------------------------------------ *)

publicResult = SolveEpsFormStripInFrame[strip, {s, t}, eta, frame,
  "FiniteFieldFirst" -> True, "FiniteFieldFallback" -> True,
  "Verbose" -> False];

FTAssert["the public in-frame solver reaches modular consistency on a chartless triple-root strip",
  AssociationQ[publicResult] &&
    Lookup[publicResult, "Status", None] === "ModularConsistent"];

FTAssert["the public dispatch never reports the strip as Solved",
  Lookup[publicResult, "Status", None] =!= "Solved" &&
    Lookup[publicResult, "SolutionContract", None] === "OneFormsNotCertified" &&
    ! TrueQ[Lookup[publicResult, "ExactDLog", False]]];

FTAssert["the dispatched result has root rank three and eight grades",
  Lookup[publicResult, "RootCount", None] === 3 &&
    Lookup[publicResult, "GradeCount", None] === 8 &&
    Lookup[publicResult, "Method", None] === "DirectRootChannel"];

FTAssert["every sign branch is present and has zero residual",
  Length[Lookup[publicResult, "BranchCertificate", {}]] === 8 &&
    Sort[Lookup[Lookup[publicResult, "BranchCertificate", {}],
      "BranchFlipMask", {}]] === Range[0, 7] &&
    AllTrue[Lookup[publicResult, "BranchCertificate", {}],
      TrueQ[Lookup[#, "ResidualZero", False]] &]];

FTAssert["the dispatched result carries the frame's root census and the dispatch flag",
  Lookup[publicResult, "MultiquadraticDispatch", None] === "Engine" &&
    Lookup[publicResult, "RootIndices", None] === {1, 2, 3} &&
    Length[Lookup[publicResult, "RootSquares", {}]] === 3];

FTAssert["the held-out prime and regulator value were both used",
  IntegerQ[Lookup[publicResult, "HeldOutPrime", None]] &&
    ! MemberQ[Lookup[publicResult, "SamplePrimes", {}],
      Lookup[publicResult, "HeldOutPrime", None]] &&
    ! MemberQ[Lookup[publicResult, "RegulatorValues", {}],
      Lookup[publicResult, "HeldOutRegulatorValue", None]]];

(* the sector driver records exactly this, and reads it back in its own
   context: the context-free part of the record must survive *)
artifactDirectory = FileNameJoin[{$TemporaryDirectory,
  "FeynFacetDispatchTest-" <> StringTake[CreateUUID[], 8]}];
modularFile = FileNameJoin[{artifactDirectory, "PROBE_1_0_modular.wl"}];
modularRecord = <|"Family" -> "PROBE", "Sector" -> 1, "LowerSector" -> 0,
  "Variables" -> {s, t}, "Regulator" -> eta, "Strip" -> strip,
  "Summary" -> <|"Method" -> "MultiquadraticModularCandidate",
    "Status" -> "ModularConsistent", "Installed" -> False,
    "RootCount" -> publicResult["RootCount"],
    "BranchCount" -> Length[publicResult["BranchCertificate"]],
    "ABIFingerprint" -> publicResult["ABIFingerprint"]|>,
  "Result" -> publicResult|>;
artifactWrite[modularRecord, modularFile];
hydrated = artifactLoadRaw[modularFile, "FeynFacet`DispatchTestArtifact`"];
FTAssert["the recorded modular artifact round-trips in an explicit context",
  Lookup[hydrated, "Status", None] === "RawMultiquadraticArtifact" &&
    AssociationQ[hydrated["Value"]] &&
    hydrated["Value"]["Summary"]["Status"] === "ModularConsistent" &&
    hydrated["Value"]["Summary"]["Installed"] === False &&
    hydrated["Value"]["Summary"]["ABIFingerprint"] ===
      publicResult["ABIFingerprint"] &&
    hydrated["Value"]["Result"]["Status"] === "ModularConsistent" &&
    Length[hydrated["Value"]["Result"]["BranchCertificate"]] === 8];
Quiet[DeleteDirectory[artifactDirectory, DeleteContents -> True]];

disabled = SolveEpsFormStripInFrame[strip, {s, t}, eta, frame,
  "MultiquadraticDispatch" -> False];
FTAssert["switching the dispatch off restores the historical refusal",
  Lookup[disabled, "Status", None] === "NoRationalStripChart" &&
    Lookup[disabled, "MultiquadraticDispatch", None] === "Disabled" &&
    Length[Lookup[disabled, "RootSquares", {}]] === 3];

(* an independent symbol that no chart and no modular ABI can carry: the
   engine refuses the INPUT, so the historical status is kept and the
   refusal is attached *)
frameExtra = BuildAlgebraicTransportFrame[{s, t, u}, {s, t}, {cs, ct}];
outOfScope = SolveEpsFormStripInFrame[
  {zeroDiagonal, zeroDiagonal, {{{Sqrt[u]}}, {{0}}}}, {s, t}, eta,
  frameExtra];
FTAssert["an out-of-scope input keeps NoRationalStripChart, with the engine's typed refusal attached",
  Lookup[outOfScope, "Status", None] === "NoRationalStripChart" &&
    Lookup[outOfScope, "MultiquadraticDispatch", None] === "OutOfScope" &&
    Lookup[Lookup[outOfScope, "MultiquadraticRefusal", <||>], "Status", None] ===
      "ContextSensitiveStripABI"];

optionError = SolveEpsFormStripInFrame[strip, {s, t}, eta, frame,
  "MultiquadraticOptions" -> {"NoSuchEngineOption" -> 1}];
FTAssert["a caller option error comes back as the engine typed it, not as a chart refusal",
  Lookup[optionError, "Status", None] === "UnknownOption" &&
    Lookup[optionError, "Options", None] === {"NoSuchEngineOption"}];

malformed = SolveEpsFormStripInFrame[strip, {s, t}, eta, frame,
  "MultiquadraticOptions" -> "not-a-rule-list"];
FTAssert["a malformed multiquadratic option list is a typed refusal",
  Lookup[malformed, "Status", None] === "InvalidMultiquadraticOptions"];

(* the dispatch must not shadow the contracts that precede it *)
zeroForcing = SolveEpsFormStripInFrame[
  {zeroDiagonal, zeroDiagonal, {{{0}}, {{0}}}}, {s, t}, eta, frame];
FTAssert["a vanishing forcing is still solved exactly before any dispatch",
  Lookup[zeroForcing, "Status", None] === "Solved" &&
    Lookup[zeroForcing, "Method", None] === "ZeroForcing" &&
    TrueQ[Lookup[zeroForcing, "ExactDLog", False]]];

undeclared = SolveEpsFormStripInFrame[
  {zeroDiagonal, zeroDiagonal, {{{Sqrt[1 + s + 3 t]}}, {{0}}}}, {s, t}, eta,
  frame];
FTAssert["an undeclared radical is still refused before any dispatch",
  Lookup[undeclared, "Status", None] === "StripContainsUndeclaredRadicals"];

(* ------------------------------------------------------------------ *)
(* F6.1: the scalar-local root-free fast path                           *)
(* ------------------------------------------------------------------ *)

roots = currentRoots[frame, {s, t}];
FTAssert["the frame yields three declared roots for the field primitives",
  ListQ[roots] && Length[roots] === 3];

rootFreeScalar = Together[(1 + s + eta t + s t)/(3 + s^2 + t + 2 eta)];
before = statistics[];
rootFreeChannels = decompose[rootFreeScalar, roots];
afterRootFree = statistics[];

FTAssert["a root-free scalar decomposes to the padded grade-zero channel vector",
  ListQ[rootFreeChannels] && Length[rootFreeChannels] === 8 &&
    TrueQ[Together[First[rootFreeChannels] - rootFreeScalar] === 0] &&
    Rest[rootFreeChannels] === ConstantArray[0, 7]];

FTAssert["the root-free scalar is counted once on the fast path and nowhere else",
  afterRootFree["RootFreeFastPathCount"] - before["RootFreeFastPathCount"] === 1 &&
    afterRootFree["AlgebraicPathCount"] - before["AlgebraicPathCount"] === 0];

FTAssert["the fast-path result was accepted only after the exact compose check",
  afterRootFree["ComposeCheckCount"] - before["ComposeCheckCount"] === 1 &&
    TrueQ[Together[compose[rootFreeChannels, roots] - rootFreeScalar] === 0]];

rootScalar = Together[roots[[1]]["Root"] roots[[3]]["Root"]/(1 + s + t) +
  roots[[2]]["Root"]];
afterRootFreeTwo = statistics[];
rootChannels = decompose[rootScalar, roots];
afterRoot = statistics[];

FTAssert["a scalar containing declared roots still takes the algebraic path",
  ListQ[rootChannels] && Length[rootChannels] === 8 &&
    afterRoot["RootFreeFastPathCount"] -
      afterRootFreeTwo["RootFreeFastPathCount"] === 0 &&
    afterRoot["AlgebraicPathCount"] -
      afterRootFreeTwo["AlgebraicPathCount"] === 1];

FTAssert["the algebraic path recomposes exactly",
  TrueQ[Together[compose[rootChannels, roots] - rootScalar] === 0] &&
    Count[rootChannels, channel_ /; ! TrueQ[Together[channel] === 0]] === 2];

FTAssert["a rank-zero decomposition is the fast path and keeps its single channel",
  Module[{low = statistics[], channels, high},
    channels = decompose[(1 + s)/(2 + t), {}];
    high = statistics[];
    channels === {Together[(1 + s)/(2 + t)]} &&
      high["RootFreeFastPathCount"] - low["RootFreeFastPathCount"] === 1 &&
      high["ComposeCheckCount"] - low["ComposeCheckCount"] === 1]];

FTAssert["an undeclared radical still fails closed in the field primitive",
  decompose[Sqrt[1 + s + 3 t]/(1 + s), roots] === $Failed &&
    decompose[Sqrt[1 + s + 3 t], {}] === $Failed];

(* the whole root-free population of a batch takes the fast path, and
   every vector is the oracle's padded grade-zero vector *)
batch = Table[Together[(i + (1 + Mod[i, 7]) s + (1 + Mod[2 i, 11]) t +
    eta (1 + Mod[i, 3]))/(17 + i + (1 + Mod[3 i, 13]) s +
    (1 + Mod[i, 4]) s^2 + (1 + Mod[i, 6]) t^2)], {i, 1, 24}];
batchBefore = statistics[];
batchChannels = decompose[#, roots] & /@ batch;
batchAfter = statistics[];
FTAssert["every root-free scalar of a batch takes the fast path and equals the padded oracle",
  batchChannels === (PadRight[{#}, 8, 0] & /@ batch) &&
    batchAfter["RootFreeFastPathCount"] -
      batchBefore["RootFreeFastPathCount"] === Length[batch] &&
    batchAfter["AlgebraicPathCount"] -
      batchBefore["AlgebraicPathCount"] === 0 &&
    batchAfter["ComposeCheckCount"] -
      batchBefore["ComposeCheckCount"] === Length[batch]];

FTAssert["the preparation record surfaces the channel-path telemetry",
  IntegerQ[forwardPreparation["RootFreeFastPathCount"]] &&
    AssociationQ[forwardPreparation["ChannelPathStatistics"]] &&
    Sort[Keys[forwardPreparation["ChannelPathStatistics"]]] ===
      Sort[{"RootFreeFastPathCount", "AlgebraicPathCount", "ComposeCheckCount"}] &&
    forwardPreparation["ChannelPathStatistics"]["AlgebraicPathCount"] >= 1];

FTAssert["the solve record surfaces the channel-path telemetry",
  IntegerQ[Lookup[publicResult, "RootFreeFastPathCount", None]] &&
    Lookup[publicResult, "RootFreeFastPathCount", 0] > 0 &&
    AssociationQ[Lookup[publicResult, "ChannelPathStatistics", None]] &&
    publicResult["ChannelPathStatistics"]["RootFreeFastPathCount"] ===
      publicResult["RootFreeFastPathCount"]];

FTReport[];
