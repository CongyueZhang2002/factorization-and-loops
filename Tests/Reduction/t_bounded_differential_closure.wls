Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
qg=FeynCalc`FCI[qs^2 qz-(4FeynCalc`SPD[qa,qk]-qs)^2];
qt=FeynCalc`FCTopology[QuadraticAngularMeasurement,{
 FeynCalc`FCI[FeynCalc`SFAD[qk]],FeynCalc`FCI[FeynCalc`SFAD[qP-qk]],
 FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,FeynCalc`FCI[FeynCalc`SPD[qa,qk]],0,{1,1}]],
 FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[qg,{1,1}]]},
 {qk},{qP,qa},FeynCalc`FCI[{FeynCalc`SPD[qP]->qs,FeynCalc`SPD[qa]->0,FeynCalc`SPD[qP,qa]->qs/2}],{}];
qf=FeynFacet`CreateCutIntegralFamily[<|"Topology"->qt,"Cuts"->{
 <|"Index"->1,"Type"->"Particle","Momentum"->qk|>,
 <|"Index"->2,"Type"->"Particle","Momentum"->qP-qk|>,
 <|"Index"->4,"Type"->"Measurement"|>},"TimeDirection"->qP,
 "Assumptions"->qs>0&&0<qz<1,"Dimension"->D,"MeasurePrefactor"->qs^2 (2Pi)^(2-D)|>];
FTTest`FTAssert["quadratic measurement uses a complete affine basis plus a dependent cut",AssociationQ[qf]];
If[!AssociationQ[qf],Print[qf];FTTest`FTReport[]];
FTTest`FTAssert["only the independent scalar-product coordinates are inverted",
 qf["AffineBasisIndices"]==={1,2,3}&&qf["DenominatorDegrees"]==={1,1,1,2}&&Keys[qf["DependentDenominatorRelations"]]==={4}];
qi=FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,0,1}];
qd=FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,0,2}];


qwork=CreateDirectory[];
initial=<|"Format"->"FeynFacet-CutFamilyReduction","Families"->{qf},"Targets"->{qi},"Rules"->{},"Masters"->{qi}|>;
request=<|"WorkingDirectory"->qwork<>"/Accepted","InitialReduction"->initial,
 "CandidateMasterBasis"->{qi},"Threads"->1,"IBPVectorMethod"->"Mixed","CutProtection"->"Particle",
 "SamplingPoints"->{{D->13/5,qs->1,qz->1/3},{D->17/7,qs->1,qz->2/5}},
 "HomogeneousScale"->qs,"RationalSolver"->"FireFly","MaximumSeedIterations"->5,"MaximumSeeds"->10000|>;
qsystem=FeynFacet`ConstructCutDifferentialSystem[{qf},{qi},{qz},request];
If[FailureQ[qsystem],Print[InputForm[qsystem]]];
FTTest`FTAssert["bounded derivative search closes the measured quadratic family without promoting cut dots",
 AssociationQ[qsystem]&&qsystem["MasterIntegralBasis"]==={qi}];
If[AssociationQ[qsystem],FTTest`FTAssert["closed derivative agrees with the independently integrated two-root density",
 Cancel[Together[qsystem["ConnectionMatrices"][[1,1,1]]+1/(2qz)+(D-4)/(2(1-qz))]]===0]];
replayed=FeynFacet`ConstructCutDifferentialSystem[{qf},{qi},{qz},Join[request,<|"GenerationKernels"->1|>]];
FTTest`FTAssert["a retained exact attempt resumes without regenerating seed shells",
 AssociationQ[replayed]&&replayed["ConnectionMatrices"]===qsystem["ConnectionMatrices"]];
failed=FeynFacet`ConstructCutDifferentialSystem[{qf},{qi},{qz},Join[request,
 <|"WorkingDirectory"->qwork<>"/Insufficient","MaximumSeeds"->1|>]];
FTTest`FTAssert["an insufficient bounded search preserves its derivative frontier and refuses promotion",
 MatchQ[failed,Failure["DerivativeCandidateSpanNotEstablished",_Association]]&&
 !failed[[2]]["ProvisionalIntegralsPromoted"]&&failed[[2]]["InputBasis"]==={qi}];
DeleteDirectory[qwork,DeleteContents->True];
Print["BOUNDED DIFFERENTIAL CLOSURE TEST COMPLETE"];FTTest`FTReport[];
