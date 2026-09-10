$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: reduce_current_virtual_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
card=FeynFacet`ReadContributionCard[directory,contribution];
source=FeynFacet`FamilyArtifactRead[path<>"/IntegralFamilies.wl"];
If[!AssociationQ[source]||source["Format"]=!="FeynFacet-VirtualIntegralFamilies",Print["Virtual integral decomposition required"];Exit[1]];
If[FeynFacet`RequireMatchingProcessDefinition[source,FeynFacet`ReadProcessCard[directory,contribution]]=!=True,
 Print["Generated virtual inputs do not match the current card"];Exit[1]];
definition=Lookup[card["Assembly"],"ScalarIntegralLibrary",None];
If[!AssociationQ[definition]||definition["Name"]=!="MasslessTwoLoopVertex",Print["Declare a supported scalar integral library"];Exit[1]];
library=FeynFacet`MasslessVertexMasterLibrary[source["LoopMomenta"],definition["NullMomenta"],
 source["ExternalMomenta"],source["KinematicRules"],definition["ScaleSquared"],Global`Epsilon];
result=None;reuse=Lookup[card,"ReductionSource",None];
candidateFiles=If[StringQ[reuse],{ExpandFileName[FileNameJoin[{directory,reuse}]]},{path<>"/Reduction.wl"}];
Do[
 If[!FileExistsQ[file],Continue[]];
 donor=FeynFacet`FamilyArtifactRead[file];If[!AssociationQ[donor],Continue[]];
 candidate=FeynFacet`ReuseIntegralReduction[source["Families"],source["Targets"],donor];
 If[!AssociationQ[candidate],Continue[]];
 matching=FeynFacet`MatchVirtualMastersToLibrary[candidate["Masters"],candidate["Families"],library];
 If[AssociationQ[matching]&&matching["Status"]==="AllMastersMatched",result=candidate;Break[]],
{file,candidateFiles}];
{seconds,result}=If[AssociationQ[result],{0,result},AbsoluteTiming[
 FeynFacet`ReduceToVirtualMasterLibrary[source["Families"],source["Targets"],library,<|
 "WorkingDirectory"->directory<>"/Kira/"<>StringReplace[contribution,"."->"/"],
 "Threads"->Min[2,Lookup[card["Execution"],"Cores",2]],"NewWorkspaceForChangedInputs"->True|>]]];
If[!AssociationQ[result],Print[System`Short[result,5]];Exit[1]];
FeynFacet`FamilyArtifactWrite[result,path<>"/Reduction.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/Reduction.wl"," SECONDS ",seconds," MASTERS ",Length[result["Masters"]]];
