#!/usr/bin/env wolframscript

$HistoryLength = 0;
campaignStartTime = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4 || Length[arguments] > 5,
  Print["CF300S12R2DIRECTDISC FAIL usage=<project-root> <rank2-preparation.wl> " <>
    "<fresh-output.wl> <I00|I01|I10|I11|ALL> [native-threads]"];
  Exit[64]];

parseStrictInteger[text_String] := Module[{digits, negative},
  If[! StringMatchQ[text,
      RegularExpression["0|-?[1-9][0-9]*"]], Return[$Failed]];
  negative = StringStartsQ[text, "-"];
  digits = If[negative, StringDrop[text, 1], text];
  If[negative, -FromDigits[digits], FromDigits[digits]]
];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
imageSelector = arguments[[4]];
nativeThreads = If[Length[arguments] === 5,
  parseStrictInteger[arguments[[5]]], 1];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
assemblerFile = FileNameJoin[{driverDirectory,
  "DirectRootChannelAssembler.wl"}];
adapterDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh"}];
nativeDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh"}];
adapterFile = FileNameJoin[{adapterDirectory, "FlintAffineRREFAdapter.wl"}];
nativeSource = FileNameJoin[{nativeDirectory, "flint_affine_rref.c"}];
nativeBinary = FileNameJoin[{nativeDirectory, "bin", "flint_affine_rref"}];

expectedPreparationSHA256 =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedInputSHA256 =
  "274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6";
expectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";
expectedAdapterSHA256 =
  "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c";
expectedNativeSourceSHA256 =
  "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd";
expectedNativeBinarySHA256 =
  "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5";
expectedSourceClosureRelative = <|
  "External/CodexExchange/triple_root_2026-08-22/TripleRootAffinePilot.wl" -> "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootAlgebra.wl" -> "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootReconstructionPrototype.wl" -> "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootStripAdapter.wl" -> "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "External/CodexExchange/triple_root_2026-08-22/direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl" -> "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "External/CodexExchange/triple_root_2026-08-22/flint_affine_rref_wl_xh/FlintAffineRREFAdapter.wl" -> "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c",
  "External/CodexExchange/triple_root_2026-08-22/flint_affine_rref_xh/flint_affine_rref.c" -> "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd"|>;
