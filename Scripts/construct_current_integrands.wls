Print["FEYNFACET DRIVER ENTERED"];
(* Card-driven generated current integrands; numerical/reference data are not inputs. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: construct_current_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT"];Exit[2]];
{projectName,orderName,channelName,contributionName}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contributionName];
setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[card]||!AssociationQ[setup],Print[{card,setup}];Exit[1]];
request=FeynFacet`ProjectAssemblyRequest[card];
If[!AssociationQ[request],Print[request];Exit[1]];
(* This geometry is read from the project/contribution card, not inferred
   from selected families. *)
If[!KeyExistsQ[card["Assembly"],"JointAngularAverage"],Print["JointAngularAverage is required in the card"];Exit[1]];
request=Join[request,<|"AngularAverage"->card["Assembly"]["JointAngularAverage"],"PrintTimings"->True,"KernelCount"->card["Execution"]["Kernels"]|>];
{elapsedSeconds,result}=AbsoluteTiming[FeynFacet`ConstructCurrentIntegrands[setup,request]];
If[!AssociationQ[result],Print[result];Exit[1]];
output=directory<>"/Results/"<>StringReplace[contributionName,"."->"/"]<>"/Integrands.wl";
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
FeynFacet`FamilyArtifactWrite[result,output,Compression->Automatic];
Print["COMPLETED ",output," SECONDS ",elapsedSeconds," BYTES ",FileByteCount[output]];
Exit[0];
