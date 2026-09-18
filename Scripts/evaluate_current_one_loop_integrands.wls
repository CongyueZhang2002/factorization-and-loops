Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: evaluate_current_one_loop_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
path=card["WorkDirectory"];
source=FeynFacet`FamilyArtifactRead[path<>"/TensorReducedIntegrands.wl"];
If[!AssociationQ[source]||!KeyExistsQ[source,"InteriorValues"],
 Print["Completed measured one-loop reduction required"];Exit[1]];
If[FeynFacet`RequireMatchingProcessDefinition[source,FeynFacet`ReadProcessCard[card]]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
If[Lookup[source,"IntegrationDefinition",None]=!=FeynFacet`ContributionIntegrationDefinition[card],
 Print["The saved measured reduction must retain the current integration definition"];Exit[1]];
e=source["DimensionalRegulator"];geometry=source["Measurement"];
conditions=geometry["Assumptions"]&&card["Assembly"]["Assumptions"];
values=FeynFacet`NormalizeMeasuredCurrentScalarValues[source,
 Join[card["Assembly"],KeyTake[card,{"SymmetryFactor","FlavorMultiplicity","ColorRules"}]]];
If[!AssociationQ[values],Print[values];Exit[1]];
{seconds,result}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ExpandOneLoopScalarFunctions[values,e,card["EpsilonRange"],conditions]]];
FeynFacet`FamilyArtifactWrite[result,path<>"/InteriorLaurentAudit.wl",Compression->Automatic];
If[!AssociationQ[result["Result"]]||result["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print[ToString[System`Short[result,4],InputForm]];Exit[1]];
result=Join[result["Result"],<|"ProcessDefinition"->source["ProcessDefinition"],
 "IntegrationDefinition"->source["IntegrationDefinition"],
 "PhysicalTwoParticleMeasureIncluded"->True,"CurrentNormalizationIncluded"->True,
 "CouplingRules"->card["Assembly"]["BareCouplingRules"],"Seconds"->seconds|>];
FeynFacet`FamilyArtifactWrite[result,path<>"/InteriorLaurentCoefficients.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/InteriorLaurentCoefficients.wl"," SECONDS ",seconds,
 " SCALAR UPPER ORDERS ",result["ScalarIntegralUpperOrders"]];
