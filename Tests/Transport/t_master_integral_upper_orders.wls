#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[x,u,e];
system=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,
 "ConnectionMatrices"->{{{e/x}}},"OriginalMasterIntegralBasis"->{master}|>;
rep=<|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{u},
 "EndpointPowers"->{-1-e}|>}|>;
request=<|"BasePoint"->{1/4},"RequestedMasterIntegralUpperOrders"-><|1->2|>,
 "MasterIntegralRepresentations"-><|1->rep|>|>;
plan=DetermineMasterIntegralExpansionOrders[system,request];
FTAssert["upper order derives the complete interval from its integral bound",
 plan["Status"]==="SufficientOrdersDetermined" &&
 plan["RequestedMasterIntegralOrderRanges"]===<|1->{-1,2}|> &&
 plan["OrdinaryPointConstantLowerBounds"]==={-1} &&
 plan["OrdinaryPointConstantUpperOrders"]==={2}];
ranged=Join[KeyDrop[request,"RequestedMasterIntegralUpperOrders"],
 <|"RequestedMasterIntegralOrderRanges"-><|1->{-1,2}|>|>];
same=DetermineMasterIntegralExpansionOrders[system,ranged];
FTAssert["upper-only and explicit-range requests determine identical mathematics",plan===same];
sol=ConstructMasterIntegralSolution[system,request];
FTAssert["upper-only requests construct every explicit master coefficient",
 AssociationQ[sol] && MasterIntegralSolutionQ[sol] &&
 Keys[sol["MasterIntegralCoefficients"]]===Range[-1,2] &&
 sol["RequestedMasterOrderCoverage"]["EveryRequestedCoefficientConstructed"]===True];
FTAssert["ambiguous upper and range requests are rejected",
 FailureQ[DetermineMasterIntegralExpansionOrders[system,Join[request,
 <|"RequestedMasterIntegralOrderRanges"-><|1->{0,2}|>|>]]]];
FTAssert["nonintegral or absent upper cutoffs are rejected",
 And@@(FailureQ[DetermineMasterIntegralExpansionOrders[system,Join[request,
   <|"RequestedMasterIntegralUpperOrders"->#|>]]]& /@ {<||>,<|1->Infinity|>,<|2->0|>,<|1->1/2|>})];
missing=DetermineMasterIntegralExpansionOrders[system,KeyDrop[request,"MasterIntegralRepresentations"]];
FTAssert["an unresolved lower bound does not produce an invented range",
 missing["Status"]==="AdditionalIntegralDataRequired" &&
 MissingQ[missing["RequestedMasterIntegralOrderRanges"][1][[1]]]];
assumed=DetermineMasterIntegralExpansionOrders[system,Join[
 KeyDrop[request,"MasterIntegralRepresentations"],<|"MasterIntegralLaurentLowerBounds"-><|1->-3|>|>]];
FTAssert["supplied lower bounds remain conditional for upper-only requests",
 assumed["Status"]==="SufficientForAssumedLaurentBounds" &&
 assumed["RequestedMasterIntegralOrderRanges"]===<|1->{-3,2}|>];
zero=Join[rep,<|"Terms"->{Join[First[rep["Terms"]],<|"Prefactor"->0|>]}|>];
zeroPlan=DetermineMasterIntegralExpansionOrders[system,Join[request,
 <|"MasterIntegralRepresentations"-><|1->zero|>|>]];
FTAssert["identically zero input produces a finite zero coefficient request",
 zeroPlan["Status"]==="SufficientOrdersDetermined" &&
 zeroPlan["RequestedMasterIntegralOrderRanges"]===<|1->{2,2}|>];
(* I1=1+(x-X0)/e, I2=1 satisfies this DE. Its pole is invisible at X0. *)
poleSystem=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,
 "ConnectionMatrices"->{{{0,1/e},{0,0}}},"OriginalMasterIntegralBasis"->{firstMaster,secondMaster}|>;
regular=<|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{u},
 "EndpointPowers"->{0}|>}|>;
cancelling=<|"Representation"->"UnitCube","Terms"->{
 First[regular["Terms"]],<|"IntegrationVariables"->{u},"EndpointPowers"->{-1-e},
 "Prefactor"->-(x-1/4)|>}|>;
poleRequest=<|"BasePoint"->{1/4},"RequestedMasterIntegralUpperOrders"-><|1->0|>,
 "MasterIntegralRepresentations"-><|1->cancelling,2->regular|>|>;
polePlan=DetermineMasterIntegralExpansionOrders[poleSystem,poleRequest];
FTAssert["a boundary-point zero cannot remove a pole away from the boundary point",
 polePlan["OrdinaryPointConstantLowerBounds"]==={0,0} &&
 polePlan["RequestedMasterIntegralOrderRanges"]===<|1->{-1,0}|>];
poleSolution=ConstructMasterIntegralSolution[poleSystem,poleRequest];
FTAssert["the coefficient-table request retains the transport-induced pole coefficient",
 AssociationQ[poleSolution] && MasterIntegralSolutionQ[poleSolution] &&
 Keys[poleSolution["MasterIntegralCoefficients"]]==={-1,0} &&
 !FreeQ[poleSolution["MasterIntegralCoefficients"][-1],FeynFacetSolution`C[2,0]]];
heterogeneousSystem=Join[poleSystem,<|"ConnectionMatrices"->{{{0,1},{0,0}}}|>];
heterogeneousRequest=Join[poleRequest,<|"MasterIntegralRepresentations"-><|
 1->cancelling,2->rep|>|>];
heterogeneousPlan=DetermineMasterIntegralExpansionOrders[heterogeneousSystem,heterogeneousRequest];
FTAssert["epsilon-regular mixing still propagates another component's pole",
 heterogeneousPlan["OrdinaryPointConstantLowerBounds"]==={0,-1} &&
 heterogeneousPlan["RequestedMasterIntegralOrderRanges"]===<|1->{-1,0}|>];
belowRequest=Join[request,<|"RequestedMasterIntegralUpperOrders"-><|1->-2|>|>];
below=ConstructMasterIntegralSolution[system,belowRequest];
FTAssert["a target below the proven lower bound stays zero without adding boundary constants",
 AssociationQ[below] && MasterIntegralSolutionQ[below] &&
 below["MasterIntegralCoefficients"][-2]==={1->0} &&
 below["RequiredInitialConstantCoefficients"]==={}];
FTReport[];
