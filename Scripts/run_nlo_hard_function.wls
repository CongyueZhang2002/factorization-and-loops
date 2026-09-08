#!/usr/bin/env wolframscript
(* One campaign card -> generated amplitudes, reductions, analytic masters,
   PDF/FF/UV cards, exact pole cancellation and an explicit Mathematica file. *)
$HistoryLength=0;$MaxExtraPrecision=50;SetSystemOptions["ParallelOptions"->"ParallelThreadNumber"->1];
root=DirectoryName[ExpandFileName[$InputFileName],2];args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3},Length[args]],Print["Usage: run_nlo_hard_function.wls PROJECT CAMPAIGN [all|assemble]"];Exit[2]];
mode=If[Length[args]===3,args[[3]],"all"];If[!MemberQ[{"all","assemble"},mode],Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
project=ExpandFileName[FileNameJoin[{root,args[[1]]}]];campaign=Get[FileNameJoin[{project,"Cards",args[[2]]<>".wl"}]];
If[!AssociationQ[campaign],Print["Campaign card failed"];Exit[1]];
write[value_,path_]:=(If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 Put[value,path<>".tmp"];RenameFile[path<>".tmp",path,OverwriteTarget->True];path);
fail[tag_,data_]:=(Print[tag," ",InputForm[data]];Exit[1]);
checked[value_,tag_]:=If[FailureQ[value]||value===$Failed||value===$Aborted,fail[tag,value],value];
run[script_,arguments_,name_,marker_]:=Module[{elapsed,proc,path},
 {elapsed,proc}=AbsoluteTiming[RunProcess[Join[{"wolframscript","-file",FileNameJoin[{root,"Scripts",script}]},arguments]]];
 path=FileNameJoin[{project,"Results","Validation",args[[2]],name<>".log"}];
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 Export[path,proc["StandardOutput"]<>proc["StandardError"],"Text"];
 If[proc["ExitCode"]=!=0||!StringContainsQ[proc["StandardOutput"],marker],fail[name,<|"ExitCode"->proc["ExitCode"],"Log"->path|>]];
 Print[name," ",Round[elapsed,0.01]," seconds"];elapsed];
started=AbsoluteTime[];timings=<||>;prefix=campaign["Name"];req=campaign["AssemblyRequest"];
baseBorn=Get[FileNameJoin[{project,"Cards",campaign["BornCard"]<>".wl"}]];
ctBase=campaign["CountertermParameters"];
enumeration=checked[FeynFacet`EnumerateNLOCollinearChannels[campaign["Channel"],<|
 "Species"->Keys[campaign["SpeciesMap"]],"IncomingSpins"->campaign["IncomingSpins"],"Schemes"->campaign["Schemes"],
 "SplittingVariable"->ctBase["SplittingVariable"],"KernelParameters"->ctBase["KernelParameters"]|>],"Counterterm channel enumeration"];
bornCards=checked[FeynFacet`ConstructCollinearBornProcessCards[baseBorn,enumeration,campaign["SpeciesMap"]],"Born process closure"];
bornValues=<||>;
KeyValueMap[Function[{id,card},
 write[card,FileNameJoin[{project,"Cards",prefix<>"_"<>id<>".wl"}]];
 {elapsed,value}=AbsoluteTiming[FeynFacet`ConstructBornInvariantDensity[card,<|"Scale"->req["Scale"],
  "MandelstamVariables"->req["MandelstamVariables"],"DimensionalRegulator"->Global`Epsilon|>]];
 checked[value,"Generated counterterm Born density"];AssociateTo[bornValues,id->value];AssociateTo[timings,id->elapsed];
 write[value,FileNameJoin[{project,"Results","Born",prefix<>"_"<>id<>".wl"}]]],bornCards["BornCards"]];
