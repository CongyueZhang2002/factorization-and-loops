(* The direct root-channel off-diagonal off-diagonal block equation solver (2026-08-23).

   An off-diagonal block whose entries live in a multiquadratic
   coefficient field Q(sqrt(delta_1),...,sqrt(delta_r)) and whose root
   set has NO joint rational chart cannot go through
   SolveOffDiagonalBasisTransformationBlock (it stops with NoCataloguedRationalizingParametrization).  This
   module solves such a block directly in the grade basis of
   MultiquadraticAlgebra.wl: the ansatz

     G_ij = Sum_{grade,monomial} g[i,j,grade,monomial] x^p y^q / Q(x,y) r_grade

   with constant unknowns g and constant residues R, forced by

     d_mu G - eps (E_mu G - G C_mu) + eps Sum_a R_a omega_a,mu = Bbar_mu

   (the package off-diagonal block equation convention: dG = eps (e G - G c) + inhomogeneity -
   eps Sum_a R_a dlog L_a).  Each grade of that identity is a separate
   rational equation, so one modular point contributes
   2^r * 2 * upper * lower equations and no square root of the field is
   ever taken during assembly.

   This implementation promotes audited prototypes covering compilation,
   prime forms, regulator collapse, point and sample assembly, sign
   transforms, differential checks, component decomposition, one-form
   bases, denominator construction, canonical affine solves, unpacking,
   exact channel residuals, and an independent split-sign row assembly.

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
     - artifact hydration uses the context-guarded artifact reader and
       validates the stored mathematical data directly;
     - every failure is a typed Association whose "Status" names the
       failure; no entry point returns a bare $Failed.  The four channel
       primitives (multiquadraticFieldDecompose / FieldInverse /
       FieldCompose / LiftLocalChannels) keep the source's $Failed
       sentinel: the tensor compilers detect a failed leaf structurally
       with FreeQ, which an Association would defeat;
     - an explicitly requested plan-discovery backend fails closed
       rather than falling through to the Wolfram path (handoff
       existing-defect 1).

   Reused instead of ported: the off-diagonal block equation adapter's TRCurrentRoots,
   The retired prototype's classifier and sign-change helper were the package's
   coefficientPresentationSquareRootsInVariables, transportChartRootIndices and
   transportChartApplyRootBranches; only the census matcher is
   tightened here (see multiquadraticOffDiagonalBlockRootCensus).

   Deliberately NOT ported in this pass:
     - the retired DRCA serialization cache: it
       is a campaign-scale I/O layer for reusing one compiled system
       across pool workers, and the promotion gate is prepare /
       assemble / verify.  The context-explicit reader below is the
       piece that layer needed and the piece the handoff faulted;
     - the CRT + Thiele rational-in-epsilon interpolation batch of
       TripleRootReconstructionPrototype.wl.  The exact lift here is
       per regulator value (CRT over the sampled primes plus rational
       reconstruction of the canonical particular solution), which is
       what a modular-consistency certificate needs; reconstructing the
       regulator dependence of the basis-transformation block belongs to the installation
       route that gap 2 blocks;
      - the whole-equation square-root-component round trip
       reporter.  Its statement (every entry decomposes and recomposes
       exactly) is made inside the compiler, per scalar, by
       multiquadraticOffDiagonalBlockDecomposeScalar, and a separate report of it
       would be a second source of truth. *)

