#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300GaloisOrbitForcingDriverV2`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300GaloisOrbitForcingDriverV2`Private`*"]];

cf300GaloisOrbitDriverV2Exit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print["CF300_GALOIS_ORBIT FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <output.wl> [native-threads]"];
  cf300GaloisOrbitDriverV2Exit[64]];

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
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactChannelFormsFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFormsFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
SetAttributes[symbolDefinitionFingerprint, HoldFirst];
symbolDefinitionFingerprint[symbol_] := fingerprint[{
  OwnValues[symbol], DownValues[symbol], UpValues[symbol],
  SubValues[symbol], Attributes[symbol]}];
zeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];
artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
    Quiet[Check[Get[file], $Failed]]]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>
];
stableInputsQ[] := TrueQ[
  hashes[] === sourceHashesBefore &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash &&
  FileHash[$InputFileName, "SHA256", "HexString"] === driverHashBefore];
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
  If[writeAtomic[result] === $Failed,
    Print["CF300_GALOIS_ORBIT FAIL atomic output race output=",
      outputFile]; cf300GaloisOrbitDriverV2Exit[98]];
  Print["CF300_GALOIS_ORBIT status=", status,
    " output=", outputFile];
  cf300GaloisOrbitDriverV2Exit[code]
];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_GALOIS_ORBIT FAIL invalid inputs, stale output, or threads"];
  cf300GaloisOrbitDriverV2Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash,
  Print["CF300_GALOIS_ORBIT FAIL pinned source or artifact mismatch"];
  cf300GaloisOrbitDriverV2Exit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_GALOIS_ORBIT FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  cf300GaloisOrbitDriverV2Exit[67]];

