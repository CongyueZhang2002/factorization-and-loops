#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300S12R2A0PROBE FAIL usage=<project-root> " <>
    "<rank2-preparation.wl> <fresh-output.wl> <I00|I01|I10|I11>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
imageID = arguments[[4]];
driverDirectory = DirectoryName[$InputFileName];
physicalDirectory = DirectoryName[driverDirectory];
exchangeDirectory = DirectoryName[physicalDirectory];
adapterFile = FileNameJoin[{exchangeDirectory, "flint_affine_rref_wl_xh",
  "FlintAffineRREFAdapter.wl"}];
nativeSource = FileNameJoin[{exchangeDirectory, "flint_affine_rref_xh",
  "flint_affine_rref.c"}];
nativeBinary = FileNameJoin[{exchangeDirectory, "flint_affine_rref_xh",
  "bin", "flint_affine_rref"}];

expectedPreparationSHA256 =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedInputSHA256 =
  "274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6";
expectedAdapterSHA256 =
  "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c";
expectedNativeSourceSHA256 =
  "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd";
expectedNativeBinarySHA256 =
  "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5";

(* Literal immutable manifest of the complete executed source set.  This
   diagnostic deliberately does not load LoadFACET/FeynCalc/FeynFacet. *)
expectedSourceClosureRelative = <|
  "External/CodexExchange/triple_root_2026-08-22/TripleRootAffinePilot.wl" -> "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootAlgebra.wl" -> "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootReconstructionPrototype.wl" -> "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "External/CodexExchange/triple_root_2026-08-22/TripleRootStripAdapter.wl" -> "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "External/CodexExchange/triple_root_2026-08-22/flint_affine_rref_wl_xh/FlintAffineRREFAdapter.wl" -> "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c",
  "External/CodexExchange/triple_root_2026-08-22/flint_affine_rref_xh/flint_affine_rref.c" -> "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd"|>;
