Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->adaptivePhase,
 "FinalMomenta"->{p1,p2,p3},"TotalMomentum"->q,"ExternalMomenta"->{q},
 "KinematicRules"->{FeynCalc`SPD[q]->s},"Assumptions"->s>0|>];
prepared=FeynFacet`PrepareCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[p1+p2]^2],phase,
 <|"ExternalKinematicConditions"->s>0|>];
data=FeynFacet`DecomposeMeasuredCutIntegrand[prepared];
If[!AssociationQ[data],Print[InputForm[data]];Exit[1]];
family=First[data["Families"]];cuts=family["CutIndices"];
candidatePlan=FeynFacet`ConstructUnitCutMasterCandidates[{family},data["Targets"]];
FTTest`FTAssert["unit-cut candidate selection keeps auxiliary denominators nonpositive",
 AssociationQ[candidatePlan]&&AllTrue[candidatePlan["Masters"],
  #[[2,cuts]]===ConstantArray[1,Length[cuts]]&&#[[2,-1]]<=0&]&&
 !candidatePlan["TargetSpanEstablished"]];
base=FeynCalc`GLI[family["Topology"][[1]],Table[Boole[MemberQ[cuts,j]],{j,Length[family["Topology"][[2]]]}]];
directory=CreateDirectory[];
Print["BASIS TEST DIRECTORY ",directory];
reduced=FeynFacet`ReduceCutIntegralsToBasis[{family},data["Targets"],{base},<|
 "WorkingDirectory"->directory,"Threads"->1,"HomogeneousScale"->s,
 "RationalSolver"->"FireFly","SamplingPoints"->{{D->13/5,s->1},{D->17/7,s->1}},
 "MaximumSeedIterations"->5,"MaximumSeeds"->10000|>];
If[FailureQ[reduced],Print[InputForm[reduced]]];
FTTest`FTAssert["sample-guided search yields exact target identities in the requested scalar span",
 AssociationQ[reduced]&&TrueQ[reduced["TargetSpanVerifiedExactly"]]&&
 Complement[reduced["Masters"],{base}]==={}];
If[AssociationQ[reduced],rows=FeynFacet`ApplyIntegralReduction[<|"Scalar"->data["Coefficients"]|>,reduced];
 ratio=Total[Lookup[Values[rows],base,0]]/.D->4-2e;
 FTTest`FTAssert["three-particle inverse pair mass agrees with an independent Dirichlet moment",
  Cancel[Together[ratio-FunctionExpand[s^-2 Gamma[-1-e]Gamma[3-3e]/(Gamma[1-e]Gamma[1-3e])]]]===0]];
FTTest`FTAssert["search refuses a request without complete sampling points",
 FailureQ[FeynFacet`ReduceCutIntegralsToBasis[{family},data["Targets"],{base},<|"WorkingDirectory"->directory<>"/Invalid"|>]]];
If[AssociationQ[reduced]&&DirectoryQ[directory],DeleteDirectory[directory,DeleteContents->True]];
Print["ADAPTIVE CUT BASIS TEST COMPLETE"];FTTest`FTReport[];
