#!/usr/bin/env wolframscript
(* One family: current coefficient demands -> derived finite ranges -> explicit
   solved-DE coefficients. Reuse requires identical mathematical inputs. *)
$HistoryLength=0;
repository=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[repository<>"/Addon/Load/LoadFACET.wl"]];
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=2,Print["Expected SPECIFICATION.wl OUTPUT_DIRECTORY"];Exit[64]];
specificationFile=ExpandFileName[arguments[[1]]];directory=ExpandFileName[arguments[[2]]];
spec=FeynFacetRecords`ReadRecord[specificationFile];
If[!AssociationQ[spec],Print["Specification must be an association"];Exit[64]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,
 FileNameJoin[{DirectoryName[specificationFile],path}]]];
read[path_]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],FamilyArtifactRead[path]];
(* JSON is an operational summary; exact mathematics stays in WXF. *)
jsonValue[a_Association]:=Association@KeyValueMap[
  If[StringQ[#1],#1,ToString[#1,InputForm]]->jsonValue[#2]&,a];
jsonValue[a_List]:=jsonValue/@a;
jsonValue[a_String]:=a;
jsonValue[a_Integer]:=a;
jsonValue[a_Real]:=a;
jsonValue[True]=True;jsonValue[False]=False;
jsonValue[Null]=Null;jsonValue[None]=Null;
jsonValue[a_]:=ToString[a,InputForm];
save[expr_,name_]:=Module[{file=FileNameJoin[{directory,name}],temporary,stream,encoded},
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 temporary=file<>".tmp-"<>ToString[$ProcessID];
 If[FileExtension[name]==="json",
  encoded=ExportString[jsonValue[expr],"RawJSON"];
  If[!StringQ[encoded],Throw[Failure["SummaryJSONEncodingFailed",<|"File"->name|>]]];
  Export[temporary,encoded,"Text"],
  stream=OpenWrite[temporary,BinaryFormat->True];
  BinaryWrite[stream,Normal[BinarySerialize[expr,PerformanceGoal->"Size"]],"Byte"];Close[stream]];
 RenameFile[temporary,file,OverwriteTarget->True]];
phase="Reading";started=AbsoluteTime[];timings=<||>;family=Lookup[spec,"Family",None];
preserveOutput=DirectoryQ[directory] && FileNames["*",directory]=!={};
progress[]:=Module[{value=<|"Family"->family,"Phase"->phase,
 "ElapsedSeconds"->N[AbsoluteTime[]-started],"PhaseTimings"->timings,"Status"->"Running"|>},
 save[value,"progress.wxf"];save[value,"progress.json"];Print[phase," ",family]];
result=TimeConstrained[Catch[Module[
 {data,orders,extras,options,ids,entries,requirements,upper=<||>,id,entry,master,row,
  n,masterKeys,request,solution,seconds,preparation=None,summary,identity,inputFile,
  solutionFile,summaryFile,previous,recurrenceFile,sourceData,
  cachedSolution=None,cachedPlan,cachedRanges,reusedEvolution=False,previousEvolutionSeconds=None},
 data=read[resolve[spec["DataFile"]]];sourceData=data;
 orders=read[resolve[spec["OrderRequirementsFile"]]];
 If[!AssociationQ[data] || !AssociationQ[orders] ||
   !AssociationQ[Lookup[orders,"MasterIntegralInputMap",None]] ||
   !AssociationQ[Lookup[orders,"RequiredInputUpperOrders",None]],
   Throw[Failure["ExplicitCoefficientOrdersRequired",<||>]]];
 family=data["Family"];
 If[KeyExistsQ[spec,"Family"] && spec["Family"]=!=family,
   Throw[Failure["FamilySpecificationMismatch",<||>]]];
 ids=FeynFacet`Private`miRepFC[data["OriginalMasterIntegralBasis"]];n=Length[ids];
 If[!AllTrue[ids,MatchQ[#,_FeynCalc`GLI]&],
   Throw[Failure["MasterIntegralIdentifiersRequired",<||>]]];
 masterKeys=ids/.FeynCalc`GLI[f_,powers_List]:>{If[StringQ[f],f,SymbolName[f]],powers};
 If[!DuplicateFreeQ[masterKeys],Throw[Failure["DuplicateMasterIntegralIdentifiers",<||>]]];
 extras=Lookup[spec,"RequestOptions",<||>];options=Lookup[spec,"Options",<||>];
 If[!AssociationQ[extras] || !AssociationQ[options] ||
    Complement[Keys[options],First/@Options[ConstructMasterIntegralSolution]]=!={} ||
    KeyExistsQ[options,"OutputDirectory"] ||
    AnyTrue[{"RequestedMasterIntegralOrderRanges","RequestedMasterIntegralUpperOrders"},KeyExistsQ[extras,#]&],
   Throw[Failure["FamilyConstructionOptionsInvalid",<||>]]];
 recurrenceFile=Lookup[spec,"DimensionalRecurrenceFile",None];
 If[StringQ[recurrenceFile],
  extras=Join[extras,<|"DimensionalRecurrence"->read[resolve[recurrenceFile]],
    "CutPoleBoundMethod"->"DimensionalRecurrence"|>]];
 requirements=orders["RequiredInputUpperOrders"];entries=orders["MasterIntegralInputMap"];
 Do[
  entry=entries[id];master=entry["MasterIntegral"];
  If[master["Family"]=!=family || !KeyExistsQ[requirements,id],Continue[]];
  If[!IntegerQ[requirements[id]],Throw[Failure["FiniteMasterUpperOrderRequired",<|"Input"->id|>]]];
  row=FirstPosition[masterKeys,{family,master["PropagatorPowers"]},Missing["MasterNotInClosedDE"],{1}];
  If[MissingQ[row],Throw[Failure["CoefficientMasterAbsentFromClosedDE",<|"Input"->id,"Master"->master|>]]];
  row=First[row];AssociateTo[upper,row->Max[Lookup[upper,row,-Infinity],requirements[id]]],
 {id,Keys[entries]}];
 upper=KeySort[upper];
 If[upper===<||>,Return[<|"Status"->"NotRequiredByCoefficientOrders","Family"->family|>,Module]];
 request=Join[extras,<|"RequestedMasterIntegralUpperOrders"->upper|>];
 If[KeyExistsQ[spec,"FiniteIntegrationPreparationFile"],
  preparation=read[resolve[spec["FiniteIntegrationPreparationFile"]]];
  data=ApplyFiniteIntegrationPreparation[data,preparation];
  If[FailureQ[data],Throw[data]];
  options=Join[options,<|"AutomaticPreparation"->False|>]];
 identity=<|"SourceData"->sourceData,"CoefficientOrders"->orders,"Request"->request,
   "FiniteIntegrationPreparation"->preparation,"Options"->options|>;
 inputFile=FileNameJoin[{directory,"input.wxf"}];
 solutionFile=FileNameJoin[{directory,"solution.wxf"}];
 summaryFile=FileNameJoin[{directory,"summary.wxf"}];
 If[FileExistsQ[inputFile],
  If[Import[inputFile,"WXF"]=!=identity,preserveOutput=True;
   Throw[Failure["ExistingSolutionInputMismatch",<|"Directory"->directory|>]]];
  If[FileExistsQ[solutionFile] && FileExistsQ[summaryFile],
   previous=Import[summaryFile,"WXF"];
   If[AssociationQ[previous] && Lookup[previous,"Status",None]==="Completed",
    cachedSolution=Import[solutionFile,"WXF"];
    cachedPlan=Lookup[cachedSolution,"ExpansionOrderDetermination",None];
    If[!AssociationQ[cachedPlan],Throw[Failure["StoredExpansionOrderDeterminationRequired",<||>]]];
    cachedRanges=FeynFacet`Private`epsOrderTransportedMasterRanges[
      cachedPlan["OriginalFundamentalMatrixEntryLowerBounds"],
      cachedPlan["OrdinaryPointConstantLowerBounds"],upper];
    If[cachedRanges===cachedPlan["RequestedMasterIntegralOrderRanges"],
      save[KeyDrop[previous,{"RequestedMasterIntegralOrderRanges","RequestedMasterIntegralUpperOrders","Detail"}],
        "summary.json"];
      preserveOutput=True;Return[Join[previous,<|"ReusedCompletedResult"->True|>],Module]];
    If[!AllTrue[Keys[upper],cachedRanges[#][[2]]===cachedPlan["RequestedMasterIntegralOrderRanges"][#][[2]]&],
      Throw[Failure["StoredEvolutionUpperOrderMismatch",<||>]]];
    cachedPlan=Join[cachedPlan,<|"RequestedMasterIntegralOrderRanges"->cachedRanges|>];
    reusedEvolution=True;
    previousEvolutionSeconds=Lookup[previous,"PhaseTimings",<||>]
   ]],
  If[DirectoryQ[directory] && FileNames["*",directory]=!={},preserveOutput=True;
   Throw[Failure["EmptyFamilyOutputDirectoryRequired",<|"Directory"->directory|>]]];
  save[identity,"input.wxf"]
 ];
 preserveOutput=False;
 save[<|"SourceData"->sourceData,"Request"->request,
   "CoefficientOrderScope"->Lookup[orders,"Scope",None]|>,"request.wxf"];
 phase="FiniteSolution";progress[];
 {seconds,solution}=AbsoluteTiming[If[reusedEvolution,
   Catch[FeynFacet`Private`solutionMasterCoefficientsFromOrders[cachedSolution,cachedPlan],"FiniteSolution"],
   ConstructMasterIntegralSolution[data,request,Sequence@@Normal[options]]]];
 timings[If[reusedEvolution,"AdditionalMasterCoefficientSeconds","OrderDeterminationAndFiniteSolutionSeconds"]]=seconds;
 If[FailureQ[solution],Throw[solution]];
 If[!AssociationQ[solution] || !TrueQ[Lookup[Lookup[solution,"RequestedMasterOrderCoverage",<||>],
      "EveryRequestedCoefficientConstructed",False]],
   Throw[Failure["CompleteMasterCoefficientSolutionRequired",<||>]]];
 phase="Writing";progress[];
 {seconds,summary}=AbsoluteTiming[WriteMasterIntegralSolution[solution,directory,"FileFormat"->"WXF"]];
 timings["WritingSeconds"]=seconds;
 If[FailureQ[summary],Throw[summary]];
 <|"Status"->If[solution["RequestedMasterOrderCoverage"]["Status"]==="SufficientOrdersDetermined",
    "Completed","ConstructedWithAssumedLaurentBounds"],
  "Family"->family,"ClosedMasterCount"->n,"RequestedMasterCount"->Length[upper],
  "RequestedMasterIntegralUpperOrders"->upper,
  "RequestedMasterIntegralOrderRanges"->solution["RequestedMasterIntegralOrderRanges"],
  "BasePoint"->solution["BasePoint"],"CoefficientOrderScope"->Lookup[orders,"Scope",None],
  "StoredMasterCoefficientCount"->Total[Length/@Values[solution["MasterIntegralCoefficients"]]],
  "IntegralDefinitionCount"->Length[solution["IntegralDefinitions"]],
  "RequiredBoundaryCoefficientCount"->Length[solution["RequiredInitialConstantCoefficients"]],
  "CompressedBytes"->FileByteCount[solutionFile],"BoundaryConstantsDetermined"->False,
   "PhysicalNNLOCoverageInferred"->False,"ReusedCompletedResult"->False,
  "ReusedFiniteEvolution"->reusedEvolution,"PreviousFiniteEvolutionTimings"->previousEvolutionSeconds,
  "OutputLowerBoundMethod"->"Valuations of the complete evolution matrix times the ordinary-point constant vector",
  "CoverageStatus"->solution["RequestedMasterOrderCoverage"]["Status"],
  "PhaseTimings"->timings,"Seconds"->N[AbsoluteTime[]-started]|>
]],Lookup[spec,"TimeLimitSeconds",900],Failure["FamilyFiniteSolutionBudgetExhausted",<|"Phase"->phase|>]];
If[!AssociationQ[result] ||
 !MemberQ[{"Completed","ConstructedWithAssumedLaurentBounds","NotRequiredByCoefficientOrders"},Lookup[result,"Status",None]],
 result=<|"Status"->"Incomplete","Family"->family,"Phase"->phase,"Detail"->result,
  "PhaseTimings"->timings,"Seconds"->N[AbsoluteTime[]-started]|>];
If[!preserveOutput,
 save[result,"summary.wxf"];
 save[Join[KeyDrop[result,{"RequestedMasterIntegralOrderRanges","RequestedMasterIntegralUpperOrders","Detail"}],
   If[KeyExistsQ[result,"Detail"],<|"Detail"->StringTake[ToString[result["Detail"],InputForm],UpTo[1500]]|>,<||>]],
   "summary.json"];
 save[<|"Family"->family,"Phase"->phase,"Status"->result["Status"],
   "ElapsedSeconds"->N[AbsoluteTime[]-started]|>,"progress.json"]];
Print[result];
Exit[If[MemberQ[{"Completed","NotRequiredByCoefficientOrders"},result["Status"]],0,2]];