primary=Select[Values[bornValues],#["Setup"]["Partons"]===baseBorn["Partons"]&];
If[Length[primary]=!=1,fail["Unique primary Born channel required",Length[primary]]];primary=First[primary];
contributions=<||>;
Do[
 source=campaign[kind<>"Card"];reduced=campaign["ReducedResults"][kind];
 If[mode==="all",
  card=checked[FeynFacet`CompleteProcessDiagramSelection[Get[FileNameJoin[{project,"Cards",source<>".wl"}]]],"Full amplitude diagram coverage"];
  write[card,FileNameJoin[{project,"Cards",source<>".wl"}]];
  AssociateTo[timings,kind<>"Pairs"->run["regenerate_pairs.wls",{args[[1]],source,source,"7"},kind<>"Pairs","FAILURES: 0"]]];
 pairFiles=Sort[FileNames["F*_C*.wl",FileNameJoin[{project,"Results",source,"Pairs"}]]];
 If[pairFiles==={},fail["Amplitude pairs required",source]];pairs=FeynFacet`FamilyArtifactRead /@ pairFiles;
 zero=FeynFacet`ConstructZeroAmplitudeContribution[pairs,<|"Contribution"->kind,"DimensionalRegulator"->Global`Epsilon,"Variables"->req["Variables"]|>];
 If[AssociationQ[zero],result=zero,
  If[mode==="all",
   AssociateTo[timings,kind<>"Reduction"->run["canonicalize_and_stream.wls",{args[[1]],source,reduced,"solve"},kind<>"Reduction","STREAMDIRECTORY:"]];
   AssociateTo[timings,kind<>"Coefficients"->run["stream_to_coefficients.wls",{args[[1]],reduced,"7","6"},kind<>"Coefficients","COEFFICIENTFILE:"]]];
  table=checked[FeynFacet`ReadMasterIntegralCoefficients[FileNameJoin[{project,"Results",reduced,"CoefficientResult.wl"}]],"Master coefficient input"];
  {elapsed,result}=AbsoluteTiming[If[kind==="Real",FeynFacet`ConstructNLORealContribution[table,req],
   FeynFacet`ConstructNLOVirtualContribution[table,Join[req,<|"KinematicConditions"->campaign["VirtualKinematicConditions"]|>]]]];
  checked[result,kind<>" analytic contribution"];AssociateTo[timings,kind<>"AnalyticAssembly"->elapsed]];
 AssociateTo[contributions,kind->result];
 write[result,FileNameJoin[{project,"Results","Contributions",prefix,kind<>".wl"}]],{kind,{"Real","Virtual"}}];
Do[row=bornCards["Channels"][[i]];leg=row["Leg"];
 id=If[leg==="Observed","FF","PDF"]<>leg<>IntegerString[i,10,2];
 card=Join[ctBase,KeyTake[row,{"Leg","Daughter","Parent","Spin","Scheme","SplittingKernel","FiniteKernel"}],
  <|"Contribution"->If[leg==="Observed","FFCounterterm","PDFCounterterm"],
   "FactorizationScaleSquared"->campaign["FactorizationScalesSquared"][leg],
   "BornFile"->FileNameJoin[{"Results","Born",prefix<>"_"<>row["BornCard"]<>".wl"}]|>];
 write[card,FileNameJoin[{project,"Cards",prefix<>"_"<>id<>".wl"}]];
 value=checked[FeynFacet`ConstructNLOCollinearCounterterm[bornValues[row["BornCard"]],card],"Collinear counterterm"];
 AssociateTo[contributions,id->value];write[value,FileNameJoin[{project,"Results","Contributions",prefix,id<>".wl"}]],{i,Length[bornCards["Channels"]]}];
card=Join[ctBase,<|"Contribution"->"UVCounterterm","BornFile"->FileNameJoin[{"Results","Born",prefix<>"_"<>First[Select[Keys[bornValues],bornValues[#]===primary&]]<>".wl"}]|>];
write[card,FileNameJoin[{project,"Cards",prefix<>"_UV.wl"}]];
value=checked[FeynFacet`ConstructNLOUVCounterterm[primary,card],"UV counterterm"];AssociateTo[contributions,"UV"->value];
write[value,FileNameJoin[{project,"Results","Contributions",prefix,"UV.wl"}]];
{elapsed,hard}=AbsoluteTiming[FeynFacet`AssembleNLOHardFunction[contributions,<|"RequiredContributions"->Keys[contributions],
 "BornDensity"->primary,"Scale"->req["Scale"],"Variables"->req["Variables"],"Assumptions"->campaign["FinalAssumptions"],
 "ColorRules"->campaign["ColorRules"],"Description"->campaign["Description"]|>]];
checked[hard,"Finite hard-function assembly"];AssociateTo[timings,"FinalAssembly"->elapsed];
output=write[hard,FileNameJoin[{project,"Results",campaign["Output"]}]];
report=<|"Status"->"Completed","Mode"->mode,"Seconds"->(AbsoluteTime[]-started),"StageSeconds"->timings,
 "BornChannelCount"->Length[bornValues],"CollinearChannelCount"->Length[bornCards["Channels"]],
 "Contributions"->Keys[contributions],"Output"->output,"OutputBytes"->FileByteCount[output],
 "PoleCancellation"->hard["PoleCancellation"],"ExternalFiniteReferenceValidation"->"Separate validation driver required"|>;
write[report,FileNameJoin[{project,"Results","Validation",args[[2]],"CampaignReport_"<>mode<>".wl"}]];
write[KeyDrop[bornCards,"BornCards"],FileNameJoin[{project,"Results","Validation",args[[2]],"BornChannelClosure.wl"}]];
Print[InputForm[report]];Print["NLO_CAMPAIGN_COMPLETED ",prefix];
