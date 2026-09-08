
(* Shared request validation and process-level parallel evaluation. *)
FeynFacetSolution`EvaluateMasterIntegralSolutionRequest::usage="EvaluateMasterIntegralSolutionRequest[data,request] evaluates a point, optionally loading physical boundary data and comparing independent reference data with basis and accuracy checks.";
FeynFacetSolution`EvaluateMasterIntegralSolutionBatch::usage="EvaluateMasterIntegralSolutionBatch[requests,opts] evaluates independent families or kinematic points on up to eight persistent subkernels. Each request supplies SolutionDirectory and Point, with optional BoundaryDataFile, ReferenceDataFile, EvaluationOptions and OutputFile.";
readNumericalFile[path_String] := If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
FeynFacetSolution`EvaluateMasterIntegralSolutionRequest[data_Association,request_Association] := Catch[Module[{boundary,reference=None,options,evaluated,ag,pg,comparisons={},q,row,rules,
 a,b,ids,missing,boundaryBasis,normalizeBasis,precision,uncertainty,tolerance,nonzeroComparisons=0,
  expectedPoint,coordinates=Lookup[data,"RationalizingCoordinates",None]},
 expectedPoint[record_,point_]:=Module[{vars=Lookup[record,"KinematicVariables",data["KinematicVariables"]]},
  Which[
   vars===data["KinematicVariables"],point,
   AssociationQ[coordinates]&&vars===coordinates["SourceVariables"],
    Together/@(coordinates["SourceVariables"]/.coordinates["SourceVariableSubstitution"]/.
      Thread[data["KinematicVariables"]->point]),
   True,Throw[Failure["NumericalReferenceCoordinatesMismatch",<||>]]]];
 options=Lookup[request,"EvaluationOptions",{}];
 boundary=If[KeyExistsQ[request,"BoundaryDataFile"],readNumericalFile[request["BoundaryDataFile"]],None];
 normalizeBasis[z_] := z/.s_Symbol /;SymbolName[s]==="GLI":>Global`GLI;
 If[boundary=!=None,
 boundaryBasis=normalizeBasis[boundary["OriginalMasterIntegralBasis"]];
 If[boundaryBasis=!=normalizeBasis[data["OriginalMasterIntegralBasis"]]||
   boundary["Point"]=!=expectedPoint[boundary,data["BasePoint"]]||
   Lookup[boundary,"RowIndices",Range[Length[boundaryBasis]]]=!=Range[Length[boundaryBasis]],
  Throw[Failure["BoundaryBasisOrPointMismatch",<||>]]];
 ];
 ag="AccuracyGoal"/.options/. "AccuracyGoal"->20;
 pg="PrecisionGoal"/.options/. "PrecisionGoal"->20;
 If[boundary=!=None&&Lookup[boundary,"PrecisionGoal",Infinity]<Max[ag,pg]+5,
  Throw[Failure["BoundaryAccuracyInsufficient",<|"AvailableDigits"->boundary["PrecisionGoal"]|>]]];
 evaluated=FeynFacetSolution`EvaluateMasterIntegralSolution[data,request["Point"],
  Sequence@@If[boundary===None,options,
   Join[{"InitialConstantValues"->boundary["InitialConstantValues"]},DeleteCases[options,Rule["InitialConstantValues",_]]]]];
 If[FailureQ[evaluated],Throw[evaluated]];
 If[KeyExistsQ[request,"ReferenceDataFile"],
  reference=readNumericalFile[request["ReferenceDataFile"]];
  If[normalizeBasis[reference["OriginalMasterIntegralBasis"]]=!=normalizeBasis[data["OriginalMasterIntegralBasis"]]||
    reference["Point"]=!=expectedPoint[reference,request["Point"]],Throw[Failure["ReferenceBasisOrPointMismatch",<||>]]];
  If[Lookup[reference,"PrecisionGoal",Infinity]<Max[ag,pg]+5,
   Throw[Failure["ReferenceAccuracyInsufficient",<|"AvailableDigits"->reference["PrecisionGoal"]|>]]];
  Do[
   If[!KeyExistsQ[reference["MasterIntegralEpsilonCoefficients"],q],
    Throw[Failure["ReferenceEpsilonOrderMissing",<|"Order"->q|>]]];
   rules=Association[reference["MasterIntegralEpsilonCoefficients"][q]];
   Do[
    row=First[term];a=Last[term];
    If[!KeyExistsQ[rules,row],Throw[Failure["ReferenceMasterMissing",<|"Row"->row|>]]];
    b=rules[row];
    If[!NumberQ[b],Throw[Failure["ReferenceCoefficientNotNumeric",<|"Row"->row,"Order"->q|>]]];
    precision=Precision[b]/.MachinePrecision->$MachinePrecision;
    If[!TrueQ[FeynFacetSolution`Private`roundoffRatio[{b},ag+5,pg+5]<=1],
     Throw[Failure["ReferencePrecisionInsufficient",<|"Row"->row,"Order"->q|>]]];
    If[!TrueQ[a==0]||!TrueQ[b==0],nonzeroComparisons++];
    uncertainty=Total[numericAbsoluteUncertainty /@ {a,b}];
    tolerance=10^-ag+10^-pg Max[Abs[a],Abs[b]];
    AppendTo[comparisons,<|"Row"->row,"EpsilonOrder"->q,"AbsoluteDifference"->Abs[a-b],
     "EstimatedNumericalUncertainty"->uncertainty,
     "ToleranceRatio"->(Abs[a-b]+uncertainty)/tolerance,
     "ErrorEstimateIsRigorousBound"->False|>],
   {term,evaluated["MasterIntegralEpsilonCoefficients"][q]}],
  {q,Keys[evaluated["MasterIntegralEpsilonCoefficients"]]}]];
 Join[evaluated,If[reference===None,<||>,<|"ReferenceComparisons"->comparisons,
   "ReferenceComparisonNonzeroCoefficientCount"->nonzeroComparisons,
   "ReferenceComparisonScope"->If[nonzeroComparisons===0,"ZeroValuesOnly","ContainsNonzeroValues"],
   "ReferenceComparisonStatus"->If[Max[Lookup[comparisons,"ToleranceRatio"]]<=1,
    "ReferenceComparisonPassed","ReferenceComparisonFailed"]|>]]
]];

$numericalBatchData=<||>;
numericalBatchChunk[tasks_] := Table[Module[{request=Last[task],directory,stored,options,result,started=AbsoluteTime[],path,temp},
 result=Catch[
  If[!AssociationQ[request]||!KeyExistsQ[request,"SolutionDirectory"]||!KeyExistsQ[request,"Point"],
   Throw[Failure["NumericalBatchRequestInvalid",<||>]]];
  directory=ExpandFileName[request["SolutionDirectory"]];
  options=Lookup[request,"EvaluationOptions",{}];
  (* One core per task; the batch already occupies the requested CPU budget. *)
  options=Join[DeleteCases[options,Rule["Threads",_]],{"Threads"->1}];
  If[!KeyExistsQ[$numericalBatchData,directory],
   stored=FeynFacetSolution`ReadMasterIntegralSolution[directory];
   If[!AssociationQ[stored],Throw[Failure["NumericalSolutionNotReadable",<|"Directory"->directory|>]]];
   stored=FeynFacetSolution`PrepareMasterIntegralSolution[stored,
    "NumericalBackend"->("NumericalBackend"/.options/."NumericalBackend"->Automatic)];
   If[FailureQ[stored],Throw[stored]];
   AssociateTo[$numericalBatchData,directory->stored]];
  FeynFacetSolution`EvaluateMasterIntegralSolutionRequest[$numericalBatchData[directory],
   Join[request,<|"EvaluationOptions"->options|>]]
 ];
 If[AssociationQ[request]&&KeyExistsQ[request,"OutputFile"],
  path=ExpandFileName[request["OutputFile"]];
  If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
  temp=path<>".tmp-"<>ToString[$ProcessID];Export[temp,result,"WXF"];
  RenameFile[temp,path,OverwriteTarget->True]];
 <|"RequestIndex"->First[task],"ID"->If[AssociationQ[request],Lookup[request,"ID",First[task]],First[task]],
   "WorkerProcessID"->$ProcessID,"ElapsedSeconds"->AbsoluteTime[]-started,"Result"->result|>
],{task,tasks}];

