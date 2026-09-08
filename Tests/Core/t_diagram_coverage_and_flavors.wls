root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
(* FeynArts' graph nesting: two topology containers with three inserted
   class diagrams, not two diagrams. *)
diagrams=FeynArts`TopologyList[][dummyTopo1->FeynArts`Insertions[FeynArts`Generic][
 FeynArts`FeynmanGraph[1,FeynArts`Generic==1][]->FeynArts`Insertions[FeynArts`Classes][
  FeynArts`FeynmanGraph[1,FeynArts`Classes==1][],FeynArts`FeynmanGraph[1,FeynArts`Classes==2][]]],
 dummyTopo2->FeynArts`Insertions[FeynArts`Generic][
 FeynArts`FeynmanGraph[1,FeynArts`Generic==1][]->FeynArts`Insertions[FeynArts`Classes][
  FeynArts`FeynmanGraph[1,FeynArts`Classes==1][]]]];
FTTest`FTAssert["inserted graphs are counted rather than topology containers",Length[diagrams]===2&&FeynFacet`CountProcessDiagrams[diagrams]===3];
side=<|"LoopOrder"->0,"LoopMomenta"->{},"DiagramIndices"->{1,2,3},"SelectedIndex"->3|>;
FTTest`FTAssert["selection accepts the last inserted graph",AssociationQ[FeynFacet`Private`normalizeAmplitudeSelection[diagrams,side,"test",True]]];
counts=<|"MasslessQuarkFlavors"-><|"UpType"->nU,"DownType"->nD|>|>;
idx=FeynArts`Index[Global`Generation,5];
amp=(a+Global`MQU[idx]^2)FeynArts`SumOver[idx,3];
FTTest`FTAssert["massless generation sum retains its multiplicity",FeynFacet`Private`modelResolveFlavorSums[amp,counts]===a nU];
amp2=(a+Global`MQD[idx]^2)FeynArts`SumOver[idx,3];
FTTest`FTAssert["different massless classes have distinct declared counts",FeynFacet`Private`modelResolveFlavorSums[amp2,counts]===a nD];
missing=Quiet[Catch[FeynFacet`Private`modelResolveFlavorSums[amp,<||>],FeynFacet`Private`$collinearFailure]];
FTTest`FTAssert["an undeclared flavor sum is not silently dropped",missing===$Failed];
FTTest`FTReport[];
