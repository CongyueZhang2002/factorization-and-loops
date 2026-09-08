BeginPackage["FeynFacetValidationWorker`"];
RunFamily::usage="Short uneven-duration jobs for the scheduler test.";
Begin["`Private`"];
RunFamily[task_Association]:=Module[{record,file=task["OutputDirectory"]<>"/pool_status.json"},
 RunProcess[{"taskset","-apc",ToString[task["CPU"]],ToString[$ProcessID]}];
 record=<|"Family"->task["ID"],"KernelID"->$KernelID,"WorkerPID"->$ProcessID,
  "Started"->AbsoluteTime[],"Finished"->False,"Status"->"Running"|>;
 Export[file<>".tmp",record,"RawJSON"];RenameFile[file<>".tmp",file,OverwriteTarget->True];
 Pause[task["Duration"]];record["Finished"]=True;record["FinishedAt"]=AbsoluteTime[];
 record["Status"]="Compared";
 Export[file<>".tmp",record,"RawJSON"];RenameFile[file<>".tmp",file,OverwriteTarget->True];record
];
End[];EndPackage[];
