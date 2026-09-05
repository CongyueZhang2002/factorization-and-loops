#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`rationalEpsilonDependentBlockU"];
eps = Symbol["Global`rationalEpsilonDependentBlockEps"];

formerRationalBlockAPINames = {
    "BuildRationalEpsilonLayerTransport",
    "AcceptedRationalEpsilonLayerTransportQ",
    "BuildRationalEpsilonLayerOperator",
    "AcceptedRationalEpsilonLayerOperatorQ",
    "RebaseRationalEpsilonLayerOperator",
    "RationalEpsilonLayerWordMap",
    "RationalEpsilonLayerDemandTerms",
    "AttachTransportBoundaryToRationalLayer",
    "BuildPhysicalTransportCoefficient",
    "BuildRationalEpsilonLayerEndpointResidue"};
FTAssert["the rational-epsilon-dependent-block APIs are exported without the former layer/transport/word aliases",
  And @@ (! NameQ["FeynFacet`" <> #] & /@
    formerRationalBlockAPINames)];

sourceResidues = {
  {{0, 1}, {0, 0}},
  {{1, 0}, {0, -1}}
};
source = <|
  "Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}, {"E4Omega0"}},
  "Residues" -> sourceResidues,
  "BoundarySelectors" -> <|
    -1 -> IdentityMatrix[2],
    0 -> {{1, 0}, {0, 0}}
  |>
|>;

diagonalResidue = {{1, 1}, {0, 1}};
incomingResidue = {{2, 0}, {3, 1}};
layer = <|
  "Rows" -> {7, 8},
  "PathVariable" -> u,
  "Regulator" -> eps,
  "BasePoint" -> 0,
  "PathEndpoint" -> 1,
  "Curve" -> u^4 + 1,
  "CurvePointValues" -> <||>,
  "Diagonal" -> {{{"E4OmegaInf"}, diagonalResidue}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/eps,
      "Letter" -> {"GPLPole", -2}|>,
    <|"Row" -> 2, "Column" -> 1, "Coefficient" -> 3/eps,
      "Letter" -> {"GPLPole", -2}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 1/eps,
      "Letter" -> {"GPLPole", -2}|>
  },
  "TargetBoundarySelectors" -> <|0 -> IdentityMatrix[2]|>
|>;
demand = <|"RequestedOutputPairs" -> {{0, 1}, {0, 2}, {2, 1}, {2, 2}}|>;
transport = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator"];
operator = ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[source, layer, transport];
d = First[operator["DiagonalTokens"]];
k = First[operator["IncomingTokens"]];
s = First[operator["SourceTokens"]];

FTAssert["the block coefficient operator is constructed only from a genuine accepted lazy solution and keeps mixed GPL/eMPL labels opaque",
  transport["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
  transport["Certificate", "VariationOfConstantsMethod"] === "ExactDLogDecomposition" &&
  transport["IteratedIntegralCoefficientRepresentation"] === "LazyCoefficientOperator" &&
  transport["IteratedIntegralCoefficientTermsByRequestedOutput"] === None &&
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator] &&
  operator["Dimensions"] === <|"Source" -> 2, "Target" -> 2,
    "SourceBoundary" -> 2, "TargetBoundary" -> 2,
    "TotalBoundary" -> 4|> &&
  operator["DiagonalLabels"][d] === {"E4OmegaInf"} &&
  operator["IncomingLabels"][k] === {"GPLFactor", u + 2, 0} &&
  operator["SourceLabels"][Last[operator["SourceTokens"]]] ===
    {"E4Omega0"}];

targetCoefficientMatrix =
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[
    operator, {d, d}, 0, 2, 2];
FTAssert["a target-boundary letter sequence is evaluated without enumerating sibling sequences",
  targetCoefficientMatrix["Status"] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientMatrixComputed" &&
  Normal[targetCoefficientMatrix["IteratedIntegralCoefficientMatrix"]] ===
    {Join[ConstantArray[0, 2], MatrixPower[diagonalResidue, 2][[2]]]}];

incomingCoefficientMatrix =
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[
  operator, {d, k, s}, -1, 0, 2];
expectedIncoming = diagonalResidue . incomingResidue .
  sourceResidues[[1]] . source["BoundarySelectors"][-1];
FTAssert["a D-K-S letter sequence uses the Laurent order carried by its incoming token and returns only the requested row",
  incomingCoefficientMatrix["Status"] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientMatrixComputed" &&
  Normal[incomingCoefficientMatrix["IteratedIntegralCoefficientMatrix"]] ===
    {Join[expectedIncoming[[2]], {0, 0}]}];

FTAssert["zero and invalid letter sequences remain distinct, while an unsolved output is refused before enumeration",
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[operator, {}, 0, 0, 1]["Status"] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientMatrixComputed" &&
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[operator, {k, k}, 0, 0, 1]["Status"] ===
    "IteratedIntegralOperatorTokenSequenceOutsideBlockGrammar" &&
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[operator, {d}, 0, 0, 7]["Status"] ===
    "RequestedMasterIntegralRowsInvalid" &&
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[operator, {}, 0, 1, 1]["Status"] ===
    "RequestedOutputOutsideSolvedPairs" &&
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[operator, {1, 1}]["Status"] ===
    "RequestedOutputOutsideSolvedPairs"];

coefficientMapResult =
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
    operator, {0, 2}];
