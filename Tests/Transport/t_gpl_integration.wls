#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
Clear[t,z,x];g=FeynFacetSolution`G;
integrate[ex_,opts___]:=FeynFacetSolution`IntegrateGPL[ex,{t,0,z},opts];
value[ex_,point_]:=FeynFacetSolution`EvaluateGPLExpression[ex,{z->point},"WorkingPrecision"->60];
res=integrate[1/(t-2)];
FTAssert["simple-pole sign and normalization",res===g[{2},z]&&D[res,z]===1/(z-2)];
res=integrate[t^2+1/(t-2)^3];
FTAssert["rational exact differentials retain the lower-end term",
 FullSimplify[res-(z^3/3+1/8-1/(2(z-2)^2))]===0];
res=integrate[1/(1+t^2)^2];
FTAssert["repeated irreducible quadratic factor uses Hermite reduction",
 !FailureQ[res]&&Abs[value[res,1/2]-N[(2/5+ArcTan[1/2])/2,60]]<10^-45];
res=integrate[g[{2},t]/(t-3)^2];
FTAssert["integration by parts reduces higher poles multiplying GPLs",
 !FailureQ[res]&&FullSimplify[D[res,z]-g[{2},z]/(z-3)^2]===0];
res=integrate[g[{2},t]^2/(t-3)];
FTAssert["shuffle multiplicities are retained",res===2 g[{3,2,2},z]];
FTAssert["shuffled primitive agrees with independent numerical quadrature",
 Abs[value[res,1/2]-NIntegrate[Log[1-t/2]^2/(t-3),{t,0,1/2},
  WorkingPrecision->60,AccuracyGoal->45,PrecisionGoal->45]]<10^-40];
res=integrate[(g[{2},t]+t/2)/t^2];
FTAssert["a vanishing GPL times a pole has a nonzero finite endpoint contribution",
 !FailureQ[res]&&FreeQ[res,_Failure]&&
 Abs[value[res,1/2]-NIntegrate[(Log[1-t/2]+t/2)/t^2,{t,0,1/2},
  WorkingPrecision->60,AccuracyGoal->45,PrecisionGoal->45]]<10^-40];
FTAssert["a genuinely divergent lower endpoint is rejected",
 MatchQ[integrate[g[{2},t]/t^2],Failure["GPLLowerEndpointNotFinite",_]]];
FTAssert["reciprocals of earlier logarithms are not a GPL closure claim",
 MatchQ[integrate[1/(1+Log[1+t])],Failure["NonPolynomialDependenceOnGPL",_]]];
FTAssert["non-rational kernels remain unsupported",
 MatchQ[integrate[1/Sqrt[(1-t^2)(1-2 t^2)]],Failure["NonRationalGPLCoefficient",_]]];
FTAssert["letters depending on their integration variable are rejected",
 MatchQ[integrate[g[{t+1},t]/(t-2)],Failure["GPLVariableOrLettersNotSupported",_]]];
FTAssert["logarithm normalization is preserved",
 integrate[Log[3-t]/(t-2)]===g[{2,3},z]+Log[3] g[{2},z]];
FTAssert["a stricter weight limit is respected after an earlier successful call",
 !FailureQ[integrate[g[{2},t]/(t-3),"MaxWeight"->3]]&&
 MatchQ[integrate[g[{2},t]/(t-3),"MaxWeight"->1],Failure["GPLWeightLimit",_]]];
FTAssert["arbitrary-precision decimal parsing preserves digits",
 Abs[FeynFacetSolution`Private`gplParseReal["1.2345678901234567890123456789E-2",60]-
 12345678901234567890123456789/10^30]<10^-55];
FTAssert["GiNaC GPL convention matches Li2",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{0,2},1]]+N[PolyLog[2,1/2],60]]<10^-45];
FTAssert["complex conjugate letters agree with an elementary logarithm",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{I},1]+g[{-I},1]]-N[Log[2],60]]<10^-45];
FTAssert["a contour pole requires an explicit continuation implementation",
 MatchQ[FeynFacetSolution`EvaluateGPLExpression[g[{1/2},1]],Failure["GPLLetterOnIntegrationContour",_]]];
FTAssert["machine input cannot masquerade as high precision",
 MatchQ[FeynFacetSolution`EvaluateGPLExpression[g[{2.},1]],Failure["GPLExactInputRequired",_]]];

FTAssert["a nonleading endpoint letter is an ordinary convergent GPL",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{0,1},1]]+N[Zeta[2],60]]<10^-45];
FTAssert["trailing zeros can make a leading endpoint pole integrable",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{1,0},1]]-N[Zeta[2],60]]<10^-45];
FTAssert["an explicit letter plus-i0 prescription fixes the discontinuity",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{1/2},1],"RealLetterPrescription"->1]-N[I Pi,60]]<10^-45];
FTAssert["the opposite prescription gives the conjugate value",
 Abs[FeynFacetSolution`EvaluateGPLExpression[g[{1/2},1],"RealLetterPrescription"->-1]+N[I Pi,60]]<10^-45];
FTAssert["a divergent endpoint is not fixed by declaring a prescription",
 FailureQ[FeynFacetSolution`EvaluateGPLExpression[g[{1},1],"RealLetterPrescription"->1]]];

FTAssert["trailing zeros do not cure a nonunit endpoint with nonzero logarithm",
 FailureQ[FeynFacetSolution`EvaluateGPLExpression[g[{2,0},2]]]];
FTReport[];


