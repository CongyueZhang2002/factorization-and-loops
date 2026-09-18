#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
Clear[cpT,cpZ];
Do[
 cpBody=Cancel[D[cpR,cpT]/cpR]PolyLog[2,cpR];
 cpAnswer=FeynFacetSolution`IntegrateGPL[cpBody,{cpT,0,cpZ}];
 cpExpected=PolyLog[3,cpR/.cpT->1/5]-PolyLog[3,cpR/.cpT->0];
 cpValue=If[FailureQ[cpAnswer],cpAnswer,
  FeynFacetSolution`EvaluateGPLExpression[cpAnswer,{cpZ->1/5},"WorkingPrecision"->45]];
 FTTest`FTAssert["classical rational pullback retains basepoint "<>ToString[cpR,InputForm],
  NumericQ[cpValue]&&Abs[cpValue-N[cpExpected,45]]<10^-32],
 {cpR,{cpT/(1+cpT),(1+cpT)/2,1-cpT}}];
cpAnswer=FeynFacetSolution`IntegrateGPL[PolyLog[3,1-cpT]/(1+cpT),{cpT,0,cpZ}];
cpValue=If[FailureQ[cpAnswer],cpAnswer,
 FeynFacetSolution`EvaluateGPLExpression[cpAnswer,{cpZ->1/5},"WorkingPrecision"->45]];
cpExpected=NIntegrate[PolyLog[3,1-cpT]/(1+cpT),{cpT,0,1/5},
 WorkingPrecision->45,AccuracyGoal->35,PrecisionGoal->35];
FTTest`FTAssert["logarithmic polylog derivative at an integrable endpoint",
 NumericQ[cpValue]&&Abs[cpValue-cpExpected]<10^-30];
FTTest`FTAssert["an undeclared infinite polylog branch remains rejected",
 MatchQ[FeynFacetSolution`IntegrateGPL[PolyLog[2,1/cpT],{cpT,0,cpZ}],
  Failure["FiniteClassicalPolylogarithmBasePointRequired",_]]];
FTTest`FTAssert["proved logarithm identities cancel before the endpoint convergence check",
 FeynFacetSolution`IntegrateGPL[(Log[cpT/cpA]-Log[cpT]+Log[cpA])/cpT,
  {cpT,0,cpZ},"Assumptions"->cpA>0]===0];
FTTest`FTAssert["the same undeclared branch identity does not discard a divergence",
 FailureQ[FeynFacetSolution`IntegrateGPL[(Log[cpT/cpA]-Log[cpT]+Log[cpA])/cpT,
  {cpT,0,cpZ}]]];
(* Local Laurent division must keep finite rational-pole/GPL products and
   allow cancellation between complete endpoint coefficients. *)
cpPrimitive=(Log[1-cpT]+cpT+cpT^2/2)/cpT^3;
cpAnswer=FeynFacetSolution`IntegrateGPL[D[cpPrimitive,cpT],{cpT,0,cpZ}];
cpValue=If[FailureQ[cpAnswer],cpAnswer,
 FeynFacetSolution`EvaluateGPLExpression[cpAnswer,{cpZ->1/5},"WorkingPrecision"->45]];
FTTest`FTAssert["third-order rational pole retains its finite GPL endpoint value",
 NumericQ[cpValue]&&Abs[cpValue-N[(cpPrimitive/.cpT->1/5)+1/3,45]]<10^-30];
cpPrimitive=(Log[1-cpT]+Log[1+cpT])/cpT^2;
cpAnswer=FeynFacetSolution`IntegrateGPL[D[cpPrimitive,cpT],{cpT,0,cpZ}];
cpValue=If[FailureQ[cpAnswer],cpAnswer,
 FeynFacetSolution`EvaluateGPLExpression[cpAnswer,{cpZ->1/5},"WorkingPrecision"->45]];
FTTest`FTAssert["endpoint cancellations between distinct GPL words retain the finite constant",
 NumericQ[cpValue]&&Abs[cpValue-N[(cpPrimitive/.cpT->1/5)+1,45]]<10^-30];
cpPrimitive=(Log[1-cpT]+cpT)Log[cpT]/cpT;
cpAnswer=FeynFacetSolution`IntegrateGPL[D[cpPrimitive,cpT],{cpT,0,cpZ}];
cpValue=If[FailureQ[cpAnswer],cpAnswer,
 FeynFacetSolution`EvaluateGPLExpression[cpAnswer,{cpZ->1/5},"WorkingPrecision"->45]];
FTTest`FTAssert["vanishing rational-pole logarithmic products have zero endpoint value",
 NumericQ[cpValue]&&Abs[cpValue-N[cpPrimitive/.cpT->1/5,45]]<10^-30];
cpPhi=(1-cpB)/(1-cpA+cpA(1-cpB));
cpBody=(PolyLog[2,cpPhi/(1+cpT)]-PolyLog[2,cpPhi])/cpT;
cpAnswer=FeynFacetSolution`IntegrateGPL[cpBody,{cpT,0,cpZ},
 "Assumptions"->0<cpA<1&&0<cpB<1];
cpPoint={cpA->1/3,cpB->2/5,cpZ->1/5};
cpValue=If[FailureQ[cpAnswer],cpAnswer,
 FeynFacetSolution`EvaluateGPLExpression[cpAnswer,cpPoint,"WorkingPrecision"->45]];
cpExpected=NIntegrate[Evaluate[cpBody/.cpPoint],{cpT,0,1/5},
 WorkingPrecision->45,AccuracyGoal->35,PrecisionGoal->35];
FTTest`FTAssert["preexisting and pulled-back polylog basepoints share canonical rational arguments",
 NumericQ[cpValue]&&Abs[cpValue-cpExpected]<10^-30];
FTTest`FTReport[];
