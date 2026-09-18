#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{1,2},Length[args]],Print["Usage: run_raw_contribution.wls RAW_CARD [all|resume]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
path=FeynFacet`Private`projectAbsolutePath[args[[1]]];
If[FileNameTake[path]=!="Card.wl",Print["Concrete Card.wl required"];Exit[2]];
owner=FeynFacet`Private`projectAbsolutePath[DirectoryName[path]];
card=FeynFacet`ReadContributionCard[DirectoryName[owner],FileNameTake[owner]];
If[!AssociationQ[card],Print[card];Exit[1]];
result=FeynFacet`RunRawContribution[card,If[Length[args]===2,args[[2]],"all"]];
If[!AssociationQ[result],Print[result];Exit[1]];
Print[KeyTake[result,{"Status","Seconds","File"}]];Print["RAW_CONTRIBUTION_COMPLETED"];
