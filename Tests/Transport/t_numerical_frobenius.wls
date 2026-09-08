
Get["/home/maxzhang/factorization-and-loops/FeynFacet/Solution.m"];
pass=0;failed=0;
check[name_,test_]:=If[TrueQ[test],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
prep=FeynFacetSolution`PrepareFrobeniusNumerics[
 <|"Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->{{eps/z,0},{1/(1-z),0}}|>,{0,2}];
check["preparation",AssociationQ[prep]];
r=FeynFacetSolution`EvaluateFrobeniusSolution[prep,{{1,0},{0,0},{0,0}},1/3,
 "MatchingParameter"->1/8,"AccuracyGoal"->20,"PrecisionGoal"->20,"Verbose"->True];
Print["RESULT ",KeyDrop[r,"NormalizedEpsilonCoefficients"]];
check["continuation",AssociationQ[r]];
If[AssociationQ[r],v=r["NormalizedEpsilonCoefficients"];
 check["z^epsilon",Max[Abs[Table[v[k][[1]]-Log[1/3]^k/k!,{k,0,2}]]]<10^-25];
 check["logarithm",Abs[v[0][[2]]+Log[1-1/3]]<10^-25];
 check["dilogarithm",Abs[v[1][[2]]+Log[1/3] Log[1-1/3]+PolyLog[2,1/3]]<10^-25]];
q=FeynFacetSolution`PrepareFrobeniusNumerics[
 <|"Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->{{0,0,0},{1/z,0,0},{0,1/z,0}}|>,{-2,0}];
r2=FeynFacetSolution`EvaluateFrobeniusSolution[q,{{1,0,0},{0,0,0},{0,0,0}},1/3,"MatchingParameter"->1/4];
check["Jordan logarithms",AssociationQ[r2]&&Max[Abs[r2["NormalizedEpsilonCoefficients"][-2]-{1,Log[1/3],Log[1/3]^2/2}]]<10^-25];
check["nonnilpotent residue rejected",FailureQ[FeynFacetSolution`PrepareFrobeniusNumerics[
 <|"Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->{{1/z}}|>,{0,0}]]];

trap=FeynFacetSolution`PrepareFrobeniusNumerics[
 <|"Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->{{eps^11}}|>,{-8,3}];
trapSeed=ConstantArray[{0},12];trapSeed[[1]]={1};
trapResult=FeynFacetSolution`EvaluateFrobeniusSolution[trap,trapSeed,1/3];
check["connection depth is high minus low",AssociationQ[trapResult]&&
 Abs[trapResult["NormalizedEpsilonCoefficients"][3][[1]]-1/3]<10^-25];

Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
