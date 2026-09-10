root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;passed=0;failed=0;
check[label_,test_]:=If[TrueQ[test],passed++;Print["PASS ",label],failed++;Print["FAIL ",label]];
pars=<|"CA"->caTest,"CF"->cfTest,"TR"->1/2,"FlavorCount"->nfTest|>;
channel=<|"Incoming"->{{"q","u"},{"q","d"}},"Observed"->{"q","u"}|>;
request=<|"Species"->{{"q","u"},{"q","d"},{"qbar","u"},{"qbar","d"},"g"},"Polarization"-><|"Incoming"->{"U","U"},"Observed"->"U"|>,
 "Schemes"-><|"IncomingA"->"MSbar","IncomingB"->"MSbar","Observed"->"MSbar"|>,"SplittingVariable"->xiTest,"KernelParameters"->pars|>;
closure=FeynFacet`EnumerateNLOCollinearChannels[channel,request];
check["unpolarized closure includes four collinear channels",Length[closure["Channels"]]===4];
check["off-diagonal PDF requires qg -> qg Born",Length[Select[closure["Channels"],#["Leg"]==="IncomingB"&&#["Daughter"]==="g"&&#["BornChannel"]["Recoil"]==="g"&]]===1];
transverse=FeynFacet`EnumerateNLOCollinearChannels[channel,Join[request,<|"Polarization"-><|"Incoming"->{"T","T"},"Observed"->"U"|>|>]];
check["transversity has three flavor-preserving counterterms",Length[transverse["Channels"]]===3];
finiteKernel=<|"Variable"->xiTest,"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->kappaTest(1-xiTest)|>;
matrix=<|"FiniteKernels"-><|{{"q","u"},{"q","d"},"T"}->finiteKernel|>|>;
changed=FeynFacet`EnumerateNLOCollinearChannels[channel,Join[request,<|"Polarization"-><|"Incoming"->{"T","T"},"Observed"->"U"|>,
 "Schemes"-><|"IncomingA"->"MSbar","IncomingB"->matrix,"Observed"->"MSbar"|>|>]];
check["explicit finite flavor mixing requires additional same-flavor Born",Length[changed["Channels"]]===4&&
 AnyTrue[changed["Channels"],#["BornChannel"]["Incoming"]==={{"q","u"},{"q","u"}}&]];
check["unassigned finite matrix entry uses MSbar",FeynFacet`FactorizationSchemeKernel[matrix,{"q","u"},{"q","u"},"T",xiTest,pars]["RegularCoefficient"]===0];
check["single-channel kernel is not silently applied to every flavor",FailureQ[FeynFacet`EnumerateNLOCollinearChannels[channel,
 Join[request,<|"Schemes"-><|"IncomingA"->finiteKernel,"IncomingB"->"MSbar","Observed"->"MSbar"|>|>]]]];
born=FeynFacet`CreatePartonicResult[Association@Table[j-><|
 "DeltaCoefficient"->alphaTest^2(1+vTest^2)/(sTest^2 vTest(vTest-1)^2),"PlusCoefficients"-><||>,"RegularCoefficient"->0|>,{j,0,2}],
 <|"Order"->"LO","Contribution"->"Born","Scale"->sTest,"Variables"->{vTest,wTest},"CouplingPower"->2,
 "MandelstamVariables"->{sTest,tTest,uTest},"DimensionalRegulator"->epTest|>];
card=<|"Scale"->sTest,"Variables"->{vTest,wTest},"Coupling"->alphaTest,"KernelParameters"->pars,
 "SplittingVariable"->xiTest,"Leg"->"IncomingA","Daughter"->{"q","u"},"Parent"->{"q","u"},"Spin"->"U",
 "RenormalizationScaleSquared"->mrTest,"FactorizationScaleSquared"->mfTest|>;
plain=FeynFacet`ConstructNLOCollinearCounterterm[born,card];
custom=FeynFacet`ConstructNLOCollinearCounterterm[born,Join[card,<|"FiniteKernel"->finiteKernel|>]];
expected=FeynFacet`ConvolveBornCollinearKernel[Join[born,<|"EpsilonRange"->{0,0},"Coefficients"->KeyTake[born["Coefficients"],{0}]|>],finiteKernel,card];
check["finite scheme leaves the pole unchanged",plain["Coefficients"][-1]===custom["Coefficients"][-1]];
check["finite scheme applies with the distribution redefinition sign",Factor[custom["Coefficients"][0]["RegularCoefficient"]-
 plain["Coefficients"][0]["RegularCoefficient"]+alphaTest/(2Pi)expected["RegularCoefficient"]]===0];
check["factorization logarithm equals minus the pole coefficient",Factor[Coefficient[plain["Coefficients"][0]["RegularCoefficient"],Log[mfTest]]+
 plain["Coefficients"][-1]["RegularCoefficient"]]===0];
uv=FeynFacet`ConstructNLOUVCounterterm[born,card];
check["UV derives quadratic Born coupling",uv["BornCouplingPower"]===2];
zero=FeynFacet`ConstructNLOUVCounterterm[Join[born,<|"Coefficients"->Map[<|"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>&,born["Coefficients"]]|>],card];
check["zero Born gives exact zero UV",AssociationQ[zero]&&AllTrue[Values[zero["Coefficients"]],#["DeltaCoefficient"]===0&]];
Print["NLO_COUNTERTERM_WORKFLOW_TESTS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
