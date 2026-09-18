Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: evaluate_fixed_observed_angular.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/IntegralDecomposition.wl"];
setup=FeynFacet`ReadProcessCard[card];request=FeynFacet`ProjectAssemblyRequest[card];
If[!AssociationQ[source]||!FeynFacet`Private`projectCurrentProjectionMatches[source,setup,request]||
 source["RealPhaseSpace"]=!=card["Assembly"]["RealPhaseSpace"],
 Print["Matching fixed-observed integral decomposition required"];Exit[1]];
request=Join[request,KeyTake[card,{"SymmetryFactor","FlavorMultiplicity"}],<|"PrintTimings"->True,"IntegralEvaluationFile"->card["WorkDirectory"]<>"/AngularIntegrals.wl"|>];
{seconds,result}=FeynFacet`Private`facetElapsedTiming[FeynFacet`EvaluateTwoBodyIntegralCombination[source,request]];
If[!AssociationQ[result],Print[System`InputForm[System`Short[result,7]]];Exit[1]];
result=Join[result,KeyTake[source,{"ProcessDefinition","CurrentProjectors","SpinCorrelations","InputKinematicRules","InputColorRules","ScalarIntegration","RealPhaseSpace"}],
 <|"IntegrationSeconds"->seconds,"SymmetryFactor"->Lookup[request,"SymmetryFactor",1],
 "FlavorMultiplicity"->Lookup[request,"FlavorMultiplicity",1]|>];
FeynFacet`FamilyArtifactWrite[result,card["WorkDirectory"]<>"/AngularDensity.wl",Compression->Automatic];
Print["COMPLETED angular integration SECONDS ",seconds];
