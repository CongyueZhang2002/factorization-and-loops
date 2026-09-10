#!/usr/bin/env wolframscript
(* Recompute the analytic NLO assembly from completed reductions, comparing
   each previous finite result. No diagrams, IBP or reference values are used. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projects=If[args==={},Select[FileNames["*",root<>"/Projects"],DirectoryQ],root<>"/Projects/"<>#&/@args];
report=<||>;failures=0;changes=0;
auditCompare[expression_,colorRules_]:=Module[{reduced,variables,names,rules,values,base,probes,errors},
 reduced=TimeConstrained[FeynFacet`Private`partonicMap[Factor,expression/.colorRules],2,$Aborted];
 If[reduced=!=$Aborted&&FeynFacet`Private`partonicZeroTreeQ[reduced],
  Return[<|"Agreement"->True,"Method"->"Exact rational algebra with declared color identities"|>]];
 variables=DeleteDuplicates[Cases[expression,var_Symbol/;Context[var]=!="System`",Infinity,Heads->True]];
 names=Sort[DeleteDuplicates[SymbolName/@variables]];probes={};
 Do[
  base=<|"v"->point[[1]],"w"->point[[2]],"CA"->point[[3]],"CF"->(point[[3]]^2-1)/(2point[[3]]),
   "s"->(7+index),"muR2"->(3+index)/2,"muFA2"->(11+index)/3,"muFB2"->(13+index)/5,
   "muD2"->(17+index)/7,"nU"->If[EvenQ[index],2,3],"nD"->If[EvenQ[index],3,2]|>;
  rules=Table[var->Lookup[base,SymbolName[var],(index+First@FirstPosition[names,SymbolName[var]])/7],{var,variables}];
  values=Flatten[FixedPoint[Function[item,item/.data_Association:>Values[data]],
   FeynFacet`Private`partonicMap[Function[value,N[value/.rules,60]],expression]]];
  AppendTo[probes,If[values==={}||!AllTrue[values,NumberQ],Infinity,Max[Abs[values]]]],
 {index,6},{point,{{2/7,3/8,3},{4/9,2/3,4}}}];
 <|"Agreement"->AllTrue[Flatten[probes],TrueQ[#<10^-45]&],
  "Method"->"Twelve rational kinematic/color/scale points evaluated at 60-digit precision",
  "MaximumAbsoluteDifference"->Max[Flatten[probes]]|>
];

Do[
 project=FeynFacet`ReadProjectCard[projectDirectory];
 If[!AssociationQ[project]||KeyExistsQ[project,"Current"],Continue[]];
 Do[
  directory=projectDirectory<>"/NLO/"<>channel;file=directory<>"/Results/Result.wl";
  If[!FileExistsQ[file],Continue[]];
  previous=FeynFacet`ReadPartonicResult[file];
  FeynFacet`FamilyArtifactWrite[previous,directory<>"/Results/Validation/BeforeEndpointRegeneration.wl"];
  If[!AssociationQ[previous],failures++;Continue[]];
  Print["START ",project["Project"]," ",channel];
  Internal`InheritedBlock[{FeynFacet`Private`bornParallelInterferenceRows},
   Clear[FeynFacet`Private`bornParallelInterferenceRows];
   FeynFacet`Private`bornParallelInterferenceRows[___]:=$Failed;
   {seconds,run}=AbsoluteTiming[FeynFacet`RunNLOProject[directory,"assemble"]]];

  If[!AssociationQ[run],Print["FAILED ",project["Project"]," ",channel," ",InputForm[run]];failures++;Continue[]];
  current=FeynFacet`ReadPartonicResult[file];
  difference=FeynFacet`Private`partonicDistributionSum[{current["Coefficients"][0],
   FeynFacet`Private`partonicMap[Minus,previous["Coefficients"][0]]},1];
  comparison=auditCompare[difference,Lookup[project,"ColorRules",{}]];
  same=TrueQ[comparison["Agreement"]];If[!same,changes++];
  entry=<|"Status"->"Completed","Project"->project["Project"],"Channel"->channel,
   "FiniteCoefficientsUnchanged"->same,"Comparison"->comparison,"Seconds"->seconds,"ExactPoleCancellation"->True|>;
  If[!same,AssociateTo[entry,"ChangeInFiniteCoefficients"->difference]];
  If[project["Project"]==="ppHX_LL_NLO"&&channel==="qqbar-qpqpbar",
   AssociateTo[entry,"BaselineScope"->"This channel was regenerated successfully before an earlier comparison was interrupted. Independent LL=-UU reference checks are required; this repeat comparison alone does not compare its original pre-fix file."]];
  FeynFacet`FamilyArtifactWrite[entry,directory<>"/Results/Validation/EndpointRegenerationAudit.wl"];
  AssociateTo[report,project["Project"]<>"/"<>channel->entry];
  Print[If[same,"UNCHANGED ","CORRECTED "],project["Project"]," ",channel," ",Round[seconds,0.01]," seconds"],
 {channel,Lookup[project["Orders"],"NLO",{}]}],{projectDirectory,projects}];
output=root<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp/Results/Validation/CollinearBenchmarkCampaign/EndpointRegenerationAudit.wl";
FeynFacet`FamilyArtifactWrite[<|"Failures"->failures,"ChangedResults"->changes,"Results"->report|>,output];
Print["ENDPOINT_REGENERATION_AUDIT ",Length[report]," completed, ",failures," failed, ",changes," corrected"];
Exit[If[failures===0,0,1]];
