Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: reduce_current_one_loop_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
source=FeynFacet`FamilyArtifactRead[path<>"/Integrands.wl"];
If[!AssociationQ[source],Print["Generated current integrands required"];Exit[1]];
If[FeynFacet`RequireMatchingProcessDefinition[source,FeynFacet`ReadProcessCard[card]]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
setup=source["ProcessDefinition"];
If[setup["ForwardAmplitudes"]["LoopOrder"]=!=1||setup["ConjugateAmplitudes"]["LoopOrder"]=!=0,
 Print["One-loop times tree integrands required"];Exit[1]];
geometry=FeynFacet`ConstructTwoParticleMeasurement[Join[card["Assembly"]["TwoParticleMeasurement"],
 <|"DimensionalRegulator"->Global`Epsilon|>]];
If[!AssociationQ[geometry],Print[geometry];Exit[1]];
result=FeynFacet`ReduceMeasuredOneLoopIntegrands[source["Values"],geometry,
 <|"LoopMomentum"->First[setup["ForwardAmplitudes"]["LoopMomenta"]],"PrintTimings"->True|>];
If[!AssociationQ[result],Print[result];Exit[1]];
FeynFacet`FamilyArtifactWrite[Join[result,<|"ProcessDefinition"->setup|>],
 path<>"/TensorReducedIntegrands.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/TensorReducedIntegrands.wl"];
