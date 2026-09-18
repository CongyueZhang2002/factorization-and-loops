Print["FEYNFACET DRIVER ENTERED"];
(* Resume selected jobs from a normalized coefficient checkpoint. This driver
   does not label a partial collection as a completed coefficient result. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=2,Print["Expected TRACE_DIRECTORY REQUEST.wl"];Exit[2]];
directory=ExpandFileName[args[[1]]];request=FeynFacetRecords`ReadRecord[ExpandFileName[args[[2]]]];
checkpoint=FeynFacet`Private`reconstructionTraceRecord[directory];
If[!AssociationQ[checkpoint]||!TrueQ[checkpoint["TraceData"]["CompleteTargetSet"]],
 Print["COMPLETE NORMALIZED SOURCE REQUIRED"];Exit[1]];
data=FeynFacet`Private`finiteFieldCompactTrace[checkpoint["TraceData"],directory,1,10*2^20,30,600];
If[!AssociationQ[data],Print["COMPACTION CHECKPOINT FAILED"];Exit[1]];
If[KeyExistsQ[request,"PartitionManifest"],
 data=FeynFacet`Private`reconstructionPartitionTrace[data,request["PartitionManifest"]];
 If[!AssociationQ[data],Print[data];Exit[1]]];
options=Join[<|"SeriesVariable"->None,"SeriesOrder"->None,"Threads"->Automatic,
 "FactorScan"->True,"ShiftScan"->True,"ProgressInterval"->60,"Resume"->True|>,Lookup[request,"Options",<||>]];
If[FeynFacet`Private`finiteFieldThreadCount[options["Threads"]]===$Failed,
 Print["CPU ALLOCATION INVALID"];Exit[1]];
jobs=FeynFacet`Private`reconstructionScheduleJobs[data,Lookup[request,"BundleBelowBytes",16*2^20],Automatic];
jobs=Map[Join[#,Lookup[Lookup[request,"JobOptions",<||>],#["Name"],<||>]]&,jobs];
selected=Select[jobs,MemberQ[Lookup[request,"Jobs",{}],#["Name"]]&];
If[selected==={}||Sort[Lookup[selected,"Name"]]=!=Sort[request["Jobs"]],Print["JOB SELECTION INVALID"];Exit[1]];
output=ExpandFileName[request["OutputDirectory"]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[<|"Jobs"->jobs,"Options"->options,"TraceData"->data|>,
 output<>"/ScheduleInput_"<>StringRiffle[request["Jobs"],"_"]<>".wl","Compression"->True];
exe=FeynFacet`Private`finiteFieldResolveExecutable[Automatic];
result=Catch[FeynFacet`Private`reconstructionRunSchedule[selected,data,output,exe,options],
 FeynFacet`Private`$reconstructionFailure];
If[!ListQ[result]||Length[result]=!=Length[selected],Print["RECONSTRUCTION JOB FAILED"];Exit[1]];
FeynFacet`FamilyArtifactWrite[result,output<>"/CompletedJobs_"<>StringRiffle[request["Jobs"],"_"]<>".wl","Compression"->True];
Print["RECONSTRUCTION JOBS COMPLETE ",Lookup[result,"Name"]];
