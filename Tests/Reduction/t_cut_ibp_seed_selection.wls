Print["FEYNFACET DRIVER ENTERED"];

$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/FeynFacet/Reduction/IBP/SeedSelection.wl"];
Get[root<>"/FeynFacet/Reduction/IBP/EquationSystems.wl"];
spGeometry=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->spSource,
 "FinalMomenta"->{spK1,spK2,spK3},"TotalMomentum"->spP+spQ,"ExternalMomenta"->{spP,spQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[spP]->0,FeynCalc`SPD[spQ]->-spS,
  FeynCalc`SPD[spP,spQ]->spS/(2spX)}],"ReferenceMomentum"->spP,"TaggedMomentum"->spK1,
 "MeasurementVariable"->spZ,"Assumptions"->spS>0&&0<spX<1&&0<spZ<1|>];
spPrepared=FeynFacet`PrepareMeasuredCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[spP-spK2]],spGeometry,
 <|"ExternalKinematicConditions"->spS>0&&0<spX<1|>];
spFamily=First[FeynFacet`DecomposeMeasuredCutIntegrand[spPrepared]["Families"]];
spName=spFamily["Topology"][[1]];
spT1=FeynCalc`GLI[spName,{1,1,1,1,1,-8,0}];
spT2=FeynCalc`GLI[spName,{1,1,1,1,3,-2,0}];
spPlan=FeynFacet`PlanCutIBPSeeds[spFamily,{spT1,spT2}];
FTTest`FTAssert["target profiles do not form an unnecessary dot-times-rank rectangle",
 AssociationQ[spPlan]&&ContainsAll[spPlan["Seeds"],{spT1,spT2}]&&
 !MemberQ[spPlan["Seeds"],FeynCalc`GLI[spName,{1,1,1,1,3,-8,0}]]];
FTTest`FTAssert["unit-cut targets do not preallocate cut-dot seed combinations",
 AllTrue[spPlan["Seeds"],#[[2,spFamily["CutIndices"]]]==={1,1,1,1}&]&&spPlan["SeedCount"]<200];
spColumnTest=FeynFacet`GenerateCutIBPEquations[spFamily,Take[spPlan["Seeds"],UpTo[10]]];
FTTest`FTAssert["exact equation columns keep raised cuts outside the initial seed bounds",
 AnyTrue[Flatten[Keys/@spColumnTest["Rows"]],Max[#[[2,spFamily["CutIndices"]]]]>1&]];

spFrontier=FeynCalc`GLI[spName,{2,1,1,1,1,-2,0}];
spPredecessors=FeynFacet`FindCutIBPPredecessorSeeds[spFamily,{spFrontier},spPlan["Seeds"]];
FTTest`FTAssert["predecessor seeds preserve cuts and do not promote auxiliary denominators",
 AssociationQ[spPredecessors]&&spPredecessors["SeedCount"]>0&&
 AllTrue[spPredecessors["Seeds"],Min[#[[2,spFamily["CutIndices"]]]]>0&&Max[#[[2,{6,7}]]]<=0&]&&
 Intersection[spPlan["Seeds"],spPredecessors["Seeds"]]==={}];
spIncidences=Table[
 spEquations=FeynFacet`GenerateCutIBPEquations[spFamily,{spSeed}]["Rows"];
 AnyTrue[spEquations,Lookup[#,Key[spFrontier],0]=!=0&],
 {spSeed,spPredecessors["Seeds"]}];
FTTest`FTAssert["every selected predecessor has actual nonzero incidence in its exact IBP equations",
 AllTrue[spIncidences,TrueQ]];
(* An independent sparse linear-algebra fixture: a harder unknown must be
   eliminated before the requested target can reduce to the preferred one. *)
spM=FeynCalc`GLI[spName,{1,1,1,1,1,0,0}];
spT=FeynCalc`GLI[spName,{1,1,1,1,1,-1,0}];
spH=FeynCalc`GLI[spName,{1,1,1,1,1,-2,0}];
spRows={<|spH->1,spT->-spA|>,<|spH->1,spM->-spA|>};
spDirectory=CreateDirectory[];
spRequest=<|"WorkingDirectory"->spDirectory,"Points"->{{spA->17},{spA->19}},
 "Prime"->2147483647,"Threads"->1,"PreferredMasterIntegrals"->{spM}|>;
spSamples=FeynFacet`SampleCutIBPEquations[spRows,{spT},{spFamily},spRequest];
If[FailureQ[spSamples],Print[spSamples]];
FTTest`FTAssert["Kira finite-field samples eliminate a harder auxiliary at both points",
 AssociationQ[spSamples]&&Length[spSamples["Samples"]]===2&&
 AllTrue[spSamples["Samples"],#["TargetRemainderRank"]===0&&(spT/.#["Rules"])===spM&]&&
 spSamples["ExactReductionEstablished"]===False];
spOutside=FeynFacet`SampleCutIBPEquations[spRows,{spT},{spFamily},
 Join[spRequest,<|"WorkingDirectory"->spDirectory<>"/WithoutPreference","PreferredMasterIntegrals"->{}|>]];
FTTest`FTAssert["an unpreferred scalar remainder has nonzero rank",
 AssociationQ[spOutside]&&AllTrue[spOutside["Samples"],#["TargetRemainderRank"]===1&]];
spScaleRows={<|spH->1,spT->-spScale spA|>,<|spH->1,spM->-spScale^2 spA|>};
spNormalized=FeynFacet`NormalizeIntegralEquationScale[spScaleRows,<|spM->0,spT->1,spH->2|>,spScale];
FTTest`FTAssert["equation homogeneity removes a scale by an exact change of unknowns",
 AssociationQ[spNormalized]&&spNormalized["Rows"]===spRows&&
 FeynFacet`RestoreIntegralEquationScale[{spT->spM},spNormalized]==={spT->spScale spM}];
spBadScale=FeynFacet`NormalizeIntegralEquationScale[
 {<|spH->1,spT->-(1+spScale)spA|>},<|spM->0,spT->1,spH->2|>,spScale];
FTTest`FTAssert["a scale-dependent matrix cannot be treated as its value at scale one",
 FailureQ[spBadScale]];
spHarder=FeynFacet`FindCutIBPPredecessorSeeds[spFamily,{spFrontier},spPlan["Seeds"],
 <|"FrontierNeighborDepth"->1|>];
FTTest`FTAssert["a bounded harder shell adds candidates without deleting the original frontier",
 AssociationQ[spHarder]&&ContainsAll[spHarder["SearchFrontier"],{spFrontier}]&&
 ContainsAll[spHarder["Seeds"],spPredecessors["Seeds"]]&&spHarder["SeedCount"]>spPredecessors["SeedCount"]];
If[StringStartsQ[ExpandFileName[spDirectory],ExpandFileName[$TemporaryDirectory]<>"/"],
 DeleteDirectory[spDirectory,DeleteContents->True]];
Print["AFFINE REGRESSION COMPLETE"];FTTest`FTReport[];
