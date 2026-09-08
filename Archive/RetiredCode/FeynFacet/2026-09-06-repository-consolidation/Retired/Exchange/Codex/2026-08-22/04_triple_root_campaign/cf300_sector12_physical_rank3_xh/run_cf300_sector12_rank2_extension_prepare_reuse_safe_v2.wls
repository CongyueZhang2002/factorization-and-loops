#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3 || Length[arguments] > 4,
  Print["CF300S12R2PREP FAIL usage=<project-root> <CF300_12_9_input.wl> <output.wl> [unknown-cap]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
parseStrictInteger[text_String] := Module[{digits, negative},
  If[! StringMatchQ[text,
      RegularExpression["0|-?[1-9][0-9]*"]], Return[$Failed]];
  negative = StringStartsQ[text, "-"];
  digits = If[negative, StringDrop[text, 1], text];
  If[negative, -FromDigits[digits], FromDigits[digits]]
];
unknownCap = If[Length[arguments] >= 4,
  parseStrictInteger[arguments[[4]]], 2000];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet",
    "FeynFacet.m"}],
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
  "TripleRootReconstructionPrototype" -> FileNameJoin[{
    exchangeDirectory, "TripleRootReconstructionPrototype.wl"}]|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[inputFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! IntegerQ[unknownCap] || unknownCap < 1 ||
    FileExistsQ[outputFile] || FileExistsQ[outputFile <> ".tmp"],
  Print["CF300S12R2PREP FAIL invalid or stale target"];
  Exit[65]];

inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
loadCertificate = <|"Status" -> "LoadNotStarted"|>;

