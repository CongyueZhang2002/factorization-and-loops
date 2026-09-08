#!/usr/bin/env wolframscript
(* INPUT.wl contains Families -> <|name -> <|DataFile, Request, Options|>, ...|>.
   Family data and target orders are supplied, never inferred from a process name.
   Completed immutable input/output pairs can be resumed without recomputation. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
inputFile=ExpandFileName[args[[1]]];output=ExpandFileName[args[[2]]];
input=Get[inputFile];
families=Lookup[input,"Families",None];
If[!AssociationQ[families] || families===<||> ||
 !AllTrue[Keys[families],StringQ[#] && StringMatchQ[#,RegularExpression["[A-Za-z0-9_-]+"]]&],
 Print["Families must be a nonempty association with plain directory names"];Exit[2]];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
save[value_,path_]:=Module[{temp=path<>".tmp-"<>ToString[$ProcessID],stream},
 stream=OpenWrite[temp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[value,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 RenameFile[temp,path,OverwriteTarget->True]];
read[path_]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],FamilyArtifactRead[path]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{DirectoryName[inputFile],path}]]];
report=<||>;
Do[
 specification=families[name];directory=FileNameJoin[{output,name}];
 outcome=Catch[Module[{data,request,options,preparationFile,identity,identityFile,
   solutionFile,summaryFile,previous,sol,time,written,summary},
  If[!AssociationQ[specification],Throw[Failure["FamilySpecificationRequired",<||>]]];
  data=If[KeyExistsQ[specification,"Data"],specification["Data"],
    read[resolve[specification["DataFile"]]]];
  request=Lookup[specification,"Request",<||>];options=Lookup[specification,"Options",<||>];
  If[!AssociationQ[data] || !AssociationQ[request] || !AssociationQ[options] ||
    !KeyExistsQ[request,"RequestedMasterIntegralOrderRanges"],
    Throw[Failure["MasterIntegralRangeRequestRequired",<||>]]];
  If[Complement[Keys[options],First /@ Options[ConstructMasterIntegralSolution]]=!={} ||
     KeyExistsQ[options,"OutputDirectory"],Throw[Failure["FamilyConstructionOptionsInvalid",<||>]]];
  preparationFile=Lookup[specification,"FiniteIntegrationPreparationFile",None];
  If[StringQ[preparationFile],
   data=ApplyFiniteIntegrationPreparation[data,read[resolve[preparationFile]]];
   options=Join[options,<|"AutomaticPreparation"->False|>]];
  identity=<|"Data"->data,"Request"->request,"Options"->options|>;
  identityFile=FileNameJoin[{directory,"input.wxf"}];
  solutionFile=FileNameJoin[{directory,"solution.wxf"}];
  summaryFile=FileNameJoin[{directory,"summary.wxf"}];
  If[!DirectoryQ[directory],CreateDirectory[directory]];
  If[FileExistsQ[identityFile],
   If[Import[identityFile,"WXF"]=!=identity,Throw[Failure["ExistingSolutionInputMismatch",<|"Directory"->directory|>]]];
   If[FileExistsQ[solutionFile] && FileExistsQ[summaryFile],
     previous=Import[summaryFile,"WXF"];
     Return[Join[previous,<|"ReusedCompletedResult"->True|>],Module]],
   If[FileNames["*",directory]=!={},Throw[Failure["EmptyFamilyOutputDirectoryRequired",<||>]]];
   save[identity,identityFile]
  ];
  Print["Constructing ",name];
  time=First[AbsoluteTiming[sol=ConstructMasterIntegralSolution[data,request,Sequence@@Normal[options]]]];
  If[FailureQ[sol],Throw[sol]];
  written=WriteMasterIntegralSolution[sol,directory,"FileFormat"->"WXF"];
  If[FailureQ[written],Throw[written]];
  summary=<|"Status"->If[sol["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined",
     "Completed","ConstructedWithAssumedLaurentBounds"],
   "Family"->name,"Directory"->directory,"ConstructionSeconds"->time,
   "BasePoint"->sol["BasePoint"],"RequestedMasterIntegralOrderRanges"->sol["RequestedMasterIntegralOrderRanges"],
   "MasterCount"->Length[sol["OriginalMasterIntegralBasis"]],
   "StoredMasterCoefficientCount"->Total[Length /@ Values[sol["MasterIntegralCoefficients"]]],
   "PreparedEvolutionOrderRange"->sol["TransformedSystemEpsilonOrderRange"],
   "IntegralDefinitionCount"->Length[sol["IntegralDefinitions"]],
   "RequiredBoundaryCoefficientCount"->Length[sol["RequiredInitialConstantCoefficients"]],
   "CompressedBytes"->FileByteCount[solutionFile],"BoundaryConstantsDetermined"->False,
   "PhysicalNNLOCoverageInferred"->False,"ReusedCompletedResult"->False|>;
  save[summary,summaryFile];summary
 ]];
 AssociateTo[report,name->outcome];
 save[<|"DataType"->"MasterIntegralFamilySolutionReport","Families"->report,
   "EveryFamilyCompleted"->AllTrue[Values[report],AssociationQ[#] && Lookup[#,"Status",None]==="Completed"&]|>,
   FileNameJoin[{output,"report.wxf"}]];
 Print[name," ",If[FailureQ[outcome],outcome,KeyTake[outcome,
   {"Status","ConstructionSeconds","BasePoint","StoredMasterCoefficientCount","CompressedBytes","ReusedCompletedResult"}]]],
{name,Keys[families]}];
If[!AllTrue[Values[report],AssociationQ[#] && Lookup[#,"Status",None]==="Completed"&],Exit[1]];
Exit[0];
