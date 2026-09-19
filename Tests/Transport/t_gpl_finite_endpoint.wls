Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
Clear[x,rho,c];
constants={FeynFacetSolution`G[{0,1},1]->-Zeta[2],
 FeynFacetSolution`G[{0,1,1},1]->Zeta[3]};
rows={
 {{1},1,Log[rho]},
 {{0,1},1,-Zeta[2]+rho-rho Log[rho]+rho^2/4-rho^2 Log[rho]/2},
 {{1,0},1,Zeta[2]-rho-rho^2/4},
 {{0,0},1,rho^2/2},
 {{2},2,Log[rho]-Log[2]},
 {{0},2,Log[2]-rho/2-rho^2/8},
 {{1,1,0},1,Zeta[3]+Zeta[2]Log[rho]-rho-rho^2/8}};
Do[
 {word,endpoint,expected}=row;
 value=FeynFacetSolution`ExpandGPLAtFiniteEndpoint[
  FeynFacetSolution`G[word,x],{x,endpoint},{rho,2}];
 FTAssert["finite-endpoint word "<>ToString[word]<>" at "<>ToString[endpoint],
  !FailureQ[value]&&Expand[(value/.constants)-expected]===0];
 If[FailureQ[value],Print[InputForm[value]]],{row,rows}];
value=FeynFacetSolution`ExpandGPLAtFiniteEndpoint[
 FeynFacetSolution`G[{1,1,0},x]/(1-x)^2,{x,1},{rho,0}];
FTAssert["rational endpoint pole requests sufficient inner GPL depth",
 !FailureQ[value]&&Expand[(value/.constants)-
  ((Zeta[3]+Zeta[2]Log[rho])/rho^2-1/rho-1/8)]===0];
FTAssert["an interior GPL letter is not assigned an invented contour",
 FailureQ[FeynFacetSolution`ExpandGPLAtFiniteEndpoint[
  FeynFacetSolution`G[{1/2},x],{x,1},{rho,1}]]];
FTAssert["symbolic off-contour letters require their domain",
 FailureQ[FeynFacetSolution`ExpandGPLAtFiniteEndpoint[
  FeynFacetSolution`G[{c},x],{x,1},{rho,1}]]&&
 !FailureQ[FeynFacetSolution`ExpandGPLAtFiniteEndpoint[
  FeynFacetSolution`G[{c},x],{x,1},{rho,1},"Assumptions"->c>1]]];
FTAssert["trailing-zero shuffle identities do not become spurious constant pivots",
 Expand[FeynFacetSolution`RegularizeGPLTrailingZeros[
  FeynFacetSolution`G[{0,2},1]+FeynFacetSolution`G[{2,0},1]]]===0];
FTAssert["one-letter conjugate constants retain their principal phases",
 Simplify[FeynFacetSolution`ReduceGPLWeightOne[
  FeynFacetSolution`G[{1-I},1]+FeynFacetSolution`G[{1+I},1]-FeynFacetSolution`G[{2},1]]]===0];
FTAssert["weight-one reduction does not select a branch through a real interior letter",
 FeynFacetSolution`ReduceGPLWeightOne[FeynFacetSolution`G[{1/2},1]]===FeynFacetSolution`G[{1/2},1]];
FTAssert["classical polylogarithms use the same local GPL series machinery",
 Expand[FeynFacetSolution`ExpandGPLAtOrigin[PolyLog[2,x],{x,2},"Assumptions"->0<x<1]-x-x^2/4]===0];
FTAssert["a fixed-path letter escaping to infinity vanishes uniformly",
 FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{0,-1/x^2},1/2],{x,0}]===0];
FTAssert["separated finite parameter letters have their ordinary fixed-path limits",
 FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{-1-x,0},1/2],{x,0}]===
 FeynFacetSolution`G[{-1,0},1/2]];
FTAssert["logarithmic coefficient growth cannot spoil a positive-power vanishing kernel",
 FeynFacetSolution`ExpandGPLAtOrigin[Log[x]^2 FeynFacetSolution`G[{1/x},1/2],{x,0},
  "Assumptions"->0<x<1]===0];
FTAssert["a moving letter meeting the tangential endpoint needs resolution",
 FailureQ[FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{-x},1/2],{x,0}]]];
FTAssert["a singular prefactor requires a letter jet rather than its limit",
 FailureQ[FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{-1/x},1/2]/x,{x,0}]]];
FTAssert["assumed vanishing of a leading coefficient changes the moving-letter valuation",
 FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{2+(c-d)/x},1/2],{x,0},
  "Assumptions"->c==d]===FeynFacetSolution`G[{2},1/2]];
FTAssert["an unresolved leading coefficient cannot be treated as nonzero generically",
 FailureQ[FeynFacetSolution`ExpandGPLAtOrigin[FeynFacetSolution`G[{2+c/x},1/2],{x,0}]]];
FTAssert["symmetric weight-two words are products, not independent constants",
 Simplify[FeynFacetSolution`ReduceGPLWeightOne[FeynFacetSolution`ReduceGPLWeightTwo[
  FeynFacetSolution`G[{1-I,2},1]+FeynFacetSolution`G[{2,1-I},1]+
  FeynFacetSolution`G[{1+I,2},1]+FeynFacetSolution`G[{2,1+I},1]]]-Log[2]^2]===0];
FTAssert["a repeated letter retains its shuffle multiplicity",
 FeynFacetSolution`ReduceGPLWeightTwo[FeynFacetSolution`G[{-2,-2},x]]===
 FeynFacetSolution`G[{-2},x]^2/2];
Print["FINITE GPL ENDPOINT TEST COMPLETE"];FTReport[];
