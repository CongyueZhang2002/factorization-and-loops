#!/usr/bin/env wolframscript
(* Explicit worker assignment prevents a scheduler from placing new work on
   a completed worker while that worker is being closed for a fresh family. *)
$HistoryLength=0;
Begin["FeynFacetValidationPool`"];
arguments=Rest[$ScriptCommandLine];spec=Import[First[arguments],"RawJSON"];
Needs["Parallel`Developer`"];
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
tasks=spec["Tasks"];capacity=spec["Workers"];cpus=spec["CPUs"];output=spec["OutputDirectory"];
workerFile=Lookup[spec,"WorkerFile",spec["RepositoryRoot"]<>"/Scripts/Validation/family_worker.wl"];
jobs=<||>;completed={};availableCPUs=cpus;started=AbsoluteTime[];
writeJSON[file_,value_]:=(Export[file<>".tmp",value,"RawJSON"];RenameFile[file<>".tmp",file,OverwriteTarget->True]);
writeState[]:=writeJSON[output<>"/pool_state.json",
 <|"Status"->If[tasks==={}&&Length[jobs]===0,"Finished","Running"],
 "CoordinatorPID"->$ProcessID,"RequestedWorkers"->capacity,"KernelCount"->Length[Kernels[]],
 "PendingFamilyCount"->Length[tasks],"ActiveFamilies"->Keys[jobs],"CompletedFamilies"->completed,
 "ElapsedSeconds"->AbsoluteTime[]-started|>];
CloseKernels[];
initial=TimeConstrained[LaunchKernels[capacity],60,{}];
If[Length[Kernels[]]=!=capacity,Print["Could not obtain all requested worker licenses"];CloseKernels[];Exit[2]];
While[tasks=!={}||Length[jobs]>0,
 Do[
  result=Parallel`Developer`ReceiveIfReady[jobs[id]["Kernel"]];
  If[result=!=Parallel`Developer`$NotReady,
   If[!AssociationQ[result],result=<|"Family"->id,"Status"->"WorkerFailed","Finished"->True,
     "Failure"->ToString[result,InputForm]|>;
    writeJSON[jobs[id]["Task"]["OutputDirectory"]<>"/pool_status.json",result]];
   CloseKernels[{jobs[id]["Kernel"]}];
   availableCPUs=Append[availableCPUs,jobs[id]["Task"]["CPU"]];
   AppendTo[completed,id];KeyDropFrom[jobs,id];
   Print["FINISHED ",id," ",Lookup[result,"Status","WorkerFailed"]]],
 {id,Keys[jobs]}];
 If[tasks=!={}&&Length[Kernels[]]<capacity,
  TimeConstrained[LaunchKernels[Min[capacity-Length[Kernels[]],Length[tasks]]],60,{}]];
 freeKernels=Complement[Kernels[],Lookup[Values[jobs],"Kernel",{}]];
 While[tasks=!={}&&freeKernels=!={}&&availableCPUs=!={},
  task=Join[First[tasks],<|"CPU"->First[availableCPUs]|>];tasks=Rest[tasks];availableCPUs=Rest[availableCPUs];
  kernel=First[freeKernels];freeKernels=Rest[freeKernels];
  statusFile=task["OutputDirectory"]<>"/pool_status.json";
  If[FileExistsQ[statusFile],DeleteFile[statusFile]];
  With[{file=workerFile,input=task,target=kernel},
   Parallel`Developer`Send[target,Get[file];FeynFacetValidationWorker`RunFamily[input]]];
  AssociateTo[jobs,task["ID"]-><|"Task"->task,"Kernel"->kernel|>];
  Print["START ",task["ID"]," CPU ",task["CPU"]]];
 writeState[];Pause[1]
];
CloseKernels[];writeState[];Exit[0];
