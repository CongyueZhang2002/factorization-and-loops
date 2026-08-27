BeginPackage["CodexDirectRootChannelExactOneFormRebindV6e`", {
  "CodexDirectRootChannelAssembler`",
  "CodexTripleRootReconstruction`",
  "CodexTripleRootStrip`"}];

DRCARebindExactOneFormRecordsV6e::usage =
  "DRCARebindExactOneFormRecordsV6e[assembly,target,records] performs a timed one-form-only rebind from source-certified exact channel records. It collision-checks and memoizes canonical rational leaves, constructs a specialized suffix seal, and retains exactly one legacy whole-result validation oracle.";
DRCAExactOneFormRebindSealValidQ::usage =
  "DRCAExactOneFormRebindSealValidQ[assembly,target,result,seal] validates a V6e exact one-form suffix seal without consuming its nonce.";
DRCAConsumeExactOneFormRebindSealV6e::usage =
  "DRCAConsumeExactOneFormRebindSealV6e[assembly,target,result,seal] validates and consumes a V6e seal nonce exactly once in this kernel.";
DRCAClearExactOneFormRebindSealNoncesV6e::usage =
  "DRCAClearExactOneFormRebindSealNoncesV6e[] clears only the private V6e consumed-nonce registry.";

Begin["`Private`"];

ClearAll[
  drceFailure, drceFingerprintData, drceFingerprint, drceSourceHash,
  drceSourceStableQ, drceFormShape, drceColumnOrder,
  drceSemanticPayload, drceCoreCompatibleQ, drceExactCoefficientQ,
  drceCanonicalPairValidQ, drceCompileCanonicalPair,
  drceRecordShapeValidQ, drceMeasure, drceSealPayload,
  drceSpecializedSealValidQ, DRCARebindExactOneFormRecordsV6e,
  DRCAExactOneFormRebindSealValidQ,
  DRCAConsumeExactOneFormRebindSealV6e,
  DRCAClearExactOneFormRebindSealNoncesV6e
];

$drceExpectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";
$drceSourceFile = ExpandFileName[$InputFileName];
$drceSourceSHA256 = FileHash[$drceSourceFile, "SHA256", "HexString"];
$drceMaximumEpsilonDegree = 256;
$drceConsumedNonces = <||>;

$drceSemanticKeys = {
  "SourceABIFingerprint", "RootOrderingFingerprint", "RootCount",
  "GradeCount", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "SourceSemanticFingerprint", "PrototypeSourceSHA256"};

$drceEquationCoreKeys = {
  "E", "C", "BBar", "RootSquares", "RootLogDerivatives",
  "GaugeDenominator", "GaugeLogDerivatives"};

$drcePreparationCoreKeys = {
  "Record", "Roots", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "GaugeSupport", "GaugeDenominator",
  "Normalizations", "GaugeUnknownCount", "EquationsPerPoint",
  "RootOrderingFingerprint"};

$drceResultChangedKeys = {
  "SourceABIFingerprint", "OneForms", "ResidueUnknownCount",
  "UnknownCount", "ColumnOrder", "ExactChannelForms", "CompiledForms",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "AssemblyFingerprint",
  "ExactOneFormChannelRebindV6e", "ExactOneFormChannelRebindSealV6e"};

$drceCertificateKeys = {
  "BaseValidatedOnce", "TargetValidatedOnce", "SourceStable",
  "FingerprintCollisionFree", "CanonicalPairsValid",
  "CanonicalPairsMatchChannels", "RecordChannelFingerprintsExact",
  "RawUniqueCacheConservationExact",
  "DeterministicLegacyCompilerAuditExact",
  "EquationCorePreservedExactly", "LegacyWholeResultOraclePassed"};

drceFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "DirectRootChannelExactOneFormRebindV6eFailure",
    "FailureReason" -> reason|>, data];

drceFingerprintData[value_] := Module[{serialized},
  serialized = ToString[InputForm[value]];
  <|"Fingerprint" -> Hash[serialized, "SHA256", "HexString"],
    "InputFormCharacterCount" -> StringLength[serialized]|>
];

drceFingerprint[value_] := drceFingerprintData[value]["Fingerprint"];

drceSourceHash[file_] := If[StringQ[file] && FileExistsQ[file],
  Quiet[Check[FileHash[file, "SHA256", "HexString"], $Failed]], $Failed];

drceSourceStableQ[] := TrueQ[
  drceSourceHash[$drceSourceFile] === $drceSourceSHA256];

drceFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{
      "DRCARationalExactV1", "DRCARationalPrimeV1",
      "DRCARationalImageV1"}, Lookup[expression, "Type", None]],
    "DRCARationalLeaf",
  AssociationQ[expression], Map[drceFormShape, expression],
  ListQ[expression], drceFormShape /@ expression,
  True, "Scalar"];

drceColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

