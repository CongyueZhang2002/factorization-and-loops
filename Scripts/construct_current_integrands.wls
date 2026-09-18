Print["FEYNFACET DRIVER ENTERED"];
(* Card-driven generated current integrands; numerical/reference data are not inputs. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: construct_current_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
directory=root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[card]||!AssociationQ[setup],Print[{card,setup}];Exit[1]];
request=FeynFacet`ProjectAssemblyRequest[card];
If[!AssociationQ[request],Print[request];Exit[1]];
(* Averaging is an explicit integration operation. A fixed physical tagged
   momentum is not integrated by this amplitude-generation driver. *)
request=Join[request,<|"PrintTimings"->True,"KernelCount"->card["Execution"]["Kernels"]|>,
 If[KeyExistsQ[card["Assembly"],"JointAngularAverage"],
  <|"AngularAverage"->card["Assembly"]["JointAngularAverage"]|>,<||>]];
{elapsedSeconds,result}=FeynFacet`Private`facetElapsedTiming[FeynFacet`ConstructCurrentIntegrands[setup,request]];
If[!AssociationQ[result],Print[result];Exit[1]];
output=card["WorkDirectory"]<>"/Integrands.wl";
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[result,output,Compression->Automatic];
Print["COMPLETED ",output," SECONDS ",elapsedSeconds," BYTES ",FileByteCount[output]];
Exit[0];
