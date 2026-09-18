Print["FEYNFACET DRIVER ENTERED"];

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
linearChart=FeynFacetSolution`QuadraticRootChart[cc+bb t,t,v];
lr=linearChart["OriginalVariableExpression"];lw=linearChart["SquareRootExpression"];
FTTest`FTAssert["linear radicands use a polynomial chart with exact unit tangent",
 PolynomialQ[lr,v]&&Cancel[Together[lw^2-cc-bb lr]]===0&&
 (lr/.v->0)===0&&(D[lr,v]/.v->0)===1&&
 Cancel[D[lr,v]/lw-1/Sqrt[cc]]===0];
constantChart=FeynFacetSolution`QuadraticRootChart[cc,t,v];
FTTest`FTAssert["constant radicand retains the identity coordinate",
 constantChart["OriginalVariableExpression"]===v&&
 Simplify[constantChart["ParameterExpression"]-t,Assumptions->cc>0]===0];
pairChart=FeynFacetSolution`Private`gplLinearRootPairChart[{1+t,1+2t},t,v];
pr=pairChart["OriginalVariableExpression"];pw=pairChart["SquareRootExpressions"];
FTTest`FTAssert["two linear roots share one exact zero-preserving coordinate",
 AssociationQ[pairChart]&&Cancel[Together[pw[[1]]^2-1-pr]]===0&&Cancel[Together[pw[[2]]^2-1-2pr]]===0&&
 (pr/.v->0)===0&&Cancel[D[pr,v]/.v->0]===1];
pairValue=FeynFacetSolution`IntegrateGPL[1/(Sqrt[1+t]Sqrt[1+2t]),{t,0,s},"TimeLimit"->20];
pairDerivative=D[pairValue,s]-1/(Sqrt[1+s]Sqrt[1+2s]);
FTTest`FTAssert["two-root integral has the exact derivative and lower value",
 !FailureQ[pairValue]&&FullSimplify[pairDerivative,Assumptions->0<s<1/2]===0&&
 (pairValue/.s->0/.FeynFacetSolution`G[letters_List,0]/;AllTrue[letters,#=!=0&]:>0)===0];
FTTest`FTAssert["three independent linear roots are not labelled rationalized",
 MatchQ[FeynFacetSolution`IntegrateGPL[1/Sqrt[(1+t)]/Sqrt[1+2t]/Sqrt[1+3t],{t,0,s}],
  Failure["RationalSquareRootChartNotConstructed",_]]];
classicalRoot=FeynFacetSolution`IntegrateGPL[
 PolyLog[2,(Sqrt[1+t]-1)/(Sqrt[1+t]+1)]/Sqrt[1+t],{t,0,s}];
classicalChart=FeynFacetSolution`QuadraticRootChart[1+t,t,v];
classicalR=classicalChart["OriginalVariableExpression"];
classicalV=classicalChart["ParameterExpression"]/.t->s;
expectedRoot=FeynFacetSolution`IntegrateGPL[PolyLog[2,v/(v+4)],{v,0,classicalV}];
FTTest`FTAssert["root-containing classical polylogs use the ordinary normalization pipeline",
 !FailureQ[classicalRoot]&&!FailureQ[expectedRoot]&&Expand[classicalRoot-expectedRoot]===0];
