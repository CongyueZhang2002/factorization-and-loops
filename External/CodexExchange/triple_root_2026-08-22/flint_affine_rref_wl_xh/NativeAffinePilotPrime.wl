(* ::Package:: *)

BeginPackage["CodexNativeAffinePilotPrime`"];

TRInterpolateRationalAffinePrimeNativePilot::usage =
  "TRInterpolateRationalAffinePrimeNativePilot[preparation,epsValues,p,opts] probes a bounded epsilon set natively, selects the earliest maximum-rank consistent image for Discover, then uses the existing fixed-plan solver and epsilon interpolation for the remaining usable samples.";

Begin["`Private`"];

nativeFailure[status_String, data_: <||>] := Join[<|"Status" -> status|>, data];

nativeFingerprint[value_] :=
  Hash[ToString[InputForm[value]], "SHA256", "HexString"];

nativeDegreeProfileQ[profile_, coordinateCount_Integer] :=
  ListQ[profile] && Length[profile] === coordinateCount &&
    AllTrue[profile, TrueQ[#1 === {-Infinity, 0}] ||
      (MatchQ[#1, {_Integer, _Integer}] && Min[#1] >= 0) &];

nativePreference[preparation_Association] := Join[
  preparation["GaugeUnknownCount"] +
    Range[preparation["ResidueUnknownCount"]],
  Range[preparation["GaugeUnknownCount"]]];

nativeNonce[preparation_Association, prime_Integer, epsilonValue_,
    seed_Integer] := Module[{nonce},
  nonce = Mod[
    Hash[{preparation["ABIFingerprint"], prime, epsilonValue, seed, #1},
      "SHA256"], 2^64] & /@ {"nonce-hi", "nonce-lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

nativeSolveAssociation[certificate_Association, plan_: None] := <|
  "Status" -> "CanonicalAffineSolution",
  "Prime" -> certificate["Prime"],
  "MatrixDimensions" -> certificate["MatrixDimensions"],
  "Rank" -> certificate["Rank"],
  "Nullity" -> certificate["Nullity"],
  "PivotColumns" -> certificate["PivotColumns"],
  "FreeColumns" -> certificate["FreeColumns"],
  "PivotSignature" ->
    Hash[certificate["PivotColumns"], "SHA256", "HexString"],
  "ParticularSolution" -> certificate["ParticularSolution"],
  "NullspaceBasis" -> certificate["NullspaceBasis"],
  "ResidualZero" -> True,
  "NullspaceResidualZero" -> True,
  "NormalizationCheck" -> If[AssociationQ[plan],
    certificate["ParticularSolution"][[plan["NormalizationColumns"]]] ===
        ConstantArray[0, plan["Nullity"]] &&
      (plan["Nullity"] === 0 ||
        certificate["NullspaceBasis"][[All,
          plan["NormalizationColumns"]]] === IdentityMatrix[plan["Nullity"]]),
    Missing["SemanticNormalizationAppliedDuringInterpolation"]],
  "Backend" -> "FLINTAffineRREF",
  "BackendFallbackAllowed" -> False,
  "SolvePath" -> "NativeCanonicalAffineRREFCertificate"|>;

Options[TRInterpolateRationalAffinePrimeNativePilot] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260825,
  "ConstructionCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "Backend" -> "FLINT",
  "BackendThreads" -> 4,
  "BackendFallback" -> False,
  "EliminationPlanMode" -> "Discover",
  "EliminationPlan" -> None,
  "ExpectedDegreeProfile" -> Automatic,
  "NativeBinary" -> None,
  "NativeThreads" -> 4,
  "NativeTimeoutSeconds" -> 7200,
  "NativeProbeCount" -> 4,
  "MinimumConsistentNativeProbes" -> 2,
  "MinimumUsableSampleCount" -> Automatic,
  "Verbose" -> True
};

TRInterpolateRationalAffinePrimeNativePilot[preparation_Association,
    epsilonValues_List, prime_Integer, OptionsPattern[]] := Module[
  {pointCount = OptionValue["PointCount"],
   maximumAttempts = OptionValue["MaximumAttempts"],
   randomSeed = OptionValue["RandomSeed"],
   constructionCount = OptionValue["ConstructionCount"],
   maximumTotalDegree = OptionValue["MaximumTotalDegree"],
   backend = OptionValue["Backend"],
   backendThreads = OptionValue["BackendThreads"],
   backendFallback = OptionValue["BackendFallback"],
   planMode = OptionValue["EliminationPlanMode"],
   providedPlan = OptionValue["EliminationPlan"],
   expectedDegreeProfile = OptionValue["ExpectedDegreeProfile"],
   nativeBinary = OptionValue["NativeBinary"],
   nativeThreads = OptionValue["NativeThreads"],
   nativeTimeout = OptionValue["NativeTimeoutSeconds"],
   nativeProbeCount = OptionValue["NativeProbeCount"],
   minimumConsistentNativeProbes =
     OptionValue["MinimumConsistentNativeProbes"],
   minimumUsableSampleCount = OptionValue["MinimumUsableSampleCount"],
   verbose = TrueQ[OptionValue["Verbose"]], log, validatedFingerprint,
   numeratorDegrees, eliminationPlan = None, normalizationColumns = {},
   rawSamples = {}, failures = {}, sample, solve, seed, epsilonIndex,
   assemblySeconds, solveSeconds, nativeRequest, nativeRun,
   nativeVerification, nativeCertificate = None, nativeRequestEvidence = None,
   nativeEvidence = None, nativePlan, preference, interpolationSamples,
   interpolation, degreeProfile, degreeMismatchCoordinates, selectedSamples,
   sampleCache, seedCache, assemblySecondsCache, attemptedIndices = {},
   assemblyFailureIndices = {}, inconsistentProbeIndices = {},
   nativeProbeRecords = {}, nativeProbeSummaries = {}, consistentProbes,
   genericProbeRank, selectedProbe, selectedProbeIndex, probeLimit,
   assembleImage, appendSolvedSample, samplePathContract,
   discardedEpsilonValues},
  log[items___] := If[verbose, Print["TRNATIVEPRIME ", items]];
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
    Return[nativeFailure["InvalidPreparationABI"]]];
  If[! PrimeQ[prime] || !(2 < prime < 2^31) || Mod[prime, 4] =!= 3,
    Return[nativeFailure["PrimeMustBe3Mod4", <|"Prime" -> prime|>]]];
  If[epsilonValues === {} ||
      Length[DeleteDuplicates[epsilonValues]] =!= Length[epsilonValues] ||
      AnyTrue[epsilonValues,
        !(IntegerQ[#1] || Head[#1] === Rational) ||
          Mod[Denominator[#1], prime] === 0 &],
    Return[nativeFailure["InvalidEpsilonSamples"]]];
  If[! IntegerQ[randomSeed] || ! IntegerQ[constructionCount] ||
      constructionCount < 1 || ! IntegerQ[maximumTotalDegree] ||
      maximumTotalDegree < 0 || ! IntegerQ[backendThreads] ||
      backendThreads < 1 || ! BooleanQ[backendFallback] ||
      ! IntegerQ[nativeThreads] || !(1 <= nativeThreads <= 64) ||
      ! IntegerQ[nativeTimeout] || !(1 <= nativeTimeout <= 86400) ||
      ! IntegerQ[nativeProbeCount] || nativeProbeCount < 1 ||
      ! IntegerQ[minimumConsistentNativeProbes] ||
      minimumConsistentNativeProbes < 1,
    Return[nativeFailure["InvalidNativeInterpolationOptions"]]];
  minimumUsableSampleCount = If[minimumUsableSampleCount === Automatic,
    constructionCount + 4, minimumUsableSampleCount];
  If[! IntegerQ[minimumUsableSampleCount] ||
      minimumUsableSampleCount < constructionCount + 4 ||
      Length[epsilonValues] < minimumUsableSampleCount ||
      (planMode === "Discover" &&
        (nativeProbeCount > Length[epsilonValues] ||
          minimumConsistentNativeProbes > nativeProbeCount)),
    Return[nativeFailure["InsufficientCandidateEpsilonSamples", <|
      "CandidateCount" -> Length[epsilonValues],
      "MinimumUsableSampleCount" -> minimumUsableSampleCount,
      "NativeProbeCount" -> nativeProbeCount,
      "MinimumConsistentNativeProbes" ->
        minimumConsistentNativeProbes|>]]];
  validatedFingerprint = preparation["ABIFingerprint"];
  numeratorDegrees = Max /@ Transpose[preparation["GaugeSupport"]];
  Which[
    planMode === "Discover" && providedPlan === None &&
        expectedDegreeProfile === Automatic && StringQ[nativeBinary] &&
        FileExistsQ[nativeBinary], Null,
    planMode === "Require" && AssociationQ[providedPlan] &&
        CodexTripleRootReconstruction`Private`trCrossPrimeEliminationPlanValidQ[
          preparation, providedPlan] &&
        nativeDegreeProfileQ[expectedDegreeProfile,
          preparation["UnknownCount"]],
      eliminationPlan = providedPlan;
      normalizationColumns = eliminationPlan["NormalizationColumns"],
    planMode === "Discover",
      Return[nativeFailure["NativeDiscoverConfigurationInvalid"]],
    planMode === "Require",
      Return[nativeFailure["RequiredCrossPrimeEliminationPlanInvalid",
        <|"Prime" -> prime|>]],
    True,
      Return[nativeFailure["InvalidEliminationPlanMode",
        <|"Prime" -> prime|>]]];
  preference = nativePreference[preparation];
  If[Sort[preference] =!= Range[preparation["UnknownCount"]],
    Return[nativeFailure["NativePreferenceInvalid"]]];
  sampleCache = ConstantArray[None, Length[epsilonValues]];
  seedCache = ConstantArray[None, Length[epsilonValues]];
  assemblySecondsCache = ConstantArray[None, Length[epsilonValues]];
  assembleImage[index_Integer] := Module[{localSeed, localSeconds, localSample},
    If[AssociationQ[sampleCache[[index]]], Return[sampleCache[[index]]]];
    AppendTo[attemptedIndices, index];
    localSeed = Hash[{randomSeed, validatedFingerprint, prime,
      epsilonValues[[index]]}, "CRC32"];
    {localSeconds, localSample} = AbsoluteTiming[
      CodexTripleRootReconstruction`Private`trAssembleReconstructionSampleInternal[
        preparation, epsilonValues[[index]], prime,
        "PointCount" -> pointCount,
        "MaximumAttempts" -> maximumAttempts,
        "RandomSeed" -> localSeed,
        "ValidatedABIFingerprint" -> validatedFingerprint]];
    seedCache[[index]] = localSeed;
    assemblySecondsCache[[index]] = localSeconds;
    If[! AssociationQ[localSample] ||
        Lookup[localSample, "Status", None] =!=
          "AssembledReconstructionSample" ||
        localSample["ABIFingerprint"] =!= validatedFingerprint ||
        localSample["Prime"] =!= prime ||
        localSample["EpsilonValue"] =!= epsilonValues[[index]] ||
        localSample["BranchFlipMask"] =!= 0 ||
        localSample["MatrixDimensions"] =!= Dimensions[localSample["Matrix"]] ||
        ! MatrixQ[localSample["Matrix"], IntegerQ] ||
        ! VectorQ[localSample["RightHandSide"], IntegerQ] ||
        Length[localSample["RightHandSide"]] =!=
          localSample["MatrixDimensions"][[1]],
      AppendTo[assemblyFailureIndices, index];
      AppendTo[failures, <|"EpsilonValue" -> epsilonValues[[index]],
        "Stage" -> "Assembly", "Result" -> localSample|>];
      Return[$Failed]];
    sampleCache[[index]] = localSample;
    localSample
  ];
  appendSolvedSample[localSolve_Association, index_Integer,
      localSample_Association, localSolveSeconds_] := AppendTo[rawSamples,
    Join[localSolve, <|
      "EpsilonValue" -> epsilonValues[[index]],
      "Prime" -> prime,
      "AugmentedRank" -> localSolve["Rank"],
      "Consistent" -> True,
      "ParticularCheckZero" -> localSolve["ResidualZero"],
      "NullspaceCheckZero" -> localSolve["NullspaceResidualZero"],
      "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
      "FreeResidueCount" -> preparation["ResidueUnknownCount"],
      "GaugeNumeratorDegrees" -> numeratorDegrees,
      "GaugeSupport" -> preparation["GaugeSupport"],
      "AcceptedPoints" -> localSample["AcceptedPoints"],
      "AttemptCount" -> localSample["AttemptCount"],
      "AssemblySeconds" -> assemblySecondsCache[[index]],
      "SolveSeconds" -> localSolveSeconds|>]];
  Block[{CodexTripleRootReconstruction`Private`$trValidatedABIFingerprint =
      validatedFingerprint},
    If[planMode === "Discover",
      probeLimit = Min[nativeProbeCount, Length[epsilonValues]];
      Do[
        sample = assembleImage[epsilonIndex];
        If[sample === $Failed, Continue[]];
        seed = seedCache[[epsilonIndex]];
        nativeRequest = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
          sample["Matrix"], sample["RightHandSide"], prime, preference,
          nativeNonce[preparation, prime, epsilonValues[[epsilonIndex]], seed]];
        If[Lookup[nativeRequest, "Status", None] =!= "CFFRRequestV1",
          Return[nativeFailure["NativePilotRequestInvalid", <|
            "EpsilonValue" -> epsilonValues[[epsilonIndex]]|>]]];
        {solveSeconds, nativeRun} = AbsoluteTiming[
          CodexFLINTAffineRREFAdapter`CFFRRun[nativeBinary, nativeRequest,
            nativeThreads, True, nativeTimeout]];
        Which[
          Lookup[nativeRun, "Status", None] ===
              "VerifiedFLINTAffineRREFRun",
            nativeCertificate = nativeRun["Certificate"];
            nativeVerification =
              CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
                nativeRequest, nativeCertificate];
            If[Lookup[nativeVerification, "Status", None] =!=
                "VerifiedFLINTAffineRREFCertificate",
              If[StringQ[Lookup[nativeRun, "ArtifactDirectory", None]] &&
                  DirectoryQ[nativeRun["ArtifactDirectory"]],
                Quiet[DeleteDirectory[nativeRun["ArtifactDirectory"],
                  DeleteContents -> True]]];
              Return[nativeFailure[
                "NativePilotIndependentVerificationFailed", <|
                  "EpsilonValue" -> epsilonValues[[epsilonIndex]]|>]]];
            AppendTo[nativeProbeRecords, <|
              "Index" -> epsilonIndex,
              "EpsilonValue" -> epsilonValues[[epsilonIndex]],
              "Status" -> "ConsistentNativeAffineImage",
              "Rank" -> nativeCertificate["Rank"],
              "Nullity" -> nativeCertificate["Nullity"],
              "Seed" -> seed,
              "AssemblySeconds" -> assemblySecondsCache[[epsilonIndex]],
              "NativeSeconds" -> solveSeconds,
              "Request" -> nativeRequest,
              "Certificate" -> nativeCertificate,
              "Verification" -> nativeVerification,
              "RequestSHA256" -> FileHash[nativeRun["RequestFile"],
                "SHA256", "HexString"],
              "ResponseSHA256" -> FileHash[nativeRun["ResponseFile"],
                "SHA256", "HexString"],
              "RequestByteCount" -> FileByteCount[nativeRun["RequestFile"]],
              "ResponseByteCount" -> FileByteCount[nativeRun["ResponseFile"]]|>];
            Quiet[DeleteDirectory[nativeRun["ArtifactDirectory"],
              DeleteContents -> True]],
          Lookup[nativeRun, "Status", None] === "InconsistentAffineImage",
            AppendTo[inconsistentProbeIndices, epsilonIndex];
            AppendTo[failures, <|
              "EpsilonValue" -> epsilonValues[[epsilonIndex]],
              "Stage" -> "NativeProbeSolve",
              "FailureClass" -> "MathematicalImageInconsistency",
              "Result" -> KeyDrop[nativeRun, {"ArtifactDirectory"}]|>];
            AppendTo[nativeProbeRecords, <|
              "Index" -> epsilonIndex,
              "EpsilonValue" -> epsilonValues[[epsilonIndex]],
              "Status" -> "InconsistentAffineImage",
              "ExitCode" -> Lookup[nativeRun, "ExitCode", None],
              "Seed" -> seed,
              "AssemblySeconds" -> assemblySecondsCache[[epsilonIndex]],
              "NativeSeconds" -> solveSeconds|>];
            If[StringQ[Lookup[nativeRun, "ArtifactDirectory", None]] &&
                DirectoryQ[nativeRun["ArtifactDirectory"]],
              Quiet[DeleteDirectory[nativeRun["ArtifactDirectory"],
                DeleteContents -> True]]],
          True,
            If[StringQ[Lookup[nativeRun, "ArtifactDirectory", None]] &&
                DirectoryQ[nativeRun["ArtifactDirectory"]],
              Quiet[DeleteDirectory[nativeRun["ArtifactDirectory"],
                DeleteContents -> True]]];
            Return[nativeFailure["NativePilotInfrastructureFailed", <|
              "EpsilonValue" -> epsilonValues[[epsilonIndex]],
              "NativeRun" -> KeyDrop[nativeRun,
                {"Certificate", "Verification", "ArtifactDirectory"}]|>]]],
        {epsilonIndex, probeLimit}];
      consistentProbes = Select[nativeProbeRecords,
        Lookup[#1, "Status", None] === "ConsistentNativeAffineImage" &];
      If[Length[consistentProbes] < minimumConsistentNativeProbes,
        Return[nativeFailure["InsufficientConsistentNativeProbes", <|
          "Prime" -> prime,
          "Required" -> minimumConsistentNativeProbes,
          "Observed" -> Length[consistentProbes],
          "ProbeSummaries" -> (KeyDrop[#1,
            {"Request", "Certificate", "Verification"}] & /@
              nativeProbeRecords),
          "Failures" -> failures|>]]];
      genericProbeRank = Max[Lookup[consistentProbes, "Rank"]];
      selectedProbe = First[Select[consistentProbes,
        Lookup[#1, "Rank", -1] === genericProbeRank &]];
      selectedProbeIndex = selectedProbe["Index"];
      sample = sampleCache[[selectedProbeIndex]];
      seed = selectedProbe["Seed"];
      nativeRequest = selectedProbe["Request"];
      nativeRequestEvidence = nativeRequest;
      nativeCertificate = selectedProbe["Certificate"];
      nativeVerification = selectedProbe["Verification"];
      nativeProbeSummaries = KeyTake[#1, {"Index", "EpsilonValue",
          "Status", "Rank", "Nullity", "ExitCode", "Seed",
          "AssemblySeconds", "NativeSeconds", "RequestSHA256",
          "ResponseSHA256", "RequestByteCount", "ResponseByteCount"}] & /@
        nativeProbeRecords;
      nativeEvidence = <|
        "Status" -> "VerifiedNativeAffinePilotEvidenceV2",
        "Threads" -> nativeThreads,
        "AssemblySeconds" -> selectedProbe["AssemblySeconds"],
        "NativeSeconds" -> selectedProbe["NativeSeconds"],
        "RequestSHA256" -> selectedProbe["RequestSHA256"],
        "ResponseSHA256" -> selectedProbe["ResponseSHA256"],
        "RequestByteCount" -> selectedProbe["RequestByteCount"],
        "ResponseByteCount" -> selectedProbe["ResponseByteCount"],
        "CertificateFingerprint" -> nativeFingerprint[nativeCertificate],
        "VerificationChecks" -> nativeVerification["Checks"],
        "AcceptedPoints" -> sample["AcceptedPoints"],
        "AttemptCount" -> sample["AttemptCount"],
        "Seed" -> seed,
        "EpsilonValue" -> epsilonValues[[selectedProbeIndex]],
        "SelectedProbeIndex" -> selectedProbeIndex,
        "GenericRank" -> genericProbeRank,
        "GenericityRule" -> "EarliestMaximumRankAcrossBoundedNativeProbes",
        "ProbeSummaries" -> nativeProbeSummaries|>;
      nativePlan = CodexFLINTAffineRREFAdapter`CFFRConstructCrossPrimePlanV1[
        preparation, sample, seed, nativeRequest, nativeCertificate];
      If[Lookup[nativePlan, "Status", None] =!=
            "CrossPrimeEliminationPlanV1" ||
          ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
            preparation, nativePlan],
        Return[nativeFailure["NativePilotPlanInvalid"]]];
      eliminationPlan = nativePlan;
      normalizationColumns = eliminationPlan["NormalizationColumns"];
      solve = nativeSolveAssociation[nativeCertificate];
      appendSolvedSample[solve, selectedProbeIndex, sample,
        selectedProbe["NativeSeconds"]]];
    Do[
      If[planMode === "Discover" &&
          (epsilonIndex === selectedProbeIndex ||
            MemberQ[inconsistentProbeIndices, epsilonIndex] ||
            MemberQ[assemblyFailureIndices, epsilonIndex]), Continue[]];
      sample = assembleImage[epsilonIndex];
      If[sample === $Failed, Continue[]];
      {solveSeconds, solve} = AbsoluteTiming[
        CodexTripleRootReconstruction`Private`trSolveReconstructionWithPlan[
          preparation, sample["Matrix"], sample["RightHandSide"],
          eliminationPlan, prime, backend, backendThreads,
          backendFallback]];
      If[Lookup[solve, "Status", None] =!= "CanonicalAffineSolution" ||
          ! TrueQ[Lookup[solve, "ResidualZero", False]] ||
          ! TrueQ[Lookup[solve, "NullspaceResidualZero", False]] ||
          Lookup[solve, "Rank", None] =!= eliminationPlan["GenericRank"],
        AppendTo[failures, <|"EpsilonValue" -> epsilonValues[[epsilonIndex]],
          "Stage" -> "FixedPlanSolveOrGenericity", "Result" -> solve|>];
        Continue[]];
      appendSolvedSample[solve, epsilonIndex, sample, solveSeconds],
      {epsilonIndex, Length[epsilonValues]}]];
  If[! AssociationQ[eliminationPlan] || rawSamples === {},
    Return[nativeFailure[If[planMode === "Require",
      "FixedEliminationPlanNoUsableSamples", "NoUsableSamples"],
      <|"Prime" -> prime, "Failures" -> failures|>]]];
  selectedSamples = rawSamples;
  samplePathContract = If[planMode === "Discover",
    Lookup[First[selectedSamples], "Backend", None] ===
        "FLINTAffineRREF" &&
      Lookup[First[selectedSamples], "SolvePath", None] ===
        "NativeCanonicalAffineRREFCertificate" &&
      AllTrue[Rest[selectedSamples],
        Lookup[#1, "Backend", None] === "FLINT" &&
          Lookup[#1, "SolvePath", None] ===
            "OneConstrainedMultiRHSFactorization" &&
          TrueQ[Lookup[#1, "NormalizationCheck", False]] &&
          Lookup[#1, "BackendFallbackAllowed", None] === False &],
    AllTrue[selectedSamples,
      Lookup[#1, "Backend", None] === "FLINT" &&
        Lookup[#1, "SolvePath", None] ===
          "OneConstrainedMultiRHSFactorization" &&
        TrueQ[Lookup[#1, "NormalizationCheck", False]] &&
        Lookup[#1, "BackendFallbackAllowed", None] === False &]];
  If[! TrueQ[samplePathContract],
    Return[nativeFailure["ExactSamplePathContractFailed", <|
      "Prime" -> prime,
      "PlanMode" -> planMode,
      "ObservedSampleCount" -> Length[selectedSamples],
      "Failures" -> failures,
      "SamplePathSummary" -> (KeyTake[#1, {"EpsilonValue", "Backend",
          "SolvePath", "NormalizationCheck", "BackendFallbackAllowed"}] & /@
        selectedSamples)|>]]];
  If[Length[selectedSamples] < minimumUsableSampleCount,
    Return[nativeFailure["InsufficientStablePivotSamples", <|
      "Prime" -> prime,
      "StablePivotSampleCount" -> Length[selectedSamples],
      "Required" -> minimumUsableSampleCount,
      "Failures" -> failures|>]]];
  discardedEpsilonValues = DeleteDuplicates[
    Lookup[failures, "EpsilonValue", {}]];
  If[DeleteDuplicates[attemptedIndices] =!= Range[Length[epsilonValues]] ||
      ! DuplicateFreeQ[Join[Lookup[selectedSamples, "EpsilonValue"],
        discardedEpsilonValues]] ||
      Sort[Join[Lookup[selectedSamples, "EpsilonValue"],
        discardedEpsilonValues]] =!= Sort[epsilonValues],
    Return[nativeFailure["CandidateImagePartitionInvalid", <|
      "AttemptedIndices" -> DeleteDuplicates[attemptedIndices],
      "SelectedEpsilonValues" -> Lookup[selectedSamples, "EpsilonValue"],
      "DiscardedEpsilonValues" -> discardedEpsilonValues|>]]];
  interpolationSamples = KeyTake[#1, {"EpsilonValue", "Prime",
      "ParticularSolution", "NullspaceBasis", "Rank", "AugmentedRank",
      "Consistent", "ParticularCheckZero", "NullspaceCheckZero",
      "GaugeUnknownCount", "FreeResidueCount", "GaugeNumeratorDegrees",
      "GaugeSupport"}] & /@ selectedSamples;
  log["prime=", prime, " samples=", Length[interpolationSamples],
    " rank=", eliminationPlan["GenericRank"],
    " nullity=", eliminationPlan["Nullity"],
    " mode=", planMode];
  interpolation = FeynFacet`InterpolateEpsFormStripAffine[
    interpolationSamples, prime,
    "ConstructionCount" -> constructionCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "NormalizationColumns" -> normalizationColumns];
  If[! AssociationQ[interpolation] ||
      Lookup[interpolation, "UnresolvedCoordinates", {1}] =!= {},
    Return[nativeFailure["RationalEpsilonInterpolationFailed", <|
      "Prime" -> prime,
      "ABIFingerprint" -> validatedFingerprint,
      "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
      "Interpolation" -> interpolation,
      "Failures" -> failures|>]]];
  degreeProfile = Lookup[interpolation["Interpolations"], "Degrees", $Failed];
  If[! nativeDegreeProfileQ[degreeProfile, preparation["UnknownCount"]],
    Return[nativeFailure["InvalidInterpolatedDegreeProfile",
      <|"Prime" -> prime|>]]];
  If[planMode === "Require" && degreeProfile =!= expectedDegreeProfile,
    degreeMismatchCoordinates = Select[Range[Length[degreeProfile]],
      degreeProfile[[#1]] =!= expectedDegreeProfile[[#1]] &];
    Return[nativeFailure["RejectPrimeDegreeProfileChanged", <|
      "Prime" -> prime,
      "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
      "DegreeMismatchCoordinates" -> degreeMismatchCoordinates,
      "ExpectedDegreeProfile" -> expectedDegreeProfile,
      "ObservedDegreeProfile" -> degreeProfile|>]]];
  Join[interpolation, <|
    "Status" -> "RationalAffinePrimeInterpolated",
    "ABIFingerprint" -> validatedFingerprint,
    "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"],
    "EliminationPlanMode" -> planMode,
    "EliminationPlan" -> eliminationPlan,
    "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
    "DegreeProfile" -> degreeProfile,
    "DegreeProfileFingerprint" -> nativeFingerprint[degreeProfile],
    "EliminationPlanSummary" -> KeyTake[eliminationPlan,
      {"Status", "PlanVersion", "PlanFingerprint",
       "NormalizationColumns", "IndependentEquationRows", "GenericRank",
       "Nullity", "UnknownCount", "GaugeUnknownCount", "FreeResidueCount",
       "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "PilotPrime"}],
    "InputEpsilonValues" -> epsilonValues,
    "AttemptedEpsilonValues" -> epsilonValues[[DeleteDuplicates[
      attemptedIndices]]],
    "MinimumUsableSampleCount" -> minimumUsableSampleCount,
    "StablePivotSampleCount" -> Length[selectedSamples],
    "CanonicalDenseByteEstimate" -> 0,
    "CanonicalDenseByteCap" -> 0,
    "DensePilotPerformed" -> False,
    "NativePilotPerformed" -> (planMode === "Discover"),
    "NativePilotEvidence" -> nativeEvidence,
    "NativePilotRequest" -> nativeRequestEvidence,
    "NativePilotCertificate" -> nativeCertificate,
    "NativeProbeSummaries" -> nativeProbeSummaries,
    "NativeGenericityWitness" -> If[planMode === "Discover", <|
      "Rule" -> "EarliestMaximumRankAcrossBoundedNativeProbes",
      "ProbeCount" -> Length[nativeProbeRecords],
      "ConsistentProbeCount" -> Length[consistentProbes],
      "GenericRank" -> genericProbeRank,
      "SelectedProbeIndex" -> selectedProbeIndex,
      "SelectedEpsilonValue" -> epsilonValues[[selectedProbeIndex]]|>, None],
    "DiscardedEpsilonValues" -> discardedEpsilonValues,
    "SampleFailures" -> failures,
    "SampleSummaries" -> (KeyTake[#1, {"EpsilonValue", "Rank",
        "Nullity", "PivotSignature", "AcceptedPoints", "AttemptCount",
        "Backend", "SolvePath", "NormalizationCheck",
        "BackendFallbackAllowed", "AssemblySeconds", "SolveSeconds"}] & /@
      selectedSamples)|>]
];

End[];
EndPackage[];