globalHydrationSymbolDiagnosticsBefore = <|
  "Global`x" -> symbolDefinitionFingerprint[Global`x],
  "Global`y" -> symbolDefinitionFingerprint[Global`y],
  "Global`eps" -> symbolDefinitionFingerprint[Global`eps]|>;
canonicalRuntimeContextPath = {
  "CodexDirectRootChannelCompiledArtifact`",
  "CodexDirectRootChannelAssembler`",
  "CodexDirectRootChannelAnsatzRebind`",
  "CodexAffineInconsistencyWitness`",
  "CodexFLINTAffineRREFAdapter`",
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`",
  "System`", "Global`", "CodexCF300GaloisOrbitForcingDriverV2`"};

(* Get resolves unqualified x/y/eps using the dynamic context.  Keep all
   driver symbols private (they were parsed before this Block), while artifact
   hydration, public validation and every downstream fingerprint-sensitive
   call execute in the canonical Global symbol context.  InheritedBlock makes
   clearing same-kernel poison reversible even when Exit is caught by the
   persistent pool wrapper. *)
Internal`InheritedBlock[{Global`x, Global`y, Global`eps},
  Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
  Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
  ClearAll[Global`x, Global`y, Global`eps];
  Block[{$Context = "Global`",
    $ContextPath = canonicalRuntimeContextPath},

preparationArtifact = artifactRead[preparationFile];
rawCacheArtifact = artifactRead[cacheFile];
compiledArtifact =
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile];
hydratedPreparation = If[AssociationQ[preparationArtifact],
  Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
rawAssembly = If[AssociationQ[rawCacheArtifact],
  Lookup[rawCacheArtifact, "DirectAssembly", $Failed], $Failed];
readerAssembly = If[AssociationQ[compiledArtifact],
  Lookup[compiledArtifact, "DirectAssembly", $Failed], $Failed];
readerExactForms = If[AssociationQ[readerAssembly],
  Lookup[readerAssembly, "ExactChannelForms", $Failed], $Failed];
readerCompiledForms = If[AssociationQ[readerAssembly],
  Lookup[readerAssembly, "CompiledForms", $Failed], $Failed];
storedExactFingerprint = If[AssociationQ[readerAssembly],
  Lookup[readerAssembly, "ExactChannelFormsFingerprint", $Failed],
  $Failed];
storedCompiledFingerprint = If[AssociationQ[readerAssembly],
  Lookup[readerAssembly, "CompiledFormsFingerprint", $Failed],
  $Failed];
canonicalExactFingerprint = If[readerExactForms === $Failed,
  $Failed, fingerprint[readerExactForms]];
canonicalCompiledFingerprint = If[readerCompiledForms === $Failed,
  $Failed, fingerprint[readerCompiledForms]];
hydratedVariables = If[AssociationQ[hydratedPreparation],
  Lookup[hydratedPreparation, "Variables", $Failed], $Failed];
hydratedRegulator = If[AssociationQ[hydratedPreparation],
  Lookup[hydratedPreparation, "Regulator", $Failed], $Failed];
hydrationDiagnostics = <|
  "Status" -> "CF300GaloisOrbitCanonicalHydrationV2",
  "RuntimeContext" -> $Context,
  "RuntimeContextPath" -> $ContextPath,
  "GlobalHydrationSymbolDiagnosticsBefore" ->
    globalHydrationSymbolDiagnosticsBefore,
  "CanonicalGlobalSymbolsDefinitionFree" -> And @@ Flatten[
    ({OwnValues[#1], DownValues[#1], UpValues[#1], SubValues[#1]} ===
       {{}, {}, {}, {}} & /@
      {Global`x, Global`y, Global`eps})],
  "PreparationAssociationQ" -> AssociationQ[preparationArtifact],
  "PreparationStatus" -> If[AssociationQ[preparationArtifact],
    Lookup[preparationArtifact, "Status", Missing["Absent"]], $Failed],
  "PreparationValueValidatorCanonical" -> If[
    AssociationQ[hydratedPreparation],
    CodexTripleRootReconstruction`TRPreparationABIValidQ[
      hydratedPreparation], False],
  "PreparationVariableNames" -> If[ListQ[hydratedVariables],
    SymbolName /@ hydratedVariables, $Failed],
  "PreparationVariableContexts" -> If[ListQ[hydratedVariables],
    Context /@ hydratedVariables, $Failed],
  "PreparationRegulatorName" -> If[MatchQ[hydratedRegulator, _Symbol],
    SymbolName[hydratedRegulator], $Failed],
  "PreparationRegulatorContext" -> If[
    MatchQ[hydratedRegulator, _Symbol], Context[hydratedRegulator],
    $Failed],
  "RawCacheAssociationQ" -> AssociationQ[rawCacheArtifact],
  "RawCacheStatus" -> If[AssociationQ[rawCacheArtifact],
    Lookup[rawCacheArtifact, "Status", Missing["Absent"]], $Failed],
  "RawCacheValueValidatorCanonical" -> If[
    AssociationQ[rawCacheArtifact],
    CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      rawCacheArtifact], False],
  "RawAssemblyValueValidatorCanonical" -> If[
    AssociationQ[rawAssembly],
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      rawAssembly], False],
  "RawAndReaderArtifactsValueIdentical" ->
    SameQ[rawCacheArtifact, compiledArtifact],
  "ReaderAssociationQ" -> AssociationQ[compiledArtifact],
  "ReaderStatus" -> If[AssociationQ[compiledArtifact],
    Lookup[compiledArtifact, "Status", Missing["Absent"]],
    compiledArtifact],
  "ReaderArtifactValueValidatorCanonical" -> If[
    AssociationQ[compiledArtifact],
    CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      compiledArtifact], False],
  "ReaderAssemblyValueValidatorCanonical" -> If[
    AssociationQ[readerAssembly],
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      readerAssembly], False],
  "StoredExactChannelFormsFingerprint" -> storedExactFingerprint,
  "CanonicalExactChannelFormsFingerprint" ->
    canonicalExactFingerprint,
  "ExpectedExactChannelFormsFingerprint" ->
    expectedExactChannelFormsFingerprint,
  "ExactFingerprintValueMatch" -> TrueQ[
    storedExactFingerprint === canonicalExactFingerprint ===
      expectedExactChannelFormsFingerprint],
  "StoredCompiledFormsFingerprint" -> storedCompiledFingerprint,
  "CanonicalCompiledFormsFingerprint" ->
    canonicalCompiledFingerprint,
  "ExpectedCompiledFormsFingerprint" ->
    expectedCompiledFormsFingerprint,
  "CompiledFingerprintValueMatch" -> TrueQ[
    storedCompiledFingerprint === canonicalCompiledFingerprint ===
      expectedCompiledFormsFingerprint]|>;
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    ! AssociationQ[compiledArtifact] ||
    Lookup[compiledArtifact, "Status", None] =!=
      "DirectRootChannelCompiledArtifactV1" ||
    ! And @@ Lookup[hydrationDiagnostics, {
      "CanonicalGlobalSymbolsDefinitionFree",
      "PreparationValueValidatorCanonical",
      "RawCacheValueValidatorCanonical",
      "RawAssemblyValueValidatorCanonical",
      "RawAndReaderArtifactsValueIdentical",
      "ReaderArtifactValueValidatorCanonical",
      "ReaderAssemblyValueValidatorCanonical",
      "ExactFingerprintValueMatch",
      "CompiledFingerprintValueMatch"}, False] ||
    Lookup[hydrationDiagnostics, "PreparationVariableNames", $Failed] =!=
      {"x", "y"} ||
    Lookup[hydrationDiagnostics, "PreparationVariableContexts", $Failed] =!=
      {"Global`", "Global`"} ||
    Lookup[hydrationDiagnostics, "PreparationRegulatorName", $Failed] =!=
      "eps" ||
    Lookup[hydrationDiagnostics, "PreparationRegulatorContext", $Failed] =!=
      "Global`",
  finish["PinnedArtifactsOrCanonicalHydrationInvalid", <|
    "HydrationDiagnostics" -> hydrationDiagnostics|>, 68]];
