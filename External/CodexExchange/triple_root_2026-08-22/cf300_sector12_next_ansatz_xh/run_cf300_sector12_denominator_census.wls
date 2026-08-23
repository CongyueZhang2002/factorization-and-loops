#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_DENOM_CENSUS FAIL usage=<project-root> <cache.wl> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
cacheFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
driverDirectory = DirectoryName[$InputFileName];
directDirectory = FileNameJoin[{DirectoryName[driverDirectory],
  "direct_root_channel_assembler_xh"}];
exchangeDirectory = DirectoryName[driverDirectory];
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
    "DirectRootChannelCompiledArtifact.wl"}]|>;
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
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557"|>;
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
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
  Print["CF300_DENOM_CENSUS status=", status,
    " output=", outputFile];
  Exit[code]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[cacheFile] || FileExistsQ[outputFile] ||
    ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300_DENOM_CENSUS FAIL invalid inputs or stale output"];
  Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash,
  Print["CF300_DENOM_CENSUS FAIL pinned source or cache mismatch"];
  Exit[66]];

loadOutcome = Quiet[Check[
  Get[files["LoadFACET"]];
  Get[files["TripleRootAlgebra"]];
  Get[files["TripleRootStripAdapter"]];
  Get[files["TripleRootAffinePilot"]];
  Get[files["TripleRootReconstructionPrototype"]];
  Get[files["Assembler"]];
  Get[files["ArtifactHelper"]];
  True, $Failed]];
If[loadOutcome =!= True || hashes[] =!= sourceHashesBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["PinnedLoadFailed", <||>, 67]];

{cacheReadSeconds, artifact} = AbsoluteTiming[
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile]];
If[! AssociationQ[artifact] ||
    Lookup[artifact, "Status", None] =!=
      "DirectRootChannelCompiledArtifactV1",
  finish["CompiledCacheInvalid", <||>, 68]];
assembly = artifact["DirectAssembly"];
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      assembly],
  finish["DirectAssemblyInvalid", <||>, 69]];
variables = assembly["Variables"];
epsilon = assembly["Regulator"];
If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol],
  finish["VariableContractInvalid", <||>, 70]];
polynomialVariables = Join[{epsilon}, variables];

