Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=1,Print["Usage: assemble_endpoint_profiles.wls PLAN.wl"];Exit[2]];
planFile=ExpandFileName[First[args]];plan=FeynFacet`FamilyArtifactRead[planFile];
resolve[file_]:=If[StringStartsQ[file,$PathnameSeparator],ExpandFileName[file],ExpandFileName[FileNameJoin[{DirectoryName[planFile],file}]]];
bulk=FeynFacet`FamilyArtifactRead[resolve[plan["BulkCoefficientsFile"]]];
profiles=FeynFacet`FamilyArtifactRead[resolve[plan["EndpointProfilesFile"]]];
proof=FeynFacet`FamilyArtifactRead[resolve[plan["ProjectionConditionsFile"]]];
If[!AllTrue[{bulk,profiles,proof},AssociationQ],Print["Explicit bulk, face profiles and projection proof are required"];Exit[1]];
report=<||>;
Do[
 directory=resolve[output["ChannelDirectory"]];contribution=output["Contribution"];
 card=FeynFacet`ReadContributionCard[directory,contribution];project=FeynFacet`ReadProjectCard[directory];
 If[!AssociationQ[card]||!AssociationQ[project],Print["Current contribution card required ",directory," ",InputForm[card]," ",InputForm[project]];Exit[1]];
 channel=card["Channel"];order=card["Order"];
 components=Lookup[card,"Components",<||>];
 setups=If[components===<||>,<|contribution->FeynFacet`ReadProcessCard[card]|>,
 AssociationMap[FeynFacet`ReadProcessCard[directory,contribution<>"."<>#]&,Keys[components]]];
 If[!AllTrue[Values[setups],AssociationQ],Print["Current process definitions required"];Exit[1]];
 sourceDefinitions=Lookup[output,"SourceProcessDefinitions",<||>];
 If[!AssociationQ[sourceDefinitions]||Sort[Keys[sourceDefinitions]]=!=Sort[Keys[setups]]||
  !And@@KeyValueMap[FeynFacet`RequireMatchingProcessDefinition[
    <|"ProcessDefinition"->sourceDefinitions[#1]|>,#2]===True&,setups]||
  Lookup[output,"AssemblyCard",None]=!=card,
  Print["Solved endpoint inputs do not match the current contribution card ",directory];Exit[1]];
 input=FeynFacet`CreateEndpointIntegrationInput[output["AssemblyCard"],sourceDefinitions,bulk,profiles,proof,
  <|"SourceRowLabels"->output["SourceRowLabels"],"BulkCoordinates"->"Endpoint","BulkToEndpointRules"->{}|>];
 If[!AssociationQ[input],Print["INPUT BINDING FAILED ",input];Exit[1]];
 inputFile=card["WorkDirectory"]<>"/IntegrationInput.wxf";FeynFacet`FamilyArtifactWrite[input,inputFile];
 integrationPlan=FeynFacet`CreateContributionIntegrationPlan[card,output["AssemblyCard"],sourceDefinitions,
  <|"Method"->"EndpointProfiles","IntegrationInputFile"->inputFile|>];
 If[!AssociationQ[integrationPlan],Print["CURRENT INPUT BINDING FAILED ",integrationPlan];Exit[1]];
 FeynFacet`FamilyArtifactWrite[integrationPlan,card["WorkDirectory"]<>"/IntegrationPlan.wl"];
 {sec,result}=AbsoluteTiming[FeynFacet`RunRawContribution[card,"all"]];
 If[!AssociationQ[result],Print["ASSEMBLY FAILED ",result];Exit[1]];
 AssociateTo[report,directory-><|"Seconds"->sec,"Status"->"Passed"|>];
 FeynFacet`FamilyArtifactWrite[report,resolve[plan["ReportFile"]]];
 Print["COMPLETED ENDPOINT RESULT ",project["Project"],"/",order,"/",channel," ",sec," s"],
{output,plan["Outputs"]}];
Print["COMPLETED ALL ENDPOINT PROFILE OUTPUTS ",Length[report]];
