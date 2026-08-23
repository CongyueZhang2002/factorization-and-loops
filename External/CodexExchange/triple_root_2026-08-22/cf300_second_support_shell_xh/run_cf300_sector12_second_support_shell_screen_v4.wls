#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300SecondSupportShellDriverV4`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300SecondSupportShellDriverV4`Private`*"]];
cf300SecondShellDriverV4BootstrapExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);
canonicalRuntimeFile = FileNameJoin[{DirectoryName[$InputFileName],
  "CanonicalGlobalArtifactRuntimeV1.wl"}];
expectedCanonicalRuntimeHash =
  "e9601949653a14337dbe00aead48e1a173a53d4006d516a035105497afc06a8f";
If[! FileExistsQ[canonicalRuntimeFile] ||
    FileHash[canonicalRuntimeFile, "SHA256", "HexString"] =!=
      expectedCanonicalRuntimeHash,
  Print["CF300_SECOND_SHELL FAIL canonical runtime bootstrap pin"];
  cf300SecondShellDriverV4BootstrapExit[62]];
canonicalRuntimeLoad = Quiet[Check[Get[canonicalRuntimeFile], $Failed]];
If[canonicalRuntimeLoad === $Failed ||
    DownValues[CodexCanonicalGlobalArtifactRuntimeV1`CGARRun] === {},
  Print["CF300_SECOND_SHELL FAIL canonical runtime bootstrap load"];
  cf300SecondShellDriverV4BootstrapExit[62]];
cf300SecondShellDriverV3Exit[code_Integer] :=
  CodexCanonicalGlobalArtifactRuntimeV1`CGARRequestExit[code];
canonicalRuntimeOutcome =
  CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[
arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print["CF300_SECOND_SHELL FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <output.wl> [native-threads]"];
  cf300SecondShellDriverV3Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];
nativeThreads = If[Length[arguments] === 5,
  Quiet[Check[ToExpression[arguments[[5]]], $Failed]], 1];
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
  "CanonicalRuntime" -> canonicalRuntimeFile,
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
  "CanonicalRuntime" -> expectedCanonicalRuntimeHash,
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";

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
  FileHash[$InputFileName, "SHA256", "HexString"] === driverHashBefore];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_SECOND_SHELL FAIL invalid inputs, stale output, or threads"];
  cf300SecondShellDriverV3Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash,
  Print["CF300_SECOND_SHELL FAIL pinned source or artifact mismatch"];
  cf300SecondShellDriverV3Exit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper", "AtomicHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_SECOND_SHELL FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  cf300SecondShellDriverV3Exit[67]];

