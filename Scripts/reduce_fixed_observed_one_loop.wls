Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: reduce_fixed_observed_one_loop.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/ScalarIntegrands.wl"];
setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[source]||FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True||
 !TrueQ[Lookup[source,"FullDimensionScalarProducts",False]],Print["Matching full-D scalar integrands required"];Exit[1]];
request=FeynFacet`ProjectAssemblyRequest[card];
If[KeyTake[source,{"CurrentProjectors","SpinCorrelations","InputKinematicRules"}]=!=
 Join[KeyTake[request,{"CurrentProjectors","SpinCorrelations"}],<|"InputKinematicRules"->request["KinematicRules"]|>],
 Print["Matching current and spin projections required"];Exit[1]];
geometry=card["Assembly"]["ScalarIntegration"];
If[source["ScalarIntegration"]=!=geometry,Print["Current scalar integration geometry required"];Exit[1]];
point=Lookup[geometry,"KinematicPoint",{}];
external=DeleteCases[geometry["PhysicalMomenta"],Lookup[geometry,"NormalMomentum",None]];
kinematics=<|"ExternalMomenta"->external,"KinematicRules"->Select[geometry["KinematicRules"],
 FreeQ[#,Lookup[geometry,"NormalMomentum",None]]&],"Assumptions"->geometry["Assumptions"],
 "DimensionalRegulator"->Global`Epsilon|>/.point;
loops=Join[setup["ForwardAmplitudes"]["LoopMomenta"],setup["ConjugateAmplitudes"]["LoopMomenta"]];
If[Length[loops]=!=1,Print["Exactly one loop required"];Exit[1]];
result=FeynFacet`ReduceOneLoopIntegrands[source["Values"],kinematics,
 <|"LoopMomentum"->First[loops],"PrintTimings"->True,"FactorInput"->False,"TimeLimit"->600|>];
If[!AssociationQ[result],Print[result];Exit[1]];
result=Join[result,KeyTake[source,{"CurrentProjectors","SpinCorrelations","InputKinematicRules"}],
 <|"ProcessDefinition"->setup,"ScalarIntegration"->geometry|>];
output=card["WorkDirectory"]<>"/TensorReducedIntegrands.wl";
FeynFacet`FamilyArtifactWrite[result,output,Compression->Automatic];
Print["COMPLETED ",output];