definitionFingerprint[symbols_List] := Hash[ToString[InputForm[
  ({Context[#1], OwnValues[#1], DownValues[#1], SubValues[#1],
       UpValues[#1]} & /@ symbols)]], "SHA256", "HexString"];
functionDefinitionsPresentQ[symbols_List] :=
  AllTrue[symbols, Length[DownValues[#1]] > 0 &];

SetAttributes[captureMessageTolerantLoad, HoldFirst];
captureMessageTolerantLoad[expression_] := Module[{result, messages},
  Block[{$MessageList = {}},
    result = CheckAbort[Quiet[expression], $Aborted];
    messages = ToString[InputForm[$MessageList]]];
  <|"Status" -> If[result === $Aborted, "LoadAborted",
      "LoadEvaluationCompleted"],
    "ResultHead" -> ToString[InputForm[Head[result]]],
    "Messages" -> messages|>
];

requiredFeynFacetFiles = Values[KeyTake[dependencyFiles, {
  "FeynFacetPublic", "FiniteFieldStripSolve", "FiniteFieldEpsForm",
  "FamilyEpsForm", "TransportCharts"}]];
requiredFeynFacetSymbols = {
  FeynFacet`FamilyArtifactRead, FeynFacet`TransportFamilyChart};
feynFacetRuntimeCertificate[] := Module[
  {runtimeFiles, declaredHash, observedHash, functionsPresent,
   readerDefinitionText, readerContextGuarded, chartProbe,
   sourceDirectory, sourceSealValid},
  runtimeFiles = Quiet[Check[
    FeynFacet`Private`$feynFacetSourceFiles, $Failed]];
  declaredHash = Quiet[Check[
    FeynFacet`Private`$feynFacetSourceHash, $Failed]];
  sourceDirectory = FileNameJoin[{projectRoot, "FeynFacet"}] <>
    $PathnameSeparator;
  observedHash = If[ListQ[runtimeFiles] && runtimeFiles =!= {} &&
      AllTrue[runtimeFiles, StringQ[#1] && FileExistsQ[#1] &],
    Quiet[Check[Hash[FileHash[#1, "SHA256"] & /@ runtimeFiles,
      "SHA256", "HexString"], $Failed]], $Failed];
  functionsPresent =
    functionDefinitionsPresentQ[requiredFeynFacetSymbols];
  readerDefinitionText = If[functionsPresent,
    ToString[InputForm[DownValues[FeynFacet`FamilyArtifactRead]]], ""];
  readerContextGuarded = functionsPresent &&
    StringContainsQ[readerDefinitionText, "$ContextPath"] &&
    StringContainsQ[readerDefinitionText, "System`"] &&
    StringContainsQ[readerDefinitionText, "Global`"];
  chartProbe = If[functionsPresent,
    Quiet[Check[FeynFacet`TransportFamilyChart["CF300"], $Failed]],
    $Failed];
  sourceSealValid = ListQ[runtimeFiles] && runtimeFiles =!= {} &&
    StringQ[declaredHash] && StringQ[observedHash] &&
    declaredHash === observedHash &&
    First[runtimeFiles] === dependencyFiles["FeynFacetPublic"] &&
    Complement[requiredFeynFacetFiles, runtimeFiles] === {} &&
    AllTrue[runtimeFiles,
      StringStartsQ[ExpandFileName[#1], sourceDirectory] &];
  <|"Status" -> If[sourceSealValid && functionsPresent &&
        readerContextGuarded && AssociationQ[chartProbe],
      "ValidatedFeynFacetRuntimeV2", "InvalidFeynFacetRuntimeV2"],
    "RuntimeSourceFiles" -> runtimeFiles,
    "DeclaredRuntimeSourceHash" -> declaredHash,
    "ObservedRuntimeSourceHash" -> observedHash,
    "SourceSealValid" -> sourceSealValid,
    "RequiredDefinitionsPresent" -> functionsPresent,
    "FamilyArtifactReadContextGuarded" -> readerContextGuarded,
    "CF300ChartProbeValid" -> AssociationQ[chartProbe],
    "RequiredDefinitionFingerprint" -> If[functionsPresent,
      definitionFingerprint[requiredFeynFacetSymbols], $Failed]|>
];

requiredTripleRootSymbols = {
  CodexTripleRoot`TRMaskFactor, CodexTripleRoot`TRActiveRank,
  CodexTripleRootStrip`TRCurrentRoots,
  CodexTripleRootStrip`TRFieldCompose,
  CodexTripleRootStrip`TRClassifyStripRecord,
  CodexTripleRootReconstruction`TRStableRootOrder,
  CodexTripleRootReconstruction`TRPrepareReconstruction,
  CodexTripleRootReconstruction`TRPreparationABIValidQ};
tripleRootRuntimeCertificate[] := Module[{present},
  present = functionDefinitionsPresentQ[requiredTripleRootSymbols];
  <|"Status" -> If[present, "ValidatedTripleRootRuntimeV2",
      "InvalidTripleRootRuntimeV2"],
    "RequiredDefinitionsPresent" -> present,
    "RequiredDefinitionFingerprint" -> If[present,
      definitionFingerprint[requiredTripleRootSymbols], $Failed]|>
];

writeAtomic[value_] := Module[{temporary = outputFile <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""], written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
      OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];

finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status, "InputFile" -> inputFile,
    "InputSHA256" -> inputHashBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "LoadCertificate" -> loadCertificate|>,
    data];
  If[writeAtomic[result] === $Failed,
    Print["CF300S12R2PREP FAIL atomic output race output=", outputFile];
    Exit[98]];
  Print["CF300S12R2PREP RESULT status=", status,
    " output=", outputFile];
  Exit[code]
];

feynFacetRuntimeBefore = feynFacetRuntimeCertificate[];
If[Lookup[feynFacetRuntimeBefore, "Status", None] ===
    "ValidatedFeynFacetRuntimeV2",
  feynFacetLoadMode = "ReuseValidatedFeynFacetRuntime";
  feynFacetLoadCapture = <|"Status" -> "SkippedValidatedRuntime",
    "Messages" -> "{}"|>,
  If[Names["FeynCalc`$FeynCalcVersion"] =!= {},
    feynFacetLoadMode = "ReloadFeynFacetPublicWithExistingFeynCalc";
    feynFacetLoadCapture = captureMessageTolerantLoad[
      Get[dependencyFiles["FeynFacetPublic"]]],
    feynFacetLoadMode = "LoadFACETWithLocalizedBasisSymbols";
    feynFacetLoadCapture = captureMessageTolerantLoad[
      Block[{Global`nb, Global`n, Global`xhat, Global`yhat},
        Get[dependencyFiles["LoadFACET"]]]]]];
feynFacetRuntimeAfter = feynFacetRuntimeCertificate[];
If[Lookup[feynFacetRuntimeAfter, "Status", None] =!=
    "ValidatedFeynFacetRuntimeV2" &&
    feynFacetLoadMode === "ReloadFeynFacetPublicWithExistingFeynCalc",
  feynFacetLoadMode =
    "ReloadFeynFacetPublicThenLoadFACETWithLocalizedBasisSymbols";
  feynFacetLoadCapture = <|
    "DirectPublicReload" -> feynFacetLoadCapture,
    "LoadFACETFallback" -> captureMessageTolerantLoad[
      Block[{Global`nb, Global`n, Global`xhat, Global`yhat},
        Get[dependencyFiles["LoadFACET"]]]]|>;
  feynFacetRuntimeAfter = feynFacetRuntimeCertificate[]];

exchangeLoadCapture = captureMessageTolerantLoad[
  Scan[Get, Lookup[dependencyFiles, {
    "TripleRootAlgebra", "TripleRootStripAdapter",
    "TripleRootAffinePilot", "TripleRootReconstructionPrototype"}]]];
tripleRootRuntimeAfter = tripleRootRuntimeCertificate[];
loadCertificate = <|
  "Status" -> "CF300Rank2PreparationRuntimeLoadCertificateV2",
  "FeynFacetLoadMode" -> feynFacetLoadMode,
  "FeynFacetRuntimeBefore" -> feynFacetRuntimeBefore,
  "FeynFacetLoadCapture" -> feynFacetLoadCapture,
  "FeynFacetRuntimeAfter" -> feynFacetRuntimeAfter,
  "TripleRootLoadCapture" -> exchangeLoadCapture,
  "TripleRootRuntimeAfter" -> tripleRootRuntimeAfter|>;
If[Lookup[feynFacetRuntimeAfter, "Status", None] =!=
      "ValidatedFeynFacetRuntimeV2" ||
    Lookup[tripleRootRuntimeAfter, "Status", None] =!=
      "ValidatedTripleRootRuntimeV2",
  finish["RuntimeLoadValidationFailed", <||>, 66]];

dependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashAfterLoad = FileHash[$InputFileName, "SHA256", "HexString"];

If[dependencyHashesAfterLoad =!= dependencyHashesBefore ||
    driverHashAfterLoad =!= driverHashBefore,
  finish["DependencyChangedDuringLoad", <|
    "DependencyHashesAfterLoad" -> dependencyHashesAfterLoad,
    "DriverSHA256AfterLoad" -> driverHashAfterLoad|>, 95]];

zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#1] === 0] &];
canonicalRational[expression_] := Module[{q = Together[expression]},
  {Expand[Numerator[q]], Expand[Denominator[q]]}];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
gradeSupport[channelComponent_List] := Select[
  Range[0, Last[Dimensions[channelComponent]] - 1],
  ! zeroQ[channelComponent[[All, All, All, #1 + 1]]] &];
nonsquarePolynomialQ[polynomial_, variables_List] := Module[{factors},
  If[! PolynomialQ[polynomial, variables] ||
      TrueQ[Expand[polynomial] === 0], Return[False]];
  factors = Rest[FactorList[polynomial]];
  AnyTrue[factors, OddQ[Last[#1]] &]
];
squareClassCertificate[squares_List, variables_List] := Module[
  {masks = Range[1, 2^Length[squares] - 1], products, nonsquare},
  products = Expand[CodexTripleRoot`TRMaskFactor[#1, squares]] & /@
    masks;
  nonsquare = nonsquarePolynomialQ[#1, variables] & /@ products;
  <|"Masks" -> masks, "Products" -> products,
    "Nonsquare" -> nonsquare,
    "Independent" -> AllTrue[nonsquare, TrueQ],
    "Rank" -> If[AllTrue[nonsquare, TrueQ], Length[squares],
      Missing["NotCertified"]]|>
];
localToGlobalGradeMap[sourceIndices_List] := Table[
  localMask -> Sum[
    BitGet[localMask, bit - 1] 2^(sourceIndices[[bit]] - 1),
    {bit, Length[sourceIndices]}],
  {localMask, 0, 2^Length[sourceIndices] - 1}];

mapGlobalChannels[channelStrip_List, sourceIndices_List] := Module[
  {localRank = Length[sourceIndices]},
  Map[Function[globalChannels, Table[
      globalChannels[[1 + Sum[
        BitGet[localMask, bit - 1] 2^(sourceIndices[[bit]] - 1),
        {bit, localRank}]]],
      {localMask, 0, 2^localRank - 1}]], channelStrip, {4}]
];

pureRegulatorDenominatorFactor[channelForcing_, variables_List,
    epsilon_Symbol] := Module[{factorPairs, selected, factors, powers},
  factorPairs = Flatten[Map[Function[entry, Module[
      {denominator = Denominator[Together[entry]]},
      If[TrueQ[denominator === 1], {}, Rest[FactorList[denominator]]]]],
    Flatten[channelForcing]], 1];
  selected = Select[factorPairs,
    FreeQ[First[#1], Alternatives @@ variables] &&
      ! FreeQ[First[#1], epsilon] &];
  If[selected === {}, Return[1]];
  factors = DeleteDuplicates[selected[[All, 1]], SameQ];
  powers = Table[{factor, Max[Cases[selected,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  Together[Times @@ (First[#1]^Last[#1] & /@ powers)]
];

record = FeynFacet`FamilyArtifactRead[inputFile];
inputHashAfterRead = FileHash[inputFile, "SHA256", "HexString"];
If[inputHashAfterRead =!= inputHashBefore,
  finish["InputChangedDuringRead", <|
    "InputSHA256AfterRead" -> inputHashAfterRead|>, 96]];
frame = FeynFacet`TransportFamilyChart["CF300"];
If[! AssociationQ[record] || ! AssociationQ[frame] ||
    Lookup[record, {"Family", "Sector", "LowerSector"}, None] =!=
      {"CF300", 12, 9},
  finish["InvalidPhysicalRank2Input", <||>, 66]];

variables = record["Variables"];
epsilon = record["Regulator"];
sidecar = Lookup[record, "PrecomputedChannelSidecar", $Failed];
globalRoots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
If[! AssociationQ[sidecar] || ! ListQ[globalRoots] ||
    Lookup[sidecar, "Status", None] =!=
      "ExactTermwiseChannelDecomposition" ||
    Lookup[sidecar, "ChannelSidecarVersion", None] =!= 1 ||
    Lookup[sidecar, "ChannelRootSourceOrder", None] =!=
      Range[Length[globalRoots]] ||
    Lookup[sidecar, "RootIndices", None] =!= {2, 3} ||
    Lookup[sidecar, "RootCount", None] =!= 2 ||
    Lookup[sidecar, "ChannelCount", None] =!= 2^Length[globalRoots] ||
    ! TrueQ[Lookup[sidecar, "LeafRoundTripExact", False]],
  finish["InvalidPrecomputedChannelSidecar", <||>, 67]];

channelStrip = Lookup[sidecar, "ChannelStrip", $Failed];
recordStrip = Lookup[record, "Strip", $Failed];
recordStripShapes = If[ListQ[recordStrip], Dimensions /@ recordStrip,
  $Failed];
If[! MatchQ[recordStripShapes,
    {{a_Integer, b_Integer, c_Integer},
     {d_Integer, e_Integer, f_Integer},
     {g_Integer, h_Integer, i_Integer}}] ||
    ! AllTrue[Flatten[recordStripShapes], #1 >= 1 &],
  finish["PhysicalStripShapeInvalid", <|
    "ObservedStripShapes" -> recordStripShapes|>, 68]];
expectedChannelStripShapes =
  Append[#1, 2^Length[globalRoots]] & /@ recordStripShapes;
channelStripShapes = If[ListQ[channelStrip], Dimensions /@ channelStrip,
  $Failed];
If[channelStripShapes =!= expectedChannelStripShapes,
  finish["ChannelStripShapeInvalid", <|
    "ObservedChannelStripShapes" -> channelStripShapes,
    "ExpectedChannelStripShapes" -> expectedChannelStripShapes|>, 68]];
If[
    ! zeroQ[Lookup[sidecar, "ChannelRootSquares", $Failed] -
      Lookup[globalRoots, "RootSquare", $Failed]],
  finish["ChannelSidecarRootABIMismatch", <||>, 68]];

{roundTripSeconds, roundTripQ} = AbsoluteTiming[zeroQ[
  Map[CodexTripleRootStrip`TRFieldCompose[#1, globalRoots] &,
    channelStrip, {4}] - record["Strip"]]];
channelFingerprint = fingerprint[
  Map[canonicalRational, channelStrip, {5}]];
componentSupports = gradeSupport /@ channelStrip;
activeGrades = Union @@ componentSupports;
activeRank = CodexTripleRoot`TRActiveRank[
  activeGrades, Length[globalRoots]];
supportFingerprint = fingerprint[<|
  "ComponentGradeSupport" -> componentSupports,
  "ActiveGrades" -> activeGrades,
  "ActiveGradeRank" -> activeRank|>];
If[! TrueQ[roundTripQ] ||
    channelFingerprint =!= sidecar["ChannelEquationFingerprint"] ||
    supportFingerprint =!= sidecar["SupportFingerprint"] ||
    activeGrades =!= {0, 2, 4} || activeRank =!= 2,
  finish["PrecomputedChannelSidecarCertificateFailed", <|
    "RoundTripExact" -> roundTripQ,
    "ObservedChannelEquationFingerprint" -> channelFingerprint,
    "StoredChannelEquationFingerprint" ->
      sidecar["ChannelEquationFingerprint"],
    "ObservedSupportFingerprint" -> supportFingerprint,
    "StoredSupportFingerprint" -> sidecar["SupportFingerprint"],
    "ActiveGrades" -> activeGrades, "ActiveGradeRank" -> activeRank|>,
    69]];

(* The sidecar is global catalog order {1,2,3}.  The preparation below
   chooses a stable local order for roots {2,3}; perform and certify that
   exact mask projection explicitly before sampling. *)
classification = CodexTripleRootStrip`TRClassifyStripRecord[record, frame];
stableOrder = CodexTripleRootReconstruction`TRStableRootOrder[
  frame, variables, {2, 3}];
If[Lookup[classification, "Status", None] =!= "ExactRootClassification" ||
    classification["RootIndices"] =!= {2, 3} ||
    Lookup[stableOrder, "Status", None] =!= "StableRootOrder",
  finish["Rank2RootClassificationFailed", <|
    "Classification" -> classification, "StableOrder" -> stableOrder|>,
    70]];
sourceIndices = stableOrder["SourceIndices"];
localChannelStrip = mapGlobalChannels[channelStrip, sourceIndices];
localRoots = stableOrder["Roots"];
localSquareClasses = squareClassCertificate[
  Lookup[localRoots, "RootSquare", {}], variables];
If[! zeroQ[Map[CodexTripleRootStrip`TRFieldCompose[#1, localRoots] &,
      localChannelStrip, {4}] - record["Strip"]] ||
    ! TrueQ[localSquareClasses["Independent"]] ||
    localSquareClasses["Rank"] =!= 2,
  finish["StableLocalChannelProjectionFailed", <|
    "RootSourceIndices" -> sourceIndices,
    "SquareClassCertificate" -> localSquareClasses|>, 71]];

regulatorClearFactor = pureRegulatorDenominatorFactor[
  localChannelStrip[[3]], variables, epsilon];
If[regulatorClearFactor === $Failed ||
    TrueQ[Together[regulatorClearFactor] === 0],
  finish["RegulatorClearFactorFailed", <||>, 72]];
scaledRecord = Join[record, <|"Strip" -> ReplacePart[
  record["Strip"], 3 -> Map[Together[regulatorClearFactor #1] &,
    record["Strip"][[3]], {3}]]|>];
remainingPureRegulatorDenominator = pureRegulatorDenominatorFactor[
  Map[Together[regulatorClearFactor #1] &,
    localChannelStrip[[3]], {4}], variables, epsilon];
If[! TrueQ[Together[remainingPureRegulatorDenominator] === 1],
  finish["RegulatorDenominatorClearanceIncomplete", <|
    "RegulatorClearFactor" -> regulatorClearFactor,
    "RemainingFactor" -> remainingPureRegulatorDenominator|>, 73]];

{preparationSeconds, preparation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    scaledRecord, frame]];
If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    preparation["RootCount"] =!= 2 || preparation["GradeCount"] =!= 4 ||
    preparation["RootSourceIndices"] =!= sourceIndices ||
    preparation["Dimensions"] =!= {2, 2} ||
    preparation["Normalizations"] =!= {},
  finish["ScaledRank2PreparationFailed", <|
    "RegulatorClearFactor" -> regulatorClearFactor,
    "PreparationSeconds" -> preparationSeconds,
    "Preparation" -> preparation|>, 74]];
If[preparation["UnknownCount"] > unknownCap,
  finish["Rank2PreparationExceedsUnknownCap", <|
    "UnknownCap" -> unknownCap,
    "RegulatorClearFactor" -> regulatorClearFactor,
    "PreparationSummary" -> KeyTake[preparation, {"RootSourceIndices",
      "Dimensions", "OneFormMetadata", "GaugeDenominator",
      "GaugeDenominatorDegrees", "GaugeSupport", "GaugeUnknownCount",
      "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
      "ABIFingerprint"}]|>, 75]];

result = <|"Status" -> "PreparedCF300Sector12Rank2Extension",
  "InputFile" -> inputFile,
  "InputSHA256" -> inputHashBefore,
  "DriverFile" -> $InputFileName,
  "DriverSHA256" -> driverHashBefore,
  "DependencyHashes" -> dependencyHashesBefore,
  "LoadCertificate" -> loadCertificate,
  "SidecarCertificate" -> <|
    "RoundTripExact" -> roundTripQ,
    "RoundTripSeconds" -> roundTripSeconds,
    "ChannelEquationFingerprint" -> channelFingerprint,
    "SupportFingerprint" -> supportFingerprint,
    "TermGraphFingerprint" -> sidecar["TermGraphFingerprint"],
    "ActiveGrades" -> activeGrades,
    "ActiveGradeRank" -> activeRank,
    "GlobalRootSourceOrder" -> sidecar["ChannelRootSourceOrder"],
    "StableLocalRootSourceOrder" -> sourceIndices,
    "LocalToGlobalGradeMap" -> localToGlobalGradeMap[sourceIndices],
    "LocalSquareClassCertificate" -> localSquareClasses|>,
  "RegulatorClearFactor" -> regulatorClearFactor,
  "PreparationSeconds" -> preparationSeconds,
  "RootOrderingFingerprint" ->
    preparation["RootOrderingFingerprint"],
  "OneFormOrderFingerprint" -> fingerprint[
    preparation["ABIPayload", "OneForms"]],
  "Preparation" -> preparation,
  "PreparationSummary" -> KeyTake[preparation, {"RootCount",
    "GradeCount", "RootSourceIndices", "RootFingerprints",
    "RootOrderingFingerprint", "Dimensions", "OneFormMetadata",
    "GaugeDenominator", "GaugeDenominatorDegrees", "GaugeSupport",
    "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ABIFingerprint"}]|>;
inputHashAtCompletion = FileHash[inputFile, "SHA256", "HexString"];
dependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashAtCompletion = FileHash[$InputFileName,
  "SHA256", "HexString"];
If[inputHashAtCompletion =!= inputHashBefore ||
    dependencyHashesAtCompletion =!= dependencyHashesBefore ||
    driverHashAtCompletion =!= driverHashBefore,
  finish["InputChangedBeforeCompletion", <|
    "InputSHA256AtCompletion" -> inputHashAtCompletion,
    "DependencyHashesAtCompletion" ->
      dependencyHashesAtCompletion,
    "DriverSHA256AtCompletion" -> driverHashAtCompletion|>, 97]];
If[writeAtomic[result] === $Failed,
  Print["CF300S12R2PREP FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300S12R2PREP RESULT status=", result["Status"],
  " roots=", sourceIndices,
  " clear=", InputForm[regulatorClearFactor],
  " support=", Length[preparation["GaugeSupport"]],
  " unknowns=", preparation["UnknownCount"],
  " output=", outputFile];
Exit[0];
