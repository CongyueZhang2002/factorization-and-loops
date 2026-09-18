#!/usr/bin/env wolframscript
(* Benchmark one user-supplied finite solution; no family selection here.
   Times exclude Wolfram/package startup. Each backend is prepared once. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Solution.m"];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected SOLUTION_DIRECTORY REQUEST.wl REPORT.wxf"];Exit[2]];
data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];request=FeynFacetRecords`ReadRecord[args[[2]]];
If[!AssociationQ[data]||!AssociationQ[request],Print["Invalid inputs"];Exit[2]];
point=request["Point"];repeats=Lookup[request,"Repeats",3];
If[!ListQ[point]||!IntegerQ[repeats]||repeats<1,Print["Invalid point or repeat count"];Exit[2]];
conversionOptions=Lookup[request,"ConversionOptions",{}];
evaluationOptions=DeleteCases[Lookup[request,"EvaluationOptions",{}],
 Rule["NumericalBackend",_]|Rule["InitialConstantValues",_]];
constants=Lookup[request,"InitialConstantValues",Automatic];
reportFile=ExpandFileName[args[[3]]];reportDirectory=DirectoryName[reportFile];
If[!DirectoryQ[reportDirectory],CreateDirectory[reportDirectory,CreateIntermediateDirectories->True]];
writeData[path_String,value_]:=Module[{tmp,stream},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 tmp=path<>".tmp-"<>ToString[$ProcessID];stream=OpenWrite[tmp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[value,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 RenameFile[tmp,path,OverwriteTarget->True];path];
gplDirectory=ExpandFileName[Lookup[request,"ConvertedSolutionDirectory",
 FileNameJoin[{reportDirectory,FileBaseName[reportFile]<>"-GPL"}]]];
If[gplDirectory===ExpandFileName[args[[1]]],Print["GPL output must have its own directory"];Exit[2]];
fresh=KeyDrop[data,{"GPLRepresentation","NumericalPreparation"}];
conversionTime=First[AbsoluteTiming[
 converted=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[fresh,Sequence@@conversionOptions]]];
If[FailureQ[converted],Print[converted];Exit[1]];
gplFile=writeData[FileNameJoin[{gplDirectory,"solution.wxf"}],converted];
report=<|"ConvertedSolutionFile"->gplFile,"ConversionSeconds"->conversionTime,
 "GPLRepresentation"->KeyTake[converted["GPLRepresentation"],
  {"Status","GPLCount","MaximumGPLWeight","UnconvertedIntegrals","ReusedIntegralExpressions"}],
 "FiniteSolutionCompressedBytes"->Length[Normal[BinarySerialize[fresh,PerformanceGoal->"Size"]]],
 "SolutionWithGPLCompressedBytes"->Length[Normal[BinarySerialize[converted,PerformanceGoal->"Size"]]],
 "Point"->point,"EvaluationOptions"->evaluationOptions,"InitialConstantValues"->constants,
 "TimingConvention"->"Elapsed seconds, excluding Wolfram/package startup; preparation separate; each evaluation includes source-path and convergence checks."|>;
results=<||>;values=<||>;
Do[
 preparation=First[AbsoluteTiming[
  prepared=FeynFacetSolution`PrepareMasterIntegralSolution[
    If[backend==="GiNaC",converted,fresh],"NumericalBackend"->backend]]];
 If[FailureQ[prepared],AssociateTo[results,backend-><|"Failure"->prepared|>];Continue[]];
 timings=Table[First[AbsoluteTiming[
   value=FeynFacetSolution`EvaluateMasterIntegralSolution[prepared,point,
    "NumericalBackend"->backend,"InitialConstantValues"->constants,Sequence@@evaluationOptions]]],{repeats}];
 AssociateTo[results,backend-><|"PreparationSeconds"->preparation,
  "EvaluationSeconds"->timings,"MedianEvaluationSeconds"->Median[timings],
  "Result"->value|>];
 If[AssociationQ[value],
  AssociateTo[values,backend->If[constants===Automatic,Flatten[Values[value["EpsilonCoefficients"]]],
   Flatten[Last/@#& /@ Values[value["MasterIntegralEpsilonCoefficients"]]]]]],
 {backend,{"GiNaC","FLINT"}}];
AssociateTo[report,"Evaluations"->results];
If[KeyExistsQ[values,"GiNaC"]&&KeyExistsQ[values,"FLINT"],
 AssociateTo[report,"MaximumGPLFLINTDifference"->Max[Abs[values["GiNaC"]-values["FLINT"]]]]];
If[constants=!=Automatic&&KeyExistsQ[request,"TaylorOptions"],
 direction=point-fresh["BasePoint"];
 construction=First[AbsoluteTiming[
  taylor=FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[fresh,direction,
   "InitialConstantValues"->constants,Sequence@@request["TaylorOptions"]]]];
 If[AssociationQ[taylor],
  taylorFile=writeData[FileNameJoin[{reportDirectory,FileBaseName[reportFile]<>"-Taylor.wxf"}],taylor];
  timings=Table[First[AbsoluteTiming[
   value=FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[taylor,1]]],{repeats}];
  entry=<|"ExpansionFile"->taylorFile,"ConstructionSeconds"->construction,"EvaluationSeconds"->timings,
   "MedianEvaluationSeconds"->If[AssociationQ[value],Median[timings],Missing["QueryNotSupported"]],
   "QueryStatus"->If[AssociationQ[value],value["Status"],value],
   "CompressedBytes"->Length[Normal[BinarySerialize[taylor,PerformanceGoal->"Size"]]],
   "ValidatedParameterRadius"->taylor["ValidatedParameterRadius"],"Result"->value|>;
  If[AssociationQ[value]&&KeyExistsQ[values,"GiNaC"],
   AssociateTo[entry,"MaximumGPLTaylorDifference"->Max[Abs[values["GiNaC"]-
    Flatten[Last/@#& /@ Values[value["MasterIntegralEpsilonCoefficients"]]]]]]];
  AssociateTo[report,"Taylor"->entry],
  AssociateTo[report,"Taylor"-><|"ConstructionSeconds"->construction,"Failure"->taylor|>]]
];
writeData[reportFile,report];
Print["GPL_BENCHMARK ",KeyDrop[report,{"Evaluations","Taylor","InitialConstantValues"}]];
KeyValueMap[Print[#1," ",KeyDrop[#2,{"Result"}]," Status=",
 If[AssociationQ[Lookup[#2,"Result",None]],#2["Result"]["Status"],Lookup[#2,"Result",Lookup[#2,"Failure",None]]]]&,results];
If[KeyExistsQ[report,"Taylor"],Print["Taylor ",KeyDrop[report["Taylor"],{"Result"}]]];
Exit[If[Length[values]===2,0,1]];
