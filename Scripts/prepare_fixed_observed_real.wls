Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: prepare_fixed_observed_real.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
source=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/ScalarIntegrands.wl"];
setup=FeynFacet`ReadProcessCard[card];request=FeynFacet`ProjectAssemblyRequest[card];
If[!AssociationQ[source]||!FeynFacet`Private`projectCurrentProjectionMatches[source,setup,request]||
 !TrueQ[Lookup[source,"FullDimensionScalarProducts",False]]||
 Lookup[source,"ScalarIntegration",None]=!=card["Assembly"]["ScalarIntegration"],
 Print["Matching fixed-observed full-D real integrands required"];Exit[1]];
geometry=Lookup[card["Assembly"],"RealPhaseSpace",None];
If[!AssociationQ[geometry],Print["Declared unobserved real phase space required"];Exit[1]];
definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|"Name"->fixedObservedRecoil|>]];
If[!AssociationQ[definition],Print[definition];Exit[1]];
cpuText=Environment["FACET_CPU_COUNT"];workerCount=If[StringQ[cpuText]&&StringMatchQ[cpuText,DigitCharacter..],Min[4,FromDigits[cpuText]],1];
outputs=<||>;timings=<||>;
Do[
 Print["PREPARING ",name];
 {seconds,prepared}=FeynFacet`Private`facetElapsedTiming[FeynFacet`PrepareCutIntegrand[source["Values"][name],definition,
  <|"ExternalKinematicConditions"->geometry["Assumptions"],"CancelDenominators"->False|>]];
 If[!AssociationQ[prepared],Print[prepared];Exit[1]];
 FeynFacet`FamilyArtifactWrite[prepared,card["WorkDirectory"]<>"/Prepared-"<>name<>".wl",Compression->Automatic];
 Print["PREPARED ",name," PRODUCTS ",Length[prepared["Terms"]]," SECONDS ",seconds];
 AssociateTo[timings,name<>"Preparation"->seconds];
 {seconds,decomposition}=FeynFacet`Private`facetElapsedTiming[FeynFacet`DecomposeMeasuredCutIntegrand[prepared,<|
  "ExternalKinematicConditions"->geometry["Assumptions"],"Assumptions"->geometry["Assumptions"],
  "AuxiliaryScalarProducts"->Lookup[geometry,"AuxiliaryScalarProducts",{}],
  "FamilyNamePrefix"->name,"CoefficientWorkers"->workerCount,"PrintTimings"->True|>]];
 If[!AssociationQ[decomposition],Print[decomposition];Exit[1]];
 FeynFacet`FamilyArtifactWrite[decomposition,card["WorkDirectory"]<>"/Decomposed-"<>name<>".wl",Compression->Automatic];
 AssociateTo[timings,name<>"Decomposition"->seconds];AssociateTo[outputs,name->decomposition],
 {name,Keys[source["Values"]]}];
result=FeynFacet`MergeCutIntegralDecompositions[outputs];
If[!AssociationQ[result],Print[result];Exit[1]];
result=Join[result,KeyTake[source,{"ProcessDefinition","CurrentProjectors","SpinCorrelations","InputKinematicRules","InputColorRules","ScalarIntegration"}],
 <|"RealPhaseSpace"->geometry,"StageSeconds"->timings|>];
FeynFacet`FamilyArtifactWrite[result,card["WorkDirectory"]<>"/IntegralDecomposition.wl",Compression->Automatic];
Print["COMPLETED fixed-observed real decomposition: ",Length[result["Families"]]," families, ",Length[result["Targets"]]," targets"];
