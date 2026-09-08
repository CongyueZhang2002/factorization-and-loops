#!/usr/bin/env wolframscript
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]!=2,Print["Expected REQUESTS.wl OUTPUT.wxf"];Exit[2]];
request=If[FileExtension[args[[1]]]==="wxf",Import[args[[1]],"WXF"],Get[args[[1]]]];
result=FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[request["Requests"],
 Sequence@@Lookup[request,"BatchOptions",{}]];
output=ExpandFileName[args[[2]]];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
temporary=output<>".tmp-"<>ToString[$ProcessID];Export[temporary,result,"WXF"];
RenameFile[temporary,output,OverwriteTarget->True];
Print[If[AssociationQ[result],KeyTake[result,{"Status","WorkersUsed","ElapsedSeconds"}],result]];
Exit[If[AssociationQ[result]&&result["Status"]==="Completed",0,1]];
