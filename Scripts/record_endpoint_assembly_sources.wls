Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=1,Print["Usage: record_endpoint_assembly_sources.wls PLAN.wl"];Exit[2]];
file=ExpandFileName[First[args]];
plan=FeynFacet`FamilyArtifactRead[file];outputs={};
resolve[path_String]:=If[StringStartsQ[path,$PathnameSeparator],ExpandFileName[path],
 ExpandFileName[FileNameJoin[{DirectoryName[file],path}]]];
generatedFiles=Lookup[plan,{"BulkCoefficientsFile","EndpointProfilesFile","ProjectionConditionsFile"},None];
If[AnyTrue[plan["Outputs"],!KeyExistsQ[#,"AssemblyCard"]||!KeyExistsQ[#,"SourceProcessDefinitions"]&]&&
 AnyTrue[Select[generatedFiles,StringQ],FileExistsQ[resolve[#]]&],
 Print["Record the original integration definitions before producing solved coefficient files; existing data cannot be retrospectively assigned the current normalization."];Exit[1]];
Do[
 dir=ExpandFileName[FileNameJoin[{DirectoryName[file],output["ChannelDirectory"]}]];contribution=output["Contribution"];
 card=FeynFacet`ReadContributionCard[dir,contribution];
 components=Lookup[card,"Components",<||>];names=If[components===<||>,{contribution},Keys[components]];
 sources=<||>;
 Do[
  selected=If[components===<||>,contribution,contribution<>"."<>name];
  setup=FeynFacet`ReadProcessCard[dir,selected];
  selectedCard=FeynFacet`ReadContributionCard[dir,selected];
  If[!AssociationQ[selectedCard],Print[selectedCard];Exit[1]];
  prepared=FeynFacet`FamilyArtifactRead[selectedCard["WorkDirectory"]<>"/PreparedIntegrands.wl"];
  If[!AssociationQ[prepared]||FeynFacet`RequireMatchingProcessDefinition[prepared,setup]=!=True,
   Print["CURRENT PREPARED SOURCE REQUIRED ",dir," ",selected];Exit[1]];
  AssociateTo[sources,name->prepared["ProcessDefinition"]],
 {name,names}];
 If[KeyExistsQ[output,"AssemblyCard"]&&KeyExistsQ[output,"SourceProcessDefinitions"],
  recorded=FeynFacet`Private`projectRecordedIntegrationDefinition[output["AssemblyCard"],output["SourceProcessDefinitions"]];
  current=FeynFacet`Private`projectRecordedIntegrationDefinition[card,sources];
  If[FeynFacet`Private`projectIdentityValue[recorded]=!=FeynFacet`Private`projectIdentityValue[current],
   Print["The retained original integration definition differs from the current source. Regenerate the affected calculation."];Exit[1]];
  AppendTo[outputs,output],
  AppendTo[outputs,Join[output,<|"AssemblyCard"->card,"SourceProcessDefinitions"->sources|>]]],
{output,plan["Outputs"]}];
plan["Outputs"]=outputs;FeynFacet`FamilyArtifactWrite[plan,file,"Compression"->True];
Print["COMPLETED ENDPOINT SOURCE IDENTITIES ",Length[outputs]];
