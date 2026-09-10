$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
realFlowTop=FeynCalc`FCTopology[realFlowFamily,
 {FeynCalc`SFAD[realFlowL],FeynCalc`SFAD[realFlowP-realFlowL],FeynCalc`SFAD[realFlowK-realFlowL]},
 {realFlowL},{realFlowP,realFlowK},{},{}];
realFlowData=<|"Topology"->realFlowTop,"CutIndices"->{1,2},"Prescription"->{0},
 "Master"->FeynCalc`GLI[realFlowFamily,{1,1,1}]|>;
realFlowPrepare[data_]:=Quiet[Catch[FeynFacet`Private`masterIntegralTopologyData[data],
 FeynFacet`Private`$masterIntegralFailure]];
FTTest`FTAssert["explicitly chosen AMFlow phase-space convention remains evaluable",
 AssociationQ[realFlowPrepare[realFlowData]]];
FTTest`FTAssert["prescription-free integral keeps phase-space loops at zero",
 realFlowPrepare[Append[realFlowData,"PropagatorPrescriptions"->{0,0,0}]]["Prescription"]==={0}];
Scan[Function[sgn,FTTest`FTAssert["unresolved real-emission prescription "<>ToString[sgn]<>" is rejected",
 realFlowPrepare[Append[realFlowData,"PropagatorPrescriptions"->{0,0,sgn}]]===$Failed]],{1,-1}];
FTTest`FTAssert["ordinary numerator slots require no causal limit",
 AssociationQ[realFlowPrepare[Join[realFlowData,<|"Master"->FeynCalc`GLI[realFlowFamily,{2,1,-1}],
 "PropagatorPrescriptions"->{0,0,1}|>]]]];
FTTest`FTAssert["dotted positive-energy cuts themselves are still supported",
 AssociationQ[realFlowPrepare[Join[realFlowData,<|"Master"->FeynCalc`GLI[realFlowFamily,{2,1,1}],
 "PropagatorPrescriptions"->{0,0,0}|>]]]];
FTTest`FTAssert["a source certificate cannot override explicit master prescriptions",
 realFlowPrepare[Join[realFlowData,<|"PropagatorPrescriptions"->{0,0,1},
 "SourceOrdinaryPrescriptionCertificate"-><|"Status"->"CertifiedGenericKinematics"|>|>]]===$Failed];
FTTest`FTAssert["any active member of a master batch is checked",
 realFlowPrepare[Join[realFlowData,<|"Master"->{FeynCalc`GLI[realFlowFamily,{1,1,0}],FeynCalc`GLI[realFlowFamily,{1,1,2}]},
 "PropagatorPrescriptions"->{0,0,1}|>]]===$Failed];
realFlowNested=<|"Master"->realFlowData["Master"],"Prescription"->{0},
 "TopologyRecord"->Join[KeyTake[realFlowData,{"Topology","CutIndices"}],<|"PropagatorPrescriptions"->{0,0,-1}|>]|>;
FTTest`FTAssert["nested topology prescription metadata cannot be silently lost",realFlowPrepare[realFlowNested]===$Failed];
FTTest`FTAssert["invalid metadata dimensions fail closed",
 realFlowPrepare[Append[realFlowData,"PropagatorPrescriptions"->{0}]]===$Failed];
realFlowVirtual=Join[realFlowData,<|"CutIndices"->{},"Prescription"->{1},"PropagatorPrescriptions"->{1,1,1}|>];
FTTest`FTAssert["virtual Feynman prescriptions remain supported",AssociationQ[realFlowPrepare[realFlowVirtual]]];
FTTest`FTReport[];