preparationArtifact = artifactRead[preparationFile];
compiledArtifactRaw = artifactRead[cacheFile];
compiledArtifact =
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile];
preparationPayload = If[AssociationQ[preparationArtifact],
  Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
preparationVariables = If[AssociationQ[preparationPayload],
  Lookup[preparationPayload, "Variables", $Failed], $Failed];
preparationRegulator = If[AssociationQ[preparationPayload],
  Lookup[preparationPayload, "Regulator", $Failed], $Failed];
rawAssembly = If[AssociationQ[compiledArtifactRaw],
  Lookup[compiledArtifactRaw, "DirectAssembly", $Failed], $Failed];
artifactDiagnostics = <|
  "RuntimeContext" -> $Context,
  "RuntimeContextPath" -> $ContextPath,
  "CanonicalSymbolsCleanQ" ->
    And @@ ((OwnValues[#1] === {} && DownValues[#1] === {} &&
          UpValues[#1] === {} && SubValues[#1] === {} &&
          Attributes[#1] === {}) & /@
      Unevaluated[{Global`x, Global`y, Global`eps}]),
  "PreparationAssociationQ" -> AssociationQ[preparationArtifact],
  "PreparationStatus" -> If[AssociationQ[preparationArtifact],
    Lookup[preparationArtifact, "Status", Missing["Absent"]], $Failed],
  "PreparationPayloadAssociationQ" -> AssociationQ[preparationPayload],
  "PreparationVariables" -> ToString[InputForm[preparationVariables]],
  "PreparationVariablesCanonicalQ" ->
    SameQ[preparationVariables, {Global`x, Global`y}],
  "PreparationRegulator" -> ToString[InputForm[preparationRegulator]],
  "PreparationRegulatorCanonicalQ" ->
    SameQ[preparationRegulator, Global`eps],
  "RawCacheAssociationQ" -> AssociationQ[compiledArtifactRaw],
  "RawCacheStatus" -> If[AssociationQ[compiledArtifactRaw],
    Lookup[compiledArtifactRaw, "Status", Missing["Absent"]], $Failed],
  "RawCacheValidatorQ" -> If[AssociationQ[compiledArtifactRaw],
    TrueQ[CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      compiledArtifactRaw]], False],
  "RawAssemblyAssociationQ" -> AssociationQ[rawAssembly],
  "RawAssemblyValidatorQ" -> If[AssociationQ[rawAssembly],
    TrueQ[CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      rawAssembly]], False],
  "ReaderAssociationQ" -> AssociationQ[compiledArtifact],
  "ReaderStatus" -> If[AssociationQ[compiledArtifact],
    Lookup[compiledArtifact, "Status", Missing["Absent"]],
    compiledArtifact],
  "ReaderSameAsRawQ" -> SameQ[compiledArtifact, compiledArtifactRaw]|>;
Print["CF300_SECOND_SHELL artifact_diagnostics=",
  InputForm[artifactDiagnostics]];
artifactContractQ = TrueQ[
  artifactDiagnostics["CanonicalSymbolsCleanQ"] &&
  artifactDiagnostics["PreparationStatus"] ===
    "PreparedCF300Sector12Rank2Extension" &&
  artifactDiagnostics["PreparationPayloadAssociationQ"] &&
  artifactDiagnostics["PreparationVariablesCanonicalQ"] &&
  artifactDiagnostics["PreparationRegulatorCanonicalQ"] &&
  artifactDiagnostics["RawCacheStatus"] ===
    "DirectRootChannelCompiledArtifactV1" &&
  artifactDiagnostics["RawCacheValidatorQ"] &&
  artifactDiagnostics["RawAssemblyValidatorQ"] &&
  artifactDiagnostics["ReaderAssociationQ"] &&
  artifactDiagnostics["ReaderSameAsRawQ"]];
If[! artifactContractQ,
  Print["CF300_SECOND_SHELL FAIL pinned artifacts invalid"];
  cf300SecondShellDriverV3Exit[68]];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = compiledArtifact["DirectAssembly"];
baseContractDiagnostics = <|
  "PreparationABIValidQ" -> TrueQ[
    CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation]],
  "AssemblyValidQ" -> TrueQ[
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly]],
  "SourceABIFingerprintMatchesQ" -> TrueQ[
    baseAssembly["SourceABIFingerprint"] ===
      basePreparation["ABIFingerprint"]]|>;
Print["CF300_SECOND_SHELL base_contract_diagnostics=",
  InputForm[baseContractDiagnostics]];
If[! TrueQ[And @@ Values[baseContractDiagnostics]],
  Print["CF300_SECOND_SHELL FAIL base ABI invalid"];
  cf300SecondShellDriverV3Exit[69]];

{x, y} = basePreparation["Variables"];
epsilon = basePreparation["Regulator"];
baseSupport = basePreparation["GaugeSupport"];
{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
baseOneForms = basePreparation["OneForms"];
If[{upper, lower, gradeCount, Length[baseSupport],
      Length[baseOneForms], basePreparation["GaugeUnknownCount"],
      basePreparation["ResidueUnknownCount"],
      basePreparation["UnknownCount"]} =!=
    {2, 2, 4, 30, 36, 480, 144, 624},
  Print["CF300_SECOND_SHELL FAIL physical dimension contract invalid"];
  cf300SecondShellDriverV3Exit[70]];

firstRectangle = Flatten[Table[{px, py},
  {px, 0, 5}, {py, 0, 6}], 1];
asSupport = Join[baseSupport, Complement[firstRectangle, baseSupport]];
xEdge = Table[{6, py}, {py, 0, 6}];
yEdge = Table[{px, 7}, {px, 0, 5}];
corner = {{6, 7}};
secondRectangle = Flatten[Table[{px, py},
  {px, 0, 6}, {py, 0, 7}], 1];
maxSupport = Join[asSupport, xEdge, yEdge, corner];
If[Length[asSupport] =!= 42 || Length[maxSupport] =!= 56 ||
    Take[asSupport, Length[baseSupport]] =!= baseSupport ||
    Take[maxSupport, Length[asSupport]] =!= asSupport ||
    ! DuplicateFreeQ[maxSupport] || Sort[maxSupport] =!=
      Sort[secondRectangle] ||
    Length[xEdge] =!= 7 || Length[yEdge] =!= 6 ||
    Length[corner] =!= 1,
  Print["CF300_SECOND_SHELL FAIL support construction invalid"];
  cf300SecondShellDriverV3Exit[71]];

buildVariant[label_String, support_List] := Module[
  {payload, gaugeCount, residueCount, unknownCount, target},
  gaugeCount = upper lower gradeCount Length[support];
  residueCount = Length[baseOneForms] upper lower;
  unknownCount = gaugeCount + residueCount;
  payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
    basePreparation["Record"], basePreparation["Roots"],
    basePreparation["Variables"], epsilon,
    basePreparation["Dimensions"],
    basePreparation["GaugeDenominator"], support, baseOneForms,
    basePreparation["Normalizations"]];
  If[payload === $Failed, Return[$Failed]];
  target = Join[basePreparation, <|
    "OneFormMetadata" -> <|
      "Status" -> "CF300SecondSupportShellPureSupersetV1",
      "Variant" -> label, "BaseVariant" -> "A0"|>,
    "GaugeSupport" -> support,
    "GaugeUnknownCount" -> gaugeCount,
    "ResidueUnknownCount" -> residueCount,
    "UnknownCount" -> unknownCount,
    "ABIPayload" -> payload,
    "ABIFingerprint" -> fingerprint[payload]|>];
  If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    Return[$Failed]];
  target
];

asPreparation = buildVariant["AS", asSupport];
maxPreparation = buildVariant["AS2MAX", maxSupport];
If[! AssociationQ[asPreparation] || ! AssociationQ[maxPreparation] ||
    {asPreparation["GaugeUnknownCount"],
      asPreparation["ResidueUnknownCount"],
      asPreparation["UnknownCount"]} =!= {672, 144, 816} ||
    {maxPreparation["GaugeUnknownCount"],
      maxPreparation["ResidueUnknownCount"],
      maxPreparation["UnknownCount"]} =!= {896, 144, 1040},
  Print["CF300_SECOND_SHELL FAIL target preparation invalid"];
  cf300SecondShellDriverV3Exit[72]];
{targetBuildSeconds, reboundPair} = AbsoluteTiming[{
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, asPreparation],
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, maxPreparation]}];
{asAssembly, maxAssembly} = reboundPair;
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      asAssembly] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      maxAssembly] ||
    asAssembly["SourceABIFingerprint"] =!=
      asPreparation["ABIFingerprint"] ||
    maxAssembly["SourceABIFingerprint"] =!=
      maxPreparation["ABIFingerprint"],
  Print["CF300_SECOND_SHELL FAIL ansatz rebind invalid"];
  cf300SecondShellDriverV3Exit[73]];
