#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4,
  Print["CF300PHYSR3 FAIL usage=<project-root> <census.wl> <output.wl> " <>
    "<epsilon-degree> [unknown-cap] [run-evaluator-benchmarks]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
censusFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
epsilonDegree = Quiet[Check[ToExpression[arguments[[4]]], $Failed]];
unknownCap = If[Length[arguments] >= 5,
  Quiet[Check[ToExpression[arguments[[5]]], $Failed]], 5000];
runEvaluatorBenchmarks = If[Length[arguments] >= 6,
  Switch[arguments[[6]], "True", True, "False", False, _, $Failed], False];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[censusFile] ||
    ! IntegerQ[epsilonDegree] || epsilonDegree < 0 ||
    ! IntegerQ[unknownCap] || unknownCap < 1 ||
    ! MatchQ[runEvaluatorBenchmarks, True | False],
  Print["CF300PHYSR3 FAIL invalid arguments"];
  Exit[65]];

staleOutputTargets = Select[{outputFile, outputFile <> ".tmp"}, FileExistsQ];
If[staleOutputTargets =!= {},
  Print["CF300PHYSR3 FAIL stale output target: ", staleOutputTargets];
  Exit[93]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAffinePilot.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootReconstructionPrototype.wl"}]];

writeAtomic[value_] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, outputFile, OverwriteTarget -> False]
];

finishBlocked[status_String, details_: <||>, exitCode_: 2] := Module[
  {blocked = Join[<|"Status" -> status,
      "CensusFile" -> censusFile,
      "EpsilonDegree" -> epsilonDegree|>, details]},
  writeAtomic[blocked];
  Print["CF300PHYSR3 RESULT status=", status, " output=", outputFile];
  Exit[exitCode]
];

preparationABISummary[preparation_Association] := KeyTake[preparation,
  {"Status", "RootCount", "GradeCount", "RootSourceIndices",
    "RootFingerprints", "RootOrderingFingerprint", "Dimensions",
    "OneFormMetadata", "GaugeDenominator", "GaugeDenominatorDegrees",
    "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
    "UnknownCount", "EquationsPerPoint", "ABIFingerprint",
    "ABIPayload"}];

stableFileHash[file_String] := Quiet[Check[
  FileHash[file, "SHA256", "HexString"], $Failed]];
currentHashMatchesQ[binding_Rule] := Quiet[Check[
  StringQ[First[binding]] && StringQ[Last[binding]] &&
    FileExistsQ[First[binding]] &&
    stableFileHash[First[binding]] === Last[binding], False]];

