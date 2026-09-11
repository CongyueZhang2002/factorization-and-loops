Print["FEYNFACET DRIVER ENTERED"];

$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: combine_current_components.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contribution];
If[!AssociationQ[card]||!AssociationQ[Lookup[card,"Components",None]],
 Print["A contribution card with named components is required"];Exit[1]];
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
parts=AssociationMap[FeynFacet`FamilyArtifactRead[path<>"/"<>#<>"/Result.wl"]&,Keys[card["Components"]]];
If[!AllTrue[Values[parts],AssociationQ],Print["Completed component results are required"];Exit[1]];
result=FeynFacet`CombinePartonicResults[parts,<|"Contribution"->contribution|>];
If[!AssociationQ[result],Print[result];Exit[1]];
FeynFacet`FamilyArtifactWrite[result,path<>"/Result.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/Result.wl"];
