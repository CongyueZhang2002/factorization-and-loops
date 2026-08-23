#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{5, 6}, Length[arguments]],
  Print["CF300_DENOM_WITNESS FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <denominator-census.wl> <output.wl> " <>
    "[ALL|factor-fingerprint]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
censusFile = ExpandFileName[arguments[[4]]];
outputFile = ExpandFileName[arguments[[5]]];
candidateSelector = If[Length[arguments] === 6, arguments[[6]], "ALL"];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
adapterDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh"}];
nativeDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh"}];

files = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}],
  "Assembler" -> FileNameJoin[{directDirectory,
    "DirectRootChannelAssembler.wl"}],
  "ArtifactHelper" -> FileNameJoin[{directDirectory,
    "DirectRootChannelCompiledArtifact.wl"}],
  "AnsatzRebind" -> FileNameJoin[{driverDirectory,
    "DirectRootChannelAnsatzRebind.wl"}],
  "NativeAdapter" -> FileNameJoin[{adapterDirectory,
    "FlintAffineRREFAdapter.wl"}],
  "WitnessHelper" -> FileNameJoin[{driverDirectory,
    "AffineInconsistencyWitness.wl"}],
  "NativeBinary" -> FileNameJoin[{nativeDirectory, "bin",
    "flint_affine_rref"}]|>;
expectedHashes = <|
  "LoadFACET" ->
    "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
  "TripleRootAlgebra" ->
    "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "TripleRootStripAdapter" ->
    "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "TripleRootAffinePilot" ->
    "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "TripleRootReconstructionPrototype" ->
    "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "Assembler" ->
    "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "ArtifactHelper" ->
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
  "AnsatzRebind" ->
    "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907",
  "NativeAdapter" ->
    "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605",
  "WitnessHelper" ->
    "6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f",
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
expectedPreparationHash =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedCensusHash =
  "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a";
expectedCandidateFingerprints = Sort[{
  "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881",
  "c799eabc0695b12beeccf7a2edfa9702dc5efaddfdec7bf64437b73807eff7ed",
  "ce44a483203b0cde640e984643bcf415afd24ea95df2b50ee87ae72e232be10e"}];

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
    Quiet[Check[Get[file], $Failed]]]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[
      value === $Aborted, "Aborted",
      value === $Failed, "Failed",
      True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>
];
deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]
];
writeAtomic[value_] := Module[{temporary, written, renamed, reread},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  reread = Quiet[Check[Get[outputFile], $Failed]];
  If[! SameQ[reread, value],
    deleteIfPresent[outputFile]; Return[$Failed]];
  outputFile
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status|>, data];
  If[writeAtomic[result] === $Failed, Exit[98]];
  Print["CF300_DENOM_WITNESS status=", status,
    " output=", outputFile];
  Exit[code]
];
modRational[value_, prime_Integer] := Module[{q = Together[value]},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  Mod[Numerator[q] PowerMod[Mod[Denominator[q], prime], -1, prime],
    prime]
];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[censusFile] || FileExistsQ[outputFile] ||
    ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300_DENOM_WITNESS FAIL invalid inputs or stale output"];
  Exit[65]];
If[! MemberQ[Append[expectedCandidateFingerprints, "ALL"],
    candidateSelector],
  Print["CF300_DENOM_WITNESS FAIL invalid candidate selector"];
  Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash,
  Print["CF300_DENOM_WITNESS FAIL pinned source or artifact mismatch"];
  Exit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
loadOutcome = AllTrue[Lookup[Values[loadOutcomes], "Status", None],
  #1 === "Loaded" &];
If[! TrueQ[loadOutcome] || hashes[] =!= sourceHashesBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["PinnedLoadFailed", <|
    "LoadOutcome" -> loadOutcome,
    "LoadOutcomes" -> loadOutcomes,
    "ExpectedSourceHashes" -> sourceHashesBefore,
    "ObservedSourceHashes" -> hashes[],
    "ExpectedDriverSHA256" -> driverHashBefore,
    "ObservedDriverSHA256" ->
      FileHash[$InputFileName, "SHA256", "HexString"]|>, 67]];

preparationArtifact = artifactRead[preparationFile];
compiledArtifact =
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile];
censusArtifact = artifactRead[censusFile];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    ! AssociationQ[compiledArtifact] ||
    Lookup[compiledArtifact, "Status", None] =!=
      "DirectRootChannelCompiledArtifactV1" ||
    ! AssociationQ[censusArtifact] ||
    Lookup[censusArtifact, "Status", None] =!=
      "CF300Sector12DenominatorCensusPassed",
  finish["PinnedArtifactsInvalid", <||>, 68]];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = compiledArtifact["DirectAssembly"];