(* Finite-field primitives (round-4 consolidation, 2026-09-02).  The
   residue test at every split-point site is modularResidueQ and the
   square roots are multiquadraticSquareRoots (modularSquareRoots), both
   Core/ModularArithmetic.wl; the two screens carried their own
   PowerMod[delta, (p+1)/4, p] plus square check until this date --
   identical for the p == 3 (mod 4) primes the screens admit.  Three
   bodies stay local, deliberately:
     - a radicand at a point is evaluated by multiquadraticOffDiagonalBlockModRational
       (exact Together, then ONE reduction) and the solver needs those
       reduced values for the roots; the retired modularSplitPointQ
       (Scripts/Diagnostics/ModularSplitPoints.wl) reduces literal by
       literal and refuses a coefficient denominator divisible by p even
       when it cancels;
     - the fresh-image primes of multiquadraticOffDiagonalBlockFreshResidueScreenImages
       and multiquadraticOffDiagonalBlockFreshScreenImages are
       NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]] under
       RandomSeeding -> seed + 104729 (3 mod 4, unseen, distinct);
       modularPrimes' "Random" draw is RandomPrime on [2^30, 2^31) under
       SeedRandom[seed], a different sequence, and a different sequence
       would rename the primes recorded in every stored screen-evidence
       record;
     - the regulator lift of multiquadraticOffDiagonalBlockReconstructRegulator uses
       the Core primitives through FiniteFieldEpsForm.wl
       (epsFormFiniteFieldCombineCoordinate / RationalReconstruct /
       ImageQ) but keeps its own loop because it reports the POSITION of
       every unreconstructible coefficient ("UnresolvedCoefficientLocations"),
       which its prime-schedule extension consumes; modularLift returns a
       bare $Failed. *)

(* The off-diagonal block equation solver is eight files since round 4 of the overhaul
   (2026-09-02; Codex review of that morning): this file carries the data-layout contract,
   the globals, the shared utilities and the prepare-checkpoint
   persistence primitives; the other seven, in load order
   (Private/LoadOrder.wl), are MultiquadraticOffDiagonalBlockLetters.wl,
   MultiquadraticOffDiagonalBlockScreens.wl, MultiquadraticOffDiagonalBlockPrepareCompile.wl,
   MultiquadraticOffDiagonalBlockSampling.wl, MultiquadraticOffDiagonalBlockProviders.wl,
   MultiquadraticOffDiagonalBlockReconstruction.wl and MultiquadraticOffDiagonalBlockDriver.wl.
   Every definition was moved verbatim; each file clears only the symbols
   it defines, so re-reading one file never erases another's definitions.
   All eight share the context FeynFacet`Private`. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticOffDiagonalBlockStageLogQ,
  multiquadraticOffDiagonalBlockProgressInterval,
  multiquadraticOffDiagonalBlockStageText,
  multiquadraticOffDiagonalBlockStageStart,
  multiquadraticOffDiagonalBlockStageDone,
  multiquadraticOffDiagonalBlockStageProgress,
  multiquadraticOffDiagonalBlockStageMark,
  $multiquadraticOffDiagonalBlockProgressLastTime,
  $multiquadraticOffDiagonalBlockStageStartTime,
  $multiquadraticOffDiagonalBlockStageLog,
  multiquadraticOffDiagonalBlockFailure,
  $multiquadraticOffDiagonalBlockInhomogeneityChannelSchema,
  multiquadraticOffDiagonalBlockInhomogeneityChannelRecord,
  multiquadraticOffDiagonalBlockInhomogeneityChannelsAccept,
  $multiquadraticOffDiagonalBlockPrepareCheckpointSchema,
  $multiquadraticOffDiagonalBlockPrepareCheckpointSubstages,
  multiquadraticOffDiagonalBlockPrepareCheckpointFile,
  multiquadraticOffDiagonalBlockPrepareCheckpointRecord,
  multiquadraticOffDiagonalBlockPrepareCheckpointAccept,
  multiquadraticOffDiagonalBlockCanonicalRules,
  multiquadraticOffDiagonalBlockCanonicalExpression,
  multiquadraticOffDiagonalBlockContextFreeQ,
  multiquadraticOffDiagonalBlockZeroQ,
  multiquadraticOffDiagonalBlockModRational,
  multiquadraticFieldPathStatistics,
  multiquadraticFieldPathStatisticsDelta,
  multiquadraticOffDiagonalBlockDeadlineQ,
  multiquadraticOffDiagonalBlockDeadlineExpiredQ,
  multiquadraticOffDiagonalBlockBudgetExhausted,
  multiquadraticOffDiagonalBlockDeadlineCheckpoint,
  $multiquadraticOffDiagonalBlockActiveDeadline,
  $multiquadraticOffDiagonalBlockDeadlineTag,
  $multiquadraticOffDiagonalBlockMaximumRootCount,
  $multiquadraticOffDiagonalBlockMaximumEpsilonDegree,
  $multiquadraticOffDiagonalBlockWordPrimeLimit,
  $multiquadraticOffDiagonalBlockFreivaldsProjections,
  $multiquadraticOffDiagonalBlockPrimeCache,
  $multiquadraticOffDiagonalBlockEpsilonCache,
  $multiquadraticOffDiagonalBlockDefaultPrimes,
  $multiquadraticOffDiagonalBlockPrimePool,
  $multiquadraticOffDiagonalBlockWideDefaultPrimes,
  $multiquadraticOffDiagonalBlockWidePrimePool,
  multiquadraticOffDiagonalBlockWidePrimeScheduleQ,
  $multiquadraticOffDiagonalBlockValidationPrimePool,
  $multiquadraticOffDiagonalBlockDefaultRegulatorValues,
  $multiquadraticFieldRootFreeFastPathCount,
  $multiquadraticFieldAlgebraicPathCount,
  $multiquadraticFieldComposeCheckCount
];

