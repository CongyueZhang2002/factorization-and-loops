#!/usr/bin/env wolframscript
(* Multiquadratic dispatch without a catalogued joint rationalizing
   parametrization, generator-order invariance, and the scalar-local
   root-free fast path (Design/GeneralityFixes2.md F1, F2, F6.1;
   2026-08-23).  The fixtures are rebuilt here from the construction of
   Exchange/Codex/2026-08-23/16_standardization_generality_audit/
   test_standardization_generality_adversarial.wls; the Exchange file
   itself is evidence and is never imported by a test.

   Acceptance criteria, stated before the run.

   F1, generator-order invariance.  The declaration order of a basis of
   square classes is not mathematical data.  Two presentations that declare
   the same three generators in opposite order must produce identical
   defining data and coefficient data.  Source indices remain diagnostic
   information outside those mathematical records.

   F2, chartless dispatch in the public solver.  On the audit's rank
   three {s,t} fixture with u = 1-s-t (no joint rational chart) the
   PUBLIC SolveOffDiagonalBasisTransformationBlock must reach the installable "Solved" result
   with root rank 3, eight grades and all eight sign branches certified with
   zero residual.  In production mode exact symbolic certification is
   deferred to the family certificate, while fresh modular reconstruction
   evidence and certified one-forms authorize installation.  The recorded
   artifact must round-trip through an explicit artifact context.  The historical
   An absent catalogued rationalizing parametrization is reported explicitly
   when the engine refuses the input or when dispatch is switched off; a
   caller option error comes back as the engine typed it.

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
{prepare, layoutBuilder, decompose, compose, presentationRoots,
  rootExpression, rootRadicand, statistics, artifactWrite,
  artifactLoadRaw} = private /@ {"multiquadraticOffDiagonalBlockPrepare",
  "multiquadraticOffDiagonalBlockAssemblyLayout",
  "multiquadraticFieldDecompose", "multiquadraticFieldCompose",
  "coefficientPresentationSquareRootsInVariables",
  "squareRootRecordExpression", "squareRootRecordRadicand",
  "multiquadraticFieldPathStatistics",
  "multiquadraticOffDiagonalBlockArtifactWrite", "multiquadraticOffDiagonalBlockArtifactLoadRaw"};

s = Symbol["Global`mqds"]; t = Symbol["Global`mqdt"];
u = Symbol["Global`mqdu"]; eta = Symbol["Global`mqdeta"];
cs = Symbol["Global`mqdcs"]; ct = Symbol["Global`mqdct"];
Clear[s, t, u, eta, cs, ct];

(* ------------------------------------------------------------------ *)
(* the audit's rank-three fixture, rebuilt                              *)
(* ------------------------------------------------------------------ *)

rootSquares = {s, t, u} /. u -> 1 - s - t;
frame = BuildSquareRootGeneratorsAndQuadraticRelations[rootSquares, {s, t}, {cs, ct}];
FTAssert["the rank-three Mandelstam frame is exact after u is eliminated",
  AssociationQ[frame] &&
    frame["Status"] === "SquareRootGeneratorRelationsVerified" &&
    Length[frame["SquareRootGenerators"]] === 3 &&
    frame["QuadraticRelationVerification", "PerGenerator"] ===
      {True, True, True}];

FTAssert["the root triple {s,t,1-s-t} has no joint rational chart",
  MissingQ[LookupCataloguedRationalizingParametrizationForRoots[rootSquares, {s, t}]]];

denominator = 1 - s - t;
gauge = Sqrt[s] Sqrt[t] Sqrt[denominator]/denominator;
zeroDiagonal = {{{0}}, {{0}}};
inhomogeneity = Table[{{Together[D[gauge, {s, t}[[mu]]]]}}, {mu, 2}];
strip = {zeroDiagonal, zeroDiagonal, inhomogeneity};
record = <|"Family" -> "ARBITRARY_PROCESS_ALPHA", "Variables" -> {s, t},
  "Regulator" -> eta, "OffDiagonalBlockEquation" -> strip|>;
prepareOptions = Sequence["OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> denominator,
  "Support" -> {{0, 0}}];

(* ------------------------------------------------------------------ *)
(* F1: declaration order is not part of the mathematical data           *)
(* ------------------------------------------------------------------ *)

forwardPreparation = prepare[record, frame, prepareOptions];
frameReversed = BuildSquareRootGeneratorsAndQuadraticRelations[
  Reverse[rootSquares], {s, t}, {cs, ct}];
reversedPreparation = prepare[record, frameReversed, prepareOptions];
forwardLayout = layoutBuilder[forwardPreparation];
reversedLayout = layoutBuilder[reversedPreparation];

FTAssert["both root declaration orders prepare",
  Lookup[forwardPreparation, "Status", None] ===
      "PreparedMultiquadraticOffDiagonalBlockV1" &&
    Lookup[reversedPreparation, "Status", None] ===
      "PreparedMultiquadraticOffDiagonalBlockV1" &&
    forwardPreparation["RootCount"] === 3 &&
    reversedPreparation["RootCount"] === 3];

FTAssert["the preparation schema is MultiquadraticOffDiagonalBlockPreparationV3",
  forwardPreparation["DefiningData"]["Schema"] ===
      "MultiquadraticOffDiagonalBlockPreparationV3" &&
    forwardPreparation["PreparationSchema"] ===
      "MultiquadraticOffDiagonalBlockPreparationV3"];

FTAssert["defining data does not contain source declaration indices",
  ! KeyExistsQ[forwardPreparation["DefiningData"], "RootSourceIndices"] &&
    FreeQ[forwardPreparation["DefiningData"], "RootSourceIndices"]];

FTAssert["forward and reversed declarations give permutation-equivalent defining data",
  KeyDrop[forwardPreparation["DefiningData"],
      {"RootCanonicalSquares", "RootCanonicalExpressions"}] ===
    KeyDrop[reversedPreparation["DefiningData"],
      {"RootCanonicalSquares", "RootCanonicalExpressions"}]];

FTAssert["each layout records its ordered coefficient data explicitly",
  KeyDrop[forwardLayout["CoefficientData"],
      {"RootSquares", "RootExpressions"}] ===
    KeyDrop[reversedLayout["CoefficientData"],
      {"RootSquares", "RootExpressions"}] &&
    forwardLayout["CoefficientData", "RootSquares"] ===
      Reverse[reversedLayout["CoefficientData", "RootSquares"]] &&
    forwardLayout["CoefficientData", "RootExpressions"] ===
      Reverse[reversedLayout["CoefficientData", "RootExpressions"]]];

FTAssert["the canonical roots follow the declared generator permutation",
  forwardPreparation["DefiningData"]["RootCanonicalSquares"] ===
      Reverse[reversedPreparation["DefiningData"][
        "RootCanonicalSquares"]] &&
    forwardPreparation["DefiningData"]["RootCanonicalExpressions"] ===
      Reverse[reversedPreparation["DefiningData"][
        "RootCanonicalExpressions"]]];

FTAssert["the canonical equations are identical text under either declaration",
  forwardPreparation["DefiningData"]["EquationCanonical"] ===
    reversedPreparation["DefiningData"]["EquationCanonical"]];

FTAssert["the canonical root squares themselves are the same objects",
  (rootRadicand /@ forwardPreparation["Roots"]) ===
    Reverse[rootRadicand /@ reversedPreparation["Roots"]]];

FTAssert["the source indices survive as diagnostic declaration data",
  forwardPreparation["RootSourceIndices"] === {1, 2, 3} &&
    reversedPreparation["RootSourceIndices"] === {1, 2, 3}];

(* ------------------------------------------------------------------ *)
(* F2: public dispatch without a catalogued joint parametrization       *)
(* ------------------------------------------------------------------ *)

publicResult = SolveOffDiagonalBasisTransformationBlock[strip, {s, t}, eta, frame,
  "Verbose" -> False,
  (* This test exercises rank-three dispatch and reconstruction, not the
     independent problem of discovering a denominator ansatz. *)
  "MultiquadraticOptions" -> {prepareOptions,
    "OffDiagonalBasisTransformationDenominatorFactor" -> 1,
    "IntegrabilityScreen" -> False,
    "ScreenFirst" -> False,
    "OffDiagonalBasisTransformationBlockScreen" -> False,
    "DegreeOffsetLadder" -> None}];

FTAssert["the public solver installs the triple-root strip without a joint parametrization",
  AssociationQ[publicResult] &&
    Lookup[publicResult, "Status", None] === "Solved"];

FTAssert["the public dispatch carries the installable certified-one-form contract",
  Lookup[publicResult, "SolutionContract", None] ===
      "InstallableMultiquadraticDLogV1" &&
    TrueQ[Lookup[publicResult, "OneFormsCertified", False]] &&
    Lookup[publicResult, "ExactDLog", None] ===
      Missing["DeferredToFamilyCertificate"]];

FTAssert["the dispatched result has root rank three and eight grades",
  Lookup[publicResult, "RootCount", None] === 3 &&
    Lookup[publicResult, "GradeCount", None] === 8 &&
    Lookup[publicResult, "Method", None] ===
      "DirectMultiquadraticFiniteField"];

FTAssert["every sign branch is present and has zero residual",
  Length[Lookup[publicResult, "BranchCertificate", {}]] === 8 &&
    Sort[Lookup[Lookup[publicResult, "BranchCertificate", {}],
      "BranchFlipMask", {}]] === Range[0, 7] &&
    AllTrue[Lookup[publicResult, "BranchCertificate", {}],
      TrueQ[Lookup[#, "ResidualZero", False]] &]];

FTAssert["the dispatched result carries the frame's root census and the dispatch flag",
  Lookup[publicResult, "MultiquadraticDispatch", None] === "Engine" &&
    Lookup[publicResult, "SquareRootGeneratorIndices", None] === {1, 2, 3} &&
    With[{presentation = Lookup[publicResult, "CoefficientPresentation", None]},
      AssociationQ[presentation] &&
        presentation["DataType"] === frame["DataType"] &&
        presentation["SourceVariables"] === frame["SourceVariables"] &&
        presentation["CoefficientVariables"] === frame["CoefficientVariables"] &&
        presentation["SourceToCoefficientVariableRules"] ===
          frame["SourceToCoefficientVariableRules"] &&
        presentation["SquareRootGenerators"] === frame["SquareRootGenerators"]]];

reconstructionEvidence = Lookup[publicResult,
  "RegulatorReconstruction", <||>];
trainingImageKeys = Lookup[reconstructionEvidence, "TrainingImageKeys", {}];
FTAssert["fresh unseen-prime and held-out regulator evidence authorize installation",
  Intersection[Lookup[reconstructionEvidence, "SamplePrimes", {}],
      Lookup[reconstructionEvidence, "UnseenPrimes", {}]] === {} &&
    Length[Lookup[reconstructionEvidence, "UnseenPrimes", {}]] >= 2 &&
    AllTrue[Values[Lookup[reconstructionEvidence,
        "HeldOutValidation", <||>]],
      Lookup[#1, "ValidationCount", 0] > 0 &] &&
    Lookup[reconstructionEvidence,
      "FreshProviderPointwiseCheckCount", 0] > 0 &&
    trainingImageKeys =!= {} && AllTrue[trainingImageKeys,
      MatchQ[#, {_Integer?PrimeQ, _Integer | _Rational,
        {_Integer, _Integer}}] &]];

(* the sector driver records exactly this, and reads it back in its own
   context: the context-free part of the record must survive *)
artifactDirectory = FileNameJoin[{$TemporaryDirectory,
  "FeynFacetDispatchTest-" <> StringTake[CreateUUID[], 8]}];
modularFile = FileNameJoin[{artifactDirectory, "PROBE_1_0_modular.wl"}];
modularRecord = <|"Family" -> "PROBE", "Sector" -> 1, "LowerSector" -> 0,
  "Variables" -> {s, t}, "Regulator" -> eta, "OffDiagonalBlockEquation" -> strip,
  "Summary" -> <|"Method" -> "MultiquadraticModularCandidate",
    "Status" -> "Solved", "Installed" -> True,
    "RootCount" -> publicResult["RootCount"],
    "BranchCount" -> Length[publicResult["BranchCertificate"]],
    "CoefficientData" -> forwardLayout["CoefficientData"]|>,
  "Result" -> publicResult|>;
artifactWrite[modularRecord, modularFile];
hydrated = artifactLoadRaw[modularFile, "FeynFacet`DispatchTestArtifact`"];
FTAssert["the recorded modular artifact round-trips in an explicit context",
  Lookup[hydrated, "Status", None] === "RawMultiquadraticArtifact" &&
    AssociationQ[hydrated["Value"]] &&
    hydrated["Value"]["Summary"]["Status"] === "Solved" &&
    hydrated["Value"]["Summary"]["Installed"] === True &&
    hydrated["Value"]["Summary"]["CoefficientData"] ===
      forwardLayout["CoefficientData"] &&
    hydrated["Value"]["Result"]["Status"] === "Solved" &&
    Length[hydrated["Value"]["Result"]["BranchCertificate"]] === 8];
Quiet[DeleteDirectory[artifactDirectory, DeleteContents -> True]];

disabled = SolveOffDiagonalBasisTransformationBlock[strip, {s, t}, eta, frame,
  "MultiquadraticDispatch" -> False];
FTAssert["switching the dispatch off reports the absent parametrization",
  Lookup[disabled, "Status", None] ===
      "NoCataloguedRationalizingParametrization" &&
    Lookup[disabled, "MultiquadraticDispatch", None] === "Disabled" &&
    Lookup[disabled, "SquareRootGeneratorIndices", None] === {1, 2, 3}];

(* An independent coefficient symbol lies outside the two-variable
   presentation, so the engine refuses the mathematical input. *)
frameExtra = BuildSquareRootGeneratorsAndQuadraticRelations[{s, t, u}, {s, t}, {cs, ct}];
outOfScope = SolveOffDiagonalBasisTransformationBlock[
  {zeroDiagonal, zeroDiagonal, {{{Sqrt[u]}}, {{0}}}}, {s, t}, eta,
  frameExtra];
FTAssert["an out-of-scope input reports the missing parametrization and engine refusal",
  Lookup[outOfScope, "Status", None] ===
      "NoCataloguedRationalizingParametrization" &&
    Lookup[outOfScope, "MultiquadraticDispatch", None] === "OutOfScope" &&
    Lookup[Lookup[outOfScope, "MultiquadraticRefusal", <||>], "Status", None] ===
      "ContextSensitivePreparationData"];

optionError = SolveOffDiagonalBasisTransformationBlock[strip, {s, t}, eta, frame,
  "MultiquadraticOptions" -> {"NoSuchEngineOption" -> 1}];
FTAssert["a caller option error comes back as the engine typed it, not as a chart refusal",
  Lookup[optionError, "Status", None] === "UnknownOption" &&
    Lookup[optionError, "Options", None] === {"NoSuchEngineOption"}];

malformed = SolveOffDiagonalBasisTransformationBlock[strip, {s, t}, eta, frame,
  "MultiquadraticOptions" -> "not-a-rule-list"];
FTAssert["a malformed multiquadratic option list is a typed refusal",
  Lookup[malformed, "Status", None] === "InvalidMultiquadraticOptions"];

(* the dispatch must not shadow the contracts that precede it *)
zeroInhomogeneity = SolveOffDiagonalBasisTransformationBlock[
  {zeroDiagonal, zeroDiagonal, {{{0}}, {{0}}}}, {s, t}, eta, frame];
FTAssert["a vanishing inhomogeneity is still solved exactly before any dispatch",
  Lookup[zeroInhomogeneity, "Status", None] === "Solved" &&
    Lookup[zeroInhomogeneity, "Method", None] === "ZeroInhomogeneity" &&
    TrueQ[Lookup[zeroInhomogeneity, "ExactDLog", False]]];

undeclared = SolveOffDiagonalBasisTransformationBlock[
  {zeroDiagonal, zeroDiagonal, {{{Sqrt[1 + s + 3 t]}}, {{0}}}}, {s, t}, eta,
  frame];
FTAssert["an undeclared radical is still refused before any dispatch",
  Lookup[undeclared, "Status", None] ===
    "OffDiagonalBlockEquationContainsUndeclaredRadicals"];

(* ------------------------------------------------------------------ *)
(* F6.1: the scalar-local root-free fast path                           *)
(* ------------------------------------------------------------------ *)

roots = presentationRoots[frame, {s, t}];
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

rootScalar = Together[rootExpression[roots[[1]]] rootExpression[roots[[3]]]/
  (1 + s + t) + rootExpression[roots[[2]]]];
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

FTAssert["the solve record surfaces reconstruction-path telemetry",
  AssociationQ[reconstructionEvidence] &&
    IntegerQ[Lookup[reconstructionEvidence,
      "FreshProviderPointwiseCheckCount", None]] &&
    Lookup[reconstructionEvidence,
      "FreshProviderPointwiseCheckCount", 0] > 0];

FTReport[];
