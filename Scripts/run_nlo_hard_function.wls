#!/usr/bin/env wolframscript
(* Root card.wl + NLO/channel cards -> explicit common-format LO/NLO results. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3},Length[args]],Print["Usage: run_nlo_hard_function.wls PROJECT CHANNEL [all|resume|assemble]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
channelDirectory=FileNameJoin[{root,"Projects",args[[1]],"NLO",args[[2]]}];
result=FeynFacet`RunNLOProject[channelDirectory,If[Length[args]===3,args[[3]],"all"]];
Print[InputForm[result]];
If[!AssociationQ[result]||Lookup[result,"Status",None]=!="Completed",Exit[1]];
Print["NLO_PROJECT_COMPLETED ",args[[1]]," ",args[[2]]];
