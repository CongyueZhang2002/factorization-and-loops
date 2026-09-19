Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];Clear[x,t];k=FeynFacetSolution`K;f=FeynFacetSolution`F;
data=<|"KinematicVariables"->{x},"BasePoint"->{0},"Path"-><|"Parameter"->t,"Coordinates"->{t x}|>,
 "KernelDefinitions"->{<|"Parameter"->t,"Expression"->x/(1-x t)|>},
 "IntegralDefinitions"->{<|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]|>,
 <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]f[1,t]|>},
 "AlgebraicDefinitions"->{},"Coefficients"-><|0->{1->{1}},1->{1->{f[1,1]}},2->{1->{f[2,1]}}|>|>;
prior=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,"Assumptions"->0<x<1];
next=Join[data,<|"KernelDefinitions"->Prepend[data["KernelDefinitions"],<|"Parameter"->t,"Expression"->7|>],
 "IntegralDefinitions"->Append[data["IntegralDefinitions"]/.k[1,t]->k[2,t],
 <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[2,t]f[2,t]|>],
 "Coefficients"->Append[data["Coefficients"],3->{1->{f[3,1]}}]|>];
reused=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[next,"Assumptions"->0<x<1,"PriorSolution"->prior];
fresh=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[next,"Assumptions"->0<x<1];
FTAssert["changed kernel IDs preserve exactly identical explicit integrands",
 AssociationQ[reused]&&reused["GPLRepresentation"]["PriorSolutionIntegrandsReused"]===2&&
 reused["GPLRepresentation"]["DistinctIntegrandsAttempted"]===1];
FTAssert["incremental conversion equals an independent fresh conversion",
 reused["GPLRepresentation"]["IntegralExpressions"]===fresh["GPLRepresentation"]["IntegralExpressions"]];
changed=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->2x/(1-x t)|>}|>];
new=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[changed,"Assumptions"->0<x<1,"PriorSolution"->prior];
FTAssert["matching IDs alone never authorize reusing changed integrands",
 new["GPLRepresentation"]["PriorSolutionIntegrandsReused"]===0];
FTAssert["prior conversion domains cannot be silently weakened",
 FailureQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[next,"PriorSolution"->prior]]];
FTAssert["a prior result must still match its own exact input definitions",
 FailureQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[next,"Assumptions"->0<x<1,
 "PriorSolution"->Join[prior,<|"KernelDefinitions"->{}|>]]]];
Print["INCREMENTAL GPL CONVERSION TEST COMPLETE"];FTReport[];
