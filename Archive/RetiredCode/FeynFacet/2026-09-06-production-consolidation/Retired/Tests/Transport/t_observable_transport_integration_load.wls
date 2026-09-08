#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

checks = <|
  "BuildLoaded" ->
    Length[DownValues[
      FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs]] === 1,
  "CompactBuilderLoaded" ->
    Length[DownValues[
      FeynFacet`Private`observableTransportCompactDualAutomaton]] === 1,
  "AcceptancePredicateLoaded" ->
    Length[DownValues[
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ]] === 1,
  "CoefficientMatrixAccessorLoaded" ->
    Length[DownValues[
      FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs]] === 2,
  "FinalReconstructionLoaded" ->
    Length[DownValues[
      FeynFacet`ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs]] === 2,
  "FiniteFieldRowBasisLoaded" ->
    Length[DownValues[
      FeynFacet`Private`observableTransportModularRowBasis]] === 1,
  "AutomaticCoefficientRepresentationOption" ->
    MemberQ[Options[
      FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs],
      "IteratedIntegralCoefficientRepresentation" -> Automatic],
  "RemovedPublicHeadsAbsent" -> And @@
    (System`Names["FeynFacet`" <> #] === {} & /@
      {"BuildObservableTransport", "AcceptedObservableTransportQ",
       "ObservableTransportWordMap",
       "ReconstructObservableTransportWordMaps"})
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