candidates = censusArtifact["EpsilonFreeSimplePoleCandidates"];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly] ||
    baseAssembly["SourceABIFingerprint"] =!=
      basePreparation["ABIFingerprint"] ||
    Length[candidates] =!= 3 ||
    Sort[Lookup[candidates, "FactorFingerprint"]] =!=
      expectedCandidateFingerprints ||
    ! AllTrue[candidates,
      TrueQ[#1["OmittedByForcingSimplePoleRule"]] &&
        TrueQ[#1["EpsilonFree"]] &&
        TrueQ[#1["KinematicsDependent"]] &],
  finish["BaseOrCandidateContractInvalid", <||>, 69]];

{x, y} = basePreparation["Variables"];
epsilon = basePreparation["Regulator"];
baseSupport = basePreparation["GaugeSupport"];
baseSupportCount = Length[baseSupport];
baseGaugeCount = basePreparation["GaugeUnknownCount"];
baseResidueCount = basePreparation["ResidueUnknownCount"];
{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
If[{upper, lower, gradeCount, baseSupportCount, baseGaugeCount,
      baseResidueCount} =!= {2, 2, 4, 30, 480, 144},
  finish["PhysicalDimensionContractInvalid", <||>, 70]];

buildTarget[candidate_Association] := Module[
  {factor, changedDenominator, changedDegrees, support,
   factorRules, requiredSupport, payload, gaugeCount, residueCount,
   target, rebound, pointCount},
  factor = candidate["Factor"];
  If[! PolynomialQ[factor, {x, y}] || ! FreeQ[factor, epsilon],
    Return[$Failed]];
  changedDenominator = Together[
    basePreparation["GaugeDenominator"] factor];
  changedDegrees = Exponent[changedDenominator, #1] & /@ {x, y};
  support = Flatten[Table[{px, py},
    {px, 0, changedDegrees[[1]]},
    {py, 0, changedDegrees[[2]]}], 1];
  factorRules = CoefficientRules[Expand[factor], {x, y}];
  requiredSupport = Union[Flatten[Table[
    oldMonomial + factorRule[[1]],
    {oldMonomial, baseSupport}, {factorRule, factorRules}], 1]];
  If[factorRules === {} ||
      Complement[requiredSupport, support] =!= {} ||
      ! DuplicateFreeQ[support], Return[$Failed]];
  gaugeCount = upper lower gradeCount Length[support];
  residueCount = Length[basePreparation["OneForms"]] upper lower;
  payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
    basePreparation["Record"], basePreparation["Roots"],
    basePreparation["Variables"], epsilon,
    basePreparation["Dimensions"], changedDenominator, support,
    basePreparation["OneForms"], basePreparation["Normalizations"]];
  If[payload === $Failed, Return[$Failed]];
  target = Join[basePreparation, <|
    "OneFormMetadata" -> <|
      "Status" -> "CF300DenominatorWitnessPureSupersetV1",
      "FactorFingerprint" -> candidate["FactorFingerprint"]|>,
    "GaugeDenominator" -> changedDenominator,
    "GaugeDenominatorDegrees" -> changedDegrees,
    "GaugeSupport" -> support,
    "GaugeUnknownCount" -> gaugeCount,
    "ResidueUnknownCount" -> residueCount,
    "UnknownCount" -> gaugeCount + residueCount,
    "ABIPayload" -> payload,
    "ABIFingerprint" -> fingerprint[payload]|>];
  If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    Return[$Failed]];
  rebound = CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, target];
  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        rebound] ||
      rebound["SourceABIFingerprint"] =!= target["ABIFingerprint"],
    Return[$Failed]];
  pointCount = Max[4, Ceiling[(target["UnknownCount"] + 32)/32]];
  <|"Candidate" -> candidate, "FactorRules" -> factorRules,
    "RequiredOldGaugeNumeratorSupport" -> requiredSupport,
    "TargetPreparation" -> target, "TargetAssembly" -> rebound,
    "PointCount" -> pointCount|>
];

