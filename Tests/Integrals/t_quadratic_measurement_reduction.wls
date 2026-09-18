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

qdz=FeynFacet`DifferentiateCutIntegral[qf,qi,qz];
qds=FeynFacet`DifferentiateCutIntegral[qf,qi,qs];
qtargets=DeleteDuplicates[Join[{qi,qd},Cases[{qdz,qds},_FeynCalc`GLI,Infinity]]];
qwork=FileNameJoin[{$TemporaryDirectory,"FeynFacetQuadraticMeasurementReduction"}];
qred=FeynFacet`KiraReduction[{qf},qtargets,<|"WorkingDirectory"->qwork,
 "MassDimensions"->{qs->2,qz->0},"Threads"->8,"SeedExtension"->{2,2},"NewWorkspaceForChangedInputs"->True|>];
FTTest`FTAssert["native quadratic measurement equations reduce through the common Kira path",AssociationQ[qred]];
If[!AssociationQ[qred],Print[qred];FTTest`FTReport[]];
Print["REDUCED BASIS ",InputForm[qred["Masters"]]];
qexpectedZ=-1/(2qz)-(D-4)/(2(1-qz));
FTTest`FTAssert["the reduced DE agrees with the independent two-root angular density",
 Factor[(qdz-qexpectedZ qi)/.qred["Rules"]]===0];
FTTest`FTAssert["the reduced scale derivative retains the physical phase-space normalization",
 Factor[(qds-(D-4)/(2qs)qi)/.qred["Rules"]]===0];
qvolume=FeynFacet`MasslessPhaseSpaceVolume[2,qs,qe];
qexact=qvolume qz^(-1/2)(1-qz)^(-qe)/Beta[1/2,1-qe];
FTTest`FTAssert["the independent density includes both roots and integrates to total phase space",
 FullSimplify[Integrate[qexact,{qz,0,1},Assumptions->qs>0&&qe<0]/qvolume,qs>0&&qe<0]===1];
qsystem=FeynFacet`ConstructCutDifferentialSystem[{qf},{qi},{qz},<|
 "WorkingDirectory"->qwork<>"-DE","Threads"->8,"SeedExtension"->{2,2},
 "NewWorkspaceForChangedInputs"->True|>];
FTTest`FTAssert["the common differential-system constructor closes a quadratic measurement",AssociationQ[qsystem]];
If[!AssociationQ[qsystem],Print[qsystem]];
Print["QUADRATIC REDUCTION TEST COMPLETE"];
FTTest`FTReport[];
