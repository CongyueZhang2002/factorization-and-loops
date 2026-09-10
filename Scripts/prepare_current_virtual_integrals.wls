
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: prepare_current_virtual_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contribution];setup=FeynFacet`ReadProcessCard[directory,contribution];
If[!AssociationQ[card]||!AssociationQ[setup],Print[{card,setup}];Exit[1]];
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
source=FeynFacet`FamilyArtifactRead[path<>"/Integrands.wl"];
If[FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
average=card["Assembly"]["JointAngularAverage"];
loops=Join[setup["ForwardAmplitudes"]["LoopMomenta"],setup["ConjugateAmplitudes"]["LoopMomenta"]];
{seconds,result}=AbsoluteTiming[FeynFacet`DecomposeVirtualLoopIntegrands[source["Values"],loops,
 average["PhysicalMomenta"],average["KinematicRules"],
 <|"Assumptions"->average["Assumptions"],"FamilyNamePrefix"->StringReplace[contribution,Except[LetterCharacter|DigitCharacter]->""]<>"Family"|>]];
If[!AssociationQ[result],Print[System`Short[result,5]];Exit[1]];
result=Join[result,<|"ProcessDefinition"->setup,"Seconds"->seconds,
 "ScalarIntegralNormalization"->"Product d^D ell/(i pi^(D/2))",
 "IntegrationMeasureConversion"->(I Pi^(D/2))^Length[loops]|>];
FeynFacet`FamilyArtifactWrite[result,path<>"/IntegralFamilies.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/IntegralFamilies.wl"," SECONDS ",seconds,
 " FAMILIES ",Length[result["Families"]]," TARGETS ",Length[result["Targets"]]];