{targetBuildSeconds, targets} = AbsoluteTiming[buildTarget /@ candidates];
If[MemberQ[targets, $Failed] || Length[targets] =!= 3,
  finish["CandidateTargetBuildFailed", <|
    "TargetBuildSeconds" -> targetBuildSeconds|>, 71]];
targets = If[candidateSelector === "ALL", targets,
  Select[targets,
    #1["Candidate", "FactorFingerprint"] === candidateSelector &]];
If[Length[targets] =!= If[candidateSelector === "ALL", 3, 1],
  finish["CandidateSelectorResolutionFailed", <|
    "CandidateSelector" -> candidateSelector|>, 71]];
Print["CF300_DENOM_WITNESS milestone=targets_ready elapsed_s=",
  targetBuildSeconds, " point_counts=", Lookup[targets, "PointCount"],
  " candidate_selector=", candidateSelector];

containmentProjection[target_Association, targetMatrix_?MatrixQ,
    prime_Integer] := Module[
  {targetPreparation, targetSupport, targetSupportCount,
   targetGaugeCount, factorRules, rows, gaugeColumns,
   residueColumns, targetPositions, coefficients, columns,
   targetPosition, targetColumn, oldMonomial, oldColumnVectors},
  targetPreparation = target["TargetPreparation"];
  targetSupport = targetPreparation["GaugeSupport"];
  targetSupportCount = Length[targetSupport];
  targetGaugeCount = targetPreparation["GaugeUnknownCount"];
  factorRules = target["FactorRules"];
  rows = Dimensions[targetMatrix][[1]];
  oldColumnVectors = Flatten[Table[
    oldMonomial = baseSupport[[monomial]];
    targetPositions = Table[
      targetPosition = FirstPosition[targetSupport,
        oldMonomial + factorRule[[1]], Missing["Absent"]];
      If[! MatchQ[targetPosition, {_Integer}], Return[$Failed, Module]];
      First[targetPosition],
      {factorRule, factorRules}];
    coefficients = modRational[#[[2]], prime] & /@ factorRules;
    If[MemberQ[coefficients, $Failed], Return[$Failed, Module]];
    columns = Table[
      targetColumn =
        (((i - 1) lower + (j - 1)) gradeCount + grade)
          targetSupportCount + targetPositions[[term]];
      coefficients[[term]] targetMatrix[[All, targetColumn]],
      {term, Length[factorRules]}];
    Mod[Total[columns], prime],
    {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
    {monomial, baseSupportCount}], 3];
  gaugeColumns = Transpose[oldColumnVectors];
  residueColumns = targetMatrix[[All,
    targetGaugeCount + Range[baseResidueCount]]];
  If[Dimensions[gaugeColumns] =!= {rows, baseGaugeCount} ||
      Dimensions[residueColumns] =!= {rows, baseResidueCount},
    Return[$Failed]];
  Developer`ToPackedArray[Mod[
    Join[gaugeColumns, residueColumns, 2], prime]]
];

canonicalVectorQ[array_, length_Integer, prime_Integer] := TrueQ[
  VectorQ[array, IntegerQ] && Length[array] === length &&
    AllTrue[array, 0 <= #1 < prime &]];
canonicalMatrixQ[array_, rows_Integer, columns_Integer,
    prime_Integer] := TrueQ[
  If[rows === 0,
    array === {},
    MatrixQ[array, IntegerQ] && Dimensions[array] === {rows, columns}] &&
  AllTrue[Flatten[Normal[array]], 0 <= #1 < prime &]];
nativeRankFailure[status_String, data_: <||>] :=
  Join[<|"Status" -> status|>, data];
nativeRank[localMatrix_?MatrixQ, prime_Integer, label_String,
    imageID_String, tag_String] := Module[
  {rows, columns, request, seconds, run, certificate, rank, nullity,
   diagnosticSeconds, diagnosticRun},
  {rows, columns} = Dimensions[localMatrix];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    localMatrix, ConstantArray[0, Dimensions[localMatrix][[1]]],
    prime, Range[columns], makeNonce[label, imageID, tag]];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    Return[nativeRankFailure["NativeRankRequestFailed", <|
      "RequestStatus" -> Lookup[request, "Status", None]|>]]];
  {seconds, run} = AbsoluteTiming[
    CodexFLINTAffineRREFAdapter`CFFRRun[
      files["NativeBinary"], request, 1, False, 600]];
  If[Lookup[run, "Status", None] =!=
      "VerifiedFLINTAffineRREFRun",
    {diagnosticSeconds, diagnosticRun} = AbsoluteTiming[
      CodexFLINTAffineRREFAdapter`CFFRRun[
        files["NativeBinary"], request, 1, True, 600]];
    Return[nativeRankFailure["NativeRankRunFailed", <|
      "RunStatus" -> Lookup[run, "Status", None],
      "Verification" -> Lookup[run, "Verification", Missing["Absent"]],
      "DiagnosticRunStatus" ->
        Lookup[diagnosticRun, "Status", None],
      "DiagnosticVerification" ->
        Lookup[diagnosticRun, "Verification", Missing["Absent"]],
      "DiagnosticArtifactDirectory" ->
        Lookup[diagnosticRun, "ArtifactDirectory", Missing["Absent"]],
      "DiagnosticSeconds" -> diagnosticSeconds,
      "Seconds" -> seconds|>]]];
  certificate = run["Certificate"];
  rank = certificate["Rank"];
  nullity = certificate["Nullity"];
  If[certificate["ParticularSolution"] =!=
        ConstantArray[0, columns] ||
      rank + nullity =!= columns ||
      ! canonicalVectorQ[certificate["ParticularSolution"], columns,
        prime] ||
      ! canonicalMatrixQ[certificate["NullspaceBasis"], nullity,
        columns, prime],
    Return[nativeRankFailure[
      "NativeRankCertificatePostconditionFailed", <|
        "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
        "Nullity" -> nullity,
        "ParticularDimensions" ->
          Dimensions[certificate["ParticularSolution"]],
        "NullspaceDimensions" ->
          Dimensions[certificate["NullspaceBasis"]],
        "Seconds" -> seconds|>]]];
  <|"Status" -> "VerifiedNativeRankV1",
    "MatrixDimensions" -> Dimensions[localMatrix],
    "Rank" -> rank,
    "Nullity" -> nullity,
    "Seconds" -> seconds,
    "PivotFingerprint" ->
      fingerprint[certificate["PivotColumns"]],
    "FreeColumnFingerprint" ->
      fingerprint[certificate["FreeColumns"]],
    "RowWitnessFingerprint" ->
      fingerprint[certificate["IndependentEquationRows"]]|>
];
rankImage[matrix_?MatrixQ, right_List, prime_Integer,
    label_String, imageID_String] := Module[
  {rows, columns, rightColumn, augmented, coefficient, augmentedRank},
  {rows, columns} = Dimensions[matrix];
  rightColumn = SparseArray[
    MapIndexed[{First[#2], 1} -> #1 &, right], {rows, 1}];
  augmented = Join[SparseArray[matrix], rightColumn, 2];
  coefficient = nativeRank[SparseArray[matrix], prime,
    label, imageID, "coefficient"];
  If[Lookup[coefficient, "Status", None] =!= "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageCoefficientFailed", <|
      "Coefficient" -> coefficient|>]]];
  augmentedRank = nativeRank[augmented, prime,
    label, imageID, "augmented"];
  If[Lookup[augmentedRank, "Status", None] =!= "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageAugmentedFailed", <|
      "Coefficient" -> coefficient,
      "Augmented" -> augmentedRank|>]]];
  If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
      augmentedRank["Rank"]],
    Return[nativeRankFailure["RankImageRankRelationFailed", <|
      "Coefficient" -> coefficient,
      "Augmented" -> augmentedRank|>]]];
  <|"Status" -> "CertifiedAffineConsistencyByTwoRanksV1",
    "Consistent" ->
      (coefficient["Rank"] === augmentedRank["Rank"]),
    "CoefficientRank" -> coefficient["Rank"],
    "AugmentedRank" -> augmentedRank["Rank"],
    "CoefficientNullity" -> coefficient["Nullity"],
    "CoefficientCertificate" -> coefficient,
    "AugmentedCertificate" -> augmentedRank|>
];

images = {
  <|"ImageID" -> "I00", "Prime" -> 10007,
    "EpsilonValue" -> 1/21|>,
  <|"ImageID" -> "I01", "Prime" -> 10007,
    "EpsilonValue" -> 1/11|>,
  <|"ImageID" -> "I10", "Prime" -> 10039,
    "EpsilonValue" -> 1/21|>,
  <|"ImageID" -> "I11", "Prime" -> 10039,
    "EpsilonValue" -> 1/11|>};
results = {};
Do[
  candidate = target["Candidate"];
  label = candidate["FactorFingerprint"];
  targetPreparation = target["TargetPreparation"];
  targetAssembly = target["TargetAssembly"];
  candidateResults = {};
  Do[
    prime = image["Prime"];
    epsilonValue = image["EpsilonValue"];
    seed = Hash[{2026082317, label, image["ImageID"],
      targetPreparation["ABIFingerprint"]}, "CRC32"];
    {sampleSeconds, targetSample} = AbsoluteTiming[
      CodexDirectRootChannelAssembler`DRCAAssembleSample[
        targetAssembly, epsilonValue, prime,
        "PointCount" -> target["PointCount"],
        "MaximumAttempts" -> 40 target["PointCount"],
        "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
        "BranchFlipMask" -> 0]];
    If[Lookup[targetSample, "Status", None] =!=
          "AssembledDirectRootChannelSampleV1" ||
        targetSample["MatrixDimensions"] =!=
          {32 target["PointCount"], targetPreparation["UnknownCount"]},
      finish["TargetSampleFailed", <|
        "Candidate" -> label, "Image" -> image,
        "SampleStatus" -> Lookup[targetSample, "Status", None]|>, 72]];
    screenPoints = Take[targetSample["AcceptedPoints"], 21];
    targetScreenMatrix = Take[targetSample["Matrix"], 32 21];
    targetScreenRight = Take[targetSample["RightHandSide"], 32 21];
    baseSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
      baseAssembly, epsilonValue, prime,
      "PointCount" -> 21, "MaximumAttempts" -> 21,
      "RandomSeed" -> seed, "CandidatePoints" -> screenPoints,
      "BranchFlipMask" -> 0];
    If[Lookup[baseSample, "Status", None] =!=
          "AssembledDirectRootChannelSampleV1" ||
        baseSample["AcceptedPoints"] =!= screenPoints ||
        baseSample["MatrixDimensions"] =!= {672, 624} ||
        baseSample["RightHandSide"] =!= targetScreenRight,
      finish["BaseCommonPointSampleFailed", <|
        "Candidate" -> label, "Image" -> image|>, 73]];
    projectedBase = containmentProjection[
      target, targetScreenMatrix, prime];
    If[projectedBase === $Failed ||
        projectedBase =!= baseSample["Matrix"],
      finish["PureSupersetMatrixContainmentFailed", <|
        "Candidate" -> label, "Image" -> image|>, 74]];
    witness = CodexAffineInconsistencyWitness`AIWConstruct[
      SparseArray[baseSample["Matrix"]],
      baseSample["RightHandSide"], prime,
      files["NativeAdapter"], files["NativeBinary"], 1,
      makeNonce[label, image["ImageID"], "left-witness"]];
    If[Lookup[witness, "Status", None] =!=
        "CertifiedAffineLeftInconsistencyWitnessV1",
      finish["BaseLeftWitnessFailed", <|
        "Candidate" -> label, "Image" -> image,
        "WitnessStatus" -> Lookup[witness, "Status", None],
        "WitnessFailure" -> KeyDrop[witness, "Witness"]|>, 75]];
    score = CodexAffineInconsistencyWitness`AIWScoreColumns[
      witness, SparseArray[targetScreenMatrix]];
    If[Lookup[score, "Status", None] =!=
        "AffineWitnessCandidateColumnScoreV1",
      finish["CandidateWitnessScoreFailed", <|
        "Candidate" -> label, "Image" -> image|>, 76]];
    fullRank = If[TrueQ[score["AllScoresZero"]],
      Missing["RejectedByLeftWitness"],
      rankImage[targetSample["Matrix"],
        targetSample["RightHandSide"], prime, label, image["ImageID"]]];
    If[! MissingQ[fullRank] &&
        Lookup[fullRank, "Status", None] =!=
          "CertifiedAffineConsistencyByTwoRanksV1",
      finish["CandidateFullRankFailed", <|
        "Candidate" -> label, "Image" -> image,
        "RankFailure" -> fullRank|>, 77]];
    AppendTo[candidateResults, Join[image, <|
      "PointCount" -> target["PointCount"],
      "AttemptCount" -> targetSample["AttemptCount"],
      "AcceptedPointsFingerprint" ->
        fingerprint[targetSample["AcceptedPoints"]],
      "SampleSeconds" -> sampleSeconds,
      "MatrixFingerprint" ->
        Hash[targetSample["Matrix"], "SHA256", "HexString"],
      "RightHandSideFingerprint" ->
        Hash[targetSample["RightHandSide"], "SHA256", "HexString"],
      "PureSupersetMatrixContainment" -> True,
      "Witness" -> KeyDrop[witness, "Witness"],
      "WitnessScore" -> score,
      "FullRank" -> fullRank|>]];
    Print["CF300_DENOM_WITNESS milestone=image_complete factor=", label,
      " image=", image["ImageID"], " score_nonzero=",
      score["NonzeroScoreCount"], " full_consistent=",
      If[AssociationQ[fullRank], fullRank["Consistent"], "not-run"]],
    {image, images}];
  AppendTo[results, <|
    "Factor" -> candidate["Factor"],
    "FactorFingerprint" -> label,
    "TargetABIFingerprint" -> targetPreparation["ABIFingerprint"],
    "TargetAssemblyFingerprint" -> targetAssembly["AssemblyFingerprint"],
    "SupportCount" -> Length[targetPreparation["GaugeSupport"]],
    "UnknownCount" -> targetPreparation["UnknownCount"],
    "PointCount" -> target["PointCount"],
    "OldGaugeSubspaceSupportContained" -> True,
    "ImageResults" -> candidateResults,
    "PiercesEveryWitness" -> AllTrue[candidateResults,
      ! TrueQ[#1["WitnessScore", "AllScoresZero"]] &],
    "ConsistentAtEveryPromotedImage" -> AllTrue[candidateResults,
      AssociationQ[#1["FullRank"]] &&
        TrueQ[#1["FullRank", "Consistent"]] &]|>],
  {target, targets}];

If[hashes[] =!= sourceHashesBefore ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["SourceOrArtifactChangedDuringScreen", <||>, 95]];

finish[If[candidateSelector === "ALL",
    "CF300Sector12DenominatorWitnessScreenPassed",
    "CF300Sector12DenominatorWitnessTargetedScreenPassed"], <|
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
  "CensusFile" -> censusFile, "CensusSHA256" -> expectedCensusHash,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "TargetBuildSeconds" -> targetBuildSeconds,
  "CandidateSelector" -> candidateSelector,
  "ImageSpecifications" -> images,
  "WitnessSemantics" ->
    "A^T y=0,b^T y=1; zero y^T C rigorously rejects candidate",
  "FullRankPolicy" ->
    "only nonzero witness screens receive independent FLINT ranks of A and augmented",
  "Results" -> results,
  "SurvivorFactors" ->
    (Lookup[#, "Factor"] & /@ Select[results,
      TrueQ[#1["PiercesEveryWitness"]] &&
        TrueQ[#1["ConsistentAtEveryPromotedImage"]] &])|>, 0];
