(* Ghost-antighost cut card runs through the full pre-IBP pipeline.

   Acceptance criteria:
   A. FeynArts generates exactly 7 tree diagrams for
      u d -> u d + ghost + antighost with the UU_Ghost card settings.
   B. CollinearFactorizePreIBP completes on the (1,1) ghost pair and
      returns the five-component result with at least one cut-aware
      topology and a nonempty GLI integrand. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

card = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU_Ghost.wl"
}]];

probeCard = card;
probeCard["ForwardAmplitudes", "SelectedIndex"] = 1;
probeCard["ConjugateAmplitudes", "SelectedIndex"] = 1;

diagrams = FeynFacet`GenerateDiagram[probeCard];
FTTest`FTAssert["ghost diagram generation returns both sides",
  AssociationQ[diagrams]];
FTTest`FTAssert["exactly 7 ghost diagrams",
  AssociationQ[diagrams] && Length[diagrams["Amplitude"]] === 7];

result = FeynFacet`CollinearFactorizePreIBP[probeCard];
FTTest`FTAssert["pre-IBP pipeline completes on the (1,1) ghost pair",
  MatchQ[result, {_, _, _, _, _List}]];
FTTest`FTAssert["at least one cut-aware topology record",
  MatchQ[result, {_, _, _, _, _List}] && Length[result[[5]]] >= 1];
FTTest`FTAssert["integrand contains GLI objects",
  MatchQ[result, {_, _, _, _, _List}] &&
    Cases[result[[4]], _FeynCalc`GLI, {0, Infinity}] =!= {}];
FTTest`FTAssert["every topology retains its three cut slots (kd, ke, kf lines)",
  MatchQ[result, {_, _, _, _, _List}] &&
    AllTrue[result[[5]], Length[#["CutIndices"]] === 3 &]];

FTTest`FTReport[];
