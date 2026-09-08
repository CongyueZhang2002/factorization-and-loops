#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{$Output={}},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/FeynFacet/Solution.m"];
param=RationalizingParametrizationCatalog[]["Kallen13"];
{v,w}=param["SourceVariables"];ep=Global`eps;
r1=(1-v-w)^2-4 v w;r3=(1-v+w)^2+4 v w;
primitive=Log[1-v-w+Sqrt[r1]]+Log[1-v+w+Sqrt[r3]]+Log[1+v];
sys=<|"KinematicVariables"->{v,w},"DimensionalRegulator"->ep,
 "ConnectionMatrices"->Table[{{ep D[primitive,z]}},{z,{v,w}}]|>;
lift={1/4,4};sourceBase={v,w}/.param["SourceVariableSubstitution"]/.Thread[param["ParametrizingVariables"]->lift];
pulled=PullBackMasterIntegralDifferentialSystem[Join[sys,<|"BasePoint"->sourceBase|>],param,lift];
FTAssert["complete pullback binds source and parametrizing base points",
 AssociationQ[pulled]&&pulled["BasePoint"]===lift&&
 pulled["RationalizingCoordinates"]["SourceBasePoint"]===sourceBase];
FTAssert["both square-root branches are fixed and verified",
 Length[pulled["RationalizingCoordinates"]["RootBranches"]]===2&&
 AllTrue[pulled["RationalizingCoordinates"]["RootBranches"],#["RootIdentityVerified"]&]];
FTAssert["a different physical constant-normalization point is refused",
 MatchQ[PullBackMasterIntegralDifferentialSystem[Join[sys,<|"BasePoint"->{1/3,1/7}|>],param,lift],
 Failure["RationalizingBasePointDoesNotMatchSourceNormalization",_]]];
FTAssert["a declared source sheet cannot be silently reset to principal roots",
 MatchQ[PullBackMasterIntegralDifferentialSystem[Join[sys,<|"BranchPrescription"->"Nonprincipal sheet"|>],param,lift],
 Failure["ExplicitSourceRootValuesRequiredForDeclaredSheet",_]]];
roots=<|Expand[r1]->Sqrt[r1/.Thread[{v,w}->sourceBase]],Expand[r3]->-Sqrt[r3/.Thread[{v,w}->sourceBase]]|>;
other=PullBackMasterIntegralDifferentialSystem[Join[sys,<|"BranchPrescription"->"Second root negative"|>],
 param,lift,"RootValuesAtBasePoint"->roots];
FTAssert["explicit nonprincipal roots and equivalent expanded radicands are supported",
 AssociationQ[other]&&MemberQ[Lookup[other["RationalizingCoordinates"]["RootBranches"],"SourceBasePointRoot"],
 -Sqrt[r3/.Thread[{v,w}->sourceBase]]]];
req=<|"BasePoint"->lift,"RequestedEpsilonOrders"->{0,1,2},
 "AnalyticDomain"->"A nonsingular neighborhood of the lifted base point.",
 "BranchPrescription"->"Continuous values from principal source roots at the base point."|>;
sol=ConstructMasterIntegralSolution[pulled,req];
FTAssert["the general constructor retains source-coordinate metadata",MasterIntegralSolutionQ[sol]&&
 sol["RationalizingCoordinates"]===pulled["RationalizingCoordinates"]];
FTAssert["a conflicting constructor base point cannot change already bound constants",
 MatchQ[ConstructMasterIntegralSolution[pulled,Join[req,<|"BasePoint"->{1/5,4}|>]],
 Failure["RequestedBasePointDoesNotMatchSourceNormalization",_]]];
converted=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[sol,"TimeLimit"->30];
FTAssert["two-root rationalized coefficients convert through the general GPL code",
 converted["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL"];
point={251/1000,401/100};sourcePoint=Together/@({v,w}/.param["SourceVariableSubstitution"]/.
 Thread[param["ParametrizingVariables"]->point]);
delta=(primitive/.Thread[{v,w}->sourcePoint])-(primitive/.Thread[{v,w}->sourceBase]);
num=FeynFacetSolution`EvaluateMasterIntegralSolution[converted,point,"NumericalBackend"->"GiNaC",
 "AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["GPL values agree with an independent exact exponential solution",
 AssociationQ[num]&&Max[Abs[Flatten[Values[num["EpsilonCoefficients"]]]-N[{1,delta,delta^2/2},70]]]<10^-25];
expanded=ExpandMasterIntegralSolutionInInitialConstants[converted,{0},{0,1,2}];
directory=CreateDirectory[];
boundary=<|"KinematicVariables"->{v,w},"Point"->sourceBase,
 "OriginalMasterIntegralBasis"->sol["OriginalMasterIntegralBasis"],"PrecisionGoal"->60,
 "InitialConstantValues"->{FeynFacetSolution`C[1,0]->1,FeynFacetSolution`C[1,1]->0,FeynFacetSolution`C[1,2]->0}|>;
reference=<|"KinematicVariables"->{v,w},"Point"->sourcePoint,
 "OriginalMasterIntegralBasis"->sol["OriginalMasterIntegralBasis"],"PrecisionGoal"->60,
 "MasterIntegralEpsilonCoefficients"-><|0->{1->1},1->{1->N[delta,65]},2->{1->N[delta^2/2,65]}|>|>;
Export[directory<>"/boundary.wxf",boundary,"WXF"];Export[directory<>"/reference.wxf",reference,"WXF"];
compared=FeynFacetSolution`EvaluateMasterIntegralSolutionRequest[expanded,<|"Point"->point,
 "BoundaryDataFile"->directory<>"/boundary.wxf","ReferenceDataFile"->directory<>"/reference.wxf",
 "EvaluationOptions"->{"NumericalBackend"->"GiNaC","AccuracyGoal"->25,"PrecisionGoal"->25}|>];
FTAssert["physical source-coordinate boundary/reference data map to the solution chart",
 AssociationQ[compared]&&compared["ReferenceComparisonStatus"]==="ReferenceComparisonPassed"];
DeleteDirectory[directory,DeleteContents->True];
Clear[loop,chartTadpole];
top=FeynCalc`FCTopology[chartTadpole,{FeynCalc`SFAD[{loop,v}]},{loop},{},{},{}];
tadpole=<|"Topology"->top,"OriginalMasterIntegralBasis"->{FeynCalc`GLI[chartTadpole,{2}]},
 "KinematicVariables"->{v,w},"DimensionalRegulator"->ep,
 "ConnectionMatrices"->{{{-ep/v}},{{0}}}|>;
pulledTadpole=PullBackMasterIntegralDifferentialSystem[tadpole,param,lift];
FTAssert["physical integral definitions use the new coordinates before automatic normalization",
 AssociationQ[pulledTadpole]&&FreeQ[pulledTadpole["Topology"],v|w]&&
 pulledTadpole["DataType"]==="FamilyDifferentialSystem"];
orderSolution=ConstructMasterIntegralSolution[pulledTadpole,
 <|"BasePoint"->lift,"RequestedMasterIntegralOrderRanges"-><|1->{-1,0}|>|>];
FTAssert["automatic Laurent bounds and master-order construction preserve the coordinate map",
 AssociationQ[orderSolution]&&orderSolution["InitialConstantLaurentLowerBounds"]==={-1}&&
 orderSolution["RationalizingCoordinates"]===pulledTadpole["RationalizingCoordinates"]&&
 orderSolution["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined"];
FTReport[];