expectedSourceClosure[] := Association@KeyValueMap[
  FileNameJoin[{projectRoot, #1}] -> #2 &, expectedSourceClosureRelative];
sourceClosureDifference[observed_Association, expected_Association] :=
    Module[{observedKeys, expectedKeys, commonKeys},
  observedKeys = Keys[observed]; expectedKeys = Keys[expected];
  commonKeys = Intersection[observedKeys, expectedKeys];
  <|"MissingKeys" -> Complement[expectedKeys, observedKeys],
    "UnexpectedKeys" -> Complement[observedKeys, expectedKeys],
    "HashMismatchKeys" -> Select[commonKeys,
      observed[#1] =!= expected[#1] &]|>
];

coreDependencyFiles = <|
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
explicitRuntimeFiles = Join[coreDependencyFiles, <|
  "DirectRootChannelAssembler" -> assemblerFile,
  "FLINTAffineRREFAdapter" -> adapterFile,
  "FLINTAffineRREFSource" -> nativeSource,
  "FLINTAffineRREFBinary" -> nativeBinary|>];
executedSourceFiles = Join[
  KeyTake[coreDependencyFiles, {"TripleRootAlgebra",
    "TripleRootStripAdapter", "TripleRootAffinePilot",
    "TripleRootReconstructionPrototype"}], <|
    "DirectRootChannelAssembler" -> assemblerFile,
    "FLINTAffineRREFAdapter" -> adapterFile,
    "FLINTAffineRREFSource" -> nativeSource|>];

sourceClosureFiles[] := Sort[DeleteDuplicates[Values[executedSourceFiles]]];
sourceClosureSnapshot[] := Module[{files = sourceClosureFiles[]},
  AssociationThread[files,
    FileHash[#1, "SHA256", "HexString"] & /@ files]];
namedRuntimeHashes[] := Map[
  FileHash[#1, "SHA256", "HexString"] &, explicitRuntimeFiles];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[explicitRuntimeFiles], FileExistsQ] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8) ||
    ! MemberQ[{"I00", "I01", "I10", "I11", "ALL"}, imageSelector] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300S12R2DIRECTDISC FAIL invalid input, dependency, resource limit, or stale target"];
  Exit[65]];

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]
];
writeAtomic[value_, commitCheck_: Automatic] := Module[
  {temporary, written, renamed, committed, postCommitValid},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp." <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  If[commitCheck =!= Automatic && ! TrueQ[commitCheck[]],
    deleteIfPresent[temporary]; Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], deleteIfPresent[temporary]; Return[$Failed]];
  committed = Quiet[Check[Get[outputFile], $Failed]];
  postCommitValid = SameQ[committed, value] && AssociationQ[committed] &&
    Lookup[committed, "Status", None] === Lookup[value, "Status", None] &&
    (commitCheck === Automatic || TrueQ[commitCheck[]]);
  If[! TrueQ[postCommitValid],
    If[! TrueQ[deleteIfPresent[outputFile]],
      Print["CF300S12R2DIRECTDISC FAIL invalid committed target remains output=",
        outputFile]];
    Return[$Failed]];
  outputFile
];
finish[status_String, data_: <||>, code_: 2] := Module[{artifact},
  artifact = Join[<|"Status" -> status,
    "PreparationFile" -> preparationFile,
    "NativeBinary" -> nativeBinary|>, data];
  If[writeAtomic[artifact] === $Failed,
    Print["CF300S12R2DIRECTDISC FAIL atomic output race output=", outputFile];
    Exit[98]];
  Print["CF300S12R2DIRECTDISC RESULT status=", status,
    " output=", outputFile];
  Exit[code]
];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
namedRuntimeHashesBefore = namedRuntimeHashes[];
sourceClosureBefore = sourceClosureSnapshot[];
sourceClosureExpected = expectedSourceClosure[];
sourceClosureDiff = sourceClosureDifference[sourceClosureBefore,
  sourceClosureExpected];
coreHashesBefore = KeyTake[namedRuntimeHashesBefore,
  Keys[coreDependencyFiles]];
If[preparationHashBefore =!= expectedPreparationSHA256,
  finish["PinnedPreparationHashMismatch", <|
    "ExpectedPreparationSHA256" -> expectedPreparationSHA256,
    "ObservedPreparationSHA256" -> preparationHashBefore|>, 66]];

If[! AllTrue[Values[sourceClosureDiff], #1 === {} &],
  finish["PinnedExecutedSourceClosureMismatch", <|
    "ExpectedSourceClosure" -> KeySort[sourceClosureExpected],
    "ObservedSourceClosure" -> KeySort[sourceClosureBefore],
    "SourceClosureDifference" -> sourceClosureDiff|>, 66]];
Get[coreDependencyFiles["TripleRootAlgebra"]];
Get[coreDependencyFiles["TripleRootStripAdapter"]];
Get[coreDependencyFiles["TripleRootAffinePilot"]];
Get[coreDependencyFiles["TripleRootReconstructionPrototype"]];
If[namedRuntimeHashesBefore["DirectRootChannelAssembler"] =!=
      expectedAssemblerSHA256 ||
    namedRuntimeHashesBefore["FLINTAffineRREFAdapter"] =!=
      expectedAdapterSHA256 ||
    namedRuntimeHashesBefore["FLINTAffineRREFSource"] =!=
      expectedNativeSourceSHA256 ||
    namedRuntimeHashesBefore["FLINTAffineRREFBinary"] =!=
      expectedNativeBinarySHA256,
  finish["PinnedNativeRuntimeHashMismatch", <|
    "NamedRuntimeHashes" -> namedRuntimeHashesBefore|>, 66]];
Get[assemblerFile];
Get[adapterFile];
If[namedRuntimeHashes[] =!= namedRuntimeHashesBefore ||
    sourceClosureSnapshot[] =!= sourceClosureBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["DependencyChangedDuringLoad", <||>, 95]];
Print["CF300S12R2DIRECTDISC milestone=load_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];

artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
    Quiet[Check[Get[file], $Failed]]]];
{preparationReadSeconds, preparationArtifact} = AbsoluteTiming[
  TimeConstrained[MemoryConstrained[artifactRead[preparationFile],
    2 2^30, $Failed], 600, $Failed]];
If[FileHash[preparationFile, "SHA256", "HexString"] =!=
    preparationHashBefore,
  finish["PreparationChangedDuringRead", <||>, 96]];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    Lookup[preparationArtifact, "InputSHA256", None] =!=
      expectedInputSHA256 ||
    Lookup[preparationArtifact, "DependencyHashes", None] =!=
      coreHashesBefore,
  finish["PinnedPreparationArtifactInvalid", <||>, 66]];

inputFile = Lookup[preparationArtifact, "InputFile", $Failed];
preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
If[! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
    FileHash[inputFile, "SHA256", "HexString"] =!= expectedInputSHA256 ||
    ! StringQ[preparationDriverFile] ||
    ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None],
  finish["PinnedPreparationProvenanceInvalid", <||>, 66]];

basePreparation = Lookup[preparationArtifact, "Preparation", $Failed];
If[! AssociationQ[basePreparation],
  finish["PinnedPreparationMissingPreparation", <||>, 67]];
sidecar = Lookup[preparationArtifact, "SidecarCertificate", $Failed];
squareClass = If[AssociationQ[sidecar],
  Lookup[sidecar, "LocalSquareClassCertificate", $Failed], $Failed];
expectedGradeMap = Table[localMask -> Sum[
    BitGet[localMask, bit - 1] *
      2^(basePreparation["RootSourceIndices"][[bit]] - 1),
    {bit, basePreparation["RootCount"]}],
  {localMask, 0, basePreparation["GradeCount"] - 1}];
If[! AssociationQ[sidecar] ||
    ! TrueQ[Lookup[sidecar, "RoundTripExact", False]] ||
    Lookup[sidecar, "ActiveGrades", None] =!= {0, 2, 4} ||
    Lookup[sidecar, "ActiveGradeRank", None] =!= 2 ||
    Lookup[sidecar, "StableLocalRootSourceOrder", None] =!= {2, 3} ||
    Lookup[sidecar, "LocalToGlobalGradeMap", None] =!= expectedGradeMap ||
    ! AssociationQ[squareClass] ||
    ! TrueQ[Lookup[squareClass, "Independent", False]] ||
    Lookup[squareClass, "Rank", None] =!= 2,
  finish["PinnedSquareClassCertificateInvalid", <||>, 67]];
{preparationABISeconds, preparationABIValid} = AbsoluteTiming[
  TimeConstrained[MemoryConstrained[
    CodexTripleRootReconstruction`TRPreparationABIValidQ[basePreparation],
    4 2^30, $Failed], 900, $Failed]];
If[! AssociationQ[basePreparation] ||
    preparationABIValid =!= True ||
    basePreparation["RootCount"] =!= 2 ||
    basePreparation["GradeCount"] =!= 4 ||
    basePreparation["RootSourceIndices"] =!= {2, 3} ||
    basePreparation["Dimensions"] =!= {2, 2} ||
    basePreparation["Normalizations"] =!= {} ||
    basePreparation["GaugeDenominatorDegrees"] =!= {4, 5} ||
    Length[basePreparation["GaugeSupport"]] =!= 30 ||
    Length[basePreparation["OneForms"]] =!= 36 ||
    basePreparation["GaugeUnknownCount"] =!= 480 ||
    basePreparation["ResidueUnknownCount"] =!= 144 ||
    basePreparation["UnknownCount"] =!= 624 ||
    basePreparation["EquationsPerPoint"] =!= 32,
  finish["PinnedPreparationShapeInvalid", <||>, 67]];
Print["CF300S12R2DIRECTDISC milestone=preparation_valid elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];

zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#1] === 0] &];
canonicalRational[expression_] := Module[{q = Together[expression]},
  {Expand[Numerator[q]], Expand[Denominator[q]]}
];
formKey[form : {_, _}, roots_List] := Module[{channels, canonical},
  channels = CodexTripleRootStrip`TRFieldDecompose[#1, roots] & /@ form;
  If[MemberQ[channels, $Failed], Return[$Failed]];
  canonical = Map[canonicalRational, channels, {2}];
  fingerprint[canonical]
];

$discriminatorFailureTag = Unique["CF300Rank2DiscriminatorFailure"];
raise[status_String, data_: <||>] := Throw[
  Join[<|"Status" -> status|>, data], $discriminatorFailureTag];

preMainElapsedSeconds = N[AbsoluteTime[] - campaignStartTime];
If[preMainElapsedSeconds >= 28790,
  finish["DiscriminatorGlobalTimeLimit", <|
    "PreMainElapsedSeconds" -> preMainElapsedSeconds|>, 73]];
mainTimeBudgetSeconds = Max[1, Floor[28790 - preMainElapsedSeconds]];
mainResult = MemoryConstrained[TimeConstrained[Catch[Module[
  {variables, epsilon, roots, record, strip, channelTensor,
   rawChannelExpressions, channelRecords, channelGroups,
   channelExpressions, channelGroup,
   rawPolynomialRecords, polynomialGroups, polynomialGroup,
   uniquePolynomials,
   factorizations, rawEpsilonFreeFactors, irreducibleFactors,
   factorPairs, newFactorForms, unionForms,
   unionKeys = <||>, key, existingIndex, appendUniqueForm,
   currentSupport, widenedSupport, buildVariant, variants,
   variantData, allImageSpecs, imageSpecs, makeNonce, requestFingerprint,
   nativeRank, rankImage, variantColumnMap, variantColumnMaps,
   projectionContract, fullDirectPreparation, directPreparationSeconds,
   assembleSharedSamples, sharedSamples, sharedPointStreams = <||>,
   results = <||>, variantLabel,
   preparation, pointCount, image, seed, sampleSeconds, sample,
   matrix, right, imageResult, nested, nestedMatrix, nestedRight,
   sourceStateAtCompletion, expectedSourceState, currentSourceState,
   boundedCensus, result},

  variables = basePreparation["Variables"];
  epsilon = basePreparation["Regulator"];
  roots = basePreparation["Roots"];
  record = basePreparation["Record"];
  strip = record["Strip"];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[epsilon, _Symbol] || ! MatchQ[strip, {_List, _List, _List}],
    raise["PreparationEquationShapeInvalid"]];
  Print["CF300S12R2DIRECTDISC milestone=census_start elapsed_s=",
    N[AbsoluteTime[] - campaignStartTime]];

  (* Decompose every scalar entry to rational rank-two channels, then
     census epsilon-free irreducible numerator/denominator factors. *)
  SetAttributes[boundedCensus, HoldAll];
  boundedCensus[held_] := TimeConstrained[
    MemoryConstrained[held, 3 2^30, $Failed], 180, $Failed];
  channelTensor = boundedCensus[Quiet[Check[
    Map[CodexTripleRootStrip`TRFieldDecompose[#1, roots] &,
      strip, {4}], $Failed]]];
  If[channelTensor === $Failed || ! FreeQ[channelTensor, $Failed],
    raise["RationalChannelCensusFailed"]];
  rawChannelExpressions = Flatten[channelTensor];
  channelRecords = Table[Module[{localQ, canonical},
      localQ = boundedCensus[Together[channel]];
      If[localQ === $Failed,
        raise["RationalChannelCanonicalizationLimit"]];
      canonical = boundedCensus[
        {Expand[Numerator[localQ]], Expand[Denominator[localQ]]}];
      If[canonical === $Failed,
        raise["RationalChannelCanonicalizationLimit"]];
      <|"Expression" -> localQ, "Canonical" -> canonical,
        "Fingerprint" -> fingerprint[canonical]|>],
    {channel, rawChannelExpressions}];
  channelGroups = GatherBy[channelRecords, #1["Fingerprint"] &];
  Do[
    If[! AllTrue[Rest[channelGroup],
        TrueQ[boundedCensus[Together[#1["Expression"] -
          First[channelGroup]["Expression"]]] === 0] &],
      raise["RationalChannelFingerprintCollision", <|
        "Fingerprint" -> First[channelGroup]["Fingerprint"]|>]],
    {channelGroup, channelGroups}];
  channelExpressions = Lookup[First /@ channelGroups, "Expression"];

  rawPolynomialRecords = Flatten[Table[
    If[TrueQ[channelExpression === 0], {},
      {Numerator[channelExpression], Denominator[channelExpression]}],
    {channelExpression, channelExpressions}]];
  polynomialGroups = GatherBy[rawPolynomialRecords,
    fingerprint[Expand[#1]] &];
  Do[
    If[! AllTrue[Rest[polynomialGroup],
        TrueQ[Expand[#1 - First[polynomialGroup]] === 0] &],
      raise["PolynomialFingerprintCollision"]],
    {polynomialGroup, polynomialGroups}];
  uniquePolynomials = First /@ polynomialGroups;
  factorizations = Table[
    boundedCensus[Quiet[Check[FactorList[Expand[polynomial]], $Failed]]],
    {polynomial, uniquePolynomials}];
  If[MemberQ[factorizations, $Failed] ||
      ! AllTrue[factorizations, ListQ[#1] && #1 =!= {} &],
    raise["RationalChannelFactorizationLimitOrFailure"]];
  factorPairs = Flatten[Rest /@ factorizations, 1];
  rawEpsilonFreeFactors = Cases[factorPairs,
    {factor_, _Integer} /; ! TrueQ[NumericQ[factor]] &&
        FreeQ[factor, epsilon] &&
        ! FreeQ[factor, Alternatives @@ variables] :> factor];
  irreducibleFactors = DeleteDuplicatesBy[
    Join[variables, rawEpsilonFreeFactors], fingerprint[Expand[#1]] &];
  newFactorForms = Table[
    boundedCensus[{Together[D[factor, variables[[1]]]/factor],
      Together[D[factor, variables[[2]]]/factor]}],
    {factor, irreducibleFactors}];
  If[MemberQ[newFactorForms, $Failed],
    raise["FactorDLogConstructionLimit"]];
  If[! AllTrue[newFactorForms,
      MatchQ[#1, {_, _}] && FreeQ[#1, epsilon] && ! zeroQ[#1] &&
        TrueQ[Together[D[#1[[2]], variables[[1]]] -
          D[#1[[1]], variables[[2]]]] === 0] &],
    raise["FactorDLogValidationFailed"]];

  unionForms = {};
  appendUniqueForm[form_] := Module[{localKey, prior},
    localKey = formKey[form, roots];
    If[localKey === $Failed, raise["OneFormChannelKeyFailed"]];
    If[KeyExistsQ[unionKeys, localKey],
      prior = unionForms[[unionKeys[localKey]]];
      If[! zeroQ[form - prior],
        raise["OneFormFingerprintCollision", <|"Fingerprint" -> localKey|>]],
      AppendTo[unionForms, form];
      AssociateTo[unionKeys, localKey -> Length[unionForms]]]
  ];
  Scan[appendUniqueForm, basePreparation["OneForms"]];
  Scan[appendUniqueForm, newFactorForms];
  If[Take[unionForms, Length[basePreparation["OneForms"]]] =!=
      basePreparation["OneForms"] ||
      Length[unionForms] < Length[basePreparation["OneForms"]],
    raise["OneFormUnionNotPureSuperset"]];

  currentSupport = basePreparation["GaugeSupport"];
  widenedSupport = Join[currentSupport,
    Complement[
      Flatten[Table[{px, py}, {px, 0, 5}, {py, 0, 6}], 1],
      currentSupport]];
  If[Length[widenedSupport] =!= 42 ||
      Take[widenedSupport, Length[currentSupport]] =!= currentSupport ||
      Complement[currentSupport, widenedSupport] =!= {} ||
      Max /@ Transpose[widenedSupport] =!= {5, 6},
    raise["WidenedSupportConstructionFailed"]];

  buildVariant[label_String, support_List, forms_List] := Module[
    {payload, abiFingerprint, dimensions, gradeCount, gaugeCount,
     residueCount, unknownCount, variant},
    dimensions = basePreparation["Dimensions"];
    gradeCount = basePreparation["GradeCount"];
    gaugeCount = (Times @@ dimensions) gradeCount Length[support];
    residueCount = Length[forms] (Times @@ dimensions);
    unknownCount = gaugeCount + residueCount;
    payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
      basePreparation["Record"], roots, variables, epsilon, dimensions,
      basePreparation["GaugeDenominator"], support, forms,
      basePreparation["Normalizations"]];
    If[payload === $Failed,
      raise["VariantABIPayloadFailed", <|"Variant" -> label|>]];
    abiFingerprint = fingerprint[payload];
    variant = Join[basePreparation, <|
      "OneForms" -> forms,
      "OneFormMetadata" -> <|
        "Status" -> "CF300Rank2DiscriminatorPureSupersetV1",
        "Variant" -> label,
        "BaseCount" -> Length[basePreparation["OneForms"]],
        "FactorDLogCandidateCount" -> Length[newFactorForms],
        "DeduplicatedCount" -> Length[forms]|>,
      "GaugeSupport" -> support,
      "GaugeUnknownCount" -> gaugeCount,
      "ResidueUnknownCount" -> residueCount,
      "UnknownCount" -> unknownCount,
      "ABIPayload" -> payload,
      "ABIFingerprint" -> abiFingerprint|>];
    If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[variant],
      raise["VariantABIValidationFailed", <|"Variant" -> label|>]];
    <|"Label" -> label, "Preparation" -> variant,
      "SupportCount" -> Length[support], "OneFormCount" -> Length[forms],
      "GaugeUnknownCount" -> gaugeCount,
      "ResidueUnknownCount" -> residueCount,
      "UnknownCount" -> unknownCount,
      "PointCount" -> Max[4, Ceiling[(unknownCount + 32)/32]],
      "ABIFingerprint" -> abiFingerprint,
      "SupportFingerprint" -> fingerprint[support],
      "OneFormFingerprint" -> fingerprint[
        formKey[#1, roots] & /@ forms]|>
  ];

  variants = {
    buildVariant["A0", currentSupport, basePreparation["OneForms"]],
    buildVariant["AS", widenedSupport, basePreparation["OneForms"]],
    buildVariant["AL", currentSupport, unionForms],
    buildVariant["ASL", widenedSupport, unionForms]};
  If[Lookup[variants, "Label"] =!= {"A0", "AS", "AL", "ASL"} ||
      variants[[1, "ABIFingerprint"]] =!=
        basePreparation["ABIFingerprint"] ||
      variants[[1, "PointCount"]] =!= 21 ||
      variants[[2, "PointCount"]] =!= 27,
    raise["VariantContractInvalid"]];
  Print["CF300S12R2DIRECTDISC milestone=census_complete elapsed_s=",
    N[AbsoluteTime[] - campaignStartTime],
    " unique_channels=", Length[channelExpressions],
    " factor_dlogs=", Length[newFactorForms],
    " union_forms=", Length[unionForms]];

  variantColumnMap[localPreparation_Association] := Module[
    {fullPreparation = variants[[4, "Preparation"]], upper, lower,
     gradeCount, fullSupport, localSupport, supportLocations,
     supportPositions, fullFormKeys, localFormKeys, formLocations,
     formPositions, fullSupportCount, fullGaugeCount, gaugeColumns,
     residueColumns, columnMap},
    {upper, lower} = localPreparation["Dimensions"];
    gradeCount = localPreparation["GradeCount"];
    fullSupport = fullPreparation["GaugeSupport"];
    localSupport = localPreparation["GaugeSupport"];
    supportLocations = FirstPosition[fullSupport, #1,
        Missing["SupportNotInASL"]] & /@ localSupport;
    fullFormKeys = formKey[#1, roots] & /@
      fullPreparation["OneForms"];
    localFormKeys = formKey[#1, roots] & /@
      localPreparation["OneForms"];
    formLocations = FirstPosition[fullFormKeys, #1,
        Missing["OneFormNotInASL"]] & /@ localFormKeys;
    If[! AllTrue[Join[supportLocations, formLocations],
        MatchQ[#1, {_Integer}] &], Return[$Failed]];
    supportPositions = First /@ supportLocations;
    formPositions = First /@ formLocations;
    fullSupportCount = Length[fullSupport];
    fullGaugeCount = fullPreparation["GaugeUnknownCount"];
    gaugeColumns = Flatten[Table[
      (((i - 1) lower + (j - 1)) gradeCount + grade)
          fullSupportCount + supportPositions[[monomial]],
      {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
      {monomial, Length[localSupport]}]];
    residueColumns = Flatten[Table[
      fullGaugeCount +
        ((formPositions[[letter]] - 1) upper + (i - 1)) lower + j,
      {letter, Length[localFormKeys]}, {i, upper}, {j, lower}]];
    columnMap = Join[gaugeColumns, residueColumns];
    If[Length[columnMap] =!= localPreparation["UnknownCount"] ||
        ! DuplicateFreeQ[columnMap] ||
        ! AllTrue[columnMap,
          1 <= #1 <= fullPreparation["UnknownCount"] &], Return[$Failed]];
    columnMap
  ];
  variantColumnMaps = Association@Table[
    variantData["Label"] -> variantColumnMap[variantData["Preparation"]],
    {variantData, variants}];
  If[MemberQ[Values[variantColumnMaps], $Failed] ||
      variantColumnMaps["ASL"] =!=
        Range[variants[[4, "UnknownCount"]]],
    raise["ASLProjectionColumnMapInvalid"]];
  projectionContract = Association@Table[
    variantData["Label"] -> <|
      "UnknownCount" -> variantData["UnknownCount"],
      "ColumnMapLength" -> Length[variantColumnMaps[variantData["Label"]]],
      "ColumnMapFingerprint" ->
        fingerprint[variantColumnMaps[variantData["Label"]]],
      "IdentityMap" -> (variantColumnMaps[variantData["Label"]] ===
        Range[variantData["UnknownCount"]])|>,
    {variantData, variants}];

  Print["CF300S12R2DIRECTDISC milestone=asl_compile_start elapsed_s=",
    N[AbsoluteTime[] - campaignStartTime],
    " unknowns=", variants[[4, "UnknownCount"]]];
  {directPreparationSeconds, fullDirectPreparation} = AbsoluteTiming[
    TimeConstrained[MemoryConstrained[
      CodexDirectRootChannelAssembler`DRCAPrepare[
        variants[[4, "Preparation"]]], 4 2^30, $Failed], 1800, $Failed]];
  If[! AssociationQ[fullDirectPreparation] ||
      Lookup[fullDirectPreparation, "Status", None] =!=
        "PreparedDirectRootChannelsV1" ||
      ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        fullDirectPreparation] ||
      fullDirectPreparation["SourceABIFingerprint"] =!=
        variants[[4, "ABIFingerprint"]] ||
      fullDirectPreparation["GaugeSupport"] =!=
        variants[[4, "Preparation", "GaugeSupport"]] ||
      fullDirectPreparation["OneForms"] =!=
        variants[[4, "Preparation", "OneForms"]] ||
      fullDirectPreparation["UnknownCount"] =!=
        variants[[4, "UnknownCount"]] ||
      fullDirectPreparation["EquationsPerPoint"] =!= 32,
    raise["ASLDirectPreparationLimitOrFailure", <|
      "DirectPreparationSeconds" -> directPreparationSeconds,
      "DirectPreparationStatus" ->
        Lookup[fullDirectPreparation, "Status", None]|>]];
  Print["CF300S12R2DIRECTDISC milestone=asl_compile_complete elapsed_s=",
    N[AbsoluteTime[] - campaignStartTime],
    " compile_s=", directPreparationSeconds,
    " assembly_fingerprint=",
    fullDirectPreparation["AssemblyFingerprint"]];

  allImageSpecs = {
    <|"ImageID" -> "I00", "Prime" -> 10007,
      "EpsilonValue" -> 1/21|>,
    <|"ImageID" -> "I01", "Prime" -> 10007,
      "EpsilonValue" -> 1/11|>,
    <|"ImageID" -> "I10", "Prime" -> 10039,
      "EpsilonValue" -> 1/21|>,
    <|"ImageID" -> "I11", "Prime" -> 10039,
      "EpsilonValue" -> 1/11|>};
  If[! AllTrue[allImageSpecs,
      PrimeQ[#1["Prime"]] && Mod[#1["Prime"], 4] === 3 &],
    raise["ImagePrimeContractInvalid"]];
  imageSpecs = If[imageSelector === "ALL", allImageSpecs,
    Select[allImageSpecs, #1["ImageID"] === imageSelector &]];
  If[Length[imageSpecs] =!= If[imageSelector === "ALL", 4, 1],
    raise["ImageSelectorContractInvalid"]];

  makeNonce[label_String, imageID_String, tag_String] := Module[{nonce},
    nonce = Mod[Hash[{driverHashBefore, label, imageID, tag, #1},
        "SHA256"], 2^64] & /@ {"hi", "lo"};
    If[nonce === {0, 0}, {0, 1}, nonce]
  ];
  requestFingerprint[request_Association] := fingerprint[<|
    "Metadata" -> KeyDrop[request, {"Matrix", "RightHandSide"}],
    "MatrixSHA256" -> Hash[request["Matrix"], "SHA256", "HexString"],
    "RightHandSideSHA256" -> Hash[request["RightHandSide"],
      "SHA256", "HexString"]|>];

  nativeRank[localMatrix_, localPrime_Integer, label_String,
      imageID_String, tag_String] := Module[
    {columns, request, seconds, run, certificate},
    columns = Dimensions[localMatrix][[2]];
    request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
      localMatrix, ConstantArray[0, Dimensions[localMatrix][[1]]],
      localPrime, Range[columns], makeNonce[label, imageID, tag]];
    If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
      raise["NativeRankRequestInvalid", <|"Variant" -> label,
        "ImageID" -> imageID, "Tag" -> tag|>]];
    {seconds, run} = AbsoluteTiming[
      CodexFLINTAffineRREFAdapter`CFFRRun[nativeBinary, request,
        nativeThreads, False, 600]];
    If[Lookup[run, "Status", None] =!= "VerifiedFLINTAffineRREFRun",
      raise["NativeRankRunFailed", <|"Variant" -> label,
        "ImageID" -> imageID, "Tag" -> tag,
        "MatrixDimensions" -> Dimensions[localMatrix],
        "MatrixFingerprint" ->
          Hash[localMatrix, "SHA256", "HexString"],
        "RequestFingerprint" -> requestFingerprint[request],
        "RequestNonce" -> request["Nonce"],
        "Run" -> KeyDrop[run, {"Certificate"}]|>]];
    certificate = run["Certificate"];
    If[certificate["ParticularSolution"] =!=
          ConstantArray[0, columns] ||
        certificate["Rank"] + certificate["Nullity"] =!= columns,
      raise["NativeRankCertificateInvalid", <|"Variant" -> label,
        "ImageID" -> imageID, "Tag" -> tag|>]];
    <|"Status" -> "VerifiedNativeRankV1",
      "MatrixDimensions" -> Dimensions[localMatrix],
      "Rank" -> certificate["Rank"],
      "Nullity" -> certificate["Nullity"],
      "Seconds" -> seconds,
      "RequestNonce" -> request["Nonce"],
      "RequestFingerprint" -> requestFingerprint[request],
      "PivotFingerprint" -> fingerprint[certificate["PivotColumns"]],
      "FreeColumnFingerprint" ->
        fingerprint[certificate["FreeColumns"]],
      "NullspaceFingerprint" ->
        fingerprint[certificate["NullspaceBasis"]],
      "RowWitnessFingerprint" ->
        fingerprint[certificate["IndependentEquationRows"]]|>
  ];
  rankImage[localMatrix_, localRight_List, localPrime_Integer,
      label_String, imageID_String, tag_String] := Module[
    {rows, columns, rightColumn, augmented, coefficient,
     augmentedResult, consistent},
    {rows, columns} = Dimensions[localMatrix];
    rightColumn = SparseArray[
      MapIndexed[{First[#2], 1} -> #1 &, localRight], {rows, 1}];
    augmented = Join[localMatrix, rightColumn, 2];
    If[Dimensions[augmented] =!= {rows, columns + 1} ||
        ! MatrixQ[augmented, IntegerQ],
      raise["AugmentedMatrixConstructionFailed", <|
        "Variant" -> label, "ImageID" -> imageID, "Tag" -> tag|>]];
    coefficient = nativeRank[localMatrix, localPrime, label, imageID,
      tag <> "-coefficient"];
    augmentedResult = nativeRank[augmented, localPrime, label, imageID,
      tag <> "-augmented"];
    If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
        augmentedResult["Rank"]],
      raise["AugmentedRankRelationInvalid", <|"Variant" -> label,
        "ImageID" -> imageID, "Tag" -> tag,
        "CoefficientRank" -> coefficient["Rank"],
        "AugmentedRank" -> augmentedResult["Rank"]|>]];
    consistent = augmentedResult["Rank"] === coefficient["Rank"];
    <|"Status" -> "CertifiedAffineConsistencyByTwoRanksV1",
      "Tag" -> tag, "Consistent" -> consistent,
      "CoefficientRank" -> coefficient["Rank"],
      "AugmentedRank" -> augmentedResult["Rank"],
      "CoefficientNullity" -> coefficient["Nullity"],
      "CoefficientRankCertificate" -> coefficient,
      "AugmentedRankCertificate" -> augmentedResult|>
  ];

  assembleSharedSamples[localImage_Association, localSeed_Integer] :=
      Module[{labels, pointCounts, maximumPointCount, maximumAttempts,
       fullVariantData, fullPreparation, directSeconds, directSample,
       acceptedPoints, deltaValues, residueCharacters, splitFlags,
       nonsplitPointCount, selectedRows, selectedRight, projectedRows,
       columnMap, pointCount, variantLabel, preparation},
    labels = Lookup[variants, "Label"];
    pointCounts = AssociationThread[labels, Lookup[variants, "PointCount"]];
    maximumPointCount = Max[Values[pointCounts]];
    fullVariantData = variants[[4]];
    fullPreparation = fullVariantData["Preparation"];
    If[fullVariantData["Label"] =!= "ASL" ||
        fullVariantData["PointCount"] =!= maximumPointCount ||
        fullDirectPreparation["SourceABIFingerprint"] =!=
          fullPreparation["ABIFingerprint"],
      Return[$Failed]];
    maximumAttempts = 40 maximumPointCount;
    {directSeconds, directSample} = AbsoluteTiming[
      TimeConstrained[
        CodexDirectRootChannelAssembler`DRCAAssembleSample[
          fullDirectPreparation, localImage["EpsilonValue"],
          localImage["Prime"], "PointCount" -> maximumPointCount,
          "MaximumAttempts" -> maximumAttempts,
          "RandomSeed" -> localSeed, "CandidatePoints" -> Automatic,
          "BranchFlipMask" -> 0], 1800, $Failed]];
    If[! AssociationQ[directSample] ||
        Lookup[directSample, "Status", None] =!=
          "AssembledDirectRootChannelSampleV1" ||
        directSample["ABIFingerprint"] =!=
          fullPreparation["ABIFingerprint"] ||
        directSample["AssemblyFingerprint"] =!=
          fullDirectPreparation["AssemblyFingerprint"] ||
        directSample["Prime"] =!= localImage["Prime"] ||
        directSample["EpsilonValue"] =!= localImage["EpsilonValue"] ||
        directSample["BranchFlipMask"] =!= 0 ||
        directSample["NormalizationCount"] =!= 0 ||
        directSample["RowBasis"] =!= "MultiquadraticGradeBasis" ||
        directSample["MatrixDimensions"] =!=
          {32 maximumPointCount, fullPreparation["UnknownCount"]} ||
        Dimensions[directSample["Matrix"]] =!=
          directSample["MatrixDimensions"] ||
        Length[directSample["RightHandSide"]] =!=
          32 maximumPointCount ||
        Length[directSample["AcceptedPoints"]] =!= maximumPointCount ||
        Length[directSample["PointDeltaValues"]] =!= maximumPointCount,
      Return[$Failed]];
    acceptedPoints = directSample["AcceptedPoints"];
    deltaValues = directSample["PointDeltaValues"];
    residueCharacters = Map[
      JacobiSymbol[#1, localImage["Prime"]] &, deltaValues, {2}];
    If[! AllTrue[residueCharacters,
        Length[#1] === 2 &&
          AllTrue[#1, Function[value, MemberQ[{-1, 1}, value]]] &],
      Return[$Failed]];
    splitFlags = AllTrue[#1, Function[value, value === 1]] & /@
      residueCharacters;
    nonsplitPointCount = Count[splitFlags, False];
    If[nonsplitPointCount < 1, Return[$Failed]];
    AssociateTo[sharedPointStreams,
      localImage["ImageID"] -> <|
        "Seed" -> localSeed,
        "AttemptCount" -> directSample["AttemptCount"],
        "MaximumAttempts" -> maximumAttempts,
        "MaximumPointCount" -> maximumPointCount,
        "AssemblyVariant" -> "ASLDirectRootChannels",
        "PointAcceptancePolicy" ->
          "NonzeroCoordinatesDenominatorsAndRootSquaresNoResidueGate",
        "AcceptedPoints" -> acceptedPoints,
        "PointDeltaValuesFingerprint" -> fingerprint[deltaValues],
        "ResidueCharacterHistogram" -> Counts[residueCharacters],
        "SplitPointCount" -> Count[splitFlags, True],
        "NonsplitPointCount" -> nonsplitPointCount,
        "RejectedPointCount" ->
          Length[directSample["RejectedPoints"]],
        "RejectedReasonHistogram" -> Counts[
          Lookup[directSample["RejectedPoints"], "FailureReason", None]],
        "DirectSampleSeconds" -> directSeconds,
        "DirectSampleTelemetry" -> directSample["Telemetry"]|>];
    Association@Table[
      variantLabel = variantData["Label"];
      preparation = variantData["Preparation"];
      pointCount = pointCounts[variantLabel];
      columnMap = variantColumnMaps[variantLabel];
      selectedRows = Take[directSample["Matrix"], 32 pointCount];
      selectedRight = Take[directSample["RightHandSide"], 32 pointCount];
      projectedRows = selectedRows[[All, columnMap]];
      variantLabel -> <|
        "Status" -> "AssembledSharedDirectPointPrefixSampleV1",
        "ABIFingerprint" -> preparation["ABIFingerprint"],
        "DirectAssemblyFingerprint" ->
          fullDirectPreparation["AssemblyFingerprint"],
        "Prime" -> localImage["Prime"],
        "EpsilonValue" -> localImage["EpsilonValue"],
        "Matrix" -> SparseArray[projectedRows],
        "RightHandSide" -> selectedRight,
        "MatrixDimensions" -> {32 pointCount,
          preparation["UnknownCount"]},
        "AcceptedPoints" -> Take[acceptedPoints, pointCount],
        "PointDeltaValues" -> Take[deltaValues, pointCount],
        "AttemptCount" -> directSample["AttemptCount"],
        "BranchFlipMask" -> 0,
        "NormalizationCount" -> 0,
        "AssemblyVariant" -> "ASLDirectRootChannels",
        "RowBasis" -> "MultiquadraticGradeBasis",
        "ProjectionColumnMapFingerprint" -> fingerprint[columnMap]|>,
      {variantData, variants}]
  ];

  results = AssociationThread[Lookup[variants, "Label"],
    ConstantArray[{}, Length[variants]]];
  Do[
    seed = Hash[{730000 + Mod[image["Prime"], 100000],
      basePreparation["ABIFingerprint"], image["Prime"],
      image["EpsilonValue"]}, "CRC32"];
    Print["CF300S12R2DIRECTDISC milestone=image_assembly_start image=",
      image["ImageID"], " elapsed_s=",
      N[AbsoluteTime[] - campaignStartTime]];
    {sampleSeconds, sharedSamples} = AbsoluteTiming[TimeConstrained[
      assembleSharedSamples[image, seed], 3600, $Failed]];
    If[! AssociationQ[sharedSamples] ||
        Sort[Keys[sharedSamples]] =!= Sort[Lookup[variants, "Label"]],
      raise["SharedPhysicalImageAssemblyLimitOrFailure", <|
        "ImageID" -> image["ImageID"], "Seed" -> seed|>]];
    Print["CF300S12R2DIRECTDISC milestone=image_assembly_complete image=",
      image["ImageID"], " elapsed_s=",
      N[AbsoluteTime[] - campaignStartTime],
      " shared_wrapper_s=", sampleSeconds,
      " direct_sample_s=",
      sharedPointStreams[image["ImageID"]]["DirectSampleSeconds"],
      " attempts=", sharedPointStreams[image["ImageID"]]["AttemptCount"],
      " nonsplit=",
      sharedPointStreams[image["ImageID"]]["NonsplitPointCount"]];
    Print["CF300S12R2DIRECTDISC milestone=image_ranks_start image=",
      image["ImageID"], " elapsed_s=",
      N[AbsoluteTime[] - campaignStartTime]];
    Do[
      variantLabel = variantData["Label"];
      preparation = variantData["Preparation"];
      pointCount = variantData["PointCount"];
      sample = sharedSamples[variantLabel];
      If[! AssociationQ[sample] ||
          Lookup[sample, "Status", None] =!=
            "AssembledSharedDirectPointPrefixSampleV1" ||
          sample["ABIFingerprint"] =!= preparation["ABIFingerprint"] ||
          sample["Prime"] =!= image["Prime"] ||
          sample["EpsilonValue"] =!= image["EpsilonValue"] ||
          sample["BranchFlipMask"] =!= 0 ||
          sample["NormalizationCount"] =!= 0 ||
          sample["DirectAssemblyFingerprint"] =!=
            fullDirectPreparation["AssemblyFingerprint"] ||
          sample["AssemblyVariant"] =!= "ASLDirectRootChannels" ||
          sample["RowBasis"] =!= "MultiquadraticGradeBasis" ||
          sample["ProjectionColumnMapFingerprint"] =!=
            projectionContract[variantLabel][
              "ColumnMapFingerprint"] ||
          sample["MatrixDimensions"] =!=
            {pointCount 32, preparation["UnknownCount"]} ||
          Dimensions[sample["Matrix"]] =!= sample["MatrixDimensions"] ||
          Length[sample["RightHandSide"]] =!= pointCount 32 ||
          Length[sample["AcceptedPoints"]] =!= pointCount ||
          Length[sample["PointDeltaValues"]] =!= pointCount,
        raise["PhysicalImageAssemblyFailed", <|"Variant" -> variantLabel,
          "ImageID" -> image["ImageID"],
          "Assembly" -> KeyDrop[sample, {"Matrix", "RightHandSide"}]|>]];
      matrix = sample["Matrix"];
      right = sample["RightHandSide"];
      imageResult = rankImage[matrix, right, image["Prime"],
        variantLabel, image["ImageID"], "full"];
      nested = If[variantLabel === "A0" && image["ImageID"] === "I00",
        Table[
          If[prefixPointCount === pointCount,
            Join[imageResult, <|"PrefixPointCount" -> prefixPointCount|>],
            nestedMatrix = matrix[[1 ;; 32 prefixPointCount]];
            nestedRight = right[[1 ;; 32 prefixPointCount]];
            Join[rankImage[nestedMatrix, nestedRight,
                image["Prime"], variantLabel, image["ImageID"],
                "prefix-" <>
                  ToString[prefixPointCount]],
              <|"PrefixPointCount" -> prefixPointCount|>]],
          {prefixPointCount, {19, 20, 21}}], {}];
      results[variantLabel] = Append[results[variantLabel],
        Join[image, <|
          "Seed" -> seed,
          "PointCount" -> pointCount,
          "AssemblySeconds" -> sampleSeconds,
          "AttemptCount" -> sample["AttemptCount"],
          "AcceptedPoints" -> sample["AcceptedPoints"],
          "AcceptedPointsFingerprint" ->
            fingerprint[sample["AcceptedPoints"]],
          "MatrixFingerprint" -> Hash[matrix, "SHA256", "HexString"],
          "RightHandSideFingerprint" ->
            Hash[right, "SHA256", "HexString"],
          "FullImageResult" -> imageResult,
          "NestedPrefixResults" -> nested|>]];
      Clear[sample, matrix, right, nestedMatrix, nestedRight],
      {variantData, variants}];
    Print["CF300S12R2DIRECTDISC milestone=image_ranks_complete image=",
      image["ImageID"], " elapsed_s=",
      N[AbsoluteTime[] - campaignStartTime]],
    {image, imageSpecs}];

  Print["CF300S12R2DIRECTDISC milestone=all_images_complete elapsed_s=",
    N[AbsoluteTime[] - campaignStartTime],
    " selected_images=", Lookup[imageSpecs, "ImageID"]];

  currentSourceState[] := <|
    "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
    "Input" -> FileHash[inputFile, "SHA256", "HexString"],
    "PreparationDriver" -> FileHash[preparationDriverFile,
      "SHA256", "HexString"],
    "NamedRuntimeHashes" -> namedRuntimeHashes[],
    "SourceClosure" -> sourceClosureSnapshot[],
    "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
  expectedSourceState = <|
    "Preparation" -> preparationHashBefore,
    "Input" -> expectedInputSHA256,
    "PreparationDriver" -> preparationArtifact["DriverSHA256"],
    "NamedRuntimeHashes" -> namedRuntimeHashesBefore,
    "SourceClosure" -> sourceClosureBefore,
    "Driver" -> driverHashBefore|>;
  sourceStateAtCompletion = currentSourceState[];
  If[sourceStateAtCompletion =!= expectedSourceState,
    raise["SourceChangedBeforeCompletion", <|
      "ExpectedSourceState" -> expectedSourceState,
      "ObservedSourceState" -> sourceStateAtCompletion|>]];

  result = <|
    "Status" -> "CF300Sector12Rank2DirectAnsatzDiscriminatorV1",
    "PreparationFile" -> preparationFile,
    "PreparationSHA256" -> preparationHashBefore,
    "PreparationReadSeconds" -> preparationReadSeconds,
    "PreparationABIValidationSeconds" -> preparationABISeconds,
    "InputFile" -> inputFile,
    "InputSHA256" -> expectedInputSHA256,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore,
    "RuntimeHashes" -> namedRuntimeHashesBefore,
    "NativeThreads" -> nativeThreads,
    "ImageSelector" -> imageSelector,
    "AllImageSpecifications" -> allImageSpecs,
    "SelectedImageSpecifications" -> imageSpecs,
    "PointCountFormula" -> "Max[4,Ceiling[(UnknownCount+32)/32]]",
    "FactorCensus" -> <|
      "RawRationalChannelCount" -> Length[rawChannelExpressions],
      "UniqueRationalChannelCount" -> Length[channelExpressions],
      "RawEpsilonFreeFactorCount" -> Length[rawEpsilonFreeFactors],
      "DeduplicatedEpsilonFreeFactorCount" ->
        Length[irreducibleFactors],
      "FactorDLogCandidateCount" -> Length[newFactorForms],
      "BaseOneFormCount" -> Length[basePreparation["OneForms"]],
      "UnionOneFormCount" -> Length[unionForms],
      "FactorDLogFingerprint" -> fingerprint[
        formKey[#1, roots] & /@ newFactorForms],
      "UnionOneFormFingerprint" -> fingerprint[
        formKey[#1, roots] & /@ unionForms]|>,
    "VariantSummaries" -> (KeyDrop[#1, "Preparation"] & /@ variants),
    "DirectPreparationSeconds" -> directPreparationSeconds,
    "DirectAssemblyFingerprint" ->
      fullDirectPreparation["AssemblyFingerprint"],
    "DirectPrototypeSourceSHA256" ->
      fullDirectPreparation["PrototypeSourceSHA256"],
    "PointAcceptancePolicy" ->
      "DirectNondegeneratePointsIncludingNonsplitImages",
    "SharedPointStreams" -> sharedPointStreams,
    "Results" -> results,
    "ProductionLinearAlgebraBackend" ->
      "PinnedFLINTRanksOfAAndAugmentedMatrix",
    "WolframFieldLinearAlgebraScope" ->
      "ExactChannelCompilationAndRankFourTRFieldInverseOnly",
    "DirectPreparationTimeoutSeconds" -> 1800,
    "DirectSampleTimeoutSecondsPerImage" -> 1800,
    "NativeTimeoutSecondsPerRank" -> 600,
    "GlobalTimeoutSeconds" -> 28800,
    "PreMainElapsedSeconds" -> preMainElapsedSeconds,
    "MainTimeBudgetSeconds" -> mainTimeBudgetSeconds,
    "GlobalMemoryLimitBytes" -> 8 2^30,
    "ExpectedSourceState" -> expectedSourceState,
    "SourceStateAtCompletion" -> sourceStateAtCompletion|>;
  result
], $discriminatorFailureTag], mainTimeBudgetSeconds,
  <|"Status" -> "DiscriminatorGlobalTimeLimit"|>], 8 2^30,
  <|"Status" -> "DiscriminatorGlobalMemoryLimit"|>];

If[! AssociationQ[mainResult],
  finish["DiscriminatorDidNotReturnAssociation", <||>, 97]];
If[Lookup[mainResult, "Status", None] =!=
    "CF300Sector12Rank2DirectAnsatzDiscriminatorV1",
  finish[Lookup[mainResult, "Status", "DiscriminatorFailed"],
    KeyDrop[mainResult, "Status"], 2]];
finalCurrentSourceState[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Input" -> FileHash[inputFile, "SHA256", "HexString"],
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "NamedRuntimeHashes" -> namedRuntimeHashes[],
  "SourceClosure" -> sourceClosureSnapshot[],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
If[writeAtomic[mainResult,
      Function[Null, finalCurrentSourceState[] ===
        mainResult["ExpectedSourceState"]]] ===
    $Failed,
  Print["CF300S12R2DIRECTDISC FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300S12R2DIRECTDISC RESULT status=", mainResult["Status"],
  " output=", outputFile];
Exit[0];
