#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]<3,Print["Expected COEFFICIENT_INPUT_DIRECTORY ENDPOINT_DIRECTORY OUTPUT_DIRECTORY [FAMILY ...]"];Exit[2]];
{inputs,endpoints,output}=ExpandFileName/@Take[args,3];
families=If[Length[args]>3,Drop[args,3],FileBaseName/@Sort[FileNames["CF*.wxf",inputs]]];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
save[value_,file_]:=Module[{tmp=file<>".partial",stream},
 stream=OpenWrite[tmp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[value,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 RenameFile[tmp,file,OverwriteTarget->True]];
report={};failed=False;
Do[
 If[!FileExistsQ[endpoints<>"/"<>family<>"/laurent_bounds.wxf"],
  AppendTo[report,<|"Family"->family,"Status"->"EndpointSystemPending"|>];Continue[]];
 input=Import[inputs<>"/"<>family<>".wxf","WXF"];
 endpoint=Import[endpoints<>"/"<>family<>"/endpoint_system.wxf","WXF"];
 bounds=Import[endpoints<>"/"<>family<>"/laurent_bounds.wxf","WXF"];
 coefficientID[x_]:=FeynFacet`Private`coefficientMasterID[x];
 byMaster=AssociationThread[coefficientID/@input["OriginalMasterIntegralBasis"],input["CoefficientEntries"]];
 selectedIDs=coefficientID/@endpoint["OriginalMasterIntegralBasis"];
 omitted=Complement[Keys[byMaster],selectedIDs];
 If[AnyTrue[omitted,byMaster[#]["Terms"]=!={}&]||!SubsetQ[Keys[byMaster],selectedIDs],
  Print["ActiveCoefficientMasterOutsideEndpointSystem ",family];Exit[1]];
 alignedEntries=Lookup[byMaster,selectedIDs];
 Print["START ",family," dimension ",endpoint["Dimension"]];
 seconds=First[AbsoluteTiming[
   result=FeynFacet`DetermineMasterCoefficientEndpointOrders[
    alignedEntries,endpoint,bounds,input["Request"]]]];
 save[result,output<>"/"<>family<>".wxf"];
 If[FailureQ[result],failed=True;
   row=<|"Family"->family,"Status"->"Failed","Failure"->ToString[result,InputForm],"Seconds"->seconds|>,
   row=<|"Family"->family,"Status"->result["Status"],
    "MaximumNormalOrder"->result["MaximumNormalOrder"],
    "EndpointMasterUpperOrder"->ToString[Max[Values[result["RequiredEndpointMasterUpperOrders"]]],InputForm],
    "MissingCoefficientOrderCount"->Length[result["MissingCoefficientOrders"]],
    "UnresolvedRemainderClassCount"->Length[Lookup[result,"UnresolvedCoefficientRemainderClasses",{}]],
    "Seconds"->seconds|>];
 AppendTo[report,row];Print[row];
 Export[output<>"/summary.json",<|"Families"->report,"FailureCount"->Count[Lookup[report,"Status"],"Failed"]|>,"RawJSON"],
 {family,families}];
Exit[If[failed,1,0]];
