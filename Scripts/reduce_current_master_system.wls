(* Share exact powered-integral identities across all declared components. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,
 Print["Usage: reduce_current_master_system.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
If[!AssociationQ[card]||!AssociationQ[Lookup[card,"Components",None]],
 Print["A contribution with explicit components is required"];Exit[1]];
components=Keys[card["Components"]];
paths=AssociationMap[directory<>"/Results/"<>contributionName<>"/"<>#<>"/DifferentialSystem.wl"&,components];
systems=FeynFacet`FamilyArtifactRead/@paths;
If[!AllTrue[Values[systems],AssociationQ[#]&&Lookup[#,"DataType",None]==="CutMasterDifferentialSystem"&],
 Print["Every component must have a completed differential system"];Exit[1]];
families=DeleteDuplicates[Flatten[Lookup[Values[systems],"Families"],1]];
masters=DeleteDuplicates[Flatten[Lookup[Values[systems],"MasterIntegralBasis"],1]];
output=directory<>"/Results/"<>contributionName<>"/MasterIntegrals";
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
{equivalenceSeconds,equivalences}=AbsoluteTiming[
 FeynFacet`FindCutIntegralEquivalences[masters,families,"Normalization"->"Explicit typed phase-space definitions"]];
If[!AssociationQ[equivalences],Print[equivalences];Exit[1]];
FeynFacet`FamilyArtifactWrite[equivalences,output<>"/CutEquivalences.wl"];
Print["EXACT INTEGRAL EQUIVALENCES ",Length[masters]," -> ",equivalences["EquivalenceClassCount"]];
inputs=KeyValueMap[Join[#2,<|"Family"->#1,"OriginalMasterIntegralBasis"->#2["MasterIntegralBasis"]|>]&,systems];
variables=First[inputs]["KinematicVariables"];regulator=First[inputs]["DimensionalRegulator"];
scale=card["Assembly"]["Scale"];
points=Table[Join[Thread[variables->Table[1/Prime[7k+j+3],{j,Length[variables]}]],
 {regulator->1/Prime[7k+Length[variables]+4],scale->1}],{k,2}];
{reductionSeconds,shared}=AbsoluteTiming[
 FeynFacet`ConstructGlobalMasterDifferentialSystem[inputs,equivalences,"ValidationPoints"->points]];
If[!AssociationQ[shared],
 FeynFacet`FamilyArtifactWrite[shared,output<>"/DifferentialSystemFailure.wl"];Print[shared];Exit[1]];
requests=Association@KeyValueMap[Function[{name,source},
 embedding=SelectFirst[shared["FamilyMaps"],#["Family"]===name&]["IntegralEmbedding"];
 name->(source["RequestedMasterValues"]/.
   Dispatch[Thread[source["MasterIntegralBasis"]->(Normal[embedding].shared["MasterIntegralBasis"])]]/.
   source["DimensionRule"])],systems];
shared=Join[shared,<|"OriginalMasterIntegralBasis"->shared["MasterIntegralBasis"],
 "SourceDifferentialSystems"->paths,"Families"->families,"RequestedMasterValues"->requests,
 "EquivalenceSeconds"->equivalenceSeconds,"ReductionSeconds"->reductionSeconds|>];
FeynFacet`FamilyArtifactWrite[shared,output<>"/DifferentialSystem.wl"];
Print["COMPLETED ",output<>"/DifferentialSystem.wl"," SPANNING MASTERS ",shared["GlobalSpanningMasterCount"],
 " SECONDS ",equivalenceSeconds+reductionSeconds];
