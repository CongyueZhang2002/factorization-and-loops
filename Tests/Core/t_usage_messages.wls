#!/usr/bin/env wolframscript
(* Every exported FeynFacet symbol keeps the usage message FeynFacet.m
   defines for it, and the attributes set there survive the private-file
   load.  Regression test for the 2026-08-21 finding that private files
   ClearAll'ed 34 public symbols (ClearAll removes messages), which left
   `?Symbol` empty for them. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
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
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs,
    FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ,
    FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs,
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
      "FeynFacet`TransportFamily",
      "FeynFacet`TransportPathArtifactRun",
      "FeynFacet`TransportStatus",
      "FeynFacet`TransportWord",
      "FeynFacet`TransportQuadrature",
      "FeynFacet`TransportConstant",
      "FeynFacet`BuildObservableTransport",
      "FeynFacet`AcceptedObservableTransportQ",
      "FeynFacet`ObservableTransportWordMap",
      "FeynFacet`ReconstructObservableTransportWordMaps"})
|>;
Print[InputForm[checks]];
Print["exported: ", Length[symbols], "  missing usage: ", missing];
Exit[If[And @@ Values[checks], 0, 1]];
