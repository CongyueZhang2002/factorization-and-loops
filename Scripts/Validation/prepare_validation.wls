#!/usr/bin/env wolframscript
(* Build both inventories from supplied process results, with no family cases. *)
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Solution.m"];Get[root<>"/Scripts/Validation/common.wl"];
args=Rest[$ScriptCommandLine];If[Length[args]=!=1,Print["Expected INPUT.wl"];Exit[2]];
file=ExpandFileName[First[args]];base=DirectoryName[file];spec=readValidationFile[file];
out=validationPath[base,spec["OutputDirectory"]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
campaign=validationPath[base,spec["SolutionCampaignDirectory"]];
files=Sort[FileNames["solution.wxf",campaign,Infinity]];
families={};inventory={};
Do[
 data=readValidationFile[path];rows=Sort[DeleteDuplicates[First/@Flatten[Values[data["MasterIntegralCoefficients"]],1]]];
 id=StringReplace[ToString[data["Family"],InputForm],"\""->""];
 If[rows==={}||!StringMatchQ[id,RegularExpression["[A-Za-z0-9_-]+"]],Print["Invalid family inventory ",path];Exit[2]];
 orders=Association@Table[row->Sort[Select[Keys[data["MasterIntegralCoefficients"]],
   MemberQ[First/@data["MasterIntegralCoefficients"][#],row]&]],{row,rows}];
 directory=DirectoryName[path];familyOut=out<>"/CompleteMasters/"<>id;
 request=<|"ID"->id,"SolutionDirectory"->directory,"SourceInputFile"->directory<>"/input.wxf",
  "Point"->spec["Point"],"KinematicVariables"->data["KinematicVariables"],"Rows"->rows,
  "MasterIntegralBasis"->data["OriginalMasterIntegralBasis"][[rows]],"RequiredOrders"->orders,
  "AMFlowRuntime"->spec["AMFlowRuntime"],"OutputDirectory"->familyOut,
  "EvaluationOptions"->Lookup[spec,"EvaluationOptions",{"Threads"->4,"AccuracyGoal"->18,"PrecisionGoal"->18}],
  "ComparisonOptions"->Lookup[spec,"ComparisonOptions",{"AccuracyGoal"->18,"PrecisionGoal"->18}],
  "AMFlowPrecisionGoal"->Lookup[spec,"AMFlowPrecisionGoal",25],"Threads"->Lookup[spec,"Threads",4],
  "TimeLimit"->Lookup[spec,"TimeLimit",1800]|>;
 writeValidationFile[familyOut<>"/request.wxf",request];
 AppendTo[families,<|"ID"->id,"SolutionFile"->path,"RequestFile"->familyOut<>"/request.wxf","OutputDirectory"->familyOut|>];
 Do[AppendTo[inventory,<|"Family"->id,"Row"->row,"MasterIntegral"->ToString[data["OriginalMasterIntegralBasis"][[row]],InputForm],
  "RequiredOrders"->orders[row],"Status"->"NotChecked"|>],{row,rows}],{path,files}];
 If[families==={}||!DuplicateFreeQ[Lookup[families,"ID"]],Print["Empty or duplicate family inventory"];Exit[2]];
 manifest=<|"Test"->"CompleteMasterIntegrals","RepositoryRoot"->root,"SolutionCampaignDirectory"->campaign,"Families"->families,
  "MasterIntegrals"->inventory,"RequiredMasterCount"->Length[inventory],
  "RequiredCoefficientCount"->Total[Length/@Lookup[inventory,"RequiredOrders"]],"Threads"->Lookup[spec,"Threads",4]|>;
 Export[out<>"/complete_masters.json",manifest,"RawJSON"];
 If[KeyExistsQ[spec,"AmplitudeReductionFile"],
  reductionFile=validationPath[base,spec["AmplitudeReductionFile"]];reduction=readValidationFile[reductionFile];
  refs=Lookup[spec,"BoundaryReferences",<||>];boundaryCases={};
  Do[range=reduction["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][i];If[range==={},Continue[]];
   ref=Lookup[refs,i,<||>];
   If[KeyExistsQ[ref,"Reference"],ref["Reference"]=Join[ref["Reference"],
    <|"File"->validationPath[base,ref["Reference"]["File"]]|>]];
   AppendTo[boundaryCases,Join[<|"ID"->ToString[i],"BoundaryInputIndex"->i,
    "OriginalRow"->Lookup[reduction["BoundaryInputs"][[i]],"OriginalRow",None],"RequiredOrders"->Range@@range|>,ref]],
   {i,Length[reduction["BoundaryInputs"]]}];
  writeValidationFile[out<>"/stage3.wxf",<|"AmplitudeReductionFile"->reductionFile,
   "BoundaryIntegrals"->boundaryCases,"ComparisonOptions"->Lookup[spec,"BoundaryComparisonOptions",{"AccuracyGoal"->25,"PrecisionGoal"->25}]|>];
  Print["STAGE 3 INVENTORY ",Length[boundaryCases]," inputs, ",Total[Length/@Lookup[boundaryCases,"RequiredOrders"]]," coefficients"]];
Print["COMPLETE MASTER INVENTORY ",Length[families]," families, ",Length[inventory]," masters, ",manifest["RequiredCoefficientCount"]," coefficients"];
Exit[0];