$multiquadraticOffDiagonalBlockMaximumRootCount = 3;
$multiquadraticOffDiagonalBlockMaximumEpsilonDegree = 256;
$multiquadraticOffDiagonalBlockWordPrimeLimit = 2^63;
$multiquadraticOffDiagonalBlockPrimeCache = <||>;
$multiquadraticOffDiagonalBlockEpsilonCache = <||>;

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
   existing line on the prepare / basis-transformation block-screen / compile path is emitted
   when a stage has ALREADY FINISHED and nothing announces that one has
   started.

   These helpers are that announcement and nothing else.  No result
   mathematical payload or artifact changes: every caller below uses
   them for their side effect and discards the returned Boolean.

   They follow "Verbose", they do not override it (Codex 14:30): a
   library call that was asked to be quiet stays quiet.  The top level
   Blocks $multiquadraticOffDiagonalBlockStageLog from its own "Verbose" option, so
   the production driver -- which already solves off-diagonal block equations verbosely -- gets
   the lines and a quiet caller gets none.  FACET_MQ_STAGE_LOG=On forces
   them on for a run that cannot pass an option (a pool mission),
   FACET_MQ_STAGE_LOG=Off forces them off;
   FACET_MQ_PROGRESS_SECONDS sets the interior progress interval,
   default 60 s, matching the deferred-materialize convention of
   BlockEquationDeferred.wl. *)
$multiquadraticOffDiagonalBlockProgressLastTime = <||>;
$multiquadraticOffDiagonalBlockStageStartTime = <||>;
$multiquadraticOffDiagonalBlockStageLog = False;

multiquadraticOffDiagonalBlockStageLogQ[] := Module[
  {value = Environment["FACET_MQ_STAGE_LOG"]},
  Which[value === "On", True, value === "Off", False,
    True, TrueQ[$multiquadraticOffDiagonalBlockStageLog]]];

multiquadraticOffDiagonalBlockProgressInterval[] :=
  Module[{value = Environment["FACET_MQ_PROGRESS_SECONDS"]},
    (* N[...] deliberately, as in BlockEquationDeferred.wl: Max[0, 60]
       returns the INTEGER 60 and a caller comparing it against a
       machine number would see a type it did not expect *)
    If[StringQ[value] && StringMatchQ[value, NumberString],
      N[Max[0, ToExpression[value]]], 60.]];

(* None-valued entries are dropped: the in-frame dispatcher hands this
   engine a bare {Variables, Regulator, OffDiagonalBlock} record with no family or
   sector, and "family None, sector None, lower None" on every line is
   noise, not information. *)
