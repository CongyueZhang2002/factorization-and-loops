root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
coeff=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{-ep,-ep,1-ep},z,ep,3];
FTTest`FTAssert["zeroth and first Gauss coefficients",coeff[0]===1&&coeff[1]===0];
FTTest`FTAssert["second coefficient is dilogarithm",coeff[2]===PolyLog[2,z]];
poly=Sum[coeff[j]ep^j,{j,0,3}];
residual=Expand[z(1-z)D[poly,{z,2}]+(1-ep-(1-2ep)z)D[poly,z]-ep^2 poly];
FTTest`FTAssert["explicit coefficients solve the Gauss DE through order three",
 AllTrue[Table[FullSimplify[Coefficient[residual,ep,j],0<z<1],{j,0,3}],#===0&]];
endpoint=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{-ep,-ep,1-ep},1,ep,3];
FTTest`FTAssert["endpoint value is Gamma(1-eps) Gamma(1+eps)",endpoint===<|0->1,1->0,2->Pi^2/6,3->0|>];
FTTest`FTAssert["coincident angular limit uses dimensional continuation",
 FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,1,1-ep},1,ep,3]===<|0->0,1->1,2->-1,3->1|>];
FTTest`FTAssert["zero argument is exact one",
 FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,1,1-ep},0,ep,3]===<|0->1,1->0,2->0,3->0|>];
angular=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,1,1-ep},z,ep,3];
small=1/1000;error=Abs[N[Hypergeometric2F1[1,1,1-small,2/5]-Sum[angular[j]small^j,{j,0,3}]/.z->2/5,35]];
FTTest`FTAssert["angular numerical comparison has fourth-order remainder",NumberQ[error]&&error<10^-10];
FTTest`FTAssert["exports contain no unevaluated integration or recurrence",
 FreeQ[{coeff,angular},_Integrate|_Inactive|_Sum|_Product|_Hypergeometric2F1|_SeriesCoefficient]];
FTTest`FTReport[];