drceSemanticPayload[assembly_Association] :=
  KeyTake[assembly, $drceSemanticKeys];

drceCoreCompatibleQ[assembly_Association, target_Association] :=
  TrueQ[And @@ (SameQ[Lookup[assembly, #1, $Failed],
      Lookup[target, #1, $Failed]] & /@ $drcePreparationCoreKeys)];

drceExactCoefficientQ[value_] :=
  IntegerQ[value] || Head[value] === Rational;

(* The pair must be the reduced canonical pair produced by Together, not only
   an arbitrary proportional numerator and denominator.  This makes scaled,
   sign-flipped, and stale-pair mutants fail closed. *)
drceCanonicalPairValidQ[pair_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {numerator, denominator, vars, numeratorRules, denominatorRules,
   epsilonDegrees, rational},
  If[! MatchQ[pair, {_, _}], Return[False]];
  {numerator, denominator} = pair;
  vars = Append[variables, epsilon];
  If[denominator === 0 ||
      ! FreeQ[pair,
        Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
      ! PolynomialQ[numerator, vars] || ! PolynomialQ[denominator, vars] ||
      ! SameQ[Expand[numerator], numerator] ||
      ! SameQ[Expand[denominator], denominator], Return[False]];
  numeratorRules = CoefficientRules[numerator, vars];
  denominatorRules = CoefficientRules[denominator, vars];
  If[! AllTrue[Join[Last /@ numeratorRules, Last /@ denominatorRules],
      drceExactCoefficientQ], Return[False]];
  epsilonDegrees = Last[First[#1]] & /@ Join[
    numeratorRules, denominatorRules];
  If[Max[Prepend[epsilonDegrees, 0]] > $drceMaximumEpsilonDegree,
    Return[False]];
  rational = Together[numerator/denominator];
  TrueQ[Expand[Numerator[rational]] === numerator &&
    Expand[Denominator[rational]] === denominator]
];

(* Source-pinned fast compiler.  The public helper pins the exact assembler
   source before reaching this routine, and this routine deliberately skips
   drcaCompileRational's Together/canonicalization pass. *)
drceCompileCanonicalPair[pair : {_, _},
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {numerator, denominator},
  numerator =
    CodexDirectRootChannelAssembler`Private`drcaCompilePolynomial[
      pair[[1]], variables, epsilon];
  denominator =
    CodexDirectRootChannelAssembler`Private`drcaCompilePolynomial[
      pair[[2]], variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      ! AssociationQ[numerator] || ! AssociationQ[denominator] ||
      Lookup[numerator, "Type", None] =!= "DRCAPolynomialExactV1" ||
      Lookup[denominator, "Type", None] =!= "DRCAPolynomialExactV1" ||
      Lookup[denominator, "EpsilonCoefficientRows", {}] === {},
    $Failed,
    <|"Type" -> "DRCARationalExactV1", "Numerator" -> numerator,
      "Denominator" -> denominator|>]
];
drceCompileCanonicalPair[___] := $Failed;

drceRecordShapeValidQ[record_Association] := AllTrue[{
  "OneForm", "OneFormChannels", "CanonicalFieldChannels",
  "ChannelFingerprint"}, KeyExistsQ[record, #1] &];
drceRecordShapeValidQ[_] := False;

SetAttributes[drceMeasure, HoldAll];
drceMeasure[label_String, expression_, timings_Symbol,
    memory_Symbol] := Module[{before, after, seconds, value},
  before = MemoryInUse[];
  {seconds, value} = AbsoluteTiming[expression];
  after = MemoryInUse[];
  AssociateTo[timings, label -> N[seconds]];
  AssociateTo[memory, label -> <|"BeforeBytes" -> before,
    "AfterBytes" -> after, "DeltaBytes" -> after - before|>];
  value
];

drceSealPayload[seal_Association] := KeyDrop[seal, "SealFingerprint"];

drceSpecializedSealValidQ[assembly_Association, target_Association,
    result_Association, seal_Association] := Module[
  {baseCount, suffixCount, gradeCount, dimensions, support,
   sourceFile, sourceHash, exactPrefix, compiledPrefix, exactSuffix,
   compiledSuffix, canonicalPairs, changedKeysExact, expectedGauge,
   expectedResidue, expectedUnknown, expectedColumnOrder,
   sourceHashesNow, booleanCertificates},
  If[Lookup[seal, "Status", None] =!=
      "ExactOneFormRebindSpecializedSealV6e" ||
      ! StringQ[Lookup[seal, "Nonce", None]] ||
      StringLength[seal["Nonce"]] < 8 ||
      ! StringQ[Lookup[seal, "SealFingerprint", None]] ||
      drceFingerprint[drceSealPayload[seal]] =!= seal["SealFingerprint"],
    Return[False]];
  baseCount = Length[Lookup[assembly, "OneForms", {}]];
  suffixCount = Length[Lookup[target, "OneForms", {}]] - baseCount;
  gradeCount = Lookup[assembly, "GradeCount", $Failed];
  dimensions = Lookup[assembly, "Dimensions", $Failed];
  support = Lookup[assembly, "GaugeSupport", $Failed];
  sourceFile = Lookup[assembly, "PrototypeSourceFile", $Failed];
  sourceHash = drceSourceHash[sourceFile];
  If[suffixCount < 1 || ! IntegerQ[gradeCount] ||
      ! MatchQ[dimensions, {_Integer, _Integer}] || ! ListQ[support],
    Return[False]];
  exactPrefix = Take[result["ExactChannelForms", "OneForms"], baseCount];
  compiledPrefix = Take[result["CompiledForms", "OneForms"], baseCount];
  exactSuffix = Drop[result["ExactChannelForms", "OneForms"], baseCount];
  compiledSuffix = Drop[result["CompiledForms", "OneForms"], baseCount];
  canonicalPairs = Lookup[seal, "CanonicalSuffixPairs", $Failed];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[target["OneForms"]] Times @@ dimensions;
  expectedUnknown = expectedGauge + expectedResidue;
  expectedColumnOrder = drceColumnOrder[dimensions, gradeCount, support,
    Length[target["OneForms"]]];
  changedKeysExact = TrueQ[
    KeyDrop[result, $drceResultChangedKeys] ===
      KeyDrop[assembly, $drceResultChangedKeys]];
  sourceHashesNow = <|"Assembler" -> sourceHash,
    "RebindV6e" -> drceSourceHash[$drceSourceFile]|>;
  booleanCertificates = Lookup[seal, "Certificates", <||>];
  TrueQ[
    changedKeysExact &&
    drceCoreCompatibleQ[assembly, target] &&
    sourceHash === $drceExpectedAssemblerSHA256 &&
    sourceHash === assembly["PrototypeSourceSHA256"] &&
    sourceHashesNow === seal["SourceHashesAfterConstruction"] &&
    seal["SourceHashesBeforeConstruction"] ===
      seal["SourceHashesAfterConstruction"] &&
    seal["AssemblerSourceSHA256"] === sourceHash &&
    seal["ValidatorSourceSHA256"] === $drceSourceSHA256 &&
    seal["BaseAssemblyFingerprint"] ===
      assembly["AssemblyFingerprint"] &&
    seal["ResultAssemblyFingerprint"] ===
      result["AssemblyFingerprint"] &&
    seal["TargetABIFingerprint"] === target["ABIFingerprint"] &&
    result["SourceABIFingerprint"] === target["ABIFingerprint"] &&
    result["OneForms"] === target["OneForms"] &&
    Take[result["OneForms"], baseCount] === assembly["OneForms"] &&
    exactPrefix === assembly["ExactChannelForms", "OneForms"] &&
    compiledPrefix === assembly["CompiledForms", "OneForms"] &&
    KeyDrop[result["ExactChannelForms"], "OneForms"] ===
      KeyDrop[assembly["ExactChannelForms"], "OneForms"] &&
    KeyDrop[result["CompiledForms"], "OneForms"] ===
      KeyDrop[assembly["CompiledForms"], "OneForms"] &&
    Dimensions[exactSuffix] === {suffixCount, 2, gradeCount} &&
    Dimensions[compiledSuffix] === {suffixCount, 2, gradeCount} &&
    Dimensions[canonicalPairs] === {suffixCount, 2, gradeCount, 2} &&
    drceFingerprint[exactSuffix] ===
      seal["ExactSuffixChannelsFingerprint"] &&
    drceFingerprint[canonicalPairs] ===
      seal["CanonicalSuffixPairsFingerprint"] &&
    drceFingerprint[compiledSuffix] ===
      seal["CompiledSuffixFingerprint"] &&
    drceFingerprint[Take[result["OneForms"], baseCount]] ===
      seal["BaseOneFormsPrefixFingerprint"] &&
    StringQ[seal["ExactEquationCoreFingerprint"]] &&
    StringLength[seal["ExactEquationCoreFingerprint"]] === 64 &&
    StringQ[seal["CompiledEquationCoreFingerprint"]] &&
    StringLength[seal["CompiledEquationCoreFingerprint"]] === 64 &&
    result["ExactChannelFormsFingerprint"] ===
      seal["ResultExactFormsFingerprint"] &&
    result["CompiledFormsFingerprint"] ===
      seal["ResultCompiledFormsFingerprint"] &&
    result["CompiledFormsShapeFingerprint"] ===
      seal["ResultCompiledShapeFingerprint"] &&
    result["GaugeUnknownCount"] === expectedGauge &&
    result["ResidueUnknownCount"] === expectedResidue &&
    result["UnknownCount"] === expectedUnknown &&
    result["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    target["GaugeUnknownCount"] === expectedGauge &&
    target["ResidueUnknownCount"] === expectedResidue &&
    target["UnknownCount"] === expectedUnknown &&
    target["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    result["ColumnOrder"] === expectedColumnOrder &&
    seal["BaseOneFormCount"] === baseCount &&
    seal["AppendedOneFormCount"] === suffixCount &&
    seal["GaugeUnknownCount"] === expectedGauge &&
    seal["ResidueUnknownCount"] === expectedResidue &&
    seal["UnknownCount"] === expectedUnknown &&
    seal["ColumnOrderFingerprint"] ===
      drceFingerprint[expectedColumnOrder] &&
    AssociationQ[booleanCertificates] &&
    Sort[Keys[booleanCertificates]] === Sort[$drceCertificateKeys] &&
    AllTrue[Values[booleanCertificates], BooleanQ] &&
    And @@ Values[booleanCertificates] &&
    FreeQ[{result, seal}, $Failed | _Missing]]
];

DRCAExactOneFormRebindSealValidQ[assembly_Association,
    target_Association, result_Association, seal_Association] :=
  drceSpecializedSealValidQ[assembly, target, result, seal];
DRCAExactOneFormRebindSealValidQ[___] := False;

DRCAConsumeExactOneFormRebindSealV6e[assembly_Association,
    target_Association, result_Association, seal_Association] := Module[
  {nonce = Lookup[seal, "Nonce", $Failed]},
  If[! StringQ[nonce] || KeyExistsQ[$drceConsumedNonces, nonce] ||
      ! drceSpecializedSealValidQ[assembly, target, result, seal],
    Return[False]];
  AssociateTo[$drceConsumedNonces, nonce -> <|
    "SealFingerprint" -> seal["SealFingerprint"],
    "ResultAssemblyFingerprint" -> result["AssemblyFingerprint"]|>];
  True
];
DRCAConsumeExactOneFormRebindSealV6e[___] := False;

DRCAClearExactOneFormRebindSealNoncesV6e[] :=
  ($drceConsumedNonces = <||>;
   <|"Status" -> "ExactOneFormRebindV6eNonceRegistryCleared"|>);

DRCARebindExactOneFormRecordsV6e[assembly_Association,
    target_Association, records_List] := Module[
  {timings = <||>, phaseMemory = <||>, sourceFile, sourceHashBefore,
   sourceHashesBefore, sourceHashesAfter, baseValid, targetValid,
   baseForms, targetForms, suffixForms, variables, epsilon, roots,
   gradeCount, dimensions, support, appendedForms, appendedChannels,
   canonicalPairs, recordFingerprints, composedSuffix,
   suffixCompositionExact, leafIndices,
   leafChannels, leafPairs, leafRecords, leafGroups, collisionFree,
   uniqueLeafRecords, rawLeafCount, uniqueLeafCount, cacheReuseCount,
   hashReuseGroupCount, collisionGroupCount, canonicalPairsMatchChannels,
   canonicalPairsValid, compiledUniqueLeaves, compiledByKey,
   compiledLeaves, compiledSuffix, auditIndices, legacyAuditCompiled,
   memoAuditCompiled, legacyAuditExact, exactForms, compiledForms,
   exactFingerprintData, compiledFingerprintData,
   compiledShapeFingerprintData, assemblyFingerprintData,
   gaugeUnknownCount, residueUnknownCount, unknownCount, result,
   exactCoreFingerprint, compiledCoreFingerprint,
   exactSuffixFingerprint, canonicalSuffixFingerprint,
   compiledSuffixFingerprint, basePrefixFingerprint,
   columnOrderFingerprint, sealPayload, seal, specializedSealPassed,
   legacyWholeResultOraclePassed, sourceStableAfterOracle,
   expressionByteCounts, serializedCharacterCounts, diagnostics,
   recordChannelFingerprintsExact},

  Print["CF300_GALOIS_ORBIT milestone=v6e_rebind_start records=",
    Length[records], " helper_sha256=", $drceSourceSHA256];
  sourceFile = Lookup[assembly, "PrototypeSourceFile", $Failed];
  sourceHashBefore = drceSourceHash[sourceFile];
  sourceHashesBefore = <|"Assembler" -> sourceHashBefore,
    "RebindV6e" -> drceSourceHash[$drceSourceFile]|>;
  If[sourceHashBefore =!= $drceExpectedAssemblerSHA256 ||
      sourceHashBefore =!= Lookup[assembly, "PrototypeSourceSHA256",
        $Failed] || ! drceSourceStableQ[],
    Return[drceFailure["UnpinnedSourceBeforeV6eRebind", <|
      "SourceHashesBefore" -> sourceHashesBefore|>]]];

  baseValid = drceMeasure["BaseValidation",
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      assembly], timings, phaseMemory];
  If[! TrueQ[baseValid],
    Return[drceFailure["InvalidBaseAssembly", <|
      "PhaseSeconds" -> timings|>]]];
  targetValid = drceMeasure["TargetABIValidation",
    Lookup[target, "Status", None] === "PreparedReconstruction" &&
      CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    timings, phaseMemory];
  If[! TrueQ[targetValid],
    Return[drceFailure["InvalidTargetPreparation", <|
      "PhaseSeconds" -> timings|>]]];
  If[! drceCoreCompatibleQ[assembly, target],
    Return[drceFailure["TargetChangesNonOneFormAnsatzData"]]];

  baseForms = assembly["OneForms"];
  targetForms = target["OneForms"];
  If[! ListQ[baseForms] || ! ListQ[targetForms] ||
      Length[targetForms] <= Length[baseForms] ||
      Take[targetForms, Length[baseForms]] =!= baseForms,
    Return[drceFailure["TargetOneFormsAreNotStrictPureSuperset"]]];
  suffixForms = Drop[targetForms, Length[baseForms]];
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  roots = assembly["Roots"];
  gradeCount = assembly["GradeCount"];
  dimensions = assembly["Dimensions"];
  support = assembly["GaugeSupport"];
  If[Length[records] =!= Length[suffixForms] ||
      ! AllTrue[records, drceRecordShapeValidQ],
    Return[drceFailure["AppendedRecordCountOrShapeInvalid", <|
      "ExpectedRecordCount" -> Length[suffixForms],
      "ObservedRecordCount" -> Length[records]|>]]];
  appendedForms = Lookup[records, "OneForm"];
  appendedChannels = Lookup[records, "OneFormChannels"];
  canonicalPairs = Lookup[records, "CanonicalFieldChannels"];
  recordFingerprints = Lookup[records, "ChannelFingerprint"];
  If[appendedForms =!= suffixForms ||
      Dimensions[appendedChannels] =!=
        {Length[suffixForms], 2, gradeCount} ||
      Dimensions[canonicalPairs] =!=
        {Length[suffixForms], 2, gradeCount, 2} ||
      ! VectorQ[recordFingerprints,
        StringQ[#1] && StringLength[#1] === 64 &],
    Return[drceFailure["AppendedRecordPayloadInvalid"]]];

  {composedSuffix, suffixCompositionExact} = drceMeasure[
    "SuffixCompositionEquality",
    Module[{localComposed},
      localComposed = Map[
        CodexTripleRootStrip`TRFieldCompose[#1, roots] &,
        appendedChannels, {2}];
      {localComposed, AllTrue[Flatten[localComposed - suffixForms],
        TrueQ[Together[#1] === 0] &]}], timings, phaseMemory];
  If[! TrueQ[suffixCompositionExact],
    Return[drceFailure["AppendedChannelsDoNotComposeToTargetSuffix", <|
      "PhaseSeconds" -> timings|>]]];
  Print["CF300_GALOIS_ORBIT milestone=v6e_suffix_composed seconds=",
    timings["SuffixCompositionEquality"]];

  leafIndices = Tuples[{Range[Length[suffixForms]], Range[2],
    Range[gradeCount]}];
  leafChannels = Extract[appendedChannels, leafIndices];
  leafPairs = Extract[canonicalPairs, leafIndices];
  leafRecords = drceMeasure["CanonicalLeafGrouping",
    Module[{localRecords, localGroups},
      localRecords = MapThread[Function[{index, channel, pair}, <|
          "Index" -> index, "Channel" -> channel, "Pair" -> pair,
          "Key" -> drceFingerprint[pair]|>],
        {leafIndices, leafChannels, leafPairs}];
      localGroups = GatherBy[localRecords, Lookup[#1, "Key"] &];
      {localRecords, localGroups}], timings, phaseMemory];
  {leafRecords, leafGroups} = leafRecords;
  rawLeafCount = Length[leafRecords];
  collisionFree = AllTrue[leafGroups, Function[group,
    AllTrue[Rest[group], SameQ[#1["Pair"], First[group]["Pair"]] &]]];
  collisionGroupCount = Count[leafGroups, group_ /;
    ! AllTrue[Rest[group], SameQ[#1["Pair"], First[group]["Pair"]] &]];
  If[! TrueQ[collisionFree] || collisionGroupCount =!= 0,
    Return[drceFailure["CanonicalLeafFingerprintCollision", <|
      "CollisionGroupCount" -> collisionGroupCount|>]]];
  uniqueLeafRecords = First /@ leafGroups;
  uniqueLeafCount = Length[uniqueLeafRecords];
  cacheReuseCount = rawLeafCount - uniqueLeafCount;
  hashReuseGroupCount = Count[leafGroups, group_ /; Length[group] > 1];
  {canonicalPairsValid, canonicalPairsMatchChannels,
    recordChannelFingerprintsExact} = drceMeasure[
    "CanonicalLeafValidation", {
      AllTrue[Lookup[uniqueLeafRecords, "Pair"],
        drceCanonicalPairValidQ[#1, variables, epsilon] &],
      And @@ MapThread[
        Function[{channel, pair}, TrueQ[Together[
          channel - pair[[1]]/pair[[2]]] === 0]],
        {leafChannels, leafPairs}],
      And @@ MapThread[SameQ[drceFingerprint[#1], #2] &,
        {canonicalPairs, recordFingerprints}]}, timings, phaseMemory];
  If[! canonicalPairsValid || ! canonicalPairsMatchChannels ||
      ! recordChannelFingerprintsExact ||
      rawLeafCount =!= uniqueLeafCount + cacheReuseCount,
    Return[drceFailure["CanonicalLeafContractInvalid", <|
      "RawLeafCount" -> rawLeafCount,
      "UniqueLeafCount" -> uniqueLeafCount,
      "CacheReuseCount" -> cacheReuseCount,
      "CanonicalPairsValid" -> canonicalPairsValid,
      "CanonicalPairsMatchChannels" -> canonicalPairsMatchChannels,
      "RecordChannelFingerprintsExact" ->
        recordChannelFingerprintsExact|>]]];

  compiledUniqueLeaves = drceMeasure["UniqueLeafCompilation",
    drceCompileCanonicalPair[#1["Pair"], variables, epsilon] & /@
      uniqueLeafRecords, timings, phaseMemory];
  If[! FreeQ[compiledUniqueLeaves, $Failed] ||
      ! AllTrue[compiledUniqueLeaves,
        AssociationQ[#1] &&
          Lookup[#1, "Type", None] === "DRCARationalExactV1" &],
    Return[drceFailure["CanonicalUniqueLeafCompilationFailed"]]];
  compiledByKey = AssociationThread[
    Lookup[uniqueLeafRecords, "Key"], compiledUniqueLeaves];
  compiledLeaves = Lookup[compiledByKey, Lookup[leafRecords, "Key"],
    $Failed];
  compiledSuffix = ArrayReshape[compiledLeaves,
    {Length[suffixForms], 2, gradeCount}];
  If[! FreeQ[compiledSuffix, $Failed] ||
      Dimensions[compiledSuffix] =!= Dimensions[appendedChannels],
    Return[drceFailure["MemoizedCompiledSuffixShapeInvalid"]]];

  auditIndices = DeleteDuplicates[Clip[{
    1, Ceiling[rawLeafCount/4], Ceiling[rawLeafCount/2],
    Ceiling[3 rawLeafCount/4], rawLeafCount}, {1, rawLeafCount}]];
  legacyAuditExact = Extract[appendedChannels,
    leafIndices[[auditIndices]]];
  {legacyAuditCompiled, memoAuditCompiled} = drceMeasure[
    "DeterministicLegacyCompilerAudit", {
      CodexDirectRootChannelAssembler`Private`drcaCompileRational[
        #1, variables, epsilon] & /@ legacyAuditExact,
      compiledLeaves[[auditIndices]]}, timings, phaseMemory];
  If[! SameQ[legacyAuditCompiled, memoAuditCompiled],
    Return[drceFailure["DeterministicLegacyCompilerAuditFailed", <|
      "AuditLeafIndices" -> auditIndices|>]]];
  Print["CF300_GALOIS_ORBIT milestone=v6e_unique_leaves_compiled raw=",
    rawLeafCount, " unique=", uniqueLeafCount, " reused=",
    cacheReuseCount, " compile_s=", timings["UniqueLeafCompilation"]];

  {exactForms, compiledForms} = drceMeasure["ExactCompiledJoins",
    {ReplacePart[assembly["ExactChannelForms"],
       "OneForms" -> Join[assembly["ExactChannelForms", "OneForms"],
         appendedChannels]],
     ReplacePart[assembly["CompiledForms"],
       "OneForms" -> Join[assembly["CompiledForms", "OneForms"],
         compiledSuffix]]}, timings, phaseMemory];
  If[KeyTake[exactForms, $drceEquationCoreKeys] =!=
      KeyTake[assembly["ExactChannelForms"], $drceEquationCoreKeys] ||
      KeyTake[compiledForms, $drceEquationCoreKeys] =!=
      KeyTake[assembly["CompiledForms"], $drceEquationCoreKeys],
    Return[drceFailure["EquationCoreChangedDuringV6eJoin"]]];

  gaugeUnknownCount = Times @@ dimensions gradeCount Length[support];
  residueUnknownCount = Length[targetForms] Times @@ dimensions;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  If[gaugeUnknownCount =!= target["GaugeUnknownCount"] ||
      residueUnknownCount =!= target["ResidueUnknownCount"] ||
      unknownCount =!= target["UnknownCount"] ||
      target["EquationsPerPoint"] =!= gradeCount 2 Times @@ dimensions,
    Return[drceFailure["TargetUnknownCountContractInvalid"]]];

  {exactFingerprintData, compiledFingerprintData,
     compiledShapeFingerprintData, result} =
    drceMeasure["LegacyFingerprintConstruction",
      Module[{exactData, compiledData, shapeData, localResult,
        assemblyData},
        exactData = drceFingerprintData[exactForms];
        compiledData = drceFingerprintData[compiledForms];
        shapeData = drceFingerprintData[drceFormShape[compiledForms]];
        localResult = ReplacePart[assembly, {
          "SourceABIFingerprint" -> target["ABIFingerprint"],
          "OneForms" -> targetForms,
          "ResidueUnknownCount" -> residueUnknownCount,
          "UnknownCount" -> unknownCount,
          "ColumnOrder" -> drceColumnOrder[dimensions, gradeCount,
            support, Length[targetForms]],
          "ExactChannelForms" -> exactForms,
          "CompiledForms" -> compiledForms,
          "ExactChannelFormsFingerprint" -> exactData["Fingerprint"],
          "CompiledFormsFingerprint" -> compiledData["Fingerprint"],
          "CompiledFormsShapeFingerprint" -> shapeData["Fingerprint"]}];
        assemblyData = drceFingerprintData[
          drceSemanticPayload[localResult]];
        localResult = ReplacePart[localResult,
          "AssemblyFingerprint" -> assemblyData["Fingerprint"]];
        {exactData, compiledData, shapeData,
          {localResult, assemblyData}}], timings, phaseMemory];
  {result, assemblyFingerprintData} = result;

  legacyWholeResultOraclePassed = drceMeasure[
    "OneLegacyWholeResultOracle",
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[result],
    timings, phaseMemory];
  If[! TrueQ[legacyWholeResultOraclePassed],
    Return[drceFailure["LegacyWholeResultOracleRejectedV6eResult", <|
      "PhaseSeconds" -> timings|>]]];
  sourceHashesAfter = <|"Assembler" -> drceSourceHash[sourceFile],
    "RebindV6e" -> drceSourceHash[$drceSourceFile]|>;
  sourceStableAfterOracle = TrueQ[
    sourceHashesAfter === sourceHashesBefore];
  If[! sourceStableAfterOracle,
    Return[drceFailure["SourceChangedDuringV6eRebind", <|
      "SourceHashesBefore" -> sourceHashesBefore,
      "SourceHashesAfter" -> sourceHashesAfter|>]]];

  seal = drceMeasure["SpecializedValidationSealConstruction",
    exactCoreFingerprint = drceFingerprint[
      KeyTake[exactForms, $drceEquationCoreKeys]];
    compiledCoreFingerprint = drceFingerprint[
      KeyTake[compiledForms, $drceEquationCoreKeys]];
    exactSuffixFingerprint = drceFingerprint[appendedChannels];
    canonicalSuffixFingerprint = drceFingerprint[canonicalPairs];
    compiledSuffixFingerprint = drceFingerprint[compiledSuffix];
    basePrefixFingerprint = drceFingerprint[baseForms];
    columnOrderFingerprint = drceFingerprint[result["ColumnOrder"]];
    sealPayload = <|
      "Status" -> "ExactOneFormRebindSpecializedSealV6e",
      "Nonce" -> CreateUUID[],
      "AssemblerSourceSHA256" -> sourceHashBefore,
      "ValidatorSourceSHA256" -> $drceSourceSHA256,
      "SourceHashesBeforeConstruction" -> sourceHashesBefore,
      "SourceHashesAfterConstruction" -> sourceHashesAfter,
      "BaseAssemblyFingerprint" -> assembly["AssemblyFingerprint"],
      "ResultAssemblyFingerprint" -> result["AssemblyFingerprint"],
      "TargetABIFingerprint" -> target["ABIFingerprint"],
      "BaseOneFormCount" -> Length[baseForms],
      "AppendedOneFormCount" -> Length[suffixForms],
      "BaseOneFormsPrefixFingerprint" -> basePrefixFingerprint,
      "ExactEquationCoreFingerprint" -> exactCoreFingerprint,
      "CompiledEquationCoreFingerprint" -> compiledCoreFingerprint,
      "ExactSuffixChannelsFingerprint" -> exactSuffixFingerprint,
      "CanonicalSuffixPairs" -> canonicalPairs,
      "CanonicalSuffixPairsFingerprint" -> canonicalSuffixFingerprint,
      "CompiledSuffixFingerprint" -> compiledSuffixFingerprint,
      "ResultExactFormsFingerprint" ->
        exactFingerprintData["Fingerprint"],
      "ResultCompiledFormsFingerprint" ->
        compiledFingerprintData["Fingerprint"],
      "ResultCompiledShapeFingerprint" ->
        compiledShapeFingerprintData["Fingerprint"],
      "GaugeUnknownCount" -> gaugeUnknownCount,
      "ResidueUnknownCount" -> residueUnknownCount,
      "UnknownCount" -> unknownCount,
      "ColumnOrderFingerprint" -> columnOrderFingerprint,
      "ExactSuffixDimensions" -> Dimensions[appendedChannels],
      "CompiledSuffixDimensions" -> Dimensions[compiledSuffix],
      "Certificates" -> <|
        "BaseValidatedOnce" -> TrueQ[baseValid],
        "TargetValidatedOnce" -> TrueQ[targetValid],
        "SourceStable" -> sourceStableAfterOracle,
        "FingerprintCollisionFree" -> collisionFree,
        "CanonicalPairsValid" -> canonicalPairsValid,
        "CanonicalPairsMatchChannels" -> canonicalPairsMatchChannels,
        "RecordChannelFingerprintsExact" ->
          recordChannelFingerprintsExact,
        "RawUniqueCacheConservationExact" -> TrueQ[
          rawLeafCount === uniqueLeafCount + cacheReuseCount],
        "DeterministicLegacyCompilerAuditExact" -> True,
        "EquationCorePreservedExactly" -> True,
        "LegacyWholeResultOraclePassed" ->
          TrueQ[legacyWholeResultOraclePassed]|>|>;
    Append[sealPayload,
      "SealFingerprint" -> drceFingerprint[sealPayload]],
    timings, phaseMemory];

  specializedSealPassed = drceMeasure[
    "SpecializedSealSelfValidation",
    drceSpecializedSealValidQ[assembly, target, result, seal],
    timings, phaseMemory];
  If[! TrueQ[specializedSealPassed],
    Return[drceFailure["SpecializedV6eSealSelfValidationFailed", <|
      "PhaseSeconds" -> timings|>]]];

  expressionByteCounts = <|
    "AppendedChannels" -> ByteCount[appendedChannels],
    "CanonicalPairsRaw" -> ByteCount[canonicalPairs],
    "CanonicalPairsUnique" -> ByteCount[Lookup[
      uniqueLeafRecords, "Pair"]],
    "CompiledSuffix" -> ByteCount[compiledSuffix],
    "ExactForms" -> ByteCount[exactForms],
    "CompiledForms" -> ByteCount[compiledForms]|>;
  serializedCharacterCounts = <|
    "ExactForms" -> exactFingerprintData["InputFormCharacterCount"],
    "CompiledForms" -> compiledFingerprintData[
      "InputFormCharacterCount"],
    "CompiledShape" -> compiledShapeFingerprintData[
      "InputFormCharacterCount"],
    "AssemblySemanticPayload" -> assemblyFingerprintData[
      "InputFormCharacterCount"]|>;
  diagnostics = <|
    "Status" -> "ExactOneFormChannelRebindV6e",
    "AppendedOneFormCount" -> Length[suffixForms],
    "AppendedChannelDimensions" -> Dimensions[appendedChannels],
    "CompiledSuffixDimensions" -> Dimensions[compiledSuffix],
    "RawLeafCount" -> rawLeafCount,
    "UniqueCompiledLeafCount" -> uniqueLeafCount,
    "CompileCacheReuseCount" -> cacheReuseCount,
    "HashReuseGroupCount" -> hashReuseGroupCount,
    "CollisionGroupCount" -> collisionGroupCount,
    "CompileCount" -> Length[compiledUniqueLeaves],
    "LegacyAuditCompileCount" -> Length[auditIndices],
    "LegacyWholeResultOracleCount" -> 1,
    "SpecializedSealPassed" -> specializedSealPassed,
    "LegacyWholeResultOraclePassed" ->
      TrueQ[legacyWholeResultOraclePassed],
    "AlgebraicFieldDecompositionCalls" -> 0,
    "AlgebraicRootBranchSubstitutions" -> 0,
    "EquationCorePreservedExactly" -> True,
    "MeasuredPhaseTotalSeconds" -> Total[Values[timings]],
    "PhaseSeconds" -> timings,
    "PhaseMemory" -> phaseMemory,
    "ExpressionByteCounts" -> expressionByteCounts,
    "SerializedInputFormCharacterCounts" -> serializedCharacterCounts,
    "SourceHashesBefore" -> sourceHashesBefore,
    "SourceHashesAfter" -> sourceHashesAfter|>;
  Print["CF300_GALOIS_ORBIT milestone=v6e_rebind_ready raw=",
    rawLeafCount, " unique=", uniqueLeafCount, " reused=",
    cacheReuseCount, " oracle_s=",
    timings["OneLegacyWholeResultOracle"], " seal_s=",
    timings["SpecializedValidationSealConstruction"]];
  Join[result, <|"ExactOneFormChannelRebindV6e" -> diagnostics,
    "ExactOneFormChannelRebindSealV6e" -> seal|>]
];

DRCARebindExactOneFormRecordsV6e[___] :=
  drceFailure["InvalidExactChannelRebindV6eArguments"];

End[];
EndPackage[];
