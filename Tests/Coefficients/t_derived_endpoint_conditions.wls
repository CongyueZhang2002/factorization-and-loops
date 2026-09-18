Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
req=<|"DimensionalRegulator"->ee,"NormalVariables"->{rr,tt},"Intervals"->{{0,1},{0,1}},
 "Assumptions"->True,"TestFunctionSupport"-><|"ExcludedFaces"->{rr->1,tt->1}|>|>;
derive[x_]:=FeynFacet`ConstructNormalCrossingEndpointData[x,req];
data=derive[rr^(-1-ee)tt^(-1-2ee)(1+rr+tt)/((1-rr)(1-tt))];
FTTest`FTAssert["powers and normal-domain conditions are derived",AssociationQ[data]&&data["Terms"][[1]]["Powers"]==={-1-ee,-1-2ee}];
FTTest`FTAssert["interior pole rejected despite finite endpoint value",FailureQ[derive[rr^(-1-ee)tt^(-1-2ee)/(1-2rr)]]];
FTTest`FTAssert["unresolved intersection rejected",FailureQ[derive[rr^(-1-ee)tt^(-1-ee)/(rr+tt)]]];
FTTest`FTAssert["epsilon-dependent moving denominator rejected",FailureQ[derive[rr^(-1-ee)tt^(-1-ee)/(rr+ee)]]];
FTTest`FTAssert["excluded opposite faces must be explicit",FailureQ[FeynFacet`ConstructNormalCrossingEndpointData[rr^(-1-ee)tt^(-1-ee)/(1-rr),KeyDrop[req,"TestFunctionSupport"]]]];
FTTest`FTAssert["zero component has zero smooth factor",AssociationQ[derive[0]]&&derive[0]["Terms"][[1]]["SmoothFactor"]===0];
FTTest`FTAssert["assumptions cannot exclude the tested endpoint",FailureQ[FeynFacet`ConstructNormalCrossingEndpointData[rr^(-1-ee),Join[req,<|"Assumptions"->rr>0|>]]]];
data=derive[rr^(-1-ee)tt^(-1-2ee)(1+rr+tt)];
a=FeynFacet`ExtractEndpointDistributions[data,<|"ThroughOrder"->0|>];
b=FeynFacet`ExtractEndpointDistributions[Join[req,<|"EndpointGeometry"->"NormalCrossings",
 "EndpointConditions"-><|"JointlySmoothFactors"->True,"UniformEpsilonExpansion"->True,"NoOtherSingularities"->True|>,
 "Terms"->{<|"Powers"->{-1-ee,-1-2ee},"SmoothFactor"->1+rr+tt|>}|>],<|"ThroughOrder"->0|>];
FTTest`FTAssert["derived endpoint data preserve known coefficients",AssociationQ[a]&&a["Coefficients"]===b["Coefficients"]];
Print["DERIVED ENDPOINT CONDITIONS COMPLETED"];FTTest`FTReport[];