multiquadraticOffDiagonalBlockStageText[stage_String, data_Association] := Module[
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
multiquadraticOffDiagonalBlockStageStart[stage_String, data_Association : <||>] := (
  If[multiquadraticOffDiagonalBlockStageLogQ[],
    $multiquadraticOffDiagonalBlockProgressLastTime[stage] = AbsoluteTime[];
    $multiquadraticOffDiagonalBlockStageStartTime[stage] = AbsoluteTime[];
    Print[multiquadraticOffDiagonalBlockStageText[stage <> " start", data]]];
  True);

multiquadraticOffDiagonalBlockStageDone[stage_String, data_Association : <||>] := Module[
  {start, completed = data},
  If[multiquadraticOffDiagonalBlockStageLogQ[],
    start = Lookup[$multiquadraticOffDiagonalBlockStageStartTime, stage, Missing["NoStart"]];
    If[NumberQ[start], completed = Join[completed,
      <|"elapsedSeconds" -> N[AbsoluteTime[] - start]|>]];
    Print[multiquadraticOffDiagonalBlockStageText[stage <> " done", completed]];
    KeyDropFrom[$multiquadraticOffDiagonalBlockStageStartTime, stage]];
  True
];

(* A MARK is a completed measurement of a step that had no separate
   announcement -- a sub-phase whose cost is only interesting after the
   fact.  It is deliberately not spelled "done": every "start" in this
   module has a matching "done", and a mark is neither. *)
multiquadraticOffDiagonalBlockStageMark[stage_String, data_Association : <||>] := (
  If[multiquadraticOffDiagonalBlockStageLogQ[],
    Print[multiquadraticOffDiagonalBlockStageText[stage, data]]];
  True);

(* Interior progress IS rate limited, per stage: at most one line per
   interval.  The clock starts at the stage announcement, so a stage
   that finishes inside one interval prints its start and its end and
   nothing in between. *)
multiquadraticOffDiagonalBlockStageProgress[stage_String, data_Association] := If[
  multiquadraticOffDiagonalBlockStageLogQ[] &&
    AbsoluteTime[] - Lookup[$multiquadraticOffDiagonalBlockProgressLastTime, stage,
      -Infinity] >= multiquadraticOffDiagonalBlockProgressInterval[],
  $multiquadraticOffDiagonalBlockProgressLastTime[stage] = AbsoluteTime[];
  Print[multiquadraticOffDiagonalBlockStageText[stage, data]];
  True,
  False];

(* U2 (2026-09-02): number of random row projections replayed over ALL
   original rows after a native (FLINT) constrained-core solve *)
$multiquadraticOffDiagonalBlockFreivaldsProjections = 2;

(* Sampling defaults: primes are 3 mod 4 so that every split point has
   an explicit square root (the sign-branch certificate needs one).

   CompiledChannel retains the historical 31-bit pool because its packed
   Wolfram compatibility sampler multiplies machine integers.  SplitBranch
   evaluates sparse leaves and assembles rows in FLINT nmod arithmetic, whose
   binary protocols use unsigned 64-bit words; it therefore uses the 61-bit
   pool below.  The independent validation pool deliberately remains 31-bit
   and disjoint from both reconstruction schedules. *)
$multiquadraticOffDiagonalBlockDefaultPrimes = {2147483423, 2147483399};
$multiquadraticOffDiagonalBlockPrimePool = {
  2147483423, 2147483399, 2147483587, 2147483579, 2147483563,
  2147483543, 2147483179, 2147483171, 2147483123, 2147483059,
  2147482951, 2147482943, 2147482867, 2147482859, 2147482819,
  2147482811, 2147482763, 2147482739, 2147482663, 2147482591,
  2147482583, 2147482507, 2147482367, 2147482343, 2147482327,
  2147482291, 2147482231, 2147482223, 2147482091, 2147482063,
  2147481967, 2147481907};
$multiquadraticOffDiagonalBlockWidePrimePool = {
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
$multiquadraticOffDiagonalBlockWideDefaultPrimes =
  Take[$multiquadraticOffDiagonalBlockWidePrimePool, 2];
multiquadraticOffDiagonalBlockWidePrimeScheduleQ[provider_Association] := Module[{plan},
  If[Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! StringQ[multiquadraticOffDiagonalBlockNativeRowBinary[]], Return[False]];
  (* Native deferred Inhomogeneity never consumes the bundle's split plan.  Building
     that plan here merely to choose the prime width would compile precisely
     the inhomogeneity leaves the native DAG path bypasses.  Its evaluator and the
     shared native row assembler are both 64-bit modular backends, so they
     directly admit the wide schedule. *)
  If[AssociationQ[Lookup[provider, "DeferredPreparation", None]],
    Return[StringQ[multiquadraticOffDiagonalBlockNativeDeferredBinary[]]]];
  If[! StringQ[multiquadraticOffDiagonalBlockNativeSparseBinary[]], Return[False]];
  (* Building this plan is not an extra production pass: the sampler needs
     the same provider/prime plan, and the established plan cache makes that
     later lookup free.  Wide Automatic is admitted only when every leaf can
     remain in native modular arithmetic. *)
  plan = Quiet[Check[multiquadraticOffDiagonalBlockSplitSparseEvaluationPlan[
      provider, First[$multiquadraticOffDiagonalBlockWidePrimePool]], $Failed]];
  AssociationQ[plan] &&
    Lookup[plan, "Status", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[plan, "FallbackLeafCount", -1] === 0
];
multiquadraticOffDiagonalBlockWidePrimeScheduleQ[_] := False;
$multiquadraticOffDiagonalBlockValidationPrimePool = {
  2147483323, 2147481899, 2147481883, 2147481863, 2147481827,
  2147481811, 2147481571, 2147481563};
$multiquadraticOffDiagonalBlockDefaultRegulatorValues = {1/13, 3/17};

multiquadraticOffDiagonalBlockFailure[status_String, data_: <||>] := Join[
  <|"Status" -> status, "Module" -> "MultiquadraticOffDiagonalBlockSolve"|>, data];

(* Cooperative deadline (2026-08-24).  "Deadline" is an absolute
   AbsoluteTime[] value, Infinity by default.  It is read at natural unit
   boundaries only -- between primes, between regulator values, between
   sign branches, between exact lifts -- never inside the modular
   arithmetic, and it is NOT TimeConstrained: TimeConstrained does not
   bound task-broker helpers and has escaped in pool subkernels before
   (CLAUDE.md).  Expiry is a typed result, like every other outcome of
   this module: no $Aborted, no exception, no bare $Failed. *)
multiquadraticOffDiagonalBlockDeadlineQ[deadline_] :=
  deadline === Infinity || (NumericQ[deadline] && Positive[deadline]);

multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline_] :=
  NumericQ[deadline] && AbsoluteTime[] >= deadline;

multiquadraticOffDiagonalBlockBudgetExhausted[stage_String, elapsed_, deadline_,
    progress_Association] := multiquadraticOffDiagonalBlockFailure["BudgetExhausted",
  Join[<|"Stage" -> stage, "Elapsed" -> elapsed, "Deadline" -> deadline,
    "Method" -> "DirectRootChannel", "Resumable" -> True|>, progress]];

(* ---- cooperative deadline INSIDE the preparation (2026-08-25) ------

   multiquadraticOffDiagonalBlockPrepare had no interior deadline coverage at all:
   the driver checked once before entering it and "Deadline" was not
   among its options, so FilterRules dropped it.  A mission that entered
   first-call prepare could therefore not be stopped by its sector
   budget until prepare returned -- measured live at more than 51 minutes
   on a production block, which is the last stage of this engine
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
$multiquadraticOffDiagonalBlockActiveDeadline = Infinity;
$multiquadraticOffDiagonalBlockDeadlineTag = "MultiquadraticOffDiagonalBlockPrepareDeadline";

multiquadraticOffDiagonalBlockDeadlineCheckpoint[substage_String,
    progress_Association] := If[
  $multiquadraticOffDiagonalBlockActiveDeadline =!= Infinity &&
    AbsoluteTime[] >= $multiquadraticOffDiagonalBlockActiveDeadline,
  Throw[Join[<|"Substage" -> substage|>, progress],
    $multiquadraticOffDiagonalBlockDeadlineTag],
  False];

(* A channel decomposition is an internal computational intermediate.
   It carries the mathematical data from which it was obtained, not a
   digest or an implementation identity.  The final off-diagonal block equation acceptance
   re-evaluates the transformed differential equation independently, so
   this boundary needs only reject reuse for a different mathematical
   problem; it must not duplicate that final validation. *)
$multiquadraticOffDiagonalBlockInhomogeneityChannelSchema =
  "MultiquadraticInhomogeneityChannelsV3";

multiquadraticOffDiagonalBlockInhomogeneityChannelRecord[channels_, inhomogeneity_, roots_List,
    variables_List, epsilon_] := Module[{rules, rootDefiningData},
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  rootDefiningData = (<|"Generator" -> squareRootRecordExpression[#],
      "QuadraticRadicand" -> squareRootRecordRadicand[#]|> &) /@ roots;
  <|"Schema" -> $multiquadraticOffDiagonalBlockInhomogeneityChannelSchema,
    "SchemaVersion" -> 3,
    "DefiningData" -> ({inhomogeneity, rootDefiningData} /. rules),
    "GradeCount" -> 2^Length[roots],
    "Dimensions" -> Dimensions[inhomogeneity],
    "Channels" -> channels|>
];

(* "NotSupplied" (decompose), "Accepted" (reuse), or a typed refusal that
   the caller turns into a failure record *)
multiquadraticOffDiagonalBlockInhomogeneityChannelsAccept[supplied_, inhomogeneity_, roots_List,
    variables_List, epsilon_] := Module[
  {definingData, rootDefiningData, gradeCount, channels, schema},
  If[supplied === Automatic || MissingQ[supplied] || supplied === None,
    Return[<|"Status" -> "NotSupplied"|>]];
  If[! AssociationQ[supplied],
    Return[<|"Status" -> "InhomogeneityChannelRecordExpected"|>]];
  schema = Lookup[supplied, "Schema", None];
  If[schema =!= $multiquadraticOffDiagonalBlockInhomogeneityChannelSchema,
    Return[<|"Status" -> "InhomogeneityChannelSchemaUnsupported",
      "SuppliedSchema" -> schema|>]];
  gradeCount = 2^Length[roots];
  channels = Lookup[supplied, "Channels", $Failed];
  If[! ArrayQ[channels, 4] ||
      Dimensions[channels] =!= Append[Dimensions[inhomogeneity], gradeCount] ||
      ! FreeQ[channels, $Failed],
    Return[<|"Status" -> "InhomogeneityChannelShapeMismatch",
      "Expected" -> Append[Dimensions[inhomogeneity], gradeCount],
      "Actual" -> Dimensions[channels]|>]];
  rootDefiningData = (<|"Generator" -> squareRootRecordExpression[#],
      "QuadraticRadicand" -> squareRootRecordRadicand[#]|> &) /@ roots;
  definingData = {inhomogeneity, rootDefiningData} /.
    multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  If[! SameQ[
      Lookup[supplied, "DefiningData", Missing[]] /.
        multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
      definingData],
    Return[<|"Status" -> "InhomogeneityChannelDefiningDataMismatch"|>]];
  <|"Status" -> "Accepted", "Channels" -> channels|>
];

(* ---- PREPARE INTERMEDIATE PERSISTENCE (2026-08-25) ------------------

   Preparation is the engine's long stage and it checkpointed NOTHING: a
   cancelled or budget-stopped run threw away every completed substage
   and the next attempt started from zero.  Production measurements show
   that this repeated work is material.

   Each expensive substage boundary now writes ONE self-describing
   record, and a resumed preparation may read it back instead of
   recomputing.  The three boundaries are exactly the three the
   cooperative deadline already names -- "InhomogeneityChannels",
   "CandidateLetters", "OffDiagonalBasisTransformationDenominator" -- so a stop and a checkpoint
   speak the same vocabulary.

   A checkpoint stores the mathematical input of its substage directly.
   Resume admission compares that input after mapping the caller's variable
   names to the module's formal symbols.  Backend choices and source-file
   identity are deliberately absent.  Subsequent stage predicates and the
   final off-diagonal block equation acceptance validate the mathematical result.

   CONTEXT.  Payloads are written in the formal System` symbols and
   mapped back on read, so a checkpoint written under Global` and read
   after CANONICA has taken over eps/x/y is the same object. *)
$multiquadraticOffDiagonalBlockPrepareCheckpointSchema =
  "MultiquadraticPrepareCheckpointV2";

$multiquadraticOffDiagonalBlockPrepareCheckpointSubstages = {
  "InhomogeneityChannels", "CandidateLetters", "OffDiagonalBasisTransformationDenominator"};

multiquadraticOffDiagonalBlockPrepareCheckpointFile[directory_, tag_String,
    substage_String] :=
  FileNameJoin[{directory, tag <> "_prepare_" <>
    ToLowerCase[substage] <> ".wl"}];

multiquadraticOffDiagonalBlockPrepareCheckpointRecord[substage_String,
    definingInput_, payload_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {canonicalInput, canonicalPayload, rules},
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  canonicalInput = definingInput /. rules;
  canonicalPayload = payload /. rules;
  If[! multiquadraticOffDiagonalBlockContextFreeQ[{canonicalInput, canonicalPayload}],
    Return[$Failed]];
  <|"Schema" -> $multiquadraticOffDiagonalBlockPrepareCheckpointSchema,
    "SchemaVersion" -> 2,
    "Substage" -> substage,
    "DefiningInput" -> canonicalInput,
    "Payload" -> canonicalPayload|>
];
multiquadraticOffDiagonalBlockPrepareCheckpointRecord[___] := $Failed;

(* "Accepted" with the payload in the caller's symbols, or a typed
   refusal.  Nothing here recomputes and nothing here repairs. *)
multiquadraticOffDiagonalBlockPrepareCheckpointAccept[record_, substage_String,
    definingInput_, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Module[{canonicalInput},
  If[! AssociationQ[record] ||
      Lookup[record, "Schema", None] =!=
        $multiquadraticOffDiagonalBlockPrepareCheckpointSchema,
    Return[<|"Status" -> "PrepareCheckpointSchemaUnknown",
      "Substage" -> substage,
      "SuppliedSchema" -> If[AssociationQ[record],
        Lookup[record, "Schema", None], Missing["NotAnAssociation"]]|>]];
  If[Lookup[record, "Substage", None] =!= substage,
    Return[<|"Status" -> "PrepareCheckpointSubstageMismatch",
      "Substage" -> substage,
      "SuppliedSubstage" -> Lookup[record, "Substage", None]|>]];
  canonicalInput = definingInput /.
    multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  If[! SameQ[Lookup[record, "DefiningInput", Missing[]], canonicalInput],
    Return[<|"Status" -> "PrepareCheckpointInputMismatch",
      "Substage" -> substage|>]];
  <|"Status" -> "Accepted", "Substage" -> substage,
    "Payload" -> (record["Payload"] /.
      (Reverse /@ multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon]))|>
];
multiquadraticOffDiagonalBlockPrepareCheckpointAccept[___] :=
  <|"Status" -> "PrepareCheckpointInvalidArguments"|>;

multiquadraticOffDiagonalBlockZeroQ[value_] :=
  AllTrue[Flatten[{value}], TrueQ[Together[#1] === 0] &];

multiquadraticOffDiagonalBlockModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

(* Map coefficient variables and epsilon to formal System` symbols so
   persisted mathematical expressions compare independently of context. *)
multiquadraticOffDiagonalBlockCanonicalRules[variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  Join[Thread[variables -> {\[FormalX], \[FormalY]}], {epsilon -> \[FormalE]}];

multiquadraticOffDiagonalBlockCanonicalExpression[expression_, rules_List] := Module[
  {rational = Together[expression /. rules]},
  {Expand[Numerator[rational]], Expand[Denominator[rational]]}
];

multiquadraticOffDiagonalBlockContextFreeQ[value_] := AllTrue[
  DeleteDuplicates[Cases[value, symbol_Symbol :> symbol, {0, Infinity},
    Heads -> True]],
  Context[#1] === "System`" &];

(* Canonical text for a payload field.  The context freedom is decided
   on the EXPRESSION, not on its printed form: a Global` symbol prints
   without its context whenever Global` happens to be on the context
   path, so a textual backtick test would pass exactly when the reader
   is the one that made the text ambiguous. *)
multiquadraticOffDiagonalBlockCanonicalText[expression_, rules_List] := Module[
  {canonical = multiquadraticOffDiagonalBlockCanonicalExpression[expression, rules]},
  If[! multiquadraticOffDiagonalBlockContextFreeQ[canonical], $Failed,
    ToString[InputForm[canonical]]]
];

End[];
