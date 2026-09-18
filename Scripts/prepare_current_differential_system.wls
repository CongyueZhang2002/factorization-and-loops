Print["FEYNFACET DRIVER ENTERED"];
(* Prepare a generated measured-cut connection for the shared finite solver. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,
 Print["Usage: prepare_current_differential_system.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
directory=root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
If[!AssociationQ[card],Print[card];Exit[1]];
outputDirectory=card["WorkDirectory"]<>
 If[StringContainsQ[contributionName,"."],"","/MasterIntegrals"];
input=FeynFacet`FamilyArtifactRead[outputDirectory<>"/DifferentialSystem.wl"];
If[!AssociationQ[input]||!MemberQ[{"CutMasterDifferentialSystem","GlobalMasterDifferentialSystem"},Lookup[input,"DataType",None]],
 Print["A completed typed-cut differential system is required"];Exit[1]];
system=input;
{seconds,preparation}=AbsoluteTiming[
 FeynFacet`PrepareDifferentialSystemForFiniteIntegration[system,"Verbose"->True,
  "IntermediateOutputDirectory"->outputDirectory<>"/HomogeneousBlocks"]];
FeynFacet`FamilyArtifactWrite[<|"Preparation"->preparation,"Seconds"->seconds,
 "SourceDifferentialSystem"->outputDirectory<>"/DifferentialSystem.wl",
 "DimensionRule"->Lookup[input,"DimensionRule",None]|>,outputDirectory<>"/FiniteIntegrationPreparation.wl"];
If[!AssociationQ[preparation],
 Print[If[FailureQ[preparation],Failure[First[preparation],KeyDrop[Last[preparation],{"EpsilonRescaling"}]],preparation]];
 Exit[1]];
Print["COMPLETED ",outputDirectory<>"/FiniteIntegrationPreparation.wl"," SECONDS ",seconds];
