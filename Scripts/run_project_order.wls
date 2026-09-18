Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3,4},Length[args]],Print["Usage: run_project_order.wls PROJECT_DIRECTORY ORDER [all|resume|assemble] [UPSTREAM_TIMING.json]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
runtime=If[Length[args]===4,Import[ExpandFileName[args[[4]]],"RawJSON"],<||>];
If[!AssociationQ[runtime],Print["Measured upstream timing record required"];Exit[1]];
result=FeynFacet`RunProjectOrder[ExpandFileName[args[[1]]],args[[2]],
 If[Length[args]>=3,args[[3]],"all"],runtime];
If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
Export[FileNameJoin[{ExpandFileName[args[[1]]],"Results",args[[2]],"Timing.json"}],
 KeyTake[result,{"Status","Project","Order","Mode","Seconds","PlanningSeconds","LocalExecutionSeconds","LocalClock","UpstreamPlanningSeconds","UpstreamSecondsByOwnerChannel","DistinctRawContributions","RawSecondsByOwnerChannel"}],"RawJSON"];
Print["PROJECT_ORDER_COMPLETED ",result["Project"]," ",result["Order"]," CHANNELS ",Length[result["Channels"]]];
