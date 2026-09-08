#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Clear[x,y,ep];
c1=FeynFacetSolution`C[1,0];c2=FeynFacetSolution`C[2,-1];
linearQ[z_]:=MemberQ[{{1,1},{Infinity,-Infinity}},
 FeynFacet`Private`solutionConstantDegreeRange[z]];
FTAssert["zero and explicit linear constant combinations are homogeneous",
 And@@(linearQ /@ {0,c1,c1+c2,Sin[x]c1/(1+y),c1-c1})];
FTAssert["constant offsets nonlinear and inverse constant dependence are rejected",
 !Or@@(linearQ /@ {1+c1,c1 c2,c1^2,Exp[c1],1/c1,Log[c1],c1^ep})];

zero=(x^2-1)/(x-1)-x-1;
FTAssert["Laurent valuations retain algebraic cancellations",
 DetermineLaurentValuation[zero+ep^2,ep]===2 &&
 DetermineLaurentValuation[ep^2/(zero+ep),ep]===1 &&
 DetermineLaurentValuation[zero/ep,ep]===Infinity];
FTAssert["epsilon-independent meromorphic coefficients retain their exact orders",
 DetermineLaurentValuation[Exp[x]ep^3/(1+ep Log[y]),ep]===3 &&
 DetermineLaurentValuation[Gamma[-1+ep],ep]===-1];
FTAssert["essential epsilon singularities remain rejected",
 FailureQ[DetermineLaurentValuation[Exp[1/ep],ep]]];
pointQ[z_]:=FeynFacet`Private`epsOrderOrdinaryPointQ[{z},{x},{1/2},ep];
FTAssert["ordinary-point checks reject moving poles and singular scalar coefficients",
 !pointQ[1/(x-1/2+ep)] && !pointQ[ep/(x-1/2)] &&
 pointQ[ep Exp[x]/(1+ep Log[x])]];
FTAssert["a removable coefficient singularity is checked in the complete expression",
 pointQ[(x^2-1/4)/(x-1/2)]];

(* Repeated arithmetic is explicitly defined before the integration kernels.
   A second zero coordinate also exercises empty coefficient associations. *)
Clear[xx,yy,eps];
density=(1+xx+xx^2+xx^3)^2/(1+xx^4);
shared=ConstructMasterIntegralSolution[
 <|"KinematicVariables"->{xx,yy},"DimensionalRegulator"->eps,
   "ConnectionMatrices"->{eps {{density,0},{density^2,density}},ConstantArray[0,{2,2}]}|>,
 <|"BasePoint"->{1/5,1/5},"RequestedEpsilonOrders"->{0,1,2},
   "AnalyticDomain"->"Small neighborhood of the base point.",
   "BranchPrescription"->"Continuation from the base point."|>];
FTAssert["shared scalar definitions are complete finite expressions",
 MasterIntegralSolutionQ[shared] &&
 shared["KernelDefinitionCounts"]["SharedScalarExpressionCount"]>0];
FTAssert["shared expressions reproduce the exact DE after path substitution",
 AssociationQ[VerifyMasterIntegralSolution[shared,"IdentityCheck"->"Exact"]]];
badShared=shared;badShared["KernelDefinitions"]=ReplacePart[badShared["KernelDefinitions"],
 {1,"Expression"}->FeynFacetSolution`K[1,FeynFacetSolution`t]];
FTAssert["cyclic scalar definitions cannot be exported",!MasterIntegralSolutionQ[badShared]];
badShared=shared;badShared["KernelDefinitions"]=ReplacePart[badShared["KernelDefinitions"],
 {1,"Expression"}->(1+badShared["KernelDefinitions"][[1,"Expression"]])];
FTAssert["a changed shared scalar expression fails numerical DE verification",
 FailureQ[VerifyMasterIntegralSolution[badShared]]];


badShared=shared;badShared["KernelDefinitions"]=ReplacePart[badShared["KernelDefinitions"],
 {1,"Expression"}->FeynFacetSolution`K[1]];
FTAssert["malformed scalar references are rejected",!MasterIntegralSolutionQ[badShared]];
FTReport[];