Options[FeynFacetSolution`EvaluateMasterIntegralSolutionBatch]={"Workers"->8,"KeepKernels"->False};
FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[requests_List,OptionsPattern[]] := Module[
 {workers=OptionValue["Workers"],keep=OptionValue["KeepKernels"],old=Kernels[],created={},
  selected,ids,chunks,chunkMap,results,started=AbsoluteTime[],reader,finish,out,paths},
 If[!IntegerQ[workers]||!Between[workers,{1,8}]||!MemberQ[{True,False},keep],
  Return[Failure["InvalidNumericalBatchOptions",<||>]]];
 If[requests==={},Return[<|"Status"->"Completed","Results"->{},"WorkersUsed"->0,"ElapsedSeconds"->0|>]];
 paths=Cases[requests,a_Association /;KeyExistsQ[a,"OutputFile"]:>a["OutputFile"],{1}];
 If[!VectorQ[paths,StringQ]||!DuplicateFreeQ[ExpandFileName /@ paths],
  Return[Failure["NumericalBatchOutputPathsInvalid",<||>]]];
 workers=Min[workers,Length[requests]];
 finish[] := If[!keep&&created=!={},CloseKernels[created]];
 out=CheckAbort[Catch[
  If[workers===1,
   Block[{$numericalBatchData=<||>},
    results=numericalBatchChunk[MapIndexed[{First[#2],#1}&,requests]]],
   If[Length[old]<workers,LaunchKernels[workers-Length[old]]];
   created=Complement[Kernels[],old];
   If[Length[Kernels[]]<workers,Throw[Failure["NumericalWorkersUnavailable",
     <|"Requested"->workers,"Available"->Length[Kernels[]]|>]]];
   selected=Take[Kernels[],workers];reader=FileNameJoin[{$finiteSolutionDirectory,"Solution.m"}];
   With[{file=reader},ParallelEvaluate[Get[file];$HistoryLength=0;
     FeynFacetSolution`Private`$numericalBatchData=<||>;,selected]];
   ids=ParallelEvaluate[$KernelID,selected];
   chunks=Table[MapIndexed[{i+workers(First[#2]-1),#1}&,requests[[i;; ;;workers]]],{i,workers}];
   chunkMap=AssociationThread[ids,chunks];
   With[{assigned=chunkMap},results=Flatten[ParallelEvaluate[
     FeynFacetSolution`Private`numericalBatchChunk[assigned[$KernelID]],selected],1]];
   ParallelEvaluate[FeynFacetSolution`Private`$numericalBatchData=<||>;,selected]
  ];
  results=SortBy[results,#["RequestIndex"]&];
  <|"Status"->If[AllTrue[results,AssociationQ[#["Result"]]&&
     Lookup[#["Result"],"ReferenceComparisonStatus","ReferenceComparisonPassed"]==="ReferenceComparisonPassed"&],
    "Completed","CompletedWithFailures"],"Results"->results,
    "WorkersUsed"->workers,"ElapsedSeconds"->AbsoluteTime[]-started|>
 ],finish[];Abort[]];
 finish[];out
];
