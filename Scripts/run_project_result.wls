#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{1,2},Length[args]],Print["Usage: run_project_result.wls RESULT_CARD [all|resume|assemble|plan]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mode=If[Length[args]===2,args[[2]],"all"];
result=If[mode==="plan",FeynFacet`PlanProjectResult[args[[1]]],FeynFacet`RunProjectResult[args[[1]],mode]];
If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
If[mode=!="plan",
 Export[FileNameJoin[{DirectoryName[args[[1]]],"Timing.json"}],
  KeyTake[result,{"Status","Project","Order","Channel","Seconds","AssemblySeconds","PlanningSeconds","ResultBytes","Mode","PoleCancellation"}],"RawJSON"]];
Print[InputForm[If[mode==="plan",KeyTake[result,{"Coverage","SourceOrders","RawEpsilonRanges"}],KeyDrop[result,{"RawContributions"}]]]];
Print["PROJECT_RESULT_COMPLETED"];