Clear[rawCacheArtifact, rawAssembly, readerExactForms,
  readerCompiledForms];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = compiledArtifact["DirectAssembly"];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly] ||
    baseAssembly["SourceABIFingerprint"] =!=
      basePreparation["ABIFingerprint"],
  finish["BaseABIInvalid", <||>, 69]];

{x, y} = basePreparation["Variables"];
epsilon = basePreparation["Regulator"];
roots = basePreparation["Roots"];
baseOneForms = basePreparation["OneForms"];
baseMetadata = basePreparation["OneFormMetadata"];
baseSupport = basePreparation["GaugeSupport"];
{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
baseGaugeCount = basePreparation["GaugeUnknownCount"];
baseResidueCount = basePreparation["ResidueUnknownCount"];
baseUnknownCount = basePreparation["UnknownCount"];
forcingPair = basePreparation["Record", "Strip"][[3]];
epsilonSamples = {0, 1, -1, 2};
signMasks = Range[0, 3];
If[{Length[roots], gradeCount, upper, lower, Length[baseSupport],
      Length[baseOneForms], baseGaugeCount, baseResidueCount,
      baseUnknownCount} =!= {2, 4, 2, 2, 30, 36, 480, 144, 624} ||
    Lookup[baseMetadata, {"DiagonalCount", "ForcingDLogCandidates",
      "DeduplicatedCount"}, None] =!= {8, 28, 36} ||
    Dimensions[forcingPair] =!= {2, 2, 2},
  finish["PhysicalDimensionOrMetadataContractInvalid", <|
    "ObservedOneFormMetadata" -> baseMetadata,
    "ObservedForcingDimensions" -> Dimensions[forcingPair]|>, 70]];

canonicalRational[expression_] := Module[{q = Together[expression]},
  If[! FreeQ[q,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  {Expand[Numerator[q]], Expand[Denominator[q]]}
];
scalarFieldChannels[expression_] := Module[{channels, canonical},
  channels = CodexTripleRootStrip`TRFieldDecompose[expression, roots];
  If[channels === $Failed ||
      ! zeroQ[CodexTripleRootStrip`TRFieldCompose[
        channels, roots] - expression], Return[$Failed]];
  canonical = canonicalRational /@ channels;
  If[! FreeQ[canonical, $Failed], $Failed, canonical]
];
oneFormChannels[form : {_, _}] := Module[{channels, canonical},
  channels = CodexTripleRootStrip`TRFieldDecompose[#1, roots] & /@ form;
  If[MemberQ[channels, $Failed] ||
      ! zeroQ[MapThread[
        CodexTripleRootStrip`TRFieldCompose[#1, roots] - #2 &,
        {channels, form}]], Return[$Failed]];
  canonical = Map[canonicalRational, channels, {2}];
  If[! FreeQ[canonical, $Failed], $Failed, canonical]
];
oneFormRecord[form : {_, _}] := Module[{channels},
  channels = oneFormChannels[form];
  If[channels === $Failed, Return[$Failed]];
  <|"OneForm" -> form, "CanonicalFieldChannels" -> channels,
    "ChannelFingerprint" -> fingerprint[channels]|>
];
branchSigns[mask_Integer] :=
  Table[If[BitGet[mask, bit - 1] === 0, 1, -1],
    {bit, Length[roots]}];