Print["CF300_SECOND_SHELL milestone=targets_ready elapsed_s=",
  targetBuildSeconds, " as_unknowns=816 max_unknowns=1040",
  " max_points=34"];

supportColumnMap[localSupport_List] := Module[
  {locations, positions, maxSupportCount, maxGaugeCount,
   gaugeColumns, residueColumns, result},
  locations = FirstPosition[maxSupport, #1,
      Missing["SupportNotInMax"]] & /@ localSupport;
  If[! AllTrue[locations, MatchQ[#1, {_Integer}] &],
    Return[$Failed]];
  positions = First /@ locations;
  maxSupportCount = Length[maxSupport];
  maxGaugeCount = maxPreparation["GaugeUnknownCount"];
  gaugeColumns = Flatten[Table[
    (((i - 1) lower + (j - 1)) gradeCount + grade)
        maxSupportCount + positions[[monomial]],
    {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
    {monomial, Length[localSupport]}]];
  residueColumns = maxGaugeCount +
    Range[maxPreparation["ResidueUnknownCount"]];
  result = Join[gaugeColumns, residueColumns];
  If[! DuplicateFreeQ[result], Return[$Failed]];
  result
];
gaugeBlockColumns[blockSupport_List] := Module[
  {locations, positions, maxSupportCount, result},
  locations = FirstPosition[maxSupport, #1,
      Missing["BlockNotInMax"]] & /@ blockSupport;
  If[! AllTrue[locations, MatchQ[#1, {_Integer}] &],
    Return[$Failed]];
  positions = First /@ locations;
  maxSupportCount = Length[maxSupport];
  result = Flatten[Table[
    (((i - 1) lower + (j - 1)) gradeCount + grade)
        maxSupportCount + positions[[monomial]],
    {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
    {monomial, Length[blockSupport]}]];
  If[! DuplicateFreeQ[result], Return[$Failed]];
  result
];
asColumnMap = supportColumnMap[asSupport];
blockColumnMaps = <|
  "XEdge7" -> gaugeBlockColumns[xEdge],
  "YEdge6" -> gaugeBlockColumns[yEdge],
  "Corner1" -> gaugeBlockColumns[corner]|>;
newColumnMap = Join @@ Values[blockColumnMaps];
If[Length[asColumnMap] =!= 816 ||
    Length /@ Values[blockColumnMaps] =!= {112, 96, 16} ||
    Length[newColumnMap] =!= 224 ||
    ! DuplicateFreeQ[Join[asColumnMap, newColumnMap]] ||
    Sort[Join[asColumnMap, newColumnMap]] =!= Range[1040],
  Print["CF300_SECOND_SHELL FAIL column projection invalid"];
  cf300SecondShellDriverV3Exit[74]];

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
    makeNonce[imageID, tag]];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    Return[nativeRankFailure["NativeRankRequestFailed"]]];
  {seconds, run} = AbsoluteTiming[
    CodexFLINTAffineRREFAdapter`CFFRRun[
      files["NativeBinary"], request, nativeThreads, False, 900]];
  If[Lookup[run, "Status", None] =!=
      "VerifiedFLINTAffineRREFRun",
    {diagnosticSeconds, diagnosticRun} = AbsoluteTiming[
      CodexFLINTAffineRREFAdapter`CFFRRun[
        files["NativeBinary"], request, nativeThreads, True, 900]];
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
        ConstantArray[0, columns] ||
      rank + nullity =!= columns ||
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
  {rows, columns, rightColumn, augmented, coefficient, augmentedRank},
  {rows, columns} = Dimensions[matrix];
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
  "Status" -> "CF300SecondSupportShellImageCheckpointV1",
  "DriverSHA256" -> driverHashBefore,
  "SourceHashes" -> sourceHashesBefore,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheSHA256" -> expectedCacheHash,
  "ImageSpecification" -> image,
  "ASABIFingerprint" -> asPreparation["ABIFingerprint"],
  "MaxABIFingerprint" -> maxPreparation["ABIFingerprint"],
  "MaxAssemblyFingerprint" -> maxAssembly["AssemblyFingerprint"],
  "NativeThreads" -> nativeThreads|>;
validImageResultQ[result_Association, image_Association] := TrueQ[
  result["ImageID"] === image["ImageID"] &&
  result["Prime"] === image["Prime"] &&
  result["EpsilonValue"] === image["EpsilonValue"] &&
  result["MaxPointCount"] === 34 &&
  result["ASPointCount"] === 27 &&
  result["PureSupersetMatrixProjection"] === True &&
  AssociationQ[result["Witness"]] &&
  AssociationQ[result["BlockWitnessScores"]] &&
  AssociationQ[result["MaximalWitnessScore"]] &&
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
    Print["CF300_SECOND_SHELL FAIL invalid checkpoint image=",
      image["ImageID"]];
    cf300SecondShellDriverV3Exit[75]];
  If[AssociationQ[prior],
    AppendTo[results, prior];
    Print["CF300_SECOND_SHELL milestone=image_checkpoint_resumed image=",
      image["ImageID"]];
    Continue[]];

  prime = image["Prime"];
  epsilonValue = image["EpsilonValue"];
  seed = Hash[{2026082329, "CF300_SECOND_SHELL",
    image["ImageID"], maxPreparation["ABIFingerprint"]}, "CRC32"];
  {sampleSeconds, maxSample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCAAssembleSample[
      maxAssembly, epsilonValue, prime,
      "PointCount" -> 34, "MaximumAttempts" -> 1360,
      "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
      "BranchFlipMask" -> 0]];
  If[Lookup[maxSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      maxSample["MatrixDimensions"] =!= {1088, 1040},
    Print["CF300_SECOND_SHELL FAIL max sample image=",
      image["ImageID"]];
    cf300SecondShellDriverV3Exit[76]];
  screenPoints = Take[maxSample["AcceptedPoints"], 27];
  targetScreenMatrix = Take[maxSample["Matrix"], 864];
  targetScreenRight = Take[maxSample["RightHandSide"], 864];
  asSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
    asAssembly, epsilonValue, prime,
    "PointCount" -> 27, "MaximumAttempts" -> 27,
    "RandomSeed" -> seed, "CandidatePoints" -> screenPoints,
    "BranchFlipMask" -> 0];
  projectedAS = targetScreenMatrix[[All, asColumnMap]];
  If[Lookup[asSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      asSample["AcceptedPoints"] =!= screenPoints ||
      asSample["MatrixDimensions"] =!= {864, 816} ||
      asSample["RightHandSide"] =!= targetScreenRight ||
      projectedAS =!= asSample["Matrix"],
    Print["CF300_SECOND_SHELL FAIL pure-superset projection image=",
      image["ImageID"]];
    cf300SecondShellDriverV3Exit[77]];
  witness = CodexAffineInconsistencyWitness`AIWConstruct[
    SparseArray[asSample["Matrix"]], asSample["RightHandSide"],
    prime, files["NativeAdapter"], files["NativeBinary"],
    nativeThreads,
    makeNonce[image["ImageID"], "as-left-witness"]];
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    Print["CF300_SECOND_SHELL FAIL AS witness image=",
      image["ImageID"], " status=", Lookup[witness, "Status", None]];
    cf300SecondShellDriverV3Exit[78]];
  blockScores = Association@KeyValueMap[
    #1 -> CodexAffineInconsistencyWitness`AIWScoreColumns[
      witness, SparseArray[targetScreenMatrix[[All, #2]]]] &,
    blockColumnMaps];
  maximalScore = CodexAffineInconsistencyWitness`AIWScoreColumns[
    witness, SparseArray[targetScreenMatrix[[All, newColumnMap]]]];
  If[! AllTrue[Append[Values[blockScores], maximalScore],
      Lookup[#1, "Status", None] ===
        "AffineWitnessCandidateColumnScoreV1" &],
    Print["CF300_SECOND_SHELL FAIL witness score image=",
      image["ImageID"]];
    cf300SecondShellDriverV3Exit[79]];
  fullRank = If[TrueQ[maximalScore["AllScoresZero"]],
    Missing["RejectedByASLeftWitness"],
    rankImage[maxSample["Matrix"], maxSample["RightHandSide"],
      prime, image["ImageID"]]];
  If[! MissingQ[fullRank] &&
      Lookup[fullRank, "Status", None] =!=
        "CertifiedAffineConsistencyByTwoRanksV1",
    Print["CF300_SECOND_SHELL FAIL full rank image=",
      image["ImageID"], " status=", Lookup[fullRank, "Status", None]];
    cf300SecondShellDriverV3Exit[80]];
  imageResult = Join[image, <|
    "ASPointCount" -> 27, "MaxPointCount" -> 34,
    "AttemptCount" -> maxSample["AttemptCount"],
    "AcceptedPointsFingerprint" ->
      fingerprint[maxSample["AcceptedPoints"]],
    "SampleSeconds" -> sampleSeconds,
    "MaxMatrixFingerprint" ->
      Hash[maxSample["Matrix"], "SHA256", "HexString"],
    "RightHandSideFingerprint" ->
      Hash[maxSample["RightHandSide"], "SHA256", "HexString"],
    "PureSupersetMatrixProjection" -> True,
    "Witness" -> KeyDrop[witness, "Witness"],
    "BlockWitnessScores" -> blockScores,
    "MaximalWitnessScore" -> maximalScore,
    "FullRank" -> fullRank|>];
  checkpointCommit = writeCheckpoint[image, imageResult];
  If[checkpointCommit === $Failed,
    Print["CF300_SECOND_SHELL FAIL checkpoint commit image=",
      image["ImageID"]];
    cf300SecondShellDriverV3Exit[81]];
  AppendTo[results, imageResult];
  Print["CF300_SECOND_SHELL milestone=image_checkpoint_committed image=",
    image["ImageID"], " block_nonzero=",
    Lookup[Values[blockScores], "NonzeroScoreCount"],
    " maximal_consistent=", If[AssociationQ[fullRank],
      fullRank["Consistent"], False]],
  {image, images}];

If[Length[results] =!= Length[images] ||
    Lookup[results, "ImageID"] =!= Lookup[images, "ImageID"] ||
    ! stableInputsQ[],
  Print["CF300_SECOND_SHELL FAIL completion integrity"];
  cf300SecondShellDriverV3Exit[82]];
consistentEveryImage = AllTrue[results,
  AssociationQ[#1["FullRank"]] &&
    TrueQ[#1["FullRank", "Consistent"]] &];
inconsistentEveryImage = AllTrue[results,
  MissingQ[#1["FullRank"]] ||
    (AssociationQ[#1["FullRank"]] &&
      ! TrueQ[#1["FullRank", "Consistent"]]) &];
finalPayload = <|
  "Status" -> If[consistentEveryImage,
    "CF300SecondSupportShellConsistentAllImages",
    "CF300SecondSupportShellScreenCompleted"],
  "Conclusion" -> Which[
    consistentEveryImage,
      "Promote maximal second numerator shell to reconstruction",
    inconsistentEveryImage,
      "Maximal second numerator shell is inconsistent in all four images; every anisotropic sub-shell is rejected by inclusion",
    True,
      "Image-dependent consistency; add fresh images before promotion"],
  "DriverSHA256" -> driverHashBefore,
  "SourceHashes" -> sourceHashesBefore,
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile,
  "CacheSHA256" -> expectedCacheHash,
  "NativeThreads" -> nativeThreads,
  "TargetBuildSeconds" -> targetBuildSeconds,
  "BaseSupportCount" -> 30,
  "FirstShellSupportCount" -> 42,
  "SecondShellSupportCount" -> 56,
  "SecondShellBlocks" -> <|
    "XEdge7" -> xEdge, "YEdge6" -> yEdge, "Corner1" -> corner|>,
  "SecondShellBlockColumnCounts" ->
    Map[Length, blockColumnMaps],
  "ASUnknownCount" -> 816,
  "SecondShellUnknownCount" -> 1040,
  "SecondShellPointCount" -> 34,
  "ASABIFingerprint" -> asPreparation["ABIFingerprint"],
  "MaxABIFingerprint" -> maxPreparation["ABIFingerprint"],
  "MaxAssemblyFingerprint" -> maxAssembly["AssemblyFingerprint"],
  "ImageSpecifications" -> images,
  "WitnessSemantics" ->
    "A_AS^T y=0,b^T y=1; zero y^T C rejects a block; maximal two-rank inconsistency rejects every sub-shell",
  "ConsistentEveryImage" -> consistentEveryImage,
  "InconsistentEveryImage" -> inconsistentEveryImage,
  "Results" -> results|>;
finalCommit = CodexDirectDiscriminatorAtomicCheckpointV2`DDACWriteAtomic[
  outputFile, finalPayload, Function[stableInputsQ[]]];
If[Lookup[finalCommit, "Status", None] =!= "AtomicWriteCommittedV2",
  Print["CF300_SECOND_SHELL FAIL typed_atomic_commit=",
    InputForm[finalCommit]];
  cf300SecondShellDriverV3Exit[98]];
Print["CF300_SECOND_SHELL status=", finalPayload["Status"],
  " output=", outputFile, " output_sha=",
  finalCommit["TargetSHA256"]];
cf300SecondShellDriverV3Exit[0];
];
canonicalRuntimeCode = If[
  AssociationQ[canonicalRuntimeOutcome] &&
    TrueQ[canonicalRuntimeOutcome["DefinitionsRestoredQ"]] &&
    TrueQ[canonicalRuntimeOutcome["ContextRestoredQ"]] &&
    TrueQ[canonicalRuntimeOutcome["ContextPathRestoredQ"]],
  Lookup[canonicalRuntimeOutcome, "Code", 99],
  99];
Print["CF300_SECOND_SHELL canonical_runtime_cleanup=",
  InputForm[canonicalRuntimeOutcome]];
End[];
EndPackage[];
System`Exit[canonicalRuntimeCode];
