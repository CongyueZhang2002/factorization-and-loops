#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;SetSystemOptions["ParallelOptions"->"ParallelThreadNumber"->1];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: generate_born_density.wls PROJECT CARD OUTPUT_NAME"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
project=ExpandFileName[FileNameJoin[{root,args[[1]]}]];
card=Get[FileNameJoin[{project,"Cards",args[[2]]<>".wl"}]];
If[!AssociationQ[card],Print["Born card failed"];Exit[1]];
request=Lookup[card,"BornDensity",<|"Scale"->Global`s,"MandelstamVariables"->{Global`s,Global`t,Global`u},"DimensionalRegulator"->Global`Epsilon|>];
{seconds,result}=AbsoluteTiming[FeynFacet`ConstructBornInvariantDensity[card,request]];
If[!AssociationQ[result]||FailureQ[result],Print[InputForm[result]];Exit[1]];
path=FileNameJoin[{project,"Results",args[[3]]<>".wl"}];
If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
Put[result,path<>".tmp"];RenameFile[path<>".tmp",path,OverwriteTarget->True];
Print[<|"Status"->"BornDensityGenerated","PairCount"->Length[result["Pairs"]],"Seconds"->seconds,"Output"->path|>];
Print[InputForm[result["Coefficient"]]];
