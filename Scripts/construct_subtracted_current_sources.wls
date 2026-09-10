$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: construct_subtracted_current_sources.wls PROJECT ORDER CHANNEL OUTPUT"];Exit[2]];
{project,order,channel}=Take[args,3];output=ExpandFileName[args[[4]]];
card=FeynFacet`ReadContributionCard[FileNameJoin[{root,"Projects",project,order,channel}],"Counterterm"];
If[!AssociationQ[card],Print[card];Exit[1]];
{seconds,result}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ConstructSubtractedPartonicSourceCatalog[card]]];
FeynFacet`FamilyArtifactWrite[result,output,Compression->Automatic];
If[!AssociationQ[result]||!AssociationQ[result["Result"]],
 Print["FAILED ",If[AssociationQ[result],First[result["Result"]],Head[result]]];Exit[1]];
If[result["EpsilonRemainderAudit"]["Status"]=!="Passed",Print["FAILED EPSILON AUDIT"];Exit[1]];
Print["COMPLETED ",output," SECONDS ",seconds," SOURCE COUNTS ",Length/@result["Result"]["Sources"]];
