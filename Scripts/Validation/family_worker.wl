(* One fresh licensed subkernel owns one family, including AMFlow's generated
   solver scripts. Only small progress records return to the dispatcher. *)
BeginPackage["FeynFacetValidationWorker`"];
RunFamily::usage="RunFamily[task] validates one family with one core and isolated script globals.";
Begin["`Private`"];
writeJSON[file_,value_]:=(If[Export[file<>".tmp",value,"RawJSON"]===$Failed,
 Throw[Failure["WorkerProgressSerializationFailed",<||>]]];RenameFile[file<>".tmp",file,OverwriteTarget->True]);
runFamily[task_Association] := Module[
 {root=task["RepositoryRoot"],folder=task["OutputDirectory"],request,referenceRequest,
 reference,comparison,record,started=AbsoluteTime[],stages,execution,phase,script,args,
 specification,limits,log,phaseTime=task["PhaseTimeLimit"],old,cpu=task["CPU"]},
 RunProcess[{"taskset","-apc",ToString[cpu],ToString[$ProcessID]}];
 SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
 SetEnvironment[{"OMP_NUM_THREADS"->"1","OPENBLAS_NUM_THREADS"->"1","MKL_NUM_THREADS"->"1"}];
 Get[root<>"/FeynFacet/Interfaces/AMFlowRuntime.wl"];
 request=folder<>"/pool_request.wxf";referenceRequest=folder<>"/amflow_request.wl";
 reference=folder<>"/amflow_reference.wxf";comparison=folder<>"/comparison.wxf";
 specification=Import[task["RequestFile"],"WXF"];
 limits=Association[specification["EvaluationOptions"]];
 limits["Threads"]=1;limits["TimeLimit"]=phaseTime;
 specification=Join[specification,<|"Threads"->1,"TimeLimit"->phaseTime,
  "EvaluationOptions"->Normal[limits]|>];
 Export[request<>".tmp",specification,"WXF"];RenameFile[request<>".tmp",request,OverwriteTarget->True];
 record=<|"Family"->task["ID"],"KernelID"->$KernelID,"WorkerPID"->$ProcessID,
  "CPU"->cpu,"Threads"->1,"Status"->"Running","Finished"->False,"Phases"->{},
  "ThreadOptions"->ToString[SystemOptions["ParallelOptions"],InputForm]|>;
 writeJSON[folder<>"/pool_status.json",record];
 stages={
  {"prepare",root<>"/Scripts/Validation/prepare_complete_master_reference.wls",{request,referenceRequest}},
  {"amflow",root<>"/Scripts/Transport/evaluate_masters_with_amflow.wls",{referenceRequest,reference}},
  {"compare",root<>"/Scripts/Validation/validate_complete_masters.wls",{request,reference,comparison}}
 };
 Catch[Do[
  {phase,script,args}=stage;record["Phase"]=phase;
  writeJSON[folder<>"/pool_status.json",record];
  If[phase==="amflow",
   (* Parsing/serialization must preserve all context-qualified integral heads. *)
   old=Get[referenceRequest];old=Join[old,<|"Threads"->1,"WolframScriptExecution"->"CurrentKernel","TimeLimit"->phaseTime|>];
   Block[{$ContextPath={"System`"}},Put[old,referenceRequest<>".tmp"]];
   RenameFile[referenceRequest<>".tmp",referenceRequest,OverwriteTarget->True]];
  If[phase==="compare"&&FileExistsQ[comparison<>".json"],DeleteFile[comparison<>".json"]];
  log=folder<>"/"<>phase<>".log";
  If[FileExistsQ[log],RenameFile[log,log<>"."<>ToString[$ProcessID],OverwriteTarget->True]];
  execution=TimeConstrained[
   FeynFacet`Private`runIsolatedWolframScript[script,args,log],phaseTime,
   <|"ExitCode"->124,"ElapsedSeconds"->phaseTime|>];
  record["Phases"]=Append[record["Phases"],Join[<|"Phase"->phase|>,execution]];
  If[execution["ExitCode"]=!=0,
   record["Status"]=If[phase==="compare","EvaluationFailed","ReferenceFailed"];Throw[Null]],
 {stage,stages}]];
 If[record["Status"]==="Running",record["Status"]="Compared"];
 record["Finished"]=True;record["ElapsedSeconds"]=AbsoluteTime[]-started;
 writeJSON[folder<>"/pool_status.json",record];record
];
RunFamily[task_Association] := Module[{result},
 result=TimeConstrained[CheckAbort[Catch[runFamily[task],_,
   Function[{value,tag},Failure["UncaughtWorkerExit",<|"Tag"->ToString[tag],"Value"->ToString[value]|>]]],
   Failure["WorkerAborted",<||>]],3 task["PhaseTimeLimit"]+120,Failure["WorkerTimeLimit",<||>]];
 If[!AssociationQ[result],result=<|"Family"->task["ID"],"KernelID"->$KernelID,
   "WorkerPID"->$ProcessID,"Status"->"WorkerFailed","Finished"->True,
   "Failure"->ToString[result,InputForm]|>;
  writeJSON[task["OutputDirectory"]<>"/pool_status.json",result]];
 result
];
End[];EndPackage[];
