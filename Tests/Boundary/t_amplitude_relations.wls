
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
eq=<|"Matrix"->{{1,eps,0},{0,1,1}},"Values"->{Gamma[1-eps],0}|>;
r=FeynFacet`SolveBoundaryAmplitudeRelations[eq,eps,eps->1/97];
If[FailureQ[r]||r["SolvedAmplitudeIndices"]=!={1,2}||r["RemainingAmplitudeIndices"]=!={3}||
 r["KnownAmplitudeVector"]=!={Gamma[1-eps],0,0}||r["RemainingAmplitudeMatrix"]=!={{eps},{-1},{1}},
 Print["FAIL ",r];Exit[1]];
bad=FeynFacet`SolveBoundaryAmplitudeRelations[<|"Matrix"->{{1,2},{2,4}},"Values"->{1,2}|>,eps,eps->1/97];
If[!FailureQ[bad],Print["FAIL DEPENDENCE"];Exit[1]];
Print["PASS AMPLITUDE ELIMINATION AND DEPENDENCE REJECTION"];Exit[0];
