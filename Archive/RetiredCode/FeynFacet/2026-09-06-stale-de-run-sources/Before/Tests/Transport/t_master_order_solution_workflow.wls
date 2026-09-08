#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Clear[xx,ee,kl,workflowFamily];
top=FeynCalc`FCTopology[workflowFamily,{FeynCalc`SFAD[{kl,xx}]},{kl},{},{},{}];
system=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,"Topology"->top,
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[workflowFamily,{2}],FeynCalc`GLI[workflowFamily,{3}]},
 "ConnectionMatrices"->{{{-ee/xx,0},{0,-(1+ee)/xx}}}|>;
request=<|"BasePoint"->{1/2},"RequestedMasterIntegralOrderRanges"-><|1->{-1,0},2->{0,0}|>|>;
directory=CreateDirectory[];
sol=ConstructMasterIntegralSolution[system,request,"OutputDirectory"->directory];
If[FailureQ[sol],Print[sol];Exit[1]];
FTAssert["master ranges construct explicit finite solutions and derived orders in one call",
 MasterIntegralSolutionQ[sol] &&
 sol["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined"];
FTAssert["individual requested ranges determine which master coefficients are stored",
 First /@ sol["MasterIntegralCoefficients"][-1]==={1} &&
 First /@ sol["MasterIntegralCoefficients"][0]==={1,2}];
FTAssert["unused fundamental-matrix coefficients are not represented as zeros",
 (2/.sol["Coefficients"][1])[[2]]===Missing["NotComputed"] &&
 FailureQ[MasterIntegralSolutionCoefficient[sol,2,1]]];
verified=VerifyMasterIntegralSolution[sol,"RecheckFlatness"->False,"IdentityCheck"->"Exact"];
FTAssert["the verifier checks computed U entries and the final constant convolution",
 AssociationQ[verified] && verified["InitialConstantConvolutionIdentities"]===True];
modified=sol["MasterIntegralCoefficients"];
modified[0]=ReplacePart[modified[0],{1,2}->(modified[0][[1,2]]+FeynFacetSolution`C[1,0])];
changed=Join[sol,<|"MasterIntegralCoefficients"->modified|>];
FTAssert["a changed master coefficient fails the independent convolution check",
 FailureQ[VerifyMasterIntegralSolution[changed,"RecheckFlatness"->False,"IdentityCheck"->"Exact"]]];
modified=sol["Coefficients"];modified[1]=ReplacePart[modified[1],{2,2,2}->0];
changed=Join[sol,<|"Coefficients"->modified|>];
FTAssert["an uncomputed entry cannot be relabelled as an exact zero",!MasterIntegralSolutionQ[changed]];
FTAssert["structurally zero coefficients remain explicit zeros",
 (1/.sol["Coefficients"][1])[[2]]===0];
FTAssert["no unknown kinematic boundary functions occur",
 sol["InitialConstants"]["KinematicsIndependent"]===True &&
 sol["RequiredInitialConstantCoefficients"]==={{1,-1},{1,0},{2,0}}];
Get[FileNameJoin[{root,"FeynFacet","FiniteSolutionData.wl"}]];
data=FeynFacetSolution`ReadMasterIntegralSolution[directory];
FTAssert["the standalone reader loads master coefficients and their order derivation",
 data["MasterIntegralCoefficients"]===sol["MasterIntegralCoefficients"] &&
 data["ExpansionOrderDetermination"]["BasePoint"]==={1/2}];
binaryDirectory=CreateDirectory[];
WriteMasterIntegralSolution[sol,binaryDirectory,"FileFormat"->"WXF"];
binary=FeynFacetSolution`ReadMasterIntegralSolution[binaryDirectory];
FTAssert["the compressed format contains the complete finite expression",
 binary===sol && FileByteCount[FileNameJoin[{binaryDirectory,"solution.wxf"}]]>0];
numeric=FeynFacetSolution`EvaluateMasterIntegralSolution[data,{3/5},"QuadratureOrder"->12,"WorkingPrecision"->40];
expected={1->FeynFacetSolution`C[1,0]-Log[6/5]FeynFacetSolution`C[1,-1],
 2->(5/6)FeynFacetSolution`C[2,0]};
