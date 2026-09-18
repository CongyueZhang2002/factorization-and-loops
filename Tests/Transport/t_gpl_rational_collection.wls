Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
coefficients=Table[Expand[(p+q+i)^8],{i,40}];
input=(1+Sum[coefficients[[i]]/(t+i),{i,40}])/(1+t)-
 Sum[coefficients[[i]]/((1+t)(t+i)),{i,40}];
FTAssert["the cancellation fixture retains a large rational input",LeafCount[input]>20000];
answer=FeynFacetSolution`IntegrateGPL[input,{t,0,s},"TimeLimit"->30];
FTAssert["large rational word coefficients cancel before integration",
 answer===FeynFacetSolution`G[{-1},s]];
FTReport[];
