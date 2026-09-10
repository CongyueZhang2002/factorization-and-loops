$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
glCases={{Log[2glT],glS(Log[2glS]-1)},{Log[glT]^2,glS(Log[glS]^2-2Log[glS]+2)},
 {glT Log[3/glT],glS^2/2(Log[3/glS]+1/2)}};
Do[
 glValue=FeynFacetSolution`IntegrateGPL[First[glCase],{glT,0,glS}];
 glValue=glValue/.FeynFacetSolution`G[w_List,glS]/;AllTrue[w,#===0&]:>Log[glS]^Length[w]/Factorial[Length[w]];
 FTTest`FTAssert["integrable endpoint logarithm "<>ToString[First[glCase],InputForm],
  !FailureQ[glValue]&&FullSimplify[glValue-Last[glCase],Assumptions->glS>0]===0],
 {glCase,glCases}];
FTTest`FTAssert["a genuinely divergent logarithmic endpoint remains rejected",
 FailureQ[FeynFacetSolution`IntegrateGPL[Log[glT]/glT,{glT,0,glS}]]];
FTTest`FTReport[];
