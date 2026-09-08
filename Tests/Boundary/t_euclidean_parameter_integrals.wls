
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/Tests/TestKit.wl"];
form[a_,b_,w_:1]:=<|"LoopCoefficients"->a,"ExternalCoefficients"->b,"Weight"->w|>;
den[forms_]:=<|"Power"->1,"SquaredForms"->forms|>;
data=<|"DimensionalRegulator"->ee,"LoopDimension"->2-2ee,"ExternalGramMatrix"->{{3/7}},
 "QuadraticDenominators"->{den[{form[{1},{0}]}],den[{form[{1},{1}]}]}|>;
param=FeynFacet`ConstructEuclideanParameterIntegral[data];
value=FeynFacet`IntegrateEulerBoundaryIntegral[param,{-2,0},"IntegrationBackend"->"GammaBeta"];
FTAssert["Gaussian normalization agrees with a Euclidean bubble",
 AssociationQ[value]&&FullSimplify[(value["AnalyticExpression"]-Pi^3/Sqrt[3/7])/.ee->-1/2]===0];
data["QuadraticDenominators"]={den[{form[{1,0},{0}],form[{0,1},{0}]}],
 den[{form[{1,0},{1}],form[{0,1},{1}]}]};
param=FeynFacet`ConstructEuclideanParameterIntegral[data];
value=FeynFacet`IntegrateEulerBoundaryIntegral[param,{-2,0},"IntegrationBackend"->"GammaBeta"];
FTAssert["rank-two denominators give the bubble in twice the loop dimension",
 AssociationQ[value]&&FullSimplify[(value["AnalyticExpression"]-Pi^3/Sqrt[6/7])/.ee->1/4]===0];
data["QuadraticDenominators"]={den[{form[{1,0},{0}]}],den[{form[{0,1},{0}]}]};
param=FeynFacet`ConstructEuclideanParameterIntegral[data];
FTAssert["a homogeneous Euclidean integral has an explicit scaleless record",
 AssociationQ[param]&&TrueQ[param["Scaleless"]]&&param["Terms"][[1,"Prefactor"]]===0];
data["QuadraticDenominators"]={den[{form[{1},{0},-1]}],den[{form[{1},{1}]}]};
FTAssert["negative squared-form weights are rejected",FailureQ[FeynFacet`ConstructEuclideanParameterIntegral[data]]];
FTReport[];
