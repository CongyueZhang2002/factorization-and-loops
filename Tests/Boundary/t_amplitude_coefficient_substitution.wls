
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/FeynFacet/Solution.m"];
pass=0;failed=0;check[name_,v_]:=If[TrueQ[v],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
r=FeynFacet`ReduceBoundaryAmplitudeSystem[<|"DimensionalRegulator"->eps,
 "CoefficientMatrix"->{{1,1}},"RightHandSideMatrix"->{{1}},
 "AmplitudeLaurentLowerBounds"->{-1,0},"BoundaryInputLaurentLowerBounds"->{-1}|>];
r=Join[r,<|"BoundaryInputs"->{<|"LaurentLowerBound"->-1,"LaurentCoefficients"-><|-1->1,0->2,1->3|>,
 "EpsilonOrderRange"->{-1,1}|>}|>];
expr=FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[r,{{1,-1},{1,0},{2,1}}];
check["finite Laurent convolution",expr===<|{1,-1}->1,{1,0}->2-FeynFacetSolution`C[1,0],{2,1}->FeynFacetSolution`C[1,1]|>];

withSeriesOnly=r;withSeriesOnly["BoundaryInputs"]={Join[First[r["BoundaryInputs"]],<|"AnalyticExpression"->Missing["LaurentSeriesOnly"]|>]};
check["series-only input uses its actual finite coefficients",
 FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[withSeriesOnly,{{1,-1},{1,0},{2,1}}]===expr];
unavailable=r;unavailable["BoundaryInputs"]={Join[First[r["BoundaryInputs"]],<|"LaurentCoefficients"-><|-1->Missing["Unknown"]|>|>]};
check["missing value inside a coefficient map is rejected",
 FailureQ[FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[unavailable,{{1,-1}}]]];
check["unknown omitted coefficients rejected",FailureQ[FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[r,{{1,2}}]]];
numeric=FeynFacetSolution`EvaluateBoundaryAmplitudeCoefficientValues[r,<|{1,0}->7,{1,1}->11|>,{{1,-1},{1,0},{2,1}}];
check["free coefficient values applied",Max[Abs[Values[numeric]-{1,-5,11}]]<10^-60];
shared=<|"BoundaryCoefficientDefinitions"-><|{1,0}->FeynFacetSolution`C[1,0]+FeynFacetSolution`C[2,1]|>,
 "BoundaryAmplitudes"->{<|"Definition"-><|"Original"->1|>|>,<|"Definition"-><|"Original"->2|>|>}|>;
applied=FeynFacetSolution`ApplyBoundaryAmplitudeReduction[shared,r];
check["shared definitions materially substituted",applied["UnknownBoundarySeriesCount"]===1&&
 applied["BoundaryCoefficientDefinitions"][[Key[{1,0}]]]===2-FeynFacetSolution`C[1,0]+FeynFacetSolution`C[1,1]&&
 applied["InitialConstantLaurentLowerBounds"]==={0}];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