censusHashBefore = stableFileHash[censusFile];
census = Quiet[Check[FeynFacet`FamilyArtifactRead[censusFile], $Failed]];
censusHashAfter = stableFileHash[censusFile];
If[! StringQ[censusHashBefore] || censusHashBefore =!= censusHashAfter,
  finishBlocked["CensusChangedDuringRead", <|
    "CensusSHA256Before" -> censusHashBefore,
    "CensusSHA256After" -> censusHashAfter|>, 66]];
If[! AssociationQ[census] ||
    Lookup[census, "Status", None] =!= "PreparedPhysicalRank3Strip",
  finishBlocked["CensusNotPrepared",
    <|"ObservedCensusStatus" -> Lookup[census, "Status", None]|>, 66]];

sidecarEvidence = Lookup[census, "SidecarEvidence", $Failed];
If[! AssociationQ[sidecarEvidence] ||
    ! TrueQ[Lookup[sidecarEvidence,
      "PhysicalRegularAssociationSameQ", False]],
  finishBlocked["CensusSidecarEvidenceInvalid", <||>, 67]];

inputFile = ExpandFileName[
  Lookup[Lookup[census, "Selected", <||>], "File", ""]];
expectedInputFile = ExpandFileName[
  Lookup[sidecarEvidence, "RegularInputFile", ""]];
expectedInputHash = Lookup[sidecarEvidence, "RegularInputSHA256", $Failed];
scalePower = Lookup[Lookup[census, "ScaledEquation", <||>],
  "ScalePower", $Failed];
If[inputFile =!= expectedInputFile || ! FileExistsQ[inputFile] ||
    ! StringQ[expectedInputHash] ||
    Lookup[Lookup[census, "Selected", <||>], "InputSHA256", None] =!=
      expectedInputHash ||
    ! IntegerQ[scalePower] || scalePower < 0,
  finishBlocked["InvalidCensusSelection", <|
    "SelectedInputFile" -> inputFile,
    "ExpectedInputFile" -> expectedInputFile,
    "SelectedInputSHA256" -> Lookup[
      Lookup[census, "Selected", <||>], "InputSHA256", None],
    "ExpectedInputSHA256" -> expectedInputHash|>, 68]];

evidenceFiles = {
  Lookup[sidecarEvidence, "SidecarResultFile", $Failed] ->
    Lookup[sidecarEvidence, "SidecarResultSHA256", $Failed],
  Lookup[sidecarEvidence, "SuccessSentinelFile", $Failed] ->
    Lookup[sidecarEvidence, "SuccessSentinelSHA256", $Failed],
  Lookup[sidecarEvidence, "PhysicalInputFile", $Failed] ->
    Lookup[sidecarEvidence, "PhysicalInputSHA256", $Failed]};
evidenceFilesCurrentQ = AllTrue[evidenceFiles, Function[binding,
  currentHashMatchesQ[binding]]];
If[! evidenceFilesCurrentQ,
  finishBlocked["SidecarEvidenceHashMismatch", <|
    "EvidenceFiles" -> evidenceFiles|>, 69]];

inputHashBefore = stableFileHash[inputFile];
record = Quiet[Check[FeynFacet`FamilyArtifactRead[inputFile], $Failed]];
inputHashAfter = stableFileHash[inputFile];
frame = FeynFacet`TransportFamilyChart["CF300"];
If[inputHashBefore =!= inputHashAfter || inputHashAfter =!= expectedInputHash,
  finishBlocked["PhysicalInputHashMismatch", <|
    "InputFile" -> inputFile, "ExpectedSHA256" -> expectedInputHash,
    "SHA256Before" -> inputHashBefore,
    "SHA256After" -> inputHashAfter|>, 70]];
If[! AssociationQ[record] || ! AssociationQ[frame] ||
    Lookup[record, "Family", None] =!= "CF300" ||
    Lookup[record, "Sector", None] =!= 12 ||
    Lookup[record, "LowerSector", None] =!=
      Lookup[sidecarEvidence, "SelectedLowerSector", None],
  finishBlocked["PhysicalInputReadFailed", <|
    "InputFile" -> inputFile,
    "RecordFamily" -> Lookup[record, "Family", None],
    "RecordSector" -> Lookup[record, "Sector", None],
    "RecordLowerSector" -> Lookup[record, "LowerSector", None]|>, 71]];

epsilon = record["Regulator"];
scaledRecord = Join[record, <|"Strip" -> ReplacePart[
  record["Strip"], 3 -> Map[Together[epsilon^scalePower #1] &,
    record["Strip"][[3]], {2}]]|>];

Print["CF300PHYSR3 input=", inputFile,
  " strip=", {record["Sector"], record["LowerSector"]},
  " scale=eps^", scalePower, " epsilon_degree=", epsilonDegree];

{scaledPreparationSeconds, scaledPreparation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    scaledRecord, frame]];
If[Lookup[scaledPreparation, "Status", None] =!=
      "PreparedReconstruction" ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      scaledPreparation],
  finishBlocked["ScaledPreparationFailed", <|
    "InputFile" -> inputFile, "ScalePower" -> scalePower,
    "PreparationSeconds" -> scaledPreparationSeconds,
    "Preparation" -> scaledPreparation|>]];

censusPreparationSummary = Lookup[census, "PreparationSummary", $Failed];
scaledPreparationABISummary = preparationABISummary[scaledPreparation];
If[! AssociationQ[censusPreparationSummary] ||
    ! SameQ[scaledPreparationABISummary, censusPreparationSummary],
  finishBlocked["CensusPreparationABIMismatch", <|
    "InputFile" -> inputFile,
    "CensusPreparationSummary" -> censusPreparationSummary,
    "RecomputedPreparationSummary" -> scaledPreparationABISummary,
    "ScaledPreparationSeconds" -> scaledPreparationSeconds|>, 72]];

{originalPreparationSeconds, originalPreparation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    record, frame,
    "OneForms" -> scaledPreparation["OneForms"],
    "GaugeDenominator" -> scaledPreparation["GaugeDenominator"],
    "Support" -> scaledPreparation["GaugeSupport"]]];
If[Lookup[originalPreparation, "Status", None] =!=
      "PreparedReconstruction" ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      originalPreparation],
  finishBlocked["OriginalPreparationFailed", <|
    "InputFile" -> inputFile,
    "ScaledPreparationSeconds" -> scaledPreparationSeconds,
    "OriginalPreparationSeconds" -> originalPreparationSeconds,
    "OriginalPreparation" -> originalPreparation|>]];

supportFingerprint = Hash[ToString[InputForm[<|
    "RootFingerprints" -> scaledPreparation["RootFingerprints"],
    "GaugeDenominator" ->
      scaledPreparation["ABIPayload"]["GaugeDenominator"],
    "GaugeSupport" -> scaledPreparation["GaugeSupport"],
    "OneForms" -> scaledPreparation["ABIPayload"]["OneForms"],
    "Dimensions" -> scaledPreparation["Dimensions"]|>]],
  "SHA256", "HexString"];
fingerprints = <|
  "OriginalEquation" ->
    originalPreparation["ABIPayload"]["EquationFingerprint"],
  "ScaledEquation" ->
    scaledPreparation["ABIPayload"]["EquationFingerprint"],
  "Support" -> supportFingerprint,
  "OriginalEquationAndSupport" -> originalPreparation["ABIFingerprint"],
  "ScaledEquationAndSupport" -> scaledPreparation["ABIFingerprint"]|>;

preparationSummary = Join[scaledPreparationABISummary, <|
  "OneFormCount" -> Length[scaledPreparation["OneForms"]],
  "Fingerprints" -> fingerprints|>];

If[scaledPreparation["RootCount"] =!= 3 ||
    scaledPreparation["GradeCount"] =!= 8,
  finishBlocked["SelectedStripNotRank3", <|
    "InputFile" -> inputFile,
    "PreparationSummary" -> preparationSummary|>]];
If[scaledPreparation["UnknownCount"] > unknownCap,
  finishBlocked["PreparedSupportExceedsUnknownCap", <|
    "InputFile" -> inputFile, "UnknownCap" -> unknownCap,
    "ScaledPreparationSeconds" -> scaledPreparationSeconds,
    "OriginalPreparationSeconds" -> originalPreparationSeconds,
    "PreparationSummary" -> preparationSummary|>]];

trainingPrimes = {10007, 10039, 10067};
unseenPrime = 1000003;
epsilonPool = {1/2, 2/3, 3/5, 4/7, 5/11, 6/13, 7/17,
  8/19, 9/23, 10/29};
If[epsilonDegree + 2 > Length[epsilonPool],
  finishBlocked["EpsilonDegreeScheduleTooShort", <|
    "RequiredSamples" -> epsilonDegree + 2,
    "AvailableSamples" -> Length[epsilonPool]|>]];
epsilonSamples = Take[epsilonPool, epsilonDegree + 2];

denseUnknownLimit = 1200;
denseRawByteLimit = 64 * 1024^2;
densePointCount = Max[4, Ceiling[
  (scaledPreparation["UnknownCount"] +
    scaledPreparation["EquationsPerPoint"])/
  scaledPreparation["EquationsPerPoint"]]];
denseRowCount = densePointCount * scaledPreparation["EquationsPerPoint"] +
  Length[scaledPreparation["Normalizations"]];
denseRawAugmentedBytes = 8 denseRowCount *
  (scaledPreparation["UnknownCount"] + 1);
denseSolveBudget = <|
  "UnknownLimit" -> denseUnknownLimit,
  "RawAugmentedByteLimit" -> denseRawByteLimit,
  "UnknownCount" -> scaledPreparation["UnknownCount"],
  "PointCount" -> densePointCount, "RowCount" -> denseRowCount,
  "ColumnCountIncludingRightHandSide" ->
    scaledPreparation["UnknownCount"] + 1,
  "EstimatedRawAugmentedBytes" -> denseRawAugmentedBytes|>;
If[scaledPreparation["UnknownCount"] > denseUnknownLimit ||
    denseRawAugmentedBytes > denseRawByteLimit,
  finishBlocked["DenseSolveBudgetExceeded", <|
    "InputFile" -> inputFile,
    "PreparationSummary" -> preparationSummary,
    "DenseSolveBudget" -> denseSolveBudget|>, 73]];

Print["CF300PHYSR3 support_count=",
  Length[scaledPreparation["GaugeSupport"]],
  " one_forms=", Length[scaledPreparation["OneForms"]],
  " unknowns=", scaledPreparation["UnknownCount"],
  " equation_fingerprint=", fingerprints["OriginalEquation"],
  " support_fingerprint=", fingerprints["Support"]];

evaluatorBenchmarks = If[runEvaluatorBenchmarks, Table[Module[
  {sampleSeconds, sample, solveSeconds, solve},
  {sampleSeconds, sample} = AbsoluteTiming[
    CodexTripleRootReconstruction`TRAssembleReconstructionSample[
      scaledPreparation, First[epsilonSamples], prime,
      "RandomSeed" -> 70100 + prime]];
  If[Lookup[sample, "Status", None] ===
      "AssembledReconstructionSample",
    {solveSeconds, solve} = AbsoluteTiming[
      CodexTripleRootReconstruction`TRCanonicalAffineSolve[
        sample["Matrix"], sample["RightHandSide"], prime]],
    solveSeconds = 0.; solve = <|"Status" -> "NotRun"|>];
  Print["CF300PHYSR3 evaluator prime=", prime,
    " status=", Lookup[sample, "Status", None],
    " matrix=", Lookup[sample, "MatrixDimensions", None],
    " assemble_seconds=", Round[sampleSeconds, 0.001],
    " solve_seconds=", Round[solveSeconds, 0.001],
    " rank=", Lookup[solve, "Rank", None],
    " nullity=", Lookup[solve, "Nullity", None]];
  <|"Prime" -> prime, "AssemblySeconds" -> sampleSeconds,
    "SampleSummary" -> If[AssociationQ[sample],
      KeyDrop[sample, {"Matrix", "RightHandSide"}], sample],
    "SolveSeconds" -> solveSeconds,
    "SolveSummary" -> If[AssociationQ[solve],
      KeyDrop[solve, {"ParticularSolution", "NullspaceBasis"}], solve]|>
], {prime, trainingPrimes}], {}];

If[runEvaluatorBenchmarks && ! AllTrue[evaluatorBenchmarks,
    Lookup[Lookup[#1, "SampleSummary", <||>], "Status", None] ===
        "AssembledReconstructionSample" &&
      Lookup[Lookup[#1, "SolveSummary", <||>], "Status", None] ===
        "CanonicalAffineSolution" &],
  finishBlocked["ConstructionPrimeEvaluatorBlocked", <|
    "InputFile" -> inputFile,
    "ScaledPreparationSeconds" -> scaledPreparationSeconds,
    "OriginalPreparationSeconds" -> originalPreparationSeconds,
    "PreparationSummary" -> preparationSummary,
    "EvaluatorBenchmarks" -> evaluatorBenchmarks|>]];

{reconstructionSeconds, reconstruction} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRReconstructAffineBatch[
    scaledPreparation, epsilonSamples, trainingPrimes,
    "EpsilonDegree" -> epsilonDegree,
    "RandomSeed" -> 712300,
    "Verbose" -> True]];
If[Lookup[reconstruction, "Status", None] =!= "ExactReconstruction",
  finishBlocked["PhysicalReconstructionBlocked", <|
    "InputFile" -> inputFile, "ScalePower" -> scalePower,
    "TrainingPrimes" -> trainingPrimes,
    "EpsilonSamples" -> epsilonSamples,
    "ScaledPreparationSeconds" -> scaledPreparationSeconds,
    "OriginalPreparationSeconds" -> originalPreparationSeconds,
    "ReconstructionSeconds" -> reconstructionSeconds,
    "PreparationSummary" -> preparationSummary,
    "EvaluatorBenchmarks" -> evaluatorBenchmarks,
    "Reconstruction" -> reconstruction|>]];

originalVector = Together /@
  (reconstruction["ReconstructedVector"]/epsilon^scalePower);
originalExact = CodexTripleRootReconstruction`TRExactChannelResidual[
  originalPreparation, originalVector];
originalResult = Join[reconstruction, <|
  "Preparation" -> originalPreparation,
  "ABIFingerprint" -> originalPreparation["ABIFingerprint"],
  "ReconstructedVector" -> originalVector|>];

{unseenSeconds, unseen} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    originalResult, unseenPrime, {11/31, 12/37},
    "RandomSeed" -> 723100]];
{allSignsSeconds, signChecks} = AbsoluteTiming[Table[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    originalResult, unseenPrime, {13/41, 14/43},
    "RandomSeed" -> 724000 + signMask,
    "BranchFlipMask" -> signMask],
  {signMask, 0, 7}]];