expectedSourceClosure[] := Association@KeyValueMap[
  FileNameJoin[{projectRoot, #1}] -> #2 &, expectedSourceClosureRelative];
sourceClosureDifference[observed_Association, expected_Association] :=
    Module[{observedKeys, expectedKeys, commonKeys},
  observedKeys = Keys[observed];
  expectedKeys = Keys[expected];
  commonKeys = Intersection[observedKeys, expectedKeys];
  <|"MissingKeys" -> Complement[expectedKeys, observedKeys],
    "UnexpectedKeys" -> Complement[observedKeys, expectedKeys],
    "HashMismatchKeys" -> Select[commonKeys,
      observed[#1] =!= expected[#1] &]|>
];

imageSpecifications = <|
  "I00" -> <|"Prime" -> 10007, "EpsilonValue" -> 1/21|>,
  "I01" -> <|"Prime" -> 10007, "EpsilonValue" -> 1/11|>,
  "I10" -> <|"Prime" -> 10039, "EpsilonValue" -> 1/21|>,
  "I11" -> <|"Prime" -> 10039, "EpsilonValue" -> 1/11|>|>;
If[! KeyExistsQ[imageSpecifications, imageID],
  Print["CF300S12R2A0PROBE FAIL invalid image selector"];
  Exit[64]];
image = imageSpecifications[imageID];

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
  "FLINTAffineRREFAdapter" -> adapterFile,
  "FLINTAffineRREFSource" -> nativeSource,
  "FLINTAffineRREFBinary" -> nativeBinary|>];
executedSourceFiles = Join[
  KeyTake[coreDependencyFiles, {"TripleRootAlgebra",
    "TripleRootStripAdapter", "TripleRootAffinePilot",
    "TripleRootReconstructionPrototype"}], <|
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
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300S12R2A0PROBE FAIL invalid dependency, input, or stale target"];
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
  postCommitValid = SameQ[committed, value] &&
    AssociationQ[committed] &&
    Lookup[committed, "Status", None] === Lookup[value, "Status", None] &&
    (commitCheck === Automatic || TrueQ[commitCheck[]]);
  If[! TrueQ[postCommitValid],
    If[! TrueQ[deleteIfPresent[outputFile]],
      Print["CF300S12R2A0PROBE FAIL invalid committed target remains output=",
        outputFile]];
    Return[$Failed]];
  outputFile
];
finish[status_String, data_: <||>, code_: 2] := Module[{artifact},
  artifact = Join[<|"Status" -> status, "ImageID" -> imageID,
    "PreparationFile" -> preparationFile|>, data];
  If[writeAtomic[artifact] === $Failed, Exit[98]];
  Print["CF300S12R2A0PROBE RESULT status=", status,
    " image=", imageID, " output=", outputFile];
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
If[preparationHashBefore =!= expectedPreparationSHA256 ||
    ! AllTrue[Values[sourceClosureDiff], #1 === {} &] ||
    namedRuntimeHashesBefore["FLINTAffineRREFAdapter"] =!=
      expectedAdapterSHA256 ||
    namedRuntimeHashesBefore["FLINTAffineRREFSource"] =!=
      expectedNativeSourceSHA256 ||
    namedRuntimeHashesBefore["FLINTAffineRREFBinary"] =!=
      expectedNativeBinarySHA256,
  finish["PinnedSourceHashMismatch", <|
    "NamedRuntimeHashes" -> namedRuntimeHashesBefore,
    "ExpectedSourceClosure" -> KeySort[sourceClosureExpected],
    "ObservedSourceClosure" -> KeySort[sourceClosureBefore],
    "SourceClosureDifference" -> sourceClosureDiff|>, 66]];

Get[coreDependencyFiles["TripleRootAlgebra"]];
Get[coreDependencyFiles["TripleRootStripAdapter"]];
Get[coreDependencyFiles["TripleRootAffinePilot"]];
Get[coreDependencyFiles["TripleRootReconstructionPrototype"]];
Get[adapterFile];
If[namedRuntimeHashes[] =!= namedRuntimeHashesBefore ||
    sourceClosureSnapshot[] =!= sourceClosureBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["SourceChangedDuringLoad", <||>, 95]];

artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"},
    Quiet[Check[Get[file], $Failed]]]];
preparationArtifact = artifactRead[preparationFile];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    Lookup[preparationArtifact, "InputSHA256", None] =!=
      expectedInputSHA256 ||
    Lookup[preparationArtifact, "DependencyHashes", None] =!=
      KeyTake[namedRuntimeHashesBefore, Keys[coreDependencyFiles]],
  finish["PinnedPreparationArtifactInvalid", <||>, 66]];
inputFile = Lookup[preparationArtifact, "InputFile", $Failed];
preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
If[FileHash[preparationFile, "SHA256", "HexString"] =!=
      preparationHashBefore ||
    ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
    FileHash[inputFile, "SHA256", "HexString"] =!= expectedInputSHA256 ||
    ! StringQ[preparationDriverFile] ||
    ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None],
  finish["PinnedPreparationProvenanceInvalid", <||>, 66]];
preparation = Lookup[preparationArtifact, "Preparation", $Failed];
If[! AssociationQ[preparation] ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    preparation["ABIFingerprint"] =!=
      Lookup[preparationArtifact, "Preparation", <||>]["ABIFingerprint"] ||
    preparation["RootSourceIndices"] =!= {2, 3} ||
    preparation["Dimensions"] =!= {2, 2} ||
    preparation["GaugeUnknownCount"] =!= 480 ||
    preparation["ResidueUnknownCount"] =!= 144 ||
    preparation["UnknownCount"] =!= 624 ||
    preparation["EquationsPerPoint"] =!= 32 ||
    preparation["Normalizations"] =!= {},
  finish["PinnedA0PreparationShapeInvalid", <||>, 67]];

pointCount = Max[4, Ceiling[(preparation["UnknownCount"] + 32)/32]];
If[pointCount =!= 21, finish["A0PointCountChanged", <||>, 67]];
seed = Hash[{730000 + Mod[image["Prime"], 100000],
  preparation["ABIFingerprint"], image["Prime"],
  image["EpsilonValue"]}, "CRC32"];
{assemblySeconds, sample} = AbsoluteTiming[TimeConstrained[
  Block[{CodexTripleRootReconstruction`Private`$trValidatedABIFingerprint =
      preparation["ABIFingerprint"]},
    CodexTripleRootReconstruction`Private`trAssembleReconstructionSampleInternal[
      preparation, image["EpsilonValue"], image["Prime"],
      "PointCount" -> pointCount, "MaximumAttempts" -> 40 pointCount,
      "RandomSeed" -> seed,
      "ValidatedABIFingerprint" -> preparation["ABIFingerprint"]]],
  900, $Failed]];
If[! AssociationQ[sample] ||
    Lookup[sample, "Status", None] =!= "AssembledReconstructionSample" ||
    sample["ABIFingerprint"] =!= preparation["ABIFingerprint"] ||
    sample["Prime"] =!= image["Prime"] ||
    sample["EpsilonValue"] =!= image["EpsilonValue"] ||
    sample["BranchFlipMask"] =!= 0 || sample["NormalizationCount"] =!= 0 ||
    sample["MatrixDimensions"] =!= {672, 624} ||
    Dimensions[sample["Matrix"]] =!= {672, 624} ||
    Length[sample["RightHandSide"]] =!= 672 ||
    Length[sample["AcceptedPoints"]] =!= 21,
  finish["A0ImageAssemblyFailed", <|
    "Assembly" -> KeyDrop[sample, {"Matrix", "RightHandSide"}]|>, 68]];

makeNonce[tag_String] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, imageID, seed, tag, #1},
      "SHA256"], 2^64] & /@ {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];
