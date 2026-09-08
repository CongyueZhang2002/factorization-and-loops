
root="/home/maxzhang/factorization-and-loops";
Get[root<>"/FeynFacet/Solution.m"];
pass=0;failed=0;check[name_,v_]:=If[TrueQ[v],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
shared=<|"OrdinaryPointBoundaryBasis"->{<|"ConnectionRow"->1,"NormalCoordinates"->{1/3}|>,
 <|"ConnectionRow"->2,"NormalCoordinates"->{1/3}|>},
 "BoundaryCoefficientDefinitions"-><|{1,0}->0,{2,0}->0|>|>;
construction=<|"PreparedBoundarySystem"-><|"NormalizedDifferentialSystem"-><|
 "Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->{{eps/z,0},{1/(1-z),0}}|>,
 "NormalizedToOriginalGauge"->{{1/eps,0},{0,1}}|>,"BoundarySeed"-><|"Basis"->IdentityMatrix[2]|>,
 "AmplitudeLaurentLowerBounds"->{-2,-1},"UnknownAmplitudeDefinitions"->{
 <|"Index"->1,"Definition"-><|"SeedColumn"->1|>|>,<|"Index"->2,"Definition"-><|"SeedColumn"->2|>|>},
 "KnownAmplitudeExpressions"-><||>|>;
supplied=<|{1,-2}->1,{1,-1}->0,{1,0}->0,{1,1}->0,{2,-1}->1,{2,0}->0|>;
r=FeynFacetSolution`EvaluateSharedBoundaryCoefficients[shared,construction,supplied];
Print["RESULT ",r];
check["closed seed demands accepted",AssociationQ[r]];
If[AssociationQ[r],
 v=r["BoundaryCoefficientValues"];
 check["pole in gauge handled",Abs[v[[Key[{1,0}]]]-Log[1/3]^3/6]<10^-24];
 expected=-Log[1/3]^2 Log[2/3]/2-Log[1/3]PolyLog[2,1/3]+PolyLog[3,1/3];
 check["coupled Laurent coefficient",Abs[v[[Key[{2,0}]]]-expected]<10^-24]];
bad=FeynFacetSolution`EvaluateSharedBoundaryCoefficients[shared,construction,KeyDrop[supplied,{{1,1}}]];
check["missing required coefficient rejected",FailureQ[bad]];
record=<|"SharedBoundaryDefinitionFile"->"unused","MasterIntegralCoefficients"-><|0->{{1,FeynFacetSolution`B[1,0]+FeynFacetSolution`B[2,0]}}|>,
 "RequiredInitialConstantCoefficients"->{{1,0}}|>;
applied=FeynFacetSolution`ApplyNumericalBoundaryCoefficients[record,<|{1,0}->2,{2,0}->3|>];
check["numeric B substitutions avoid endpoint integrals",applied["MasterIntegralCoefficients"][0]==={{1,5}}&&applied["RequiredInitialConstantCoefficients"]==={}];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
