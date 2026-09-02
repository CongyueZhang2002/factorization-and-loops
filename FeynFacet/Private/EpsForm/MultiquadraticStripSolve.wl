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

   Sources: Exchange/Codex/2026-08-22/04_triple_root_campaign/
   direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl
   (compile / prime forms / epsilon collapse / point and sample
   assembly / sign transforms / differential check),
   TripleRootStripAdapter.wl (channel decomposition, one-form basis,
   gauge denominator), TripleRootReconstructionPrototype.wl
   (preparation ABI, canonical affine solve, unpacking, exact channel
   residual), TripleRootAffinePilot.wl (the independent split-sign row
   assembly used as the differential reference).

   Installation requires Alphabet plus residue matrices, authenticated
   dlog potentials on the ACTIVE reconstructed support, and independent
   residual evidence.  The direct solver now promotes to "Solved" only
   when MultiquadraticInstallation.wl verifies that complete payload;
   bare or uncertified one-forms remain "ModularConsistent" and are not
   installed (Design/MultiquadraticPromotion.md section 3).

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
  multiquadraticStripStageMark,
  $multiquadraticStripProgressLastTime, $multiquadraticStripStageStartTime,
  $multiquadraticStripStageLog,
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
  multiquadraticStripChannelTextKey,
  multiquadraticStripExpressionTextKey,
  $multiquadraticStripLetterDLogSchema,
  $multiquadraticStripLetterDLogChannelSchema,
  $multiquadraticStripPotentialSchema,
  $multiquadraticStripPotentialCache,
  $multiquadraticStripPotentialCounters,
  $multiquadraticStripPotentialCacheEntryLimit,
  multiquadraticStripPotentialCacheReset,
  multiquadraticStripPotentialStatistics,
  multiquadraticStripPotentialPairKey,
  multiquadraticStripConstructedDLogEvidence,
  multiquadraticStripPotentialRelationZeroQ,
  multiquadraticStripVerifyPotential,
  multiquadraticStripPotentialsCertifiedQ,
  multiquadraticStripLetterKinematicPart,
  multiquadraticStripDiagonalSpan,
  multiquadraticStripDiagonalSpanBoundedExact,
  multiquadraticStripDiagonalSpanSampled,
  multiquadraticStripDiagonalSpansSampled,
  multiquadraticStripDiagonalSpanBasisImages,
  multiquadraticStripRationalAffineParticular,
  multiquadraticStripRationalAffineParticularBatch,
  $multiquadraticStripDiagonalSpanSamplePoints,
  $multiquadraticStripDiagonalSpanExactBasisLimit,
  multiquadraticStripActivePotentialCertification,
  multiquadraticStripTransferDiagnosticResidues,
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
  multiquadraticStripActiveGradeNorm,
  multiquadraticFieldDecompose,
  multiquadraticFieldCompose, multiquadraticLiftLocalChannels,
  multiquadraticFieldPathStatistics,
  multiquadraticFieldPathStatisticsDelta,
  multiquadraticClosedOneFormQ, multiquadraticScalarOneForms,
  multiquadraticRationalGaugeDenominator,
  multiquadraticStripCanonicalFactor, multiquadraticStripRationalPolarCurves,
  multiquadraticStripNormInAlphabetQ, multiquadraticStripPolynomialSquareRoot,
  multiquadraticStripSquareCompletionConstants, multiquadraticStripNormMonomials,
  multiquadraticStripAlgebraicLetters, multiquadraticStripRegulatorSampleValues,
  multiquadraticStripFieldMemberQ, multiquadraticStripFormTextKey,
  multiquadraticStripLetterOneForm,
  multiquadraticStripLetterChannelData,
  multiquadraticStripLetterDLogDataInField,
  multiquadraticStripDLogShardTask,
  multiquadraticStripConstructDLogBatch,
  multiquadraticStripRowAlphabetLetters,
  multiquadraticStripCandidateLetters, multiquadraticStripNormDenominatorFactor,
  multiquadraticStripMergeGaugeDenominator,
  multiquadraticStripMergeGaugeDenominatorSourceData,
  multiquadraticStripMergeGaugeDenominatorSources,
  multiquadraticStripScreenCompilePolynomialExact,
  multiquadraticStripScreenCompileExpandedPolynomialExact,
  multiquadraticStripScreenReducePolynomial,
  multiquadraticStripScreenCompilePolynomial,
  multiquadraticStripScreenCompileScalarExact,
  multiquadraticStripScreenCompileFactoredScalarExact,
  multiquadraticStripScreenReduceScalar,
  multiquadraticStripScreenCompileScalar,
  multiquadraticStripScreenEvaluatePolynomial,
  multiquadraticStripScreenEvaluateRational,
  multiquadraticStripScreenEvaluatePolynomialValue,
  multiquadraticStripScreenEvaluateRationalValue,
  multiquadraticStripScreenPowerTables,
  multiquadraticStripScreenSizeEstimate,
  multiquadraticStripScreenAdmissionRefusal,
  multiquadraticStripSampleSizeEstimate,
  multiquadraticStripSampleAdmissionRefusal,
  multiquadraticStripScreenCompileCached,
  multiquadraticStripScreenCompileCacheClear,
  $multiquadraticStripScreenCompileCache,
  $multiquadraticStripScreenCompileCacheBytes,
  $multiquadraticStripScreenCompileCacheLimit,
  $multiquadraticStripScreenCompileStatistics,
  $multiquadraticStripScreenMaximumUnknowns,
  $multiquadraticStripScreenMaximumBytes,
  $multiquadraticStripSampleMaximumBytes,
  multiquadraticStripIntegrabilityScreen,
  multiquadraticStripIntegrabilityScreenImages,
  multiquadraticStripScreenEvidenceClassify,
  multiquadraticStripConfirmedObstructionEvidenceQ,
  multiquadraticStripFreshResidueScreenImages,
  multiquadraticStripGaugeAnsatz, multiquadraticStripGaugeScreen,
  multiquadraticStripGaugeScreenImages,
  multiquadraticStripFreshScreenImages,
  $multiquadraticStripDefaultFreshImageCount,
  multiquadraticStripGaugeScreenLadder,
  multiquadraticStripDegreeOffsetLadder,
  multiquadraticStripDegreeOffsetLadderParse,
  $multiquadraticStripDefaultDegreeOffsetLadder,
  (* the witness-guided mixed-grade letter cluster
     (multiquadraticStripCurveParameterization / ...GradeNorm /
     ...MixedGradeLetters) moved to Prototypes/ on 2026-08-26; it has no
     production caller and must not be ClearAll-ed from here, or a
     session that loaded the prototype first would lose it *)
  $multiquadraticStripRegulatorSamplePool,
  multiquadraticStripRootOrder,
  multiquadraticStripRootCensusFromFrameCensus,
  multiquadraticStripRootCensus,
  multiquadraticStripRootCensusWithBundle,
  multiquadraticStripCanonicalizeRadicals,
  multiquadraticStripReconstructRegulator,
  multiquadraticStripProviderResidualImage,
  $multiquadraticStripRegulatorScheduleDefault,
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
  multiquadraticStripCoefficientABIPayload,
  multiquadraticStripAssemblyLayout,
  multiquadraticStripAssemblyLayoutValidQ,
  multiquadraticStripAssemblyLayoutHotValidQ,
  multiquadraticStripAssemblyLayoutEvaluationValidQ,
  $multiquadraticStripTrustedLayoutEvaluation,
  multiquadraticStripProviderValidQ,
  multiquadraticStripProviderHotValidQ,
  multiquadraticStripProviderEvaluationValidQ,
  $multiquadraticStripTrustedProviderEvaluation,
  multiquadraticStripCompiledProvider,
  multiquadraticStripProviderPreflight,
  multiquadraticStripCompiledProviderChannels,
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
  multiquadraticStripAssemblePointRows,
  multiquadraticStripPointCoefficientsValidQ,
  multiquadraticStripModularInverse, multiquadraticStripModularGradePower,
  multiquadraticStripModularGradeEvaluate,
  $multiquadraticStripGradeEvaluateTag,
  multiquadraticStripEntryActiveRoots,
  multiquadraticStripRootMaskActiveRoots,
  multiquadraticStripBundleRootEmbedding,
  multiquadraticStripBundleLocalData,
  multiquadraticStripQuotientGradeEntry,
  multiquadraticStripSplitBranchEntry,
  $multiquadraticStripSplitRootSymbols,
  $multiquadraticStripSplitSparseCompilation,
  $multiquadraticStripSplitSparsePlanCache,
  $multiquadraticStripSplitSparseExactPlanCache,
  $multiquadraticStripTrustedSplitSparsePlanEvaluation,
  multiquadraticStripSplitSparseEvaluationPlan,
  multiquadraticStripSplitSparseEvaluationPlanValidQ,
  multiquadraticStripSplitSparseEvaluationPlanHotValidQ,
  multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ,
  multiquadraticStripSplitSparsePlannedEntry,
  multiquadraticStripNativeSparseBinary,
  multiquadraticStripNativeSparseWritePlan,
  multiquadraticStripNativeSparseEvaluateBatch,
  multiquadraticStripNativeDeferredBinary,
  multiquadraticStripNativeDeferredWriteRequest,
  multiquadraticStripNativeDeferredReadOutput,
  multiquadraticStripNativeDeferredEvaluateBatch,
  multiquadraticStripAttachDeferredPreparation,
  multiquadraticStripChartForcingProvider,
  multiquadraticStripChartForcingProviderValidQ,
  multiquadraticStripChartForcingProviderHotValidQ,
  multiquadraticStripChartForcingPreflight,
  multiquadraticStripChartForcingFoldTensor,
  multiquadraticStripNativeDeferredChartEvaluateBatch,
  multiquadraticStripNativePreflightBatch,
  multiquadraticStripNativeRowBinary,
  multiquadraticStripNativeRowAssembleBatch,
  multiquadraticStripPointResult,
  multiquadraticStripPlannedProviderChannels,
  multiquadraticStripDirectProvider, multiquadraticStripProviderChannels,
  multiquadraticStripBundleGaugeDenominator,
  multiquadraticStripBundleExactChannelTask,
  multiquadraticStripBundleExactChannels,
  multiquadraticStripBundleRefinedGaugeDenominator,
  multiquadraticStripBundleProviderChannels,
  multiquadraticStripConservativeGaugeDenominator, multiquadraticStripNormalizationRows,
  multiquadraticStripAssembleSample, multiquadraticStripSignTransform,
  multiquadraticStripTransformPointToSigns,
  multiquadraticStripTransformSampleToSigns,
  multiquadraticStripSplitPointRows,
  multiquadraticStripDifferentialCheckPoint,
  multiquadraticStripAffineSolve,
  multiquadraticStripPlanDiscoveryBackendDecision,
  multiquadraticStripNativeAffineSolve,
  multiquadraticStripPlanDiscoverySolve,
  multiquadraticStripAffineConsistencyEvidence,
  $multiquadraticStripPlanDiscoveryNativeMinimumEntries,
  multiquadraticStripConstrainedPlanValidQ,
  multiquadraticStripConstrainedPlanDiscover,
  multiquadraticStripFullResidualEvidenceValidQ,
  multiquadraticStripConstrainedAffineSolve,
  multiquadraticStripConstrainedAffineFallback,
  multiquadraticStripFollowerImagePayload,
  multiquadraticStripFollowerImagePayloadValidQ,
  multiquadraticStripFollowerImageSolve,
  multiquadraticStripFollowerImageAuthenticate,
  multiquadraticStripFollowerImageTask,
  multiquadraticStripFollowerImageKernelCount,
  multiquadraticStripFollowerImageWave,
  multiquadraticStripPilotImageRecord,
  multiquadraticStripPilotImageAuthenticate,
  multiquadraticStripProviderSupportLadder,
  multiquadraticStripUnpackVector,
  multiquadraticStripChannelMatrixProduct,
  multiquadraticStripExactChannelResidual,
  multiquadraticStripArtifactWrite, multiquadraticStripArtifactLoadRaw,
  multiquadraticStripReadPreparedArtifact, multiquadraticStripOptionNames,
  multiquadraticStripProductionOptionGate, multiquadraticStripBackendGate,
  multiquadraticStripClearCaches, solveEpsFormStripMultiquadratic,
  multiquadraticStripDeadlineQ, multiquadraticStripDeadlineExpiredQ,
  multiquadraticStripBudgetExhausted, multiquadraticStripDeadlineCheckpoint,
  $multiquadraticStripActiveDeadline, $multiquadraticStripDeadlineTag,
  $multiquadraticStripMaximumRootCount, $multiquadraticStripMaximumEpsilonDegree,
  $multiquadraticStripWordPrimeLimit,
  $multiquadraticStripSourceFile, $multiquadraticStripSourceSHA256,
  $multiquadraticStripABIVersion,
  $multiquadraticStripFreivaldsProjections,
  $multiquadraticStripPrimeCache, $multiquadraticStripEpsilonCache,
  $multiquadraticStripDefaultPrimes, $multiquadraticStripPrimePool,
  $multiquadraticStripWideDefaultPrimes,
  $multiquadraticStripWidePrimePool,
  multiquadraticStripWidePrimeScheduleQ,
  $multiquadraticStripValidationPrimePool,
  $multiquadraticStripDefaultRegulatorValues,
  $multiquadraticFieldRootFreeFastPathCount, $multiquadraticFieldAlgebraicPathCount,
  $multiquadraticFieldComposeCheckCount
];

$multiquadraticStripMaximumRootCount = 3;
$multiquadraticStripMaximumEpsilonDegree = 256;
$multiquadraticStripWordPrimeLimit = 2^63;
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
$multiquadraticStripStageStartTime = <||>;
$multiquadraticStripStageLog = False;

multiquadraticStripStageLogQ[] := Module[
  {value = Environment["FACET_MQ_STAGE_LOG"]},
  Which[value === "On", True, value === "Off", False,
    True, TrueQ[$multiquadraticStripStageLog]]];

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
    $multiquadraticStripStageStartTime[stage] = AbsoluteTime[];
    Print[multiquadraticStripStageText[stage <> " start", data]]];
  True);

multiquadraticStripStageDone[stage_String, data_Association : <||>] := Module[
  {start, completed = data},
  If[multiquadraticStripStageLogQ[],
    start = Lookup[$multiquadraticStripStageStartTime, stage, Missing["NoStart"]];
    If[NumberQ[start], completed = Join[completed,
      <|"elapsedSeconds" -> N[AbsoluteTime[] - start]|>]];
    Print[multiquadraticStripStageText[stage <> " done", completed]];
    KeyDropFrom[$multiquadraticStripStageStartTime, stage]];
  True
];

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
(* U3 (user decision 2026-09-02): the implementation identity carried by
   every stored assembly, letter and potential certificate is a
   HAND-MAINTAINED ABI version, not a hash of this file -- a comment edit
   no longer invalidates every artifact.  Bump the string when the
   certificate or cache-key semantics change.  Records written before this
   date carry "SourceSHA256" instead and are accepted as the legacy
   lineage. *)
$multiquadraticStripABIVersion = "MultiquadraticStripSolve-ABI-1";
$multiquadraticStripSourceSHA256 = $multiquadraticStripABIVersion;

(* U2 (2026-09-02): number of random row projections replayed over ALL
   original rows after a native (FLINT) constrained-core solve *)
$multiquadraticStripFreivaldsProjections = 2;

(* Sampling defaults: primes are 3 mod 4 so that every split point has
   an explicit square root (the sign-branch certificate needs one).

   CompiledChannel retains the historical 31-bit pool because its packed
   Wolfram compatibility sampler multiplies machine integers.  SplitBranch
   evaluates sparse leaves and assembles rows in FLINT nmod arithmetic, whose
   binary protocols use unsigned 64-bit words; it therefore uses the 61-bit
   pool below.  The independent validation pool deliberately remains 31-bit
   and disjoint from both reconstruction schedules. *)
$multiquadraticStripDefaultPrimes = {2147483423, 2147483399};
$multiquadraticStripPrimePool = {
  2147483423, 2147483399, 2147483587, 2147483579, 2147483563,
  2147483543, 2147483179, 2147483171, 2147483123, 2147483059,
  2147482951, 2147482943, 2147482867, 2147482859, 2147482819,
  2147482811, 2147482763, 2147482739, 2147482663, 2147482591,
  2147482583, 2147482507, 2147482367, 2147482343, 2147482327,
  2147482291, 2147482231, 2147482223, 2147482091, 2147482063,
  2147481967, 2147481907};
$multiquadraticStripWidePrimePool = {
  2305843009213693951, 2305843009213693907, 2305843009213693723,
  2305843009213693487, 2305843009213693123, 2305843009213692967,
  2305843009213692799, 2305843009213692671, 2305843009213692527,
  2305843009213692463, 2305843009213692427, 2305843009213692419,
  2305843009213692343, 2305843009213692331, 2305843009213692283,
  2305843009213692211, 2305843009213692199, 2305843009213692139,
  2305843009213692107, 2305843009213692103, 2305843009213692083,
  2305843009213692043, 2305843009213692031, 2305843009213692007,
  2305843009213691819, 2305843009213691767, 2305843009213691579,
  2305843009213691567, 2305843009213691551, 2305843009213691347,
  2305843009213691287, 2305843009213690907};
$multiquadraticStripWideDefaultPrimes =
  Take[$multiquadraticStripWidePrimePool, 2];
multiquadraticStripWidePrimeScheduleQ[provider_Association] := Module[{plan},
  If[Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! StringQ[multiquadraticStripNativeRowBinary[]], Return[False]];
  (* Native deferred BBar never consumes the bundle's split plan.  Building
     that plan here merely to choose the prime width would compile precisely
     the forcing leaves the native DAG path bypasses.  Its evaluator and the
     shared native row assembler are both 64-bit modular backends, so they
     directly admit the wide schedule. *)
  If[AssociationQ[Lookup[provider, "DeferredPreparation", None]],
    Return[StringQ[multiquadraticStripNativeDeferredBinary[]]]];
  If[! StringQ[multiquadraticStripNativeSparseBinary[]], Return[False]];
  (* Building this plan is not an extra production pass: the sampler needs
     the same provider/prime plan, and the established plan cache makes that
     later lookup free.  Wide Automatic is admitted only when every leaf can
     remain in native modular arithmetic. *)
  plan = Quiet[Check[multiquadraticStripSplitSparseEvaluationPlan[
      provider, First[$multiquadraticStripWidePrimePool]], $Failed]];
  AssociationQ[plan] &&
    Lookup[plan, "Status", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[plan, "FallbackLeafCount", -1] === 0
];
multiquadraticStripWidePrimeScheduleQ[_] := False;
$multiquadraticStripValidationPrimePool = {
  2147483323, 2147481899, 2147481883, 2147481863, 2147481827,
  2147481811, 2147481571, 2147481563};
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

   Preparation is the engine's long stage and it checkpointed NOTHING: a
   cancelled or budget-stopped run threw away every completed substage
   and the next attempt started from zero.  What that cost on a real
   block is measured in Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   MultiquadraticMeasurementNarratives_2026-08-26.md, section 2.

   Each expensive substage boundary now writes ONE self-describing
   record, and a resumed preparation may read it back instead of
   recomputing.  The three boundaries are exactly the three the
   cooperative deadline already names -- "ForcingChannels",
   "CandidateLetters", "GaugeDenominator" -- so a stop and a checkpoint
   speak the same vocabulary.

   PROVENANCE.  A checkpoint is NOT a cache keyed by a file name.  Every
   record carries implementation provenance for diagnostics, an INPUT
   fingerprint over exactly the mathematical inputs its substage consumed,
   a PAYLOAD content hash, and a seal fingerprint over the stored header.
   Resume admission is deliberately blind to implementation provenance:
   changing a backend or the source file cannot change a mathematical
   intermediate.  A reader therefore requires the same substage and input,
   and verifies that the stored payload still matches its stored seal.
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
      "ABIVersion" -> $multiquadraticStripABIVersion,
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
    "ABIVersion", "AlgebraABIFingerprint", "InputFingerprint",
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

(* The minimal Galois-orbit norm of an already decomposed field element.
   Inactive generators are projected out first, so a one-root letter in a
   rank-three family receives its quadratic norm rather than that norm raised
   to the fourth power.  The recursion is the norm half of the established
   inverse tower: u + v r -> u^2 - delta v^2, one generator at a time. *)
multiquadraticStripActiveGradeNorm[channels_List, deltas_List] := Module[
  {rank = Length[deltas], activeIndices, localChannels, normTower, result},
  If[Length[channels] =!= 2^rank, Return[$Failed]];
  (* Field decomposition canonicalizes every zero channel to literal 0. *)
  activeIndices = Select[Range[rank], Function[index,
    AnyTrue[Range[0, Length[channels] - 1], Function[mask,
      BitGet[mask, index - 1] === 1 &&
        ! SameQ[channels[[mask + 1]], 0]]]]];
  localChannels = Table[Module[{globalMask = Sum[
        BitGet[localMask, bit - 1] 2^(activeIndices[[bit]] - 1),
        {bit, Length[activeIndices]}]}, channels[[globalMask + 1]]],
    {localMask, 0, 2^Length[activeIndices] - 1}];
  normTower[values_List, squares_List] := Module[
    {localRank = Length[squares], half, low, high, reduced},
    If[Length[values] =!= 2^localRank, Return[$Failed]];
    If[localRank === 0, Return[Together[First[values]]]];
    half = 2^(localRank - 1);
    low = Take[values, half]; high = Drop[values, half];
    reduced = Together /@ (
      multiquadraticMultiply[low, low, Most[squares]] -
        Last[squares] multiquadraticMultiply[high, high, Most[squares]]);
    normTower[reduced, Most[squares]]];
  result = normTower[localChannels, deltas[[activeIndices]]];
  If[result === $Failed ||
      ! FreeQ[result,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    $Failed, Together[result]]
];
multiquadraticStripActiveGradeNorm[___] := $Failed;

(* Root symbols are generated from the declared frame.  Rank three is the
   current resource ceiling, not part of the algebraic ABI. *)
multiquadraticFieldDecompose[expression_, roots_List,
    validateRoundTrip_: True, normalizeInput_: True] := Module[
  {rank = Length[roots], deltas, rootImages, symbols,
   replaced, rational, numerator, denominator, numeratorChannels,
   denominatorChannels, denominatorInverse, result, channels, reconstructed},
  If[rank > $multiquadraticStripMaximumRootCount ||
      ! MemberQ[{True, False}, normalizeInput], Return[$Failed]];
  deltas = If[rank === 0, {},
    Together /@ Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]]];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  rootImages = Lookup[roots, "Root", ConstantArray[$Failed, rank]];
  If[! FreeQ[rootImages, $Failed], Return[$Failed]];
  symbols = Table[Unique["multiquadraticRoot$"], {rank}];
  replaced = If[rank === 0, expression,
    (* Deferred assembly represents inactive algebra generators by literal
       symbols.  Replace each declared root expression directly before the
       radical square-class matcher; the latter remains the fallback for
       equivalent radical spellings.  Without this first rule, literal tags
       bypassed the algebraic path as apparently root-free scalars. *)
    transportChartApplyRootBranches[
      expression /. Thread[rootImages -> symbols], roots, symbols]];
  If[replaced === $Failed, Return[$Failed]];
  (* rank 0 decides on the normal form, as it always has: Together may
     rationalize a numeric radical away, and that expression is a
     rational scalar *)
  If[rank > 0 &&
      ! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  (* Deferred target assembly already returns one exact numerator over one
     exact denominator in inert root tags.  Re-running Together on those
     multi-million-leaf quotients was the entire 635 s CF259 {24,15}
     projection.  Consumers that own that representation may skip only this
     input normalization; the polynomial guards and exact field arithmetic
     below are unchanged, and an uncombined input is refused. *)
  rational = If[TrueQ[normalizeInput], Together[replaced], replaced];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  (* Scalar-local root-free fast path (2026-08-23, ported from
     Exchange/Codex/2026-08-23/13_scalar_root_free_fast_path/
     0001-scalar-local-root-free-fast-path.patch).  A
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
    If[TrueQ[validateRoundTrip],
      reconstructed = multiquadraticFieldCompose[channels, roots];
      If[reconstructed === $Failed ||
          ! TrueQ[Together[reconstructed - expression] === 0],
        Return[$Failed]];
      $multiquadraticFieldComposeCheckCount++];
    $multiquadraticFieldRootFreeFastPathCount++;
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

(* DELETED 2026-08-26 (round-2 wave, Codex review 4.2): the first
   one-form deduplicator cluster -- multiquadraticOneFormKey,
   multiquadraticDeduplicateOneForms, multiquadraticDiagonalOneFormBasis
   and multiquadraticCandidateOneFormBasis.  A comment-stripped scan of
   FeynFacet/, Scripts/ and Tests/ found no caller outside the cluster
   itself.  multiquadraticStripCandidateLetters is the builder that
   replaced it: it keys one-forms by canonical text instead of by a
   channel fingerprint (so it never decomposes to deduplicate), it
   tags every record with its source Kind, and it mints the dlog
   certificate at the one site that pairs a letter with its one-form.
   multiquadraticScalarOneForms and multiquadraticClosedOneFormQ, which
   that builder still uses, are kept above. *)

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

(* Three invariants this section exists to enforce.  The measurements
   that established each of them, on a real block, are in
   Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   MultiquadraticMeasurementNarratives_2026-08-26.md, section 5.

   (i) REGULATOR SAMPLE VALUES ARE CHOSEN, NEVER FIXED.  A fixed sample
   list can land on poles of a block's forcing, and every candidate dlog
   built at such a value is lost.  A generic pool is therefore tested
   entry by entry and a value that makes any entry singular is
   re-sampled.
   (ii) ALGEBRAIC LETTERS ARE GENERATED WITH A CERTIFICATE, NOT GUESSED.
   An integrability condition inconsistent with every rational alphabet
   is repaired by letters A +- Sqrt[delta]: for each root square delta
   and each small product M of polar curves the rational constant c with
   delta + c M a perfect square is solved for, and A is that square root.
   The norm filter below is the certificate that keeps the family small
   -- a letter whose norm A^2 - delta carries an irreducible factor
   outside the alphabet is refused.
   (iii) THE ROW'S INSTALLED ALPHABETS BELONG IN THE BASIS.  The row's
   flatness identity couples the already-installed blocks of the same row
   and column to this one, so their letters are adjoined when the caller
   supplies them (the sector state's StripSolvers "Alphabet" entries). *)

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
  {symbols, replaced},
  If[roots === {},
    Return[TrueQ[FreeQ[expression,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]]]]];
  symbols = Table[Unique["multiquadraticRoot$"], {Length[roots]}];
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

(* When the exact grade channels already exist, they are the canonical
   field representation.  Key that rational data directly instead of
   materialising radicals and asking Together to rediscover the same
   normal form.  Dimensions are part of the payload, so a letter channel
   vector and a two-component one-form cannot collide. *)
multiquadraticStripChannelTextKey[channels_List, variables_List,
    epsilon_Symbol] := Module[{rules, depth, canonical},
  depth = ArrayDepth[channels];
  If[depth < 1, Return[$Failed]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  canonical = Quiet[Map[Together, channels /. rules, {depth}]];
  If[! ListQ[canonical] || ! FreeQ[canonical, $Failed], Return[$Failed]];
  Hash[ToString[InputForm[{Dimensions[canonical], canonical}]],
    "SHA256", "HexString"]
];
multiquadraticStripChannelTextKey[channels_List,
    variables : {_Symbol, _Symbol}] := Module[{rules, depth, canonical},
  depth = ArrayDepth[channels];
  If[depth < 1, Return[$Failed]];
  rules = Thread[variables -> {\[FormalX], \[FormalY]}];
  canonical = Quiet[Map[Together, channels /. rules, {depth}]];
  If[! ListQ[canonical] || ! FreeQ[canonical, $Failed], Return[$Failed]];
  Hash[ToString[InputForm[{Dimensions[canonical], canonical}]],
    "SHA256", "HexString"]
];
multiquadraticStripChannelTextKey[___] := $Failed;

(* A cheap structural key for an internally constructed expression.  Unlike
   the channel key this deliberately performs no algebra: it binds the exact
   raw letter stored in the record while normalizing only the two chart-symbol
   names.  The retained grade channels separately bind its field value. *)
multiquadraticStripExpressionTextKey[expression_,
    variables : {_Symbol, _Symbol}] := Hash[ToString[InputForm[
      expression /. Thread[variables -> {\[FormalX], \[FormalY]}]]],
    "SHA256", "HexString"];

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

(* A letter that already belongs to the declared multiquadratic field is
   differentiated IN THAT FIELD.  Building Together[D[L]/L] first makes
   a large radical expression and only decomposes it again in the compile
   stage.  Here L is decomposed once, inverted in the grade algebra, and
   differentiated channel by channel; composing the two channel vectors
   yields the same exact one-form without materialising that intermediate
   expression tree.  multiquadraticStripLetterChannelPair certifies the
   decomposition and inverse exactly.  Rank zero and any typed refusal
   retain the conservative historical path. *)
multiquadraticStripLetterDLogDataInField[letter_, roots_List,
    variables : {x_, y_}] := Module[
  {channelData, letterChannels = Missing["NotRetained"], channels, form,
   letterChannelKey, formChannelKey, letterExpressionKey, potentialPairKey,
   channelZeroQ},
  letterExpressionKey = multiquadraticStripExpressionTextKey[
    letter, variables];
  If[roots =!= {},
    channelData = Quiet[multiquadraticStripLetterChannelData[
      letter, roots, variables]];
    channels = If[AssociationQ[channelData],
      Lookup[channelData, "DLogChannels", $Failed], $Failed];
    letterChannels = If[AssociationQ[channelData],
      Lookup[channelData, "LetterChannels", Missing["NotRetained"]],
      Missing["NotRetained"]];
    If[MatchQ[channels, {_List, _List}] && FreeQ[channels, $Failed],
      form = Quiet[multiquadraticFieldCompose[#1, roots] & /@ channels];
      If[MatchQ[form, {_, _}] && FreeQ[form,
          $Failed | DirectedInfinity | Indeterminate],
        letterChannelKey = multiquadraticStripChannelTextKey[
          letterChannels, variables];
        formChannelKey = multiquadraticStripChannelTextKey[
          channels, variables];
        potentialPairKey = multiquadraticStripPotentialPairKey[
          letter, form, variables, \[FormalE]];
        (* Both constructors end their channel arithmetic in Together, so an
           exact zero channel is already the integer 0.  Record that verdict
           here instead of normalizing the same channels again on admission. *)
        channelZeroQ = AllTrue[Flatten[channels], SameQ[#1, 0] &];
        Return[<|"OneForm" -> form, "Channels" -> channels,
          "LetterChannels" -> letterChannels,
          "LetterChannelKey" -> letterChannelKey,
          "LetterExpressionKey" -> letterExpressionKey,
          "OneFormChannelKey" -> formChannelKey,
          "PotentialPairKey" -> potentialPairKey,
          "ChannelZeroQ" -> channelZeroQ,
          "Path" -> "GradeAlgebra"|>]]]];
  form = multiquadraticStripLetterOneForm[letter, variables];
  If[! MatchQ[form, {_, _}], Return[$Failed]];
  channels = If[roots === {}, List /@ form,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ form]];
  letterChannels = If[roots === {}, {letter}, Missing["NotRetained"]];
  potentialPairKey = multiquadraticStripPotentialPairKey[
    letter, form, variables, \[FormalE]];
  channelZeroQ = If[MatchQ[channels, {_List, _List}] &&
      FreeQ[channels, $Failed],
    AllTrue[Flatten[channels], SameQ[#1, 0] &],
    Missing["NotRetained"]];
  <|"OneForm" -> form,
    "Channels" -> If[MatchQ[channels, {_List, _List}] &&
      FreeQ[channels, $Failed], channels, Missing["NotRetained"]],
    "LetterChannels" -> letterChannels,
    "LetterChannelKey" -> If[ListQ[letterChannels],
      multiquadraticStripChannelTextKey[letterChannels, variables],
      Missing["NotRetained"]],
    "LetterExpressionKey" -> letterExpressionKey,
    "OneFormChannelKey" -> If[MatchQ[channels, {_List, _List}],
      multiquadraticStripChannelTextKey[channels, variables],
      Missing["NotRetained"]],
    "PotentialPairKey" -> potentialPairKey,
    "ChannelZeroQ" -> channelZeroQ,
    "Path" -> "MaterializedFallback"|>
];

(* Helper-side shard for the independent whole-forcing dlogs.  The payload
   is written in formal System` variables, exactly like the compile shard,
   so a helper's $Context cannot rebind chart symbols. *)
multiquadraticStripDLogShardTask[payload_Association, indices_List] := Module[
  {entries, roots, results},
  entries = Lookup[payload, "Entries", $Failed];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[entries] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ] ||
      ! AllTrue[indices, 1 <= #1 <= Length[entries] &], Return[$Failed]];
  results = multiquadraticStripLetterDLogDataInField[
      entries[[#1]], roots, {\[FormalX], \[FormalY]}] & /@ indices;
  If[! AllTrue[results, AssociationQ], $Failed,
    <|"Indices" -> indices, "Data" -> results|>]
];
multiquadraticStripDLogShardTask[dataFile_String, indices_List] := Module[
  {payload = Quiet[CheckAbort[taskBrokerRead[dataFile], $Failed]]},
  If[AssociationQ[payload],
    multiquadraticStripDLogShardTask[payload, indices], $Failed]
];
multiquadraticStripDLogShardTask[___] := $Failed;

(* Ordered batch constructor.  kernelCount is a Wolfram-worker count: 1 is the
   conservative serial path.  Under KernelPool the TaskBroker owns helpers;
   outside it, 2..8 launch only the missing subkernels and close only those
   launched here.  A failed/malformed shard is recomputed locally, so parallel
   transport can cost time but cannot change the candidate set. *)
multiquadraticStripConstructDLogBatch[letters_List, roots_List,
    variables : {x_, y_}, kernelCount_Integer] :=
  multiquadraticStripConstructDLogBatch[letters, roots, variables,
    kernelCount, Infinity];
multiquadraticStripConstructDLogBatch[letters_List, roots_List,
    variables : {x_, y_}, kernelCount_Integer, deadline_] := Module[
  {count = Length[letters], requested, launched = {}, loadFile, rules,
   inverseRules, payload, dataFile = None, groups, shardResults, data,
   validShardQ, route = "Serial", seconds = 0., body, workerKernels,
   workerIDs, kernelGroups, chunk, k, brokerFree = 0, helperCount = 0,
   helperGroups, helperResults, localGroup, localResult, codes, handle = None,
   timeout = 7200, startTime = AbsoluteTime[], invalidGroups = {},
   budgetResult = None},
  If[! multiquadraticStripDeadlineQ[deadline], Return[$Failed]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["CandidateDLogs", 0., deadline,
      <|"LetterCount" -> count, "CompletedShards" -> 0|>]]];
  requested = Min[8, Max[1, kernelCount], Max[1, count]];
  If[count === {}, Return[<|"Data" -> {}, "Route" -> route,
      "Subkernels" -> 0, "BrokerHelperCount" -> 0,
      "Seconds" -> 0.|>]];
  validShardQ[result_, group_] := AssociationQ[result] &&
    Lookup[result, "Indices", None] === group &&
    MatchQ[Lookup[result, "Data", None], {___Association}] &&
    Length[result["Data"]] === Length[group];
  body[] := Which[
   requested < 2,
    {seconds, data} = AbsoluteTiming[
      multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
        letters],

   TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]] &&
       IntegerQ[brokerFree = Quiet[Check[taskBrokerFreeKernels[], 0]]] &&
       brokerFree >= 1,
    helperCount = Min[requested - 1, count - 1, brokerFree];
    rules = Thread[variables -> {\[FormalX], \[FormalY]}];
    inverseRules = Reverse /@ rules;
    payload = <|"Entries" -> (letters /. rules),
      "Roots" -> (roots /. rules)|>;
    dataFile = taskBrokerDataFile[
      "mqdlog_" <> StringReplace[CreateUUID[], "-" -> ""], payload];
    If[! StringQ[dataFile],
      {seconds, data} = AbsoluteTiming[
        multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
          letters];
      route = "SerialFallback",
      (* The broker receives every helper shard before the mission kernel
         starts its own share.  Its resource controller may then reassign
         those queued seats when the active-family set changes. *)
      groups = Table[Range[offset, count, helperCount + 1],
        {offset, helperCount + 1}];
      helperGroups = Take[groups, helperCount];
      localGroup = Last[groups];
      codes = Table[
        "FeynFacet`Private`multiquadraticStripDLogShardTask[" <>
          ToString[dataFile, InputForm] <> "," <>
          ToString[group, InputForm] <> "]", {group, helperGroups}];
      If[NumericQ[deadline],
        timeout = Max[1, Min[timeout,
          Ceiling[deadline - AbsoluteTime[]]]]];
      {seconds, shardResults} = AbsoluteTiming[
        handle = taskBrokerSubmit[codes, "Label" -> "mqdlog",
          "Timeout" -> timeout];
        localResult = multiquadraticStripDLogShardTask[payload, localGroup];
        helperResults = taskBrokerCollect[handle];
        If[! ListQ[helperResults] ||
            Length[helperResults] =!= helperCount,
          helperResults = ConstantArray[$Failed, helperCount]];
        Append[helperResults, localResult]];
      invalidGroups = Pick[groups,
        MapThread[! validShardQ[#1, #2] &, {shardResults, groups}], True];
      If[invalidGroups =!= {} &&
          multiquadraticStripDeadlineExpiredQ[deadline],
        budgetResult = multiquadraticStripBudgetExhausted[
          "CandidateDLogs", AbsoluteTime[] - startTime, deadline,
          <|"LetterCount" -> count,
            "CompletedShards" -> Length[groups] - Length[invalidGroups],
            "MissingShardIndices" -> Flatten[invalidGroups]|>],
        data = ConstantArray[$Failed, count];
        Do[
          chunk = If[validShardQ[shardResults[[k]], groups[[k]]],
            shardResults[[k, "Data"]] /. inverseRules,
            multiquadraticStripLetterDLogDataInField[
                letters[[#1]], roots, variables] & /@ groups[[k]]];
          data[[groups[[k]]]] = chunk,
          {k, Length[groups]}];
        route = "TaskBrokerShards"]],

   ! TrueQ[$KernelID === 0],
    {seconds, data} = AbsoluteTiming[
      multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
        letters],

   True,
    If[Length[Kernels[]] < requested,
      launched = Quiet[Check[LaunchKernels[requested - Length[Kernels[]]], {}]]];
    If[Length[Kernels[]] < requested,
      {seconds, data} = AbsoluteTiming[
        multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
          letters],
      (* ParallelMap schedules over every live kernel.  That violates the
         requested cap when a caller owns a larger pre-existing pool.
         Select exactly the requested KernelObjects and give each one a
         balanced, deterministic shard through ParallelEvaluate. *)
      workerKernels = Take[Kernels[], requested];
      workerIDs = Quiet[Check[
        ParallelEvaluate[$KernelID, workerKernels], $Failed]];
      If[! VectorQ[workerIDs, IntegerQ] ||
          Length[workerIDs] =!= Length[workerKernels],
        {seconds, data} = AbsoluteTiming[
          multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
            letters];
        route = "SerialFallback",
      loadFile = $feynFacetLoader;
      If[! AllTrue[ParallelEvaluate[
          NameQ["FeynFacet`Private`multiquadraticStripDLogShardTask"],
          workerKernels],
          TrueQ],
        With[{file = loadFile},
          ParallelEvaluate[Quiet[Get[file], General::shdw], workerKernels]]];
      rules = Thread[variables -> {\[FormalX], \[FormalY]}];
      inverseRules = Reverse /@ rules;
      payload = <|"Entries" -> (letters /. rules),
        "Roots" -> (roots /. rules)|>;
      dataFile = FileNameJoin[{$TemporaryDirectory,
        "facet_mq_dlog_" <> StringReplace[CreateUUID[], "-" -> ""] <>
          ".wl"}];
      Put[payload, dataFile];
      (* Round-robin rather than contiguous shards: conjugate algebraic
         letters and hard forcing entries tend to be adjacent, so this
         prevents one helper from inheriting an entire expensive family. *)
      groups = Table[Range[offset, count, requested],
        {offset, requested}];
      kernelGroups = AssociationThread[workerIDs -> groups];
      {seconds, shardResults} = AbsoluteTiming[Quiet[Check[
        With[{file = dataFile, assignments = kernelGroups},
          ParallelEvaluate[
            FeynFacet`Private`multiquadraticStripDLogShardTask[file,
              Lookup[assignments, $KernelID, {}]], workerKernels]],
        $Failed]]];
      If[! ListQ[shardResults] ||
          Length[shardResults] =!= Length[groups],
        shardResults = ConstantArray[$Failed, Length[groups]]];
      data = ConstantArray[$Failed, count];
      Do[
        chunk = If[validShardQ[shardResults[[k]], groups[[k]]],
          shardResults[[k, "Data"]] /. inverseRules,
          multiquadraticStripLetterDLogDataInField[
              letters[[#1]], roots, variables] & /@ groups[[k]]];
        data[[groups[[k]]]] = chunk,
        {k, Length[groups]}];
      route = "ParallelShards"]]];
  CheckAbort[body[],
    If[AssociationQ[handle], Quiet[taskBrokerCancel[handle]]];
    If[StringQ[dataFile] && FileExistsQ[dataFile], Quiet[DeleteFile[dataFile]]];
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    Abort[]];
  If[StringQ[dataFile] && FileExistsQ[dataFile], Quiet[DeleteFile[dataFile]]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]];
  If[AssociationQ[budgetResult], Return[budgetResult]];
  If[! MatchQ[data, {___Association}] || Length[data] =!= count,
    {seconds, data} = AbsoluteTiming[
      multiquadraticStripLetterDLogDataInField[#1, roots, variables] & /@
        letters]; route = "SerialFallback"];
  <|"Data" -> data, "Route" -> route,
    "Subkernels" -> Which[route === "ParallelShards", requested,
      route === "TaskBrokerShards", helperCount, True, 0],
    "BrokerHelperCount" -> If[route === "TaskBrokerShards",
      helperCount, 0],
    "Seconds" -> seconds|>
];
multiquadraticStripConstructDLogBatch[___] := $Failed;

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
$multiquadraticStripLetterDLogChannelSchema =
  "MultiquadraticLetterDLogChannelsV2";

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
    "ABIVersion" -> $multiquadraticStripABIVersion,
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

(* Internal grade-algebra records use their already-certified rational
   channels as the provenance payload and also bind the exact stored letter
   spelling.  The compile boundary recomposes the one-form channels exactly;
   the spelling key detects raw-letter mutation without demanding that a
   recomposed radical expression be SameQ to an algebraically equal input.
   The five-argument V1 validator above remains the contract for records that
   do not carry retained channels. *)
multiquadraticStripLetterDLogCertificateValidQ[certificate_, letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    letterChannels_List, formChannels_List] := Module[
  {letterKey, formKey, letterExpressionKey},
  If[Lookup[certificate, "Schema", None] =!=
      $multiquadraticStripLetterDLogChannelSchema,
    Return[multiquadraticStripLetterDLogCertificateValidQ[
      certificate, letter, form, variables, epsilon]]];
  If[MissingQ[letter] || ! MatchQ[form, {_, _}], Return[False]];
  letterKey = multiquadraticStripChannelTextKey[
    letterChannels, variables, epsilon];
  formKey = multiquadraticStripChannelTextKey[
    formChannels, variables, epsilon];
  letterExpressionKey = multiquadraticStripExpressionTextKey[
    letter, variables];
  StringQ[letterKey] && StringQ[formKey] &&
    StringQ[letterExpressionKey] &&
    SameQ[KeyTake[certificate, {"Schema", "ABIVersion",
        "LetterExpressionSHA256", "LetterChannelSHA256",
        "OneFormChannelSHA256"}],
      <|"Schema" -> $multiquadraticStripLetterDLogChannelSchema,
        "ABIVersion" -> $multiquadraticStripABIVersion,
        "LetterExpressionSHA256" -> letterExpressionKey,
        "LetterChannelSHA256" -> letterKey,
        "OneFormChannelSHA256" -> formKey|>]
];

(* ------------------------------------------------------------------ *)
(* CERTIFIED dlog POTENTIALS (2026-08-26, round-2 item 7)               *)
(* ------------------------------------------------------------------ *)

(* Codex review 1.2 and Pro's answer 2, in one sentence: a hash is
   provenance, not a proof.  The certificate above proves that a letter
   and a one-form were produced TOGETHER by this code path from this
   source; an epsilon form needs the MATHEMATICAL statement

       omega_a = dlog L_a,     i.e.   omega_a - dL_a/L_a = 0 exactly,

   for an explicit potential L_a.  A closed one-form is not enough: the
   space of closed forms on a multiquadratic surface is strictly larger
   than the span of dlogs of its S-units, so "closed" leaves the result
   uninstallable and the engine has always said so.  What was missing is
   the positive half -- an actual verification, carried with the form.

   COST.  Both reviews prescribe the same policy: verify ONCE per unique
   (omega, L) pair, unconditionally, and cache the verdict by CONTENT.
   The relation is two Together calls on objects the alphabet layer has
   already normalized; against the algebraic stage it is free, and the
   cache makes a repeated pair free outright.  The key is the pair of
   canonical texts the provenance certificate already hashes, so two
   algebraically identical pairs written differently share one entry.

   SCOPE.  A record whose letter is Missing (the "Diagonal" kind: the
   scalar entries of e and c are closed forms by construction, not
   dlogs) is NOT verified and NOT installable as a certified letter --
   the absent potential is the refusal, exactly as before. *)

$multiquadraticStripPotentialSchema = "MultiquadraticVerifiedPotentialV1";
$multiquadraticStripPotentialCacheEntryLimit = 4096;
$multiquadraticStripPotentialCache = <||>;
$multiquadraticStripPotentialCounters =
  <|"Hits" -> 0, "Misses" -> 0, "Verified" -> 0, "Refused" -> 0,
    "Evictions" -> 0, "Seconds" -> 0.|>;

multiquadraticStripPotentialCacheReset[] := (
  $multiquadraticStripPotentialCache = <||>;
  $multiquadraticStripPotentialCounters =
    <|"Hits" -> 0, "Misses" -> 0, "Verified" -> 0, "Refused" -> 0,
      "Evictions" -> 0, "Seconds" -> 0.|>;);

multiquadraticStripPotentialStatistics[] :=
  Join[$multiquadraticStripPotentialCounters,
    <|"Entries" -> Length[$multiquadraticStripPotentialCache],
      "EntryLimit" -> $multiquadraticStripPotentialCacheEntryLimit|>];

(* the content key of a (one-form, letter) PAIR: the same two canonical
   texts the provenance certificate hashes, so a verified pair and its
   certificate name the same objects *)
multiquadraticStripPotentialPairKey[letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, letterText, formKey},
  If[MissingQ[letter] || ! MatchQ[form, {_, _}], Return[$Failed]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  letterText = Quiet[ToString[InputForm[Together[letter /. rules]]]];
  If[! StringQ[letterText], Return[$Failed]];
  formKey = multiquadraticStripFormTextKey[form, variables, epsilon];
  If[! StringQ[formKey], Return[$Failed]];
  Hash[{$multiquadraticStripPotentialSchema, letterText, formKey},
    "SHA256", "HexString"]
];

(* Evidence for the INTERNAL constructor, which has just produced form as
   dlog(letter).  Re-differentiating the same letter and subtracting the
   just-produced form is a tautological second construction, not an
   independent check; on a representative hard multiquadratic block it
   doubled this phase's wall time.  Bind the raw letter spelling and both
   canonical grade-channel payloads, but record explicitly that exactness
   follows from construction.  Caller-supplied pairs still go through
   multiquadraticStripVerifyPotential and can be refused. *)
multiquadraticStripConstructedDLogEvidence[letterKey_String,
    formKey_String, letterExpressionKey_String,
    potentialPairKey_String] := Module[
  {certificate, potential},
  certificate = <|"Schema" -> $multiquadraticStripLetterDLogChannelSchema,
    "ABIVersion" -> $multiquadraticStripABIVersion,
    "LetterExpressionSHA256" -> letterExpressionKey,
    "LetterChannelSHA256" -> letterKey,
    "OneFormChannelSHA256" -> formKey|>;
  potential = <|"Schema" -> $multiquadraticStripPotentialSchema,
    "Status" -> "PotentialVerified", "Verified" -> True,
    "PairKey" -> potentialPairKey,
    "ABIVersion" -> $multiquadraticStripABIVersion,
    "VerificationMethod" -> "ConstructedExactDLog"|>;
  <|"Potential" -> potential, "DLogCertificate" -> certificate|>
];
multiquadraticStripConstructedDLogEvidence[___] := $Failed;

(* THE EXACT STATEMENT, made once.  Together is used only as a zero
   test on the DIFFERENCE -- it is not asked to preserve the algebraic
   word of the letter (the trap this repository records), because
   nothing downstream reads this expression: only its vanishing. *)
multiquadraticStripPotentialRelationZeroQ[letter_, form : {_, _},
    variables : {x_Symbol, y_Symbol}] := Module[{value, dlog},
  value = Quiet[Together[letter]];
  If[TrueQ[value === 0] ||
      ! FreeQ[value, DirectedInfinity | Indeterminate], Return[False]];
  dlog = Quiet[{Together[D[value, x]/value], Together[D[value, y]/value]}];
  If[! FreeQ[dlog, DirectedInfinity | Indeterminate], Return[False]];
  TrueQ[Quiet[Together[form[[1]] - dlog[[1]]]] === 0] &&
    TrueQ[Quiet[Together[form[[2]] - dlog[[2]]]] === 0]
];

multiquadraticStripVerifyPotential[letter_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {key, cached, zeroQ, seconds, record},
  If[MissingQ[letter],
    Return[<|"Schema" -> $multiquadraticStripPotentialSchema,
      "Status" -> "NoPotentialOffered", "Verified" -> False,
      "PairKey" -> Missing["NoLetter"], "Cached" -> False|>]];
  If[! MatchQ[form, {_, _}],
    Return[<|"Schema" -> $multiquadraticStripPotentialSchema,
      "Status" -> "InvalidOneForm", "Verified" -> False,
      "PairKey" -> Missing["NoForm"], "Cached" -> False|>]];
  key = multiquadraticStripPotentialPairKey[letter, form, variables, epsilon];
  If[! StringQ[key],
    Return[<|"Schema" -> $multiquadraticStripPotentialSchema,
      "Status" -> "PairNotNormalizable", "Verified" -> False,
      "PairKey" -> Missing["NotNormalizable"], "Cached" -> False|>]];
  cached = Lookup[$multiquadraticStripPotentialCache, key, Missing["NoEntry"]];
  If[! MissingQ[cached],
    $multiquadraticStripPotentialCounters["Hits"] += 1;
    Return[Join[cached, <|"Cached" -> True|>]]];
  $multiquadraticStripPotentialCounters["Misses"] += 1;
  {seconds, zeroQ} = AbsoluteTiming[
    multiquadraticStripPotentialRelationZeroQ[letter, form, variables]];
  $multiquadraticStripPotentialCounters["Seconds"] += seconds;
  If[TrueQ[zeroQ], $multiquadraticStripPotentialCounters["Verified"] += 1,
    $multiquadraticStripPotentialCounters["Refused"] += 1];
  record = <|"Schema" -> $multiquadraticStripPotentialSchema,
    "Status" -> If[TrueQ[zeroQ], "PotentialVerified", "PotentialRefused"],
    "Verified" -> TrueQ[zeroQ], "PairKey" -> key,
    "ABIVersion" -> $multiquadraticStripABIVersion,
    "Cached" -> False|>;
  (* bounded by ENTRY COUNT: an entry is five short values and a hash,
     so a byte bound would only restate the entry bound *)
  If[Length[$multiquadraticStripPotentialCache] >=
      $multiquadraticStripPotentialCacheEntryLimit,
    $multiquadraticStripPotentialCache = <||>;
    $multiquadraticStripPotentialCounters["Evictions"] += 1];
  AssociateTo[$multiquadraticStripPotentialCache, key -> record];
  record
];

(* The verdict over a whole CANDIDATE alphabet: certified only when
   EVERY record carries a verified potential.  Since round-3 A2 this is
   TELEMETRY about the candidate pool -- it never sets the terminal
   certification bit, which belongs to the ACTIVE-support verdict below
   (an unused candidate with zero reconstructed residue cannot obstruct
   installation). *)
multiquadraticStripPotentialsCertifiedQ[letterRecords_] :=
  MatchQ[letterRecords, {___Association}] &&
    letterRecords =!= {} &&
    AllTrue[letterRecords,
      TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];

(* The kinematic part of a letter: multiplicative factors free of BOTH
   chart variables (numeric content, powers of the regulator, masses)
   are stripped -- dlog(c(eps) L0) and dlog(L0) have identical (x, y)
   components, so a letter like eps*x is the letter x wearing invisible
   content, and an INSTALLED letter must be the epsilon-independent
   representative.  A letter whose variable-carrying part still contains
   the regulator (x + eps) has genuinely kinematics-dependent regulator
   mixing and is not repairable this way: the caller rejects it. *)
multiquadraticStripLetterKinematicPart[letter_, variables_List] :=
  Quiet[Check[Module[{t = Together[letter], keep},
    keep[expr_] := Times @@ (Power[#1[[1]], #1[[2]]] & /@
      Select[FactorList[expr],
        ! FreeQ[#1[[1]], Alternatives @@ variables] &]);
    keep[Numerator[t]]/keep[Denominator[t]]], $Failed]];

(* Is a closed form an exact CONSTANT-coefficient combination of the
   verified basis one-forms?  omega_diag = Sum_a c_a omega_a with c_a
   free of the chart variables and the regulator; free parameters are
   set to zero deterministically and BOTH components are rechecked with
   an exact zero test.  A kinematics-dependent coefficient is refused:
   it would turn constant residue matrices into kinematic functions. *)
multiquadraticStripDiagonalSpan[form : {_, _}, basisForms_List,
    variables : {x_, y_}] := Module[
  {cs, difference, equations, solutions, values, exact},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  cs = Table[Unique["spanC"], {Length[basisForms]}];
  difference[mu_, coefficients_] := Together[form[[mu]] -
    Sum[coefficients[[a]] basisForms[[a, mu]], {a, Length[basisForms]}]];
  equations = And @@ Table[
    Numerator[difference[mu, cs]] == 0, {mu, 2}];
  solutions = Quiet[SolveAlways[equations, variables]];
  If[! MatchQ[solutions, {__List}], Return[Missing["NotSpanned"]]];
  values = cs /. First[solutions] /. Alternatives @@ cs -> 0;
  If[! AllTrue[values, FreeQ[#1, Alternatives @@ variables] &],
    Return[Missing["KinematicCoefficient"]]];
  exact = AllTrue[Table[difference[mu, values] === 0 ||
    Together[difference[mu, values]] === 0, {mu, 2}], TrueQ];
  If[! exact, Return[Missing["NotSpanned"]]];
  <|"Spanned" -> True, "Coefficients" -> values|>
];
multiquadraticStripDiagonalSpan[___] := Missing["InvalidSpanArguments"];

(* SolveAlways is useful for a tiny residual basis, but its polynomial
   quantifier expansion grows catastrophically with a large dlog alphabet.
   A failed sampled span is only a compression miss: retaining the diagonal
   form is conservative and leaves the downstream exact installation gate
   unchanged.  Bound the historical exact fallback instead of allowing an
   optional alphabet-reduction step to consume a whole strip budget. *)
$multiquadraticStripDiagonalSpanExactBasisLimit = 8;
multiquadraticStripDiagonalSpanBoundedExact[form : {_, _},
    basisForms_List, variables : {_, _}] :=
  If[Length[basisForms] <= $multiquadraticStripDiagonalSpanExactBasisLimit,
    multiquadraticStripDiagonalSpan[form, basisForms, variables],
    Missing["ExactSpanSkippedLargeBasis"]];
multiquadraticStripDiagonalSpanBoundedExact[___] :=
  Missing["InvalidBoundedSpanArguments"];

(* Solve a NUMERIC rational affine system with a deterministic free-zero
   section.  This is deliberately smaller than the modular solver below:
   diagonal-span sampling has no modulus and needs only one particular
   vector, followed by independent held-out rational images. *)
multiquadraticStripRationalAffineParticular[matrix_?MatrixQ,
    right_List] := Module[
  {dimensions = Dimensions[matrix], unknownCount, reduced, coefficient,
   pivotRows = {}, pivotColumns = {}, pivot, inconsistent, particular},
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[$Failed]];
  unknownCount = dimensions[[2]];
  reduced = Quiet[Check[RowReduce[MapThread[Append, {matrix, right}]],
    $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  coefficient = reduced[[All, 1 ;; unknownCount]];
  Do[
    pivot = SelectFirst[Range[unknownCount],
      ! TrueQ[coefficient[[row, #1]] === 0] &,
      Missing["NotFound"]];
    If[! MissingQ[pivot],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, pivot]],
    {row, Length[coefficient]}];
  inconsistent = AnyTrue[Range[Length[coefficient]], Function[row,
    AllTrue[coefficient[[row]], TrueQ[#1 === 0] &] &&
      ! TrueQ[reduced[[row, -1]] === 0]]];
  If[TrueQ[inconsistent],
    Return[<|"Consistent" -> False, "Rank" -> Length[pivotColumns]|>]];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] = reduced[[pivotRows[[k]], -1]],
    {k, Length[pivotColumns]}];
  <|"Consistent" -> True, "Rank" -> Length[pivotColumns],
    "ParticularSolution" -> particular|>
];
multiquadraticStripRationalAffineParticular[___] := $Failed;

(* The same coefficient matrix with several right-hand sides.  RowReduce
   is allowed to see the appended columns only when every right-hand side
   is consistent; then no appended column can become a pivot, and the
   coefficient pivots define all free-zero sections at once.  If any
   right-hand side is inconsistent the caller falls back to the scalar
   routine, which identifies the individual verdicts without relying on
   a mixed augmented reduction. *)
multiquadraticStripRationalAffineParticularBatch[matrix_?MatrixQ,
    rightMatrix_?MatrixQ] := Module[
  {dimensions = Dimensions[matrix], rightDimensions = Dimensions[rightMatrix],
   unknownCount, targetCount, reduced, coefficient, rightReduced,
   pivotRows = {}, pivotColumns = {}, pivot, zeroRows, particular},
  If[Length[dimensions] =!= 2 || Length[rightDimensions] =!= 2 ||
      dimensions[[1]] =!= rightDimensions[[1]] ||
      rightDimensions[[2]] < 1, Return[$Failed]];
  unknownCount = dimensions[[2]];
  targetCount = rightDimensions[[2]];
  reduced = Quiet[Check[RowReduce[Join[matrix, rightMatrix, 2]], $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  coefficient = reduced[[All, 1 ;; unknownCount]];
  rightReduced = reduced[[All, unknownCount + 1 ;; unknownCount + targetCount]];
  zeroRows = Select[Range[Length[coefficient]],
    AllTrue[coefficient[[#1]], TrueQ[#1 === 0] &] &];
  If[AnyTrue[Flatten[rightReduced[[zeroRows]]], ! TrueQ[#1 === 0] &],
    Return[<|"Consistent" -> False|>]];
  Do[
    pivot = SelectFirst[Range[unknownCount],
      ! TrueQ[coefficient[[row, #1]] === 0] &,
      Missing["NotFound"]];
    If[! MissingQ[pivot],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, pivot]],
    {row, Length[coefficient]}];
  particular = ConstantArray[0, {targetCount, unknownCount}];
  Do[particular[[All, pivotColumns[[k]]]] =
      rightReduced[[pivotRows[[k]], All]],
    {k, Length[pivotColumns]}];
  <|"Consistent" -> True, "Rank" -> Length[pivotColumns],
    "ParticularSolutions" -> particular|>
];
multiquadraticStripRationalAffineParticularBatch[___] := $Failed;

(* A constant-coefficient span is a linear-algebra question, not a
   polynomial-quantifier problem.  Decompose every component into the
   declared 2^r rational grade channels, evaluate those rational functions
   at deterministic exact points, and solve the resulting small rational
   system.  A sampled inconsistency is already an exact counterexample.
   A sampled solution is accepted only after six further exact-rational
   held-out points.  This is deliberately a modular-style probabilistic
   certificate (no floating tolerance); the final differential-equation
   image checks remain an independent downstream guard.

   If an expression carries parameters beyond the two chart variables, or
   the deterministic schedule does not determine a section, return typed
   NotApplicable.  Only a small residual basis may then use the historical
   SolveAlways route; a large basis keeps the diagonal form conservatively.
   The optional channel arguments allow the candidate builder to reuse the
   grade-algebra dlogs it has just constructed instead of decomposing the
   same 44-letter basis once per diagonal record. *)
$multiquadraticStripDiagonalSpanSamplePoints = {
  {2, 3}, {3, 5}, {5, 2}, {2, 5}, {-1, 2}, {2, -1}, {-2, 3}, {3, -2},
  {-3, 5}, {5, -3}, {1/2, 2/3}, {2/3, 3/5}, {3/5, 5/7}, {5/7, 7/11},
  {-1/2, 2/3}, {2/3, -1/2}, {-2/3, 3/5}, {3/5, -2/3},
  {7, 11}, {11, 7}, {-5, 7}, {7, -5}, {11, 13}, {13, 11},
  {13, 17}, {17, 13}, {-7, 11}, {11, -7}, {17, 19}, {19, 17},
  {-11, 13}, {13, -11}, {1/3, 2/5}, {2/5, 3/7}, {3/7, 5/11},
  {5/11, 7/13}, {-1/3, 2/5}, {2/5, -1/3}, {-3/7, 5/11},
  {5/11, -3/7}, {19, 23}, {23, 19}, {-13, 17}, {17, -13},
  {23, 29}, {29, 23}, {-17, 19}, {19, -17}
};

multiquadraticStripDiagonalSpanBasisImages[basisChannels_List,
    variables : {x_, y_}] := Module[
  {images = {}, rules, values, numericRationalQ},
  If[basisChannels === {}, Return[{}]];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  Do[
    rules = Thread[variables -> point];
    values = Quiet[Check[
      (Flatten[#1 /. rules] &) /@ basisChannels, $Failed]];
    If[values =!= $Failed &&
        AllTrue[Flatten[values], numericRationalQ],
      AppendTo[images, <|"Point" -> point,
        "Rows" -> Transpose[values]|>]],
    {point, $multiquadraticStripDiagonalSpanSamplePoints}];
  images
];
multiquadraticStripDiagonalSpanBasisImages[___] := $Failed;

(* Several diagonal forms share the same verified dlog basis, grade frame
   and evaluation points.  Solve their constant-coefficient span in one
   augmented reduction instead of repeating the 48-by-N row reduction for
   every scalar entry.  This fast path returns Missing on a mixed or
   parameterful case; the candidate builder then invokes the scalar
   routine for each form, so batching never weakens a verdict. *)
multiquadraticStripDiagonalSpansSampled[forms : {{_, _} ..},
    basisForms_List, roots_List, variables : {x_, y_},
    suppliedFormChannels_ : Automatic,
    suppliedBasisChannels_ : Automatic,
    suppliedBasisImages_ : Automatic] := Module[
  {gradeCount = 2^Length[roots], targetCount = Length[forms], formChannels,
   basisChannels, channelShapeQ, basisImages, imageSchedule,
   suppliedBasisImagesQ, basisValues, matrix = {}, rightMatrix = {}, rules,
   targetColumns, targetRows, rows, solve, solutions = None,
   lastRank = -1, validPoints = 0, heldOutPassed = 0,
   requiredHeldOut = 6, numericRationalQ, decompose, residual, verdict,
   basisImageShapeQ, point},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  channelShapeQ[value_] := MatchQ[value, {_List, _List}] &&
    Dimensions[value] === {2, gradeCount} && FreeQ[value, $Failed];
  decompose[oneForm_] := If[roots === {}, List /@ oneForm,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm]];
  formChannels = If[ListQ[suppliedFormChannels] &&
      Length[suppliedFormChannels] === targetCount &&
      AllTrue[suppliedFormChannels, channelShapeQ],
    suppliedFormChannels, decompose /@ forms];
  basisChannels = If[ListQ[suppliedBasisChannels] &&
      Length[suppliedBasisChannels] === Length[basisForms] &&
      AllTrue[suppliedBasisChannels, channelShapeQ],
    suppliedBasisChannels, decompose /@ basisForms];
  If[! ListQ[formChannels] || Length[formChannels] =!= targetCount ||
      ! AllTrue[formChannels, channelShapeQ] ||
      ! AllTrue[basisChannels, channelShapeQ],
    Return[Missing["SampledSpanDecompositionFailed"]]];
  basisImageShapeQ[image_] := AssociationQ[image] &&
    MatchQ[Lookup[image, "Point", None], {_, _}] &&
    MatrixQ[Lookup[image, "Rows", None]] &&
    Dimensions[image["Rows"]] === {2 gradeCount, Length[basisForms]};
  suppliedBasisImagesQ = ListQ[suppliedBasisImages] &&
      suppliedBasisImages =!= {} &&
      AllTrue[suppliedBasisImages, basisImageShapeQ];
  basisImages = If[suppliedBasisImagesQ, suppliedBasisImages, {}];
  imageSchedule = If[suppliedBasisImagesQ, basisImages,
    <|"Point" -> #1|> & /@ $multiquadraticStripDiagonalSpanSamplePoints];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  multiquadraticStripStageStart["diagonal spans: shared solve",
    <|"targets" -> targetCount, "basis" -> Length[basisForms],
      "images" -> Length[imageSchedule],
      "basisImageRoute" -> If[suppliedBasisImagesQ, "Supplied", "Lazy"]|>];
  verdict = Catch[Do[
    point = image["Point"];
    rules = Thread[variables -> point];
    If[suppliedBasisImagesQ,
      rows = image["Rows"],
      basisValues = Quiet[Check[
        (Flatten[#1 /. rules] &) /@ basisChannels, $Failed]];
      If[basisValues === $Failed ||
          ! AllTrue[Flatten[basisValues], numericRationalQ], Continue[]];
      rows = Transpose[basisValues]];
    targetColumns = Quiet[Check[
      Flatten[#1 /. rules] & /@ formChannels, $Failed]];
    If[targetColumns === $Failed ||
        ! AllTrue[Flatten[targetColumns], numericRationalQ], Continue[]];
    targetRows = Transpose[targetColumns];
    validPoints++;
    If[ListQ[solutions],
      residual = Flatten[rows . Transpose[solutions] - targetRows];
      If[AllTrue[residual, TrueQ[#1 === 0] &],
        heldOutPassed++;
        If[heldOutPassed >= requiredHeldOut,
          Throw[Table[<|"Spanned" -> True,
              "Coefficients" -> solutions[[target]],
              "Method" -> "ExactRationalImagesBatch",
              "ConstructionPoints" -> validPoints - heldOutPassed,
              "HeldOutPoints" -> heldOutPassed, "Rank" -> lastRank,
              "BatchTargets" -> targetCount|>,
            {target, targetCount}], "DiagonalSpansVerdict"]];
        Continue[],
        solutions = None; heldOutPassed = 0]];
    matrix = Join[matrix, rows];
    rightMatrix = Join[rightMatrix, targetRows];
    If[Length[matrix] < Length[basisForms], Continue[]];
    solve = multiquadraticStripRationalAffineParticularBatch[
      matrix, rightMatrix];
    If[! AssociationQ[solve] || ! TrueQ[solve["Consistent"]],
      Throw[Missing["BatchSpanMixedOrInconsistent"],
        "DiagonalSpansVerdict"]];
    lastRank = solve["Rank"];
    solutions = solve["ParticularSolutions"];
    heldOutPassed = 0,
    {image, imageSchedule}], "DiagonalSpansVerdict"];
  multiquadraticStripStageDone["diagonal spans: shared solve",
    <|"targets" -> targetCount, "validPoints" -> validPoints,
      "status" -> If[ListQ[verdict], "Spanned", "Fallback"]|>];
  If[ListQ[verdict] && Length[verdict] === targetCount, Return[verdict]];
  Missing[If[validPoints === 0, "SampledSpanNotApplicable",
    "SampledSpanBatchFallback"]]
];
multiquadraticStripDiagonalSpansSampled[___] :=
  Missing["InvalidSampledSpansArguments"];

multiquadraticStripDiagonalSpanSampled[form : {_, _}, basisForms_List,
    roots_List, variables : {x_, y_}, suppliedFormChannels_ : Automatic,
    suppliedBasisChannels_ : Automatic,
    suppliedBasisImages_ : Automatic] := Module[
  {gradeCount = 2^Length[roots], formChannels, basisChannels, channelShapeQ,
   basisImages, matrix = {}, right = {}, rules, targetValues, rows, solve,
   solution = None, lastRank = -1, validPoints = 0, heldOutPassed = 0,
   requiredHeldOut = 6, numericRationalQ, decompose, residual, verdict,
   basisImageShapeQ, point},
  If[basisForms === {}, Return[Missing["NoBasis"]]];
  multiquadraticStripStageStart["diagonal span: channel preparation",
    <|"basis" -> Length[basisForms], "rank" -> Length[roots]|>];
  channelShapeQ[value_] := MatchQ[value, {_List, _List}] &&
    Dimensions[value] === {2, gradeCount} && FreeQ[value, $Failed];
  decompose[oneForm_] := If[roots === {}, List /@ oneForm,
    Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm]];
  formChannels = If[channelShapeQ[suppliedFormChannels],
    suppliedFormChannels, decompose[form]];
  basisChannels = If[
    ListQ[suppliedBasisChannels] &&
      Length[suppliedBasisChannels] === Length[basisForms] &&
      AllTrue[suppliedBasisChannels, channelShapeQ],
    suppliedBasisChannels, decompose /@ basisForms];
  If[! channelShapeQ[formChannels] ||
      ! AllTrue[basisChannels, channelShapeQ],
    Return[Missing["SampledSpanDecompositionFailed"]]];
  basisImageShapeQ[image_] := AssociationQ[image] &&
    MatchQ[Lookup[image, "Point", None], {_, _}] &&
    MatrixQ[Lookup[image, "Rows", None]] &&
    Dimensions[image["Rows"]] === {2 gradeCount, Length[basisForms]};
  basisImages = If[ListQ[suppliedBasisImages] &&
      suppliedBasisImages =!= {} &&
      AllTrue[suppliedBasisImages, basisImageShapeQ],
    suppliedBasisImages,
    multiquadraticStripDiagonalSpanBasisImages[basisChannels, variables]];
  If[! ListQ[basisImages] || basisImages === {},
    Return[Missing["SampledSpanNoBasisImages"]]];
  multiquadraticStripStageDone["diagonal span: channel preparation",
    <|"basis" -> Length[basisChannels], "images" -> Length[basisImages]|>];
  numericRationalQ[value_] := IntegerQ[value] || Head[value] === Rational;
  verdict = Catch[Do[
    point = image["Point"];
    rows = image["Rows"];
    multiquadraticStripStageStart["diagonal span: rational image",
      <|"point" -> point, "accepted" -> validPoints|>];
    rules = Thread[variables -> point];
    targetValues = Quiet[Check[Flatten[formChannels /. rules], $Failed]];
    If[targetValues === $Failed ||
        ! AllTrue[targetValues, numericRationalQ],
      multiquadraticStripStageDone["diagonal span: rational image",
        <|"point" -> point, "status" -> "Rejected"|>];
      Continue[]];
    validPoints++;
    multiquadraticStripStageDone["diagonal span: rational image",
      <|"point" -> point, "rows" -> Length[rows]|>];
    (* Once a construction prefix has proposed constant coefficients,
       the next points are HELD OUT: they neither choose nor modify that
       vector when it passes.  Six independent exact-rational images are
       the same probabilistic certification policy used by the modular
       strip solver; no floating tolerance enters.  A failure is folded
       into the construction system and a new section is solved. *)
    If[ListQ[solution],
      residual = Together /@ (rows . solution - targetValues);
      If[AllTrue[residual, TrueQ[#1 === 0] &],
        heldOutPassed++;
        If[heldOutPassed >= requiredHeldOut,
          Throw[<|"Spanned" -> True, "Coefficients" -> solution,
            "Method" -> "ExactRationalImages",
            "ConstructionPoints" -> validPoints - heldOutPassed,
            "HeldOutPoints" -> heldOutPassed, "Rank" -> lastRank|>,
            "DiagonalSpanVerdict"]];
        Continue[],
        solution = None; heldOutPassed = 0]];
    matrix = Join[matrix, rows];
    right = Join[right, targetValues];
    If[Length[matrix] < Length[basisForms], Continue[]];
    multiquadraticStripStageStart["diagonal span: row reduction",
      <|"rows" -> Length[matrix], "columns" -> Length[basisForms]|>];
    solve = multiquadraticStripRationalAffineParticular[matrix, right];
    multiquadraticStripStageDone["diagonal span: row reduction",
      <|"status" -> If[AssociationQ[solve],
        Lookup[solve, "Consistent", None], "Failed"]|>];
    If[! AssociationQ[solve],
      Throw[Missing["SampledSpanLinearSolveFailed"],
        "DiagonalSpanVerdict"]];
    If[! TrueQ[solve["Consistent"]],
      Throw[<|"Spanned" -> False, "Method" -> "ExactSampleCounterexample",
        "ValidPoints" -> validPoints, "Rank" -> solve["Rank"]|>,
        "DiagonalSpanVerdict"]];
    lastRank = solve["Rank"];
    solution = solve["ParticularSolution"];
    heldOutPassed = 0,
    {image, basisImages}],
    "DiagonalSpanVerdict"];
  If[verdict =!= Null, Return[verdict]];
  Missing[If[validPoints === 0, "SampledSpanNotApplicable",
    "SampledSpanUnderdetermined"]]
];
multiquadraticStripDiagonalSpanSampled[___] :=
  Missing["InvalidSampledSpanArguments"];

(* THE INSTALLATION VERDICT (round-3 A2): computed from the exact
   reconstructed representation, never from the candidate pool.  A
   letter is ACTIVE iff at least one entry of its reconstructed residue
   matrix K_a(eps) is not the zero rational function -- an exact
   one-variable test per scalar, never a sampled or floating one.
   Verified potentials are required exactly for the active support; an
   empty active alphabet is vacuously certified for a gauge-only
   solution (AllTrue[{}, ...] is the desired mathematical semantics).
   If reconstruction was skipped or failed the verdict is
   PendingReconstruction, not False. *)
multiquadraticStripActivePotentialCertification[
    letterRecords : {___Association}, residues_, reconstructedQ_] := Module[
  {zeroEntryQ, activeQ, active, inactive, unverifiedActive},
  If[! TrueQ[reconstructedQ] || ! ListQ[residues] ||
      Length[residues] =!= Length[letterRecords],
    Return[<|"Status" -> "ActivePotentialCertificationV1",
      "Certified" -> False,
      "Pending" -> "PendingReconstruction",
      "ActiveIndices" -> Missing["PendingReconstruction"],
      "EmptyActiveAlphabet" -> Missing["PendingReconstruction"]|>]];
  zeroEntryQ[q_] := Quiet[Check[Numerator[Together[q]] === 0, False]];
  activeQ[matrix_] := ! AllTrue[Flatten[{matrix}], zeroEntryQ];
  active = Select[Range[Length[letterRecords]], activeQ[residues[[#1]]] &];
  inactive = Complement[Range[Length[letterRecords]], active];
  unverifiedActive = Select[active, ! TrueQ[Lookup[
    Lookup[letterRecords[[#1]], "Potential", <||>], "Verified", False]] &];
  <|"Status" -> "ActivePotentialCertificationV1",
    "ActiveIndices" -> active,
    "InactiveIndices" -> inactive,
    "ActiveLetterRecords" -> (KeyTake[letterRecords[[#1]],
      {"Kind", "Letter", "FormKey", "Potential"}] & /@ active),
    "ActiveOneForms" -> (Lookup[letterRecords[[#1]], "OneForm",
      Missing["NoOneForm"]] & /@ active),
    "ActiveResidues" -> residues[[active]],
    "EmptyActiveAlphabet" -> (active === {}),
    "Certified" -> (unverifiedActive === {}),
    "UnverifiedActiveIndices" -> unverifiedActive|>
];
multiquadraticStripActivePotentialCertification[___] :=
  multiquadraticStripFailure["InvalidActiveCertificationArguments"];

(* The exact basis change for a redundant diagnostic column that
   survived into a reconstructed result: with omega_diag =
   Sum_a c_a omega_a, the residues transfer as
       K_a' = K_a + c_a K_diag,   K_diag' = 0,
   and Sum K' omega is EXACTLY Sum K omega -- the caller rechecks the
   differential residual before installation regardless. *)
multiquadraticStripTransferDiagnosticResidues[residues_List,
    diagnosticIndex_Integer, coefficients_List, basisIndices_List] := Module[
  {out = residues, diagResidue},
  If[diagnosticIndex < 1 || diagnosticIndex > Length[residues] ||
      Length[coefficients] =!= Length[basisIndices],
    Return[multiquadraticStripFailure["InvalidResidueTransfer"]]];
  diagResidue = residues[[diagnosticIndex]];
  Do[out[[basisIndices[[a]]]] = Map[Together,
      out[[basisIndices[[a]]]] + coefficients[[a]] diagResidue, {-1}],
    {a, Length[basisIndices]}];
  out[[diagnosticIndex]] = Map[0 &, diagResidue, {-1}];
  out
];
multiquadraticStripTransferDiagnosticResidues[___] :=
  multiquadraticStripFailure["InvalidResidueTransferArguments"];

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
  "MaximumNormExponent" -> 2,
  (* 1 = serial; 2..8 = requested Wolfram workers.  Automatic uses the
     current TaskBroker helper allocation inside KernelPool, otherwise the
     already-live subkernels (and launches none). *)
  "DLogKernels" -> Automatic,
  "Deadline" -> Infinity
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
   additionalLetters, additionalData,
   records = {}, channelByFormKey = <||>, form, rootSquares, entries, diagonal,
   rowSource, add, counts, rawCount, kindRank, priority,
   grouped, verifiedRecords, verifiedForms, verifiedChannelForms,
   verifiedBasisImages, diagnosticRecords, diagonalBatchRecords,
   diagonalBatchChannelForms, diagonalBatchSpans, diagonalSpanIndex = 0,
   regulatorRejected = 0,
   dlogKernelRequest, dlogKernelCount, dlogDeadline, forcingEntries,
   derivedLetters,
   derivedBatch, derivedData, forcingData, rationalData, algebraicData,
   algebraicLetters},
  pool = Replace[OptionValue["RegulatorSamplePool"],
    Automatic :> $multiquadraticStripRegulatorSamplePool];
  sampleCount = OptionValue["RegulatorSampleCount"];
  dlogDeadline = OptionValue["Deadline"];
  dlogKernelRequest = OptionValue["DLogKernels"];
  dlogKernelCount = Replace[dlogKernelRequest,
    Automatic :> If[TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
      With[{free = Quiet[Check[taskBrokerFreeKernels[], 0]]},
        If[IntegerQ[free] && free >= 0, Max[1, Min[8, free + 1]], 1]],
      Max[1, Min[8, Length[Kernels[]]]]]];
  If[! IntegerQ[sampleCount] || sampleCount < 1 || ! ListQ[pool] || pool === {},
    Return[multiquadraticStripFailure["InvalidRegulatorSampleRequest",
      <|"RegulatorSampleCount" -> sampleCount|>]]];
  If[! IntegerQ[dlogKernelCount] || ! (1 <= dlogKernelCount <= 8),
    Return[multiquadraticStripFailure["InvalidDLogKernelCount",
      <|"DLogKernels" -> dlogKernelRequest,
        "Expected" -> "Automatic or an integer from 1 through 8"|>]]];
  If[! multiquadraticStripDeadlineQ[dlogDeadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> dlogDeadline|>]]];
  additional = Flatten[{OptionValue["AdditionalLetters"]}];
  If[AnyTrue[additional, AssociationQ[#1] &&
        (! KeyExistsQ[#1, "Letter"] ||
          ! MatchQ[Lookup[#1, "GaugeNormPower", 1],
            _Integer?NonNegative] ||
          ! MatchQ[Lookup[#1, "SourcePoleOrderUpperBound", 1],
            _Integer?Positive]) &],
    Return[multiquadraticStripFailure[
      "InvalidAdditionalLetterMetadata"]]];
  additionalLetters = Map[
    If[AssociationQ[#1], #1["Letter"], #1] &, additional];
  multiquadraticStripStageStart["candidate letters: regulator samples"];
  samples = multiquadraticStripRegulatorSampleValues[bbar, variables, epsilon,
    sampleCount, pool];
  multiquadraticStripStageDone["candidate letters: regulator samples"];
  rootSquares = Lookup[roots, "RootSquare", {}];
  entries = Flatten[samples["SubstitutedEntries"]];
  multiquadraticStripStageStart["candidate letters: polar census",
    <|"forcingEntries" -> Length[entries]|>];
  alphabet = multiquadraticStripRationalPolarCurves[
    Join[entries, Flatten[e], Flatten[c]], rootSquares, variables];
  multiquadraticStripStageDone["candidate letters: polar census",
    <|"curves" -> Length[alphabet]|>];
  multiquadraticStripStageStart["candidate letters: algebraic generation",
    <|"rank" -> Length[roots], "curves" -> Length[alphabet]|>];
  algebraic = Replace[OptionValue["AlgebraicLetters"],
    Automatic :> multiquadraticStripAlgebraicLetters[roots, alphabet, variables,
      "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
      "MaximumNormExponent" -> OptionValue["MaximumNormExponent"]]];
  multiquadraticStripStageDone["candidate letters: algebraic generation",
    <|"records" -> Length[Flatten[{algebraic}]]|>];
  If[! MatchQ[algebraic, {___Association}],
    algebraic = <|"Kind" -> "Algebraic", "Letter" -> #1,
      "Norm" -> Missing["NotDerived"]|> & /@ Flatten[{algebraic}]];
  rowSource = Replace[OptionValue["RowAlphabet"],
    Automatic :> multiquadraticStripRowAlphabetLetters[
      Replace[Lookup[record, "StripSolvers", {}], Except[_List] :> {}],
      Lookup[record, "Sector", None], Lookup[record, "LowerSector", None]]];
  rowLetters = Flatten[{rowSource}];
  (* accumulate RAW records, in a fixed order, with a text key per
     one-form.  Since round-3 A2 there is NO first-wins deduplication
     here: every valid record is collected, and a second phase below
     chooses one representative per one-form by a stable priority, so a
     later VERIFIED letter replaces an earlier unverified record with
     the same one-form instead of being discarded by it. *)
  add[kind_String, letterIn_, oneFormIn_, extra_Association] := Module[
    {fkey, letter = letterIn, oneForm = oneFormIn, stripped,
     extraOut = extra,
     derivedNorm = Missing["NotDerived"],
     constructedQ = oneFormIn === Automatic || AssociationQ[oneFormIn],
     evidence, potential, certificate, dlogData,
     channels = Missing["NotRetained"],
     letterChannels = Missing["NotRetained"], channelRepresentationQ,
     constructedChannelEvidenceQ, letterChannelKey = $Failed,
     letterExpressionKey = $Failed, potentialPairKey = $Failed,
     suppliedFormChannelKey = $Failed,
     constructedChannelZeroQ = Missing["NotRetained"], zeroQ},
    (* AN INSTALLED LETTER MUST BE EPSILON-INDEPENDENT (round-3 A2): a
       letter such as eps*x has the same kinematic dlog as x, so its
       one-form passes the filter above while the letter symbol does
       not.  A proven kinematics-independent multiplicative content is
       stripped and the potential verified against the stripped letter;
       a letter whose variable-carrying part still contains the
       regulator (x + eps) is rejected. *)
    If[! MissingQ[letter] && ! FreeQ[letter, epsilon],
      stripped = multiquadraticStripLetterKinematicPart[letter, variables];
      If[stripped === $Failed || ! FreeQ[stripped, epsilon],
        regulatorRejected++; Return[Null]];
      letter = stripped;
      extraOut = Join[extraOut, <|"StrippedContent" -> True|>]];
    (* Every non-diagonal candidate below passes Automatic: derive the
       one-form HERE, after epsilon-only content has been stripped, so
       the stored letter and stored form are one indivisible construction.
       At positive root rank the grade-algebra path avoids the expanded
       D[L]/L tree; its conservative fallback is the historical routine. *)
    If[constructedQ,
      If[MissingQ[letter], Return[Null]];
      dlogData = If[AssociationQ[oneFormIn], oneFormIn,
        multiquadraticStripLetterDLogDataInField[
          letter, roots, variables]];
      If[! AssociationQ[dlogData], Return[Null]];
      oneForm = Lookup[dlogData, "OneForm", $Failed];
      channels = Lookup[dlogData, "Channels", Missing["NotRetained"]];
      letterChannels = Lookup[dlogData, "LetterChannels",
        Missing["NotRetained"]];
      letterChannelKey = Lookup[dlogData, "LetterChannelKey", $Failed];
      letterExpressionKey = Lookup[dlogData,
        "LetterExpressionKey", $Failed];
      suppliedFormChannelKey = Lookup[dlogData,
        "OneFormChannelKey", $Failed];
      potentialPairKey = Lookup[dlogData, "PotentialPairKey", $Failed];
      constructedChannelZeroQ = Lookup[dlogData, "ChannelZeroQ",
        Missing["NotRetained"]]];
    If[oneForm === $Failed || ! MatchQ[oneForm, {_, _}], Return[Null]];
    channelRepresentationQ = MatchQ[channels, {_List, _List}] &&
      Dimensions[channels] === {2, 2^Length[roots]} &&
      FreeQ[channels, $Failed];
    If[! constructedQ && ! channelRepresentationQ,
      channels = Quiet[multiquadraticFieldDecompose[#1, roots] & /@ oneForm];
      channelRepresentationQ = MatchQ[channels, {_List, _List}] &&
        Dimensions[channels] === {2, 2^Length[roots]} &&
        FreeQ[channels, $Failed]];
    constructedChannelEvidenceQ = constructedQ && channelRepresentationQ &&
      ListQ[letterChannels] &&
      Length[letterChannels] === 2^Length[roots] &&
      FreeQ[letterChannels, $Failed];
    (* Caller-supplied algebraic letters arrive without the Norm metadata that
       the automatic A+-sqrt(delta) constructor carries.  Their exact letter
       channels are already available here from the parallel dlog batch, so
       derive the active-tower norm from those eight coefficients instead of
       launching a second serial symbolic divisor pass. *)
    If[constructedChannelEvidenceQ &&
        MissingQ[Lookup[extraOut, "Norm", Missing["NoNorm"]]] &&
        ! multiquadraticStripZeroQ[Rest[letterChannels]],
      derivedNorm = multiquadraticStripActiveGradeNorm[letterChannels,
        Together /@ rootSquares];
      If[derivedNorm =!= $Failed,
        extraOut = Join[extraOut, <|"Norm" -> derivedNorm,
          "NormDerivedFromChannels" -> True|>]]];
    zeroQ = If[channelRepresentationQ && constructedQ &&
        MatchQ[constructedChannelZeroQ, True | False],
      constructedChannelZeroQ,
      If[channelRepresentationQ, multiquadraticStripZeroQ[channels],
        multiquadraticStripZeroQ[oneForm]]];
    If[TrueQ[zeroQ], Return[Null]];
    (* THE regulator, not a symbol whose NAME starts with "eps" (round-2
       item 1, Codex review 1.6).  The spelling test was wrong in both
       directions: a production regulator named `ee` was invisible to it,
       so a form carrying the regulator entered the supposedly
       regulator-free basis; and an ordinary kinematic or mass symbol
       spelled `eps...` was filtered out of an alphabet it belongs to.
       The regulator argument is already in scope here. *)
    If[! FreeQ[oneForm, epsilon], Return[Null]];
    (* The retained channels are exact membership evidence: the internal
       constructor decomposed the letter, inverted and differentiated in
       the grade algebra, then composed this very one-form.  Re-decomposing
       both materialized components here repeats the expensive operation
       the compact route was designed to avoid.  Forms without that
       evidence retain the historical exact membership gate. *)
    If[! channelRepresentationQ &&
        (! multiquadraticStripFieldMemberQ[oneForm[[1]], roots] ||
         ! multiquadraticStripFieldMemberQ[oneForm[[2]], roots]), Return[Null]];
    fkey = If[channelRepresentationQ,
      If[constructedQ && StringQ[suppliedFormChannelKey],
        suppliedFormChannelKey,
        multiquadraticStripChannelTextKey[channels, variables, epsilon]],
      multiquadraticStripFormTextKey[oneForm, variables, epsilon]];
    If[! StringQ[fkey], Return[Null]];
    If[constructedChannelEvidenceQ,
      If[! StringQ[letterChannelKey],
        letterChannelKey = multiquadraticStripChannelTextKey[
          letterChannels, variables, epsilon]];
      If[! StringQ[letterChannelKey], Return[Null]];
      If[! StringQ[letterExpressionKey],
        letterExpressionKey = multiquadraticStripExpressionTextKey[
          letter, variables]];
      If[! StringQ[letterExpressionKey], Return[Null]];
      If[! StringQ[potentialPairKey],
        potentialPairKey = multiquadraticStripPotentialPairKey[
          letter, oneForm, variables, epsilon]];
      If[! StringQ[potentialPairKey], Return[Null]];
      evidence = multiquadraticStripConstructedDLogEvidence[
        letterChannelKey, fkey, letterExpressionKey, potentialPairKey];
      If[! AssociationQ[evidence], Return[Null]];
      potential = evidence["Potential"];
      certificate = evidence["DLogCertificate"],
      potential = KeyDrop[multiquadraticStripVerifyPotential[letter,
        oneForm, variables, epsilon], "Cached"];
      certificate = If[MissingQ[letter], Missing["NotADLog"],
        multiquadraticStripLetterDLogCertificate[
          letter, oneForm, variables, epsilon]]];
    If[constructedQ && channelRepresentationQ &&
        TrueQ[Lookup[potential, "Verified", False]],
      AssociateTo[channelByFormKey, fkey -> channels]];
    (* THE dlog CERTIFICATE, minted at the one site that pairs a letter
       with the one-form computed from it.  A "Diagonal" record carries
       Missing["NotADLog"] as its letter and therefore no certificate: it
       is a closed form, not a dlog, and the compact route must refuse it
       -- which is exactly what an absent certificate makes it do. *)
    (* THE POTENTIAL, verified once per unique (omega, L) pair and cached
       by content (round-2 item 7).  This is the mathematical statement
       the certificate above only carries provenance for: a record whose
       "Potential" is not Verified is not an installable letter, whatever
       its provenance says. *)
    AppendTo[records, Join[<|"Kind" -> kind, "Letter" -> letter,
      "OneForm" -> oneForm, "FormKey" -> fkey,
      (* KeyDrop["Cached"]: whether this pair was verified now or read
         from the content cache is PROCESS telemetry, and two otherwise
         identical preparations must be byte-identical (the prepare-core
         suite compares them with SameQ).  The hit/miss counts stay
         available through multiquadraticStripPotentialStatistics[]. *)
      "Potential" -> potential,
      "DLogCertificate" -> certificate|>,
      If[channelRepresentationQ,
        <|"OneFormChannels" -> channels|>, <||>],
      If[constructedQ && channelRepresentationQ &&
          TrueQ[Lookup[potential, "Verified", False]],
        (* The compiler recomposes these exact channels against both raw
           fields before using them. *)
        <|"DLogChannels" -> channels,
          "DLogLetterChannels" -> letterChannels|>, <||>], extraOut]]];
  multiquadraticStripStageStart["candidate letters: diagonal records"];
  diagonal = multiquadraticScalarOneForms /@ {e, c};
  Do[
    If[! multiquadraticClosedOneFormQ[form, variables], Continue[]];
    add["Diagonal", Missing["NotADLog"], form, <||>],
    {form, Flatten[diagonal, 1]}];
  multiquadraticStripStageDone["candidate letters: diagonal records",
    <|"records" -> Length[records]|>];
  multiquadraticStripStageStart["candidate letters: forcing dlogs",
    <|"entries" -> Length[entries]|>];
  forcingEntries = Select[entries,
    ! TrueQ[Together[#1] === 0] &&
      ! FreeQ[#1, Alternatives @@ variables] &];
  (* One helper bootstrap covers every package-derived dlog.  Splitting only
     ForcingDLog and then rebuilding rational and algebraic dlogs serially
     leaves most of a large alphabet on the main kernel.  These constructions
     are independent and obey the same exact grade-algebra ABI. *)
  algebraicLetters = Lookup[algebraic, "Letter", {}];
  derivedLetters = Join[forcingEntries, alphabet, algebraicLetters,
    additionalLetters];
  derivedBatch = multiquadraticStripConstructDLogBatch[
    derivedLetters, roots, variables, dlogKernelCount, dlogDeadline];
  If[! AssociationQ[derivedBatch],
    Return[multiquadraticStripFailure["DerivedDLogConstructionFailed"]]];
  If[Lookup[derivedBatch, "Status", None] === "BudgetExhausted",
    Return[derivedBatch]];
  derivedData = Lookup[derivedBatch, "Data", {}];
  If[Length[derivedData] =!= Length[derivedLetters],
    Return[multiquadraticStripFailure["DerivedDLogConstructionFailed",
      <|"Expected" -> Length[derivedLetters],
        "Received" -> Length[derivedData]|>]]];
  forcingData = Take[derivedData, Length[forcingEntries]];
  rationalData = Take[Drop[derivedData, Length[forcingEntries]],
    Length[alphabet]];
  algebraicData = Take[Drop[derivedData,
      Length[forcingEntries] + Length[alphabet]],
    Length[algebraicLetters]];
  additionalData = Drop[derivedData,
    Length[forcingEntries] + Length[alphabet] + Length[algebraicLetters]];
  MapThread[add["ForcingDLog", #1, #2, <||>] &,
    {forcingEntries, forcingData}];
  multiquadraticStripStageDone["candidate letters: forcing dlogs",
    <|"records" -> Length[records],
      "batchedDLogs" -> Length[derivedLetters],
      "route" -> Lookup[derivedBatch, "Route", None],
      "subkernels" -> Lookup[derivedBatch, "Subkernels", 0],
      "seconds" -> Lookup[derivedBatch, "Seconds", Missing["NotMeasured"]]|>];
  multiquadraticStripStageStart["candidate letters: rational factors",
    <|"curves" -> Length[alphabet]|>];
  MapThread[add["RationalFactor", #1, #2, <||>] &,
    {alphabet, rationalData}];
  multiquadraticStripStageDone["candidate letters: rational factors",
    <|"records" -> Length[records]|>];
  multiquadraticStripStageStart["candidate letters: algebraic records",
    <|"candidates" -> Length[algebraic]|>];
  MapThread[Function[{recordItem, dlogItem},
      add["Algebraic", recordItem["Letter"], dlogItem,
        KeyTake[recordItem,
          {"A", "Norm", "RootSquare", "NormInAlphabet"}]]],
    {algebraic, algebraicData}];
  multiquadraticStripStageDone["candidate letters: algebraic records",
    <|"records" -> Length[records]|>];
  multiquadraticStripStageStart["candidate letters: inherited records",
    <|"row" -> Length[rowLetters], "supplied" -> Length[additional]|>];
  Do[add["RowAlphabet", letter, Automatic, <||>],
    {letter, rowLetters}];
  MapThread[Function[{item, dlogItem},
    If[AssociationQ[item],
      add["Supplied", item["Letter"], dlogItem,
        KeyTake[item,
          {"GaugeNormPower", "SourcePoleOrderUpperBound"}]],
      add["Supplied", item, dlogItem, <||>]]],
    {additional, additionalData}];
  multiquadraticStripStageDone["candidate letters: inherited records",
    <|"records" -> Length[records]|>];
  rawCount = Length[records];
  (* ---- phase 2 (round-3 A2): one representative per one-form, by a
     STABLE priority -- verified potential first, then installed
     row-alphabet letters, supplied letters, derived rational/algebraic/
     forcing letters, and last the bare diagnostic diagonal forms.  The
     representative sits in the slot of the key's FIRST occurrence, and
     the kinds it superseded travel with it as diagnostics. *)
  multiquadraticStripStageStart["candidate letters: deduplicate",
    <|"records" -> rawCount|>];
  kindRank = <|"RowAlphabet" -> 2, "Supplied" -> 3, "RationalFactor" -> 4,
    "Algebraic" -> 4, "ForcingDLog" -> 4, "Diagonal" -> 5|>;
  priority[rec_] := {If[TrueQ[Lookup[Lookup[rec, "Potential", <||>],
      "Verified", False]], 0, 1],
    Lookup[kindRank, Lookup[rec, "Kind", None], 4]};
  grouped = GroupBy[records, Lookup[#1, "FormKey", None] &];
  records = Table[Module[{group = grouped[key], best},
      best = First[MinimalBy[group, priority]];
      If[Length[group] > 1,
        best = Join[best, <|"SupersededKinds" -> DeleteCases[
          Lookup[group, "Kind", None], Lookup[best, "Kind", None]]|>]];
      best],
    {key, DeleteDuplicates[Lookup[records, "FormKey", {}]]}];
  multiquadraticStripStageDone["candidate letters: deduplicate",
    <|"records" -> Length[records]|>];
  (* ---- phase 3 (round-3 A2): a bare unverified Diagonal form that is
     an exact CONSTANT-coefficient combination of the verified letters is
     DIAGNOSTIC, not a basis vector: its column is omitted before the
     unknown layout is made, and the span certificate travels with it so
     residues on the verified letters carry the same connection. *)
  multiquadraticStripStageStart["candidate letters: diagonal span",
    <|"records" -> Length[records]|>];
  verifiedRecords = Select[records,
    TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];
  verifiedForms = Lookup[verifiedRecords, "OneForm", {}];
  verifiedChannelForms = Lookup[channelByFormKey,
    Lookup[verifiedRecords, "FormKey", {}], Missing["NotRetained"]];
  verifiedBasisImages = Automatic;
  diagonalBatchRecords = Select[records,
    Lookup[#1, "Kind", None] === "Diagonal" &&
      ! TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &];
  diagonalBatchChannelForms = Lookup[diagonalBatchRecords,
    "OneFormChannels", Automatic];
  diagonalBatchSpans = If[diagonalBatchRecords === {}, {},
    multiquadraticStripDiagonalSpansSampled[
      Lookup[diagonalBatchRecords, "OneForm", {}], verifiedForms, roots,
      variables, diagonalBatchChannelForms, verifiedChannelForms,
      verifiedBasisImages]];
  (* The normal all-spanned route evaluates basis images lazily and stops
     after its construction plus held-out points.  Only a mixed/refused
     batch needs the complete reusable table for the scalar fallbacks. *)
  If[MissingQ[diagonalBatchSpans] && diagonalBatchRecords =!= {} &&
      verifiedChannelForms =!= {} &&
      AllTrue[verifiedChannelForms, MatchQ[#1, {_List, _List}] &],
    verifiedBasisImages = multiquadraticStripDiagonalSpanBasisImages[
      verifiedChannelForms, variables]];
  diagnosticRecords = {};
  records = Fold[Function[{kept, rec},
    If[Lookup[rec, "Kind", None] === "Diagonal" &&
        ! TrueQ[Lookup[Lookup[rec, "Potential", <||>], "Verified", False]],
      Module[{diagonalForm = Lookup[rec, "OneForm", $Failed], span},
        diagonalSpanIndex++;
        span = If[ListQ[diagonalBatchSpans] &&
            Length[diagonalBatchSpans] === Length[diagonalBatchRecords],
          diagonalBatchSpans[[diagonalSpanIndex]],
          multiquadraticStripDiagonalSpanSampled[diagonalForm,
            verifiedForms, roots, variables,
            Lookup[rec, "OneFormChannels", Automatic],
            verifiedChannelForms, verifiedBasisImages]];
        If[MissingQ[span],
          span = multiquadraticStripDiagonalSpanBoundedExact[
            diagonalForm, verifiedForms, variables]];
        If[AssociationQ[span] && TrueQ[span["Spanned"]],
          AppendTo[diagnosticRecords, Join[rec,
            <|"Diagnostic" -> True, "SpannedBy" -> span["Coefficients"],
              "SpanCertificate" -> KeyDrop[span, "Coefficients"]|>]];
          kept,
          Append[kept, rec]]],
      Append[kept, rec]]], {}, records];
  multiquadraticStripStageDone["candidate letters: diagonal span",
    <|"installed" -> Length[records],
      "diagnostic" -> Length[diagnosticRecords]|>];
  counts = Association[Table[kind -> Count[records, item_ /;
      Lookup[item, "Kind", None] === kind],
    {kind, {"Diagonal", "ForcingDLog", "RationalFactor", "Algebraic",
      "RowAlphabet", "Supplied"}}]];
  <|"Status" -> "MultiquadraticCandidateLettersV1",
    "OneForms" -> Lookup[records, "OneForm", {}],
    "Letters" -> Lookup[records, "Letter", {}],
    "LetterRecords" -> records,
    (* the spanned diagonal forms, kept OUT of the unknown layout *)
    "DiagnosticRecords" -> diagnosticRecords,
    (* round-2 item 7 + round-3 A2: per-letter verdicts, and a summary
       that is TELEMETRY about the candidate pool -- the installation
       verdict is the ACTIVE-support certification, computed only after
       regulator reconstruction *)
    "PotentialsVerified" -> Count[records,
      item_ /; TrueQ[Lookup[Lookup[item, "Potential", <||>], "Verified",
        False]]],
    "PotentialsRefused" -> Count[records,
      item_ /; ! TrueQ[Lookup[Lookup[item, "Potential", <||>], "Verified",
        False]]],
    "PotentialsCertified" -> multiquadraticStripPotentialsCertifiedQ[records],
    "CandidatePotentialSummary" -> <|
      "Considered" -> rawCount,
      "Installed" -> Length[records],
      "Diagnostic" -> Length[diagnosticRecords],
      "RegulatorContentRejected" -> regulatorRejected,
      "Superseded" -> Count[records, item_ /;
        Lookup[item, "SupersededKinds", {}] =!= {}]|>,
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
    variables_List] := Module[
  {normRecords, factorPairs, canonicalPairs, factors},
  normRecords = DeleteCases[Map[Function[record, Module[
      {norm = Lookup[record, "Norm", Missing["NoNorm"]],
       power = Lookup[record, "GaugeNormPower", 1]},
      If[MissingQ[norm] || ! MatchQ[power, _Integer?NonNegative] ||
          power === 0 || TrueQ[Quiet[Together[norm]] === 0], Nothing,
        {norm, power}]]], Select[letterRecords, AssociationQ]], Nothing];
  If[normRecords === {}, Return[1]];
  factorPairs = Flatten[Map[Function[normRecord, Module[{list},
    list = Quiet[FactorList[Expand[Together[First[normRecord]]]]];
    If[! ListQ[list], {},
      ({First[#1], Last[#1] Last[normRecord]} & /@ Select[Rest[list],
        ! FreeQ[First[#1], Alternatives @@ variables] &])]]],
    normRecords], 1];
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

(* The deferred divisor census already supplies a product as distinct base /
   exponent sources.  Factoring their complete product makes Together expand a
   large intermediate before FactorList can recover the same factors.  Stream
   the factor pairs instead: exponents ADD within the forcing product and take
   the MAXIMUM against the independent letter contribution, exactly as
   multiquadraticStripMergeGaugeDenominator does. *)
multiquadraticStripMergeGaugeDenominatorSourceData[sources_List, extra_,
    variables_List] := Module[
  {factorPairs, canonicalize, sameFactorQ, sourceLists, sourcePairs,
   extraPairs, canonicalSources, canonicalExtra, factors, power,
   factorPowers, denominator, degrees},
  If[! AllTrue[sources,
      MatchQ[#1, {_, exponent_Integer /; exponent >= 0}] &], Return[$Failed]];
  factorPairs[expression_, multiplier_Integer] := Module[{list},
    list = Quiet[FactorList[Together[expression]]];
    If[! ListQ[list], Return[$Failed]];
    {First[#1], multiplier Last[#1]} & /@ Rest[list]];
  sourceLists = factorPairs[First[#1], Last[#1]] & /@ sources;
  If[MemberQ[sourceLists, $Failed], Return[$Failed]];
  sourcePairs = Flatten[sourceLists, 1];
  extraPairs = factorPairs[extra, 1];
  If[extraPairs === $Failed, Return[$Failed]];
  sourcePairs = Select[sourcePairs,
    ! FreeQ[First[#1], Alternatives @@ variables] &];
  extraPairs = Select[extraPairs,
    ! FreeQ[First[#1], Alternatives @@ variables] &];
  canonicalize[pairs_List] := DeleteCases[
    {multiquadraticStripCanonicalFactor[First[#1], variables], Last[#1]} & /@
      pairs, {$Failed | 0, _}];
  canonicalSources = canonicalize[sourcePairs];
  canonicalExtra = canonicalize[extraPairs];
  sameFactorQ[left_, right_] := SameQ[left, right] ||
    TrueQ[Together[left - right] === 0];
  factors = DeleteDuplicates[
    Join[If[canonicalSources === {}, {}, canonicalSources[[All, 1]]],
      If[canonicalExtra === {}, {}, canonicalExtra[[All, 1]]]],
    sameFactorQ];
  power[pairs_List, factor_] := Total[Last /@ Select[pairs,
    sameFactorQ[First[#1], factor] &]];
  factorPowers = Table[{factor, Max[power[canonicalSources, factor],
      power[canonicalExtra, factor]]}, {factor, factors}];
  denominator = Times @@
    (First[#1]^Last[#1] & /@ factorPowers);
  degrees = Table[Total[(Last[#1] Exponent[First[#1], variable]) & /@
      factorPowers], {variable, variables}];
  <|"Status" -> "GaugeDenominatorSourceDataV1",
    "GaugeDenominator" -> denominator,
    "GaugeDenominatorDegrees" -> degrees,
    "FactorPowers" -> factorPowers|>
];
multiquadraticStripMergeGaugeDenominatorSourceData[___] := $Failed;

multiquadraticStripMergeGaugeDenominatorSources[sources_List, extra_,
    variables_List] := Module[{data =
      multiquadraticStripMergeGaugeDenominatorSourceData[
        sources, extra, variables]},
  If[AssociationQ[data], data["GaugeDenominator"], $Failed]
];
multiquadraticStripMergeGaugeDenominatorSources[___] := $Failed;

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

multiquadraticStripScreenCompilePolynomialExact[polynomial_,
    allVariables_List] := Module[{expanded, rules, exponents},
  expanded = Quiet[Expand[polynomial]];
  If[! PolynomialQ[expanded, allVariables], Return[$Failed]];
  rules = CoefficientRules[expanded, allVariables];
  If[rules === {},
    Return[<|"Exponents" -> {}, "ExactCoefficients" -> {},
      "MaximumExponents" -> ConstantArray[0, Length[allVariables]]|>]];
  exponents = First /@ rules;
  <|"Exponents" -> Developer`ToPackedArray[exponents],
    "ExactCoefficients" -> Last /@ rules,
    "MaximumExponents" -> Max /@ Transpose[exponents]|>
];
multiquadraticStripScreenCompilePolynomialExact[___] := $Failed;

(* Fast path for an expression which is already an expanded sum of
   monomials.  CoefficientRules calls Expand again and performs a general
   polynomial conversion; on large deferred operands that dominated sparse
   plan construction even though every existing Plus term was already a
   monomial.  Parse that representation directly and merge only genuinely
   duplicate exponent vectors. *)
multiquadraticStripScreenCompileExpandedPolynomialExact[polynomial_,
    allVariables_List] := Module[
  {terms, coefficients, rules, exponents},
  If[! TrueQ[PolynomialQ[polynomial, allVariables]], Return[$Failed]];
  terms = If[Head[polynomial] === Plus, List @@ polynomial, {polynomial}];
  (* Expand each existing additive term independently.  This distributes
     small local factors such as x^n (4 x + y^2), but unlike Expand on the
     whole deferred numerator it cannot form a cross product between the
     numerator's separately compiled top-level factors. *)
  terms = Expand[terms];
  terms = Flatten[If[Head[#1] === Plus, List @@ #1, {#1}] & /@ terms];
  (* Exponent threads over a list of monomials inside the kernel.  Together
     with the all-rational coefficient test and the absence of nested Plus,
     this rejects non-monomial or non-polynomial terms without a scalar
     Wolfram-level parser loop. *)
  If[! FreeQ[terms, _Plus], Return[$Failed]];
  exponents = Transpose[Exponent[terms, #1] & /@ allVariables];
  coefficients = terms /. Thread[allVariables -> 1];
  If[! MatrixQ[exponents,
        IntegerQ[#1] && NonNegative[#1] &] ||
      ! VectorQ[coefficients,
        IntegerQ[#1] || Head[#1] === Rational &], Return[$Failed]];
  rules = Select[Normal[Merge[
      MapThread[Rule, {exponents, coefficients}], Total]],
    Last[#1] =!= 0 &];
  If[rules === {},
    Return[<|"Exponents" -> {}, "ExactCoefficients" -> {},
      "MaximumExponents" -> ConstantArray[0, Length[allVariables]]|>]];
  exponents = First /@ rules;
  <|"Exponents" -> Developer`ToPackedArray[exponents],
    "ExactCoefficients" -> Last /@ rules,
    "MaximumExponents" -> Max /@ Transpose[exponents]|>
];
multiquadraticStripScreenCompileExpandedPolynomialExact[___] := $Failed;

multiquadraticStripScreenReducePolynomial[exact_Association,
    prime_Integer] := Module[{coefficients},
  coefficients = multiquadraticStripModRational[#1, prime] & /@
    Lookup[exact, "ExactCoefficients", {$Failed}];
  If[MemberQ[coefficients, $Failed], Return[$Failed]];
  <|"Exponents" -> exact["Exponents"],
    "Coefficients" -> Developer`ToPackedArray[coefficients],
    "MaximumExponents" -> exact["MaximumExponents"]|>
];
multiquadraticStripScreenReducePolynomial[___] := $Failed;

multiquadraticStripScreenCompilePolynomial[polynomial_, allVariables_List,
    prime_Integer] := multiquadraticStripScreenReducePolynomial[
  multiquadraticStripScreenCompilePolynomialExact[polynomial, allVariables],
  prime];

multiquadraticStripScreenCompileScalarExact[expression_, roots_List,
    rootSymbols_List, variables_List] := Module[
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
  numerator = multiquadraticStripScreenCompilePolynomialExact[
    Numerator[rational], allVariables];
  denominator = multiquadraticStripScreenCompilePolynomialExact[
    Denominator[rational], allVariables];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["ExactCoefficients"] === {}, Return[$Failed]];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "MaximumExponents" -> MapThread[Max,
      {numerator["MaximumExponents"], denominator["MaximumExponents"]}]|>
];
multiquadraticStripScreenCompileScalarExact[___] := $Failed;

(* Deferred operands already carry an exact canonical quotient.  Recombining
   its numerator factors with Together/Expand before finite-field evaluation
   can manufacture a huge cross product which is absent from the source DAG.
   Compile the existing top-level product factor by factor instead; evaluation
   multiplies the factor values modulo p, so this is exactly the same rational
   function without materializing that cross product.  This representation is
   deliberately split-value-only; derivative screens keep the established
   flat rational compiler. *)
multiquadraticStripScreenCompileFactoredScalarExact[numerator_,
    denominatorFactors_List, roots_List, rootSymbols_List,
    variables_List] := Module[
  {allVariables = Join[variables, rootSymbols], splitNumerator,
   normalizeFactor, compileFactor, numeratorData, denominatorData,
   maxima},
  splitNumerator = If[Head[numerator] === Times, List @@ numerator,
    {numerator}];
  normalizeFactor[factor_, inheritedPower_Integer : 1] := Which[
    MatchQ[factor, Power[_, exponent_Integer?Positive]],
      {First[factor], inheritedPower Last[factor]},
    True, {factor, inheritedPower}];
  compileFactor[{factor_, power_Integer?Positive}] := Module[
    {replaced, compiled},
    replaced = If[roots === {}, factor,
      Quiet[transportChartApplyRootBranches[factor, roots, rootSymbols]]];
    If[replaced === $Failed ||
        ! FreeQ[replaced,
          Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
        ! FreeQ[replaced, DirectedInfinity | Indeterminate],
      Return[$Failed]];
    compiled = multiquadraticStripScreenCompileExpandedPolynomialExact[
      replaced, allVariables];
    If[compiled === $Failed,
      compiled = multiquadraticStripScreenCompilePolynomialExact[
        replaced, allVariables]];
    If[compiled === $Failed, $Failed,
      <|"Polynomial" -> compiled, "Power" -> power|>]
  ];
  numeratorData = compileFactor /@
    (normalizeFactor /@ splitNumerator);
  denominatorData = compileFactor /@
    If[denominatorFactors === {}, {{1, 1}},
      normalizeFactor[First[#1], Last[#1]] & /@ denominatorFactors];
  If[MemberQ[numeratorData, $Failed] ||
      MemberQ[denominatorData, $Failed] ||
      AnyTrue[denominatorData,
        Lookup[#1["Polynomial"], "ExactCoefficients", {}] === {} &],
    Return[$Failed]];
  maxima = Lookup[Join[numeratorData, denominatorData][[All, "Polynomial"]],
    "MaximumExponents"];
  <|"Representation" -> "SplitValueFactoredRationalV1",
    "NumeratorFactors" -> numeratorData,
    "DenominatorFactors" -> denominatorData,
    "MaximumExponents" -> If[maxima === {},
      ConstantArray[0, Length[allVariables]], Max /@ Transpose[maxima]]|>
];
multiquadraticStripScreenCompileFactoredScalarExact[___] := $Failed;

multiquadraticStripScreenReduceScalar[exact_Association,
    prime_Integer] := Module[
  {numerator, denominator, reduceFactor, numeratorFactors,
   denominatorFactors},
  If[Lookup[exact, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    reduceFactor[factor_Association] := Module[{polynomial},
      polynomial = multiquadraticStripScreenReducePolynomial[
        Lookup[factor, "Polynomial", <||>], prime];
      If[polynomial === $Failed, $Failed,
        <|"Polynomial" -> polynomial,
          "Power" -> Lookup[factor, "Power", $Failed]|>]];
    numeratorFactors = reduceFactor /@
      Lookup[exact, "NumeratorFactors", {}];
    denominatorFactors = reduceFactor /@
      Lookup[exact, "DenominatorFactors", {}];
    If[MemberQ[numeratorFactors, $Failed] ||
        MemberQ[denominatorFactors, $Failed] ||
        denominatorFactors === {} ||
        ! AllTrue[Join[numeratorFactors, denominatorFactors],
          IntegerQ[#1["Power"]] && #1["Power"] > 0 &],
      Return[$Failed]];
    Return[<|"Representation" -> "SplitValueFactoredRationalV1",
      "NumeratorFactors" -> numeratorFactors,
      "DenominatorFactors" -> denominatorFactors,
      "MaximumExponents" -> exact["MaximumExponents"]|>]];
  numerator = multiquadraticStripScreenReducePolynomial[
    Lookup[exact, "Numerator", <||>], prime];
  denominator = multiquadraticStripScreenReducePolynomial[
    Lookup[exact, "Denominator", <||>], prime];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "MaximumExponents" -> exact["MaximumExponents"]|>
];
multiquadraticStripScreenReduceScalar[___] := $Failed;

multiquadraticStripScreenCompileScalar[expression_, roots_List,
    rootSymbols_List, variables_List, prime_Integer] :=
  multiquadraticStripScreenReduceScalar[
    multiquadraticStripScreenCompileScalarExact[expression, roots,
      rootSymbols, variables], prime];

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

(* Split-branch coefficient images need only the scalar value.  Reusing the
   screen derivative evaluator here would form one extra packed dot product
   per compiled variable for both numerator and denominator, even though all
   of those derivatives are discarded. *)
multiquadraticStripScreenEvaluatePolynomialValue[compiled_Association,
    powerTables_List, prime_Integer] := Module[
  {exponents = compiled["Exponents"], coefficients = compiled["Coefficients"],
   monomials},
  If[coefficients === {}, Return[0]];
  monomials = Fold[
    Function[{accumulated, index},
      Mod[accumulated powerTables[[index]][[exponents[[All, index]] + 1]],
        prime]],
    ConstantArray[1, Length[coefficients]], Range[Length[powerTables]]];
  Mod[coefficients . monomials, prime]
];

multiquadraticStripScreenEvaluateRationalValue[compiled_Association,
    powerTables_List, prime_Integer] := Module[
  {numerator, denominator, evaluateFactor},
  If[Lookup[compiled, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    evaluateFactor[factor_Association] := PowerMod[
      multiquadraticStripScreenEvaluatePolynomialValue[
        factor["Polynomial"], powerTables, prime], factor["Power"], prime];
    numerator = Fold[Mod[#1 #2, prime] &, 1,
      evaluateFactor /@ compiled["NumeratorFactors"]];
    denominator = Fold[Mod[#1 #2, prime] &, 1,
      evaluateFactor /@ compiled["DenominatorFactors"]];
    If[denominator === 0, Return[$Failed]];
    Return[Mod[numerator PowerMod[denominator, -1, prime], prime]]];
  numerator = multiquadraticStripScreenEvaluatePolynomialValue[
    compiled["Numerator"], powerTables, prime];
  denominator = multiquadraticStripScreenEvaluatePolynomialValue[
    compiled["Denominator"], powerTables, prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
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
$multiquadraticStripSampleMaximumBytes = 4. 10^9;

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

(* The production sampler used to discover this limit only after allocation.
   It retains per-point rows and then joins them into the final packed matrix,
   so two dense copies are a hard lower bound on peak memory.  Refuse before
   compiling a provider plan or drawing one point; a smaller support or a
   fibre solver may proceed, but the current dense algorithm may not consume
   the machine merely to demonstrate that it is too large. *)
multiquadraticStripSampleSizeEstimate[pointCount_Integer,
    equationsPerPoint_Integer, normalizationCount_Integer,
    unknownCount_Integer] := Module[{rows},
  rows = pointCount equationsPerPoint + normalizationCount;
  <|"Points" -> pointCount, "Rows" -> rows, "Columns" -> unknownCount,
    "PackedMatrixBytes" -> 8 rows unknownCount,
    "PeakPackedBytesLowerBound" -> 16 rows unknownCount|>
];
multiquadraticStripSampleSizeEstimate[___] := $Failed;

multiquadraticStripSampleAdmissionRefusal[estimate_Association,
    maximumBytes_] := If[
  NumericQ[maximumBytes] &&
      estimate["PeakPackedBytesLowerBound"] > maximumBytes,
  multiquadraticStripFailure["SampleMatrixResourceLimit", <|
    "Reason" -> "DenseMatrixByteCeilingExceeded",
    "SizeEstimate" -> estimate,
    "MaximumMatrixBytes" -> maximumBytes,
    "Resumable" -> True|>],
  None
];
multiquadraticStripSampleAdmissionRefusal[___] :=
  multiquadraticStripFailure["InvalidSampleMatrixAdmission"];

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
  "ForcingProvider" -> Automatic,
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
   rootSymbols, compileScalar, deltaCompiled,
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
   compileStatisticsBefore, forcingProvider, nativeForcingQ,
   sameFrameNativeForcingQ, chartNativeForcingQ, preflight, chartPreflight,
   nativeForcing, bbarChannels, bbarDerivativeChannels, bbarCurlChannels,
   forcingExteriorDerivative, gradeMonomials, composeChannels},
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
  forcingProvider = OptionValue["ForcingProvider"];
  sameFrameNativeForcingQ = AssociationQ[forcingProvider] &&
    multiquadraticStripProviderValidQ[forcingProvider] &&
    Lookup[forcingProvider, "RootCount", None] === rank &&
    Lookup[forcingProvider, "Variables", None] === variables &&
    Lookup[forcingProvider, "Regulator", None] === epsilon &&
    Lookup[forcingProvider, "Dimensions", None] === {upper, lower} &&
    AssociationQ[Lookup[forcingProvider, "DeferredPreparation", None]];
  chartNativeForcingQ = AssociationQ[forcingProvider] &&
    multiquadraticStripChartForcingProviderValidQ[forcingProvider] &&
    Lookup[forcingProvider, "RootCount", None] === rank &&
    Lookup[forcingProvider, "Variables", None] === variables &&
    Lookup[forcingProvider, "Regulator", None] === epsilon &&
    Lookup[forcingProvider, "Dimensions", None] === {upper, lower} &&
    Lookup[forcingProvider, "Roots", None] === roots;
  nativeForcingQ = sameFrameNativeForcingQ || chartNativeForcingQ;
  If[forcingProvider =!= Automatic && ! nativeForcingQ,
    Return[multiquadraticStripFailure["InvalidIntegrabilityForcingProvider"]]];
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
  rootSymbols = Table[Unique["multiquadraticRoot$"], {rank}];
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
    bCompiled = If[expired || nativeForcingQ, {},
      Map[compileScalar, bbar, {3}]];
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
      If[nativeForcingQ,
        If[chartNativeForcingQ,
          chartPreflight = multiquadraticStripChartForcingPreflight[
            forcingProvider, regulatorValue, prime, point, rootValues];
          If[Lookup[chartPreflight, "Status", None] =!=
              "MultiquadraticChartForcingPreflightV1",
            rejected["NativeForcingPreflight"] =
              Lookup[rejected, "NativeForcingPreflight", 0] + 1;
            Continue[]];
          nativeForcing =
            multiquadraticStripNativeDeferredChartEvaluateBatch[
              forcingProvider, {chartPreflight}];
          If[Lookup[nativeForcing, "Status", None] =!=
                "MultiquadraticNativeDeferredChartBatchV1" ||
              Length[Lookup[nativeForcing, "BBarBatch", {}]] =!= 1 ||
              Length[Lookup[nativeForcing, "BBarCurlBatch", {}]] =!= 1,
            rejected["NativeForcingEvaluation"] =
              Lookup[rejected, "NativeForcingEvaluation", 0] + 1;
            Continue[]];
          bbarChannels = First[nativeForcing["BBarBatch"]];
          bbarCurlChannels = First[nativeForcing["BBarCurlBatch"]],
          preflight = multiquadraticStripProviderPreflight[
            forcingProvider, regulatorValue, prime, point];
          If[Lookup[preflight, "Status", None] =!=
              "MultiquadraticProviderPreflightV1" ||
              ! TrueQ[Lookup[preflight, "SplitPointQ", False]],
            rejected["NativeForcingPreflight"] =
              Lookup[rejected, "NativeForcingPreflight", 0] + 1;
            Continue[]];
          rootValues = preflight["RootValues"];
          nativeForcing = multiquadraticStripNativeDeferredEvaluateBatch[
            forcingProvider, {preflight}, "Derivatives" -> True];
          If[Lookup[nativeForcing, "Status", None] =!=
                "MultiquadraticNativeDeferredDerivativeBatchV1" ||
              Length[Lookup[nativeForcing, "BBarBatch", {}]] =!= 1 ||
              Take[Dimensions[Lookup[nativeForcing,
                  "BBarDerivativeBatch", {}]], UpTo[2]] =!= {2, 1},
            rejected["NativeForcingEvaluation"] =
              Lookup[rejected, "NativeForcingEvaluation", 0] + 1;
            Continue[]];
          bbarChannels = First[nativeForcing["BBarBatch"]];
          bbarDerivativeChannels =
            nativeForcing["BBarDerivativeBatch"][[All, 1]];
          bbarCurlChannels = Mod[
            bbarDerivativeChannels[[2, 1]] -
              bbarDerivativeChannels[[1, 2]], prime]]];
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
        gradeMonomials = Table[Product[
          If[BitGet[grade - 1, a - 1] === 1, values[[2 + a]], 1],
          {a, rank}], {grade, 2^rank}];
        composeChannels[channelTensor_] := Map[
          Mod[#1 . gradeMonomials, prime] &, channelTensor, {2}];
        If[Catch[
            ex = matrixValue[eCompiled[[1]]]; ey = matrixValue[eCompiled[[2]]];
            cx = matrixValue[cCompiled[[1]]]; cy = matrixValue[cCompiled[[2]]];
            If[nativeForcingQ,
              bx = composeChannels[bbarChannels[[1]]];
              by = composeChannels[bbarChannels[[2]]],
              bx = matrixValue[bCompiled[[1]]];
              by = matrixValue[bCompiled[[2]]]];
            dyex = matrixDerivative[eCompiled[[1]], 2];
            dxey = matrixDerivative[eCompiled[[2]], 1];
            dycx = matrixDerivative[cCompiled[[1]], 2];
            dxcy = matrixDerivative[cCompiled[[2]], 1];
            If[nativeForcingQ,
              forcingExteriorDerivative = composeChannels[bbarCurlChannels],
              dybx = matrixDerivative[bCompiled[[1]], 2];
              dxby = matrixDerivative[bCompiled[[2]], 1];
              forcingExteriorDerivative = Mod[dybx - dxby, prime]];
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
        forcingCurl = Mod[forcingExteriorDerivative +
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
(* ------------------------------------------------------------------ *)
(* The screen-evidence classifier (round-3 A1, Codex instruction).      *)
(*                                                                      *)
(* ONE side-effect-free classifier decides every screen verdict, for    *)
(* the residue-only screen and the full-gauge screen alike.  Its input  *)
(* is EVIDENCE, not a solver object:                                    *)
(*   ConfiguredRequired / ConfiguredUsable -- the configured images;    *)
(*   FreshRequested / FreshGenerated / FreshUsable -- the fresh draw;   *)
(*   Defects -- every USABLE defect, configured then fresh;             *)
(*   UnusableStatuses -- statuses of images that did not measure;       *)
(*   ConfirmationEnabled -- whether a negative may be confirmed at all. *)
(*                                                                      *)
(* The one monotonicity rule: adding evidence may confirm or weaken a   *)
(* verdict, but failed or contrary fresh evidence is NEVER discarded in *)
(* favour of an earlier two-image result.  "FreshRequested" -> 0 is     *)
(* deliberately valid: a caller that explicitly asks for zero fresh     *)
(* images accepts the configured-image evidence as the whole contract.  *)
(* ------------------------------------------------------------------ *)

multiquadraticStripScreenEvidenceConfirmedQ[ev_Association] :=
  TrueQ[Lookup[ev, "ConfirmationEnabled", False]] &&
  Lookup[ev, "ConfiguredUsable", 0] >= Lookup[ev, "ConfiguredRequired", 2] &&
  Lookup[ev, "FreshGenerated", -1] === Lookup[ev, "FreshRequested", 0] &&
  Lookup[ev, "FreshUsable", -1] === Lookup[ev, "FreshRequested", 0] &&
  Length[Lookup[ev, "Defects", {}]] ===
    Lookup[ev, "ConfiguredUsable", 0] + Lookup[ev, "FreshUsable", 0] &&
  Lookup[ev, "Defects", {}] =!= {} &&
  AllTrue[Lookup[ev, "Defects", {None}], IntegerQ[#1] && #1 > 0 &];

multiquadraticStripScreenEvidenceClassify[ev_Association] := Module[
  {defects = Lookup[ev, "Defects", {}],
   unusable = Lookup[ev, "UnusableStatuses", {}], allPositive},
  allPositive = defects =!= {} &&
    AllTrue[defects, IntegerQ[#1] && #1 > 0 &];
  Which[
    (* a usable zero defect is SAMPLED consistency: that image exhibits
       a solution of its own specialized system.  It wins over every
       positive defect (monotonicity), but it is not a claim about the
       generic field. *)
    defects =!= {} && AllTrue[defects, #1 === 0 &],
      <|"Verdict" -> "SampledConsistent", "AllZero" -> True|>,
    AnyTrue[defects, #1 === 0 &],
      <|"Verdict" -> "SampledConsistent", "AllZero" -> False,
        "Reason" -> "MixedDefectEvidence"|>,
    multiquadraticStripScreenEvidenceConfirmedQ[ev],
      <|"Verdict" -> "ConfirmedObstruction"|>,
    allPositive && unusable =!= {},
      <|"Verdict" -> "Inconclusive", "Reason" -> "UnusableFreshImage"|>,
    allPositive && Lookup[ev, "ConfiguredUsable", 0] >=
        Lookup[ev, "ConfiguredRequired", 2],
      (* every usable image carries a defect, but the requested fresh
         evidence was not fully obtained: the verdict may not harden *)
      <|"Verdict" -> "Inconclusive", "Reason" -> "FreshEvidenceIncomplete"|>,
    allPositive,
      <|"Verdict" -> "Unconfirmed"|>,
    True,
      <|"Verdict" -> "Inconclusive", "Reason" -> "InsufficientEvidence"|>]
];
multiquadraticStripScreenEvidenceClassify[___] :=
  multiquadraticStripFailure["InvalidScreenEvidence"];

(* the predicate a DRIVER must recheck before returning any negative
   contract: the status name alone is not the authority, the evidence
   record is *)
multiquadraticStripConfirmedObstructionEvidenceQ[rec_Association] :=
  Module[{ev = Lookup[rec, "EvidenceRecord", <||>]},
    AssociationQ[ev] && multiquadraticStripScreenEvidenceConfirmedQ[ev]];
multiquadraticStripConfirmedObstructionEvidenceQ[___] := False;

(* Fresh random good images for the RESIDUE-ONLY screen.  Same admission
   as the gauge generator -- unused admissible prime, regulator value the
   forcing sampler accepts -- but NO gauge-denominator condition, because
   there is no gauge ansatz here; instead the root squares and letter
   one-forms must remain evaluable and nondegenerate at the value. *)
multiquadraticStripFreshResidueScreenImages[record_Association, roots_List,
    letterRecords_List, count_Integer, seed_Integer, excludePrimes_List,
    excludeValues_List] := Module[
  {variables, epsilon, strip, pool, sampled, values, primes, candidate,
   rejectedPrimes = {}, rejectedValues, attempts, evaluableQ, squares,
   oneForms},
  If[count <= 0, Return[<|"Status" -> "NoFreshImagesRequested",
    "Images" -> {}, "RejectedPrimes" -> {}, "RejectedValues" -> {}|>]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidRecordForFreshResidueImages"]]];
  squares = Lookup[roots, "RootSquare", {}];
  oneForms = Lookup[letterRecords, "OneForm", {}];
  evaluableQ[value_] := Module[{image = Quiet[Check[
      Together[{squares, oneForms} /. epsilon -> value], $Failed]]},
    image =!= $Failed &&
      FreeQ[image, DirectedInfinity | Indeterminate | ComplexInfinity] &&
      ! AnyTrue[Flatten[{image[[1]]}], TrueQ[Together[#1] === 0] &]];
  pool = DeleteCases[
    BlockRandom[RandomSample[$multiquadraticStripRegulatorSamplePool],
      RandomSeeding -> seed],
    Alternatives @@ excludeValues];
  pool = Select[pool, evaluableQ];
  sampled = multiquadraticStripRegulatorSampleValues[strip[[3]], variables,
    epsilon, count, pool];
  values = Lookup[sampled, "Values", {}];
  rejectedValues = Lookup[sampled, "RejectedValues", {}];
  primes = {}; attempts = 0;
  BlockRandom[
    While[Length[primes] < Length[values] && attempts < 4096,
      attempts++;
      candidate = NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]];
      If[Mod[candidate, 4] === 3 && candidate < 2^31 &&
          ! MemberQ[excludePrimes, candidate] && ! MemberQ[primes, candidate],
        AppendTo[primes, candidate],
        AppendTo[rejectedPrimes, candidate]]],
    RandomSeeding -> seed + 104729];
  If[Length[primes] < Length[values], values = Take[values, Length[primes]]];
  <|"Status" -> If[Length[values] >= count, "FreshScreenImages",
      "InsufficientFreshScreenImages"],
    "Images" -> Transpose[{Take[primes, Length[values]], values}],
    "Requested" -> count, "Seed" -> seed,
    "RejectedValues" -> rejectedValues,
    "RejectedPrimeCount" -> Length[rejectedPrimes]|>
];
multiquadraticStripFreshResidueScreenImages[___] :=
  multiquadraticStripFailure["InvalidFreshResidueImageArguments"];

Options[multiquadraticStripIntegrabilityScreenImages] = Join[
  Options[multiquadraticStripIntegrabilityScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True,
  "FreshImageCount" -> Automatic,
  "FreshImageSeed" -> Automatic
}];

multiquadraticStripIntegrabilityScreenImages[record_Association, roots_List,
    letterRecords_List, opts : OptionsPattern[]] := Module[
  {gate, images, firstPrime, firstRegulator, results = {}, screenOptions,
   result, defects, status, startTime = AbsoluteTime[], configuredCount,
   freshCount, freshSeed, freshRequest, freshImages = {},
   freshResults = {}, evidence, verdict, allImages},
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
    (* the fast path: a zero-defect image ends the screen and permits
       the full route.  It is SAMPLED consistency -- a solution of that
       image's own specialized system -- not proof of generic
       solvability; the classifier below records it as such. *)
    If[Lookup[result, "Defect", 1] === 0, Break[]];
    If[! TrueQ[OptionValue["ConfirmObstruction"]], Break[]],
    {k, Length[images]}];
  configuredCount = Length[results];
  (* ---- the fresh-image confirmation (round-3 A1): a defect that
     survives every configured image is re-tested at fresh random good
     images through the same evidence classifier as the full-gauge
     screen.  "FreshImageCount" -> 0 accepts the configured evidence. *)
  freshCount = Replace[OptionValue["FreshImageCount"],
    Automatic :> $multiquadraticStripDefaultFreshImageCount];
  freshSeed = Replace[OptionValue["FreshImageSeed"],
    Automatic :> Replace[OptionValue["RandomSeed"], Automatic -> 20260826]];
  If[! IntegerQ[freshSeed], freshSeed = 20260826];
  freshRequest = <|"Status" -> "FreshImagesNotRun"|>;
  If[freshCount > 0 && TrueQ[OptionValue["ConfirmObstruction"]] &&
      configuredCount >= 2 &&
      AllTrue[results, Lookup[#1, "Status", None] ===
        "AlphabetIntegrabilityObstruction" &] &&
      AllTrue[results, IntegerQ[Lookup[#1, "Defect", None]] &&
        Lookup[#1, "Defect", 0] > 0 &],
    freshRequest = multiquadraticStripFreshResidueScreenImages[record, roots,
      letterRecords, freshCount, freshSeed, images[[All, 1]],
      images[[All, 2]]];
    freshImages = Lookup[freshRequest, "Images", {}];
    If[! MatchQ[freshImages, {{_Integer, _Integer | _Rational} ...}],
      freshImages = {}];
    Do[
      result = multiquadraticStripIntegrabilityScreen[record, roots,
        letterRecords, "Prime" -> freshImages[[k, 1]],
        "RegulatorValue" -> freshImages[[k, 2]],
        "RandomSeed" -> freshSeed + 15485863 k,
        Sequence @@ screenOptions];
      If[! MemberQ[{"AlphabetIntegrabilityObstruction",
          "AlphabetIntegrabilityConsistent"}, Lookup[result, "Status", None]],
        freshRequest = Join[freshRequest,
          <|"UnusableImage" -> freshImages[[k]],
            "UnusableImageStatus" -> Lookup[result, "Status", None]|>];
        Break[]];
      AppendTo[freshResults, result];
      AppendTo[results, result];
      If[Lookup[result, "Defect", 1] === 0, Break[]],
      {k, Length[freshImages]}]];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  evidence = <|
    "ConfiguredRequired" -> 2,
    "ConfiguredUsable" -> Count[Take[results, UpTo[configuredCount]],
      r_ /; MemberQ[{"AlphabetIntegrabilityObstruction",
        "AlphabetIntegrabilityConsistent"}, Lookup[r, "Status", None]]],
    "FreshRequested" -> If[Lookup[freshRequest, "Status", None] ===
        "FreshImagesNotRun" && freshCount > 0 &&
        ! AllTrue[Take[results, UpTo[configuredCount]],
          IntegerQ[Lookup[#1, "Defect", None]] &&
            Lookup[#1, "Defect", 0] > 0 &], 0, freshCount],
    "FreshGenerated" -> Length[Lookup[freshRequest, "Images", {}]],
    "FreshUsable" -> Length[freshResults],
    "Defects" -> Select[defects, IntegerQ],
    "UnusableStatuses" -> DeleteMissing[
      {Lookup[freshRequest, "UnusableImageStatus", Missing["None"]]}],
    "ConfirmationEnabled" -> TrueQ[OptionValue["ConfirmObstruction"]]|>;
  verdict = multiquadraticStripScreenEvidenceClassify[evidence];
  status = Which[
    ! AllTrue[Take[results, UpTo[configuredCount]],
        MemberQ[{"AlphabetIntegrabilityObstruction",
          "AlphabetIntegrabilityConsistent"}, Lookup[#1, "Status", None]] &],
      (* a not-applicable / budget-exhausted configured image is not a
         verdict *)
      Lookup[Last[Take[results, UpTo[configuredCount]]], "Status",
        "IntegrabilityScreenNotApplicable"],
    Lookup[verdict, "Verdict", None] === "SampledConsistent",
      "AlphabetIntegrabilityConsistent",
    Lookup[verdict, "Verdict", None] === "ConfirmedObstruction",
      "AlphabetIntegrabilityObstruction",
    Lookup[verdict, "Verdict", None] === "Unconfirmed",
      "AlphabetIntegrabilityObstructionUnconfirmed",
    True, "IntegrabilityScreenInconclusive"];
  allImages = Join[Take[images, UpTo[configuredCount]],
    Take[freshImages, UpTo[Length[freshResults]]]];
  Join[
    (* the deciding image's own payload travels on, so witnesses,
       scored letters and phase timings are not lost by the wrapper *)
    KeyDrop[Last[results], {"Status", "Seconds"}],
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Method" -> "ResidueOnlyIntegrability",
      "Confirmed" -> (status === "AlphabetIntegrabilityObstruction" &&
        multiquadraticStripScreenEvidenceConfirmedQ[evidence]),
      "Reason" -> Lookup[verdict, "Reason", Missing["NoReason"]],
      (* SAMPLED consistency: a zero-defect image exhibits a solution of
         ITS OWN specialized system.  The positive-defect images beside
         it are recorded as evidence, never acted on; the generic
         statement is left to the full route. *)
      "SampledConsistency" ->
        (status === "AlphabetIntegrabilityConsistent"),
      "ExceptionalRegulatorImages" ->
        If[status === "AlphabetIntegrabilityConsistent",
          Pick[Take[allImages, UpTo[Length[defects]]],
            Map[IntegerQ[#1] && #1 > 0 &, defects]], {}],
      "ImageCount" -> Length[results], "Defects" -> defects,
      "Images" -> allImages,
      "ImageResults" -> results,
      "ConfiguredImageCount" -> configuredCount,
      "FreshImageCount" -> Length[freshResults],
      "FreshImageRequest" -> KeyTake[freshRequest,
        {"Status", "Requested", "Seed", "RejectedValues",
         "RejectedPrimeCount", "UnusableImage", "UnusableImageStatus"}],
      "EvidenceRecord" -> Join[evidence,
        <|"Verdict" -> Lookup[verdict, "Verdict", None]|>],
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
  (* A near-square point set can interpolate a false section in a
     high-nullity system.  Eight surplus point blocks leave a real
     held-out row margin while adding much less work than a symbolic
     compile or an incorrectly adopted support rung. *)
  "ExtraRowPoints" -> 8,
  "CandidateOneForms" -> {},
  "CandidateSubsets" -> Automatic,
  "LeftNullSpace" -> Automatic,
  "Deadline" -> Infinity,
  "MaximumUnknowns" -> Automatic,
  "MaximumBytes" -> Automatic,
  (* see the note at multiquadraticStripIntegrabilityScreen *)
  "CompileCacheBytes" -> Automatic
};

(* A large production screen with no candidate columns needs only the
   affine-consistency verdict.  Paying twice for Wolfram MatrixRank and then
   for a full left null space is useful for witness-guided letter discovery,
   but it is pathological for a tens-of-millions-entry gate.  Above this
   threshold reuse the authenticated CFFR1 affine backend already used by the
   real solver.  Small screens and every explicit witness/candidate request
   retain the historical Wolfram route and its left witness. *)
$multiquadraticStripGaugeScreenNativeMinimumEntries = 10000000;

multiquadraticStripGaugeScreen[ansatz_Association, opts : OptionsPattern[]] :=
  Module[
  {gate, record, variables, epsilon, strip, e, c, bbar, roots, oneForms,
   gaugeDenominator, support, dimensions, upper, lower, rank, gradeCount,
   supportCount, letterCount, gaugeUnknownCount, residueUnknownCount,
   unknownCount, candidateForms, candidateCount, candidateWidth, prime,
   regulatorValue, epsilonMod, pointCount, maximumAttempts, randomSeed,
   equationsPerPoint, rootSymbols, compileScalar,
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
   lettersCompiled = 0, letterIndex, candidateIndex, compileCacheBytes,
   nativeRankQ = False, rankBackend = "Wolfram", rankThreads = 1,
   rankEvidence = <||>, defectEvidence = None},
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
  rootSymbols = Table[Unique["multiquadraticRoot$"], {rank}];
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
    nativeRankQ = candidateCount === 0 &&
      OptionValue["LeftNullSpace"] =!= True &&
      Times @@ Dimensions[matrix] >=
        $multiquadraticStripGaugeScreenNativeMinimumEntries &&
      StringQ[finiteFieldStripCFFRBinary[]] &&
      FileExistsQ[finiteFieldStripCFFRBinary[]];
    If[nativeRankQ,
      rankThreads = taskBrokerNativeThreadLimit[8];
      rankEvidence = multiquadraticStripAffineConsistencyEvidence[
        matrix, rightVector, prime, gaugeUnknownCount,
        residueUnknownCount, "FLINTAffineRREF", rankThreads, 0];
      Switch[Lookup[rankEvidence, "Status", None],
        "ProviderSupportImageConsistent",
          rankA = rankEvidence["Rank"];
          rankAugmented = rankEvidence["AugmentedRank"];
          defect = 0;
          rankBackend = "FLINTAffineRREF",
        "ProviderSupportImageInconsistent",
          rankA = Lookup[rankEvidence, "Rank",
            Missing["NotComputedForNativeInconsistency"]];
          rankAugmented = Lookup[rankEvidence, "AugmentedRank",
            Missing["NotComputedForNativeInconsistency"]];
          defect = Lookup[rankEvidence, "Defect", 1];
          rankBackend = "FLINTAffineRREF",
        _, nativeRankQ = False]];
    If[! TrueQ[nativeRankQ],
      rankA = MatrixRank[matrix, Modulus -> prime];
      rankAugmented = MatrixRank[MapThread[Append, {matrix, rightVector}],
        Modulus -> prime];
      defect = rankAugmented - rankA;
      rankBackend = "Wolfram"];
    ]];
  If[TrueQ[nativeRankQ],
    defectEvidence = KeyTake[rankEvidence, {"Status", "DefectEvidence",
      "InconsistentVerdict", "PlanDiscoveryBackendRequested",
      "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads"}];
    (* Drop a consistent native solution immediately: its particular/null
       basis has served only to authenticate the rank verdict and must not
       remain live through the later screen bookkeeping. *)
    rankEvidence = <||>];
  wanted = If[TrueQ[nativeRankQ], False,
    Replace[OptionValue["LeftNullSpace"],
      Automatic :> (defect > 0 || candidateCount > 0)]];
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
    "Nullity" -> If[IntegerQ[rankA], unknownCount - rankA,
      Missing["NotComputedForNativeInconsistency"]],
    "LeftNullity" -> If[IntegerQ[rankA], Length[matrix] - rankA,
      Missing["NotComputedForNativeInconsistency"]],
    "MatrixDimensions" -> Dimensions[matrix],
    "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "LetterCount" -> letterCount, "Prime" -> prime,
    "RegulatorValue" -> regulatorValue, "PointCount" -> accepted,
    "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
    "EquationsPerPoint" -> equationsPerPoint,
    "Witness" -> witness, "DefectEvidence" -> defectEvidence,
    "RankBackend" -> rankBackend, "RankBackendThreads" -> rankThreads,
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

(* ---- FRESH RANDOM GOOD IMAGES (2026-08-26, round-2 item 3, Codex
   review 1.5) --------------------------------------------------------

   Two FIXED primes do not make modular inconsistency one-sided.  Codex's
   counterexample: with the two configured primes p1, p2 and P = p1 p2,
   the exact scalar equation P g = 1 is solvable over Q (g = 1/P) and
   inconsistent modulo either prime.  Physical input rarely looks like
   that, but the wording has to survive the case that does.

   So the two configured images stay as the CHEAP FIRST PASS -- unchanged
   cost, unchanged behaviour when they disagree -- and a defect that
   survives them is then re-tested at fresh RANDOM good images drawn per
   call.  An image is GOOD when its prime is an admissible screen prime
   (p = 3 mod 4, 3 < p < 2^31) that no earlier image used, and its
   regulator value is one at which the forcing is regular and still
   kinematics-dependent, and at which the ansatz's own gauge denominator
   does not collapse to a constant or to zero -- a singular denominator
   makes the affine system a different system, and its defect would say
   nothing about the ansatz.

   The regulator values are drawn from the same pool the alphabet
   sampler uses, filtered by exactly the acceptance
   multiquadraticStripRegulatorSampleValues applies, so a value this
   generator returns is a value the rest of the engine calls good. *)
multiquadraticStripFreshScreenImages[ansatz_Association, count_Integer,
    seed_Integer, excludePrimes_List, excludeValues_List] := Module[
  {record, variables, epsilon, strip, gaugeDenominator, pool, sampled,
   values, primes, candidate, rejectedPrimes = {}, rejectedValues, attempts,
   denominatorOK},
  If[count <= 0, Return[<|"Status" -> "NoFreshImagesRequested",
    "Images" -> {}, "RejectedPrimes" -> {}, "RejectedValues" -> {}|>]];
  record = Lookup[ansatz, "Record", <||>];
  variables = Lookup[ansatz, "Variables", Lookup[record, "Variables", $Failed]];
  epsilon = Lookup[ansatz, "Regulator", Lookup[record, "Regulator", $Failed]];
  strip = Lookup[ansatz, "Strip", Lookup[record, "Strip", $Failed]];
  gaugeDenominator = Lookup[ansatz, "GaugeDenominator", 1];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidGaugeAnsatzForFreshImages"]]];
  (* the regulator values: the alphabet sampler's own acceptance, plus
     the ansatz-specific denominator test *)
  pool = DeleteCases[
    BlockRandom[RandomSample[$multiquadraticStripRegulatorSamplePool],
      RandomSeeding -> seed],
    Alternatives @@ excludeValues];
  denominatorOK[value_] := Module[{image = Quiet[Check[
      Together[gaugeDenominator /. epsilon -> value], $Failed]]},
    image =!= $Failed && FreeQ[image, DirectedInfinity | Indeterminate] &&
      ! TrueQ[Together[image] === 0]];
  pool = Select[pool, denominatorOK];
  sampled = multiquadraticStripRegulatorSampleValues[strip[[3]], variables,
    epsilon, count, pool];
  values = Lookup[sampled, "Values", {}];
  rejectedValues = Lookup[sampled, "RejectedValues", {}];
  (* the primes: random admissible screen primes below 2^31, none reused *)
  primes = {}; attempts = 0;
  BlockRandom[
    While[Length[primes] < Length[values] && attempts < 4096,
      attempts++;
      candidate = NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]];
      If[Mod[candidate, 4] === 3 && candidate < 2^31 &&
          ! MemberQ[excludePrimes, candidate] && ! MemberQ[primes, candidate],
        AppendTo[primes, candidate],
        AppendTo[rejectedPrimes, candidate]]],
    RandomSeeding -> seed + 104729];
  If[Length[primes] < Length[values], values = Take[values, Length[primes]]];
  <|"Status" -> If[Length[values] >= count, "FreshScreenImages",
      "InsufficientFreshScreenImages"],
    "Images" -> Transpose[{Take[primes, Length[values]], values}],
    "Requested" -> count, "Seed" -> seed,
    "RejectedValues" -> rejectedValues,
    "RejectedPrimeCount" -> Length[rejectedPrimes]|>
];
multiquadraticStripFreshScreenImages[___] :=
  multiquadraticStripFailure["InvalidFreshScreenImageArguments"];

(* Two independent images.  As a PRODUCTION GATE the second image is run
   only when the first reports a defect -- a defect at one image can be a
   bad image, and a consistent image does not gate anything, so it is not
   made more consistent by a second one.  As a DISCOVERY instrument the
   opposite is wanted: "the defect drops to 0" is only accepted at TWO
   images, so "ConfirmConsistency" -> True runs every image regardless.

   A defect that survives BOTH configured images is then re-tested at
   "FreshImageCount" fresh random good images (round-2 item 3): the
   verdict is an obstruction only when every image run -- configured and
   fresh -- carries a defect, and the record carries the total image
   count so a consumer can state the evidence instead of a theorem.
   "FreshImageCount" -> 0 restores the pre-2026-08-26 two-image
   behaviour exactly, which is what the ladder rungs use. *)
Options[multiquadraticStripGaugeScreenImages] = Join[
  Options[multiquadraticStripGaugeScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True,
  "ConfirmConsistency" -> False,
  "FreshImageCount" -> Automatic,
  "FreshImageSeed" -> Automatic
}];

$multiquadraticStripDefaultFreshImageCount = 3;

multiquadraticStripGaugeScreenImages[ansatz_Association,
    opts : OptionsPattern[]] := Module[
  {gate, images, results = {}, screenOptions, result, defects,
   freshCount, freshSeed, freshRequest, freshImages = {}, freshResults = {},
   configuredCount, imageCount, evidence, verdict, measuringCount},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreenImages]]]];
  If[AssociationQ[gate], Return[gate]];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}],
    Return[multiquadraticStripFailure["InvalidGaugeScreenImages",
      <|"Images" -> images|>]]];
  (* two identical (prime, regulator) images are one image, never two
     confirmations *)
  images = DeleteDuplicates[images];
  freshCount = Replace[OptionValue["FreshImageCount"],
    Automatic :> $multiquadraticStripDefaultFreshImageCount];
  If[! (IntegerQ[freshCount] && freshCount >= 0),
    Return[multiquadraticStripFailure["InvalidFreshImageCount",
      <|"FreshImageCount" -> freshCount|>]]];
  freshSeed = Replace[OptionValue["FreshImageSeed"],
    Automatic :> OptionValue["RandomSeed"]];
  If[! IntegerQ[freshSeed],
    Return[multiquadraticStripFailure["InvalidFreshImageSeed",
      <|"FreshImageSeed" -> freshSeed|>]]];
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
  configuredCount = Length[results];
  (* ---- the fresh-image confirmation.  Only a CONFIRMED defect at the
     configured images pays for it: a consistent image, an unconfirmed
     one, and every typed stop go straight out as before. *)
  freshRequest = <|"Status" -> "FreshImagesNotRun"|>;
  If[freshCount > 0 && configuredCount >= 2 &&
      AllTrue[results, Lookup[#1, "Status", None] === "GaugeImageObstruction" &] &&
      AllTrue[results, IntegerQ[Lookup[#1, "Defect", None]] &&
        Lookup[#1, "Defect", 0] > 0 &],
    freshRequest = multiquadraticStripFreshScreenImages[ansatz, freshCount,
      freshSeed, images[[All, 1]], images[[All, 2]]];
    freshImages = Lookup[freshRequest, "Images", {}];
    If[! MatchQ[freshImages, {{_Integer, _Integer | _Rational} ...}],
      freshImages = {}];
    Do[
      result = multiquadraticStripGaugeScreen[ansatz,
        "Prime" -> freshImages[[k, 1]], "RegulatorValue" -> freshImages[[k, 2]],
        "RandomSeed" -> freshSeed + 15485863 k,
        Sequence @@ screenOptions];
      (* a fresh image that does not MEASURE -- a budget stop, a ceiling
         refusal -- is recorded and dropped, never folded into the
         verdict: it would otherwise turn a confirmed two-image
         obstruction into "the screen does not apply to this block",
         which is a different statement about a different thing *)
      If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
          Lookup[result, "Status", None]],
        freshRequest = Join[freshRequest,
          <|"UnusableImage" -> freshImages[[k]],
            "UnusableImageStatus" -> Lookup[result, "Status", None]|>];
        Break[]];
      AppendTo[freshResults, result];
      AppendTo[results, result];
      If[Lookup[result, "Defect", 1] === 0, Break[]],
      {k, Length[freshImages]}]];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  imageCount = Length[results];
  measuringCount = Count[results, r_ /; MemberQ[{"GaugeImageObstruction",
    "GaugeImageConsistent"}, Lookup[r, "Status", None]]];
  evidence = <|
    "ConfiguredRequired" -> 2,
    "ConfiguredUsable" -> Count[Take[results, UpTo[configuredCount]],
      r_ /; MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
        Lookup[r, "Status", None]]],
    "FreshRequested" -> If[Lookup[freshRequest, "Status", None] ===
        "FreshImagesNotRun", 0, freshCount],
    "FreshGenerated" -> Length[Lookup[freshRequest, "Images", {}]],
    "FreshUsable" -> Length[freshResults],
    "Defects" -> Select[defects, IntegerQ],
    "UnusableStatuses" -> DeleteMissing[
      {Lookup[freshRequest, "UnusableImageStatus", Missing["None"]]}],
    "ConfirmationEnabled" -> TrueQ[OptionValue["ConfirmObstruction"]]|>;
  verdict = multiquadraticStripScreenEvidenceClassify[evidence];
  Join[<|"Status" -> Which[
      measuringCount < imageCount,
        (* a budget stop is a RESUMABLE stop, not "the screen does not
           apply to this block": the two must not be conflated *)
        If[AnyTrue[results, Lookup[#1, "Status", None] === "BudgetExhausted" &],
          "BudgetExhausted", "GaugeScreenNotApplicable"],
      Lookup[verdict, "Verdict", None] === "SampledConsistent" &&
          TrueQ[Lookup[verdict, "AllZero", False]],
        If[Length[results] >= 2 || ! TrueQ[OptionValue["ConfirmConsistency"]],
          "GaugeImageConsistent", "GaugeImageConsistentUnconfirmed"],
      Lookup[verdict, "Verdict", None] === "SampledConsistent",
        (* a zero defect beside positive ones: sampled consistency.  The
           full route continues; this is NOT "consistent over the
           generic field" and NOT an obstruction (round-3 A1) *)
        "GaugeScreenInconclusive",
      Lookup[verdict, "Verdict", None] === "ConfirmedObstruction",
        "GaugeImageObstruction",
      Lookup[verdict, "Verdict", None] === "Unconfirmed",
        "GaugeImageObstructionUnconfirmed",
      True, "GaugeScreenInconclusive"],
    "Reason" -> Lookup[verdict, "Reason", Missing["NoReason"]],
    "Module" -> "MultiquadraticStripSolve",
    "Method" -> "PointEvaluatedAffineGaugeSystem",
    "ImageCount" -> imageCount, "Defects" -> defects,
    "Images" -> Join[Take[images, UpTo[configuredCount]],
      Take[freshImages, UpTo[imageCount - configuredCount]]],
    "ImageResults" -> results,
    (* the evidence a consumer must quote instead of a theorem; the
       DRIVER rechecks the confirmation predicate on this record before
       any negative contract *)
    "EvidenceRecord" -> Join[evidence,
      <|"Verdict" -> Lookup[verdict, "Verdict", None]|>],
    "ConfiguredImageCount" -> configuredCount,
    "FreshImageCount" -> Length[freshResults],
    "FreshImageRequest" -> KeyTake[freshRequest,
      {"Status", "Requested", "Seed", "RejectedValues", "RejectedPrimeCount",
       "UnusableImage", "UnusableImageStatus"}],
    "FreshImages" -> Take[freshImages, UpTo[Length[freshResults]]],
    "FreshDefects" -> (Lookup[#1, "Defect", Missing["NoDefect"]] & /@
      freshResults),
    "SizeEstimate" -> Lookup[Last[results], "SizeEstimate",
      Missing["NoSizeEstimate"]],
    "PhaseTimings" -> Merge[Lookup[results, "PhaseTimings", <||>], Total],
    "Stage" -> Lookup[Last[results], "Stage", Missing["NoStage"]],
    "MatrixDimensions" -> Lookup[Last[results], "MatrixDimensions",
      Missing["NoMatrix"]],
    "AnsatzFingerprint" -> Lookup[ansatz, "ABIFingerprint",
      Missing["NoPreparation"]],
    "Seconds" -> Total[Lookup[results, "Seconds", 0]]|>,
    (* the ansatz a defect belongs to: without it a defect cannot
       distinguish a missing letter from too small a support *)
    <|"Ansatz" -> Lookup[Last[results], "Ansatz", Missing["NoAnsatz"]]|>]
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
    (* "FreshImageCount" -> 0 unless the caller asked otherwise: a rung
       is a search over ANSATZ SIZE, and what it needs from an obstructed
       rung is only "keep climbing".  The fresh-image confirmation
       (round-2 item 3) is what makes the FINAL verdict quotable, and the
       driver runs it once on the base screen, not once per rung -- three
       extra screens per rung at 50-90 s each would be pure cost. *)
    result = multiquadraticStripGaugeScreenImages[ansatz,
      "ConfirmConsistency" -> True, "Deadline" -> deadline,
      "FreshImageCount" -> Replace[OptionValue["FreshImageCount"],
        Automatic :> 0],
      Sequence @@ FilterRules[screenOptions,
        Except[HoldPattern["FreshImageCount" -> _]]]];
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
   diagnostic.  The in-frame dispatcher has already paid for that package
   census; the helper below accepts that exact same-call result so the
   multiquadratic solver need not scan a large strip twice. *)
multiquadraticStripRootCensusFromFrameCensus[frameCensus_Association,
    allRoots_List] := Module[
  {rootBases, radicals, matches, indices, unknown, denested,
   denestedIndices},
  rootBases = Together /@ (#1["Root"]^2 & /@ allRoots);
  radicals = Lookup[frameCensus, "RadicalBases", {}];
  matches[base_] := Flatten[Position[rootBases,
    candidate_ /; TrueQ[Together[base - candidate] === 0], {1},
    Heads -> False]];
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#1] === {} &];
  (* ONE SHARED FIELD CANONICALIZER (2026-08-26, round-2 item 4, Codex
     review 1.4).  A radicand that is not LITERALLY a declared square may
     still lie in the declared multiquadratic field: with declared roots
     Sqrt[x] and Sqrt[y], Sqrt[x y] is Sqrt[x] Sqrt[y].  The transport
     side has recognized and denested such a base exactly since
     2026-08-24 (transportChartDenestRadicalBase, its square identity
     checked exactly and its global sign fixed numerically); the solver
     refused it as an undeclared radical and multiquadraticFieldDecompose
     then failed on the same strip transport accepts.

     The frame census above has ALREADY run the denester on every base
     the exact matcher missed -- its "DenestedRadicalBases" is exactly
     that -- so consuming it here costs nothing on a strip whose radicals
     are all declared (every CF259/CF300/CF303 strip measured so far)
     and is the whole repair on a strip whose are not.  The level-1
     matcher stays: the frame census's own index set is still only a
     diagnostic, because its all-level Position over-reports rank. *)
  denested = KeySelect[Lookup[frameCensus, "DenestedRadicalBases", <||>],
    Function[base, AnyTrue[unknown, TrueQ[Together[base - #1] === 0] &]]];
  denestedIndices = Sort[DeleteDuplicates[Join[
    Flatten[Lookup[Values[denested], "RootIndices", {}]],
    Flatten[Lookup[Values[denested], "InnerRootIndices", {}]]]]];
  indices = Sort[DeleteDuplicates[Join[indices, denestedIndices]]];
  unknown = Select[unknown,
    Function[base, ! AnyTrue[Keys[denested], TrueQ[Together[base - #1] === 0] &]]];
  <|"Status" -> If[unknown === {}, "ExactRootClassification",
      "UnclassifiedRadicals"],
    "RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    (* the bases that needed denesting, with the verified rewrite: a
       consumer that decomposes into channels MUST canonicalize the
       expression with multiquadraticStripCanonicalizeRadicals first *)
    "DenestedRadicalBases" -> denested,
    "DenestedRootIndices" -> denestedIndices,
    "NumericRadicalClasses" ->
      Lookup[frameCensus, "NumericRadicalClasses", {}],
    "FrameCensusRootIndices" -> Lookup[frameCensus, "RootIndices", {}],
    "FrameCensusUnclassified" ->
      Lookup[frameCensus, "UnclassifiedRadicalBases", {}]|>
];
multiquadraticStripRootCensusFromFrameCensus[___] :=
  multiquadraticStripFailure["InvalidFrameRootCensusArguments"];

multiquadraticStripRootCensus[strip_, allRoots_List] :=
  multiquadraticStripRootCensusFromFrameCensus[
    transportChartRootIndices[strip, allRoots], allRoots];

(* Extend the visible-strip census by the authenticated root frame of a
   deferred forcing bundle.  The dense BBar slot is deliberately zero on that
   route, so this union is the single shared authority used both before
   alphabet construction and by preparation.  The union is canonicalized by
   BlockEquationDeferred's stable frame builder, the same route used by the
   transport dispatcher; source indices remain provenance only. *)
multiquadraticStripRootCensusWithBundle[strip_, allRoots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, deferredBundle_,
    frameCensus_: Automatic] := Module[
  {classification, validation, bundleRoots, bundleIndices, selectedIndices,
   stableFrame, requiredRootIndices},
  If[AssociationQ[deferredBundle],
    validation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[validation, "Status", None] =!= "BundleValid",
      Return[multiquadraticStripFailure["InvalidDeferredBundle",
        <|"Detail" -> validation|>]]];
    If[Lookup[deferredBundle, "Variables", None] =!= variables ||
        Lookup[deferredBundle, "Regulator", None] =!= epsilon ||
        Lookup[deferredBundle, "Dimensions", None] =!=
          Prepend[Dimensions[strip[[3, 1]]], 2],
      Return[multiquadraticStripFailure["DeferredBundleFrameMismatch"]]],
    If[! MissingQ[deferredBundle] && deferredBundle =!= Automatic,
      Return[multiquadraticStripFailure["InvalidDeferredBundle"]]]];
  classification = If[AssociationQ[frameCensus],
    multiquadraticStripRootCensusFromFrameCensus[frameCensus, allRoots],
    multiquadraticStripRootCensus[strip, allRoots]];
  If[! AssociationQ[deferredBundle],
    Return[Join[classification, <|"BundleRootIndices" -> {},
      "RequiredRootIndices" -> classification["RootIndices"]|>]]];
  bundleRoots = Lookup[deferredBundle["RootFrame"], "Roots", {}];
  bundleIndices = Table[Module[{matches},
      matches = Flatten[Position[allRoots,
        candidate_ /; TrueQ[Quiet[Together[
              candidate["RootSquare"] - bundleRoot["RootSquare"]]] === 0] &&
          TrueQ[Quiet[Together[
              candidate["Root"] - bundleRoot["Root"]]] === 0],
        {1}, Heads -> False]];
      If[Length[matches] =!= 1,
        Return[multiquadraticStripFailure[
          "DeferredBundleRootFrameMismatch",
          <|"BundleRoot" -> bundleRoot, "Matches" -> matches|>], Module]];
      First[matches]],
    {bundleRoot, bundleRoots}];
  If[! VectorQ[bundleIndices, IntegerQ],
    Return[FirstCase[bundleIndices, failure_Association :> failure,
      multiquadraticStripFailure["DeferredBundleRootFrameMismatch"]]]];
  selectedIndices = DeleteDuplicates[Join[
    classification["RootIndices"], bundleIndices]];
  stableFrame = blockEquationDeferredRootFrame[
    KeyTake[#1, {"Root", "RootSquare"}] & /@ allRoots[[selectedIndices]],
    variables, epsilon];
  If[Lookup[stableFrame, "Status", None] =!= "StableRootOrder",
    Return[multiquadraticStripFailure["DeferredBundleRootUnionInvalid",
      <|"Detail" -> stableFrame|>]]];
  requiredRootIndices = selectedIndices[[Lookup[stableFrame["Roots"],
    "SourceIndex", {}]]];
  Join[classification, <|"BundleRootIndices" -> bundleIndices,
    "RequiredRootIndices" -> requiredRootIndices|>]
];
multiquadraticStripRootCensusWithBundle[___] :=
  multiquadraticStripFailure["InvalidBundleRootCensusArguments"];

(* The rewrite side of the same canonicalizer.  Given an expression (a
   strip, a matrix, a letter) and the census that classified it, return
   the expression with every denested radical replaced by its declared
   form, so that transportChartApplyRootBranches and therefore
   multiquadraticFieldDecompose see only declared radicands.

   A census with no denested SYMBOLIC base returns the input untouched
   and does no work: this is the measured common case, and the guard is
   what keeps the canonicalizer free on CF300-shaped input.  A numeric
   class constant is a constant of the coefficient field and is left
   alone, exactly as the transport side leaves it. *)
multiquadraticStripCanonicalizeRadicals[expression_, allRoots_List,
    census_Association] := Module[{denested, variables, canonical},
  denested = KeySelect[Lookup[census, "DenestedRadicalBases", <||>],
    ! NumericQ[#1] &];
  If[denested === <||> || ! ListQ[allRoots] || allRoots === {},
    Return[<|"Status" -> "NoRadicalCanonicalizationNeeded",
      "Expression" -> expression, "Rewritten" -> 0, "Bases" -> {}|>]];
  variables = Select[DeleteDuplicates[Flatten[Variables /@
    (Together /@ Lookup[allRoots, "RootSquare", {}])]], MatchQ[#1, _Symbol] &];
  canonical = transportChartCanonicalizeDenestedRadicals[expression, allRoots,
    variables, denested];
  If[Lookup[canonical, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure["RadicalCanonicalizationFailed",
      <|"Detail" -> canonical, "Bases" -> Keys[denested]|>]]];
  <|"Status" -> "RadicalsCanonicalized",
    "Expression" -> canonical["Expression"],
    "Rewritten" -> canonical["Rewritten"],
    "Bases" -> Keys[canonical["Rewrites"]],
    "Signs" -> Lookup[Values[canonical["Rewrites"]], "Sign", {}],
    "Witnesses" -> Lookup[Values[canonical["Rewrites"]], "Witness", {}]|>
];
multiquadraticStripCanonicalizeRadicals[___] :=
  multiquadraticStripFailure["InvalidRadicalCanonicalizationArguments"];

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
  {rules, strip, deferredBundle, diagonalCanonical, equationCanonical,
   bundleFingerprint, bundleValidation, deferredFastQ, deferredDimensions},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  deferredBundle = Lookup[record, "DeferredBundle",
    Missing["NoDeferredBundle"]];
  deferredDimensions = Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]];
  deferredFastQ = AssociationQ[deferredBundle] &&
    MatchQ[deferredDimensions, {_Integer?Positive, _Integer?Positive}] &&
    Dimensions[strip[[3]]] === Prepend[deferredDimensions, 2] &&
    AllTrue[Flatten[strip[[3]]], SameQ[#1, 0] &] &&
    Lookup[deferredBundle, "Dimensions", None] ===
      Prepend[deferredDimensions, 2];
  equationCanonical = If[deferredFastQ,
    (* On the deferred route BBar is intentionally a zero shape placeholder;
       its authenticated bundle is the forcing.  Re-running Together, Expand
       and InputForm over every large diagonal entry took more than nine
       minutes on CF259 (27,9), even with CompileCore -> False.  A strict
       context-free structural seal of E/C plus the already-authenticated
       bundle binds exactly the representation this call consumes.  An
       equivalent rewrite can conservatively miss a cache/checkpoint, but it
       cannot reuse one for different input. *)
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[$Failed]];
    bundleFingerprint = Lookup[deferredBundle, "BundleFingerprint", None];
    diagonalCanonical = strip[[1 ;; 2]] /. rules;
    If[! StringQ[bundleFingerprint] ||
        ! multiquadraticStripContextFreeQ[diagonalCanonical],
      Return[$Failed]];
    "DeferredEquationStructuralV1:" <> Hash[
      {"DeferredEquationStructuralV1", diagonalCanonical,
       bundleFingerprint, Dimensions /@ strip},
      "SHA256", "HexString"],
    ToString[InputForm[Map[
      multiquadraticStripCanonicalText[#1, rules] &, strip, {4}]]]];
  <|"RootCanonicalSquares" -> (multiquadraticStripCanonicalText[
      Lookup[#1, "RootSquare", $Failed], rules] & /@ roots),
    "RootCanonicalExpressions" -> (multiquadraticStripCanonicalText[
      Lookup[#1, "Root", $Failed], rules] & /@ roots),
    "EquationCanonical" -> equationCanonical|>
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
  (* the BASE gauge denominator (Automatic: derived from the forcing and the
     letters).  A supplied value is canonicalized by
     multiquadraticStripMergeGaugeDenominator (unit leading coefficient per
     factor, factors free of the chart variables dropped) and is then
     ENLARGED by the GaugeDenominatorFactor below unless that is pinned to 1;
     a planted or pinned ansatz must pass "GaugeDenominatorFactor" -> 1
     (t_multiquadratic_installed_family_chain, 2026-09-02). *)
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
  (* The preparation owns the ansatz metadata, not the coefficient
     representation.  CompiledChannel preserves the historical exact
     channel preparation.  SplitBranch and QuotientGrade deliberately
     leave ForcingChannels absent and derive an automatic conservative
     denominator from the source/bundle divisors; their provider supplies
     finite-field coefficients later.  Automatic remains CompiledChannel
     for direct callers of Prepare; the top-level production driver
     resolves its own Automatic to SplitBranch. *)
  "CoefficientProvider" -> Automatic,
  (* Optional immutable BlockEquationDeferredBundleV2.  Direct providers
     consume it at modular points and the preparation consumes only its
     divisor summary; no dense forcing need be materialized. *)
  "DeferredBundle" -> Automatic,
  (* True makes the forcing channels come from the SEALED, interned
     compile core (E, C and BBar decomposed and compiled once, keyed on
     the equation and the roots), which the compiler then finds already
     built.  False decomposes the forcing here and leaves E and C to the
     compiler.

     Automatic = FALSE.  Pre-building the core pays only where a core is
     REUSED -- a degree-offset ladder rung, a second ansatz on the same
     equation, a re-prepare -- and costs where it is not, because the
     compiler already receives prepare's sealed channels.  Turning it on
     is a measured decision per shape, never a default.  The measurement
     that fixed this default is in
     Results/UU_08_10_canonical/FamilyEpsFormsSolving/
     MultiquadraticMeasurementNarratives_2026-08-26.md, section 1.

     Either way the result is the same: both routes reach a
     byte-identical preparation and the same assembly fingerprints.  The
     False branch goes through the interned decomposer, which returns
     exactly what multiquadraticStripDecomposeScalar returns and so
     cannot change a value, but decomposes each distinct entry once. *)
  "CompileCore" -> Automatic,
  "NormalizationEquations" -> {},
  "RootIndices" -> Automatic,
  (* Internal same-call reuse.  The top-level solver has already classified
     the exact strip before building its alphabet; on an outer-authenticated
     deferred bundle it passes that result here instead of scanning the same
     very large E/C trees again.  Direct Prepare callers keep Automatic. *)
  "RootClassification" -> Automatic,
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
  (* 1 = serial; 2..8 = requested Wolfram subkernels.  Automatic uses
     already-live subkernels but launches none. *)
  "DLogKernels" -> Automatic,
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

(* `record` is a Module LOCAL initialized from the argument, not the
   pattern name itself: the shared field canonicalizer (round-2 item 4)
   may rewrite the strip into declared radicals, and everything after
   that point -- the ABI payload, the stored "Record", the compile core
   key, the forcing decomposition -- must see the SAME canonical strip. *)
multiquadraticStripPrepare[sourceRecord_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {record = sourceRecord, radicalCanonicalization,
   gate, variables, epsilon, strip, allRoots, classification, rootIndices,
   bundleIndices, requiredRootIndices,
   order, roots, channelForcing, suppliedChannels, oneFormData, oneForms,
   gaugeDenominator,
   letterRecords, gaugeDenominatorFactor,
   denominatorDegrees, degreeOffset, numeratorDegrees, support, dimensions,
   gradeCount, gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, normalizations, payload, fingerprint,
   coreEnabled, coreCanonical, coreDimensions, coreKey, coreConsumed = False,
   coefficientProvider, deferredBundle, bundleRootEmbedding, bundleGauge,
   deferredPreparationWrapper, deferredPreparation,
   directPreparationQ, suppliedClassification, trustedClassificationQ,
   refinedBundleGauge,
   provisionalDegrees, provisionalSupportCount, provisionalUnknownCount,
   provisionalEquationsPerPoint, provisionalPointCount,
   provisionalSampleEstimate,
   checkpointDirectory, checkpointMode, checkpointEnabledQ, checkpointTag,
   checkpointRecords = {},
   checkpointRead, checkpointWrite, checkpointInputFingerprint,
   forcingCheckpointFingerprint, checkpointChannels,
   letterCheckpointFingerprint, checkpointLetters,
   denominatorCheckpointFingerprint, denominatorCheckpointNorms,
   checkpointDenominator,
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
  (* A deferred bundle is mathematical input, not telemetry.  Its forcing
     roots are absent from the deliberate zero BBar placeholder, so it must
     authenticate and join the root census before RootIndices is chosen. *)
  deferredBundle = Replace[OptionValue["DeferredBundle"], Automatic :>
    Lookup[record, "DeferredBundle", Missing["NoDeferredBundle"]]];
  deferredPreparationWrapper = Lookup[record, "DeferredPreparation",
    Missing["NoDeferredPreparation"]];
  deferredPreparation = If[AssociationQ[deferredPreparationWrapper],
    Lookup[deferredPreparationWrapper, "Preparation",
      deferredPreparationWrapper], deferredPreparationWrapper];
  (* The raw native route deliberately has no DeferredBundle: its immutable
     BlockEquationDeferred preparation is the coefficient source.  The outer
     solver has already unioned the wrapper's declared RootSquares with the
     visible strip census.  Authenticate that same-call source by its small
     structural seal so Prepare does not throw the union away and rescan the
     zero BBar placeholder as a rank-one equation. *)
  directPreparationQ = AssociationQ[deferredPreparationWrapper] &&
    AssociationQ[deferredPreparation] &&
    ListQ[Lookup[deferredPreparationWrapper, "RootSquares", $Failed]] &&
    Lookup[deferredPreparation, "Status", None] === "Prepared" &&
    Lookup[deferredPreparation, "ABIVersion", None] ===
      $blockEquationDeferredABIVersion &&
    Lookup[deferredPreparation, "Variables", None] === variables &&
    Lookup[deferredPreparation, "Regulator", None] === epsilon &&
    Lookup[deferredPreparation, "Dimensions", None] ===
      Dimensions[strip[[3]]];
  allRoots = transportChartCurrentRoots[frame, variables];
  If[! ListQ[allRoots],
    Return[multiquadraticStripFailure["AlgebraicFrameNotWellFormed"]]];
  multiquadraticStripStageStart["prepare: root census",
    <|"supplied" -> AssociationQ[OptionValue["RootClassification"]]|>];
  suppliedClassification = OptionValue["RootClassification"];
  trustedClassificationQ = AssociationQ[suppliedClassification] &&
    AllTrue[{"UnclassifiedRadicalBases", "RootIndices",
      "BundleRootIndices", "RequiredRootIndices"},
      KeyExistsQ[suppliedClassification, #1] &] &&
    ((AssociationQ[deferredBundle] &&
        AssociationQ[$blockEquationDeferredTrustedBundle] &&
        Lookup[blockEquationDeferredBundleValidate[deferredBundle],
          "Status", None] === "BundleValid") || directPreparationQ);
  classification = If[trustedClassificationQ, suppliedClassification,
    multiquadraticStripRootCensusWithBundle[strip, allRoots,
      variables, epsilon, deferredBundle]];
  multiquadraticStripStageDone["prepare: root census",
    <|"source" -> If[trustedClassificationQ, "SameCall", "Fresh"]|>];
  If[! KeyExistsQ[classification, "UnclassifiedRadicalBases"],
    Return[classification]];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[multiquadraticStripFailure["StripContainsUndeclaredRadicals",
      <|"RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]]];
  (* THE SHARED CANONICALIZER (round-2 item 4).  Any radical the census
     classified only by denesting is rewritten into declared radicals
     BEFORE anything decomposes: transportChartApplyRootBranches, and so
     multiquadraticFieldDecompose, substitutes declared radicands only,
     and would otherwise fail on a strip transport happily accepts.
     A strip with no denested base takes the no-op branch. *)
  radicalCanonicalization = multiquadraticStripCanonicalizeRadicals[strip,
    allRoots, classification];
  Which[
    Lookup[radicalCanonicalization, "Status", None] ===
      "NoRadicalCanonicalizationNeeded", Null,
    Lookup[radicalCanonicalization, "Status", None] === "RadicalsCanonicalized",
      strip = radicalCanonicalization["Expression"];
      record = Join[record, <|"Strip" -> strip|>],
    True, Return[radicalCanonicalization]];
  bundleIndices = classification["BundleRootIndices"];
  requiredRootIndices = classification["RequiredRootIndices"];
  rootIndices = Replace[OptionValue["RootIndices"],
    Automatic :> Sort[requiredRootIndices]];
  If[! VectorQ[rootIndices, IntegerQ] || rootIndices =!= Sort[rootIndices] ||
      ! DuplicateFreeQ[rootIndices] ||
      ! SubsetQ[rootIndices, Sort[DeleteDuplicates[Join[
          classification["RootIndices"], bundleIndices]]]],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  If[AssociationQ[deferredBundle] && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticStripFailure[
      "DeferredBundleRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[directPreparationQ && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticStripFailure[
      "DeferredPreparationRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[Length[rootIndices] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank",
      <|"MaximumRank" -> $multiquadraticStripMaximumRootCount,
        "ActualRank" -> Length[rootIndices]|>]]];
  (* before the root order, which denests and square-class-matches every
     declared radical *)
  If[prepareGuard["RootOrder"], Return[prepareStop]];
  multiquadraticStripStageStart["prepare: root order"];
  order = multiquadraticStripRootOrder[frame, variables, rootIndices, epsilon];
  multiquadraticStripStageDone["prepare: root order",
    <|"status" -> Lookup[order, "Status", None]|>];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  roots = order["Roots"];
  coefficientProvider = Replace[OptionValue["CoefficientProvider"],
    Automatic -> "CompiledChannel"];
  If[! MemberQ[{"CompiledChannel", "SplitBranch", "QuotientGrade"},
      coefficientProvider],
    Return[multiquadraticStripFailure["InvalidCoefficientProvider",
      <|"CoefficientProvider" -> coefficientProvider|>]]];
  If[! MissingQ[deferredBundle],
    bundleRootEmbedding = multiquadraticStripBundleRootEmbedding[
      Lookup[deferredBundle["RootFrame"], "Roots", {}], roots];
    If[bundleRootEmbedding === $Failed,
      Return[multiquadraticStripFailure[
        "DeferredBundleRootOrderMismatch"]]];
    record = Join[record, <|"DeferredBundle" -> deferredBundle|>]];
  (* the exact decomposition WITH the recompose check, so the compiler can
     reuse this result inside the same call instead of decomposing the
     forcing a second time (post-mortem item 5: the second decomposition
     was 807 s of the 4872 s compile of CF300 (12,9)) *)
  suppliedChannels = If[coefficientProvider === "CompiledChannel",
    multiquadraticStripForcingChannelsAccept[
      OptionValue["ForcingChannels"], strip[[3]], roots, variables, epsilon],
    <|"Status" -> "NotRequired"|>];
  If[! MemberQ[{"NotSupplied", "Accepted", "NotRequired"},
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
  multiquadraticStripStageStart["prepare: equation identity",
    <|"deferred" -> AssociationQ[deferredBundle]|>];
  coreCanonical = multiquadraticStripCoreCanonicalData[record, roots,
    variables, epsilon];
  multiquadraticStripStageDone["prepare: equation identity",
    <|"status" -> If[AssociationQ[coreCanonical], "Prepared", "Failed"]|>];
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
  checkpointEnabledQ = checkpointDirectory =!= None &&
    checkpointMode =!= "None";
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
  (* Production normally has persistence disabled.  In that case a
     checkpoint identity has no consumer: checkpointRead and checkpointWrite
     both return before looking at it.  Large algebraic metadata must not be
     serialized merely to manufacture a key that will be discarded. *)
  checkpointInputFingerprint[substage_String, extra_] :=
    If[checkpointDirectory === None || checkpointMode === "None",
      Missing["CheckpointsDisabled"],
      multiquadraticStripFingerprint[{substage,
        If[AssociationQ[coreCanonical],
          Lookup[coreCanonical, {"EquationCanonical", "RootCanonicalSquares",
            "RootCanonicalExpressions"}], $Failed],
        coreDimensions, extra}]];
  (* read: Missing if persistence is off, this substage has no file, or
     the file exists and does not authenticate -- and in the last case
     the refusal is RECORDED, so a poisoned checkpoint is visible in the
     preparation rather than silently ignored *)
  checkpointRead[substage_String, fingerprint_] := Module[
    {file, raw, verdict, proposalVerdict = <||>, proposalQ = False,
     suppliedFingerprint, readStatus},
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
    (* A gauge denominator is an ansatz proposal, not accepted mathematics.
       If the exact input representation changed, an internally intact stored
       denominator may still be tried: a bad proposal can only make the
       solver fail to find a gauge, while the normal fresh modular residual
       remains the sole per-block acceptance.  Forcing channels and letters
       never receive this relaxation. *)
    If[substage === "GaugeDenominator" &&
        Lookup[verdict, "Status", None] ===
          "PrepareCheckpointInputMismatch",
      suppliedFingerprint = Lookup[raw["Value"], "InputFingerprint", None];
      If[StringQ[suppliedFingerprint],
        proposalVerdict = multiquadraticStripPrepareCheckpointAccept[
          raw["Value"], substage, suppliedFingerprint, variables, epsilon];
        proposalQ = Lookup[proposalVerdict, "Status", None] === "Accepted" &&
          MatchQ[Lookup[proposalVerdict, "Payload", None],
            {_, _} | {_, _, {_Integer, _Integer}}]]];
    readStatus = If[proposalQ, "AcceptedGaugeDenominatorProposal",
      Lookup[verdict, "Status", None]];
    AppendTo[checkpointRecords, <|"Substage" -> substage,
      "Action" -> "Read", "Status" -> readStatus,
      "File" -> file, "FileSHA256" -> raw["SHA256"],
      "Refusal" -> KeyDrop[verdict, {"Status", "Payload"}]|>];
    If[proposalQ, Return[proposalVerdict["Payload"]]];
    If[readStatus =!= "Accepted",
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
  forcingCheckpointFingerprint = If[checkpointEnabledQ,
    checkpointInputFingerprint["ForcingChannels", {}],
    Missing["CheckpointsDisabled"]];
  checkpointChannels = If[coefficientProvider =!= "CompiledChannel" ||
      suppliedChannels["Status"] === "Accepted",
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
    coefficientProvider =!= "CompiledChannel", Missing["DirectProvider"],
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
  If[coefficientProvider === "CompiledChannel" &&
      suppliedChannels["Status"] =!= "Accepted" && MissingQ[checkpointChannels],
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
      letterCheckpointFingerprint = If[checkpointEnabledQ,
        checkpointInputFingerprint[
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
               multiquadraticStripCanonicalRules[variables, epsilon]]}],
        Missing["CheckpointsDisabled"]];
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
          "MaximumNormExponent" -> OptionValue["MaximumNormExponent"],
          "DLogKernels" -> OptionValue["DLogKernels"],
          "Deadline" -> deadline];
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
  denominatorCheckpointNorms = If[
    MatchQ[letterRecords, {___Association}],
    DeleteCases[
      Lookup[#1, "Norm", Missing["NoNorm"]] & /@ letterRecords,
      _Missing], {}];
  multiquadraticStripStageStart[
    "prepare: gauge denominator checkpoint identity",
    <|"enabled" -> checkpointEnabledQ,
      "norms" -> Length[denominatorCheckpointNorms]|>];
  denominatorCheckpointFingerprint = If[checkpointEnabledQ,
    checkpointInputFingerprint[
      "GaugeDenominator",
      {multiquadraticStripFingerprint[
         denominatorCheckpointNorms /.
           multiquadraticStripCanonicalRules[variables, epsilon]],
       multiquadraticStripFingerprint[OptionValue["GaugeDenominatorFactor"] /.
         multiquadraticStripCanonicalRules[variables, epsilon]],
       multiquadraticStripFingerprint[OptionValue["GaugeDenominator"] /.
         multiquadraticStripCanonicalRules[variables, epsilon]],
       "GaugeDenominatorProposalV2",
       If[AssociationQ[deferredBundle],
         Lookup[deferredBundle, "BundleFingerprint", None], None]}],
    Missing["CheckpointsDisabled"]];
  multiquadraticStripStageDone[
    "prepare: gauge denominator checkpoint identity"];
  checkpointDenominator = checkpointRead["GaugeDenominator",
    denominatorCheckpointFingerprint];
  If[MatchQ[checkpointDenominator,
      {_, _} | {_, _, {_Integer, _Integer}}],
    multiquadraticStripStageMark["prepare: gauge denominator",
      <|"source" -> "Checkpoint"|>];
    If[Length[checkpointDenominator] === 3,
      {gaugeDenominatorFactor, gaugeDenominator, denominatorDegrees} =
        checkpointDenominator,
      {gaugeDenominatorFactor, gaugeDenominator} = checkpointDenominator;
      denominatorDegrees = Missing["NotStored"]],
    checkpointDenominator = Missing["NoCheckpoint"];
    gaugeDenominatorFactor = Replace[OptionValue["GaugeDenominatorFactor"],
      Automatic :> If[MatchQ[letterRecords, {___Association}],
        multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1]];
    gaugeDenominator = Replace[OptionValue["GaugeDenominator"], {
      supplied_ /; supplied =!= Automatic :>
        multiquadraticStripMergeGaugeDenominator[
          supplied, gaugeDenominatorFactor, variables],
      Automatic :> If[coefficientProvider === "CompiledChannel",
        multiquadraticStripMergeGaugeDenominator[
          multiquadraticRationalGaugeDenominator[channelForcing, variables],
          gaugeDenominatorFactor, variables],
        If[AssociationQ[deferredBundle],
          multiquadraticStripStageStart[
            "prepare: bundle gauge denominator"];
          bundleGauge = multiquadraticStripBundleGaugeDenominator[
            deferredBundle, variables,
            If[MatchQ[letterRecords, {___Association}], letterRecords, {}]];
          multiquadraticStripStageDone[
            "prepare: bundle gauge denominator",
            <|"status" -> Lookup[bundleGauge, "Status", None],
              "factors" -> Lookup[bundleGauge, "FactorCount", None],
              "groups" -> Lookup[bundleGauge, "GroupedFactorCount", None],
              "seconds" -> Lookup[bundleGauge, "Seconds", None]|>];
          If[Lookup[bundleGauge, "Status", None] =!=
              "BundleGaugeDenominatorV1", Return[bundleGauge, Module]];
          (* Refine only when the pre-cancellation rectangle would exceed
             the sampler's hard memory ceiling.  Small/easy blocks retain
             the cheap divisor-summary path exactly. *)
          If[OptionValue["Support"] === Automatic &&
              MatchQ[coreDimensions, {_Integer, _Integer}] &&
              MatchQ[OptionValue["DegreeOffset"],
                {_Integer?NonNegative, _Integer?NonNegative}],
            provisionalDegrees =
              bundleGauge["GaugeDenominatorDegrees"] +
                OptionValue["DegreeOffset"];
            provisionalSupportCount = Times @@ (provisionalDegrees + 1);
            provisionalUnknownCount = (Times @@ coreDimensions) *
                2^Length[roots] * provisionalSupportCount +
              Length[oneForms] * (Times @@ coreDimensions);
            provisionalEquationsPerPoint = 2 * (Times @@ coreDimensions) *
              2^Length[roots];
            provisionalPointCount = Max[4, Ceiling[
              (provisionalUnknownCount + provisionalEquationsPerPoint)/
                provisionalEquationsPerPoint]];
            provisionalSampleEstimate = multiquadraticStripSampleSizeEstimate[
              provisionalPointCount, provisionalEquationsPerPoint, 0,
              provisionalUnknownCount];
            If[AssociationQ[provisionalSampleEstimate] &&
                provisionalSampleEstimate["PeakPackedBytesLowerBound"] >
                  $multiquadraticStripSampleMaximumBytes,
              multiquadraticStripStageStart[
                "prepare: exact bundle denominator refinement",
                <|"preCancellationUnknowns" -> provisionalUnknownCount,
                  "preCancellationPeakBytes" ->
                    provisionalSampleEstimate[
                      "PeakPackedBytesLowerBound"],
                  "entries" -> Times @@ coreDimensions,
                  "rank" -> Length[roots]|>];
              refinedBundleGauge =
                multiquadraticStripBundleRefinedGaugeDenominator[
                  deferredBundle, roots, variables, epsilon,
                  If[MatchQ[letterRecords, {___Association}],
                    letterRecords, {}]];
              multiquadraticStripStageDone[
                "prepare: exact bundle denominator refinement",
                <|"status" -> Lookup[refinedBundleGauge, "Status", None],
                  "seconds" -> Lookup[refinedBundleGauge, "Seconds",
                    Missing["NotMeasured"]],
                  "helpers" -> Lookup[refinedBundleGauge,
                    "BrokerHelperCount", 0]|>];
              If[Lookup[refinedBundleGauge, "Status", None] =!=
                  "BundleRefinedGaugeDenominatorV1",
                Return[refinedBundleGauge, Module]];
              bundleGauge = Join[bundleGauge, <|
                "PreCancellationGaugeDenominator" ->
                  bundleGauge["GaugeDenominator"],
                "GaugeDenominator" ->
                  refinedBundleGauge["GaugeDenominator"],
                "GaugeDenominatorDegrees" ->
                  refinedBundleGauge["GaugeDenominatorDegrees"],
                "ExactCancellationRefinement" ->
                  KeyDrop[refinedBundleGauge, "GaugeDenominator"],
                "PreCancellationSampleEstimate" ->
                  provisionalSampleEstimate|>]]];
          denominatorDegrees = bundleGauge["GaugeDenominatorDegrees"];
          bundleGauge["GaugeDenominator"],
          multiquadraticStripConservativeGaugeDenominator[strip, roots,
            letterRecords, variables]]]}]];
  If[TrueQ[Together[gaugeDenominatorFactor] === 0] ||
      ! FreeQ[gaugeDenominatorFactor,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorFactorNotRational",
      <|"GaugeDenominatorFactor" -> gaugeDenominatorFactor|>]]];
  If[TrueQ[gaugeDenominator === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  If[! MatchQ[denominatorDegrees,
      {_Integer?NonNegative, _Integer?NonNegative}],
    multiquadraticStripStageStart[
      "prepare: gauge denominator degrees"];
    denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
    multiquadraticStripStageDone[
      "prepare: gauge denominator degrees",
      <|"degrees" -> denominatorDegrees|>]];
  If[MissingQ[checkpointDenominator],
    checkpointWrite["GaugeDenominator", denominatorCheckpointFingerprint,
      {gaugeDenominatorFactor, gaugeDenominator, denominatorDegrees}]];
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
      "DenestedRootIndices", "NumericRadicalClasses",
      "FrameCensusRootIndices", "FrameCensusUnclassified",
      "BundleRootIndices", "RequiredRootIndices"}],
    (* what the shared field canonicalizer rewrote, if anything: a
       provenance field, deliberately outside the hashed ABI payload
       (the payload already hashes the CANONICAL strip) *)
    "RadicalCanonicalization" -> KeyTake[radicalCanonicalization,
      {"Status", "Rewritten", "Bases", "Signs"}],
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
    (* ---- CERTIFIED dlog POTENTIALS (round-2 item 7).  The preparation
       states, for the alphabet it actually installed, whether every
       one-form carries a VERIFIED potential omega = dlog L.  A caller
       that supplied bare one-forms has no letters to verify, and the
       verdict is then False with the reason recorded: a closed one-form
       with no verified potential is not installable, which is the
       refusal both reviews asked to keep. *)
    "Potentials" -> If[MatchQ[letterRecords, {___Association}],
      KeyTake[#1, {"Kind", "Letter", "FormKey", "Potential"}] & /@
        letterRecords,
      Missing["LettersSuppliedAsOneForms"]],
    (* since round-3 A2 this is CANDIDATE-POOL telemetry: the terminal
       certification bit is the ACTIVE-support verdict, computed only
       after regulator reconstruction, because an unused candidate with
       zero reconstructed residue cannot obstruct installation *)
    "PotentialsCertified" -> If[MatchQ[letterRecords, {___Association}],
      multiquadraticStripPotentialsCertifiedQ[letterRecords], False],
    "PotentialsCertifiedReason" -> Which[
      ! MatchQ[letterRecords, {___Association}],
        "OneFormsSuppliedWithoutLetters",
      letterRecords === {}, "EmptyAlphabet",
      multiquadraticStripPotentialsCertifiedQ[letterRecords],
        "EveryOneFormCarriesAVerifiedPotential",
      True, "SomeOneFormHasNoVerifiedPotential"],
    (* Map, NOT Lookup[list, key, default]: Lookup reads an EMPTY list as
       an empty list of RULES and returns the DEFAULT rather than an empty
       list, so on an alphabet with nothing unverified this fed Counts a
       bare None (Counts::invrp, found by the round-2 final gate).  Map is
       correct on the empty list and on every other. *)
    "PotentialsUnverifiedKinds" -> If[MatchQ[letterRecords, {___Association}],
      Counts[Lookup[#1, "Kind", None] & /@ Select[letterRecords,
        ! TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &]],
      Missing["LettersSuppliedAsOneForms"]],
    "GaugeDenominatorFactor" -> Together[gaugeDenominatorFactor],
    (* sealed, not bare (Codex 04:30 P2): the record carries the
       fingerprint of the forcing / root order / variables / regulator it
       decomposes, so a consumer can fail closed instead of trusting a
       shape *)
    "ForcingChannels" -> If[coefficientProvider === "CompiledChannel",
      multiquadraticStripForcingChannelRecord[channelForcing, strip[[3]],
        roots, variables, epsilon], Missing["DirectProvider"]],
    "DeferredBundle" -> If[AssociationQ[deferredBundle], deferredBundle,
      Missing["NoDeferredBundle"]],
    "DeferredBundleFingerprint" -> If[AssociationQ[deferredBundle],
      deferredBundle["BundleFingerprint"], Missing["NoDeferredBundle"]],
    "BundleDivisorProvenance" -> If[AssociationQ[bundleGauge],
      KeyDrop[bundleGauge, "GaugeDenominator"],
      Missing["BundleGaugeDenominatorNotUsed"]],
    "CoefficientProvider" -> coefficientProvider,
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
   Exchange/Fable/2026-08-24/01_cf300_12_9_state_and_reply/
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
multiquadraticStripLetterChannelData[letter_, roots_List,
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
    <|"LetterChannels" -> channels, "DLogChannels" -> result|>]
];
multiquadraticStripLetterChannelData[___] := $Failed;

multiquadraticStripLetterChannelPair[letter_, roots_List,
    variables : {_Symbol, _Symbol}] := Module[{data},
  data = multiquadraticStripLetterChannelData[letter, roots, variables];
  If[AssociationQ[data], Lookup[data, "DLogChannels", $Failed], $Failed]
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
  {letter, certificate, derived, letterChannels, formChannels,
   certificateValidQ},
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
  letterChannels = Lookup[letterRecord, "DLogLetterChannels", $Failed];
  formChannels = Lookup[letterRecord, "DLogChannels", $Failed];
  certificateValidQ = If[ListQ[letterChannels] && ListQ[formChannels],
    multiquadraticStripLetterDLogCertificateValidQ[certificate, letter,
      form, variables, epsilon, letterChannels, formChannels],
    multiquadraticStripLetterDLogCertificateValidQ[certificate, letter,
      form, variables, epsilon]];
  If[mode =!= "Exact" &&
      TrueQ[certificateValidQ],
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
   admissible, retainedChannels, recomposed, channelCertificateQ},
  If[TrueQ[compactQ],
    admission = multiquadraticStripCompactDLogAdmission[letterRecord, form,
      variables, epsilon, admissionMode];
    If[TrueQ[admission["Admitted"]],
      retainedChannels = Lookup[letterRecord, "DLogChannels", $Failed];
      channelCertificateQ = Lookup[Lookup[letterRecord, "DLogCertificate",
          <||>], "Schema", None] ===
          $multiquadraticStripLetterDLogChannelSchema &&
        Lookup[admission, "Method", None] === "CertifiedTag";
      If[MatchQ[retainedChannels, {_List, _List}] &&
          Dimensions[retainedChannels] === {2, 2^Length[roots]} &&
          FreeQ[retainedChannels, $Failed],
        recomposed = Quiet[
          multiquadraticFieldCompose[#1, roots] & /@ retainedChannels];
        (* Admission has already bound the raw letter and both channel
           payloads (V2), or checked dlog(letter) exactly (V1/fallback).
           Recompose only the channels that will actually be installed and
           demand exact identity with the requested one-form. *)
        If[SameQ[recomposed, form],
          channels = retainedChannels]];
      If[! MatchQ[channels, {_List, _List}],
        If[TrueQ[channelCertificateQ],
          admission = <|"Admitted" -> False,
            "Reason" -> "RetainedChannelRecompositionMismatch"|>,
          channels = multiquadraticStripLetterChannelPair[
            admission["Letter"], roots, variables]]];
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
  prefix = {$multiquadraticStripABIVersion, variables, epsilon,
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
  If[shardCount >= 2 && TrueQ[Quiet[taskBrokerActiveQ[]]] &&
      Quiet[Check[taskBrokerFreeKernels[], 0]] >= 1,
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
  {$multiquadraticStripABIVersion, algebraFingerprint,
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
      {$multiquadraticStripABIVersion, variables, epsilon, denominator},
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
  "CompiledFormsShapeFingerprint", "ABIVersion"}];

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
   that shows sharding pays at all.  It has not been shown to pay on the
   one real shape measured -- see
   Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   MultiquadraticMeasurementNarratives_2026-08-26.md, section 3.
   Production sharding waits for those measurements (Codex 14:30, shard
   row; agreed disposition).  Until then this option exists so the shard
   PATH stays exercised by its tests and does not rot, and the LEGACY
   compiler beside it is retained for the same reason and for no other:
   both are DIFFERENTIAL-TEST ORACLES, held to the current compiler by
   Tests/Multiquadratic/t_multiquadratic_prepare_core.wls, with no production caller. *)
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
          Counts[Replace[Lookup[oneData, "Paths", {}],
            Except[_List] -> {}]], <||>]|>]];
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
    "OneFormPaths" -> Counts[Replace[Lookup[oneData, "Paths", {}],
      Except[_List] -> {}]],
    "CompactAdmissions" -> Counts[Replace[
      Lookup[oneData, "CompactAdmissions", {}], Except[_List] -> {}]],
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
    "ABIVersion" -> $multiquadraticStripABIVersion,
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
  requiredKeys = {"SourceFile", "ABIVersion", "ABIFingerprint",
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
    assembly["ABIVersion"] === $multiquadraticStripABIVersion &&
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
(* Provider-independent row layout and coefficient ABI                 *)
(* ------------------------------------------------------------------ *)

(* A coefficient provider is compatible with a row layout only when it
   speaks exactly the same multiquadratic basis.  The ROOT BRANCH is part
   of that basis: Root -> -Sqrt[delta] has the same square but reverses all
   odd grades.  Consequently this payload fingerprints both the square and
   the chosen root expression, as well as every object whose order fixes a
   coefficient tensor axis. *)
multiquadraticStripCoefficientABIPayload[
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    dimensions : {_Integer, _Integer}, oneForms_List,
    gaugeDenominator_] := Module[
  {rules, rootSquares, rootExpressions, canonicalSquares,
   canonicalExpressions, canonicalForms, canonicalDenominator},
  If[Min[dimensions] < 1 ||
      ! AllTrue[roots, AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
        KeyExistsQ[#1, "RootSquare"] &&
        TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[$Failed]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootExpressions = Lookup[roots, "Root", {}];
  canonicalSquares = multiquadraticStripCanonicalText[#1, rules] & /@
    rootSquares;
  canonicalExpressions = multiquadraticStripCanonicalText[#1, rules] & /@
    rootExpressions;
  canonicalForms = Map[multiquadraticStripCanonicalText[#1, rules] &,
    oneForms, {2}];
  canonicalDenominator = multiquadraticStripCanonicalText[
    gaugeDenominator, rules];
  If[! FreeQ[{canonicalSquares, canonicalExpressions, canonicalForms,
      canonicalDenominator}, $Failed], Return[$Failed]];
  <|"Schema" -> "MultiquadraticCoefficientABIV1",
    "Variables" -> {"x", "y"}, "Regulator" -> "epsilon",
    "Dimensions" -> dimensions,
    "RootSquares" -> canonicalSquares,
    "RootExpressions" -> canonicalExpressions,
    "RootFingerprints" -> (Hash[#1, "SHA256", "HexString"] & /@
      Transpose[{canonicalSquares, canonicalExpressions}]),
    "RootOrderingFingerprint" -> Hash[
      Transpose[{canonicalSquares, canonicalExpressions}], "SHA256",
      "HexString"],
    "OneForms" -> canonicalForms,
    "GaugeDenominator" -> canonicalDenominator|>
];
multiquadraticStripCoefficientABIPayload[___] := $Failed;

(* The layout owns columns, rows and normalizations, but no coefficient
   source.  In particular it does not claim that characteristic-zero
   channels were compiled. *)
multiquadraticStripAssemblyLayout[preparation_Association] := Module[
  {coefficientPayload, coefficientFingerprint, semantic, result},
  If[! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparationABI"]]];
  coefficientPayload = multiquadraticStripCoefficientABIPayload[
    preparation["Variables"], preparation["Regulator"],
    preparation["Roots"], preparation["Dimensions"],
    preparation["OneForms"], preparation["GaugeDenominator"]];
  If[coefficientPayload === $Failed,
    Return[multiquadraticStripFailure["CoefficientABIFailed"]]];
  coefficientFingerprint = multiquadraticStripFingerprint[
    coefficientPayload];
  result = <|
    "Status" -> "MultiquadraticStripAssemblyLayoutV1",
    "SourceFile" -> $multiquadraticStripSourceFile,
    "ABIVersion" -> $multiquadraticStripABIVersion,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "RootOrderingFingerprint" ->
      coefficientPayload["RootOrderingFingerprint"],
    "Record" -> preparation["Record"], "Roots" -> preparation["Roots"],
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> preparation["Variables"],
    "Regulator" -> preparation["Regulator"],
    "Dimensions" -> preparation["Dimensions"],
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
    "CoefficientABIPayload" -> coefficientPayload,
    "CoefficientABIFingerprint" -> coefficientFingerprint|>;
  semantic = KeyTake[result, {"ABIVersion", "ABIFingerprint",
    "AlgebraABIFingerprint", "RootOrderingFingerprint", "RootCount",
    "GradeCount", "Dimensions", "GaugeSupport", "GaugeUnknownCount",
    "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
    "ColumnOrder", "RowOrder", "CoefficientABIFingerprint"}];
  Append[result, "LayoutFingerprint" ->
    multiquadraticStripFingerprint[semantic]]
];
multiquadraticStripAssemblyLayout[___] :=
  multiquadraticStripFailure["InvalidAssemblyLayoutArguments"];

multiquadraticStripAssemblyLayoutValidQ[layout_Association] := Module[
  {dimensions, rootCount, gradeCount, support, oneForms, expectedGauge,
   expectedResidue, coefficientPayload, coefficientFingerprint, semantic},
  If[Lookup[layout, "Status", None] =!=
      "MultiquadraticStripAssemblyLayoutV1", Return[False]];
  dimensions = Lookup[layout, "Dimensions", $Failed];
  rootCount = Lookup[layout, "RootCount", $Failed];
  gradeCount = Lookup[layout, "GradeCount", $Failed];
  support = Lookup[layout, "GaugeSupport", $Failed];
  oneForms = Lookup[layout, "OneForms", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! IntegerQ[rootCount] || rootCount < 0 ||
      rootCount > $multiquadraticStripMaximumRootCount ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {} ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[oneForms] Times @@ dimensions;
  coefficientPayload = multiquadraticStripCoefficientABIPayload[
    layout["Variables"], layout["Regulator"], layout["Roots"], dimensions,
    oneForms, layout["GaugeDenominator"]];
  If[coefficientPayload === $Failed, Return[False]];
  coefficientFingerprint = multiquadraticStripFingerprint[
    coefficientPayload];
  semantic = KeyTake[layout, {"ABIVersion", "ABIFingerprint",
    "AlgebraABIFingerprint", "RootOrderingFingerprint", "RootCount",
    "GradeCount", "Dimensions", "GaugeSupport", "GaugeUnknownCount",
    "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
    "ColumnOrder", "RowOrder", "CoefficientABIFingerprint"}];
  TrueQ[
    Lookup[layout, "ABIVersion", None] ===
      $multiquadraticStripABIVersion &&
    Lookup[layout, "AlgebraABIFingerprint", None] ===
      multiquadraticAlgebraABIFingerprint[] &&
    Lookup[layout, "CoefficientABIPayload", None] === coefficientPayload &&
    Lookup[layout, "CoefficientABIFingerprint", None] ===
      coefficientFingerprint &&
    Lookup[layout, "RootOrderingFingerprint", None] ===
      coefficientPayload["RootOrderingFingerprint"] &&
    layout["GaugeUnknownCount"] === expectedGauge &&
    layout["ResidueUnknownCount"] === expectedResidue &&
    layout["UnknownCount"] === expectedGauge + expectedResidue &&
    layout["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    layout["ColumnOrder"] === multiquadraticStripColumnOrder[dimensions,
      gradeCount, support, Length[oneForms]] &&
    layout["RowOrder"] === multiquadraticStripRowOrder[dimensions,
      gradeCount] &&
    Lookup[layout, "LayoutFingerprint", None] ===
      multiquadraticStripFingerprint[semantic]]
];
multiquadraticStripAssemblyLayoutValidQ[___] := False;

(* As with coefficient providers, a layout is deeply authenticated at the
   sampling/reconstruction boundary.  Point rows need only its immutable
   dimensions and fingerprints; rebuilding canonical ABI payloads for every
   point is pure repetition. *)
$multiquadraticStripTrustedLayoutEvaluation = False;

multiquadraticStripAssemblyLayoutHotValidQ[layout_Association] := TrueQ[
  Lookup[layout, "Status", None] ===
    "MultiquadraticStripAssemblyLayoutV1" &&
  MatchQ[Lookup[layout, "Dimensions", None], {_Integer, _Integer}] &&
  Min[layout["Dimensions"]] >= 1 &&
  IntegerQ[Lookup[layout, "RootCount", None]] && layout["RootCount"] >= 0 &&
  Lookup[layout, "GradeCount", None] === 2^layout["RootCount"] &&
  IntegerQ[Lookup[layout, "UnknownCount", None]] &&
  layout["UnknownCount"] >= 0 &&
  StringQ[Lookup[layout, "LayoutFingerprint", None]] &&
  StringQ[Lookup[layout, "CoefficientABIFingerprint", None]]];
multiquadraticStripAssemblyLayoutHotValidQ[___] := False;

multiquadraticStripAssemblyLayoutEvaluationValidQ[layout_] := If[
  TrueQ[$multiquadraticStripTrustedLayoutEvaluation],
  multiquadraticStripAssemblyLayoutHotValidQ[layout],
  multiquadraticStripAssemblyLayoutValidQ[layout]];

(* A compiled-channel provider is an authenticated compatibility wrapper;
   it remains the characteristic-zero differential oracle, not a second
   row assembler. *)
multiquadraticStripCompiledProvider[assembly_Association] := Module[
  {preparation, layout, result},
  If[! multiquadraticStripCompiledValidQ[assembly],
    Return[multiquadraticStripFailure["InvalidCompiledAssembly"]]];
  preparation = Lookup[assembly, "Preparation", $Failed];
  layout = multiquadraticStripAssemblyLayout[preparation];
  If[! multiquadraticStripAssemblyLayoutValidQ[layout], Return[layout]];
  result = <|"Status" -> "MultiquadraticCoefficientProviderV1",
    "Kind" -> "CompiledChannel", "Assembly" -> assembly,
    "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
    "RootCount" -> layout["RootCount"],
    "GradeCount" -> layout["GradeCount"],
    "Dimensions" -> layout["Dimensions"]|>;
  Append[result, "ProviderFingerprint" -> multiquadraticStripFingerprint[
    {"CompiledChannel", result["CoefficientABIFingerprint"],
      assembly["AssemblyFingerprint"]}]]
];
multiquadraticStripCompiledProvider[___] :=
  multiquadraticStripFailure["InvalidCompiledProviderArguments"];

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
   right, row, gaugeRow, residueRow, residueRowExpectedWidth, assemblySeconds,
   coefficients, assembled},
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
  (* ---- THE PROVIDER INTERFACE (round-2 item 10).  Everything above is
     the COMPILED-CHANNEL PROVIDER: it answers "what are the coefficient
     values at this point?" out of the compiled exact channels.  The row
     equation itself is one equation and lives in ONE place, which the
     two direct providers feed with the same association. *)
  coefficients = <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "CompiledChannel", "Prime" -> prime,
    "Point" -> {x, y},
    "RegulatorValue" -> epsilonForms["EpsilonValue"],
    "EpsilonMod" -> epsilonMod,
    "RootSquares" -> deltaValues,
    "RootValues" -> If[AllTrue[deltaValues,
      JacobiSymbol[#1, prime] === 1 &],
      multiquadraticSquareRoots[deltaValues, prime],
      ConstantArray[0, Length[deltaValues]]],
    "SplitPointQ" -> AllTrue[deltaValues,
      JacobiSymbol[#1, prime] === 1 &],
    "GaugeDenominator" -> denominatorValue,
    "GaugeLogDerivatives" -> evaluated["GaugeLogDerivatives"],
    "RootLogDerivatives" -> evaluated["RootLogDerivatives"],
    "E" -> evaluated["E"], "C" -> evaluated["C"],
    "BBar" -> evaluated["BBar"], "OneForms" -> evaluated["OneForms"]|>;
  assembled = multiquadraticStripAssemblePointRows[assembly, coefficients];
  If[Lookup[assembled, "Status", None] =!= "AssembledMultiquadraticPointV1",
    Throw[assembled, "MultiquadraticStripAssemblyFailure"]];
  Join[assembled,
    <|"AssemblySeconds" -> N[AbsoluteTime[] - startTime]|>]
], "MultiquadraticStripAssemblyFailure"];

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
  "SplitPointsOnly" -> False,
  "SplitSparseEvaluationPlan" -> Automatic,
  "MaximumMatrixBytes" -> Automatic
};

multiquadraticStripAssembleSample[assembly_Association, epsilonValue_,
    prime_Integer, opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, epsilonForms, pointCount, maximumAttempts,
   randomSeed, candidatePoints, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0, point,
   pointResult, pointRows, pointRight, normalization, matrix, right,
   pointRanges, equationCount, splitOnly, maximumMatrixBytes,
   matrixEstimate, matrixAdmission},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[OptionValue["SplitSparseEvaluationPlan"] =!= Automatic,
    Return[multiquadraticStripFailure[
      "SplitSparseEvaluationPlanNotApplicable"]]];
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
  maximumMatrixBytes = Replace[OptionValue["MaximumMatrixBytes"],
    Automatic :> $multiquadraticStripSampleMaximumBytes];
  If[! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[maximumAttempts] ||
      maximumAttempts < pointCount || ! IntegerQ[randomSeed] ||
      ! (NumericQ[maximumMatrixBytes] && maximumMatrixBytes > 0) ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyOptions"]]];
  matrixEstimate = multiquadraticStripSampleSizeEstimate[pointCount,
    assembly["EquationsPerPoint"], Length[assembly["Normalizations"]],
    assembly["UnknownCount"]];
  matrixAdmission = multiquadraticStripSampleAdmissionRefusal[
    matrixEstimate, maximumMatrixBytes];
  If[AssociationQ[matrixAdmission], Return[matrixAdmission]];
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
  matrix = Developer`ToPackedArray[If[Length[normalization[[1]]] === 0,
    pointRows, Join[pointRows, Normal[normalization[[1]]]]]];
  right = Developer`ToPackedArray[Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = assembly["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "ABIFingerprint" -> assembly["ABIFingerprint"],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "ABIVersion" -> assembly["ABIVersion"], "Prime" -> prime,
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

(* The provider-backed production sampler.  This is the only five-
   argument implementation: every provider supplies coefficients, and
   every coefficient record reaches multiquadraticStripAssemblePointRows.
   The historical compiled signature above remains a compatibility
   oracle until its callers are migrated, but contains no independent
   row equation. *)
multiquadraticStripAssembleSample[layout_Association,
    provider_Association, epsilonValue_, prime_Integer,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, pointCount, maximumAttempts,
   randomSeed, candidatePoints, splitOnly, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0,
   point, preflight, coefficients, pointResult, normalization,
   normalizationSeconds, pointRows, pointRight, matrix, right, pointRanges,
   equationCount, preflightSeconds = 0., coefficientSeconds = 0.,
   rowSeconds = 0., largeEntryEvaluations = 0, preflightRejects = 0,
   providerCalls = 0, imageStoreKey, trainingImageKeys,
   splitCompileAttempts = 0, splitCompileCacheHits = 0,
   splitCompileCacheMisses = 0, splitSparseSuccesses = 0,
   splitSubstitutionFallbacks = 0, splitCompileSeconds = 0.,
   splitEvaluationSeconds = 0., splitFallbackSeconds = 0.,
   requestedSplitPlan, splitPlan = Automatic, splitPlanBuildSeconds = 0.,
   splitPlanBuildCompileInvocations = 0,
   splitUniqueLeafEvaluationSeconds = 0., splitOccurrenceGatherSeconds = 0.,
   splitBundleCompositionSeconds = 0., splitNativeSuccesses = 0,
   preflightBatch, nativeBatch, suppliedChannels, batchIndex,
   candidateExhausted = False, nativeBatchEligible = False,
   nativeBatchAttemptCount = 0, nativeBatchSuccessCount = 0,
   nativeBatchFallbackCount = 0, nativeBatchSeconds = 0.,
   nativePlanWriteSeconds = 0., nativePointWriteSeconds = 0.,
   nativeAdapterSeconds = 0., nativeResponseReadSeconds = 0.,
   coefficientBatch, nativeRowBatch, suppliedPointResults,
   nativeRowBatchEligible = False, nativeRowBatchAttemptCount = 0,
   nativeRowBatchSuccessCount = 0, nativeRowBatchFallbackCount = 0,
   nativeRowBatchSeconds = 0., nativeRowInputWriteSeconds = 0.,
   nativeRowAdapterSeconds = 0., nativeRowResponseReadSeconds = 0.,
   nativePreflightBatch, nativePreflightRecords = Automatic,
   nativeCandidatePoints, nativePreflightBatchEligible = False,
   nativePreflightBatchAttemptCount = 0,
   nativePreflightBatchSuccessCount = 0,
   nativePreflightBatchFallbackCount = 0,
   nativePreflightBatchSeconds = 0.,
   nativePreflightCompileSeconds = 0.,
   nativePreflightEvaluationSeconds = 0.,
   nativePreflightDecodeSeconds = 0.,
   deferredNativeSourceQ = False, deferredNativeBatch,
   deferredNativeBBarBatch = Automatic,
   deferredNativeBatchAttemptCount = 0,
   deferredNativeBatchSuccessCount = 0,
   deferredNativeBatchFailureCount = 0,
   deferredNativeBatchSeconds = 0.,
   deferredNativeParseSeconds = 0.,
   deferredNativeEvaluationSeconds = 0., maximumMatrixBytes,
   matrixEstimate, matrixAdmission},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticStripAssemblyLayoutEvaluationValidQ[layout] ||
      ! multiquadraticStripProviderEvaluationValidQ[provider] ||
      ! PrimeQ[prime] ||
      (Lookup[provider, "RootCount", 0] > 0 && Mod[prime, 4] =!= 3) ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[multiquadraticStripFailure["InvalidProviderSampleInput"]]];
  If[layout["CoefficientABIFingerprint"] =!=
      provider["CoefficientABIFingerprint"],
    Return[multiquadraticStripFailure["ProviderLayoutMismatch",
      <|"LayoutFingerprint" -> layout["LayoutFingerprint"],
        "ProviderFingerprint" -> provider["ProviderFingerprint"],
        "ExpectedCoefficientABI" -> layout["CoefficientABIFingerprint"],
        "ObservedCoefficientABI" ->
          provider["CoefficientABIFingerprint"],
        "LargeEntryEvaluationCount" -> 0|>]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(layout["UnknownCount"] + layout["EquationsPerPoint"])/
      layout["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  splitOnly = TrueQ[OptionValue["SplitPointsOnly"]];
  requestedSplitPlan = OptionValue["SplitSparseEvaluationPlan"];
  maximumMatrixBytes = Replace[OptionValue["MaximumMatrixBytes"],
    Automatic :> $multiquadraticStripSampleMaximumBytes];
  If[! IntegerQ[pointCount] || pointCount < 1 ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount ||
      ! IntegerQ[randomSeed] ||
      ! (NumericQ[maximumMatrixBytes] && maximumMatrixBytes > 0) ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticStripFailure["InvalidSampleAssemblyOptions"]]];
  matrixEstimate = multiquadraticStripSampleSizeEstimate[pointCount,
    layout["EquationsPerPoint"], Length[layout["Normalizations"]],
    layout["UnknownCount"]];
  matrixAdmission = multiquadraticStripSampleAdmissionRefusal[
    matrixEstimate, maximumMatrixBytes];
  If[AssociationQ[matrixAdmission], Return[matrixAdmission]];
  deferredNativeSourceQ =
    AssociationQ[Lookup[provider, "DeferredPreparation", None]];
  If[provider["Kind"] === "SplitBranch",
    If[deferredNativeSourceQ,
      (* The ordinary split plan includes every deferred-bundle operand.
         Native BBar makes those leaves dead work; E/C and one-forms take
         the existing unplanned direct path until a filtered plan is shown
         to pay on a physical block. *)
      If[! MemberQ[{Automatic, None}, requestedSplitPlan],
        Return[multiquadraticStripFailure[
          "SplitSparseEvaluationPlanNotApplicable"]]];
      splitPlan = Automatic,
      Which[
      requestedSplitPlan === Automatic,
        {splitPlanBuildSeconds, splitPlan} = AbsoluteTiming[
          Block[{$multiquadraticStripTrustedProviderEvaluation = True},
            multiquadraticStripSplitSparseEvaluationPlan[provider, prime]]];
        If[Lookup[splitPlan, "Status", None] =!=
            "MultiquadraticSplitSparseEvaluationPlanV1",
          Return[multiquadraticStripFailure[
            "SplitSparseEvaluationPlanBuildFailed",
            <|"Detail" -> splitPlan|>]]];
        splitPlanBuildCompileInvocations = Lookup[splitPlan,
          "BuildCompileInvocationCount", 0],
      requestedSplitPlan === None,
        splitPlan = Automatic,
      AssociationQ[requestedSplitPlan] &&
          multiquadraticStripSplitSparseEvaluationPlanValidQ[
            requestedSplitPlan, provider, prime],
        splitPlan = requestedSplitPlan,
      True,
        Return[multiquadraticStripFailure[
          "InvalidSplitSparseEvaluationPlan",
          <|"ProviderFingerprint" -> provider["ProviderFingerprint"],
            "Prime" -> prime|>]]]];
    If[splitPlan =!= Automatic &&
        Lookup[splitPlan, "CoefficientABIFingerprint", None] =!=
          layout["CoefficientABIFingerprint"],
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanLayoutMismatch"]]],
    If[! MemberQ[{Automatic, None}, requestedSplitPlan],
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]]];
  nativeBatchEligible = AssociationQ[splitPlan] &&
    StringQ[multiquadraticStripNativeSparseBinary[]] &&
    AllTrue[Lookup[splitPlan["Leaves"], "Compiled", {}], AssociationQ];
  nativeRowBatchEligible =
    StringQ[multiquadraticStripNativeRowBinary[]];
  nativePreflightBatchEligible = provider["Kind"] === "SplitBranch" &&
    StringQ[multiquadraticStripNativeSparseBinary[]] &&
    maximumAttempts <= 100000;
  imageStoreKey = multiquadraticStripFingerprint[{
    layout["LayoutFingerprint"], provider["ProviderFingerprint"], prime,
    epsilonValue, randomSeed, pointCount, maximumAttempts, splitOnly,
    If[candidatePoints === Automatic, Automatic,
      Mod[candidatePoints, prime]]}];
  Block[{$multiquadraticStripTrustedProviderEvaluation = True,
      $multiquadraticStripTrustedLayoutEvaluation = True,
      $multiquadraticStripTrustedSplitSparsePlanEvaluation =
        (splitPlan =!= Automatic)},
   BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    If[nativePreflightBatchEligible,
      nativeCandidatePoints = If[candidatePoints === Automatic,
        Table[RandomInteger[{2, prime - 2}, 2], {maximumAttempts}],
        Take[candidatePoints, UpTo[maximumAttempts]]];
      nativePreflightBatchAttemptCount++;
      nativePreflightBatch = multiquadraticStripNativePreflightBatch[
        provider, epsilonValue, prime, nativeCandidatePoints, 1];
      nativePreflightBatchSeconds += Lookup[nativePreflightBatch,
        "Seconds", 0.];
      candidatePoints = nativeCandidatePoints;
      If[Lookup[nativePreflightBatch, "Status", None] ===
          "MultiquadraticNativePreflightBatchV1",
        nativePreflightBatchSuccessCount++;
        nativePreflightRecords = nativePreflightBatch["Records"];
        preflightSeconds += nativePreflightBatch["Seconds"];
        nativePreflightCompileSeconds += Lookup[nativePreflightBatch,
          "CompileSeconds", 0.];
        nativePreflightEvaluationSeconds += Lookup[nativePreflightBatch,
          "NativeBatchSeconds", 0.];
        nativePreflightDecodeSeconds += Lookup[nativePreflightBatch,
          "DecodeSeconds", 0.],
        nativePreflightBatchFallbackCount++]];
    While[Length[accepted] < pointCount && attempts < maximumAttempts &&
        ! candidateExhausted,
      preflightBatch = {};
      While[Length[preflightBatch] < pointCount - Length[accepted] &&
          attempts < maximumAttempts && ! candidateExhausted,
        attempts++;
        If[candidatePoints === Automatic,
          point = RandomInteger[{2, prime - 2}, 2],
          candidateIndex++;
          If[candidateIndex > Length[candidatePoints],
            candidateExhausted = True; Break[]];
          point = candidatePoints[[candidateIndex]]];
        preflight = If[ListQ[nativePreflightRecords],
          nativePreflightRecords[[candidateIndex]],
          multiquadraticStripProviderPreflight[provider,
            epsilonValue, prime, point]];
        preflightSeconds += Lookup[preflight, "PreflightSeconds", 0.];
        If[Lookup[preflight, "Status", None] =!=
            "MultiquadraticProviderPreflightV1",
          preflightRejects++;
          AppendTo[rejected, Join[<|"Point" -> Mod[point, prime],
            "FailureReason" -> Lookup[preflight, "Status", None],
            "LargeEntryEvaluationCount" -> 0|>,
            KeyTake[preflight, {"DeltaValues", "RootIndices"}]]];
          Continue[]];
        If[splitOnly && ! TrueQ[preflight["SplitPointQ"]],
          preflightRejects++;
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> "PointNotSplitOverPrime",
            "LargeEntryEvaluationCount" -> 0|>];
          Continue[]];
        AppendTo[preflightBatch, preflight]];
      If[preflightBatch === {}, Continue[]];
      suppliedChannels = ConstantArray[Automatic, Length[preflightBatch]];
      If[nativeBatchEligible,
        nativeBatchAttemptCount++;
        nativeBatch = multiquadraticStripNativeSparseEvaluateBatch[
          splitPlan, preflightBatch, 1];
        nativeBatchSeconds += Lookup[nativeBatch, "Seconds", 0.];
        If[Lookup[nativeBatch, "Status", None] ===
            "MultiquadraticNativeSparseBatchV1",
          nativeBatchSuccessCount++;
          coefficientSeconds += Lookup[nativeBatch, "Seconds", 0.];
          splitUniqueLeafEvaluationSeconds += Lookup[nativeBatch,
            "Seconds", 0.];
          nativePlanWriteSeconds += Lookup[nativeBatch,
            "PlanWriteSeconds", 0.];
          nativePointWriteSeconds += Lookup[nativeBatch,
            "PointWriteSeconds", 0.];
          nativeAdapterSeconds += Lookup[nativeBatch,
            "AdapterSeconds", 0.];
          nativeResponseReadSeconds += Lookup[nativeBatch,
            "ResponseReadSeconds", 0.];
          Do[If[VectorQ[nativeBatch["LeafStatuses"][[batchIndex]],
                #1 === 0 &],
              suppliedChannels[[batchIndex]] =
                nativeBatch["Channels"][[batchIndex]],
              nativeBatchFallbackCount++],
            {batchIndex, Length[preflightBatch]}],
          nativeBatchFallbackCount++]];
      deferredNativeBBarBatch = Automatic;
      If[deferredNativeSourceQ,
        deferredNativeBatchAttemptCount++;
        deferredNativeBatch =
          multiquadraticStripNativeDeferredEvaluateBatch[provider,
            preflightBatch];
        deferredNativeBatchSeconds += Lookup[deferredNativeBatch,
          "Seconds", 0.];
        coefficientSeconds += Lookup[deferredNativeBatch, "Seconds", 0.];
        If[Lookup[deferredNativeBatch, "Status", None] ===
              "MultiquadraticNativeDeferredBatchV1" &&
            Length[Lookup[deferredNativeBatch, "BBarBatch", {}]] ===
              Length[preflightBatch],
          deferredNativeBatchSuccessCount++;
          deferredNativeBBarBatch = deferredNativeBatch["BBarBatch"];
          deferredNativeParseSeconds += Lookup[deferredNativeBatch,
            "ParseSeconds", 0.];
          deferredNativeEvaluationSeconds += Lookup[deferredNativeBatch,
            "EvaluationSeconds", 0.],
          deferredNativeBatchFailureCount++]];
      coefficientBatch = Table[
        preflight = preflightBatch[[batchIndex]];
        point = preflight["Point"];
        providerCalls++;
        coefficients = If[deferredNativeSourceQ &&
            ! ListQ[deferredNativeBBarBatch],
          multiquadraticStripFailure[
            "NativeDeferredForcingUnavailable",
            <|"Point" -> point, "Prime" -> prime,
              "RegulatorValue" -> epsilonValue,
              "Detail" -> If[AssociationQ[deferredNativeBatch],
                KeyDrop[deferredNativeBatch, "BBarBatch"],
                deferredNativeBatch]|>],
          If[ListQ[suppliedChannels[[batchIndex]]],
            multiquadraticStripPlannedProviderChannels[provider, preflight,
              splitPlan, suppliedChannels[[batchIndex]]],
            multiquadraticStripProviderChannels[provider, epsilonValue,
              prime, point, preflight, splitPlan,
              If[deferredNativeSourceQ, "NativeDeferredAST",
                Automatic]]]];
        coefficientSeconds += Lookup[coefficients, "Seconds", 0.];
        splitCompileAttempts += Lookup[coefficients,
          "SplitSparseCompileAttemptCount", 0];
        splitCompileCacheHits += Lookup[coefficients,
          "SplitSparseCompileCacheHitCount", 0];
        splitCompileCacheMisses += Lookup[coefficients,
          "SplitSparseCompileCacheMissCount", 0];
        splitSparseSuccesses += Lookup[coefficients,
          "SplitSparseEvaluationCount", 0];
        splitNativeSuccesses += Lookup[coefficients,
          "SplitSparseNativeEvaluationCount", 0];
        splitSubstitutionFallbacks += Lookup[coefficients,
          "SplitSubstitutionFallbackCount", 0];
        splitCompileSeconds += Lookup[coefficients,
          "SplitSparseCompileSeconds", 0.];
        splitEvaluationSeconds += Lookup[coefficients,
          "SplitSparseEvaluationSeconds", 0.];
        splitFallbackSeconds += Lookup[coefficients,
          "SplitSubstitutionFallbackSeconds", 0.];
        splitUniqueLeafEvaluationSeconds += Lookup[coefficients,
          "SplitSparseUniqueLeafEvaluationSeconds", 0.];
        splitOccurrenceGatherSeconds += Lookup[coefficients,
          "SplitSparseOccurrenceGatherSeconds", 0.];
        splitBundleCompositionSeconds += Lookup[coefficients,
          "SplitSparseDeferredBundleCompositionSeconds", 0.];
        largeEntryEvaluations += Lookup[coefficients,
          "LargeEntryEvaluationCount", 0];
        If[deferredNativeSourceQ &&
            Lookup[coefficients, "Status", None] ===
              "MultiquadraticPointCoefficientsV1",
          coefficients = Join[coefficients, <|
            "BBar" -> deferredNativeBBarBatch[[batchIndex]],
            "ForcingProvider" -> "NativeDeferredASTV1",
            "NativeDeferredASTTermCount" ->
              Lookup[deferredNativeBatch, "TermCount", 0],
            "NativeDeferredASTUniqueExpressionCount" ->
              Lookup[deferredNativeBatch, "UniqueExpressionCount", 0]|>]];
        coefficients,
        {batchIndex, Length[preflightBatch]}];
      suppliedPointResults = ConstantArray[Automatic,
        Length[preflightBatch]];
      If[nativeRowBatchEligible && AllTrue[coefficientBatch,
          Lookup[#1, "Status", None] ===
            "MultiquadraticPointCoefficientsV1" &],
        nativeRowBatchAttemptCount++;
        nativeRowBatch = multiquadraticStripNativeRowAssembleBatch[
          layout, coefficientBatch, 1];
        nativeRowBatchSeconds += Lookup[nativeRowBatch, "Seconds", 0.];
        If[Lookup[nativeRowBatch, "Status", None] ===
            "MultiquadraticNativeRowBatchV1",
          nativeRowBatchSuccessCount++;
          nativeRowInputWriteSeconds += Lookup[nativeRowBatch,
            "InputWriteSeconds", 0.];
          nativeRowAdapterSeconds += Lookup[nativeRowBatch,
            "AdapterSeconds", 0.];
          nativeRowResponseReadSeconds += Lookup[nativeRowBatch,
            "ResponseReadSeconds", 0.];
          suppliedPointResults = Table[
            multiquadraticStripPointResult[layout,
              coefficientBatch[[batchIndex]],
              nativeRowBatch["Rows"][[batchIndex]],
              nativeRowBatch["RightHandSides"][[batchIndex]],
              nativeRowBatch["Seconds"]/Length[coefficientBatch]],
            {batchIndex, Length[coefficientBatch]}],
          nativeRowBatchFallbackCount++]];
      Do[
        preflight = preflightBatch[[batchIndex]];
        point = preflight["Point"];
        coefficients = coefficientBatch[[batchIndex]];
        If[Lookup[coefficients, "Status", None] =!=
            "MultiquadraticPointCoefficientsV1",
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> Lookup[coefficients, "Status", None],
            "LargeEntryEvaluationCount" -> Lookup[coefficients,
              "LargeEntryEvaluationCount", 0]|>];
          Continue[]];
        pointResult = If[AssociationQ[suppliedPointResults[[batchIndex]]],
          suppliedPointResults[[batchIndex]],
          multiquadraticStripAssemblePointRows[layout, coefficients]];
        rowSeconds += Lookup[pointResult, "AssemblySeconds", 0.];
        If[Lookup[pointResult, "Status", None] =!=
            "AssembledMultiquadraticPointV1",
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> Lookup[pointResult, "Status", None],
            "LargeEntryEvaluationCount" -> Lookup[coefficients,
              "LargeEntryEvaluationCount", 0]|>];
          Continue[]];
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> "DuplicatePointModuloPrime",
            "LargeEntryEvaluationCount" -> Lookup[coefficients,
              "LargeEntryEvaluationCount", 0]|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, Join[pointResult,
            <|"ProviderFingerprint" -> provider["ProviderFingerprint"],
              "CoefficientABIFingerprint" ->
                provider["CoefficientABIFingerprint"],
              "SplitPointQ" -> preflight["SplitPointQ"],
              "PreflightSeconds" -> preflight["PreflightSeconds"],
              "CoefficientSeconds" -> Lookup[coefficients, "Seconds", 0.],
              "LargeEntryEvaluationCount" -> Lookup[coefficients,
                "LargeEntryEvaluationCount", 0]|>]]],
        {batchIndex, Length[preflightBatch]}]
      ]
   ]];
  If[Length[accepted] < pointCount,
    Return[multiquadraticStripFailure["InsufficientProviderPoints",
      <|"LayoutFingerprint" -> layout["LayoutFingerprint"],
        "ProviderFingerprint" -> provider["ProviderFingerprint"],
        "AcceptedPointCount" -> Length[accepted],
        "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
        "PreflightRejectCount" -> preflightRejects,
        "LargeEntryEvaluationCount" -> largeEntryEvaluations,
        "ProviderCallCount" -> providerCalls|>]]];
  {normalizationSeconds, normalization} = AbsoluteTiming[
    multiquadraticStripNormalizationRows[layout, epsilonValue, prime]];
  If[normalization === $Failed,
    Return[multiquadraticStripFailure["NormalizationValueSingular"]]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[If[Length[normalization[[1]]] === 0,
    pointRows, Join[pointRows, Normal[normalization[[1]]]]]];
  right = Developer`ToPackedArray[
    Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = layout["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount,
    index equationCount}, {index, Length[accepted]}];
  trainingImageKeys = Table[
    {layout["LayoutFingerprint"], provider["ProviderFingerprint"], prime,
      epsilonValue, accepted[[index, "Point"]]},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "ABIFingerprint" -> layout["ABIFingerprint"],
    "LayoutFingerprint" -> layout["LayoutFingerprint"],
    "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
    "Provider" -> provider["Kind"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "ImageStoreKey" -> imageStoreKey,
    "TrainingImageKeys" -> trainingImageKeys,
    "ABIVersion" -> layout["ABIVersion"], "Prime" -> prime,
    "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> multiquadraticStripModRational[epsilonValue, prime],
    "Matrix" -> matrix, "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointDeltaValues" -> Lookup[accepted, "DeltaValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "SplitPointsOnly" -> splitOnly,
    "PreflightRejectCount" -> preflightRejects,
    "ProviderCallCount" -> providerCalls,
    "LargeEntryEvaluationCount" -> largeEntryEvaluations,
    "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
    "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
    "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
    "SplitSparseEvaluationCount" -> splitSparseSuccesses,
    "SplitSparseNativeEvaluationCount" -> splitNativeSuccesses,
    "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
    "SplitSparseCompileSeconds" -> splitCompileSeconds,
    "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
    "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
    "SplitSparsePlanFingerprint" -> If[AssociationQ[splitPlan],
      splitPlan["PlanFingerprint"], None],
    "SplitSparsePlanCacheHit" -> If[AssociationQ[splitPlan],
      TrueQ[Lookup[splitPlan, "PlanCacheHit", False]], False],
    "SplitSparsePlanUniqueLeafCount" -> If[AssociationQ[splitPlan],
      splitPlan["UniqueLeafCount"], 0],
    "SplitSparsePlanOccurrenceCount" -> If[AssociationQ[splitPlan],
      splitPlan["OccurrenceCount"], 0],
    "SplitSparsePlanCompileInvocationCount" -> If[AssociationQ[splitPlan],
      splitPlanBuildCompileInvocations, 0],
    "SplitSparsePlanFallbackLeafCount" -> If[AssociationQ[splitPlan],
      splitPlan["FallbackLeafCount"], 0],
    "SplitSparsePlanConstructionSeconds" -> splitPlanBuildSeconds,
    "SplitSparseNativeBatchEligible" -> nativeBatchEligible,
    "SplitSparseNativeBatchAttemptCount" -> nativeBatchAttemptCount,
    "SplitSparseNativeBatchSuccessCount" -> nativeBatchSuccessCount,
    "SplitSparseNativeBatchFallbackCount" -> nativeBatchFallbackCount,
    "SplitSparseNativeBatchSeconds" -> nativeBatchSeconds,
    "SplitSparseNativePlanWriteSeconds" -> nativePlanWriteSeconds,
    "SplitSparseNativePointWriteSeconds" -> nativePointWriteSeconds,
    "SplitSparseNativeAdapterSeconds" -> nativeAdapterSeconds,
    "SplitSparseNativeResponseReadSeconds" -> nativeResponseReadSeconds,
    "NativeRowBatchEligible" -> nativeRowBatchEligible,
    "NativeRowBatchAttemptCount" -> nativeRowBatchAttemptCount,
    "NativeRowBatchSuccessCount" -> nativeRowBatchSuccessCount,
    "NativeRowBatchFallbackCount" -> nativeRowBatchFallbackCount,
    "NativeRowBatchSeconds" -> nativeRowBatchSeconds,
    "NativeRowInputWriteSeconds" -> nativeRowInputWriteSeconds,
    "NativeRowAdapterSeconds" -> nativeRowAdapterSeconds,
    "NativeRowResponseReadSeconds" -> nativeRowResponseReadSeconds,
    "NativePreflightBatchEligible" -> nativePreflightBatchEligible,
    "NativePreflightBatchAttemptCount" -> nativePreflightBatchAttemptCount,
    "NativePreflightBatchSuccessCount" -> nativePreflightBatchSuccessCount,
    "NativePreflightBatchFallbackCount" -> nativePreflightBatchFallbackCount,
    "NativePreflightBatchSeconds" -> nativePreflightBatchSeconds,
    "NativePreflightCompileSeconds" -> nativePreflightCompileSeconds,
    "NativePreflightEvaluationSeconds" ->
      nativePreflightEvaluationSeconds,
    "NativePreflightDecodeSeconds" -> nativePreflightDecodeSeconds,
    "NativeDeferredSourceQ" -> deferredNativeSourceQ,
    "NativeDeferredBatchAttemptCount" ->
      deferredNativeBatchAttemptCount,
    "NativeDeferredBatchSuccessCount" ->
      deferredNativeBatchSuccessCount,
    "NativeDeferredBatchFailureCount" ->
      deferredNativeBatchFailureCount,
    "NativeDeferredBatchSeconds" -> deferredNativeBatchSeconds,
    "NativeDeferredParseSeconds" -> deferredNativeParseSeconds,
    "NativeDeferredEvaluationSeconds" ->
      deferredNativeEvaluationSeconds,
    "SplitSparseUniqueLeafEvaluationSeconds" ->
      splitUniqueLeafEvaluationSeconds,
    "SplitSparseOccurrenceGatherSeconds" -> splitOccurrenceGatherSeconds,
    "SplitSparseDeferredBundleCompositionSeconds" ->
      splitBundleCompositionSeconds,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> layout["ColumnOrder"],
    "RowOrder" -> layout["RowOrder"],
    "PhaseSeconds" -> <|"Preflight" -> preflightSeconds,
      "NativePreflightBatch" -> nativePreflightBatchSeconds,
      "CoefficientEvaluation" -> coefficientSeconds,
      "RowAssembly" -> rowSeconds,
      "Normalization" -> normalizationSeconds,
      "SplitSparsePlanConstruction" -> splitPlanBuildSeconds,
      "SplitSparseNativeBatch" -> nativeBatchSeconds,
      "NativeDeferredBatch" -> deferredNativeBatchSeconds,
      "NativeRowBatch" -> nativeRowBatchSeconds,
      "SplitSparseUniqueLeafEvaluation" ->
        splitUniqueLeafEvaluationSeconds,
      "SplitSparseOccurrenceGather" -> splitOccurrenceGatherSeconds,
      "SplitSparseDeferredBundleComposition" ->
        splitBundleCompositionSeconds|>,
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

(* The rectangular first image is the one place where a full affine RREF is
   unavoidable.  CFFR1 is already the authenticated native adapter used by
   FiniteFieldStripSolve.wl; this layer only translates its response into the
   multiquadratic affine ABI.  Automatic uses the declared matrix-entry
   threshold below.  Its fallback is deliberately narrow: adapter absence or
   execution/authentication failure may use Wolfram, but an adapter exit 5 is
   the mathematical verdict for that image and is never retried by a different
   solver. *)
$multiquadraticStripPlanDiscoveryNativeMinimumEntries = 250000;

multiquadraticStripPlanDiscoveryBackendDecision[requested_, threads_,
    dimensions : {_Integer, _Integer}, minimumEntries_: Automatic] := Module[
  {threshold = Replace[minimumEntries, Automatic :>
      $multiquadraticStripPlanDiscoveryNativeMinimumEntries], entries,
   available, reported},
  reported = If[MemberQ[{Automatic, "Wolfram", "FLINTAffineRREF"}, requested],
    requested, If[StringQ[requested], requested,
      ToString[Head[requested], InputForm]]];
  If[! MemberQ[{Automatic, "Wolfram", "FLINTAffineRREF"}, requested],
    Return[multiquadraticStripFailure["InvalidPlanDiscoveryBackend",
      <|"PlanDiscoveryBackendRequested" -> reported,
        "AllowedBackends" -> {Automatic, "Wolfram", "FLINTAffineRREF"}|>]]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure["InvalidPlanDiscoveryBackendThreads",
      <|"PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendThreads" -> threads,
        "AllowedRange" -> {1, 8}|>]]];
  If[! IntegerQ[threshold] || threshold < 0 || Min[dimensions] < 0,
    Return[multiquadraticStripFailure["InvalidPlanDiscoveryBackendThreshold",
      <|"PlanDiscoveryBackendMinimumEntries" -> threshold,
        "MatrixDimensions" -> dimensions|>]]];
  entries = Times @@ dimensions;
  available = StringQ[finiteFieldStripCFFRBinary[]] &&
    FileExistsQ[finiteFieldStripCFFRBinary[]];
  Which[
    requested === "Wolfram",
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendUsed" -> "Wolfram",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> False,
        "PlanDiscoveryBackendSelectionReason" -> "ExplicitWolfram",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    requested === "FLINTAffineRREF" && ! available,
      multiquadraticStripFailure["PlanDiscoveryBackendUnavailable",
        <|"PlanDiscoveryBackendRequested" -> requested,
          "PlanDiscoveryBackendUsed" -> None,
          "PlanDiscoveryBackendThreads" -> threads,
          "AvailableBackends" -> {"Wolfram"},
          "MatrixEntries" -> entries,
          "NativeMinimumMatrixEntries" -> threshold|>],
    requested === "FLINTAffineRREF",
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> False,
        "PlanDiscoveryBackendSelectionReason" -> "ExplicitNative",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    available && entries >= threshold,
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> Automatic,
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> True,
        "PlanDiscoveryBackendSelectionReason" -> "AutomaticSizeThreshold",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    True,
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> Automatic,
        "PlanDiscoveryBackendUsed" -> "Wolfram",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> True,
        "PlanDiscoveryBackendSelectionReason" -> If[available,
          "AutomaticBelowSizeThreshold", "AutomaticAdapterUnavailable"],
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>]
];
multiquadraticStripPlanDiscoveryBackendDecision[___] :=
  multiquadraticStripFailure["InvalidPlanDiscoveryBackendDecisionArguments"];

multiquadraticStripNativeAffineSolve[matrix_?MatrixQ, right_List,
    prime_Integer, gaugeUnknownCount_Integer, residueUnknownCount_Integer,
    threads_Integer] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[matrix], preference,
   runSeconds, run, response, verificationSeconds, verification, solution},
  If[! PrimeQ[prime] || Length[dimensions] =!= 2 ||
      dimensions[[1]] =!= Length[right] ||
      dimensions[[2]] =!= gaugeUnknownCount + residueUnknownCount ||
      ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure["InvalidNativeAffineInput"]]];
  preference = Join[Reverse[Range[gaugeUnknownCount]],
    gaugeUnknownCount + Range[residueUnknownCount]];
  {runSeconds, run} = AbsoluteTiming[finiteFieldStripCFFRRun[matrix, right,
    prime, preference, threads, Automatic]];
  If[Lookup[run, "Status", None] =!= "OK",
    Return[Join[run, <|"PlanDiscoveryBackendRequested" ->
        "FLINTAffineRREF", "PlanDiscoveryBackendUsed" ->
        "FLINTAffineRREF", "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendSeconds" -> runSeconds,
        "MatrixDimensions" -> dimensions|>]]];
  response = run["Response"];
  {verificationSeconds, verification} = AbsoluteTiming[
    finiteFieldStripCFFRVerify[matrix, right, prime, response, Automatic]];
  If[Lookup[verification, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure["PlanDiscoveryBackendVerificationFailed",
      <|"PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "BackendFailure" -> verification,
        "AdapterBinding" -> KeyTake[run, {"Protocol", "Nonce",
          "RequestSHA256", "ResponseSHA256", "AdapterSourceSHA256",
          "AdapterBinarySHA256", "Threads"}],
        "PhaseSeconds" -> <|"Adapter" -> runSeconds,
          "FullOriginalRowReplay" -> verificationSeconds|>|>]]];
  solution = <|"Status" -> "MultiquadraticAffineSolution",
    "Prime" -> prime, "MatrixDimensions" -> dimensions,
    "Rank" -> response["Rank"], "Nullity" -> response["Nullity"],
    "PivotColumns" -> response["PivotColumns"],
    "FreeColumns" -> response["FreeColumns"],
    "PivotSignature" -> Hash[response["PivotColumns"], "SHA256",
      "HexString"],
    "ParticularSolution" -> response["ParticularSolution"],
    "NullspaceBasis" -> response["NullspaceBasis"],
    "IndependentEquationRows" -> response["IndependentEquationRows"],
    "NativeNormalizationColumns" -> response["NormalizationColumns"],
    "FullResidualZero" -> True, "NullspaceResidualZero" -> True,
    "PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
    "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
    "PlanDiscoveryBackendThreads" -> run["Threads"],
    "PlanDiscoveryBackendBinding" -> KeyTake[run, {"Protocol", "Nonce",
      "RequestSHA256", "ResponseSHA256", "AdapterSourceSHA256",
      "AdapterBinarySHA256", "Threads"}],
    "PhaseSeconds" -> <|"Adapter" -> runSeconds,
      "FullOriginalRowReplay" -> verificationSeconds|>,
    "PlanDiscoveryBackendSeconds" -> N[AbsoluteTime[] - startTime]|>;
  solution
];
multiquadraticStripNativeAffineSolve[___] :=
  multiquadraticStripFailure["InvalidNativeAffineArguments"];

multiquadraticStripPlanDiscoverySolve[matrix_?MatrixQ, right_List,
    prime_Integer, gaugeUnknownCount_Integer, residueUnknownCount_Integer,
    requested_, threads_Integer, minimumEntries_: Automatic] := Module[
  {startTime = AbsoluteTime[], decision, native, wolframSeconds, wolfram,
   fallbackReason = None},
  decision = multiquadraticStripPlanDiscoveryBackendDecision[requested,
    threads, Dimensions[matrix], minimumEntries];
  If[Lookup[decision, "Status", None] =!= "OK", Return[decision]];
  If[decision["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF",
    native = multiquadraticStripNativeAffineSolve[matrix, right, prime,
      gaugeUnknownCount, residueUnknownCount, threads];
    If[Lookup[native, "Status", None] === "MultiquadraticAffineSolution",
      Return[Join[native, KeyTake[decision, {
        "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
        "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
        "MatrixEntries", "NativeMinimumMatrixEntries"}]]]];
    (* Exit 5 is an exact verdict about this affine image.  It is not an
       adapter failure and therefore has no Automatic fallback. *)
    If[Lookup[native, "Status", None] === "InconsistentModularSystem",
      Return[Join[native, KeyTake[decision, {
        "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
        "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
        "MatrixEntries", "NativeMinimumMatrixEntries"}]]]];
    If[! TrueQ[decision["PlanDiscoveryBackendFallbackAllowed"]],
      Return[multiquadraticStripFailure["PlanDiscoveryBackendFailed",
        Join[KeyTake[decision, {"PlanDiscoveryBackendRequested",
          "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads",
          "PlanDiscoveryBackendSelectionReason", "MatrixEntries",
          "NativeMinimumMatrixEntries"}], <|"BackendFailure" -> native|>]]]];
    fallbackReason = Lookup[native, "Status", "NativeExecutionFailed"]];
  If[fallbackReason === None &&
      decision["PlanDiscoveryBackendSelectionReason"] ===
        "AutomaticAdapterUnavailable",
    fallbackReason = "CFFRAdapterUnavailable"];
  {wolframSeconds, wolfram} = AbsoluteTiming[
    multiquadraticStripAffineSolve[matrix, right, prime]];
  If[! AssociationQ[wolfram], Return[wolfram]];
  Join[wolfram, <|"PlanDiscoveryBackendRequested" -> requested,
    "PlanDiscoveryBackendUsed" -> "Wolfram",
    "PlanDiscoveryBackendThreads" -> threads,
    "PlanDiscoveryBackendSelectionReason" ->
      decision["PlanDiscoveryBackendSelectionReason"],
    "PlanDiscoveryBackendFallbackReason" -> fallbackReason,
    "MatrixEntries" -> decision["MatrixEntries"],
    "NativeMinimumMatrixEntries" -> decision["NativeMinimumMatrixEntries"],
    "PlanDiscoveryBackendSeconds" -> wolframSeconds,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>]
];
multiquadraticStripPlanDiscoverySolve[___] :=
  multiquadraticStripFailure["InvalidPlanDiscoverySolveArguments"];

(* A support rung needs only consistency evidence, not a selected affine
   representative.  A successful native response supplies both ranks.  On
   exit 5 CFFR1 has already established affine inconsistency; because there is
   exactly one RHS column, rank([A|b])-rank(A) is then exactly one.  Absolute
   ranks are deliberately left Missing instead of paying a second homogeneous
   RREF solely for telemetry.  The inconsistent verdict is never sent to
   Wolfram. *)
multiquadraticStripAffineConsistencyEvidence[matrix_?MatrixQ, right_List,
    prime_Integer, gaugeUnknownCount_Integer, residueUnknownCount_Integer,
    requested_, threads_Integer, minimumEntries_: Automatic] := Module[
  {startTime = AbsoluteTime[], solution},
  solution = multiquadraticStripPlanDiscoverySolve[matrix, right, prime,
    gaugeUnknownCount, residueUnknownCount, requested, threads,
    minimumEntries];
  Which[
    Lookup[solution, "Status", None] === "MultiquadraticAffineSolution",
      <|"Status" -> "ProviderSupportImageConsistent", "Prime" -> prime,
        "Rank" -> solution["Rank"], "AugmentedRank" -> solution["Rank"],
        "Defect" -> 0, "MatrixDimensions" -> Dimensions[matrix],
        "Solution" -> solution,
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> solution["PlanDiscoveryBackendUsed"],
        "PlanDiscoveryBackendThreads" ->
          solution["PlanDiscoveryBackendThreads"],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    Lookup[solution, "Status", None] === "InconsistentModularSystem" &&
        Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
          "FLINTAffineRREF",
      <|"Status" -> "ProviderSupportImageInconsistent", "Prime" -> prime,
        "Rank" -> Missing["NotComputedForInconsistentImage"],
        "AugmentedRank" -> Missing["NotComputedForInconsistentImage"],
        "Defect" -> 1, "MatrixDimensions" -> Dimensions[matrix],
        "DefectEvidence" -> "SingleRightHandSideAffineInconsistency",
        "InconsistentVerdict" -> KeyDrop[solution,
          {"RequestFile", "ResponseFile"}],
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    Lookup[solution, "Status", None] === "InconsistentModularSystem",
      <|"Status" -> "ProviderSupportImageInconsistent", "Prime" -> prime,
        "Rank" -> solution["Rank"],
        "AugmentedRank" -> solution["AugmentedRank"],
        "Defect" -> solution["AugmentedRank"] - solution["Rank"],
        "MatrixDimensions" -> Dimensions[matrix],
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> solution["PlanDiscoveryBackendUsed"],
        "PlanDiscoveryBackendThreads" ->
          solution["PlanDiscoveryBackendThreads"],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    True, solution]
];
multiquadraticStripAffineConsistencyEvidence[___] :=
  multiquadraticStripFailure["InvalidAffineConsistencyEvidenceArguments"];

(* A pilot image pays for one full RREF.  It fixes three pieces of the
   affine ABI which must not drift with the regulator or the prime: an
   independent set of equation rows, the pivot signature, and the columns
   which define the canonical affine section.  Later images solve the one
   square constrained core with nullity+1 right-hand sides.  The additional
   right-hand sides reconstruct a basis of the kernel in the SAME section;
   checking them against every original row certifies that the generic rank
   has neither risen nor fallen without doing another RREF. *)
multiquadraticStripConstrainedPlanValidQ[plan_Association] := Module[
  {unknownCount, equationCount, rank, nullity, rows, columns, pivotColumns,
   freeColumns, semantic},
  If[Lookup[plan, "Status", None] =!=
      "MultiquadraticConstrainedAffinePlanV1", Return[False]];
  unknownCount = Lookup[plan, "UnknownCount", $Failed];
  equationCount = Lookup[plan, "EquationCount", $Failed];
  rank = Lookup[plan, "Rank", $Failed];
  nullity = Lookup[plan, "Nullity", $Failed];
  rows = Lookup[plan, "IndependentEquationRows", $Failed];
  columns = Lookup[plan, "NormalizationColumns", $Failed];
  pivotColumns = Lookup[plan, "PivotColumns", $Failed];
  freeColumns = Lookup[plan, "FreeColumns", $Failed];
  If[! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! IntegerQ[equationCount] || equationCount < 1 ||
      ! IntegerQ[rank] || rank < 0 || rank > Min[unknownCount, equationCount] ||
      ! IntegerQ[nullity] || nullity =!= unknownCount - rank ||
      ! VectorQ[rows, IntegerQ] || Length[rows] =!= rank ||
      ! DuplicateFreeQ[rows] || ! AllTrue[rows, 1 <= #1 <= equationCount &] ||
      ! VectorQ[columns, IntegerQ] || Length[columns] =!= nullity ||
      ! DuplicateFreeQ[columns] ||
      ! AllTrue[columns, 1 <= #1 <= unknownCount &] ||
      ! VectorQ[pivotColumns, IntegerQ] || Length[pivotColumns] =!= rank ||
      ! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, 1 <= #1 <= unknownCount &] ||
      ! VectorQ[freeColumns, IntegerQ] || Length[freeColumns] =!= nullity ||
      Sort[Join[pivotColumns, freeColumns]] =!= Range[unknownCount] ||
      ! StringQ[Lookup[plan, "PivotSignature", None]] ||
      ! StringQ[Lookup[plan, "LayoutFingerprint", None]] ||
      ! StringQ[Lookup[plan, "ProviderFingerprint", None]], Return[False]];
  semantic = KeyTake[plan, {"Status", "UnknownCount", "EquationCount",
    "Rank", "Nullity", "IndependentEquationRows", "NormalizationColumns",
    "PivotColumns", "FreeColumns", "PivotSignature", "LayoutFingerprint",
    "ProviderFingerprint"}];
  semantic = Join[semantic, KeyTake[plan, {
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendBinding"}]];
  TrueQ[Lookup[plan, "PlanFingerprint", None] ===
    multiquadraticStripFingerprint[semantic]]
];
multiquadraticStripConstrainedPlanValidQ[___] := False;

(* Native follower solves inherit the adapter's exact constrained-core
   verification.  They do not repeat an all-original-row matrix product;
   the reconstructed block is accepted later at fresh modular points.
   The Wolfram fallback still certifies all rows itself. *)
multiquadraticStripFullResidualEvidenceValidQ[evidence_Association,
    prime_Integer] := Module[{method, nullity},
  method = Lookup[evidence, "FullResidualCheckMethod", None];
  nullity = Lookup[evidence, "Nullity", $Failed];
  If[! PrimeQ[prime] || ! IntegerQ[nullity] || nullity < 0,
    Return[False]];
  If[method === "NativeCoreVerifiedFreivaldsAllRows",
    Return[Lookup[evidence, "ConstrainedSolveBackendUsed", None] ===
        "FLINT" &&
      TrueQ[Lookup[evidence, "NativeCoreResidualZero", False]] &&
      TrueQ[Lookup[evidence, "NativeCoreResidualExact", False]] &&
      TrueQ[Lookup[evidence, "FullResidualZero", False]] &&
      IntegerQ[Lookup[evidence, "FreivaldsProjections", None]] &&
      Lookup[evidence, "FreivaldsProjections", 0] >= 2]];
  (* records written before 2026-09-02 carry the core-only method *)
  If[method === "NativeConstrainedCoreVerified",
    Return[Lookup[evidence, "ConstrainedSolveBackendUsed", None] ===
        "FLINT" &&
      TrueQ[Lookup[evidence, "NativeCoreResidualZero", False]] &&
      TrueQ[Lookup[evidence, "NativeCoreResidualExact", False]]]];
  MemberQ[{"ExactMatrixMatrix", "ExactFullAffineRREF"}, method] &&
    TrueQ[Lookup[evidence, "FullResidualZero", False]] &&
    TrueQ[Lookup[evidence, "NullspaceResidualZero", False]] &&
    TrueQ[Lookup[evidence, "FullResidualExact", False]]
];
multiquadraticStripFullResidualEvidenceValidQ[___] := False;

multiquadraticStripConstrainedAffineSolve[matrix_?MatrixQ, right_List,
    prime_Integer, plan_Association] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[matrix], unknownCount,
   equationCount, rank, nullity, rows, columns, selector, core, rhsMatrix,
   solveSeconds = 0., residualSeconds = 0.,
   nativeSolveSeconds = 0., wolframSolveSeconds = 0.,
   particular, nullspace, normalizationOK, backendThreads,
   backendDecision, backendUsed = "Wolfram", backendFallbackReason = None,
   nativeAttempted = False, nativeValidationFailure = None,
   nativeValidationRecovered = False, fullResidualReplayCount = 0,
   residualCheckEvidence = {},
   nativeSolution = $Failed, wolframSolution = $Failed, validation = <||>,
   solutionShapeQ, nativeSolutionShapeQ, validateSolution,
   validationFailureReason, needWolfram = True},
  If[! PrimeQ[prime] || ! multiquadraticStripConstrainedPlanValidQ[plan],
    Return[multiquadraticStripFailure["InvalidConstrainedAffinePlan"]]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right] ||
      ! MatrixQ[matrix, IntegerQ] || ! VectorQ[right, IntegerQ],
    Return[multiquadraticStripFailure[
      "ConstrainedAffineDimensionMismatch"]]];
  {equationCount, unknownCount} = dimensions;
  If[{equationCount, unknownCount} =!=
      Lookup[plan, {"EquationCount", "UnknownCount"}, {$Failed, $Failed}],
    Return[multiquadraticStripFailure["ConstrainedPlanDimensionMismatch",
      <|"Expected" -> Lookup[plan, {"EquationCount", "UnknownCount"}],
        "Observed" -> dimensions|>]]];
  rank = plan["Rank"]; nullity = plan["Nullity"];
  rows = plan["IndependentEquationRows"];
  columns = plan["NormalizationColumns"];
  selector = SparseArray[MapIndexed[{First[#2], #1} -> 1 &, columns],
    {nullity, unknownCount}];
  core = If[nullity === 0, matrix[[rows]], Join[matrix[[rows]], selector]];
  rhsMatrix = If[nullity === 0, List /@ right[[rows]],
    Join[
      Join[List /@ right[[rows]], ConstantArray[0, {rank, nullity}], 2],
      Join[ConstantArray[0, {nullity, 1}], IdentityMatrix[nullity], 2]]];
  If[Dimensions[core] =!= {unknownCount, unknownCount} ||
      Dimensions[rhsMatrix] =!= {unknownCount, nullity + 1},
    Return[multiquadraticStripFailure["ConstrainedCoreDimensionMismatch",
      <|"CoreDimensions" -> Dimensions[core],
        "RightHandSideDimensions" -> Dimensions[rhsMatrix]|>]]];
  solutionShapeQ[candidate_] := MatrixQ[candidate, IntegerQ] &&
    Dimensions[candidate] === {unknownCount, nullity + 1};
  nativeSolutionShapeQ[candidate_] := solutionShapeQ[candidate] &&
    AllTrue[Flatten[candidate], 0 <= #1 < prime &];
  validateSolution[candidate_, nativeCoreVerified_: False] := Module[
    {candidateMatrix = Mod[candidate, prime], candidateParticular,
     candidateNullspace, candidateNormalizationOK, targetMatrix,
     residual, residualZero, replaySeconds, certificateSummary},
    candidateParticular = candidateMatrix[[All, 1]];
    candidateNullspace = If[nullity === 0, {},
      Transpose[candidateMatrix[[All, 2 ;;]]]];
    candidateNormalizationOK =
      candidateParticular[[columns]] === ConstantArray[0, nullity] &&
      (nullity === 0 ||
        candidateNullspace[[All, columns]] === IdentityMatrix[nullity]);
    If[! TrueQ[candidateNormalizationOK],
      Return[<|"Status" -> "NormalizationMismatch",
        "SolutionMatrix" -> candidateMatrix,
        "ParticularSolution" -> candidateParticular,
        "NullspaceBasis" -> candidateNullspace,
        "NormalizationOK" -> False|>]];
    If[TrueQ[nativeCoreVerified],
      (* U2 (user decision 2026-09-02): a native solve is verified on the
         constrained core only by the adapter; the ORIGINAL rows are now
         replayed as well, by Freivalds projection -- two random row
         combinations r.M.X == r.B mod p -- at O(m n) per projection
         instead of the O(m n (nullity+1)) exact product, with a false
         acceptance probability of at most p^-2 per image (p >= 2^30). *)
      targetMatrix = Join[List /@ Mod[right, prime],
        ConstantArray[0, {equationCount, nullity}], 2];
      {replaySeconds, residualZero} = AbsoluteTiming[Module[{ok = True},
        Do[Module[{r = RandomInteger[{1, prime - 1}, equationCount], lhs, rhs},
          lhs = Mod[Mod[r . matrix, prime] . candidateMatrix, prime];
          rhs = Mod[r . targetMatrix, prime];
          If[lhs =!= rhs, ok = False]], {$multiquadraticStripFreivaldsProjections}];
        ok]];
      residualSeconds += replaySeconds;
      fullResidualReplayCount++;
      certificateSummary = <|
        "Status" -> If[residualZero, "Accepted", "FullResidualNonzero"],
        "FullResidualZero" -> residualZero,
        "NullspaceResidualZero" -> residualZero,
        "FullResidualCheckMethod" -> "NativeCoreVerifiedFreivaldsAllRows",
        "FullResidualExact" -> False,
        "FreivaldsProjections" -> $multiquadraticStripFreivaldsProjections,
        "NativeCoreResidualZero" -> True,
        "NativeCoreResidualExact" -> True, "Seconds" -> replaySeconds|>;
      AppendTo[residualCheckEvidence, certificateSummary];
      Return[Join[certificateSummary, <|
        "SolutionMatrix" -> candidateMatrix,
        "ParticularSolution" -> candidateParticular,
        "NullspaceBasis" -> candidateNullspace,
        "NormalizationOK" -> True|>]]];
    targetMatrix = Join[List /@ Mod[right, prime],
      ConstantArray[0, {equationCount, nullity}], 2];
    {replaySeconds, residual} = AbsoluteTiming[
      Mod[matrix . candidateMatrix - targetMatrix, prime]];
    residualSeconds += replaySeconds;
    fullResidualReplayCount++;
    residualZero = MatrixQ[residual, #1 === 0 &];
    certificateSummary = <|
      "Status" -> If[residualZero, "Accepted", "FullResidualNonzero"],
      "FullResidualZero" -> residualZero,
      "NullspaceResidualZero" -> residualZero,
      "FullResidualCheckMethod" -> "ExactMatrixMatrix",
      "FullResidualExact" -> True,
      "NonzeroResidualCount" -> If[residualZero, 0,
        Count[Flatten[residual], Except[0]]],
      "ResidualFingerprint" -> If[residualZero, None,
        multiquadraticStripFingerprint[residual]],
      "Seconds" -> replaySeconds|>;
    AppendTo[residualCheckEvidence, certificateSummary];
    Join[certificateSummary, <|
      "SolutionMatrix" -> candidateMatrix,
      "ParticularSolution" -> candidateParticular,
      "NullspaceBasis" -> candidateNullspace,
      "NormalizationOK" -> True|>]
  ];
  validationFailureReason["NormalizationMismatch"] :=
    "FLINTNormalizationValidationFailed";
  validationFailureReason["FullResidualNonzero"] :=
    "FLINTFullResidualValidationFailed";
  validationFailureReason[_] := "FLINTResponseStructureInvalid";
  (* The same authenticated fixed-core adapter already used by the rational
     finite-field solver is substantially faster for the very wide
     nullity+1 systems occurring in direct multiquadratic reconstruction.
     Its protocol admits at most eight native threads.  Automatic
     remains fail-open only to the historical Wolfram solve; every imported
     solution is provisional until the canonical normalization and all-row
     residual checks below. *)
  backendThreads = Lookup[plan, "PlanDiscoveryBackendThreads", 2];
  If[! IntegerQ[backendThreads], backendThreads = 2];
  backendThreads = Clip[backendThreads, {1, 8}];
  backendDecision = finiteFieldStripBackendDecision[Automatic,
    backendThreads, unknownCount];
  If[Lookup[backendDecision, "Status", None] === "OK" &&
      Lookup[backendDecision, "UseBackend", None] === "FLINT",
    nativeAttempted = True;
    {nativeSolveSeconds, nativeSolution} = AbsoluteTiming[
      finiteFieldStripFLINTSolve[core, rhsMatrix, prime, backendThreads]];
    solveSeconds += nativeSolveSeconds;
    If[nativeSolutionShapeQ[nativeSolution],
      validation = validateSolution[nativeSolution, True];
      If[Lookup[validation, "Status", None] === "Accepted",
        backendUsed = "FLINT";
        needWolfram = False,
        nativeValidationFailure = validationFailureReason[
          Lookup[validation, "Status", None]];
        backendFallbackReason = nativeValidationFailure],
      backendFallbackReason = If[nativeSolution === $Failed,
        "FLINTExecutionFailed", "FLINTResponseStructureInvalid"];
      If[nativeSolution =!= $Failed,
        nativeValidationFailure = backendFallbackReason]],
    If[Lookup[backendDecision, "Status", None] =!= "OK",
      backendFallbackReason = Lookup[backendDecision, "Status",
        "BackendDecisionFailed"],
      If[unknownCount >= 256 &&
          Lookup[backendDecision, "UseBackend", None] === "Wolfram",
        backendFallbackReason = "FLINTAdapterUnavailable"]]];
  If[needWolfram,
    {wolframSolveSeconds, wolframSolution} = AbsoluteTiming[
      Quiet[Check[LinearSolve[core, rhsMatrix, Modulus -> prime], $Failed]]];
    solveSeconds += wolframSolveSeconds;
    backendUsed = "Wolfram";
    If[solutionShapeQ[wolframSolution],
      validation = validateSolution[wolframSolution];
      If[Lookup[validation, "Status", None] === "Accepted" &&
          nativeValidationFailure =!= None,
        nativeValidationRecovered = True],
      validation = <|"Status" -> "StructureInvalid"|>]];
  If[Lookup[validation, "Status", None] === "StructureInvalid",
    Return[multiquadraticStripFailure["ConstrainedCoreSingular",
      <|"Prime" -> prime, "CoreDimensions" -> Dimensions[core],
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" -> backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  particular = validation["ParticularSolution"];
  nullspace = validation["NullspaceBasis"];
  normalizationOK = validation["NormalizationOK"];
  If[! TrueQ[normalizationOK],
    Return[multiquadraticStripFailure[
      "ConstrainedPlanNormalizationMismatch",
      <|"Prime" -> prime, "NormalizationColumns" -> columns,
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" ->
          backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  If[Lookup[validation, "Status", None] === "FullResidualNonzero",
    Return[multiquadraticStripFailure["ConstrainedFullResidualNonzero",
      <|"Prime" -> prime,
        "NonzeroResidualCount" -> Lookup[validation,
          "NonzeroResidualCount", Missing["NotRecorded"]],
        "ResidualFingerprint" -> Lookup[validation,
          "ResidualFingerprint", Missing["NotRecorded"]],
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" ->
          backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  <|"Status" -> "MultiquadraticConstrainedAffineSolution",
    "Prime" -> prime, "Rank" -> rank, "Nullity" -> nullity,
    "PivotSignature" -> plan["PivotSignature"],
    "PivotColumns" -> plan["PivotColumns"],
    "FreeColumns" -> plan["FreeColumns"],
    "NormalizationColumns" -> columns,
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace,
    "CanonicalValues" -> particular,
    "PlanFingerprint" -> plan["PlanFingerprint"],
    "SolvePath" -> "ConstrainedCoreMultiRHS",
    "ConstrainedSolveBackendRequested" -> Automatic,
    "ConstrainedSolveBackendUsed" -> backendUsed,
    "ConstrainedSolveBackendThreads" -> backendThreads,
    "ConstrainedSolveBackendFallbackReason" -> backendFallbackReason,
    "ConstrainedSolveNativeAttempted" -> nativeAttempted,
    "ConstrainedSolveNativeValidationFailure" ->
      nativeValidationFailure,
    "ConstrainedSolveNativeValidationRecovered" ->
      nativeValidationRecovered,
    "ConstrainedSolveFullResidualReplayCount" -> fullResidualReplayCount,
    "ConstrainedSolveNativeCoreReplayCount" -> 0,
    "FullResidualZero" -> Lookup[validation, "FullResidualZero",
      Missing["NotChecked"]],
    "NullspaceResidualZero" -> Lookup[validation,
      "NullspaceResidualZero", Missing["NotChecked"]],
    "NativeCoreResidualZero" -> Lookup[validation,
      "NativeCoreResidualZero", Missing["NotApplicable"]],
    "NativeCoreResidualExact" -> Lookup[validation,
      "NativeCoreResidualExact", Missing["NotApplicable"]],
    "FullResidualCheckMethod" -> validation["FullResidualCheckMethod"],
    "FullResidualExact" -> validation["FullResidualExact"],
    "FreivaldsProjections" -> Lookup[validation, "FreivaldsProjections",
      Missing["NotApplicable"]],
    "FullResidualChecks" -> residualCheckEvidence,
    "PhaseSeconds" -> <|"CoreSolve" -> solveSeconds,
      "NativeCoreSolve" -> nativeSolveSeconds,
      "WolframCoreSolve" -> wolframSolveSeconds,
      "FullResidual" -> residualSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripConstrainedAffineSolve[___] :=
  multiquadraticStripFailure["InvalidConstrainedAffineArguments"];

multiquadraticStripConstrainedPlanDiscover[matrix_?MatrixQ, right_List,
    solution_Association, normalizationColumns_List, prime_Integer,
    layoutFingerprint_String, providerFingerprint_String,
    suppliedIndependentRows_: Automatic] := Module[
  {dimensions = Dimensions[matrix], rank, nullity, independentRows, semantic,
   plan, canonical, replay},
  If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution" ||
      ! PrimeQ[prime] || Length[dimensions] =!= 2 ||
      dimensions[[1]] =!= Length[right],
    Return[multiquadraticStripFailure[
      "InvalidConstrainedPlanPilot"]]];
  rank = solution["Rank"]; nullity = solution["Nullity"];
  If[Length[normalizationColumns] =!= nullity ||
      ! VectorQ[normalizationColumns, IntegerQ] ||
      ! DuplicateFreeQ[normalizationColumns] ||
      ! AllTrue[normalizationColumns, 1 <= #1 <= dimensions[[2]] &],
    Return[multiquadraticStripFailure[
      "ConstrainedPlanNormalizationInvalid",
      <|"Nullity" -> nullity,
        "NormalizationColumns" -> normalizationColumns|>]]];
  canonical = Quiet[NormalizeEpsFormAffineSample[
    <|"ParticularSolution" -> solution["ParticularSolution"],
      "NullspaceBasis" -> solution["NullspaceBasis"]|>,
    normalizationColumns, prime]];
  If[canonical === $Failed,
    Return[multiquadraticStripFailure[
      "ConstrainedPlanNormalizationSingular"]]];
  independentRows = Replace[suppliedIndependentRows, Automatic :>
    finiteFieldStripIndependentRows[Normal[matrix], rank, prime]];
  If[independentRows === $Failed || Length[independentRows] =!= rank,
    Return[multiquadraticStripFailure[
      "ConstrainedPlanIndependentRowsFailed"]]];
  If[! VectorQ[independentRows, IntegerQ] ||
      ! DuplicateFreeQ[independentRows] ||
      ! AllTrue[independentRows, 1 <= #1 <= dimensions[[1]] &] ||
      (suppliedIndependentRows === Automatic &&
        MatrixRank[matrix[[independentRows]], Modulus -> prime] =!= rank),
    Return[multiquadraticStripFailure[
      "ConstrainedPlanIndependentRowsInvalid"]]];
  plan = <|"Status" -> "MultiquadraticConstrainedAffinePlanV1",
    "UnknownCount" -> dimensions[[2]], "EquationCount" -> dimensions[[1]],
    "Rank" -> rank, "Nullity" -> nullity,
    "IndependentEquationRows" -> independentRows,
    "NormalizationColumns" -> normalizationColumns,
    "PivotColumns" -> solution["PivotColumns"],
    "FreeColumns" -> solution["FreeColumns"],
    "PivotSignature" -> solution["PivotSignature"],
    "LayoutFingerprint" -> layoutFingerprint,
    "ProviderFingerprint" -> providerFingerprint|>;
  plan = Join[plan, KeyTake[solution, {
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
    "PlanDiscoveryBackendFallbackReason", "PlanDiscoveryBackendSeconds",
    "PlanDiscoveryBackendBinding"}]];
  semantic = Join[KeyTake[plan, {"Status", "UnknownCount", "EquationCount",
    "Rank", "Nullity", "IndependentEquationRows", "NormalizationColumns",
    "PivotColumns", "FreeColumns", "PivotSignature", "LayoutFingerprint",
    "ProviderFingerprint"}], KeyTake[plan, {
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendBinding"}]];
  plan = Append[plan, "PlanFingerprint" ->
    multiquadraticStripFingerprint[semantic]];
  If[! multiquadraticStripConstrainedPlanValidQ[plan],
    Return[multiquadraticStripFailure[
      "ConstrainedPlanAuthenticationFailed"]]];
  If[Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF",
    (* finiteFieldStripCFFRVerify already replayed the imported particular
       and every imported nullspace vector on every original row.  Re-solving
       the pilot's square core here would pay a second O(n^3) elimination and
       add no independent check. *)
    Return[Join[plan, <|"PilotPrime" -> prime,
      "PilotReplaySeconds" -> Lookup[solution,
        "PlanDiscoveryBackendSeconds", Missing["NotMeasured"]],
      "PilotReplayMethod" -> "CFFRFullOriginalRowResiduals",
      "PilotParticularResidualZero" -> True,
      "PilotNullspaceResidualZero" -> True|>]]];
  replay = multiquadraticStripConstrainedAffineSolve[matrix, right, prime,
    plan];
  If[Lookup[replay, "Status", None] =!=
        "MultiquadraticConstrainedAffineSolution" ||
      replay["CanonicalValues"] =!= canonical["ParticularSolution"],
    Return[multiquadraticStripFailure["ConstrainedPlanPilotReplayFailed",
      <|"Detail" -> KeyDrop[replay, {"ParticularSolution",
          "NullspaceBasis", "CanonicalValues"}]|>]]];
  Join[plan, <|"PilotPrime" -> prime,
    "PilotReplaySeconds" -> replay["Seconds"]|>]
];
multiquadraticStripConstrainedPlanDiscover[___] :=
  multiquadraticStripFailure["InvalidConstrainedPlanArguments"];

(* A valid plan which is singular at an exceptional image is not discarded
   and is never replaced by a different section.  The full solver may rescue
   that image only when it reproduces the pilot rank/pivots and the locked
   normalization columns remain nonsingular. *)
multiquadraticStripConstrainedAffineFallback[matrix_?MatrixQ, right_List,
    prime_Integer, plan_Association] := Module[
  {startTime = AbsoluteTime[], planned, full, fullSeconds, canonical},
  If[! multiquadraticStripConstrainedPlanValidQ[plan],
    Return[multiquadraticStripFailure["InvalidConstrainedAffinePlan"]]];
  planned = multiquadraticStripConstrainedAffineSolve[matrix, right, prime,
    plan];
  If[Lookup[planned, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution", Return[planned]];
  {fullSeconds, full} = AbsoluteTiming[
    multiquadraticStripAffineSolve[matrix, right, prime]];
  If[Lookup[full, "Status", None] =!= "MultiquadraticAffineSolution",
    Return[multiquadraticStripFailure["ConstrainedPlanFallbackFailed",
      <|"PlanFailure" -> planned, "FullSolveFailure" -> full,
        "FullSolveSeconds" -> fullSeconds|>]]];
  If[{full["Rank"], full["Nullity"], full["PivotSignature"]} =!=
      {plan["Rank"], plan["Nullity"], plan["PivotSignature"]},
    Return[multiquadraticStripFailure["ConstrainedPlanSignatureMismatch",
      <|"Expected" -> {plan["Rank"], plan["Nullity"],
          plan["PivotSignature"]},
        "Observed" -> {full["Rank"], full["Nullity"],
          full["PivotSignature"]}, "PlanFailure" -> planned|>]]];
  canonical = Quiet[NormalizeEpsFormAffineSample[
    <|"ParticularSolution" -> full["ParticularSolution"],
      "NullspaceBasis" -> full["NullspaceBasis"]|>,
    plan["NormalizationColumns"], prime]];
  If[canonical === $Failed,
    Return[multiquadraticStripFailure[
      "ConstrainedPlanSectionSingular",
      <|"NormalizationColumns" -> plan["NormalizationColumns"],
        "PlanFailure" -> planned|>]]];
  <|"Status" -> "MultiquadraticConstrainedAffineFallbackSolution",
    "Prime" -> prime, "Rank" -> full["Rank"],
    "Nullity" -> full["Nullity"],
    "PivotSignature" -> full["PivotSignature"],
    "PivotColumns" -> full["PivotColumns"],
    "FreeColumns" -> full["FreeColumns"],
    "NormalizationColumns" -> plan["NormalizationColumns"],
    "ParticularSolution" -> full["ParticularSolution"],
    "NullspaceBasis" -> full["NullspaceBasis"],
    "CanonicalValues" -> canonical["ParticularSolution"],
    "PlanFingerprint" -> plan["PlanFingerprint"],
    "SolvePath" -> "FullAffineSameSectionFallback",
    "FallbackReason" -> Lookup[planned, "Status", None],
    "FullResidualZero" -> True, "NullspaceResidualZero" -> True,
    "FullResidualCheckMethod" -> "ExactFullAffineRREF",
    "FullResidualExact" -> True,
    "FullResidualChecks" -> Lookup[planned, "FullResidualChecks", {}],
    "ConstrainedSolveFullResidualReplayCount" -> Lookup[planned,
      "ConstrainedSolveFullResidualReplayCount", 0],
    "ConstrainedSolveNativeCoreReplayCount" -> Lookup[planned,
      "ConstrainedSolveNativeCoreReplayCount", 0],
    "PhaseSeconds" -> <|"ConstrainedAttempt" ->
        Lookup[planned, "Seconds", 0.], "FullFallback" -> fullSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripConstrainedAffineFallback[___] :=
  multiquadraticStripFailure["InvalidConstrainedFallbackArguments"];

(* After the modal image has fixed the affine section, each remaining image
   is independent.  This immutable payload is the complete helper authority;
   it binds the already authenticated layout, provider and constrained plan
   without defining a second solver ABI. *)
multiquadraticStripFollowerImagePayload[layout_Association,
    provider_Association, plan_Association, pointCount_, maximumAttempts_,
    randomSeed_Integer, lockedSignature_List] := Module[{payload},
  If[! multiquadraticStripAssemblyLayoutHotValidQ[layout] ||
      ! multiquadraticStripProviderHotValidQ[provider] ||
      ! multiquadraticStripConstrainedPlanValidQ[plan] ||
      plan["LayoutFingerprint"] =!= layout["LayoutFingerprint"] ||
      plan["ProviderFingerprint"] =!= provider["ProviderFingerprint"] ||
      ! (pointCount === Automatic || IntegerQ[pointCount] && pointCount > 0) ||
      ! (maximumAttempts === Automatic ||
        IntegerQ[maximumAttempts] && maximumAttempts > 0) ||
      lockedSignature =!= {plan["Rank"], plan["Nullity"],
        plan["PivotSignature"]},
    Return[multiquadraticStripFailure[
      "InvalidFollowerImagePayloadArguments"]]];
  payload = <|"Schema" -> "MultiquadraticFollowerImagePayloadV1",
    "LayoutFingerprint" -> layout["LayoutFingerprint"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "PlanFingerprint" -> plan["PlanFingerprint"],
    "PointCount" -> pointCount, "MaximumAttempts" -> maximumAttempts,
    "RandomSeed" -> randomSeed, "LockedSignature" -> lockedSignature,
    "Layout" -> layout, "Provider" -> provider, "Plan" -> plan|>;
  payload
];
multiquadraticStripFollowerImagePayload[___] :=
  multiquadraticStripFailure["InvalidFollowerImagePayloadArguments"];

multiquadraticStripFollowerImagePayloadValidQ[payload_Association] := Module[
  {layout = Lookup[payload, "Layout", $Failed],
   provider = Lookup[payload, "Provider", $Failed],
   plan = Lookup[payload, "Plan", $Failed]},
  If[! AssociationQ[layout] || ! AssociationQ[provider] ||
      ! AssociationQ[plan] ||
      Lookup[payload, "Schema", None] =!=
        "MultiquadraticFollowerImagePayloadV1" ||
      ! multiquadraticStripAssemblyLayoutHotValidQ[layout] ||
      ! multiquadraticStripProviderHotValidQ[provider] ||
      ! multiquadraticStripConstrainedPlanValidQ[plan] ||
      Lookup[payload, "LayoutFingerprint", None] =!=
        layout["LayoutFingerprint"] ||
      Lookup[payload, "ProviderFingerprint", None] =!=
        provider["ProviderFingerprint"] ||
      Lookup[payload, "PlanFingerprint", None] =!= plan["PlanFingerprint"] ||
      plan["LayoutFingerprint"] =!= layout["LayoutFingerprint"] ||
      plan["ProviderFingerprint"] =!= provider["ProviderFingerprint"] ||
      ! (Lookup[payload, "PointCount", None] === Automatic ||
        IntegerQ[Lookup[payload, "PointCount", None]] &&
          payload["PointCount"] > 0) ||
      ! (Lookup[payload, "MaximumAttempts", None] === Automatic ||
        IntegerQ[Lookup[payload, "MaximumAttempts", None]] &&
          payload["MaximumAttempts"] > 0) ||
      ! IntegerQ[Lookup[payload, "RandomSeed", None]] ||
      Lookup[payload, "LockedSignature", None] =!=
        {plan["Rank"], plan["Nullity"], plan["PivotSignature"]},
    Return[False]];
  True
];
multiquadraticStripFollowerImagePayloadValidQ[___] := False;

(* A follower task has no access to the reconstruction's caches, counters or
   telemetry.  It returns only a fingerprint-bound image record; the sampled
   matrix stays on the worker. *)
multiquadraticStripFollowerImageSolve[payload_Association,
    request_Association] := Module[
  {prime = Lookup[request, "Prime", $Failed],
   value = Lookup[request, "RegulatorValue", $Failed], sample,
   samplingTiming, solveResult, eliminationTiming, imageStatus, result,
   record, workerKernelID = Quiet[Check[$KernelID, 0]]},
  If[! multiquadraticStripFollowerImagePayloadValidQ[payload] ||
      ! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticStripFailure[
      "InvalidFollowerImageSolveArguments"]]];
  {samplingTiming, sample} = AbsoluteTiming[
    Block[{$multiquadraticStripTrustedProviderEvaluation = True,
        $multiquadraticStripTrustedLayoutEvaluation = True},
      multiquadraticStripAssembleSample[payload["Layout"],
        payload["Provider"], value, prime,
        "PointCount" -> payload["PointCount"],
        "MaximumAttempts" -> payload["MaximumAttempts"],
        "RandomSeed" -> payload["RandomSeed"]]]];
  If[Lookup[sample, "Status", None] =!=
      "AssembledMultiquadraticSampleV1",
    eliminationTiming = 0.;
    result = <|"Status" -> "ReconstructionSampleFailed",
      "Prime" -> prime, "RegulatorValue" -> value, "Detail" -> sample,
      "SamplingSeconds" -> samplingTiming, "EliminationSeconds" -> 0.,
      "SolvePath" -> "FollowerSampleFailed"|>,
    {eliminationTiming, solveResult} = AbsoluteTiming[
      multiquadraticStripConstrainedAffineFallback[sample["Matrix"],
        sample["RightHandSide"], prime, payload["Plan"]]];
    imageStatus = Lookup[solveResult, "Status", None];
    If[! MemberQ[{"MultiquadraticConstrainedAffineSolution",
          "MultiquadraticConstrainedAffineFallbackSolution"}, imageStatus],
      result = <|"Status" -> "ReconstructionConstrainedSolveFailed",
        "Prime" -> prime, "RegulatorValue" -> value,
        "Detail" -> solveResult, "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming,
        "SolvePath" -> "ConstrainedPlanRejectedImage"|>,
      result = Join[<|"Status" -> "OK", "Prime" -> prime,
        "RegulatorValue" -> value, "EpsilonMod" -> sample["EpsilonMod"],
        "ImageStoreKey" -> sample["ImageStoreKey"],
        "TrainingImageKeys" -> sample["TrainingImageKeys"],
        "SamplePhaseSeconds" -> sample["PhaseSeconds"],
        "Rank" -> solveResult["Rank"],
        "Nullity" -> solveResult["Nullity"],
        "PivotSignature" -> solveResult["PivotSignature"],
        "PivotColumns" -> solveResult["PivotColumns"],
        "FreeColumns" -> solveResult["FreeColumns"],
        "CanonicalValues" -> solveResult["CanonicalValues"],
        "SolvePath" -> solveResult["SolvePath"],
        "PlanFingerprint" -> solveResult["PlanFingerprint"],
        "FullResidualZero" -> solveResult["FullResidualZero"],
        "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming,
        "FollowerSolveKind" -> If[imageStatus ===
          "MultiquadraticConstrainedAffineSolution", "Constrained",
          "FullAffineFallback"]|>,
        KeyTake[solveResult, {"ConstrainedSolveBackendRequested",
          "ConstrainedSolveBackendUsed", "ConstrainedSolveBackendThreads",
          "ConstrainedSolveBackendFallbackReason",
          "ConstrainedSolveNativeAttempted",
          "ConstrainedSolveNativeValidationFailure",
          "ConstrainedSolveNativeValidationRecovered",
          "ConstrainedSolveFullResidualReplayCount",
          "ConstrainedSolveNativeCoreReplayCount",
          "FullResidualCheckMethod", "FullResidualExact",
          "FullResidualChecks", "NullspaceResidualZero",
          "NativeCoreResidualZero", "NativeCoreResidualExact",
          "PhaseSeconds"}]]]];
  record = <|"Status" -> "MultiquadraticFollowerImageRecordV1",
    "Prime" -> prime, "RegulatorValue" -> value,
    "LayoutFingerprint" -> payload["LayoutFingerprint"],
    "ProviderFingerprint" -> payload["ProviderFingerprint"],
    "PlanFingerprint" -> payload["PlanFingerprint"],
    "WorkerKernelID" -> If[IntegerQ[workerKernelID], workerKernelID, 0],
    "Result" -> result|>;
  record
];
multiquadraticStripFollowerImageSolve[___] :=
  multiquadraticStripFailure["InvalidFollowerImageSolveArguments"];

multiquadraticStripFollowerImageAuthenticate[record_Association,
    payload_Association, request_Association] := Module[
  {prime = Lookup[request, "Prime", $Failed],
   value = Lookup[request, "RegulatorValue", $Failed], result, status,
   trainingKeys},
  If[! multiquadraticStripFollowerImagePayloadValidQ[payload] ||
      ! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticStripFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "InvalidAuthenticationArguments"|>]]];
  If[Lookup[record, "Status", None] =!=
        "MultiquadraticFollowerImageRecordV1" ||
      Lookup[record, {"Prime", "RegulatorValue"}, None] =!= {prime, value} ||
      Lookup[record, "LayoutFingerprint", None] =!=
        payload["LayoutFingerprint"] ||
      Lookup[record, "ProviderFingerprint", None] =!=
        payload["ProviderFingerprint"] ||
      Lookup[record, "PlanFingerprint", None] =!=
        payload["PlanFingerprint"] ||
      ! IntegerQ[Lookup[record, "WorkerKernelID", None]] ||
      record["WorkerKernelID"] < 0,
    Return[multiquadraticStripFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageRecordKeyMismatch"|>]]];
  result = Lookup[record, "Result", $Failed];
  If[! AssociationQ[result] ||
      Lookup[result, {"Prime", "RegulatorValue"}, None] =!= {prime, value},
    Return[multiquadraticStripFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageResultKeyMismatch"|>]]];
  status = Lookup[result, "Status", None];
  If[status === "OK",
    trainingKeys = Lookup[result, "TrainingImageKeys", $Failed];
    If[Lookup[result, "EpsilonMod", None] =!=
          multiquadraticStripModRational[value, prime] ||
        Lookup[result, "PlanFingerprint", None] =!=
          payload["PlanFingerprint"] ||
        {Lookup[result, "Rank", None], Lookup[result, "Nullity", None],
          Lookup[result, "PivotSignature", None]} =!=
          payload["LockedSignature"] ||
        Lookup[result, "PivotColumns", None] =!=
          payload["Plan", "PivotColumns"] ||
        Lookup[result, "FreeColumns", None] =!=
          payload["Plan", "FreeColumns"] ||
        ! multiquadraticStripFullResidualEvidenceValidQ[result, prime] ||
        ! StringQ[Lookup[result, "ImageStoreKey", None]] ||
        ! ListQ[trainingKeys] || trainingKeys === {} ||
        ! AllTrue[trainingKeys, MatchQ[#1,
          {payload["LayoutFingerprint"], payload["ProviderFingerprint"],
            prime, value, {_Integer, _Integer}}] &] ||
        ! VectorQ[Lookup[result, "CanonicalValues", None],
          Function[item, IntegerQ[item] && 0 <= item < prime]] ||
        Length[result["CanonicalValues"]] =!=
          payload["Plan", "UnknownCount"] ||
        ! MemberQ[{"Constrained", "FullAffineFallback"},
          Lookup[result, "FollowerSolveKind", None]],
      Return[multiquadraticStripFailure[
        "FollowerImageAuthenticationFailed",
        <|"Reason" -> "FollowerImageResultCertificateInvalid"|>]]],
    If[! MemberQ[{"ReconstructionSampleFailed",
          "ReconstructionConstrainedSolveFailed"}, status],
      Return[multiquadraticStripFailure[
        "FollowerImageAuthenticationFailed",
        <|"Reason" -> "FollowerImageResultStatusInvalid"|>]]]];
  If[! AllTrue[Lookup[result,
        {"SamplingSeconds", "EliminationSeconds"}, {-1, -1}],
      NumericQ[#1] && #1 >= 0 &],
    Return[multiquadraticStripFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageTimingInvalid"|>]]];
  <|"Status" -> "AuthenticatedMultiquadraticFollowerImageV1",
    "Prime" -> prime, "RegulatorValue" -> value,
    "LayoutFingerprint" -> payload["LayoutFingerprint"],
    "ProviderFingerprint" -> payload["ProviderFingerprint"],
    "PlanFingerprint" -> payload["PlanFingerprint"]|>
];
multiquadraticStripFollowerImageAuthenticate[___] :=
  multiquadraticStripFailure["FollowerImageAuthenticationFailed",
    <|"Reason" -> "InvalidAuthenticationArguments"|>];

(* Broker helper entry: taskBrokerRead memoizes the immutable payload by file
   and modification time on a persistent helper. *)
multiquadraticStripFollowerImageTask[dataFile_String,
    request_Association] := Module[{payload = taskBrokerRead[dataFile]},
  If[! multiquadraticStripFollowerImagePayloadValidQ[payload], $Failed,
    multiquadraticStripFollowerImageSolve[payload, request]]
];
multiquadraticStripFollowerImageTask[___] := $Failed;

(* Concurrency counts images, including the mission kernel's local share.
   Resolve Automatic against the pool-owned family/core grant and helpers that
   are actually free; the TaskBroker remains the only owner of Wolfram kernels.
   A follower wave needs at least two native cores per image to be worthwhile,
   but the native-core lease may redistribute the remaining grant dynamically.
   Multi-family waves stay serial so the pool can divide resources among
   families instead of creating nested image fan-out. *)
multiquadraticStripFollowerImageKernelCount[requested_,
    nativeThreads_Integer] := Module[
  {processors, free, requestedCount, processorCount, effectiveNative,
   minimumNativePerImage, activeFamilies},
  If[! (requested === Automatic ||
        IntegerQ[requested] && Between[requested, {1, 8}]) ||
      ! Between[nativeThreads, {1, 8}], Return[1]];
  activeFamilies = Quiet[Check[taskBrokerActiveFamilyCount[], 1]];
  If[IntegerQ[activeFamilies] && activeFamilies > 1, Return[1]];
  requestedCount = Replace[requested, Automatic -> 4];
  If[requestedCount === 1, Return[1]];
  processors = Quiet[Check[taskBrokerNativeCoreQuota[], 1]];
  effectiveNative = Quiet[Check[
    taskBrokerNativeThreadLimit[nativeThreads], nativeThreads]];
  minimumNativePerImage = If[
    IntegerQ[processors] && processors > 1 &&
      IntegerQ[effectiveNative] && effectiveNative > 1, 2, 1];
  processorCount = If[IntegerQ[processors] && processors > 0,
    Max[1, Quotient[processors, minimumNativePerImage]], 1];
  If[processorCount < 2, Return[1]];
  If[! TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]], Return[1]];
  free = Quiet[Check[taskBrokerFreeKernels[], 0]];
  If[! IntegerQ[free] || free < 1, Return[1]];
  Max[1, Min[8, requestedCount, processorCount, free + 1]]
];
multiquadraticStripFollowerImageKernelCount[___] := 1;

(* One wave gives the leading requests to free broker helpers and keeps the
   remaining share on the mission kernel.  Results are restored to request
   order before admission.  A missing, timed-out or malformed helper result is
   recomputed locally only while the absolute reconstruction deadline remains;
   otherwise it is abandoned with typed budget evidence.  dispatcher is a
   private test seam; production uses only the TaskBroker data-file protocol. *)
multiquadraticStripFollowerImageWave[payload_Association, requests_List,
    concurrency_Integer, timeout_Integer, absoluteDeadline_,
    dispatcher_: Automatic] := Module[
  {startTime = AbsoluteTime[], serial, dataFile, codes, handle, farmed,
   helperResults, localResults, results, resultRoutes, authentication,
   fallbackIndices = {}, route, dataKey, free, helperCount = 0,
   helperIndices = {}, localIndices = {}, actualConcurrency = 1,
   batchSize = Length[requests], localPosition, fallbackPosition, index},
  serial[] := multiquadraticStripFollowerImageSolve[payload, #1] & /@
    requests;
  If[! multiquadraticStripFollowerImagePayloadValidQ[payload] ||
      ! MatchQ[requests, {__Association}] || Length[requests] > 8 ||
      ! AllTrue[requests, IntegerQ[Lookup[#1, "Prime", None]] &&
        PrimeQ[#1["Prime"]] && MatchQ[
          Lookup[#1, "RegulatorValue", None], _Integer | _Rational] &] ||
      ! Between[concurrency, {1, 8}] || timeout < 1 ||
      ! multiquadraticStripDeadlineQ[absoluteDeadline],
    Return[multiquadraticStripFailure[
      "InvalidFollowerImageWaveArguments"]]];
  If[concurrency < 2 || batchSize < 2,
    Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
      "Route" -> "Serial", "Concurrency" -> 1,
      "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
      "BrokerHelperCount" -> 0, "FallbackIndices" -> {},
      "Timeout" -> timeout,
      "Results" -> serial[],
      "ResultRoutes" -> ConstantArray["SerialFollower", batchSize],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
  If[dispatcher === Automatic,
    free = Quiet[Check[taskBrokerFreeKernels[], 0]];
    If[! TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]] ||
        ! IntegerQ[free] || free < 1,
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout, "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    helperCount = Min[concurrency - 1, batchSize - 1, free];
    If[helperCount < 1,
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout, "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    dataKey = multiquadraticStripFingerprint[Lookup[payload,
      {"Schema", "LayoutFingerprint", "ProviderFingerprint",
       "PlanFingerprint", "PointCount", "MaximumAttempts", "RandomSeed",
       "LockedSignature"}]];
    dataFile = taskBrokerDataFile["mqfollow_" <> dataKey, payload];
    If[! StringQ[dataFile],
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout,
        "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    helperIndices = Range[helperCount];
    localIndices = Range[helperCount + 1, batchSize];
    codes = ("FeynFacet`Private`multiquadraticStripFollowerImageTask[" <>
        ToString[dataFile, InputForm] <> "," <>
        ToString[#1, InputForm] <> "]" &) /@ requests[[helperIndices]];
    handle = taskBrokerSubmit[codes, "Label" -> "mqfollow",
      "Timeout" -> timeout];
    localResults = Table[
      index = localIndices[[localPosition]];
      If[multiquadraticStripDeadlineExpiredQ[absoluteDeadline],
        Return[multiquadraticStripBudgetExhausted[
          "RegulatorReconstruction:FollowerWaveLocal",
          AbsoluteTime[] - startTime, absoluteDeadline,
          <|"AbandonedIndices" ->
              Drop[localIndices, localPosition - 1],
            "AbandonedRequests" -> requests[[
              Drop[localIndices, localPosition - 1]]],
            "LateBrokerWorkNotCancelled" -> True|>], Module]];
      multiquadraticStripFollowerImageSolve[payload, requests[[index]]],
      {localPosition, Length[localIndices]}];
    farmed = taskBrokerCollect[handle];
    helperResults = If[ListQ[farmed] && Length[farmed] === helperCount,
      farmed, ConstantArray[$Failed, helperCount]];
    results = Join[helperResults, localResults];
    resultRoutes = Join[ConstantArray["TaskBrokerFollower", helperCount],
      ConstantArray["SerialFollower", Length[localIndices]]];
    route = "TaskBroker",
    helperCount = Min[concurrency - 1, batchSize - 1];
    helperIndices = Range[helperCount];
    localIndices = Range[helperCount + 1, batchSize];
    helperResults = (Quiet[Check[dispatcher[payload, #1], $Failed]] &) /@
      requests[[helperIndices]];
    localResults = multiquadraticStripFollowerImageSolve[payload, #1] & /@
      requests[[localIndices]];
    results = Join[helperResults, localResults];
    resultRoutes = Join[ConstantArray["InjectedFollower", helperCount],
      ConstantArray["SerialFollower", Length[localIndices]]];
    route = "InjectedDispatcher"];
  actualConcurrency = 1 + helperCount;
  authentication = MapThread[
    multiquadraticStripFollowerImageAuthenticate[#1, payload, #2] &,
    {results, requests}];
  fallbackIndices = Flatten[Position[
    Lookup[authentication, "Status", None],
    Except["AuthenticatedMultiquadraticFollowerImageV1"], {1},
    Heads -> False]];
  Do[index = fallbackIndices[[fallbackPosition]];
    If[multiquadraticStripDeadlineExpiredQ[absoluteDeadline],
      Return[multiquadraticStripBudgetExhausted[
        "RegulatorReconstruction:FollowerWaveFallback",
        AbsoluteTime[] - startTime, absoluteDeadline,
        <|"WaveRoute" -> route,
          "AbandonedFallbackIndices" ->
            Drop[fallbackIndices, fallbackPosition - 1],
          "AbandonedRequests" -> requests[[
            Drop[fallbackIndices, fallbackPosition - 1]]],
          "LateBrokerWorkNotCancelled" ->
            (dispatcher === Automatic)|>], Module]];
    results[[index]] = multiquadraticStripFollowerImageSolve[payload,
      requests[[index]]];
    resultRoutes[[index]] = "SerialFollowerFallback",
    {fallbackPosition, Length[fallbackIndices]}];
  <|"Status" -> "MultiquadraticFollowerImageWaveV1",
    "Route" -> If[fallbackIndices === {}, route,
      route <> "WithSerialFallback"],
    "Concurrency" -> actualConcurrency,
    "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
    "BrokerHelperCount" -> If[dispatcher === Automatic, helperCount, 0],
    "FallbackIndices" -> fallbackIndices, "Timeout" -> timeout,
    "Results" -> results, "ResultRoutes" -> resultRoutes,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripFollowerImageWave[___] :=
  multiquadraticStripFailure["InvalidFollowerImageWaveArguments"];

(* Construct a reusable pilot envelope.  Prime and regulator metadata are
   copied into the solution as well as the outer record.  Admission below
   replays the actual affine equations; hashing the whole matrix and solution
   would add no mathematical evidence. *)
multiquadraticStripPilotImageRecord[prime_Integer, value_,
    sample_Association, solution_Association] := Module[{pilot},
  If[! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticStripFailure[
      "InvalidPilotImageRecordArguments"]]];
  pilot = <|"Prime" -> prime, "RegulatorValue" -> value,
    "Sample" -> sample,
    "Solution" -> Join[solution, <|"RegulatorValue" -> value,
      "EpsilonMod" -> Lookup[sample, "EpsilonMod", $Failed]|>]|>;
  pilot
];
multiquadraticStripPilotImageRecord[___] :=
  multiquadraticStripFailure["InvalidPilotImageRecordArguments"];

(* Full cache-admission check.  The direct residual replay proves that the
   response solves this sample, including an independent kernel basis.  The
   free-column identity is the deterministic affine-solver ABI and proves
   nullspace rank without paying for another RREF. *)
multiquadraticStripPilotImageAuthenticate[pilot_Association,
    layout_Association, provider_Association] := Module[
  {prime, value, epsilonMod, sample, solution, matrix, right, dimensions,
   unknownCount, rank, nullity, pivots, free, particular, nullspace,
   particularResidualQ, particularCanonicalQ, nullResidualQ,
   nullIndependentQ, acceptedPoints, trainingKeys, normalizationCount,
   expectedRows, failure},
  failure[reason_String, detail_Association : <||>] :=
    multiquadraticStripFailure["PilotImageAuthenticationFailed",
      Join[<|"Reason" -> reason,
        "PilotKey" -> Lookup[pilot, {"Prime", "RegulatorValue"}, None]|>,
        detail]];
  {prime, value} = Lookup[pilot, {"Prime", "RegulatorValue"}, $Failed];
  sample = Lookup[pilot, "Sample", $Failed];
  solution = Lookup[pilot, "Solution", $Failed];
  If[! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational] ||
      ! AssociationQ[sample] || ! AssociationQ[solution],
    Return[failure["MalformedPilotEnvelope"]]];
  epsilonMod = multiquadraticStripModRational[value, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[failure["InvalidPilotRegulatorImage"]]];
  If[Lookup[sample, "Status", None] =!=
        "AssembledMultiquadraticSampleV1" ||
      Lookup[sample, "Prime", None] =!= prime ||
      Lookup[sample, "EpsilonValue", None] =!= value ||
      Lookup[sample, "EpsilonMod", None] =!= epsilonMod ||
      Lookup[sample, "ABIFingerprint", None] =!=
        layout["ABIFingerprint"] ||
      Lookup[sample, "LayoutFingerprint", None] =!=
        layout["LayoutFingerprint"] ||
      Lookup[sample, "CoefficientABIFingerprint", None] =!=
        layout["CoefficientABIFingerprint"] ||
      Lookup[sample, "ProviderFingerprint", None] =!=
        provider["ProviderFingerprint"] ||
      Lookup[sample, "Provider", None] =!= provider["Kind"] ||
      Lookup[sample, "ABIVersion", None] =!= layout["ABIVersion"] ||
      Lookup[sample, "ColumnOrder", None] =!= layout["ColumnOrder"] ||
      Lookup[sample, "RowOrder", None] =!= layout["RowOrder"],
    Return[failure["PilotSampleKeyOrABIMismatch"]]];
  If[Lookup[solution, "Status", None] =!=
        "MultiquadraticAffineSolution" ||
      Lookup[solution, "Prime", None] =!= prime ||
      Lookup[solution, "RegulatorValue", None] =!= value ||
      Lookup[solution, "EpsilonMod", None] =!= epsilonMod,
    Return[failure["PilotSolutionKeyMismatch"]]];
  matrix = Lookup[sample, "Matrix", $Failed];
  right = Lookup[sample, "RightHandSide", $Failed];
  acceptedPoints = Lookup[sample, "AcceptedPoints", $Failed];
  trainingKeys = Lookup[sample, "TrainingImageKeys", $Failed];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  dimensions = Quiet[Check[Dimensions[matrix], $Failed]];
  expectedRows = If[ListQ[acceptedPoints] && IntegerQ[normalizationCount],
    Length[acceptedPoints] layout["EquationsPerPoint"] +
      normalizationCount, $Failed];
  If[! MatrixQ[matrix,
        Function[item, IntegerQ[item] && 0 <= item < prime]] ||
      ! VectorQ[right,
        Function[item, IntegerQ[item] && 0 <= item < prime]] ||
      ! MatchQ[dimensions, {_Integer?Positive, _Integer?Positive}] ||
      Length[right] =!= dimensions[[1]] ||
      dimensions[[2]] =!= layout["UnknownCount"] ||
      ! MatchQ[acceptedPoints, {{_Integer, _Integer} ..}] ||
      ! DuplicateFreeQ[acceptedPoints] ||
      ! AllTrue[Flatten[acceptedPoints], 0 <= #1 < prime &] ||
      ! IntegerQ[normalizationCount] || normalizationCount < 0 ||
      dimensions[[1]] =!= expectedRows ||
      ! ListQ[trainingKeys] || ! DuplicateFreeQ[trainingKeys] ||
      trainingKeys =!= ({layout["LayoutFingerprint"],
          provider["ProviderFingerprint"], prime, value,
          Mod[#1, prime]} & /@ acceptedPoints) ||
      Lookup[sample, "MatrixDimensions", None] =!= dimensions ||
      Lookup[solution, "MatrixDimensions", None] =!= dimensions,
    Return[failure["PilotMatrixShapeMismatch"]]];
  unknownCount = dimensions[[2]];
  {rank, nullity} = Lookup[solution, {"Rank", "Nullity"}, $Failed];
  pivots = Lookup[solution, "PivotColumns", $Failed];
  free = Lookup[solution, "FreeColumns", $Failed];
  particular = Lookup[solution, "ParticularSolution", $Failed];
  nullspace = Lookup[solution, "NullspaceBasis", $Failed];
  If[! IntegerQ[rank] || ! IntegerQ[nullity] || rank < 0 || nullity < 0 ||
      rank + nullity =!= unknownCount || rank > dimensions[[1]] ||
      ! VectorQ[pivots, IntegerQ] || Length[pivots] =!= rank ||
      ! VectorQ[free, IntegerQ] || Length[free] =!= nullity ||
      ! DuplicateFreeQ[Join[pivots, free]] ||
      Sort[Join[pivots, free]] =!= Range[unknownCount] ||
      Lookup[solution, "PivotSignature", None] =!=
        Hash[pivots, "SHA256", "HexString"] ||
      ! VectorQ[particular, IntegerQ] ||
      Length[particular] =!= unknownCount ||
      ! If[nullity === 0, nullspace === {},
        MatrixQ[nullspace, IntegerQ] &&
          Dimensions[nullspace] === {nullity, unknownCount}] ||
      ! AllTrue[Join[particular, Flatten[nullspace]],
        0 <= #1 < prime &],
    Return[failure["PilotAffineStructureInvalid"]]];
  particularResidualQ = VectorQ[
    Mod[matrix . particular - right, prime], #1 === 0 &];
  particularCanonicalQ = nullity === 0 ||
    particular[[free]] === ConstantArray[0, nullity];
  nullResidualQ = nullity === 0 || MatrixQ[
    Normal[Mod[matrix . Transpose[nullspace], prime]], #1 === 0 &];
  nullIndependentQ = nullity === 0 ||
    Normal[Mod[nullspace[[All, free]], prime]] ===
      Normal[IdentityMatrix[nullity]];
  If[! TrueQ[particularResidualQ] || ! TrueQ[particularCanonicalQ],
    Return[failure[If[! TrueQ[particularResidualQ],
      "PilotParticularResidualNonzero",
      "PilotParticularFreeCoordinatesNonzero"]]]];
  If[! TrueQ[nullResidualQ] || ! TrueQ[nullIndependentQ],
    Return[failure["PilotNullspaceInvalid",
      <|"NullspaceResidualZero" -> nullResidualQ,
        "NullspaceIndependent" -> nullIndependentQ|>]]];
  <|"Status" -> "AuthenticatedMultiquadraticPilotImageV1",
    "Prime" -> prime, "RegulatorValue" -> value,
    "ParticularResidualZero" -> True,
    "ParticularFreeCoordinatesZero" -> True,
    "NullspaceResidualZero" -> True,
    "NullspaceIndependent" -> True|>
];
multiquadraticStripPilotImageAuthenticate[___] :=
  multiquadraticStripFailure["PilotImageAuthenticationFailed",
    <|"Reason" -> "InvalidPilotAuthenticationArguments"|>];

Options[multiquadraticStripProviderSupportLadder] = {
  "BaseDegreeOffset" -> {0, 0},
  "DegreeOffsetLadder" -> Automatic,
  "Images" -> Automatic,
  "MaximumImageAttempts" -> 6,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082701,
  "PlanDiscoveryBackend" -> Automatic,
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> Automatic,
  "Deadline" -> Infinity
};

(* The deferred bundle's materialized BBar is a shape placeholder, so its
   support question is decided only after the authenticated provider exists.
   A rung is admitted by two usable, unanimous (prime, regulator) images
   assembled by the production provider/row ABI.  Failed samples/evidence are
   replaced from a bounded candidate schedule.  Mixed usable verdicts stop
   typed and inconclusive; only two unanimous inconsistencies may advance to
   the next rung or, at ladder exhaustion, support an obstruction.  Only
   layout/support are rebuilt: the builder supplied by the driver reuses the
   full letter records, the exact bundle-derived denominator and, whenever
   its coefficient ABI still binds, the provider object itself. *)
multiquadraticStripProviderSupportLadder[basePreparation_Association,
    baseLayout_Association, baseProvider_Association, rungBuilder_,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, baseOffset, ladder, offsets, images,
   maximumImageAttempts, pointCount, maximumAttempts, randomSeed,
   requestedBackend, threads,
   minimumEntries, deadline, skipped = {}, rungs = {}, offset, built,
   preparation, layout, provider, providerReused, imageEvidence, pilotImages,
   unusableEvidence, attemptedImages, sampleSeconds, sample,
   evidenceSeconds, evidence, statuses, rungStatus, boundPilot,
   pilotAuthentication,
   adopted = None},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripProviderSupportLadder]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticStripPreparationValidQ[basePreparation] ||
      ! multiquadraticStripAssemblyLayoutValidQ[baseLayout] ||
      ! multiquadraticStripProviderValidQ[baseProvider] ||
      baseLayout["ABIFingerprint"] =!= basePreparation["ABIFingerprint"] ||
      baseLayout["CoefficientABIFingerprint"] =!=
        baseProvider["CoefficientABIFingerprint"],
    Return[multiquadraticStripFailure[
      "InvalidProviderSupportLadderInput"]]];
  baseOffset = OptionValue["BaseDegreeOffset"];
  ladder = Replace[OptionValue["DegreeOffsetLadder"],
    Automatic :> multiquadraticStripDegreeOffsetLadder[]];
  If[! MatchQ[baseOffset, {_Integer, _Integer}] || Min[baseOffset] < 0 ||
      ! MatchQ[ladder, {} | {{_Integer, _Integer} ..}] ||
      ! AllTrue[Flatten[ladder], IntegerQ[#1] && #1 >= 0 &],
    Return[multiquadraticStripFailure["InvalidDegreeOffsetLadder",
      <|"BaseDegreeOffset" -> baseOffset,
        "DegreeOffsetLadder" -> ladder|>]]];
  offsets = {baseOffset};
  Do[If[offset[[1]] <= baseOffset[[1]] &&
        offset[[2]] <= baseOffset[[2]],
      AppendTo[skipped, offset], AppendTo[offsets, offset]],
    {offset, ladder}];
  offsets = DeleteDuplicates[offsets];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  maximumImageAttempts = OptionValue["MaximumImageAttempts"];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}] ||
      Length[images] < 2 || Length[DeleteDuplicates[images]] < 2 ||
      ! IntegerQ[maximumImageAttempts] || maximumImageAttempts < 2 ||
      ! AllTrue[images[[All, 1]],
        PrimeQ[#1] && Mod[#1, 4] === 3 &&
          3 < #1 < $multiquadraticStripWordPrimeLimit &],
    Return[multiquadraticStripFailure["InvalidProviderSupportImages",
      <|"Images" -> images,
        "MaximumImageAttempts" -> maximumImageAttempts,
        "Required" -> "two usable distinct (prime, regulator) images"|>]]];
  images = Take[DeleteDuplicates[images], UpTo[maximumImageAttempts]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  randomSeed = OptionValue["RandomSeed"];
  requestedBackend = OptionValue["PlanDiscoveryBackend"];
  threads = OptionValue["PlanDiscoveryBackendThreads"];
  minimumEntries = OptionValue["PlanDiscoveryBackendMinimumEntries"];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline"]]];
  Do[
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[multiquadraticStripBudgetExhausted[
        "DeferredProviderSupportLadder", AbsoluteTime[] - startTime,
        deadline, <|"NextDegreeOffset" -> offset,
          "LadderRungs" -> rungs|>], Module]];
    built = If[offset === baseOffset,
      <|"Preparation" -> basePreparation, "Layout" -> baseLayout,
        "Provider" -> baseProvider|>, rungBuilder[offset]];
    If[! AssociationQ[built] ||
        ! multiquadraticStripPreparationValidQ[
          Lookup[built, "Preparation", <||>]] ||
        ! multiquadraticStripAssemblyLayoutValidQ[
          Lookup[built, "Layout", <||>]] ||
        ! multiquadraticStripProviderValidQ[
          Lookup[built, "Provider", <||>]],
      Return[multiquadraticStripFailure[
        "ProviderSupportRungPreparationFailed",
        <|"DegreeOffset" -> offset, "Detail" -> built,
          "LadderRungs" -> rungs|>], Module]];
    preparation = built["Preparation"];
    layout = built["Layout"];
    provider = built["Provider"];
    If[layout["ABIFingerprint"] =!= preparation["ABIFingerprint"] ||
        layout["CoefficientABIFingerprint"] =!=
          provider["CoefficientABIFingerprint"],
      Return[multiquadraticStripFailure["ProviderSupportRungABIMismatch",
        <|"DegreeOffset" -> offset,
          "LayoutFingerprint" -> layout["LayoutFingerprint"],
          "ProviderFingerprint" -> provider["ProviderFingerprint"]|>],
        Module]];
    providerReused = provider["ProviderFingerprint"] ===
      baseProvider["ProviderFingerprint"];
    imageEvidence = {}; pilotImages = {}; unusableEvidence = {};
    attemptedImages = {};
    Do[
      If[Length[imageEvidence] >= 2, Break[]];
      AppendTo[attemptedImages, image];
      {sampleSeconds, sample} = AbsoluteTiming[
        Block[{$multiquadraticStripTrustedProviderEvaluation = True,
            $multiquadraticStripTrustedLayoutEvaluation = True},
          multiquadraticStripAssembleSample[layout, provider, image[[2]],
            image[[1]], "PointCount" -> pointCount,
            "MaximumAttempts" -> maximumAttempts,
            "RandomSeed" -> randomSeed + 1009 imageIndex]]];
      If[Lookup[sample, "Status", None] =!=
          "AssembledMultiquadraticSampleV1",
        AppendTo[unusableEvidence, <|"Image" -> image,
          "Reason" -> "ProviderSupportImageAssemblyFailed",
          "Detail" -> sample, "SamplingSeconds" -> sampleSeconds|>];
        Continue[]];
      {evidenceSeconds, evidence} = AbsoluteTiming[
        multiquadraticStripAffineConsistencyEvidence[sample["Matrix"],
          sample["RightHandSide"], image[[1]],
          preparation["GaugeUnknownCount"],
          preparation["ResidueUnknownCount"], requestedBackend, threads,
          minimumEntries]];
      If[! MemberQ[{"ProviderSupportImageConsistent",
            "ProviderSupportImageInconsistent"},
          Lookup[evidence, "Status", None]],
        AppendTo[unusableEvidence, <|"Image" -> image,
          "Reason" -> "ProviderSupportImageEvidenceFailed",
          "Detail" -> evidence, "SamplingSeconds" -> sampleSeconds,
          "EvidenceSeconds" -> evidenceSeconds|>];
        Continue[]];
      AppendTo[imageEvidence, Join[KeyDrop[evidence, {"Solution"}],
        <|"RegulatorValue" -> image[[2]],
          "AcceptedPoints" -> sample["AcceptedPoints"],
          "LayoutFingerprint" -> layout["LayoutFingerprint"],
          "ProviderFingerprint" -> provider["ProviderFingerprint"],
          "SamplingSeconds" -> sampleSeconds,
          "EvidenceSeconds" -> evidenceSeconds|>]];
      If[Lookup[evidence, "Status", None] ===
          "ProviderSupportImageConsistent",
        boundPilot = multiquadraticStripPilotImageRecord[
          image[[1]], image[[2]], sample, evidence["Solution"]];
        pilotAuthentication = If[AssociationQ[boundPilot],
          multiquadraticStripPilotImageAuthenticate[
            boundPilot, layout, provider],
          multiquadraticStripFailure["PilotImageAuthenticationFailed",
            <|"Reason" -> "PilotRecordConstructionFailed"|>]];
        If[! AssociationQ[boundPilot] ||
            Lookup[pilotAuthentication, "Status", None] =!=
              "AuthenticatedMultiquadraticPilotImageV1",
          AppendTo[unusableEvidence, <|"Image" -> image,
            "Reason" -> "ProviderSupportPilotAuthenticationFailed",
            "Detail" -> pilotAuthentication|>];
          imageEvidence = Most[imageEvidence],
          AppendTo[pilotImages, boundPilot]]],
      {imageIndex, Length[images]}, {image, {images[[imageIndex]]}}];
    statuses = Lookup[imageEvidence, "Status", {}];
    rungStatus = Which[
      Length[statuses] < 2, "ProviderSupportRungInconclusive",
      statuses === ConstantArray["ProviderSupportImageConsistent", 2],
        "ProviderSupportRungConsistent",
      statuses === ConstantArray["ProviderSupportImageInconsistent", 2],
        "ProviderSupportRungInconsistent",
      True, "ProviderSupportRungMixedEvidence"];
    AppendTo[rungs, <|"DegreeOffset" -> offset,
      "SupportCount" -> Length[preparation["GaugeSupport"]],
      "UnknownCount" -> preparation["UnknownCount"],
      "LayoutFingerprint" -> layout["LayoutFingerprint"],
      "ProviderFingerprint" -> provider["ProviderFingerprint"],
      "ProviderReused" -> providerReused,
      "ImageCount" -> Length[imageEvidence],
      "AttemptCount" -> Length[attemptedImages],
      "Images" -> ({Lookup[#1, "Prime", None],
          Lookup[#1, "RegulatorValue", None]} & /@ imageEvidence),
      "AttemptedImages" -> attemptedImages,
      "UnusableImageEvidence" -> unusableEvidence,
      "Ranks" -> Lookup[imageEvidence, "Rank", {}],
      "AugmentedRanks" -> Lookup[imageEvidence, "AugmentedRank", {}],
      "Defects" -> Lookup[imageEvidence, "Defect", {}],
      "ImageEvidence" -> imageEvidence,
      "Status" -> rungStatus|>];
    If[MemberQ[{"ProviderSupportRungInconclusive",
          "ProviderSupportRungMixedEvidence"}, rungStatus],
      Return[<|"Status" -> "DeferredProviderSupportLadderInconclusive",
        "Method" -> "ProviderBackedRankAugmentedRankLadder",
        "Reason" -> If[rungStatus === "ProviderSupportRungMixedEvidence",
          "MixedConsistencyEvidence", "UsableImageQuorumUnavailable"],
        "AdoptedDegreeOffset" -> Missing["NoConsistentRung"],
        "BaseDegreeOffset" -> baseOffset,
        "DegreeOffsetLadder" -> ladder,
        "SkippedDegreeOffsets" -> skipped,
        "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
        "LadderDefects" ->
          ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
        "RequiredUsableImageCount" -> 2,
        "MaximumImageAttempts" -> maximumImageAttempts,
        "ObstructionCertified" -> False,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>, Module]];
    If[rungStatus === "ProviderSupportRungConsistent",
      adopted = <|"Preparation" -> preparation, "Layout" -> layout,
        "Provider" -> provider, "PilotImages" -> pilotImages|>;
      Break[]],
    {offset, offsets}];
  If[AssociationQ[adopted],
    Join[<|"Status" -> "DeferredProviderSupportLadderAdopted",
      "Method" -> "ProviderBackedRankAugmentedRankLadder",
      "AdoptedDegreeOffset" -> Last[rungs]["DegreeOffset"],
      "BaseDegreeOffset" -> baseOffset,
      "DegreeOffsetLadder" -> ladder,
      "SkippedDegreeOffsets" -> skipped,
      "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
      "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
      "ImageCountPerRung" -> 2,
      "MaximumImageAttempts" -> maximumImageAttempts,
      "SuccessfulPilotReuseCount" -> Length[adopted["PilotImages"]],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>, adopted],
    <|"Status" -> "DeferredProviderSupportLadderExhausted",
      "Method" -> "ProviderBackedRankAugmentedRankLadder",
      "AdoptedDegreeOffset" -> Missing["NoConsistentRung"],
      "BaseDegreeOffset" -> baseOffset,
      "DegreeOffsetLadder" -> ladder,
      "SkippedDegreeOffsets" -> skipped,
      "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
      "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
      "ImageCountPerRung" -> 2,
      "MaximumImageAttempts" -> maximumImageAttempts,
      "ObstructionCertified" -> True,
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]
];
multiquadraticStripProviderSupportLadder[___] :=
  multiquadraticStripFailure["InvalidProviderSupportLadderArguments"];

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
   that value, which is what a per-value lift certifies.

   SPECIALIZATION (fixed 2026-08-26, round-2 item 2, Codex review 1.3).
   Until this fix the strip and the one-forms were specialized at
   epsilonImage while the GAUGE and the RESIDUES were left symbolic in
   eps, and the numeric epsilonImage was then multiplied against them.
   That is wrong whenever the reconstructed object carries eps, which
   the ansatz permits in two ways: the gauge DENOMINATOR is built from
   the forcing and routinely carries eps (multiquadraticStripUnpackVector
   divides by it), and after the rational-in-eps reconstruction the
   coefficients themselves are rational functions of eps.

   Codex's minimal counterexample, now Tests/Multiquadratic/t_multiquadratic_exact_
   verifier.wls: G = 1/(1 + eps x), Bbar_x = -eps/(1 + eps x)^2,
   E = C = 0, no letters.  The identity is exact at every eps; at
   eps = 2 the pre-fix verifier compared -eps/(1+eps x)^2 against
   -2/(1+2x)^2 and reported a nonzero residual.

   Everything that enters the identity is now specialized at exactly one
   place, before any differentiation or multiplication. *)
multiquadraticStripExactChannelResidual[preparation_Association, vector_List,
    epsilonValue_: Automatic] := Module[
  {unpacked, gauge, residues, record, roots, deltas, variables, epsilon,
   epsilonImage, strip, decompose, eChannels, cChannels, bbarChannels,
   oneFormChannels, derivative, leftProduct, rightProduct, residueTerm, residual},
  unpacked = multiquadraticStripUnpackVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedMultiquadraticSolution",
    Return[unpacked]];
  record = preparation["Record"];
  roots = preparation["Roots"];
  deltas = Lookup[roots, "RootSquare", {}];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  epsilonImage = If[epsilonValue === Automatic, epsilon, epsilonValue];
  (* the reconstructed object at THIS regulator image, not the generic
     one multiplied by a number *)
  (* Quiet: a coefficient singular AT this image is a typed refusal
     below, not a message storm in a campaign log *)
  gauge = Quiet[Map[Together,
    unpacked["GaugeChannels"] /. epsilon -> epsilonImage, {3}]];
  residues = If[unpacked["Residues"] === {}, {},
    Quiet[Map[Together,
      unpacked["Residues"] /. epsilon -> epsilonImage, {3}]]];
  If[! FreeQ[{gauge, residues}, DirectedInfinity | Indeterminate],
    Return[multiquadraticStripFailure["ExactChannelGaugeSingularAtRegulator",
      <|"EpsilonValue" -> epsilonImage|>]]];
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

(* ---- ONE ROW ASSEMBLER OVER THE PROVIDER INTERFACE ------------------
   (2026-08-26, round-2 item 10; Codex review 4.1)

   There were three copies of the same PDE row: the screen's row
   assembler, the compiled-channel assembler, and
   multiquadraticStripSplitPointRows.  The equation is one equation; only
   the way its COEFFICIENTS are obtained differs.  So the coefficients
   become an interface --

     <|"Status" -> "MultiquadraticPointCoefficientsV1",
       "Point", "Prime", "EpsilonMod",
       "RootSquares", "GaugeDenominator",
       "GaugeLogDerivatives", "RootLogDerivatives",
       "E", "C", "BBar", "OneForms"|>

   -- and this ONE function turns any provider's answer into rows.  Three
   providers implement the interface: the compiled-channel provider (the
   historical route, now the fallback and the artifact oracle), the
   split-branch provider and the quotient-grade provider.

   multiquadraticStripSplitPointRows is deliberately NOT folded in: it
   builds the same rows by an independent route (sign-branch rows
   transformed back), and Codex 4.1 asks that it be retained "as an
   independent differential test".  It is exactly that, and the test that
   holds this function to it is the differential one. *)

multiquadraticStripPointCoefficientsValidQ[assembly_Association,
    coefficients_Association] := Module[
  {layoutQ, compiledOracleQ, dimensions, upper, lower, gradeCount,
   rootCount, oneFormCount, prime, modularValues, modularQ},
  layoutQ = multiquadraticStripAssemblyLayoutEvaluationValidQ[assembly];
  compiledOracleQ = ! layoutQ && multiquadraticStripCompiledValidQ[assembly];
  If[! layoutQ && ! compiledOracleQ, Return[False]];
  dimensions = assembly["Dimensions"];
  {upper, lower} = dimensions;
  gradeCount = assembly["GradeCount"];
  rootCount = assembly["RootCount"];
  oneFormCount = Length[assembly["OneForms"]];
  prime = Lookup[coefficients, "Prime", None];
  If[! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[False]];
  modularValues = Lookup[coefficients,
    {"EpsilonMod", "RootSquares", "RootValues", "GaugeDenominator",
     "GaugeLogDerivatives", "RootLogDerivatives", "E", "C", "BBar",
     "OneForms"}, {}];
  modularQ = True;
  Scan[If[! IntegerQ[#1] || ! (0 <= #1 < prime), modularQ = False] &,
    modularValues, {-1}];
  TrueQ[
    Lookup[coefficients, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" && modularQ &&
    MatchQ[Lookup[coefficients, "Point", None], {_Integer, _Integer}] &&
    Length[coefficients["RootSquares"]] === rootCount &&
    Length[Lookup[coefficients, "RootValues", {}]] === rootCount &&
    Length[coefficients["GaugeLogDerivatives"]] === 2 &&
    If[rootCount === 0,
      Lookup[coefficients, "RootLogDerivatives", Missing["RootLogDerivatives"]]
        === {},
      Dimensions[coefficients["RootLogDerivatives"]] === {rootCount, 2}] &&
    Dimensions[Lookup[coefficients, "E", {}]] ===
      {2, upper, upper, gradeCount} &&
    Dimensions[Lookup[coefficients, "C", {}]] ===
      {2, lower, lower, gradeCount} &&
    Dimensions[Lookup[coefficients, "BBar", {}]] ===
      {2, upper, lower, gradeCount} &&
    If[oneFormCount === 0,
      Lookup[coefficients, "OneForms", Missing["OneForms"]] === {},
      Dimensions[Lookup[coefficients, "OneForms", {}]] ===
        {oneFormCount, 2, gradeCount}] &&
    If[layoutQ,
      Lookup[coefficients, "CoefficientABIFingerprint", None] ===
        assembly["CoefficientABIFingerprint"] &&
      StringQ[Lookup[coefficients, "ProviderFingerprint", None]],
      Lookup[coefficients, "Provider", None] === "CompiledChannel"]]
];

multiquadraticStripAssemblePointRows[assembly_Association,
    coefficients_Association] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["GaugeSupport"], supportCount, unknownCount,
   gaugeUnknownCount, oneFormCount, prime, epsilonMod, x, y,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   gaugeLogDerivatives, rootLogDerivatives, eValues, cValues, bbarValues,
   oneFormValues, monomialValues, basisValues, basisDerivatives, xInverse,
   yInverse, half, logarithmicDerivative, targetGrade, sourceGrade,
   productGrade, productFactor, mu, i, j, a, b, letter, monomial,
   productWeight, productGrades, productWeights, rowIndex, rowCount, rows,
   right, row, gaugeRow, residueRow, residueRowExpectedWidth},
  If[! multiquadraticStripPointCoefficientsValidQ[assembly, coefficients],
    Throw[multiquadraticStripFailure["InvalidPointCoefficients"],
      "MultiquadraticStripAssemblyFailure"]];
  prime = coefficients["Prime"];
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = coefficients["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[multiquadraticStripFailure["ZeroRegulatorImage"],
      "MultiquadraticStripAssemblyFailure"]];
  {x, y} = coefficients["Point"];
  If[x === 0 || y === 0,
    Throw[multiquadraticStripFailure["ZeroPointCoordinate",
      <|"Point" -> {x, y}|>], "MultiquadraticStripAssemblyFailure"]];
  deltaValues = coefficients["RootSquares"];
  If[MemberQ[deltaValues, 0],
    Throw[multiquadraticStripFailure["DegenerateRootImage",
      <|"Point" -> {x, y}, "DeltaValues" -> deltaValues|>],
      "MultiquadraticStripAssemblyFailure"]];
  denominatorValue = coefficients["GaugeDenominator"];
  If[denominatorValue === 0,
    Throw[multiquadraticStripFailure["ZeroGaugeDenominator",
      <|"Point" -> {x, y}|>], "MultiquadraticStripAssemblyFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  deltaMaskFactors = Developer`ToPackedArray[
    multiquadraticStripMaskFactorMod[#1, deltaValues, prime] & /@
      Range[0, gradeCount - 1]];
  gaugeLogDerivatives = coefficients["GaugeLogDerivatives"];
  rootLogDerivatives = coefficients["RootLogDerivatives"];
  eValues = coefficients["E"];
  cValues = coefficients["C"];
  bbarValues = coefficients["BBar"];
  oneFormValues = coefficients["OneForms"];
  xInverse = PowerMod[x, -1, prime];
  yInverse = PowerMod[y, -1, prime];
  half = PowerMod[2, -1, prime];
  monomialValues = Developer`ToPackedArray[Table[
    Mod[PowerMod[x, support[[monomial, 1]], prime]
      PowerMod[y, support[[monomial, 2]], prime], prime],
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
  multiquadraticStripPointResult[assembly, coefficients, rows, right,
    N[AbsoluteTime[] - startTime]]
], "MultiquadraticStripAssemblyFailure"];
multiquadraticStripAssemblePointRows[___] :=
  multiquadraticStripFailure["InvalidAssemblePointRowsArguments"];


(* ------------------------------------------------------------------ *)
(* DIRECT COEFFICIENT PROVIDERS (2026-08-26, round-2 item 9)            *)
(* ------------------------------------------------------------------ *)

(* THE MEASUREMENT THAT DRIVES THIS.  Preparation of the real CF300
   (12,9) block is 1439.7 s, of which 1400.5 s (97.3%) is
   multiquadraticFieldDecompose of the whole forcing into global
   characteristic-zero channels.  The modular solve does not need those
   FUNCTIONS: it needs their VALUES at finite-field points.  Codex's
   bounded benchmark on the same frozen block
   (Exchange/Codex/2026-08-25/09_direct_branch_benchmark.wls) evaluated
   the original forcing directly on
   every Galois branch at one point and reproduced all 32 frozen exact
   channel projections; the first entry cost 2.727 s to decompose
   exactly and 0.0745 s to evaluate on all four branches.

   TWO PROVIDERS, both exact statements about F_p:

   SPLIT-BRANCH.  At a point where every declared radicand is a quadratic
   residue, each root has a value r_i in F_p and the 2^d sign branches
   sigma give

       f(sigma_1 r_1, ..., sigma_d r_d) = Sum_S c_S chi_S(sigma) r_S.

   A Walsh-Hadamard transform over the branches recovers c_S r_S, and
   division by the nonzero r_S recovers c_S -- which is exactly
   multiquadraticProjectConjugates in the algebra module.  Simple,
   independently checkable, and validated against the frozen block.  It
   needs a split point.

   QUOTIENT-GRADE.  Evaluate the expression directly in

       F_p[r_1, ..., r_d] / (r_i^2 - Delta_i)

   on grade vectors, inverting denominators with the recursive tower
   norm.  Valid at NONSPLIT points too -- no one-in-2^d residue
   restriction, which is what matters at rank three -- and it is the
   better production provider.  A zero norm is a typed rejection of the
   POINT, never a zero value.

   Both are cross-checked at split points: the split-branch provider is
   the independent oracle for the quotient-grade one, exactly as Pro
   prescribes.  Neither reconstructs a global channel function, and
   neither needs one.

   PER-ENTRY ACTIVE-ROOT REDUCTION (Pro item 1, which Pro ranks first).
   Most scalar entries of a rank-3 bundle use fewer than three
   generators.  The active subset is determined once per entry, the
   evaluation runs in that local subfield of rank d' <= d, and the local
   channels are lifted to the declared global grade ABI with
   multiquadraticLiftLocalChannels.  A rank-one scalar does not pay
   rank-three costs because the family declares three roots. *)

(* ---- modular grade arithmetic ------------------------------------- *)

(* The recursive quadratic-tower inverse of the exact route, in F_p.
   Same recursion, same acceptance: a zero norm at any level means the
   element is a zero divisor there, and the caller must reject the POINT
   rather than record a value. *)
multiquadraticStripModularInverse[a_List, deltas_List, prime_Integer] := Module[
  {rank = Length[deltas], half, u, v, subDeltas, uSquare, vSquare, norm,
   normInverse, low, high},
  If[! IntegerQ[prime] || prime <= 1 || Length[a] =!= 2^rank ||
      ! VectorQ[a, IntegerQ], Return[$Failed]];
  If[rank === 0,
    Return[If[Mod[First[a], prime] === 0, $Failed,
      {PowerMod[First[a], -1, prime]}]]];
  half = 2^(rank - 1);
  u = Take[a, half];
  v = Drop[a, half];
  subDeltas = Most[deltas];
  If[AllTrue[v, Mod[#1, prime] === 0 &],
    Return[Module[{inner = multiquadraticStripModularInverse[u, subDeltas,
        prime]},
      If[inner === $Failed, $Failed,
        Join[inner, ConstantArray[0, half]]]]]];
  uSquare = multiquadraticMultiply[u, u, subDeltas, prime];
  vSquare = multiquadraticMultiply[v, v, subDeltas, prime];
  If[! ListQ[uSquare] || ! ListQ[vSquare], Return[$Failed]];
  norm = Mod[uSquare - Last[deltas] vSquare, prime];
  normInverse = multiquadraticStripModularInverse[norm, subDeltas, prime];
  If[normInverse === $Failed, Return[$Failed]];
  low = multiquadraticMultiply[u, normInverse, subDeltas, prime];
  high = multiquadraticMultiply[v, normInverse, subDeltas, prime];
  If[! ListQ[low] || ! ListQ[high], Return[$Failed]];
  Join[Mod[low, prime], Mod[-high, prime]]
];
multiquadraticStripModularInverse[___] := $Failed;

multiquadraticStripModularGradePower[a_List, exponent_Integer, deltas_List,
    prime_Integer] := Module[{result, base = a, n = Abs[exponent], inverse,
   width = Length[a]},
  If[exponent === 0, Return[PadRight[{Mod[1, prime]}, width, 0]]];
  If[exponent < 0,
    inverse = multiquadraticStripModularInverse[a, deltas, prime];
    If[inverse === $Failed, Return[$Failed]];
    base = inverse];
  result = PadRight[{Mod[1, prime]}, width, 0];
  While[n > 0,
    If[BitAnd[n, 1] === 1,
      result = multiquadraticMultiply[result, base, deltas, prime];
      If[! ListQ[result], Return[$Failed]]];
    n = BitShiftRight[n, 1];
    If[n > 0,
      base = multiquadraticMultiply[base, base, deltas, prime];
      If[! ListQ[base], Return[$Failed]]]];
  result
];

(* ---- the evaluator ------------------------------------------------- *)

(* ONE recursive modular evaluator over the RAW expression tree.  It
   never forms a symbolic intermediate: every node is reduced to a grade
   vector over F_p as it is met, so no Together, no Expand and no
   characteristic-zero rational growth.

   Both providers are this evaluator with a different radical rule --
   split-branch binds each root to its branch VALUE (a rank-0
   evaluation), quotient-grade binds it to the grade UNIT VECTOR -- which
   is why they cannot disagree for a structural reason, and a
   disagreement between them is always a real defect.

   Every refusal is typed and separate: a zero denominator, a zero norm,
   an undeclared radical and an unsupported node are four different
   statements and none of them is a zero value. *)
$multiquadraticStripGradeEvaluateTag = "MultiquadraticStripGradeEvaluate";

(* radicalRules: a list of {rootSquare, gradeValue} pairs.  The radicand
   is matched up to a POSITIVE RATIONAL SQUARE scale by
   transportChartRootBranchScale -- the same rule the exact branch
   substitution uses, because the kernel pulls rational square factors
   out of a radical (Sqrt[4 N] -> 2 Sqrt[N]). *)
multiquadraticStripModularGradeEvaluate[expression_, scalarRules_Association,
    radicalRules_List, deltas_List, prime_Integer] := Catch[Module[
  {width = 2^Length[deltas], evaluate, embed, radicalValue, scaleImage},
  embed[value_Integer] := PadRight[{Mod[value, prime]}, width, 0];
  scaleImage[scale_] := Mod[Numerator[scale] PowerMod[
    Mod[Denominator[scale], prime], -1, prime], prime];
  (* Sqrt[base] as a grade vector, or Missing when the base is not a
     declared square class *)
  radicalValue[base_] := radicalValue[base] = Module[{index, scale},
    index = SelectFirst[Range[Length[radicalRules]],
      transportChartRootBranchScale[base, radicalRules[[#1, 1]]] =!= None &,
      Missing["NoRadical"]];
    If[MissingQ[index], Return[Missing["NoRadical"]]];
    scale = transportChartRootBranchScale[base, radicalRules[[index, 1]]];
    If[Mod[Denominator[scale], prime] === 0,
      Throw[<|"Status" -> "BadPrimeForRadicalScale", "Scale" -> scale|>,
        $multiquadraticStripGradeEvaluateTag]];
    Mod[scaleImage[scale] radicalRules[[index, 2]], prime]];
  evaluate[node_] := Which[
    IntegerQ[node], embed[node],
    Head[node] === Rational,
      Module[{denominator = Mod[Denominator[node], prime]},
        If[denominator === 0,
          Throw[<|"Status" -> "BadPrimeForRationalCoefficient",
            "Denominator" -> Denominator[node]|>,
            $multiquadraticStripGradeEvaluateTag]];
        embed[Mod[Numerator[node] PowerMod[denominator, -1, prime], prime]]],
    MatchQ[node, _Symbol],
      If[KeyExistsQ[scalarRules, node], embed[scalarRules[node]],
        Throw[<|"Status" -> "UnassignedSymbol", "Symbol" -> HoldForm[node]|>,
          $multiquadraticStripGradeEvaluateTag]],
    Head[node] === Plus,
      Fold[Mod[#1 + evaluate[#2], prime] &, ConstantArray[0, width],
        List @@ node],
    Head[node] === Times,
      Fold[Module[{product = multiquadraticMultiply[#1, evaluate[#2], deltas,
          prime]},
        If[! ListQ[product],
          Throw[<|"Status" -> "GradeProductFailed"|>,
            $multiquadraticStripGradeEvaluateTag]];
        Mod[product, prime]] &, embed[1], List @@ node],
    (* a HALF power: Power[b, m/2] with m odd is (Sqrt[b])^m *)
    MatchQ[node, Power[_, _Rational]] && Denominator[Last[node]] === 2,
      Module[{root = radicalValue[First[node]], value},
        If[MissingQ[root],
          Throw[<|"Status" -> "UndeclaredRadical",
            "RadicalBase" -> HoldForm[First[node]]|>,
            $multiquadraticStripGradeEvaluateTag]];
        value = multiquadraticStripModularGradePower[root,
          Numerator[Last[node]], deltas, prime];
        If[value === $Failed,
          Throw[<|"Status" -> "SingularPoint",
            "Reason" -> "ZeroRadicalValueOrZeroNorm"|>,
            $multiquadraticStripGradeEvaluateTag]];
        value],
    MatchQ[node, Power[_, _Integer]],
      Module[{value = multiquadraticStripModularGradePower[
          evaluate[First[node]], Last[node], deltas, prime]},
        If[value === $Failed,
          Throw[<|"Status" -> "SingularPoint",
            "Reason" -> "ZeroNormOrZeroDenominator"|>,
            $multiquadraticStripGradeEvaluateTag]];
        value],
    MatchQ[node, Power[_, _Rational]],
      Throw[<|"Status" -> "UnsupportedFractionalPower",
        "Exponent" -> Last[node]|>, $multiquadraticStripGradeEvaluateTag],
    True,
      Throw[<|"Status" -> "UnsupportedExpression",
        "Head" -> ToString[Head[node]]|>,
        $multiquadraticStripGradeEvaluateTag]];
  <|"Status" -> "OK", "Channels" -> evaluate[expression]|>],
  $multiquadraticStripGradeEvaluateTag];

(* ---- per-entry active root subset --------------------------------- *)

(* Which DECLARED roots actually occur in one scalar entry.  The same
   square-class matcher the census and the branch substitution use, so an
   entry that carries Sqrt[4 delta_2] is reported as using root 2. *)
multiquadraticStripEntryActiveRoots[entry_, roots_List] := Module[{bases},
  bases = transportChartRadicalBases[entry];
  If[bases === {}, Return[{}]];
  Sort[DeleteDuplicates[Flatten[Table[
    Select[Range[Length[roots]],
      transportChartRootBranchScale[base,
        Lookup[roots[[#1]], "RootSquare", 0]] =!= None &],
    {base, bases}]]]]
];

(* Convert authenticated bit-mask metadata to the ordered local root subset.
   This is deliberately a tiny integer operation: operand masks were already
   recomputed by blockEquationDeferredBundleValidate, so the direct provider
   must not repeat a symbolic radical census for every interned operand. *)
multiquadraticStripRootMaskActiveRoots[mask_Integer, rank_Integer] /;
    rank >= 0 && 0 <= mask < 2^rank :=
  Select[Range[rank], BitGet[mask, #1 - 1] === 1 &];
multiquadraticStripRootMaskActiveRoots[___] := $Failed;

(* Embed the bundle's own canonical root frame into the solver's canonical
   root frame.  Bundle compilation deliberately prunes roots absent from the
   deferred forcing, while E and C may still require them; equality of the two
   frames is therefore too strong.  Exact root and square matching preserves
   the declared branch, and unique positions give the mask relabelling below. *)
multiquadraticStripBundleRootEmbedding[bundleRoots_List, roots_List] :=
 Module[{positions},
  positions = Table[Module[{matches = Select[Range[Length[roots]],
       TrueQ[Quiet[Together[
           roots[[#1, "RootSquare"]] - bundleRoot["RootSquare"]]] === 0] &&
         TrueQ[Quiet[Together[
           roots[[#1, "Root"]] - bundleRoot["Root"]]] === 0] &]},
      If[Length[matches] === 1, First[matches], $Failed]],
    {bundleRoot, bundleRoots}];
  If[VectorQ[positions, IntegerQ] && DuplicateFreeQ[positions], positions,
    $Failed]
];
multiquadraticStripBundleRootEmbedding[___] := $Failed;

(* Immutable, derived hot-path data for one deferred bundle.  Operand masks
   come from the validator-authenticated table.  Coefficients have no bundle
   mask field, so canonicalize composite radicals and compute their masks once
   when the provider is constructed.  The public provider validator
   recomputes this record; trusted point loops only read the sealed copy. *)
multiquadraticStripBundleLocalData[bundle_Association, roots_List,
    variables : {_Symbol, _Symbol}] := Catch[Module[
  {rank = Length[roots], frame, bundleRoots, bundleRank,
   bundleRootEmbedding, squares, operands, expressions, localMasks,
   localActiveRoots, masks, activeRoots, coefficientData, tag},
  tag = Unique["MultiquadraticBundleLocalDataFailure"];
  frame = Lookup[bundle, "RootFrame", <||>];
  bundleRoots = Lookup[frame, "Roots", None];
  bundleRootEmbedding = If[ListQ[bundleRoots],
    multiquadraticStripBundleRootEmbedding[bundleRoots, roots], $Failed];
  If[bundleRootEmbedding === $Failed,
    Throw[multiquadraticStripFailure[
      "DeferredBundleRootOrderMismatch"], tag]];
  bundleRank = Length[bundleRoots];
  squares = Together /@ Lookup[roots, "RootSquare", {}];
  operands = Lookup[bundle, "OperandTable", {}];
  expressions = Map[Function[operand,
    operand["Numerator"]/Times @@
      (Power[First[#1], Last[#1]] & /@
        operand["DenominatorFactors"])], operands];
  localMasks = Lookup[operands, "RootMask", $Failed];
  localActiveRoots =
    multiquadraticStripRootMaskActiveRoots[#1, bundleRank] & /@ localMasks;
  If[MemberQ[localActiveRoots, $Failed],
    Throw[multiquadraticStripFailure[
      "InvalidBundleOperandRootMask"], tag]];
  activeRoots = Map[Function[indices, bundleRootEmbedding[[indices]]],
    localActiveRoots];
  masks = Total[2^(#1 - 1)] & /@ activeRoots;
  coefficientData = Map[Function[job,
      Map[Function[term, Module[{canonical, expression, mask, active},
        canonical = blockEquationDeferredFrameCanonicalize[
          First[term], frame, variables];
        If[Lookup[canonical, "Status", None] =!= "OK",
          Throw[Join[multiquadraticStripFailure[
            "BundleCoefficientCanonicalizationFailed"],
            <|"Detail" -> canonical|>], tag]];
        expression = canonical["Expression"];
        mask = blockEquationDeferredFactorRootMask[expression, squares];
        active = multiquadraticStripRootMaskActiveRoots[mask, rank];
        If[mask === $Failed || active === $Failed,
          Throw[multiquadraticStripFailure[
            "InvalidBundleCoefficientRootMask"], tag]];
        <|"Expression" -> expression, "RootMask" -> mask,
          "ActiveRoots" -> active|>]], Lookup[job, "Terms", {}]]],
    Lookup[bundle, "Jobs", {}]];
  <|"Status" -> "MultiquadraticBundleLocalDataV1",
    "OperandExpressions" -> expressions,
    "OperandRootMasks" -> masks,
    "OperandActiveRoots" -> activeRoots,
    "CoefficientExpressions" -> Map[Lookup[#1, "Expression"] &,
      coefficientData, {2}],
    "CoefficientRootMasks" -> Map[Lookup[#1, "RootMask"] &,
      coefficientData, {2}],
    "CoefficientActiveRoots" -> Map[Lookup[#1, "ActiveRoots"] &,
      coefficientData, {2}]|>
], tag, #1 &];
multiquadraticStripBundleLocalData[___] :=
  multiquadraticStripFailure["InvalidBundleLocalDataArguments"];

(* ---- the two providers, per entry ---------------------------------- *)

(* Both return a GLOBAL grade vector of width 2^rank: the local channels
   of the entry's active subfield, lifted through
   multiquadraticLiftLocalChannels.  Both take the root VALUES mod p of
   the declared roots (split-branch needs them to be genuine square
   roots; quotient-grade uses only the squares). *)

multiquadraticStripQuotientGradeEntry[entry_, roots_List, activeIndices_List,
    scalarRules_Association, deltaValues_List, prime_Integer] := Module[
  {localDeltas, radicalRules, evaluated, lifted, rank = Length[roots]},
  localDeltas = deltaValues[[activeIndices]];
  (* local grade unit vector of root k: mask 2^(k-1), index mask + 1 *)
  radicalRules = Table[
    {Lookup[roots[[activeIndices[[k]]]], "RootSquare", 0],
     UnitVector[2^Length[activeIndices], 2^(k - 1) + 1]},
    {k, Length[activeIndices]}];
  evaluated = multiquadraticStripModularGradeEvaluate[entry, scalarRules,
    radicalRules, localDeltas, prime];
  If[Lookup[evaluated, "Status", None] =!= "OK", Return[evaluated]];
  lifted = multiquadraticLiftLocalChannels[evaluated["Channels"],
    activeIndices, rank];
  If[lifted === $Failed,
    Return[<|"Status" -> "LocalChannelLiftFailed",
      "ActiveRoots" -> activeIndices|>]];
  <|"Status" -> "OK", "Channels" -> Mod[lifted, prime],
    "ActiveRoots" -> activeIndices, "LocalRank" -> Length[activeIndices]|>
];

(* Stable formal roots for the sparse branch compiler.  They are implementation
   variables, never part of a provider or coefficient ABI, and the compile
   cache is reset on every load of this source. *)
$multiquadraticStripSplitRootSymbols = Table[
  Unique["FeynFacet`Private`mqSplitRoot$"],
  {$multiquadraticStripMaximumRootCount}];
$multiquadraticStripSplitSparseCompilation = True;
$multiquadraticStripSplitSparsePlanCache = <||>;
$multiquadraticStripSplitSparseExactPlanCache = <||>;
$multiquadraticStripTrustedSplitSparsePlanEvaluation = False;

(* THE SPLIT FAST PATH.  Applying root branches and point rules directly is
   cheap for a small expression but still walks the entire raw tree once per
   sign and per point.  A rank-r entry sampled at P points therefore paid
   P 2^r full-tree substitutions.  The screen subsystem already has the exact
   representation we need: replace the active radicals by formal roots once,
   compile the resulting rational function to sparse modular monomials once
   per prime, then evaluate each sign by packed dot products.  Its cache is
   expression/root/variable/prime authenticated and byte bounded.

   Compilation is only an optimization.  Any compile or evaluation refusal
   takes the historical substitution path, and that path retains the recursive
   grade evaluator as its typed diagnostic fallback.  Thus cache availability
   can change time and telemetry, never the accepted coefficient channels. *)
multiquadraticStripSplitBranchEntry[entry_, roots_List, activeIndices_List,
    scalarRules_Association, deltaValues_List, rootValues_List,
    prime_Integer, suppliedCompiled_: Automatic] := Module[
  {localRank = Length[activeIndices], localRoots, branchValues, mask, signs,
    radicalRules, evaluated, channels, lifted, rank = Length[roots],
    pointRules, localRootRecords, fast, method = "SparseRootPlaceholder",
    localRootSymbols, scalarVariables, compiled, compileSeconds = 0.,
    evaluationSeconds = 0., fallbackSeconds = 0., cacheHitsBefore,
    cacheHit = False, values, powerTables, pair,
    substitutionBranches, fallbackMethod = "Substitution",
    plannedQ = suppliedCompiled =!= Automatic},
  localRoots = rootValues[[activeIndices]];
  If[MemberQ[Mod[localRoots, prime], 0],
    Return[<|"Status" -> "SingularPoint", "Reason" -> "ZeroRootValue"|>]];
  pointRules = Normal[scalarRules];
  localRootRecords = roots[[activeIndices]];
  localRootSymbols = Take[$multiquadraticStripSplitRootSymbols, localRank];
  scalarVariables = Keys[scalarRules];
  (* The packed Wolfram sparse dot product is a 31-bit compatibility path:
     products of 61-bit residues do not stay in signed machine integers.
     Wide production normally supplies native FLINT leaf channels and never
     enters here; an explicit-wide or exceptional native fallback uses the
     exact substitution evaluator instead. *)
  If[prime < 2^31,
    If[plannedQ,
      compiled = suppliedCompiled,
     If[TrueQ[$multiquadraticStripSplitSparseCompilation],
      cacheHitsBefore = Lookup[$multiquadraticStripScreenCompileStatistics,
        "Hits", 0];
      {compileSeconds, compiled} = AbsoluteTiming[
        multiquadraticStripScreenCompileCached[entry, localRootRecords,
          localRootSymbols, scalarVariables, prime]];
      cacheHit = Lookup[$multiquadraticStripScreenCompileStatistics, "Hits", 0] >
        cacheHitsBefore,
      compiled = $Failed]],
    compiled = $Failed];
  If[AssociationQ[compiled],
    {evaluationSeconds, branchValues} = AbsoluteTiming[Catch[
      Quiet[Check[Table[
      signs = Table[If[BitGet[mask, k - 1] === 1, -1, 1],
        {k, localRank}];
      values = Join[Values[scalarRules], Mod[signs localRoots, prime]];
      powerTables = multiquadraticStripScreenPowerTables[values,
        compiled["MaximumExponents"], prime];
      pair = multiquadraticStripScreenEvaluateRationalValue[compiled,
        powerTables, prime];
      If[pair === $Failed, Throw[$Failed,
        "MultiquadraticSplitCompiledEvaluation"]];
      pair, {mask, 0, 2^localRank - 1}], $Failed]],
      "MultiquadraticSplitCompiledEvaluation", Function[{value, tag}, value]]],
    branchValues = $Failed];
  substitutionBranches[] := Module[{result},
    result = Table[
      signs = Table[If[BitGet[mask, k - 1] === 1, -1, 1], {k, localRank}];
      fast = Quiet[Check[
        multiquadraticStripModRational[
          transportChartApplyRootBranches[entry, localRootRecords,
            Mod[signs localRoots, prime]] /. pointRules, prime], $Failed]];
      If[IntegerQ[fast], fast,
        fallbackMethod = "GradeEvaluator";
        radicalRules = Table[
          {Lookup[roots[[activeIndices[[k]]]], "RootSquare", 0],
            {Mod[signs[[k]] localRoots[[k]], prime]}},
          {k, localRank}];
        evaluated = multiquadraticStripModularGradeEvaluate[entry, scalarRules,
          radicalRules, {}, prime];
        If[Lookup[evaluated, "Status", None] =!= "OK",
          Return[evaluated, Module]];
        First[evaluated["Channels"]]],
      {mask, 0, 2^localRank - 1}];
    result];
  If[! VectorQ[branchValues, IntegerQ],
    {fallbackSeconds, branchValues} = AbsoluteTiming[substitutionBranches[]];
    method = fallbackMethod;
    If[! VectorQ[branchValues, IntegerQ], Return[branchValues]]];
  (* Walsh-Hadamard back to channels, then divide by the evaluated r_S *)
  channels = multiquadraticProjectConjugates[branchValues,
    Mod[localRoots, prime], prime];
  If[channels === $Failed,
    Return[<|"Status" -> "BranchProjectionFailed"|>]];
  lifted = multiquadraticLiftLocalChannels[channels, activeIndices, rank];
  If[lifted === $Failed,
    Return[<|"Status" -> "LocalChannelLiftFailed",
      "ActiveRoots" -> activeIndices|>]];
  <|"Status" -> "OK", "Channels" -> Mod[lifted, prime],
    "ActiveRoots" -> activeIndices, "LocalRank" -> localRank,
    "Method" -> method, "BranchValues" -> branchValues,
    "SparsePlanUsed" -> plannedQ,
    "SparseCompileCacheHit" -> cacheHit,
    "SparseCompileSeconds" -> compileSeconds,
    "SparseEvaluationSeconds" -> evaluationSeconds,
    "SubstitutionFallbackSeconds" -> fallbackSeconds|>
];

(* ---- the provider object ------------------------------------------ *)

(* THE PROVIDER INTERFACE (round-2 item 10).  A provider answers exactly
   one question: at (point, regulator image, prime), what are the
   coefficient values the row assembler needs?  Three implementations
   answer it -- the compiled-channel one that already existed, and the
   two direct ones here -- and ONE multiquadraticStripAssemblePointRows
   turns any of those answers into rows.  That is what removes the
   duplication Codex 4.1 names, and it is what makes the split-branch
   route an independent DIFFERENTIAL TEST of the compiled route instead
   of a fourth copy of the same loop.

   The per-entry active-root census, the gauge-denominator log
   derivatives and the root log derivatives are symbolic objects computed
   ONCE, when the provider is built.  They are the only symbolic work the
   direct route does; the global exact channel decomposition -- 97.3% of
   preparation on the real block -- is not done at all. *)
Options[multiquadraticStripDirectProvider] = {
  "Kind" -> "QuotientGrade",
  "OneForms" -> {},
  "GaugeDenominator" -> 1,
  "DeferredBundle" -> Automatic,
  "CoefficientABIFingerprint" -> Automatic,
  "SourceFingerprint" -> Automatic
};

multiquadraticStripDirectProvider[record_Association, roots_List,
    opts : OptionsPattern[]] := Module[
  {gate, kind, variables, epsilon, strip, entries, activeRoots, oneForms,
   gaugeDenominator, gaugeLog, rootLog, oneFormActive, dimensions,
   coefficientPayload, coefficientFingerprint, requestedFingerprint,
   sourceFingerprint, canonicalData, result, deferredBundle,
   bundleValidation, bundleFingerprint = None, bundleRootEmbedding,
   bundleLocalData = Missing["NoDeferredBundle"],
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripDirectProvider]]]];
  If[AssociationQ[gate], Return[gate]];
  kind = OptionValue["Kind"];
  If[! MemberQ[{"QuotientGrade", "SplitBranch"}, kind],
    Return[multiquadraticStripFailure["InvalidProviderKind",
      <|"Kind" -> kind|>]]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  deferredBundle = Replace[OptionValue["DeferredBundle"], Automatic :>
    Lookup[record, "DeferredBundle", Missing["NoDeferredBundle"]]];
  If[AssociationQ[deferredBundle],
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[multiquadraticStripFailure["InvalidDeferredBundle",
        <|"Detail" -> bundleValidation|>]]];
    bundleRootEmbedding = multiquadraticStripBundleRootEmbedding[
      Lookup[deferredBundle["RootFrame"], "Roots", {}], roots];
    If[bundleRootEmbedding === $Failed,
      Return[multiquadraticStripFailure[
        "DeferredBundleRootOrderMismatch"]]];
    bundleFingerprint = deferredBundle["BundleFingerprint"];
    bundleLocalData = multiquadraticStripBundleLocalData[deferredBundle,
      roots, variables];
    If[Lookup[bundleLocalData, "Status", None] =!=
        "MultiquadraticBundleLocalDataV1",
      Return[bundleLocalData]]];
  dimensions = If[AssociationQ[deferredBundle],
    Rest[deferredBundle["Dimensions"]],
    Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      (! AssociationQ[deferredBundle] &&
        Dimensions[strip[[3]]] =!= Prepend[dimensions, 2]) ||
      Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticStripFailure["InvalidStripDimensions"]]];
  oneForms = OptionValue["OneForms"];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  gaugeDenominator = Together[OptionValue["GaugeDenominator"]];
  If[TrueQ[gaugeDenominator === 0],
    Return[multiquadraticStripFailure["ZeroGaugeDenominator"]]];
  coefficientPayload = multiquadraticStripCoefficientABIPayload[
    variables, epsilon, roots, dimensions, oneForms, gaugeDenominator];
  If[coefficientPayload === $Failed,
    Return[multiquadraticStripFailure["CoefficientABIFailed"]]];
  coefficientFingerprint = multiquadraticStripFingerprint[
    coefficientPayload];
  requestedFingerprint = OptionValue["CoefficientABIFingerprint"];
  If[requestedFingerprint =!= Automatic &&
      requestedFingerprint =!= coefficientFingerprint,
    Return[multiquadraticStripFailure["ProviderLayoutMismatch",
      <|"Expected" -> requestedFingerprint,
        "Observed" -> coefficientFingerprint|>]]];
  sourceFingerprint = OptionValue["SourceFingerprint"];
  If[sourceFingerprint === Automatic,
    canonicalData = multiquadraticStripCoreCanonicalData[record, roots,
      variables, epsilon];
    If[! AssociationQ[canonicalData],
      Return[multiquadraticStripFailure["ProviderSourceFingerprintFailed"]]];
    sourceFingerprint = Hash[canonicalData["EquationCanonical"], "SHA256",
      "HexString"]];
  If[! StringQ[sourceFingerprint],
    Return[multiquadraticStripFailure["InvalidProviderSourceFingerprint"]]];
  entries = If[AssociationQ[deferredBundle],
    <|"E" -> strip[[1]], "C" -> strip[[2]]|>,
    <|"E" -> strip[[1]], "C" -> strip[[2]], "BBar" -> strip[[3]]|>];
  activeRoots = Map[multiquadraticStripEntryActiveRoots[#1, roots] &,
    entries, {4}];
  oneFormActive = Map[multiquadraticStripEntryActiveRoots[#1, roots] &,
    oneForms, {2}];
  (* symbolic ONCE: d_mu Q / Q and d_mu Delta_a / Delta_a.  Both are
     small rational objects, and both are what the row assembler needs to
     differentiate the gauge basis without differentiating anything at a
     point. *)
  gaugeLog = Table[Together[D[gaugeDenominator, variables[[mu]]]/
    gaugeDenominator], {mu, 2}];
  rootLog = Table[Together[D[Lookup[roots[[a]], "RootSquare", 1],
      variables[[mu]]]/Lookup[roots[[a]], "RootSquare", 1]],
    {a, Length[roots]}, {mu, 2}];
  result = <|"Status" -> "MultiquadraticDirectProviderV1",
    "Kind" -> kind, "Roots" -> roots, "RootCount" -> Length[roots],
    "GradeCount" -> 2^Length[roots],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "Entries" -> entries, "ActiveRoots" -> activeRoots,
    "DeferredBundle" -> If[AssociationQ[deferredBundle], deferredBundle,
      Missing["NoDeferredBundle"]],
    "DeferredBundleFingerprint" -> bundleFingerprint,
    "BundleOperandExpressions" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandExpressions"],
      Missing["NoDeferredBundle"]],
    "BundleOperandRootMasks" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandRootMasks"], Missing["NoDeferredBundle"]],
    "BundleOperandActiveRoots" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandActiveRoots"], Missing["NoDeferredBundle"]],
    "BundleCoefficientExpressions" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientExpressions"],
      Missing["NoDeferredBundle"]],
    "BundleCoefficientRootMasks" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientRootMasks"],
      Missing["NoDeferredBundle"]],
    "BundleCoefficientActiveRoots" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientActiveRoots"],
      Missing["NoDeferredBundle"]],
    "OneForms" -> oneForms, "OneFormActiveRoots" -> oneFormActive,
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeLogDerivatives" -> gaugeLog, "RootLogDerivatives" -> rootLog,
    "CoefficientABIPayload" -> coefficientPayload,
    "CoefficientABIFingerprint" -> coefficientFingerprint,
    "SourceFingerprint" -> sourceFingerprint,
    "ActiveRootHistogram" -> Counts[Flatten[
      Values[Map[Length, activeRoots, {4}]]]],
    "CensusSeconds" -> AbsoluteTime[] - startTime|>;
  Append[result, "ProviderFingerprint" -> multiquadraticStripFingerprint[
    {kind, coefficientFingerprint, sourceFingerprint, bundleFingerprint}]]
];
multiquadraticStripDirectProvider[___] :=
  multiquadraticStripFailure["InvalidDirectProviderArguments"];

multiquadraticStripProviderValidQ[provider_Association] := Module[
  {kind, assembly, payload, coefficientFingerprint, expectedProvider,
   bundle, bundleValidation, bundleLocalData},
  kind = Lookup[provider, "Kind", None];
  Which[
    Lookup[provider, "Status", None] ===
        "MultiquadraticCoefficientProviderV1" && kind === "CompiledChannel",
      assembly = Lookup[provider, "Assembly", $Failed];
      If[! multiquadraticStripCompiledValidQ[assembly], Return[False]];
      expectedProvider = multiquadraticStripCompiledProvider[assembly];
      TrueQ[KeyTake[provider, {"Status", "Kind", "CoefficientABIFingerprint",
          "RootCount", "GradeCount", "Dimensions", "ProviderFingerprint"}] ===
        KeyTake[expectedProvider, {"Status", "Kind",
          "CoefficientABIFingerprint", "RootCount", "GradeCount",
          "Dimensions", "ProviderFingerprint"}]],
    Lookup[provider, "Status", None] === "MultiquadraticDirectProviderV1" &&
        MemberQ[{"SplitBranch", "QuotientGrade"}, kind],
      payload = multiquadraticStripCoefficientABIPayload[
        provider["Variables"], provider["Regulator"], provider["Roots"],
        provider["Dimensions"], provider["OneForms"],
        provider["GaugeDenominator"]];
      If[payload === $Failed, Return[False]];
      coefficientFingerprint = multiquadraticStripFingerprint[payload];
      bundle = Lookup[provider, "DeferredBundle", None];
      If[AssociationQ[bundle],
        bundleValidation = blockEquationDeferredBundleValidate[bundle];
        If[Lookup[bundleValidation, "Status", None] =!= "BundleValid" ||
            Lookup[provider, "DeferredBundleFingerprint", None] =!=
              Lookup[bundle, "BundleFingerprint", None],
          Return[False]];
        bundleLocalData = multiquadraticStripBundleLocalData[bundle,
          provider["Roots"], provider["Variables"]];
        If[Lookup[bundleLocalData, "Status", None] =!=
              "MultiquadraticBundleLocalDataV1" ||
            KeyTake[provider, {"BundleOperandExpressions",
                "BundleOperandRootMasks", "BundleOperandActiveRoots",
                "BundleCoefficientExpressions",
                "BundleCoefficientRootMasks",
                "BundleCoefficientActiveRoots"}] =!= <|
              "BundleOperandExpressions" ->
                bundleLocalData["OperandExpressions"],
              "BundleOperandRootMasks" ->
                bundleLocalData["OperandRootMasks"],
              "BundleOperandActiveRoots" ->
                bundleLocalData["OperandActiveRoots"],
              "BundleCoefficientExpressions" ->
                bundleLocalData["CoefficientExpressions"],
              "BundleCoefficientRootMasks" ->
                bundleLocalData["CoefficientRootMasks"],
              "BundleCoefficientActiveRoots" ->
                bundleLocalData["CoefficientActiveRoots"]|>,
          Return[False]],
        If[Lookup[provider, "DeferredBundleFingerprint", None] =!= None,
          Return[False]]];
      TrueQ[provider["CoefficientABIPayload"] === payload &&
        provider["CoefficientABIFingerprint"] === coefficientFingerprint &&
        provider["RootCount"] === Length[provider["Roots"]] &&
        provider["GradeCount"] === 2^provider["RootCount"] &&
        provider["ProviderFingerprint"] === multiquadraticStripFingerprint[
          {kind, coefficientFingerprint, provider["SourceFingerprint"],
            Lookup[provider, "DeferredBundleFingerprint", None]}]],
    True, False]
];
multiquadraticStripProviderValidQ[___] := False;

(* A provider is authenticated once at an API boundary.  Recomputing the
   coefficient ABI and deeply validating a deferred DAG at every sampled
   point made bundle validation part of the finite-field hot loop.  Inside a
   dynamically scoped, already-authenticated evaluation this predicate checks
   only the small immutable seal.  Public/private entry points still use the
   full validator above. *)
$multiquadraticStripTrustedProviderEvaluation = False;

multiquadraticStripProviderHotValidQ[provider_Association] := Module[
  {kind = Lookup[provider, "Kind", None], status, rootCount, gradeCount,
   dimensions, bundle, bundleFingerprint, expectedFingerprint, assembly},
  status = Lookup[provider, "Status", None];
  rootCount = Lookup[provider, "RootCount", $Failed];
  gradeCount = Lookup[provider, "GradeCount", $Failed];
  dimensions = Lookup[provider, "Dimensions", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 ||
      gradeCount =!= 2^rootCount ||
      ! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! StringQ[Lookup[provider, "CoefficientABIFingerprint", None]] ||
      ! StringQ[Lookup[provider, "ProviderFingerprint", None]],
    Return[False]];
  Which[
    status === "MultiquadraticCoefficientProviderV1" &&
        kind === "CompiledChannel",
      assembly = Lookup[provider, "Assembly", $Failed];
      If[! AssociationQ[assembly] ||
          ! StringQ[Lookup[assembly, "AssemblyFingerprint", None]],
        Return[False]];
      expectedFingerprint = multiquadraticStripFingerprint[{
        "CompiledChannel", provider["CoefficientABIFingerprint"],
        assembly["AssemblyFingerprint"]}];
      TrueQ[provider["ProviderFingerprint"] === expectedFingerprint],
    status === "MultiquadraticDirectProviderV1" &&
        MemberQ[{"SplitBranch", "QuotientGrade"}, kind],
      If[! ListQ[Lookup[provider, "Roots", $Failed]] ||
          Length[provider["Roots"]] =!= rootCount ||
          ! StringQ[Lookup[provider, "SourceFingerprint", None]],
        Return[False]];
      bundle = Lookup[provider, "DeferredBundle", None];
      bundleFingerprint = Lookup[provider, "DeferredBundleFingerprint", None];
      If[AssociationQ[bundle],
        If[! StringQ[bundleFingerprint] ||
            Lookup[bundle, "BundleFingerprint", None] =!= bundleFingerprint,
          Return[False]],
        If[bundleFingerprint =!= None, Return[False]]];
      expectedFingerprint = multiquadraticStripFingerprint[{kind,
        provider["CoefficientABIFingerprint"],
        provider["SourceFingerprint"], bundleFingerprint}];
      TrueQ[provider["ProviderFingerprint"] === expectedFingerprint],
    True, False]
];
multiquadraticStripProviderHotValidQ[___] := False;

multiquadraticStripProviderEvaluationValidQ[provider_] := If[
  TrueQ[$multiquadraticStripTrustedProviderEvaluation],
  multiquadraticStripProviderHotValidQ[provider],
  multiquadraticStripProviderValidQ[provider]];

(* A SplitBranch plan binds one provider and prime to UNIQUE
   (expression, active-root subset) leaves plus integer occurrence maps.
   Construction uses an in-memory bucket and exact SameQ collision resolution;
   hot points and later epsilon fibres reach leaves solely by integer position.
   Compilation failures retain the exact historical substitution/grade
   fallback. *)
multiquadraticStripSplitSparseEvaluationPlan[provider_Association,
    prime_Integer] := Module[
  {startTime = AbsoluteTime[], cacheKey, cached, roots, scalarVariables,
   leaves = {}, buckets = <||>, register, entries, entryActive, entryMaps,
   registerAtLevel, oneFormMap, bundle, operandMap = {}, coefficientMap = {},
   operandTable = {}, structuredOperands = <||>, compileLeaf, compileSeconds,
   compiled, compileInvocationCount = 0, compiledLeafCount, plan,
   occurrenceCount, exactCacheKey, exactCached, exactLeaves,
   exactPlanCacheHit = False, exactCompileSeconds = 0., leafIndex},
  If[! multiquadraticStripProviderEvaluationValidQ[provider] ||
      Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[multiquadraticStripFailure[
      "InvalidSplitSparseEvaluationPlanInput"]]];
  cacheKey = StringJoin["SplitSparsePlan:",
    provider["ProviderFingerprint"], ":", ToString[prime]];
  If[KeyExistsQ[$multiquadraticStripSplitSparsePlanCache, cacheKey],
    cached = $multiquadraticStripSplitSparsePlanCache[cacheKey];
    If[multiquadraticStripSplitSparseEvaluationPlanHotValidQ[cached,
        provider, prime],
      Return[Join[cached, <|"PlanCacheHit" -> True,
        "BuildCompileInvocationCount" -> 0,
        "BuildSeconds" -> N[AbsoluteTime[] - startTime]|>]],
      KeyDropFrom[$multiquadraticStripSplitSparsePlanCache, cacheKey]]];
  roots = provider["Roots"];
  scalarVariables = Join[provider["Variables"], {provider["Regulator"]}];
  exactCacheKey = provider["ProviderFingerprint"];
  exactCached = Lookup[$multiquadraticStripSplitSparseExactPlanCache,
    exactCacheKey, Missing["NotFound"]];
  If[AssociationQ[exactCached],
    leaves = exactCached["Leaves"];
    entryMaps = exactCached["OccurrenceMaps", "Entries"];
    oneFormMap = exactCached["OccurrenceMaps", "OneForms"];
    operandMap = exactCached["OccurrenceMaps", "BundleOperands"];
    coefficientMap = exactCached["OccurrenceMaps", "BundleCoefficients"];
    exactLeaves = exactCached["ExactLeaves"];
    exactPlanCacheHit = True,
    register[expression_, activeIndices_List] := Module[
      {bucketKey, candidates, index},
      bucketKey = Hash[{expression, activeIndices}];
      candidates = Lookup[buckets, bucketKey, {}];
      index = SelectFirst[candidates,
        SameQ[leaves[[#1, "Expression"]], expression] &&
          SameQ[leaves[[#1, "ActiveRoots"]], activeIndices] &,
        Missing["NotFound"]];
      If[MissingQ[index],
        AppendTo[leaves, <|"Expression" -> expression,
          "ActiveRoots" -> activeIndices|>];
        index = Length[leaves];
        AssociateTo[buckets, bucketKey -> Append[candidates, index]]];
      index];
    (* Active-root subsets are themselves lists, so MapThread at the scalar
       level descends one dimension too far.  Ragged deferred-job term lists
       make that especially visible: scalar coefficients are paired against
       the elements of their root-index lists instead of against the lists.
       Position-based pairing preserves the tensor/job structure exactly. *)
    registerAtLevel[expressions_, active_, level_Integer] :=
      MapIndexed[Function[{expression, position},
        register[expression, Extract[active, position]]],
        expressions, {level}];
    entries = provider["Entries"];
    entryActive = provider["ActiveRoots"];
    entryMaps = Association[Table[key -> registerAtLevel[
        entries[key], entryActive[key], 3], {key, Keys[entries]}]];
    oneFormMap = If[provider["OneForms"] === {}, {},
      registerAtLevel[provider["OneForms"],
        provider["OneFormActiveRoots"], 2]];
    bundle = Lookup[provider, "DeferredBundle", None];
    If[AssociationQ[bundle],
      operandMap = registerAtLevel[provider["BundleOperandExpressions"],
        provider["BundleOperandActiveRoots"], 1];
      coefficientMap = registerAtLevel[
        provider["BundleCoefficientExpressions"],
        provider["BundleCoefficientActiveRoots"], 2];
      operandTable = Lookup[bundle, "OperandTable", {}];
      If[Length[operandTable] === Length[operandMap],
        Do[If[! KeyExistsQ[structuredOperands, operandMap[[index]]],
          AssociateTo[structuredOperands,
            operandMap[[index]] -> operandTable[[index]]]],
          {index, Length[operandMap]}]]];
    compileLeaf[leaf_Association, index_Integer] := Module[
      {activeRoots = roots[[leaf["ActiveRoots"]]], rootSymbols},
      rootSymbols = Take[$multiquadraticStripSplitRootSymbols,
        Length[leaf["ActiveRoots"]]];
      If[KeyExistsQ[structuredOperands, index],
        multiquadraticStripScreenCompileFactoredScalarExact[
          structuredOperands[index, "Numerator"],
          structuredOperands[index, "DenominatorFactors"], activeRoots,
          rootSymbols, scalarVariables],
        multiquadraticStripScreenCompileScalarExact[leaf["Expression"],
          activeRoots, rootSymbols, scalarVariables]]];
    {exactCompileSeconds, exactLeaves} = AbsoluteTiming[
      If[TrueQ[$multiquadraticStripSplitSparseCompilation],
        MapIndexed[compileLeaf[#1, First[#2]] &, leaves],
        ConstantArray[$Failed, Length[leaves]]]];
    multiquadraticStripCacheInsert[
      $multiquadraticStripSplitSparseExactPlanCache, exactCacheKey,
      <|"Leaves" -> leaves, "ExactLeaves" -> exactLeaves,
        "OccurrenceMaps" -> <|"Entries" -> entryMaps,
          "OneForms" -> oneFormMap, "BundleOperands" -> operandMap,
          "BundleCoefficients" -> coefficientMap|>|>, 2]];
  leaves = MapIndexed[Function[{leaf, position},
    leafIndex = First[position];
    If[TrueQ[$multiquadraticStripSplitSparseCompilation],
      compileInvocationCount++;
      {compileSeconds, compiled} = AbsoluteTiming[
        If[AssociationQ[exactLeaves[[leafIndex]]],
          multiquadraticStripScreenReduceScalar[
            exactLeaves[[leafIndex]], prime], $Failed]],
      compileSeconds = 0.; compiled = $Failed];
    Join[leaf, <|"Compiled" -> If[AssociationQ[compiled], compiled, $Failed],
      "CompileSeconds" -> compileSeconds|>]], leaves];
  compiledLeafCount = Count[Lookup[leaves, "Compiled", {}], _Association];
  occurrenceCount = Total[Length[Flatten[#1]] & /@ Join[
    Values[entryMaps], {oneFormMap, operandMap, coefficientMap}]];
  plan = <|"Status" -> "MultiquadraticSplitSparseEvaluationPlanV1",
    "Schema" -> "MultiquadraticSplitSparseEvaluationPlanV1",
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "CoefficientABIFingerprint" -> provider["CoefficientABIFingerprint"],
    "Prime" -> prime, "RootCount" -> provider["RootCount"],
    "Leaves" -> leaves,
    "OccurrenceMaps" -> <|"Entries" -> entryMaps,
      "OneForms" -> oneFormMap, "BundleOperands" -> operandMap,
      "BundleCoefficients" -> coefficientMap|>,
    "UniqueLeafCount" -> Length[leaves],
    "OccurrenceCount" -> occurrenceCount,
    "CompileInvocationCount" -> compileInvocationCount,
    "CompiledLeafCount" -> compiledLeafCount,
    "FallbackLeafCount" -> Length[leaves] - compiledLeafCount,
    "CompileSeconds" -> Total[Lookup[leaves, "CompileSeconds", 0.]],
    "ExactPlanCacheHit" -> exactPlanCacheHit,
    "ExactCompileSeconds" -> exactCompileSeconds,
    "PlanCacheHit" -> False,
    "BuildCompileInvocationCount" -> compileInvocationCount,
    "PlanFingerprint" -> cacheKey|>;
  plan = Append[plan, "BuildSeconds" -> N[AbsoluteTime[] - startTime]];
  multiquadraticStripCacheInsert[$multiquadraticStripSplitSparsePlanCache,
    cacheKey, plan, 8]
];
multiquadraticStripSplitSparseEvaluationPlan[___] :=
  multiquadraticStripFailure[
    "InvalidSplitSparseEvaluationPlanArguments"];

multiquadraticStripSplitSparseEvaluationPlanHotValidQ[plan_Association,
    provider_Association, prime_Integer] := Module[
  {leaves = Lookup[plan, "Leaves", $Failed], maps, indices},
  maps = Lookup[plan, "OccurrenceMaps", $Failed];
  indices = If[AssociationQ[maps] &&
      AssociationQ[Lookup[maps, "Entries", $Failed]],
    Flatten[Join[Values[maps["Entries"]],
      {Lookup[maps, "OneForms", {}],
       Lookup[maps, "BundleOperands", {}],
       Lookup[maps, "BundleCoefficients", {}]}]], $Failed];
  TrueQ[Lookup[plan, "Status", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[plan, "Schema", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[provider, "Kind", None] === "SplitBranch" &&
    Lookup[plan, "ProviderFingerprint", None] ===
      Lookup[provider, "ProviderFingerprint", Missing["NoProvider"]] &&
    Lookup[plan, "CoefficientABIFingerprint", None] ===
      Lookup[provider, "CoefficientABIFingerprint", Missing["NoABI"]] &&
    Lookup[plan, "Prime", None] === prime && PrimeQ[prime] &&
    Lookup[plan, "RootCount", None] === Lookup[provider, "RootCount", None] &&
    ListQ[leaves] && AssociationQ[maps] &&
    StringQ[Lookup[plan, "PlanFingerprint", None]] &&
    VectorQ[indices, IntegerQ[#1] && 1 <= #1 <= Length[leaves] &]]
];
multiquadraticStripSplitSparseEvaluationPlanHotValidQ[___] := False;

multiquadraticStripSplitSparseEvaluationPlanValidQ[plan_Association,
    provider_Association, prime_Integer] := Module[
  {leaves, maps, entryMaps, match, matchAtLevel, entries, active, entryOK,
   oneFormOK, bundle, operandOK, coefficientOK, leafOK},
  If[! multiquadraticStripProviderHotValidQ[provider] ||
      ! multiquadraticStripSplitSparseEvaluationPlanHotValidQ[plan,
        provider, prime], Return[False]];
  leaves = plan["Leaves"]; maps = plan["OccurrenceMaps"];
  entryMaps = Lookup[maps, "Entries", $Failed];
  If[! AssociationQ[entryMaps] ||
      Sort[Keys[entryMaps]] =!= Sort[Keys[provider["Entries"]]],
    Return[False]];
  leafOK = AllTrue[leaves, Function[leaf,
    AssociationQ[leaf] &&
      VectorQ[Lookup[leaf, "ActiveRoots", $Failed], IntegerQ] &&
      DuplicateFreeQ[leaf["ActiveRoots"]] &&
      Sort[leaf["ActiveRoots"]] === leaf["ActiveRoots"] &&
      AllTrue[leaf["ActiveRoots"],
        1 <= #1 <= provider["RootCount"] &] &&
      (AssociationQ[Lookup[leaf, "Compiled", None]] ||
        Lookup[leaf, "Compiled", None] === $Failed)]];
  If[! leafOK, Return[False]];
  match[expression_, activeIndices_, index_] := IntegerQ[index] &&
    1 <= index <= Length[leaves] &&
    SameQ[leaves[[index, "Expression"]], expression] &&
    SameQ[leaves[[index, "ActiveRoots"]], activeIndices];
  matchAtLevel[expressions_, activeRoots_, indices_, level_Integer] :=
    TrueQ[And @@ Flatten[MapIndexed[Function[{expression, position},
      match[expression, Extract[activeRoots, position],
        Extract[indices, position]]], expressions, {level}]]];
  entries = provider["Entries"]; active = provider["ActiveRoots"];
  entryOK = And @@ Flatten[Table[
    matchAtLevel[entries[key], active[key], entryMaps[key], 3],
    {key, Keys[entries]}]];
  oneFormOK = If[provider["OneForms"] === {},
    Lookup[maps, "OneForms", $Failed] === {},
    matchAtLevel[provider["OneForms"], provider["OneFormActiveRoots"],
      Lookup[maps, "OneForms", $Failed], 2]];
  bundle = Lookup[provider, "DeferredBundle", None];
  If[AssociationQ[bundle],
    operandOK = matchAtLevel[provider["BundleOperandExpressions"],
      provider["BundleOperandActiveRoots"],
      Lookup[maps, "BundleOperands", $Failed], 1];
    coefficientOK = matchAtLevel[
      provider["BundleCoefficientExpressions"],
      provider["BundleCoefficientActiveRoots"],
      Lookup[maps, "BundleCoefficients", $Failed], 2],
    operandOK = Lookup[maps, "BundleOperands", $Failed] === {};
    coefficientOK = Lookup[maps, "BundleCoefficients", $Failed] === {}];
  TrueQ[entryOK && oneFormOK && operandOK && coefficientOK &&
    plan["UniqueLeafCount"] === Length[leaves] &&
    plan["OccurrenceCount"] === Total[Length[Flatten[#1]] & /@
      Join[Values[entryMaps], {maps["OneForms"], maps["BundleOperands"],
        maps["BundleCoefficients"]}]] &&
    plan["PlanFingerprint"] === StringJoin["SplitSparsePlan:",
      provider["ProviderFingerprint"], ":", ToString[prime]]]
];
multiquadraticStripSplitSparseEvaluationPlanValidQ[___] := False;

multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[plan_,
    provider_, prime_] := If[
  TrueQ[$multiquadraticStripTrustedSplitSparsePlanEvaluation],
  multiquadraticStripSplitSparseEvaluationPlanHotValidQ[plan, provider, prime],
  multiquadraticStripSplitSparseEvaluationPlanValidQ[plan, provider, prime]];

multiquadraticStripSplitSparsePlannedEntry[plan_Association,
    index_Integer, provider_Association, scalarRules_Association,
    deltaValues_List, rootValues_List, prime_Integer] := Module[{leaf},
  If[index < 1 || index > Length[plan["Leaves"]],
    Return[multiquadraticStripFailure[
      "SplitSparsePlanOccurrenceIndexInvalid", <|"Index" -> index|>]]];
  leaf = plan["Leaves"][[index]];
  multiquadraticStripSplitBranchEntry[leaf["Expression"], provider["Roots"],
    leaf["ActiveRoots"], scalarRules, deltaValues, rootValues, prime,
    leaf["Compiled"]]
];
multiquadraticStripSplitSparsePlannedEntry[___] :=
  multiquadraticStripFailure["InvalidSplitSparsePlannedEntryArguments"];

(* Native value arithmetic for an already compiled split plan.  The adapter
   receives one plan and all preflight-approved points of an image, evaluates
   every local sign branch with FLINT nmod arithmetic, projects to local
   channels and lifts to the declared global grade order.  The protocol is a
   temporary-file transport only: correctness is tested against the existing
   Wolfram evaluator, not against metadata or a second cache identity. *)
multiquadraticStripNativeSparseBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_sparse_eval"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripNativeSparseWritePlan[plan_Association,
    file_String] := Module[
  {stream = None, leaves = Lookup[plan, "Leaves", $Failed], prime,
   rootCount, numeratorFactors, denominatorFactors, numeratorTerms,
   denominatorTerms, active, sideFactors, writePolynomial,
   writeFactor, ok = False},
  If[! ListQ[leaves] || leaves === {} ||
      ! AllTrue[Lookup[leaves, "Compiled", {}], AssociationQ],
    Return[False]];
  prime = Lookup[plan, "Prime", $Failed];
  rootCount = Lookup[plan, "RootCount", $Failed];
  If[! PrimeQ[prime] || ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}],
    Return[False]];
  sideFactors[compiled_Association, side_String] := If[
    Lookup[compiled, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    Lookup[compiled, side <> "Factors", $Failed],
    {<|"Polynomial" -> Lookup[compiled, side, $Failed], "Power" -> 1|>}];
  numeratorFactors = sideFactors[#1["Compiled"], "Numerator"] & /@ leaves;
  denominatorFactors = sideFactors[#1["Compiled"], "Denominator"] & /@ leaves;
  If[! MatchQ[numeratorFactors, {{__Association} ..}] ||
      ! MatchQ[denominatorFactors, {{__Association} ..}] ||
      ! AllTrue[Flatten[{numeratorFactors, denominatorFactors}],
        MatchQ[#1, _Association] &&
          AssociationQ[Lookup[#1, "Polynomial", None]] &&
          IntegerQ[Lookup[#1, "Power", None]] && #1["Power"] > 0 &],
    Return[False]];
  numeratorTerms = Total[Length[#1["Polynomial", "Coefficients"]] & /@
    Flatten[numeratorFactors]];
  denominatorTerms = Total[Length[#1["Polynomial", "Coefficients"]] & /@
    Flatten[denominatorFactors]];
  writePolynomial[polynomial_Association] := Module[{rows},
    rows = MapThread[Prepend,
      {polynomial["Exponents"], polynomial["Coefficients"]}];
    BinaryWrite[stream, Flatten[rows], "UnsignedInteger64",
      ByteOrdering -> -1]];
  writeFactor[factor_Association] := (
    BinaryWrite[stream, {factor["Power"],
        Length[factor["Polynomial", "Coefficients"]]},
      "UnsignedInteger64", ByteOrdering -> -1];
    writePolynomial[factor["Polynomial"]]);
  Quiet[Check[
    stream = OpenWrite[file, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["MQSE1P2\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {prime, rootCount, Length[leaves],
        Total[Length /@ numeratorFactors],
        Total[Length /@ denominatorFactors], numeratorTerms,
        denominatorTerms}, "UnsignedInteger64", ByteOrdering -> -1];
    Do[
      active = leaves[[index, "ActiveRoots"]];
      BinaryWrite[stream, {Total[2^(active - 1)], Length[active],
          Length[numeratorFactors[[index]]],
          Length[denominatorFactors[[index]]]},
        "UnsignedInteger64", ByteOrdering -> -1];
      writeFactor /@ numeratorFactors[[index]];
      writeFactor /@ denominatorFactors[[index]],
      {index, Length[leaves]}];
    Close[stream]; stream = None; ok = True,
    If[Head[stream] === OutputStream, Quiet[Close[stream]]]; ok = False]];
  ok
];
multiquadraticStripNativeSparseWritePlan[___] := False;

multiquadraticStripNativeSparseEvaluateBatch[plan_Association,
    preflights_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], binary, prime, rootCount, leafCount,
   gradeCount, directory = None, planFile, pointFile, outputFile,
   stream = None, rows, process, magic, header, statuses, channels,
   planWriteSeconds = 0., pointWriteSeconds = 0., adapterSeconds = 0.,
   readSeconds = 0., result, tag},
  tag = Unique["MultiquadraticNativeSparseBatchFailure"];
  binary = multiquadraticStripNativeSparseBinary[];
  prime = Lookup[plan, "Prime", $Failed];
  rootCount = Lookup[plan, "RootCount", $Failed];
  leafCount = Length[Lookup[plan, "Leaves", {}]];
  gradeCount = If[IntegerQ[rootCount], 2^rootCount, 0];
  If[! StringQ[binary] || preflights === {} ||
      ! Between[threads, {1, 8}] || ! PrimeQ[prime] ||
      ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      leafCount < 1 || ! AllTrue[preflights,
        Lookup[#1, "Status", None] ===
            "MultiquadraticProviderPreflightV1" &&
          Lookup[#1, "Prime", None] === prime &&
          Length[Lookup[#1, "RootValues", {}]] === rootCount &],
    Return[multiquadraticStripFailure[
      "InvalidNativeSparseBatchInput"]]];
  result = Catch[
    directory = CreateDirectory[];
    planFile = FileNameJoin[{directory, "plan.bin"}];
    pointFile = FileNameJoin[{directory, "points.bin"}];
    outputFile = FileNameJoin[{directory, "channels.bin"}];
    {planWriteSeconds, result} = AbsoluteTiming[
      multiquadraticStripNativeSparseWritePlan[plan, planFile]];
    If[! TrueQ[result],
      Throw[multiquadraticStripFailure[
        "NativeSparsePlanWriteFailed"], tag]];
    rows = Join[Lookup[#1, "Point", {}],
        {Lookup[#1, "EpsilonMod", $Failed]},
        Lookup[#1, "RootValues", {}]] & /@ preflights;
    {pointWriteSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenWrite[pointFile, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["MQSE1Q1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {prime, rootCount, leafCount, Length[preflights]},
        "UnsignedInteger64", ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[rows], "UnsignedInteger64",
        ByteOrdering -> -1];
      Close[stream]; stream = None; True, False]]];
    If[! TrueQ[result],
      If[Head[stream] === OutputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeSparsePointWriteFailed"], tag]];
    {adapterSeconds, process} = AbsoluteTiming[RunProcess[
      taskBrokerNativeCommand[
        {binary, planFile, pointFile, outputFile, ToString[threads]}, threads]]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0,
      Throw[multiquadraticStripFailure[
        "NativeSparseAdapterFailed"], tag]];
    {readSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenRead[outputFile, BinaryFormat -> True];
      magic = BinaryReadList[stream, "UnsignedInteger8", 8];
      header = BinaryReadList[stream, "UnsignedInteger64", 4,
        ByteOrdering -> -1];
      statuses = BinaryReadList[stream, "UnsignedInteger64",
        Length[preflights] leafCount, ByteOrdering -> -1];
      channels = BinaryReadList[stream, "UnsignedInteger64",
        Length[preflights] leafCount gradeCount, ByteOrdering -> -1];
      Close[stream]; stream = None;
      If[magic =!= ToCharacterCode["MQSE1X1\000"] ||
          header =!= {prime, rootCount, leafCount, Length[preflights]} ||
          Length[statuses] =!= Length[preflights] leafCount ||
          ! AllTrue[statuses, MemberQ[{0, 1}, #1] &] ||
          Length[channels] =!= Length[preflights] leafCount gradeCount ||
          ! AllTrue[channels, 0 <= #1 < prime &], $Failed,
        <|"Status" -> "MultiquadraticNativeSparseBatchV1",
          "LeafStatuses" -> ArrayReshape[statuses,
            {Length[preflights], leafCount}],
          "Channels" -> ArrayReshape[channels,
            {Length[preflights], leafCount, gradeCount}],
          "Threads" -> threads|>], $Failed]]];
    If[! AssociationQ[result],
      If[Head[stream] === InputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeSparseResponseInvalid"], tag]];
    Join[result, <|"PlanWriteSeconds" -> planWriteSeconds,
      "PointWriteSeconds" -> pointWriteSeconds,
      "AdapterSeconds" -> adapterSeconds,
      "ResponseReadSeconds" -> readSeconds|>],
    tag, #1 &];
  If[StringQ[directory] && DirectoryQ[directory],
    Quiet[DeleteDirectory[directory, DeleteContents -> True]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - startTime]], result]
];
multiquadraticStripNativeSparseEvaluateBatch[___] :=
  multiquadraticStripFailure["InvalidNativeSparseBatchArguments"];

(* A preserved BlockEquationDeferred preparation is already the arithmetic
   DAG of the forcing.  Evaluate that DAG at every split point in one native
   batch instead of first materializing and canonicalizing its whole rational
   functions.  The provider still owns E, C, Q and the one-form basis; this
   adapter replaces only BBar before the existing row assembler is called. *)
multiquadraticStripNativeDeferredBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_deferred_ast_eval"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripAttachDeferredPreparation[provider_Association,
    preparation_Association, inputFile_String] := Module[{seal},
  (* The caller has just constructed the provider and the ordinary boundary
     immediately below performs the one full validation.  Re-running the
     bundle traversal here would make attachment itself duplicate the large
     provider work; the immutable small seal is sufficient at this seam. *)
  If[! multiquadraticStripProviderHotValidQ[provider] ||
      ! FileExistsQ[inputFile] ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion ||
      Lookup[preparation, "Variables", None] =!= provider["Variables"] ||
      Lookup[preparation, "Regulator", None] =!= provider["Regulator"] ||
      Lookup[preparation, "Dimensions", None] =!=
        Prepend[provider["Dimensions"], 2] ||
      Lookup[preparation, "SourceFingerprint", None] =!=
        provider["SourceFingerprint"],
    Return[multiquadraticStripFailure[
      "InvalidDeferredPreparationProvider"]]];
  (* Never attach the large Records forest to a provider that is serialized
     for every image.  Its existing source fingerprint and this small shape
     seal identify the immutable file; no second full-payload hash is made. *)
  seal = KeyTake[preparation, {"Status", "ABIVersion", "SourceFingerprint",
    "Variables", "Regulator", "Dimensions"}];
  Join[provider, <|"DeferredPreparation" -> seal,
    "DeferredPreparationFile" -> inputFile|>]
];
multiquadraticStripAttachDeferredPreparation[___] :=
  multiquadraticStripFailure[
    "InvalidDeferredPreparationProviderArguments"];

multiquadraticStripNativeDeferredWriteRequest[file_String,
    provider_Association, preflights_List] := Module[
  {variables, regulator, roots, prime, lines, rootLines, imageLines},
  variables = Lookup[provider, "Variables", $Failed];
  regulator = Lookup[provider, "Regulator", $Failed];
  roots = Lookup[provider, "Roots", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[roots, {___Association}] || preflights === {},
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredRequestInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] || ! AllTrue[preflights,
      Lookup[#1, "Status", None] ===
          "MultiquadraticProviderPreflightV1" &&
        Lookup[#1, "Prime", None] === prime &&
        Lookup[#1, "ProviderFingerprint", None] ===
          provider["ProviderFingerprint"] &&
        Length[Lookup[#1, "RootSquares", {}]] === Length[roots] &&
        Length[Lookup[#1, "RootValues", {}]] === Length[roots] &],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredPreflightBatch", <|
        "Statuses" -> Lookup[preflights, "Status", None],
        "ObservedPrimes" -> Lookup[preflights, "Prime", None],
        "ExpectedPrime" -> prime,
        "ObservedProviderFingerprints" ->
          Lookup[preflights, "ProviderFingerprint", None],
        "ExpectedProviderFingerprint" ->
          Lookup[provider, "ProviderFingerprint", None],
        "RootSquareCounts" ->
          (Length[Lookup[#1, "RootSquares", {}]] & /@ preflights),
        "RootValueCounts" ->
          (Length[Lookup[#1, "RootValues", {}]] & /@ preflights),
        "ExpectedRootCount" -> Length[roots]|>]]];
  rootLines = ("root " <> ToString[Lookup[#1, "RootSquare", $Failed],
      InputForm, PageWidth -> Infinity]) & /@ roots;
  imageLines = Function[preflight,
      "image " <> StringRiffle[ToString /@ Join[
        preflight["Point"], {preflight["EpsilonMod"]},
        Flatten[Transpose[{preflight["RootSquares"],
          preflight["RootValues"]}]]], " "]] /@ preflights;
  lines = Join[{"DeferredASTRequestV1", "prime " <> ToString[prime],
      "variables " <> StringRiffle[
        SymbolName /@ Join[variables, {regulator}], " "],
      "rank " <> ToString[Length[roots]]}, rootLines,
    {"base_count " <> ToString[Length[preflights]]}, imageLines];
  If[Quiet[Check[
      Export[file, StringRiffle[lines, "\n"] <> "\n", "Text"]; True,
      False]],
    <|"Status" -> "MultiquadraticNativeDeferredRequestV1",
      "Prime" -> prime, "BaseCount" -> Length[preflights],
      "RootCount" -> Length[roots]|>,
    multiquadraticStripFailure["NativeDeferredRequestWriteFailed"]]
];
multiquadraticStripNativeDeferredWriteRequest[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredRequestArguments"];

Options[multiquadraticStripNativeDeferredReadOutput] = {
  "Derivatives" -> False
};
multiquadraticStripNativeDeferredReadOutput[file_String,
    provider_Association, expectedPrime_Integer,
    expectedBaseCount_Integer, opts : OptionsPattern[]] := Module[
  {stream = None, magic, status, header, prime, rank, baseCount, gradeCount,
   recordCount, termCount, uniqueCount, dimensions, parseNanoseconds,
   evaluationNanoseconds, targets, values, trailing, expectedDimensions,
   expectedTargets, result, derivatives, componentCount, componentValues,
   batch},
  derivatives = TrueQ[OptionValue["Derivatives"]];
  componentCount = If[derivatives, 3, 1];
  result = Catch[Quiet[Check[
    stream = OpenRead[file, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    status = BinaryRead[stream, "UnsignedInteger64", ByteOrdering -> -1];
    header = BinaryReadList[stream, "UnsignedInteger64", 12,
      ByteOrdering -> -1];
    If[magic =!= ToCharacterCode[
          If[derivatives, "DAGO2V1\000", "DAGO1V1\000"]] ||
        ! IntegerQ[status] || Length[header] =!= 12,
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputHeaderInvalid"]]];
    If[status =!= 0,
      Throw[multiquadraticStripFailure["NativeDeferredEvaluatorRefused",
        <|"NativeStatusCode" -> status,
          "DetailIndex" -> header[[8]],
          "DetailOffset" -> header[[9]]|>]]];
    {prime, rank, baseCount, gradeCount, recordCount, termCount,
      uniqueCount} = Take[header, 7];
    dimensions = header[[8 ;; 10]];
    {parseNanoseconds, evaluationNanoseconds} = header[[11 ;; 12]];
    expectedDimensions = Prepend[provider["Dimensions"], 2];
    If[prime =!= expectedPrime || rank =!= provider["RootCount"] ||
        gradeCount =!= provider["GradeCount"] ||
        baseCount =!= expectedBaseCount ||
        dimensions =!= expectedDimensions ||
        recordCount =!= Times @@ expectedDimensions,
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputShapeMismatch",
        <|"Observed" -> {prime, rank, baseCount, gradeCount, dimensions,
            recordCount},
          "Expected" -> {expectedPrime, provider["RootCount"],
            expectedBaseCount, provider["GradeCount"], expectedDimensions,
            Times @@ expectedDimensions}|>]]];
    targets = ConstantArray[{}, recordCount];
    values = ConstantArray[{}, recordCount];
    Do[
      targets[[index]] = BinaryReadList[stream, "UnsignedInteger64", 3,
        ByteOrdering -> -1];
      values[[index]] = BinaryReadList[stream, "UnsignedInteger64",
        componentCount baseCount gradeCount, ByteOrdering -> -1],
      {index, recordCount}];
    trailing = BinaryRead[stream, "UnsignedInteger8"];
    Close[stream]; stream = None;
    expectedTargets = Flatten[Table[{mu, i, j},
      {mu, expectedDimensions[[1]]}, {i, expectedDimensions[[2]]},
      {j, expectedDimensions[[3]]}], 2];
    If[targets =!= expectedTargets || trailing =!= EndOfFile ||
        ! AllTrue[Flatten[values], IntegerQ[#1] && 0 <= #1 < prime &],
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputPayloadInvalid"]]];
    componentValues = Table[
      values[[All, (component - 1) baseCount gradeCount +
        Range[baseCount gradeCount]]], {component, componentCount}];
    batch[component_Integer] := Table[ArrayReshape[
      componentValues[[component, All,
        (base - 1) gradeCount + Range[gradeCount]]],
      Append[dimensions, gradeCount]], {base, baseCount}];
    Join[<|"Status" -> If[derivatives,
          "MultiquadraticNativeDeferredDerivativeBatchV1",
          "MultiquadraticNativeDeferredBatchV1"],
      "Prime" -> prime, "RootCount" -> rank,
      "GradeCount" -> gradeCount, "BaseCount" -> baseCount,
      "Dimensions" -> dimensions, "RecordCount" -> recordCount,
      "TermCount" -> termCount, "UniqueExpressionCount" -> uniqueCount,
      "ParseSeconds" -> N[parseNanoseconds/10.^9],
      "EvaluationSeconds" -> N[evaluationNanoseconds/10.^9],
      "BBarBatch" -> batch[1]|>,
      If[derivatives, <|"BBarDerivativeBatch" -> {batch[2], batch[3]}|>,
        <||>]],
    multiquadraticStripFailure["NativeDeferredOutputReadFailed"]]]];
  If[Head[stream] === InputStream, Quiet[Close[stream]]];
  result
];
multiquadraticStripNativeDeferredReadOutput[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredOutputArguments"];

Options[multiquadraticStripNativeDeferredEvaluateBatch] = {
  "Derivatives" -> False,
  "Threads" -> Automatic
};
multiquadraticStripNativeDeferredEvaluateBatch[provider_Association,
    preflights_List, opts : OptionsPattern[]] := Module[
  {started = AbsoluteTime[], binary, preparation, inputFile, directory = None,
   requestFile, outputFile, request, process, result, prime, derivatives,
   command, threads, actualThreads},
  derivatives = TrueQ[OptionValue["Derivatives"]];
  threads = Replace[OptionValue["Threads"],
    Automatic :> Clip[$ProcessorCount, {1, 8}]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredThreadCount", <|"Threads" -> threads|>]]];
  actualThreads = Min[threads, Length[preflights]];
  binary = multiquadraticStripNativeDeferredBinary[];
  preparation = Lookup[provider, "DeferredPreparation", None];
  inputFile = Lookup[provider, "DeferredPreparationFile", None];
  If[! StringQ[binary] || ! AssociationQ[preparation] ||
      ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion ||
      Lookup[preparation, "SourceFingerprint", None] =!=
        provider["SourceFingerprint"] || preflights === {},
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredBatchInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] ||
      ! AllTrue[preflights, Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure[
      "MixedNativeDeferredBatchPrimes"]]];
  result = Internal`WithLocalSettings[
    directory = CreateDirectory[];
    requestFile = FileNameJoin[{directory, "request.txt"}];
    outputFile = FileNameJoin[{directory, "output.bin"}];,
    request = multiquadraticStripNativeDeferredWriteRequest[requestFile,
      provider, preflights];
    If[Lookup[request, "Status", None] =!=
        "MultiquadraticNativeDeferredRequestV1", request,
      command = Join[{binary, inputFile, requestFile, outputFile},
        If[derivatives, {"--derivatives"}, {}],
        {"--threads", ToString[actualThreads]}];
      process = RunProcess[command];
      If[! AssociationQ[process] || process["ExitCode"] =!= 0,
        multiquadraticStripFailure["NativeDeferredEvaluatorProcessFailed",
          <|"ExitCode" -> If[AssociationQ[process],
              process["ExitCode"], None],
            "StandardError" -> If[AssociationQ[process],
              process["StandardError"], Missing["NoProcess"]]|>],
        multiquadraticStripNativeDeferredReadOutput[outputFile, provider,
          prime, Length[preflights], "Derivatives" -> derivatives]]],
    If[StringQ[directory] && DirectoryQ[directory],
      Quiet[DeleteDirectory[directory, DeleteContents -> True]]]];
  If[AssociationQ[result],
    Join[result, <|"Threads" -> actualThreads,
      "Seconds" -> N[AbsoluteTime[] - started]|>], result]
];
multiquadraticStripNativeDeferredEvaluateBatch[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredBatchArguments"];

(* A deferred forcing may remain in its source variables even when the
   integrability screen is run in a rational chart.  This wrapper records the
   small exact frame map and one image, in the target multiquadratic field, for
   every source radical.  The large preserved DAG remains untouched. *)
multiquadraticStripChartForcingProvider[sourceProvider_Association,
    targetRoots_List, chartData_Association,
    sourceRootImages_List] := Module[
  {sourceVariables, targetVariables, regulator, sourceRoots, substitution,
   substitutionValues, suppliedJacobian, jacobian, jacobianDet,
   pulledSourceSquares, rootImageChannels, rootIdentities, fingerprint,
   chartSeal},
  If[! multiquadraticStripProviderValidQ[sourceProvider] ||
      ! AssociationQ[Lookup[sourceProvider, "DeferredPreparation", None]] ||
      ! StringQ[Lookup[sourceProvider, "DeferredPreparationFile", None]] ||
      ! FileExistsQ[sourceProvider["DeferredPreparationFile"]] ||
      ! MatchQ[targetRoots, {___Association}] ||
      Length[targetRoots] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure[
      "InvalidChartForcingSourceProvider"]]];
  sourceVariables = Lookup[sourceProvider, "Variables", $Failed];
  targetVariables = Lookup[chartData, "Variables", $Failed];
  regulator = Lookup[sourceProvider, "Regulator", $Failed];
  sourceRoots = Lookup[sourceProvider, "Roots", $Failed];
  substitution = Lookup[chartData, "Subst", $Failed];
  suppliedJacobian = Lookup[chartData, "Jacobian", Automatic];
  If[! MatchQ[sourceVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[targetVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[sourceRoots, {___Association}] ||
      Length[sourceRoots] =!= Length[sourceRootImages] ||
      ! MatchQ[substitution, {_Rule, _Rule}] ||
      First /@ substitution =!= sourceVariables ||
      ! AllTrue[targetRoots,
        KeyExistsQ[#1, "Root"] && KeyExistsQ[#1, "RootSquare"] &],
    Return[multiquadraticStripFailure[
      "InvalidChartForcingFrame"]]];
  substitutionValues = Last /@ substitution;
  If[! FreeQ[{substitutionValues, sourceRootImages}, regulator],
    Return[multiquadraticStripFailure[
      "RegulatorDependentChartForcingFrame"]]];
  jacobian = Quiet[Check[Map[Together, Table[
      D[substitutionValues[[i]], targetVariables[[a]]],
      {i, 2}, {a, 2}], {2}], $Failed]];
  If[! MatchQ[jacobian, {{_, _}, {_, _}}] ||
      (suppliedJacobian =!= Automatic &&
        (! MatchQ[suppliedJacobian, {{_, _}, {_, _}}] ||
          ! AllTrue[Flatten[jacobian - suppliedJacobian],
            TrueQ[Quiet[Check[Together[#1], $Failed]] === 0] &])),
    Return[multiquadraticStripFailure[
      "ChartForcingJacobianMismatch"]]];
  jacobianDet = Quiet[Check[Together[Det[jacobian]], $Failed]];
  If[jacobianDet === $Failed || TrueQ[jacobianDet === 0],
    Return[multiquadraticStripFailure[
      "ChartForcingJacobianDegenerate"]]];
  pulledSourceSquares = Quiet[Check[
    Together /@ (Lookup[sourceRoots, "RootSquare", $Failed] /.
      substitution), $Failed]];
  If[pulledSourceSquares === $Failed ||
      ! FreeQ[pulledSourceSquares, $Failed],
    Return[multiquadraticStripFailure[
      "ChartForcingRootSquarePullBackFailed"]]];
  rootIdentities = MapThread[TrueQ[Quiet[Check[
        Together[#1^2 - #2], $Failed]] === 0] &,
    {sourceRootImages, pulledSourceSquares}];
  If[! AllTrue[rootIdentities, TrueQ],
    Return[multiquadraticStripFailure[
      "ChartForcingRootImageMismatch",
      <|"RootIdentities" -> rootIdentities|>]]];
  rootImageChannels = Map[
    multiquadraticFieldDecompose[#1, targetRoots] &,
    sourceRootImages];
  If[! ListQ[rootImageChannels] ||
      Length[rootImageChannels] =!= Length[sourceRoots] ||
      ! AllTrue[rootImageChannels,
        ListQ[#1] && Length[#1] === 2^Length[targetRoots] &] ||
      ! FreeQ[rootImageChannels, $Failed],
    Return[multiquadraticStripFailure[
      "ChartForcingRootImageFieldMismatch"]]];
  chartSeal = <|"Status" -> "OK", "Variables" -> targetVariables,
    "SourceVariables" -> sourceVariables, "Subst" -> substitution,
    "Jacobian" -> jacobian, "JacobianDet" -> jacobianDet|>;
  fingerprint = multiquadraticStripFingerprint[{
    "NativeDeferredChart", sourceProvider["ProviderFingerprint"],
    targetRoots, chartSeal, sourceRootImages, rootImageChannels}];
  <|"Status" -> "MultiquadraticChartForcingProviderV1",
    "Kind" -> "NativeDeferredChart", "SourceProvider" -> sourceProvider,
    "Variables" -> targetVariables, "Regulator" -> regulator,
    "Roots" -> targetRoots, "RootCount" -> Length[targetRoots],
    "GradeCount" -> 2^Length[targetRoots],
    "Dimensions" -> sourceProvider["Dimensions"],
    "ChartData" -> chartSeal, "SourceRootImages" -> sourceRootImages,
    "SourceRootImageChannels" -> rootImageChannels,
    "ProviderFingerprint" -> fingerprint|>
];
multiquadraticStripChartForcingProvider[___] :=
  multiquadraticStripFailure[
    "InvalidChartForcingProviderArguments"];

multiquadraticStripChartForcingProviderValidQ[provider_Association] := Module[
  {expected, sourceProvider, chartData, targetRoots, sourceRootImages, keys},
  If[Lookup[provider, "Status", None] =!=
        "MultiquadraticChartForcingProviderV1" ||
      Lookup[provider, "Kind", None] =!= "NativeDeferredChart",
    Return[False]];
  sourceProvider = Lookup[provider, "SourceProvider", $Failed];
  chartData = Lookup[provider, "ChartData", $Failed];
  targetRoots = Lookup[provider, "Roots", $Failed];
  sourceRootImages = Lookup[provider, "SourceRootImages", $Failed];
  If[! AssociationQ[sourceProvider] || ! AssociationQ[chartData] ||
      ! ListQ[targetRoots] || ! ListQ[sourceRootImages], Return[False]];
  expected = multiquadraticStripChartForcingProvider[sourceProvider,
    targetRoots, chartData, sourceRootImages];
  If[Lookup[expected, "Status", None] =!=
      "MultiquadraticChartForcingProviderV1", Return[False]];
  keys = {"Status", "Kind", "Variables", "Regulator", "Roots",
    "RootCount", "GradeCount", "Dimensions", "ChartData",
    "SourceRootImages", "SourceRootImageChannels",
    "ProviderFingerprint"};
  TrueQ[KeyTake[provider, keys] === KeyTake[expected, keys]]
];
multiquadraticStripChartForcingProviderValidQ[___] := False;

(* The screen validates the full wrapper once.  Point evaluation subsequently
   checks only this immutable small seal; the source evaluator retains its own
   authenticated preparation and request checks. *)
multiquadraticStripChartForcingProviderHotValidQ[provider_Association] :=
 Module[{sourceProvider, roots, sourceRoots, channels, chartData, fingerprint},
  sourceProvider = Lookup[provider, "SourceProvider", $Failed];
  roots = Lookup[provider, "Roots", $Failed];
  sourceRoots = If[AssociationQ[sourceProvider],
    Lookup[sourceProvider, "Roots", $Failed], $Failed];
  channels = Lookup[provider, "SourceRootImageChannels", $Failed];
  chartData = Lookup[provider, "ChartData", $Failed];
  If[Lookup[provider, "Status", None] =!=
        "MultiquadraticChartForcingProviderV1" ||
      Lookup[provider, "Kind", None] =!= "NativeDeferredChart" ||
      ! multiquadraticStripProviderHotValidQ[sourceProvider] ||
      ! AssociationQ[Lookup[sourceProvider, "DeferredPreparation", None]] ||
      ! StringQ[Lookup[sourceProvider, "DeferredPreparationFile", None]] ||
      ! FileExistsQ[sourceProvider["DeferredPreparationFile"]] ||
      ! ListQ[roots] || ! ListQ[sourceRoots] ||
      Lookup[provider, "RootCount", -1] =!= Length[roots] ||
      Lookup[provider, "GradeCount", -1] =!= 2^Length[roots] ||
      Lookup[provider, "Dimensions", None] =!=
        Lookup[sourceProvider, "Dimensions", Missing["NoDimensions"]] ||
      ! AssociationQ[chartData] ||
      Lookup[chartData, "Variables", None] =!=
        Lookup[provider, "Variables", Missing["NoVariables"]] ||
      ! MatchQ[channels, {___List}] ||
      Length[channels] =!= Length[sourceRoots] ||
      ! AllTrue[channels, Length[#1] === 2^Length[roots] &],
    Return[False]];
  fingerprint = multiquadraticStripFingerprint[{
    "NativeDeferredChart", sourceProvider["ProviderFingerprint"], roots,
    chartData, provider["SourceRootImages"], channels}];
  TrueQ[fingerprint === Lookup[provider, "ProviderFingerprint", None]]
];
multiquadraticStripChartForcingProviderHotValidQ[___] := False;

multiquadraticStripChartForcingPreflight[provider_Association, epsilonValue_,
    prime_Integer, targetPoint : {_Integer, _Integer},
    targetRootValues_List] := Module[
  {startTime = AbsoluteTime[], sourceProvider, targetVariables, regulator,
   targetRoots, sourceRoots, chartData, epsilonMod, scalarRules,
   evaluateScalar, sourcePoint, jacobian, jacobianDet, targetDeltaValues,
   sourceRootImageChannels, sourceRootImageChannelValues,
   targetSheetMonomials, sourceRootSheetValues, sourcePreflight,
   sourceRootSquares, failure},
  failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
    Join[<|"ProviderFingerprint" -> Lookup[provider,
        "ProviderFingerprint", Missing["NoProviderFingerprint"]],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "Point" -> Mod[targetPoint, prime],
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>, data]];
  If[! multiquadraticStripChartForcingProviderHotValidQ[provider] ||
      ! PrimeQ[prime] || ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[failure["InvalidChartForcingPreflightInput"]]];
  sourceProvider = provider["SourceProvider"];
  targetVariables = provider["Variables"];
  regulator = provider["Regulator"];
  targetRoots = provider["Roots"];
  sourceRoots = sourceProvider["Roots"];
  chartData = provider["ChartData"];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0 ||
      Length[targetRootValues] =!= Length[targetRoots] ||
      ! VectorQ[targetRootValues, IntegerQ] ||
      MemberQ[Mod[targetRootValues, prime], 0],
    Return[failure["InvalidChartForcingTargetImage"]]];
  scalarRules = Join[
    AssociationThread[targetVariables, Mod[targetPoint, prime]],
    <|regulator -> epsilonMod|>];
  evaluateScalar[expression_] := Module[{evaluated},
    evaluated = multiquadraticStripModularGradeEvaluate[expression,
      scalarRules, {}, {}, prime];
    If[Lookup[evaluated, "Status", None] =!= "OK" ||
        Length[Lookup[evaluated, "Channels", {}]] =!= 1,
      $Failed, First[evaluated["Channels"]]]];
  sourcePoint = evaluateScalar /@ (Last /@ chartData["Subst"]);
  jacobian = Map[evaluateScalar, chartData["Jacobian"], {2}];
  jacobianDet = evaluateScalar[chartData["JacobianDet"]];
  targetDeltaValues = evaluateScalar /@ Lookup[targetRoots,
    "RootSquare", {}];
  If[! VectorQ[sourcePoint, IntegerQ] ||
      ! MatrixQ[jacobian, IntegerQ] || Dimensions[jacobian] =!= {2, 2} ||
      ! IntegerQ[jacobianDet] || jacobianDet === 0 ||
      Mod[Det[jacobian] - jacobianDet, prime] =!= 0 ||
      ! VectorQ[targetDeltaValues, IntegerQ] ||
      Length[targetDeltaValues] =!= Length[targetRoots] ||
      ! AllTrue[Range[Length[targetRoots]],
        Mod[targetRootValues[[#1]]^2 - targetDeltaValues[[#1]], prime] ===
          0 &],
    Return[failure["ChartForcingFrameImageSingular"]]];
  sourceRootImageChannels = provider["SourceRootImageChannels"];
  sourceRootImageChannelValues =
    Map[evaluateScalar, sourceRootImageChannels, {2}];
  If[! MatrixQ[sourceRootImageChannelValues, IntegerQ] ||
      Dimensions[sourceRootImageChannelValues] =!=
        {Length[sourceRoots], 2^Length[targetRoots]},
    Return[failure["ChartForcingRootImageEvaluationFailed"]]];
  targetSheetMonomials = Table[
    Table[Product[
      If[BitGet[grade - 1, a - 1] === 1,
        Mod[If[BitGet[mask, a - 1] === 1, -1, 1]
          targetRootValues[[a]], prime], 1],
      {a, Length[targetRoots]}],
      {grade, 1, 2^Length[targetRoots]}],
    {mask, 0, 2^Length[targetRoots] - 1}];
  sourceRootSheetValues = Mod[
    targetSheetMonomials . Transpose[sourceRootImageChannelValues], prime];
  If[! MatrixQ[sourceRootSheetValues, IntegerQ] ||
      MemberQ[Flatten[sourceRootSheetValues], 0],
    Return[failure["ChartForcingSourceRootImageDegenerate"]]];
  sourcePreflight = multiquadraticStripProviderPreflight[sourceProvider,
    epsilonValue, prime, sourcePoint];
  If[Lookup[sourcePreflight, "Status", None] =!=
      "MultiquadraticProviderPreflightV1",
    Return[failure["ChartForcingSourcePreflightFailed",
      <|"Detail" -> sourcePreflight|>]]];
  sourceRootSquares = Lookup[sourcePreflight, "RootSquares", {}];
  If[Length[sourceRootSquares] =!= Length[sourceRoots] ||
      ! AllTrue[Range[Length[sourceRoots]], Mod[
          sourceRootSheetValues[[1, #1]]^2 - sourceRootSquares[[#1]],
          prime] === 0 &],
    Return[failure["ChartForcingSourceRootAuthenticationFailed"]]];
  sourcePreflight = Join[sourcePreflight, <|
    "RootValues" -> First[sourceRootSheetValues], "SplitPointQ" -> True|>];
  <|"Status" -> "MultiquadraticChartForcingPreflightV1",
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "Prime" -> prime, "RegulatorValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "Point" -> Mod[targetPoint, prime],
    "TargetRootValues" -> Mod[targetRootValues, prime],
    "SourceRootSheetValues" -> sourceRootSheetValues,
    "SourcePreflight" -> sourcePreflight,
    "Jacobian" -> Mod[jacobian, prime],
    "JacobianDet" -> Mod[jacobianDet, prime],
    "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripChartForcingPreflight[___] :=
  multiquadraticStripFailure[
    "InvalidChartForcingPreflightArguments"];

(* Fold a source-grade tensor onto the target grade basis by evaluating the
   source basis on each target sheet and applying the target Walsh projector.
   This handles rationalized roots, retained roots and products of retained
   roots uniformly; no hard-coded embedding of grade bits is needed. *)
multiquadraticStripChartForcingFoldTensor[tensor_,
    sourceRootSheetValues_List, targetRootValues_List,
    prime_Integer] := Module[
  {targetGradeCount, sourceRank, sourceGradeCount, dimensions, mapLevel,
   sourceSheetMonomials, fold, result},
  targetGradeCount = 2^Length[targetRootValues];
  If[Length[sourceRootSheetValues] =!= targetGradeCount ||
      ! MatrixQ[sourceRootSheetValues, IntegerQ] ||
      ! PrimeQ[prime] || MemberQ[Mod[targetRootValues, prime], 0],
    Return[$Failed]];
  sourceRank = If[sourceRootSheetValues === {}, 0,
    Length[First[sourceRootSheetValues]]];
  sourceGradeCount = 2^sourceRank;
  dimensions = Dimensions[tensor];
  If[dimensions === {} || Last[dimensions] =!= sourceGradeCount,
    Return[$Failed]];
  sourceSheetMonomials = Table[
    Table[Product[If[BitGet[grade - 1, a - 1] === 1,
        sourceRootSheetValues[[sheet, a]], 1], {a, sourceRank}],
      {grade, 1, sourceGradeCount}],
    {sheet, targetGradeCount}];
  fold[channelVector_List] := multiquadraticProjectConjugates[
    Mod[sourceSheetMonomials . channelVector, prime],
    Mod[targetRootValues, prime], prime];
  mapLevel = Length[dimensions] - 1;
  result = Map[fold, tensor, {mapLevel}];
  If[FreeQ[result, $Failed] &&
      Dimensions[result] === ReplacePart[dimensions, -1 -> targetGradeCount],
    Mod[result, prime], $Failed]
];
multiquadraticStripChartForcingFoldTensor[___] := $Failed;

Options[multiquadraticStripNativeDeferredChartEvaluateBatch] = {
  "Threads" -> Automatic
};
multiquadraticStripNativeDeferredChartEvaluateBatch[
    provider_Association, preflights_List,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], sourceProvider, prime, sourcePreflights,
   threads, native, bbarBatch = {}, curlBatch = {}, base, sourceBBar,
   sourceDerivatives, foldedBBar, sourceCurl, foldedCurl, jacobian,
   jacobianDet, chartBBar},
  If[! multiquadraticStripChartForcingProviderHotValidQ[provider] ||
      preflights === {} || ! AllTrue[preflights,
        Lookup[#1, "Status", None] ===
            "MultiquadraticChartForcingPreflightV1" &&
          Lookup[#1, "ProviderFingerprint", None] ===
            provider["ProviderFingerprint"] &],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredChartBatchInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] || ! AllTrue[preflights,
      Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure[
      "MixedNativeDeferredChartBatchPrimes"]]];
  threads = OptionValue["Threads"];
  sourceProvider = provider["SourceProvider"];
  sourcePreflights = Lookup[preflights, "SourcePreflight", {}];
  native = multiquadraticStripNativeDeferredEvaluateBatch[sourceProvider,
    sourcePreflights, "Derivatives" -> True, "Threads" -> threads];
  If[Lookup[native, "Status", None] =!=
      "MultiquadraticNativeDeferredDerivativeBatchV1",
    Return[multiquadraticStripFailure[
      "NativeDeferredChartSourceEvaluationFailed",
      <|"Detail" -> native|>]]];
  Do[
    sourceBBar = native["BBarBatch"][[base]];
    sourceDerivatives = native["BBarDerivativeBatch"][[All, base]];
    foldedBBar = multiquadraticStripChartForcingFoldTensor[sourceBBar,
      preflights[[base, "SourceRootSheetValues"]],
      preflights[[base, "TargetRootValues"]], prime];
    sourceCurl = Mod[sourceDerivatives[[2, 1]] -
      sourceDerivatives[[1, 2]], prime];
    foldedCurl = multiquadraticStripChartForcingFoldTensor[sourceCurl,
      preflights[[base, "SourceRootSheetValues"]],
      preflights[[base, "TargetRootValues"]], prime];
    If[foldedBBar === $Failed || foldedCurl === $Failed,
      Return[multiquadraticStripFailure[
        "NativeDeferredChartGradeFoldFailed",
        <|"BaseIndex" -> base|>]]];
    jacobian = preflights[[base, "Jacobian"]];
    jacobianDet = preflights[[base, "JacobianDet"]];
    chartBBar = {
      Mod[jacobian[[1, 1]] foldedBBar[[1]] +
        jacobian[[2, 1]] foldedBBar[[2]], prime],
      Mod[jacobian[[1, 2]] foldedBBar[[1]] +
        jacobian[[2, 2]] foldedBBar[[2]], prime]};
    AppendTo[bbarBatch, chartBBar];
    AppendTo[curlBatch, Mod[jacobianDet foldedCurl, prime]],
    {base, Length[preflights]}];
  <|"Status" -> "MultiquadraticNativeDeferredChartBatchV1",
    "Prime" -> prime, "RootCount" -> provider["RootCount"],
    "GradeCount" -> provider["GradeCount"],
    "BaseCount" -> Length[preflights],
    "Dimensions" -> Prepend[provider["Dimensions"], 2],
    "BBarBatch" -> bbarBatch, "BBarCurlBatch" -> curlBatch,
    "SourceRootCount" -> sourceProvider["RootCount"],
    "SourceNative" -> KeyDrop[native,
      {"BBarBatch", "BBarDerivativeBatch"}],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripNativeDeferredChartEvaluateBatch[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredChartBatchArguments"];

(* The split-point census is the same finite-field problem on a much smaller
   root-free list: root squares, Q, d log Q and d log Delta.  Evaluate the
   complete candidate pool in one native call, then perform only the Legendre
   tests and square roots in Wolfram.  This replaces hundreds of repeated
   symbolic substitutions without changing the accepted point sequence. *)
multiquadraticStripNativePreflightBatch[provider_Association,
    epsilonValue_, prime_Integer, points_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], rootCount, variables, epsilon, epsilonMod,
   expressions, compileSeconds, compiled, nativePlan, dummy, native,
   values, decodeSeconds, records, decode, perPointSeconds = 0.},
  rootCount = Lookup[provider, "RootCount", $Failed];
  variables = Lookup[provider, "Variables", $Failed];
  epsilon = Lookup[provider, "Regulator", $Failed];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      ! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      epsilonMod === $Failed || epsilonMod === 0 || points === {} ||
      ! MatchQ[points, {{_Integer, _Integer} ..}] ||
      ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure[
      "InvalidNativePreflightBatchInput"]]];
  expressions = Join[Lookup[provider["Roots"], "RootSquare", {}],
    {provider["GaugeDenominator"]}, provider["GaugeLogDerivatives"],
    Flatten[provider["RootLogDerivatives"]]];
  {compileSeconds, compiled} = AbsoluteTiming[
    multiquadraticStripScreenCompileScalar[#1, {}, {},
        Join[variables, {epsilon}], prime] & /@ expressions];
  If[! AllTrue[compiled, AssociationQ],
    Return[multiquadraticStripFailure[
      "NativePreflightCompileFailed"]]];
  nativePlan = <|"Prime" -> prime, "RootCount" -> rootCount,
    "Leaves" -> Map[<|"ActiveRoots" -> {}, "Compiled" -> #1|> &,
      compiled]|>;
  dummy = Map[<|"Status" -> "MultiquadraticProviderPreflightV1",
      "Prime" -> prime, "Point" -> Mod[#1, prime],
      "EpsilonMod" -> epsilonMod,
      "RootValues" -> ConstantArray[1, rootCount]|> &, points];
  native = multiquadraticStripNativeSparseEvaluateBatch[nativePlan, dummy,
    threads];
  If[Lookup[native, "Status", None] =!=
      "MultiquadraticNativeSparseBatchV1",
    Return[multiquadraticStripFailure[
      "NativePreflightEvaluationFailed",
      <|"Detail" -> native, "CompileSeconds" -> compileSeconds,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]]];
  values = native["Channels"][[All, All, 1]];
  decode[index_] := Module[{point = Mod[points[[index]], prime], scalars,
      deltas, denominator, gaugeLog, rootLog, splitQ, rootValues,
      failure},
    failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
      Join[<|"ProviderFingerprint" -> provider["ProviderFingerprint"],
        "Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "Point" -> point, "PreflightRejected" -> True,
        "LargeEntryEvaluationCount" -> 0,
        "PreflightSeconds" -> perPointSeconds|>, data]];
    If[! VectorQ[native["LeafStatuses"][[index]], #1 === 0 &],
      Return[failure["RationalChannelPole"]]];
    scalars = values[[index]];
    deltas = Take[scalars, rootCount];
    denominator = scalars[[rootCount + 1]];
    gaugeLog = scalars[[rootCount + 2 ;; rootCount + 3]];
    rootLog = If[rootCount === 0, {},
      ArrayReshape[Drop[scalars, rootCount + 3], {rootCount, 2}]];
    If[MemberQ[deltas, 0],
      Return[failure["DegenerateRootImage",
        <|"DeltaValues" -> deltas|>]]];
    If[denominator === 0,
      Return[failure["ZeroGaugeDenominator"]]];
    splitQ = AllTrue[deltas, JacobiSymbol[#1, prime] === 1 &];
    If[! splitQ,
      Return[failure["PointNotSplitOverPrime",
        <|"DeltaValues" -> deltas|>]]];
    rootValues = multiquadraticSquareRoots[deltas, prime];
    If[rootValues === $Failed,
      Return[failure["ModularSquareRootFailed"]]];
    <|"Status" -> "MultiquadraticProviderPreflightV1",
      "Provider" -> "SplitBranch",
      "ProviderFingerprint" -> provider["ProviderFingerprint"],
      "CoefficientABIFingerprint" ->
        provider["CoefficientABIFingerprint"],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> epsilonMod, "Point" -> point,
      "ScalarRules" -> Join[AssociationThread[variables, point],
        <|epsilon -> epsilonMod|>],
      "RootSquares" -> deltas, "RootValues" -> rootValues,
      "SplitPointQ" -> True, "GaugeDenominator" -> denominator,
      "GaugeLogDerivatives" -> gaugeLog,
      "RootLogDerivatives" -> rootLog,
      "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> perPointSeconds|>];
  {decodeSeconds, records} = AbsoluteTiming[decode /@ Range[Length[points]]];
  <|"Status" -> "MultiquadraticNativePreflightBatchV1",
    "Records" -> records, "PointCount" -> Length[points],
    "ExpressionCount" -> Length[expressions],
    "CompileSeconds" -> compileSeconds,
    "NativeBatchSeconds" -> native["Seconds"],
    "DecodeSeconds" -> decodeSeconds,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripNativePreflightBatch[___] :=
  multiquadraticStripFailure["InvalidNativePreflightBatchArguments"];

multiquadraticStripNativeRowBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_row_assemble"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripNativeRowAssembleBatch[assembly_Association,
    coefficients_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], binary, prime, rootCount, gradeCount,
   dimensions, upper, lower, support, oneFormCount, pointCount, rowCount,
   unknownCount, directory = None, inputFile, outputFile, stream = None,
   payload, process, magic, header, rows, right, writeSeconds = 0.,
   adapterSeconds = 0., readSeconds = 0., result, tag},
  tag = Unique["MultiquadraticNativeRowBatchFailure"];
  binary = multiquadraticStripNativeRowBinary[];
  prime = If[coefficients === {}, $Failed,
    Lookup[First[coefficients], "Prime", $Failed]];
  rootCount = Lookup[assembly, "RootCount", $Failed];
  gradeCount = If[IntegerQ[rootCount], 2^rootCount, 0];
  dimensions = Lookup[assembly, "Dimensions", $Failed];
  support = Lookup[assembly, "GaugeSupport", $Failed];
  oneFormCount = Length[Lookup[assembly, "OneForms", {}]];
  pointCount = Length[coefficients];
  If[! StringQ[binary] || ! Between[threads, {1, 8}] ||
      ! PrimeQ[prime] || ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      ! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! MatchQ[support, {{_Integer?NonNegative, _Integer?NonNegative} ..}] ||
      pointCount < 1 || ! AllTrue[coefficients,
        Lookup[#1, "Status", None] ===
            "MultiquadraticPointCoefficientsV1" &&
          Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure["InvalidNativeRowBatchInput"]]];
  {upper, lower} = dimensions;
  rowCount = gradeCount 2 upper lower;
  unknownCount = upper lower gradeCount Length[support] +
    oneFormCount upper lower;
  result = Catch[
    directory = CreateDirectory[];
    inputFile = FileNameJoin[{directory, "rows-input.bin"}];
    outputFile = FileNameJoin[{directory, "rows-output.bin"}];
    payload = Flatten[{
          Lookup[#1, "Point", {}], Lookup[#1,
            {"EpsilonMod", "GaugeDenominator"}, {$Failed, $Failed}],
          Lookup[#1, "RootSquares", {}],
          Lookup[#1, "GaugeLogDerivatives", {}],
          Lookup[#1, "RootLogDerivatives", {}], Lookup[#1, "E", {}],
          Lookup[#1, "C", {}], Lookup[#1, "BBar", {}],
          Lookup[#1, "OneForms", {}]}] & /@ coefficients;
    {writeSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenWrite[inputFile, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["MQRA1V1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {prime, rootCount, upper, lower, Length[support],
          oneFormCount, pointCount}, "UnsignedInteger64",
        ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[support], "UnsignedInteger64",
        ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[payload], "UnsignedInteger64",
        ByteOrdering -> -1];
      Close[stream]; stream = None; True, False]]];
    If[! TrueQ[result],
      If[Head[stream] === OutputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeRowInputWriteFailed"], tag]];
    {adapterSeconds, process} = AbsoluteTiming[RunProcess[
      taskBrokerNativeCommand[
        {binary, inputFile, outputFile, ToString[threads]}, threads]]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0,
      Throw[multiquadraticStripFailure[
        "NativeRowAdapterFailed"], tag]];
    {readSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenRead[outputFile, BinaryFormat -> True];
      magic = BinaryReadList[stream, "UnsignedInteger8", 8];
      header = BinaryReadList[stream, "UnsignedInteger64", 4,
        ByteOrdering -> -1];
      rows = BinaryReadList[stream, "UnsignedInteger64",
        pointCount rowCount unknownCount, ByteOrdering -> -1];
      right = BinaryReadList[stream, "UnsignedInteger64",
        pointCount rowCount, ByteOrdering -> -1];
      Close[stream]; stream = None;
      If[magic =!= ToCharacterCode["MQRA1X1\000"] ||
          header =!= {prime, pointCount, rowCount, unknownCount} ||
          Length[rows] =!= pointCount rowCount unknownCount ||
          Length[right] =!= pointCount rowCount, $Failed,
        <|"Status" -> "MultiquadraticNativeRowBatchV1",
          "Rows" -> ArrayReshape[rows,
            {pointCount, rowCount, unknownCount}],
          "RightHandSides" -> ArrayReshape[right,
            {pointCount, rowCount}], "Threads" -> threads|>], $Failed]]];
    If[! AssociationQ[result],
      If[Head[stream] === InputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeRowResponseInvalid"], tag]];
    Join[result, <|"InputWriteSeconds" -> writeSeconds,
      "AdapterSeconds" -> adapterSeconds,
      "ResponseReadSeconds" -> readSeconds|>],
    tag, #1 &];
  If[StringQ[directory] && DirectoryQ[directory],
    Quiet[DeleteDirectory[directory, DeleteContents -> True]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - startTime]], result]
];
multiquadraticStripNativeRowAssembleBatch[___] :=
  multiquadraticStripFailure["InvalidNativeRowBatchArguments"];

multiquadraticStripPointResult[assembly_Association,
    coefficients_Association, rows_List, right_List, assemblySeconds_] :=
  <|"Status" -> "AssembledMultiquadraticPointV1",
    "AssemblyFingerprint" -> Lookup[assembly, "AssemblyFingerprint",
      Missing["NotCompiled"]],
    "LayoutFingerprint" -> Lookup[assembly, "LayoutFingerprint",
      Missing["LegacyCompiledOracle"]],
    "CoefficientABIFingerprint" -> Lookup[coefficients,
      "CoefficientABIFingerprint", Missing["LegacyCompiledOracle"]],
    "ProviderFingerprint" -> Lookup[coefficients, "ProviderFingerprint",
      Missing["LegacyCompiledOracle"]],
    "Prime" -> coefficients["Prime"],
    "Provider" -> Lookup[coefficients, "Provider", "CompiledChannel"],
    "EpsilonValue" -> Lookup[coefficients, "RegulatorValue",
      Missing["NoRegulatorValue"]],
    "EpsilonMod" -> coefficients["EpsilonMod"],
    "Point" -> coefficients["Point"],
    "DeltaValues" -> coefficients["RootSquares"],
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows],
    "Dimensions" -> assembly["Dimensions"],
    "RootCount" -> assembly["RootCount"],
    "GradeCount" -> assembly["GradeCount"],
    "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
    "UnknownCount" -> assembly["UnknownCount"],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "AssemblySeconds" -> assemblySeconds|>;
multiquadraticStripPointResult[___] :=
  multiquadraticStripFailure["InvalidPointResultArguments"];

(* Cheap authenticated point preflight.  It evaluates only the root
   squares, the gauge denominator and their logarithmic derivatives.  A
   split provider rejects a nonsplit point here, before one large matrix
   entry is touched.  The returned primitives are reused by the full
   coefficient evaluation. *)
multiquadraticStripProviderPreflight[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer}] := Module[
  {startTime = AbsoluteTime[], kind, roots, rank, variables, epsilon,
   epsilonMod, scalarRules, evaluateScalar, deltaValues, denominatorValue,
   gaugeLogValues, rootLogValues, splitQ, rootValues, assembly,
   epsilonForms, forms, imagePolynomials, requiredXExponents,
   requiredYExponents, x, y, xPowers, yPowers, primitiveForms,
   primitiveEvaluated, failure},
  failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
    Join[<|"ProviderFingerprint" -> Lookup[provider,
        "ProviderFingerprint", Missing["NoProviderFingerprint"]],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "Point" -> Mod[point, prime], "PreflightRejected" -> True,
      "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>, data]];
  If[! multiquadraticStripProviderEvaluationValidQ[provider],
    Return[failure["InvalidCoefficientProvider"]]];
  If[! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[failure["InvalidPrime"]]];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[failure["BadPrimeForRegulatorValue"]]];
  If[MemberQ[Mod[point, prime], 0],
    Return[failure["ZeroPointCoordinate"]]];
  kind = provider["Kind"];
  If[kind === "CompiledChannel",
    assembly = provider["Assembly"];
    epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime,
      epsilonValue];
    If[Lookup[epsilonForms, "Status", None] =!=
          "MultiquadraticStripEpsilonFormsV1" ||
        ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms,
          prime], Return[failure["RegulatorFormsInvalid"]]];
    forms = epsilonForms["Forms"];
    imagePolynomials = Cases[forms, association_Association /;
      Lookup[association, "Type", None] ===
        "MultiquadraticPolynomialImageV1" :> association, {0, Infinity}];
    requiredXExponents = Union[assembly["GaugeSupport"][[All, 1]],
      Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
    requiredYExponents = Union[assembly["GaugeSupport"][[All, 2]],
      Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
    {x, y} = Mod[point, prime];
    xPowers = AssociationThread[requiredXExponents,
      PowerMod[x, #1, prime] & /@ requiredXExponents];
    yPowers = AssociationThread[requiredYExponents,
      PowerMod[y, #1, prime] & /@ requiredYExponents];
    primitiveForms = KeyTake[forms, {"RootSquares", "GaugeDenominator"}];
    primitiveEvaluated = Catch[multiquadraticStripEvaluateForms[
      primitiveForms, xPowers, yPowers, prime],
      "MultiquadraticStripBadPoint"];
    If[! AssociationQ[primitiveEvaluated],
      Return[failure["RationalChannelPole"]]];
    deltaValues = primitiveEvaluated["RootSquares"];
    denominatorValue = primitiveEvaluated["GaugeDenominator"];
    If[! VectorQ[deltaValues, IntegerQ] ||
        Length[deltaValues] =!= assembly["RootCount"] ||
        MemberQ[deltaValues, 0],
      Return[failure["DegenerateRootImage",
        <|"DeltaValues" -> deltaValues|>]]];
    If[! IntegerQ[denominatorValue] || denominatorValue === 0,
      Return[failure["ZeroGaugeDenominator"]]];
    splitQ = AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &];
    Return[<|"Status" -> "MultiquadraticProviderPreflightV1",
      "Provider" -> kind,
      "ProviderFingerprint" -> provider["ProviderFingerprint"],
      "CoefficientABIFingerprint" ->
        provider["CoefficientABIFingerprint"],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> epsilonMod, "Point" -> {x, y},
      "RootSquares" -> deltaValues, "RootValues" -> If[splitQ,
        multiquadraticSquareRoots[deltaValues, prime],
        ConstantArray[0, Length[deltaValues]]],
      "SplitPointQ" -> splitQ,
      "GaugeDenominator" -> denominatorValue,
      "EpsilonForms" -> epsilonForms, "XPowers" -> xPowers,
      "YPowers" -> yPowers, "PrimitiveValues" -> primitiveEvaluated,
      "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>]];
  roots = provider["Roots"];
  rank = provider["RootCount"];
  variables = provider["Variables"];
  epsilon = provider["Regulator"];
  scalarRules = Join[AssociationThread[variables, Mod[point, prime]],
    <|epsilon -> epsilonMod|>];
  evaluateScalar[expression_] := Module[{evaluated},
    evaluated = multiquadraticStripModularGradeEvaluate[expression,
      scalarRules, {}, {}, prime];
    If[Lookup[evaluated, "Status", None] =!= "OK", $Failed,
      First[evaluated["Channels"]]]];
  deltaValues = Table[evaluateScalar[Lookup[roots[[k]], "RootSquare", 0]],
    {k, rank}];
  If[MemberQ[deltaValues, $Failed],
    Return[failure["RootSquareNotEvaluable",
      <|"RootIndices" -> Flatten[Position[deltaValues, $Failed]]|>]]];
  If[MemberQ[deltaValues, 0],
    Return[failure["DegenerateRootImage",
      <|"DeltaValues" -> deltaValues|>]]];
  denominatorValue = evaluateScalar[provider["GaugeDenominator"]];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Return[failure["ZeroGaugeDenominator"]]];
  gaugeLogValues = evaluateScalar /@ provider["GaugeLogDerivatives"];
  rootLogValues = Map[evaluateScalar, provider["RootLogDerivatives"], {2}];
  If[MemberQ[Flatten[{gaugeLogValues, rootLogValues}], $Failed],
    Return[failure["RationalChannelPole"]]];
  splitQ = AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &];
  If[kind === "SplitBranch" && ! splitQ,
    Return[failure["PointNotSplitOverPrime",
      <|"DeltaValues" -> deltaValues|>]]];
  rootValues = If[splitQ, multiquadraticSquareRoots[deltaValues, prime],
    ConstantArray[0, rank]];
  If[splitQ && rootValues === $Failed,
    Return[failure["ModularSquareRootFailed"]]];
  <|"Status" -> "MultiquadraticProviderPreflightV1",
    "Provider" -> kind,
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "CoefficientABIFingerprint" -> provider["CoefficientABIFingerprint"],
    "Prime" -> prime, "RegulatorValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "Point" -> Mod[point, prime],
    "ScalarRules" -> scalarRules, "RootSquares" -> deltaValues,
    "RootValues" -> rootValues, "SplitPointQ" -> splitQ,
    "GaugeDenominator" -> denominatorValue,
    "GaugeLogDerivatives" -> gaugeLogValues,
    "RootLogDerivatives" -> rootLogValues,
    "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
    "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripProviderPreflight[___] :=
  multiquadraticStripFailure["InvalidProviderPreflightArguments"];

(* The compiled oracle now produces the same coefficient record as the
   direct providers and reaches the same row assembler. *)
multiquadraticStripCompiledProviderChannels[provider_Association,
    preflight_Association] := Module[
  {startTime = AbsoluteTime[], assembly, prime, forms, evaluated,
   remaining, coefficients, entryCount},
  If[! multiquadraticStripProviderEvaluationValidQ[provider] ||
      provider["Kind"] =!= "CompiledChannel" ||
      Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      Lookup[preflight, "ProviderFingerprint", None] =!=
        provider["ProviderFingerprint"],
    Return[multiquadraticStripFailure["InvalidCompiledProviderPreflight"]]];
  assembly = provider["Assembly"];
  prime = preflight["Prime"];
  forms = preflight["EpsilonForms"]["Forms"];
  remaining = KeyDrop[forms, {"RootSquares", "GaugeDenominator"}];
  evaluated = Catch[multiquadraticStripEvaluateForms[remaining,
    preflight["XPowers"], preflight["YPowers"], prime],
    "MultiquadraticStripBadPoint"];
  If[! AssociationQ[evaluated],
    Return[multiquadraticStripFailure["RationalChannelPole",
      <|"Prime" -> prime, "Point" -> preflight["Point"],
        "ProviderFingerprint" -> provider["ProviderFingerprint"],
        "LargeEntryEvaluationCount" -> 0|>]]];
  evaluated = Join[preflight["PrimitiveValues"], evaluated];
  entryCount = Total[Times @@ Dimensions[#1] & /@
    Lookup[evaluated, {"E", "C", "BBar", "OneForms"}, {}]];
  coefficients = <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "CompiledChannel", "Prime" -> prime,
    "Point" -> preflight["Point"],
    "RegulatorValue" -> preflight["RegulatorValue"],
    "EpsilonMod" -> preflight["EpsilonMod"],
    "RootSquares" -> preflight["RootSquares"],
    "RootValues" -> preflight["RootValues"],
    "SplitPointQ" -> preflight["SplitPointQ"],
    "GaugeDenominator" -> preflight["GaugeDenominator"],
    "GaugeLogDerivatives" -> evaluated["GaugeLogDerivatives"],
    "RootLogDerivatives" -> evaluated["RootLogDerivatives"],
    "E" -> evaluated["E"], "C" -> evaluated["C"],
    "BBar" -> evaluated["BBar"], "OneForms" -> evaluated["OneForms"],
    "CoefficientABIFingerprint" -> provider["CoefficientABIFingerprint"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "PreflightSeconds" -> preflight["PreflightSeconds"],
    "LargeEntryEvaluationCount" -> entryCount,
    "EntryEvaluationCount" -> entryCount,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>;
  coefficients
];
multiquadraticStripCompiledProviderChannels[___] :=
  multiquadraticStripFailure["InvalidCompiledProviderChannelArguments"];

(* Evaluate the deferred forcing DAG at one authenticated point.  SplitBranch
   evaluates each operand and coefficient only on the sign orbit of its local
   active subfield, lifts those channels to the global ABI, and assembles jobs
   with quotient-algebra multiplication.  Thus a root-free operand costs one
   scalar image and a rank-one operand costs two even in a rank-three frame.
   QuotientGrade retains its existing one-grade-evaluation-per-entry route.
   No dense symbolic BBar and no Together over a target entry is formed. *)
multiquadraticStripBundleProviderChannels[provider_Association,
    preflight_Association, splitPlan_: Automatic,
    plannedLeafChannels_: Automatic] := Catch[Module[
  {startTime = AbsoluteTime[], bundle = provider["DeferredBundle"],
   expressions, operandActiveRoots, coefficientExpressions,
   coefficientActiveRoots, jobs, dimensions, roots = provider["Roots"],
   rank, gradeCount, prime, scalarRules, deltaValues, rootValues, kind, tag,
   evaluateSplit, operandValues, targetChannels, radicalRules,
   evaluateGrade, coefficientValues, multiply, zero, termProducts,
   evaluationCount = 0, coefficientCount = 0,
   operandScalarCount = 0, coefficientScalarCount = 0,
   globalSheetScalarCount = 0, splitCompileAttempts = 0,
   splitCompileCacheHits = 0, splitCompileCacheMisses = 0,
   splitSparseSuccesses = 0, splitSubstitutionFallbacks = 0,
   splitCompileSeconds = 0., splitEvaluationSeconds = 0.,
   splitFallbackSeconds = 0., plannedQ, occurrenceMaps,
   operandIndices, coefficientIndices, gatherSeconds = 0.,
   compositionSeconds = 0.},
  tag = Unique["MultiquadraticBundleProviderFailure"];
  If[! multiquadraticStripProviderEvaluationValidQ[provider] ||
      ! AssociationQ[bundle] ||
      bundle["BundleFingerprint"] =!=
        provider["DeferredBundleFingerprint"],
    Throw[multiquadraticStripFailure["InvalidDeferredBundle"], tag]];
  expressions = provider["BundleOperandExpressions"];
  operandActiveRoots = provider["BundleOperandActiveRoots"];
  coefficientExpressions = provider["BundleCoefficientExpressions"];
  coefficientActiveRoots = provider["BundleCoefficientActiveRoots"];
  jobs = bundle["Jobs"];
  dimensions = bundle["Dimensions"];
  rank = provider["RootCount"]; gradeCount = provider["GradeCount"];
  prime = preflight["Prime"]; scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["RootSquares"];
  rootValues = preflight["RootValues"];
  kind = provider["Kind"];
  plannedQ = splitPlan =!= Automatic;
  If[plannedQ,
    If[kind =!= "SplitBranch" ||
        ! multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[
          splitPlan, provider, prime] ||
        ! ListQ[plannedLeafChannels] ||
        Length[plannedLeafChannels] =!= Length[splitPlan["Leaves"]] ||
        ! AllTrue[plannedLeafChannels,
          VectorQ[#1, IntegerQ] && Length[#1] === gradeCount &],
      Throw[multiquadraticStripFailure[
        "InvalidBundleSplitSparseEvaluationPlan"], tag]];
    occurrenceMaps = splitPlan["OccurrenceMaps"];
    operandIndices = occurrenceMaps["BundleOperands"];
    coefficientIndices = occurrenceMaps["BundleCoefficients"];
    {gatherSeconds, {operandValues, coefficientValues}} = AbsoluteTiming[{
      Map[plannedLeafChannels[[#1]] &, operandIndices],
      Map[plannedLeafChannels[[#1]] &, coefficientIndices, {2}]}];
    operandScalarCount = Total[2^Length[
        splitPlan["Leaves"][[#1, "ActiveRoots"]]] & /@ operandIndices];
    coefficientScalarCount = Total[2^Length[
        splitPlan["Leaves"][[#1, "ActiveRoots"]]] & /@
      Flatten[coefficientIndices]];
    evaluationCount = Length[operandIndices];
    coefficientCount = Length[Flatten[coefficientIndices]];
    globalSheetScalarCount = gradeCount (evaluationCount + coefficientCount);
    zero = ConstantArray[0, gradeCount];
    multiply[left_, right_] := Module[{product =
        multiquadraticMultiply[left, right, deltaValues, prime]},
      If[! ListQ[product],
        Throw[multiquadraticStripFailure[
          "BundleQuotientProductFailed"], tag]];
      Mod[product, prime]];
    {compositionSeconds, targetChannels} = AbsoluteTiming[Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}]];
    Return[<|"Status" -> "MultiquadraticBundleChannelsV1",
      "BBar" -> ArrayReshape[targetChannels,
        Append[dimensions, gradeCount]],
      "BundleFingerprint" -> bundle["BundleFingerprint"],
      "OperandEvaluationCount" -> operandScalarCount,
      "CoefficientEvaluationCount" -> coefficientScalarCount,
      "OperandEntryEvaluationCount" -> evaluationCount,
      "CoefficientEntryEvaluationCount" -> coefficientCount,
      "OperandScalarBranchEvaluationCount" -> operandScalarCount,
      "CoefficientScalarBranchEvaluationCount" -> coefficientScalarCount,
      "ScalarBranchEvaluationCount" ->
        operandScalarCount + coefficientScalarCount,
      "GlobalSheetScalarBranchEvaluationCount" -> globalSheetScalarCount,
      "ScalarBranchEvaluationReduction" -> globalSheetScalarCount -
        operandScalarCount - coefficientScalarCount,
      "SplitSparseCompileAttemptCount" -> 0,
      "SplitSparseCompileCacheHitCount" -> 0,
      "SplitSparseCompileCacheMissCount" -> 0,
      "SplitSparseEvaluationCount" -> 0,
      "SplitSubstitutionFallbackCount" -> 0,
      "SplitSparseCompileSeconds" -> 0.,
      "SplitSparseEvaluationSeconds" -> 0.,
      "SplitSubstitutionFallbackSeconds" -> 0.,
      "OccurrenceGatherSeconds" -> gatherSeconds,
      "CompositionSeconds" -> compositionSeconds,
      "SplitSparsePlanFingerprint" -> splitPlan["PlanFingerprint"],
      "OperandLocalRankHistogram" -> Counts[Length /@ operandActiveRoots],
      "CoefficientLocalRankHistogram" -> Counts[
        Length /@ Flatten[coefficientActiveRoots, 1]],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
  zero = ConstantArray[0, gradeCount];
  multiply[left_, right_] := Module[{product =
      multiquadraticMultiply[left, right, deltaValues, prime]},
    If[! ListQ[product],
      Throw[multiquadraticStripFailure[
        "BundleQuotientProductFailed"], tag]];
    Mod[product, prime]];
  If[kind === "SplitBranch",
    If[! TrueQ[preflight["SplitPointQ"]],
      Throw[multiquadraticStripFailure["PointNotSplitOverPrime",
        <|"LargeEntryEvaluationCount" -> 0|>], tag]];
    evaluateSplit[expression_, activeIndices_List, role_String] := Module[
      {result, scalarCount},
      result = multiquadraticStripSplitBranchEntry[expression, roots,
        activeIndices, scalarRules, deltaValues, rootValues, prime];
      If[Lookup[result, "Status", None] =!= "OK",
        Throw[Join[multiquadraticStripFailure[
          "BundleSplitEvaluationFailed"],
          <|"Role" -> role, "Detail" -> result|>], tag]];
      scalarCount = Length[Lookup[result, "BranchValues", {}]];
      If[scalarCount =!= 2^Length[activeIndices],
        Throw[multiquadraticStripFailure[
          "BundleSplitEvaluationTelemetryInvalid"], tag]];
      splitCompileAttempts++;
      If[TrueQ[Lookup[result, "SparseCompileCacheHit", False]],
        splitCompileCacheHits++, splitCompileCacheMisses++];
      If[Lookup[result, "Method", None] === "SparseRootPlaceholder",
        splitSparseSuccesses++, splitSubstitutionFallbacks++];
      splitCompileSeconds += Lookup[result, "SparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[result,
        "SparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[result,
        "SubstitutionFallbackSeconds", 0.];
      If[role === "Operand",
        evaluationCount++; operandScalarCount += scalarCount,
        coefficientCount++; coefficientScalarCount += scalarCount];
      result["Channels"]];
    operandValues = Table[evaluateSplit[expressions[[id]],
        operandActiveRoots[[id]], "Operand"],
      {id, Length[expressions]}];
    coefficientValues = Table[Table[evaluateSplit[
          coefficientExpressions[[jobIndex, termIndex]],
          coefficientActiveRoots[[jobIndex, termIndex]], "Coefficient"],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}],
      {jobIndex, Length[jobs]}];
    targetChannels = Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}];
    globalSheetScalarCount = gradeCount (evaluationCount + coefficientCount),
    radicalRules = Table[
      {roots[[k, "RootSquare"]], UnitVector[gradeCount, 2^(k - 1) + 1]},
      {k, rank}];
    evaluateGrade[expression_] := Module[{evaluated},
      evaluated = multiquadraticStripModularGradeEvaluate[expression,
        scalarRules, radicalRules, deltaValues, prime];
      If[Lookup[evaluated, "Status", None] =!= "OK",
        Throw[Join[multiquadraticStripFailure[
          "BundleQuotientEvaluationFailed"], <|"Detail" -> evaluated|>],
          tag]];
      evaluated["Channels"]];
    operandValues = Table[evaluationCount++; evaluateGrade[expression],
      {expression, expressions}];
    coefficientValues = Table[Table[coefficientCount++;
        evaluateGrade[coefficientExpressions[[jobIndex, termIndex]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}],
      {jobIndex, Length[jobs]}];
    targetChannels = Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}]];
  <|"Status" -> "MultiquadraticBundleChannelsV1",
    "BBar" -> ArrayReshape[targetChannels,
      Append[dimensions, gradeCount]],
    "BundleFingerprint" -> bundle["BundleFingerprint"],
    (* Historical counts continue to mean actual scalar work on the split
       route; explicit entry counts remove any ambiguity for telemetry. *)
    "OperandEvaluationCount" -> If[kind === "SplitBranch",
      operandScalarCount, evaluationCount],
    "CoefficientEvaluationCount" -> If[kind === "SplitBranch",
      coefficientScalarCount, coefficientCount],
    "OperandEntryEvaluationCount" -> evaluationCount,
    "CoefficientEntryEvaluationCount" -> coefficientCount,
    "OperandScalarBranchEvaluationCount" -> operandScalarCount,
    "CoefficientScalarBranchEvaluationCount" -> coefficientScalarCount,
    "ScalarBranchEvaluationCount" ->
      operandScalarCount + coefficientScalarCount,
    "GlobalSheetScalarBranchEvaluationCount" -> globalSheetScalarCount,
    "ScalarBranchEvaluationReduction" ->
      globalSheetScalarCount - operandScalarCount - coefficientScalarCount,
    "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
    "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
    "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
    "SplitSparseEvaluationCount" -> splitSparseSuccesses,
    "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
    "SplitSparseCompileSeconds" -> splitCompileSeconds,
    "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
    "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
    "OperandLocalRankHistogram" -> Counts[Length /@ operandActiveRoots],
    "CoefficientLocalRankHistogram" -> Counts[
      Length /@ Flatten[coefficientActiveRoots, 1]],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
], tag, #1 &];
multiquadraticStripBundleProviderChannels[___] :=
  multiquadraticStripFailure["InvalidBundleProviderArguments"];

(* Planned SplitBranch evaluation visits every unique leaf exactly once, then
   gathers all E/C/BBar/one-form and deferred-DAG occurrences by integer map.
   No expression, active-root list, or cache key is hashed on this path. *)
multiquadraticStripPlannedProviderChannels[provider_Association,
    preflight_Association, plan_Association,
    suppliedLeafChannels_: Automatic] := Module[
  {startTime = AbsoluteTime[], prime = Lookup[preflight, "Prime", $Failed],
   scalarRules, deltaValues, rootValues, leafEvaluationSeconds,
   leafResults, badIndex, bad, leafChannels, maps, gatherSeconds,
   values, oneFormValues, bundleChannels = None, entryKeys,
   sparseCount, nativeCount, fallbackCount, sparseSeconds, fallbackSeconds,
   bundleGatherSeconds = 0., bundleCompositionSeconds = 0.,
   occurrenceCount, entryCount},
  If[Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      Lookup[preflight, "ProviderFingerprint", None] =!=
        Lookup[provider, "ProviderFingerprint", None] ||
      ! multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[
        plan, provider, prime],
    Return[multiquadraticStripFailure[
      "InvalidSplitSparseEvaluationPlan"]]];
  scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["RootSquares"];
  rootValues = preflight["RootValues"];
  If[suppliedLeafChannels === Automatic,
    {leafEvaluationSeconds, leafResults} = AbsoluteTiming[MapIndexed[
      multiquadraticStripSplitSparsePlannedEntry[plan, First[#2], provider,
        scalarRules, deltaValues, rootValues, prime] &, plan["Leaves"]]],
    If[! ListQ[suppliedLeafChannels] ||
        Length[suppliedLeafChannels] =!= Length[plan["Leaves"]] ||
        ! AllTrue[suppliedLeafChannels,
          VectorQ[#1, IntegerQ] &&
            Length[#1] === provider["GradeCount"] &],
      Return[multiquadraticStripFailure[
        "InvalidNativeSparseLeafChannels"]]];
    leafEvaluationSeconds = 0.;
    leafResults = Map[<|"Status" -> "OK", "Channels" -> #1,
        "Method" -> "NativeSparseBatch", "SparseEvaluationSeconds" -> 0.,
        "SubstitutionFallbackSeconds" -> 0.|> &,
      suppliedLeafChannels]];
  badIndex = SelectFirst[Range[Length[leafResults]],
    Lookup[leafResults[[#1]], "Status", None] =!= "OK" &,
    Missing["NotFound"]];
  If[! MissingQ[badIndex],
    bad = leafResults[[badIndex]];
    Return[Join[<|"Status" -> Lookup[bad, "Status",
          "SplitSparsePlannedLeafFailed"],
        "SplitSparsePlanLeafIndex" -> badIndex,
        "SplitSparsePlanFingerprint" -> plan["PlanFingerprint"],
        "Prime" -> prime,
        "RegulatorValue" -> preflight["RegulatorValue"],
        "Point" -> preflight["Point"],
        "LargeEntryEvaluationCount" -> 0|>,
      KeyDrop[bad, "Status"]]]];
  leafChannels = Lookup[leafResults, "Channels"];
  maps = plan["OccurrenceMaps"];
  entryKeys = Keys[provider["Entries"]];
  {gatherSeconds, {values, oneFormValues}} = AbsoluteTiming[{
    Association[Table[key -> Map[leafChannels[[#1]] &,
      maps["Entries"][key], {3}], {key, entryKeys}]],
    If[provider["OneForms"] === {}, {},
      Map[leafChannels[[#1]] &, maps["OneForms"], {2}]]}];
  If[AssociationQ[Lookup[provider, "DeferredBundle", None]],
    bundleChannels = multiquadraticStripBundleProviderChannels[provider,
      preflight, plan, leafChannels];
    If[Lookup[bundleChannels, "Status", None] =!=
        "MultiquadraticBundleChannelsV1", Return[bundleChannels]];
    AssociateTo[values, "BBar" -> bundleChannels["BBar"]];
    bundleGatherSeconds = Lookup[bundleChannels,
      "OccurrenceGatherSeconds", 0.];
    bundleCompositionSeconds = Lookup[bundleChannels,
      "CompositionSeconds", 0.]];
  sparseCount = Count[Lookup[leafResults, "Method", None],
    "SparseRootPlaceholder" | "NativeSparseBatch"];
  nativeCount = Count[Lookup[leafResults, "Method", None],
    "NativeSparseBatch"];
  fallbackCount = Length[leafResults] - sparseCount;
  sparseSeconds = Total[Lookup[leafResults, "SparseEvaluationSeconds", 0.]];
  fallbackSeconds = Total[Lookup[leafResults,
    "SubstitutionFallbackSeconds", 0.]];
  occurrenceCount = plan["OccurrenceCount"];
  entryCount = occurrenceCount;
  <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "SplitBranch", "Prime" -> prime,
    "Point" -> preflight["Point"],
    "RegulatorValue" -> preflight["RegulatorValue"],
    "EpsilonMod" -> preflight["EpsilonMod"],
    "RootSquares" -> deltaValues, "RootValues" -> rootValues,
    "SplitPointQ" -> preflight["SplitPointQ"],
    "GaugeDenominator" -> preflight["GaugeDenominator"],
    "GaugeLogDerivatives" -> preflight["GaugeLogDerivatives"],
    "RootLogDerivatives" -> preflight["RootLogDerivatives"],
    "E" -> values["E"], "C" -> values["C"],
    "BBar" -> values["BBar"], "OneForms" -> oneFormValues,
    "CoefficientABIFingerprint" -> provider["CoefficientABIFingerprint"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "DeferredBundleFingerprint" -> Lookup[provider,
      "DeferredBundleFingerprint", None],
    "BundleOperandEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "OperandEvaluationCount", 0], 0],
    "BundleCoefficientEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "CoefficientEvaluationCount", 0], 0],
    "BundleOperandEntryEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "OperandEntryEvaluationCount", 0], 0],
    "BundleCoefficientEntryEvaluationCount" -> If[
      AssociationQ[bundleChannels],
      Lookup[bundleChannels, "CoefficientEntryEvaluationCount", 0], 0],
    "BundleOperandScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "OperandScalarBranchEvaluationCount", 0], 0],
    "BundleCoefficientScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "CoefficientScalarBranchEvaluationCount", 0], 0],
    "BundleScalarBranchEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "ScalarBranchEvaluationCount", 0], 0],
    "BundleGlobalSheetScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "GlobalSheetScalarBranchEvaluationCount", 0], 0],
    "BundleScalarBranchEvaluationReduction" -> If[
      AssociationQ[bundleChannels],
      Lookup[bundleChannels, "ScalarBranchEvaluationReduction", 0], 0],
    "BundleEvaluationSeconds" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "Seconds", 0], 0],
    "SplitSparseCompileAttemptCount" -> 0,
    "SplitSparseCompileCacheHitCount" -> 0,
    "SplitSparseCompileCacheMissCount" -> 0,
    "SplitSparseEvaluationCount" -> sparseCount,
    "SplitSparseNativeEvaluationCount" -> nativeCount,
    "SplitSubstitutionFallbackCount" -> fallbackCount,
    "SplitSparseCompileSeconds" -> 0.,
    "SplitSparseEvaluationSeconds" -> sparseSeconds,
    "SplitSubstitutionFallbackSeconds" -> fallbackSeconds,
    "SplitSparsePlanFingerprint" -> plan["PlanFingerprint"],
    "SplitSparseUniqueLeafCount" -> Length[plan["Leaves"]],
    "SplitSparseOccurrenceCount" -> occurrenceCount,
    "SplitSparseUniqueLeafEvaluationSeconds" -> leafEvaluationSeconds,
    "SplitSparseOccurrenceGatherSeconds" ->
      gatherSeconds + bundleGatherSeconds,
    "SplitSparseDeferredBundleCompositionSeconds" ->
      bundleCompositionSeconds,
    "PreflightSeconds" -> preflight["PreflightSeconds"],
    "LargeEntryEvaluationCount" -> entryCount,
    "EntryEvaluationCount" -> entryCount,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripPlannedProviderChannels[___] :=
  multiquadraticStripFailure[
    "InvalidPlannedProviderChannelArguments"];

(* ONE point, ONE regulator image, ONE prime: every coefficient value the
   row assembler consumes.  Four arguments construct the authenticated
   preflight; the five-argument form reuses one already drawn by the
   sampler.  A typed rejection of the point is never a zero value. *)
multiquadraticStripProviderChannels[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer}] := Module[{preflight},
  preflight = multiquadraticStripProviderPreflight[provider, epsilonValue,
    prime, point];
  If[Lookup[preflight, "Status", None] =!=
      "MultiquadraticProviderPreflightV1", preflight,
    Block[{$multiquadraticStripTrustedProviderEvaluation = True},
      multiquadraticStripProviderChannels[provider, epsilonValue, prime,
        point, preflight]]]
];

multiquadraticStripProviderChannels[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    preflight_Association, splitPlan_: Automatic,
    forcingMode_: Automatic] := Module[
  {startTime = AbsoluteTime[], roots, rank, kind, scalarRules, deltaValues,
    rootValues, evaluateEntry, values, oneFormValues, entryCount = 0,
    tag, evaluated, entryKeys, bundleChannels,
    nativeDeferredForcingQ,
    splitCompileAttempts = 0, splitCompileCacheHits = 0,
    splitCompileCacheMisses = 0, splitSparseSuccesses = 0,
    splitSubstitutionFallbacks = 0, splitCompileSeconds = 0.,
    splitEvaluationSeconds = 0., splitFallbackSeconds = 0.},
  If[Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      Lookup[preflight, "ProviderFingerprint", None] =!=
        Lookup[provider, "ProviderFingerprint", None] ||
      Lookup[preflight, "Prime", None] =!= prime ||
      Lookup[preflight, "RegulatorValue", None] =!= epsilonValue ||
      Lookup[preflight, "Point", None] =!= Mod[point, prime],
    Return[multiquadraticStripFailure["ProviderPreflightMismatch"]]];
  If[Lookup[provider, "Kind", None] === "CompiledChannel",
    If[splitPlan =!= Automatic,
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]];
    Return[multiquadraticStripCompiledProviderChannels[provider, preflight]]];
  If[! multiquadraticStripProviderEvaluationValidQ[provider],
    Return[multiquadraticStripFailure["InvalidDirectProvider"]]];
  roots = provider["Roots"];
  rank = provider["RootCount"];
  kind = provider["Kind"];
  nativeDeferredForcingQ = forcingMode === "NativeDeferredAST" &&
    AssociationQ[Lookup[provider, "DeferredPreparation", None]];
  If[splitPlan =!= Automatic,
    If[kind =!= "SplitBranch",
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]];
    Return[multiquadraticStripPlannedProviderChannels[provider, preflight,
      splitPlan]]];
  scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["RootSquares"];
  rootValues = preflight["RootValues"];
  tag = Unique["MultiquadraticDirectProviderEntryFailure"];
  evaluateEntry[entry_, activeIndices_] := Module[{result},
    entryCount++;
    result = If[kind === "SplitBranch",
      multiquadraticStripSplitBranchEntry[entry, roots, activeIndices,
        scalarRules, deltaValues, rootValues, prime],
      multiquadraticStripQuotientGradeEntry[entry, roots, activeIndices,
        scalarRules, deltaValues, prime]];
    If[Lookup[result, "Status", None] =!= "OK",
      Throw[Join[<|"Status" -> Lookup[result, "Status",
          "ProviderRejected"], "Point" -> Mod[point, prime],
        "Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "ProviderFingerprint" -> provider["ProviderFingerprint"],
        "LargeEntryEvaluationCount" -> entryCount|>,
        KeyDrop[result, "Status"]], tag]];
    If[kind === "SplitBranch",
      splitCompileAttempts++;
      If[TrueQ[Lookup[result, "SparseCompileCacheHit", False]],
        splitCompileCacheHits++, splitCompileCacheMisses++];
      If[Lookup[result, "Method", None] === "SparseRootPlaceholder",
        splitSparseSuccesses++, splitSubstitutionFallbacks++];
      splitCompileSeconds += Lookup[result, "SparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[result,
        "SparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[result,
        "SubstitutionFallbackSeconds", 0.]];
    result["Channels"]];
  evaluated = Catch[
    entryKeys = Keys[provider["Entries"]];
    If[nativeDeferredForcingQ,
      entryKeys = DeleteCases[entryKeys, "BBar"]];
    values = Association[Table[
      key -> MapThread[evaluateEntry, {provider["Entries"][key],
        provider["ActiveRoots"][key]}, 3],
      {key, entryKeys}]];
    If[AssociationQ[Lookup[provider, "DeferredBundle", None]] &&
        ! nativeDeferredForcingQ,
      bundleChannels = multiquadraticStripBundleProviderChannels[provider,
        preflight];
      If[Lookup[bundleChannels, "Status", None] =!=
          "MultiquadraticBundleChannelsV1",
        Throw[Join[<|"Status" -> Lookup[bundleChannels, "Status",
            "BundleProviderRejected"],
          "Point" -> Mod[point, prime], "Prime" -> prime,
          "RegulatorValue" -> epsilonValue,
          "ProviderFingerprint" -> provider["ProviderFingerprint"],
          "LargeEntryEvaluationCount" -> entryCount +
            Lookup[bundleChannels, "OperandEvaluationCount", 0]|>,
          KeyDrop[bundleChannels, "Status"]], tag]];
      AssociateTo[values, "BBar" -> bundleChannels["BBar"]];
      entryCount += Lookup[bundleChannels, "OperandEvaluationCount", 0];
      splitCompileAttempts += Lookup[bundleChannels,
        "SplitSparseCompileAttemptCount", 0];
      splitCompileCacheHits += Lookup[bundleChannels,
        "SplitSparseCompileCacheHitCount", 0];
      splitCompileCacheMisses += Lookup[bundleChannels,
        "SplitSparseCompileCacheMissCount", 0];
      splitSparseSuccesses += Lookup[bundleChannels,
        "SplitSparseEvaluationCount", 0];
      splitSubstitutionFallbacks += Lookup[bundleChannels,
        "SplitSubstitutionFallbackCount", 0];
      splitCompileSeconds += Lookup[bundleChannels,
        "SplitSparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[bundleChannels,
        "SplitSparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[bundleChannels,
        "SplitSubstitutionFallbackSeconds", 0.]];
    oneFormValues = If[provider["OneForms"] === {}, {},
      MapThread[evaluateEntry, {provider["OneForms"],
        provider["OneFormActiveRoots"]}, 2]];
    <|"Status" -> "MultiquadraticPointCoefficientsV1",
      "Provider" -> kind, "Prime" -> prime,
      "Point" -> Mod[point, prime], "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> preflight["EpsilonMod"],
      "RootSquares" -> deltaValues, "RootValues" -> rootValues,
      "SplitPointQ" -> preflight["SplitPointQ"],
      "GaugeDenominator" -> preflight["GaugeDenominator"],
      "GaugeLogDerivatives" -> preflight["GaugeLogDerivatives"],
      "RootLogDerivatives" -> preflight["RootLogDerivatives"],
      "E" -> values["E"], "C" -> values["C"],
      "BBar" -> If[nativeDeferredForcingQ,
        Missing["NativeDeferredASTPending"], values["BBar"]],
      "ForcingProvider" -> If[nativeDeferredForcingQ,
        "NativeDeferredASTPending", kind],
      "OneForms" -> oneFormValues,
      "CoefficientABIFingerprint" -> provider["CoefficientABIFingerprint"],
      "ProviderFingerprint" -> provider["ProviderFingerprint"],
      "DeferredBundleFingerprint" -> Lookup[provider,
        "DeferredBundleFingerprint", None],
      "BundleOperandEvaluationCount" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "OperandEvaluationCount", 0], 0],
      "BundleCoefficientEvaluationCount" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "CoefficientEvaluationCount", 0], 0],
      "BundleOperandEntryEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "OperandEntryEvaluationCount", 0], 0],
      "BundleCoefficientEntryEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "CoefficientEntryEvaluationCount", 0], 0],
      "BundleOperandScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "OperandScalarBranchEvaluationCount", 0], 0],
      "BundleCoefficientScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "CoefficientScalarBranchEvaluationCount", 0], 0],
      "BundleScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "ScalarBranchEvaluationCount", 0], 0],
      "BundleGlobalSheetScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "GlobalSheetScalarBranchEvaluationCount", 0], 0],
      "BundleScalarBranchEvaluationReduction" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "ScalarBranchEvaluationReduction", 0], 0],
      "BundleEvaluationSeconds" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "Seconds", 0], 0],
      "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
      "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
      "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
      "SplitSparseEvaluationCount" -> splitSparseSuccesses,
      "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
      "SplitSparseCompileSeconds" -> splitCompileSeconds,
      "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
      "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
      "PreflightSeconds" -> preflight["PreflightSeconds"],
      "LargeEntryEvaluationCount" -> entryCount,
      "EntryEvaluationCount" -> entryCount,
      "Seconds" -> N[AbsoluteTime[] - startTime]|>, tag];
  evaluated
];
multiquadraticStripProviderChannels[___] :=
  multiquadraticStripFailure["InvalidProviderChannelArguments"];

(* ------------------------------------------------------------------ *)
(* A CONSERVATIVE GAUGE DENOMINATOR, WITHOUT ANY CHANNEL DECOMPOSITION  *)
(* (round-2 item 9; Codex 2.3, the screen-first ordering)               *)
(* ------------------------------------------------------------------ *)

(* WHY IT IS A SUPERSET, and why that matters.  The production rule
   multiquadraticRationalGaugeDenominator reads the CHANNEL denominators
   and admits each polar factor one power below its worst order.  A
   channel of f = N/D has denominator dividing the NORM of D, because
   clearing D by its conjugates is exactly what the channel
   decomposition does.  So

     Prod over rational factors  g^(max multiplicity)
     x Prod over algebraic factors Norm(g)^(max multiplicity)
     x the alphabet's own norm factor

   is divisible by the production denominator for every entry, at every
   multiplicity: it is a SUPERSET ansatz, and a screen that refuses a
   superset refuses every subset of it -- which is what makes it sound to
   run the screen BEFORE the expensive exact preparation.

   It is deliberately generous, and that is the point: it costs one
   FactorList per distinct raw denominator (work the gauge-denominator
   rule already does) instead of the 1400.5 s global decomposition it
   replaces in the screen's input. *)
multiquadraticStripConservativeGaugeDenominator[strip_, roots_List,
    letterRecords_, variables_List] := Module[
  {entries, denominators, factorPairs, groups, rational, algebraic,
   normFactor, product, conjugates, norm},
  entries = DeleteCases[Flatten[strip[[3]]], 0];
  denominators = DeleteDuplicates[
    Denominator[Quiet[Together[#1]]] & /@ entries];
  denominators = DeleteCases[denominators, _?NumericQ];
  factorPairs = Flatten[Map[
    Function[denominator, Module[{list = Quiet[FactorList[denominator]]},
      If[! ListQ[list], {}, Select[Rest[list], ! NumericQ[First[#1]] &]]]],
    denominators], 1];
  If[factorPairs === {} && ! MatchQ[letterRecords, {___Association}],
    Return[1]];
  conjugates[factor_] := DeleteDuplicates[
    Table[Quiet[Together[transportChartApplyRootBranches[factor, roots,
      Table[If[BitGet[mask, k - 1] === 1, -1, 1] Lookup[roots[[k]], "Root", 0],
        {k, Length[roots]}]]]],
      {mask, 0, 2^Length[roots] - 1}],
    TrueQ[Quiet[Together[#1 - #2]] === 0] &];
  norm[factor_] := Quiet[Expand[Together[Times @@ conjugates[factor]]]];
  groups = GatherBy[factorPairs, Quiet[Expand[Together[First[#1]]]] &];
  rational = Times @@ Table[
    Quiet[Expand[Together[First[First[group]]]]]^Max[Last /@ group],
    {group, Select[groups, FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  algebraic = Times @@ Table[
    norm[First[First[group]]]^Max[Last /@ group],
    {group, Select[groups, ! FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  normFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  product = Quiet[Together[rational algebraic normFactor]];
  If[TrueQ[product === 0] ||
      ! FreeQ[product, Power[_, _Rational?(Denominator[#1] === 2 &)]],
    Return[$Failed]];
  Quiet[Expand[product]]
];
multiquadraticStripConservativeGaugeDenominator[___] := $Failed;

(* Build the rational gauge pole ansatz from the immutable pre-cancellation
   divisor census.  Algebraic factors enter through their certified Galois
   orbit norm; factors in the same orbit are merged at the largest required
   order rather than multiplied repeatedly. *)
multiquadraticStripBundleGaugeDenominator[bundle_Association,
    variables : {_Symbol, _Symbol}, letterRecords_: {}] := Module[
  {startTime = AbsoluteTime[], validation, summary, factors, orbits, keyGroups,
   collapsedRecords, grouped, forcingSources, forcingFactor, letterFactor,
   mergeData, denominator, records},
  validation = blockEquationDeferredBundleValidate[bundle];
  If[Lookup[validation, "Status", None] =!= "BundleValid",
    Return[multiquadraticStripFailure["InvalidDeferredBundle",
      <|"Detail" -> validation|>]]];
  summary = bundle["DivisorSummary"];
  factors = summary["Factors"];
  orbits = summary["GaloisOrbits"];
  records = DeleteCases[Table[Module[
      {order = Ceiling[Lookup[factor,
          "MaxEntryPoleOrderUpperBound", 0]], base, exponent},
      exponent = Max[0, order - 1];
      If[exponent === 0, Return[Nothing, Module]];
      base = If[TrueQ[Lookup[factor, "Algebraic", False]],
        With[{orbit = Lookup[factor, "OrbitIndex", 0]},
          If[! IntegerQ[orbit] || ! (1 <= orbit <= Length[orbits]),
            Return[Nothing, Module]];
          Lookup[orbits[[orbit]], "Norm", $Failed]],
        Lookup[factor, "Factor", $Failed]];
      If[base === $Failed ||
          FreeQ[base, Alternatives @@ variables], Return[Nothing, Module]];
      <|"Base" -> Quiet[Together[base]], "Exponent" -> exponent,
        "FactorIndex" -> Lookup[factor, "FactorIndex", None],
        "OrbitIndex" -> Lookup[factor, "OrbitIndex", 0],
        "SourcePoleOrderUpperBound" -> order|>],
    {factor, factors}], Nothing];
  (* FactorIndex is unique for a rational divisor; algebraic conjugates that
     share a norm already carry the same validated OrbitIndex.  Collapse those
     guaranteed equalities by integer key before the semantic comparison.
     Different orbits, and an orbit versus a rational factor, can still have
     equal bases, so the final Together-Gather is retained on the much smaller
     collapsed list. *)
  keyGroups = GatherBy[records, If[#1["OrbitIndex"] > 0,
      {"Orbit", #1["OrbitIndex"]}, {"Factor", #1["FactorIndex"]}] &];
  collapsedRecords = Map[Function[group, Append[First[group],
      "Exponent" -> Max[Lookup[group, "Exponent"]]]], keyGroups];
  grouped = Gather[collapsedRecords,
    TrueQ[Quiet[Together[#1["Base"] - #2["Base"]]] === 0] &];
  forcingSources = Table[
    {First[group]["Base"], Max[Lookup[group, "Exponent"]]},
    {group, grouped}];
  forcingFactor = Times @@
    (First[#1]^Last[#1] & /@ forcingSources);
  letterFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  mergeData = multiquadraticStripMergeGaugeDenominatorSourceData[
    forcingSources, letterFactor, variables];
  If[! AssociationQ[mergeData] ||
      Lookup[mergeData, "Status", None] =!=
        "GaugeDenominatorSourceDataV1",
    Return[multiquadraticStripFailure[
      "BundleGaugeDenominatorFactorMergeFailed"]]];
  denominator = mergeData["GaugeDenominator"];
  If[denominator === $Failed || TrueQ[denominator === 0] ||
      ! FreeQ[denominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure[
      "BundleGaugeDenominatorNotRational"]]];
  <|"Status" -> "BundleGaugeDenominatorV1",
    "GaugeDenominator" -> denominator,
    "ForcingFactor" -> forcingFactor, "LetterFactor" -> letterFactor,
    "DivisorRecords" -> records,
    "DivisorSummary" -> summary,
    "BundleFingerprint" -> bundle["BundleFingerprint"],
    "GaugeDenominatorDegrees" -> mergeData["GaugeDenominatorDegrees"],
    "FactorCount" -> Length[factors], "OrbitCount" -> Length[orbits],
    "ProvenanceGroupCount" -> Length[keyGroups],
    "GroupedFactorCount" -> Length[grouped],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripBundleGaugeDenominator[___] :=
  multiquadraticStripFailure["InvalidBundleGaugeDenominatorArguments"];

(* The bundle divisor census is deliberately pre-cancellation.  That is a
   cheap and safe default, but a large overestimate makes the dense affine
   system grow quadratically in memory.  When the estimated sampler would
   cross its hard byte ceiling, materialize only the small target block and
   decompose its scalar entries exactly.  This is denominator computation,
   not a second acceptance test: the existing block-level modular identity
   remains the production acceptance boundary. *)
multiquadraticStripBundleExactChannelTask[payload_Association,
    indices_List] := Module[{entries, roots, channels},
  If[! AssociationQ[payload], Return[$Failed]];
  entries = Lookup[payload, "Entries", $Failed];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[entries] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ] ||
      ! AllTrue[indices, Between[#1, {1, Length[entries]}] &],
    Return[$Failed]];
  channels = multiquadraticStripDecomposeScalar[#1, roots] & /@
    entries[[indices]];
  If[! AllTrue[channels,
      ListQ[#1] && Length[#1] === 2^Length[roots] &&
        FreeQ[#1, $Failed] &], $Failed,
    <|"Indices" -> indices, "Channels" -> channels|>]
];
multiquadraticStripBundleExactChannelTask[dataFile_String,
    indices_List] := Module[{payload = taskBrokerRead[dataFile]},
  If[AssociationQ[payload],
    multiquadraticStripBundleExactChannelTask[payload, indices], $Failed]
];
multiquadraticStripBundleExactChannelTask[___] := $Failed;

multiquadraticStripBundleExactChannels[forcing_, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    bundleFingerprint_String] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[forcing], entries,
   gradeCount = 2^Length[roots], rules, inverseRules, payload, dataFile,
   free = 0, workerCount, groups, helperGroups, localGroup, codes, handle,
   helperResults, localResult, results, channelVectors, result, indices,
   channels, missing},
  If[! MatchQ[dimensions, {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure[
      "InvalidBundleExactChannelForcing"]]];
  entries = Flatten[forcing];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  inverseRules = Reverse /@ rules;
  payload = <|"Entries" -> (entries /. rules), "Roots" -> (roots /. rules)|>;
  If[! multiquadraticStripContextFreeQ[payload],
    Return[multiquadraticStripFailure[
      "ContextSensitiveBundleExactChannels"]]];
  If[TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
    free = Quiet[Check[taskBrokerFreeKernels[], 0]]];
  If[! IntegerQ[free] || free < 0, free = 0];
  workerCount = Min[Length[entries], free + 1];
  groups = TakeList[Range[Length[entries]],
    Ceiling[(Length[entries] - Range[workerCount] + 1)/workerCount]];
  helperGroups = Most[groups];
  localGroup = Last[groups];
  dataFile = If[helperGroups === {}, None,
    taskBrokerDataFile["mqbundlechannels_" <>
      Hash[{"BundleExactChannelsV1", $multiquadraticStripABIVersion,
        bundleFingerprint, Lookup[roots, "RootSquare", {}] /. rules},
        "SHA256", "HexString"], payload]];
  If[helperGroups =!= {} && StringQ[dataFile],
    codes = Table[
      "FeynFacet`Private`multiquadraticStripBundleExactChannelTask[" <>
        ToString[dataFile, InputForm] <> "," <>
        ToString[group, InputForm] <> "]", {group, helperGroups}];
    handle = taskBrokerSubmit[codes, "Label" -> "mqbundlechannels",
      "Timeout" -> 7200],
    helperGroups = {};
    localGroup = Range[Length[entries]];
    handle = None];
  localResult = multiquadraticStripBundleExactChannelTask[payload, localGroup];
  helperResults = If[AssociationQ[handle], taskBrokerCollect[handle], {}];
  results = Join[helperResults, {localResult}];
  channelVectors = ConstantArray[Missing["NotComputed"], Length[entries]];
  Do[
    result = results[[k]];
    If[AssociationQ[result],
      indices = Lookup[result, "Indices", {}];
      channels = Lookup[result, "Channels", {}];
      If[VectorQ[indices, IntegerQ] && Length[indices] === Length[channels] &&
          AllTrue[indices, Between[#1, {1, Length[entries]}] &],
        MapThread[(channelVectors[[#1]] = #2) &, {indices, channels}]]],
    {k, Length[results]}];
  missing = Flatten[Position[channelVectors, _Missing, {1}, Heads -> False]];
  If[missing =!= {},
    result = multiquadraticStripBundleExactChannelTask[payload, missing];
    If[! AssociationQ[result],
      Return[multiquadraticStripFailure[
        "BundleExactChannelDecompositionFailed",
        <|"MissingEntryIndices" -> missing|>]]];
    MapThread[(channelVectors[[#1]] = #2) &,
      {result["Indices"], result["Channels"]}]];
  If[! AllTrue[channelVectors,
      ListQ[#1] && Length[#1] === gradeCount && FreeQ[#1, $Failed] &],
    Return[multiquadraticStripFailure[
      "BundleExactChannelDecompositionFailed"]]];
  <|"Status" -> "BundleExactForcingChannelsV1",
    "Channels" -> (ArrayReshape[Flatten[channelVectors],
       Append[dimensions, gradeCount]] /. inverseRules),
    "EntryCount" -> Length[entries],
    "BrokerHelperCount" -> Length[helperGroups],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripBundleExactChannels[___] :=
  multiquadraticStripFailure["InvalidBundleExactChannelArguments"];

multiquadraticStripBundleRefinedGaugeDenominator[bundle_Association,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    letterRecords_: {}] := Module[
  {startTime = AbsoluteTime[], evaluated, exactChannels, forcingFactor,
   letterFactor, denominator},
  (* The caller has already authenticated the bundle while constructing the
     conservative denominator.  Repeating that scan here adds no mathematics. *)
  evaluated = blockEquationDeferredBundleEvaluate[bundle, {},
    "Validate" -> False, "ExpressionTransform" -> Identity];
  If[Lookup[evaluated, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure[
      "BundleExactMaterializationFailed"]]];
  exactChannels = multiquadraticStripBundleExactChannels[
    evaluated["Image"], roots, variables, epsilon,
    Lookup[bundle, "BundleFingerprint", "UnfingerprintedBundle"]];
  If[Lookup[exactChannels, "Status", None] =!=
      "BundleExactForcingChannelsV1", Return[exactChannels]];
  forcingFactor = multiquadraticRationalGaugeDenominator[
    exactChannels["Channels"], variables];
  letterFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  denominator = multiquadraticStripMergeGaugeDenominator[
    forcingFactor, letterFactor, variables];
  If[denominator === $Failed || TrueQ[Quiet[Together[denominator]] === 0] ||
      ! FreeQ[denominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure[
      "BundleRefinedGaugeDenominatorNotRational"]]];
  <|"Status" -> "BundleRefinedGaugeDenominatorV1",
    "GaugeDenominator" -> denominator,
    "GaugeDenominatorDegrees" ->
      (Exponent[denominator, #1] & /@ variables),
    "ForcingFactor" -> forcingFactor, "LetterFactor" -> letterFactor,
    "EntryCount" -> exactChannels["EntryCount"],
    "BrokerHelperCount" -> exactChannels["BrokerHelperCount"],
    "ChannelSeconds" -> exactChannels["Seconds"],
    "Seconds" -> N[AbsoluteTime[] - startTime],
    "BundleFingerprint" -> Lookup[bundle, "BundleFingerprint", None]|>
];
multiquadraticStripBundleRefinedGaugeDenominator[___] :=
  multiquadraticStripFailure[
    "InvalidBundleRefinedGaugeDenominatorArguments"];


(* ------------------------------------------------------------------ *)
(* RATIONAL-IN-EPSILON RECONSTRUCTION (2026-08-26, round-2 item 6)      *)
(* ------------------------------------------------------------------ *)

(* THE MISSING ALGORITHM, in Codex review 1.1's words: the route solved
   the whole unknown vector INDEPENDENTLY for every (prime, regulator
   value), checked only that rank/nullity/pivot signatures agreed, and
   published the gauge and residues of the FIRST epsilon fiber.  A stable
   pivot structure does not establish that those independently chosen
   particular solutions are evaluations of ONE rational vector
   (g(eps), K(eps)): independently chosen particular solutions can jump
   between nullspace sections as eps varies, and interpolating them is
   then meaningless.  That is not a defect in the declared
   ModularConsistent contract -- it is the algorithm between that
   contract and a solved form.

   THE COMMON NORMALIZATION IS PART OF THE MATHEMATICS.  A canonical
   affine SECTION is chosen once -- nullity many normalization columns
   whose nullspace block is nonsingular -- and every epsilon image and
   every prime is normalized to the SAME section before anything is
   interpolated.  An image whose block is singular on those columns is
   rejected typed; it is not silently normalized differently.

   PORTED, NOT REDESIGNED.  The rational route's machinery is called
   directly, because it is the same mathematics on the same field:

     finiteFieldStripNormalizationColumns  the section (gauge-tail
                                           first, residues as fallback)
     NormalizeEpsFormAffineSample          the canonical representative
     finiteFieldStripHeldOutInterpolate    adaptive rational fitting of
                                           EVERY coordinate in eps, with
                                           held-out eps validation and
                                           degree-profile rejection
     epsFormFiniteFieldCombineCoordinate   CRT across primes
     epsFormFiniteFieldRationalReconstruct the rational lift
     epsFormFiniteFieldImageQ              the coefficient image check

   WHAT COMES OUT.  g(eps) and K_a(eps) as rational functions of the
   regulator, with K_a required free of the kinematic variables (they
   are single coordinates of the vector, so this is a check that the
   ansatz was built as claimed, not an assumption).  The reconstructed
   GENERIC object is then reinstalled in the differential equation and
   verified by multiquadraticStripExactChannelResidual -- which is
   exactly why round-2 item 2 had to fix that verifier first: at generic
   eps the pre-fix verifier was accidentally right, and at every numeric
   image it was wrong, so it could never have certified this object.

   DOWNSTREAM IS UNCHANGED.  The residues may still carry eps; the
   staged contract has always been that FactorFamilyRegulatorDependence
   removes it at family level with a constant-in-kinematics T(eps).
   Nothing here changes that stage. *)

$multiquadraticStripRegulatorScheduleDefault = DeleteDuplicates[Join[
  {1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 4, 6, 8, 9, 10, 12,
   5/3, 7/3, 11/5, 13/7, 29, 31}, Range[1, 72]]];

(* A fresh finite-field replay of one reconstructed generic vector.  The
   provider, rather than an exact global channel materialization, builds the
   original equation at fresh points.  Training and validation are readily
   proved disjoint because the caller uses primes absent from the CRT. *)
Options[multiquadraticStripProviderResidualImage] = {
  "PointCount" -> 1,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082701,
  "SplitPointsOnly" -> True
};

multiquadraticStripProviderResidualImage[layout_Association,
    provider_Association, vector_List, epsilon_Symbol, epsilonValue_,
    prime_Integer, opts : OptionsPattern[]] := Module[
  {gate, startTime = AbsoluteTime[], sample, vectorImage, residual,
   residualZero, sampleSeconds, residualSeconds},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripProviderResidualImage]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticStripAssemblyLayoutEvaluationValidQ[layout] ||
      ! multiquadraticStripProviderEvaluationValidQ[provider] ||
      layout["CoefficientABIFingerprint"] =!=
        provider["CoefficientABIFingerprint"] ||
      Length[vector] =!= layout["UnknownCount"],
    Return[multiquadraticStripFailure[
      "InvalidProviderResidualInput"]]];
  {sampleSeconds, sample} = AbsoluteTiming[
    Block[{$multiquadraticStripTrustedProviderEvaluation = True,
        $multiquadraticStripTrustedLayoutEvaluation = True},
      multiquadraticStripAssembleSample[layout, provider, epsilonValue, prime,
        "PointCount" -> OptionValue["PointCount"],
        "MaximumAttempts" -> OptionValue["MaximumAttempts"],
        "RandomSeed" -> OptionValue["RandomSeed"],
        "SplitPointsOnly" -> OptionValue["SplitPointsOnly"]]]];
  If[Lookup[sample, "Status", None] =!=
      "AssembledMultiquadraticSampleV1",
    Return[multiquadraticStripFailure[
      "ProviderValidationImageUnavailable",
      <|"Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "Detail" -> sample, "Seconds" -> N[AbsoluteTime[] - startTime]|>]]];
  vectorImage = multiquadraticStripModRational[#1, prime] & /@
    Quiet[Together /@ (vector /. epsilon -> epsilonValue)];
  If[MemberQ[vectorImage, $Failed],
    Return[multiquadraticStripFailure[
      "ProviderValidationVectorSingular",
      <|"Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]]];
  {residualSeconds, residual} = AbsoluteTiming[
    Mod[sample["Matrix"] . vectorImage - sample["RightHandSide"], prime]];
  residualZero = VectorQ[residual, #1 === 0 &];
  <|"Status" -> If[residualZero,
      "ProviderPointwiseResidualZero", "ProviderPointwiseResidualNonzero"],
    "Passed" -> residualZero, "Prime" -> prime,
    "RegulatorValue" -> epsilonValue,
    "Points" -> sample["AcceptedPoints"],
    "ValidationImageKeys" -> sample["TrainingImageKeys"],
    "LayoutFingerprint" -> layout["LayoutFingerprint"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "NonzeroRowCount" -> Count[residual, Except[0]],
    "ResidualFingerprint" -> multiquadraticStripFingerprint[residual],
    "PhaseSeconds" -> <|"Sampling" -> sampleSeconds,
      "Residual" -> residualSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripProviderResidualImage[___] :=
  multiquadraticStripFailure["InvalidProviderResidualArguments"];

Options[multiquadraticStripReconstructRegulator] = {
  "SamplePrimes" -> Automatic,
  "PrimePool" -> Automatic,
  "MinimumGoodPrimeCount" -> Automatic,
  "MaximumGoodPrimeCount" -> 32,
  "MaximumRejectedPrimeCount" -> 64,
  "RegulatorValues" -> Automatic,
  "InitialRegulatorCount" -> 9,
  "MaximumRegulatorCount" -> Automatic,
  "UnseenPrime" -> Automatic,
  "UnseenPrimeCount" -> 2,
  "FreshPointwiseChecksPerPrime" -> 3,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082601,
  "InitialConstructionCount" -> 4,
  "HeldOutCount" -> 3,
  "MaximumTotalDegree" -> 64,
  "NormalizationColumns" -> Automatic,
  "PlanDiscoveryBackend" -> Automatic,
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> Automatic,
  (* The production driver has just constructed and fully validated these
     three objects.  It may skip repeating the same deep ABI walk at the
     reconstruction boundary; standalone callers retain full validation. *)
  "InputsValidated" -> False,
  (* Total simultaneous follower images, including this kernel.  Automatic
     uses up to four images subject to free TaskBroker helpers and the
     native-core grant. *)
  "ImageKernelCount" -> Automatic,
  (* provider support discovery can hand the exact successful samples and
     affine responses to reconstruction; they are authenticated again before
     entering the image cache *)
  "PilotImages" -> {},
  (* True   = the mathematical statement: the reconstructed GENERIC
              object satisfies the differential equation identically;
     "AtSampledValues" = the same identity at each sampled regulator
              value only (cheap; a probabilistic statement about the
              generic object);
     False  = no exact check (the modular certificates still stand). *)
  (* Automatic preserves the strongest verification supported by the
     coefficient representation: compiled channels prove the exact generic
     identity, while point-evaluated providers use fresh disjoint images. *)
  "ExactVerification" -> Automatic,
  "Deadline" -> Infinity,
  "Verbose" -> False
};

multiquadraticStripReconstructRegulator[preparation_Association,
    layout_Association, provider_Association,
    opts : OptionsPattern[]] := Module[
  {gate, startTime = AbsoluteTime[], deadline, verbose, log, primes, primePool,
   minimumGoodPrimeCount, maximumGoodPrimeCount, maximumRejectedPrimeCount,
   unseenPrime, unseenPrimeCount, validationPrimes, freshPointwiseChecks,
   schedule, values, maximumValues, learnedRegulatorSampleCount = Automatic,
   newPrimeRegulatorValues, pointCount, maximumAttempts,
   randomSeed, initialConstruction, heldOutCount, maximumTotalDegree,
   solveImage, admitFollowerImage, imagesFor, canonicalFor,
   images = <||>, imageCache = <||>,
   exceptionalImages = {}, reference, referencePrime,
   normalizationColumns = Automatic, normalizationLocked = False,
   lockedSignature = Automatic, eliminationPlan = Missing["NotDiscovered"],
   eliminationPlanFailure = None, signature, signatures = {},
   interpolations = <||>,
   expectedDegrees = Automatic, expectedDegreeSampleCount = Automatic,
   perPrime, coordinateCount,
   combined, lifted, coefficientCheck, unseenCheck, epsilon, variables,
   vector, vectorFingerprint, installationEvidence, unpacked, residues,
   residuesKinematicsFree, exactVerification,
   exactGeneric = <|"Status" -> "ExactVerificationSkipped"|>,
   exactAtValues = <||>, pointwiseValidation = {}, validationSeconds = 0.,
   validationCandidates, validationResult, validationValue, liftAttempt,
   liftResult = <||>, liftSucceeded = False, goodPrimes = {},
   rejectedPrimes = {}, primeRejections = <||>, primeResult,
   primeSignatures, referenceSignature = Automatic, candidatePrime,
   unresolvedCoefficientLocations = {}, liftAttemptHistory = {},
   coefficientHeight = Missing["NotReconstructed"],
   coefficientHeightBitLength = Missing["NotReconstructed"],
   rationalReconstructionMinimumPrimeCount = Missing["NotReconstructed"],
   actualMinimumPrimeCount = Missing["NotReconstructed"],
   reconstructedCoefficients, coefficientHeights,
   crtSeconds = 0., crtTiming, liftAttempts = 0,
   degreeHistogram, sampleSeconds = 0., eliminationSeconds = 0.,
   interpolationSeconds = 0., liftSeconds = 0., verifySeconds = 0.,
   constrainedSolveCount = 0, fullSolveCount = 0, fallbackSolveCount = 0,
   imagePhaseRecords = {}, grew = 0, requestedPlanBackend,
   planBackendThreads, planBackendMinimumEntries, planBackendGate,
   imageKernelCountRequested, imageKernelCount = 1,
   followerNativeThreads,
   followerPayload = Automatic, followerAuthentication,
   followerWave, followerWaveRequests, followerWaveResults,
   followerWaveTimeout,
   followerWaveRecords = {}, followerParallelWaveCount = 0,
   followerSerialWaveCount = 0, followerParallelImageCount = 0,
   followerSerialImageCount = 0,
   suppliedPilotImages, suppliedPilotKeys, pilotAuthentication,
   pilotImageCache = <||>, reusedPilotImageCount = 0,
   reusedPilotKeys = {}, fullSolveCountedPilotKeys = {},
   structuralPilotEvidence = {}, structuralPilotPrimeCount = 0,
   structuralPilotRREFCount = 0, structuralPilotNewSampleCount = 0,
   structuralPilotNewRREFCount = 0, structuralPilotCacheHitCount = 0,
   structuralPilot, structuralPrime, structuralPrimeIndex,
   structuralValue, structuralValueIndex, structuralSample,
   structuralSolution, structuralKey, structuralSignature,
   structuralSamplingTiming, structuralEliminationTiming,
   structuralSignatures, structuralCandidatePrimes, structuralOrigin,
   modalStructuralCandidates, modalStructuralSignature = Automatic,
   modalReferenceEvidence, modalReferencePrime, modalReferenceValue,
   isolatedStructuralEvidence, structuralFailureDetails,
   structuralFailureStatuses, planDiscoveryTelemetry = <||>,
   inputsValidated, widePrimeSchedule},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripReconstructRegulator]]]];
  If[AssociationQ[gate], Return[gate]];
  inputsValidated = TrueQ[OptionValue["InputsValidated"]];
  If[! If[inputsValidated,
        Lookup[preparation, "Status", None] ===
            "PreparedMultiquadraticStripV1" &&
          multiquadraticStripAssemblyLayoutHotValidQ[layout] &&
          multiquadraticStripProviderHotValidQ[provider],
        multiquadraticStripPreparationValidQ[preparation] &&
          multiquadraticStripAssemblyLayoutValidQ[layout] &&
          multiquadraticStripProviderValidQ[provider]] ||
      layout["ABIFingerprint"] =!= preparation["ABIFingerprint"] ||
      layout["CoefficientABIFingerprint"] =!=
        provider["CoefficientABIFingerprint"],
    Return[multiquadraticStripFailure["InvalidReconstructionInput"]]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline|>]]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["[multiquadratic] reconstruct: ", items]];
  epsilon = preparation["Regulator"];
  variables = preparation["Variables"];
  widePrimeSchedule = If[
    OptionValue["SamplePrimes"] === Automatic ||
      OptionValue["PrimePool"] === Automatic,
    Block[{$multiquadraticStripTrustedProviderEvaluation = True},
      multiquadraticStripWidePrimeScheduleQ[provider]], False];
  primes = Replace[OptionValue["SamplePrimes"], Automatic :>
    If[widePrimeSchedule,
      $multiquadraticStripWideDefaultPrimes,
      $multiquadraticStripDefaultPrimes]];
  primePool = Replace[OptionValue["PrimePool"], Automatic :>
    DeleteDuplicates[Join[primes,
      If[widePrimeSchedule,
        $multiquadraticStripWidePrimePool,
        $multiquadraticStripPrimePool]]]];
  minimumGoodPrimeCount = Replace[OptionValue["MinimumGoodPrimeCount"],
    Automatic :> Length[primes]];
  maximumGoodPrimeCount = OptionValue["MaximumGoodPrimeCount"];
  maximumRejectedPrimeCount = OptionValue["MaximumRejectedPrimeCount"];
  unseenPrime = Replace[OptionValue["UnseenPrime"], Automatic :> 2147483323];
  unseenPrimeCount = OptionValue["UnseenPrimeCount"];
  freshPointwiseChecks = OptionValue["FreshPointwiseChecksPerPrime"];
  validationPrimes = Take[DeleteDuplicates[Join[{unseenPrime},
      $multiquadraticStripValidationPrimePool]], UpTo[unseenPrimeCount]];
  schedule = Replace[OptionValue["RegulatorValues"],
    Automatic :> $multiquadraticStripRegulatorScheduleDefault];
  maximumValues = Replace[OptionValue["MaximumRegulatorCount"],
    Automatic :> Length[schedule]];
  initialConstruction = OptionValue["InitialConstructionCount"];
  heldOutCount = OptionValue["HeldOutCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  randomSeed = OptionValue["RandomSeed"];
  normalizationColumns = OptionValue["NormalizationColumns"];
  requestedPlanBackend = OptionValue["PlanDiscoveryBackend"];
  planBackendThreads = OptionValue["PlanDiscoveryBackendThreads"];
  planBackendMinimumEntries = OptionValue[
    "PlanDiscoveryBackendMinimumEntries"];
  imageKernelCountRequested = OptionValue["ImageKernelCount"];
  If[! (imageKernelCountRequested === Automatic ||
        IntegerQ[imageKernelCountRequested] &&
          Between[imageKernelCountRequested, {1, 8}]),
    Return[multiquadraticStripFailure["InvalidImageKernelCount",
      <|"ImageKernelCount" -> imageKernelCountRequested|>]]];
  planBackendGate = multiquadraticStripPlanDiscoveryBackendDecision[
    requestedPlanBackend, planBackendThreads, {0, 0},
    planBackendMinimumEntries];
  If[Lookup[planBackendGate, "Status", None] =!= "OK",
    Return[planBackendGate]];
  imageKernelCount = multiquadraticStripFollowerImageKernelCount[
    imageKernelCountRequested, planBackendThreads];
  followerNativeThreads = planBackendThreads;
  suppliedPilotImages = OptionValue["PilotImages"];
  If[! MatchQ[suppliedPilotImages, {___Association}],
    Return[multiquadraticStripFailure["InvalidPilotImages"]]];
  suppliedPilotKeys = (Lookup[#1,
      {"Prime", "RegulatorValue"}, $Failed] &) /@ suppliedPilotImages;
  If[! DuplicateFreeQ[suppliedPilotKeys],
    Return[multiquadraticStripFailure["PilotImageAuthenticationFailed",
      <|"Reason" -> "DuplicatePilotImageKey",
        "PilotKeys" -> suppliedPilotKeys|>]]];
  pilotAuthentication = SelectFirst[
    multiquadraticStripPilotImageAuthenticate[#1, layout, provider] & /@
      suppliedPilotImages,
    Lookup[#1, "Status", None] =!=
      "AuthenticatedMultiquadraticPilotImageV1" &,
    Missing["NotFound"]];
  If[AssociationQ[pilotAuthentication], Return[pilotAuthentication]];
  Do[AssociateTo[pilotImageCache,
      Lookup[pilot, {"Prime", "RegulatorValue"}] -> pilot],
    {pilot, suppliedPilotImages}];
  exactVerification = Replace[OptionValue["ExactVerification"], Automatic :>
    If[provider["Kind"] === "CompiledChannel", True, "ProviderPoints"]];
  If[! VectorQ[primes, IntegerQ] || primes === {} ||
      ! VectorQ[primePool, IntegerQ] || primePool === {} ||
      ! AllTrue[Join[primePool, validationPrimes],
        PrimeQ[#1] && Mod[#1, 4] === 3 &&
          3 < #1 < $multiquadraticStripWordPrimeLimit &] ||
      ! DuplicateFreeQ[primePool] || ! DuplicateFreeQ[validationPrimes] ||
      ! ContainsAll[primePool, primes] ||
      Intersection[primePool, validationPrimes] =!= {} ||
      ! IntegerQ[minimumGoodPrimeCount] || minimumGoodPrimeCount < 1 ||
      ! IntegerQ[maximumGoodPrimeCount] ||
      maximumGoodPrimeCount < minimumGoodPrimeCount ||
      ! IntegerQ[maximumRejectedPrimeCount] || maximumRejectedPrimeCount < 0 ||
      ! IntegerQ[unseenPrimeCount] || unseenPrimeCount < 1 ||
      Length[validationPrimes] < unseenPrimeCount ||
      ! IntegerQ[freshPointwiseChecks] || freshPointwiseChecks < 1 ||
      ! ListQ[schedule] || ! DuplicateFreeQ[schedule] ||
      ! AllTrue[schedule, MatchQ[#1, _Integer | _Rational] &] ||
      ! IntegerQ[initialConstruction] || initialConstruction < 2 ||
      ! IntegerQ[heldOutCount] || heldOutCount < 1 ||
      ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0 ||
      ! IntegerQ[OptionValue["InitialRegulatorCount"]] ||
      ! IntegerQ[maximumValues] || maximumValues > Length[schedule] ||
      ! MemberQ[{True, False, "AtSampledValues", "ProviderPoints"},
        exactVerification],
    Return[multiquadraticStripFailure["InvalidReconstructionSchedule",
      <|"SamplePrimes" -> primes, "PrimePool" -> primePool,
        "UnseenPrimes" -> validationPrimes,
        "RegulatorValues" -> schedule|>]]];
  values = Take[schedule, UpTo[Max[OptionValue["InitialRegulatorCount"],
    initialConstruction + heldOutCount]]];
  If[Length[values] < initialConstruction + heldOutCount,
    Return[multiquadraticStripFailure["InsufficientRegulatorSchedule",
      <|"Required" -> initialConstruction + heldOutCount,
        "Available" -> Length[schedule]|>]]];
  (* The first accepted prime measures how many regulator fibres the adaptive
     fit actually consumed.  Later primes may start from that proven count;
     any exceptional prime grows only its own image list.  CRT combines the
     normalized interpolation coefficients and does not require identical
     regulator points or equal sample counts across primes. *)
  newPrimeRegulatorValues[] := Take[schedule, UpTo[Replace[
    learnedRegulatorSampleCount, Automatic :> Length[values]]]];
  admitFollowerImage[record_, request_Association, route_String] := Module[
    {result, key = Lookup[request, {"Prime", "RegulatorValue"}], kind},
    followerAuthentication =
      multiquadraticStripFollowerImageAuthenticate[record, followerPayload,
        request];
    If[Lookup[followerAuthentication, "Status", None] =!=
        "AuthenticatedMultiquadraticFollowerImageV1",
      result = <|"Status" -> "ReconstructionFollowerImageAuthenticationFailed",
        "Prime" -> request["Prime"],
        "RegulatorValue" -> request["RegulatorValue"],
        "Detail" -> followerAuthentication, "SamplingSeconds" -> 0.,
        "EliminationSeconds" -> 0., "SolvePath" -> route|>;
      AssociateTo[imageCache, key -> result]; Return[result]];
    result = Join[record["Result"], <|
      "FollowerExecutionRoute" -> route,
      "FollowerWorkerKernelID" -> record["WorkerKernelID"]|>];
    sampleSeconds += Lookup[result, "SamplingSeconds", 0.];
    eliminationSeconds += Lookup[result, "EliminationSeconds", 0.];
    If[StringStartsQ[route, "TaskBroker"], followerParallelImageCount++,
      followerSerialImageCount++];
    If[Lookup[result, "Status", None] === "OK",
      kind = Lookup[result, "FollowerSolveKind", None];
      If[kind === "Constrained", constrainedSolveCount++,
        If[kind === "FullAffineFallback",
          fallbackSolveCount++; fullSolveCount++]]];
    AppendTo[imagePhaseRecords, KeyTake[result,
      {"Prime", "RegulatorValue", "SamplingSeconds", "SamplePhaseSeconds",
       "EliminationSeconds", "SolvePath", "PlanFingerprint",
       "FollowerExecutionRoute", "FollowerWorkerKernelID",
       "ConstrainedSolveBackendUsed", "ConstrainedSolveBackendThreads",
       "ConstrainedSolveNativeValidationFailure",
       "ConstrainedSolveNativeValidationRecovered",
       "ConstrainedSolveFullResidualReplayCount",
       "ConstrainedSolveNativeCoreReplayCount",
       "FullResidualCheckMethod", "FullResidualExact",
       "FullResidualChecks", "PhaseSeconds"}]];
    AssociateTo[imageCache, key -> result];
    result];
  (* ---- one (prime, regulator) image.  Structural quorum below chooses the
     modal reference before this routine is allowed to discover the common
     affine section and constrained elimination plan.  Every later image uses
     that plan; an inapplicable core may fall back to a full solve only under
     the already locked section. *)
  solveImage[prime_, value_] := Module[
    {sample, solution, result, key = {prime, value}, samplingTiming,
      eliminationTiming = 0., canonical, discovered,
      discoveryTiming = 0., solvePath = None, planFingerprint = None,
      cachedPilot, pilotReused = False, request,
      independentRows = Automatic},
    If[KeyExistsQ[imageCache, key], Return[imageCache[key]]];
    (* Lookup treats a list key as a request for several scalar keys;
       provider image keys are themselves {prime, regulator} lists. *)
    cachedPilot = If[KeyExistsQ[pilotImageCache, key],
      pilotImageCache[key], None];
    If[AssociationQ[eliminationPlan] && ! AssociationQ[cachedPilot],
      If[! AssociationQ[followerPayload],
        followerPayload = multiquadraticStripFollowerImagePayload[layout,
          provider, eliminationPlan, pointCount, maximumAttempts, randomSeed,
          lockedSignature]];
      If[Lookup[followerPayload, "Status", None] ===
          "InvalidFollowerImagePayloadArguments",
        Return[followerPayload]];
      request = <|"Prime" -> prime, "RegulatorValue" -> value|>;
      Return[admitFollowerImage[
        multiquadraticStripFollowerImageSolve[followerPayload, request],
        request, "SerialFollower"]]];
    If[AssociationQ[cachedPilot],
      sample = cachedPilot["Sample"];
      solution = cachedPilot["Solution"];
      samplingTiming = 0.; pilotReused = True;
      If[! MemberQ[reusedPilotKeys, key],
        AppendTo[reusedPilotKeys, key]; reusedPilotImageCount++];
      If[! MemberQ[fullSolveCountedPilotKeys, key],
        AppendTo[fullSolveCountedPilotKeys, key]; fullSolveCount++],
      {samplingTiming, sample} = AbsoluteTiming[
        Block[{$multiquadraticStripTrustedProviderEvaluation = True,
            $multiquadraticStripTrustedLayoutEvaluation = True},
          multiquadraticStripAssembleSample[layout, provider, value, prime,
            "PointCount" -> pointCount, "MaximumAttempts" -> maximumAttempts,
            "RandomSeed" -> randomSeed]]]];
    sampleSeconds += samplingTiming;
    If[Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1",
      result = <|"Status" -> "ReconstructionSampleFailed", "Prime" -> prime,
        "RegulatorValue" -> value, "Detail" -> sample,
        "SamplingSeconds" -> samplingTiming, "EliminationSeconds" -> 0.|>;
      AssociateTo[imageCache, key -> result]; Return[result]];
    If[AssociationQ[eliminationPlan],
      If[pilotReused,
        If[{solution["Rank"], solution["Nullity"],
              solution["PivotSignature"]} =!= lockedSignature,
          result = <|"Status" -> "ReconstructionPlanSignatureMismatch",
            "Prime" -> prime, "RegulatorValue" -> value,
            "Expected" -> lockedSignature,
            "Observed" -> {solution["Rank"], solution["Nullity"],
              solution["PivotSignature"]}, "SamplingSeconds" -> 0.,
            "EliminationSeconds" -> 0.,
            "SolvePath" -> "ProviderSupportPilotRejected"|>;
          AssociateTo[imageCache, key -> result]; Return[result]];
        canonical = Quiet[NormalizeEpsFormAffineSample[
          <|"ParticularSolution" -> solution["ParticularSolution"],
            "NullspaceBasis" -> solution["NullspaceBasis"]|>,
          normalizationColumns, prime]];
        If[canonical === $Failed,
          result = <|"Status" -> "ReconstructionSectionSingular",
            "Prime" -> prime, "RegulatorValue" -> value,
            "NormalizationColumns" -> normalizationColumns,
            "SamplingSeconds" -> 0., "EliminationSeconds" -> 0.,
            "SolvePath" -> "ProviderSupportPilotRejected"|>;
          AssociateTo[imageCache, key -> result]; Return[result]];
        result = <|"Status" -> "OK", "Prime" -> prime,
          "RegulatorValue" -> value, "EpsilonMod" -> sample["EpsilonMod"],
          "ImageStoreKey" -> sample["ImageStoreKey"],
          "TrainingImageKeys" -> sample["TrainingImageKeys"],
          "SamplePhaseSeconds" -> sample["PhaseSeconds"],
          "Rank" -> solution["Rank"], "Nullity" -> solution["Nullity"],
          "PivotSignature" -> solution["PivotSignature"],
          "PivotColumns" -> solution["PivotColumns"],
          "FreeColumns" -> solution["FreeColumns"],
          "CanonicalValues" -> canonical["ParticularSolution"],
          "SolvePath" -> "ProviderSupportPilotReused",
          "PlanFingerprint" -> eliminationPlan["PlanFingerprint"],
          "PlanDiscoveryBackendRequested" -> Lookup[solution,
            "PlanDiscoveryBackendRequested", requestedPlanBackend],
          "PlanDiscoveryBackendUsed" -> Lookup[solution,
            "PlanDiscoveryBackendUsed", "Wolfram"],
          "PlanDiscoveryBackendThreads" -> Lookup[solution,
            "PlanDiscoveryBackendThreads", planBackendThreads],
          "FullResidualZero" -> True, "SamplingSeconds" -> 0.,
          "EliminationSeconds" -> 0.|>;
        AppendTo[imagePhaseRecords, KeyTake[result,
          {"Prime", "RegulatorValue", "SamplingSeconds", "SamplePhaseSeconds",
           "EliminationSeconds", "SolvePath", "PlanFingerprint",
           "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads"}]];
        AssociateTo[imageCache, key -> result]; Return[result]];
      (* Non-pilot followers returned through the pure seam above. *)
      Return[multiquadraticStripFailure[
        "UnexpectedFollowerImageControlFlow"]]];
    If[! pilotReused,
      {eliminationTiming, solution} = AbsoluteTiming[
        multiquadraticStripPlanDiscoverySolve[sample["Matrix"],
          sample["RightHandSide"], prime,
          preparation["GaugeUnknownCount"],
          preparation["ResidueUnknownCount"], requestedPlanBackend,
          planBackendThreads, planBackendMinimumEntries]],
      eliminationTiming = 0.];
    eliminationSeconds += eliminationTiming;
    If[! pilotReused, fullSolveCount++];
    If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution",
      result = <|"Status" -> "ReconstructionSolveFailed", "Prime" -> prime,
        "RegulatorValue" -> value, "Detail" -> solution,
        "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming,
        "SolvePath" -> "FullAffinePilotOrPlanUnavailable",
        "PlanDiscoveryBackendRequested" -> requestedPlanBackend,
        "PlanDiscoveryBackendUsed" -> Lookup[solution,
          "PlanDiscoveryBackendUsed", None]|>;
      AppendTo[imagePhaseRecords, KeyTake[result,
        {"Prime", "RegulatorValue", "SamplingSeconds", "SamplePhaseSeconds",
         "EliminationSeconds", "SolvePath"}]];
      AssociateTo[imageCache, key -> result]; Return[result]];
    If[! normalizationLocked,
      normalizationColumns = Replace[normalizationColumns,
        Automatic :> If[solution["Nullity"] === 0, {},
          If[Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
              "FLINTAffineRREF",
            solution["NativeNormalizationColumns"],
            finiteFieldStripNormalizationColumns[Normal[
              solution["NullspaceBasis"]], preparation["GaugeUnknownCount"],
              preparation["ResidueUnknownCount"], prime]]]];
      If[! VectorQ[normalizationColumns, IntegerQ] ||
          Length[normalizationColumns] =!= solution["Nullity"] ||
          ! DuplicateFreeQ[normalizationColumns] ||
          ! AllTrue[normalizationColumns,
            1 <= #1 <= preparation["UnknownCount"] &],
        result = <|"Status" -> "ReconstructionSectionInvalid",
          "Prime" -> prime, "RegulatorValue" -> value,
          "Nullity" -> solution["Nullity"],
          "NormalizationColumns" -> normalizationColumns,
          "SamplingSeconds" -> samplingTiming,
          "EliminationSeconds" -> eliminationTiming|>;
        AssociateTo[imageCache, key -> result]; Return[result]];
      normalizationLocked = True;
      lockedSignature = {solution["Rank"], solution["Nullity"],
        solution["PivotSignature"]};
      planDiscoveryTelemetry = KeyTake[solution, {
        "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
        "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
        "PlanDiscoveryBackendFallbackReason", "PlanDiscoveryBackendSeconds",
        "MatrixEntries", "NativeMinimumMatrixEntries"}];
      independentRows = If[
        Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
          "FLINTAffineRREF", solution["IndependentEquationRows"], Automatic];
      {discoveryTiming, discovered} = AbsoluteTiming[
        multiquadraticStripConstrainedPlanDiscover[sample["Matrix"],
          sample["RightHandSide"], solution, normalizationColumns, prime,
          layout["LayoutFingerprint"], provider["ProviderFingerprint"],
          independentRows]];
      eliminationSeconds += discoveryTiming;
      eliminationTiming += discoveryTiming;
      If[Lookup[discovered, "Status", None] ===
          "MultiquadraticConstrainedAffinePlanV1",
        eliminationPlan = discovered;
        planFingerprint = discovered["PlanFingerprint"],
        eliminationPlanFailure = discovered;
        eliminationPlan = Missing["PlanUnavailable"]]];
    If[lockedSignature =!= Automatic &&
        {solution["Rank"], solution["Nullity"],
          solution["PivotSignature"]} =!= lockedSignature,
      result = <|"Status" -> "ReconstructionPlanSignatureMismatch",
        "Prime" -> prime, "RegulatorValue" -> value,
        "Expected" -> lockedSignature,
        "Observed" -> {solution["Rank"], solution["Nullity"],
          solution["PivotSignature"]}, "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming|>;
      AssociateTo[imageCache, key -> result]; Return[result]];
    canonical = Quiet[NormalizeEpsFormAffineSample[
      <|"ParticularSolution" -> solution["ParticularSolution"],
        "NullspaceBasis" -> solution["NullspaceBasis"]|>,
      normalizationColumns, prime]];
    If[canonical === $Failed,
      result = <|"Status" -> "ReconstructionSectionSingular",
        "Prime" -> prime, "RegulatorValue" -> value,
        "NormalizationColumns" -> normalizationColumns,
        "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming|>;
      AssociateTo[imageCache, key -> result]; Return[result]];
    solvePath = If[AssociationQ[eliminationPlan],
      If[pilotReused, "ProviderSupportPilotAndPlanDiscoveryReused",
        "FullAffinePilotAndPlanDiscovery"], "FullAffinePlanUnavailable"];
    result = <|"Status" -> "OK", "Prime" -> prime,
      "RegulatorValue" -> value, "EpsilonMod" -> sample["EpsilonMod"],
      "ImageStoreKey" -> sample["ImageStoreKey"],
      "TrainingImageKeys" -> sample["TrainingImageKeys"],
      "SamplePhaseSeconds" -> sample["PhaseSeconds"],
      "Rank" -> solution["Rank"], "Nullity" -> solution["Nullity"],
      "PivotSignature" -> solution["PivotSignature"],
      "PivotColumns" -> solution["PivotColumns"],
      "FreeColumns" -> solution["FreeColumns"],
      "ParticularSolution" -> solution["ParticularSolution"],
      "NullspaceBasis" -> solution["NullspaceBasis"],
      "CanonicalValues" -> canonical["ParticularSolution"],
      "SolvePath" -> solvePath,
      "PlanFingerprint" -> If[AssociationQ[eliminationPlan],
        eliminationPlan["PlanFingerprint"], None],
      "PlanDiscoveryBackendRequested" -> Lookup[solution,
        "PlanDiscoveryBackendRequested", requestedPlanBackend],
      "PlanDiscoveryBackendUsed" -> Lookup[solution,
        "PlanDiscoveryBackendUsed", "Wolfram"],
      "PlanDiscoveryBackendThreads" -> Lookup[solution,
        "PlanDiscoveryBackendThreads", planBackendThreads],
      "FullResidualZero" -> True, "SamplingSeconds" -> samplingTiming,
      "EliminationSeconds" -> eliminationTiming|>;
    AppendTo[imagePhaseRecords, KeyTake[result,
      {"Prime", "RegulatorValue", "SamplingSeconds", "SamplePhaseSeconds",
       "EliminationSeconds",
       "SolvePath", "PlanFingerprint"}]];
    AssociateTo[imageCache, key -> result];
    result];
  imagesFor[prime_, valueList_] := Module[
    {result = {}, candidateValues, image, requested = Length[valueList],
     candidateIndex = 1, value, nextValues, nextKeys, waveRoute, waveWidth,
     recordImage},
    recordImage[current_, currentValue_] :=
      If[Lookup[current, "Status", None] === "OK",
        AppendTo[result, current],
        AppendTo[exceptionalImages, <|"Prime" -> prime,
          "RegulatorValue" -> currentValue,
          "Reason" -> Lookup[current, "Status", None],
          "Detail" -> KeyDrop[current, {"Detail"}]|>]];
    candidateValues = Take[DeleteDuplicates[Join[valueList, schedule]],
      UpTo[maximumValues]];
    While[Length[result] < requested &&
        candidateIndex <= Length[candidateValues],
      value = candidateValues[[candidateIndex]];
      If[multiquadraticStripDeadlineExpiredQ[deadline],
        Return[multiquadraticStripBudgetExhausted["RegulatorReconstruction",
          AbsoluteTime[] - startTime, deadline,
          <|"Prime" -> prime, "RegulatorValue" -> value|>], Module]];
      (* Consecutive uncached, non-pilot followers enter one bounded wave.
         Cached pilots remain on the main kernel, and results are admitted in
         regulator schedule order regardless of completion order. *)
      imageKernelCount = multiquadraticStripFollowerImageKernelCount[
        imageKernelCountRequested,
        If[AssociationQ[eliminationPlan],
          Lookup[eliminationPlan, "PlanDiscoveryBackendThreads",
            planBackendThreads], planBackendThreads]];
      If[imageKernelCount >= 2 && AssociationQ[eliminationPlan] &&
          requested - Length[result] >= 2 &&
          candidateIndex < Length[candidateValues],
        waveWidth = Min[imageKernelCount, requested - Length[result],
          Length[candidateValues] - candidateIndex + 1];
        nextValues = candidateValues[[
          candidateIndex ;; candidateIndex + waveWidth - 1]];
        nextKeys = {prime, #1} & /@ nextValues;
        If[AllTrue[nextKeys, ! KeyExistsQ[imageCache, #1] &&
              ! KeyExistsQ[pilotImageCache, #1] &],
          If[! AssociationQ[followerPayload],
            followerPayload = multiquadraticStripFollowerImagePayload[layout,
              provider, eliminationPlan, pointCount, maximumAttempts,
              randomSeed, lockedSignature]];
          If[AssociationQ[followerPayload] &&
              Lookup[followerPayload, "Schema", None] ===
                "MultiquadraticFollowerImagePayloadV1",
            followerWaveRequests = (<|"Prime" -> prime,
                "RegulatorValue" -> #1|> &) /@ nextValues;
            followerWaveTimeout = If[deadline === Infinity, 1800,
              Max[1, Min[1800, Ceiling[deadline - AbsoluteTime[]]]]];
            followerWave = multiquadraticStripFollowerImageWave[
              followerPayload, followerWaveRequests, imageKernelCount,
              followerWaveTimeout, deadline];
            If[Lookup[followerWave, "Status", None] === "BudgetExhausted",
              Return[followerWave, Module]];
            If[Lookup[followerWave, "Status", None] ===
                "MultiquadraticFollowerImageWaveV1" &&
                Length[Lookup[followerWave, "Results", {}]] === waveWidth &&
                Length[Lookup[followerWave, "ResultRoutes", {}]] ===
                  waveWidth,
              waveRoute = followerWave["Route"];
              If[StringStartsQ[waveRoute, "TaskBroker"],
                followerParallelWaveCount++, followerSerialWaveCount++];
              AppendTo[followerWaveRecords, KeyTake[followerWave,
                {"Route", "Concurrency", "RequestedConcurrency",
                 "BatchSize", "BrokerHelperCount",
                 "FallbackIndices", "ResultRoutes", "Timeout", "Seconds"}]];
              followerWaveResults = MapThread[
                admitFollowerImage,
                {followerWave["Results"], followerWaveRequests,
                 followerWave["ResultRoutes"]}];
              MapThread[recordImage, {followerWaveResults, nextValues}];
              candidateIndex += waveWidth; Continue[]]]]];
      image = solveImage[prime, value];
      recordImage[image, value];
      candidateIndex++];
    If[Length[result] < requested,
      multiquadraticStripFailure["ExceptionalRegulatorImagesExhausted",
        <|"Prime" -> prime, "RequestedImageCount" -> requested,
          "UsableImageCount" -> Length[result],
          "MaximumRegulatorCount" -> maximumValues|>],
      result]];
  (* A structural image is evidence about a prime, not authority to choose
     the affine section.  Inspect at most three distinct primes and require a
     two-vote signature before normalization, nullity, pivots, or the
     constrained plan are locked.  Supplied support-ladder pilots enter the
     same cache and are never sampled or row-reduced again. *)
  structuralCandidatePrimes = DeleteDuplicates[Join[
    Lookup[suppliedPilotImages, "Prime", {}], primePool]];
  Do[
    structuralPrime = structuralCandidatePrimes[[structuralPrimeIndex]];
    structuralPilotPrimeCount++;
    structuralPilot = SelectFirst[suppliedPilotImages,
      Lookup[#1, "Prime", None] === structuralPrime &, None];
    If[AssociationQ[structuralPilot],
      structuralOrigin = "PilotImages";
      structuralPilotCacheHitCount++,
      structuralOrigin = "Discovered";
      structuralPilot = None;
      Do[
        structuralValue = values[[structuralValueIndex]];
        structuralKey = {structuralPrime, structuralValue};
        {structuralSamplingTiming, structuralSample} = AbsoluteTiming[
          Block[{$multiquadraticStripTrustedProviderEvaluation = True,
              $multiquadraticStripTrustedLayoutEvaluation = True},
            multiquadraticStripAssembleSample[layout, provider,
              structuralValue, structuralPrime,
              "PointCount" -> pointCount,
              "MaximumAttempts" -> maximumAttempts,
              "RandomSeed" -> randomSeed +
                7919 structuralPrimeIndex + 101 structuralValueIndex]]];
        sampleSeconds += structuralSamplingTiming;
        structuralPilotNewSampleCount++;
        If[Lookup[structuralSample, "Status", None] =!=
            "AssembledMultiquadraticSampleV1",
          (* The dense-matrix admission bound depends only on this ansatz's
             row/column counts.  Trying another prime or regulator cannot
             turn an over-cap lower bound into an admissible sample, and zero
             attempted RREFs must not be reported as unstable mathematics. *)
          If[Lookup[structuralSample, "Status", None] ===
              "SampleMatrixResourceLimit",
            Return[Join[structuralSample, <|
              "Stage" -> "StructuralPilotSampling",
              "Prime" -> structuralPrime,
              "RegulatorValue" -> structuralValue|>], Module]];
          AppendTo[exceptionalImages, <|"Prime" -> structuralPrime,
            "RegulatorValue" -> structuralValue,
            "Reason" -> "StructuralPilotSampleFailed",
            "Detail" -> structuralSample|>];
          Continue[]];
        {structuralEliminationTiming, structuralSolution} = AbsoluteTiming[
          multiquadraticStripPlanDiscoverySolve[
            structuralSample["Matrix"],
            structuralSample["RightHandSide"], structuralPrime,
            preparation["GaugeUnknownCount"],
            preparation["ResidueUnknownCount"], requestedPlanBackend,
            planBackendThreads, planBackendMinimumEntries]];
        eliminationSeconds += structuralEliminationTiming;
        structuralPilotRREFCount++; structuralPilotNewRREFCount++;
        fullSolveCount++;
        If[Lookup[structuralSolution, "Status", None] =!=
            "MultiquadraticAffineSolution",
          AppendTo[exceptionalImages, <|"Prime" -> structuralPrime,
            "RegulatorValue" -> structuralValue,
            "Reason" -> "StructuralPilotSolveFailed",
            "Detail" -> structuralSolution|>];
          Continue[]];
        structuralPilot = multiquadraticStripPilotImageRecord[
          structuralPrime, structuralValue, structuralSample,
          structuralSolution];
        (* This sample and affine solution were produced in this call.  The
           native discovery path has already replayed the particular and
           every nullspace vector on all original rows; redoing the same
           dense matrix products through pilot cache admission is duplicate
           work.  Only externally supplied pilots use the admission replay. *)
        If[! AssociationQ[structuralPilot],
          AppendTo[exceptionalImages, <|"Prime" -> structuralPrime,
            "RegulatorValue" -> structuralValue,
            "Reason" -> "StructuralPilotRecordFailed"|>];
          structuralPilot = None;
          Continue[]];
        AssociateTo[pilotImageCache, structuralKey -> structuralPilot];
        AppendTo[fullSolveCountedPilotKeys, structuralKey];
        Break[],
        {structuralValueIndex, Length[values]}]];
    If[! AssociationQ[structuralPilot],
      AppendTo[structuralPilotEvidence, <|"Prime" -> structuralPrime,
        "Status" -> "NoUsableStructuralPilot"|>];
      AppendTo[rejectedPrimes, structuralPrime];
      AssociateTo[primeRejections, structuralPrime ->
        <|"Status" -> "NoUsableStructuralPilot"|>];
      Continue[]];
    structuralKey = Lookup[structuralPilot,
      {"Prime", "RegulatorValue"}];
    structuralSolution = structuralPilot["Solution"];
    If[structuralOrigin === "PilotImages",
      structuralPilotRREFCount++;
      If[! MemberQ[fullSolveCountedPilotKeys, structuralKey],
        AppendTo[fullSolveCountedPilotKeys, structuralKey];
        fullSolveCount++]];
    If[! MemberQ[reusedPilotKeys, structuralKey],
      AppendTo[reusedPilotKeys, structuralKey]; reusedPilotImageCount++];
    structuralSignature = {structuralSolution["Rank"],
      structuralSolution["Nullity"],
      structuralSolution["PivotSignature"]};
    AppendTo[structuralPilotEvidence, <|
      "Status" -> "StructuralPilotSignature", "Prime" -> structuralPrime,
      "RegulatorValue" -> structuralPilot["RegulatorValue"],
      "Signature" -> structuralSignature, "Origin" -> structuralOrigin,
      "PlanDiscoveryBackendRequested" -> Lookup[structuralSolution,
        "PlanDiscoveryBackendRequested", requestedPlanBackend],
      "PlanDiscoveryBackendUsed" -> Lookup[structuralSolution,
        "PlanDiscoveryBackendUsed", Missing["NotRecorded"]],
      "PlanDiscoveryBackendThreads" -> Lookup[structuralSolution,
        "PlanDiscoveryBackendThreads", planBackendThreads]|>];
    structuralSignatures = Lookup[Select[structuralPilotEvidence,
      Lookup[#1, "Status", None] === "StructuralPilotSignature" &],
      "Signature", {}];
    modalStructuralCandidates = Select[
      DeleteDuplicates[structuralSignatures],
      Count[structuralSignatures, #1] >= 2 &];
    If[modalStructuralCandidates =!= {},
      modalStructuralSignature = First[modalStructuralCandidates]; Break[]],
    {structuralPrimeIndex, Min[3, Length[structuralCandidatePrimes]]}];
  If[modalStructuralSignature === Automatic,
    structuralSignatures = Lookup[Select[structuralPilotEvidence,
      Lookup[#1, "Status", None] === "StructuralPilotSignature" &],
      "Signature", {}];
    If[structuralSignatures === {},
      structuralFailureDetails = Cases[exceptionalImages,
        item_Association /; MemberQ[
          {"StructuralPilotSampleFailed", "StructuralPilotSolveFailed"},
          Lookup[item, "Reason", None]] :> Lookup[item, "Detail", Nothing]];
      structuralFailureStatuses = Lookup[structuralFailureDetails,
        "Status", Missing["Status"]];
      If[structuralFailureDetails =!= {} &&
          Length[DeleteDuplicates[structuralFailureStatuses]] === 1,
        Return[Join[First[structuralFailureDetails], <|
          "Stage" -> "StructuralPilot",
          "StructuralPilotEvidence" -> structuralPilotEvidence|>]]];
      Return[multiquadraticStripFailure["StructuralPilotUnavailable",
        <|"StructuralPilotEvidence" -> structuralPilotEvidence,
          "ExceptionalRegulatorImages" -> exceptionalImages|>]]];
    If[Length[structuralSignatures] === 1,
      Return[multiquadraticStripFailure["StructuralPilotQuorumUnavailable",
        <|"StructuralPilotEvidence" -> structuralPilotEvidence,
          "UsableStructuralPilotCount" -> 1,
          "RequiredAgreementCount" -> 2,
          "ExceptionalRegulatorImages" -> exceptionalImages|>]]];
    Return[multiquadraticStripFailure["ModularStructureUnstable",
      <|"StructuralPilotEvidence" -> structuralPilotEvidence,
        "DistinctPrimeCount" -> structuralPilotPrimeCount,
        "MaximumDistinctPrimeCount" -> 3,
        "RequiredAgreementCount" -> 2,
        "StructuralPilotRREFCount" -> structuralPilotRREFCount,
        "StructuralPilotNewSampleCount" -> structuralPilotNewSampleCount,
        "StructuralPilotNewFullAffineSolveCount" ->
          structuralPilotNewRREFCount,
        "StructuralPilotCacheHitCount" -> structuralPilotCacheHitCount,
        "ReusedPilotImageCount" -> reusedPilotImageCount,
        "FullAffineSolveCount" -> fullSolveCount,
        "PlanDiscoveryBackendRequested" -> requestedPlanBackend,
        "PlanDiscoveryBackendThreads" -> planBackendThreads|>]]];
  modalReferenceEvidence = SelectFirst[structuralPilotEvidence,
    Lookup[#1, "Signature", None] === modalStructuralSignature &, None];
  modalReferencePrime = modalReferenceEvidence["Prime"];
  modalReferenceValue = modalReferenceEvidence["RegulatorValue"];
  isolatedStructuralEvidence = Select[structuralPilotEvidence,
    Lookup[#1, "Status", None] === "StructuralPilotSignature" &&
      Lookup[#1, "Signature", None] =!= modalStructuralSignature &];
  Do[
    If[! MemberQ[rejectedPrimes, evidence["Prime"]],
      AppendTo[rejectedPrimes, evidence["Prime"]]];
    AssociateTo[primeRejections, evidence["Prime"] -> <|
      "Status" -> "NonmodalModularStructure",
      "Signature" -> evidence["Signature"],
      "ModalSignature" -> modalStructuralSignature,
      "RegulatorValue" -> evidence["RegulatorValue"]|>];
    AppendTo[exceptionalImages, <|"Prime" -> evidence["Prime"],
      "RegulatorValue" -> evidence["RegulatorValue"],
      "Reason" -> "NonmodalModularStructure",
      "Observed" -> evidence["Signature"],
      "Modal" -> modalStructuralSignature|>],
    {evidence, isolatedStructuralEvidence}];
  (* A support-ladder pilot may deliberately use the cheap historical
     31-bit discovery pool while reconstruction uses wide CRT primes.  Such a
     pilot fixes the common section and constrained plan, but must not mutate
     the requested reconstruction-prime schedule.  A modal prime already in
     that schedule still moves to the front as before. *)
  If[MemberQ[primePool, modalReferencePrime],
    primePool = DeleteDuplicates[Join[{modalReferencePrime}, primePool]]];
  referenceSignature = modalStructuralSignature;
  (* Consume the modal cached response as the one existing discovery image.
     This discovers the common normalization and constrained plan without a
     second RREF, even when the chosen pilot came from the support ladder. *)
  reference = solveImage[modalReferencePrime, modalReferenceValue];
  If[Lookup[reference, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure[
      "ModalStructuralReferenceRejected",
      <|"Prime" -> modalReferencePrime,
        "RegulatorValue" -> modalReferenceValue,
        "ModalSignature" -> modalStructuralSignature,
        "Detail" -> reference|>]]];
  (* ---- the SECTION, chosen once from the reference image and reused at
     every regulator value and every prime *)
  referencePrime = Missing["NoUsableReferencePrime"];
  Do[
    images[candidatePrime] = imagesFor[candidatePrime, values];
    If[Lookup[images[candidatePrime], "Status", None] ===
        "BudgetExhausted", Return[images[candidatePrime], Module]];
    If[ListQ[images[candidatePrime]], referencePrime = candidatePrime; Break[],
      AppendTo[rejectedPrimes, candidatePrime];
      AssociateTo[primeRejections, candidatePrime ->
        Lookup[images[candidatePrime], "Status", "ReferenceImageFailed"]]];
    If[Length[rejectedPrimes] > maximumRejectedPrimeCount, Break[]],
    {candidatePrime, primePool}];
  If[! IntegerQ[referencePrime],
    Return[multiquadraticStripFailure["ReconstructionPrimePoolExhausted",
      <|"Stage" -> "ReferenceImage", "RejectedPrimes" -> rejectedPrimes,
        "PrimeRejections" -> primeRejections|>]]];
  reference = First[images[referencePrime]];
  If[! TrueQ[normalizationLocked] ||
      ! VectorQ[normalizationColumns, IntegerQ] ||
      Length[normalizationColumns] =!= reference["Nullity"] ||
      ! AllTrue[normalizationColumns,
        1 <= #1 <= preparation["UnknownCount"] &],
    Return[multiquadraticStripFailure["ReconstructionSectionInvalid",
      <|"Nullity" -> reference["Nullity"],
        "NormalizationColumns" -> normalizationColumns|>]]];
  log["affine section: nullity ", reference["Nullity"],
    ", normalization columns ", normalizationColumns];
  canonicalFor[prime_, imageList_] := Module[{normalized},
    normalized = Table[
      If[ListQ[Lookup[image, "CanonicalValues", None]] &&
          Length[image["CanonicalValues"]] === preparation["UnknownCount"],
          <|"EpsilonValue" -> image["RegulatorValue"],
            "EpsilonMod" -> image["EpsilonMod"],
            "Values" -> image["CanonicalValues"]|>,
        Module[{canonical = Quiet[NormalizeEpsFormAffineSample[
            <|"ParticularSolution" -> image["ParticularSolution"],
              "NullspaceBasis" -> image["NullspaceBasis"]|>,
            normalizationColumns, prime]]},
          If[canonical === $Failed, $Failed,
            <|"EpsilonValue" -> image["RegulatorValue"],
              "EpsilonMod" -> image["EpsilonMod"],
              "Values" -> canonical["ParticularSolution"]|>]]],
      {image, imageList}];
    If[MemberQ[normalized, $Failed], $Failed, normalized]];
  (* ---- every prime, with adaptive growth of the regulator schedule *)
  perPrime[prime_] := Module[
    {imageList, canonical, result, timing, requestedCount,
     additionalCount},
    imageList = If[KeyExistsQ[images, prime], images[prime],
      images[prime] = imagesFor[prime, newPrimeRegulatorValues[]]];
    If[! ListQ[imageList], Return[imageList]];
    requestedCount = Length[imageList];
    While[True,
      canonical = canonicalFor[prime, imageList];
      If[canonical === $Failed,
        Return[multiquadraticStripFailure["ReconstructionSectionSingular",
          <|"Prime" -> prime,
            "NormalizationColumns" -> normalizationColumns|>], Module]];
      timing = AbsoluteTiming[
        finiteFieldStripHeldOutInterpolate[canonical, prime,
          "InitialConstructionCount" -> initialConstruction,
          "HeldOutCount" -> heldOutCount,
          "MaximumTotalDegree" -> maximumTotalDegree,
          "ExpectedDegrees" -> expectedDegrees]];
      interpolationSeconds += timing[[1]];
      result = timing[[2]];
      If[Lookup[result, "Status", None] === "HeldOutValidated",
        Return[result, Module]];
      If[Lookup[result, "Status", None] ===
          "MaximumTotalDegreeExceeded",
        Return[multiquadraticStripFailure[
          "RegulatorMaximumTotalDegreeExceeded",
          <|"Prime" -> prime, "Detail" -> result|>], Module]];
      If[Lookup[result, "Status", None] =!= "MoreSamplesRequired",
        Return[multiquadraticStripFailure["RegulatorInterpolationFailed",
          <|"Prime" -> prime, "Detail" -> result|>], Module]];
      log["prime ", prime, ": interpolation at ", requestedCount,
        " images requests ", Lookup[result,
          "RequiredAdditionalSampleCount", 1], " more (",
        Lookup[result, "Reason", "Unknown"], "), consumed/constructed ",
        Lookup[result, "ConsumedSampleCount", Missing["Unavailable"]], "/",
        Lookup[result, "ConstructionCount", Missing["Unavailable"]],
        ", backend threads ", Lookup[result, "InterpolationBackendThreads",
          Missing["Unavailable"]], ", coordinate statuses ",
        Lookup[result, "CoordinateStatusHistogram", Missing["Unavailable"]]];
      (* A failed held-out becomes construction data for THIS prime.  Earlier
         accepted interpolants have already passed their own disjoint held-out
         checks and are not backfilled merely to share a regulator schedule. *)
      If[requestedCount >= maximumValues,
        Return[multiquadraticStripFailure["RegulatorScheduleExhausted",
          <|"Prime" -> prime, "RegulatorValueCount" -> requestedCount,
            "MaximumRegulatorCount" -> maximumValues,
            "Detail" -> result|>], Module]];
      grew++;
      additionalCount = Max[1, Lookup[result,
        "RequiredAdditionalSampleCount", 1]];
      requestedCount = Min[maximumValues,
        requestedCount + additionalCount];
      images[prime] = imagesFor[prime,
        Take[schedule, UpTo[requestedCount]]];
      If[Lookup[images[prime], "Status", None] === "BudgetExhausted",
        Return[images[prime], Module]];
      If[! ListQ[images[prime]], Return[images[prime], Module]];
      imageList = images[prime]]];
  (* Prime interpolation is accumulated below together with adaptive CRT.
     A bad prime is evidence about that image only and is recorded, never
     promoted to a gauge/alphabet obstruction. *)
  (* Adaptive CRT/lift.  Provider images and regulator interpolants are
     retained when a prime is added; the small coefficientwise CRT combine
     is rebuilt over the accepted primes.  Do not call that combine
     incremental unless an integrated profile justifies another state ABI. *)
  liftAttempt[acceptedPrimes_List] := Module[
    {localCombined, localLifted, localCoefficientCheck, localLiftSeconds,
     localVector, localVectorFingerprint, localUnpacked, localResidues,
     localValidation,
     localValidationSeconds, localValidationCandidates,
     localValidationResult, localValidationValue,
     modulus = Times @@ acceptedPrimes},
    coordinateCount = preparation["UnknownCount"];
    (* A later non-height failure must not inherit locations from an earlier
       failed prefix.  Preserve complete Position paths; flattening them
       destroys the coordinate/part/coefficient distinction. *)
    unresolvedCoefficientLocations = {};
    If[AnyTrue[acceptedPrimes,
        Length[interpolations[#1]["Interpolations"]] =!= coordinateCount &],
      Return[multiquadraticStripFailure[
        "ReconstructionCoordinateCountMismatch"], Module]];
    {crtTiming, localCombined} = AbsoluteTiming[Table[
      epsFormFiniteFieldCombineCoordinate[
        Table[interpolations[p]["Interpolations"][[coordinate]],
          {p, acceptedPrimes}], acceptedPrimes],
      {coordinate, coordinateCount}]];
    crtSeconds += crtTiming;
    If[MemberQ[localCombined, $Failed],
      Return[multiquadraticStripFailure[
        "RegulatorDegreeProfileDisagrees",
        <|"Primes" -> acceptedPrimes|>], Module]];
    {localLiftSeconds, localLifted} = AbsoluteTiming[Table[<|
      "NumeratorCoefficients" ->
        (epsFormFiniteFieldRationalReconstruct[#1, modulus] & /@
          localCombined[[coordinate]]["Numerator"]),
      "DenominatorCoefficients" ->
        (epsFormFiniteFieldRationalReconstruct[#1, modulus] & /@
          localCombined[[coordinate]]["Denominator"])|>,
      {coordinate, coordinateCount}]];
    liftSeconds += localLiftSeconds;
    If[! FreeQ[localLifted, $Failed],
      unresolvedCoefficientLocations = Position[localLifted, $Failed,
        Infinity, Heads -> False];
      Return[multiquadraticStripFailure[
        "RationalReconstructionHeightUnresolved",
        <|"Modulus" -> modulus,
          "ModulusBitLength" -> IntegerLength[modulus, 2],
          "UnresolvedCoefficientCount" ->
            Length[unresolvedCoefficientLocations],
          "UnresolvedCoefficientLocations" ->
            unresolvedCoefficientLocations|>],
        Module]];
    localCoefficientCheck = AllTrue[Range[coordinateCount],
      Function[coordinate, AllTrue[acceptedPrimes, Function[p,
        AllTrue[Transpose[{localCombined[[coordinate]]["Numerator"],
            localLifted[[coordinate]]["NumeratorCoefficients"]}],
          epsFormFiniteFieldImageQ[#1[[1]], #1[[2]], p] &] &&
        AllTrue[Transpose[{localCombined[[coordinate]]["Denominator"],
            localLifted[[coordinate]]["DenominatorCoefficients"]}],
          epsFormFiniteFieldImageQ[#1[[1]], #1[[2]], p] &]]]]];
    If[! TrueQ[localCoefficientCheck],
      Return[multiquadraticStripFailure[
        "RegulatorCoefficientImageMismatch"], Module]];
    localVector = Table[With[{
        numerator = localLifted[[coordinate]]["NumeratorCoefficients"],
        denominator = localLifted[[coordinate]]["DenominatorCoefficients"]},
      Together[Total[numerator epsilon^Range[0, Length[numerator] - 1]]/
        Total[denominator epsilon^Range[0, Length[denominator] - 1]]]],
      {coordinate, coordinateCount}];
    If[! FreeQ[localVector, DirectedInfinity | Indeterminate],
      Return[multiquadraticStripFailure[
        "ReconstructedVectorSingular"], Module]];
    localVectorFingerprint =
      multiquadraticStripReconstructedVectorFingerprint[localVector,
        layout["LayoutFingerprint"], provider["ProviderFingerprint"]];
    If[! StringQ[localVectorFingerprint],
      Return[multiquadraticStripFailure[
        "ReconstructedVectorFingerprintFailed"], Module]];
    localUnpacked = multiquadraticStripUnpackVector[preparation, localVector];
    If[Lookup[localUnpacked, "Status", None] =!=
        "UnpackedMultiquadraticSolution", Return[localUnpacked, Module]];
    localResidues = localUnpacked["Residues"];
    If[! TrueQ[FreeQ[localResidues, Alternatives @@ variables]],
      Return[multiquadraticStripFailure[
        "ReconstructedResiduesCarryKinematics",
        <|"Variables" -> variables|>], Module]];
    localValidationCandidates = Complement[schedule,
      DeleteDuplicates[Lookup[Flatten[Lookup[images, acceptedPrimes]],
        "RegulatorValue", {}]]];
    If[Length[localValidationCandidates] < freshPointwiseChecks,
      localValidationCandidates = Join[localValidationCandidates,
        Select[Range[33, 33 + 4 freshPointwiseChecks],
          FreeQ[schedule, #1] &]]];
    {localValidationSeconds, localValidation} = AbsoluteTiming[Flatten[Table[
      localValidationResult = Missing["NoUsableValidationImage"];
      Do[
        localValidationValue = localValidationCandidates[[1 + Mod[
          (primeIndex - 1) freshPointwiseChecks + checkIndex + attempt - 3,
          Length[localValidationCandidates]]]];
        localValidationResult = Block[{
            $multiquadraticStripTrustedProviderEvaluation = True,
            $multiquadraticStripTrustedLayoutEvaluation = True},
          multiquadraticStripProviderResidualImage[
            layout, provider, localVector, epsilon, localValidationValue,
            validationPrimes[[primeIndex]], "PointCount" -> 1,
            "MaximumAttempts" -> maximumAttempts,
            "RandomSeed" -> randomSeed + 1000003 primeIndex +
              1009 checkIndex + attempt, "SplitPointsOnly" -> True]];
        If[AssociationQ[localValidationResult],
          localValidationResult = Join[localValidationResult,
            <|"ReconstructedVectorFingerprint" ->
              localVectorFingerprint|>]];
        If[MemberQ[{"ProviderPointwiseResidualZero",
            "ProviderPointwiseResidualNonzero"},
            Lookup[localValidationResult, "Status", None]], Break[]],
        {attempt, 1, 6}];
      If[Lookup[localValidationResult, "Status", None] =!=
          "ProviderPointwiseResidualZero",
        Return[multiquadraticStripFailure[
          If[Lookup[localValidationResult, "Status", None] ===
              "ProviderPointwiseResidualNonzero",
            "CandidateLiftRejectedByFreshProviderResidual",
            "FreshProviderValidationIncomplete"],
          <|"Prime" -> validationPrimes[[primeIndex]],
            "RegulatorValue" -> localValidationValue,
            "CheckIndex" -> checkIndex,
            "LastDetail" -> localValidationResult|>], Module]];
      {localValidationResult}, {primeIndex, Length[validationPrimes]},
      {checkIndex, freshPointwiseChecks}], 2]];
    <|"Status" -> "AdaptiveRegulatorLiftValidated",
      "Combined" -> localCombined, "Lifted" -> localLifted,
      "CoefficientCheck" -> localCoefficientCheck,
      "Vector" -> localVector, "Unpacked" -> localUnpacked,
      "ReconstructedVectorFingerprint" -> localVectorFingerprint,
      "Residues" -> localResidues,
      "PointwiseValidation" -> localValidation,
      "ValidationSeconds" -> localValidationSeconds,
      "Modulus" -> modulus,
      "ModulusBitLength" -> IntegerLength[modulus, 2]|>];

  Do[
    If[Length[goodPrimes] >= maximumGoodPrimeCount ||
        Length[rejectedPrimes] > maximumRejectedPrimeCount, Break[]];
    If[MemberQ[rejectedPrimes, candidatePrime], Continue[]];
    If[! KeyExistsQ[images, candidatePrime],
      images[candidatePrime] = imagesFor[candidatePrime,
        newPrimeRegulatorValues[]]];
    If[Lookup[images[candidatePrime], "Status", None] ===
        "BudgetExhausted", Return[images[candidatePrime], Module]];
    If[! ListQ[images[candidatePrime]],
      AppendTo[rejectedPrimes, candidatePrime];
      AssociateTo[primeRejections, candidatePrime ->
        Lookup[images[candidatePrime], "Status", "ImageScheduleFailed"]];
      log["prime ", candidatePrime, " rejected before interpolation: ",
        Lookup[images[candidatePrime], "Status", "ImageScheduleFailed"]];
      Continue[]];
    primeResult = perPrime[candidatePrime];
    If[Lookup[primeResult, "Status", None] === "BudgetExhausted",
      Return[primeResult, Module]];
    (* A degree cap is a property of the fixed rational section, not of the
       modular prime.  Repeating the same complete degree census at every
       prime cannot change this verdict and only rebuilds all epsilon fibres. *)
    If[Lookup[primeResult, "Status", None] ===
        "RegulatorMaximumTotalDegreeExceeded",
      log["regulator reconstruction stopped at the configured degree cap ",
        maximumTotalDegree, " after prime ", candidatePrime];
      Return[primeResult, Module]];
    If[Lookup[primeResult, "Status", None] =!= "HeldOutValidated",
      AppendTo[rejectedPrimes, candidatePrime];
      AssociateTo[primeRejections, candidatePrime ->
        Lookup[primeResult, "Status", "InterpolationFailed"]];
      log["prime ", candidatePrime, " rejected by interpolation: ",
        Lookup[primeResult, "Status", "InterpolationFailed"]];
      Continue[]];
    primeSignatures = DeleteDuplicates[
      {#1["Rank"], #1["Nullity"], #1["PivotSignature"]} & /@
        images[candidatePrime]];
    If[Length[primeSignatures] =!= 1 ||
        (referenceSignature =!= Automatic &&
          First[primeSignatures] =!= referenceSignature),
      AppendTo[rejectedPrimes, candidatePrime];
      AssociateTo[primeRejections, candidatePrime ->
        <|"Status" -> "NonmodalModularStructure",
          "Signatures" -> primeSignatures|>];
      log["prime ", candidatePrime,
        " rejected: nonmodal modular structure"];
      Continue[]];
    If[referenceSignature === Automatic,
      referenceSignature = First[primeSignatures]];
    interpolations[candidatePrime] = primeResult;
    If[expectedDegrees === Automatic,
      expectedDegrees = Lookup[primeResult["Interpolations"], "Degrees"];
      expectedDegreeSampleCount = Max[initialConstruction,
          1 + Max[Prepend[Cases[expectedDegrees,
            {numerator_Integer, denominator_Integer} :>
              numerator + denominator], 0]]] + heldOutCount;
      learnedRegulatorSampleCount = If[
        initialConstruction + heldOutCount <= expectedDegreeSampleCount <=
            maximumValues,
        expectedDegreeSampleCount,
        Lookup[primeResult, "SampleCount", Automatic]]];
    AppendTo[goodPrimes, candidatePrime];
    log["prime accepted ", Length[goodPrimes], "/",
      maximumGoodPrimeCount, ": ", candidatePrime,
      ", images ", Lookup[primeResult, "SampleCount", Missing["Unknown"]],
      ", interpolation ", Lookup[primeResult, "InterpolationBackend",
        "Wolfram"]];
    If[Length[goodPrimes] < minimumGoodPrimeCount, Continue[]];
    liftAttempts++;
    liftResult = liftAttempt[goodPrimes];
    log["lift after ", Length[goodPrimes], " primes: ",
      Lookup[liftResult, "Status", None], ", unresolved coefficients ",
      Length[Lookup[liftResult, "UnresolvedCoefficientLocations", {}]]];
    AppendTo[liftAttemptHistory, With[
      {modulus = Times @@ goodPrimes,
       status = Lookup[liftResult, "Status", None],
       locations = Lookup[liftResult,
         "UnresolvedCoefficientLocations", {}]},
      <|"GoodPrimeCount" -> Length[goodPrimes],
        "ModulusBitLength" -> IntegerLength[modulus, 2],
        "SymmetricHeightBoundBitLength" -> IntegerLength[
          Floor[Sqrt[(modulus - 1)/2]], 2],
        "Status" -> status,
        "UnresolvedCoefficientCount" -> Length[locations],
        "UnresolvedCoefficientLocations" -> locations,
        "PrimeCountEstimate" -> If[MemberQ[{
            "RationalReconstructionHeightUnresolved",
            "CandidateLiftRejectedByFreshProviderResidual"}, status],
          <|"Method" -> If[
              status === "RationalReconstructionHeightUnresolved",
              "SymmetricHeightCapacityV1",
              "FreshProviderRejectionV1"],
            "Lower" -> Length[goodPrimes] + 1,
            "Likely" -> Length[goodPrimes] + 1,
            "Conservative" -> Length[goodPrimes] + 2,
            "LowerStrength" -> If[
              status === "RationalReconstructionHeightUnresolved",
              "RigorousForCurrentPrefix",
              "RequiredByFreshProviderValidation"],
            "LikelyStrength" -> "SchedulingHeuristic",
            "ConservativeStrength" -> "SchedulingHeuristic",
            "WithinConfiguredMaximum" -> <|
              "Likely" ->
                Length[goodPrimes] + 1 <= maximumGoodPrimeCount,
              "Conservative" ->
                Length[goodPrimes] + 2 <= maximumGoodPrimeCount|>|>,
          Missing["NotAHeightEstimate"]]|>]];
    If[Lookup[liftResult, "Status", None] ===
        "AdaptiveRegulatorLiftValidated",
      liftSucceeded = True; Break[]];
    If[Lookup[liftResult, "Status", None] ===
        "FreshProviderValidationIncomplete", Return[liftResult, Module]],
    {candidatePrime, primePool}];
  If[! liftSucceeded,
    Return[multiquadraticStripFailure[
      If[Length[goodPrimes] >= maximumGoodPrimeCount,
        Replace[Lookup[liftResult, "Status", None],
          Except["RationalReconstructionHeightUnresolved" |
              "CandidateLiftRejectedByFreshProviderResidual"] ->
            "AdaptiveRegulatorLiftUnresolved"],
        "ReconstructionPrimePoolExhausted"],
      <|"GoodPrimes" -> goodPrimes, "RejectedPrimes" -> rejectedPrimes,
        "PrimeRejections" -> primeRejections,
        "GoodPrimeCount" -> Length[goodPrimes],
        "MaximumGoodPrimeCount" -> maximumGoodPrimeCount,
        "MaximumRejectedPrimeCount" -> maximumRejectedPrimeCount,
        "ModulusBitLength" -> If[goodPrimes === {}, 0,
          IntegerLength[Times @@ goodPrimes, 2]],
        "UnresolvedCoefficientCount" ->
          Length[unresolvedCoefficientLocations],
        "UnresolvedCoefficientLocations" ->
          unresolvedCoefficientLocations,
        "LiftAttemptHistory" -> liftAttemptHistory,
        "PrimeCountEstimate" -> If[liftAttemptHistory === {},
          Missing["NoLiftAttempt"], Lookup[Last[liftAttemptHistory],
            "PrimeCountEstimate", Missing["NotAHeightEstimate"]]],
        "LastLiftDetail" -> liftResult|>]]];
  primes = goodPrimes;
  reference = First[images[First[primes]]];
  values = DeleteDuplicates[Lookup[Flatten[Lookup[images, primes]],
    "RegulatorValue", {}]];
  signature = referenceSignature;
  combined = liftResult["Combined"];
  lifted = liftResult["Lifted"];
  reconstructedCoefficients = Flatten[Table[Join[
      lifted[[coordinate]]["NumeratorCoefficients"],
      lifted[[coordinate]]["DenominatorCoefficients"]],
    {coordinate, Length[lifted]}]];
  coefficientHeights = Flatten[
    ({Abs[Numerator[#1]], Denominator[#1]} &) /@
      reconstructedCoefficients];
  coefficientHeight = Max[Prepend[coefficientHeights, 1]];
  coefficientHeightBitLength = IntegerLength[coefficientHeight, 2];
  rationalReconstructionMinimumPrimeCount = SelectFirst[
    Range[Length[primes]],
    Floor[Sqrt[(Times @@ Take[primes, #1] - 1)/2]] >=
      coefficientHeight &,
    Missing["NotReachedByAcceptedPrimes"]];
  actualMinimumPrimeCount = If[
    IntegerQ[rationalReconstructionMinimumPrimeCount],
    Max[minimumGoodPrimeCount, rationalReconstructionMinimumPrimeCount],
    Missing["NotReachedByAcceptedPrimes"]];
  coefficientCheck = liftResult["CoefficientCheck"];
  vector = liftResult["Vector"];
  vectorFingerprint = liftResult["ReconstructedVectorFingerprint"];
  unpacked = liftResult["Unpacked"];
  residues = liftResult["Residues"];
  residuesKinematicsFree = True;
  pointwiseValidation = liftResult["PointwiseValidation"];
  validationSeconds = liftResult["ValidationSeconds"];
  unseenCheck = True;
  (* ---- reinstall the GENERIC object in the differential equation *)
  If[exactVerification === "ProviderPoints",
    exactGeneric = <|"Status" -> "ProviderPointwiseResidualZero",
      "ImageCount" -> Length[pointwiseValidation],
      "PrimeCount" -> Length[validationPrimes],
      "ContractStrength" -> "FreshFiniteFieldImages",
      "GenericStatement" -> "Probabilistic"|>;
    exactAtValues = Association[Table[
      check["RegulatorValue"] -> check["Status"],
      {check, pointwiseValidation}]],
  If[exactVerification =!= False,
    {verifySeconds, exactGeneric} = AbsoluteTiming[
      If[exactVerification === True,
        multiquadraticStripExactChannelResidual[preparation, vector],
        <|"Status" -> "ExactVerificationAtSampledValuesOnly"|>]];
    If[exactVerification === True &&
        Lookup[exactGeneric, "Status", None] =!= "ExactChannelResidualZero",
      Return[multiquadraticStripFailure["ReconstructedGenericResidualNonzero",
        <|"Detail" -> KeyDrop[exactGeneric, "ResidualChannels"]|>]]];
    exactAtValues = Association[Table[
      value -> Lookup[multiquadraticStripExactChannelResidual[preparation,
        vector, value], "Status", None],
      {value, Take[values, UpTo[3]]}]];
    If[AnyTrue[Values[exactAtValues], #1 =!= "ExactChannelResidualZero" &],
      Return[multiquadraticStripFailure["ReconstructedValueResidualNonzero",
        <|"ExactChannelResidual" -> exactAtValues|>]]]]];
  installationEvidence = If[exactVerification === True,
    Join[KeyTake[exactGeneric, {"Status"}],
      <|"Provider" -> provider["Kind"],
        "LayoutFingerprint" -> layout["LayoutFingerprint"],
        "ProviderFingerprint" -> provider["ProviderFingerprint"],
        "ReconstructedVectorFingerprint" -> vectorFingerprint|>],
    <|"Status" -> "FreshProviderResidualZero",
      "Provider" -> provider["Kind"],
      "LayoutFingerprint" -> layout["LayoutFingerprint"],
      "ProviderFingerprint" -> provider["ProviderFingerprint"],
      "ReconstructedVectorFingerprint" -> vectorFingerprint,
      "Primes" -> validationPrimes, "Checks" -> pointwiseValidation,
      "FreshProviderValidationDisjointFromCRT" ->
        Intersection[primes, validationPrimes] === {}|>];
  degreeHistogram = Counts[Lookup[
    interpolations[First[primes]]["Interpolations"], "Degrees"]];
  <|"Status" -> "ReconstructedRegulatorDependenceV1",
    "Method" -> "CanonicalAffineSectionRationalInRegulator",
    "LayoutFingerprint" -> layout["LayoutFingerprint"],
    "Provider" -> provider["Kind"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
    "Regulator" -> epsilon, "Variables" -> variables,
    "SamplePrimes" -> primes, "UnseenPrime" -> unseenPrime,
    "UnseenPrimes" -> validationPrimes,
    "RegulatorValues" -> values,
    "LearnedRegulatorSampleCount" -> learnedRegulatorSampleCount,
    "ExpectedDegreeSampleCount" -> expectedDegreeSampleCount,
    "PrimeRegulatorImageCounts" -> Association[Table[
      prime -> Length[Lookup[images, prime, {}]], {prime, primes}]],
    "RegulatorScheduleGrowths" -> grew,
    "NormalizationColumns" -> normalizationColumns,
    "Nullity" -> signature[[2]], "Rank" -> signature[[1]],
    "PivotSignature" -> signature[[3]],
    "PivotColumns" -> reference["PivotColumns"],
    "FreeColumns" -> reference["FreeColumns"],
    "CoordinateCount" -> coordinateCount,
    "DegreeHistogram" -> degreeHistogram,
    "MaximumRegulatorDegree" -> Max[0, Cases[
      Flatten[Lookup[interpolations[First[primes]]["Interpolations"],
        "Degrees"]], _Integer]],
    "Vector" -> vector,
    "ReconstructedVectorFingerprint" -> vectorFingerprint,
    "GaugeChannels" -> unpacked["GaugeChannels"],
    "Gauge" -> unpacked["Gauge"],
    "Residues" -> residues,
    "ResiduesKinematicsFree" -> residuesKinematicsFree,
    "ResiduesRegulatorFree" -> FreeQ[residues, epsilon],
    "CoefficientImageCheck" -> coefficientCheck,
    "UnseenPrimeCoefficientCheck" -> unseenCheck,
    "FreshProviderPointwiseChecks" -> pointwiseValidation,
    "FreshProviderPointwiseCheckCount" -> Length[pointwiseValidation],
    "FreshProviderValidationDisjointFromCRT" ->
      Intersection[primes, validationPrimes] === {},
    "InstallationEvidence" -> installationEvidence,
    "UnseenPrimeInterpolation" ->
      Missing["ReplacedByFreshProviderPointwiseValidation"],
    "AdaptivePrimeAccumulation" -> True,
    "GoodPrimes" -> primes,
    "RejectedPrimes" -> rejectedPrimes,
    "PrimeRejections" -> primeRejections,
    "ExceptionalRegulatorImages" -> exceptionalImages,
    "ConstrainedEliminationPlan" -> If[AssociationQ[eliminationPlan],
      KeyDrop[eliminationPlan, {"IndependentEquationRows"}],
      Missing["PlanUnavailable"]],
    "ConstrainedEliminationPlanFailure" -> eliminationPlanFailure,
    "PlanDiscoveryBackendRequested" -> requestedPlanBackend,
    "PlanDiscoveryBackendUsed" -> Lookup[planDiscoveryTelemetry,
      "PlanDiscoveryBackendUsed", Missing["PlanNotDiscovered"]],
    "PlanDiscoveryBackendThreads" -> planBackendThreads,
    "PlanDiscoveryBackendMinimumEntries" -> Replace[
      planBackendMinimumEntries, Automatic :>
        $multiquadraticStripPlanDiscoveryNativeMinimumEntries],
    "PlanDiscoveryTelemetry" -> planDiscoveryTelemetry,
    "FollowerImageKernelCountRequested" -> imageKernelCountRequested,
    "FollowerImageMaximumConcurrency" ->
      Max[Prepend[Lookup[followerWaveRecords, "Concurrency", {}], 1]],
    "FollowerImageNativeThreadCeiling" ->
      Max[Prepend[Lookup[followerWaveRecords, "Concurrency", {}], 1]]
        If[AssociationQ[eliminationPlan],
          Lookup[eliminationPlan, "PlanDiscoveryBackendThreads",
            followerNativeThreads], followerNativeThreads],
    "FollowerImageParallelWaveCount" -> followerParallelWaveCount,
    "FollowerImageSerialWaveCount" -> followerSerialWaveCount,
    "FollowerImageParallelCount" -> followerParallelImageCount,
    "FollowerImageSerialCount" -> followerSerialImageCount,
    "FollowerImageWaveRecords" -> followerWaveRecords,
    "ReusedPilotImageCount" -> reusedPilotImageCount,
    "StructuralPilotEvidence" -> structuralPilotEvidence,
    "StructuralPilotPrimeCount" -> structuralPilotPrimeCount,
    "StructuralPilotRREFCount" -> structuralPilotRREFCount,
    "StructuralPilotNewSampleCount" -> structuralPilotNewSampleCount,
    "StructuralPilotNewFullAffineSolveCount" ->
      structuralPilotNewRREFCount,
    "StructuralPilotCacheHitCount" -> structuralPilotCacheHitCount,
    "ModalStructuralSignature" -> modalStructuralSignature,
    "ModalReferencePrime" -> modalReferencePrime,
    "ModalReferenceRegulatorValue" -> modalReferenceValue,
    "ConstrainedSolveCount" -> constrainedSolveCount,
    "FullAffineSolveCount" -> fullSolveCount,
    "FullAffineFallbackCount" -> fallbackSolveCount,
    "ImagePhaseRecords" -> imagePhaseRecords,
    "LiftAttemptCount" -> liftAttempts,
    "LiftAttemptHistory" -> liftAttemptHistory,
    "CombinedModulusBitLength" -> IntegerLength[Times @@ primes, 2],
    "CoefficientHeight" -> coefficientHeight,
    "CoefficientHeightBitLength" -> coefficientHeightBitLength,
    "RationalReconstructionMinimumPrimeCount" ->
      rationalReconstructionMinimumPrimeCount,
    "ActualMinimumPrimeCount" -> actualMinimumPrimeCount,
    "ActualPrimeCount" -> Length[primes],
    "PrimeCountOvershoot" -> If[IntegerQ[actualMinimumPrimeCount],
      Length[primes] - actualMinimumPrimeCount,
      Missing["MinimumNotReached"]],
    "ActualMinimumPrimeCountBasis" ->
      "ExactSymmetricHeightBoundOverAcceptedPrimePrefixes",
    "HeldOutValidation" -> Association[Table[
      prime -> KeyTake[interpolations[prime],
        {"SampleCount", "ConstructionCount", "ValidationCount",
         "CertificationMode", "DeterministicShortfallCoordinates"}],
      {prime, primes}]],
    "ExactVerification" -> exactVerification,
    "ExactGenericResidual" -> KeyDrop[exactGeneric, "ResidualChannels"],
    "ExactChannelResidualAtValues" -> exactAtValues,
    "TrainingImageKeys" -> DeleteDuplicates[Flatten[
      Lookup[Flatten[Lookup[images, primes]], "TrainingImageKeys", {}], 1]],
    "ImageStoreKeys" -> DeleteDuplicates[
      Lookup[Flatten[Lookup[images, primes]], "ImageStoreKey", {}]],
    "PhaseSeconds" -> <|"Sampling" -> sampleSeconds,
      "Elimination" -> eliminationSeconds,
      "Interpolation" -> interpolationSeconds, "CRT" -> crtSeconds,
      "Lift" -> liftSeconds,
      "FreshValidation" -> validationSeconds,
      "ExactVerification" -> verifySeconds|>,
    "Seconds" -> AbsoluteTime[] - startTime|>
];
(* Compatibility oracle: a compiled assembly is immediately split into
   its provider-independent layout and its tagged compiled provider. *)
multiquadraticStripReconstructRegulator[preparation_Association,
    assembly_Association, opts : OptionsPattern[]] := Module[
  {layout = multiquadraticStripAssemblyLayout[preparation], provider},
  If[! multiquadraticStripCompiledValidQ[assembly],
    Return[multiquadraticStripFailure["InvalidReconstructionInput"]]];
  provider = multiquadraticStripCompiledProvider[assembly];
  multiquadraticStripReconstructRegulator[preparation, layout, provider,
    opts]
];
multiquadraticStripReconstructRegulator[___] :=
  multiquadraticStripFailure["InvalidReconstructionArguments"];

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
multiquadraticStripBackendGate[backend_, threads_: 2,
    minimumEntries_: Automatic] := Module[{decision},
  decision = multiquadraticStripPlanDiscoveryBackendDecision[backend, threads,
    {0, 0}, minimumEntries];
  If[Lookup[decision, "Status", None] === "OK", None, decision]
];

multiquadraticStripClearCaches[] := (
  $multiquadraticStripPrimeCache = <||>;
  $multiquadraticStripEpsilonCache = <||>;
  (* the compile pools of the 2026-08-25 core/ansatz split are caches
     too: a caller that clears state expects them gone *)
  multiquadraticStripCompileCacheClear[];
  multiquadraticStripScreenCompileCacheClear[];
  $multiquadraticStripSplitSparsePlanCache = <||>;
  $multiquadraticStripSplitSparseExactPlanCache = <||>;
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
  (* The immutable strip input file that contains a bundle's preserved
     BlockEquationDeferred DAG.  The native evaluator reads it directly;
     the large Records forest is never copied into the provider. *)
  "DeferredPreparationFile" -> Automatic,
  "SamplePrimes" -> Automatic,
  "RegulatorValues" -> Automatic,
  "HeldOutPrime" -> Automatic,
  "HeldOutRegulatorValue" -> Automatic,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "PlanDiscoveryBackend" -> Automatic,
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> Automatic,
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
  (* how many FRESH RANDOM good images re-test a defect that survived
     both configured images (round-2 item 3).  Automatic is the module
     default (3); 0 restores the pre-2026-08-26 two-fixed-prime verdict
     and is what the ladder rungs use internally. *)
  "GaugeScreenFreshImageCount" -> Automatic,
  (* ---- SCREEN-FIRST ORDERING (round-2 item 9; Codex 2.3).  The
     full-gauge screen on a CONSERVATIVE SUPERSET ansatz, built from the
     RAW forcing denominators and the alphabet norms with no channel
     decomposition at all, run BEFORE the exact preparation it screens.

     Automatic = "Advisory": the screen is run and its verdict recorded,
     and it NEVER stops the block.  The superset argument is sound (see
     multiquadraticStripConservativeGaugeDenominator), so True is
     admissible and stops on a CONFIRMED obstruction -- but no real block
     has yet been screened both ways under this wave's no-family-run
     gate, and a negative verdict needs evidence like a positive one.
     False skips it. *)
  "ScreenFirst" -> Automatic,
  "ScreenFirstDegreeOffset" -> Automatic,
  (* the screen-validated escalation ladder, run ONLY when the screen at
     the configured "DegreeOffset" reports a CONFIRMED defect.  Automatic
     = FACET_MQ_DEGREE_LADDER or the built-in ladder; None = no
     escalation (the pre-2026-08-25 behaviour: return the typed
     obstruction at once). *)
  "DegreeOffsetLadder" -> Automatic,
  (* ---- RATIONAL-IN-EPSILON RECONSTRUCTION (round-2 item 6).  Automatic
     = True: without it the route cannot produce one coherent solution
     vector and its terminal contract can never rise above
     ModularConsistent, which is the gap the round-2 wave exists to
     close.  It costs one assemble-and-solve per (prime, regulator
     image), and the regulator schedule is longer than the two values
     the fiberwise route sampled: budget for
     (|SamplePrimes| + 1) x RegulatorReconstructionCount images.
     False restores the pre-2026-08-26 fiberwise behaviour exactly. *)
  "RegulatorReconstruction" -> Automatic,
  "RegulatorReconstructionValues" -> Automatic,
  "RegulatorReconstructionCount" -> 9,
  "RegulatorReconstructionImageKernelCount" -> Automatic,
  "ReconstructionPrimePool" -> Automatic,
  "ReconstructionMinimumGoodPrimeCount" -> Automatic,
  "ReconstructionMaximumGoodPrimeCount" -> 32,
  "ReconstructionMaximumRejectedPrimeCount" -> 64,
  "ReconstructionMaximumTotalDegree" -> 64,
  "ReconstructionUnseenPrimeCount" -> 2,
  "ReconstructionFreshPointwiseChecksPerPrime" -> 3,
  (* True = verify the reconstructed GENERIC object in the differential
     equation (the mathematical statement); "AtSampledValues" = the same
     identity at the sampled regulator values only; False = modular
     certificates only. *)
  "RegulatorReconstructionCheck" -> Automatic,
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
solveEpsFormStripMultiquadratic[sourceRecord_Association, frame_Association,
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
  {record = sourceRecord, radicalCanonicalization,
   reconstruction, reconstructedQ, potentialsCertifiedQ,
   activeCertification, activeCertifiedQ, installable,
   screenFirst, screenFirstAnsatz, screenFirstOffset,
   conservativeDenominator,
   startTime = AbsoluteTime[], gate, backendGate, verbose, log, preparation,
   assembly, layout, provider, providerRecord, coefficientProvider,
   reconstructionEnabled,
   primes, widePrimeSchedule, regulatorValues, heldOutPrime, heldOutRegulatorValue,
   allPrimes, samples = <||>, solutions = <||>, sample, solution, signature,
   signatures = {}, lifts = <||>, exactChecks = <||>, heldOutSolution,
   freshProviderChecks, freshReference, branchCertificate, branchMask,
   transformedSample, differential, liftedVector, unpacked, prime,
   regulatorValue, samplerOptions, deadline, budgetProgress,
   budgetExhausted, enrich, variables, epsilon, strip, allRoots, classification,
   deferredBundle, deferredASTWrapper, deferredASTPreparation,
   deferredASTInputFile, deferredASTSourceQ, deferredASTRootSquares,
   deferredASTRootIndices, deferredASTSelectedIndices,
   deferredASTStableFrame, slimDeferredLayout,
   bundleIndices,
   requiredRootIndices, rootIndices, order,
    suppliedRootClassification, trustedRootClassificationQ,
    screenRoots, letterRecords, letterData, screen,
    screenRegulatorValue, prepareOptions, gaugeScreen, gaugeLadder,
    deferredProviderLadder, ladderImages, ladderValues, rungBuilder,
    reconstructionPilotImages = {},
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
  backendGate = multiquadraticStripBackendGate[
    OptionValue["PlanDiscoveryBackend"],
    OptionValue["PlanDiscoveryBackendThreads"],
    OptionValue["PlanDiscoveryBackendMinimumEntries"]];
  If[AssociationQ[backendGate], Return[backendGate]];
  coefficientProvider = Replace[OptionValue["CoefficientProvider"],
    Automatic -> "SplitBranch"];
  If[! MemberQ[{"CompiledChannel", "SplitBranch", "QuotientGrade"},
      coefficientProvider],
    Return[multiquadraticStripFailure["InvalidCoefficientProvider",
      <|"CoefficientProvider" -> coefficientProvider|>]]];
  reconstructionEnabled = TrueQ[Replace[
    OptionValue["RegulatorReconstruction"], Automatic -> True]];
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
  deferredBundle = Replace[OptionValue["DeferredBundle"], Automatic :>
    Lookup[record, "DeferredBundle", Missing["NoDeferredBundle"]]];
  deferredASTWrapper = Lookup[record, "DeferredPreparation",
    If[AssociationQ[deferredBundle],
      Lookup[deferredBundle, "DeferredPreparation",
        Missing["NoDeferredPreparation"]],
      Missing["NoDeferredPreparation"]]];
  deferredASTPreparation = If[AssociationQ[deferredASTWrapper],
    Lookup[deferredASTWrapper, "Preparation", deferredASTWrapper],
    deferredASTWrapper];
  deferredASTInputFile = Replace[OptionValue["DeferredPreparationFile"],
    Automatic :> Lookup[record, "DeferredPreparationFile",
      Missing["NoDeferredPreparationFile"]]];
  deferredASTSourceQ = AssociationQ[deferredASTPreparation] &&
    StringQ[deferredASTInputFile];
  slimDeferredLayout[candidate_] := If[deferredASTSourceQ &&
      AssociationQ[candidate] && Lookup[candidate, "Status", None] ===
        "MultiquadraticStripAssemblyLayoutV1",
    Join[candidate, <|"Record" -> KeyDrop[candidate["Record"],
      {"DeferredBundle", "DeferredPreparation",
        "DeferredPreparationFile"}]|>], candidate];
  screenRoots = Missing["RootsNotResolved"];
  letterRecords = Missing["NotBuilt"];
  screen = <|"Status" -> "IntegrabilityScreenSkipped"|>;
  If[MatchQ[variables, {_Symbol, _Symbol}] && MatchQ[epsilon, _Symbol] &&
      MatchQ[strip, {_List, _List, _List}],
    allRoots = transportChartCurrentRoots[frame, variables];
    If[ListQ[allRoots],
      suppliedRootClassification = OptionValue["RootClassification"];
      trustedRootClassificationQ =
        AssociationQ[suppliedRootClassification] &&
        AssociationQ[deferredBundle] &&
        AssociationQ[$blockEquationDeferredTrustedBundle] &&
        Lookup[blockEquationDeferredBundleValidate[deferredBundle],
          "Status", None] === "BundleValid" &&
        AllTrue[{"RadicalBases", "UnclassifiedRadicalBases"},
          KeyExistsQ[suppliedRootClassification, #1] &];
      multiquadraticStripStageStart["outer root census",
        <|"supplied" -> trustedRootClassificationQ|>];
      classification = multiquadraticStripRootCensusWithBundle[strip, allRoots,
        variables, epsilon, deferredBundle,
        If[trustedRootClassificationQ, suppliedRootClassification,
          Automatic]];
      (* The dense BBar is a zero-shape placeholder on the raw native route,
         exactly as it is for a DeferredBundle.  Union the root squares bound
         by the authenticated preparation wrapper before alphabet/grade
         construction; otherwise the visible strip silently collapses a
         genuine rank-3 forcing to the diagonal's rank-1 field. *)
      If[deferredASTSourceQ && ! AssociationQ[deferredBundle],
        deferredASTRootSquares = Lookup[deferredASTWrapper,
          "RootSquares", Missing["NoRootSquares"]];
        If[! ListQ[deferredASTRootSquares],
          Return[multiquadraticStripFailure[
            "DeferredPreparationRootFrameMissing"]]];
        deferredASTRootIndices = Table[Module[{matches},
            matches = Flatten[Position[allRoots,
              candidate_ /; TrueQ[Quiet[Together[
                    candidate["RootSquare"] - square]] === 0],
              {1}, Heads -> False]];
            If[Length[matches] =!= 1,
              Return[multiquadraticStripFailure[
                "DeferredPreparationRootFrameMismatch",
                <|"RootSquare" -> square, "Matches" -> matches|>],
                Module]];
            First[matches]],
          {square, deferredASTRootSquares}];
        If[! VectorQ[deferredASTRootIndices, IntegerQ],
          Return[FirstCase[deferredASTRootIndices,
            failure_Association :> failure,
            multiquadraticStripFailure[
              "DeferredPreparationRootFrameMismatch"]]]];
        deferredASTSelectedIndices = DeleteDuplicates[Join[
          Lookup[classification, "RootIndices", {}],
          deferredASTRootIndices]];
        deferredASTStableFrame = blockEquationDeferredRootFrame[
          KeyTake[#1, {"Root", "RootSquare"}] & /@
            allRoots[[deferredASTSelectedIndices]], variables, epsilon];
        If[Lookup[deferredASTStableFrame, "Status", None] =!=
            "StableRootOrder",
          Return[multiquadraticStripFailure[
            "DeferredPreparationRootUnionInvalid",
            <|"Detail" -> deferredASTStableFrame|>]]];
        classification = Join[classification, <|
          "BundleRootIndices" -> deferredASTRootIndices,
          "RequiredRootIndices" ->
            deferredASTSelectedIndices[[Lookup[
              deferredASTStableFrame["Roots"], "SourceIndex", {}]]]|>]];
      multiquadraticStripStageDone["outer root census",
        <|"source" -> If[trustedRootClassificationQ, "SameCall", "Fresh"]|>];
      If[! KeyExistsQ[classification, "UnclassifiedRadicalBases"],
        Return[classification]];
      (* the shared field canonicalizer, ahead of the alphabet and both
         screens (round-2 item 4): the letters, the one-forms and the
         point evaluations all decompose into channels, so they must see
         the same declared-radical strip prepare will see.  A no-op on a
         strip whose radicals are all declared squares. *)
      radicalCanonicalization = multiquadraticStripCanonicalizeRadicals[strip,
        allRoots, classification];
      If[Lookup[radicalCanonicalization, "Status", None] ===
          "RadicalsCanonicalized",
        strip = radicalCanonicalization["Expression"];
        record = Join[record, <|"Strip" -> strip|>]];
      bundleIndices = classification["BundleRootIndices"];
      requiredRootIndices = classification["RequiredRootIndices"];
      rootIndices = Replace[OptionValue["RootIndices"],
        Automatic :> Sort[requiredRootIndices]];
      If[VectorQ[rootIndices, IntegerQ] && rootIndices === Sort[rootIndices] &&
          DuplicateFreeQ[rootIndices] &&
          SubsetQ[rootIndices, Sort[DeleteDuplicates[Join[
            classification["RootIndices"], bundleIndices]]]] &&
          (! AssociationQ[deferredBundle] ||
            ContainsAll[rootIndices, bundleIndices]) &&
          (! deferredASTSourceQ || AssociationQ[deferredBundle] ||
            ContainsAll[rootIndices, bundleIndices]) &&
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
      "MaximumNormExponent" -> OptionValue["MaximumNormExponent"],
      "DLogKernels" -> OptionValue["DLogKernels"],
      "Deadline" -> deadline];
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
  If[! AssociationQ[deferredBundle] &&
      TrueQ[OptionValue["IntegrabilityScreen"]] && ListQ[screenRoots] &&
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
    (* Only a CONFIRMED obstruction ends the block: every configured
       image AND the full requested fresh-image draw carrying a defect,
       per the evidence classifier (round-3 A1).  The status name alone
       is not the authority -- the driver rechecks the evidence
       predicate before returning the negative contract. *)
    If[Lookup[screen, "Status", None] === "AlphabetIntegrabilityObstruction" &&
        multiquadraticStripConfirmedObstructionEvidenceQ[screen],
      (* ansatz-relative name, for the same reason as the gauge contract
         below (round-2 item 3): the note here was already bounded, the
         NAME was not, and a consumer that reads only the name would
         record a theorem *)
      Return[Join[screen, <|"SolutionContract" -> "AlphabetObstructionWithinAnsatz",
        "ContractNote" -> StringJoin[
          "the residue-only integrability system carries a rank defect at ",
          ToString[Lookup[screen, "ImageCount", 0]],
          " independent (prime, regulator) images (",
          ToString[Lookup[screen, "ConfiguredImageCount", 0]],
          " configured plus ",
          ToString[Lookup[screen, "FreshImageCount", 0]],
          " drawn fresh at random for this call): a high-confidence ",
          "modular obstruction, i.e. no gauge of any shape, denominator ",
          "or support repairs this alphabet at any of these images and ",
          "the alphabet is missing letters. It is not an unconditional ",
          "theorem over Q(eps): the statement is exact for each ",
          "specialized finite-field system, and its generic validity ",
          "rests on the images being independent, not on a proved ",
          "epsilon-degree bound."],
        "ContractStrength" -> "HighConfidenceModularObstruction",
        "ImageCount" -> Lookup[screen, "ImageCount", Missing["NotRecorded"]],
        "Seconds" -> AbsoluteTime[] - startTime|>]]];
    If[Lookup[screen, "Status", None] ===
        "AlphabetIntegrabilityObstructionUnconfirmed",
      log["integrability screen: the defect did NOT reproduce at the ",
        "confirmation image; not treated as an obstruction"]];
    If[Lookup[screen, "Status", None] === "IntegrabilityScreenInconclusive",
      log["integrability screen: INCONCLUSIVE (",
        Lookup[screen, "Reason", None],
        "); the defect evidence is incomplete and may not harden into ",
        "an obstruction; the established route runs"]];
    If[Lookup[screen, "Status", None] === "BudgetExhausted",
      Return[enrich[Join[budgetExhausted["IntegrabilityScreen"],
        <|"IntegrabilityScreen" -> KeyTake[screen,
          {"Stage", "SizeEstimate", "PhaseTimings",
           "MatrixDimensions"}]|>]]]]];
  (* ---------------------------------------------------------------- *)
  (* SCREEN-FIRST: the conservative superset ansatz, before prepare.     *)
  (* ---------------------------------------------------------------- *)
  screenFirst = <|"Status" -> "ScreenFirstSkipped"|>;
  If[! AssociationQ[deferredBundle] &&
      Replace[OptionValue["ScreenFirst"], Automatic :> "Advisory"] =!= False &&
      ListQ[screenRoots] && MatchQ[letterRecords, {__Association}],
    screenFirstOffset = Replace[OptionValue["ScreenFirstDegreeOffset"],
      Automatic :> Module[{ladder = Replace[OptionValue["DegreeOffsetLadder"],
          {Automatic :> multiquadraticStripDegreeOffsetLadder[],
           None -> {}}]},
        If[MatchQ[ladder, {{_Integer, _Integer} ..}],
          {Max[Append[ladder[[All, 1]], OptionValue["DegreeOffset"][[1]]]],
           Max[Append[ladder[[All, 2]], OptionValue["DegreeOffset"][[2]]]]},
          OptionValue["DegreeOffset"]]]];
    conservativeDenominator =
      multiquadraticStripConservativeGaugeDenominator[strip, screenRoots,
        letterRecords, variables];
    If[conservativeDenominator === $Failed,
      screenFirst = <|"Status" -> "ConservativeGaugeDenominatorFailed"|>,
      multiquadraticStripStageStart["screen-first",
        <|"degreeOffset" -> screenFirstOffset,
          "letters" -> Length[letterRecords]|>];
      screenFirstAnsatz = multiquadraticStripGaugeAnsatz[record, screenRoots,
        Lookup[letterRecords, "OneForm", {}], conservativeDenominator,
        "DegreeOffset" -> screenFirstOffset];
      screenFirst = If[Lookup[screenFirstAnsatz, "Status", None] =!=
          "MultiquadraticGaugeAnsatzV1", screenFirstAnsatz,
        multiquadraticStripGaugeScreenImages[screenFirstAnsatz,
          "PointCount" -> OptionValue["GaugeScreenPointCount"],
          "FreshImageCount" -> OptionValue["GaugeScreenFreshImageCount"],
          "Deadline" -> deadline, Sequence @@ ceilingOptions]];
      multiquadraticStripStageDone["screen-first",
        <|"status" -> Lookup[screenFirst, "Status", None],
          "defects" -> Lookup[screenFirst, "Defects", None],
          "images" -> Lookup[screenFirst, "ImageCount", None],
          "seconds" -> Lookup[screenFirst, "Seconds", Missing["NotMeasured"]]|>];
      log["screen-first (conservative superset ansatz): ",
        Lookup[screenFirst, "Status", None], ", defects ",
        Lookup[screenFirst, "Defects", None], ", unknowns ",
        Lookup[screenFirstAnsatz, "UnknownCount", None]];
      (* the STOP is opt-in.  A confirmed defect on a SUPERSET ansatz is
         a defect on every subset of it, so the stop is sound; it is off
         by default only because no real block has been screened both
         ways yet under the no-family-run gate. *)
      If[OptionValue["ScreenFirst"] === True &&
          Lookup[screenFirst, "Status", None] === "GaugeImageObstruction" &&
          multiquadraticStripConfirmedObstructionEvidenceQ[screenFirst],
        Return[enrich[Join[
          KeyTake[screenFirst, {"ImageCount", "ConfiguredImageCount",
            "FreshImageCount", "Defects", "Images", "Ansatz",
            "EvidenceRecord"}],
          <|"Status" -> "GaugeImageObstruction",
            "Stage" -> "ScreenFirst",
            "Module" -> "MultiquadraticStripSolve",
            "SolutionContract" -> "GaugeObstructionWithinAnsatz",
            "ContractStrength" -> "HighConfidenceModularObstruction",
            "ConservativeGaugeDenominator" -> conservativeDenominator,
            "ScreenFirstDegreeOffset" -> screenFirstOffset,
            "ContractNote" -> "the affine gauge system of a CONSERVATIVE SUPERSET ansatz -- the raw forcing denominators with algebraic factors replaced by their Galois norms, the alphabet norms, and a degree offset at least the largest ladder rung -- carries a rank defect at every image run. A superset that is inconsistent makes every subset of it inconsistent, so the exact preparation this stage precedes would reproduce the defect. It is a high-confidence modular obstruction WITHIN THAT ANSATZ, not a theorem over Q(eps).",
            "Seconds" -> AbsoluteTime[] - startTime|>]]]]]];
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
    If[AssociationQ[classification],
      {"RootClassification" -> classification}, {}],
    (* the caller's deadline now reaches prepare, which since 2026-08-25
       checks it at its own interior boundaries *)
    {"Deadline" -> deadline,
      "CoefficientProvider" -> coefficientProvider},
    FilterRules[DeleteCases[Flatten[{opts}],
      HoldPattern["LetterRecords" -> _] | HoldPattern["LetterRecords" :> _] |
      HoldPattern["CompileCore" -> _] | HoldPattern["CompileCore" :> _] |
      HoldPattern["RootClassification" -> _] |
      HoldPattern["RootClassification" :> _] |
      HoldPattern["CoefficientProvider" -> _] |
      HoldPattern["CoefficientProvider" :> _] |
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
  gaugeScreen = If[AssociationQ[deferredBundle],
    <|"Status" -> "GaugeScreenSkipped",
      "Reason" -> "DeferredForcingRequiresAuthenticatedProvider"|>,
    <|"Status" -> "GaugeScreenSkipped"|>];
  If[! AssociationQ[deferredBundle] && TrueQ[OptionValue["GaugeScreen"]],
    multiquadraticStripStageStart["gauge screen",
      <|"unknowns" -> preparation["UnknownCount"],
        "support" -> Length[preparation["GaugeSupport"]],
        "oneForms" -> Length[preparation["OneForms"]],
        "equationsPerPoint" -> preparation["EquationsPerPoint"],
        "degreeOffset" -> adoptedDegreeOffset|>];
    (* the CHEAP FIRST PASS: two configured images, no fresh ones.  The
       fresh-image confirmation is paid below, only when the ladder has
       failed and the block is actually going to be refused. *)
    gaugeScreen = multiquadraticStripGaugeScreenImages[preparation,
      "Images" -> OptionValue["GaugeScreenImages"],
      "PointCount" -> OptionValue["GaugeScreenPointCount"],
      "FreshImageCount" -> 0,
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
           block is going to be REFUSED, so this is where the evidence
           has to be paid for -- the same screen re-run with fresh random
           good images (round-2 item 3).  Nothing before this point pays
           for them. *)
        gaugeScreen = If[Replace[OptionValue["GaugeScreenFreshImageCount"],
              Automatic :> $multiquadraticStripDefaultFreshImageCount] === 0,
          gaugeScreen,
          Module[{confirmed = multiquadraticStripGaugeScreenImages[preparation,
              "Images" -> OptionValue["GaugeScreenImages"],
              "PointCount" -> OptionValue["GaugeScreenPointCount"],
              "FreshImageCount" ->
                OptionValue["GaugeScreenFreshImageCount"],
              "Deadline" -> deadline, Sequence @@ ceilingOptions]},
            multiquadraticStripStageDone["gauge screen: fresh confirmation",
              <|"status" -> Lookup[confirmed, "Status", None],
                "images" -> Lookup[confirmed, "ImageCount", None],
                "defects" -> Lookup[confirmed, "Defects", None]|>];
            log["gauge screen: fresh-image confirmation ",
              Lookup[confirmed, "Status", None], ", defects ",
              Lookup[confirmed, "Defects", None]];
            (* ALWAYS adopt the confirmation run (round-3 A1,
               monotonicity): failed or contrary fresh evidence may
               never be discarded in favour of the earlier two-image
               result *)
            confirmed]];
        Which[
          (* the negative contract: ONLY the exact confirmed status,
             with the evidence predicate rechecked on the record itself
             -- the status name alone is not the authority *)
          Lookup[gaugeScreen, "Status", None] === "GaugeImageObstruction" &&
            multiquadraticStripConfirmedObstructionEvidenceQ[gaugeScreen],
        Return[enrich[Join[
          KeyDrop[First[gaugeScreen["ImageResults"]], {"Module"}],
          <|"Status" -> "GaugeImageObstruction",
            "Module" -> "MultiquadraticStripSolve",
            "Confirmed" -> True,
            "EvidenceRecord" -> Lookup[gaugeScreen, "EvidenceRecord",
              Missing["NotRecorded"]],
            "Defects" -> gaugeScreen["Defects"],
            "Images" -> gaugeScreen["Images"],
            "ImageResults" -> (KeyDrop[#1, {"Witness"}] & /@
              gaugeScreen["ImageResults"]),
            "DegreeOffset" -> OptionValue["DegreeOffset"],
            "GaugeScreenLadder" -> gaugeLadder,
            "LadderDefects" -> Lookup[gaugeLadder, "LadderDefects",
              Missing["GaugeScreenLadderNotRun"]],
            (* ANSATZ-RELATIVE, BOUNDED WORDING (round-2 item 3, Codex
               review 1.5).  The old contract name
               "NoGaugeExistsWithThisAnsatz" is theorem-level language
               for evidence that is modular and finite: N independent
               images, each an exact statement about ITS OWN specialized
               finite-field system.  What is recorded now is the
               statement the evidence supports, with the count and the
               ansatz it is relative to attached. *)
            "SolutionContract" -> "GaugeObstructionWithinAnsatz",
            "ContractStrength" -> "HighConfidenceModularObstruction",
            "ImageCount" -> Lookup[gaugeScreen, "ImageCount", 0],
            "ConfiguredImageCount" -> Lookup[gaugeScreen,
              "ConfiguredImageCount", Missing["NotRecorded"]],
            "FreshImageCount" -> Lookup[gaugeScreen, "FreshImageCount",
              Missing["NotRecorded"]],
            "AnsatzFingerprint" -> Lookup[preparation, "ABIFingerprint",
              Missing["NoPreparation"]],
            "Ansatz" -> Lookup[gaugeScreen, "Ansatz", Missing["NoAnsatz"]],
            "ContractNote" -> StringJoin[
              "the complete affine gauge system carries a rank defect at ",
              ToString[Lookup[gaugeScreen, "ImageCount", 0]],
              " independent (prime, regulator) images",
              If[Lookup[gaugeScreen, "FreshImageCount", 0] > 0,
                StringJoin[" (", ToString[Lookup[gaugeScreen,
                  "ConfiguredImageCount", 0]],
                  " configured plus ", ToString[Lookup[gaugeScreen,
                    "FreshImageCount", 0]],
                  " drawn fresh at random for this call)"], ""],
              If[Lookup[gaugeLadder, "Status", None] ===
                  "GaugeScreenLadderExhausted",
                " AND at every escalated numerator degree of the ladder", ""],
              "; the compile it screens would reproduce exactly this defect, ",
              "and the witness names which residue demand is unmet.  This is ",
              "a HIGH-CONFIDENCE MODULAR obstruction WITHIN THE STATED ",
              "ALPHABET, SUPPORT AND DENOMINATOR ANSATZ (fingerprint above), ",
              "not a theorem over Q(eps): each image is exact for its own ",
              "specialized system, and genericity rests on the images being ",
              "independent, not on a proved epsilon-degree bound.  A ",
              "different alphabet, support or gauge denominator is a ",
              "different statement and must be screened separately."],
            "GaugeScreenSeconds" -> gaugeScreen["Seconds"],
            "GaugeScreenLadderSeconds" -> Lookup[gaugeLadder, "Seconds",
              Missing["GaugeScreenLadderNotRun"]],
            "Seconds" -> AbsoluteTime[] - startTime|>]]],
          (* a fresh image admitted a solution: the configured defect is
             an exceptional image of a solvable system.  CONTINUE the
             full route -- never a negative contract. *)
          MemberQ[{"GaugeImageConsistent", "GaugeImageConsistentUnconfirmed"},
              Lookup[gaugeScreen, "Status", None]] ||
            (Lookup[gaugeScreen, "Status", None] === "GaugeScreenInconclusive" &&
             Lookup[gaugeScreen, "Reason", None] === "MixedDefectEvidence"),
          log["gauge screen: a fresh image admitted a solution ",
            "(sampled consistency); the configured defect is treated as ",
            "exceptional and the full route continues"],
          (* a budget stop of the confirmation run stays a budget stop *)
          Lookup[gaugeScreen, "Status", None] === "BudgetExhausted",
          Return[enrich[Join[budgetExhausted["GaugeScreenConfirmation"],
            <|"GaugeScreen" -> KeyTake[gaugeScreen,
              {"Stage", "SizeEstimate", "PhaseTimings",
               "MatrixDimensions"}]|>]]],
          (* everything else -- an unconfirmed defect, incomplete or
             unusable fresh evidence, a not-applicable re-screen -- is a
             typed INCONCLUSIVE stop: no negative contract, no contract
             strength, resumable with a different seed or budget *)
          True,
          Return[enrich[Join[
            KeyTake[gaugeScreen, {"ImageCount", "ConfiguredImageCount",
              "FreshImageCount", "Defects", "Images", "EvidenceRecord",
              "FreshImageRequest", "Ansatz"}],
            <|"Status" -> "GaugeScreenInconclusive",
              "Module" -> "MultiquadraticStripSolve",
              "Confirmed" -> False,
              "Reason" -> Lookup[gaugeScreen, "Reason",
                Lookup[gaugeScreen, "Status", Missing["NoReason"]]],
              "DegreeOffset" -> OptionValue["DegreeOffset"],
              "GaugeScreenLadder" -> gaugeLadder,
              "ContractNote" -> StringJoin[
                "the configured images carry a defect but the requested ",
                "fresh-image confirmation was NOT completed (",
                ToString[Lookup[gaugeScreen, "Reason",
                  Lookup[gaugeScreen, "Status", "unknown"]]],
                "); the evidence may not harden into an obstruction ",
                "contract.  Re-run with a different FreshImageSeed or a ",
                "larger budget to decide the block."],
              "Seconds" -> AbsoluteTime[] - startTime|>]]]]]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["GaugeScreen"]]];
  (* the preparation object was built in THIS call: its ABI payload is
     the one just computed and its forcing channels are exact, so the
     compiler neither re-derives the payload nor decomposes the forcing
     a second time (post-mortem item 5) *)
  multiquadraticStripStageStart[If[coefficientProvider === "CompiledChannel",
      "compile", "provider"],
    <|"family" -> Lookup[record, "Family", None],
      "sector" -> Lookup[record, "Sector", None],
      "lower" -> Lookup[record, "LowerSector", None],
      "unknowns" -> preparation["UnknownCount"],
      "oneForms" -> Length[preparation["OneForms"]],
      "support" -> Length[preparation["GaugeSupport"]]|>];
  (* the public compile-architecture options reach the compiler, so that
     "CompileCore" -> False really does restore the pre-2026-08-25 path
     on the whole route and not merely in prepare (Codex P2) *)
  If[coefficientProvider === "CompiledChannel",
    assembly = multiquadraticStripCompile[preparation,
      "PreparationValidated" -> True,
      "ForcingChannels" -> Lookup[preparation, "ForcingChannels", Automatic],
      "CompileCore" -> OptionValue["CompileCore"],
      "LetterChannels" -> OptionValue["LetterChannels"],
      "LetterGradeSupport" -> OptionValue["LetterGradeSupport"],
      "CompactDLogAdmission" -> OptionValue["CompactDLogAdmission"],
      "LegacyCompiler" -> OptionValue["LegacyCompiler"],
      "Deadline" -> deadline,
      "PoolByteLimit" -> poolByteLimit,
      "PoolEntryLimit" -> poolEntryLimit];
    If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
      Return[enrich[assembly]]];
    layout = multiquadraticStripAssemblyLayout[preparation];
    provider = multiquadraticStripCompiledProvider[assembly],
    assembly = Missing["DirectProviderDoesNotCompileChannels"];
    (* Follower payloads need the row layout, not the large coefficient
       source.  Keep the authenticated bundle in preparation/provenance,
       while every serialized layout carries only the mathematical strip. *)
    layout = slimDeferredLayout[
      multiquadraticStripAssemblyLayout[preparation]];
    If[! multiquadraticStripAssemblyLayoutValidQ[layout],
      Return[enrich[layout]]];
    providerRecord = If[deferredASTSourceQ,
      KeyDrop[preparation["Record"], {"DeferredBundle",
        "DeferredPreparation", "DeferredPreparationFile"}],
      preparation["Record"]];
    provider = multiquadraticStripDirectProvider[providerRecord,
      preparation["Roots"], "Kind" -> coefficientProvider,
      "OneForms" -> preparation["OneForms"],
      "GaugeDenominator" -> preparation["GaugeDenominator"],
      "DeferredBundle" -> If[deferredASTSourceQ, None,
        Lookup[preparation, "DeferredBundle", Automatic]],
      "CoefficientABIFingerprint" ->
        layout["CoefficientABIFingerprint"],
      "SourceFingerprint" -> If[deferredASTSourceQ &&
          AssociationQ[deferredASTPreparation],
        Lookup[deferredASTPreparation, "SourceFingerprint",
          preparation["ABIFingerprint"]],
        preparation["ABIFingerprint"]]];
    If[deferredASTSourceQ,
      provider = multiquadraticStripAttachDeferredPreparation[provider,
        deferredASTPreparation, deferredASTInputFile]]];
  If[! multiquadraticStripAssemblyLayoutValidQ[layout] ||
      ! multiquadraticStripProviderValidQ[provider],
    Return[enrich[If[AssociationQ[provider], provider,
      multiquadraticStripFailure["ProviderConstructionFailed"]]]]];
  multiquadraticStripStageDone[
    If[coefficientProvider === "CompiledChannel", "compile", "provider"],
    If[coefficientProvider === "CompiledChannel",
      KeyTake[Lookup[assembly, "CompileStatistics", <||>],
        {"Architecture", "Seconds", "CoreSeconds", "OneFormSeconds",
         "GaugeDenominatorSeconds"}],
      <|"kind" -> coefficientProvider,
       "seconds" -> Lookup[provider, "CensusSeconds", 0.],
        "activeRootHistogram" ->
          Lookup[provider, "ActiveRootHistogram", <||>]|>]];
  (* A deferred bundle's BBar slot is a zero shape placeholder.  No symbolic
     screen above inspected it; now that the authenticated provider exists,
     measure the real affine rows at the configured support and climb only if
     both independent images are inconsistent. *)
  deferredProviderLadder = <|"Status" ->
    "DeferredProviderSupportLadderNotRun"|>;
  If[AssociationQ[deferredBundle] &&
      OptionValue["Support"] === Automatic &&
      OptionValue["DegreeOffsetLadder"] =!= None,
    ladderValues = Replace[OptionValue["RegulatorReconstructionValues"],
      Automatic :> $multiquadraticStripRegulatorScheduleDefault];
    ladderImages = Module[{ladderPrimes = Replace[
        OptionValue["SamplePrimes"], Automatic :>
          $multiquadraticStripDefaultPrimes], ladderPrimePool, primary},
      ladderPrimePool = Replace[OptionValue["ReconstructionPrimePool"],
        Automatic :> DeleteDuplicates[Join[ladderPrimes,
          $multiquadraticStripPrimePool]]];
      If[! ListQ[ladderPrimePool] || ! ListQ[ladderValues], {},
        primary = If[Length[ladderPrimePool] >= 2 &&
            Length[ladderValues] >= 2,
          Transpose[{Take[ladderPrimePool, 2], Take[ladderValues, 2]}], {}];
        DeleteDuplicates[Join[primary, Flatten[Table[{p, value},
          {p, ladderPrimePool}, {value, ladderValues}], 1]]]]];
    rungBuilder = Function[{offset}, Module[{nextPreparation, nextLayout,
        reusableProvider = provider, nextOptions},
      nextOptions = Join[
        If[MatchQ[Lookup[preparation, "LetterRecords", None],
            {___Association}],
          {"LetterRecords" -> preparation["LetterRecords"]}, {}],
        {"DegreeOffset" -> offset,
          "GaugeDenominator" -> preparation["GaugeDenominator"],
          "ForcingChannels" -> Replace[
            Lookup[preparation, "ForcingChannels", Automatic],
            Except[_Association] -> Automatic]},
        DeleteCases[prepareOptions,
          HoldPattern["DegreeOffset" -> _] |
          HoldPattern["DegreeOffset" :> _] |
          HoldPattern["Support" -> _] | HoldPattern["Support" :> _] |
          HoldPattern["GaugeDenominator" -> _] |
          HoldPattern["GaugeDenominator" :> _] |
          HoldPattern["ForcingChannels" -> _] |
          HoldPattern["ForcingChannels" :> _] |
          HoldPattern["LetterRecords" -> _] |
          HoldPattern["LetterRecords" :> _]]];
      nextPreparation = multiquadraticStripPrepare[record, frame,
        Sequence @@ nextOptions];
      If[Lookup[nextPreparation, "Status", None] =!=
          "PreparedMultiquadraticStripV1",
        Return[nextPreparation, Module]];
      nextLayout = slimDeferredLayout[
        multiquadraticStripAssemblyLayout[nextPreparation]];
      If[! multiquadraticStripAssemblyLayoutValidQ[nextLayout],
        Return[nextLayout, Module]];
      If[nextLayout["CoefficientABIFingerprint"] =!=
          reusableProvider["CoefficientABIFingerprint"],
        Return[multiquadraticStripFailure[
          "ProviderSupportCoefficientABIChanged",
          <|"DegreeOffset" -> offset,
            "Expected" -> reusableProvider["CoefficientABIFingerprint"],
            "Observed" -> nextLayout["CoefficientABIFingerprint"]|>],
          Module]];
      <|"Preparation" -> nextPreparation, "Layout" -> nextLayout,
        "Provider" -> reusableProvider|>]];
    multiquadraticStripStageStart["deferred provider support ladder",
      <|"baseDegreeOffset" -> OptionValue["DegreeOffset"],
        "images" -> ladderImages,
        "provider" -> provider["Kind"]|>];
    deferredProviderLadder = multiquadraticStripProviderSupportLadder[
      preparation, layout, provider, rungBuilder,
      "BaseDegreeOffset" -> OptionValue["DegreeOffset"],
      "DegreeOffsetLadder" -> OptionValue["DegreeOffsetLadder"],
      "Images" -> ladderImages, "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> OptionValue["RandomSeed"],
      "PlanDiscoveryBackend" -> OptionValue["PlanDiscoveryBackend"],
      "PlanDiscoveryBackendThreads" ->
        OptionValue["PlanDiscoveryBackendThreads"],
      "PlanDiscoveryBackendMinimumEntries" ->
        OptionValue["PlanDiscoveryBackendMinimumEntries"],
      "Deadline" -> deadline];
    multiquadraticStripStageDone["deferred provider support ladder",
      <|"status" -> Lookup[deferredProviderLadder, "Status", None],
        "adoptedDegreeOffset" -> Lookup[deferredProviderLadder,
          "AdoptedDegreeOffset", None],
        "ladderDefects" -> Lookup[deferredProviderLadder,
          "LadderDefects", None],
        "seconds" -> Lookup[deferredProviderLadder, "Seconds",
          Missing["NotMeasured"]]|>];
    Which[
      Lookup[deferredProviderLadder, "Status", None] ===
          "DeferredProviderSupportLadderAdopted",
        adoptedDegreeOffset = deferredProviderLadder["AdoptedDegreeOffset"];
        preparation = deferredProviderLadder["Preparation"];
        layout = deferredProviderLadder["Layout"];
        provider = deferredProviderLadder["Provider"];
        reconstructionPilotImages = deferredProviderLadder["PilotImages"];
        If[adoptedDegreeOffset =!= OptionValue["DegreeOffset"],
          assembly = Missing["ProviderReusedAcrossSupportLayout"]],
      Lookup[deferredProviderLadder, "Status", None] ===
          "DeferredProviderSupportLadderExhausted" &&
          TrueQ[Lookup[deferredProviderLadder,
            "ObstructionCertified", False]],
        Return[enrich[Join[KeyDrop[deferredProviderLadder,
          {"Preparation", "Layout", "Provider", "PilotImages"}],
          <|"SolutionContract" -> "GaugeObstructionWithinTestedSupportLadder",
            "ContractStrength" -> "TwoProviderImagesPerRung"|>]]],
      True,
        Return[enrich[deferredProviderLadder]]]];
  (* between preparation and the modular schedule *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Preparation"]]];
  widePrimeSchedule = If[OptionValue["SamplePrimes"] === Automatic,
    Block[{$multiquadraticStripTrustedProviderEvaluation = True},
      multiquadraticStripWidePrimeScheduleQ[provider]], False];
  primes = Replace[OptionValue["SamplePrimes"], Automatic :>
    If[widePrimeSchedule,
      $multiquadraticStripWideDefaultPrimes,
      $multiquadraticStripDefaultPrimes]];
  regulatorValues = Replace[OptionValue["RegulatorValues"],
    Automatic :> $multiquadraticStripDefaultRegulatorValues];
  heldOutPrime = Replace[OptionValue["HeldOutPrime"], Automatic :> 2147483323];
  heldOutRegulatorValue = Replace[OptionValue["HeldOutRegulatorValue"],
    Automatic :> 5/23];
  allPrimes = Append[primes, heldOutPrime];
  If[! VectorQ[primes, IntegerQ] || primes === {} ||
      ! AllTrue[allPrimes, PrimeQ[#1] && Mod[#1, 4] === 3 &&
        3 < #1 < $multiquadraticStripWordPrimeLimit &] ||
      ! DuplicateFreeQ[allPrimes] || ! ListQ[regulatorValues] ||
      regulatorValues === {} ||
      ! AllTrue[Append[regulatorValues, heldOutRegulatorValue],
        MatchQ[#1, _Integer | _Rational] &] ||
      MemberQ[regulatorValues, heldOutRegulatorValue],
    Return[multiquadraticStripFailure["InvalidSamplingSchedule",
      <|"Primes" -> primes, "HeldOutPrime" -> heldOutPrime,
        "RegulatorValues" -> regulatorValues,
        "HeldOutRegulatorValue" -> heldOutRegulatorValue|>]]];
  (* The provider-backed reconstruction below owns the modular image
     schedule.  The former driver solved every image once here and then
     solved the same images a second time during reconstruction.  Besides
     doubling the dominant work, that legacy loop required a compiled
     assembly and therefore made the direct providers unusable at the
     production entry point.  Keep the old sampler only as an explicit
     compatibility oracle; production has one image store and one solve
     loop. *)
  If[! reconstructionEnabled,
    Return[enrich[multiquadraticStripFailure[
      "RegulatorReconstructionRequired",
      <|"Reason" -> "the production multiquadratic route requires one coherent rational-in-regulator gauge; independent epsilon fibres are diagnostic only",
        "CoefficientProvider" -> coefficientProvider|>]]]];
  samples = <||>; solutions = <||>; lifts = <||>; exactChecks = <||>;
  branchCertificate = {<|"Status" ->
      "SupersededByProviderReconstruction"|>};
  differential = <|"Status" -> "DeferredToFreshProviderValidation"|>;
  unpacked = <|"Status" -> "NotReconstructed"|>;
  (* ---------------------------------------------------------------- *)
  (* RATIONAL-IN-EPSILON RECONSTRUCTION (round-2 item 6).               *)
  (* Everything above is fiberwise: one lift per regulator VALUE.  This *)
  (* stage produces ONE coherent solution vector, rational in the       *)
  (* regulator, on one canonical affine section, validated at held-out  *)
  (* epsilon images and an unseen prime and reinstalled in the          *)
  (* differential equation.  It is the difference between a modular     *)
  (* consistency statement and a solved object.                         *)
  (* ---------------------------------------------------------------- *)
  If[TrueQ[Replace[OptionValue["RegulatorReconstruction"], Automatic :> True]],
    multiquadraticStripStageStart["regulator reconstruction",
      <|"unknowns" -> preparation["UnknownCount"],
        "oneForms" -> Length[preparation["OneForms"]]|>];
    reconstruction = multiquadraticStripReconstructRegulator[preparation,
      layout, provider,
      "InputsValidated" -> True,
      "SamplePrimes" -> primes, "UnseenPrime" -> heldOutPrime,
      "PrimePool" -> OptionValue["ReconstructionPrimePool"],
      "MinimumGoodPrimeCount" ->
        OptionValue["ReconstructionMinimumGoodPrimeCount"],
      "MaximumGoodPrimeCount" ->
        OptionValue["ReconstructionMaximumGoodPrimeCount"],
      "MaximumRejectedPrimeCount" ->
        OptionValue["ReconstructionMaximumRejectedPrimeCount"],
      "MaximumTotalDegree" ->
        OptionValue["ReconstructionMaximumTotalDegree"],
      "UnseenPrimeCount" ->
        OptionValue["ReconstructionUnseenPrimeCount"],
      "FreshPointwiseChecksPerPrime" ->
        OptionValue["ReconstructionFreshPointwiseChecksPerPrime"],
      "RegulatorValues" -> OptionValue["RegulatorReconstructionValues"],
      "InitialRegulatorCount" ->
        OptionValue["RegulatorReconstructionCount"],
      "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> OptionValue["RandomSeed"],
      "PlanDiscoveryBackend" -> OptionValue["PlanDiscoveryBackend"],
      "PlanDiscoveryBackendThreads" ->
        OptionValue["PlanDiscoveryBackendThreads"],
      "PlanDiscoveryBackendMinimumEntries" ->
        OptionValue["PlanDiscoveryBackendMinimumEntries"],
      "ImageKernelCount" ->
        OptionValue["RegulatorReconstructionImageKernelCount"],
      "PilotImages" -> reconstructionPilotImages,
      "ExactVerification" -> Replace[
        OptionValue["RegulatorReconstructionCheck"], Automatic :>
          If[coefficientProvider === "CompiledChannel", True,
            "ProviderPoints"]],
      "Deadline" -> deadline, "Verbose" -> verbose];
    multiquadraticStripStageDone["regulator reconstruction",
      <|"status" -> Lookup[reconstruction, "Status", None],
        "degrees" -> Lookup[reconstruction, "DegreeHistogram", None],
        "seconds" -> Lookup[reconstruction, "Seconds",
          Missing["NotMeasured"]]|>];
    log["regulator reconstruction: ", Lookup[reconstruction, "Status", None],
      ", degree histogram ", Lookup[reconstruction, "DegreeHistogram", None]];
    If[Lookup[reconstruction, "Status", None] === "BudgetExhausted",
      Return[enrich[reconstruction]]],
    reconstruction = <|"Status" -> "RegulatorReconstructionSkipped"|>];
  reconstructedQ = Lookup[reconstruction, "Status", None] ===
    "ReconstructedRegulatorDependenceV1";
  If[! reconstructedQ,
    Return[enrich[Join[reconstruction,
      <|"SolutionContract" -> "RegulatorReconstructionIncomplete"|>]]]];
  signature = Lookup[reconstruction, {"Rank", "Nullity",
    "PivotSignature"}, Missing["NotReconstructed"]];
  unpacked = <|"Status" -> "UnpackedMultiquadraticSolution",
    "GaugeChannels" -> reconstruction["GaugeChannels"],
    "Gauge" -> reconstruction["Gauge"],
    "Residues" -> reconstruction["Residues"]|>;
  (* Reconstruction already replayed the generic vector at fresh split
     points on unseen primes (two primes x three images by default).  A
     second provider sample and a full RREF here repeated the dominant work
     without strengthening that statement: a rank-changing fresh image which
     the generic vector satisfies still certifies the vector.  Reuse the
     authenticated fresh checks for the sign-branch and differential views. *)
  freshProviderChecks = Lookup[reconstruction,
    "FreshProviderPointwiseChecks", {}];
  If[! MatchQ[freshProviderChecks, {__Association}] ||
      ! AllTrue[freshProviderChecks,
        Lookup[#1, "Status", None] === "ProviderPointwiseResidualZero" &&
          TrueQ[Lookup[#1, "Passed", False]] &],
    Return[enrich[multiquadraticStripFailure[
      "FreshProviderValidationMissingAfterReconstruction"]]]];
  freshReference = First[freshProviderChecks];
  heldOutPrime = freshReference["Prime"];
  heldOutRegulatorValue = freshReference["RegulatorValue"];
  heldOutSolution = <|
    "Status" -> "SupersededByReconstructionFreshChecks",
    "Rank" -> signature[[1]], "Nullity" -> signature[[2]],
    "PivotColumns" -> reconstruction["PivotColumns"],
    "FreeColumns" -> reconstruction["FreeColumns"],
    "PivotSignature" -> signature[[3]],
    "FreshCheckCount" -> Length[freshProviderChecks],
    "FreshPrimes" -> DeleteDuplicates[Lookup[freshProviderChecks, "Prime"]],
    "Evidence" -> "AuthenticatedReconstructionProviderResiduals"|>;
  branchCertificate = Table[<|"BranchFlipMask" -> branchMask,
      "ResidualZero" -> True,
      "Evidence" -> "InvertibleGradeToSignTransformAtFreshSplitPoints",
      "FreshCheckCount" -> Length[freshProviderChecks]|>,
    {branchMask, 0, preparation["GradeCount"] - 1}];
  differential = <|"Status" -> "MultiquadraticPointDifferentialPassed",
    "Passed" -> True, "Method" -> "ReconstructionFreshProviderResiduals",
    "Primes" -> DeleteDuplicates[Lookup[freshProviderChecks, "Prime"]],
    "RegulatorValues" ->
      DeleteDuplicates[Lookup[freshProviderChecks, "RegulatorValue"]],
    "Points" -> DeleteDuplicates[Flatten[
      Lookup[freshProviderChecks, "Points", {}], 1]],
    "FreshCheckCount" -> Length[freshProviderChecks]|>;
  (* Preserve the small, useful compatibility view of the old fibrewise
     fields without repeating any modular solve.  Each is an evaluation of
     the one reconstructed vector, not an independently selected affine
     representative. *)
  Do[
    liftedVector = Quiet[Together /@
      (reconstruction["Vector"] /. preparation["Regulator"] ->
        regulatorValue)];
    lifts[regulatorValue] = <|"Status" -> "LiftedMultiquadraticVector",
      "Vector" -> liftedVector, "Source" -> "RegulatorReconstruction"|>;
    exactChecks[regulatorValue] = Switch[
      Lookup[reconstruction, "ExactVerification", False],
      True | "AtSampledValues", "ExactChannelResidualZero",
      "ProviderPoints", "ProviderPointwiseResidualZero",
      _, "VerificationSkipped"],
    {regulatorValue, regulatorValues}];
  (* THE INSTALLATION VERDICT (round-3 A2): computed from the exact
     reconstructed ACTIVE support, never from the candidate pool.  The
     candidate-pool verdict stays available as telemetry. *)
  potentialsCertifiedQ = TrueQ[Lookup[preparation, "PotentialsCertified",
    False]];
  activeCertification = Module[{potentialRecords, residuesForActive},
    residuesForActive = Lookup[reconstruction, "Residues", {}];
    (* Potentials is a compact reporting view and intentionally omits the
       authenticated OneForm.  Installation needs the full aligned records:
       the active-support converter validates both the potential pair seal
       and the exact form that was installed in the row layout. *)
    potentialRecords = Lookup[preparation, "LetterRecords", {}];
    If[! MatchQ[potentialRecords, {___Association}] ||
        Length[potentialRecords] =!= Length[residuesForActive],
      potentialRecords = Table[<|"Potential" -> <|"Verified" -> False,
        "Reason" -> "LetterRecordsUnavailableToDriver"|>|>,
        {Length[Replace[residuesForActive, Except[_List] -> {}]]}]];
    multiquadraticStripActivePotentialCertification[potentialRecords,
      residuesForActive, reconstructedQ]];
  activeCertifiedQ = TrueQ[Lookup[activeCertification, "Certified", False]];
  installable = If[activeCertifiedQ,
    multiquadraticStripBuildInstallableSolution[preparation, reconstruction,
      activeCertification, reconstruction["InstallationEvidence"],
      preparation["Dimensions"]],
    multiquadraticStripFailure["ActivePotentialCertificationUnavailable"]];
  If[Lookup[installable, "Status", None] === "Solved",
    Return[Join[installable, <|
      "Family" -> Lookup[record, "Family", None],
      "Sector" -> Lookup[record, "Sector", None],
      "LowerSector" -> Lookup[record, "LowerSector", None],
      "RootIndices" -> Lookup[preparation, "RootSourceIndices",
        preparation["RootIndices"]],
      "RootSquares" -> preparation["RootSquares"],
      "RootCount" -> preparation["RootCount"],
      "GradeCount" -> preparation["GradeCount"],
      (* The direct identity-frame installer does not need to expose this,
         but a rational-chart fallback feeds the same solved gauge into the
         package's finite-field inverse-map reconstruction.  Reuse the
         denominator already certified by preparation instead of factoring
         the reconstructed gauge again. *)
      "GaugeDenominator" -> preparation["GaugeDenominator"],
      "GaugeDenominatorDegrees" -> preparation["GaugeDenominatorDegrees"],
      "GaugeChannels" -> reconstruction["GaugeChannels"],
      "Residues" -> installable["ResidueMatrices"],
      "ActivePotentialCertification" -> KeyDrop[activeCertification,
        {"ActiveOneForms", "ActiveResidues"}],
      "BranchCertificate" -> branchCertificate,
      "DifferentialCheck" -> differential,
      "FullAffineSolveCount" -> Lookup[reconstruction,
        "FullAffineSolveCount", Missing["NotRecorded"]],
      "PostReconstructionAffineSolveCount" -> 0,
      "DeferredBundleFingerprint" -> Lookup[preparation,
        "DeferredBundleFingerprint", Missing["NoDeferredBundle"]],
      "AdoptedDegreeOffset" -> adoptedDegreeOffset,
      "IntegrabilityScreen" -> KeyTake[screen, {"Status", "Reason"}],
      "GaugeScreen" -> If[AssociationQ[gaugeScreen],
        KeyTake[gaugeScreen, {"Status", "Reason"}],
        <|"Status" -> "GaugeScreenSkipped"|>],
      "RegulatorReconstruction" -> KeyTake[reconstruction,
        {"Status", "Method", "Provider", "ProviderFingerprint",
         "LayoutFingerprint", "ReconstructedVectorFingerprint",
         "SamplePrimes", "UnseenPrimes", "RegulatorValues",
         "LearnedRegulatorSampleCount", "PrimeRegulatorImageCounts",
         "RegulatorScheduleGrowths", "HeldOutValidation",
         "LiftAttemptCount", "LiftAttemptHistory",
         "CombinedModulusBitLength", "CoefficientHeight",
         "CoefficientHeightBitLength",
         "RationalReconstructionMinimumPrimeCount",
         "ActualMinimumPrimeCount", "ActualPrimeCount",
         "PrimeCountOvershoot", "ActualMinimumPrimeCountBasis",
         "NormalizationColumns", "DegreeHistogram",
         "FreshProviderPointwiseCheckCount", "ConstrainedEliminationPlan",
          "ConstrainedEliminationPlanFailure", "ConstrainedSolveCount",
          "FullAffineSolveCount", "FullAffineFallbackCount",
          "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
          "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendMinimumEntries",
          "PlanDiscoveryTelemetry", "ReusedPilotImageCount",
          "FollowerImageKernelCountRequested",
          "FollowerImageMaximumConcurrency",
          "FollowerImageNativeThreadCeiling",
          "FollowerImageParallelWaveCount", "FollowerImageSerialWaveCount",
          "FollowerImageParallelCount", "FollowerImageSerialCount",
          "FollowerImageWaveRecords",
          "StructuralPilotEvidence", "StructuralPilotPrimeCount",
          "StructuralPilotRREFCount", "StructuralPilotNewSampleCount",
          "StructuralPilotNewFullAffineSolveCount",
          "StructuralPilotCacheHitCount", "ModalStructuralSignature",
          "ModalReferencePrime", "ModalReferenceRegulatorValue",
          "ImagePhaseRecords", "PhaseSeconds", "Seconds"}],
      "DeferredProviderSupportLadder" -> If[
        AssociationQ[deferredProviderLadder],
        KeyDrop[deferredProviderLadder,
          {"Preparation", "Layout", "Provider", "PilotImages"}],
        <|"Status" -> "DeferredProviderSupportLadderNotRun"|>],
      "Seconds" -> AbsoluteTime[] - startTime|>]]];
  <|(* The installable branch returned above is the only Solved contract.
       Reaching this fallback means reconstruction succeeded but active dlog
       certification or installation evidence did not; retain the honest
       ModularConsistent result and record the exact missing condition. *)
    "Status" -> "ModularConsistent",
    "Method" -> "DirectRootChannel",
    "SolutionContract" -> "OneFormsNotCertified",
    "RegulatorReconstructed" -> reconstructedQ,
    "SolvedLevelClaim" -> <|
      "Withheld" -> True,
      "RegulatorReconstructed" -> reconstructedQ,
      (* the INSTALLATION-relevant bit: verified potentials on the
         ACTIVE support of the reconstructed residues (round-3 A2); the
         candidate-pool verdict beside it is telemetry *)
      "ActivePotentialsCertified" -> activeCertifiedQ,
      "CandidatePotentialsCertified" -> potentialsCertifiedQ,
      "MissingForInstallation" -> If[activeCertifiedQ,
        Lookup[installable, "Status", "InstallationEvidenceUnavailable"],
        "ActiveDLogPotentialCertification"],
      "Reason" -> Which[
        reconstructedQ && activeCertifiedQ,
          "the ACTIVE support is certified, but the installation gate refused the residual/provenance payload with status " <>
            ToString[Lookup[installable, "Status", "unknown"]],
        reconstructedQ,
          "the regulator dependence is reconstructed and verified, but an ACTIVE letter (nonzero reconstructed residue) has no verified dlog potential: indices " <> ToString[Lookup[activeCertification, "UnverifiedActiveIndices", "unknown"]],
        Lookup[activeCertification, "Pending", None] === "PendingReconstruction",
          "no coherent rational-in-regulator solution vector was reconstructed (" <> ToString[Lookup[reconstruction, "Status", "unknown"]] <> "), so the active support is unknown and certification is pending",
        True,
          "neither a reconstructed rational-in-regulator solution vector nor certified potentials"]|>,
    "ActivePotentialCertification" -> KeyDrop[activeCertification,
      {"ActiveOneForms", "ActiveResidues"}],
    "InstallationAttempt" -> installable,
    "ContractNote" -> "the reconstructed provider solution is modularly consistent but did not satisfy the active-support installation gate; it is recorded and not installed as a solved epsilon form.",
    "RegulatorReconstruction" -> KeyTake[reconstruction,
      {"Status", "Method", "Provider", "ProviderFingerprint",
       "CoefficientABIFingerprint", "SamplePrimes", "UnseenPrime",
       "RegulatorValues",
       "NormalizationColumns", "DegreeHistogram", "MaximumRegulatorDegree",
       "ResiduesKinematicsFree", "ResiduesRegulatorFree",
       "CoefficientImageCheck", "UnseenPrimeCoefficientCheck",
       "ExactVerification", "RegulatorScheduleGrowths", "HeldOutValidation",
       "AdaptivePrimeAccumulation", "GoodPrimes", "RejectedPrimes",
       "PrimeRejections", "ExceptionalRegulatorImages", "LiftAttemptCount",
       "LiftAttemptHistory", "PrimeCountEstimate",
       "UnresolvedCoefficientCount", "UnresolvedCoefficientLocations",
       "CombinedModulusBitLength", "CoefficientHeight",
       "CoefficientHeightBitLength",
       "RationalReconstructionMinimumPrimeCount",
       "ActualMinimumPrimeCount", "ActualPrimeCount",
       "PrimeCountOvershoot", "ActualMinimumPrimeCountBasis",
       "UnseenPrimes",
       "FreshProviderPointwiseCheckCount",
       "FreshProviderValidationDisjointFromCRT",
       "ConstrainedEliminationPlan", "ConstrainedEliminationPlanFailure",
       "ConstrainedSolveCount", "FullAffineSolveCount",
       "FullAffineFallbackCount", "PlanDiscoveryBackendRequested",
       "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads",
       "PlanDiscoveryBackendMinimumEntries", "PlanDiscoveryTelemetry",
       "ReusedPilotImageCount", "StructuralPilotEvidence",
       "StructuralPilotPrimeCount", "StructuralPilotRREFCount",
       "StructuralPilotNewSampleCount",
       "StructuralPilotNewFullAffineSolveCount",
       "StructuralPilotCacheHitCount", "ModalStructuralSignature",
       "ModalReferencePrime", "ModalReferenceRegulatorValue",
       "FollowerImageKernelCountRequested",
       "FollowerImageMaximumConcurrency",
       "FollowerImageNativeThreadCeiling",
       "FollowerImageParallelWaveCount", "FollowerImageSerialWaveCount",
       "FollowerImageParallelCount", "FollowerImageSerialCount",
       "FollowerImageWaveRecords", "ImagePhaseRecords",
       "TrainingImageKeys", "ImageStoreKeys", "PhaseSeconds", "Seconds"}],
    "RegulatorGauge" -> Lookup[reconstruction, "Gauge",
      Missing["NotReconstructed"]],
    "RegulatorGaugeChannels" -> Lookup[reconstruction, "GaugeChannels",
      Missing["NotReconstructed"]],
    "RegulatorResidues" -> Lookup[reconstruction, "Residues",
      Missing["NotReconstructed"]],
    "RegulatorVector" -> Lookup[reconstruction, "Vector",
      Missing["NotReconstructed"]],
    "PotentialsCertified" -> potentialsCertifiedQ,
    "PotentialsCertifiedReason" -> Lookup[preparation,
      "PotentialsCertifiedReason", Missing["NotRecorded"]],
    "PotentialsUnverifiedKinds" -> Lookup[preparation,
      "PotentialsUnverifiedKinds", Missing["NotRecorded"]],
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "RootIndices" -> Lookup[preparation, "RootSourceIndices",
      preparation["RootIndices"]],
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
    (* the screen-first verdict on the conservative superset ansatz,
       recorded whether or not it was given the authority to stop *)
    "ScreenFirst" -> If[AssociationQ[screenFirst],
      KeyTake[screenFirst, {"Status", "ImageCount", "ConfiguredImageCount",
        "FreshImageCount", "Defects"}],
      <|"Status" -> "ScreenFirstSkipped"|>],
    (* the offset the REAL ansatz was built at: the caller's, unless the
       ladder measured a larger one and adopted it.  Timing-free, like
       every other field of this record. *)
    "AdoptedDegreeOffset" -> adoptedDegreeOffset,
    "GaugeScreenLadder" -> If[AssociationQ[gaugeLadder],
      KeyTake[gaugeLadder, {"Status", "AdoptedDegreeOffset",
        "BaseDegreeOffset", "DegreeOffsetLadder", "SkippedDegreeOffsets",
        "RungCount", "LadderDefects"}],
      <|"Status" -> "GaugeScreenLadderNotRun"|>],
    "DeferredProviderSupportLadder" -> If[
      AssociationQ[deferredProviderLadder],
      KeyDrop[deferredProviderLadder,
        {"Preparation", "Layout", "Provider", "PilotImages"}],
      <|"Status" -> "DeferredProviderSupportLadderNotRun"|>],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "AlgebraABIFingerprint" -> preparation["AlgebraABIFingerprint"],
    "PreparationSchema" -> Lookup[preparation, "PreparationSchema",
      Missing["PreparationSchema"]],
    "AssemblyFingerprint" -> If[AssociationQ[assembly],
      Lookup[assembly, "AssemblyFingerprint", Missing["NotCompiled"]],
      Missing["DirectProviderDoesNotCompileChannels"]],
    "LayoutFingerprint" -> layout["LayoutFingerprint"],
    "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
    "CoefficientProvider" -> provider["Kind"],
    "ProviderFingerprint" -> provider["ProviderFingerprint"],
    "Rank" -> signature[[1]], "Nullity" -> signature[[2]],
    "PivotSignature" -> signature[[3]],
    "PivotColumns" -> reconstruction["PivotColumns"],
    "FullAffineSolveCount" -> Lookup[reconstruction,
      "FullAffineSolveCount", Missing["NotRecorded"]],
    "PostReconstructionAffineSolveCount" -> 0,
    "SamplePrimes" -> primes, "RegulatorValues" -> regulatorValues,
    "HeldOutPrime" -> heldOutPrime,
    "HeldOutRegulatorValue" -> heldOutRegulatorValue,
    "HeldOutSolution" -> heldOutSolution,
    "ModularSolutions" -> Association[KeyValueMap[
      #1 -> KeyTake[#2, {"Rank", "Nullity", "PivotSignature",
        "ParticularSolution"}] &, solutions]],
    "ExactLift" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Status", None] &, lifts]],
    "ExactLiftVectors" -> Association[KeyValueMap[
      #1 -> Lookup[#2, "Vector", Missing["NotLifted"]] &, lifts]],
    "ExactChannelResidual" -> exactChecks,
    "GaugeChannels" -> Lookup[unpacked, "GaugeChannels",
      Missing["NotLifted"]],
    "Gauge" -> Lookup[unpacked, "Gauge", Missing["NotLifted"]],
    "Residues" -> Lookup[unpacked, "Residues", Missing["NotLifted"]],
    "BranchCertificate" -> branchCertificate,
    "DifferentialCheck" -> KeyTake[differential,
      {"Status", "Passed", "Method", "Prime", "RegulatorValue",
       "Point", "Points", "BranchFlipMask"}],
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
