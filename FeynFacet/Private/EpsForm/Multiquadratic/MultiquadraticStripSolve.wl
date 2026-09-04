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

(* Finite-field primitives (round-4 consolidation, 2026-09-02).  The
   residue test at every split-point site is modularResidueQ and the
   square roots are multiquadraticSquareRoots (modularSquareRoots), both
   Core/ModularArithmetic.wl; the two screens carried their own
   PowerMod[delta, (p+1)/4, p] plus square check until this date --
   identical for the p == 3 (mod 4) primes the screens admit.  Three
   bodies stay local, deliberately:
     - a radicand at a point is evaluated by multiquadraticStripModRational
       (exact Together, then ONE reduction) and the solver needs those
       reduced values for the roots; the retired modularSplitPointQ
       (Scripts/Diagnostics/ModularSplitPoints.wl) reduces literal by
       literal and refuses a coefficient denominator divisible by p even
       when it cancels;
     - the fresh-image primes of multiquadraticStripFreshResidueScreenImages
       and multiquadraticStripFreshScreenImages are
       NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]] under
       RandomSeeding -> seed + 104729 (3 mod 4, unseen, distinct);
       modularPrimes' "Random" draw is RandomPrime on [2^30, 2^31) under
       SeedRandom[seed], a different sequence, and a different sequence
       would rename the primes recorded in every stored screen-evidence
       record;
     - the regulator lift of multiquadraticStripReconstructRegulator uses
       the Core primitives through FiniteFieldEpsForm.wl
       (epsFormFiniteFieldCombineCoordinate / RationalReconstruct /
       ImageQ) but keeps its own loop because it reports the POSITION of
       every unreconstructible coefficient ("UnresolvedCoefficientLocations"),
       which its prime-schedule extension consumes; modularLift returns a
       bare $Failed. *)

