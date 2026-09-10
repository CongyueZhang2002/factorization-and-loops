$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
Clear[localT,localS];
a=FeynFacetSolution`RescaleGPLArguments[FeynFacetSolution`G[{1/localT,0},1],localT,localT>0];
FTAssert["positive rescaling retains the trailing-zero basepoint correction",
 a===FeynFacetSolution`G[{1,0},localT]-Log[localT]FeynFacetSolution`G[{1},localT]];
FTAssert["an all-zero word at one remains zero",Expand[
 FeynFacetSolution`RescaleGPLArguments[FeynFacetSolution`G[{0,0},1],localT,localT>0]/.
 FeynFacetSolution`G[{0,0},localT]->Log[localT]^2/2/.
 FeynFacetSolution`G[{0},localT]->Log[localT]]===0];
FTAssert["unproved complex rescaling is rejected",
 FailureQ[FeynFacetSolution`RescaleGPLArguments[FeynFacetSolution`G[{1},localT],localS]]];
FTAssert["local GPL series retains logarithmic terms",
 Expand[FeynFacetSolution`ExpandGPLAtOrigin[a,{localT,2}]-localT-localT^2/4]===0];
FTAssert["rational poles demand deeper GPL coefficients",
 FeynFacetSolution`ExpandGPLAtOrigin[(FeynFacetSolution`G[{1},localT]+localT)/localT^2,{localT,0}]===-1/2];
FTAssert["analytic logarithms and GPLs cancel locally",
 FeynFacetSolution`ExpandGPLAtOrigin[(Log[1-localT]-FeynFacetSolution`G[{1},localT])/localT^3,{localT,0}]===0];
FTReport[];
