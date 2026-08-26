(* The direct root-channel off-diagonal strip solver (2026-08-23).

   An off-diagonal block whose entries live in a multiquadratic
   coefficient field Q(sqrt(delta_1),...,sqrt(delta_r)) and whose root
   set has NO joint rational chart cannot go through
   SolveEpsFormStripInFrame (it stops with NoRationalStripChart).  This
   module solves such a block directly in the grade basis of
   MultiquadraticAlgebra.wl: the ansatz

     G_ij = Sum_{grade,monomial} g[i,j,grade,monomial] x^p y^q / Q(x,y) r_grade

   with constant unknowns g and constant residues R, forced by

     d_mu G - eps (E_mu G - G C_mu) + eps Sum_a R_a omega_a,mu = Bbar_mu

   (the package strip convention: dG = eps (e G - G c) + bbar -
   eps Sum_a R_a dlog L_a).  Each grade of that identity is a separate
   rational equation, so one modular point contributes
   2^r * 2 * upper * lower equations and no square root of the field is
   ever taken during assembly.

   Sources: External/CodexExchange/triple_root_2026-08-22/
   direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl
   (compile / prime forms / epsilon collapse / point and sample
   assembly / sign transforms / differential check),
   TripleRootStripAdapter.wl (channel decomposition, one-form basis,
   gauge denominator), TripleRootReconstructionPrototype.wl
   (preparation ABI, canonical affine solve, unpacking, exact channel
   residual), TripleRootAffinePilot.wl (the independent split-sign row
   assembly used as the differential reference).

   Contract, and it is NOT the package solution contract.  Installation
   of a strip requires Alphabet plus constant residue matrices and a
   certified dlog potential (familyRowGaugeDLogForm and the family
   certificate).  This solver produces closed one-forms, not certified
   potentials, so its terminal success status is "ModularConsistent"
   and NEVER "Solved" (package bug handoff 2026-08-23, External gap 2;
   Design/MultiquadraticPromotion.md section 3).  The sector driver
   records a ModularConsistent result, it never installs it.

   Changes required by the handoff and made here:
     - the production sampler has NO "BranchFlipMask" option: direct
       grade rows are branch invariant, and a flip changes no equation
       (External gap 1).  Sign flips exist only in the sign-transform
       and differential-certificate functions below, where they are the
       object under test.  Passing the option to a production entry
       point is a typed error, not a silently ignored rule;
     - fingerprints canonicalize the chart variables and the regulator
       to formal System` symbols before hashing, so no fingerprint
       depends on the reader's $Context (pool defect 3);
     - artifact hydration splits the raw load from validation, takes
       the artifact context explicitly, and uses Quiet[CheckAbort[...]]
       rather than Quiet[Check[Get[...], $Failed]], which discards a
       valid artifact after any suppressed message (pool defect 4).
       FamilyArtifactRead has both defects and is deliberately not used
       here;
     - every failure is a typed Association whose "Status" names the
       failure; no entry point returns a bare $Failed.  The four channel
       primitives (multiquadraticFieldDecompose / FieldInverse /
       FieldCompose / LiftLocalChannels) keep the source's $Failed
       sentinel: the tensor compilers detect a failed leaf structurally
       with FreeQ, which an Association would defeat;
     - an explicitly requested plan-discovery backend fails closed
       rather than falling through to the Wolfram path (handoff
       existing-defect 1).

   Reused instead of ported: the strip adapter's TRCurrentRoots,
   TRClassifyStripRecord and TRApplyRootBranches are the package's
   transportChartCurrentRoots, transportChartRootIndices and
   transportChartApplyRootBranches; only the census matcher is
   tightened here (see multiquadraticStripRootCensus).

   Deliberately NOT ported in this pass:
     - the DRCA serialization cache (DRCAReadCompiledArtifact,
       DRCAWriteCompiledArtifact and their fingerprint rebinding): it
       is a campaign-scale I/O layer for reusing one compiled system
       across pool workers, and the promotion gate is prepare /
       assemble / verify.  The context-explicit reader below is the
       piece that layer needed and the piece the handoff faulted;
     - the CRT + Thiele rational-in-epsilon interpolation batch of
       TripleRootReconstructionPrototype.wl.  The exact lift here is
       per regulator value (CRT over the sampled primes plus rational
       reconstruction of the canonical particular solution), which is
       what a modular-consistency certificate needs; reconstructing the
       regulator dependence of the gauge belongs to the installation
       route that gap 2 blocks;
     - the FLINT affine-RREF backend (native binary, request/response
       protocol, witness certificates).  It is requested through the
       "PlanDiscoveryBackend" option surface and fails closed here;
     - TRDecomposeStripRecord, the whole-strip channel round-trip
       reporter.  Its statement (every entry decomposes and recomposes
       exactly) is made inside the compiler, per scalar, by
       multiquadraticStripDecomposeScalar, and a separate report of it
       would be a second source of truth. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripStageLogQ, multiquadraticStripProgressInterval,
  multiquadraticStripStageText, multiquadraticStripStageStart,
  multiquadraticStripStageDone, multiquadraticStripStageProgress,
  multiquadraticStripStageMark, multiquadraticStripStageSize,
  $multiquadraticStripProgressLastTime, $multiquadraticStripStageLog,
  multiquadraticStripFailure, multiquadraticStripFingerprint,
  $multiquadraticStripForcingChannelSchema,
  $multiquadraticStripForcingChannelSchemaV1,
  multiquadraticStripForcingChannelFingerprint,
  multiquadraticStripForcingChannelContentHash,
  multiquadraticStripForcingChannelRecord,
  multiquadraticStripForcingChannelsAccept,
  $multiquadraticStripPrepareCheckpointSchema,
  $multiquadraticStripPrepareCheckpointSubstages,
  multiquadraticStripPrepareCheckpointFile,
  multiquadraticStripPrepareCheckpointRecord,
  multiquadraticStripPrepareCheckpointAccept,
  multiquadraticStripLetterDLogCertificate,
  multiquadraticStripLetterDLogCertificateWithKey,
  multiquadraticStripLetterDLogCertificateValidQ,
  $multiquadraticStripLetterDLogSchema,
  multiquadraticStripCompactDLogAdmission,
  multiquadraticStripChannelGradeSupport,
  multiquadraticStripChannelVectorGradeSupport,
  multiquadraticStripCompileCoreKeyFromParts,
  multiquadraticStripCompileCoreKey,
  multiquadraticStripCompileOneFormKey,
  multiquadraticStripLetterProvenanceHash,
  multiquadraticStripIntern, multiquadraticStripInternProbe,
  multiquadraticStripInternValidQ, multiquadraticStripInternReset,
  multiquadraticStripInternStatistics, multiquadraticStripInternValueBytes,
  multiquadraticStripCompileCacheClear,
  $multiquadraticStripInternPools, $multiquadraticStripInternCounters,
  $multiquadraticStripPoolEntryLimit, $multiquadraticStripPoolByteLimit,
  $multiquadraticStripPoolOversizeBytes,
  multiquadraticStripCanonicalRules, multiquadraticStripCanonicalExpression,
  multiquadraticStripContextFreeQ, multiquadraticStripZeroQ,
  multiquadraticStripModRational,
  multiquadraticFieldInverse, multiquadraticFieldInverseTower,
  multiquadraticFieldInverseLinearSolve, $multiquadraticFieldInverseMethod,
  multiquadraticFieldDecompose,
  multiquadraticFieldCompose, multiquadraticLiftLocalChannels,
  multiquadraticFieldPathStatistics, multiquadraticFieldResetPathStatistics,
  multiquadraticFieldPathStatisticsDelta,
  multiquadraticClosedOneFormQ, multiquadraticOneFormKey,
  multiquadraticDeduplicateOneForms, multiquadraticScalarOneForms,
  multiquadraticDiagonalOneFormBasis, multiquadraticCandidateOneFormBasis,
  multiquadraticRationalGaugeDenominator,
  multiquadraticStripCanonicalFactor, multiquadraticStripRationalPolarCurves,
  multiquadraticStripNormInAlphabetQ, multiquadraticStripPolynomialSquareRoot,
  multiquadraticStripSquareCompletionConstants, multiquadraticStripNormMonomials,
  multiquadraticStripAlgebraicLetters, multiquadraticStripRegulatorSampleValues,
  multiquadraticStripFieldMemberQ, multiquadraticStripFormTextKey,
  multiquadraticStripLetterOneForm, multiquadraticStripRowAlphabetLetters,
  multiquadraticStripCandidateLetters, multiquadraticStripNormDenominatorFactor,
  multiquadraticStripMergeGaugeDenominator,
  multiquadraticStripScreenCompilePolynomial,
  multiquadraticStripScreenCompileScalar,
  multiquadraticStripScreenEvaluatePolynomial,
  multiquadraticStripScreenEvaluateRational,
  multiquadraticStripScreenPowerTables,
  multiquadraticStripScreenSizeEstimate,
  multiquadraticStripScreenAdmissionRefusal,
  multiquadraticStripScreenCompileCached,
  multiquadraticStripScreenCompileCacheClear,
  $multiquadraticStripScreenCompileCache,
  $multiquadraticStripScreenCompileCacheBytes,
  $multiquadraticStripScreenCompileCacheLimit,
  $multiquadraticStripScreenCompileStatistics,
  $multiquadraticStripScreenMaximumUnknowns,
  $multiquadraticStripScreenMaximumBytes,
  multiquadraticStripIntegrabilityScreen,
  multiquadraticStripIntegrabilityScreenImages,
  multiquadraticStripGaugeAnsatz, multiquadraticStripGaugeScreen,
  multiquadraticStripGaugeScreenImages,
  multiquadraticStripGaugeScreenLadder,
  multiquadraticStripDegreeOffsetLadder,
  multiquadraticStripDegreeOffsetLadderParse,
  $multiquadraticStripDefaultDegreeOffsetLadder,
  multiquadraticStripCurveParameterization,
  multiquadraticStripRationalFunctionSquareRoot,
  multiquadraticStripGradeSquare, multiquadraticStripGradeNorm,
  multiquadraticStripMixedGradeLetters,
  $multiquadraticStripRegulatorSamplePool,
  multiquadraticStripRootOrder, multiquadraticStripRootCensus,
  multiquadraticStripRationalSquareQ, multiquadraticStripSquareClassSquareQ,
  multiquadraticStripCompileNormalizations,
  multiquadraticStripGaugeIndex, multiquadraticStripResidueIndex,
  multiquadraticStripPointRowIndex, multiquadraticStripColumnOrder,
  multiquadraticStripRowOrder, multiquadraticStripABIPayload,
  multiquadraticStripCoreCanonicalData, multiquadraticStripDecomposeForcing,
  multiquadraticStripPrepare, multiquadraticStripPreparationValidQ,
  multiquadraticStripCompilePolynomial, multiquadraticStripCompileRational,
  multiquadraticStripDecomposeScalar, multiquadraticStripCompileTensor,
  multiquadraticStripFormShape, multiquadraticStripSemanticPayload,
  multiquadraticStripCompile, multiquadraticStripCompiledValidQ,
  multiquadraticStripMapRationals, multiquadraticStripReducePolynomial,
  multiquadraticStripReduceRational, multiquadraticStripCacheInsert,
  multiquadraticStripPrimeForms, multiquadraticStripCollapsePolynomial,
  multiquadraticStripCollapseRational, multiquadraticStripCollapseEpsilon,
  multiquadraticStripMaximumExponents, multiquadraticStripEvaluatePolynomial,
  multiquadraticStripEvaluateRational, multiquadraticStripEvaluateForms,
  multiquadraticStripPolynomialImageValidQ,
  multiquadraticStripRationalImageValidQ,
  multiquadraticStripEpsilonFormsValidQ, multiquadraticStripMaskFactorMod,
  multiquadraticStripCharacter, multiquadraticStripAssemblePointInternal,
  multiquadraticStripAssemblePoint, multiquadraticStripNormalizationRows,
  multiquadraticStripAssembleSample, multiquadraticStripSignTransform,
  multiquadraticStripTransformPointToSigns,
  multiquadraticStripTransformSampleToSigns,
  multiquadraticStripSplitPointRows,
  multiquadraticStripDifferentialCheckPoint,
  multiquadraticStripAffineSolve, multiquadraticStripUnpackVector,
  multiquadraticStripChannelMatrixProduct,
  multiquadraticStripExactChannelResidual, multiquadraticStripLiftVector,
  multiquadraticStripArtifactWrite, multiquadraticStripArtifactLoadRaw,
  multiquadraticStripReadPreparedArtifact, multiquadraticStripOptionNames,
  multiquadraticStripProductionOptionGate, multiquadraticStripBackendGate,
  multiquadraticStripClearCaches, solveEpsFormStripMultiquadratic,
  multiquadraticStripDeadlineQ, multiquadraticStripDeadlineExpiredQ,
  multiquadraticStripBudgetExhausted, multiquadraticStripDeadlineCheckpoint,
  $multiquadraticStripActiveDeadline, $multiquadraticStripDeadlineTag,
  $multiquadraticStripMaximumRootCount, $multiquadraticStripMaximumEpsilonDegree,
  $multiquadraticStripSourceFile, $multiquadraticStripSourceSHA256,
  $multiquadraticStripPrimeCache, $multiquadraticStripEpsilonCache,
  $multiquadraticStripDefaultPrimes, $multiquadraticStripDefaultRegulatorValues,
  $multiquadraticFieldRootFreeFastPathCount, $multiquadraticFieldAlgebraicPathCount,
  $multiquadraticFieldComposeCheckCount
];

$multiquadraticStripMaximumRootCount = 3;
$multiquadraticStripMaximumEpsilonDegree = 256;
$multiquadraticStripPrimeCache = <||>;
$multiquadraticStripEpsilonCache = <||>;

(* Channel-decomposition telemetry (2026-08-23).  These are cumulative
   process counters; every record that reports them reports the DELTA
   over its own work, taken from multiquadraticFieldPathStatistics[]
   before and after. *)
$multiquadraticFieldRootFreeFastPathCount = 0;
$multiquadraticFieldAlgebraicPathCount = 0;
$multiquadraticFieldComposeCheckCount = 0;

multiquadraticFieldPathStatistics[] := <|
  "RootFreeFastPathCount" -> $multiquadraticFieldRootFreeFastPathCount,
  "AlgebraicPathCount" -> $multiquadraticFieldAlgebraicPathCount,
  "ComposeCheckCount" -> $multiquadraticFieldComposeCheckCount|>;

multiquadraticFieldResetPathStatistics[] := (
  $multiquadraticFieldRootFreeFastPathCount = 0;
  $multiquadraticFieldAlgebraicPathCount = 0;
  $multiquadraticFieldComposeCheckCount = 0;
  multiquadraticFieldPathStatistics[]);

(* The difference of two statistics snapshots, for a record field. *)
multiquadraticFieldPathStatisticsDelta[before_Association, after_Association] :=
  Association[KeyValueMap[#1 -> #2 - Lookup[before, #1, 0] &, after]];

(* ------------------------------------------------------------------ *)
(* Stage announcements (2026-08-25).                                    *)
(* ------------------------------------------------------------------ *)

(* An unlabelled multi-minute gap in a solve log is an instrumentation
   defect, not merely a cosmetic one: on 2026-08-25 the round-6 campaign
   watchdog could not distinguish a legitimate 21-minute first-call
   PREPARE on a 68-letter ansatz from a hung kernel, because every
   existing line on the prepare / gauge-screen / compile path is emitted
   when a stage has ALREADY FINISHED and nothing announces that one has
   started (watchdog ledger item 1, scratchpad/watchdog/r6_criteria.md).

   These helpers are that announcement and nothing else.  No result
   payload, fingerprint or artifact changes: every caller below uses
   them for their side effect and discards the returned Boolean.

   They follow "Verbose", they do not override it (Codex 14:30): a
   library call that was asked to be quiet stays quiet.  The top level
   Blocks $multiquadraticStripStageLog from its own "Verbose" option, so
   the production driver -- which already solves strips verbosely -- gets
   the lines and a quiet caller gets none.  FACET_MQ_STAGE_LOG=On forces
   them on for a run that cannot pass an option (a pool mission),
   FACET_MQ_STAGE_LOG=Off forces them off;
   FACET_MQ_PROGRESS_SECONDS sets the interior progress interval,
   default 60 s, matching the deferred-materialize convention of
   BlockEquationDeferred.wl. *)
$multiquadraticStripProgressLastTime = <||>;
$multiquadraticStripStageLog = False;

multiquadraticStripStageLogQ[] := Module[
  {value = Environment["FACET_MQ_STAGE_LOG"]},
  Which[value === "On", True, value === "Off", False,
    True, TrueQ[$multiquadraticStripStageLog]]];

(* A size probe costs a full traversal, so it is taken only when a line
   will actually be printed (Codex 14:30: "measure whether the added
   LeafCount traversals are material"; this makes the question moot on
   the quiet path). *)
multiquadraticStripStageSize[expression_] :=
  If[multiquadraticStripStageLogQ[], LeafCount[expression],
    Missing["StageLogDisabled"]];

multiquadraticStripProgressInterval[] :=
  Module[{value = Environment["FACET_MQ_PROGRESS_SECONDS"]},
    (* N[...] deliberately, as in BlockEquationDeferred.wl: Max[0, 60]
       returns the INTEGER 60 and a caller comparing it against a
       machine number would see a type it did not expect *)
    If[StringQ[value] && StringMatchQ[value, NumberString],
      N[Max[0, ToExpression[value]]], 60.]];

(* None-valued entries are dropped: the in-frame dispatcher hands this
   engine a bare {Variables, Regulator, Strip} record with no family or
   sector, and "family None, sector None, lower None" on every line is
   noise, not information. *)
multiquadraticStripStageText[stage_String, data_Association] := Module[
  {shown = DeleteCases[data, None]},
  "[multiquadratic] " <> stage <>
    If[shown === <||>, "",
      ": " <> StringRiffle[KeyValueMap[
        Function[{key, value},
          key <> " " <> ToString[
            If[Head[value] === Real, Round[value, 0.1], value], InputForm]],
        shown], ", "]]];

(* A stage START is never rate limited: one line per stage entry is the
   whole point, and a stage that is about to cost 20 minutes must be
   named before it costs them. *)
multiquadraticStripStageStart[stage_String, data_Association : <||>] := (
  If[multiquadraticStripStageLogQ[],
    $multiquadraticStripProgressLastTime[stage] = AbsoluteTime[];
    Print[multiquadraticStripStageText[stage <> " start", data]]];
  True);

multiquadraticStripStageDone[stage_String, data_Association : <||>] := (
  If[multiquadraticStripStageLogQ[],
    Print[multiquadraticStripStageText[stage <> " done", data]]];
  True);

(* A MARK is a completed measurement of a step that had no separate
   announcement -- a sub-phase whose cost is only interesting after the
   fact.  It is deliberately not spelled "done": every "start" in this
   module has a matching "done", and a mark is neither. *)
multiquadraticStripStageMark[stage_String, data_Association : <||>] := (
  If[multiquadraticStripStageLogQ[],
    Print[multiquadraticStripStageText[stage, data]]];
  True);

(* Interior progress IS rate limited, per stage: at most one line per
   interval.  The clock starts at the stage announcement, so a stage
   that finishes inside one interval prints its start and its end and
   nothing in between. *)
multiquadraticStripStageProgress[stage_String, data_Association] := If[
  multiquadraticStripStageLogQ[] &&
    AbsoluteTime[] - Lookup[$multiquadraticStripProgressLastTime, stage,
      -Infinity] >= multiquadraticStripProgressInterval[],
  $multiquadraticStripProgressLastTime[stage] = AbsoluteTime[];
  Print[multiquadraticStripStageText[stage, data]];
  True,
  False];

(* The source identity is bound once, at load: DRCA re-hashed its own
   file after every point assembly, which is one file read per modular
   point and buys nothing that a boundary check does not. *)
$multiquadraticStripSourceFile = If[StringQ[$InputFileName],
  ExpandFileName[$InputFileName], ""];
$multiquadraticStripSourceSHA256 = If[$multiquadraticStripSourceFile =!= "" &&
    FileExistsQ[$multiquadraticStripSourceFile],
  FileHash[$multiquadraticStripSourceFile, "SHA256", "HexString"],
  Missing["SourceFileUnavailable"]];

(* Sampling defaults: primes are 3 mod 4 so that every split point has
   an explicit square root (the sign-branch certificate needs one), and
   below 2^31 so that products stay machine integers. *)
$multiquadraticStripDefaultPrimes = {2147483423, 2147483399};
$multiquadraticStripDefaultRegulatorValues = {1/13, 3/17};

multiquadraticStripFailure[status_String, data_: <||>] := Join[
  <|"Status" -> status, "Module" -> "MultiquadraticStripSolve"|>, data];

(* Cooperative deadline (2026-08-24).  "Deadline" is an absolute
   AbsoluteTime[] value, Infinity by default.  It is read at natural unit
   boundaries only -- between primes, between regulator values, between
   sign branches, between exact lifts -- never inside the modular
   arithmetic, and it is NOT TimeConstrained: TimeConstrained does not
   bound task-broker helpers and has escaped in pool subkernels before
   (CLAUDE.md).  Expiry is a typed result, like every other outcome of
   this module: no $Aborted, no exception, no bare $Failed. *)
multiquadraticStripDeadlineQ[deadline_] :=
  deadline === Infinity || (NumericQ[deadline] && Positive[deadline]);

multiquadraticStripDeadlineExpiredQ[deadline_] :=
  NumericQ[deadline] && AbsoluteTime[] >= deadline;

multiquadraticStripBudgetExhausted[stage_String, elapsed_, deadline_,
    progress_Association] := multiquadraticStripFailure["BudgetExhausted",
  Join[<|"Stage" -> stage, "Elapsed" -> elapsed, "Deadline" -> deadline,
    "Method" -> "DirectRootChannel", "Resumable" -> True|>, progress]];

(* ---- cooperative deadline INSIDE the preparation (2026-08-25) ------

   multiquadraticStripPrepare had no interior deadline coverage at all:
   the driver checked once before entering it and "Deadline" was not
   among its options, so FilterRules dropped it.  A mission that entered
   first-call prepare could therefore not be stopped by its sector
   budget until prepare returned -- measured live at 51+ minutes on
   CF300 sector 12 (2026-08-25), which is the last stage of this engine
   not covered by the budget.

   The decomposition loops are the natural interior boundary and they
   sit behind opaque helpers (the interned tensor compiler, the compile
   core record), so the deadline is threaded DYNAMICALLY rather than
   through every signature: prepare Blocks the symbol below, the loops
   read it, and an expiry leaves by Throw -- Return inside a Map or a Do
   terminates only the loop (documented Wolfram trap).  Infinity is the
   default and is compared by SameQ before any clock is read, so
   "Deadline" -> Infinity performs and behaves exactly as no option at
   all. *)
$multiquadraticStripActiveDeadline = Infinity;
$multiquadraticStripDeadlineTag = "MultiquadraticStripPrepareDeadline";

multiquadraticStripDeadlineCheckpoint[substage_String,
    progress_Association] := If[
  $multiquadraticStripActiveDeadline =!= Infinity &&
    AbsoluteTime[] >= $multiquadraticStripActiveDeadline,
  Throw[Join[<|"Substage" -> substage|>, progress],
    $multiquadraticStripDeadlineTag],
  False];

multiquadraticStripFingerprint[value_] :=
  Hash[ToString[InputForm[value]], "SHA256", "HexString"];

(* ---- provenance for a reused forcing-channel decomposition ---------
   (Codex 04:30 P2: "reused forcing channels need provenance, not only
   shape")

   Decomposing the forcing into grade channels a second time inside the
   same call is a measured 807 s of the CF300 (12,9) compile, so the
   preparation hands its own decomposition on.  The reuse used to be
   accepted on ARRAY SHAPE and a $Failed scan alone: safe for the one
   caller that supplies the array it has just built, and unsafe as a
   general cache or artifact boundary, where a shape-compatible array
   from a DIFFERENT strip would be installed silently and the whole
   solve would be built on someone else's forcing.
   A supplied decomposition therefore travels as a SEALED RECORD whose
   fingerprint covers the forcing it decomposes, the declared root
   order, the variables and the regulator; the consumer recomputes that
   fingerprint from its own inputs and FAILS CLOSED on any mismatch. A
   bare array carries no provenance and can only be shape-checked, so it
   is refused typed rather than trusted.

   ---- V2 (2026-08-25, Codex 14:30 P1: forcing-channel CONTENT) -------

   V1 fingerprinted the forcing, the root squares, the rank and the
   dimensions -- everything the channels are DERIVED FROM, and not the
   channels themselves.  A same-shape mutation of the "Channels" field
   under an otherwise valid V1 seal was therefore accepted, and the whole
   solve was then built on BBar data that decomposes a different object.
   The seal is a content seal now: "ChannelsSHA256" is a field of the
   record AND an ingredient of the fingerprint, so a mutated channel
   fails both the content test and the provenance test, and the two
   failures are reported separately (a content mismatch names the
   channels; a provenance mismatch names the strip).

   V1 records are REFUSED, never upgraded: a V1 record proves nothing
   about its channels, and silently re-sealing it here would mint exactly
   the provenance it lacks.  The refusal is typed and its caller
   decomposes the forcing itself, which is what a missing seal has always
   meant. *)
$multiquadraticStripForcingChannelSchemaV1 =
  "MultiquadraticForcingChannelsV1";
$multiquadraticStripForcingChannelSchema =
  "MultiquadraticForcingChannelsV2";

(* A STRUCTURAL hash, not an algebraic one: the forcing of a real block
   carries 10^4-10^5 leaves and the point of the reuse is to avoid
   touching it again, so canonicalizing it here would cost more than the
   decomposition it protects.  The chart variables and the regulator are
   mapped to the module's formal symbols first (a cheap replacement), so
   the seal does not depend on which context they arrived in; anything
   else that differs -- a different strip, a different root order, a
   different forcing -- changes the hash and the reuse is refused. *)
multiquadraticStripForcingChannelContentHash[channels_, variables_List,
    epsilon_] := Hash[
  channels /. multiquadraticStripCanonicalRules[variables, epsilon],
  "SHA256", "HexString"];

multiquadraticStripForcingChannelFingerprint[forcing_, roots_List,
    variables_List, epsilon_, contentHash_] := Module[
  {rules = multiquadraticStripCanonicalRules[variables, epsilon]},
  multiquadraticStripFingerprint[{
    $multiquadraticStripForcingChannelSchema,
    Hash[forcing /. rules, "SHA256"],
    Hash[Lookup[roots, "RootSquare", {}] /. rules, "SHA256"],
    Length[roots], Dimensions[forcing], contentHash}]];

multiquadraticStripForcingChannelRecord[channels_, forcing_, roots_List,
    variables_List, epsilon_] := Module[
  {contentHash = multiquadraticStripForcingChannelContentHash[channels,
    variables, epsilon]},
  <|"Schema" -> $multiquadraticStripForcingChannelSchema,
    "SchemaVersion" -> 2,
    "ChannelsSHA256" -> contentHash,
    "Fingerprint" -> multiquadraticStripForcingChannelFingerprint[forcing,
      roots, variables, epsilon, contentHash],
    "GradeCount" -> 2^Length[roots],
    "Dimensions" -> Dimensions[forcing],
    "Channels" -> channels|>
];

(* "NotSupplied" (decompose), "Accepted" (reuse), or a typed refusal that
   the caller turns into a failure record *)
multiquadraticStripForcingChannelsAccept[supplied_, forcing_, roots_List,
    variables_List, epsilon_] := Module[
  {expected, gradeCount, channels, schema, contentHash},
  If[supplied === Automatic || MissingQ[supplied] || supplied === None,
    Return[<|"Status" -> "NotSupplied"|>]];
  If[! AssociationQ[supplied],
    Return[<|"Status" -> "ForcingChannelsUnsealed",
      "Reason" -> "a forcing-channel decomposition must arrive as a sealed \
record; a bare array carries no provenance and is refused"|>]];
  schema = Lookup[supplied, "Schema", None];
  (* refused-typed, NOT upgraded: a V1 seal authenticates the forcing it
     decomposes and says nothing at all about the channels it carries *)
  If[schema === $multiquadraticStripForcingChannelSchemaV1,
    Return[<|"Status" -> "ForcingChannelSealSuperseded",
      "SuppliedSchema" -> schema,
      "ExpectedSchema" -> $multiquadraticStripForcingChannelSchema,
      "Reason" -> "the V1 seal does not authenticate the channel content; \
a V1 record is recomputed, never accepted"|>]];
  If[schema =!= $multiquadraticStripForcingChannelSchema,
    Return[<|"Status" -> "ForcingChannelsUnsealed",
      "Reason" -> "a forcing-channel decomposition must arrive as a sealed \
record; a bare array carries no provenance and is refused"|>]];
  gradeCount = 2^Length[roots];
  channels = Lookup[supplied, "Channels", $Failed];
  If[! ArrayQ[channels, 4] ||
      Dimensions[channels] =!= Append[Dimensions[forcing], gradeCount] ||
      ! FreeQ[channels, $Failed],
    Return[<|"Status" -> "ForcingChannelShapeMismatch",
      "Expected" -> Append[Dimensions[forcing], gradeCount],
      "Actual" -> Dimensions[channels]|>]];
  (* the CONTENT test first: it names the field that was mutated, while
     the fingerprint test below cannot distinguish a channel mutation
     from a different strip *)
  contentHash = multiquadraticStripForcingChannelContentHash[channels,
    variables, epsilon];
  If[Lookup[supplied, "ChannelsSHA256", None] =!= contentHash,
    Return[<|"Status" -> "ForcingChannelContentMismatch",
      "ExpectedChannelsSHA256" -> contentHash,
      "SuppliedChannelsSHA256" -> Lookup[supplied, "ChannelsSHA256",
        Missing["NoChannelsSHA256"]]|>]];
  expected = multiquadraticStripForcingChannelFingerprint[forcing, roots,
    variables, epsilon, contentHash];
  If[Lookup[supplied, "Fingerprint", None] =!= expected,
    Return[<|"Status" -> "ForcingChannelProvenanceMismatch",
      "ExpectedFingerprint" -> expected,
      "SuppliedFingerprint" -> Lookup[supplied, "Fingerprint",
        Missing["NoFingerprint"]]|>]];
  <|"Status" -> "Accepted", "Channels" -> channels|>
];

(* ---- PREPARE INTERMEDIATE PERSISTENCE (2026-08-25) ------------------

   multiquadraticStripPrepare measured 2710.9 s cold on the real CF300
   (12,9) descriptor and checkpointed NOTHING: a cancelled or budget
   stopped run threw away every completed substage and the next attempt
   started from zero.  That is what the round-6 cancellation cost.

   Each expensive substage boundary now writes ONE self-describing
   record, and a resumed preparation may read it back instead of
   recomputing.  The three boundaries are exactly the three the
   cooperative deadline already names -- "ForcingChannels",
   "CandidateLetters", "GaugeDenominator" -- so a stop and a checkpoint
   speak the same vocabulary.

   PROVENANCE.  A checkpoint is NOT a cache keyed by a file name.  Every
   record carries: this source file's SHA-256, the grade-algebra ABI
   fingerprint, an INPUT fingerprint over exactly the inputs its
   substage consumed, a PAYLOAD content hash, and a seal fingerprint
   over all of those.  A reader recomputes all of them from its own
   inputs and refuses typed on any mismatch -- it never repairs, never
   upgrades and never trusts a file because it has the expected name.
   The forcing checkpoint's payload is additionally the V2 sealed
   forcing-channel record itself, so its channels are content
   authenticated by exactly the code path the in-memory reuse uses.

   CONTEXT.  Payloads are written in the formal System` symbols and
   mapped back on read, so a checkpoint written under Global` and read
   after CANONICA has taken over eps/x/y is the same object. *)
$multiquadraticStripPrepareCheckpointSchema =
  "MultiquadraticPrepareCheckpointV1";

$multiquadraticStripPrepareCheckpointSubstages = {
  "ForcingChannels", "CandidateLetters", "GaugeDenominator"};

multiquadraticStripPrepareCheckpointFile[directory_, tag_String,
    substage_String] :=
  FileNameJoin[{directory, tag <> "_prepare_" <>
    ToLowerCase[substage] <> ".wl"}];

multiquadraticStripPrepareCheckpointRecord[substage_String,
    inputFingerprint_, payload_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {canonical, contentHash},
  canonical = payload /. multiquadraticStripCanonicalRules[variables, epsilon];
  If[! multiquadraticStripContextFreeQ[canonical], Return[$Failed]];
  contentHash = Hash[canonical, "SHA256", "HexString"];
  Module[{header = <|
      "Schema" -> $multiquadraticStripPrepareCheckpointSchema,
      "SchemaVersion" -> 1,
      "Substage" -> substage,
      "SourceSHA256" -> $multiquadraticStripSourceSHA256,
      "AlgebraABIFingerprint" -> multiquadraticAlgebraABIFingerprint[],
      "InputFingerprint" -> inputFingerprint,
      "PayloadSHA256" -> contentHash|>},
    Join[header,
      <|"Fingerprint" -> multiquadraticStripFingerprint[header],
        "Payload" -> canonical|>]]
];
multiquadraticStripPrepareCheckpointRecord[___] := $Failed;

(* "Accepted" with the payload in the caller's symbols, or a typed
   refusal.  Nothing here recomputes and nothing here repairs. *)
multiquadraticStripPrepareCheckpointAccept[record_, substage_String,
    inputFingerprint_, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Module[{header, contentHash},
  If[! AssociationQ[record] ||
      Lookup[record, "Schema", None] =!=
        $multiquadraticStripPrepareCheckpointSchema,
    Return[<|"Status" -> "PrepareCheckpointSchemaUnknown",
      "Substage" -> substage,
      "SuppliedSchema" -> If[AssociationQ[record],
        Lookup[record, "Schema", None], Missing["NotAnAssociation"]]|>]];
  If[Lookup[record, "Substage", None] =!= substage,
    Return[<|"Status" -> "PrepareCheckpointSubstageMismatch",
      "Substage" -> substage,
      "SuppliedSubstage" -> Lookup[record, "Substage", None]|>]];
  If[Lookup[record, "SourceSHA256", None] =!=
        $multiquadraticStripSourceSHA256 ||
      Lookup[record, "AlgebraABIFingerprint", None] =!=
        multiquadraticAlgebraABIFingerprint[],
    Return[<|"Status" -> "PrepareCheckpointImplementationMismatch",
      "Substage" -> substage|>]];
  If[Lookup[record, "InputFingerprint", None] =!= inputFingerprint,
    Return[<|"Status" -> "PrepareCheckpointInputMismatch",
      "Substage" -> substage,
      "ExpectedInputFingerprint" -> inputFingerprint,
      "SuppliedInputFingerprint" -> Lookup[record, "InputFingerprint",
        Missing["NoInputFingerprint"]]|>]];
  contentHash = Hash[Lookup[record, "Payload", $Failed],
    "SHA256", "HexString"];
  If[Lookup[record, "PayloadSHA256", None] =!= contentHash,
    Return[<|"Status" -> "PrepareCheckpointContentMismatch",
      "Substage" -> substage,
      "ExpectedPayloadSHA256" -> contentHash,
      "SuppliedPayloadSHA256" -> Lookup[record, "PayloadSHA256",
        Missing["NoPayloadSHA256"]]|>]];
  header = KeyTake[record, {"Schema", "SchemaVersion", "Substage",
    "SourceSHA256", "AlgebraABIFingerprint", "InputFingerprint",
    "PayloadSHA256"}];
  If[Lookup[record, "Fingerprint", None] =!=
      multiquadraticStripFingerprint[header],
    Return[<|"Status" -> "PrepareCheckpointSealMismatch",
      "Substage" -> substage|>]];
  <|"Status" -> "Accepted", "Substage" -> substage,
    "Payload" -> (record["Payload"] /.
      (Reverse /@ multiquadraticStripCanonicalRules[variables, epsilon]))|>
];
multiquadraticStripPrepareCheckpointAccept[___] :=
  <|"Status" -> "PrepareCheckpointInvalidArguments"|>;

multiquadraticStripZeroQ[value_] :=
  AllTrue[Flatten[{value}], TrueQ[Together[#1] === 0] &];

multiquadraticStripModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

(* Canonicalization for every stored fingerprint: the chart variables
   and the regulator become formal System` symbols, so the InputForm
   text of an ABI payload is the same in Global`, in a dedicated
   artifact context, and after CANONICA has taken over eps/x/y. *)
multiquadraticStripCanonicalRules[variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Join[Thread[variables -> {\[FormalX], \[FormalY]}], {epsilon -> \[FormalE]}];

multiquadraticStripCanonicalExpression[expression_, rules_List] := Module[
  {rational = Together[expression /. rules]},
  {Expand[Numerator[rational]], Expand[Denominator[rational]]}
];

multiquadraticStripContextFreeQ[value_] := AllTrue[
  DeleteDuplicates[Cases[value, symbol_Symbol :> symbol, {0, Infinity},
    Heads -> True]],
  Context[#1] === "System`" &];

(* Canonical text for a payload field.  The context freedom is decided
   on the EXPRESSION, not on its printed form: a Global` symbol prints
   without its context whenever Global` happens to be on the context
   path, so a textual backtick test would pass exactly when the reader
   is the one that made the text ambiguous. *)
multiquadraticStripCanonicalText[expression_, rules_List] := Module[
  {canonical = multiquadraticStripCanonicalExpression[expression, rules]},
  If[! multiquadraticStripContextFreeQ[canonical], $Failed,
    ToString[InputForm[canonical]]]
];

(* ------------------------------------------------------------------ *)
(* Field arithmetic in the grade basis                                  *)
(* ------------------------------------------------------------------ *)

(* ---- RECURSIVE QUADRATIC-TOWER INVERSION (2026-08-25, Codex 14:30
   "rank-3 inversion strategy") ----------------------------------------

   The historical route below builds the 2^r x 2^r multiplication matrix
   of the element and solves it symbolically.  At rank 3 that is an 8x8
   rational linear solve whose entries are the strip's own rational
   functions, and it was the measured cost of every rank-3 channel
   decomposition.

   The tower does it with r divisions of DEGREE TWO instead.  Write
   A_k = A_{k-1}[r_k]/(r_k^2 - delta_k) and split the channel vector on
   the top bit, a = u + v r_k with u, v in A_{k-1} (the low and high
   halves of the vector, in exactly the mask order the ABI uses).  Then

       a^-1 = (u - v r_k) N^-1,    N = u^2 - delta_k v^2  in A_{k-1},

   so one rank-k inversion is two squarings and two products in
   A_{k-1} plus ONE rank-(k-1) inversion, and the recursion bottoms out
   at a single rational division.  The result is the same element of the
   same field; it is accepted by the SAME exact product check as before,
   which is the acceptance that decides, not the route.

   The LinearSolve route is kept callable as the reference the
   equivalence test holds the tower to, and as the fallback if the tower
   cannot divide (a zero norm at some level of the tower means the
   element is a zero divisor, and both routes then refuse). *)
multiquadraticFieldInverseTower[a_List, deltas_List] := Module[
  {rank = Length[deltas], half, u, v, subDeltas, uSquare, vSquare, norm,
   normInverse},
  If[Length[a] =!= 2^rank, Return[$Failed]];
  If[rank === 0,
    Return[If[TrueQ[Together[First[a]] === 0], $Failed,
      {Together[1/First[a]]}]]];
  half = 2^(rank - 1);
  u = Take[a, half];
  v = Drop[a, half];
  subDeltas = Most[deltas];
  (* a purely low element is an element of A_{k-1}: no norm is needed *)
  If[multiquadraticStripZeroQ[v],
    Return[Module[{inner = multiquadraticFieldInverseTower[u, subDeltas]},
      If[inner === $Failed, $Failed,
        Join[inner, ConstantArray[0, half]]]]]];
  uSquare = multiquadraticMultiply[u, u, subDeltas];
  vSquare = multiquadraticMultiply[v, v, subDeltas];
  norm = Together /@ (uSquare - Last[deltas] vSquare);
  normInverse = multiquadraticFieldInverseTower[norm, subDeltas];
  If[normInverse === $Failed, Return[$Failed]];
  Join[
    Together /@ multiquadraticMultiply[u, normInverse, subDeltas],
    Together /@ (- multiquadraticMultiply[v, normInverse, subDeltas])]
];
multiquadraticFieldInverseTower[___] := $Failed;

(* the pre-2026-08-25 route, kept as the equivalence reference *)
multiquadraticFieldInverseLinearSolve[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], columns, matrix, inverse, check},
  If[multiquadraticStripZeroQ[Rest[a]],
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    Return[Prepend[ConstantArray[0, dimension - 1], Together[1/First[a]]]]];
  columns = Table[
    multiquadraticMultiply[a, UnitVector[dimension, column], deltas],
    {column, dimension}];
  matrix = Transpose[columns];
  inverse = Quiet[LinearSolve[matrix, UnitVector[dimension, 1]]];
  If[! ListQ[inverse] || Length[inverse] =!= dimension, Return[$Failed]];
  inverse = Together /@ inverse;
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! multiquadraticStripZeroQ[check - UnitVector[dimension, 1]], $Failed, inverse]
];
multiquadraticFieldInverseLinearSolve[___] := $Failed;

(* "RecursiveTower" (the default) or "LinearSolve" (the reference).  The
   acceptance is the same exact product check on both routes, so the
   method is a cost decision and never a correctness one. *)
$multiquadraticFieldInverseMethod = "RecursiveTower";

multiquadraticFieldInverse[a_List, deltas_List] /;
    Length[a] === 2^Length[deltas] := Module[
  {dimension = Length[a], inverse, check},
  (* the grade-zero fast path, ahead of both routes: a rational scalar
     inverts in one division and needs no tower and no matrix *)
  If[multiquadraticStripZeroQ[Rest[a]],
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    Return[Prepend[ConstantArray[0, dimension - 1], Together[1/First[a]]]]];
  inverse = If[$multiquadraticFieldInverseMethod === "LinearSolve",
    multiquadraticFieldInverseLinearSolve[a, deltas],
    multiquadraticFieldInverseTower[a, deltas]];
  (* a tower that cannot divide has met a zero norm at some level; the
     matrix route is asked once before the element is called singular,
     so no element that the historical route inverted is refused now *)
  If[(! ListQ[inverse] || Length[inverse] =!= dimension) &&
      $multiquadraticFieldInverseMethod =!= "LinearSolve",
    inverse = multiquadraticFieldInverseLinearSolve[a, deltas]];
  If[! ListQ[inverse] || Length[inverse] =!= dimension, Return[$Failed]];
  (* THE acceptance, unchanged and route independent *)
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! ListQ[check] ||
      ! multiquadraticStripZeroQ[check - UnitVector[dimension, 1]],
    $Failed, inverse]
];
multiquadraticFieldInverse[___] := $Failed;

(* Root symbols are Module locals, so nothing is interned in a package
   context and nothing survives the call (pool defect 8: a generator
   must not leave thousands of definition-free names behind).  The rank
   ceiling is what makes the fixed triple enough. *)
multiquadraticFieldDecompose[expression_, roots_List] := Module[
  {rank = Length[roots], rootOne, rootTwo, rootThree, deltas, symbols,
   replaced, rational, numerator, denominator, numeratorChannels,
   denominatorChannels, denominatorInverse, result, channels, reconstructed},
  If[rank > $multiquadraticStripMaximumRootCount, Return[$Failed]];
  deltas = If[rank === 0, {},
    Together /@ Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]]];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  symbols = Take[{rootOne, rootTwo, rootThree}, rank];
  replaced = If[rank === 0, expression,
    transportChartApplyRootBranches[expression, roots, symbols]];
  If[replaced === $Failed, Return[$Failed]];
  (* rank 0 decides on the normal form, as it always has: Together may
     rationalize a numeric radical away, and that expression is a
     rational scalar *)
  If[rank > 0 &&
      ! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Together[replaced];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  (* Scalar-local root-free fast path (2026-08-23, ported from
     External/CodexExchange/finite_field_scalar_rootfree_squeeze_
     2026-08-23_xh/0001-scalar-local-root-free-fast-path.patch).  A
     rank-r bundle contains many entries that use no declared root at
     all; such a scalar is already its own grade-zero channel, so
     polynomial field reduction and the recursive norm inversion below
     compute a known answer.  The full 2^r grade ABI is preserved by
     padding, and the result is accepted ONLY after the same exact
     compose check the algebraic path is held to.  Alternatives[] (rank
     0) matches nothing, so a rank-0 call takes this path and is now
     compose-checked as well. *)
  If[FreeQ[rational, Alternatives @@ symbols],
    channels = PadRight[{rational}, 2^rank, 0];
    reconstructed = multiquadraticFieldCompose[channels, roots];
    If[reconstructed === $Failed ||
        ! TrueQ[Together[reconstructed - expression] === 0],
      Return[$Failed]];
    $multiquadraticFieldRootFreeFastPathCount++;
    $multiquadraticFieldComposeCheckCount++;
    Return[channels]];
  $multiquadraticFieldAlgebraicPathCount++;
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[! PolynomialQ[numerator, symbols] || ! PolynomialQ[denominator, symbols],
    Return[$Failed]];
  numeratorChannels = multiquadraticFromPolynomial[numerator, symbols, deltas];
  denominatorChannels = multiquadraticFromPolynomial[denominator, symbols, deltas];
  If[numeratorChannels === $Failed || denominatorChannels === $Failed,
    Return[$Failed]];
  denominatorInverse = multiquadraticFieldInverse[denominatorChannels, deltas];
  If[denominatorInverse === $Failed, Return[$Failed]];
  result = multiquadraticMultiply[numeratorChannels, denominatorInverse, deltas];
  Together /@ result
];

multiquadraticFieldCompose[channels_List, roots_List] /;
    Length[channels] === 2^Length[roots] :=
  multiquadraticToExpression[channels, Lookup[roots, "Root", {}]];
multiquadraticFieldCompose[___] := $Failed;

(* Embed a local channel vector over a subset of the declared roots
   into the declared global grade width, rank 0 included. *)
multiquadraticLiftLocalChannels[channels_List, indices_List, rank_Integer] := Module[
  {lifted, masks, globalMask},
  If[rank < 0 || indices =!= Sort[indices] || ! VectorQ[indices, IntegerQ] ||
      Length[DeleteDuplicates[indices]] =!= Length[indices] ||
      ! AllTrue[indices, 1 <= #1 <= rank &] ||
      Length[channels] =!= 2^Length[indices], Return[$Failed]];
  lifted = ConstantArray[0, 2^rank];
  If[indices === {}, lifted[[1]] = First[channels]; Return[lifted]];
  masks = Table[Sum[BitGet[localMask, bit - 1] 2^(indices[[bit]] - 1),
      {bit, Length[indices]}],
    {localMask, 0, Length[channels] - 1}];
  If[Length[DeleteDuplicates[masks]] =!= Length[masks] ||
      ! AllTrue[masks, 0 <= #1 < 2^rank &], Return[$Failed]];
  Do[
    globalMask = masks[[localMask + 1]];
    lifted[[globalMask + 1]] = channels[[localMask + 1]],
    {localMask, 0, Length[channels] - 1}];
  lifted
];
multiquadraticLiftLocalChannels[___] := $Failed;

(* ------------------------------------------------------------------ *)
(* One-form span and gauge denominator                                  *)
(* ------------------------------------------------------------------ *)

multiquadraticScalarOneForms[pair : {first_List, second_List}] := Module[
  {dimensions = Dimensions[first]},
  If[Dimensions[second] =!= dimensions || Length[dimensions] =!= 2, Return[{}]];
  Flatten[Table[{first[[i, j]], second[[i, j]]},
    {i, dimensions[[1]]}, {j, dimensions[[2]]}], 1]
];

multiquadraticClosedOneFormQ[form : {_, _}, variables : {x_, y_}] :=
  TrueQ[Together[D[form[[2]], x] - D[form[[1]], y]] === 0];

multiquadraticOneFormKey[form : {_, _}, roots_List] := Module[{channels},
  channels = multiquadraticFieldDecompose[#1, roots] & /@ form;
  If[MemberQ[channels, $Failed], $Failed,
    multiquadraticStripFingerprint[Together /@ Flatten[channels]]]
];

multiquadraticDeduplicateOneForms[forms_List, roots_List, variables_List] := Module[
  {valid, tagged},
  valid = Select[forms,
    ! multiquadraticStripZeroQ[#1] &&
      FreeQ[#1, _Symbol?(StringStartsQ[SymbolName[#1], "eps"] &)] &&
      multiquadraticClosedOneFormQ[#1, variables] &];
  tagged = Cases[Map[{multiquadraticOneFormKey[#1, roots], #1} &, valid],
    {key_ /; key =!= $Failed, form_} :> {key, form}];
  Last /@ DeleteDuplicatesBy[tagged, First]
];

multiquadraticDiagonalOneFormBasis[strip : {e_List, c_List, _List}, roots_List,
    variables : {_Symbol, _Symbol}] :=
  multiquadraticDeduplicateOneForms[
    Join[multiquadraticScalarOneForms[e], multiquadraticScalarOneForms[c]],
    roots, variables];

(* The diagonal span plus dlogs of the forcing entries at a few
   regulator values.  These are CLOSED one-forms, not certified dlog
   letters -- the distinction is the whole of External gap 2. *)
multiquadraticCandidateOneFormBasis[strip : {e_List, c_List, bbar_List},
    roots_List, variables : {x_, y_}, epsilon_Symbol] := Module[
  {diagonal, samples = {0, 1, -1, 2}, forcingEntries, functions, dlogs, combined},
  diagonal = multiquadraticDiagonalOneFormBasis[strip, roots, variables];
  forcingEntries = Flatten[bbar];
  functions = DeleteDuplicates[Flatten[Table[Together[entry /. epsilon -> value],
    {entry, forcingEntries}, {value, samples}]]];
  functions = Select[functions,
    ! TrueQ[Together[#1] === 0] && ! FreeQ[#1, Alternatives @@ variables] &];
  dlogs = ({Together[D[#1, x]/#1], Together[D[#1, y]/#1]} &) /@ functions;
  combined = multiquadraticDeduplicateOneForms[Join[diagonal, dlogs], roots, variables];
  <|"OneForms" -> combined, "DiagonalCount" -> Length[diagonal],
    "ForcingDLogCandidates" -> Length[dlogs],
    "DeduplicatedCount" -> Length[combined]|>
];

(* One power below the worst forcing pole: the gauge may carry the
   repeated part of a channel denominator, never more. *)
multiquadraticRationalGaugeDenominator[channelForcing_, variables_List] := Module[
  {entries, factorPairs, factors, powers},
  entries = Flatten[channelForcing];
  factorPairs = Flatten[Map[
    Function[entry, Module[{denominator = Denominator[Together[entry]]},
      If[TrueQ[denominator === 1], {},
        Select[Rest[FactorList[denominator]], ! TrueQ[NumericQ[First[#1]]] &]]]],
    entries], 1];
  If[factorPairs === {}, Return[1]];
  factors = DeleteDuplicates[factorPairs[[All, 1]], SameQ];
  powers = Table[{factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  Together[Times @@ ((First[#1]^(Max[0, Last[#1] - 1])) & /@
    Select[powers, ! FreeQ[First[#1], Alternatives @@ variables] &])]
];

(* ------------------------------------------------------------------ *)
(* Alphabet construction: polar curves, norms, algebraic letters        *)
(* ------------------------------------------------------------------ *)

(* 2026-08-24, CF300 (12,9) post-mortem.  Three measured facts drive
   this section.
   (i) The engine's regulator sample list {0, 1, -1, 2} lands on poles of
   that block's forcing (its channel denominators carry eps^3 and 1+eps),
   so 14 of 32 candidate dlogs were lost before the solve ever ran.  The
   sample values are now CHOSEN: a generic pool is tested entry by entry
   and a value that makes any entry singular is re-sampled.
   (ii) The block's integrability condition is inconsistent with any
   alphabet of rational letters, and is repaired by four ALGEBRAIC
   letters A +- Sqrt[delta] whose norms A^2 - delta factor completely
   into the strip's rational alphabet.  Such letters are generated here,
   not guessed: for each root square delta and each small product M of
   polar curves the rational constant c with delta + c M a perfect square
   is solved for, and A is that square root.  The norm filter below is
   the certificate that keeps the family small -- a letter whose norm
   carries an irreducible factor outside the alphabet is refused.
   (iii) The letters of the row's already installed blocks are not in the
   candidate basis at all, though the flatness identity of the row
   couples them to this block; they are adjoined when the caller supplies
   them (the sector state's StripSolvers "Alphabet" entries).           *)

(* A canonical representative of a polynomial up to RATIONAL NUMBER
   scale: the numeric part of the lexicographically leading coefficient
   is divided out.  Used for deduplication, for the exact division filter
   and for the gauge-denominator merge, where a numeric scale is
   irrelevant.  The leading coefficient itself need not be numeric: a
   polar factor of a strip carries the regulator in its coefficients
   (CF300 (12,9) has -1-2eps-x-2eps x-y-2eps y+xy+eps xy), and an
   earlier version of this function refused such a factor, which silently
   dropped an ADMISSIBLE POLE from the merged gauge denominator. *)
multiquadraticStripCanonicalFactor[polynomial_, variables_List] := Module[
  {expanded, rules, leading, scale, leadingRules},
  expanded = Expand[Together[polynomial]];
  If[! PolynomialQ[expanded, variables], Return[$Failed]];
  rules = CoefficientRules[expanded, variables];
  If[rules === {}, Return[0]];
  leading = Last[First[rules]];
  scale = If[IntegerQ[leading] || Head[leading] === Rational, leading,
    leadingRules = Quiet[CoefficientRules[Expand[leading],
      Variables[Expand[leading]]]];
    If[! ListQ[leadingRules] || leadingRules === {}, $Failed,
      Last[First[leadingRules]]]];
  If[! (IntegerQ[scale] || Head[scale] === Rational) || scale === 0,
    Return[$Failed]];
  Expand[expanded/scale]
];

(* The strip's rational polar curves: the x/y-dependent irreducible
   factors of the DENOMINATORS of the given expressions, plus the given
   root squares.  Numerators are deliberately not factored -- a forcing
   numerator is a large dense polynomial whose factorization costs more
   than the whole screen and whose irreducible parts are not poles. *)
multiquadraticStripRationalPolarCurves[expressions_, extra_List,
    variables_List] := Module[{entries, collected = {}, rational, list},
  entries = Select[Flatten[{expressions}], ! TrueQ[Quiet[Together[#1]] === 0] &];
  Do[
    rational = Quiet[Together[entry]];
    If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
      Continue[]];
    list = Quiet[Rest[FactorList[Denominator[rational]]]];
    If[! ListQ[list], Continue[]];
    collected = Join[collected,
      Select[First /@ list, ! FreeQ[#1, Alternatives @@ variables] &]],
    {entry, entries}];
  Do[
    list = Quiet[Rest[FactorList[Expand[Together[candidate]]]]];
    If[! ListQ[list], Continue[]];
    collected = Join[collected,
      Select[First /@ list, ! FreeQ[#1, Alternatives @@ variables] &]],
    {candidate, extra}];
  collected = DeleteCases[
    multiquadraticStripCanonicalFactor[#1, variables] & /@ collected,
    $Failed | 0];
  (* the alphabet is a set of KINEMATIC polar curves: a factor whose
     coefficients still carry the regulator is a pole of the connection
     in eps, not a letter, and it must not enter the norm filter (where
     it could divide a norm in Q(eps)[x,y]).  Such factors do enter the
     gauge denominator, through the merge, which reads the forcing rule's
     own denominator and not this alphabet. *)
  collected = Select[collected, Function[candidate,
    AllTrue[Last /@ CoefficientRules[candidate, variables], NumericQ]]];
  SortBy[DeleteDuplicates[collected, TrueQ[Together[#1 - #2] === 0] &],
    {LeafCount[#1], ToString[InputForm[#1]]} &]
];

(* THE NORM FILTER.  A candidate algebraic letter A +- Sqrt[delta] is
   admissible only if its norm A^2 - delta factors completely into the
   strip's rational alphabet: every alphabet letter is divided out
   exactly, as many times as it divides, and what remains must be a
   non-zero rational CONSTANT.  An irreducible factor outside the
   alphabet leaves a variable behind and the letter is refused.  This is
   the whole of the "every letter certifiable" requirement -- the
   quadratic extension generated by the letter is then unramified
   outside the alphabet. *)
multiquadraticStripNormInAlphabetQ[norm_, alphabet_List, variables_List] :=
  Module[{remainder, quotient, changed, guard = 0},
  remainder = Quiet[Expand[Together[norm]]];
  If[! PolynomialQ[remainder, variables] || TrueQ[remainder === 0],
    Return[False]];
  changed = True;
  While[changed && ! FreeQ[remainder, Alternatives @@ variables] &&
      guard < 64,
    guard++; changed = False;
    Do[
      If[FreeQ[letter, Alternatives @@ variables], Continue[]];
      quotient = Quiet[Cancel[Together[remainder/letter]]];
      If[PolynomialQ[quotient, variables],
        remainder = Expand[quotient]; changed = True],
      {letter, alphabet}]];
  TrueQ[FreeQ[remainder, Alternatives @@ variables] &&
    ! TrueQ[Together[remainder] === 0]]
];

(* An exact polynomial square root, or $Failed.  Factor first so that
   PowerExpand has a squared form to open; the answer is then VERIFIED by
   expansion, so the sign convention PowerExpand picks is irrelevant. *)
multiquadraticStripPolynomialSquareRoot[polynomial_, variables_List] := Module[
  {expanded, candidate},
  expanded = Quiet[Expand[Together[polynomial]]];
  If[! PolynomialQ[expanded, variables] || TrueQ[expanded === 0],
    Return[$Failed]];
  candidate = Quiet[PowerExpand[Sqrt[Factor[expanded]]]];
  If[PolynomialQ[candidate, variables] &&
      TrueQ[Expand[candidate^2 - expanded] === 0], Expand[candidate], $Failed]
];

(* The rational constants c for which delta + c M can be a perfect
   square.  One variable is specialized to a small integer, which turns
   the square condition into the vanishing of a discriminant -- a
   polynomial equation in c alone.  The candidates are only candidates:
   every one is verified EXACTLY by taking the polynomial square root of
   delta + c M in both variables. *)
multiquadraticStripSquareCompletionConstants[delta_, monomial_,
    variables_List, constantSymbol_Symbol] := Module[
  {candidates = {}, other, specialized, discriminant, solutions, degree},
  Do[
    other = variables[[3 - k]];
    Do[
      specialized = Quiet[Expand[
        (delta + constantSymbol monomial) /. other -> value]];
      If[! PolynomialQ[specialized, {variables[[k]], constantSymbol}],
        Continue[]];
      degree = Exponent[specialized, variables[[k]]];
      If[! IntegerQ[degree] || degree < 2, Continue[]];
      discriminant = Quiet[Discriminant[specialized, variables[[k]]]];
      If[! PolynomialQ[discriminant, constantSymbol] ||
          TrueQ[Expand[discriminant] === 0] ||
          FreeQ[discriminant, constantSymbol], Continue[]];
      solutions = Quiet[Solve[discriminant == 0, constantSymbol]];
      If[ListQ[solutions],
        candidates = Join[candidates,
          Cases[constantSymbol /. solutions, _Integer | _Rational]]],
      {value, {3, 5, 7}}],
    {k, 2}];
  DeleteDuplicates[DeleteCases[candidates, 0]]
];

(* Small products of polar curves: at most maximumFactors distinct
   letters, each to at most maximumExponent. *)
multiquadraticStripNormMonomials[alphabet_List, maximumFactors_Integer,
    maximumExponent_Integer] := Module[{subsets},
  subsets = Subsets[Range[Length[alphabet]],
    {0, Min[maximumFactors, Length[alphabet]]}];
  DeleteDuplicates[Flatten[Table[
    Times @@ (alphabet[[subset]]^exponents),
    {subset, subsets},
    {exponents, Tuples[Range[maximumExponent], Length[subset]]}], 2]]
];

Options[multiquadraticStripAlgebraicLetters] = {
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2
};

(* The algebraic letter family of a multiquadratic strip.  For every
   declared root and every small product M of polar curves, solve for the
   rational constant c with delta + c M a perfect square A^2; the letters
   are A + Sqrt[delta] and A - Sqrt[delta], with norm A^2 - delta = c M.
   The norm filter is applied to every emitted letter even though the
   construction satisfies it by design: it is the certificate the record
   carries, and it is the same predicate applied to letters that arrive
   from anywhere else (row alphabets, caller-supplied lists). *)
multiquadraticStripAlgebraicLetters[roots_List, alphabet_List,
    variables_List, opts : OptionsPattern[]] := Module[
  {constantSymbol, monomials, records = {}, delta, rootExpression, constants,
   square, a, norm, key, seen = {}, canonical},
  monomials = multiquadraticStripNormMonomials[alphabet,
    OptionValue["MaximumNormFactors"], OptionValue["MaximumNormExponent"]];
  Module[{c},
    constantSymbol = c;
    Do[
      delta = Together[Lookup[root, "RootSquare", $Failed]];
      rootExpression = Lookup[root, "Root", $Failed];
      If[delta === $Failed || rootExpression === $Failed, Continue[]];
      (* A = 0: the root itself, admissible when delta factors into the
         alphabet (it always does when delta is a declared polar curve) *)
      If[multiquadraticStripNormInAlphabetQ[-delta, alphabet, variables],
        AppendTo[records, <|"Kind" -> "Algebraic", "Letter" -> rootExpression,
          "A" -> 0, "RootSquare" -> delta, "Norm" -> Expand[-delta],
          "NormInAlphabet" -> True|>]];
      Do[
        constants = multiquadraticStripSquareCompletionConstants[delta,
          monomial, variables, constantSymbol];
        Do[
          square = Expand[delta + constant monomial];
          a = multiquadraticStripPolynomialSquareRoot[square, variables];
          If[a === $Failed, Continue[]];
          norm = Expand[a^2 - delta];
          If[TrueQ[norm === 0], Continue[]];
          If[! multiquadraticStripNormInAlphabetQ[norm, alphabet, variables],
            Continue[]];
          canonical = multiquadraticStripCanonicalFactor[a, variables];
          If[canonical === $Failed, Continue[]];
          key = {ToString[InputForm[Together[delta]]],
            ToString[InputForm[canonical]]};
          If[MemberQ[seen, key], Continue[]];
          AppendTo[seen, key];
          AppendTo[records, <|"Kind" -> "Algebraic",
            "Letter" -> Together[a + rootExpression], "A" -> a,
            "RootSquare" -> delta, "Norm" -> norm, "NormInAlphabet" -> True|>];
          AppendTo[records, <|"Kind" -> "Algebraic",
            "Letter" -> Together[a - rootExpression], "A" -> a,
            "RootSquare" -> delta, "Norm" -> norm, "NormInAlphabet" -> True|>],
          {constant, constants}],
        {monomial, monomials}],
      {root, roots}]];
  records
];

(* ------------------------------------------------------------------ *)
(* Regulator samples away from the forcing's poles                      *)
(* ------------------------------------------------------------------ *)

$multiquadraticStripRegulatorSamplePool = {1, 2, 3, 5, 7, 11, 13, 4, 6, 8,
  9, 10, 12, 5/3, 7/3, 11/5, 13/7, 7/5, 17, 19};

(* A sample value is ACCEPTED only after every forcing entry has been
   substituted and survived: a value at which any entry is singular, or
   at which no entry retains any kinematic dependence, is rejected and
   the next pool value is tried.  The substituted entries are returned,
   because the caller needs exactly them for the candidate dlogs. *)
multiquadraticStripRegulatorSampleValues[forcing_, variables_List,
    epsilon_Symbol, count_Integer, pool_List] := Module[
  {entries, accepted = {}, rejected = {}, values, usable},
  entries = Flatten[{forcing}];
  Do[
    If[Length[accepted] >= count, Break[]];
    values = Quiet[Check[
      Together[#1 /. epsilon -> candidate], $Failed,
      {Power::infy, Infinity::indet, Power::indet}] & /@ entries];
    usable = FreeQ[values, $Failed] &&
      FreeQ[values, DirectedInfinity | Indeterminate | ComplexInfinity] &&
      AnyTrue[values, ! TrueQ[Together[#1] === 0] &&
        ! FreeQ[#1, Alternatives @@ variables] &];
    If[TrueQ[usable],
      AppendTo[accepted, <|"Value" -> candidate, "Entries" -> values|>],
      AppendTo[rejected, candidate]],
    {candidate, pool}];
  <|"Status" -> If[Length[accepted] >= count, "RegulatorSamplesChosen",
      "InsufficientRegulatorSamples"],
    "Values" -> Lookup[accepted, "Value", {}],
    "SubstitutedEntries" -> Lookup[accepted, "Entries", {}],
    "RejectedValues" -> rejected, "Pool" -> pool, "Requested" -> count|>
];

(* ------------------------------------------------------------------ *)
(* Field membership, one-form keys, the candidate letter set            *)
(* ------------------------------------------------------------------ *)

(* Cheap membership test for the strip's multiquadratic field: replace
   the declared roots by symbols and require no fractional power to
   survive.  This is the early half of multiquadraticFieldDecompose and
   costs no field inversion, which is what makes an adjoined alphabet
   affordable. *)
multiquadraticStripFieldMemberQ[expression_, roots_List] := Module[
  {rootOne, rootTwo, rootThree, symbols, replaced},
  If[roots === {},
    Return[TrueQ[FreeQ[expression,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]]]]];
  symbols = Take[{rootOne, rootTwo, rootThree}, Length[roots]];
  replaced = Quiet[transportChartApplyRootBranches[expression, roots, symbols]];
  If[replaced === $Failed, Return[False]];
  TrueQ[FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]] &&
    FreeQ[Quiet[Together[replaced]],
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]]]
];

(* Deduplication key.  The Codex-derived basis keyed one-forms on their
   exact channel decomposition, which is a field inversion per component
   and measured 1539 s of the 2429 s preparation of CF300 (12,9).  Two
   forms that are equal have the same Together normal form in canonical
   symbols, so the text of that normal form is the key; a collision would
   only merge two equal columns. *)
multiquadraticStripFormTextKey[form : {_, _}, variables_List,
    epsilon_Symbol] := Module[{rules, canonical},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  canonical = Quiet[Together /@ (form /. rules)];
  Hash[ToString[InputForm[canonical]], "SHA256", "HexString"]
];

multiquadraticStripLetterOneForm[letter_, variables : {x_, y_}] := Module[
  {value = Quiet[Together[letter]], derivative},
  If[TrueQ[value === 0] || ! FreeQ[value, DirectedInfinity | Indeterminate],
    Return[$Failed]];
  derivative = Quiet[{Together[D[letter, x]/letter],
    Together[D[letter, y]/letter]}];
  If[! FreeQ[derivative, DirectedInfinity | Indeterminate | $Failed],
    Return[$Failed]];
  derivative
];

(* ---- the compact-route dlog certificate (2026-08-25, Codex 14:30 P1)

   multiquadraticStripCompileOneFormEntry may compile a one-form by
   decomposing its LETTER and differentiating inside the grade algebra --
   which computes the channels of dlog(Letter), not the channels of the
   form it was asked to compile.  Those two agree exactly when the record
   is one this module built.  The old admission test was
   SameQ[record["OneForm"], form]: it proves the caller passed the form
   it stored, and NOTHING about whether that form is the letter's dlog.
   A caller-assembled record naming a correct letter and a wrong one-form
   passed it, and the compiler then silently installed dlog(Letter) in
   place of the requested form.

   The certificate is minted HERE, at the only site that pairs a letter
   with the one-form it computed from it, and it binds the SHA-256 of
   BOTH canonical texts.  Admission re-derives both hashes from the
   letter and the form actually presented at the call, so a mutation of
   either field breaks the binding.  It is provenance, not a proof of
   correctness of this function; what it proves is that these two
   objects were produced together by this code path from this source. *)
$multiquadraticStripLetterDLogSchema = "MultiquadraticLetterDLogV1";

(* The two hashes use exactly the normalization
   multiquadraticStripFormTextKey already applies to every candidate
   one-form -- ONE Together per component and the InputForm text of the
   result.  Deliberately NOT multiquadraticStripCanonicalText, which
   additionally Expands the numerator and the denominator: on a real
   block's algebraic one-form that Expand is unbounded, and it would
   make minting a provenance tag cost more than the algebra the tag
   exists to avoid.  Together alone is canonical enough for a hash --
   it is deterministic, and the mint and the check run it on the same
   objects. *)
multiquadraticStripLetterDLogCertificate[letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticStripLetterDLogCertificateWithKey[letter,
    If[MatchQ[form, {_, _}],
      multiquadraticStripFormTextKey[form, variables, epsilon],
      $Failed], variables, epsilon];

(* the form key is what multiquadraticStripCandidateLetters computes for
   every record anyway, so the mint costs ONE Together on the letter *)
multiquadraticStripLetterDLogCertificateWithKey[letter_, formKey_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, letterText},
  If[! StringQ[formKey] || MissingQ[letter], Return[Missing["NoLetter"]]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  letterText = Quiet[ToString[InputForm[Together[letter /. rules]]]];
  If[! StringQ[letterText], Return[Missing["LetterNotNormalizable"]]];
  <|"Schema" -> $multiquadraticStripLetterDLogSchema,
    "SourceSHA256" -> $multiquadraticStripSourceSHA256,
    "LetterSHA256" -> Hash[letterText, "SHA256", "HexString"],
    "OneFormSHA256" -> formKey|>
];

multiquadraticStripLetterDLogCertificateValidQ[certificate_, letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{expected},
  If[! AssociationQ[certificate], Return[False]];
  If[Lookup[certificate, "Schema", None] =!=
      $multiquadraticStripLetterDLogSchema, Return[False]];
  expected = multiquadraticStripLetterDLogCertificate[letter, form,
    variables, epsilon];
  AssociationQ[expected] && SameQ[
    KeyTake[certificate, Keys[expected]], expected]
];

(* The row's already-installed alphabets.  A driver hands over the
   sector state's StripSolvers records; the blocks that share this
   block's ROW (same upper sector) or its COLUMN (same lower sector) are
   the ones the row flatness identity couples to it. *)
multiquadraticStripRowAlphabetLetters[stripSolvers_List, sector_,
    lowerSector_] := Module[{selected, letters},
  selected = Select[stripSolvers,
    AssociationQ[#1] && (Lookup[#1, "Sector", None] === sector ||
      Lookup[#1, "LowerSector", None] === lowerSector) &];
  letters = Flatten[Lookup[selected, "Alphabet", {}] /. Missing[___] :> {}];
  DeleteDuplicates[Select[letters, ! TrueQ[Quiet[Together[#1]] === 0] &]]
];

Options[multiquadraticStripCandidateLetters] = {
  "RegulatorSampleCount" -> 4,
  "RegulatorSamplePool" -> Automatic,
  "RowAlphabet" -> Automatic,
  "AdditionalLetters" -> {},
  "AlgebraicLetters" -> Automatic,
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2
};

(* The candidate one-form basis, rebuilt.  Five sources, each tagged:
     Diagonal      the scalar entries of e and c (closed forms, not dlogs)
     ForcingDLog   dlogs of the forcing entries at the CHOSEN samples
     RationalFactor dlogs of the strip's rational polar curves
     Algebraic     A +- Sqrt[delta], norm-filtered
     RowAlphabet   the installed alphabets of the row and column
     Supplied      whatever the caller adds
   Everything is filtered for membership in the strip's field, for
   regulator freedom, and (for the diagonal forms, which are not dlogs by
   construction) for closedness. *)
multiquadraticStripCandidateLetters[strip : {e_List, c_List, bbar_List},
    roots_List, variables : {x_, y_}, epsilon_Symbol, record_Association,
    opts : OptionsPattern[]] := Module[
  {samples, pool, sampleCount, alphabet, algebraic, rowLetters, additional,
   records = {}, keys = <||>, form, rootSquares, entries, diagonal,
   rowSource, add, counts, algebraicRecord},
  pool = Replace[OptionValue["RegulatorSamplePool"],
    Automatic :> $multiquadraticStripRegulatorSamplePool];
  sampleCount = OptionValue["RegulatorSampleCount"];
  If[! IntegerQ[sampleCount] || sampleCount < 1 || ! ListQ[pool] || pool === {},
    Return[multiquadraticStripFailure["InvalidRegulatorSampleRequest",
      <|"RegulatorSampleCount" -> sampleCount|>]]];
  samples = multiquadraticStripRegulatorSampleValues[bbar, variables, epsilon,
    sampleCount, pool];
  rootSquares = Lookup[roots, "RootSquare", {}];
  entries = Flatten[samples["SubstitutedEntries"]];
  alphabet = multiquadraticStripRationalPolarCurves[
    Join[entries, Flatten[e], Flatten[c]], rootSquares, variables];
  algebraic = Replace[OptionValue["AlgebraicLetters"],
    Automatic :> multiquadraticStripAlgebraicLetters[roots, alphabet, variables,
      "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
      "MaximumNormExponent" -> OptionValue["MaximumNormExponent"]]];
  If[! MatchQ[algebraic, {___Association}],
    algebraic = <|"Kind" -> "Algebraic", "Letter" -> #1,
      "Norm" -> Missing["NotDerived"]|> & /@ Flatten[{algebraic}]];
  rowSource = Replace[OptionValue["RowAlphabet"],
    Automatic :> multiquadraticStripRowAlphabetLetters[
      Replace[Lookup[record, "StripSolvers", {}], Except[_List] :> {}],
      Lookup[record, "Sector", None], Lookup[record, "LowerSector", None]]];
  rowLetters = Flatten[{rowSource}];
  additional = Flatten[{OptionValue["AdditionalLetters"]}];
  (* accumulate, in a fixed order, with a text key per one-form *)
  add[kind_String, letter_, oneForm_, extra_Association] := Module[{fkey},
    If[oneForm === $Failed || ! MatchQ[oneForm, {_, _}], Return[Null]];
    If[multiquadraticStripZeroQ[oneForm], Return[Null]];
    If[! FreeQ[oneForm, _Symbol?(StringStartsQ[SymbolName[#1], "eps"] &)],
      Return[Null]];
    If[! multiquadraticStripFieldMemberQ[oneForm[[1]], roots] ||
        ! multiquadraticStripFieldMemberQ[oneForm[[2]], roots], Return[Null]];
    fkey = multiquadraticStripFormTextKey[oneForm, variables, epsilon];
    If[KeyExistsQ[keys, fkey], Return[Null]];
    AssociateTo[keys, fkey -> True];
    (* THE dlog CERTIFICATE, minted at the one site that pairs a letter
       with the one-form computed from it.  A "Diagonal" record carries
       Missing["NotADLog"] as its letter and therefore no certificate: it
       is a closed form, not a dlog, and the compact route must refuse it
       -- which is exactly what an absent certificate makes it do. *)
    AppendTo[records, Join[<|"Kind" -> kind, "Letter" -> letter,
      "OneForm" -> oneForm, "FormKey" -> fkey,
      "DLogCertificate" -> If[MissingQ[letter], Missing["NotADLog"],
        multiquadraticStripLetterDLogCertificateWithKey[letter, fkey,
          variables, epsilon]]|>, extra]]];
  diagonal = multiquadraticScalarOneForms /@ {e, c};
  Do[
    If[! multiquadraticClosedOneFormQ[form, variables], Continue[]];
    add["Diagonal", Missing["NotADLog"], form, <||>],
    {form, Flatten[diagonal, 1]}];
  Do[
    If[TrueQ[Together[entry] === 0] ||
        FreeQ[entry, Alternatives @@ variables], Continue[]];
    add["ForcingDLog", entry,
      multiquadraticStripLetterOneForm[entry, variables], <||>],
    {entry, entries}];
  Do[add["RationalFactor", letter,
      multiquadraticStripLetterOneForm[letter, variables], <||>],
    {letter, alphabet}];
  Do[add["Algebraic", algebraicRecord["Letter"],
      multiquadraticStripLetterOneForm[algebraicRecord["Letter"], variables],
      KeyTake[algebraicRecord, {"A", "Norm", "RootSquare", "NormInAlphabet"}]],
    {algebraicRecord, algebraic}];
  Do[add["RowAlphabet", letter,
      multiquadraticStripLetterOneForm[letter, variables], <||>],
    {letter, rowLetters}];
  Do[add["Supplied", letter,
      multiquadraticStripLetterOneForm[letter, variables], <||>],
    {letter, additional}];
  counts = Association[Table[kind -> Count[records, item_ /;
      Lookup[item, "Kind", None] === kind],
    {kind, {"Diagonal", "ForcingDLog", "RationalFactor", "Algebraic",
      "RowAlphabet", "Supplied"}}]];
  <|"Status" -> "MultiquadraticCandidateLettersV1",
    "OneForms" -> Lookup[records, "OneForm", {}],
    "Letters" -> Lookup[records, "Letter", {}],
    "LetterRecords" -> records,
    "Alphabet" -> alphabet,
    "AlgebraicLetterRecords" -> Select[records,
      Lookup[#1, "Kind", None] === "Algebraic" &],
    "RegulatorValues" -> samples["Values"],
    "RejectedRegulatorValues" -> samples["RejectedValues"],
    "RegulatorSampleStatus" -> samples["Status"],
    "RowAlphabetLetterCount" -> Length[rowLetters],
    "Counts" -> counts,
    "DeduplicatedCount" -> Length[records]|>
];
multiquadraticStripCandidateLetters[___] :=
  multiquadraticStripFailure["InvalidCandidateLetterArguments"];

(* The gauge denominator factor contributed by algebraic letters.  A
   multiquadratic gauge written over a rational denominator acquires the
   NORMS of its algebraic letters, A^2 - B^2 delta, which
   multiquadraticRationalGaugeDenominator (a Max[0, p-1] rule on the
   forcing channels, dropping simple poles) can never produce.  Each
   distinct irreducible factor of the norms enters once, to the highest
   power it reaches in any single norm. *)
multiquadraticStripNormDenominatorFactor[letterRecords_List,
    variables_List] := Module[{norms, factorPairs, canonicalPairs, factors},
  norms = DeleteCases[Lookup[#1, "Norm", Missing["NoNorm"]] & /@
    Select[letterRecords, AssociationQ], _Missing];
  norms = Select[norms, ! TrueQ[Quiet[Together[#1]] === 0] &];
  If[norms === {}, Return[1]];
  factorPairs = Flatten[Map[Function[norm, Module[{list},
    list = Quiet[Rest[FactorList[Expand[Together[norm]]]]];
    If[! ListQ[list], {},
      Select[list, ! FreeQ[First[#1], Alternatives @@ variables] &]]]],
    norms], 1];
  If[factorPairs === {}, Return[1]];
  canonicalPairs = DeleteCases[
    {multiquadraticStripCanonicalFactor[First[#1], variables], Last[#1]} & /@
      factorPairs, {$Failed | 0, _}];
  If[canonicalPairs === {}, Return[1]];
  factors = DeleteDuplicates[canonicalPairs[[All, 1]],
    TrueQ[Together[#1 - #2] === 0] &];
  Times @@ Table[
    factor^Max[Cases[canonicalPairs,
      {candidate_, power_} /; TrueQ[Together[candidate - factor] === 0] :>
        power]],
    {factor, factors}]
];

(* The gauge denominator is a set of ADMITTED POLES with orders, not a
   product of two independent denominators: a factor that both the
   forcing rule and a norm ask for is admitted once, at the larger of the
   two orders.  Multiplying the two would double every shared factor --
   on CF300 (12,9) that is degree (11,12) instead of (9,9), an ansatz 56%
   wider for no pole the gauge can reach. *)
multiquadraticStripMergeGaugeDenominator[base_, extra_, variables_List] :=
  Module[{pairs, canonicalPairs, factors, constant, list},
  list[expression_] := Module[{factorList},
    factorList = Quiet[FactorList[Together[expression]]];
    If[! ListQ[factorList], {}, factorList]];
  pairs = Join[list[base], list[extra]];
  constant = Times @@ Cases[pairs,
    {value_ /; FreeQ[value, Alternatives @@ variables], power_} :>
      value^power];
  pairs = Select[pairs, ! FreeQ[First[#1], Alternatives @@ variables] &];
  If[pairs === {}, Return[Together[base]]];
  canonicalPairs = DeleteCases[
    {multiquadraticStripCanonicalFactor[First[#1], variables], Last[#1]} & /@
      pairs, {$Failed | 0, _}];
  If[canonicalPairs === {}, Return[Together[base]]];
  factors = DeleteDuplicates[canonicalPairs[[All, 1]],
    TrueQ[Together[#1 - #2] === 0] &];
  Times @@ Table[
    factor^Max[Cases[canonicalPairs,
      {candidate_, power_} /; TrueQ[Together[candidate - factor] === 0] :>
        power]],
    {factor, factors}]
];

(* ------------------------------------------------------------------ *)
(* The residue-only integrability screen                                *)
(* ------------------------------------------------------------------ *)

(* Cross-differentiating the strip equation
     d_mu G = eps (e_mu G - G c_mu) + bbar_mu - eps Sum_a R_a w_{a,mu}
   and using dw_a = 0 gives, exactly,
     eps F_e G - eps G F_c + Cbbar
       = eps^2 Sum_a [ (w_{a,y} e_x - w_{a,x} e_y) R_a
                     + R_a (w_{a,x} c_y - w_{a,y} c_x) ] ,
     Cbbar = (d_y bbar_x - d_x bbar_y)
             + eps (e_x bbar_y - e_y bbar_x + bbar_x c_y - bbar_y c_x),
     F_e   = d_y e_x - d_x e_y + eps [e_x, e_y]   (F_c likewise).
   When the diagonal connections are flat -- F_e = F_c = 0, MEASURED at
   every sampled point, never assumed -- the gauge G drops out entirely
   and what is left is a LINEAR system in the constant residues alone.
   Its consistency is a necessary condition on the alphabet and it costs
   only point evaluations of e, c, bbar and their first derivatives: no
   channel decomposition, no compilation, no gauge ansatz.  If the
   measurement says a diagonal connection is not flat the screen does not
   apply and the caller falls back to the full condition, i.e. to the
   gauge system, which carries the G-dependent terms.

   Derivatives are taken by the chain rule on the COMPILED form, never
   symbolically: each scalar becomes exponent/coefficient tables over
   (x, y, r_1..r_r) modulo one prime, and
     d/dx = partial_x + Sum_a partial_{r_a} (delta_a)_x / (2 r_a).      *)

multiquadraticStripScreenCompilePolynomial[polynomial_, allVariables_List,
    prime_Integer] := Module[{expanded, rules, coefficients, exponents},
  expanded = Quiet[Expand[polynomial]];
  If[! PolynomialQ[expanded, allVariables], Return[$Failed]];
  rules = CoefficientRules[expanded, allVariables];
  If[rules === {},
    Return[<|"Exponents" -> {}, "Coefficients" -> {},
      "MaximumExponents" -> ConstantArray[0, Length[allVariables]]|>]];
  coefficients = multiquadraticStripModRational[#1, prime] & /@ (Last /@ rules);
  If[MemberQ[coefficients, $Failed], Return[$Failed]];
  exponents = First /@ rules;
  <|"Exponents" -> Developer`ToPackedArray[exponents],
    "Coefficients" -> Developer`ToPackedArray[coefficients],
    "MaximumExponents" -> Max /@ Transpose[exponents]|>
];

multiquadraticStripScreenCompileScalar[expression_, roots_List,
    rootSymbols_List, variables_List, prime_Integer] := Module[
  {replaced, rational, numerator, denominator, allVariables},
  If[expression === $Failed, Return[$Failed]];
  allVariables = Join[variables, rootSymbols];
  replaced = If[roots === {}, expression,
    Quiet[transportChartApplyRootBranches[expression, roots, rootSymbols]]];
  If[replaced === $Failed, Return[$Failed]];
  If[! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Quiet[Together[replaced]];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
      ! FreeQ[rational, DirectedInfinity | Indeterminate], Return[$Failed]];
  numerator = multiquadraticStripScreenCompilePolynomial[Numerator[rational],
    allVariables, prime];
  denominator = multiquadraticStripScreenCompilePolynomial[
    Denominator[rational], allVariables, prime];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "MaximumExponents" -> MapThread[Max,
      {numerator["MaximumExponents"], denominator["MaximumExponents"]}]|>
];

(* value and the partial derivative with respect to EVERY compiled
   variable, at one point; every variable value is invertible there,
   which the point acceptance guarantees *)
multiquadraticStripScreenEvaluatePolynomial[compiled_Association,
    powerTables_List, inverses_List, prime_Integer] := Module[
  {exponents = compiled["Exponents"], coefficients = compiled["Coefficients"],
   count = Length[inverses], monomials},
  If[coefficients === {}, Return[{0, ConstantArray[0, count]}]];
  monomials = Fold[
    Function[{accumulated, index},
      Mod[accumulated powerTables[[index]][[exponents[[All, index]] + 1]],
        prime]],
    ConstantArray[1, Length[coefficients]], Range[count]];
  {Mod[coefficients . monomials, prime],
   Table[Mod[inverses[[index]] (
     (coefficients exponents[[All, index]]) . monomials), prime],
    {index, count}]}
];

multiquadraticStripScreenEvaluateRational[compiled_Association,
    powerTables_List, inverses_List, prime_Integer] := Module[
  {numeratorPair, denominatorPair, inverse, value},
  numeratorPair = multiquadraticStripScreenEvaluatePolynomial[
    compiled["Numerator"], powerTables, inverses, prime];
  denominatorPair = multiquadraticStripScreenEvaluatePolynomial[
    compiled["Denominator"], powerTables, inverses, prime];
  If[First[denominatorPair] === 0, Return[$Failed]];
  inverse = PowerMod[First[denominatorPair], -1, prime];
  value = Mod[First[numeratorPair] inverse, prime];
  {value, Mod[(Last[numeratorPair] - value Last[denominatorPair]) inverse,
    prime]}
];

multiquadraticStripScreenPowerTables[values_List, maximumExponents_List,
    prime_Integer] := Table[
  FoldList[Mod[#1 values[[index]], prime] &, 1,
    Range[Max[1, maximumExponents[[index]]]]],
  {index, Length[values]}];

(* ------------------------------------------------------------------ *)
(* Screen admission, phase telemetry and compiled-form reuse           *)
(* (Codex 04:30 P1: "the default-on dense screen needs a size/byte gate *)
(* and its own deadline")                                              *)
(* ------------------------------------------------------------------ *)

(* Both screens size a nearly square dense system and hand it to modular
   MatrixRank / NullSpace.  Measured scaling on CF300 (12,9): 43-47 s at
   1816 unknowns, 86-98 s at 2920-3128, 149 s at 3816.  A wider block or
   a larger support turns a default-on "cheap gate" into a dense-memory
   cliff, so the size is ESTIMATED BEFORE ANY ALLOCATION and compared
   against configurable ceilings; over the ceiling the screen returns a
   typed not-applicable result and the established route continues
   unscreened, which is exactly what a gate must do when it cannot
   afford to run. *)
$multiquadraticStripScreenMaximumUnknowns = 20000;
$multiquadraticStripScreenMaximumBytes = 4. 10^9;

multiquadraticStripScreenSizeEstimate[rowCount_, columnCount_,
    candidateColumnCount_ : 0] := Module[{total = columnCount + candidateColumnCount},
  <|"Rows" -> rowCount, "Columns" -> columnCount,
    "CandidateColumns" -> candidateColumnCount,
    "TotalColumns" -> total,
    (* one machine integer per entry of the packed matrix, plus the
       augmented column and one transposed copy for the left null space *)
    "PackedBytes" -> 8. rowCount (total + 1) 2|>];

multiquadraticStripScreenAdmissionRefusal[estimate_Association,
    maximumUnknowns_, maximumBytes_, status_String] := Which[
  IntegerQ[maximumUnknowns] && estimate["TotalColumns"] > maximumUnknowns,
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "UnknownCountCeilingExceeded", "SizeEstimate" -> estimate,
      "MaximumUnknowns" -> maximumUnknowns, "MaximumBytes" -> maximumBytes|>,
  NumericQ[maximumBytes] && estimate["PackedBytes"] > maximumBytes,
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ByteCeilingExceeded", "SizeEstimate" -> estimate,
      "MaximumUnknowns" -> maximumUnknowns, "MaximumBytes" -> maximumBytes|>,
  True, None];

(* Compiled scalar forms are reused across the images of a confirmation
   pair and across the rungs of the degree-offset ladder (Codex 04:30 P1,
   point 4).  A rung changes only the gauge support and denominator: the
   compiled e, c, bbar and root squares are identical, and before this
   cache every rung recompiled all of them for every image.  The key is
   the exact (expression, roots, variables, prime) the compile depends on;
   the cache is byte-bounded and reports hits/misses, so it can never
   become the memory problem the screen ceilings exist to prevent. *)
$multiquadraticStripScreenCompileCache = <||>;
$multiquadraticStripScreenCompileCacheBytes = 0;
$multiquadraticStripScreenCompileCacheLimit = 2. 10^8;
$multiquadraticStripScreenCompileStatistics =
  <|"Hits" -> 0, "Misses" -> 0, "Evictions" -> 0, "Bytes" -> 0|>;

multiquadraticStripScreenCompileCacheClear[] := (
  $multiquadraticStripScreenCompileCache = <||>;
  $multiquadraticStripScreenCompileCacheBytes = 0;
  $multiquadraticStripScreenCompileStatistics =
    <|"Hits" -> 0, "Misses" -> 0, "Evictions" -> 0, "Bytes" -> 0|>);

multiquadraticStripScreenCompileCached[expression_, roots_List,
    rootSymbols_List, variables_List, prime_Integer] := Module[
  {key, value, bytes},
  key = {Hash[{expression, Lookup[roots, "RootSquare", {}], rootSymbols,
    variables, prime}, "SHA256"]};
  If[KeyExistsQ[$multiquadraticStripScreenCompileCache, key],
    $multiquadraticStripScreenCompileStatistics["Hits"] =
      $multiquadraticStripScreenCompileStatistics["Hits"] + 1;
    Return[$multiquadraticStripScreenCompileCache[key]]];
  value = multiquadraticStripScreenCompileScalar[expression, roots,
    rootSymbols, variables, prime];
  $multiquadraticStripScreenCompileStatistics["Misses"] =
    $multiquadraticStripScreenCompileStatistics["Misses"] + 1;
  bytes = ByteCount[value];
  If[$multiquadraticStripScreenCompileCacheBytes + bytes >
      $multiquadraticStripScreenCompileCacheLimit,
    $multiquadraticStripScreenCompileStatistics["Evictions"] =
      $multiquadraticStripScreenCompileStatistics["Evictions"] +
        Length[$multiquadraticStripScreenCompileCache];
    $multiquadraticStripScreenCompileCache = <||>;
    $multiquadraticStripScreenCompileCacheBytes = 0];
  $multiquadraticStripScreenCompileCache[key] = value;
  $multiquadraticStripScreenCompileCacheBytes =
    $multiquadraticStripScreenCompileCacheBytes + bytes;
  $multiquadraticStripScreenCompileStatistics["Bytes"] =
    $multiquadraticStripScreenCompileCacheBytes;
  value
];

Options[multiquadraticStripIntegrabilityScreen] = {
  "Prime" -> Automatic,
  "RegulatorValue" -> Automatic,
  "PointCount" -> 20,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082401,
  "ScoreLetters" -> True,
  "Deadline" -> Infinity,
  "MaximumUnknowns" -> Automatic,
  "MaximumBytes" -> Automatic,
  (* the byte ceiling of the shared compiled-scalar cache, as an OPTION
     rather than a dynamic global: a per-call ceiling belongs to the
     call (2026-08-25).  Automatic is the module constant. *)
  "CompileCacheBytes" -> Automatic
};

multiquadraticStripIntegrabilityScreen[record_Association, roots_List,
    letterRecords_List, opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, strip, e, c, bbar, upper, lower, rank, prime,
   regulatorValue, epsilonMod, pointCount, maximumAttempts, randomSeed,
   rootOne, rootTwo, rootThree, rootSymbols, compileScalar, deltaCompiled,
   eCompiled, cCompiled, bCompiled, letterCompiled, maximumExponents,
   letterCount, unknownCount, rows = {}, right = {}, accepted = {},
   rejected = <||>, attempts = 0, point, probeTables, probeInverses,
   deltaValues, rootValues, pointRows, pointRight, pointOK, notFlat = False,
   values, inverses, powerTables, rootDerivatives, evaluate, matrixValue,
   matrixDerivative, ex, ey, cx, cy, bx, by, dyex, dxey, dycx, dxcy, dybx,
   dxby, curvatureE, curvatureC, forcingCurl, oneFormValues, matrix,
   rightVector, rankA, rankAugmented, defect, witness, nullVectors, scored,
   keptColumns, screenStatus, rationalLeaves,
   deadline, maximumUnknowns, maximumBytes, sizeEstimate, refusal,
   lettersCompiled = 0, letterIndex, compileCacheBytes,
   startTime = AbsoluteTime[], phaseTimings = <||>, compileSeconds,
   assemblySeconds, rankSeconds, leftNullSeconds = 0., expired = False,
   compileStatisticsBefore},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripIntegrabilityScreen]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline|>]]];
  maximumUnknowns = Replace[OptionValue["MaximumUnknowns"],
    Automatic :> $multiquadraticStripScreenMaximumUnknowns];
  maximumBytes = Replace[OptionValue["MaximumBytes"],
    Automatic :> $multiquadraticStripScreenMaximumBytes];
  compileCacheBytes = Replace[OptionValue["CompileCacheBytes"],
    Automatic :> $multiquadraticStripScreenCompileCacheLimit];
  If[! (NumericQ[compileCacheBytes] && compileCacheBytes > 0),
    Return[multiquadraticStripFailure["InvalidScreenCompileCacheBytes",
      <|"CompileCacheBytes" -> compileCacheBytes|>]]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  {e, c, bbar} = strip;
  If[! MatchQ[Dimensions[bbar], {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  {upper, lower} = Dimensions[bbar[[1]]];
  rank = Length[roots];
  If[rank > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank"]]];
  prime = Replace[OptionValue["Prime"],
    Automatic :> First[$multiquadraticStripDefaultPrimes]];
  regulatorValue = Replace[OptionValue["RegulatorValue"],
    Automatic :> First[$multiquadraticStripDefaultRegulatorValues]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount + 40];
  randomSeed = OptionValue["RandomSeed"];
  If[! PrimeQ[prime] || ! (3 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
      ! MatchQ[regulatorValue, _Integer | _Rational] ||
      ! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[randomSeed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount,
    Return[multiquadraticStripFailure["InvalidIntegrabilityScreenInput",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue,
        "PointCount" -> pointCount|>]]];
  epsilonMod = multiquadraticStripModRational[regulatorValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue|>]]];
  letterCount = Length[letterRecords];
  If[letterCount < 1, Return[multiquadraticStripFailure["EmptyAlphabet"]]];
  (* the admission gate, BEFORE any allocation or compile: rows are
     2^rank equations per accepted point times the two one-form
     components times the block entries, columns are the residue
     unknowns *)
  sizeEstimate = multiquadraticStripScreenSizeEstimate[
    pointCount 2^rank upper lower, letterCount upper lower];
  refusal = multiquadraticStripScreenAdmissionRefusal[sizeEstimate,
    maximumUnknowns, maximumBytes, "IntegrabilityScreenNotApplicable"];
  If[AssociationQ[refusal],
    Return[Join[refusal, <|"Prime" -> prime,
      "RegulatorValue" -> regulatorValue, "LetterCount" -> letterCount,
      "Seconds" -> AbsoluteTime[] - startTime|>]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:Compile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate|>]]];
  rootSymbols = Take[{rootOne, rootTwo, rootThree}, rank];
  compileScalar[expression_] := multiquadraticStripScreenCompileCached[
    Quiet[Check[Together[expression /. epsilon -> regulatorValue], $Failed,
      {Power::infy, Infinity::indet, Power::indet}]],
    roots, rootSymbols, variables, prime];
  compileStatisticsBefore = $multiquadraticStripScreenCompileStatistics;
  (* INTERIOR BOUNDARIES of the compile phase (2026-08-25): the letter,
     and the three diagonal/forcing tensors.  See the identical note in
     multiquadraticStripGaugeScreen. *)
  lettersCompiled = 0;
  compileSeconds = First[AbsoluteTiming[
   Block[{$multiquadraticStripScreenCompileCacheLimit = compileCacheBytes},
    deltaCompiled = multiquadraticStripScreenCompileCached[#1, {}, rootSymbols,
        variables, prime] & /@ Lookup[roots, "RootSquare", {}];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    eCompiled = If[expired, {}, Map[compileScalar, e, {3}]];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    cCompiled = If[expired, {}, Map[compileScalar, c, {3}]];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    bCompiled = If[expired, {}, Map[compileScalar, bbar, {3}]];
    letterCompiled = With[
      {forms = Lookup[letterRecords, "OneForm", {}]},
      Table[
        If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
          expired = True; {},
          lettersCompiled++; compileScalar /@ forms[[letterIndex]]],
        {letterIndex, Length[forms]}]];]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:LetterCompile", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "LettersCompiled" -> lettersCompiled, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  If[! FreeQ[{deltaCompiled, eCompiled, cCompiled, bCompiled, letterCompiled},
      $Failed],
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ScreenCompilationFailed", "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:PointAssembly", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  rationalLeaves = Cases[{deltaCompiled, eCompiled, cCompiled, bCompiled,
      letterCompiled}, association_Association /;
      KeyExistsQ[association, "Numerator"] :> association, {0, Infinity}];
  maximumExponents = Max /@ Transpose[
    Lookup[rationalLeaves, "MaximumExponents"]];
  assemblySeconds = First[AbsoluteTiming[
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts &&
        ! notFlat && ! expired,
      (* cooperative stop during point acquisition: every accepted point
         is one 2^rank-branch evaluation of the whole block *)
      If[multiquadraticStripDeadlineExpiredQ[deadline],
        expired = True; Break[]];
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      (* the root squares first: the point must split every declared root *)
      probeTables = multiquadraticStripScreenPowerTables[
        Join[point, ConstantArray[1, rank]], maximumExponents, prime];
      probeInverses = Join[PowerMod[point, -1, prime], ConstantArray[1, rank]];
      deltaValues = Table[
        Module[{pair = multiquadraticStripScreenEvaluateRational[
           deltaCompiled[[a]], probeTables, probeInverses, prime]},
         If[pair === $Failed, $Failed, First[pair]]], {a, rank}];
      If[MemberQ[deltaValues, $Failed] || MemberQ[deltaValues, 0] ||
          ! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
        rejected["NotSplitOverPrime"] =
          Lookup[rejected, "NotSplitOverPrime", 0] + 1;
        Continue[]];
      rootValues = PowerMod[deltaValues, (prime + 1)/4, prime];
      If[! AllTrue[Range[rank],
          Mod[rootValues[[#1]]^2 - deltaValues[[#1]], prime] === 0 &],
        rejected["RootImageNotARoot"] =
          Lookup[rejected, "RootImageNotARoot", 0] + 1;
        Continue[]];
      pointRows = {}; pointRight = {}; pointOK = True;
      Do[
        values = Join[point, Table[
          Mod[If[BitGet[mask, a - 1] === 1, -1, 1] rootValues[[a]], prime],
          {a, rank}]];
        If[MemberQ[values, 0], pointOK = False; Break[]];
        inverses = PowerMod[values, -1, prime];
        powerTables = multiquadraticStripScreenPowerTables[values,
          maximumExponents, prime];
        rootDerivatives = Table[
          Module[{pair = multiquadraticStripScreenEvaluateRational[
             deltaCompiled[[a]], powerTables, inverses, prime], half},
           If[pair === $Failed, ConstantArray[0, 2],
             half = PowerMod[Mod[2 values[[2 + a]], prime], -1, prime];
             Mod[half Last[pair][[1 ;; 2]], prime]]],
          {a, rank}];
        evaluate[compiled_] := Module[{pair},
          pair = multiquadraticStripScreenEvaluateRational[compiled,
            powerTables, inverses, prime];
          If[pair === $Failed, Throw[$Failed, "MultiquadraticScreenPoint"]];
          {First[pair], Table[Mod[Last[pair][[mu]] +
             Sum[Last[pair][[2 + a]] rootDerivatives[[a, mu]], {a, rank}],
             prime], {mu, 2}]}];
        matrixValue[block_] := Map[First[evaluate[#1]] &, block, {2}];
        matrixDerivative[block_, mu_] :=
          Map[Last[evaluate[#1]][[mu]] &, block, {2}];
        If[Catch[
            ex = matrixValue[eCompiled[[1]]]; ey = matrixValue[eCompiled[[2]]];
            cx = matrixValue[cCompiled[[1]]]; cy = matrixValue[cCompiled[[2]]];
            bx = matrixValue[bCompiled[[1]]]; by = matrixValue[bCompiled[[2]]];
            dyex = matrixDerivative[eCompiled[[1]], 2];
            dxey = matrixDerivative[eCompiled[[2]], 1];
            dycx = matrixDerivative[cCompiled[[1]], 2];
            dxcy = matrixDerivative[cCompiled[[2]], 1];
            dybx = matrixDerivative[bCompiled[[1]], 2];
            dxby = matrixDerivative[bCompiled[[2]], 1];
            oneFormValues = Table[
              {First[evaluate[letterCompiled[[k, 1]]]],
               First[evaluate[letterCompiled[[k, 2]]]]}, {k, letterCount}];
            True, "MultiquadraticScreenPoint"] =!= True,
          pointOK = False; Break[]];
        curvatureE = Mod[dyex - dxey + epsilonMod (ex . ey - ey . ex), prime];
        curvatureC = Mod[dycx - dxcy + epsilonMod (cx . cy - cy . cx), prime];
        If[! (AllTrue[Flatten[curvatureE], #1 === 0 &] &&
            AllTrue[Flatten[curvatureC], #1 === 0 &]),
          notFlat = True; pointOK = False; Break[]];
        forcingCurl = Mod[dybx - dxby +
          epsilonMod (ex . by - ey . bx + bx . cy - by . cx), prime];
        Do[
          AppendTo[pointRight, forcingCurl[[i, j]]];
          AppendTo[pointRows, Developer`ToPackedArray[Flatten[Table[
            Mod[Mod[epsilonMod^2, prime] Mod[
              If[vv === j, Mod[oneFormValues[[k, 2]] ex[[i, uu]] -
                oneFormValues[[k, 1]] ey[[i, uu]], prime], 0] +
              If[uu === i, Mod[oneFormValues[[k, 1]] cy[[vv, j]] -
                oneFormValues[[k, 2]] cx[[vv, j]], prime], 0], prime], prime],
            {k, letterCount}, {uu, upper}, {vv, lower}]]]],
          {i, upper}, {j, lower}],
        {mask, 0, 2^rank - 1}];
      If[TrueQ[pointOK],
        AppendTo[accepted, point];
        rows = Join[rows, pointRows]; right = Join[right, pointRight],
        rejected["Unusable"] = Lookup[rejected, "Unusable", 0] + 1]]]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:PointAssembly", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "PointCount" -> Length[accepted], "AttemptCount" -> attempts,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  If[TrueQ[notFlat],
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "DiagonalConnectionsNotFlat",
      "FlatDiagonalConnections" -> False, "Prime" -> prime,
      "RegulatorValue" -> regulatorValue, "AttemptCount" -> attempts|>]];
  If[Length[accepted] < 1 || rows === {},
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "NoAdmissiblePoints", "AttemptCount" -> attempts,
      "RejectedPoints" -> rejected, "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  unknownCount = letterCount upper lower;
  matrix = Developer`ToPackedArray[rows];
  rightVector = Developer`ToPackedArray[right];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:Rank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  rankSeconds = First[AbsoluteTiming[
    rankA = MatrixRank[matrix, Modulus -> prime];
    rankAugmented = MatrixRank[MapThread[Append, {matrix, rightVector}],
      Modulus -> prime];]];
  defect = rankAugmented - rankA;
  (* POST-RANK BOUNDARY (2026-08-25): the verdict is paid for, and the
     left null space plus one MatrixRank per letter below is a second
     expensive block.  The stop carries the rank pair it measured. *)
  If[(defect > 0 || (TrueQ[OptionValue["ScoreLetters"]] && letterCount > 1)) &&
      multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:PostRank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "Defect" -> defect, "Rank" -> rankA,
        "AugmentedRank" -> rankAugmented, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds|>|>]]];
  witness = Missing["Consistent"];
  If[defect > 0,
    leftNullSeconds = First[AbsoluteTiming[
      nullVectors = NullSpace[Transpose[matrix], Modulus -> prime];]];
    witness = SelectFirst[nullVectors, Mod[#1 . rightVector, prime] =!= 0 &,
      Missing["NoWitnessFound"]];
    If[! MissingQ[witness],
      witness = <|"Prime" -> prime, "Vector" -> witness,
        "TransposeResidualZero" ->
          AllTrue[Mod[witness . matrix, prime], #1 === 0 &],
        "RightHandSidePairing" -> Mod[witness . rightVector, prime],
        "Support" -> Count[witness, _?(#1 =!= 0 &)]|>]];
  scored = If[TrueQ[OptionValue["ScoreLetters"]] && letterCount > 1,
    Table[
      keptColumns = Complement[Range[unknownCount],
        Range[(k - 1) upper lower + 1, k upper lower]];
      <|"Index" -> k, "Kind" -> Lookup[letterRecords[[k]], "Kind", None],
        "Letter" -> Lookup[letterRecords[[k]], "Letter", Missing["NoLetter"]],
        "RankContribution" ->
          rankA - MatrixRank[matrix[[All, keptColumns]], Modulus -> prime]|>,
      {k, letterCount}], {}];
  (* ONE IMAGE.  These statuses are the per-image verdict and keep their
     names; a CONFIRMED verdict over two independent (prime, regulator)
     images is what multiquadraticStripIntegrabilityScreenImages returns
     and what the top level is allowed to act on (Codex 04:30 P1). *)
  screenStatus = If[defect > 0, "AlphabetIntegrabilityObstruction",
    "AlphabetIntegrabilityConsistent"];
  phaseTimings = <|"Compile" -> compileSeconds,
    "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds,
    "LeftNullSpace" -> leftNullSeconds|>;
  <|"Status" -> screenStatus, "Module" -> "MultiquadraticStripSolve",
    "Method" -> "ResidueOnlyIntegrability",
    "SizeEstimate" -> sizeEstimate, "PhaseTimings" -> phaseTimings,
    "CompileCache" -> Join[
      AssociationMap[($multiquadraticStripScreenCompileStatistics[#1] -
        compileStatisticsBefore[#1]) &, {"Hits", "Misses", "Evictions"}],
      <|"Bytes" -> $multiquadraticStripScreenCompileCacheBytes|>],
    "Seconds" -> AbsoluteTime[] - startTime,
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Defect" -> defect, "Rank" -> rankA, "AugmentedRank" -> rankAugmented,
    "Nullity" -> unknownCount - rankA,
    "MatrixDimensions" -> Dimensions[matrix],
    "UnknownCount" -> unknownCount, "LetterCount" -> letterCount,
    "Prime" -> prime, "RegulatorValue" -> regulatorValue,
    "PointCount" -> Length[accepted], "AcceptedPoints" -> accepted,
    "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
    "FlatDiagonalConnections" -> True, "Witness" -> witness,
    "ScoredLetters" -> scored,
    "Alphabet" -> Lookup[letterRecords, "Letter", {}],
    "LetterKinds" -> Lookup[letterRecords, "Kind", {}]|>
];
multiquadraticStripIntegrabilityScreen[___] :=
  multiquadraticStripFailure["InvalidIntegrabilityScreenArguments"];

(* ------------------------------------------------------------------ *)
(* TWO INDEPENDENT IMAGES ON THE REJECTION PATH ONLY                    *)
(* (Codex 04:30 P1: "a single regulator image is not an exact generic  *)
(*  Q(eps) obstruction")                                                *)
(* ------------------------------------------------------------------ *)

(* A rank defect of the specialized finite-field system is EXACT for that
   system, and it is NOT a theorem about the generic system over Q(eps):
   a generically solvable system such as (eps - a) z = 1 is inconsistent
   at eps = a, and more (x, y) points AT THE SAME REGULATOR VALUE cannot
   remove that exceptional-regulator mode.  Nor is a solution denominator
   known in advance from the input-pole census.
   So: the fast single-image CONSISTENCY path is kept exactly as it was
   -- a consistent image gates nothing and is not made more consistent by
   a second one -- and only a REJECTION is confirmed at a second
   independent (prime, regulator) image, precisely as the full-gauge
   screen already does.  Two agreeing images make the verdict a
   HIGH-CONFIDENCE MODULAR OBSTRUCTION, which is what the caller may act
   on; it is still not an unconditional theorem over Q(eps), and the
   status language and the solution contract say so. *)
Options[multiquadraticStripIntegrabilityScreenImages] = Join[
  Options[multiquadraticStripIntegrabilityScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True
}];

multiquadraticStripIntegrabilityScreenImages[record_Association, roots_List,
    letterRecords_List, opts : OptionsPattern[]] := Module[
  {gate, images, firstPrime, firstRegulator, results = {}, screenOptions,
   result, defects, status, startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripIntegrabilityScreenImages]]]];
  If[AssociationQ[gate], Return[gate]];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}],
    Return[multiquadraticStripFailure["InvalidIntegrabilityScreenImages",
      <|"Images" -> images|>]]];
  (* an explicitly requested prime / regulator value IS the first image:
     the caller's choice (the alphabet's own first regulator sample) must
     stay the one that decides the fast path *)
  firstPrime = OptionValue["Prime"];
  firstRegulator = OptionValue["RegulatorValue"];
  images = ReplacePart[images, 1 -> {
    Replace[firstPrime, Automatic :> images[[1, 1]]],
    Replace[firstRegulator, Automatic :> images[[1, 2]]]}];
  (* two identical images are one image, not two confirmations *)
  images = DeleteDuplicates[images];
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["Prime" -> _] | HoldPattern["RegulatorValue" -> _] |
      HoldPattern["RandomSeed" -> _]],
    Options[multiquadraticStripIntegrabilityScreen]];
  Do[
    result = multiquadraticStripIntegrabilityScreen[record, roots,
      letterRecords, "Prime" -> images[[k, 1]],
      "RegulatorValue" -> images[[k, 2]],
      "RandomSeed" -> OptionValue["RandomSeed"] + 7919 k,
      Sequence @@ screenOptions];
    AppendTo[results, result];
    If[! MemberQ[{"AlphabetIntegrabilityObstruction",
        "AlphabetIntegrabilityConsistent"}, Lookup[result, "Status", None]],
      Break[]];
    (* the fast path: a consistent image ends the screen *)
    If[Lookup[result, "Defect", 1] === 0, Break[]];
    If[! TrueQ[OptionValue["ConfirmObstruction"]], Break[]],
    {k, Length[images]}];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  status = Which[
    ! AllTrue[results, MemberQ[{"AlphabetIntegrabilityObstruction",
      "AlphabetIntegrabilityConsistent"}, Lookup[#1, "Status", None]] &],
      (* a not-applicable / budget-exhausted image is not a verdict *)
      Lookup[Last[results], "Status", "IntegrabilityScreenNotApplicable"],
    (* ANY consistent image settles it: that image exhibits a solution of
       the specialized system, so the generic system is solvable and a
       defect at another image was an exceptional regulator value, not an
       obstruction.  The exceptional images are recorded, never acted
       on. *)
    AnyTrue[defects, IntegerQ[#1] && #1 === 0 &],
      "AlphabetIntegrabilityConsistent",
    Length[results] >= 2 && AllTrue[defects, IntegerQ[#1] && #1 > 0 &],
      "AlphabetIntegrabilityObstruction",
    True, "AlphabetIntegrabilityObstructionUnconfirmed"];
  Join[
    (* the deciding image's own payload travels on, so witnesses,
       scored letters and phase timings are not lost by the wrapper *)
    KeyDrop[Last[results], {"Status", "Seconds"}],
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Method" -> "ResidueOnlyIntegrability",
      "Confirmed" -> (status === "AlphabetIntegrabilityObstruction"),
      (* the images whose defect was NOT reproduced: an exceptional
         regulator value of an otherwise solvable system, kept as
         evidence and never acted on *)
      "ExceptionalRegulatorImages" ->
        If[status === "AlphabetIntegrabilityConsistent",
          Pick[Take[images, UpTo[Length[results]]],
            Map[IntegerQ[#1] && #1 > 0 &, defects]], {}],
      "ImageCount" -> Length[results], "Defects" -> defects,
      "Images" -> Take[images, UpTo[Length[results]]],
      "ImageResults" -> results,
      "PhaseTimings" -> Merge[
        Lookup[results, "PhaseTimings", <||>], Total],
      "Seconds" -> AbsoluteTime[] - startTime|>]
];
multiquadraticStripIntegrabilityScreenImages[___] :=
  multiquadraticStripFailure["InvalidIntegrabilityScreenArguments"];

(* ------------------------------------------------------------------ *)
(* The FULL-GAUGE per-image screen (2026-08-25)                         *)
(* ------------------------------------------------------------------ *)

(* The integrability screen above projects the gauge OUT: it certifies
   only that the alphabet can carry the residues.  Its consistency is
   necessary, not sufficient -- CF300 (12,9) is consistent there and
   still carries a defect in the full system.  This screen assembles the
   COMPLETE affine gauge system (gauge coefficients AND residues) at one
   (prime, eps) image by point evaluation, with no symbolic compile and
   no channel decomposition, and measures rank / augmented rank / defect
   / nullity plus a verified left witness.  Measured on CF300 (12,9):
   43 s at 1816 unknowns, 98 s at 3128.  The compile it screens is
   ~7900 s, so it is the cheap gate in front of it.

   Row (mu, i, j) at a split point, in the engine's own column order
   (multiquadraticStripColumnOrder: gauge {i,j,grade,monomial}, then
   residues {letter,i,j}):
     Sum_{i'j' grade mon} g[i',j',grade,mon] K + eps Sum_a R[a,i,j] w_a,mu
       = bbar_mu[i,j],
     K = [i'=i,j'=j] dB_mu - eps [j'=j] e_mu[i,i'] B
                            + eps [i'=i] c_mu[j',j] B,
     B = x^p y^q r_grade / Q.
   The rows are taken in the SIGN basis (2^r sign branches per split
   point), which is the invertible Hadamard image of the engine's grade
   rows; rank, defect and nullity are basis-independent, and the witness
   is reported in that same sign-row basis.

   CANDIDATE COLUMNS.  "CandidateOneForms" appends extra residue columns
   that are NOT part of the base system.  The base rank/defect/witness
   are measured on the base columns alone; each candidate is then scored
   against the witness (y . C != 0 is Codex's necessary condition) and
   the defect of an arbitrary SUBSET of candidates is read off the small
   pairing matrix L . [C | b], where L is a basis of the left null space
   of the base matrix.  One assembly therefore answers every subset
   question, which is what makes witness-guided letter discovery
   affordable. *)

Options[multiquadraticStripGaugeAnsatz] = {
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic
};

(* A minimal ansatz descriptor for the screen.  A full preparation
   record already satisfies the screen's contract; this builder exists so
   the screen can be run BEFORE (or without) a preparation, which is the
   whole point of a cheap gate: preparation decomposes the forcing into
   channels and costs ~10^3 s on the blocks this screen is for. *)
multiquadraticStripGaugeAnsatz[record_Association, roots_List,
    oneForms_List, gaugeDenominator_, opts : OptionsPattern[]] := Module[
  {gate, variables, strip, dimensions, degrees, degreeOffset, support},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeAnsatz]]]];
  If[AssociationQ[gate], Return[gate]];
  variables = Lookup[record, "Variables", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  If[TrueQ[Together[gaugeDenominator] === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1,
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  degrees = Exponent[Together[gaugeDenominator], #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset"]]];
  support = Replace[OptionValue["Support"], Automatic :>
    Flatten[Table[{i, j}, {i, 0, degrees[[1]] + degreeOffset[[1]]},
      {j, 0, degrees[[2]] + degreeOffset[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticStripFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  <|"Status" -> "MultiquadraticGaugeAnsatzV1",
    "Record" -> record, "Variables" -> variables,
    "Regulator" -> Lookup[record, "Regulator", $Failed],
    "Strip" -> strip, "Roots" -> roots, "RootCount" -> Length[roots],
    "OneForms" -> oneForms,
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> degrees,
    "GaugeSupport" -> support, "Dimensions" -> dimensions,
    "GradeCount" -> 2^Length[roots],
    "GaugeUnknownCount" ->
      (Times @@ dimensions) 2^Length[roots] Length[support],
    "ResidueUnknownCount" -> Length[oneForms] (Times @@ dimensions),
    "UnknownCount" -> (Times @@ dimensions) 2^Length[roots] Length[support] +
      Length[oneForms] (Times @@ dimensions)|>
];
multiquadraticStripGaugeAnsatz[___] :=
  multiquadraticStripFailure["InvalidGaugeAnsatzArguments"];

Options[multiquadraticStripGaugeScreen] = {
  "Prime" -> Automatic,
  "RegulatorValue" -> Automatic,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082501,
  "ExtraRowPoints" -> 1,
  "CandidateOneForms" -> {},
  "CandidateSubsets" -> Automatic,
  "LeftNullSpace" -> Automatic,
  "Deadline" -> Infinity,
  "MaximumUnknowns" -> Automatic,
  "MaximumBytes" -> Automatic,
  (* see the note at multiquadraticStripIntegrabilityScreen *)
  "CompileCacheBytes" -> Automatic
};

multiquadraticStripGaugeScreen[ansatz_Association, opts : OptionsPattern[]] :=
  Module[
  {gate, record, variables, epsilon, strip, e, c, bbar, roots, oneForms,
   gaugeDenominator, support, dimensions, upper, lower, rank, gradeCount,
   supportCount, letterCount, gaugeUnknownCount, residueUnknownCount,
   unknownCount, candidateForms, candidateCount, candidateWidth, prime,
   regulatorValue, epsilonMod, pointCount, maximumAttempts, randomSeed,
   equationsPerPoint, rootOne, rootTwo, rootThree, rootSymbols, compileScalar,
   deltaCompiled, eCompiled, cCompiled, bCompiled, formCompiled,
   candidateCompiled, denominatorCompiled, rationalLeaves, maximumExponents,
   rows = {}, right = {}, candidateRows = {}, accepted = 0, attempts = 0,
   rejected = <||>, point, probeTables, probeInverses, deltaValues, rootValues,
   pointOK, pointRows, pointRight, pointCandidate, values, inverses,
   powerTables, rootDerivatives, evaluate, denominatorPair, denominatorValue,
   denominatorInverse, denominatorLog, ex, ey, cx, cy, bx, by, formValues,
   candidateValues, monomialValues, gradeValues, gradeLog, basisValues,
   basisDerivatives, xInverse, yInverse, rowVector, matrix, candidateMatrix,
   rightVector, rankA, rankAugmented, defect, leftNull, witness, wanted,
   pairing, subsets, subsetResults, candidateScores, screenStatus, seconds,
   startTime = AbsoluteTime[], subsetDefect,
   deadline, maximumUnknowns, maximumBytes, sizeEstimate, refusal,
   phaseTimings = <||>, compileSeconds, assemblySeconds, rankSeconds,
   leftNullSeconds = 0., expired = False, compileStatisticsBefore,
   lettersCompiled = 0, letterIndex, candidateIndex, compileCacheBytes},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreen]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline|>]]];
  maximumUnknowns = Replace[OptionValue["MaximumUnknowns"],
    Automatic :> $multiquadraticStripScreenMaximumUnknowns];
  maximumBytes = Replace[OptionValue["MaximumBytes"],
    Automatic :> $multiquadraticStripScreenMaximumBytes];
  compileCacheBytes = Replace[OptionValue["CompileCacheBytes"],
    Automatic :> $multiquadraticStripScreenCompileCacheLimit];
  If[! (NumericQ[compileCacheBytes] && compileCacheBytes > 0),
    Return[multiquadraticStripFailure["InvalidScreenCompileCacheBytes",
      <|"CompileCacheBytes" -> compileCacheBytes|>]]];
  record = Lookup[ansatz, "Record", <||>];
  If[! AssociationQ[record], record = <||>];
  variables = Lookup[ansatz, "Variables", Lookup[record, "Variables", $Failed]];
  epsilon = Lookup[ansatz, "Regulator", Lookup[record, "Regulator", $Failed]];
  strip = Lookup[ansatz, "Strip", Lookup[record, "Strip", $Failed]];
  roots = Lookup[ansatz, "Roots", $Failed];
  oneForms = Lookup[ansatz, "OneForms", $Failed];
  gaugeDenominator = Lookup[ansatz, "GaugeDenominator", $Failed];
  support = Lookup[ansatz, "GaugeSupport", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] || ! ListQ[roots] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}] ||
      ! MatchQ[support, {{_Integer, _Integer} ..}] ||
      gaugeDenominator === $Failed,
    Return[multiquadraticStripFailure["InvalidGaugeAnsatz",
      <|"MissingKeys" -> Select[{"Variables", "Regulator", "Strip", "Roots",
          "OneForms", "GaugeDenominator", "GaugeSupport"},
        ! KeyExistsQ[ansatz, #1] &]|>]]];
  {e, c, bbar} = strip;
  If[! MatchQ[Dimensions[bbar], {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  {upper, lower} = Dimensions[bbar[[1]]];
  rank = Length[roots];
  If[rank > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank"]]];
  gradeCount = 2^rank;
  supportCount = Length[support];
  letterCount = Length[oneForms];
  candidateForms = Replace[OptionValue["CandidateOneForms"], Automatic :> {}];
  If[! MatchQ[candidateForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["InvalidCandidateOneForms"]]];
  candidateCount = Length[candidateForms];
  candidateWidth = upper lower;
  gaugeUnknownCount = upper lower gradeCount supportCount;
  residueUnknownCount = letterCount upper lower;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = 2 upper lower gradeCount;
  prime = Replace[OptionValue["Prime"],
    Automatic :> First[$multiquadraticStripDefaultPrimes]];
  regulatorValue = Replace[OptionValue["RegulatorValue"],
    Automatic :> First[$multiquadraticStripDefaultRegulatorValues]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Ceiling[(unknownCount +
      Max[1, OptionValue["ExtraRowPoints"]] equationsPerPoint)/
      equationsPerPoint]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 60 pointCount + 60];
  randomSeed = OptionValue["RandomSeed"];
  If[! PrimeQ[prime] || ! (3 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
      ! MatchQ[regulatorValue, _Integer | _Rational] ||
      ! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[randomSeed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount,
    Return[multiquadraticStripFailure["InvalidGaugeScreenInput",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue,
        "PointCount" -> pointCount|>]]];
  epsilonMod = multiquadraticStripModRational[regulatorValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue|>]]];
  (* the admission gate, BEFORE any allocation (Codex 04:30 P1).  The
     screen is DEFAULT ON, so its cost must be bounded by a declared
     ceiling rather than by the block that happens to arrive. *)
  sizeEstimate = multiquadraticStripScreenSizeEstimate[
    pointCount equationsPerPoint, unknownCount,
    candidateCount candidateWidth];
  refusal = multiquadraticStripScreenAdmissionRefusal[sizeEstimate,
    maximumUnknowns, maximumBytes, "GaugeScreenNotApplicable"];
  If[AssociationQ[refusal],
    Return[Join[refusal, <|"Prime" -> prime,
      "RegulatorValue" -> regulatorValue,
      "UnknownCount" -> unknownCount,
      "GaugeUnknownCount" -> gaugeUnknownCount,
      "ResidueUnknownCount" -> residueUnknownCount,
      "EquationsPerPoint" -> equationsPerPoint,
      "RequestedPointCount" -> pointCount,
      "Seconds" -> AbsoluteTime[] - startTime|>]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:Compile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate|>]]];
  (* a MARK, not a start: this function has six typed exits (three budget
     stops, two admission refusals, the result) and a "start" that only
     sometimes reaches a "done" is worse than no pair at all *)
  multiquadraticStripStageMark["gauge screen image",
    <|"prime" -> prime, "eps" -> regulatorValue,
      "unknowns" -> unknownCount, "points" -> pointCount,
      "rows" -> sizeEstimate["Rows"],
      "columns" -> sizeEstimate["TotalColumns"],
      "bytes" -> sizeEstimate["PackedBytes"]|>];
  rootSymbols = Take[{rootOne, rootTwo, rootThree}, rank];
  compileScalar[expression_] := multiquadraticStripScreenCompileCached[
    Quiet[Check[Together[expression /. epsilon -> regulatorValue], $Failed,
      {Power::infy, Infinity::indet, Power::indet}]],
    roots, rootSymbols, variables, prime];
  compileStatisticsBefore = $multiquadraticStripScreenCompileStatistics;
  (* INTERIOR BOUNDARIES of the compile phase (2026-08-25, Codex 14:30
     "screen interior boundaries").  Until today the screen read the
     deadline only BEFORE this phase and again after it: a 52-letter
     alphabet on a wide block spends minutes here and an expired budget
     could not stop between two letters.  The boundary is the LETTER
     (and the diagonal/forcing tensor), which is the finest one that
     exists without changing what is compiled -- one letter is one
     Together plus one modular polynomial compile and is not
     interruptible inside. *)
  lettersCompiled = 0;
  compileSeconds = First[AbsoluteTiming[
  Block[{$multiquadraticStripScreenCompileCacheLimit = compileCacheBytes},
  deltaCompiled = multiquadraticStripScreenCompileCached[#1, {}, rootSymbols,
      variables, prime] & /@ Lookup[roots, "RootSquare", {}];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  eCompiled = If[expired, {}, Map[compileScalar, e, {3}]];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  cCompiled = If[expired, {}, Map[compileScalar, c, {3}]];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  bCompiled = If[expired, {}, Map[compileScalar, bbar, {3}]];
  formCompiled = Table[
    If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
      expired = True; {},
      lettersCompiled++; compileScalar /@ oneForms[[letterIndex]]],
    {letterIndex, letterCount}];
  candidateCompiled = Table[
    If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
      expired = True; {},
      compileScalar /@ candidateForms[[candidateIndex]]],
    {candidateIndex, candidateCount}];
  denominatorCompiled = If[expired, $Failed,
    compileScalar[gaugeDenominator]];]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:LetterCompile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "LettersCompiled" -> lettersCompiled, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  If[! FreeQ[{deltaCompiled, eCompiled, cCompiled, bCompiled, formCompiled,
      candidateCompiled, denominatorCompiled}, $Failed],
    Return[<|"Status" -> "GaugeScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ScreenCompilationFailed", "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  rationalLeaves = Cases[{deltaCompiled, eCompiled, cCompiled, bCompiled,
      formCompiled, candidateCompiled, denominatorCompiled},
    association_Association /; KeyExistsQ[association, "Numerator"] :>
      association, {0, Infinity}];
  maximumExponents = Max /@ Transpose[
    Lookup[rationalLeaves, "MaximumExponents"]];
  maximumExponents[[1]] = Max[maximumExponents[[1]], Max[support[[All, 1]]]];
  maximumExponents[[2]] = Max[maximumExponents[[2]], Max[support[[All, 2]]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PointAssembly",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  assemblySeconds = First[AbsoluteTiming[
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[accepted < pointCount && attempts < maximumAttempts && ! expired,
      If[multiquadraticStripDeadlineExpiredQ[deadline],
        expired = True; Break[]];
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      probeTables = multiquadraticStripScreenPowerTables[
        Join[point, ConstantArray[1, rank]], maximumExponents, prime];
      probeInverses = Join[PowerMod[point, -1, prime], ConstantArray[1, rank]];
      deltaValues = Table[
        Module[{pair = multiquadraticStripScreenEvaluateRational[
           deltaCompiled[[a]], probeTables, probeInverses, prime]},
         If[pair === $Failed, $Failed, First[pair]]], {a, rank}];
      If[MemberQ[deltaValues, $Failed] || MemberQ[deltaValues, 0] ||
          ! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
        rejected["NotSplitOverPrime"] =
          Lookup[rejected, "NotSplitOverPrime", 0] + 1;
        Continue[]];
      rootValues = PowerMod[deltaValues, (prime + 1)/4, prime];
      If[! AllTrue[Range[rank],
          Mod[rootValues[[#1]]^2 - deltaValues[[#1]], prime] === 0 &],
        rejected["RootImageNotARoot"] =
          Lookup[rejected, "RootImageNotARoot", 0] + 1;
        Continue[]];
      pointOK = True; pointRows = {}; pointRight = {}; pointCandidate = {};
      (* the 2^r sign branches of this point are the invertible image of
         the grade rows: all of them, or none *)
      Do[
        values = Join[point, Table[
          Mod[If[BitGet[signMask, a - 1] === 1, -1, 1] rootValues[[a]], prime],
          {a, rank}]];
        If[MemberQ[values, 0], pointOK = False; Break[]];
        inverses = PowerMod[values, -1, prime];
        powerTables = multiquadraticStripScreenPowerTables[values,
          maximumExponents, prime];
        rootDerivatives = Table[
          Module[{pair = multiquadraticStripScreenEvaluateRational[
             deltaCompiled[[a]], powerTables, inverses, prime], half},
           If[pair === $Failed, ConstantArray[0, 2],
             half = PowerMod[Mod[2 values[[2 + a]], prime], -1, prime];
             Mod[half Last[pair][[1 ;; 2]], prime]]],
          {a, rank}];
        evaluate[compiled_] := Module[{pair},
          pair = multiquadraticStripScreenEvaluateRational[compiled,
            powerTables, inverses, prime];
          If[pair === $Failed, Throw[$Failed, "MultiquadraticGaugeScreenPoint"]];
          {First[pair], Table[Mod[Last[pair][[mu]] +
             Sum[Last[pair][[2 + a]] rootDerivatives[[a, mu]], {a, rank}],
             prime], {mu, 2}]}];
        If[Catch[
            denominatorPair = evaluate[denominatorCompiled];
            ex = Map[First[evaluate[#1]] &, eCompiled[[1]], {2}];
            ey = Map[First[evaluate[#1]] &, eCompiled[[2]], {2}];
            cx = Map[First[evaluate[#1]] &, cCompiled[[1]], {2}];
            cy = Map[First[evaluate[#1]] &, cCompiled[[2]], {2}];
            bx = Map[First[evaluate[#1]] &, bCompiled[[1]], {2}];
            by = Map[First[evaluate[#1]] &, bCompiled[[2]], {2}];
            formValues = Map[First[evaluate[#1]] &, formCompiled, {2}];
            candidateValues = Map[First[evaluate[#1]] &, candidateCompiled, {2}];
            True, "MultiquadraticGaugeScreenPoint"] =!= True,
          pointOK = False; Break[]];
        denominatorValue = First[denominatorPair];
        If[denominatorValue === 0, pointOK = False; Break[]];
        denominatorInverse = PowerMod[denominatorValue, -1, prime];
        denominatorLog = Mod[Last[denominatorPair] denominatorInverse, prime];
        xInverse = inverses[[1]]; yInverse = inverses[[2]];
        monomialValues = Table[
          Mod[powerTables[[1]][[support[[k, 1]] + 1]]
            powerTables[[2]][[support[[k, 2]] + 1]], prime], {k, supportCount}];
        gradeValues = Table[
          Mod[Product[If[BitGet[grade, a - 1] === 1, values[[2 + a]], 1],
            {a, rank}], prime], {grade, 0, gradeCount - 1}];
        (* dlog r_grade = Sum_{a in grade} (dr_a/dmu)/r_a, and
           rootDerivatives[[a]] is dr_a/dmu because r_a^2 = delta_a *)
        gradeLog = Table[
          Mod[Sum[If[BitGet[grade, a - 1] === 1,
            Mod[rootDerivatives[[a, mu]] inverses[[2 + a]], prime], 0],
            {a, rank}], prime],
          {grade, 0, gradeCount - 1}, {mu, 2}];
        basisValues = Flatten[Table[
          Mod[gradeValues[[grade + 1]] monomialValues[[k]] denominatorInverse,
            prime], {grade, 0, gradeCount - 1}, {k, supportCount}]];
        basisDerivatives = Table[Flatten[Table[
          Mod[Mod[gradeValues[[grade + 1]] monomialValues[[k]]
              denominatorInverse, prime]
            Mod[If[mu === 1, support[[k, 1]] xInverse,
                support[[k, 2]] yInverse] +
              gradeLog[[grade + 1, mu]] - denominatorLog[[mu]], prime], prime],
          {grade, 0, gradeCount - 1}, {k, supportCount}]], {mu, 2}];
        Do[
          rowVector = Join[
            Flatten[Table[
              Mod[If[i2 === i && j2 === j, basisDerivatives[[mu]], 0] +
                Mod[If[j2 === j, -epsilonMod If[mu === 1, ex[[i, i2]],
                      ey[[i, i2]]], 0] +
                  If[i2 === i, epsilonMod If[mu === 1, cx[[j2, j]],
                      cy[[j2, j]]], 0], prime] basisValues, prime],
              {i2, upper}, {j2, lower}]],
            Flatten[Table[If[i2 === i && j2 === j,
              Mod[epsilonMod formValues[[k, mu]], prime], 0],
              {k, letterCount}, {i2, upper}, {j2, lower}]]];
          If[Length[rowVector] =!= unknownCount,
            Throw[$Failed, "MultiquadraticGaugeScreenWidth"]];
          AppendTo[pointRows, Developer`ToPackedArray[rowVector]];
          AppendTo[pointRight, If[mu === 1, bx[[i, j]], by[[i, j]]]];
          If[candidateCount > 0,
            AppendTo[pointCandidate, Developer`ToPackedArray[Flatten[Table[
              If[i2 === i && j2 === j,
                Mod[epsilonMod candidateValues[[k, mu]], prime], 0],
              {k, candidateCount}, {i2, upper}, {j2, lower}]]]]],
          {mu, 2}, {i, upper}, {j, lower}],
        {signMask, 0, gradeCount - 1}];
      If[TrueQ[pointOK],
        accepted++;
        rows = Join[rows, pointRows]; right = Join[right, pointRight];
        If[candidateCount > 0, candidateRows = Join[candidateRows, pointCandidate]],
        rejected["Unusable"] = Lookup[rejected, "Unusable", 0] + 1]]]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PointAssembly",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate, "PointCount" -> accepted,
        "RequestedPointCount" -> pointCount, "AttemptCount" -> attempts,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  If[accepted < pointCount,
    Return[<|"Status" -> "GaugeScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "InsufficientAdmissiblePoints",
      "PointCount" -> accepted, "RequestedPointCount" -> pointCount,
      "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
      "Prime" -> prime, "RegulatorValue" -> regulatorValue|>]];
  matrix = Developer`ToPackedArray[Mod[rows, prime]];
  rightVector = Developer`ToPackedArray[Mod[right, prime]];
  candidateMatrix = If[candidateCount > 0,
    Developer`ToPackedArray[Mod[candidateRows, prime]], {}];
  (* the two opaque calls below cannot be interrupted cooperatively, so
     the deadline is checked immediately before each of them *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:Rank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  rankSeconds = First[AbsoluteTiming[
    rankA = MatrixRank[matrix, Modulus -> prime];
    rankAugmented = MatrixRank[MapThread[Append, {matrix, rightVector}],
      Modulus -> prime];]];
  defect = rankAugmented - rankA;
  wanted = Replace[OptionValue["LeftNullSpace"],
    Automatic :> (defect > 0 || candidateCount > 0)];
  (* POST-RANK BOUNDARY (2026-08-25).  The rank pair is the screen's
     verdict and it is now paid for; what remains -- the left null space
     of the transpose and one MatrixRank per candidate letter -- is a
     second expensive block.  The stop therefore carries the rank and the
     defect it already measured, so a resumed run knows the verdict even
     though the witness was never built.  It fires only when that second
     block would actually run. *)
  If[(TrueQ[wanted] || candidateCount > 0) &&
      multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PostRank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "Defect" -> defect, "Rank" -> rankA,
        "AugmentedRank" -> rankAugmented,
        "LeftNullSpaceWanted" -> TrueQ[wanted],
        "CandidateCount" -> candidateCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds|>|>]]];
  leftNullSeconds = First[AbsoluteTiming[
    leftNull = If[TrueQ[wanted],
      NullSpace[Transpose[matrix], Modulus -> prime], {}];]];
  witness = Missing["Consistent"];
  If[defect > 0,
    witness = If[ListQ[leftNull] && leftNull =!= {},
      SelectFirst[leftNull, Mod[#1 . rightVector, prime] =!= 0 &,
        Missing["NoWitnessFound"]], Missing["LeftNullSpaceNotComputed"]];
    If[! MissingQ[witness],
      witness = <|"Prime" -> prime, "Vector" -> witness,
        "RowBasis" -> "SignBranch",
        "TransposeResidualZero" ->
          AllTrue[Mod[witness . matrix, prime], #1 === 0 &],
        "RightHandSidePairing" -> Mod[witness . rightVector, prime],
        "Support" -> Count[witness, _?(#1 =!= 0 &)]|>]];
  (* subset defects from the small pairing matrix L . [C | b]:
     b is in the column span of [A | C_S] exactly when its pairing
     column lies in the span of the C_S pairing columns *)
  candidateScores = {}; subsetResults = {};
  If[candidateCount > 0 && ListQ[leftNull],
    pairing = If[leftNull === {}, {},
      Mod[leftNull . MapThread[Append, {candidateMatrix, rightVector}], prime]];
    subsetDefect[indices_List] := Module[{columns},
      If[pairing === {}, Return[0]];
      columns = Flatten[
        ((#1 - 1) candidateWidth + Range[candidateWidth]) & /@ indices];
      MatrixRank[pairing[[All, Append[columns, candidateCount candidateWidth + 1]]],
        Modulus -> prime] -
        If[columns === {}, 0,
          MatrixRank[pairing[[All, columns]], Modulus -> prime]]];
    candidateScores = Table[
      Module[{block = (k - 1) candidateWidth + Range[candidateWidth]},
      <|"Index" -> k,
        "WitnessPairing" -> If[AssociationQ[witness],
          Mod[witness["Vector"] . candidateMatrix[[All, block]], prime],
          Missing["NoWitness"]],
        "PiercesWitness" -> If[AssociationQ[witness],
          AnyTrue[Mod[witness["Vector"] . candidateMatrix[[All, block]], prime],
            #1 =!= 0 &], Missing["NoWitness"]],
        (* rank([A | C_k]) - rank(A), read off the pairing matrix.  0
           means the candidate's residue columns lie in the span of the
           system's existing columns: its dlog is a linear combination of
           one-forms the alphabet already has, so it is not a new letter
           at all -- a distinction the witness pairing alone cannot make,
           and the one that separates "no new direction was produced"
           from "new directions were produced and none touches the
           obstruction". *)
        "RankContribution" -> If[pairing === {}, 0,
          MatrixRank[pairing[[All, block]], Modulus -> prime]],
        "Defect" -> subsetDefect[{k}]|>],
      {k, candidateCount}];
    subsets = Replace[OptionValue["CandidateSubsets"], Automatic :>
      If[candidateCount > 1, {Range[candidateCount]}, {}]];
    If[! MatchQ[subsets, {{___Integer} ...}],
      subsets = If[candidateCount > 1, {Range[candidateCount]}, {}]];
    subsetResults = Table[
      <|"Indices" -> subset, "Defect" -> subsetDefect[subset]|>,
      {subset, subsets}]];
  screenStatus = If[defect > 0, "GaugeImageObstruction", "GaugeImageConsistent"];
  seconds = AbsoluteTime[] - startTime;
  phaseTimings = <|"Compile" -> compileSeconds,
    "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds,
    "LeftNullSpace" -> leftNullSeconds|>;
  <|"Status" -> screenStatus, "Module" -> "MultiquadraticStripSolve",
    "Method" -> "PointEvaluatedAffineGaugeSystem",
    "SizeEstimate" -> sizeEstimate, "PhaseTimings" -> phaseTimings,
    "CompileCache" -> Join[
      AssociationMap[($multiquadraticStripScreenCompileStatistics[#1] -
        compileStatisticsBefore[#1]) &, {"Hits", "Misses", "Evictions"}],
      <|"Bytes" -> $multiquadraticStripScreenCompileCacheBytes|>],
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Defect" -> defect, "Rank" -> rankA, "AugmentedRank" -> rankAugmented,
    "Nullity" -> unknownCount - rankA,
    "LeftNullity" -> Length[matrix] - rankA,
    "MatrixDimensions" -> Dimensions[matrix],
    "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "LetterCount" -> letterCount, "Prime" -> prime,
    "RegulatorValue" -> regulatorValue, "PointCount" -> accepted,
    "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
    "EquationsPerPoint" -> equationsPerPoint,
    "Witness" -> witness,
    "CandidateCount" -> candidateCount,
    "CandidateScores" -> candidateScores,
    "CandidateSubsetResults" -> subsetResults,
    (* the ansatz a defect belongs to: a defect with no ansatz descriptor
       cannot distinguish a missing letter from too small a support *)
    "Ansatz" -> <|"GaugeDenominator" -> Together[gaugeDenominator],
      "GaugeDenominatorDegrees" ->
        (Exponent[Together[gaugeDenominator], #1] & /@ variables),
      "SupportCount" -> supportCount, "GradeCount" -> gradeCount,
      "Dimensions" -> {upper, lower}, "RootCount" -> rank,
      "RootSquares" -> Lookup[roots, "RootSquare", {}],
      "ABIFingerprint" -> Lookup[ansatz, "ABIFingerprint",
        Missing["NoPreparation"]]|>,
    "Seconds" -> seconds|>
];
multiquadraticStripGaugeScreen[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenArguments"];

(* Two independent images.  As a PRODUCTION GATE the second image is run
   only when the first reports a defect -- a defect at one image can be a
   bad image, and a consistent image does not gate anything, so it is not
   made more consistent by a second one.  As a DISCOVERY instrument the
   opposite is wanted: "the defect drops to 0" is only accepted at TWO
   images, so "ConfirmConsistency" -> True runs every image regardless.
   The verdict is an obstruction only when both images carry a defect. *)
Options[multiquadraticStripGaugeScreenImages] = Join[
  Options[multiquadraticStripGaugeScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True,
  "ConfirmConsistency" -> False
}];

multiquadraticStripGaugeScreenImages[ansatz_Association,
    opts : OptionsPattern[]] := Module[
  {gate, images, results = {}, screenOptions, result, defects},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreenImages]]]];
  If[AssociationQ[gate], Return[gate]];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}],
    Return[multiquadraticStripFailure["InvalidGaugeScreenImages",
      <|"Images" -> images|>]]];
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["Prime" -> _] | HoldPattern["RegulatorValue" -> _] |
      HoldPattern["RandomSeed" -> _]],
    Options[multiquadraticStripGaugeScreen]];
  Do[
    result = multiquadraticStripGaugeScreen[ansatz,
      "Prime" -> images[[k, 1]], "RegulatorValue" -> images[[k, 2]],
      "RandomSeed" -> OptionValue["RandomSeed"] + 7919 k,
      Sequence @@ screenOptions];
    AppendTo[results, result];
    If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
        Lookup[result, "Status", None]], Break[]];
    If[Lookup[result, "Defect", 1] === 0,
      If[! TrueQ[OptionValue["ConfirmConsistency"]], Break[]],
      If[! TrueQ[OptionValue["ConfirmObstruction"]], Break[]]],
    {k, Length[images]}];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  <|"Status" -> Which[
      ! AllTrue[results, MemberQ[{"GaugeImageObstruction",
        "GaugeImageConsistent"}, Lookup[#1, "Status", None]] &],
        (* a budget stop is a RESUMABLE stop, not "the screen does not
           apply to this block": the two must not be conflated *)
        If[AnyTrue[results, Lookup[#1, "Status", None] === "BudgetExhausted" &],
          "BudgetExhausted", "GaugeScreenNotApplicable"],
      AllTrue[defects, IntegerQ[#1] && #1 === 0 &] &&
        (Length[results] >= 2 || ! TrueQ[OptionValue["ConfirmConsistency"]]),
        "GaugeImageConsistent",
      AllTrue[defects, IntegerQ[#1] && #1 === 0 &],
        "GaugeImageConsistentUnconfirmed",
      AllTrue[defects, IntegerQ[#1] && #1 > 0 &] && Length[results] >= 2,
        "GaugeImageObstruction",
      True, "GaugeImageObstructionUnconfirmed"],
    "Module" -> "MultiquadraticStripSolve",
    "Method" -> "PointEvaluatedAffineGaugeSystem",
    "ImageCount" -> Length[results], "Defects" -> defects,
    "Images" -> Take[images, UpTo[Length[results]]],
    "ImageResults" -> results,
    "SizeEstimate" -> Lookup[Last[results], "SizeEstimate",
      Missing["NoSizeEstimate"]],
    "PhaseTimings" -> Merge[Lookup[results, "PhaseTimings", <||>], Total],
    "Stage" -> Lookup[Last[results], "Stage", Missing["NoStage"]],
    "MatrixDimensions" -> Lookup[Last[results], "MatrixDimensions",
      Missing["NoMatrix"]],
    "Seconds" -> Total[Lookup[results, "Seconds", 0]]|>
];
multiquadraticStripGaugeScreenImages[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenArguments"];

(* ------------------------------------------------------------------ *)
(* Screen-validated DEGREE-OFFSET LADDER (2026-08-25)                   *)
(* ------------------------------------------------------------------ *)

(* CF300 (12,9) needs a gauge NUMERATOR three degrees above its
   denominator ("DegreeOffset" -> {3,3}); at the default {0,0} the screen
   above correctly refuses the ansatz, and no caller can be expected to
   know that number per block in an unattended campaign.  So the offset
   is MEASURED: when the screen at the configured offset reports a
   CONFIRMED defect, the SCREEN ONLY -- never the compile -- is re-run at
   escalating offsets, and the first one that is consistent at TWO images
   is adopted for the real solve.  A rung costs one screen per image
   (measured 50-90 s on that block) against a compile measured at
   ~7900 s, so the whole ladder is cheap by construction.

   The escalation is a search over ANSATZ SIZE, not over the alphabet: a
   rung that reaches defect 0 says the missing direction was a gauge pole
   at infinity, and a ladder that exhausts leaves the alphabet verdict of
   the base screen standing untouched. *)

$multiquadraticStripDefaultDegreeOffsetLadder = {{1, 1}, {2, 2}, {3, 3},
  {4, 4}};

(* FACET_MQ_DEGREE_LADDER = "1,1;2,2;3,3", parsed defensively in the style
   of FACET_BROKER_MINIMUM_SECONDS: anything that is not a nonempty list
   of pairs of nonnegative integers falls back to the default rather than
   erroring or half-parsing.  An environment typo must never silently
   change the ansatz an overnight campaign compiles. *)
multiquadraticStripDegreeOffsetLadderParse[text_, fallback_] := Module[
  {trimmed, rungs},
  trimmed = If[StringQ[text], StringTrim[text], ""];
  If[trimmed === "", Return[fallback]];
  If[! StringMatchQ[trimmed, RegularExpression[
      "[0-9]+ *, *[0-9]+( *; *[0-9]+ *, *[0-9]+)*"]],
    Return[fallback]];
  rungs = Quiet[Check[
    Map[ToExpression[StringTrim[#1]] &,
      StringSplit[StringSplit[trimmed, ";"], ","], {2}], $Failed]];
  If[MatchQ[rungs, {{_Integer, _Integer} ..}] &&
      AllTrue[Flatten[rungs], IntegerQ[#1] && #1 >= 0 &],
    rungs, fallback]];

multiquadraticStripDegreeOffsetLadder[] :=
  multiquadraticStripDegreeOffsetLadderParse[
    Environment["FACET_MQ_DEGREE_LADDER"],
    $multiquadraticStripDefaultDegreeOffsetLadder];

(* The source may be a full preparation record or the cheap ansatz
   descriptor: the ladder reads only the four fields it needs to rebuild
   an ansatz at another offset, and both carry them. *)
Options[multiquadraticStripGaugeScreenLadder] = Join[
  DeleteCases[Options[multiquadraticStripGaugeScreenImages],
    HoldPattern["ConfirmConsistency" -> _]], {
  "DegreeOffsetLadder" -> Automatic,
  "BaseDegreeOffset" -> {0, 0},
  "Deadline" -> Infinity,
  "Verbose" -> False
}];

multiquadraticStripGaugeScreenLadder[source_Association,
    opts : OptionsPattern[]] := Module[
  {gate, record, roots, oneForms, gaugeDenominator, ladder, baseOffset,
   deadline, verbose, log, screenOptions, rungs = {}, skipped = {},
   ansatz, result, imageResults, adopted = None,
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreenLadder]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  record = Lookup[source, "Record", $Failed];
  roots = Lookup[source, "Roots", $Failed];
  oneForms = Lookup[source, "OneForms", $Failed];
  gaugeDenominator = Lookup[source, "GaugeDenominator", $Failed];
  If[! AssociationQ[record] || ! ListQ[roots] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}] || gaugeDenominator === $Failed,
    Return[multiquadraticStripFailure["InvalidGaugeAnsatz",
      <|"MissingKeys" -> Select[{"Record", "Roots", "OneForms",
          "GaugeDenominator"}, ! KeyExistsQ[source, #1] &]|>]]];
  baseOffset = OptionValue["BaseDegreeOffset"];
  If[! MatchQ[baseOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset",
      <|"BaseDegreeOffset" -> baseOffset|>]]];
  ladder = Replace[OptionValue["DegreeOffsetLadder"],
    Automatic :> multiquadraticStripDegreeOffsetLadder[]];
  If[! MatchQ[ladder, {} | {{_Integer, _Integer} ..}] ||
      ! AllTrue[Flatten[ladder], IntegerQ[#1] && #1 >= 0 &],
    Return[multiquadraticStripFailure["InvalidDegreeOffsetLadder",
      <|"DegreeOffsetLadder" -> ladder|>]]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["[multiquadratic] ", items]];
  (* every rung is a DISCOVERY measurement, so defect 0 is accepted only
     at two images: "ConfirmConsistency" is the ladder's, not the
     caller's *)
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["DegreeOffsetLadder" -> _] |
      HoldPattern["DegreeOffsetLadder" :> _] |
      HoldPattern["BaseDegreeOffset" -> _] |
      HoldPattern["BaseDegreeOffset" :> _] |
      HoldPattern["Deadline" -> _] | HoldPattern["Deadline" :> _] |
      HoldPattern["Verbose" -> _] | HoldPattern["Verbose" :> _]],
    Options[multiquadraticStripGaugeScreenImages]];
  Do[
    (* a rung no larger than the offset that already failed cannot repair
       anything: it is recorded as skipped, not measured *)
    If[offset[[1]] <= baseOffset[[1]] && offset[[2]] <= baseOffset[[2]],
      AppendTo[skipped, offset]; Continue[]];
    (* the deadline is read at every rung boundary: a rung is this
       ladder's unit of work *)
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[multiquadraticStripBudgetExhausted["GaugeScreenLadder",
        AbsoluteTime[] - startTime, deadline,
        <|"Method" -> "ScreenValidatedDegreeOffsetLadder",
          "BaseDegreeOffset" -> baseOffset,
          "DegreeOffsetLadder" -> ladder,
          "NextDegreeOffset" -> offset,
          "SkippedDegreeOffsets" -> skipped,
          "LadderRungs" -> rungs,
          "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@
            rungs)|>], Module]];
    ansatz = multiquadraticStripGaugeAnsatz[record, roots, oneForms,
      gaugeDenominator, "DegreeOffset" -> offset];
    If[Lookup[ansatz, "Status", None] =!= "MultiquadraticGaugeAnsatzV1",
      Return[ansatz, Module]];
    (* the rung's own screen is bounded by the same deadline: checking
       only BETWEEN rungs left one dense rank/nullspace call able to
       overrun the whole budget on its own (Codex 04:30 P1) *)
    result = multiquadraticStripGaugeScreenImages[ansatz,
      "ConfirmConsistency" -> True, "Deadline" -> deadline,
      Sequence @@ screenOptions];
    If[Lookup[result, "Status", None] === "BudgetExhausted",
      (* the LADDER is the unit a caller resumes, so the stop keeps the
         ladder's stage name; the screen phase that actually ran out of
         time is carried beside it as diagnostics *)
      Return[Join[result, <|"Method" -> "ScreenValidatedDegreeOffsetLadder",
        "Stage" -> "GaugeScreenLadder",
        "ScreenStage" -> Lookup[result, "Stage", Missing["NoScreenStage"]],
        "BaseDegreeOffset" -> baseOffset, "DegreeOffsetLadder" -> ladder,
        "NextDegreeOffset" -> offset, "SkippedDegreeOffsets" -> skipped,
        "LadderRungs" -> rungs,
        "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@
          rungs)|>], Module]];
    imageResults = Lookup[result, "ImageResults", {}];
    AppendTo[rungs, <|"DegreeOffset" -> offset,
      "SupportCount" -> Length[ansatz["GaugeSupport"]],
      "UnknownCount" -> ansatz["UnknownCount"],
      "Status" -> Lookup[result, "Status", None],
      "ImageCount" -> Lookup[result, "ImageCount", 0],
      "Images" -> Lookup[result, "Images", {}],
      "Defects" -> Lookup[result, "Defects", Missing["NoDefect"]],
      "Ranks" -> Lookup[imageResults, "Rank", {}],
      "AugmentedRanks" -> Lookup[imageResults, "AugmentedRank", {}],
      "Nullities" -> Lookup[imageResults, "Nullity", {}],
      "MatrixDimensions" -> Lookup[imageResults, "MatrixDimensions", {}],
      "Seconds" -> Lookup[result, "Seconds", 0]|>];
    log["gauge screen ladder: DegreeOffset ", offset, ", support ",
      Length[ansatz["GaugeSupport"]], ", ", ansatz["UnknownCount"],
      " unknowns -> ", Lookup[result, "Status", None], ", defects ",
      Lookup[result, "Defects", None], ", ",
      Round[Lookup[result, "Seconds", 0], 0.1], " s"];
    If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent",
        "GaugeImageObstructionUnconfirmed",
        "GaugeImageConsistentUnconfirmed"}, Lookup[result, "Status", None]],
      Return[multiquadraticStripFailure["GaugeScreenLadderNotApplicable",
        <|"DegreeOffset" -> offset,
          "ScreenStatus" -> Lookup[result, "Status", None],
          "LadderRungs" -> rungs, "ScreenResult" -> result|>], Module]];
    If[Lookup[result, "Status", None] === "GaugeImageConsistent",
      adopted = offset; Break[]],
    {offset, ladder}];
  <|"Status" -> If[adopted === None, "GaugeScreenLadderExhausted",
      "GaugeScreenLadderAdopted"],
    "Module" -> "MultiquadraticStripSolve",
    "Method" -> "ScreenValidatedDegreeOffsetLadder",
    "AdoptedDegreeOffset" -> If[adopted === None,
      Missing["GaugeScreenLadderExhausted"], adopted],
    "BaseDegreeOffset" -> baseOffset,
    "DegreeOffsetLadder" -> ladder,
    "SkippedDegreeOffsets" -> skipped,
    "RungCount" -> Length[rungs],
    "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
    "LadderRungs" -> rungs,
    "Seconds" -> AbsoluteTime[] - startTime|>
];
multiquadraticStripGaugeScreenLadder[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenLadderArguments"];

(* ------------------------------------------------------------------ *)
(* Witness-guided MIXED-GRADE letter discovery (2026-08-25, Codex Q3)   *)
(* ------------------------------------------------------------------ *)

(* The norm-factor generator above finds SINGLE-ROOT principal letters
   A +- Sqrt[delta] only.  Codex's Q3: the object that can be missing is
   a mixed-grade potential
     P = P0 + P1 r1 + P2 r2 + P12 r1 r2,
   whose FULL Galois norm is supported on the polar divisor D, and whose
   dlog is then the missing letter.  Enumerating such P by templates is
   hopeless; the problem is solved EXACTLY and LINEARLY as follows.

   A letter exists at a polar factor f exactly when the prime divisor f
   SPLITS in the multiquadratic cover -- and then the function whose
   divisor is the split part is the letter.  So:

   (1) parameterize the curve f = 0 (f must be linear in one variable,
       which every rational polar factor of these strips is; anything
       else is reported, not guessed at);
   (2) on that curve, decide for EVERY grade g whether delta_g is a
       square in the residue field.  Those grades form a subgroup S of
       the grade group -- the decomposition data of f;
   (3) the condition "P vanishes on one prime above f" is then LINEAR in
       the coefficients of the P_g: substitute the square roots for the
       split roots, keep the others symbolic, reduce r_a^2 -> delta_a,
       and demand every remaining coefficient vanish identically along
       the curve.  That is a rational-linear system; its null space is
       the space of mixed-grade potentials with a zero at that prime;
   (4) the full Galois norm of each solution is computed exactly and
       filtered by the SAME norm-in-alphabet certificate the single-root
       letters carry, now against the polar CENSUS factor set rather
       than the current alphabet.

   The degree bound is raised one step at a time, so the first solutions
   found are the minimal-degree generators, not generic members of a
   large space.  A measured empty result at a stated bound is a real
   negative: no mixed-grade letter of that degree has its divisor over
   these factors. *)

(* The curve f = 0 as var -> rational function of the other variable.
   Only a factor that is LINEAR in one of the two variables is
   parameterized this way; anything else is reported as unparameterized
   rather than approximated. *)
(* Catch/Throw, NOT Return inside Do: this package has paid for that trap
   (Return inside Do discards the result and the Module falls through). *)
multiquadraticStripCurveParameterization[factor_, variables : {x_, y_}] :=
  Catch[Module[{expanded, other, coefficients},
  expanded = Quiet[Expand[Together[factor]]];
  If[! PolynomialQ[expanded, variables],
    Throw[$Failed, "MultiquadraticCurveParameterization"]];
  Do[
    other = variables[[3 - k]];
    If[Exponent[expanded, variables[[k]]] =!= 1, Continue[]];
    coefficients = CoefficientList[expanded, variables[[k]]];
    If[Length[coefficients] =!= 2 || TrueQ[Together[coefficients[[2]]] === 0],
      Continue[]];
    Throw[<|"Variable" -> other,
      "Rule" -> variables[[k]] -> Together[-coefficients[[1]]/coefficients[[2]]],
      "Eliminated" -> variables[[k]], "Factor" -> expanded|>,
      "MultiquadraticCurveParameterization"],
    {k, 2}];
  $Failed], "MultiquadraticCurveParameterization"];

(* An exact square root of a rational function of ONE variable, or
   $Failed.  q = n/d is a square exactly when n d is a square polynomial;
   then Sqrt[q] = Sqrt[n d]/d. *)
multiquadraticStripRationalFunctionSquareRoot[value_, variable_Symbol] :=
  Module[{rational, numerator, denominator, product, squareRoot, constant},
  rational = Quiet[Together[value]];
  If[! FreeQ[rational, DirectedInfinity | Indeterminate], Return[$Failed]];
  If[TrueQ[rational === 0], Return[0]];
  numerator = Numerator[rational]; denominator = Denominator[rational];
  If[FreeQ[rational, variable],
    Return[If[multiquadraticStripRationalSquareQ[rational], Sqrt[rational],
      $Failed]]];
  product = Quiet[Expand[numerator denominator]];
  If[! PolynomialQ[product, variable], Return[$Failed]];
  constant = Quiet[Cancel[product/Expand[product/Coefficient[product,
    variable, Exponent[product, variable]]]]];
  squareRoot = multiquadraticStripPolynomialSquareRoot[product, {variable}];
  If[squareRoot === $Failed, Return[$Failed]];
  Together[squareRoot/denominator]
];

(* grade bitmask -> the product of its root squares *)
multiquadraticStripGradeSquare[roots_List, grade_Integer] :=
  Expand[Together[Product[
    If[BitGet[grade, a - 1] === 1, Lookup[roots[[a]], "RootSquare", 1], 1],
    {a, Length[roots]}]]];

(* The Galois norm of P = Sum_g c_g r_g: the product over its DISTINCT
   conjugates, reduced by r_a^2 = delta_a.  Distinct, not all 2^r sign
   branches: a P that happens to lie in a proper subfield has repeated
   branches, and multiplying them all would return the true norm raised
   to the index -- which doubles every exponent in the polar divisor and
   in any gauge denominator built from it.  For a P with full grade
   support the two definitions agree.  Exact and rational either way. *)
multiquadraticStripGradeNorm[coefficients_List, roots_List] := Module[
  {rank = Length[roots], gradeCount, branch, branches = {}, product,
   rootOne, rootTwo, rootThree, symbols, squares, reduce},
  gradeCount = 2^rank;
  If[Length[coefficients] =!= gradeCount, Return[$Failed]];
  symbols = Take[{rootOne, rootTwo, rootThree}, rank];
  squares = Table[Together[Lookup[roots[[a]], "RootSquare", 1]], {a, rank}];
  (* the reduction r_a^2 -> delta_a, applied to exhaustion; the norm is
     Galois invariant, so nothing symbolic may survive *)
  reduce[value_] := Module[{current = Expand[value], guardCount = 0},
    While[guardCount < 32 && ! FreeQ[current,
        Power[Alternatives @@ symbols, p_Integer /; p >= 2]],
      guardCount++;
      current = Expand[current /.
        Power[symbol_ /; MemberQ[symbols, symbol], p_Integer /; p >= 2] :>
          symbol^Mod[p, 2] squares[[First[FirstPosition[symbols, symbol]]]]^
            Quotient[p, 2]]];
    current];
  Do[
    branch = Expand[Sum[
      coefficients[[grade + 1]] Product[
        If[BitGet[grade, a - 1] === 1,
          If[BitGet[signMask, a - 1] === 1, -1, 1] symbols[[a]], 1],
        {a, rank}],
      {grade, 0, gradeCount - 1}]];
    AppendTo[branches, branch],
    {signMask, 0, gradeCount - 1}];
  branches = DeleteDuplicates[branches,
    TrueQ[Expand[Together[#1 - #2]] === 0] &];
  product = 1;
  Do[product = reduce[Expand[product branch]], {branch, branches}];
  If[! FreeQ[product, Alternatives @@ symbols], Return[$Failed]];
  Quiet[Expand[Together[product]]]
];

Options[multiquadraticStripMixedGradeLetters] = {
  "MaximumDegree" -> 2,
  "Factors" -> Automatic,
  "Alphabet" -> {},
  "MaximumSolutionsPerPrime" -> 6,
  (* 0 = the solution basis only; 2 = also every +-1 combination of a
     PAIR of basis vectors.  Part of the stated bound of a negative. *)
  "CombinationOrder" -> 2,
  "CombinationBasisLimit" -> 24,
  (* a letter of grade support {0, g} lies in a quadratic subfield and is
     already produced by multiquadraticStripAlgebraicLetters; one of
     support {g, h} is r_g times such a letter, so its dlog is spanned by
     the alphabet plus dlog r_g.  True emits only supports of size >= 3,
     which is where the genuinely mixed-grade content is. *)
  "MinimumGradeSupport" -> 1
};

multiquadraticStripMixedGradeLetters[roots_List, censusFactors_List,
    variables : {x_, y_}, opts : OptionsPattern[]] := Module[
  {gate, rank, gradeCount, alphabet, factors, maximumDegree, maximumSolutions,
   records = {}, diagnostics = {}, parameterization, freeVariable, rule,
   gradeSquares, curveSquares, splitGrades, squareRoots, rootSymbols,
   rootOne, rootTwo, rootThree, degree, monomials, unknowns, coefficients,
   substituted, reduced, conditions, equations, solutions, basis, candidate,
   norm, letter, canonical, seen = {}, key, symbolValues, remaining,
   numerators, gradeSquareOnCurve, solutionCount, expression,
   ramifiedGrades, trivialCount = 0, combinationOrder, combinationLimit,
   minimumSupport, combinationCount = 0, gradeSupport},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripMixedGradeLetters]]]];
  If[AssociationQ[gate], Return[gate]];
  rank = Length[roots];
  If[rank < 1 || rank > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank",
      <|"ActualRank" -> rank|>]]];
  gradeCount = 2^rank;
  alphabet = Replace[OptionValue["Alphabet"], Automatic :> censusFactors];
  factors = Replace[OptionValue["Factors"], Automatic :> censusFactors];
  maximumDegree = OptionValue["MaximumDegree"];
  maximumSolutions = OptionValue["MaximumSolutionsPerPrime"];
  combinationOrder = OptionValue["CombinationOrder"];
  combinationLimit = OptionValue["CombinationBasisLimit"];
  minimumSupport = OptionValue["MinimumGradeSupport"];
  If[! IntegerQ[maximumDegree] || maximumDegree < 0 ||
      ! IntegerQ[maximumSolutions] || maximumSolutions < 1 ||
      ! IntegerQ[combinationOrder] || combinationOrder < 0 ||
      ! IntegerQ[combinationLimit] || combinationLimit < 1 ||
      ! IntegerQ[minimumSupport] || minimumSupport < 1,
    Return[multiquadraticStripFailure["InvalidMixedGradeRequest",
      <|"MaximumDegree" -> maximumDegree,
        "CombinationOrder" -> combinationOrder,
        "MinimumGradeSupport" -> minimumSupport|>]]];
  rootSymbols = Take[{rootOne, rootTwo, rootThree}, rank];
  gradeSquares = Table[multiquadraticStripGradeSquare[roots, grade],
    {grade, 0, gradeCount - 1}];
  Do[
    parameterization = multiquadraticStripCurveParameterization[factor,
      variables];
    If[parameterization === $Failed,
      AppendTo[diagnostics, <|"Factor" -> factor,
        "Status" -> "NotRationallyParameterized"|>];
      Continue[]];
    freeVariable = parameterization["Variable"];
    rule = parameterization["Rule"];
    (* (2) the decomposition data: which grades are squares on the curve *)
    curveSquares = Quiet[Together[gradeSquares /. rule]];
    squareRoots = Table[
      multiquadraticStripRationalFunctionSquareRoot[curveSquares[[grade + 1]],
        freeVariable], {grade, 0, gradeCount - 1}];
    splitGrades = Select[Range[0, gradeCount - 1],
      squareRoots[[#1 + 1]] =!= $Failed &];
    ramifiedGrades = Select[Range[0, gradeCount - 1],
      TrueQ[Together[curveSquares[[#1 + 1]]] === 0] &];
    If[Length[splitGrades] <= 1,
      AppendTo[diagnostics, <|"Factor" -> factor, "Status" -> "Inert",
        "SplitGrades" -> splitGrades|>];
      Continue[]];
    AppendTo[diagnostics, <|"Factor" -> factor, "Status" -> "Split",
      "SplitGrades" -> splitGrades, "RamifiedGrades" -> ramifiedGrades,
      "FullSplit" -> (Length[splitGrades] === gradeCount &&
        ramifiedGrades === {})|>];
    (* (3) the LINEAR vanishing condition at one prime above the factor.
       Split roots take their square-root value on the curve; the others
       stay symbolic and are reduced by r_a^2 = delta_a, and every
       surviving coefficient must vanish identically along the curve. *)
    symbolValues = Table[
      If[MemberQ[splitGrades, 2^(a - 1)], squareRoots[[2^(a - 1) + 1]],
        rootSymbols[[a]]], {a, rank}];
    gradeSquareOnCurve = curveSquares;
    solutionCount = 0;
    Do[
      If[solutionCount >= maximumSolutions, Break[]];
      monomials = Flatten[Table[x^i y^j, {i, 0, degree}, {j, 0, degree}]];
      unknowns = Table[Unique["mg"], {gradeCount Length[monomials]}];
      coefficients = Table[
        Sum[unknowns[[(grade) Length[monomials] + m]] monomials[[m]],
          {m, Length[monomials]}], {grade, 0, gradeCount - 1}];
      expression = Sum[
        coefficients[[grade + 1]] Product[
          If[BitGet[grade, a - 1] === 1, symbolValues[[a]], 1], {a, rank}],
        {grade, 0, gradeCount - 1}];
      substituted = Quiet[Expand[expression /. rule]];
      (* reduce r_a^2 -> delta_a on the curve *)
      reduced = substituted;
      Do[
        reduced = Quiet[Expand[reduced /.
          Power[rootSymbols[[a]], p_Integer /; p >= 2] :>
            rootSymbols[[a]]^Mod[p, 2] gradeSquareOnCurve[[2^(a - 1) + 1]]^
              Quotient[p, 2]]],
        {a, rank}];
      reduced = Quiet[Together[reduced]];
      remaining = Select[rootSymbols, ! FreeQ[reduced, #1] &];
      conditions = If[remaining === {}, {Numerator[reduced]},
        Numerator[#1] & /@ Flatten[CoefficientList[Numerator[reduced],
          remaining]]];
      numerators = Select[Quiet[Expand[conditions]],
        ! TrueQ[Together[#1] === 0] &];
      equations = DeleteCases[Flatten[
        CoefficientList[#1, freeVariable] & /@ numerators], 0];
      If[equations === {}, Continue[]];
      solutions = Quiet[Solve[Thread[equations == 0], unknowns]];
      If[! MatchQ[solutions, {_List}], Continue[]];
      basis = Table[
        (coefficients /. First[solutions] /. unknown -> 1) /.
          (# -> 0 & /@ unknowns),
        {unknown, unknowns}];
      basis = DeleteDuplicates[
        Select[basis, ! AllTrue[Flatten[{#1}], TrueQ[Together[#1] === 0] &] &]];
      (* A solution that the factor divides outright, or a single-grade
         solution whose coefficient factors into the alphabet, is not a
         NEW letter: its dlog is already spanned by the rational letters
         and the root dlogs (dlog r_a = dlog delta_a / 2, and delta_a is
         itself a census factor).  Such solutions are counted and
         reported, never emitted, and the genuinely mixed-grade ones are
         tried first. *)
      basis = SortBy[basis, Function[entry,
        {-Count[entry, item_ /; ! TrueQ[Together[item] === 0]],
         LeafCount[entry]}]];
      (* A LETTER is a particular point of the solution space, not a
         basis vector of it: the space contains every multiple of the
         factor and every product of smaller letters, and the letter is
         the point whose norm is supported on the census.  The basis is
         therefore extended by the deterministic +-1 combinations of
         PAIRS of basis vectors before the norm certificate selects; the
         combination order is an option, and it is part of the stated
         bound of any negative result. *)
      If[combinationOrder >= 2 && Length[basis] >= 2 &&
          Length[basis] <= combinationLimit,
        basis = Join[basis, Flatten[Table[
          {basis[[i]] + basis[[j]], basis[[i]] - basis[[j]]},
          {i, Length[basis] - 1}, {j, i + 1, Length[basis]}], 2]]];
      combinationCount += Length[basis];
      Do[
        If[solutionCount >= maximumSolutions, Break[]];
        If[AllTrue[candidate, Function[item,
            TrueQ[Together[item] === 0] ||
              PolynomialQ[Quiet[Cancel[Together[item/factor]]], variables]]],
          trivialCount++; Continue[]];
        gradeSupport = Select[Range[0, gradeCount - 1],
          ! TrueQ[Together[candidate[[#1 + 1]]] === 0] &];
        If[Length[gradeSupport] < minimumSupport, trivialCount++; Continue[]];
        If[Length[gradeSupport] === 1 &&
            multiquadraticStripNormInAlphabetQ[
              First[Select[candidate, ! TrueQ[Together[#1] === 0] &]],
              alphabet, variables],
          trivialCount++; Continue[]];
        norm = multiquadraticStripGradeNorm[candidate, roots];
        If[norm === $Failed || TrueQ[Together[norm] === 0], Continue[]];
        If[! multiquadraticStripNormInAlphabetQ[norm, alphabet, variables],
          Continue[]];
        letter = Together[Sum[
          candidate[[grade + 1]] Product[
            If[BitGet[grade, a - 1] === 1,
              Sqrt[Lookup[roots[[a]], "RootSquare", 1]], 1], {a, rank}],
          {grade, 0, gradeCount - 1}]];
        If[TrueQ[Together[letter] === 0], Continue[]];
        canonical = ToString[InputForm[Together[
          letter/First[Select[candidate, ! TrueQ[Together[#1] === 0] &]]]]];
        key = {ToString[InputForm[Together[factor]]], canonical};
        If[MemberQ[seen, key], Continue[]];
        AppendTo[seen, key];
        solutionCount++;
        AppendTo[records, <|"Kind" -> "MixedGrade", "Letter" -> letter,
          "GradeCoefficients" -> candidate,
          "GradeSupport" -> gradeSupport,
          "Norm" -> norm, "NormInAlphabet" -> True,
          "Divisor" -> factor, "Degree" -> degree,
          "SplitGrades" -> splitGrades|>],
        {candidate, basis}],
      {degree, 0, maximumDegree}],
    {factor, factors}];
  <|"Status" -> "MultiquadraticMixedGradeLettersV1",
    "LetterRecords" -> records, "Letters" -> Lookup[records, "Letter", {}],
    "Count" -> Length[records], "TrivialSolutionCount" -> trivialCount,
    "CandidatesTested" -> combinationCount,
    "MaximumDegree" -> maximumDegree,
    "CombinationOrder" -> combinationOrder,
    "MinimumGradeSupport" -> minimumSupport,
    "Factors" -> factors, "Diagnostics" -> diagnostics,
    "SplitFactors" -> Select[diagnostics, Lookup[#1, "Status", None] === "Split" &],
    "UnparameterizedFactors" -> Select[diagnostics,
      Lookup[#1, "Status", None] === "NotRationallyParameterized" &]|>
];
multiquadraticStripMixedGradeLetters[___] :=
  multiquadraticStripFailure["InvalidMixedGradeArguments"];

(* ------------------------------------------------------------------ *)
(* Preparation: root order, index ABI, support, normalizations          *)
(* ------------------------------------------------------------------ *)

(* Frame order alone is not a stable ABI across catalog edits, so the
   selected roots are re-sorted by a canonical fingerprint of their
   root squares.  Two roots with the same square would give one
   generator two sign bits and are rejected. *)
(* 2^r independent sign automorphisms need r independent square
   classes: distinct radicands are not enough, {x, y, x y} has rank two
   and would give one generator two sign bits.  Factorization over Q
   detects exactly the rational-function square relations this
   evaluator admits.  The Codex sources check only for DUPLICATE root
   squares; FamilyRowGaugeFiniteField.wl's canonicalizer has this
   stronger check, and the neutral module must carry it or the
   duplicate cannot be deleted in favour of it (handoff External gap
   3).  Kept algorithmically identical to that copy so the differential
   test can compare verdicts. *)
multiquadraticStripRationalSquareQ[value : (_Integer | _Rational)] :=
  value >= 0 && IntegerQ[Sqrt[Numerator[value]]] &&
    IntegerQ[Sqrt[Denominator[value]]];
multiquadraticStripRationalSquareQ[_] := False;

multiquadraticStripSquareClassSquareQ[expression_] := Module[
  {q, numeratorFactors, denominatorFactors, constant},
  q = Quiet[Together[expression]];
  If[! FreeQ[q, Power[_, exponent_Rational /; Denominator[exponent] =!= 1]],
    Return[False]];
  numeratorFactors = Quiet[FactorList[Numerator[q]]];
  denominatorFactors = Quiet[FactorList[Denominator[q]]];
  If[! ListQ[numeratorFactors] || ! ListQ[denominatorFactors] ||
      numeratorFactors === {} || denominatorFactors === {}, Return[False]];
  constant = First[First[numeratorFactors]]/First[First[denominatorFactors]];
  multiquadraticStripRationalSquareQ[constant] &&
    AllTrue[Rest[numeratorFactors], EvenQ[Last[#1]] &] &&
    AllTrue[Rest[denominatorFactors], EvenQ[Last[#1]] &]
];

multiquadraticStripRootOrder[frame_Association, variables : {_Symbol, _Symbol},
    indices_List, epsilon_Symbol] := Module[
  {current, roots, rules, decorated, duplicates, dependent},
  current = transportChartCurrentRoots[frame, variables];
  If[! ListQ[current], Return[multiquadraticStripFailure["InvalidMultiquadraticFrame"]]];
  If[! AllTrue[indices, IntegerQ[#1] && 1 <= #1 <= Length[current] &],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  roots = current[[indices]];
  If[! AllTrue[roots, AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
      KeyExistsQ[#1, "RootSquare"] &&
      TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[multiquadraticStripFailure["InvalidRootMetadata"]]];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[roots[[#1[[1]], "RootSquare"]] -
      roots[[#1[[2]], "RootSquare"]]] === 0] &];
  If[duplicates =!= {},
    Return[multiquadraticStripFailure["DuplicateRootSquares",
      <|"DuplicatePairs" -> duplicates|>]]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; multiquadraticStripSquareClassSquareQ[
      Times @@ Lookup[roots[[subset]], "RootSquare", {}]] :> subset, None];
  If[dependent =!= None,
    Return[multiquadraticStripFailure["DependentRootSquares",
      <|"RootIndices" -> indices[[dependent]]|>]]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  decorated = MapThread[Function[{root, sourceIndex}, Module[{canonical},
      canonical = ToString[InputForm[multiquadraticStripCanonicalExpression[
        root["RootSquare"], rules]]];
      Join[root, <|"SourceIndex" -> sourceIndex,
        "CanonicalRootSquare" -> canonical,
        "RootFingerprint" -> Hash[canonical, "SHA256", "HexString"]|>]]],
    {roots, indices}];
  decorated = SortBy[decorated,
    {Lookup[#1, "CanonicalRootSquare", ""], Lookup[#1, "RootFingerprint", ""]} &];
  <|"Status" -> "StableRootOrder", "Roots" -> decorated,
    "SourceIndices" -> Lookup[decorated, "SourceIndex", {}],
    "RootFingerprints" -> Lookup[decorated, "RootFingerprint", {}],
    "OrderingFingerprint" -> Hash[Lookup[decorated, "CanonicalRootSquare", {}],
      "SHA256", "HexString"]|>
];

(* Root census.  transportChartRootIndices is the package classifier and
   is called here, but its matcher

     Flatten[Position[rootBases, candidate_ /; Together[base - candidate] === 0]]

   (TransportCharts.wl lines 230-231, identical in Codex's
   TRClassifyStripRecord) searches rootBases at every level and then
   flattens position specifications into root indices.  With frame
   squares {x, y, 1 + x + y} a strip containing only Sqrt[x] is reported
   as rank three: x matches at {1} and again inside 1 + x + y at {3,2},
   and the flattened {3,2} contributes indices 3 and 2.  A superset is
   not harmless -- it multiplies the ansatz by 2^(extra roots), demands
   a split point for roots that do not occur, and can push a genuine
   rank-3 block past the rank ceiling -- so the decision is taken on an
   exact level-1 match here, with the package census kept alongside as a
   diagnostic.  Cannot be repaired in TransportCharts.wl in this pass
   (no existing file is edited). *)
multiquadraticStripRootCensus[strip_, allRoots_List] := Module[
  {frameCensus, rootBases, radicals, matches, indices, unknown},
  frameCensus = transportChartRootIndices[strip, allRoots];
  rootBases = Together /@ (#1["Root"]^2 & /@ allRoots);
  radicals = Lookup[frameCensus, "RadicalBases", {}];
  matches[base_] := Flatten[Position[rootBases,
    candidate_ /; TrueQ[Together[base - candidate] === 0], {1},
    Heads -> False]];
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#1] === {} &];
  <|"Status" -> If[unknown === {}, "ExactRootClassification",
      "UnclassifiedRadicals"],
    "RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    "FrameCensusRootIndices" -> Lookup[frameCensus, "RootIndices", {}],
    "FrameCensusUnclassified" ->
      Lookup[frameCensus, "UnclassifiedRadicalBases", {}]|>
];

multiquadraticStripGaugeIndex[upperDimension_Integer, lowerDimension_Integer,
    gradeCount_Integer, supportCount_Integer, i_Integer, j_Integer,
    grade_Integer, monomial_Integer] :=
  ((((i - 1) lowerDimension + (j - 1)) gradeCount + grade) supportCount) + monomial;

multiquadraticStripResidueIndex[gaugeUnknownCount_Integer,
    upperDimension_Integer, lowerDimension_Integer, letter_Integer,
    i_Integer, j_Integer] :=
  gaugeUnknownCount + (((letter - 1) upperDimension + (i - 1)) lowerDimension) + j;

multiquadraticStripPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1)) lowerDimension + j;

multiquadraticStripColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

multiquadraticStripRowOrder[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" -> "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

multiquadraticStripCompileNormalizations[specifications_List, dimensions_List,
    gradeCount_Integer, support_List, oneForms_List,
    gaugeUnknownCount_Integer] := Catch[Module[
  {compiled = {}, kind, column, positions, i, j, grade, monomial, letter, value,
   unknownCount},
  unknownCount = gaugeUnknownCount + Length[oneForms] (Times @@ dimensions);
  Do[
    If[! AssociationQ[specification],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    kind = Lookup[specification, "Kind", Missing["Kind"]];
    value = Lookup[specification, "Value", Missing["Value"]];
    If[MissingQ[value],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    column = Switch[kind,
      "Column", Lookup[specification, "Column", $Failed],
      "GaugeCoefficient",
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        grade = Lookup[specification, "Grade", $Failed];
        monomial = Lookup[specification, "Monomial", $Failed];
        positions = Flatten[Position[support, monomial, {1}, Heads -> False]];
        If[! IntegerQ[i] || ! IntegerQ[j] || ! IntegerQ[grade] ||
            Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]] || grade < 0 || grade >= gradeCount,
          $Failed,
          multiquadraticStripGaugeIndex[dimensions[[1]], dimensions[[2]],
            gradeCount, Length[support], i, j, grade, First[positions]]],
      "Residue",
        letter = Lookup[specification, "Letter", $Failed];
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        If[! IntegerQ[letter] || ! IntegerQ[i] || ! IntegerQ[j] ||
            letter < 1 || letter > Length[oneForms] || i < 1 ||
            i > dimensions[[1]] || j < 1 || j > dimensions[[2]], $Failed,
          multiquadraticStripResidueIndex[gaugeUnknownCount, dimensions[[1]],
            dimensions[[2]], letter, i, j]],
      _, $Failed];
    If[! IntegerQ[column] || column < 1 || column > unknownCount,
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation",
        <|"ResolvedColumn" -> column, "UnknownCount" -> unknownCount|>]]];
    AppendTo[compiled, <|"Column" -> column, "Value" -> value, "Kind" -> kind|>],
    {specification, specifications}];
  If[! DuplicateFreeQ[Lookup[compiled, "Column", {}]],
    Throw[multiquadraticStripFailure["DuplicateNormalizationColumn"]]];
  compiled
]];

(* The context-free canonical texts of the EQUATION and the ROOTS.  Both
   the ABI payload and the compile core KEY are built from exactly these
   three, and none of them depends on the ansatz (support, one-forms,
   gauge denominator).  Splitting them out lets prepare key and build the
   compile core BEFORE it has a payload, and then hand the same texts to
   the payload instead of taking the whole-strip InputForm twice
   (2026-08-25). *)
multiquadraticStripCoreCanonicalData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, strip},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  <|"RootCanonicalSquares" -> (multiquadraticStripCanonicalText[
      Lookup[#1, "RootSquare", $Failed], rules] & /@ roots),
    "RootCanonicalExpressions" -> (multiquadraticStripCanonicalText[
      Lookup[#1, "Root", $Failed], rules] & /@ roots),
    "EquationCanonical" -> ToString[InputForm[Map[
      multiquadraticStripCanonicalText[#1, rules] &, strip, {4}]]]|>
];
multiquadraticStripCoreCanonicalData[___] := $Failed;

(* the nine-argument form is the ABI as every existing caller (and
   multiquadraticStripPreparationValidQ, which re-derives the payload to
   validate it) knows it; the tenth argument is a canonical-data
   Association a caller has already paid for *)
multiquadraticStripABIPayload[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List] :=
  multiquadraticStripABIPayload[record, roots, variables, epsilon, dimensions,
    gaugeDenominator, support, oneForms, normalizations, Automatic];

multiquadraticStripABIPayload[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List, canonicalData_] := Module[
  {rules, canonical, canonicalSquares, canonicalRoots, equationCanonical,
   payload},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  canonical = If[AssociationQ[canonicalData], canonicalData,
    multiquadraticStripCoreCanonicalData[record, roots, variables, epsilon]];
  If[! AssociationQ[canonical], Return[$Failed]];
  {canonicalSquares, canonicalRoots, equationCanonical} = Lookup[canonical,
    {"RootCanonicalSquares", "RootCanonicalExpressions", "EquationCanonical"}];
  payload = <|
    (* V2 (2026-08-23, generality audit P2): "RootSourceIndices" left the
       hashed payload.  The DECLARATION order of a basis of square
       classes is not mathematical data -- reversing {s,t,1-s-t} in the
       frame leaves the canonical roots, equations, support and field
       unchanged -- but it changed this fingerprint, so two equivalent
       caller declarations produced ABI-incompatible artifacts and no
       cache hit.  Nothing consumed the field; it survives as non-hashed
       provenance in the preparation record.  The grade ordering is
       protected by "RootCanonicalSquares" and "RootOrderingFingerprint",
       which are computed from the canonical (sorted) order. *)
    "Schema" -> "MultiquadraticStripPreparationV2",
    "EquationCanonical" -> equationCanonical,
    "EquationFingerprint" -> Hash[equationCanonical, "SHA256", "HexString"],
    "RootCanonicalSquares" -> canonicalSquares,
    "RootCanonicalExpressions" -> canonicalRoots,
    "RootFingerprints" -> Hash[#1, "SHA256", "HexString"] & /@ canonicalSquares,
    "RootOrderingFingerprint" -> Hash[canonicalSquares, "SHA256", "HexString"],
    "Dimensions" -> dimensions,
    "GaugeDenominator" -> multiquadraticStripCanonicalText[gaugeDenominator, rules],
    "GaugeSupport" -> support,
    "OneForms" -> Map[multiquadraticStripCanonicalText[#1, rules] &, oneForms, {2}],
    "Normalizations" -> Map[Join[KeyDrop[#1, "Value"],
      <|"Value" -> multiquadraticStripCanonicalText[
        Lookup[#1, "Value", $Failed], rules]|>] &, normalizations]|>;
  (* a payload that still names a context symbol is not an ABI *)
  If[! FreeQ[payload, $Failed] || ! multiquadraticStripContextFreeQ[payload],
    Return[$Failed]];
  payload
];

Options[multiquadraticStripPrepare] = {
  "OneForms" -> Automatic,
  "GaugeDenominator" -> Automatic,
  (* 2026-08-24: an extra polynomial factor of the gauge denominator, in
     the style of the rational engine's denominator options.  Automatic
     means "the norms of the algebraic letters of the alphabet actually
     used": a multiquadratic gauge acquires exactly those, and the
     Max[0, p-1] rule of multiquadraticRationalGaugeDenominator (which
     drops simple poles and never sees a norm at all) cannot produce
     them.  With no algebraic letter the factor is 1 and every existing
     caller is unchanged. *)
  "GaugeDenominatorFactor" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  (* exists for ONE caller: solveEpsFormStripMultiquadratic re-preparing
     at an ADOPTED degree offset in the same call.  The channel
     decomposition depends on the strip and the roots only -- never on the
     support -- so the channels of the first preparation are bit for bit
     the ones this one would recompute, at a measured 807 s on CF300
     (12,9).  A supplied set is shape-checked, and Automatic (the
     default) decomposes as before, so every other caller is unchanged. *)
  "ForcingChannels" -> Automatic,
  (* 2026-08-25.  True makes the forcing channels come from the SEALED,
     interned compile core (E, C and BBar decomposed and compiled once,
     keyed on the equation and the roots), which the compiler then finds
     already built.  False decomposes the forcing here and leaves E and C
     to the compiler.

     Automatic = FALSE, and that default is a MEASUREMENT, not a
     preference.  Cold, on the real CF300 (12,9) descriptor (52-letter
     ansatz, 1808 unknowns, support 100), both routes to the same
     byte-identical preparation and the same assembly fingerprints:

       CompileCore -> False   prepare 2710.9 s + compile  91.3 s = 2802.2 s
       CompileCore -> True    prepare 2810.7 s + compile  89.8 s = 2900.5 s

     Building the core early cost 99.8 s and gave back 1.5 s, because the
     duplication it was meant to remove is already gone: the compiler
     receives prepare's SEALED channels and its whole core stage is
     0.16 s of a 91.3 s compile, of which 89.0 s is the one-form
     compilation.  Pre-building E, C and every BBar channel in prepare
     therefore buys nothing on this shape and is off by default.

     It is kept, and kept correct, because it is the right structure
     where a core IS reused -- a degree-offset ladder rung, a second
     ansatz on the same equation, a re-prepare -- and because a caller
     that wants it should not have to reimplement it.  Turning it on is
     a measured decision per shape, not a default.

     The fallback is HEAD's STRUCTURE but not HEAD's cost: it goes
     through the interned decomposer, which returns exactly what
     multiquadraticStripDecomposeScalar returns and so cannot change a
     value, but decomposes each distinct entry once. *)
  "CompileCore" -> Automatic,
  "NormalizationEquations" -> {},
  "RootIndices" -> Automatic,
  (* candidate letter construction; used only when "OneForms" is
     Automatic (or when "LetterRecords" carries a set built by the
     caller in the same call) *)
  "LetterRecords" -> Automatic,
  "RegulatorSampleCount" -> 4,
  "RegulatorSamplePool" -> Automatic,
  "RowAlphabet" -> Automatic,
  "AdditionalLetters" -> {},
  "AlgebraicLetters" -> Automatic,
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2,
  (* absolute AbsoluteTime[] value; Infinity = unbounded, the default, so
     every existing caller is unchanged.  See the note at
     multiquadraticStripDeadlineCheckpoint: until 2026-08-25 this was the
     last stage of the engine outside the sector budget. *)
  "Deadline" -> Infinity,
  (* ---- intermediate persistence (2026-08-25).  None (the default)
     writes and reads nothing, so every existing caller is unchanged.
     A directory turns on BOTH: each expensive substage writes its
     sealed record and a later preparation of the SAME inputs reads it
     back instead of recomputing.  "Write" and "Read" split that for a
     driver that wants one direction only. *)
  "CheckpointDirectory" -> None,
  "CheckpointMode" -> Automatic,
  (* Automatic derives the tag from the record's Family / Sector /
     LowerSector, which is what the sector driver already names its
     strip artifacts by *)
  "CheckpointTag" -> Automatic
};

multiquadraticStripPrepare[record_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, strip, allRoots, classification, rootIndices,
   order, roots, channelForcing, suppliedChannels, oneFormData, oneForms,
   gaugeDenominator,
   letterRecords, gaugeDenominatorFactor,
   denominatorDegrees, degreeOffset, numeratorDegrees, support, dimensions,
   gradeCount, gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, normalizations, payload, fingerprint,
   coreEnabled, coreCanonical, coreDimensions, coreKey, coreConsumed = False,
   checkpointDirectory, checkpointMode, checkpointTag, checkpointRecords = {},
   checkpointRead, checkpointWrite, checkpointInputFingerprint,
   forcingCheckpointFingerprint, checkpointChannels,
   letterCheckpointFingerprint, checkpointLetters,
   denominatorCheckpointFingerprint, checkpointDenominator,
   deadline, prepareProgress, prepareBudget, prepareStop, prepareGuard,
   familyName, sectorId, lowerSectorId, startTime = AbsoluteTime[],
   pathStatisticsBefore = multiquadraticFieldPathStatistics[], pathStatistics},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripPrepare]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in solveEpsFormStripMultiquadratic *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  (* precomputed, NOT read inside prepareProgress: a pattern variable in
     the body of a delayed definition is substituted when the outer rule
     fires, which would embed the whole strip record in that definition
     (the rule TransportCharts.wl records at its own budgetProgress) *)
  {familyName, sectorId, lowerSectorId} = Lookup[record,
    {"Family", "Sector", "LowerSector"}, None];
  (* resume-safe progress: what this preparation had established when it
     stopped, so the next run can see how far the ansatz got *)
  (* The SHAPE is the engine's common typed-stop shape: the same keys
     solveEpsFormStripMultiquadratic's own budgetProgress carries, so a
     preparation stop is shape-compatible with every other stop of this
     engine (t_solver_budget checks exactly that).  The three sampling
     identifiers do not exist yet at this stage and say so honestly
     rather than being omitted. *)
  prepareProgress[] := <|
    "Family" -> familyName, "Sector" -> sectorId,
    "LowerSector" -> lowerSectorId,
    "Prime" -> Missing["NotSampled"],
    "RegulatorValue" -> Missing["NotSampled"],
    "SamplesDone" -> Missing["NotSampled"],
    "RootCount" -> If[ListQ[roots], Length[roots], Missing["NotOrdered"]],
    "ForcingDimensions" -> If[MatchQ[coreDimensions, {_Integer, _Integer}],
      coreDimensions, Missing["NotClassified"]],
    "ForcingChannelsDone" -> ListQ[channelForcing],
    "ForcingChannelSource" -> If[TrueQ[coreConsumed], "CompileCore",
      Missing["NotDecomposed"]],
    "LetterCount" -> If[MatchQ[letterRecords, {___Association}],
      Length[letterRecords], Missing["NotBuilt"]],
    "OneFormCount" -> If[MatchQ[oneForms, {} | {{_, _} ..}],
      Length[oneForms], Missing["NotBuilt"]],
    "UnknownCount" -> If[IntegerQ[unknownCount], unknownCount,
      Missing["NotBuilt"]],
    "SupportSize" -> If[ListQ[support], Length[support],
      Missing["NotBuilt"]]|>;
  prepareBudget[substage_String, extra_Association : <||>] :=
    multiquadraticStripBudgetExhausted["Preparation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[prepareProgress[], extra]];
  (* one boundary: check, and stop typed if the budget has passed *)
  prepareGuard[substage_String] :=
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      prepareStop = prepareBudget[substage]; True, False];
  If[prepareGuard["Entry"], Return[prepareStop]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] ||
      SameQ[variables[[1]], variables[[2]]] || MemberQ[variables, epsilon],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  allRoots = transportChartCurrentRoots[frame, variables];
  If[! ListQ[allRoots],
    Return[multiquadraticStripFailure["AlgebraicFrameNotWellFormed"]]];
  classification = multiquadraticStripRootCensus[strip, allRoots];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[multiquadraticStripFailure["StripContainsUndeclaredRadicals",
      <|"RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]]];
  rootIndices = Replace[OptionValue["RootIndices"],
    Automatic :> classification["RootIndices"]];
  If[! VectorQ[rootIndices, IntegerQ] || rootIndices =!= Sort[rootIndices] ||
      ! DuplicateFreeQ[rootIndices] ||
      ! SubsetQ[rootIndices, classification["RootIndices"]],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  If[Length[rootIndices] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank",
      <|"MaximumRank" -> $multiquadraticStripMaximumRootCount,
        "ActualRank" -> Length[rootIndices]|>]]];
  (* before the root order, which denests and square-class-matches every
     declared radical *)
  If[prepareGuard["RootOrder"], Return[prepareStop]];
  order = multiquadraticStripRootOrder[frame, variables, rootIndices, epsilon];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  roots = order["Roots"];
  (* the exact decomposition WITH the recompose check, so the compiler can
     reuse this result inside the same call instead of decomposing the
     forcing a second time (post-mortem item 5: the second decomposition
     was 807 s of the 4872 s compile of CF300 (12,9)) *)
  suppliedChannels = multiquadraticStripForcingChannelsAccept[
    OptionValue["ForcingChannels"], strip[[3]], roots, variables, epsilon];
  If[! MemberQ[{"NotSupplied", "Accepted"},
      Lookup[suppliedChannels, "Status", None]],
    Return[multiquadraticStripFailure[suppliedChannels["Status"],
      KeyDrop[suppliedChannels, "Status"]]]];
  (* Automatic is FALSE here and TRUE in multiquadraticStripCompile: the
     compiler's own core cache is 0.16 s and earns its keep across
     ansatz changes, while building it EARLY was measured at +99.8 s on
     CF300 (12,9).  See the option note above. *)
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> False];
  If[! MemberQ[{True, False}, coreEnabled],
    Return[multiquadraticStripFailure["InvalidPrepareCompileCoreOption",
      <|"CompileCore" -> coreEnabled|>]]];
  (* the core key needs the equation and root canonical texts and the
     forcing dimensions, none of which depends on the ansatz.  The
     dimensions are VALIDATED further down exactly where they were
     validated at HEAD: a malformed strip simply fails to key the core
     and takes the fallback, so no failure status moved. *)
  coreCanonical = multiquadraticStripCoreCanonicalData[record, roots,
    variables, epsilon];
  coreDimensions = Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]];
  (* ---- the intermediate-persistence layer of THIS preparation ------
     Resolved once, here, so that every substage below is one
     checkpointRead / checkpointWrite pair and nothing about the file
     layout leaks into the substages themselves. *)
  checkpointDirectory = OptionValue["CheckpointDirectory"];
  checkpointMode = Replace[OptionValue["CheckpointMode"],
    Automatic -> "ReadWrite"];
  If[! (checkpointDirectory === None || StringQ[checkpointDirectory]) ||
      ! MemberQ[{"ReadWrite", "Read", "Write", "None"}, checkpointMode],
    Return[multiquadraticStripFailure["InvalidPrepareCheckpointOption",
      <|"CheckpointDirectory" -> checkpointDirectory,
        "CheckpointMode" -> checkpointMode|>]]];
  checkpointTag = Replace[OptionValue["CheckpointTag"], Automatic :>
    StringJoin[Riffle[ToString /@ {Lookup[record, "Family", "family"],
      Lookup[record, "Sector", 0], Lookup[record, "LowerSector", 0]}, "_"]]];
  If[! StringQ[checkpointTag] || StringLength[checkpointTag] === 0 ||
      ! StringFreeQ[checkpointTag, {"/", "\\", ".."}],
    Return[multiquadraticStripFailure["InvalidPrepareCheckpointTag",
      <|"CheckpointTag" -> checkpointTag|>]]];
  (* the inputs EVERY substage of this preparation shares: this strip's
     canonical equation text, and the canonical root order.  A substage
     appends whatever else it consumed. *)
  checkpointInputFingerprint[substage_String, extra_] :=
    multiquadraticStripFingerprint[{substage,
      If[AssociationQ[coreCanonical],
        Lookup[coreCanonical, {"EquationCanonical", "RootCanonicalSquares",
          "RootCanonicalExpressions"}], $Failed],
      coreDimensions, extra}];
  (* read: Missing if persistence is off, this substage has no file, or
     the file exists and does not authenticate -- and in the last case
     the refusal is RECORDED, so a poisoned checkpoint is visible in the
     preparation rather than silently ignored *)
  checkpointRead[substage_String, fingerprint_] := Module[
    {file, raw, verdict},
    If[checkpointDirectory === None ||
        ! MemberQ[{"ReadWrite", "Read"}, checkpointMode],
      Return[Missing["CheckpointsDisabled"]]];
    file = multiquadraticStripPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    If[! FileExistsQ[file],
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> "PrepareCheckpointAbsent",
        "File" -> file|>];
      Return[Missing["CheckpointAbsent"]]];
    raw = multiquadraticStripArtifactLoadRaw[file,
      "FeynFacet`MultiquadraticArtifact`"];
    If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact",
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> Lookup[raw, "Status", "ReadFailed"],
        "File" -> file|>];
      Return[Missing["CheckpointUnreadable"]]];
    verdict = multiquadraticStripPrepareCheckpointAccept[raw["Value"],
      substage, fingerprint, variables, epsilon];
    AppendTo[checkpointRecords, <|"Substage" -> substage,
      "Action" -> "Read", "Status" -> Lookup[verdict, "Status", None],
      "File" -> file, "FileSHA256" -> raw["SHA256"],
      "Refusal" -> KeyDrop[verdict, {"Status", "Payload"}]|>];
    If[Lookup[verdict, "Status", None] =!= "Accepted",
      Return[Missing["CheckpointRefused"]]];
    verdict["Payload"]];
  checkpointWrite[substage_String, fingerprint_, payload_] := Module[
    {file, checkpoint, written},
    If[checkpointDirectory === None ||
        ! MemberQ[{"ReadWrite", "Write"}, checkpointMode], Return[Null]];
    checkpoint = multiquadraticStripPrepareCheckpointRecord[substage,
      fingerprint, payload, variables, epsilon];
    If[checkpoint === $Failed,
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Write", "Status" -> "PrepareCheckpointNotContextFree"|>];
      Return[Null]];
    file = multiquadraticStripPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    written = Quiet[Check[multiquadraticStripArtifactWrite[checkpoint, file],
      $Failed]];
    AppendTo[checkpointRecords, <|"Substage" -> substage,
      "Action" -> "Write",
      "Status" -> If[AssociationQ[written],
        Lookup[written, "Status", "WriteFailed"], "PrepareCheckpointWriteFailed"],
      "File" -> file,
      "FileSHA256" -> If[AssociationQ[written],
        Lookup[written, "SHA256", Missing["NoHash"]], Missing["NoHash"]]|>];
    Null];
  coreKey = If[AssociationQ[coreCanonical] &&
      MatchQ[coreDimensions, {_Integer, _Integer}] &&
      FreeQ[coreCanonical, $Failed],
    multiquadraticStripCompileCoreKeyFromParts[
      multiquadraticAlgebraABIFingerprint[],
      Hash[coreCanonical["EquationCanonical"], "SHA256", "HexString"],
      Hash[coreCanonical["RootCanonicalSquares"], "SHA256", "HexString"],
      coreCanonical["RootCanonicalSquares"],
      coreCanonical["RootCanonicalExpressions"], coreDimensions,
      variables, epsilon],
    $Failed];
  (* before the forcing decomposition -- the stage that made this
     coverage necessary *)
  If[prepareGuard["ForcingChannels"], Return[prepareStop]];
  (* CHECKPOINT (2026-08-25).  The payload of the forcing checkpoint IS
     the V2 sealed forcing-channel record, so a checkpoint read is
     authenticated by exactly the code path an in-memory reuse is: the
     envelope proves the file belongs to this strip and this source, and
     the seal inside it proves the channels are the decomposition of
     THIS forcing.  A mutated channel fails the inner seal even if the
     envelope is rebuilt around it. *)
  forcingCheckpointFingerprint =
    checkpointInputFingerprint["ForcingChannels", {}];
  checkpointChannels = If[suppliedChannels["Status"] === "Accepted",
    Missing["ChannelsSupplied"],
    Module[{stored = checkpointRead["ForcingChannels",
        forcingCheckpointFingerprint], accept},
      If[MissingQ[stored], Missing["NoCheckpoint"],
        accept = multiquadraticStripForcingChannelsAccept[stored, strip[[3]],
          roots, variables, epsilon];
        AppendTo[checkpointRecords, <|"Substage" -> "ForcingChannels",
          "Action" -> "Seal", "Status" -> Lookup[accept, "Status", None]|>];
        If[Lookup[accept, "Status", None] === "Accepted", accept["Channels"],
          Missing["CheckpointSealRefused"]]]]];
  channelForcing = Which[
    suppliedChannels["Status"] === "Accepted", suppliedChannels["Channels"],
    ! MissingQ[checkpointChannels],
      multiquadraticStripStageMark["prepare: forcing channel decomposition",
        <|"source" -> "Checkpoint", "forcing" -> coreDimensions|>];
      checkpointChannels,
    True,
    Module[{stage = "prepare: forcing channel decomposition", seconds = 0.,
        built = $Failed},
      multiquadraticStripStageStart[stage,
        <|"family" -> Lookup[record, "Family", None],
          "sector" -> Lookup[record, "Sector", None],
          "lower" -> Lookup[record, "LowerSector", None],
          "forcing" -> coreDimensions, "rank" -> Length[roots],
          "grades" -> 2^Length[roots],
          "route" -> If[TrueQ[coreEnabled] && coreKey =!= $Failed,
            "CompileCore", "Independent"]|>];
      (* the VALUE pools are per call at both ends, exactly as in the
         compiler: they make one call decompose each unique value once
         and are never carried between calls *)
      multiquadraticStripInternReset["Scalar"];
      multiquadraticStripInternReset["Rational"];
      (* the decomposition loops read the deadline per entry and leave by
         Throw; Block restores the dynamic value on every exit path,
         including the Throw *)
      built = Catch[
        Block[{$multiquadraticStripActiveDeadline = deadline},
          {seconds, built} = AbsoluteTiming[
            If[TrueQ[coreEnabled] && coreKey =!= $Failed,
              Module[{core = multiquadraticStripCompileCoreRecord[strip, roots,
                  variables, epsilon, Missing["NotSupplied"], coreKey, True]},
                If[AssociationQ[core],
                  Lookup[Lookup[core, "BBar", <||>], "Channels", $Failed],
                  $Failed]],
              $Failed]];
          coreConsumed = built =!= $Failed && FreeQ[built, $Failed];
          If[! coreConsumed,
            {seconds, built} = AbsoluteTiming[
              multiquadraticStripDecomposeForcing[strip[[3]], roots]]];
          built],
        $multiquadraticStripDeadlineTag,
        Function[{payload, tag},
          prepareStop = prepareBudget[
            Lookup[payload, "Substage", "ForcingChannels"],
            KeyDrop[payload, "Substage"]];
          $Failed]];
      multiquadraticStripInternReset["Scalar"];
      multiquadraticStripInternReset["Rational"];
      multiquadraticStripStageDone[stage,
        <|"seconds" -> N[seconds],
          "source" -> Which[AssociationQ[prepareStop], "BudgetExhausted",
            coreConsumed, "CompileCore", True, "Independent"]|>];
      built]];
  If[AssociationQ[prepareStop], Return[prepareStop]];
  If[! FreeQ[channelForcing, $Failed],
    Return[multiquadraticStripFailure["ForcingChannelDecompositionFailed"]]];
  (* written only when this call actually decomposed: a checkpoint that
     was just read back is not rewritten, and a supplied decomposition
     belongs to its caller, not to this strip's persistence *)
  If[suppliedChannels["Status"] =!= "Accepted" && MissingQ[checkpointChannels],
    checkpointWrite["ForcingChannels", forcingCheckpointFingerprint,
      multiquadraticStripForcingChannelRecord[channelForcing, strip[[3]],
        roots, variables, epsilon]]];
  letterRecords = OptionValue["LetterRecords"];
  oneFormData = OptionValue["OneForms"];
  (* before the candidate-letter construction, a single opaque call *)
  If[prepareGuard["CandidateLetters"], Return[prepareStop]];
  If[oneFormData === Automatic,
    If[! MatchQ[letterRecords, {___Association}],
      (* CHECKPOINT: the whole candidate-letter record, keyed on the
         strip, the root order, the letter-construction options and the
         row alphabet the record supplies -- the complete input of
         multiquadraticStripCandidateLetters. *)
      letterCheckpointFingerprint = checkpointInputFingerprint[
        "CandidateLetters",
        {OptionValue["RegulatorSampleCount"],
         OptionValue["RegulatorSamplePool"],
         multiquadraticStripFingerprint[OptionValue["RowAlphabet"] /.
           multiquadraticStripCanonicalRules[variables, epsilon]],
         multiquadraticStripFingerprint[OptionValue["AdditionalLetters"] /.
           multiquadraticStripCanonicalRules[variables, epsilon]],
         multiquadraticStripFingerprint[OptionValue["AlgebraicLetters"] /.
           multiquadraticStripCanonicalRules[variables, epsilon]],
         OptionValue["MaximumNormFactors"],
         OptionValue["MaximumNormExponent"],
         Lookup[record, {"Sector", "LowerSector"}, None],
         multiquadraticStripFingerprint[
           Replace[Lookup[record, "StripSolvers", {}], Except[_List] :> {}] /.
             multiquadraticStripCanonicalRules[variables, epsilon]]}];
      checkpointLetters = checkpointRead["CandidateLetters",
        letterCheckpointFingerprint];
      If[! MissingQ[checkpointLetters] &&
          Lookup[checkpointLetters, "Status", None] ===
            "MultiquadraticCandidateLettersV1",
        multiquadraticStripStageMark["prepare: candidate letters",
          <|"source" -> "Checkpoint",
            "letters" -> Length[Lookup[checkpointLetters, "LetterRecords",
              {}]]|>];
        letterRecords = checkpointLetters,
        checkpointLetters = Missing["NoCheckpoint"];
        multiquadraticStripStageStart["prepare: candidate letters",
          <|"family" -> Lookup[record, "Family", None],
            "sector" -> Lookup[record, "Sector", None],
            "lower" -> Lookup[record, "LowerSector", None],
            "rank" -> Length[roots], "forcing" -> coreDimensions|>];
        letterRecords = multiquadraticStripCandidateLetters[strip, roots,
          variables, epsilon, record,
          "RegulatorSampleCount" -> OptionValue["RegulatorSampleCount"],
          "RegulatorSamplePool" -> OptionValue["RegulatorSamplePool"],
          "RowAlphabet" -> OptionValue["RowAlphabet"],
          "AdditionalLetters" -> OptionValue["AdditionalLetters"],
          "AlgebraicLetters" -> OptionValue["AlgebraicLetters"],
          "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
          "MaximumNormExponent" -> OptionValue["MaximumNormExponent"]];
        multiquadraticStripStageDone["prepare: candidate letters",
          <|"status" -> Lookup[letterRecords, "Status", None],
            "letters" -> Length[Lookup[letterRecords, "LetterRecords", {}]]|>]];
      If[Lookup[letterRecords, "Status", None] =!=
          "MultiquadraticCandidateLettersV1",
        Return[If[AssociationQ[letterRecords], letterRecords,
          multiquadraticStripFailure["OneFormBasisFailed"]]]];
      If[MissingQ[checkpointLetters],
        checkpointWrite["CandidateLetters", letterCheckpointFingerprint,
          letterRecords]];
      oneFormData = letterRecords;
      letterRecords = oneFormData["LetterRecords"],
      oneFormData = <|"OneForms" -> Lookup[letterRecords, "OneForm", {}],
        "DeduplicatedCount" -> Length[letterRecords]|>]];
  oneForms = If[AssociationQ[oneFormData],
    Lookup[oneFormData, "OneForms", $Failed], oneFormData];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  (* after the alphabet is fixed and before the gauge denominator, which
     factors the norms of every algebraic letter actually used *)
  If[prepareGuard["GaugeDenominator"], Return[prepareStop]];
  (* CHECKPOINT: the norm factorization of every algebraic letter plus
     the merge with the rational denominator.  Its inputs are the
     alphabet actually used and the two denominator options. *)
  denominatorCheckpointFingerprint = checkpointInputFingerprint[
    "GaugeDenominator",
    {multiquadraticStripFingerprint[
       If[MatchQ[letterRecords, {___Association}], letterRecords, {}] /.
         multiquadraticStripCanonicalRules[variables, epsilon]],
     multiquadraticStripFingerprint[OptionValue["GaugeDenominatorFactor"] /.
       multiquadraticStripCanonicalRules[variables, epsilon]],
     multiquadraticStripFingerprint[OptionValue["GaugeDenominator"] /.
       multiquadraticStripCanonicalRules[variables, epsilon]]}];
  checkpointDenominator = checkpointRead["GaugeDenominator",
    denominatorCheckpointFingerprint];
  If[MatchQ[checkpointDenominator, {_, _}],
    multiquadraticStripStageMark["prepare: gauge denominator",
      <|"source" -> "Checkpoint"|>];
    {gaugeDenominatorFactor, gaugeDenominator} = checkpointDenominator,
    checkpointDenominator = Missing["NoCheckpoint"];
    gaugeDenominatorFactor = Replace[OptionValue["GaugeDenominatorFactor"],
      Automatic :> If[MatchQ[letterRecords, {___Association}],
        multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1]];
    gaugeDenominator = Replace[OptionValue["GaugeDenominator"],
      Automatic :> multiquadraticStripMergeGaugeDenominator[
        multiquadraticRationalGaugeDenominator[channelForcing, variables],
        gaugeDenominatorFactor, variables]]];
  If[TrueQ[Together[gaugeDenominatorFactor] === 0] ||
      ! FreeQ[gaugeDenominatorFactor,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorFactorNotRational",
      <|"GaugeDenominatorFactor" -> gaugeDenominatorFactor|>]]];
  If[MissingQ[checkpointDenominator],
    checkpointWrite["GaugeDenominator", denominatorCheckpointFingerprint,
      {gaugeDenominatorFactor, gaugeDenominator}]];
  If[TrueQ[Together[gaugeDenominator] === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset"]]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  If[support === Automatic,
    support = Flatten[Table[{i, j}, {i, 0, numeratorDegrees[[1]]},
      {j, 0, numeratorDegrees[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticStripFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[strip[[3]]] =!= Prepend[dimensions, 2],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  If[Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticStripFailure["InvalidDiagonalDimensions"]]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  normalizations = multiquadraticStripCompileNormalizations[
    OptionValue["NormalizationEquations"], dimensions, gradeCount, support,
    oneForms, gaugeUnknownCount];
  If[! ListQ[normalizations], Return[normalizations]];
  (* before the ABI payload, the last opaque stage of the preparation *)
  If[prepareGuard["ABIPayload"], Return[prepareStop]];
  (* the canonical equation/root texts were already paid for above, when
     the compile core was keyed; handing them over is what keeps the
     whole-strip InputForm to ONE pass *)
  payload = multiquadraticStripABIPayload[record, roots, variables, epsilon,
    dimensions, gaugeDenominator, support, oneForms, normalizations,
    coreCanonical];
  If[payload === $Failed,
    Return[multiquadraticStripFailure["ContextSensitiveStripABI"]]];
  fingerprint = multiquadraticStripFingerprint[payload];
  pathStatistics = multiquadraticFieldPathStatisticsDelta[pathStatisticsBefore,
    multiquadraticFieldPathStatistics[]];
  <|"Status" -> "PreparedMultiquadraticStripV1",
    "PreparationSchema" -> payload["Schema"],
    "Record" -> record, "Frame" -> frame,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Roots" -> roots, "RootCount" -> Length[roots],
    "RootIndices" -> rootIndices,
    "RootCensus" -> KeyTake[classification, {"RootIndices", "RadicalBases",
      "FrameCensusRootIndices", "FrameCensusUnclassified"}],
    (* provenance only: which declaration slot each canonical root came
       from.  Deliberately NOT part of the hashed ABI payload (V2). *)
    "RootSourceIndices" -> order["SourceIndices"],
    "RootFingerprints" -> order["RootFingerprints"],
    "RootOrderingFingerprint" -> order["OrderingFingerprint"],
    "RootSquares" -> Lookup[roots, "RootSquare", {}],
    "OneForms" -> oneForms, "OneFormMetadata" -> oneFormData,
    (* the letter provenance and the exact forcing channels of THIS call;
       neither is part of the hashed ABI payload, and the compiler reuses
       the channels rather than decomposing the forcing again *)
    "LetterRecords" -> If[MatchQ[letterRecords, {___Association}],
      letterRecords, Missing["LettersSuppliedAsOneForms"]],
    "AlgebraicLetterCount" -> If[MatchQ[letterRecords, {___Association}],
      Count[letterRecords, item_ /; Lookup[item, "Kind", None] === "Algebraic"],
      Missing["LettersSuppliedAsOneForms"]],
    "GaugeDenominatorFactor" -> Together[gaugeDenominatorFactor],
    (* sealed, not bare (Codex 04:30 P2): the record carries the
       fingerprint of the forcing / root order / variables / regulator it
       decomposes, so a consumer can fail closed instead of trusting a
       shape *)
    "ForcingChannels" -> multiquadraticStripForcingChannelRecord[
      channelForcing, strip[[3]], roots, variables, epsilon],
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeSupport" -> support, "Dimensions" -> dimensions,
    "GradeCount" -> gradeCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "Normalizations" -> normalizations,
    "ColumnOrder" -> multiquadraticStripColumnOrder[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> multiquadraticStripRowOrder[dimensions, gradeCount],
    "AlgebraABIFingerprint" -> multiquadraticAlgebraABIFingerprint[],
    (* channel-decomposition telemetry of THIS preparation, not of the
       process: the scalar-local root-free fast path count and the
       algebraic (field reduction + inversion) count *)
    "RootFreeFastPathCount" -> pathStatistics["RootFreeFastPathCount"],
    "ChannelPathStatistics" -> pathStatistics,
    (* what this preparation persisted and what it read back, with the
       typed verdict of every authentication.  Telemetry: NOT part of
       the hashed ABI payload and not part of the preparation
       fingerprint, so a checkpointed preparation is byte-identical to
       an uncheckpointed one everywhere the ABI is compared. *)
    "PrepareCheckpoints" -> checkpointRecords,
    "ABIPayload" -> payload, "ABIFingerprint" -> fingerprint|>
];
multiquadraticStripPrepare[___] :=
  multiquadraticStripFailure["InvalidPrepareArguments"];

multiquadraticStripPreparationValidQ[preparation_Association] := Module[
  {payload, roots, dimensions, gradeCount, gaugeUnknownCount, residueUnknownCount},
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticStripV1",
    Return[False]];
  roots = Lookup[preparation, "Roots", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  If[! ListQ[roots] || ! MatchQ[dimensions, {_Integer, _Integer}], Return[False]];
  payload = multiquadraticStripABIPayload[preparation["Record"], roots,
    preparation["Variables"], preparation["Regulator"], dimensions,
    preparation["GaugeDenominator"], preparation["GaugeSupport"],
    preparation["OneForms"], preparation["Normalizations"]];
  If[payload === $Failed, Return[False]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount
    Length[preparation["GaugeSupport"]];
  residueUnknownCount = Length[preparation["OneForms"]] (Times @@ dimensions);
  TrueQ[
    payload === Lookup[preparation, "ABIPayload", Missing["Payload"]] &&
    Lookup[preparation, "ABIFingerprint", Missing["Fingerprint"]] ===
      multiquadraticStripFingerprint[payload] &&
    Lookup[preparation, "AlgebraABIFingerprint", Missing["Algebra"]] ===
      multiquadraticAlgebraABIFingerprint[] &&
    Lookup[preparation, "RootOrderingFingerprint", Missing["RootOrder"]] ===
      payload["RootOrderingFingerprint"] &&
    Lookup[preparation, "RootCount", Missing["RootCount"]] === Length[roots] &&
    Lookup[preparation, "GradeCount", Missing["GradeCount"]] === gradeCount &&
    Lookup[preparation, "GaugeUnknownCount", Missing["Gauge"]] ===
      gaugeUnknownCount &&
    Lookup[preparation, "ResidueUnknownCount", Missing["Residue"]] ===
      residueUnknownCount &&
    Lookup[preparation, "UnknownCount", Missing["Unknown"]] ===
      gaugeUnknownCount + residueUnknownCount &&
    Lookup[preparation, "EquationsPerPoint", Missing["Equations"]] ===
      gradeCount 2 (Times @@ dimensions)]
];

(* ------------------------------------------------------------------ *)
(* Exact channel compilation into a sparse x/y polynomial ABI           *)
(* ------------------------------------------------------------------ *)

(* Terms sharing an x/y monomial are grouped; the row keeps the exact
   coefficients of eps^0..eps^K, so one compilation serves every
   regulator value and every prime. *)
multiquadraticStripCompilePolynomial[polynomial_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {vars = Append[variables, epsilon], expanded, rules, groups, xExponents,
   yExponents, maximumEpsilonDegree, coefficientRows},
  expanded = Expand[polynomial];
  If[! PolynomialQ[expanded, vars], Return[$Failed]];
  rules = CoefficientRules[expanded, vars];
  If[rules === {}, Return[<|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> {}, "YExponents" -> {}, "EpsilonCoefficientRows" -> {}|>]];
  If[! AllTrue[Last /@ rules, IntegerQ[#1] || Head[#1] === Rational &],
    Return[$Failed]];
  maximumEpsilonDegree = Max[rules[[All, 1, 3]]];
  If[maximumEpsilonDegree > $multiquadraticStripMaximumEpsilonDegree,
    Return[$Failed]];
  groups = GatherBy[rules, First[#1][[1 ;; 2]] &];
  xExponents = groups[[All, 1, 1, 1]];
  yExponents = groups[[All, 1, 1, 2]];
  coefficientRows = Table[
    Module[{row = ConstantArray[0, Max[group[[All, 1, 3]]] + 1]},
      Do[row[[rule[[1, 3]] + 1]] += rule[[2]], {rule, group}]; row],
    {group, groups}];
  <|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> Developer`ToPackedArray[xExponents],
    "YExponents" -> Developer`ToPackedArray[yExponents],
    "EpsilonCoefficientRows" -> coefficientRows|>
];

multiquadraticStripCompileRational[expression_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[{rational, numerator, denominator},
  rational = Together[expression];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = multiquadraticStripCompilePolynomial[Numerator[rational],
    variables, epsilon];
  denominator = multiquadraticStripCompilePolynomial[Denominator[rational],
    variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1", "Numerator" -> numerator,
    "Denominator" -> denominator|>
];

multiquadraticStripDecomposeScalar[expression_, roots_List] := Module[
  {channels, reconstructed},
  channels = multiquadraticFieldDecompose[expression, roots];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[roots] ||
      MemberQ[channels, $Failed], Return[$Failed]];
  reconstructed = multiquadraticFieldCompose[channels, roots];
  If[! TrueQ[Together[reconstructed - expression] === 0], Return[$Failed]];
  channels
];

multiquadraticStripCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Module[{channels, compiled},
  channels = Map[multiquadraticStripDecomposeScalar[#1, roots] &, tensor,
    {scalarLevel}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[multiquadraticStripCompileRational[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* ------------------------------------------------------------------ *)
(* The compile architecture (2026-08-25)                                *)
(* ------------------------------------------------------------------ *)

(* Source: Codex's Q1 answer,
   External/CodexExchange/triple_root_cf300_129_2026-08-24/
   codex_response_to_fable_cf300_129_2026-08-24.md, on a compile
   measured at 4872 s against a 0.7 s affine solve on CF300 (12,9).
   Five changes, in Codex's order:

     1 an immutable compiled equation CORE (E, C, BBar, root squares and
       their log derivatives) keyed on the equation, the roots and the
       chart symbols only, plus a separately keyed gauge-denominator
       record.  Neither depends on the ansatz, so a support or
       DegreeOffset change compiles NOTHING and an exact-prefix alphabet
       extension compiles only the suffix (Codex's measured rebind
       evidence: 12 s against 691 s for a fresh compile);

     2 interned exact scalars and channel values: a hash bucket with a
       SameQ collision check, so each unique value is decomposed and
       compiled once.  The zero channel of a 2^r grade vector, and the
       zero entries of a sparse E/C/BBar, are the common case;

     3 compact letter channels.  For a letter L = A + B r_m the one-form
       dlog L is built from the LETTER's own grade channels, its
       derivative in the grade basis and the norm A^2 - B^2 delta_m; the
       expanded D[L]/L tree is never decomposed.  That tree is the
       measured expensive object (the forcing-dlog letters carry 10^4 to
       10^5 leaves).  A general multigrade letter takes the same route
       through the existing field multiplication/inversion ABI;

     4 the canonical rational pair returned by the field decomposition
       feeds CoefficientRules directly; the second Together (a
       multivariate GCD of two large polynomials, for nothing) is gone;

     5 the remaining unique one-form suffix may be brokered into 2 to 4
       IMMUTABLE compile shards.  Naive parallelism duplicates work and
       peak memory, so this is opt-in and last.

   Nothing here changes what is compiled: every acceptance the old
   compiler made (exact decomposition with a recompose check, exact
   inverse product check, polynomial shape checks) is made here, and the
   compact letter path is admitted only when the letter record PROVES
   the stored one-form is the dlog of the record's letter. *)

ClearAll[
  multiquadraticStripInternReset, multiquadraticStripIntern,
  multiquadraticStripInternValidQ,
  multiquadraticStripInternProbe, multiquadraticStripInternStatistics,
  multiquadraticStripCompileCacheClear,
  multiquadraticStripCompileRationalFromPair,
  multiquadraticStripCompileRationalCanonical,
  multiquadraticStripDecomposeScalarInterned,
  multiquadraticStripCompileRationalInterned,
  multiquadraticStripCompileTensorInterned,
  multiquadraticStripCompactInverse, multiquadraticStripLetterChannelPair,
  multiquadraticStripCompileOneFormEntry, multiquadraticStripCompileOneForms,
  multiquadraticStripCompileShardTask,
  multiquadraticStripCompileCoreKey, multiquadraticStripCompileCoreKeyFromParts,
  multiquadraticStripCompileCoreRecord,
  multiquadraticStripCompileDenominatorRecord,
  multiquadraticStripCompileLegacyCore,
  multiquadraticStripCompileLegacyDenominator,
  $multiquadraticStripInternPools, $multiquadraticStripInternCounters,
  $multiquadraticStripInternCounterNames,
  $multiquadraticStripPoolEntryLimit, $multiquadraticStripCompileShardMinimum
];

$multiquadraticStripInternPools = <||>;
$multiquadraticStripInternCounters = <||>;

(* "Scalar" and "Rational" are VALUE pools, reset at both ends of a
   compile call: they exist to make one call compile each unique value
   once, and holding them would grow a long-lived pool kernel without
   bound.  "Core", "GaugeDenominator" and "OneForm" are the persistent
   pools -- they ARE the core/ansatz split -- and are bounded by entry
   count; a pool at its cap starts again rather than growing.

   BYTE BOUNDS (2026-08-25, Codex 14:30 "persistent cache memory bound").
   An entry count is not a memory bound: one CF300-sized compile core is
   hundreds of megabytes and two of them are the whole ceiling, while
   512 small one-forms are nothing.  Each pool therefore also declares a
   MEASURED ByteCount ceiling, and an OVERSIZE value -- one that alone
   exceeds the pool's own oversize allowance -- BYPASSES the cache
   instead of evicting it: returning it to the caller uncached costs one
   recomputation, while admitting it would flush every entry the pool
   holds to store something that cannot be held anyway.  ByteCount is
   measured once per admitted value; it is a traversal, and it is taken
   only on a MISS, never on a hit. *)
$multiquadraticStripPoolEntryLimit = <|
  "Core" -> 2, "GaugeDenominator" -> 16, "OneForm" -> 512|>;

(* the pool's total measured ByteCount ceiling *)
$multiquadraticStripPoolByteLimit = <|
  "Core" -> 2. 10^9, "GaugeDenominator" -> 2. 10^8, "OneForm" -> 1. 10^9|>;

(* a single value above this is never admitted: it bypasses the pool and
   the pool keeps what it already holds.  Automatic = the pool's own byte
   ceiling, i.e. "no single value may fill the pool by itself". *)
$multiquadraticStripPoolOversizeBytes = <|
  "Core" -> Automatic, "GaugeDenominator" -> Automatic,
  "OneForm" -> Automatic|>;

multiquadraticStripInternValueBytes[value_] := N[ByteCount[value]];

(* below this many uncached one-forms a shard cannot pay for its own
   serialization and kernel round trip *)
$multiquadraticStripCompileShardMinimum = 8;

(* Both pools are FLAT Associations keyed by {pool, hash} and {pool,
   counter}: a one-level Part assignment on a symbol holding an
   Association is the only update form with a guaranteed constant-time
   semantics, and the compile does thousands of these per call. *)
$multiquadraticStripInternCounterNames = {"Hits", "Misses", "Collisions",
  "Entries", "Resets", "Rejected", "Bytes", "Oversize"};

multiquadraticStripInternReset[pool_String] := (
  $multiquadraticStripInternPools = KeySelect[$multiquadraticStripInternPools,
    First[#1] =!= pool &];
  Scan[($multiquadraticStripInternCounters[[Key[{pool, #1}]]] = 0) &,
    $multiquadraticStripInternCounterNames];);

multiquadraticStripInternStatistics[] := Module[{pools},
  pools = DeleteDuplicates[First /@ Keys[$multiquadraticStripInternCounters]];
  Association[Table[pool -> Association[Table[
      name -> Lookup[$multiquadraticStripInternCounters, Key[{pool, name}], 0],
      {name, $multiquadraticStripInternCounterNames}]],
    {pool, pools}]]
];

multiquadraticStripCompileCacheClear[] := (
  $multiquadraticStripInternPools = <||>;
  $multiquadraticStripInternCounters = <||>;
  <|"Status" -> "MultiquadraticStripCompileCachesCleared"|>);

(* Present without computing: the shard planner needs to know which
   one-forms the pool already holds before it decides what to farm. *)
multiquadraticStripInternProbe[pool_String, key_] := Module[{bucket, hit},
  bucket = Lookup[$multiquadraticStripInternPools, Key[{pool, Hash[key]}], {}];
  hit = SelectFirst[bucket, SameQ[First[#1], key] &, None];
  If[hit === None, Missing["NotInterned"], Last[hit]]
];

(* Hash bucket plus SameQ collision check (Codex item 2).  The hash is
   the expression hash, never a canonical text: this pool is session
   local, it is never serialized and it is never fingerprinted, so its
   context sensitivity is not an ABI question.  SameQ decides, so a hash
   collision merges nothing; two mathematically equal but structurally
   different values simply miss, which costs time and never correctness. *)
(* A NEGATIVE result is never cached (Codex P1, 2026-08-25).  The pools
   used to store whatever compute[] returned, $Failed included, and the
   early-core construction in prepare made that reachable on the public
   path: an early core that failed to build stored $Failed under the core
   key, prepare fell back to its own decomposition and succeeded, and the
   compiler then HIT the cached $Failed and returned
   ExactChannelDecompositionFailed on a block that was perfectly
   solvable.  A failed build is now recomputed rather than remembered --
   the cost of a repeated failure, against a poisoned cache that fails a
   whole solve.

   Per-pool validity is a predicate, not a bare $Failed test: a Core
   record whose five members are not all present is malformed even
   though it contains no $Failed. *)
multiquadraticStripInternValidQ["Core", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"E", "C", "BBar", "RootSquares", "RootLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
multiquadraticStripInternValidQ["GaugeDenominator", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"GaugeDenominator", "GaugeLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
(* the OneForm pool holds compiled entries only.  A typed REFUSAL (an
   Association carrying "Status") is a negative result and is never
   interned -- the same rule the Core pool's $Failed refusal follows. *)
multiquadraticStripInternValidQ["OneForm", value_] :=
  AssociationQ[value] && ! KeyExistsQ[value, "Status"] &&
    FreeQ[value, $Failed] &&
    AllTrue[{"Channels", "Compiled", "Path"}, KeyExistsQ[value, #1] &];
multiquadraticStripInternValidQ[_String, value_] :=
  value =!= $Failed && FreeQ[value, $Failed];

multiquadraticStripIntern[pool_String, key_, compute_] := Module[
  {hash, bucket, hit, value, limit, byteLimit, oversizeLimit, bytes,
   poolBytes, hits, misses, resets, oversize, counter},
  counter[name_String] :=
    Lookup[$multiquadraticStripInternCounters, Key[{pool, name}], 0];
  hash = Hash[key];
  bucket = Lookup[$multiquadraticStripInternPools, Key[{pool, hash}], {}];
  hit = SelectFirst[bucket, SameQ[First[#1], key] &, None];
  If[hit =!= None,
    $multiquadraticStripInternCounters[[Key[{pool, "Hits"}]]] =
      counter["Hits"] + 1;
    Return[Last[hit]]];
  value = compute[];
  (* refused BEFORE any counter or bucket is touched: a rejected value
     leaves the pool exactly as it found it *)
  If[! multiquadraticStripInternValidQ[pool, value],
    $multiquadraticStripInternCounters[[Key[{pool, "Rejected"}]]] =
      counter["Rejected"] + 1;
    Return[value]];
  limit = Lookup[$multiquadraticStripPoolEntryLimit, pool, Infinity];
  byteLimit = Lookup[$multiquadraticStripPoolByteLimit, pool, Infinity];
  oversizeLimit = Replace[
    Lookup[$multiquadraticStripPoolOversizeBytes, pool, Automatic],
    Automatic :> byteLimit];
  (* the measurement is taken ONCE, on a miss, on the value that is about
     to be admitted -- never on a hit, and never on the pool as a whole *)
  bytes = multiquadraticStripInternValueBytes[value];
  (* OVERSIZE BYPASS.  A value that alone exceeds the pool's allowance is
     returned uncached: it is one recomputation against flushing every
     entry the pool holds for something the pool cannot hold. *)
  If[NumericQ[oversizeLimit] && bytes > oversizeLimit,
    $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] =
      counter["Misses"] + 1;
    $multiquadraticStripInternCounters[[Key[{pool, "Oversize"}]]] =
      counter["Oversize"] + 1;
    Return[value]];
  poolBytes = counter["Bytes"];
  If[counter["Entries"] >= limit ||
      (NumericQ[byteLimit] && poolBytes + bytes > byteLimit),
    (* bounded on BOTH axes: a pool at either cap starts again rather
       than growing without bound in a long-lived pool kernel *)
    hits = counter["Hits"]; misses = counter["Misses"];
    resets = counter["Resets"]; oversize = counter["Oversize"];
    multiquadraticStripInternReset[pool];
    $multiquadraticStripInternCounters[[Key[{pool, "Hits"}]]] = hits;
    $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] = misses;
    $multiquadraticStripInternCounters[[Key[{pool, "Oversize"}]]] = oversize;
    $multiquadraticStripInternCounters[[Key[{pool, "Resets"}]]] = resets + 1;
    poolBytes = 0;
    bucket = {}];
  $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] =
    counter["Misses"] + 1;
  If[bucket =!= {},
    $multiquadraticStripInternCounters[[Key[{pool, "Collisions"}]]] =
      counter["Collisions"] + 1];
  $multiquadraticStripInternPools[[Key[{pool, hash}]]] = Append[bucket, {key, value}];
  $multiquadraticStripInternCounters[[Key[{pool, "Entries"}]]] =
    counter["Entries"] + 1;
  $multiquadraticStripInternCounters[[Key[{pool, "Bytes"}]]] =
    poolBytes + bytes;
  value
];

(* Codex item 4.  multiquadraticFieldDecompose ends in Together /@, so
   every channel it returns IS a canonical rational pair and
   Numerator/Denominator are exactly the pair CoefficientRules needs.
   The split is accepted only when both halves are genuine polynomials
   in {x, y, eps}; anything else falls back to the conservative Together
   path, so a caller that hands in a non-canonical expression cannot be
   given a wrong pair. *)
multiquadraticStripCompileRationalFromPair[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {compiledNumerator, compiledDenominator},
  If[! FreeQ[expression, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  compiledNumerator = multiquadraticStripCompilePolynomial[
    Numerator[expression], variables, epsilon];
  If[compiledNumerator === $Failed, Return[$Failed]];
  compiledDenominator = multiquadraticStripCompilePolynomial[
    Denominator[expression], variables, epsilon];
  If[compiledDenominator === $Failed ||
      compiledDenominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1",
    "Numerator" -> compiledNumerator, "Denominator" -> compiledDenominator|>
];

multiquadraticStripCompileRationalCanonical[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{fast},
  fast = multiquadraticStripCompileRationalFromPair[expression, variables,
    epsilon];
  If[fast =!= $Failed, fast,
    multiquadraticStripCompileRational[expression, variables, epsilon]]
];

(* The ROOTS are part of the key, not context.  The same scalar is
   decomposed at two different ranks inside ONE compile: the root
   squares and the root/gauge log derivatives are decomposed over the
   EMPTY root set (they are rational by construction), while E, C, BBar
   and the one-forms are decomposed over the declared roots.  Keying on
   the expression alone let 1/x -- the log derivative of the root square
   delta = x, and equally the x-component of dlog x -- return a rank-0
   channel vector of width 1 where the grade ABI demands width 2^r.
   Found 2026-08-25 by t_multiquadratic_strip_solve. *)
multiquadraticStripDecomposeScalarInterned[expression_, roots_List] :=
  multiquadraticStripIntern["Scalar", {roots, expression},
    Function[multiquadraticStripDecomposeScalar[expression, roots]]];

multiquadraticStripCompileRationalInterned[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticStripIntern["Rational", expression,
    Function[multiquadraticStripCompileRationalCanonical[expression,
      variables, epsilon]]];

(* prepare's INDEPENDENT forcing decomposition -- the fallback taken when
   the compile core cannot be built or is switched off.  It differs from
   the HEAD expression Map[multiquadraticStripDecomposeScalar[...], ...,
   {3}] in two ways that cannot change its value: the interned decomposer
   (which memoizes multiquadraticStripDecomposeScalar and returns exactly
   its result, so the repeated zero entries of a sparse forcing are
   decomposed once) and one rate-limited progress line per interval. *)
multiquadraticStripDecomposeForcing[bbar_, roots_List] := Module[
  {stage = "prepare: forcing channel decomposition", total, done = 0,
   started = AbsoluteTime[]},
  total = Quiet[Check[Times @@ Take[Dimensions[bbar], UpTo[3]], 0]];
  Map[Function[entry,
      done++;
      multiquadraticStripDeadlineCheckpoint["ForcingChannels",
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripDecomposeScalarInterned[entry, roots]],
    bbar, {3}]
];

multiquadraticStripCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticStripCompileTensorInterned[tensor, scalarLevel, roots,
    variables, epsilon, None];

(* "stage" is a telemetry label only.  With a label the decomposition
   emits ONE rate-limited progress line per interval naming the entry it
   has reached; without one (the root squares and log derivatives, which
   are a handful of scalars) it is silent.  Nothing else differs, so the
   returned record is byte-identical either way. *)
multiquadraticStripCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    stage_] := Module[
  {channels, compiled, total, done = 0, started = AbsoluteTime[], decompose},
  If[StringQ[stage],
    total = Times @@ Take[Dimensions[tensor], UpTo[scalarLevel]];
    multiquadraticStripStageStart[stage,
      <|"entries" -> total, "rank" -> Length[roots],
        "grades" -> 2^Length[roots]|>];
    decompose[entry_] := (
      done++;
      multiquadraticStripDeadlineCheckpoint[stage,
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripDecomposeScalarInterned[entry, roots]),
    decompose[entry_] := (
      multiquadraticStripDeadlineCheckpoint["CompileTensor", <||>];
      multiquadraticStripDecomposeScalarInterned[entry, roots])];
  channels = Map[decompose, tensor, {scalarLevel}];
  If[! FreeQ[channels, $Failed],
    If[StringQ[stage],
      multiquadraticStripStageDone[stage,
        <|"seconds" -> N[AbsoluteTime[] - started], "status" -> "Failed"|>]];
    Return[$Failed]];
  compiled = Map[
    multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[StringQ[stage],
    multiquadraticStripStageDone[stage,
      <|"seconds" -> N[AbsoluteTime[] - started],
        "status" -> If[FreeQ[compiled, $Failed], "OK", "Failed"]|>]];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* Codex item 3, the inverse.  A element with grade support {0, m} has
   the two-term inverse (A - B r_m)/(A^2 - B^2 delta_m) -- its NORM, not
   a 2^r x 2^r rational solve; a pure single-grade element inverts in
   one division.  Any other support falls through to the general field
   inversion ABI.  Every branch is accepted only after the exact product
   check against the grade identity, which is the same acceptance
   multiquadraticFieldInverse makes. *)
multiquadraticStripCompactInverse[a_List, deltas_List] := Module[
  {dimension = Length[a], nonzero, mask, factor, norm, inverse, check,
   general = False},
  If[dimension =!= 2^Length[deltas], Return[$Failed]];
  (* the channels arrive from the field ABI, which ends in Together, so a
     zero channel IS the integer 0: re-Togethering every channel of a
     full-support letter merely to test it for zero was measured as the
     dominant cost of this routine on the rank-3 fixture (2026-08-25) *)
  nonzero = Flatten[Position[SameQ[#1, 0] & /@ a, False, {1},
    Heads -> False]];
  inverse = Which[
    nonzero === {}, $Failed,
    nonzero === {1},
      ReplacePart[ConstantArray[0, dimension], 1 -> Together[1/a[[1]]]],
    Length[nonzero] === 1,
      mask = First[nonzero] - 1;
      factor = Together[multiquadraticMaskFactor[mask, deltas]];
      If[TrueQ[factor === 0], $Failed,
        ReplacePart[ConstantArray[0, dimension],
          (mask + 1) -> Together[1/(a[[mask + 1]] factor)]]],
    Length[nonzero] === 2 && First[nonzero] === 1,
      mask = Last[nonzero] - 1;
      factor = Together[multiquadraticMaskFactor[mask, deltas]];
      norm = Together[a[[1]]^2 - a[[mask + 1]]^2 factor];
      If[TrueQ[norm === 0], $Failed,
        ReplacePart[ConstantArray[0, dimension],
          {1 -> Together[a[[1]]/norm],
           (mask + 1) -> Together[-a[[mask + 1]]/norm]}]],
    True, general = True; multiquadraticFieldInverse[a, deltas]];
  If[inverse === $Failed || ! ListQ[inverse] || Length[inverse] =!= dimension,
    Return[$Failed]];
  (* multiquadraticFieldInverse already made this exact product check;
     repeating it costs a second 2^r x 2^r symbolic multiply *)
  If[TrueQ[general], Return[inverse]];
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! ListQ[check] ||
      ! multiquadraticStripZeroQ[check - UnitVector[dimension, 1]],
    $Failed, inverse]
];

(* Codex item 3, the one-form.  dlog L = (dL) L^-1 entirely inside the
   grade algebra: decompose the LETTER (the small object), check that it
   recomposes exactly, invert by the norm, differentiate in the grade
   basis (multiquadraticDerivative carries the dlog delta term, so the
   derivative never leaves its grade) and multiply.  The expanded
   D[L]/L tree is never formed and never decomposed.

   Exactness: the recompose check certifies the channels of L; the
   product check inside multiquadraticStripCompactInverse certifies the
   inverse; derivative and product are exact identities of the ABI.  So
   the returned channels are the exact channels of dlog L without any
   check on the materialized tree. *)
multiquadraticStripLetterChannelPair[letter_, roots_List,
    variables : {_Symbol, _Symbol}] := Module[
  {rank = Length[roots], deltas, channels, composed, inverse, result},
  deltas = If[rank === 0, {},
    Together /@ Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]]];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  channels = Quiet[multiquadraticFieldDecompose[letter, roots]];
  If[! ListQ[channels] || Length[channels] =!= 2^rank ||
      ! FreeQ[channels, $Failed], Return[$Failed]];
  composed = multiquadraticFieldCompose[channels, roots];
  If[composed === $Failed ||
      ! TrueQ[Together[composed - letter] === 0], Return[$Failed]];
  inverse = multiquadraticStripCompactInverse[channels, deltas];
  If[inverse === $Failed, Return[$Failed]];
  result = Table[
    Module[{derivative = multiquadraticDerivative[channels, deltas,
        variables[[mu]]]},
      If[! ListQ[derivative] || ! FreeQ[derivative, $Failed], $Failed,
        multiquadraticMultiply[derivative, inverse, deltas]]],
    {mu, 2}];
  If[! MatchQ[result, {_List, _List}] || ! FreeQ[result, $Failed], $Failed,
    result]
];

(* ---- COMPACT-DLOG ADMISSION (2026-08-25, Codex 14:30 P1) -----------

   The compact path computes the channels of dlog(Letter) and installs
   them as the channels of "form".  That substitution is sound only if
   form IS dlog(Letter).  The pre-2026-08-25 gate tested
   SameQ[record["OneForm"], form] -- i.e. that the caller passed the form
   it had itself stored -- which is true of any self-consistent wrong
   record and proves nothing about the dlog relation.

   Two admissions are accepted, in this order:

     "CertifiedTag"    the record carries the package-produced
                       certificate minted at the site that computed the
                       one-form from the letter, and BOTH its hashes
                       re-derive from the letter and the form presented
                       here.  Costs two canonical texts, no algebra.
     "ExactDLogCheck"  dlog(Letter) is recomputed and compared to form
                       entry by entry.  This is the exact relation, not
                       a sample of it; it costs one Together per
                       component and is the fallback for records this
                       module did not build.

   Anything else is REFUSED for the compact path -- a diagonal form
   (closed, not a dlog), a record whose halves disagree, a bare form
   with no record -- and the entry is compiled by decomposing the form
   that was actually asked for, which is always correct.  The refusal
   reason travels with the entry so a caller can see how many letters
   took which route and why. *)
multiquadraticStripCompactDLogAdmission[letterRecord_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, mode_] := Module[
  {letter, certificate, derived},
  If[! AssociationQ[letterRecord],
    Return[<|"Admitted" -> False, "Reason" -> "NoLetterRecord"|>]];
  letter = Lookup[letterRecord, "Letter", Missing["NoLetter"]];
  If[MissingQ[letter],
    Return[<|"Admitted" -> False, "Reason" -> "NotADLog"|>]];
  If[! SameQ[Lookup[letterRecord, "OneForm", Missing["NoOneForm"]], form],
    Return[<|"Admitted" -> False,
      "Reason" -> "OneFormIsNotTheRecordOneForm"|>]];
  certificate = Lookup[letterRecord, "DLogCertificate",
    Missing["NoCertificate"]];
  If[mode =!= "Exact" &&
      multiquadraticStripLetterDLogCertificateValidQ[certificate, letter,
        form, variables, epsilon],
    Return[<|"Admitted" -> True, "Method" -> "CertifiedTag",
      "Letter" -> letter|>]];
  If[mode === "Certified",
    Return[<|"Admitted" -> False,
      "Reason" -> If[AssociationQ[certificate],
        "DLogCertificateMismatch", "DLogCertificateMissing"]|>]];
  derived = multiquadraticStripLetterOneForm[letter, variables];
  If[! MatchQ[derived, {_, _}],
    Return[<|"Admitted" -> False, "Reason" -> "LetterHasNoDLog"|>]];
  If[! (TrueQ[Together[derived[[1]] - form[[1]]] === 0] &&
        TrueQ[Together[derived[[2]] - form[[2]]] === 0]),
    Return[<|"Admitted" -> False,
      "Reason" -> "OneFormIsNotTheLetterDLog"|>]];
  <|"Admitted" -> True, "Method" -> "ExactDLogCheck", "Letter" -> letter|>
];

(* the grade masks one channel VECTOR occupies.  The channels arrive from
   the field ABI, which ends in Together, so a zero channel is the
   integer 0 and no normalization is needed here. *)
multiquadraticStripChannelVectorGradeSupport[vector_List] :=
  Flatten[Position[vector, entry_ /; ! TrueQ[entry === 0], {1},
    Heads -> False]] - 1;

(* the union over a list of channel vectors (a one-form is two of them) *)
multiquadraticStripChannelGradeSupport[vectors : {__List}] :=
  Sort[DeleteDuplicates[Flatten[
    multiquadraticStripChannelVectorGradeSupport /@ vectors]]];
multiquadraticStripChannelGradeSupport[vector_List] :=
  Sort[multiquadraticStripChannelVectorGradeSupport[vector]];

(* One compiled one-form. *)
multiquadraticStripCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_] := multiquadraticStripCompileOneFormEntry[form, letterRecord,
  roots, variables, epsilon, compactQ, Automatic, Automatic];

multiquadraticStripCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, gradeSupport_, admissionMode_] := Module[
  {channels = $Failed, admission = <|"Admitted" -> False,
     "Reason" -> "CompactRouteDisabled"|>, path, compiled, support,
   admissible},
  If[TrueQ[compactQ],
    admission = multiquadraticStripCompactDLogAdmission[letterRecord, form,
      variables, epsilon, admissionMode];
    If[TrueQ[admission["Admitted"]],
      channels = multiquadraticStripLetterChannelPair[admission["Letter"],
        roots, variables];
      If[! MatchQ[channels, {_List, _List}],
        admission = <|"Admitted" -> False,
          "Reason" -> "LetterChannelsUnavailable"|>]]];
  If[MatchQ[channels, {_List, _List}],
    (* THE GRADE GATE (2026-08-25).  "GradeSupport" declares the grade
       masks the compiled system carries.  A letter whose dlog occupies a
       mask outside that set cannot be represented by the compiled
       residue columns, and admitting it would send the modular solve
       looking for an inconsistency whose cause is this letter.  It is a
       TYPED refusal of the whole compile, not a fallback: the caller
       declared a grade set and this letter leaves it. *)
    admissible = Replace[gradeSupport,
      Automatic :> Range[0, 2^Length[roots] - 1]];
    support = multiquadraticStripChannelGradeSupport[channels];
    If[! VectorQ[admissible, IntegerQ] || ! SubsetQ[admissible, support],
      Return[<|"Status" -> "CompactLetterGradeSupportExceeded",
        "GradeSupport" -> support,
        "AdmissibleGradeSupport" -> admissible,
        "Path" -> "CompactLetterChannels"|>]]];
  path = If[MatchQ[channels, {_List, _List}], "CompactLetterChannels",
    channels = multiquadraticStripDecomposeScalarInterned[#1, roots] & /@ form;
    "DecomposedForm"];
  If[! ListQ[channels] || ! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[
    multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
    channels, {2}];
  If[! FreeQ[compiled, $Failed], Return[$Failed]];
  <|"Channels" -> channels, "Compiled" -> compiled, "Path" -> path,
    "CompactAdmission" -> If[path === "CompactLetterChannels",
      admission["Method"], admission["Reason"]]|>
];

(* Helper side of Codex item 5.  The shard receives an IMMUTABLE payload
   file written in formal System` symbols, so nothing it reads depends
   on the helper kernel's $Context (the CANONICA rebinding trap), and it
   acquires no nested kernel of its own. *)
multiquadraticStripCompileShardTask[dataFile_String, indices_List] := Module[
  {payload, forms, records, roots, entries},
  payload = Quiet[CheckAbort[Get[dataFile], $Failed]];
  If[! AssociationQ[payload], Return[$Failed]];
  forms = Lookup[payload, "OneForms", $Failed];
  records = Lookup[payload, "LetterRecords", None];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[forms] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ], Return[$Failed]];
  entries = Table[
    multiquadraticStripCompileOneFormEntry[forms[[index]],
      If[MatchQ[records, {___Association}] && Length[records] === Length[forms],
        records[[index]], None],
      roots, {\[FormalX], \[FormalY]}, \[FormalE],
      TrueQ[Lookup[payload, "Compact", False]],
      Lookup[payload, "GradeSupport", Automatic],
      Lookup[payload, "AdmissionMode", Automatic]],
    {index, indices}];
  If[! FreeQ[entries, $Failed], $Failed,
    <|"Indices" -> indices, "Entries" -> entries|>]
];

(* ---- the one-form pool KEY (2026-08-25, Codex 14:30 "OneForm key
   provenance").  The pre-2026-08-25 key was {prefix, form}: the SAME
   form compiled through the compact letter-channel route and through
   the decomposed-form route landed on ONE entry, so a route flip inside
   a session could serve the other route's channels, and two records
   naming DIFFERENT letters for the same stored one-form were
   indistinguishable.  The key now carries the requested ROUTE and the
   letter's provenance hash, so an entry can only ever be served to the
   configuration that produced it.  The stored entry additionally
   reports the route it actually took ("Path"), which the compact route
   may still downgrade after an admission refusal. *)
multiquadraticStripLetterProvenanceHash[record_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {certificate},
  If[! AssociationQ[record], Return["NoLetterRecord"]];
  certificate = Lookup[record, "DLogCertificate", Missing["NoCertificate"]];
  (* the certificate already hashes the canonical letter and one-form
     texts, so it IS the provenance and costs nothing to reuse *)
  If[AssociationQ[certificate],
    Return[Hash[{Lookup[record, "Kind", None], certificate},
      "SHA256", "HexString"]]];
  Hash[{Lookup[record, "Kind", None],
    ToString[InputForm[Lookup[record, "Letter", Missing["NoLetter"]] /.
      multiquadraticStripCanonicalRules[variables, epsilon]]]},
    "SHA256", "HexString"]
];

multiquadraticStripCompileOneFormKey[prefix_, form_, record_, compactQ_,
    gradeSupport_, admissionMode_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := {prefix, form,
  If[TrueQ[compactQ], "CompactLetterChannels", "DecomposedForm"],
  multiquadraticStripLetterProvenanceHash[record, variables, epsilon],
  gradeSupport, admissionMode};

(* The ansatz half of the split: one interned entry per one-form, keyed
   on the chart symbols, the canonical roots, the form itself, the route
   and the letter provenance.  An exact-prefix alphabet extension
   therefore hits the pool on every old letter and compiles only the
   suffix. *)
multiquadraticStripCompileOneForms[oneForms_List, letterRecords_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, shards_] :=
  multiquadraticStripCompileOneForms[oneForms, letterRecords, roots,
    variables, epsilon, compactQ, shards, Automatic, Automatic];

multiquadraticStripCompileOneForms[oneForms_List, letterRecords_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, shards_, gradeSupport_, admissionMode_] := Module[
  {records, aligned, prefix, keys, pending, entries, planned, groups,
   payload, dataFile, results, shardCount, rules, inverseRules, canonical,
   refused},
  aligned = MatchQ[letterRecords, {___Association}] &&
    Length[letterRecords] === Length[oneForms];
  records = If[aligned, letterRecords,
    ConstantArray[None, Length[oneForms]]];
  prefix = {$multiquadraticStripSourceSHA256, variables, epsilon,
    Lookup[roots, "Root", {}], Lookup[roots, "RootSquare", {}]};
  keys = Table[
    multiquadraticStripCompileOneFormKey[prefix, oneForms[[index]],
      records[[index]], compactQ, gradeSupport, admissionMode, variables,
      epsilon],
    {index, Length[oneForms]}];
  multiquadraticStripStageStart["compile: one-forms",
    <|"oneForms" -> Length[oneForms], "rank" -> Length[roots],
      "compact" -> TrueQ[compactQ], "shards" -> shards,
      "cached" -> Count[keys,
        key_ /; ! MissingQ[multiquadraticStripInternProbe["OneForm", key]]]|>];
  (* shard plan: only the one-forms the pool does NOT already hold, and
     only when a live broker and enough uncached work justify it *)
  shardCount = If[IntegerQ[shards] && shards >= 2 && shards <= 8, shards, 0];
  If[shardCount >= 2 && TrueQ[Quiet[taskBrokerActiveQ[]]],
    pending = Select[Range[Length[oneForms]],
      MissingQ[multiquadraticStripInternProbe["OneForm", keys[[#1]]]] &];
    pending = DeleteDuplicatesBy[pending, keys[[#1]] &];
    If[Length[pending] >= $multiquadraticStripCompileShardMinimum,
      rules = multiquadraticStripCanonicalRules[variables, epsilon];
      inverseRules = Reverse /@ rules;
      payload = <|"OneForms" -> (oneForms /. rules),
        "LetterRecords" -> If[aligned, letterRecords /. rules, None],
        "Roots" -> (roots /. rules), "Compact" -> TrueQ[compactQ],
        "GradeSupport" -> gradeSupport, "AdmissionMode" -> admissionMode|>;
      dataFile = taskBrokerDataFile[
        "mqcompile_" <> Hash[{prefix, oneForms}, "SHA256", "HexString"],
        payload];
      If[StringQ[dataFile],
        groups = Partition[pending, UpTo[Ceiling[Length[pending]/shardCount]]];
        results = taskBrokerRun[
          Table["FeynFacet`Private`multiquadraticStripCompileShardTask[\"" <>
            dataFile <> "\", " <> ToString[group, InputForm] <> "]",
            {group, groups}], "Label" -> "mqcompile", "Timeout" -> 7200];
        Do[
          If[AssociationQ[results[[k]]] &&
              Lookup[results[[k]], "Indices", None] === groups[[k]],
            MapThread[Function[{index, entry},
              canonical = If[AssociationQ[entry],
                Append[entry, "Channels" ->
                  (Lookup[entry, "Channels", $Failed] /. inverseRules)],
                entry];
              If[AssociationQ[canonical],
                multiquadraticStripIntern["OneForm", keys[[index]],
                  Function[canonical]]]],
              {groups[[k]], Lookup[results[[k]], "Entries", {}]}]],
          {k, Length[groups]}]]]];
  planned = Table[
    With[{form = oneForms[[index]], record = records[[index]],
        key = keys[[index]]},
      (* BOUNDARY: between letters.  The compile of one letter is a
         decomposition and an inversion in the grade algebra and is not
         interruptible inside; the letter is the finest boundary that
         exists without changing what is computed. *)
      multiquadraticStripDeadlineCheckpoint["Compilation:OneForms",
        <|"Letter" -> index, "Of" -> Length[oneForms]|>];
      multiquadraticStripStageProgress["compile: one-forms",
        <|"letter" -> index, "of" -> Length[oneForms]|>];
      multiquadraticStripIntern["OneForm", key,
        Function[multiquadraticStripCompileOneFormEntry[form, record, roots,
          variables, epsilon, compactQ, gradeSupport, admissionMode]]]],
    {index, Length[oneForms]}];
  (* a TYPED refusal from the grade gate is propagated as itself, not
     collapsed into $Failed: the caller must be able to name the letter *)
  refused = SelectFirst[planned,
    AssociationQ[#1] && KeyExistsQ[#1, "Status"] &, None];
  If[refused =!= None,
    Return[Join[refused, <|"LetterIndex" -> First[Flatten[Position[planned,
      refused, {1}, 1, Heads -> False]], Missing["NotFound"]]|>]]];
  If[! FreeQ[planned, $Failed] || ! MatchQ[planned, {___Association}],
    Return[$Failed]];
  entries = planned;
  <|"Channels" -> Lookup[entries, "Channels", {}],
    "Compiled" -> Lookup[entries, "Compiled", {}],
    "Paths" -> Lookup[entries, "Path", {}],
    "CompactAdmissions" -> Lookup[entries, "CompactAdmission",
      Missing["NotRecorded"]]|>
];

(* The core key.  Deliberately NOT the ABI fingerprint: that one carries
   the support, the one-forms and the gauge denominator, all of which are
   ansatz.  This one carries exactly what the core depends on -- the
   equation, the canonical roots, the grade ABI, this source file, and
   the chart symbols themselves, because two preparations that differ
   only in symbol names share an EquationFingerprint (it is computed
   from the canonical text) and must NOT share compiled channels. *)
(* The key parts, so that PREPARE can key the core before it has an ABI
   payload (2026-08-25).  Both callers must land on the same pool entry
   or the core is built twice, which is the whole defect that split
   closes.

   ---- ROOT EXPRESSIONS (2026-08-25, Codex 14:30 P1) -----------------

   Until today the key carried only the root SQUARES.  The core's
   algebra does not depend on the squares alone: every channel of E, C
   and BBar is a coefficient in the basis {1, r_1, r_2, r_1 r_2, ...},
   and replacing r_a by -r_a is a different basis of the same field with
   different coefficients.  Two preparations whose ONLY difference was a
   root sign therefore shared a core key and the second silently
   received the first's channels -- a wrong-basis collision that no
   later exact check could see, because every channel is individually
   well formed.  The ordered canonical root EXPRESSIONS are now keyed as
   well, so a sign mutant misses.  (The squares stay in the key: they are
   what the grade multiplication table is built from, and a root whose
   canonical text is equal while its square differs is not reachable but
   is also not worth relying on.) *)
multiquadraticStripCompileCoreKeyFromParts[algebraFingerprint_,
    equationFingerprint_, rootOrderingFingerprint_, rootCanonicalSquares_,
    rootCanonicalExpressions_, dimensions_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  {$multiquadraticStripSourceSHA256, algebraFingerprint,
   equationFingerprint, rootOrderingFingerprint, rootCanonicalSquares,
   rootCanonicalExpressions, dimensions, variables, epsilon};

multiquadraticStripCompileCoreKey[preparation_Association,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {payload = Lookup[preparation, "ABIPayload", $Failed]},
  If[! AssociationQ[payload], Return[$Failed]];
  If[AnyTrue[{"EquationFingerprint", "RootOrderingFingerprint",
      "RootCanonicalSquares", "RootCanonicalExpressions", "Dimensions"},
      ! KeyExistsQ[payload, #1] &], Return[$Failed]];
  multiquadraticStripCompileCoreKeyFromParts[
    Lookup[preparation, "AlgebraABIFingerprint", $Failed],
    payload["EquationFingerprint"], payload["RootOrderingFingerprint"],
    payload["RootCanonicalSquares"], payload["RootCanonicalExpressions"],
    payload["Dimensions"], variables, epsilon]
];

(* Takes the STRIP, not a preparation: prepare consumes this record too
   and has no preparation object yet when it does (2026-08-25).  The
   preparation-shaped call site in multiquadraticStripCompile passes
   preparation["Record"]["Strip"], so nothing it compiles changed. *)
multiquadraticStripCompileCoreRecord[strip_, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_,
    coreKey_, useCacheQ_] := Module[{build},
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  build[] := Module[
    {e, c, bbar, eData, cData, bData, rootSquares, rootSquareData,
     rootLogData},
    {e, c, bbar} = strip;
    eData = multiquadraticStripCompileTensorInterned[e, 3, roots, variables,
      epsilon, "compile core: E"];
    cData = multiquadraticStripCompileTensorInterned[c, 3, roots, variables,
      epsilon, "compile core: C"];
    bData = If[ArrayQ[reusedChannels, 4] &&
        Dimensions[reusedChannels] === Append[Dimensions[bbar],
          2^Length[roots]] && FreeQ[reusedChannels, $Failed],
      Module[{compiled = Map[
          multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
          reusedChannels, {4}]},
        If[! FreeQ[compiled, $Failed], $Failed,
          <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
      multiquadraticStripCompileTensorInterned[bbar, 3, roots, variables,
        epsilon, "compile core: BBar"]];
    rootSquares = Lookup[roots, "RootSquare", {}];
    rootSquareData = multiquadraticStripCompileTensorInterned[rootSquares, 1,
      {}, variables, epsilon];
    rootLogData = multiquadraticStripCompileTensorInterned[
      Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
        {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
    If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
      $Failed,
      <|"E" -> eData, "C" -> cData, "BBar" -> bData,
        "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]];
  If[TrueQ[useCacheQ] && coreKey =!= $Failed,
    multiquadraticStripIntern["Core", coreKey, Function[build[]]],
    build[]]
];

(* The gauge denominator is neither core nor ansatz: an alphabet change
   moves it (the norms of the algebraic letters enter it), a support
   change does not.  It is two rational scalars and their two log
   derivatives, so it gets its own small keyed pool. *)
multiquadraticStripCompileDenominatorRecord[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, useCacheQ_] := Module[
  {build},
  build[] := Module[{denominatorData, denominatorLogData},
    denominatorData = multiquadraticStripCompileTensorInterned[{denominator},
      1, {}, variables, epsilon];
    denominatorLogData = multiquadraticStripCompileTensorInterned[
      {D[denominator, variables[[1]]]/denominator,
       D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
    If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
      <|"GaugeDenominator" -> denominatorData,
        "GaugeLogDerivatives" -> denominatorLogData|>]];
  If[TrueQ[useCacheQ],
    multiquadraticStripIntern["GaugeDenominator",
      {$multiquadraticStripSourceSHA256, variables, epsilon, denominator},
      Function[build[]]],
    build[]]
];

(* The pre-2026-08-25 compiler, kept callable.  "LegacyCompiler" -> True
   routes every part through multiquadraticStripCompileTensor exactly as
   before: no interning, no core cache, no compact letter channels, and
   the second Together that fed CoefficientRules.  It is the reference
   the equivalence test holds the new architecture to (compiled-assembly
   modular images at (prime, eps, point) triples), and a bisect handle;
   it is not a production route. *)
multiquadraticStripCompileLegacyCore[preparation_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_] := Module[
  {strip = Lookup[preparation, "Record", <||>]["Strip"], e, c, bbar, eData,
   cData, bData, rootSquares, rootSquareData, rootLogData},
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  {e, c, bbar} = strip;
  eData = multiquadraticStripCompileTensor[e, 3, roots, variables, epsilon];
  cData = multiquadraticStripCompileTensor[c, 3, roots, variables, epsilon];
  bData = If[ArrayQ[reusedChannels, 4] &&
      Dimensions[reusedChannels] === Append[Dimensions[bbar],
        2^Length[roots]] && FreeQ[reusedChannels, $Failed],
    Module[{compiled = Map[
        multiquadraticStripCompileRational[#1, variables, epsilon] &,
        reusedChannels, {4}]},
      If[! FreeQ[compiled, $Failed], $Failed,
        <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
    multiquadraticStripCompileTensor[bbar, 3, roots, variables, epsilon]];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootSquareData = multiquadraticStripCompileTensor[rootSquares, 1, {},
    variables, epsilon];
  rootLogData = multiquadraticStripCompileTensor[
    Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
      {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
  If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
    $Failed,
    <|"E" -> eData, "C" -> cData, "BBar" -> bData,
      "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]
];

multiquadraticStripCompileLegacyDenominator[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {denominatorData, denominatorLogData},
  denominatorData = multiquadraticStripCompileTensor[{denominator}, 1, {},
    variables, epsilon];
  denominatorLogData = multiquadraticStripCompileTensor[
    {D[denominator, variables[[1]]]/denominator,
     D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
  If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
    <|"GaugeDenominator" -> denominatorData,
      "GaugeLogDerivatives" -> denominatorLogData|>]
];

multiquadraticStripFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{"MultiquadraticRationalExactV1",
      "MultiquadraticRationalPrimeV1", "MultiquadraticRationalImageV1"},
    Lookup[expression, "Type", None]], "MultiquadraticRationalLeaf",
  AssociationQ[expression], Map[multiquadraticStripFormShape, expression],
  ListQ[expression], multiquadraticStripFormShape /@ expression,
  True, "Scalar"
];

multiquadraticStripSemanticPayload[assembly_Association] := KeyTake[assembly, {
  "ABIFingerprint", "AlgebraABIFingerprint", "RootOrderingFingerprint",
  "RootCount", "GradeCount", "Dimensions", "GaugeSupport",
  "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
  "EquationsPerPoint", "ColumnOrder", "RowOrder",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "SourceSHA256"}];

(* "PreparationValidated" and "ForcingChannels" exist for ONE caller:
   solveEpsFormStripMultiquadratic, which has just built this preparation
   object itself in the same call.  Re-deriving the ABI payload and
   decomposing the forcing a second time then costs (measured on CF300
   (12,9)) 25 s and 807 s and can only reproduce what the preparation
   already carries.  Both default to the conservative behaviour, so a
   preparation that arrived from an artifact, a cache or another process
   is still validated and still decomposed here. *)
(* "PreparationValidated" and "ForcingChannels" exist for ONE caller:
   solveEpsFormStripMultiquadratic (see the note above).

   "CompileCore", "LetterChannels" and "CompileShards" are the 2026-08-25
   compile architecture.  All three default to Automatic and all three
   are then ON except sharding, which needs a live task broker AND an
   explicit shard count: naive parallelism duplicates work and peak
   memory, so it is last and opt-in.  "CompileCore" -> False and
   "LetterChannels" -> False restore the pre-2026-08-25 compiler exactly,
   which is what the equivalence test uses as its reference.

   ---- "CompileShards" IS A PRIVATE TEST CONTROL (decision 2026-08-25)

   It is NOT a production option and has no production caller.  It is
   absent from Options[solveEpsFormStripMultiquadratic] deliberately, so
   no public route can reach it, and the top-level option gate refuses
   it by name like any other unknown option.

   LEDGER NOTE.  What a production shard contract needs, and what does
   not exist yet: a strict result schema validated per shard (indices,
   entry count, per-entry shape) before anything is interned; a
   helper-leak guarantee (a helper that dies must not leave a claimed
   index uncompiled and unrecomputed); ABSOLUTE deadlines rather than
   the fixed 7200 s "Timeout" below; and a measured per-entry stage cost
   that shows sharding pays at all -- on CF300 (12,9) the entire
   one-form compilation is 89 s, so the serialization of the payload
   would dominate.  Production sharding waits for those measurements
   (Codex 14:30, shard row; agreed disposition).  Until then this option
   exists so the shard PATH stays exercised by its tests and does not
   rot. *)
Options[multiquadraticStripCompile] = {
  "PreparationValidated" -> False,
  "ForcingChannels" -> Automatic,
  "CompileCore" -> Automatic,
  "LetterChannels" -> Automatic,
  (* PRIVATE TEST CONTROL -- see the ledger note above.  Not a public
     option; do not add it to a production option set. *)
  "CompileShards" -> Automatic,
  "LegacyCompiler" -> False,
  (* the grade masks the compiled system carries.  Automatic = all 2^r
     of them (no restriction, the historical behaviour); a declared set
     makes the compact letter-channel route refuse typed any letter
     whose dlog occupies a mask outside it. *)
  "LetterGradeSupport" -> Automatic,
  (* how the compact route may prove form == dlog(Letter): Automatic =
     the package certificate if the record carries one, else the exact
     dlog check; "Certified" = certificate only; "Exact" = always
     recompute and compare. *)
  "CompactDLogAdmission" -> Automatic,
  (* absolute AbsoluteTime[] value; Infinity = unbounded, the default,
     so every existing caller is unchanged.  Read at the compile stage
     boundaries and, through the dynamic deadline, at every decomposed
     entry and every letter. *)
  "Deadline" -> Infinity,
  (* the persistent compile pools' ceilings, as OPTIONS rather than
     dynamic globals: a per-call ceiling belongs to the call
     (2026-08-25).  Automatic on both is the module constant. *)
  "PoolByteLimit" -> Automatic,
  "PoolEntryLimit" -> Automatic
};

multiquadraticStripCompile[preparation_Association,
    opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, record, roots, rules, dimensions,
   coreKey, core, eData, cData, bData, oneData, rootSquareData,
   rootLogData, reusedChannels, denominatorRecord, denominatorData,
   denominatorLogData, exactForms, compiledForms, canonicalExact, result,
   payload, coreEnabled, compactQ, shards, legacyQ, coreSeconds,
   oneFormSeconds, denominatorSeconds, statistics,
   gradeSupport, admissionMode, deadline, compileStop, compileProgress,
   compileBudget, compileGuard, poolByteLimit, poolEntryLimit,
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripCompile]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in prepare and in the top-level driver *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  If[! TrueQ[OptionValue["PreparationValidated"]] &&
      ! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparationABI"]]];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  dimensions = preparation["Dimensions"];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  legacyQ = TrueQ[OptionValue["LegacyCompiler"]];
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> ! legacyQ];
  compactQ = Replace[OptionValue["LetterChannels"], Automatic -> ! legacyQ];
  shards = Replace[OptionValue["CompileShards"], Automatic -> 0];
  gradeSupport = Replace[OptionValue["LetterGradeSupport"],
    ell_List :> Sort[DeleteDuplicates[ell]]];
  admissionMode = Replace[OptionValue["CompactDLogAdmission"],
    Automatic -> "CertifiedOrExact"];
  poolByteLimit = Replace[OptionValue["PoolByteLimit"],
    Automatic :> $multiquadraticStripPoolByteLimit];
  poolEntryLimit = Replace[OptionValue["PoolEntryLimit"],
    Automatic :> $multiquadraticStripPoolEntryLimit];
  If[! AssociationQ[poolByteLimit] || ! AssociationQ[poolEntryLimit] ||
      ! AllTrue[Values[poolByteLimit], NumericQ[#1] && #1 > 0 &] ||
      ! AllTrue[Values[poolEntryLimit],
        #1 === Infinity || (IntegerQ[#1] && #1 > 0) &],
    Return[multiquadraticStripFailure["InvalidCompilePoolCeiling",
      <|"PoolByteLimit" -> poolByteLimit,
        "PoolEntryLimit" -> poolEntryLimit|>]]];
  If[! MemberQ[{True, False}, coreEnabled] ||
      ! MemberQ[{True, False}, compactQ] ||
      ! (IntegerQ[shards] && 0 <= shards <= 8),
    Return[multiquadraticStripFailure["InvalidCompileArchitectureOption",
      <|"CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
        "CompileShards" -> shards|>]]];
  If[! (gradeSupport === Automatic ||
      (VectorQ[gradeSupport, IntegerQ] && gradeSupport =!= {} &&
        AllTrue[gradeSupport, 0 <= #1 < preparation["GradeCount"] &])),
    Return[multiquadraticStripFailure["InvalidLetterGradeSupport",
      <|"LetterGradeSupport" -> gradeSupport,
        "GradeCount" -> preparation["GradeCount"]|>]]];
  If[! MemberQ[{"CertifiedOrExact", "Certified", "Exact"}, admissionMode],
    Return[multiquadraticStripFailure["InvalidCompactDLogAdmission",
      <|"CompactDLogAdmission" -> admissionMode,
        "Expected" -> {Automatic, "Certified", "Exact"}|>]]];
  If[legacyQ && (coreEnabled || compactQ || shards =!= 0),
    Return[multiquadraticStripFailure["LegacyCompilerOptionConflict",
      <|"CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
        "CompileShards" -> shards|>]]];
  (* ---- the cooperative compile deadline (2026-08-25, Codex 14:30) ---
     Same shape and same mechanism as prepare's: a typed resumable
     BudgetExhausted whose Stage names a "Compilation:" substage, read
     at the stage boundaries HERE and, through the dynamic deadline
     Blocked below, between decomposed entries and between letters.
     NEVER TimeConstrained: it does not bound task-broker helpers and
     has escaped in pool subkernels (CLAUDE.md). *)
  compileStop = None;
  compileProgress[] := <|
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Prime" -> Missing["NotSampled"],
    "RegulatorValue" -> Missing["NotSampled"],
    "SamplesDone" -> Missing["NotSampled"],
    "RootCount" -> Lookup[preparation, "RootCount", Missing["NotPrepared"]],
    "OneFormCount" -> Length[Lookup[preparation, "OneForms", {}]],
    "UnknownCount" -> Lookup[preparation, "UnknownCount",
      Missing["NotPrepared"]],
    "SupportSize" -> Length[Lookup[preparation, "GaugeSupport", {}]],
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"]|>;
  compileBudget[substage_String, extra_Association : <||>] :=
    multiquadraticStripBudgetExhausted["Compilation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[compileProgress[], extra]];
  compileGuard[substage_String] :=
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      compileStop = compileBudget[substage]; True, False];
  If[compileGuard["Entry"], Return[compileStop]];
  (* the VALUE pools are per call at both ends: they make one call
     compile each unique value once and are never carried *)
  multiquadraticStripInternReset["Scalar"];
  multiquadraticStripInternReset["Rational"];
  (* a supplied decomposition is accepted only against its own seal
     (Codex 04:30 P2); an unsealed or mismatched one is refused typed,
     never re-derived silently and never installed.  Accepted channels
     flow into the compile core as the raw array; absence flows as
     Missing so the core derives them itself. *)
  reusedChannels = Module[
    {bbarLocal = Last[Lookup[record, "Strip", {$Failed, $Failed, $Failed}]],
     seal},
    seal = multiquadraticStripForcingChannelsAccept[
    OptionValue["ForcingChannels"], bbarLocal, roots, variables, epsilon];
    Which[
      Lookup[seal, "Status", None] === "Accepted", seal["Channels"],
      Lookup[seal, "Status", None] === "NotSupplied",
        Missing["NotSupplied"],
      True, seal]];
  If[AssociationQ[reusedChannels],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure[reusedChannels["Status"],
      KeyDrop[reusedChannels, "Status"]]]];
  coreKey = If[TrueQ[coreEnabled],
    multiquadraticStripCompileCoreKey[preparation, variables, epsilon],
    $Failed];
  (* one Block for the whole compile: the decomposition loops and the
     letter loop read the dynamic deadline and leave by Throw, and Block
     restores it on every exit path including the Throw.  Infinity is
     compared by SameQ before any clock is read, so the default performs
     exactly as no deadline at all. *)
  {coreSeconds, core} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileLegacyCore[preparation, roots, variables,
            epsilon, reusedChannels],
          multiquadraticStripCompileCoreRecord[
            Lookup[record, "Strip", $Failed], roots, variables,
            epsilon, reusedChannels, coreKey, coreEnabled]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["Core",
          Join[<|"Substage" -> Lookup[load, "Substage", "Core"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[core],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  {eData, cData, bData, rootSquareData, rootLogData} =
    Lookup[core, {"E", "C", "BBar", "RootSquares", "RootLogDerivatives"}];
  If[compileGuard["OneForms"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  {oneFormSeconds, oneData} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileTensor[preparation["OneForms"], 2, roots,
            variables, epsilon],
          multiquadraticStripCompileOneForms[preparation["OneForms"],
            Lookup[preparation, "LetterRecords", None], roots, variables,
            epsilon, compactQ, shards, gradeSupport, admissionMode]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["OneForms",
          Join[<|"Substage" -> Lookup[load, "Substage", "OneForms"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  (* pairs with the start emitted inside multiquadraticStripCompileOneForms:
     that function has typed early exits, this line does not *)
  If[! legacyQ,
    multiquadraticStripStageDone["compile: one-forms",
      <|"seconds" -> N[oneFormSeconds],
        "status" -> Which[AssociationQ[compileStop], "BudgetExhausted",
          AssociationQ[oneData] && ! KeyExistsQ[oneData, "Status"], "OK",
          AssociationQ[oneData], Lookup[oneData, "Status", "Failed"],
          True, "Failed"],
        "paths" -> If[AssociationQ[oneData],
          Counts[Lookup[oneData, "Paths", {}]], <||>]|>]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  (* the typed grade-gate refusal travels as itself: it names the letter
     and the mask that left the declared grade set *)
  If[AssociationQ[oneData] && KeyExistsQ[oneData, "Status"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure[oneData["Status"],
      KeyDrop[oneData, "Status"]]]];
  If[! AssociationQ[oneData],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  If[compileGuard["GaugeDenominator"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  {denominatorSeconds, denominatorRecord} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileLegacyDenominator[
            preparation["GaugeDenominator"], variables, epsilon],
          multiquadraticStripCompileDenominatorRecord[
            preparation["GaugeDenominator"], variables, epsilon,
            coreEnabled]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["GaugeDenominator",
          Join[<|"Substage" -> Lookup[load, "Substage",
            "GaugeDenominator"]|>, KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[denominatorRecord],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["RationalAssemblyFormCompilationFailed"]]];
  denominatorData = denominatorRecord["GaugeDenominator"];
  denominatorLogData = denominatorRecord["GaugeLogDerivatives"];
  statistics = <|
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"],
    "CoreSeconds" -> coreSeconds, "OneFormSeconds" -> oneFormSeconds,
    "GaugeDenominatorSeconds" -> denominatorSeconds,
    "CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
    (* private test control, echoed here as telemetry only *)
    "CompileShards" -> shards,
    "LetterGradeSupport" -> gradeSupport,
    "CompactDLogAdmission" -> admissionMode,
    "OneFormPaths" -> Counts[Lookup[oneData, "Paths", {}]],
    "CompactAdmissions" -> Counts[Lookup[oneData, "CompactAdmissions", {}]],
    "Pools" -> multiquadraticStripInternStatistics[]|>;
  multiquadraticStripInternReset["Scalar"];
  multiquadraticStripInternReset["Rational"];
  exactForms = <|"E" -> eData["Channels"], "C" -> cData["Channels"],
    "BBar" -> bData["Channels"], "OneForms" -> oneData["Channels"],
    "RootSquares" -> (First /@ rootSquareData["Channels"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Channels"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Channels"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Channels"]|>;
  compiledForms = <|"E" -> eData["Compiled"], "C" -> cData["Compiled"],
    "BBar" -> bData["Compiled"], "OneForms" -> oneData["Compiled"],
    "RootSquares" -> (First /@ rootSquareData["Compiled"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Compiled"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Compiled"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Compiled"]|>;
  If[! FreeQ[compiledForms, $Failed],
    Return[multiquadraticStripFailure["CompiledAssemblyFormsInvalid"]]];
  (* the exact forms carry the chart symbols: canonicalize before
     hashing so the cache key is not the reader's context (pool defect
     3 -- ExactChannelFormsFingerprint changed with the inspecting
     context in the Codex original) *)
  canonicalExact = exactForms /. rules;
  If[! multiquadraticStripContextFreeQ[canonicalExact],
    Return[multiquadraticStripFailure["ContextSensitiveChannelForms"]]];
  result = <|
    "Status" -> "CompiledMultiquadraticStripV1",
    "SourceFile" -> $multiquadraticStripSourceFile,
    "SourceSHA256" -> $multiquadraticStripSourceSHA256,
    "Preparation" -> preparation,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"],
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "GaugeSupport" -> preparation["GaugeSupport"],
    "OneForms" -> preparation["OneForms"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
    "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ColumnOrder" -> preparation["ColumnOrder"],
    "RowOrder" -> preparation["RowOrder"],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" -> multiquadraticStripFingerprint[canonicalExact],
    "CompiledFormsFingerprint" -> multiquadraticStripFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" -> multiquadraticStripFingerprint[
      multiquadraticStripFormShape[compiledForms]]|>;
  payload = multiquadraticStripSemanticPayload[result];
  (* telemetry only.  multiquadraticStripSemanticPayload is a KeyTake of
     a fixed list, so nothing here enters AssemblyFingerprint and no
     artifact comparison sees a wall clock. *)
  result = Append[result, "CompileStatistics" -> Append[statistics,
    "Seconds" -> AbsoluteTime[] - startTime]];
  Append[result, "AssemblyFingerprint" -> multiquadraticStripFingerprint[payload]]
];
multiquadraticStripCompile[___] :=
  multiquadraticStripFailure["InvalidCompileArguments"];

multiquadraticStripCompiledValidQ[assembly_Association] := Module[
  {dimensions, rootCount, gradeCount, support, expectedGauge, expectedResidue,
   requiredKeys, rules, canonicalExact},
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
    Return[False]];
  requiredKeys = {"SourceFile", "SourceSHA256", "ABIFingerprint",
    "AlgebraABIFingerprint", "RootOrderingFingerprint", "Record", "Roots",
    "RootCount", "GradeCount", "Variables", "Regulator", "Dimensions",
    "GaugeSupport", "OneForms", "GaugeDenominator", "Normalizations",
    "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ColumnOrder", "RowOrder", "ExactChannelForms",
    "CompiledForms", "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
    "CompiledFormsShapeFingerprint", "AssemblyFingerprint"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &], Return[False]];
  dimensions = assembly["Dimensions"];
  rootCount = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  support = assembly["GaugeSupport"];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || ! IntegerQ[rootCount] ||
      ! (0 <= rootCount <= $multiquadraticStripMaximumRootCount) ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {}, Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[assembly["OneForms"]] Times @@ dimensions;
  rules = multiquadraticStripCanonicalRules[assembly["Variables"],
    assembly["Regulator"]];
  canonicalExact = assembly["ExactChannelForms"] /. rules;
  TrueQ[
    assembly["SourceSHA256"] === $multiquadraticStripSourceSHA256 &&
    assembly["AlgebraABIFingerprint"] === multiquadraticAlgebraABIFingerprint[] &&
    assembly["GaugeUnknownCount"] === expectedGauge &&
    assembly["ResidueUnknownCount"] === expectedResidue &&
    assembly["UnknownCount"] === expectedGauge + expectedResidue &&
    assembly["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    assembly["ColumnOrder"] === multiquadraticStripColumnOrder[dimensions,
      gradeCount, support, Length[assembly["OneForms"]]] &&
    assembly["RowOrder"] === multiquadraticStripRowOrder[dimensions, gradeCount] &&
    assembly["ExactChannelFormsFingerprint"] ===
      multiquadraticStripFingerprint[canonicalExact] &&
    assembly["CompiledFormsFingerprint"] ===
      multiquadraticStripFingerprint[assembly["CompiledForms"]] &&
    assembly["CompiledFormsShapeFingerprint"] === multiquadraticStripFingerprint[
      multiquadraticStripFormShape[assembly["CompiledForms"]]] &&
    assembly["AssemblyFingerprint"] === multiquadraticStripFingerprint[
      multiquadraticStripSemanticPayload[assembly]]]
];

(* ------------------------------------------------------------------ *)
(* Prime forms and regulator collapse                                   *)
(* ------------------------------------------------------------------ *)

multiquadraticStripMapRationals[expression_, sourceType_String, function_] := Which[
  AssociationQ[expression] && Lookup[expression, "Type", None] === sourceType,
    function[expression],
  AssociationQ[expression],
    Map[multiquadraticStripMapRationals[#1, sourceType, function] &, expression],
  ListQ[expression],
    multiquadraticStripMapRationals[#1, sourceType, function] & /@ expression,
  True, expression
];

multiquadraticStripReducePolynomial[polynomial_Association, prime_Integer] := Module[
  {rows},
  rows = Map[multiquadraticStripModRational[#1, prime] &,
    polynomial["EpsilonCoefficientRows"], {2}];
  If[! FreeQ[rows, $Failed], Return[$Failed]];
  <|"Type" -> "MultiquadraticPolynomialPrimeV1",
    "XExponents" -> polynomial["XExponents"],
    "YExponents" -> polynomial["YExponents"],
    "EpsilonCoefficientRows" -> Developer`ToPackedArray[rows], "Prime" -> prime|>
];

multiquadraticStripReduceRational[rational_Association, prime_Integer] := Module[
  {numerator, denominator},
  numerator = multiquadraticStripReducePolynomial[rational["Numerator"], prime];
  denominator = multiquadraticStripReducePolynomial[rational["Denominator"], prime];
  If[numerator === $Failed || denominator === $Failed, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalPrimeV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

SetAttributes[multiquadraticStripCacheInsert, HoldFirst];
multiquadraticStripCacheInsert[cacheSymbol_Symbol, key_, value_,
    maximum_Integer] := (
  If[! AssociationQ[cacheSymbol], cacheSymbol = <||>];
  If[Length[cacheSymbol] >= maximum,
    KeyDropFrom[cacheSymbol, First[Keys[cacheSymbol]]]];
  AssociateTo[cacheSymbol, key -> value];
  value);

multiquadraticStripPrimeForms[assembly_Association, prime_Integer] := Module[
  {key, forms},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidPrimeFormsInput"]]];
  key = {assembly["AssemblyFingerprint"], prime};
  If[KeyExistsQ[$multiquadraticStripPrimeCache, key],
    Return[$multiquadraticStripPrimeCache[key]]];
  forms = multiquadraticStripMapRationals[assembly["CompiledForms"],
    "MultiquadraticRationalExactV1",
    multiquadraticStripReduceRational[#1, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticStripFailure["PrimeReductionFailed",
      <|"Prime" -> prime|>]]];
  multiquadraticStripCacheInsert[$multiquadraticStripPrimeCache, key, <|
    "Status" -> "MultiquadraticStripPrimeFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Prime" -> prime, "Forms" -> forms|>, 8]
];

multiquadraticStripCollapsePolynomial[polynomial_Association, epsilonMod_Integer,
    prime_Integer] := Module[{coefficients, keep},
  If[polynomial["EpsilonCoefficientRows"] === {},
    Return[<|"Type" -> "MultiquadraticPolynomialImageV1", "XExponents" -> {},
      "YExponents" -> {}, "Coefficients" -> {}, "Prime" -> prime|>]];
  coefficients = Fold[Mod[#1 epsilonMod + #2, prime] &, 0, Reverse[#1]] & /@
    polynomial["EpsilonCoefficientRows"];
  keep = Flatten[Position[coefficients, Except[0], {1}, Heads -> False]];
  <|"Type" -> "MultiquadraticPolynomialImageV1",
    "XExponents" -> Developer`ToPackedArray[polynomial["XExponents"][[keep]]],
    "YExponents" -> Developer`ToPackedArray[polynomial["YExponents"][[keep]]],
    "Coefficients" -> Developer`ToPackedArray[coefficients[[keep]]],
    "Prime" -> prime|>
];

multiquadraticStripCollapseRational[rational_Association, epsilonMod_Integer,
    prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticStripCollapsePolynomial[rational["Numerator"],
    epsilonMod, prime];
  denominator = multiquadraticStripCollapsePolynomial[rational["Denominator"],
    epsilonMod, prime];
  If[denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalImageV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

multiquadraticStripMaximumExponents[forms_] := Module[{polynomials, nonzero},
  polynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  nonzero = Select[polynomials, Lookup[#1, "Coefficients", {}] =!= {} &];
  If[nonzero === {}, {0, 0},
    {Max[Max /@ Lookup[nonzero, "XExponents"]],
     Max[Max /@ Lookup[nonzero, "YExponents"]]}]
];

multiquadraticStripCollapseEpsilon[assembly_Association, prime_Integer,
    epsilonValue_] := Module[{key, primeForms, epsilonMod, forms, maximum},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidCollapseInput"]]];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  key = {assembly["AssemblyFingerprint"], prime, epsilonMod};
  If[KeyExistsQ[$multiquadraticStripEpsilonCache, key],
    Return[$multiquadraticStripEpsilonCache[key]]];
  primeForms = multiquadraticStripPrimeForms[assembly, prime];
  If[Lookup[primeForms, "Status", None] =!= "MultiquadraticStripPrimeFormsV1",
    Return[primeForms]];
  forms = multiquadraticStripMapRationals[primeForms["Forms"],
    "MultiquadraticRationalPrimeV1",
    multiquadraticStripCollapseRational[#1, epsilonMod, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticStripFailure["RegulatorCollapseFailed",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  maximum = multiquadraticStripMaximumExponents[forms];
  multiquadraticStripCacheInsert[$multiquadraticStripEpsilonCache, key, <|
    "Status" -> "MultiquadraticStripEpsilonFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"], "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsilonMod,
    "MaximumExponents" -> maximum, "Forms" -> forms,
    "FormsShapeFingerprint" -> multiquadraticStripFingerprint[
      multiquadraticStripFormShape[forms]],
    "FormsFingerprint" -> multiquadraticStripFingerprint[forms]|>, 32]
];

multiquadraticStripPolynomialImageValidQ[polynomial_Association, prime_Integer,
    allowZero_: True] := Module[{xExponents, yExponents, coefficients},
  If[Sort[Keys[polynomial]] =!= Sort[{"Type", "XExponents", "YExponents",
      "Coefficients", "Prime"}] ||
      polynomial["Type"] =!= "MultiquadraticPolynomialImageV1" ||
      polynomial["Prime"] =!= prime, Return[False]];
  xExponents = polynomial["XExponents"];
  yExponents = polynomial["YExponents"];
  coefficients = polynomial["Coefficients"];
  TrueQ[VectorQ[xExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[yExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[coefficients, IntegerQ[#1] && 0 <= #1 < prime &] &&
    Length[xExponents] === Length[yExponents] === Length[coefficients] &&
    (TrueQ[allowZero] || coefficients =!= {})]
];

multiquadraticStripRationalImageValidQ[rational_Association, prime_Integer] :=
  TrueQ[
    Sort[Keys[rational]] === Sort[{"Type", "Numerator", "Denominator", "Prime"}] &&
    rational["Type"] === "MultiquadraticRationalImageV1" &&
    rational["Prime"] === prime && AssociationQ[rational["Numerator"]] &&
    AssociationQ[rational["Denominator"]] &&
    multiquadraticStripPolynomialImageValidQ[rational["Numerator"], prime, True] &&
    multiquadraticStripPolynomialImageValidQ[rational["Denominator"], prime, False]];

multiquadraticStripEpsilonFormsValidQ[assembly_Association, forms_Association,
    prime_Integer] := Module[
  {imageForms, rationalLeaves, epsilonMod, maximumExponents, expectedKeys},
  expectedKeys = {"Status", "AssemblyFingerprint", "Prime", "EpsilonValue",
    "EpsilonMod", "MaximumExponents", "Forms", "FormsShapeFingerprint",
    "FormsFingerprint"};
  If[Sort[Keys[forms]] =!= Sort[expectedKeys] ||
      Lookup[forms, "Status", None] =!= "MultiquadraticStripEpsilonFormsV1" ||
      Lookup[forms, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] ||
      Lookup[forms, "Prime", None] =!= prime, Return[False]];
  epsilonMod = Lookup[forms, "EpsilonMod", $Failed];
  maximumExponents = Lookup[forms, "MaximumExponents", $Failed];
  imageForms = Lookup[forms, "Forms", $Failed];
  If[! IntegerQ[epsilonMod] || ! (0 <= epsilonMod < prime) ||
      multiquadraticStripModRational[forms["EpsilonValue"], prime] =!= epsilonMod ||
      ! MatchQ[maximumExponents, {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! AssociationQ[imageForms], Return[False]];
  rationalLeaves = Cases[imageForms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticRationalImageV1" :>
      association, {0, Infinity}];
  TrueQ[rationalLeaves =!= {} &&
    AllTrue[rationalLeaves, multiquadraticStripRationalImageValidQ[#1, prime] &] &&
    multiquadraticStripMaximumExponents[imageForms] === maximumExponents &&
    multiquadraticStripFingerprint[multiquadraticStripFormShape[imageForms]] ===
      assembly["CompiledFormsShapeFingerprint"] === forms["FormsShapeFingerprint"] &&
    multiquadraticStripFingerprint[imageForms] === forms["FormsFingerprint"]]
];

multiquadraticStripEvaluatePolynomial[polynomial_Association,
    xPowers_Association, yPowers_Association, prime_Integer] := Module[
  {monomials, terms},
  If[polynomial["Coefficients"] === {}, Return[0]];
  monomials = Mod[Lookup[xPowers, polynomial["XExponents"]]
    Lookup[yPowers, polynomial["YExponents"]], prime];
  terms = Mod[polynomial["Coefficients"] monomials, prime];
  Mod[Total[terms], prime]
];

multiquadraticStripEvaluateRational[rational_Association, xPowers_Association,
    yPowers_Association, prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticStripEvaluatePolynomial[rational["Numerator"],
    xPowers, yPowers, prime];
  denominator = multiquadraticStripEvaluatePolynomial[rational["Denominator"],
    xPowers, yPowers, prime];
  If[denominator === 0, Throw[$Failed, "MultiquadraticStripBadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

multiquadraticStripEvaluateForms[forms_, xPowers_Association,
    yPowers_Association, prime_Integer] :=
  multiquadraticStripMapRationals[forms, "MultiquadraticRationalImageV1",
    multiquadraticStripEvaluateRational[#1, xPowers, yPowers, prime] &];

multiquadraticStripMaskFactorMod[mask_Integer, deltaValues_List, prime_Integer] :=
  Fold[Mod[#1 #2, prime] &, 1,
    Pick[deltaValues, BitGet[mask,
      If[deltaValues === {}, {}, Range[0, Length[deltaValues] - 1]]], 1]];

multiquadraticStripCharacter[signMask_Integer, grade_Integer, rank_Integer] :=
  If[Mod[Total[BitGet[BitAnd[signMask, grade],
      If[rank === 0, {}, Range[0, rank - 1]]]], 2] === 0, 1, -1];

(* ------------------------------------------------------------------ *)
(* Point and sample assembly (production: no branch flip)               *)
(* ------------------------------------------------------------------ *)

multiquadraticStripAssemblePointInternal[assembly_Association,
    epsilonForms_Association, prime_Integer, point : {_Integer, _Integer},
    validatedFingerprint_: Automatic] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["GaugeSupport"], supportCount, unknownCount,
   gaugeUnknownCount, oneFormCount, epsilonMod, forms, imagePolynomials,
   requiredXExponents, requiredYExponents, x, y, xPowers, yPowers, evaluated,
   primitiveEvaluated, primitiveDeltaValues, primitiveDenominatorValue,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   gaugeLogDerivatives, rootLogDerivatives, eValues, cValues, bbarValues,
   oneFormValues, monomialValues, basisValues, basisDerivatives, xInverse,
   yInverse, half, logarithmicDerivative, targetGrade, sourceGrade,
   productGrade, productFactor, mu, i, j, a, b, letter, monomial,
   productWeight, productGrades, productWeights, rowIndex, rowCount, rows,
   right, row, gaugeRow, residueRow, residueRowExpectedWidth, assemblySeconds},
  If[validatedFingerprint =!= assembly["AssemblyFingerprint"] &&
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Throw[multiquadraticStripFailure["InvalidRegulatorForms"],
      "MultiquadraticStripAssemblyFailure"]];
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = epsilonForms["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[multiquadraticStripFailure["ZeroRegulatorImage"],
      "MultiquadraticStripAssemblyFailure"]];
  {x, y} = Mod[point, prime];
  If[x === 0 || y === 0,
    Throw[multiquadraticStripFailure["ZeroPointCoordinate", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  forms = epsilonForms["Forms"];
  imagePolynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  requiredXExponents = Union[support[[All, 1]],
    Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
  requiredYExponents = Union[support[[All, 2]],
    Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
  xPowers = AssociationThread[requiredXExponents,
    PowerMod[x, #1, prime] & /@ requiredXExponents];
  yPowers = AssociationThread[requiredYExponents,
    PowerMod[y, #1, prime] & /@ requiredYExponents];
  evaluated = Catch[multiquadraticStripEvaluateForms[forms, xPowers, yPowers,
    prime], "MultiquadraticStripBadPoint"];
  If[evaluated === $Failed,
    (* separate the two admissible reasons for a bad point: a ramified
       or non-split root image, and a zero of the gauge denominator *)
    primitiveEvaluated = Catch[multiquadraticStripEvaluateForms[
      KeyTake[forms, {"RootSquares", "GaugeDenominator"}], xPowers, yPowers,
      prime], "MultiquadraticStripBadPoint"];
    If[AssociationQ[primitiveEvaluated],
      primitiveDeltaValues = primitiveEvaluated["RootSquares"];
      If[VectorQ[primitiveDeltaValues, IntegerQ] &&
          Length[primitiveDeltaValues] === assembly["RootCount"] &&
          MemberQ[primitiveDeltaValues, 0],
        Throw[multiquadraticStripFailure["DegenerateRootImage",
          <|"Point" -> point, "DeltaValues" -> primitiveDeltaValues|>],
          "MultiquadraticStripAssemblyFailure"]];
      primitiveDenominatorValue = primitiveEvaluated["GaugeDenominator"];
      If[IntegerQ[primitiveDenominatorValue] && primitiveDenominatorValue === 0,
        Throw[multiquadraticStripFailure["ZeroGaugeDenominator",
          <|"Point" -> point|>], "MultiquadraticStripAssemblyFailure"]]];
    Throw[multiquadraticStripFailure["RationalChannelPole", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  deltaValues = evaluated["RootSquares"];
  If[! VectorQ[deltaValues, IntegerQ] ||
      Length[deltaValues] =!= assembly["RootCount"] || MemberQ[deltaValues, 0],
    Throw[multiquadraticStripFailure["DegenerateRootImage",
      <|"Point" -> point, "DeltaValues" -> deltaValues|>],
      "MultiquadraticStripAssemblyFailure"]];
  denominatorValue = evaluated["GaugeDenominator"];
  If[! IntegerQ[denominatorValue] || denominatorValue === 0,
    Throw[multiquadraticStripFailure["ZeroGaugeDenominator", <|"Point" -> point|>],
      "MultiquadraticStripAssemblyFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  deltaMaskFactors = Developer`ToPackedArray[
    multiquadraticStripMaskFactorMod[#1, deltaValues, prime] & /@
      Range[0, gradeCount - 1]];
  gaugeLogDerivatives = evaluated["GaugeLogDerivatives"];
  rootLogDerivatives = evaluated["RootLogDerivatives"];
  eValues = evaluated["E"];
  cValues = evaluated["C"];
  bbarValues = evaluated["BBar"];
  oneFormValues = evaluated["OneForms"];
  xInverse = PowerMod[x, -1, prime];
  yInverse = PowerMod[y, -1, prime];
  half = PowerMod[2, -1, prime];
  monomialValues = Developer`ToPackedArray[Table[
    Mod[xPowers[support[[monomial, 1]]] yPowers[support[[monomial, 2]]], prime],
    {monomial, supportCount}]];
  basisValues = Developer`ToPackedArray[Table[
    Mod[monomialValues[[monomial]] denominatorInverse, prime],
    {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  (* d_mu (x^p y^q / Q r_grade) / r_grade *)
  basisDerivatives = Developer`ToPackedArray[Table[
    logarithmicDerivative = Mod[
      If[mu === 1, support[[monomial, 1]] xInverse,
        support[[monomial, 2]] yInverse] - gaugeLogDerivatives[[mu]] +
      half Sum[If[BitGet[sourceGrade, a - 1] === 1,
        rootLogDerivatives[[a, mu]], 0], {a, assembly["RootCount"]}], prime];
    Mod[basisValues[[sourceGrade + 1, monomial]] logarithmicDerivative, prime],
    {mu, 2}, {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  productGrades = Developer`ToPackedArray[Table[BitXor[targetGrade, sourceGrade],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1}]];
  productWeights = Developer`ToPackedArray[Table[
    productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
    productFactor = deltaMaskFactors[[BitAnd[productGrade, sourceGrade] + 1]];
    Mod[Mod[epsilonMod basisValues[[sourceGrade + 1, monomial]], prime]
      productFactor, prime],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1},
    {monomial, supportCount}]];
  rowCount = assembly["EquationsPerPoint"];
  rows = Table[ConstantArray[0, unknownCount], rowCount];
  right = ConstantArray[0, rowCount];
  Do[
    rowIndex = multiquadraticStripPointRowIndex[targetGrade, mu, i, j,
      upperDimension, lowerDimension];
    gaugeRow = Flatten[Table[
      productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
      productWeight = productWeights[[targetGrade + 1, sourceGrade + 1, monomial]];
      Mod[Mod[
          If[targetGrade === sourceGrade && a === i && b === j,
            basisDerivatives[[mu, sourceGrade + 1, monomial]], 0] +
          If[b === j, -productWeight eValues[[mu, i, a, productGrade + 1]], 0],
          prime] +
        If[a === i, productWeight cValues[[mu, b, j, productGrade + 1]], 0],
        prime],
      {a, upperDimension}, {b, lowerDimension},
      {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
    residueRow = Flatten[Table[
      If[a === i && b === j,
        Mod[epsilonMod oneFormValues[[letter, mu, targetGrade + 1]], prime], 0],
      {letter, oneFormCount}, {a, upperDimension}, {b, lowerDimension}]];
    If[Length[residueRow] =!= residueRowExpectedWidth,
      Throw[multiquadraticStripFailure["ResidueRowWidthMismatch",
        <|"Expected" -> residueRowExpectedWidth,
          "Observed" -> Length[residueRow]|>],
        "MultiquadraticStripAssemblyFailure"]];
    row = Join[gaugeRow, residueRow];
    If[Length[row] =!= unknownCount,
      Throw[multiquadraticStripFailure["RowWidthMismatch",
        <|"Expected" -> unknownCount, "Observed" -> Length[row]|>],
        "MultiquadraticStripAssemblyFailure"]];
    rows[[rowIndex]] = Developer`ToPackedArray[row];
    right[[rowIndex]] = Mod[bbarValues[[mu, i, j, targetGrade + 1]], prime],
    {targetGrade, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  rows = Developer`ToPackedArray[rows];
  right = Developer`ToPackedArray[right];
  assemblySeconds = N[AbsoluteTime[] - startTime];
  <|"Status" -> "AssembledMultiquadraticPointV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"], "Prime" -> prime,
    "EpsilonValue" -> epsilonForms["EpsilonValue"], "EpsilonMod" -> epsilonMod,
    "Point" -> {x, y}, "DeltaValues" -> deltaValues, "Rows" -> rows,
    "RightHandSide" -> right, "MatrixDimensions" -> Dimensions[rows],
    "Dimensions" -> dimensions, "RootCount" -> assembly["RootCount"],
    "GradeCount" -> gradeCount, "EquationsPerGrade" -> 2 Times @@ dimensions,
    "UnknownCount" -> unknownCount, "RowBasis" -> "MultiquadraticGradeBasis",
    "AssemblySeconds" -> assemblySeconds|>
], "MultiquadraticStripAssemblyFailure"];

multiquadraticStripAssemblePoint[assembly_Association,
    epsilonForms_Association, prime_Integer,
    point : {_Integer, _Integer}] := Module[{result},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidPointAssemblyInput"]]];
  result = multiquadraticStripAssemblePointInternal[assembly, epsilonForms,
    prime, point];
  If[AssociationQ[result], result,
    multiquadraticStripFailure["PointAssemblyDidNotReturnAssociation"]]
];
multiquadraticStripAssemblePoint[___] :=
  multiquadraticStripFailure["InvalidPointAssemblyArguments"];

multiquadraticStripNormalizationRows[assembly_Association, epsilonValue_,
    prime_Integer] := Module[
  {unknownCount = assembly["UnknownCount"], epsilon = assembly["Regulator"],
   rows, right},
  rows = Table[Developer`ToPackedArray[ReplacePart[
      ConstantArray[0, unknownCount], normalization["Column"] -> 1]],
    {normalization, assembly["Normalizations"]}];
  right = multiquadraticStripModRational[
      #1["Value"] /. epsilon -> epsilonValue, prime] & /@
    assembly["Normalizations"];
  If[MemberQ[right, $Failed], $Failed,
    {Developer`ToPackedArray[rows], Developer`ToPackedArray[right]}]
];

(* The production sampler.  It has NO branch-flip option: a direct
   grade row is branch invariant, so a flip mask changes no equation
   and recording one would suggest the sample depended on it (package
   bug handoff 2026-08-23, External gap 1).  Passing the option is a
   typed error.
   The grade rows need no split point at all -- that is the point of
   the direct channel basis -- so "SplitPointsOnly" defaults to False.
   A caller that will transform the sample into sign branches (the
   certificate path) asks for split points explicitly. *)
Options[multiquadraticStripAssembleSample] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "CandidatePoints" -> Automatic,
  "SplitPointsOnly" -> False
};

multiquadraticStripAssembleSample[assembly_Association, epsilonValue_,
    prime_Integer, opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, epsilonForms, pointCount, maximumAttempts,
   randomSeed, candidatePoints, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0, point,
   pointResult, pointRows, pointRight, normalization, matrix, right,
   pointRanges, equationCount, splitOnly},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyInput"]]];
  epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticStripEpsilonFormsV1" ||
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[If[AssociationQ[epsilonForms] &&
        Lookup[epsilonForms, "Status", None] =!=
          "MultiquadraticStripEpsilonFormsV1", epsilonForms,
      multiquadraticStripFailure["RegulatorFormsInvalid"]]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(assembly["UnknownCount"] + assembly["EquationsPerPoint"])/
      assembly["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  splitOnly = TrueQ[OptionValue["SplitPointsOnly"]];
  If[! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[maximumAttempts] ||
      maximumAttempts < pointCount || ! IntegerQ[randomSeed] ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyOptions"]]];
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts,
      attempts++;
      point = If[candidatePoints === Automatic,
        RandomInteger[{2, prime - 2}, 2],
        candidateIndex++;
        If[candidateIndex > Length[candidatePoints], Break[]];
        candidatePoints[[candidateIndex]]];
      pointResult = multiquadraticStripAssemblePointInternal[assembly,
        epsilonForms, prime, point, assembly["AssemblyFingerprint"]];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1" &&
          splitOnly && ! AllTrue[pointResult["DeltaValues"],
            JacobiSymbol[#1, prime] === 1 &],
        pointResult = multiquadraticStripFailure["PointNotSplitOverPrime",
          <|"Point" -> point|>]];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1",
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> point,
            "FailureReason" -> "DuplicatePointModuloPrime"|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, pointResult]],
        AppendTo[rejected, <|"Point" -> point,
          "FailureReason" -> Lookup[pointResult, "Status", None]|>]]]
  ];
  If[Length[accepted] < pointCount,
    Return[multiquadraticStripFailure["InsufficientDirectChannelPoints",
      <|"AcceptedPointCount" -> Length[accepted], "AttemptCount" -> attempts,
        "RejectedPoints" -> rejected|>]]];
  normalization = multiquadraticStripNormalizationRows[assembly, epsilonValue,
    prime];
  If[normalization === $Failed,
    Return[multiquadraticStripFailure["NormalizationValueSingular"]]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[Join[pointRows, normalization[[1]]]];
  right = Developer`ToPackedArray[Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = assembly["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "ABIFingerprint" -> assembly["ABIFingerprint"],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "SourceSHA256" -> assembly["SourceSHA256"], "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsilonForms["EpsilonMod"],
    "Matrix" -> matrix, "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointDeltaValues" -> Lookup[accepted, "DeltaValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "SplitPointsOnly" -> splitOnly,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> assembly["ColumnOrder"], "RowOrder" -> assembly["RowOrder"],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripAssembleSample[___] :=
  multiquadraticStripFailure["InvalidSampleAssemblyArguments"];

(* ------------------------------------------------------------------ *)
(* Sign transforms and the differential certificate                     *)
(* ------------------------------------------------------------------ *)

(* The only place a branch sign exists: the invertible map from grade
   rows to the 2^r split-sign rows at a point.  A flip mask permutes
   the sign blocks and is the object under test, never a production
   parameter. *)
multiquadraticStripSignTransform[rootValues_List, prime_Integer] := Module[
  {rank = Length[rootValues], gradeCount, rootProducts},
  If[! PrimeQ[prime] || rank > $multiquadraticStripMaximumRootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &],
    Return[multiquadraticStripFailure["InvalidSignTransformInput"]]];
  gradeCount = 2^rank;
  rootProducts = multiquadraticStripMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  Developer`ToPackedArray[Table[
    Mod[multiquadraticStripCharacter[signMask, grade, rank]
      rootProducts[[grade + 1]], prime],
    {signMask, 0, gradeCount - 1}, {grade, 0, gradeCount - 1}]]
];

multiquadraticStripTransformPointToSigns[pointResult_Association,
    rootValues_List, prime_Integer, flipMask_Integer: 0] := Module[
  {rootCount, gradeCount, equationsPerGrade, unknownCount, deltaValues,
   pointRows, pointRight, transform, rowsByGrade, rightByGrade, rows, right,
   transformedRow, transformedRight, sourceSign, targetGrade},
  If[Lookup[pointResult, "Status", None] =!= "AssembledMultiquadraticPointV1" ||
      Lookup[pointResult, "Prime", None] =!= prime,
    Return[multiquadraticStripFailure["InvalidPointTransformInput"]]];
  rootCount = Lookup[pointResult, "RootCount", $Failed];
  gradeCount = Lookup[pointResult, "GradeCount", $Failed];
  equationsPerGrade = Lookup[pointResult, "EquationsPerGrade", $Failed];
  unknownCount = Lookup[pointResult, "UnknownCount", $Failed];
  deltaValues = Lookup[pointResult, "DeltaValues", $Failed];
  pointRows = Lookup[pointResult, "Rows", $Failed];
  pointRight = Lookup[pointResult, "RightHandSide", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 || ! IntegerQ[gradeCount] ||
      gradeCount =!= 2^rootCount || ! IntegerQ[equationsPerGrade] ||
      equationsPerGrade < 1 || ! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! MatrixQ[pointRows, IntegerQ] ||
      Dimensions[pointRows] =!= {gradeCount equationsPerGrade, unknownCount} ||
      ! AllTrue[Flatten[pointRows], 0 <= #1 < prime &] ||
      ! VectorQ[pointRight, IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[pointRight] =!= gradeCount equationsPerGrade ||
      ! VectorQ[deltaValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Length[deltaValues] =!= rootCount || Length[rootValues] =!= rootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Mod[rootValues^2 - deltaValues, prime] =!= ConstantArray[0, rootCount] ||
      ! IntegerQ[flipMask] || flipMask < 0 || flipMask >= gradeCount,
    Return[multiquadraticStripFailure["InvalidPointTransformParameters"]]];
  transform = multiquadraticStripSignTransform[rootValues, prime];
  If[! ListQ[transform],
    Return[multiquadraticStripFailure["SignTransformFailed"]]];
  rowsByGrade = ArrayReshape[pointRows,
    {gradeCount, equationsPerGrade, unknownCount}];
  rightByGrade = ArrayReshape[pointRight, {gradeCount, equationsPerGrade}];
  rows = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRow = ConstantArray[0, unknownCount];
      Do[transformedRow = Mod[transformedRow +
          transform[[sourceSign + 1, targetGrade + 1]]
            rowsByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      Developer`ToPackedArray[transformedRow],
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  right = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRight = 0;
      Do[transformedRight = Mod[transformedRight +
          transform[[sourceSign + 1, targetGrade + 1]]
            rightByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      transformedRight,
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  <|"Status" -> "TransformedMultiquadraticPointToSignsV1", "Prime" -> prime,
    "Point" -> pointResult["Point"], "RootValues" -> rootValues,
    "BranchFlipMask" -> flipMask, "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "SignTransform" -> transform|>
];
multiquadraticStripTransformPointToSigns[___] :=
  multiquadraticStripFailure["InvalidPointTransformArguments"];

multiquadraticStripTransformSampleToSigns[assembly_Association,
    sample_Association, prime_Integer, flipMask_Integer: 0] := Module[
  {pointCount, equationCount, normalizationCount, pointResults, transformed,
   deltaValues, rootValues, rows, right, normalizationRows, normalizationRight,
   index, range, expectedRanges, totalRows},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3 ||
      Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1" ||
      Lookup[sample, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] || sample["Prime"] =!= prime,
    Return[multiquadraticStripFailure["InvalidSampleTransformInput"]]];
  pointCount = Length[sample["AcceptedPoints"]];
  equationCount = assembly["EquationsPerPoint"];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  totalRows = pointCount equationCount + normalizationCount;
  expectedRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, pointCount}];
  If[pointCount < 1 || ! IntegerQ[normalizationCount] || normalizationCount < 0 ||
      ! MatchQ[sample["AcceptedPoints"], {{_Integer, _Integer} ..}] ||
      ! ListQ[Lookup[sample, "PointDeltaValues", None]] ||
      Length[sample["PointDeltaValues"]] =!= pointCount ||
      Lookup[sample, "PointRowRanges", None] =!= expectedRanges ||
      ! MatrixQ[Lookup[sample, "Matrix", None], IntegerQ] ||
      Dimensions[sample["Matrix"]] =!= {totalRows, assembly["UnknownCount"]} ||
      ! VectorQ[Lookup[sample, "RightHandSide", None],
        IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[sample["RightHandSide"]] =!= totalRows,
    Return[multiquadraticStripFailure["InvalidSampleTransformShape"]]];
  pointResults = Table[
    range = sample["PointRowRanges"][[index]];
    <|"Status" -> "AssembledMultiquadraticPointV1", "Prime" -> prime,
      "Point" -> sample["AcceptedPoints"][[index]],
      "Rows" -> sample["Matrix"][[range[[1]] ;; range[[2]]]],
      "RightHandSide" -> sample["RightHandSide"][[range[[1]] ;; range[[2]]]],
      "DeltaValues" -> sample["PointDeltaValues"][[index]],
      "RootCount" -> assembly["RootCount"], "GradeCount" -> assembly["GradeCount"],
      "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
      "UnknownCount" -> assembly["UnknownCount"]|>,
    {index, pointCount}];
  (* Return inside Table does not leave the enclosing function: the
     Codex original (DirectRootChannelAssembler.wl lines 1088-1099)
     leaves an unevaluated Return in the result list, which then
     degrades into a generic transform failure.  Tag the target. *)
  transformed = Table[
    deltaValues = sample["PointDeltaValues"][[index]];
    If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
      Return[multiquadraticStripFailure["PointNotSplitOverPrime",
        <|"PointIndex" -> index, "DeltaValues" -> deltaValues|>], Module]];
    rootValues = multiquadraticSquareRoots[deltaValues, prime];
    If[rootValues === $Failed,
      Return[multiquadraticStripFailure["PointSquareRootFailure",
        <|"PointIndex" -> index|>], Module]];
    multiquadraticStripTransformPointToSigns[pointResults[[index]], rootValues,
      prime, flipMask],
    {index, pointCount}];
  If[! AllTrue[transformed, Lookup[#1, "Status", None] ===
      "TransformedMultiquadraticPointToSignsV1" &],
    Return[multiquadraticStripFailure["SamplePointTransformFailed"]]];
  rows = Join @@ Lookup[transformed, "Rows"];
  right = Join @@ Lookup[transformed, "RightHandSide"];
  If[normalizationCount > 0,
    normalizationRows = Take[sample["Matrix"], -normalizationCount];
    normalizationRight = Take[sample["RightHandSide"], -normalizationCount];
    rows = Join[rows, normalizationRows];
    right = Join[right, normalizationRight]];
  <|"Status" -> "TransformedMultiquadraticSampleToSignsV1", "Prime" -> prime,
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "BranchFlipMask" -> flipMask|>
];
multiquadraticStripTransformSampleToSigns[___] :=
  multiquadraticStripFailure["InvalidSampleTransformArguments"];

(* The independent reference: the same equations built one sign branch
   at a time by substituting +-root values into the exact strip, with no
   channel decomposition and no compiled ABI.  It shares nothing with
   the direct assembler except the index formulas, so agreement is a
   real differential statement. *)
multiquadraticStripSplitPointRows[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Catch[Module[
  {variables, epsilon, record, strip, e, c, bbar, roots, oneForms, support,
   gaugeDenominator, dimensions, upperDimension, lowerDimension, rank,
   gradeCount, supportCount, gaugeUnknownCount, unknownCount, epsilonMod,
   deltaValues, rootValues, denominatorValue, denominatorInverse,
   denominatorDerivatives, deltaLogDerivatives, rootProducts, signs,
   branchValue, branchMatrix, branchPair, basisValue, basisDerivative,
   eValues, cValues, bbarValues, oneFormValues, rows, right, row, rowIndex,
   sourceSign, xPower, yPower, monomialValue, monomialLog, value},
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  record = assembly["Record"];
  roots = assembly["Roots"];
  oneForms = assembly["OneForms"];
  support = assembly["GaugeSupport"];
  gaugeDenominator = assembly["GaugeDenominator"];
  strip = record["Strip"];
  {e, c, bbar} = strip;
  dimensions = assembly["Dimensions"];
  {upperDimension, lowerDimension} = dimensions;
  rank = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  supportCount = Length[support];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  unknownCount = assembly["UnknownCount"];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Throw[multiquadraticStripFailure["InvalidRegulatorImage"],
      "MultiquadraticStripSplitFailure"]];
  deltaValues = multiquadraticStripModRational[
      #1 /. Thread[variables -> point], prime] & /@ Lookup[roots, "RootSquare", {}];
  If[MemberQ[deltaValues, $Failed | 0] ||
      ! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Throw[multiquadraticStripFailure["PointNotSplitOverPrime",
      <|"Point" -> point|>], "MultiquadraticStripSplitFailure"]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Throw[multiquadraticStripFailure["PointSquareRootFailure"],
      "MultiquadraticStripSplitFailure"]];
  denominatorValue = multiquadraticStripModRational[
    gaugeDenominator /. Thread[variables -> point] /. epsilon -> epsilonValue,
    prime];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Throw[multiquadraticStripFailure["ZeroGaugeDenominator"],
      "MultiquadraticStripSplitFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  denominatorDerivatives = multiquadraticStripModRational[
      D[gaugeDenominator, #1] /. Thread[variables -> point] /.
        epsilon -> epsilonValue, prime] & /@ variables;
  If[MemberQ[denominatorDerivatives, $Failed],
    Throw[multiquadraticStripFailure["GaugeDenominatorDerivativeSingular"],
      "MultiquadraticStripSplitFailure"]];
  deltaLogDerivatives = Table[
    value = multiquadraticStripModRational[
      D[roots[[a, "RootSquare"]], variables[[mu]]]/roots[[a, "RootSquare"]] /.
        Thread[variables -> point], prime];
    If[value === $Failed,
      Throw[multiquadraticStripFailure["RootLogDerivativeSingular"],
        "MultiquadraticStripSplitFailure"]];
    value,
    {a, rank}, {mu, 2}];
  rootProducts = multiquadraticStripMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  branchValue[expression_, signList_] := Module[{branched, image},
    branched = transportChartApplyRootBranches[expression, roots,
      Mod[signList rootValues, prime]];
    image = multiquadraticStripModRational[
      branched /. Thread[variables -> point] /. epsilon -> epsilonValue, prime];
    If[image === $Failed,
      Throw[multiquadraticStripFailure["BranchValueSingular"],
        "MultiquadraticStripSplitFailure"]];
    image];
  branchMatrix[matrix_, signList_] := Map[branchValue[#1, signList] &, matrix, {2}];
  branchPair[pair_, signList_] := branchMatrix[#1, signList] & /@ pair;
  eValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[e, signs], {signMask, 0, gradeCount - 1}];
  cValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[c, signs], {signMask, 0, gradeCount - 1}];
  bbarValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[bbar, signs], {signMask, 0, gradeCount - 1}];
  oneFormValues = Table[
    signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchValue[oneForms[[letter, mu]], signs],
    {signMask, 0, gradeCount - 1}, {letter, Length[oneForms]}, {mu, 2}];
  rows = Table[ConstantArray[0, unknownCount], gradeCount 2 upperDimension lowerDimension];
  right = ConstantArray[0, gradeCount 2 upperDimension lowerDimension];
  Do[
    sourceSign = BitXor[signMask, flipMask];
    rowIndex = multiquadraticStripPointRowIndex[signMask, mu, i, j,
      upperDimension, lowerDimension];
    row = ConstantArray[0, unknownCount];
    Do[
      {xPower, yPower} = support[[monomial]];
      monomialValue = Mod[PowerMod[Mod[point[[1]], prime], xPower, prime]
        PowerMod[Mod[point[[2]], prime], yPower, prime], prime];
      basisValue = Mod[multiquadraticStripCharacter[sourceSign, grade, rank]
        rootProducts[[grade + 1]] monomialValue denominatorInverse, prime];
      monomialLog = If[mu === 1,
        If[xPower === 0, 0,
          Mod[xPower PowerMod[Mod[point[[1]], prime], -1, prime], prime]],
        If[yPower === 0, 0,
          Mod[yPower PowerMod[Mod[point[[2]], prime], -1, prime], prime]]];
      basisDerivative = Mod[basisValue Mod[monomialLog -
        denominatorDerivatives[[mu]] denominatorInverse +
        PowerMod[2, -1, prime] Sum[If[BitGet[grade, a - 1] === 1,
          deltaLogDerivatives[[a, mu]], 0], {a, rank}], prime], prime];
      row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
        gradeCount, supportCount, i, j, grade, monomial]]] +=
        basisDerivative;
      Do[row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, a, j, grade, monomial]]] +=
          -epsilonMod eValues[[sourceSign + 1, mu, i, a]] basisValue,
        {a, upperDimension}];
      Do[row[[multiquadraticStripGaugeIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, i, b, grade, monomial]]] +=
          epsilonMod cValues[[sourceSign + 1, mu, b, j]] basisValue,
        {b, lowerDimension}],
      {grade, 0, gradeCount - 1}, {monomial, supportCount}];
    Do[row[[multiquadraticStripResidueIndex[gaugeUnknownCount, upperDimension,
        lowerDimension, letter, i, j]]] +=
        epsilonMod oneFormValues[[sourceSign + 1, letter, mu]],
      {letter, Length[oneForms]}];
    rows[[rowIndex]] = Mod[row, prime];
    right[[rowIndex]] = Mod[bbarValues[[sourceSign + 1, mu, i, j]], prime],
    {signMask, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  <|"Status" -> "MultiquadraticSplitPointRowsV1", "Prime" -> prime,
    "Point" -> Mod[point, prime], "DeltaValues" -> deltaValues,
    "RootValues" -> rootValues, "BranchFlipMask" -> flipMask,
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "UnknownCount" -> unknownCount|>
], "MultiquadraticStripSplitFailure"];

multiquadraticStripDifferentialCheckPoint[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Module[
  {startTime = AbsoluteTime[], epsilonForms, direct, deltaValues, rootValues,
   transformed, reference, matrixEqual, rightEqual, passed},
  If[! multiquadraticStripCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3,
    Return[multiquadraticStripFailure["InvalidDifferentialAssembly"]]];
  epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticStripEpsilonFormsV1" ||
      ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[multiquadraticStripFailure["DifferentialRegulatorCollapseFailed"]]];
  direct = multiquadraticStripAssemblePointInternal[assembly, epsilonForms,
    prime, point, assembly["AssemblyFingerprint"]];
  If[Lookup[direct, "Status", None] =!= "AssembledMultiquadraticPointV1",
    Return[direct]];
  deltaValues = direct["DeltaValues"];
  If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Return[multiquadraticStripFailure["DifferentialPointNotSplit",
      <|"DeltaValues" -> deltaValues|>]]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Return[multiquadraticStripFailure["DifferentialSquareRootFailure"]]];
  transformed = multiquadraticStripTransformPointToSigns[direct, rootValues,
    prime, flipMask];
  If[Lookup[transformed, "Status", None] =!=
      "TransformedMultiquadraticPointToSignsV1", Return[transformed]];
  reference = multiquadraticStripSplitPointRows[assembly, epsilonValue, prime,
    point, flipMask];
  If[Lookup[reference, "Status", None] =!= "MultiquadraticSplitPointRowsV1",
    Return[reference]];
  matrixEqual = TrueQ[Normal[transformed["Rows"]] === Normal[reference["Rows"]]];
  rightEqual = TrueQ[Normal[transformed["RightHandSide"]] ===
    Normal[reference["RightHandSide"]]];
  passed = TrueQ[matrixEqual && rightEqual];
  <|"Status" -> If[passed, "MultiquadraticPointDifferentialPassed",
      "MultiquadraticPointDifferentialFailed"],
    "Passed" -> passed, "MatrixEqual" -> matrixEqual,
    "RightHandSideEqual" -> rightEqual, "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "Point" -> point,
    "RootCount" -> assembly["RootCount"], "BranchFlipMask" -> flipMask,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripDifferentialCheckPoint[___] :=
  multiquadraticStripFailure["InvalidDifferentialPointArguments"];

(* ------------------------------------------------------------------ *)
(* Modular solve, unpacking, exact verification                         *)
(* ------------------------------------------------------------------ *)

(* Deterministic RREF: a particular solution with every free column
   zero, plus the nullspace basis, plus the residual check.  The pivot
   columns are the elimination signature that must not move between
   primes or regulator values. *)
multiquadraticStripAffineSolve[matrix_?MatrixQ, right_List, prime_Integer] :=
  Module[
  {dimensions = Dimensions[matrix], unknownCount, augmented, reduced,
   coefficientPart, pivotRows = {}, pivotColumns = {}, position,
   inconsistentRows, freeColumns, particular, nullspace, residual, nullResidual},
  If[! PrimeQ[prime],
    Return[multiquadraticStripFailure["InvalidPrime", <|"Prime" -> prime|>]]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[multiquadraticStripFailure["AffineDimensionMismatch"]]];
  unknownCount = dimensions[[2]];
  augmented = MapThread[Append, {Mod[Normal[matrix], prime], Mod[right, prime]}];
  reduced = RowReduce[augmented, Modulus -> prime];
  coefficientPart = reduced[[All, 1 ;; unknownCount]];
  Do[
    position = SelectFirst[Range[unknownCount],
      Mod[coefficientPart[[row, #1]], prime] =!= 0 &, Missing["NotFound"]];
    If[! MissingQ[position],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, position]],
    {row, Length[coefficientPart]}];
  If[! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, IntegerQ[#1] && 1 <= #1 <= unknownCount &] ||
      Length[pivotColumns] > Min[dimensions],
    Return[multiquadraticStripFailure["InvalidPivotStructure",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "PivotColumns" -> pivotColumns|>]]];
  inconsistentRows = Select[Range[Length[coefficientPart]],
    multiquadraticStripZeroQ[Mod[coefficientPart[[#1]], prime]] &&
      Mod[reduced[[#1, -1]], prime] =!= 0 &];
  If[inconsistentRows =!= {},
    (* the rank of the coefficient part and the affine defect belong to
       the typed failure: without them a recorded inconsistency says only
       that the system had no solution, and the driver's failure summary
       cannot tell a missing letter from too small an ansatz
       (2026-08-24) *)
    Return[multiquadraticStripFailure["InconsistentModularSystem",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "InconsistentRows" -> inconsistentRows,
        "Rank" -> Length[pivotColumns],
        "AugmentedRank" -> Length[pivotColumns] + Length[inconsistentRows],
        "Defect" -> Length[inconsistentRows],
        "Nullity" -> unknownCount - Length[pivotColumns]|>]]];
  freeColumns = Complement[Range[unknownCount], pivotColumns];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] = Mod[reduced[[pivotRows[[k]], -1]], prime],
    {k, Length[pivotColumns]}];
  nullspace = Table[Module[{vector = ConstantArray[0, unknownCount]},
    vector[[free]] = 1;
    Do[vector[[pivotColumns[[k]]]] = Mod[-reduced[[pivotRows[[k]], free]], prime],
      {k, Length[pivotColumns]}];
    vector], {free, freeColumns}];
  residual = AllTrue[Mod[matrix . particular - right, prime], #1 === 0 &];
  nullResidual = AllTrue[nullspace,
    Function[vector, AllTrue[Mod[matrix . vector, prime], #1 === 0 &]]];
  If[! (TrueQ[residual] && TrueQ[nullResidual]),
    Return[multiquadraticStripFailure["AffineResidualNonzero",
      <|"Prime" -> prime, "ResidualZero" -> residual,
        "NullspaceResidualZero" -> nullResidual|>]]];
  <|"Status" -> "MultiquadraticAffineSolution", "Prime" -> prime,
    "MatrixDimensions" -> dimensions, "Rank" -> Length[pivotColumns],
    "Nullity" -> Length[freeColumns], "PivotColumns" -> pivotColumns,
    "FreeColumns" -> freeColumns,
    "PivotSignature" -> Hash[pivotColumns, "SHA256", "HexString"],
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace|>
];
multiquadraticStripAffineSolve[___] :=
  multiquadraticStripFailure["InvalidAffineSolveArguments"];

multiquadraticStripUnpackVector[preparation_Association, vector_List] := Module[
  {dimensions, gradeCount, support, denominator, variables, gaugeUnknownCount,
   gaugeCoefficients, gaugeChannels, residues},
  If[! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparationABI"]]];
  If[Length[vector] =!= preparation["UnknownCount"],
    Return[multiquadraticStripFailure["ReconstructedVectorLengthMismatch",
      <|"Expected" -> preparation["UnknownCount"],
        "Observed" -> Length[vector]|>]]];
  dimensions = preparation["Dimensions"];
  gradeCount = preparation["GradeCount"];
  support = preparation["GaugeSupport"];
  denominator = preparation["GaugeDenominator"];
  variables = preparation["Variables"];
  gaugeUnknownCount = preparation["GaugeUnknownCount"];
  gaugeCoefficients = Table[
    vector[[multiquadraticStripGaugeIndex[dimensions[[1]], dimensions[[2]],
      gradeCount, Length[support], i, j, grade, monomial]]],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, 0, gradeCount - 1},
    {monomial, Length[support]}];
  gaugeChannels = Table[Together[
      Sum[gaugeCoefficients[[i, j, grade, monomial]]
          variables[[1]]^support[[monomial, 1]]
          variables[[2]]^support[[monomial, 2]],
        {monomial, Length[support]}]/denominator],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, gradeCount}];
  residues = If[preparation["ResidueUnknownCount"] === 0, {},
    Table[vector[[multiquadraticStripResidueIndex[gaugeUnknownCount,
      dimensions[[1]], dimensions[[2]], letter, i, j]]],
      {letter, Length[preparation["OneForms"]]}, {i, dimensions[[1]]},
      {j, dimensions[[2]]}]];
  <|"Status" -> "UnpackedMultiquadraticSolution",
    "GaugeCoefficients" -> gaugeCoefficients, "GaugeChannels" -> gaugeChannels,
    "Gauge" -> Table[multiquadraticFieldCompose[gaugeChannels[[i, j]],
        preparation["Roots"]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    "Residues" -> residues|>
];
multiquadraticStripUnpackVector[___] :=
  multiquadraticStripFailure["InvalidUnpackArguments"];

multiquadraticStripChannelMatrixProduct[left_List, right_List, deltas_List] :=
  Module[{leftDimensions = Dimensions[left], rightDimensions = Dimensions[right],
    inner},
  If[Length[leftDimensions] =!= 3 || Length[rightDimensions] =!= 3 ||
      leftDimensions[[2]] =!= rightDimensions[[1]] ||
      leftDimensions[[3]] =!= rightDimensions[[3]], Return[$Failed]];
  inner = leftDimensions[[2]];
  Table[Together /@ Total[Table[
      multiquadraticMultiply[left[[i, k]], right[[k, j]], deltas], {k, inner}]],
    {i, leftDimensions[[1]]}, {j, rightDimensions[[2]]}]
];

(* The exact statement about a reconstructed vector: every grade of
   d_mu G - eps (E G - G C) + eps R omega - Bbar vanishes identically in
   the chart variables.  With a regulator VALUE the identity is made at
   that value, which is what a per-value lift certifies. *)
multiquadraticStripExactChannelResidual[preparation_Association, vector_List,
    epsilonValue_: Automatic] := Module[
  {unpacked, gauge, residues, record, roots, deltas, variables, epsilon,
   epsilonImage, strip, decompose, eChannels, cChannels, bbarChannels,
   oneFormChannels, derivative, leftProduct, rightProduct, residueTerm, residual},
  unpacked = multiquadraticStripUnpackVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedMultiquadraticSolution",
    Return[unpacked]];
  gauge = unpacked["GaugeChannels"];
  residues = unpacked["Residues"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  deltas = Lookup[roots, "RootSquare", {}];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  epsilonImage = If[epsilonValue === Automatic, epsilon, epsilonValue];
  strip = record["Strip"] /. epsilon -> epsilonImage;
  decompose[matrix_] := Map[multiquadraticFieldDecompose[#1, roots] &, matrix, {2}];
  eChannels = decompose /@ strip[[1]];
  cChannels = decompose /@ strip[[2]];
  bbarChannels = decompose /@ strip[[3]];
  oneFormChannels = Table[
    multiquadraticFieldDecompose[
      preparation["OneForms"][[letter, mu]] /. epsilon -> epsilonImage, roots],
    {letter, Length[preparation["OneForms"]]}, {mu, 2}];
  If[! FreeQ[{eChannels, cChannels, bbarChannels, oneFormChannels}, $Failed],
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  residual = Table[
    derivative = Map[multiquadraticDerivative[#1, deltas, variables[[mu]]] &,
      gauge, {2}];
    leftProduct = multiquadraticStripChannelMatrixProduct[eChannels[[mu]], gauge,
      deltas];
    rightProduct = multiquadraticStripChannelMatrixProduct[gauge, cChannels[[mu]],
      deltas];
    If[leftProduct === $Failed || rightProduct === $Failed,
      Return[multiquadraticStripFailure["ExactChannelDimensionMismatch"], Module]];
    residueTerm = If[Length[preparation["OneForms"]] === 0,
      ConstantArray[0, Append[preparation["Dimensions"], preparation["GradeCount"]]],
      Table[Together /@ Total[Table[
          residues[[letter, i, j]] oneFormChannels[[letter, mu]],
          {letter, Length[preparation["OneForms"]]}]],
        {i, preparation["Dimensions"][[1]]}, {j, preparation["Dimensions"][[2]]}]];
    Map[Together, derivative - epsilonImage leftProduct +
      epsilonImage rightProduct + epsilonImage residueTerm -
      bbarChannels[[mu]], {3}],
    {mu, 2}];
  <|"Status" -> If[multiquadraticStripZeroQ[residual],
      "ExactChannelResidualZero", "ExactChannelResidualNonzero"],
    "ResidualZero" -> multiquadraticStripZeroQ[residual],
    "EpsilonValue" -> epsilonImage, "ResidualChannels" -> residual|>
];

(* CRT over the sampled primes, then rational reconstruction coordinate
   by coordinate (the package's epsFormFiniteFieldRationalReconstruct).
   A coordinate that does not lift is reported, not guessed. *)
multiquadraticStripLiftVector[images_List, primes_List] := Module[
  {modulus, combined, lifted, failures},
  If[Length[images] =!= Length[primes] || images === {} ||
      ! MatrixQ[images, IntegerQ] || ! VectorQ[primes, PrimeQ],
    Return[multiquadraticStripFailure["InvalidLiftInput"]]];
  If[! AllTrue[images, Length[#1] === Length[First[images]] &],
    Return[multiquadraticStripFailure["InconsistentLiftWidths"]]];
  modulus = Times @@ primes;
  combined = Table[ChineseRemainder[images[[All, index]], primes],
    {index, Length[First[images]]}];
  lifted = epsFormFiniteFieldRationalReconstruct[#1, modulus] & /@ combined;
  failures = Flatten[Position[lifted, $Failed, {1}, Heads -> False]];
  If[failures =!= {},
    Return[multiquadraticStripFailure["RationalReconstructionFailed",
      <|"Coordinates" -> failures, "Modulus" -> modulus|>]]];
  <|"Status" -> "LiftedMultiquadraticVector", "Vector" -> lifted,
    "Modulus" -> modulus, "Primes" -> primes|>
];

(* ------------------------------------------------------------------ *)
(* Artifacts: raw load and validation are separate                      *)
(* ------------------------------------------------------------------ *)

multiquadraticStripArtifactWrite[value_, file_String] := Module[
  {directory, temporary},
  directory = DirectoryName[ExpandFileName[file]];
  If[directory =!= "" && ! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True];
  <|"Status" -> "MultiquadraticArtifactWritten", "File" -> file,
    "SHA256" -> FileHash[file, "SHA256", "HexString"]|>
];

(* Raw hydration only.  The artifact context is explicit and its
   namespace is created before the read, so an artifact is never parsed
   into Global` by accident and never into CANONICA`; CheckAbort keeps
   a valid artifact that merely emitted a suppressed message (pool
   defects 3 and 4).  Nothing here decides admissibility -- the
   validator does. *)
multiquadraticStripArtifactLoadRaw[file_String, context_String] := Module[
  {value, messages},
  If[! StringEndsQ[context, "`"],
    Return[multiquadraticStripFailure["InvalidArtifactContext",
      <|"Context" -> context|>]]];
  If[! FileExistsQ[file],
    Return[multiquadraticStripFailure["ArtifactFileMissing", <|"File" -> file|>]]];
  {value, messages} = Block[
    {$Context = context, $ContextPath = {context, "System`"}, $MessageList = {}},
    Quiet[{CheckAbort[Get[file], $Aborted], $MessageList}]];
  If[value === $Aborted,
    Return[multiquadraticStripFailure["ArtifactReadAborted",
      <|"File" -> file, "Messages" -> ToString[messages]|>]]];
  <|"Status" -> "RawMultiquadraticArtifact", "File" -> file,
    "Context" -> context, "Value" -> value,
    "Messages" -> ToString[messages],
    "SHA256" -> FileHash[file, "SHA256", "HexString"]|>
];

multiquadraticStripReadPreparedArtifact[file_String,
    context_String: "FeynFacet`MultiquadraticArtifact`"] := Module[
  {raw, value},
  raw = multiquadraticStripArtifactLoadRaw[file, context];
  If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact", Return[raw]];
  value = raw["Value"];
  If[! AssociationQ[value],
    Return[multiquadraticStripFailure["ArtifactNotAnAssociation",
      <|"File" -> file, "Head" -> ToString[Head[value]]|>]]];
  Which[
    Lookup[value, "Status", None] === "PreparedMultiquadraticStripV1",
      If[multiquadraticStripPreparationValidQ[value],
        <|"Status" -> "HydratedMultiquadraticPreparation", "File" -> file,
          "Context" -> context, "Preparation" -> value,
          "ABIFingerprint" -> value["ABIFingerprint"]|>,
        multiquadraticStripFailure["ArtifactPreparationABIInvalid",
          <|"File" -> file|>]],
    Lookup[value, "Status", None] === "CompiledMultiquadraticStripV1",
      If[multiquadraticStripCompiledValidQ[value],
        <|"Status" -> "HydratedMultiquadraticAssembly", "File" -> file,
          "Context" -> context, "Assembly" -> value,
          "AssemblyFingerprint" -> value["AssemblyFingerprint"]|>,
        multiquadraticStripFailure["ArtifactAssemblyABIInvalid",
          <|"File" -> file|>]],
    True,
      multiquadraticStripFailure["ArtifactSchemaUnknown",
        <|"File" -> file, "ArtifactStatus" -> Lookup[value, "Status", None]|>]]
];
multiquadraticStripReadPreparedArtifact[___] :=
  multiquadraticStripFailure["InvalidArtifactReadArguments"];

(* ------------------------------------------------------------------ *)
(* Option gates                                                         *)
(* ------------------------------------------------------------------ *)

multiquadraticStripOptionNames[opts_List] :=
  Cases[Flatten[opts], (name_ -> _) | (name_ :> _) :> name];

(* A production entry point refuses a branch flip outright and refuses
   an unknown option rather than ignoring it silently. *)
multiquadraticStripProductionOptionGate[opts_List, allowed_List] := Module[
  {names = multiquadraticStripOptionNames[opts], unknown},
  If[MemberQ[names, "BranchFlipMask"],
    Return[multiquadraticStripFailure["BranchFlipMaskNotAvailableInProduction",
      <|"Reason" -> "direct grade rows are branch invariant; sign flips exist only in the sign-transform and differential-certificate functions"|>]]];
  unknown = DeleteDuplicates[Select[names, ! MemberQ[allowed, #1] &]];
  If[unknown =!= {},
    Return[multiquadraticStripFailure["UnknownOption", <|"Options" -> unknown|>]]];
  None
];

(* The requested backend is validated exhaustively: an unavailable one
   fails closed rather than falling through to the Wolfram path
   (package bug handoff 2026-08-23, existing defect 1). *)
multiquadraticStripBackendGate[backend_] := Which[
  backend === Automatic || backend === "Wolfram", None,
  StringQ[backend],
    multiquadraticStripFailure["PlanDiscoveryBackendUnavailable",
      <|"RequestedBackend" -> backend,
        "AvailableBackends" -> {Automatic, "Wolfram"}|>],
  True,
    multiquadraticStripFailure["InvalidPlanDiscoveryBackend",
      <|"RequestedBackend" -> ToString[backend]|>]
];

multiquadraticStripClearCaches[] := (
  $multiquadraticStripPrimeCache = <||>;
  $multiquadraticStripEpsilonCache = <||>;
  (* the compile pools of the 2026-08-25 core/ansatz split are caches
     too: a caller that clears state expects them gone *)
  multiquadraticStripCompileCacheClear[];
  <|"Status" -> "MultiquadraticStripCachesCleared"|>);

(* ------------------------------------------------------------------ *)
(* Top-level entry point                                                *)
(* ------------------------------------------------------------------ *)

(* DeleteDuplicatesBy on the option NAME: "Deadline" is now declared by
   multiquadraticStripPrepare as well (2026-08-25), with the identical
   default, and a duplicated option name in an Options list is a trap
   waiting for the next reader.  Prepare's declaration wins, which is
   also what makes FilterRules thread the caller's deadline into the
   preparation without a special case. *)
Options[solveEpsFormStripMultiquadratic] = DeleteDuplicatesBy[Join[
  Options[multiquadraticStripPrepare], {
  "SamplePrimes" -> Automatic,
  "RegulatorValues" -> Automatic,
  "HeldOutPrime" -> Automatic,
  "HeldOutRegulatorValue" -> Automatic,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "PlanDiscoveryBackend" -> Automatic,
  "DifferentialCheck" -> True,
  (* the residue-only integrability screen runs BEFORE prepare/compile;
     False skips it entirely *)
  "IntegrabilityScreen" -> True,
  "IntegrabilityScreenPointCount" -> 20,
  "IntegrabilityScreenPrime" -> Automatic,
  "IntegrabilityScreenRegulatorValue" -> Automatic,
  (* the full-gauge per-image screen runs AFTER prepare and BEFORE
     compile: it needs the prepared denominator and support, and it
     screens the compile, which is 99% of the remaining cost.  False
     skips it entirely. *)
  "GaugeScreen" -> True,
  "GaugeScreenPointCount" -> Automatic,
  "GaugeScreenImages" -> Automatic,
  (* the screen-validated escalation ladder, run ONLY when the screen at
     the configured "DegreeOffset" reports a CONFIRMED defect.  Automatic
     = FACET_MQ_DEGREE_LADDER or the built-in ladder; None = no
     escalation (the pre-2026-08-25 behaviour: return the typed
     obstruction at once). *)
  "DegreeOffsetLadder" -> Automatic,
  (* absolute AbsoluteTime[] value; Infinity = unbounded (the default,
     so every existing caller is unchanged) *)
  "Deadline" -> Infinity,
  (* The compile-architecture knobs, 2026-08-25 (Codex P2).  "CompileCore"
     is declared by multiquadraticStripPrepare and reaches THIS option
     set through the Join above; it is forwarded to the compiler below so
     that one public option governs both the early core in prepare and
     the compiler's own core, which is what its documentation claims.
     "LetterChannels" and "LegacyCompiler" are forwarded for the same
     reason.

     "CompileShards" is deliberately NOT a public option: it needs a live
     task broker and its strict result schema, helper-leak and fallback
     contract are not hardened (Codex 14:30, shard row).  It stays a
     PRIVATE test control of multiquadraticStripCompile with no
     production caller until that contract exists. *)
  "LetterChannels" -> Automatic,
  (* the compact route's grade gate and its dlog-admission policy
     (2026-08-25).  Automatic on both is the historical behaviour: every
     grade mask of the declared rank is admissible, and a letter proves
     its dlog relation by the package certificate if it carries one and
     by an exact recomputation otherwise. *)
  "LetterGradeSupport" -> Automatic,
  "CompactDLogAdmission" -> Automatic,
  "LegacyCompiler" -> False,
  (* ---- the screen / cache / broker ceilings (2026-08-25, Codex 14:30
     "top-level ceiling options").  Every one of these was a buried
     constant of this file; each is now a documented option whose
     Automatic is exactly the constant, so no existing caller changes
     and a campaign can bound a screen or a pool without editing the
     package. *)
  (* the admission ceilings BOTH screens are gated by, in unknowns and
     in estimated packed bytes; over either one the screen returns a
     typed <Screen>NotApplicable and the established route continues *)
  "ScreenMaximumUnknowns" -> Automatic,
  "ScreenMaximumBytes" -> Automatic,
  (* measured ByteCount ceilings of the persistent compile pools, as
     <|pool -> bytes|>; a value alone above a pool's ceiling bypasses
     that pool rather than evicting it *)
  "CompilePoolByteLimit" -> Automatic,
  "CompilePoolEntryLimit" -> Automatic,
  (* the byte ceiling of the screens' own compiled-scalar cache *)
  "ScreenCompileCacheBytes" -> Automatic,
  "Verbose" -> False
}], First];

(* The terminal success status is ModularConsistent.  It is NEVER
   "Solved": the package strip contract needs a certified dlog
   potential per letter, and this route returns closed one-forms
   (package bug handoff 2026-08-23, External gap 2).  The sector driver
   records the result; installation stays blocked until an OneForms
   contract exists. *)
solveEpsFormStripMultiquadratic[record_Association, frame_Association,
    opts : OptionsPattern[]] := Block[
  (* the stage lines follow this call's "Verbose" (Codex 14:30): they are
     diagnostics, not a second logging policy.  Block, so every exit path
     -- including a Return out of the Module below -- restores it, and so
     that prepare / compile / the screens, which have no Verbose option
     of their own, inherit the decision made here. *)
  (* the EXPLICIT three-argument OptionValue: the enclosing-function form
     relies on being rewritten inside the rule body, and this sits in a
     Block variable initializer, which is held *)
  {$multiquadraticStripStageLog = TrueQ[OptionValue[
    solveEpsFormStripMultiquadratic, {opts}, "Verbose"]]},
  Module[
  {startTime = AbsoluteTime[], gate, backendGate, verbose, log, preparation,
   assembly, primes, regulatorValues, heldOutPrime, heldOutRegulatorValue,
   allPrimes, samples = <||>, solutions = <||>, sample, solution, signature,
   signatures = {}, lifts = <||>, exactChecks = <||>, heldOutSample,
   heldOutSolution, heldOutResidual, branchCertificate, branchMask,
   transformedSample, differential, liftedVector, unpacked, prime,
   regulatorValue, samplerOptions, deadline, budgetProgress,
   budgetExhausted, enrich, variables, epsilon, strip, allRoots, classification,
   rootIndices, order, screenRoots, letterRecords, letterData, screen,
   screenRegulatorValue, prepareOptions, gaugeScreen, gaugeLadder,
   adoptedDegreeOffset, screenMaximumUnknowns, screenMaximumBytes,
   poolByteLimit, poolEntryLimit, screenCacheBytes, ceilingOptions,
   pathStatisticsBefore = multiquadraticFieldPathStatistics[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[solveEpsFormStripMultiquadratic]]]];
  If[AssociationQ[gate], Return[gate]];
  (* ---- the declared ceilings (2026-08-25).  Automatic is the module
     constant, so the resolved value is exactly the historical one; a
     declared value travels to the screens as their own options and to
     the compile pools through a Block around the compile, which is the
     scope a per-call ceiling must have. *)
  screenMaximumUnknowns = Replace[OptionValue["ScreenMaximumUnknowns"],
    Automatic :> $multiquadraticStripScreenMaximumUnknowns];
  screenMaximumBytes = Replace[OptionValue["ScreenMaximumBytes"],
    Automatic :> $multiquadraticStripScreenMaximumBytes];
  poolByteLimit = Replace[OptionValue["CompilePoolByteLimit"],
    Automatic :> $multiquadraticStripPoolByteLimit];
  poolEntryLimit = Replace[OptionValue["CompilePoolEntryLimit"],
    Automatic :> $multiquadraticStripPoolEntryLimit];
  screenCacheBytes = Replace[OptionValue["ScreenCompileCacheBytes"],
    Automatic :> $multiquadraticStripScreenCompileCacheLimit];
  If[! (IntegerQ[screenMaximumUnknowns] && screenMaximumUnknowns > 0) ||
      ! (NumericQ[screenMaximumBytes] && screenMaximumBytes > 0) ||
      ! (NumericQ[screenCacheBytes] && screenCacheBytes > 0) ||
      ! AssociationQ[poolByteLimit] || ! AssociationQ[poolEntryLimit] ||
      ! AllTrue[Values[poolByteLimit], NumericQ[#1] && #1 > 0 &] ||
      ! AllTrue[Values[poolEntryLimit],
        #1 === Infinity || (IntegerQ[#1] && #1 > 0) &],
    Return[multiquadraticStripFailure["InvalidCeilingOption",
      <|"ScreenMaximumUnknowns" -> screenMaximumUnknowns,
        "ScreenMaximumBytes" -> screenMaximumBytes,
        "ScreenCompileCacheBytes" -> screenCacheBytes,
        "CompilePoolByteLimit" -> poolByteLimit,
        "CompilePoolEntryLimit" -> poolEntryLimit|>]]];
  ceilingOptions = {"MaximumUnknowns" -> screenMaximumUnknowns,
    "MaximumBytes" -> screenMaximumBytes,
    "CompileCacheBytes" -> screenCacheBytes};
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  (* the partial progress this engine already tracks *)
  budgetProgress[] := <|
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Prime" -> If[IntegerQ[prime], prime, None],
    "RegulatorValue" -> If[NumericQ[regulatorValue], regulatorValue, None],
    "SamplesDone" -> Length[samples],
    "SampleKeys" -> Keys[samples],
    "PrimesDone" -> DeleteDuplicates[Cases[Keys[samples], {p_, _} :> p]],
    "SupportSize" -> If[AssociationQ[preparation],
      Length[Lookup[preparation, "GaugeSupport", {}]],
      Missing["NotPrepared"]],
    "UnknownCount" -> If[AssociationQ[preparation],
      Lookup[preparation, "UnknownCount", Missing["NotPrepared"]],
      Missing["NotPrepared"]],
    "RootCount" -> If[AssociationQ[preparation],
      Lookup[preparation, "RootCount", Missing["NotPrepared"]],
      Missing["NotPrepared"]]|>;
  budgetExhausted[stage_String] := multiquadraticStripBudgetExhausted[
    stage, AbsoluteTime[] - startTime, deadline, budgetProgress[]];
  (* the ansatz a failure happened in.  A typed failure from the sampler
     or the modular solve names the prime, the matrix and the
     inconsistent rows but not the ansatz that produced them, and the
     driver's failure summary then records a defect with no way to tell a
     missing letter from too small a support (2026-08-24). *)
  enrich[failure_] := If[! AssociationQ[failure], failure,
    Join[<|
      "Family" -> Lookup[record, "Family", None],
      "Sector" -> Lookup[record, "Sector", None],
      "LowerSector" -> Lookup[record, "LowerSector", None],
      "Method" -> "DirectRootChannel",
      "UnknownCount" -> If[AssociationQ[preparation],
        Lookup[preparation, "UnknownCount", Missing["NotPrepared"]],
        Missing["NotPrepared"]],
      "GaugeDenominator" -> If[AssociationQ[preparation],
        Lookup[preparation, "GaugeDenominator", Missing["NotPrepared"]],
        Missing["NotPrepared"]],
      "GaugeSupport" -> If[AssociationQ[preparation],
        Lookup[preparation, "GaugeSupport", Missing["NotPrepared"]],
        Missing["NotPrepared"]],
      "OneFormCount" -> If[AssociationQ[preparation],
        Length[Lookup[preparation, "OneForms", {}]], Missing["NotPrepared"]],
      "RootIndices" -> If[AssociationQ[preparation],
        Lookup[preparation, "RootIndices", Missing["NotPrepared"]],
        Missing["NotPrepared"]],
      "IntegrabilityScreen" -> KeyTake[screen,
        {"Status", "Reason", "Defect", "Rank", "AugmentedRank",
         "LetterCount", "FlatDiagonalConnections"}],
      "GaugeScreen" -> If[AssociationQ[gaugeScreen],
        KeyTake[gaugeScreen, {"Status", "ImageCount", "Defects"}],
        <|"Status" -> "GaugeScreenSkipped"|>],
      "GaugeScreenLadder" -> If[AssociationQ[gaugeLadder],
        KeyTake[gaugeLadder, {"Status", "AdoptedDegreeOffset",
          "LadderDefects"}],
        <|"Status" -> "GaugeScreenLadderNotRun"|>],
      "AdoptedDegreeOffset" -> adoptedDegreeOffset|>,
      failure]];
  backendGate = multiquadraticStripBackendGate[OptionValue["PlanDiscoveryBackend"]];
  If[AssociationQ[backendGate], Return[backendGate]];
  (* after the option gates (a malformed request is a caller error and
     outranks a budget stop) *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Entry"]]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["[multiquadratic] ", items]];
  (* ---------------------------------------------------------------- *)
  (* Alphabet construction and the residue-only integrability screen.   *)
  (* Both run BEFORE the forcing channel decomposition and the compile, *)
  (* which are 99.9% of this engine's cost: an alphabet that cannot     *)
  (* satisfy the integrability condition can never satisfy the gauge    *)
  (* system it is a projection of, and there is no reason to spend      *)
  (* hours discovering that.                                            *)
  (* ---------------------------------------------------------------- *)
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  screenRoots = Missing["RootsNotResolved"];
  letterRecords = Missing["NotBuilt"];
  screen = <|"Status" -> "IntegrabilityScreenSkipped"|>;
  If[MatchQ[variables, {_Symbol, _Symbol}] && MatchQ[epsilon, _Symbol] &&
      MatchQ[strip, {_List, _List, _List}],
    allRoots = transportChartCurrentRoots[frame, variables];
    If[ListQ[allRoots],
      classification = multiquadraticStripRootCensus[strip, allRoots];
      rootIndices = Replace[OptionValue["RootIndices"],
        Automatic :> classification["RootIndices"]];
      If[VectorQ[rootIndices, IntegerQ] &&
          Length[rootIndices] <= $multiquadraticStripMaximumRootCount,
        order = multiquadraticStripRootOrder[frame, variables, rootIndices,
          epsilon];
        If[Lookup[order, "Status", None] === "StableRootOrder",
          screenRoots = order["Roots"]]]]];
  If[ListQ[screenRoots] && OptionValue["OneForms"] === Automatic &&
      ! MatchQ[OptionValue["LetterRecords"], {___Association}],
    multiquadraticStripStageStart["alphabet",
      <|"family" -> Lookup[record, "Family", None],
        "sector" -> Lookup[record, "Sector", None],
        "lower" -> Lookup[record, "LowerSector", None],
        "rank" -> Length[screenRoots],
        "forcing" -> Quiet[Check[Dimensions[strip[[3, 1]]], None]]|>];
    letterData = multiquadraticStripCandidateLetters[strip, screenRoots,
      variables, epsilon, record,
      "RegulatorSampleCount" -> OptionValue["RegulatorSampleCount"],
      "RegulatorSamplePool" -> OptionValue["RegulatorSamplePool"],
      "RowAlphabet" -> OptionValue["RowAlphabet"],
      "AdditionalLetters" -> OptionValue["AdditionalLetters"],
      "AlgebraicLetters" -> OptionValue["AlgebraicLetters"],
      "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
      "MaximumNormExponent" -> OptionValue["MaximumNormExponent"]];
    If[Lookup[letterData, "Status", None] =!= "MultiquadraticCandidateLettersV1",
      Return[If[AssociationQ[letterData], letterData,
        multiquadraticStripFailure["OneFormBasisFailed"]]]];
    letterRecords = letterData["LetterRecords"];
    multiquadraticStripStageDone["alphabet",
      <|"letters" -> Length[letterRecords],
        "counts" -> Lookup[letterData, "Counts", <||>]|>];
    log["alphabet: ", Length[letterRecords], " letters ",
      letterData["Counts"], ", regulator samples ",
      letterData["RegulatorValues"], " (rejected ",
      letterData["RejectedRegulatorValues"], ")"]];
  If[! MatchQ[letterRecords, {___Association}],
    letterRecords = If[MatchQ[OptionValue["LetterRecords"], {___Association}],
      OptionValue["LetterRecords"],
      If[MatchQ[OptionValue["OneForms"], {{_, _} ..}],
        <|"Kind" -> "Supplied", "Letter" -> Missing["OneFormSuppliedDirectly"],
          "OneForm" -> #1|> & /@ OptionValue["OneForms"],
        Missing["NotBuilt"]]]];
  If[TrueQ[OptionValue["IntegrabilityScreen"]] && ListQ[screenRoots] &&
      MatchQ[letterRecords, {__Association}],
    screenRegulatorValue = Replace[
      OptionValue["IntegrabilityScreenRegulatorValue"],
      Automatic :> If[AssociationQ[letterData] &&
          MatchQ[Lookup[letterData, "RegulatorValues", {}], {__}],
        First[letterData["RegulatorValues"]], Automatic]];
    multiquadraticStripStageStart["integrability screen",
      <|"letters" -> Length[letterRecords],
        "points" -> OptionValue["IntegrabilityScreenPointCount"]|>];
    screen = multiquadraticStripIntegrabilityScreenImages[record, screenRoots,
      letterRecords, "Prime" -> OptionValue["IntegrabilityScreenPrime"],
      "RegulatorValue" -> screenRegulatorValue,
      "PointCount" -> OptionValue["IntegrabilityScreenPointCount"],
      "Deadline" -> deadline, Sequence @@ ceilingOptions];
    multiquadraticStripStageDone["integrability screen",
      <|"status" -> Lookup[screen, "Status", None],
        "defects" -> Lookup[screen, "Defects", None],
        "seconds" -> Lookup[screen, "Seconds", Missing["NotMeasured"]]|>];
    log["integrability screen: ", Lookup[screen, "Status", None],
      ", defects ", Lookup[screen, "Defects", None], " over ",
      Lookup[screen, "ImageCount", None], " image(s), rank ",
      Lookup[screen, "Rank", None], "/", Lookup[screen, "AugmentedRank", None],
      " of ", Lookup[screen, "MatrixDimensions", None]];
    (* Only a CONFIRMED obstruction -- a defect at two independent
       (prime, regulator) images -- ends the block.  One image cannot
       distinguish a generic obstruction from an exceptional regulator
       value at which a generically solvable system degenerates, so an
       unconfirmed defect is recorded and the established route runs. *)
    If[Lookup[screen, "Status", None] === "AlphabetIntegrabilityObstruction",
      Return[Join[screen, <|"SolutionContract" -> "NoGaugeExistsWithThisAlphabet",
        "ContractNote" -> "the residue-only integrability system carries a rank defect at TWO independent (prime, regulator) images: a high-confidence modular obstruction, i.e. no gauge of any shape, denominator or support repairs this alphabet at either image and the alphabet is missing letters. It is not an unconditional theorem over Q(eps): the statement is exact for each specialized finite-field system, and its generic validity rests on the two images being independent, not on a proved epsilon-degree bound.",
        "ContractStrength" -> "HighConfidenceModularObstruction",
        "Seconds" -> AbsoluteTime[] - startTime|>]]];
    If[Lookup[screen, "Status", None] ===
        "AlphabetIntegrabilityObstructionUnconfirmed",
      log["integrability screen: the defect did NOT reproduce at the ",
        "confirmation image; not treated as an obstruction"]];
    If[Lookup[screen, "Status", None] === "BudgetExhausted",
      Return[enrich[Join[budgetExhausted["IntegrabilityScreen"],
        <|"IntegrabilityScreen" -> KeyTake[screen,
          {"Stage", "SizeEstimate", "PhaseTimings",
           "MatrixDimensions"}]|>]]]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Preparation"]]];
  prepareOptions = Join[
    If[MatchQ[letterRecords, {___Association}] &&
        OptionValue["OneForms"] === Automatic,
      {"LetterRecords" -> letterRecords}, {}],
    (* the legacy compiler does not consume a compile core, so prepare
       must not build one for it: "LegacyCompiler" is not a prepare
       option and would otherwise leave prepare's own Automatic core on *)
    If[TrueQ[OptionValue["LegacyCompiler"]], {"CompileCore" -> False},
      {"CompileCore" -> OptionValue["CompileCore"]}],
    (* the caller's deadline now reaches prepare, which since 2026-08-25
       checks it at its own interior boundaries *)
    {"Deadline" -> deadline},
    FilterRules[DeleteCases[Flatten[{opts}],
      HoldPattern["LetterRecords" -> _] | HoldPattern["LetterRecords" :> _] |
      HoldPattern["CompileCore" -> _] | HoldPattern["CompileCore" :> _] |
      HoldPattern["Deadline" -> _] | HoldPattern["Deadline" :> _]],
      Options[multiquadraticStripPrepare]]];
  multiquadraticStripStageStart["prepare",
    <|"family" -> Lookup[record, "Family", None],
      "sector" -> Lookup[record, "Sector", None],
      "lower" -> Lookup[record, "LowerSector", None],
      "letters" -> If[MatchQ[letterRecords, {___Association}],
        Length[letterRecords], Missing["NotBuilt"]],
      "degreeOffset" -> OptionValue["DegreeOffset"],
      "forcing" -> Quiet[Check[Dimensions[strip[[3, 1]]], None]]|>];
  preparation = multiquadraticStripPrepare[record, frame,
    Sequence @@ prepareOptions];
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticStripV1",
    (* prepare's own typed stops -- including, since 2026-08-25, its
       interior BudgetExhausted -- travel out of this driver with the
       same ansatz context every other typed failure here carries *)
    Return[enrich[preparation]]];
  multiquadraticStripStageDone["prepare",
    <|"unknowns" -> preparation["UnknownCount"],
      "support" -> Length[preparation["GaugeSupport"]],
      "oneForms" -> Length[preparation["OneForms"]]|>];
  log["prepared: rank ", preparation["RootCount"], ", ",
    preparation["UnknownCount"], " unknowns, ",
    preparation["EquationsPerPoint"], " equations per point"];
  (* ---------------------------------------------------------------- *)
  (* The FULL-GAUGE per-image screen, in front of the compile.          *)
  (* The integrability screen above is necessary but not sufficient:    *)
  (* CF300 (12,9) passes it and the full system still carries a defect. *)
  (* This one assembles the complete affine system from point           *)
  (* evaluations of the PREPARED ansatz -- measured 43 s at 1816        *)
  (* unknowns and 98 s at 3128 -- against a compile measured at ~7900 s.*)
  (* ---------------------------------------------------------------- *)
  adoptedDegreeOffset = OptionValue["DegreeOffset"];
  gaugeLadder = <|"Status" -> "GaugeScreenLadderNotRun"|>;
  If[TrueQ[OptionValue["GaugeScreen"]],
    multiquadraticStripStageStart["gauge screen",
      <|"unknowns" -> preparation["UnknownCount"],
        "support" -> Length[preparation["GaugeSupport"]],
        "oneForms" -> Length[preparation["OneForms"]],
        "equationsPerPoint" -> preparation["EquationsPerPoint"],
        "degreeOffset" -> adoptedDegreeOffset|>];
    gaugeScreen = multiquadraticStripGaugeScreenImages[preparation,
      "Images" -> OptionValue["GaugeScreenImages"],
      "PointCount" -> OptionValue["GaugeScreenPointCount"],
      "Deadline" -> deadline, Sequence @@ ceilingOptions];
    multiquadraticStripStageDone["gauge screen",
      <|"status" -> Lookup[gaugeScreen, "Status", None],
        "defects" -> Lookup[gaugeScreen, "Defects", None],
        "images" -> Lookup[gaugeScreen, "ImageCount", None],
        "seconds" -> Lookup[gaugeScreen, "Seconds", Missing["NotMeasured"]]|>];
    log["gauge screen: ", Lookup[gaugeScreen, "Status", None], ", defects ",
      Lookup[gaugeScreen, "Defects", None], " over ",
      Lookup[gaugeScreen, "ImageCount", None], " image(s), ",
      Round[Lookup[gaugeScreen, "Seconds", 0], 0.1], " s, phases ",
      Round[#1, 0.1] & /@ Lookup[gaugeScreen, "PhaseTimings", <||>]];
    If[Lookup[gaugeScreen, "Status", None] === "BudgetExhausted",
      Return[enrich[Join[budgetExhausted["GaugeScreen"],
        <|"GaugeScreen" -> KeyTake[gaugeScreen,
          {"Stage", "SizeEstimate", "PhaseTimings", "MatrixDimensions"}]|>]]]];
    If[MemberQ[{"GaugeImageObstruction", "GaugeImageObstructionUnconfirmed"},
        Lookup[gaugeScreen, "Status", None]],
      (* THE ESCALATION LADDER, screens only.  A CONFIRMED defect at the
         configured offset is not yet a verdict on the block: the gauge
         may simply need a numerator degree above the denominator (a pole
         at infinity), which is a property of the ansatz and not of the
         alphabet.  An UNCONFIRMED obstruction is not escalated -- the
         two-image confirmation is what makes a defect a fact. *)
      If[OptionValue["Support"] =!= Automatic,
        (* an explicit support PINS the ansatz: a degree offset would not
           reach the compile (prepare's "Support" wins over its
           "DegreeOffset"), so escalating would screen an ansatz the
           solve never builds *)
        gaugeLadder = <|"Status" -> "GaugeScreenLadderNotApplicable",
          "Reason" -> "an explicit Support pins the ansatz; DegreeOffset has no effect on it"|>];
      If[OptionValue["DegreeOffsetLadder"] =!= None &&
          OptionValue["Support"] === Automatic &&
          Lookup[gaugeScreen, "Status", None] === "GaugeImageObstruction",
        gaugeLadder = multiquadraticStripGaugeScreenLadder[preparation,
          "DegreeOffsetLadder" -> OptionValue["DegreeOffsetLadder"],
          "BaseDegreeOffset" -> OptionValue["DegreeOffset"],
          "Deadline" -> deadline, "Verbose" -> verbose,
          "Images" -> OptionValue["GaugeScreenImages"],
          "PointCount" -> OptionValue["GaugeScreenPointCount"],
          Sequence @@ ceilingOptions,
          (* no witness is wanted on a ladder rung: the base screen above
             already produced one, and the left null space is the
             expensive half of a screen *)
          "LeftNullSpace" -> False]];
      (* the budget stop of the ladder is the driver's budget stop *)
      If[Lookup[gaugeLadder, "Status", None] === "BudgetExhausted",
        Return[enrich[Join[budgetExhausted["GaugeScreenLadder"],
          <|"GaugeScreenLadder" -> KeyTake[gaugeLadder,
            {"BaseDegreeOffset", "DegreeOffsetLadder", "NextDegreeOffset",
             "SkippedDegreeOffsets", "LadderDefects", "LadderRungs"}]|>]]]];
      If[Lookup[gaugeLadder, "Status", None] === "GaugeScreenLadderAdopted",
        adoptedDegreeOffset = gaugeLadder["AdoptedDegreeOffset"];
        log["gauge screen: defect 0 at DegreeOffset ", adoptedDegreeOffset,
          "; adopting"];
        (* the adopted offset enters the REAL ansatz exactly as a caller's
           would: the preparation is rebuilt through the same entry point
           with the same options, reusing only the forcing channels, which
           the offset cannot change *)
        preparation = multiquadraticStripPrepare[record, frame,
          "DegreeOffset" -> adoptedDegreeOffset,
          "ForcingChannels" -> Lookup[preparation, "ForcingChannels",
            Automatic],
          Sequence @@ DeleteCases[prepareOptions,
            HoldPattern["DegreeOffset" -> _] |
            HoldPattern["DegreeOffset" :> _]]];
        If[Lookup[preparation, "Status", None] =!=
            "PreparedMultiquadraticStripV1",
          Return[enrich[preparation]]];
        log["re-prepared at DegreeOffset ", adoptedDegreeOffset, ": ",
          preparation["UnknownCount"], " unknowns, support ",
          Length[preparation["GaugeSupport"]]],
        (* no rung reached defect 0 (or the ladder was disabled): the
           typed obstruction, now carrying the whole ladder *)
        Return[enrich[Join[
          KeyDrop[First[gaugeScreen["ImageResults"]], {"Module"}],
          <|"Status" -> "GaugeImageObstruction",
            "Module" -> "MultiquadraticStripSolve",
            "Confirmed" -> (Lookup[gaugeScreen, "Status", None] ===
              "GaugeImageObstruction"),
            "ImageCount" -> gaugeScreen["ImageCount"],
            "Defects" -> gaugeScreen["Defects"],
            "Images" -> gaugeScreen["Images"],
            "ImageResults" -> (KeyDrop[#1, {"Witness"}] & /@
              gaugeScreen["ImageResults"]),
            "DegreeOffset" -> OptionValue["DegreeOffset"],
            "GaugeScreenLadder" -> gaugeLadder,
            "LadderDefects" -> Lookup[gaugeLadder, "LadderDefects",
              Missing["GaugeScreenLadderNotRun"]],
            "SolutionContract" -> "NoGaugeExistsWithThisAnsatz",
            "ContractNote" -> If[Lookup[gaugeLadder, "Status", None] ===
                "GaugeScreenLadderExhausted",
              "the complete affine gauge system is inconsistent at these images AND at every escalated numerator degree of the ladder; the compile it screens would reproduce exactly this defect -- the ansatz is missing a letter or a support direction no degree offset supplies, and the witness names which residue demand is unmet",
              "the complete affine gauge system is inconsistent at these images; the compile it screens would reproduce exactly this defect -- the ansatz is missing a letter or a support direction, and the witness names which residue demand is unmet"],
            "GaugeScreenSeconds" -> gaugeScreen["Seconds"],
            "GaugeScreenLadderSeconds" -> Lookup[gaugeLadder, "Seconds",
              Missing["GaugeScreenLadderNotRun"]],
            "Seconds" -> AbsoluteTime[] - startTime|>]]]]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["GaugeScreen"]]];
  (* the preparation object was built in THIS call: its ABI payload is
     the one just computed and its forcing channels are exact, so the
     compiler neither re-derives the payload nor decomposes the forcing
     a second time (post-mortem item 5) *)
  multiquadraticStripStageStart["compile",
    <|"family" -> Lookup[record, "Family", None],
      "sector" -> Lookup[record, "Sector", None],
      "lower" -> Lookup[record, "LowerSector", None],
      "unknowns" -> preparation["UnknownCount"],
      "oneForms" -> Length[preparation["OneForms"]],
      "support" -> Length[preparation["GaugeSupport"]]|>];
  (* the public compile-architecture options reach the compiler, so that
     "CompileCore" -> False really does restore the pre-2026-08-25 path
     on the whole route and not merely in prepare (Codex P2) *)
  assembly = multiquadraticStripCompile[preparation,
    "PreparationValidated" -> True,
    "ForcingChannels" -> Lookup[preparation, "ForcingChannels", Automatic],
    "CompileCore" -> OptionValue["CompileCore"],
    "LetterChannels" -> OptionValue["LetterChannels"],
    "LetterGradeSupport" -> OptionValue["LetterGradeSupport"],
    "CompactDLogAdmission" -> OptionValue["CompactDLogAdmission"],
    "LegacyCompiler" -> OptionValue["LegacyCompiler"],
    (* the caller's deadline now reaches the compiler, which since
       2026-08-25 checks it at its own stage and per-letter boundaries;
       before this the driver could only check AFTER compile returned *)
    "Deadline" -> deadline,
    "PoolByteLimit" -> poolByteLimit,
    "PoolEntryLimit" -> poolEntryLimit];
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
    Return[enrich[assembly]]];
  multiquadraticStripStageDone["compile",
    KeyTake[Lookup[assembly, "CompileStatistics", <||>],
      {"Architecture", "Seconds", "CoreSeconds", "OneFormSeconds",
       "GaugeDenominatorSeconds"}]];
  (* between preparation and the modular schedule *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Preparation"]]];
  primes = Replace[OptionValue["SamplePrimes"],
    Automatic :> $multiquadraticStripDefaultPrimes];
  regulatorValues = Replace[OptionValue["RegulatorValues"],
    Automatic :> $multiquadraticStripDefaultRegulatorValues];
  heldOutPrime = Replace[OptionValue["HeldOutPrime"], Automatic :> 2147483323];
  heldOutRegulatorValue = Replace[OptionValue["HeldOutRegulatorValue"],
    Automatic :> 5/23];
  allPrimes = Append[primes, heldOutPrime];
  If[! VectorQ[primes, IntegerQ] || primes === {} ||
      ! AllTrue[allPrimes, PrimeQ[#1] && Mod[#1, 4] === 3 && 3 < #1 < 2^31 &] ||
      ! DuplicateFreeQ[allPrimes] || ! ListQ[regulatorValues] ||
      regulatorValues === {} ||
      ! AllTrue[Append[regulatorValues, heldOutRegulatorValue],
        MatchQ[#1, _Integer | _Rational] &] ||
      MemberQ[regulatorValues, heldOutRegulatorValue],
    Return[multiquadraticStripFailure["InvalidSamplingSchedule",
      <|"Primes" -> primes, "HeldOutPrime" -> heldOutPrime,
        "RegulatorValues" -> regulatorValues,
        "HeldOutRegulatorValue" -> heldOutRegulatorValue|>]]];
  samplerOptions = {"PointCount" -> OptionValue["PointCount"],
    "MaximumAttempts" -> OptionValue["MaximumAttempts"],
    "RandomSeed" -> OptionValue["RandomSeed"]};
  Do[
    (* between primes and between regulator values: one modular sample
       plus its affine solve is the unit of this loop *)
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[budgetExhausted["ModularSampling"], Module]];
    sample = multiquadraticStripAssembleSample[assembly, regulatorValue, prime,
      Sequence @@ samplerOptions];
    If[Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1",
      Return[enrich[sample], Module]];
    solution = multiquadraticStripAffineSolve[sample["Matrix"],
      sample["RightHandSide"], prime];
    If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution",
      Return[enrich[solution], Module]];
    samples[{prime, regulatorValue}] = sample;
    solutions[{prime, regulatorValue}] = solution;
    AppendTo[signatures, {solution["Rank"], solution["Nullity"],
      solution["PivotSignature"]}];
    log["prime ", prime, ", eps ", regulatorValue, ": rank ",
      solution["Rank"], ", nullity ", solution["Nullity"]],
    {regulatorValue, regulatorValues}, {prime, primes}];
  If[Length[DeleteDuplicates[signatures]] =!= 1,
    Return[enrich[multiquadraticStripFailure["ModularStructureUnstable",
      <|"Signatures" -> DeleteDuplicates[signatures]|>]]]];
  signature = First[signatures];
  (* held-out prime AND held-out regulator value: the guard against a
     structure that only exists at the sampled images.  Split points
     are required here and only here, so that the same held-out
     solution also carries the sign-branch certificate. *)
  (* between the sampled schedule and the held-out guard *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["HeldOutGuard"]]];
  heldOutSample = multiquadraticStripAssembleSample[assembly,
    heldOutRegulatorValue, heldOutPrime, Sequence @@ samplerOptions,
    "SplitPointsOnly" -> True];
  If[Lookup[heldOutSample, "Status", None] =!= "AssembledMultiquadraticSampleV1",
    Return[enrich[heldOutSample]]];
  heldOutSolution = multiquadraticStripAffineSolve[heldOutSample["Matrix"],
    heldOutSample["RightHandSide"], heldOutPrime];
  If[Lookup[heldOutSolution, "Status", None] =!= "MultiquadraticAffineSolution",
    Return[enrich[heldOutSolution]]];
  If[{heldOutSolution["Rank"], heldOutSolution["Nullity"],
      heldOutSolution["PivotSignature"]} =!= signature,
    Return[multiquadraticStripFailure["HeldOutStructureMismatch",
      <|"Signature" -> signature,
        "HeldOutSignature" -> {heldOutSolution["Rank"],
          heldOutSolution["Nullity"], heldOutSolution["PivotSignature"]}|>]]];
  (* every sign branch: the transformed system is the same statement,
     so the grade solution must satisfy all 2^r of them *)
  branchCertificate = Table[
    (* between sign branches *)
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[budgetExhausted["BranchCertificate"], Module]];
    transformedSample = multiquadraticStripTransformSampleToSigns[assembly,
      heldOutSample, heldOutPrime, branchMask];
    If[Lookup[transformedSample, "Status", None] =!=
        "TransformedMultiquadraticSampleToSignsV1",
      Return[transformedSample, Module]];
    <|"BranchFlipMask" -> branchMask,
      "ResidualZero" -> AllTrue[Mod[transformedSample["Rows"] .
          heldOutSolution["ParticularSolution"] -
          transformedSample["RightHandSide"], heldOutPrime], #1 === 0 &]|>,
    {branchMask, 0, assembly["GradeCount"] - 1}];
  If[! AllTrue[branchCertificate, TrueQ[#1["ResidualZero"]] &],
    Return[multiquadraticStripFailure["BranchCertificateFailed",
      <|"BranchCertificate" -> branchCertificate|>]]];
  differential = If[TrueQ[OptionValue["DifferentialCheck"]],
    multiquadraticStripDifferentialCheckPoint[assembly, heldOutRegulatorValue,
      heldOutPrime, First[heldOutSample["AcceptedPoints"]], 0],
    <|"Status" -> "DifferentialCheckSkipped"|>];
  If[TrueQ[OptionValue["DifferentialCheck"]] &&
      Lookup[differential, "Status", None] =!=
        "MultiquadraticPointDifferentialPassed",
    Return[multiquadraticStripFailure["DifferentialCheckFailed",
      <|"Differential" -> differential|>]]];
  (* best-effort exact lift, one regulator value at a time: CRT over the
     sampled primes and rational reconstruction of the canonical
     particular solution, then the exact channel identity at that value *)
  Do[
    (* between exact lifts, one regulator value each *)
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[budgetExhausted["ExactLift"], Module]];
    liftedVector = multiquadraticStripLiftVector[
      Table[solutions[{prime, regulatorValue}]["ParticularSolution"],
        {prime, primes}], primes];
    lifts[regulatorValue] = liftedVector;
    If[Lookup[liftedVector, "Status", None] === "LiftedMultiquadraticVector",
      exactChecks[regulatorValue] = multiquadraticStripExactChannelResidual[
        preparation, liftedVector["Vector"], regulatorValue];
      If[Lookup[exactChecks[regulatorValue], "Status", None] ===
          "ExactChannelResidualNonzero",
        Return[multiquadraticStripFailure["ExactChannelResidualNonzero",
          <|"RegulatorValue" -> regulatorValue|>], Module]]],
    {regulatorValue, regulatorValues}];
  unpacked = If[Lookup[lifts[First[regulatorValues]], "Status", None] ===
      "LiftedMultiquadraticVector",
    multiquadraticStripUnpackVector[preparation,
      lifts[First[regulatorValues]]["Vector"]],
    <|"Status" -> "NotLifted"|>];
  <|"Status" -> "ModularConsistent",
    "Method" -> "DirectRootChannel",
    "SolutionContract" -> "OneFormsNotCertified",
    "ContractNote" -> "closed one-forms, no certified dlog potential: this result is recorded, never installed as a solved epsilon form",
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "RootIndices" -> preparation["RootIndices"],
    "RootSquares" -> preparation["RootSquares"],
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Dimensions" -> preparation["Dimensions"],
    "GaugeSupport" -> preparation["GaugeSupport"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "GaugeDenominatorFactor" -> Lookup[preparation, "GaugeDenominatorFactor",
      Missing["NotRecorded"]],
    "OneForms" -> preparation["OneForms"],
    "OneFormCount" -> Length[preparation["OneForms"]],
    "CandidateAlphabet" -> If[MatchQ[letterRecords, {___Association}],
      Lookup[letterRecords, "Letter", {}], Missing["LettersSuppliedAsOneForms"]],
    "LetterKinds" -> If[MatchQ[letterRecords, {___Association}],
      Lookup[letterRecords, "Kind", {}], Missing["LettersSuppliedAsOneForms"]],
    "AlgebraicLetterCount" -> Lookup[preparation, "AlgebraicLetterCount",
      Missing["NotRecorded"]],
    "RegulatorSampleValues" -> If[AssociationQ[letterData],
      Lookup[letterData, "RegulatorValues", {}], Missing["NotBuilt"]],
    "IntegrabilityScreen" -> KeyTake[screen,
      {"Status", "Reason", "Defect", "Rank", "AugmentedRank",
       "MatrixDimensions", "UnknownCount", "LetterCount", "Prime",
       "RegulatorValue", "PointCount", "FlatDiagonalConnections"}],
    (* the mathematical payload only: a timing field here would make two
       otherwise identical solve records differ (t_solver_budget compares
       them key by key), and the screen's cost is already logged *)
    "GaugeScreen" -> If[AssociationQ[gaugeScreen],
      KeyTake[gaugeScreen, {"Status", "ImageCount", "Defects", "Images"}],
      <|"Status" -> "GaugeScreenSkipped"|>],
    (* the offset the REAL ansatz was built at: the caller's, unless the
       ladder measured a larger one and adopted it.  Timing-free, like
       every other field of this record. *)
    "AdoptedDegreeOffset" -> adoptedDegreeOffset,
    "GaugeScreenLadder" -> If[AssociationQ[gaugeLadder],
      KeyTake[gaugeLadder, {"Status", "AdoptedDegreeOffset",
        "BaseDegreeOffset", "DegreeOffsetLadder", "SkippedDegreeOffsets",
        "RungCount", "LadderDefects"}],
      <|"Status" -> "GaugeScreenLadderNotRun"|>],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "PreparationSchema" -> Lookup[preparation, "PreparationSchema",
      Missing["PreparationSchema"]],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Rank" -> signature[[1]], "Nullity" -> signature[[2]],
    "PivotSignature" -> signature[[3]],
    "PivotColumns" -> heldOutSolution["PivotColumns"],
    "SamplePrimes" -> primes, "RegulatorValues" -> regulatorValues,
    "HeldOutPrime" -> heldOutPrime,
    "HeldOutRegulatorValue" -> heldOutRegulatorValue,
    "HeldOutSolution" -> KeyTake[heldOutSolution, {"Rank", "Nullity",
      "PivotColumns", "FreeColumns", "PivotSignature", "ParticularSolution",
      "NullspaceBasis"}],
    "ModularSolutions" -> Association[KeyValueMap[
      #1 -> KeyTake[#2, {"Rank", "Nullity", "PivotSignature",
        "ParticularSolution"}] &, solutions]],
    "ExactLift" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Status", None] &, lifts]],
    "ExactLiftVectors" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Vector", Missing["NotLifted"]] &, lifts]],
    "ExactChannelResidual" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Status", None] &, exactChecks]],
    "GaugeChannels" -> Lookup[unpacked, "GaugeChannels",
      Missing["NotLifted"]],
    "Gauge" -> Lookup[unpacked, "Gauge", Missing["NotLifted"]],
    "Residues" -> Lookup[unpacked, "Residues", Missing["NotLifted"]],
    "BranchCertificate" -> branchCertificate,
    "DifferentialCheck" -> KeyTake[differential,
      {"Status", "Passed", "Point", "BranchFlipMask"}],
    "RootFreeFastPathCount" -> multiquadraticFieldPathStatisticsDelta[
      pathStatisticsBefore,
      multiquadraticFieldPathStatistics[]]["RootFreeFastPathCount"],
    "ChannelPathStatistics" -> multiquadraticFieldPathStatisticsDelta[
      pathStatisticsBefore, multiquadraticFieldPathStatistics[]],
    "Seconds" -> AbsoluteTime[] - startTime|>
]
];
solveEpsFormStripMultiquadratic[___] :=
  multiquadraticStripFailure["InvalidSolveArguments"];

End[];