FTAssert["one solved output produces a genuine letter-sequence-to-coefficient-matrix association",
  coefficientMapResult["Status"] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed" &&
  AssociationQ[coefficientMapResult["IteratedIntegralCoefficientMap"]] &&
  coefficientMapResult["LetterSequenceCount"] > 0 &&
  AllTrue[Values[coefficientMapResult["IteratedIntegralCoefficientMap"]],
    MatrixQ[#] && Dimensions[#] === {1, 4} &] &&
  Normal[Lookup[coefficientMapResult["IteratedIntegralCoefficientMap"],
      Key[{}]]] === {{0, 0, 0, 1}}];

alteredIncomingLayer = Join[layer, <|"Incoming" ->
  ReplacePart[layer["Incoming"], 1 -> Join[layer["Incoming"][[1]],
    <|"Coefficient" -> 3/eps|>]]|>];
tamperedResidues = Join[transport, <|"KResidues" ->
  MapAt[# + 1 &, transport["KResidues"],
    {Key[First[Keys[transport["KResidues"]]]], 1, 1}]|>];
adversarialOperatorStatuses = {
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    source, alteredIncomingLayer, transport]["Status"],
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    source, layer, tamperedResidues]["Status"]};
Print["adversarial operator-construction statuses: ",
  InputForm[adversarialOperatorStatuses]];
FTAssert["the operator constructor re-verifies the supplied incoming connection and solved residues",
  adversarialOperatorStatuses[[1]] ===
      "RationalEpsilonDependentBlockSolutionVerificationFailed" &&
  RationalEpsilonDependentBlockSolutionQ[tamperedResidues] &&
  adversarialOperatorStatuses[[2]] ===
      "RationalEpsilonDependentBlockSolutionVerificationFailed"];

tangentialPrescription = <|"Type" -> "TangentialRegularized",
  "LocalDirection" -> -1, "PhysicalCoordinateLeadingCoefficient" -> 3/2,
  "LogBranch" -> 0|>;
independentRebase = ChangeRationalEpsilonDependentBlockSolutionBasePoint[
  operator, 1/2, source["BoundarySelectors"],
  layer["TargetBoundarySelectors"],
  "BasePointPrescription" -> tangentialPrescription];
FTAssert["independent source and target constants are embedded once into a shared boundary vector after changing the base point",
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[independentRebase] &&
  independentRebase["BasePointChange", "OriginalBoundaryLayout"] ===
    "Independent" &&
  independentRebase["BoundaryLayout"] === "Shared" &&
  independentRebase["Path", "BasePointPrescription"] ===
    tangentialPrescription &&
  independentRebase["Dimensions", "TotalBoundary"] === 4 &&
  Normal[independentRebase["SourceBoundarySelectors", 0]] ===
    {{1, 0, 0, 0}, {0, 0, 0, 0}} &&
  Normal[independentRebase["TargetBoundarySelectors", 0]] ===
    {{0, 0, 1, 0}, {0, 0, 0, 1}}];

sharedSource = <|
  "Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {ConstantArray[0, {2, 2}]},
  "BoundarySelectors" -> <|0 -> IdentityMatrix[2]|>
|>;
sharedLayer = <|
  "Rows" -> {7, 8},
  "PathVariable" -> u,
  "Regulator" -> eps,
  "BasePoint" -> 0,
  "PathEndpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -2}, ConstantArray[0, {2, 2}]}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>
  },
  "TargetBoundarySelectors" -> <|0 -> {{0, 1}, {1, 0}}|>,
  "SharedBoundaryCoordinates" -> True
|>;
sharedDemand = <|"RequestedOutputPairs" -> {{0, 1}, {0, 2}}|>;
sharedTransport = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  sharedSource, sharedLayer, sharedDemand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator", "PrimeCount" -> 3];
sharedOperator = ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
  sharedSource, sharedLayer, sharedTransport];
sharedCoefficientMap =
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
    sharedOperator, {0, All}];
FTAssert["shared boundary coordinates are not duplicated and the off-diagonal basis-transformation block at the path endpoint contributes as a coefficient rather than a fake integration letter",
  sharedTransport["OffDiagonalBasisTransformationBlockAtPathEndpoint"][0] === IdentityMatrix[2] &&
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[sharedOperator] &&
  sharedOperator["BoundaryLayout"] === "Shared" &&
  sharedOperator["Dimensions", "TotalBoundary"] === 2 &&
  sharedCoefficientMap["Status"] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed" &&
  Keys[sharedCoefficientMap["IteratedIntegralCoefficientMap"]] === {{}} &&
  Normal[Lookup[sharedCoefficientMap["IteratedIntegralCoefficientMap"],
      Key[{}]]] ===
    sharedLayer["TargetBoundarySelectors", 0] +
      sharedSource["BoundarySelectors", 0]];

FTAssert["lazy demand caps fail closed instead of silently truncating",
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[operator, {2, All},
    "MaximumTerms" -> 1]["Status"] ===
      "IteratedIntegralCoefficientMapConstructionCapped"];

FTSummary[];
