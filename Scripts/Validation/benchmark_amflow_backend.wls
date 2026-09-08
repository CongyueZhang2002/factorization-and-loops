#!/usr/bin/env wolframscript
(* Recompute an independent reference using another upstream solver backend.
   A copied symbolic AMFlow workspace may be supplied; no production DE or
   production boundary value enters the reference computation. *)
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Interfaces/AMFlowRuntime.wl"];
args=Rest[$ScriptCommandLine];
If[!MemberQ[{4,5},Length[args]],Print["Expected ORIGINAL_REQUEST.wl ORIGINAL_REFERENCE.wxf NATIVE_AMFLOW_DIRECTORY OUTPUT_DIRECTORY [FreshBoundaryOrders|SkipTargetReduction|NoMaximalCut]"];Exit[2]];
folder=ExpandFileName[args[[4]]];If[!DirectoryQ[folder],CreateDirectory[folder,CreateIntermediateDirectories->True]];
reusedSymbolicWorkspace=DirectoryQ[folder<>"/AMFlowWork"]&&FileNames["diffeq",folder<>"/AMFlowWork",Infinity]=!={};
request=Get[args[[1]]];
If[ExpandFileName[request["WorkingDirectory"]]===folder<>"/AMFlowWork",Print["Benchmark must use its own workspace"];Exit[2]];
freshBoundaryOrders=Length[args]===5&&args[[5]]==="FreshBoundaryOrders";
oldBoundaryOrders=If[freshBoundaryOrders,Association[(#->Get[#])&/@FileNames["border",folder<>"/AMFlowWork",Infinity]],<||>];
If[freshBoundaryOrders,Export[folder<>"/previous_boundary_orders.wxf",oldBoundaryOrders,"WXF"];Scan[DeleteFile,Keys[oldBoundaryOrders]]];
baselineReference=Import[args[[2]],"WXF"];
request=Join[request,<|"AMFlowPath"->ExpandFileName[args[[3]]],
 "AMFlowDESolver"->"CPP","WorkingDirectory"->folder<>"/AMFlowWork",
 "SkipTargetReduction"->Lookup[baselineReference,"SkipTargetReduction",False],
 "UseMaximalCut"->Lookup[baselineReference,"UseMaximalCut",True],
 "Threads"->1,"WolframScriptExecution"->"CurrentKernel","TimeLimit"->3600|>];
If[Length[args]===5&&args[[5]]==="SkipTargetReduction",request["SkipTargetReduction"]=True];
If[Length[args]===5&&args[[5]]==="NoMaximalCut",request["UseMaximalCut"]=False];
cacheIndex=<||>;
If[Length[args]===5&&args[[5]]==="CachedSystems",
 cacheIndex=FeynFacetAMFlowRuntime`Private`indexCompletedAMFlowSystems[folder<>"/AMFlowWork"];
 Print["INDEXED ",cacheIndex];request["ReuseCompletedAMFlowSystems"]=True];
Block[{$ContextPath={"System`"}},Put[request,folder<>"/request.wl"]];
initialLinks=Links[];
execution=FeynFacet`Private`runIsolatedWolframScript[root<>"/Scripts/Transport/evaluate_masters_with_amflow.wls",
 {folder<>"/request.wl",folder<>"/reference.wxf"},folder<>"/amflow.log"];
If[execution["ExitCode"]=!=0,Print["REFERENCE FAILED ",execution];Exit[1]];
If[Links[]=!=initialLinks,Print["Native link leaked from script scope"];Exit[1]];
Get[root<>"/FeynFacet/Solution.m"];
native=Import[folder<>"/reference.wxf","WXF"];previous=Import[args[[2]],"WXF"];
If[TrueQ[Lookup[native,"ReusedComputedLaurentExpansion",False]],Print["Benchmark reused numerical values"];Exit[1]];
If[KeyTake[native,{"IntegralDefinition","Point","OriginalMasterIntegralBasis","MasterIntegralPrefactors","AMFlowExpansionOrder","PrecisionGoal"}]=!=
 KeyTake[previous,{"IntegralDefinition","Point","OriginalMasterIntegralBasis","MasterIntegralPrefactors","AMFlowExpansionOrder","PrecisionGoal"}],Print["Reference definitions or precision changed"];Exit[1]];
checks=Table[
 a=Association@Table[k->Lookup[Association[native["MasterIntegralEpsilonCoefficients"][k]],row],{k,Keys[native["MasterIntegralEpsilonCoefficients"]]}];
 b=Association@Table[k->Lookup[Association[previous["MasterIntegralEpsilonCoefficients"][k]],row],{k,Keys[previous["MasterIntegralEpsilonCoefficients"]]}];
 FeynFacetSolution`CompareLaurentCoefficients[a,b,Keys[a],"AccuracyGoal"->20,"PrecisionGoal"->20],{row,native["RowIndices"]}];
boundaryOrdersMatched=AllTrue[Keys[oldBoundaryOrders],FileExistsQ[#]&&Get[#]===oldBoundaryOrders[#]&];
passed=AllTrue[checks,AssociationQ[#]&&#["Status"]==="Passed"&]&&boundaryOrdersMatched;
report=<|"Status"->If[passed,"Passed","Failed"],"Family"->ToString[native["Family"],InputForm],
 "Backend"->native["AMFlowDESolver"],"ReferencePrecisionGoal"->native["PrecisionGoal"],
 "ComparisonDigits"->20,"MasterCount"->Length[checks],
 "CoefficientCount"->Total[Lookup[checks,"PassedCoefficientCount",0]],
 "NativeElapsedSeconds"->native["ElapsedSeconds"],"OriginalElapsedSeconds"->previous["ElapsedSeconds"],
 "NativeLinksClosed"->True,"RecomputedBoundaryOrderCount"->Length[oldBoundaryOrders],
 "SkipTargetReduction"->Lookup[native,"SkipTargetReduction",False],
 "UseMaximalCut"->Lookup[native,"UseMaximalCut",True],
 "IndexedCompletedSystemCount"->Count[Values[cacheIndex],True],
 "NativeBoundaryOrdersMatchMMA"->boundaryOrdersMatched,
 "ReusedSymbolicWorkspace"->reusedSymbolicWorkspace,"Results"->checks|>;
Export[folder<>"/report.wxf",report,"WXF"];
Export[folder<>"/report.json",KeyDrop[report,"Results"],"RawJSON"];
Print[KeyDrop[report,"Results"]];Exit[If[passed,0,1]];
