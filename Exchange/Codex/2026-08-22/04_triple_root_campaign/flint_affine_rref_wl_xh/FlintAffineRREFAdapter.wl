(* ::Package:: *)

BeginPackage["CodexFLINTAffineRREFAdapter`"];

CFFRMakeRequest::usage =
  "CFFRMakeRequest[A,b,p,preference,nonce] validates and constructs a nonce-bound CFFR1V1 affine-RREF request.";
CFFRWriteRequest::usage =
  "CFFRWriteRequest[file,request] atomically serializes an exact CFFR1V1 request.";
CFFRParseResponse::usage =
  "CFFRParseResponse[file,request] strictly parses a nonce-bound CFFR1X1 response with exact-size, exact-EOF, index, and canonical-word checks.";
CFFRVerifyCertificate::usage =
  "CFFRVerifyCertificate[request,certificate] independently verifies the affine solution, canonical basis, row-minor witness, normalization-minor witness, and preference selection.";
CFFRConstructCrossPrimePlanV1::usage =
  "CFFRConstructCrossPrimePlanV1[preparation,sample,seed,request,certificate] constructs the existing CrossPrimeEliminationPlanV1 payload after independent certificate verification.";
CFFRRun::usage =
  "CFFRRun[binary,request,threads,keepDirectory,timeoutSeconds] invokes flint_affine_rref without a shell and accepts output only after strict parse and verification.";

Begin["`Private`"];

$cffrInputMagic = ToCharacterCode["CFFR1V1\000"];
$cffrOutputMagic = ToCharacterCode["CFFR1X1\000"];
$cffrInputHeaderWords = 9;
$cffrOutputHeaderWords = 11;
$cffrProtocolVersion = 1;
$cffrInconsistentExitCode = 5;
$cffrMaximumWord = 2^64 - 1;
$cffrPlanPayloadKeys = {
  "Status", "PlanVersion", "ABIFingerprint",
  "RootOrderingFingerprint", "MatrixDimensions", "PointCount",
  "NormalizationEquationCount", "BranchFlipMask",
  "IndependentEquationRows", "NormalizationColumns", "GenericRank",
  "Nullity", "UnknownCount", "GaugeUnknownCount", "FreeResidueCount",
  "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "GaugeSupport",
  "PilotPrime", "PilotEpsilonValue", "PilotRandomSeed",
  "PilotAcceptedPoints", "PilotPivotColumns", "PilotFreeColumns",
  "DiscoveryMethod"};

cffrFailure[status_String, data_: <||>] := Join[<|"Status" -> status|>, data];

cffrExactKeysQ[association_Association, keys_List] :=
  Sort[Keys[association]] === Sort[keys];

cffrUnsignedWordQ[value_] :=
  IntegerQ[value] && 0 <= value <= $cffrMaximumWord;

cffrCanonicalWordQ[value_, prime_Integer] :=
  IntegerQ[value] && 0 <= value < prime;

cffrPrimeQ[prime_] := IntegerQ[prime] && 2 < prime < 2^63 && PrimeQ[prime];

cffrPermutationQ[value_, size_Integer] :=
  VectorQ[value, IntegerQ] && Length[value] === size &&
    Sort[value] === Range[size];

cffrMatrixShapeQ[value_, rows_Integer, columns_Integer] := Which[
  rows === 0, value === {},
  True, MatrixQ[value, IntegerQ] && Dimensions[value] === {rows, columns}
];