residual=Values[Association[numeric["MasterIntegralEpsilonCoefficients"][0]]]-Values[Association[expected]];
FTAssert["evaluating the stored integrals reproduces the analytic master coefficients",
 Max[Abs[N[residual/.FeynFacetSolution`C[_,_]->1,30]]]<10^-20];
onlyFirst=ConstructMasterIntegralSolution[system,
 <|"BasePoint"->{1/2},"RequestedMasterIntegralOrderRanges"-><|1->{0,0}|>|>];
FTAssert["an uncoupled unrequested master needs no invented boundary bound",
 MasterIntegralSolutionQ[onlyFirst] &&
 onlyFirst["InitialConstantLaurentLowerBounds"][[2]]===Missing["NotRequired"]];
FTAssert["unresolved integral data cannot produce a completed master solution",
 FailureQ[ConstructMasterIntegralSolution[KeyDrop[system,"Topology"],request]]];
FTAssert["singular normalization is not silently relabelled as ordinary initial values",
 FailureQ[ConstructMasterIntegralSolution[system,Join[request,<|
 "BoundaryNormalization"-><|"Type"->"Frobenius","NormalVariable"->xx,"SingularPoint"->0|>|>]]]];

form=Get[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical",
 "DifferentialEquationDataV2","CF269","FamilyDLogEpsilonForm.wl"}]];
recurrence=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","EpsilonOrderDetermination",
 "CF269","DimensionalRecurrence.wxf"}],"WXF"];
actualRequest=<|"BasePoint"->{1/4,1/3},"DimensionalRecurrence"->recurrence,
 "RequestedMasterIntegralOrderRanges"->AssociationThread[Range[23],ConstantArray[{-3,0},23]]|>;
actual=ConstructMasterIntegralSolution[form,actualRequest];
If[FailureQ[actual],Print[actual];Exit[2]];
FTAssert["the complete real family uses the same point for bounds and finite integration",
 actual["BasePoint"]==={1/4,1/3} &&
 actual["ExpansionOrderDetermination"]["BasePoint"]===actual["BasePoint"]];
FTAssert["all 92 requested master coefficients are explicitly stored",
 Length[Flatten[Values[actual["MasterIntegralCoefficients"]],1]]===92 &&
 FreeQ[actual["MasterIntegralCoefficients"],_Missing]];
FTAssert["entrywise demands retain the prepared evolution order four",
 actual["TransformedSystemEpsilonOrderRange"]==={0,4} &&
 actual["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined"];
chartForm=Get[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical",
 "DifferentialEquationDataV2","CF48","FamilyDLogEpsilonForm.wl"}]];
chartReps=ConstructMasterIntegralRepresentations[chartForm,<|"BasePoint"->{1/4,1/3},"RequestedRows"->{1}|>];
chartRep=chartReps["MasterIntegralRepresentations"][1];
FTAssert["rationalizing coordinates are substituted into the physical integral definition",
 FreeQ[chartRep["KinematicRules"],Alternatives@@chartForm["CoefficientVariables"]] &&
 chartRep["TimeDirectionSquared"]===1/3];
defs=FeynFacet`Private`epsOrderPointIntegralDefinitions[chartForm,<||>,chartForm["DimensionalRegulator"]];
FTAssert["physical cut conditions distinguish admissible ordinary-point candidates",
 !FeynFacet`Private`epsOrderPhysicalPointQ[defs,chartForm["CoefficientVariables"],{1/4,1/6}] &&
 FeynFacet`Private`epsOrderPhysicalPointQ[defs,chartForm["CoefficientVariables"],{1/6,1/4}]];
FTAssert["an existing recurrence supplies its point when the caller leaves it automatic",
 FeynFacet`Private`epsOrderRequestedBasePoint[form,<|"DimensionalRecurrence"->recurrence|>,<||>]==={1/4,1/3}];
Clear[ll,pp,mixedFamily];
mixedTop=FeynCalc`FCTopology[mixedFamily,
 {FeynCalc`SFAD[{kl,xx}],FeynCalc`SFAD[ll],FeynCalc`SFAD[pp-ll]},
 {kl,ll},{pp},{FeynCalc`SPD[pp]->1},{}];
mixed=<|"Topology"->mixedTop,"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[mixedFamily,{2,1,1}]},
 "ConnectionMatrices"->{{{-ee/xx}}},"Prescription"->{1,0},
 "CutIndices"->{2,3},"CutMomenta"->{ll,pp-ll}|>;
mixedDefinitions=ConstructMasterIntegralRepresentations[mixed,<|"BasePoint"->{1/2}|>];
mixedRep=mixedDefinitions["MasterIntegralRepresentations"][1];
FTAssert["independent real and virtual integrations are factored automatically",
 mixedRep["Representation"]==="ProductOfIntegrals" && Length[mixedRep["Factors"]]===2];
FTAssert["a factor is an integral definition rather than an invented master identifier",
 AllTrue[mixedRep["Factors"],!KeyExistsQ[#,"MasterIntegral"]&]];
FTAssert["factorized real-virtual masters have derived epsilon orders",
 DetermineIntegralLaurentBound[mixedRep]["LowerBound"]===-1];
mixedSolution=ConstructMasterIntegralSolution[mixed,<|"BasePoint"->{1/2},
 "RequestedMasterIntegralOrderRanges"-><|1->{-1,0}|>|>];
FTAssert["factorized real-virtual definitions reach the same finite export interface",
 MasterIntegralSolutionQ[mixedSolution] &&
 mixedSolution["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined"];

coupledTop=ReplacePart[mixedTop,2->Append[mixedTop[[2]],FeynCalc`SFAD[kl-ll]]];
coupled=Join[mixed,<|"Topology"->coupledTop,
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[mixedFamily,{2,1,1,-1}]}|>];
coupledDefinitions=ConstructMasterIntegralRepresentations[coupled,<|"BasePoint"->{1/2}|>];
coupledRep=coupledDefinitions["MasterIntegralRepresentations"][1];
FTAssert["a numerator that couples the integrations prevents false factorization",
 coupledRep["Representation"]==="MomentumSpace" &&
 coupledRep["ParameterRepresentationStatus"]==="CoupledLoopAndPhaseSpaceParametrizationRequired" &&
 FailureQ[DetermineIntegralLaurentBound[coupledRep]]];
inactive=Join[mixed,<|"OriginalMasterIntegralBasis"->{FeynCalc`GLI[mixedFamily,{0,1,1}]}|>];
inactiveDefinitions=ConstructMasterIntegralRepresentations[inactive,<|"BasePoint"->{1/2}|>];
FTAssert["an unused loop does not produce an incomplete product representation",
 inactiveDefinitions["MasterIntegralRepresentations"][1]["Representation"]==="MomentumSpace"];
changed=Join[sol,<|"BasePoint"->{1/3}|>];
FTAssert["the stored order derivation and finite solution must share a base point",
 !MasterIntegralSolutionQ[changed]];
FTReport[];
