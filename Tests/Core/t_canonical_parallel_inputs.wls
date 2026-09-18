Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tmp=CreateDirectory[];input=CreateDirectory[tmp<>"/Input"];
Get[root<>"/Tests/Support/GeneratedPairRecords.wl"];
generatedRows=FeynFacetTestPairs`GeneratePairTestRecords[root,tmp<>"/Generated"];
If[!MatchQ[generatedRows,{_Association,_Association}],Print["PAIR FIXTURE GENERATION FAILED"];Exit[1]];
template=Last[generatedRows];
records=Table[With[{pair=<|"Forward"->1,"Conjugate"->i|>},
 Join[template,<|"Pair"->pair,"ResultDirectory"->input,
 "Setup"->Append[template["Setup"],"ConjugateAmplitudes"->Append[template["Setup"]["ConjugateAmplitudes"],"SelectedIndex"->i]],
 "Topologies"->(Append[#,"DiagramPair"->pair]&/@template["Topologies"])|>]],{i,32}];
files=MapIndexed[FeynFacet`FamilyArtifactWrite[#1,input<>"/F1_C"<>ToString[First[#2]]<>".wl"]&,records];
readWorkers={};
out=Internal`InheritedBlock[{FeynFacet`Private`facetSymbolicMap},
 DownValues[originalRecordMap]=DownValues[FeynFacet`Private`facetSymbolicMap]/.FeynFacet`Private`facetSymbolicMap->originalRecordMap;
 Clear[FeynFacet`Private`facetSymbolicMap];
 FeynFacet`Private`facetSymbolicMap[fn_,items_List]:=If[fn===FeynFacet`FamilyArtifactRead,
  Module[{result=originalRecordMap[Function[item,{$KernelID,FeynFacet`FamilyArtifactRead[item]}],items]},
   If[!ListQ[result],$Failed,readWorkers=First/@result;Last/@result]],
  originalRecordMap[fn,items]];
 FeynFacet`Private`CanonicalizePairArtifacts[files,tmp<>"/Canonical","Kernels"->2,"ReturnRecords"->True]];
FTTest`FTAssert["the canonicalizer reads a full file batch on its owned workers",
 AssociationQ[out]&&Length[readWorkers]===32&&AllTrue[readWorkers,#>0&]&&Length[DeleteDuplicates[readWorkers]]===2];
FTTest`FTAssert["returned canonical records match the parallel-written files",
 AssociationQ[out]&&out["Records"]===(FeynFacet`FamilyArtifactRead/@out["Files"])];
FTTest`FTAssert["canonical read and write workers are released",Kernels[]==={}];
CopyFile[files[[1]]<>".meta.wxf",files[[2]]<>".meta.wxf",OverwriteTarget->True];
bad=Quiet@FeynFacet`Private`CanonicalizePairArtifacts[files,tmp<>"/Corrupt","Kernels"->2,"ReturnRecords"->True];
FTTest`FTAssert["a corrupt companion rejects parallel input before acceptance",
 bad===$Failed&&!FileExistsQ[tmp<>"/Corrupt/CanonicalRegistry.wl"]&&Kernels[]==={}];
data=If[AssociationQ[out],Catch[FeynFacet`Private`ibpInputData[out["Records"],True],FeynFacet`Private`$ibpFailure],$Failed];
prepared=<|"InputData"->data,"TopologyEquivalence"-><||>,"Targets"->{},
 "Completed"-><||>,"Runtime"-><||>,"ProjectLocation"-><||>|>;
project=<|"ProjectRoot"->tmp,"Directory"->tmp,"Manifest"->{},"InputPayload"-><||>,"InputFingerprint"->"fixture"|>;
solve=Internal`InheritedBlock[{FeynFacet`Private`ibpSolvedProjectFingerprint},
 Clear[FeynFacet`Private`ibpSolvedProjectFingerprint];FeynFacet`Private`ibpSolvedProjectFingerprint[___]:="fixture";
 FeynFacet`Private`kiraStreamSolveData[prepared,project,<||>]];
FTTest`FTAssert["the Kira solve handle retains only the derived input summary",
 AssociationQ[solve]&&solve["InputData"]===KeyDrop[data,"Sources"]&&!KeyExistsQ[solve["InputData"],"Sources"]];
DeleteDirectory[tmp,DeleteContents->True];FTTest`FTReport[];
