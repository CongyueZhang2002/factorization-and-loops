$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repositoryRoot = DirectoryName[scriptDirectory, 3];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];
sourcePath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303PhysicalSoftSixSystem.wl"}];
outputPath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303SixModeEndpointFrame.wl"}];
source = Get[sourcePath];
If[Lookup[source, "Status", "Missing"] =!= "CF303PhysicalSoftSixSystemExactV1",
  Print["FAIL source status"]; Quit[2]];

recordsToMatrix[records_, field_] := Normal[SparseArray[
  ({#Row, #Column} -> Lookup[#, field, 0]) & /@ records, {6, 6}]];
bParallel = recordsToMatrix[source["Homogeneous"]["Tangential"], "Finite"];
normalResidue = Normal[SparseArray[
  ({#Row, #Column} -> Lookup[#Principal, -1, 0]) & /@
    source["Homogeneous"]["Normal"], {6, 6}]];

frameTiming = AbsoluteTiming[
  nonzeroEigenvalue = -2*(1 + 2*eps);
  spectralProjector = Map[Cancel[Together[#]] &,
    normalResidue/nonzeroEigenvalue, {2}];
  kernelMixing = (2 + 5*eps)/(2*p^2);
  modeFrame = Transpose[{
    {1, 0, 0, 0, 0, 0},
    {0, 1, 0, 0, 0, 0},
    {0, 0, 1, kernelMixing, 0, 0},
    {0, 0, 0, 0, 1, 0},
    {0, 0, 0, 0, 0, 1},
    {0, 0, 0, 1, 0, -1/p^2}}];
  levelt = BuildEndpointLeveltModeConnection[normalResidue, bParallel,
    <|"TangentialVariable" -> p, "Regulator" -> eps,
      "ModeFrame" -> modeFrame,
      "LocalExponents" -> {0, 0, 0, 0, 0, nonzeroEigenvalue}|>];
  If[Lookup[levelt, "Status", "Failure"] =!=
      "EndpointLeveltModeConnectionBuilt",
    Print["FAIL Levelt API ", InputForm[levelt]]; Quit[3]];
  modeFrameInverse = levelt["InverseModeFrame"];
  residueInModeFrame = levelt["NormalResidueInModeFrame"];
  gamma = levelt["TangentialConnection"];
];
frameSeconds = First[frameTiming];

(* The accepted final-block physical gauge is small enough to keep exactly.
   In the convention I25=T25.F25 it changes only the two zero-exponent target
   modes, so it cannot mix the normal eigenspaces. *)
targetGauge = {
  {(-2 - 3*eps)/(4*(p - 1)^2*p^4*(p + 1)^2),
    (2 + 3*eps)*(2 + p)/(8*(p - 1)^2*p^4*(p + 1)^2)},
  {(-2 - 7*eps - 6*eps^2)/(4*(p - 1)^3*p^4*(p + 1)^3),
    (2 + 9*eps + 9*eps^2 + 8*p + 28*eps*p + 24*eps^2*p +
       2*p^2 + 5*eps*p^2 + 3*eps^2*p^2)/
      (16*(p - 1)^3*p^5*(p + 1)^3)}};
targetGaugeInverse = Map[Cancel[Together[#]] &, Inverse[targetGauge], {2}];
acceptedCoordinateGauge = IdentityMatrix[6];
acceptedCoordinateGauge[[4 ;; 5, 4 ;; 5]] = targetGauge;
acceptedModeFrame = modeFrame . acceptedCoordinateGauge;
acceptedLevelt = BuildEndpointLeveltModeConnection[normalResidue, bParallel,
  <|"TangentialVariable" -> p, "Regulator" -> eps,
    "ModeFrame" -> acceptedModeFrame,
    "LocalExponents" -> {0, 0, 0, 0, 0, nonzeroEigenvalue}|>];
If[Lookup[acceptedLevelt, "Status", "Failure"] =!=
    "EndpointLeveltModeConnectionBuilt",
  Print["FAIL accepted target Levelt API ", InputForm[acceptedLevelt]];
  Quit[3]];
acceptedGamma = acceptedLevelt["TangentialConnection"];
targetEpsilonConnection = eps*{
  {-(-3 - 2*p + 6*p^2)/((p - 1)*p*(p + 1)),
    (-1 + 4*p)/(2*(p - 1)*(p + 1))},
  {2/((p - 1)*(p + 1)),
    -(-3 + 2*p + 4*p^2)/((p - 1)*p*(p + 1))}};
targetGPLCouplings = <|
  "InvP" -> {{-3, 0}, {0, -3}},
  "InvOneMinusP" -> {{1/2, -3/4}, {-1, 3/2}},
  "InvOnePlusP" -> {{-5/2, 5/4}, {-1, 1/2}}|>;

(* Remove the integer normal exponent and the eps-independent tangential
   prefactor of the isolated nonzero mode.  If J6 is the mode above, use
   J6=rho^-2 R6 K6; then K6 is in epsilon form in both directions. *)
normalIntegerShearPower = -2;
shiftedNormalExponent = nonzeroEigenvalue - normalIntegerShearPower;
nonzeroTangentialPrefactor =
  1/((1 - p^2)*(1 - 2*p^2)^2);
epsilonNormalizedNonzeroConnection =
  eps*(4/p + 16*p/(1 - 2*p^2));
nonzeroNormalizationResidual = Cancel[Together[
  gamma[[6, 6]] - D[Log[nonzeroTangentialPrefactor], p] -
    epsilonNormalizedNonzeroConnection]];

(* Compact source gauges.  The regular block-24 gauge is a simple rational
   representative; its p-independent right binding identifies it exactly
   with the rho^0 slice of TDiagonal.S in accepted canonical coordinates. *)
block24BaseGauge = {
  {1/(p^2*(p^2 - 1)), 0},
  {1/(p^2*(p^2 - 1)), 1/(p^3*(p^2 - 1))}};
block24SourceGauge = block24BaseGauge .
  {{1, 0}, {p*eps*(3 + 4*eps)/(1 + eps), 1}};
canonicalPolynomial = -2 + 13*eps - 27*eps^2 + 18*eps^3;
acceptedBlock24Gauge = {
  {-3*canonicalPolynomial/(2*eps^3*(p - 1)*p^2*(p + 1)),
    3*canonicalPolynomial/(8*eps^3*(p - 1)*p^2*(p + 1))},
  {-3*(1 + 2*eps)^2*canonicalPolynomial/
      (2*eps^3*(1 + eps)*(p - 1)*p^2*(p + 1)),
    3*(1 + 2*eps)*canonicalPolynomial*(-1 - 4*eps + 2*p +
       4*eps*p)/(16*eps^3*(1 + eps)*(p - 1)*p^3*(p + 1))}};
block24AcceptedBinding = Map[Cancel[Together[#]] &,
  Inverse[block24SourceGauge] . acceptedBlock24Gauge, {2}];
block23ZeroGauge = 1/(p^4*(p^2 - 1));
block23ZeroAcceptedNormalization =
  -7*canonicalPolynomial*(1 + 5*eps)/(4*eps^3*(1 + 4*eps));
block23NonzeroAcceptedExtension =
  -14*canonicalPolynomial/(eps^3*(2 + 3*eps));
block23NonzeroBaseNormalization =
  14*(1 + 4*eps)*canonicalPolynomial/eps^3;
block23NonzeroExtensionInBaseFrame = Cancel[Together[
  block23NonzeroAcceptedExtension/block23NonzeroBaseNormalization]];
productionCoordinateGauge = IdentityMatrix[6];
productionCoordinateGauge[[1 ;; 2, 1 ;; 2]] = block24SourceGauge;
productionCoordinateGauge[[3, 3]] = block23ZeroGauge;
productionCoordinateGauge[[4 ;; 5, 4 ;; 5]] = targetGauge;
productionCoordinateGauge[[6, 6]] = nonzeroTangentialPrefactor;
productionModeFrame = modeFrame . productionCoordinateGauge;
productionLevelt = BuildEndpointLeveltModeConnection[normalResidue, bParallel,
  <|"TangentialVariable" -> p, "Regulator" -> eps,
    "ModeFrame" -> productionModeFrame,
    "LocalExponents" -> {0, 0, 0, 0, 0, nonzeroEigenvalue}|>];
If[Lookup[productionLevelt, "Status", "Failure"] =!=
    "EndpointLeveltModeConnectionBuilt",
  Print["FAIL production Levelt API ", InputForm[productionLevelt]];
  Quit[3]];
productionGamma = productionLevelt["TangentialConnection"];
productionSourceIndices = {1, 2, 3, 6};
productionSourceConnection =
  productionGamma[[productionSourceIndices, productionSourceIndices]];
productionSourceLetters = {
  {"GPLPole", 0}, {"GPLFactor", 1 - 2*p^2, 1}};
productionSourceResidues = {
  DiagonalMatrix[{-2, -2, -8, 4}],
  DiagonalMatrix[{0, 0, 0, 16}]};
productionSourceSelectors = ConstantArray[0, {4, 6}];
Do[productionSourceSelectors[[index, index]] = 1, {index, 4}];
productionTargetSelectors = {
  {0, 0, 0, 0, 1, 0},
  {0, 0, 0, 0, 0, 1}};
productionSource = <|
  "Dimension" -> 4,
  "Letters" -> productionSourceLetters,
  "Residues" -> productionSourceResidues,
  "BoundarySelectors" -> <|0 -> productionSourceSelectors|>|>;
productionTargetDiagonal = {
  {{"GPLPole", 0}, targetGPLCouplings["InvP"]},
  {{"GPLPole", 1}, -targetGPLCouplings["InvOneMinusP"]},
  {{"GPLPole", -1}, targetGPLCouplings["InvOnePlusP"]}};
productionIncomingRecord[target_, sourceIndex_] := Module[{value},
  value = productionGamma[[target + 3,
    productionSourceIndices[[sourceIndex]]]];
  value = Cancel[Together[value]];
  If[value === 0, Nothing,
    <|"Row" -> target, "Column" -> sourceIndex,
      "Coefficient" -> Cancel[Together[p*value]],
      "Letter" -> {"GPLPole", 0}|>]
];
productionIncoming = Flatten[Table[
  productionIncomingRecord[target, sourceIndex],
  {target, 2}, {sourceIndex, Length[productionSourceIndices]}]];
productionLayer = <|
  "Rows" -> {44, 45}, "PathVariable" -> p, "Regulator" -> eps,
  "BasePoint" -> 4/11, "Endpoint" -> pFinal,
  "Diagonal" -> productionTargetDiagonal,
  "Incoming" -> productionIncoming,
  "ZeroColumns" -> {4},
  "TargetBoundarySelectors" -> <|0 -> productionTargetSelectors|>,
  "SharedBoundaryCoordinates" -> True|>;
productionPrepare = BuildRationalEpsilonLayerTransport[
  productionSource, productionLayer, <|"Pairs" -> {{0, 1}, {0, 2}}|>,
  "PrepareOnly" -> True];
productionDemand = <|"Pairs" -> {{0, 1}, {0, 2}}|>;
productionTransportTiming = AbsoluteTiming[
  productionTransport = BuildRationalEpsilonLayerTransport[
    productionSource, productionLayer, productionDemand,
    "PrimeCount" -> 3, "WordRepresentation" -> "LazyOperator"]];
productionTransportSeconds = First[productionTransportTiming];
productionTransportPredicate = AcceptedRationalEpsilonLayerTransportQ[
  productionTransport, productionSource, productionLayer, productionDemand];
productionOperatorTiming = AbsoluteTiming[
  productionOperator = BuildRationalEpsilonLayerOperator[
    productionSource, productionLayer, productionTransport]];
productionOperatorSeconds = First[productionOperatorTiming];
productionCertificate = Lookup[productionTransport, "Certificate", <||>];
productionGaugeFunctions = Lookup[productionTransport,
  "GaugeFunctions", <||>];
productionGaugeNonzeros = Total[
  Length[SparseArray[#]["NonzeroPositions"]] & /@
    Values[productionGaugeFunctions]];

(* Exact local map from the six production mode coefficients to the accepted
   z-path coordinates at the soft junction.  This is not yet the rebase from
   z=1/2: that requires a tangentially regularized inverse of the accepted
   z-path operator. *)
acceptedSourceStateRows = Join[Range[22], {26, 27}, Range[29, 36],
  Range[39, 43], {23, 24, 25, 28, 37, 38}];
productionToAcceptedBlock24 = Map[Cancel[Together[#]] &,
  Inverse[block24AcceptedBinding], {2}];
acceptedJunctionSourceMap = ConstantArray[0, {43, 6}];
acceptedJunctionSourceMap[[{36, 37}, {1, 2}]] =
  productionToAcceptedBlock24;
acceptedJunctionSourceMap[[34, 3]] =
  1/block23ZeroAcceptedNormalization;
acceptedJunctionSourceMap[[{34, 35}, 4]] =
  {1, -2}/block23NonzeroBaseNormalization;
acceptedJunctionSourceMap = Map[Cancel[Together[#]] &,
  acceptedJunctionSourceMap, {2}];
independentTargetF25Map = {
  {0, 0, 0, 0, 1, 0},
  {0, 0, 0, 0, 0, 1}};
knownG25NormalExtension = {
  {0, 0, 0, block23NonzeroExtensionInBaseFrame, 0, 0},
  {0, 0, 0, block23NonzeroExtensionInBaseFrame, 0, 0}};

kernelNames = {"InvP", "InvOneMinusP", "InvOnePlusP", "InvP3",
  "InvP5", "P", "QuadraticDLog"};
kernels = {1/p, 1/(1 - p), 1/(1 + p), 1/p^3, 1/p^5, p,
  p/(1 - 2*p^2)};
kernelTypes = {"GPL", "GPL", "GPL", "ExactDerivative",
  "ExactDerivative", "ExactDerivative", "GPLQuadraticDLog"};
kernelPrimitives = {Log[p], -Log[1 - p], Log[1 + p], -1/(2*p^2),
  -1/(4*p^4), p^2/2, -Log[1 - 2*p^2]/4};
samplePoints = {2, 3, 4, 5, 6, 7, 8};
evaluationInverse = Inverse[Table[kernels[[column]] /. p -> samplePoints[[row]],
  {row, Length[samplePoints]}, {column, Length[kernels]}]];

decompositionTiming = AbsoluteTiming[
  couplingMatrices = ConstantArray[0, {Length[kernels], 6, 6}];
  Do[
    samples = gamma[[row, column]] /. p -> # & /@ samplePoints;
    coefficients = Map[Cancel[Together[#]] &, evaluationInverse . samples];
    Do[couplingMatrices[[kernel, row, column]] = coefficients[[kernel]],
      {kernel, Length[kernels]}],
    {row, 6}, {column, 6}];
  recomposed = Sum[kernels[[kernel]]*couplingMatrices[[kernel]],
    {kernel, Length[kernels]}];
  decompositionResidual = Map[Cancel[Together[#]] &, gamma - recomposed, {2}];
];
decompositionSeconds = First[decompositionTiming];

matrixEntries[matrix_] := Reap[Do[
  If[matrix[[row, column]] =!= 0,
    Sow[<|"Row" -> row, "Column" -> column,
      "Value" -> matrix[[row, column]]|>]],
  {row, Length[matrix]}, {column, Length[First[matrix]]}]][[2]] /. {
    {} -> {}, {entries_} :> entries};
kernelRecords = Table[
  <|"Name" -> kernelNames[[kernel]], "Kernel" -> kernels[[kernel]],
    "Type" -> kernelTypes[[kernel]],
    "Primitive" -> kernelPrimitives[[kernel]],
    "Couplings" -> matrixEntries[couplingMatrices[[kernel]]]|>,
  {kernel, Length[kernels]}];
allCouplings = Flatten[Lookup[kernelRecords, "Couplings"]];
epsilonDegrees = If[allCouplings === {}, {},
  ({Exponent[Numerator[Together[#Value]], eps],
      Exponent[Denominator[Together[#Value]], eps]} &) /@ allCouplings];
crossToNonzero = gamma[[1 ;; 5, {6}]];
crossFromNonzero = gamma[[{6}, 1 ;; 5]];
acceptedCrossToNonzero = acceptedGamma[[1 ;; 5, {6}]];
acceptedCrossFromNonzero = acceptedGamma[[{6}, 1 ;; 5]];
productionCrossToNonzero = productionGamma[[1 ;; 5, {6}]];
productionCrossFromNonzero = productionGamma[[{6}, 1 ;; 5]];
zeroMatrixQ[matrix_] := And @@ Flatten[Map[# === 0 &, matrix, {2}]];
validation = <|
  "RankOneResidue" -> (MatrixRank[normalResidue] === 1),
  "ProjectorIdempotent" ->
    zeroMatrixQ[Map[Cancel[Together[#]] &,
      spectralProjector . spectralProjector - spectralProjector, {2}]],
  "FrameDeterminantOne" -> (Cancel[Det[modeFrame]] === 1),
  "ResidueDiagonalized" ->
    residueInModeFrame === DiagonalMatrix[{0, 0, 0, 0, 0,
      nonzeroEigenvalue}],
  "CrossEigenspaceBlocksVanish" ->
    ! TrueQ[levelt["CrossExponentCoupling"]] &&
      Lookup[levelt["ExponentSectors"], "Indices"] === {{1, 2, 3, 4, 5}, {6}} &&
      zeroMatrixQ[crossToNonzero] && zeroMatrixQ[crossFromNonzero],
  "KernelRecompositionExact" -> zeroMatrixQ[decompositionResidual],
  "AcceptedTargetGaugeInvertible" ->
    Cancel[Together[Det[targetGauge]]] =!= 0,
  "AcceptedFrameCrossEigenspaceBlocksVanish" ->
    ! TrueQ[acceptedLevelt["CrossExponentCoupling"]] &&
      zeroMatrixQ[acceptedCrossToNonzero] &&
      zeroMatrixQ[acceptedCrossFromNonzero],
  "AcceptedTargetBlockIsEpsilonForm" ->
    zeroMatrixQ[Map[Cancel[Together[#]] &,
      acceptedGamma[[4 ;; 5, 4 ;; 5]] - targetEpsilonConnection, {2}]] &&
      zeroMatrixQ[Map[Cancel[Together[#]] &,
        targetEpsilonConnection/eps -
          (targetGPLCouplings["InvP"]/p +
            targetGPLCouplings["InvOneMinusP"]/(1 - p) +
            targetGPLCouplings["InvOnePlusP"]/(1 + p)), {2}]],
  "NonzeroModeEpsilonNormalized" ->
    Expand[shiftedNormalExponent + 4*eps] === 0 &&
      nonzeroNormalizationResidual === 0,
  "Block24GaugeIsAcceptedAndEpsilonNormalized" ->
    FreeQ[block24AcceptedBinding, p] &&
      zeroMatrixQ[Map[Cancel[Together[#]] &,
        block24SourceGauge . block24AcceptedBinding -
          acceptedBlock24Gauge, {2}]] &&
      zeroMatrixQ[Map[Cancel[Together[#]] &,
        Inverse[block24SourceGauge] . gamma[[1 ;; 2, 1 ;; 2]] .
          block24SourceGauge -
          Inverse[block24SourceGauge] . D[block24SourceGauge, p] -
          (-2*eps/p)*IdentityMatrix[2], {2}]],
  "ProductionDiagonalBlocksAreEpsilonForm" ->
    zeroMatrixQ[Map[Cancel[Together[#]] &,
      productionSourceConnection - eps*(
        productionSourceResidues[[1]]/p +
        productionSourceResidues[[2]]*p/(1 - 2*p^2)), {2}]] &&
      zeroMatrixQ[Map[Cancel[Together[#]] &,
        productionGamma[[4 ;; 5, 4 ;; 5]] -
          targetEpsilonConnection, {2}]],
  "ProductionCrossEigenspaceBlocksVanish" ->
    ! TrueQ[productionLevelt["CrossExponentCoupling"]] &&
      zeroMatrixQ[productionCrossToNonzero] &&
      zeroMatrixQ[productionCrossFromNonzero],
  "AcceptedTargetExtensionBoundToNonzeroFrame" ->
    Cancel[Together[block23NonzeroExtensionInBaseFrame +
      1/((1 + 4*eps)*(2 + 3*eps))]] === 0 &&
      Cancel[Together[block23NonzeroBaseNormalization*
        block23NonzeroExtensionInBaseFrame -
          block23NonzeroAcceptedExtension]] === 0,
  "RationalLayerProductionInputPrepared" ->
    Lookup[productionPrepare, "Status", "Failure"] === "Prepared" &&
      Lookup[productionPrepare, "Dimensions", Missing[]] === {2, 4} &&
      TrueQ[Lookup[productionPrepare,
        "SharedBoundaryCoordinates", False]],
  "FullProductionTransportAccepted" ->
    Lookup[productionTransport, "Status", "Failure"] ===
      "RationalEpsilonLayerTransportAccepted" &&
      TrueQ[productionTransportPredicate] &&
      Lookup[productionOperator, "Status", "Failure"] ===
        "RationalEpsilonLayerOperatorAccepted" &&
      TrueQ[AcceptedRationalEpsilonLayerOperatorQ[productionOperator]],
  "AcceptedJunctionModeMapExact" ->
    Dimensions[acceptedJunctionSourceMap] === {43, 6} &&
      Dimensions[independentTargetF25Map] === {2, 6} &&
      Dimensions[knownG25NormalExtension] === {2, 6} &&
      Complement[DeleteDuplicates[
        SparseArray[acceptedJunctionSourceMap]["NonzeroPositions"][[All, 1]]],
        {34, 35, 36, 37}] === {} &&
      acceptedSourceStateRows[[{34, 35, 36, 37}]] ===
        {40, 41, 42, 43}|>;
If[! And @@ Values[validation],
  Print["FAIL validation ", InputForm[validation]];
  If[! TrueQ[validation["RationalLayerProductionInputPrepared"]],
    Print["FAIL production prepare ", InputForm[productionPrepare]]];
  If[! TrueQ[validation["AcceptedJunctionModeMapExact"]],
    Print["FAIL junction map dims=",
      InputForm[{Dimensions[acceptedJunctionSourceMap],
        Dimensions[independentTargetF25Map],
        Dimensions[knownG25NormalExtension]}], " support=",
      InputForm[DeleteDuplicates[SparseArray[acceptedJunctionSourceMap][
        "NonzeroPositions"][[All, 1]]]], " states=",
      InputForm[acceptedSourceStateRows[[{34, 35, 36, 37}]]]]];
  Quit[3]];

result = <|
  "Status" -> "CF303SixModeEndpointFrameAcceptedV1",
  "Family" -> "CF303", "Basis" -> source["Basis"],
  "PhysicalRows" -> source["PhysicalRows"],
  "StateCanonicalRowOrder" -> source["StateCanonicalRowOrder"],
  "NormalResidue" -> <|"Matrix" -> normalResidue, "Rank" -> 1,
    "NonzeroEigenvalue" -> nonzeroEigenvalue,
    "SpectralProjector" -> spectralProjector|>,
  "ModeFrame" -> <|
    "Builder" -> "BuildEndpointLeveltModeConnection",
    "Convention" -> "columns are five zero modes followed by one nonzero mode",
    "Labels" -> {"ZeroE1", "ZeroE2", "ZeroBlock23",
      "ZeroTargetE5", "ZeroTargetE6", "NonzeroBlock23"},
    "Matrix" -> modeFrame, "Inverse" -> modeFrameInverse,
    "ResidueInFrame" -> residueInModeFrame,
    "ExponentData" -> levelt["ExponentData"],
    "ExponentSectors" -> Lookup[levelt["ExponentSectors"], "Indices"]|>,
  "TangentialConnection" -> <|
    "Convention" -> "Gamma=V^-1 B_parallel V - V^-1 dV/dp",
    "SparseEntries" -> matrixEntries[gamma],
    "ZeroEigenspaceBlock" -> gamma[[1 ;; 5, 1 ;; 5]],
    "NonzeroEigenspaceBlock" -> gamma[[{6}, {6}]],
    "CrossToNonzero" -> crossToNonzero,
    "CrossFromNonzero" -> crossFromNonzero|>,
  "AcceptedTargetGauge" -> <|
    "Convention" -> "I25=T25.F25",
    "Provenance" -> "accepted CF303 PhysicalGaugeByOrderPairs at rho=0",
    "Matrix" -> targetGauge, "Inverse" -> targetGaugeInverse,
    "Determinant" -> Cancel[Together[Det[targetGauge]]],
    "AcceptedModeFrame" -> acceptedModeFrame,
    "TangentialConnectionSparseEntries" -> matrixEntries[acceptedGamma],
    "TargetEpsilonConnection" -> targetEpsilonConnection,
    "TargetGPLCouplings" -> targetGPLCouplings,
    "GPLAlphabet" -> {0, 1, -1}|>,
  "EpsilonNormalizedNonzeroMode" -> <|
    "Convention" -> "J6=rho^-2 R6 K6",
    "IntegerShearPower" -> normalIntegerShearPower,
    "NormalExponentBefore" -> nonzeroEigenvalue,
    "NormalExponentAfter" -> shiftedNormalExponent,
    "R6" -> nonzeroTangentialPrefactor,
    "TangentialConnectionAfter" -> epsilonNormalizedNonzeroConnection,
    "GPLAlphabet" -> {0, 1/Sqrt[2], -1/Sqrt[2]}|>,
  "ProductionInput" -> <|
    "Status" -> "CF303SixModeRationalLayerInputAcceptedV1",
    "FrameColumnOrder" -> {"Block24Mode1", "Block24Mode2",
      "Block23Zero", "TargetMode1", "TargetMode2", "Block23Nonzero"},
    "SourceModeOrder" -> {"Block24Mode1", "Block24Mode2",
      "Block23Zero", "Block23Nonzero"},
    "PhysicalModeFrame" -> productionModeFrame,
    "TangentialConnectionSparseEntries" -> matrixEntries[productionGamma],
    "Source" -> productionSource,
    "Layer" -> productionLayer,
    "BoundaryCoordinateOrder" -> {
      "Block24Mode1", "Block24Mode2", "Block23Zero",
      "Block23Nonzero",
      "IndependentTargetMode1", "IndependentTargetMode2"},
    "CompactPhysicalGauges" -> <|
      "Block24" -> block24SourceGauge,
      "Block23Zero" -> block23ZeroGauge,
      "Block23Nonzero" -> nonzeroTangentialPrefactor,
      "TargetBlock25" -> targetGauge|>,
    "AcceptedCoordinateBinding" -> <|
      "Block24CanonicalToProduction" -> block24AcceptedBinding,
      "Block23ZeroCanonicalToProduction" ->
        block23ZeroAcceptedNormalization,
      "Block23NonzeroCanonicalToProduction" ->
        block23NonzeroBaseNormalization,
      "Block23NonzeroAcceptedTargetExtension" ->
        block23NonzeroAcceptedExtension*{1, 1},
      "Block23NonzeroTargetExtensionInProductionNormalization" ->
        block23NonzeroExtensionInBaseFrame*{1, 1},
      "TargetExtensionEncodedInNonzeroModeFrame" -> True,
      "TargetBoundarySelectorsContainOnlyIndependentZeroModes" -> True,
      "FrobeniusRegularPrefactorRequired" -> True|>,
    "PrepareOnlyControl" -> KeyTake[productionPrepare,
      {"Status", "Orders", "Factors", "Dimensions",
        "SharedBoundaryCoordinates"}],
    "FullRunEvidence" -> <|
      "DemandPairs" -> productionDemand["Pairs"],
      "TransportStatus" -> Lookup[productionTransport, "Status", None],
      "Route" -> Lookup[productionCertificate, "IncomingRoute", None],
      "GaugeStatus" -> Lookup[productionTransport, "GaugeStatus", None],
      "GaugeRepresentation" -> Lookup[productionCertificate,
        "GaugeRepresentation", None],
      "Window" -> Lookup[productionTransport, "Window", None],
      "Primes" -> Lookup[productionCertificate, "Primes", {}],
      "FreshValidationPrime" -> Lookup[productionCertificate,
        "FreshValidationPrime", None],
      "GaugeOrders" -> Keys[productionGaugeFunctions],
      "GaugeNonzeroEntries" -> productionGaugeNonzeros,
      "GaugeByteCount" -> ByteCount[productionGaugeFunctions],
      "TransportByteCount" -> ByteCount[productionTransport],
      "FourArgumentPredicate" -> productionTransportPredicate,
      "OperatorStatus" -> Lookup[productionOperator, "Status", None],
      "OperatorPredicate" ->
        AcceptedRationalEpsilonLayerOperatorQ[productionOperator],
      "OperatorByteCount" -> ByteCount[productionOperator],
      "TimingsSeconds" -> <|
        "Transport" -> productionTransportSeconds,
        "Operator" -> productionOperatorSeconds|>|>,
    "AcceptedZPathJunction" -> <|
      "Status" -> "CF303AcceptedZPathJunctionModeMapV1",
      "Junction" -> <|"p" -> pFinal, "z" -> 2*pFinal,
        "NormalCoordinate" -> "rho=2p-z",
        "Prescription" -> "TangentialRegularized"|>,
      "AcceptedSourceStateRows" -> acceptedSourceStateRows,
      "SourceModeMap" -> SparseArray[acceptedJunctionSourceMap],
      "IndependentTargetRepresentation" -> "F25",
      "IndependentTargetF25ModeMap" ->
        SparseArray[independentTargetF25Map],
      "KnownG25NormalResidueExtension" ->
        SparseArray[knownG25NormalExtension],
      "TargetModeMapComplete" -> False,
      "MissingTargetConversion" ->
        "Apply G25=F25-H.F_source with the principal and finite local H deck contracted against source Frobenius jets",
      "PhysicalNormalExponents" ->
        {0, 0, 0, -2 - 4*eps, 0, 0},
      "CanonicalNormalExponents" ->
        {0, 0, 0, -4*eps, 0, 0},
      "AcceptedZBasePoint" -> 1/2,
      "AcceptedZBoundaryColumns" -> 293,
      "RequiresRegularizedZRebase" -> True,
      "NoDirectSelectorSubstitution" -> True|>|>,
  "KernelDecomposition" -> <|
    "GPLAlphabet" -> {0, 1, -1, 1/Sqrt[2], -1/Sqrt[2]},
    "Kernels" -> kernelRecords,
    "CoefficientEpsilonDegreeMax" -> If[epsilonDegrees === {}, {0, 0},
      Max /@ Transpose[epsilonDegrees]],
    "Interpretation" -> "higher-pole and polynomial kernels have rational primitives"|>,
  "Validation" -> validation,
  "TimingsSeconds" -> <|"FrameAndGamma" -> frameSeconds,
    "KernelDecomposition" -> decompositionSeconds|>|>;
Put[result, outputPath];
Print["PASS frameSeconds=", frameSeconds,
  " decompositionSeconds=", decompositionSeconds,
  " gammaNonzeros=", Length[result["TangentialConnection"]["SparseEntries"]],
  " epsilonDegreeMax=", result["KernelDecomposition"]["CoefficientEpsilonDegreeMax"]];
Quit[];
