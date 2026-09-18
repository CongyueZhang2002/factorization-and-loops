Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
channel=root<>"/Projects/EE_EEC/Raw/NNLO/q-qb";
aggregate=FeynFacet`ReadContributionCard[channel,"DoubleReal"];
FTTest`FTAssert["NNLO EEC declares disjoint complete external states",AssociationQ[aggregate]&&Length[aggregate["Components"]]===3];
If[!AssociationQ[aggregate],Print[InputForm[aggregate]];FTTest`FTReport[]];
Do[
 card=FeynFacet`ReadContributionCard[channel,"DoubleReal."<>row[[1]]];
 FTTest`FTAssert["derived state and flavor counting for "<>row[[1]],AssociationQ[card]&&
  card["SymmetryFactor"]===row[[2]]&&Simplify[card["FlavorMultiplicity"]-row[[3]]]===0],
 {row,{{"Gluons",1/2,Global`nf},{"IdenticalQuarks",1/4,Global`nf},
   {"DifferentQuarks",1,Global`nf(Global`nf-1)/2}}}];
card=FeynFacet`ReadContributionCard[root<>"/Projects/EE_EEC/Raw/LO/q-qb","Born"];
FTTest`FTAssert["Born normalization uses the same complete current flavor sum",AssociationQ[card]&&
 card["SymmetryFactor"]===1&&card["FlavorMultiplicity"]===Global`nf];
virtual=FeynFacet`ReadContributionCard[channel,"Virtual"];
FTTest`FTAssert["two-loop interference and one-loop square are distinct amplitude orders",
 AssociationQ[virtual]&&virtual["Components"]["TwoLoop"]["AmplitudeLoops"]==={2,0}&&
 virtual["Components"]["OneLoopSquared"]["AmplitudeLoops"]==={1,1}];
Print["EEC STATE COUNTS TEST COMPLETE"];
FTTest`FTReport[];