canonicalPolynomial[polynomial_] := Module[
  {expanded, rules, ordered, pivot, canonical, canonicalRules},
  expanded = Expand[polynomial];
  If[TrueQ[expanded === 0] ||
      ! PolynomialQ[expanded, polynomialVariables] ||
      Complement[DeleteDuplicates[
        Cases[expanded, _Symbol, Infinity]], polynomialVariables] =!= {},
    Return[$Failed]];
  rules = CoefficientRules[expanded, polynomialVariables];
  If[rules === {}, Return[$Failed]];
  ordered = SortBy[rules, First];
  pivot = Last[First[ordered]];
  If[! MatchQ[pivot, _Integer | _Rational] ||
      TrueQ[pivot === 0], Return[$Failed]];
  canonical = Expand[Together[expanded/pivot]];
  If[! PolynomialQ[canonical, polynomialVariables] ||
      Complement[DeleteDuplicates[
        Cases[canonical, _Symbol, Infinity]], polynomialVariables] =!= {},
    Return[$Failed]];
  canonicalRules = SortBy[
    CoefficientRules[canonical, polynomialVariables], First];
  If[canonicalRules === {} ||
      Last[First[canonicalRules]] =!= 1, Return[$Failed]];
  canonical
];
factorRecords[polynomial_] := Module[{factorization, records},
  factorization = Quiet[Check[
    TimeConstrained[MemoryConstrained[
      FactorList[Expand[polynomial]], 2 2^30, $Failed], 240,
      $Failed], $Failed]];
  If[! ListQ[factorization] || factorization === {} ||
      factorization === $Failed, Return[$Failed]];
  records = ({canonicalPolynomial[#[[1]]], #[[2]]} &) /@
    Rest[factorization];
  If[! AllTrue[records,
      ListQ[#] && Length[#] === 2 &&
        PolynomialQ[#[[1]], polynomialVariables] &&
        IntegerQ[#[[2]]] && Positive[#[[2]]] &],
    Return[$Failed]];
  records
];

exact = assembly["ExactChannelForms"];
sourceScalars = Flatten[Table[
  MapIndexed[<|"Source" -> key, "ScalarIndex" -> First[#2],
      "Expression" -> #1|> &,
    Flatten[exact[key]]],
  {key, {"E", "C", "BBar"}}]];
nonzeroScalars = Select[sourceScalars,
  ! TrueQ[Lookup[#, "Expression", 0] === 0] &];
{denominatorSeconds, scalarDenominators} = AbsoluteTiming[
  Table[Module[{rational, denominator, canonical},
    rational = Quiet[Check[Together[record["Expression"]], $Failed]];
    If[rational === $Failed, Return[Join[
      KeyDrop[record, "Expression"], <|
        "Status" -> "TogetherFailed"|>], Module]];
    denominator = Denominator[rational];
    canonical = canonicalPolynomial[denominator];
    If[canonical === $Failed, Return[Join[
      KeyDrop[record, "Expression"], <|
        "Status" -> "CanonicalPolynomialFailed",
        "DenominatorInputFormPrefix" ->
          StringTake[ToString[InputForm[denominator]], UpTo[4096]],
        "PolynomialQ" ->
          PolynomialQ[Expand[denominator], polynomialVariables],
        "ObservedSymbols" -> DeleteDuplicates[
          Cases[denominator, _Symbol, Infinity]]|>],
      Module]];
    Join[KeyDrop[record, "Expression"], <|
      "Status" -> "OK",
      "Denominator" -> canonical,
      "DenominatorFingerprint" -> fingerprint[canonical]|>]],
    {record, nonzeroScalars}]];
scalarDenominatorFailures = Select[scalarDenominators,
  Lookup[#, "Status", None] =!= "OK" &];
If[scalarDenominatorFailures =!= {},
  finish["ChannelDenominatorCanonicalizationFailed", <|
    "FailureCount" -> Length[scalarDenominatorFailures],
    "FailureRecords" -> Take[scalarDenominatorFailures, UpTo[16]]|>, 71]];
denominatorGroups = GatherBy[scalarDenominators,
  Lookup[#, "DenominatorFingerprint"] &];
If[! AllTrue[denominatorGroups,
    Function[group, AllTrue[Rest[group],
      SameQ[#1["Denominator"], First[group]["Denominator"]] &]]],
  finish["ChannelDenominatorFingerprintCollision", <||>, 71]];
uniqueDenominators = First /@ denominatorGroups;

{factorSeconds, denominatorFactorizations} = AbsoluteTiming[
  Association@Table[
    record["DenominatorFingerprint"] ->
      factorRecords[record["Denominator"]],
    {record, uniqueDenominators}]];
If[MemberQ[Values[denominatorFactorizations], $Failed],
  finish["ChannelDenominatorFactorizationFailed", <||>, 72]];

channelFactorOccurrences = Flatten[Table[
  Map[<|"Source" -> record["Source"],
      "ScalarIndex" -> record["ScalarIndex"],
      "Factor" -> #[[1]], "Exponent" -> #[[2]],
      "FactorFingerprint" -> fingerprint[#[[1]]]|> &,
    denominatorFactorizations[record["DenominatorFingerprint"]]],
  {record, scalarDenominators}], 1];
channelFactorGroups = GatherBy[channelFactorOccurrences,
  Lookup[#, "FactorFingerprint"] &];
If[! AllTrue[channelFactorGroups,
    Function[group, AllTrue[Rest[group],
      SameQ[#1["Factor"], First[group]["Factor"]] &]]],
  finish["ChannelFactorFingerprintCollision", <||>, 72]];

gaugeDenominator = assembly["GaugeDenominator"];
gaugeCanonical = canonicalPolynomial[
  Denominator[Together[1/gaugeDenominator]]];
If[gaugeCanonical === $Failed,
  finish["GaugeDenominatorCanonicalizationFailed", <||>, 73]];
gaugeFactors = factorRecords[gaugeCanonical];
If[gaugeFactors === $Failed,
  finish["GaugeDenominatorFactorizationFailed", <||>, 73]];
gaugeFactorRecords = Map[<|"Factor" -> #[[1]],
      "Exponent" -> #[[2]],
      "FactorFingerprint" -> fingerprint[#[[1]]]|> &,
  gaugeFactors];
gaugeFactorGroups = GatherBy[gaugeFactorRecords,
  Lookup[#, "FactorFingerprint"] &];
If[! AllTrue[gaugeFactorGroups,
    Function[group, AllTrue[Rest[group],
      SameQ[#1["Factor"], First[group]["Factor"]] &]]],
  finish["GaugeFactorFingerprintCollision", <||>, 73]];
gaugeExponentByFingerprint = Association@Table[
  First[group]["FactorFingerprint"] -> Max[Lookup[group, "Exponent"]],
  {group, gaugeFactorGroups}];

factorSummary = SortBy[Table[Module[
    {first, factor, factorFingerprint, maxExponent,
     gaugeExponent, sources, simplePoleOnly, sourceExponentMaxima,
     forcingExponent, diagonalExponent, expectedGaugeExponent,
     gaugeExponentDeficit, kinematicQ},
    first = First[group];
    factor = first["Factor"];
    factorFingerprint = first["FactorFingerprint"];
    maxExponent = Max[Lookup[group, "Exponent"]];
    gaugeExponent = Lookup[gaugeExponentByFingerprint,
      factorFingerprint, 0];
    sources = Sort[DeleteDuplicates[Lookup[group, "Source"]]];
    simplePoleOnly = maxExponent === 1;
    sourceExponentMaxima = Association@Table[
      source -> Max[Prepend[
        (Lookup[#, "Exponent", 0] & /@
          Select[group, Lookup[#, "Source", None] === source &]),
        0]],
      {source, {"E", "C", "BBar"}}];
    forcingExponent = sourceExponentMaxima["BBar"];
    diagonalExponent = Max[
      sourceExponentMaxima["E"], sourceExponentMaxima["C"]];
    expectedGaugeExponent = Max[forcingExponent - 1, 0];
    gaugeExponentDeficit = Max[
      expectedGaugeExponent - gaugeExponent, 0];
    kinematicQ = ! FreeQ[factor, Alternatives @@ variables];
    <|"Factor" -> factor,
      "FactorFingerprint" -> factorFingerprint,
      "ChannelMaximumDenominatorExponent" -> maxExponent,
      "SourceMaximumDenominatorExponents" -> sourceExponentMaxima,
      "ForcingMaximumDenominatorExponent" -> forcingExponent,
      "DiagonalMaximumDenominatorExponent" -> diagonalExponent,
      "GaugeDenominatorExponent" -> gaugeExponent,
      "ExpectedMinimalGaugeExponentFromForcing" ->
        expectedGaugeExponent,
      "GaugeExponentDeficit" -> gaugeExponentDeficit,
      "AbsentFromGaugeDenominator" -> (gaugeExponent === 0),
      "SimplePoleOnly" -> simplePoleOnly,
      "ForcingSimplePoleOnly" -> (forcingExponent === 1),
      "OmittedByForcingSimplePoleRule" ->
        (forcingExponent === 1 && gaugeExponent === 0),
      "EpsilonFree" -> FreeQ[factor, epsilon],
      "KinematicsDependent" -> kinematicQ,
      "Sources" -> sources,
      "OccurrenceCount" -> Length[group]|>],
    {group, channelFactorGroups}],
  Lookup[#, "FactorFingerprint"] &];

epsilonFreeSimplePoleCandidates = Select[factorSummary,
  TrueQ[#1["OmittedByForcingSimplePoleRule"]] &&
    TrueQ[#1["EpsilonFree"]] &&
    TrueQ[#1["KinematicsDependent"]] &];
contextualDiagonalSimplePoleCandidates = Select[factorSummary,
  TrueQ[#1["AbsentFromGaugeDenominator"]] &&
    TrueQ[#1["DiagonalMaximumDenominatorExponent"] === 1] &&
    TrueQ[#1["ForcingMaximumDenominatorExponent"] === 0] &&
    TrueQ[#1["EpsilonFree"]] &&
    TrueQ[#1["KinematicsDependent"]] &];
allAbsentCandidates = Select[factorSummary,
  TrueQ[#1["AbsentFromGaugeDenominator"]] &];
gaugeExponentDeficits = Select[factorSummary,
  TrueQ[#1["GaugeExponentDeficit"] > 0] &];
If[gaugeExponentDeficits =!= {},
  finish["GaugeDenominatorMissingRequiredHigherPoleFactor", <|
    "GaugeExponentDeficits" -> gaugeExponentDeficits,
    "FactorSummary" -> factorSummary|>, 74]];
If[epsilonFreeSimplePoleCandidates === {},
  finish["NoOmittedEpsilonFreeForcingSimplePoleCandidates", <|
    "CandidateDefinition" ->
      "epsilon-free kinematic factor with BBar maximum pole order one and gauge exponent zero",
    "ContextualDiagonalSimplePoleCandidates" ->
      contextualDiagonalSimplePoleCandidates,
    "FactorSummary" -> factorSummary|>, 74]];

If[hashes[] =!= sourceHashesBefore ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["SourceOrCacheChangedDuringCensus", <||>, 95]];

finish["CF300Sector12DenominatorCensusPassed", <|
  "CacheFile" -> cacheFile,
  "CacheSHA256" -> expectedCacheHash,
  "CacheReadAndValidationSeconds" -> cacheReadSeconds,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "Variables" -> variables, "Regulator" -> epsilon,
  "GaugeDenominator" -> gaugeDenominator,
  "GaugeDenominatorCanonical" -> gaugeCanonical,
  "GaugeFactorization" -> gaugeFactors,
  "GaugeExponentDeficits" -> gaugeExponentDeficits,
  "NonzeroChannelScalarCount" -> Length[nonzeroScalars],
  "UniqueChannelDenominatorCount" -> Length[uniqueDenominators],
  "DenominatorCanonicalizationSeconds" -> denominatorSeconds,
  "FactorizationSeconds" -> factorSeconds,
  "FactorSummary" -> factorSummary,
  "AllAbsentCandidateCount" -> Length[allAbsentCandidates],
  "AllAbsentCandidates" -> allAbsentCandidates,
  "CandidateDefinition" ->
    "epsilon-free kinematic factor with BBar maximum pole order one and gauge exponent zero",
  "EpsilonFreeSimplePoleCandidateCount" ->
    Length[epsilonFreeSimplePoleCandidates],
  "EpsilonFreeSimplePoleCandidates" ->
    epsilonFreeSimplePoleCandidates,
  "ContextualDiagonalSimplePoleCandidateCount" ->
    Length[contextualDiagonalSimplePoleCandidates],
  "ContextualDiagonalSimplePoleCandidates" ->
    contextualDiagonalSimplePoleCandidates|>, 0];
