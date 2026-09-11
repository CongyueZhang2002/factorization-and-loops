Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=2,Print["Usage: combine_partonic_contributions.wls PROJECT ORDER"];Exit[2]];
{projectName,order}=args;project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>projectName];
If[!AssociationQ[project],Print["Project card required"];Exit[1]];
Do[
 directory=project["Directory"]<>"/"<>order<>"/"<>channel;
 names=FileBaseName/@FileNames["*.wl",directory<>"/Cards"];
 If[names==={},Print["No contribution cards ",channel];Exit[1]];
 parts=AssociationMap[FeynFacet`ReadPartonicResult[directory<>"/Results/"<>#<>"/Result.wl"]&,names];
 If[!AllTrue[Values[parts],AssociationQ],Print["Incomplete contributions ",channel," ",Keys[Select[parts,FailureQ]]];Exit[1]];
 {sec,out}=AbsoluteTiming[FeynFacet`CombinePartonicResults[parts,<|"Contribution"->"Total","RequiredContributions"->names,
  "Schemes"->project["Counterterms"]["Schemes"],"PoleCancellationVerified"->False|>]];
 If[!AssociationQ[out],
  Print["COMBINATION FAILED ",channel," ",InputForm[out]];
  Print["IDENTITIES ",KeyTake[#,{"Order","Project","Channel","PhysicalChannel","Polarization","Coupling","CouplingPower","StructureFunctions"}]&/@parts];
  Print["CONVENTIONS ",KeyTake[#,{"Scale","Variables","DimensionalRegulator","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization","LaurentLowerBound","EpsilonRange"}]&/@parts];Exit[1]];
 FeynFacet`FamilyArtifactWrite[out,directory<>"/Results/CombinedLaurentResult.wl",Compression->Automatic];
 Print["COMBINED ",projectName,"/",channel," ",sec," s"],
{channel,project["Orders"][order]}];
Print["COMPLETED ALL PARTONIC CONTRIBUTION SUMS"];