rationalDerivative=FeynFacetSolution`IntegrateGPL[(1-t^2)/(1+t+t^2)^2,{t,0,s}];
FTTest`FTAssert["compact exact rational derivatives do not introduce cancelling algebraic GPLs",
 FreeQ[rationalDerivative,_FeynFacetSolution`G]&&
 Cancel[Together[rationalDerivative-s/(1+s+s^2)]]===0];
refinedConstant=FeynFacetSolution`IntegrateGPL[Sqrt[(1+zz)^2],{t,0,s},"Assumptions"->0<zz<1];
oppositeConstant=FeynFacetSolution`IntegrateGPL[Sqrt[(1+zz)^2],{t,0,s},"Assumptions"->zz< -1];
FTTest`FTAssert["constant radicals are simplified only in the supplied real domain",
 Expand[refinedConstant-s(1+zz)]===0&&Expand[oppositeConstant+s(1+zz)]===0];
imaginaryPair=FeynFacetSolution`IntegrateGPL[1/(Sqrt[-1+t]Sqrt[1+2t]),{t,0,s}];
FTTest`FTAssert["imaginary basepoint root retains its initial branch",
 !FailureQ[imaginaryPair]&&FullSimplify[D[imaginaryPair,s]-1/(Sqrt[-1+s]Sqrt[1+2s]),
 Assumptions->0<s<1/2]===0];
negativePair=FeynFacetSolution`IntegrateGPL[1/(Sqrt[-1-t]Sqrt[-1-2t]),{t,0,s}];
FTTest`FTAssert["two imaginary initial roots keep the product sign",
 !FailureQ[negativePair]&&FullSimplify[D[negativePair,s]+1/(Sqrt[1+s]Sqrt[1+2s]),
 Assumptions->0<s<1/2]===0&&
 (negativePair/.s->0/.FeynFacetSolution`G[letters_List,0]/;AllTrue[letters,#=!=0&]:>0)===0];
mixedChart=FeynFacetSolution`Private`gplLinearRootPairChart[{1+t,-1+t/2},t,v];
mixedR=mixedChart["OriginalVariableExpression"];mixedRoots=mixedChart["SquareRootExpressions"];
mixedInverse=4mixedR/((1+mixedRoots[[2]]/I)(mixedRoots[[1]]+mixedRoots[[2]]/I));
FTTest`FTAssert["the returned two-root lift has an exact inverse and initial phase",
 Cancel[Together[mixedInverse-v]]===0&&
 (mixedChart["Jacobian"]/Times@@mixedRoots/.v->0)===-I];
expandedRadical=FeynFacetSolution`IntegrateGPL[Sqrt[1+2zz+zz^2],{t,0,s},
 "Assumptions"->0<zz<1];
FTTest`FTAssert["expanded radicands are factored before domain refinement",
 Expand[expandedRadical-s(1+zz)]===0];
scaledPair=FeynFacetSolution`IntegrateGPL[1/(Sqrt[1+pp t]Sqrt[1+2pp t]),{t,0,s},
 "Assumptions"->pp>0];
FTTest`FTAssert["positive scale extraction preserves the exact two-root derivative",
 !FailureQ[scaledPair]&&FullSimplify[D[scaledPair,s]-1/(Sqrt[1+pp s]Sqrt[1+2pp s]),
 Assumptions->pp>0&&0<s<1/(4pp)]===0];
scaledChart=FeynFacetSolution`Private`gplLinearRootPairChart[{1+pp t,1+2pp t},t,v];
scaledMap=scaledChart["OriginalVariableExpression"]/.v->v/pp;
scaledLog=FeynFacetSolution`PullbackGPL[FeynFacetSolution`G[{0},t],{t->scaledMap,v},
 "Assumptions"->pp>0];
scaledLower=Expand[scaledLog-FeynFacetSolution`G[{0},v]]/.v->0/.
 FeynFacetSolution`G[{letter_},0]/;letter=!=0:>0;
FTTest`FTAssert["coordinate scaling retains the lower-end logarithm",
 FullSimplify[scaledLower+Log[pp],Assumptions->pp>0]===0];
identityPullback=FeynFacetSolution`PullbackGPL[FeynFacetSolution`G[{-1,0},t],
 {t->(v+v^2)/(1+v),v}];
identityIntegral=FeynFacetSolution`IntegrateGPL[
 FeynFacetSolution`G[{-1},(t+t^2)/(1+t)]/(1+t),{t,0,s}];
FTTest`FTAssert["rational arguments that cancel to the identity are actually normalized",
 identityPullback===FeynFacetSolution`G[{-1,0},v]&&
 identityIntegral===FeynFacetSolution`G[{-1,-1},s]];
FTTest`FTReport[];
