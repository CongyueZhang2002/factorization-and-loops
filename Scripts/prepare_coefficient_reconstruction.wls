Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[!MemberQ[{3,4},Length[args]],Print["Expected TRACE_DIRECTORY REQUEST.wl OUTPUT.wl or TRACE_DIRECTORY CHANNEL_DIRECTORY CONTRIBUTION OUTPUT.wl"];Exit[2]];
request=If[Length[args]===4,
 FeynFacet`Private`coefficientProjectReconstructionInputs[ExpandFileName[args[[2]]],args[[3]]],
 FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]]];

If[!AssociationQ[request],Print["PLANNING REQUEST REQUIRED"];Exit[2]];
{seconds,result}=AbsoluteTiming[FeynFacet`PrepareCoefficientReconstructionPlan[args[[1]],request]];
If[!AssociationQ[result],Print["COEFFICIENT PLAN FAILED ",result];Exit[1]];
FeynFacet`Private`coefficientPlanWrite[result,ExpandFileName[Last[args]]];
Print["COEFFICIENT RECONSTRUCTION PLAN COMPLETE ",seconds," seconds; ",result["DiscoveryReport"]];
