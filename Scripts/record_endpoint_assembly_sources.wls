$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=1,Print["Usage: record_endpoint_assembly_sources.wls PLAN.wl"];Exit[2]];
file=ExpandFileName[First[args]];
plan=FeynFacet`FamilyArtifactRead[file];outputs={};
Do[
 dir=output["ChannelDirectory"];contribution=output["Contribution"];
 card=FeynFacet`ReadContributionCard[dir,contribution];
 components=Lookup[card,"Components",<||>];names=If[components===<||>,{contribution},Keys[components]];
 sources=<||>;
 Do[
  selected=If[components===<||>,contribution,contribution<>"."<>name];
  setup=FeynFacet`ReadProcessCard[dir,selected];
  prepared=FeynFacet`FamilyArtifactRead[dir<>"/Results/"<>StringReplace[selected,"."->"/"]<>"/PreparedIntegrands.wl"];
  If[!AssociationQ[prepared]||FeynFacet`RequireMatchingProcessDefinition[prepared,setup]=!=True,
   Print["CURRENT PREPARED SOURCE REQUIRED ",dir," ",selected];Exit[1]];
  AssociateTo[sources,name->prepared["ProcessDefinition"]],
 {name,names}];
 AppendTo[outputs,Join[output,<|"AssemblyCard"->card,"SourceProcessDefinitions"->sources|>]],
{output,plan["Outputs"]}];
plan["Outputs"]=outputs;FeynFacet`FamilyArtifactWrite[plan,file,"Compression"->True];
Print["COMPLETED ENDPOINT SOURCE IDENTITIES ",Length[outputs]];
