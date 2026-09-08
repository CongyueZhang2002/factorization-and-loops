#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
Clear[x,t];
c=FeynFacetSolution`C;f=FeynFacetSolution`F;k=FeynFacetSolution`K;
data=<|"KinematicVariables"->{x},"BasePoint"->{0},"RequestedRows"->{1},
 "KernelDefinitions"->{<|"Index"->1,"Parameter"->t,"Expression"->x/(1-x t)|>},
 "IntegralDefinitions"->{
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]|>,
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t] f[1,t]|>},
 "AlgebraicDefinitions"->{},
 "Coefficients"-><|0->{1->{1}},1->{1->{f[1,1]}},2->{1->{f[2,1]}}|>,
 "MasterIntegralCoefficients"-><|0->{1->c[1,0]},1->{1->f[1,1] c[1,0]+c[1,1]},
  2->{1->f[2,1] c[1,0]+f[1,1] c[1,1]+c[1,2]}|>|>;
ev[dd_,pt_,opts___] := FeynFacetSolution`EvaluateMasterIntegralSolution[dd,pt,opts];
r=ev[data,{4/5},"AccuracyGoal"->30,"PrecisionGoal"->30,"WorkingPrecision"->70];
FTAssert["iterated logarithms converge away from the base point",
 AssociationQ[r]&&r["Status"]==="NumericalConvergenceObserved"&&
 Abs[r["EpsilonCoefficients"][2][[1,1]]-N[Log[5]^2/2,70]]<10^-30];
FTAssert["all three numerical refinements are recorded",
 AssociationQ[r]&&And@@(KeyExistsQ[Last[r["ConvergenceHistory"]],#]& /@
 {"OrderDifferenceRatio","SubdivisionDifferenceRatio","PrecisionDifferenceRatio"})&&
 !TrueQ[r["ErrorEstimateIsRigorousBound"]]];
seg=ev[data,{4/5},"IntegrationBreakpoints"->{0,1/3,2/3,1},
 "AccuracyGoal"->25,"PrecisionGoal"->25,"WorkingPrecision"->65];
FTAssert["panel propagation includes the earlier integrals' accumulated values",
 AssociationQ[seg]&&Abs[seg["EpsilonCoefficients"][2][[1,1]]-N[Log[5]^2/2,65]]<10^-25];
FTAssert["numerical evaluation preserves integer boundary labels",
 N[c[1,-2],50]===c[1,-2]];
physical=ev[data,{1/2},"InitialConstantValues"->{c[1,0]->2,c[1,1]->3,c[1,2]->5}];
FTAssert["boundary substitution produces the requested numerical Laurent coefficient",
 AssociationQ[physical]&&NumericQ[Last[First[physical["MasterIntegralEpsilonCoefficients"][2]]]]&&
 Abs[Last[First[physical["MasterIntegralEpsilonCoefficients"][2]]]-
 N[Log[2]^2+3 Log[2]+5,50]]<10^-20];
FTAssert["missing boundary orders fail instead of becoming zero",
 MatchQ[ev[data,{1/2},"InitialConstantValues"->{c[1,0]->1}],
 Failure["InitialConstantValuesIncomplete",_]]];
FTAssert["insufficient boundary precision is rejected",
 MatchQ[ev[data,{1/2},"InitialConstantValues"->{c[1,0]->N[1,22],c[1,1]->0,c[1,2]->0}],
 Failure["NumericalInputPrecisionInsufficient",_]]];
FTAssert["machine precision kinematics cannot request twenty digits",
 MatchQ[ev[data,{0.5}],Failure["NumericalInputPrecisionInsufficient",_]]];
FTAssert["a pole between quadrature nodes is rejected",
 MatchQ[ev[data,{2}],Failure["IntegrationPathMeetsSingularity",_]]];
FTAssert["unachieved convergence is a failure",
 MatchQ[ev[data,{99/100},"QuadratureOrder"->2,"MaxQuadratureOrder"->3,
 "MaxRefinements"->1],Failure["NumericalConvergenceNotReached",_]]];
unchecked=ev[data,{1/2},"CheckConvergence"->False];
FTAssert["a requested fixed-order evaluation does not claim convergence",
 AssociationQ[unchecked]&&unchecked["Status"]==="EvaluatedWithoutConvergenceCheck"];
missing=Join[data,<|"Coefficients"-><|0->{1->{1,Missing["NotComputed"]}}|>|>];
m=ev[missing,{1/2}];
FTAssert["uncomputed evolution entries remain explicitly uncomputed",
 AssociationQ[m]&&m["EpsilonCoefficients"][0][[1,2]]===Missing["NotComputed"]];
bad=Join[data,<|"IntegralDefinitions"->{<|"IntegrationVariable"->t,"Integrand"->f[1,t]|>}|>];
FTAssert["a cyclic stored definition is rejected",FailureQ[ev[bad,{1/2}]]];
FTAssert["the entire evaluation has a time limit",
 MatchQ[ev[data,{1/2},"TimeLimit"->0.001],Failure["NumericalEvaluationTimeLimit",_]]];
tiny=ev[data,{1/2},"InitialConstantValues"->{c[1,0]->N[0,50],c[1,1]->0,c[1,2]->0}];
FTAssert["an approximate zero is judged by absolute accuracy",
 AssociationQ[tiny]&&tiny["Status"]==="NumericalConvergenceObserved"];
direct=Join[data,<|"KernelDefinitions"->{},"IntegralDefinitions"->{
 <|"IntegrationVariable"->t,"Integrand"->1/(t-1/2)|>}|>];
FTAssert["poles written directly in an integrand are also rejected",
 MatchQ[ev[direct,{1/2}],Failure["IntegrationPathMeetsSingularity",_]]];
cancel=Join[data,<|"Coefficients"-><|0->{1->{1+10^35 (f[1,1]+Log[1-x])}}|>,
 "MasterIntegralCoefficients"-><|0->{1->(1+10^35 (f[1,1]+Log[1-x])) c[1,0]}|>|>];
cr=ev[cancel,{1/2},"AccuracyGoal"->15,"PrecisionGoal"->15,"WorkingPrecision"->50,
 "MaxRefinements"->10];
FTAssert["cancellation causes precision refinement instead of false accuracy",
 AssociationQ[cr]&&cr["WorkingPrecision"]>50&&Abs[cr["EpsilonCoefficients"][0][[1,1]]-1]<10^-15];
FTAssert["boundary substitution preserves integer master row identifiers",
 AssociationQ[physical]&&Keys[Association[physical["MasterIntegralEpsilonCoefficients"][2]]]==={1}];
FTReport[];

