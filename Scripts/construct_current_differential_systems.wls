Print["FEYNFACET DRIVER ENTERED"];
(* One DE reduction is shared between all scalar structures of a component. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: construct_current_differential_systems.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
If[!AssociationQ[card],Print[card];Exit[1]];
componentPath=card["ContributionPath"];
outputDirectory=directory<>"/Results/"<>componentPath;
input=FeynFacet`FamilyArtifactRead[outputDirectory<>"/IntegralFamilies.wl"];
If[!AssociationQ[input]||Lookup[input,"Format",None]=!="FeynFacet-CurrentIntegralFamilies",
 Print["Prepared integral families are required"];Exit[1]];
combined=FeynFacet`MergeCutIntegralDecompositions[input["Values"]];
If[!AssociationQ[combined],Print[combined];Exit[1]];
Print["SHARED REDUCTION: ",Length[combined["Families"]]," families; ",Length[combined["Targets"]]," targets"];
FeynFacet`FamilyArtifactWrite[combined,outputDirectory<>"/ReductionInput.wl",Compression->Automatic];
parameters=card["Assembly"]["Variables"];scale=card["Assembly"]["Scale"];
validationPoints=Table[Join[Thread[parameters->Table[(2+j)/(7+2j+4sample),{j,Length[parameters]}]],
 {scale->1,D->(17+2sample)/5}],{sample,0,1}];
request=<|"WorkingDirectory"->directory<>"/Kira/"<>componentPath<>"/DifferentialSystem",
 "Threads"->Lookup[card["Execution"],"KiraThreads",1],"PrintTimings"->True,
 "SeedExtension"->{1,1},"ValidationPoints"->validationPoints|>;
{seconds,system}=AbsoluteTiming[FeynFacet`ConstructCutDifferentialSystem[
 combined["Families"],combined["Targets"],parameters,request]];
If[!AssociationQ[system],Print[system];Exit[1]];
FeynFacet`FamilyArtifactWrite[system,outputDirectory<>"/DifferentialSystem.wl",Compression->Automatic];
Print["COMPLETED ",outputDirectory<>"/DifferentialSystem.wl"," SECONDS ",seconds,
 " SPANNING MASTERS ",Length[system["MasterIntegralBasis"]]];
Exit[0];
