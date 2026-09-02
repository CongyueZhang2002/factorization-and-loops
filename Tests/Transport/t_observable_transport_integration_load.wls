#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

checks = <|
  "BuildLoaded" ->
    Length[DownValues[FeynFacet`BuildObservableTransport]] === 1,
  "CompactBuilderLoaded" ->
    Length[DownValues[
      FeynFacet`Private`observableTransportCompactDualAutomaton]] === 1,
  "AcceptancePredicateLoaded" ->
    Length[DownValues[FeynFacet`AcceptedObservableTransportQ]] === 1,
  "WordAccessorLoaded" ->
    Length[DownValues[FeynFacet`ObservableTransportWordMap]] === 2,
  "FinalReconstructionLoaded" ->
    Length[DownValues[
      FeynFacet`ReconstructObservableTransportWordMaps]] === 2,
  "FiniteFieldRowBasisLoaded" ->
    Length[DownValues[
      FeynFacet`Private`observableTransportModularRowBasis]] === 1,
  "AutomaticWordRepresentationOption" ->
    MemberQ[Options[FeynFacet`BuildObservableTransport],
      "WordRepresentation" -> Automatic]
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