(* The strip solver is eight files since round 4 of the overhaul
   (2026-09-02; Codex review of that morning): this file carries the ABI,
   the globals, the shared utilities and the prepare-checkpoint
   persistence primitives; the other seven, in load order
   (Private/LoadOrder.wl), are MultiquadraticStripLetters.wl,
   MultiquadraticStripScreens.wl, MultiquadraticStripPrepareCompile.wl,
   MultiquadraticStripSampling.wl, MultiquadraticStripProviders.wl,
   MultiquadraticStripReconstruction.wl and MultiquadraticStripDriver.wl.
   Every definition was moved verbatim; each file clears only the symbols
   it defines, so re-reading one file never erases another's definitions.
   All eight share the context FeynFacet`Private`. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripStageLogQ,
  multiquadraticStripProgressInterval,
  multiquadraticStripStageText,
  multiquadraticStripStageStart,
  multiquadraticStripStageDone,
  multiquadraticStripStageProgress,
  multiquadraticStripStageMark,
  $multiquadraticStripProgressLastTime,
  $multiquadraticStripStageStartTime,
  $multiquadraticStripStageLog,
  multiquadraticStripFailure,
  $multiquadraticStripForcingChannelSchema,
  multiquadraticStripForcingChannelRecord,
  multiquadraticStripForcingChannelsAccept,
  $multiquadraticStripPrepareCheckpointSchema,
  $multiquadraticStripPrepareCheckpointSubstages,
  multiquadraticStripPrepareCheckpointFile,
  multiquadraticStripPrepareCheckpointRecord,
  multiquadraticStripPrepareCheckpointAccept,
  multiquadraticStripCanonicalRules,
  multiquadraticStripCanonicalExpression,
  multiquadraticStripContextFreeQ,
  multiquadraticStripZeroQ,
  multiquadraticStripModRational,
  multiquadraticFieldPathStatistics,
  multiquadraticFieldPathStatisticsDelta,
  multiquadraticStripDeadlineQ,
  multiquadraticStripDeadlineExpiredQ,
  multiquadraticStripBudgetExhausted,
  multiquadraticStripDeadlineCheckpoint,
  $multiquadraticStripActiveDeadline,
  $multiquadraticStripDeadlineTag,
  $multiquadraticStripMaximumRootCount,
  $multiquadraticStripMaximumEpsilonDegree,
  $multiquadraticStripWordPrimeLimit,
  $multiquadraticStripFreivaldsProjections,
  $multiquadraticStripPrimeCache,
  $multiquadraticStripEpsilonCache,
  $multiquadraticStripDefaultPrimes,
  $multiquadraticStripPrimePool,
  $multiquadraticStripWideDefaultPrimes,
  $multiquadraticStripWidePrimePool,
  multiquadraticStripWidePrimeScheduleQ,
  $multiquadraticStripValidationPrimePool,
  $multiquadraticStripDefaultRegulatorValues,
  $multiquadraticFieldRootFreeFastPathCount,
  $multiquadraticFieldAlgebraicPathCount,
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

(* A channel decomposition is an internal computational intermediate.
   It carries the mathematical data from which it was obtained, not a
   digest or an implementation identity.  The final strip acceptance
   re-evaluates the transformed differential equation independently, so
   this boundary needs only reject reuse for a different mathematical
   problem; it must not duplicate that final validation. *)
$multiquadraticStripForcingChannelSchema =
  "MultiquadraticForcingChannelsV3";

multiquadraticStripForcingChannelRecord[channels_, forcing_, roots_List,
    variables_List, epsilon_] := Module[{rules},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  <|"Schema" -> $multiquadraticStripForcingChannelSchema,
    "SchemaVersion" -> 3,
    "DefiningData" -> ({forcing, roots} /. rules),
    "GradeCount" -> 2^Length[roots],
    "Dimensions" -> Dimensions[forcing],
    "Channels" -> channels|>
];

(* "NotSupplied" (decompose), "Accepted" (reuse), or a typed refusal that
   the caller turns into a failure record *)
multiquadraticStripForcingChannelsAccept[supplied_, forcing_, roots_List,
    variables_List, epsilon_] := Module[
  {definingData, gradeCount, channels, schema},
  If[supplied === Automatic || MissingQ[supplied] || supplied === None,
    Return[<|"Status" -> "NotSupplied"|>]];
  If[! AssociationQ[supplied],
    Return[<|"Status" -> "ForcingChannelRecordExpected"|>]];
  schema = Lookup[supplied, "Schema", None];
  If[schema =!= $multiquadraticStripForcingChannelSchema,
    Return[<|"Status" -> "ForcingChannelSchemaUnsupported",
      "SuppliedSchema" -> schema|>]];
  gradeCount = 2^Length[roots];
  channels = Lookup[supplied, "Channels", $Failed];
  If[! ArrayQ[channels, 4] ||
      Dimensions[channels] =!= Append[Dimensions[forcing], gradeCount] ||
      ! FreeQ[channels, $Failed],
    Return[<|"Status" -> "ForcingChannelShapeMismatch",
      "Expected" -> Append[Dimensions[forcing], gradeCount],
      "Actual" -> Dimensions[channels]|>]];
  definingData = {forcing, roots} /.
    multiquadraticStripCanonicalRules[variables, epsilon];
  If[! SameQ[Lookup[supplied, "DefiningData", Missing[]], definingData],
    Return[<|"Status" -> "ForcingChannelDefiningDataMismatch"|>]];
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

   A checkpoint stores the mathematical input of its substage directly.
   Resume admission compares that input after mapping the caller's variable
   names to the module's formal symbols.  Backend choices and source-file
   identity are deliberately absent.  Subsequent stage predicates and the
   final strip acceptance validate the mathematical result.

   CONTEXT.  Payloads are written in the formal System` symbols and
   mapped back on read, so a checkpoint written under Global` and read
   after CANONICA has taken over eps/x/y is the same object. *)
$multiquadraticStripPrepareCheckpointSchema =
  "MultiquadraticPrepareCheckpointV2";

$multiquadraticStripPrepareCheckpointSubstages = {
  "ForcingChannels", "CandidateLetters", "GaugeDenominator"};

multiquadraticStripPrepareCheckpointFile[directory_, tag_String,
    substage_String] :=
  FileNameJoin[{directory, tag <> "_prepare_" <>
    ToLowerCase[substage] <> ".wl"}];

multiquadraticStripPrepareCheckpointRecord[substage_String,
    definingInput_, payload_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {canonicalInput, canonicalPayload, rules},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  canonicalInput = definingInput /. rules;
  canonicalPayload = payload /. rules;
  If[! multiquadraticStripContextFreeQ[{canonicalInput, canonicalPayload}],
    Return[$Failed]];
  <|"Schema" -> $multiquadraticStripPrepareCheckpointSchema,
    "SchemaVersion" -> 2,
    "Substage" -> substage,
    "DefiningInput" -> canonicalInput,
    "Payload" -> canonicalPayload|>
];
multiquadraticStripPrepareCheckpointRecord[___] := $Failed;

(* "Accepted" with the payload in the caller's symbols, or a typed
   refusal.  Nothing here recomputes and nothing here repairs. *)
multiquadraticStripPrepareCheckpointAccept[record_, substage_String,
    definingInput_, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Module[{canonicalInput},
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
  canonicalInput = definingInput /.
    multiquadraticStripCanonicalRules[variables, epsilon];
  If[! SameQ[Lookup[record, "DefiningInput", Missing[]], canonicalInput],
    Return[<|"Status" -> "PrepareCheckpointInputMismatch",
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

(* Map coefficient variables and epsilon to formal System` symbols so
   persisted mathematical expressions compare independently of context. *)
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

End[];
