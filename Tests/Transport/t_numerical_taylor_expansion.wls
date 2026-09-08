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

tayData=Join[data,<|"DimensionalRegulator"->eps,"OriginalConnectionMatrices"->{{{eps/(1-x)}}},
 "InitialConstantLaurentLowerBounds"->{0}|>];
tay=FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[tayData,{1},
 "InitialConstantValues"->{c[1,0]->1,c[1,1]->0,c[1,2]->0}];
query=FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[tay,1/10];
FTAssert["Taylor coefficients evaluate the analytic epsilon expansion",
 AssociationQ[tay]&&AssociationQ[query]&&
 Abs[Last[First[query["MasterIntegralEpsilonCoefficients"][2]]]-N[Log[10/9]^2/2,60]]<10^-20];
FTAssert["Taylor storage contains explicit coefficients with no deferred solver",
 MatrixQ[tay["TaylorCoefficients"],NumberQ]&&Dimensions[tay["TaylorCoefficients"]]==={3,41}&&
 FreeQ[tay["TaylorCoefficients"],_Function|_Integrate|_DSolve|_NDSolve]];
FTAssert["Taylor queries refuse points outside the tested local region",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[tay,2],
 Failure["TaylorPointOutsideValidatedRegion",_]]];
FTAssert["Taylor queries reject insufficient parameter precision",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[tay,0.1],
 Failure["TaylorParameterPrecisionInsufficient",_]]];
negative=Join[data,<|"DimensionalRegulator"->eps,
 "OriginalConnectionMatrices"->{{{0,1/eps},{0,0}}},
 "InitialConstantLaurentLowerBounds"->{0,0},"KernelDefinitions"->{},
 "IntegralDefinitions"->{},"Coefficients"-><|0->{1->{1,0}},-1->{1->{0,x}}|>,
 "MasterIntegralCoefficients"-><|0->{1->c[1,0]+x c[2,1]}|>|>];
nt=FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[negative,{1},
 "InitialConstantValues"->{c[1,0]->7,c[2,1]->3},"TaylorOrder"->8];
FTAssert["a negative epsilon power requires the higher boundary order without unrelated states",
 AssociationQ[nt]&&nt["CoefficientStates"]==={{1,0},{2,1}}&&
 Abs[Last[First[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[nt,1/3]["MasterIntegralEpsilonCoefficients"][0]]]-8]<10^-20];
FTAssert["missing higher boundary coefficients cannot be replaced by zero",
 FailureQ[FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[negative,{1},
  "InitialConstantValues"->{c[1,0]->7}]]];
cycle=Join[tayData,<|"OriginalConnectionMatrices"->{{{1/eps}}}|>];
FTAssert["unbounded raw-DE epsilon dependencies decline the Taylor route",
 MatchQ[FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[cycle,{1},
  "InitialConstantValues"->{c[1,0]->1,c[1,1]->0,c[1,2]->0}],
  Failure["TaylorEpsilonClosureUnbounded",_]]];
zeroData=Join[tayData,<|"InitialConstantLaurentLowerBounds"->{1},
 "MasterIntegralCoefficients"-><|0->{1->0}|>|>];
zt=FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[zeroData,{1},"InitialConstantValues"->{}];
FTAssert["coefficients below the propagated Laurent bound are explicitly zero",
 AssociationQ[zt]&&zt["CoefficientStates"]==={}&&
 FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[zt,0]["MasterIntegralEpsilonCoefficients"][0]==={1->0}];
grid=FeynFacetSolution`Private`gaussIntegrationData[8,60];
FTAssert["the indefinite integration matrix integrates polynomial moments",
 Max[Flatten[Abs[Table[grid["IndefiniteIntegrationMatrix"].grid["Nodes"]^j-
 grid["Nodes"]^(j+1)/(j+1),{j,0,7}]]]]<10^-50];

seed=FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[tay,1/10,"ReturnCoefficientStateValues"->True];
recentered=FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[tayData,{1},
 "InitialConstantValues"->{c[1,0]->1,c[1,1]->0,c[1,2]->0},"CenterData"->seed];
FTAssert["a local expansion can be recentered using all required coefficients with capped accuracy",
 AssociationQ[recentered]&&recentered["Center"]==={1/10}&&
 Abs[Last[First[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[recentered,1/100]["MasterIntegralEpsilonCoefficients"][1]]]-N[-Log[89/100],60]]<10^-20];
FTAssert["recentring cannot mix a different boundary vector",
 MatchQ[FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[tayData,{1},
  "InitialConstantValues"->{c[1,0]->2,c[1,1]->0,c[1,2]->0},"CenterData"->seed],
 Failure["TaylorCenterDataMismatch",_]]];
FTReport[];
