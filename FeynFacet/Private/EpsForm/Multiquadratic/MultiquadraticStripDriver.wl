(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripDriver.wl -- part 8 of 8 of the
   multiquadratic strip solver (split from MultiquadraticStripSolve.wl in
   round 4, 2026-09-02, pure moves): artifact persistence (raw load separate from validation), option gates,
   cache clearing, and the top-level entry point
   solveEpsFormStripMultiquadratic with its terminal acceptance.
   Loads after the preceding parts (Private/LoadOrder.wl); shared data,
   globals and the shared utilities are in MultiquadraticStripSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripArtifactWrite,
  multiquadraticStripArtifactLoadRaw,
  multiquadraticStripReadPreparedArtifact,
  multiquadraticStripOptionNames,
  multiquadraticStripProductionOptionGate,
  multiquadraticStripBackendGate,
  multiquadraticStripClearCaches,
  solveEpsFormStripMultiquadratic
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
  <|"Status" -> "MultiquadraticArtifactWritten", "File" -> file|>
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
    "Messages" -> ToString[messages]|>
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
          "Context" -> context, "Preparation" -> value|>,
        multiquadraticStripFailure["ArtifactPreparationInvalid",
          <|"File" -> file|>]],
    Lookup[value, "Status", None] === "CompiledMultiquadraticStripV1",
      If[multiquadraticStripCompiledValidQ[value],
        <|"Status" -> "HydratedMultiquadraticAssembly", "File" -> file,
          "Context" -> context, "Assembly" -> value|>,
        multiquadraticStripFailure["ArtifactAssemblyInvalid",
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

     This is an optional obstruction study, not part of production solving.
     True runs it and stops on a confirmed inconsistency within the tested
     ansatz; False skips it.  Production must not pay for an advisory screen
     that cannot affect the result. *)
  "ScreenFirst" -> False,
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
  (* Production validates the reconstructed object at fresh kinematic and
     regulator points over primes not used for reconstruction.  Explicit True
     remains available for an offline symbolic study, but Automatic never
     selects it. *)
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
   allPrimes, samples = <||>, solutions = <||>, sample, solution, structure,
   lifts = <||>, exactChecks = <||>, heldOutSolution,
   freshProviderChecks, freshReference, branchCertificate, branchMask,
   transformedSample, differential, liftedVector, unpacked, prime,
   regulatorValue, samplerOptions, deadline, budgetProgress,
   budgetExhausted, enrich, variables, epsilon, strip, allRoots, classification,
   deferredBundle, deferredASTWrapper, deferredASTPreparation,
   deferredASTInputFile, deferredASTSourceQ, deferredASTPresentation,
   deferredASTPresentationRoots, deferredASTGeneratorIndices,
   deferredASTRoots, deferredASTRootIndices, deferredASTSelectedIndices,
   deferredASTGeneratorValidation, slimDeferredLayout,
   bundleIndices,
   requiredRootIndices, rootIndices, order,
    suppliedRootClassification, suppliedRootClassificationValidQ,
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
    allRoots = coefficientPresentationSquareRootsInVariables[frame, variables];
    If[ListQ[allRoots],
      suppliedRootClassification = OptionValue["RootClassification"];
      suppliedRootClassificationValidQ =
        AssociationQ[suppliedRootClassification] &&
        AssociationQ[deferredBundle] &&
        Lookup[blockEquationDeferredBundleValidate[deferredBundle],
          "Status", None] === "BundleValid" &&
        AllTrue[{"RadicalBases", "UnclassifiedRadicalBases"},
          KeyExistsQ[suppliedRootClassification, #1] &];
      multiquadraticStripStageStart["outer root census",
        <|"supplied" -> suppliedRootClassificationValidQ|>];
      classification = multiquadraticStripRootCensusWithBundle[strip, allRoots,
        variables, epsilon, deferredBundle,
        If[suppliedRootClassificationValidQ, suppliedRootClassification,
          Automatic]];
      (* The dense BBar is a zero-shape placeholder on the raw native route,
         exactly as it is for a DeferredBundle.  Union the square-root
         generators bound by the preparation wrapper before alphabet/grade
         construction; otherwise the visible strip silently collapses a
         genuine rank-3 forcing to the diagonal's rank-1 field. *)
      If[deferredASTSourceQ && ! AssociationQ[deferredBundle],
        deferredASTPresentation = masterTransportCoefficientPresentationData[
          Lookup[deferredASTWrapper, "CoefficientPresentation",
            Missing["NoCoefficientPresentation"]], variables];
        deferredASTPresentationRoots =
          coefficientPresentationSquareRootsInVariables[
            deferredASTPresentation, variables];
        deferredASTGeneratorIndices = Lookup[deferredASTWrapper,
          "SquareRootGeneratorIndices", $Failed];
        If[Lookup[deferredASTPresentation, "Status", None] =!= "OK" ||
            ! ListQ[deferredASTPresentationRoots] ||
            ! VectorQ[deferredASTGeneratorIndices, IntegerQ] ||
            ! ContainsOnly[deferredASTGeneratorIndices,
              Range[Length[deferredASTPresentationRoots]]] ||
            deferredASTGeneratorIndices =!=
              Sort[DeleteDuplicates[deferredASTGeneratorIndices]],
          Return[multiquadraticStripFailure[
            "DeferredPreparationCoefficientPresentationInvalid"]]];
        deferredASTRoots =
          deferredASTPresentationRoots[[deferredASTGeneratorIndices]];
        deferredASTRootIndices = Table[Module[{matches},
            matches = Flatten[Position[allRoots,
              candidate_ /; TrueQ[Quiet[Together[
                    squareRootRecordExpression[candidate] -
                      squareRootRecordExpression[root]]] === 0] &&
                  TrueQ[Quiet[Together[
                    squareRootRecordRadicand[candidate] -
                      squareRootRecordRadicand[root]]] === 0],
              {1}, Heads -> False]];
            If[Length[matches] =!= 1,
              Return[multiquadraticStripFailure[
                "DeferredPreparationSquareRootGeneratorMismatch",
                <|"SquareRootGenerator" -> root,
                  "Matches" -> matches|>],
                Module]];
            First[matches]],
          {root, deferredASTRoots}];
        If[! VectorQ[deferredASTRootIndices, IntegerQ],
          Return[FirstCase[deferredASTRootIndices,
            failure_Association :> failure,
            multiquadraticStripFailure[
              "DeferredPreparationSquareRootGeneratorMismatch"]]]];
        deferredASTSelectedIndices = DeleteDuplicates[Join[
          Lookup[classification, "RootIndices", {}],
          deferredASTRootIndices]];
        deferredASTGeneratorValidation =
          blockEquationDeferredValidateSquareRootGenerators[
            allRoots[[deferredASTSelectedIndices]], variables, epsilon];
        If[Lookup[deferredASTGeneratorValidation, "Status", None] =!=
            "SquareRootGeneratorsValidated",
          Return[multiquadraticStripFailure[
            "DeferredPreparationSquareRootGeneratorUnionInvalid",
            <|"Detail" -> deferredASTGeneratorValidation|>]]];
        classification = Join[classification, <|
          "BundleRootIndices" -> deferredASTRootIndices,
          "RequiredRootIndices" -> deferredASTSelectedIndices|>]];
      multiquadraticStripStageDone["outer root census",
        <|"source" -> If[suppliedRootClassificationValidQ,
          "SameCall", "Fresh"]|>];
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
      TrueQ[OptionValue["ScreenFirst"]] &&
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
              "ALPHABET, SUPPORT AND DENOMINATOR ANSATZ, ",
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
  (* The preparation object was built in this call and its forcing channels
     are reused directly, so the
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
        Lookup[preparation, "DeferredBundle", Automatic]]];
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
      If[! SameQ[nextLayout["CoefficientData"],
          reusableProvider["CoefficientData"]],
        Return[multiquadraticStripFailure[
          "ProviderSupportCoefficientDataChanged",
          <|"DegreeOffset" -> offset,
            "Expected" -> reusableProvider["CoefficientData"],
            "Observed" -> nextLayout["CoefficientData"]|>],
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
    multiquadraticStripWidePrimeScheduleQ[provider], False];
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
          "ProviderPoints"],
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
  structure = Lookup[reconstruction, {"Rank", "Nullity",
    "PivotColumns"}, Missing["NotReconstructed"]];
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
    "Rank" -> structure[[1]], "Nullity" -> structure[[2]],
    "PivotColumns" -> reconstruction["PivotColumns"],
    "FreeColumns" -> reconstruction["FreeColumns"],
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
      "AdoptedDegreeOffset" -> adoptedDegreeOffset,
      "IntegrabilityScreen" -> KeyTake[screen, {"Status", "Reason"}],
      "GaugeScreen" -> If[AssociationQ[gaugeScreen],
        KeyTake[gaugeScreen, {"Status", "Reason"}],
        <|"Status" -> "GaugeScreenSkipped"|>],
      "RegulatorReconstruction" -> KeyTake[reconstruction,
        {"Status", "Method", "Provider", "CoefficientData",
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
          "StructuralPilotCacheHitCount", "ModalStructuralStructure",
          "ModalReferencePrime", "ModalReferenceRegulatorValue",
          "ImagePhaseRecords", "TrainingImageKeys", "PhaseSeconds",
          "Seconds"}],
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
      {"Status", "Method", "Provider", "CoefficientData", "SamplePrimes",
       "UnseenPrime",
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
       "StructuralPilotCacheHitCount", "ModalStructuralStructure",
       "ModalReferencePrime", "ModalReferenceRegulatorValue",
       "FollowerImageKernelCountRequested",
       "FollowerImageMaximumConcurrency",
       "FollowerImageNativeThreadCeiling",
       "FollowerImageParallelWaveCount", "FollowerImageSerialWaveCount",
       "FollowerImageParallelCount", "FollowerImageSerialCount",
       "FollowerImageWaveRecords", "ImagePhaseRecords",
       "TrainingImageKeys", "PhaseSeconds", "Seconds"}],
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
    "PreparationSchema" -> Lookup[preparation, "PreparationSchema",
      Missing["PreparationSchema"]],
    "CoefficientProvider" -> provider["Kind"],
    "Rank" -> structure[[1]], "Nullity" -> structure[[2]],
    "PivotColumns" -> reconstruction["PivotColumns"],
    "FullAffineSolveCount" -> Lookup[reconstruction,
      "FullAffineSolveCount", Missing["NotRecorded"]],
    "PostReconstructionAffineSolveCount" -> 0,
    "SamplePrimes" -> primes, "RegulatorValues" -> regulatorValues,
    "HeldOutPrime" -> heldOutPrime,
    "HeldOutRegulatorValue" -> heldOutRegulatorValue,
    "HeldOutSolution" -> heldOutSolution,
    "ModularSolutions" -> Association[KeyValueMap[
      #1 -> KeyTake[#2, {"Rank", "Nullity", "PivotColumns",
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
