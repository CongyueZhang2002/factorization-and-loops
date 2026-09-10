$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]===4&&Last[args]==="Counterterm",args=Most[args]];
If[Length[args]=!=3,Print["Usage: construct_partonic_counterterm.wls PROJECT ORDER CHANNEL"];Exit[2]];
directory=FileNameJoin[Prepend[args,root<>"/Projects"]];
card=FeynFacet`ReadContributionCard[directory,"Counterterm"];
If[!AssociationQ[card],Print[card];Exit[1]];
{seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ConstructPartonicCounterterm[card]]];
path=directory<>"/Results/Counterterm";
FeynFacet`FamilyArtifactWrite[audit,path<>"/LaurentAudit.wl",Compression->Automatic];
If[!AssociationQ[audit["Result"]]||audit["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print[System`Short[audit,5]];Exit[1]];
result=Join[audit["Result"],<|"Seconds"->seconds|>];
FeynFacet`FamilyArtifactWrite[result,path<>"/Result.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/Result.wl"," SECONDS ",seconds," EPSILON RANGE ",result["EpsilonRange"]];
