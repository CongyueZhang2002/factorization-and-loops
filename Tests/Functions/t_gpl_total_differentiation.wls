Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
g=FeynFacetSolution`G;diff=FeynFacetSolution`DifferentiateGPLExpression;
FTTest`FTAssert["a moving single letter has the derivative of its physical logarithm",
 Together[diff[g[{1/x},1],x]-D[Log[1-x],x]]===0];
FTTest`FTAssert["coincident moving letters are combined before singular differences are divided",
 Together[(diff[g[{1/x,1/x},1],x]/.g[{1/x},1]->Log[1-x])-D[Log[1-x]^2/2,x]]===0];
FTTest`FTAssert["trailing zero letters obey the tangential-basepoint scaling law",
 FullSimplify[diff[g[{2x,0},x],x]-g[{2x},x]/x]===0];
FTTest`FTAssert["all-zero words retain the logarithmic endpoint derivative",
 FullSimplify[diff[g[{0,0},x],x]-Log[x]/x]===0];
expression=g[{1/x,-1,1/x},1/2]+Log[x]g[{-1/x,1},1/2];
derivative=diff[expression,x];h=1/10^12;
number=FeynFacetSolution`EvaluateGPLExpression[derivative,{x->1/3},"WorkingPrecision"->65];
plus=FeynFacetSolution`EvaluateGPLExpression[expression,{x->1/3+h},"WorkingPrecision"->65];
minus=FeynFacetSolution`EvaluateGPLExpression[expression,{x->1/3-h},"WorkingPrecision"->65];
FTTest`FTAssert["moving-letter total differentials agree with high-precision numerical variation",
 NumericQ[number]&&Abs[number-(plus-minus)/(2h)]<10^-22];
Print["GPL TOTAL DIFFERENTIATION TEST COMPLETE"];FTTest`FTReport[];
