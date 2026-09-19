Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];Clear[x];
constants={FeynFacetSolution`G[{0,1},1]->-Zeta[2],
 FeynFacetSolution`G[{0,0,1},1]->-Zeta[3],FeynFacetSolution`G[{0,1,1},1]->Zeta[3]};
Do[
 {integrand,endpoint,expected}=row;
 result=FeynFacetSolution`IntegrateGPLHadamardFinitePart[integrand,{x,0,endpoint}];
 FTAssert["Hadamard finite part of "<>ToString[InputForm[integrand]]<>" on "<>ToString[endpoint],
  AssociationQ[result]&&Simplify[(result["Value"]/.constants)-expected]===0&&
  !result["MeromorphicDimensionalIntegralEstablished"]];
 If[FailureQ[result],Print[InputForm[result]]],
 {row,{{1/x+1/(1-x),1,0},{1/x^2,1,-1},{1/(1-x)^2,1,-1},
  {Log[x]/x^2,1,-1},{Log[x]/x,1,0},{Log[1-x]/x,1,-Zeta[2]},
  {FeynFacetSolution`G[{0,1},x]/x,1,-Zeta[3]},{1/x,2,Log[2]}}}];
FTAssert["an internal real pole cannot receive an implicit contour prescription",
 FailureQ[FeynFacetSolution`IntegrateGPLHadamardFinitePart[1/(x-1/2),{x,0,1}]]&&
 FailureQ[FeynFacetSolution`IntegrateGPLHadamardFinitePart[1/(x-1/2)^2,{x,0,1}]]];
Print["GPL HADAMARD FINITE PART TEST COMPLETE"];FTReport[];