requestFingerprint[request_Association] := fingerprint[<|
  "Metadata" -> KeyDrop[request, {"Matrix", "RightHandSide"}],
  "MatrixSHA256" -> Hash[request["Matrix"], "SHA256", "HexString"],
  "RightHandSideSHA256" -> Hash[request["RightHandSide"],
    "SHA256", "HexString"]|>];

nativeRank[localMatrix_, prime_Integer, tag_String,
    preference_List] := Module[{request, seconds, run, certificate},
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    localMatrix, ConstantArray[0, Dimensions[localMatrix][[1]]], prime,
    preference, makeNonce[tag]];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    finish["NativeRankRequestInvalid", <|"Tag" -> tag|>, 69]];
  {seconds, run} = AbsoluteTiming[
    CodexFLINTAffineRREFAdapter`CFFRRun[nativeBinary, request, 1,
      False, 600]];
  If[Lookup[run, "Status", None] =!= "VerifiedFLINTAffineRREFRun",
    finish["NativeRankRunFailed", <|"Tag" -> tag,
      "MatrixDimensions" -> Dimensions[localMatrix],
      "MatrixFingerprint" -> Hash[localMatrix, "SHA256", "HexString"],
      "RequestFingerprint" -> requestFingerprint[request],
      "RequestNonce" -> request["Nonce"],
      "Run" -> KeyDrop[run, {"Certificate"}]|>, 70]];
  certificate = run["Certificate"];
  If[certificate["ParticularSolution"] =!=
      ConstantArray[0, Dimensions[localMatrix][[2]]] ||
      certificate["Rank"] + certificate["Nullity"] =!=
        Dimensions[localMatrix][[2]],
    finish["NativeRankCertificateInvalid", <|"Tag" -> tag|>, 71]];
  <|"Status" -> "VerifiedNativeRankV1",
    "MatrixDimensions" -> Dimensions[localMatrix],
    "Rank" -> certificate["Rank"], "Nullity" -> certificate["Nullity"],
    "Seconds" -> seconds, "RequestNonce" -> request["Nonce"],
    "RequestFingerprint" -> requestFingerprint[request],
    "PivotFingerprint" -> fingerprint[certificate["PivotColumns"]],
    "FreeColumnFingerprint" -> fingerprint[certificate["FreeColumns"]],
    "NullspaceFingerprint" -> fingerprint[certificate["NullspaceBasis"]],
    "RowWitnessFingerprint" ->
      fingerprint[certificate["IndependentEquationRows"]]|>
];

rankImage[localMatrix_, localRight_List, prime_Integer,
    tag_String] := Module[{rows, columns, rightColumn, augmented,
    coefficient, augmentedResult, consistent},
  {rows, columns} = Dimensions[localMatrix];
  rightColumn = SparseArray[
    MapIndexed[{First[#2], 1} -> #1 &, localRight], {rows, 1}];
  augmented = Join[localMatrix, rightColumn, 2];
  If[Dimensions[augmented] =!= {rows, columns + 1} ||
      ! MatrixQ[augmented, IntegerQ],
    finish["AugmentedMatrixConstructionFailed", <|"Tag" -> tag|>, 69]];
  coefficient = nativeRank[localMatrix, prime, tag <> "-coefficient",
    Range[columns]];
  augmentedResult = nativeRank[augmented, prime, tag <> "-augmented",
    Range[columns + 1]];
  If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
      augmentedResult["Rank"]],
    finish["AugmentedRankRelationInvalid", <|"Tag" -> tag,
      "CoefficientRank" -> coefficient["Rank"],
      "AugmentedRank" -> augmentedResult["Rank"]|>, 72]];
  consistent = augmentedResult["Rank"] === coefficient["Rank"];
  <|"Status" -> "CertifiedAffineConsistencyByTwoRanksV1",
    "Tag" -> tag, "Consistent" -> consistent,
    "CoefficientRank" -> coefficient["Rank"],
    "AugmentedRank" -> augmentedResult["Rank"],
    "CoefficientNullity" -> coefficient["Nullity"],
    "CoefficientRankCertificate" -> coefficient,
    "AugmentedRankCertificate" -> augmentedResult|>
];

matrix = sample["Matrix"];
right = sample["RightHandSide"];
fullResult = rankImage[matrix, right, image["Prime"], "full"];
nestedResults = If[imageID === "I00",
  Table[If[prefixPointCount === 21,
      Join[fullResult, <|"PrefixPointCount" -> 21|>],
      Join[rankImage[matrix[[1 ;; 32 prefixPointCount]],
          right[[1 ;; 32 prefixPointCount]], image["Prime"],
          "prefix-" <> ToString[prefixPointCount]],
        <|"PrefixPointCount" -> prefixPointCount|>]],
    {prefixPointCount, {19, 20, 21}}], {}];

currentState[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Input" -> FileHash[inputFile, "SHA256", "HexString"],
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"],
  "NamedRuntimeHashes" -> namedRuntimeHashes[],
  "SourceClosure" -> sourceClosureSnapshot[]|>;
expectedState = <|
  "Preparation" -> preparationHashBefore,
  "Input" -> expectedInputSHA256,
  "PreparationDriver" -> preparationArtifact["DriverSHA256"],
  "Driver" -> driverHashBefore,
  "NamedRuntimeHashes" -> namedRuntimeHashesBefore,
  "SourceClosure" -> sourceClosureBefore|>;
If[currentState[] =!= expectedState,
  finish["SourceChangedBeforeStaging", <||>, 96]];

result = <|
  "Status" -> "CF300Sector12Rank2A0ImageProbeV1",
  "ImageID" -> imageID, "Image" -> image,
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> preparationHashBefore,
  "InputFile" -> inputFile, "InputSHA256" -> expectedInputSHA256,
  "DriverFile" -> $InputFileName, "DriverSHA256" -> driverHashBefore,
  "NativeThreads" -> 1, "NativeTimeoutSecondsPerRank" -> 600,
  "SymbolicAssemblyTimeoutSeconds" -> 900,
  "Seed" -> seed, "PointCount" -> pointCount,
  "AssemblySeconds" -> assemblySeconds,
  "AttemptCount" -> sample["AttemptCount"],
  "AcceptedPoints" -> sample["AcceptedPoints"],
  "AcceptedPointsFingerprint" -> fingerprint[sample["AcceptedPoints"]],
  "MatrixFingerprint" -> Hash[matrix, "SHA256", "HexString"],
  "RightHandSideFingerprint" -> Hash[right, "SHA256", "HexString"],
  "FullImageResult" -> fullResult,
  "NestedPrefixResults" -> nestedResults,
  "ConsistencyMethod" -> "VerifiedRanksOfAAndAugmentedMatrix",
  "ExpectedSourceState" -> expectedState|>;
If[writeAtomic[result, Function[Null, currentState[] === expectedState]] ===
    $Failed,
  Print["CF300S12R2A0PROBE FAIL atomic commit or source-stability gate"];
  Exit[97]];
Print["CF300S12R2A0PROBE RESULT status=", result["Status"],
  " image=", imageID, " consistent=", fullResult["Consistent"],
  " output=", outputFile];
Exit[0];
