#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300S12R2NATIVEBENCH FAIL usage=<project-root> " <>
    "<preparation.wl> <fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
nativeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[nativeDirectory];
nativeBinary = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh", "bin", "flint_affine_rref"}];
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
adapterFile = FileNameJoin[{nativeDirectory, "FlintAffineRREFAdapter.wl"}];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! FileExistsQ[adapterFile] || ! FileExistsQ[nativeBinary] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300S12R2NATIVEBENCH FAIL invalid or stale target"];
  Exit[65]];

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp." <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status,
    "PreparationFile" -> preparationFile,
    "NativeBinary" -> nativeBinary|>, data];
  If[writeAtomic[result] === $Failed, Exit[98]];
  Print["CF300S12R2NATIVEBENCH RESULT status=", status,
    " output=", outputFile];
  Exit[code]
];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
adapterHashBefore = FileHash[adapterFile, "SHA256", "HexString"];
binaryHashBefore = FileHash[nativeBinary, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];

Get[dependencyFiles["LoadFACET"]];
Get[dependencyFiles["TripleRootAlgebra"]];
Get[dependencyFiles["TripleRootStripAdapter"]];
Get[dependencyFiles["TripleRootAffinePilot"]];
Get[dependencyFiles["TripleRootReconstructionPrototype"]];
Get[adapterFile];
If[Map[FileHash[#1, "SHA256", "HexString"] &, dependencyFiles] =!=
      dependencyHashesBefore ||
    FileHash[adapterFile, "SHA256", "HexString"] =!= adapterHashBefore ||
    FileHash[nativeBinary, "SHA256", "HexString"] =!= binaryHashBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["DependencyChangedDuringLoad", <||>, 95]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
If[FileHash[preparationFile, "SHA256", "HexString"] =!=
    preparationHashBefore,
  finish["PreparationChangedDuringRead", <||>, 96]];
preparationArtifactKeys = {"Status", "InputFile", "InputSHA256",
  "DriverFile", "DriverSHA256", "DependencyHashes", "SidecarCertificate",
  "RegulatorClearFactor", "PreparationSeconds", "RootOrderingFingerprint",
  "OneFormOrderFingerprint", "Preparation", "PreparationSummary"};
If[! AssociationQ[preparationArtifact] ||
    ! AllTrue[preparationArtifactKeys,
      KeyExistsQ[preparationArtifact, #1] &] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    Lookup[preparationArtifact, "DependencyHashes", None] =!=
      dependencyHashesBefore,
  finish["PreparationArtifactInvalid", <||>, 66]];
preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
inputFile = Lookup[preparationArtifact, "InputFile", $Failed];
If[! StringQ[preparationDriverFile] || ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None] ||
    ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
    FileHash[inputFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "InputSHA256", None],
  finish["PreparationProvenanceInvalid", <||>, 66]];
preparation = Lookup[preparationArtifact, "Preparation", $Failed];
summaryKeys = {"RootCount", "GradeCount", "RootSourceIndices",
  "RootFingerprints", "RootOrderingFingerprint", "Dimensions",
  "OneFormMetadata", "GaugeDenominator", "GaugeDenominatorDegrees",
  "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
  "UnknownCount", "EquationsPerPoint", "ABIFingerprint"};
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
      fingerprint[preparation["ABIPayload", "OneForms"]] ||
    Lookup[preparationArtifact, "PreparationSummary", None] =!=
      KeyTake[preparation, summaryKeys] ||
    TrueQ[Together[preparationArtifact["RegulatorClearFactor"]] === 0],
  finish["PreparationABIOrShapeInvalid", <||>, 67]];

sidecar = Lookup[preparationArtifact, "SidecarCertificate", $Failed];
sidecarKeys = {"RoundTripExact", "RoundTripSeconds",
  "ChannelEquationFingerprint", "SupportFingerprint",
  "TermGraphFingerprint", "ActiveGrades", "ActiveGradeRank",
  "GlobalRootSourceOrder", "StableLocalRootSourceOrder",
  "LocalToGlobalGradeMap", "LocalSquareClassCertificate"};
squareClass = If[AssociationQ[sidecar],
  Lookup[sidecar, "LocalSquareClassCertificate", $Failed], $Failed];
expectedGradeMap = Table[localMask -> Sum[
    BitGet[localMask, bit - 1] *
      2^(preparation["RootSourceIndices"][[bit]] - 1),
    {bit, preparation["RootCount"]}],
  {localMask, 0, preparation["GradeCount"] - 1}];
If[! AssociationQ[sidecar] ||
    ! AllTrue[sidecarKeys, KeyExistsQ[sidecar, #1] &] ||
    ! TrueQ[sidecar["RoundTripExact"]] ||
    ! AllTrue[{"ChannelEquationFingerprint", "SupportFingerprint",
        "TermGraphFingerprint"}, StringQ[sidecar[#1]] &] ||
    sidecar["ActiveGrades"] =!= {0, 2, 4} ||
    sidecar["ActiveGradeRank"] =!= 2 ||
    sidecar["StableLocalRootSourceOrder"] =!= {2, 3} ||
    sidecar["LocalToGlobalGradeMap"] =!= expectedGradeMap ||
    ! AssociationQ[squareClass] ||
    ! AllTrue[{"Independent", "Rank", "Masks", "Products", "Nonsquare"},
      KeyExistsQ[squareClass, #1] &] ||
    ! TrueQ[Lookup[squareClass, "Independent", False]] ||
    Lookup[squareClass, "Rank", None] =!= 2,
  finish["SidecarCertificateInvalid", <||>, 68]];

preference = Join[
  preparation["GaugeUnknownCount"] +
    Range[preparation["ResidueUnknownCount"]],
  Range[preparation["GaugeUnknownCount"]]];
If[Sort[preference] =!= Range[624],
  finish["PreferencePermutationInvalid", <||>, 69]];

probePrimes = {10007, 10039, 10067};
probeEpsilonValues = (#1/(#1 + 20) &) /@ Range[4];
minimumConsistentProbeCount = 2;
minimumDistinctConsistentPrimes = 2;
imageProbeRecords = {};
consistentImageProbes = {};
Do[
  Do[
    randomSeed = 730000 + Mod[probePrime, 100000];
    seed = Hash[{randomSeed, preparation["ABIFingerprint"], probePrime,
      probeEpsilonValue}, "CRC32"];
    {assemblySeconds, sample} = AbsoluteTiming[
      Block[{CodexTripleRootReconstruction`Private`$trValidatedABIFingerprint =
          preparation["ABIFingerprint"]},
        CodexTripleRootReconstruction`Private`trAssembleReconstructionSampleInternal[
          preparation, probeEpsilonValue, probePrime,
          "PointCount" -> Automatic,
          "MaximumAttempts" -> Automatic,
          "RandomSeed" -> seed,
          "ValidatedABIFingerprint" -> preparation["ABIFingerprint"]]]];
    If[! AssociationQ[sample] ||
        Lookup[sample, "Status", None] =!=
          "AssembledReconstructionSample" ||
        sample["ABIFingerprint"] =!= preparation["ABIFingerprint"] ||
        sample["Prime"] =!= probePrime ||
        sample["EpsilonValue"] =!= probeEpsilonValue ||
        sample["BranchFlipMask"] =!= 0 ||
        sample["MatrixDimensions"] =!= {672, 624} ||
        Dimensions[sample["Matrix"]] =!= {672, 624} ||
        Length[sample["AcceptedPoints"]] =!= 21 ||
        sample["NormalizationCount"] =!= 0 ||
        ! MatrixQ[sample["Matrix"], IntegerQ] ||
        ! VectorQ[sample["RightHandSide"],
          IntegerQ[#1] && 0 <= #1 < probePrime &] ||
        Length[sample["RightHandSide"]] =!= 672 ||
        ! AllTrue[Flatten[sample["AcceptedPoints"]],
          2 <= #1 <= probePrime - 2 &],
      AppendTo[imageProbeRecords, <|
        "Prime" -> probePrime, "EpsilonValue" -> probeEpsilonValue,
        "Status" -> "AssemblyRejected",
        "AssemblySeconds" -> assemblySeconds|>];
      Continue[]];
    probeNonce = Mod[Hash[{preparationHashBefore, driverHashBefore,
        probePrime, probeEpsilonValue, "probe", #1}, "SHA256"], 2^64] & /@
      {"hi", "lo"};
    If[probeNonce === {0, 0}, probeNonce = {0, 1}];
    probeRequest = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
      sample["Matrix"], sample["RightHandSide"], probePrime, preference,
      probeNonce];
    If[Lookup[probeRequest, "Status", None] =!= "CFFRRequestV1",
      finish["ImageProbeRequestConstructionFailed", <|
        "Prime" -> probePrime,
        "EpsilonValue" -> probeEpsilonValue|>, 70]];
    {probeNativeSeconds, probeRun} = AbsoluteTiming[
      CodexFLINTAffineRREFAdapter`CFFRRun[nativeBinary, probeRequest,
        1, True, 7200]];
    Which[
      Lookup[probeRun, "Status", None] === "InconsistentAffineImage",
        AppendTo[imageProbeRecords, <|
          "Prime" -> probePrime, "EpsilonValue" -> probeEpsilonValue,
          "Status" -> "InconsistentAffineImage",
          "FailureClass" -> Lookup[probeRun, "FailureClass", None],
          "ExitCode" -> Lookup[probeRun, "ExitCode", None],
          "AssemblySeconds" -> assemblySeconds,
          "NativeSeconds" -> probeNativeSeconds|>];
        If[StringQ[Lookup[probeRun, "ArtifactDirectory", None]] &&
            DirectoryQ[probeRun["ArtifactDirectory"]],
          Quiet[DeleteDirectory[probeRun["ArtifactDirectory"],
            DeleteContents -> True]]],
      Lookup[probeRun, "Status", None] === "VerifiedFLINTAffineRREFRun",
        probeCertificate = probeRun["Certificate"];
        probeVerification =
          CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
            probeRequest, probeCertificate];
        If[Lookup[probeVerification, "Status", None] =!=
              "VerifiedFLINTAffineRREFCertificate" ||
            ! AllTrue[Values[probeVerification["Checks"]], TrueQ],
          Quiet[DeleteDirectory[probeRun["ArtifactDirectory"],
            DeleteContents -> True]];
          finish["ImageProbeCertificateVerificationFailed", <|
            "Prime" -> probePrime,
            "EpsilonValue" -> probeEpsilonValue|>, 71]];
        probeRecord = <|
          "Prime" -> probePrime, "EpsilonValue" -> probeEpsilonValue,
          "Status" -> "ConsistentNativeAffineImage",
          "Rank" -> probeCertificate["Rank"],
          "Nullity" -> probeCertificate["Nullity"],
          "Seed" -> seed,
          "RandomSeed" -> randomSeed,
          "AssemblySeconds" -> assemblySeconds,
          "NativeSeconds" -> probeNativeSeconds,
          "Sample" -> sample|>;
        AppendTo[imageProbeRecords, probeRecord];
        AppendTo[consistentImageProbes, probeRecord];
        Quiet[DeleteDirectory[probeRun["ArtifactDirectory"],
          DeleteContents -> True]],
      True,
        If[StringQ[Lookup[probeRun, "ArtifactDirectory", None]] &&
            DirectoryQ[probeRun["ArtifactDirectory"]],
          Quiet[DeleteDirectory[probeRun["ArtifactDirectory"],
            DeleteContents -> True]]];
        finish["ImageProbeInfrastructureFailed", <|
          "Prime" -> probePrime, "EpsilonValue" -> probeEpsilonValue,
          "Run" -> KeyDrop[probeRun,
            {"Certificate", "Verification", "ArtifactDirectory"}]|>, 70]],
    {probePrime, probePrimes}];
  If[Length[consistentImageProbes] >= minimumConsistentProbeCount &&
      Length[DeleteDuplicates[Lookup[consistentImageProbes, "Prime"]]] >=
        minimumDistinctConsistentPrimes, Break[]],
  {probeEpsilonValue, probeEpsilonValues}];
If[Length[consistentImageProbes] < minimumConsistentProbeCount ||
    Length[DeleteDuplicates[Lookup[consistentImageProbes, "Prime"]]] <
      minimumDistinctConsistentPrimes,
  finish["NoCrossPrimeConsistentNativeImage", <|
    "ProbeRecords" -> (KeyDrop[#1, "Sample"] & /@ imageProbeRecords)|>,
    72]];
genericProbeRank = Max[Lookup[consistentImageProbes, "Rank"]];
selectedProbe = First[Select[consistentImageProbes,
  Lookup[#1, "Rank", -1] === genericProbeRank &]];
prime = selectedProbe["Prime"];
epsilonValue = selectedProbe["EpsilonValue"];
randomSeed = selectedProbe["RandomSeed"];
seed = selectedProbe["Seed"];
assemblySeconds = selectedProbe["AssemblySeconds"];
sample = selectedProbe["Sample"];

benchmarkRecords = {};
requests = {};
certificates = {};
plans = {};
Do[
  nonce = Mod[Hash[{preparationHashBefore, driverHashBefore, threads, #1},
      "SHA256"], 2^64] & /@ {"hi", "lo"};
  If[nonce === {0, 0}, nonce = {0, 1}];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    sample["Matrix"], sample["RightHandSide"], prime, preference, nonce];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    finish["RequestConstructionFailed", <|"Threads" -> threads|>, 70]];
  {nativeSeconds, run} = AbsoluteTiming[
    CodexFLINTAffineRREFAdapter`CFFRRun[nativeBinary, request,
      threads, True, 7200]];
  If[Lookup[run, "Status", None] =!= "VerifiedFLINTAffineRREFRun",
    If[StringQ[Lookup[run, "ArtifactDirectory", None]] &&
        DirectoryQ[run["ArtifactDirectory"]],
      Quiet[DeleteDirectory[run["ArtifactDirectory"],
        DeleteContents -> True]]];
    finish["NativeRunFailed", <|"Threads" -> threads,
      "NativeSeconds" -> nativeSeconds,
      "Run" -> KeyDrop[run, {"Certificate", "Verification"}]|>, 70]];
  certificate = run["Certificate"];
  verification = CodexFLINTAffineRREFAdapter`CFFRVerifyCertificate[
    request, certificate];
  If[Lookup[verification, "Status", None] =!=
      "VerifiedFLINTAffineRREFCertificate" ||
      ! AllTrue[Values[verification["Checks"]], TrueQ],
    Quiet[DeleteDirectory[run["ArtifactDirectory"], DeleteContents -> True]];
    finish["IndependentCertificateVerificationFailed",
      <|"Threads" -> threads|>, 71]];
  plan = CodexFLINTAffineRREFAdapter`CFFRConstructCrossPrimePlanV1[
    preparation, sample, seed, request, certificate];
  If[Lookup[plan, "Status", None] =!= "CrossPrimeEliminationPlanV1" ||
      ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
        preparation, plan],
    Quiet[DeleteDirectory[run["ArtifactDirectory"], DeleteContents -> True]];
    finish["V1PlanValidationFailed", <|"Threads" -> threads|>, 71]];
  AppendTo[requests, request];
  AppendTo[certificates, certificate];
  AppendTo[plans, plan];
  AppendTo[benchmarkRecords, <|
    "Threads" -> threads,
    "NativeSeconds" -> nativeSeconds,
    "RequestSHA256" -> FileHash[run["RequestFile"],
      "SHA256", "HexString"],
    "ResponseSHA256" -> FileHash[run["ResponseFile"],
      "SHA256", "HexString"],
    "RequestByteCount" -> FileByteCount[run["RequestFile"]],
    "ResponseByteCount" -> FileByteCount[run["ResponseFile"]],
    "CertificateFingerprint" -> fingerprint[KeyDrop[certificate, "Nonce"]],
    "PlanFingerprint" -> plan["PlanFingerprint"],
    "Rank" -> certificate["Rank"],
    "Nullity" -> certificate["Nullity"],
    "AllVerificationChecks" ->
      AllTrue[Values[verification["Checks"]], TrueQ]|>];
  Quiet[DeleteDirectory[run["ArtifactDirectory"], DeleteContents -> True]],
  {threads, {1, 2, 4}}];

If[! AllTrue[Rest[plans], SameQ[#1, First[plans]] &] ||
    ! AllTrue[Rest[certificates],
      SameQ[KeyDrop[#1, "Nonce"], KeyDrop[First[certificates], "Nonce"]] &],
  finish["CrossThreadSemanticMismatch", <|
    "BenchmarkRecords" -> benchmarkRecords|>, 72]];

sourceStateAtCompletion = <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Input" -> FileHash[inputFile, "SHA256", "HexString"],
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "Dependencies" -> Map[FileHash[#1, "SHA256", "HexString"] &,
    dependencyFiles],
  "Adapter" -> FileHash[adapterFile, "SHA256", "HexString"],
  "Binary" -> FileHash[nativeBinary, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedSourceState = <|
  "Preparation" -> preparationHashBefore,
  "Input" -> preparationArtifact["InputSHA256"],
  "PreparationDriver" -> preparationArtifact["DriverSHA256"],
  "Dependencies" -> dependencyHashesBefore,
  "Adapter" -> adapterHashBefore,
  "Binary" -> binaryHashBefore,
  "Driver" -> driverHashBefore|>;
If[sourceStateAtCompletion =!= expectedSourceState,
  finish["SourceChangedBeforeCompletion", <|
    "ExpectedSourceState" -> expectedSourceState,
    "ObservedSourceState" -> sourceStateAtCompletion|>, 97]];

result = <|
  "Status" -> "CF300Sector12Rank2NativePilotBenchmarkV2",
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> preparationHashBefore,
  "InputFile" -> inputFile,
  "InputSHA256" -> preparationArtifact["InputSHA256"],
  "DependencyHashes" -> dependencyHashesBefore,
  "AdapterFile" -> adapterFile,
  "AdapterSHA256" -> adapterHashBefore,
  "NativeBinary" -> nativeBinary,
  "NativeBinarySHA256" -> binaryHashBefore,
  "DriverFile" -> $InputFileName,
  "DriverSHA256" -> driverHashBefore,
  "ProbePrimes" -> probePrimes,
  "ProbeEpsilonValues" -> probeEpsilonValues,
  "ImageProbeSummaries" -> (KeyDrop[#1, "Sample"] & /@
    imageProbeRecords),
  "GenericityWitness" -> <|
    "Rule" -> "EarliestMaximumRankAcrossBoundedCrossPrimeEpsilonProbes",
    "ConsistentProbeCount" -> Length[consistentImageProbes],
    "DistinctConsistentPrimes" -> DeleteDuplicates[
      Lookup[consistentImageProbes, "Prime"]],
    "GenericRank" -> genericProbeRank,
    "SelectedPrime" -> prime,
    "SelectedEpsilonValue" -> epsilonValue|>,
  "Prime" -> prime,
  "EpsilonValue" -> epsilonValue,
  "RandomSeed" -> randomSeed,
  "SampleSeed" -> seed,
  "AssemblySeconds" -> assemblySeconds,
  "MatrixDimensions" -> sample["MatrixDimensions"],
  "AcceptedPoints" -> sample["AcceptedPoints"],
  "AttemptCount" -> sample["AttemptCount"],
  "BenchmarkRecords" -> benchmarkRecords,
  "CrossThreadCertificatesIdenticalModuloNonce" -> True,
  "CrossThreadPlansIdentical" -> True,
  "EliminationPlan" -> First[plans],
  "EliminationPlanFingerprint" -> First[plans]["PlanFingerprint"],
  "ReferenceRequest" -> First[requests],
  "ReferenceCertificate" -> First[certificates],
  "AllRowParticularResidualZero" -> True,
  "AllRowNullspaceResidualZero" -> True,
  "RowMinorInverseWitnessVerified" -> True,
  "NormalizationMinorInverseWitnessVerified" -> True|>;
If[writeAtomic[result] === $Failed, Exit[98]];
Print["CF300S12R2NATIVEBENCH RESULT status=", result["Status"],
  " assembly_seconds=", Round[assemblySeconds, 0.001],
  " output=", outputFile];
Exit[0];