conjugatePotential[potential_, mask_Integer] :=
  CodexTripleRootStrip`TRApplyRootBranches[
    potential, roots, MapThread[#1 #2["Root"] &,
      {branchSigns[mask], roots}]];

buildPotentialSource[mu_Integer, i_Integer, j_Integer, value_] :=
 Module[{potential, channels},
  potential = Together[forcingPair[[mu, i, j]] /. epsilon -> value];
  If[TrueQ[potential === 0] || FreeQ[potential, x | y],
    Return[Nothing]];
  channels = scalarFieldChannels[potential];
  If[channels === $Failed, Return[$Failed]];
  <|"SourcePotentialID" -> fingerprint[{
      "CF300", 12, 9, mu, i, j, value,
      channels}],
    "DerivativeComponent" -> mu, "Upper" -> i, "Lower" -> j,
    "EpsilonValue" -> value, "SourcePotential" -> potential,
    "SourcePotentialFieldChannels" -> channels,
    "SourcePotentialFingerprint" -> fingerprint[channels]|>
];
potentialSources = Flatten[Table[
  buildPotentialSource[mu, i, j, value],
  {mu, 2}, {i, upper}, {j, lower}, {value, epsilonSamples}]];
If[potentialSources === {} || MemberQ[potentialSources, $Failed] ||
    ! AllTrue[potentialSources, AssociationQ] ||
    ! DuplicateFreeQ[Lookup[potentialSources, "SourcePotentialID"]],
  finish["PotentialSourceCensusFailed", <||>, 71]];

buildConjugateCandidate[source_Association, mask_Integer] := Module[
  {sourcePotential, sourceForm, potential, signs, potentialChannels,
   canonicalPotentialChannels, form, formRecord, involutionExact,
   dlogIdentityExact, orbitDLogExact, closedExact},
  sourcePotential = source["SourcePotential"];
  sourceForm = {Together[D[sourcePotential, x]/sourcePotential],
    Together[D[sourcePotential, y]/sourcePotential]};
  signs = branchSigns[mask];
  potential = Together[conjugatePotential[sourcePotential, mask]];
  involutionExact = zeroQ[
    conjugatePotential[potential, mask] - sourcePotential];
  potentialChannels =
    CodexTripleRootStrip`TRFieldDecompose[potential, roots];
  If[potentialChannels === $Failed ||
      ! zeroQ[CodexTripleRootStrip`TRFieldCompose[
        potentialChannels, roots] - potential], Return[$Failed]];
  canonicalPotentialChannels = canonicalRational /@ potentialChannels;
  If[! FreeQ[canonicalPotentialChannels, $Failed], Return[$Failed]];
  form = {Together[D[potential, x]/potential],
    Together[D[potential, y]/potential]};
  dlogIdentityExact = And @@ MapThread[
    zeroQ[potential #1 - D[potential, #2]] &,
    {form, {x, y}}];
  orbitDLogExact = zeroQ[form -
    (conjugatePotential[#1, mask] & /@ sourceForm)];
  closedExact = zeroQ[D[form[[2]], x] - D[form[[1]], y]];
  formRecord = oneFormRecord[form];
  If[formRecord === $Failed || ! TrueQ[involutionExact] ||
      ! TrueQ[dlogIdentityExact] || ! TrueQ[orbitDLogExact] ||
      ! TrueQ[closedExact],
    Return[$Failed]];
  Join[source, <|"SignMask" -> mask, "BranchSigns" -> signs,
    "ConjugatedPotential" -> potential,
    "ConjugatedPotentialFingerprint" -> fingerprint[
      canonicalPotentialChannels],
    "PotentialFieldChannels" -> canonicalPotentialChannels,
    "InvolutionExact" -> involutionExact,
    "DLogIdentityExact" -> dlogIdentityExact,
    "OrbitDLogExact" -> orbitDLogExact,
    "ClosedOneFormExact" -> closedExact|>, formRecord]
];

{censusSeconds, conjugateCandidates} = AbsoluteTiming[
  Flatten[Table[buildConjugateCandidate[source, mask],
    {source, potentialSources}, {mask, signMasks}]]];
If[MemberQ[conjugateCandidates, $Failed] ||
    Length[conjugateCandidates] =!=
      Length[potentialSources] Length[signMasks] ||
    ! AllTrue[conjugateCandidates,
      TrueQ[#1["InvolutionExact"]] &&
      TrueQ[#1["DLogIdentityExact"]] &&
      TrueQ[#1["OrbitDLogExact"]] &&
      TrueQ[#1["ClosedOneFormExact"]] &],
  finish["ConjugateOrExactDLogCensusFailed", <|
    "PotentialSourceCount" -> Length[potentialSources],
    "CandidateCount" -> Length[conjugateCandidates],
    "CensusSeconds" -> censusSeconds|>, 72]];

candidateGroups = GatherBy[conjugateCandidates,
  Lookup[#1, "ChannelFingerprint"] &];
If[! AllTrue[candidateGroups, Function[group,
    AllTrue[Rest[group],
      SameQ[#1["CanonicalFieldChannels"],
        First[group]["CanonicalFieldChannels"]] &]]],
  finish["ForcingChannelFingerprintCollision", <||>, 73]];
forcingLetterRecords = MapIndexed[Function[{group, index},
  <|"ForcingLetterIndex" -> First[index],
    "ChannelFingerprint" -> First[group]["ChannelFingerprint"],
    "OneForm" -> First[group]["OneForm"],
    "CanonicalFieldChannels" ->
      First[group]["CanonicalFieldChannels"],
    "ProvenanceCount" -> Length[group],
    "Provenance" -> KeyDrop[#1, {"OneForm",
        "CanonicalFieldChannels"}] & /@ group|>], candidateGroups];

baseFormRecords = oneFormRecord /@ baseOneForms;
If[MemberQ[baseFormRecords, $Failed],
  finish["BaseOneFormChannelCanonicalizationFailed", <||>, 74]];
baseFingerprints = Lookup[baseFormRecords, "ChannelFingerprint"];
If[! DuplicateFreeQ[baseFingerprints],
  finish["BaseOneFormsNotChannelDistinct", <||>, 74]];
diagonalForms = CodexTripleRootStrip`TRDiagonalOneFormBasis[
  basePreparation["Record", "Strip"], roots, {x, y}];
If[Length[diagonalForms] =!= 8 ||
    diagonalForms =!= Take[baseOneForms, 8],
  finish["DiagonalPrefixContractInvalid", <|
    "ObservedDiagonalCount" -> Length[diagonalForms]|>, 74]];

identityForcingFingerprints = DeleteDuplicates[Lookup[
  Select[conjugateCandidates, #1["SignMask"] === 0 &],
  "ChannelFingerprint"]];
If[Sort[identityForcingFingerprints] =!=
    Sort[Drop[baseFingerprints, 8]],
  finish["IdentityForcingBasisDoesNotRecoverBaseSuffix", <|
    "IdentityForcingCount" -> Length[identityForcingFingerprints],
    "BaseForcingSuffixCount" -> Length[Drop[baseFingerprints, 8]]|>,
    75]];

additionalLetterRecords = Select[forcingLetterRecords,
  ! MemberQ[baseFingerprints, #1["ChannelFingerprint"]] &];
maxOneForms = Join[baseOneForms,
  Lookup[additionalLetterRecords, "OneForm"]];
If[Length[forcingLetterRecords] > 112 || Length[maxOneForms] > 120 ||
    Length[additionalLetterRecords] > 84,
  finish["Rank2OrbitCardinalityBoundViolated", <|
    "ForcingLetterCount" -> Length[forcingLetterRecords],
    "MaximalOneFormCount" -> Length[maxOneForms],
    "AppendedOrbitLetterCount" -> Length[additionalLetterRecords]|>,
    76]];
maxFormRecords = oneFormRecord /@ maxOneForms;
If[MemberQ[maxFormRecords, $Failed],
  finish["MaximalOrbitBasisConstructionFailed", <||>, 76]];
maxFingerprints = Lookup[maxFormRecords, "ChannelFingerprint"];
If[
    ! DuplicateFreeQ[maxFingerprints] ||
    Take[maxOneForms, Length[baseOneForms]] =!= baseOneForms ||
    Sort[Union[baseFingerprints,
      Lookup[forcingLetterRecords, "ChannelFingerprint"]]] =!=
      Sort[maxFingerprints],
  finish["MaximalOrbitBasisConstructionFailed", <||>, 76]];

sourceOrbitRecords = Table[Module[{members, masks, memberKeys},
  members = Select[conjugateCandidates,
    #1["SourcePotentialID"] === source["SourcePotentialID"] &];
  masks = Sort[Lookup[members, "SignMask"]];
  memberKeys = Association@Table[
    member["SignMask"] -> member["ChannelFingerprint"],
    {member, members}];
  <|"SourcePotentialID" -> source["SourcePotentialID"],
    "DerivativeComponent" -> source["DerivativeComponent"],
    "Upper" -> source["Upper"], "Lower" -> source["Lower"],
    "EpsilonValue" -> source["EpsilonValue"],
    "SourcePotential" -> source["SourcePotential"],
    "ObservedSignMasks" -> masks,
    "LetterFingerprintBySignMask" -> memberKeys,
    "KleinFourCompositionExact" -> And @@ Flatten[Table[
      zeroQ[conjugatePotential[
          conjugatePotential[source["SourcePotential"], left], right] -
        conjugatePotential[source["SourcePotential"],
          BitXor[left, right]]],
      {left, signMasks}, {right, signMasks}]],
    "OrbitSizeAfterDLogDeduplication" ->
      Length[DeleteDuplicates[Values[memberKeys]]]|>
  ], {source, potentialSources}];
orbitClosureExact = AllTrue[sourceOrbitRecords,
  #1["ObservedSignMasks"] === signMasks &&
  TrueQ[#1["KleinFourCompositionExact"]] &&
  Complement[Values[#1["LetterFingerprintBySignMask"]],
    maxFingerprints] === {} &];
If[! TrueQ[orbitClosureExact],
  finish["GaloisOrbitClosureFailed", <|
    "SourceOrbitRecords" -> sourceOrbitRecords|>, 77]];

gaugeCount = baseGaugeCount;
residueCount = Length[maxOneForms] upper lower;
unknownCount = gaugeCount + residueCount;
payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
  basePreparation["Record"], roots, basePreparation["Variables"],
  epsilon, basePreparation["Dimensions"],
  basePreparation["GaugeDenominator"], baseSupport, maxOneForms,
  basePreparation["Normalizations"]];
If[payload === $Failed,
  finish["MaximalOrbitABIPayloadFailed", <||>, 78]];
maxPreparation = Join[basePreparation, <|
  "OneForms" -> maxOneForms,
  "OneFormMetadata" -> <|
    "Status" -> "CF300GaloisOrbitClosedForcingBasisV2",
    "BaseOneFormCount" -> Length[baseOneForms],
    "PotentialSourceCount" -> Length[potentialSources],
    "ConjugateCandidateCount" -> Length[conjugateCandidates],
    "DeduplicatedForcingLetterCount" -> Length[forcingLetterRecords],
    "AppendedOrbitLetterCount" -> Length[additionalLetterRecords],
    "GaloisSignMasks" -> signMasks,
    "EpsilonSamples" -> epsilonSamples|>,
  "ResidueUnknownCount" -> residueCount,
  "UnknownCount" -> unknownCount,
  "ABIPayload" -> payload,
  "ABIFingerprint" -> fingerprint[payload]|>];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      maxPreparation],
  finish["MaximalOrbitPreparationInvalid", <||>, 78]];

{rebindSeconds, maxAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, maxPreparation]];
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      maxAssembly] ||
    maxAssembly["SourceABIFingerprint"] =!=
      maxPreparation["ABIFingerprint"] ||
    Take[maxAssembly["OneForms"], Length[baseOneForms]] =!=
      baseOneForms,
  finish["MaximalOrbitAnsatzRebindInvalid", <|
    "RebindStatus" -> Lookup[maxAssembly, "Status", None],
    "RebindSeconds" -> rebindSeconds|>, 79]];

pointCount = Max[21, Ceiling[(unknownCount + 32)/32]];
If[unknownCount > 960 || pointCount > 31,
  finish["Rank2OrbitUnknownBoundViolated", <|
    "UnknownCount" -> unknownCount, "PointCount" -> pointCount|>,
    79]];
Print["CF300_GALOIS_ORBIT milestone=target_ready census_s=",
  censusSeconds, " rebind_s=", rebindSeconds,
  " sources=", Length[potentialSources],
  " forcing_letters=", Length[forcingLetterRecords],
  " appended=", Length[additionalLetterRecords],
  " unknowns=", unknownCount, " points=", pointCount];

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
nativeRank[localMatrix_?MatrixQ, prime_Integer, label_String,
    imageID_String, tag_String] := Module[
  {rows, columns, request, seconds, run, certificate, rank, nullity,
   diagnosticSeconds, diagnosticRun},
  {rows, columns} = Dimensions[localMatrix];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    localMatrix, ConstantArray[0, rows], prime, Range[columns],
    makeNonce[label, imageID, tag]];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    Return[nativeRankFailure["NativeRankRequestFailed", <|
      "RequestStatus" -> Lookup[request, "Status", None]|>]]];
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
        ConstantArray[0, columns] || rank + nullity =!= columns ||
      ! canonicalVectorQ[certificate["ParticularSolution"], columns,
        prime] ||
      ! canonicalMatrixQ[certificate["NullspaceBasis"], nullity,
        columns, prime],
    Return[nativeRankFailure[
      "NativeRankCertificatePostconditionFailed", <|
        "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
        "Nullity" -> nullity, "Seconds" -> seconds|>]]];
  <|"Status" -> "VerifiedNativeRankV1",
    "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
    "Nullity" -> nullity, "Seconds" -> seconds,
    "PivotFingerprint" -> fingerprint[certificate["PivotColumns"]],
    "FreeColumnFingerprint" -> fingerprint[certificate["FreeColumns"]],
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
  If[Lookup[augmentedRank, "Status", None] =!=
      "VerifiedNativeRankV1",
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
imageResults = Table[Module[
  {prime, epsilonValue, seed, sampleSeconds, targetSample,
   screenPoints, targetScreenMatrix, targetScreenRight, baseSample,
   witness, newColumns, score, fullRank, imageInconsistent},
  prime = image["Prime"];
  epsilonValue = image["EpsilonValue"];
  seed = Hash[{2026082331, "GaloisOrbitForcingV2",
    image["ImageID"], maxPreparation["ABIFingerprint"]}, "CRC32"];
  {sampleSeconds, targetSample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCAAssembleSample[
      maxAssembly, epsilonValue, prime,
      "PointCount" -> pointCount,
      "MaximumAttempts" -> 40 pointCount,
      "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
      "BranchFlipMask" -> 0]];
  If[Lookup[targetSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      targetSample["MatrixDimensions"] =!=
        {32 pointCount, unknownCount},
    finish["TargetSampleFailed", <|"Image" -> image,
      "SampleStatus" -> Lookup[targetSample, "Status", None]|>, 80]];
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
      baseSample["RightHandSide"] =!= targetScreenRight ||
      Take[targetScreenMatrix, All, baseUnknownCount] =!=
        baseSample["Matrix"],
    finish["BasePureSubsetContainmentFailed", <|"Image" -> image|>,
      81]];
  witness = CodexAffineInconsistencyWitness`AIWConstruct[
    SparseArray[baseSample["Matrix"]], baseSample["RightHandSide"],
    prime, files["NativeAdapter"], files["NativeBinary"],
    nativeThreads,
    makeNonce["GaloisOrbitForcingV2", image["ImageID"],
      "left-witness"]];
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    finish["BaseLeftWitnessFailed", <|"Image" -> image,
      "WitnessStatus" -> Lookup[witness, "Status", None],
      "WitnessFailure" -> KeyDrop[witness, "Witness"]|>, 82]];
  newColumns = targetScreenMatrix[[All,
    baseUnknownCount + 1 ;; unknownCount]];
  score = CodexAffineInconsistencyWitness`AIWScoreColumns[
    witness, SparseArray[newColumns]];
  If[Lookup[score, "Status", None] =!=
      "AffineWitnessCandidateColumnScoreV1",
    finish["OrbitColumnWitnessScoreFailed", <|"Image" -> image|>,
      83]];
  fullRank = If[TrueQ[score["AllScoresZero"]],
    Missing["RejectedByBaseLeftWitness"],
    rankImage[targetSample["Matrix"],
      targetSample["RightHandSide"], prime,
      "GaloisOrbitForcingV2", image["ImageID"]]];
  If[! MissingQ[fullRank] &&
      Lookup[fullRank, "Status", None] =!=
        "CertifiedAffineConsistencyByTwoRanksV1",
    finish["MaximalOrbitFullRankFailed", <|"Image" -> image,
      "RankFailure" -> fullRank|>, 84]];
  imageInconsistent = If[MissingQ[fullRank], True,
    ! TrueQ[fullRank["Consistent"]]];
  Print["CF300_GALOIS_ORBIT milestone=image_complete image=",
    image["ImageID"], " score_nonzero=", score["NonzeroScoreCount"],
    " inconsistent=", imageInconsistent];
  Join[image, <|"PointCount" -> pointCount,
    "AttemptCount" -> targetSample["AttemptCount"],
    "AcceptedPointsFingerprint" ->
      fingerprint[targetSample["AcceptedPoints"]],
    "SampleSeconds" -> sampleSeconds,
    "MatrixFingerprint" ->
      Hash[targetSample["Matrix"], "SHA256", "HexString"],
    "RightHandSideFingerprint" ->
      Hash[targetSample["RightHandSide"], "SHA256", "HexString"],
    "BaseColumnPrefixContainedExactly" -> True,
    "BaseWitness" -> KeyDrop[witness, "Witness"],
    "AppendedOrbitColumnWitnessScore" -> score,
    "FullRank" -> fullRank,
    "MaximalOrbitAnsatzInconsistentAtImage" -> imageInconsistent|>]
  ], {image, images}];

If[! stableInputsQ[],
  finish["SourceOrArtifactChangedDuringScreen", <||>, 95]];

finish["CF300Sector12GaloisOrbitForcingScreenPassedV2", <|
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "CanonicalHydrationDiagnostics" -> hydrationDiagnostics,
  "CensusSeconds" -> censusSeconds,
  "RebindSeconds" -> rebindSeconds,
  "EpsilonSamples" -> epsilonSamples,
  "GaloisSignMasks" -> signMasks,
  "PotentialSourceCount" -> Length[potentialSources],
  "ConjugateCandidateCount" -> Length[conjugateCandidates],
  "DeduplicatedForcingLetterCount" -> Length[forcingLetterRecords],
  "BaseOneFormCount" -> Length[baseOneForms],
  "AppendedOrbitLetterCount" -> Length[additionalLetterRecords],
  "MaximalOneFormCount" -> Length[maxOneForms],
  "MaximalUnknownCount" -> unknownCount,
  "PointCount" -> pointCount,
  "ExactPotentialAndDLogProvenance" -> forcingLetterRecords,
  "SourcePotentialGaloisOrbits" -> sourceOrbitRecords,
  "OrbitClosureExact" -> orbitClosureExact,
  "MaximalPreparationSummary" -> KeyTake[maxPreparation, {
    "RootSourceIndices", "OneFormMetadata", "GaugeDenominator",
    "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
    "UnknownCount", "ABIFingerprint"}],
  "MaximalAssemblyFingerprint" -> maxAssembly["AssemblyFingerprint"],
  "ImageSpecifications" -> images,
  "ImageResults" -> imageResults,
  "EveryImageRejectsMaximalOrbitAnsatz" -> AllTrue[imageResults,
    TrueQ[#1["MaximalOrbitAnsatzInconsistentAtImage"]] &],
  "SubsetEmbeddingCertificate" -> <|
    "Status" -> "ExactColumnSubsetEmbeddingV2",
    "BaseOneFormsArePrefix" -> True,
    "GaugeColumnsUnchanged" -> True,
    "EachAppendedLetterOccupiesResidueColumns" -> upper lower,
    "MaximalRejectsEveryLetterSubsetAtAnInconsistentImage" -> True,
    "Scope" ->
      "subsets of the four-sign closure of forcing-entry dlogs at epsilon samples {0,1,-1,2}",
    "Qualification" ->
      "finite-field image rejection is not by itself a lifted characteristic-zero obstruction certificate"|>|>,
  0]]];
