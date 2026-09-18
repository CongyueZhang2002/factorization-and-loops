#!/usr/bin/env wolframscript
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/Scripts/Validation/common.wl"];
args=Rest[$ScriptCommandLine];If[!MemberQ[{2,3},Length[args]],Print["Expected FAMILY_REQUEST.wxf OUTPUT.wl [rows]"];Exit[2]];
spec=readValidationFile[args[[1]]];rows=If[Length[args]===3,ToExpression/@StringSplit[args[[3]],","],spec["Rows"]];
If[rows==={}||!VectorQ[rows,IntegerQ]||!DuplicateFreeQ[rows]||!ContainsAll[spec["Rows"],rows],Print["Invalid rows"];Exit[2]];
saved=readValidationFile[spec["SolutionDirectory"]<>"/solution.wxf"];
currentRows=Sort[DeleteDuplicates[First/@Flatten[Values[saved["MasterIntegralCoefficients"]],1]]];
currentOrders=Association@Table[row->Sort[Select[Keys[saved["MasterIntegralCoefficients"]],
 MemberQ[First/@saved["MasterIntegralCoefficients"][#],row]&]],{row,currentRows}];
If[currentRows=!=spec["Rows"]||currentOrders=!=spec["RequiredOrders"]||
 (validationMasterID/@saved["OriginalMasterIntegralBasis"][[currentRows]])=!=(validationMasterID/@spec["MasterIntegralBasis"]),
 Print["Master inventory changed; regenerate validation inputs"];Exit[1]];
input=readValidationFile[spec["SourceInputFile"]];source=input["SourceData"];
result=FeynFacet`ConstructMasterIntegralDefinitions[source,<|"RequestedRows"->rows|>,"InputRoot"->root];
If[FailureQ[result]||Lookup[result,"UnresolvedIntegralDefinitions",<||>]=!=<||>,Print["FAILED DEFINITIONS ",result];Exit[1]];
defs=result["MasterIntegralDefinitions"];definition=defs[First[rows]];
masters=Lookup[Values[KeyTake[defs,rows]],"MasterIntegral"];
If[(validationMasterID/@masters)=!=(validationMasterID/@spec["MasterIntegralBasis"][[Flatten[FirstPosition[spec["Rows"],#]&/@rows]]]),
 Print["Master inventory differs from source definitions"];Exit[1]];
request=Join[spec["AMFlowRuntime"],<|"IntegralDefinition"->definition,"MasterIntegralBasis"->masters,
 "MasterIntegralPrefactors"->(defs[#]["MasterIntegralPrefactor"]&/@rows),"RowIndices"->rows,
 "Point"->spec["Point"],"KinematicVariables"->spec["KinematicVariables"],
 "EpsilonLowerOrders"->(Min[spec["RequiredOrders"][#]]&/@rows),
 "EpsilonOrder"->Max[Flatten[Lookup[spec["RequiredOrders"],rows]]],
 "PrecisionGoal"->spec["AMFlowPrecisionGoal"],"Threads"->spec["Threads"],
 "TimeLimit"->spec["TimeLimit"],"WorkingDirectory"->spec["OutputDirectory"]<>"/AMFlowWork"|>];
(* The AMFlow process does not load FeynCalc. Preserve qualified symbolic
   heads instead of printing short names dependent on this ContextPath. *)
FeynFacetRecords`WriteRecord[request,args[[2]]];
Print["PREPARED AMFLOW ",spec["ID"]," rows ",rows," upper ",request["EpsilonOrder"]];Exit[0];
