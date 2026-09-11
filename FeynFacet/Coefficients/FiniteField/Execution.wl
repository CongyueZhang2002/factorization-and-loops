(* Shared production execution for complete rational columns and literal
   exact/finite partitions. A finite order must come from a bound order plan. *)
BeginPackage["FeynFacet`"];Begin["`Private`"];
finiteFieldExecuteCoefficientPlan[inputs_Association,data_Association,
 nativeDirectory_String,executable_String,options_Association,planInput_:Automatic] := Catch[Module[
 {plan=planInput,directory,partDirectory,partData=None,sourceIndices={},orderPlans=<||>,
  partPlans=<||>,partModes=<||>,jobs,partJobs={},records,partRecords={},collected,partCollected,
  jobOptions,groups,indices,index,source,order,variable,candidates,part,run,result,
  threshold=Lookup[options,"BundleBelowBytes",16*2^20],orderInputs},
 If[StringQ[plan],plan=FeynFacet`FamilyArtifactRead[plan]];
 orderInputs=Lookup[options,"ReconstructionOrderInputs",None];
 If[!MemberQ[{Automatic,None},orderInputs]&&!AssociationQ[orderInputs],
  reconstructionFail["reconstruction order inputs","an association or None is required"]];
 If[plan===Automatic,
  plan=If[AssociationQ[orderInputs],
    coefficientPrepareReconstructionPlan[inputs,data,nativeDirectory,orderInputs],<||>],
  If[AssociationQ[plan]&&KeyExistsQ[plan,"PartitionManifest"]&&
     coefficientValidateSavedPlan[plan,orderInputs]=!=True,
   reconstructionFail["saved coefficient plan","current mathematical inputs differ or are unavailable"]]];
 If[!AssociationQ[plan],reconstructionFail["execution plan","an association is required"]];
 directory=Lookup[plan,"OrdinaryWorkingDirectory",FileNameJoin[{nativeDirectory,"Reconstruction"}]];
 jobOptions=Join[<|"SeriesVariable"->None,"SeriesOrder"->None,"Threads"->options["Threads"],
   "FactorScan"->True,"ShiftScan"->True,"ProgressInterval"->60,"Resume"->True|>,
   KeyTake[options,{"Threads","FactorScan","ShiftScan","Resume","ProgressInterval"}]];
 If[KeyExistsQ[plan,"PartitionManifest"],
  If[Lookup[plan,"SourceTraceManifestHash",None]=!=
    coefficientFileHash[finiteFieldTraceManifestFile[inputs["TraceDirectory"]]],
   reconstructionFail["partition plan","the source trace definition binding differs"]];
  partData=reconstructionPartitionTrace[data,plan["PartitionManifest"]];
  If[!AssociationQ[partData],reconstructionFail["literal coefficient partition",partData]];
  sourceIndices=DeleteDuplicates[partData["PartitionSourceIndices"]];
  orderPlans=Lookup[plan,"CoefficientOrderPlans",<||>];
  If[StringQ[orderPlans],orderPlans=FeynFacet`FamilyArtifactRead[orderPlans]];
  If[!AssociationQ[orderPlans]||Sort[Keys[orderPlans]]=!=Sort[sourceIndices],
   reconstructionFail["partition orders","a bound order plan for every regular source is required"]];
  Do[
   source=partData["PartitionSourceIndices"][[index]];
   If[partData["PartitionKinds"][[index]]==="Exact",
    AssociateTo[partModes,index->{None,None}],
    order=orderPlans[source];
    If[!AssociationQ[order]||order["Status"]=!="SufficientOrdersDetermined"||
      projectAbsolutePath[order["InputBindings"]["Source"]["ExpressionFile"]]=!=partData["OutputFiles"][[index]],
     reconstructionFail["partition orders","the regular-source order binding differs"]];
    If[coefficientMasterID[order["InputBindings"]["CatalogMapping"]["Source"]]=!=
      coefficientMasterID[data["Masters"][[data["OutputMetadata"][[source]]["MasterIndex"]]]],
     reconstructionFail["partition orders","the source master differs"]];
    If[Lookup[order["InputBindings"],"SourceSHA256",None]=!=
        coefficientFileHash[partData["OutputFiles"][[index]]]||
      Lookup[order["InputBindings"],"TraceColumnBinding",None]=!=
       <|"OutputMetadata"->data["OutputMetadata"][[source]],
         "Definitions"->KeyTake[data,{"Masters","SymbolRules","Signatures","Variables","PhysicalFactor"}]|>||
      Lookup[order["InputBindings"],"SourceDefinitions",None]=!=
       KeyTake[inputs["Metadata"],{"CardName","Setup","Pairs","AnalyticContext","Topologies",
          "TopologyEquivalence","ReverseRules","MassDimensions","DimensionRule"}],
      reconstructionFail["partition orders","the source content or mathematical definition binding differs"]];
    candidates=Select[Keys[data["SymbolRules"]],
      MemberQ[{"eps","ep","Epsilon",SymbolName[order["DimensionalRegulator"]]},SymbolName[#]]&];
    If[Length[candidates]=!=1,reconstructionFail["partition orders","a unique regulator alias is required"]];
    variable=First[candidates];
    AssociateTo[partModes,index->{variable,order["RequiredCoefficientUpperOrder"]}];
    AssociateTo[partPlans,index->order]],
  {index,Length[partData["OutputFiles"]]}]];
 jobs=reconstructionScheduleJobs[data,threshold,Automatic];
 jobs=Map[Function[job,indices=Complement[job["Outputs"],sourceIndices];
   If[indices==={},Nothing,Join[job,<|"Outputs"->indices,"Bytes"->Total[data["ExpressionBytes"][[indices]]]|>]]],jobs];
 run[selected_,traceData_,where_] := Module[{},
  If[!DirectoryQ[where],CreateDirectory[where,CreateIntermediateDirectories->True]];
  If[TrueQ[Lookup[plan,"ResumeOnly",False]]&&!AllTrue[selected,
    reconstructionJobReusableQ[#,traceData,where,executable,
      Join[jobOptions,KeyTake[#,{"SeriesVariable","SeriesOrder"}]],True]&],
   reconstructionFail["scheduled results","a required completed job is unavailable"]];
  reconstructionRunSchedule[selected,traceData,where,executable,jobOptions]];
 records=run[jobs,data,directory];
 collected=reconstructionCollectScheduledJobs[directory,inputs["TraceDirectory"],data,records,jobOptions];
 If[!AssociationQ[collected],reconstructionFail["scheduled result parsing",collected]];
 If[AssociationQ[partData],
  partDirectory=Lookup[plan,"PartitionWorkingDirectory",FileNameJoin[{directory,"Partitions"}]];
  partJobs=Flatten[Map[Function[job,
    groups=GatherBy[job["Outputs"],partModes[#]&];
    Map[Function[outputs,Join[job,<|
      "Name"->If[Length[groups]===1,job["Name"],job["Name"]<>"_"<>IntegerString[First[outputs],10,6]],
      "Outputs"->outputs,"Bytes"->Total[partData["ExpressionBytes"][[outputs]]],
      "SeriesVariable"->partModes[First[outputs]][[1]],"SeriesOrder"->partModes[First[outputs]][[2]]|>]],groups]],
    reconstructionScheduleJobs[partData,threshold,Automatic]],1];
  partRecords=run[partJobs,partData,partDirectory];
  partCollected=reconstructionCollectScheduledJobs[partDirectory,inputs["TraceDirectory"],
    partData,partRecords,jobOptions,partPlans];
  If[!AssociationQ[partCollected],reconstructionFail["partition result parsing",partCollected]];
  collected=reconstructionMergePartitionResults[data,collected,partData,partCollected]];
 result=reconstructionAssembleProduction[Join[inputs,<|"TraceData"->data|>],collected,
   Join[records,partRecords],executable,jobOptions];
 If[AssociationQ[result]&&orderPlans=!=<||>,
  result=Append[result,"CoefficientReconstructionOrderPlans"->orderPlans]];
 result
],$reconstructionFailure];
End[];EndPackage[];
