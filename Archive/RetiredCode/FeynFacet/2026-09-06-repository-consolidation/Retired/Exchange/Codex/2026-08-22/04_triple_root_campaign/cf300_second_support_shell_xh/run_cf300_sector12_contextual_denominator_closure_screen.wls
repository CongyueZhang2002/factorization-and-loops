#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{6, 7}, Length[arguments]],
  Print["CF300_CONTEXT_DENOM FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <denominator-census.wl> <output.wl> " <>
    "<CTX:PLUS_X|CTX:PLUS_XY|CTX:BOTH|MAX5> [native-threads]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
censusFile = ExpandFileName[arguments[[4]]];
outputFile = ExpandFileName[arguments[[5]]];
candidateSelector = arguments[[6]];
nativeThreads = If[Length[arguments] === 7,
  Quiet[Check[ToExpression[arguments[[7]]], $Failed]], 1];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
supportDirectory = FileNameJoin[{exchangeDirectory,
  "cf300_sector12_next_ansatz_xh"}];
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
  "AnsatzRebind" -> FileNameJoin[{supportDirectory,
    "DirectRootChannelAnsatzRebind.wl"}],
  "NativeAdapter" -> FileNameJoin[{adapterDirectory,
    "FlintAffineRREFAdapter.wl"}],
  "WitnessHelper" -> FileNameJoin[{supportDirectory,
    "AffineInconsistencyWitness.wl"}],
  "AtomicHelper" -> FileNameJoin[{directDirectory,
    "DirectDiscriminatorAtomicCheckpointV2.wl"}],
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
  "AtomicHelper" ->
    "dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30",
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedCensusHash =
  "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a";
expectedAllAbsentFingerprints = Sort[{
  "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881",
  "33ee404e011f65512b192d8baa6ecd29175dccb8c8328c801a495a56bead0301",
  "c799eabc0695b12beeccf7a2edfa9702dc5efaddfdec7bf64437b73807eff7ed",
  "ca57b1d43a23420f8c1eec7d9e8dd0da36077e0a203b6a6feccd26ceac8f8284",
  "ce44a483203b0cde640e984643bcf415afd24ea95df2b50ee87ae72e232be10e"}];
plusXFingerprint =
  "ca57b1d43a23420f8c1eec7d9e8dd0da36077e0a203b6a6feccd26ceac8f8284";
plusXYFingerprint =
  "33ee404e011f65512b192d8baa6ecd29175dccb8c8328c801a495a56bead0301";
allowedSelectors = {"CTX:PLUS_X", "CTX:PLUS_XY", "CTX:BOTH", "MAX5"};

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
stableInputsQ[] := TrueQ[
  hashes[] === sourceHashesBefore &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash &&
  FileHash[censusFile, "SHA256", "HexString"] === expectedCensusHash &&
  FileHash[$InputFileName, "SHA256", "HexString"] === driverHashBefore];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];
modRational[value_, prime_Integer] := Module[{q = Together[value]},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  Mod[Numerator[q] PowerMod[Mod[Denominator[q], prime], -1, prime],
    prime]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[censusFile] || FileExistsQ[outputFile] ||
    ! DirectoryQ[DirectoryName[outputFile]] ||
    ! MemberQ[allowedSelectors, candidateSelector] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_CONTEXT_DENOM FAIL invalid inputs, selector, or threads"];
  Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash,
  Print["CF300_CONTEXT_DENOM FAIL pinned source or artifact mismatch"];
  Exit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper", "AtomicHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_CONTEXT_DENOM FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  Exit[67]];

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
  Print["CF300_CONTEXT_DENOM FAIL pinned artifacts invalid"];
  Exit[68]];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = compiledArtifact["DirectAssembly"];
