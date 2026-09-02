(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripReconstruction.wl -- part 7 of 8 of the
   multiquadratic strip solver (split from MultiquadraticStripSolve.wl in
   round 4, 2026-09-02, pure moves): rational-in-epsilon reconstruction: the provider residual image and
   multiquadraticStripReconstructRegulator (CRT across primes, rational
   reconstruction, held-out validation, the prime-schedule extension).
   Loads after the preceding parts (Private/LoadOrder.wl); the ABI, the
   globals and the shared utilities are in MultiquadraticStripSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripReconstructRegulator,
  multiquadraticStripProviderResidualImage,
  $multiquadraticStripRegulatorScheduleDefault
];

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

End[];
