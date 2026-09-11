#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
(* General weighted assembly of retained coefficient files and exact maps. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Addon/Load/LoadFACET.wl"];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Expected ASSEMBLY_REQUEST.wl"];Exit[2]];
request=Get[ExpandFileName[First[args]]];
If[!AssociationQ[request]||!ContainsAll[Keys[request],{"CoefficientFiles","OutputFile"}]||
 !ListQ[request["CoefficientFiles"]]||!StringQ[request["OutputFile"]],
 Print["CoefficientFiles and OutputFile required"];Exit[2]];
file=ExpandFileName[request["OutputFile"]];
If[ToLowerCase[FileExtension[file]]=!="wxf",Print["OutputFile must have .wxf extension"];Exit[2]];
read[path_]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
rules=If[KeyExistsQ[request,"MasterIntegralRulesFile"],read[request["MasterIntegralRulesFile"]],
 Lookup[request,"MasterIntegralRules",{}]];
perRules=If[KeyExistsQ[request,"MasterIntegralRulesFiles"],
 If[!ListQ[request["MasterIntegralRulesFiles"]],Print["MasterIntegralRulesFiles must be a list"];Exit[2]];
 read/@request["MasterIntegralRulesFiles"],Lookup[request,"MasterIntegralRulesByContribution",Automatic]];
targetCatalog=If[KeyExistsQ[request,"TargetCatalogFile"],read[request["TargetCatalogFile"]],
 Lookup[request,"TargetCatalog",Automatic]];
elapsed=First[AbsoluteTiming[
 result=FeynFacet`AssembleCutContributions[request["CoefficientFiles"],
  "MasterIntegralRules"->rules,"MasterIntegralRulesByContribution"->perRules,
  "TargetCatalog"->targetCatalog,
  Sequence@@Normal[KeyTake[request,{"Weights","AdditionalFactor","TargetTopologies"}]]]]];
If[!AssociationQ[result]||Lookup[result,"Format",None]=!="FeynFacet-MasterIntegralCoefficients"||
 Lookup[result,"Status",None]=!="CutContributionsAssembled",Print["Cut assembly failed: ",result];Exit[1]];
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
temporary=file<>".partial";
If[!StringQ[Quiet[Check[Export[temporary,result,"WXF",PerformanceGoal->"Size"],$Failed]]],
 Print["Coefficient serialization failed"];Exit[1]];
If[Import[temporary,"WXF"]=!=result,Print["Coefficient serialization read-back failed"];Exit[1]];
If[!StringQ[Quiet[Check[RenameFile[temporary,file,OverwriteTarget->True],$Failed]]],
 Print["Coefficient output rename failed"];Exit[1]];
summary=<|"Status"->result["Status"],"MasterCount"->Length[result["Masters"]],
 "TermCount"->Total[Length[#["Terms"]]&/@result["Masters"]],
 "LaurentTermCount"->Count[Flatten[Lookup[result["Masters"],"Terms"],1],t_Association/;t["Representation"]==="LaurentSeries"],
 "RemainderTermCount"->Length[result["RemainderTerms"]],
 "ContributionWeights"->Lookup[result["Contributions"],"Weight"],
 "ElapsedSeconds"->elapsed,"OutputFile"->file,"OutputBytes"->FileByteCount[file]|>;
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED CUT ASSEMBLY ",summary];Exit[0];
