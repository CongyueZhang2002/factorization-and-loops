Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/EE_EEC/Raw/NNLO/q-qb","DoubleReal.Gluons"];
request=FeynFacet`ProjectAssemblyRequest[card];
choices={card["UnobservedGluonStates"],
 {<|"Momentum"->Global`k3,"Sum"->"Physical","ReferenceMomentum"->Global`q|>,
  <|"Momentum"->Global`k4,"Sum"->"Physical","ReferenceMomentum"->Global`q|>},
 {<|"Momentum"->Global`k3,"Sum"->"Physical","ReferenceMomentum"->Global`k1|>,
  <|"Momentum"->Global`k4,"Sum"->"Physical","ReferenceMomentum"->Global`q|>}};
densities=Table[
 setup=FeynFacet`ReadProcessCard[Join[card,<|"UnobservedGluonStates"->choice|>]];
 source=FeynFacet`ConstructCurrentIntegrands[setup,Join[request,<|"PrintTimings"->True,"KernelCount"->1|>]];
 If[!AssociationQ[source],Print[InputForm[source]];Exit[1]];
 value=FeynFacet`SubstituteScalarPowers[First[Values[source["Values"]]]request["CurrentNormalization"],request["BareCouplingRules"]];
 denominators=DeleteDuplicates[Cases[value,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
 value=value/.Table[object->Times@@Map[
    With[{description=FeynFacet`Private`propagatorDescriptor[#]},description["UnitCore"]^-description["Power"]]&,
    FeynFacet`Private`propagatorFactors[FeynCalc`ToSFAD[object]]],{object,denominators}];
 FeynCalc`ExpandScalarProduct[value],{choice,choices}];
chart=FeynFacet`MasslessInvariantPhaseSpaceCoordinates[Take[card["FinalMomenta"],4],Global`q,Global`Q2,ge,{gu,gv,ga,gb,gt}];
errors=Table[
 rules=Join[{gu->point[[1]],gv->point[[2]],ga->point[[3]],gb->point[[4]],gt->point[[5]]},
  {Global`Q2->7/3,D->point[[6]],Global`muR2->11/5,Global`nf->3,FeynCalc`CA->3,FeynCalc`CF->4/3,
    FeynCalc`SUNN->3,FeynFacet`\[Alpha]s->1/10,Global`Epsilon->(4-point[[6]])/2}];
 values=N[(densities/.chart["ScalarProductRules"])/.rules,45];
 exchanged=N[(First[densities]/.{Global`k3->Global`k4,Global`k4->Global`k3}/.chart["ScalarProductRules"])/.rules,45];
 If[!VectorQ[Append[values,exchanged],NumberQ],Print[InputForm[values]];Print[InputForm[exchanged]];Exit[1]];
 {Max[Abs[values-RotateLeft[values]]]/Max[1,Max[Abs[values]]],Abs[First[values]-exchanged]/Max[1,Abs[First[values]]]},
 {point,{{2/7,3/5,1/4,2/5,1/3,4},{1/3,1/4,2/7,3/8,3/5,5}}}];
FTTest`FTAssert["complete four-parton current is independent of physical/covariant sums and gauge reference",
 Max[errors[[All,1]]]<10^-30];
FTTest`FTAssert["the complete density is invariant under exchanging identical final gluons",
 Max[errors[[All,2]]]<10^-30];
Print["FOUR PARTON CURRENT GAUGE TEST COMPLETE"];
FTTest`FTReport[];
