SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[BuildSimplificationContext] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyHardCoefficients] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]}
};
SyntaxInformation[ToFeynFacetForm] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _, _.}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[KiraImportReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[ReconstructCoefficients] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[ReconstructionStatus] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CoefficientProgressPanel] = {"ArgumentsPattern" -> {}};
SyntaxInformation[DecomposeFamilyBlocks] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[BuildFamilyDifferentialSystemBlockDecomposition] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[FamilyDifferentialSystemBlockDecompositionQ] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructDiagonalBlockDLogEpsilonForm] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[DiagonalBlockDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ClassifyBlocks] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[ValidateCanonicalForm] =
  {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};
SyntaxInformation[CanonicalBlocksStatus] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[RationalizingParametrizationCatalog] = {"ArgumentsPattern" -> {}};
SyntaxInformation[VerifyRationalizingParametrization] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[RegisterFamilyRootData] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[LoadFamilyRootData] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[FamilyRootData] = {"ArgumentsPattern" -> {_, _., _.}};
SyntaxInformation[
  AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[NormalizeEpsFormAffineSample] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ReconstructOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[VerifyOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[SolveOffDiagonalBasisTransformationBlockFiniteField] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[AnalyzeOffDiagonalBlockEpsilonFormObstructions] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[SolveDiagonalBlockBasisTransformationFiniteField] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ExactlyValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidateFamilyDLogEpsilonForm] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[AssembleCutContributions] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[IdenticalParticleSymmetryFactor] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[MasterIntegralAmFlow] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[IdentifySafePropagator] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[GenerateDiagram] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[DimensionalShift] = {"ArgumentsPattern" -> {_, _, _, _.}};
SyntaxInformation[ComputeTruncatedLocalFrobeniusExpansion] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[TransformTangentialConnectionToNormalResidueEigenbasis] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ConstructBoundaryFunctionDifferentialSystem] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BoundaryFunctionDifferentialSystemQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ConstructBoundaryFunctionEpsilonCoefficientEquations] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructMasterIntegralDimensionalRecurrence] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[DetermineLaurentBoundsFromDimensionalRecurrence] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[ConstructMasterIntegralRepresentations] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};
SyntaxInformation[DetermineMasterIntegralExpansionOrders] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[DetermineLaurentValuation] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[DetermineIntegralLaurentBound] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[DetermineEpsilonOrders] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[DetermineFundamentalMatrixEpsilonOrders] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[DetermineEndpointEpsilonOrders] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[DetermineFrobeniusLaurentBounds] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[WriteMasterIntegralSolution] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[ConstructMasterIntegralSolution] =
  {"ArgumentsPattern" -> {_, ___}};
SyntaxInformation[MasterIntegralSolutionQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[DeriveMasterIntegralEpsilonOrderRequirements] =
  {"ArgumentsPattern" -> {_, _, _.}};
SyntaxInformation[MasterIntegralEpsilonOrderRequirementsQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[MatchBoundaryAsymptoticsToFrobeniusModes] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[DegenerateResidueEigenspaceBasis] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructBoundarySelectorMatrices] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[ConstructBoundaryValueVectorFromConstants] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[ConstructBoundaryValueVectorFromFunctions] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[BoundaryConstantEpsilonCoefficient] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BoundaryFunctionEpsilonCoefficient] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[IteratedIntegralKernel] =
  {"ArgumentsPattern" -> {_, _, _.}};
SyntaxInformation[ExpandIteratedIntegralLetterSequence] =
  {"ArgumentsPattern" -> {_, _, _., _.}};
SyntaxInformation[ComputeConnectionResidueAtLocalExpansionPoint] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint] =
  {"ArgumentsPattern" -> {_, _, _, _, _, OptionsPattern[]}};
SyntaxInformation[ComposeRationalizingParametrizations] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[BuildSquareRootGeneratorsAndQuadraticRelations] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[FamilySquareRootGeneratorCensus] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[LookupCataloguedRationalizingParametrizationForRoots] =
  {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[SolveOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ExtendRationalizingParametrization] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

Options[PartialFraction] = {
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False
};


