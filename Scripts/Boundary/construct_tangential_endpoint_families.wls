#!/usr/bin/env wolframscript
(* One main kernel owns at most eight subkernels. Each task executes the
   same process-independent single-system constructor and preserves failure
   records. Resume requires identical mathematical source and common data. *)
$HistoryLength=0;
campaignRoot=DirectoryName[ExpandFileName[$InputFileName],3];
campaignArgs=Rest[$ScriptCommandLine];
If[Length[campaignArgs]=!=2,Print["Expected CAMPAIGN_INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
campaignRead[path_String]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
campaignRead[data_]:=data;
campaignSave[data_,path_]:=Module[{temporary=path<>".partial",stream},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 stream=OpenWrite[temporary,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[data,PerformanceGoal->"Size"]],"Byte"];
 Close[stream];RenameFile[temporary,path,OverwriteTarget->True]];
campaignInput=campaignRead[campaignArgs[[1]]];
campaignOutput=ExpandFileName[campaignArgs[[2]]];
If[!AssociationQ[campaignInput],Print["FAIL campaign input"];Exit[2]];
campaignSources=Lookup[campaignInput,"DifferentialSystemFiles",{}];
campaignWorkers=Lookup[campaignInput,"Workers",1];
campaignSeconds=Lookup[campaignInput,"FamilyTimeLimit",900];
campaignCommon=Lookup[campaignInput,"CommonInput",<||>];
campaignOverrides=Lookup[campaignInput,"FamilyInputOverrides",<||>];
campaignResume=TrueQ[Lookup[campaignInput,"Resume",True]];
If[!MatchQ[campaignSources,{__String}] || !DuplicateFreeQ[campaignSources] ||
 !AssociationQ[campaignCommon] || !AssociationQ[campaignOverrides] ||
 !AllTrue[Values[campaignOverrides],AssociationQ] || !IntegerQ[campaignWorkers] ||
 !(1<=campaignWorkers<=8) || !NumericQ[campaignSeconds] || campaignSeconds<=0,
 Print["FAIL campaign sources, workers, common input or time limit"];Exit[2]];
If[!DirectoryQ[campaignOutput],CreateDirectory[campaignOutput,CreateIntermediateDirectories->True]];
campaignCommonData=campaignCommon;
campaignCommonData=Join[campaignCommonData,<|"ConstructionImplementation"->
  Association@Table[file->Import[campaignRoot<>"/"<>file,"Text"],{file,{
   "FeynFacet/Boundary/TangentialSystem.wl",
   "FeynFacet/DifferentialEquations/LocalAnalysis/Normalization.wl",
   "FeynFacet/Boundary/PrimaryExpansion.wl",
   "FeynFacet/DifferentialEquations/LocalAnalysis/Frobenius.wl",
   "Scripts/Boundary/construct_tangential_endpoints.wls"}}]|>];
If[KeyExistsQ[campaignCommonData,"PhysicalBoundaryConstruction"],
 campaignConstruction=campaignRead[campaignCommonData["PhysicalBoundaryConstruction"]];
 If[!AssociationQ[campaignConstruction],Print["FAIL physical boundary construction"];Exit[2]];
 campaignConstructionFile=campaignOutput<>"/physical_boundary_construction.wxf";
 campaignCommonData=Join[campaignCommonData,<|"PhysicalBoundaryConstruction"->campaignConstruction|>]];
campaignSameCommon=FileExistsQ[campaignOutput<>"/common_mathematical_input.wxf"] &&
 SameQ[campaignRead[campaignOutput<>"/common_mathematical_input.wxf"],campaignCommonData];
campaignSave[campaignCommonData,campaignOutput<>"/common_mathematical_input.wxf"];
If[KeyExistsQ[campaignCommonData,"PhysicalBoundaryConstruction"],
 campaignSave[campaignConstruction,campaignConstructionFile];
 campaignCommon=Join[campaignCommon,<|"PhysicalBoundaryConstruction"->campaignConstructionFile|>]];
campaignSave[campaignInput,campaignOutput<>"/campaign_input.wxf"];
campaignJobs=Table[
 campaignSource=campaignRead[sourceFile];
 If[!AssociationQ[campaignSource] || !StringQ[Lookup[campaignSource,"Family",None]],
  Print["FAIL invalid source system ",sourceFile];Exit[2]];
 campaignFamily=campaignSource["Family"];
 If[!StringMatchQ[campaignFamily,RegularExpression["[A-Za-z0-9_-]+"]],
  Print["FAIL family identifier ",campaignFamily];Exit[2]];
 campaignDirectory=FileNameJoin[{campaignOutput,campaignFamily}];
 campaignConfig=Join[campaignCommon,Lookup[campaignOverrides,campaignFamily,<||>],
   <|"DifferentialSystem"->ExpandFileName[sourceFile]|>];
 campaignConfigFile=FileNameJoin[{campaignOutput,"Inputs",campaignFamily<>".wxf"}];
 campaignCanReuse=campaignResume && campaignSameCommon &&
   FileExistsQ[campaignDirectory<>"/summary.wxf"] &&
   FileExistsQ[campaignDirectory<>"/endpoint_system.wxf"] &&
   If[KeyExistsQ[campaignCommon,"PhysicalBoundaryConstruction"],
     FileExistsQ[campaignDirectory<>"/boundary_basis_matching.wxf"],True] &&
   FileExistsQ[campaignDirectory<>"/source_system.wxf"] &&
   FileExistsQ[campaignDirectory<>"/input.wxf"] &&
   Lookup[campaignRead[campaignDirectory<>"/summary.wxf"],"Status",None]==="PASS" &&
   SameQ[campaignRead[campaignDirectory<>"/source_system.wxf"],campaignSource] &&
   SameQ[campaignRead[campaignDirectory<>"/input.wxf"],campaignConfig];
 campaignSave[campaignConfig,campaignConfigFile];
 <|"Family"->campaignFamily,"InputFile"->campaignConfigFile,
   "OutputDirectory"->campaignDirectory,"Reused"->campaignCanReuse|>,
 {sourceFile,campaignSources}];
If[!DuplicateFreeQ[Lookup[campaignJobs,"Family"]],Print["FAIL repeated family"];Exit[2]];

Begin["TangentialEndpointCampaign`"];
Clear[RunFamily];
RunFamily[job_,driver_,seconds_] := Module[{result,elapsed=AbsoluteTime[],log,code,
  previousOutput=$Output,previousMessages=$Messages,summary,write},
 write[data_,file_]:=Module[{temporary=file<>".partial",stream},
  stream=OpenWrite[temporary,BinaryFormat->True];
  BinaryWrite[stream,Normal[BinarySerialize[data,PerformanceGoal->"Size"]],"Byte"];
  Close[stream];RenameFile[temporary,file,OverwriteTarget->True]];
 If[TrueQ[job["Reused"]],Return[Join[job,<|"Status"->"PASS","ElapsedSeconds"->0|>]]];
 If[!DirectoryQ[job["OutputDirectory"]],CreateDirectory[job["OutputDirectory"],CreateIntermediateDirectories->True]];
 write[<|"Status"->"RUNNING","Family"->job["Family"]|>,job["OutputDirectory"]<>"/summary.wxf"];
 Export[job["OutputDirectory"]<>"/progress.json",<|"Status"->"RUNNING","Family"->job["Family"]|>,"RawJSON"];
 log=OpenWrite[job["OutputDirectory"]<>"/construction.log"];
 code=TimeConstrained[
  Block[{$Output={log},$Messages={log},
    $ScriptCommandLine={"wolframscript",job["InputFile"],job["OutputDirectory"]},
    System`Exit=Function[status,Throw[status,"EndpointWorkerExit"]]},
   Catch[CheckAbort[Get[driver],Throw["Aborted","EndpointWorkerExit"]],"EndpointWorkerExit"]],
  seconds,"TimeLimit"];
 Close[log];
 result=If[FileExistsQ[job["OutputDirectory"]<>"/summary.wxf"] &&
   (code===0 || code===Null),
   Import[job["OutputDirectory"]<>"/summary.wxf","WXF"],
   <|"Status"->"FAIL","Cause"->code|>];
 summary=Join[job,<|"Status"->Lookup[result,"Status","FAIL"],
   "Result"->result,"ElapsedSeconds"->AbsoluteTime[]-elapsed|>];
 If[Lookup[summary,"Status",None]=!="PASS",write[
   <|"Status"->"FAIL","Family"->job["Family"],"Cause"->code|>,job["OutputDirectory"]<>"/summary.wxf"]];
 write[summary,job["OutputDirectory"]<>"/campaign_result.wxf"];
 Export[job["OutputDirectory"]<>"/progress.json",
   KeyTake[summary,{"Family","Status","Reused","ElapsedSeconds"}],"RawJSON"];
 summary
];
End[];
campaignDriver=campaignRoot<>"/Scripts/Boundary/construct_tangential_endpoints.wls";
campaignStarted=AbsoluteTime[];
If[campaignWorkers===1,
 campaignResults=TangentialEndpointCampaign`RunFamily[#,campaignDriver,campaignSeconds]&/@campaignJobs,
 LaunchKernels[campaignWorkers];
 ParallelEvaluate[$HistoryLength=0];
 DistributeDefinitions[TangentialEndpointCampaign`RunFamily];
 campaignResults=With[{driver=campaignDriver,seconds=campaignSeconds},
   ParallelMap[TangentialEndpointCampaign`RunFamily[#,driver,seconds]&,campaignJobs,
     Method->"FinestGrained",DistributedContexts->None]];
 CloseKernels[]];
campaignReport=<|"DataType"->"TangentialEndpointFamilyCampaign","SchemaVersion"->1,
 "Results"->campaignResults,"RequestedFamilyCount"->Length[campaignJobs],
 "PassedFamilyCount"->Count[Lookup[campaignResults,"Status"],"PASS"],
 "FailedFamilyCount"->Count[Lookup[campaignResults,"Status"],Except["PASS"]],
 "ReusedFamilyCount"->Count[Lookup[campaignResults,"Reused"],True],
 "ElapsedSeconds"->AbsoluteTime[]-campaignStarted,"Workers"->campaignWorkers|>;
campaignSave[campaignReport,campaignOutput<>"/campaign_report.wxf"];
Print["PASS ",campaignReport["PassedFamilyCount"]," / ",campaignReport["RequestedFamilyCount"],
 "; FAIL ",campaignReport["FailedFamilyCount"],"; reused ",campaignReport["ReusedFamilyCount"],
 "; elapsed seconds ",campaignReport["ElapsedSeconds"]];
If[campaignReport["FailedFamilyCount"]>0,Exit[1]];
