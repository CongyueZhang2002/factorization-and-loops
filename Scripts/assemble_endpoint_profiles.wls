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
 setups=If[components===<||>,<|contribution->FeynFacet`ReadProcessCard[directory,contribution]|>,
 AssociationMap[FeynFacet`ReadProcessCard[directory,contribution<>"."<>#]&,Keys[components]]];
 If[!AllTrue[Values[setups],AssociationQ],Print["Current process definitions required"];Exit[1]];
 sourceDefinitions=Lookup[output,"SourceProcessDefinitions",<||>];
 If[!AssociationQ[sourceDefinitions]||Sort[Keys[sourceDefinitions]]=!=Sort[Keys[setups]]||
  !And@@KeyValueMap[FeynFacet`RequireMatchingProcessDefinition[
    <|"ProcessDefinition"->sourceDefinitions[#1]|>,#2]===True&,setups]||
  Lookup[output,"AssemblyCard",None]=!=card,
  Print["Solved endpoint inputs do not match the current contribution card ",directory];Exit[1]];
 labels=output["SourceRowLabels"];
 indices=Map[Function[label,First@FirstPosition[profiles["CoefficientRowLabels"],label]],labels];
 oneBulk=FeynFacet`SelectLaurentCoefficientVector[bulk,indices];
 groups=Map[Function[group,<|"Powers"->group["Powers"],"FaceSeries"->
  Map[FeynFacet`SelectLaurentCoefficientVector[#,indices]&,group["FaceSeries"]]|>],profiles["ProfileGroups"]];
 oneProfiles=Join[profiles,<|"CoefficientRowLabels"->project["StructureFunctions"],"ProfileGroups"->groups|>];
 If[Length[labels]=!=Length[project["StructureFunctions"]],Print["Structure-function row count mismatch"];Exit[1]];
 request=FeynFacet`Private`projectAssemblyRequest[card,channel,contribution];
 axes=request["DistributionBasis"]["Axes"];
 request["DistributionBasis"]=<|"Axes"->MapThread[Append[#1,"NormalVariable"->#2]&,{axes,profiles["NormalVariables"]}]|>;
 meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornSupportKinematicRules","BornMomentumRules",
 "BornConstraints","TwoParticleMeasurement","BareCouplingRules"}],
 FeynFacet`Private`projectResultIdentity[project,channel,setups],
 <|"Order"->order,"Contribution"->contribution,"CouplingPower"->project["BornCouplingPower"]+Switch[order,"LO",0,"NLO",1,"NNLO",2],
 "EpsilonRange"->card["EpsilonRange"],"TestFunctionSupport"->request["EndpointExpansion"]["TestFunctionSupport"],
 "AssemblyPlan"->planFile,"SourceRowLabels"->labels|>];
 {sec,result}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
  FeynFacet`CreatePartonicResultFromProfileCoefficients[oneBulk,oneProfiles,meta,proof]]];
 path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
 FeynFacet`FamilyArtifactWrite[result,path<>"/EndpointAssemblyAudit.wl",Compression->Automatic];
 If[!AssociationQ[result["Result"]]||result["EpsilonRemainderAudit"]["Status"]=!="Passed",
  Print["ASSEMBLY FAILED ",channel," ",StringTake[ToString[result,InputForm],UpTo[3000]]];Exit[1]];
 FeynFacet`FamilyArtifactWrite[result["Result"],path<>"/Result.wl",Compression->Automatic];
 AssociateTo[report,directory-><|"Seconds"->sec,"Status"->"Passed"|>];
 FeynFacet`FamilyArtifactWrite[report,resolve[plan["ReportFile"]]];
 Print["COMPLETED ENDPOINT RESULT ",project["Project"],"/",order,"/",channel," ",sec," s"],
{output,plan["Outputs"]}];
Print["COMPLETED ALL ENDPOINT PROFILE OUTPUTS ",Length[report]];
