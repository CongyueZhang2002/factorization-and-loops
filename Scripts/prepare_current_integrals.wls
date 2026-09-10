(* Source-product prescription proof and scalar preparation, driven by cards. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[!MemberQ[{4,5},Length[arguments]],Print["Usage: prepare_current_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT [all|prepare|decompose|finish]"];Exit[2]];
{projectName,orderName,channelName,contributionName}=Take[arguments,4];
mode=If[Length[arguments]===5,Last[arguments],"all"];
If[!MemberQ[{"all","prepare","decompose","finish"},mode],Print["Invalid preparation mode"];Exit[2]];
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
setup=FeynFacet`ReadProcessCard[directory,contributionName];
If[!AssociationQ[card]||!AssociationQ[setup],Print[{card,setup}];Exit[1]];
geometry=Lookup[card["Assembly"],"MeasuredPhaseSpace",None];
average=Lookup[card["Assembly"],"JointAngularAverage",None];
If[!AssociationQ[geometry]||!AssociationQ[average],Print["MeasuredPhaseSpace and JointAngularAverage are required"];Exit[1]];
definition=FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[geometry,<|
 "Name"->MeasuredSource,"FinalMomenta"->Last[setup["PartonMomentum"]],
 "TotalMomentum"->Total[First[setup["PartonMomentum"]]],
 "ExternalMomenta"->average["PhysicalMomenta"],"KinematicRules"->average["KinematicRules"],
 "TaggedMomentum"->First[Last[setup["PartonMomentum"]]],"Assumptions"->average["Assumptions"]|>]];
If[!AssociationQ[definition],Print[definition];Exit[1]];
outputDirectory=directory<>"/Results/"<>StringReplace[contributionName,"."->"/"];
source=FeynFacet`FamilyArtifactRead[outputDirectory<>"/Integrands.wl"];
If[!AssociationQ[source]||Lookup[source,"Format",None]=!="FeynFacet-CurrentIntegrands",
 Print["Generated scalar current integrands are required"];Exit[1]];
If[FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
prepared=<||>;decomposed=<||>;timings=<||>;decompositionTimings=<||>;
coreText=Environment["FACET_CPU_COUNT"];
coefficientWorkers=If[StringQ[coreText]&&StringMatchQ[coreText,DigitCharacter..],
 Min[8,Max[1,FromDigits[coreText]]],1];

If[MemberQ[{"decompose","finish"},mode],
 result=FeynFacet`FamilyArtifactRead[outputDirectory<>"/PreparedIntegrands.wl"];
 If[!AssociationQ[result]||Lookup[result,"Format",None]=!="FeynFacet-PreparedCurrentIntegrands"||
   Sort[Keys[result["Values"]]]=!=Sort[Keys[source["Values"]]],
  Print["Complete prepared scalar structures are required"];Exit[1]];
 If[FeynFacet`RequireMatchingProcessDefinition[result,setup]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
 prepared=result["Values"],
 Do[
  Print["Preparing measured integral products for ",structure];
  {seconds,value}=AbsoluteTiming[FeynFacet`PrepareMeasuredCutIntegrand[source["Values"][structure],definition,
   Join[KeyTake[geometry,{"ExternalKinematicConditions"}],<|"PrintTimings"->True|>]]];
  If[!AssociationQ[value],Print[value];Exit[1]];
  AssociateTo[prepared,structure->value];AssociateTo[timings,structure->seconds];
  Print["PREPARED ",structure," SECONDS ",seconds," DENOMINATORS ",
   Length[value["OrdinaryInversePropagators"]]," TERMS ",Length[value["Terms"]]],
 {structure,Keys[source["Values"]]}];
 result=<|"Format"->"FeynFacet-PreparedCurrentIntegrands","FormatVersion"->1,
  "Values"->prepared,"ProcessDefinition"->source["ProcessDefinition"],"PreparationSeconds"->timings,
  "PhaseSpaceAndFluxIncluded"->False|>;
 FeynFacet`FamilyArtifactWrite[result,outputDirectory<>"/PreparedIntegrands.wl",Compression->Automatic]
];
If[mode==="prepare",Print["COMPLETED ",outputDirectory<>"/PreparedIntegrands.wl"];Exit[0]];
Do[
 Print["Constructing independent integral families for ",structure];
 checkpointFile=outputDirectory<>"/Structure"<>ToString[First[FirstPosition[Keys[source["Values"]],structure]]]<>
  ".CoefficientCheckpoint.wxf";
 If[mode==="finish"&&FileExistsQ[checkpointFile],
  checkpoint=If[FileExistsQ[checkpointFile],Import[checkpointFile,"WXF"],$Failed];
  If[!AssociationQ[checkpoint]||checkpoint["SourceProcessDefinition"]=!=source["ProcessDefinition"],
   Print["A matching coefficient checkpoint is required"];Exit[1]];
  {decompositionSeconds,integrals}=AbsoluteTiming[FeynFacet`SimplifyMeasuredIntegralDecomposition[
   checkpoint["Data"],<|"CoefficientWorkers"->coefficientWorkers|>]],
 {decompositionSeconds,integrals}=AbsoluteTiming[FeynFacet`DecomposeMeasuredCutIntegrand[prepared[structure],
  Join[KeyTake[geometry,{"ExternalKinematicConditions"}],
   <|"PrintTimings"->True,"CoefficientWorkers"->coefficientWorkers,
     "CoefficientCheckpointFunction"->Function[data,Export[checkpointFile,
      <|"SourceProcessDefinition"->source["ProcessDefinition"],"Data"->data|>,"WXF"]],"FamilyNamePrefix"->StringReplace[contributionName,Except[LetterCharacter|DigitCharacter]->""]<>
    "Structure"<>ToString[First[FirstPosition[Keys[source["Values"]],structure]]]<>"Family"|>]]]];
 If[!AssociationQ[integrals],Print[integrals];Exit[1]];
 AssociateTo[decomposed,structure->integrals];AssociateTo[decompositionTimings,structure->decompositionSeconds];
 Print["DECOMPOSED ",structure," SECONDS ",decompositionSeconds,
  " FAMILIES ",Length[integrals["Families"]]," TARGETS ",Length[integrals["Targets"]]],
 {structure,Keys[source["Values"]]}];
FeynFacet`FamilyArtifactWrite[<|"Format"->"FeynFacet-CurrentIntegralFamilies","FormatVersion"->1,
 "Values"->decomposed,"ProcessDefinition"->source["ProcessDefinition"],
 "DecompositionSeconds"->decompositionTimings|>,outputDirectory<>"/IntegralFamilies.wl",Compression->Automatic];
Scan[If[FileExistsQ[#],DeleteFile[#]]&,FileNames["Structure*.CoefficientCheckpoint.wxf",outputDirectory]];
Print["COMPLETED ",outputDirectory<>"/IntegralFamilies.wl"];
Exit[0];
