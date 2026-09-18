Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: simplify_current_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contributionName];
If[!AssociationQ[card],Print[card];Exit[1]];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/Integrands.wl"];
If[!AssociationQ[source]||FeynFacet`RequireMatchingProcessDefinition[source,FeynFacet`ReadProcessCard[card]]=!=True,
 Print["Matching generated current integrands required"];Exit[1]];
request=FeynFacet`ProjectAssemblyRequest[card];
If[!FeynFacet`Private`projectCurrentProjectionMatches[source,FeynFacet`ReadProcessCard[card],request],
 Print["Matching current, spin, kinematic and color projections required"];Exit[1]];
geometry=Lookup[card["Assembly"],"ScalarIntegration",None];
If[!AssociationQ[geometry],Print["Declared ScalarIntegration geometry required"];Exit[1]];
candidateFile=card["WorkDirectory"]<>"/ScalarIntegrands.wl";
If[FileExistsQ[candidateFile],candidate=FeynFacet`FamilyArtifactRead[candidateFile];
 If[AssociationQ[candidate]&&TrueQ[Lookup[candidate,"FullDimensionScalarProducts",False]]&&
   FeynFacet`Private`projectCurrentProjectionMatches[candidate,source["ProcessDefinition"],request]&&
   KeyDrop[Lookup[candidate,"ScalarIntegration",<||>],"NormalMomentum"]===KeyDrop[geometry,"NormalMomentum"],
  source=candidate;Print["Reusing completed full-D numerator projection"]]];
result=FeynFacet`SimplifyCurrentScalarIntegrands[source,geometry,If[card["Contribution"]==="Real",Lookup[card["Assembly"],"RealPhaseSpace",None],None],<|"CheckpointDirectory"->card["WorkDirectory"]<>"/NumeratorProjection"|>];
If[!AssociationQ[result],Print[result];Exit[1]];
output=card["WorkDirectory"]<>"/ScalarIntegrands.wl";
FeynFacet`FamilyArtifactWrite[result,output,Compression->Automatic];
Print["COMPLETED ",output];