censusHashAtCompletion = stableFileHash[censusFile];
inputHashAtCompletion = stableFileHash[inputFile];
evidenceFilesStableAtCompletionQ = AllTrue[evidenceFiles,
  currentHashMatchesQ];
If[censusHashAtCompletion =!= censusHashAfter ||
    inputHashAtCompletion =!= expectedInputHash ||
    ! evidenceFilesStableAtCompletionQ,
  finishBlocked["ProvenanceChangedDuringReconstruction", <|
    "CensusSHA256Before" -> censusHashBefore,
    "CensusSHA256AtCompletion" -> censusHashAtCompletion,
    "InputSHA256Before" -> inputHashBefore,
    "InputSHA256AtCompletion" -> inputHashAtCompletion,
    "ExpectedInputSHA256" -> expectedInputHash,
    "EvidenceFilesStableAtCompletionQ" ->
      evidenceFilesStableAtCompletionQ|>, 74]];

accepted = Lookup[originalExact, "Status", None] ===
      "ExactChannelResidualZero" &&
    TrueQ[Lookup[originalExact, "ResidualZero", False]] &&
    Lookup[unseen, "Status", None] === "UnseenPrimeVerified" &&
    AllTrue[signChecks,
      Lookup[#1, "Status", None] === "UnseenPrimeVerified" &&
        TrueQ[Lookup[#1, "ResidualZero", False]] &];

result = <|"Status" -> If[accepted,
    "PhysicalRank3ReconstructionCertified",
    "PhysicalRank3VerificationFailed"],
  "InputFile" -> inputFile, "CensusFile" -> censusFile,
  "CensusSHA256" -> censusHashAfter,
  "InputSHA256" -> inputHashAfter,
  "SidecarEvidence" -> sidecarEvidence,
  "Strip" -> {record["Sector"], record["LowerSector"]},
  "ScalePower" -> scalePower, "EpsilonDegree" -> epsilonDegree,
  "TrainingPrimes" -> trainingPrimes, "UnseenPrime" -> unseenPrime,
  "EpsilonSamples" -> epsilonSamples,
  "ScaledPreparationSeconds" -> scaledPreparationSeconds,
  "OriginalPreparationSeconds" -> originalPreparationSeconds,
  "ReconstructionSeconds" -> reconstructionSeconds,
  "UnseenVerificationSeconds" -> unseenSeconds,
  "AllEightSignMasksSeconds" -> allSignsSeconds,
  "PreparationSummary" -> preparationSummary,
  "DenseSolveBudget" -> denseSolveBudget,
  "EvaluatorBenchmarksEnabled" -> runEvaluatorBenchmarks,
  "EvaluatorBenchmarks" -> evaluatorBenchmarks,
  "ScaledReconstruction" -> reconstruction,
  "OriginalReconstructedVector" -> originalVector,
  "OriginalExactVerification" -> originalExact,
  "UnseenPrimeVerification" -> unseen,
  "SignBranchVerifications" -> signChecks|>;
writeAtomic[result];
Print["CF300PHYSR3 RESULT status=", result["Status"],
  " strip=", result["Strip"],
  " reconstruction_seconds=", Round[reconstructionSeconds, 0.001],
  " unseen_seconds=", Round[unseenSeconds, 0.001],
  " all_signs_seconds=", Round[allSignsSeconds, 0.001],
  " output=", outputFile];
Exit[If[accepted, 0, 1]];