cffrCanonicalMatrixQ[value_, rows_Integer, columns_Integer,
    prime_Integer] :=
  cffrMatrixShapeQ[value, rows, columns] &&
    AllTrue[Flatten[value], cffrCanonicalWordQ[#1, prime] &];

cffrRequestKeys = {
  "Status", "ProtocolVersion", "Magic", "MatrixDimensions",
  "RHSColumns", "Prime", "PreferenceCount", "Flags", "Nonce",
  "PayloadWords", "Matrix", "RightHandSide", "Preference",
  "WireIndexBase"};

cffrRequestValidQ[request_Association] := Module[
  {dimensions, rows, columns, prime, nonce, matrix, right, preference},
  If[! cffrExactKeysQ[request, cffrRequestKeys], Return[False]];
  dimensions = request["MatrixDimensions"];
  If[! MatchQ[dimensions, {_Integer, _Integer}], Return[False]];
  {rows, columns} = dimensions;
  prime = request["Prime"];
  nonce = request["Nonce"];
  matrix = request["Matrix"];
  right = request["RightHandSide"];
  preference = request["Preference"];
  TrueQ[
    request["Status"] === "CFFRRequestV1" &&
    request["ProtocolVersion"] === $cffrProtocolVersion &&
    request["Magic"] === "CFFR1V1" &&
    rows >= 1 && columns >= 1 &&
    request["RHSColumns"] === 1 && cffrPrimeQ[prime] &&
    request["PreferenceCount"] === columns && request["Flags"] === 0 &&
    MatchQ[nonce, {_Integer, _Integer}] &&
    AllTrue[nonce, cffrUnsignedWordQ] && nonce =!= {0, 0} &&
    request["PayloadWords"] === rows columns + rows + columns &&
    cffrCanonicalMatrixQ[matrix, rows, columns, prime] &&
    VectorQ[right, cffrCanonicalWordQ[#1, prime] &] &&
    Length[right] === rows && cffrPermutationQ[preference, columns] &&
    request["WireIndexBase"] === 0]
];

cffrFreshNonce[] := Module[{nonce},
  nonce = RandomInteger[{0, $cffrMaximumWord}, 2];
  If[nonce === {0, 0}, {0, 1}, nonce]
];

CFFRMakeRequest[matrix_?MatrixQ, right_List, prime_Integer,
    preference_: Automatic, nonce_: Automatic] := Module[
  {normalMatrix = Normal[matrix], dimensions, rows, columns,
   actualPreference, actualNonce},
  dimensions = Dimensions[normalMatrix];
  If[Length[dimensions] =!= 2,
    Return[cffrFailure["RequestMatrixNotRectangular"]]];
  {rows, columns} = dimensions;
  actualPreference = If[preference === Automatic, Range[columns], preference];
  actualNonce = If[nonce === Automatic, cffrFreshNonce[], nonce];
  If[rows < 1 || columns < 1 || ! cffrPrimeQ[prime] ||
      ! MatrixQ[normalMatrix, IntegerQ] || ! VectorQ[right, IntegerQ] ||
      Length[right] =!= rows ||
      ! cffrPermutationQ[actualPreference, columns] ||
      ! MatchQ[actualNonce, {_Integer, _Integer}] ||
      ! AllTrue[actualNonce, cffrUnsignedWordQ] || actualNonce === {0, 0},
    Return[cffrFailure["InvalidAffineRREFRequest"]]];
  With[{request = <|
      "Status" -> "CFFRRequestV1",
      "ProtocolVersion" -> $cffrProtocolVersion,
      "Magic" -> "CFFR1V1",
      "MatrixDimensions" -> dimensions,
      "RHSColumns" -> 1,
      "Prime" -> prime,
      "PreferenceCount" -> columns,
      "Flags" -> 0,
      "Nonce" -> actualNonce,
      "PayloadWords" -> rows columns + rows + columns,
      "Matrix" -> Mod[normalMatrix, prime],
      "RightHandSide" -> Mod[right, prime],
      "Preference" -> actualPreference,
      "WireIndexBase" -> 0|>},
    If[cffrRequestValidQ[request], request,
      cffrFailure["InvalidAffineRREFRequest"]]]
];

CFFRMakeRequest[___] := cffrFailure["InvalidAffineRREFRequestArguments"];

cffrCloseQuietly[stream_] := If[stream =!= None, Quiet[Close[stream]]];

cffrDeleteTemporary[file_String] :=
  If[FileExistsQ[file], Quiet[DeleteFile[file]]];

CFFRWriteRequest[file_String, request_Association] := Module[
  {directory, temporary, stream = None, result, rows, columns, prime,
   nonce, payload},
  If[! cffrRequestValidQ[request],
    Return[cffrFailure["InvalidAffineRREFRequest"]]];
  If[FileExistsQ[file], Return[cffrFailure["RequestTargetExists"]]];
  directory = DirectoryName[ExpandFileName[file]];
  If[! DirectoryQ[directory], Return[cffrFailure["RequestDirectoryMissing"]]];
  temporary = FileNameJoin[{directory,
    "." <> FileNameTake[file] <> ".tmp-" <> StringReplace[CreateUUID[], "-" -> ""]}];
  {rows, columns} = request["MatrixDimensions"];
  prime = request["Prime"];
  nonce = request["Nonce"];
  payload = Join[Flatten[request["Matrix"]], request["RightHandSide"],
    request["Preference"] - 1];
  result = Quiet[Check[
    stream = OpenWrite[temporary, BinaryFormat -> True];
    BinaryWrite[stream, $cffrInputMagic, "UnsignedInteger8"];
    BinaryWrite[stream,
      {rows, columns, 1, prime, columns, 0, nonce[[1]], nonce[[2]],
        Length[payload]}, "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, payload, "UnsignedInteger64", ByteOrdering -> -1];
    Close[stream]; stream = None;
    If[FileByteCount[temporary] =!=
        8 + 8 ($cffrInputHeaderWords + Length[payload]),
      $Failed,
      RenameFile[temporary, file]; True], $Failed]];
  cffrCloseQuietly[stream];
  If[result =!= True, cffrDeleteTemporary[temporary]];
  If[result === True,
    <|"Status" -> "AffineRREFRequestWritten", "File" -> ExpandFileName[file],
      "ByteCount" -> FileByteCount[file], "Nonce" -> nonce|>,
    cffrFailure["AffineRREFRequestWriteFailed"]]
];

CFFRWriteRequest[___] := cffrFailure["InvalidRequestWriterArguments"];

cffrResponseKeys = {
  "Status", "ProtocolVersion", "Magic", "MatrixDimensions",
  "RHSColumns", "Prime", "Rank", "Nullity", "PreferenceCount",
  "Flags", "Nonce", "PayloadWords", "PivotColumns", "FreeColumns",
  "IndependentEquationRows", "NormalizationColumns",
  "ParticularSolution", "NullspaceBasis", "RowMinorInverse",
  "NormalizationMinorInverse", "WireIndexBase"};

cffrExpectedResponsePayloadWords[columns_Integer, rank_Integer,
    nullity_Integer] :=
  3 columns + nullity columns + rank^2 + nullity^2;

cffrSlice[payload_List, offset_Integer, count_Integer] :=
  If[count === 0, {}, payload[[offset + 1 ;; offset + count]]];

CFFRParseResponse[file_String, request_Association] := Module[
  {stream = None, magic, header, rows, columns, rhsColumns, prime, rank,
   nullity, preferenceCount, flags, nonceHi, nonceLo, payloadWords,
   expectedWords, expectedBytes, payload, offset = 0, pivot, free,
   independentRows, normalizationColumns, particular, nullspaceFlat,
   rowInverseFlat, normalizationInverseFlat, certificate, eof},
  If[! cffrRequestValidQ[request],
    Return[cffrFailure["InvalidAffineRREFRequest"]]];
  If[! FileExistsQ[file], Return[cffrFailure["ResponseFileMissing"]]];
  If[FileByteCount[file] < 8 + 8 $cffrOutputHeaderWords,
    Return[cffrFailure["ResponseHeaderTruncated"]]];
  stream = Quiet[Check[OpenRead[file, BinaryFormat -> True], $Failed]];
  If[stream === $Failed, Return[cffrFailure["ResponseOpenFailed"]]];
  magic = Quiet[Check[BinaryReadList[stream, "UnsignedInteger8", 8], $Failed]];
  header = Quiet[Check[BinaryReadList[stream, "UnsignedInteger64",
      $cffrOutputHeaderWords, ByteOrdering -> -1], $Failed]];
  If[magic === $Failed || header === $Failed ||
      Length[magic] =!= 8 || Length[header] =!= $cffrOutputHeaderWords,
    cffrCloseQuietly[stream]; Return[cffrFailure["ResponseHeaderReadFailed"]]];
  If[magic =!= $cffrOutputMagic,
    cffrCloseQuietly[stream]; Return[cffrFailure["ResponseMagicMismatch"]]];
  {rows, columns, rhsColumns, prime, rank, nullity, preferenceCount,
    flags, nonceHi, nonceLo, payloadWords} = header;
  If[{rows, columns} =!= request["MatrixDimensions"] || rhsColumns =!= 1 ||
      prime =!= request["Prime"] || preferenceCount =!= columns ||
      flags =!= 0 || {nonceHi, nonceLo} =!= request["Nonce"],
    cffrCloseQuietly[stream];
    Return[cffrFailure["ResponseHeaderBindingMismatch"]]];
  If[rank > Min[rows, columns] || nullity > columns ||
      rank + nullity =!= columns,
    cffrCloseQuietly[stream];
    Return[cffrFailure["ResponseRankNullityInvalid"]]];
  expectedWords = cffrExpectedResponsePayloadWords[columns, rank, nullity];
  expectedBytes = 8 + 8 $cffrOutputHeaderWords + 8 expectedWords;
  If[payloadWords =!= expectedWords,
    cffrCloseQuietly[stream];
    Return[cffrFailure["ResponsePayloadWordCountMismatch"]]];
  If[FileByteCount[file] =!= expectedBytes,
    cffrCloseQuietly[stream];
    Return[cffrFailure["ResponseExactSizeMismatch"]]];
  payload = Quiet[Check[BinaryReadList[stream, "UnsignedInteger64",
      expectedWords, ByteOrdering -> -1], $Failed]];
  eof = Quiet[Check[BinaryRead[stream, "UnsignedInteger8"], $Failed]];
  cffrCloseQuietly[stream]; stream = None;
  If[payload === $Failed || Length[payload] =!= expectedWords ||
      eof =!= EndOfFile,
    Return[cffrFailure["ResponsePayloadReadFailed"]]];
  pivot = cffrSlice[payload, offset, rank]; offset += rank;
  free = cffrSlice[payload, offset, nullity]; offset += nullity;
  independentRows = cffrSlice[payload, offset, rank]; offset += rank;
  normalizationColumns = cffrSlice[payload, offset, nullity]; offset += nullity;
  particular = cffrSlice[payload, offset, columns]; offset += columns;
  nullspaceFlat = cffrSlice[payload, offset, nullity columns];
  offset += nullity columns;
  rowInverseFlat = cffrSlice[payload, offset, rank^2]; offset += rank^2;
  normalizationInverseFlat = cffrSlice[payload, offset, nullity^2];
  offset += nullity^2;
  If[offset =!= expectedWords,
    Return[cffrFailure["ResponsePayloadPartitionMismatch"]]];
  If[! (VectorQ[pivot, IntegerQ] && Length[pivot] === rank &&
        pivot === Sort[pivot] && DuplicateFreeQ[pivot] &&
        AllTrue[pivot, 0 <= #1 < columns &] &&
        VectorQ[free, IntegerQ] && Length[free] === nullity &&
        free === Sort[free] && DuplicateFreeQ[free] &&
        AllTrue[free, 0 <= #1 < columns &] &&
        Sort[Join[pivot, free]] === Range[0, columns - 1] &&
        VectorQ[independentRows, IntegerQ] &&
        independentRows === Sort[independentRows] &&
        DuplicateFreeQ[independentRows] &&
        AllTrue[independentRows, 0 <= #1 < rows &] &&
        VectorQ[normalizationColumns, IntegerQ] &&
        normalizationColumns === Sort[normalizationColumns] &&
        DuplicateFreeQ[normalizationColumns] &&
        AllTrue[normalizationColumns, 0 <= #1 < columns &]),
    Return[cffrFailure["ResponseWireIndexStructureInvalid"]]];
  If[! AllTrue[Join[particular, nullspaceFlat, rowInverseFlat,
        normalizationInverseFlat], cffrCanonicalWordQ[#1, prime] &],
    Return[cffrFailure["ResponseNoncanonicalResidueWord"]]];
  certificate = <|
    "Status" -> "FLINTAffineRREFCertificateV1",
    "ProtocolVersion" -> $cffrProtocolVersion,
    "Magic" -> "CFFR1X1",
    "MatrixDimensions" -> {rows, columns},
    "RHSColumns" -> rhsColumns,
    "Prime" -> prime,
    "Rank" -> rank,
    "Nullity" -> nullity,
    "PreferenceCount" -> preferenceCount,
    "Flags" -> flags,
    "Nonce" -> {nonceHi, nonceLo},
    "PayloadWords" -> payloadWords,
    "PivotColumns" -> pivot + 1,
    "FreeColumns" -> free + 1,
    "IndependentEquationRows" -> independentRows + 1,
    "NormalizationColumns" -> normalizationColumns + 1,
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> If[nullity === 0, {},
      ArrayReshape[nullspaceFlat, {nullity, columns}]],
    "RowMinorInverse" -> If[rank === 0, {},
      ArrayReshape[rowInverseFlat, {rank, rank}]],
    "NormalizationMinorInverse" -> If[nullity === 0, {},
      ArrayReshape[normalizationInverseFlat, {nullity, nullity}]],
    "WireIndexBase" -> 0|>;
  If[cffrExactKeysQ[certificate, cffrResponseKeys], certificate,
    cffrFailure["ResponseSchemaConstructionFailed"]]
];

CFFRParseResponse[___] := cffrFailure["InvalidResponseParserArguments"];

cffrModRank[matrix_List, prime_Integer] := Module[
  {array = Mod[matrix, prime], rows, columns, rank = 0, column, pivot,
   pivotValue, row},
  rows = Length[array];
  If[rows === 0, Return[0]];
  If[! MatrixQ[array, IntegerQ], Return[$Failed]];
  columns = Length[First[array]];
  If[! AllTrue[array, Length[#1] === columns &], Return[$Failed]];
  For[column = 1, column <= columns && rank < rows, column++,
    pivot = SelectFirst[Range[rank + 1, rows],
      array[[#1, column]] =!= 0 &, Missing["NotFound"]];
    If[! MissingQ[pivot],
      If[pivot =!= rank + 1,
        array[[{rank + 1, pivot}]] = array[[{pivot, rank + 1}]]];
      pivotValue = PowerMod[array[[rank + 1, column]], -1, prime];
      array[[rank + 1]] = Mod[pivotValue array[[rank + 1]], prime];
      Do[If[row =!= rank + 1 && array[[row, column]] =!= 0,
        array[[row]] = Mod[array[[row]] -
          array[[row, column]] array[[rank + 1]], prime]],
        {row, rows}];
      rank++]];
  rank
];

cffrGreedyNormalizationColumns[nullspace_List, preference_List,
    nullity_Integer, prime_Integer] := Module[
  {selected = {}, currentRank = 0, candidateRank, column},
  If[nullity === 0, Return[{}]];
  Do[
    candidateRank = cffrModRank[nullspace[[All, Append[selected, column]]],
      prime];
    If[candidateRank === $Failed, Return[$Failed]];
    If[candidateRank > currentRank,
      AppendTo[selected, column]; currentRank = candidateRank];
    If[currentRank === nullity, Break[]],
    {column, preference}];
  If[currentRank === nullity, selected, $Failed]
];

cffrInverseWitnessQ[matrix_, inverse_, size_Integer, prime_Integer] :=
  If[size === 0, matrix === {} && inverse === {},
    Module[{identity = Normal[IdentityMatrix[size]]},
      (* Large IdentityMatrix expressions remain in a structured form in
         Wolfram kernels.  SameQ is representation-sensitive, so compare
         the explicit exact arrays rather than rejecting a valid inverse. *)
      cffrCanonicalMatrixQ[matrix, size, size, prime] &&
      cffrCanonicalMatrixQ[inverse, size, size, prime] &&
      Normal[Mod[matrix . inverse, prime]] === identity &&
      Normal[Mod[inverse . matrix, prime]] === identity]];

cffrCanonicalPivotOrderQ[pivot_List, free_List, nullspace_List,
    prime_Integer] := Module[{forbiddenPositions},
  If[free === {}, Return[True]];
  AllTrue[Range[Length[free]], Function[index,
    forbiddenPositions =
      Flatten[Position[pivot, value_ /; value > free[[index]]]];
    forbiddenPositions === {} ||
      AllTrue[
        Mod[nullspace[[index, pivot[[forbiddenPositions]]]], prime],
        #1 === 0 &]]]
];

CFFRVerifyCertificate[request_Association,
    certificate_Association] := Module[
  {matrix, right, preference, prime, rows, columns, rank, nullity,
   pivot, free, independentRows, normalizationColumns, particular,
   nullspace, rowInverse, normalizationInverse, rowMinor,
   normalizationMinor, derivedParticular, derivedNullspace,
   derivedVector, greedyNormalization, checks},
  If[! cffrRequestValidQ[request],
    Return[cffrFailure["InvalidAffineRREFRequest"]]];
  If[! cffrExactKeysQ[certificate, cffrResponseKeys],
    Return[cffrFailure["CertificateSchemaInvalid"]]];
  {rows, columns} = request["MatrixDimensions"];
  matrix = request["Matrix"];
  right = request["RightHandSide"];
  preference = request["Preference"];
  prime = request["Prime"];
  rank = certificate["Rank"];
  nullity = certificate["Nullity"];
  pivot = certificate["PivotColumns"];
  free = certificate["FreeColumns"];
  independentRows = certificate["IndependentEquationRows"];
  normalizationColumns = certificate["NormalizationColumns"];
  particular = certificate["ParticularSolution"];
  nullspace = certificate["NullspaceBasis"];
  rowInverse = certificate["RowMinorInverse"];
  normalizationInverse = certificate["NormalizationMinorInverse"];
  checks = <|
    "HeaderBinding" -> TrueQ[
      certificate["Status"] === "FLINTAffineRREFCertificateV1" &&
      certificate["ProtocolVersion"] === $cffrProtocolVersion &&
      certificate["Magic"] === "CFFR1X1" &&
      certificate["MatrixDimensions"] === {rows, columns} &&
      certificate["RHSColumns"] === 1 && certificate["Prime"] === prime &&
      certificate["PreferenceCount"] === columns &&
      certificate["Flags"] === 0 &&
      certificate["Nonce"] === request["Nonce"] &&
      certificate["PayloadWords"] ===
        cffrExpectedResponsePayloadWords[columns, rank, nullity] &&
      certificate["WireIndexBase"] === 0],
    "RankNullity" -> TrueQ[
      IntegerQ[rank] && IntegerQ[nullity] &&
      0 <= rank <= Min[rows, columns] && 0 <= nullity <= columns &&
      rank + nullity === columns],
    "PivotFreePartition" -> TrueQ[
      VectorQ[pivot, IntegerQ] && VectorQ[free, IntegerQ] &&
      Length[pivot] === rank && Length[free] === nullity &&
      pivot === Sort[pivot] && free === Sort[free] &&
      DuplicateFreeQ[pivot] && DuplicateFreeQ[free] &&
      Sort[Join[pivot, free]] === Range[columns]],
    "IndependentRowsShape" -> TrueQ[
      VectorQ[independentRows, IntegerQ] && Length[independentRows] === rank &&
      independentRows === Sort[independentRows] &&
      DuplicateFreeQ[independentRows] &&
      AllTrue[independentRows, 1 <= #1 <= rows &]],
    "NormalizationColumnsShape" -> TrueQ[
      VectorQ[normalizationColumns, IntegerQ] &&
      Length[normalizationColumns] === nullity &&
      normalizationColumns === Sort[normalizationColumns] &&
      DuplicateFreeQ[normalizationColumns] &&
      AllTrue[normalizationColumns, 1 <= #1 <= columns &]],
    "PayloadShapesAndWords" -> TrueQ[
      VectorQ[particular, cffrCanonicalWordQ[#1, prime] &] &&
      Length[particular] === columns &&
      cffrCanonicalMatrixQ[nullspace, nullity, columns, prime] &&
      cffrCanonicalMatrixQ[rowInverse, rank, rank, prime] &&
      cffrCanonicalMatrixQ[normalizationInverse, nullity, nullity, prime]]|>;
  If[! AllTrue[Values[checks], TrueQ],
    Return[cffrFailure["CertificateStructuralVerificationFailed",
      <|"Checks" -> checks|>]]];
  rowMinor = If[rank === 0, {}, matrix[[independentRows, pivot]]];
  normalizationMinor = If[nullity === 0, {},
    nullspace[[All, normalizationColumns]]];
  derivedParticular = ConstantArray[0, columns];
  If[rank > 0,
    derivedParticular[[pivot]] = Mod[rowInverse . right[[independentRows]], prime]];
  derivedNullspace = Table[
    derivedVector = ConstantArray[0, columns];
    derivedVector[[free[[index]]]] = 1;
    If[rank > 0,
      derivedVector[[pivot]] = Mod[-rowInverse .
        matrix[[independentRows, free[[index]]]], prime]];
    derivedVector,
    {index, nullity}];
  greedyNormalization = cffrGreedyNormalizationColumns[
    nullspace, preference, nullity, prime];
  checks = Join[checks, <|
    "AffineResidual" -> TrueQ[
      Mod[matrix . particular - right, prime] === ConstantArray[0, rows]],
    "NullspaceResidual" -> TrueQ[
      nullity === 0 || Mod[matrix . Transpose[nullspace], prime] ===
        ConstantArray[0, {rows, nullity}]],
    "CanonicalFreeIdentity" -> TrueQ[
      nullity === 0 || nullspace[[All, free]] === IdentityMatrix[nullity]],
    "CanonicalParticularFreeZero" -> TrueQ[
      particular[[free]] === ConstantArray[0, nullity]],
    "CanonicalPivotOrder" -> TrueQ[
      cffrCanonicalPivotOrderQ[pivot, free, nullspace, prime]],
    "RowMinorInverseWitness" -> TrueQ[
      cffrInverseWitnessQ[rowMinor, rowInverse, rank, prime]],
    "DerivedCanonicalParticular" -> TrueQ[particular === derivedParticular],
    "DerivedCanonicalNullspace" -> TrueQ[nullspace === derivedNullspace],
    "NormalizationMinorInverseWitness" -> TrueQ[
      cffrInverseWitnessQ[normalizationMinor, normalizationInverse,
        nullity, prime]],
    "PreferenceGreedyNormalization" -> TrueQ[
      ListQ[greedyNormalization] &&
      Sort[greedyNormalization] === normalizationColumns]
    |>];
  If[AllTrue[Values[checks], TrueQ],
    <|"Status" -> "VerifiedFLINTAffineRREFCertificate",
      "Checks" -> checks, "Certificate" -> certificate,
      "GreedyNormalizationColumnsInPreferenceOrder" -> greedyNormalization|>,
    cffrFailure["CertificateAlgebraicVerificationFailed",
      <|"Checks" -> checks|>]]
];

CFFRVerifyCertificate[___] :=
  cffrFailure["InvalidCertificateVerifierArguments"];

cffrStableFingerprint[value_] :=
  Hash[ToString[InputForm[value]], "SHA256", "HexString"];

cffrModRational[value_, prime_Integer] := Module[{numerator, denominator},
  If[! (IntegerQ[value] || Head[value] === Rational), Return[$Failed]];
  numerator = Numerator[value];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

CFFRConstructCrossPrimePlanV1[preparation_Association,
    sample_Association, seed_Integer, request_Association,
    certificate_Association] := Module[
  {verification, requiredPreparation, requiredSample, support,
   numeratorDegrees, acceptedPointDimensions, payload, plan},
  verification = CFFRVerifyCertificate[request, certificate];
  If[Lookup[verification, "Status", None] =!=
      "VerifiedFLINTAffineRREFCertificate",
    Return[cffrFailure["PlanCertificateVerificationFailed"]]];
  requiredPreparation = {"ABIFingerprint", "RootOrderingFingerprint",
    "UnknownCount", "GaugeUnknownCount", "ResidueUnknownCount",
    "GaugeSupport", "GaugeDenominatorDegrees", "EquationsPerPoint",
    "Normalizations"};
  requiredSample = {"MatrixDimensions", "AcceptedPoints",
    "NormalizationCount", "BranchFlipMask", "Prime", "EpsilonValue",
    "Matrix", "RightHandSide"};
  If[! AllTrue[requiredPreparation, KeyExistsQ[preparation, #1] &] ||
      ! AllTrue[requiredSample, KeyExistsQ[sample, #1] &],
    Return[cffrFailure["PlanMetadataMissing"]]];
  support = preparation["GaugeSupport"];
  If[! MatrixQ[support, IntegerQ] || support === {} ||
      ! AllTrue[support, Length[#1] === 2 &] || Min[Flatten[support]] < 0,
    Return[cffrFailure["PlanGaugeSupportInvalid"]]];
  numeratorDegrees = Max /@ Transpose[support];
  acceptedPointDimensions = Dimensions[sample["AcceptedPoints"]];
  If[sample["MatrixDimensions"] =!= request["MatrixDimensions"] ||
      sample["Prime"] =!= request["Prime"] ||
      request["Matrix"] =!= Mod[Normal[sample["Matrix"]], request["Prime"]] ||
      request["RightHandSide"] =!=
        Mod[sample["RightHandSide"], request["Prime"]] ||
      sample["BranchFlipMask"] =!= 0 ||
      ! StringQ[preparation["ABIFingerprint"]] ||
      ! StringQ[preparation["RootOrderingFingerprint"]] ||
      preparation["UnknownCount"] =!= request["MatrixDimensions"][[2]] ||
      ! IntegerQ[preparation["GaugeUnknownCount"]] ||
      preparation["GaugeUnknownCount"] < 0 ||
      ! IntegerQ[preparation["ResidueUnknownCount"]] ||
      preparation["ResidueUnknownCount"] < 0 ||
      preparation["GaugeUnknownCount"] + preparation["ResidueUnknownCount"] =!=
        preparation["UnknownCount"] ||
      request["Preference"] =!= Join[
        preparation["GaugeUnknownCount"] +
          Range[preparation["ResidueUnknownCount"]],
        Range[preparation["GaugeUnknownCount"]]] ||
      ! MatchQ[preparation["GaugeDenominatorDegrees"], {_Integer, _Integer}] ||
      Min[preparation["GaugeDenominatorDegrees"]] < 0 ||
      ! IntegerQ[preparation["EquationsPerPoint"]] ||
      preparation["EquationsPerPoint"] < 1 ||
      ! ListQ[preparation["Normalizations"]] ||
      sample["NormalizationCount"] =!= Length[preparation["Normalizations"]] ||
      ! MatrixQ[sample["AcceptedPoints"], IntegerQ] ||
      ! MatchQ[acceptedPointDimensions, {_Integer, 2}] ||
      acceptedPointDimensions[[1]] < 1 ||
      sample["MatrixDimensions"][[1]] =!=
        Length[sample["AcceptedPoints"]] preparation["EquationsPerPoint"] +
          sample["NormalizationCount"] ||
      ! AllTrue[Flatten[sample["AcceptedPoints"]],
        2 <= #1 <= request["Prime"] - 2 &] ||
      Mod[request["Prime"], 4] =!= 3 ||
      cffrModRational[sample["EpsilonValue"], request["Prime"]] === $Failed ||
      cffrModRational[sample["EpsilonValue"], request["Prime"]] === 0,
    Return[cffrFailure["PlanMetadataBindingMismatch"]]];
  payload = <|
    "Status" -> "CrossPrimeEliminationPlanV1",
    "PlanVersion" -> 1,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"],
    "MatrixDimensions" -> sample["MatrixDimensions"],
    "PointCount" -> Length[sample["AcceptedPoints"]],
    "NormalizationEquationCount" -> sample["NormalizationCount"],
    "BranchFlipMask" -> sample["BranchFlipMask"],
    "IndependentEquationRows" -> certificate["IndependentEquationRows"],
    "NormalizationColumns" -> certificate["NormalizationColumns"],
    "GenericRank" -> certificate["Rank"],
    "Nullity" -> certificate["Nullity"],
    "UnknownCount" -> preparation["UnknownCount"],
    "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
    "FreeResidueCount" -> preparation["ResidueUnknownCount"],
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeDenominatorDegrees" -> preparation["GaugeDenominatorDegrees"],
    "GaugeSupport" -> support,
    "PilotPrime" -> sample["Prime"],
    "PilotEpsilonValue" -> sample["EpsilonValue"],
    "PilotRandomSeed" -> seed,
    "PilotAcceptedPoints" -> sample["AcceptedPoints"],
    "PilotPivotColumns" -> certificate["PivotColumns"],
    "PilotFreeColumns" -> certificate["FreeColumns"],
    "DiscoveryMethod" ->
      "CanonicalRREFPlusProductionPlanDiscovery"|>;
  plan = Append[payload, "PlanFingerprint" -> cffrStableFingerprint[payload]];
  If[KeyTake[plan, $cffrPlanPayloadKeys] === payload,
    plan, cffrFailure["PlanPayloadConstructionFailed"]]
];

CFFRConstructCrossPrimePlanV1[___] :=
  cffrFailure["InvalidPlanConstructorArguments"];

CFFRRun[binary_String, request_Association, threads_Integer: 1,
    keepDirectory_: False, timeoutSeconds_Integer: 3600] := Module[
  {directory, input, output, writeResult, process, parsed, verified,
   result},
  If[! cffrRequestValidQ[request],
    Return[cffrFailure["InvalidAffineRREFRequest"]]];
  If[! FileExistsQ[binary], Return[cffrFailure["AffineRREFBinaryMissing"]]];
  If[! (1 <= threads <= 64) || ! BooleanQ[keepDirectory] ||
      ! (1 <= timeoutSeconds <= 86400),
    Return[cffrFailure["AffineRREFRunOptionsInvalid"]]];
  directory = Quiet[Check[CreateDirectory[], $Failed]];
  If[! StringQ[directory] || ! DirectoryQ[directory],
    Return[cffrFailure["AffineRREFTemporaryDirectoryFailed"]]];
  input = FileNameJoin[{directory, "request.bin"}];
  output = FileNameJoin[{directory, "response.bin"}];
  writeResult = CFFRWriteRequest[input, request];
  If[Lookup[writeResult, "Status", None] =!= "AffineRREFRequestWritten",
    Quiet[DeleteDirectory[directory, DeleteContents -> True]];
    Return[cffrFailure["AffineRREFRequestStagingFailed"]]];
  process = TimeConstrained[
    Quiet[Check[
      RunProcess[{ExpandFileName[binary], input, output, ToString[threads]}],
      $Failed]], timeoutSeconds, $Aborted];
  If[! AssociationQ[process] || Lookup[process, "ExitCode", -1] =!= 0,
    result = If[AssociationQ[process] &&
        Lookup[process, "ExitCode", -1] === $cffrInconsistentExitCode,
      cffrFailure["InconsistentAffineImage", <|
        "ExitCode" -> $cffrInconsistentExitCode,
        "FailureClass" -> "MathematicalImageInconsistency",
        "RetryableWithDifferentImage" -> True|>],
      cffrFailure["AffineRREFProcessFailed", <|
        "ExitCode" -> If[AssociationQ[process],
          Lookup[process, "ExitCode", Missing["ExitCode"]],
          Missing["ProcessFailed"]],
        "FailureClass" -> "ProcessOrProtocolFailure",
        "RetryableWithDifferentImage" -> False|>]];
    If[! keepDirectory, Quiet[DeleteDirectory[directory, DeleteContents -> True]]];
    Return[If[keepDirectory, Append[result, "ArtifactDirectory" -> directory],
      result]]];
  parsed = CFFRParseResponse[output, request];
  If[Lookup[parsed, "Status", None] =!= "FLINTAffineRREFCertificateV1",
    result = cffrFailure["AffineRREFResponseRejected",
      <|"ParseStatus" -> Lookup[parsed, "Status", None]|>],
    verified = CFFRVerifyCertificate[request, parsed];
    result = If[Lookup[verified, "Status", None] ===
        "VerifiedFLINTAffineRREFCertificate",
      <|"Status" -> "VerifiedFLINTAffineRREFRun",
        "Certificate" -> parsed, "Verification" -> verified,
        "ExitCode" -> process["ExitCode"]|>,
      cffrFailure["AffineRREFCertificateRejected",
        <|"Verification" -> verified|>]]];
  If[keepDirectory,
    Join[result, <|"ArtifactDirectory" -> directory,
      "RequestFile" -> input, "ResponseFile" -> output|>],
    Quiet[DeleteDirectory[directory, DeleteContents -> True]]; result]
];

CFFRRun[___] := cffrFailure["InvalidAffineRREFRunArguments"];

End[];
EndPackage[];
