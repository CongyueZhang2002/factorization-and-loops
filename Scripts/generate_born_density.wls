#!/usr/bin/env wolframscript
(* Generate one declared LO channel in the same format consumed at higher orders. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: generate_born_density.wls PROJECT CHANNEL"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=FileNameJoin[{root,"Projects",args[[1]],"LO",args[[2]]}];
card=FeynFacet`ReadContributionCard[directory,"Born"];
setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[card]||!AssociationQ[setup],Print["Declared Born channel required."];Exit[1]];
request=Join[FeynFacet`ProjectAssemblyRequest[card],
 FeynFacet`ProjectResultIdentity[card,setup],
 <|"EpsilonRange"->card["EpsilonRange"],"BornCouplingPower"->card["BornCouplingPower"]|>];
{seconds,result}=AbsoluteTiming[FeynFacet`ConstructBornResult[setup,request]];
If[!AssociationQ[result]||FailureQ[result],Print[StringTake[ToString[result,InputForm],UpTo[2000]]];Exit[1]];
path=FileNameJoin[{directory,"Results","Result.wl"}];
FeynFacet`Private`projectWrite[result,path];
Print[<|"Status"->"BornResultGenerated","Seconds"->seconds,"Output"->path|>];
Print["BORN_RESULT_COMPLETED"];
