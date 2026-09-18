Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
logarithm=FeynFacetSolution`G[{1/h^2},t]+FeynFacetSolution`G[{-1/h^2},t]-2Log[h]-FeynFacetSolution`G[{1},t]-FeynFacetSolution`G[{-1},t];
value=FeynFacetSolution`IntegrateGPL[(1-t^2)/(1-h^4 t^2)^2 logarithm,{t,0,1},"Assumptions"->0<h<1];
FTTest`FTAssert["short rational-log primitives cancel divergent upper-end GPL coefficients exactly",
 !FailureQ[value]&&FreeQ[value,FeynFacetSolution`G[{1},1]|_Integrate|_FeynFacetSolution`IntegrateGPL|Indeterminate|_DirectedInfinity]];
If[FailureQ[value],Print[InputForm[value]];FTTest`FTReport[];Exit[1]];
number=FeynFacetSolution`EvaluateGPLExpression[value,{h->1/2},"WorkingPrecision"->40];
reference=NIntegrate[(1-t^2)/(1-t^2/16)^2 Log[(1-t^2/16)/((1-t^2)/4)],{t,0,1},
 WorkingPrecision->40,AccuracyGoal->25,PrecisionGoal->25];
FTTest`FTAssert["the explicit finite GPL result agrees with direct convergent quadrature",
 NumericQ[number]&&Abs[number-reference]<10^-23];
Print["GPL FINITE UPPER CANCELLATION TEST COMPLETE"];FTTest`FTReport[];
