
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
g=FeynFacetSolution`G;
chart=FeynFacetSolution`QuadraticRootChart[aa t^2+bb t+cc,t,v];
r=chart["OriginalVariableExpression"];w=chart["SquareRootExpression"];
FTTest`FTAssert["symbolic conic equation, Jacobian and unit tangent",
 AssociationQ[chart]&&Cancel[Together[w^2-(aa r^2+bb r+cc)]]===0&&
 (r/.v->0)===0&&Cancel[D[r,v]/.v->0]===1&&
 Cancel[Together[D[r,v]/w-1/(Sqrt[cc](1-bb v/(2cc)+(bb^2-4aa cc)v^2/(16cc^2)))]]===0];
FTTest`FTAssert["ramified basepoint is rejected explicitly",
 FailureQ[FeynFacetSolution`QuadraticRootChart[t+t^2,t,v]]];
simple=FeynFacetSolution`PullbackGPL[g[{-1,0},t],{t->2v,v}];
FTTest`FTAssert["rescaling retains trailing-zero tangent constant",
 simple===g[{-1/2,0},v]+Log[2]g[{-1/2},v]];
map=v/(1-v);
pull[w_]:=FeynFacetSolution`PullbackGPL[g[w,t],{t->map,v}];
words={{0},{0,0},{-1,0},{0,-1},{-1,0,0},{-1,-2}};
results=pull/@words;
(* GPL shuffle reduction turns exact derivative comparisons into rational
   coefficient identities, avoiding numerical sampling. *)
zero[expr_]:=Block[{FeynFacetSolution`Private`$gplMaxTerms=10000},
 And@@(TrueQ[Cancel[Together[#]]===0]&/@Values[FeynFacetSolution`Private`gplWords[Expand[expr],v]])];
FTTest`FTAssert["word derivatives agree for logarithmic and mixed words",
 And@@MapThread[zero[D[#2,v]-D[map,v]/(map-First[#1])If[Rest[#1]==={},1,pull[Rest[#1]]]]&,{words,results}]];
q=1-2t/3+4t^2/9;
chart=FeynFacetSolution`QuadraticRootChart[q,t,v];r=chart["OriginalVariableExpression"];
FTTest`FTAssert["known physical conic chart has the positive orientation",
 r===v/(1+v/3-v^2/12)||Cancel[Together[r-v/(1+v/3-v^2/12)]]===0];
answer=FeynFacetSolution`IntegrateGPL[1/Sqrt[q],{t,0,s}];
target=3/2(g[{-2},chart["ParameterExpression"]/.t->s]-g[{6},chart["ParameterExpression"]/.t->s]);
FTTest`FTAssert["root kernel integrates to the exact expected GPL difference",
 !FailureQ[answer]&&FullSimplify[answer-target,Assumptions->s>0]===0];
linear=FeynFacetSolution`IntegrateGPL[1/Sqrt[1+t],{t,0,s}];
FTTest`FTAssert["linear root with negative unnormalized tangent is integrated",
 !FailureQ[linear]&&FullSimplify[linear-2(Sqrt[1+s]-1),Assumptions->s>0]===0];
Print["ROOT ANSWER ",InputForm[answer]," LINEAR ",InputForm[linear]];
FTTest`FTReport[];
