$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
eiConditions=<|"NoInteriorSingularities"->True,"UniformEpsilonExpansionOnCompactSubsets"->True,
 "RepresentationValidOnHalfOpenInterval"->True|>;
eiExpression=(eiZ+Global`Epsilon)/Global`Epsilon*eiZ^(-1-Global`Epsilon);
eiExpansion=FeynFacet`ConstructAnalyticEndpointExpansion[eiExpression,<|"DimensionalRegulator"->Global`Epsilon,
 "Variable"->eiZ,"Assumptions"->True,"ThroughOrder"->1,"EndpointConditions"->eiConditions|>];
FTTest`FTAssert["an epsilon-suppressed endpoint coefficient still determines the endpoint power",
 AssociationQ[eiExpansion]&&eiExpansion["EndpointLeadingPower"]===-1-Global`Epsilon&&
 eiExpansion["EndpointLeadingCoefficient"]===1];
eiResult=FeynFacet`ExtractEndpointDistributions[eiExpansion,<|"ThroughOrder"->1|>];
eiCoefficients=eiResult["Components"][[1]]["Coefficients"];
eiMoment[expr_]:=Module[{ordinary},
 ordinary=expr/.{FeynFacet`EndpointDeltaDerivative[eiZ,0,1]->1,
 FeynFacet`EndpointPlusDistribution[eiZ,-1,_Integer,1,1]->0};
 Integrate[ordinary,{eiZ,0,1}]];
FTTest`FTAssert["distributional endpoint poles cancel in the exact constant-test-function moment",
 FullSimplify[eiMoment[eiCoefficients[-1]]]===0&&
 FullSimplify[eiMoment[eiCoefficients[0]]]===1&&
 FullSimplify[eiMoment[eiCoefficients[1]]]===1];
FTTest`FTAssert["the same expression has distinct regulator and coordinate Laurent orders",
 FeynFacet`Private`analyticEndpointLeading[eiZ+Global`Epsilon,Global`Epsilon,eiZ,True]==={0,Global`Epsilon}&&
 FeynFacet`DetermineLaurentValuation[eiZ+Global`Epsilon,Global`Epsilon]===0];
FTTest`FTReport[];
