#!/usr/bin/env wolframscript
(* Read-only audit of saved finite-solution epsilon cutoffs. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,
 Print["Usage: check_solution_epsilon_remainders.wls SOLUTION.wxf|SOLUTION_TREE REPORT.wxf"];Exit[2]];
input=ExpandFileName[args[[1]]];output=ExpandFileName[args[[2]]];
inputs=If[DirectoryQ[input],Sort[FileNames["solution.wxf",input,Infinity]],{input}];
If[inputs==={}||MemberQ[inputs,output]||!AllTrue[inputs,FileExistsQ],
 Print["Readable inputs and a distinct output path are required."];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
reports=Table[
 record=Import[file,"WXF"];
 {elapsed,checked}=AbsoluteTiming[CheckMasterIntegralSolutionEpsilonRemainders[record]];
 If[!AssociationQ[checked],checked=<|"Result"->Failure["FiniteSolutionAssociationRequired",<||>],
   "EpsilonRemainderAudit"-><|"Status"->"CalculationFailed","ChecksByStage"-><||>|>|>];
 checked=Join[checked,<|"InputFile"->file,"AuditWallSeconds"->elapsed|>];
 Print[FileNameTake[DirectoryName[file],-2],": ",checked["EpsilonRemainderAudit"]["Status"]," (",elapsed," s)"];
 checked,{file,inputs}];
status=If[AllTrue[reports,#["EpsilonRemainderAudit"]["Status"]==="Passed"&],"Passed","Failed"];
report=If[Length[reports]===1,First[reports],<|"Status"->status,"SolutionCount"->Length[reports],
 "AuditWallSeconds"->Total[Lookup[reports,"AuditWallSeconds"]],"Reports"->reports|>];
report=Join[report,<|"Created"->DateString["ISODateTime"]|>];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
If[Export[output,report,"WXF"]===$Failed,Exit[2]];
Print[<|"Status"->status,"SolutionCount"->Length[reports],"AuditWallSeconds"->report["AuditWallSeconds"],"Report"->output|>];
If[status=!="Passed",Print[Select[reports,#["EpsilonRemainderAudit"]["Status"]=!="Passed"&]];Exit[1]];
