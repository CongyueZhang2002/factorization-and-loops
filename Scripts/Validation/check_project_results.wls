#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3,4},Length[args]],
 Print["Usage: check_project_results.wls PROJECT ORDER [CHANNEL|all] [BASELINES.json]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projectPath=If[DirectoryQ[args[[1]]],ExpandFileName[args[[1]]],FileNameJoin[{root,"Projects",args[[1]]}]];
project=FeynFacet`ReadProjectCard[projectPath];order=args[[2]];
If[!AssociationQ[project]||!KeyExistsQ[project["Orders"],order],Print["Declared project/order required"];Exit[2]];
selection=If[Length[args]>=3,args[[3]],"all"];
channels=If[selection==="all",project["Orders"][order],{selection}];
If[!SubsetQ[project["Orders"][order],channels],Print["Declared result channels required"];Exit[2]];
references={};
If[Length[args]===4,
 references=Import[args[[4]],"RawJSON"];
 If[!MatchQ[references,{_Association..}],Print["Nonempty baseline inventory required"];Exit[2]];
 Get[root<>"/Tests/Support/CountertermComparison.wl"]];
reportDirectory=FileNameJoin[{root,"Reports",DateString[{"Year","-","Month","-","Day"}]}];
reports={};
Do[
 directory=FileNameJoin[{project["Directory"],"Results",order,channel}];
 plan=FeynFacet`PlanProjectResult[FileNameJoin[{directory,"Result_Card.wl"}]];
 If[!AssociationQ[plan],Print[InputForm[plan]];Exit[1]];
 rawChecks=Map[AssociationQ[FeynFacet`ReadRawContributionResult[#]]&,plan["RawCards"]];
 final=FeynFacet`ReadPartonicResult[FileNameJoin[{directory,"Results.wl"}],<|
  "Project"->project["Project"],"Order"->order,"Channel"->channel,
  "PhysicalChannel"->project["Channels"][channel],
  "EpsilonRange"->plan["ResultCard"]["EpsilonRange"],
  "ResultSelection"->plan["ResultCard"]["Inputs"],
  "CouplingNormalization"->project["Counterterms"]["CouplingNormalization"]|>];
 If[!AllTrue[rawChecks,TrueQ]||!AssociationQ[final],
  Print["RESULT_VALIDATION_FAILED ",channel," ",Keys[Select[rawChecks,Not]]];
  If[FailureQ[final],Print[InputForm[final]]];Exit[1]];
 report=<|"Project"->project["Project"],"Order"->order,"Channel"->channel,
  "Passed"->True,"RawComponentsValidated"->Length[rawChecks],
  "EpsilonRange"->plan["ResultCard"]["EpsilonRange"],"ReferenceComparison"->"NotRequested"|>;
 If[Length[args]===4,
  candidates=Select[references,Lookup[#,"Project",None]===project["Project"]&&
    Lookup[#,"Order",None]===order&&Lookup[#,"Channel",None]===channel&];
  If[Length[candidates]=!=1,Print["Unique baseline required for ",channel];Exit[1]];
  referenceFile=Lookup[First[candidates],"BaselineResult",None];
  If[!StringQ[referenceFile],Print["BaselineResult file required"];Exit[1]];
  If[!StringStartsQ[referenceFile,"/"],
   referenceFile=ExpandFileName[FileNameJoin[{DirectoryName[ExpandFileName[args[[4]]]],referenceFile}]]];
  baseline=FeynFacet`ReadPartonicResult[referenceFile];
  comparison=FTCountertermComparison`CompareResults[baseline,final,<|
   "EpsilonRange"->plan["ResultCard"]["EpsilonRange"],
   "ParameterRules"->Join[Lookup[project,"ColorRules",{}],Lookup[project,"BenchmarkParameterRules",{}]],
   "Assumptions"->Lookup[final,"Domain",True],"SecondsPerCoefficient"->30|>];
  If[!AssociationQ[comparison],Print[InputForm[comparison]];Exit[1]];
  report=Join[report,<|"Passed"->TrueQ[comparison["Passed"]],"ReferenceFile"->referenceFile,
   "ReferenceComparison"->comparison|>]];
 FeynFacet`FamilyArtifactWrite[report,FileNameJoin[{reportDirectory,
  project["Project"]<>"_"<>order<>"_"<>channel<>"_ResultCheck.wl"}]];
 AppendTo[reports,report];Print[If[TrueQ[report["Passed"]],"PASS ","FAIL "],project["Project"]," ",order," ",channel],
{channel,channels}];
If[!AllTrue[reports,TrueQ[#["Passed"]]&],Exit[1]];
Print["PROJECT_RESULTS_CHECKED ",Length[reports]];
