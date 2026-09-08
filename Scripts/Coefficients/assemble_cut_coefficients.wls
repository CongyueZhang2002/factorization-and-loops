#!/usr/bin/env wolframscript
(* General weighted assembly of retained coefficient files and exact maps. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Addon/Load/LoadFACET.wl"];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Expected ASSEMBLY_REQUEST.wl"];Exit[2]];
request=Get[ExpandFileName[First[args]]];
read[file_]:=If[ToLowerCase[FileExtension[file]]==="wxf",Import[file,"WXF"],Get[file]];
rules=If[KeyExistsQ[request,"MasterIntegralRulesFile"],read[request["MasterIntegralRulesFile"]],
 Lookup[request,"MasterIntegralRules",{}]];
If[AssociationQ[rules],rules=rules["Rules"]];
elapsed=First[AbsoluteTiming[
 result=FeynFacet`AssembleCutContributions[request["CoefficientFiles"],
  "MasterIntegralRules"->rules,
  Sequence@@Normal[KeyTake[request,{"Weights","AdditionalFactor","TargetTopologies"}]]]]];
If[FailureQ[result],Print[result];Exit[1]];
file=ExpandFileName[request["OutputFile"]];
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
temporary=file<>".tmp";stream=OpenWrite[temporary,BinaryFormat->True];
BinaryWrite[stream,Normal[BinarySerialize[result,PerformanceGoal->"Size"]],"Byte"];
Close[stream];
If[Import[temporary,"WXF"]=!=result,Print["Coefficient serialization read-back failed"];Exit[1]];
RenameFile[temporary,file,OverwriteTarget->True];
summary=<|"Status"->result["Status"],"MasterCount"->Length[result["Masters"]],
 "TermCount"->Total[Length[#["Terms"]]&/@result["Masters"]],
 "LaurentTermCount"->Count[Flatten[Lookup[result["Masters"],"Terms"],1],t_Association/;t["Representation"]==="LaurentSeries"],
 "RemainderTermCount"->Length[result["RemainderTerms"]],
 "ContributionWeights"->Lookup[result["Contributions"],"Weight"],
 "ElapsedSeconds"->elapsed,"OutputFile"->file,"OutputBytes"->FileByteCount[file]|>;
Export[file<>".json",summary,"RawJSON"];Print[summary];Exit[0];
