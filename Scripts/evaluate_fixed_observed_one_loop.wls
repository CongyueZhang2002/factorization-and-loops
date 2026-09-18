Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: evaluate_fixed_observed_one_loop.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/TensorReducedIntegrands.wl"];
setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[source]||FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True||
 source["ScalarIntegration"]=!=card["Assembly"]["ScalarIntegration"],Print["Matching tensor reduction required"];Exit[1]];
request=Join[FeynFacet`ProjectAssemblyRequest[card],FeynFacet`ProjectResultIdentity[card,setup],
 <|"Order"->orderName,"EpsilonRange"->card["EpsilonRange"],
 "CouplingNormalization"->card["Counterterms"]["CouplingNormalization"]|>];
If[KeyTake[source,{"CurrentProjectors","SpinCorrelations","InputKinematicRules"}]=!=
 Join[KeyTake[request,{"CurrentProjectors","SpinCorrelations"}],<|"InputKinematicRules"->request["KinematicRules"]|>],
 Print["Matching current and spin projections required"];Exit[1]];
{seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ConstructFixedObservedVirtualContribution[source,request]]];
FeynFacet`FamilyArtifactWrite[audit,card["WorkDirectory"]<>"/LaurentAudit.wl"];
If[!AssociationQ[audit]||!AssociationQ[audit["Result"]]||audit["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print[InputForm[System`Short[audit,4]]];Exit[1]];
FeynFacet`FamilyArtifactWrite[audit["Result"],card["ResultFile"]];
Print["COMPLETED ",card["ResultFile"]," SECONDS ",seconds];
