Print["FEYNFACET DRIVER ENTERED"];
(* One shared queue serves full raw execution and explicit diagram-only runs.
   Usage: regenerate_pairs.wls RAW_CHANNEL CONTRIBUTION [all|resume] [kernels] *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3,4},Length[args]],
 Print["Usage: regenerate_pairs.wls RAW_CHANNEL CONTRIBUTION [all|resume] [kernels]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[ExpandFileName[args[[1]]],args[[2]]];
If[!AssociationQ[card],Print[InputForm[card]];Exit[1]];
mode=If[Length[args]>=3,args[[3]],"resume"];
If[Length[args]===4,
 If[!StringMatchQ[args[[4]],DigitCharacter..],Exit[2]];count=FromDigits[args[[4]]];
 If[!TrueQ[1<=count<=8],Exit[2]];
 card=Join[card,<|"Execution"->Join[card["Execution"],<|"Kernels"->count|>]|>]];
result=FeynFacet`GenerateContributionPairArtifacts[card,mode];
If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
Print["PAIR_ARTIFACTS_COMPLETED ",result["Directory"]];
