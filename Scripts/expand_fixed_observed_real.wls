Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: expand_fixed_observed_real.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
request=FeynFacet`ProjectAssemblyRequest[card];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/AngularDensity.wl"];
If[!AssociationQ[source]||!FeynFacet`Private`projectCurrentProjectionMatches[source,FeynFacet`ReadProcessCard[card],request]||
 source["RealPhaseSpace"]=!=card["Assembly"]["RealPhaseSpace"]||
 Lookup[source,"SymmetryFactor",1]=!=Lookup[card,"SymmetryFactor",1]||
 Lookup[source,"FlavorMultiplicity",1]=!=Lookup[card,"FlavorMultiplicity",1],
 Print["Matching exact angular density required"];Exit[1]];
prepared=Association@Table[name->FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/Prepared-"<>name<>".wl"],{name,Keys[source["Values"]]}];
If[!AllTrue[Values[prepared],AssociationQ],Print["Original prepared products required"];Exit[1]];
request=Join[request,KeyTake[card["Assembly"],{"RealPhaseSpace","ScalarIntegration"}],
 <|"Order"->card["Order"],"EpsilonRange"->card["EpsilonRange"],"WorkDirectory"->card["WorkDirectory"]|>];
result=FeynFacet`ConstructFixedObservedRealContribution[source,prepared,request];
If[!AssociationQ[result],Print[System`InputForm[System`Short[result,7]]];Exit[1]];
FeynFacet`FamilyArtifactWrite[result,card["WorkDirectory"]<>"/IntegratedReal.wl",Compression->Automatic];
Print["COMPLETED fixed-observed real endpoint expansion"];
