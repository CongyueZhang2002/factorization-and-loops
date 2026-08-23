(* STAGED ONLY.  Do not load from an active mission until the V6f runtime
   acceptance gate has promoted and source-pinned this exact file.

   Exactness boundary: the pinned driver must pass the immediate result of
   the frozen V6 legacy rebind.  That rebind has already constructed and
   validated the complete assembly.  V6f returns that exact semantic value;
   it never reconstructs a whole assembly from hashes.  The record Merkle
   tree is an integrity/indexing certificate, not an algebraic acceptance
   oracle. *)

BeginPackage["CodexDirectRootChannelExactOneFormBridgeV6f`", {
  "CodexDirectRootChannelAssembler`", "CodexTripleRootStrip`"}];

DRCABuildExactOneFormBridgeV6f::usage =
  "DRCABuildExactOneFormBridgeV6f[assembly,target,records,legacyResult,sourceFiles,expectedFingerprint] checks the optimized record suffix exactly against the immediate frozen-V6 result and registers a compact same-kernel bridge.";
DRCAResolveExactOneFormBridgeV6f::usage =
  "DRCAResolveExactOneFormBridgeV6f[handle] resolves a compact source-pinned handle without reserializing the stored assembly.";
DRCAReleaseExactOneFormBridgeV6f::usage =
  "DRCAReleaseExactOneFormBridgeV6f[handle] removes the private same-kernel bridge.";

Begin["`Private`"];

ClearAll[drbfFailure, drbfFingerprint, drbfSourceHashes,
  drbfExactCoefficientQ, drbfCanonicalPairValidQ,
  drbfCompileCanonicalPair, drbfMerkleRoot,
  drbfRecordLeafPayload, DRCABuildExactOneFormBridgeV6f,
  DRCAResolveExactOneFormBridgeV6f, DRCAReleaseExactOneFormBridgeV6f];

$drbfExpectedSourceHashes = <|
  "Assembler" ->
    "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "OrbitCoreV6d" ->
    "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
  "ExactChannelRebindV6" ->
    "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44"|>;

$drbfEquationCoreKeys = {"E", "C", "BBar", "RootSquares",
  "RootLogDerivatives", "GaugeDenominator", "GaugeLogDerivatives"};
$drbfRequiredRecordKeys = {"ForcingLetterIndex", "ChannelFingerprint",
  "OneForm", "OneFormChannels", "CanonicalFieldChannels",
  "ProvenanceCount", "Provenance"};
$drbfMaximumEpsilonDegree = 1;
$drbfRegistry = <||>;

drbfFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "ExactOneFormBridgeV6fFailure",
    "FailureReason" -> reason|>, data];

drbfFingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

drbfSourceHashes[sourceFiles_Association] := AssociationMap[
  Function[file, If[StringQ[file] && FileExistsQ[file],
    Quiet[Check[FileHash[file, "SHA256", "HexString"], $Failed]],
    $Failed]], sourceFiles];

drbfExactCoefficientQ[value_] := IntegerQ[value] ||
  Head[value] === Rational;

