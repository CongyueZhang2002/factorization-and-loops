Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
geometry=<|"Name"->ComplementTest,"FinalMomenta"->{k1,k2,k3,k4},"TotalMomentum"->q,
 "ExternalMomenta"->{q},"KinematicRules"->{FeynCalc`SPD[q]->s},"Assumptions"->s>0|>;
records=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,<|"Arguments"->{a,b},
 "Observable"->s FeynCalc`SPD[a,b]/(2FeynCalc`SPD[q,a]FeynCalc`SPD[q,b]),
 "Weight"->1,"Variable"->z,"Tuples"-><|"Ordered"->True,"IncludeRepeated"->False|>|>];
definition=SelectFirst[records,MemberQ[#["ParticleTuples"],{1,2}]&]["Definition"];
family=FeynFacet`CreateCutIntegralDefinition[Join[definition,<|"Topology"->ReplacePart[definition["Topology"],
 2->Join[definition["Topology"][[2]],FeynCalc`FCI[FeynCalc`SFAD[q-#]&/@{k1,k2,k3,q-k1-k2-k3}]]]|>]];
If[!AssociationQ[family],Print[InputForm[family]];Exit[1]];
c0=1/(2048Pi^5);lambda=Sqrt[1-4v(1-v)/3];u=2/(1+lambda);l=2Log[1+lambda]-Log[4v(1-v)/3];
cases={{{0,0,1,0},0,2c0,u*l/lambda},{{1,1,0,0},0,2c0,(-Log[v]-Log[2/3]+Log[1-v/3])/(1-v)},
 {{0,0,1,1},-1,-c0,l/lambda},{{1,0,1,0},0,2c0,-l*Log[1-v*u]/(v*lambda)}};
Do[
 integral=FeynCalc`GLI[family["Topology"][[1]],Join[ConstantArray[1,5],case[[1]]]];
 result=FeynFacet`EvaluatePairComplementMassPeriod[family,integral,e];
 FTTest`FTAssert["typed complement period has exact finite coverage "<>ToString[case[[1]]],
  AssociationQ[result]&&result["KnownThroughOrder"]===case[[2]]&&!result["ExactTail"]];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 number=FeynFacetSolution`EvaluateGPLExpression[result["Coefficients"][case[[2]]]/case[[3]],{z->1/3,s->1},"WorkingPrecision"->40];
 reference=NIntegrate[Evaluate[case[[4]]],{v,0,1/2,1},WorkingPrecision->30,AccuracyGoal->20,PrecisionGoal->20];
 FTTest`FTAssert["absolute normalized period agrees with independent energy quadrature "<>ToString[case[[1]]],
  NumericQ[number]&&Abs[number-reference]<10^-22],{case,cases}];
FTTest`FTAssert["dotted cuts are outside this on-shell coefficient provider",
 FailureQ[FeynFacet`EvaluatePairComplementMassPeriod[family,
 FeynCalc`GLI[family["Topology"][[1]],{2,1,1,1,1,0,0,1,0}],e]]];
Print["COMPLEMENT MASS PERIODS TEST COMPLETE"];FTTest`FTReport[];
