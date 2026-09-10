#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],2];$HistoryLength=0;$MaxExtraPrecision=50;SetSystemOptions["ParallelOptions"->"ParallelThreadNumber"->1];
args=Rest[$ScriptCommandLine];If[Length[args]<2,Print["Usage: generate_nlo_counterterm.wls PROJECT CARD [CARD ...]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
project=ExpandFileName[FileNameJoin[{root,First[args]}]];
runCard[name_String]:=Module[{card,path,born,seconds,result,output},
 card=Get[FileNameJoin[{project,"Cards",name<>".wl"}]];
 If[!AssociationQ[card]||!StringQ[Lookup[card,"BornFile",None]],Print["Counterterm card failed: ",name];Exit[1]];
 path=ExpandFileName[FileNameJoin[{project,card["BornFile"]}]];born=Get[path];
 {seconds,result}=AbsoluteTiming[Switch[Lookup[card,"Contribution",None],
  "PDFCounterterm"|"FFCounterterm",FeynFacet`ConstructNLOCollinearCounterterm[born,card],
  "UVCounterterm",FeynFacet`ConstructNLOUVCounterterm[born,card],_,Failure["CountertermKindUnsupported",<||>]]];
 If[FailureQ[result]||!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 output=FileNameJoin[{project,"Results","Counterterms",name<>".wl"}];
 FeynFacet`FamilyArtifactWrite[result,output];Print[<|"Status"->"CountertermConstructed","Card"->name,"Seconds"->seconds,"Output"->output|>]
];
Scan[runCard,Rest[args]];Print["COUNTERTERMS_COMPLETED ",Length[args]-1];
