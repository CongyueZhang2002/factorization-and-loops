root="/home/maxzhang/factorization-and-loops";$HistoryLength=0;$MaxExtraPrecision=50;
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
setup=<|"SetMassZero"->{pa,pb,pc,pd},"PartonIntegrated"->{pd},"PartonMomentum"->({pa,pb}->{pc,pd})|>;
rules=FeynFacet`Private`topologyExternalOnShellRules[setup,{pa,pb,pc},{ell}];
support=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[pa+pb-pc]]];
FTTest`FTAssert["eliminated two-body momentum remains on shell",Expand[support/.rules]===0 && Length[rules]===4];
realSetup=Join[setup,<|"PartonMomentum"->({pa,pb}->{pc,pd,ell})|>];
realRules=FeynFacet`Private`topologyExternalOnShellRules[realSetup,{pa,pb,pc},{ell}];
FTTest`FTAssert["real-emission cut is not imposed as external relation",Length[realRules]===3];
subset=FeynFacet`Private`topologyExternalOnShellRules[setup,{pa,pc},{ell}];
FTTest`FTAssert["subtopology gains no extraneous external invariant",Length[subset]===2];
config=Join[setup,<|"ForwardAmplitudes"-><|"LoopOrder"->1,"LoopMomenta"->{ell},"DiagramIndices"->{1},"SelectedIndex"->1|>,
 "ConjugateAmplitudes"-><|"LoopOrder"->0,"LoopMomenta"->{},"DiagramIndices"->{1},"SelectedIndex"->1|>,"PhaseSpaceMomentum"->{pd}|>];
families=Block[{Print},FeynFacet`BuildTopologies[FeynCalc`SFAD[ell,ell-pa,ell-pc],{ell},config]];
FTTest`FTAssert["triangle is completed over the process external basis",ListQ[families]&&Length[families]===1&&Length[families[[1]]["Topology"][[2]]]===4];
top=families[[1]]["Topology"];
gliRules=Flatten[FeynCalc`FCLoopCreateRulesToGLI[top]];
FTTest`FTAssert["the added external vector has an explicit scalar-product reduction",
 FreeQ[FeynCalc`FCI[FeynCalc`SPD[ell,pb]]/.gliRules,ell]];
FTTest`FTReport[];
