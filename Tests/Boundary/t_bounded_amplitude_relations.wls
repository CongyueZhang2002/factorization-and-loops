
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
pass=0;failed=0;check[name_,value_]:=If[TrueQ[value],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
run[q_,w_,lo_,bl_]:=FeynFacet`ReduceBoundaryAmplitudeSystem[<|"DimensionalRegulator"->eps,
 "CoefficientMatrix"->q,"RightHandSideMatrix"->w,"AmplitudeLaurentLowerBounds"->lo,
 "BoundaryInputLaurentLowerBounds"->bl|>];
r=run[{{1,1}},{{1}},{-7,-6},{-7}];
check["weighted pivot preserves unequal lower bounds",AssociationQ[r]&&r["SolvedAmplitudeIndices"]==={1}&&
 r["FreeAmplitudeMatrix"]==={{-eps^-6},{eps^-6}}&&r["ParticularSolutionCompatibility"]==="AutomaticFromInputBounds"];
r=run[{{1,1},{1,1+eps^2}},IdentityMatrix[2],{0,0},{0,0}];
check["epsilon squared divisibility retained",AssociationQ[r]&&
 Min[Lookup[r["RightHandSideRegularityConditions"],"LaurentLowerBoundFromInputs"]]===-2&&
 r["ParticularSolutionCompatibility"]==="RequiresBoundaryCoefficientChecks"];
r=run[{{1,1},{1,1+eps^2}},{{1},{1+eps^2}},{0,0},{0}];
check["repeated RHS combined before order planning",AssociationQ[r]&&r["BoundaryInputMatrix"]==={{0},{1}}&&
 r["ParticularSolutionCompatibility"]==="AutomaticFromInputBounds"];
r=run[{{0}},{{1}},{0},{0}];
check["zero row RHS identity retained",AssociationQ[r]&&r["ZeroRowRightHandSideConditions"]==={{1}}&&
 r["ParticularSolutionCompatibility"]==="RequiresBoundaryCoefficientChecks"];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
