$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=2,Print["Usage: share_master_differential_systems.wls REQUEST OUTPUT_DIRECTORY"];Exit[2]];
requestPath=ExpandFileName[First[arguments]];
request=FeynFacet`FamilyArtifactRead[requestPath];
If[!AssociationQ[request],Print[request];Exit[1]];
paths=Map[ExpandFileName[FileNameJoin[{DirectoryName[requestPath],#}]]&,request["DifferentialSystems"]];
systems=FeynFacet`FamilyArtifactRead/@paths;
If[!AllTrue[Values[systems],AssociationQ],Print["Completed differential systems are required"];Exit[1]];
families=DeleteDuplicates[Flatten[Lookup[Values[systems],"Families"],1]];
masters=DeleteDuplicates[Flatten[Lookup[Values[systems],"MasterIntegralBasis"],1]];
out=ExpandFileName[arguments[[2]]];If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
{equivalenceSeconds,equivalences}=AbsoluteTiming[FeynFacet`FindCutIntegralEquivalences[
 masters,families,"Normalization"->"Complete typed cut definitions and explicit measures"]];
If[FailureQ[equivalences],Print[equivalences];Exit[1]];
FeynFacet`FamilyArtifactWrite[equivalences,out<>"/CutEquivalences.wl",Compression->Automatic];
Print["EXACT EQUIVALENCES ",Length[masters]," -> ",equivalences["EquivalenceClassCount"]];
inputs=KeyValueMap[Join[#2,<|"Family"->#1,"OriginalMasterIntegralBasis"->#2["MasterIntegralBasis"]|>]&,systems];
{seconds,shared}=AbsoluteTiming[FeynFacet`ConstructGlobalMasterDifferentialSystem[
 inputs,equivalences,"ValidationPoints"->request["ValidationPoints"]]];
If[FailureQ[shared],FeynFacet`FamilyArtifactWrite[shared,out<>"/Failure.wl"];Print[shared];Exit[1]];
mapped=Association@KeyValueMap[Function[{name,source},
 embedding=SelectFirst[shared["FamilyMaps"],#["Family"]===name&]["IntegralEmbedding"];
 name->(source["RequestedMasterValues"]/.Dispatch[
  Thread[source["MasterIntegralBasis"]->Normal[embedding].shared["MasterIntegralBasis"]]]/.
  Lookup[source,"DimensionRule",{}])],systems];
shared=Join[shared,<|"SourceDifferentialSystems"->paths,"Families"->families,
 "OriginalMasterIntegralBasis"->shared["MasterIntegralBasis"],"RequestedMasterValues"->mapped|>];
FeynFacet`FamilyArtifactWrite[shared,out<>"/DifferentialSystem.wl",Compression->Automatic];
Print["COMPLETED ",out<>"/DifferentialSystem.wl"," MASTERS ",Length[shared["MasterIntegralBasis"]],
 " SECONDS ",equivalenceSeconds+seconds];
