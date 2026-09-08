#!/usr/bin/env wolframscript
(* Evaluate an existing symbolic solution with boundary values and, optionally,
   compare to independently supplied reference master values at the endpoint. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]!=3,Print["Expected SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf"];Exit[2]];
read[path_] := If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
If[!DirectoryQ[DirectoryName[ExpandFileName[args[[3]]]]],
 CreateDirectory[DirectoryName[ExpandFileName[args[[3]]]],CreateIntermediateDirectories->True]];
request=read[args[[2]]];data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];
result=FeynFacetSolution`EvaluateMasterIntegralSolutionRequest[data,request];
Export[args[[3]]<>".tmp",result,"WXF"];RenameFile[args[[3]]<>".tmp",args[[3]],OverwriteTarget->True];
Print["RESULT ",If[AssociationQ[result],KeyTake[result,{"Status","ReferenceComparisonStatus","ReferenceComparisonScope","ElapsedSeconds"}],result]];
Exit[If[AssociationQ[result]&&Lookup[result,"ReferenceComparisonStatus","ReferenceComparisonPassed"]==="ReferenceComparisonPassed",0,1]];
