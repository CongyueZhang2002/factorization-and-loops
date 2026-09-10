(* Union contribution targets before IBP. Source names are local to each input. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=1,Print["Usage: construct_shared_current_differential_system.wls MANIFEST.json"];Exit[2]];
manifestPath=ExpandFileName[First[arguments]];manifest=Import[manifestPath,"RawJSON"];
If[!AssociationQ[manifest],Print["A JSON manifest is required"];Exit[2]];
sources=Lookup[manifest,"Contributions",{}];decompositions=<||>;physics=None;
Do[
 directory=FileNameJoin[Prepend[Lookup[source,{"Project","Order","Channel"}],root<>"/Projects"]];
 contribution=source["Contribution"];card=FeynFacet`ReadContributionCard[directory,contribution];
 If[!AssociationQ[card],Print[card];Exit[1]];
 currentPhysics=KeyTake[card["Assembly"],{"Variables","Scale"}];
 If[physics===None,physics=currentPhysics,
  If[currentPhysics=!=physics,Print["Shared reductions require the same kinematic variables and scale"];Exit[1]]];
 file=directory<>"/Results/"<>StringReplace[contribution,"."->"/"]<>"/IntegralFamilies.wl";
 input=FeynFacet`FamilyArtifactRead[file];
 If[!AssociationQ[input]||Lookup[input,"Format",None]=!="FeynFacet-CurrentIntegralFamilies",
  Print["Missing completed integral families: ",file];Exit[1]];
 If[FeynFacet`RequireMatchingProcessDefinition[input,FeynFacet`ReadProcessCard[directory,contribution]]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
 label=StringRiffle[Append[Lookup[source,{"Project","Order","Channel"}],contribution],"/"];
 KeyValueMap[AssociateTo[decompositions,(label<>"/"<>#1)->#2]&,input["Values"]],
 {source,sources}];
combined=FeynFacet`MergeCutIntegralDecompositions[decompositions];
If[FailureQ[combined],Print[combined];Exit[1]];
Print["Merging exact affine cut-family equivalences before IBP"];
combined=FeynFacet`MergeEquivalentCutIntegralFamilies[combined];
If[FailureQ[combined],Print[combined];Exit[1]];
Print["AFFINE FAMILY REDUCTION ",KeyTake[combined["AffineFamilyEquivalences"],
 {"InputFamilyCount","OutputFamilyCount","InputTargetCount","OutputTargetCount","Seconds"}]];
out=ExpandFileName[FileNameJoin[{DirectoryName[manifestPath],manifest["OutputDirectory"]}]];
work=ExpandFileName[FileNameJoin[{DirectoryName[manifestPath],manifest["WorkingDirectory"]}]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[combined,out<>"/ReductionInput.wl",Compression->Automatic];
Print["SHARED REDUCTION ",Length[decompositions]," scalar sources -> ",Length[combined["Families"]],
 " exact distinct families and ",Length[combined["Targets"]]," targets"];
variables=physics["Variables"];scale=physics["Scale"];
points=Table[Join[Thread[variables->Table[(2+j)/(7+2j+4sample),{j,Length[variables]}]],
 {scale->1,D->(17+2sample)/5}],{sample,0,1}];
request=<|"WorkingDirectory"->work,"Threads"->Lookup[manifest,"Threads",1],
 "PrintTimings"->True,"SeedExtension"->{1,1},"ValidationPoints"->points|>;
{seconds,system}=AbsoluteTiming[FeynFacet`ConstructCutDifferentialSystem[
 combined["Families"],combined["Targets"],variables,request]];
If[FailureQ[system],FeynFacet`FamilyArtifactWrite[system,out<>"/Failure.wl"];Print[system];Exit[1]];
FeynFacet`FamilyArtifactWrite[Join[system,<|"SourceContributions"->sources|>],
 out<>"/DifferentialSystem.wl",Compression->Automatic];
Print["COMPLETED ",out<>"/DifferentialSystem.wl"," SECONDS ",seconds,
 " SPANNING MASTERS ",Length[system["MasterIntegralBasis"]]];
