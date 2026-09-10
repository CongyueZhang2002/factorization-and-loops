root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;passed=0;failed=0;
check[label_,test_]:=If[TrueQ[test],passed++;Print["PASS ",label],failed++;Print["FAIL ",label]];
row[d_,p_:<||>,r_:0]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->r|>;
contribution[type_,pole_,finite_]:=FeynFacet`CreatePartonicResult[<|-1->row[pole],0->finite|>,<|
 "Contribution"->type,"Order"->"NLO","Scale"->sTest,"Variables"->{vTest,wTest},"DimensionalRegulator"->epTest|>];
inputs=<|"R"->contribution["Real",1,row[3,<||>,wTest]],
 "V"->contribution["Virtual",-1,row[2]],"PDF"->contribution["Counterterm",0,row[0,<|2->5|>]]|>;
request=<|"RequiredContributions"->Keys[inputs],"BornDensity"->FeynFacet`CreatePartonicResult[<|0->row[1/vTest]|>,<|
 "Order"->"LO","Contribution"->"Born","Scale"->sTest,"Variables"->{vTest,wTest},"DimensionalRegulator"->epTest|>],
 "Scale"->sTest,"Variables"->{vTest,wTest},"Assumptions"->sTest>0&&0<vTest<1&&0<wTest<1|>;
result=FeynFacet`AssembleNLOHardFunction[inputs,request];
check["finite scheme can contain a higher logarithmic plus distribution",AssociationQ[result]&&result["Coefficients"][0]["PlusCoefficients"][2]===5];
check["finite coefficients retained after exact pole cancellation",AssociationQ[result]&&result["Coefficients"][0]["DeltaCoefficient"]===5&&result["Coefficients"][0]["RegularCoefficient"]===wTest];
check["missing required contribution rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[KeyDrop[inputs,"PDF"],request]]];
broken=inputs;broken["V"]=ReplacePart[broken["V"],{"Coefficients",Key[-1],"DeltaCoefficient"}->-2];
check["uncancelled pole rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["R"]=Join[broken["R"],<|"Coefficients"->KeyDrop[broken["R"]["Coefficients"],0]|>];
check["missing finite epsilon coefficient rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["R"]=ReplacePart[broken["R"],{"Coefficients",Key[0]}->KeyDrop[broken["R"]["Coefficients"][0],"RegularCoefficient"]];
check["missing distribution field is not assumed zero",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["PDF"]=ReplacePart[broken["PDF"],{"Coefficients",Key[0],"PlusCoefficients"}-><|1/2->5|>];
check["noninteger plus logarithm order rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["R"]=ReplacePart[broken["R"],{"Coefficients",Key[0],"RegularCoefficient"}->FeynFacetSolution`F[1,wTest]];
check["unevaluated finite integral rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["R"]=ReplacePart[broken["R"],{"Coefficients",Key[0],"RegularCoefficient"}->epTest];
check["residual regulator inside epsilon coefficient rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
broken=inputs;broken["R"]=ReplacePart[broken["R"],{"Coefficients",Key[0],"RegularCoefficient"}->OtherRegulator`epTest];
check["same-named regulator in another context rejected",FailureQ[FeynFacet`AssembleNLOHardFunction[broken,request]]];
Print["NLO_HARD_FUNCTION_ASSEMBLY_TESTS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
