Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tmp=CreateDirectory[];
data=With[{z=I},<|"Scalar"->FeynCalc`CA x+z,
 "HeldKey"-><|HoldComplete[z]->7,HoldComplete[I]->11|>|>];
files=Table[FeynFacet`FamilyArtifactWrite[Append[data,"Index"->i],tmp<>"/r"<>ToString[i]<>".wl"],{i,3}];
before=Kernels[];
out=FeynFacet`Private`facetWithSymbolicWorkers[
 <|"Read"->FeynFacet`Private`facetSymbolicMap[FeynFacet`FamilyArtifactRead,files],
 "Serial"->FeynFacet`Private`facetWithSymbolicWorkers[
   FeynFacet`Private`facetSymbolicMap[Function[item,$KernelID],Range[3]],1],
 "ChangedPool"->Quiet[Block[{FeynFacet`Private`$facetSymbolicWorkers=Append[Kernels[],uninitializedKernel]},
   FeynFacet`Private`facetSymbolicMap[Identity,{1}]]]|>,2];
read=out["Read"];
FTTest`FTAssert["an explicit nested serial scope stays on the main kernel",out["Serial"]==={0,0,0}];
FTTest`FTAssert["a changed pool cannot receive record jobs",out["ChangedPool"]===$Failed];
FTTest`FTAssert["parallel record reads preserve exact values, order and held keys",
 read===(FeynFacet`FamilyArtifactRead/@files)];
FTTest`FTAssert["owned record workers are closed after success",Kernels[]===before];
failed=Catch[FeynFacet`Private`facetWithSymbolicWorkers[Throw[$Failed,"test"],2],"test"];
FTTest`FTAssert["owned record workers are closed after a thrown failure",failed===$Failed&&Kernels[]===before];
existing=FeynFacet`Private`facetLaunchKernels[1];
nested=FeynFacet`Private`facetWithSymbolicWorkers[Length[Kernels[]],2];
FTTest`FTAssert["an unrelated caller pool is retained and not expanded",nested===Length[existing]&&Kernels[]===existing];
CloseKernels[existing];
DeleteDirectory[tmp,DeleteContents->True];FTTest`FTReport[];
