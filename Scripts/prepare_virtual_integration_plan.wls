Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: prepare_virtual_integration_plan.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
directory=FileNameJoin[{root,"Projects",args[[1]],"Raw",args[[2]],args[[3]]}];
card=FeynFacet`ReadContributionCard[directory,args[[4]]];
If[!AssociationQ[card],Print[card];Exit[1]];
names=Keys[Lookup[card,"Components",<||>]];
If[names==={},names={args[[4]]}];
sources=<||>;files=<||>;
Do[
 selected=If[KeyExistsQ[card,"Components"],args[[4]]<>"."<>name,args[[4]]];
 component=FeynFacet`ReadContributionCard[directory,selected];
 setup=FeynFacet`ReadProcessCard[component];path=component["WorkDirectory"];
 input=FeynFacet`FamilyArtifactRead[path<>"/IntegralFamilies.wl"];
 reduction=FeynFacet`FamilyArtifactRead[path<>"/Reduction.wl"];
 If[!AssociationQ[input]||!AssociationQ[reduction]||
   FeynFacet`RequireMatchingProcessDefinition[input,setup]=!=True,
  Print["Current reduced virtual source required: ",selected];Exit[1]];
 AssociateTo[sources,name->input["ProcessDefinition"]];
 AssociateTo[files,selected-><|"IntegralFamiliesFile"->path<>"/IntegralFamilies.wl",
  "ReductionFile"->path<>"/Reduction.wl"|>],
 {name,names}];
plan=FeynFacet`CreateContributionIntegrationPlan[card,card,sources,
 <|"Method"->"VirtualMasterLibrary","Components"->files|>];
If[!AssociationQ[plan],Print[plan];Exit[1]];
FeynFacet`FamilyArtifactWrite[plan,card["WorkDirectory"]<>"/IntegrationPlan.wl"];
Print["COMPLETED VIRTUAL INTEGRATION PLAN ",card["WorkDirectory"]];
