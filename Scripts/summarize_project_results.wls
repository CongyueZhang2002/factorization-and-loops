Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],2];
args=Rest[$ScriptCommandLine];
If[Length[args]<1,Print["Usage: summarize_project_results.wls OUTPUT.json [ORDER ...]"];Exit[2]];
output=ExpandFileName[First[args]];orders=If[Length[args]>1,Rest[args],{"NLO","NNLO"}];
If[!AllTrue[orders,MemberQ[{"LO","NLO","NNLO"},#]&],Print["Explicit perturbative orders required"];Exit[2]];
rows={};projects={};nonnegative[x_]:=NumberQ[x]&&TrueQ[x>=0];
Do[
 orderDirectory=DirectoryName[projectTimingFile];
 {project,order}=FileNameSplit[orderDirectory][[{-3,-1}]];
 If[!MemberQ[orders,order],Continue[]];
 projectTiming=Import[projectTimingFile,"RawJSON"];
 If[!AssociationQ[projectTiming]||Lookup[projectTiming,"Status",None]=!="Completed",Continue[]];
 elapsedKey=If[Lookup[projectTiming,"TimingKind",None]==="AccumulatedStageExecution",
   "MeasuredExecutionSeconds","WallSeconds"];
 If[!TrueQ[Lookup[projectTiming,"Fresh",False]]||
    !nonnegative[Lookup[projectTiming,elapsedKey,None]],
  Print["Missing fresh project elapsed time: ",projectTimingFile];Exit[1]];
 projectRows={};
 Do[
  directory=DirectoryName[file];channel=FileNameTake[directory];
  resultFile=FileNameJoin[{directory,"Results.wl"}];timingFile=FileNameJoin[{directory,"Timing.json"}];
  If[!AllTrue[{resultFile,resultFile<>".meta.wxf",timingFile},FileExistsQ],
   Print["Incomplete completed channel: ",directory];Exit[1]];
  timing=Import[timingFile,"RawJSON"];
  If[!AssociationQ[timing]||!AllTrue[
    Lookup[timing,{"RawSeconds","AssemblySeconds"},None],nonnegative],
   Print["Invalid owned-raw plus assembly timing: ",timingFile];Exit[1]];
  totalSeconds=timing["RawSeconds"]+timing["AssemblySeconds"];
  reliable=TrueQ[Lookup[timing,"ChannelTimingReliable",True]];
  row=<|"Project"->project,"Order"->order,"Channel"->channel,"Status"->"Completed",
   "RawSeconds"->If[reliable,timing["RawSeconds"],Null],"AssemblySeconds"->If[reliable,timing["AssemblySeconds"],Null],
   "UpstreamSeconds"->Lookup[timing,"UpstreamSeconds",0],
   "TotalSeconds"->If[reliable,totalSeconds,Null],"TotalMinutes"->If[reliable,totalSeconds/60,Null],
   "LocalClock"->Lookup[timing,"LocalClock",Null],"ChannelTimingReliable"->reliable,
   "TimingIssue"->Lookup[timing,"TimingIssue",Null],
   "ResultBytes"->Total[FileByteCount/@{resultFile,resultFile<>".meta.wxf"}],
   "PoleCancellation"->Lookup[timing,"PoleCancellation",Null],
   "TimingFile"->timingFile|>;
  AppendTo[rows,row];AppendTo[projectRows,row],
 {file,FileNames["*/Result_Card.wl",orderDirectory]}];
 If[projectRows==={},Print["Completed project contains no result channels: ",orderDirectory];Exit[1]];
 rawOwners=Lookup[projectTiming,"RawSecondsByOwnerChannel",<||>];
 auxiliary=KeyDrop[rawOwners,Lookup[projectRows,"Channel"]];
 AppendTo[projects,<|"Project"->project,"Order"->order,"Channels"->Length[projectRows],
  "WallSeconds"->Lookup[projectTiming,"WallSeconds",Null],
  "WallMinutes"->If[elapsedKey==="WallSeconds",projectTiming[elapsedKey]/60,Null],
  "MeasuredExecutionSeconds"->Lookup[projectTiming,"MeasuredExecutionSeconds",Null],
  "MeasuredExecutionMinutes"->If[elapsedKey==="MeasuredExecutionSeconds",projectTiming[elapsedKey]/60,Null],
  "SuccessfulExecutionSeconds"->Lookup[projectTiming,"SuccessfulExecutionSeconds",Null],
  "FailedAttemptSeconds"->Lookup[projectTiming,"FailedAttemptSeconds",0],
  "DiscardedAttemptSeconds"->Lookup[projectTiming,"DiscardedAttemptSeconds",0],
  "TimingKind"->Lookup[projectTiming,"TimingKind","UninterruptedElapsedTime"],
  "CpuSet"->Lookup[projectTiming,"CpuSet",{}],"WallClock"->"PythonMonotonic","Fresh"->True,
  "AuxiliaryRawSecondsByOwnerChannel"->auxiliary,
  "TimingFile"->projectTimingFile|>],
 {projectTimingFile,FileNames["*/Results/*/Timing.json",root<>"/Projects"]}];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
Export[output,<|
 "TimeDefinition"->"Channel time is its recorded owned raw computation (including fresh upstream stages) plus final assembly. Project elapsed time additionally includes auxiliary source channels, shared planning, every kernel startup and cleanup. Verification is separate.",
 "TimeUnit"->"min","SizeUnit"->"decimal kB, including .meta.wxf","SignificantDigits"->2,
 "Rows"->rows,"Projects"->projects|>,"RawJSON"];
Print["PROJECT_RESULT_TIMINGS ",Length[rows]," ",output];
