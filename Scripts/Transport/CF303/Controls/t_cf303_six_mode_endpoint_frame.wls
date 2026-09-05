$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repositoryRoot = DirectoryName[scriptDirectory, 4];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];
source = Get[FileNameJoin[{scriptDirectory, "..", "Artifacts",
  "CF303PhysicalSoftSixSystem.wl"}]];
frame = Get[FileNameJoin[{scriptDirectory, "..", "Artifacts",
  "CF303SixModeEndpointFrame.wl"}]];

recordsToMatrix[records_, field_] := Normal[SparseArray[
  ({#Row, #Column} -> Lookup[#, field, 0]) & /@ records, {6, 6}]];
zeroMatrixQ[matrix_] := And @@ Flatten[Map[# === 0 &, matrix, {2}]];
reduceMatrix[matrix_] := Map[Cancel[Together[#]] &, matrix, {2}];
checks = {};
check[name_, condition_] := AppendTo[checks, <|"Name" -> name,
  "Passed" -> TrueQ[condition]|>];

bParallel = recordsToMatrix[source["Homogeneous"]["Tangential"], "Finite"];
normalResidue = Normal[SparseArray[
  ({#Row, #Column} -> Lookup[#Principal, -1, 0]) & /@
    source["Homogeneous"]["Normal"], {6, 6}]];
residueRecord = frame["NormalResidue"];
modeRecord = frame["NormalResidueEigenbasis"];
v = modeRecord["Matrix"];
vInverse = modeRecord["Inverse"];
lambda = residueRecord["NonzeroEigenvalue"];
projector = residueRecord["SpectralProjector"];
gamma = Normal[SparseArray[
  ({#Row, #Column} -> #Value) & /@
    frame["TangentialConnectionInEigenbasis"]["SparseEntries"], {6, 6}]];
eigenbasisTransformation =
  TransformTangentialConnectionToNormalResidueEigenbasis[
    normalResidue, bParallel,
  <|"TangentialVariable" -> p, "Regulator" -> eps,
    "NormalResidueEigenbasis" -> v,
    "LocalExponents" -> {0, 0, 0, 0, 0, lambda}|>];

check["rank_one_spectral_data",
  MatrixRank[normalResidue] === 1 &&
  zeroMatrixQ[reduceMatrix[normalResidue - lambda*projector]] &&
  zeroMatrixQ[reduceMatrix[projector . projector - projector]]];
check["moving_frame_diagonalizes_residue",
  Cancel[Det[v]] === 1 && zeroMatrixQ[reduceMatrix[vInverse . v - IdentityMatrix[6]]] &&
  reduceMatrix[vInverse . normalResidue . v] ===
    DiagonalMatrix[{0, 0, 0, 0, 0, lambda}]];
check["package_api_spectrum_and_gamma",
  eigenbasisTransformation["Status"] ===
      "TangentialConnectionTransformedToNormalResidueEigenbasis" &&
  zeroMatrixQ[reduceMatrix[gamma -
    eigenbasisTransformation["TangentialConnectionInEigenbasis"]]] &&
  Lookup[eigenbasisTransformation["ExponentData"], "IntegerPart"] ===
    {0, 0, 0, 0, 0, -2} &&
  Lookup[eigenbasisTransformation["ExponentData"],
    "RegulatorCoefficient"] ===
    {0, 0, 0, 0, 0, -4} &&
  Lookup[eigenbasisTransformation["EqualExponentSectors"], "Indices"] ===
    {{1, 2, 3, 4, 5}, {6}}];
check["package_api_cross_eigenspace_blocks_vanish",
  eigenbasisTransformation["UnequalExponentCoupling"] === False &&
  zeroMatrixQ[gamma[[1 ;; 5, {6}]]] &&
  zeroMatrixQ[gamma[[{6}, 1 ;; 5]]]];

targetRecord = frame["AcceptedTargetBasisTransformation"];
targetBasisTransformationMatrix = targetRecord["Matrix"];
acceptedFrame = targetRecord["AcceptedNormalResidueEigenbasis"];
acceptedEigenbasisTransformation =
  TransformTangentialConnectionToNormalResidueEigenbasis[
    normalResidue, bParallel,
  <|"TangentialVariable" -> p, "Regulator" -> eps,
    "NormalResidueEigenbasis" -> acceptedFrame,
    "LocalExponents" -> {0, 0, 0, 0, 0, lambda}|>];
acceptedGamma = acceptedEigenbasisTransformation[
  "TangentialConnectionInEigenbasis"];
targetConnection = targetRecord["TargetEpsilonConnection"];
targetCouplings = targetRecord["TargetGPLCouplings"];
check["accepted_target_basis_transformation_and_normal_residue_eigenbasis_api",
  Cancel[Together[Det[targetBasisTransformationMatrix]]] ===
    targetRecord["Determinant"] &&
  zeroMatrixQ[reduceMatrix[targetRecord["Inverse"] .
      targetBasisTransformationMatrix -
    IdentityMatrix[2]]] &&
  acceptedEigenbasisTransformation["Status"] ===
      "TangentialConnectionTransformedToNormalResidueEigenbasis" &&
  acceptedEigenbasisTransformation["UnequalExponentCoupling"] === False &&
  zeroMatrixQ[acceptedGamma[[1 ;; 5, {6}] ]] &&
  zeroMatrixQ[acceptedGamma[[{6}, 1 ;; 5]]]];
check["accepted_target_block_is_rational_gpl_epsilon_form",
  zeroMatrixQ[reduceMatrix[
    acceptedGamma[[4 ;; 5, 4 ;; 5]] - targetConnection]] &&
  zeroMatrixQ[reduceMatrix[targetConnection/eps -
    (targetCouplings["InvP"]/p +
      targetCouplings["InvOneMinusP"]/(1 - p) +
      targetCouplings["InvOnePlusP"]/(1 + p))]] &&
  zeroMatrixQ[targetConnection /. eps -> 0]];

nonzeroRecord = frame["EpsilonNormalizedNonzeroMode"];
check["nonzero_mode_integer_shear_and_prefactor",
  Expand[nonzeroRecord["NormalExponentAfter"] + 4*eps] === 0 &&
  Cancel[Together[gamma[[6, 6]] -
    D[Log[nonzeroRecord["R6"]], p] -
    nonzeroRecord["TangentialConnectionAfter"]]] === 0 &&
  Cancel[Together[nonzeroRecord["TangentialConnectionAfter"] -
    eps*(4/p + 16*p/(1 - 2*p^2))]] === 0];

production = frame["ProductionInput"];
productionFrame = production["PhysicalNormalResidueEigenbasis"];
productionEigenbasisTransformation =
  TransformTangentialConnectionToNormalResidueEigenbasis[
    normalResidue, bParallel,
  <|"TangentialVariable" -> p, "Regulator" -> eps,
    "NormalResidueEigenbasis" -> productionFrame,
    "LocalExponents" -> {0, 0, 0, 0, 0, lambda}|>];
productionGamma = Normal[SparseArray[
  ({#Row, #Column} -> #Value) & /@
    production["TangentialConnectionSparseEntries"], {6, 6}]];
sourceIndices = {1, 2, 3, 6};
productionSource = production["Source"];
productionBlock = production["Layer"];
sourceConnection = eps*(
  productionSource["Residues"][[1]]/p +
  productionSource["Residues"][[2]]*p/(1 - 2*p^2));
check["production_frame_and_epsilon_diagonal_blocks",
  production["Status"] ===
      "CF303SixModeRationalEpsilonDependentBlockInputValidatedV2" &&
  production["FrameColumnOrder"] === {"Block24Mode1", "Block24Mode2",
    "Block23Zero", "TargetMode1", "TargetMode2", "Block23Nonzero"} &&
  production["SourceModeOrder"] === {"Block24Mode1", "Block24Mode2",
    "Block23Zero", "Block23Nonzero"} &&
  productionEigenbasisTransformation["Status"] ===
      "TangentialConnectionTransformedToNormalResidueEigenbasis" &&
  zeroMatrixQ[reduceMatrix[productionGamma -
    productionEigenbasisTransformation[
      "TangentialConnectionInEigenbasis"]]] &&
  zeroMatrixQ[reduceMatrix[
    productionGamma[[sourceIndices, sourceIndices]] - sourceConnection]] &&
  zeroMatrixQ[reduceMatrix[
    productionGamma[[4 ;; 5, 4 ;; 5]] - targetConnection]]];
check["accepted_coordinate_binding_and_embedded_target_extension",
  FreeQ[production["AcceptedCoordinateBinding"][
    "Block24CanonicalToProduction"], p] &&
  Lookup[production["AcceptedCoordinateBinding"],
    "TargetExtensionEncodedInNonzeroResidueEigenbasis",
    Lookup[production["AcceptedCoordinateBinding"],
      "TargetExtensionEncodedInNonzeroModeFrame", False]] === True &&
  production["AcceptedCoordinateBinding"][
    "Block23NonzeroTargetExtensionInProductionNormalization"] ===
      {-1/((1 + 4*eps)*(2 + 3*eps)),
       -1/((1 + 4*eps)*(2 + 3*eps))} &&
  productionBlock["TargetBoundarySelectors"][0] ===
    {{0, 0, 0, 0, 1, 0}, {0, 0, 0, 0, 0, 1}}];
productionDemand =
  <|"RequestedOutputPairs" -> {{0, 1}, {0, 2}}|>;
prepared = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  productionSource, productionBlock, productionDemand,
  "PrepareOnly" -> True];
check["rational_epsilon_dependent_block_problem_prepares",
  prepared["Status"] ===
      "RationalEpsilonDependentBlockVariationOfConstantsProblemPrepared" &&
  prepared["Dimensions"] === {2, 4} &&
  prepared["SharedBoundaryCoordinates"] === True &&
  productionBlock["ZeroColumns"] === {4}];
fullSolution = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  productionSource, productionBlock, productionDemand,
  "PrimeCount" -> 3,
  "IteratedIntegralCoefficientRepresentation" ->
    "LazyCoefficientOperator"];
fullOperator =
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    productionSource, productionBlock, fullSolution];
fullEvidence = production["FullRunEvidence"];
check["full_symbolic_path_endpoint_solution_and_coefficient_operator",
  fullSolution["Status"] ===
      "RationalEpsilonDependentBlockSolutionAccepted" &&
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[
    fullOperator] &&
  fullEvidence["VariationOfConstantsMethod"] ===
    "FiniteFieldHermiteReductionAndReconstruction" &&
  fullEvidence["OffDiagonalTransformationBlockRepresentation"] === "RationalFunction" &&
  Length[fullEvidence["Primes"]] === 3 &&
  PrimeQ[fullEvidence["FreshValidationPrime"]] &&
  fullEvidence[
    "OffDiagonalBasisTransformationBlockNonzeroEntries"] === 6 &&
  TrueQ[fullEvidence[
    "CoefficientOperatorStructuralPredicate"]]];

junction = production["AcceptedZPathJunction"];
junctionSource = junction["SourceModeMap"];
junctionTarget = junction["IndependentTargetF25ModeMap"];
knownG25Extension = junction["KnownG25NormalResidueExtension"];
check["accepted_z_path_junction_mode_map",
  junction["Status"] === "CF303AcceptedZPathJunctionModeMapV1" &&
  Dimensions[junctionSource] === {43, 6} &&
  Dimensions[junctionTarget] === {2, 6} &&
  Dimensions[knownG25Extension] === {2, 6} &&
  DeleteDuplicates[junctionSource["NonzeroPositions"][[All, 1]]] ===
    {34, 35, 36, 37} &&
  Normal[knownG25Extension[[All, 4]]] ===
    production["AcceptedCoordinateBinding"]
      ["Block23NonzeroTargetExtensionInProductionNormalization"] &&
  Normal[junctionTarget[[All, {5, 6}] ]] === IdentityMatrix[2] &&
  junction["IndependentTargetRepresentation"] === "F25" &&
  junction["TargetModeMapComplete"] === False &&
  junction["RequiresRegularizedZRebase"] === True &&
  junction["NoDirectSelectorSubstitution"] === True];

kernelRecords = frame["KernelDecomposition"]["Kernels"];
recomposed = Total[Function[record,
  record["Kernel"]*Normal[SparseArray[
    ({#Row, #Column} -> #Value) & /@ record["Couplings"], {6, 6}]]]
  /@ kernelRecords];
check["kernel_decomposition_and_primitives",
  zeroMatrixQ[reduceMatrix[gamma - recomposed]] &&
  And @@ (Cancel[D[#Primitive, p] - #Kernel] === 0 & /@ kernelRecords)];
couplings = Flatten[Lookup[kernelRecords, "Couplings"]];
check["rational_epsilon_coefficients",
  And @@ (Function[entry, With[{value = Together[entry["Value"]]},
      FreeQ[value, p] && PolynomialQ[Numerator[value], eps] &&
        PolynomialQ[Denominator[value], eps]]]
    /@ couplings) &&
  frame["KernelDecomposition"]["CoefficientEpsilonDegreeMax"] === {2, 1}];

failures = Select[checks, ! TrueQ[#Passed] &];
Scan[Print[If[#Passed, "PASS ", "FAIL "], #Name] &, checks];
Print["SUMMARY passed=", Count[Lookup[checks, "Passed"], True],
  " failed=", Length[failures]];
Quit[If[failures === {}, 0, 1]];
