#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 6 || Length[arguments] > 11,
  Print["CF300S12R2NATIVE FAIL usage=<project-root> <preparation.wl> " <>
    "<output.wl> <prime> <discover|reuse> <plan-source-or-dash> " <>
    "[candidate-sample-count] [construction-count] [maximum-total-degree] " <>
    "[native-probe-count] [minimum-consistent-native-probes]"];
  Exit[64]];

parseStrictInteger[text_String] := Module[{negative, digits},
  If[! StringMatchQ[text, RegularExpression["0|-?[1-9][0-9]*"]],
    Return[$Failed]];
  negative = StringStartsQ[text, "-"];
  digits = If[negative, StringDrop[text, 1], text];
  If[negative, -FromDigits[digits], FromDigits[digits]]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prime = parseStrictInteger[arguments[[4]]];
planMode = arguments[[5]];
planSourceToken = arguments[[6]];
planSourceFile = If[planMode === "reuse",
  ExpandFileName[planSourceToken], None];
sampleCount = If[Length[arguments] >= 7,
  parseStrictInteger[arguments[[7]]], 48];
constructionCount = If[Length[arguments] >= 8,
  parseStrictInteger[arguments[[8]]], 24];
maximumTotalDegree = If[Length[arguments] >= 9,
  parseStrictInteger[arguments[[9]]], 22];
nativeProbeCount = If[Length[arguments] >= 10,
  parseStrictInteger[arguments[[10]]], 4];
minimumConsistentNativeProbes = If[Length[arguments] >= 11,
  parseStrictInteger[arguments[[11]]], 2];
nativeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[nativeDirectory];
nativeBinary = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh", "bin", "flint_affine_rref"}];
fixedPlanFLINTBinary = FileNameJoin[{projectRoot, "FeynFacet", "Backends",
  "flint", "bin", "flint_modular_solve"}];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;
nativeDependencyFiles = <|
  "FlintAffineRREFAdapter" -> FileNameJoin[{nativeDirectory,
    "FlintAffineRREFAdapter.wl"}],
  "NativeAffinePilotPrime" -> FileNameJoin[{nativeDirectory,
    "NativeAffinePilotPrime.wl"}]|>;
prototypeFile = dependencyFiles["TripleRootReconstructionPrototype"];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! AllTrue[Values[nativeDependencyFiles], FileExistsQ] ||
    ! FileExistsQ[nativeBinary] || ! FileExistsQ[fixedPlanFLINTBinary] ||
    ! PrimeQ[prime] || !(2 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
    ! MemberQ[{"discover", "reuse"}, planMode] ||
    (planMode === "discover" && planSourceToken =!= "-") ||
    (planMode === "reuse" &&
      (planSourceToken === "-" || ! FileExistsQ[planSourceFile])) ||
    ! IntegerQ[sampleCount] || !(1 <= sampleCount <= 256) ||
    ! IntegerQ[constructionCount] || constructionCount < 1 ||
    sampleCount < constructionCount + 4 ||
    ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0 ||
    ! IntegerQ[nativeProbeCount] ||
      !(1 <= nativeProbeCount <= sampleCount) ||
    ! IntegerQ[minimumConsistentNativeProbes] ||
      !(1 <= minimumConsistentNativeProbes <= nativeProbeCount) ||
    FileExistsQ[outputFile] || FileExistsQ[outputFile <> ".tmp"],
  Print["CF300S12R2NATIVE FAIL invalid or stale target"];
  Exit[65]];

preparationHashBefore = FileHash[preparationFile, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#1, "SHA256", "HexString"] &,
  dependencyFiles];
nativeDependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, nativeDependencyFiles];
prototypeHashBefore = dependencyHashesBefore[
  "TripleRootReconstructionPrototype"];
nativeBinaryHashBefore = FileHash[nativeBinary, "SHA256", "HexString"];
fixedPlanFLINTBinaryHashBefore = FileHash[fixedPlanFLINTBinary,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
planSourceHashBefore = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];

Get[dependencyFiles["LoadFACET"]];
Get[dependencyFiles["TripleRootAlgebra"]];
Get[dependencyFiles["TripleRootStripAdapter"]];
Get[dependencyFiles["TripleRootAffinePilot"]];
Get[prototypeFile];
Get[nativeDependencyFiles["FlintAffineRREFAdapter"]];
Get[nativeDependencyFiles["NativeAffinePilotPrime"]];

writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp." <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];
writeAndExit[value_, code_Integer] := If[writeAtomic[value] === $Failed,
  Print["CF300S12R2NATIVE FAIL atomic output race output=", outputFile];
  Exit[98], Exit[code]];

dependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
nativeDependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, nativeDependencyFiles];
driverHashAfterLoad = FileHash[$InputFileName, "SHA256", "HexString"];
nativeBinaryHashAfterLoad = FileHash[nativeBinary, "SHA256", "HexString"];
fixedPlanFLINTBinaryHashAfterLoad = FileHash[fixedPlanFLINTBinary,
  "SHA256", "HexString"];
If[dependencyHashesAfterLoad =!= dependencyHashesBefore ||
    nativeDependencyHashesAfterLoad =!= nativeDependencyHashesBefore ||
    driverHashAfterLoad =!= driverHashBefore ||
    nativeBinaryHashAfterLoad =!= nativeBinaryHashBefore ||
    fixedPlanFLINTBinaryHashAfterLoad =!= fixedPlanFLINTBinaryHashBefore,
  writeAndExit[<|"Status" -> "DependencyChangedDuringLoad"|>, 95]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
planSourceArtifact = If[planMode === "reuse",
  FeynFacet`FamilyArtifactRead[planSourceFile], None];
preparationHashAfterRead = FileHash[preparationFile,
  "SHA256", "HexString"];
planSourceHashAfterRead = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];
If[preparationHashAfterRead =!= preparationHashBefore ||
    planSourceHashAfterRead =!= planSourceHashBefore,
  writeAndExit[<|"Status" -> "InputChangedDuringRead"|>, 96]];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    Lookup[preparationArtifact, "DependencyHashes", None] =!=
      dependencyHashesBefore,
  writeAndExit[<|"Status" -> "PreparationArtifactInvalid"|>, 66]];
preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
inputFile = Lookup[preparationArtifact, "InputFile", $Failed];
If[! StringQ[preparationDriverFile] || ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None] ||
    ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
    FileHash[inputFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "InputSHA256", None],
  writeAndExit[<|"Status" -> "PreparationProvenanceInvalid"|>, 66]];
preparation = Lookup[preparationArtifact, "Preparation", $Failed];
If[! AssociationQ[preparation] ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    preparation["RootCount"] =!= 2 || preparation["GradeCount"] =!= 4 ||
    preparation["RootSourceIndices"] =!= {2, 3} ||
    preparation["Dimensions"] =!= {2, 2} ||
    preparation["Normalizations"] =!= {} ||
    preparation["GaugeUnknownCount"] =!= 480 ||
    preparation["ResidueUnknownCount"] =!= 144 ||
    preparation["UnknownCount"] =!= 624 ||
    preparation["EquationsPerPoint"] =!= 32 ||
    Length[preparation["GaugeSupport"]] =!= 30 ||
    Lookup[preparationArtifact, "RootOrderingFingerprint", None] =!=
      preparation["RootOrderingFingerprint"] ||
    Lookup[preparationArtifact, "OneFormOrderFingerprint", None] =!=
      fingerprint[preparation["ABIPayload", "OneForms"]],
  writeAndExit[<|"Status" -> "PreparationABIInvalid"|>, 67]];

eliminationPlan = None;
expectedDegreeProfile = Automatic;
If[planMode === "reuse",
  If[! AssociationQ[planSourceArtifact] ||
      Lookup[planSourceArtifact, "Status", None] =!=
        "RationalAffinePrimeInterpolated" ||
      Lookup[planSourceArtifact, "PlanAcquisitionMode", None] =!= "Discover" ||
      Lookup[planSourceArtifact, "PreparationSHA256", None] =!=
        preparationHashBefore ||
      Lookup[planSourceArtifact, "PrototypeSHA256", None] =!=
        prototypeHashBefore ||
      Lookup[planSourceArtifact, "DependencyHashes", None] =!=
        dependencyHashesBefore ||
      Lookup[planSourceArtifact, "NativeDependencyHashes", None] =!=
        nativeDependencyHashesBefore ||
      Lookup[planSourceArtifact, "NativeBinarySHA256", None] =!=
        nativeBinaryHashBefore ||
      Lookup[planSourceArtifact, "NativeBinaryFile", None] =!= nativeBinary ||
      Lookup[planSourceArtifact, "FixedPlanFLINTBinaryFile", None] =!=
        fixedPlanFLINTBinary ||
      Lookup[planSourceArtifact, "FixedPlanFLINTBinarySHA256", None] =!=
        fixedPlanFLINTBinaryHashBefore ||
      Lookup[planSourceArtifact, "DriverSHA256", None] =!= driverHashBefore ||
      Lookup[planSourceArtifact, "DriverFile", None] =!= $InputFileName ||
      Lookup[planSourceArtifact, "RootOrderingFingerprint", None] =!=
        preparation["RootOrderingFingerprint"] ||
      ! TrueQ[Lookup[planSourceArtifact, "NativePilotPerformed", False]] ||
      Lookup[planSourceArtifact, "DensePilotPerformed", None] =!= False ||
      ! ListQ[Lookup[planSourceArtifact, "SampleFailures", None]] ||
      ! IntegerQ[Lookup[planSourceArtifact,
        "StablePivotSampleCount", None]] ||
      Lookup[planSourceArtifact, "StablePivotSampleCount", 0] <
        constructionCount + 4 ||
      Lookup[planSourceArtifact, "StablePivotSampleCount", 0] > sampleCount ||
      Lookup[planSourceArtifact, "MinimumUsableSampleCount", None] =!=
        constructionCount + 4 ||
      Lookup[planSourceArtifact, "InputEpsilonValues", None] =!=
        ((#1/(#1 + 20) &) /@ Range[sampleCount]),
    writeAndExit[<|"Status" -> "PlanSourceProvenanceMismatch"|>, 68]];
  eliminationPlan = Lookup[planSourceArtifact, "EliminationPlan", $Failed];
  expectedDegreeProfile = Lookup[planSourceArtifact,
    "DegreeProfile", $Failed];
  sourceNativeEvidence = Lookup[planSourceArtifact,
    "NativePilotEvidence", $Failed];
  sourceNativeRequest = Lookup[planSourceArtifact,
    "NativePilotRequest", $Failed];
  sourceNativeCertificate = Lookup[planSourceArtifact,
    "NativePilotCertificate", $Failed];
  sourceSampleSummaries = Lookup[planSourceArtifact,
    "SampleSummaries", $Failed];
  sourceNativeProbeSummaries = Lookup[sourceNativeEvidence,
    "ProbeSummaries", $Failed];
  sourceConsistentProbeSummaries = If[ListQ[sourceNativeProbeSummaries],
    Select[sourceNativeProbeSummaries,
      Lookup[#1, "Status", None] === "ConsistentNativeAffineImage" &], {}];
  sourceGenericRank = If[sourceConsistentProbeSummaries === {}, $Failed,
    Max[Lookup[sourceConsistentProbeSummaries, "Rank"]]];
  sourceSelectedProbe = If[sourceGenericRank === $Failed, $Failed,
    First[Select[sourceConsistentProbeSummaries,
      Lookup[#1, "Rank", -1] === sourceGenericRank &]]];
  sourceGenericityWitness = Lookup[planSourceArtifact,
    "NativeGenericityWitness", $Failed];
  sourceSampleFailures = Lookup[planSourceArtifact, "SampleFailures", $Failed];
  sourceDiscardedEpsilonValues = If[ListQ[sourceSampleFailures],
    DeleteDuplicates[Lookup[sourceSampleFailures, "EpsilonValue", {}]],
    $Failed];
  sourceSampleEpsilonValues = If[ListQ[sourceSampleSummaries],
    Lookup[sourceSampleSummaries, "EpsilonValue", $Failed], $Failed];
  If[! AssociationQ[eliminationPlan] ||
      ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
        preparation, eliminationPlan] ||
      Lookup[planSourceArtifact, "Prime", None] =!=
        eliminationPlan["PilotPrime"] ||
      Lookup[planSourceArtifact, "EliminationPlanFingerprint", None] =!=
        eliminationPlan["PlanFingerprint"] ||
      Lookup[planSourceArtifact, "DegreeProfileFingerprint", None] =!=
        fingerprint[expectedDegreeProfile] ||
      expectedDegreeProfile =!= Lookup[
        Lookup[planSourceArtifact, "Interpolations", {}],
        "Degrees", $Failed] ||
      ! AssociationQ[sourceNativeEvidence] ||
      Lookup[sourceNativeEvidence, "Status", None] =!=
        "VerifiedNativeAffinePilotEvidenceV2" ||
      Lookup[sourceNativeEvidence, "Seed", None] =!=
        eliminationPlan["PilotRandomSeed"] ||
      Lookup[sourceNativeEvidence, "EpsilonValue", None] =!=
        eliminationPlan["PilotEpsilonValue"] ||
      Lookup[sourceNativeEvidence, "AcceptedPoints", None] =!=
        eliminationPlan["PilotAcceptedPoints"] ||
      ! AssociationQ[sourceNativeRequest] ||
      ! AssociationQ[sourceNativeCertificate] ||
      Lookup[sourceNativeCertificate, "Status", None] =!=
        "FLINTAffineRREFCertificateV1" ||
      fingerprint[sourceNativeCertificate] =!=
        Lookup[sourceNativeEvidence, "CertificateFingerprint", None] ||
      ! ListQ[sourceNativeProbeSummaries] ||
      Count[Lookup[sourceNativeProbeSummaries, "Status", None],
        "ConsistentNativeAffineImage"] <
        minimumConsistentNativeProbes ||
      Lookup[sourceNativeEvidence, "GenericityRule", None] =!=
        "EarliestMaximumRankAcrossBoundedNativeProbes" ||
      ! AssociationQ[sourceGenericityWitness] ||
      sourceGenericRank =!= eliminationPlan["GenericRank"] ||
      ! AssociationQ[sourceSelectedProbe] ||
      Lookup[sourceSelectedProbe, "Index", None] =!=
        Lookup[sourceNativeEvidence, "SelectedProbeIndex", None] ||
      Lookup[sourceSelectedProbe, "EpsilonValue", None] =!=
        eliminationPlan["PilotEpsilonValue"] ||
      Lookup[planSourceArtifact, "NativeProbeSummaries", None] =!=
        sourceNativeProbeSummaries ||
      Lookup[sourceGenericityWitness, "GenericRank", None] =!=
        sourceGenericRank ||
      Lookup[sourceGenericityWitness, "SelectedProbeIndex", None] =!=
        Lookup[sourceSelectedProbe, "Index", None] ||
      ! ListQ[sourceSampleSummaries] ||
      Length[sourceSampleSummaries] =!=
        Lookup[planSourceArtifact, "StablePivotSampleCount", None] ||
      Lookup[planSourceArtifact, "AttemptedEpsilonValues", None] =!=
        Lookup[planSourceArtifact, "InputEpsilonValues", None] ||
      Lookup[planSourceArtifact, "DiscardedEpsilonValues", None] =!=
        sourceDiscardedEpsilonValues ||
      ! DuplicateFreeQ[Join[sourceSampleEpsilonValues,
        sourceDiscardedEpsilonValues]] ||
      Sort[Join[sourceSampleEpsilonValues, sourceDiscardedEpsilonValues]] =!=
        Sort[Lookup[planSourceArtifact, "InputEpsilonValues", {}]] ||
      Lookup[First[sourceSampleSummaries], "Backend", None] =!=
        "FLINTAffineRREF" ||
      Lookup[First[sourceSampleSummaries], "SolvePath", None] =!=
        "NativeCanonicalAffineRREFCertificate" ||
      ! AllTrue[Rest[sourceSampleSummaries],
        Lookup[#1, "Backend", None] === "FLINT" &&
          Lookup[#1, "SolvePath", None] ===
            "OneConstrainedMultiRHSFactorization" &&
          TrueQ[Lookup[#1, "NormalizationCheck", False]] &&
          Lookup[#1, "BackendFallbackAllowed", None] === False &],
    writeAndExit[<|"Status" -> "PlanSourceSemanticMismatch"|>, 68]];
  sourceVerification =
    CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
      sourceNativeRequest, sourceNativeCertificate];
  sourceSample = <|
    "MatrixDimensions" -> sourceNativeRequest["MatrixDimensions"],
    "Matrix" -> sourceNativeRequest["Matrix"],
    "RightHandSide" -> sourceNativeRequest["RightHandSide"],
    "AcceptedPoints" -> eliminationPlan["PilotAcceptedPoints"],
    "NormalizationCount" -> Length[preparation["Normalizations"]],
    "BranchFlipMask" -> 0,
    "Prime" -> eliminationPlan["PilotPrime"],
    "EpsilonValue" -> eliminationPlan["PilotEpsilonValue"]|>;
  recomputedSourcePlan =
    CodexFLINTAffineRREFAdapter`CFFRConstructCrossPrimePlanV1[
      preparation, sourceSample, eliminationPlan["PilotRandomSeed"],
      sourceNativeRequest, sourceNativeCertificate];
  If[Lookup[sourceVerification, "Status", None] =!=
        "VerifiedFLINTAffineRREFCertificate" ||
      recomputedSourcePlan =!= eliminationPlan,
    writeAndExit[<|"Status" ->
      "PlanSourceNativeCertificateReverificationFailed"|>, 68]]];

epsilonValues = (#1/(#1 + 20) &) /@ Range[sampleCount];
Print["CF300S12R2NATIVE prime=", prime, " plan_mode=", planMode,
  " samples=", sampleCount, " construction=", constructionCount,
  " maximum_total_degree=", maximumTotalDegree,
  " native_probe_count=", nativeProbeCount,
  " minimum_consistent_native_probes=", minimumConsistentNativeProbes,
  " unknowns=", preparation["UnknownCount"]];
{seconds, interpolation} = AbsoluteTiming[
  CodexNativeAffinePilotPrime`TRInterpolateRationalAffinePrimeNativePilot[
    preparation, epsilonValues, prime,
    "ConstructionCount" -> constructionCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "RandomSeed" -> 730000 + Mod[prime, 100000],
    "Backend" -> "FLINT", "BackendThreads" -> 4,
    "BackendFallback" -> False,
    "EliminationPlanMode" -> If[planMode === "discover",
      "Discover", "Require"],
    "EliminationPlan" -> eliminationPlan,
    "ExpectedDegreeProfile" -> expectedDegreeProfile,
    "NativeBinary" -> nativeBinary,
    "NativeThreads" -> 4,
    "NativeTimeoutSeconds" -> 7200,
    "NativeProbeCount" -> nativeProbeCount,
    "MinimumConsistentNativeProbes" -> minimumConsistentNativeProbes,
    "MinimumUsableSampleCount" -> constructionCount + 4,
    "Verbose" -> True]];
result = If[AssociationQ[interpolation], Join[interpolation, <|
    "PreparationFile" -> preparationFile,
    "PreparationSHA256" -> preparationHashBefore,
    "InputFile" -> preparationArtifact["InputFile"],
    "InputSHA256" -> preparationArtifact["InputSHA256"],
    "PlanAcquisitionMode" -> If[planMode === "discover", "Discover", "Reuse"],
    "PlanSourceFile" -> If[planMode === "reuse", planSourceFile, None],
    "PlanSourceSHA256" -> If[planMode === "reuse",
      planSourceHashBefore, None],
    "PrimeSeconds" -> seconds,
    "PrototypeSHA256" -> prototypeHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "NativeDependencyHashes" -> nativeDependencyHashesBefore,
    "NativeBinaryFile" -> nativeBinary,
    "NativeBinarySHA256" -> nativeBinaryHashBefore,
    "FixedPlanFLINTBinaryFile" -> fixedPlanFLINTBinary,
    "FixedPlanFLINTBinarySHA256" -> fixedPlanFLINTBinaryHashBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore|>],
  <|"Status" -> "PrimeInterpolationNotAssociation",
    "Prime" -> prime, "PrimeSeconds" -> seconds|>];
resultSampleSummaries = Lookup[result, "SampleSummaries", $Failed];
resultSampleFailures = Lookup[result, "SampleFailures", $Failed];
resultDiscardedEpsilonValues = If[ListQ[resultSampleFailures],
  DeleteDuplicates[Lookup[resultSampleFailures, "EpsilonValue", {}]],
  $Failed];
resultSampleEpsilonValues = If[ListQ[resultSampleSummaries],
  Lookup[resultSampleSummaries, "EpsilonValue", $Failed], $Failed];
resultNativeProbeSummaries = Lookup[result, "NativeProbeSummaries", $Failed];
resultConsistentProbeSummaries = If[ListQ[resultNativeProbeSummaries],
  Select[resultNativeProbeSummaries,
    Lookup[#1, "Status", None] === "ConsistentNativeAffineImage" &], {}];
resultGenericRank = If[resultConsistentProbeSummaries === {}, $Failed,
  Max[Lookup[resultConsistentProbeSummaries, "Rank"]]];
resultSelectedProbe = If[resultGenericRank === $Failed, $Failed,
  First[Select[resultConsistentProbeSummaries,
    Lookup[#1, "Rank", -1] === resultGenericRank &]]];
resultGenericityWitness = Lookup[result, "NativeGenericityWitness", $Failed];
If[Lookup[result, "Status", None] === "RationalAffinePrimeInterpolated" &&
    (Lookup[result, "RootOrderingFingerprint", None] =!=
        preparation["RootOrderingFingerprint"] ||
      Lookup[result, "EliminationPlanMode", None] =!=
        If[planMode === "discover", "Discover", "Require"] ||
      ! AssociationQ[Lookup[result, "EliminationPlan", $Failed]] ||
      Lookup[result, "EliminationPlanFingerprint", None] =!=
        Lookup[Lookup[result, "EliminationPlan", <||>],
          "PlanFingerprint", Missing["PlanFingerprint"]] ||
      Lookup[result, "DegreeProfileFingerprint", None] =!=
        fingerprint[Lookup[result, "DegreeProfile", $Failed]] ||
      (planMode === "discover" &&
        (! TrueQ[Lookup[result, "NativePilotPerformed", False]] ||
          Lookup[result, "DensePilotPerformed", None] =!= False ||
          ! AssociationQ[Lookup[result, "NativePilotEvidence", $Failed]] ||
          ! AssociationQ[Lookup[result, "NativePilotRequest", $Failed]] ||
          ! AssociationQ[Lookup[result, "NativePilotCertificate", $Failed]] ||
          ! ListQ[Lookup[result, "NativeProbeSummaries", $Failed]] ||
          Count[Lookup[resultNativeProbeSummaries, "Status", None],
            "ConsistentNativeAffineImage"] <
              minimumConsistentNativeProbes ||
          ! AssociationQ[resultGenericityWitness] ||
          resultGenericRank =!=
            Lookup[Lookup[result, "EliminationPlan", <||>],
              "GenericRank", None] ||
          ! AssociationQ[resultSelectedProbe] ||
          Lookup[resultSelectedProbe, "Index", None] =!=
            Lookup[Lookup[result, "NativePilotEvidence", <||>],
              "SelectedProbeIndex", None] ||
          Lookup[resultGenericityWitness, "SelectedProbeIndex", None] =!=
            Lookup[resultSelectedProbe, "Index", None])) ||
      (planMode === "reuse" &&
        (Lookup[result, "EliminationPlan", $Failed] =!= eliminationPlan ||
          Lookup[result, "DegreeProfile", $Failed] =!=
            expectedDegreeProfile ||
          TrueQ[Lookup[result, "NativePilotPerformed", True]] ||
          Lookup[result, "NativePilotEvidence", $Failed] =!= None ||
          Lookup[result, "NativePilotRequest", $Failed] =!= None ||
          Lookup[result, "NativePilotCertificate", $Failed] =!= None ||
          Lookup[result, "NativeProbeSummaries", $Failed] =!= {} ||
          Lookup[result, "NativeGenericityWitness", $Failed] =!= None)) ||
      ! ListQ[Lookup[result, "SampleFailures", None]] ||
      ! IntegerQ[Lookup[result, "StablePivotSampleCount", None]] ||
      Lookup[result, "StablePivotSampleCount", 0] < constructionCount + 4 ||
      Lookup[result, "StablePivotSampleCount", 0] > sampleCount ||
      Lookup[result, "MinimumUsableSampleCount", None] =!=
        constructionCount + 4 ||
      Lookup[result, "InputEpsilonValues", None] =!= epsilonValues ||
      Lookup[result, "AttemptedEpsilonValues", None] =!= epsilonValues ||
      Lookup[result, "DiscardedEpsilonValues", None] =!=
        resultDiscardedEpsilonValues ||
      ! ListQ[resultSampleSummaries] ||
      Length[resultSampleSummaries] =!=
        Lookup[result, "StablePivotSampleCount", None] ||
      ! DuplicateFreeQ[Join[resultSampleEpsilonValues,
        resultDiscardedEpsilonValues]] ||
      Sort[Join[resultSampleEpsilonValues, resultDiscardedEpsilonValues]] =!=
        Sort[epsilonValues] ||
      If[planMode === "discover",
        Lookup[First[resultSampleSummaries], "Backend", None] =!=
            "FLINTAffineRREF" ||
          Lookup[First[resultSampleSummaries], "SolvePath", None] =!=
            "NativeCanonicalAffineRREFCertificate" ||
          ! AllTrue[Rest[resultSampleSummaries],
            Lookup[#1, "Backend", None] === "FLINT" &&
              Lookup[#1, "SolvePath", None] ===
                "OneConstrainedMultiRHSFactorization" &&
              TrueQ[Lookup[#1, "NormalizationCheck", False]] &&
              Lookup[#1, "BackendFallbackAllowed", None] === False &],
        ! AllTrue[resultSampleSummaries,
          Lookup[#1, "Backend", None] === "FLINT" &&
            Lookup[#1, "SolvePath", None] ===
              "OneConstrainedMultiRHSFactorization" &&
            TrueQ[Lookup[#1, "NormalizationCheck", False]] &&
            Lookup[#1, "BackendFallbackAllowed", None] === False &]]),
  result = <|"Status" -> "PrimeResultSemanticMismatch",
    "Prime" -> prime, "PlanAcquisitionMode" -> planMode|>];

preparationHashAtCompletion = FileHash[preparationFile,
  "SHA256", "HexString"];
planSourceHashAtCompletion = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];
sourceStateAtCompletion = <|
  "Preparation" -> preparationHashAtCompletion,
  "PlanSource" -> planSourceHashAtCompletion,
  "Prototype" -> FileHash[prototypeFile, "SHA256", "HexString"],
  "Dependencies" -> Map[FileHash[#1, "SHA256", "HexString"] &,
    dependencyFiles],
  "NativeDependencies" -> Map[FileHash[#1, "SHA256", "HexString"] &,
    nativeDependencyFiles],
  "NativeBinary" -> FileHash[nativeBinary, "SHA256", "HexString"],
  "FixedPlanFLINTBinary" -> FileHash[fixedPlanFLINTBinary,
    "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"],
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "Input" -> FileHash[inputFile, "SHA256", "HexString"]|>;
expectedSourceState = <|
  "Preparation" -> preparationHashBefore,
  "PlanSource" -> planSourceHashBefore,
  "Prototype" -> prototypeHashBefore,
  "Dependencies" -> dependencyHashesBefore,
  "NativeDependencies" -> nativeDependencyHashesBefore,
  "NativeBinary" -> nativeBinaryHashBefore,
  "FixedPlanFLINTBinary" -> fixedPlanFLINTBinaryHashBefore,
  "Driver" -> driverHashBefore,
  "PreparationDriver" -> preparationArtifact["DriverSHA256"],
  "Input" -> preparationArtifact["InputSHA256"]|>;
If[sourceStateAtCompletion =!= expectedSourceState,
  result = <|"Status" -> "SourceChangedBeforeCompletion",
    "Prime" -> prime,
    "ExpectedSourceState" -> expectedSourceState,
    "ObservedSourceState" -> sourceStateAtCompletion|>];
If[writeAtomic[result] === $Failed,
  Print["CF300S12R2NATIVE FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300S12R2NATIVE RESULT status=", result["Status"],
  " prime=", prime, " seconds=", Round[seconds, 0.001],
  " output=", outputFile];
Exit[If[result["Status"] === "RationalAffinePrimeInterpolated", 0, 2]];
