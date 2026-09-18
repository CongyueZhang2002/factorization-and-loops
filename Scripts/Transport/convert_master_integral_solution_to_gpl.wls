#!/usr/bin/env wolframscript
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected SOLUTION_DIRECTORY OPTIONS.wl OUTPUT_DIRECTORY"];Exit[2]];
data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];
options=FeynFacetRecords`ReadRecord[args[[2]]];
If[!AssociationQ[data]||!ListQ[options],Print["Invalid solution or option list"];Exit[2]];
result=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,Sequence@@options];
If[FailureQ[result],Print[result];Exit[1]];
directory=ExpandFileName[args[[3]]];
If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
path=FileNameJoin[{directory,"solution.wxf"}];
temporary=path<>".tmp-"<>ToString[$ProcessID];
stream=OpenWrite[temporary,BinaryFormat->True];
BinaryWrite[stream,Normal[BinarySerialize[result,PerformanceGoal->"Size"]],"Byte"];Close[stream];
RenameFile[temporary,path,OverwriteTarget->True];
Print["GPL_CONVERSION ",KeyTake[result["GPLRepresentation"],
 {"Status","GPLCount","MaximumGPLWeight","ConversionSeconds","ReusedIntegralExpressions"}]];
(* A partial result is useful and saved, but is not silently labelled complete. *)
Exit[If[result["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL",0,3]];
