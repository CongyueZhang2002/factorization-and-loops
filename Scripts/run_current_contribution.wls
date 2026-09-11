Print["FEYNFACET DRIVER ENTERED"];
#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: run_current_contribution.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=FileNameJoin[{root,"Projects",args[[1]],args[[2]],args[[3]]}];
card=FeynFacet`ReadContributionCard[directory,args[[4]]];setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[card]||!AssociationQ[setup]||!KeyExistsQ[setup,"Currents"],Print["Current contribution card required."];Exit[1]];
request=Join[FeynFacet`ProjectAssemblyRequest[card],
 FeynFacet`ProjectResultIdentity[card,setup],<|"EpsilonRange"->card["EpsilonRange"]|>];
{seconds,result}=AbsoluteTiming[Switch[args[[4]],
 "Born",FeynFacet`ConstructBornResult[setup,request],
 "Real",density=FeynFacet`ConstructCurrentRealDensity[setup,request];
  If[AssociationQ[density],FeynFacet`ConstructCurrentRealContribution[density,
   Join[request["EndpointExpansion"],<|"EpsilonRange"->card["EpsilonRange"]|>]],density],
 "Virtual",FeynFacet`ConstructCurrentVirtualContribution[setup,request],
 _,Failure["CurrentContributionUnsupported",<||>]]];
If[!AssociationQ[result],Print[StringTake[ToString[result,InputForm],UpTo[1800]]];Exit[1]];
result=Join[result,<|"ProcessDefinition"->setup,"RenormalizationStage"->"Bare"|>];
path=FileNameJoin[{directory,"Results",If[args[[4]]==="Born",Nothing,args[[4]]],"Result.wl"}];
FeynFacet`FamilyArtifactWrite[result,path];
If[FeynFacet`ReadPartonicResult[path]=!=result,Print["Result read-back failed."];Exit[1]];
Print[<|"Status"->"Completed","Contribution"->args[[4]],"Seconds"->seconds,"ResultFile"->path,"EpsilonRange"->result["EpsilonRange"]|>];
Print["COMPLETED ",path];