drbfCanonicalPairValidQ[pair_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {numerator, denominator, vars, numeratorRules, denominatorRules,
   epsilonDegrees, rational},
  If[! MatchQ[pair, {_, _}], Return[False]];
  {numerator, denominator} = pair;
  vars = Append[variables, epsilon];
  If[denominator === 0 ||
      ! FreeQ[pair, Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
      ! PolynomialQ[numerator, vars] || ! PolynomialQ[denominator, vars] ||
      ! SameQ[Expand[numerator], numerator] ||
      ! SameQ[Expand[denominator], denominator], Return[False]];
  numeratorRules = CoefficientRules[numerator, vars];
  denominatorRules = CoefficientRules[denominator, vars];
  If[! AllTrue[Join[Last /@ numeratorRules, Last /@ denominatorRules],
      drbfExactCoefficientQ], Return[False]];
  epsilonDegrees = Last[First[#1]] & /@ Join[
    numeratorRules, denominatorRules];
  If[Max[Prepend[epsilonDegrees, 0]] > $drbfMaximumEpsilonDegree,
    Return[False]];
  rational = Together[numerator/denominator];
  TrueQ[Expand[Numerator[rational]] === numerator &&
    Expand[Denominator[rational]] === denominator]
];

drbfCompileCanonicalPair[pair : {_, _},
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {numerator, denominator},
  numerator = CodexDirectRootChannelAssembler`Private`drcaCompilePolynomial[
    pair[[1]], variables, epsilon];
  denominator = CodexDirectRootChannelAssembler`Private`drcaCompilePolynomial[
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
drbfCompileCanonicalPair[___] := $Failed;

(* Domain-separated deterministic binary Merkle root.  Odd levels duplicate
   the final digest.  It authenticates compact leaf seals only; it can never
   replace the exact comparisons in DRCABuildExactOneFormBridgeV6f. *)
drbfMerkleRoot[leaves_List] := Module[{level = leaves, paired},
  If[leaves === {} || ! VectorQ[leaves,
      StringQ[#1] && StringLength[#1] === 64 &], Return[$Failed]];
  While[Length[level] > 1,
    If[OddQ[Length[level]], level = Append[level, Last[level]]];
    paired = Partition[level, 2];
    level = drbfFingerprint[{"V6fMerkleNodeV1", #[[1]], #[[2]]}] & /@
      paired];
  drbfFingerprint[{"V6fMerkleRootV1", Length[leaves], First[level]}]
];

drbfRecordLeafPayload[record_Association, index_Integer,
    targetFingerprint_String, sourceRoot_String] := <|
  "Domain" -> "V6fSourceCertifiedRecordLeafV1",
  "Index" -> index,
  "ForcingLetterIndex" -> record["ForcingLetterIndex"],
  "TargetABIFingerprint" -> targetFingerprint,
  "PinnedSourceRoot" -> sourceRoot,
  "OneFormFingerprint" -> drbfFingerprint[record["OneForm"]],
  "ChannelFingerprint" -> record["ChannelFingerprint"],
  "ProvenanceCount" -> record["ProvenanceCount"],
  "ProvenanceFingerprint" -> drbfFingerprint[record["Provenance"]]|>;

DRCABuildExactOneFormBridgeV6f[assembly_Association,
    target_Association, records_List, legacyResult_Association,
    sourceFiles_Association, expectedFingerprint_String] := Module[
  {sourceHashesBefore, sourceRoot, legacyDiagnostics, semanticAssembly,
   baseCount, suffixCount, gradeCount, variables, epsilon, roots,
   appendedForms, appendedChannels, canonicalPairs, recordFingerprints,
   composedSuffix, leafIndices, leafChannels, leafPairs, leafRecords, leafGroups,
   uniqueLeafRecords, compiledUniqueLeaves, compiledByKey, compiledLeaves,
   compiledSuffix, oracleExactSuffix, oracleCompiledSuffix,
   legacyAuditIndices, legacyAuditExact, legacyAuditCompiled,
   memoAuditCompiled, recordLeafPayloads, recordLeafSeals, recordMerkleRoot,
   bridgeID, compactPayload, handle, sourceHashesAfter},

  If[Sort[Keys[sourceFiles]] =!= Sort[Keys[$drbfExpectedSourceHashes]],
    Return[drbfFailure["SourceFileSetInvalid"]]];
  sourceHashesBefore = drbfSourceHashes[sourceFiles];
  If[sourceHashesBefore =!= $drbfExpectedSourceHashes,
    Return[drbfFailure["PinnedSourceHashMismatch", <|
      "ObservedSourceHashes" -> sourceHashesBefore|>]]];
  sourceRoot = drbfFingerprint[Normal[sourceHashesBefore]];

  legacyDiagnostics = Lookup[legacyResult,
    "ExactOneFormChannelRebindV6", <||>];
  semanticAssembly = KeyDrop[legacyResult,
    "ExactOneFormChannelRebindV6"];
  If[Lookup[legacyDiagnostics, "Status", None] =!=
        "ExactOneFormChannelRebindV6" ||
      Lookup[semanticAssembly, "AssemblyFingerprint", None] =!=
        expectedFingerprint,
    Return[drbfFailure["ImmediateLegacyOracleWitnessInvalid"]]];

  baseCount = Length[Lookup[assembly, "OneForms", {}]];
  suffixCount = Length[Lookup[target, "OneForms", {}]] - baseCount;
  gradeCount = Lookup[assembly, "GradeCount", $Failed];
  variables = Lookup[assembly, "Variables", $Failed];
  epsilon = Lookup[assembly, "Regulator", $Failed];
  roots = Lookup[assembly, "Roots", $Failed];
  If[suffixCount < 1 || ! IntegerQ[gradeCount] ||
      ! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      Length[records] =!= suffixCount ||
      ! AllTrue[records, Function[record, AssociationQ[record] &&
        AllTrue[$drbfRequiredRecordKeys, KeyExistsQ[record, #1] &]]],
    Return[drbfFailure["InputShapeInvalid"]]];
  appendedForms = Lookup[records, "OneForm"];
  appendedChannels = Lookup[records, "OneFormChannels"];
  canonicalPairs = Lookup[records, "CanonicalFieldChannels"];
  recordFingerprints = Lookup[records, "ChannelFingerprint"];
  If[appendedForms =!= Drop[target["OneForms"], baseCount] ||
      Dimensions[appendedChannels] =!= {suffixCount, 2, gradeCount} ||
      Dimensions[canonicalPairs] =!= {suffixCount, 2, gradeCount, 2} ||
      ! VectorQ[recordFingerprints,
        StringQ[#1] && StringLength[#1] === 64 &],
    Return[drbfFailure["RecordPayloadInvalid"]]];

  composedSuffix = Map[CodexTripleRootStrip`TRFieldCompose[#1, roots] &,
    appendedChannels, {2}];
  If[! AllTrue[Flatten[composedSuffix - appendedForms],
      TrueQ[Together[#1] === 0] &],
    Return[drbfFailure["RecordChannelsDoNotComposeExactly"]]];

  leafIndices = Tuples[{Range[suffixCount], Range[2], Range[gradeCount]}];
  leafChannels = Extract[appendedChannels, leafIndices];
  leafPairs = Extract[canonicalPairs, leafIndices];
  leafRecords = MapThread[Function[{index, pair}, <|
      "Index" -> index, "Pair" -> pair,
      "Key" -> drbfFingerprint[pair]|>], {leafIndices, leafPairs}];
  leafGroups = GatherBy[leafRecords, Lookup[#1, "Key"] &];
  If[! AllTrue[leafGroups, Function[group,
      AllTrue[Rest[group], SameQ[#1["Pair"], First[group]["Pair"]] &]]],
    Return[drbfFailure["CanonicalLeafFingerprintCollision"]]];
  uniqueLeafRecords = First /@ leafGroups;
  If[! AllTrue[Lookup[uniqueLeafRecords, "Pair"],
        drbfCanonicalPairValidQ[#1, variables, epsilon] &] ||
      ! And @@ MapThread[Function[{channel, pair}, TrueQ[Together[
          channel - pair[[1]]/pair[[2]]] === 0]],
        {leafChannels, leafPairs}] ||
      ! And @@ MapThread[SameQ[drbfFingerprint[#1], #2] &,
        {canonicalPairs, recordFingerprints}],
    Return[drbfFailure["CanonicalRecordContractInvalid"]]];

  compiledUniqueLeaves = drbfCompileCanonicalPair[
      #1["Pair"], variables, epsilon] & /@ uniqueLeafRecords;
  If[! FreeQ[compiledUniqueLeaves, $Failed],
    Return[drbfFailure["UniqueLeafCompilationFailed"]]];
  compiledByKey = AssociationThread[
    Lookup[uniqueLeafRecords, "Key"], compiledUniqueLeaves];
  compiledLeaves = Lookup[compiledByKey, Lookup[leafRecords, "Key"],
    $Failed];
  compiledSuffix = ArrayReshape[compiledLeaves,
    {suffixCount, 2, gradeCount}];

  legacyAuditIndices = DeleteDuplicates[Clip[{1,
    Ceiling[Length[leafIndices]/4], Ceiling[Length[leafIndices]/2],
    Ceiling[3 Length[leafIndices]/4], Length[leafIndices]},
    {1, Length[leafIndices]}]];
  legacyAuditExact = Extract[appendedChannels,
    leafIndices[[legacyAuditIndices]]];
  legacyAuditCompiled =
    CodexDirectRootChannelAssembler`Private`drcaCompileRational[
      #1, variables, epsilon] & /@ legacyAuditExact;
  memoAuditCompiled = compiledLeaves[[legacyAuditIndices]];
  If[! SameQ[legacyAuditCompiled, memoAuditCompiled],
    Return[drbfFailure["DeterministicLegacyCompilerAuditFailed"]]];

  oracleExactSuffix = Drop[
    semanticAssembly["ExactChannelForms", "OneForms"], baseCount];
  oracleCompiledSuffix = Drop[
    semanticAssembly["CompiledForms", "OneForms"], baseCount];
  If[appendedChannels =!= oracleExactSuffix ||
      compiledSuffix =!= oracleCompiledSuffix ||
      target["OneForms"] =!= semanticAssembly["OneForms"] ||
      target["ABIFingerprint"] =!=
        semanticAssembly["SourceABIFingerprint"] ||
      Take[semanticAssembly["OneForms"], baseCount] =!=
        assembly["OneForms"] ||
      KeyTake[semanticAssembly["ExactChannelForms"],
        $drbfEquationCoreKeys] =!= KeyTake[assembly["ExactChannelForms"],
        $drbfEquationCoreKeys] ||
      KeyTake[semanticAssembly["CompiledForms"],
        $drbfEquationCoreKeys] =!= KeyTake[assembly["CompiledForms"],
        $drbfEquationCoreKeys],
    Return[drbfFailure["ExactLegacySuffixBridgeMismatch"]]];

  recordLeafPayloads = MapIndexed[drbfRecordLeafPayload[#1,
      First[#2], target["ABIFingerprint"], sourceRoot] &, records];
  recordLeafSeals = drbfFingerprint /@ recordLeafPayloads;
  recordMerkleRoot = drbfMerkleRoot[recordLeafSeals];
  If[recordMerkleRoot === $Failed,
    Return[drbfFailure["RecordMerkleConstructionFailed"]]];

  sourceHashesAfter = drbfSourceHashes[sourceFiles];
  If[sourceHashesAfter =!= sourceHashesBefore,
    Return[drbfFailure["SourceChangedDuringBridgeBuild"]]];
  bridgeID = CreateUUID[];
  compactPayload = <|
    "Status" -> "ExactOneFormBridgeV6f",
    "BridgeID" -> bridgeID,
    "SourceHashes" -> sourceHashesBefore,
    "SourceRoot" -> sourceRoot,
    "BaseAssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "TargetABIFingerprint" -> target["ABIFingerprint"],
    "ResultAssemblyFingerprint" -> expectedFingerprint,
    "RecordCount" -> Length[records],
    "RawLeafCount" -> Length[leafRecords],
    "UniqueCompiledLeafCount" -> Length[uniqueLeafRecords],
    "RecordLeafSeals" -> recordLeafSeals,
    "RecordMerkleRoot" -> recordMerkleRoot,
    "ExactLegacyOracleBridgePassed" -> True,
    "ExactSuffixChannelsPassed" -> True,
    "ExactCompiledSuffixPassed" -> True|>;
  handle = Append[compactPayload,
    "BridgeFingerprint" -> drbfFingerprint[compactPayload]];
  AssociateTo[$drbfRegistry, bridgeID -> <|
    "Handle" -> handle, "Assembly" -> semanticAssembly,
    "SourceFiles" -> sourceFiles|>];
  handle
];
DRCABuildExactOneFormBridgeV6f[___] :=
  drbfFailure["InvalidBridgeBuildArguments"];

DRCAResolveExactOneFormBridgeV6f[handle_Association] := Module[
  {bridgeID, entry},
  bridgeID = Lookup[handle, "BridgeID", $Failed];
  entry = Lookup[$drbfRegistry, bridgeID, $Failed];
  If[! AssociationQ[entry] || handle =!= entry["Handle"] ||
      drbfSourceHashes[entry["SourceFiles"]] =!= handle["SourceHashes"],
    Return[drbfFailure["UnknownTamperedOrStaleBridge"]]];
  <|"Status" -> "ExactOneFormBridgeV6fResolved",
    "Assembly" -> entry["Assembly"], "Handle" -> handle|>
];
DRCAResolveExactOneFormBridgeV6f[___] :=
  drbfFailure["InvalidBridgeHandle"];

DRCAReleaseExactOneFormBridgeV6f[handle_Association] := Module[
  {bridgeID = Lookup[handle, "BridgeID", $Failed], entry},
  entry = Lookup[$drbfRegistry, bridgeID, $Failed];
  If[! AssociationQ[entry] || handle =!= entry["Handle"], Return[False]];
  KeyDropFrom[$drbfRegistry, bridgeID];
  True
];
DRCAReleaseExactOneFormBridgeV6f[___] := False;

End[];
EndPackage[];
