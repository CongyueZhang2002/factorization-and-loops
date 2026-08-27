BeginPackage["CodexAffineInconsistencyWitness`", {
  "CodexFLINTAffineRREFAdapter`"}];

AIWConstruct::usage =
  "AIWConstruct[A,b,p,adapterSource,binary,threads,nonce] certifies a normalized left inconsistency witness y over F_p by solving A^T y=0 and b^T y=1 with the pinned native affine solver.";

AIWScoreColumns::usage =
  "AIWScoreColumns[witness,C] computes y^T C. An all-zero score is a rigorous certificate that adding C cannot repair the witnessed affine inconsistency; a nonzero score is only a necessary screen.";

Begin["`Private`"];

ClearAll[aiwFailure, aiwFingerprint, aiwCanonicalMatrixQ,
  aiwCanonicalVectorQ];

$aiwExpectedAdapterSHA256 =
  "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605";
$aiwExpectedNativeBinarySHA256 =
  "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5";

aiwFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "AffineInconsistencyWitnessFailure",
    "FailureReason" -> reason|>, data];

aiwFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

aiwCanonicalMatrixQ[matrix_, rows_Integer, columns_Integer,
    prime_Integer] := TrueQ[
  MatrixQ[matrix, IntegerQ] && Dimensions[matrix] === {rows, columns} &&
  AllTrue[Flatten[Normal[matrix]], 0 <= #1 < prime &]];

aiwCanonicalVectorQ[vector_List, length_Integer,
    prime_Integer] := TrueQ[
  Length[vector] === length && VectorQ[vector, IntegerQ] &&
  AllTrue[vector, 0 <= #1 < prime &]];

AIWConstruct[matrix_?MatrixQ, right_List, prime_Integer,
    adapterSource_String, nativeBinary_String, threads_Integer: 1,
    nonce : {_Integer, _Integer}] := Module[
  {dimensions, rows, columns, adapterHash,
   nativeHash, canonicalMatrix, canonicalRight, dualMatrix,
   dualRight, request, run, certificate, witness, leftResidual,
   rightPairing},
  dimensions = Dimensions[matrix];
  If[! MatchQ[dimensions, {_Integer, _Integer}] ||
      Min[dimensions] < 1 || ! PrimeQ[prime] ||
      ! (1 <= threads <= 8) || nonce === {0, 0},
    Return[aiwFailure["InvalidWitnessArguments"]]];
  {rows, columns} = dimensions;
  canonicalMatrix = SparseArray[Mod[matrix, prime]];
  canonicalRight = Mod[right, prime];
  If[! aiwCanonicalMatrixQ[canonicalMatrix, rows, columns, prime] ||
      ! aiwCanonicalVectorQ[canonicalRight, rows, prime],
    Return[aiwFailure["InvalidAffineImage"]]];
  adapterHash = If[StringQ[adapterSource] && FileExistsQ[adapterSource],
    FileHash[adapterSource, "SHA256", "HexString"], $Failed];
  nativeHash = If[FileExistsQ[nativeBinary],
    FileHash[nativeBinary, "SHA256", "HexString"], $Failed];
  If[adapterHash =!= $aiwExpectedAdapterSHA256 ||
      nativeHash =!= $aiwExpectedNativeBinarySHA256,
    Return[aiwFailure["PinnedNativeRuntimeMismatch", <|
      "AdapterSHA256" -> adapterHash,
      "NativeBinarySHA256" -> nativeHash|>]]];

  (* Fredholm alternative over F_p: b is outside Col[A] exactly when
     this normalized dual system has a solution. *)
  dualMatrix = SparseArray[Join[
    Transpose[canonicalMatrix], {canonicalRight}]];
  dualRight = Join[ConstantArray[0, columns], {1}];
  request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
    dualMatrix, dualRight, prime, Range[rows], nonce];
  If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
    Return[aiwFailure["NativeWitnessRequestInvalid"]]];
  run = CodexFLINTAffineRREFAdapter`CFFRRun[
    nativeBinary, request, threads, False, 600];
  If[Lookup[run, "Status", None] =!=
      "VerifiedFLINTAffineRREFRun",
    Return[aiwFailure["NativeWitnessSolveFailed", <|
      "NativeRun" -> KeyDrop[run, {"Certificate"}]|>]]];
  certificate = run["Certificate"];
  witness = certificate["ParticularSolution"];
  leftResidual = Mod[Transpose[canonicalMatrix].witness, prime];
  rightPairing = Mod[canonicalRight.witness, prime];
  If[! aiwCanonicalVectorQ[witness, rows, prime] ||
      leftResidual =!= ConstantArray[0, columns] ||
      rightPairing =!= 1,
    Return[aiwFailure["NativeWitnessResidualFailed"]]];
  <|"Status" -> "CertifiedAffineLeftInconsistencyWitnessV1",
    "Prime" -> prime, "MatrixDimensions" -> dimensions,
    "WitnessLength" -> rows, "Witness" -> witness,
    "WitnessFingerprint" -> aiwFingerprint[witness],
    "MatrixFingerprint" -> Hash[canonicalMatrix,
      "SHA256", "HexString"],
    "RightHandSideFingerprint" -> Hash[canonicalRight,
      "SHA256", "HexString"],
    "LeftResidualZero" -> True, "RightPairing" -> 1,
    "NativeThreads" -> threads, "RequestNonce" -> nonce,
    "NativeCertificateRank" -> certificate["Rank"],
    "NativeCertificateNullity" -> certificate["Nullity"],
    "NativePivotFingerprint" ->
      aiwFingerprint[certificate["PivotColumns"]],
    "NativeFreeColumnFingerprint" ->
      aiwFingerprint[certificate["FreeColumns"]]|>
];

AIWConstruct[___] := aiwFailure["InvalidWitnessArguments"];

AIWScoreColumns[witness_Association,
    candidateColumns_?MatrixQ] := Module[
  {prime, vector, rows, columns, canonicalCandidates, scores,
   activeColumns},
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    Return[aiwFailure["InvalidCertifiedWitness"]]];
  prime = witness["Prime"];
  vector = witness["Witness"];
  rows = witness["WitnessLength"];
  If[! MatchQ[Dimensions[candidateColumns],
      {rows, columns_Integer /; columns >= 1}],
    Return[aiwFailure["CandidateColumnShapeMismatch"]]];
  columns = Dimensions[candidateColumns][[2]];
  canonicalCandidates = SparseArray[Mod[candidateColumns, prime]];
  If[! aiwCanonicalMatrixQ[
      canonicalCandidates, rows, columns, prime],
    Return[aiwFailure["CandidateColumnsInvalid"]]];
  scores = Developer`ToPackedArray[
    Mod[vector.canonicalCandidates, prime]];
  activeColumns = Flatten[Position[scores, Except[0]]];
  <|"Status" -> "AffineWitnessCandidateColumnScoreV1",
    "Prime" -> prime, "WitnessFingerprint" ->
      witness["WitnessFingerprint"],
    "CandidateMatrixDimensions" -> {rows, columns},
    "CandidateMatrixFingerprint" -> Hash[canonicalCandidates,
      "SHA256", "HexString"],
    "ScoreFingerprint" -> aiwFingerprint[scores],
    "NonzeroScoreCount" -> Length[activeColumns],
    "NonzeroScoreColumns" -> activeColumns,
    "AllScoresZero" -> (activeColumns === {}),
    "Conclusion" -> If[activeColumns === {},
      "CertifiedCandidateBlockCannotRepairThisAffineImage",
      "NecessaryScreenPassedButFullRankTestStillRequired"]|>
];

AIWScoreColumns[___] := aiwFailure["InvalidColumnScoreArguments"];

End[];
EndPackage[];
