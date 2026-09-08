#!/usr/bin/env wolframscript
(* Every exported FeynFacet symbol keeps the usage message FeynFacet.m
   defines for it, and the attributes set there survive the private-file
   load.  Regression test for the 2026-08-21 finding that private files
   ClearAll'ed 34 public symbols (ClearAll removes messages), which left
   `?Symbol` empty for them. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "EpsilonForm.m"}]];
symbols = Select[System`Names["FeynFacet`*"],
  ! StringEndsQ[#, "$"] &];
usageQ[name_] := StringQ[ToExpression[name <> "::usage"]];
missing = Select[symbols, ! usageQ[#] &];
checks = <|
  "ExportedSymbolsPresent" -> Length[symbols] >= 90,
  "EveryExportedSymbolHasUsage" -> missing === {},
  "CutKeepsHoldAll" -> Attributes[FeynFacet`Cut] === {HoldAll},
  "PartialFractionKeepsOptions" -> Options[FeynFacet`PartialFraction] =!= {},
  "PublicDefinitionsLoaded" -> AllTrue[{FeynFacet`DiagonalBlockEpsForm,
    FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField, FeynFacet`FamilyRootData,
    FeynFacet`ValidateFamilyDLogEpsilonForm,
    FeynFacet`ConstructMasterIntegralSolution,
    FeynFacet`DetermineMasterIntegralExpansionOrders,
    FeynFacet`WriteMasterIntegralSolution,
    FeynFacet`SimplifyHardCoefficients},
    Length[DownValues[#]] > 0 &],
  "FiniteFieldImplementationHelpersArePrivate" ->
    And @@ (System`Names[#] === {} & /@ {
      "FeynFacet`PrepareOffDiagonalBlockFiniteFieldSystem",
      "FeynFacet`ComputeOffDiagonalBlockFiniteFieldImage",
      "FeynFacet`InterpolateOffDiagonalBasisTransformationBlockInEpsilon",
      "FeynFacet`RecordVerifiedOffDiagonalBasisTransformationBlock"}),
  "RetiredTransportCompatibilitySymbolsAreAbsent" ->
    And @@ (System`Names[#] === {} & /@ {
      "FeynFacet`FactorFamilyRegulatorDependenceInFrame",
      "FeynFacet`CertifyTransportEpsilonValuations",
      "FeynFacet`BuildTangentialJunctionBinding",
      "FeynFacet`AcceptedTangentialJunctionBindingQ",
      "FeynFacet`ComposeTangentialJunctionIteratedIntegralCoefficientMaps",
      "FeynFacet`TransportFamily",
      "FeynFacet`TransportPathArtifactRun",
      "FeynFacet`TransportStatus",
      "FeynFacet`TransportWord",
      "FeynFacet`TransportQuadrature",
      "FeynFacet`TransportConstant",
      "FeynFacet`BuildObservableTransport",
      "FeynFacet`AcceptedObservableTransportQ",
      "FeynFacet`ObservableTransportWordMap",
      "FeynFacet`ReconstructObservableTransportWordMaps",
      "FeynFacet`AttachBoundarySelectorsToRationalEpsilonDependentBlock",
      "FeynFacet`BoundaryCoefficientOperatorProductQ",
      "FeynFacet`BuildSingularPointMatchingData",
      "FeynFacet`CanonicalizeClasses",
      "FeynFacet`ChangeRationalEpsilonDependentBlockSolutionBasePoint",
      "FeynFacet`ChooseRegularBasePointAndFirstPathParameterScale",
      "FeynFacet`ClassifyRequestedOutputIteratedIntegralCoefficientInputs",
      "FeynFacet`ComposeBoundaryFunctionSolutionMapWithTangentialEvolution",
      "FeynFacet`ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution",
      "FeynFacet`ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint",
      "FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs",
      "FeynFacet`ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix",
      "FeynFacet`ConstructBoundaryCoefficientOperatorProduct",
      "FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs",
      "FeynFacet`ConstructMasterIntegralEpsilonExpansionCoefficient",
      "FeynFacet`ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap",
      "FeynFacet`ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator",
      "FeynFacet`FactorizedFiniteFieldBoundarySolutionCompositionQ",
      "FeynFacet`FindRequestedOutputIteratedIntegralCoefficientInputFiles",
      "FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ",
      "FeynFacet`LibraFamilyEpsForm",
      "FeynFacet`RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ",
      "FeynFacet`RationalEpsilonDependentBlockSolutionQ",
      "FeynFacet`ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs",
      "FeynFacet`SelectValidatedFamilyDLogEpsilonFormInputs",
      "FeynFacet`SingularPointMatchingDataQ",
      "FeynFacet`SolveRationalEpsilonDependentBlockByVariationOfConstants",
      "FeynFacet`TangentialBoundaryEvolutionOperatorQ",
      "FeynFacet`ValidateBasisTransformationEpsilonValuationsAtRationalPoints",
      "FeynFacet`VerifyRationalEpsilonDependentBlockSolution",
      "FeynFacet`WriteRequestedOutputIteratedIntegralCoefficientInputSummary"})
|>;
Print[InputForm[checks]];
Print["exported: ", Length[symbols], "  missing usage: ", missing];
Exit[If[And @@ Values[checks], 0, 1]];