catalog = SortBy[censusArtifact["AllAbsentCandidates"],
  #1["FactorFingerprint"] &];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly] ||
    baseAssembly["SourceABIFingerprint"] =!=
      basePreparation["ABIFingerprint"] || Length[catalog] =!= 5 ||
    Lookup[catalog, "FactorFingerprint"] =!=
      expectedAllAbsentFingerprints ||
    ! AllTrue[catalog,
      TrueQ[#1["AbsentFromGaugeDenominator"]] &&
        TrueQ[#1["EpsilonFree"]] &&
        TrueQ[#1["KinematicsDependent"]] &],
  Print["CF300_CONTEXT_DENOM FAIL base or catalog contract invalid"];
  Exit[69]];

catalogByFingerprint = Association[
  (#1["FactorFingerprint"] -> #1) & /@ catalog];
selectedFingerprints = Switch[candidateSelector,
  "CTX:PLUS_X", {plusXFingerprint},
  "CTX:PLUS_XY", {plusXYFingerprint},
  "CTX:BOTH", Sort[{plusXFingerprint, plusXYFingerprint}],
  "MAX5", expectedAllAbsentFingerprints,
  _, $Failed];
members = Lookup[catalogByFingerprint, selectedFingerprints, $Failed];
If[selectedFingerprints === $Failed || MemberQ[members, $Failed] ||
    ! MemberQ[{1, 2, 5}, Length[members]],
  Print["CF300_CONTEXT_DENOM FAIL selector resolution invalid"];
  Exit[70]];
selectedFactor = Times @@ Lookup[members, "Factor"];
selection = <|
  "Selector" -> candidateSelector,
  "Factor" -> selectedFactor,
  "FactorFingerprint" -> fingerprint[selectedFactor],
  "MemberFingerprints" -> selectedFingerprints,
  "MemberFactors" -> Lookup[members, "Factor"],
  "MemberCount" -> Length[members]|>;

{x, y} = basePreparation["Variables"];
epsilon = basePreparation["Regulator"];
baseSupport = basePreparation["GaugeSupport"];
baseSupportCount = Length[baseSupport];
baseGaugeCount = basePreparation["GaugeUnknownCount"];
baseResidueCount = basePreparation["ResidueUnknownCount"];
{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
If[{upper, lower, gradeCount, baseSupportCount, baseGaugeCount,
      baseResidueCount, basePreparation["UnknownCount"]} =!=
    {2, 2, 4, 30, 480, 144, 624},
  Print["CF300_CONTEXT_DENOM FAIL physical dimension contract invalid"];
  Exit[71]];

allSubsetContainmentCertificate[] := Module[
  {indices = Range[Length[catalog]], records, subsetIndices,
   subsetMembers, complementMembers, subsetFactor, complementFactor,
   subsetDenominator, subsetDegrees, subsetSupport, complementRules,
   requiredFullSupport, fullDenominator, fullDegrees, fullSupport},
  fullDenominator = Together[basePreparation["GaugeDenominator"]
    Times @@ (Lookup[#1, "Factor"] & /@ catalog)];
  fullDegrees = Exponent[fullDenominator, #1] & /@ {x, y};
  fullSupport = Flatten[Table[{px, py},
    {px, 0, fullDegrees[[1]]}, {py, 0, fullDegrees[[2]]}], 1];
  records = Table[
    subsetMembers = catalog[[subsetIndices]];
    complementMembers = catalog[[Complement[indices, subsetIndices]]];
    subsetFactor = Times @@ (Lookup[#1, "Factor"] & /@ subsetMembers);
    complementFactor = Times @@
      (Lookup[#1, "Factor"] & /@ complementMembers);
    subsetDenominator = Together[
      basePreparation["GaugeDenominator"] subsetFactor];
    subsetDegrees = Exponent[subsetDenominator, #1] & /@ {x, y};
    subsetSupport = Flatten[Table[{px, py},
      {px, 0, subsetDegrees[[1]]},
      {py, 0, subsetDegrees[[2]]}], 1];
    complementRules = CoefficientRules[Expand[complementFactor], {x, y}];
    requiredFullSupport = Union[Flatten[Table[
      oldMonomial + rule[[1]],
      {oldMonomial, subsetSupport}, {rule, complementRules}], 1]];
    <|"SubsetMask" -> StringJoin[Table[
        If[MemberQ[subsetIndices, bit], "1", "0"], {bit, indices}]],
      "SubsetFingerprints" ->
        (Lookup[#1, "FactorFingerprint"] & /@ subsetMembers),
      "ComplementFingerprints" ->
        (Lookup[#1, "FactorFingerprint"] & /@ complementMembers),
      "SubsetDenominatorDegrees" -> subsetDegrees,
      "SubsetSupportCount" -> Length[subsetSupport],
      "ComplementFactorRules" -> complementRules,
      "RequiredEmbeddedSupportCount" -> Length[requiredFullSupport],
      "RequiredSupportContainedInMAX5" ->
        (Complement[requiredFullSupport, fullSupport] === {})|>,
    {subsetIndices, Rest[Subsets[indices]]}];
  If[Length[records] =!= 31 || fullDegrees =!= {10, 8} ||
      Length[fullSupport] =!= 99 ||
      ! AllTrue[records,
        TrueQ[#1["RequiredSupportContainedInMAX5"]] &],
    Return[$Failed]];
  <|"Status" -> "MAX5SquareFreeSubsetContainmentCertificateV1",
    "CatalogBitOrder" -> expectedAllAbsentFingerprints,
    "SubsetCount" -> 31,
    "FullDenominatorDegrees" -> fullDegrees,
    "FullSupportCount" -> Length[fullSupport],
    "EmbeddingIdentity" ->
      "P/D_S = P*(F_MAX/F_S)/D_MAX for every gauge grade and matrix entry",
    "ResidueColumnsIdentical" -> True,
    "Records" -> records|>
];
subsetContainmentCertificate = If[candidateSelector === "MAX5",
  allSubsetContainmentCertificate[], Missing["NotMAX5"]];
If[candidateSelector === "MAX5" &&
    ! AssociationQ[subsetContainmentCertificate],
  Print["CF300_CONTEXT_DENOM FAIL MAX5 containment certificate invalid"];
  Exit[72]];

buildTarget[] := Module[
  {factor, changedDenominator, changedDegrees, support, factorRules,
   requiredSupport, payload, gaugeCount, residueCount, target, rebound,
   pointCount, expectedShape},
  factor = selection["Factor"];
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
      "Status" -> "CF300ContextualDenominatorClosurePureSupersetV1",
      "Selector" -> candidateSelector,
      "MemberFingerprints" -> selectedFingerprints|>,
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
  expectedShape = Switch[candidateSelector,
    "CTX:PLUS_X", {{5, 5}, 36, 720, 24},
    "CTX:PLUS_XY", {{5, 6}, 42, 816, 27},
    "CTX:BOTH", {{6, 6}, 49, 928, 30},
    "MAX5", {{10, 8}, 99, 1728, 55}];
  If[{changedDegrees, Length[support], target["UnknownCount"],
      pointCount} =!= expectedShape, Return[$Failed]];
  <|"FactorRules" -> factorRules,
    "RequiredOldGaugeNumeratorSupport" -> requiredSupport,
    "TargetPreparation" -> target, "TargetAssembly" -> rebound,
    "PointCount" -> pointCount|>
];
{targetBuildSeconds, target} = AbsoluteTiming[buildTarget[]];
If[! AssociationQ[target],
  Print["CF300_CONTEXT_DENOM FAIL selected target build failed"];
  Exit[73]];
targetPreparation = target["TargetPreparation"];
targetAssembly = target["TargetAssembly"];
Print["CF300_CONTEXT_DENOM milestone=target_ready selector=",
  candidateSelector, " elapsed_s=", targetBuildSeconds,
  " support=", Length[targetPreparation["GaugeSupport"]],
  " unknowns=", targetPreparation["UnknownCount"],
  " points=", target["PointCount"]];

containmentProjection[targetMatrix_?MatrixQ, prime_Integer] := Module[
  {targetSupport, targetSupportCount, targetGaugeCount, factorRules,
   rows, gaugeColumns, residueColumns, targetPositions, coefficients,
   columns, targetPosition, targetColumn, oldMonomial,
   oldColumnVectors},
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
    coefficients = modRational[#1[[2]], prime] & /@ factorRules;
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
  If[rows === 0, array === {},
    MatrixQ[array, IntegerQ] && Dimensions[array] === {rows, columns}] &&
  AllTrue[Flatten[Normal[array]], 0 <= #1 < prime &]];
nativeRankFailure[status_String, data_: <||>] :=
  Join[<|"Status" -> status|>, data];
nativeRank[localMatrix_?MatrixQ, prime_Integer, imageID_String,
    tag_String] := Module[
  {rows, columns, request, seconds, run, certificate, rank, nullity,
   diagnosticSeconds, diagnosticRun},
  {rows, columns} = Dimensions[localMatrix];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    localMatrix, ConstantArray[0, rows], prime, Range[columns],
    makeNonce[candidateSelector, imageID, tag]];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    Return[nativeRankFailure["NativeRankRequestFailed"]]];
  {seconds, run} = AbsoluteTiming[
    CodexFLINTAffineRREFAdapter`CFFRRun[
      files["NativeBinary"], request, nativeThreads, False, 1200]];
  If[Lookup[run, "Status", None] =!=
      "VerifiedFLINTAffineRREFRun",
    {diagnosticSeconds, diagnosticRun} = AbsoluteTiming[
      CodexFLINTAffineRREFAdapter`CFFRRun[
        files["NativeBinary"], request, nativeThreads, True, 1200]];
    Return[nativeRankFailure["NativeRankRunFailed", <|
      "RunStatus" -> Lookup[run, "Status", None],
      "Verification" -> Lookup[run, "Verification", Missing["Absent"]],
      "DiagnosticRunStatus" -> Lookup[diagnosticRun, "Status", None],
      "DiagnosticVerification" -> Lookup[diagnosticRun,
        "Verification", Missing["Absent"]],
      "DiagnosticArtifactDirectory" -> Lookup[diagnosticRun,
        "ArtifactDirectory", Missing["Absent"]],
      "DiagnosticSeconds" -> diagnosticSeconds,
      "Seconds" -> seconds|>]]];
  certificate = run["Certificate"];
  rank = certificate["Rank"];
  nullity = certificate["Nullity"];
  If[certificate["ParticularSolution"] =!=
        ConstantArray[0, columns] || rank + nullity =!= columns ||
      ! canonicalVectorQ[certificate["ParticularSolution"], columns,
        prime] ||
      ! canonicalMatrixQ[certificate["NullspaceBasis"], nullity,
        columns, prime],
    Return[nativeRankFailure[
      "NativeRankCertificatePostconditionFailed"]]];
  <|"Status" -> "VerifiedNativeRankV1",
    "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
    "Nullity" -> nullity, "Seconds" -> seconds,
    "PivotFingerprint" -> fingerprint[certificate["PivotColumns"]],
    "FreeColumnFingerprint" -> fingerprint[
      certificate["FreeColumns"]],
    "RowWitnessFingerprint" -> fingerprint[
      certificate["IndependentEquationRows"]]|>
];
rankImage[matrix_?MatrixQ, right_List, prime_Integer,
    imageID_String] := Module[
  {rows, rightColumn, augmented, coefficient, augmentedRank},
  rows = Dimensions[matrix][[1]];
  rightColumn = SparseArray[
    MapIndexed[{First[#2], 1} -> #1 &, right], {rows, 1}];
  augmented = Join[SparseArray[matrix], rightColumn, 2];
  coefficient = nativeRank[SparseArray[matrix], prime, imageID,
    "coefficient"];
  If[Lookup[coefficient, "Status", None] =!= "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageCoefficientFailed", <|
      "Coefficient" -> coefficient|>]]];
  augmentedRank = nativeRank[augmented, prime, imageID, "augmented"];
  If[Lookup[augmentedRank, "Status", None] =!=
      "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageAugmentedFailed", <|
      "Coefficient" -> coefficient,
      "Augmented" -> augmentedRank|>]]];
  If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
      augmentedRank["Rank"]],
    Return[nativeRankFailure["RankImageRankRelationFailed"]]];
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
checkpointFile[image_Association] := outputFile <> "." <>
  image["ImageID"] <> ".checkpoint.wl";
checkpointContract[image_Association] := <|
  "Status" -> "CF300ContextualDenominatorImageCheckpointV1",
  "DriverSHA256" -> driverHashBefore,
  "SourceHashes" -> sourceHashesBefore,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheSHA256" -> expectedCacheHash,
  "CensusSHA256" -> expectedCensusHash,
  "Selector" -> candidateSelector,
  "ImageSpecification" -> image,
  "TargetABIFingerprint" -> targetPreparation["ABIFingerprint"],
  "TargetAssemblyFingerprint" -> targetAssembly["AssemblyFingerprint"],
  "NativeThreads" -> nativeThreads|>;
validImageResultQ[result_Association, image_Association] := TrueQ[
  result["ImageID"] === image["ImageID"] &&
  result["Prime"] === image["Prime"] &&
  result["EpsilonValue"] === image["EpsilonValue"] &&
  result["PointCount"] === target["PointCount"] &&
  result["PureSupersetMatrixProjection"] === True &&
  AssociationQ[result["Witness"]] &&
  AssociationQ[result["WitnessScore"]] &&
  (MissingQ[result["FullRank"]] || AssociationQ[result["FullRank"]])];
readCheckpoint[image_Association] := Module[
  {read, payload, contract, result},
  read = CodexDirectDiscriminatorAtomicCheckpointV2`DDACReadSealed[
    checkpointFile[image]];
  If[Lookup[read, "Status", None] === "AtomicArtifactAbsentV2",
    Return[Missing["AbsentCheckpoint"]]];
  If[Lookup[read, "Status", None] =!= "AtomicArtifactReadV2",
    Return[$Failed]];
  payload = read["Payload"];
  contract = checkpointContract[image];
  result = Lookup[payload, "ImageResult", $Failed];
  If[KeyDrop[payload, {"ImageResult", "CompletedAtAbsoluteTime"}] =!=
        contract || ! AssociationQ[result] ||
      ! validImageResultQ[result, image], Return[$Failed]];
  result
];
writeCheckpoint[image_Association, result_Association] := Module[
  {payload, commit},
  payload = Join[checkpointContract[image], <|
    "ImageResult" -> result,
    "CompletedAtAbsoluteTime" -> AbsoluteTime[]|>];
  commit = CodexDirectDiscriminatorAtomicCheckpointV2`DDACWriteAtomic[
    checkpointFile[image], payload, Function[stableInputsQ[]]];
  If[Lookup[commit, "Status", None] =!= "AtomicWriteCommittedV2",
    $Failed, commit]
];

results = {};
Do[
  prior = readCheckpoint[image];
  If[prior === $Failed,
    Print["CF300_CONTEXT_DENOM FAIL invalid checkpoint image=",
      image["ImageID"]];
    Exit[74]];
  If[AssociationQ[prior],
    AppendTo[results, prior];
    Print["CF300_CONTEXT_DENOM milestone=image_checkpoint_resumed image=",
      image["ImageID"]];
    Continue[]];
  prime = image["Prime"];
  epsilonValue = image["EpsilonValue"];
  seed = Hash[{2026082331, candidateSelector, image["ImageID"],
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
    Print["CF300_CONTEXT_DENOM FAIL target sample image=",
      image["ImageID"]];
    Exit[75]];
  screenPoints = Take[targetSample["AcceptedPoints"], 21];
  targetScreenMatrix = Take[targetSample["Matrix"], 672];
  targetScreenRight = Take[targetSample["RightHandSide"], 672];
  baseSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
    baseAssembly, epsilonValue, prime,
    "PointCount" -> 21, "MaximumAttempts" -> 21,
    "RandomSeed" -> seed, "CandidatePoints" -> screenPoints,
    "BranchFlipMask" -> 0];
  projectedBase = containmentProjection[targetScreenMatrix, prime];
  If[Lookup[baseSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      baseSample["AcceptedPoints"] =!= screenPoints ||
      baseSample["MatrixDimensions"] =!= {672, 624} ||
      baseSample["RightHandSide"] =!= targetScreenRight ||
      projectedBase === $Failed || projectedBase =!= baseSample["Matrix"],
    Print["CF300_CONTEXT_DENOM FAIL pure-superset projection image=",
      image["ImageID"]];
    Exit[76]];
  witness = CodexAffineInconsistencyWitness`AIWConstruct[
    SparseArray[baseSample["Matrix"]], baseSample["RightHandSide"],
    prime, files["NativeAdapter"], files["NativeBinary"],
    nativeThreads,
    makeNonce[candidateSelector, image["ImageID"], "left-witness"]];
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    Print["CF300_CONTEXT_DENOM FAIL base witness image=",
      image["ImageID"], " status=", Lookup[witness, "Status", None]];
    Exit[77]];
  score = CodexAffineInconsistencyWitness`AIWScoreColumns[
    witness, SparseArray[targetScreenMatrix]];
  If[Lookup[score, "Status", None] =!=
      "AffineWitnessCandidateColumnScoreV1",
    Print["CF300_CONTEXT_DENOM FAIL witness score image=",
      image["ImageID"]];
    Exit[78]];
  fullRank = If[TrueQ[score["AllScoresZero"]],
    Missing["RejectedByBaseLeftWitness"],
    rankImage[targetSample["Matrix"], targetSample["RightHandSide"],
      prime, image["ImageID"]]];
  If[! MissingQ[fullRank] &&
      Lookup[fullRank, "Status", None] =!=
        "CertifiedAffineConsistencyByTwoRanksV1",
    Print["CF300_CONTEXT_DENOM FAIL full rank image=",
      image["ImageID"], " status=", Lookup[fullRank, "Status", None]];
    Exit[79]];
  imageResult = Join[image, <|
    "PointCount" -> target["PointCount"],
    "AttemptCount" -> targetSample["AttemptCount"],
    "AcceptedPointsFingerprint" ->
      fingerprint[targetSample["AcceptedPoints"]],
    "SampleSeconds" -> sampleSeconds,
    "MatrixFingerprint" ->
      Hash[targetSample["Matrix"], "SHA256", "HexString"],
    "RightHandSideFingerprint" ->
      Hash[targetSample["RightHandSide"], "SHA256", "HexString"],
    "PureSupersetMatrixProjection" -> True,
    "Witness" -> KeyDrop[witness, "Witness"],
    "WitnessScore" -> score,
    "FullRank" -> fullRank|>];
  checkpointCommit = writeCheckpoint[image, imageResult];
  If[checkpointCommit === $Failed,
    Print["CF300_CONTEXT_DENOM FAIL checkpoint commit image=",
      image["ImageID"]];
    Exit[80]];
  AppendTo[results, imageResult];
  Print["CF300_CONTEXT_DENOM milestone=image_checkpoint_committed selector=",
    candidateSelector, " image=", image["ImageID"],
    " score_nonzero=", score["NonzeroScoreCount"],
    " consistent=", If[AssociationQ[fullRank],
      fullRank["Consistent"], False]],
  {image, images}];

If[Length[results] =!= Length[images] ||
    Lookup[results, "ImageID"] =!= Lookup[images, "ImageID"] ||
    ! stableInputsQ[],
  Print["CF300_CONTEXT_DENOM FAIL completion integrity"];
  Exit[81]];
consistentEveryImage = AllTrue[results,
  AssociationQ[#1["FullRank"]] &&
    TrueQ[#1["FullRank", "Consistent"]] &];
inconsistentEveryImage = AllTrue[results,
  MissingQ[#1["FullRank"]] ||
    (AssociationQ[#1["FullRank"]] &&
      ! TrueQ[#1["FullRank", "Consistent"]]) &];
finalPayload = <|
  "Status" -> "CF300ContextualDenominatorClosureScreenCompleted",
  "Conclusion" -> Which[
    consistentEveryImage,
      "Promote selected denominator target to reconstruction",
    candidateSelector === "MAX5" && inconsistentEveryImage,
      "MAX5 is inconsistent in all four images; exact containment rejects all 31 nonempty square-free subsets",
    inconsistentEveryImage,
      "Selected contextual denominator target is inconsistent in all four images",
    True,
      "Image-dependent consistency; add fresh images before promotion"],
  "DriverSHA256" -> driverHashBefore,
  "SourceHashes" -> sourceHashesBefore,
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
  "CensusFile" -> censusFile, "CensusSHA256" -> expectedCensusHash,
  "NativeThreads" -> nativeThreads,
  "TargetBuildSeconds" -> targetBuildSeconds,
  "Selection" -> selection,
  "CandidateCatalogBitOrder" -> expectedAllAbsentFingerprints,
  "CandidateCatalog" -> MapIndexed[<|
      "BitPosition" -> First[#2],
      "Factor" -> #1["Factor"],
      "FactorFingerprint" -> #1["FactorFingerprint"]|> &,
    catalog],
  "TargetGaugeDenominatorDegrees" ->
    targetPreparation["GaugeDenominatorDegrees"],
  "TargetSupportCount" -> Length[targetPreparation["GaugeSupport"]],
  "TargetUnknownCount" -> targetPreparation["UnknownCount"],
  "TargetPointCount" -> target["PointCount"],
  "TargetABIFingerprint" -> targetPreparation["ABIFingerprint"],
  "TargetAssemblyFingerprint" -> targetAssembly["AssemblyFingerprint"],
  "BasePureSupersetSupportContained" -> True,
  "MAX5SubsetContainmentCertificate" -> subsetContainmentCertificate,
  "ImageSpecifications" -> images,
  "WitnessSemantics" ->
    "A_base^T y=0,b^T y=1; zero y^T C rejects target; two ranks certify consistency",
  "ConsistentEveryImage" -> consistentEveryImage,
  "InconsistentEveryImage" -> inconsistentEveryImage,
  "Results" -> results|>;
finalCommit = CodexDirectDiscriminatorAtomicCheckpointV2`DDACWriteAtomic[
  outputFile, finalPayload, Function[stableInputsQ[]]];
If[Lookup[finalCommit, "Status", None] =!= "AtomicWriteCommittedV2",
  Print["CF300_CONTEXT_DENOM FAIL typed_atomic_commit=",
    InputForm[finalCommit]];
  Exit[98]];
Print["CF300_CONTEXT_DENOM status=", finalPayload["Status"],
  " selector=", candidateSelector, " output=", outputFile,
  " output_sha=", finalCommit["TargetSHA256"]];
Exit[0];
