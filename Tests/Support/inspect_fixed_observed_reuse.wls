Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/NLO/q-q","Real.SameFlavor"];
request=FeynFacet`ProjectAssemblyRequest[card];setup=FeynFacet`ReadProcessCard[card];
sourceDirectory=card["WorkDirectory"];
a=FeynFacet`FamilyArtifactRead[sourceDirectory<>"/Integrands.wl"];b=FeynFacet`FamilyArtifactRead[sourceDirectory<>"/ScalarIntegrands.wl"];
Print["CHECK NEW SOURCE ",FeynFacet`Private`projectCurrentProjectionMatches[a,setup,request]];
Print["MATCH CONDITIONS ",{FeynFacet`RequireMatchingProcessDefinition[a,setup],a["CurrentProjectors"]===request["CurrentProjectors"],a["SpinCorrelations"]===request["SpinCorrelations"],a["InputKinematicRules"]===request["KinematicRules"],a["InputColorRules"]===Lookup[request,"ColorRules",{}]}];
Print["SPIN REQUEST ",InputForm[request["SpinCorrelations"]]];Print["SPIN SOURCE ",InputForm[a["SpinCorrelations"]]];
Print["SORTED SPIN EQUAL ",FeynFacet`Private`projectIdentityValue[request["SpinCorrelations"]]===FeynFacet`Private`projectIdentityValue[a["SpinCorrelations"]]];

Print["CHECK OLD SCALAR ",FeynFacet`Private`projectCurrentProjectionMatches[b,setup,request]];
Do[Print["FIELD ",k," EQUAL ",a[k]===b[k]," BYTES ",{ByteCount[a[k]],ByteCount[b[k]]}];
 If[a[k]=!=b[k],Print["DIFFERENCE ",k," ",StringTake[ToString[{a[k],b[k]},InputForm],UpTo[8000]]]],
 {k,{"CurrentProjectors","SpinCorrelations","InputKinematicRules","InputColorRules"}}];
Print["PROCESS DIFFERENT KEYS ",Select[Union[Keys[a["ProcessDefinition"]],Keys[b["ProcessDefinition"]]],a["ProcessDefinition"][#]=!=b["ProcessDefinition"][#]&]];
Do[If[a["ProcessDefinition"][k]=!=b["ProcessDefinition"][k],Print["PROCESS ",k," ",StringTake[ToString[{a["ProcessDefinition"][k],b["ProcessDefinition"][k]},InputForm],UpTo[3000]]]],{k,Keys[a["ProcessDefinition"]]}];
Print["GEOMETRY ",b["ScalarIntegration"]===card["Assembly"]["ScalarIntegration"]];
Print["COMPLETED fixed observed reuse inspection"];
